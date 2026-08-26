#!/bin/sh
# audit_continue_switch.sh — THE #99 CONTINUE-WITH-SWITCH RIG, committed
# (the 14z-97 (7) doctrine debt, payable once #103 was fixed — paid at the
# 14z-99 post-freeze close, 2026-08-20).
#
# THE SCENARIO (#99, maintainer field report on merged-m2): a crash-reset at
# fight start of the 5th arcade match, Donovan vs CPU-Phobos, reached by
# continuing WITH A CHARACTER SWITCH after losing as Phobos. This rig
# reproduces the structural path on the shipping merged build:
#   coin-boosted marathon -> forced PHOBOS -> natural mash loss ->
#   continue -> FORCED SWITCH TO DONOVAN at the re-select window ->
#   the ladder plays on (in the measured trajectory: a second continue, a
#   mash switch to Pyron, and a TENANT-VS-TENANT CPU match at match 5) ->
#   guarded to the marathon's END at 40620.
#
# WHAT IT LOCKS (measured 2026-08-20 on merged-m4 = build/m3b_merged11,
# two identical guarded runs):
#   1. #99 regression lock: the guarded run ENDs at 40620 with ZERO
#      CRASH/PCWEEDS/SOFTRESET/END-CRASH lines, across two continues and
#      two character switches.
#   2. #103 lock on this path: the tenant's natural loss JUDGES — KO
#      (p1 hp < 0) resolves through mode 8 to a NEW match within 1600
#      frames. (This exact rig froze 9,500+ frames at that KO before the
#      14z-99 fix — 14z-97 (7).)
#   3. The switch lands: the post-continue match plays P1 = DONOVAN.
#   4. A tenant-vs-tenant CPU pairing occurs after a continue (both
#      fighter bases in tenant space) — the #99 context shape.
#   5. THE LITERAL #99 PAIRING: a post-continue match plays P1=DONOVAN
#      vs CPU-PHOBOS (f22420 in the frozen trajectory, match 4) — and
#      the run continues past it. The reported crash context, exercised
#      and clean.
#
# SELF-UPDATING BASES: fighter identity is checked via +0x60.l against the
# BUILD'S OWN hitbox-base table (PRG:0x0BD97A, atlas character_tables.md) —
# derived at runtime, not frozen, because tenant blocks RELOCATE between
# freezes (measured this session: phobos 0x4477b0 -> 0x4594a0 and pyron
# 0x49ab7c -> 0x4ac7dc across the 14z-99 window while donovan held; the
# stale bases.tsv rows were the #94 reference-rot class, fixed same
# commit). Tenant space test: base >= 0x300000 (wide_ext-relocated blocks;
# every legacy base is < 0x100000).
#
# the switch-poke window (f32040-32220; RE-MEASURED 14z-110 on merged14 by
#   the phase-1 recipe: forced Phobos WINS 3 — match 3 is naturally
#   Phobos-vs-CPU-DONOVAN — loses match 4 to Bishamon ~f31860; the
#   re-select opens ~f31940-32500, next match f32580. The old merged11
#   schedule was f16100-16280, loss at match 2) is frozen to THIS build's measured loss
# THIS build's measured loss trajectory (Phobos loses match 2 ~f15540, the
# re-select opens f16100). A future freeze can move the mash lottery; if
# assertion 3 then fails, RE-MEASURE the loss/re-select frames with the
# phase-1 mapping recipe (dumps only, no switch pokes) and re-freeze the
# schedule — do not widen the assertions.
#
# STEERING NOTE: $FF8114 index pokes do NOT select the opponent (measured:
# two poke sets at f16180-16415 gave bit-identical outcomes — but REMOVING
# them changed the downstream lottery, so the writes perturb state without
# steering). The committed poke-free trajectory happens to deliver the
# LITERAL #99 pairing at match 4 (Donovan vs CPU-Phobos, f22420) — frozen
# as assertion 5. If a future freeze's lottery loses it, either re-measure
# a trajectory that reaches the pairing or fall back to the read_tap.lua
# loader/consumer serialization named on issue #99.
#
# Kill pokes: NONE (audit_kill_poke_shape: a 2-byte HP poke manufactures
# the #103 stall shape by instrument; losses here are the mash's own).
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged11] tests/audit_continue_switch.sh
# ~18 min (one guarded 40,620-frame MAME marathon). On-demand.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged14}"  # re-pointed 14z-110: the schedule below is keyed to THIS build's measured trajectory
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
[ -f "$BUILD/prg/vm3j.04d" ] || { echo "SKIP: no prg/vm3j.04d in $BUILD (need the decoded member for the base table)"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

# Coin-boosted marathon, derived from the committed replay (one source).
RPL="$W/coin_marathon.rpl"
python3 - "$RPL" <<'PY'
import sys
lines = open("tests/replays/26_don_arcade_mash.rpl").read().splitlines(keepends=True)
out, done = [], False
for ln in lines:
    if not done and ln[:1].isdigit():
        out.append("100-105 sys=C1\n140-145 sys=C1\n180-185 sys=C1\n220-225 sys=C1\n")
        done = True
    out.append(ln)
open(sys.argv[1], "w").writelines(out)
PY

# Pokes: force PHOBOS (0x10) at the initial select; force DONOVAN (0x13)
# at the measured post-loss re-select window. No HP pokes.
PK="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10"
PK="$PK;32040:ff8782:13;32100:ff8782:13;32160:ff8782:13;32220:ff8782:13"
# 14z-110: the post-continue first draw is VENUE-STEERED to Phobos (venue
# 0x02 on Donovan's row; EVEN values only — game/gotchas.md), so assertion 5
# no longer depends on the lottery the 14z-100 freeze got lucky with.
PK="$PK;$(python3 -c "print(';'.join(f'{fr}:ff8121:02' for fr in range(32300,32560,40)))")"
DF="$(python3 -c "print(';'.join(f'{f}:ff8000-ff8180;{f}:ff8400-ff8470;{f}:ff8800-ff8870' for f in range(2500,40600,80)))")"

echo "== guarded marathon (Phobos -> loss -> continue -> switch to Donovan)"
rc=0
GUARD_DEBUG=0 POKES="$PK" DUMPS="$DF" \
  MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
  tools/run_replay_guarded.sh vsavjw "$RPL" "$W/out.log" "$W/sbx" \
  > "$W/guard.log" 2>&1 || rc=$?
if [ "$rc" != 0 ]; then
    echo "FAIL: guard tripped or run died (rc=$rc) — the #99 lock is RED"
    grep -E "^(CRASH|STACK|PCWEEDS|SOFTRESET|END-CRASH|INPUT-VIOLATION) " "$W/out.log" 2>/dev/null || tail -5 "$W/guard.log"
    exit 1
fi
grep -q "^END 40620" "$W/out.log" || { echo "FAIL: no END 40620"; exit 1; }
echo "   ok: END 40620, zero guard trips (assertion 1)"

python3 - "$W" "$BUILD" <<'PY'
import glob, re, struct, sys
d, build = sys.argv[1], sys.argv[2]

# The build's own hitbox-base table (PRG:0x0BD97A -> member 04d @ 0x3D97A,
# LE-word file order).
data = open(f"{build}/prg/vm3j.04d", "rb").read()
raw = data[0x3D97A:0x3D97A + 32*4]
sw = bytearray()
for i in range(0, len(raw), 2):
    sw += raw[i+1:i+2] + raw[i:i+1]
tbl = struct.unpack(">32I", bytes(sw))
PHOBOS, DONOVAN = tbl[0x10], tbl[0x13]
TEN = 0x300000

frames = sorted(int(re.search(r"dump_(\d+)_ff8000", f).group(1))
                for f in glob.glob(f"{d}/dump_*_ff8000.bin"))
rows = []
for f in frames:
    try:
        b0 = open(f"{d}/dump_{f}_ff8000.bin", "rb").read()
        b4 = open(f"{d}/dump_{f}_ff8400.bin", "rb").read()
        b8 = open(f"{d}/dump_{f}_ff8800.bin", "rb").read()
    except FileNotFoundError:
        continue
    rows.append((f,
        struct.unpack(">H", b0[0x004:0x006])[0],   # mode
        struct.unpack(">I", b4[0x60:0x64])[0],     # p1 base
        struct.unpack(">I", b8[0x60:0x64])[0],     # p2 base
        struct.unpack(">h", b4[0x50:0x52])[0]))    # p1 hp

# matches = runs of loaded fighters (both bases nonzero)
matches, cur = [], None
for f, mode, p1, p2, hp in rows:
    if p1 and p2:
        if cur is None or (p1, p2) != (cur[1], cur[2]):
            cur = [f, p1, p2]; matches.append(cur)
print("   matches (first-dump-frame, p1, p2):")
for f, p1, p2 in matches:
    tag = lambda b: "TENANT" if b >= TEN else "legacy"
    print(f"     f{f}: {p1:#x} ({tag(p1)}) vs {p2:#x} ({tag(p2)})")

fail = 0
# 2: a real loss (hp<0) that judges: mode 8 then a new match within 1600f
loss = next((f for f, m, p1, p2, hp in rows if hp < 0 and p1 >= TEN), None)
if loss is None:
    print("FAIL: no tenant KO loss observed (rig dead?)"); fail = 1
else:
    j = [f for f, m, p1, p2, hp in rows if f > loss and m == 8]
    nxt = [f for f, p1, p2 in matches if f > loss]
    if j and nxt and j[0] - loss <= 1600 and nxt[0] - loss <= 1600:
        print(f"   ok: tenant loss f{loss} JUDGED (mode 8 f{j[0]}, next match f{nxt[0]}) (assertion 2)")
    else:
        print(f"FAIL: loss f{loss} did not judge into a new match within 1600f (#103 shape)"); fail = 1
# 3: the forced switch landed — some match after the loss plays P1=Donovan
if loss is not None:
    post = [m for m in matches if m[0] > loss]
    if any(p1 == DONOVAN for _, p1, p2 in post):
        print("   ok: the switch landed — a post-continue match plays P1=DONOVAN (assertion 3)")
    else:
        print("FAIL: no post-continue match with P1=DONOVAN — the switch-poke window has drifted; re-measure (header)"); fail = 1
    # 4: tenant-vs-tenant CPU pairing after the continue
    if any(p1 >= TEN and p2 >= TEN for _, p1, p2 in post):
        print("   ok: tenant-vs-tenant CPU match after a continue (assertion 4)")
    else:
        print("FAIL: no tenant-vs-tenant pairing post-continue — trajectory moved; re-measure"); fail = 1
    # 5: THE LITERAL #99 PAIRING — Donovan vs CPU-Phobos post-continue
    if any(p1 == DONOVAN and p2 == PHOBOS for _, p1, p2 in post):
        print("   ok: THE LITERAL #99 PAIRING played — P1=Donovan vs CPU-Phobos post-continue (assertion 5)")
    else:
        print("FAIL: Donovan-vs-CPU-Phobos not reached — the frozen trajectory moved; re-measure (header)"); fail = 1
sys.exit(fail)
PY
echo "AUDIT PASS (#99 continue-with-switch path clean end to end)"
