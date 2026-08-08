#!/bin/sh
# test_don_sword.sh — Donovan sword-swing behavior gate (session 14z-5).
#
# Verifies the round-26 sword-swing fix: on 6HP the sword object
# ($FF9500 on the ported build) must be COMMANDED into the swing anim
# family. Mechanism under test (see docs/project/patch_notes.md 14z-5): the
# ported sword-command code resolves anim numbers 0x124-0x201 through
# the UNMASKED set-anim clone (reconciliation kind patched_clone for
# vs2 0x5C77E); the vanilla masked resolver would truncate them and the
# sword would idle through attacks (the round-20..26 missing-swing bug).
#
# Probe: replay 31_don_6hp_vsavj (round-start whiff 6HP at ~2610). The
# swing resolves node 0x0E1A20 (= vs2 0x28DEF8, Donovan's table via
# 0xBD07A row 0x0F) and writes idx +9=00 within a frame of it. The
# node address is anim-region-placement dependent: if the donovan anim
# region moves from 0x0D3070, re-derive (vs2 node 0x28DEF8 - 0x27F548
# + <new base>) and re-freeze.
#
# Usage: ROMDIR=... tests/test_don_sword.sh [rompath_dir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

DUMPS=$(python3 -c "print(';'.join(f'{f}:ff9500-ff9560' for f in range(2606,2620,2)))")
DUMPS="$DUMPS" REPLAY="$REPO/tests/replays/31_don_6hp_vsavj.rpl" \
    CHECKSUM_OUT="$WORK/c.log" MAME_SANDBOX="$WORK" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK" <<'EOF'
import glob, os, sys
work = sys.argv[1]
seen = {}
for p in glob.glob(os.path.join(work, 'dump_*_ff9500.bin')):
    fr = int(os.path.basename(p).split('_')[1])
    d = open(p, 'rb').read()
    seen[fr] = (int.from_bytes(d[0x1C:0x20], 'big'), d[9])
# swing must appear: node 0xE1A20 reached with idx +9 == 0 on some probe frame
hit = [fr for fr, (a, i) in seen.items() if a == 0xE1A20 and i == 0]
walk = sorted(a for a, _ in seen.values())
if hit:
    print(f"  ok: sword swing commanded (node 0xE1A20, idx 0 at frame {hit[0]})")
    sys.exit(0)
print("FAIL: sword never entered the swing node 0xE1A20 with idx 0")
for fr in sorted(seen):
    a, i = seen[fr]
    print(f"  f{fr}: anim={a:06x} +9={i:02x}")
sys.exit(1)
EOF
echo "PASS: Donovan sword-swing gate"
