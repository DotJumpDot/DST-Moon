# Plan notes

Phase plan + version pins + deferred ideas. Update as phases complete;
completed phases get their CHANGELOG line on the day they land.

## Current phase

- Phase 1 done (2026-10-30): fork landed, profile live, first `dstm` boot.
- Phase 2 (next): live-run tuning against Qwen36-35B-ablit — verify tool
  calling through llama.cpp's `--jinja` template, watch first-hello token
  cost, tune maxTokens/temperature per turn quality.

## Done

- 2026-10-30 — Phase 1: fork from DST-Comet (copy + rebrand + moon theme),
  dst-moon profile (llama-local provider, strict sandbox), dstm launcher,
  own data dir ~/.dst-moon, engine/plugin renamed, docs.

## Version pins

- `@deepseek-ai/dsh` global — 0.2.1-rc.2 — the only engine; never modified
- `vendor/dsh-tui` — upstream `2957277` (2026-10-24) + fork changes
  (Docs/CHANGES.md)
- engine fork — 0.2.1-rc.2-moon.1 — host pairs rc.2 == rc.3 bundles
- pnpm — 11.21.0 via npx for pack (12 refuses bundledDependencies under
  the isolated linker); global 12.x fine for install
- local model — Qwen3.6-35B-A3B Ablit APEX-MiniPlus (`--alias
  Qwen36-35B-ablit`), 262k KV, port 8080

## Deferred / ideas

- Local-model context care from CometStream worth porting later: no-keep-
  alive fetch for loopback (llama-server ECONNRESET between turns),
  cannonball history trimming, bounded tool output with spill files.
  The dsh engine has its own compaction; evaluate before porting.
- A second provider route for a small "fast" local model (e.g. Ling-tiny)
  as the subagent default — cheap teammates under the 35B lead.
- Splash art: a moon-phase companion variant set (whale girl stays for
  now; the mascot cycle is whale girl → whale → none).
- Local-model telemetry: llama.cpp `timings`/cache-hit chips in the
  transcript turn row (CometStream ContextRing equivalent).
