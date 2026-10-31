# DST-Moon local-AI operating guide

How the harness behaves around a local llama.cpp model, what the numbers
mean, and what the 2026-10-31 audit measured on the real rig. Companion to
`Docs/HANDOFF.md` (state separation) and `profile/cordis.patch.yml` (the
config source of truth).

## The telemetry stack (what you see and where it comes from)

llama.cpp reports `usage.prompt_tokens_details.cached_tokens` on every
request (build b12002 on this rig). The pi-ai openai-completions adapter
maps it exactly the way we need:

```
input      = prompt_tokens − cached_tokens        (uncached prefill)
cacheRead  = cached_tokens                        (KV cache hits)
cacheWrite = 0                                    (llama.cpp has no write tier)
```

That flows through dsh-llm → the session log (`data.usage.cacheReadTokens`)
→ the TUI channel, with zero engine forks. Surfaces:

| Surface | Field | Reads |
|---|---|---|
| Status line | `cache 94.0%` | last request's `cacheRead / (input+cacheRead+cacheWrite)` |
| Status line | `38 tps` | decode rate, first token → settle (plain, single color) |
| Info panel | `First tok` | TTFT: first stream delta minus the step's start (`940ms` / `2.4s` / `1m04s`); ≥30s appends `(warm-up? first request takes 1-2 min)` |
| Info panel | `Prefill` | effective prompt-processing rate: whole prompt ÷ TTFT (`2100 tok/s`) |
| Info panel | `Cache hit` | same as the status-line cache field |

Reading a slow turn: low cache % + slow prefill = prefix miss (something
rewrote early context, or the server restarted); high cache % + slow first
token = warm-up after a fresh model load; fast prefill + low tps = the
model is thinking (reasoning tokens), not the harness.

TTFT anchor: `step.start` carries no timestamp, so the projector anchors on
the previous timed event (the user message for a turn's first call, the
tool result for later steps) — the closest durable approximation to request
dispatch, and it stays correct on replay.

## Per-alias context windows

The launchers parse every `C:\Code\Ai_Model\start-*.bat` for `--alias X`
and `-c N` and export `DSH_LLAMA_CTX` (`alias:ctx` pipe pairs); the profile
attaches `contextWindow` per catalog entry, so the context bar, pressure
warnings and compaction trigger all follow the loaded model — Bonsai-27B
declares 32768, the 262k models declare 262144. The route-level
`defaultContextWindow: 131072` only applies when no bat is known (server
down at launch, bats unreadable) — deliberate: quality on these finetunes
rots past ~80-150k regardless of what the KV holds.

Cross-session cache is real on this rig: the 2026-10-31 01:33 session's
FIRST request served 9,463 of 12,402 prompt tokens from leftover KV cache
(76% hit) because system prompt + tool schemas + injections are
byte-identical across sessions. Corollary: changing the preset, tools or
system prompt invalidates that warm start.

## Prefix-cache audit (measured, not assumed)

`python scripts/analyze_session.py` (or `--all`) reads the engine session
logs and reports, per session: the hello budget (first request's exact
prompt tokens), every request's cache split, non-user injections, title
LLM requests, and whether the reconstructed message surface stayed
append-only between requests.

Findings on the three pre-liangshen Qwen sessions (2026-10-30/31):

- Surface is append-only in practice: the three boot injections
  (runtime-context, skill-catalog, time-context) appear ONCE at the start;
  follow-up requests hit 99.6-99.9% cache with 19-47 uncached tokens.
  time-context was a QUALITY problem (the model obeyed it literally), not
  a cache problem — liangshen fixed the rambling, cache was never broken.
- Hello budget with the DEFAULT preset: **12.3-12.4k prompt tokens**.
  liangshen sessions should land lower (no time-context block, leaner tool
  face); the analyzer is the regression gate — run it after any preset or
  plugin change and compare the first line.
- `session/title-llm-request` fires once per session (first prompt): a
  SEPARATE llama.cpp request sharing almost no prefix, so on the
  single-slot server it evicts the conversation KV once, at the cheapest
  possible moment (right after hello). Leave it.

## Compaction & sampling

`compaction-basic` is pinned in the profile at the engine defaults —
compact at 80% of the DECLARED window, keep a 16% verbatim tail — so the
knobs are visible and flip-ready: raise `retainRatio` (more verbatim) or
lower `thresholdRatio` (earlier, smaller summaries) if a local model's
compaction summaries read lossy; `modelPolicies` can tune one alias
differently. With per-alias windows declared, bonsai now compacts at ~26k
and the big models at ~210k.

Sampling (temperature/top-p) is NOT profile-exposable today: dsh-llm's
`LlmCallControls.temperature` exists call-level, but no config surface
feeds it from a cordis profile. Flip-ready only in the sense that the
engine seam exists; wiring it means an engine-fork row like the
agent-team tarballs.

## Server-down UX

A connection failure on the `llama-local` route renders as
`turn error · llama.cpp unreachable at 127.0.0.1:8080 — start a start-*.bat
(Ai_Model), then re-send` instead of the raw `fetch failed`. Timeouts are
deliberately NOT matched — a slow-but-up server must not read as down.
Matcher: `src/channel/projection.ts` `localServerFailureHint`, gated on
provider `llama-local`.

## State isolation (post-2026-10-31)

DST-Comet moved to `~/.dsh-tui-comet` (pinned by its launchers via
`DSH_TUI_STATE_DIR`). DST-Moon's `paths.ts` honors the same variable as
its second override (`DSH_TUI_DATA_DIR` first for tests, then
`DSH_TUI_STATE_DIR`, then the `~/.dst-moon` default) and both dstm
launchers export the pin explicitly — a rebase that restores the upstream
`~/.dsh-tui` default still lands in Moon's own dir. Neither fork can touch
the other's settings, theme, mount ledger or prompt history.

## Tool-call stress test (run when a model is up)

The one live item not covered by offline verification: how the agent loop
copes with a local model emitting 3+ batched tool calls and mangled JSON
args (CometStream's history says this is THE local-model failure mode).
With a model running:

```
dsh --profile dst-moon headless --json "In this directory, using ONE batch
of tool calls: (1) list the files, (2) read package.json and report the
name field, (3) run node -e \"console.log(6*7)\" and report the output."
python scripts/analyze_session.py        # then check the cache/injection rows
```

What to look for in the `--json` events / session log: all three calls in
one assistant step (batch OK), per-call results even if one arg is invalid
(no whole-batch abort), and a repair retry rather than a dead turn after a
malformed-args result. If the model mangles args and the turn dies, the
fix belongs in an argument-repair layer — note the model + quirk here.

## Verification

- `node --import tsx/esm scripts/verify-local-telemetry.tsx` — 18 checks:
  formatTtft ladder, hint matcher gates, InfoPanel row rendering
  (settled / warm-up / empty states).
- `node --import tsx/esm scripts/verify-moon-transcript.tsx` — transcript
  regression (33 checks) still green after the projection changes.
- `python scripts/analyze_session.py` — the live-data audit above.
