# AGENTS.md — working rules for this repo

This file is the contract. Every working session — human or AI agent —
follows it from the first commit to the last. Copy this folder to start
a new project and the style carries over unchanged.

## What this repo is

DST-Moon: a UX fork of dsh-TUI on top of the DeepSeek Harness (`dsh`)
engine, aimed at **local AI models** (llama.cpp, OpenAI-compatible, no API
key). The launch command is `dstm` (`dsh --profile dst-moon`). It is the
local-model sibling of DST-Comet (the bug-bounty harness): same engine,
same fork lineage, **zero shared state** — own profile (`dst-moon`), own
TUI data dir (`~/.dst-moon`), own session roots, no MCP servers, and a
strict workspace-write sandbox. Primary platform: Windows (Git Bash +
PowerShell / Windows Terminal).

## Repo layout

- `README.md` — what the project is, status, how to run, doc index.
- `AGENTS.md` — this file: house rules + commit & push style.
- `CHANGELOG.md` — newest-first `YYYY-MM-DD — what` log of the work.
- `Docs/` — long-form docs, one topic per file (`Docs/README.md` is the
  index). Plan notes, architecture, run instructions, handoffs.
  `Docs/CHANGES.md` records every modified file vs the upstream pin.
- `vendor/dsh-tui/` — **our fork; all product changes happen here.**
  `vendor/deepseek-harness/` is a read-only, untracked reference
  (recreate with `scripts/setup-vendor.sh`).
- `profile/` — the `dst-moon` dsh profile patch; source of truth for
  provider + sandbox config. `scripts/install-fork.bat` installs it.
- `engine/` — forked Agent Teams packages at `-moon.1` versions.
- `plugins/dst-moon-agent-tools/` — context-awareness tools.
- `bin/dstm` / `bin/dstm.cmd` — the launcher.

## House rules

- Keep upstream file structure; make changes surgical and documented so we
  can rebase on new upstream pins. Record each modified file in
  `Docs/CHANGES.md` with a one-line reason.
- The session log is the source of truth; the TUI only projects it.
- Windows is the primary platform. Verify anything user-visible in both
  Git Bash and PowerShell / Windows Terminal before claiming it works.
- **No secrets in this repo** — and never copy DST-Comet's profile patch
  wholesale: it contains live credentials. Moon's profile is written from
  scratch in `profile/cordis.patch.yml`.
- **No MCP servers in the Moon profile.** The whole point is a cheap first
  hello for a local model; adding a big tool schema back is a regression.
- **Strict folder rule stays strict:** the profile ships
  `sandbox-policy: workspace-write` + `approval: ask`. Don't "fix" agents
  hitting `FS_SANDBOX_DENIED` walls by loosening the profile — fix the
  workspace or use `/permission` per session.
- State separation is load-bearing: `~/.dst-moon` (data dir) and
  `DSH_TUI_SESSION_ROOT` must keep pointing at Moon-owned paths. Don't
  reintroduce shared `~/.dsh-tui` references in the fork.
- Small surgical commits. One commit = one type of work = one checklist.
- Don't rewrite pushed history. Fix-forward with a new commit.

## Commit & push style (every commit, no exceptions)

**Subject:** `Type: summary (extra detail in parens)` — Type ∈
`Feat | Fix | Test | Docs | Chore | Release`. One commit carries exactly
one type; never mix.

**Body:** a `- [x]` checklist of what the commit actually did — one item
per real change, wrapped ~72 cols, concrete (file names, setting names,
numbers), not restatements of the subject.

**Closer:** a `Verified:` paragraph naming the checks that ran and their
results (commands + counts). If verification was declined or impossible,
say that plainly instead — never fake a green.

```
Feat: moon theme replaces comet (pink-night structure, moonlit palette)
- [x] theme.ts: moonNightTheme + MOON_BAR_RAMP (accent #F2D583, blue
  #7FB6D9, text #EDF1F5, cool night neutrals); comet theme + case removed;
  auto-dark slot resolves to moon; isLightThemeActive dark identity
- [x] themeCatalog.ts BUILT_IN_BASE moon:'dark'; branding.ts splash words
  DST/MOON + moonlight tagline; LogoV2 honors deepseek-brand tagline

Verified: pnpm compile clean; verify-moon-transcript OK; typecheck green.
```

**Push policy:** one push = one or more *whole* commits of exactly this
shape. No WIP pushes, no "update", no "misc". If it isn't worth a
checklist, it isn't worth a commit — batch it into the next real one.

Tip: write the message to a file and `git commit -F <file>` — inline
heredocs through Git Bash can flatten newlines.

## Before you commit (session checklist)

1. Change compiles / tests / scripts run — capture real numbers.
2. `CHANGELOG.md` has (or gets) its `YYYY-MM-DD — what` line.
3. Docs touched where the change alters behavior or structure.
4. `git status` shows only files this commit means to include.
5. Commit message written per the style above, via `git commit -F`.
