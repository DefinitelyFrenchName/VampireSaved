#!/usr/bin/env python3
"""checkdocs_rom.py — re-derive the atlas's ROM-shaped claims from the
decrypted reference images, so a documented fact cannot rot in silence.

  python3 tools/checkdocs_rom.py                  # every check, + the coverage NOTE
  python3 tools/checkdocs_rom.py --list           # the registry
  python3 tools/checkdocs_rom.py --only NAME      # one check
  python3 tools/checkdocs_rom.py --doc FILE       # every check on one document
  python3 tools/checkdocs_rom.py --uncovered      # what no check reaches
  python3 tools/checkdocs_rom.py --disasm         # capstone beside a mismatch
  python3 tools/checkdocs_rom.py --views DIR --root DIR    # controls

WHY THIS EXISTS (14z-142, living-docs slice L3; scope
`docs/project/living_docs_scope.md` §11). The atlas states hundreds of facts
about the program image and NOTHING re-derived any of them. Some have no
second home in the tree at all: `docs/game/atlas/README.md` says of its
opcode-view SHA-1 column, in the document itself, "it has no second home in
the tree, so this is the only place it is checked" — a figure a human
re-derived by hand at 14z-118 and would have to remember to re-derive again.

WHAT A CHECK IS, and the two halves matter equally. A check QUOTES its claim
from the document (`says()`, asserting the sentence is still there) and
DERIVES the same fact from the image, then compares. Quoting is not
decoration: without it a check silently outlives the sentence it was written
for, and passes while documenting nothing. A reworded document is a STALE
verdict, which is a prompt to re-read the check, never to delete the quote.

THE MEASUREMENTS THAT SHAPED IT (§11.3, all made before this file existed):

  * THE CHECKS ARE HAND-WRITTEN AND MUST BE. Of the 36 68k instruction spans
    in the atlas ROM tier, exactly ONE sits in a paragraph naming exactly one
    address and 27 sit in paragraphs naming none — the atlas pairs an
    instruction to an address in PROSE. No census can seed these, and no
    later session may grow coverage automatically from one.
  * AN ATLAS QUOTE MAY BE A SEMANTIC PARAPHRASE AND THE DOCUMENT STILL
    CORRECT. `character_tables.md` describes the palette blitter as
    `or.l #$F000F000`; the image holds `or.l d0,(a1)+` with `move.l
    #$f000f000,d0` two instructions earlier. A word compare on that text
    would report correct documentation as stale, which is how a checker
    trains its reader to ignore it. Such claims are declared PARAPHRASE and
    checked against the literal fact they summarise — never skipped, always
    printed (maintainer-ruled 2026-09-07).
  * ALL THREE SETS ARE READ (maintainer-ruled 2026-09-07). The atlas's spine
    is a three-set comparison table — 41 sibling addresses, 50 rows carrying
    two or more — so a vsavj-only checker would leave its largest table
    unchecked. `decrypt_view` takes the set as an argument and the opener's
    ROM audit covers all 76 members, so this costs nothing.
  * COVERAGE IS REPORTED AGAINST 346 (maintainer-ruled 2026-09-07): the 473
    atlas addresses minus the 127 carried only by `ram.md`. Those 127 are
    program addresses, but their claims are dataflow ("this routine writes
    that field") and belong to the suite, not here (scope §6.5). Counting
    them would make the number permanently and misleadingly low.

NO CAPSTONE DEPENDENCY. A check carries the expected OPCODE WORDS with the
mnemonic beside them in a comment; the words are the evidence. `--disasm`
adds capstone's reading beside a mismatch and is diagnostic only, never a
skip — a checker whose verdict depends on an optional import measures
whatever happens to be installed.

Needs the decrypted views (`tests/lib/decrypt_cache.sh`, ROMDIR on a cache
miss). Rule 7: prints addresses, words and shapes — never a byte run longer
than the atlas already quotes.
ci_static, ~20 s (tests/test_checkdocs_rom.sh).
"""
import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ATLAS = "docs/game/atlas"
SETS = ("vsavj", "vsav2", "vhunt2")

# The ROM-tier documents (scope §11: ram.md's claims are RAM and stay with
# the suite; its 127 program addresses are dataflow and out of scope here).
ROM_TIER_DOCS = ("README.md", "character_tables.md", "id_space.md",
                 "select_screen.md", "sprite_lists.md", "venue_assets.md")

# Ruled 2026-09-07: the coverage denominator. Asserted against the live
# census by --uncovered, so it cannot drift from the tree unnoticed.
DENOMINATOR = 346


class Stale(Exception):
    """The document no longer says what the check quotes."""


class Mismatch(Exception):
    """The document and the image disagree."""


class Vacuous(Exception):
    """A table validator that its own negative control cannot make fail."""


# ---------------------------------------------------------------- the image

class Image:
    """One decrypted view pair, logging every address a check reads."""

    def __init__(self, name, op_path, data_path):
        self.name = name
        self.op = Path(op_path).read_bytes()
        self.data = Path(data_path).read_bytes()
        if len(self.op) != 4 * 1024 * 1024 or len(self.data) != 4 * 1024 * 1024:
            raise SystemExit(
                "checkdocs_rom: %s view is %d/%d bytes, expected 4 MiB each — "
                "a short image is a decrypt that did not finish"
                % (name, len(self.op), len(self.data)))

    def _view(self, view):
        if view not in ("op", "data"):
            raise ValueError("view must be 'op' or 'data', got %r" % (view,))
        return self.op if view == "op" else self.data

    def bytes(self, addr, n, view="op"):
        TOUCHED.update(range(addr, addr + n))
        return self._view(view)[addr:addr + n]

    def word(self, addr, view="op"):
        return int.from_bytes(self.bytes(addr, 2, view), "big")

    def long(self, addr, view="op"):
        return int.from_bytes(self.bytes(addr, 4, view), "big")

    def words(self, addr, n, view="op"):
        b = self.bytes(addr, 2 * n, view)
        return [int.from_bytes(b[i:i + 2], "big") for i in range(0, 2 * n, 2)]

    def longs(self, addr, n, view="op"):
        b = self.bytes(addr, 4 * n, view)
        return [int.from_bytes(b[i:i + 4], "big") for i in range(0, 4 * n, 4)]

    def count(self, needle, view="op"):
        """Occurrences of a byte pattern. Deliberately does NOT mark TOUCHED:
        a whole-image scan reaches every address and would report the corpus
        as fully covered on the strength of one check."""
        return self._view(view).count(needle)


TOUCHED = set()
IMAGES = {}
DOCS = {}
CHECKS = []           # (doc, name, fn)
CONTROLS_FIRED = []   # names of negative controls that fired
PARAPHRASE = {}       # name -> why the doc's text is not a transcription
UNENCODABLE = {}      # address -> why no check can reach it


def img(name):
    return IMAGES[name]


# ---------------------------------------------------------------- the claim

_WS = re.compile(r"\s+")


def _collapsed(doc):
    if doc not in DOCS:
        raise Stale("no such document: %s" % doc)
    return DOCS[doc]


def says(doc, *fragments):
    """Assert each fragment appears in the document, whitespace-collapsed so a
    re-wrapped line is not a false verdict. This is half of every check."""
    text = _collapsed(doc)
    for frag in fragments:
        if _WS.sub(" ", frag).strip() not in text:
            raise Stale("%s no longer contains: %s" % (doc, frag.strip()))


def eq(label, doc_value, rom_value):
    if doc_value != rom_value:
        raise Mismatch("%s: document says %s, image holds %s"
                       % (label, _fmt(doc_value), _fmt(rom_value)))


def _fmt(v):
    if isinstance(v, int):
        return "0x%X" % v
    if isinstance(v, (list, tuple)):
        return "[" + " ".join(_fmt(x) for x in v) + "]"
    return str(v)


def check(doc, name, paraphrase=None):
    """Register a check. `paraphrase=` declares that the document's wording is
    a faithful SUMMARY rather than a transcription, and names the literal fact
    the check asserts instead."""
    def deco(fn):
        CHECKS.append((doc, name, fn))
        if paraphrase:
            PARAPHRASE[name] = paraphrase
        return fn
    return deco


def table(name, base, count, stride, read, entry, control=None):
    """Run `entry` over every row, then over the row at `control` (default: a
    deliberately misaligned base), where at least one entry MUST be rejected.
    A validator its own control cannot break is reported Vacuous: it would
    pass against any bytes, and a check that cannot fail is not evidence."""
    for i in range(count):
        v = read(base + i * stride)
        if not entry(v, i):
            raise Mismatch("%s: row %d at 0x%06X rejected — %s"
                           % (name, i, base + i * stride, _fmt(v)))
    ctl = control if control is not None else base + max(1, stride // 2)
    if all(entry(read(ctl + i * stride), i) for i in range(count)):
        raise Vacuous(
            "%s: the validator accepts the control base 0x%06X too, so it "
            "would accept anything — it proves nothing about 0x%06X"
            % (name, ctl, base))
    CONTROLS_FIRED.append(name)


# ================================================================= THE CHECKS
# Each quotes its claim, then derives it. Opcode words carry their mnemonic in
# a comment; the words are what is compared.

@check("README.md", "opcode_view_digests")
def _digests():
    """The three decrypted opcode views hash to the digests the atlas prints.

    This is the check the document itself asked for: "it has no second home in
    the tree, so this is the only place it is checked"."""
    import hashlib
    says("README.md",
         "The SHA-1 column is re-derived by",
         "it has no second home in the tree, so this is the only place it is checked")
    text = _collapsed("README.md")
    for s in SETS:
        row = re.search(r"\|\s*" + s + r"\s*\|[^|]*\|[^|]*\|\s*`([0-9a-f]{40})`\s*\|", text)
        if not row:
            raise Stale("README.md: no SHA-1 row for %s" % s)
        want = row.group(1)
        got = hashlib.sha1(img(s).op).hexdigest()
        # The digest is of the whole view; mark the image read for coverage.
        TOUCHED.update((0x000000,))
        eq("%s opcode-view SHA-1" % s, want, got)


@check("README.md", "watchdog_constants")
def _watchdog():
    """Each set's watchdog constant, and the one placement the atlas asserts.

    The README gives the watchdog as a property of the KEY BLOCK and names no
    address for it (§11.3 finding 6), so the checkable forms are its presence
    and the site character_tables.md does place it at."""
    says("README.md",
         "`cmpi.l #$726A4BAF, D0`",
         "`cmpi.l #$06920760, D0`",
         "vsav2/vhunt2 sharing a watchdog instruction (distinct keys)")
    for s, const in (("vsavj", 0x726A4BAF), ("vsav2", 0x06920760),
                     ("vhunt2", 0x06920760)):
        needle = b"\x0c\x80" + const.to_bytes(4, "big")   # cmpi.l #const,d0
        n = img(s).count(needle)
        if n == 0:
            raise Mismatch("%s: the watchdog compare cmpi.l #$%08X,d0 does not "
                           "occur in the opcode view" % (s, const))
    # The sibling symmetry the README's own sentence predicts.
    eq("vsav2/vhunt2 share the watchdog constant",
       img("vsav2").count(b"\x0c\x80\x06\x92\x07\x60") > 0,
       img("vhunt2").count(b"\x0c\x80\x06\x92\x07\x60") > 0)


@check("character_tables.md", "watchdog_in_blitter_loop",
       paraphrase="the atlas renders the blitter as `move.l (a0)+,(a1); or.l "
                  "#$F000F000` — a faithful SUMMARY: the image holds `or.l "
                  "d0,(a1)+` with `move.l #$f000f000,d0` two instructions "
                  "earlier. The literal facts checked instead are the d0 load "
                  "and the watchdog's placement inside the loop.")
def _blitter():
    """PRG:0x000EF2 loads #$f000f000 into d0 and feeds the watchdog inline."""
    says("character_tables.md",
         "uploaded straight from ROM",
         "by the system blitter at `PRG:0x000EF2`",
         "feeds the CPS2 encryption",
         "watchdog inline**: `cmpi.l #$726A4BAF,d0` lives inside this loop")
    j = img("vsavj")
    eq("PRG:0x000EF2 moveq #$1f,d7 (the loop the atlas names)", 0x7E1F,
       j.word(0x000EF2))
    eq("PRG:0x000EF4 move.l #imm,d0 opcode", 0x203C, j.word(0x000EF4))
    eq("the constant loaded into d0", 0xF000F000, j.long(0x000EF6))
    eq("PRG:0x000EFA cmpi.l opcode", 0x0C80, j.word(0x000EFA))
    eq("the watchdog constant at 0x000EFA", 0x726A4BAF, j.long(0x000EFC))


@check("character_tables.md", "loader_immediates")
def _loader():
    """The loader's own immediates ARE the table addresses documented below it.

    The transcription uses `#<word_tbl>` / `#<tbl64>` placeholders, so what is
    checkable is that the operands resolve to the addresses the table states —
    which makes the two claims verify each other."""
    says("character_tables.md",
         "vsavj `PRG:0x028DD8`",
         "movea.l #<word_tbl>,a0",
         "movea.l #<tbl64>,a0",
         "| struct+0x132 (.w) | `PRG:0x0BE17A` |",
         "| struct+0x64 (.l) | `PRG:0x0BD9FA` |")
    j = img("vsavj")
    eq("0x028DD8 ext.w d0", 0x4880, j.word(0x028DD8))
    eq("0x028DDA add.w d0,d0", 0xD040, j.word(0x028DDA))
    eq("0x028DDC movea.l #imm,a0", 0x207C, j.word(0x028DDC))
    eq("the word-table immediate == the documented struct+0x132 base",
       0x0BE17A, j.long(0x028DDE))
    eq("0x028DEA movea.l #imm,a0", 0x207C, j.word(0x028DEA))
    eq("the tbl64 immediate == the documented struct+0x64 base",
       0x0BD9FA, j.long(0x028DEC))


@check("character_tables.md", "per_set_table_bases")
def _bases():
    """The three per-character tables, on all three images: 32 entries each,
    every hitbox base a plausible ROM pointer. Ruled 2026-09-07 — the atlas's
    spine is this three-set table, so all three are read."""
    says("character_tables.md",
         "## Table addresses (32 entries each: slots 0x00-0x0F, variants 0x10-0x1F)",
         "| hitbox base (.l) | `PRG:0x0BD97A` | `PRG:0x0D7B18` | `PRG:0x0D73AA` |",
         "| struct+0x64 (.l) | `PRG:0x0BD9FA` | `PRG:0x0D7B98` | `PRG:0x0D742A` |",
         "| struct+0x132 (.w) | `PRG:0x0BE17A` | `PRG:0x0D8318` | `PRG:0x0D7BAA` |")
    # The two pointer tables: 32 entries, every one a plausible ROM pointer.
    for label, bases in (
            ("hitbox base", (("vsavj", 0x0BD97A), ("vsav2", 0x0D7B18), ("vhunt2", 0x0D73AA))),
            ("struct+0x64", (("vsavj", 0x0BD9FA), ("vsav2", 0x0D7B98), ("vhunt2", 0x0D742A)))):
        for s, base in bases:
            im = img(s)
            table("%s %s table" % (s, label), base, 32, 4,
                  lambda a, _im=im: _im.long(a, "data"),
                  lambda v, i: 0x001000 <= v <= 0x3FFFFF)
    # struct+0x132 is a WORD table and measures uniform 0x0018 in all three
    # sets — a real documented shape, and a weak validator on its own, so it
    # earns its place only because the misaligned control rejects it.
    for s, base in (("vsavj", 0x0BE17A), ("vsav2", 0x0D8318), ("vhunt2", 0x0D7BAA)):
        im = img(s)
        table("%s struct+0x132 table" % s, base, 32, 2,
              lambda a, _im=im: _im.word(a, "data"),
              lambda v, i: v == 0x0018)


@check("character_tables.md", "variant_half_aliases_except_slot8")
def _variants():
    """The variant half aliases the base half at every slot but 0x8, whose
    dataset is the documented Oboro block. A structural finding, re-derived."""
    says("character_tables.md",
         "Variant half (0x10-0x1F) aliases the base half except:",
         "**vsavj: slot 0x8 only**",
         "variant dataset 0x18 (base 0x0B3450) is **Oboro Bishamon**")
    j = img("vsavj")
    rows = j.longs(0x0BD97A, 32, "data")
    differing = [i for i in range(16) if rows[i] != rows[16 + i]]
    eq("slots where the variant half differs", [8], differing)
    eq("the variant 0x18 dataset base", 0x0B3450, rows[0x18])


@check("id_space.md", "id_cycling_selectors")
def _cycling():
    """Both id-cycling selectors mask #$0f in vsavj — and vsav2 ships the
    identical sites with #$1f, which is the document's own comparison."""
    says("id_space.md",
         "| `PRG:0x010E2C` | `andi.b #$0f,$382(a4)` after `addq.b #$1`",
         "| `PRG:0x010E3A` | the same after `subq.b #$1`",
         "nothing structural; vsav2 does the identical thing with `#$1f`")
    j = img("vsavj")
    for addr in (0x010E2C, 0x010E3A):
        # andi.b #$0f,$382(a4)
        eq("vsavj 0x%06X words" % addr, [0x022C, 0x000F, 0x0382], j.words(addr, 3))
    eq("vsavj sites masking #$0f", 2, j.count(b"\x02\x2c\x00\x0f\x03\x82"))
    eq("vsav2 sites masking #$1f", 2, img("vsav2").count(b"\x02\x2c\x00\x1f\x03\x82"))
    eq("vsav2 sites masking #$0f", 0, img("vsav2").count(b"\x02\x2c\x00\x0f\x03\x82"))


@check("id_space.md", "anim_number_table_04ffa8")
def _animtable():
    """PRG:0x04FFA8: 32 rows x 24 bytes ending at 0x0502A8, the variant half a
    byte copy of the base half, and the value range — including the slot-0x8
    exception the 14z-142 measurement found (see the document's own row)."""
    says("id_space.md",
         "that table is **32 rows × 24 bytes**, ending cleanly at `0x0502A8`",
         "with rows `0x10-0x1F` byte-identical copies of `0x00-0x0F`",
         "values `0x0370-0x03D7` for every row except slot `0x8`")
    j = img("vsavj")
    eq("the table's end", 0x0502A8, 0x04FFA8 + 32 * 24)
    rows = [j.bytes(0x04FFA8 + 24 * i, 24, "data") for i in range(32)]
    eq("the variant half is a byte copy", rows[:16], rows[16:])
    for i in range(16):
        if i == 8:
            continue
        vals = [int.from_bytes(rows[i][2 * k:2 * k + 2], "big") for k in range(12)]
        if not all(0x0370 <= v <= 0x03D7 for v in vals):
            raise Mismatch("row 0x%X carries a value outside 0x0370-0x03D7: %s"
                           % (i, _fmt(vals)))
    slot8 = [int.from_bytes(rows[8][2 * k:2 * k + 2], "big") for k in range(12)]
    says("id_space.md", "slot `0x8` carries its own block `0x02A5-0x02AD`")
    eq("slot 0x8's block range", (0x02A5, 0x02AD), (min(slot8), max(slot8)))


# ================================================================== COVERAGE

def atlas_census(root):
    """(rom_tier, ram_document, sibling) address sets, from the same collector
    `docs/annotations.md` is generated by — so the denominator cannot drift
    from the corpus."""
    sys.path.insert(0, str(root / "tools"))
    import gen_annotations as GA
    rows = GA.collect(root)
    rom_tier, ram_doc, sibling = {}, {}, set()
    for v, carriers in rows.items():
        tier0 = {(rel, sec, hint) for t, rel, sec, hint in carriers if t == 0}
        if not tier0:
            continue
        files = {rel for rel, _, _ in tier0}
        if any(h for _, _, h in tier0):
            sibling.add(v)
        if files == {"%s/ram.md" % ATLAS}:
            ram_doc[v] = files
        else:
            rom_tier[v] = files
    return rom_tier, ram_doc, sibling


def report_uncovered(root, verbose):
    rom_tier, ram_doc, sibling = atlas_census(root)
    covered = {v for v in rom_tier if v in TOUCHED}
    uncovered = sorted(set(rom_tier) - covered)
    print()
    print("== coverage ==")
    print("  ROM-TIER      %4d atlas addresses (the denominator)" % len(rom_tier))
    print("  covered       %4d" % len(covered))
    print("  RAM-DOCUMENT  %4d carried only by ram.md — dataflow claims, out "
          "of scope (scope §6.5)" % len(ram_doc))
    print("  SIBLING       %4d of the atlas rows name a vs2/vh2 address"
          % len(sibling))
    if len(rom_tier) != DENOMINATOR:
        print("  NOTE: the census now returns %d ROM-tier addresses where this "
              "tool declares %d — the corpus moved; re-read scope §11.2 and "
              "update DENOMINATOR deliberately." % (len(rom_tier), DENOMINATOR))
    if verbose:
        per_doc = {}
        for v in uncovered:
            for f in rom_tier[v]:
                per_doc.setdefault(f, []).append(v)
        print()
        for f in sorted(per_doc):
            addrs = sorted(per_doc[f])
            print("  %-44s %3d uncovered" % (f, len(addrs)))
            for i in range(0, len(addrs), 8):
                marks = " ".join(
                    ("0x%06X%s" % (a, "*" if a in sibling else ""))
                    for a in addrs[i:i + 8])
                print("      " + marks)
        print("  (* = the atlas names it as a vs2/vh2 address)")
    return len(covered), len(rom_tier)


# ====================================================================== main

def load_docs(root):
    for name in ROM_TIER_DOCS:
        p = root / ATLAS / name
        if not p.exists():
            raise SystemExit("checkdocs_rom: missing %s" % p)
        DOCS[name] = _WS.sub(" ", p.read_text(encoding="utf-8", errors="replace"))


def load_images(views):
    for s in SETS:
        op, dat = views / ("%s_opcodes.bin" % s), views / ("%s_data.bin" % s)
        if not op.exists() or not dat.exists():
            raise SystemExit(
                "checkdocs_rom: no decrypted views for %s under %s — the gate "
                "runs `decrypt_view` first (ROMDIR on a cache miss)" % (s, views))
        IMAGES[s] = Image(s, op, dat)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--views", default=str(REPO / "build/out"),
                    help="directory holding <set>_opcodes.bin / _data.bin")
    ap.add_argument("--root", default=str(REPO), help="document tree to read")
    ap.add_argument("--only", help="run one check by name")
    ap.add_argument("--doc", help="run every check on one document")
    ap.add_argument("--list", action="store_true", help="the registry")
    ap.add_argument("--uncovered", action="store_true",
                    help="list the addresses no check reaches")
    ap.add_argument("--disasm", action="store_true",
                    help="capstone's reading beside a mismatch (diagnostic)")
    args = ap.parse_args()
    root = Path(args.root).resolve()

    if args.list:
        for doc, name, fn in CHECKS:
            tag = " [PARAPHRASE]" if name in PARAPHRASE else ""
            print("%-26s %-34s%s" % (doc, name, tag))
            if name in PARAPHRASE:
                print("      " + PARAPHRASE[name])
        return 0

    load_docs(root)
    load_images(Path(args.views).resolve())

    selected = [c for c in CHECKS
                if (not args.only or c[1] == args.only)
                and (not args.doc or c[0] == args.doc)]
    if not args.only and not args.doc:
        selected = CHECKS
    if args.only and not selected:
        raise SystemExit("checkdocs_rom: no check named %r" % args.only)

    bad = 0
    for doc, name, fn in selected:
        try:
            fn()
        except (Stale, Mismatch, Vacuous) as e:
            bad += 1
            print("MISMATCH  %-32s %s: %s" % (name, type(e).__name__, e))
            if args.disasm:
                _disasm_hint(e)
        else:
            tag = "  [PARAPHRASE]" if name in PARAPHRASE else ""
            print("ok        %-32s %s%s" % (name, doc, tag))

    print()
    print("%d checks, %d ok, %d mismatched; %d table controls fired (%s)"
          % (len(selected), len(selected) - bad, bad, len(CONTROLS_FIRED),
             ", ".join(CONTROLS_FIRED) or "none"))
    if PARAPHRASE:
        print("%d declared PARAPHRASE claim(s): %s"
              % (len(PARAPHRASE), ", ".join(sorted(PARAPHRASE))))

    covered = total = 0
    if not args.only and not args.doc:
        covered, total = report_uncovered(root, args.uncovered)
        print()
        print("NOTE: checkdocs_rom.coverage %d/%d atlas ROM-tier addresses"
              % (covered, total))
    return 1 if bad else 0


def _disasm_hint(exc):
    try:
        import capstone
    except ImportError:
        print("      (--disasm needs capstone; the words above are the evidence)")
        return
    m = re.search(r"0x([0-9A-Fa-f]{5,6})", str(exc))
    if not m:
        return
    a = int(m.group(1), 16)
    md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_M68K_000)
    for ins in list(md.disasm(img("vsavj").op[a:a + 16], a))[:3]:
        print("      0x%06X  %s %s" % (ins.address, ins.mnemonic, ins.op_str))


if __name__ == "__main__":
    sys.exit(main())
