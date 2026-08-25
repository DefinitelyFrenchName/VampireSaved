#!/bin/sh
# test_obj_records.sh — ground truth for tools/oram_obj_records.py.
#
# WHY. The OBJ list is the surface a cross-implementation VIDEO oracle can
# actually stand on. VRAM was tried in 14z-108 and RULED OUT: MAME and jtcps2
# legitimately hold different bytes in the palette and all three scroll
# tilemaps (the palette by HALF), and the same difference appears on STOCK
# vsavj, so that surface can never separate "our port broke something" from
# "these are two implementations". The OBJ list is different in kind — it is
# what the 68k BUILDS, so both implementations should agree on it.
#
# But the core cannot run Lua. All it hands back is a block of SDRAM bytes,
# so the comparison needs a BYTE-LEVEL walker — and a new walker is exactly
# the kind of instrument this project keeps getting burned by (STATE 14z-108:
# the lane's instrument-defect count reached eight). CLAUDE.md §4: a test's
# classification code is validated against known ground truth BEFORE its
# verdicts are trusted.
#
# THE GROUND TRUTH IS THE BEST AVAILABLE ONE: the SAME BYTES walked by TWO
# INDEPENDENT IMPLEMENTATIONS. tests/lua/obj_records_dump.lua walks the live
# MAME machine through the memory-space API; tools/oram_obj_records.py walks
# a raw dump of that same ORAM. They must agree BYTE FOR BYTE. If they ever
# diverge the LUA IS THE AUTHORITY — it reads the machine, the python reads
# a copy.
#
# NOT ROM-FREE and no fixture is committed: ORAM content is ROM-derived
# (rule 7), so the gate regenerates it from the romset each run. MAME only,
# no Verilator — about two minutes.
#
# Usage: ROMDIR=... tests/test_obj_records.sh [build-dir]
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/m3b_merged13}"
RPL="$REPO/tests/replays/36_pick_tenant_cell.rpl"
FRAME=2886                     # the frozen tenant-oracle MAME anchor
TOOL="$REPO/tools/oram_obj_records.py"
fail=0
ok()  { echo "  PASS $1"; }
bad() { echo "  FAIL $1"; fail=1; }

[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset (this gate runs the real romset)"; exit 77; }
[ -d "$REPO/$BUILD/rompath" ] || { echo "SKIP: no $BUILD/rompath"; exit 77; }
: "${MAME_BIN:=$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN (tools/setup_mame.sh)"; exit 77; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

echo "== produce BOTH artifacts from the same machine at frame $FRAME =="
REPLAY="$RPL" DUMP_FRAMES="$FRAME" TRACE_OUT="$W/lua.txt" \
MAME_SANDBOX="$W/box1" MAME_BIN="$MAME_BIN" \
MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
    "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/obj_records_dump.lua" \
    > "$W/lua.log" 2>&1 || { echo "FAIL: the lua OBJ dump did not complete"; tail -3 "$W/lua.log"; exit 1; }

mkdir -p "$W/oram"
DUMPS="$FRAME:700000-711fff" MAME_BIN="$MAME_BIN" \
MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
    "$REPO/tools/run_replay_mame.sh" vsavjw "$RPL" "$W/oram/out.log" "$W/box2" \
    > "$W/oram.log" 2>&1 || { echo "FAIL: the raw ORAM dump did not complete"; tail -3 "$W/oram.log"; exit 1; }

DUMP="$W/oram/dump_${FRAME}_700000.bin"
[ -s "$DUMP" ] || { echo "FAIL: no ORAM dump at $DUMP"; exit 1; }

echo "== 1 the walkers agree, byte for byte =="
grep -a "^F$FRAME " "$W/lua.txt" > "$W/lua_f.txt" || true
python3 "$TOOL" "$DUMP" --frame "$FRAME" > "$W/py_f.txt"
LN=$(wc -l < "$W/lua_f.txt"); PN=$(wc -l < "$W/py_f.txt")
[ "$LN" -gt 0 ] || bad "1z the lua produced NO records — the rig is not reaching the list"
if diff -q "$W/lua_f.txt" "$W/py_f.txt" >/dev/null 2>&1; then
    ok "1a python walker == lua walker, $PN lines, byte for byte"
else
    bad "1a the two walkers DISAGREE (lua $LN lines, python $PN)"
    diff "$W/lua_f.txt" "$W/py_f.txt" | head -6 | sed 's/^/      /'
fi

echo "== 2 the live buffer is DISCRIMINATED from the idle one =="
# CPS-2 ORAM is double-buffered; the live page terminates, the idle one runs
# to the walker's cap. A comparison that cannot tell them apart would compare
# whichever page happened to be first.
python3 "$TOOL" "$DUMP" --frame "$FRAME" --summary > "$W/sum.txt"
grep -q "B0 entries=.* TERMINATES (live)" "$W/sum.txt" \
    && ok "2a B0 terminates and is reported live" \
    || bad "2a B0 was not identified as the live page: $(cat "$W/sum.txt" | tr '\n' ' ')"
grep -q "B1 entries=1024" "$W/sum.txt" \
    && ok "2b B1 runs to the cap (the idle page), so the two are distinguishable" \
    || bad "2b B1 did not run to the cap — re-check the page geometry"

echo "== 3 MUST-FIRE: a one-byte perturbation must change the verdict =="
python3 - "$DUMP" "$W/bad.bin" <<'PY'
import sys
d = bytearray(open(sys.argv[1], 'rb').read())
# entry 4's code word lives at page $708000 + 4*8 + 4; move one bit of it.
off = 0x8000 + 4 * 8 + 4
d[off] ^= 0x01
open(sys.argv[2], 'wb').write(bytes(d))
PY
python3 "$TOOL" "$W/bad.bin" --frame "$FRAME" > "$W/py_bad.txt"
if diff -q "$W/py_f.txt" "$W/py_bad.txt" >/dev/null 2>&1; then
    bad "3a a flipped code bit produced IDENTICAL output — the walker is blind"
else
    ok "3a control fired: a one-bit change in a tile code changes the records"
fi

echo "== 4 MUST-FIRE: a wrong page geometry is REFUSED, not silently walked =="
if python3 "$TOOL" "$DUMP" --frame "$FRAME" --first-page 0x40000 > "$W/py_oob.txt" 2>"$W/py_oob.err"; then
    bad "4a an out-of-range --first-page was accepted"
else
    grep -q "REFUSING" "$W/py_oob.err" \
        && ok "4a control fired: an impossible page offset is refused loudly" \
        || bad "4a it failed, but not with a REFUSING message"
fi

echo
[ "$fail" -eq 0 ] && echo "PASS test_obj_records" || echo "FAIL test_obj_records"
exit "$fail"
