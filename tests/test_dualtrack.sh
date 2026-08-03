#!/bin/sh
# test_dualtrack.sh — the two tracks must differ ONLY where they are meant to.
#
# The dual-track decision (14z-59g) keeps a stock-size build alongside the
# CPS-2 WIDE roster build. That is only coherent if the WIDE build is a
# SUPERSET of the stock one: same engine, same legacy behaviour, plus the
# content the extension made possible.
#
# This gate establishes that directly, as a live A/B between the two builds
# — no frozen expectations involved, so it is machine-independent and needs
# no freeze decision:
#
#   1. LEGACY IDENTICAL. On replays that never reach the patched slot, the
#      WIDE build must be bit-identical to the stock build. Legacy
#      characters never execute ported code, so anything else means the
#      profile leaked into vanilla behaviour. This is what lets every gate
#      that passes on the stock build transfer to the WIDE build without
#      re-plumbing each one for the vsavjw set.
#
#   2. PATCHED-SLOT CONTENT DIFFERS, AND THE DIFFERENCE IS ATTRIBUTED. On
#      Donovan replays the two MUST diverge — the sfx helper is live on WIDE
#      and stubbed on stock. Identical here would mean the WIDE build
#      carries content that does nothing: the vacuous-relocation trap (B4)
#      in yet another hat.
#
#      01_attract_long belongs in THIS group, not group 1: the attract demo
#      features the patched slot, which is why the stock build already
#      carries `diverge vsavj/masked 4278` for it. Measured 14z-59j, its
#      stock-vs-WIDE difference is 57 bytes and EVERY ONE is either the
#      dead-stack window $FF7F00-$FF7FFF (a CLAUDE.md §4 masked window --
#      hook cycle skew, not live state) or the $FF05xx sound-driver work
#      area (docs/atlas/ram.md), which is precisely what a live sfx helper
#      is supposed to touch. ZERO bytes of gameplay state. Section 3 asserts
#      that attribution rather than accepting "it differs".
#
# Usage: ROMDIR=... tests/test_dualtrack.sh [stock_rompath] [wide_rompath]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
STOCK="${1:-$REPO/build/m5_stock/rompath}"
WIDE="${2:-$REPO/build/m5_wide/rompath}"
[ -f "$STOCK/vsavj.zip"  ] || { echo "no stock build at $STOCK";  exit 1; }
[ -f "$WIDE/vsavjw.zip" ] || { echo "no WIDE build at $WIDE";     exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

LEGACY="02_demitri_vs_cpu 03_two_player_vs 04_select_fuzz \
05_timeout_idle 06_test_mode 07_mash_storm 08_challenger_join 09_mirror_pick \
10_midattract_start 29_felicia_walljump 30_demitri_throw"
DONOVAN="01_attract_long 12_donovan_vs_cpu 19_don_dp_spam 25_don_darkforce 56_don_es_ls"

run() {  # run <tag> <set> <rompath> <replay>
    FBNEO_ROMPATH="$3" tools/run_replay_fbneo.sh "$2" \
        "$REPO/tests/replays/$4.rpl" "$WORK/$1.log" "$WORK/sb_$1" >/dev/null 2>&1
}

echo "== 1. LEGACY must be bit-identical (the profile must not touch vanilla) =="
for rp in $LEGACY; do
    run "s_$rp" vsavj  "$STOCK" "$rp"
    run "w_$rp" vsavjw "$WIDE"  "$rp"
    if cmp -s "$WORK/s_$rp.log" "$WORK/w_$rp.log"; then
        echo "  ok: $rp identical"
    else
        echo "  FAIL: $rp — the WIDE build changed LEGACY behaviour"
        diff "$WORK/s_$rp.log" "$WORK/w_$rp.log" | head -3
        fail=1
    fi
done

echo "== 2. patched-slot content must differ (else it does nothing) =="
for rp in $DONOVAN; do
    run "sd_$rp" vsavj  "$STOCK" "$rp"
    run "wd_$rp" vsavjw "$WIDE"  "$rp"
    if cmp -s "$WORK/sd_$rp.log" "$WORK/wd_$rp.log"; then
        echo "  FAIL: $rp identical — the live sfx helper changes NOTHING"
        fail=1
    else
        fr=$(diff "$WORK/sd_$rp.log" "$WORK/wd_$rp.log" | awk '/^< [0-9]/{print $2; exit}')
        echo "  ok: $rp diverges from frame $fr (sfx helper live on WIDE)"
    fi
done

echo "== 3. the attract difference must be ATTRIBUTABLE, byte for byte =="
FBNEO_DUMPS="4400:ff0000-ffffff" FBNEO_ROMPATH="$STOCK" \
    tools/run_replay_fbneo.sh vsavj "$REPO/tests/replays/01_attract_long.rpl" \
    "$WORK/at_s.log" "$WORK/sb_at_s" >/dev/null 2>&1
FBNEO_DUMPS="4400:ff0000-ffffff" FBNEO_ROMPATH="$WIDE" \
    tools/run_replay_fbneo.sh vsavjw "$REPO/tests/replays/01_attract_long.rpl" \
    "$WORK/at_w.log" "$WORK/sb_at_w" >/dev/null 2>&1
python3 tools/attribute_ramdiff.py "$WORK/at_s.log" "$WORK/at_w.log" 4400 \
    --window 7F00-7FFF:dead-stack --window 0500-05FF:sound-driver || fail=1

echo
[ "$fail" = 0 ] || { echo "FAIL: dual-track gate"; exit 1; }
echo "PASS: dual-track — WIDE is legacy-identical to stock and differs only"
echo "      on Donovan, so the stock build's gates transfer to it."
