#!/usr/bin/env python3
"""check_wheel_bank5.py — independent re-derivation of the select-wheel
bank-5 move (14z-63, phase 3 item 1).

The move: the whole wheel record serves from WIDE group C bank 5. The
drawer object ($FFB800) is ONE object with ONE bank word, so the vanilla
entries' tiles are copied BYTE-IDENTICAL from vsav group A into group C
at the same in-group index (0x10000+code) — vanilla-cell pixels identical
by construction — and the appended cells' native vs2 codes carry the real
vs2 medallion art. The program side flips one immediate: the select-init
`move.w #$2000,$18(a6)` at PRG:0x5F8B2 becomes #$3000 (bank 5,
gfx_tiles.bank_word encoding — never bank<<13).

Checks (all re-derived from the ROMs + manifest layout, never from the
build's own intermediates):
  1. the vanilla opcode image holds the expected init instruction at the
     site, and the build's patch.json carries EXACTLY the expected code op;
  2. wheel_bank5.json equals an independent tile enumeration: every tile
     of every entry of the vanilla record @0x272A68 (host) + every tile
     of the layout's appended cells (vs2), disjoint;
  3. the BUILT vsavjw.zip group C members hold, at 0x10000+code: host
     tiles byte-identical to vsav group A, vs2 tiles byte-identical to
     vsav2 group A — decoded straight from the zips (the member-identity
     honest instrument; an emulator over a chained rompath is not one);
  4. instrument ground truth: at least one compared host tile and one vs2
     tile must be NON-BLANK, or the byte-compare proves nothing.

Prints `SITE`, `TILES host <n> vs2 <n>` and `OK` on success; exits 1 with
a FAIL line otherwise.

Usage:
  check_wheel_bank5.py <outbase> <vsavj_opcodes.bin> <vsavj_data.bin> \
      <romdir> <layout.json> [--site 0x5F8B2] [--record 0x272A68]
"""

import argparse
import json
import struct
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from gfx_tiles import GROUP_A, GROUP_C, tile_bytes, BLANK  # noqa: E402
import hashlib  # noqa: E402

SITE_OLD = bytes.fromhex("3d7c20000018")   # move.w #$2000,$18(a6)
SITE_NEW = bytes.fromhex("3d7c30000018")   # move.w #$3000,$18(a6) (bank 5)


def die(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


def load_group_quiet(z, prefix, group):
    return [z.read(f"{prefix}.{n}m") for n in group]


def block_tiles(t, at, into):
    bx = ((at >> 8) & 15) + 1
    by = ((at >> 12) & 15) + 1
    for dy in range(by):
        for dx in range(bx):
            into.add((t & ~0xF) + (dy << 4) + ((t + dx) & 0xF))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("outbase")
    ap.add_argument("opcodes")
    ap.add_argument("data")
    ap.add_argument("romdir")
    ap.add_argument("layout")
    ap.add_argument("--site", default="0x5F8B2")
    ap.add_argument("--record", default="0x272A68")
    args = ap.parse_args()
    out = Path(args.outbase)
    site = int(args.site, 16)
    rec = int(args.record, 16)

    opc = Path(args.opcodes).read_bytes()
    vj = Path(args.data).read_bytes()

    # 1. the site + the op
    if opc[site:site + 6] != SITE_OLD:
        die(f"vanilla opcode image at {site:#x} holds "
            f"{opc[site:site+6].hex()}, expected {SITE_OLD.hex()}")
    patch = json.loads((out / "patch" / "patch.json").read_text())
    ops = patch["ops"] if isinstance(patch, dict) and "ops" in patch else patch
    hits = [o for o in ops
            if o.get("op") == "code" and int(o.get("addr"), 16) == site]
    if len(hits) != 1 or hits[0].get("hex") != SITE_NEW.hex():
        die(f"patch.json code op at {site:#x}: got {hits}, expected one op "
            f"with hex {SITE_NEW.hex()}")
    print(f"SITE {site:#x} {SITE_OLD.hex()} -> {SITE_NEW.hex()}")

    # 1b. the highlight base rows (14z-63 item 2): the 32-row pc-relative
    # base table must be ALIASED in vanilla (variant half == base half),
    # and the build must carry one code op per layout cell writing that
    # cell's highlight_base pair into its row; row 0x12 (reserved) must
    # NOT be written.
    HB_SITE = 0x5FAE2
    if opc[HB_SITE:HB_SITE + 0x40] != opc[HB_SITE + 0x40:HB_SITE + 0x80]:
        die(f"vanilla highlight base table at {HB_SITE:#x} is not aliased "
            f"— wrong site or moved table")
    lay_hb = json.loads(Path(args.layout).read_text())
    for k, spec in lay_hb["cells"].items():
        c = int(str(k), 16)
        hb = spec.get("highlight_base")
        if hb is None:
            die(f"layout cell {c:#04x} has no highlight_base")
        row = HB_SITE + 4 * c
        want = struct.pack(">HH", int(hb[0]), int(hb[1])).hex()
        got = [o for o in ops if o.get("op") == "code"
               and int(o.get("addr"), 16) == row]
        if len(got) != 1 or got[0].get("hex") != want:
            die(f"highlight base row {c:#04x} at {row:#x}: got {got}, "
                f"expected one code op with hex {want}")
    if any(o.get("op") == "code" and int(o.get("addr"), 16) == HB_SITE + 4 * 0x12
           for o in ops):
        die("highlight base row 0x12 (RESERVED) is written")
    print(f"HBROWS {len(lay_hb['cells'])}")

    # 2. the inventory, re-derived
    fmt, budget, cm1 = struct.unpack(">HHH", vj[rec:rec + 6])
    if fmt != 2:
        die(f"record {rec:#x} fmt {fmt} != 2 — wrong record")
    host = set()
    for k in range(cm1 + 1):
        t, at = struct.unpack(">HH", vj[rec + 10 + 4 * k:rec + 14 + 4 * k])
        block_tiles(t, at, host)
    lay = json.loads(Path(args.layout).read_text())
    vs2 = set()
    for spec in lay["cells"].values():
        block_tiles(int(str(spec["tile"]), 16), int(str(spec["attr"]), 16),
                    vs2)
    if host & vs2:
        die(f"host/vs2 enumerations overlap: {sorted(host & vs2)}")
    built = json.loads((out / "patch" / "wheel_bank5.json").read_text())
    if set(built["host"]) != host or set(built["vs2"]) != vs2:
        die(f"wheel_bank5.json disagrees with the re-derivation: "
            f"host {len(built['host'])}/{len(host)}, "
            f"vs2 {len(built['vs2'])}/{len(vs2)}")
    print(f"TILES host {len(host)} vs2 {len(vs2)}")

    # 2b. the medallion palettes (14z-63 maintainer round): each appended
    # cell's record entry must be re-palmed to its declared free row, and
    # the build must write the vs2 palette row bytes into select block A
    # at that row. Sources re-read from the vs2 image, never from the
    # build's own intermediates.
    PAL_A = 0x3A3800
    # locate the built record: the repoint op names it
    rp = [o for o in ops if o.get("op") == "poke32"
          and int(o.get("addr"), 16) == 0x2689FE]
    if len(rp) != 1:
        die(f"wheel repoint op: {rp}")
    rec_dst = int(str(rp[0]["val"]), 16)
    body = [o for o in ops if o.get("op") == "data"
            and int(o.get("addr"), 16) == rec_dst]
    if len(body) != 1:
        die(f"wheel record data op at {rec_dst:#x}: {len(body)} found")
    bb = bytes.fromhex(body[0]["hex"])
    nvan = cm1 + 1
    if not Path("build/out/vsav2_data.bin").exists():
        die("build/out/vsav2_data.bin missing (run the build first)")
    vs2_data = Path("build/out/vsav2_data.bin").read_bytes()
    cells = sorted((int(str(k), 16), v) for k, v in lay["cells"].items())
    for i, (c, spec) in enumerate(cells):
        at = int.from_bytes(bb[10 + 4 * (nvan + i) + 2:
                               10 + 4 * (nvan + i) + 4], "big")
        pr = int(str(spec["pal_row"]))
        ps = int(str(spec["pal_src"]))
        if (at & 0x1F) != pr:
            die(f"cell {c:#04x}: record entry pal {at & 0x1F:#04x} != "
                f"declared pal_row {pr:#04x}")
        want = vs2_data[ps:ps + 0x20].hex()
        hit = [o for o in ops if o.get("op") == "data"
               and int(o.get("addr"), 16) == PAL_A + pr * 0x20]
        if len(hit) != 1 or hit[0]["hex"] != want:
            die(f"cell {c:#04x}: block A row {pr:#04x} palette op wrong "
                f"or missing")
    print(f"PALROWS {len(cells)}")

    # 3. the built group C members vs the sources, straight from the zips
    zw = zipfile.ZipFile(out / "rompath" / "vsavjw.zip")
    gc = load_group_quiet(zw, "vsw", GROUP_C)
    za = zipfile.ZipFile(Path(args.romdir) / "vsav.zip")
    ga = load_group_quiet(za, "vm3", GROUP_A)
    z2 = zipfile.ZipFile(Path(args.romdir) / "vsav2.zip")
    g2 = load_group_quiet(z2, "vs2", GROUP_A)
    nonblank_host = nonblank_vs2 = 0
    for c in sorted(host):
        got = tile_bytes(gc, 0x10000 + c)
        want = tile_bytes(ga, 0x10000 + c)
        if got != want:
            die(f"host tile 0x{c:04X}: group C bytes differ from vsav "
                f"group A")
        if hashlib.sha1(want).digest() not in BLANK:
            nonblank_host += 1
    for c in sorted(vs2):
        got = tile_bytes(gc, 0x10000 + c)
        want = tile_bytes(g2, 0x10000 + c)
        if got != want:
            die(f"vs2 tile 0x{c:04X}: group C bytes differ from vsav2 "
                f"group A")
        if hashlib.sha1(want).digest() not in BLANK:
            nonblank_vs2 += 1

    # 4. the instrument is grounded
    if not nonblank_host or not nonblank_vs2:
        die(f"blank-source degeneracy: {nonblank_host} non-blank host / "
            f"{nonblank_vs2} non-blank vs2 tiles — the compare proves "
            f"nothing")
    print(f"NONBLANK host {nonblank_host} vs2 {nonblank_vs2}")
    print("OK")


if __name__ == "__main__":
    main()
