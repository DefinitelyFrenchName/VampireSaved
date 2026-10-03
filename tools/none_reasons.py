#!/usr/bin/env python3
"""none_reasons.py — every finding of a close's FINDINGS TABLE whose test is `none` says why.

WHY (14z-188 close, rule-checker run 2026-10-02-563): the findings table gives each finding
(a), (b), ... a home and "a test, an open ticket or none". A bare `none` reads the same whether
the finding cannot be tested (a working-practice lesson, a statement) or nobody wrote the test.
homes_tracked.py sees file names and close_findings.py sees addresses; neither sees this. The
row was promoted from that close's scratch check when the ledger came to name it.

WHAT: reads the row LIVE from a STATE file by its title (default "(11) THE FINDINGS TABLE") — in the
newest `## Session` group when the file has one (14z-189: the same title can recur in an older group),
prints its sha1 (12 hex, the same fingerprint homes_tracked.py prints), and for every finding
whose text holds `/ none` requires `/ none (` — a parenthesised reason right after it.

    python3 tools/none_reasons.py [--row TITLE] [STATEFILE]   exit 0 ok, 1 a bare none, 2 no row
    python3 tools/none_reasons.py --selftest [--lenient]

--lenient is a KNOWN-BAD variant (a bare `none` accepted): its self-test must FAIL — the must-fire
control `bare-none-accepted` of tests/test_close_tools.sh.
"""
import hashlib
import re
import sys


def newest_group(text):
    """the newest `## Session` group when the text has one (a row title such as "(12) THE FINDINGS TABLE" can recur in
    an older group until that group rolls off — 14z-189, #204), else the whole text"""
    lines = text.split('\n')
    start = next((i for i, l in enumerate(lines) if l.startswith('## Session ')), None)
    if start is None:
        return lines
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith(('## ', '# '))), len(lines))
    return lines[start:end]


def check(text, title, lenient=False):
    rows = [l for l in newest_group(text) if l.startswith('| **' + title + '**')]
    if len(rows) != 1:
        return 2, [f'rows titled {title!r}: {len(rows)} (want 1)']
    s = rows[0]
    out = ['ROW SHA1 ' + hashlib.sha1(s.encode()).hexdigest()[:12]]
    bad = n = 0
    for p in re.split(r'(?=\([a-z]\) )', s):
        m = re.match(r'\(([a-z])\) ', p)
        if not m or '/ none' not in p:
            continue
        n += 1
        ok = lenient or re.search(r'/ none \(', p) is not None
        bad += not ok
        out.append(('ok    ' if ok else 'NO REASON ') + m.group(1))
    out.append(f'none-tests {n}  without reason {bad}')
    return (1 if bad else 0), out


def selftest(lenient=False):
    t = '(11) THE FINDINGS TABLE'
    good = f'| **{t}** | (a) x — `a.md` / `t.sh`; (b) y — `b.md` / none (a statement) |'
    bare = f'| **{t}** | (a) x — `a.md` / `t.sh`; (b) y — `b.md` / none; (c) z / none (why) |'
    grouped = f'## Session 14z-2 — new\n{good}\n## Session 14z-1 — old\n{bare}\n'
    cases = [(good, 0), (bare, 1), ('no row here', 2), (good + '\n' + good, 2), (grouped, 0)]
    fails = 0
    for text, want in cases:
        got, _ = check(text, t, lenient)
        if got != want:
            fails += 1
            print(f'SELFTEST FAIL: want {want} got {got} on {text[:60]!r}')
    if not fails:
        print(f'SELFTEST PASS ({len(cases)} cases)')
    return 1 if fails else 0


def main(argv):
    if argv[:1] == ['--selftest']:
        return selftest('--lenient' in argv)
    title = '(11) THE FINDINGS TABLE'
    if argv[:1] == ['--row']:
        title, argv = argv[1], argv[2:]
    path = argv[0] if argv else 'STATE.md'
    code, lines = check(open(path, encoding='utf-8').read(), title)
    print('\n'.join(lines) + f'  ({path})')
    return code


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
