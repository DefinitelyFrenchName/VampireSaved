#!/usr/bin/env python3
"""audit_latch_readers.py — every instruction that TOUCHES the select-confirm
latch bytes of a fighter block, enumerated BY FORM (GitHub #151 step 3, 14z-161).

The select CONFIRM writes three per-fighter bytes for the cell the cursor is on
— the VS2/VH2 flavor `+0x3C2` and two copies of the id, `+0x3BD` and `+0x3E0`
(vs2; vsavj copies the id to `+0x3BD` and a flag `+0x3BC` to `+0x3E3`) — BEFORE
the early-window pick poke swaps the id, so a poked leg carries the cursor
character's values in them (`tests/audit_forced_pick_fidelity.sh`). Whether a
gate's subject can depend on that is a question about the READERS of those
bytes, and "never read in N frames of one rig" is absence on one path
([VSP-22]). This is the static half: the census of every instruction in an
opcode view whose effective address names one of the offsets, in every form the
68000 can write it —
  (d16,A6)   `$3bd(a6)`  the fighter block through its own base register;
  (d16,An)   any other An (the ladder reads `$3bc(a0)`);
  (d16,A5)   `$7bd(a5)` / `$bbd(a5)`  — A5 is `RAM:$FF8000`, so P1's block is
             `+0x400` and P2's `+0x800` (atlas ram.md);
  abs.l      `$ff87bd` / `$ff8bbd`  (and the short-absolute sign-extended form).
Word-sized accesses that COVER a byte are included (`$3bc` as a word reaches
`+0x3BD`): the census keys on the byte offsets and reports the access width.

Method: candidate extension words are found by a word scan (the displacement or
the absolute address as it would be encoded), then each candidate is
disassembled with capstone at the preceding opcode word and kept only if the
decoded operand names the offset — a word scan alone would list every data
table holding the value. Read/write is classified from the mnemonic and the
operand position. A linear sweep over data would invent instructions; anchoring
each decode on the extension word does not.

POSITIVE CONTROLS (--selftest): the sites the atlas already names must be found
with the stated class — vs2 `PRG:0x01F6CE` / `0x01F6C8` (writes of the copies),
`0x01F848` (the flavor write), `0x026322` / `0x02595A` / `0x02598A` (flavor
reads); vsavj `0x020AC8` (the copy), `0x00A782` (`$3bd` read), `0x00AF1C`
(`$3bc(a0)`). A census that misses a known site is blind and says so.

Usage:
  audit_latch_readers.py <opcodes.bin> [--label vs2] [--tsv out.tsv] [--selftest vs2|vsavj]
  prints the SHA-1 of the image it read ([VSP-9]).
"""
import argparse, hashlib, struct, sys
try:
    import capstone
except ImportError:
    print("FAIL: capstone is not importable"); sys.exit(2)

OFFS = {0x3BC: "flag", 0x3BD: "id-copy", 0x3C2: "flavor", 0x3E0: "id-copy-2", 0x3E3: "flag-copy"}
A5_BASE = 0xFF8000
BLOCKS = {0x400: "P1", 0x800: "P2"}

WRITERS = {"clr", "st", "sf", "move", "movea", "bset", "bclr", "bchg", "addq", "subq", "add", "sub",
           "and", "or", "eor", "neg", "not", "addi", "subi", "andi", "ori", "eori", "asl", "asr",
           "lsl", "lsr", "rol", "ror", "roxl", "roxr", "swap", "ext", "movem", "addx", "subx", "abcd",
           "sbcd", "nbcd", "tas", "negx"}
READERS = {"tst", "cmp", "cmpi", "cmpm", "btst", "chk", "movem", "lea", "pea", "jmp", "jsr"}


def classify(mn, op_str, operand_idx, nops):
    """read / write / rw for the operand at operand_idx of an instruction."""
    stem = mn.split(".")[0]
    if stem in ("tst", "cmp", "cmpi", "btst", "chk"):
        return "read"
    if stem in ("clr", "st", "sf"):
        return "write"
    if stem in ("move", "movea"):
        return "read" if operand_idx == 0 else "write"
    if stem in ("bset", "bclr", "bchg", "tas", "not", "neg", "negx", "nbcd"):
        return "rw"
    if stem in ("addq", "subq", "addi", "subi", "andi", "ori", "eori", "add", "sub", "and", "or", "eor",
                "asl", "asr", "lsl", "lsr", "rol", "ror", "roxl", "roxr"):
        return "rw" if (nops == 1 or operand_idx == nops - 1) else "read"
    if stem in ("lea", "pea"):
        return "address"
    if stem == "movem":
        return "read" if operand_idx == 0 else "write"
    return "read?"


def encodings(off):
    """(matching extension-word value, description) pairs for one offset."""
    out = [(off, f"d16=${off:x}")]
    for base, blk in BLOCKS.items():
        out.append((base + off, f"d16(a5)=${base + off:x} {blk}"))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image")
    ap.add_argument("--label", default="")
    ap.add_argument("--tsv")
    ap.add_argument("--selftest", choices=["vs2", "vsavj"])
    a = ap.parse_args()
    img = open(a.image, "rb").read()
    print(f"{a.image}: {len(img)} bytes sha1 {hashlib.sha1(img).hexdigest()}")
    md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_M68K_000)
    md.detail = False
    n = len(img) // 2
    words = struct.unpack(f">{n}H", img[:n * 2])
    # candidate extension words
    want = {}
    for off in OFFS:
        for enc, desc in encodings(off):
            want.setdefault(enc, []).append((off, desc))
    abs_want = {}
    for base in BLOCKS:
        for off in OFFS:
            abs_want[A5_BASE + base + off] = off
    rows = []
    seen = set()
    for i in range(1, n):
        w = words[i]
        cands = []
        if w in want:
            cands.append(("d16", w))
        # abs.l: the high word 0x00FF then the low word
        if w == 0x00FF and i + 1 < n and (0x00FF0000 | words[i + 1]) in abs_want:
            cands.append(("absl", 0x00FF0000 | words[i + 1]))
        if not cands:
            continue
        # the opcode word is 1 or 2 words before (a preceding immediate/other ext word)
        for back in (1, 2, 3):
            if i - back < 0:
                continue
            addr = (i - back) * 2
            ins = next(md.disasm(img[addr:addr + 10], addr, count=1), None)
            if ins is None or ins.size < (back + 1) * 2:
                continue
            ops = [o.strip() for o in ins.op_str.split(",")] if ins.op_str else []
            for kind, val in cands:
                for oi, o in enumerate(ops):
                    hit = None
                    if kind == "d16":
                        for off, desc in want[val]:
                            if val == off and f"${off:x}(a" in o:
                                hit = (off, o)
                            elif val != off and f"${val:x}(a5)" in o:
                                hit = (off, o)
                    else:
                        if f"${val:x}" in o or f"${val & 0xFFFFFF:x}" in o:
                            hit = (abs_want[val], o)
                    if hit and (addr, oi) not in seen:
                        seen.add((addr, oi))
                        off, o = hit
                        width = ins.mnemonic.split(".")[1] if "." in ins.mnemonic else "?"
                        cls = classify(ins.mnemonic, ins.op_str, oi, len(ops))
                        rows.append((addr, off, OFFS[off], cls, width, ins.mnemonic, ins.op_str))
            break  # the nearest decodable opcode wins; a farther one would straddle it
    rows.sort()
    lab = a.label or a.image
    print(f"== {lab}: {len(rows)} instruction operands name a latch offset")
    for addr, off, what, cls, width, mn, ops in rows:
        print(f"  PRG:0x{addr:06X}  +0x{off:03X} {what:10s} {cls:7s} .{width}  {mn} {ops}")
    if a.tsv:
        with open(a.tsv, "w") as f:
            f.write("# audit_latch_readers.py — instruction operands naming a confirm-latch offset\n")
            f.write(f"# image {a.image} sha1 {hashlib.sha1(img).hexdigest()}\n")
            f.write("addr\toffset\twhat\tclass\twidth\tmnemonic\toperands\n")
            for addr, off, what, cls, width, mn, ops in rows:
                f.write(f"0x{addr:06X}\t0x{off:03X}\t{what}\t{cls}\t{width}\t{mn}\t{ops}\n")
    if a.selftest:
        ctl = {"vs2": [(0x01F6CE, 0x3BD, "write"), (0x01F6C8, 0x3E0, "write"), (0x01F848, 0x3C2, "write"),
                       (0x026322, 0x3C2, "read"), (0x02595A, 0x3C2, "read"), (0x02598A, 0x3C2, "read")],
               "vsavj": [(0x020AC8, 0x3BD, "write"), (0x020ACE, 0x3E3, "write"), (0x00A782, 0x3BD, "read"),
                         (0x00AF1C, 0x3BC, "read")]}[a.selftest]
        have = {(r[0], r[1]): r[3] for r in rows}
        bad = 0
        for addr, off, cls in ctl:
            got = have.get((addr, off))
            if got == cls:
                print(f"  ok    control PRG:0x{addr:06X} +0x{off:X} {cls}")
            else:
                print(f"  FAIL  control PRG:0x{addr:06X} +0x{off:X} expected {cls}, census says {got}"); bad += 1
        if bad:
            print("FAIL: audit_latch_readers selftest — the census is blind to a known site"); sys.exit(1)
        print("PASS: audit_latch_readers selftest")


if __name__ == "__main__":
    main()
