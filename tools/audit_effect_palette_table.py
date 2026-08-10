#!/usr/bin/env python3
"""audit_effect_palette_table.py — freeze the shape of the per-character
palette POINTER tables (14z-76).

WHY THIS EXISTS. Pyron's effect palette sat unported for two sessions on the
premise that the table at PRG:0x38C218 "has only SIXTEEN rows", so a variant id
would index PAST it into an adjacent shared table and clobber a row vanilla
uses. That premise is wrong: 0x38C198 (sprite) and 0x38C218 (effect) are each
ONE 32-ROW table indexed by the full character id, with rows 0x10-0x1F the
ordinary variant half. 0x38C1D8 and 0x38C258 are not tables at all — they are
those tables' second halves, and nothing in the ROM ever uses them as a base.

A tenant at a variant id therefore repoints its own row, exactly as it does in
every other 32-row per-character table in this port.

The four assertions, all measured, all re-derived here from the ROM:

  1. SHAPE     — each table is 32 rows of pointers into the palette data
                 region, and the region's own data begins after both tables.
  2. ALIASING  — each table's variant half aliases the base half EXCEPT at
                 rows 0x12 and 0x18. Two independent tables agreeing on the
                 same two exceptions is what rules out "two 16-row tables":
                 0x18 is Oboro Bishamon, a variant dataset vsav genuinely
                 ships (docs/game/atlas/character_tables.md).
  3. NO SECOND BASE — the literals 0x38C1D8 and 0x38C258 appear ZERO times in
                 either ROM view. Neither is ever loaded as a base address.
  4. NO FOLD   — every site that indexes the effect table carries the same
                 18-byte preamble, in which the character id byte reaches the
                 index with NO mask and NO fold. If a fold is ever introduced
                 above the tables, a variant row stops being reachable and
                 this gate must fail loudly rather than let a tenant's palette
                 silently resolve to a base-half character's.

Optionally (--build) also checks a built program image: the tenant's row is
repointed, and every base-half row is bit-identical to vanilla.

Usage:
    python3 tools/audit_effect_palette_table.py <vj_opcodes.bin> <vj_data.bin>
            [--build <verify_op.bin> --tenant 0x11]
"""
import argparse
import struct
import sys

SPRITE_TABLE = 0x38C198
EFFECT_TABLE = 0x38C218
TABLE_ROWS = 32
DATA_START = 0x38C2A0          # first palette block, right after both tables
PAL_LO, PAL_HI = 0x380000, 0x3E0000

# rows whose variant half legitimately carries its own block: vsav's own
# variant datasets (0x18 = Oboro Bishamon; 0x12 its sibling).
EXPECTED_EXCEPTIONS = (0x12, 0x18)

# the five sites that index the effect table, and the preamble they share:
#   movea.l #$38c218,a0 / moveq #0,d1 / move.b $382(a6),d1 /
#   lsl.w #2,d1        / movea.l (a0,d1.w),a0
READER_SITES = (0x02AD20, 0x02AFA2, 0x02B25A, 0x02B45C, 0x02B4CA)
READER_PREAMBLE = bytes.fromhex("207c0038c2187200122e0382e54920701000")

# three further sites take a HARDCODED row instead of the id — effects that
# always draw from one character's block (rows 0x06/0x0C/0x0E = Anakaris,
# Q-Bee, Lilith), applied to whichever fighter is in a6. Frozen here because
# they are the reason a tenant's row is NOT the only thing that can change a
# fighter's effect colours, and because they must never start taking the id.
#   movea.l #$38c218,a0 / moveq #<row*4>,d1 / movea.l (a0,d1.w),a0
CONST_SITES = {0x02ABCE: 0x06, 0x02ABF0: 0x0C, 0x02AC12: 0x0E}

NON_BASES = (0x38C1D8, 0x38C258)


def u32(buf, off):
    return struct.unpack_from(">I", buf, off)[0]


def rows(buf, base, n=TABLE_ROWS):
    return [u32(buf, base + 4 * i) for i in range(n)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("opcodes")
    ap.add_argument("data")
    ap.add_argument("--build", help="a built verify_op.bin to check too")
    ap.add_argument("--tenant", default="0x11")
    args = ap.parse_args()

    op = open(args.opcodes, "rb").read()
    da = open(args.data, "rb").read()
    fail = []

    # ---- 1. shape -------------------------------------------------------
    for base, name in ((SPRITE_TABLE, "sprite"), (EFFECT_TABLE, "effect")):
        rs = rows(da, base)
        bad = [(i, v) for i, v in enumerate(rs) if not (PAL_LO <= v < PAL_HI)]
        if bad:
            fail.append(f"{name} table {base:#08x}: {len(bad)} row(s) are not "
                        f"palette-region pointers, first {bad[0]}")
        else:
            print(f"  ok: {name} table {base:#08x} = {TABLE_ROWS} rows, all "
                  f"pointers into {PAL_LO:#x}-{PAL_HI:#x}")
    end = EFFECT_TABLE + 4 * TABLE_ROWS
    if end > DATA_START:
        fail.append(f"the two 32-row tables run to {end:#x}, past the first "
                    f"palette block at {DATA_START:#x} — table shape moved")
    else:
        print(f"  ok: both tables end at {end:#x}, before the data at "
              f"{DATA_START:#x}")

    # ---- 2. aliasing ----------------------------------------------------
    for base, name in ((SPRITE_TABLE, "sprite"), (EFFECT_TABLE, "effect")):
        rs = rows(da, base)
        exc = tuple(0x10 + i for i in range(16) if rs[0x10 + i] != rs[i])
        if exc != EXPECTED_EXCEPTIONS:
            fail.append(f"{name} table variant-half exceptions {[hex(x) for x in exc]} "
                        f"!= expected {[hex(x) for x in EXPECTED_EXCEPTIONS]}")
        else:
            print(f"  ok: {name} variant half aliases the base half except "
                  f"rows {[hex(x) for x in exc]}")

    # ---- 3. no second base ----------------------------------------------
    for addr in NON_BASES:
        pat = struct.pack(">I", addr)
        n = op.count(pat) + da.count(pat)
        if n:
            fail.append(f"{addr:#08x} is referenced {n} time(s) — it is being "
                        f"used as a table base, the 32-row model is wrong")
        else:
            print(f"  ok: {addr:#08x} has 0 references (a table half, not a base)")

    # ---- 4. no fold -----------------------------------------------------
    found = [a for a in READER_SITES if op[a:a + len(READER_PREAMBLE)] == READER_PREAMBLE]
    if len(found) != len(READER_SITES):
        missing = [hex(a) for a in READER_SITES if a not in found]
        fail.append(f"reader preamble changed at {missing} — re-derive the "
                    f"index width before trusting any variant palette row")
    else:
        print(f"  ok: {len(found)} reader sites index the effect table with the "
              f"raw id byte (no mask, no fold)")
    for addr, row in sorted(CONST_SITES.items()):
        want = bytes.fromhex("207c0038c218") + struct.pack(">H", 0x7200 | (4 * row)) \
            + bytes.fromhex("20701000")
        if op[addr:addr + len(want)] != want:
            fail.append(f"constant-row site {addr:#08x} no longer takes fixed "
                        f"row {row:#04x} — it may have started taking the id")
    if not any(f.startswith("constant-row") for f in fail):
        print(f"  ok: {len(CONST_SITES)} further sites take FIXED rows "
              f"{[hex(r) for r in sorted(CONST_SITES.values())]}, never the id")

    stray = (op.count(struct.pack(">I", EFFECT_TABLE))
             - len(READER_SITES) - len(CONST_SITES))
    if stray:
        fail.append(f"{stray} unaccounted reference(s) to {EFFECT_TABLE:#08x} — "
                    f"a site covered by neither the id nor the fixed-row check")

    # ---- optional: the built image --------------------------------------
    if args.build:
        tenant = int(args.tenant, 0)
        bi = open(args.build, "rb").read()
        vrow = EFFECT_TABLE + 4 * tenant
        got, van = u32(bi, vrow), u32(da, vrow)
        if got == van:
            fail.append(f"build: effect row {tenant:#04x} at {vrow:#08x} is still "
                        f"the vanilla alias {van:#08x} — not ported")
        else:
            print(f"  ok: build effect row {tenant:#04x} repointed "
                  f"{van:#08x} -> {got:#08x}")
        dirty = [i for i in range(0x10)
                 if u32(bi, EFFECT_TABLE + 4 * i) != u32(da, EFFECT_TABLE + 4 * i)]
        if dirty:
            fail.append(f"build: base-half effect rows {[hex(i) for i in dirty]} "
                        f"differ from vanilla — LEGACY CLOBBER")
        else:
            print("  ok: build base-half effect rows 0x00-0x0F all pristine")

    if fail:
        print("\nFAIL:")
        for f in fail:
            print("  " + f)
        return 1
    print("\nPASS: effect/sprite palette tables are 32-row id-indexed, "
          "variant rows reachable and unaliased-safe")
    return 0


if __name__ == "__main__":
    sys.exit(main())
