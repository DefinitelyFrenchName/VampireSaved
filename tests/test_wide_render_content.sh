#!/bin/sh
# test_wide_render_content.sh — the WIDE track must RENDER the ported
# content exactly as the stock track does.
#
# WHY THIS EXISTS (14z-60z). Donovan and Anita rendered as garbage on the
# WIDE track for two sessions while EVERY automated gate stayed green: the
# RAM gates are structurally blind to the video path (14z-55), the pixel
# gate test_gfx_menus.sh covers MENUS on the stock track, and the WIDE
# profile gate proves the profile inert on LEGACY content. Nothing looked
# at ported content on the WIDE track, so a human playtest was the only
# detector. This is that missing gate.
#
# The bug it was written against: the WIDE romset's appended group C was a
# byte copy of the stock group B (the B4 canary shape), so it carried group
# B's CRCs. Both emulators resolve a ROM entry by HASH before falling back
# to its NAME, so group B's declared CRC matched the canary copies and the
# loader served PRISTINE tiles for the members the build had patched.
# Donovan drew with vanilla art: right geometry, wrong pixels, silent.
#
# Three sections:
#   1. MEMBER IDENTITY (static, no emulator) — no member of either set may
#      carry the pristine bytes of a member that build patched.
#   2. PIXEL A/B — per-frame framebuffer checksums of a Donovan replay on
#      both tracks must be IDENTICAL. Measured 14z-60z: the tracks do not
#      skew at all on this pair (3,720/3,720 frames identical), so this is
#      an exact comparison, not an anchor comparison. If a future change
#      makes the tracks skew, fix the skew or move to anchors deliberately
#      — do not relax this to "close enough".
#      NOTE: work RAM is deliberately NOT compared here. Donovan replays
#      legitimately diverge in RAM between tracks (the sfx helper is live
#      on WIDE, stubbed on stock — tests/test_dualtrack.sh owns that).
#   3. POSITIVE CONTROL — a WIDE set poisoned back into the 14z-60z shape
#      must FAIL both section 1 and section 2. A gate that has never been
#      shown to fail is not evidence (CLAUDE.md §4: verdict logic is itself
#      tested).
#
# Usage: ROMDIR=... tests/test_wide_render_content.sh [stock_rompath] [wide_rompath]
#   env REPLAYS      replays to compare (default 11_pick_donovan)
#   env MAME_WIDE_BIN  WIDE-patched MAME (default ~/.cache/vampire-saved/mame/cps2)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

STOCK="${1:-$REPO/build/m5_stock/rompath}"
WIDE="${2:-$REPO/build/m5_wide/rompath}"
REPLAYS="${REPLAYS:-11_pick_donovan}"
MAME_WIDE_BIN="${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"

[ -f "$STOCK/vsavj.zip" ]  || { echo "no stock build at $STOCK (tools/build_donovan.sh 6 build/m5_stock)"; exit 1; }
[ -f "$WIDE/vsavjw.zip" ] || { echo "no WIDE build at $WIDE (GEN_FLAGS=... --profile cps2-wide-v1)"; exit 1; }
[ -x "$MAME_WIDE_BIN" ]   || { echo "no WIDE-patched MAME at $MAME_WIDE_BIN (tools/setup_mame.sh)"; exit 1; }
"$MAME_WIDE_BIN" -listfull vsavjw >/dev/null 2>&1 || {
    echo "FAIL: $MAME_WIDE_BIN does not know vsavjw — it does not carry the profile"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# per-frame framebuffer checksums for one (set, rompath, replay)
video() {  # video <tag> <set> <rompath> <replay>
    MAME_BIN="$MAME_WIDE_BIN" MAME_ROMPATH="$3;$ROMDIR" \
    MAME_SANDBOX="$WORK/sbx_$1" REPLAY="$REPO/tests/replays/$4.rpl" \
    CHECKSUM_OUT="$WORK/$1.ram" VIDEO_OUT="$WORK/$1.vid" \
        tools/run_mame.sh "$2" -autoboot_script "$REPO/tests/lua/replay.lua" \
        > "$WORK/$1.run" 2>&1
    grep -q "^END " "$WORK/$1.vid" || { echo "  run $1 produced no END line"; cat "$WORK/$1.run"; return 1; }
}

echo "== 1. member identity: nothing shadows a patched member =="
for rp in "$STOCK" "$WIDE"; do
    if python3 tools/audit_romset_identity.py "$rp" --quiet; then
        echo "  ok: $(basename "$(dirname "$rp")")"
    else
        echo "  FAIL: $(basename "$(dirname "$rp")") — a member shadows a patched one"
        fail=1
    fi
done

echo "== 2. pixel A/B: the WIDE track renders ported content like stock =="
for rp in $REPLAYS; do
    video "s_$rp" vsavj  "$STOCK" "$rp" || { fail=1; continue; }
    video "w_$rp" vsavjw "$WIDE"  "$rp" || { fail=1; continue; }
    if cmp -s "$WORK/s_$rp.vid" "$WORK/w_$rp.vid"; then
        echo "  ok: $rp — $(grep -c . "$WORK/s_$rp.vid") frames pixel-identical across tracks"
    else
        first="$(diff "$WORK/s_$rp.vid" "$WORK/w_$rp.vid" | grep '^<' | head -1 | awk '{print $1}' | tr -d '<' )"
        echo "  FAIL: $rp — framebuffer differs from the stock track (first divergent frame:$first)"
        echo "        Snapshot it: tests/lua/snapshot_frames.lua with SNAP_FRAMES=$first"
        fail=1
    fi
done

echo "== 3. positive control: the 14z-60z shape must FAIL both checks =="
# Rebuild the poisoned set: group C = byte copies of the stock group B, which
# is exactly what --gfx-copy-group-b writes and what shipped by accident.
mkdir -p "$WORK/poison"
cp "$WIDE"/*.zip "$WORK/poison/" 2>/dev/null || true
python3 - "$WORK/poison/vsavjw.zip" "$ROMDIR/vsav.zip" <<'PYEOF'
import shutil, sys, zipfile
target, parent = sys.argv[1], sys.argv[2]
pz = zipfile.ZipFile(parent)
copy = dict(zip(("vsw.31m", "vsw.33m", "vsw.35m", "vsw.37m"),
                ("vm3.14m", "vm3.16m", "vm3.18m", "vm3.20m")))
# read from a copy: rewriting `target` in place while it is open truncates it
shutil.copyfile(target, target + ".orig")
src = zipfile.ZipFile(target + ".orig")
names = src.namelist()
with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as out:
    for n in names:
        out.writestr(n, pz.read(copy[n]) if n in copy else src.read(n))
PYEOF

if python3 tools/audit_romset_identity.py "$WORK/poison" --quiet >/dev/null 2>&1; then
    echo "  FAIL: the audit PASSED a poisoned set — it cannot see the bug it exists for"
    fail=1
else
    echo "  ok: the member-identity audit rejects the poisoned set"
fi

ctl_rp="$(echo $REPLAYS | awk '{print $1}')"
if video "p_$ctl_rp" vsavjw "$WORK/poison" "$ctl_rp"; then
    if cmp -s "$WORK/s_$ctl_rp.vid" "$WORK/p_$ctl_rp.vid"; then
        echo "  FAIL: the poisoned set rendered IDENTICALLY to stock — the pixel"
        echo "        comparison is blind (wrong replay, or the tiles are not reached)"
        fail=1
    else
        n="$(diff "$WORK/s_$ctl_rp.vid" "$WORK/p_$ctl_rp.vid" | grep -c '^<')"
        echo "  ok: the poisoned set diverges from stock on $n frames — the gate sees it"
    fi
else
    echo "  FAIL: the poisoned control run did not complete"
    fail=1
fi

echo "== 4. the decoded tiles at the ported band are the BUILD's, not pristine =="
# Sharper than pixels and independent of them: read the tile bytes the
# emulator actually holds at the address Donovan's select sprite composes.
# MIND THE BANK BITS. The sprite record's code word is 0xAD8F but its y-word
# selects bank 2, so the address is 0x2AD8F:
#     tile = code | ((y & 0x6000) << 3)
# Dumping tile 0xAD8F instead reads an unrelated band that is vanilla on
# every build — which is exactly how the load hypothesis was first declared
# dead (14z-60y) while it was in fact the cause.
BAND="2ad8f:16"
band() {  # band <tag> <set> <rompath>
    MAME_BIN="$MAME_WIDE_BIN" MAME_ROMPATH="$3;$ROMDIR" MAME_SANDBOX="$WORK/gsb_$1" \
    GFX_WINDOWS="$BAND" TRACE_OUT="$WORK/$1.gfx" \
        tools/run_mame.sh "$2" -autoboot_script "$REPO/tests/lua/gfx_region_dump.lua" \
        > "$WORK/$1.gfxrun" 2>&1
    grep -q "^GFXDUMPSUMMARY" "$WORK/$1.gfx" || { echo "  dump $1 did not complete"; return 1; }
    awk '/^GFX /{print $5}' "$WORK/$1.gfx"      # the fnv=<hash> field
}
b_stock="$(band bstock vsavj  "$STOCK")"   || fail=1
b_wide="$(band bwide  vsavjw "$WIDE")"     || fail=1
b_pristine="$(band bpri vsavj "$ROMDIR")"  || fail=1

if [ "$b_wide" = "$b_stock" ] && [ -n "$b_wide" ]; then
    echo "  ok: WIDE serves the same tiles as the stock track ($b_wide)"
else
    echo "  FAIL: WIDE tiles $b_wide != stock tiles $b_stock at the ported band"
    fail=1
fi
if [ "$b_stock" != "$b_pristine" ] && [ -n "$b_pristine" ]; then
    echo "  ok: and both differ from PRISTINE ($b_pristine) — the dump is not blind"
else
    echo "  FAIL: the ported band reads pristine on the stock track too — wrong band,"
    echo "        or this build does not patch it (the instrument proves nothing)"
    fail=1
fi

[ "$fail" = 0 ] || { echo "FAIL: WIDE content-rendering gate"; exit 1; }
echo "PASS: WIDE content-rendering gate (member identity + pixel A/B vs stock"
echo "      + a positive control that the comparison actually detects the fault"
echo "      + the decoded tile band, with a pristine negative control)"
