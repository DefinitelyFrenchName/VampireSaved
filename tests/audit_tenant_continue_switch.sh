#!/bin/sh
# audit_tenant_continue_switch.sh — A TENANT CPU OPPONENT SURVIVES A CONTINUE-AND-SWITCH (GitHub #202, 14z-189): lose to CPU Phobos as Donovan, continue, answer NO to "same character?" and pick Aulbath, and the ladder's re-pick is SKIPPED by the 14z-87 keep-tenant thunk — Aulbath fights Phobos, where the draw is Sasquatch. Frozen AS MEASURED on the merged build.
#
# WHAT: the first-rung pick (PRG:0x00AE7C) re-runs after a continue; on our builds its store (PRG:0x0AEF6) sits in the
#   keep-tenant site_thunk, which skips it while the CPU side's +0x382 holds 0x10/0x11/0x13. After a loss to a tenant
#   the CPU side still holds that tenant, so when the player SWITCHES character on the continue the ladder draws from
#   the new character's row (stage and all) but the tenant loads anyway — a legacy character meets a tenant, which no
#   ladder row can schedule (engine_internals "WHO CAN BE DRAWN AGAINST WHOM"). Later rungs pick through a different
#   store (PRG:0x0AFCE, no thunk) and are not affected; a continue with the SAME character draws the held class anyway.
# HOW: one rig, two legs, merged build on MAME. tests/replays/don/202_don_continue_switch.rpl picks Donovan on the wheel,
#   the venue byte $FF8121 is pinned to 0x10 (rung 1 Bishamon, rung 2 Phobos), P2's then P1's HP words are poked
#   negative (Bishamon KO'd at f3000, Donovan KO'd by Phobos at f4600), and the replay continues, answers NO and moves
#   the cursor to Aulbath. Leg HELD runs as is; leg RELEASED also pokes P2's +0x382 to 0x03 between the switch and the
#   re-pick, so the store runs and writes the DRAW. Per leg: a non-debug write tap on $FF8B82/$FF8782/$FF8100
#   (tests/lua/read_tap.lua) and P1/P2 block dumps every 10 frames (tests/lua/replay.lua). Each loaded character is
#   named by its +0x60 against the BUILD's own table (PRG:0x0BD97A, as audit_don_vs_cpu does), names from
#   tests/expected/roster_pairings/bases.tsv.
# EXPECTS: both legs' setup events happen (else VOID): rung 1 loads Bishamon, P2 KO'd, rung 2 written 0x10 by
#   PRG:0x0AFCE and Phobos loads, P1 KO'd, P1's +0x382 committed 0x09 after the continue, the re-pick's stage write
#   (PRG:0x00AF10) follows it. RELEASED: the store writes $FF8B82 in the re-pick's frame with a class D != 0x10, and
#   P2 loads D with P1 Aulbath. HELD (EXPECT=held, the default, as measured): no write to $FF8B82 between the switch
#   and the re-pick, and P2 loads Phobos with P1 Aulbath. Both legs write the same stage. EXPECT=draw is the form
#   once #202 is fixed: HELD loads D too. Every control fails.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/roster_pairings/bases.tsv tests/lib/controls.sh
#   tests/lua/read_tap.lua tests/lua/replay.lua tests/replays/don/202_don_continue_switch.rpl tools/run_mame.sh
#   tools/setup_mame.sh
#
# POKE READ-BACK (tests/expected/poke_readback.tsv, ruled 2026-10-02, 14z-189): the RELEASED leg's check that its
#   0x03 poke on $FF8B82 landed between the switch and the re-pick reads the rig's OWN poke back — a RIG RECORD, not
#   the engine; the store write in the re-pick's frame and the $FF8782 commit are the game's own (OBSERVES).
#
# MUST-FIRE: perturbed-copy: legs-swapped — the checks run with the HELD and RELEASED legs exchanged must fail, so "the held tenant loads instead of the draw" is something they can refuse (in-gate: on the real taps and dumps; mode: exchanged and the gate FAILs)
# MUST-FIRE: perturbed-copy: base-misnamed — the checks run with every class base reassigned to the next class must fail, so each loaded character is named by its +0x60 (in-gate: on the real dumps; mode: reassigned and the gate FAILs)
# MUST-FIRE: perturbed-copy: repick-misplaced — the checks run with the re-pick taken at the NEXT stage write must fail, so the RELEASED store is attributed to the re-pick's own frame (in-gate: on the real taps; mode: moved and the gate FAILs)
#
# NOT COVERED: Phobos and Pyron as the player or as the held tenant (one pairing, Donovan -> Phobos); a challenger
#   joining; a continue reached by the late START (that is a new game: P2's +0x382 is cleared, measured 14z-189); the
#   FBNeo leg; whether the field ever met it. The rig's KOs are pokes, and its frames are the merged build's.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged30] [EXPECT=held|draw] [KEEP=<dir>]
#        tests/audit_tenant_continue_switch.sh
#   emulator tier, MAME; ~1.5 min (two legs, each a tap run and a dump run in parallel)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${BUILD:-build/m3b_merged30}"
EXPECT="${EXPECT:-held}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD";; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no merged build at $BUILD (rompath/vsavjw.zip)"; exit 1; }
[ -f "$BUILD/prg/vm3j.04d" ] || { echo "FAIL: no prg/vm3j.04d in $BUILD"; exit 1; }
case "$EXPECT" in held|draw) ;; *) echo "FAIL: EXPECT must be held or draw"; exit 1;; esac
echo "build under test: $BUILD ($(shasum "$BUILD/prg/vm3j.04d" | cut -c1-8) vm3j.04d), EXPECT=$EXPECT"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
RPL="$REPO/tests/replays/don/202_don_continue_switch.rpl"
N=7000
PK="1704:ff8782:13;1760:ff8782:13;1900:ff8782:13;2100:ff8782:13;2400:ff8782:13"   # P1 Donovan at the wheel commit
BASEP="$PK;1750-2860:ff8121:10;3000:ff8850:ffffffff;4600:ff8450:ffffffff"          # venue 0x10; Bishamon, then Donovan KO'd
D="$(python3 -c "print(';'.join(f'{f}:ff8400-ff87ff;{f}:ff8800-ff8bff' for f in range(2800, $N, 10)))")"

leg() {  # leg <name> <pokes> — a tap run and a dump run, in parallel
    for k in tap dmp; do rm -rf "$W/$1_$k"; mkdir -p "$W/$1_$k"; done
    ( cd "$W/$1_tap" && MAME_SANDBOX="$W/$1_tap/sb" MAME_ROMPATH="$BUILD/rompath;$ROMDIR" REPLAY="$RPL" POKES="$2" \
        RTAP="ff8b82,2;ff8782,2;ff8100,2" WINDOW="1,1" TRACE_OUT="$W/$1_tap.txt" FRAMES="$N" \
        "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/$1_tap/mame.log" 2>&1
      rm -rf "$W/$1_tap/sb" ) </dev/null 2>/dev/null &
    ( cd "$W/$1_dmp" && MAME_SANDBOX="$W/$1_dmp/sb" MAME_ROMPATH="$BUILD/rompath;$ROMDIR" REPLAY="$RPL" POKES="$2" \
        DUMPS="$D" CHECKSUM_OUT="$W/$1_dmp/cs.log" FRAMES="$N" \
        "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/replay.lua" > "$W/$1_dmp/mame.log" 2>&1
      rm -rf "$W/$1_dmp/sb" ) </dev/null 2>/dev/null &
    wait   # a teardown segfault (MFI-12) is not a verdict: the END line and the dumps decide
}
echo "== 1. the legs (merged build, MAME)"
leg held "$BASEP"
leg released "$BASEP;6100:ff8b82:03"
fail=0
for l in held released; do
    grep -q '^END ' "$W/${l}_tap.txt" 2>/dev/null || { echo "  FAIL  $l: no END line in the tap (see $W/${l}_tap/mame.log) — VOID"; fail=1; }
    [ -f "$W/${l}_dmp/dump_6990_ff8800.bin" ] || { echo "  FAIL  $l: dumps incomplete (see $W/${l}_dmp/mame.log) — VOID"; fail=1; }
done
[ "$fail" = 0 ] || { echo "FAIL: audit_tenant_continue_switch (a leg did not complete)"; exit 1; }
echo "  ok    two legs complete"

check() {  # check <held leg> <released leg> <base rotation> <re-pick skip> — exit 1 on any FAIL or VOID
    python3 - "$W" "$1" "$2" "$3" "$4" "$EXPECT" "$BUILD/prg/vm3j.04d" "$REPO/tests/expected/roster_pairings/bases.tsv" <<'PY'
import re, struct, sys
W, HELD, REL, rot, skip, expect, prg, bases_p = sys.argv[1:9]
rot, skip = int(rot), int(skip)
bad = []
def ok(m): print(f"  ok    {m}")
def no(m): print(f"  FAIL  {m}"); bad.append(m)
raw = open(prg, "rb").read()[0x3D97A:0x3D97A + 32 * 4]
sw = bytearray()
for i in range(0, len(raw), 2): sw += raw[i + 1:i + 2] + raw[i:i + 1]
base = [struct.unpack(">I", bytes(sw[4 * i:4 * i + 4]))[0] for i in range(32)]
if rot: base = base[1:] + base[:1]
names = {}
for ln in open(bases_p):
    if ln.startswith("#") or not ln.strip(): continue
    c, n = ln.split("\t")[:2]; names[int(c, 16)] = n
cls_of = {}
for i, b in enumerate(base): cls_of.setdefault(b, i)
nm = lambda b: f"{names.get(cls_of.get(b), '?')} ({b:#010x})"
def taps(leg):
    out = []
    for ln in open(f"{W}/{leg}_tap.txt"):
        m = re.match(r"W (\d+) PC (\w+) off (\w+) data (\w+) mask (\w+)", ln)
        if m and m.group(5) == "0000ff00": out.append((int(m.group(1)), int(m.group(2), 16), m.group(3), (int(m.group(4), 16) >> 8) & 0xFF))
        elif m and m.group(3) == "ff8100": out.append((int(m.group(1)), int(m.group(2), 16), m.group(3), int(m.group(4), 16) & 0xFFFF))
    return out
def blk(leg, f, a):
    b = open(f"{W}/{leg}_dmp/dump_{f}_{a}.bin", "rb").read()
    return b[0x382], int.from_bytes(b[0x60:0x64], "big"), struct.unpack(">h", b[0x52:0x54])[0]
FR = range(2800, 7000, 10)
def first(leg, a, lo, hi, pred):
    for f in FR:
        if lo <= f < hi and pred(blk(leg, f, a)): return f
    return None
def setup(leg):  # -> (commit frame, re-pick frame, re-pick stage) or None (VOID)
    T, v = taps(leg), []
    if first(leg, "ff8800", 2800, 3000, lambda x: x[1] == base[0x08]) is None: v.append("rung 1 did not load Bishamon")
    if first(leg, "ff8800", 3000, 3600, lambda x: x[2] < 0) is None: v.append("P2 was not KO'd in match 1")
    if not [t for t in T if 3000 < t[0] < 4400 and t[1] == 0xAFCE and t[2] == "ff8b82" and t[3] == 0x10]: v.append("rung 2 was not written 0x10 by PRG:0x0AFCE")
    if first(leg, "ff8800", 4400, 4700, lambda x: x[1] == base[0x10]) is None: v.append("rung 2 did not load Phobos")
    if first(leg, "ff8400", 4600, 5300, lambda x: x[2] < 0) is None: v.append("P1 was not KO'd in match 2")
    c = [t[0] for t in T if t[0] > 5500 and t[2] == "ff8782" and t[3] == 0x09]
    if not c: v.append("P1's +0x382 was never committed 0x09 after the continue")
    p = [t for t in T if c and t[0] > c[0] and t[1] == 0xAF10]
    if len(p) <= skip: v.append("no re-pick stage write (PRG:0x00AF10) after the switch")
    if v:
        for m in v: print(f"  VOID  {leg}: {m}")
        return None
    ok(f"{leg}: setup — Bishamon then Phobos, both KOs, the switch committed 0x09 at f{c[0]}, the re-pick at f{p[skip][0]} (stage {p[skip][3]:#04x})")
    return c[0], p[skip][0], p[skip][3]
def match3(leg, fp):
    for f in FR:
        if f > fp + 100:
            p2, p1 = blk(leg, f, "ff8800"), blk(leg, f, "ff8400")
            if p2[1] and p1[1]: return f, p1[1], p2[1]
    return None, 0, 0
sH, sR = setup(HELD), setup(REL)
if sH is None or sR is None:
    print("  VOID  a leg's setup events did not happen — no verdict on it"); sys.exit(1)
TR = taps(REL)
rel_at = [t for t in TR if sR[0] < t[0] < sR[1] and t[2] == "ff8b82" and t[3] == 0x03]
if rel_at: ok(f"RELEASED: P2's +0x382 released to 0x03 at f{rel_at[0][0]}, between the switch and the re-pick")
else: no("RELEASED: the release poke did not land between the switch and the re-pick")
st = [t for t in TR if t[0] == sR[1] and t[2] == "ff8b82"]
draw = st[0][3] if st else None
if draw is not None and draw != 0x10: ok(f"RELEASED: the store wrote the draw {draw:#04x} ({names.get(draw, '?')}) in the re-pick's frame f{sR[1]} (PC {st[0][1]:#x})")
else: no(f"RELEASED: no store write of a non-Phobos class in the re-pick's frame f{sR[1]}: {st}")
f3, p1, p2 = match3(REL, sR[1])
if draw is not None and p2 == base[draw] and p1 == base[0x09]: ok(f"RELEASED: match 3 (f{f3}) P1 {nm(p1)} vs P2 {nm(p2)} — the draw loads")
else: no(f"RELEASED: match 3 (f{f3}) P1 {nm(p1)} vs P2 {nm(p2)} (want Aulbath vs the draw)")
TH = taps(HELD)
hw = [t for t in TH if sH[0] < t[0] <= sH[1] and t[2] == "ff8b82"]
f3h, p1h, p2h = match3(HELD, sH[1])
if expect == "held":
    if not hw: ok(f"HELD: no write to $FF8B82 between the switch f{sH[0]} and the re-pick f{sH[1]} — the store was skipped")
    else: no(f"HELD: $FF8B82 written between the switch and the re-pick: {hw}")
    if p2h == base[0x10] and p1h == base[0x09]: ok(f"HELD: match 3 (f{f3h}) P1 {nm(p1h)} vs P2 {nm(p2h)} — the held tenant loads, not the draw")
    else: no(f"HELD: match 3 (f{f3h}) P1 {nm(p1h)} vs P2 {nm(p2h)} (want Aulbath vs Phobos, as measured)")
else:
    if draw is not None and p2h == base[draw] and p1h == base[0x09]: ok(f"HELD: match 3 (f{f3h}) P1 {nm(p1h)} vs P2 {nm(p2h)} — the draw loads (#202 fixed)")
    else: no(f"HELD: match 3 (f{f3h}) P1 {nm(p1h)} vs P2 {nm(p2h)} (want Aulbath vs the draw)")
if sH[2] == sR[2]: ok(f"both legs: the re-pick wrote the same stage {sH[2]:#04x} — the ladder ran the same draw")
else: no(f"the re-pick's stage differs: HELD {sH[2]:#04x}, RELEASED {sR[2]:#04x}")
sys.exit(1 if bad else 0)
PY
}
echo "== 2. the checks"
H=held; R=released; ROT=0; SK=0
vs_ctl_is legs-swapped && { H=released; R=held; }
vs_ctl_is base-misnamed && ROT=1
vs_ctl_is repick-misplaced && SK=1
check "$H" "$R" "$ROT" "$SK" || fail=1

echo "== 3. the controls"
if check released held 0 0 > /dev/null 2>&1; then vs_ctl_dead legs-swapped "the checks pass with the legs exchanged" || fail=1
else vs_ctl_fired legs-swapped "the checks refuse the exchanged legs"; fi
if check held released 1 0 > /dev/null 2>&1; then vs_ctl_dead base-misnamed "the checks pass with every base reassigned" || fail=1
else vs_ctl_fired base-misnamed "the checks refuse the reassigned bases"; fi
if check held released 0 1 > /dev/null 2>&1; then vs_ctl_dead repick-misplaced "the checks pass with the re-pick misplaced" || fail=1
else vs_ctl_fired repick-misplaced "the checks refuse the misplaced re-pick"; fi

[ "$fail" = 0 ] && echo "PASS: audit_tenant_continue_switch" || { echo "FAIL: audit_tenant_continue_switch"; exit 1; }
