# classify.sh — THE verdict classifier of this tree. One copy, sourced by
# every runner: run_all_static.sh, run_all_emulator.sh and run_battery_m2.sh.
#
#   vs_classify <exit-status> <logfile> [detail-width]
#     sets VS_VERDICT  (PASS | SKIP | FAIL | TIMEOUT)
#     and  VS_DETAIL   (the one line a human reads beside the verdict)
#
# WHY ONE COPY (14z-139). The 14z-135 census found this classifier
# DUPLICATED in the two runners AND DIFFERING: the sweep's copy had the
# TIMEOUT and the exit-0-after-shell-error branches, the static runner's had
# neither, and the battery's `bat` read exit 0 by the SKIP grep alone. So a
# gate that died at a `${VAR:?}` demand after its EXIT trap — exit 0 on macOS
# bash 3.2 ([VSP-176], docs/project/gotchas.md) — was FAIL under the sweep,
# PASS under the pre-commit command and PASS in the battery. The generic
# harness resolved it by lifting the STRONGER copy as its one classifier
# (blackbox-harness lib/sh/classify.sh); this file is the same resolution in
# this tree. The lines below are the sweep's, moved, not rewritten.
#
# EXIT STATUS DECIDES FIRST. A gate that prints `SKIP:` AND exits non-zero is
# a FAILURE, not a skip: it ran, could not complete, and said so. The case is
# not hypothetical — on the first sweep `test_wide_profile.sh` printed
# "SKIPPED: set FBNEO_REF" and exited 2 with "PARTIAL: the emulator superset
# invariant was NOT run", and an exit-status-second classifier called it a
# skip: the ONE gate that justifies modifying an emulator at all read as
# benign. SKIP is only ever exit 0 plus the marker.
#
# THE THREE EXCEPTIONS, each written for a false green that was paid for:
#   1. exit 124 / 137 (the timeout wrapper's) -> TIMEOUT, not FAIL, so a
#      killed gate is never read as a defect in the artifact.
#   2. exit 0 with the shell's OWN `<script>.sh: line N: NAME: message` in
#      the log -> FAIL (14z-134). macOS bash 3.2 returns 0 for a `${VAR:?}`
#      abort once an EXIT trap is armed; the M16 release run recorded a
#      65-minute Verilator gate as `PASS 0s` on four lines of log. The
#      pattern is a parameter abort, `command not found`, a syntax error.
#      The benign look-alike — MAME segfaulting at teardown AFTER the
#      summary line, `line N:  <pid> Segmentation fault: 11` — has digits
#      where the NAME would be and does not match ([MFI-12]).
#   3. exit 0 with `^ *SKIP` -> SKIP; the word SKIP in PROSE is not a marker.
#
# Ground truth: tests/test_static_runner.sh (§1, §8), test_emulator_runner.sh
# (§12) and test_battery_accounting.sh (§3-§6) — every runner is exercised
# against stub gates of each shape, through the shipped code, never a copy.
#
# NOTE LINES ARE NOT VERDICTS (14z-141). A gate may print `NOTE: <key> <value>`
# at column 0 beside its normal output and still exit 0 with its usual PASS: a
# verdict is per GATE, a NOTE is per NUMBER, and one gate can report several.
# This classifier deliberately does not know about them - adding a fifth
# verdict here would have to reach all three runners and their ground truths,
# reopening the divergence 14z-139 closed. `run_all_static.sh` surfaces them in
# an advisory block instead; `test_static_runner.sh` section 9 is the proof.

# THE CONTROLS CONTRACT IS READ HERE, NOT AS A FIFTH VERDICT (14z-147, step
# two of the must-fire ruling, STATE 14z-145 point 4: "NO fourth verdict"). An
# optional 4th argument names the gate SCRIPT; when given and the verdict is
# PASS, the header's `# MUST-FIRE:` declarations are compared with the log's
# `CONTROL FIRED:` / `CONTROL DEAD:` lines (tests/lib/controls.sh, the one
# reader) and a red block — a declared control that did not fire, a DEAD
# line, a firing no header declares — turns the verdict into plain FAIL. A
# gate with no declaration is left alone (UNDECLARED is counted by the
# runners as a NOTE, never failed here: 236 gates predate the grammar).
# SKIP and FAIL are never touched: a skipped gate ran nothing, a failed gate
# is already red.
[ -n "${REPO:-}" ] && [ -f "$REPO/tests/lib/controls.sh" ] && . "$REPO/tests/lib/controls.sh"

vs_classify() {
    _st="$1"; _log="$2"; _w="${3:-90}"; _gate="${4:-}"
    _vs_classify_base "$_st" "$_log" "$_w"
    [ "$VS_VERDICT" = PASS ] && [ -n "$_gate" ] && [ -f "$_gate" ] || return 0
    command -v vs_ctl_read >/dev/null 2>&1 || return 0
    vs_ctl_read "$_gate" "$_log"
    if [ "$VS_CTL_VERDICT" = RED ]; then
        VS_VERDICT=FAIL; VS_DETAIL="$(printf '%s' "$VS_CTL_DETAIL" | cut -c1-"$_w")"
    fi
    return 0
}

# THE EXECUTABLE CONTROL'S VERDICT (14z-147) — one copy, here, so the runners
# carry no second shell-error regex (test_static_runner §8 locks that). A gate
# run under `CONTROL=<name>` must reach its OWN FAIL:
#   HONOURED  exit non-zero and no crash — the perturbation was caught
#   LIES      exit 0 (or a SKIP) — the perturbation left the gate green
#   REFUSED   the gate printed `REFUSED: CONTROL=` — a declared name it never reads
#   DIED      the shell's own error line or a Python traceback — a crash is
#             not a verdict ([VSP-108])
#   TIMEOUT   the wrapper's exits, as for any gate
vs_classify_control() {  # vs_classify_control <exit-status> <logfile>
    _cst="$1"; _clog="$2"
    if grep -qa '^REFUSED: CONTROL=' "$_clog"; then
        VS_CTL_EXEC=REFUSED; VS_CTL_EXEC_DETAIL="declared in the header, not a mode of the gate"; return 0
    fi
    _vs_classify_base "$_cst" "$_clog" 90
    case "$VS_VERDICT" in
    TIMEOUT) VS_CTL_EXEC=TIMEOUT; VS_CTL_EXEC_DETAIL="$VS_DETAIL" ;;
    PASS|SKIP) VS_CTL_EXEC=LIES; VS_CTL_EXEC_DETAIL="exit $_cst under its own perturbation — the control tests nothing" ;;
    FAIL)
        if [ "$_cst" = 0 ] || grep -qa '^Traceback' "$_clog"; then
            VS_CTL_EXEC=DIED; VS_CTL_EXEC_DETAIL="a crash is not a verdict: $(grep -aE '\.sh: line [0-9]+: [A-Za-z_][A-Za-z0-9_]*: |^Traceback|Error' "$_clog" | head -1 | cut -c1-90)"
        else
            VS_CTL_EXEC=HONOURED; VS_CTL_EXEC_DETAIL="reached the gate's own FAIL (exit $_cst)"
        fi ;;
    esac
    return 0
}

_vs_classify_base() {
    _st="$1"; _log="$2"; _w="${3:-90}"
    if [ "$_st" = 124 ] || [ "$_st" = 137 ]; then
        VS_VERDICT=TIMEOUT; VS_DETAIL="killed (exit $_st)"; return 0
    fi
    if [ "$_st" != 0 ]; then
        VS_VERDICT=FAIL
        VS_DETAIL="exit $_st: $(grep -aE '^ *(SKIP|PARTIAL)|FAIL|ERROR|Traceback|not found' "$_log" | tail -1 | cut -c1-"$_w")"
        return 0
    fi
    if grep -qaE '\.sh: line [0-9]+: [A-Za-z_][A-Za-z0-9_]*: ' "$_log"; then
        VS_VERDICT=FAIL
        VS_DETAIL="exit 0 after a shell error: $(grep -aE '\.sh: line [0-9]+: [A-Za-z_][A-Za-z0-9_]*: ' "$_log" | head -1 | cut -c1-"$_w")"
        return 0
    fi
    if grep -qaE '^ *SKIP' "$_log"; then
        VS_VERDICT=SKIP
        VS_DETAIL="$(grep -aE '^ *SKIP' "$_log" | head -1 | cut -c1-"$_w")"
        return 0
    fi
    VS_VERDICT=PASS; VS_DETAIL=""
    return 0
}
