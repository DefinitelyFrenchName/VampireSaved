#!/bin/sh
# test_fbneo_smoke.sh — M0: the FBNeo headless runner boots vsavj and
# survives a soak without crashing.
#
# Usage: ROMDIR=/path/to/roms tests/test_fbneo_smoke.sh [set] [seconds]
# PASS = all ROM members load OK, emulation starts, and the process is still
# alive after the soak period (we kill it ourselves).
set -eu

SET="${1:-vsavj}"
SOAK="${2:-15}"
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FBNEO_SANDBOX="$WORK/sandbox" ROMDIR="$ROMDIR" \
    "$REPO/tools/run_fbneo.sh" "$SET" > "$WORK/fb.log" 2>&1 &
FBPID=$!
sleep "$SOAK"

if ! kill -0 "$FBPID" 2>/dev/null; then
    echo "FAIL: FBNeo exited before ${SOAK}s soak ended; log:"
    cat "$WORK/fb.log"
    exit 1
fi
kill "$FBPID" 2>/dev/null
wait "$FBPID" 2>/dev/null || true

grep -q "Starting emulation of $SET" "$WORK/fb.log" || { echo "FAIL: no emulation start line"; cat "$WORK/fb.log"; exit 1; }
# ROM member loads log as "Loading <name>... (OK)"; anything else is a failure
if grep "Loading.*\.\.\." "$WORK/fb.log" | grep -qv "(OK)"; then
    echo "FAIL: some ROM members failed to load:"
    grep "Loading.*\.\.\." "$WORK/fb.log" | grep -v "(OK)"
    exit 1
fi
LOADED=$(grep -c "(OK)" "$WORK/fb.log")
echo "PASS: $SET booted headless in FBNeo, $LOADED members loaded OK, alive after ${SOAK}s"
