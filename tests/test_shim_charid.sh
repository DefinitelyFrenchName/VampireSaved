#!/bin/sh
# test_shim_charid.sh — the init shim can identify WHICH tenant it is running
# for, because (0x382,A6) already holds the character id when it runs.
#
# WHY (M3b slice G, 14z-77). A merged build has ONE init shim serving N
# tenants, and each needs a different VS2/VH2 flavor byte. `flavor_tail()`
# therefore emits `cmpi.b #id,(0x382,A6)` per tenant — which is only correct
# if the player struct's id field is POPULATED at the moment the shim runs,
# at char-init, before the character handler.
#
# That was an ASSUMPTION when the code was written: strongly implied (the
# dispatch the shim is hosted on is itself id-indexed, and +0x382 is the id
# field of both player structs, docs/game/atlas/ram.md) but not measured at
# this point in the frame. A register dump alone cannot answer it and
# frame-level ordering is too coarse — both events are inside one frame — so
# `GUARD_PROBE_MEM` was added to replay_guard.lua to read memory AT THE HIT.
#
# Measured 14z-77 on donovan-m3a: A6=$FF8400 -> $FF8782 = 0x13 and
# A6=$FF8800 -> $FF8B82 = 0x13, on two independent 2P replays. BOTH player
# structs, because the chain must work for either.
#
# The rig needs the forced-pick pokes. Without them replay 11 never runs
# Donovan's char-init at all and this gate measures nothing while looking
# like it passed — which is exactly what happened first (CLAUDE.md: a
# negative result from a rig is a fact about the RIG until proven otherwise).
# Section 0 is that proof, on this instrument, every run.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/test_shim_charid.sh [build] [id]
#   build defaults to build/m5_wide, id to 0x13 (donovan-m3a).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"

BUILD="${1:-build/m5_wide}"
TID="${2:-13}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN

if [ ! -d "$BUILD/rompath" ] || [ ! -x "$MAME_BIN" ]; then
    echo "SKIP: need a build at $BUILD and the WIDE MAME binary at $MAME_BIN"
    echo "      (tools/setup_mame.sh; build dirs are untracked)"
    exit 0
fi

# The shim address is READ FROM THE BUILD, never hardcoded — it is allocated,
# so it moves whenever the space model does.
SHIM="$(sed -n 's/^code *0x0*\([0-9a-f]*\) init shim .*/\1/p' \
        "$BUILD/patch/patch_notes_fragment.md" | head -1)"
if [ -z "$SHIM" ]; then
    echo "SKIP: no 'init shim' line in $BUILD/patch/patch_notes_fragment.md"
    echo "      (a build below stage 5 has no shim to probe)"
    exit 0
fi
echo "  build $BUILD, tenant id 0x$TID, shim at PRG:0x$SHIM"

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
export MAME_ROMPATH="$PWD/$BUILD/rompath;$ROMDIR"
# Forced pick for BOTH sides: the cursor path lands on different characters
# on the two wheels, so hand-picking cannot be relied on (HANDOFF).
export POKES="1400:ff8782:$TID;1450:ff8782:$TID;1500:ff8782:$TID;\
1400:ff8b82:$TID;1450:ff8b82:$TID;1500:ff8b82:$TID"
fail=0

probe() {  # probe <addr> <memspec> <replay> -> log path on stdout
    GUARD_PROBE="$1" GUARD_PROBE_MEM="$2" \
    tools/run_replay_guarded.sh vsavjw "tests/replays/$3.rpl" \
        "$WORK/$1_$2_$3.log" "$WORK/box_$1_$2_$3" >/dev/null 2>&1 || true
    echo "$WORK/$1_$2_$3.log"
}

echo "== 0: the instrument arms (a real zero and a blind zero look alike) =="
L="$(probe 016c64 A6+382 03_two_player_vs)"
N="$(grep -c '^PROBE ' "$L" || true)"
if [ "${N:-0}" -gt 0 ]; then
    echo "  ok: the pool seeder 0x016c64 reports $N hits with MEM attached"
else
    echo "  FAIL: no hits at a known-executed address — the probe is blind,"
    echo "        so every zero below would be meaningless"
    exit 1
fi

echo "== 1: at the shim, (0x382,A6) already holds the tenant id =="
for R in 03_two_player_vs 16_xemu_2p; do
    L="$(probe "$SHIM" A6+382 "$R")"
    HITS="$(grep -c '^PROBE ' "$L" || true)"
    if [ "${HITS:-0}" -lt 2 ]; then
        echo "  FAIL: $R — $HITS shim hits, expected both player structs."
        echo "        The rig did not form the match; fix the rig, do not"
        echo "        read this as a fact about the engine."
        fail=1; continue
    fi
    BAD="$(grep '^PROBE ' "$L" | grep -vc "=$TID\$" || true)"
    P1="$(grep -c 'A6=00ff8400 .*=' "$L" || true)"
    P2="$(grep -c 'A6=00ff8800 .*=' "$L" || true)"
    if [ "${BAD:-0}" = 0 ] && [ "${P1:-0}" -ge 1 ] && [ "${P2:-0}" -ge 1 ]; then
        echo "  ok: $R — $HITS hits, every one reads 0x$TID; both structs"
        echo "      seen (P1 A6=\$FF8400, P2 A6=\$FF8800)"
    else
        echo "  FAIL: $R — $BAD hit(s) did not read 0x$TID (P1 $P1, P2 $P2)"
        grep '^PROBE ' "$L" | head -4
        fail=1
    fi
done

echo "== 2: verdict control — the id is at +0x382, not everywhere =="
# If some other offset in the struct also read the tenant id, section 1 would
# pass on a coincidence rather than on the field it names.
L="$(probe "$SHIM" A6+0 03_two_player_vs)"
if grep '^PROBE ' "$L" | grep -q "=$TID\$"; then
    echo "  FAIL: (0x000,A6) also reads 0x$TID — section 1 is not evidence"
    echo "        that +0x382 specifically carries the character id"
    fail=1
else
    echo "  ok: (0x000,A6) does not read 0x$TID, so +0x382 is doing the work"
fi

[ "$fail" = 0 ] || { echo "FAIL: init-shim char-id gate"; exit 1; }
echo "PASS: the init shim can identify its tenant — (0x382,A6) holds the"
echo "      character id at char-init, both player structs, 2 replays"
