# Changelog

One line per meaningful change, newest first. Format:
`YYYY-MM-DD — what`. A bigger pass may take a short indented bullet
list under its date line. Entries mirror the commit log; commits
themselves follow the style in `AGENTS.md`.

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
