# Architecture

## Overview

DST-Moon is a terminal UI over the DeepSeek Harness agent engine, aimed at
a local llama.cpp model. Three layers:

```
bin/dstm (launcher: env + --profile dst-moon)
  └─ global dsh engine (npm -g, never modified)
       ├─ profile ~/.dsh/profiles/dst-moon (bundles + cordis.patch.yml)
       │    ├─ dist/dst-moon.tgz            ← vendor/dsh-tui (our fork)
       │    ├─ engine/dist/*.tgz (-moon.1)  ← engine/ (Agent Teams fork)
       │    └─ link:plugins/dst-moon-agent-tools
       └─ provider llama-local → http://127.0.0.1:8080/v1 (llama.cpp)
```

## Modules

- `vendor/dsh-tui/` — TypeScript React (Ink) TUI; `src/channel/` projects
  the session log (source of truth) into views; `tui-profile/` is the
  cordis glue. Vendored deps (`vendor/dsh-std`, mathjax, sqlite) build
  via `npm run build:vendor`.
- `engine/` — three forked harness packages (`agent-team` service,
  `tool-agent-team` model-facing tools, `agent-team-profile` bundle) at
  `0.2.1-rc.2-moon.1`.
- `plugins/dst-moon-agent-tools/` — `context_status` (the model reads its
  own context pressure) + `session_compact` (agent-initiated compaction).
- `profile/` — the profile patch: TUI row, local provider route, sandbox.

## Data flow & state

User input → dsh engine (agent loop, tools, session log) → TUI projection.
State lives in three places, all Moon-owned:

- `~/.dst-moon/` — TUI data dir (`DATA_DIR` in
  `vendor/dsh-tui/src/utils/paths.ts`; env `DSH_TUI_DATA_DIR` overrides) —
  settings, theme/model prefs, history, session index, resume.txt.
- `~/.dst-moon/sessions/` — session logs (`DSH_TUI_SESSION_ROOT`, set by
  the launcher; without it logs land in the shared `~/.dsh/sessions`).
- `~/.dsh/profiles/dst-moon/` — the profile itself (shared `~/.dsh` by
  design: same engine, separate profile directory).

## Decisions

- **2026-10-30 — fork from DST-Comet, not upstream**: inherit the Comet
  fork's UX work wholesale (Docs/CHANGES.md), then diverge. Rebasing to a
  new upstream pin means replaying both change sets.
- **2026-10-30 — pi-ai route, not DEEPSEEK_BASE_URL**: the official
  deepseek route speaks Anthropic Messages; llama.cpp serves OpenAI
  completions. A hand-declared `llama-local` pi-ai route fits natively
  (max_tokens field, reasoning_content thinking, keyless via dummy
  bearer header).
- **2026-10-30 — moon owns the auto-dark slot**: `getTheme('auto')`
  resolves dark terminals to `moon` instead of `dark`. The persisted
  `/theme` choice still wins through the forced chain (prop > env >
  theme.json), so the brand-default lever (which overrides stale prefs)
  was deliberately not used.
- **2026-10-30 — contextWindow 131072, not 262144**: the launchers run
  262k KV, but quality on these finetunes rots past ~80–150k
  (CometStream ops lore); half is the conservative default. Tunable in
  `profile/cordis.patch.yml`.
- **2026-10-30 — workspace-write + ask on Windows**: overrides the dsh-tui
  bundle's win32 default (danger-full-access + never). The strict folder
  rule is the product's promise; `/permission` relaxes per session.
