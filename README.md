# DST-Moon

**DST** = **D**eep**S**eek **T**erminal. DST-Moon is our dsh-TUI fork aimed
at **local AI models** — the same harness you know from
[DST-Comet](https://github.com/DotJumpDot) (our bug-bounty profile), re-tuned
for a llama.cpp server on your own machine. `dstm` launches it
(**DST Moon**).

```
dstm  →  dsh --profile dst-moon  →  our dsh-tui fork  →  local llama.cpp (OpenAI-compatible)
```

## Why a separate fork

DST-Comet's profile carries Constellation-MCP (59–77 browser-army tools with
full JSON schemas billed on every request) plus a 24 KB workspace protocol —
its first hello eats ~33k tokens. Fine on a cloud model; ruinous on a local
one. DST-Moon is **completely separate**:

| | DST-Comet | DST-Moon |
|---|---|---|
| dsh profile | `dsh-tui` | `dst-moon` |
| TUI state dir | `~/.dsh-tui` | `~/.dst-moon` |
| Session logs | `~/.dsh/sessions` | `~/.dst-moon/sessions` (via `DSH_TUI_SESSION_ROOT`) |
| Provider | DeepSeek cloud (+zai, opencode-go) | `llama-local` → `http://127.0.0.1:8080/v1` |
| MCP servers | Constellation + friends | **none** |
| Sandbox | danger-full-access (Windows default) | **workspace-write + ask** |

Same global `dsh` engine install (never touched), same launcher shape —
zero shared state between the two products.

## Strict folder rule

The Moon profile locks the agent to the workspace it was launched in:
writes outside the launch directory are denied (`sandbox-policy`
`workspace-write`), and privileged operations ask first (`approval: ask`).
Relax per-session with `/permission` if a task truly needs more. The local
model never gets Constellation's reach — it codes, it does not browse.

## Layout

| Path | What |
|---|---|
| `vendor/dsh-tui/` | **Our fork — all product changes happen here.** Vendored from upstream, `.git` stripped; pin in [VENDORED.md](VENDORED.md). |
| `profile/` | The `dst-moon` dsh profile patch (provider, sandbox) — the source of truth the installer copies into `~/.dsh/profiles/dst-moon/`. |
| `engine/` | Fork of the Agent Teams engine packages (`-moon.1` versions) — generic orchestration, no bug-bounty flavor. |
| `plugins/dst-moon-agent-tools/` | `context_status` + `session_compact` — context-awareness tools, the mitigation for context-hungry sessions. |
| `bin/` | `dstm` launcher (Windows `.cmd` + bash). |
| `scripts/` | `install-fork.bat` (build + pack + install into the profile), `setup-vendor.sh`. |
| `Docs/`, `assets/` | Design notes, change log vs upstream, icon. |

## Setup

Requirements: Node 20+, pnpm 11+ (or let the scripts `npx` it), git, a
global `dsh` install (`npm i -g @deepseek-ai/dsh`), and a local
llama.cpp server listening on `127.0.0.1:8080` (start one from
`C:\Code\Ai_Model`, e.g. `start-qwen36-35b-ablit-APEXMiniPlus-262k.bat` —
no API key needed; the profile sends a dummy bearer).

```sh
# 1. (optional) re-create the untracked harness reference checkout
scripts/setup-vendor.sh

# 2. build + pack + install the fork into the dst-moon profile
scripts\install-fork.bat

# 3. launch from any project directory
dstm
```

First run boots into the **Moon theme** (moon-gold accent, moonlight-blue
second voice, moon-white text) — pink-night's structure under a moonlit
palette. `/theme` switches, and your pick persists.

## Model wiring

`profile/cordis.patch.yml` declares the `llama-local` pi-ai route
(OpenAI-completions, `max_tokens` field, `reasoning_content` thinking) with
`contextWindow: 131072` — deliberately half of the launchers' 262k KV, since
quality on these finetunes rots past ~80–150k (CometStream ops lore). To
point at a different local model: edit the `models:` entry + the TUI row's
`model:`, re-run the installer.

## License

Our changes: MIT. Vendored code keeps its upstream licenses
(`vendor/dsh-tui/LICENSE`, `THIRD_PARTY_LICENSES/`).
