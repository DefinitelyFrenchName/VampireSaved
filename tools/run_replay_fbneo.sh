#!/bin/sh
# run_replay_fbneo.sh — run one input-script replay on patched FBNeo, emit
# checksum log (format-identical to the MAME harness logs).
#
# Usage: ROMDIR=... tools/run_replay_fbneo.sh <set> <replay.rpl> <out.log> [sandbox]
set -eu

SET="${1:?usage: run_replay_fbneo.sh <set> <replay.rpl> <out.log> [sandbox]}"
RPL="${2:?replay path required}"
OUT="${3:?output log path required}"
SANDBOX="${4:-}"
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
FBNEO="$REPO/emu/fbneo/fbneo"
[ -x "$FBNEO" ] || { echo "no FBNeo binary; build: (cd emu/fbneo && make sdl2 SKIPDEPEND=1 -j8)"; exit 1; }

RPL="$(cd "$(dirname "$RPL")" && pwd)/$(basename "$RPL")"
OUT_DIR="$(cd "$(dirname "$OUT")" && pwd)"; OUT="$OUT_DIR/$(basename "$OUT")"

WORK="${SANDBOX:-$(mktemp -d)}"
mkdir -p "$WORK"
ln -sfn "$ROMDIR" "$WORK/roms"
( cd "$WORK" && HOME="$WORK" SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
    "$FBNEO" "$SET" -hinput "$RPL" -hout "$OUT" > "$WORK/fbneo_replay.log" 2>&1 ) \
    || { cat "$WORK/fbneo_replay.log"; exit 1; }
grep -q "^END " "$OUT" || { echo "harness did not complete (no END line)"; cat "$WORK/fbneo_replay.log"; exit 1; }
