#!/bin/sh
# audit_tenant_throw_geometry.sh — THE TENANTS AS THROWERS, OURS vs NATIVE VS2
# (14z-131, maintainer-directed 2026-09-04; Pyron and Donovan joined and the level pinned 14z-193, #230).
#
# WHAT: Phobos's three throws (6+HP, Circuit Scrapper, ES Circuit Scrapper) and Pyron's and Donovan's
#   standard throw, ours vs native vs2, for all 18 roster victims, at the MATCHED speed level and a
#   pinned RNG: the held victim traverses the SAME ordered (pose, dx, dy) states in the same order on
#   both legs, the end-of-hold tail is one uniform shape per throw, and damage is compared as totals per
#   victim — dwell reported, never asserted.
# HOW: the same replay per throw and victim on both legs on MAME (90 cells, JOBS-way parallel), level 06
#   and RNG word 0000 poked on both legs (the parity gates' ruled equalised input), every frame of the
#   hold collapsed into the ordered state sequence with dwell counts; pose indexes resolved through each
#   game's own anim_index_c (pixels deliberately not compared: two generations of the victim's art).
# EXPECTS: 18/18 identical ordered states per throw, tail (0,0) on every throw, the Sasquatch damage
#   residue cells as frozen (vanilla's own defense row); a red is a state missing, reordered, a tail or a
#   damage cell moved.
#
# MUST-FIRE: perturbed-copy: arc-swap — Pyron's standard throw with two victims' native post-release arcs exchanged (the legs' arc SETS unchanged) must be flagged by the per-victim arc check, and the gate must FAIL (mode: the exchange is applied to the real measurement)
# MUST-FIRE: known-bad: wrong-thrower — Victor (0x03) poked into Donovan's slot on the ours leg must hold a +0x60 base other than Donovan's, and the identity check must FAIL (mode: every ours Donovan leg runs Victor)
# MUST-FIRE: known-bad: unpinned-level — Donovan's standard throw with the NATIVE leg's level pin withheld (vsav2's default TURBO against vsavj's NORMAL) must diverge in hold order from ours, and the gate must FAIL (mode: every native leg runs unpinned)
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lua/replay.lua tests/replays/
#   tools/run_mame.sh tools/setup_mame.sh tests/expected/roster_pairings/bases.tsv tests/lib/controls.sh
#
# THE ASK, verbatim in substance: *"there are throws that have been
# historically problematic with the VS2 tenants as THROWERS, not victims,
# namely Phobos' throws: 4/6 + MP/HP at contact (standard throw); 63214 +
# MP/HP at contact (command throw 'circuit scrapper'); 63214 + 2 punches at
# contact (ES version). These have all had their share of corrections... and
# even now I am not 100% sure they are identical both mechanically and
# visually to their VS2 versions... these throws involve mostly POSITION of
# the victim and not a victim's changing sprite."*
#
# So the observable is the VICTIM'S POSITION, and the reference is NATIVE
# VS2 — the tenants come from there, so it is the vanilla reference for them
# even though it is not VS. Both legs run the SAME replay with the SAME
# attacker and the SAME victim; nothing here compares one throw to another.
#
# WHAT IS MEASURED, per throw, on both legs. NOTE THE COMPARISON IS ORDERED,
# not a set — the maintainer's own critique of the first cut (2026-09-04:
# "we have but 5 frames for moves that last many tens of frames... it might be
# a sample bias"). Every frame of the hold is sampled and collapsed into the
# ORDERED sequence of (pose, dx, dy) states with dwell counts:
#   * THE HOLD TRAJECTORY — the victim's position relative to the attacker
#     (what the capture positioner at PRG:0x02802E writes, [VSE-44]) together
#     with its pose-record index, IN ORDER. Order and identity are asserted;
#     DWELL is reported and NOT asserted, because dwell is where the host
#     engine's rate difference lives.
#   * DAMAGE as (amount, POSE) pairs — never as frame numbers, for the same
#     reason.
#   * the POST-RELEASE ARC height — the recorded historical suspicion.
#
# WHAT IS DELIBERATELY *NOT* COMPARED: the victim's PIXELS. Victor in our
# build is VS's Victor; in native vsav2 he is VS2's Victor, and those are
# different generations of his art. A pixel difference in the victim is a
# cross-game fact, not evidence about our port. The pose INDEX is resolved
# through each game's OWN anim_index_c, so a match means "the same logical
# pose slot", which is the comparable thing.
#
# *** SUPERSEDED 14z-193 (#230): the table below was measured UNPINNED, each game at its default speed level.
# At the matched level every tail is (0,0) and the hold ratio 1.000; the frozen values now live in the
# verdict's FROZEN dict, keyed by thrower and throw. Kept as the 14z-131 record. ***
# THE RESULT THIS FREEZES — ALL 18 ROSTER VICTIMS (widened 14z-131 after the
# maintainer asked what the sweep costs: measured, Victor alone is 27.7 s and
# all eighteen is 186 s at 6-way parallelism, so the wider gate is ~6.7x the
# time for 18x the coverage and there was no reason not to take it):
#
#   throw               ordered states       tail          damage
#   standard 6+HP       18/18 IDENTICAL      ours +1       2 victims +/-1
#   circuit scrapper    18/18 IDENTICAL      none          3 victims +/-1
#   ES circuit scrapper 18/18 IDENTICAL      native +1     2 victims +/-1
#
# EVERY victim traverses the SAME states in the SAME order on all three
# throws, and the end-of-hold tail is UNIFORM ACROSS ALL EIGHTEEN — which is
# why it is frozen as one shape per throw rather than as 54 literals, and is
# itself evidence the tail is a boundary/cadence effect rather than
# per-character data.
#
# THE DAMAGE RESIDUE, and it is an OPEN FINDING the widening surfaced (the
# single-victim gate could never have seen it — Victor is not among them):
# 5 of 54 victim/throw cells differ by EXACTLY +/-1 total damage, and the sign
# is PER VICTIM, not per throw:
#     victim 0x10 (Phobos)   ours +1 on standard, CS and ES
#     victim 0x13 (Donovan)  ours -1 on standard, CS and ES
#     victim 0x0A (Sasquatch) ours -1 on CS only
# Ruled out already: victim starting HP is 288 on both legs for every victim,
# so it is not a max-HP effect; and bank_map declares no per-character defence
# or damage-scaling table, so the scalar is somewhere this map does not model.
# RULED WITHIN TOLERANCE (maintainer, 2026-09-04): "+/- 1 damage is within
# tolerances... interesting to root-cause it to deepen our understanding of
# the engines though so let's keep that open for a future session." So a RED
# on this row is NOT "a damage bug" — it is "the residue moved", which is the
# thing worth knowing. Frozen with its exact deltas. THE MECHANISM, NAMED
# 14z-145 (tests/audit_defense_row_residue.sh, a read watch on both legs): the
# defender-side DEFENSE CURVE row the victim's id selects (vsavj 0x0B8940 /
# vs2 0x0D2ABE, column = the attacker's id) differs between the games on EXACTLY
# these three roster ids and no other — rows 0x10/0x13 are content-SWAPPED (the
# port kept vanilla's rows by the 2026-08-14 ruling, SUPERSEDED 2026-09-18 by "take the vs2 rows" —
# the fix re-freezes this gate's tenant cells; defense_rows.md: Phobos rides Bulleta's
# curve, Donovan Victor's, hence the opposite signs) and row 0x0A is a
# CROSS-GENERATION retune of Sasquatch. Ours answers d3 = 0/2/1 where native
# answers 2/0/0; the control victim answers 2/2. Not a defect; the residue
# is the observable of the 2026-08-14 defense-row ruling.
#
# WHAT THIS REFUTED. `80_hui_grab_2p.rpl`'s own header said "only the victim
# throw-arc HEIGHT differs (alias physics, queued)". It does not: the arcs are
# identical on all three throws. The claim predates the 14z-67 throw_arc_tables
# fix and was never retracted; it is retracted in the replay now.
#
# LIVENESS, AND IT IS NOT OPTIONAL:
#   * every leg must actually HOLD the victim, or its verdict is void
#     ([VSP-137] — a soak must assert the mechanism it exists to exercise);
#   * the ES leg must show P1's STOCK DROP 9 -> 8. Without meter the ES input
#     degrades SILENTLY to the MP grab and returns numbers identical to
#     replay 80 — measured, and the whole reason replay 97 carries a meter
#     poke ([VSP-131], [VSP-123]).
#
# ON THE VICTIM SAMPLE (the maintainer's own question: "do we test all victims
# or only a sample and if it's a sample how to determine it"). ONE victim is
# used here, Victor 0x03, deliberately: this gate's subject is the ATTACKER's
# geometry, and the capture block's per-victim head is what the #104 work
# already covers from the other side (audit_don_grab_pose sweeps
# VICTIMS="01 13 10 11" — a legacy victim plus each tenant row). Widening
# this gate to all four victims is a VICTIMS= loop away if ever wanted; it
# would quadruple a ~12 min run to re-measure an axis already gated.
#
# 90 cells x 2 legs + 18 control legs; ~2.5 min on ERIS at JOBS=10 for Phobos's 108 legs alone.
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged31] [THROWERS="10 11 13"] [VICTIMS="..."] [JOBS=6]
#        tests/audit_tenant_throw_geometry.sh
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
# AND THE MAME BINARY IS PINNED (14z-133): the "ours" leg boots vsavjw, which
# only the WIDE source build knows. run_mame.sh falls back to `mame` on PATH
# (Homebrew's: "Unknown system 'vsavjw'"), so in a shell that does not export
# MAME_BIN — the emulator runner exports none — the ours leg produced NO
# DUMPS and the liveness check reported "held frames ours=0". First seen on
# the M16 freeze sweep, the gate's first run under the runner.
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged31}"
# THE THROWERS (#230, 14z-193): Phobos 0x10 with his three throws, Pyron 0x11 and Donovan 0x13 with the
# standard throw (the throw `audit_pyron_capture_block` and `audit_throw_tech` run, one cell each until now).
THROWERS="${THROWERS:-10 11 13}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
# THE EQUALISED INPUT (#230, 14z-193; the standing ruling of 2026-09-25, 14z-182, on the parity gates'
# per-frame level and RNG pins, after #135/14z-158 found native vsav2 defaults to TURBO, level 8, and
# vsavj to NORMAL, 6). Until 14z-193 this gate ran each game at its default: the frozen end-of-hold tails
# (1,0) and (0,1) and the "cadence" ratio ~1.07 were THAT, not the engines — pinned, every throw's tail is
# (0,0) and the hold ratio 1.000 (build/agent193/t230/). Both legs: level 06 from frame 2000, the RNG
# word 0000 (its fixed point, #183) from 2363 — audit_move_parity.sh's pins. ONE function builds a leg's
# pokes, so the control withholds exactly what the gate asserts ([VSP-181]).
pokes_for() {  # pokes_for <att> <vic> <meter: m or empty> <leg> <unpinned: 1 or empty>
    _p="1400:ff8782:$1;1450:ff8782:$1;1500:ff8782:$1;1400:ff8b82:$2;1450:ff8b82:$2;1500:ff8b82:$2"
    [ -n "$3" ] && _p="$_p;2900:ff8509:09;3000:ff8509:09;3100:ff8509:09"
    _p="$_p;2363-3400:ff80d4:0000"
    if [ "$4" = native ] && [ -n "$5" ]; then printf '%s' "$_p"; else printf '%s;2000-3400:ff8116:06' "$_p"; fi
}
specs_for() {  # specs_for <att>: the throws this thrower runs
    if [ "$1" = 10 ]; then echo "std:judge/02_throw.rpl:3000:3260: cs:hui/80_hui_grab_2p.rpl:3145:3375: es:hui/97_hui_grab_es_2p.rpl:3140:3400:m"
    else echo "std:judge/02_throw.rpl:3000:3260:"; fi
}
UNPIN_ALL=""; vs_ctl_is unpinned-level && UNPIN_ALL=1
# CONTROL wrong-thrower (run 2026-10-06-709 Q4): Victor's id (0x03) poked into Donovan's slot on the OURS leg
WRONG13=""; vs_ctl_is wrong-thrower && WRONG13=1
JOBS="${JOBS:-6}"
# THE ROSTER: 15 vanilla + the 3 tenants. 0x0B is Zabel's shared special slot
# and 0x12 is Dark Gallon — neither is a selectable roster victim here.
VICTIMS="${VICTIMS:-00 01 02 03 04 05 06 07 08 09 0a 0c 0d 0e 0f 10 11 13}"

_n=0
# NB plain $VICTIMS: this script is #!/bin/sh, where a bare $var DOES
# word-split. (An interactive zsh does NOT — that is the [[bash-tool-shell-is-zsh]]
# trap, and it bit the ad-hoc sweep that produced these numbers, twice.)
run_leg() {  # run_leg <dir> <leg> <rpl> <pokes> <lo> <hi>
    mkdir -p "$1/sbx"
    if [ "$2" = ours ]; then _s=vsavjw; _rp="$REPO/$BUILD/rompath;$ROMDIR"
    else                     _s=vsav2;  _rp="$ROMDIR"; fi
    _df="$(python3 -c "print(';'.join(f'{f}:ff8410-ff8418;{f}:ff8810-ff8818;{f}:ff881c-ff8820;{f}:ff8934-ff8935;{f}:ff8509-ff850a;{f}:ff8850-ff8852;{f}:ff8406-ff8408;{f}:ff8460-ff8464' for f in range($5,$6)))")"
    ( cd "$1" && REPLAY="$REPO/tests/replays/$3" POKES="$4" DUMPS="$_df" \
      CHECKSUM_OUT="$1/out.log" MAME_SANDBOX="$1/sbx" MAME_ROMPATH="$_rp" \
      "$REPO/tools/run_mame.sh" "$_s" \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$1/mame.log" 2>&1 ) &
    _n=$((_n + 1))
    [ $((_n % JOBS)) -eq 0 ] && wait
    return 0
}
for att in $THROWERS; do
for vic in $VICTIMS; do
    for spec in $(specs_for "$att"); do
        nm=${spec%%:*}; _r=${spec#*:}; rpl=${_r%%:*}; _r=${_r#*:}
        lo=${_r%%:*}; _r=${_r#*:}; hi=${_r%%:*}; mt=${_r#*:}
        for leg in ours native; do
            _pid="$att"; [ -n "$WRONG13" ] && [ "$att" = 13 ] && [ "$leg" = ours ] && _pid=03
            run_leg "$W/${att}_${vic}_${nm}_${leg}" "$leg" "$rpl" "$(pokes_for "$_pid" "$vic" "$mt" "$leg" "$UNPIN_ALL")" "$lo" "$hi"
        done
    done
done
done
# THE CONTROL's legs (normal runs only): Donovan's standard throw, NATIVE leg with the level pin
# withheld — measured 14z-193: unpinned, all 18 victims' hold orders diverge from ours.
if [ -z "${VS_CTL:-}" ] && echo " $THROWERS " | grep -q " 13 "; then
    # wrong-thrower's leg: Victor thrown in Donovan's ours slot, one victim
    run_leg "$W/ctlw_00_std_ours" ours judge/02_throw.rpl "$(pokes_for 03 00 "" ours "")" 3000 3260
    for vic in $VICTIMS; do
        run_leg "$W/ctl_${vic}_std_native" native judge/02_throw.rpl "$(pokes_for 13 "$vic" "" native 1)" 3000 3260
    done
fi
wait
echo "== ran $_n legs ($(echo $THROWERS | wc -w | tr -d ' ') throwers x $(echo $VICTIMS | wc -w | tr -d ' ') victims; pinned level 06 and RNG 0000 on both legs$( [ -n "$UNPIN_ALL" ] && echo ' — EXCEPT the native level, CONTROL unpinned-level')), JOBS=$JOBS"

VS_CTL="${VS_CTL:-}" python3 - "$W" "$VICTIMS" "$BUILD" "$THROWERS" <<'PY' > "$W/verdict.txt" || fail=1
import glob, re, struct, sys, json
W, VICTIMS, BUILD, THROWERS = sys.argv[1], sys.argv[2].split(), sys.argv[3], sys.argv[4].split()
vj = open('build/out/vsavj_data.bin', 'rb').read()
v2 = open('build/out/vsav2_data.bin', 'rb').read()
C, ORI_VJ, ORI_V2 = 0x0BCFFA, 0x0BD0FA, 0x0D7298
pl = json.load(open(f"{BUILD}/patch/placements.json"))["regions"]
def _g(r, k):
    x = pl[r][k]; return int(x, 16) if isinstance(x, str) else x
REG = {0x10: 'anim@huitzil', 0x11: 'anim@pyron', 0x13: 'anim'}

# WHICH TABLE RESOLVES A POSE POINTER depends on the LEG *and* the VICTIM, and
# getting it wrong reports a real hold as "not a table entry" — the trap
# audit_don_grab_pose documents and that this gate walked into on its first
# widened run: all three TENANT victims came back "divergent" with unresolved
# poses, which was the resolver, not the build.
def lut_for(leg, vic):
    if leg == 'ours' and vic < 0x10:
        tbl, img, sh = struct.unpack_from('>I', vj, C + vic * 4)[0], vj, 0
    else:
        tbl = struct.unpack_from('>I', v2, C + (ORI_V2 - ORI_VJ) + vic * 4)[0]
        img = v2
        r = REG.get(vic, 'anim')
        sh = (_g(r, 'dst') - _g(r, 'src')) if leg == 'ours' else 0
    return {tbl + struct.unpack_from('>H', img, tbl + 2 * i)[0] + sh: i for i in range(96)}

def series(tag, leg, vic):
    lut = lut_for(leg, vic); out = []
    for p in sorted(glob.glob(f"{W}/{tag}_{leg}/dump_*_ff8810.bin"),
                    key=lambda q: int(re.search(r'dump_(\d+)_', q).group(1))):
        fr = int(re.search(r'dump_(\d+)_', p).group(1))
        cap = (open(f"{W}/{tag}_{leg}/dump_{fr}_ff8934.bin", 'rb').read() or b'\0')[0]
        v = open(p, 'rb').read()
        a = open(f"{W}/{tag}_{leg}/dump_{fr}_ff8410.bin", 'rb').read()
        hp = struct.unpack_from('>H', open(f"{W}/{tag}_{leg}/dump_{fr}_ff8850.bin", 'rb').read(), 0)[0]
        ptr = struct.unpack_from('>I', open(f"{W}/{tag}_{leg}/dump_{fr}_ff881c.bin", 'rb').read(), 0)[0]
        stk = open(f"{W}/{tag}_{leg}/dump_{fr}_ff8509.bin", 'rb').read()[0]
        # THE ATTACKER'S MOVE (rule-checker run 2026-10-06-708 Q4): its id and its seq/sub on every frame, so a
        # hold is attributed to the THROWER and to ONE move, the same on both legs — not to "a grab that matches"
        _sq = open(f"{W}/{tag}_{leg}/dump_{fr}_ff8406.bin", 'rb').read() or b'\0\0'
        # THE ATTACKER'S IDENTITY (run 2026-10-06-709 Q3): NOT RAM:$FF8782, which this gate itself pokes, but the
        # +0x60 character-data base the GAME loaded for it (RAM:$FF8460), checked against each game's own table
        _b = open(f"{W}/{tag}_{leg}/dump_{fr}_ff8460.bin", 'rb').read()
        abase = struct.unpack_from('>I', _b, 0)[0] if len(_b) >= 4 else None
        out.append(dict(cap=cap, hp=hp, stk=stk, pose=lut.get(ptr, '?'), abase=abase, seq=(_sq[0], _sq[1]),
                        dx=struct.unpack_from('>h', v, 0)[0] - struct.unpack_from('>h', a, 0)[0],
                        dy=struct.unpack_from('>h', v, 4)[0] - struct.unpack_from('>h', a, 4)[0]))
    return out

def states(s):
    r = []
    for e in s:
        if not e['cap']:
            continue
        k = (e['pose'], e['dx'], e['dy'])
        if r and r[-1][0] == k: r[-1][1] += 1
        else: r.append([k, 1])
    return r

# FROZEN 14z-131 over all 18 roster victims. `tail` is (extra_ours,
# extra_native) and is UNIFORM across every victim, so it is one shape per
# throw. `dmg` names the only victims whose TOTAL damage differs, with the
# exact (ours, native) pair — an OPEN finding, frozen so it cannot drift.
# RE-FROZEN 14z-170 (the M19 freeze): the ±1 total-damage residue of victims 0x10 and 0x13 is GONE — it was
# the defense-curve row the victim's id selects (root-caused 14z-145), and the ruled fix gave Phobos and
# Donovan vs2's own rows. 0x0a (Sasquatch) stays: vanilla vsavj's own row differs from vs2's.
# RE-FROZEN 14z-193 (#230) at the MATCHED level and pinned RNG: every tail is (0,0) — the (1,0) and (0,1)
# frozen 14z-131 were the unmatched speed levels — and Pyron and Donovan join with the standard throw. Their
# arcs vary per victim but never between legs; Pyron's damage differs only on Sasquatch (vanilla's row, as on
# Phobos's circuit scrapper). `seq` is the attacker's seq at the hold's FIRST captured frame (not every frame), the same on all
# 18 victims and both legs (rule-checker run 2026-10-06-708 Q4); the thrower is proved by its loaded +0x60 base (709 Q3); that it is the move NAMED rests on the replay's input,
# not a move table. Measured on ERIS (build/agent193/t230/).
FROZEN = {
 ('10', 'std'): dict(seq={2}, tail=(0, 0), arc={64}, es=False, dmg={}),
 ('10', 'cs'):  dict(seq={14}, tail=(0, 0), arc={278,284,287,288,290,291,295,296,298,306,311}, es=False, dmg={'0a': (19, 20)}),
 ('10', 'es'):  dict(seq={16}, tail=(0, 0), arc={380,386,389,390,392,393,397,398,400,408,413}, es=True,  dmg={}),
 ('11', 'std'): dict(seq={2}, tail=(0, 0), arc={64,65,68,69,71,72,76,81,82,85,87,101}, es=False, dmg={'0a': (13, 14)}),
 ('13', 'std'): dict(seq={4}, tail=(0, 0), arc={64,68}, es=False, dmg={}),
}
WHO = {'10': 'Phobos', '11': 'Pyron', '13': 'Donovan'}
# each thrower's +0x60 base as each GAME holds it: ours from tests/expected/roster_pairings/bases.tsv (derived from
# the merged image's own table PRG:0x0BD97A), native from vsav2's own table PRG:0x0D7B18 in its pristine image
BASE = {'ours': {}, 'native': {}}
for ln in open('tests/expected/roster_pairings/bases.tsv'):
    c = ln.rstrip('\n').split('\t')
    if len(c) >= 3 and c[0].startswith('0x') and not ln.startswith('#'):
        BASE['ours'][int(c[0], 16)] = int(c[2], 16)
for a in (0x10, 0x11, 0x13):
    BASE['native'][a] = struct.unpack_from('>I', v2, 0x0D7B18 + a * 4)[0]
NAMES = {'std': 'standard throw 6+HP', 'cs': 'circuit scrapper 63214+MP',
         'es': 'ES circuit scrapper 63214+2P'}
bad = 0
import os
CTL, ARCV = os.environ.get('VS_CTL', ''), {}
for att, nm in [k for k in FROZEN if k[0] in THROWERS]:
    f = FROZEN[(att, nm)]
    order_bad, unres, tails, dmg_got, nohold, es_dead, cad = [], [], set(), {}, [], [], []
    who_bad, moves, seen = [], {'ours': set(), 'native': set()}, {'ours': set(), 'native': set()}
    arcs, arc_v = {}, {}
    for vic in VICTIMS:
        o, n = series(f"{att}_{vic}_{nm}", 'ours', int(vic, 16)), series(f"{att}_{vic}_{nm}", 'native', int(vic, 16))
        so, sn = states(o), states(n)
        ko, kn = [k for k, _ in so], [k for k, _ in sn]
        if sum(d for _, d in so) < 10 or sum(d for _, d in sn) < 10:
            nohold.append(vic); continue
        if f['es'] and (len({e['stk'] for e in o}) < 2 or len({e['stk'] for e in n}) < 2):
            es_dead.append(vic); continue
        if any(k[0] == '?' for k in ko + kn):
            unres.append(vic)
        # the attacker on every captured frame: the named thrower, and its seq at the FIRST captured frame
        for leg, s_ in (('ours', o), ('native', n)):
            held = [e for e in s_ if e['cap']]
            seen[leg] |= {e['abase'] for e in held}
            if any(e['abase'] != BASE[leg][int(att, 16)] for e in held):
                who_bad.append(f"{vic}/{leg}")
            moves[leg].add(held[0]['seq'][0])
        c = min(len(ko), len(kn))
        if ko[:c] != kn[:c]:
            order_bad.append(vic)
        tails.add((len(ko) - c, len(kn) - c))
        to = o[0]['hp'] - min(e['hp'] for e in o)
        tn = n[0]['hp'] - min(e['hp'] for e in n)
        if to != tn:
            dmg_got[vic] = (to, tn)
        cad.append(sum(d for _, d in so) / max(1, sum(d for _, d in sn)))
        for leg, s in (('ours', o), ('native', n)):
            fl = [e['dy'] for i, e in enumerate(s)
                  if not e['cap'] and any(x['cap'] for x in s[:i])]
            _pk = (max(fl) - min(fl)) if fl else None
            arcs.setdefault(leg, set()).add(_pk)
            arc_v.setdefault(vic, {})[leg] = _pk
    print(f"== {WHO[att]}: {NAMES[nm]} ==")
    if nohold or es_dead:
        print(f"  FAIL: no hold for {nohold}; ES never spent a stock for {es_dead} — VOID")
        bad += 1; print(); continue
    if unres:
        print(f"  FAIL: unresolved pose pointers for victims {unres} — the RESOLVER is"
              f"\n        wrong for them, not the build. Do not read the verdicts below."); bad += 1
    # IDENTITY and SEQ are two verdicts, each with its own line (rule-checker run 2026-10-06-710 Q1: one "ok" line
    # printed from the seq branch read as an identity pass under the wrong-thrower mode). The bases printed are the
    # ones MEASURED on the captured frames, beside the ones each game's table expects.
    _fmt = lambda xs: ','.join('0x%x' % x if x is not None else 'none' for x in sorted(xs, key=lambda v: -1 if v is None else v))
    if who_bad:
        print(f"  FAIL: identity — the attacker's loaded +0x60 base is not 0x{att}'s on every captured frame: {who_bad}; "
              f"measured ours {{{_fmt(seen['ours'])}}} native {{{_fmt(seen['native'])}}}"); bad += 1
    else:
        print(f"  ok: identity — on every captured frame of every victim the attacker's loaded +0x60 base is 0x{att}'s: "
              f"measured ours {{{_fmt(seen['ours'])}}} native {{{_fmt(seen['native'])}}} (tables: ours "
              f"0x{BASE['ours'][int(att, 16)]:x}, native 0x{BASE['native'][int(att, 16)]:x})")
    if moves['ours'] != moves['native'] or moves['ours'] != f['seq']:
        print(f"  FAIL: seq — the attacker's seq at the hold's first captured frame: ours {sorted(moves['ours'])} native "
              f"{sorted(moves['native'])}, frozen {sorted(f['seq'])}"); bad += 1
    else:
        print(f"  ok: seq — the attacker's seq at the hold's first captured frame is {sorted(f['seq'])} on every victim and both legs")
    if order_bad:
        print(f"  FAIL: hold trajectories diverge in ORDER for victims {order_bad}"); bad += 1
    else:
        print(f"  ok: {len(VICTIMS)}/{len(VICTIMS)} victims traverse the same states in the same order")
    if tails != {f['tail']}:
        print(f"  FAIL: end-of-hold tail not uniform / moved: saw {sorted(tails)}, frozen {f['tail']}"); bad += 1
    else:
        print(f"  ok: end-of-hold tail {f['tail']} (extra ours, extra native), uniform across all victims")
    if dmg_got != {k: tuple(v) for k, v in f['dmg'].items()}:
        print(f"  FAIL: total-damage residue moved: {dmg_got}, frozen {f['dmg']}"); bad += 1
    else:
        print(f"  ok: total damage identical except the frozen residue {f['dmg']} (Sasquatch's vanilla row; the tenants' residue fixed at M19)")
    # THE ARC — the check that refuted replay 80's "only the throw-arc HEIGHT
    # differs" claim. Kept when the gate widened; losing it would have quietly
    # dropped the one assertion that retired a nine-session-old suspicion.
    ao, an = arcs.get('ours', set()), arcs.get('native', set())
    # THE INVARIANT IS "ours == native", per throw across every victim. The
    # SET is frozen too, but note it is victim-DEPENDENT for cs/es: the
    # single-victim version of this gate froze `278`/`380`, which were
    # VICTOR's numbers, and widening is what exposed that as victim-specific
    # rather than a property of the throw. std's arc is the same 64 for all
    # eighteen; cs and es span eleven values each.
    # PER VICTIM (rule-checker run 2026-10-06-711 Q4): comparing the two legs' SETS let a victim's arc differ
    # between legs whenever its value appeared for some other victim; each victim's own pair is compared now.
    def swap2(av):  # the arc-swap perturbation: two victims' NATIVE arcs exchanged — the legs' SETS stay equal
        vs = [v for v in sorted(av) if av[v].get('native') is not None]
        pair = next(((a, b) for i, a in enumerate(vs) for b in vs[i + 1:] if av[a]['native'] != av[b]['native']), None)
        if not pair: return None
        cp = {v: dict(x) for v, x in av.items()}
        cp[pair[0]]['native'], cp[pair[1]]['native'] = av[pair[1]]['native'], av[pair[0]]['native']
        return cp
    if CTL == 'arc-swap' and (att, nm) == ('11', 'std'):
        arc_v = swap2(arc_v) or arc_v
    ARCV[(att, nm)] = arc_v
    arc_bad = {v: (a.get('ours'), a.get('native')) for v, a in arc_v.items() if a.get('ours') != a.get('native')}
    if arc_bad:
        print(f"  FAIL: post-release arc peak differs between legs for victims {arc_bad} (ours, native)"); bad += 1
    elif ao != an:
        print(f"  FAIL: post-release arc peaks DIFFER between legs:"
              f" ours={sorted(ao)} native={sorted(an)}"); bad += 1
    elif ao != f['arc']:
        print(f"  FAIL: arc peak set moved: {sorted(ao)}, frozen {sorted(f['arc'])}"); bad += 1
    else:
        print(f"  ok: post-release arc peak identical on both legs, victim by victim ({len(arc_v)} victims;"
              f" {len(ao)} distinct value(s) over them, frozen)")
    print(f"  cadence: ours/native hold ratio {min(cad):.3f}-{max(cad):.3f}"
          f" — at the matched level 1.000 was measured on every cell (14z-193); reported, not gated")
    print()
# THE CONTROL (normal runs): Donovan's standard throw with the native leg's level pin withheld must
# diverge in hold ORDER from ours on at least one victim (measured 14z-193: all 18).
ctl = sorted(glob.glob(f"{W}/ctl_*_std_native"))
if ctl:
    div = []
    for d in ctl:
        vic = re.search(r"ctl_(..)_std_native", d).group(1)
        ko = [k for k, _ in states(series(f"13_{vic}_std", 'ours', int(vic, 16)))]
        kn = [k for k, _ in states(series(f"ctl_{vic}_std", 'native', int(vic, 16)))]
        c = min(len(ko), len(kn))
        if not kn or ko[:c] != kn[:c] or len(ko) != len(kn):
            div.append(vic)
    print(f"CTLRESULT {'fired' if div else 'dead'} {len(div)} of {len(ctl)} victims diverge with the native level unpinned")
# THE arc-swap CONTROL (normal runs; run 2026-10-06-711 Q4): on Pyron's standard throw, two victims' native arcs
# exchanged must be flagged by the per-victim check while the two legs' SETS still compare equal.
if not CTL and ('11', 'std') in ARCV:
    av = ARCV[('11', 'std')]; sw = swap2(av)
    if sw is None:
        print("CTLARC dead no two victims with different native arcs to exchange")
    else:
        flagged = [v for v, a in sw.items() if a.get('ours') != a.get('native')]
        sets_equal = {a.get('ours') for a in sw.values()} == {a.get('native') for a in sw.values()}
        print(f"CTLARC {'fired' if flagged and sets_equal else 'dead'} two native arcs exchanged on Pyron's throw: "
              f"per-victim check flags {sorted(flagged)}, the legs' sets {'still equal' if sets_equal else 'differ'}")
if glob.glob(f"{W}/ctlw_00_std_ours"):
    held = [e for e in series("ctlw_00_std", 'ours', 0) if e['cap']]
    wrong = [e['abase'] for e in held if e['abase'] != BASE['ours'][0x13]]
    print(f"CTLWRONG {'fired' if held and wrong else 'dead'} Victor in Donovan's slot: {len(held)} held frames, "
          f"{len(wrong)} with a base other than Donovan's (0x{wrong[0]:x})" if wrong else
          f"CTLWRONG dead Victor in Donovan's slot: {len(held)} held frames, none with another base")
sys.exit(1 if bad else 0)
PY
cat "$W/verdict.txt" | grep -v -E '^CTL(RESULT|WRONG|ARC)'
_ca="$(grep '^CTLARC' "$W/verdict.txt" || true)"
_cr="$(grep '^CTLRESULT' "$W/verdict.txt" || true)"
_cw="$(grep '^CTLWRONG' "$W/verdict.txt" || true)"
if [ -z "${VS_CTL:-}" ] && echo " $THROWERS " | grep -q " 13 "; then
    case "$_cr" in
        "CTLRESULT fired "*) vs_ctl_fired unpinned-level "${_cr#CTLRESULT fired }" ;;
        *) vs_ctl_dead unpinned-level "${_cr:-no control verdict}" || fail=1 ;;
    esac
    case "$_cw" in
        "CTLWRONG fired "*) vs_ctl_fired wrong-thrower "${_cw#CTLWRONG fired }" ;;
        *) vs_ctl_dead wrong-thrower "${_cw:-no control verdict}" || fail=1 ;;
    esac
    case "$_ca" in
        "CTLARC fired "*) vs_ctl_fired arc-swap "${_ca#CTLARC fired }" ;;
        *) vs_ctl_dead arc-swap "${_ca:-no control verdict}" || fail=1 ;;
    esac
fi

[ "$fail" = 0 ] || { echo "FAIL: tenant throw geometry"; exit 1; }
echo "PASS: the tenants' throws match native VS2 geometry at the matched level (Phobos's three, Pyron's and Donovan's standard; re-frozen 14z-193)"
