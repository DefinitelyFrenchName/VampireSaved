#!/bin/sh
# test_gfx_tiles.sh — fact-locks for the CPS-2 gfx tile layout understanding
# (M2b groundwork, session 14). Static only: reads reference zips, no MAME.
#
# Locks (measured 2026-07-28, correct Cps2LoadOne-derived canonical form):
#   1. vsav2 vs vhunt2 (siblings): >=200000 tiles match AT THE SAME INDEX
#      -- the sibling pair shares gfx layout, the property every
#      cross-sibling assumption in M2a/M2b rests on.
#   2. vsav2 vs vsav: >=195000 non-blank tiles found content-addressed
#      (art shared but REPACKED), and <10000 at the same index -- the
#      repack fact that makes naive index-preserving porting impossible.
#   3. The naive-slicing trap stays documented: contiguous 32-byte
#      slicing must NOT reproduce lock 2 (cross-set match collapses).
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

python3 "$REPO/tools/gfx_tiles.py" match \
    "$ROMDIR/vhunt2.zip:vh2" "$ROMDIR/vsav2.zip:vs2" > "$W/sib.txt" 2>/dev/null
same=$(sed -n 's/.*same index \([0-9]*\)).*/\1/p' "$W/sib.txt")
if [ "$same" -ge 200000 ]; then
    echo "  ok: sibling pair shares layout ($same tiles at same index)"
else
    echo "FAIL: sibling same-index count $same < 200000"; fail=1
fi

python3 "$REPO/tools/gfx_tiles.py" match \
    "$ROMDIR/vsav.zip:vm3" "$ROMDIR/vsav2.zip:vs2" > "$W/cross.txt" 2>/dev/null
found=$(sed -n 's/.*found-in-A \([0-9]*\) .*/\1/p' "$W/cross.txt")
same=$(sed -n 's/.*same index \([0-9]*\)).*/\1/p' "$W/cross.txt")
if [ "$found" -ge 195000 ] && [ "$same" -lt 10000 ]; then
    echo "  ok: vsav2 art shared-but-repacked vs vsav (found $found, same-index $same)"
else
    echo "FAIL: cross-game match found=$found same=$same (expect >=195000 / <10000)"; fail=1
fi

# 4. OBJ record-format + tile-inventory locks (decoded session 14:
#    format/budget/count/cptr header, (tile,attr) entries, block cells
#    n&~0xF + dy<<4 + (n+dx)&0xF). Numbers measured on the reference
#    images; drift means either the walker or the understanding broke.
python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$W/vsavj_op.bin" \
    --data-out "$W/vsavj_data.bin" > /dev/null 2>&1 || true
JIMG="$W/vsavj_data.bin"; [ -f "$JIMG" ] || JIMG="$REPO/build/out/vsavj_data.bin"
jout=$(python3 "$REPO/tools/obj_records.py" "$JIMG" --base 0 \
    --start 0x248B88 --end 0x26AB88)
echo "$jout" | grep -q "unique expanded tiles 17763" \
    && echo "$jout" | grep -q "band 0xAD3D-0xEEBB: 16669 tiles" \
    && echo "  ok: Jedah OBJ inventory locked (17763 tiles; main band 0xAD3D-0xEEBB)" \
    || { echo "FAIL: Jedah OBJ inventory drifted:"; echo "$jout" | head -3; fail=1; }

[ "$fail" = 0 ] && echo "PASS: gfx tile layout fact-locks" || echo "FAIL: gfx tile layout fact-locks"
exit "$fail"
