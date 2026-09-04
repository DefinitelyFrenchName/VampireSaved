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
# WHAT IS MEASURED, per throw, on both legs:
#   * the victim's HOLD OFFSETS — position relative to the attacker on every
#     frame the captured flag (+0x134) is set. This is what the capture
#     positioner at PRG:0x02802E writes ([VSE-44]).
#   * the victim's POSE-RECORD sequence, resolved to indices through each
#     leg's own `anim_index_c` table, so the two games are comparable.
#   * the POST-RELEASE ARC height — the recorded historical suspicion.
#
# THE RESULT THIS FREEZES (measured 14z-131 on merged-m15 vs native vsav2,
# victim pinned to Victor 0x03 by early-window pokes):
#
#   throw                     hold offsets      pose            arc peak
#   standard 6+HP             18/18 EXACT       ours +1 tail    64 == 64
#   circuit scrapper 63214+MP 16/16 EXACT       IDENTICAL       278 == 278
#   ES circuit scrapper       22 of 23          IDENTICAL       380 == 380
#
# THE TWO DELTAS ARE BOTH AT THE HOLD'S END BOUNDARY, and in OPPOSITE
# directions, which is why they are frozen as measured rather than smoothed
# into a tolerance:
#   * standard: ours reaches ONE MORE pose (22) than native and holds 89
#     frames to native's 82.
#   * ES: ours is a STRICT SUBSET — it visits every offset native does except
#     native's FINAL hold frame (4,100), while holding 130 frames to native's
#     120. Ours ends one keyframe short of native's last.
# Both are consistent with the ruled host-engine cadence (#114, maintainer
# 2026-09-02: *"we must respect the fact that we are porting the character to
# a different engine and the engine, being vanilla vsav, takes precedence"* —
# vsavj runs fewer engine double-ticks per video frame than vsav2). NOT
# ESTABLISHED as that cause; frozen as the measured shape so a real geometry
# change cannot hide behind them.
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
print(';'.join(f'{f}:ff8410-ff8418;{f}:ff8810-ff8818;{f}:ff881c-ff8820;{f}:ff8934-ff8935;{f}:ff8509-ff850a'
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

# FROZEN 14z-131. `extra_native` = offsets native visits that ours does not,
# `extra_ours` = the reverse; both are END-BOUNDARY effects, named so a real
# geometry change cannot hide behind them (see the header).
FROZEN = {
  'std': dict(arc=64,  extra_native=[],          extra_ours=[],  pose_tail_ours=[22], es=False),
  'cs':  dict(arc=278, extra_native=[],          extra_ours=[],  pose_tail_ours=[],   es=False),
  'es':  dict(arc=380, extra_native=[(4, 100)],  extra_ours=[],  pose_tail_ours=[],   es=True),
}
NAMES = {'std': 'standard throw 6+HP', 'cs': 'circuit scrapper 63214+MP',
         'es': 'ES circuit scrapper 63214+2P'}
bad = 0
for nm in ('std', 'cs', 'es'):
    f = FROZEN[nm]
    print(f"== {NAMES[nm]} ==")
    got = {}
    for leg in ('ours', 'native'):
        tbl, img = TBL[leg], IMG[leg]
        lut = {tbl + struct.unpack_from('>H', img, tbl + 2 * i)[0]: i for i in range(96)}
        held, flight, stock = [], [], []
        for p in sorted(glob.glob(f"{W}/{nm}_{leg}/dump_*_ff8810.bin"),
                        key=lambda q: int(re.search(r'dump_(\d+)_', q).group(1))):
            fr = int(re.search(r'dump_(\d+)_', p).group(1))
            cap = (open(f"{W}/{nm}_{leg}/dump_{fr}_ff8934.bin", 'rb').read() or b'\0')[0]
            stock.append(open(f"{W}/{nm}_{leg}/dump_{fr}_ff8509.bin", 'rb').read()[0])
            v = open(p, 'rb').read()
            a = open(f"{W}/{nm}_{leg}/dump_{fr}_ff8410.bin", 'rb').read()
            y = struct.unpack_from('>h', v, 4)[0]
            if cap:
                ptr = struct.unpack_from('>I', open(f"{W}/{nm}_{leg}/dump_{fr}_ff881c.bin", 'rb').read(), 0)[0]
                held.append((struct.unpack_from('>h', v, 0)[0] - struct.unpack_from('>h', a, 0)[0],
                             y - struct.unpack_from('>h', a, 4)[0], lut.get(ptr, '?')))
            elif held:
                flight.append(y)
        got[leg] = (sorted({(x, yy) for x, yy, _ in held}),
                    list(dict.fromkeys(p for *_, p in held)),
                    (max(flight) - min(flight)) if flight else None,
                    len(held), sorted(set(stock)))
    # ---- liveness first -------------------------------------------------
    void = False
    for leg in ('ours', 'native'):
        if got[leg][3] < 10:
            print(f"  FAIL: {leg} held the victim on only {got[leg][3]} frames — the rig"
                  f" did not\n        produce the throw, so this row is VOID, not a verdict."); void = True
    if f['es']:
        for leg in ('ours', 'native'):
            if len(got[leg][4]) < 2:
                print(f"  FAIL: {leg}: P1's stock never dropped (saw {got[leg][4]}) — the ES"
                      f" input\n        DEGRADED to the MP grab. Void, not a pass."); void = True
    if void:
        bad += 1; print(); continue
    print(f"  liveness: held ours={got['ours'][3]} native={got['native'][3]}"
          + (f"; ES stock {got['ours'][4]} / {got['native'][4]}" if f['es'] else ""))
    # ---- arc ------------------------------------------------------------
    ao, an = got['ours'][2], got['native'][2]
    if ao != an or ao != f['arc']:
        print(f"  FAIL: arc peak ours={ao} native={an}, frozen {f['arc']}"); bad += 1
    else:
        print(f"  ok: post-release arc peak {ao} on both legs (frozen)")
    # ---- positions ------------------------------------------------------
    so, sn = set(got['ours'][0]), set(got['native'][0])
    en, eo = sorted(sn - so), sorted(so - sn)
    if en != sorted(f['extra_native']) or eo != sorted(f['extra_ours']):
        print(f"  FAIL: hold offsets moved. only-native {en} (frozen {f['extra_native']});"
              f"\n        only-ours {eo} (frozen {f['extra_ours']})"); bad += 1
    else:
        shared = len(so & sn)
        print(f"  ok: {shared} shared hold offsets; only-native {en or 'none'},"
              f" only-ours {eo or 'none'} (frozen)")
    # ---- pose -----------------------------------------------------------
    po, pn = got['ours'][1], got['native'][1]
    if po[:len(pn)] != pn or po[len(pn):] != f['pose_tail_ours']:
        print(f"  FAIL: pose sequence ours={po} native={pn},"
              f" frozen extra tail {f['pose_tail_ours']}"); bad += 1
    else:
        print(f"  ok: pose sequence matches native"
              + (f" plus the frozen tail {f['pose_tail_ours']}" if f['pose_tail_ours'] else ""))
    print()
sys.exit(1 if bad else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: tenant throw geometry"; exit 1; }
echo "PASS: Phobos's three throws match native VS2 geometry (frozen 14z-131)"
