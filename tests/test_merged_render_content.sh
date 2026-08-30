#!/bin/sh
# test_merged_render_content.sh — the MERGED build must serve all THREE
# tenants' tiles (and only where designed), measured in the emulator's own
# decoded gfx memory (M3b Phase 3 S5, 14z-83).
#
# The RAM gates are structurally blind to the video path (14z-55/60z), and
# until this gate NOTHING looked at Huitzil's or Pyron's art in any
# emulator — Donovan's band check (test_wide_render_content.sh §2) was the
# only render gate in the suite. These are H/P's FIRST.
#
# DESIGN: live A/B against the three FROZEN solo builds — no frozen hash
# files (machine-independent by construction, the standing preference).
# The solo builds' art is ratified by their own gates + playtests; the
# merged build must serve the SAME decoded tiles at the same composed
# addresses. (MIND THE BANK BITS, 14z-60y: composed address =
# code | bank<<16; all tenants ride bank 4 = y-word 0x1000 -> 0x4xxxx.)
#
# WINDOW CHOICE IS LOAD-BEARING (measured, first run of this gate): the
# merged bank 4 is the UNION of the three write sets, so merged == solo
# holds at a code ONLY where the solo tenant placed it or nobody did —
# a window containing another tenant's exclusive codes fails BY DESIGN
# (P's band head 0x4ED5 sits in the H∩P boundary; H populates codes there
# that solo-pyron leaves zero — the first run failed exactly there).
# So: D 0xAD8F (only D places >=0xAD80), H 0x0AF6 (band head; its one
# shared code is a same-source boundary tile), P 0x5000 (the first
# 16-code run fully inside P's inventory ABOVE H's band_hi 0x4EFC,
# verified statically), strip 0x86A0 (only the strip places there).
#
# Sections:
#   1. member identity (static) on the merged rompath.
#   2. BAND EQUIVALENCE, merged vs solo, decoded gfx memory:
#        D 0x4AD8F == m5_wide;  H 0x40AF6 == hui41;  P 0x45000 == pyron21;
#        the RELOCATED STRIP 0x486A0 == hui41 (the S3 placement, live);
#        merged bank 2 @ 0x2AD8F == PRISTINE (de-substitution held);
#        and the four tenant windows are pairwise DISTINCT (a comparison
#        of two broken dumps reads "identical" — RH-18; distinctness +
#        the poison control below are the non-vacuity proof).
#   3. POISON CONTROL: group C zeroed + one pristine-shadow member — the
#      identity audit must reject it AND every tenant window's dump must
#      change (the instrument sees group C, all four windows).
#   4. LIVENESS: the three real pick replays (36 D / 37 H / 40 P) each
#      complete on the merged build with a live framebuffer stream.
#
# Usage: ROMDIR=... tests/test_merged_render_content.sh [merged_rompath]
#   env MAME_WIDE_BIN (default ~/.cache/vampire-saved/mame/cps2)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-83 (S5): the MERGED render gate — H/P's FIRST render gates anywhere.
#   Live A/B vs the three frozen solo builds in decoded gfx memory (no frozen
#   hashes): D 0x4AD8F, H 0x40AF6, P 0x45000, the relocated strip 0x486A0,
#   group-B pristine at 0x2AD8F, pairwise-distinct check, 4-window poison
#   control, 3 pick- replay liveness. WINDOW CHOICE IS LOAD-BEARING (header):
#   merged bank 4 is a UNION — a window holding another tenant's exclusive
#   codes fails BY DESIGN. ~25 min
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

MERGED="${1:-$REPO/build/m3b_merged21/rompath}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
MAME_WIDE_BIN="${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
# THE SOLO REFERENCES MUST BE BUILDS THAT STILL BOOT ON THE CURRENT
# EMULATOR BINARY, and that is not automatic (14z-92). WIDE v1.1 (14z-86)
# made the Z80 driver members `vsw.z01/z02` content members, and v1.2 made
# `vsw.21m/22m` content members with sentinel CRCs — so a reference frozen
# before those profile versions is REFUSED BY MAME ("vsw.z01 NOT FOUND",
# "vsw.21m WRONG CHECKSUMS") and its leg produces nothing at all.
# `build/hui31` was exactly that: this gate had been un-runnable on its
# huitzil legs since 14z-86 and nobody saw it, because a dead leg was
# reported as a content mismatch against an empty value (both fixed here —
# see chk()). Re-pointed to the CURRENT frozen solo, huitzil-m15.
# WHEN A TENANT IS RE-FROZEN, RE-POINT ITS ROW HERE. D and P still name
# older builds (donovan-m3a / pyron-m3); those boot and pass today, but
# they are one profile bump away from the same failure.
D_RP="$REPO/build/don_m18/rompath"   # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
H_RP="$REPO/build/hui52/rompath"    # re-pointed 14z-105 (window freeze); re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
P_RP="$REPO/build/pyron36/rompath"  # re-pointed 14z-105 (window freeze); re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b

[ -f "$MERGED/vsavjw.zip" ] || {
    echo "SKIP: no merged build at $MERGED (tools/build_merged.sh)"; exit 0; }
for rp in "$D_RP" "$H_RP" "$P_RP"; do
    [ -f "$rp/vsavjw.zip" ] || { echo "SKIP: no solo build at $rp"; exit 0; }
done
[ -x "$MAME_WIDE_BIN" ] || { echo "SKIP: no WIDE MAME"; exit 0; }
"$MAME_WIDE_BIN" -listfull vsavjw >/dev/null 2>&1 || {
    echo "FAIL: $MAME_WIDE_BIN does not know vsavjw"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# NO `-verifyroms` PRECONDITION HERE, and it is worth saying why so it is
# not "helpfully" added later (tried and reverted, 14z-92): the group-C
# descriptor CRCs are deliberate SENTINELS (0xdec0de31..37, HANDOFF
# "Group C descriptor CRCs are SENTINELS") and content members resolve by
# NAME, so `-verifyroms vsavjw` reports every content build BAD — including
# builds that boot and render perfectly. It fails all four rompaths here
# and is therefore a dead instrument for this gate. The live check is the
# dump itself: a leg that cannot boot produces no dump, and chk() below
# reports that as a DEAD LEG rather than as a content mismatch.

echo "== 1. member identity on the merged rompath =="
if python3 tools/audit_romset_identity.py "$MERGED" --quiet; then
    echo "  ok: no member shadows a patched member"
else
    echo "  FAIL: member identity"; fail=1
fi

echo "== 2. band equivalence: merged vs the frozen solo builds =="
band() {  # band <tag> <rompath> <window>
    MAME_BIN="$MAME_WIDE_BIN" MAME_ROMPATH="$2;$ROMDIR" \
    MAME_SANDBOX="$WORK/gsb_$1" GFX_WINDOWS="$3" TRACE_OUT="$WORK/$1.gfx" \
        tools/run_mame.sh vsavjw \
        -autoboot_script "$REPO/tests/lua/gfx_region_dump.lua" \
        > "$WORK/$1.gfxrun" 2>&1
    grep -q "^GFXDUMPSUMMARY" "$WORK/$1.gfx" || {
        echo "  dump $1 did not complete" >&2; return 1; }
    awk '/^GFX /{print $5}' "$WORK/$1.gfx"
}
# pristine group-B window needs a stock set; use the vanilla vsavj
bp() {  # pristine bank-2 window via stock vsavj
    MAME_BIN="$MAME_WIDE_BIN" MAME_ROMPATH="$ROMDIR" \
    MAME_SANDBOX="$WORK/gsb_$1" GFX_WINDOWS="$2" TRACE_OUT="$WORK/$1.gfx" \
        tools/run_mame.sh vsavj \
        -autoboot_script "$REPO/tests/lua/gfx_region_dump.lua" \
        > "$WORK/$1.gfxrun" 2>&1
    grep -q "^GFXDUMPSUMMARY" "$WORK/$1.gfx" || {
        echo "  dump $1 did not complete" >&2; return 1; }
    awk '/^GFX /{print $5}' "$WORK/$1.gfx"
}

m_d="$(band m_d "$MERGED" 4ad8f:16)"     || fail=1
m_h="$(band m_h "$MERGED" 40af6:16)"     || fail=1
m_p="$(band m_p "$MERGED" 45000:16)"     || fail=1
m_s="$(band m_s "$MERGED" 486a0:16)"     || fail=1
m_b2="$(band m_b2 "$MERGED" 2ad8f:16)"   || fail=1
s_d="$(band s_d "$D_RP" 4ad8f:16)"       || fail=1
s_h="$(band s_h "$H_RP" 40af6:16)"       || fail=1
s_p="$(band s_p "$P_RP" 45000:16)"       || fail=1
s_s="$(band s_s "$H_RP" 486a0:16)"       || fail=1
prist="$(bp prist 2ad8f:16)"             || fail=1

chk() {  # chk <label> <got> <want>
    # 14z-92: a DEAD LEG and a real mismatch must not look alike. An empty
    # operand means the dump never ran (typically a reference build that
    # predates the current WIDE profile and is refused by MAME) — reporting
    # that as "merged <fnv> != solo <empty>" reads as a content regression
    # on the build under test, which is the opposite of the truth. Name it.
    if [ -z "$2" ] || [ -z "$3" ]; then
        echo "  FAIL: $1 — DEAD LEG, no gfx dump produced" \
             "(merged='$2' solo='$3')"
        echo "        a reference frozen before WIDE v1.1/v1.2 is REFUSED by"
        echo "        MAME (vsw.z01 NOT FOUND / vsw.21m WRONG CHECKSUMS)."
        echo "        This is an instrument failure, NOT a verdict on the"
        echo "        merged build. Check the .gfxrun log before believing"
        echo "        anything about content."
        fail=1
    elif [ "$2" = "$3" ]; then
        echo "  ok: $1 ($2)"
    else
        echo "  FAIL: $1 — merged $2 != solo $3"; fail=1
    fi
}
chk "D band  0x4AD8F == don_m18 (label re-pointed 14z-117)"  "$m_d" "$s_d"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
chk "H band  0x40AF6 == hui52 (label re-pointed 14z-117)"    "$m_h" "$s_h"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
chk "P band  0x45000 == pyron36 (label re-pointed 14z-117)"  "$m_p" "$s_p"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
chk "strip   0x486A0 == hui52 (the S3 relocation, live; label re-pointed 14z-117)" "$m_s" "$s_s"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
chk "bank 2  0x2AD8F == PRISTINE (de-substitution held)" "$m_b2" "$prist"
distinct="$(printf '%s\n%s\n%s\n%s\n' "$m_d" "$m_h" "$m_p" "$m_s" | sort -u | wc -l | tr -d ' ')"
if [ "$distinct" = 4 ]; then
    echo "  ok: the four tenant windows are pairwise distinct (not a blind dump)"
else
    echo "  FAIL: only $distinct distinct hashes across the 4 tenant windows"
    fail=1
fi

echo "== 3. poison control: zeroed group C + one shadow member =="
mkdir -p "$WORK/poison"
cp "$MERGED"/*.zip "$WORK/poison/"
python3 - "$WORK/poison/vsavjw.zip" "$ROMDIR/vsav.zip" <<'PYEOF'
import shutil, sys, zipfile
target, refzip = sys.argv[1], sys.argv[2]
zero = {f"vsw.{n}m": bytes(0x400000) for n in (31, 33, 35, 37)}
shadow = {"vsw.21m": zipfile.ZipFile(refzip).read("vm3.13m")}
shutil.copyfile(target, target + ".orig")
src = zipfile.ZipFile(target + ".orig")
with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as out:
    for n in src.namelist():
        out.writestr(n, zero.get(n) or shadow.get(n) or src.read(n))
PYEOF
if python3 tools/audit_romset_identity.py "$WORK/poison" --quiet >/dev/null 2>&1; then
    echo "  FAIL: the audit PASSED a set with a pristine-shadow member"; fail=1
else
    echo "  ok: the member-identity audit rejects the shadow"
fi
for w in 4ad8f:D 40af6:H 45000:P 486a0:strip; do
    win="${w%%:*}"; tag="${w#*:}"
    pz="$(band "poi_$tag" "$WORK/poison" "$win:16")" || true
    case "$tag" in D) mv="$m_d";; H) mv="$m_h";; P) mv="$m_p";; strip) mv="$m_s";; esac
    if [ -n "$pz" ] && [ "$pz" != "$mv" ]; then
        echo "  ok: poisoned $tag window differs — instrument live"
    else
        echo "  FAIL: poisoned $tag window unchanged — instrument blind"; fail=1
    fi
done

echo "== 4. liveness: the three real pick replays on the merged build =="
for r in 36_pick_tenant_cell 37_pick_huitzil_cell 40_pick_pyron_cell; do
    MAME_BIN="$MAME_WIDE_BIN" MAME_ROMPATH="$MERGED;$ROMDIR" \
    MAME_SANDBOX="$WORK/sbx_$r" REPLAY="$REPO/tests/replays/$r.rpl" \
    CHECKSUM_OUT="$WORK/$r.ram" VIDEO_OUT="$WORK/$r.vid" \
        tools/run_mame.sh vsavjw -autoboot_script "$REPO/tests/lua/replay.lua" \
        > "$WORK/$r.run" 2>&1 || true
    if grep -q "^END " "$WORK/$r.vid" 2>/dev/null; then
        dis="$(awk '{print $2}' "$WORK/$r.vid" | sort -u | wc -l | tr -d ' ')"
        if [ "$dis" -gt 100 ]; then
            echo "  ok: $r completed, live framebuffer ($dis distinct frames)"
        else
            echo "  FAIL: $r framebuffer degenerate ($dis distinct)"; fail=1
        fi
    else
        echo "  FAIL: $r did not complete"; fail=1
    fi
done

[ "$fail" = 0 ] || { echo "FAIL: merged content-rendering gate"; exit 1; }
echo "PASS: merged content-rendering gate — all three tenants' bands + the"
echo "      relocated strip serve the frozen solo art; de-substitution held;"
echo "      poison control fired on all four windows; three pick replays live"
