#!/bin/sh
# test_don_reactions.sh — ported-move hit-class reaction gate (14z-26).
#
# Locks the hit-class property table extension (data_port
# hit_class_props_ext): vs2 classes 0x4E-0x53 routed correctly. Probe:
# replay 48 (Change Immortal deity hit kills P2 at HP=1). Without the
# extension the victim takes plain hitstun (node 0x157AC0) and stands
# back up; with it the electrocute/special-finish reaction fires
# (shake node 0x157EBC family at the KO).
#
# STRENGTHENED 14z-27: the deity's 7 attack records are remapped to
# the native electric class 0x04 (region_fix rows) — the victim must
# run the full native electrocute death and SETTLE ON the grounded
# node 0x158210 (the same terminal node as any healthy electric KO).
#
# Usage: ROMDIR=... tests/test_don_reactions.sh [rompath_dir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

POKES="2600:ff8850:00010001" \
DUMPS="2670:ff8800-ff8830;2950:ff8800-ff8830;3030:ff8800-ff8830" \
    REPLAY="$REPO/tests/replays/48_don_immortal_ko.rpl" \
    CHECKSUM_OUT="$WORK/c.log" MAME_SANDBOX="$WORK" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK" <<'EOF2'
import sys, os
work = sys.argv[1]
d = open(os.path.join(work, 'dump_2670_ff8800.bin'), 'rb').read()
node = int.from_bytes(d[0x1c:0x20], 'big')
assert 0x157C00 <= node <= 0x1585FF, (
    f"victim not in electric reaction at f2670: {node:#x} "
    f"(plain hitstun/idle -> class remap regressed)")
for fr in (2950, 3030):
    d = open(os.path.join(work, f'dump_{fr}_ff8800.bin'), 'rb').read()
    node = int.from_bytes(d[0x1c:0x20], 'big')
    assert node == 0x158210, (
        f"victim node at f{fr} = {node:#x}, expected grounded death "
        f"0x158210 (idle loop = the round-39 neutral-pose bug)")
print("  ok: deity KO runs the full native electric death (grounded at 0x158210)")
EOF2
echo "PASS: Donovan hit-class reaction gate"
