#!/bin/sh
# test_pyron_soak.sh — the Pyron stage-4 chaos soak (14z-67, the moveset
# arc opener). The full behavioral chain, guarded, on the real packed
# set: builds stage 4, forces id 0x11 through the vanilla select flow,
# then runs the input-chaos soak (tests/replays/pyron/70_pyron_mash.rpl
# — QCF/QCB/DP/charges/pairs, the Donovan-21 shape) for 11000 frames
# across round transitions. Expects:
#   1. guard CLEAN end-to-end;
#   2. his satellite alive in round 2 (+0x2A = $D4xx at f6000 —
#      MEASURED on the first clean soak; P links ONE satellite where
#      H links two pods);
#   3. run on the set the build actually packed.
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

echo "== stage-4 build"
TENANT_MANIFEST=build/manifest/pyron.toml TENANT_CHAR=0x11 \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 4 "$WORK/pyr4" > "$WORK/build.log" 2>&1 \
    || { tail -15 "$WORK/build.log"; echo "FAIL: build"; exit 1; }
echo "  ok: built ($(grep '^build fingerprint' "$WORK/build.log" | cut -d' ' -f3 | cut -c1-8))"

SET=vsavj
[ -f "$WORK/pyr4/rompath/vsavjw.zip" ] && SET=vsavjw

echo "== guarded 11000-frame chaos soak"
if ! POKES="1704:ff8782:11;1760:ff8782:11;1900:ff8782:11;2100:ff8782:11;2400:ff8782:11" \
   DUMPS="6000:ff8428-ff8430" \
   MAME_ROMPATH="$WORK/pyr4/rompath;$ROMDIR" \
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

echo "PASS: Pyron stage-4 soak (guard clean, satellite live across rounds)"
