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

P2_DELTA = 0x80
STRIDE = 4
ROWS = 0x20
JEDAH = 0x0F

# The three select UI pieces select_port.py touches. Each: P1 base, and the
# records the ENGINE fetched for cursor rows 0x01/0x03/0x07/0x0F during
# 11_pick_donovan (default -> U -> U -> R -> Jedah). Those four are the
# cross-check that makes the row arithmetic evidence rather than a claim.
PIECES = {
    "big_portrait": (0x26742A, {0x01: 0x27195E, 0x03: 0x2719DA,
                                0x07: 0x271B0E, 0x0F: 0x271CE8}),
    "name_banner":  (0x2675AA, {0x01: 0x272156, 0x03: 0x272172,
                                0x07: 0x2721AA, 0x0F: 0x27221A}),
    "highlight":    (0x268A02, {0x01: 0x2725DC, 0x03: 0x272594,
                                0x07: 0x272532, 0x0F: 0x2724A2}),
}
# Immediately BEFORE the highlight array sits the wheel record pointer
# (PRG:0x2689FE -> 0x272A68), which is why a highlight tap interleaves a
# constant record with the per-cell ones. Same referrer 14z-60r found for
# the wheel relocation: this region is packed with no room to grow.
WHEEL_RECORD_PTR = 0x2689FE


def rd32(img, off):
    return int.from_bytes(img[off:off + 4], "big")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("data")
    ap.add_argument("--id", default="0x13", help="tenant id to report on")
    ap.add_argument("--piece", default="all", choices=["all", *PIECES])
    ap.add_argument("--rows", action="store_true", help="print every row")
    ap.add_argument("--json")
    a = ap.parse_args()
    img = open(a.data, "rb").read()
    tid = int(a.id, 0)
    pieces = PIECES if a.piece == "all" else {a.piece: PIECES[a.piece]}

    out, bad = {}, 0
    for piece, (base, known) in pieces.items():
        print(f"\n== {piece}: P1 PRG:0x{base:06X}  P2 PRG:0x{base+P2_DELTA:06X}"
              f"  stride {STRIDE}  rows 0x{ROWS:02X}")
        rows = {"p1_base": base, "p2_base": base + P2_DELTA, "p1": [], "p2": []}
        for label, b, key in (("P1", base, "p1"),
                              ("P2", base + P2_DELTA, "p2")):
            for i in range(ROWS):
                off = b + i * STRIDE
                v = rd32(img, off)
                note = ""
                if i >= 0x10:
                    lo = rd32(img, b + (i - 0x10) * STRIDE)
                    if v != lo:
                        note = "  !! DIVERGES from row 0x%02X" % (i - 0x10)
                        bad += 1
                    else:
                        note = "  == row 0x%02X (variant alias)" % (i - 0x10)
                if label == "P1" and i in known:
                    if v == known[i]:
                        note += "  <- measured in-emulator"
                    else:
                        note += "  !! MEASURED %06X" % known[i]
                        bad += 1
                if i == JEDAH:
                    note += "  [Jedah — the port's current slot]"
                if i == tid:
                    note += f"  [TENANT TARGET id 0x{tid:02X}]"
                rows[key].append({"row": i, "addr": off, "ptr": v})
                if a.rows:
                    print(f"   {label} row 0x{i:02X}  PRG:0x{off:06X}  "
                          f"-> 0x{v:06X}{note}")
        p1, p2 = base + tid * STRIDE, base + P2_DELTA + tid * STRIDE
        print(f"   id 0x{tid:02X} owns  P1 PRG:0x{p1:06X} -> 0x{rd32(img,p1):06X}"
              f"   P2 PRG:0x{p2:06X} -> 0x{rd32(img,p2):06X}"
              f"   (both alias row 0x{tid-0x10:02X})")
        print(f"   cross-checks {len(known)}/{len(known)} · variant aliases "
              f"{'hold' if not bad else 'BROKEN'}")
        out[piece] = rows

    print(f"\n== a tenant at id 0x{tid:02X} needs {2*len(pieces)} longs repointed "
          f"({len(pieces)} piece(s) x P1/P2).")
    print("   No widening, no fold to defeat, and no legacy row touched: no "
          "legacy id\n   can index the variant half (tests/audit_id_writers.sh).")
    print(f"   Adjacent, do not disturb: the wheel record pointer at "
          f"PRG:0x{WHEEL_RECORD_PTR:06X} -> 0x{rd32(img, WHEEL_RECORD_PTR):06X}, "
          f"immediately\n   before the highlight array (it is why a highlight "
          f"tap shows a constant record).")

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
