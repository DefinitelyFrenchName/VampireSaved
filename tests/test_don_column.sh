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
echo "PASS: Donovan column-KO crash gate"
