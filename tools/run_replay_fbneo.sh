#!/bin/sh
# run_replay_fbneo.sh — run one input-script replay on patched FBNeo, emit
# checksum log (format-identical to the MAME harness logs).
#
# Usage: ROMDIR=... tools/run_replay_fbneo.sh <set> <replay.rpl> <out.log> [sandbox]
#   env FBNEO_DUMPS    optional "-hdump" spec, same grammar as the MAME
#                      harness DUMPS ("2900:ff8000-ff8700;..."); dump files
#                      land next to <out.log> as <out.log>.dump_<f>_<a>.bin
#   env FBNEO_ROMPATH  optional dir of zips overlaying $ROMDIR (patched-build
#                      runs: its vsavj.zip wins over the reference one)
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
if [ -n "${FBNEO_ROMPATH:-}" ]; then
    # per-zip overlay: reference zips first, overlay zips win
    rm -rf "$WORK/roms"; mkdir -p "$WORK/roms"
    for z in "$ROMDIR"/*.zip; do ln -sf "$z" "$WORK/roms/$(basename "$z")"; done
    for z in "$FBNEO_ROMPATH"/*.zip; do ln -sf "$z" "$WORK/roms/$(basename "$z")"; done
else
    ln -sfn "$ROMDIR" "$WORK/roms"
fi

set -- "$SET" -hinput "$RPL" -hout "$OUT"
[ -n "${FBNEO_DUMPS:-}" ] && set -- "$@" -hdump "$FBNEO_DUMPS"

( cd "$WORK" && HOME="$WORK" SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
    "$FBNEO" "$@" > "$WORK/fbneo_replay.log" 2>&1 ) \
    || { cat "$WORK/fbneo_replay.log"; exit 1; }
grep -q "^END " "$OUT" || { echo "harness did not complete (no END line)"; cat "$WORK/fbneo_replay.log"; exit 1; }
