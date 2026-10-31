# Changelog

One line per meaningful change, newest first. Format:
`YYYY-MM-DD — what`. A bigger pass may take a short indented bullet
list under its date line. Entries mirror the commit log; commits
themselves follow the style in `AGENTS.md`.

- 2026-10-31 — Local-AI pass 2: telemetry, per-alias windows, crash/isolation
  twins (user ask: "do all of that" minus the thinking-token counter).
  Info panel gains First tok (TTFT) + Prefill rows fed by a new lastTimings
  projection (cache % already rode llama.cpp cached_tokens — verified in the
  session logs, 99.6-99.9% hits on follow-ups); a llama-local connection
  failure now renders "start a start-*.bat, then re-send" instead of raw
  `fetch failed`; launchers parse the Ai_Model bats (--alias/-c) so each
  alias declares its real contextWindow (bonsai 32768, others 262144);
  compaction-basic pinned at engine defaults (0.8/0.16) flip-ready in the
  profile; comet's 2026-10-30 heightOf sparse-row crash ported to Moon and
  the DSH_TUI_STATE_DIR launcher pin mirrored so Comet (~/.dsh-tui-comet)
  and Moon (~/.dst-moon) can never share TUI state. New tooling:
  scripts/analyze_session.py (hello budget 12.4k on the default preset,
  append-only prefix, one title-LLM cache eviction per session) and
  verify-local-telemetry.tsx (18 checks). Details: Docs/LOCAL-AI.md.
- 2026-10-31 — Model name follows the running alias + liangshen preset
  (user reports): TUI row `model` now resolves from DSH_LLAMA_MODELS at
  boot (llama.cpp ignores the model field, so sessions worked while the
  display stayed pinned to Qwen36-35B-ablit); `preset: liangshen` replaces
  the harness default preset, whose time-context plugin injected a
  per-turn "Time sampled... / Browser time zone: unavailable. Ask the user
  to clarify..." user-message block that the local model read literally and
  rambled about on every hello (session-log verified, source.kind
  time-context; Comet sessions show the same injection).
- 2026-10-31 — Route models fixed to a real list (Fix): pi-ai refuses a
  hand-declared route with no models at boot ("resolves no models"), so the
  launchers now probe GET /v1/models and pass the running aliases in
  DSH_LLAMA_MODELS; the profile materializes the list from that via !!js
  (fallback: the first-run default alias). Installer pnpm-installs the
  agent-tools plugin deps (link: target had no node_modules).
- 2026-10-30 — Onboarding wizard skipped on Moon (user ask): the first-run
  wizard assumes DEEPSEEK_API_KEY and the cloud catalog; shouldOfferOnboarding
  now answers false unless DSH_TUI_ONBOARDING=1.
- 2026-10-30 — Running-model auto-detect (user ask): profile drops the
  hardcoded model list (pi-ai live-discovery of GET /v1/models), and
  validateModelRoute adopts the first running alias for a local route whose
  pin is not loaded instead of falling back to the cloud default; /model
  lists everything the server serves.
- 2026-10-30 — Status bar TPS made a plain single-color number (user pref):
  gauge + sparkline removed from the status line, InfoPanel tps row loses
  the green/yellow/red speed ladder; renderers stay in StatusMetrics.
- 2026-10-30 — Moon theme re-tuned to the full gold family (user pref):
  every role pink-night paints pink is now gold/amber/bronze — warm ivory
  text #F2EDE2 on warm night neutrals, no light-blue mix; classic pastel
  method pills and functional escapes kept, pink-night-style.
- 2026-10-30 — Forked from DST-Comet into DST-Moon: copied vendor/dsh-tui,
  engine (renamed `-moon.1`), plugins (`@dst-moon/agent-tools`), bin
  (dstm), scripts, assets, Docs; dropped Advice/, orchestra/, Constellation
  wiring; own profile `dst-moon` (local llama.cpp provider, workspace-write
  sandbox); moon theme replaces comet; own data dir `~/.dst-moon`.
- 2026-10-26 — Base project scaffold: README, AGENTS.md (house rules +
  commit & push style contract), CHANGELOG, `Docs/` starter set (index,
  architecture, how-to-run, plan notes, handoff), .gitignore; initial
  commit made in the house style via `git commit -F`.
