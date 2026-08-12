#!/bin/sh
# test_gfx_chain.sh — the group-C gfx CHAIN mode (14z-83 S2; expectation
# flipped by the S3 strip relocation: the full D->H->P chain now SUCCEEDS,
# and the must-fail control runs on an old-shift fixture). ~9 min.
#
# The merge's gfx half runs build_gfx once per tenant, each link chaining
# over the prior link's members + write ledger (--chain). Five sections,
# using the FROZEN build dirs' side files as inputs (provenance:
# test_m3a_reproducible.sh):
#
#   1. SOLO BYTE-IDENTITY: a chain-free Donovan run reproduces the frozen
#      build/m5_wide/gfx members byte-for-byte.
#   2. IDEMPOTENCE (chain-of-one): re-running a link over its own output
#      is a no-op (members + ledger identical).
#   3. D -> H chains; H's ledger is CUMULATIVE and carries the RELOCATED
#      strip at 0x86A0-0x87BF.
#   4. H -> P completes THE FULL 3-TENANT CHAIN (zero real collisions
#      since S3) — P's members carry all three tenants' art.
#   5. THE MUST-FAIL CONTROL: an old-shift (0x1000) strip fixture rebuilds
#      the historical defect — chaining P onto that H' link dies loudly at
#      a strip-range dst naming both sources. A chain that swallows this
#      is not a collision gate.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
HUI="${HUI:-build/hui31}"

for d in build/m5_wide "$HUI" build/pyron21; do
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

gfx_h() {  # huitzil link -> $1, chain $2, strip json $3
    python3 tools/build_gfx_donovan.py "$ROMDIR" "$1" \
        --tiles "$HUI/donovan_tiles.json" \
        --select-tiles "$HUI/select_tiles.json" \
        --select-bank5 "$HUI/patch/select_bank5.json" \
        --effect-c5 "$HUI/patch/effect_c5.json" \
        --wheel-bank5 "$HUI/patch/wheel_bank5.json" \
        --strip-tiles "$3" \
        --effect-tail build/manifest/effect_tail.json \
        --tenant "$HUI/patch/tenant.json" \
        --chain "$2"
}

gfx_p() {  # pyron link -> $1, chain $2
    python3 tools/build_gfx_donovan.py "$ROMDIR" "$1" \
        --tiles build/pyron21/donovan_tiles.json \
        --select-tiles build/pyron21/select_tiles.json \
        --select-bank5 build/pyron21/patch/select_bank5.json \
        --effect-c5 build/pyron21/patch/effect_c5.json \
        --wheel-bank5 build/pyron21/patch/wheel_bank5.json \
        --effect-tail build/manifest/effect_tail.json \
        --tenant build/pyron21/patch/tenant.json \
        --chain "$2"
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

echo "== 3: Donovan -> Huitzil chains; relocated strip in the ledger =="
gfx_h "$W/gfx_h" "$W/gfx_d" build/manifest/strip_tiles/0x10.json \
    > "$W/h.log" 2>&1 || { tail -5 "$W/h.log"; exit 1; }
python3 - "$W" <<'PY'
import json, sys
d = json.load(open(sys.argv[1] + "/gfx_d/gfx_written.json"))
h = json.load(open(sys.argv[1] + "/gfx_h/gfx_written.json"))
dc = {tuple(e) for e in d["C"]}
hc = {tuple(e) for e in h["C"]}
missing = dc - hc
assert not missing, f"H ledger lost {len(missing)} of D's entries — " \
                    "not cumulative"
strip = sorted(i for i, k, s in h["C"]
               if k == "vs2A" and i < 0x10000 and 0x14EA0 <= s <= 0x14FBF)
assert (len(strip), min(strip), max(strip)) == (288, 0x86A0, 0x87BF), \
    f"strip not at the relocated dst: {len(strip)} entries " \
    f"{min(strip):#x}-{max(strip):#x}"
print(f"  ok: H link cumulative ({len(dc)} D entries carried); strip at "
      f"0x86A0-0x87BF (288)")
PY

echo "== 4: Huitzil -> Pyron completes the FULL 3-tenant chain =="
gfx_p "$W/gfx_p" "$W/gfx_h" > "$W/p.log" 2>&1 || { tail -5 "$W/p.log"; exit 1; }
python3 - "$W" <<'PY'
import json, sys
h = json.load(open(sys.argv[1] + "/gfx_h/gfx_written.json"))
p = json.load(open(sys.argv[1] + "/gfx_p/gfx_written.json"))
hc = {tuple(e) for e in h["C"]}
pc = {tuple(e) for e in p["C"]}
missing = hc - pc
assert not missing, f"P ledger lost {len(missing)} entries — not cumulative"
b4 = {i for i, k, s in p["C"] if i < 0x10000}
print(f"  ok: FULL CHAIN — P's members carry all three tenants "
      f"({len(b4)} bank-4 codes, {len(pc)} total group-C entries)")
PY

echo "== 5: MUST-FAIL — the old-shift fixture reproduces the collision =="
python3 - "$W" <<'PY'
import json, sys
st = json.load(open("build/manifest/strip_tiles/0x10.json"))
st["shift"] = "0x1000"
json.dump(st, open(sys.argv[1] + "/strip_old.json", "w"))
PY
gfx_h "$W/gfx_h_old" "$W/gfx_d" "$W/strip_old.json" \
    > "$W/hold.log" 2>&1 || { tail -5 "$W/hold.log"; exit 1; }
set +e
gfx_p "$W/gfx_p_old" "$W/gfx_h_old" > "$W/pold.log" 2>&1
rc=$?
set -e
if [ "$rc" = 0 ]; then
    echo "FAIL: the P link SUCCEEDED over the old-shift fixture's known"
    echo "      collision — the chain swallowed a different-bytes overwrite"
    exit 1
fi
grep -q "collides with DIFFERENT bytes" "$W/pold.log" || {
    echo "FAIL: P fixture link failed for the wrong reason:"
    tail -5 "$W/pold.log"; exit 1; }
grep -qE "0x05[EF][0-9A-F]{2}" "$W/pold.log" || {
    echo "FAIL: the collision error does not name a strip-range code:"
    grep "collides" "$W/pold.log" | head -2; exit 1; }
echo "  ok: fixture P link failed loudly at a strip-range dst:"
grep "collides" "$W/pold.log" | head -1 | sed 's/^/     /'

echo
echo "PASS: gfx chain mode — solo identical, idempotent, FULL 3-tenant"
echo "      chain green since the S3 relocation, and the old-shift fixture"
echo "      still fails loudly"
