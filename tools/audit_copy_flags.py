#!/usr/bin/env python3
"""audit_copy_flags.py — the copy-character flags (Shadow +0x3BC, Marionette +0x3C3) and
their select-screen arming counters, per game (14z-189, GitHub #128).

WHAT IT MEASURES. A linear capstone disassembly of the program's code region
(`--hi`, default 0xC0000) of one opcode view, and:
  SITES   every instruction whose operand text names `$3bc(aN)` / `$3c3(aN)`
          (a count, and the addresses);
  ARM     every `cmpi.b #$n,$42(a6)` (Shadow's START counter) and
          `cmpi.b #$n,$48(a6)` (vs2's second counter) with its immediate;
  SET     every `st.b $3bc(a6)` / `st.b $3c3(a6)` (the flag writers).
Linear disassembly can mis-frame inside data; the counts are what this
framing finds, and the gate freezes them as such (RH-11: framing decides
"is there an instruction here").

Usage: audit_copy_flags.py <game> <opcodes.bin> [--hi 0xC0000]
Prints the SHA-1 of the image. Exit 0 always — the gate judges.
"""
import argparse, re
import hashlib

import capstone


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("game")
    ap.add_argument("op")
    ap.add_argument("--hi", type=lambda x: int(x, 0), default=0xC0000)
    a = ap.parse_args()
    img = open(a.op, "rb").read()
    print(f"# {a.game} {a.op} sha1 {hashlib.sha1(img).hexdigest()}")
    md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)
    sites = {"$3bc": [], "$3c3": []}
    # the OTHER ways code could name the two flags (rule-checker run 2026-10-03-595 Q4): a5-relative at the second
    # block (+0x400 / +0x800 from P1's), or the absolute addresses $FF87xx / $FF8Bxx — every textual match is LISTED,
    # immediates and branch targets included, so the frozen list shows each one is or is not an access
    alt_re = re.compile(r"\$(7c3|bc3|7bc|bbc)\(a|\$f*8[7b](c3|bc)\b")
    alt = []
    # WIDTH-AWARE (rule-checker run 2026-10-03-599 Q4; NOT movem, absolute word/long, index or computed addresses —
    # rule-checker run 2026-10-03-600): a .w or .l access at a NEIGHBOURING displacement also touches a
    # flag byte (e.g. a word at +0x3C2, a long at +0x3C0). Every displacement access whose covered bytes include a flag
    # byte at any of the three blocks (+0, +0x400, +0x800) WITHOUT naming it is listed as WIDE.
    disp_re = re.compile(r"(-?)\$([0-9a-f]+)\(a[0-7]")
    flags = {base + off: name for off, name in ((0x3BC, "3bc"), (0x3C3, "3c3")) for base in (0, 0x400, 0x800)}
    wide = []
    arm, setters = [], []
    pc = 0
    while pc < a.hi:
        ins = next(md.disasm(img[pc:pc + 10], pc), None)
        if ins is None:
            pc += 2
            continue
        t = f"{ins.mnemonic} {ins.op_str}"
        for k in sites:
            if f"{k}(a" in t:
                sites[k].append(pc)
        size = {"b": 1, "w": 2, "l": 4}.get(ins.mnemonic.rsplit(".", 1)[-1], 0) if "." in ins.mnemonic else 0
        base_mn = ins.mnemonic.split(".")[0]
        if base_mn in ("btst", "bchg", "bclr", "bset"):
            size = 1          # a bit op on MEMORY is byte-sized whatever the decoder's suffix
        for m in disp_re.finditer(t):
            d = int(m.group(2), 16) * (-1 if m.group(1) else 1)
            covered = range(d, d + 2 * size, 2) if base_mn == "movep" else range(d, d + size)   # movep: alternate bytes
            hit = sorted({flags[b] + (f"@+{b - (b & 0xFF00) + 0:x}" if False else "") for b in covered if b in flags and b != d})
            if hit:
                wide.append(f"{pc:06x}:{t.replace(' ', '')}->{'/'.join(hit)}")
        if alt_re.search(t):
            alt.append(f"{pc:06x}:{t.replace(' ', '')}")
        if ins.mnemonic == "cmpi.b" and ("$42(a6)" in t or "$48(a6)" in t):
            arm.append(f"{pc:06x}:{t.replace(' ', '')}")
        if ins.mnemonic == "st.b" and ("$3bc(a6)" in t or "$3c3(a6)" in t):
            setters.append(f"{pc:06x}:{t.replace(' ', '')}")
        pc += ins.size
    for k, v in sites.items():
        print(f"SITES {a.game} {k} {len(v)}")
    print(f"ALTFORMS {a.game} " + (" ".join(alt) or "none"))
    print(f"WIDE {a.game} " + (" ".join(wide) or "none"))
    print(f"ARM {a.game} " + (" ".join(arm) or "none"))
    print(f"SET {a.game} " + (" ".join(setters) or "none"))


if __name__ == "__main__":
    main()
