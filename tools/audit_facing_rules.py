#!/usr/bin/env python3
"""audit_facing_rules.py — the victim FACING RULE (+0xE) of every LEGACY attack
record reachable from a walked anim node, per game (14z-167, GitHub #159: the
legacy control for the rule-5 finding; promoted from a build/ scratch script).

  python3 tools/audit_facing_rules.py <vsavj_data.bin> <vsav2_data.bin> [--tsv]

Reads each image through build/manifest/bank_map.toml's layout exactly as
tools/audit_same_data_p2.py does (the same resolvers, imported), walks tables
a/a2/b/c (the fighter's hitbox set) and proj (the projectile set) for every
legacy id both games carry, and counts DISTINCT records (by address) by +0xE.
Measured 14z-167: rule 5 on 0 of vsavj's reachable legacy records and on 1 of
vsav2's (a Lilith projectile record). Values above 5 are XORed raw by BOTH
resolvers, so rule 5 is the one value the two engines resolve differently.
The walk can reach records that are not real (odd values appear on both
sides), so this counts REACHABLE records; it is not a census of true records.
"""
import argparse, collections, hashlib, sys
from pathlib import Path
R = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(R / "tools"))
import _minitoml as mt
from anim_nodes import walk_table
from hitbox_records import HitboxSet
from audit_same_data_p2 import SHARED, NAMES, rd32

def census(img, d, rows):
    seen, hits5 = {}, []
    for cid in SHARED:
        hb = HitboxSet.from_image(img, rd32(img, rows["hitbox_base"] + d + cid * 4), rd32(img, rows["hitbox_comp"] + d + cid * 4))
        try:
            phb = HitboxSet.from_image(img, rd32(img, rows["proj_hitbox_base"] + d + cid * 4), rd32(img, rows["proj_hitbox_comp"] + d + cid * 4))
        except Exception:
            phb = None
        for name in ("anim_index_a", "anim_index_a2", "anim_index_b", "anim_index_c", "anim_index_proj"):
            h = phb if name == "anim_index_proj" else hb
            if h is None: continue
            res = walk_table(img, 0, rd32(img, rows[name] + d + cid * 4))
            for seq, ch in res["chains"].items():
                for n in ch["nodes"]:
                    if (n.get("hbA", 0) >> 8) == 0: continue
                    rec = h.node_boxes(n["hb8"], n["hbA"])["attack"]
                    if not rec: continue
                    key = (cid, name == "anim_index_proj", rec.get("addr"))
                    f = rec["facing"]; f = f - 256 if f > 127 else f
                    if key not in seen:
                        seen[key] = f
                        if f == 5: hits5.append(f"{NAMES[cid]} {name[11:]} seq {seq} rec {rec.get('addr')}")
    return seen, hits5

def main():
    ap = argparse.ArgumentParser(); ap.add_argument("vsavj"); ap.add_argument("vsav2"); ap.add_argument("--tsv", action="store_true")
    a = ap.parse_args()
    bank = mt.loads((R / "build/manifest/bank_map.toml").read_text())
    rows = {t["name"]: int(t["vsavj"]) for t in bank["table"]}
    orig = {g: int(bank["origins"][g]) for g in ("vsavj", "vsav2")}
    for g, p in (("vsavj", a.vsavj), ("vsav2", a.vsav2)):
        img = Path(p).read_bytes()
        seen, hits5 = census(img, orig[g] - orig["vsavj"], rows)
        c = collections.Counter(seen.values())
        if a.tsv:
            print(f"legacy\t{g}\trecords={len(seen)}\trule5={c.get(5, 0)}\trules={','.join(f'{k}:{v}' for k, v in sorted(c.items()))}")
        else:
            print(f"{g}: {p} sha1 {hashlib.sha1(img).hexdigest()}")
            print(f"  {len(seen)} distinct reachable legacy attack records; facing rule counts {dict(sorted(c.items()))}")
            for h5 in hits5: print("  rule 5:", h5)

if __name__ == "__main__":
    main()
