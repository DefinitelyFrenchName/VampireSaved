#!/usr/bin/env python3
"""enum_biased_lists.py — the #109 site inventory (14z-101 prep).

HONEST LIMITS (read before trusting a row): the head validator is the
census heuristic, and outside anim-shaped data it FALSE-POSITIVES —
hitbox/hitbox_proj "type-4/6/8" rows are hitbox records whose values
look like type words (the 14z-74 census scanned anim spans only for
this reason), and aux-region hits with 0xFFxx "codes" are coordinate
data misread. The composite (type-12) validator is far looser than the
manifest's own enumeration rule ("children all resolve to in-region
lists of a known type"), so ORPHAN-12 counts are an upper bound of
mostly-noise. Filter a row by reading its bytes before acting on it.
First measured run (hui45): 24 covered type-4 children (matches the
takeover comment), 22 UNCOVERED rows of which the hitbox/aux families
are suspect FPs and the anim/x2b7ef4 rows are real review items.

Enumerate every sprite list of a BIASED type (4/6/8) and every composite
(12) across ALL of a tenant's placed regions in the vs2 data view, and
classify each against the existing fix machinery:

  COVERED    type-4 child of a composite that is retyped 000C->0006 in
             the manifest (the takeover body's own vs2-bias strip code
             serves those, and ONLY those)
  UNCOVERED  everything else biased: direct type-4 lists, type-6/8 lists
             anywhere, and NON-type-4 biased children of retyped
             composites (the takeover forwards non-4 children to the
             VANILLA drawer)
  ORPHAN-12  a composite that is NOT retyped (would mis-dispatch on vsav
             if ever drawn)

For each site: address, region, type, count, the raw code span its
entries carry (type 4/6/8 inline or via cptr per format), so the fix's
strip/tile inventory falls straight out.

Usage: enum_biased_lists.py <vs2_data.bin> <placements.json> <manifest.toml>
"""
import json, re, sys

TYPES = {4, 6, 8, 12}

def valid_head(dat, a, f):
    budget = int.from_bytes(dat[a+2:a+4], "big")
    count = int.from_bytes(dat[a+4:a+6], "big")
    cptr = int.from_bytes(dat[a+6:a+10], "big")
    if f == 4:
        return 0 < count + 1 <= budget <= 0x100
    if f in (6, 8):
        return (0 < count + 1 <= budget <= 0x100) and (0x100000 <= cptr < 0x400000)
    if f == 12:
        return 0 < int.from_bytes(dat[a+2:a+4], "big") + 1 <= 0x40
    return False

def codes_of(dat, a, f):
    count = int.from_bytes(dat[a+4:a+6], "big") + 1
    out = []
    if f == 4:                      # +6: count x 8 bytes, (code,attr) first
        for i in range(count):
            out.append(int.from_bytes(dat[a+6+i*8:a+8+i*8], "big"))
    elif f in (6, 8):               # +10: count x long (code, attr)
        for i in range(count):
            out.append(int.from_bytes(dat[a+10+i*4:a+12+i*4], "big"))
    return [c for c in out if c]

def main():
    dat = open(sys.argv[1], "rb").read()
    regions = json.load(open(sys.argv[2]))["regions"]
    mani = open(sys.argv[3]).read()
    retyped = set(int(m, 16) for m in re.findall(
        r'src_addr = (0x[0-9A-Fa-f]+)\s*\nold_hex = "000c"\s*\nnew_hex = "0006"', mani))

    spans = sorted((p["src"], p["src"] + p["len"], name)
                   for name, p in regions.items())
    def region_of(addr):
        for lo, hi, name in spans:
            if lo <= addr < hi:
                return name
        return None

    heads = {}   # addr -> (type, region)
    for lo, hi, name in spans:
        for a in range(lo, hi - 10, 2):
            f = int.from_bytes(dat[a:a+2], "big")
            if f in TYPES and valid_head(dat, a, f):
                heads[a] = (f, name)

    # composite children
    child_of = {}    # child addr -> (composite addr, retyped?)
    for a, (f, name) in heads.items():
        if f != 12:
            continue
        count = int.from_bytes(dat[a+2:a+4], "big") + 1
        for i in range(count):
            ch = int.from_bytes(dat[a+8+i*8:a+12+i*8], "big")
            # heuristic guard: children must land in a placed region
            if region_of(ch):
                child_of.setdefault(ch, (a, a in retyped))

    rows = []
    for a, (f, name) in sorted(heads.items()):
        if f == 12:
            status = "retyped-composite" if a in retyped else "ORPHAN-12"
            rows.append((a, name, f, status, "", 0))
            continue
        cs = codes_of(dat, a, f)
        span = f"{min(cs):#06x}-{max(cs):#06x}" if cs else "-"
        parent = child_of.get(a)
        if f == 4 and parent and parent[1]:
            status = "covered-child"
        elif parent and parent[1]:
            status = f"UNCOVERED (type-{f} child of retyped composite)"
        elif parent:
            status = f"UNCOVERED (child of ORPHAN composite {parent[0]:#x})"
        else:
            status = "UNCOVERED (direct)"
        rows.append((a, name, f, status, span, len(cs)))

    n_cov = sum(1 for r in rows if r[3] == "covered-child")
    n_unc = sum(1 for r in rows if r[3].startswith("UNCOVERED"))
    n_ret = sum(1 for r in rows if r[3] == "retyped-composite")
    n_orp = sum(1 for r in rows if r[3] == "ORPHAN-12")
    print(f"# {len(rows)} sites: {n_ret} retyped composites, {n_orp} orphan composites,")
    print(f"#   {n_cov} covered type-4 children, {n_unc} UNCOVERED biased lists")
    print(f"# retyped rows in manifest: {len(retyped)}")
    print("addr      region      type  status                                    codes         n")
    for a, name, f, status, span, n in rows:
        if f == 12 and status == "retyped-composite":
            continue   # noise; counted above
        print(f"{a:#08x}  {name:10s}  {f:>3}   {status:40s}  {span:13s} {n}")

main()
