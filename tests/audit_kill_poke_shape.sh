#!/bin/sh
# audit_kill_poke_shape.sh — A 2-BYTE HP KILL POKE MANUFACTURES #103's
# UNJUDGEABLE STATE ON ANY CHARACTER (14z-98). On-demand, ~7 min
# (2 MAME runs, parallel). GROUND TRUTH FOR RIG AUTHORS, frozen both ways.
#
# THE ENGINE PROPERTY (engine_internals "THE ROUND JUDGE"): the round
# judge kills on THE SIGN OF WHITE HP (+0x52), and the damage pipeline
# keeps white <= hp so white crosses zero first. A poke that writes ONLY
# the 2-byte hp word (`f:ff8450:0001`) leaves white at ~288; the next
# real hit underflows hp while white stays positive — a state no engine
# path can produce and no engine path can ever JUDGE. Measured on a
# pure-LEGACY leg (Victor, merged-m3): the 2-byte shape stalls the round
# UNRESOLVED >= 8760 frames (phase pinned at 6, the #103 failsafe shape);
# the 4-byte shape (`f:ff8450:00010001`, hp AND white — the
# test_don_column idiom) flows in ~600 frames through the healthy kill
# commit. This is vanilla engine behavior reached by instrument, NOT a
# build defect — which is exactly why it is dangerous: a rig using the
# 2-byte shape reads its own poke as a #103 reproduction.
#
# WHAT THIS RETRACTED (recorded 14z-98, GitHub #103 — and SETTLED the
# same day by the maintainer's no-poke MAME retest): the 14z-97 (7)
# continue rig produced "#103 instance 2" (Phobos KO'd by Bishamon)
# with "HP set to 1 at round start" pokes whose byte-width was never
# committed. Instance 2 is CLOSED AS THIS ARTIFACT: the retest showed
# real tenant losses judge (14z-98 (5)), on top of his natural
# early-round losses (14z-97 (7)), his near-death commits firing
# healthily (14z-98 tap), his x026142 escapes being FIXED, and the
# maintainer's earlier real no-poke Bishamon loss reaching the continue
# screen. Donovan's #103 was UNAFFECTED: zero-poke repro (trigger
# refined 14z-98 (5): the hp:=1 pin must fire in the round first).
#
# THE RULE THIS GATE ENFORCES BY EXISTING: kill/heal pokes write BOTH
# words — `frame:ff8450:00010001` (P1) / `frame:ff8850:00010001` (P2).
#
# Both verdicts are FROZEN: the 2-byte leg must stall (if it ever flows,
# the judge stopped reading white — an engine-behavior change worth a
# full stop) and the 4-byte leg must flow (if it stalls, the kill commit
# broke). A NO-KO on either leg is a dead rig, not a pass.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged11]
#        tests/audit_kill_poke_shape.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged17}"  # re-pointed 14z-113 (merged-m10: one-zip repackaging of merged-m9, same program)
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

RPL="$W/marathon_head.rpl"
awk -F'[- ]' '/^[0-9]/ { if ($1 + 0 > 12000) exit } { print }' \
    "$REPO/tests/replays/26_don_arcade_mash.rpl" > "$RPL"

DF="$(python3 -c "print(';'.join(f'{f}:ff8000-ff8180;{f}:ff8450-ff8456' for f in range(2900,12000,40)))")"

run_leg() { # tag hpspec
    d="$W/$1"; mkdir -p "$d/sbx"
    # Victor forced (a pure-legacy leg: the property under test is the
    # ENGINE's, so no ported byte may be in the path); kill pokes at
    # round-1 start +100f, three 20f apart, hands off (14z-97b shape).
    ( cd "$d" && POKES="1704:ff8782:03;1760:ff8782:03;1900:ff8782:03;2100:ff8782:03;2400:ff8782:03;3000:ff8450:$2;3020:ff8450:$2;3040:ff8450:$2" \
      DUMPS="$DF" REPLAY="$RPL" CHECKSUM_OUT="$d/out.log" MAME_SANDBOX="$d/sbx" \
      MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" FRAMES=12000 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/mame.log" 2>&1 ) &
}
run_leg hponly 0001
run_leg both   00010001
wait

classify() { # dir -> FLOWED n | STALL n | UNRESOLVED n | NO-KO
    python3 - "$1" <<'PY'
import glob, struct, re, sys
d = sys.argv[1]
frames = sorted(int(re.search(r'dump_(\d+)_ff8450', f).group(1))
                for f in glob.glob(f"{d}/dump_*_ff8450.bin"))
if not frames: print("NO-DATA"); sys.exit(0)
ko = kost = res = None
for f in frames:
    hp = struct.unpack(">H", open(f"{d}/dump_{f}_ff8450.bin","rb").read()[:2])[0]
    g = open(f"{d}/dump_{f}_ff8000.bin","rb").read()
    stage = struct.unpack(">H", g[0x100:0x102])[0]
    if hp > 60000 and ko is None: ko, kost = f, stage
    if ko and res is None and stage != kost: res = f
if ko is None: print("NO-KO")
elif res is None: print(f"UNRESOLVED {frames[-1]-ko}")
else: print(f"{'STALL' if res-ko >= 3000 else 'FLOWED'} {res-ko}")
PY
}

A="$(classify "$W/hponly")"; echo "== 2-byte poke (hp only):  $A"
B="$(classify "$W/both")";   echo "== 4-byte poke (hp+white): $B"

case "$A" in
STALL*|UNRESOLVED*) echo "  ok: the 2-byte shape manufactures the unjudgeable state (frozen)" ;;
NO-KO) echo "FAIL: 2-byte leg produced no KO — the rig did not make the event"; fail=1 ;;
*) echo "FAIL: the 2-byte leg FLOWED ($A) — the judge no longer reads white's"
   echo "      sign alone; engine_internals \"THE ROUND JUDGE\" needs re-derivation"
   fail=1 ;;
esac
case "$B" in
FLOWED*) echo "  ok: the 4-byte idiom flows through the healthy kill commit (frozen)" ;;
NO-KO) echo "FAIL: 4-byte leg produced no KO — the rig did not make the event"; fail=1 ;;
*) echo "FAIL: the 4-byte leg did not flow ($B) — the kill commit broke"; fail=1 ;;
esac

[ "$fail" = 0 ] && echo "AUDIT PASS (both poke shapes behave as frozen)" \
    || { echo "AUDIT FAIL"; exit 1; }
