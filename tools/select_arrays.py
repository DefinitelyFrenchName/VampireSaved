#!/usr/bin/env python3
"""select_arrays.py — decode the select-screen record-pointer array, the
table that decides which portrait/name/etc the hovered cell displays.

WHY THIS EXISTS (M3a). The port's select mechanism today is IN-PLACE record
surgery (tools/select_port.py): the tenant sits in Jedah's slot 0x0F, so
replacing the CONTENT of the records that slot already points at fixes both
players with zero pointer pokes. Moving the tenant to id 0x13 cannot work
that way — it needs its OWN records — and the queued question was how much
the mechanism has to change. This tool answers it from the ROM.

THE MEASURED MODEL (14z-61; every number below cross-checked in-emulator,
see tests/test_select_arrays.sh):

    P1 array   PRG:0x26742A   stride 4   rows 0x00-0x1F
    P2 array   PRG:0x2674AA   = P1 + 0x80, same shape
    index      the CELL/ID, unmasked (the consumer masks to 8 bits, not 4)
    rows 0x10-0x1F  alias rows 0x00-0x0F byte-for-byte — the VARIANT HALF,
                    exactly the convention docs/atlas/id_space.md found in
                    every other per-character table

Consumers: PRG:0x05F328 and PRG:0x06C0E0 (`movea.l #$2672AA,a0` +
`lea $FC(a0,d0.w),a0`; the second adds d1=0x80 for P2), storing the cell
pointer at $1C(a6). The record itself is the LONG AT CELL+4, walked by the
format dispatcher at PRG:0x01AFA6.

CONSEQUENCE: a tenant at id 0x13 has a FIRST-CLASS ROW here — PRG:0x267476
(P1) and PRG:0x2674F6 (P2) — which today merely alias Victor's records.
Repointing those two longs gives the tenant its own select records. No
widening, no fold to defeat, and no legacy row touched: no legacy id can
index the variant half (tests/audit_id_writers.sh).

Usage: select_arrays.py <vsavj_data.bin> [--id 0x13] [--json OUT]
"""

import argparse
import json
import sys

P1_BASE = 0x26742A
P2_DELTA = 0x80
STRIDE = 4
ROWS = 0x20
# Cross-checks that must hold for the model to be the right one.
KNOWN = {0x01: 0x27195E, 0x03: 0x2719DA, 0x07: 0x271B0E, 0x0F: 0x271CE8}
JEDAH = 0x0F


def rd32(img, off):
    return int.from_bytes(img[off:off + 4], "big")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("data")
    ap.add_argument("--id", default="0x13", help="tenant id to report on")
    ap.add_argument("--json")
    a = ap.parse_args()
    img = open(a.data, "rb").read()
    tid = int(a.id, 0)

    print(f"  P1 array PRG:0x{P1_BASE:06X}   P2 array PRG:0x{P1_BASE+P2_DELTA:06X}"
          f"   stride {STRIDE}   rows 0x{ROWS:02X}")

    out = {"p1_base": P1_BASE, "p2_base": P1_BASE + P2_DELTA,
           "stride": STRIDE, "rows": ROWS, "p1": [], "p2": []}
    bad = 0
    for label, base, key in (("P1", P1_BASE, "p1"),
                             ("P2", P1_BASE + P2_DELTA, "p2")):
        print(f"\n== {label}")
        for i in range(ROWS):
            off = base + i * STRIDE
            v = rd32(img, off)
            alias = ""
            if i >= 0x10:
                lo = rd32(img, base + (i - 0x10) * STRIDE)
                alias = ("  == row 0x%02X (variant alias)" % (i - 0x10)
                         if v == lo else "  !! DIVERGES from row 0x%02X" % (i - 0x10))
                if v != lo:
                    bad += 1
            tag = ""
            if label == "P1" and i in KNOWN:
                ok = v == KNOWN[i]
                tag = ("  <- measured in-emulator" if ok
                       else "  !! MEASURED %06X" % KNOWN[i])
                if not ok:
                    bad += 1
            if i == JEDAH:
                tag += "  [Jedah — the port's current slot]"
            if i == tid:
                tag += f"  [TENANT TARGET id 0x{tid:02X}]"
            out[key].append({"row": i, "addr": off, "ptr": v})
            print(f"   row 0x{i:02X}  PRG:0x{off:06X}  -> 0x{v:06X}{alias}{tag}")

    p1 = P1_BASE + tid * STRIDE
    p2 = P1_BASE + P2_DELTA + tid * STRIDE
    print(f"\n== a tenant at id 0x{tid:02X} owns two longs:")
    print(f"   P1  PRG:0x{p1:06X}  currently 0x{rd32(img, p1):06X} "
          f"(alias of row 0x{tid - 0x10:02X})")
    print(f"   P2  PRG:0x{p2:06X}  currently 0x{rd32(img, p2):06X} "
          f"(alias of row 0x{tid - 0x10:02X})")
    print("   Repointing them is the whole select-record mechanism at a "
          "variant id:\n   no widening, no fold, and no legacy row touched.")

    if a.json:
        json.dump(out, open(a.json, "w"), indent=1)
        print(f"   wrote {a.json}")
    if bad:
        print(f"\nFAIL: {bad} cross-check(s) did not hold — the model is wrong "
              f"for this image")
        return 1
    print("\nOK: every in-emulator cross-check and every variant alias holds")
    return 0


if __name__ == "__main__":
    sys.exit(main())
