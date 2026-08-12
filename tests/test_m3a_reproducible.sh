#!/bin/sh
# test_m3a_reproducible.sh — the M3b Phase 0 reproducibility gate (14z-65).
#
# EVERY frozen reference must rebuild BIT-EXACT from the current tree:
#   donovan-m3a (WIDE)  4b7d0dc7319ed6cf94a02b22938cdb18946dfddd
#   m5_stock            6c93cfa8a8a80ae2303d3acaf8c7bff487f369c5
#   huitzil-m3 (WIDE)   34c8b47de5a43a67e7292f16d0ad133d287fa7e4
#   pyron-m2   (WIDE)   69e8c6f08b9fc5859948e50cfb41156d62adf1ec
#
# EXTENDED 14z-76 from the original pair to all four. This is the standing
# gate for the M3b multi-tenant refactor and its value scales with the count:
# the refactor must leave THREE independent tenant fingerprints untouched, so
# each frozen vertical is an independent oracle over the same change. That is
# the payoff of decision D4's "freeze each vertical first, then merge".
# A machinery refactor that moves either fingerprint is a failed change, no
# matter what it was trying to do (the M3a lesson: a frozen reference that
# cannot be rebuilt is not a reference). Run after EVERY machinery commit in
# the M3b milestone. Builds go to a scratch dir; the canonical build/m5_*
# dirs are not touched.
#
# Usage: ROMDIR=... tests/test_m3a_reproducible.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

EXPECT_WIDE="4b7d0dc7319ed6cf94a02b22938cdb18946dfddd"
EXPECT_STOCK="6c93cfa8a8a80ae2303d3acaf8c7bff487f369c5"
# huitzil-m3 (14z-79, maintainer-ratified). Supersedes huitzil-m2
# (9deda0808e87601b10e2171405805d4669ba2624), which can no longer be
# produced from the tree: huitzil.toml gained the (b') index-window thunk
# and lost the withdrawn df_palette_seq_rows row. git tag freeze/huitzil-m2
# is the way back to a tree that reproduces it.
# huitzil-m4 (14z-82c: + the ADOPTED hitclass_map_extend thunk)
EXPECT_HUI="e66678d087824d1639750d2b9565c0b99ad2b250"
# pyron-m3 (14z-82c: + the ADOPTED hitclass_map_extend thunk — the f7997 fix)
EXPECT_PYR="6c7f7322da793c12b3681dd3ef5a76b3792ae5d0"

# The WIDE overlay romset (deterministic from the audited reference sets;
# built into scratch so the canonical build/wide0 is never clobbered).
echo "== WIDE overlay romset (scratch)"
python3 tools/build_wide_romset.py "$ROMDIR" "$WORK/wide0/rompath" \
    --qsound 2 --gfx 4 --prg 4 > /dev/null

echo "== rebuild donovan-m3a (WIDE)"
KEY_SET=vsavj WIDE_ROMSET="$WORK/wide0/rompath/vsavjw.zip" \
    GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
    tools/build_donovan.sh 6 "$WORK/m3a_wide" > "$WORK/wide.log" 2>&1 \
    || { tail -20 "$WORK/wide.log"; echo "FAIL: WIDE rebuild errored"; exit 1; }
FP_WIDE="$(python3 tools/build_fingerprint.py "$WORK/m3a_wide/rompath;$ROMDIR" \
    --set vsavjw --sha-only)"
[ "$FP_WIDE" = "$EXPECT_WIDE" ] || {
    echo "FAIL: WIDE fingerprint $FP_WIDE != donovan-m3a $EXPECT_WIDE"
    echo "  (the tree no longer reproduces the frozen reference)"; exit 1; }
echo "  ok: donovan-m3a reproduced ($FP_WIDE)"

echo "== rebuild m5_stock"
GEN_FLAGS="--allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 "$WORK/m3a_stock" > "$WORK/stock.log" 2>&1 \
    || { tail -20 "$WORK/stock.log"; echo "FAIL: stock rebuild errored"; exit 1; }
FP_STOCK="$(python3 tools/build_fingerprint.py "$WORK/m3a_stock/rompath;$ROMDIR" \
    --set vsavj --sha-only)"
[ "$FP_STOCK" = "$EXPECT_STOCK" ] || {
    echo "FAIL: stock fingerprint $FP_STOCK != m5_stock $EXPECT_STOCK"
    echo "  (the tree no longer reproduces the frozen stock twin)"; exit 1; }
echo "  ok: m5_stock reproduced ($FP_STOCK)"

# The two tenant verticals. Same WIDE overlay, their own manifests/ids.
for _t in "huitzil:0x10:$EXPECT_HUI" "pyron:0x11:$EXPECT_PYR"; do
    _name="${_t%%:*}"; _rest="${_t#*:}"; _char="${_rest%%:*}"; _want="${_rest#*:}"
    echo "== rebuild $_name ($_char)"
    TENANT_MANIFEST="build/manifest/$_name.toml" TENANT_CHAR="$_char" \
        WIDE_ROMSET="$WORK/wide0/rompath/vsavjw.zip" \
        GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 6 "$WORK/$_name" > "$WORK/$_name.log" 2>&1 \
        || { tail -20 "$WORK/$_name.log"; echo "FAIL: $_name rebuild errored"; exit 1; }
    _fp="$(python3 tools/build_fingerprint.py "$WORK/$_name/rompath;$ROMDIR" \
        --set vsavjw --sha-only)"
    [ "$_fp" = "$_want" ] || {
        echo "FAIL: $_name fingerprint $_fp != $_want"
        echo "  (the tree no longer reproduces the frozen $_name vertical)"; exit 1; }
    echo "  ok: $_name reproduced ($_fp)"
done

echo "PASS: all four frozen references rebuild bit-exact from this tree"
