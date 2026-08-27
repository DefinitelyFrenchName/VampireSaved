#!/bin/sh
# test_inp_crash_merged_m8_01.sh — THE #99 NATURAL-PATH CAPTURE, as a gate (14z-111).
# tests/inp/crash-merged-m8-01 is the maintainer's own MAME session (WIDE_RECORD): 1P
# Donovan, 6+HP through Bishamon, keep-away vs CPU-Phobos -> the crash the
# field reported, reproduced BY HAND on merged15 after every scripted rig
# ran clean. Played back headless under tests/lua/inp_guard.lua.
#
#   MODE=defect (the default until the fix shipped in merged-m9): asserts the crash fires EXACTLY
#         as captured — vec11 (line-F) at PRG:0x422BAC, frame 4806 (+-2) —
#         so the capture itself cannot rot silently.
#   MODE=clean (DEFAULT since 14z-111): asserts NO exception fires through frame 6000 (the recording
#         ends ~4900; MAX_FRAMES overrides) (the
#         fix's acceptance; flip the default in the same commit as the fix).
# Usage: ROMDIR=... [MODE=defect|clean] [BUILD=build/m3b_merged15] tests/test_inp_crash_merged_m8_01.sh
# Emulator tier (MAME, ~1 min). NOT ci_static.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged16}"   # re-point at every merged freeze
MODE="${MODE:-clean}"   # flipped 14z-111 with the fix (merged-m9); MODE=defect reproduces the capture on merged15
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
# stage the tracked recording where run_inp_guarded.sh expects it, isolated
export HOME_INP="$W/inp"; mkdir -p "$W/inp"; cp -R tests/inp/crash-merged-m8-01 "$W/inp/"
HOME="$W" INP_HOME="$W" sh -c '
  mkdir -p "$HOME/.cache/vampire-saved" && ln -s "$HOME/inp" "$HOME/.cache/vampire-saved/inp"
  MAME_BIN="${MAME_BIN:-'"$HOME"'/.cache/vampire-saved/mame/cps2}" \
  STOP_AFTER=5 MAX_FRAMES="${MAX_FRAMES:-6000}" tools/run_inp_guarded.sh "'"$BUILD"'" crash-merged-m8-01 "'"$W"'/out"' > "$W/run.txt" 2>&1 || true
grep -E "^(CRASH|END)" "$W/run.txt" || { echo "FAIL: no guard output"; tail -5 "$W/run.txt"; exit 1; }
CR="$(grep -m1 "^CRASH" "$W/run.txt" || true)"
case "$MODE" in
defect)
    echo "$CR" | grep -Eq "^CRASH 480[4-8] vec11 PC 422bac " \
        && { echo "PASS (defect mode): the captured crash fires as frozen — $CR"; exit 0; } \
        || { echo "FAIL (defect mode): expected 'CRASH 4806 vec11 PC 422bac', got '${CR:-none}'"; exit 1; } ;;
clean)
    [ -z "$CR" ] && { echo "PASS (clean mode): the recording plays through with no exception"; exit 0; } \
        || { echo "FAIL (clean mode): $CR"; exit 1; } ;;
*)  echo "unknown MODE $MODE"; exit 2 ;;
esac
