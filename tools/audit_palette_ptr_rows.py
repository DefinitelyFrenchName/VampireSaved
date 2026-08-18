#!/usr/bin/env python3
"""Is the sprite-palette POINTER table at 0x38C198 16 or 32 rows?

It matters for the 0x13 move: a pointer row can be redirected for a tenant
without disturbing anyone else, but only if the row exists. The consumer
(PRG:0x01C3FE) indexes it from $100(a5) with NO mask and bounds the value
against #$20, which suggests 32.
"""
import struct
import sys

d = open(sys.argv[1], "rb").read()
BASE = 0x38C198
print("rows at %06X (longs):" % BASE)
rows = []
for i in range(36):
    v = struct.unpack(">I", d[BASE + i * 4:BASE + i * 4 + 4])[0]
    rows.append(v)
    plaus = 0x300000 <= v < 0x400000
    tag = ""
    if i == 16:
        tag = "   <-- first VARIANT-half row"
    print("  %2d (%#04x): %08X %s%s"
          % (i, i, v, "ptr" if plaus else "?", tag))
    if i == 31:
        print("     ---- 32-row boundary ----")
lo, hi = rows[0:16], rows[16:32]
print("\nupper 16 rows == lower 16 rows:", lo == hi)
print("all 32 rows ROM-plausible pointers:",
      all(0x300000 <= v < 0x400000 for v in rows[:32]))
