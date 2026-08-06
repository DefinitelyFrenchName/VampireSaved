#!/bin/sh
# test_m3a_reproducible.sh — the M3b Phase 0 reproducibility gate (14z-65).
#
# The frozen reference pair must rebuild BIT-EXACT from the current tree:
#   donovan-m3a (WIDE)  fingerprint 4b7d0dc7319ed6cf94a02b22938cdb18946dfddd
#   m5_stock            fingerprint 6c93cfa8a8a80ae2303d3acaf8c7bff487f369c5
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

echo "PASS: both frozen references rebuild bit-exact from this tree"
