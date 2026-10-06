#!/bin/sh
# test_emu_run_compare.sh — two emulator-tier runs are compared per row over what BOTH ran and BOTH
# passed (`tools/emu_run_compare.py`, 14z-193, GitHub #122).
#
# WHAT: tools/emu_run_compare.py sums each side's seconds only over rows present in both runs with
#   verdict PASS on both, per lane and kind (gate / control), and counts the rows each run has alone.
# HOW: drives the tool's selftest (two synthetic runs with a FAIL, a SKIP, a TIMEOUT, a control row and
#   a row on each side alone, against fixed expected lines); two controls run copies with one rule of
#   the common set switched off, and each must fail the selftest.
# EXPECTS: the selftest's six lines read as designed and both controls fail on their copies.
#
# WHY. #122 compared PILOT's release tier with the Mac's: the runs differed in content (387 rows
# against 211), two of PILOT's rows were TIMEOUTs at the cap and two FAILs on the environment, so only
# the both-PASS common rows measure the host. The scratch script that answered it was promoted here.
#
# MUST-FIRE: perturbed-copy: verdict-ignored — a copy that sums a common row whatever its verdict must pass the selftest's FAIL/SKIP rows, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: one-side-counted — a copy that counts every row of run A as common must take a row B never ran, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_emu_run_compare.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

make_copy() {  # make_copy <control> — a copy of the tool with ONE rule of the common set switched off
    mkdir -p "$W/$1"; cp tools/emu_run_compare.py "$W/$1/"
    python3 - "$W/$1/emu_run_compare.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "verdict-ignored": ('if g in b and a[g]["verdict"] == "PASS" and b[g]["verdict"] == "PASS"]',
                        'if g in b]  # CONTROL verdict-ignored'),
    "one-side-counted": ('if g in b and a[g]["verdict"] == "PASS" and b[g]["verdict"] == "PASS"]',
                         'if a[g]["verdict"] == "PASS" and b.get(g, {"verdict": "PASS"})["verdict"] == "PASS"]  # CONTROL one-side-counted'),
}
a, b = edits[name]
assert s.count(a) == 1, name
s = s.replace(a, b, 1)
if name == "one-side-counted":   # a row B never ran then sums as 0 s on B, as a careless join would
    a2 = 's[2] += int(b[g]["seconds"])'
    assert s.count(a2) == 1, name
    s = s.replace(a2, 's[2] += int(b[g]["seconds"]) if g in b else 0', 1)
open(p, "w").write(s)
PY
    echo "$W/$1/emu_run_compare.py"
}

echo "== test_emu_run_compare: #122 — two runs' per-row speed over the both-PASS common rows =="
fail=0
T=tools/emu_run_compare.py
case "${VS_CTL:-}" in verdict-ignored|one-side-counted) T="$(make_copy "$VS_CTL")" ;; esac
python3 "$T" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the comparer's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in verdict-ignored one-side-counted; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 '  FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" -eq 0 ]; then echo "PASS: test_emu_run_compare"; else echo "FAIL: test_emu_run_compare"; exit 1; fi
