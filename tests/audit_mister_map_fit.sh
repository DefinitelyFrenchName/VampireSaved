#!/bin/sh
# audit_mister_map_fit.sh — the MiSTer SDRAM placement map FITS, and the four
# content extents it depends on have not moved. (14z-107 (4);
# docs/project/mister_map.md is the design this gate defends.)
#
# WHY IT EXISTS. The bank-repack map fits the 64 MB tier with **0.708 MB of
# slack**, and the fit is a function of THREE frozen content extents plus one
# structural size:
#   * group C obj bank 4's highest tile code   (Donovan's band+shelf top)
#   * group C obj bank 5's highest tile code   (the ported effect set)
#   * the QSound extension's live extent       (the M5 voice batch)
#   * the 68k PRG region                       (6 MB, pinned by the 30-byte
#                                               facing-alias thunk at 0x5FFF00)
# A tile code IS its SDRAM address on CPS-2 (the download scramble at
# jtcps1_prom_we.v:105 undoes the .rom's 4-way interleave), so ONE new tenant
# tile above the frozen ceiling silently overflows a bank. That failure would
# not appear until a MiSTer bring-up, months from the commit that caused it.
#
# THE TRAP THIS GATE ALSO CLOSES. "6.39 MB of tenant art" is a LIVE-BYTE
# count, not an address footprint; the footprint is 15.45 MB because the art
# is sparse across both group-C obj banks. Freezing the maxima is what keeps
# that distinction from being re-lost.
#
# VERDICT CONTROLS (a fit check with no control asserts nothing):
#   A. the UNTRIMMED 16 MB QSound region must overflow BOTH the 26-bit
#      ioctl_addr port and the 16-bit header start word — i.e. the arithmetic
#      is able to say no;
#   B. one extra megabyte of obj-bank-5 footprint must overflow SDRAM bank 0;
#   C. the "tile code IS its SDRAM address" identity must FAIL when the CPS-2
#      scramble is removed — otherwise the identity check is testing nothing.
#
# Static: reads the built WIDE romset + frozen manifests. No emulator, no
# build, ~5 s.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${MAP_FIT_BUILD:-build/m3b_merged13}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || {
    echo "SKIP: no WIDE romset at $BUILD/rompath/vsavjw.zip"; exit 0; }
[ -f "$BUILD/patch/effect_map.json" ] || {
    echo "SKIP: no manifests at $BUILD/patch/"; exit 0; }

python3 - "$BUILD" <<'PY'
import glob, hashlib, json, os, sys, zipfile
sys.path.insert(0, "tools")
import gfx_tiles as G

BUILD = sys.argv[1]
errs = []


def bad(m):
    print("FAIL:", m)
    errs.append(m)


def frozen(label, got, want):
    if got != want:
        bad(f"{label} = {got:#x}, frozen {want:#x} — the map's slack is "
            "0.708 MB; re-run the fit arithmetic before absorbing this")
    else:
        print(f"  ok {label} = {got:#x}")


z = zipfile.ZipFile(os.path.join(BUILD, "rompath", "vsavjw.zip"))
for m in G.GROUP_C:
    d = z.read(f"vsw.{m}m")
    print(f"  read vsw.{m}m sha1 {hashlib.sha1(d).hexdigest()}")
simms = [z.read(f"vsw.{m}m") for m in G.GROUP_C]

# ── 1. group C: non-blank census, per obj bank ─────────────────────────
live = {4: [], 5: []}
for t2 in range(0x20000):
    if hashlib.sha1(G.tile_bytes(simms, t2)).digest() not in G.BLANK:
        live[4 + (t2 >> 16)].append(t2 & 0xFFFF)
print(f"  group C obj bank 4: {len(live[4])} non-blank, max {max(live[4]):#06x}")
print(f"  group C obj bank 5: {len(live[5])} non-blank, max {max(live[5]):#06x}")
frozen("obj bank 4 non-blank count", len(live[4]), 45736)
frozen("obj bank 5 non-blank count", len(live[5]), 6245)
frozen("obj bank 4 highest non-blank code", max(live[4]), 0xEE73)
frozen("obj bank 5 highest non-blank code", max(live[5]), 0xFE41)


# ── 2. the DECLARED write set (the manifests, which may exceed the bytes) ──
def ints(o):
    if isinstance(o, list):
        for x in o:
            yield from ints(x)
    elif isinstance(o, dict):
        for v in o.values():
            yield from ints(v)
    elif isinstance(o, int):
        yield o


emax = max(ints(json.load(open(os.path.join(BUILD, "patch/effect_map.json")))))
c5 = glob.glob(os.path.join(BUILD, "patch/effect_c5*.json"))
if not c5:
    bad("no patch/effect_c5*.json — the bank-5 ceiling is unmeasurable")
c5max = max(max(ints(json.load(open(f)))) for f in c5) if c5 else 0
frozen("obj bank 4 declared ceiling (effect_map)", emax, 0xEE73)
frozen("obj bank 5 declared ceiling (effect_c5)", c5max, 0xFFDB)

FOOT4 = (emax + 1) * 128          # 0x773A00
FOOT5 = (c5max + 1) * 128         # 0x7FEE00
print(f"  footprints: obj bank 4 {FOOT4:#x} ({FOOT4/2**20:.3f} MB), "
      f"obj bank 5 {FOOT5:#x} ({FOOT5/2**20:.3f} MB)")


# ── 3. QSound live extent, and the placed length ───────────────────────
def end_nonzero(b):
    i = len(b)
    while i and b[i - 1] == 0:
        i -= 1
    return i


q21, q22 = z.read("vsw.21m"), z.read("vsw.22m")
QS_LIVE = 0x800000 + end_nonzero(q21)     # extension starts at region 8 MB
frozen("QSound live extent (region offset)", QS_LIVE, 0x8E57F0)
if end_nonzero(q22):
    bad("vsw.22m is no longer empty — the 8.9375 MB QSound placement "
        "assumes DSP sample banks stop at 0x8E")
QS_PLACED = 0x8F0000                       # top of DSP sample bank 0x8E
if QS_PLACED < QS_LIVE:
    bad(f"QSound placement {QS_PLACED:#x} does not cover live {QS_LIVE:#x}")


# ── 4. PRG: the 6 MB region is pinned by the 0x5FFF00 thunk ────────────
def end_nonff(b):
    i = len(b)
    while i and b[i - 1] == 0xFF:
        i -= 1
    return i


prg_end = 0
for n, base in ((41, 0x400000), (42, 0x480000), (43, 0x500000), (44, 0x580000)):
    e = end_nonff(z.read(f"vsw.{n}"))
    if e:
        prg_end = max(prg_end, base + e)
frozen("PRG live extent (highest byte + 1)", prg_end, 0x5FFF1E)
PRG_LEN = 0x600000
if prg_end > PRG_LEN:
    bad("PRG content above the 6 MB WIDE ceiling")

Z80_LEN, FW_LEN, KEY_LEN, HDR_LEN = 0x40000, 0x2000, 20, 44
GFX_LEN = 0x3000000


def rom_layout(qs_len):
    """(file size, {region: header word in KiB}) for the .rom the MRA emits.
    Region starts are body offsets; jtcps1_prom_we.v subtracts FULL_HEADER=64
    (= 44 header + 20 key), so these are exactly what the RTL compares."""
    snd = PRG_LEN
    pcm = snd + Z80_LEN
    gfx = pcm + qs_len
    fw = gfx + GFX_LEN
    words = {"audiocpu": snd >> 10, "qsound": pcm >> 10,
             "gfx": gfx >> 10, "firmware": fw >> 10}
    return HDR_LEN + KEY_LEN + fw + FW_LEN, words, (snd, pcm, gfx, fw)


IOCTL_MAX = 1 << 26          # jtframe_mem_ports.inc:1 — input [25:0] ioctl_addr
WORD_MAX = 1 << 16           # corerom.go set_header_offset — 16-bit start word

size, words, starts = rom_layout(QS_PLACED)
print(f"  .rom size {size} B ({size/2**20:.3f} MB); header words {words}")
if size > IOCTL_MAX:
    bad(f".rom {size} B exceeds the 26-bit ioctl_addr ceiling {IOCTL_MAX}")
for k, w in words.items():
    if w >= WORD_MAX:
        bad(f"header word {k} = {w} KiB does not fit 16 bits")
for name, s in zip(("audiocpu", "qsound", "gfx", "firmware"), starts):
    if s % 1024:
        bad(f"region {name} starts at {s:#x}, not 1 KiB-aligned — the Go "
            "generator's +20 key offset then puts the header word off by one")

# ── 5. the SDRAM banks ─────────────────────────────────────────────────
BANK = 16 << 20
VRAM, ORAM, WRAM, Z80W = 0x40000, 0x8000, 0x10000, 0x80000
PCM_HIGH = 0x100000          # the 1 MB window for DSP banks 0x80-0x8F


def banks(foot4, foot5, qs_placed):
    ba0 = PRG_LEN + VRAM + ORAM + WRAM + Z80W + PCM_HIGH + foot5
    ba1 = min(qs_placed, 0x800000) + foot4
    return ba0, ba1


ba0, ba1 = banks(FOOT4, FOOT5, QS_PLACED)
print(f"  bank 0 {ba0} B of {BANK} (slack {BANK-ba0} B); "
      f"bank 1 {ba1} B of {BANK} (slack {BANK-ba1} B)")
if ba0 > BANK:
    bad(f"SDRAM bank 0 overflows by {ba0-BANK} B")
if ba1 > BANK:
    bad(f"SDRAM bank 1 overflows by {ba1-BANK} B")
if QS_PLACED - 0x800000 > PCM_HIGH:
    bad("the QSound high window is larger than the 1 MB placed in bank 0")

# ── 6. the mechanism itself: scramble o interleave = identity ──────────
# Everything above rests on "a CPS-2 tile code IS its SDRAM address". That is
# not an opinion about the numbers, it is a property of two bit permutations,
# so it is checked here rather than believed. (Verified EXHAUSTIVELY over all
# 131,072 tiles of a group at 14z-107 (4); the gate samples for speed.)
def scramble(a):                       # jtcps1_prom_we.v:105, 26-bit
    return (((a >> 21) & 0x1F) << 21) | (((a >> 3) & 1) << 20) \
         | (((a >> 4) & 0x1FFFF) << 3) | (a & 7)


def wrong_scramble(a):                 # the plausible-but-wrong variant
    return a                           # "no scramble" — the control


def member_off_to_rom(k, off):         # ROMX_LOAD GROUPWORD | SKIP(6)
    return ((off >> 1) << 3) | (k << 1) | (off & 1)


def tile_slices(t2):                   # tools/gfx_tiles.py:112 tile_bytes()
    b, rem = divmod(128 * t2, 0x200000)
    chunk, o = divmod(rem, 0x100000)
    base = b * 0x80000 + 64 * (o // 128) + 2 * chunk
    return [(k, base + 4 * r + j)
            for k in range(4) for r in range(16) for j in (0, 1)]


def identity_holds(f, codes):
    return all({f(member_off_to_rom(k, off)) for k, off in tile_slices(t)}
               == set(range(t * 128, t * 128 + 128)) for t in codes)


SAMPLE = ([0, 1, 0x3F, 0x1FFF, 0x2000, 0x3FFF, 0x4000, 0x7FFF, 0x8000,
           0xEE73, 0xFFDB, 0xFFFF, 0x10000, 0x1FFFF]
          + list(range(0, 0x20000, 61)))
if identity_holds(scramble, SAMPLE):
    print(f"  ok scramble o interleave = identity over {len(SAMPLE)} codes "
          "(SDRAM addr = code*128)")
else:
    bad("the CPS-2 GFX scramble does NOT cancel the .rom interleave — every "
        "footprint in this gate and in mister_map.md is then wrong")
if identity_holds(wrong_scramble, SAMPLE):
    bad("control did not fire: the identity check passes with NO scramble, "
        "so it is not testing the permutation")
else:
    print("  ok scramble control fired (identity fails without the scramble)")

# ── 7. controls ────────────────────────────────────────────────────────
print("== control A: the UNTRIMMED 16 MB QSound region must be rejected ==")
csize, cwords, _ = rom_layout(0x1000000)
if csize <= IOCTL_MAX:
    bad("control A did not fire: untrimmed .rom fits 26-bit ioctl_addr")
elif cwords["firmware"] < WORD_MAX:
    bad("control A half-fired: firmware start word still fits 16 bits")
else:
    print(f"  ok control A fired ({csize/2**20:.2f} MB > 64 MB, and "
          f"qsnd_start {cwords['firmware']} KiB > 65535)")

print("== control B: +1 MB of obj-bank-5 footprint must overflow bank 0 ==")
cb0, _ = banks(FOOT4, FOOT5 + (1 << 20), QS_PLACED)
if cb0 <= BANK:
    bad(f"control B did not fire: bank 0 still fits at {cb0} B")
else:
    print(f"  ok control B fired (bank 0 would need {cb0-BANK} B more)")

if errs:
    print(f"\nFAIL: MiSTer map fit — {len(errs)} problem(s)")
    sys.exit(1)
print("\nPASS: the MiSTer SDRAM placement map fits, and every extent it "
      "depends on is frozen (docs/project/mister_map.md)")
PY
