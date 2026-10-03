#!/usr/bin/env python3
"""cpu_soak_dist.py — what a CPU fighter DOES over a long window, as distributions, for
comparing a tenant CPU on our build with the same character's CPU on native vsav2
(GitHub #129, 14z-189; the gate is tests/audit_tenant_cpu_soak.sh).

The two legs diverge frame by frame from the first random draw, so nothing here compares
frames. Each leg is reduced to distributions over its in-match window:

  NODE   entries into each animation node (a change of +0x1C), the node read through the
         build's placements (patch/placements.json, the tenant's anim region) back to its
         vsav2 address — so a node on ours and the same node on native share a key. Entries
         outside the region (shared engine nodes) keep their raw value on both legs.
  SEQ    frames spent in each +0x06 value (the fighter's state family).
  CMD    entries into each CPU AI current-command byte +0x241 (atlas/ram.md; the vsavj and
         vs2 interpreters address +0x241 / +0x205 / +0x22B identically, 15 / 4 / 2 operand
         references each — measured 14z-189).
  SCRIPT frames per CPU AI script index +0x205.

For each distribution the tool prints the total-variation distance (TVD, 0 = identical
shares, 1 = disjoint) between leg A and leg B, plus each leg's event count and its top
entries. It judges nothing; the gate freezes and compares the figures.

Usage: cpu_soak_dist.py <traceA> <traceB> <placements.json|-> <anim-region|-> [--from F]
       [--labelA ours] [--labelB native] [--raw]
  <anim-region>  the placements key translating leg A's nodes (anim / anim@huitzil /
                 anim@pyron); '-' or --raw: no translation (the must-fire control's form).
"""
import argparse, json, sys
from collections import Counter


def load(path, frm):
    rows = []
    for line in open(path):
        if not line.startswith("F "):
            continue
        p = line.split()
        f = int(p[1])
        if f < frm:
            continue
        d = {k: int(v) for k, v in (kv.split("=") for kv in p[2:])}
        if d.get("scr") != 0x40000:
            continue
        rows.append((f, d))
    return rows


def dists(rows, tr):
    node, seq, cmd, script = Counter(), Counter(), Counter(), Counter()
    prev_node = prev_cmd = None
    dist = []
    air = 0
    for _, d in rows:
        n = tr(d["node"])
        if n != prev_node:
            node[n] += 1
            prev_node = n
        seq[d["seq"]] += 1
        if d["ai241"] != prev_cmd:
            cmd[d["ai241"]] += 1
            prev_cmd = d["ai241"]
        script[d["ai205"]] += 1
        dist.append(abs(d["x1"] - d["x2"]))
        air += d["y2"] != 40
    return {"NODE": node, "SEQ": seq, "CMD": cmd, "SCRIPT": script}, dist, air


def tvd(a, b):
    ta, tb = sum(a.values()) or 1, sum(b.values()) or 1
    return 0.5 * sum(abs(a[k] / ta - b[k] / tb) for k in set(a) | set(b))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("a"); ap.add_argument("b"); ap.add_argument("placements"); ap.add_argument("region")
    ap.add_argument("--from", dest="frm", type=int, default=0)
    ap.add_argument("--labelA", default="ours"); ap.add_argument("--labelB", default="native")
    ap.add_argument("--raw", action="store_true")
    ap.add_argument("--top", type=int, default=8)
    a = ap.parse_args()
    tr = lambda v: v
    if not a.raw and a.placements != "-" and a.region != "-":
        r = json.load(open(a.placements))["regions"][a.region]
        dst, src, ln = r["dst"], r["src"], r["len"]
        tr = lambda v: v - dst + src if dst <= v < dst + ln else v
        print(f"# translate leg A's nodes: {a.region} dst {dst:#x} src {src:#x} len {ln:#x}")
    else:
        print("# NO translation (raw node pointers)")
    ra, rb = load(a.a, a.frm), load(a.b, a.frm)
    da, xa, aa = dists(ra, tr)
    db, xb, ab = dists(rb, lambda v: v)
    print(f"FRAMES {a.labelA} {len(ra)} {a.labelB} {len(rb)}")
    print(f"DIST {a.labelA} mean {sum(xa) / max(len(xa), 1):.1f} {a.labelB} mean {sum(xb) / max(len(xb), 1):.1f}")
    print(f"AIR {a.labelA} {aa} {a.labelB} {ab}")
    for k in ("NODE", "SEQ", "CMD", "SCRIPT"):
        A, B = da[k], db[k]
        shared = len(set(A) & set(B))
        print(f"{k} tvd {tvd(A, B):.3f} events {a.labelA} {sum(A.values())} {a.labelB} {sum(B.values())} "
              f"keys {a.labelA} {len(A)} {a.labelB} {len(B)} shared {shared}")
        for lbl, C in ((a.labelA, A), (a.labelB, B)):
            tot = sum(C.values()) or 1
            fmt = (lambda v: f"{v:#08x}") if k == "NODE" else (lambda v: f"{v:#04x}")
            print(f"  {k} top {lbl}: " + " ".join(f"{fmt(v)}:{c * 100 / tot:.1f}%" for v, c in C.most_common(a.top)))


if __name__ == "__main__":
    main()
