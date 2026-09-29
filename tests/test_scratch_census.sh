#!/bin/sh
# test_scratch_census.sh — every scratch program a session wrote is classed, and each class holds
# (`tools/scratch_census.py`, 14z-185b, GitHub #190 P4).
#
# WHAT: tools/scratch_census.py fails on each of its conditions and only then: an UNCLASSED scratch
#   program; a PROMOTED row whose target is untracked, or not named in HANDOFF.md; a CLOSE-CHECK row the
#   close's checks file does not run, or that a tracked file names; a NOT PROMOTED row with no reason;
#   a STALE row; a clean class file passes.
# HOW: drives the tool's selftest (eight cases in a synthetic git repository); seven controls — one per
#   failure condition (#185 item 5) — run copies with that condition's failure turned into a print, and
#   each must fail the selftest.
# EXPECTS: the selftest's eight cases read as designed and all seven controls fail on their copies.
#
# WHY. The close checklist's step 5 promotes scratch whose figures a document quotes; in the 14z-185
# close, rule-checker runs 422, 438 and 439 found the census meant to show that printing its classes and
# reasons while checking only that a reason existed. The maintainer ruled the promotion: "P1+P2, then P4".
#
# MUST-FIRE: perturbed-copy: unclassed-ignored — a copy that does not count an UNCLASSED program must pass that case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: untracked-ignored — a copy that does not count an untracked PROMOTED target must pass that case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: handoff-ignored — a copy that does not count a PROMOTED target missing from HANDOFF.md must pass that case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: unrun-ignored — a copy that does not count a CLOSE-CHECK the checks file never runs must pass that case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: named-ignored — a copy that does not count a CLOSE-CHECK named by a tracked file must pass that case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: noreason-ignored — a copy that does not count a NOT PROMOTED row without a reason must pass that case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: stale-ignored — a copy that does not count a row naming a missing file must pass that case, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_scratch_census.sh      # ci_portable, ~2 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
CTLS="unclassed-ignored untracked-ignored handoff-ignored unrun-ignored named-ignored noreason-ignored stale-ignored"

make_copy() {  # make_copy <control> — a copy of the tool with ONE failure condition turned into a print
    mkdir -p "$W/$1"; cp tools/scratch_census.py "$W/$1/"
    python3 - "$W/$1/scratch_census.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
line = {
    "unclassed-ignored": 'fail("UNCLASSED", p)',
    "untracked-ignored": """fail("PROMOTED", f"{p}: target {arg or '(none)'} is not a tracked file")""",
    "handoff-ignored": 'fail("PROMOTED", f"{p}: HANDOFF.md does not name {arg}")',
    "unrun-ignored": 'fail("CLOSE-CHECK", f"{p}: the checks file runs no command naming {base}")',
    "named-ignored": """fail("CLOSE-CHECK", f"{p}: named by tracked file(s) {', '.join(refs[:3])} — promote it")""",
    "noreason-ignored": 'fail("NO REASON", p)',
    "stale-ignored": 'fail("STALE", f"{p}: no such file")',
}[name]
assert s.count(line) == 1, name
open(p, "w").write(s.replace(line, "print(" + line[len("fail("):] + "  # CONTROL " + name, 1))
PY
    echo "$W/$1/scratch_census.py"
}

echo "== test_scratch_census: #190 P4 — the scratch census =="
fail=0
SC=tools/scratch_census.py
case " $CTLS " in *" ${VS_CTL:-none} "*) SC="$(make_copy "$VS_CTL")" ;; esac
python3 "$SC" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the census's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in $CTLS; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 '  FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: each failure condition fails the census, and a clean class file passes"
else echo "FAIL: test_scratch_census"; exit 1; fi
