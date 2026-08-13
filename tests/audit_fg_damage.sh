#!/bin/sh
# audit_fg_damage.sh — Phobos' EX Final Guardian (623+2K) damage on the
# merged build, FROZEN at the measured KNOWN-OPEN value (14z-85e).
# On-demand, ~5 min (2 MAME runs).
#
# THE ITEM THIS LOCKS (maintainer field report, 14z-85e): FG connects as
# a multi-hit but deals 1-2 HP/tick, ~10 of 288 total — while native VS2
# deals "quite a lot". MEASURED SAME SESSION: the port is BYTE-FAITHFUL
# (hitbox_proj record identical to vs2; base power byte (8,A3) = 2 in
# BOTH games), so the divergence is the per-game SCALER (damage-class
# tables) or native hit-count — STATE 14z-85e has the pipeline PCs.
# This audit freezes the CURRENT behavior so any change is loud in both
# directions: a regression (damage drops/EX stops firing) and the FIX
# (damage rises → re-freeze to the vs2-matched number, deliberately).
#
# VERDICT LIVENESS (the 14z-85e downgrade trap, maintainer-flagged): the
# EX costs a meter stock — a run where $FF8509 never decrements measured
# a WHIFF or a meterless downgraded DP, not the EX, and proves nothing.
# The stock decrement is asserted per leg before any damage verdict.
#
# Fighter structs are $FF8400 (P1) / $FF8800 (P2): HP at +0x50, char id
# at +0x382 — the first 14z-85e rig dumped $FF8BD0 (id-address + 0x4E)
# and read zeros; the struct BASE is not the id address (ram.md).
#
# Usage: ROMDIR=... tests/audit_fg_damage.sh [merged builddir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/m3b_merged}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;3000:ff8509:03;3020:ff8509:03"
DF=$(python3 -c "print(';'.join(f'{f}:ff8850-ff8853;{f}:ff8509-ff850a' for f in range(2900,4500,4)))")
for leg in fgA:71_hui_ex_fg fgC:73_hui_ex_fg_close; do
    name="${leg%%:*}"; rp="${leg#*:}"
    d="$W/$name"; mkdir -p "$d"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" POKES="$PK" \
      REPLAY="$REPO/tests/replays/hui/$rp.rpl" DUMPS="$DF" FRAMES=4520 \
      CHECKSUM_OUT="$d/c.ram" \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/out" 2>&1 ) &
done
wait

python3 - "$W" <<'PY' || fail=1
import glob, sys
W = sys.argv[1]
# FROZEN KNOWN-OPEN (14z-85e): total P2 damage in the window per leg.
# When the scaler fix ships, re-freeze to the vs2-matched number —
# deliberately, with the vs2 reference measurement beside it.
EXPECT = {"fgA": 10, "fgC": 10}
errs = []
for leg, want in EXPECT.items():
    hp, stock = [], []
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ff8850.bin"),
                    key=lambda p: int(p.split("_")[-2])):
        b = open(f, "rb").read()
        hp.append((b[0] << 8) | b[1])
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ff8509.bin"),
                    key=lambda p: int(p.split("_")[-2])):
        stock.append(open(f, "rb").read()[0])
    live = [h for h in hp if h]
    if not live:
        errs.append(f"{leg}: match never live (P2 HP always 0) — dead rig")
        continue
    if not stock or max(stock) < 3:
        errs.append(f"{leg}: meter pokes did not land (max stock "
                    f"{max(stock) if stock else '-'}) — verdict vacuous")
        continue
    if min(stock) >= max(stock):
        errs.append(f"{leg}: NO stock decrement — the EX never fired "
                    "(whiff or meterless downgrade); this run proves "
                    "nothing about FG damage")
        continue
    dmg = live[0] - min(live)
    if dmg != want:
        errs.append(f"{leg}: FG dealt {dmg} HP, frozen known-open is "
                    f"{want} — if this is the scaler fix landing, "
                    "re-freeze WITH the vs2 reference measurement; "
                    "anything else, investigate")
    else:
        print(f"  ok: {leg} — EX fired (stock {max(stock)}->{min(stock)}), "
              f"damage {dmg} HP (the frozen known-open value)")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: FG damage audit"; exit 1; }
echo "PASS: Final Guardian fires as the real EX and deals the frozen"
echo "      known-open damage (10 HP) on both rigs — the 14z-85e parity"
echo "      item is UNCHANGED (fix pending, STATE 14z-85e)"
