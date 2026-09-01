#!/usr/bin/env python3
"""anim_reloc_audit.py — are a tenant's PLACED anim chains fully relocated?

  python3 tools/anim_reloc_audit.py build/<tenant> [--json out.json]

Walks every per-character anim INDEX TABLE of a tenant build with
`tools/anim_nodes.py` (the audited walker — never a reimplementation) and
classifies every node's sprite-record pointer:

  placed            inside the PLACED anim region      — correct
  in_source_range   inside the tenant's vs2 SOURCE range — UNRELOCATED, the
                    defect: on vsavj that address holds unrelated vanilla
                    data, so the move draws vanilla art and never faults
  outside_placed    neither — REPORTED, NOT ASSERTED (see below)

ONLY `in_source_range` IS A VERDICT. `outside_placed` is dominated by WALK
OVERRUN, not by defects: the walker takes a seq count that overruns some
tables' real per-character entry count, so it follows word offsets into
unrelated data and reports "nodes" that are not nodes (Huitzil's
`anim_index_c`: 69 of 139 chains end `out_of_region`, with "sprites" like
`0x159a15fa` on nodes reading dur 0 / flags 0). That is [VSP-70]'s shape — an
index past a word-displacement table's end is the next thing's data — and it
is a property of the INSTRUMENT, not of the build. The source-range check is
unaffected and stays conservative: it scans every node the walker emits,
garbage included, so a real unrelocated pointer cannot hide in a bad chain.

THE 24-BIT MASK. The sprite field's top byte carries FLAGS (`0x010E4C7C`,
`0x020F10B8` occur on real Donovan nodes). 68k addresses are 24 bits, so
every pointer is masked `& 0xFFFFFF` before classification. Skipping the mask
reports three legitimate nodes as wild pointers — measured 14z-126b, and it
was the measurement that was wrong ([VSP-148]).

Reads `patch/placements.json` (the anim region's src/dst/len) and
`extract/regions.json` (the `anim_index_*` table pointers, which are SOURCE
addresses and are mapped through the same delta). Prints a one-line summary
per table and a totals line; `--json` emits the machine-readable verdict used
by `tests/test_tenant_anim_relocation.sh`.
"""
import argparse, json, subprocess, sys, tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def anim_tables(regions):
    """every {'table': 'anim_index_*', 'ptr': '0x...'} row, at any depth"""
    out = []
    def walk(o):
        if isinstance(o, dict):
            t = o.get("table", "")
            if isinstance(t, str) and t.startswith("anim_index") and "ptr" in o:
                out.append((t, int(str(o["ptr"]), 16)))
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)
    walk(regions)
    return sorted(set(out))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("build")
    ap.add_argument("--json")
    a = ap.parse_args()
    B = Path(a.build)
    img = B / "verify_data.bin"
    place = json.load(open(B / "patch" / "placements.json"))["regions"]["anim"]
    src, dst, ln = place["src"], place["dst"], place["len"]
    tables = anim_tables(json.load(open(B / "extract" / "regions.json")))
    if not tables:
        print(f"{B.name}: no anim_index_* rows in extract/regions.json", file=sys.stderr)
        return 2

    total = placed = 0
    in_src, outside, first_node = [], [], None
    with tempfile.TemporaryDirectory() as tmp:
        for name, sptr in tables:
            if not (src <= sptr < src + ln):
                continue                       # a table outside the anim region
            placed_tbl = dst + (sptr - src)
            out = Path(tmp) / f"{name}.json"
            r = subprocess.run(
                [sys.executable, str(REPO / "tools" / "anim_nodes.py"), str(img),
                 "--base", "0", "--table", hex(placed_tbl),
                 "--end", hex(dst + ln), "--json", str(out)],
                capture_output=True, text=True)
            if r.returncode != 0 or not out.exists():
                print(f"{B.name}: anim_nodes.py failed on {name} @ {placed_tbl:#x}\n"
                      f"{r.stderr[:400]}", file=sys.stderr)
                return 2
            d = json.load(open(out))
            n_t = n_p = 0
            for ch in d.get("chains", {}).values():
                for node in ch.get("nodes", []):
                    sp = node.get("sprite")
                    if sp is None:
                        continue
                    v = (int(sp, 16) if isinstance(sp, str) else sp) & 0xFFFFFF
                    if v == 0:
                        continue
                    total += 1; n_t += 1
                    if first_node is None:
                        first_node = int(str(node["addr"]), 16)
                    if dst <= v < dst + ln:
                        placed += 1; n_p += 1
                    elif src <= v < src + ln:
                        in_src.append(v)
                    else:
                        outside.append(v)
            print(f"{B.name} {name:<16} table {placed_tbl:#08x}  "
                  f"{n_p}/{n_t} pointers relocated")

    verdict = dict(build=B.name, src=src, dst=dst, len=ln, total=total, placed=placed,
                   in_source_range=sorted(set(in_src)), outside_placed=sorted(set(outside)),
                   first_node=first_node)
    print(f"{B.name}: {placed}/{total} relocated · "
          f"{len(set(in_src))} UNRELOCATED (the verdict) · "
          f"{len(set(outside))} outside (walk overrun, not asserted)")
    if a.json:
        if a.json == "/dev/stdout":
            print(json.dumps(verdict))
        else:
            Path(a.json).write_text(json.dumps(verdict, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
