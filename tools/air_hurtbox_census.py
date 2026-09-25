#!/usr/bin/env python3
"""air_hurtbox_census.py — WHICH ANIMATION NODES OF WHICH CHARACTERS CARRY A HURTBOX LOW ENOUGH FOR
THE PLASMA TRAP DOME TO REACH (14z-182, GitHub #175). A static census, no emulator.

  python3 tools/air_hurtbox_census.py <data image> [--layout vsav2|vsavj] [--ids 03,10] [--limit 5] [--json out]

WHY. The dome's attack box is (0, 0, 40, 6): 12 px tall, its top 6 px above the dome's y, which is the
ground (40) while it stands — so it can only touch a victim whose TESTED hurtbox reaches down to 46.
An airborne victim stands at y >= 41, so the question "can the dome hit anyone in the air" is: does
any node an airborne victim can be in carry a tested vuln box whose bottom (box y - hh, relative to
the victim's feet) is <= 5 (`--limit`)? Measured 14z-182 on native vs2 (tools/trap_air_probe.sh):
the dome's hit test runs on EVERY pass against an airborne victim (the fighter-hit loop, vs2
`0x1699c`/`0x169f0`/`0x16a46`, A6 = the dome) — no grounded-only rule — and a jumping Victor carries
ONE tested box, vuln0 (0, 69, 32, 36), its bottom 33 px above his feet.

WHAT IT READS. For every character id of the image (the bank rows of build/manifest/bank_map.toml,
read with the chosen layout), every node of tables a / a2 / b / c walked by tools/anim_nodes.py, its
family entry (node hb8 -> {vuln0, vuln1, vuln2, push}) resolved through tools/hitbox_records.py.
**A vuln id of 0 is NO BOX** — the engine's per-box loop skips it (vs2 `0x1698a`, `0x169de`: `beq`
past the test) — so only nonzero ids count; the shared resolver's node_boxes() resolves id 0 to a
phantom box and is NOT used for the verdict here. A chain the walker reads off its region (an
out_of_region / runaway end) is not a chain and is skipped, counted.

WHAT IT CANNOT SAY. The animation data does not mark a node AIRBORNE. The census reports two
airborne indicators and never proves one: the a2 slots 0x12-0x1D (the neutral / forward jump attacks,
docs/game/engine_internals.md "The anim index a2's TWO aerial slot sets", MEASURED on the vanilla
fifteen) and the VULN0-ONLY family signature (vuln1 = vuln2 = 0) that a jumping Victor carries. A node
with a low box and neither indicator may still be airborne (a knockdown arc); whether a candidate is
ever airborne is a live measurement.

Output: per id, the node count, the nodes with a tested box <= limit (low), how many of those are
vuln0-only, the a2 aerial slots' lowest bottom, and the low vuln0-only chains listed.
"""
import argparse, hashlib, json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import _minitoml as mt
from anim_nodes import walk_table
from hitbox_records import HitboxSet

NAMES = {0x00: "Bulleta", 0x01: "Demitri", 0x02: "Gallon", 0x03: "Victor", 0x04: "Zabel", 0x05: "Morrigan",
         0x06: "Anakaris", 0x07: "Felicia", 0x08: "Bishamon", 0x09: "Aulbath", 0x0A: "Sasquatch",
         0x0C: "Q-Bee", 0x0D: "Lei-Lei", 0x0E: "Lilith", 0x0F: "Jedah",
         0x10: "Huitzil/Phobos", 0x11: "Pyron", 0x13: "Donovan"}
IDS = {"vsav2": [0x00, 0x01, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x13],
       "vsavj": [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0C, 0x0D, 0x0E, 0x0F]}
TABLES = ("anim_index_a", "anim_index_a2", "anim_index_b", "anim_index_c")


def rd32(img, a):
    return int.from_bytes(img[a:a + 4], "big")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--layout", choices=("vsav2", "vsavj"), default="vsav2")
    ap.add_argument("--ids")
    ap.add_argument("--limit", type=int, default=5)
    ap.add_argument("--bank", default=str(Path(__file__).parent.parent / "build/manifest/bank_map.toml"))
    ap.add_argument("--json")
    a = ap.parse_args()
    img = Path(a.image).read_bytes()
    print(f"image {a.image} sha1 {hashlib.sha1(img).hexdigest()} layout {a.layout} limit {a.limit}")
    bank = mt.loads(Path(a.bank).read_text())
    delta = int(bank["origins"][a.layout]) - int(bank["origins"]["vsavj"])
    rows = {t["name"]: int(t["vsavj"]) + delta for t in bank["table"]}
    ids = [int(x, 16) for x in a.ids.split(",")] if a.ids else IDS[a.layout]
    report = {}
    tot_low_v0 = 0
    for cid in ids:
        hb = HitboxSet.from_image(img, rd32(img, rows["hitbox_base"] + cid * 4), rd32(img, rows["hitbox_comp"] + cid * 4))
        r = {"name": NAMES.get(cid, "?"), "nodes": 0, "low": 0, "low_v0only": 0, "v0only": 0, "skipped_chains": 0,
             "aerial_min_bottom": None, "low_v0only_chains": [], "min_bottom_v0only": None}
        seen = set()
        for name in TABLES:
            try:
                res = walk_table(img, 0, rd32(img, rows[name] + cid * 4))
            except Exception:
                continue
            for seq, ch in res["chains"].items():
                seq = int(seq, 16) if isinstance(seq, str) else int(seq)   # the walker keys chains by a hex string
                if ch["end"] in ("out_of_region", "runaway"):
                    r["skipped_chains"] += 1
                    continue
                for n in ch["nodes"]:
                    if n["addr"] in seen:
                        continue
                    seen.add(n["addr"])
                    fam = hb.family(n["hb8"])
                    present = [i for i in range(3) if fam[i] != 0]
                    if not present:
                        continue
                    bots = []
                    for i in present:
                        x, y, hw, hh = hb.box(hb.tables[f"vuln{i}"] + 8 * fam[i])
                        bots.append(y - hh)
                    low = min(bots)
                    r["nodes"] += 1
                    v0only = present == [0]
                    if v0only:
                        r["v0only"] += 1
                        r["min_bottom_v0only"] = low if r["min_bottom_v0only"] is None else min(r["min_bottom_v0only"], low)
                    if name == "anim_index_a2" and 0x12 <= seq <= 0x1D:
                        r["aerial_min_bottom"] = low if r["aerial_min_bottom"] is None else min(r["aerial_min_bottom"], low)
                    if low <= a.limit:
                        r["low"] += 1
                        if v0only:
                            r["low_v0only"] += 1
                            tag = f"{name[11:]}:{seq:#04x}"
                            if tag not in r["low_v0only_chains"]:
                                r["low_v0only_chains"].append(tag)
        tot_low_v0 += r["low_v0only"]
        report[f"{cid:#04x}"] = r
        print(f"{cid:#04x} {r['name']:<15} nodes {r['nodes']:4d}  low(<= {a.limit}) {r['low']:4d}  "
              f"vuln0-only {r['v0only']:4d} (lowest bottom {r['min_bottom_v0only']}; low {r['low_v0only']})  "
              f"a2 aerials lowest bottom {r['aerial_min_bottom']}  skipped chains {r['skipped_chains']}"
              + (f"\n      low vuln0-only chains: {' '.join(r['low_v0only_chains'])}" if r["low_v0only_chains"] else ""))
    print(f"TOTAL low vuln0-only nodes: {tot_low_v0}")
    if a.json:
        Path(a.json).write_text(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
