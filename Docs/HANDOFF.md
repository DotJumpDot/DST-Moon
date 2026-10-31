# Handoff

Pick-up-where-we-left-off notes. Update at the end of every session that
changes state a stranger (or future-you) would trip over.

## Where we are (2026-10-31, pass 2)

- Local-AI pass 2 landed: TTFT/prefill telemetry (Info panel), server-down
  error hint, per-alias context windows from the Ai_Model bats, compaction
  pinned flip-ready, comet's heightOf crash ported, `DSH_TUI_STATE_DIR`
  launcher pin mirrored. See `Docs/LOCAL-AI.md` — it is the operating
  guide and holds the audit numbers (hello budget 12.4k default preset,
  99%+ follow-up cache hits, one title-LLM cache eviction per session).
- State separation is now symmetric: Comet owns `~/.dsh-tui-comet` (its
  launchers pin it), Moon owns `~/.dst-moon` (paths.ts default + both dstm
  launchers export the pin). Neither can touch the other. A THIRD dsh-tui
  fork would get the upstream `~/.dsh-tui` and also collide with nothing.
- Still open: live tool-call stress test against a running model (batched
  calls + mangled args) — offline pieces verified, the live run needs the
  server up. Sampling knobs are engine-side unwired (documented in
  LOCAL-AI.md).

## Where we were (2026-10-30)

- Phase 1 complete: fork from DST-Comet landed, moon theme in, `dst-moon`
  profile installed and verified via `dsh --profile dst-moon --dump-config`
  (llama-local provider, workspace-write sandbox, zero MCP rows).
- NOT yet done: a live interactive `dstm` boot against the running model.
  All composition is verified; the first real session is phase 2.

## First session checklist (next agent / next human)

1. Start the model: `C:\Code\Ai_Model\start-qwen36-35b-ablit-APEXMiniPlus-262k.bat`
   (listens on 127.0.0.1:8080, no key; first request warms up ~1–2 min).
2. `dstm` from a scratch project dir; confirm: moon theme (gold accent),
   `DST·Moon` wordmark, model line shows `Qwen36-35B-ablit`.
3. Watch the first hello's token cost — the whole point was killing the
   33k hello. If it's high, check for workspace AGENTS.md size and
   `/context_status` (via the agent-tools plugin).
4. Tool calling: give the model a small file task; llama.cpp runs with
   `--jinja` so native tool_calls should work. If args come back
   malformed, note the model's quirk (CometStream tracked these
   per-model in AGENTS.md).
5. Sandbox check: ask the agent to write OUTSIDE the workspace — expect
   `FS_SANDBOX_DENIED`, not a write.

## Gotchas learned on day one

- The fork is a pnpm workspace: NEVER `npm install` it (`workspace:*`
  protocol). Use `npx -y pnpm@11.21.0 install --config.nodeLinker=hoisted`.
- `pnpm -r pack` drops tarballs in the workspace ROOT, not package dirs —
  the installer moves them from `engine/*.tgz`, not `engine/<pkg>/`.
- Three version exemptions are required (installer grants them):
  dsh-code-runtime-worker-thread@rc.6, dsh-agent-presets@rc.6,
  dsh-experimental-tool-agent-team@0.2.1-rc.2-moon.1 — all on dsh
  0.2.1-rc.2, all mirroring Comet's proven profile.
- `patch: entry "tool-ralph" not found` at boot is upstream noise (Comet
  shows it too) — ignore.
- Comet's profile `~/.dsh/profiles/dsh-tui/cordis.patch.yml` holds live
  credentials. Never copy from it; Moon's profile is hand-written.
- Thai rendering (2026-10-31): TRIED AND REVERTED. A merged font family
  ("Cascadia Prompt" = WT-bundled Cascadia Mono 2407 + Prompt, built with
  fontTools pyftmerge, per-user installed) put real Prompt Thai in the
  terminal BUT the English went visibly wrong — Prompt's proportional
  kerning/GPOS leaks into the terminal cell grid (irregular letter gaps),
  and the user chose stock over it. Final state: settings.json has NO font
  override (WT default Cascadia Mono, bundled 2407 cut; backup at
  `settings.json.bak-2026-10-31`). The plain Prompt family remains
  installed per-user (harmless; GUI apps can use it). If Thai-in-terminal
  is ever revisited, the merge must ALSO strip/keep-out Prompt's Latin
  GPOS kerning — and WT has no configurable fallback list (face is a
  string; arrays are rejected by the schema).
