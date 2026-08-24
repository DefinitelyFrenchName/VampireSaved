#!/usr/bin/env python3
"""mister_sdram_census.py — THE SDRAM IMAGE CENSUS (14z-107 (9), MiSTer slice D2).

WHAT IT DOES. Takes the four post-download SDRAM bank images a Verilator run
dumped (`tools/run_sim_jtcps2.sh --keep-banks`) and the `.rom` that was
downloaded, replays the CPS-2 download mapping in Python, and compares the
result BYTE FOR BYTE against all four 16 MB banks. Every byte of every bank is
accounted for: a region that landed at the wrong offset fails, a region that
landed in the wrong BANK fails, and a byte written anywhere the map says
nothing lives also fails, because the expectation is zero there.

WHY IT IS THE RIGHT EVIDENCE FOR SLICE D2. D2 PLACES the CPS-2 WIDE romset in
SDRAM; the fetch that READS group C is the obj promote, which is slice D3. So
D2 cannot be proven by running the game — nothing reads the new regions yet.
What CAN be proven, completely, is that the download put every byte where
`docs/project/mister_map.md` section 5 says it goes. That is this tool.

HOW A .rom BYTE REACHES A DUMP BYTE — derived from the RTL and the harness,
not guessed:
  * `jtcps1_prom_we.v:137` `prog_mask <= !ioctl_addr[0] ? 2'b10 : 2'b01`, and
    jtframe's write masks are ACTIVE LOW, so an EVEN region byte goes to the
    LOW half of the 16-bit SDRAM word and an ODD one to the HIGH half.
  * `test.cpp` `write_bank16` stores through an `int16_t*` on a little-endian
    host, so word W's low byte is `banks[k][2W]` and its high byte
    `banks[k][2W+1]`.
  * `test.cpp` `SDRAM::dump()` writes `out[j^1] = banks[k][j]`.
Composing: a region byte at region offset `r`, placed at 16-bit word offset
`OFF`, lands at dump index `2*OFF + (r ^ 1)`. Since `2*OFF` is even that is
`(BYTE_OFF + r) ^ 1` — i.e. **each region appears at its byte offset with the
16-bit words byte-swapped**. The same composition is what makes
`sdram_bank0.bin == byteswap(rom body)` on a stock image, which
docs/platform/mister.md already records as an independent cross-check.

THE GFX SCRAMBLE. `jtcps1_prom_we.v:105` permutes the GFX region address at
download time: `g = { a[25:21], a[3], a[20:4], a[2:0] }`. It is a pure bit
permutation and it only moves bits inside a 2 MB block, so the census walks the
region 2 MB at a time and un-permutes with sixteen strided slice copies per
block (see `unscramble_block`). Bits 25:21 pass straight through, which is why
the group-C test (`g[25]`) and the obj-bank test (`g[23]`) read the same before
and after it.

CONTROLS. `--perturb NAME` shifts one placement constant of the EXPECTED map by
`--perturb-kib` (default 1 KiB) and re-runs: a census that cannot say no is not
evidence. Names: prg, z80, pcm_hi, pcm_lo, gfxc4, gfxc5, gfx.

Usage:
  tools/mister_sdram_census.py <bankdir> --rom <file.rom> --map wide|stock
      [--perturb NAME] [--perturb-kib N]

RULE 7: the bank images and the .rom are ROM-derived. This tool READS them from
a scratch directory and prints only offsets, lengths, counts and hashes.
"""
import argparse
import hashlib
import os
import sys

BANK = 16 << 20
HDR = 44                    # JTFRAME_HEADER on CPS-2
KEY = 20                    # the CPS-2 key region
FULL_HEADER = HDR + KEY     # jtcps1_prom_we.v:58, FULL_HEADER = 26'd64
BLK = 1 << 21               # the CPS-2 GFX scramble is contained in 2 MB

# ---- the map, in BANK BYTE offsets (2 x the 23-bit WORD constants in RTL) ---
# cores/cps2w/hdl/jtcps1_sdram.v; docs/project/mister_map.md section 5.
WIDE = dict(prg=(0, 0x000000), z80=(0, 0x658000), pcm_hi=(0, 0x6E0000),
            gfxc5=(0, 0x7E0000), pcm_lo=(1, 0x000000), gfxc4=(1, 0x800000))
# cores/cps1/hdl/jtcps1_sdram.v as upstream ships it (the reference core).
STOCK = dict(prg=(0, 0x000000), z80=(0, 0x700000), pcm_lo=(1, 0x000000))

PCM_SPLIT = 0x800000        # DSP sample bank 0x80 == pcm_addr[23]


def bswap(src):
    """16-bit byte swap: out[i] = src[i^1]. src must have even length."""
    out = bytearray(len(src))
    out[0::2] = src[1::2]
    out[1::2] = src[0::2]
    return out


def unscramble_block(src):
    """Undo jtcps1_prom_we.v:105 for one 2 MB block.

    Within a block the permutation is g = { a[3], a[20:4], a[2:0] }, so writing
    g as (t, m, n) = (g[20], g[19:3], g[2:0]) gives a = m*16 + t*8 + n. For a
    FIXED n the destination indices t*2^20 + m*8 + n and the source indices
    m*16 + t*8 + n are both arithmetic progressions, so the whole permutation
    is sixteen strided slice copies rather than 2 million index lookups.
    """
    out = bytearray(BLK)
    half = BLK >> 1
    for t in (0, 1):
        for n in range(8):
            out[t * half + n: t * half + half: 8] = src[t * 8 + n: BLK: 16]
    return out


def diffs(a, b):
    """(count, first index) of differing bytes; (0, -1) when equal."""
    if a == b:
        return 0, -1
    n, first = 0, -1
    step = 1 << 16
    for i in range(0, len(a), step):
        ca, cb = a[i:i + step], b[i:i + step]
        if ca == cb:
            continue
        for j in range(len(ca)):
            if ca[j] != cb[j]:
                n += 1
                if first < 0:
                    first = i + j
    return n, first


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("bankdir")
    ap.add_argument("--rom", required=True)
    ap.add_argument("--map", choices=("wide", "stock"), default="wide")
    ap.add_argument("--perturb", default="")
    ap.add_argument("--perturb-kib", type=int, default=1)
    a = ap.parse_args()

    place = dict(WIDE if a.map == "wide" else STOCK)
    gfx_shift = 0
    if a.perturb:
        d = a.perturb_kib * 1024
        if a.perturb == "gfx":
            gfx_shift = d
        elif a.perturb in place:
            bk, off = place[a.perturb]
            place[a.perturb] = (bk, off + d)
        else:
            sys.exit(f"--perturb {a.perturb}: not a region of the {a.map} map "
                     f"({', '.join(sorted(place))}, gfx)")
        print(f"  PERTURBED: {a.perturb} moved by +{d} B — this run MUST FAIL")

    with open(a.rom, "rb") as fh:
        rom = fh.read()
    print(f"  rom  {a.rom} {len(rom)} B sha1 "
          f"{hashlib.sha1(rom).hexdigest()[:16]}...")
    if len(rom) <= FULL_HEADER:
        sys.exit("the .rom is shorter than its own header")

    # ---- the header words --------------------------------------------------
    # jtcps1_prom_we.v:148-149 shifts bytes 0-7 in from the TOP of a 64-bit
    # register, so byte 0 is the LSB of snd_start, byte 1 its MSB, and so on.
    w = [rom[2 * i] | (rom[2 * i + 1] << 8) for i in range(4)]
    snd_start, pcm_start, gfx_start, qsnd_start = w
    print(f"  header words (KiB): audiocpu {snd_start}  qsound {pcm_start}  "
          f"gfx {gfx_start}  firmware {qsnd_start}")
    body = rom[FULL_HEADER:]
    bounds = [0, snd_start << 10, pcm_start << 10, gfx_start << 10,
              qsnd_start << 10, len(body)]
    if bounds != sorted(bounds):
        sys.exit(f"header words are not monotonic: {bounds}")
    prg, z80 = body[bounds[0]:bounds[1]], body[bounds[1]:bounds[2]]
    oki, gfx = body[bounds[2]:bounds[3]], body[bounds[3]:bounds[4]]
    fw = body[bounds[4]:bounds[5]]
    print(f"  regions: prg {len(prg)} B  audiocpu {len(z80)} B  "
          f"qsound {len(oki)} B  gfx {len(gfx)} B  firmware {len(fw)} B")

    # ---- build the expected image -----------------------------------------
    exp = [bytearray(BANK) for _ in range(4)]
    laid = []                       # (name, bank, byte offset, length)

    def lay(name, bank, off, data):
        if not data:
            return
        if len(data) & 1:
            sys.exit(f"{name}: odd length {len(data)}; the 16-bit word "
                     "placement is not defined for it")
        if off + len(data) > BANK:
            sys.exit(f"{name}: {len(data)} B at {off:#x} overflows bank {bank}")
        exp[bank][off:off + len(data)] = bswap(data)
        laid.append((name, bank, off, len(data)))

    lay("68k PRG", *place["prg"], prg)
    lay("Z80 program", *place["z80"], z80)
    if a.map == "wide":
        lay("QSound PCM low  (DSP banks 0x00-0x7F)", *place["pcm_lo"],
            oki[:PCM_SPLIT])
        lay("QSound PCM high (DSP banks 0x80+)", *place["pcm_hi"],
            oki[PCM_SPLIT:])
    else:
        lay("QSound PCM", *place["pcm_lo"], oki)
    # the firmware region is the QSound DSP internal ROM: prom_we, never SDRAM
    if fw:
        laid.append(("firmware (prom_we, NOT in SDRAM)", -1, 0, len(fw)))

    # ---- GFX, 2 MB block at a time, through the inverse scramble ------------
    nblk, rem = divmod(len(gfx), BLK)
    if rem:
        sys.exit(f"the GFX region is {len(gfx)} B, not a multiple of 2 MB — "
                 "the block-wise scramble walk assumes it is")
    seen = {}
    for b in range(nblk):
        src = unscramble_block(gfx[b * BLK:(b + 1) * BLK])
        g25, g24, g23, lo2 = (b >> 4) & 1, (b >> 3) & 1, (b >> 2) & 1, b & 3
        if a.map == "wide" and g25:
            bank, base = place["gfxc5" if g23 else "gfxc4"]
            name = f"GFX group C obj bank {5 if g23 else 4}"
            off = base + (lo2 << 21)
        else:
            bank, name = 2 + g23, f"GFX obj bank {g23 + 2 * g24 + 4 * g25}"
            off = (g24 << 23) | (lo2 << 21)
        off += gfx_shift
        if off + BLK > BANK:
            sys.exit(f"{name}: 2 MB block at {off:#x} overflows bank {bank}")
        exp[bank][off:off + BLK] = bswap(src)
        lo, hi = seen.get((name, bank), (off, off + BLK))
        seen[(name, bank)] = (min(lo, off), max(hi, off + BLK))
    for (name, bank), (lo, hi) in sorted(seen.items(),
                                         key=lambda x: (x[0][1], x[1][0])):
        laid.append((name, bank, lo, hi - lo))

    # ---- report the map, then compare --------------------------------------
    print("\n  region                                   bank    byte offset"
          "        length")
    for name, bank, off, ln in laid:
        where = "  --  " if bank < 0 else f"  {bank}   "
        print(f"  {name:<39}{where}{off:#012x} {ln:>12}")

    print()
    bad = 0
    for k in range(4):
        f = os.path.join(a.bankdir, f"sdram_bank{k}.bin")
        if not os.path.isfile(f):
            print(f"  FAIL bank {k}: {f} is missing")
            bad += 1
            continue
        with open(f, "rb") as fh:
            got = fh.read()
        if len(got) != BANK:
            print(f"  FAIL bank {k}: {len(got)} B, expected {BANK}")
            bad += 1
            continue
        used = BANK - got.count(0)
        n, first = diffs(bytes(exp[k]), got)
        if n == 0:
            print(f"  PASS bank {k}: all {BANK:,} B match the map "
                  f"({used:,} non-zero, {100.0 * used / BANK:.1f}% of the bank)")
        else:
            bad += 1
            print(f"  FAIL bank {k}: {n:,} of {BANK:,} bytes differ; first at "
                  f"{first:#x} (image {got[first]:#04x}, map {exp[k][first]:#04x})")
    print()
    if a.perturb:
        if bad:
            print(f"PASS control: the perturbed map ({a.perturb} "
                  f"+{a.perturb_kib} KiB) is REJECTED by the census")
            return 0
        print(f"FAIL control: the census accepted a map with {a.perturb} moved "
              f"by {a.perturb_kib} KiB — it is not testing the placement")
        return 1
    if bad:
        print(f"FAIL: SDRAM image census — {bad} of 4 banks disagree with "
              "docs/project/mister_map.md section 5")
        return 1
    print("PASS: SDRAM image census — every byte of all four banks is where "
          "docs/project/mister_map.md section 5 places it")
    return 0


if __name__ == "__main__":
    sys.exit(main())
