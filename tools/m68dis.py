#!/usr/bin/env python3
"""m68dis.py <image.bin> <start_hex> <end_hex> — linear m68k disassembly
with raw bytes (capstone, M68K_000, big-endian).

The session workhorse for reading decrypted views (build/out/*_opcodes.bin
— remember: PC-relative reads live in the OPCODE view, data-path reads in
the DATA view; docs/GOTCHAS.md). Prints the SHA-1 of the image it reads
(project convention). Addresses are PRG offsets == CPU addresses for the
low 4MB. Undecodable words print as dc.w and advance by 2 — fine for
linear reads through data; fix your start address if a known routine
decodes as garbage (RH-11: framing decides "is there an instruction
here"). Promoted from scratch 14z-85g after serving three sessions'
disassembly (FG damage, trap sound, trap shock).
"""
import sys, hashlib
import capstone

def main():
    img_path, start, end = sys.argv[1], int(sys.argv[2], 16), int(sys.argv[3], 16)
    data = open(img_path, "rb").read()
    print(f"# {img_path}  sha1 {hashlib.sha1(data).hexdigest()}")
    md = capstone.Cs(capstone.CS_ARCH_M68K,
                     capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)
    addr = start
    while addr < end:
        got = False
        for insn in md.disasm(data[addr:addr + 10], addr):
            print(f"{insn.address:08x}  {insn.bytes.hex():<20} {insn.mnemonic} {insn.op_str}")
            addr += insn.size
            got = True
            break
        if not got:
            w = data[addr:addr + 2].hex()
            print(f"{addr:08x}  {w:<20} dc.w ${w}   ; UNDECODED")
            addr += 2

main()
