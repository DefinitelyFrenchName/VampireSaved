#!/usr/bin/env python3
"""audit_quote_font_window.py — the win-quote glyph font as the EMITTER draws it,
and what the three tenant quote blocks would cost against it (14z-189, GitHub #123).

WHY THIS EXISTS. `tools/audit_quote_font.py` (14z-116) compared each code at
tile `0x3800 + code` — gfx bank 0 — in both games. Measured 14z-189, that is
not where either game draws a quote glyph: the system-text emitter (vsavj
`PRG:0x01BA6A`, format 0 at `0x01BA8E`, format 1 at `0x01BACC`) writes the
OBJ y word with an IMMEDIATE `ori.w #$2000,d1` (bank 1) and the code word with
an IMMEDIATE `addi.w #<base>,d2` — vsavj `0x3800`, vs2 and vh2 `0x4200`. So a
quote code C draws tile `0x10000 + base + (C & 0xFFF)` in group A, and the two
games' fonts are the SAME font at bases 0x600 tiles apart. (On screen: replay
61 on merged-m22, the quote's OBJ entries carry y = 0x20b0 and tile address
0x13ee5 etc., written by PC 0x01BABE; the bank-0 window holds character art.)

WHAT IT REPORTS, each figure derived from the images it is given:
  1. EMITTER   per game, every format-0/1 tail `or.w $1a(a6),d0 / move.w
               (a0)+,d2 / addi.w #imm,d2` and the `ori.w #bank,d1` before it;
               the font base and bank are READ from the opcode view, never
               assumed (`--vs2-op` drives the census below).
  2. WINDOW    blank tiles in vsavj's real window (bank 1, 4096 tiles).
  3. CENSUS    every code the three vs2 tenant blocks use (decode via
               audit_quote_font.tenant_codes, vs2 data view): the vs2 glyph at
               vs2's own base, looked up in vsavj's window — SAME (same code
               draws the same glyph), ELSEWHERE (present at another code — a
               remap), ABSENT (a tile must travel), VS2-BLANK (pad/blank).
  4. BANK5     with --build: group C bank 5's copy of the window (the 14z-116
               "clean route" space) blank count on the BUILT vsavjw.zip.

Usage:
  audit_quote_font_window.py <vsavj_op> <vsavj_data> <vs2_op> <vs2_data> <romdir>
      [--build build/m3b_merged31]
Prints the SHA-1 of every image read. Exit 0 always — the gate judges.
"""
import argparse
import hashlib
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gfx_tiles  # noqa: E402
from audit_quote_font import tenant_codes  # noqa: E402

TAIL = bytes.fromhex("806e001a34180642")   # or.w $1a(a6),d0 / move.w (a0)+,d2 / addi.w #


def sha(b):
    return hashlib.sha1(b).hexdigest()


def emitter(op):
    """[(site, base, bank)] for every format tail in the opcode view."""
    out = []
    a = op.find(TAIL)
    while a >= 0:
        base = int.from_bytes(op[a + 8:a + 10], "big")
        o = op.rfind(bytes.fromhex("0041"), a - 24, a)      # ori.w #imm,d1
        bank = int.from_bytes(op[o + 2:o + 4], "big") if o >= 0 else -1
        out.append((a, base, bank))
        a = op.find(TAIL, a + 1)
    return out


def group_a(zp, prefix):
    z = zipfile.ZipFile(zp)
    print(f"# {zp} sha1 {sha(open(zp, 'rb').read())}")
    return [z.read(f"{prefix}.{n}m") for n in gfx_tiles.GROUP_A]


def blank(t):
    return hashlib.sha1(t).digest() in gfx_tiles.BLANK


def main():
    ap = argparse.ArgumentParser()
    for k in ("vj_op", "vj_data", "v2_op", "v2_data", "romdir"):
        ap.add_argument(k)
    ap.add_argument("--build")
    a = ap.parse_args()
    imgs = {k: Path(getattr(a, k)).read_bytes() for k in ("vj_op", "vj_data", "v2_op", "v2_data")}
    for k, v in imgs.items():
        print(f"# {k} {getattr(a, k)} sha1 {sha(v)}")

    em = {}
    for g, k in (("vsavj", "vj_op"), ("vsav2", "v2_op")):
        em[g] = emitter(imgs[k])
        for site, base, bank in em[g]:
            print(f"EMITTER {g} site {site:#08x} base {base:#06x} bank {bank:#06x}")
    bases = {g: {b for _, b, _ in em[g]} for g in em}
    if any(len(v) != 1 for v in bases.values()):
        print(f"EMITTER-AMBIGUOUS {bases}")
        return
    vj_base = 0x10000 + bases["vsavj"].pop()
    v2_base = 0x10000 + bases["vsav2"].pop()

    gj = group_a(f"{a.romdir}/vsav.zip", "vm3")
    g2 = group_a(f"{a.romdir}/vsav2.zip", "vs2")
    nb = sum(1 for t in range(vj_base, vj_base + 0x1000) if blank(gfx_tiles.tile_bytes(gj, t)))
    print(f"WINDOW vsavj tiles {vj_base:#07x}-{vj_base + 0xFFF:#07x} blank {nb}/4096")

    codes = tenant_codes(imgs["v2_data"], [0x10, 0x11, 0x13])
    allc = sorted(set().union(*[set(c) for c in codes.values()]))
    win = {}
    for t in range(vj_base, vj_base + 0x1000):
        win.setdefault(gfx_tiles.tile_bytes(gj, t), t)
    verdict = {}
    for c in allc:
        t2 = gfx_tiles.tile_bytes(g2, v2_base + (c & 0xFFF))
        hit = win.get(t2)
        verdict[c] = ("VS2-BLANK" if blank(t2) else "SAME" if hit == vj_base + (c & 0xFFF)
                      else "ELSEWHERE" if hit is not None else "ABSENT")
    tally = {k: sum(1 for v in verdict.values() if v == k) for k in ("SAME", "ELSEWHERE", "ABSENT", "VS2-BLANK")}
    print(f"CENSUS codes {len(allc)} " + " ".join(f"{k} {v}" for k, v in tally.items()))
    for t, cs in codes.items():
        ab = [c for c in cs if verdict[c] == "ABSENT"]
        print(f"CENSUS tenant {t:#04x} codes {len(cs)} absent {len(ab)} absent-uses {sum(cs[c] for c in ab)}")
    ab = [c for c in allc if verdict[c] == "ABSENT"]
    print("ABSENT " + (f"{min(ab):#05x}-{max(ab):#05x} n={len(ab)}" if ab else "none"))
    vacant = sum(1 for c in ab if blank(gfx_tiles.tile_bytes(gj, vj_base + (c & 0xFFF))))
    print(f"ABSENT-AT-BLANK-SLOT {vacant}/{len(ab)} (vsavj's tile at the same code is blank)")

    if a.build:
        zp = Path(a.build) / "rompath" / "vsavjw.zip"
        z = zipfile.ZipFile(zp)
        print(f"# {zp} sha1 {sha(zp.read_bytes())}")
        gc = [z.read(f"vsw.{n}m") for n in gfx_tiles.GROUP_C]
        lo = vj_base   # bank 5 = group C's second 64K block: same in-group offset as bank 1 in group A
        n5 = sum(1 for t in range(lo, lo + 0x1000) if blank(gfx_tiles.tile_bytes(gc, t)))
        print(f"BANK5 group C {lo:#07x}-{lo + 0xFFF:#07x} blank {n5}/4096")


if __name__ == "__main__":
    main()
