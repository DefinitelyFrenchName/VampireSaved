#!/bin/sh
# test_don_accent.sh — weapon-accent steadiness + Victor-accent legacy
# guard (session 14z-19, rounds 34-35).
#
# Mechanism under test (docs/patch_notes.md 14z-19): the engine MARCHES
# palette row 0x0C (P1 weapon row) through accent slots T0 (0x39FBE0)
# and T1 (0x39FC00) plus the sprite block; for slot 0x0F both slots
# must hold row-C content so every phase uploads the same bytes (the
# vs2 steady look through the vsavj march). The 14z-18 regression to
# guard forever: 0x39B040 is VICTOR's accent data (P2 rows 0x10/0x11
# are the P2 CHARACTER's rows) — it must stay byte-identical to
# vanilla, and Victor's row-0x10 glow must still CYCLE in-match.
# Palette ROM->palette RAM never transits work RAM, so the masked
# legacy gate is blind here — this static+pixel-adjacent gate is the
# only guard.
#
# Usage: ROMDIR=... tests/test_don_accent.sh [rompath_dir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

# ── 1. static ROM asserts (fast, no emulator) ────────────────────────
python3 - "$RPDIR" <<'EOF'
import sys, zipfile, hashlib
rp = sys.argv[1]
d = zipfile.ZipFile(f'{rp}/vsavj.zip').read('vm3j.10b')
van = open('build/out/vsavj_data.bin','rb').read()
vs2 = open('build/out/vsav2_data.bin','rb').read()
def swap(b): return bytes(x for i in range(0,len(b),2) for x in (b[i+1], b[i]))
t0, t1, t2 = d[0x1FBE0:0x1FC00], d[0x1FC00:0x1FC20], d[0x1FC20:0x1FC40]
assert t0 == t1 == swap(vs2[0x39CBDC:0x39CBFC]), "accent T0/T1 must both hold vs2 row-C"
assert t2 == swap(vs2[0x39CBFC:0x39CC1C]), "accent row-D slot must hold vs2 row-D"
assert d[0x1B040:0x1B080] == swap(van[0x39B040:0x39B080]), \
    "VICTOR ACCENT 0x39B040-7F MODIFIED — superset violation (14z-18 regression)"
print("  ok: static — T0==T1==vs2 rowC, rowD slot, Victor accent pristine")
EOF

# ── 2. behavioral: replay 31 idle window, palette RAM per frame ──────
DUMPS=$(python3 -c "print(';'.join(f'{f}:90c180-90c23f' for f in range(2440,2480)))")
DUMPS="$DUMPS" REPLAY="$REPO/tests/replays/31_don_6hp_vsavj.rpl" \
    CHECKSUM_OUT="$WORK/c.log" MAME_SANDBOX="$WORK" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK" <<'EOF'
import glob, os, sys
work = sys.argv[1]
dumps = {}
for p in glob.glob(os.path.join(work, 'dump_*_90c180.bin')):
    dumps[int(os.path.basename(p).split('_')[1])] = open(p, 'rb').read()
frames = sorted(dumps)
assert len(frames) >= 30, f"only {len(frames)} dumps captured"
# dump covers rows 0x0C.. at offset 0: row 0x0C = [0:0x20], row 0x10 = [0x80:0xA0]
rowc = {dumps[f][0x00:0x20] for f in frames}
row10 = {dumps[f][0x80:0xA0] for f in frames}
# frozen native-vs2 row 0x0C content (measured live, session 14z-19)
NATIVE_C = bytes.fromhex(
    'f000fffffdfffcdff9adf87af635ffeafdb8fa86f864f653fbcef88bfe00f002')
assert rowc == {NATIVE_C}, \
    f"row 0x0C not steady/native ({len(rowc)} variants): " + \
    "; ".join(v.hex() for v in sorted(rowc)[:3])
print(f"  ok: row 0x0C steady over {len(frames)} frames, native-vs2 content")
# rows 0x0E/0x0F: the 14z-20 fixture-override thunk must yield native
# content (row 0x0F = the statue red ramp; measured live on vs2).
# GOTCHA guarded here: a hole-"a" thunk placement stores embedded data
# as ciphertext (crypt range) — this catches any regression to garbage.
NATIVE_E = bytes.fromhex(
    'fd00fffffdddfbbbf33bf54ff65ff76ff216f111f112f113f115f216f228f000')
NATIVE_F = bytes.fromhex(
    'f01dfffffdddfbbbfa22fe32fe43fe54f500f000f100f200f400f500f611f001')
rowe = {dumps[f][0x40:0x60] for f in frames}
rowf = {dumps[f][0x60:0x80] for f in frames}
assert rowe == {NATIVE_E}, f"row 0x0E wrong: {sorted(rowe)[0].hex()}"
assert rowf == {NATIVE_F}, f"row 0x0F wrong (fixture override): {sorted(rowf)[0].hex()}"
print("  ok: rows 0x0E/0x0F native (fixture override live, data readable)")
assert len(row10) == 2, \
    f"P2 Victor row 0x10 must CYCLE (vanilla glow) — saw {len(row10)} variant(s)"
print("  ok: Victor row 0x10 glow cycling (legacy behavior alive)")
EOF
echo "PASS: Donovan weapon-accent + Victor-accent gate"
