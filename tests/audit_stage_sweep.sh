#!/bin/sh
# audit_stage_sweep.sh — EVERY TENANT ON EVERY STAGE (14z-104, the §4
# "each stage" cell — no stage sweep existed anywhere before this).
#
# Stage selection is the $FF8100 word (the ladder/venue index,
# engine_internals "the stage-name banner" section: 12 stages, values
# 0x00..0x16 even; the twelve are identical at identical values across
# the games). In the 2P flow the selector writes it between f2050 and
# f2150, and the venue ASSETS load from it before ~f2450 — measured
# 14z-104: a poke at f2150/f2250 both sticks AND recolors the stage
# palette block at $90C2C0, while f2450+ sticks without the venue
# following. So the audit pokes at 2150+2200 and the match that follows
# is genuinely FOUGHT on the poked venue.
#
# WHAT IT ASSERTS, per (tenant x stage) leg — rig judge/02_throw.rpl,
# so every venue sees real CONTACT, not just a load:
#   1. the stage word reads back as the poked value at match time
#      (f3000) — the poke landed after the selector and stuck;
#   2. the match is LIVE (P2 HP 0x120 at f3000) and the throw CONNECTS
#      (P2 damaged) on that venue;
#   3. the run completes (a crash/reset kills the leg's samples).
# Plus two sweep-level checks: the no-poke control reads the default
# venue (0x0E), and the sweep must produce >= 8 DISTINCT stage-palette
# blocks across the 12 stages — proving the poke is load-bearing on the
# ASSET side, not only on the readback (palettes are compared for
# distinctness, never frozen).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged23] [JOBS=6]
#        tests/audit_stage_sweep.sh          (~37 legs, ~6 min at JOBS=6)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged23}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
JOBS="${JOBS:-6}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
RPL="$REPO/tests/replays/judge/02_throw.rpl"

run_leg() {  # name  p1id  stage-hex-or-empty
    n="$1"; id="$2"; st="$3"
    d="$W/$n"; mkdir -p "$d/sb"
    PK="1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
    [ -n "$st" ] && PK="$PK;2150:ff8100:00$st;2200:ff8100:00$st"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$RPL" POKES="$PK" \
      DUMPS="3000:ff8100-ff8101;3000:90c2c0-90c2ff;3000:ff8850-ff8851;3200:ff8850-ff8851" \
      FRAMES=3250 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/out" 2>&1 ) &
}

STAGES="00 02 04 06 08 0a 0c 0e 10 12 14 16"
i=0
for t in 13:don 10:hui 11:pyr; do
    id="${t%%:*}"; tn="${t#*:}"
    for st in $STAGES; do
        run_leg "${tn}_$st" "$id" "$st"
        i=$((i+1)); [ $((i % JOBS)) -eq 0 ] && wait
    done
done
run_leg nopoke 13 ""
wait

python3 - "$W" <<'PY' || { echo "FAIL: stage sweep"; exit 1; }
import binascii, sys
W = sys.argv[1]
STAGES = ["00","02","04","06","08","0a","0c","0e","10","12","14","16"]
errs = []
pals = {}
def rd(d, name):
    try:
        return open(f"{W}/{d}/{name}", "rb").read()
    except FileNotFoundError:
        return None
for tn in ("don", "hui", "pyr"):
    for st in STAGES:
        d = f"{tn}_{st}"
        sw = rd(d, "dump_3000_ff8100.bin")
        hp0 = rd(d, "dump_3000_ff8850.bin")
        hp1 = rd(d, "dump_3200_ff8850.bin")
        pal = rd(d, "dump_3000_90c2c0.bin")
        if None in (sw, hp0, hp1, pal):
            errs.append(f"{d}: dumps missing — the leg died (crash?)"); continue
        v = int.from_bytes(sw, "big")
        if v != int(st, 16):
            errs.append(f"{d}: stage word {v:#06x}, poked {int(st,16):#04x} "
                        "— the poke did not hold"); continue
        if int.from_bytes(hp0, "big") != 0x120:
            errs.append(f"{d}: match not live at f3000"); continue
        if int.from_bytes(hp1, "big") >= 0x120:
            errs.append(f"{d}: the throw never connected on this venue")
            continue
        pals.setdefault(st, set()).add(binascii.hexlify(pal))
ok = 36 - len(errs)
print(f"  {ok}/36 tenant-x-stage legs: stage held, match live, contact made")
# the no-poke control
sw = rd("nopoke", "dump_3000_ff8100.bin")
if sw is None or int.from_bytes(sw, "big") != 0x0E:
    errs.append("nopoke control: default venue is not 0x0e — the readback "
                "check is not measuring the selector")
else:
    print("  ok: no-poke control reads the default venue 0x0e")
distinct = len({p for s in pals.values() for p in s})
if distinct < 8:
    errs.append(f"only {distinct} distinct stage palettes across the sweep "
                "— the poke is not load-bearing on the asset side")
else:
    print(f"  ok: {distinct} distinct stage-palette blocks across 12 stages")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: every tenant fights (with contact) on every one of the 12"
echo "      stages; the poke is load-bearing and the control holds"
