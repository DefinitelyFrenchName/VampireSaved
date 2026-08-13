#!/bin/sh
# audit_trap_sound.sh — the MK Plasma Trap fires AND sounds (14z-82d lock).
#
# WHY. Air 214+MK's detonation crashed the machine on every Phobos build
# before the 14z-79 (b') fix — so its sfx had never been HEARD, and the
# maintainer's hui30 playtest read the restored sound as a new change.
# The 14z-82d measurement chain (ring A/B hui29-vs-hui30 byte-identical
# on both trap rigs; the liveness probes that named the mine as pool
# TYPE 69) resolved it. This audit locks the resolved behavior so a
# regression is loud: on the current huitzil build, the 87 timer rig
# must SPAWN the mine (type-69 write into the projectile pool) and SOUND
# its detonation (id 0x049A enqueued into the ring shortly after).
# Measured ground truth (hui29 == hui30): spawns f3432/f4232, throw id
# 0x010A f3474, detonation id 0x049A at f3571/f3716.
#
# RESOLVED NOT-A-BUG (maintainer, 14z-84): the detonation sound is
# PROXIMITY-TRIGGERED — all three variants sound with the opponent
# near. The item this line used to file as KNOWN-OPEN — LK/HK
# detonations have NO sound and never did — whether that is vs2-faithful
# needs a native three-strength comparison when the sound arc comes.
#
# Usage: ROMDIR=... tests/audit_trap_sound.sh [builddir]   (~10 min, 2 runs)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/hui30}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }

PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"

# ── 1: the mine SPAWNS (rig liveness — a silent run with no spawn would
#       read as regression-free while measuring nothing) ────────────────
REPLAY="$PWD/tests/replays/hui/87_hui_plasma_trap.rpl" TAP="ff9400,3c00" \
FRAMES=5000 POKES="$PK" TRACE_OUT="$W/w.txt" MAME_SANDBOX="$W/sbx1" \
MAME_ROMPATH="$(abspath "$BUILD")/rompath;$ROMDIR" \
    tools/run_mame.sh vsavjw \
    -autoboot_script "$PWD/tests/lua/type_write_census.lua" >/dev/null 2>&1 || true
SPAWNS="$(grep "^W" "$W/w.txt" | awk 'substr($9,5,2)=="45"' | wc -l | tr -d ' ')"
if [ "${SPAWNS:-0}" -ge 1 ]; then
    echo "  PASS  1: mine spawned (type-69 pool write x$SPAWNS)"
else
    echo "  FAIL  1: no type-69 spawn — the rig did not fire the move;"
    echo "        nothing below means anything (87's own status rules)"
    grep "^W" "$W/w.txt" | head -3
    exit 1
fi

# ── 2: the detonation SOUNDS (id 0x049A in the ring after the spawn) ────
REPLAY="$PWD/tests/replays/hui/87_hui_plasma_trap.rpl" FRAMES=5000 \
POKES="$PK" TRACE_OUT="$W/ring.txt" MAME_SANDBOX="$W/sbx2" \
MAME_ROMPATH="$(abspath "$BUILD")/rompath;$ROMDIR" \
    tools/run_mame.sh vsavjw \
    -autoboot_script "$PWD/tests/lua/ring_tap.lua" >/dev/null 2>&1 || true
DET="$(grep -c "id 049a" "$W/ring.txt" || true)"
if [ "${DET:-0}" -ge 1 ]; then
    echo "  PASS  2: detonation sfx enqueued (id 049a x$DET)"
else
    echo "  FAIL  2: detonation id 0x049A never reached the ring — the"
    echo "        MK trap has gone silent (or worse: check the guard on"
    echo "        this rig; pre-(b') builds CRASHED here)"
    fail=1
fi

[ "$fail" = 0 ] && echo "audit_trap_sound: PASS (MK trap fires and sounds)" \
                || echo "audit_trap_sound: FAILURES"
exit "$fail"
