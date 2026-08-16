#!/usr/bin/env python3
"""audit_walker_callers.py — every reference that can reach an object-pool
walker, enumerated BY FORM.

WHY (14z-91). The obj_hook legacy-cycle fix relocates each walker into free
space and rewrites the OPERAND of every `jsr <walker>`. Completeness is the
whole correctness argument: a caller we miss keeps walking the VANILLA table,
which is bit-identical for legacy (it *is* vanilla) but over-indexes for a
tenant type. So the inventory has to be enumerated rather than assumed, and
it has to say which reference FORMS it covered.

FORMS COVERED (all of them scanned over the whole 4 MB opcode image):
  abs.l operand   4EB9/4EF9 <addr32>            jsr/jmp absolute long
  data longword   <addr32> at any 2-byte offset  pointer tables, movea.l #imm
  pc-relative     4EBA/4EFA <d16>               jsr/jmp (d16,PC)
  branches        6xxx (Bcc/bsr/bra), .s and .w  target computed and matched

NOT COVERED, and stated rather than hidden: a target computed at RUNTIME
(base register plus a variable) is invisible to any static scan. That is the
residual this tool cannot close; the dynamic complement is
tests/audit_walker_repoint.sh, which requires ZERO hits on the vanilla
walker entries across the corpus once the repoint ships.

DECODE NOISE IS REAL. A linear 2-byte scan reads operand words as opcodes,
so branch hits are reported with their context bytes and a plausibility note
rather than asserted — the surrounding run at 0x5442E-0x54457, for instance,
is a block of `jmp`/`jsr abs.l` stubs whose operand words decode as branches.
Judge each by its context, and prefer the abs.l/data columns, which do not
suffer from this.

Usage:
    tools/audit_walker_callers.py build/out/vsavj_opcodes.bin \
        [--walker 0x54458:0x2c] [--walker 0x5e52a:0x2c] [--toml]
"""
import argparse
import hashlib
import sys

DEFAULT_WALKERS = ("0x54458:0x2c", "0x5e52a:0x2c")


def u16(b, o):
    return int.from_bytes(b[o:o + 2], "big")


def u32(b, o):
    return int.from_bytes(b[o:o + 4], "big")


def ctx(img, at, before=6, after=10):
    lo = max(0, at - before)
    return img[lo:at].hex() + "|" + img[at:at + after].hex()


def scan(img, base, length):
    """Return dict of form -> list of (addr, note)."""
    end = base + length
    hits = {"abs_call": [], "abs_data": [], "pcrel": [], "branch": []}
    for o in range(0, len(img) - 4, 2):
        v = u32(img, o)
        if base <= v < end:
            op = u16(img, o - 2) if o >= 2 else 0
            if op in (0x4EB9, 0x4EF9):
                kind = "jsr" if op == 0x4EB9 else "jmp"
                hits["abs_call"].append(
                    (o - 2, f"{kind}.l -> {v:#08x}"
                            f"{'' if v == base else f' (MID-BODY +{v - base:#x})'}"
                            f"  [{ctx(img, o - 2)}]"))
            else:
                hits["abs_data"].append(
                    (o, f"longword {v:#08x}"
                        f"{'' if v == base else f' (MID-BODY +{v - base:#x})'}"
                        f"  [{ctx(img, o)}]"))
    for o in range(0, len(img) - 4, 2):
        op = u16(img, o)
        if op in (0x4EBA, 0x4EFA):
            d = u16(img, o + 2)
            if d & 0x8000:
                d -= 0x10000
            tgt = o + 2 + d
            if base <= tgt < end:
                kind = "jsr" if op == 0x4EBA else "jmp"
                hits["pcrel"].append((o, f"{kind} ({d:#x},PC) -> {tgt:#08x}  [{ctx(img, o)}]"))
        if (op & 0xF000) == 0x6000:
            disp = op & 0xFF
            if disp == 0x00:
                d = u16(img, o + 2)
                if d & 0x8000:
                    d -= 0x10000
                tgt, sz = o + 2 + d, "w"
            elif disp == 0xFF:
                continue                      # .l form, 68020+; not on this CPU
            else:
                d = disp - 0x100 if disp & 0x80 else disp
                tgt, sz = o + 2 + d, "s"
            if base <= tgt < end:
                cc = (op >> 8) & 0xF
                nm = {0x0: "bra", 0x1: "bsr"}.get(cc, f"bcc{cc:x}")
                hits["branch"].append(
                    (o, f"{nm}.{sz} -> {tgt:#08x} (+{tgt - base:#x})  [{ctx(img, o)}]"))
    return hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--walker", action="append", default=None,
                    help="addr:len (hex), repeatable")
    ap.add_argument("--toml", action="store_true")
    a = ap.parse_args()
    img = open(a.image, "rb").read()
    print(f"image {a.image}")
    print(f"  sha1 {hashlib.sha1(img).hexdigest()}  len {len(img):#x}")
    rows = []
    for spec in (a.walker or list(DEFAULT_WALKERS)):
        s, l = spec.split(":")
        base, length = int(s, 16), int(l, 16)
        print(f"\n=== walker {base:#08x} len {length:#x} "
              f"(table at {base + length:#08x})")
        print(f"    body {img[base:base + length].hex()}")
        h = scan(img, base, length)
        callers = []
        for form in ("abs_call", "pcrel", "branch", "abs_data"):
            print(f"  -- {form}: {len(h[form])}")
            for at, note in h[form]:
                print(f"     {at:#08x}  {note}")
                if form == "abs_call" and note.startswith("jsr.l") and "MID-BODY" not in note:
                    callers.append(at)
        rows.append((base, length, sorted(callers)))
        print(f"  => CALLERS (jsr.l to the entry point): {len(callers)}"
              f" {[hex(c) for c in callers]}")
    if a.toml:
        print("\n# --- frozen inventory ---")
        for base, length, callers in rows:
            print(f"\n[[obj_walker]]")
            print(f"walker = 0x{base:05x}")
            print(f"walker_len = 0x{length:x}")
            print(f'walker_old_hex = "{img[base:base + length].hex()}"')
            print(f"callers = [{', '.join(f'0x{c:06x}' for c in callers)}]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
