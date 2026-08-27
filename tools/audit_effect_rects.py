#!/usr/bin/env python3
"""audit_effect_rects.py — every multi-tile OBJ block a tenant draws must hold
the DONOR'S OWN RECTANGLE at its destination.  (GitHub #112, 14z-112.)

STATUS (14z-112): A MEASUREMENT INSTRUMENT, **NOT YET A GATE.**  Its verdict
logic is ground-truthed (5/5 against hand measurements), but its PREMISE —
that a tenant block's destination should hold the donor's rectangle — only
holds for tiles THE PORT ACTUALLY WROTE.  Its first real run reported 1623 of
2777 blocks "corrupt", which the stock comparison explains: the merged build's
window `0xa000-0xffff` is byte-identical to stock vsavj (24576/24576 tiles),
so those blocks draw VANILLA art, and vsavj and vsav2 lay their shared engine
art out differently — the test was measuring that difference, not a defect.
Pass `--stock` so stock-art blocks are classified separately instead of being
reported as corruption; only PORT-WRITTEN blocks are audited.  Do not wire
this into a runner as a pass/fail gate until the population question is
settled.

WHY THIS EXISTS.  The records that draw tenant sprites are STOCK vsavj data —
byte-identical to the reference (measured: `vm3j.08a` differs in 0 of 524288
bytes).  The port never rewrites them; it places the tenant's art AT the tile
codes those host records already reference.  A CPS-2 block of `w x h` tiles
draws `code + r*0x10 + c`, so a multi-tile block is only correct if the
donor's rectangle was laid into the destination rectangle TILE FOR TILE.  The
#112 "Press of Death turns black mid-move" was exactly this: of the 14 blocks
in one record, 11 were placed perfectly and 3 were not — the 2x8 block had
1 of its 16 tiles right, and the other 15 held real but FOREIGN donor art, so
the foot drew as recognisable shapes filled with the wrong pixels.

WHAT IT CHECKS.  For each observed block `(code, w, h)`:
    donor_of(ours[code + r*0x10 + c]) == donor_of(ours[code]) + r*0x10 + c
for every r,c — i.e. the destination rectangle is a translated copy of one
donor rectangle.  Tiles are matched BY CONTENT (128-byte hash), never by
arithmetic: the band-delta inversion was falsified and the effect shelf packs
non-contiguously, so only content matching is admissible here.

INPUTS (all produced by tests/lua/inp_probe.lua, see test_effect_rects.sh):
  --ours    <file>   "<tile_hex> <hash>" per line, the build under test
  --donor   <file>   same, one per donor romset (repeatable)
  --blocks  <file>   "BLK <code> <w> <h> <attr> <frame>" lines, repeatable
  --known   <file>   optional: blocks already known-bad (one "code w h" per
                     line, '#' comments).  Listed blocks are reported but do
                     not fail the audit, so the gate catches NEW breakage and
                     any change to a known one while a fix is pending.

AMBIGUITY IS HANDLED HONESTLY.  A hash can match several donor tiles (blank
and flat-fill tiles repeat).  A block PASSES if ANY candidate donor base
reproduces the whole rectangle; it is reported UNMAPPED (not failed) when its
base tile matches no donor tile at all, because that is a coverage gap in the
donor scan rather than evidence of corruption.
"""

import argparse
import collections
import sys


def load_hashes(path):
    """-> {tile_index: hash} from '<tile_hex> <hash>' lines."""
    out = {}
    with open(path) as fh:
        for line in fh:
            parts = line.split()
            if len(parts) == 2:
                out[int(parts[0], 16)] = parts[1]
    return out


def load_blocks(paths):
    """-> sorted list of distinct (code, w, h) from BLK lines."""
    seen = {}
    for p in paths:
        with open(p) as fh:
            for line in fh:
                if not line.startswith("BLK "):
                    continue
                f = line.split()
                code, w, h = int(f[1], 16), int(f[2]), int(f[3])
                if w * h > 1:
                    seen[(code, w, h)] = seen.get((code, w, h), 0) + 1
    return sorted(seen), seen


def load_known(path):
    known = set()
    if not path:
        return known
    with open(path) as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            f = line.split()
            known.add((int(f[0], 16), int(f[1]), int(f[2])))
    return known


def audit(ours, donors, blocks, stock=None):
    """-> (results, stats).  results: list of dicts, one per block."""
    # hash -> [(donor_name, index), ...]
    by_hash = collections.defaultdict(list)
    for name, table in donors.items():
        for idx, h in table.items():
            by_hash[h].append((name, idx))

    results = []
    for code, w, h in blocks:
        base_hash = ours.get(code)
        if base_hash is None:
            results.append(dict(code=code, w=w, h=h, state="OURS-MISSING"))
            continue
        if stock is not None and stock.get(code) == base_hash:
            # the port never wrote this tile: it is host art, and the
            # donor-rectangle premise does not apply to it.
            results.append(dict(code=code, w=w, h=h, state="STOCK-ART"))
            continue
        candidates = by_hash.get(base_hash, [])
        if not candidates:
            results.append(dict(code=code, w=w, h=h, state="UNMAPPED"))
            continue

        best = None
        for dname, dbase in candidates:
            good, misses = 0, []
            for r in range(h):
                for c in range(w):
                    ot = ours.get(code + r * 0x10 + c)
                    want = dbase + r * 0x10 + c
                    hit = ot is not None and (dname, want) in by_hash.get(ot, [])
                    if hit:
                        good += 1
                    elif len(misses) < 4:
                        misses.append((code + r * 0x10 + c, want))
            if best is None or good > best[0]:
                best = (good, w * h, dname, dbase, misses)
            if good == w * h:
                break

        good, total, dname, dbase, misses = best
        results.append(dict(code=code, w=w, h=h, state="OK" if good == total else "CORRUPT",
                            good=good, total=total, donor=dname, dbase=dbase,
                            misses=misses))
    return results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ours", required=True)
    ap.add_argument("--donor", action="append", required=True,
                    help="name=path (repeatable)")
    ap.add_argument("--blocks", action="append", required=True)
    ap.add_argument("--known")
    ap.add_argument("--stock", help="hash map of the STOCK romset: blocks whose "
                    "tiles the port never wrote are classified STOCK-ART and "
                    "not audited (their art is the host's, so the donor-"
                    "rectangle premise does not apply)")
    ap.add_argument("--max-report", type=int, default=25)
    ap.add_argument("--min-coverage", type=float, default=0.60,
                    help="fail if fewer than this fraction of observed blocks "
                         "could be resolved against a donor (default 0.60)")
    args = ap.parse_args()

    ours = load_hashes(args.ours)
    donors = {}
    for spec in args.donor:
        name, path = spec.split("=", 1)
        donors[name] = load_hashes(path)
    blocks, counts = load_blocks(args.blocks)
    known = load_known(args.known)

    print(f"ours: {len(ours)} tiles; donors: "
          + ", ".join(f"{n} {len(t)}" for n, t in donors.items())
          + f"; blocks observed: {len(blocks)}")

    stock = load_hashes(args.stock) if args.stock else None
    results = audit(ours, donors, blocks, stock)
    state = collections.Counter(r["state"] for r in results)
    corrupt = [r for r in results if r["state"] == "CORRUPT"]
    new_corrupt = [r for r in corrupt if (r["code"], r["w"], r["h"]) not in known]
    stale_known = known - {(r["code"], r["w"], r["h"]) for r in corrupt}

    print(f"  OK {state['OK']}   CORRUPT {state['CORRUPT']}"
          f"   UNMAPPED {state['UNMAPPED']}   OURS-MISSING {state['OURS-MISSING']}"
          f"   STOCK-ART {state['STOCK-ART']}")

    if corrupt:
        print(f"\nCORRUPT BLOCKS ({len(corrupt)}; {len(new_corrupt)} not in --known):")
        for r in sorted(corrupt, key=lambda r: (r["good"] / r["total"], -r["total"]))[:args.max_report]:
            tag = "" if (r["code"], r["w"], r["h"]) in known else "  <-- NEW"
            print(f"  {r['code']:#06x} {r['w']}x{r['h']:<3} {r['good']:>3}/{r['total']:<3}"
                  f" donor {r['donor']} base {r['dbase']:#07x}{tag}")
            for slot, want in r["misses"][:2]:
                got = "unplaced"
                print(f"      slot {slot:#06x} should hold donor {want:#07x}")
        if len(corrupt) > args.max_report:
            print(f"  ... {len(corrupt) - args.max_report} more not shown "
                  f"(raise --max-report to see them)")

    if stale_known:
        print(f"\nSTALE --known entries (listed but NOT corrupt any more — "
              f"remove them once the fix lands): "
              + ", ".join(f"{c:#06x} {w}x{h}" for c, w, h in sorted(stale_known)))

    # COVERAGE IS PART OF THE VERDICT (RH-25): an audit whose inputs did not
    # line up would otherwise report "0 corrupt" and pass while measuring
    # nothing.  Demand that most observed blocks were actually resolved.
    measured = state["OK"] + state["CORRUPT"]
    auditable = len(blocks) - state["STOCK-ART"]
    coverage = measured / auditable if auditable else 0.0
    print(f"  coverage: {measured}/{auditable} auditable blocks resolved ({coverage:.0%})"
          + (f"; {state['STOCK-ART']} skipped as host art" if stock else "; --stock NOT given, host-art blocks are NOT excluded"))
    if not auditable:
        print("\nNOTE: every observed block is host art — nothing to audit on this build")
        return 0
    if not blocks:
        print("\nFAIL audit_effect_rects — no blocks observed (harvest produced nothing)")
        return 1
    if coverage < args.min_coverage:
        print(f"\nFAIL audit_effect_rects — only {coverage:.0%} of blocks resolved, "
              f"below --min-coverage {args.min_coverage:.0%}: the inputs do not line up "
              f"(wrong hash map, wrong build, or a donor scan that is too narrow), "
              f"so a clean result here would be meaningless")
        return 1

    ok = not new_corrupt
    print("\nPASS audit_effect_rects" if ok else
          f"\nFAIL audit_effect_rects — {len(new_corrupt)} corrupt block(s) not declared in --known")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
