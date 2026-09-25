#!/usr/bin/env python3
"""trap_air_boxes.py — resolve a field_trace of tools/trap_air_probe.sh into world-space boxes.

For each sampled frame: the victim's vuln boxes (from +0x80/+0x84/+0x88 and the family ids in
+0x94 — an id of 0 is NO BOX: the engine's per-box loop skips it, vs2 `0x1698a`/`0x169de` `beq`
past the test, and a jumping Victor carries `0x03000003`, only vuln0; the first form of this tool
resolved id 0 to a phantom box and reported an airborne overlap that the engine never tests,
14z-182) and, for every $FF9400 pool slot whose current node carries an attack record
(node +0xA word >> 8 != 0), that slot's attack box (record table +0x8C, 0x20 bytes a record, the
box its first four signed words). Encoding: docs/game/engine_internals.md "Hitboxes and attack
records" — box (x, y, hw, hh), centre (X + (flip ? -x : x), Y + y), half-extents, y up, ground 40.

Per (attack box, vuln box) pair it prints the two gaps: gx = |dcx| - (hw1 + hw2) and
gy = |dcy| - (hh1 + hh2). Both <= 0 means the rectangles overlap (touching counted as overlap —
whether the engine's test is strict is NOT decided here; the margins are printed so it can be read).

It also names each fighter by its hitbox base (+0x60 — in a match +0x382 is the voice class, [VSE-62])
against the image's bank row, and the victim's current node as (table, seq, node #) of its own chains.

Usage: trap_air_boxes.py <trace.ft> <data image> [--layout vsav2|vsavj]
"""
import struct
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import _minitoml as mt
from anim_nodes import walk_table


def s16(b, a):
    return struct.unpack(">h", b[a:a + 2])[0]


def u16(b, a):
    return struct.unpack(">H", b[a:a + 2])[0]


def box(data, addr):
    return tuple(s16(data, addr + 2 * i) for i in range(4))


def world(bx, X, Y, flip):
    x, y, hw, hh = bx
    return (X + (-x if flip else x), Y + y, hw, hh)


def rd32(b, a):
    return int.from_bytes(b[a:a + 4], "big")


def static_node_boxes(img_path, layout, cid):
    """{ "table:seq#k": (vuln0, vuln1, vuln2) } — every node of character `cid`'s tables a/a2/b/c with its
    three vuln boxes resolved from the image (None for a zero id: no box). The per-node static data a
    live box is compared against (tests/audit_trap_air_hit.sh: which differences are the character's
    own data, and that our build carries pristine vsavj's)."""
    from hitbox_records import HitboxSet
    img = Path(img_path).read_bytes()
    bank = mt.loads((Path(__file__).parent.parent / "build/manifest/bank_map.toml").read_text())
    dl = int(bank["origins"][layout]) - int(bank["origins"]["vsavj"])
    rows = {t["name"]: int(t["vsavj"]) + dl for t in bank["table"]}
    hb = HitboxSet.from_image(img, rd32(img, rows["hitbox_base"] + cid * 4), rd32(img, rows["hitbox_comp"] + cid * 4))
    out = {}
    for name in ("anim_index_a", "anim_index_a2", "anim_index_b", "anim_index_c"):
        try:
            res = walk_table(img, 0, rd32(img, rows[name] + cid * 4))
        except Exception:
            continue
        for seq, ch in res["chains"].items():
            for k, n in enumerate(ch["nodes"]):
                fam = hb.family(n["hb8"])
                out[f"{name[11:]}:{seq}#{k}"] = tuple(hb.box(hb.tables[f"vuln{i}"] + 8 * fam[i]) if fam[i] else None for i in range(3))
    return out


def main():
    ft, img = sys.argv[1], sys.argv[2]
    layout = sys.argv[sys.argv.index("--layout") + 1] if "--layout" in sys.argv else "vsav2"
    data = open(img, "rb").read()
    bank = mt.loads((Path(__file__).parent.parent / "build/manifest/bank_map.toml").read_text())
    delta = int(bank["origins"][layout]) - int(bank["origins"]["vsavj"])
    rows = {t["name"]: int(t["vsavj"]) + delta for t in bank["table"]}
    base_id = {rd32(data, rows["hitbox_base"] + i * 4): i for i in reversed(range(32))}   # the LOWEST id wins: variant rows alias the base half ([VSE-10])
    node_of = {}

    def locate(cid, addr):
        if cid not in node_of:
            m = {}
            for name in ("anim_index_a", "anim_index_a2", "anim_index_b", "anim_index_c"):
                try:
                    res = walk_table(data, 0, rd32(data, rows[name] + cid * 4))
                except Exception:
                    continue
                for seq, ch in res["chains"].items():
                    for k, n in enumerate(ch["nodes"]):
                        a = int(n["addr"], 16) if isinstance(n["addr"], str) else n["addr"]
                        m.setdefault(a, f"{name[11:]}:{seq}#{k}")
            node_of[cid] = m
        return node_of[cid].get(addr, "?")
    named = False
    print(f"# boxes from {ft} through {img}; y up, ground 40; gap <= 0 on BOTH axes = overlap")
    for line in open(ft):
        if not line.startswith("F "):
            continue
        parts = line.split()
        f = int(parts[1])
        v = {k: int(val) for k, val in (p.split("=") for p in parts[2:])}
        X, Y, flip = v["vx"], v["vy"], v["vflip"] & 1
        fam = v["vfam"] & 0xFFFFFFFF
        ids = [(fam >> 24) & 0xFF, (fam >> 16) & 0xFF, (fam >> 8) & 0xFF]
        vulns = []
        for i in range(3):
            if ids[i] == 0:            # no box: the engine skips the test
                vulns.append(None)
                continue
            t = v[f"vt{i}"] & 0xFFFFFF
            vulns.append(world(box(data, t + 8 * ids[i]), X, Y, flip))
        lo = min(b[1] - b[3] for b in vulns if b)
        head = (f"f{f} victim x={X} y={Y} {'AIR' if Y > 40 else 'gnd'} seq={v['vseq']:#04x} cls={v['vcls']:#04x} "
                f"hp={v['vhp']} ids={ids} lowest-vuln-bottom={lo}")
        atk = []
        for k in range(32):
            node = v[f"s{k}node"] & 0xFFFFFF
            if v[f"s{k}type"] == 0 or node == 0 or node + 0xC > len(data):
                continue
            rid = u16(data, node + 0xA) >> 8
            if rid == 0:
                continue
            rec = (v[f"s{k}rec"] & 0xFFFFFF) + rid * 0x20
            ab = world(box(data, rec), v[f"s{k}x"], v[f"s{k}y"], v[f"s{k}flip"] & 1)
            atk.append((k, v[f"s{k}type"], rid, ab))
        p1, p2 = base_id.get(v["p1base"] & 0xFFFFFF), base_id.get(v["p2base"] & 0xFFFFFF)
        if not named:
            print(f"# fighters by hitbox base: P1 id {p1}, P2 id {p2}" + ("" if p1 is not None and p2 is not None else " (UNRESOLVED)"))
            named = True
        head += " flip=%d vboxes=%s" % (flip, "|".join("-" if b is None else "%d,%d,%d,%d" % b for b in vulns))
        head += f" node={locate(p2, v['vnode'] & 0xFFFFFF) if p2 is not None else '?'}"
        print(head)
        for (k, ty, rid, (ax, ay, ahw, ahh)) in atk:
            gaps = []
            for b in vulns:
                if b is None:
                    gaps.append("(none)")
                    continue
                cx, cy, hw, hh = b
                gx = abs(ax - cx) - (ahw + hw)
                gy = abs(ay - cy) - (ahh + hh)
                gaps.append(f"({gx},{gy}){'*' if gx <= 0 and gy <= 0 else ''}")
            print(f"   slot{k} type={ty:#04x} rec={rid:#x} box y {ay - ahh}..{ay + ahh} x {ax - ahw}..{ax + ahw} "
                  f"gaps(v0,v1,v2)={' '.join(gaps)}")


if __name__ == "__main__":
    main()
