#!/bin/sh
# test_down_flash_mechanism.sh — THE MECHANISM behind GitHub #113's one-frame
# white-out, measured 2026-09-01 (14z-126b) and locked here.
#
# WHAT IT ASSERTS. The white frame is a DELIBERATE PALETTE-BASE SWAP, not a
# palette blank and not a layer register: the game writes CPS-A `0x80410a`
# (MAME cps1.h `CPS1_PALETTE_BASE = 0x0a/2`) from its normal `0x90c0` to
# `0x9240` for exactly ONE frame, and `0x924000` is filled entirely with
# `ffff`, so every layer resolves to white.
#   1. `0x9240` is written EXACTLY 4 times in the 6,700-frame run and `0x90c0`
#      is the normal value -- the 4/4 discriminator. A 5th occurrence, or a
#      missing one, FAILS: that is a new flash or a lost one.
#   2. every `0x9240` frame is immediately followed by an all-white frame
#      (the fnv1a64 the sibling gate freezes), and no white frame lacks one.
#   3. the palette region at `0x924000` is all `ffff`.
# CONTROL (must-fire): asserting the SAME shape against `0x90c0` -- the normal
# value, present on ~6,590 frames -- must FAIL, proving the test discriminates
# rather than accepting any base value.
#
# WHAT THIS GATE DOES NOT ESTABLISH: WHY Capcom flashes the screen at all.
# It locks the MECHANISM (how the flash is produced) and the fact that a base
# swap is the cheap way to produce one. The DESIGN INTENT is unknown; all four
# occurrences happen to sit at state transitions, which is an observation, not
# a finding. Do not read this gate as explaining the effect's purpose.
#
# WHY A SECOND GATE rather than an assert inside test_down_flash_vanilla.sh:
# that one locks the INVENTORY (where white frames are) from the framebuffer
# alone; this one locks WHY, and needs a register tap. Keeping them apart means
# a mechanism change cannot be masked by an unchanged inventory.
#
# TWO INSTRUMENT TRAPS PAID FOR HERE, both recorded so they are not re-paid:
#   * `0x800100` is the driver's "Mirror (sfa)" block and is NEVER written by
#     this game -- a tap there returns a clean, meaningless zero. The live
#     registers are `0x804100-0x80417f`.
#   * a tap's MECHANISM being control-proven at one address does NOT prove
#     another address is meaningful. Check that the range is written at all.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/test_down_flash_mechanism.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
case "$ROMDIR" in /*) ;; *) ROMDIR="$(cd "$ROMDIR" && pwd)" ;; esac
BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
[ -x "$BIN" ] || BIN="$HOME/.cache/vampire-saved/mame/cps2"
[ -x "$BIN" ] || { echo "SKIP: no MAME binary"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"
RPL="$REPO/tests/replays/104_1p_auto_ko_win.rpl"

MAME_BIN="$BIN" MAME_SANDBOX="$W/sb1" REPLAY="$RPL" \
  TAP=80410a,2 WINDOW=0,6700 FRAMES=6700 TRACE_OUT="$W/base.txt" \
  tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/tap_writes.lua" > "$W/o1" 2>&1 || true
MAME_BIN="$BIN" MAME_SANDBOX="$W/sb2" REPLAY="$RPL" MAX_FRAMES=6700 \
  CHECKSUM_OUT="$W/probe.log" DUMP_FRAMES=6645 PAL_BASE=924000 PAL_ROWS=00,01,02 \
  tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/inp_probe.lua" > "$W/o2" 2>&1 || true

python3 - "$W/base.txt" "$W/probe.log" <<'PY'
import sys
WHITE="eab1fb569cb99b25"
base={}
for ln in open(sys.argv[1]):
    if ln.startswith("frame"):
        p=ln.split(); base[int(p[1])]=p[7]
white=set()
palrows=[]
for ln in open(sys.argv[2]):
    if ln.startswith("V "):
        f=ln.split()
        if f[2]==WHITE: white.add(int(f[1]))
    elif ln.startswith("P F6645 "):
        palrows.append(ln.split("dark=")[1].split(None,1)[1].strip())
err=[]
def check(val, expect_pass):
    hits=sorted(f for f,v in base.items() if v=="0000%s"%val)
    ok = len(hits)==4 and all((f+1) in white for f in hits) and len(white)==4
    return ok, hits
ok, hits = check("9240", True)
if len(hits)!=4: err.append("expected 4 writes of 0x9240, got %d: %s" % (len(hits),hits))
if len(white)!=4: err.append("expected 4 white frames, got %d: %s" % (len(white),sorted(white)))
for f in hits:
    if f+1 not in white: err.append("0x9240 at f%d is not followed by a white frame" % f)
for w in white:
    if (w-1) not in hits: err.append("white frame f%d has no 0x9240 the frame before" % w)
if not palrows: err.append("no palette dump at 0x924000")
for r in palrows:
    if set(r.split())!={"ffff"}: err.append("0x924000 row is not all ffff: %s" % r[:40])
okc, hc = check("90c0", False)
if okc: err.append("CONTROL DID NOT FIRE: the normal base 0x90c0 also satisfied the shape")
if err:
    print("FAIL test_down_flash_mechanism:"); [print("   "+e) for e in err]; sys.exit(1)
print("  ok 0x9240 written exactly 4x (f%s), each followed by an all-white frame" % ",f".join(str(f) for f in hits))
print("  ok 0x924000 is all ffff; control fired (0x90c0, the normal value, fails the shape)")
print("PASS: #113's white frame is a palette-base swap to an all-white block")
PY
