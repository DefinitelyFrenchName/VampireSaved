#!/bin/sh
# build_merged.sh — the 3-tenant merged build WITH gfx (M3b Phase 3 S4,
# 14z-83). Program half: the same generator invocation the merged-legacy
# instrument uses (audit_merged_legacy.sh section B — one process, three
# extracts, three manifests). Gfx half: the S2 chain, one build_gfx link
# per tenant over the prior link's members + ledger, consuming the MERGED
# generator's own per-tenant side files. Packs a runnable vsavjw set.
#
# THIS PRODUCES THE FIRST PLAYTESTABLE 3-TENANT ARTIFACT. It is NOT
# registered (registry rows are a freeze decision, S6); run_suite refuses
# it by design until then.
#
# Usage: ROMDIR=... [WIDE_ROMSET=...] tools/build_merged.sh <outbase>
#        (e.g. tools/build_merged.sh build/m3b_merged)
set -eu
OUT="${1:?usage: build_merged.sh <outbase>}"
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WIDE_ZIP="${WIDE_ROMSET:-$PWD/build/wide0/rompath/vsavjw.zip}"

# the three frozen verticals' extracts are the generator's inputs
# (extraction is deterministic — test_m3a_reproducible re-extracts and
# all four fingerprints are bit-exact, so these dirs ARE the bytes)
D_EX="build/m5_wide/extract"
H_EX="build/hui31/extract"
P_EX="build/pyron21/extract"
missing=""
for d in "$D_EX" "$H_EX" "$P_EX"; do [ -d "$d" ] || missing="$missing $d"; done
[ -f "$WIDE_ZIP" ] || missing="$missing $WIDE_ZIP"
[ -z "$missing" ] || { echo "FAIL: missing$missing"; exit 1; }

rm -rf "$OUT"; mkdir -p "$OUT"

echo "== 1: merged program image (3 tenants, one generator process) =="
python3 tools/gen_donovan_patch.py "$D_EX" "$OUT/patch" \
    --extract "$H_EX" --extract "$P_EX" \
    --vsavj "$ROMDIR/vsavj.zip" --stage 6 \
    --port build/manifest/donovan.toml --port build/manifest/huitzil.toml \
    --port build/manifest/pyron.toml \
    --profile cps2-wide-v1 --allow-plausible --tripwire-open \
    > "$OUT/gen.log" 2>&1 || {
        echo "FAIL: generation errored"; tail -15 "$OUT/gen.log"; exit 1; }
grep -q '^GENERATION OK' "$OUT/gen.log" || {
    echo "FAIL: no GENERATION OK"; tail -15 "$OUT/gen.log"; exit 1; }
NOPS="$(python3 -c "import json;print(len(json.load(open('$OUT/patch/patch.json'))['ops']))")"
[ "$NOPS" = 593 ] || {
    echo "FAIL: $NOPS ops, frozen fixture is 593 (re-freeze"
    echo "      test_tenant_loop FIRST if the merge legitimately changed)"
    exit 1; }
echo "  ok: 593 ops (the frozen test_tenant_loop fixture)"
python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$OUT/prg" \
    --patch "$OUT/patch/patch.json" > "$OUT/patch_prg.log" 2>&1 || {
        echo "FAIL: patch_prg refused the merged patch"
        tail -10 "$OUT/patch_prg.log"; exit 1; }

echo "== 2: gfx chain — one link per tenant over the prior link =="
# per-tenant walks (the tenant's ratified layout span over its own
# extract), inventories merged with extra_tiles where a set exists
CHAIN=""
for T in donovan:0x13:$D_EX huitzil:0x10:$H_EX pyron:0x11:$P_EX; do
    name="${T%%:*}"; rest="${T#*:}"; char="${rest%%:*}"; ex="${rest#*:}"
    span="$(python3 - "$char" <<'PY'
import sys
sys.path.insert(0, "tools")
from _minitoml import loads
lay = loads(open("build/manifest/gfx_layout3.toml").read())
row = {r["id"]: r for r in lay["tenant"]}[int(sys.argv[1], 16)]
print(f"{row['anim_base']:#x} {row['anim_base'] + row['anim_len']:#x} "
      f"{row['sweep_lo']:#x} {row['sweep_hi']:#x}")
PY
)"
    set -- $span
    python3 tools/obj_records.py "$ex/region_anim.bin" \
        --base "$1" --start "$1" --end "$2" \
        --cptr-lo 0x300000 --cptr-hi 0x361000 \
        --sweep-lo "$3" --sweep-hi "$4" \
        --json "$OUT/tiles_$name.json" > /dev/null
    EXTRA="build/manifest/extra_tiles/$char.json"
    if [ -f "$EXTRA" ]; then
        python3 - "$OUT/tiles_$name.json" "$EXTRA" <<'PY'
import json, sys
inv = json.load(open(sys.argv[1]))
extra = json.load(open(sys.argv[2]))["tiles"]
merged = sorted(set(inv) | set(extra))
json.dump(merged, open(sys.argv[1], "w"))
print(f"  extra tiles: +{len(merged) - len(inv)}, "
      f"inventory {len(inv)} -> {len(merged)}")
PY
    fi
    # this tenant's row of the generator's tenants.json, as a
    # tenant.json-shaped file for build_gfx --tenant
    python3 - "$OUT" "$name" <<'PY'
import json, sys
tens = json.load(open(sys.argv[1] + "/patch/tenants.json"))
row = {t["name"]: t for t in tens}[sys.argv[2]]
json.dump(row, open(f"{sys.argv[1]}/tenant_{sys.argv[2]}.json", "w"))
PY
    # per-tenant side-file spellings from the MERGED generator's own
    # output: tenant 0 keeps the bare names, later tenants ride .<name>
    if [ "$name" = donovan ]; then SP=""; else SP=".$name"; fi
    FLAGS="--tiles $OUT/tiles_$name.json"
    [ -f "$OUT/patch/effect_map$SP.json" ] && \
        FLAGS="$FLAGS --effects $OUT/patch/effect_map$SP.json"
    FLAGS="$FLAGS --select-tiles $OUT/patch/select_tiles$SP.json"
    [ -f "$OUT/patch/select_bank5$SP.json" ] && \
        FLAGS="$FLAGS --select-bank5 $OUT/patch/select_bank5$SP.json"
    [ -f "$OUT/patch/effect_c5$SP.json" ] && \
        FLAGS="$FLAGS --effect-c5 $OUT/patch/effect_c5$SP.json"
    # the wheel is ENGINE-level: the merged generator emits it ONCE and
    # link 0 places it (later links would only benign-skip every tile)
    [ "$name" = donovan ] && [ -f "$OUT/patch/wheel_bank5.json" ] && \
        FLAGS="$FLAGS --wheel-bank5 $OUT/patch/wheel_bank5.json"
    [ -f "build/manifest/strip_tiles/$char.json" ] && \
        FLAGS="$FLAGS --strip-tiles build/manifest/strip_tiles/$char.json"
    FLAGS="$FLAGS --effect-tail build/manifest/effect_tail.json"
    FLAGS="$FLAGS --tenant $OUT/tenant_$name.json"
    [ -n "$CHAIN" ] && FLAGS="$FLAGS --chain $CHAIN"
    echo "  -- link $name"
    # shellcheck disable=SC2086
    python3 tools/build_gfx_donovan.py "$ROMDIR" "$OUT/gfx_$name" $FLAGS \
        > "$OUT/gfx_$name.log" 2>&1 || {
            echo "FAIL: gfx link $name"; tail -8 "$OUT/gfx_$name.log"
            exit 1; }
    tail -2 "$OUT/gfx_$name.log" | sed 's/^/     /'
    CHAIN="$OUT/gfx_$name"
done

echo "== 3: pack (program + LAST link's members) =="
KEY_SET=vsavj ROMDIR="$ROMDIR" tools/pack_build.sh "$OUT/prg" "$OUT/rompath" \
    --set vsavjw --merge "$WIDE_ZIP" > "$OUT/pack.log" 2>&1 || {
        echo "FAIL: pack"; tail -10 "$OUT/pack.log"; exit 1; }
GFXSTAGE="$(mktemp -d)"
unzip -q -o "$ROMDIR/vsav.zip" -d "$GFXSTAGE"
cp "$CHAIN"/vm3.*m "$GFXSTAGE"/
( cd "$GFXSTAGE" && rm -f vsav.zip && zip -q -X vsav.zip * )
cp "$GFXSTAGE/vsav.zip" "$OUT/rompath/vsav.zip"
rm -rf "$GFXSTAGE"
RPZIP="$(cd "$OUT/rompath" && pwd)/vsavjw.zip"
( cd "$CHAIN" && zip -q -X "$RPZIP" vsw.*m )
echo "  ok: group-A members + group-C simms from the last link ($CHAIN)"
# group B must stay PRISTINE in the packed vsav.zip (de-substitution)
python3 - "$OUT/rompath/vsav.zip" "$ROMDIR/vsav.zip" <<'PY'
import sys, zipfile
b, p = (zipfile.ZipFile(a) for a in sys.argv[1:3])
bad = [n for n in ("vm3.14m", "vm3.16m", "vm3.18m", "vm3.20m")
       if b.getinfo(n).CRC != p.getinfo(n).CRC]
assert not bad, f"group B members differ from pristine: {bad}"
print("  ok: group B pristine in the packed vsav.zip")
PY
python3 tools/audit_romset_identity.py "$OUT/rompath" || {
    echo "FAIL: member-identity audit — do not run anything from this set"
    exit 1; }

echo "== 4: per-tenant static verification =="
python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$OUT/vanilla_op.bin" \
    --data-out "$OUT/vanilla_data.bin" > /dev/null 2>&1
for T in donovan:$D_EX huitzil:$H_EX pyron:$P_EX; do
    name="${T%%:*}"; ex="${T#*:}"
    echo "  -- verify_gfx_build --tenant $name"
    python3 tools/verify_gfx_build.py "$OUT" --tenant "$name" \
        --gfx-dir "$OUT/gfx_$name" --extract-dir "$ex" | sed 's/^/     /'
    echo "  -- check_tenant_hud --tenant $name"
    python3 tools/check_tenant_hud.py "$OUT" "$OUT/vanilla_data.bin" \
        "$ROMDIR" --tenant "$name" --gfx-dir "$CHAIN" | sed 's/^/     /'
done

FP="$(python3 tools/build_fingerprint.py "$OUT/rompath;$ROMDIR" --set vsavjw --sha-only)"
cat > "$OUT/README.txt" <<EOF
3-TENANT MERGED BUILD WITH GFX (tools/build_merged.sh, 14z-83 S4).
Program: the 593-op merged image. Gfx: the S2 chain (D -> H -> P), last
link's members packed; group B pristine.
NOT REGISTERED (S6 decision) — run_suite refuses it until frozen.
fingerprint: $FP
EOF
echo "build fingerprint: $FP"
echo "OK: merged build with gfx at $OUT/rompath (register at S6 freeze time)"
