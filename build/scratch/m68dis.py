#!/usr/bin/env python3
"""Scratch 68k disassembler with resync — analysis aid, not a build tool.

Usage: m68dis.py <image.bin> <start_hex> <end_hex>
Remember which VIEW you want: opcodes image for code, data image for
tables reached via lea/movea + (An,Dn) (docs/GOTCHAS.md).
"""
import sys
import capstone

img = open(sys.argv[1], "rb").read()
start = int(sys.argv[2], 16)
end = int(sys.argv[3], 16)
md = capstone.Cs(capstone.CS_ARCH_M68K,
                 capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)
a = start
while a < end:
    got = False
    for i in md.disasm(img[a:end], a, count=1):
        print("%06X  %-20s %-10s %s"
              % (i.address, i.bytes.hex(), i.mnemonic, i.op_str))
        a += i.size
        got = True
    if not got:
        w = img[a] << 8 | img[a + 1]
        print("%06X  %-20s .word      $%04x" % (a, img[a:a + 2].hex(), w))
        a += 2
