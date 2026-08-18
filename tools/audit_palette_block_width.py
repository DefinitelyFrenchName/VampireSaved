#!/usr/bin/env python3
"""How wide are the per-character palette-block tables really?

Consumers index them (id & 0xF) * 0x400 — 16 blocks of 1KB — but two
select-screen sites do NOT mask, so a tenant on a variant id would read past
the end. This checks where each table actually stops, by looking for the
point at which blocks stop looking like palette data.

A CPS-2 palette word is 4-bit-per-channel; a block of 0x400 bytes is 512
words. Real palette blocks are dense in the 0x0000-0xFFFF range with
structure; padding/other data tends to be 0xFF runs or wildly different.
"""
import sys

d = open(sys.argv[1], "rb").read()
BASES = [0x3A4400, 0x3C13C8, 0x3D25F0, 0x3E6938]
BLK = 0x400


def looks_like_palette(b):
    if len(b) < BLK:
        return False
    ff = b.count(0xFF)
    zero = b.count(0x00)
    return ff < BLK * 0.5 and zero < BLK * 0.9


for base in BASES:
    n = 0
    for i in range(40):
        if looks_like_palette(d[base + i * BLK: base + (i + 1) * BLK]):
            n = i + 1
        else:
            break
    end16 = base + 16 * BLK
    print("table %06X: %2d consecutive palette-like blocks "
          "(16 blocks end at %06X)" % (base, n, end16))
    print("   block 16 (what id 0x10 would read): %s"
          % d[end16:end16 + 16].hex())
    print("   block 19 (what id 0x13 would read): %s"
          % d[base + 19 * BLK: base + 19 * BLK + 16].hex())
