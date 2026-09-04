#!/bin/sh
# test_m2a_flavor_selector.sh — the Start-hold flavor selector (stage 5).
#
# Community-confirmed protocol (docs/game/atlas/character_tables.md): holding
# YOUR Start through select confirm and match load selects the other
# game's flavor of Donovan (VS2 default = latch 01; held = VH2 = 00).
# The init shim reads the per-player Start bitmask ($FF8060, bit=player,
# measured live through char-init) and seeds the player-struct latch
# (+0x3C2), which Donovan's QCB+K handler + projectile consume.
#
# Locks: on 17_don_oracle_vsavj (P1 Donovan, P2 Victor):
#   plain          -> P1 latch 01 (VS2 default)
#   P1 Start held  -> P1 latch 00 (VH2)
#   P2 Start held  -> P1 latch 01 (per-player isolation)
# P2's latch stays 00 in all runs (shim runs only on slot-0x0F init).
#
# Usage: ROMDIR=... tests/test_m2a_flavor_selector.sh [rompath_dir]
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
RPDIR="${1:-$REPO/build/donovan5/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR — run tools/build_donovan.sh 5 first"; exit 1; }
RPDIR="$(cd "$RPDIR" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"
fail=0

BASE="$REPO/tests/replays/17_don_oracle_vsavj.rpl"
mk_hold() { # $1=out $2=sys-token
    python3 - "$BASE" "$1" "$2" <<'PY'
import sys
src = open(sys.argv[1]).read().splitlines()
out = []
for l in src:
    out.append(l)
    if l.startswith('1300-1302'):
        out.append(f'1290-2700 sys={sys.argv[3]}')
open(sys.argv[2], 'w').write('\n'.join(out) + '\n')
PY
}
mk_hold "$WORK/hold_p1.rpl" S1
mk_hold "$WORK/hold_p2.rpl" S2

check() { # $1=replay $2=want_p1 $3=label
    DUMPS="2380:ff87c2-ff87c3;2380:ff8bc2-ff8bc3" REPLAY="$1" \
        CHECKSUM_OUT="$WORK/c.log" MAME_SANDBOX="$WORK/box_$3" \
        MAME_ROMPATH="$RPDIR;$ROMDIR" "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
    p1=$(xxd -p "$WORK/dump_2380_ff87c2.bin" | cut -c1-2)
    p2=$(xxd -p "$WORK/dump_2380_ff8bc2.bin" | cut -c1-2)
    rm -f "$WORK"/dump_*.bin
    if [ "$p1" = "$2" ] && [ "$p2" = "00" ]; then
        echo "  ok: $3 -> P1 latch $p1, P2 latch $p2"
    else
        echo "FAIL: $3 -> P1 latch $p1 (want $2), P2 latch $p2 (want 00)"
        fail=1
    fi
}

check "$BASE" 01 plain
check "$WORK/hold_p1.rpl" 00 p1-held
check "$WORK/hold_p2.rpl" 01 p2-held

[ "$fail" = 0 ] && echo "PASS: Start-hold flavor selector" \
    || { echo "FAIL: Start-hold flavor selector"; exit 1; }
