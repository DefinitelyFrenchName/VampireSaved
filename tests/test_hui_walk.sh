#!/bin/sh
# test_hui_walk.sh — Huitzil velocity-port gate (14z-66, playtest
# round-1 item 2 "feels a bit slower").
#
# Mechanism (measured): both vsavj param32 tables are 32-row with rows
# 0x10-0x1F byte-aliasing 0x00-0x0F, and all three consumers index the
# RAW +0x382 id (no fold) — so tenant 0x10 moved at the ALIAS CONTENT
# (Bulleta's rows) until port_param32 wrote his true vs2 pairs into
# variant rows 0x10 (superset-safe by the op invariant; vanilla rows
# 0x00-0x0F untouched).
#
# Two sections:
#   1. STATIC — the built zip's data view carries his true pairs at
#      rows 0x10 and the vanilla rows are pristine.
#   2. DYNAMIC — replay 74 (steady forward walk, dumps before push-box
#      contact): the 15-frame 16.16 X deltas equal the FROZEN measured
#      values 0x1C2000 / 0x384000. The walk has an anim-driven phase
#      profile (the two windows run 0.6x / 1.2x of nominal), so the
#      frozen values are the profile times HIS 0x32000 — both scale by
#      exactly 25/24 vs the alias build (measured on e8d95a5c-family
#      pre-port builds: 0x1B0000 / 0x360000, the natural negative
#      control this gate fails back to if the port evaporates).
#
# Usage: ROMDIR=... tests/test_hui_walk.sh [existing-stage4-builddir]
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

echo "== static: variant rows carry his pairs, vanilla rows pristine"
python3 tools/cps2_decrypt.py "$BUILD/rompath/vsavjw.zip" "$WORK/op.bin" \
    --data-out "$WORK/data.bin" > /dev/null
python3 - "$WORK/data.bin" <<'EOF'
import sys
d = open(sys.argv[1], 'rb').read()
checks = [
    ("param32_a[0x10] (his pair)",  0x0BD8FA, "00032000fffd4000"),
    ("param32_b[0x10] (his pair)",  0x0BE37A, "0001a000fffdc000"),
    ("param32_a[0x00] (vanilla)",   0x0BD87A, "00030000fffd4000"),
    ("param32_b[0x00] (vanilla)",   0x0BE2FA, "00020000fffd4000"),
]
bad = 0
for name, addr, want in checks:
    got = d[addr:addr+8].hex()
    ok = got == want
    bad += 0 if ok else 1
    print("  %s %s: %s" % ("ok:" if ok else "FAIL:", name, got))
sys.exit(1 if bad else 0)
EOF

echo "== dynamic: walk-speed deltas (replay 74)"
( cd "$WORK" && \
  POKES="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10" \
  DUMPS="3060:ff8410-ff8414;3075:ff8410-ff8414;3090:ff8410-ff8414" \
  MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
  "$REPO/tools/run_replay_guarded.sh" vsavjw "$REPO/tests/replays/hui/74_hui_walk.rpl" \
      "$WORK/g.log" "$WORK/box" > "$WORK/g.out" 2>&1 ) || {
    echo "FAIL: walk replay guard tripped:"
    grep -m2 -E "CRASH|REGS" "$WORK/g.log" || tail -5 "$WORK/g.out"
    exit 1
}
python3 - "$WORK" <<'EOF'
import struct, sys
w = sys.argv[1]
xs = []
for f in (3060, 3075, 3090):
    d = open("%s/dump_%d_ff8410.bin" % (w, f), 'rb').read()
    xs.append(struct.unpack('>i', d[:4])[0])
d1, d2 = xs[1] - xs[0], xs[2] - xs[1]
want = (0x1C2000, 0x384000)
print("  d1=0x%06x d2=0x%06x (frozen 0x%06x/0x%06x; alias build reads 0x1B0000/0x360000)"
      % (d1, d2, *want))
if (d1, d2) != want:
    print("FAIL: walk deltas off the frozen values")
    sys.exit(1)
EOF
echo "  ok: his forward velocity serves movement"

echo "PASS: Huitzil velocity port (static rows + measured walk speed)"
