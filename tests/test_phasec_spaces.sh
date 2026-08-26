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
# THE STOCK TWIN'S CURRENT FINGERPRINT. Re-pinned 14z-94 (GitHub #30) from
# ae701ffb, which two maintainer-ratified freezes had superseded while this
# gate ran under no runner and so never said so:
#
#   ae701ffb  the original stock twin
#   6c93cfa8  14z-64 — ae701ffb + EXACTLY the 2-byte mirror-victim fix
#             (PRG:0x0B1A16, byte-attributed) — HANDOFF "m5_stock"
#   a054de5c  14z-91 — the legacy-regression fix, which is NOT profile-gated,
#             so all four builds moved — HANDOFF:184 "stock twin
#             build/m5_stock2 (a054de5c)"
#   16da59b6  14z-99 — #103's pcrel rows, not profile-gated
#   883e7d17  14z-102 — #107's reconciliation row flip, shared map, not
#             profile-gated (donovan-m10-stock, build/m5_stock5)
#
# The gate's standing warning below — "The refactor MOVED PORTED BYTES. Do NOT
# re-freeze to pass" — is aimed at a refactor silently moving bytes, which is
# NOT what happened here: a054de5c is the value HANDOFF documents as the
# current stock twin, reached by two ratified changes. The warning stays,
# because the next mismatch may well be the real thing.
# EXPECT="${1:-a054de5c...}"  # 14z-91..14z-96 (the stock constant era)
# RE-POINTED 14z-99: the WINDOW moved the stock twin for the first time
# since 14z-91 — #103's pcrel_escape_fix rows are deliberately NOT
# profile-gated (the stock track carries donovan's regions and gets the
# arcade-death-stall fix too). Ratified byte movement, not a refactor —
# the "do NOT re-freeze to pass" warning above targets inert refactors.
EXPECT="${1:-cf4557602d82c6dbb1ccb76b5377825effdd5526}"  # re-frozen 14z-110: the #99 d2 window is NOT profile-gated (the stock track carries the same six 0x51 nodes), so the stock image moves
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
# 14z-99: [0-9a-fA-F] — the generator prints UPPERCASE hex, and the
# allocation cursor contained a letter (0x4191F0) for the first time at
# the window, so the lowercase-only class missed it and this gate
# reported "extension not available" about an available extension.
elif grep -qE "wide_ext 0x[0-9a-fA-F]+/0x600000" "$WORK/wide.log"; then
    # CORRECTED 14z-94 (GitHub #30): this grepped the LITERAL
    # "wide_ext 0x400010/0x600000". That number is the extension's current
    # ALLOCATION POINTER, not its base — so it moved to 0x406040 the moment
    # real content occupied the first 0x6030 bytes, and the gate started
    # reporting "extension not available" about an extension that was
    # available with 0x1F9FC0 free. The invariant is the 0x600000 CEILING and
    # the fact that the space is declared at all; the cursor is expected to
    # move as the port grows.
    _we="$(grep -oE 'wide_ext [^,)]*\)' "$WORK/wide.log" | head -1)"
    echo "  ok: extension declared and available under the profile — $_we"
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
