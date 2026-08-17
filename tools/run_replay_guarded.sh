#!/bin/sh
# run_replay_guarded.sh — run one replay under the crash guard
# (tests/lua/replay_guard.lua). Same interface as run_replay_mame.sh.
#
# Usage: ROMDIR=... tools/run_replay_guarded.sh <set> <replay.rpl> <out.log> [sandbox]
#   env GUARD_DEBUG=0     cheap mode (no -debug); default 1 = authoritative
#   env CRASH_VECTORS / CODE_RANGES / GUARD_MATCH / DUMPS / SNAP_FRAMES /
#       TAIL_FRAMES / MAME_ROMPATH pass through to the guard / runner.
#   env GUARD_PROBE=hexaddr [GUARD_PROBE_COND=expr]  logging breakpoint:
#       PROBE lines in the log (regs + return addr), run continues.
#
# Exit 0 only if the log ends with a clean "END " line AND contains no
# CRASH/PCWEEDS/SOFTRESET/END-CRASH lines. The log is the bug report.
set -eu

SET="${1:?usage: run_replay_guarded.sh <set> <replay.rpl> <out.log> [sandbox]}"
RPL="${2:?replay path required}"
OUT="${3:?output log path required}"
SANDBOX="${4:-}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"

RPL="$(cd "$(dirname "$RPL")" && pwd)/$(basename "$RPL")"
OUT_DIR="$(cd "$(dirname "$OUT")" && pwd)"; OUT="$OUT_DIR/$(basename "$OUT")"

WORK="${SANDBOX:-$(mktemp -d)}"
mkdir -p "$WORK"

# Build the MAME argument list. With -debug the debugger halts at the first
# instruction; the -debugscript "go" resumes it at emulated time zero (the
# guard's periodic callback would also resume it, but this is deterministic
# insurance). NOTE: -debug runs are deterministic but NOT checksum-comparable
# to non-debug runs (scheduler timeslicing differs — docs/GOTCHAS.md); use
# GUARD_DEBUG=0 when the checksum log must match frozen expectations.
set -- "$SET" -autoboot_script "$REPO/tests/lua/replay_guard.lua"
if [ "${GUARD_DEBUG:-1}" = "1" ]; then
    printf 'go\n' > "$WORK/guard_go.dbs"
    set -- "$@" -debug -debugger none -debugscript "$WORK/guard_go.dbs"
fi

REPLAY="$RPL" CHECKSUM_OUT="$OUT" MAME_SANDBOX="$WORK" \
    "$REPO/tools/run_mame.sh" "$@" > "$WORK/mame_guard.log" 2>&1 \
    || { cat "$WORK/mame_guard.log"; exit 1; }

# INPUT-VIOLATION joins the trip set (14z-94, GitHub #31). The guard now
# carries replay.lua's input-integrity assertion, and a violation means the
# run stopped being a replay of the script — a stray host press, a joystick, a
# stuck modifier. MAME's window takes focus even under -video none. Without it
# in this grep the line would be written to the log and never read, which is
# the same silent PASS the check exists to remove.
if grep -Eq "^(CRASH|PCWEEDS|SOFTRESET|END-CRASH|INPUT-VIOLATION) " "$OUT"; then
    echo "GUARD TRIPPED:"
    grep -E "^(CRASH|STACK|PCWEEDS|SOFTRESET|END-CRASH|INPUT-VIOLATION) " "$OUT"
    exit 2
fi
grep -q "^END " "$OUT" || { echo "replay did not complete (no END line)"; cat "$WORK/mame_guard.log"; exit 1; }
