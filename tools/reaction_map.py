#!/usr/bin/env python3
"""reaction_map.py — PHASE 3 of the character-data map: which of a tenant's
anim chains each REACTION CLASS enters when the tenant is the VICTIM, and how
long the reaction runs (measured 14z-120 (7) on native vs2).

  python3 tools/reaction_map.py <schedule.json> <field_trace.txt> <chains_dir>

The rig is tools/name_moves.py's `<tenant>_victim` schedules: P1 = Victor
(forced 0x03) attacks P2 = the tenant (forced by the P2 early-window poke)
with every contact class the naming rigs reached — light/medium/heavy
standing and crouching normals, the sweep, a jumping heavy, the throw, a
DP and a fireball — hits in part 1, BLOCKED in part 2 (P2 holds AWAY),
anti-air contacts in part 3. field_trace.lua samples P2's node pointer,
class byte +0x54, freeze +0x5C, HP/white and position.

One line per contact:  <part>\t<event>\tcls=<victim +0x54>\tfrz=<+0x5C>\t<path>\tlen=<frames>
  path = the chains ENTERED from the contact frame, as table:seq@entry-node
         (a2/c chains are entered MID-chain by node index; OFF:<addr> = a node
         the five index tables do not reach), until the tenant is back on a
         table-a chain other than the one it stood on at the contact, or 240 f;
  len  = frames from the contact to that return (the STUN as the engine ran
         it — the reaction chains are HOLD chains ended by an engine counter,
         so the length is NOT the chain's data frames).
Measured returns: Donovan a:0x2f / a:0x04, Huitzil a:0x1e / a:0x04, Pyron a:0x05 / a:0x04.
"""
import json
import sys

# The RETURN rule: the first table-`a` chain entered AFTER at least one
# non-`a` chain (b / c / OFF) has run — the reaction sets live in tables b
# and c, the stands in a (Donovan a:0x2f, Huitzil a:0x1e, Pyron a:0x05),
# so nothing is hard-coded per tenant.


def load_chains(cd):
    """node address -> the list of (table, seq, index) chains it belongs to.

    A node is usually on SEVERAL chains (the lying/wake family, the block
    stance, every shared tail), so the label is chosen by label_for():
    the chain the previous node was on (continuity), else the chain that
    ENTERS at this node (index 0) with the smallest seq, else the smallest
    seq. Before 14z-121 the map kept "the last chain enumerated", which
    moved labels whenever the decoder learned more chains (the table bound
    fix relabelled Donovan's b:0x44 -> b:0x79 and Pyron's a:0x05 -> a:0x3f)."""
    node2 = {}
    for name in ("a", "a2", "b", "c", "proj"):
        for seq, c in json.load(open(f"{cd}/{name}.json"))["chains"].items():
            for i, n in enumerate(c.get("nodes") or []):
                node2.setdefault(int(n["addr"], 16), []).append((name, int(seq, 16), i))
    return node2


def label_for(cands, prev):
    if prev:
        for c in cands:
            if c[:2] == prev[:2]:
                return c
    entries = [c for c in cands if c[2] == 0]
    return min(entries or cands, key=lambda c: (c[0], c[1]))


def contacts(sched_path, trace_path, chains_dir):
    sched = json.load(open(sched_path)); node2 = load_chains(chains_dir)
    rows = {}
    for line in open(trace_path):
        f = line.split()
        if len(f) < 3 or f[0] != "F":
            continue
        v = dict(kv.split("=") for kv in f[2:]); rows[int(f[1])] = {k: int(x) for k, x in v.items()}
    def evname(fr):
        best = None
        for e in sched["events"]:
            if e["frame"] <= fr: best = e["name"]
        return best
    out = []; prev = None
    for fr in sorted(rows):
        v = rows[fr]
        if prev is None: prev = fr; continue
        pv = rows[prev]
        if v["p2hp"] < pv["p2hp"] or v["p2white"] < pv["p2white"] or (v["p2frz"] and not pv["p2frz"]):
            path = []; k = fr; last = None; back = None; reacted = False; prevkey = None
            while k in rows and k < fr + 240:
                cands = node2.get(rows[k]["p2node"] & 0xffffffff)
                key = label_for(cands, prevkey) if cands else None
                prevkey = key
                lab = f"{key[0]}:0x{key[1]:02x}@{key[2]}" if key else f"OFF:{rows[k]['p2node']:#x}"
                if lab.rsplit("@", 1)[0] != (last.rsplit("@", 1)[0] if last else None): path.append(lab)
                last = lab
                if not (key and key[0] == "a"): reacted = True          # a reaction chain (b/c/OFF) has run
                elif reacted: back = k - fr; break                        # the first table-a chain after it = the return
                k += 1
            out.append(f"{sched['part']}\t{evname(fr)}\tcls={v['p2cls']:#04x}\tfrz={v['p2frz']}\t{' '.join(path[:8])}\tlen={back}")
        prev = fr
    return out


if __name__ == "__main__":
    print("\n".join(contacts(sys.argv[1], sys.argv[2], sys.argv[3])))
