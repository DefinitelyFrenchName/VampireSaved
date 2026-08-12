#!/bin/sh
# test_type_stamp_census.sh — the static type-stamp census reproduces the
# FROZEN inventory (build/manifest/type_stamps.toml), and its verdict logic
# is alive in both directions.
#
# WHY (14z-82). The merged obj_hook fix renumbers TYPE NUMBERS inside
# non-first tenants' region copies. That is only sound while every site
# that WRITES or CONSULTS a family type is known; the frozen inventory is
# that knowledge, and this gate makes any drift — a scan change, a
# regions.json change, a new form — a loud FAIL that forces re-review
# instead of silent absorption. The scan carries its own positive control
# (the six measured stamp sites must be seen) and negative control (the
# three unported family stamps must map to no tenant), per the
# list_type_census.py lesson: a census that cannot see the thing it is
# looking for reads exactly like a clean result.
#
# Sections:
#   1  scan vs frozen inventory — no drift, controls green
#   2  verdict control A: a bogus --expect-extra site must FAIL the scan
#   3  verdict control B: a tampered frozen copy must FAIL verification
#
# Usage: tests/test_type_stamp_census.sh
# Needs: build/out/vsav2_opcodes.bin (decrypted opcode view) and the three
# tenants' extract dirs. No emulator, no ROMDIR. ~5 s.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="${TMPDIR:-/tmp}/type_stamp_census_$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT
fail=0

IMG=build/out/vsav2_opcodes.bin
REGS="--regions build/m5_wide/extract/regions.json \
      --regions build/hui30/extract/regions.json \
      --regions build/pyron21/extract/regions.json"
FROZEN=build/manifest/type_stamps.toml

for f in "$IMG" build/m5_wide/extract/regions.json \
         build/hui30/extract/regions.json \
         build/pyron21/extract/regions.json "$FROZEN"; do
    [ -f "$f" ] || { echo "SKIP: missing $f"; exit 0; }
done

# ── 1: scan vs frozen — no drift, controls green ─────────────────────────
if python3 tools/audit_type_stamps.py "$IMG" $REGS \
        --verify "$FROZEN" >"$WORK/s1.txt" 2>&1; then
    if grep -q "PASS  no drift" "$WORK/s1.txt"; then
        echo "  PASS  1: census matches frozen inventory ($(grep -c 'PASS' "$WORK/s1.txt") checks)"
    else
        echo "  FAIL  1: scan exited 0 without the no-drift verdict"
        fail=1
    fi
else
    echo "  FAIL  1: census drift or control failure"
    grep -E "DRIFT|FAIL" "$WORK/s1.txt" | head -10
    fail=1
fi

# ── 2: verdict control A — the scan must be able to FAIL its --expect ────
if python3 tools/audit_type_stamps.py "$IMG" $REGS \
        --expect-extra 0x123456:117 >"$WORK/s2.txt" 2>&1; then
    echo "  FAIL  2: bogus expect site was not caught (positive control dead)"
    fail=1
else
    if grep -q "FAIL  expect 0x123456" "$WORK/s2.txt"; then
        echo "  PASS  2: bogus expect site caught"
    else
        echo "  FAIL  2: scan failed for the wrong reason"
        tail -5 "$WORK/s2.txt"
        fail=1
    fi
fi

# ── 3: verdict control B — a tampered frozen file must FAIL verify ───────
# Flip one stamp's type in a copy: the drift detector must name it.
sed 's/^type = 117$/type = 118/' "$FROZEN" >"$WORK/tampered.toml"
if python3 tools/audit_type_stamps.py "$IMG" $REGS \
        --verify "$WORK/tampered.toml" >"$WORK/s3.txt" 2>&1; then
    echo "  FAIL  3: tampered inventory verified clean (drift detector dead)"
    fail=1
else
    if grep -q "DRIFT" "$WORK/s3.txt"; then
        echo "  PASS  3: tampered inventory caught ($(grep -c DRIFT "$WORK/s3.txt") drift rows)"
    else
        echo "  FAIL  3: verify failed without naming the drift"
        tail -5 "$WORK/s3.txt"
        fail=1
    fi
fi

[ "$fail" = 0 ] && echo "test_type_stamp_census: ALL PASS" || echo "test_type_stamp_census: FAILURES"
exit "$fail"
