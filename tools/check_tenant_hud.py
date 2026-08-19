#!/usr/bin/env python3
"""check_tenant_hud.py — independent re-derivation of the variant-id HUD
fix (14z-63, phase 3 item 4: the folded-venue "VICTOR"/wrong-mugshot
symptom).

Mechanism (measured): both HUD consumers are UNMASKED — the mugshot
stager (0x8937C..) indexes table PRG:0x89884 (word/char) by $782/$b82(a5)
and the name stager (0x89684) indexes PRG:0x898C4 (8B/char) by $382(a4)
— and both tables are 32-row ALIASED, so a tenant at 0x13 read the row
0x03 alias (Victor). Fix: fill row 0x13 of both tables (tenant-gated
pokes) + place the mugshot art at the free-pool anchor 0xBE90 on variant
builds only (Jedah's own 0x3DC8 cells stay pristine). Stager base:
vsavj adds +0x3800 to table codes.

Checks:
  1. vanilla shape: both tables 32-row aliased in the data image;
  2. the build carries EXACTLY the three expected pokes (row addresses
     re-derived from table bases, values re-derived from the anchors);
  3. art: built group A holds vs2's mugshot block (0x4D62 2x2) at
     0xBE90 and vs2's name block (0x4D55 3x1) at 0xBE8C, byte-identical
     and non-blank; Jedah's own mugshot cells (0x3DC8 2x2) are
     byte-identical to PRISTINE vsav (host de-substitution).

Usage: check_tenant_hud.py <outbase> <vsavj_data.bin> <romdir>
"""

import hashlib
import json
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from gfx_tiles import GROUP_A, tile_bytes, BLANK, cell_at  # noqa: E402

MUG_TABLE = 0x89884          # word per char, 32 rows
NAME_TABLE = 0x898C4         # 8 bytes per char, 32 rows
STAGER_BASE = 0x3800
JEDAH_MUG = 0x3DC8           # the host's own cells — must stay pristine

# Per-tenant HUD facts (14z-67, de-Donovanized): an INDEPENDENT
# re-derivation table — values measured from vs2's DATA-view HUD tables
# (name entry = code/attr/xoff/advance; art code = entry + 0x4200, the
# vs2 stager bias) and the chosen free-pool anchors. Keyed by tenant id
# from the build's own tenant.json.
TENANTS = {
    0x13: dict(mug_anchor=0xBE90, name_anchor=0xBE8C,
               mug_src=0x4D62, name_src=0x4D55, name_bx=3,
               name_hi=0x868C0202, name_lo=0xFFE80003),
    0x10: dict(mug_anchor=0xBE9A, name_anchor=0xBE92,
               mug_src=0x47A0, name_src=0x46AB, name_bx=2,
               name_hi=0x86920102, name_lo=0xFFE80002),
    # 0x11 Pyron (14z-75). Re-derived from vs2's own row 0x11 — mug
    # 0x0B60, name `0B53 0102 FFF0 0002` — plus the +0x4200 bias. Note
    # the lo long is FFF00002, not H's FFE80002: 2-tile plates in this
    # table normally carry xoff -16 and H's -24 is the outlier, so these
    # are vs2's values, not copies of H's row.
    0x11: dict(mug_anchor=0xBE9C, name_anchor=0xBE94,
               mug_src=0x4D60, name_src=0x4D53, name_bx=2,
               name_hi=0x86940102, name_lo=0xFFF00002),
}


def die(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


def block(anchor, bx, by):
    for dy in range(by):
        for dx in range(bx):
            yield cell_at(anchor, dx, dy)


def main():
    # 14z-83 S4: multi-tenant form. Solo invocation (3 positionals) is
    # unchanged; a merged build checks each tenant with --tenant <name>
    # (row from tenants.json) and --gfx-dir <last chain link> (the
    # cumulative group-A members carry every tenant's HUD art).
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("outbase")
    ap.add_argument("data_path")
    ap.add_argument("romdir")
    ap.add_argument("--tenant")
    ap.add_argument("--gfx-dir")
    args = ap.parse_args()
    outbase, data_path, romdir = args.outbase, args.data_path, args.romdir
    out = Path(outbase)
    gfx_dir = Path(args.gfx_dir) if args.gfx_dir else out / "gfx"
    vj = Path(data_path).read_bytes()

    if args.tenant:
        tens = json.loads((out / "patch" / "tenants.json").read_text())
        tj = {t["name"]: t for t in tens}[args.tenant]
    else:
        tj = json.loads((out / "patch" / "tenant.json").read_text())
    TENANT = int(tj["id"])
    if TENANT not in TENANTS:
        die(f"no HUD fact row for tenant id {TENANT:#04x} — measure and "
            f"add it to TENANTS before this build's HUD can be verified")
    T = TENANTS[TENANT]
    MUG_ANCHOR, NAME_ANCHOR = T["mug_anchor"], T["name_anchor"]
    MUG_SRC, NAME_SRC = T["mug_src"], T["name_src"]
    EXPECTED_POKES = {
        MUG_TABLE + 2 * TENANT: ("poke16", MUG_ANCHOR - STAGER_BASE),
        NAME_TABLE + 8 * TENANT: ("poke32", T["name_hi"]),
        NAME_TABLE + 8 * TENANT + 4: ("poke32", T["name_lo"]),
    }

    # 1. vanilla table shapes
    for base, w, name in ((MUG_TABLE, 2, "mugshot"), (NAME_TABLE, 8, "name")):
        if vj[base:base + 16 * w] != vj[base + 16 * w:base + 32 * w]:
            die(f"vanilla {name} table at {base:#x} is not 32-row aliased")
    print("TABLES aliased")

    # 2. the pokes
    patch = json.loads((out / "patch" / "patch.json").read_text())
    ops = patch["ops"] if isinstance(patch, dict) and "ops" in patch else patch
    for addr, (kind, val) in EXPECTED_POKES.items():
        hits = [o for o in ops if o.get("op") == kind
                and int(o.get("addr"), 16) == addr]
        if len(hits) != 1 or int(str(hits[0].get("val")), 16) != val:
            die(f"expected one {kind} at {addr:#x} val {val:#x}, got {hits}")
    print(f"POKES {len(EXPECTED_POKES)}")

    # 3. the art, straight from the members
    ga_built = [open(gfx_dir / f"vm3.{n}m", "rb").read()
                for n in GROUP_A]
    z2 = zipfile.ZipFile(Path(romdir) / "vsav2.zip")
    g2 = [z2.read(f"vs2.{n}m") for n in GROUP_A]
    za = zipfile.ZipFile(Path(romdir) / "vsav.zip")
    gp = [za.read(f"vm3.{n}m") for n in GROUP_A]
    nonblank = 0
    for (src, dst, bx, by, nm) in ((MUG_SRC, MUG_ANCHOR, 2, 2, "mugshot"),
                                   (NAME_SRC, NAME_ANCHOR,
                                    T["name_bx"], 1, "name")):
        for s, d in zip(block(src, bx, by), block(dst, bx, by)):
            want = tile_bytes(g2, 0x10000 + s)
            got = tile_bytes(ga_built, 0x10000 + d)
            if got != want:
                die(f"{nm} tile 0x{d:04X}: built group A differs from vs2 "
                    f"source 0x{s:04X}")
            if hashlib.sha1(want).digest() not in BLANK:
                nonblank += 1
    if not nonblank:
        die("all compared art tiles are blank — the compare proves nothing")
    for c in block(JEDAH_MUG, 2, 2):
        if tile_bytes(ga_built, 0x10000 + c) != tile_bytes(gp, 0x10000 + c):
            die(f"host mugshot cell 0x{c:04X} differs from pristine vsav "
                f"— host de-substitution violated")
    print(f"ART mugshot@{MUG_ANCHOR:#x} name@{NAME_ANCHOR:#x} "
          f"nonblank {nonblank}; host cells pristine")
    print("OK")


if __name__ == "__main__":
    main()
