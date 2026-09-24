#!/bin/sh
# test_bg_leg_shape.sh — NO GATE MAY BACKGROUND AN EMULATOR LEG THAT WRITES ITS
# EXIT STATUS UNDER `set -e` WITHOUT `set +e` INSIDE THE GROUP (14z-171).
# ROM-free, ~2 s. Tool: tools/audit_bg_leg_shape.py (its docstring is the WHY).
#
# WHAT: no gate backgrounds an emulator leg that writes its exit status under `set -e`
#   without `set +e` inside the group — the shape that made nine gates print `exited none`
#   on a green run at 14z-168 and blame the emulator.
# HOW: tools/audit_bg_leg_shape.py reads every tests/*.sh for a backgrounded group that
#   captures `$?` under errexit and classes it SAFE or RISKY; the control deletes one real
#   gate's `set +e` in a copy of the whole tests/ tree and audits that copy.
# EXPECTS: PASS when no group is RISKY; a red names the gate and the group. It does not
#   claim the status file is USED or that the right subshell carries the `set +e` — only
#   that a captured status cannot be lost.
#
# MUST-FIRE: perturbed-copy: plus-e-removed — a copy of the WHOLE tests/ tree with one real gate's `set +e` deleted must be reported RISKY by the auditor (mode: that copy is what section 1 audits, so the run must fail)
#
# WHY A STATIC GATE. The defect is silent on a GREEN run: the leg's artifacts
# are complete, only its status file is missing, so the parent prints
# `exited none` and the reader blames the emulator. It was paid for at 14z-168
# on nine gates, and the first scripted repair put `set +e` on the WRONG
# subshell in three of them — a green run cannot distinguish a robustness fix
# that landed from one that did not ([VSP-19]), so the shape needs a reader.
#
# WHAT IT DOES NOT CLAIM. It does not check that a status file is USED, nor
# that the right subshell got the `set +e` — only that a group which captures
# `$?` under errexit cannot lose it. A group capturing no status is not
# flagged: its verdict comes from its artifacts.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
rc=0

# THE PERTURBATION, one function the control and the mode both call ([VSP-181]):
# a copy of the WHOLE tests/ tree with one real gate's `set +e` deleted. Whole,
# not one file, so what the mode audits is the real input minus one safety.
PSRC=""
perturb() {   # perturb <dest dir>; sets PSRC to the gate it broke
    mkdir -p "$1"
    cp "$REPO"/tests/*.sh "$1/" 2>/dev/null || true
    PSRC="$(command grep -ln 'set +e' "$REPO"/tests/audit_*.sh | head -1)"
    [ -n "$PSRC" ] || { echo "REFUSED: no gate in tests/ carries the safe shape to perturb"; exit 3; }
    sed 's/set +e; //; s/set +e$//' "$PSRC" > "$1/$(basename "$PSRC")"
    cmp -s "$PSRC" "$1/$(basename "$PSRC")" && {
        echo "REFUSED: removing set +e changed nothing in $PSRC — the shape moved"; exit 3; }
    return 0
}

# Under CONTROL the audited tree IS the perturbed copy.
AUD="tests"
if [ "$VS_CTL" = plus-e-removed ]; then
    perturb "$T/mode"; AUD="$T/mode"
    echo "(control mode: auditing $AUD — tests/ with $(basename "$PSRC")'s set +e removed)"
fi

echo "1. the audited tests/ tree carries no unsafe backgrounded emulator leg"
if out1="$(python3 tools/audit_bg_leg_shape.py "$AUD" 2>&1)"; then
    printf '%s\n' "$out1" | sed 's/^/  /'
    echo "  ok: no RISKY group, no UNRESOLVED group"
else
    printf '%s\n' "$out1" | sed 's/^/  /'
    echo "  FAIL: see the RISKY/UNRESOLVED lines above"; rc=1
fi

echo "2. must-fire control: the same auditor over that tree with one real gate's set +e removed"
perturb "$T/bad"
if python3 tools/audit_bg_leg_shape.py "$T/bad" > "$T/bad.log" 2>&1; then
    vs_ctl_dead plus-e-removed "$(basename "$PSRC") with its set +e deleted still read clean" || true
    rc=1
else
    vs_ctl_fired plus-e-removed "$(basename "$PSRC") with its set +e deleted -> $(command grep 'RISKY:' "$T/bad.log" | tr -d ' ')"
fi

echo
[ "$rc" = 0 ] && echo "PASS: no backgrounded emulator leg can lose its exit status" \
              || echo "FAIL: test_bg_leg_shape"
exit $rc
