#!/bin/sh
# test_m2a_flavor_selector.sh — the Start-hold flavor selector (stage 5).
#
# WHAT: holding your own Start through select confirm and match load selects the other
#   game's flavour of Donovan: the per-player latch (+0x3C2) reads 01 plain (VS2), 00 with
#   P1 Start held (VH2), and P2's Start leaves P1's latch alone.
# HOW: replay 17 on MAME three ways (plain, P1 Start held, P2 Start held) with both players'
#   latches read from dumps after char-init.
# EXPECTS: 01 / 00 / 01 for P1 and 00 for P2 in every run; a red is the init shim reading
#   the wrong Start bit or seeding the wrong struct.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/jobs.sh tests/lua/replay.lua
#   tests/replays/17_don_oracle_vsavj.rpl tools/build_donovan.sh tools/run_mame.sh
#   tools/setup_mame.sh
#
# SHEET: none — runs our build only, judged on its own; no reference leg and no frozen reference values
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
# Usage: ROMDIR=... [JOBS=N] tests/test_m2a_flavor_selector.sh [rompath_dir]
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

# JOBS (#334 item 2, 14z-211): the three runs are independent, so they go through tests/lib/jobs.sh's pool, JOBS at a
# time; default min(4, CPUs/6). Each run now writes its own folder $WORK/run_<label> (checksum log, the dumps beside it,
# its exit status) where all three used to share $WORK/c.log and the same dump names; the checks read them after, in
# the order they always ran, and a run that failed stops the gate there as set -e did.
. "$REPO/tests/lib/jobs.sh"; vs_jobs JOBS 4 6
one_run() { # $1=replay $2=label
    mkdir -p "$WORK/run_$2"; _rc=0
    DUMPS="2380:ff87c2-ff87c3;2380:ff8bc2-ff8bc3" REPLAY="$1" \
        CHECKSUM_OUT="$WORK/run_$2/c.log" MAME_SANDBOX="$WORK/box_$2" \
        MAME_ROMPATH="$RPDIR;$ROMDIR" "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1 || _rc=$?
    echo "$_rc" > "$WORK/run_$2/rc"
}
check() { # $1=want_p1 $2=label
    _rc="$(cat "$WORK/run_$2/rc" 2>/dev/null || echo 1)"; [ "$_rc" = 0 ] || exit "$_rc"
    p1=$(xxd -p "$WORK/run_$2/dump_2380_ff87c2.bin" | cut -c1-2)
    p2=$(xxd -p "$WORK/run_$2/dump_2380_ff8bc2.bin" | cut -c1-2)
    rm -f "$WORK/run_$2"/dump_*.bin
    if [ "$p1" = "$1" ] && [ "$p2" = "00" ]; then
        echo "  ok: $2 -> P1 latch $p1, P2 latch $p2"
    else
        echo "FAIL: $2 -> P1 latch $p1 (want $1), P2 latch $p2 (want 00)"
        fail=1
    fi
}

vs_pool_start "$JOBS"
vs_pool_run one_run "$BASE" plain
vs_pool_run one_run "$WORK/hold_p1.rpl" p1-held
vs_pool_run one_run "$WORK/hold_p2.rpl" p2-held
vs_pool_wait
check 01 plain
check 00 p1-held
check 01 p2-held

[ "$fail" = 0 ] && echo "PASS: Start-hold flavor selector" \
    || { echo "FAIL: Start-hold flavor selector"; exit 1; }
