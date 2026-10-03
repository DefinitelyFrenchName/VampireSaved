#!/usr/bin/env python3
"""audit_roulette_tag_rows.py — the arcade-ladder map's opponent TAG (name + mini-art) per
character id, in each game (14z-189, GitHub #124).

THE MECHANISM, measured 14z-189 on merged-m22 (replay 111 + the pokes of
tests/test_ladder_tenant_vs_palette.sh, CPU Phobos vs CPU Bishamon): the map
screen spawns, for the current rung, a type-7 sub-0x08 child (vsavj init
`PRG:0x05FBE6`) whose +0x0A is the opponent's character id. Its init reads an
x-offset pair from two word tables (`lea $603de(pc)` / `lea $6041e(pc)`, data
view, id*2) and points +0x1C at `0x26752A + id*4 - 4`; the effect-pool builder
then does `movea.l $1c(a6),a0 / movea.l 4(a0),a0` (`PRG:0x01AFA6`), i.e. it
draws ROW id of the long array at 0x26752A. In vsavj that array's rows
0x10-0x13 — the rows this tool checks — are COPIES of rows 0x00-0x03 (Capcom's
aliasing guard, the [VSE-75] shape; the rest of the half, 0x14-0x1F, is not checked here), so a tenant id 0x10 draws row 0x00 — BULLETA. No code folds the id:
the "4-bit fold" is in the data. vs2 carries its own rows at 0x10/0x11/0x13.

WHAT IT REPORTS per game (the array, the two width tables and the 0x90C140
palette pool are LOCATED in each image by instruction pattern, never assumed):
  ARRAY   site, base, and for rows 0x10/0x11/0x12/0x13 the record pointer and
          whether it equals row id-0x10 (ALIAS) or not (OWN)
  WIDTH   the two words per row 0x10-0x13, ALIAS/OWN the same way
  POOL    the 32-byte palette row per id 0x10-0x13, ALIAS/OWN

Usage: audit_roulette_tag_rows.py <game> <opcodes.bin> <data.bin>
Prints the SHA-1 of both images. Exit 0 always — the gate judges.
"""
import hashlib
import sys

TAG = bytes.fromhex("3d7ca000001a3d7c20000018")   # move.w #$a000,$1a(a6) / move.w #$2000,$18(a6)


def main():
    game, opp, dap = sys.argv[1:4]
    op, da = open(opp, "rb").read(), open(dap, "rb").read()
    print(f"# {game} op {hashlib.sha1(op).hexdigest()} data {hashlib.sha1(da).hexdigest()}")
    site = op.find(TAG)                       # the FIRST tag child is sub 0x08 (the mini-art + name)
    m = op.find(bytes.fromhex("207c"), site, site + 40)
    arr = int.from_bytes(op[m + 2:m + 6], "big")
    longs = lambda b, r: int.from_bytes(da[b + 4 * r:b + 4 * r + 4], "big")
    words = lambda b, r: int.from_bytes(da[b + 2 * r:b + 2 * r + 2], "big")
    tag = lambda a, b: "ALIAS" if a == b else "OWN"
    print(f"ARRAY {game} site {site:#08x} base {arr:#08x} " +
          " ".join(f"{r:02x}:{longs(arr, r):06x}:{tag(longs(arr, r), longs(arr, r - 0x10))}" for r in (0x10, 0x11, 0x12, 0x13)))
    for back in (0x2E, 0x24):                  # the two `lea (pc)` width tables before the tag site
        pc = site - back
        assert op[pc:pc + 2] == bytes.fromhex("41fa"), (game, hex(pc))
        tb = pc + 2 + int.from_bytes(op[pc + 2:pc + 4], "big", signed=True)
        print(f"WIDTH {game} table {tb:#08x} " +
              " ".join(f"{r:02x}:{words(tb, r):04x}:{tag(words(tb, r), words(tb, r - 0x10))}" for r in (0x10, 0x11, 0x12, 0x13)))
    a = op.find(bytes.fromhex("eb48207c"))
    while a >= 0 and op[a + 8:a + 18] != bytes.fromhex("41f0000043f90090c140"):
        a = op.find(bytes.fromhex("eb48207c"), a + 1)
    pool = int.from_bytes(op[a + 4:a + 8], "big")
    row = lambda r: da[pool + 32 * r:pool + 32 * r + 32]
    print(f"POOL {game} site {a:#08x} base {pool:#08x} " +
          " ".join(f"{r:02x}:{hashlib.sha1(row(r)).hexdigest()[:6]}:{tag(row(r), row(r - 0x10))}" for r in (0x10, 0x11, 0x12, 0x13)))


if __name__ == "__main__":
    main()
