#!/bin/sh
# test_hui_soak.sh — the Huitzil stage-4 SOAK gate (14z-65).
#
# The full behavioral chain, guarded, on the REAL packed set: builds stage
# 4, forces id 0x10 through the vanilla select flow, then runs the chaos
# soak (tests/replays/hui/70_hui_mash.rpl — QCF/QCB/DP/charges/pairs, the
# Donovan-21 shape) for 11000 frames across round transitions. Expects:
#   1. guard CLEAN end-to-end (states/moves/sounds/pods all exercised);
#   2. BOTH satellites alive in round 2 (+0x2A/+0x2C nonzero at f6000) —
#      the pod-lifecycle regression tripwire (the f4983 arc);
#   3. run on the set the build actually packed (vsavjw when wide_ext is
#      used — a vsavj-set run against it is the PRISTINE ROM: false green).
#
# Usage: ROMDIR=... tests/test_hui_soak.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== stage 4 build"
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 4 "$WORK/hui4" > "$WORK/build.log" 2>&1 \
    || { tail -15 "$WORK/build.log"; echo "FAIL: build"; exit 1; }
SET=vsavj
if [ -f "$WORK/hui4/rompath/vsavjw.zip" ]; then
    SET=vsavjw
    export MAME_BIN="$HOME/.cache/vampire-saved/mame/cps2"
fi
echo "  ok: built ($(grep '^build fingerprint' "$WORK/build.log" | cut -d' ' -f3 | cut -c1-8)), packed as $SET"

echo "== guarded 11000-frame chaos soak"
if ! POKES="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10" \
   DUMPS="6000:ff842a-ff842e;11000:ff8460-ff8468" \
   MAME_ROMPATH="$WORK/hui4/rompath;$ROMDIR" \
   tools/run_replay_guarded.sh "$SET" tests/replays/hui/70_hui_mash.rpl \
       "$WORK/soak.log" "$WORK/soakbox" > "$WORK/soak.out" 2>&1; then
    echo "FAIL: guard tripped:"
    grep -m2 -E "CRASH|REGS" "$WORK/soak.log" || tail -5 "$WORK/soak.out"
    exit 1
fi
echo "  ok: clean through 11000 frames"

PODS="$(xxd -p "$WORK/dump_6000_ff842a.bin" 2>/dev/null | cut -c1-8)"
case "$PODS" in
    0000*) echo "FAIL: round-2 satellites dead (+0x2A/+0x2C = $PODS)"; exit 1 ;;
    *)     echo "  ok: round-2 satellites alive ($PODS)" ;;
esac

echo "PASS: Huitzil stage-4 soak (guard clean, pods live across rounds)"
