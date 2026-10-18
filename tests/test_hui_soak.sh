#!/bin/sh
# test_hui_soak.sh — the Huitzil stage-4 SOAK gate (14z-65).
#
# WHAT: Phobos survives an 11,000-frame input-chaos soak across round transitions on the
#   REAL packed set, with both satellites alive in round 2 (the pod-lifecycle regression
#   tripwire).
# HOW: on build/hui61 (a self-built stage-4 build until 14z-197; one can be given), forces id 0x10
#   through the vanilla select flow and runs 70_hui_mash guarded on MAME on the set the build packed
#   (a vsavj-set run against a WIDE build is the pristine ROM: false green).
# EXPECTS: guard clean end to end and both satellite pointers non-zero at f6000 (round 1) and at
#   f9000 with the match live (round 2); a red is a crash or a pod lost across the round.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lua/replay_guard.lua
#   tests/replays/hui/70_hui_mash.rpl tools/build_donovan.sh tools/run_mame.sh
#   tools/run_replay_guarded.sh tools/setup_mame.sh
#
# SHEET: none — runs our build only, judged on its own; no reference leg and no frozen reference values
#
# The full behavioral chain, guarded, on the REAL packed set: builds stage
# 4, forces id 0x10 through the vanilla select flow, then runs the chaos
# soak (tests/replays/hui/70_hui_mash.rpl — QCF/QCB/DP/charges/pairs, the
# Donovan-21 shape) for 11000 frames across round transitions. Expects:
#   1. guard CLEAN end-to-end (states/moves/sounds/pods all exercised);
#   2. BOTH satellites alive in round 2 (+0x2A/+0x2C nonzero) — the
#      pod-lifecycle regression tripwire (the f4983 arc). RE-TIMED 14z-197
#      (#228 step 4, maintainer-ruled "Move to hui61, re-time 2"): f6000 is
#      ROUND 1 on the replay's own timing — on build/hui61, replay.lua, no
#      debugger, the round transition runs ~f8400-8600 (state 6/8/a/2) and the
#      match is live again from ~f8650 with both pods set
#      (build/agent197/t228/s3/soak/) — so the gate reads f6000 (round 1) AND
#      f9000 (round 2), the match state word $FF8008 asserted 0x0004 at BOTH so
#      a moved transition or a reset reads as a dead rig, not a dead pod (f6000's
#      state check added 14z-197 under rule-checker run 2026-10-11-807 Q1);
#   3. run on the set the build actually packed (vsavjw when wide_ext is
#      used — a vsavj-set run against it is the PRISTINE ROM: false green).
#
# Usage: ROMDIR=... tests/test_hui_soak.sh [builddir]   (default build/hui61)
#
# THE BUILD IS build/hui61 BY DEFAULT since 14z-197 (maintainer-ruled 2026-10-11, DECISIONS_HISTORY.md): on the
# replays' own timing the fresh stage-4 build LEAVES THE MATCH on this rig: both pods are set over f2900-4650, then the
# state words at $FF8000 zero between f4650 and f4700 and the game never returns to the match (state 0x0004) — the same
# unexplained stage-4 reset as the 2P rigs, recorded not root-caused — so it has no pods at f6000; build/hui61 keeps the
# match and both pods through both rounds (build/agent197/t228/s3/soak/hui4/ and soak/summary.txt). Corrected 14z-197
# before commit (rule-checker run 2026-10-11-807 Q1): this note first said the stage-4 build "loses both pods by f6000",
# read off this gate's own verdict, which could not tell a reset from a dead pod until f6000's state check.
# A stage-4 build can still be passed by hand.
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
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

B="${1:-build/hui61}"   # re-pointed 14z-197 (was: a fresh stage-4 build) — see THE BUILD above
case "$B" in /*) ;; *) B="$REPO/$B" ;; esac
[ -d "$B/rompath" ] || { echo "FAIL: no $B/rompath"; exit 1; }
SET=vsavj
if [ -f "$B/rompath/vsavjw.zip" ]; then
    SET=vsavjw
    export MAME_BIN="$HOME/.cache/vampire-saved/mame/cps2"
fi
echo "  ok: build $B, packed as $SET"

echo "== guarded 11000-frame chaos soak"
if ! POKES="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10" \
   DUMPS="6000:ff842a-ff842e;6000:ff8000-ff8010;9000:ff842a-ff842e;9000:ff8000-ff8010;11000:ff8460-ff8468" \
   MAME_ROMPATH="$B/rompath;$ROMDIR" \
   tools/run_replay_guarded.sh "$SET" tests/replays/hui/70_hui_mash.rpl \
       "$WORK/soak.log" "$WORK/soakbox" > "$WORK/soak.out" 2>&1; then
    echo "FAIL: guard tripped:"
    grep -m2 -E "CRASH|REGS" "$WORK/soak.log" || tail -5 "$WORK/soak.out"
    exit 1
fi
echo "  ok: clean through 11000 frames"

ST1="$(xxd -p "$WORK/dump_6000_ff8000.bin" 2>/dev/null | cut -c17-24)"
[ "$ST1" = 00040000 ] || { echo "FAIL: the match is not live at f6000 (\$FF8008 = ${ST1:-no dump}) — the game left the match (a reset reads here, not as dead pods); the rig, not the pods"; exit 1; }
PODS="$(xxd -p "$WORK/dump_6000_ff842a.bin" 2>/dev/null | cut -c1-8)"
case "$PODS" in
    ""|0000*|????0000) echo "FAIL: round-1 satellites dead at f6000 (+0x2A/+0x2C = ${PODS:-no dump})"; exit 1 ;;
    *)     echo "  ok: round-1 satellites alive at f6000 ($PODS)" ;;
esac
ST="$(xxd -p "$WORK/dump_9000_ff8000.bin" 2>/dev/null | cut -c17-24)"
[ "$ST" = 00040000 ] || { echo "FAIL: the match is not live at f9000 (\$FF8008 = ${ST:-no dump}) — the round transition moved; the rig, not the pods"; exit 1; }
PODS2="$(xxd -p "$WORK/dump_9000_ff842a.bin" 2>/dev/null | cut -c1-8)"
case "$PODS2" in
    ""|0000*|????0000) echo "FAIL: round-2 satellites dead at f9000 (+0x2A/+0x2C = ${PODS2:-no dump})"; exit 1 ;;
    *)     echo "  ok: round-2 satellites alive at f9000, the match live ($PODS2)" ;;
esac

echo "PASS: Huitzil soak (guard clean, pods live across rounds)"
