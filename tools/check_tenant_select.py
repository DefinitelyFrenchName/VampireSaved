#!/usr/bin/env python3
"""check_tenant_select.py — verify a variant-id build's select records
(M3a select-records half, 14z-62).

At a variant-half tenant id the generator composes the tenant's OWN select
records (three UI pieces x P1/P2) into space-model allocations and repoints
the six variant-half array rows; the host character's records must return
to VANILLA bytes (docs/atlas/select_screen.md; the mechanism gate is
tests/test_select_arrays.sh). This checker re-derives the expected
composition INDEPENDENTLY from the vs2 image + select_port.PLACEMENTS and
requires the built image to match, byte for byte:

  1. the six array rows are repointed, and the 31 OTHER rows of each array
     are byte-identical to vanilla;
  2. each composed record matches vs2's: header (fmt/budget/count = vs2's
     own), coordinate list bytes, and every entry tile either remapped
     through the placement map or kept as a vs2 placeholder code;
  3. the host's select-family bytes are VANILLA again: the whole record
     block PRG:0x271900-0x274700, the select-palette grid column for char
     0x0F, and the shared name-banner coordinate list (the speed-menu pair).

Prints machine-readable lines for the runtime gate:
  ROW <piece> <side> <array-row-addr> -> <record-addr>
  WHEELPTR <value>          (the wheel record referrer PRG:0x2689FE)

Usage:
  check_tenant_select.py <built-prg-dir-or-logical-bin> \
      <vanilla_data.bin> <vs2_data.bin> [--id 0x13]

Exits nonzero with FAIL lines on any violation.
"""

import argparse
import hashlib
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cps2_decrypt as cps  # noqa: E402
import select_port as sp    # noqa: E402  (PLACEMENTS is the single map)

# Measured 14z-61/62e (docs/atlas/select_screen.md, frozen by
# tests/test_select_arrays.sh): (name, vj_base, vs2_base, sides). Paired
# pieces have a P2 array at +0x80 in BOTH engines; splash P1/P2 and the
# win quote are single arrays (the win quote has no P2 twin at all — the
# portrait array follows it immediately).
PIECES = [
    ("portrait",    0x26742A, 0x2A0762, ("p1", "p2")),
    ("name_banner", 0x2675AA, 0x2A08E2, ("p1", "p2")),
    ("highlight",   0x268A02, 0x2A18FE, ("p1", "p2")),
    ("splash_p1",   0x2672AA, 0x2A05E2, ("p1",)),
    ("splash_p2",   0x26732A, 0x2A0662, ("p1",)),
    ("win_quote",   0x2673AA, 0x2A06E2, ("p1",)),
]
WHEELPTR = 0x2689FE
JEDAH_BLOCK = (0x271900, 0x274700)   # every record select_port ever surgered
PAL_GRID, PAL_CHAR, PAL_VARS = 0x3AC000, 0x0F, 11
SHARED_LIST = (0x32A196, 4)          # speed-menu pair (select_port SHARED_LISTS)


def u16(b, o):
    return int.from_bytes(b[o:o + 2], "big")


def u32(b, o):
    return int.from_bytes(b[o:o + 4], "big")


def load_image(path):
    if os.path.isdir(path):
        names = sorted((n for n in os.listdir(path) if cps._PRG_RE.search(n)),
                       key=lambda n: int(cps._PRG_RE.search(n).group(1)))
        blob = b"".join(open(os.path.join(path, n), "rb").read()
                        for n in names)
        return bytes(cps.words_to_logical_bytes(cps.words_from_file_bytes(blob)))
    return open(path, "rb").read()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("built")
    ap.add_argument("vanilla")
    ap.add_argument("vs2")
    ap.add_argument("--id", type=lambda v: int(v, 0), default=0x13)
    args = ap.parse_args()

    img = load_image(args.built)
    van = open(args.vanilla, "rb").read()
    v2 = open(args.vs2, "rb").read()
    for tag, blob in (("built", img), ("vanilla", args.vanilla),
                      ("vs2", args.vs2)):
        h = (hashlib.sha1(blob).hexdigest() if isinstance(blob, bytes)
             else hashlib.sha1(open(blob, "rb").read()).hexdigest())
        print(f"read {tag} sha1 {h}")

    tid = args.id
    assert tid >= 0x10, "checker is for variant-half tenant ids"
    fails = []

    def chk(cond, msg):
        if not cond:
            fails.append(msg)
            print(f"FAIL: {msg}")

    for nm, p1, vs2p1, sides in PIECES:
        for side in sides:
            base = p1 if side == "p1" else p1 + 0x80
            vbase = vs2p1 if side == "p1" else vs2p1 + 0x80
            row = base + 4 * tid
            dst = u32(img, row)
            chk(dst != u32(van, row),
                f"{nm}/{side} row {tid:#04x} at {row:#x} not repointed")
            chk(all(img[base + 4 * i:base + 4 * i + 4]
                    == van[base + 4 * i:base + 4 * i + 4]
                    for i in range(32) if i != tid),
                f"{nm}/{side}: a row other than {tid:#04x} differs from vanilla")
            print(f"ROW {nm} {side} {row:#x} -> {dst:#x}")

            # independent re-derivation from the vs2 source record
            vrec = u32(v2, vbase + 4 * tid)
            fmt, bud, cm1 = struct.unpack(">HHH", v2[vrec:vrec + 6])
            cnt = cm1 + 1
            vcptr = u32(v2, vrec + 6)
            chk(struct.unpack(">HHH", img[dst:dst + 6]) == (fmt, bud, cm1),
                f"{nm}/{side} record header != vs2's (fmt/budget/count)")
            ncptr = u32(img, dst + 6)
            chk(img[ncptr:ncptr + 4 * cnt] == v2[vcptr:vcptr + 4 * cnt],
                f"{nm}/{side} coord list bytes != vs2's")
            for k in range(cnt):
                t, at = u16(v2, vrec + 10 + 4 * k), u16(v2, vrec + 12 + 4 * k)
                bx, by = ((at >> 8) & 15) + 1, ((at >> 12) & 15) + 1
                want = sp.PLACEMENTS.get((t, bx, by), t)
                got = (u16(img, dst + 10 + 4 * k), u16(img, dst + 12 + 4 * k))
                chk(got == (want, at),
                    f"{nm}/{side} entry {k}: {got[0]:04X}/{got[1]:04X} != "
                    f"expected {want:04X}/{at:04X}")

    s, e = JEDAH_BLOCK
    chk(img[s:e] == van[s:e],
        f"host select-record block {s:#x}-{e:#x} differs from vanilla")
    chk(all(img[PAL_GRID + (v * 16 + PAL_CHAR) * 0x20:
                PAL_GRID + (v * 16 + PAL_CHAR) * 0x20 + 0x20]
            == van[PAL_GRID + (v * 16 + PAL_CHAR) * 0x20:
                   PAL_GRID + (v * 16 + PAL_CHAR) * 0x20 + 0x20]
            for v in range(PAL_VARS)),
        "select-palette grid column for char 0x0F differs from vanilla")
    a, ln = SHARED_LIST
    chk(img[a:a + ln] == van[a:a + ln],
        f"shared coord list {a:#x} differs from vanilla")

    print(f"WHEELPTR {u32(img, WHEELPTR):#x}")
    if fails:
        print(f"FAIL: {len(fails)} violation(s)")
        sys.exit(1)
    print(f"OK: tenant {tid:#04x} select records verified "
          f"(9 rows, 9 composed records, host bytes vanilla)")


if __name__ == "__main__":
    main()
