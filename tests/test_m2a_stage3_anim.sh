#!/bin/sh
# test_m2a_stage3_anim.sh — M2a stage-3 gate: Donovan anim + sprite
# sub-table clusters, still under Jedah's dispatch code.
#
# This is the ladder's weakest mixture: Jedah's state handlers index
# Donovan's anim space. The gate is deliberately narrow — idle only:
#   1. Anim system engages the relocated data: after match start, the anim
#      script cursor (+0x1C) lies INSIDE the relocated anim region, sampled
#      across an ~600-frame idle window.
#   2. No crash across that window (-debug guard) and a full round
#      completes under the cheap guard.
#   3. Superset invariant: legacy gate green; pick divergence exactly 2886.
# A crash here may be a WAIVED-MIXTURE artifact ONLY with crash-stack
# evidence (Jedah handler PC reading Donovan anim data) AND stage 4 later
# passing — otherwise it is a real relocation bug (see docs/project/patch_notes.md).
#
# Usage: ROMDIR=... tests/test_m2a_stage3_anim.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/m2a_common.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# Stage 3 moves the pick replay's first divergence EARLIER than stages 1-2
# (2886, match init): the select screen reads the hovered character's ANIM
# data, so the cursor landing on slot 0x0F at frame 1080 is the first
# legitimate slot-0x0F involvement (measured; hitbox/value repoints alone
# don't touch the select screen).
PICK_DIVERGE=1080

# --- build ---------------------------------------------------------------
ROMDIR="$ROMDIR" "$REPO/tools/build_donovan.sh" 3 "$REPO/build/donovan" \
    > "$WORK/build.log" 2>&1 || { tail -15 "$WORK/build.log"; exit 1; }
tail -2 "$WORK/build.log"
RP="$REPO/build/donovan/rompath;$ROMDIR"

ANIM_RANGE=$(python3 - "$REPO/build/donovan/patch/placements.json" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))["regions"]["anim"]
print(f"{p['dst']:x} {p['dst'] + p['len']:x}")
PY
)

# --- 1+2. anim engagement + guarded idle window --------------------------
SPEC=$(python3 -c "print(';'.join(f'{f}:ff841c-ff8420' for f in range(3000,3600,40)))")
if DUMPS="$SPEC" MAME_ROMPATH="$RP" "$REPO/tools/run_replay_guarded.sh" vsavj \
        "$REPO/tests/replays/11_pick_donovan.rpl" "$WORK/idle.log" \
        "$WORK/idlebox" > "$WORK/idle.out" 2>&1; then
    echo "  ok: 600-frame idle window exception-free (-debug guard)"
else
    echo "FAIL: guard tripped during idle (mixture artifact or relocation bug):"
    cat "$WORK/idle.out"; fail=1
fi
if python3 - "$WORK" $ANIM_RANGE <<'PY'
import glob, sys
w, lo, hi = sys.argv[1], int(sys.argv[2], 16), int(sys.argv[3], 16)
bad = ok = 0
for f in sorted(glob.glob(f"{w}/dump_*_ff841c.bin")):
    v = int.from_bytes(open(f, "rb").read()[:4], "big")
    if lo <= v < hi:
        ok += 1
    else:
        bad += 1
        print(f"  {f.split('/')[-1]}: anim ptr {v:#x} OUTSIDE relocated anim [{lo:#x},{hi:#x})")
print(f"  anim ptr samples: {ok} inside relocated region, {bad} outside")
sys.exit(1 if bad or not ok else 0)
PY
then
    echo "  ok: anim cursor runs inside the relocated Donovan anim region"
else
    echo "FAIL: anim cursor not (fully) in relocated region"; fail=1
fi

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
    echo "  ok: full round with Donovan anim completes (cheap guard clean)"
else
    echo "FAIL: round run tripped the guard:"; cat "$WORK/round.out"; fail=1
fi

# --- 3. superset gate ----------------------------------------------------
m2a_legacy_gate "$RP" "$WORK"
[ "$gate_fail" = 0 ] || fail=1
MAME_ROMPATH="$RP" "$REPO/tools/run_replay_mame.sh" vsavj \
    "$REPO/tests/replays/11_pick_donovan.rpl" "$WORK/pick.log" "$WORK/pickbox2"
if m2a_diverge "$WORK/pick.log" 11_pick_donovan "$PICK_DIVERGE" > /dev/null; then
    echo "  ok: pick replay diverges exactly at $PICK_DIVERGE"
else
    echo "FAIL: pick divergence moved:"
    m2a_diverge "$WORK/pick.log" 11_pick_donovan "$PICK_DIVERGE" || true
    fail=1
fi

[ "$fail" = 0 ] && echo "PASS: stage 3 Donovan anim engaged, idle-coherent" \
    || { echo "SUITE RED"; exit 1; }
