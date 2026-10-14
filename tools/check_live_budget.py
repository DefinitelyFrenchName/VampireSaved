#!/usr/bin/env python3
"""check_live_budget.py — the four live documents stay within their size budget (GitHub #282 item F, 14z-201).

  python3 tools/check_live_budget.py              # check the tree
  python3 tools/check_live_budget.py --root DIR   # a copy of the tree (the gate's controls)

WHY THIS EXISTS. The maintainer (#282): the live documents had grown until rules in them were skimmed over — "files
were too large and you ended up glazing over them". The budget, ruled 2026-10-14 and 2026-10-15
(DECISIONS_HISTORY.md "Ruled 2026-10-14 (14z-201) — #282's scope" and "… — #282 item F"): "ideally 200 lines long
and 500 absolute maximum", and a byte cap so a long line cannot meet the line count — "50kB sounds like a good
targer". The `*_HISTORY.md` archives are not held to it (they get an index, tests/test_history_index.sh).

WHAT IT CHECKS, for each of LIVE:
  FAIL  the document is missing, has more than MAX_LINES lines, or more than MAX_BYTES bytes
  WARN  it has more than IDEAL_LINES lines (printed, not failed: 200 is the aim, 500 the limit)
Lines are counted as `wc -l` counts them; bytes are the UTF-8 file size. 50 kB is read as 50,000 bytes.
This file is the one copy of the numbers: tools/check_state_lists.py takes STATE.md's byte cap from here.
ROM-free, emulator-free, well under a second (ci_portable, tests/test_live_budget.sh).
"""
import argparse
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LIVE = ("CLAUDE.md", "STATE.md", "HANDOFF.md", "docs/NEXT_SESSION.md")
IDEAL_LINES = 200
MAX_LINES = 500
MAX_BYTES = 50_000


def measure(root):
    """[(path, lines or None, bytes or None, [failures], [warnings])] for each live document under root."""
    out = []
    for rel in LIVE:
        p = root / rel
        if not p.is_file():
            out.append((rel, None, None, [f"{rel}: MISSING — a live document the budget covers is not in the tree"], []))
            continue
        data = p.read_bytes()
        lines, size = data.count(b"\n"), len(data)
        fails, warns = [], []
        if lines > MAX_LINES:
            fails.append(f"{rel}: {lines} lines, over the {MAX_LINES}-line maximum")
        if size > MAX_BYTES:
            fails.append(f"{rel}: {size:,} bytes, over the {MAX_BYTES:,}-byte cap")
        if lines > IDEAL_LINES:
            warns.append(f"{rel}: {lines} lines, above the {IDEAL_LINES}-line aim")
        out.append((rel, lines, size, fails, warns))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", default=str(REPO), help="the tree to check (default: this repo)")
    a = ap.parse_args()
    rows = measure(Path(a.root))
    for rel, lines, size, fails, warns in rows:
        if lines is not None:
            print(f"  {rel:22} {lines:4} lines {size:7,} bytes")
    for _, _, _, fails, warns in rows:
        for w in warns:
            print(f"WARN  {w}")
        for f in fails:
            print(f"FAIL  {f}")
    nfail = sum(len(r[3]) for r in rows)
    if nfail:
        print(f"live budget: {nfail} failure(s) — move detail to a subject doc or an archive, never into longer lines")
        return 1
    print(f"live budget: {len(LIVE)} documents within {MAX_LINES} lines and {MAX_BYTES:,} bytes "
          f"({sum(1 for r in rows if r[4])} above the {IDEAL_LINES}-line aim)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
