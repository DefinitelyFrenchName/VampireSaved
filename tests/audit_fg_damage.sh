#!/bin/sh
# audit_fg_damage.sh — Phobos' EX Final Guardian (623+2K) damage on the
# merged build vs a CPU opponent, FROZEN at the measured value.
# On-demand, ~5 min (2 MAME runs).
#
# STATUS (14z-85f): the 14z-85e parity item this was filed against is
# CLOSED — the divergence was NEVER the scaler (all scaler tables are
# byte-equivalent between the games) but the ported object-hit damage
# applier staging into vs2's A5 work vars, which vsavj never reads
# (same-value class #4; fixed by the six x028122 port_patch rows,
# huitzil-m8/pyron-m5). THE PARITY GATE IS tests/audit_fg_parity.sh
# (native A/B on the frozen staircase). This audit's own 10 HP was
# measured UNCHANGED by the fix: on these CPU-opponent rigs the ticks
# that landed were FIGHTER-path contacts (legitimately staged all
# along); the broken object-path ticks never connected here. The 10
# therefore stays frozen as a plain regression lock on these rigs —
# it is NOT the parity number and never was.
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
# FROZEN (14z-85e, re-verified UNCHANGED on the fixed build 14z-85f):
# total P2 damage per leg — fighter-path contact damage on these
# CPU-opponent rigs. The parity number lives in audit_fg_parity.sh.
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
        errs.append(f"{leg}: FG dealt {dmg} HP, frozen value is {want} "
                    "— regression on the fighter-path contacts these "
                    "rigs measure (the object-path parity gate is "
                    "audit_fg_parity.sh); investigate")
    else:
        print(f"  ok: {leg} — EX fired (stock {max(stock)}->{min(stock)}), "
              f"damage {dmg} HP (the frozen known-open value)")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: FG damage audit"; exit 1; }
echo "PASS: Final Guardian fires as the real EX and deals the frozen"
echo "      fighter-path damage (10 HP) on both CPU-opponent rigs —"
echo "      the parity gate is audit_fg_parity.sh (14z-85f)"
