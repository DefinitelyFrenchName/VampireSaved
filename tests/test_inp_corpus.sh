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
# (tests/inp/crash-merged-m8-01) found the real one in an evening. The tooling was
# never the gap — its systematic use was. So:
#   * every reproducible field/playtest crash is captured as a WIDE_RECORD
#     .inp BEFORE any theory (CLAUDE.md §4, "FIELD REPORTS ARE RECORDINGS");
#   * every recording is tracked under tests/inp/<name>/ (force-added, like
#     savestates) with a one-line NOTE file saying what it exercises, NAMED
#     <what>-<freeze set>-NN after the freeze it was PLAYED on
#     (crash-merged-m8-01), never the mark or the session;
#   * the ~/.cache copy is deleted once tracked; untracked, unreferenced
#     recordings are deleted after a grep (CLAUDE.md §4);
#   * this gate replays ALL of them under tests/lua/inp_guard.lua at every
#     freeze and fails on the first exception anywhere.
# A recording that still crashes on purpose (a captured-but-unfixed defect)
# is declared by a DEFECT file in its dir naming the expected "vec<n> PC
# <pc6>" — the gate then asserts that exact crash instead (so the capture
# cannot rot) and lists it loudly as OPEN.
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged22] [ONLY=name] tests/test_inp_corpus.sh  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
# Emulator tier (MAME, ~1 min per recording). NOT ci_static.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged22}"   # re-point at every merged freeze  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no WIDE build at $BUILD"; exit 1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mkdir -p "$W/inp" "$W/.cache/vampire-saved"; ln -s "$W/inp" "$W/.cache/vampire-saved/inp"
# LIVENESS, and it is a real check rather than a formality. A run that played
# ZERO frames executes no code, so it can raise no exception and would sail
# through the "no CRASH" test below: green while asserting nothing. That state
# is reachable — a RELATIVE ROMDIR makes both runners lose the parent zip and
# report "Total playback frames: 0" (paid for 14z-126b). The runners no longer
# terminate such a run at all; this rejects it a second way, because a gate
# whose only liveness test is "some END line exists" is one bug away from
# testing nothing.
live_run() {
    _e="$(grep -m1 '^END' "$1" | awk '{print $2}')"
    _p="$(grep -m1 '^PLAYBACK' "$1" | awk '{print $2}')"
    [ -n "$_e" ] || return 1
    [ "$_e" -gt 0 ] 2>/dev/null || return 1
    [ -z "$_p" ] || [ "$_p" -gt 0 ] 2>/dev/null || return 1
    return 0
}
live_why() {
    grep -q '^END' "$1" || { echo "no END line"; return; }
    echo "END $(grep -m1 '^END' "$1" | awk '{print $2}')/PLAYBACK $(grep -m1 '^PLAYBACK' "$1" | awk '{print $2}') — zero frames played"
}

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
    live_run "$W/run_$name.txt" || { echo "  FAIL: $name — dead run ($(live_why "$W/run_$name.txt"))"; tail -3 "$W/run_$name.txt"; fail=1; continue; }
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
# ---- CONTROL: the liveness predicate must actually reject a dead run -------
# [VSP-19]: a test's classification code is validated against known ground
# truth before its verdicts are trusted. Without this, the check above could
# rot back into "any END line will do" and nothing would notice.
CW="$(mktemp -d)"; trap 'rm -rf "$CW"' EXIT
printf 'PLAYBACK 0\nEND 0\n'       > "$CW/dead.txt"
printf 'V 1 x\nEND 0\n'            > "$CW/dead_noplayback.txt"
printf 'PLAYBACK 5000\nEND 5000\n' > "$CW/live.txt"
printf 'V 1 x\n'                    > "$CW/noend.txt"
cerr=0
live_run "$CW/dead.txt"            && { echo "  FAIL control: a 0-frame run was accepted as live"; cerr=1; }
live_run "$CW/dead_noplayback.txt" && { echo "  FAIL control: END 0 was accepted as live"; cerr=1; }
live_run "$CW/noend.txt"           && { echo "  FAIL control: a run with no END was accepted as live"; cerr=1; }
live_run "$CW/live.txt"            || { echo "  FAIL control: a real run was rejected as dead"; cerr=1; }
[ "$cerr" -eq 0 ] && echo "  ok liveness controls fired (3 dead rejected, 1 live accepted)" || fail=1

[ "$n" -gt 0 ] || { echo "FAIL: no recordings under tests/inp/"; exit 1; }
[ "$fail" -eq 0 ] && { echo "PASS: $n recording(s) replayed on $BUILD, no exception ($open declared-open)"; exit 0; }
echo "FAIL: inp corpus"; exit 1
