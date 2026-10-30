# How to run

Windows-first: everything below works in both Git Bash and PowerShell /
Windows Terminal (the launcher ships as `bin/dstm.cmd` and `bin/dstm`).

## Prerequisites

- Node 20+ (24.x on this rig), pnpm 11+ on PATH (scripts also `npx` the
  exact `pnpm@11.21.0` for pack steps), git
- `dsh` CLI on PATH — `npm i -g @deepseek-ai/dsh` (0.2.1-rc.2 on this rig)
- A local llama.cpp server on `127.0.0.1:8080`, no API key. Start one from
  `C:\Code\Ai_Model`, e.g. `start-qwen36-35b-ablit-APEXMiniPlus-262k.bat`
  (current main model, `--alias Qwen36-35B-ablit`, 262k KV, `--jinja`)
- No DeepSeek key needed — Moon talks only to the local server

## Setup (once, and after profile/model changes)

```sh
# optional: untracked harness reference checkout (~103 MB)
scripts/setup-vendor.sh

# build fork + engine, pack tarballs, install into the dst-moon profile,
# copy profile/cordis.patch.yml over
scripts\install-fork.bat
```

The installer needs the tarballs to stay on disk: the profile's
`package.json` holds `file:`/`link:` dependencies into `dist\` and
`engine\dist\` (both gitignored — rebuild after a fresh clone).

## Run

```sh
dstm                 # from any project directory (the workspace)
dstm --resume        # resume the last session (reads ~/.dst-moon/resume.txt)
```

First boot: Moon theme (moon-gold accent), whale companion splash,
`DST·Moon` wordmark in the side panel. `/theme` to switch (persists),
`/permission` to relax the sandbox for a session.

## Verify

```sh
# fork typecheck + transcript regression (in vendor/dsh-tui)
cd vendor/dsh-tui && npx -y pnpm@11.21.0 run typecheck
node --import tsx/esm scripts/verify-moon-transcript.tsx

# engine fork (in engine/)
npx -y pnpm@11.21.0 run verify   # typecheck (3 pkgs) + node:test + builds

# profile sanity: dsh resolves the profile and the provider route
dsh --profile dst-moon --version
```

A commit's `Verified:` paragraph names which of these ran and the counts.
