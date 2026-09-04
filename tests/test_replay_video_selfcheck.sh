#!/bin/sh
# test_replay_video_selfcheck.sh — ground truth for replay.lua's VIDEO_OUT,
# the MAME per-frame framebuffer checksum.
#
# WHY: session 14z-55 discovered that the FBNeo harness had never rendered a
# pixel — every gate the project owned on that side was structurally blind to
# the video path, and would have reported the CPS-2 WIDE 19-bit tile address
# "green" without ever executing it. MAME now gets the same instrument, so it
# gets the same treatment CLAUDE.md §4 demands: a verdict mechanism is not
# trusted until it has been validated against known ground truth.
#
# Four checks, two of them two-sided:
#   1. LIVENESS       — a real match yields thousands of distinct framebuffer
#                       checksums. A blind instrument yields one.
#   2. NON-PERTURBING — the RAM log is bit-identical to the frozen expectation
#                       with VIDEO_OUT enabled, so turning it on can never
#                       invalidate a frozen result.
#   3. DETERMINISM    — two runs produce identical video logs.
#   4. GROUND TRUTH   — against a build with a KNOWN pixel difference
#                       (donovan6, whose select medallion differs from vanilla
#                       on exactly the wheel-visible frames, per
#                       tests/test_gfx_menus.sh):
#                         frame  650 pixel-identical  -> checksums MUST match
#                         frames 950/1250  880px diff -> checksums MUST differ
#                       Both directions matter: an instrument that always
#                       differs is as useless as one that never does.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/test_replay_video_selfcheck.sh
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
RPL="tests/replays/02_demitri_vs_cpu.rpl"
fail=0

run() {   # run <tag> <rompath>
    VIDEO_OUT="$WORK/$1.vid" MAME_ROMPATH="$2" \
        tools/run_replay_mame.sh vsavj "$RPL" "$WORK/$1.log" "$WORK/sb_$1" >/dev/null 2>&1
}
vsum() {  # vsum <tag> <frame>
    awk -v f="$2" '$1 == f { print $2; exit }' "$WORK/$1.vid"
}

echo "== 1. liveness =="
run van "$ROMDIR"
frames=$(grep -c '^[0-9]' "$WORK/van.vid")
distinct=$(awk '/^[0-9]/ { print $2 }' "$WORK/van.vid" | sort -u | wc -l | tr -d ' ')
echo "  $frames frames, $distinct distinct framebuffer checksums"
if [ "$distinct" -lt 1000 ]; then
    echo "  FAIL: too few distinct values — the instrument is not seeing the screen"
    fail=1
else
    echo "  ok: the instrument is genuinely rendering"
fi

echo "== 2. non-perturbation of the RAM oracle =="
got=$(shasum "$WORK/van.log" | cut -d' ' -f1)
exp=$(cat tests/expected/vsavj/02_demitri_vs_cpu.sha1)
if [ "$got" = "$exp" ]; then
    echo "  ok: RAM log still bit-identical to the frozen expectation"
else
    echo "  FAIL: enabling VIDEO_OUT changed the RAM log ($got != $exp)"
    fail=1
fi

echo "== 3. determinism =="
run van2 "$ROMDIR"
if cmp -s "$WORK/van.vid" "$WORK/van2.vid"; then
    echo "  ok: two runs produce identical video logs"
else
    echo "  FAIL: video log is nondeterministic"
    diff "$WORK/van.vid" "$WORK/van2.vid" | head -3
    fail=1
fi

echo "== 4. two-sided ground truth vs a known pixel difference =="
if [ ! -f "build/donovan6/rompath/vsavj.zip" ]; then
    echo "  SKIPPED: no build/donovan6/rompath (tools/build_donovan.sh 6 build/donovan6)"
    echo "  NOTE: checks 1-3 show the instrument is live, deterministic and"
    echo "        harmless, but NOT that it detects a real pixel difference."
    skipped=1
else
    run don "$REPO/build/donovan6/rompath;$ROMDIR"
    # Frame 650 (title): tests/test_gfx_menus.sh compares it full-frame and
    # passes, so these two builds are pixel-identical there.
    if [ "$(vsum van 650)" = "$(vsum don 650)" ]; then
        echo "  ok: frame  650 checksums MATCH (known pixel-identical)"
    else
        echo "  FAIL: frame 650 differs, but the menus gate says it should not"
        echo "        — the instrument reports differences that are not there"
        fail=1
    fi
    # Frames 950/1250 (wheel visible): the menus gate has to MASK the
    # medallion box on these, i.e. 880 pixels genuinely differ.
    for fr in 950 1250; do
        if [ "$(vsum van "$fr")" != "$(vsum don "$fr")" ]; then
            echo "  ok: frame $fr checksums DIFFER (known 880px medallion diff)"
        else
            echo "  FAIL: frame $fr identical, but 880 pixels are known to differ"
            echo "        — the instrument is BLIND to a real pixel change"
            fail=1
        fi
    done
fi

[ "$fail" = 0 ] || { echo "FAIL: VIDEO_OUT self-check"; exit 1; }
if [ -n "${skipped:-}" ]; then
    echo "PARTIAL: VIDEO_OUT is live, deterministic and non-perturbing, but the"
    echo "         two-sided ground truth did not run."
    exit 2
fi
echo "PASS: VIDEO_OUT self-check — the MAME framebuffer instrument sees the"
echo "      screen, is deterministic, does not disturb the RAM oracle, and"
echo "      detects a known pixel difference without crying wolf on a known"
echo "      identical frame."
