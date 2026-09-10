#!/usr/bin/env python3
"""rehit_ring.py — THE MULTI-HIT RE-HIT RULE, read off the engine (14z-146).

The question it answers: when does a second attack record with the SAME hit id
land? The hit test at PRG:0x018064 refuses a record whose +0x10 (hit id) equals
the VICTIM's recent-hit slot `+0x6C[attacker +0x70]` (one byte per attacking
fighter block, four slots), the slot is WRITTEN at contact by PRG:0x01827C, and
it is CLEARED by PRG:0x022268 every engine tick in which the attacker's current
anim node carries NO attack record (`node +0x0A == 0`) — `clr.l $86c(a5)` for
P2's ring when P1's node is a gap node, `clr.l $46c(a5)` the other way. So the
slot survives only across CONSECUTIVE attack nodes: a same-id record lands again
once the attacker passes through a gap node, and consecutive attack nodes with
the same id land once. That is what tools/frame_data.py's segment rule encodes.

Inputs, from one vanilla hit rig (tools/vanilla_join_rig.py gen <cid> hit):
  * a tap_writes.lua log over the VICTIM's ring (TAP=ff886c,8): every clear and
    every contact write, PC-attributed;
  * a field_trace.lua log with node,cnt,p2hp,r0,p2i145,p2i1a4 (P1's node pointer
    and countdown, P2's HP, ring slot 0, midair-hit counter, air-vuln timer);
  * the rig's schedule JSON and the vsavj DATA view (node -> record index).

Both instruments count frames at frame_done. A frame that runs two engine ticks
can leave the node on one tick and clear the ring on the next while the sample
still shows the attack node, so the structural check allows the clear on an
attack node's LAST sample (cnt == 1) and nowhere else.

Usage: rehit_ring.py <tap.txt> <trace.txt> <sched.json> <vsavj_data.bin> <cid_hex>
Prints one WRITERS line, one STRUCT line, one EVENT line per button, exit 0.
"""
import json, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import vanilla_join_rig as R  # noqa: E402

CLEAR_PC, CONTACT_PC = "022276", "01827c"


def parse_tap(path):
    clears, contacts, pcs = {}, [], set()
    for ln in Path(path).read_text().splitlines():
        m = re.match(r"frame (\d+) PC (\w+) off (\w+) data (\w+)", ln)
        if not m:
            continue
        f, pc, off, d = int(m.group(1)), m.group(2), m.group(3), int(m.group(4), 16)
        pcs.add(pc)
        if pc == CLEAR_PC:
            clears[f] = clears.get(f, 0) + 1
        elif pc == CONTACT_PC:
            contacts.append((f, off, (d >> 8) & 0xFF))   # byte write on the even address: data<<8
        else:
            contacts.append((f, off, d))
    return clears, contacts, sorted(pcs)


def analyse(tap, trace, sched, img, cid):
    nm = R.node_map(img, cid, detail=True)
    fr = R._samples(trace)
    clears, contacts, pcs = parse_tap(tap)
    sch = json.load(open(sched))
    lo = min(e["frame"] for e in sch["events"]) - 60
    hi = max(e["frame"] for e in sch["events"]) + 300

    def rec(f):
        n = fr.get(f, {}).get("node", 0)
        l = nm.get(n)
        return l[2] if l else 0

    atk = {f for f in range(lo, hi + 1) if f in fr and rec(f)}
    noclr = {f for f in range(lo, hi + 1) if f in fr and f not in clears}
    bad_skip = sorted(noclr - atk)                       # a skipped clear on a gap node
    cleared_atk = sorted(atk - noclr)                    # a clear on an attack node
    not_last = [f for f in cleared_atk if fr[f].get("cnt") != 1]
    out = [f"WRITERS {' '.join(pcs)}",
           f"STRUCT skipped_on_gap={len(bad_skip)} cleared_on_attack={len(cleared_atk)} "
           f"cleared_on_attack_not_last={len(not_last)} attack_samples={len(atk)}"]
    for e in sch["events"]:
        t0 = e["frame"]; t1 = t0 + e["gap"] - 60
        cs = [(f, v) for f, off, v in contacts if t0 <= f < t1]
        # the chain P1 entered and its derived hit segments
        chains = [nm[fr[f]["node"]][0] for f in range(t0, t0 + 40) if f in fr and fr[f].get("node", 0) in nm]
        chain = next((c for c in chains if c.startswith("a2:")), chains[0] if chains else "?")
        # ring value at each contact, and whether the slot was cleared between two same-id contacts
        seq = []
        for i, (f, v) in enumerate(cs):
            gap = any(g in clears for g in range(cs[i - 1][0] + 1, f)) if i else None
            seq.append(f"{v}@{f - t0}" + ("" if i == 0 else ("+" if gap else "=")))
        drops = 0; prev = None
        for f in range(t0 - 10, t1):
            v = fr.get(f, {}).get("p2hp")
            if v is None:
                continue
            if prev is not None and v < prev and prev - v < 200:
                drops += 1
            prev = v
        # a refusal with the slot clear: an attack node sampled with r0 == 0 and no drop that frame,
        # while the victim's midair-hit counter is set and its air-vuln timer is zero (the juggle gate)
        juggle = [f for f in range(t0, t1) if f in atk and fr[f].get("r0") == 0
                  and fr[f].get("p2i145", 0) and not fr[f].get("p2i1a4", 0)]
        out.append(f"EVENT {e['name']} chain={chain} contacts={len(cs)} ids={','.join(seq) or '-'} "
                   f"hp_drops={drops} juggle_refusal_frames={len(juggle)}")
    return out


def main():
    tap, trace, sched, img_p, cid = sys.argv[1:6]
    img = Path(img_p).read_bytes()
    import hashlib
    print(f"# {img_p} sha1 {hashlib.sha1(img).hexdigest()}")
    for ln in analyse(tap, trace, sched, img, int(cid, 16)):
        print(ln)


if __name__ == "__main__":
    main()
