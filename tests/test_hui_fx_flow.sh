#!/bin/sh
# test_hui_fx_flow.sh — the effect-flow attribution gate (14z-68).
#
# Captures the tap probe that refuted the 14z-67 seq-D entry theory
# and named the true root (STATE 14z-68). Two legs on replay 83b
# (2P-dummy, cross-emulator-reproducible, FBNeo write taps):
#
#   1. FIGHTER-SIDE FLOW IDENTITY: H's ray must run HIS OWN per-char
#      flow — the state-0x12 recognizer latch (ff8506=12 from the
#      0x55500 twin) and the seq-0x0E sub-flow writes (0x5684E/
#      0x56854/0x5685A/0x5686C twins). This is the fact the built
#      dispatch-table rows 0x10 provide; if a build regresses them,
#      this leg names it. (Native never executes 0x56D68 — the
#      refuted entry; asserted stays-absent on ours too.)
#
#   2. PIECE-SIDE MACHINE ATTRIBUTION: the ray effect object (id
#      0x14) spawns into the $FFBxxx pool on every build; WHICH
#      machine runs its first tick is the port state:
#        pre-port  — vanilla vj 0x5E7B0 family, bank word +0x18 = 0
#                    (the measured deficiency, asserted so its
#                    disappearance is loud)
#        post-port — the placed piece machine (build carries a
#                    "piece_machine" op), bank word +0x18 = 0x3000
#                    (group C bank 5, the c5 flip value)
#      Port presence is auto-detected from the build's
#      patch_notes_fragment (the run_suite fingerprint pattern).
#
# Usage: ROMDIR=... tests/test_hui_fx_flow.sh [stage-6-builddir]
#        (self-builds stage 6 from huitzil.toml if no build given)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   the effect-flow attribution gate (14z-68): leg 1 fighter-side flow
#   identity (H's ray runs HIS per-char handlers; the REFUTED 0x56D68 entry
#   must stay cold); leg 2 piece-side machine attribution, auto-detecting
#   pre/post-port from the build's own patch notes. Rig: replay 83b (2P dummy,
#   3 spaced 236LP, FBNeo taps). Ground-truthed on hui9 + a bad-thunk negative
#   control. Self-builds stage 6 unless given
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
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ $# -ge 1 ]; then
    BUILD="$1"
else
    echo "== stage 6 build"
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 6 "$WORK/hui6" > "$WORK/build.log" 2>&1 \
        || { tail -15 "$WORK/build.log"; echo "FAIL: build"; exit 1; }
    BUILD="$WORK/hui6"
fi
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no vsavjw.zip (WIDE build required)"; exit 1; }

RPL="$REPO/tests/replays/hui/83b_hui_ray_2p.rpl"
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"
TAP="ff8400-ff87ff;ffb800-ffbfff"

echo "== tapped replay 83b on the build"
FBNEO_HPOKE="$PK" FBNEO_HTAP="$TAP" FBNEO_HTAP_OUT="$WORK/ours.tap" \
FBNEO_ROMPATH="$BUILD/rompath" \
    tools/run_replay_fbneo.sh vsavjw "$RPL" "$WORK/ours.log" "$WORK/s1" \
    > "$WORK/ours.out" 2>&1 || { tail -5 "$WORK/ours.out"; echo "FAIL: build leg"; exit 1; }

python3 - "$BUILD" "$WORK/ours.tap" <<'EOF' || exit 1
import json, sys
build, tap = sys.argv[1], sys.argv[2]
pl = json.load(open(f"{build}/patch/placements.json"))
code = pl["regions"]["code"]
DELTA = code["dst"] - code["src"]          # placed-code delta (contiguous pair)
ported = False
try:
    ported = "piece_prebake" in open(f"{build}/patch/patch_notes_fragment.md").read()
except FileNotFoundError:
    pass
ev = []
for line in open(tap):
    if line.startswith('#'): continue
    p = line.split()
    if len(p) != 5: continue
    ev.append((int(p[0]), int(p[1],16), p[2], p[3], int(p[4][3:],16)))

fail = 0
# ── 1. fighter-side flow identity ──────────────────────────────────
lat = [(fr,pc-DELTA) for fr,a,v,s,pc in ev if a==0xff8506 and v=='12']
sub = set(pc-DELTA for fr,a,v,s,pc in ev if 0x56840 <= pc-DELTA <= 0x568d0)
d68 = [1 for fr,a,v,s,pc in ev if pc-DELTA in (0x56d76,0x56d7a,0x56d7e,0x56d82)]
if lat and all(abs(p-0x55506) <= 6 for _,p in lat):
    print(f"  ok: state-0x12 latch from the 0x55500 twin ({len(lat)} attempts)")
else:
    print(f"  FAIL: state-0x12 latch missing or wrong writer ({lat[:3]})"); fail=1
need = {0x56854, 0x5685a, 0x56870}
if need & sub == need:
    print(f"  ok: seq-0x0E sub-flow runs H's own handler ({len(sub)} writer pcs)")
else:
    print(f"  FAIL: seq-0x0E sub-flow writers missing: {sorted(hex(x) for x in need-sub)}"); fail=1
if not d68:
    print("  ok: the refuted 0x56D68 entry stays cold")
else:
    print(f"  FAIL: 0x56D68 head-clears executed {len(d68)}x — a seq-head thunk is live"); fail=1

# ── 2. piece-side machine attribution ──────────────────────────────
rays = [(fr,a-0x54) for fr,a,v,s,pc in ev if (a&0x7f)==0x54 and v=='14' and 0xffb800<=a<0xffc000]
if len(rays) >= 1:
    print(f"  ok: ray object spawns (id 0x14, {len(rays)} attempts)")
else:
    print("  FAIL: no id-0x14 ray object spawned"); fail=1
# first-tick bank-word write on the first ray slot
bank = None; tick_pc = None
if rays:
    fr0, slot = rays[0]
    for fr,a,v,s,pc in ev:
        if a == slot+0x18 and fr0 <= fr <= fr0+3:
            bank, tick_pc = v, pc; break
if ported:
    if bank == '3000':
        print(f"  ok: PREBAKE — the ray piece gets bank 0x3000 at spawn (pc={tick_pc:#x})")
    else:
        print(f"  FAIL: piece_prebake present but bank word = {bank} (pc={tick_pc and hex(tick_pc)})"); fail=1
else:
    if bank == '0000' and tick_pc is not None and 0x5E780 <= tick_pc < 0x5EE00:
        print(f"  ok: PRE-PORT — vanilla machine ticks the piece (pc={tick_pc:#x}, bank 0)")
        print("      (the documented deficiency, STATE 14z-68 — flips when the port lands)")
    else:
        print(f"  FAIL: pre-port attribution changed: bank={bank} pc={tick_pc and hex(tick_pc)}"); fail=1
sys.exit(fail)
EOF

echo "PASS: test_hui_fx_flow"
