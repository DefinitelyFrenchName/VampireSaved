#!/bin/sh
# test_don_column.sh — swordless-421P column KO crash gate (14z-33).
#
# The column's KO records carried vs2's EXTENDED record types
# 0x50/0x52; vsavj's record-type dispatch table ends at entry 0x4F, so
# those types fetched CODE BYTES as jump displacements -> vec3 reset
# (round-43 crash). Fixed by alias remaps proven by vs2's own dispatch
# (0x52==type 6, 0x50==type 0x0F). This gate replays the exact crash
# sequence GUARDED and requires an END-clean run.
#
# Usage: ROMDIR=... tests/test_don_column.sh [rompath_dir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

if POKES="2890:ff8850:00010001" MAME_ROMPATH="$RPDIR;$ROMDIR" \
    tools/run_replay_guarded.sh vsavj \
    "$REPO/tests/replays/50_don_column_ko.rpl" \
    "$WORK/g.log" "$WORK/box" > "$WORK/out.txt" 2>&1; then
    grep -q "^END " "$WORK/g.log" || { echo "FAIL: no END in guard log"; exit 1; }
    echo "  ok: column KO END-clean under guard (no vec3)"
else
    echo "FAIL: guard tripped on the column KO:"; grep -A3 "GUARD TRIPPED" "$WORK/out.txt" | head -6
    exit 1
fi
# ── 14z-46: swordless-deity palette lock (rounds 41/55 arc). The
#    summon's seq-state stub must upload vs2's record 0x2D4 -> P1
#    rows 0x0B/0x0C at f2913 (the per-stub seq_ids map; the old
#    consecutive-id synthesis uploaded 0x2D3 = the yellow deity).
#    Frozen from native vs2 (plant_vs2 replay, f2960). No poke — the
#    palette beat is pre-KO and poke-free frames are choreography-
#    identical to the gate's guarded run history.
mkdir -p "$WORK/pal"
DUMPS="2960:90c160-90c1a0" \
    REPLAY="$REPO/tests/replays/50_don_column_ko.rpl" \
    CHECKSUM_OUT="$WORK/pal/c.log" MAME_SANDBOX="$WORK/pal" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
python3 - "$WORK/pal" <<'EOF2'
import sys, os
FROZEN = "ff00f55cf66ef78ff8aff9bffadffcfffffff0aff0cff0effafffdfff111f007f000fffffdfffcdff9adf87af635ffeafdb8fa86f864f653fbcef88bfe00f002"
d = open(os.path.join(sys.argv[1], 'dump_2960_90c160.bin'),'rb').read()[:0x40]
assert d.hex() == FROZEN, (
    "swordless-deity rows 0x0B/0x0C diverge from native vs2 (yellow "
    "deity = wrong seq record; check [state_hook] seq_ids)")
print("  ok: swordless-deity palette rows native-locked (0x0B/0x0C)")
EOF2
echo "PASS: Donovan column-KO crash gate"
