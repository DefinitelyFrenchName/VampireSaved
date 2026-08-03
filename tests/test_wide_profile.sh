#!/bin/sh
# test_wide_profile.sh — CPS-2 WIDE profile gate (Phase B).
#
# Two invariants, both required by Rule 1 v2 (docs/cps2_wide.md):
#
#  1. EMULATOR SUPERSET INVARIANT — the patched FBNeo binary, running the
#     STOCK unmodified vsavj set, must behave bit-identically to a
#     pre-patch binary. This is the emulator-side twin of the ROM-side
#     superset invariant: it proves our driver additions cannot perturb
#     vanilla content, and by construction cannot perturb other games.
#     Needs a reference binary (FBNEO_REF); skipped with a loud notice if
#     one is not supplied, because an unrun invariant must never look green.
#
#  2. PROFILE INERTNESS — the WIDE set (grown regions, zero-filled new
#     members, identical program/gfx content) must behave bit-identically
#     to the stock set on the same binary. Any difference means a grown
#     region is NOT inert and the profile is not safe to build content on.
#
# Both compare the harness's per-frame work-RAM checksum logs over the
# legacy corpus — the same basis the ROM-side gates use.
#
# Usage:
#   ROMDIR=... [FBNEO_REF=/path/to/pre-wide/fbneo] tests/test_wide_profile.sh
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WIDE_ROMPATH="${WIDE_ROMPATH:-$REPO/build/wide0/rompath}"
[ -f "$WIDE_ROMPATH/vsavjw.zip" ] || {
    echo "no WIDE romset at $WIDE_ROMPATH (build it: tools/build_wide_romset.py)"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

CORPUS="${*:-01_attract_long 02_demitri_vs_cpu 03_two_player_vs 04_select_fuzz \
05_timeout_idle 06_test_mode 07_mash_storm 08_challenger_join 09_mirror_pick \
10_midattract_start 29_felicia_walljump 30_demitri_throw}"

fail=0

echo "== 0. build identity (the dispatch fingerprint cannot see this) =="
python3 tools/build_fingerprint.py "$WIDE_ROMPATH;$ROMDIR" --set vsavjw --full \
    | sed 's/^/  WIDE  /'
python3 tools/build_fingerprint.py "$ROMDIR" --set vsavj --full \
    | sed 's/^/  stock /'

echo "== 1. emulator superset invariant (stock vsavj: reference binary vs WIDE binary) =="
if [ -n "${FBNEO_REF:-}" ] && [ -x "${FBNEO_REF}" ]; then
    for rp in $CORPUS; do
        FBNEO_BIN="$FBNEO_REF" tools/run_replay_fbneo.sh vsavj \
            "$REPO/tests/replays/$rp.rpl" "$WORK/ref_$rp.log" "$WORK/sb_ref_$rp" >/dev/null 2>&1
        tools/run_replay_fbneo.sh vsavj \
            "$REPO/tests/replays/$rp.rpl" "$WORK/new_$rp.log" "$WORK/sb_new_$rp" >/dev/null 2>&1
        if cmp -s "$WORK/ref_$rp.log" "$WORK/new_$rp.log"; then
            echo "  ok: $rp bit-identical"
        else
            echo "  FAIL: $rp — the patched binary changed STOCK vsavj behaviour"
            diff "$WORK/ref_$rp.log" "$WORK/new_$rp.log" | head -3
            fail=1
        fi
    done
else
    echo "  SKIPPED: set FBNEO_REF to a pre-WIDE fbneo binary to run this."
    echo "  NOTE: this invariant is the whole basis for allowing emulator"
    echo "        changes at all (Rule 1 v2 clause 3) — a build that has not"
    echo "        run it is NOT validated, regardless of section 2 below."
    fail_skipped=1
fi

echo "== 2. profile inertness (WIDE set vs stock set, same binary) =="
for rp in $CORPUS; do
    tools/run_replay_fbneo.sh vsavj \
        "$REPO/tests/replays/$rp.rpl" "$WORK/stock_$rp.log" "$WORK/sb_s_$rp" >/dev/null 2>&1
    FBNEO_ROMPATH="$WIDE_ROMPATH" tools/run_replay_fbneo.sh vsavjw \
        "$REPO/tests/replays/$rp.rpl" "$WORK/wide_$rp.log" "$WORK/sb_w_$rp" >/dev/null 2>&1
    if cmp -s "$WORK/stock_$rp.log" "$WORK/wide_$rp.log"; then
        echo "  ok: $rp bit-identical on the grown regions"
    else
        echo "  FAIL: $rp — a grown region is NOT inert"
        diff "$WORK/stock_$rp.log" "$WORK/wide_$rp.log" | head -3
        fail=1
    fi
done

[ "$fail" = 0 ] || { echo "FAIL: CPS-2 WIDE profile gate"; exit 1; }
if [ -n "${fail_skipped:-}" ]; then
    echo "PARTIAL: profile inert, but the emulator superset invariant was NOT run"
    exit 2
fi
echo "PASS: CPS-2 WIDE profile gate (emulator superset invariant + inertness)"
