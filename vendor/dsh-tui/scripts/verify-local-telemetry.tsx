/**
 * DST Moon local-telemetry regression: TTFT/prefill rows + server-down hint.
 *
 * Locks the local-model UX contract added 2026-10-31:
 *  1. formatTtft ladder (ms / s / m+ss, negative clamps);
 *  2. localServerFailureHint maps a llama-local connection failure to the
 *     actionable "start a bat" hint, and passes everything else through
 *     (other providers, timeouts, non-connection errors);
 *  3. the Info panel renders the First tok / Prefill rows plain (single
 *     color), flags warm-up past 30s, and shows the em dash before any
 *     request settles.
 *
 * Run: node --import tsx/esm scripts/verify-local-telemetry.tsx
 */
process.env.FORCE_COLOR = '3'
process.env.DSH_TUI_THEME = 'dark'
process.env.DSH_TUI_LANG = 'en'

const [{ PassThrough, Writable }, React, { Terminal: XTerm }, { render }, { InfoPanel }, { SidePanelRuntimeContext }, { formatTtft }, { localServerFailureHint }] = await Promise.all([
  import('node:stream'),
  import('react'),
  import('@xterm/headless'),
  import('../src/ui.js'),
  import('../src/components/sidePanel/InfoPanel.js'),
  import('../src/components/sidePanel/SidePanelRuntimeContext.js'),
  import('../src/screens/StatusMetrics.js'),
  import('../src/channel/projection.js'),
])

let failed = 0
function check(name: string, ok: boolean, extra = ''): void {
  console.log(`${ok ? 'PASS' : 'FAIL'}: ${name}${extra ? `  (${extra})` : ''}`)
  if (!ok) failed += 1
}

// --- 1. formatTtft ladder ------------------------------------------------
check('formatTtft 940ms', formatTtft(940) === '940ms', formatTtft(940))
check('formatTtft 2400ms', formatTtft(2400) === '2.4s', formatTtft(2400))
check('formatTtft 64000ms', formatTtft(64_000) === '1m04s', formatTtft(64_000))
check('formatTtft clamps negative', formatTtft(-5) === '0ms', formatTtft(-5))

// --- 2. server-down hint -------------------------------------------------
const hint = localServerFailureHint('fetch failed', 'llama-local')
check('hint on fetch failed', hint !== undefined && hint.includes('llama.cpp unreachable'), String(hint))
const refused = localServerFailureHint('connect ECONNREFUSED 127.0.0.1:8080', 'llama-local')
check('hint on ECONNREFUSED', refused !== undefined && refused.includes('start-*.bat'), String(refused))
check('no hint for other provider', localServerFailureHint('fetch failed', 'deepseek') === undefined)
check('no hint for timeout (server up, slow)', localServerFailureHint('connect ETIMEDOUT', 'llama-local') === undefined)
check('no hint for non-connection error', localServerFailureHint('rate limit exceeded', 'llama-local') === undefined)

// --- 3. InfoPanel rows ---------------------------------------------------
const COLS = 110, ROWS = 30
const term = new XTerm({ cols: COLS, rows: ROWS, scrollback: 0, allowProposedApi: true })
class FakeStdout extends Writable {
  columns = COLS; rows = ROWS; isTTY = true
  _write(chunk: unknown, _e: BufferEncoding, cb: () => void) { term.write(String(chunk), cb) }
}
class FakeStderr extends Writable { isTTY = true; _write(_c: unknown, _e: BufferEncoding, cb: () => void) { cb() } }
class FakeStdin extends PassThrough {
  isTTY = true
  setRawMode() { return this }
  ref() { return this }
  unref() { return this }
}

function screen(): string {
  const buf = term.buffer.active
  return Array.from({ length: ROWS }, (_, y) => buf.getLine(buf.baseY + y)?.translateToString(true) ?? '').join('\n')
}

/** Partial channel literal (the established verify-harness pattern: the
 *  screens take partial ports; production always has the full channel). */
function makeChannel(overrides: Record<string, unknown>): Record<string, unknown> {
  return {
    sessionTitle: 'telemetry', sessionId: 'abcd1234', agentId: 'efgh5678',
    cwd: 'C:\\Code\\DST-Moon', displayCwd: 'C:\\Code\\DST-Moon', gitBranch: 'main',
    model: 'Qwen36-35B-ablit', provider: 'llama-local', reasoningEffort: undefined,
    mode: { id: 'default' }, working: false, spinnerMode: 'requesting', status: 'ready',
    tokens: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, peak: {}, idle: {} },
    contextWindow: 262144, tps: undefined, lastUsage: undefined, lastTimings: undefined,
    costReport: undefined, mainCost: {}, subagentCost: [], backgroundJobs: [], subagents: [],
    mcpStatus: () => ['MCP servers (0)'],
    ...overrides,
  }
}

function renderPanel(channel: Record<string, unknown>): Promise<string> {
  return new Promise(resolve => {
    void (async () => {
      const instance = await render(
        <SidePanelRuntimeContext.Provider value={{ runtime: null as never, channel: channel as never }}>
          <InfoPanel width={44} height={26} focused={false} visible />
        </SidePanelRuntimeContext.Provider>,
        { stdin: new FakeStdin() as never, stdout: new FakeStdout() as never, stderr: new FakeStderr() as never, exitOnCtrlC: false, patchConsole: false },
      )
      setTimeout(() => {
        const text = screen()
        instance.unmount()
        resolve(text)
      }, 150)
    })()
  })
}

const settledPanel = await renderPanel(makeChannel({
  lastUsage: { input: 740, output: 356, cacheRead: 11_500, cacheWrite: 0, at: 1 },
  lastTimings: { ttftMs: 2400, prefillTps: 2100, at: 1 },
  tps: 38,
}))
check('settled: first-tok row', settledPanel.includes('First tok') && settledPanel.includes('2.4s'))
check('settled: prefill row', settledPanel.includes('Prefill') && settledPanel.includes('2100 tok/s'))
check('settled: cache row rides cached_tokens', settledPanel.includes('Cache hit') && settledPanel.includes('94.0%'))
check('settled: throughput row stays plain', settledPanel.includes('Throughput') && settledPanel.includes('38 tps'))
check('settled: no warm-up flag at 2.4s', !settledPanel.includes('warm-up'))

const warmPanel = await renderPanel(makeChannel({
  lastTimings: { ttftMs: 75_000, prefillTps: 155, at: 1 },
}))
check('warm-up: 1m15s flagged', warmPanel.includes('First tok') && warmPanel.includes('1m15s') && warmPanel.includes('warm-up'))
check('warm-up: slow prefill shown plain', warmPanel.includes('Prefill') && warmPanel.includes('155 tok/s'))

const emptyPanel = await renderPanel(makeChannel({}))
check('before any request: rows show em dash', emptyPanel.includes('First tok') && /First tok\s+—/.test(emptyPanel))
check('before any request: no phantom prefill', !emptyPanel.includes('tok/s'))

console.log(failed === 0 ? 'ALL PASS' : `${failed} FAILED`)
process.exit(failed === 0 ? 0 : 1)
