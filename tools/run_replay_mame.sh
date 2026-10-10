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
# CLEAR WHAT THIS RUN MUST WRITE, BEFORE IT RUNS (14z-197, GitHub #253). Success
# is read from an ARTIFACT (`^END` in $OUT), so a run that exits 0 without
# writing — the autoboot script never started, a frontend wrapper returned —
# would otherwise pass on the previous run's log; the FBNeo sibling has cleared
# its outputs since 14z-90 (#12). The side channels replay.lua writes are
# cleared by name too: INPUT_OUT, VIDEO_OUT, and each file a DUMPS spec names
# (`<dir of $OUT>/dump_<frame>_<start, %06x>.bin`, replay.lua's own naming) —
# never a glob, so another leg's dumps in a shared directory are left alone.
rm -f "$OUT"
[ -n "${INPUT_OUT:-}" ] && rm -f "$INPUT_OUT"
[ -n "${VIDEO_OUT:-}" ] && rm -f "$VIDEO_OUT"
_ifs="$IFS"; IFS=';'
for _spec in ${DUMPS:-}; do
    _fr="${_spec%%:*}"; _first="${_spec#*:}"; _first="${_first%%-*}"
    case "$_fr:$_first" in
        *[!0-9]*:*|:*|*:) ;;    # replay.lua asserts on a bad spec; nothing to name
        *) case "$_first" in *[!0-9a-fA-F]*) ;; *) rm -f "$OUT_DIR/$(printf 'dump_%d_%06x.bin' "$_fr" "0x$_first")" ;; esac ;;
    esac
done
IFS="$_ifs"
REPLAY="$RPL" CHECKSUM_OUT="$OUT" MAME_SANDBOX="$WORK" \
    "$REPO/tools/run_mame.sh" "$SET" \
    -autoboot_script "$REPO/tests/lua/replay.lua" > "$WORK/mame_replay.log" 2>&1 \
    || { cat "$WORK/mame_replay.log"; exit 1; }
grep -qs "^END " "$OUT" || { echo "replay did not complete (no END line)"; cat "$WORK/mame_replay.log"; exit 1; }
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
