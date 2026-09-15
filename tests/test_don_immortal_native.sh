#!/bin/sh
# test_don_immortal_native.sh — 421+P (Lightning Sword) AGAINST NATIVE vsav2 AT A MATCHED SPEED LEVEL AND A PINNED RNG,
# in hit count, damage and hit frames (14z-127, GitHub #114; matched 14z-158, #135, #142).
#
# MUST-FIRE: known-bad: jedah-artefact — the #114 artefact (pristine vsavj + replay 48 selects JEDAH, not Donovan) must not be accepted as ours, so treating the Jedah control leg as ours must fail (mode: the control leg is measured and required to match Donovan, which it never does, so the gate FAILs)
# MUST-FIRE: perturbed-copy: unmatched-modes — the native legs left at vsav2's DEFAULT play mode (TURBO, speed level 8) against ours at level 6 must fail, so the gate is proven to see the level it pins (in-gate: native LP at the ceiling at the default level lands its hits on different frames from ours at level 6; mode: every native leg runs at its default level and the level-6 comparisons FAIL)
# MUST-FIRE: perturbed-copy: unpinned-rng — the MP no-mash legs at level 6 with the RNG left unpinned must diverge (native 4 hits, ours 5, measured 14z-158: #142), so the gate is proven to see the RNG state it pins (in-gate: two unpinned legs; mode: every leg runs unpinned and the comparisons FAIL)
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
# ** WHY EVERY LEG PINS THE SPEED LEVEL (14z-158, #135).** After character
# select, P1 picks NORMAL / TURBO / AUTO / AUTO&TURBO, and the choice sets the
# speed level RAM:$FF8116, which alone decides how often the game task runs an
# extra logic pass (the 32-bit pattern at PRG:0x008E6C in vsavj, 0x00763A in
# vs2, identical; docs/game/engine_internals.md). vsav2 HARD-CODES P1's default
# to TURBO at character confirm (PRG:0x01F98C `move.b #$1,$7(a6)`), vsavj to
# NORMAL (PRG:0x020D38 `clr.b $7(a6)`), and these replays never touch the menu.
# So until 14z-158 every NATIVE leg ran TURBO (level 8) against ours at NORMAL
# (level 6) — which is what 14z-127 measured as "the vsavj engine runs fewer
# double-ticks per video frame": RETRACTED.
#
# ** AND PINS THE RNG (14z-158, #142).** The object loop (vsavj PRG:0x02207E,
# vs2 0x020A2E, the same code) updates P1 first or P2 first on every pass,
# picked by bit 0 of the engine RNG (RAM:$FF80D4-D5, vsavj PRG:0x014E8A, vs2
# 0x01357E, the same routine), and the two games' RNG states differ all through
# a match, vanilla content included. So a sequence that sets and decrements a
# freeze in the same pass lands a hit one pass apart depending on the draw: MP
# with no mash at level 6 was 5 hits on ours and 4 on native, the fifth at frame
# 2678, because on the pass after the fourth hit the two legs updated the
# fighters in opposite orders and ours' attacker stayed frozen one pass longer.
# The unpinned-rng control's evidence re-measures that order every run: on the
# frame after the fourth hit the attacker's freeze `+0x5C` is written 3, 4, 3
# on native (set, then its reducer) and 3, 2, 4 on ours (its reducer, then set).
# With the level AND the RNG pinned, every leg is identical to the frame.
#
# MAINTAINER'S RULINGS (2026-09-15; DECISIONS_HISTORY.md "Ruled 2026-09-15
# (14z-158)"): *"Force the same speed level on both legs and assert ours ==
# native at NORMAL (level 6) and TURBO (level 8). Retract LP's 'one hit short'
# and §4's '+1 frame' as mode artifacts."* Then *"Poke the level and $FF80D4-D5
# = 0000 every frame 2400-2800 on both legs; assert hit count, damage AND hit
# frames equal (measured identical 16/16). Keep a must-fire control that leaves
# the RNG unpinned and must diverge (MP at level 6), so the gate proves it sees
# the RNG."* #142 closed invalid. The 2026-09-02 ruling that the vanilla vsav
# engine takes precedence stands. Every leg's own dumps prove both pins held:
# the level at 2600 and 2800, the RNG = 0000 at 2600 and 2800, the turbo-pass
# flag $FF812D = 1 at 2600.
#
#   1. NATIVE   vsav2, replay 51, LP/MP/HP/ES no-mash, at level 6 and at level 8
#               -> the reference, measured, against its frozen count and damage
#   2. OURS     the build under test, same eight legs -> must EQUAL native at the
#               same level in count, damage and hit frames, with P1's identity
#               asserted from bases.tsv
#   3. CONTROL  pristine vsavj + replay 48             -> must FAIL section 2
#   4. ENGINE   vanilla Victor mirror, both games, both levels -> the freeze
#               drains in the SAME number of frames on both games at each level,
#               and in a different number between the levels (the level is live)
#   5. CEILING  all four strengths at the TRUE maximum press rate, both levels ->
#               ours must EQUAL native in count, damage and hit frames
#
# MASHING (section 5, measured 14z-127). Mash extends the loop: each new press
# bumps a MASH ACCUMULATOR (`+0x0A`), and when the deciding code finds it at >= 7
# it spends one unit of an ITERATION BUDGET (`+0x27`, the per-strength cap:
# 2/3/3/4 for LP/MP/HP/ES) and loops again. VERIFIED IDENTICAL BETWEEN THE GAMES
# AT THREE LEVELS -- the 94 chain nodes (every non-pointer field, every link
# relocated by the port delta), the deciding code (vs2 0x059EEA vs ours 0x0C00FA,
# instruction for instruction, only the jmp relocated), and the budget's start
# value per strength. With the level and the RNG pinned, at the TRUE INPUT
# CEILING ours equals native at every strength and both levels: LP 5/9, MP 9/13,
# HP 11/15, ES 16/20 (measured 14z-158). THE COUNTS FOLLOW THE RNG PATH — unpinned
# (each game's own draws) LP at the ceiling read 4/8 at level 6 and 5/9 at level
# 8, and the frozen numbers of 14z-127 were one such path. ~~LP is ONE HIT SHORT
# (4 vs 5)~~ and ~~ours saturates at a LOWER mash rate because the host clock is
# slower~~ — RETRACTED 14z-158: both compared ours at level 6 with native at level
# 8, unpinned. The mid-rate comparison has not been re-measured.
#
# NOT COVERED HERE, deliberately:
#   * TICK-ACCURATE DURATIONS. `tools/tick_durations.py` is the right
#     instrument (a write tap fires per write, so it sees every tick); it is
#     PC-pinned to vsavj and needs vs2's twin PCs for a cross-game run.
#
# Usage: ROMDIR=... tests/test_don_immortal_native.sh [rompath_dir]
#   The rompath's pack picks the track: a `vsavjw.zip` runs the WIDE leg
#   (replay don/114 + the WIDE MAME binary), anything else the stock leg.
# Runtime: ~4 min (42 MAME legs), emulator tier.
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
RPDIR="${1:-$REPO/build/m5_stock17/rompath}"
# A MISSING PREREQUISITE IS LOUD, NEVER A SILENT exit 0. This gate is a
# FREEZE-BATTERY LEG (run_battery_m2.sh 3f) and `bat` invokes it as a bare
# command, so an exit 0 would be counted as PASS and "BATTERY GREEN" would be
# a lie — the exact class tests/test_battery_accounting.sh exists to bar
# ([VSP-101]: SKIP IS NOT PASS). Same convention as test_don_reactions.sh.
[ -d "$RPDIR" ] || { echo "FAIL: no build at $RPDIR"; exit 1; }
RPDIR="$(cd "$RPDIR" && pwd)"                    # [VSP-108]
BASES="$REPO/tests/expected/roster_pairings/bases.tsv"
[ -f "$BASES" ] || { echo "FAIL: missing $BASES"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"

DSPEC="$(python3 -c "print(';'.join(f'{f}:ff8800-ff8a00' for f in range(2600,2801))+';2600:ff8400-ff8600;2600:ff8080-ff817f;2800:ff8080-ff817f')")"

# Per-strength replays are DERIVED from the two committed bases by substituting
# the button on the activation line -- one line, printed, rather than eight
# near-identical files. ES additionally needs a banked stock ([VSP-123]).
mkgen() {  # mkgen <base rpl> <button> <out>
    grep -v '^#' "$REPO/tests/replays/$1" \
      | sed "s/^2620-2624 p1=.*/2620-2624 p1=$2/" > "$3"
    grep -q "^2620-2624 p1=$2\$" "$3" || { echo "FAIL: button substitution missed in $3"; exit 1; }
}
# Section 5: THE TRUE INPUT CEILING. A "mash" that presses for one frame and
# releases for one frame leaves a DEAD FRAME -- it is HALF the achievable rate.
# Alternating two buttons every frame makes EVERY frame a new press (the
# previous button is released), which is the real ceiling. Measuring below the
# ceiling compares the two legs at different points of the response curve and
# manufactures a difference (paid for 14z-127).
mkceil() {  # mkceil <base rpl> <button> <out>
    python3 - "$REPO/tests/replays/$1" "$2" "$3" <<'EOP'
import sys
src, btn, out = sys.argv[1], sys.argv[2], sys.argv[3]
body = [l for l in open(src).read().splitlines() if not l.startswith('#')]
body = [f'2620-2624 p1={btn}' if l.startswith('2620-2624 p1=') else l for l in body]
mash = [f'{f}-{f} p1=' + ('1' if f % 2 == 0 else '2') for f in range(2636, 2791)]
body = [l for l in body if not l.endswith(' wait')] + mash + ['3600 wait']
open(out, 'w').write("\n".join(body) + "\n")
EOP
    grep -q "^2620-2624 p1=$2\$" "$3" || { echo "FAIL: ceiling replay $3 malformed"; exit 1; }
}
run() {   # run <name> <set> <rompath> <rpl file> <pokes> [mame_bin]
    mkdir -p "$WORK/$1"
    [ -n "${6:-}" ] && { MAME_BIN="$6"; export MAME_BIN; }
    DUMPS="$DSPEC" POKES="$5" REPLAY="$4" CHECKSUM_OUT="$WORK/$1/c.log" \
        MAME_SANDBOX="$WORK/$1/sb" MAME_ROMPATH="$3" tools/run_mame.sh "$2" \
        -autoboot_script "$REPO/tests/lua/replay.lua" > "$WORK/$1/mame.log" 2>&1
    unset MAME_BIN
    rm -rf "$WORK/$1/sb"
    [ "$(ls "$WORK/$1"/dump_*_ff8800.bin 2>/dev/null | wc -l)" -ge 150 ] \
        || { echo "FAIL: leg $1 produced no dumps (see $WORK/$1/mame.log)"; exit 1; }
}
tapleg() {   # tapleg <name> <set> <rompath> <rpl file> <pokes> [mame_bin] — the attacker's freeze writes, frames 2655..2668
    mkdir -p "$WORK/$1"
    [ -n "${6:-}" ] && { MAME_BIN="$6"; export MAME_BIN; }
    POKES="$5" REPLAY="$4" TAP=ff845c,2 WINDOW=2655,2668 FRAMES=2668 TRACE_OUT="$WORK/$1/tap.log" \
        MAME_SANDBOX="$WORK/$1/sb" MAME_ROMPATH="$3" tools/run_mame.sh "$2" \
        -autoboot_script "$REPO/tests/lua/tap_writes.lua" > "$WORK/$1/mame.log" 2>&1
    unset MAME_BIN
    rm -rf "$WORK/$1/sb"
    grep -q '^END 2668 ' "$WORK/$1/tap.log" 2>/dev/null \
        || { echo "FAIL: tap leg $1 did not reach frame 2668 (see $WORK/$1/mame.log)"; exit 1; }
}
# THE TWO PINS — one function each, used by every leg. The unmatched-modes mode
# withholds the level from the native legs (vsav2 stays at its default, 8); the
# unpinned-rng mode withholds the RNG pin from every leg.
level_pokes() { python3 -c "print(';'.join(f'{f}:ff8116:$1' for f in range(2400, 2801)))"; }
rng_pokes()   { python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2400, 2801)))"; }
join_pokes() { _o=""; for _p in "$@"; do [ -n "$_p" ] && { [ -n "$_o" ] && _o="$_o;$_p" || _o="$_p"; }; done; echo "$_o"; }

if [ -f "$RPDIR/vsavjw.zip" ]; then
    OURS_SET=vsavjw; OURS_BASE=don/114_don_immortal_wide.rpl
    OURS_BIN="$HOME/.cache/vampire-saved/mame/cps2"
    [ -x "$OURS_BIN" ] || { echo "FAIL: WIDE build under test but no WIDE MAME binary at"
                            echo "      $OURS_BIN — build it with tools/setup_mame.sh. Refusing to"
                            echo "      self-skip: this gate is battery leg 3f and a silent exit 0"
                            echo "      would be counted as PASS."; exit 1; }
else
    OURS_SET=vsavj; OURS_BASE=48_don_immortal_ko.rpl; OURS_BIN=""
fi
echo "  ours: $OURS_SET + $OURS_BASE  ($RPDIR)"

VPOKE="1400:ff8782:03;1450:ff8782:03;1500:ff8782:03;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
grep -v '^#' "$REPO/tests/replays/48_don_immortal_ko.rpl" \
  | sed 's/^2620-2624 p1=.*/2620-2624 p1=3/' | grep -v '^261[048]' > "$WORK/van.rpl"
for s in LP:1 MP:2 HP:3 ES:13; do
    st="${s%%:*}"; b="${s##*:}"
    mkgen 51_vs2_immortal_native.rpl "$b" "$WORK/nat_$st.rpl"
    mkgen "$OURS_BASE"               "$b" "$WORK/our_$st.rpl"
    mkceil 51_vs2_immortal_native.rpl "$b" "$WORK/nat_${st}_ceil.rpl"
    mkceil "$OURS_BASE"               "$b" "$WORK/our_${st}_ceil.rpl"
done
R="$(rng_pokes)"; [ "$MODE" = unpinned-rng ] && R=""
for lv in 06 08; do
    L="$(level_pokes "$lv")"
    NL="$L"; [ "$MODE" = unmatched-modes ] && NL=""
    for s in LP MP HP ES; do
        es=""; [ "$s" = ES ] && es="2550:ff8509:09"
        run "nat_${s}_L$lv"      vsav2       "$ROMDIR"        "$WORK/nat_$s.rpl"        "$(join_pokes "$es" "$NL" "$R")"
        run "our_${s}_L$lv"      "$OURS_SET" "$RPDIR;$ROMDIR" "$WORK/our_$s.rpl"        "$(join_pokes "$es" "$L" "$R")" "$OURS_BIN"
        run "nat_${s}_ceil_L$lv" vsav2       "$ROMDIR"        "$WORK/nat_${s}_ceil.rpl" "$(join_pokes "$es" "$NL" "$R")"
        run "our_${s}_ceil_L$lv" "$OURS_SET" "$RPDIR;$ROMDIR" "$WORK/our_${s}_ceil.rpl" "$(join_pokes "$es" "$L" "$R")" "$OURS_BIN"
    done
    run "van_vs2_L$lv"   vsav2 "$ROMDIR" "$WORK/van.rpl" "$(join_pokes "$VPOKE" "$NL" "$R")"
    run "van_vsavj_L$lv" vsavj "$ROMDIR" "$WORK/van.rpl" "$(join_pokes "$VPOKE" "$L" "$R")"
done
run ctl vsavj "$ROMDIR" "$REPO/tests/replays/48_don_immortal_ko.rpl" ""
# the in-gate controls' own legs: native LP at the ceiling at its DEFAULT level
# (RNG pinned), and MP no-mash at level 6 on both sides with the RNG UNPINNED —
# plus a write tap on each unpinned MP leg for the order that makes them part
run nat_LP_ceil_default vsav2 "$ROMDIR" "$WORK/nat_LP_ceil.rpl" "$(rng_pokes)"
L6="$(level_pokes 06)"
run nat_MP_L06_unpinned vsav2       "$ROMDIR"        "$WORK/nat_MP.rpl" "$L6"
run our_MP_L06_unpinned "$OURS_SET" "$RPDIR;$ROMDIR" "$WORK/our_MP.rpl" "$L6" "$OURS_BIN"
tapleg tap_nat_MP_L06_unpinned vsav2       "$ROMDIR"        "$WORK/nat_MP.rpl" "$L6"
tapleg tap_our_MP_L06_unpinned "$OURS_SET" "$RPDIR;$ROMDIR" "$WORK/our_MP.rpl" "$L6" "$OURS_BIN"

python3 - "$WORK" "$BASES" "$MODE" <<'EOF2'
import sys, os, struct
sys.stdout.reconfigure(encoding="utf-8", newline="\n")
work, bases_path = sys.argv[1], sys.argv[2]
MODE = sys.argv[3] if len(sys.argv) > 3 else ""
bases = {}
for line in open(bases_path):
    if line.startswith('#') or not line.strip(): continue
    c, n, b = line.split()[:3]; bases[n] = int(b, 16)
DON, JEDAH = bases['donovan'], bases['jedah']
DON_VS2 = 0x000C8DF8            # vs2's own Donovan base (pristine-ROM fact)
LEVELS = (6, 8)
STR = ('LP', 'MP', 'HP', 'ES')

def u16(b,o): return struct.unpack('>H',b[o:o+2])[0]
def s16(b,o): return struct.unpack('>h',b[o:o+2])[0]
def u32(b,o): return struct.unpack('>I',b[o:o+4])[0]

def measure(leg):
    d = os.path.join(work, leg); prev=None; hits=[]; xs={}
    p1 = u32(open(os.path.join(d,'dump_2600_ff8400.bin'),'rb').read(), 0x60)
    for f in range(2600, 2801):
        p = os.path.join(d, f'dump_{f}_ff8800.bin')
        if not os.path.exists(p): continue
        b = open(p,'rb').read(); hp = u16(b,0x50); xs[f] = s16(b,0x10)
        if prev is not None and hp < prev: hits.append((f, prev-hp))
        prev = hp
    held = (len({xs[f] for f in range(hits[0][0], hits[-1][0]+1)}) == 1) if hits else None
    return dict(p1=p1, n=len(hits), dmg=sum(d for _,d in hits), held=held,
                frames=[f for f,_ in hits], vals=[d for _,d in hits])

def pins(leg, frame):   # (level $FF8116, RNG $FF80D4-D5, turbo-pass flag $FF812D)
    b = open(os.path.join(work, leg, f'dump_{frame}_ff8080.bin'), 'rb').read()
    return b[0x96], u16(b, 0x54), b[0xAD]

def shape(m): return (m['n'], m['dmg'], m['frames'])

def freeze_writes(leg, frame):   # the attacker's +0x5C byte writes on one tap frame, in order
    out = []
    for l in open(os.path.join(work, leg, 'tap.log')):
        if l.startswith('frame'):
            t = l.split()
            if int(t[1]) == frame and int(t[5], 16) == 0xFF845C and int(t[9], 16) == 0xFF00:
                out.append((int(t[7], 16) >> 8) & 0xFF)
    return out

# THE EXECUTABLE MODE: treat the Jedah control leg as ours and require it to be
# Donovan, which it never is, so the gate FAILs (a clean exit, not a traceback).
if MODE == "jedah-artefact":
    c = measure('ctl')
    if c['p1'] == DON:
        print(f"jedah-artefact mode: the control leg IS Donovan (P1 {c['p1']:#x}) — cannot demonstrate the #114 artefact"); sys.exit(1)
    print(f"jedah-artefact mode: the pristine-vsavj control leg selects P1 {c['p1']:#x} (Jedah, not Donovan {DON:#x}); accepting it as ours is the #114 artefact, so the gate FAILs")
    print("FAIL: test_don_immortal_native (jedah-artefact mode)")
    sys.exit(1)

fails = []
def need(ok, msg):
    print(("  ok: " if ok else "  FAIL: ") + msg)
    if not ok: fails.append(msg)

# ── 0. both pins held on every leg ──────────────────────────────────────
for L in LEVELS:
    legs = [f'{side}_{s}{kind}_L{L:02d}' for side in ('nat', 'our') for s in STR for kind in ('', '_ceil')]
    legs += [f'van_vs2_L{L:02d}', f'van_vsavj_L{L:02d}']
    bad = []
    for leg in legs:
        (l0, r0, t0), (l1, r1, _) = pins(leg, 2600), pins(leg, 2800)
        if (l0, l1, r0, r1, t0) != (L, L, 0, 0, 1):
            bad.append(f"{leg} level {l0}/{l1} RNG {r0:04x}/{r1:04x} turbo-pass flag {t0}")
    need(not bad, f"level {L}: all {len(legs)} legs held $FF8116 = {L} and $FF80D4-D5 = 0000 at 2600 and 2800, $FF812D = 1"
         + (f" — NOT: {bad[:4]}" if bad else ""))

# ── 1. native, measured in-run, against its frozen count and damage ─────
# One RNG path (0000 pinned every frame from 2400); the same at both levels.
NOMASH = {'LP': (3, 7), 'MP': (5, 9), 'HP': (7, 11), 'ES': (9, 13)}
nat = {}
for L in LEVELS:
    for st in STR:
        m = measure(f'nat_{st}_L{L:02d}'); nat[(st, L)] = m
        need(m['p1'] == DON_VS2 and (m['n'], m['dmg']) == NOMASH[st] and m['held'],
             f"NATIVE {st} level {L}: {m['n']}h/{m['dmg']}d held={m['held']} P1 {m['p1']:#x} "
             f"(frozen {NOMASH[st][0]}h/{NOMASH[st][1]}d, vs2 Donovan {DON_VS2:#x}) at {m['frames']}")

# ── 2. ours must EQUAL native at the same level, having selected Donovan ─
for L in LEVELS:
    for st in STR:
        m = measure(f'our_{st}_L{L:02d}'); n = nat[(st, L)]
        need(m['p1'] == DON, f"OURS {st} level {L}: P1 +0x60 = {m['p1']:#x}, Donovan {DON:#x} (bases.tsv) — "
                             f"any other character is the #114 artefact")
        if m['p1'] != DON: continue
        need(shape(m) == shape(n) and m['held'],
             f"OURS {st} level {L}: {m['n']}h/{m['dmg']}d at {m['frames']} held={m['held']} "
             f"== native {n['n']}h/{n['dmg']}d at {n['frames']}")

# ── 3. must-fire control: the #114 artefact ─────────────────────────────
c = measure('ctl')
if c['p1'] != JEDAH:
    print(f"CONTROL DEAD: jedah-artefact — control P1 +0x60 = {c['p1']:#x}, expected vanilla Jedah {JEDAH:#x}"); fails.append("jedah-artefact dead")
elif (c['n'], c['dmg']) == (nat[('HP', 6)]['n'], nat[('HP', 6)]['dmg']):
    print("CONTROL DEAD: jedah-artefact — the control matched Donovan's HP shape, so the assertions cannot discriminate"); fails.append("jedah-artefact dead")
else:
    print(f"CONTROL FIRED: jedah-artefact — pristine vsavj selects JEDAH ({c['n']}h/{c['dmg']}d, "
          f"held={c['held']}); accepted as ours (the mode) the gate FAILs")

# ── 4. the engine at a matched level and a pinned RNG, on vanilla content ─
def drain(leg):
    d = os.path.join(work, leg); prev=None; hit=None; vals=[]
    for f in range(2600, 2801):
        p = os.path.join(d, f'dump_{f}_ff8800.bin')
        if not os.path.exists(p): continue
        b = open(p,'rb').read(); hp = u16(b,0x50)
        if prev is not None and hp < prev and hit is None: hit = f
        prev = hp
        if hit and f >= hit: vals.append(b[0x5c])
    return (vals[0], len([v for v in vals[:20] if v > 0])) if hit else None
DRAIN = {6: (11, 10), 8: (11, 9)}
got = {}
for L in LEVELS:
    s2, sj = drain(f'van_vs2_L{L:02d}'), drain(f'van_vsavj_L{L:02d}')
    got[L] = s2
    need(s2 is not None and s2 == sj == DRAIN[L],
         f"ENGINE level {L}: vanilla Victor freeze (start, frames draining) vsav2 {s2} == vsavj {sj} (frozen {DRAIN[L]})")
need(got[6] is not None and got[8] is not None and got[6][1] != got[8][1],
     f"ENGINE: the level is live — the drain takes {got[6] and got[6][1]} frames at level 6 and {got[8] and got[8][1]} at level 8")

# ── 5. THE CEILING: at maximum press rate ours must equal native ─────────
CEIL = {'LP': (5, 9), 'MP': (9, 13), 'HP': (11, 15), 'ES': (16, 20)}
for L in LEVELS:
    for st in STR:
        n = measure(f'nat_{st}_ceil_L{L:02d}'); o = measure(f'our_{st}_ceil_L{L:02d}')
        need(n['p1'] == DON_VS2 and (n['n'], n['dmg']) == CEIL[st],
             f"CEILING native {st} level {L}: {n['n']}h/{n['dmg']}d (frozen {CEIL[st]}) P1 {n['p1']:#x}")
        need(o['p1'] == DON and shape(o) == shape(n),
             f"CEILING ours {st} level {L}: {o['n']}h/{o['dmg']}d at {o['frames']} == native at {n['frames']} P1 {o['p1']:#x}")

# THE CEILING SCRIPT IS LIVE: the one-on/one-off mash used everywhere before
# 14z-127 is NOT the ceiling (it leaves a dead frame). If the no-mash ES and the
# ceiling ES agreed, the ceiling script would be doing nothing.
need(CEIL['ES'][0] > nat[('ES', 6)]['n'],
     f"the ceiling mash is live — native ES {nat[('ES', 6)]['n']}h no-mash -> {CEIL['ES'][0]}h at max press rate")

# ── MUST-FIRE CONTROLS, in-gate ─────────────────────────────────────────
d = measure('nat_LP_ceil_default'); dl, dr, _ = pins('nat_LP_ceil_default', 2600)
o6 = measure('our_LP_ceil_L06')
if dl == 8 and dr == 0 and shape(d) != shape(o6):
    print(f"CONTROL FIRED: unmatched-modes — native LP at the ceiling at vsav2's default level {dl} lands "
          f"{d['n']}h/{d['dmg']}d at {d['frames']}, ours at level 6 {o6['n']}h/{o6['dmg']}d at {o6['frames']}: "
          f"comparing unmatched levels FAILs")
else:
    print(f"CONTROL DEAD: unmatched-modes — the default-level native leg reads level {dl}, RNG {dr:04x}, "
          f"{shape(d)}; ours at level 6 {shape(o6)}: the gate cannot be shown to see the level"); fails.append("unmatched-modes dead")
un, uo = measure('nat_MP_L06_unpinned'), measure('our_MP_L06_unpinned')
rn, ro = pins('nat_MP_L06_unpinned', 2600)[1], pins('our_MP_L06_unpinned', 2600)[1]
if shape(un) != shape(uo) and (rn, ro) != (0, 0):
    print(f"CONTROL FIRED: unpinned-rng — MP no-mash at level 6 with the RNG unpinned (native {rn:04x}, ours {ro:04x} "
          f"at 2600): native {un['n']}h at {un['frames']}, ours {uo['n']}h at {uo['frames']} — without the pin the legs part (#142)")
else:
    print(f"CONTROL DEAD: unpinned-rng — unpinned native {shape(un)}, ours {shape(uo)}, RNG {rn:04x}/{ro:04x}: "
          f"the gate cannot be shown to see the RNG"); fails.append("unpinned-rng dead")
# WHY they part (#142): on the frame after the fourth hit (tap frame 2667) the
# RNG-picked update order sets the attacker's freeze before its reducer on
# native and after it on ours
fn, fo = freeze_writes('tap_nat_MP_L06_unpinned', 2667), freeze_writes('tap_our_MP_L06_unpinned', 2667)
need((fn, fo) == ([3, 4, 3], [3, 2, 4]),
     f"#142's mechanism, unpinned MP at level 6: the attacker's +0x5C writes on tap frame 2667 are native {fn} "
     f"(set, then reducer) and ours {fo} (reducer, then set) — frozen [3, 4, 3] / [3, 2, 4]")

if fails:
    print(f"FAIL: test_don_immortal_native — {len(fails)} assertion(s) failed")
    sys.exit(1)
EOF2
echo "PASS: 421+P matches native in count, damage and hit frames at every strength, no-mash and at the mash ceiling, at speed levels 6 and 8 with the RNG pinned"
