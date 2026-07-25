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
REPLAY="$RPL" CHECKSUM_OUT="$OUT" MAME_SANDBOX="$WORK" \
    "$REPO/tools/run_mame.sh" "$SET" \
    -autoboot_script "$REPO/tests/lua/replay.lua" > "$WORK/mame_replay.log" 2>&1 \
    || { cat "$WORK/mame_replay.log"; exit 1; }
grep -q "^END " "$OUT" || { echo "replay did not complete (no END line)"; cat "$WORK/mame_replay.log"; exit 1; }
