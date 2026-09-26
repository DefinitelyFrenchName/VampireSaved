#!/usr/bin/env python3
"""trap_air_static.py — the #175 box figures re-derived STATICALLY from a data view, through the tree's own
readers (tools/hitbox_records.py, tools/anim_nodes.py, tools/trap_air_boxes.py). No emulator.

  python3 tools/trap_air_static.py dome|victor|felicia <data image> <layout vsav2|vsavj>

Written 14z-183 for NEXT_SESSION item 0b (procedure run 2026-09-25-224, QP1): 14z-182 quoted these figures in
docs/game/engine_internals.md "Hitboxes and attack records" (the bullet on the projectile's per-box loop) from its own runs; a
measurer re-derived them with this script on build/out/vsav2_data.bin, build/out/vsavj_data.bin and
build/m3b_merged28/verify_data.bin (each first shown to be the decrypted view of the zip it is named for).
The live verdict stays tests/audit_trap_air_hit.sh; this is the static half.

dome     — Huitzil/Phobos (id 0x10) projectile attack records 5 and 6: box (x, y, hw, hh) and class +0x17
victor   — Victor (id 0x03): every family entry whose vuln1 and vuln2 ids are 0 (vuln0-only), its vuln0 box,
           that box's bottom (y - hh), and how many nodes of tables a/a2/b/c use the entry (first 6 named)
felicia  — Felicia (id 0x07): every node of b:0x0f with its three vuln boxes, and a2:0x14 node 4 likewise
"""
import sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import _minitoml as mt
from anim_nodes import walk_table
from hitbox_records import HitboxSet
from trap_air_boxes import static_node_boxes


def rd32(b, a):
    return int.from_bytes(b[a:a + 4], "big")


mode, path, layout = sys.argv[1], sys.argv[2], sys.argv[3]
img = Path(path).read_bytes()
bank = mt.loads((REPO / "build/manifest/bank_map.toml").read_text())
d = int(bank["origins"][layout]) - int(bank["origins"]["vsavj"])
rows = {t["name"]: int(t["vsavj"]) + d for t in bank["table"]}
print(f"# {mode} {path} layout={layout}")

if mode == "dome":
    cid = 0x10
    ph = HitboxSet.from_image(img, rd32(img, rows["proj_hitbox_base"] + cid * 4), rd32(img, rows["proj_hitbox_comp"] + cid * 4))
    for k in (5, 6):
        r = ph.record(k)
        print(f"proj record {k} addr={r['addr']} box={r['box']} cls={r['cls']:#04x}")
elif mode == "victor":
    cid = 0x03
    hb = HitboxSet.from_image(img, rd32(img, rows["hitbox_base"] + cid * 4), rd32(img, rows["hitbox_comp"] + cid * 4))
    users = {}
    for name in ("anim_index_a", "anim_index_a2", "anim_index_b", "anim_index_c"):
        try:
            res = walk_table(img, 0, rd32(img, rows[name] + cid * 4))
        except Exception:
            continue
        for seq, ch in res["chains"].items():
            for k, n in enumerate(ch["nodes"]):
                users.setdefault(n["hb8"], []).append(f"{name[11:]}:{seq}#{k}")
    for i in range(hb.family_count()):
        fam = hb.family(i)
        if fam[0] and not fam[1] and not fam[2]:
            bx = hb.box(hb.tables["vuln0"] + 8 * fam[0])
            u = users.get(i, [])
            print(f"family {i:#04x} entry={bytes(fam).hex()} vuln0 id={fam[0]} box={bx} bottom={bx[1] - bx[3]} nodes={len(u)} {' '.join(u[:6])}")
elif mode == "felicia":
    boxes = static_node_boxes(path, layout, 0x07)
    for key in sorted(k for k in boxes if k.startswith("b:0x0f#")):
        print(key, boxes[key])
    key = "a2:0x14#4"
    v = boxes.get(key)
    print(key, v, "bottoms=" + ",".join("-" if b is None else str(b[1] - b[3]) for b in (v or ())))
