#!/bin/sh
# test_expectation_provenance.sh — every frozen expectation file says WHERE ITS
# NUMBERS CAME FROM (14z-128). ROM-free, ~1 s.
#
# WHY. The maintainer's rule for adjudicating a red gate (2026-09-02): "to know
# if we should fix the gate or what it caught, we must use data we can trust,
# and that means measuring or relying on data that is known to be true for it
# was vetted by measurements." A red gate is a QUESTION, and its first question
# is which side rests on a measurement. Measured at the 14z-127 close: 15 of 45
# frozen expectation files declared their provenance nowhere a triage would
# look.
#
# `tests/expected/PROVENANCE.md` is the answer, kept beside the files. This
# gate keeps it complete BOTH WAYS — a file with no row, or a row naming a file
# that is gone, is the drift that would make the page worth less than nothing
# (a register that is confidently incomplete is read as exhaustive).
#
# SCOPE: the FILES directly under tests/expected/. The 43 DIRECTORIES are the
# per-build expectation sets, whose provenance is registry.tsv plus the
# freeze/<name> tag ([VSP-94]) — the page says so, and duplicating that here
# would put two gates on one claim.
#
# Usage: tests/test_expectation_provenance.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
PAGE=tests/expected/PROVENANCE.md
[ -f "$PAGE" ] || { echo "FAIL: $PAGE is missing"; exit 1; }

echo "== 1. every expectation file has a row, every row an existing file"
python3 - "$PAGE" <<'PY' || rc=1
import os, re, sys
page = open(sys.argv[1], encoding="utf-8").read()
# a row is a table line whose first cell is a `backticked` filename
rows = set(re.findall(r'^\|\s*`([^`]+)`\s*\|', page, re.M))
files = {f for f in os.listdir("tests/expected")
         if os.path.isfile(os.path.join("tests/expected", f))
         and f != "PROVENANCE.md" and not f.startswith(".")}
missing = sorted(files - rows)
dead = sorted(r for r in rows if r not in files)
ok = True
if missing:
    ok = False
    print(f"  FAIL: {len(missing)} expectation file(s) with NO provenance row:")
    for m in missing:
        print(f"      {m}")
    print("      Add a row to tests/expected/PROVENANCE.md saying what the")
    print("      numbers describe, what evidence they rest on, and how to")
    print("      re-freeze them. If you cannot say, that is the finding.")
if dead:
    ok = False
    print(f"  FAIL: {len(dead)} provenance row(s) naming a file that is gone:")
    for d in dead:
        print(f"      {d}")
if ok:
    print(f"  ok: {len(files)} expectation files, {len(rows)} rows, complete both ways")
sys.exit(0 if ok else 1)
PY

echo "== 2. every row names an evidence class the page defines"
python3 - "$PAGE" <<'PY' || rc=1
import re, sys
page = open(sys.argv[1], encoding="utf-8").read()
CLASSES = ("in-emulator", "derived", "static", "hash-lock", "registry")
bad = []
for line in page.splitlines():
    m = re.match(r'^\|\s*`([^`]+)`\s*\|([^|]*)\|([^|]*)\|([^|]*)\|', line)
    if not m:
        continue
    rests = m.group(4)
    if not any(c in rests for c in CLASSES):
        bad.append((m.group(1), rests.strip()[:50]))
if bad:
    print(f"  FAIL: {len(bad)} row(s) whose 'rests on' names no defined class:")
    for f, r in bad:
        print(f"      {f}: {r!r}")
    print(f"      Defined classes: {', '.join(CLASSES)}")
    sys.exit(1)
print("  ok: every row's evidence class is one the page defines")
PY

echo "== 3. must-fire controls"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
# A: a row removed -> the file must be reported as unprovenanced
grep -v '^| `registry.tsv`' "$PAGE" > "$T/page_a.md"
if python3 - "$T/page_a.md" >/dev/null 2>&1 <<'PY'
import os, re, sys
page = open(sys.argv[1], encoding="utf-8").read()
rows = set(re.findall(r'^\|\s*`([^`]+)`\s*\|', page, re.M))
files = {f for f in os.listdir("tests/expected")
         if os.path.isfile(os.path.join("tests/expected", f))
         and f != "PROVENANCE.md" and not f.startswith(".")}
sys.exit(0 if not (files - rows) else 1)
PY
then
    echo "  FAIL: control A — a deleted row was NOT caught"; rc=1
else
    echo "  ok: control A — a deleted row is caught as an unprovenanced file"
fi
# B: a row for a file that does not exist -> caught
{ cat "$PAGE"; echo '| `no_such_file.txt` | x | y | in-emulator | z | 14z-1 |'; } > "$T/page_b.md"
if python3 - "$T/page_b.md" >/dev/null 2>&1 <<'PY'
import os, re, sys
page = open(sys.argv[1], encoding="utf-8").read()
rows = set(re.findall(r'^\|\s*`([^`]+)`\s*\|', page, re.M))
files = {f for f in os.listdir("tests/expected")
         if os.path.isfile(os.path.join("tests/expected", f))
         and f != "PROVENANCE.md" and not f.startswith(".")}
sys.exit(0 if not [r for r in rows if r not in files] else 1)
PY
then
    echo "  FAIL: control B — a dead row was NOT caught"; rc=1
else
    echo "  ok: control B — a row naming a missing file is caught"
fi

echo
[ "$rc" = 0 ] && echo "PASS: every frozen expectation says where its numbers came from" \
              || echo "FAIL: see above"
exit $rc
