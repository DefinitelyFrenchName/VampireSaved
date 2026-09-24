#!/bin/sh
# test_measures_contract.sh — ground truth for THE MEASUREMENT CONTRACT'S READER,
# tests/lib/measures.sh: the `# MEASURES: <name> — <floor>` header grammar, the
# `MEASURED: <name> = <n>` run-time line, the declared-vs-measured readback the
# classifier turns into FAIL, and the undeclared measurement. (GitHub #171 slice Q2,
# ruled 2026-09-24 "Declared/fired grammar".) ROM-free, ~1 s.
#
# WHAT: the measurement contract's reader reads what the grammar says: the header line in
#   the leading comment block (a bare `#` continues it, a non-comment line ends it), the
#   name and integer floor, the run-time line at column 0; a PASS whose declared
#   measurement is absent, below its floor, or whose log prints a name no header declares,
#   classifies FAIL through the shipped classifier; a gate declaring nothing is untouched.
# HOW: synthetic gate scripts and logs of each shape are pushed through the SHIPPED
#   classifier (tests/lib/classify.sh) and reader; two controls (a declaring stub whose
#   log lacks the MEASURED line, one whose measurement is below its floor) must classify
#   FAIL.
# EXPECTS: every synthetic case classifies as the contract states; a red means a runner
#   would read an empty or missing measurement as a green — shape 1b of the M19 release
#   tier, where two gates compared an empty table for four days of green closes.
#
# MUST-FIRE: known-bad: missing-measurement — a synthetic gate declaring `# MEASURES: rows — 1` whose log prints no MEASURED line must classify FAIL through the shipped classifier, or an absent measurement would keep its gate green
# MUST-FIRE: known-bad: below-floor — a synthetic gate declaring a floor of 10 whose log prints `MEASURED: rows = 0` must classify FAIL, or an empty table would keep its gate green
# MUST-FIRE: known-bad: freeze-refused — under FREEZE=1 the guard (vs_meas_guard) handed 0 rows against a floor of 10 must REFUSE (return 1), or the M19 shape — a frozen empty table — would freeze again
# MEASURES: synthetic-cases — 17 the ok/bad checks this gate counts as it runs (dogfood: the runners read this gate too; the floor is the count measured at 14z-180)
#
# WHY. CLAUDE.md §4 [VSP-19]: verdict logic is itself tested. This reader is what every
# runner now trusts to say whether a gate's measurement had anything in it; a reader
# that missed a declaration would silently turn the contract back into prose.
#
# Usage: tests/test_measures_contract.sh    # ci_portable
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
. "$REPO/tests/lib/measures.sh"
. "$REPO/tests/lib/classify.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
rc=0; n_checks=0; ok() { n_checks=$((n_checks + 1)); echo "  ok: $*"; }; bad() { n_checks=$((n_checks + 1)); echo "  FAIL: $*"; rc=1; }

mkgate() {  # mkgate <path> <header lines...>
    _p="$1"; shift
    { echo "#!/bin/sh"; for l in "$@"; do echo "$l"; done; echo 'echo "PASS"'; echo "exit 0"; } > "$_p"
    chmod +x "$_p"
}
classify() {  # classify <gate> <log lines...> -> VS_VERDICT
    _g="$1"; shift; : > "$T/c.log"; for l in "$@"; do echo "$l" >> "$T/c.log"; done
    vs_classify 0 "$T/c.log" 90 "$_g"
}

if [ -n "$VS_CTL" ]; then
    echo "MODE: control $VS_CTL — the known-bad log is pushed through the shipped classifier; this run must FAIL"
    case "$VS_CTL" in
        missing-measurement) mkgate "$T/m.sh" "# m.sh — a stub" "# MEASURES: rows — 1 the table's rows"; classify "$T/m.sh" "PASS: fine" ;;
        below-floor)         mkgate "$T/m.sh" "# m.sh — a stub" "# MEASURES: rows — 10 the table's rows"; classify "$T/m.sh" "PASS: fine" "MEASURED: rows = 0" ;;
        freeze-refused)      mkgate "$T/m.sh" "# m.sh — a stub" "# MEASURES: rows — 10 the table's rows"
                             if ( FREEZE=1 vs_meas_guard "$T/m.sh" rows 0 ); then echo "  the guard ACCEPTED a freeze at 0 rows under a floor of 10"; echo "PASS (the known-bad was NOT caught)"; exit 0
                             else echo "  the guard REFUSED the freeze at 0 rows under a floor of 10"; echo "FAIL (the known-bad was caught — the mode reached the gate's own FAIL)"; exit 1; fi ;;
    esac
    echo "  classified $VS_VERDICT: $VS_DETAIL"
    [ "$VS_VERDICT" = FAIL ] && { echo "FAIL (the known-bad was caught — the mode reached the gate's own FAIL)"; exit 1; }
    echo "PASS (the known-bad was NOT caught)"; exit 0
fi

echo "== 1. the header grammar, in the LEADING COMMENT BLOCK =="
mkgate "$T/g1.sh" "# g1.sh — a gate" "#" "# MEASURES: rows — 12 the rows of the produced table" "# prose" "#" "# MEASURES: hashed-files — 6"
got="$(vs_meas_declared "$T/g1.sh" | tr '\t\n' ': ')"
[ "$got" = "rows:12 hashed-files:6 " ] && ok "two declarations read across a bare # ($got)" || bad "declared read '$got'"
{ echo "#!/bin/sh"; echo "# g2.sh"; echo "set -u"; echo "# MEASURES: late — 1 not a header line"; echo "exit 0"; } > "$T/g2.sh"
[ -z "$(vs_meas_declared "$T/g2.sh")" ] && ok "a MEASURES line below the first code line is NOT a declaration" || bad "a line outside the leading block was read"
mkgate "$T/g3.sh" "# MEASURES: Bad_Name — 1 bad name" "# MEASURES: rows - 1 hyphen not em dash" "# MEASURES: rows — many not an integer"
[ -z "$(vs_meas_declared "$T/g3.sh")" ] && ok "a bad name, a hyphen separator and a non-integer floor are all rejected" || bad "the grammar accepted a malformed line: $(vs_meas_declared "$T/g3.sh")"

echo "== 2. declared vs measured, through vs_meas_read =="
mkgate "$T/g4.sh" "# g4.sh" "# MEASURES: rows — 12 rows" "# MEASURES: files — 6 files"
printf 'PASS\nMEASURED: rows = 15\nMEASURED: files = 6\n' > "$T/g4a.log"; vs_meas_read "$T/g4.sh" "$T/g4a.log"
[ "$VS_MEAS_VERDICT" = OK ] && [ "$VS_MEAS_OK" = 2 ] && ok "both at or above floor: OK (15>=12, 6>=6)" || bad "expected OK, got $VS_MEAS_VERDICT ($VS_MEAS_DETAIL)"
printf 'PASS\nMEASURED: rows = 15\n' > "$T/g4b.log"; vs_meas_read "$T/g4.sh" "$T/g4b.log"
[ "$VS_MEAS_VERDICT" = RED ] && printf '%s' "$VS_MEAS_DETAIL" | grep -q 'files(not measured)' && ok "a declared name never printed: RED ($VS_MEAS_DETAIL)" || bad "missing measurement not RED: $VS_MEAS_VERDICT $VS_MEAS_DETAIL"
printf 'PASS\nMEASURED: rows = 0\nMEASURED: files = 6\n' > "$T/g4c.log"; vs_meas_read "$T/g4.sh" "$T/g4c.log"
[ "$VS_MEAS_VERDICT" = RED ] && printf '%s' "$VS_MEAS_DETAIL" | grep -q 'rows=0<12' && ok "a measurement below its floor: RED ($VS_MEAS_DETAIL)" || bad "below-floor not RED: $VS_MEAS_VERDICT"
printf 'PASS\nMEASURED: rows = 15\nMEASURED: files = 6\nMEASURED: ghost = 3\n' > "$T/g4d.log"; vs_meas_read "$T/g4.sh" "$T/g4d.log"
[ "$VS_MEAS_VERDICT" = RED ] && printf '%s' "$VS_MEAS_DETAIL" | grep -q 'ghost(undeclared)' && ok "a printed name no header declares: RED" || bad "undeclared measurement not RED: $VS_MEAS_VERDICT"
mkgate "$T/g5.sh" "# g5.sh — declares nothing"; printf 'PASS\n' > "$T/g5.log"; vs_meas_read "$T/g5.sh" "$T/g5.log"
[ "$VS_MEAS_VERDICT" = NONE ] && ok "a gate declaring nothing reads NONE" || bad "expected NONE, got $VS_MEAS_VERDICT"
printf 'PASS\n  MEASURED: rows = 15\nMEASURED: files = 6\n' > "$T/g4e.log"; vs_meas_read "$T/g4.sh" "$T/g4e.log"
[ "$VS_MEAS_VERDICT" = RED ] && ok "an indented MEASURED line is prose, not a measurement (column 0 only)" || bad "an indented line was read as a measurement"

echo "== 3. the classifier turns a red block into plain FAIL and leaves the rest alone =="
classify "$T/g4.sh" "PASS: fine" "MEASURED: rows = 15" "MEASURED: files = 6"
[ "$VS_VERDICT" = PASS ] && ok "measured at floor: PASS" || bad "expected PASS, got $VS_VERDICT ($VS_DETAIL)"
classify "$T/g4.sh" "PASS: fine" "MEASURED: rows = 15"
[ "$VS_VERDICT" = FAIL ] && printf '%s' "$VS_DETAIL" | grep -q 'measures RED' && ok "a missing measurement: FAIL ($VS_DETAIL)" || bad "expected FAIL, got $VS_VERDICT"
classify "$T/g5.sh" "PASS: fine"
[ "$VS_VERDICT" = PASS ] && ok "a gate declaring nothing: PASS untouched" || bad "an undeclaring gate was touched: $VS_VERDICT"
: > "$T/skip.log"; echo "SKIP: no build" > "$T/skip.log"; vs_classify 0 "$T/skip.log" 90 "$T/g4.sh"
[ "$VS_VERDICT" = SKIP ] && ok "SKIP is never touched by the measurement read" || bad "a SKIP became $VS_VERDICT"
vs_classify 1 "$T/g4a.log" 90 "$T/g4.sh"
[ "$VS_VERDICT" = FAIL ] && ok "a non-zero exit is FAIL before any read" || bad "exit 1 read as $VS_VERDICT"
# the controls read still comes first: a dead control on a gate that also measures is FAIL for the control
mkgate "$T/g6.sh" "# g6.sh" "# MUST-FIRE: known-bad: flip — must fail" "# MEASURES: rows — 1"
classify "$T/g6.sh" "PASS" "MEASURED: rows = 5"
[ "$VS_VERDICT" = FAIL ] && printf '%s' "$VS_DETAIL" | grep -q 'controls RED' && ok "the controls read comes first: an unfired control is the detail" || bad "expected the controls' FAIL, got $VS_VERDICT ($VS_DETAIL)"

echo "== 4. controls: the two known-bad logs must classify FAIL =="
mkgate "$T/m1.sh" "# m1.sh" "# MEASURES: rows — 1 rows"; classify "$T/m1.sh" "PASS: fine"
[ "$VS_VERDICT" = FAIL ] && vs_ctl_fired missing-measurement "a declaring stub with no MEASURED line classified FAIL" || { vs_ctl_dead missing-measurement "classified $VS_VERDICT"; rc=1; }
mkgate "$T/m2.sh" "# m2.sh" "# MEASURES: rows — 10 rows"; classify "$T/m2.sh" "PASS: fine" "MEASURED: rows = 0"
[ "$VS_VERDICT" = FAIL ] && vs_ctl_fired below-floor "MEASURED: rows = 0 under a floor of 10 classified FAIL" || { vs_ctl_dead below-floor "classified $VS_VERDICT"; rc=1; }
if ( FREEZE=1 vs_meas_guard "$T/m2.sh" rows 0 > "$T/guard.txt" ); then vs_ctl_dead freeze-refused "the guard accepted a freeze at 0 rows under a floor of 10"; rc=1
else vs_ctl_fired freeze-refused "$(head -1 "$T/guard.txt")"; fi
( FREEZE=1 vs_meas_guard "$T/m2.sh" rows 10 >/dev/null ) && ok "the guard accepts a freeze AT the floor (10 >= 10)" || bad "the guard refused a freeze at the floor"
( vs_meas_guard "$T/m2.sh" rows 0 >/dev/null ) && ok "outside FREEZE=1 the guard is silent and returns 0" || bad "the guard refused outside FREEZE=1"

echo "== 5. this gate measures what it declares (dogfood) =="
vs_measured synthetic-cases "$n_checks"   # COUNTED by ok()/bad(), never a constant (rule-checker run 2026-09-24-143, Q1/Q4)

[ "$rc" = 0 ] && echo "PASS: the measurement contract's reader reads what the grammar says" || echo "FAIL"
exit $rc
