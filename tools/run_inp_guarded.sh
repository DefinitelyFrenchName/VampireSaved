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
# ROMDIR MUST BE ABSOLUTE: this script `cd "$OUT"` before invoking MAME, so a
# RELATIVE ROMDIR resolves against the OUTPUT dir, the parent zip is not found,
# and playback silently becomes a ZERO-FRAME run (paid for 14z-126b). Resolve it
# here and fail loudly if it does not exist.
ROMDIR="$(cd "$ROMDIR" 2>/dev/null && pwd)" || { echo "ROMDIR does not exist: ${ROMDIR}" >&2; exit 2; }
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
EXITFLAG="-exit_after_playback"
[ -n "${INP_RUN_PAST_END:-}" ] && EXITFLAG=""
DBG=""
if [ -n "${INP_DEBUG:-}" ]; then
    # debugger mode: -debug halts at the first instruction; the debugscript
    # resumes it (tools/run_replay_guarded.sh pattern). Timeslicing differs
    # from cheap mode — compare crash frames before trusting a trace.
    printf 'go\n' > "$SB/go.dbg"; DBG="-debug -debugger none -debugscript $SB/go.dbg"
fi
CHECKSUM_OUT="$OUT/inp_guard.log" "$BIN" vsavjw -rompath "$RP;$ROMDIR" $DBG \
    -playback "$NAME.inp" -input_directory "$D" $EXITFLAG -nvram_directory "$SB/nvram" \
    -keyboardprovider none -mouseprovider none -joystickprovider none -lightgunprovider none \
    -video none -sound none -nothrottle -skip_gameinfo \
    -cfg_directory "$SB/cfg" -diff_directory "$SB/diff" -snapshot_directory "$SB/snap" \
    -state_directory "$SB/sta" -homepath "$SB" \
    -autoboot_script "$REPO/tests/lua/inp_guard.lua" > "$OUT/mame.out" 2>&1 || true
# The run stops at the END OF THE RECORDING (-exit_after_playback), so nothing
# past the maintainer's last input is ever measured. MAME 0.288 gives Lua no
# machine-stop hook, so the terminator is written here: PLAYBACK <n> is MAME's
# own authoritative count of recorded frames, END <n> the last sampled frame.
PB="$(grep -o 'Total playback frames: [0-9]*' "$OUT/mame.out" | tail -1 | awk '{print $4}')"
# ONLY a run that MAME itself reports as a playback gets a terminator: an
# absent END must stay absent so the corpus gate's dead-run check can still
# fail (RH-25 — a gate that cannot fail is not a gate).
# PB="0" means MAME loaded no recorded frames at all (bad .inp, missing member,
# relative ROMDIR). That is a DEAD RUN and must not be terminated, or the corpus
# gate greps a green "END 0" and asserts nothing. `[ -n "$PB" ]` alone was true
# for "0" and defeated the rule this very comment states (fixed 14z-126b).
if [ -n "$PB" ] && [ "$PB" -gt 0 ] 2>/dev/null; then
    echo "PLAYBACK $PB" >> "$OUT/inp_guard.log"
    grep -q '^END' "$OUT/inp_guard.log" || echo "END $PB" >> "$OUT/inp_guard.log"
fi
grep -E "^(CRASH|REGS|STACK|DUMP|SELFTEST|TRACE|W |END)" "$OUT/inp_guard.log" || { echo "NO GUARD OUTPUT — see $OUT/mame.out"; tail -5 "$OUT/mame.out"; exit 1; }
