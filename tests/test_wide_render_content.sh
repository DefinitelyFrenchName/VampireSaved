#!/bin/sh
# test_wide_render_content.sh — the WIDE track must SERVE the ported
# content's tiles (and only where designed), measured in the emulator's
# own decoded gfx memory.
#
# WHY THIS EXISTS (14z-60z). Donovan and Anita rendered as garbage on the
# WIDE track for two sessions while EVERY automated gate stayed green: the
# RAM gates are structurally blind to the video path (14z-55) and nothing
# looked at ported content on the WIDE track, so a human playtest was the
# only detector. This is that missing gate.
#
# RE-SHAPED 14z-67 for the m3a de-substitution (the original gate went
# STALE at the 14z-64 freeze and sat failing, undetected, because it is
# not in the battery — found in the 14z-67 sweep). The original compared
# cross-track PIXELS on a slot-0x0F replay and dumped the band at the
# stock bank address for both tracks. Post-m3a both are wrong BY DESIGN:
# the WIDE track restores Jedah at slot 0x0F (replay 11 renders JEDAH
# there) and serves Donovan from group C bank 4 (0x4AD8F, not 0x2AD8F).
# Cross-track pixel identity is gone by design; the content proof is the
# emulator's decoded tile memory, which is exactly what its renderer
# composes from (B4/B5 proved the path from there to pixels on both
# emulators, work RAM AND framebuffer).
#
# Sections:
#   1. MEMBER IDENTITY (static) — no member of either set carries the
#      pristine bytes of a member that build patched.
#   2. BAND EQUIVALENCE (the content check, in-emulator) — the decoded
#      tiles at Donovan's band:
#        WIDE @ bank 4 (0x4AD8F)  == stock @ bank 2 (0x2AD8F)   [his art]
#        WIDE @ bank 2 (0x2AD8F)  == PRISTINE                   [Jedah
#          restored — THE DE-SUBSTITUTION INVARIANT, asserted]
#        stock @ bank 2           != PRISTINE                   [dump not
#          blind]
#   3. POSITIVE CONTROL — group C zero-poisoned: the member audit must
#      reject it (a pristine-zero revert of patched members) AND the
#      WIDE band dump must change. A gate never shown to fail is not
#      evidence.
#   4. LIVENESS — replay 36 (the real cell-0x13 pick) completes on the
#      WIDE build with a live framebuffer stream (the render path is
#      exercised end to end, not just the tile memory).
#
# Usage: ROMDIR=... tests/test_wide_render_content.sh [stock_rompath] [wide_rompath]
#   env MAME_WIDE_BIN  WIDE-patched MAME (default ~/.cache/vampire-saved/mame/cps2)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

STOCK="${1:-$REPO/build/m5_stock13/rompath}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
WIDE="${2:-$REPO/build/m5_wide/rompath}"
MAME_WIDE_BIN="${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"

[ -f "$STOCK/vsavj.zip" ]  || { echo "no stock build at $STOCK (tools/build_donovan.sh 6 build/m5_stock13)"; exit 1; }  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$WIDE/vsavjw.zip" ] || { echo "no WIDE build at $WIDE (GEN_FLAGS=... --profile cps2-wide-v1)"; exit 1; }
[ -x "$MAME_WIDE_BIN" ]   || { echo "no WIDE-patched MAME at $MAME_WIDE_BIN (tools/setup_mame.sh)"; exit 1; }
"$MAME_WIDE_BIN" -listfull vsavjw >/dev/null 2>&1 || {
    echo "FAIL: $MAME_WIDE_BIN does not know vsavjw — it does not carry the profile"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

echo "== 1. member identity: nothing shadows a patched member =="
for rp in "$STOCK" "$WIDE"; do
    if python3 tools/audit_romset_identity.py "$rp" --quiet; then
        echo "  ok: $(basename "$(dirname "$rp")")"
    else
        echo "  FAIL: $(basename "$(dirname "$rp")") — a member shadows a patched one"
        fail=1
    fi
done

echo "== 2. band equivalence: the emulator's decoded tiles at Donovan's band =="
# MIND THE BANK BITS (the 14z-60y lesson): the sprite record's code word
# is 0xAD8F; the composed address = code | bank<<16. Stock = bank 2
# (y-word 0x4000) -> 0x2AD8F. WIDE (m3a, variant id) = bank 4 (y-word
# 0x1000, the bit-12 promote) -> 0x4AD8F.
band() {  # band <tag> <set> <rompath> <window>
    MAME_BIN="$MAME_WIDE_BIN" MAME_ROMPATH="$3;$ROMDIR" MAME_SANDBOX="$WORK/gsb_$1" \
    GFX_WINDOWS="$4" TRACE_OUT="$WORK/$1.gfx" \
        tools/run_mame.sh "$2" -autoboot_script "$REPO/tests/lua/gfx_region_dump.lua" \
        > "$WORK/$1.gfxrun" 2>&1
    grep -q "^GFXDUMPSUMMARY" "$WORK/$1.gfx" || { echo "  dump $1 did not complete"; return 1; }
    awk '/^GFX /{print $5}' "$WORK/$1.gfx"      # the fnv=<hash> field
}
b_stock="$(band bstock vsavj  "$STOCK"  2ad8f:16)"  || fail=1
b_wide4="$(band bwide4 vsavjw "$WIDE"   4ad8f:16)"  || fail=1
b_wide2="$(band bwide2 vsavjw "$WIDE"   2ad8f:16)"  || fail=1
b_prist="$(band bpri   vsavj  "$ROMDIR" 2ad8f:16)"  || fail=1

if [ -n "$b_wide4" ] && [ "$b_wide4" = "$b_stock" ]; then
    echo "  ok: WIDE bank 4 serves the same Donovan tiles as stock bank 2 ($b_wide4)"
else
    echo "  FAIL: WIDE bank-4 band $b_wide4 != stock bank-2 band $b_stock"
    fail=1
fi
if [ -n "$b_wide2" ] && [ "$b_wide2" = "$b_prist" ]; then
    echo "  ok: WIDE bank 2 reads PRISTINE — Jedah restored (the de-substitution invariant)"
else
    echo "  FAIL: WIDE bank-2 band $b_wide2 != pristine $b_prist — group B not pristine"
    fail=1
fi
if [ -n "$b_stock" ] && [ "$b_stock" != "$b_prist" ]; then
    echo "  ok: stock band differs from pristine — the dump is not blind"
else
    echo "  FAIL: the stock band reads pristine — wrong band or the build does not patch it"
    fail=1
fi

echo "== 3. positive control: a poisoned set must FAIL both instruments =="
# TWO poisons in one set, one per instrument's contract:
#   - group C zeroed (a reverted band) -> the BAND DUMP must change;
#   - vsw.21m := pristine vm3.13m bytes (a true SHADOW: a patched
#     member's pristine bytes under another name — the audit's class,
#     exactly the 14z-60z loader hazard).
mkdir -p "$WORK/poison"
cp "$WIDE"/*.zip "$WORK/poison/" 2>/dev/null || true
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
    echo "  FAIL: the audit PASSED a set with a pristine-shadow member"
    fail=1
else
    echo "  ok: the member-identity audit rejects the shadow (the 14z-60z class)"
fi
b_poison="$(band bpoi vsavjw "$WORK/poison" 4ad8f:16)" || true
if [ -n "$b_poison" ] && [ "$b_poison" != "$b_wide4" ]; then
    echo "  ok: the poisoned band dump differs ($b_poison) — the instrument sees it"
else
    echo "  FAIL: the poisoned set dumps the same band — the instrument is blind"
    fail=1
fi

echo "== 4. liveness: the real cell-0x13 pick renders on the WIDE build =="
MAME_BIN="$MAME_WIDE_BIN" MAME_ROMPATH="$WIDE;$ROMDIR" \
MAME_SANDBOX="$WORK/sbx_live" REPLAY="$REPO/tests/replays/36_pick_tenant_cell.rpl" \
CHECKSUM_OUT="$WORK/live.ram" VIDEO_OUT="$WORK/live.vid" \
    tools/run_mame.sh vsavjw -autoboot_script "$REPO/tests/lua/replay.lua" \
    > "$WORK/live.run" 2>&1 || true
if grep -q "^END " "$WORK/live.vid" 2>/dev/null; then
    dis="$(awk '{print $2}' "$WORK/live.vid" | sort -u | wc -l | tr -d ' ')"
    if [ "$dis" -gt 100 ]; then
        echo "  ok: replay 36 completed with a live framebuffer ($dis distinct frames)"
    else
        echo "  FAIL: framebuffer stream degenerate ($dis distinct checksums)"
        fail=1
    fi
else
    echo "  FAIL: the replay-36 run did not complete"
    fail=1
fi

[ "$fail" = 0 ] || { echo "FAIL: WIDE content-rendering gate"; exit 1; }
echo "PASS: WIDE content-rendering gate (member identity + band equivalence"
echo "      incl. the de-substitution invariant + a positive control + liveness)"
