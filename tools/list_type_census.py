#!/usr/bin/env python3
# list_type_census.py — census the SPRITE-LIST TYPES in a span of a romset's
# data view, so "does this tenant need a second gfx bank?" is a measurement
# and not an assumption.
#
# WHY (14z-74). `build/manifest/gfx_layout3.toml` asserts a ONE-SOURCE-BANK
# premise: a tenant's art is one contiguous band in one source bank, so a
# delta-0 placement into WIDE group C is complete. That premise is FALSE for
# any tenant carrying a **list type 4** — the procedural strip generator
# composes its OWN bank word (`ori.w #$2000` = bank 1) instead of taking the
# object's `+0x18`, so its art cannot reach group C through the record path
# and needs a ported handler + a `--strip-tiles` copy (Huitzil's beam, 14z-71).
# `docs/project/porting_sprite_lists.md` §4 says to re-check this per tenant
# BEFORE the gfx rung. This tool is that check.
#
# THE VALIDATOR MUST BE CONTROLLED. A first pass at this measurement reported
# "0 type-4" for Huitzil — whose beam is a KNOWN type 4 — because type 4 was
# being rejected by the coordinate-pointer constraint that only types 0/2/8
# have (type 4 carries its entries INLINE, no cptr). A census that cannot see
# the thing it is looking for reads exactly like a clean result. Hence
# --control: assert an expected count in a span known to contain them.
#
# Usage:
#   python3 tools/list_type_census.py <data.bin> --start 0x264086 --len 0x1B500
#   python3 tools/list_type_census.py <data.bin> --start .. --len .. \
#           --expect-type4 0            # fail if the count differs
#
# <data.bin> is a DATA-view image (tools/cps2_decrypt.py --data-out).

import argparse
import sys

TYPES = (0, 2, 4, 6, 8, 10, 12)


def census(dat, start, end, cptr_lo=0x100000, cptr_hi=0x400000):
    """Count sprite-list heads by type word (+0) over [start,end).

    Per-type validation mirrors the drawer's own formats
    (docs/game/atlas/sprite_lists.md §3):
      0/2/8 : +2 budget, +4 count-1, +6 coordinate-stream POINTER
      4     : +2 budget, +4 count-1, then INLINE 8-byte entries (no pointer)
      12    : composite/group — a count then N x {dx,dy,sub-list ptr}
    """
    out = {}
    for a in range(start, end - 10, 2):
        f = int.from_bytes(dat[a:a + 2], "big")
        if f not in TYPES:
            continue
        budget = int.from_bytes(dat[a + 2:a + 4], "big")
        count = int.from_bytes(dat[a + 4:a + 6], "big")
        cptr = int.from_bytes(dat[a + 6:a + 10], "big")
        if f == 0:
            if not (0 < budget <= 0x100) or not (cptr_lo <= cptr < cptr_hi):
                continue
        elif f in (2, 8):
            if not (0 < count + 1 <= budget <= 0x100):
                continue
            if not (cptr_lo <= cptr < cptr_hi):
                continue
        elif f == 4:
            # NO cptr constraint — entries are inline. This is the bug that
            # made the first version of this census blind to type 4.
            if not (0 < count + 1 <= budget <= 0x100):
                continue
        elif f == 12:
            if not (0 < count + 1 <= 0x40):
                continue
        else:
            continue
        out[f] = out.get(f, 0) + 1
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--start", type=lambda x: int(x, 0), required=True)
    ap.add_argument("--len", dest="length", type=lambda x: int(x, 0))
    ap.add_argument("--end", type=lambda x: int(x, 0))
    ap.add_argument("--label", default="span")
    ap.add_argument("--expect-type4", type=int, default=None,
                    help="fail unless the type-4 count equals this")
    a = ap.parse_args()
    if a.end is None:
        if a.length is None:
            ap.error("give --len or --end")
        a.end = a.start + a.length
    dat = open(a.image, "rb").read()
    got = census(dat, a.start, a.end)
    print(f"{a.label}: 0x{a.start:06x}-0x{a.end:06x} "
          f"types {dict(sorted(got.items()))}")
    n4 = got.get(4, 0)
    print(f"  type-4 (procedural strip; needs a ported handler + strip-tiles "
          f"to reach group C): {n4}")
    if a.expect_type4 is not None and n4 != a.expect_type4:
        print(f"FAIL: expected {a.expect_type4} type-4 lists, measured {n4}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
