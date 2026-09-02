#!/bin/sh
# test_don_immortal_native.sh — 421+P (Lightning Sword) AGAINST NATIVE vsav2,
# in the units the comparison is allowed to use (14z-127, GitHub #114).
#
# WHY IT EXISTS. `test_don_reactions.sh` asserts this move on OUR build only:
# all its legs run `vsavj` and its "native == 10" was testimony, not a
# measurement (STATE 14z-42c). #114 was opened on that weak provenance. This
# gate measures NATIVE IN THE SAME RUN, so no constant here is anyone's memory.
#
# WHAT #114 ACTUALLY WAS. Its "ours" leg was JEDAH. Replay 48's P1 path
# (U,U,R -> slot 0x0F) selects Donovan only on the SUBSTITUTED stock track;
# since the 14z-115 wheel separation a WIDE build puts the tenants on their own
# appended row, so that path lands on vanilla Jedah (+0x60 = 0x000b0d2e) and
# the "3 hits / 11 damage, victim pushed 728->852" recorded as ours was his
# 421+HP. Section 3 is that artefact, kept as the must-fire control. Section 2
# therefore asserts WHO IT SELECTED before it believes any number ([VSP-156]).
#
# ** WHY THIS GATE COMPARES HIT COUNT AND DAMAGE AND NOT FRAME TIMINGS.**
# Measured 14z-127: our deity ticks run ~1 video frame slower per ~11 engine
# ticks than native's. That is NOT the port. Section 4 measures it on VANILLA
# content -- four vanilla characters, forced picks, identical inputs, the same
# scenario on both games -- and the hit-freeze `+0x5C` = 11 drains in 9 video
# frames on vsav2 and 10 on vsavj FOR EVERY ONE OF THEM. The vsavj engine runs
# fewer double-ticks per video frame than vsav2's (docs/game/gotchas.md "THE
# ENGINE RUNS TWO TICKS IN ONE VIDEO FRAME"), so a ported character CANNOT tick
# at vsav2's frame rate without ticking unlike every other character in the
# game it now lives in.
# MAINTAINER'S RULING (2026-09-02): "we must respect the fact that we are
# porting the character to a different engine and the engine, being vanilla
# vsav, takes precedence." So the HOST ENGINE'S CLOCK WINS, and the assertable
# quantities are the ones the clock does not set: HIT COUNT and DAMAGE.
# Asserting vsav2's frame numbers here would be a permanently red gate no fix
# could address, and "fixing" it would break the character away from its host.
#
#   1. NATIVE   vsav2, replay 51, LP/MP/HP/ES no-mash -> the reference, measured
#   2. OURS     the build under test, same four        -> must EQUAL native,
#               two-sided, with P1's identity asserted from bases.tsv
#   3. CONTROL  pristine vsavj + replay 48             -> must FAIL section 2
#   4. ENGINE   vanilla Victor mirror, both games      -> the +1 frame gap on
#               content the port never touches: the licence for section 2's
#               units, with the gap itself frozen
#
# NOT COVERED HERE, deliberately (scoped 14z-127, not started):
#   * MASHING. Mash extends the loop, and the extension is MULTI-LEVEL (the
#     maintainer: at least two extra levels by rate). Measured 14z-127 across
#     six rates, but the rig fires presses at FIXED ABSOLUTE FRAMES while our
#     move runs on the slower host clock, so the presses land at different
#     PHASES of the move on the two legs and the comparison is confounded --
#     it produced non-monotonic cells (MP at the slowest rate reading FEWER
#     hits than no-mash), which no real mechanic does. A mash assertion needs
#     a script anchored to each leg's OWN move progress. Until then this gate
#     says nothing about mashing rather than something false.
#   * TICK-ACCURATE DURATIONS. `tools/tick_durations.py` is the right
#     instrument (a write tap fires per write, so it sees every tick); it is
#     PC-pinned to vsavj and needs vs2's twin PCs for a cross-game run.
#
# Usage: ROMDIR=... tests/test_don_immortal_native.sh [rompath_dir]
#   The rompath's pack picks the track: a `vsavjw.zip` runs the WIDE leg
#   (replay don/114 + the WIDE MAME binary), anything else the stock leg.
# Runtime: ~9 min, emulator tier.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/m5_stock13/rompath}"
[ -d "$RPDIR" ] || { echo "SKIP: no build at $RPDIR"; exit 0; }
RPDIR="$(cd "$RPDIR" && pwd)"                    # [VSP-108]
BASES="$REPO/tests/expected/roster_pairings/bases.tsv"
[ -f "$BASES" ] || { echo "FAIL: missing $BASES"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

DSPEC="$(python3 -c "print(';'.join(f'{f}:ff8800-ff8a00' for f in range(2600,2761))+';2600:ff8400-ff8600')")"

# Per-strength replays are DERIVED from the two committed bases by substituting
# the button on the activation line -- one line, printed, rather than eight
# near-identical files. ES additionally needs a banked stock ([VSP-123]).
mkgen() {  # mkgen <base rpl> <button> <out>
    grep -v '^#' "$REPO/tests/replays/$1" \
      | sed "s/^2620-2624 p1=.*/2620-2624 p1=$2/" > "$3"
    grep -q "^2620-2624 p1=$2\$" "$3" || { echo "FAIL: button substitution missed in $3"; exit 1; }
}
run() {   # run <name> <set> <rompath> <rpl file> <pokes> [mame_bin]
    mkdir -p "$WORK/$1"
    [ -n "${6:-}" ] && { MAME_BIN="$6"; export MAME_BIN; }
    DUMPS="$DSPEC" POKES="$5" REPLAY="$4" CHECKSUM_OUT="$WORK/$1/c.log" \
        MAME_SANDBOX="$WORK/$1/sb" MAME_ROMPATH="$3" tools/run_mame.sh "$2" \
        -autoboot_script "$REPO/tests/lua/replay.lua" > "$WORK/$1/mame.log" 2>&1
    unset MAME_BIN
    [ "$(ls "$WORK/$1"/dump_*_ff8800.bin 2>/dev/null | wc -l)" -ge 150 ] \
        || { echo "FAIL: leg $1 produced no dumps (see $WORK/$1/mame.log)"; exit 1; }
}

if [ -f "$RPDIR/vsavjw.zip" ]; then
    OURS_SET=vsavjw; OURS_BASE=don/114_don_immortal_wide.rpl
    OURS_BIN="$HOME/.cache/vampire-saved/mame/cps2"
    [ -x "$OURS_BIN" ] || { echo "SKIP: WIDE build but no WIDE MAME at $OURS_BIN"; exit 0; }
else
    OURS_SET=vsavj; OURS_BASE=48_don_immortal_ko.rpl; OURS_BIN=""
fi
echo "  ours: $OURS_SET + $OURS_BASE  ($RPDIR)"

for s in LP:1 MP:2 HP:3 ES:13; do
    st="${s%%:*}"; b="${s##*:}"; pk=""
    [ "$st" = ES ] && pk="2550:ff8509:09"
    mkgen 51_vs2_immortal_native.rpl "$b" "$WORK/nat_$st.rpl"
    mkgen "$OURS_BASE"               "$b" "$WORK/our_$st.rpl"
    run "nat_$st" vsav2      "$ROMDIR"           "$WORK/nat_$st.rpl" "$pk"
    run "our_$st" "$OURS_SET" "$RPDIR;$ROMDIR"   "$WORK/our_$st.rpl" "$pk" "$OURS_BIN"
done
run ctl vsavj "$ROMDIR" "$REPO/tests/replays/48_don_immortal_ko.rpl" ""
# Section 4: vanilla VICTOR mirror (id 0x03 forced BOTH sides), same inputs,
# both games. The port touches nothing here.
VPOKE="1400:ff8782:03;1450:ff8782:03;1500:ff8782:03;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
grep -v '^#' "$REPO/tests/replays/48_don_immortal_ko.rpl" \
  | sed 's/^2620-2624 p1=.*/2620-2624 p1=3/' | grep -v '^261[048]' > "$WORK/van.rpl"
run van_vs2  vsav2 "$ROMDIR" "$WORK/van.rpl" "$VPOKE"
run van_vsavj vsavj "$ROMDIR" "$WORK/van.rpl" "$VPOKE"

python3 - "$WORK" "$BASES" <<'EOF2'
import sys, os, struct
work, bases_path = sys.argv[1], sys.argv[2]
bases = {}
for line in open(bases_path):
    if line.startswith('#') or not line.strip(): continue
    c, n, b = line.split()[:3]; bases[n] = int(b, 16)
DON, JEDAH = bases['donovan'], bases['jedah']
DON_VS2 = 0x000C8DF8            # vs2's own Donovan base (pristine-ROM fact)

def u16(b,o): return struct.unpack('>H',b[o:o+2])[0]
def s16(b,o): return struct.unpack('>h',b[o:o+2])[0]
def u32(b,o): return struct.unpack('>I',b[o:o+4])[0]

def measure(leg):
    d = os.path.join(work, leg); prev=None; hits=[]; xs={}
    p1 = u32(open(os.path.join(d,'dump_2600_ff8400.bin'),'rb').read(), 0x60)
    for f in range(2600, 2761):
        p = os.path.join(d, f'dump_{f}_ff8800.bin')
        if not os.path.exists(p): continue
        b = open(p,'rb').read(); hp = u16(b,0x50); xs[f] = s16(b,0x10)
        if prev is not None and hp < prev: hits.append((f, prev-hp))
        prev = hp
    held = (len({xs[f] for f in range(hits[0][0], hits[-1][0]+1)}) == 1) if hits else None
    return dict(p1=p1, n=len(hits), dmg=sum(d for _,d in hits), held=held,
                steps=hits, vals=[d for _,d in hits])

# ── 1. native, measured in-run, against its frozen shape ────────────────
FROZEN = {'LP': (3,7), 'MP': (5,9), 'HP': (6,10), 'ES': (9,13)}
nat = {}
for st in FROZEN:
    m = measure(f'nat_{st}'); nat[st] = m
    assert m['p1'] == DON_VS2, (
        f"native {st}: P1 +0x60 = {m['p1']:#x}, expected vs2 Donovan {DON_VS2:#x}")
    assert (m['n'], m['dmg']) == FROZEN[st], (
        f"NATIVE {st} = {m['n']}h/{m['dmg']}d, frozen reference is "
        f"{FROZEN[st][0]}h/{FROZEN[st][1]}d — the INSTRUMENT moved, not the port")
    assert m['held'], f"native {st}: victim not held through the shake"
    print(f"  ok: NATIVE {st:2} {m['n']}h/{m['dmg']:2}d, victim held  {m['vals']}")

# ── 2. ours must EQUAL native, two-sided, having selected Donovan ───────
for st in FROZEN:
    m = measure(f'our_{st}')
    assert m['p1'] == DON, (
        f"ours {st}: P1 +0x60 = {m['p1']:#x}, expected Donovan {DON:#x} (bases.tsv). "
        f"THE REPLAY SELECTED SOMEONE ELSE — the #114 artefact; any number here "
        f"would be that character's")
    assert m['n'] == nat[st]['n'], (
        f"OURS {st}: {m['n']} hits vs native's {nat[st]['n']} "
        f"(ours {m['vals']}, native {nat[st]['vals']})")
    assert m['dmg'] == nat[st]['dmg'], (
        f"OURS {st}: {m['dmg']} damage vs native's {nat[st]['dmg']} "
        f"(ours {m['vals']}, native {nat[st]['vals']})")
    assert m['held'], f"ours {st}: victim not held through the shake"
    print(f"  ok: OURS   {st:2} {m['n']}h/{m['dmg']:2}d == native, victim held")

# ── 3. must-fire control: the #114 artefact ─────────────────────────────
c = measure('ctl')
assert c['p1'] == JEDAH, (
    f"control: P1 +0x60 = {c['p1']:#x}, expected vanilla Jedah {JEDAH:#x}")
assert (c['n'], c['dmg']) != (nat['HP']['n'], nat['HP']['dmg']), (
    "CONTROL matched Donovan's HP shape — the assertions cannot discriminate")
print(f"  ok: CONTROL fires — pristine vsavj (Jedah) {c['n']}h/{c['dmg']}d "
      f"held={c['held']} (the #114 artefact)")

# ── 4. the engine clock, on vanilla content: why §2 compares counts ─────
def drain(leg):
    d = os.path.join(work, leg); prev=None; hit=None; vals=[]
    for f in range(2600, 2761):
        p = os.path.join(d, f'dump_{f}_ff8800.bin')
        if not os.path.exists(p): continue
        b = open(p,'rb').read(); hp = u16(b,0x50)
        if prev is not None and hp < prev and hit is None: hit = f
        prev = hp
        if hit and f >= hit: vals.append(b[0x5c])
    assert hit, f"{leg}: no vanilla contact — the engine-clock control did not fire"
    return vals[0], len([v for v in vals[:20] if v > 0])
s2, f2 = drain('van_vs2'); sj, fj = drain('van_vsavj')
assert s2 == sj, f"vanilla freeze START differs ({s2} vs {sj}) — not a clock question"
assert fj == f2 + 1, (
    f"the vanilla cross-game clock gap moved: vsav2 drains {s2} in {f2} frames, "
    f"vsavj in {fj} (frozen: +1). Section 2's licence to compare COUNTS rests on "
    f"this being the ENGINE's difference and not the port's — re-measure before "
    f"touching anything else")
print(f"  ok: ENGINE CLOCK on vanilla content — freeze {s2} drains in {f2} f on "
      f"vsav2, {fj} f on vsavj (+1, frozen). The host clock is slower FOR "
      f"EVERYONE, so §2 asserts counts, not frames")
EOF2
echo "PASS: 421+P equals native in hit count and damage at every strength (no-mash)"
