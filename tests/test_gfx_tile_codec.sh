#!/bin/sh
# test_gfx_tile_codec.sh — ground truth for tools/gfx_tiles.py decode/encode
# (14z-105, born with the select-screen version string's AUTHORED tiles —
# the first tiles this project ever SYNTHESIZED rather than copied).
#
# THE LAW IT LOCKS: within each 8-pixel half of a CPS-2 OBJ tile row,
# plane bit i is pixel 7-i. MEASURED 14z-105: tiles encoded with bit i =
# pixel i drew every half mirrored on the real OBJ path (MAME snapshot of
# the select screen, pixel-compared against the intended bitmap — the
# mirrored encode was caught only because "M6" is not symmetric). Nothing
# had ever consumed decode()'s pixel ORDER before (cmd_match and BLANK
# compare raw bytes), so the mirror had been invisible since the module
# was written. Transparent pen is 15.
#
# Sections (ROM-free; in tests/ci_portable.txt):
#   1  a synthetic single-pixel tile lands at the byte/bit the law says
#      (left half pixel 0 -> bit 7 of L01[0]; right half pixel 15 -> bit 0
#      of R01[0]; pen planes split across L01/L23)
#   2  decode(encode(px)) == px for random 16x16 pixel fields, and
#      encode(decode(t)) == t for random 128-byte tiles (both directions)
#   3  verdict controls: the PRE-FIX mapping (bit i = pixel i) reconstructed
#      inline must DISAGREE with encode on an asymmetric tile, and a
#      one-bit corruption must not round-trip silently
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-105 (ci_portable, ~1s): the CPS-2 OBJ tile bit law (plane bit i =
#   pixel 7-i within each 8-px half, pen 15 transparent), round trips both
#   ways, and the PRE-FIX mirrored mapping reconstructed inline and required
#   to DISAGREE on an asymmetric tile.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
python3 - <<'PY'
import sys, random
sys.path.insert(0, "tools")
from gfx_tiles import decode, encode, SEP
fail = 0
def ok(c, msg):
    global fail
    print(("  ok: " if c else "FAIL: ") + msg)
    if not c: fail = 1

print("== 1. the bit law on single pixels ==")
px = bytearray([0] * 256); px[0] = 1            # row 0, pixel 0, pen 1 (plane 0)
t = encode(px)
ok(t[0] == 0x80 and t[1] == 0 and t[32] == 0 and t[33] == 0 and t[64] == 0,
   "left-half pixel 0 pen 1 -> L01[0] bit 7 only")
px = bytearray([0] * 256); px[15] = 8           # row 0, pixel 15, pen 8 (plane 3)
t = encode(px)
ok(t[97] == 0x01 and t[96] == 0 and t[64] == 0 and t[0] == 0,
   "right-half pixel 15 pen 8 -> R23[1] bit 0 only")
px = bytearray([0] * 256); px[3 * 16 + 9] = 6   # row 3, pixel 9, pen 6 (planes 1,2)
t = encode(px)
ok(t[64 + 7] == (1 << 6) and t[96 + 6] == (1 << 6) and t[64 + 6] == 0 and t[96 + 7] == 0,
   "row 3 pixel 9 pen 6 -> R01[7] bit 6 (plane 1) + R23[6] bit 6 (plane 2)")

print("== 2. round trips both directions ==")
random.seed(14105)
for _ in range(200):
    px = bytearray(random.randrange(16) for _ in range(256))
    assert decode(encode(px)) == px
for _ in range(200):
    t = bytes(random.randrange(256) for _ in range(128))
    assert encode(decode(t)) == t
ok(True, "200 random pixel fields and 200 random tiles round-trip")

print("== 3. verdict controls ==")
def encode_prefix(px):                        # the mapping BEFORE 14z-105
    L01, L23, R01, R23 = bytearray(32), bytearray(32), bytearray(32), bytearray(32)
    for r in range(16):
        for half, (b01, b23) in ((0, (L01, L23)), (8, (R01, R23))):
            p = [0, 0, 0, 0]
            for x in range(8):
                v = px[r * 16 + half + x] & 0xF
                for k in range(4):
                    p[k] |= ((v >> k) & 1) << x
            b01[2 * r], b01[2 * r + 1], b23[2 * r], b23[2 * r + 1] = p
    return bytes(L01 + L23 + R01 + R23)
asym = bytearray([15] * 256); asym[0] = 7       # asymmetric: one corner pixel
ok(encode_prefix(asym) != encode(asym), "the pre-fix (mirrored) mapping DISAGREES on an asymmetric tile")
sym = bytearray([15] * 256)
for r in range(16): sym[r * 16 + 0] = sym[r * 16 + 7] = 7   # mirror-symmetric within the half
ok(encode_prefix(sym) == encode(sym), "…and agrees on a half-symmetric tile (why 'M' looked right)")
t = encode(asym); bad = bytearray(t); bad[5] ^= 0x10
ok(decode(bytes(bad)) != decode(t), "a one-bit corruption changes the decode")
sys.exit(fail)
PY
echo "PASS: gfx tile codec — bit law, round trips, controls"
