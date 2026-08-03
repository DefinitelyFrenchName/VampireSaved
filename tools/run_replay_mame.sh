#!/bin/sh
# run_replay_mame.sh — run one input-script replay on MAME, emit checksum log.
#
# Usage: ROMDIR=... tools/run_replay_mame.sh <set> <replay.rpl> <out.log> [sandbox]
set -eu

SET="${1:?usage: run_replay_mame.sh <set> <replay.rpl> <out.log> [sandbox]}"
RPL="${2:?replay path required}"
OUT="${3:?output log path required}"
SANDBOX="${4:-}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"

RPL="$(cd "$(dirname "$RPL")" && pwd)/$(basename "$RPL")"
OUT_DIR="$(cd "$(dirname "$OUT")" && pwd)"; OUT="$OUT_DIR/$(basename "$OUT")"

WORK="${SANDBOX:-$(mktemp -d)}"
mkdir -p "$WORK"
REPLAY="$RPL" CHECKSUM_OUT="$OUT" MAME_SANDBOX="$WORK" \
    "$REPO/tools/run_mame.sh" "$SET" \
    -autoboot_script "$REPO/tests/lua/replay.lua" > "$WORK/mame_replay.log" 2>&1 \
    || { cat "$WORK/mame_replay.log"; exit 1; }
grep -q "^END " "$OUT" || { echo "replay did not complete (no END line)"; cat "$WORK/mame_replay.log"; exit 1; }
# Input-integrity violation: host input reached the emulated controls, so
# this run is not a replay of the script and must never be compared against
# anything. Fail here rather than let a corrupt log into a gate.
if grep -q "^INPUT-VIOLATION " "$OUT"; then
    echo "INPUT INTEGRITY VIOLATION — external input reached the machine:"
    grep "^INPUT-VIOLATION " "$OUT"
    echo "  (tools/run_mame.sh disables all host input providers; if this"
    echo "   fires, something bypassed that. The run is discarded.)"
    exit 1
fi
