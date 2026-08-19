#!/usr/bin/env python3
"""gfx_tiles.py — canonical CPS-2 gfx tile extraction, matching, rendering.

The gfx simms (x.13m-x.20m, 8 x 4MB = 32MB = 0x40000 16x16 4bpp tiles)
do NOT store tiles as contiguous byte runs. Per the hardware interleave
(FBNeo Cps2LoadOne/Cps2Load100000, emu/fbneo/src/burn/drv/capcom/cps.cpp):

- Group A simms (13,15,17,19) hold tiles 0x00000-0x1FFFF; group B
  (14,16,18,20) hold 0x20000-0x3FFFF.
- 13m/15m are the LEFT 8x16 half of each tile (planes 0-1 / 2-3);
  17m/19m the RIGHT half. (Group B likewise.)
- Within a simm, each 0x80000-byte block splits into even/odd 2-byte
  word streams feeding two different 1MB decoded chunks: tile t2's 32
  bytes in a simm are 16 PAIRS at stride 4:
      block b = (128*t2) // 0x200000
      chunk   = ((128*t2) % 0x200000) // 0x100000
      base    = b*0x80000 + 64*((128*t2 % 0x100000)//128) + 2*chunk
      pairs at base + 4*row, row = 0..15
- Naive contiguous 32-byte slicing mixes bytes of tiles 1MB apart; it
  happens to compare equal for SAME-INDEX tiles across sets (same
  neighbors) but breaks all content-addressed cross-set matching. See
  docs/GOTCHAS.md.

Canonical tile form used here: 128 bytes = the four simms' 32-byte
contributions concatenated in load order (L01, L23, R01, R23).

Usage:
  gfx_tiles.py match <romdirA.zip:prefix> <romdirB.zip:prefix>
      content-addressed matching report (B's tiles looked up in A)
  gfx_tiles.py sheet <rom.zip:prefix> <start_hex> <out.bmp> [grid]
      render a grid x grid tile sheet (grayscale) for visual inspection
  gfx_tiles.py dump <rom.zip:prefix> <out.json>
      write {tile_index: sha1} for external joins

Every mode prints the SHA-1 of each simm it reads (repo convention).
"""

import hashlib
import json
import struct
import sys
import zipfile

GROUP_A = (13, 15, 17, 19)
GROUP_B = (14, 16, 18, 20)
# CPS-2 WIDE v1 group C (vsw simms, appended by the profile): tiles
# 0x40000-0x5FFFF, banks 4-5. Same interleave, same member size (4MB).
GROUP_C = (31, 33, 35, 37)
TILES_PER_GROUP = 0x20000


# ── THE OBJ BLOCK-CELL GEOMETRY (GitHub #47) ────────────────────────────
# One hardware fact, stated once: an OBJ block's tile codes advance with a
# 16-TILE ROW STRIDE and WITHIN-ROW WRAP — row dy lives at (head & ~0xF) +
# (dy << 4), and the column steps (head + dx) & 0xF, wrapping inside the
# 16-tile row rather than carrying into it. Before this helper the formula
# was restated 25 times across 7 files (verified byte-identical, zero
# drift — the extraction is mechanical and any behavioural change means
# the conversion is wrong). The attr decode below is its companion: the
# OBJ attribute word carries the block size as two 4-bit fields, stored
# MINUS ONE.

def cell_at(head, dx, dy):
    """Tile code of cell (dx, dy) of an OBJ block anchored at `head`."""
    return (head & ~0xF) + (dy << 4) + ((head + dx) & 0xF)


def block_cells(head, bx, by):
    """Every cell of a bx x by block, row-major (dy outer, dx inner)."""
    for dy in range(by):
        for dx in range(bx):
            yield cell_at(head, dx, dy)


def attr_block(attr):
    """OBJ attr word -> (bx, by), each 1..16 (stored as size-1 nibbles)."""
    return ((attr >> 8) & 15) + 1, ((attr >> 12) & 15) + 1


def bank_word(bank):
    """The OBJ y-word bank bits for a gfx bank — NOT `bank << 13`.

    Stock banks ride y bits 13-14. The WIDE profile's 19th tile-address
    bit is y BIT 12, promoted after the terminator check (the CPS-2 Turbo
    rule, docs/project/cps2_wide.md): bit 15 is the sprite-list TERMINATOR, so
    bank 4 = 0x1000 and bank 5 = 0x3000. `4 << 13` would be 0x8000 — a
    terminator, ending the sprite list at the first tenant sprite.
    """
    return {0: 0x0000, 1: 0x2000, 2: 0x4000, 3: 0x6000,
            4: 0x1000, 5: 0x3000}[bank]
BLANK = {hashlib.sha1(b"\x00" * 128).digest(),
         hashlib.sha1(b"\xff" * 128).digest()}
SEP = [sum(((b >> i) & 1) << (4 * i) for i in range(8)) for b in range(256)]


def load_simms(spec):
    """spec = path.zip:prefix -> (groupA simms, groupB simms)"""
    path, prefix = spec.rsplit(":", 1)
    z = zipfile.ZipFile(path)
    out = []
    for group in (GROUP_A, GROUP_B):
        simms = []
        for n in group:
            data = z.read(f"{prefix}.{n}m")
            print(f"  read {prefix}.{n}m sha1 {hashlib.sha1(data).hexdigest()}",
                  file=sys.stderr)
            simms.append(data)
        out.append(simms)
    return out


def tile_bytes(simms, t2):
    b, rem = divmod(128 * t2, 0x200000)
    chunk, o = divmod(rem, 0x100000)
    t2p = o // 128
    parts = []
    for s in simms:
        base = b * 0x80000 + 64 * t2p + 2 * chunk
        parts.append(b"".join(s[base + 4 * r: base + 4 * r + 2]
                              for r in range(16)))
    return b"".join(parts)


def all_tiles(groups):
    ga, gb = groups
    n = len(ga[0]) // 32
    return ([tile_bytes(ga, i) for i in range(n)]
            + [tile_bytes(gb, i) for i in range(n)])


def write_tile(simms, t2, tile):
    """Inverse of tile_bytes: scatter a canonical 128B tile back into four
    mutable simm buffers (bytearrays) at within-group index t2."""
    b, rem = divmod(128 * t2, 0x200000)
    chunk, o = divmod(rem, 0x100000)
    t2p = o // 128
    for si, s in enumerate(simms):
        part = tile[si * 32:(si + 1) * 32]
        base = b * 0x80000 + 64 * t2p + 2 * chunk
        for r in range(16):
            s[base + 4 * r: base + 4 * r + 2] = part[2 * r: 2 * r + 2]


def decode(tile):
    """Canonical 128B -> 256 pixel values 0-15 (row-major 16x16)."""
    px = bytearray(256)
    L01, L23, R01, R23 = (tile[0:32], tile[32:64], tile[64:96], tile[96:128])
    for r in range(16):
        lw = (SEP[L01[2*r]] | SEP[L01[2*r+1]] << 1
              | SEP[L23[2*r]] << 2 | SEP[L23[2*r+1]] << 3)
        rw = (SEP[R01[2*r]] | SEP[R01[2*r+1]] << 1
              | SEP[R23[2*r]] << 2 | SEP[R23[2*r+1]] << 3)
        for x in range(8):
            px[r * 16 + x] = (lw >> (4 * x)) & 0xF
            px[r * 16 + 8 + x] = (rw >> (4 * x)) & 0xF
    return px


def cmd_match(spec_a, spec_b):
    va = all_tiles(load_simms(spec_a))
    vb = all_tiles(load_simms(spec_b))
    idx = {}
    for i, t in enumerate(va):
        idx.setdefault(hashlib.sha1(t).digest(), i)
    found = missing = blank = same = 0
    missing_runs, run_start = [], None
    for i, t in enumerate(vb):
        h = hashlib.sha1(t).digest()
        if h in BLANK:
            blank += 1
            hit = True
        else:
            hit = h in idx
            if hit:
                found += 1
                if idx[h] == i:
                    same += 1
            else:
                missing += 1
        if not hit and run_start is None:
            run_start = i
        if hit and run_start is not None:
            missing_runs.append((run_start, i))
            run_start = None
    if run_start is not None:
        missing_runs.append((run_start, len(vb)))
    print(f"B tiles: found-in-A {found} (same index {same}), "
          f"MISSING {missing}, blank {blank}")
    big = [(s, e) for s, e in missing_runs if e - s >= 256]
    print(f"missing runs >=256 tiles: {len(big)}")
    for s, e in big:
        print(f"  0x{s:05X}-0x{e:05X} ({e - s} tiles, {(e-s)*128//1024} KB)")


def cmd_sheet(spec, start, out, grid=32):
    tiles = all_tiles(load_simms(spec))
    W = H = grid * 16
    img = bytearray(W * H)
    for gy in range(grid):
        for gx in range(grid):
            px = decode(tiles[start + gy * grid + gx])
            for r in range(16):
                row = bytes(v * 17 for v in px[r * 16: r * 16 + 16])
                img[(gy*16+r)*W + gx*16: (gy*16+r)*W + gx*16 + 16] = row
    with open(out, "wb") as f:
        rowsz = (W + 3) // 4 * 4
        f.write(b"BM" + struct.pack("<IHHI", 54 + 1024 + rowsz*H, 0, 0,
                                    54 + 1024))
        f.write(struct.pack("<IiiHHIIiiII", 40, W, -H, 1, 8, 0, rowsz*H,
                            2835, 2835, 256, 0))
        for i in range(256):
            f.write(bytes((i, i, i, 0)))
        for y in range(H):
            f.write(img[y*W:(y+1)*W])
            f.write(b"\x00" * (rowsz - W))
    print(f"wrote {out} (tiles 0x{start:05X}-0x{start+grid*grid:05X})")


def cmd_dump(spec, out):
    tiles = all_tiles(load_simms(spec))
    d = {i: hashlib.sha1(t).hexdigest() for i, t in enumerate(tiles)}
    json.dump(d, open(out, "w"))
    print(f"wrote {out} ({len(d)} tiles)")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == "match":
        cmd_match(sys.argv[2], sys.argv[3])
    elif cmd == "sheet":
        cmd_sheet(sys.argv[2], int(sys.argv[3], 16), sys.argv[4],
                  int(sys.argv[5]) if len(sys.argv) > 5 else 32)
    elif cmd == "dump":
        cmd_dump(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
