#!/bin/sh
# test_don_immortal_native.sh — THE CROSS-GAME 421+P LOCK (14z-127, GitHub #114).
#
# WHY IT EXISTS. `test_don_reactions.sh` asserts 421+P's shape on OUR build
# only: all its legs run `vsavj`, and its "native == 10" was a constant taken
# from testimony. #114 was opened because that provenance is weak. This gate
# closes it the other way round — it MEASURES NATIVE in the same run and
# compares, so no constant here is anyone's memory.
#
# WHAT #114 ACTUALLY FOUND, measured 2026-09-02 (this gate's own three legs):
# 421+P DOES reproduce native. The issue's "ours" leg was JEDAH. Replay 48's
# P1 path (U,U,R -> slot 0x0F) selects Donovan only on the SUBSTITUTED stock
# track; since the 14z-115 wheel separation a WIDE build puts the tenants on
# their own appended row, so that path lands on Jedah (+0x60 = 0x000b0d2e) and
# what got measured was Jedah's 421+HP: 3 hits / 11 damage, victim pushed
# 728 -> 852. Donovan's, on BOTH tracks, is 6 hits / 10 damage with the victim
# HELD -- native's numbers exactly. Section 3 is that artefact, kept as this
# gate's must-fire control.
#
# THE LESSON THIS GATE ENFORCES: a tenant replay is a claim about the build it
# was authored for ([VSP-156]). Section 2 therefore asserts WHO IT SELECTED,
# from tests/expected/roster_pairings/bases.tsv, before it believes a number.
#
#   1. NATIVE  vsav2 + replay 51            -> 6 hits, 10 total, victim held
#   2. OURS    build + replay 48 (stock) or
#                      replay don/114 (WIDE)    -> identical, and P1 IS Donovan
#   3. CONTROL pristine vsavj + replay 48   -> MUST FAIL section 2's assertions
#
# Usage: ROMDIR=... tests/test_don_immortal_native.sh [rompath_dir]
#   The rompath's pack picks the track: a `vsavjw.zip` runs the WIDE leg
#   (replay 114 + the WIDE MAME binary), anything else the stock leg.
# Runtime: ~3 min, emulator tier.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/m5_stock13/rompath}"
[ -d "$RPDIR" ] || { echo "SKIP: no build at $RPDIR"; exit 0; }
RPDIR="$(cd "$RPDIR" && pwd)"          # [VSP-108]: canonicalise before measuring
BASES="$REPO/tests/expected/roster_pairings/bases.tsv"
[ -f "$BASES" ] || { echo "FAIL: missing $BASES"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

# Per-frame P1+P2 fighter blocks across the whole move window.
DSPEC="$(python3 -c "print(';'.join(f'{f}:ff8800-ff8a00;{f}:ff8400-ff8600' for f in range(2595,2711)))")"

run_leg() {   # run_leg <name> <set> <rompath> <replay> [mame_bin]
    _n="$1"; _s="$2"; _rp="$3"; _r="$4"; _b="${5:-}"
    mkdir -p "$WORK/$_n"
    if [ -n "$_b" ]; then MAME_BIN="$_b"; export MAME_BIN; fi
    DUMPS="$DSPEC" REPLAY="$REPO/tests/replays/$_r" \
        CHECKSUM_OUT="$WORK/$_n/c.log" MAME_SANDBOX="$WORK/$_n/sb" \
        MAME_ROMPATH="$_rp" tools/run_mame.sh "$_s" \
        -autoboot_script "$REPO/tests/lua/replay.lua" \
        > "$WORK/$_n/mame.log" 2>&1
    unset MAME_BIN
    [ "$(ls "$WORK/$_n"/dump_*_ff8800.bin 2>/dev/null | wc -l)" -ge 100 ] || {
        echo "FAIL: leg $_n produced no dumps (see $WORK/$_n/mame.log)"; exit 1; }
}

if [ -f "$RPDIR/vsavjw.zip" ]; then
    OURS_SET=vsavjw; OURS_RPL=don/114_don_immortal_wide.rpl
    OURS_BIN="$HOME/.cache/vampire-saved/mame/cps2"
    [ -x "$OURS_BIN" ] || { echo "SKIP: WIDE build but no WIDE MAME at $OURS_BIN"; exit 0; }
else
    OURS_SET=vsavj;  OURS_RPL=48_don_immortal_ko.rpl; OURS_BIN=""
fi
echo "  ours: $OURS_SET + $OURS_RPL  ($RPDIR)"

run_leg native  vsav2 "$ROMDIR"            51_vs2_immortal_native.rpl
run_leg ours    "$OURS_SET" "$RPDIR;$ROMDIR" "$OURS_RPL" "$OURS_BIN"
run_leg control vsavj "$ROMDIR"            48_don_immortal_ko.rpl

python3 - "$WORK" "$BASES" <<'EOF2'
import sys, os, struct
work, bases_path = sys.argv[1], sys.argv[2]

DON_VS2 = 0x000C8DF8   # vs2's own Donovan hitbox base (pristine-ROM fact, fixed)
bases = {}
for line in open(bases_path):
    if line.startswith('#') or not line.strip():
        continue
    cls, name, base = line.split()[:3]
    bases[name] = int(base, 16)
DON = bases['donovan']       # re-derived at every freeze; never hardcoded here

def u16(b, o): return struct.unpack('>H', b[o:o+2])[0]
def s16(b, o): return struct.unpack('>h', b[o:o+2])[0]
def u32(b, o): return struct.unpack('>I', b[o:o+4])[0]

def measure(leg):
    prev = None; hits = []; xs = {}
    p1id = None
    for f in range(2595, 2711):
        p2 = open(os.path.join(work, leg, f'dump_{f}_ff8800.bin'), 'rb').read()
        if p1id is None:
            p1 = open(os.path.join(work, leg, f'dump_{f}_ff8400.bin'), 'rb').read()
            p1id = u32(p1, 0x60)
        hp = u16(p2, 0x50); xs[f] = s16(p2, 0x10)
        if prev is not None and hp < prev: hits.append((f, prev - hp))
        prev = hp
    total = sum(d for _, d in hits)
    if hits:
        f0, f1 = hits[0][0], hits[-1][0]
        held = len({xs[f] for f in range(f0, f1 + 1)}) == 1
        span = f1 - f0
    else:
        f0 = f1 = span = None; held = False
    return dict(p1id=p1id, hits=len(hits), total=total, held=held,
                span=span, first=f0, last=f1, steps=hits,
                x0=xs[2595], x1=xs[2710])

def shape_ok(m):
    """Donovan's 421+P, two-sided: 6 hits, 10 damage, the victim HELD."""
    return (m['hits'] == 6 and m['total'] == 10 and m['held']
            and m['span'] is not None and 45 <= m['span'] <= 60)

def show(tag, m):
    print(f"  {tag:8} p1 +0x60={m['p1id']:#010x}  {m['hits']} hits / {m['total']} dmg  "
          f"held={m['held']}  span={m['span']}  x {m['x0']}->{m['x1']}")
    print(f"           " + " ".join(f"f{f}:-{d}" for f, d in m['steps']))

nat = measure('native'); our = measure('ours'); ctl = measure('control')
show('NATIVE', nat); show('OURS', our); show('CONTROL', ctl)

# ── 1. native is the reference, and it is MEASURED here, not remembered ──
assert nat['p1id'] == DON_VS2, (
    f"native leg P1 +0x60 = {nat['p1id']:#x}, expected vs2 Donovan {DON_VS2:#x} "
    f"— replay 51 did not select Donovan on vsav2")
assert shape_ok(nat), (
    f"NATIVE vsav2 421+P is not the frozen shape: {nat['hits']} hits / "
    f"{nat['total']} dmg / held={nat['held']} / span={nat['span']} "
    f"(expected 6 / 10 / True / 45..60)")
print("  ok: NATIVE vsav2 measured — 6 hits, 10 damage, victim held")

# ── 2. ours must match it, and must have selected DONOVAN to say so ──────
assert our['p1id'] == DON, (
    f"OURS leg P1 +0x60 = {our['p1id']:#x}, expected Donovan {DON:#x} "
    f"(bases.tsv). THE REPLAY SELECTED SOMEONE ELSE — this is the #114 "
    f"artefact: a substituted-wheel path on a separated wheel. Any number "
    f"measured here would be that character's, not Donovan's")
assert shape_ok(our), (
    f"OURS 421+P diverges from native: {our['hits']} hits / {our['total']} dmg "
    f"/ held={our['held']} / span={our['span']} (native "
    f"{nat['hits']} / {nat['total']} / {nat['held']} / {nat['span']})")
assert our['hits'] == nat['hits'] and our['total'] == nat['total'], (
    f"OURS {our['hits']}h/{our['total']}d != NATIVE {nat['hits']}h/{nat['total']}d")
print("  ok: OURS reproduces native — same hit count, same damage, victim held")

# ── 3. must-fire control: the #114 artefact itself ───────────────────────
assert ctl['p1id'] == bases['jedah'], (
    f"control leg P1 +0x60 = {ctl['p1id']:#x}, expected vanilla Jedah "
    f"{bases['jedah']:#x} — the control is not measuring what it documents")
assert not shape_ok(ctl), (
    "CONTROL: pristine vsavj + replay 48 satisfied Donovan's 421+P shape. "
    "The assertions cannot discriminate and this gate proves nothing")
print(f"  ok: CONTROL fires — pristine vsavj (Jedah) gives {ctl['hits']} hits / "
      f"{ctl['total']} dmg, victim pushed {ctl['x0']}->{ctl['x1']} (the #114 artefact)")
EOF2
echo "PASS: 421+P reproduces native vsav2 (cross-game, identity-asserted)"
