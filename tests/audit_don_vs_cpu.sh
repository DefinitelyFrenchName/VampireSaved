#!/bin/sh
# audit_don_vs_cpu.sh — the DETERMINISTIC Donovan-vs-CPU-opponent gate
# (14z-110, GitHub #111). Closes the coverage gap #99 fell through: after the
# extended wheel grew, NO gate reached the Donovan-vs-CPU-Phobos pairing —
# 26_don_arcade_mash's U,U,R prologue lands on Jedah, and
# audit_continue_switch's frozen trajectory drifted off the pairing.
#
# HOW IT IS DETERMINISTIC. The arcade ladder's opponent draw is a
# sound-state-fed LOTTERY (atlas/ram.md, $FF8110) UNLESS the venue byte
# $FF8121 is pinned: the draw pool is rowA[venue..venue+7], so poking $FF8121
# before match 1's draw selects the opponent exactly (measured 14z-109, 12/12
# EVEN values; re-confirmed 14z-110: venue 0x02 loads P2=Phobos 0x4595B0 at
# match start). Donovan's ladder row (class 0x13): venue 0x02 -> Phobos,
# 0x10 -> Bishamon — the two FIELD crash contexts. See the EVEN-ONLY rule at
# venue_of below; Pyron is not steerable on this row. P1 Donovan is reached
# by 110_don_arcade_mash's L,L,D,D wheel path, not 26's U,U,R.
#
# WHAT IT ASSERTS: rig LIVENESS (P2's hitbox base at match start == the
# venue-selected opponent's base, from the BUILD's own table PRG:0x0BD97A — a
# wrong opponent is a DEAD leg, never a pass) and a guard-clean END on each leg.
#
# **THE #99 CRASH DOES NOT REPRODUCE HERE, AND THAT IS RECORDED, NOT HIDDEN.**
# Measured 14z-110: a full 40,620-frame Donovan-vs-Phobos marathon (venue 0x02)
# under the authoritative guard ran CLEAN to END 40620 — the P1-mash never
# drives Phobos's object to walk Donovan's bad node (#99 = node 0x3FB899, vs2
# state 0x51; the field crash needs the specific cross-fighter interaction the
# maintainer sees 100% on the CORE and this project measures ~0% on MAME rigs).
# So a clean pass here is COVERAGE, not proof the bug is absent — exactly the
# audit_continue_switch caveat. This gate's value is the deterministic pairing
# reachability; the #99 fix is verified elsewhere (fsm_census + the ported fix).
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged15] [FRAMES=40700]
#        [LEGS="phobos bishamon pyron"] tests/audit_don_vs_cpu.sh
# ~18 min per leg (one guarded marathon each). On-demand.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged15}"  # re-pointed 14z-110b
FRAMES="${FRAMES:-40700}"
LEGS="${LEGS:-phobos bishamon}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
[ -f "$BUILD/prg/vm3j.04d" ] || { echo "SKIP: no prg/vm3j.04d in $BUILD"; exit 0; }
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
[ -f "tests/replays/110_don_arcade_mash.rpl" ] || { echo "SKIP: no replay 110"; exit 0; }
export MAME_BIN

# leg -> venue byte (Donovan row 0x13 first-draw), for the report/assert.
# THE VENUE BYTE MUST BE EVEN (measured 14z-110): poking an ODD venue crashes
# the ladder pick itself — vec3 at PC 0x00AF46, fault ADDR 0x0000B72D, before
# any match exists. The 14z-109 sweep measured the twelve EVEN values only;
# vanilla writes only even venues. Donovan's row: 0x02 -> Phobos (his paired
# stage), 0x10 -> Bishamon-then-Phobos — exactly the two FIELD crash contexts.
# NO even venue on his row first-draws PYRON (0x11 sits at odd offsets only),
# so that pairing is NOT steerable here; it is covered by
# tests/replays/109_2p_don_vs_phobos.rpl's 2P family and the guard corpus'
# forced legs instead — stated, not hidden.
venue_of() { case "$1" in
    phobos) echo 02;; bishamon) echo 10;;
    *) echo "";; esac; }
# expected opponent character id (rowA[venue]) for the liveness assert
id_of() { case "$1" in phobos) echo 0x10;; bishamon) echo 0x08;; esac; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok()  { echo "  ok: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

for leg in $LEGS; do
    V="$(venue_of "$leg")"
    [ -n "$V" ] || { bad "unknown leg $leg"; continue; }
    echo "== leg: Donovan P1 vs CPU-$leg (venue 0x$V)"
    d="$W/$leg"; mkdir -p "$d/sbx"
    # force P1=Donovan at the wheel commit; steer the venue before match-1 draw;
    # dump P2's block at match start for the liveness check.
    PK="1704:ff8782:13;1760:ff8782:13;1900:ff8782:13;2100:ff8782:13;2400:ff8782:13"
    VP="$(python3 -c "print(';'.join(f'{f}:ff8121:$V' for f in range(1750,2860,20)))")"
    DF="$(python3 -c "print(';'.join(f'{f}:ff8800-ff8870' for f in range(2900,3400,20)))")"
    rc=0
    GUARD_DEBUG=1 POKES="$PK;$VP" DUMPS="$DF" \
      MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      tools/run_replay_guarded.sh vsavjw tests/replays/110_don_arcade_mash.rpl \
      "$d/out.log" "$d/sbx" > "$d/g.log" 2>&1 || rc=$?

    # liveness: P2 base at match start == the venue-selected opponent
    python3 - "$d" "$BUILD" "$(id_of "$leg")" "$leg" <<'PY' || fail=1
import glob, struct, sys
d, build, want_id, leg = sys.argv[1], sys.argv[2], int(sys.argv[3], 16), sys.argv[4]
data = open(f"{build}/prg/vm3j.04d", "rb").read()
raw = data[0x3D97A:0x3D97A + 32 * 4]
sw = bytearray()
for i in range(0, len(raw), 2):
    sw += raw[i + 1:i + 2] + raw[i:i + 1]
bases = [struct.unpack(">I", bytes(sw[4 * i:4 * i + 4]))[0] for i in range(32)]
want = bases[want_id]
seen = set()
for f in sorted(glob.glob(f"{d}/dump_*_ff8800.bin")):
    b = open(f, "rb").read()
    seen.add(struct.unpack(">I", b[0x60:0x64])[0])
if want in seen:
    print(f"  ok: P2 loaded {leg} base {want:#08x} at match start (liveness)")
else:
    nz = sorted(x for x in seen if x)
    print(f"FAIL: P2 base {want:#08x} ({leg}) not seen — DEAD leg. saw {[hex(x) for x in nz]}")
    sys.exit(1)
PY

    if [ "$rc" = 0 ] && grep -q "^END $((FRAMES-80))\|^END 40620" "$d/out.log"; then
        ok "$leg leg guard-clean to END"
    elif [ "$rc" = 2 ]; then
        # a crash here would be #99 reproducing on MAME — REPORT it loudly, it is
        # a finding (the honest gap says it does not on a P1-mash), not a pass.
        echo "  NOTE: guard TRIPPED on the $leg leg — #99 (or another vector) reproduced on MAME:"
        grep -E "^(CRASH|STACK|SOFTRESET|PCWEEDS) " "$d/out.log" | head -4
        bad "$leg leg tripped the guard (see above) — investigate, do not absorb"
    else
        bad "$leg leg did not complete (rc=$rc)"; tail -3 "$d/g.log"
    fi
done

[ "$fail" = 0 ] && echo "PASS: audit_don_vs_cpu" || echo "FAIL: audit_don_vs_cpu"
exit "$fail"
