# Vendored upstreams

This monorepo vendors upstream projects. Upstream commit pins live here so
we can rebase our fork and track what we changed. DST-Moon itself was
forked from our DST-Comet repo (snapshot of 2026-10-30), which in turn
forks the upstreams below.

| Path | Upstream | Pinned commit | Date |
|---|---|---|---|
| `vendor/dsh-tui` | https://github.com/ccch1mneyyy/dsh-TUI | `29572774890a4a89ae1fa562dd15a1ae21bb3593` | 2026-10-24 |
| `vendor/deepseek-harness` (not tracked, local only) | https://github.com/deepseek-ai/deepseek-harness | `22ddee3792402c3e70ec5f86a63c3e3e895a2f60` | 2026-10-23 |
| `engine/` (forked copy, tracked) | same deepseek-harness pin, `packages/experimental/{agent-team,tool-agent-team,agent-team-profile}` | `22ddee3792402c3e70ec5f86a63c3e3e895a2f60` | 2026-10-26 |
| whole repo | our DST-Comet fork (`C:\Code\Dsh_Tui_Comet`, main @ 2026-10-30, minus `Advice/`, `orchestra/`, `Picture/`, profile secrets) | — | 2026-10-30 |

Runtime pairing used for development: `@deepseek-ai/dsh@0.2.1-rc.2` (npm global)
against `dsh-tui` at the pinned commit (which targets dsh `0.2.1-rc.2`).
Engine fork versions are `0.2.1-rc.2-moon.1` (renamed from Comet's
`-comet.1`; the running host pairs rc.2 == rc.3 bundles byte-for-byte).

## Why deepseek-harness is not in git

It is ~103 MB of source that we treat as a read-only reference (plugin APIs,
agent-team service, tools). Our product changes are all inside `vendor/dsh-tui`.
`scripts/setup-vendor.sh` re-creates the checkout at the pinned commit.

The exception is `engine/`: the three Agent Teams packages we fork (see
`engine/README.md`) ARE tracked — they are small, they carry our orchestration
changes, and their fork versions must survive upstream re-pins.

## What DST-Moon deliberately does NOT carry over from DST-Comet

- **Constellation-MCP** (or any MCP server) — bug-bounty tooling; its
  schemas are the 33k-token first hello. Moon's profile has none.
- **`Advice/` and `orchestra/`** — bug-bounty run logs and the team
  protocol for hunts. They live in the Bug_Bounty workspace, not here.
- **The installed profile's credentials** — Comet's `cordis.patch.yml`
  carries live mail/API credentials. Moon's profile
  (`profile/cordis.patch.yml`) is written from scratch: local model only,
  no keys.

## Re-vendoring at a new pin

```sh
rm -rf vendor/dsh-tui
git clone https://github.com/ccch1mneyyy/dsh-TUI.git vendor/dsh-tui
git -C vendor/dsh-tui checkout <commit>
rm -rf vendor/dsh-tui/.git
# update the table above, then re-apply Docs/CHANGES.md
```
