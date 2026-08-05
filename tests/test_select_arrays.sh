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
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

DATA="$WORK/vsavj_data.bin"
python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$WORK/vsavj_op.bin" \
    --data-out "$DATA" > /dev/null

echo "== 1. static: the measured model holds =="
if python3 tools/select_arrays.py "$DATA" --id 0x13 > "$WORK/static.txt" 2>&1; then
    echo "  ok: four in-emulator cross-checks + 32 variant aliases hold"
else
    echo "  FAIL: the static model no longer describes the reference image"
    sed 's/^/        /' "$WORK/static.txt" | grep -E "!!|FAIL" | head
    fail=1
fi
# The tenant's two longs must still be ALIASES on the reference ROM. If a
# build repointed them, that is the M3a change and it must be deliberate.
if grep -q "P1  PRG:0x267476  currently 0x2719DA (alias of row 0x03)" "$WORK/static.txt" \
   && grep -q "P2  PRG:0x2674F6  currently 0x271DEC (alias of row 0x03)" "$WORK/static.txt"; then
    echo "  ok: id 0x13's rows are Victor aliases on vanilla (the port's target)"
else
    echo "  FAIL: id 0x13's rows are not the expected vanilla aliases"
    grep "PRG:0x2674" "$WORK/static.txt" | head -4
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
# 11_pick_donovan walks the cursor default -> U -> U -> R, ending on Jedah.
# Watch reads of the array region and log the record pointer in A0 at the
# format dispatcher; the sequence of distinct records IS the row sequence.
WATCH="267380,140,r" TRACE_OUT="$WORK/tap.txt" FRAMES=1200 \
REPLAY="$REPO/tests/replays/11_pick_donovan.rpl" MAME_SANDBOX="$WORK/sbx" \
MAME_BIN="${MAME_REF_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}" \
    tools/run_mame.sh vsavj -debug -debugger none \
    -autoboot_script "$REPO/tests/lua/trace_writes.lua" > "$WORK/tap.log" 2>&1 || {
    echo "  FAIL: the tap run did not complete"; cat "$WORK/tap.log" | tail -5; fail=1; }

if [ -f "$WORK/tap.txt" ]; then
    # A null A0 is the pre-select boot hit, not a record fetch — skip it.
    got=$(awk '{for(i=1;i<=NF;i++) if($i=="A0") a0=$(i+1)}
               $1=="frame" && a0!="00000000" && a0!=prev {printf "%s ", a0; prev=a0}' \
              "$WORK/tap.txt")
    want="0027195e 002719da 00271b0e 00271ce8 "
    if [ "$got" = "$want" ]; then
        echo "  ok: cursor path fetched rows 0x01, 0x03, 0x07, 0x0F — exactly"
        echo "      the records the static model puts at those rows"
    else
        echo "  FAIL: the engine fetched a different sequence"
        echo "        got:  $got"
        echo "        want: $want"
        fail=1
    fi
fi

[ "$fail" = 0 ] || { echo "FAIL: select record-array gate"; exit 1; }
echo "PASS: select record-array gate (static model + negative control +"
echo "      the engine's own row sequence)"
