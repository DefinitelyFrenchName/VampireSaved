#!/bin/sh
# test_pod_black_foot_palette.sh — GitHub #112's black foot, CAUSALLY located
# (14z-126b, 2026-09-01): the black pixels ARE palette row 0b index 14
# (RAM:$90C17C) of the OBJ palette page, and nothing else.
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
# (PRG:0x02AD64/0x02AD78) puts f111 back before the sprite draws. Which
# palette-sequence request issues that later write is still unknown.
#
# Usage: ROMDIR=... tests/test_pod_black_foot_palette.sh   (~7 min, 2 MAME runs)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
case "$ROMDIR" in /*) ;; *) ROMDIR="$(cd "$ROMDIR" && pwd)" ;; esac
export ROMDIR
BUILD="${BUILD:-build/m3b_merged21}"
[ -f "$REPO/$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$REPO/tests/inp/pod-black-m14-01/pod-black-m14-01.inp" ] || { echo "SKIP: recording absent"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mk() { python3 -c "import sys;a=sys.argv[1];print(';'.join('%d:%s:fcff'%(f,a) for f in range(14355,14376)))" "$1"; }

SNAP_FRAMES=14370 MAX_FRAMES=14376 \
  tools/run_inp_probe.sh "$BUILD" pod-black-m14-01 "$W/base" >/dev/null 2>&1 || true
SNAP_FRAMES=14370 MAX_FRAMES=14376 POKES="$(mk 90c17c)" \
  tools/run_inp_probe.sh "$BUILD" pod-black-m14-01 "$W/fix" >/dev/null 2>&1 || true
SNAP_FRAMES=14370 MAX_FRAMES=14376 POKES="$(mk 90c17a)" \
  tools/run_inp_probe.sh "$BUILD" pod-black-m14-01 "$W/ctl" >/dev/null 2>&1 || true

python3 - "$W" <<'PY'
import sys, os
from PIL import Image
W=sys.argv[1]
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
srcs={pa[x,y] for x,y in fix}; dsts={pb[x,y] for x,y in fix}
if srcs!={(17,17,17)}: err.append("idx14 poke moved pixels that were not the black f111: %s" % sorted(srcs)[:4])
if dsts!={(204,255,255)}: err.append("idx14 poke did not land on fcff: %s" % sorted(dsts)[:4])
if len(fix)!=7007: err.append("expected 7007 black pixels, got %d (the foot moved or the recording changed)" % len(fix))
if not ctl: err.append("CONTROL DID NOT FIRE: poking idx13 changed nothing")
if fix & ctl: err.append("CONTROL FAILED: idx13 and idx14 share %d pixels — not index-specific" % len(fix&ctl))
if (17,17,17) in {pa[x,y] for x,y in ctl}: err.append("CONTROL FAILED: idx13 also repaints black pixels")
if err:
    print("FAIL test_pod_black_foot_palette:"); [print("   "+e) for e in err]; sys.exit(1)
print("  ok forcing $90C17C=fcff moves exactly %d pixels, all rgb(17,17,17) -> rgb(204,255,255)" % len(fix))
print("  ok control fired: $90C17A moves %d DISJOINT pixels, none of them black" % len(ctl))
print("PASS: #112's black foot IS palette row 0b index 14 (causal, not correlational)")
PY
