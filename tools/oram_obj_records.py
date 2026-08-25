#!/usr/bin/env python3
"""Walk a RAW OBJ-RAM (ORAM) dump into the SAME record lines that
tests/lua/obj_records_dump.lua prints from a live MAME machine.

WHY THIS EXISTS. The MiSTer core has no Lua and no memory-space API — all it
can hand back is a block of SDRAM bytes (`run_sim_jtcps2.sh --region`). MAME
can hand back the same block by address. So a byte-level walker that both
sides share turns ORAM into a CROSS-IMPLEMENTATION surface: the OBJ list is
what the 68k BUILDS, so unlike the palette or the scroll tilemaps the two
implementations have no licence to disagree about it.

THE WALK IS NOT INVENTED HERE. It is transcribed from obj_records_dump.lua
(y bit 15 terminates; attr >= 0xFF00 terminates; a18 = code | ((y & 0x6000)
<< 3); a19 adds 0x40000 when y bit 12 is set) and `tests/test_obj_records.sh`
requires this file to reproduce that tool's output BYTE FOR BYTE from the
same dump. If the two ever disagree, the lua is the authority: it reads the
machine, this reads a copy.

ORAM IS DOUBLE-BUFFERED. CPS-2 holds two OBJ pages and the hardware selects
between them at run time (on the FPGA core that is
`main_addr_x[13] = main_ram_addr[15] ^ obank`). So a dump contains BOTH, and
which one is live is not something either side can be assumed into. Hence
--buffer: dump both, compare both, and let the terminator say which is real
(the live page terminates; the idle one runs to the 0x400 cap).

Usage:
  oram_obj_records.py <dump.bin> --base-addr 0x700000 [--buffer 0|1|all]
                      [--frame N] [--page-stride 0x8000] [--first-page 0x8000]

  --base-addr    the 68k address the dump's byte 0 corresponds to
  --first-page   offset from base-addr to OBJ page 0 (CPS-2: $708000)
  --page-stride  distance to page 1 (CPS-2: 0x8000)
"""
import sys, struct, argparse

CAP = 0x400          # the walker's entry cap, as in the lua
ATTR_TERM = 0xFF00


def walk(buf, page_off, frame, bi, out):
    """Emit one page's records. Returns the number of entries emitted."""
    n = 0
    for i in range(CAP):
        off = page_off + i * 8
        if off + 8 > len(buf):
            break
        x, y, code, attr = struct.unpack_from(">HHHH", buf, off)
        if y & 0x8000:
            break
        if attr >= ATTR_TERM:
            break
        a18 = code | ((y & 0x6000) << 3)
        a19 = a18 | (0x40000 if (y & 0x1000) else 0)
        out.append(
            "F%d B%d E%03d x=%04x y=%04x code=%04x attr=%04x pal=%02x "
            "sz=%dx%d a18=%05x a19=%05x"
            % (frame, bi, i, x, y, code, attr, attr & 0x1F,
               ((attr >> 8) & 15) + 1, ((attr >> 12) & 15) + 1, a18, a19)
        )
        n += 1
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dump")
    ap.add_argument("--base-addr", default="0x700000")
    ap.add_argument("--first-page", default="0x8000")
    ap.add_argument("--page-stride", default="0x8000")
    ap.add_argument("--buffer", default="all", choices=["0", "1", "all"])
    ap.add_argument("--frame", type=int, default=0)
    ap.add_argument("--summary", action="store_true",
                    help="print only the per-buffer entry counts")
    a = ap.parse_args()

    buf = open(a.dump, "rb").read()
    first = int(a.first_page, 0)
    stride = int(a.page_stride, 0)

    pages = [0, 1] if a.buffer == "all" else [int(a.buffer)]
    out, counts = [], {}
    for bi in pages:
        off = first + bi * stride
        if off >= len(buf):
            print("REFUSING: page %d at offset 0x%x is past the end of a "
                  "0x%x-byte dump — wrong --base-addr/--first-page?"
                  % (bi, off, len(buf)), file=sys.stderr)
            return 2
        counts[bi] = walk(buf, off, a.frame, bi, out)

    if a.summary:
        for bi in pages:
            live = "TERMINATES (live)" if counts[bi] < CAP else "runs to the cap (idle/unterminated)"
            print("B%d entries=%d  %s" % (bi, counts[bi], live))
    else:
        print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
