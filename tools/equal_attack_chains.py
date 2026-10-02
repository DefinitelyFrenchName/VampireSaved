"""equal_attack_chains.py (14z-188, GitHub #198; promoted from the scratch equal_attacks.py, widened after rule-checker runs 2026-10-02-559/560): every chain of Demitri
(id 0x01) in tables a, a2, b, c and proj, classed by the census tool's own comparison (audit_same_data_p2.chain_shape;
proj on the projectile hitbox tables, as the census does): EQUAL on both games, DIFFERS, ONE-SIDED (present on one
game only) or INVALID (the walker ran off the table on a side). Every EQUAL chain carrying an attack record is
printed with each attack node's (real, white) power; POWERED marks those with a non-zero power on some node.
Positive controls: a2:0x04 (his 5HP) must class DIFFERS and its attack node 2 must read 14/7 on vsavj and 13/7 on vs2
(the census's own figures), and a2:0x29 must class EQUAL with a POWERED attack record — else the run is VOID.
Usage: python3 tools/equal_attack_chains.py <vsavj_data.bin> <vsav2_data.bin>   (the decrypted data views, e.g. build/out/)"""
import hashlib, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import audit_same_data_p2 as a
import _minitoml as mt
imgs = {"vsavj": Path(sys.argv[1]).read_bytes(), "vsav2": Path(sys.argv[2]).read_bytes()}
for k, v in imgs.items(): print(f"{k} sha1 {hashlib.sha1(v).hexdigest()}")
bank = mt.loads((Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml").read_text())
delta = int(bank["origins"]["vsav2"]) - int(bank["origins"]["vsavj"])
rows = {x["name"]: int(x["vsavj"]) for x in bank["table"]}
cid = 1
cls = {}
pow04 = {}
pw29 = False
for t in ("a", "a2", "b", "c", "proj"):
    sh = {}
    for g, img in imgs.items():
        d = 0 if g == "vsavj" else delta
        hbn = ("proj_hitbox_base", "proj_hitbox_comp") if t == "proj" else ("hitbox_base", "hitbox_comp")
        hb = a.HitboxSet.from_image(img, a.rd32(img, rows[hbn[0]] + d + cid * 4), a.rd32(img, rows[hbn[1]] + d + cid * 4))
        sh[g] = a.chain_shape(img, a.rd32(img, rows["anim_index_" + t] + d + cid * 4), hb, a.node_index(img, rows, d, cid))
    if t == "a2":   # the power control: a2:0x04's attack node 2 must read its known powers on each image
        for g in ("vsavj", "vsav2"):
            n = sh[g]["0x04"][0][2]
            pow04[g] = (n[6][2][1], n[6][2][2]) if len(n[6]) == 3 and n[6][2] else None
    counts = {"EQUAL": 0, "DIFFERS": 0, "ONE-SIDED": 0, "INVALID": 0}
    for seq in sorted(set(sh["vsavj"]) | set(sh["vsav2"]), key=lambda x: int(x, 16)):
        A, B = sh["vsavj"].get(seq), sh["vsav2"].get(seq)
        if A is None or B is None:
            k = "ONE-SIDED"; print(f"ONE-SIDED {t}:{seq} on {'vsavj' if B is None else 'vsav2'} only")
        elif A[0] == "INVALID" or B[0] == "INVALID":
            k = "INVALID"; print(f"INVALID {t}:{seq} vsavj {A[0] if A[0] == 'INVALID' else 'ok'} vsav2 {B[0] if B[0] == 'INVALID' else 'ok'}")
        elif A != B:
            k = "DIFFERS"
        else:
            k = "EQUAL"
            atk = [(n, x[6][2][1], x[6][2][2]) for n, x in enumerate(A[0]) if len(x[6]) == 3 and x[6][2]]
            if atk:
                pw = any(r or w for _, r, w in atk)
                if f"{t}:{seq}" == "a2:0x29": pw29 = pw
                print(f"EQUAL-ATTACK{' POWERED' if pw else ''} {t}:{seq} nodes {len(A[0])} attack nodes " + " ".join(f"n{n} {r}/{w}" for n, r, w in atk))
                k = "EQUAL-ATTACK"
        cls[f"{t}:{seq}"] = k
        counts[k if k != "EQUAL-ATTACK" else "EQUAL"] += 1
    print(f"TABLE {t}: " + " ".join(f"{k} {v}" for k, v in counts.items()))
ok = cls.get("a2:0x04") == "DIFFERS" and cls.get("a2:0x29") == "EQUAL-ATTACK" and pw29 and pow04 == {"vsavj": (14, 7), "vsav2": (13, 7)}
print(f"CONTROL a2:0x04 {cls.get('a2:0x04')} (want DIFFERS), node 2 power {pow04} (want vsavj 14/7, vsav2 13/7); "
      f"a2:0x29 {cls.get('a2:0x29')} powered={pw29} (want EQUAL-ATTACK, powered): {'OK' if ok else 'VOID'}")
sys.exit(0 if ok else 1)
