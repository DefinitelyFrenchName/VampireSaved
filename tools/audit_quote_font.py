#!/usr/bin/env python3
"""audit_quote_font.py — does vsavj's font ROM carry the GLYPHS vs2's three
tenant win-quote blocks ask for? (14z-116, the win-quote Phase-0 measurement.)

WHY THIS EXISTS. Porting the tenants' quote TEXT moves the vs2 char CODES
into vsavj. A code is not a character: the renderer (`PRG:0x089062`) masks
each code with `andi.w #$fff` and the drawer adds the font base `0x3800`, so
code C draws vsavj's tile `0x3800 + C`. If vs2's tile at that index holds a
different glyph — or vsavj's holds nothing — the ported line renders as
someone else's kana, or as blanks, and NO RAM gate and NO checksum can see
it: text never transits work RAM. That is the question this tool answers,
and it is the one that decides whether the port is data-only or needs tiles.

WHAT IT COMPARES. For every code used by the three vs2 tenant blocks
(decode_win_quotes.py is the source of the code set), the canonical 128-byte
tile at `0x3800 + code` in vsavj vs the same index in vsav2, read through
gfx_tiles.py's interleave (a naive 32-byte slice compares equal for
same-index tiles by accident and is worthless here — see that module's
header). Verdicts per code:

  SAME    both sets hold byte-identical tiles      -> ports for free
  BLANK   vsavj's tile is all-0x00/0xFF, vs2's is not -> the glyph is MISSING
          from vsavj: the code needs a tile port + a code remap
  DIFFER  both non-blank and different             -> the code means a
          DIFFERENT character in vsavj: a port that ignores this renders
          the wrong kana at full opacity (the 14z-68 class: "matches vs2"
          while the screen is wrong)

Codes are counted per tenant so the cost is attributable, and the pad code
(0x1020, blank by design) is reported separately rather than silently
dropped — a "code that renders nothing" is a legitimate part of the data.

Usage:
  audit_quote_font.py <romdir> [--codes-json f] [--font-base 0x3800]
      [--tenants 0x10,0x11,0x13] [--list-missing]
Prints the SHA-1 of every simm read (gfx_tiles.py does it on stderr).
Exit 0 always: this REPORTS, it does not judge — the GO/NO-GO on it is the
maintainer's (the plan's Phase-0 table).
"""
import argparse
import hashlib
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gfx_tiles  # noqa: E402
from decode_win_quotes import (GAMES, fold, load, read_string, sw)  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
PAD_CODE = 0x1020


def tenant_codes(d2, tenants):
    """{tenant_id: {code: n_uses}} from vs2's bank, via the decoder's walk."""
    bank = int.from_bytes(d2[GAMES["vsav2"]["root"]:GAMES["vsav2"]["root"] + 4], "big")
    out = {}
    for t in tenants:
        blk = bank + sw(d2, bank + 2 * fold(t))
        counts = {}
        for i in range(16):
            lines, _, probs = read_string(d2, blk + sw(d2, blk + 2 * i), limit=8)
            for ln in lines:
                for c in ln:
                    counts[c] = counts.get(c, 0) + 1
        out[t] = counts
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("romdir")
    ap.add_argument("--font-base", type=lambda x: int(x, 0), default=0x3800)
    ap.add_argument("--tenants", default="0x10,0x11,0x13")
    ap.add_argument("--list-missing", action="store_true")
    # The gfx simms live in the PARENT set (vsavj is a clone whose zip holds
    # only program members) — vsav.zip:vm3 / vsav2.zip:vs2, the same specs
    # every other gate uses.
    ap.add_argument("--host-gfx", default="vsav.zip:vm3")
    ap.add_argument("--src-gfx", default="vsav2.zip:vs2")
    a = ap.parse_args()
    tenants = [int(x, 0) for x in a.tenants.split(",")]

    d2 = load(REPO / "build" / "out" / "vsav2_data.bin")
    codes = tenant_codes(d2, tenants)
    allc = sorted(set().union(*[set(c) for c in codes.values()]))
    print(f"# tenant blocks use {len(allc)} distinct codes "
          f"({min(allc):#06x}-{max(allc):#06x}), font base {a.font_base:#06x}")

    gj = gfx_tiles.load_simms(f"{a.romdir}/{a.host_gfx}")
    g2 = gfx_tiles.load_simms(f"{a.romdir}/{a.src_gfx}")

    def tile(groups, idx):
        ga, gb = groups
        n = len(ga[0]) // 32
        return gfx_tiles.tile_bytes(ga if idx < n else gb, idx if idx < n else idx - n)

    verdict = {}
    for c in allc:
        idx = a.font_base + c
        tj, t2 = tile(gj, idx), tile(g2, idx)
        bj = hashlib.sha1(tj).digest() in gfx_tiles.BLANK
        b2 = hashlib.sha1(t2).digest() in gfx_tiles.BLANK
        if c == PAD_CODE:
            verdict[c] = "PAD"
        elif tj == t2:
            verdict[c] = "SAME"
        elif bj and not b2:
            verdict[c] = "BLANK"
        elif bj and b2:
            verdict[c] = "PAD"
        else:
            verdict[c] = "DIFFER"

    for t in tenants:
        tally = {}
        for c in codes[t]:
            tally[verdict[c]] = tally.get(verdict[c], 0) + 1
        used = sum(codes[t].values())
        bad = [c for c in codes[t] if verdict[c] in ("BLANK", "DIFFER")]
        badu = sum(codes[t][c] for c in bad)
        print(f"tenant {t:#04x}: {len(codes[t])} distinct codes, {used} uses -> "
              + ", ".join(f"{k} {v}" for k, v in sorted(tally.items()))
              + f"  | codes needing work: {len(bad)} ({badu} uses)")

    tot = {}
    for c in allc:
        tot[verdict[c]] = tot.get(verdict[c], 0) + 1
    print("TOTAL: " + ", ".join(f"{k} {v}" for k, v in sorted(tot.items())))
    need = [c for c in allc if verdict[c] in ("BLANK", "DIFFER")]
    print(f"CODES NEEDING A TILE PORT OR REMAP: {len(need)} of {len(allc)}")
    if a.list_missing and need:
        for c in need:
            print(f"  {c:04x} -> tile {a.font_base + c:#07x}  {verdict[c]}")


if __name__ == "__main__":
    main()
