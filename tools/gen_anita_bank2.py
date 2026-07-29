#!/usr/bin/env python3
"""gen_anita_bank2.py — regenerate the bank-2 record keys in
build/manifest/effect_tail.json from the EMPIRICAL attribution
(session 14o; replaces f8eda2ca's content-voting, reverted).

Evidence chain: runtime trace (tests/lua/obj_record_bank_trace.lua, 9
replays) shows exactly one x2b7ef4 record drawn by #$4000-bank objects:
0x0FCECA — Anita's feet. Its emitting sub-object's anim cursor
(obj+0x1C = 0x0F619C) walks a local (FF-tag, record-ptr) list; that
list bounds everything the sub-object can ever draw: 54 fmt-2 records,
vs2 codes 0x0F8B-0x0FBC (Donovan-page art, vs2 bank 3). Those records
were mis-triaged by the bank-1 effect-tail maps (+0x47/same-index) —
playtest rounds 10-13: solid-green, then garbled feet.

Writes: bank2_recs = the 54 SOURCE record addresses (walked from the
pristine vs2 stream at 0x2BA120, the src image of dst 0x0F619C);
bank2_place = per-(code,bx,by) shelf targets in the freed Jedah-band
tail, rows continuing above the anim-pass shelf watermark read from an
existing build's effect_map.json.

Usage: gen_anita_bank2.py <vsav2_prg_or_zip> <effect_map.json> [--write]
Prints SHA-1 of what it reads (project convention); --write updates
build/manifest/effect_tail.json in place, else dry-run.
"""

import hashlib
import json
import sys
import zipfile
from pathlib import Path

STREAM_SRC = 0x2BA120        # vs2 addr of the feet sub-object record list
X2B_SRC_LO = 0x2B7EF4        # x2b7ef4 source window (vs2)
X2B_SRC_HI = 0x2B7EF4 + 0xB20C
EFF_LO, EFF_HI = 0xEA40, 0xEEBB   # freed Jedah-band tail (donovan.toml)
EXPECT_RECS = 54


def load_vs2(path):
    p = Path(path)
    if p.suffix == ".zip":
        z = zipfile.ZipFile(p)
        raw = b"".join(z.read(f"vs2j.{n:02d}") for n in range(3, 11))
    else:
        raw = p.read_bytes()
    print(f"vs2 prg sha1 {hashlib.sha1(raw).hexdigest()}")
    img = bytearray(len(raw))
    img[0::2] = raw[1::2]
    img[1::2] = raw[0::2]
    return img


def main():
    vs2 = load_vs2(sys.argv[1])
    emap = json.loads(Path(sys.argv[2]).read_text())
    write = "--write" in sys.argv

    # walk the (FF-tag, rec-ptr) stream in the PRISTINE vs2 image; the
    # pointers there are vs2-space (pre-relocation), so the walk is
    # independent of any build
    recs = []
    o = STREAM_SRC
    while True:
        tag = int.from_bytes(vs2[o:o + 4], "big")
        ptr = int.from_bytes(vs2[o + 4:o + 8], "big")
        if (tag >> 24) != 0xFF or not (X2B_SRC_LO <= ptr < X2B_SRC_HI):
            break
        recs.append(ptr)
        o += 8
    assert len(recs) == EXPECT_RECS, \
        f"stream walk found {len(recs)} records, expected {EXPECT_RECS}"

    # collect (code, bx, by) block keys from the vs2 records (fmt 2)
    keys = set()
    n_words = 0
    for ra in recs:
        fmt = int.from_bytes(vs2[ra:ra + 2], "big")
        assert fmt == 2, f"rec {ra:06X}: fmt {fmt} (expected 2)"
        cnt = int.from_bytes(vs2[ra + 4:ra + 6], "big")
        for k in range(cnt + 1):
            t = int.from_bytes(vs2[ra + 10 + 4 * k:ra + 12 + 4 * k], "big")
            a = int.from_bytes(vs2[ra + 12 + 4 * k:ra + 14 + 4 * k], "big")
            keys.add((t, ((a >> 8) & 15) + 1, ((a >> 12) & 15) + 1))
            n_words += 1
        assert all(t < 0x2000 for t, _, _ in keys), "unexpected band code"

    # shelf watermark: first free 16-aligned row above every dst already
    # assigned by the anim gfx_remap pass (and any prior b2 pairs)
    top = max(d for _, d in emap)
    row0 = (top >> 4) + 1
    shelf_row, shelf_x, shelf_h = row0, 0, 0
    place = {}
    for t, bx, by in sorted(keys, key=lambda k: (-k[2], -k[1], k[0])):
        if shelf_x + bx > 16:
            shelf_row += shelf_h
            shelf_x, shelf_h = 0, 0
        place[(t, bx, by)] = (shelf_row << 4) + shelf_x
        shelf_x += bx
        shelf_h = max(shelf_h, by)
    top_new = ((shelf_row + shelf_h) << 4) - 1
    assert top_new <= EFF_HI, f"shelf overflow: {top_new:#x} > {EFF_HI:#x}"

    print(f"records: {len(recs)} ({recs[0]:06X}..{recs[-1]:06X}), "
          f"{n_words} tile words, {len(keys)} blocks")
    print(f"shelf: rows 0x{row0:03X}0-0x{top_new:04X} "
          f"(prev watermark 0x{top:04X}, cap 0x{EFF_HI:04X})")

    mpath = Path(__file__).resolve().parent.parent / \
        "build/manifest/effect_tail.json"
    et = json.loads(mpath.read_text())
    et["bank2_recs"] = [f"0x{ra:06X}" for ra in recs]
    et["bank2_place"] = {f"0x{t:04X},{bx},{by}": f"0x{d:04X}"
                         for (t, bx, by), d in sorted(place.items())}
    if write:
        mpath.write_text(json.dumps(et, indent=1))
        print(f"wrote {mpath}")
    else:
        print("dry run (--write to update manifest)")


if __name__ == "__main__":
    main()
