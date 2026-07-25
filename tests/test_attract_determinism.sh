#!/bin/sh
# test_attract_determinism.sh — M0 acceptance: a 60-second scripted
# attract-mode run checksums work RAM identically across two fresh runs.
#
# Usage: ROMDIR=/path/to/roms tests/test_attract_determinism.sh [set] [frames]
# Defaults: vsavj, 3600 frames. PASS = per-frame checksum logs identical.
set -eu

SET="${1:-vsavj}"
FRAMES="${2:-3600}"
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for run in 1 2; do
    echo "== run $run ($SET, $FRAMES frames)"
    ( cd "$WORK" && \
      CHECKSUM_OUT="$WORK/run$run.txt" FRAMES="$FRAMES" \
      MAME_SANDBOX="$WORK/sandbox$run" ROMDIR="$ROMDIR" \
      "$REPO/tools/run_mame.sh" "$SET" \
          -autoboot_script "$REPO/tests/lua/attract_checksum.lua" \
          > "$WORK/run$run.log" 2>&1 ) || { cat "$WORK/run$run.log"; exit 1; }
    tail -1 "$WORK/run$run.txt"
done

if cmp -s "$WORK/run1.txt" "$WORK/run2.txt"; then
    echo "PASS: $FRAMES frames of work-RAM checksums identical across runs"
else
    echo "FAIL: checksum logs differ; first divergent frame:"
    diff "$WORK/run1.txt" "$WORK/run2.txt" | head -4
    exit 1
fi
