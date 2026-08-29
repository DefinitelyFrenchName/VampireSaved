#!/usr/bin/env python3
"""anim_nodes.py — walk a character's ANIMATION NODE CHAINS (phase 1 of the
character-data map) exactly as the engine's node walker does.

  python3 tools/anim_nodes.py <image.bin> --base 0xADDR --table 0xADDR [--name a]
                              [--end 0xADDR] [--json out.json] [--max-seq N]

  <image.bin>   a data-view image; `--base` is the ROM address of image[0]
                (0 for a full data view such as build/<t>/verify_data.bin; the
                region's `src` for an extract blob such as region_anim.bin)
  --table       the per-character anim INDEX TABLE (the bank row's pointer:
                anim_index_a/a2/b/c/proj — regions.json `values[]`)
  --end         optional upper bound of the anim region (chain walks stop
                outside it and report `out_of_region`)

THE RULES, READ OFF THE WALKER (vs2 PRG:0x02713C..0x0271F2, decoded 14z-118 —
docs/game/engine_internals.md "The animation walker"):
  node select (0x2713C): a0 = table + word[table + 2*seq]  (offsets are
    relative to the TABLE base); obj+0x1C = a0; obj+0x20.l = node[0..3]
    (+0 duration countdown, +1 flags -> obj+0x21); node+8.w * 4 indexes the
    obj+0x64 hitbox-family table -> obj+0x68, obj+0x94 = its first long (the
    box ids); node+0x16 nonzero -> per-node sfx record (index * 8 into the
    character's [[sound_table]] array: id, alt id, p4, p5, d3).
  advance (0x271C4): subq.b #1,obj+0x20; at zero read flags = node+1:
    bit7 set -> next = (node+0x18).l  (a LINK; loop-backs are links)
    bit6 set -> st.b obj+0x21, stay    (the chain HOLDS on this node = END)
    else     -> next = node + 0x18     (sequential)
  A chain therefore ends on a hold node or on a revisit (a loop).

OUTPUT (--json): {"table": ..., "entries": N, "chains": {seq: {"start": addr,
"nodes": [{"addr", "dur", "flags", "sprite", "hb8", "hbA", "shadow", "op",
"sfx", "link"}...], "end": "hold" | "loop:<addr>" | "out_of_region" |
"runaway"}}}. Node fields are decoded numbers — never raw hex beyond the
6-byte script-op area at +0x10 (kept as hex because it is undecoded).

Table length: the entry count is the smallest word offset / 2 — every
offset points past the table, so the first node's offset bounds the table
(validated per table: any offset below that count*2 is reported as an
inconsistency and the walk refuses).

NOT YET MEASURED LIVE: the phase-1 rig (tests/test_anim_node_walk.sh)
compares these chains against obj+0x1C / obj+0x20 sampled per frame on a
native vs2 run. Until it passes, this decoder's output is a READING of the
walker, not a verified instrument.
"""
import argparse
import hashlib
import json
import sys
from pathlib import Path

NODE = 0x18
MAX_NODES = 4096


def walk_table(img, base, table, end=None, max_seq=None, entries=None):
    def rd(addr, n):
        o = addr - base
        if o < 0 or o + n > len(img):
            return None
        return img[o:o + n]

    words = []
    k = 0
    while True:
        b = rd(table + 2 * k, 2)
        if b is None:
            break
        words.append(int.from_bytes(b, "big"))
        k += 1
        if max_seq and k >= max_seq:
            break
        # stop reading once we would run into the first node
        if words and k * 2 >= min(w for w in words if w):
            break
    nonzero = [w for w in words if w]
    if not nonzero and entries is None:
        return {"table": f"{table:#x}", "entries": 0, "chains": {}, "error": "empty table"}
    if entries is None:
        entries = min(nonzero) // 2
    else:
        # a caller-imposed count (the ours side of a comparison): read that many words
        words = [int.from_bytes(rd(table + 2 * k, 2) or b"\0\0", "big") for k in range(entries)]
    words = words[:entries]
    bad = [i for i, w in enumerate(words) if w and w < entries * 2]
    chains = {}
    for seq, w in enumerate(words):
        if w == 0:
            chains[f"{seq:#04x}"] = {"start": None, "nodes": [], "end": "unused"}
            continue
        start = table + w
        nodes = []
        seen = set()
        a = start
        endk = None
        while True:
            if a in seen:
                endk = f"loop:{a:#x}"
                break
            if end is not None and not (base <= a < end):
                endk = "out_of_region"
                break
            n = rd(a, NODE + 4)  # +4 so a link long at +0x18 is readable
            if n is None or len(n) < NODE:
                endk = "out_of_region"
                break
            seen.add(a)
            flags = n[1]
            node = {"addr": f"{a:#x}", "dur": n[0], "flags": flags,
                    "sprite": f"{int.from_bytes(n[4:8], 'big'):#x}",
                    "hb8": int.from_bytes(n[8:10], "big"), "hbA": int.from_bytes(n[10:12], "big"),
                    "shadow": int.from_bytes(n[12:14], "big") & 0x1FFF,
                    "op": n[0x10:0x16].hex(), "sfx": n[0x16]}
            if flags & 0x80:
                link = int.from_bytes(n[0x18:0x1C], "big") if len(n) >= 0x1C else None
                node["link"] = f"{link:#x}" if link is not None else None
                nodes.append(node)
                if link is None:
                    endk = "out_of_region"
                    break
                a = link
            elif flags & 0x40:
                nodes.append(node)
                endk = "hold"
                break
            else:
                nodes.append(node)
                a += NODE
            if len(nodes) >= MAX_NODES:
                endk = "runaway"
                break
        chains[f"{seq:#04x}"] = {"start": f"{start:#x}", "nodes": nodes, "end": endk,
                                 "frames": sum(x["dur"] for x in nodes)}
    out = {"table": f"{table:#x}", "entries": entries, "chains": chains}
    if bad:
        out["inconsistent_offsets"] = bad
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image", type=Path)
    ap.add_argument("--base", required=True, type=lambda x: int(x, 0))
    ap.add_argument("--table", required=True, type=lambda x: int(x, 0))
    ap.add_argument("--name", default="")
    ap.add_argument("--end", type=lambda x: int(x, 0), default=None)
    ap.add_argument("--max-seq", type=int, default=None)
    ap.add_argument("--json", type=Path)
    a = ap.parse_args()
    img = a.image.read_bytes()
    print(f"read  {a.image}  sha1 {hashlib.sha1(img).hexdigest()}  base {a.base:#x}")
    res = walk_table(img, a.base, a.table, a.end, a.max_seq)
    res["name"] = a.name
    ch = res["chains"]
    ends = {}
    for c in ch.values():
        ends[c["end"].split(":")[0]] = ends.get(c["end"].split(":")[0], 0) + 1
    print(f"table {res['table']} ({a.name}): {res['entries']} entries, "
          f"{sum(len(c['nodes']) for c in ch.values())} nodes; ends: {ends}"
          + (f"; INCONSISTENT offsets at seqs {res['inconsistent_offsets']}" if res.get("inconsistent_offsets") else ""))
    if a.json:
        a.json.write_text(json.dumps(res, indent=1, sort_keys=True) + "\n")
        print(f"wrote {a.json}")


if __name__ == "__main__":
    main()
