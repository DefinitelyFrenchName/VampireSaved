#!/bin/sh
# test_run_record.sh — a runner's record of what it ran on names every change to what it recorded
# (`tools/run_record.py`, 14z-185b, GitHub #189: "R-reach, both runners").
#
# WHAT: tools/run_record.py's records and `compare` mean what they say: one planted change per
#   recorded field — HEAD moved, a tracked file dirtied, one removed, an untracked file added, a
#   submodule dirtied, a reached program edited, a dirty file edited again, a different command
#   line, a changed allow-listed variable — is each NAMED; an untracked build/ product and a record
#   against itself are not differences; a secret-looking variable is neither named nor valued.
# HOW: drives the tool's selftest over a synthetic repository with a submodule; three controls run
#   copies blind to untracked files, blind to the reach, and with the secret filter removed, and
#   each must fail the selftest.
# EXPECTS: the selftest's 14 checks pass and all three controls fail on their copies; a red names
#   the plant compare did not name.
#
# WHY. tests/run_all_emulator.sh's commit.txt recorded HEAD and the paths of dirty TRACKED files
# only, and the 14z-185 close's rule-checker runs 429-431, 434, 435 and 441 each rebuilt, after the
# fact, what a run had executed. The record is written by both runners at a run's start and end
# (silently: bbh's fidelity test compares their output exactly).
#
# MUST-FIRE: perturbed-copy: blind-untracked — a copy whose status leaves out untracked files must miss the planted stray file, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: blind-reach — a copy whose compare never reports the reach must miss the edited program, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: secret-leak — a copy without the secret-name filter must record the planted token variable, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_run_record.sh      # ci_portable, ~5 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

make_copy() {  # make_copy <control> — a copy of the tool (with battery_reach beside it), ONE perturbation
    mkdir -p "$W/$1"; cp tools/run_record.py tools/battery_reach.py "$W/$1/"
    python3 - "$W/$1/run_record.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "blind-untracked": ('"status", "--porcelain", "--untracked-files=all"', '"status", "--porcelain", "--untracked-files=no"'),
    "blind-reach": ('            diffs.append(f"reach: program changed  {p}")\n', '            pass  # CONTROL blind-reach\n'),
    "secret-leak": ("        if SECRETISH.search(k):\n", "        if False:  # CONTROL secret-leak\n"),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/run_record.py"
}

echo "== test_run_record: #189 — what a run ran on =="
fail=0
RR=tools/run_record.py
if vs_ctl_is blind-untracked || vs_ctl_is blind-reach || vs_ctl_is secret-leak; then RR="$(make_copy "$VS_CTL")"; fi
python3 "$RR" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the record's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in blind-untracked blind-reach secret-leak; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 'FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: every planted change to a recorded field is named; a build/ product and a self-comparison are not differences"
else echo "FAIL: test_run_record"; exit 1; fi
