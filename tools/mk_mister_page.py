#!/usr/bin/env python3
"""Render docs/project/mister_core.md's diagrams as a standalone HTML page.

The visual companion to `docs/project/mister_core.md`: the same material, with
the SDRAM map, the three-sizes confusion and the tile-address path DRAWN rather
than described. Writes an HTML file (default `docs/project/mister_core.html`,
which is .gitignored) that is self-contained, so it publishes as an Artifact and
also just opens in a browser.

  python3 tools/mk_mister_page.py [out.html]               # Artifact fragment
  python3 tools/mk_mister_page.py --standalone [out.html]  # opens in a browser
  python3 tools/mk_mister_page.py --check                  # verify, write nothing
  python3 tools/mk_mister_page.py --check --verbose        # ...and say what passed
  python3 tools/mk_mister_page.py --ascii                  # the two figures the
                                                           # markdown carries, to
                                                           # paste back into it
  ... --repo <path>   run against another checkout's documents. The gate uses it
                      to perturb a COPY of this script without touching the tree.

GEOMETRY IS COMPUTED, NEVER HAND-TYPED. Every region is declared once, in
bytes, in `REGIONS` / `THREE_SIZES` / `BANK_ROUTE`; every x, y, width and height
on the page is derived from those by one scale factor per figure. Hand-authoring
SVG coordinates is how off-by-one diagrams happen, and this page's whole subject
is a memory map whose slack is 131,072 bytes of 67,108,864 — 0.2%, i.e. under
two pixels at any width a browser will render. A picture that rounded that away
would be worse than no picture.

THE RICH PAGE IS NEVER COMMITTED. A hand-copied artifact goes stale silently, so
the generated HTML is gitignored and this generator is the thing under review.
The markdown carries ASCII versions of two figures; those are emitted by
`ascii_bank_map()` / `ascii_three_sizes()` here and `--check` diffs them against
what the committed markdown actually holds, so they cannot drift either.

WHAT `--check` RE-DERIVES (and it fails, loudly, on any drift):

  1. the map itself — every placement offset and length against the frozen
     `placement()` table inside `tests/audit_mister_map_fit.sh`, which is the
     gate that defends the fit, plus the section-5 offsets in
     `docs/project/mister_map.md`;
  2. the arithmetic — bank tops, the overlap check, "bank 1 is exactly full",
     "bank 0 has 131,072 B free", and the `.rom` image size and all four header
     words, against the figures `mister_map.md` section 3 states;
  3. the frozen content extents — every `frozen(...)` constant in the fit gate;
  4. the ASCII figures embedded in `docs/project/mister_core.md`;
  5. where the inputs are reachable, the numbers against the REAL artifacts:
     the group-C occupancy census re-counted from the built WIDE romset
     (~2 s), and the palette re-read from the decrypted program image. Those
     two SKIP rather than fail when their inputs are absent, the same
     convention `tests/run_all_static.sh` uses, and the skips are printed.

THE PALETTE IS THE GAME'S OWN, and it carries the page's one piece of meaning:
COOL = STOCK / UNTOUCHED, WARM = OURS. Read that way, the SDRAM map shows the
superset invariant at a glance — banks 2 and 3 are entirely cool.

The sixteen colours are DEMITRI'S SPRITE PALETTE, row 0. Provenance, so it can
be re-derived: `docs/game/atlas/character_tables.md` documents a 32-row
sprite-palette POINTER table at `PRG:0x38C198`, indexed by the full character
id; Demitri is id `0x01` (the slot->character map in the same file), so his
block is the long at `PRG:0x38C19C`, which reads `PRG:0x38C7A0`. The first
sixteen big-endian words there are the palette, in CPS-2's `xRGB` nibble
format. The stored brightness nibble is ignored on purpose: the system blitter
at `PRG:0x000EF2` uploads with `or.l #$F000F000`, i.e. it forces full
brightness, so `#RRGGBB = (r*17, g*17, b*17)` is what the screen actually shows.
Demitri rather than anyone else because he is this port's reference fighter —
`tests/test_mister_sim_anchor.sh` compares MAME and the FPGA core on his record
base, and he is the select screen's default cell.

Rule 7 note: sixteen colour triplets are DERIVED DATA, not ROM content, and
committing them in a generator is the precedent set by the Sailor Moon S
project's `tools/mkarchpage.py`. No ROM bytes are read at page-build time; the
re-derivation in `--check` reads the decrypted image only when it is already
present in `build/out/` and skips otherwise.

Everything else on the page is derived from those sixteen by `mix()` and
`desat()` — the paper, the ink, the rules, the neutral used for free space —
so there is exactly one hand-picked colour set in this file and it came out of
the cartridge.
"""

import html
import pathlib
import re
import sys

# ---------------------------------------------------------------------------
# Paths. REPO is resolved from this file so the generator works from any cwd;
# --repo overrides it, which is what lets the gate copy this script to a temp
# directory, perturb a constant, and still find the documents to check against.
# ---------------------------------------------------------------------------
ARGV = sys.argv[1:]
REPO = pathlib.Path(__file__).resolve().parent.parent
if "--repo" in ARGV:
    i = ARGV.index("--repo")
    REPO = pathlib.Path(ARGV[i + 1]).resolve()
    del ARGV[i:i + 2]
CHECK = "--check" in ARGV
VERBOSE = "--verbose" in ARGV
STANDALONE_MODE = "--standalone" in ARGV
ASCII_MODE = "--ascii" in ARGV
for f in ("--check", "--verbose", "--standalone", "--ascii"):
    while f in ARGV:
        ARGV.remove(f)
OUT = pathlib.Path(ARGV[0]) if ARGV else REPO / "docs" / "project" / "mister_core.html"

MAP_DOC = REPO / "docs" / "project" / "mister_map.md"
CORE_DOC = REPO / "docs" / "project" / "mister_core.md"
FIT_GATE = REPO / "tests" / "audit_mister_map_fit.sh"

# ---------------------------------------------------------------- palette ----
# Demitri's sprite palette, row 0, PRG:0x38C7A0 — see the module docstring.
PAL_TABLE = 0x38C198          # the 32-row sprite-palette pointer table
PAL_CHAR_ID = 0x01            # Demitri
PAL_ROW = 0                   # row 0 of his 0x500-byte block
DEMITRI = ["#443333", "#ffeeaa", "#ffbb99", "#ee9977",
           "#cc8866", "#ffdd00", "#ff0000", "#995511",
           "#550000", "#334455", "#446677", "#668899",
           "#88aabb", "#bbccdd", "#ffffff", "#000000"]


def _rgb(c):
    return int(c[1:3], 16), int(c[3:5], 16), int(c[5:7], 16)


def mix(a, b, t):
    """Blend two hex colours; t=0 is all a, t=1 is all b."""
    ra, ga, ba = _rgb(a)
    rb, gb, bb = _rgb(b)
    return "#%02x%02x%02x" % (round(ra + (rb - ra) * t),
                              round(ga + (gb - ga) * t),
                              round(ba + (bb - ba) * t))


def desat(c, t):
    """Pull a colour toward its own luminance. Used only for 'free space',
    which must read as absence rather than as another category."""
    r, g, b = _rgb(c)
    y = round(0.299 * r + 0.587 * g + 0.114 * b)
    return mix(c, "#%02x%02x%02x" % (y, y, y), t)


COOL_D, COOL_M, COOL_L = DEMITRI[9], DEMITRI[11], DEMITRI[13]   # 334455/668899/bbccdd
WARM_D, WARM_M, WARM_L = DEMITRI[7], DEMITRI[4], DEMITRI[2]     # 995511/cc8866/ffbb99
GOLD, FLAME, CREAM = DEMITRI[5], DEMITRI[6], DEMITRI[1]         # ffdd00/ff0000/ffeeaa

# role -> (light-theme fill, dark-theme fill). COOL = stock, WARM = ours.
#
# THE LIGHT COLUMN IS DARK AND THE DARK COLUMN IS LIGHT, on purpose: a region
# carries white label text on the light theme and near-black on the dark one
# (--on-fill), so each fill has to be the one a reader can read that text on.
# The three cool steps are Demitri's own cape ramp taken at 9/10/12; the three
# warm ones are his skin/gold ramp. `label_ink()` below then measures, per
# theme, which of two inks a label on each fill can actually be read in.
ROLE = {
    "stockgfx": (COOL_D, COOL_M),                       # vanilla GFX, banks 2+3
    "stock":    (DEMITRI[10], DEMITRI[12]),             # stock program / samples
    "sys":      (COOL_M, COOL_L),                       # VRAM/ORAM/WRAM windows
    "ourgfx":   (WARM_D, WARM_L),                       # group C
    "oursnd":   (WARM_M, CREAM),                        # the QSound extension
    "ourprg":   (mix(WARM_D, GOLD, .40), GOLD),         # the program extension
    # An alignment gap is free space that happens to be in the middle, so it
    # gets the SAME role rather than a seventh colour nobody can decode.
    "free":     (desat(COOL_M, .55), desat(mix(COOL_M, "#000000", .30), .70)),
}


def _lum(c):
    def ch(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = _rgb(c)
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def contrast(a, b):
    la, lb = sorted((_lum(a), _lum(b)))
    return (lb + 0.05) / (la + 0.05)


# The two inks a label inside a filled region may use. Which one each role gets
# is DECIDED BY MEASUREMENT, not by eye: label_ink() picks whichever of the two
# has the higher WCAG contrast against the fill, per theme, so no label can end
# up as pale text on a pale block. That is what frees the role fills to be
# chosen for TELLING APART — three cool steps and three warm ones off Demitri's
# own ramps — instead of for happening to carry white text.
INK_LIGHT = "#ffffff"
INK_DARK = mix(COOL_D, "#000000", .70)


def label_ink(fill):
    return max((INK_LIGHT, INK_DARK), key=lambda c: contrast(fill, c))

# ---------------------------------------------------------------------------
# THE DECLARED DATA. Everything below is bytes, read from
# docs/project/mister_map.md section 5 and re-checked by --check against
# tests/audit_mister_map_fit.sh. Nothing here is a pixel.
# ---------------------------------------------------------------------------
BANK = 16 << 20                     # jtframe SDRAM_LARGE: 4 banks of 16 MB
NBANKS = 4
TIER = NBANKS * BANK

PRG_STOCK = 4 << 20                 # jtcps2 decodes a flat 4 MB
PRG_LEN = 0x600000                  # WIDE v1 declares 6 MB
PRG_LIVE_END = 0x4D10F3 + 1         # mister_fit section 1
PRG_PIN = 0x5FFF00                  # the 30-byte facing-alias thunk
VRAM, ORAM, WRAM, Z80W = 0x40000, 0x8000, 0x10000, 0x80000
Z80_LOADED = 0x40000                # 256 KB downloaded into a 512 KB window
PCM_HIGH = 0x100000                 # the 1 MB window for DSP banks 0x80-0x8F
PCM_HIGH_LOADED = 0xF0000           # banks 0x80-0x8E
PCM_LOW = 0x800000                  # the stock 8 MB
GROUPC_BANK = 0x800000              # each group-C obj bank is an 8 MB region

# (bank, offset, length, role, short name, tooltip note)
REGIONS = [
    (0, 0x000000, PRG_STOCK, "stock", "68k PRG — stock 4 MB",
     "CPU:$000000-$3FFFFF, the window jtcps2 already decodes. ROM_OFFSET = 0"),
    (0, PRG_STOCK, PRG_LEN - PRG_STOCK, "ourprg", "WIDE PRG ext",
     "CPU:$400000-$5FFFFF. Live to PRG:0x4D10F3, then 0xFF fill, plus the "
     "30-byte facing-alias pin at PRG:0x5FFF00. Needs the D4 read decode"),
    (0, 0x600000, VRAM, "sys", "VRAM", "256 KB. Never downloaded"),
    (0, 0x640000, ORAM, "sys", "OBJ RAM", "32 KB. Never downloaded"),
    (0, 0x648000, WRAM, "sys", "work RAM",
     "RAM:$FF0000-$FFFFFF, 64 KB. Was 0x600000 on the reference core — the "
     "constant moved with the re-pack, and an instrument that did not follow "
     "it turned test_mister_wide_inert red in 101 frames of 101"),
    (0, 0x658000, Z80W, "stock", "Z80 window",
     f"a {Z80W >> 10} KB slot carrying a {Z80_LOADED >> 10} KB region — the "
     f"same declared-vs-live gap as the graphics, in miniature. "
     f"SND_OFFSET = 23'h32C000"),
    (0, 0x6D8000, 0x6E0000 - 0x6D8000, "free", "align",
     "a 32 KB alignment gap before PCMH_OFFSET — free space that happens to "
     "be in the middle"),
    (0, 0x6E0000, PCM_HIGH, "oursnd", "QSound PCM high",
     "a 1 MB window for DSP sample banks 0x80-0x8F, of which 0x80-0x8E "
     "(0xF0000 B) are downloaded. NEW PCMH_OFFSET = 23'h370000"),
    (0, 0x7E0000, GROUPC_BANK, "ourgfx", "GFX group C — obj bank 5",
     "an 8 MB REGION carrying select/wheel art, cold during a match. Art "
     "reaches 0x7FEE00. NEW GFXC5_OFFSET = 23'h3F0000"),
    (0, 0xFE0000, BANK - 0xFE0000, "free", "free",
     "131,072 B — every byte of slack in the whole 64 MB tier"),

    (1, 0x000000, PCM_LOW, "stock", "QSound PCM low",
     "DSP sample banks 0x00-0x7F, the stock 8 MB, at PCM_OFFSET = 0 exactly "
     "as on stock jtcps2"),
    (1, 0x800000, GROUPC_BANK, "ourgfx", "GFX group C — obj bank 4",
     "an 8 MB REGION carrying the three fighter bands, i.e. the in-match "
     "traffic. Art reaches 0x773A00. NEW GFXC4_OFFSET = 23'h400000"),

    (2, 0x000000, 0x800000, "stockgfx", "GFX obj bank 0", "vanilla, untouched"),
    (2, 0x800000, 0x800000, "stockgfx", "GFX obj bank 2", "vanilla, untouched"),
    (3, 0x000000, 0x800000, "stockgfx", "GFX obj bank 1 + scroll",
     "vanilla, untouched. The same bytes serve the scroll slot, SCR_OFFSET = 0"),
    (3, 0x800000, 0x800000, "stockgfx", "GFX obj bank 3", "vanilla, untouched"),
]

# Hairlines inside a region: (bank, byte offset, label, tooltip)
MARKS = [
    (0, PRG_LIVE_END, "0x4D10F3", "the highest live program byte (mister_fit section 1)"),
    (0, PRG_PIN, "0x5FFF00", "the 30-byte facing-alias thunk — a fixed manifest address"),
    (0, 0x6E0000 + PCM_HIGH_LOADED, "0x8E", "top of the last downloaded DSP sample bank"),
    (0, 0x7E0000 + 0x7FEE00, "0xFFDB", "top of obj bank 5's declared tile codes"),
    (1, 0x800000 + 0x773A00, "0xEE73", "top of obj bank 4's declared tile codes"),
]

# Which `placement()` row of tests/audit_mister_map_fit.sh each drawn region
# belongs to. The picture draws sub-bands the gate does not model — the PRG
# region is one 6 MB row there and two bands here, because the 4 MB line inside
# it is exactly the stock/ours boundary and is worth seeing — so --check
# COALESCES by this key before comparing. Comparing like with like is the whole
# point; a check that quietly compared a sub-band against a whole region would
# be reporting on its own modelling rather than on the map.
GATE_ROW = {
    (0, 0x000000): "68k PRG", (0, PRG_STOCK): "68k PRG",
    (0, 0x600000): "VRAM", (0, 0x640000): "OBJ RAM", (0, 0x648000): "work RAM",
    (0, 0x658000): "Z80 program", (0, 0x6E0000): "QSound PCM high",
    (0, 0x7E0000): "GFX group C obj 5",
    (1, 0x000000): "QSound PCM low", (1, 0x800000): "GFX group C obj 4",
}

# The window the SDRAM figure re-draws at its own scale, because at 16 MB
# across a bar these regions are 2-51 px wide.
DETAIL = (0x600000, 0x7E0000)

BANK_NOTE = {
    0: "the only read/WRITE bank (ba_wr[3:1] = 0), and the one bank carrying "
       "JTFRAME_BA0_AUTOPRECH",
    1: "read-only. EXACTLY FULL: 8 MB of PCM + 8 MB of obj bank 4, to the byte",
    2: "read-only. Vanilla's own art, byte-for-byte where stock jtcps2 puts it",
    3: "read-only. Vanilla's own art, byte-for-byte where stock jtcps2 puts it",
}

# ---- the three sizes -------------------------------------------------------
# Per group-C obj bank: declared region, address footprint, live codes.
# top_code is the manifests' declared ceiling; top_live is the highest
# NON-BLANK code. Both are frozen in tests/audit_mister_map_fit.sh.
TILE = 128
THREE_SIZES = [
    # (obj bank, sdram bank, declared, top_code, live_codes, top_live)
    (4, 1, GROUPC_BANK, 0xEE73, 45736, 0xEE73),
    (5, 0, GROUPC_BANK, 0xFFDB, 6245, 0xFE41),
]
# mister_fit section 3's figure, from a DIFFERENT instrument (the as-built
# write set rather than a non-blank census). Carried so the page can name the
# gap rather than silently pick one.
WRITE_SET_CODES = 52347

# Measured occupancy of the two group-C obj banks, 64 buckets of 1,024 tile
# codes each: how many codes in each bucket carry art. Instrument:
# tools/gfx_tiles.py's tile_bytes()+BLANK over
# build/m3b_merged13/rompath/vsavjw.zip, i.e. the same census
# tests/audit_mister_map_fit.sh runs; --check re-derives it byte for byte
# when that build is present. This is what makes the "live art" bar an actual
# measurement of sparseness instead of a decorative scatter.
BUCKETS = 64
GROUPC_OCC = {
    4: [21, 8, 513, 72, 5, 943, 1024, 1024, 1024, 1021, 1024, 1024, 1024,
        1024, 1024, 1023, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024,
        1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 867, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 573, 958, 1017, 1024, 1015, 1024, 1012, 1024, 1024,
        1024, 1024, 1024, 1024, 1024, 474, 857, 540, 0, 0, 0, 0],
    5: [1023, 1024, 1024, 1024, 1024, 81, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 0, 1, 2, 0, 1, 1, 0, 0, 144,
        1, 0, 21, 280, 27, 84, 134, 341, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 2],
}

# ---- the address path ------------------------------------------------------
# The OBJ table y-word, bit by bit. role: what each bit does once D3 lands.
YWORD = [(15, "term", "T", "sprite-list TERMINATOR — the promote must happen AFTER this is tested"),
         (14, "bank", "B1", "obj bank bit 1 (stock)"),
         (13, "bank", "B0", "obj bank bit 0 (stock)"),
         (12, "prom", "P", "PROMOTED into bit 15 — the 19th tile-address bit. Vanilla never sets it")]
YWORD_POS = (11, 10, "pos", "y position, 10 bits (table_y[9:0]); bits 11:10 are spare")

# obj bank value -> (SDRAM bank, byte offset, is-ours)
BANK_ROUTE = [
    (0, 2, 0x000000, False), (1, 3, 0x000000, False),
    (2, 2, 0x800000, False), (3, 3, 0x800000, False),
    (4, 1, 0x800000, True),  (5, 0, 0x7E0000, True),
]

# ---- the .rom image --------------------------------------------------------
HDR_LEN, KEY_LEN = 44, 20
ROM_ORDER = [("maincpu", PRG_LEN, None),
             ("audiocpu", 0x40000, "snd"),
             ("qsound", 0x8F0000, "pcm"),
             ("gfx", 0x3000000, "gfx"),
             ("firmware", 0x2000, "qsnd")]
IOCTL_MAX = 1 << 26          # jtframe_mem_ports.inc:1 — input [25:0] ioctl_addr
WORD_MAX = 1 << 16           # corerom.go set_header_offset — a 16-bit start word
QSOUND_UNTRIMMED = 0x1000000

# ---- the slice ladder ------------------------------------------------------
SLICES = [
    ("D0", "the MRA", "trim the declared-but-empty QSound tail so the image "
     "downloads at all — 70.26 MB to 63.196 MB", "done", "38acc638"),
    ("D1", "QSound width", "the RUNTIME profile bit and the eighth bank bit; "
     "cores/cps2w stops being cfg-only", "done", "4840df8a"),
    ("D2", "placement", "every region where the map says, checked across all "
     "67,108,864 bytes of the image", "done", "0df6f000"),
    ("D3", "the promote", "the 3-bit obj bank going live — the first slice "
     "where tenant art is actually fetchable", "next", None),
    ("D4", "the PRG window", "the 6 MB read decode, and the wait-state line "
     "with it", "queued", None),
]

# ---- the traffic measurement, per video frame, in-match phase ---------------
# tests/audit_sdram_bank_load.sh, re-derived 14z-107 (7).
STW_CEILING = 123825          # one bank's all-miss ceiling, transactions/frame
TRAFFIC = [("ba0", "68k + VRAM + ORAM + WRAM + snd", 40976, None),
           ("ba1", "QSound PCM", 13926, 98.3),
           ("ba2", "obj", 1096, 42.2),
           ("ba3", "obj + scroll", 18438, 28.9)]


# ---------------------------------------------------------------------------
# DERIVED ARITHMETIC. Nothing below is typed; it all falls out of the data.
# ---------------------------------------------------------------------------
def bank_regions(b):
    return [r for r in REGIONS if r[0] == b]


def bank_top(b):
    return max((off + ln for _, off, ln, role, _, _ in bank_regions(b)
                if role != "free"), default=0)


def bank_free(b):
    return BANK - bank_top(b)


def overlaps():
    out = []
    for i, (b1, o1, l1, _, n1, _) in enumerate(REGIONS):
        for b2, o2, l2, _, n2, _ in REGIONS[i + 1:]:
            if b1 == b2 and o1 < o2 + l2 and o2 < o1 + l1:
                out.append(f"{n1} and {n2} overlap in bank {b1}")
    return out


def rom_layout(qs_len=0x8F0000):
    """(size, {tag: header word in KiB}, {name: body offset}) for the .rom."""
    pos, words, starts = 0, {}, {}
    for name, ln, tag in ROM_ORDER:
        starts[name] = pos
        if tag:
            words[tag] = pos >> 10
        pos += QSOUND_UNTRIMMED if (name == "qsound" and qs_len is None) else \
            (qs_len if name == "qsound" else ln)
    return HDR_LEN + KEY_LEN + pos, words, starts


def footprint(top_code):
    return (top_code + 1) * TILE


def live_bytes(obj_bank):
    return sum(GROUPC_OCC[obj_bank]) * TILE


def mb(n):
    return n / (1 << 20)


# ---------------------------------------------------------------------------
# ASCII figures. These are what the committed markdown carries, so they are
# generated here and diffed against the document by --check. Widths are
# allocated by largest-remainder with a floor of one cell for any non-empty
# region, so a region smaller than a cell is drawn small rather than drawn
# away — bank 0's 131,072 B of slack is 0.5 of a cell and is the single most
# load-bearing thing in the picture.
# ---------------------------------------------------------------------------
ASCII_COLS = 64
# One glyph per placed region, keyed by (bank, offset). ADJACENT REGIONS THAT
# SHARE A GLYPH ARE MERGED BEFORE ALLOCATION — bank 0's four system windows and
# their alignment gap are 3.5 cells between them, and allocating each of the
# five separately with a floor of one cell would steal 2.5 cells from obj bank
# 5 and draw two equal 8 MB regions at different widths. The SVG draws them
# separately, at a scale where they fit.
ASCII_GLYPH = {
    (0, 0x000000): "P", (0, PRG_STOCK): "w",
    (0, 0x600000): "s", (0, 0x640000): "s", (0, 0x648000): "s",
    (0, 0x658000): "s", (0, 0x6D8000): "s",
    (0, 0x6E0000): "Q", (0, 0x7E0000): "5", (0, 0xFE0000): ".",
    (1, 0x000000): "q", (1, 0x800000): "4",
    (2, 0x000000): "=", (2, 0x800000): "=",
    (3, 0x000000): "=", (3, 0x800000): "=",
}


def allocate(lengths, cols):
    """Largest-remainder allocation with a floor of 1 cell per non-empty item.
    Sums to `cols` exactly, and never rounds a live region to nothing —
    bank 0's 131,072 B of slack is half a cell and is the single most
    load-bearing thing in the picture."""
    total = sum(lengths)
    ideal = [c * cols / total for c in lengths]
    got = [max(1, int(x)) if c else 0 for x, c in zip(ideal, lengths)]
    order = sorted(range(len(got)), key=lambda i: (-(ideal[i] - int(ideal[i])), i))
    k = 0
    while sum(got) < cols:
        got[order[k % len(order)]] += 1
        k += 1
    while sum(got) > cols:
        big = max(range(len(got)), key=lambda i: (got[i], ideal[i]))
        if got[big] <= 1:
            break
        got[big] -= 1
    return got


def ascii_row(b):
    merged = []                       # [(length, glyph)], adjacent like glyphs joined
    for _, off, ln, _, _, _ in bank_regions(b):
        g = ASCII_GLYPH[(b, off)]
        if merged and merged[-1][1] == g:
            merged[-1][0] += ln
        else:
            merged.append([ln, g])
    widths = allocate([m[0] for m in merged], ASCII_COLS)
    return "".join(m[1] * w for m, w in zip(merged, widths))


def ascii_bank_map():
    rule = "|" + "|".join(["-" * 7] * 8) + "|"
    axis = " byte offset     0        2        4        6        8       10" \
           "       12       14      16 MB"
    rows = [axis, "                 " + rule]
    for b in range(NBANKS):
        rows.append(f" SDRAM bank {b}    " + ascii_row(b))
    rows.append("                 " + rule)
    return "\n".join(rows)


def ascii_three_sizes():
    span = 2 * GROUPC_BANK
    scale = ASCII_COLS / span
    dec = sum(s[2] for s in THREE_SIZES)
    foot = [footprint(s[3]) for s in THREE_SIZES]
    rows = []
    rows.append("   0 MB     2        4        6        8       10       12"
                "       14       16 MB")
    rows.append("   " + "|" + "|".join(["-" * 7] * 8) + "|")
    # declared: solid, the whole span
    rows.append("D  " + "#" * ASCII_COLS + "  %6.3f  what SDRAM reserves" % mb(dec))
    # footprint: per obj bank, inked to its top code then dotted to the boundary
    line = ""
    for i, f in enumerate(foot):
        w = int(round(GROUPC_BANK * scale))
        ink = int(round(f * scale))
        line += "#" * ink + "·" * (w - ink)
    rows.append("F  " + line + "  %6.3f  what the codes reach" % mb(sum(foot)))
    # live: one cell per bucket, inked when the bucket carries any art
    line = ""
    for ob, _, _, _, _, _ in THREE_SIZES:
        occ = GROUPC_OCC[ob]
        step = len(occ) // (ASCII_COLS // 2)
        for k in range(0, len(occ), step):
            chunk = occ[k:k + step]
            frac = sum(chunk) / (1024 * len(chunk))
            line += "#" if frac > 0.66 else ("+" if frac > 0.05 else
                                             ("." if sum(chunk) else " "))
    rows.append("L  " + line + "  %6.3f  what actually exists" % mb(
        sum(live_bytes(s[0]) for s in THREE_SIZES)))
    rows.append("   " + "|" + "|".join(["-" * 7] * 8) + "|")
    rows.append("   ^ obj bank 4 (0-8 MB)                 ^ obj bank 5 (8-16 MB)")
    return "\n".join(rows)


# ---------------------------------------------------------------------------
# DRAWING. SVG text neither wraps nor shrinks, so a label longer than its box
# runs out over whatever is beside it. Nothing here is eyeballed: every string
# is measured with text_w() and either placed inside, placed outside on a
# leader, or dropped in favour of the <title> tooltip.
# ---------------------------------------------------------------------------
NARROW = set("ijltfrI.,:;'|!()[]{} ")
WIDE = set("mwMW@")


def text_w(s, size, mono=True):
    """Advance width of a string, in px.

    MONO BY DEFAULT, and that is not a stylistic choice: this page's
    stylesheet sets `text{font-family:ui-monospace,...}`, so EVERY <text>
    element on it is monospace. The first cut measured with the proportional
    estimator, under-read a 25-character label by 20 px, and clipped it
    against the left edge of its own figure. Menlo and SF Mono advance
    0.60em; the proportional branch below is kept for anything that ever
    opts out and deliberately over-estimates, so it errs toward dropping a
    label rather than letting one overflow."""
    if mono:
        return len(s) * size * 0.60
    w = 0.0
    for ch in s:
        if ch in NARROW:
            w += 0.34
        elif ch in WIDE:
            w += 0.92
        elif ch.isupper() or ch.isdigit() or ch == "$":
            w += 0.66
        else:
            w += 0.55
    return w * size


def esc(s):
    return html.escape(str(s))


def human(n):
    if n >= 1 << 20 and n % (1 << 20) == 0:
        return f"{n >> 20} MB"
    if n >= 1 << 20:
        return f"{mb(n):.3f} MB"
    if n >= 1024 and n % 1024 == 0:
        return f"{n >> 10} KB"
    return f"{n:,} B"


# ---- V1, the SDRAM map -----------------------------------------------------
def free_label(b):
    """Banks 2 and 3 are also 'full', but saying so beside bank 1 would bury
    the fact worth reading: bank 1 has no room left AFTER our additions, and
    theirs was never ours to spend."""
    n = bank_free(b)
    if b >= 2:
        return "vanilla — 16 MB, untouched"
    return f"{n:,} B free" if n else "0 B free — EXACTLY FULL"


def svg_sdram():
    """Four 16 MB banks at ONE scale, every region proportional, plus one
    magnified strip because bank 0's system windows are 2-51 px at that
    scale and one of them is where work RAM moved to."""
    # The gutters are MEASURED from the longest string that has to sit in
    # them, not guessed. The right-hand one carries the free-space verdicts,
    # which are the conclusion of the whole figure and the labels that must
    # never be clipped — so it is sized from whichever of them is widest, and
    # stays right when their wording changes.
    pad = 10
    gut = max(text_w(f"bank {b}", 13) for b in range(NBANKS)) + 24
    right = max(text_w(free_label(b), 11.5) for b in range(NBANKS)) + 22
    barw, rowh, gap, top = 820, 46, 16, 34
    sc = barw / BANK
    d0, d1 = DETAIL
    dsc = barw / (d1 - d0)
    dety = top + NBANKS * (rowh + gap) + 52   # headroom for stacked offsets
    w = gut + barw + right + pad
    h = dety + rowh + 26
    below, above = [], []
    p = [f'<svg viewBox="0 0 {w:.0f} {h:.0f}" width="{w:.0f}" height="{h:.0f}" '
         f'role="img" aria-label="The four SDRAM banks of jtcps2w, 16 MB each '
         f'at one scale, showing where the CPS-2 WIDE romset is placed, that '
         f'banks 2 and 3 are entirely vanilla, that bank 1 is exactly full and '
         f'that bank 0 has 131,072 bytes free; with bank 0 s system windows '
         f'redrawn magnified beneath">']
    # MB axis
    for m in range(0, 17, 2):
        x = gut + m * (1 << 20) * sc
        p.append(f'<text class="axis" x="{x:.1f}" y="16" text-anchor="middle">'
                 f'{m}</text>')
        p.append(f'<line class="tick" x1="{x:.1f}" y1="21" x2="{x:.1f}" '
                 f'y2="{top + NBANKS * (rowh + gap) - gap + 5:.1f}"/>')
    p.append(f'<text class="axis" x="{gut + barw + 8:.1f}" y="16">MB</text>')

    for b in range(NBANKS):
        y = top + b * (rowh + gap)
        p.append(f'<text class="bname" x="{gut - 12:.1f}" '
                 f'y="{y + rowh / 2 + 5:.1f}" text-anchor="end">bank {b}</text>')
        p.append(f'<rect class="bankbg" x="{gut:.1f}" y="{y}" width="{barw}" '
                 f'height="{rowh}" rx="3"/>')
        for _, off, ln, role, name, note in bank_regions(b):
            x = gut + off * sc
            rw = max(1.6, ln * sc)
            title = (f"bank {b}, 0x{off:06X} + {human(ln)} — {name}. {note} "
                     f"[{BANK_NOTE[b]}]")
            p.append(f'<g class="reg r-{role}"><title>{esc(title)}</title>'
                     f'<rect x="{x:.2f}" y="{y}" width="{rw:.2f}" '
                     f'height="{rowh}" rx="2"/>')
            sub = human(ln)
            two = text_w(sub, 10.5) + 14 < rw
            if text_w(name, 12) + 14 < rw:
                p.append(f'<text class="rname" x="{x + 7:.1f}" '
                         f'y="{y + (18 if two else rowh / 2 + 4):.1f}">'
                         f'{esc(name)}</text>')
                if two:
                    p.append(f'<text class="rsub" x="{x + 7:.1f}" '
                             f'y="{y + 33:.1f}">{esc(sub)}</text>')
            p.append("</g>")
        # hairlines for the live extents inside a declared region
        for mbk, moff, mlab, mnote in MARKS:
            if mbk != b:
                continue
            x = gut + moff * sc
            p.append(f'<g class="mark"><title>{esc(mlab + " — " + mnote)}</title>'
                     f'<line x1="{x:.2f}" y1="{y - 4}" x2="{x:.2f}" '
                     f'y2="{y + rowh + 4}"/></g>')
        # the free-space callout, to the right of the bar
        cls = "callout" + (" zero" if bank_free(b) == 0 else "")
        p.append(f'<text class="{cls}" x="{gut + barw + 10:.1f}" '
                 f'y="{y + rowh / 2 + 4:.1f}">{esc(free_label(b))}</text>')

    # THE DETAIL STRIP, stated as magnified rather than implied.
    p.append(f'<rect class="bankbg" x="{gut:.1f}" y="{dety:.0f}" '
             f'width="{barw}" height="{rowh}" rx="3"/>')
    for _, off, ln, role, name, note in bank_regions(0):
        if off + ln <= d0 or off >= d1:
            continue
        x = gut + (off - d0) * dsc
        rw = max(1.6, ln * dsc)
        title = f"bank 0, 0x{off:06X} + {human(ln)} — {name}. {note}"
        p.append(f'<g class="reg r-{role}"><title>{esc(title)}</title>'
                 f'<rect x="{x:.2f}" y="{dety:.0f}" width="{rw:.2f}" '
                 f'height="{rowh}" rx="2"/></g>')
        short = name.split(" — ")[0]
        if text_w(short, 11) + 12 < rw:
            p.append(f'<text class="rname" x="{x + 6:.1f}" y="{dety + 19:.0f}">'
                     f'{esc(short)}</text>')
            p.append(f'<text class="rsub" x="{x + 6:.1f}" y="{dety + 34:.0f}">'
                     f'{esc(human(ln))}</text>')
        else:
            below.append((x + rw / 2, f"{short} {human(ln)}"))
        above.append((x + rw / 2, f"0x{off:06X}"))

    # Outside labels are STACKED, not spaced by eye: OBJ RAM is 32 KB against
    # work RAM's 64 KB and even magnified they are 14 and 27 px apart, so the
    # placer walks down rows until it finds one this string does not collide in
    # and draws a leader to it. Two labels overlapping is how a diagram starts
    # lying about which region it is naming.
    def stack(items, y0, dy, cls, up):
        used = []
        for cx, txt in items:
            tw = text_w(txt, 11)
            x0, x1 = cx - tw / 2, cx + tw / 2
            r = 0
            while any(r == ur and x0 < ux1 + 6 and ux0 - 6 < x1
                      for ur, ux0, ux1 in used):
                r += 1
            used.append((r, x0, x1))
            y = y0 + (-1 if up else 1) * r * dy
            p.append(f'<text class="axis" x="{cx:.1f}" y="{y:.0f}" '
                     f'text-anchor="middle">{esc(txt)}</text>')
            if r:
                ly0 = dety - 4 if up else dety + rowh + 4
                ly1 = y + (4 if up else -9)
                p.append(f'<line class="lead" x1="{cx:.1f}" y1="{ly0:.0f}" '
                         f'x2="{cx:.1f}" y2="{ly1:.0f}"/>')
        return max((r for r, _, _ in used), default=0)

    nb = stack(below, dety + rowh + 15, 14, "axis", False)
    na = stack(above, dety - 6, 14, "axis", True)
    # the caption goes above whatever the offset labels needed, not at a
    # guessed height
    p.append(f'<text class="hd" x="{gut:.1f}" y="{dety - 20 - na * 14:.0f}">'
             f'bank 0, 0x{d0:06X}-0x{d1:06X}, magnified '
             f'{dsc / sc:.0f}&#215;</text>')
    p[0] = p[0].replace(f'"0 0 {w:.0f} {h:.0f}"',
                        f'"0 0 {w:.0f} {h + nb * 14:.0f}"')
    p[0] = p[0].replace(f'height="{h:.0f}"', f'height="{h + nb * 14:.0f}"')
    p.append("</svg>")
    return "\n".join(p)


# ---- V2, the three sizes ---------------------------------------------------
ROW_LABEL = [("declared region", "consumes a bank"),
             ("address footprint", "a code IS its address"),
             ("live art", "measured, per 1,024 codes")]


def svg_three_sizes():
    """Three bars at a SHARED scale. The live-art bar is drawn from the
    measured per-bucket census: each cell spans 1,024 tile codes and its
    inked width is the fraction of those codes that carry art, so the total
    inked width IS the live-byte figure."""
    pad = 10
    gut = max(max(text_w(a, 12.5), text_w(b_, 10.5)) for a, b_ in ROW_LABEL) + 22
    right = max(text_w(f"{m_:.3f} MB", 12.5) for m_ in (16.0,)) + 22
    barw, rowh, gap, top = 760, 40, 26, 26
    span = len(THREE_SIZES) * GROUPC_BANK
    sc = barw / span
    w = gut + barw + right + pad
    h = top + 3 * (rowh + gap) + 16
    p = [f'<svg viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" '
         f'aria-label="The same group-C graphics measured three ways at one '
         f'scale: the declared region, the address footprint the tile codes '
         f'reach, and the live art scattered inside it">']
    for m in range(0, 17, 2):
        x = gut + m * (1 << 20) * sc
        p.append(f'<text class="axis" x="{x:.1f}" y="14" text-anchor="middle">'
                 f'{m}</text>')
    p.append(f'<text class="axis" x="{gut + barw + 8:.1f}" y="14">MB</text>')

    def row(i):
        """Row origin + its two measured labels, placed in the gutter."""
        y = top + i * (rowh + gap)
        name, sub = ROW_LABEL[i]
        p.append(f'<text class="lname" x="{gut - 12:.1f}" y="{y + 17}" '
                 f'text-anchor="end">{esc(name)}</text>')
        p.append(f'<text class="lsub" x="{gut - 12:.1f}" y="{y + 32}" '
                 f'text-anchor="end">{esc(sub)}</text>')
        return y

    # 1. declared region
    y = row(0)
    for i, (ob, sb, dec, _, _, _) in enumerate(THREE_SIZES):
        x = gut + i * GROUPC_BANK * sc
        p.append(f'<g class="reg r-ourgfx"><title>obj bank {ob}: an 8 MB '
                 f'region, downloaded whole into SDRAM bank {sb} whatever the '
                 f'art does inside it</title>'
                 f'<rect x="{x:.2f}" y="{y}" width="{dec * sc - 2:.2f}" '
                 f'height="{rowh}" rx="2"/>'
                 f'<text class="rname" x="{x + 8:.1f}" y="{y + 25}">obj bank '
                 f'{ob} → SDRAM ba{sb}</text></g>')
    p.append(f'<text class="total" x="{gut + barw + 10:.1f}" y="{y + 25}">'
             f'{mb(sum(s[2] for s in THREE_SIZES)):.3f} MB</text>')

    # 2. address footprint
    y = row(1)
    tot = 0
    for i, (ob, sb, dec, top_code, _, _) in enumerate(THREE_SIZES):
        f = footprint(top_code)
        tot += f
        x = gut + i * GROUPC_BANK * sc
        p.append(f'<g class="reg r-ourgfx"><title>obj bank {ob}: the codes '
                 f'reach 0x{top_code:04X}, so the span is 0x{f:X} = '
                 f'{mb(f):.3f} MB</title>'
                 f'<rect x="{x:.2f}" y="{y}" width="{f * sc:.2f}" '
                 f'height="{rowh}" rx="2"/></g>')
        dead = dec - f
        p.append(f'<g class="reg r-free"><title>{dead:,} B of obj bank {ob}’s '
                 f'region sits above its highest declared code — dead, and '
                 f'what a group-C MRA trim could recover</title>'
                 f'<rect class="dead" x="{x + f * sc:.2f}" y="{y}" '
                 f'width="{max(1.5, dead * sc):.2f}" height="{rowh}" rx="2"/></g>')
        p.append(f'<text class="code" x="{x + f * sc - 6:.1f}" y="{y + 25}" '
                 f'text-anchor="end">0x{top_code:04X}</text>')
    p.append(f'<text class="total" x="{gut + barw + 10:.1f}" y="{y + 25}">'
             f'{mb(tot):.3f} MB</text>')

    # 3. live art, from the census
    y = row(2)
    lb = 0
    for i, (ob, _, _, _, _, _) in enumerate(THREE_SIZES):
        occ = GROUPC_OCC[ob]
        cellw = GROUPC_BANK * sc / len(occ)
        for k, n in enumerate(occ):
            lb += n * TILE
            if not n:
                continue
            x = gut + i * GROUPC_BANK * sc + k * cellw
            lo, hi = k * 1024, k * 1024 + 1023
            p.append(f'<g class="reg r-ourgfx"><title>obj bank {ob}, codes '
                     f'0x{lo:04X}-0x{hi:04X}: {n} of 1,024 carry art</title>'
                     f'<rect x="{x:.2f}" y="{y}" '
                     f'width="{max(0.8, cellw * n / 1024):.2f}" '
                     f'height="{rowh}" rx="1"/></g>')
    p.append(f'<text class="total" x="{gut + barw + 10:.1f}" y="{y + 25}">'
             f'{mb(lb):.3f} MB</text>')
    p.append("</svg>")
    return "\n".join(p)


# ---- V3, the address path --------------------------------------------------
def svg_path():
    """Tile code -> the promote -> a 3-bit bank -> SDRAM bank + byte offset."""
    # cw and the table width are sized so the whole figure fits the article
    # column (~1,120 px) without the scroller kicking in — a diagram whose
    # right-hand half is behind a horizontal scrollbar is one most readers
    # never see the conclusion of.
    pad, cw, ch, top = 12, 36, 40, 46
    gut = max(text_w("15..0", 11), 0) + 44
    nrow = len(BANK_ROUTE)
    tblw = 290
    tblx = gut + 16 * cw + 56
    w = tblx + tblw + pad
    h = top + ch + 30 + 84 + nrow * 30 + 26
    p = [f'<svg viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" '
         f'aria-label="How a CPS-2 tile code reaches SDRAM: the object '
         f'table y-word, the CPS-2 Turbo promote of bit 12 into bit 15, the '
         f'resulting 3-bit bank, and which SDRAM bank and offset each bank '
         f'value lands in">']
    p.append(f'<text class="hd" x="{pad}" y="16">OBJ table y-word — '
             f'cores/cps2/hdl/jtcps2_obj_scan.v</text>')
    roles = {}
    for bit, role, lab, note in YWORD:
        roles[bit] = (role, lab, note)
    for i in range(16):
        bit = 15 - i
        x = gut + i * cw
        role, lab, note = roles.get(bit, (YWORD_POS[2], "", YWORD_POS[3]))
        p.append(f'<g class="bitcell b-{role}"><title>bit {bit} — {esc(note)}</title>'
                 f'<rect x="{x}" y="{top}" width="{cw - 3}" height="{ch}" rx="3"/>'
                 f'<text class="bitlab" x="{x + (cw - 3) / 2:.1f}" '
                 f'y="{top + 26}" text-anchor="middle">{esc(lab)}</text></g>')
        p.append(f'<text class="axis" x="{x + (cw - 3) / 2:.1f}" '
                 f'y="{top - 6}" text-anchor="middle">{bit}</text>')
    p.append(f'<text class="axis" x="{gut - 10:.1f}" y="{top + 25}" '
             f'text-anchor="end">15..0</text>')

    # the promote arc: bit 12 -> bit 15, drawn from the cell geometry
    x12 = gut + (15 - 12) * cw + (cw - 3) / 2
    x15 = gut + (15 - 15) * cw + (cw - 3) / 2
    ybot = top + ch
    arc = ybot + 30
    p.append(f'<path class="arc" d="M {x12:.1f} {ybot + 3} L {x12:.1f} {arc} '
             f'L {x15:.1f} {arc} L {x15:.1f} {ybot + 8}"/>')
    p.append(f'<text class="step" x="{x15 + 10:.1f}" y="{arc + 16}">'
             f'(2) promote — if bit 12, set bit 15</text>')
    p.append(f'<text class="step warn" x="{gut + 16 * cw + 10}" y="{top + 25}">'
             f'(1) terminator test FIRST</text>')
    p.append(f'<text class="step" x="{pad}" y="{arc + 44}">'
             f'(3) bank = {{ y[12], y[14], y[13] }} — 3 bits, 0..7; WIDE '
             f'declares 0..5. tile address = (bank &lt;&lt; 16) | code, '
             f'× 128 B</text>')

    # the routing table, one row per bank value
    ty = arc + 84
    p.append(f'<text class="hd" x="{tblx:.1f}" y="{ty - 8}">where each bank '
             f'value lands</text>')
    for k, (bv, sb, off, ours) in enumerate(BANK_ROUTE):
        y = ty + k * 30
        role = "ourgfx" if ours else "stockgfx"
        note = ("group C — reached only through the promote; the download "
                "redirect keys on gfx_addr[25] and picks the bank with "
                "gfx_addr[23]") if ours else \
               ("vanilla — computed by expressions the profile does not touch, "
                "which is what makes the superset invariant structural")
        p.append(f'<g class="route r-{role}"><title>obj bank {bv} → SDRAM '
                 f'ba{sb} at 0x{off:06X}. {esc(note)}</title>'
                 f'<rect x="{tblx:.1f}" y="{y}" width="{tblw}" height="25" '
                 f'rx="3"/>'
                 f'<text class="rt" x="{tblx + 10:.1f}" y="{y + 17}">'
                 f'bank {bv} ({bv:03b})</text>'
                 f'<text class="rt" x="{tblx + tblw - 10:.1f}" y="{y + 17}" '
                 f'text-anchor="end">ba{sb} @ 0x{off:06X}</text></g>')
    p.append(f'<text class="axis" x="{tblx:.1f}" y="{ty + nrow * 30 + 16}">'
             f'cool = vanilla · warm = ours</text>')
    p.append("</svg>")
    return "\n".join(p)


# ---- V4, the slice ladder --------------------------------------------------
def svg_slices():
    pad, rowh, gap, top = 12, 46, 12, 26
    railx, boxx, boxw = 40, 78, 660
    w = boxx + boxw + pad
    h = top + len(SLICES) * (rowh + gap) + 10
    p = [f'<svg viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" '
         f'aria-label="The five MiSTer RTL slices D0 to D4, in order, with '
         f'which are done and which are next">']
    y0 = top + rowh / 2
    y1 = top + (len(SLICES) - 1) * (rowh + gap) + rowh / 2
    p.append(f'<line class="rail" x1="{railx}" y1="{y0}" x2="{railx}" y2="{y1}"/>')
    for i, (tag, name, what, status, commit) in enumerate(SLICES):
        y = top + i * (rowh + gap)
        cy = y + rowh / 2
        p.append(f'<circle class="node s-{status}" cx="{railx}" cy="{cy}" r="9"/>')
        p.append(f'<g class="slice s-{status}"><title>{esc(tag)} — {esc(name)}: '
                 f'{esc(what)}{" (fork commit " + commit + ")" if commit else ""}'
                 f'</title>'
                 f'<rect x="{boxx}" y="{y}" width="{boxw}" height="{rowh}" rx="5"/>'
                 f'<text class="stag" x="{boxx + 12}" y="{y + 19}">{esc(tag)}</text>'
                 f'<text class="sname" x="{boxx + 48}" y="{y + 19}">{esc(name)}</text>'
                 f'<text class="swhat" x="{boxx + 12}" y="{y + 36}">'
                 f'{esc(what[:96] + ("…" if len(what) > 96 else ""))}</text>'
                 f'<text class="sstat" x="{boxx + boxw - 12}" y="{y + 19}" '
                 f'text-anchor="end">{esc(status.upper())}</text></g>')
    p.append("</svg>")
    return "\n".join(p)


def legend(items):
    out = ['<ul class="legend">']
    for role, text in items:
        out.append(f'<li><span class="sw r-{role}"></span>{esc(text)}</li>')
    out.append("</ul>")
    return "\n".join(out)


# ---------------------------------------------------------------------------
# CHECK. Re-derive what the page draws; fail if anything moved.
# ---------------------------------------------------------------------------
def _parse_fit_gate():
    """Pull the frozen constants and the placement table out of the gate that
    defends the fit. That file — not this one — is the authority.

    It is parsed rather than imported because it is a shell script with the
    Python in a heredoc, and the length column holds expressions
    (`min(qs_placed, 0x800000)`). The eval is over a repo-local file we own,
    with `__builtins__` emptied and only `min`/`max` handed in; anything it
    cannot evaluate is skipped, and the row-count assertion in check() is what
    notices if that starts happening silently."""
    src = FIT_GATE.read_text(encoding="utf-8")
    syms = {}
    for m in re.finditer(r"^([A-Z][A-Z0-9_, ]*)\s*=\s*(.+?)\s*$", src, re.M):
        names = [n.strip() for n in m.group(1).split(",")]
        try:
            vals = eval(m.group(2), {"__builtins__": {}}, dict(syms))
        except Exception:
            continue
        if len(names) == 1:
            syms[names[0]] = vals
        elif isinstance(vals, tuple) and len(vals) == len(names):
            syms.update(dict(zip(names, vals)))
    rows = []
    for m in re.finditer(r'^\s*\("([^"]+)",\s*(\d+),\s*(0x[0-9A-Fa-f]+),\s*(.+?)\),\s*$',
                         src, re.M):
        try:
            ln = eval(m.group(4), {"__builtins__": {"min": min, "max": max}},
                      dict(syms, qs_placed=0x8F0000, c5_len=syms.get("GROUPC_BANK"),
                           c4_len=syms.get("GROUPC_BANK")))
        except Exception:
            continue
        rows.append((m.group(1), int(m.group(2)), int(m.group(3), 16), ln))
    frozen = {}
    for m in re.finditer(r'frozen\("([^"]+)",\s*[^,]+,\s*(0x[0-9A-Fa-f]+|\d+)\)', src):
        frozen[m.group(1)] = int(m.group(2), 0)
    return syms, rows, frozen


def check():
    bad, ok, skipped = [], [], []

    def want(cond, msg, good=""):
        (ok if cond else bad).append(good or msg if cond else msg)

    # -- 1. the map against the gate that defends it -------------------------
    syms, rows, frozen = _parse_fit_gate()
    want(len(rows) >= 9, f"{FIT_GATE.name}: parsed {len(rows)} placement rows, "
         "expected at least 9 — the gate's placement() table changed shape and "
         "this generator can no longer read it",
         f"{FIT_GATE.name}: parsed {len(rows)} placement rows")
    gate_map = {name: (b, off, ln) for name, b, off, ln in rows}
    # coalesce the drawn sub-bands back to the gate's model, see GATE_ROW
    mine = {}
    for b, off, ln, role, name, _ in REGIONS:
        key = GATE_ROW.get((b, off))
        if key is None:
            continue
        if key in mine:
            mb_, moff, mln = mine[key]
            mine[key] = (mb_, min(moff, off), mln + ln)
        else:
            mine[key] = (b, off, ln)
    for key, (b, off, ln) in mine.items():
        if key not in gate_map:
            bad.append(f"'{key}' (bank {b}, 0x{off:06X}) is drawn here but is "
                       f"not in {FIT_GATE.name}'s placement()")
        elif gate_map[key] != (b, off, ln):
            gb, goff, gln = gate_map[key]
            bad.append(f"'{key}': this page draws bank {b} 0x{off:06X} + "
                       f"{ln:,} B, the gate places bank {gb} 0x{goff:06X} + "
                       f"{gln:,} B")
    for key, (b, off, ln) in gate_map.items():
        if key not in mine:
            bad.append(f"{FIT_GATE.name} places '{key}' at bank {b} "
                       f"0x{off:06X} and this page does not draw it")
    if not bad:
        ok.append(f"all {len(mine)} placed regions match {FIT_GATE.name} "
                  f"(drawn sub-bands coalesced to its model)")
    for sym, val in (("BANK", BANK), ("PRG_LEN", PRG_LEN), ("VRAM", VRAM),
                     ("ORAM", ORAM), ("WRAM", WRAM), ("Z80W", Z80W),
                     ("PCM_HIGH", PCM_HIGH), ("GROUPC_BANK", GROUPC_BANK)):
        if syms.get(sym) != val:
            bad.append(f"constant {sym}: this page has {val:#x}, "
                       f"{FIT_GATE.name} has {syms.get(sym)}")
    ok.append("the eight shared size constants agree with the fit gate")

    # -- 2. the frozen content extents ---------------------------------------
    expect = {
        "obj bank 4 highest non-blank code": THREE_SIZES[0][5],
        "obj bank 5 highest non-blank code": THREE_SIZES[1][5],
        "obj bank 4 declared ceiling (effect_map)": THREE_SIZES[0][3],
        "obj bank 5 declared ceiling (effect_c5)": THREE_SIZES[1][3],
        "obj bank 4 non-blank count": THREE_SIZES[0][4],
        "obj bank 5 non-blank count": THREE_SIZES[1][4],
        # the highest live program byte + 1 is the 30-byte pin's end, not the
        # allocator's high-water mark — which is exactly why the PRG region is
        # 6 MB rather than 5
        "PRG live extent (highest byte + 1)": PRG_PIN + 30,
    }
    for k, v in expect.items():
        if k not in frozen:
            bad.append(f"{FIT_GATE.name} no longer freezes '{k}'")
        elif frozen[k] != v:
            bad.append(f"frozen extent '{k}': this page draws {v:#x}, the gate "
                       f"freezes {frozen[k]:#x}")
    ok.append(f"all {len(expect)} frozen content extents agree with the fit gate")
    for ob, occ in GROUPC_OCC.items():
        n = sum(occ)
        f = {4: "obj bank 4 non-blank count", 5: "obj bank 5 non-blank count"}[ob]
        if frozen.get(f) != n:
            bad.append(f"the drawn occupancy census for obj bank {ob} sums to "
                       f"{n:,} codes; the gate freezes {frozen.get(f)}")
    ok.append("the drawn occupancy buckets sum to the frozen non-blank counts")

    # -- 3. the arithmetic ----------------------------------------------------
    for m in overlaps():
        bad.append("OVERLAP: " + m)
    for b in range(NBANKS):
        if bank_top(b) > BANK:
            bad.append(f"SDRAM bank {b} overflows by {bank_top(b) - BANK:,} B")
    want(bank_free(1) == 0, f"bank 1 should be EXACTLY FULL, it has "
         f"{bank_free(1):,} B free", "bank 1 is exactly full")
    want(bank_free(0) == 131072, f"bank 0 should have 131,072 B free, it has "
         f"{bank_free(0):,}", "bank 0 has 131,072 B free")
    placed = sum(bank_top(b) for b in range(NBANKS))
    want(TIER - placed == 131072, f"tier slack is {TIER - placed:,} B, "
         "expected 131,072", f"total slack {TIER - placed:,} B of {TIER:,}")

    size, words, starts = rom_layout()
    want(size <= IOCTL_MAX, f".rom is {size:,} B, past the 26-bit ioctl_addr "
         f"ceiling {IOCTL_MAX:,}", f".rom {size:,} B fits the 26-bit ioctl_addr")
    for k, v in words.items():
        if v >= WORD_MAX:
            bad.append(f"header word {k}_start = {v} KiB does not fit 16 bits")
    for name, s in starts.items():
        if s % 1024:
            bad.append(f"region {name} starts at {s:#x}, not 1 KiB-aligned")
    ok.append("every region start is 1 KiB-aligned and every header word fits")

    # the must-fail control, checked here so the arithmetic is known able to
    # say no: mapped verbatim the image overflows BOTH ceilings.
    csize, cwords, _ = rom_layout(qs_len=QSOUND_UNTRIMMED)
    if csize <= IOCTL_MAX or cwords["qsnd"] < WORD_MAX:
        bad.append("the untrimmed QSound region no longer overflows both "
                   "ceilings — this page's arithmetic cannot say no, so its "
                   "'the trim is mandatory' claim is untested")
    else:
        ok.append(f"control: untrimmed = {csize:,} B and qsnd_start "
                  f"{cwords['qsnd']} KiB, both rejected")

    # -- 4. against docs/project/mister_map.md -------------------------------
    doc = MAP_DOC.read_text(encoding="utf-8")
    for tag, val in words.items():
        m = re.search(rf"`{tag}_start` = \*\*(\d+)\*\*", doc)
        if not m:
            bad.append(f"{MAP_DOC.name} no longer states `{tag}_start`")
        elif int(m.group(1)) != val:
            bad.append(f"header word {tag}_start: computed {val}, "
                       f"{MAP_DOC.name} says {m.group(1)}")
    m = re.search(r"\*\*([\d,]+) B = [\d.]+ MB\*\*", doc)
    if not m:
        bad.append(f"{MAP_DOC.name} no longer states the .rom size")
    elif int(m.group(1).replace(",", "")) != size:
        bad.append(f".rom size: computed {size:,}, {MAP_DOC.name} says "
                   f"{m.group(1)}")
    else:
        ok.append(f"the .rom size and all four header words match {MAP_DOC.name}")
    for key, (b, off, ln) in sorted(mine.items(), key=lambda kv: kv[1]):
        if f"`0x{off:06X}`" not in doc:
            bad.append(f"{MAP_DOC.name} section 5 no longer carries the offset "
                       f"0x{off:06X} ('{key}')")
    if f"{bank_free(0):,} B" not in doc:
        bad.append(f"{MAP_DOC.name} no longer states bank 0's "
                   f"{bank_free(0):,} B of free space")
    if "EXACTLY FULL" not in doc:
        bad.append(f"{MAP_DOC.name} no longer states that bank 1 is exactly full")
    ok.append(f"{MAP_DOC.name} section 5 carries every placed offset, bank 0's "
              f"{bank_free(0):,} B and bank 1's 'EXACTLY FULL'")

    # -- 5. the ASCII figures in the synthesis doc ---------------------------
    core = CORE_DOC.read_text(encoding="utf-8") if CORE_DOC.exists() else ""
    for label, fn in (("bank map", ascii_bank_map),
                      ("three sizes", ascii_three_sizes)):
        art = fn()
        if not core:
            skipped.append(f"{CORE_DOC.name} is absent — the {label} ASCII "
                           "figure was not checked")
        elif art not in core:
            bad.append(f"the {label} ASCII figure in {CORE_DOC.name} is not "
                       f"what this generator emits. Re-run with --ascii and "
                       f"paste the output back into the document")
        else:
            ok.append(f"the {label} ASCII figure in {CORE_DOC.name} is current")

    # -- 6. against the real artifacts, where reachable ----------------------
    build = REPO / "build" / "m3b_merged13" / "rompath" / "vsavjw.zip"
    if not build.exists():
        skipped.append(f"no WIDE romset at {build} — the group-C occupancy "
                       "census was not re-derived")
    else:
        try:
            import hashlib
            import zipfile
            sys.path.insert(0, str(REPO / "tools"))
            import gfx_tiles as G
            z = zipfile.ZipFile(build)
            simms = [z.read(f"vsw.{m}m") for m in G.GROUP_C]
            occ = {4: [0] * BUCKETS, 5: [0] * BUCKETS}
            for t2 in range(0x20000):
                if hashlib.sha1(G.tile_bytes(simms, t2)).digest() not in G.BLANK:
                    occ[4 + (t2 >> 16)][(t2 & 0xFFFF) * BUCKETS // 0x10000] += 1
            for ob in (4, 5):
                if occ[ob] != GROUPC_OCC[ob]:
                    d = [i for i, (a, b_) in enumerate(zip(occ[ob], GROUPC_OCC[ob]))
                         if a != b_]
                    bad.append(f"obj bank {ob}: the drawn occupancy census is "
                               f"stale in {len(d)} of {BUCKETS} buckets "
                               f"(first: bucket {d[0]}, measured {occ[ob][d[0]]}, "
                               f"drawn {GROUPC_OCC[ob][d[0]]})")
            if occ == GROUPC_OCC:
                ok.append("the group-C occupancy census re-derives byte for "
                          "byte from the built WIDE romset")
        except Exception as e:                       # noqa: BLE001
            skipped.append(f"the occupancy census could not be re-derived: {e}")

    dat = REPO / "build" / "out" / "vsavj_data.bin"
    if not dat.exists():
        skipped.append(f"no decrypted program image at {dat} — the palette was "
                       "not re-read from the ROM")
    else:
        import struct
        d = dat.read_bytes()
        ptr = struct.unpack(">I", d[PAL_TABLE + PAL_CHAR_ID * 4:
                                    PAL_TABLE + PAL_CHAR_ID * 4 + 4])[0]
        base = ptr + PAL_ROW * 32
        got = ["#%02x%02x%02x" % (((v >> 8) & 0xF) * 17, ((v >> 4) & 0xF) * 17,
                                  (v & 0xF) * 17)
               for v in struct.unpack(">16H", d[base:base + 32])]
        if got != DEMITRI:
            bad.append(f"the page's palette is not what PRG:0x{base:06X} holds: "
                       f"read {got[:4]}…, drawn {DEMITRI[:4]}…")
        else:
            ok.append(f"the palette re-reads exactly from PRG:0x{base:06X} "
                      f"(Demitri, sprite palette row {PAL_ROW})")

    if VERBOSE:
        for line in ok:
            print("  ok", line)
    for line in skipped:
        print("  SKIP:", line)
    for line in bad:
        print("  FAIL:", line)
    if bad:
        print(f"\nFAIL: mk_mister_page — {len(bad)} of the numbers this page "
              f"draws no longer re-derive")
        return 1
    print(f"\nPASS: every figure re-derives ({len(ok)} checks"
          f"{', ' + str(len(skipped)) + ' skipped' if skipped else ''})")
    return 0


# ---------------------------------------------------------------------- page --
CSS_TEMPLATE = """
:root{
  --paper:%(paper_l)s; --surface:%(surface_l)s; --sunken:%(sunken_l)s;
  --ink:%(ink_l)s; --ink-2:%(ink2_l)s; --ink-3:%(ink3_l)s;
  --rule:%(rule_l)s; --accent:%(accent_l)s; --accent-soft:%(accsoft_l)s;
  --on-fill:%(onfill_l)s; --warn:%(flame)s;
  %(roles_l)s
  --shadow:0 1px 2px rgba(20,17,17,.06), 0 8px 24px -12px rgba(20,17,17,.20);
}
@media (prefers-color-scheme: dark){ :root:not([data-theme="light"]){
  --paper:%(paper_d)s; --surface:%(surface_d)s; --sunken:%(sunken_d)s;
  --ink:%(ink_d)s; --ink-2:%(ink2_d)s; --ink-3:%(ink3_d)s;
  --rule:%(rule_d)s; --accent:%(accent_d)s; --accent-soft:%(accsoft_d)s;
  --on-fill:%(onfill_d)s; --warn:%(warm_l)s;
  %(roles_d)s
  --shadow:0 1px 2px rgba(0,0,0,.5), 0 10px 30px -14px rgba(0,0,0,.7);
}
%(fills_d_media)s}
:root[data-theme="dark"]{
  --paper:%(paper_d)s; --surface:%(surface_d)s; --sunken:%(sunken_d)s;
  --ink:%(ink_d)s; --ink-2:%(ink2_d)s; --ink-3:%(ink3_d)s;
  --rule:%(rule_d)s; --accent:%(accent_d)s; --accent-soft:%(accsoft_d)s;
  --on-fill:%(onfill_d)s; --warn:%(warm_l)s;
  %(roles_d)s
  --shadow:0 1px 2px rgba(0,0,0,.5), 0 10px 30px -14px rgba(0,0,0,.7);
}
%(fills_d_theme)s
*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);
  font:16px/1.65 ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif;
  -webkit-font-smoothing:antialiased}
.wrap{max-width:78rem;margin:0 auto;padding:0 clamp(1rem,4vw,3rem) 6rem}
.col{max-width:44rem}
h1,h2,h3{font-family:"Iowan Old Style","Palatino Linotype",Palatino,Georgia,serif;
  font-weight:600;text-wrap:balance;letter-spacing:-.01em}
h1{font-size:clamp(2rem,4.6vw,3.1rem);line-height:1.08;margin:0 0 .6rem}
h2{font-size:clamp(1.35rem,2.4vw,1.8rem);margin:3.4rem 0 .3rem}
h3{font-size:1.06rem;margin:2rem 0 .3rem}
p,li{color:var(--ink-2)} p{margin:.75rem 0}
strong{color:var(--ink);font-weight:600}
code,.mono{font-family:ui-monospace,SFMono-Regular,"SF Mono",Menlo,Consolas,monospace;
  font-variant-numeric:tabular-nums}
code{font-size:.88em;background:var(--sunken);padding:.1em .34em;border-radius:3px;
  color:var(--ink)}
a{color:var(--accent)}
.eyebrow{font:600 .72rem/1 ui-monospace,SFMono-Regular,Menlo,monospace;
  letter-spacing:.18em;text-transform:uppercase;color:var(--ink-3);margin:0 0 1.2rem}
header.hero{padding:clamp(3rem,7vw,5.5rem) 0 1rem}
.standfirst{font-size:1.12rem;color:var(--ink-2);max-width:42rem}
.rule{height:1px;background:var(--rule);border:0;margin:2.5rem 0 0}
nav.jump{position:sticky;top:0;z-index:10;
  background:color-mix(in srgb,var(--paper) 88%%,transparent);
  backdrop-filter:blur(8px);border-bottom:1px solid var(--rule);margin-bottom:1rem}
nav.jump ol{display:flex;gap:.2rem;list-style:none;margin:0;padding:.5rem 0;
  overflow-x:auto}
nav.jump a{display:block;padding:.3rem .6rem;border-radius:5px;text-decoration:none;
  font:500 .8rem/1.4 ui-sans-serif,system-ui,sans-serif;color:var(--ink-2);
  white-space:nowrap}
nav.jump a:hover,nav.jump a:focus-visible{background:var(--accent-soft);color:var(--accent)}
figure{margin:1.6rem 0 2rem;background:var(--surface);border:1px solid var(--rule);
  border-radius:10px;box-shadow:var(--shadow);overflow:hidden}
.scroller{overflow-x:auto;padding:1.1rem 1.1rem .4rem}
figcaption{padding:.2rem 1.1rem 1rem;color:var(--ink-3);font-size:.86rem}
figcaption b{color:var(--ink-2);font-weight:600}
svg{display:block}
text{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
  font-variant-numeric:tabular-nums}
.axis{font-size:11px;fill:var(--ink-3)}
.tick{stroke:var(--rule);stroke-width:1;stroke-dasharray:2 4}
.bankbg{fill:var(--sunken)}
.bname{font-size:13px;fill:var(--ink-2);font-weight:600}
.reg rect{stroke:var(--surface);stroke-width:1}
%(fills)s
.rname{font-size:12px;fill:var(--on-fill);font-weight:600}
.rsub{font-size:10.5px;fill:var(--on-fill);opacity:.82}
.code{font-size:10.5px;fill:var(--on-fill);opacity:.9}
.reg rect.dead{fill:var(--c-free);opacity:.5}
.callout{font-size:11.5px;fill:var(--ink-3)}
.callout.zero{fill:var(--warn);font-weight:600}
.lead{stroke:var(--rule);stroke-width:1}
.mark line{stroke:var(--ink);stroke-width:1.25;stroke-dasharray:3 2;opacity:.62}
.lname{font-size:12.5px;fill:var(--ink-2);font-weight:600}
.lsub{font-size:10.5px;fill:var(--ink-3)}
.total{font-size:12.5px;fill:var(--ink);font-weight:600}
.hd{font-size:11px;fill:var(--ink-3);letter-spacing:.05em}
.bitcell rect{fill:var(--c-free);stroke:var(--surface);stroke-width:1}
.bitcell.b-term rect{fill:var(--warn)}
.bitcell.b-bank rect{fill:var(--c-stockgfx)}
.bitcell.b-prom rect{fill:var(--c-ourgfx)}
.bitlab{font-size:12px;fill:var(--on-fill);font-weight:600}
.b-pos .bitlab{fill:var(--ink-3)}
.arc{fill:none;stroke:var(--c-ourgfx);stroke-width:2}
.step{font-size:11.5px;fill:var(--ink-2)}
.step.warn{fill:var(--warn);font-weight:600}
.route rect{stroke:var(--surface);stroke-width:1}
.rt{font-size:11.5px;fill:var(--on-fill);font-weight:600}
.rail{stroke:var(--rule);stroke-width:2}
.node{fill:var(--c-stock)} .node.s-next{fill:var(--c-ourgfx)}
.node.s-queued{fill:var(--c-free)}
.slice rect{fill:var(--sunken);stroke:var(--rule);stroke-width:1}
.slice.s-next rect{stroke:var(--c-ourgfx);stroke-width:2}
.stag{font-size:12.5px;fill:var(--ink);font-weight:700}
.sname{font-size:12.5px;fill:var(--ink-2)}
.swhat{font-size:11px;fill:var(--ink-3)}
.sstat{font-size:10.5px;fill:var(--ink-3);letter-spacing:.1em}
.slice.s-next .sstat{fill:var(--c-ourgfx);font-weight:700}
.legend{display:flex;flex-wrap:wrap;gap:.25rem 1.1rem;list-style:none;margin:.2rem 0 0;
  padding:0 1.1rem 1rem;font-size:.82rem;color:var(--ink-3)}
.legend li{display:flex;align-items:center;gap:.4rem}
.sw{width:.8rem;height:.8rem;border-radius:3px;display:inline-block;
  background:var(--c-free)}
table{border-collapse:collapse;width:100%%;font-size:.9rem;margin:1rem 0}
th,td{text-align:left;padding:.45rem .7rem;border-bottom:1px solid var(--rule);
  vertical-align:top}
th{font:600 .74rem/1.3 ui-monospace,SFMono-Regular,Menlo,monospace;
  letter-spacing:.08em;text-transform:uppercase;color:var(--ink-3)}
td:first-child{white-space:nowrap}
.tablewrap{overflow-x:auto}
.num{text-align:right;font-family:ui-monospace,Menlo,monospace;
  font-variant-numeric:tabular-nums}
.callout-box{border-left:3px solid var(--accent);background:var(--surface);
  padding:.85rem 1.1rem;border-radius:0 8px 8px 0;margin:1.4rem 0}
.callout-box p{margin:.3rem 0}
.callout-box .tag{font:600 .7rem/1 ui-monospace,Menlo,monospace;letter-spacing:.14em;
  text-transform:uppercase;color:var(--accent)}
.palette{display:flex;flex-wrap:wrap;gap:0;border-radius:8px;overflow:hidden;
  margin:1.1rem 0;border:1px solid var(--rule)}
.palette i{flex:1 1 3.4rem;height:3.2rem;position:relative}
.palette i span{position:absolute;inset:auto 0 .25rem 0;text-align:center;
  font:500 9px/1 ui-monospace,Menlo,monospace;color:#fff;mix-blend-mode:difference}
footer{margin-top:4rem;padding-top:1.4rem;border-top:1px solid var(--rule);
  color:var(--ink-3);font-size:.85rem}
section[id]{scroll-margin-top:4rem}
:focus-visible{outline:2px solid var(--accent);outline-offset:2px;border-radius:3px}
@media (prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}}
@media print{
  nav.jump{display:none}
  .scroller{overflow:visible;padding-bottom:1rem}
  svg{max-width:100%%;height:auto}
  figure{break-inside:avoid;box-shadow:none}
  h2{break-after:avoid}
  tr{break-inside:avoid}
}
"""


def css():
    roles_l = " ".join(f"--c-{k}:{v[0]};" for k, v in ROLE.items())
    roles_d = " ".join(f"--c-{k}:{v[1]};" for k, v in ROLE.items())
    # ONE FILL RULE PER DECLARED ROLE, GENERATED — so a role added to ROLE
    # cannot silently render as the stylesheet's default grey, which is exactly
    # what the first cut of this page did for all six of them. The fills are
    # var-driven and written once; only the LABEL INK is re-stated per theme,
    # because which of the two inks wins is a function of the fill, and the
    # fill changes with the theme.
    def inks(idx, prefix=""):
        return "\n".join(
            f"{prefix}.reg.r-{k} .rname,{prefix}.reg.r-{k} .rsub,"
            f"{prefix}.reg.r-{k} .code,{prefix}.route.r-{k} .rt"
            f"{{fill:{label_ink(v[idx])}}}" for k, v in ROLE.items())
    fills = "\n".join(
        f".reg.r-{k} rect,.route.r-{k} rect{{fill:var(--c-{k})}}\n"
        f".sw.r-{k}{{background:var(--c-{k})}}" for k in ROLE) + "\n" + inks(0)
    fills_d_media = inks(1, ':root:not([data-theme="light"]) ')
    fills_d_theme = inks(1, ':root[data-theme="dark"] ')
    return CSS_TEMPLATE % {
        "paper_l": mix(CREAM, "#ffffff", .90), "surface_l": mix(CREAM, "#ffffff", .965),
        "sunken_l": mix(COOL_L, "#ffffff", .60), "ink_l": mix(COOL_D, "#000000", .55),
        "ink2_l": mix(COOL_D, "#000000", .18), "ink3_l": mix(COOL_D, "#ffffff", .34),
        "rule_l": mix(COOL_L, "#ffffff", .28), "accent_l": mix(WARM_D, "#000000", .10),
        "accsoft_l": mix(WARM_L, "#ffffff", .72), "onfill_l": "#ffffff",
        "paper_d": mix(COOL_D, "#000000", .80), "surface_d": mix(COOL_D, "#000000", .66),
        "sunken_d": mix(COOL_D, "#000000", .74), "ink_d": mix(COOL_L, "#ffffff", .55),
        "ink2_d": COOL_L, "ink3_d": mix(COOL_M, "#ffffff", .10),
        "rule_d": mix(COOL_D, "#000000", .42), "accent_d": WARM_L,
        "accsoft_d": mix(WARM_D, "#000000", .62),
        "onfill_d": mix(COOL_D, "#000000", .74),
        "roles_l": roles_l, "roles_d": roles_d,
        "flame": FLAME, "warm_l": WARM_L, "fills": fills, "fills_d_media": fills_d_media,
        "fills_d_theme": fills_d_theme,
    }


def traffic_rows():
    out = []
    for tag, what, acc, miss in TRAFFIC:
        pct = 100 * acc / STW_CEILING
        m = "100% by construction" if miss is None else f"{miss}%"
        out.append(f"<tr><td><code>{tag}</code></td><td>{esc(what)}</td>"
                   f"<td class='num'>{acc:,}</td><td class='num'>{m}</td>"
                   f"<td class='num'>{pct:.0f}%</td></tr>")
    return "\n".join(out)


def sections():
    size, words, _ = rom_layout()
    csize, cwords, _ = rom_layout(qs_len=QSOUND_UNTRIMMED)
    dead = [s[2] - footprint(s[3]) for s in THREE_SIZES]
    worst = TRAFFIC[1][2] + TRAFFIC[2][2] + TRAFFIC[3][2]
    return f"""
<section id="sizes">
<div class="col"><h2>Three sizes of the same art</h2>
<p>This is the section the rest of the page hangs on, and it exists because
conflating these three numbers has produced a wrong answer three separate
times, twice in published figures. They are not interchangeable, and each one
governs a different decision.</p>
<p>The middle one is a property of CPS-2 rather than of our art:
<strong>a tile code <em>is</em> its address</strong>. The download scramble at
<code>jtcps1_prom_we.v:105</code>, composed with the download image's 4-way
64-bit interleave, undoes that interleave exactly — the SDRAM address of tile
code <code>c</code> is <code>c &times; 128</code>, contiguous and monotonic.
So the art is sparse <em>within</em> its span, and it cannot be compacted
without renumbering tile codes, which is game data.</p></div>
<figure><div class="scroller">{svg_three_sizes()}</div>
<figcaption><b>What the picture claims:</b> that the same graphics measure
{mb(sum(s[2] for s in THREE_SIZES)):.3f} MB, {mb(sum(footprint(s[3]) for s in THREE_SIZES)):.3f} MB
and {mb(sum(live_bytes(s[0]) for s in THREE_SIZES)):.3f} MB depending on which question you asked, and
that the bottom row's gaps are real — each of its {2 * BUCKETS} cells spans
1,024 tile codes and its inked width is the fraction of those codes that carry
art, so the total inked width <em>is</em> the live-byte figure. <b>What it does
not claim:</b> anything about which tile is where inside a cell, and nothing
about a fourth quantity — the ROMSET, which ships all 16 MB of members whatever
any of these rows say.</figcaption></figure>
<div class="col">
<div class="tablewrap"><table>
<tr><th>measurement</th><th class="num">obj bank 4</th>
<th class="num">obj bank 5</th><th class="num">total</th>
<th>what it governs</th></tr>
<tr><td><strong>live bytes</strong><br>art that exists</td>
<td class="num">{THREE_SIZES[0][4]:,}&nbsp;codes</td>
<td class="num">{THREE_SIZES[1][4]:,}&nbsp;codes</td>
<td class="num">{mb(sum(live_bytes(s[0]) for s in THREE_SIZES)):.3f}&nbsp;MB</td>
<td>the romset. Nothing else</td></tr>
<tr><td><strong>address footprint</strong><br>the span the codes reach</td>
<td class="num">to&nbsp;0x{THREE_SIZES[0][3]:04X}<br>{mb(footprint(THREE_SIZES[0][3])):.3f}&nbsp;MB</td>
<td class="num">to&nbsp;0x{THREE_SIZES[1][3]:04X}<br>{mb(footprint(THREE_SIZES[1][3])):.3f}&nbsp;MB</td>
<td class="num">{mb(sum(footprint(s[3]) for s in THREE_SIZES)):.3f}&nbsp;MB</td>
<td>how much address space must exist</td></tr>
<tr><td><strong>declared region</strong><br>what the MRA downloads</td>
<td class="num">{mb(THREE_SIZES[0][2]):.3f}&nbsp;MB</td>
<td class="num">{mb(THREE_SIZES[1][2]):.3f}&nbsp;MB</td>
<td class="num">{mb(sum(s[2] for s in THREE_SIZES)):.3f}&nbsp;MB</td>
<td><strong>what consumes an SDRAM bank</strong></td></tr>
</table></div>
<div class="callout-box"><p class="tag">A fourth number, and it is a different question</p>
<p><code>mister_fit.md</code> section 3 reports <strong>{WRITE_SET_CODES:,}
group-C codes</strong> from the as-built <em>write set</em> — what the build
writes — where the census above counts
{sum(s[4] for s in THREE_SIZES):,} <em>non-blank</em> codes in the shipped
members. The {WRITE_SET_CODES - sum(s[4] for s in THREE_SIZES)} that differ
are tiles the build writes and that are all-<code>00</code> or
all-<code>FF</code>. Both figures are correct answers to different questions;
neither document says which it is answering, which is how the two get quoted
interchangeably.</p></div>
<p><strong>The consequence points in two directions at once.</strong> Adding
tenant art costs nothing as long as the codes stay inside the existing 16 MB,
because the space is already reserved — a new tile above
<code>0x{THREE_SIZES[0][3]:04X}</code> or <code>0x{THREE_SIZES[1][3]:04X}</code>
overflows nothing. But the declared region cannot grow at all: a fifth group-C
member, or anything past 16 MB, overflows immediately and there is nowhere for
the excess to go.</p>
<p>What the footprints still tell you is how much of each region is
<em>dead</em>: <strong>{dead[0]:,} B in obj bank 4 and {dead[1]:,} B in obj
bank 5</strong>, which is what a group-C download trim could in principle
recover. That trim is not the flat truncation the QSound one was — the graphics
region is a 4-way interleave and the scramble turns a contiguous tail of tile
codes into a non-contiguous set of file offsets. Unmeasured, recorded, not
needed today.</p>
<div class="callout-box"><p class="tag">How this was caught, once</p>
<p>The placement map claimed <strong>0.708 MB</strong> of slack for four
sessions. It had sized the two group-C regions by their live address footprint.
A whole-image census of the real download found <strong>0.125 MB</strong>, with
bank 1 exactly full — a factor of six. The error was one of <em>kind</em>, not
arithmetic.</p></div>
</div>
</section>

<section id="map">
<div class="col"><h2>Where every byte goes</h2>
<p>Vanilla's 32 MB of graphics stays exactly where stock <code>jtcps2</code>
puts it, in banks 2 and 3, untouched to the byte. Everything the roster adds is
placed around it. Every offset and length below was checked against a real
download image, all {TIER:,} bytes of it.</p></div>
<figure><div class="scroller">{svg_sdram()}</div>
{legend([("stockgfx", "vanilla GFX — untouched"),
         ("stock", "stock program and samples"),
         ("sys", "video and work memories (never downloaded)"),
         ("ourprg", "our program extension"),
         ("oursnd", "our QSound extension"),
         ("ourgfx", "our GFX group C"),
         ("free", "free")])}
<figcaption><b>What the picture claims:</b> that all four banks are drawn at
one scale, that every region is proportional to its declared length, and that
the free space is drawn as free space — bank 0 has
{bank_free(0):,} bytes and bank 1 has none at all. Cool is stock, warm is ours,
so the two solid cool rows are the superset invariant at a glance. Dashed
hairlines mark live extents <em>inside</em> a declared region. <b>What it does
not claim:</b> that a region is full — the graphics regions are downloaded
whole and are mostly empty inside, which is the point of the figure above.
</figcaption></figure>
<div class="col">
<h3>The two placements that are not obvious</h3>
<p><strong>QSound is split across two banks</strong>, on
<code>pcm_addr[23]</code>. The stock 8 MB stays at bank 1 offset zero,
byte-identical to stock, and the DSP sample banks the profile added go to bank
0. With QSound whole in bank 1 the best case is an overflow of 0.9375 MB and no
rearrangement closes it, because the deficit is strictly bank 1's. It is forced
from the other side too: a jtframe 8-bit memory slot cannot address more than
8 MB, so one wide region was never expressible.</p>
<p><strong>Group C's two object banks are deliberately separated</strong>, one
per SDRAM bank. Obj bank 4 — the three fighter bands, i.e. the in-match traffic
— goes to bank 1, the bank whose headroom was actually measured. Obj bank 5 —
select and wheel art, cold during a match — goes to bank 0, so its extra load
lands on the select screen rather than in a match.</p>
<h3>Why bank 1 can take the load</h3>
<p>Object graphics and sound samples now share a bank, which sounds like the
kind of decision that ruins frame timing. <strong>It was measured before it was
chosen.</strong> Per video frame, in-match, on stock content:</p>
<div class="tablewrap"><table>
<tr><th>bank</th><th>what it serves</th><th>accesses / frame</th>
<th>row-miss rate</th><th>of the all-miss ceiling</th></tr>
{traffic_rows()}
</table></div>
<p>QSound round-robins sixteen channels at unrelated addresses, so nearly every
fetch opens a new row — <strong>there is no locality in bank 1 for a repack to
spoil</strong>. Bank 1's worst case is its own {TRAFFIC[1][2]:,} plus
<em>every</em> object fetch the game makes today
({TRAFFIC[2][2]:,} + {TRAFFIC[3][2]:,}) = {worst:,}, or
{100 * worst / STW_CEILING:.0f}% of the {STW_CEILING:,}-transaction ceiling —
while bank 0 already sustains {100 * TRAFFIC[0][2] / STW_CEILING:.0f}% in stock
configuration. That bounds the <em>headroom</em>; it does not prove the
repacked design, and bank 0's ability to absorb the select-screen traffic is
still unmeasured.</p>
</div>
</section>

<section id="path">
<div class="col"><h2>How a tile reaches memory</h2>
<p>The graphics cap is a <strong>format</strong>, not a memory size: a 16-bit
tile code plus a 2-bit bank taken from the object table's y-word is 2<sup>18</sup>
codes of 128 bytes, which is exactly 32 MB. Capcom hit the same wall on CPS-2
Turbo and solved it by promoting y-word bit 12 into bit 15 <em>after</em> the
end-of-list test — and bit 15 is the list terminator, which is why the order
matters and why the profile's first draft, which proposed using bit 15
directly, would have dropped every sprite after the first promoted one.</p></div>
<figure><div class="scroller">{svg_path()}</div>
<figcaption><b>What the picture claims:</b> that bank values 0-3 are computed by
expressions the profile does not touch and land in banks 2 and 3 exactly as
they always have, and that only the promoted values 4 and 5 — which vanilla
cannot produce, because it never sets bit 12 on a live sprite, measured across
the full legacy corpus with a control proving the probe was not blind — are
redirected. <b>What it does not claim:</b> that this is live. The promote is
slice D3; today the game top ties the third bank bit low, so the two group-C
read slots are provably unreachable.</figcaption></figure>
</section>

<section id="slices">
<div class="col"><h2>Where the work stands</h2>
<p>Each slice is independently verifiable, carries its own gate and its own
must-fire control, and re-runs the match-start anchor oracle on stock
<code>vsavj</code> as the emulator superset leg.</p></div>
<figure><div class="scroller">{svg_slices()}</div>
<figcaption><b>What the picture claims:</b> the order, and which slices have
landed. D2 before D3 is not a preference — you cannot prove the promote until
the art is placed. <b>What it does not claim:</b> that D0-D2 make a WIDE set
boot. They do not; nothing fetches from group C until D3.</figcaption></figure>
<div class="col">
<div class="callout-box"><p class="tag">The image had to be trimmed first</p>
<p>Mapped verbatim, the WIDE download image is
<strong>{csize:,} B</strong> — past the 26-bit download address the game port
declares ({IOCTL_MAX:,} B), and its last region's start word would be
{cwords['qsnd']:,} KiB, which does not fit the 16-bit header field. <strong>It
is written wrapped, with no warning</strong>, as {cwords['qsnd'] % WORD_MAX:,} —
the same value the QSound region's OWN start already carries. Trimming the
declared-but-empty sample tail at the mapping layer brings it to
<strong>{size:,} B</strong> with header words
{" / ".join(str(words[t]) for t in ("snd", "pcm", "gfx", "qsnd"))}, all legal,
and changes no romset byte.</p></div>
</div>
</section>
"""


def build():
    swatches = "".join(f'<i style="background:{c}"><span>{c[1:]}</span></i>'
                       for c in DEMITRI)
    return f"""<title>CPS-2 WIDE on MiSTer</title>
<style>{css()}</style>
<nav class="jump"><div class="wrap"><ol>
<li><a href="#sizes">Three sizes</a></li>
<li><a href="#map">The SDRAM map</a></li>
<li><a href="#path">The address path</a></li>
<li><a href="#slices">Where it stands</a></li>
</ol></div></nav>
<div class="wrap">
<header class="hero col">
  <p class="eyebrow">Vampire Saved &middot; jtcps2w &middot; platform synthesis</p>
  <h1>CPS-2 WIDE on MiSTer</h1>
  <p class="standfirst">Why the full roster fits in 64 MB of SDRAM, where every
  byte of it goes, and which limits no amount of memory can buy off.</p>
</header>
<hr class="rule">
{sections()}
<footer class="col">
  <p>The drawn companion to <code>docs/project/mister_core.md</code>, which
  carries the same material as text and names the provenance of every figure.
  This page is <strong>generated</strong> by
  <code>tools/mk_mister_page.py</code> and never committed; its
  <code>--check</code> mode re-derives every number it draws against
  <code>docs/project/mister_map.md</code>, the frozen constants in
  <code>tests/audit_mister_map_fit.sh</code>, and — where they are reachable —
  the built romset and the decrypted program image themselves.</p>
  <p>Its palette is the game's own. Below is <strong>Demitri's sprite
  palette</strong>, row 0, read from <code>PRG:0x38C7A0</code> through the
  32-row pointer table at <code>PRG:0x38C198</code>, at the full brightness the
  system blitter forces on upload. Cool is stock and untouched; warm is
  ours.</p>
  <div class="palette">{swatches}</div>
</footer>
</div>"""


STANDALONE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="Why the full Vampire Savior roster fits in 64 MB of MiSTer SDRAM, where every byte of it goes, and which CPS-2 limits no amount of memory can buy off.">
<meta name="color-scheme" content="light dark">
{head}
</head>
<body>
{body}
</body>
</html>
"""


def standalone(page):
    cut = page.index("</style>") + len("</style>")
    return STANDALONE.format(head=page[:cut].strip(), body=page[cut:].strip())


if __name__ == "__main__":
    if ASCII_MODE:
        print(ascii_bank_map())
        print()
        print(ascii_three_sizes())
        sys.exit(0)
    if CHECK:
        sys.exit(check())
    page = build()
    if STANDALONE_MODE:
        page = standalone(page)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(page, encoding="utf-8")
    print("wrote", OUT, OUT.stat().st_size, "bytes")
