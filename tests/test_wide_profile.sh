#!/bin/sh
# test_wide_profile.sh — CPS-2 WIDE profile gate (Phase B).
#
# Two invariants, both required by Rule 1 v2 (docs/project/cps2_wide.md):
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
# Both compare, over the legacy corpus, BOTH:
#   * the per-frame work-RAM checksum (the basis the ROM-side gates use), and
#   * the per-frame FRAMEBUFFER checksum (FBNEO_HVIDEO).
# The framebuffer half is not optional garnish: the RAM checksum is BLIND to
# the entire video path — the harness historically ran with pBurnDraw=NULL —
# so a rendering change such as the WIDE 19-bit sprite tile address produces
# byte-identical RAM logs whether it works or is catastrophically broken.
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
if [ -n "${FBNEO_REF:-}" ] && [ -x "${FBNEO_REF}" ] \
   && grep -q "CPS-2 WIDE v1" "${FBNEO_REF}" 2>/dev/null; then
    # Paid for 14z-59e: `WIDE=0 tools/setup_fbneo.sh` used to only SKIP
    # applying the profile patch, never revert it, so a reference built from
    # a tree that already carried it came out WITH the profile. Section 1
    # then compared WIDE against WIDE and passed trivially — the invariant
    # that justifies allowing emulator changes at all was measuring nothing.
    # The driver title string is compiled in, so this catches it statically.
    echo "  FAIL: FBNEO_REF carries the CPS-2 WIDE profile — it is NOT a"
    echo "        pre-patch reference, and this comparison would be vacuous."
    echo "        Rebuild it: WIDE=0 tools/setup_fbneo.sh (now reverts properly)"
    fail=1
elif [ -n "${FBNEO_REF:-}" ] && [ -x "${FBNEO_REF}" ]; then
    for rp in $CORPUS; do
        FBNEO_HVIDEO="$WORK/ref_$rp.vid" FBNEO_BIN="$FBNEO_REF" tools/run_replay_fbneo.sh vsavj \
            "$REPO/tests/replays/$rp.rpl" "$WORK/ref_$rp.log" "$WORK/sb_ref_$rp" >/dev/null 2>&1
        FBNEO_HVIDEO="$WORK/new_$rp.vid" tools/run_replay_fbneo.sh vsavj \
            "$REPO/tests/replays/$rp.rpl" "$WORK/new_$rp.log" "$WORK/sb_new_$rp" >/dev/null 2>&1
        if cmp -s "$WORK/ref_$rp.log" "$WORK/new_$rp.log" \
           && cmp -s "$WORK/ref_$rp.vid" "$WORK/new_$rp.vid"; then
            echo "  ok: $rp bit-identical (RAM + framebuffer)"
        else
            echo "  FAIL: $rp — the patched binary changed STOCK vsavj behaviour"
            cmp -s "$WORK/ref_$rp.log" "$WORK/new_$rp.log" || echo "    (work RAM differs)"
            cmp -s "$WORK/ref_$rp.vid" "$WORK/new_$rp.vid" || echo "    (framebuffer differs)"
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
    FBNEO_HVIDEO="$WORK/stock_$rp.vid" tools/run_replay_fbneo.sh vsavj \
        "$REPO/tests/replays/$rp.rpl" "$WORK/stock_$rp.log" "$WORK/sb_s_$rp" >/dev/null 2>&1
    FBNEO_HVIDEO="$WORK/wide_$rp.vid" FBNEO_ROMPATH="$WIDE_ROMPATH" tools/run_replay_fbneo.sh vsavjw \
        "$REPO/tests/replays/$rp.rpl" "$WORK/wide_$rp.log" "$WORK/sb_w_$rp" >/dev/null 2>&1
    if cmp -s "$WORK/stock_$rp.log" "$WORK/wide_$rp.log" \
       && cmp -s "$WORK/stock_$rp.vid" "$WORK/wide_$rp.vid"; then
        echo "  ok: $rp bit-identical on the grown regions (RAM + framebuffer)"
    else
        echo "  FAIL: $rp — a grown region is NOT inert"
        cmp -s "$WORK/stock_$rp.log" "$WORK/wide_$rp.log" || echo "    (work RAM differs)"
        cmp -s "$WORK/stock_$rp.vid" "$WORK/wide_$rp.vid" || echo "    (framebuffer differs)"
        fail=1
    fi
done

[ "$fail" = 0 ] || { echo "FAIL: CPS-2 WIDE profile gate"; exit 1; }
if [ -n "${fail_skipped:-}" ]; then
    echo "PARTIAL: profile inert, but the emulator superset invariant was NOT run"
    exit 2
fi
# ── 3. B4 CANARY: are the new gfx banks actually USABLE? ────────────────
# Inertness (sections 1-2) only proves the profile does no harm. This
# proves the 19-bit tile address REACHES the appended banks: with
# CPS2_WIDE_CANARY=1 the emulator relocates bank-2/3 sprites into WIDE
# banks 4/5 at draw time, and the romset must carry group C as a byte copy
# of group B (build with --gfx-copy-group-b). Stock ROM both sides, so RAM
# is identical by construction and only pixels can move.
#
# That copy shape must NEVER ship: it carries group B's CRCs, and both
# emulators resolve a ROM entry by hash before name, so in a set whose
# group B is PATCHED the loader serves pristine tiles for it (14z-60z —
# how the WIDE build rendered Donovan with vanilla art). The canary romset
# therefore lives in its own directory; the shippable overlay is zero-filled.
CANARY_ROMPATH="${CANARY_ROMPATH:-$REPO/build/wide_canary/rompath}"
if python3 - "$CANARY_ROMPATH" <<'PYEOF'
import sys, zipfile, hashlib, os
z = zipfile.ZipFile(os.path.join(sys.argv[1], "vsavjw.zip"))
p = zipfile.ZipFile(os.path.join(os.environ["ROMDIR"], "vsav.zip"))
ok = all(hashlib.sha1(z.read(c)).digest() == hashlib.sha1(p.read(b)).digest()
         for c, b in zip(("vsw.31m","vsw.33m","vsw.35m","vsw.37m"),
                         ("vm3.14m","vm3.16m","vm3.18m","vm3.20m"))
         if c in z.namelist())
sys.exit(0 if ok and "vsw.31m" in z.namelist() else 1)
PYEOF
then
    echo "== 3. B4 canary: sprites served from the appended gfx banks =="
    for rp in $CORPUS; do
        FBNEO_HVIDEO="$WORK/cs_$rp.vid" tools/run_replay_fbneo.sh vsavj \
            "$REPO/tests/replays/$rp.rpl" "$WORK/cs_$rp.log" "$WORK/csb_$rp" >/dev/null 2>&1
        CPS2_WIDE_CANARY=1 FBNEO_HVIDEO="$WORK/cw_$rp.vid" FBNEO_ROMPATH="$CANARY_ROMPATH" \
            tools/run_replay_fbneo.sh vsavjw \
            "$REPO/tests/replays/$rp.rpl" "$WORK/cw_$rp.log" "$WORK/cwb_$rp" >/dev/null 2>&1
        if cmp -s "$WORK/cs_$rp.log" "$WORK/cw_$rp.log" \
           && cmp -s "$WORK/cs_$rp.vid" "$WORK/cw_$rp.vid"; then
            echo "  ok: $rp identical with sprites fetched from banks 4/5"
        else
            echo "  FAIL: $rp — the appended banks do not render correctly"
            fail=1
        fi
    done
else
    echo "== 3. B4 canary: SKIPPED (no canary romset at $CANARY_ROMPATH;"
    echo "     build it THERE — never over the shippable overlay — with"
    echo "     tools/build_wide_romset.py \"\$ROMDIR\" build/wide_canary/rompath \\"
    echo "         --qsound 2 --gfx 4 --prg 4 --gfx-copy-group-b) =="
fi

[ "$fail" = 0 ] || { echo "FAIL: CPS-2 WIDE profile gate"; exit 1; }
echo "PASS: CPS-2 WIDE profile gate (emulator superset invariant + inertness,"
echo "      work RAM AND framebuffer, over $(echo $CORPUS | wc -w | tr -d ' ') replays)"
echo "      plus the B4 canary: the 19-bit path REACHES the appended banks.)"
