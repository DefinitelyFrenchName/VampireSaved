#!/bin/sh
# test_fsm_census.sh — the STATIC object-script node-state census gate
# (14z-110, GitHub #99). Locks tools/audit_fsm_census.py against its frozen
# inventory (build/manifest/fsm_census.toml) AND proves the checker can fail.
#
# WHAT IT LOCKS. Every ported node whose object-script state byte (+0x17) is
# >= vsavj's 80-entry FSM table size is enumerated and its dispatcher-level vs2
# equivalence classified. The frozen inventory is the point: a tenant edit that
# introduces a NEW out-of-range member fails here instead of on a CRT — the
# build-time guard #99 asked for.
#
# NEGATIVE CONTROLS (a checker that cannot fail is not a checker, RH-8/25):
#   1. perturb a node's +0x17 from 0x51 to a fresh out-of-range value in a
#      COPY of verify_data.bin -> --check must FAIL (ADDED/idx change).
#   2. clear a node's +0x17 to an in-range value -> --check must FAIL (MISSING).
#   3. the pristine build -> --check must PASS.
#
# Needs ROMDIR (the vs2 classification oracle) + a build with verify_{data,op}.bin.
# No emulator, seconds.
# Usage: ROMDIR=... tests/test_fsm_census.sh [builddir]
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${1:-build/m3b_merged13}"
INV="build/manifest/fsm_census.toml"
VS2="$ROMDIR/vsav2.zip"
[ -f "$BUILD/verify_data.bin" ] || { echo "SKIP: no verify_data.bin in $BUILD"; exit 0; }
[ -f "$VS2" ] || { echo "SKIP: no vsav2.zip in ROMDIR"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok()  { echo "  ok: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

echo "== 3: pristine build matches the frozen inventory"
if python3 tools/audit_fsm_census.py "$BUILD" --vs2 "$VS2" --check "$INV" >"$W/pristine.log" 2>&1; then
    ok "pristine --check PASS"
else
    bad "pristine --check did not pass"; cat "$W/pristine.log"
fi

# Build a perturbed sandbox: copy the build's two images, mutate data.
mkdir -p "$W/b/patch"
cp "$BUILD/verify_op.bin" "$W/b/"
cp "$BUILD/patch/atlas_fragment.md" "$W/b/patch/"

echo "== 1: a fresh out-of-range +0x17 must be caught as ADDED/changed"
python3 - "$BUILD/verify_data.bin" "$W/b/verify_data.bin" <<'PY'
import sys
d = bytearray(open(sys.argv[1], "rb").read())
# 0x3FB862 is a frozen 0x51 node; make it 0x53 (still out of range, different idx)
assert d[0x3FB862 + 0x17] == 0x51, d[0x3FB862 + 0x17]
d[0x3FB862 + 0x17] = 0x53
open(sys.argv[2], "wb").write(d)
PY
if python3 tools/audit_fsm_census.py "$W/b" --vs2 "$VS2" --check "$INV" >"$W/perturb.log" 2>&1; then
    bad "checker PASSED on a perturbed +0x17 (0x51->0x53) — it cannot fail"
else
    grep -q "FAIL: census differs" "$W/perturb.log" && ok "perturbed +0x17 caught" \
        || { bad "checker failed for the wrong reason"; cat "$W/perturb.log"; }
fi

echo "== 2: clearing a node to in-range must be caught as MISSING"
python3 - "$BUILD/verify_data.bin" "$W/b/verify_data.bin" <<'PY'
import sys
d = bytearray(open(sys.argv[1], "rb").read())
d[0x3FB882 + 0x17] = 0x19          # in range -> node drops out of the census
open(sys.argv[2], "wb").write(d)
PY
if python3 tools/audit_fsm_census.py "$W/b" --vs2 "$VS2" --check "$INV" >"$W/miss.log" 2>&1; then
    bad "checker PASSED with a node removed — MISSING not detected"
else
    grep -q "MISSING" "$W/miss.log" && ok "removed node caught as MISSING" \
        || { bad "removal failed for the wrong reason"; cat "$W/miss.log"; }
fi

[ "$fail" = 0 ] && echo "PASS: test_fsm_census" || echo "FAIL: test_fsm_census"
exit "$fail"
