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
# FOLLOWS: emu/mame-patches/ tests/expected/vsavj/masked-v2/ tests/lib/controls.sh tests/lua/emu_clock.lua
#   tests/lua/obj_record_bank_trace.lua tests/replays/ tools/run_mame.sh tools/setup_mame.sh
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
RPL=03_two_player_vs; N=1500
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

[ "$rc" = 0 ] && echo "PASS: test_emu_clock" || echo "FAIL: test_emu_clock"
exit "$rc"
