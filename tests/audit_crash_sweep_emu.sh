#!/bin/sh
# audit_crash_sweep_emu.sh — THE EMULATOR ROWS OF THE CRASH SWEEP (#310, 14z-218): tests/test_crash_sweep.sh --tier emulator.
#
# WHAT: the rows of tests/expected/crash_sweep.tsv whose target gate needs an emulator (audit_victim_parity,
#   test_obj_records) and, on a Linux host with podman, the `linux` rows (audit_release_linux_cleanhost): every call of
#   tests/lib/controls.sh `vs_ctl_show_err` in those gates proven by a planted crash, as tests/test_crash_sweep.sh proves the
#   static gates' calls (its header is the specification; this script selects the tier and judges the three controls from its output).
# HOW: runs tests/test_crash_sweep.sh with `--tier emulator`, passing CONTROL through, prints its output, and judges the
#   three controls itself from it: each control's own `CONTROL FIRED:` line there is re-emitted as this gate's firing,
#   anything else is this gate's CONTROL DEAD (so its verdict lines are its own code, not a copy). Exits with the inner
#   status (1 if a control is dead).
# EXPECTS: the static gate's EXPECTS for the emulator rows; ROMDIR set (the target gates need the reference sets).
# FOLLOWS: tests/test_crash_sweep.sh tools/crash_sweep.py tests/lib/crash_sweep.sh tests/lib/controls.sh
#   tests/lib/classify.sh tests/expected/crash_sweep.tsv
#
# MUST-FIRE: known-bad: helper-neutered — as tests/test_crash_sweep.sh's: every emulator site row's kb leg (the helper neutered) must read HONOURED (in-gate; mode: the fx legs run the neutered copy, so the gate FAILs)
# MUST-FIRE: perturbed-copy: row-dropped — as tests/test_crash_sweep.sh's: the table without its first site row leaves that site UNCOVERED (in-gate; mode: the check reads that copy, so the gate FAILs)
# MUST-FIRE: shadow-tool: shim-inert — as tests/test_crash_sweep.sh's: a never-planting shim makes the first emulator row's fx leg read HONOURED with no planted call (in-gate; mode: every row runs that copy, so the gate FAILs)
#
# WHY: #310 — test_crash_sweep.sh is static-tier; its emulator rows need MAME and the builds, so they run in the
#   emulator tier (tests/ci_emulator.tsv) from this wrapper.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd -P)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: audit_crash_sweep_emu — mktemp -d failed"; exit 2; }
trap 'rm -rf "$W"' EXIT
trap 'exit 143' INT TERM
/bin/sh "$REPO/tests/test_crash_sweep.sh" --tier emulator > "$W/inner.log" 2>&1; rc=$?
grep -av '^CONTROL \(FIRED\|DEAD\): ' "$W/inner.log"
for c in helper-neutered row-dropped shim-inert; do
    l="$(grep -am1 "^CONTROL FIRED: $c — " "$W/inner.log")"
    if [ -n "$l" ]; then vs_ctl_fired "$c" "${l#CONTROL FIRED: $c — }"
    elif [ -z "$VS_CTL" ]; then
        vs_ctl_dead "$c" "the emulator tier printed no firing for it: $(grep -am1 "^CONTROL DEAD: $c — " "$W/inner.log" | cut -c1-160)" || rc=1
    fi   # under a mode the inner gate's in-gate controls may legitimately not run; its exit is the verdict
done
exit "$rc"
