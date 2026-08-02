#!/bin/sh
# audit_mask_window_ff4182.sh — on-demand audit of the third masked
# window (14z-49, maintainer-ratified round 64).
#
# THE WINDOW: RAM:$FF4182-$FF41A1, the palette-fade staging buffer's
# slot for select palette-block-A row 14 (docs/atlas/ram.md). It is
# masked out of the legacy oracle because the 14z-49 medallion recolor
# changes that ROM row BY DESIGN, and venue fades stage block-A rows
# through this work-RAM buffer even in legacy replays.
#
# WHAT THIS SCRIPT PROVES (the original 14z-49b attribution, rerun):
# at the historical first-divergence point (05_timeout_idle f9126, the
# match->win fade after the round-1 timeout), on a $FF4140-$FF41DF dump
# of BOTH vanilla and the build under test:
#   1. vanilla's window slot holds vanilla row-14 content;
#   2. the build's window slot holds exactly the ported row (vs2's
#      Donovan-icon row, F-bright) — the designed diff;
#   3. every surrounding buffer byte OUTSIDE the window is identical
#      between the two runs — the blind spot hides the designed diff
#      and NOTHING else.
# If (2) fails: the row source drifted — check med_pal_row14_a.
# If (3) fails: something else now lives in the masked neighborhood —
# STOP and root-cause; do not widen the mask (CLAUDE.md standing
# watch).
#
# WHEN TO RUN: not part of the battery (the battery's masked gate
# already covers everything outside the window). Run on suspicion:
# a new divergence near $FF41xx, a row-14 retune, or before extending
# the window family for a new palette-block port (Huitzil/Pyron).
#
# Usage: ROMDIR=... tests/audit_mask_window_ff4182.sh [rompath_dir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

run_side() { # $1=rompath $2=outsub
    mkdir -p "$WORK/$2"
    DUMPS="9126:ff4140-ff41e0" FRAMES=9180 \
        REPLAY="$REPO/tests/replays/05_timeout_idle.rpl" \
        CHECKSUM_OUT="$WORK/$2/c.log" MAME_SANDBOX="$WORK/$2" \
        MAME_ROMPATH="$1" tools/run_mame.sh vsavj \
        -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
}

run_side "$ROMDIR" van
run_side "$RPDIR;$ROMDIR" pat

python3 - "$WORK" <<'EOF'
import sys, os
work = sys.argv[1]
# dump base ff4140; window = ff4182-ff41a1 -> offsets 0x42-0x61
WIN_LO, WIN_HI = 0x42, 0x62
VAN_ROW = "fffcfdc8fb96f973fcfffbcffa9df97af768f658f447f326ff00fc00f800f014"
PORT_ROW = "fffffda8fc86fb75fa64f743f532f322facef78df458ffd6fb84fc22f922f005"
v = open(os.path.join(work, 'van', 'dump_9126_ff4140.bin'), 'rb').read()
p = open(os.path.join(work, 'pat', 'dump_9126_ff4140.bin'), 'rb').read()
assert len(v) >= 0xA0 and len(p) >= 0xA0, "short dump — replay/run failure"
assert v[WIN_LO:WIN_HI].hex() == VAN_ROW, (
    f"vanilla window slot drifted from the frozen vanilla row:\n"
    f"  got {v[WIN_LO:WIN_HI].hex()}\n  exp {VAN_ROW}\n"
    f"(vanilla ROM or fade path changed?? re-derive the attribution)")
print("  ok: vanilla window slot == vanilla block-A row 14")
assert p[WIN_LO:WIN_HI].hex() == PORT_ROW, (
    f"build window slot != the designed ported row:\n"
    f"  got {p[WIN_LO:WIN_HI].hex()}\n  exp {PORT_ROW}\n"
    f"(med_pal_row14_a drift, or something ELSE is writing the slot — "
    f"root-cause before trusting the mask)")
print("  ok: build window slot == the designed ported row (vs2 Donovan icon)")
outside = [i for i in range(0xA0) if not (WIN_LO <= i < WIN_HI)]
bad = [i for i in outside if v[i] != p[i]]
assert not bad, (
    f"NEIGHBORHOOD DIVERGENCE outside the masked window at "
    f"{['$FF4140+%#x' % i for i in bad]} — the blind spot no longer "
    f"contains the whole diff. STOP: root-cause; do not widen the mask.")
print(f"  ok: all {len(outside)} neighborhood bytes outside the window identical")
EOF
echo "PASS: masked-window ff4182 audit — the blind spot hides the designed diff and nothing else"
