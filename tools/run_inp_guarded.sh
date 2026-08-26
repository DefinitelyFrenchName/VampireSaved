#!/bin/sh
# run_inp_guarded.sh — play a WIDE_RECORD .inp back HEADLESS under
# tests/lua/inp_guard.lua (cheap mode: no -debug, faithful playback) and
# capture the game's own exception record the moment a crash fires.
# 14z-111 — the natural-path #99 capture instrument.
#
# Usage: ROMDIR=... tools/run_inp_guarded.sh <build_dir> <inp_name> [out_dir]
#   <inp_name> is the WIDE_RECORD name (dir under ~/.cache/vampire-saved/inp).
#   env MAME_BIN, ARM_FRAME, MAX_FRAMES, STOP_AFTER, SELFTEST_FRAME pass through.
# Output: <out_dir>/inp_guard.log (+ crash_<frame>_ff0000.bin dumps).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${1:?build dir}"; NAME="${2:?inp name}"; OUT="${3:-$REPO/build/inp_guard/$NAME}"
BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
D="$HOME/.cache/vampire-saved/inp/$NAME"
[ -f "$D/$NAME.inp" ] || { echo "no $D/$NAME.inp" >&2; exit 1; }
RP="$REPO/$BUILD/rompath"; [ -f "$RP/vsavjw.zip" ] || { echo "no WIDE build at $RP" >&2; exit 1; }
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
SB="$(mktemp -d)"; trap 'rm -rf "$SB"' EXIT
cp -R "$D/nvram" "$SB/nvram"
mkdir -p "$SB/cfg" "$SB/diff" "$SB/snap" "$SB/sta"
echo "== playback $D/$NAME.inp on $BUILD -> $OUT/inp_guard.log"
: "${SDL_VIDEODRIVER:=dummy}"; export SDL_VIDEODRIVER
cd "$OUT"
CHECKSUM_OUT="$OUT/inp_guard.log" "$BIN" vsavjw -rompath "$RP;$ROMDIR" \
    -playback "$NAME.inp" -input_directory "$D" -nvram_directory "$SB/nvram" \
    -keyboardprovider none -mouseprovider none -joystickprovider none -lightgunprovider none \
    -video none -sound none -nothrottle -skip_gameinfo \
    -cfg_directory "$SB/cfg" -diff_directory "$SB/diff" -snapshot_directory "$SB/snap" \
    -state_directory "$SB/sta" -homepath "$SB" \
    -autoboot_script "$REPO/tests/lua/inp_guard.lua" > "$OUT/mame.out" 2>&1 || true
grep -E "^(CRASH|REGS|STACK|DUMP|SELFTEST|END)" "$OUT/inp_guard.log" || { echo "NO GUARD OUTPUT — see $OUT/mame.out"; tail -5 "$OUT/mame.out"; exit 1; }
