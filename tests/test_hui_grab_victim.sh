#!/bin/sh
# test_hui_grab_victim.sh — the GRAB-VICTIM placement A/B gate (14z-73).
#
# THE DEFECT — FIXED 14z-73 (grab_hold_keyframes: H's own vs2 keyframe
# block 0x0C56AA ported, row 0xBE2BA repointed; patch_index documents this
# gate guarding it at `matches`, peak Δ=0). Historical shape: during
# Phobos' grab the VICTIM's sprite teleported mid-animation — the victim
# is placed every frame by the attacker's capture-pose data; the endpoints
# looked right but the held phase did not.
#
# WHY THIS RIG WORKS WITHOUT CORNERING (retires the 14z-72 blocker). The two
# legs are different games (native vsav2 vs our vsavjw), so their ABSOLUTE
# positions differ by a fixed ~21px camera/origin offset. 14z-72 compared
# absolute victim-x, saw 21px, and declared the rig "not comparable". But the
# VICTIM OFFSET RELATIVE TO THE ATTACKER (dx = p2x - p1x) is identical on both
# legs before the grab (measured dx=42 both) — the global shift cancels. So
# replay 80, run on both legs with the same both-sides forced pick, is already
# comparable at the relative level; no corner walk is needed.
#
# WHAT IT ASSERTS.
#   1. BOTH legs actually grabbed (P1 seq 0x0E + victim took 0x13 damage).
#      A rig that whiffed measures nothing — the checker refuses to judge it.
#   2. The relative-offset A/B verdict via tools/check_grab_victim.py:
#      --expect matches (DEFAULT SINCE 14z-103; measured Δ=0 on hui46)
#      asserts ours tracks native through the hold. The default had stayed
#      on the PRE-FIX `differs` since the gate's birth at 14z-73 — the fix
#      landed the same session and every freeze ran the gate with explicit
#      =matches, so the stale default was never hit until the 14z-103
#      re-point. GRAB_VICTIM_EXPECT=differs reproduces the pre-fix defect
#      (needs a pre-14z-73 build).
#   3. VERDICT-LOGIC CONTROLS (each MUST be rejected): a "fixed" leg (ours ==
#      native) must fail --expect differs, proving the checker is not blind to
#      the divergence it claims to measure; and a "never grabbed" leg must be
#      refused, proving the connect gate works. (The 14z-71 lesson: a dead
#      instrument and a real result are the same shape from outside.)
#
# Usage: ROMDIR=... [GRAB_VICTIM_EXPECT=differs|matches] \
#            tests/test_hui_grab_victim.sh [wide-builddir]
#        (defaults to build/hui54)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   grab-victim placement A/B (14z-73): native vsav2 vs the build, replay 80
#   through field_trace.lua, comparing the victim offset RELATIVE to the
#   attacker (dx=p2x-p1x — cancels the ~21px global camera shift, so NO corner
#   rig is needed). Refuses to judge unless both legs grabbed (seq 0x0E + 0x13
#   dmg); 2 verdict controls. GRAB_VICTIM_EXPECT=matches (default since
#   14z-103; the 14z-73 grab_hold_keyframes fix is what it guards, Δ=0) |
#   =differs reproduces the pre-fix ~109px teleport (needs a pre-14z-73
#   build). Checker tools/check_grab_victim.py. Defaults hui46
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
   # RE-POINTED 14z-94 (GitHub #94): was build/hui25, a pre-WIDE-v1.1 set
   # (19 members, no vsw.z01/z02) — the script could not run at all.
   # Its frozen inventory may still describe the OLD build: run it
   # before trusting a green, and re-measure rather than absorb.

BUILD="${1:-build/hui54}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
EXPECT="${GRAB_VICTIM_EXPECT:-matches}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || {
    echo "FAIL: no $BUILD/rompath/vsavjw.zip (WIDE tenant build required)"; exit 1; }

MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
RPL="$REPO/tests/replays/hui/80_hui_grab_2p.rpl"
# P1 = Huitzil (0x10), P2 = Victor (0x03 on both wheels). Early window only —
# late pokes leak into the 2P commit/load (the replay-80 rule).
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
# fighter blocks: P1 $FF8400 / P2 $FF8800. x +0x10.w, y +0x14.w, facing +0x0B,
# seq +0x06, hp +0x50.w (docs/game/atlas/ram.md).
FIELDS="ff8410:w:p1x,ff8414:w:p1y,ff840b:b:p1face,ff8406:b:p1seq,ff8450:w:p1hp,ff8810:w:p2x,ff8814:w:p2y,ff880b:b:p2face,ff8806:b:p2seq,ff8850:w:p2hp,ff8832:w:p2link"

leg() {   # $1 tag  $2 set  $3 rompath-or-empty
    tag=$1; set_=$2; rp=$3
    d="$WORK/$tag"; mkdir -p "$d/s1"
    if [ -n "$rp" ]; then MAME_ROMPATH="$rp;$ROMDIR"; export MAME_ROMPATH
    else unset MAME_ROMPATH || true; fi
    ( cd "$d" && REPLAY="$RPL" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3130 FIELD_TO=3300 FRAMES=3400 \
      MAME_SANDBOX="$d/s1" \
      "$REPO/tools/run_mame.sh" "$set_" \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" \
      > "$d/run.out" 2>&1 ) || { tail -6 "$d/run.out"; echo "FAIL: $tag leg"; exit 1; }
}

echo "== native leg (vsav2)"
leg native vsav2 ""
echo "== build leg ($BUILD)"
leg ours vsavjw "$BUILD/rompath"

echo
echo "== the relative-offset A/B (expect: $EXPECT)"
python3 "$REPO/tools/check_grab_victim.py" "$WORK" --expect "$EXPECT" \
    || { echo "FAIL: grab-victim A/B did not match expectation '$EXPECT'"; exit 1; }

echo
echo "== verdict-logic controls (each MUST be rejected)"
ok=1
# (a) "fixed" — ours == native. Under --expect differs this must FAIL (proves
#     the checker actually sees the divergence, i.e. is not blind).
mkdir -p "$WORK/neg_fixed/native" "$WORK/neg_fixed/ours"
cp "$WORK/native/field.txt" "$WORK/neg_fixed/native/field.txt"
cp "$WORK/native/field.txt" "$WORK/neg_fixed/ours/field.txt"
if python3 "$REPO/tools/check_grab_victim.py" "$WORK/neg_fixed" --expect differs --quiet \
       > "$WORK/neg_fixed.out" 2>&1; then
    echo "   FAIL: checker PASSED the neg_fixed (ours==native) corruption under 'differs'"; ok=0
else
    echo "   ok: neg_fixed rejected — $(grep -m1 '  - ' "$WORK/neg_fixed.out" | cut -c5-90)"
fi
# (b) "never grabbed" — ours' P1 seq never reaches 0x0E. Must be REFUSED.
mkdir -p "$WORK/neg_nograb/native" "$WORK/neg_nograb/ours"
cp "$WORK/native/field.txt" "$WORK/neg_nograb/native/field.txt"
sed 's/p1seq=14/p1seq=0/g' "$WORK/ours/field.txt" > "$WORK/neg_nograb/ours/field.txt"
if python3 "$REPO/tools/check_grab_victim.py" "$WORK/neg_nograb" --expect "$EXPECT" --quiet \
       > "$WORK/neg_nograb.out" 2>&1; then
    echo "   FAIL: checker JUDGED the neg_nograb (whiffed) corruption"; ok=0
else
    echo "   ok: neg_nograb refused — $(grep -m1 '  - ' "$WORK/neg_nograb.out" | cut -c5-90)"
fi
[ "$ok" = 1 ] || { echo "FAIL: verdict logic does not detect what it claims to"; exit 1; }

echo
echo "PASS: grab-victim A/B valid (both legs grabbed) and matches expectation '$EXPECT'"
