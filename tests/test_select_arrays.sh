#!/bin/sh
# test_select_arrays.sh — freeze the select-screen record-pointer array, the
# table M3a's tenant move depends on.
#
# WHY (14z-61). The port displays the tenant's select portrait today by
# IN-PLACE record surgery on Jedah's records (tools/select_port.py), which
# works only because the tenant occupies slot 0x0F. Moving it to id 0x13
# needs its OWN records, and the open question was how much machinery that
# costs. Measurement says: two longs. The array is 32 rows per player,
# indexed by the cell/id with NO 4-bit fold, and rows 0x10-0x1F are variant
# aliases — so id 0x13 has a first-class row that no legacy id can reach.
#
# This gate exists so that answer cannot rot silently. Three sections:
#   1. STATIC — the model holds against the reference image: the four
#      in-emulator cross-checks, and all 32 variant aliases.
#   2. NEGATIVE CONTROL — a one-byte corruption of the array must FAIL the
#      static check. A model that cannot be broken is not being tested.
#   3. RUNTIME — the engine itself confirms the mapping: hovering four known
#      cells must fetch exactly the four frozen records, read through
#      $1C(a6)+4 at the record walker PRG:0x01AFA6. Static row arithmetic is
#      a claim until the engine agrees with it (the house lesson).
#
# Usage: ROMDIR=... tests/test_select_arrays.sh
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

DATA="$WORK/vsavj_data.bin"
decrypt_view vsavj "$WORK/vsavj_op.bin" "$DATA"

echo "== 1. static: the measured model holds =="
if python3 tools/select_arrays.py "$DATA" --id 0x13 > "$WORK/static.txt" 2>&1; then
    echo "  ok: four in-emulator cross-checks + 32 variant aliases hold"
else
    echo "  FAIL: the static model no longer describes the reference image"
    sed 's/^/        /' "$WORK/static.txt" | grep -E "!!|FAIL" | head
    fail=1
fi
# The tenant's SIX longs (three pieces x P1/P2) must still be Victor aliases
# on the reference ROM. If a build repointed them, that is the M3a change
# and it must be deliberate rather than discovered.
miss=0
for row in \
  "id 0x13 owns  P1 PRG:0x267476 -> 0x2719DA   P2 PRG:0x2674F6 -> 0x271DEC" \
  "id 0x13 owns  P1 PRG:0x2675F6 -> 0x272172   P2 PRG:0x267676 -> 0x273080" \
  "id 0x13 owns  P1 PRG:0x268A4E -> 0x272594   P2 PRG:0x268ACE -> 0x2727C0"
do
    grep -qF "$row" "$WORK/static.txt" || { echo "  missing: $row"; miss=1; }
done
if [ "$miss" = 0 ]; then
    echo "  ok: all six of id 0x13's rows are Victor aliases on vanilla"
else
    echo "  FAIL: id 0x13's rows are not the expected vanilla aliases"
    fail=1
fi
# And the wheel record pointer that sits immediately before the highlight
# array must still be where the relocation work expects it (14z-60r).
if grep -qF "PRG:0x2689FE -> 0x272A68" "$WORK/static.txt"; then
    echo "  ok: the adjacent wheel record pointer is unmoved"
else
    echo "  FAIL: the wheel record pointer at PRG:0x2689FE moved or changed"
    fail=1
fi

echo "== 2. negative control: a corrupted array must FAIL =="
python3 - "$DATA" "$WORK/corrupt.bin" <<'PY'
import sys
d = bytearray(open(sys.argv[1], "rb").read())
d[0x267466] ^= 0xFF          # one byte of Jedah's P1 row
open(sys.argv[2], "wb").write(d)
PY
if python3 tools/select_arrays.py "$WORK/corrupt.bin" > "$WORK/neg.txt" 2>&1; then
    echo "  FAIL: a corrupted array PASSED — the check proves nothing"
    fail=1
else
    echo "  ok: one flipped byte in row 0x0F is caught"
fi

echo "== 3. runtime: the engine fetches the rows the model predicts =="
# 11_pick_donovan walks the cursor default -> U -> U -> R, ending on Jedah,
# i.e. rows 0x01, 0x03, 0x07, 0x0F. Watch reads of each array and log the
# record pointer in A0 at the format dispatcher; the sequence of distinct
# records IS the row sequence. All three UI pieces, because the port's
# select surgery touches all three and only the first was measured at first.
#
# The highlight stream additionally interleaves a CONSTANT record: the wheel
# record pointer at PRG:0x2689FE sits immediately before that array. Filter
# it rather than pretend it is not there.
runtime() {  # runtime <tag> <watch> <expected sequence> [filter]
    WATCH="$2" TRACE_OUT="$WORK/$1.txt" FRAMES=1200 \
    REPLAY="$REPO/tests/replays/11_pick_donovan.rpl" MAME_SANDBOX="$WORK/sbx_$1" \
    MAME_BIN="${MAME_REF_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}" \
        tools/run_mame.sh vsavj -debug -debugger none \
        -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
        > "$WORK/$1.log" 2>&1 || {
        echo "  FAIL: the $1 tap run did not complete"; tail -5 "$WORK/$1.log"
        fail=1; return; }
    got=$(awk -v skip="${4:-}" '
        {for(i=1;i<=NF;i++) if($i=="A0") a0=$(i+1)}
        $1=="frame" && a0!="00000000" && a0!=skip && a0!=prev {
            printf "%s ", a0; prev=a0 }' "$WORK/$1.txt")
    if [ "$got" = "$3" ]; then
        echo "  ok: $1 — rows 0x01, 0x03, 0x07, 0x0F fetched exactly"
    else
        echo "  FAIL: $1 — the engine fetched a different sequence"
        echo "        got:  $got"
        echo "        want: $3"
        fail=1
    fi
}
runtime big_portrait "267380,140,r" "0027195e 002719da 00271b0e 00271ce8 "
runtime name_banner  "2675a0,100,r" "00272156 00272172 002721aa 0027221a "
# 002689fa is a boot-time artefact of the wider window; 00272a68 is the
# wheel record (PRG:0x2689FE), constant across the whole select screen.
runtime highlight    "268a00,120,r" "002725dc 00272594 00272532 002724a2 " \
                     "00272a68"

[ "$fail" = 0 ] || { echo "FAIL: select record-array gate"; exit 1; }
echo "PASS: select record-array gate (static model + negative control +"
echo "      the engine's own row sequence)"
