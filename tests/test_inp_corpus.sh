#!/bin/sh
# test_inp_corpus.sh — EVERY tracked hand-played recording plays through with
# NO CPU exception on the current merged build. 14z-111, maintainer-ruled.
#
# WHY THIS EXISTS (the learning, paid for in 14z-109..111). WIDE_RECORD
# (tools/run_wide.sh) had existed since 14z-9x and HANDOFF called a recorded
# field report "a replay protocol" — but no gate consumed the recordings and
# no crash report was ever captured as one. Three sessions and two shipped
# fixes (14z-110, 14z-110b) were spent on a rig-derived, poke-contaminated
# mechanism that was never the field crash; the maintainer's FIRST recording
# (tests/inp/crash_m10) found the real one in an evening. The tooling was
# never the gap — its systematic use was. So:
#   * every reproducible field/playtest crash is captured as a WIDE_RECORD
#     .inp BEFORE any theory (CLAUDE.md §4, "FIELD REPORTS ARE RECORDINGS");
#   * every recording is tracked under tests/inp/<name>/ (force-added, like
#     savestates) with a one-line NOTE file saying what it exercises;
#   * this gate replays ALL of them under tests/lua/inp_guard.lua at every
#     freeze and fails on the first exception anywhere.
# A recording that still crashes on purpose (a captured-but-unfixed defect)
# is declared by a DEFECT file in its dir naming the expected "vec<n> PC
# <pc6>" — the gate then asserts that exact crash instead (so the capture
# cannot rot) and lists it loudly as OPEN.
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged16] [ONLY=name] tests/test_inp_corpus.sh
# Emulator tier (MAME, ~1 min per recording). NOT ci_static.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged16}"   # re-point at every merged freeze
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no WIDE build at $BUILD"; exit 1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mkdir -p "$W/inp" "$W/.cache/vampire-saved"; ln -s "$W/inp" "$W/.cache/vampire-saved/inp"
n=0; fail=0; open=0
for d in tests/inp/*/; do
    name="$(basename "$d")"
    [ -n "${ONLY:-}" ] && [ "$name" != "$ONLY" ] && continue
    [ -f "$d/$name.inp" ] || { echo "  FAIL: $d has no $name.inp"; fail=1; continue; }
    n=$((n+1)); cp -R "$d" "$W/inp/$name"
    HOME="$W" MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}" \
        STOP_AFTER=5 MAX_FRAMES="${MAX_FRAMES:-6000}" \
        tools/run_inp_guarded.sh "$BUILD" "$name" "$W/out_$name" > "$W/run_$name.txt" 2>&1 || true
    CR="$(grep -m1 '^CRASH' "$W/run_$name.txt" || true)"
    grep -q '^END' "$W/run_$name.txt" || { echo "  FAIL: $name — no END line (dead run)"; tail -3 "$W/run_$name.txt"; fail=1; continue; }
    if [ -f "$d/DEFECT" ]; then
        want="$(cat "$d/DEFECT")"; open=$((open+1))
        echo "$CR" | grep -q "$want" \
            && echo "  OPEN (as frozen): $name — $CR" \
            || { echo "  FAIL: $name declared DEFECT '$want' but got '${CR:-none}' — the capture rotted or the defect moved"; fail=1; }
    elif [ -n "$CR" ]; then
        echo "  FAIL: $name — $CR"; echo "        $(cat "$d/NOTE" 2>/dev/null || echo 'no NOTE')"; fail=1
    else
        echo "  ok: $name plays through clean ($(cat "$d/NOTE" 2>/dev/null || echo 'no NOTE'))"
    fi
done
[ "$n" -gt 0 ] || { echo "FAIL: no recordings under tests/inp/"; exit 1; }
[ "$fail" -eq 0 ] && { echo "PASS: $n recording(s) replayed on $BUILD, no exception ($open declared-open)"; exit 0; }
echo "FAIL: inp corpus"; exit 1
