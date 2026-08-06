#!/bin/sh
# test_tenant_hud.sh — the variant-id HUD fix (14z-63, phase 3 item 4):
# a tenant at 0x13 must show its OWN in-match mugshot and name plate,
# and the host's own HUD cells must stay pristine.
#
# MECHANISM (measured; docs/atlas/venue_assets.md addendum). Both HUD
# consumers are UNMASKED (mugshot stager 0x8937C by $782/$b82(a5); name
# stager 0x89684 by $382(a4)) and both per-char tables (0x89884 word/char,
# 0x898C4 8B/char) are 32-ROW ALIASED — so the tenant read row 0x03's
# alias (Victor: the reported symptom). The $130(a5)/0x00A43E fold is a
# DIFFERENT family (select/VS palette blocks), untouched here. Fix = fill
# row 0x13 (three tenant-gated pokes) + place the mugshot art at the
# free-pool anchor 0xBE90 (variant builds only).
#
#   1. STATIC — tools/check_tenant_hud.py re-derives everything (table
#      shapes, poke addresses/values, art bytes vs both source zips,
#      host-cell pristineness).
#   2. NEGATIVE CONTROL — a patch stripped of the mugshot poke FAILS.
#   3. RUNTIME — in a real tenant match the HUD OBJ stream carries the
#      staged codes: mugshot 0xBE90 (2x2) and name 0xBE8C (3x1), and the
#      opponent's mugshot still stages from the vanilla 0x3Dxx page.
#
# Usage: ROMDIR=... tests/test_tenant_hud.sh [outbase]
#   outbase: an existing variant-id WIDE build (default: builds fresh).
# Env: MAME_WIDE_BIN (default ~/.cache/vampire-saved/mame/cps2);
#      SKIP_RUNTIME=1 skips section 3.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

OUTBASE="${1:-}"
if [ -z "$OUTBASE" ]; then
    OUTBASE="$WORK/build"
    echo "== 0. building at --tenant-id 0x13 (fresh) =="
    KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open \
--profile cps2-wide-v1 --tenant-id 0x13" \
        tools/build_donovan.sh 6 "$OUTBASE" > "$WORK/build.log" 2>&1 || {
        echo "FAIL: build did not complete"; tail -20 "$WORK/build.log"
        exit 1; }
    tail -2 "$WORK/build.log" | sed 's/^/  /'
fi

VAN="$WORK/vsavj_data.bin"
python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$WORK/vsavj_op.bin" \
    --data-out "$VAN" > /dev/null

echo "== 1. static: tables + pokes + art + host pristineness =="
python3 tools/check_tenant_hud.py "$OUTBASE" "$VAN" "$ROMDIR" \
    > "$WORK/static.txt" || {
    echo "FAIL: static check:"; sed 's/^/  /' "$WORK/static.txt"; exit 1; }
sed 's/^/  ok: /' "$WORK/static.txt"

echo "== 2. negative control: the verdict logic is itself tested =="
mkdir -p "$WORK/neg/patch"
ln -s "$(cd "$OUTBASE" && pwd)/gfx" "$WORK/neg/gfx"
python3 - "$OUTBASE" "$WORK/neg" <<'PY'
import json, sys
p = json.load(open(sys.argv[1] + "/patch/patch.json"))
ops = p["ops"] if isinstance(p, dict) and "ops" in p else p
kept = [o for o in ops
        if not (o.get("op") == "poke16" and o.get("addr") == "0x898aa")]
if isinstance(p, dict) and "ops" in p:
    p["ops"] = kept
else:
    p = kept
json.dump(p, open(sys.argv[2] + "/patch/patch.json", "w"))
PY
if python3 tools/check_tenant_hud.py "$WORK/neg" "$VAN" "$ROMDIR" \
        > /dev/null 2>&1; then
    echo "  FAIL: a patch without the mugshot poke PASSED the checker"
    fail=1
else
    echo "  ok: a stripped mugshot poke is caught"
fi

echo "== 3. runtime: the HUD stages the tenant's codes in a real match =="
if [ "${SKIP_RUNTIME:-0}" = 1 ]; then
    echo "  SKIPPED (SKIP_RUNTIME=1)"
else
    WIDE_BIN="${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
    "$WIDE_BIN" -listfull vsavjw > /dev/null 2>&1 || {
        echo "FAIL: $WIDE_BIN does not know vsavjw (tools/setup_mame.sh)"
        exit 1; }
    REPLAY="$REPO/tests/replays/36_pick_tenant_cell.rpl" \
    DUMP_FRAMES=3100 FRAMES=3110 TRACE_OUT="$WORK/obj.txt" \
    MAME_SANDBOX="$WORK/sbx" MAME_BIN="$WIDE_BIN" \
    MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
        tools/run_mame.sh vsavjw \
        -autoboot_script tests/lua/obj_records_dump.lua > /dev/null 2>&1 \
        || true
    ok=1
    grep -q "code=be90 attr=112a" "$WORK/obj.txt" || {
        echo "  FAIL: tenant mugshot (code be90, attr 112a) not staged"
        ok=0; }
    grep -q "code=be8c attr=0202" "$WORK/obj.txt" || {
        echo "  FAIL: tenant name plate (code be8c, attr 0202) not staged"
        ok=0; }
    grep -qE "code=3d[0-9a-f]{2} attr=1110" "$WORK/obj.txt" || {
        echo "  FAIL: opponent mugshot (vanilla 0x3Dxx page) not staged"
        ok=0; }
    if [ "$ok" = 1 ]; then
        echo "  ok: mugshot be90 + name be8c staged; opponent vanilla 3Dxx"
    else
        fail=1
    fi
fi

if [ "$fail" -ne 0 ]; then
    echo "FAIL: tenant HUD gate"
    exit 1
fi
echo "PASS: tenant HUD gate (32-row-alias mechanism + pokes + art +"
echo "      host pristineness + the engine's own staging in-match)"
