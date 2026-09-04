#!/bin/sh
# audit_tenant_throw_geometry.sh — PHOBOS'S THREE THROWS, OURS vs NATIVE VS2
# (14z-131, maintainer-directed 2026-09-04).
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
# thing worth knowing. Frozen with its exact deltas; the mechanism is an open
# KNOWLEDGE item in STATE, not a defect.
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
# 6 MAME runs, 2 at a time, ~12 min.
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged23] [VICTIM=03]
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
BUILD="${BUILD:-build/m3b_merged23}"
VICTIM="${VICTIM:-03}"
ATT="${ATT:-10}"            # Phobos/Huitzil as the thrower
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
JOBS="${JOBS:-6}"
# THE ROSTER: 15 vanilla + the 3 tenants. 0x0B is Zabel's shared special slot
# and 0x12 is Dark Gallon — neither is a selectable roster victim here.
VICTIMS="${VICTIMS:-00 01 02 03 04 05 06 07 08 09 0a 0c 0d 0e 0f 10 11 13}"

_n=0
# NB plain $VICTIMS: this script is #!/bin/sh, where a bare $var DOES
# word-split. (An interactive zsh does NOT — that is the [[bash-tool-shell-is-zsh]]
# trap, and it bit the ad-hoc sweep that produced these numbers, twice.)
for vic in $VICTIMS; do
    for spec in "std:judge/02_throw.rpl:3000:3260:" \
                "cs:hui/80_hui_grab_2p.rpl:3145:3375:" \
                "es:hui/97_hui_grab_es_2p.rpl:3140:3400:m"; do
        nm=${spec%%:*}; _r=${spec#*:}; rpl=${_r%%:*}; _r=${_r#*:}
        lo=${_r%%:*}; _r=${_r#*:}; hi=${_r%%:*}; mt=${_r#*:}
        for leg in ours native; do
            d="$W/${vic}_${nm}_${leg}"; mkdir -p "$d/sbx"
            if [ "$leg" = ours ]; then _s=vsavjw; _rp="$REPO/$BUILD/rompath;$ROMDIR"
            else                      _s=vsav2;  _rp="$ROMDIR"; fi
            pk="1400:ff8782:$ATT;1450:ff8782:$ATT;1500:ff8782:$ATT"
            pk="$pk;1400:ff8b82:$vic;1450:ff8b82:$vic;1500:ff8b82:$vic"
            [ -n "$mt" ] && pk="$pk;2900:ff8509:09;3000:ff8509:09;3100:ff8509:09"
            df="$(python3 -c "print(';'.join(f'{f}:ff8410-ff8418;{f}:ff8810-ff8818;{f}:ff881c-ff8820;{f}:ff8934-ff8935;{f}:ff8509-ff850a;{f}:ff8850-ff8852' for f in range($lo,$hi)))")"
            ( cd "$d" && REPLAY="$REPO/tests/replays/$rpl" POKES="$pk" DUMPS="$df" \
              CHECKSUM_OUT="$d/out.log" MAME_SANDBOX="$d/sbx" MAME_ROMPATH="$_rp" \
              "$REPO/tools/run_mame.sh" "$_s" \
              -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/mame.log" 2>&1 ) &
            _n=$((_n + 1))
            [ $((_n % JOBS)) -eq 0 ] && wait
        done
    done
done
wait
echo "== ran $_n legs ($(echo $VICTIMS | wc -w | tr -d ' ') victims x 3 throws x 2), JOBS=$JOBS"

python3 - "$W" "$VICTIMS" "$BUILD" <<'PY' || fail=1
import glob, re, struct, sys, json
W, VICTIMS, BUILD = sys.argv[1], sys.argv[2].split(), sys.argv[3]
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
        out.append(dict(cap=cap, hp=hp, stk=stk, pose=lut.get(ptr, '?'),
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
FROZEN = {
 'std': dict(tail=(1, 0), arc={64}, es=False, dmg={'10': (15, 14), '13': (14, 15)}),
 'cs':  dict(tail=(0, 0), arc={278,284,287,288,290,291,295,296,298,306,311}, es=False, dmg={'0a': (19, 20), '10': (20, 19), '13': (19, 20)}),
 'es':  dict(tail=(0, 1), arc={380,386,389,390,392,393,397,398,400,408,413}, es=True,  dmg={'10': (20, 19), '13': (19, 20)}),
}
NAMES = {'std': 'standard throw 6+HP', 'cs': 'circuit scrapper 63214+MP',
         'es': 'ES circuit scrapper 63214+2P'}
bad = 0
for nm in ('std', 'cs', 'es'):
    f = FROZEN[nm]
    order_bad, unres, tails, dmg_got, nohold, es_dead, cad = [], [], set(), {}, [], [], []
    arcs = {}
    for vic in VICTIMS:
        o, n = series(f"{vic}_{nm}", 'ours', int(vic, 16)), series(f"{vic}_{nm}", 'native', int(vic, 16))
        so, sn = states(o), states(n)
        ko, kn = [k for k, _ in so], [k for k, _ in sn]
        if sum(d for _, d in so) < 10 or sum(d for _, d in sn) < 10:
            nohold.append(vic); continue
        if f['es'] and (len({e['stk'] for e in o}) < 2 or len({e['stk'] for e in n}) < 2):
            es_dead.append(vic); continue
        if any(k[0] == '?' for k in ko + kn):
            unres.append(vic)
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
            arcs.setdefault(leg, set()).add((max(fl) - min(fl)) if fl else None)
    print(f"== {NAMES[nm]} ==")
    if nohold or es_dead:
        print(f"  FAIL: no hold for {nohold}; ES never spent a stock for {es_dead} — VOID")
        bad += 1; print(); continue
    if unres:
        print(f"  FAIL: unresolved pose pointers for victims {unres} — the RESOLVER is"
              f"\n        wrong for them, not the build. Do not read the verdicts below."); bad += 1
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
        print(f"  ok: total damage identical except the frozen residue {f['dmg']} (OPEN, see STATE)")
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
    if ao != an:
        print(f"  FAIL: post-release arc peaks DIFFER between legs:"
              f" ours={sorted(ao)} native={sorted(an)}"); bad += 1
    elif ao != f['arc']:
        print(f"  FAIL: arc peak set moved: {sorted(ao)}, frozen {sorted(f['arc'])}"); bad += 1
    else:
        print(f"  ok: post-release arc peaks identical on both legs for every victim"
              f" ({len(ao)} distinct value(s), frozen)")
    print(f"  cadence: ours/native hold ratio {min(cad):.3f}-{max(cad):.3f}"
          f" — the ruled host-engine rate (#114), reported, not gated")
    print()
sys.exit(1 if bad else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: tenant throw geometry"; exit 1; }
echo "PASS: Phobos's three throws match native VS2 geometry (frozen 14z-131)"
