#!/usr/bin/env python3
"""audit_region_overlap.py — can the tenants' shared source spans be placed ONCE?

M3b Phase 2 item 2 says: "key regions by (src_set, src_addr, len); a shared
span is placed ONCE and all tenants' relocations resolve through the shared
placement." This tool measures whether that is achievable, because the answer
decides the shape of the whole region-identity slice.

THE THREE CLASSES, straight from the extractions:

  SHARED SPAN     the same (src, len) under the same name in more than one
                  extraction — a candidate for placing once.
  NAME COLLISION  the same NAME with different spans. Two sub-kinds, and they
                  want opposite treatment: the generic names (`anim`, `code`,
                  `hitbox`, `aux0_*`) are each tenant's OWN region and need
                  per-tenant NAMESPACING, while `x088512` is one source region
                  extracted at three different EXTENTS.
  UNIQUE          declared by one tenant only.

THE MEASUREMENT THAT MATTERS is not whether the spans match — it is whether
the tenants' emitted BLOBS can be reconciled. Each tenant's generator run
rewrites pointers inside a shared region to reach that tenant's own placed
regions, so the blobs differ by construction. Per byte, across three tenants:

  agree        all three identical — untouched, or touched identically
  1-differs    exactly one tenant differs: its own row/field in a per-character
               table. Disjoint, so a union is well defined.
  CONFLICT     two or more disagree at the SAME byte: one field, several
               tenants, and only one value can ship. A union is NOT defined
               here; the merge needs per-tenant copies or a per-character
               indirection at that field.

PLACEMENT MUST BE NORMALISED OUT FIRST, and this is the trap the tool exists
to avoid. The three reference builds are independent single-tenant builds, so
each allocator puts regions at its own addresses; a pointer into a SHARED
region then reads as a conflict when a merged build would resolve it to one
address. Un-relocating every word that lands inside a placed region back to
the SOURCE address it came from removes exactly that artefact. Measured
14z-77 on the three frozen builds: it drops the count from 7,591 to 2,000 —
**74% of the raw figure is the artefact**, so an un-normalised number is not
merely imprecise, it is wrong. `--no-normalise` exists only to demonstrate
that, never to produce a verdict.

Usage: audit_region_overlap.py <extract_or_build_dir>...  [--json]
  Each argument is a build dir (containing patch/ and extract/) or an extract
  dir. Blob comparison needs build dirs; span classification needs only
  extracts.
"""
import argparse
import json
import sys
from collections import Counter
from pathlib import Path


def load_regions(d):
    for cand in (Path(d, "extract", "regions.json"), Path(d, "regions.json")):
        if cand.is_file():
            return json.loads(cand.read_text())
    raise SystemExit(f"no regions.json under {d}")


def patch_dir(d):
    p = Path(d, "patch")
    return p if p.is_dir() else None


def classify_spans(mans):
    """-> (shared, name_clash, unique) over {owner: regions.json}."""
    names = {}
    for who, j in mans.items():
        for n, r in j["regions"].items():
            names.setdefault(n, {})[who] = (r["src"], r["len"])
    shared, clash, unique = [], [], []
    for n, byw in sorted(names.items()):
        if len(byw) == 1:
            unique.append((n, byw))
        elif len(set(byw.values())) == 1:
            shared.append((n, byw))
        else:
            clash.append((n, byw))
    return shared, clash, unique


def unreloc_ranges(build):
    """(dst_lo, dst_hi, src) per placed region — the un-relocation map."""
    pl = json.loads(Path(build, "patch", "placements.json").read_text())
    return [(r["dst"], r["dst"] + r["len"], r["src"])
            for r in pl["regions"].values()]


def normalise(blob, ranges):
    """Rewrite each 4-byte word pointing INTO a placed region back to its
    source address. Placement is per-build and arbitrary; the source address
    is the tenant-independent identity of the thing pointed at."""
    out = bytearray(blob)
    for i in range(len(blob) - 3):
        v = int.from_bytes(blob[i:i + 4], "big")
        for lo, hi, src in ranges:
            if lo <= v < hi:
                out[i:i + 4] = (src + (v - lo)).to_bytes(4, "big")
                break
    return bytes(out)


def compare_blobs(name, builds, ranges):
    """-> dict(common, agree, solo, conflict, first_conflict) or None."""
    bl = {}
    for who, b in builds.items():
        p = Path(b, "patch", f"fixed_{name}.bin")
        if p.is_file():
            bl[who] = normalise(p.read_bytes(), ranges[who])
    if len(bl) < 3:
        # With two tenants "exactly one differs" is indistinguishable from
        # "both disagree", so the classification is not defined. Say so
        # rather than reporting a reassuring zero.
        return {"owners": sorted(bl), "undecidable": len(bl) == 2}
    m = min(len(v) for v in bl.values())
    ws = sorted(bl)
    agree = solo = conflict = 0
    first = None
    for i in range(m):
        vals = [bl[w][i] for w in ws]
        if len(set(vals)) == 1:
            agree += 1
            continue
        c = Counter(vals)
        if len(vals) - c.most_common(1)[0][1] == 1 and len(set(vals)) == 2:
            solo += 1
        else:
            conflict += 1
            if first is None:
                first = i
    return {"owners": ws, "common": m, "agree": agree, "solo": solo,
            "conflict": conflict, "first_conflict": first,
            "undecidable": False}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dirs", nargs="+", type=Path)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--no-normalise", action="store_true",
                    help="skip placement normalisation — for the CONTROL that "
                         "proves normalising is load-bearing, never for a "
                         "verdict (it reports the artefact as conflicts)")
    args = ap.parse_args()

    mans, builds = {}, {}
    for d in args.dirs:
        j = load_regions(d)
        who = j.get("char_name") or d.name
        mans[who] = j
        if patch_dir(d):
            builds[who] = d
    shared, clash, unique = classify_spans(mans)

    report = {"owners": sorted(mans), "shared": [], "name_clash": [],
              "unique": [n for n, _ in unique], "blobs": {}}
    for n, byw in shared:
        s, l = next(iter(byw.values()))
        report["shared"].append({"name": n, "src": s, "len": l,
                                 "owners": sorted(byw)})
    for n, byw in clash:
        report["name_clash"].append(
            {"name": n, "spans": {w: list(v) for w, v in sorted(byw.items())}})

    ranges = {w: ([] if args.no_normalise else unreloc_ranges(b))
              for w, b in builds.items()}
    for n, _ in shared:
        r = compare_blobs(n, builds, ranges)
        if r:
            report["blobs"][n] = r
    report["total_conflict"] = sum(
        v.get("conflict", 0) for v in report["blobs"].values())

    if args.json:
        print(json.dumps(report, indent=1))
        return 0

    print(f"owners: {', '.join(report['owners'])}")
    print(f"\nSHARED SPANS (same name, same src+len) — {len(shared)}")
    for e in report["shared"]:
        print("  %-12s src=0x%06x len=0x%05x  %s"
              % (e["name"], e["src"], e["len"], "+".join(e["owners"])))
    print(f"\nNAME COLLISIONS (same name, different span) — {len(clash)}")
    for e in report["name_clash"]:
        kind = ("same start, different EXTENT"
                if len({v[0] for v in e["spans"].values()}) == 1
                else "per-tenant region sharing a generic name")
        print("  %-12s %s" % (e["name"], kind))
        for w, (s, l) in e["spans"].items():
            print("       %-9s src=0x%06x len=0x%05x" % (w, s, l))
    print(f"\nUNIQUE TO ONE TENANT — {len(unique)}")

    if report["blobs"]:
        print("\nBLOB RECONCILIATION on shared spans (placement normalised):")
        print("  %-12s %8s %9s %9s  %s"
              % ("region", "common", "1-differs", "CONFLICT", "note"))
        for n, v in report["blobs"].items():
            if v.get("undecidable"):
                print("  %-12s %8s %9s %9s  only %s — 2 tenants cannot be "
                      "classified" % (n, "-", "-", "-", "+".join(v["owners"])))
                continue
            note = ("" if not v["conflict"]
                    else "first +0x%x" % v["first_conflict"])
            print("  %-12s 0x%06x %9d %9d  %s"
                  % (n, v["common"], v["solo"], v["conflict"], note))
        print("\nTOTAL CONFLICTING BYTES: %d" % report["total_conflict"])
        if report["total_conflict"]:
            print("\n  A shared span with conflicting bytes CANNOT be placed "
                  "once by dedup:\n  two tenants write different values to "
                  "the same field, and only one\n  can ship. The merge needs "
                  "a per-tenant copy of that region, or a\n  per-character "
                  "indirection at each conflicting field.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
