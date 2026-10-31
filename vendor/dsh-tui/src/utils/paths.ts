/**
 * Data-directory paths for the dsh-tui profile. All preferences and history
 * live under the data dir below.
 *
 * The compiled copy (lib/types/utils/paths.js) is also imported by the bin
 * launcher, mirroring the shellQuote precedent.
 */

import { homedir } from 'node:os'
import { join } from 'node:path'

/**
 * The user's home directory. `os.homedir()` first; the USERPROFILE/HOME
 * spellings are the last-resort fallback for stripped-down environments.
 * @returns Absolute home path.
 */
export function homeDir(): string {
  return homedir() || process.env.USERPROFILE || process.env.HOME || ''
}

/**
 * Data directory all preferences/history live in.
 *
 * DST-Moon fork: `~/.dst-moon`, so this product never shares state with a
 * sibling dsh-tui fork (DST-Comet pins `~/.dsh-tui-comet`). Resolution
 * order: `DSH_TUI_DATA_DIR` (tests/embeds), then `DSH_TUI_STATE_DIR` — the
 * cross-fork launcher-pin convention (both dstm launchers export it
 * explicitly, so the pin survives even if a rebase restores the upstream
 * `~/.dsh-tui` default in this module) — then the fork default.
 */
export const DATA_DIR = resolveDataDir()

function resolveDataDir(): string {
  const testOverride = process.env.DSH_TUI_DATA_DIR
  if (testOverride !== undefined && testOverride !== '') return testOverride
  const pin = process.env.DSH_TUI_STATE_DIR
  if (pin !== undefined && pin.trim() !== '') return pin.trim()
  return join(homeDir(), '.dst-moon')
}

/**
 * Where one backend keeps its own files: `<dataRoot>/backends/<id>`, keyed by
 * the backend's declared id (the `x-dsh-tui` Backend entry's `spec.id` field).
 * The single construction point, so a check for what a removal
 * left behind reads the same path the backend wrote to (C-5).
 *
 * `dataRoot` defaults to this profile's own data dir. It is a parameter so
 * that a regression can point the whole check at a temporary tree, exactly like
 * the diagnostics' own `dataDir` override.
 */
export function backendDataDir(backendId: string, dataRoot: string = DATA_DIR): string {
  return join(dataRoot, 'backends', backendId)
}
