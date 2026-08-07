#!/bin/sh
# test_hui_air.sh — Huitzil air-movement gate (14z-66, playtest round-1
# item 3: float + air dash were DEAD).
#
# Mechanism (measured; STATE 14z-66): vs2 routes the class-02 jump seq
# BY CHAR ID at the engine head — id 0x10 gets his OWN per-char jump
# handler (float/air-action/restart bodies). The port clones that
# handler (region x02592a), thunk-routes tenant owners at vsavj's live
# twin head 0x22A0E (tenant_jump_seq), and rewrites the oracle-invisible
# pcrel escapes of both engine-style regions (pcrel_escape_fix).
#
# Sections (replay 75 float probe, replay 79 air-dash probe), each with
# an anti-coverage-loss assertion — the measured mode signature, not
# just "no crash":
#   1. FLOAT — hold-8 rises then HOVERS: Y at f3350..f3370 pinned to one
#      value >= 100px (the mover-bypass hold). Sample frames sit AFTER
#      the rise completes: with the jump_params port the native-speed
#      rise reaches the 121.1 ceiling at ~f3345 (the alias-physics
#      build reached 109.4 by ~f3320 — the original 3330-frame samples
#      were tuned to THAT rise and caught the new one mid-climb).
#   2. AIR DASH — 66 during the float: the air-dash seq byte 0x14
#      appears at +0x05 with X advancing >= 30px across f3185..f3200 at
#      near-constant height.
#
# Usage: ROMDIR=... tests/test_hui_air.sh [existing-stage4-builddir]
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ $# -ge 1 ]; then
    BUILD="$1"
    echo "== using existing build $BUILD"
else
    echo "== stage 4 build"
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 4 "$WORK/hui4" > "$WORK/build.log" 2>&1 \
        || { tail -15 "$WORK/build.log"; echo "FAIL: build"; exit 1; }
    BUILD="$WORK/hui4"
fi
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no vsavjw.zip (WIDE build required)"; exit 1; }
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"

PK="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10"

echo "== float (replay 75)"
d="$WORK/float"; mkdir -p "$d"
( cd "$d" && POKES="$PK" \
  DUMPS="3350:ff8400-ff8420;3360:ff8400-ff8420;3370:ff8400-ff8420" \
  MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
  "$REPO/tools/run_replay_guarded.sh" vsavjw "$REPO/tests/replays/hui/75_hui_air.rpl" \
      "$d/g.log" "$d/box" > "$d/g.out" 2>&1 ) || {
    echo "FAIL: float replay guard tripped:"
    grep -m2 -E "CRASH|REGS" "$d/g.log" || tail -5 "$d/g.out"
    exit 1
}
python3 - "$d" <<'EOF'
import struct, sys
d = sys.argv[1]
ys = []
for f in (3350, 3360, 3370):
    b = open("%s/dump_%d_ff8400.bin" % (d, f), 'rb').read()
    ys.append(struct.unpack('>i', b[0x14:0x18])[0])
same = ys[0] == ys[1] == ys[2]
high = ys[0] / 65536.0 >= 100
print("  hover Y: %s (%.1f px)" % ("CONSTANT" if same else "VARYING %s" % ys, ys[0]/65536.0))
if not (same and high):
    print("FAIL: no hover — the float did not engage")
    sys.exit(1)
EOF
echo "  ok: float hovers (mover bypassed, Y pinned)"

echo "== air dash (replay 79)"
d="$WORK/ad"; mkdir -p "$d"
( cd "$d" && POKES="$PK" \
  DUMPS="3185:ff8400-ff8420;3200:ff8400-ff8420" \
  MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
  "$REPO/tools/run_replay_guarded.sh" vsavjw "$REPO/tests/replays/hui/79_hui_airdash.rpl" \
      "$d/g.log" "$d/box" > "$d/g.out" 2>&1 ) || {
    echo "FAIL: air-dash replay guard tripped:"
    grep -m2 -E "CRASH|REGS" "$d/g.log" || tail -5 "$d/g.out"
    exit 1
}
python3 - "$d" <<'EOF'
import struct, sys
d = sys.argv[1]
rows = []
for f in (3185, 3200):
    b = open("%s/dump_%d_ff8400.bin" % (d, f), 'rb').read()
    rows.append((b[0x06], struct.unpack('>i', b[0x10:0x14])[0],
                 struct.unpack('>i', b[0x14:0x18])[0]))
seq_ok = rows[0][0] == 0x14
dx = (rows[1][1] - rows[0][1]) / 65536.0
dy = abs(rows[1][2] - rows[0][2]) / 65536.0
print("  seq=%02x dx=%.1f px dy=%.1f px over 15f" % (rows[0][0], dx, dy))
if not (seq_ok and dx >= 30 and dy < 8):
    print("FAIL: air dash did not engage (seq/trajectory off)")
    sys.exit(1)
EOF
echo "  ok: air dash engages (seq 0x14, flat accelerated dash)"

echo "PASS: Huitzil air movement (float + air dash live)"
