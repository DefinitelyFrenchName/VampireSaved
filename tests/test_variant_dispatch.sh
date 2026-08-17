#!/bin/sh
# test_variant_dispatch.sh — THE VARIANT-ROW DISPATCH AUDIT (14z-75).
#
# The single most common defect shape in this port: a 32-row
# per-character jump table where vsav ALIASES rows 0x10-0x1F onto
# 0x00-0x0F, so a tenant at a variant id silently inherits a base-half
# character's routine. Pyron's sprite/HUD blink was this in THREE
# separate tables, and chasing it one screen at a time found only the
# first — the in-match one. This gate sweeps for the SHAPE instead.
#
# For every qualifying table it requires
#     ours[tenant_row] == vs2[tenant_row]
# i.e. the tenant behaves as its own game does. Rows where OURS RUNS A
# ROUTINE vs2 DOES NOT are the live defect class and fail the gate; rows
# where vs2 runs one we do not are reported but do not fail (a missing
# feature, not a spurious one — e.g. Donovan's own routines, unported).
#
#   1. THE AUDIT on the build under test (must be clean for its tenant).
#   2. NEGATIVE CONTROL — reintroduce one aliased row into a COPY of the
#      build's image and require the audit to catch it. Without this, a
#      sweep that silently judged nothing would pass.
#   3. COVERAGE CONTROL — no table may be left "unjudgeable". vsav ships
#      TWO byte-identical copies of the main dispatcher, and an earlier
#      twin-finder that demanded a unique context match skipped exactly
#      the table carrying the first instance of this defect.
#
# Usage: ROMDIR=... tests/test_variant_dispatch.sh [outbase] [tenant]
# Static, no emulator, seconds.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

BUILD="${1:-build/pyron17}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
# THE TENANT COMES FROM THE BUILD, not from a default (14z-78).
# It used to be `${2:-0x11}`, so `test_variant_dispatch.sh build/hui27` swept a
# HUITZIL build while judging PYRON's id — reporting three "spurious inherited
# routines" that belong to no tenant on that build, and hiding the fact that
# Phobos' real answer is ONE row. A gate that silently answers a different
# question than the one its caller asked is worse than no gate.
# Every build writes its own id to patch/tenant.json, so ask it. An explicit
# second argument still wins, for sweeping a build at an id it does not carry.
TENANT="${2:-}"
if [ -z "$TENANT" ] && [ -f "$BUILD/patch/tenant.json" ]; then
    TENANT="$(python3 -c "import json,sys;print(hex(json.load(open(sys.argv[1]))['id']))" \
              "$BUILD/patch/tenant.json" 2>/dev/null || true)"
fi
if [ -z "$TENANT" ]; then
    echo "FAIL: no tenant id — $BUILD has no patch/tenant.json and none was"
    echo "      given. Refusing to guess: a wrong id makes this gate report on"
    echo "      a character the build does not back."
    exit 1
fi
OPIMG="$BUILD/verify_op.bin"
[ -f "$OPIMG" ] || { echo "FAIL: no $OPIMG"; exit 1; }

decrypt_view vsavj "$WORK/vj.bin" "$WORK/vjd.bin"
decrypt_view vsav2 "$WORK/v2.bin" "$WORK/v2d.bin"

echo "== 1. the audit on $BUILD (tenant $TENANT)"
if python3 tools/audit_variant_dispatch.py "$WORK/vj.bin" "$WORK/v2.bin" \
        "$OPIMG" --tenant "$TENANT" --expect-clean > "$WORK/a.txt" 2>&1; then
    sed -n 's/^/  /p' "$WORK/a.txt" | grep -E "summary|TENANT|table" || true
    echo "  ok: tenant $TENANT inherits no base-half routine vs2 does not run"
else
    echo "  FAIL: the audit reports a spurious inherited routine:"
    sed 's/^/    /' "$WORK/a.txt"; fail=1
fi

echo "== 2. negative control: reintroduce one aliased row"
python3 - "$OPIMG" "$WORK/bad.bin" <<'PY'
import sys
# 0x02B672 is table 0x02B650's row 0x11; 0x0042 is the aliased value that
# gave Pyron row 0x01's palette routine on the select / route-map screens.
b = bytearray(open(sys.argv[1], "rb").read())
b[0x02B672:0x02B674] = b"\x00\x42"
open(sys.argv[2], "wb").write(bytes(b))
PY
if python3 tools/audit_variant_dispatch.py "$WORK/vj.bin" "$WORK/v2.bin" \
        "$WORK/bad.bin" --tenant 0x11 --expect-clean > "$WORK/b.txt" 2>&1; then
    echo "  FAIL: the audit PASSED an image carrying the aliased row"
    fail=1
else
    echo "  ok: the reintroduced aliased row is caught"
fi

echo "== 3. coverage control: every table must be judgeable"
n=$(sed -n 's/.*, \([0-9]*\) unjudgeable/\1/p' "$WORK/a.txt")
if [ "${n:-1}" = 0 ]; then
    echo "  ok: 0 tables unjudgeable (every vs2 twin located)"
else
    echo "  FAIL: $n table(s) unjudgeable — the sweep is not covering them,"
    echo "        which is how the first instance of this defect was missed"
    fail=1
fi

if [ "$fail" -ne 0 ]; then echo "FAIL: variant-row dispatch gate"; exit 1; fi
echo "PASS: variant-row dispatch gate (sweep + negative control + coverage)"
