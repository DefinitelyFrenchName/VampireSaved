#!/usr/bin/env python3
"""Enumerate the per-slot VENUE-ASSET consumers.

`PRG:0x00A43E` folds the character id to 4 bits and stores it at
`$130(a5)`. That work var is read at ~15 sites which index per-character
asset tables (palette blocks, portraits, names, mugshots). Those tables are
16 WIDE, so a tenant on a variant id inherits its base character's assets
until they are widened — this lists what would have to grow.

For each read site: the mask applied, the index scaling, and the table base.
"""
import sys
import capstone

img = open(sys.argv[1], "rb").read()
md = capstone.Cs(capstone.CS_ARCH_M68K,
                 capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)


def mn(i):
    return i.mnemonic.split(".")[0]


sites = []
for a in range(0, 0x100000, 2):
    if img[a:a + 2] != b"\x01\x30":
        continue
    ins = list(md.disasm(img[a - 2:a + 8], a - 2, count=1))
    if not ins:
        continue
    i = ins[0]
    if i.size < 4 or "$130(a5)" not in i.op_str:
        continue
    src, _, dst = i.op_str.partition(", ")
    if "$130(a5)" not in src:
        continue                      # a write, not a read
    sites.append(a - 2)

print("reads of $130(a5): %d\n" % len(sites))
SCALE = {"ror": lambda n: "id << %d" % (16 - n), "lsl": lambda n: "id << %d" % n,
         "add": lambda n: "id * 2 (add)", "asl": lambda n: "id << %d" % n}
for s in sites:
    ins = list(md.disasm(img[s:s + 64], s, count=14))
    mask = scale = base = None
    for i in ins[1:]:
        m = mn(i)
        o = i.op_str
        if m in ("rts", "jmp") or (m.startswith("b") and m not in
                                   ("bset", "bclr", "btst", "bchg")):
            break
        if mask is None and m in ("andi", "and") and "#$" in o:
            mask = int(o.split("#$")[1].split(",")[0], 16)
        if scale is None and m in ("ror", "rol", "lsl", "asl") and "#$" in o:
            n = int(o.split("#$")[1].split(",")[0], 16)
            scale = "%s #%d" % (m, n)
        if base is None and m in ("lea", "movea") and "$" in o:
            t = o.split("$")[1].split(".")[0].split(",")[0].strip()
            try:
                v = int(t, 16)
                if 0x100000 <= v < 0x400000:
                    base = v
            except ValueError:
                pass
    print("  %06X  mask=%-6s scale=%-9s table=%s"
          % (s, ("#$%02x" % mask) if mask is not None else "none",
             scale or "none", ("%06X" % base) if base else "-"))
