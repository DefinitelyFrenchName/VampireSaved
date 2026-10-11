#!/bin/sh
# test_emu_clock.sh — THE SHARED INSTRUMENT CLOCK STAYS ON EMULATED TIME UNDER BREAKPOINTS (14z-197, GitHub #228 step 4).
#
# WHAT: tests/lua/emu_clock.lua, the frame clock every breakpoint instrument now shares, counts EMULATED
#   frames and stages replay input in replay.lua's order: its reference leg (no debugger) reproduces the frozen
#   vanilla basis checksum, and a leg whose breakpoints stop the CPU thousands of times still covers every frame
#   it counts and reads the game's own frame counter RAM:$FF8080 equal to the reference leg's.
# HOW: tests/lua/obj_record_bank_trace.lua (the first instrument converted) on pristine vsavj, replay
#   03_two_player_vs, 1500 frames: a REFERENCE leg (INSTR_REFERENCE=1, no -debug) whose ANCHOR is compared with
#   tests/expected/vsavj/masked-v2's checksum at frame 1500 under its MASK, and a BREAKPOINT leg with the A0
#   window opened to the whole address space (REC_LO=0 REC_HI=ffffff), so the format handlers stop the CPU on
#   every object drawn; each leg's ALIGN line (emu_clock.lua's ALIGN_OUT) is read.
# EXPECTS: the reference anchor equals the basis; the breakpoint leg counted 1500 frames over 1500 emulated ones
#   with stops' UI frames skipped (uiframes > 0), and its game clock equals the reference's. Whether the
#   breakpoint leg's own checksum equals the basis is PRINTED, not asserted: a stop can move the game without
#   moving $FF8080 ([MFI-2]; measured 14z-197: it differs here). A red means instruments' input lands on the
#   wrong frame again — every gate built on them describes a game the replay never played.
#   SECTION 4 (14z-197, slice 2) is the ground truth of tests/lib/instr_align.sh's RUN MANIFEST verdicts, on
#   tests/lua/trace_writes.lua (the instrument with POKES): ia_freeze accepts an aligned write-watch run and its
#   rows pass ia_check_manifest; it REFUSES a run under the frame_done clock and two runs under one key that
#   disagree on POKES; and a POKE on the anchor frame — which moves replay.lua's checksum there (shown) — still
#   leaves the reference leg's anchor equal to replay.lua's (emu_clock.lua's on_pokes runs before the anchor, as
#   replay.lua pokes before its checksum).
#   SECTION 5 (14z-197, #228's last three instruments — maintainer-ruled "Convert all three now"): bp_regs.lua,
#   fsm_census.lua and obj_record_full_trace.lua, which no gate runs, each to frame 3000 of the same replay: a
#   reference leg whose anchor equals the basis there, and a breakpoint leg counting 3000 over 3000 emulated
#   frames on the reference's game clock with its own breakpoints live (its output's hits, records or END line).
# FOLLOWS: emu/mame-patches/ tests/expected/vsavj/masked-v2/ tests/lib/controls.sh tests/lib/instr_align.sh
#   tests/lua/bp_regs.lua tests/lua/emu_clock.lua tests/lua/fsm_census.lua tests/lua/obj_record_bank_trace.lua
#   tests/lua/obj_record_full_trace.lua tests/lua/pokes_spec.lua tests/lua/replay.lua tests/lua/trace_writes.lua
#   tests/replays/ tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: known-bad: first-frame-skip — a reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss the basis checksum at frame 1500 (in-gate; as a mode the reference leg runs the skip and the gate FAILs)
# MUST-FIRE: known-bad: drift-clock — the breakpoint leg under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync) must cover fewer emulated frames than it counts and read a game clock unlike the reference's (in-gate; as a mode the breakpoint leg runs the old clock and the gate FAILs)
#
# Usage: ROMDIR=... tests/test_emu_clock.sh      # emulator tier, prereq lane, MAME (~4 min)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
rc=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; rc=1; }

BASIS=tests/expected/vsavj/masked-v2
MASK="$(cat "$BASIS/MASK")"
RPL=03_two_player_vs; N=1500; N5=3000
WANT="$(awk -v n=$N '$1==n {print $2}' "$BASIS/logs/$RPL.log")"
[ -n "$WANT" ] || { echo "FAIL: $BASIS/logs/$RPL.log has no frame $N"; exit 1; }

leg() {  # leg <tag> <debug: 0|1> <env...> — one instrument run; its ALIGN line to $W/<tag>.align
    tag="$1"; dbg="$2"; shift 2
    if [ "$dbg" = 1 ]; then set -- "$@" -- -debug -debugger none; else set -- "$@" --; fi
    envs=""; while [ "$1" != "--" ]; do envs="$envs $1"; shift; done; shift
    # shellcheck disable=SC2086
    env $envs REPLAY="$REPO/tests/replays/$RPL.rpl" FRAMES=$N ANCHOR=$N MASK_RANGES="$MASK" \
        ALIGN_OUT="$W/$tag.align" TRACE_OUT="$W/$tag.trace" MAME_SANDBOX="$W/sb_$tag" MAME_ROMPATH="$ROMDIR" \
        timeout 1800 tools/run_mame.sh vsavj "$@" -autoboot_script "$REPO/tests/lua/obj_record_bank_trace.lua" \
        > "$W/$tag.log" 2>&1 || true
}
field() { awk -v k="$2" '{for (i = 1; i < NF; i++) if ($i == k) {print $(i + 1); exit}}' "$W/$1.align" 2>/dev/null; }
anchor() { awk '{for (i = 1; i < NF; i++) if ($i == "anchor") {print $(i + 2); exit}}' "$W/$1.align" 2>/dev/null; }

REFCLOCK=""; vs_ctl_is first-frame-skip && REFCLOCK="INSTR_CLOCK=skip_first"
BPCLOCK="";  vs_ctl_is drift-clock && BPCLOCK="INSTR_CLOCK=frame_done"

echo "== 1. the reference leg reproduces replay.lua (pristine vsavj, $RPL, frame $N)"
leg ref 0 INSTR_REFERENCE=1 $REFCLOCK
[ -s "$W/ref.align" ] || { echo "FAIL: the reference leg wrote no ALIGN line:"; tail -5 "$W/ref.log"; exit 1; }
ra="$(anchor ref)"; rg="$(field ref gameclock)"
[ "$ra" = "$WANT" ] && ok "anchor $ra = the frozen basis at frame $N (game clock $rg)" \
    || bad "anchor $ra, the frozen basis reads $WANT: the clock or the staging is off replay.lua's"

echo "== 2. a breakpoint leg stays on emulated time and on the reference's game clock"
leg bp 1 REC_LO=0 REC_HI=ffffff $BPCLOCK
[ -s "$W/bp.align" ] || { echo "FAIL: the breakpoint leg wrote no ALIGN line:"; tail -5 "$W/bp.log"; exit 1; }
bf="$(field bp frames)"; be="$(field bp emulated)"; bu="$(field bp uiframes)"; bg="$(field bp gameclock)"
[ "$bf" = "$N" ] && [ "$be" = "$N" ] && ok "counted $bf, emulated $be" || bad "counted $bf frames over $be emulated"
[ "${bu:-0}" -gt 0 ] && ok "$bu stop frames skipped (the breakpoints stopped the CPU)" \
    || bad "uiframes ${bu:-?}: no stop frame was skipped — the breakpoints never stopped the CPU (this leg tested nothing), or the clock counted the stops as frames"
[ "$bg" = "$rg" ] && ok "game clock $bg = the reference's" || bad "game clock $bg, the reference's $rg"
[ "$(anchor bp)" = "$WANT" ] && echo "  note  the breakpoint leg's checksum equals the basis" \
    || echo "  note  the breakpoint leg's checksum $(anchor bp) is not the basis's ([MFI-2]: a stop can move the game; printed, not asserted)"

if vs_ctl_is first-frame-skip || vs_ctl_is drift-clock; then
    [ "$rc" = 1 ] && { echo "FAIL: test_emu_clock (control mode: $VS_CTL)"; exit 1; }
    echo "FAIL: test_emu_clock — control mode $VS_CTL left the gate green"; exit 1
fi

echo "== 3. controls"
leg skip 0 INSTR_REFERENCE=1 INSTR_CLOCK=skip_first
sa="$(anchor skip)"
if [ -z "$sa" ]; then vs_ctl_dead first-frame-skip "the skip leg wrote no anchor" || rc=1
elif [ "$sa" = "$WANT" ]; then vs_ctl_dead first-frame-skip "the skipped clock still reproduced the basis" || rc=1
else vs_ctl_fired first-frame-skip "under the first-frame skip the reference leg reads $sa at frame $N where the frozen basis reads $WANT"; fi
leg drift 1 REC_LO=0 REC_HI=ffffff INSTR_CLOCK=frame_done
de="$(field drift emulated)"; dg="$(field drift gameclock)"
if [ -z "$de" ]; then vs_ctl_dead drift-clock "the drift leg wrote no ALIGN line" || rc=1
elif [ "$de" -lt "$N" ] && [ "$dg" != "$rg" ]; then
    vs_ctl_fired drift-clock "under the frame_done clock the breakpoint leg covered $de emulated frames of $N counted and reads game clock $dg where the reference's reads $rg"
else vs_ctl_dead drift-clock "the frame_done clock covered $de of $N frames, game clock $dg (reference $rg)" || rc=1; fi

echo "== 4. the run manifest's verdicts (tests/lib/instr_align.sh, on trace_writes.lua with POKES)"
. "$REPO/tests/lib/instr_align.sh"
TW="$REPO/tests/lua/trace_writes.lua"; N4=600; R4="$REPO/tests/replays/$RPL.rpl"
PK4="$N4:ff8100:a55a"       # a write ON the anchor frame
mk() {  # mk <tag> <extra env> — one write-watch run of trace_writes (P1's x word: a stop on most frames)
    mkdir -p "$W/m_$1"
    # shellcheck disable=SC2086
    ( cd "$W/m_$1" && env $2 WATCH=ff8410,2 POKES="$PK4" REPLAY="$R4" FRAMES=$N4 ALIGN_OUT="$W/m_$1/align" \
        TRACE_OUT="$W/m_$1/t.txt" MAME_SANDBOX="$W/m_$1/sb" MAME_ROMPATH="$ROMDIR" \
        timeout 900 "$REPO/tools/run_mame.sh" vsavj -debug -debugger none -autoboot_script "$TW" > "$W/m_$1/l.log" 2>&1 ) </dev/null || true
}
mk good ""; mk drift INSTR_CLOCK=frame_done
ia_note "$W/good.tsv" vsavj "$RPL" vsavj - "$R4" $N4 "POKES=$PK4 WATCH=ff8410,2" "$W/m_good/align"
if ia_freeze "$TW" "$W/good.tsv" "$W/fz_good" 2 "$W/good_rows.tsv" > "$W/fz_good.txt"; then
    ok "ia_freeze accepts an aligned run ($(ia_field "$W/m_good/align" uiframes) stop frames skipped): $(cut -f3,4 "$W/good_rows.tsv" | tr '\t' ' ')"
else bad "ia_freeze refused an aligned run: $(head -2 "$W/fz_good.txt" | tr '\n' ' ')"; fi
[ "$(ia_field "$W/m_good/align" uiframes)" -gt 0 ] 2>/dev/null || bad "the write watch never stopped the CPU — this section tested nothing"
ia_check_manifest "$W/good_rows.tsv" "$W/good.tsv" > "$W/cm.txt" && ok "ia_check_manifest passes the run against its own frozen row" \
    || bad "ia_check_manifest failed the run it was frozen from: $(head -1 "$W/cm.txt")"
ia_note "$W/drift.tsv" vsavj "$RPL" vsavj - "$R4" $N4 "POKES=$PK4 WATCH=ff8410,2" "$W/m_drift/align"
if ia_freeze "$TW" "$W/drift.tsv" "$W/fz_drift" 2 "$W/drift_rows.tsv" > "$W/fz_drift.txt"; then bad "ia_freeze ACCEPTED a run under the frame_done clock"
else ok "ia_freeze refuses a run under the frame_done clock: $(grep "game clock" "$W/fz_drift.txt" | head -1)"; fi
cp "$W/good.tsv" "$W/conflict.tsv"
ia_note "$W/conflict.tsv" vsavj "$RPL" vsavj - "$R4" $N4 "POKES=1:ff8100:00 WATCH=ff8410,2" "$W/m_good/align"
if ia_freeze "$TW" "$W/conflict.tsv" "$W/fz_c" 2 "$W/c_rows.tsv" > "$W/fz_c.txt" 2>&1; then bad "ia_freeze ACCEPTED two runs under one key with different POKES"
else ok "ia_freeze refuses two runs under one key that disagree on POKES"; fi
# the anchor frame's POKE moves replay.lua's checksum there, so the equality above is an ordering test
_ia_rl vsavj - "$R4" "" "$W/rl_nopoke"
p1="$(ia_replaylua_read "$W/fz_good/k1/rl" $N4)"; p0="$(ia_replaylua_read "$W/rl_nopoke" $N4)"
if [ -n "$p1" ] && [ -n "$p0" ] && [ "$p1" != "$p0" ]; then
    ok "the anchor-frame POKE moves replay.lua's checksum ($p0 -> $p1), and the reference leg's anchor matched it"
else bad "the anchor-frame POKE did not move replay.lua's checksum ($p0 / $p1): the ordering is untested"; fi

echo "== 5. the three instruments no gate runs (bp_regs, fsm_census, obj_record_full_trace), frame $N5"
# Each runs on its own breakpoints over replay 03 to frame N5 = 3000 (the dispatcher family first fires at
# f2922 there; 8 hits in 4000 frames, measured 14z-197): a REFERENCE leg (no -debug) whose anchor must equal
# the basis, and a BREAKPOINT leg that must count N5 frames over N5 emulated ones on the reference's game clock,
# its breakpoints live (the instrument's own output says so — fsm_census's few stops cannot be told from the
# boot halt by uiframes alone). bp_regs breaks on the six OBJ format handlers obj_record_full_trace uses: on the
# format-0 handler alone it skipped 1,275 UI frames (uiframes) and logged none inside 2990-3000 (measured 14z-197;
# uiframes counts the UI frames the clock skipped, not stops — a leg with no stop can read 1).
leg5() {  # leg5 <tag> <lua> <debug: 0|1> <env...>
    t5="$1"; l5="$2"; d5="$3"; shift 3; mkdir -p "$W/i5_$t5"
    if [ "$d5" = 1 ]; then x5="-debug -debugger none"; else x5=""; fi
    # shellcheck disable=SC2086
    ( cd "$W/i5_$t5" && env "$@" REPLAY="$REPO/tests/replays/$RPL.rpl" FRAMES=$N5 ANCHOR=$N5 MASK_RANGES="$MASK" \
        ALIGN_OUT="$W/i5_$t5/align" TRACE_OUT="$W/i5_$t5/out.txt" CENSUS_OUT="$W/i5_$t5/out.txt" MAME_SANDBOX="$W/i5_$t5/sb" MAME_ROMPATH="$ROMDIR" \
        timeout 1800 "$REPO/tools/run_mame.sh" vsavj $x5 -autoboot_script "$REPO/$l5" > "$W/i5_$t5/log" 2>&1 ) </dev/null || true
}
f5() { awk -v k="$2" '{for (i = 1; i < NF; i++) if ($i == k) {print $(i + 1); exit}}' "$W/i5_$1/align" 2>/dev/null; }
a5() { awk '{for (i = 1; i < NF; i++) if ($i == "anchor") {print $(i + 2); exit}}' "$W/i5_$1/align" 2>/dev/null; }
WANT5="$(awk -v n=$N5 '$1==n {print $2}' "$BASIS/logs/$RPL.log")"
for s5 in "bp:tests/lua/bp_regs.lua:BPS=1afc6,1b234,1b61a,1b6aa,1b73e,1b7cc WINDOW=2990,3000" \
          "fsm:tests/lua/fsm_census.lua:SITES=18440:80:2,18508:80:2,185d2:80:2" \
          "full:tests/lua/obj_record_full_trace.lua:WIN_LO=2990 WIN_HI=3000"; do
    t5="${s5%%:*}"; r5="${s5#*:}"; l5="${r5%%:*}"; e5="${r5#*:}"
    # shellcheck disable=SC2086
    leg5 "${t5}_ref" "$l5" 0 INSTR_REFERENCE=1 $e5 &
    # shellcheck disable=SC2086
    leg5 "${t5}_bp" "$l5" 1 $e5 &
done
wait
for s5 in bp:bp_regs fsm:fsm_census full:obj_record_full_trace; do
    t5="${s5%%:*}"; n5="${s5#*:}"
    ra5="$(a5 "${t5}_ref")"; rg5="$(f5 "${t5}_ref" gameclock)"
    bf5="$(f5 "${t5}_bp" frames)"; be5="$(f5 "${t5}_bp" emulated)"; bg5="$(f5 "${t5}_bp" gameclock)"
    [ -n "$ra5" ] && [ "$ra5" = "$WANT5" ] && ok "$n5 reference leg: anchor $ra5 = the frozen basis at frame $N5 (game clock $rg5)" \
        || bad "$n5 reference leg: anchor ${ra5:-none}, the basis reads $WANT5 ($(tail -1 "$W/i5_${t5}_ref/log"))"
    [ "$bf5" = "$N5" ] && [ "$be5" = "$N5" ] && [ -n "$bg5" ] && [ "$bg5" = "$rg5" ] \
        && ok "$n5 breakpoint leg: counted $bf5 over $be5 emulated, game clock $bg5 = its reference's (uiframes $(f5 "${t5}_bp" uiframes))" \
        || bad "$n5 breakpoint leg: counted ${bf5:-?} over ${be5:-?} emulated, game clock ${bg5:-?} (reference ${rg5:-?})"
    case "$t5" in
        bp)   h5="$(awk '$1=="END" {print $4}' "$W/i5_bp_bp/out.txt" 2>/dev/null)"; w5="END hits ${h5:-none} in the window";;
        fsm)  h5="$(awk '$1=="SITE" {s += $8} END {print s + 0}' "$W/i5_fsm_bp/out.txt" 2>/dev/null)"; w5="$h5 dispatcher hits";;
        full) h5="$(grep -c '^F ' "$W/i5_full_bp/out.txt" 2>/dev/null)"; w5="$h5 record lines in the window";;
    esac
    [ "${h5:-0}" -gt 0 ] 2>/dev/null && ok "$n5 breakpoints live: $w5" \
        || bad "$n5 breakpoints never fired ($w5): this leg tested nothing"
done

[ "$rc" = 0 ] && echo "PASS: test_emu_clock" || echo "FAIL: test_emu_clock"
exit "$rc"
