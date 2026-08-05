#!/bin/sh
# test_tenant_select_records.sh — the M3a select-records half: at a
# variant-half tenant id the build must carry the tenant's OWN select
# records and the host's records must return to VANILLA bytes.
#
# WHY (14z-62). The slot-0x0F port displays the tenant's select UI by
# in-place surgery on Jedah's records (tools/select_port.py). De-substituting
# the tenant to id 0x13 replaces that mechanism with six repointed
# variant-half array rows + generator-composed records
# (docs/atlas/select_screen.md; the vanilla-side model gate is
# tests/test_select_arrays.sh). This gate freezes the new mechanism:
#
#   1. STATIC — tools/check_tenant_select.py re-derives the expected
#      composition independently (vs2 image + select_port.PLACEMENTS) and
#      the built image must match: 6 rows repointed, 31 other rows per
#      array vanilla, record headers/coords/entries byte-faithful, and the
#      host's whole select-record block + palette-grid column + shared
#      coord list back to vanilla.
#   2. NEGATIVE CONTROLS — the checker's verdict logic is itself tested
#      (CLAUDE.md §4): a pristine image FAILS (nothing repointed), one
#      flipped byte in a composed record FAILS, one flipped byte in the
#      host block FAILS.
#   3. RUNTIME — the engine agrees: walking the cursor onto the appended
#      cell 0x13 (replay 36) must fetch EXACTLY the predicted row sequence
#      for all three UI pieces, ending on the tenant's composed records —
#      read through $1C(a6)+4 at the record walker, the 14z-61 method.
#
# Usage: ROMDIR=... tests/test_tenant_select_records.sh [outbase]
#   outbase: an existing variant-id build (default: builds one fresh into a
#   temp dir with --tenant-id 0x13 --profile cps2-wide-v1).
# Env: MAME_WIDE_BIN overrides the WIDE MAME binary
#      (default ~/.cache/vampire-saved/mame/cps2). SKIP_RUNTIME=1 skips
#      section 3 (e.g. no WIDE emulator on this machine).
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

OUTBASE="${1:-}"
if [ -z "$OUTBASE" ]; then
    OUTBASE="$WORK/build"
    echo "== 0. building at --tenant-id 0x13 (fresh) =="
    KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open \
--profile cps2-wide-v1 --tenant-id 0x13" \
        tools/build_donovan.sh 6 "$OUTBASE" > "$WORK/build.log" 2>&1 || {
        echo "FAIL: build did not complete"; tail -20 "$WORK/build.log"
        exit 1; }
    tail -2 "$WORK/build.log" | sed 's/^/  /'
fi
[ -d "$OUTBASE/prg" ] || { echo "FAIL: $OUTBASE/prg missing"; exit 1; }

VAN="$WORK/vsavj_data.bin"
VS2="$WORK/vsav2_data.bin"
python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$WORK/vsavj_op.bin" \
    --data-out "$VAN" > /dev/null
python3 tools/cps2_decrypt.py "$ROMDIR/vsav2.zip" "$WORK/vsav2_op.bin" \
    --data-out "$VS2" > /dev/null

echo "== 1. static: composition + host de-substitution =="
if python3 tools/check_tenant_select.py "$OUTBASE/prg" "$VAN" "$VS2" \
        --id 0x13 > "$WORK/static.txt" 2>&1; then
    echo "  ok: 6 rows, 6 composed records, host bytes vanilla"
else
    echo "  FAIL: static check (below)"
    grep "FAIL" "$WORK/static.txt" | head | sed 's/^/        /'
    fail=1
fi

echo "== 2. negative controls: the verdict logic is itself tested =="
# materialise the logical image once for corruption
python3 - "$OUTBASE/prg" "$WORK/img.bin" <<'PY'
import sys, os
sys.path.insert(0, "tools")
import cps2_decrypt as cps
d = sys.argv[1]
names = sorted((n for n in os.listdir(d) if cps._PRG_RE.search(n)),
               key=lambda n: int(cps._PRG_RE.search(n).group(1)))
blob = b"".join(open(os.path.join(d, n), "rb").read() for n in names)
open(sys.argv[2], "wb").write(
    bytes(cps.words_to_logical_bytes(cps.words_from_file_bytes(blob))))
PY
neg() {  # neg <desc> <python-mutation>
    python3 - "$WORK/img.bin" "$WORK/neg.bin" "$WORK/static.txt" <<PY
import sys
d = bytearray(open(sys.argv[1], "rb").read())
$2
open(sys.argv[2], "wb").write(bytes(d))
PY
    if python3 tools/check_tenant_select.py "$WORK/neg.bin" "$VAN" "$VS2" \
            --id 0x13 > /dev/null 2>&1; then
        echo "  FAIL: $1 PASSED the checker — the verdict proves nothing"
        fail=1
    else
        echo "  ok: $1 is caught"
    fi
}
neg "a pristine image (nothing repointed)" "
d[:] = open('$VAN','rb').read()"
neg "one flipped byte in a composed record" "
rec = next(int(l.split('-> ')[1], 16) for l in open(sys.argv[3])
           if l.startswith('ROW portrait p1'))
d[rec + 2] ^= 0xFF   # its budget word"
neg "one flipped byte in the host record block" "
d[0x271CE8 + 2] ^= 0xFF   # Jedah's P1 portrait budget word"

echo "== 3. runtime: the engine fetches the tenant's rows on cell 0x13 =="
if [ "${SKIP_RUNTIME:-0}" = 1 ]; then
    echo "  SKIPPED (SKIP_RUNTIME=1)"
else
    WIDE_BIN="${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
    "$WIDE_BIN" -listfull vsavjw > /dev/null 2>&1 || {
        echo "FAIL: $WIDE_BIN does not know vsavjw (build it: tools/setup_mame.sh)"
        exit 1; }
    # expected sequences: rows 0x01,0x05,0x0A,0x09 (vanilla values frozen by
    # tests/test_select_arrays.sh) then the tenant's composed record, read
    # from the CHECKER's report rather than hard-coded — the gate follows
    # the space model instead of freezing allocator output.
    rowval() { awk -v p="$1" -v s="$2" \
        '$1=="ROW" && $2==p && $3==s {print $NF}' "$WORK/static.txt" \
        | sed 's/0x/00/'; }
    WHEEL="$(awk '$1=="WHEELPTR"{print $2}' "$WORK/static.txt" | sed 's/0x/00/')"
    runtime() {  # runtime <tag> <watch> <expected sequence> [filter]
        WATCH="$2" TRACE_OUT="$WORK/$1.txt" FRAMES=1400 \
        REPLAY="$REPO/tests/replays/36_pick_tenant_cell.rpl" \
        MAME_SANDBOX="$WORK/sbx_$1" MAME_BIN="$WIDE_BIN" \
        MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
            tools/run_mame.sh vsavjw -debug -debugger none \
            -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
            > "$WORK/$1.log" 2>&1 || {
            echo "  FAIL: the $1 tap run did not complete"
            tail -5 "$WORK/$1.log"; fail=1; return; }
        got=$(awk -v skip="${4:-}" '
            {for(i=1;i<=NF;i++) if($i=="A0") a0=$(i+1)}
            $1=="frame" && a0!="00000000" && a0!=skip && a0!=prev {
                printf "%s ", a0; prev=a0 }' "$WORK/$1.txt")
        if [ "$got" = "$3" ]; then
            echo "  ok: $1 — rows 0x01,0x05,0x0A,0x09 then the tenant's record"
        else
            echo "  FAIL: $1 — the engine fetched a different sequence"
            echo "        got:  $got"
            echo "        want: $3"
            fail=1
        fi
    }
    runtime big_portrait "267380,140,r" \
        "0027195e 00271a36 00271bc0 00271b8a $(rowval portrait p1) "
    runtime name_banner "2675a0,100,r" \
        "00272156 0027218e 002721d4 002721c6 $(rowval name_banner p1) "
    # the wheel record pointer PRG:0x2689FE sits immediately before the
    # highlight array; on this build it holds the RELOCATED wheel record —
    # filter that constant, exactly as the vanilla gate does for 0x272A68.
    runtime highlight "268a00,120,r" \
        "002725dc 002726ac 0027268a 00272642 $(rowval highlight p1) " \
        "$WHEEL"
fi

[ "$fail" = 0 ] || { echo "FAIL: tenant select-records gate"; exit 1; }
echo "PASS: tenant select-records gate (static composition + negative"
echo "      controls + the engine's own row sequence onto cell 0x13)"
