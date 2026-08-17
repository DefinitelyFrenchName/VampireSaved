#!/usr/bin/env python3
"""decode_stage_banners.py — decode the STAGE-NAME banner family and the
per-character arcade-ladder rows that select from it (14z-94, GitHub #92).

WHY THIS EXISTS. #92 crashes because Huitzil's and Pyron's authored ladder
rows carry the value `0x18`, which runs off the end of vsavj's banner
family and dereferences that table's `0x00400000` terminator. Fixing it
means replacing four bytes per tenant with a legal value — and that value
is player-perceptible, so it is a maintainer decision, not an arbitrary
in-range pick. A decision needs the value SPACE named, not numbered: this
tool turns each legal value into the stage it selects.

WHAT THE VALUE IS. `0x00aeca` picks a candidate index from the class pool
copied out of table A (`PRG:0x00B268`), writes that CLASS to the opponent's
`$382`, and writes table B's (`PRG:0x00BB68`) parallel byte to `$FF8100`.
`$FF8100` is the STAGE index: `0x05ffa6` turns it into a banner-record
pointer, and other readers index stage assets with it (e.g. `0x01bf5e`
uploads into palette RAM `0x90C2C0`). So one ladder entry is a pair —
"fight this CLASS at this STAGE".

**THE ANCHOR IS PER-GAME AND MUST BE READ FROM THE CODE, NOT ASSUMED.**
This is the trap that produced a wrong answer first time round. The site is

    move.w $100(a5),d0 ; add.w d0,d0 ; movea.l #ANCHOR,a0 ; lea -4(a0,d0.w),a0

so `a0 = ANCHOR + 2v - 4` and the consumer dereferences the FOLLOWING row,
i.e. value `v` selects the row at `ANCHOR + 2v`. ANCHOR is NOT the pointer
table's base — it is the address of the family's FIRST row:

    vsavj  site 0x05ffa6  anchor 0x26775a  = table 0x26771e row 0x0f
    vsav2  site 0x06c13c  anchor 0x2a0a96  = table 0x2a0a4a row 0x13

Assuming the table base instead of the anchor shifts every value by four
rows and invents a clean-looking "+8 renumber" between the two games that
does not exist. `tests/test_decode_stage_banners.sh` carries that as a
verdict control. Read the anchor with:

    python3 tools/m68dis.py build/out/<set>_opcodes.bin 0x05ffa0 0x05ffc0

MEASURED RESULT (14z-94): both games number `v=0x00` at their own first
row, and the twelve stages vsav ships are the same twelve, in the same
order, at the same values. vs2 has a THIRTEENTH at `v=0x18` —
REVENGER'S ROOST — which vsav does not have. That single missing stage is
all of #92: the ported rows are otherwise correctly numbered.

RECORD FORMAT. fmt-4 sprite record: `fmt.w`, `w1.w`, `count-1.w`, then
`count` entries of `code.w attr.w x.w y.w`. Codes are system-font glyphs
(+0x3800 applied by the drawer); `0x07b1`..`0x07ca` are 'A'..'Z' and
anything else is printed as `[xxxx]` rather than guessed — `0x079c` is an
apostrophe and `0x0733` a separator, and neither is worth a lookup table
when the point is to identify a stage.

Usage:
  decode_stage_banners.py stages <image.bin> <ptr_table> <anchor>
  decode_stage_banners.py ladder <image.bin> <tableA> <tableB> <class>
  decode_stage_banners.py ladder-hex <hexA> <hexB> --stages <image> <tbl> <anchor>
"""
import sys
import hashlib

GLYPH_A, GLYPH_Z = 0x07B1, 0x07CA
# A row is a real pointer if it lands in program space. The families are
# terminated by 0x00400000 / 0x04000000 sentinels, which this rejects.
PTR_LO, PTR_HI = 0x000400, 0x400000


def load(path):
    data = open(path, "rb").read()
    print(f"# {path}  sha1 {hashlib.sha1(data).hexdigest()}")
    return data


def w(b, a):
    return int.from_bytes(b[a:a + 2], "big")


def l(b, a):
    return int.from_bytes(b[a:a + 4], "big")


def decode_record(b, addr):
    """Return (fmt, count, text) for the fmt-4 glyph record at addr."""
    fmt, n = w(b, addr), w(b, addr + 4)
    out = []
    for i in range(n + 1):
        c = w(b, addr + 6 + i * 8)
        out.append(chr(ord("A") + c - GLYPH_A) if GLYPH_A <= c <= GLYPH_Z
                   else f"[{c:04x}]")
    return fmt, n + 1, "".join(out)


def stages(img, table, anchor):
    """Enumerate the banner family from its ANCHOR row to the terminator.

    Returns {value: (row, addr, text)}. The anchor's row index is derived
    from the table base only for reporting; the walk itself uses the
    anchor, which is what the engine uses.
    """
    row0 = (anchor - table) // 4
    out = {}
    v = 0
    while True:
        a = l(img, anchor + v * 2)
        if not (PTR_LO <= a < PTR_HI):
            break
        fmt, n, text = decode_record(img, a)
        if fmt != 4:
            print(f"  ! value {v:#04x} row {row0 + v // 2:#04x} @{a:#08x} "
                  f"is fmt {fmt}, not a banner record — family boundary?")
            break
        out[v] = (row0 + v // 2, a, text)
        v += 2
    return out


def ladder(rowA, rowB, stage_map):
    """Decode one 64-byte ladder row pair into 8 groups of 8 entries.

    Table A holds the candidate CLASS, table B the STAGE value at the same
    index — the selector at 0x00aeca uses ONE index into both. An entry
    whose stage value is absent from stage_map is out of range: that is
    the #92 shape, and it is reported per offset so a fix can be written
    against byte positions.
    """
    bad = []
    for g in range(8):
        print(f"  group {g} (venue byte {g * 8:#04x}):")
        for i in range(8):
            o = g * 8 + i
            cls, val = rowA[o], rowB[o]
            name = stage_map.get(val)
            if name is None:
                bad.append((o, cls, val))
                shown = "*** OUT OF RANGE ***"
            else:
                shown = name[2]
            print(f"    +{o:#04x}  idx {i}  class {cls:#04x}  "
                  f"stage {val:#04x}  {shown}")
    return bad


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    mode = sys.argv[1]

    if mode == "stages":
        img = load(sys.argv[2])
        table, anchor = int(sys.argv[3], 16), int(sys.argv[4], 16)
        smap = stages(img, table, anchor)
        print(f"# table {table:#08x} anchor {anchor:#08x} "
              f"(row {(anchor - table) // 4:#04x}) — {len(smap)} stages")
        for v, (row, a, t) in sorted(smap.items()):
            print(f"  v={v:#04x}  row {row:#04x}  @{a:#08x}  {t}")
        if not smap:
            # An empty family is a WRONG ANCHOR, not a game with no stages.
            # Say so and exit nonzero: a caller that greps for names would
            # otherwise read this as "the names are absent" and be right by
            # accident. This is the base-as-anchor mistake's signature.
            sys.exit("  EMPTY FAMILY — the anchor is wrong. It is the address "
                     "of the family's FIRST ROW, not the pointer table base.")
        print(f"  max legal value {max(smap):#04x}")

    elif mode == "ladder":
        img = load(sys.argv[2])
        ta, tb, cls = (int(x, 16) for x in sys.argv[3:6])
        # the stage map for the same image, read from argv[6:8]
        table, anchor = int(sys.argv[6], 16), int(sys.argv[7], 16)
        smap = stages(img, table, anchor)
        rowA = img[ta + (cls << 6): ta + (cls << 6) + 64]
        rowB = img[tb + (cls << 6): tb + (cls << 6) + 64]
        print(f"# ladder row class {cls:#04x}")
        bad = ladder(rowA, rowB, smap)
        print(f"  {len(bad)} out-of-range entries")

    elif mode == "ladder-hex":
        rowA = bytes.fromhex(sys.argv[2])
        rowB = bytes.fromhex(sys.argv[3])
        img = load(sys.argv[5])
        table, anchor = int(sys.argv[6], 16), int(sys.argv[7], 16)
        smap = stages(img, table, anchor)
        bad = ladder(rowA, rowB, smap)
        print(f"  {len(bad)} out-of-range entries")
        for o, c, v in bad:
            print(f"    +{o:#04x}: class {c:#04x} wants stage {v:#04x}, "
                  f"which this image does not have")
    else:
        sys.exit(__doc__)


main()
