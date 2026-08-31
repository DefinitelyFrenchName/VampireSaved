#!/usr/bin/env python3
"""frame_data.py — the ONE derivation of per-chain startup / active / recovery
from an animation chain's nodes. Imported by tools/charmap_md.py (the tenant
appendix pages), tools/charmap_html.py (the character pages) and
tools/vanilla_frames.py (the vanilla derivation), so the three cannot drift.

THE LAW, as measured (tests/test_hitbox_encoding.sh, 14z-120 (5)):
  a node's hbA word (+0xA) >> 8 is the ATTACK RECORD index, and
  **a chain's ACTIVE frames are its nodes with hbA != 0**.
  The record's +0x10 is the HIT ID (the multi-hit dedup key), so two adjacent
  attack nodes carrying different hit ids are two HITS, not one longer one.

WHY THIS MODULE EXISTS (14z-125). Until now `charmap_md.py` and
`charmap_html.py` each computed `active = sum(durs[first:last+1])` — the
INCLUSIVE SPAN from the first to the last attack node, which counts
NON-ATTACKING gap nodes as active. That contradicted the law above (stated in
tools/hitbox_records.py's own docstring) and inflated 18 tenant chains:
Huitzil 5LP read active 13 where the true active is 6, his 6LP 15 vs 6, his
2HK 18 vs 12; Donovan's Ifrit Sword ES 22 vs 16. It also collapsed multi-hit
moves to a single wrong number, which is exactly what made the community
cross-check impossible to run: the community sheet writes those moves in a
runs grammar (`2(4)3,2`) that carries the gaps explicitly.

So `derive()` returns BOTH:
  * `active` — the true total, attack nodes only (the number to compare);
  * `notation` — the same runs in the community grammar, so a comparison
    against a community sheet is like-for-like;
  * `span`  — the old inclusive figure, kept so the change is auditable and
    so "why did this number move?" has an answer in the data itself.
"""


def derive(durs, atk, hit_id=None):
    """durs: per-node duration bytes. atk: per-node attack-record index
    (0 = not an attack node). hit_id: optional {record index: hit id} used to
    split contiguous active frames into separate hits; when a record is absent
    from it (or it is None) adjacent nodes MERGE, which is the conservative
    reading — an unknown hit id never invents a hit boundary.

    Returns None when the chain has no attack node at all, else a dict:
      startup, active, span, recovery, first, last, records, runs, notation
    """
    if not any(atk):
        return None
    first = next(i for i, a in enumerate(atk) if a)
    last = max(i for i, a in enumerate(atk) if a)

    runs = []
    i = first
    while i <= last:
        if atk[i]:
            seg = []
            while i <= last and atk[i]:
                hid = (hit_id or {}).get(atk[i])
                if seg and seg[-1]["hit_id"] == hid:
                    seg[-1]["frames"] += durs[i]
                    seg[-1]["records"].append(atk[i])
                else:
                    seg.append({"kind": "hit", "frames": durs[i], "hit_id": hid, "records": [atk[i]]})
                i += 1
            for s in seg:
                s["records"] = sorted(set(s["records"]))
                runs.append(s)
        else:
            gap = 0
            while i <= last and not atk[i]:
                gap += durs[i]
                i += 1
            runs.append({"kind": "gap", "frames": gap})

    notation = ""
    for r in runs:
        if r["kind"] == "gap":
            notation += f"({r['frames']})"
        else:
            notation += ("," if notation and not notation.endswith(")") else "") + str(r["frames"])

    return {
        "startup": sum(durs[:first]),
        "active": sum(r["frames"] for r in runs if r["kind"] == "hit"),
        "span": sum(durs[first:last + 1]),
        "recovery": sum(durs[last + 1:]),
        "first": first,
        "last": last,
        "records": sorted({a for a in atk if a}),
        "runs": runs,
        "notation": notation,
    }


def hit_ids(attack_records):
    """{record index: hit id} from the map JSON's structures.hitbox.attack list
    (entries carry "idx" and "fields": {"hit_id": ...})."""
    out = {}
    for r in attack_records or []:
        f = r.get("fields") or {}
        if "hit_id" in f:
            out[r["idx"]] = f["hit_id"]
    return out


def from_nodes(nodes, attack_records=None, side="vs2"):
    """Convenience for the charmap JSON's node shape: nodes[i]["fields"]["dur"][side]
    and ["hbA"][side], with the hit ids read off the map's attack-record list."""
    durs = [n["fields"]["dur"][side] for n in nodes]
    atk = [n["fields"]["hbA"][side] >> 8 for n in nodes]
    return derive(durs, atk, hit_ids(attack_records))


def line(fd, end_is_hold=True):
    """The one-line rendering used by the tenant appendix pages."""
    recs = ", ".join(f"{x:#x}" for x in fd["records"])
    s = (f"Frame data (derived): startup {fd['startup']} · active {fd['active']}"
         + (f" ({fd['notation']})" if fd["notation"] != str(fd["active"]) else "")
         + f" (nodes {fd['first']}-{fd['last']}, attack record{'s' if len(fd['records']) > 1 else ''} {recs})"
         + f" · recovery {fd['recovery']}")
    if fd["span"] != fd["active"]:
        s += f" — {fd['span'] - fd['active']} frame(s) between hits are NOT active (span {fd['span']})"
    if not end_is_hold:
        s += " — the chain loops/holds, so the tail is the data's, not the move's"
    return s
