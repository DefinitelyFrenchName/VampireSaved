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

vs_classify() {
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
