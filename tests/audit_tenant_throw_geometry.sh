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
# THE RESULT THIS FREEZES (measured 14z-131, merged-m15 vs native vsav2,
# victim pinned to Victor 0x03 by early-window pokes):
#
#   throw                      ordered states        damage (amt @ pose)
#   standard 6+HP              29 vs 28, ours +1     14 @ 13   both legs
#   circuit scrapper 63214+MP  23 vs 23, IDENTICAL   19 @ 19   both legs
#   ES circuit scrapper        46 vs 47, native +1   2@21 2@21 15@19 both
#   ...and arc peaks 64 / 278 / 380, equal on both legs in all three.
#
# SO THE TRAJECTORIES TRAVERSE THE SAME STATES IN THE SAME ORDER, and every
# damage event lands for the same amount at the same POSE. The only structural
# differences are ONE extra end-of-hold state, in OPPOSITE directions
# (standard: ours reaches one more; ES: native reaches one more).
#
# THE CADENCE, measured here independently rather than assumed: ours holds 89
# frames to native's 82 (standard), 60 to 55 (CS), 130 to 120 (ES) — and on ES
# the damage offsets GROW through the move, +5 then +7 then +10 video frames,
# which is the signature of a RATE difference rather than a port defect. 130
# vs 120 is 8.3% slower against #114's documented ~1 frame per ~11 engine
# ticks (9.1%). That is the maintainer-ruled class (2026-09-02: "we must
# respect the fact that we are porting the character to a different engine and
# the engine, being vanilla vsav, takes precedence"), so dwell and frame
# numbers are REPORTED and never gated.
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
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged22] [VICTIM=03]
#        tests/audit_tenant_throw_geometry.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged22}"
VICTIM="${VICTIM:-03}"
ATT="${ATT:-10}"            # Phobos/Huitzil as the thrower
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

# throw : replay : first : last : extra pokes : frozen arc peak : ES?
SPECS="std:judge/02_throw.rpl:3000:3260::64:0
cs:hui/80_hui_grab_2p.rpl:3145:3375::278:0
es:hui/97_hui_grab_es_2p.rpl:3140:3400:;2900:ff8509:09;3000:ff8509:09;3100:ff8509:09:380:1"

for spec in $SPECS; do
    nm=$(echo "$spec" | cut -d: -f1); rpl=$(echo "$spec" | cut -d: -f2)
    lo=$(echo "$spec" | cut -d: -f3); hi=$(echo "$spec" | cut -d: -f4)
    for leg in ours native; do
        d="$W/${nm}_${leg}"; mkdir -p "$d/sbx"
        if [ "$leg" = ours ]; then _s=vsavjw; _rp="$REPO/$BUILD/rompath;$ROMDIR"
        else                      _s=vsav2;  _rp="$ROMDIR"; fi
        pk="1400:ff8782:$ATT;1450:ff8782:$ATT;1500:ff8782:$ATT"
        pk="$pk;1400:ff8b82:$VICTIM;1450:ff8b82:$VICTIM;1500:ff8b82:$VICTIM"
        case "$nm" in es) pk="$pk;2900:ff8509:09;3000:ff8509:09;3100:ff8509:09";; esac
        df="$(python3 -c "
print(';'.join(f'{f}:ff8410-ff8418;{f}:ff8810-ff8818;{f}:ff881c-ff8820;{f}:ff8934-ff8935;{f}:ff8509-ff850a;{f}:ff8850-ff8852'
                for f in range($lo,$hi)))")"
        ( cd "$d" && REPLAY="$REPO/tests/replays/$rpl" POKES="$pk" DUMPS="$df" \
          CHECKSUM_OUT="$d/out.log" MAME_SANDBOX="$d/sbx" MAME_ROMPATH="$_rp" \
          "$REPO/tools/run_mame.sh" "$_s" \
          -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/mame.log" 2>&1 ) &
    done
    wait
done

python3 - "$W" "$VICTIM" <<'PY' || fail=1
import glob, re, struct, sys
W, VIC = sys.argv[1], int(sys.argv[2], 16)
vj = open('build/out/vsavj_data.bin', 'rb').read()
v2 = open('build/out/vsav2_data.bin', 'rb').read()
C, DELTA = 0x0BCFFA, 0x0D7298 - 0x0BD0FA
TBL = {'ours': struct.unpack_from('>I', vj, C + VIC * 4)[0],
       'native': struct.unpack_from('>I', v2, C + DELTA + VIC * 4)[0]}
IMG = {'ours': vj, 'native': v2}

# FROZEN 14z-131, STRENGTHENED the same session after the maintainer pointed
# out that comparing SETS is blind to order and dwell:
#   tail_ours / tail_native = the ONE extra end-of-hold state each leg may
#   carry (see the header); everything before it must match IN ORDER.
#   damage = the (amount, pose) pairs, which must match EXACTLY. Frame
#   numbers are deliberately NOT compared — see the cadence note.
FROZEN = {
  'std': dict(arc=64,  tail_ours=[(22, 72, 0)], tail_native=[],
              damage=[(14, 13)], es=False),
  'cs':  dict(arc=278, tail_ours=[], tail_native=[],
              damage=[(19, 19)], es=False),
  'es':  dict(arc=380, tail_ours=[], tail_native=[(18, 4, 100)],
              damage=[(2, 21), (2, 21), (15, 19)], es=True),
}
NAMES = {'std': 'standard throw 6+HP', 'cs': 'circuit scrapper 63214+MP',
         'es': 'ES circuit scrapper 63214+2P'}

def series(nm, leg):
    tbl, img = TBL[leg], IMG[leg]
    lut = {tbl + struct.unpack_from('>H', img, tbl + 2 * i)[0]: i for i in range(96)}
    out = []
    for p in sorted(glob.glob(f"{W}/{nm}_{leg}/dump_*_ff8810.bin"),
                    key=lambda q: int(re.search(r'dump_(\d+)_', q).group(1))):
        fr = int(re.search(r'dump_(\d+)_', p).group(1))
        cap = (open(f"{W}/{nm}_{leg}/dump_{fr}_ff8934.bin", 'rb').read() or b'\0')[0]
        v = open(p, 'rb').read()
        a = open(f"{W}/{nm}_{leg}/dump_{fr}_ff8410.bin", 'rb').read()
        hp = struct.unpack_from('>H', open(f"{W}/{nm}_{leg}/dump_{fr}_ff8850.bin", 'rb').read(), 0)[0]
        ptr = struct.unpack_from('>I', open(f"{W}/{nm}_{leg}/dump_{fr}_ff881c.bin", 'rb').read(), 0)[0]
        stk = open(f"{W}/{nm}_{leg}/dump_{fr}_ff8509.bin", 'rb').read()[0]
        out.append(dict(fr=fr, cap=cap, hp=hp, stk=stk, pose=lut.get(ptr, '?'),
                        dx=struct.unpack_from('>h', v, 0)[0] - struct.unpack_from('>h', a, 0)[0],
                        dy=struct.unpack_from('>h', v, 4)[0] - struct.unpack_from('>h', a, 4)[0]))
    return out

def states(s):
    r = []
    for e in s:
        if not e['cap']:
            continue
        k = (e['pose'], e['dx'], e['dy'])
        if r and r[-1][0] == k:
            r[-1][1] += 1
        else:
            r.append([k, 1])
    return r

def damage(s):
    return [(a['hp'] - b['hp'], b['pose']) for a, b in zip(s, s[1:]) if b['hp'] < a['hp']]

def arcpeak(s):
    fl = [e['dy'] for e in s if not e['cap']]
    seen = any(e['cap'] for e in s)
    fl = [e['dy'] for i, e in enumerate(s) if not e['cap'] and any(x['cap'] for x in s[:i])]
    return (max(fl) - min(fl)) if fl and seen else None

bad = 0
for nm in ('std', 'cs', 'es'):
    f = FROZEN[nm]
    print(f"== {NAMES[nm]} ==")
    o, n = series(nm, 'ours'), series(nm, 'native')
    so, sn = states(o), states(n)
    # ---- liveness -------------------------------------------------------
    void = False
    for leg, s in (('ours', so), ('native', sn)):
        if sum(d for _, d in s) < 10:
            print(f"  FAIL: {leg} held the victim on only {sum(d for _,d in s)} frames — VOID"); void = True
    if f['es']:
        for leg, s in (('ours', o), ('native', n)):
            if len({e['stk'] for e in s}) < 2:
                print(f"  FAIL: {leg}: stock never dropped — the ES input DEGRADED to the"
                      f" MP grab. VOID, not a pass."); void = True
    if void:
        bad += 1; print(); continue
    # ---- ORDERED state trajectory (not a set: order AND identity) --------
    ko = [k for k, _ in so]; kn = [k for k, _ in sn]
    common = min(len(ko), len(kn))
    if ko[:common] != kn[:common]:
        i = next(j for j in range(common) if ko[j] != kn[j])
        print(f"  FAIL: the hold trajectories DIVERGE at state {i}:"
              f" ours {ko[i]} native {kn[i]}"); bad += 1
    elif ko[common:] != f['tail_ours'] or kn[common:] != f['tail_native']:
        print(f"  FAIL: end-of-hold tail moved. ours {ko[common:]} (frozen"
              f" {f['tail_ours']}), native {kn[common:]} (frozen {f['tail_native']})"); bad += 1
    else:
        print(f"  ok: {common} hold states IN THE SAME ORDER"
              f"; frozen tails ours {f['tail_ours'] or 'none'},"
              f" native {f['tail_native'] or 'none'}")
    # ---- damage: amount and POSE, never the frame number -----------------
    do, dn = damage(o), damage(n)
    if do != dn or do != f['damage']:
        print(f"  FAIL: damage ours {do} native {dn}, frozen {f['damage']}"); bad += 1
    else:
        print(f"  ok: damage {do} — same amounts at the same POSES on both legs")
    # ---- the cadence, REPORTED not asserted ------------------------------
    to, tn = sum(d for _, d in so), sum(d for _, d in sn)
    print(f"  cadence: hold {to} frames ours vs {tn} native"
          f" ({100.0*(to-tn)/tn:+.1f}%) — the ruled host-engine rate (#114),"
          f" reported, not gated")
    # ---- arc ------------------------------------------------------------
    ao, an = arcpeak(o), arcpeak(n)
    if ao != an or ao != f['arc']:
        print(f"  FAIL: arc peak ours={ao} native={an}, frozen {f['arc']}"); bad += 1
    else:
        print(f"  ok: post-release arc peak {ao} on both legs (frozen)")
    print()
sys.exit(1 if bad else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: tenant throw geometry"; exit 1; }
echo "PASS: Phobos's three throws match native VS2 geometry (frozen 14z-131)"
