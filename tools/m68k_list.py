#!/usr/bin/env python3
"""m68k_list.py — a 68000 listing of a range of a decrypted OPCODE view, mnemonics only (14z-195, promoted from the
#118 pilot's scratch reader of 14z-194, GitHub #118).

  python3 tools/m68k_list.py <opcodes.bin> <hex start> <hex end>

The reader the static rows of docs/game/atlas/ram.md cite ("static reads") for #118: each instruction of
[start, end) as `address  mnemonic operands`, decoded by capstone in 68000 mode, one instruction at a time from
`start` (an undecodable word prints `??` and advances 2 bytes). It prints MNEMONICS ONLY — never the raw bytes —
so nothing ROM-verbatim is reproduced (CLAUDE.md rule 7). The image is any opcode view (`tools/cps2_decrypt.py`
output, `build/out/<set>_opcodes.bin`, a build's verify_op.bin); a range inside the encrypted window must be read
from the OPCODE view, a PC-relative DATA table from the opcode view too ([VSP-63]).

Not a gate: a diagnostic reader. Named m68k_list, never `dis.py`, which shadows the standard library's `dis`.
"""
import sys


def listing(img, lo, hi):
    """Yield (address, text) for every instruction of img[lo:hi], one decode at a time."""
    import capstone
    md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)
    a = lo
    while a < hi:
        ins = next(md.disasm(img[a:a + 10], a, count=1), None)
        if not ins:
            yield a, "??"
            a += 2
            continue
        yield a, f"{ins.mnemonic} {ins.op_str}".rstrip()
        a += ins.size


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    img = open(sys.argv[1], "rb").read()
    lo, hi = int(sys.argv[2], 16), int(sys.argv[3], 16)
    for a, text in listing(img, lo, hi):
        print(f"{a:06x}  {text}")


if __name__ == "__main__":
    main()
