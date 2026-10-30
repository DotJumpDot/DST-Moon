# The dst-moon dsh profile

`cordis.patch.yml` here is the source of truth for the DST-Moon dsh
profile. `scripts/install-fork.bat` copies it to
`%USERPROFILE%\.dsh\profiles\dst-moon\cordis.patch.yml` after installing
the fork/engine/plugin tarballs — edit it here, then re-run the installer
(or copy the file over manually; the patch layer hot-reloads on next
launch).

## What it configures

- **TUI row** (`dsh-tui`): provider `llama-local`, model `Qwen36-35B-ablit`,
  whale companion, fullscreen — same shape as the Comet profile minus the
  cloud provider/effort.
- **Local model route** (`llm-pi-ai` → `llama-local`): OpenAI-completions
  against `http://127.0.0.1:8080/v1`, dummy bearer (the launchers run
  llama-server without `--api-key`), `maxTokens: 32768`,
  `contextWindow: 131072` (half the KV on purpose — quality on these
  finetunes rots past ~80–150k), `thinkingFormat: deepseek` so
  `reasoning_content` renders as thinking.
- **Strict folder rule** (`sandbox-policy` + `approval`):
  `workspace-write` rooted at the launch cwd, mutations outside denied,
  privileged ops ask. This overrides the dsh-tui bundle's Windows default
  of `danger-full-access` + `never`.

## What is deliberately absent

No MCP servers, no cloud providers, no credentials. Adding a big tool
schema back re-creates the 33k-token first hello this profile exists to
avoid.

## Switching models

Nothing to edit: the route has **no hardcoded model list** — it discovers
the live model list from the running llama-server (`GET /v1/models`). Load
a different `C:\Code\Ai_Model\start-*.bat`, restart `dstm`, done: a pinned
default that isn't currently loaded adopts the first running alias, and
`/model` lists everything the server is serving (your pick persists). If
the server uses a different port, change `baseURL`. All current launchers
use `127.0.0.1:8080` with no key.
