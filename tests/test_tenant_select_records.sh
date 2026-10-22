#!/bin/sh
# test_tenant_select_records.sh — the M3a select-records half: at a
# variant-half tenant id the build must carry the tenant's OWN select
# records and the host's records must return to VANILLA bytes.
#
# WHAT: at a variant-half tenant id the build carries the tenant's OWN select records (six
#   array rows repointed, records composed from the vs2 image) and the host's select-record
#   block, palette-grid column and shared coord list return to VANILLA bytes; the engine
#   walking onto cell 0x13 fetches exactly the predicted row sequence for all three UI
#   pieces.
# HOW: tools/check_tenant_select.py re-derives the composition from the vs2 image and
#   select_port.PLACEMENTS and compares the built image; negative controls (a pristine
#   image, a flipped composed byte, a flipped host byte) must fail; runtime on WIDE MAME
#   with replay 36 reads the record walker.
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): trace_writes.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua); every tap run's game clock RAM:$FF8080 at its last frame is held to
#   tests/expected/instr_gameclock/test_tenant_select_records.tsv, frozen by `--freeze-clock` from REFERENCE legs
#   (no watch, no debugger) each held to replay.lua run live; one STAGING reference leg is held to replay.lua on
#   every run (tests/lib/instr_align.sh).
# EXPECTS: static equal, the three controls failing, the engine's rows as predicted;
#   SKIP_RUNTIME=1 skips section 3. Every tap run on emulated time at its frozen game clock, the staging leg on
#   replay.lua's checksum.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/donovan-m5/mask tests/expected/instr_gameclock/
#   tests/expected/vsavj/masked-v2/logs/11_pick_donovan.log tests/lib/controls.sh tests/lib/decrypt_cache.sh
#   tests/lib/instr_align.sh tests/lib/tenant_build.sh tests/lua/emu_clock.lua tests/lua/replay.lua
#   tests/lua/trace_writes.lua tests/replays/
#   tools/build_donovan.sh tools/check_tenant_select.py tools/compare_window.py
#   tools/run_mame.sh tools/run_replay_mame.sh tools/setup_mame.sh tests/lib/sheet.sh
#
# SHEET: legs vsavj,ours — moments: section 4's host pick on replay 11 (the frozen vanilla masked log against the variant-id build's): the bounded window's first and last frame (889, 2415) and the replay's sync anchors — not comparable: inside the ratified window 889-2415 the legs differ by ratification (the select wheel's added cells); sections 1-3 (static bytes, the record walker's reads) have no picture
# SHEET-VARIANT: TENANT13_OUTBASE tests/lib/tenant_build.sh tenant_build_13 vsavjw — the ours leg is the 0x13 variant this gate builds for itself, not one of the commit's tracks: proof_sheets builds it in the clean checkout and states its fingerprint (ruled 2026-10-22, "Built in checkout, stated")
#
# MUST-FIRE: known-bad: drift-clock — a tap run under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 1,059 emulated frames of 1,400 counted) must miss its frozen game clock (in-gate: one extra run of the highlight tap — two other taps lose exactly 256 frames, which the byte cannot see; mode: every tap run runs the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
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
# Usage: ROMDIR=... tests/test_tenant_select_records.sh [outbase] [--freeze-clock]
#   outbase: an existing variant-id build (default: builds one fresh into a
#   temp dir with --tenant-id 0x13 --profile cps2-wide-v1).
# Env: MAME_WIDE_BIN overrides the WIDE MAME binary
#      (default ~/.cache/vampire-saved/mame/cps2). SKIP_RUNTIME=1 skips
#      section 3 (e.g. no WIDE emulator on this machine).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   M3a select-records mechanism (14z-62): a variant-id build carries the
#   tenant's OWN six select records (space-model allocations, six array rows
#   poked) and the host's select-family program bytes are VANILLA. Static re-
#   derivation + verdict-logic negative controls + the engine's own row fetch
#   onto cell 0x13 (replay 36, WIDE MAME). Self-builds at 0x13 unless given a
#   build. 14z-88: reads the mask from the current set; the splash section
#   matches the CPU opponent's RNG ladder draw as VANILLA (was pinned to one
#   draw and went stale silently — run it in batteries)
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
. "$REPO/tests/lib/tenant_build.sh"    # GitHub #71
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0
FREEZE_CLOCK=0
for a in "$@"; do [ "$a" = "--freeze-clock" ] && FREEZE_CLOCK=1; done
[ "${1:-}" = "--freeze-clock" ] && shift
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
CLOCKS="tests/expected/instr_gameclock/test_tenant_select_records.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"

# The build shape lives in tests/lib/tenant_build.sh (GitHub #71): stage,
# profile and tenant id were inline in five gates and all three have moved
# before.
tenant_build_13 "$WORK" "${1:-}" || exit 1
[ -d "$OUTBASE/prg" ] || { echo "FAIL: $OUTBASE/prg missing"; exit 1; }

VAN="$WORK/vsavj_data.bin"
VS2="$WORK/vsav2_data.bin"
decrypt_view vsavj "$WORK/vsavj_op.bin" "$VAN"
decrypt_view vsav2 "$WORK/vsav2_op.bin" "$VS2"

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
        _leg=t13; [ "${RT_FRAMES:-1400}" = 1400 ] || _leg="t13_${RT_FRAMES}"
        ia_note "$WORK/manifest.tsv" "$_leg" "${2%.rpl}" vsavjw "$OUTBASE/rompath;$ROMDIR" "$REPO/tests/replays/$2" \
            "${RT_FRAMES:-1400}" "MAME_BIN=$WIDE_BIN WATCH=$3" "$WORK/$1.align"
        # shellcheck disable=SC2086
        env $_clk WATCH="$3" TRACE_OUT="$WORK/$1.txt" FRAMES="${RT_FRAMES:-1400}" ALIGN_OUT="$WORK/$1.align" \
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
        # token "VANILLA" in the expected sequence matches ANY vanilla ROM
        # record (an address below the WIDE extension and not the tenant's
        # own) — for rows whose IDENTITY is an RNG draw (the CPU opponent's
        # ladder draw shifts with hook cycles: 14z-62e froze 0x2738b8, the
        # 14z-87 batch draws 0x273a02; the gate asserts the SHAPE — a
        # vanilla record then the tenant's — and prints the draw).
        seq_ok=1
        _want="$4"; _got="$got"
        while [ -n "$_want" ]; do
            w=${_want%% *}; _want=${_want#* }; [ "$_want" = "$w" ] && _want=""
            g=${_got%% *};  _got=${_got#* };   [ "$_got" = "$g" ] && _got=""
            if [ "$w" = VANILLA ]; then
                case "$g" in 00[0-3]?????) [ "$g" != "$(rowval splash_p1 p1)" ] || seq_ok=0 ;; *) seq_ok=0 ;; esac
                [ -n "$g" ] && echo "  (RNG draw: vanilla record $g)"
            else
                [ "$w" = "$g" ] || seq_ok=0
            fi
        done
        [ -z "$_got" ] || seq_ok=0
        if [ "$seq_ok" = 1 ]; then
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
    # replay): the CPU opponent's VANILLA splash_p2 row (an RNG ladder
    # draw — 0x06 / record 0x2738b8 at 14z-62e, 0x273a02 by 14z-87: the
    # draw follows hook-cycle-shifted RNG state, so it is matched as
    # VANILLA, not pinned — 14z-88) interleaves with the TENANT's composed
    # splash_p1 record — the engine serving the tenant's own splash.
    # (The win-quote piece fires only at a match win; statics + alias
    # anchors cover it until a 0x13 win replay exists.)
    RT_FRAMES=2800 runtime splash 36_pick_tenant_cell.rpl "2672aa,100,r" \
        "VANILLA $(rowval splash_p1 p1) " "" first
    # ...and the +0x80 name structure has NO consumer on any measured path
    # (0 reads through 2P select, confirm, splash, match start). The
    # composed row is kept for safety; this asserts the measured negative
    # so the gate speaks up if some path DOES start reading it.
    ia_note "$WORK/manifest.tsv" t13 37_p2_pick_tenant vsavjw "$OUTBASE/rompath;$ROMDIR" \
        "$REPO/tests/replays/37_p2_pick_tenant.rpl" 1400 "MAME_BIN=$WIDE_BIN WATCH=26762a,80,r" "$WORK/p2name_neg.align"
    # shellcheck disable=SC2086
    env $_clk WATCH="26762a,80,r" TRACE_OUT="$WORK/p2name_neg.txt" FRAMES=1400 ALIGN_OUT="$WORK/p2name_neg.align" \
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
# the frozen vanilla oracle — tools/freeze_masked_basis.sh). 14z-88: the
# mask is READ from the current expectation set (one source of truth);
# a V3 basis (row 0x1D's slot) was applied and WITHDRAWN the same day —
# the 0x1D medallion move cost a legacy pairing one main-loop frame
# (STATE 14z-88); with the row back on 0x1A this section is the plain
# bounded window again.
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
    MASK_RANGES="$(cat tests/expected/donovan-m5/mask)" MAME_BIN="$WIDE_BIN" \
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

if [ "${SKIP_RUNTIME:-0}" != 1 ]; then
    echo "== 5. the instrument's alignment (#228 step 4, option A) =="
    if [ "$FREEZE_CLOCK" = 1 ]; then
        [ "$fail" = 0 ] || { echo "REFUSED: sections 1-4 failed — nothing frozen"; exit 1; }
        ia_freeze "$REPO/tests/lua/trace_writes.lua" "$WORK/manifest.tsv" "$WORK/fz" "${JOBS:-4}" "$WORK/clocks.tsv" \
            > "$WORK/fz.txt" || { sed 's/^/  /' "$WORK/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
        mkdir -p "$(dirname "$CLOCKS")"
        { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
          echo "# option A) by \`tests/test_tenant_select_records.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): t13 = the variant-id"
          echo "# build (tests/lib/tenant_build.sh tenant_build_13, built fresh), t13_2800 its 2,800-frame splash run; every reference leg"
          echo "# held to replay.lua run live, every tap run to its reference leg's game clock."
          echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
          cat "$WORK/clocks.tsv"; } > "$CLOCKS"
        echo "froze $(wc -l < "$WORK/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
        exit 0
    fi
    if ia_check_manifest "$CLOCKS" "$WORK/manifest.tsv" > "$WORK/align_bad.txt"; then
        echo "  ok: every tap run on emulated time, at its frozen game clock"
    else echo "  FAIL: $(wc -l < "$WORK/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$WORK/align_bad.txt" | sed 's/^/        /'; fail=1; fi
    # THE DRIFT CONTROL RUNS ON THE THIRD TAP RUN (highlight), not the staging leg's first (measured 14z-197): under the
    # old clock big_portrait and name_banner each lose EXACTLY 256 frames (1,144 emulated of 1,400), so their one-byte
    # game clock wraps back to the frozen value and only frames == emulated sees them; highlight loses 341 (1,059).
    ia_stage test_tenant_select_records "$CLOCKS" "$REPO/tests/lua/trace_writes.lua" "$WORK/manifest.tsv" 1 "$WORK/st" "$MODE" 3 || fail=1
    if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
        [ "$fail" = 1 ] && { echo "FAIL: tenant select-records gate (control mode: $MODE)"; exit 1; }
        echo "FAIL: tenant select-records gate — control mode $MODE left the gate green"; exit 1
    fi
    if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
    if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi
fi

# THE SHEET (#291): with SHEET_OUT set, section 4's two legs — the frozen vanilla masked log and this run's — and the
# moments its window verdict rests on. A fresh build lives in $WORK, deleted at exit, so its rompath is copied into
# SHEET_OUT for the capture; a build handed in through TENANT13_OUTBASE (tools/proof_sheets.py run builds the declared
# variant in the clean checkout's build/, ruled 2026-10-22) persists and is named as it is. Nothing the gate decides changes.
. "$REPO/tests/lib/sheet.sh"
if sheet_on && [ -z "$MODE" ] && [ "$FREEZE_CLOCK" = 0 ] && [ "${SKIP_RUNTIME:-0}" != 1 ] && [ -f "$WORK/11_legacy.log" ]; then
    _sb="tests/expected/vsavj/masked-v2/logs/11_pick_donovan.log"
    _sfr="$(awk '$1 ~ /^[0-9]+$/ {n = $1} END {print n}' "$_sb")"
    _smask="$(cat tests/expected/donovan-m5/mask)"
    mkdir -p "$SHEET_OUT/legs"
    if [ -n "${TENANT13_OUTBASE:-}" ]; then _t13rp="$OUTBASE/rompath"
    else rm -rf "$SHEET_OUT/legs/t13_rompath"; cp -R "$OUTBASE/rompath" "$SHEET_OUT/legs/t13_rompath"; _t13rp="$SHEET_OUT/legs/t13_rompath"; fi
    if python3 tools/compare_window.py "$_sb" "$WORK/11_legacy.log" --onset 889 --end 2415 > /dev/null 2>&1; then _v="window as frozen"; else _v=DIFF; fi
    sheet_new host11 "The host pick on a variant-id build (11_pick_donovan): vanilla vsavj above the 0x13 build" donovan - \
        "inside the ratified window 889-2415 the legs differ by ratification (the select wheel's added cells)"
    sheet_leg host11 vanilla vsavj vsavj "$ROMDIR" "$REPO/tests/replays/11_pick_donovan.rpl" - "$_sfr" "$_sb" "$_smask"
    sheet_leg host11 t13 ours vsavjw "$_t13rp;$ROMDIR" "$REPO/tests/replays/11_pick_donovan.rpl" - "$_sfr" \
        "$WORK/11_legacy.log" "$_smask"
    sheet_anchors host11
    sheet_inputs host11 18      # #291 S4-E (Q2: "at the replay's inputs, up to 18 frames", "18 per round"), each proven on the logs above
    for _sw in 889:opens 2415:closes; do
        sheet_moment host11 "w${_sw%%:*}" "f${_sw%%:*} window ${_sw#*:} (ratified bounded window)" "$_v"
        sheet_at host11 "w${_sw%%:*}" vanilla "${_sw%%:*}" log
        sheet_at host11 "w${_sw%%:*}" t13 "${_sw%%:*}" log
    done
fi

[ "$fail" = 0 ] || { echo "FAIL: tenant select-records gate"; exit 1; }
echo "PASS: tenant select-records gate (static composition + negative"
echo "      controls + the engine's own row sequence onto cell 0x13 +"
echo "      the host-pick re-convergence window)"
