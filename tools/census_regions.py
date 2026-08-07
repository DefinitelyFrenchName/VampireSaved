#!/usr/bin/env python3
"""census_regions.py — the two structural censuses over an extraction's
code-kind regions (14z-66 mechanisms, promoted to a tool for the D4
step-2 Pyron early warning; STATE 14z-66 watch item).

Census 1 — [[data_in_code]] candidates: a small DATA table embedded in
a CODE region. If the region is placed in the crypt hole its bytes are
stored re-encrypted, so runtime DATA READS of the table see garbage
(the FG capture-pose crash class, 3 paid debugging arcs). Shape scanned
(the exact shape gen_donovan_patch.py's reroute supports):

    lea (d16,pc),An        (w  & 0xF1FF) == 0x41FA
    move.{b,w,l} (An,Xn.w) (w2 & 0x0038) == 0x0030, reg == An,
                           size field in {1,2,3}

with the lea target landing INSIDE a code-kind region of the same
extraction. Every such site needs a [[data_in_code]] manifest row
before that region may be crypt-placed.

Census 2 — [[pcrel_escape_fix]] escapes: word-form pcrel branches
(bra/bsr/Bcc.w: (w & 0xF000) == 0x6000, low byte 0) whose target lies
OUTSIDE the region span. Invisible to the sibling oracle (both
siblings preserve spacing) and unrewritable in place; a cloned or
relocated region executing one branches into unrelated bytes (the
x02592a anim freeze, the x026142 air-dash death). Regions with escapes
need a [[pcrel_escape_fix]] row (trampoline pad) or their escapes
individually accounted for.

BOTH sweeps are linear pattern scans over code bytes: data words can
pattern-match (false positives are possible, silence is meaningful,
hits need triage). The instrument is ground-truthed against the known
Huitzil inventory in tests/test_census_regions.sh before its numbers
are trusted for any other tenant.

Usage:
  census_regions.py <extract_dir> [--manifest build/manifest/x.toml]
                    [--json out.json]

Prints per-region findings and totals; --manifest marks findings
already covered by data_in_code/pcrel_escape_fix rows. Exit 0 always
(census, not gate — wrap in a test to freeze expectations).
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _minitoml import loads as toml_loads  # noqa: E402


def in_dead(off, dead):
    return any(a <= off < b for a, b in dead)


def scan_data_in_code(name, blob, src, dead, code_spans):
    """lea(d16,pc),An + read (An,Xn.w) with target inside a code region."""
    hits = []
    for i in range(0, len(blob) - 8, 2):
        if in_dead(i, dead):
            continue
        w = int.from_bytes(blob[i:i + 2], "big")
        if (w & 0xF1FF) != 0x41FA:
            continue
        an = (w >> 9) & 7
        w2 = int.from_bytes(blob[i + 4:i + 6], "big")
        if (w2 & 0x0038) != 0x0030 or (w2 & 7) != an \
                or (w2 >> 12) not in (1, 2, 3):
            continue
        disp = int.from_bytes(blob[i + 2:i + 4], "big", signed=True)
        tgt = src + i + 2 + disp
        host = next((n for n, (lo, hi) in code_spans.items()
                     if lo <= tgt < hi), None)
        if host is None:
            continue
        hits.append({"reader": src + i, "table": tgt, "table_host": host,
                     "reader_old_hex": blob[i:i + 8].hex()})
    return hits


def scan_escapes(name, blob, src, dead):
    """word-form pcrel branches leaving the region (generator's sweep)."""
    escapes = []
    i = 0
    while i + 4 <= len(blob):
        w = int.from_bytes(blob[i:i + 2], "big")
        if (w & 0xF000) == 0x6000 and (w & 0xFF) == 0:
            if not in_dead(i, dead):
                disp = int.from_bytes(blob[i + 2:i + 4], "big", signed=True)
                tgt = src + i + 2 + disp
                if not (src <= tgt < src + len(blob)):
                    escapes.append({"site": src + i, "opcode": w,
                                    "target": tgt})
            i += 4
            continue
        i += 2
    return escapes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("extract_dir")
    ap.add_argument("--manifest", help="tenant manifest toml; marks "
                    "findings already covered by rows")
    ap.add_argument("--json", help="write findings JSON")
    args = ap.parse_args()

    meta = json.load(open(os.path.join(args.extract_dir, "regions.json")))
    regions = meta["regions"]
    covered_readers, covered_escape_regions = set(), set()
    if args.manifest:
        man = toml_loads(open(args.manifest).read())
        covered_readers = {int(str(dc["reader"]), 0)
                           for dc in man.get("data_in_code", [])}
        covered_escape_regions = {pf["region"]
                                  for pf in man.get("pcrel_escape_fix", [])}

    code_spans = {n: (v["src"], v["src"] + v["len"])
                  for n, v in regions.items() if v["kind"] == "code"}
    out = {"src_set": meta.get("src_set"), "char": meta.get("char"),
           "code_regions": sorted(code_spans),
           "data_in_code": [], "escapes": {}}
    tot_dc = tot_dc_unc = tot_esc = 0
    for name, (lo, hi) in sorted(code_spans.items(), key=lambda kv: kv[1]):
        v = regions[name]
        blob = open(os.path.join(args.extract_dir,
                                 f"region_{name}.bin"), "rb").read()
        assert len(blob) == v["len"], f"{name}: bin/len mismatch"
        dead = [tuple(d) for d in v.get("dead", [])]

        dc = scan_data_in_code(name, blob, lo, dead, code_spans)
        for h in dc:
            h["region"] = name
            h["covered"] = h["reader"] in covered_readers
            out["data_in_code"].append(h)
            tot_dc += 1
            if not h["covered"]:
                tot_dc_unc += 1
            print(f"  data_in_code {name}+{h['reader']-lo:#06x}: reader "
                  f"{h['reader']:#08x} -> table {h['table']:#08x} "
                  f"(in {h['table_host']})"
                  + ("  [covered]" if h["covered"] else "  [UNCOVERED]"))

        esc = scan_escapes(name, blob, lo, dead)
        if esc:
            uniq = sorted({e["target"] for e in esc})
            cov = name in covered_escape_regions
            out["escapes"][name] = {"count": len(esc),
                                    "unique_targets": uniq, "covered": cov}
            tot_esc += len(esc)
            print(f"  escapes {name}: {len(esc)} sites -> "
                  f"{len(uniq)} unique targets "
                  f"({', '.join(hex(t) for t in uniq[:8])}"
                  f"{'...' if len(uniq) > 8 else ''})"
                  + ("  [covered]" if cov else "  [UNCOVERED]"))

    print(f"census: {tot_dc} data_in_code sites ({tot_dc_unc} uncovered), "
          f"{tot_esc} escape sites in {len(out['escapes'])} regions "
          f"over {len(code_spans)} code regions")
    if args.json:
        json.dump(out, open(args.json, "w"), indent=1)
        print(f"wrote {args.json}")


if __name__ == "__main__":
    main()
