#!/bin/sh
# test_tenant_select_records.sh — the M3a select-records half: at a
# variant-half tenant id the build must carry the tenant's OWN select
# records and the host's records must return to VANILLA bytes.
#
# WHY (14z-62/62e). The slot-0x0F port displays the tenant's select UI by
# in-place surgery on Jedah's records (tools/select_port.py). De-substituting
# the tenant to id 0x13 replaces that mechanism with NINE repointed
# variant-half array rows (portrait/name/highlight x P1+P2, splash P1/P2,
# win quote) + generator-composed records
# (docs/game/atlas/select_screen.md; the vanilla-side model gate is
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
    echo "  ok: 9 rows, 9 composed records, host bytes vanilla"
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
    runtime() {  # runtime <tag> <replay> <watch> <expected sequence> [filter]
        WATCH="$3" TRACE_OUT="$WORK/$1.txt" FRAMES="${RT_FRAMES:-1400}" \
        REPLAY="$REPO/tests/replays/$2" \
        MAME_SANDBOX="$WORK/sbx_$1" MAME_BIN="$WIDE_BIN" \
        MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
            tools/run_mame.sh vsavjw -debug -debugger none \
            -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
            > "$WORK/$1.log" 2>&1 || {
            echo "  FAIL: the $1 tap run did not complete"
            tail -5 "$WORK/$1.log"; fail=1; return; }
        # dedupe mode: consecutive (default) for single-cursor windows;
        # "first" for windows both cursors interleave (order of FIRST
        # appearance, which is deterministic: join, then each press).
        if [ "${6:-}" = first ]; then
            got=$(awk -v skip="${5:-}" '
                {for(i=1;i<=NF;i++) if($i=="A0") a0=$(i+1)}
                $1=="frame" && a0!="00000000" && a0!=skip && !seen[a0]++ {
                    printf "%s ", a0 }' "$WORK/$1.txt")
        else
            got=$(awk -v skip="${5:-}" '
                {for(i=1;i<=NF;i++) if($i=="A0") a0=$(i+1)}
                $1=="frame" && a0!="00000000" && a0!=skip && a0!=prev {
                    printf "%s ", a0; prev=a0 }' "$WORK/$1.txt")
        fi
        if [ "$got" = "$4" ]; then
            echo "  ok: $1 — vanilla rows then the tenant's record"
        else
            echo "  FAIL: $1 — the engine fetched a different sequence"
            echo "        got:  $got"
            echo "        want: $4"
            fail=1
        fi
    }
    # P1 cursor (replay 36): rows 0x01 -> 0x05 -> 0x0A -> 0x09 -> 0x13
    runtime big_portrait 36_pick_tenant_cell.rpl "267380,140,r" \
        "0027195e 00271a36 00271bc0 00271b8a $(rowval portrait p1) "
    runtime name_banner 36_pick_tenant_cell.rpl "2675a0,100,r" \
        "00272156 0027218e 002721d4 002721c6 $(rowval name_banner p1) "
    # the wheel record pointer PRG:0x2689FE sits immediately before the
    # highlight array; on this build it holds the RELOCATED wheel record —
    # filter that constant, exactly as the vanilla gate does for 0x272A68.
    runtime highlight 36_pick_tenant_cell.rpl "268a00,120,r" \
        "002725dc 002726ac 0027268a 00272642 $(rowval highlight p1) " \
        "$WHEEL"
    # P2 cursor (replay 37, +0x80 arrays): join fetches the P2 default row
    # 0x05, then L -> 0x0A, D -> 0x09, D -> 0x13.
    runtime p2_portrait 37_p2_pick_tenant.rpl "2674aa,80,r" \
        "00271e48 00271fd2 00271f9c $(rowval portrait p2) "
    runtime p2_highlight 37_p2_pick_tenant.rpl "268a82,80,r" \
        "002728c8 002728a6 00272866 $(rowval highlight p2) "
    # The NAME piece is asymmetric (measured 14z-62): BOTH players' name
    # banners read the P1 ARRAY (each indexed by its own cell), so on the 2P
    # replay the P1 name array serves P1's row 0x01 and P2's row sequence,
    # ending on the tenant's P1 name record. First-appearance order is
    # deterministic (join, then each P2 press).
    runtime p2_name_via_p1 37_p2_pick_tenant.rpl "2675a0,100,r" \
        "00272156 0027218e 002721d4 002721c6 $(rowval name_banner p1) " \
        "" first
    # VS SPLASH (14z-62e; fires at the versus screen, ~frame 2599 on this
    # replay): the CPU opponent's VANILLA splash_p2 row (0x06 for this
    # replay's ladder draw) interleaves with the TENANT's composed
    # splash_p1 record — the engine serving the tenant's own splash.
    # (The win-quote piece fires only at a match win; statics + alias
    # anchors cover it until a 0x13 win replay exists.)
    RT_FRAMES=2800 runtime splash 36_pick_tenant_cell.rpl "2672aa,100,r" \
        "002738b8 $(rowval splash_p1 p1) " "" first
    # ...and the +0x80 name structure has NO consumer on any measured path
    # (0 reads through 2P select, confirm, splash, match start). The
    # composed row is kept for safety; this asserts the measured negative
    # so the gate speaks up if some path DOES start reading it.
    WATCH="26762a,80,r" TRACE_OUT="$WORK/p2name_neg.txt" FRAMES=1400 \
    REPLAY="$REPO/tests/replays/37_p2_pick_tenant.rpl" \
    MAME_SANDBOX="$WORK/sbx_p2name_neg" MAME_BIN="$WIDE_BIN" \
    MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
        tools/run_mame.sh vsavjw -debug -debugger none \
        -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
        > "$WORK/p2name_neg.log" 2>&1 || {
        echo "  FAIL: the p2-name negative tap run did not complete"
        tail -5 "$WORK/p2name_neg.log"; fail=1; }
    # (a frame-1 boot-scan hit with A0=00000000 is expected — the same
    # boot-time artefact class the vanilla gate notes; a REAL consumer
    # carries the record pointer in A0)
    nreads=$(awk '{for(i=1;i<=NF;i++) if($i=="A0") a0=$(i+1)}
                  $1=="frame" && a0!="00000000" {n++} END {print n+0}' \
             "$WORK/p2name_neg.txt")
    if grep -q "^END" "$WORK/p2name_neg.txt" && [ "$nreads" = 0 ]; then
        echo "  ok: p2 name array (+0x80) unconsumed, as measured"
    else
        echo "  FAIL: the +0x80 name array WAS read ($nreads hits, or no END"
        echo "        line) — the 14z-62 'no consumer' finding no longer"
        echo "        holds; re-measure before trusting the name model"
        fail=1
    fi
fi

echo "== 4. de-substitution acceptance: picking the HOST re-converges =="
# Replay 11 picks slot 0x0F. On slot-substituted builds that loads the
# tenant and diverges from vanilla forever (class `diverge 890`). On a
# variant-id build the host is HIMSELF again, so the same replay must
# NOTE (14z-64): compared on the V2 masked basis — the round-64 mask
# plus the medallion rows' palette staging slots ($FF41C2-E1 row 0x16,
# $FF4222-41 row 0x19, $FF4242-61 row 0x1A; the staging area is
# $FF3F02 + row*0x20 and the ratified $FF4182 window is row 0x14's
# slot — same mechanism, sibling slots, part of the bundle
# ratification). The vanilla logs under this basis live in
# tests/expected/vsavj/masked-v2/ (regenerated deterministically from
# the frozen vanilla oracle).
# measure as the §4 v3 BOUNDED WINDOW (PENDING RATIFICATION in the
# re-freeze bundle). History: 14z-62c measured window 890-2362 ($FF06D1
# menu counter tail); 14z-63 wheel bank-5 moved it to 889-2415 (onset =
# the drawer bank word $FFB818 <- #$3000 written by the select init one
# frame before the old record-pointer-cache onset; end = the VS-phase
# re-init 0x5FD02 rewriting it); 14z-63 medallion palettes transiently
# added a fade-staging flicker at 2836 ($FF406A, one frame); 14z-64's
# mid-row march retarget REMOVED it again (the marchers no longer write
# rows 0x16/0x19 on select, so the transition fade never stages the
# changed rows) — measured: the flicker inventory is EMPTY and the
# window is unchanged, so the class reverts to the plain bounded
# window. This section is the reason the whole slot-row audit exists —
# it caught the palette/sfx/fixture rows still aimed at row 0x0F.
if [ "${SKIP_RUNTIME:-0}" = 1 ]; then
    echo "  SKIPPED (SKIP_RUNTIME=1)"
else
    MASK_RANGES="043c-043d,4182-41a2,41c2-41e2,4222-4262,7f00-8000" MAME_BIN="$WIDE_BIN" \
    MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
        tools/run_replay_mame.sh vsavjw tests/replays/11_pick_donovan.rpl \
        "$WORK/11_legacy.log" > "$WORK/11_legacy.out" 2>&1 || {
        echo "  FAIL: replay 11 did not complete"; fail=1; }
    if [ -f "$WORK/11_legacy.log" ]; then
        if python3 tools/compare_window.py \
                tests/expected/vsavj/masked-v2/logs/11_pick_donovan.log \
                "$WORK/11_legacy.log" --onset 889 --end 2415 \
                > "$WORK/11_legacy.cmp" 2>&1; then
            echo "  ok: host pick = bounded window 889-2415, fully re-convergent"
        else
            echo "  FAIL: the host pick does not re-converge as frozen:"
            sed 's/^/        /' "$WORK/11_legacy.cmp" | tail -5
            fail=1
        fi
    fi
fi

[ "$fail" = 0 ] || { echo "FAIL: tenant select-records gate"; exit 1; }
echo "PASS: tenant select-records gate (static composition + negative"
echo "      controls + the engine's own row sequence onto cell 0x13 +"
echo "      the host-pick re-convergence window)"
