#!/usr/bin/env python3
"""What in the pipeline still ASSUMES slot 0x0F / Jedah?

Moving the tenant to 0x13 turns every such assumption into a silent wrong
answer. This separates executable assumptions from prose so the move has an
enumerated work list instead of a crash-driven one.

Heuristic: a hit is CODE unless its line is a comment, or it sits inside a
triple-quoted block. Imperfect, so both lists are printed.
"""
import glob
import re

PAT = re.compile(r"0x0f|0x0F|jedah|Jedah|JEDAH")
SKIP = ("select_wheel.py", "check_wheel_walk.py", "audit_id_space.py",
        "wheel_positions.py", "wheel_layout.py")

code, prose = [], []
for path in sorted(glob.glob("tools/*.py") + glob.glob("tools/*.sh")):
    if any(path.endswith(s) for s in SKIP):
        continue
    indoc = False
    for n, line in enumerate(open(path, errors="replace"), 1):
        q = line.count('"""') + line.count("'''")
        was = indoc
        if q % 2:
            indoc = not indoc
        if not PAT.search(line):
            continue
        s = line.strip()
        if was or indoc or s.startswith("#"):
            prose.append((path, n, s))
        else:
            code.append((path, n, s))

print("=== EXECUTABLE assumptions (%d) ===" % len(code))
cur = None
for p, n, s in code:
    if p != cur:
        print("\n%s" % p)
        cur = p
    print("  %4d  %s" % (n, s[:104]))
print("\n=== in comments/docstrings only (%d) — no action, but they will "
      "mislead a reader after the move ===" % len(prose))
from collections import Counter
for p, c in Counter(p for p, _, _ in prose).most_common():
    print("  %-32s %d" % (p, c))
