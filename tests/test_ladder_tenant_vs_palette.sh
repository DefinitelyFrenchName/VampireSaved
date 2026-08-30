#!/bin/sh
# test_ladder_tenant_vs_palette.sh — THE ARCADE-LADDER "VS PALETTE POOL"
# (PRG:0x3A3CA0 + id*32) MEASURED ON SCREEN for a TENANT opponent (14z-123,
# the documentation rationalization pass, inferred_claims.md row 7).
#
# WHY. Since M2b engine_internals carried "0x90C140 writers (vsavj 0xB0AC
# attract path, table 0x3A3CA0 keyed by $114(a5)) not yet repointed — if the
# attract demo shows wrong Donovan colors, that is the mechanism", later
# bounded (14z-118) to "a tenant-vs-tenant VS screen in 1P would show the
# placeholder ramp ... Not measured on screen." Nobody had looked. This gate
# is the look, and it freezes what it saw so the claim cannot drift again.
#
# WHAT IT MEASURED (14z-123, build/m3b_merged21, MAME -debug timeline):
#   * PRG:0x00B094-0x00B0B4 is NOT an attract path. It runs ONCE per ladder
#     match on the 1P OPPONENT-ROULETTE screen (RAM:$FF8008 == 0x0008): it
#     reads the picked opponent's id from the ladder order list (a5-0x61B8)
#     at $114(a5), copies pool row `0x3A3CA0 + id*32` (32 bytes, the copy
#     helper 0x1C3A4 with d7=0, words OR'd with 0xF000) into palette RAM
#     0x90C140 = OBJ palette row 0x0A. Probe at 0xB0B4: frame 2416,
#     A0 = 0x3A3EA0 for CPU Phobos (id 0x10), 0x3A3DA0 for CPU Bishamon
#     (0x08). The 2P path (replay 109) never executes it (0 hits).
#   * WHAT ROW 0x0A COLOURS: the roulette tag's MINI CHARACTER ART beside
#     the picked opponent's name (bbox (123,56)-(171,72) at frame 2520) —
#     found by poking the row solid red and pixel-diffing against an
#     unpoked run: only that box changes on the roulette, and NOTHING on
#     the VS screen changes (0 px at frame 2700). The VS-screen portraits
#     and name plates do not use it.
#   * SO THE VS SCREEN IS CORRECT for a tenant: the 1P VS screen against
#     CPU Phobos and the 2P VS screen with P2 Phobos (replay 109) are
#     PIXEL-IDENTICAL in both portrait regions (0 px differ). The 14z-118
#     "placeholder ramp on the VS screen" sentence was wrong about the
#     surface.
#   * WHAT IS WRONG, cosmetically, on the ROULETTE screen for a tenant
#     opponent: the tag shows the BASE character's name and mini-art
#     (Phobos 0x10 -> "BULLETA", a 4-bit-folded consumer) drawn in pool
#     row 0x10's colours (a brown ramp; row 0x13 is the grey ramp). The
#     legacy control (Bishamon) shows BISHAMON in its own colours.
#     Single-player, tenant-plays-1P only, cosmetic — recorded, not fixed.
#
# WHAT IT ASSERTS (frozen in tests/expected/ladder_tenant_vs_palette.txt,
# FREEZE=1 re-freezes from the run):
#   1. screen identity from the state words ([VSP-124]): $FF8008 == 0x0008 at
#      the roulette frame and 0x000A at the VS frame on every leg;
#   2. the probe: exactly one hit per 1P leg, A0 == pool base + id*32 read
#      from the BUILD's own image, A1 == 0x90C140; zero hits on the 2P leg;
#   3. palette RAM 0x90C140 at the VS frame == that pool row | 0xF000 (the
#      copy landed and nothing overwrote it before the match);
#   4. liveness: P2's hitbox base at match start == the venue-selected
#      opponent's row of the build's base table (a wrong opponent is a DEAD
#      leg, never a pass — audit_don_vs_cpu.sh's rule);
#   5. the red-poke A/B: >0 px differ INSIDE the tag bbox and 0 outside it
#      on the roulette frame (positive control: the instrument sees the
#      element), 0 px anywhere on the VS frame;
#   6. the 1P-vs-2P VS-screen A/B: 0 px differ in both portrait regions.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged21] [FREEZE=1]
#        tests/test_ladder_tenant_vs_palette.sh      (~4 legs in parallel, ~5 min)
# EMULATOR tier (MAME -debug, gfx-bearing build required — [VSP-141]).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged21}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
EXP="tests/expected/ladder_tenant_vs_palette.txt"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
[ -f "$BUILD/prg/vm3j.04d" ] && [ -f "$BUILD/prg/vm3j.10b" ] || { echo "SKIP: no prg members in $BUILD"; exit 0; }
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN"; exit 0; }
python3 -c "import PIL" 2>/dev/null || { echo "SKIP: python3 PIL not available"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
R111=tests/replays/111_don_arcade_vs_screen.rpl
R109=tests/replays/109_2p_don_vs_phobos.rpl
ROUL=2520; VS1P=2700; VS2P=2550          # frames on the -debug timeline (measured 14z-123)
PK="1704:ff8782:13;1760:ff8782:13;1900:ff8782:13;2100:ff8782:13;2400:ff8782:13"
RED="$(python3 -c "print('0f00'*16)")"
venue_pokes() { python3 -c "print(';'.join(f'{f}:ff8121:$1' for f in range(1750,2860,20)))"; }
LIVE="$(python3 -c "print(';'.join(f'{f}:ff8800-ff8870' for f in range(2900,3400,20)))")"

leg() { # name replay pokes snap_frames dumps
    d="$W/$1"; mkdir -p "$d/sbx"
    GUARD_DEBUG=1 GUARD_PROBE=b0b4 POKES="$3" SNAP_FRAMES="$4" DUMPS="$5" \
      MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      tools/run_replay_guarded.sh vsavjw "$2" "$d/out.log" "$d/sbx" > "$d/g.log" 2>&1
    echo $? > "$d/rc"
}
D1P="$ROUL:ff8000-ff8010;$ROUL:90c140-90c160;$VS1P:ff8000-ff8010;$VS1P:90c140-90c160;$LIVE"
leg phobos_ctl   "$R111" "$PK;$(venue_pokes 02)"                                     "$ROUL,$VS1P" "$D1P" &
leg phobos_red   "$R111" "$PK;$(venue_pokes 02);2450:90c140:$RED;2650:90c140:$RED"   "$ROUL,$VS1P" "$D1P" &
leg bishamon_ctl "$R111" "$PK;$(venue_pokes 10)"                                     "$ROUL,$VS1P" "$D1P" &
leg p2_ctl       "$R109" ""                                                          "$VS2P"       "$VS2P:ff8000-ff8010;$VS2P:90c140-90c160" &
wait
for l in phobos_ctl phobos_red bishamon_ctl p2_ctl; do
    rc="$(cat "$W/$l/rc" 2>/dev/null || echo 99)"
    [ "$rc" = 0 ] || { echo "FAIL: leg $l rc=$rc"; tail -5 "$W/$l/g.log"; echo "FAIL test_ladder_tenant_vs_palette"; exit 1; }
done

python3 - "$W" "$BUILD" "$ROUL" "$VS1P" "$VS2P" > "$W/got.txt" <<'PY' || { cat "$W/got.txt"; echo "FAIL test_ladder_tenant_vs_palette (analysis)"; exit 1; }
import glob, re, struct, sys
from PIL import Image, ImageChops
W, BUILD, ROUL, VS1P, VS2P = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
POOL = 0x3A3CA0
def swapped(path):
    raw = open(path, "rb").read(); sw = bytearray(len(raw)); sw[0::2] = raw[1::2]; sw[1::2] = raw[0::2]; return bytes(sw)
prg10 = swapped(f"{BUILD}/prg/vm3j.10b")            # PRG:0x380000-0x3FFFFF, data view (outside the crypt range)
prg04 = swapped(f"{BUILD}/prg/vm3j.04d")            # PRG:0x080000-0x0FFFFF
bases = [struct.unpack(">I", prg04[0x3D97A + 4*i:0x3D97A + 4*i + 4])[0] for i in range(32)]   # PRG:0x0BD97A hitbox bases
def pool_row(i):
    off = POOL + i*32 - 0x380000
    return struct.unpack(">16H", prg10[off:off+32])
def dump(leg, fr, lo):
    return open(f"{W}/{leg}/dump_{fr}_{lo}.bin", "rb").read()
def state(leg, fr):
    b = dump(leg, fr, "ff8000"); return struct.unpack(">I", b[8:12])[0]
def pal(leg, fr):
    return struct.unpack(">16H", dump(leg, fr, "90c140")[:32])
def probes(leg):
    return [l for l in open(f"{W}/{leg}/out.log") if l.startswith("PROBE ")]
def snap(leg, idx):
    return Image.open(f"{W}/{leg}/sbx/snap/vsavjw/{idx:04d}.png").convert("RGB")
def px(img_a, img_b, box=None):
    d = ImageChops.difference(img_a, img_b)
    if box: d = d.crop(box)
    return sum(1 for p in d.getdata() if p != (0, 0, 0))
fail = False
out = []
def emit(s): out.append(s)
def must(cond, s):
    global fail
    emit(("ok   " if cond else "BAD  ") + s)
    if not cond: fail = True
# 1. screen identity
for leg in ("phobos_ctl", "phobos_red", "bishamon_ctl"):
    emit(f"state {leg} {ROUL} 8008={state(leg, ROUL):08x} {VS1P} 8008={state(leg, VS1P):08x}")
    must(state(leg, ROUL) == 0x00080000 and state(leg, VS1P) == 0x000A0000, f"{leg}: roulette at {ROUL}, VS screen at {VS1P} (state words)")
emit(f"state p2_ctl {VS2P} 8008={state('p2_ctl', VS2P):08x}")
must(state("p2_ctl", VS2P) == 0x000A0000, f"p2_ctl: VS screen at {VS2P}")
# 2. the probe, 3. the palette row, 4. liveness
for leg, cid in (("phobos_ctl", 0x10), ("bishamon_ctl", 0x08)):
    ps = probes(leg)
    m = re.match(r"PROBE (\d+) D0=\w+ D1=\w+ A0=(\w+) A1=(\w+)", ps[0]) if ps else None
    a0 = int(m.group(2), 16) if m else -1; a1 = int(m.group(3), 16) if m else -1
    emit(f"probe {leg} hits={len(ps)} frame={m.group(1) if m else '-'} A0={a0:08x} A1={a1:08x}")
    must(len(ps) == 1 and a0 == POOL + cid*32 and a1 == 0x90C140, f"{leg}: one copy of pool row 0x{cid:02x} (PRG:0x{POOL + cid*32:06X}) into 0x90C140 before the match")
    row = pool_row(cid); got = pal(leg, VS1P)
    emit(f"pool {leg} row=0x{cid:02x} " + " ".join(f"{w:04x}" for w in row))
    emit(f"pal140 {leg} {VS1P} " + " ".join(f"{w:04x}" for w in got))
    must(all(g == (r | 0xF000) for g, r in zip(got, row)), f"{leg}: palette RAM 0x90C140 at the VS frame == pool row | 0xF000")
    seen = set()
    for f in glob.glob(f"{W}/{leg}/dump_*_ff8800.bin"):
        seen.add(struct.unpack(">I", open(f, "rb").read()[0x60:0x64])[0])
    emit(f"liveness {leg} P2base want={bases[cid]:08x} seen={' '.join(f'{x:08x}' for x in sorted(seen))}")
    must(bases[cid] in seen, f"{leg}: P2 loaded the venue-selected opponent (id 0x{cid:02x}) at match start")
emit(f"probe p2_ctl hits={len(probes('p2_ctl'))}")
must(len(probes("p2_ctl")) == 0, "p2_ctl: the 2P path never runs the ladder pool copy")
emit(f"pal140 p2_ctl {VS2P} " + " ".join(f"{w:04x}" for w in pal("p2_ctl", VS2P)))
# 5. the red-poke A/B
TAG = (123, 56, 171, 72)
c_r, r_r = snap("phobos_ctl", 0), snap("phobos_red", 0)
inside = px(c_r, r_r, TAG); total = px(c_r, r_r)
emit(f"red roulette {ROUL} tag_bbox={TAG} px_inside={inside} px_outside={total - inside}")
must(inside > 0 and total == inside, f"roulette {ROUL}: row 0x0A colours ONLY the tag mini-art (bbox {TAG})")
vs_px = px(snap("phobos_ctl", 1), snap("phobos_red", 1))
emit(f"red vs {VS1P} px={vs_px}")
must(vs_px == 0, f"VS screen {VS1P}: nothing drawn from row 0x0A")
# 6. 1P vs 2P VS-screen portrait A/B
a, b = snap("phobos_ctl", 1), snap("p2_ctl", 0)
p2 = px(a, b, (232, 16, 384, 224)); p1 = px(a, b, (0, 16, 160, 224))
emit(f"vs_ab phobos 1P@{VS1P} vs 2P@{VS2P} P2portrait_px={p2} P1portrait_px={p1}")
must(p2 == 0 and p1 == 0, "the tenant's VS-screen portraits are pixel-identical on the ladder and 2P paths")
print("\n".join(out))
sys.exit(1 if fail else 0)
PY

cat "$W/got.txt"
if [ "${FREEZE:-0}" = 1 ]; then cp "$W/got.txt" "$EXP"; echo "  FROZE  $EXP from this run — FREEZE=1"; fi
[ -f "$EXP" ] || { echo "FAIL: no expectation file $EXP (run once with FREEZE=1 and review it)"; exit 1; }
if diff -u "$EXP" "$W/got.txt" > "$W/diff.txt"; then
    echo "  ok    matches $EXP"
else
    echo "FAIL: differs from $EXP:"; cat "$W/diff.txt"; echo "FAIL test_ladder_tenant_vs_palette"; exit 1
fi
# verdict-logic control ([VSP-19]): a perturbed expectation must not match
sed 's/px_inside=[0-9]*/px_inside=0/' "$EXP" > "$W/perturbed.txt"
if diff -q "$W/perturbed.txt" "$W/got.txt" >/dev/null; then echo "FAIL: perturbed expectation matched"; exit 1; fi
echo "  ok    control: a perturbed expectation is rejected"
echo "PASS test_ladder_tenant_vs_palette"
