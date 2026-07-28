#!/usr/bin/env python3
"""build_gfx_donovan.py — place Donovan's sprite tiles into vsav's gfx
members at Jedah's band positions (M2b tile-data step).

Reads Donovan's art from vsav2's gfx (bank 3) and writes it into copies
of vsav's group-B simms (vm3.14m/16m/18m/20m — bank 2 lives in group B)
at the Jedah-band placement decided by the session-14 measurements:

  source band  : vs2 bank 3, codes SRC_LO..SRC_HI (0x863F..0xC2EF used)
  placement    : vsav bank 2, delta +0x2750 (16-aligned, preserves
                 sprite-block row-wrap), i.e. codes 0xAD8F..0xEA3F —
                 above the 44-tile Sasquatch-shared band head
                 (0xAD3E-0xAD74), inside Jedah's band (max 0xEEBB).

Only tiles Donovan's OBJ records actually reference (the inventory JSON
from tools/obj_records.py) are copied; every other byte of every member
is untouched (verified). The PRG-side record remap (same delta) is a
separate patcher step — this tool only produces gfx members + the remap
spec consumed by that step.

Usage:
  build_gfx_donovan.py <ROMDIR> <outdir> --tiles <donovan_tiles.json>

Outputs in <outdir>: vm3.14m/16m/18m/20m (patched), remap_spec.json,
and prints SHA-1s of everything read and written (repo convention).
Verification (always run): re-extract every written position and compare
to the source tile; assert untouched ranges byte-identical to input.
"""

import argparse
import hashlib
import json
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gfx_tiles import GROUP_A, GROUP_B, tile_bytes, write_tile  # noqa: E402

SRC_BANK = 3          # Donovan's bank in vsav2
DST_BANK = 2          # Jedah's bank in vsav (slot-0x0F table row = 0x4000)
DELTA = 0x2750        # 16-aligned code delta, decided session 14
BAND_LO, BAND_HI = 0x863F, 0xC2EF          # Donovan main band (measured)
SAFE_LO, SAFE_HI = 0xAD80, 0xEEBB          # writable window in Jedah band


def load_group(z, prefix, group):
    out = []
    for n in group:
        data = z.read(f"{prefix}.{n}m")
        print(f"  read {prefix}.{n}m sha1 {hashlib.sha1(data).hexdigest()}")
        out.append(data)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("romdir")
    ap.add_argument("outdir")
    ap.add_argument("--tiles", required=True,
                    help="obj_records.py --json output (vs2 tile codes)")
    args = ap.parse_args()
    os.makedirs(args.outdir, exist_ok=True)

    inv = json.load(open(args.tiles))
    band = sorted(t for t in inv if BAND_LO <= t <= BAND_HI)
    skipped = len(inv) - len(band)
    print(f"inventory: {len(inv)} tiles, {len(band)} in main band "
          f"({skipped} effect/low tiles handled by the per-record map, "
          f"not this tool)")
    lo_dst, hi_dst = band[0] + DELTA, band[-1] + DELTA
    assert SAFE_LO <= lo_dst and hi_dst <= SAFE_HI, \
        f"placement 0x{lo_dst:04X}-0x{hi_dst:04X} outside safe window"
    assert DELTA % 16 == 0, "delta must be 16-aligned (block row-wrap)"

    z2 = zipfile.ZipFile(os.path.join(args.romdir, "vsav2.zip"))
    za = zipfile.ZipFile(os.path.join(args.romdir, "vsav.zip"))
    src = load_group(z2, "vs2", GROUP_B)      # bank 3 = group B (>=0x20000)
    dst_orig = load_group(za, "vm3", GROUP_B)  # bank 2 = group B too
    dst = [bytearray(s) for s in dst_orig]

    # src bank 3 -> group-B index = 0x10000 + code
    # dst bank 2 -> group-B index = 0x00000 + code
    written = set()
    for code in band:
        tile = tile_bytes(src, 0x10000 + code)
        write_tile(dst, (code + DELTA), tile)
        written.add(code + DELTA)

    # verification 1: every written position reads back as the source tile
    for code in band:
        got = tile_bytes(dst, code + DELTA)
        want = tile_bytes(src, 0x10000 + code)
        assert got == want, f"readback mismatch at dst code 0x{code+DELTA:04X}"
    # verification 2: untouched positions byte-identical to input
    dirty = 0
    for t2 in range(0, 0x20000):
        if t2 in written:
            continue
        if tile_bytes(dst, t2) != tile_bytes(
                [memoryview(x) for x in dst_orig], t2):
            print(f"FAIL: untouched tile 0x{t2:05X} changed")
            dirty += 1
    assert dirty == 0, f"{dirty} untouched tiles changed"
    print(f"verified: {len(band)} tiles placed at codes "
          f"0x{lo_dst:04X}-0x{hi_dst:04X} (bank {DST_BANK}); "
          f"all other tiles byte-identical")

    for n, buf in zip(GROUP_B, dst):
        path = os.path.join(args.outdir, f"vm3.{n}m")
        open(path, "wb").write(buf)
        print(f"  wrote vm3.{n}m sha1 {hashlib.sha1(bytes(buf)).hexdigest()}")

    spec = {"delta": DELTA, "band_lo": BAND_LO, "band_hi": BAND_HI,
            "dst_bank_word": DST_BANK << 13,
            "src_bank_word": SRC_BANK << 13,
            "placed": [lo_dst, hi_dst]}
    json.dump(spec, open(os.path.join(args.outdir, "remap_spec.json"), "w"),
              indent=1)
    print(f"wrote remap_spec.json: {spec}")


if __name__ == "__main__":
    main()
