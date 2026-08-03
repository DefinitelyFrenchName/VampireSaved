#!/bin/sh
# test_phasec_spaces.sh — the address-space refactor must not move a byte.
#
# Phase C replaces two hard-coded holes with a declarative, ordered space
# list, and adds a profile-gated space for the CPS-2 WIDE program extension.
# That is a refactor of the ALLOCATOR, which decides where every ported byte
# lands — so the only acceptable evidence it is correct is that the generated
# build comes out BIT-IDENTICAL to the pre-refactor one.
#
# The tool-level analogue of the superset invariant: a pipeline change that
# improves nothing observable must change nothing observable.
#
# Two properties, both required:
#   1. STOCK build (no --profile) is byte-identical to the pre-refactor
#      fingerprint, even though the WIDE extension and a profile-gated
#      sound_table row are now DECLARED. Gated space and gated content must
#      not exist for a build that did not ask for them.
#   2. WIDE build (--profile cps2-wide-v1) makes the extension available and
#      fails with a PRECISE diagnosis rather than a crash, because the
#      pipeline cannot yet grow the program image. When that lands, this
#      expectation is re-frozen DELIBERATELY as a recorded decision — never
#      silently to make the gate green.
#
# Usage: ROMDIR=... tests/test_phasec_spaces.sh [expected-fingerprint]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
EXPECT="${1:-ae701ffb06d0cbf3462cad1a9faa47534a3c00e4}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

echo "== 1. STOCK build must be byte-identical (gated space/content absent) =="
GEN_FLAGS="--allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 "$WORK/stock" > "$WORK/stock.log" 2>&1 || {
        echo "  FAIL: stock build errored"; tail -15 "$WORK/stock.log"; exit 1; }
grep -E "^stage 6:" "$WORK/stock.log" | sed 's/^/  /'
got=$(sed -n 's/.*build fingerprint: \([0-9a-f]\{40\}\).*/\1/p' "$WORK/stock.log" | head -1)
if [ "$got" = "$EXPECT" ]; then
    echo "  ok: $got — allocator generalised without moving a byte"
else
    echo "  FAIL: fingerprint $got, expected $EXPECT"
    echo "        The refactor MOVED PORTED BYTES. Do NOT re-freeze to pass."
    fail=1
fi
if grep -q "wide_ext" "$WORK/stock.log"; then
    echo "  FAIL: the profile-gated space exists in a stock build"
    fail=1
else
    echo "  ok: wide_ext absent from a stock build (gated by construction)"
fi

echo "== 2. WIDE build: extension available, failure DIAGNOSED not crashed =="
GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
    tools/build_donovan.sh 6 "$WORK/wide" > "$WORK/wide.log" 2>&1 || true
if grep -q "Traceback" "$WORK/wide.log"; then
    echo "  FAIL: crashed instead of diagnosing"; grep -A3 Traceback "$WORK/wide.log" | head -5
    fail=1
elif grep -q "wide_ext 0x400010/0x600000" "$WORK/wide.log"; then
    echo "  ok: extension declared and available (2MB) under the profile"
    if grep -q "lies beyond the .* program image" "$WORK/wide.log"; then
        echo "  ok: allocating into it fails with the precise next-step diagnosis"
    else
        echo "  NOTE: no image-growth diagnosis — the pipeline may now grow the"
        echo "        image, in which case re-freeze this gate deliberately."
    fi
else
    echo "  FAIL: extension not available under --profile cps2-wide-v1"
    fail=1
fi

echo
[ "$fail" = 0 ] || { echo "FAIL: Phase C address-space gate"; exit 1; }
echo "PASS: Phase C address-space model — declarative, profile-gated, and"
echo "      byte-for-byte inert on the stock build."
