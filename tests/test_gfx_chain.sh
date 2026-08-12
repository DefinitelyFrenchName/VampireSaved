#!/bin/sh
# test_gfx_chain.sh — the group-C gfx CHAIN mode (14z-83 S2). ~6 min.
#
# The merge's gfx half runs build_gfx once per tenant, each link chaining
# over the prior link's members + write ledger (--chain). This gate proves
# the mechanism four ways, using the FROZEN build dirs' side files as
# inputs (their provenance is test_m3a_reproducible.sh):
#
#   1. SOLO BYTE-IDENTITY: a chain-free Donovan run reproduces the frozen
#      build/m5_wide/gfx members byte-for-byte (the S1/S2 refactors did
#      not move the solo path).
#   2. IDEMPOTENCE (chain-of-one): re-running the same link over its own
#      output is a no-op — every write is a benign same-source skip;
#      members and ledger come out byte-identical.
#   3. CHAIN CARRIES: Donovan -> Huitzil SUCCEEDS (their write sets'
#      overlaps are all same-source), and Huitzil's output ledger is
#      CUMULATIVE (it contains Donovan's entries).
#   4. THE MUST-FAIL CONTROL: chaining Pyron onto Huitzil's link FAILS
#      loudly at the known 288-code strip collision (P's band write hits
#      H's strip tile with different bytes — the audit_gfx_merged_census
#      defect, held for the S3 relocation). A chain that swallows this is
#      not a collision gate.
#      >>> S3 NOTE: when the strip relocation lands, case 4 FLIPS — the
#      full D->H->P chain must then succeed and this gate asserts that
#      instead (update the expectation WITH the relocation commit).
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

for d in build/m5_wide build/hui30 build/pyron21; do
    [ -d "$d/patch" ] || { echo "SKIP: missing $d (frozen build inputs)"; exit 0; }
done
[ -f build/m5_wide/gfx/vsw.31m ] || {
    echo "SKIP: build/m5_wide/gfx has no vsw members"; exit 0; }

gfx_d() {  # donovan link -> $1, optional --chain $2
    python3 tools/build_gfx_donovan.py "$ROMDIR" "$1" \
        --tiles build/m5_wide/donovan_tiles.json \
        --effects build/m5_wide/patch/effect_map.json \
        --select-tiles build/m5_wide/select_tiles.json \
        --select-bank5 build/m5_wide/patch/select_bank5.json \
        --wheel-bank5 build/m5_wide/patch/wheel_bank5.json \
        --effect-tail build/manifest/effect_tail.json \
        --tenant build/m5_wide/patch/tenant.json \
        ${2:+--chain "$2"}
}

echo "== 1: solo Donovan link == frozen build/m5_wide/gfx byte-for-byte =="
gfx_d "$W/gfx_d" > "$W/d.log" 2>&1 || { tail -5 "$W/d.log"; exit 1; }
for n in 31 33 35 37; do
    a="$(shasum "$W/gfx_d/vsw.${n}m" | cut -d' ' -f1)"
    b="$(shasum "build/m5_wide/gfx/vsw.${n}m" | cut -d' ' -f1)"
    [ "$a" = "$b" ] || { echo "FAIL: vsw.${n}m differs from frozen"; exit 1; }
done
echo "  ok: 4/4 vsw members identical to the frozen build"

echo "== 2: idempotence — the link chained over its own output is a no-op =="
gfx_d "$W/gfx_d2" "$W/gfx_d" > "$W/d2.log" 2>&1 || { tail -5 "$W/d2.log"; exit 1; }
for n in 31 33 35 37; do
    cmp -s "$W/gfx_d/vsw.${n}m" "$W/gfx_d2/vsw.${n}m" || {
        echo "FAIL: idempotence — vsw.${n}m moved on re-chain"; exit 1; }
done
python3 - "$W" <<'PY'
import json, sys
a = json.load(open(sys.argv[1] + "/gfx_d/gfx_written.json"))
b = json.load(open(sys.argv[1] + "/gfx_d2/gfx_written.json"))
assert a == b, "ledger changed on an idempotent re-chain"
print("  ok: members and ledger identical (all writes were benign skips)")
PY

echo "== 3: Donovan -> Huitzil chains (same-source overlaps only) =="
python3 tools/build_gfx_donovan.py "$ROMDIR" "$W/gfx_h" \
    --tiles build/hui30/donovan_tiles.json \
    --select-tiles build/hui30/select_tiles.json \
    --select-bank5 build/hui30/patch/select_bank5.json \
    --effect-c5 build/hui30/patch/effect_c5.json \
    --wheel-bank5 build/hui30/patch/wheel_bank5.json \
    --strip-tiles build/manifest/strip_tiles/0x10.json \
    --effect-tail build/manifest/effect_tail.json \
    --tenant build/hui30/patch/tenant.json \
    --chain "$W/gfx_d" > "$W/h.log" 2>&1 || { tail -5 "$W/h.log"; exit 1; }
python3 - "$W" <<'PY'
import json, sys
d = json.load(open(sys.argv[1] + "/gfx_d/gfx_written.json"))
h = json.load(open(sys.argv[1] + "/gfx_h/gfx_written.json"))
dc = {tuple(e) for e in d["C"]}
hc = {tuple(e) for e in h["C"]}
missing = dc - hc
assert not missing, f"H ledger lost {len(missing)} of D's entries — " \
                    "not cumulative"
print(f"  ok: H link succeeded; ledger cumulative "
      f"({len(dc)} D entries all present, {len(hc)} total)")
PY

echo "== 4: MUST-FAIL — Pyron onto Huitzil dies at the strip collision =="
set +e
python3 tools/build_gfx_donovan.py "$ROMDIR" "$W/gfx_p" \
    --tiles build/pyron21/donovan_tiles.json \
    --select-tiles build/pyron21/select_tiles.json \
    --select-bank5 build/pyron21/patch/select_bank5.json \
    --effect-c5 build/pyron21/patch/effect_c5.json \
    --wheel-bank5 build/pyron21/patch/wheel_bank5.json \
    --effect-tail build/manifest/effect_tail.json \
    --tenant build/pyron21/patch/tenant.json \
    --chain "$W/gfx_h" > "$W/p.log" 2>&1
rc=$?
set -e
if [ "$rc" = 0 ]; then
    echo "FAIL: the P link SUCCEEDED over the known 288-code strip"
    echo "      collision — the chain swallowed a different-bytes overwrite"
    exit 1
fi
grep -q "collides with DIFFERENT bytes" "$W/p.log" || {
    echo "FAIL: P link failed for the wrong reason:"; tail -5 "$W/p.log"
    exit 1; }
grep -qE "0x05[EF][0-9A-F]{2}" "$W/p.log" || {
    echo "FAIL: the collision error does not name a strip-range code:"
    grep "collides" "$W/p.log" | head -2; exit 1; }
echo "  ok: P link failed loudly at a strip-range dst, naming both sources:"
grep "collides" "$W/p.log" | head -1 | sed 's/^/     /'

echo
echo "PASS: gfx chain mode — solo identical, idempotent, cumulative, and"
echo "      the known collision fails loudly (S3 flips case 4 to success)"
