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

Edit the `models:` entry (id/contextWindow/maxTokens) and the TUI row's
`model:` to match your llama-server `--alias`, then re-run
`scripts/install-fork.bat`. If the server uses a different port, change
`baseURL`. All current `C:\Code\Ai_Model\start-*.bat` launchers use
`127.0.0.1:8080` with no key.
