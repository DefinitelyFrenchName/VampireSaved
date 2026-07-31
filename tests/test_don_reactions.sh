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
# KNOWN-PARTIAL (14z-26): the shake->collapse handoff is still
# missing (victim stands after the shake; native vs2 collapses).
# When that lands, STRENGTHEN this gate to assert the collapse node
# instead of tolerating the release.
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
DUMPS="2670:ff8800-ff8830;2690:ff8800-ff8830" \
    REPLAY="$REPO/tests/replays/48_don_immortal_ko.rpl" \
    CHECKSUM_OUT="$WORK/c.log" MAME_SANDBOX="$WORK" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK" <<'EOF2'
import sys, os
work = sys.argv[1]
for fr in (2670, 2690):
    d = open(os.path.join(work, f'dump_{fr}_ff8800.bin'), 'rb').read()
    node = int.from_bytes(d[0x1c:0x20], 'big')
    assert node == 0x157EBC, (
        f"victim node at f{fr} = {node:#x}, expected electrocute shake "
        f"0x157EBC (0x157AC0 = plain hitstun -> hit_class_props_ext "
        f"regressed)")
print("  ok: deity KO routes the electrocute shake (class 0x4E property)")
EOF2
echo "PASS: Donovan hit-class reaction gate"
