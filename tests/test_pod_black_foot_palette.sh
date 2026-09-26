#!/bin/sh
# test_pod_black_foot_palette.sh — GitHub #112's black foot, CAUSALLY located
# (14z-126b, 2026-09-01): the black pixels ARE palette row 0b index 14
# (RAM:$90C17C) of the OBJ palette page, and nothing else.
#
# WHAT: #112's black foot, CAUSALLY located: the black pixels ARE palette row 0b index 14
#   (RAM:$90C17C) of the OBJ page — poking that entry across the black frame of the
#   recording turns exactly the 7007 near-black pixels to the poked colour and nothing else,
#   while poking the neighbouring entry moves a disjoint non-black set.
# HOW: tests/inp/pod-black-m14-01 on MAME with the entry poked (3 runs, ~2.5 min), the
#   framebuffer diffed pixel by pixel; the control substitutes the neighbour poke's pixel
#   set.
# EXPECTS: one source colour, one destination colour, the frozen count; the neighbour
#   control fails. WHY the entry holds f111 at that moment is measured elsewhere (a hit
#   re-requests the body palette).
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/inp/ tests/lib/controls.sh
#   tests/lua/inp_probe.lua tools/run_inp_probe.sh tools/setup_mame.sh
#
# MUST-FIRE: known-bad: neighbour-poke-disjoint — the neighbour palette entry 0x90C17A moves a DISJOINT non-black pixel set, so treating it as the black-foot set must fail (mode: the neighbour-poke set is substituted for the fix set and the black-pixel assertions fail; REFUSES with exit 3 if the recording is absent)
#
# WHY A CAUSAL GATE. The mechanism was first argued from a COLOUR COINCIDENCE
# -- f111 = rgb(17,17,17) is the commonest colour near the effect -- and from
# comparing pixel boxes at the same SCREEN coordinates in two frames where the
# effect sits at different positions, i.e. mismatched content. That is
# correlation, and it was wrong to publish as a root cause. This gate replaces
# it with an intervention: force the entry and watch the pixels move.
#
#   1. POKE $90C17C = fcff (the value a CLEAN instance holds) across the black
#      frame of tests/inp/pod-black-m14-01, and EVERY changed pixel must go
#      from the near-black f111 rgb(17,17,17) to fcff rgb(204,255,255).
#      Frozen: 7007 pixels, one source colour, one destination colour.
#   2. CONTROL (must fire): poking the NEIGHBOURING entry $90C17A instead must
#      change a DIFFERENT, DISJOINT pixel set that is NOT the black one -- so
#      the result is index-specific and not "any palette poke repaints it".
#
# What this gate does NOT establish: WHY the entry holds f111 at that moment.
# The effect loads fcff and a later write of the same palette-copy routine
# (PRG:0x02AD64/0x02AD78) puts f111 back before the sprite draws. That WHY is
# measured elsewhere (2026-09-02, 14z-126b; until 14z-157 this header still
# called it unknown): every index-14 write in the window carries P1's fighter
# block (A6 = RAM:$FF8400), and the early revert happens because Donovan is
# HIT while his effect is still drawing — being hit re-requests his default
# body palette. Of the eleven effect-palette loads in the recording, the one
# that survives 28 frames instead of 108-144 is the only one with damage
# inside its window. docs/game/engine_internals.md "EFFECT PALETTES ARE OWNED
# BY THE PLAYER, NOT THE EFFECT".
#
# PINNED TO THE M19 BUILD (maintainer-ruled 2026-09-26, 14z-183: "Pin it to M19
# (Recommended)" — DECISIONS_HISTORY.md). The recording is a hand-played
# Donovan-vs-CPU run; on merged-m20 the #157 fix changes that fight after his first
# registration-pair store (f4236), the playback diverges from f4812 on, and the
# frozen frame holds 0 black pixels there (7007 on M19; build/rc183/pod/). The
# gate's subject — palette row 0b index 14 — is code the M20 delta does not touch,
# so it keeps running on the build where the recording reproduces as captured:
# build/m3b_merged27, kept by the build-dir policy while this line names it. A
# freeze's re-point sweep must leave the default alone.
#
# Usage: ROMDIR=... tests/test_pod_black_foot_palette.sh   (~2.5 min, 3 MAME runs — 145 s measured 2026-09-15; it said ~7 min, 2 runs until then)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
case "$ROMDIR" in /*) ;; *) ROMDIR="$(cd "$ROMDIR" && pwd)" ;; esac
export ROMDIR
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
BUILD="${BUILD:-build/m3b_merged27}"   # PINNED to merged-m19 (maintainer-ruled 2026-09-26, 14z-183) — NEVER re-point this line in a freeze sweep; see the header
[ -f "$REPO/$BUILD/rompath/vsavjw.zip" ] || { if [ -n "$MODE" ]; then echo "REFUSED: CONTROL=$MODE needs a WIDE build at $BUILD (absent)"; exit 3; fi; echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$REPO/tests/inp/pod-black-m14-01/pod-black-m14-01.inp" ] || { if [ -n "$MODE" ]; then echo "REFUSED: CONTROL=$MODE needs the pod-black-m14-01 recording (absent)"; exit 3; fi; echo "SKIP: recording absent"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mk() { python3 -c "import sys;a=sys.argv[1];print(';'.join('%d:%s:fcff'%(f,a) for f in range(14355,14376)))" "$1"; }

SNAP_FRAMES=14370 MAX_FRAMES=14376 \
  tools/run_inp_probe.sh "$BUILD" pod-black-m14-01 "$W/base" >/dev/null 2>&1 || true
SNAP_FRAMES=14370 MAX_FRAMES=14376 POKES="$(mk 90c17c)" \
  tools/run_inp_probe.sh "$BUILD" pod-black-m14-01 "$W/fix" >/dev/null 2>&1 || true
SNAP_FRAMES=14370 MAX_FRAMES=14376 POKES="$(mk 90c17a)" \
  tools/run_inp_probe.sh "$BUILD" pod-black-m14-01 "$W/ctl" >/dev/null 2>&1 || true

python3 - "$W" "$MODE" <<'PY'
import sys, os
from PIL import Image
W=sys.argv[1]
MODE=sys.argv[2] if len(sys.argv) > 2 else ""
def img(d):
    p=os.path.join(d,"snap","vsavjw","0000.png")
    if not os.path.exists(p): sys.exit("FAIL: no snapshot in %s (run did not reach f14370)"%d)
    return Image.open(p).convert("RGB")
a,b,c = img(W+"/base"), img(W+"/fix"), img(W+"/ctl")
pa,pb,pc = a.load(), b.load(), c.load()
Wd,Ht=a.size
fix={(x,y) for y in range(Ht) for x in range(Wd) if pa[x,y]!=pb[x,y]}
ctl={(x,y) for y in range(Ht) for x in range(Wd) if pa[x,y]!=pc[x,y]}
err=[]
# THE EXECUTABLE MODE: treat the neighbour-poke set as the black-foot set; its
# pixels are not the near-black f111, so the black-pixel assertions fail.
target = ctl if MODE == "neighbour-poke-disjoint" else fix
srcs={pa[x,y] for x,y in target}; dsts={pb[x,y] for x,y in target}
if srcs!={(17,17,17)}: err.append("idx14 poke moved pixels that were not the black f111: %s" % sorted(srcs)[:4])
if dsts!={(204,255,255)}: err.append("idx14 poke did not land on fcff: %s" % sorted(dsts)[:4])
if len(target)!=7007: err.append("expected 7007 black pixels, got %d (the foot moved or the recording changed)" % len(target))
# the must-fire control on the REAL sets (independent of the mode)
if not ctl:
    print("CONTROL DEAD: neighbour-poke-disjoint — poking idx13 changed nothing"); err.append("CONTROL DID NOT FIRE: poking idx13 changed nothing")
elif fix & ctl:
    print("CONTROL DEAD: neighbour-poke-disjoint — idx13 and idx14 share %d pixels" % len(fix&ctl)); err.append("CONTROL FAILED: idx13 and idx14 share %d pixels — not index-specific" % len(fix&ctl))
elif (17,17,17) in {pa[x,y] for x,y in ctl}:
    print("CONTROL DEAD: neighbour-poke-disjoint — idx13 also repaints black pixels"); err.append("CONTROL FAILED: idx13 also repaints black pixels")
else:
    print("CONTROL FIRED: neighbour-poke-disjoint — idx13 moves a DISJOINT non-black set (the mode substitutes it for the fix set and the black-pixel assertions fail)")
if err:
    print("FAIL test_pod_black_foot_palette:"); [print("   "+e) for e in err]; sys.exit(1)
print("  ok forcing $90C17C=fcff moves exactly %d pixels, all rgb(17,17,17) -> rgb(204,255,255)" % len(fix))
print("  ok control fired: $90C17A moves %d DISJOINT pixels, none of them black" % len(ctl))
print("PASS: #112's black foot IS palette row 0b index 14 (causal, not correlational)")
PY
