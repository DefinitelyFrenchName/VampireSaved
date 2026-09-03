#!/bin/sh
# test_pyron_soak.sh — the Pyron STAGE-6 chaos soak (14z-67 as stage 4;
# MOVED TO STAGE 6 at 14z-129, maintainer-approved). The full behavioral
# chain, guarded, on the real packed set: builds stage 6, forces id 0x11
# through the vanilla select flow,
# then runs the input-chaos soak (tests/replays/pyron/70_pyron_mash.rpl
# — QCF/QCB/DP/charges/pairs, the Donovan-21 shape) for 11000 frames
# across round transitions. Expects:
#   1. guard CLEAN end-to-end;
#   2. his satellite alive in round 2 (+0x2A = $D4xx at f6000 —
#      MEASURED on the first clean soak; P links ONE satellite where
#      H links two pods);
#   3. run on the set the build actually packed.
#
# WHY STAGE 6, MEASURED 14z-129 (it was RED in the 14z-128 sweep at stage 4,
# CRASH 3020 vec4 PC 000000, and the crash was the GATE's premise, not the
# port). STAGE 5 IS THE SELECT PLUMBING — the `aux_poke` rows that make a
# tenant id reachable. A stage-4 build has Pyron's data, art, code and hooks
# but nothing that makes id 0x11 loadable, so forcing it lands on an
# unpopulated pointer. Three legs on ONE stage-4 build (a01c586a, bit-identical
# to the sweep's) separate it completely:
#     pokes id 0x11 (Pyron)   -> CRASH 3020
#     no pokes                -> END 11017 clean
#     pokes id 0x03 (Victor)  -> END 11017 clean
#     the SAME rig at stage 6 -> END 11017 clean
# So it is neither the poke schedule nor the build's health. It worked at
# 14z-67 because the id space was different; the select flow has changed three
# times since (the 14z-115 wheel separation among them).
#
# AND MOVING IT CLOSES A RECORDED COVERAGE GAP, which is the better reason.
# STATE_HISTORY names this gate's stage choice as HALF OF WHY the f7997
# type-64 crash escaped: "test_pyron_soak.sh builds STAGE 4, not the frozen
# stage-6 artifact — the only gate running 70_mash never ran it on pyron-m2."
# Stage 6 is what ships. No stage-4 coverage is lost: test_pyron_ladder.sh
# builds and checks stages 1-4 AND 6 with the op invariants and the legacy
# bit-identity legs.
# NOTHING WAS RE-FROZEN TO GET HERE — the round-2 satellite expectation is
# unchanged and was re-measured on the stage-6 run (+0x28 window = 0000d480,
# still 0000d4xx).
#
# The three crashes this soak found and the arc fixed (STATE 14z-67):
# the pod-zone data_in_code table (bite #4 of the class), the shared
# zones' pcrel escapes + queue remap + obj_hook union, and the
# satellite handler family roots (types 64-75 — proven SHARED when P's
# first spawn tripped type 64's tripwire).
#
# Usage: ROMDIR=... tests/test_pyron_soak.sh
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== stage-6 build"
TENANT_MANIFEST=build/manifest/pyron.toml TENANT_CHAR=0x11 \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 "$WORK/pyr6" > "$WORK/build.log" 2>&1 \
    || { tail -15 "$WORK/build.log"; echo "FAIL: build"; exit 1; }
echo "  ok: built ($(grep '^build fingerprint' "$WORK/build.log" | cut -d' ' -f3 | cut -c1-8))"

SET=vsavj
[ -f "$WORK/pyr6/rompath/vsavjw.zip" ] && SET=vsavjw

# Stage 6 packs a WIDE romset, and only the profile-carrying MAME knows
# `vsavjw`. A stock binary exits "Unknown system" before the machine runs,
# which the crash guard reports as a trip — i.e. as a crash in the build
# ([CPE-40]). That is exactly how test_pyron_ladder went red in the 14z-128
# sweep. Release-scope gates FAIL on a missing prerequisite rather than
# self-skip (STATE "RELEASE-TIME TEST SCOPE").
if [ "$SET" = vsavjw ]; then
    MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
    [ -x "$MAME_BIN" ] || { echo "FAIL: no WIDE MAME binary at $MAME_BIN"; \
        echo "      build it: tools/setup_mame.sh"; exit 1; }
    export MAME_BIN
fi

echo "== guarded 11000-frame chaos soak"
if ! POKES="1704:ff8782:11;1760:ff8782:11;1900:ff8782:11;2100:ff8782:11;2400:ff8782:11" \
   DUMPS="6000:ff8428-ff8430" \
   MAME_ROMPATH="$WORK/pyr6/rompath;$ROMDIR" \
   tools/run_replay_guarded.sh "$SET" tests/replays/pyron/70_pyron_mash.rpl \
       "$WORK/soak.log" "$WORK/soakbox" > "$WORK/soak.out" 2>&1; then
    echo "FAIL: guard tripped:"
    grep -m2 -E "CRASH|REGS" "$WORK/soak.log" || tail -5 "$WORK/soak.out"
    exit 1
fi
grep -q "^END 11017" "$WORK/soak.log" || { echo "FAIL: soak ended early"; exit 1; }
echo "  ok: clean through 11000 frames"

SAT="$(xxd -p "$WORK/dump_6000_ff8428.bin" 2>/dev/null | cut -c1-8)"
case "$SAT" in
    0000d4*) echo "  ok: round-2 satellite alive (+0x2A window $SAT)" ;;
    *)       echo "FAIL: round-2 satellite state drifted (+0x28 window = $SAT, want 0000d4xx)"; exit 1 ;;
esac

echo "PASS: Pyron stage-6 soak (guard clean, satellite live across rounds)"
