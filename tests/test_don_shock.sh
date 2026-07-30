#!/bin/sh
# test_don_shock.sh — Victor-shock-on-Donovan stale-OBJ gate (session 14z-7).
#
# Verifies the round-27 garble fix: the VS-screen leftovers (Donovan's
# portrait pieces) in the OBJ-list tail buckets must be CLEARED by the
# countdown blob (init-shim marker at $FF7F00, consumed ~0x50 match
# frames in by the sword-routine detour) before Victor's 236HP curtain
# re-displays those buckets. Probe: replay 32_victor_shock_vsavj; at the
# shock zap (f2740) the tail buckets 0x708600-0x70865F and
# 0x708A60-0x708A9F must be all-zero (pre-fix: fc1b/c625/fbc9 stale mix,
# garbled tiles on the victim).
#
# Usage: ROMDIR=... tests/test_don_shock.sh [rompath_dir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

DUMPS="2740:708000-709000" REPLAY="$REPO/tests/replays/32_victor_shock_vsavj.rpl" \
    CHECKSUM_OUT="$WORK/c.log" MAME_SANDBOX="$WORK" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK" <<'EOF'
import glob, os, sys
d = open(glob.glob(os.path.join(sys.argv[1], 'dump_2740_708000.bin'))[0], 'rb').read()
bad = []
for lo, hi in ((0x600, 0x660), (0xA60, 0xAA0)):
    for o in range(lo, hi, 8):
        code = int.from_bytes(d[o+4:o+6], 'big')
        if code:
            bad.append((0x708000+o, code))
if bad:
    print("FAIL: stale tail entries live at the shock zap:")
    for a, c in bad[:12]:
        print(f"  {a:06x}: code {c:04x}")
    sys.exit(1)
print("  ok: OBJ tail buckets clear at the shock zap (f2740)")
EOF
echo "PASS: Donovan shock stale-OBJ gate"
