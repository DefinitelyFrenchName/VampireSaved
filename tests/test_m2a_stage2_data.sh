#!/bin/sh
# test_m2a_stage2_data.sh — M2a stage-2 gate: Donovan passive data.
#
# Stage 2 injects Donovan's hitbox + projectile-hitbox blobs and all his
# per-character value rows; Jedah's code and anim stay (dispatch 00/01 still
# route through the stage-1 trampolines). The mixture is wrong-but-defined:
# Jedah's moveset reading Donovan's numbers. Behavior correctness is NOT
# gated here — coherence and provenance are:
#   1. Live effect: slot 0x0F loads Donovan's RELOCATED hitbox base/comp
#      (addresses from the generator's placements.json — no hardcoding).
#   2. Coherence: a full round (pick + idle to KO/timeout, ~9300 frames)
#      completes under the cheap guard (match flags stable in-round, END
#      reached), and the pick window is exception-free under -debug guard.
#   3. Superset invariant: legacy gate green; pick replay still first
#      diverges exactly at 2886.
#
# Usage: ROMDIR=... tests/test_m2a_stage2_data.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/m2a_common.sh"
WORK="$(mktemp -d)"   # the stage build lives HERE (14z-133b): build/donovan was an M2a-era dir the
                      # build-dir policy pruned around, and pack_build.sh rightly refused an empty prg/ (RED 14z-128)
trap 'rm -rf "$WORK"' EXIT
fail=0

PICK_DIVERGE=2886

# --- build (no pipe: a generator failure must abort the gate) ------------
ROMDIR="$ROMDIR" "$REPO/tools/build_donovan.sh" 2 "$WORK/donovan" \
    > "$WORK/build.log" 2>&1 || { tail -15 "$WORK/build.log"; exit 1; }
tail -2 "$WORK/build.log"
RP="$WORK/donovan/rompath;$ROMDIR"

WANT_BASE=$(python3 - "$WORK/donovan/patch/placements.json" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))["regions"]["hitbox"]
print(f"{p['dst'] + (0x0C8DF8 - p['src']):08x}")
PY
)
WANT_COMP=$(python3 - "$WORK/donovan/patch/placements.json" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))["regions"]["hitbox"]
print(f"{p['dst'] + (0x0C8BB8 - p['src']):08x}")
PY
)

# --- 1. live effect ------------------------------------------------------
DUMPS="3600:ff8460-ff8468" MAME_ROMPATH="$RP" \
    REPLAY="$REPO/tests/replays/11_pick_donovan.rpl" \
    CHECKSUM_OUT="$WORK/pick.log" MAME_SANDBOX="$WORK/pickbox" \
    "$REPO/tools/run_mame.sh" vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
GOT=$(xxd -p "$WORK/dump_3600_ff8460.bin")
case "$GOT" in
    ${WANT_BASE}${WANT_COMP}*)
        echo "  ok: slot 0x0F loads Donovan relocated base 0x$WANT_BASE comp 0x$WANT_COMP" ;;
    *) echo "FAIL: +0x60/+0x64 = $GOT (want $WANT_BASE $WANT_COMP)"; fail=1 ;;
esac

# --- 2. coherence --------------------------------------------------------
cat > "$WORK/round.rpl" <<'EOF'
300-305 sys=C1
800-803 sys=S1
1000-1002 p1=U
1040-1042 p1=U
1080-1082 p1=R
1700-1702 p1=1
9300 wait
EOF
if GUARD_DEBUG=0 GUARD_MATCH="3000-3600" MAME_ROMPATH="$RP" \
        "$REPO/tools/run_replay_guarded.sh" vsavj "$WORK/round.rpl" \
        "$WORK/round.log" "$WORK/roundbox" > "$WORK/round.out" 2>&1; then
    echo "  ok: full round with Donovan data completes (cheap guard clean)"
else
    echo "FAIL: round run tripped the guard:"; cat "$WORK/round.out"; fail=1
fi
if MAME_ROMPATH="$RP" "$REPO/tools/run_replay_guarded.sh" vsavj \
        "$REPO/tests/replays/11_pick_donovan.rpl" "$WORK/guard.log" \
        "$WORK/guardbox" > "$WORK/guard.out" 2>&1; then
    echo "  ok: pick window exception-free (-debug guard)"
else
    echo "FAIL: -debug guard tripped:"; cat "$WORK/guard.out"; fail=1
fi

# --- 3. superset gate ----------------------------------------------------
m2a_legacy_gate "$RP" "$WORK"
[ "$gate_fail" = 0 ] || fail=1
if m2a_diverge "$WORK/pick.log" 11_pick_donovan "$PICK_DIVERGE" > /dev/null; then
    echo "  ok: pick replay diverges exactly at $PICK_DIVERGE"
else
    echo "FAIL: pick divergence moved:"; m2a_diverge "$WORK/pick.log" 11_pick_donovan "$PICK_DIVERGE" || true
    fail=1
fi

[ "$fail" = 0 ] && echo "PASS: stage 2 Donovan passive data proven coherent" \
    || { echo "SUITE RED"; exit 1; }
