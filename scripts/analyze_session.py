#!/usr/bin/env python3
"""DST-Moon session analyzer: hello budget, cache hits, prefix stability.

Reads one dsh engine session log (session.v4.jsonl.zstd) and reports the
local-model facts the TUI cannot show from one request alone:

  1. Hello budget  - provider-reported prompt size of the FIRST conversation
                     request (inputTokens + cacheReadTokens of the first
                     assistant message), plus how much of it llama.cpp served
                     from KV cache left over from earlier sessions.
  2. Cache table   - every settled request's uncached input vs cache-read and
                     the hit rate (llama.cpp prompt_tokens_details.cached_tokens
                     as mapped by the pi-ai adapter -> cacheReadTokens).
  3. Injections    - every durable user/message whose source is not the human
                     (the old time-context plugin pattern). Should be EMPTY on
                     liangshen-preset sessions.
  4. Title requests- session/title-llm-request count. Each is a SEPARATE
                     llama.cpp request sharing almost no prefix with the
                     conversation, so on a single-slot server it evicts the
                     conversation KV cache; the next turn re-prefills.
  5. Prefix audit  - reconstructs the model-visible message surface at each
                     request/header from the durable events and diffs
                     consecutive surfaces: append-only keeps --cache-reuse
                     instant; a divergence BEFORE the previous tail means the
                     next request re-prefixed everything after that point.

Token counts marked "est" are chars/4 estimates (surface text only); the
cache table numbers are provider-reported and exact.

Usage:
  python scripts/analyze_session.py                 # newest llama-local log
  python scripts/analyze_session.py <session.v4.jsonl.zstd | session dir>
  python scripts/analyze_session.py --all           # every llama-local log
"""
import glob
import io
import json
import os
import sys
import datetime

try:
    import zstandard
except ImportError:
    print("pip install zstandard", file=sys.stderr)
    raise SystemExit(2)

SESSIONS_ROOT = os.path.join(os.path.expanduser('~'), '.dsh', 'sessions')


def iter_events(path):
    with open(path, 'rb') as fh:
        reader = zstandard.ZstdDecompressor().stream_reader(fh)
        for line in io.TextIOWrapper(reader, encoding='utf-8', errors='replace'):
            line = line.strip()
            if line:
                try:
                    yield json.loads(line)
                except json.JSONDecodeError:
                    pass


def block_text(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return ''.join(b.get('text', '') for b in content if isinstance(b, dict))
    return ''


def est_tokens(text):
    return max(1, len(text) // 4)


def find_logs():
    hits = []
    for path in glob.glob(os.path.join(SESSIONS_ROOT, '*', '*', 'session.v4.jsonl.zstd')):
        try:
            for ev in iter_events(path):
                if ev.get('type') == 'request/context' and ev.get('data', {}).get('provider') == 'llama-local':
                    hits.append(path)
                    break
        except Exception:
            pass
    hits.sort(key=os.path.getmtime, reverse=True)
    return hits


def surface_entry(ev):
    """One model-visible surface item: (kind, est tokens, head text, detail)."""
    t, d = ev.get('type'), ev.get('data', {})
    if t == 'system/message':
        text = block_text(d.get('message', {}).get('content'))
        return ('system', est_tokens(text), text[:60], 'surfaceOp=' + str(d.get('surfaceOp')))
    if t == 'user/message':
        text = block_text(d.get('content'))
        src = (d.get('source') or {}).get('kind', '?')
        return ('user/' + src, est_tokens(text), text[:60].replace('\n', ' '), '')
    if t == 'assistant/message':
        text = block_text(d.get('message', {}).get('content'))
        return ('assistant', est_tokens(text), text[:60].replace('\n', ' '), '')
    if t == 'tool/call':
        return ('tool-call', est_tokens(json.dumps(d.get('arguments', ''))), str(d.get('name', '?')), '')
    if t == 'tool/result':
        text = block_text(d.get('content'))
        return ('tool-result', est_tokens(text), text[:60].replace('\n', ' '), 'err' if d.get('isError') else '')
    return None


def analyze(path):
    surface = []          # running model-visible surface (list of entries)
    surfaces_at_request = []
    usage_rows, injections, title_requests, contexts = [], [], [], []
    first_conversation_usage = None
    for ev in iter_events(path):
        t, d = ev.get('type'), ev.get('data', {})
        if t == 'request/context':
            contexts.append(d)
        elif t == 'session/title-llm-request':
            title_requests.append(ev.get('time'))
        elif t == 'user/message':
            if (d.get('source') or {}).get('kind') not in (None, 'user'):
                injections.append((d.get('turn'), d.get('step'),
                                   (d.get('source') or {}).get('kind'),
                                   block_text(d.get('content'))[:70].replace('\n', ' ')))
            surface.append(surface_entry(ev) or ('user', 1, '?', ''))
        elif t == 'assistant/message':
            surface.append(surface_entry(ev) or (t, 1, '?', ''))
            # usage rides data.usage (beside data.message)
            u = d.get('usage') or (d.get('message') or {}).get('usage') or {}
            inp, cache = u.get('inputTokens'), u.get('cacheReadTokens')
            if inp is not None or cache is not None:
                inp = inp or 0
                cache = cache or 0
                usage_rows.append((ev.get('seq'), inp, cache, u.get('outputTokens') or 0))
                if first_conversation_usage is None:
                    first_conversation_usage = (inp, cache)
        elif t in ('system/message', 'tool/call', 'tool/result'):
            surface.append(surface_entry(ev) or (t, 1, '?', ''))
        elif t == 'request/header':
            surfaces_at_request.append((ev.get('seq'), list(surface)))

    name = os.path.basename(os.path.dirname(path))
    ws = os.path.basename(os.path.dirname(os.path.dirname(path)))
    when = datetime.datetime.fromtimestamp(os.path.getmtime(path)).strftime('%Y-%m-%d %H:%M')
    models = sorted({c.get('model', '?') for c in contexts})
    windows = sorted({c.get('contextWindow') for c in contexts if c.get('contextWindow')})
    print(f"\n=== {ws}/{name}  ({when}, {os.path.getsize(path) // 1024} KB zstd)")
    print(f"    model {', '.join(models)}  declared window {', '.join(map(str, windows)) or '?'}")

    if first_conversation_usage:
        inp, cache = first_conversation_usage
        print(f"    hello budget: {inp + cache:,} prompt tokens "
              f"({inp:,} uncached + {cache:,} served from leftover KV cache)")
    else:
        print("    hello budget: no settled request in this session")

    if usage_rows:
        print("    cache per request (seq, uncached, cacheRead, hit%, out):")
        for seq, inp, cache, out in usage_rows:
            total = inp + cache
            hit = (cache * 100.0 / total) if total else 0.0
            print(f"      {seq:>4}  {inp:>7,}  {cache:>8,}  {hit:5.1f}%  {out:>6,}")

    if injections:
        print(f"    injections: {len(injections)} non-user user/message events:")
        for turn, step, kind, head in injections[:8]:
            print(f"      turn {turn} step {step} [{kind}] {head}")
        if len(injections) > 8:
            print(f"      ... +{len(injections) - 8} more")
    else:
        print("    injections: none (clean append-only surface)")

    if title_requests:
        print(f"    title LLM requests: {len(title_requests)} "
              f"(separate prompt -> evicts the conversation KV cache once each)")

    mutated = 0
    for (seq_a, prev), (seq_b, cur) in zip(surfaces_at_request, surfaces_at_request[1:]):
        common = 0
        for p, c in zip(prev, cur):
            if p[:3] == c[:3]:
                common += 1
            else:
                break
        if common < len(prev):
            mutated += 1
            at = prev[common] if common < len(prev) else None
            print(f"    prefix MUTATED before request seq {seq_b}: common={common}/{len(prev)}, "
                  f"divergence at {at[0] if at else '?'} est~{at[1] if at else 0} tok: {at[2] if at else ''!r}")
    if surfaces_at_request and mutated == 0:
        print(f"    prefix audit: append-only across all {len(surfaces_at_request)} requests "
              f"(--cache-reuse stays instant)")


def main():
    args = sys.argv[1:]
    if args and args[0] == '--all':
        logs = find_logs()
        if not logs:
            print('no llama-local sessions found under', SESSIONS_ROOT)
            return
        for p in logs:
            analyze(p)
        return
    if args:
        target = args[0]
        if os.path.isdir(target):
            target = os.path.join(target, 'session.v4.jsonl.zstd')
    else:
        logs = find_logs()
        if not logs:
            print('no llama-local sessions found under', SESSIONS_ROOT)
            return
        target = logs[0]
        print(f"(newest llama-local session: {target})")
    analyze(target)


if __name__ == '__main__':
    main()
