#!/bin/sh
# audit_trap_sound.sh — the MK Plasma Trap fires, ring live (14z-82d
# lock, RE-SCOPED 14z-85g).
#
# WHY. Air 214+MK's detonation crashed the machine on every Phobos build
# before the 14z-79 (b') fix. This audit locks that fix: the 87 timer
# rig must SPAWN the mine (type-69 write into the projectile pool) and
# the sound RING must be live across the run (id 0x049A enqueued — a
# crashing trap dies before any ring activity continues).
#
# RETRACTED (14z-85g): the 14z-82d attribution of 0x049A as "the
# detonation sfx" was a timing coincidence — 0x049A is PERIODIC AMBIENT
# (~144-frame cadence, starts f2594, BEFORE any trap input, on native
# vs2 too; its f3571/f3716 hits are two cadence beats, not two
# detonations). The trap's REAL sounds are per-node record nodes 10/11
# (ids 0x0739 spawn / 0x073A timer detonation), measured on native vs2
# — and on our build they are ZEROED BY THE 14z-85b CURATION, correctly
# (vsavj keys MUSIC-family content at those same ids; un-zeroing =
# the music-retrigger bug). The parity question this header used to
# carry is therefore CLOSED: the detonation chirp is RESTORED 14z-85g
# (sound_stub -> vsavj 0x199, same sample bytes; huitzil-m9); only the
# EJECTION sound (0x739) remains M5.
# THE PARITY GATE is tests/audit_trap_parity.sh (frozen per-attempt
# inventories, ours vs native; forbids 0739/073a on ours).
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

# ── 2: the ring is LIVE across the trap window (ambient id 0x049A
#       present — a crash would cut the cadence; NOT the detonation id,
#       see the header retraction) ─────────────────────────────────────
REPLAY="$PWD/tests/replays/hui/87_hui_plasma_trap.rpl" FRAMES=5000 \
POKES="$PK" TRACE_OUT="$W/ring.txt" MAME_SANDBOX="$W/sbx2" \
MAME_ROMPATH="$(abspath "$BUILD")/rompath;$ROMDIR" \
    tools/run_mame.sh vsavjw \
    -autoboot_script "$PWD/tests/lua/ring_tap.lua" >/dev/null 2>&1 || true
DET="$(grep -c "id 049a" "$W/ring.txt" || true)"
if [ "${DET:-0}" -ge 1 ]; then
    echo "  PASS  2: ring live across the trap window (ambient 049a x$DET)"
else
    echo "  FAIL  2: ambient id 0x049A never reached the ring — the run"
    echo "        died or the tap is dead (pre-(b') builds CRASHED here)"
    fail=1
fi

[ "$fail" = 0 ] && echo "audit_trap_sound: PASS (MK trap fires; ring live)" \
                || echo "audit_trap_sound: FAILURES"
exit "$fail"
