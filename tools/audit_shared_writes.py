#!/usr/bin/env python3
"""audit_shared_writes.py — THE SHARED-SURFACE WRITE INVENTORY (14z-79).

WHAT THIS IS FOR. `tests/test_hui_ladder.sh` already encodes the right rule —
every emitted op must write either DECLARED FREE SPACE or a VARIANT ROW
(slot 0x10-0x1F) of a per-character table — but it runs stages 1-3 only. The
row that broke Bulleta was stage 4:

    data_port df_palette_seq_rows -> vsavj 0x39ACC0, 0x80 bytes

Those are palette-seq ids 0x1E-0x21, i.e. BULLETA'S Dark Force block. It wrote
a BASE row of a shared table, shipped in 14z-69, and rendered a legacy
character wrong for ten sessions. Nothing failed, because the invariant that
would have named it stops one stage short of it.

WHY THIS IS AN INVENTORY AND NOT A CLASSIFIER. A classifier needs to know, for
every address in the ROM, whether it is per-character data and which row a
write lands on. We do not have that map, and pretending to have it is how you
get a gate that is confidently wrong: the palette-seq table is indexed by
SEQUENCE id, not by character, so "rows 0x1E/0x1F look like variant rows"
would have waved the defect through. Post-hoc attribution from the generator's
own notes does not work either — measured, the atlas fragment covers only ~30%
of shared writes by exact address.

So the honest mechanism is the one this repo already uses for hazards it can
enumerate but not decide (`test_index_space.sh`'s frozen counts,
`test_manifest_merge.sh`'s frozen collision set): FREEZE THE INVENTORY. Every
write that lands outside free space and outside a known variant row is listed,
per tenant, in `build/manifest/shared_writes.toml`. The gate fails on any
addition, removal or change. That failure is the point: it forces a human to
look at a new shared-surface write and write down why it is safe — which is
the step that was skipped in 14z-69.

WHAT IT CANNOT DO, stated so nobody reads more into a green run: it does not
prove the frozen entries are safe. It proves they were REVIEWED. An entry that
was wrong when it was frozen stays wrong and green — as df_palette_seq_rows
would have, had it been frozen without anyone checking whose rows 0x1E-0x21
are. The gate buys a review checkpoint, not a proof.

Usage:
    python3 tools/audit_shared_writes.py <build-dir> [--json]
    python3 tools/audit_shared_writes.py <build-dir> --freeze <tenant>
"""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def spaces_from(manifest):
    """[[space]] rows -> (start, end) list. Profile-gated spaces included:
    a WIDE build can legitimately use them, and a stock build simply never
    emits into them."""
    out = []
    txt = Path(manifest).read_text()
    for block in txt.split("[[space]]")[1:]:
        row = dict(re.findall(r'^(\w+)\s*=\s*("[^"]*"|0x[0-9A-Fa-f]+|\d+)',
                              block, re.M))
        if "start" in row and "end" in row:
            out.append((int(row["start"].strip('"'), 0),
                        int(row["end"].strip('"'), 0)))
    return out


def variant_tables():
    """Per-character tables from bank_map.toml, as (base, entry_size).

    A `kind = "auto"` row GRANTS NO EXEMPTION (14z-128). "auto" means the
    scanner discovered a per-character region and nothing measured its entry
    size, so its `stride` is the scan default rather than a fact — and the
    exemption this function computes is `base + 0x10*es .. base + 0x20*es`,
    which is only the variant half if `es` is right.

    MEASURED, and this is why the rule exists rather than being a scruple.
    `gap_be27a` is declared `kind = "auto"`, `stride = 0x40`, so es came out
    2 and the exempt window was 0x0BE29A-0x0BE2BA. The table is the CAPTURE-
    KEYFRAME POINTER TABLE and its entries are LONGWORDS — three independent
    ways: bank_map's own note calls it "the 32-LONG capture-keyframe pointer
    table", donovan.toml's `slot_ptr_table = 0xBE27A` places row 0x00 at
    0xBE27A and row 0x01 at 0xBE27E, and the values written are 32-bit ROM
    pointers. So es is 4, the real variant half is 0x0BE2BA-0x0BE2FA, and
    that window was exempting LONGWORD ROWS 0x08-0x0F — Bishamon, Aulbath,
    Sasquatch, 0x0B, Q-Bee, Lei-Lei, Lilith and Jedah. LEGACY rows, in the
    one gate whose whole purpose is to make a legacy-surface write a
    build-time review. Eight writes per tenant build sat inside it (the #104
    capture-pose port, 14z-99) and never reached the inventory.

    Nothing shipped unreviewed through the hole — that work is maintainer-
    ruled and locked by audit_don_grab_pose.sh — but the gate that exists to
    force the review was blind to it, which is the same shape as the defect
    the gate was built for (the Bulleta DF block, 14z-69).

    The ROOT cause is the bank_map row, not this function: `gap_be27a` +
    `gap_be2ba` model one 32-long table as two 0x40 halves, which also makes
    the generated character-data pages read both rows at the wrong address.
    Correcting it moves `kind`, and `kind` is load-bearing in
    extract_char.py and gen_donovan_patch.py, so it can move BUILD OUTPUT —
    a measured change of its own, recorded in STATE for the maintainer. This
    function is the containment: an unmeasured stride now exempts nothing,
    so being wrong is safe and loud ([VSP-22]).
    """
    out = []
    txt = (ROOT / "build/manifest/bank_map.toml").read_text()
    for block in txt.split("[[table]]")[1:]:
        row = dict(re.findall(r'^(\w+)\s*=\s*("[^"]*"|0x[0-9A-Fa-f]+|\d+)',
                              block, re.M))
        if "vsavj" not in row:
            continue
        kind = row.get("kind", '""').strip('"')
        if kind == "auto":
            continue
        base = int(row["vsavj"].strip('"'), 0)
        if kind == "byte2d":
            es = int(row["span"].strip('"'), 0) // 32
        else:
            es = int(row.get("stride", '"0x80"').strip('"'), 0) // 32
        out.append((row.get("name", '"?"').strip('"'), base, es))
    return out


def op_len(pdir, o):
    k = o["op"]
    if k == "poke16":
        return 2
    if k == "poke32":
        return 4
    if "hex" in o:
        return len(o["hex"]) // 2
    return (pdir / o["path"]).stat().st_size


def inventory(build_dir):
    pdir = Path(build_dir) / "patch"
    ops = json.load(open(pdir / "patch.json"))["ops"]
    # the build's own manifest is not recorded in patch.json, so take the
    # union of every tenant manifest's spaces — a write inside ANY declared
    # free space is not shared surface. The three manifests declare the same
    # three spaces, so this is exact rather than permissive today; if they
    # ever diverge, the union is still the correct question ("did this land
    # in space the allocator owns?").
    sp = []
    for m in ("donovan", "huitzil", "pyron"):
        p = ROOT / f"build/manifest/{m}.toml"
        if p.exists():
            sp += spaces_from(p)
    tabs = variant_tables()
    out = []
    for o in ops:
        a = int(o["addr"], 0)
        n = op_len(pdir, o)
        if any(s <= a and a + n <= e for s, e in sp):
            continue
        hit = next((nm for nm, base, es in tabs
                    if base + 0x10 * es <= a and a + n <= base + 0x20 * es),
                   None)
        if hit:
            continue
        out.append({"addr": f"0x{a:06x}", "len": n, "op": o["op"]})
    out.sort(key=lambda r: (int(r["addr"], 16), r["len"]))
    return out


def load_frozen():
    p = ROOT / "build/manifest/shared_writes.toml"
    if not p.exists():
        return {}
    txt = p.read_text()
    frozen = {}
    for block in txt.split("[[tenant]]")[1:]:
        m = re.search(r'^name\s*=\s*"([^"]+)"', block, re.M)
        if not m:
            continue
        rows = re.findall(r'^\s*"(0x[0-9a-f]+)\s+(\d+)\s+(\w+)"', block, re.M)
        frozen[m.group(1)] = [{"addr": a, "len": int(l), "op": k}
                              for a, l, k in rows]
    return frozen


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("build_dir")
    ap.add_argument("--tenant", help="name to compare against the frozen set")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    inv = inventory(a.build_dir)
    if a.json:
        print(json.dumps(inv, indent=2))
        return 0

    print(f"{a.build_dir}: {len(inv)} shared-surface writes "
          f"(outside declared free space, outside any known variant row)")
    for r in inv:
        print(f'  "{r["addr"]} {r["len"]} {r["op"]}"')

    if not a.tenant:
        return 0
    frozen = load_frozen().get(a.tenant)
    if frozen is None:
        print(f"\nFAIL: no frozen inventory for tenant '{a.tenant}' in "
              f"build/manifest/shared_writes.toml")
        return 1
    key = lambda r: (r["addr"], r["len"], r["op"])
    now, was = {key(r) for r in inv}, {key(r) for r in frozen}
    added, gone = sorted(now - was), sorted(was - now)
    if not added and not gone:
        print(f"\nok: matches the frozen inventory for '{a.tenant}' "
              f"({len(inv)} writes)")
        return 0
    for k in added:
        print(f"\nFAIL: NEW shared-surface write {k[0]} +{k[1]} ({k[2]})")
    for k in gone:
        print(f"\nFAIL: shared-surface write GONE {k[0]} +{k[1]} ({k[2]})")
    print("\n  A shared-surface write lands on bytes the VANILLA game may read.")
    print("  Before adding it to build/manifest/shared_writes.toml, establish")
    print("  WHOSE bytes those are — the 14z-69 DF-palette row wrote rows that")
    print("  turned out to be Bulleta's Dark Force block, and shipped for ten")
    print("  sessions. Record the answer in the row's `why`.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
