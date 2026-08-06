#!/usr/bin/env python3
"""scan_code_refs.py — 68k operand triage over a plaintext code blob.

Finds and labels candidate references inside extracted (decrypted) 68000
code: absolute-long operands after known opcodes, bare ROM-range longwords
(unknown context), and char-id 0x13 immediates. Used by extract_char.py on
the Donovan code region; the vsav2<->vhunt2 blob diff remains the
authoritative completeness check for relocatable fields (every shifting
field must be a diff site) — this scanner adds semantics and catches
same-value references (RAM/hardware, and engine refs whose address happens
to coincide across the sibling sets).

Labels:
  jsr/jmp/pea/lea/movea/move_src/cmpi_l  known opcode immediately before an
                                         abs.l operand — high confidence
  bare_long                              ROM-plausible BE long, no known
                                         opcode context — triage
  charid_imm                             word 0x0013 after a cmpi.b/cmpi.w
                                         opcode — Donovan's vsav2 char id;
                                         he becomes 0x0F in vsavj

Target classes (--base gives the blob's ROM address):
  internal  inside [base, base+len)            -> relocate by region delta
  ram_hw    0xFF0000+ work RAM or 0x400000-0xFFFFFF I/O space -> leave
  rom       elsewhere in PRG 0x000000-0x3FFFFF -> engine/data ref (R1 unless
            it falls inside another extracted region)

Usage:
    python3 tools/scan_code_refs.py <blob.bin> --base 0x5AE20 [--json out]

As a module: scan(blob: bytes, base: int) -> list of dicts.
"""

import argparse
import json
import sys
from pathlib import Path

# opcode word -> label, for opcodes taking an abs.l EA in the extension words
# (An register field masked out where applicable)
_OP_LABELS = [
    (0xFFFF, 0x4EB9, "jsr"),
    (0xFFFF, 0x4EF9, "jmp"),
    (0xFFFF, 0x4879, "pea"),
    (0xF1FF, 0x41F9, "lea"),        # lea abs.l,An
    (0xF1FF, 0x2079, "movea"),      # movea.l abs.l,An
    (0xF1FF, 0x2039, "move_src"),   # move.l abs.l,Dn
    (0xF1FF, 0x207C, "movea_imm"),  # movea.l #imm,An (table-base loads)
    (0xF1FF, 0x203C, "move_imm"),   # move.l #imm,Dn
    (0xFFFF, 0x0C80, "cmpi_l"),     # cmpi.l #imm,D0 (watchdog-style)
]


def _label_for(op):
    for mask, val, label in _OP_LABELS:
        if (op & mask) == val:
            return label
    return None


def _classify(target, base, length):
    if base <= target < base + length:
        return "internal"
    if 0xFF0000 <= target <= 0xFFFFFF:
        return "ram_hw"
    if 0x400000 <= target < 0xFF0000:
        return "ram_hw"  # I/O / QSound / gfx space
    if target < 0x400000:
        return "rom"
    return "other"


def scan(blob, base, charid=0x13):
    """Return candidate reference sites, most-confident label per offset.
    charid: the source char's id — pass 3 matches ITS immediate word (was a
    hardcoded 0x0013, so any non-Donovan tenant's id sites were silently
    missed; 14z-65)."""
    n = len(blob)
    refs = {}

    def word(i):
        return (blob[i] << 8) | blob[i + 1]

    def long_(i):
        return (word(i) << 16) | word(i + 2)

    # pass 1: abs.l operands after known opcodes (even offsets)
    for i in range(0, n - 5, 2):
        label = _label_for(word(i))
        if label:
            v = long_(i + 2)
            if v < 0x1000000:  # 24-bit bus; upper byte 0 in practice
                refs[i + 2] = {"off": i + 2, "width": 32, "target": v,
                               "how": label,
                               "class": _classify(v, base, n)}

    # pass 2: bare ROM-plausible longs (triage; skip offsets already labeled)
    for i in range(0, n - 3, 2):
        if i in refs or (i - 2) in refs:
            continue
        v = long_(i)
        if 0x000100 <= v < 0x400000 and v % 2 == 0:
            refs[i] = {"off": i, "width": 32, "target": v, "how": "bare_long",
                       "class": _classify(v, base, n)}

    # pass 3: char-id immediates after cmpi.b/cmpi.w on any EA
    out = sorted(refs.values(), key=lambda r: r["off"])
    for i in range(0, n - 3, 2):
        op = word(i)
        if (op & 0xFF00) == 0x0C00 and (op & 0x00C0) in (0x0000, 0x0040):
            if word(i + 2) == charid:
                out.append({"off": i + 2, "width": 16, "target": charid,
                            "how": "charid_imm", "class": "charid"})
    return sorted(out, key=lambda r: r["off"])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("blob", type=Path)
    ap.add_argument("--base", required=True, type=lambda x: int(x, 0))
    ap.add_argument("--json", type=Path)
    args = ap.parse_args()

    blob = args.blob.read_bytes()
    refs = scan(blob, args.base)
    counts = {}
    for r in refs:
        counts[r["how"]] = counts.get(r["how"], 0) + 1
    print(f"{args.blob}: {len(blob)} bytes @0x{args.base:06X}, "
          f"{len(refs)} candidate refs {counts}", file=sys.stderr)
    if args.json:
        args.json.write_text(json.dumps(refs, indent=1))
    else:
        for r in refs:
            print(f"  +0x{r['off']:04X} {r['how']:10s} -> 0x{r['target']:06X} "
                  f"({r['class']})")


if __name__ == "__main__":
    main()
