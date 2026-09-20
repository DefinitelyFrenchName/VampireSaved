#!/usr/bin/env python3
"""audit_same_data_p2.py — WHICH LEGACY CHARACTER, IF ANY, CARRIES THE SAME
CHARACTER DATA ON vsavj AND vsav2 (14z-164, GitHub #136 proposition 2,
maintainer-agreed 2026-09-17).

  python3 tools/audit_same_data_p2.py <vsavj_data.bin> <vsav2_data.bin> [--ids 03,05] [--json out]

WHY. The tenant-move rigs PUT VICTOR ON P2 UNTIL 14z-165; on our leg he is
Vampire Savior's Victor and on the native leg Vampire Savior 2's, and the
14z-164 census found five of the 13 first divergences begin in HIS state. A P2
whose data is the same on both games removes that confound. THIS TOOL'S ANSWER
WAS ACTED ON: the maintainer ruled Demitri (Bishamon the fallback) on
2026-09-17 and the naming rigs switched at 14z-165, so the rigs no longer put
Victor on P2 — the tool now guards that choice rather than motivating it. The three-sibling law ([VSE-1]: the
per-character bank is index-aligned across the sets) makes the question STATIC:
for every legacy id both games carry, compare what the bank row reaches.

WHAT IS COMPARED, per id (the classes a VICTIM's behaviour rests on first):
  values   every value16 / value8 / rec8 / byte2d row of the bank (bytes)
  auto     every `auto` row (bytes — a differing auto row may be a pointer
           that legitimately differs by the sibling shift; reported, never
           counted as a data difference on its own)
  anim     tables a / a2 / b / c / proj walked by tools/anim_nodes.py on both
           games: per seq the node count, each node's dur / flags / shadow /
           op / sfx, the link as an index INTO THE CHAIN, the end kind, AND THE
           NODE'S RESOLVED HITBOXES — its three vuln boxes, its push box and
           its attack record's content (box, powers, meter, class, pushback,
           facing, freeze, scale, recovery, strength, special) resolved through
           tools/hitbox_records.py. Indices (hb8 / hbA / the hit id) are NOT
           compared: vs2 renumbered the family and record tables when it grew
           them (Bulleta 80 -> 85 families), and an index is not content
           ([VSP-53]). A link or loop target that LEAVES its chain is compared
           by where it lands in the character's own graph, (table, seq, node),
           never collapsed to one token (run 2026-09-17-26); a target that no
           walked chain of the character contains (an EXTERNAL node — Zabel
           and Jedah carry dozens) is compared by that node's OWN content with
           its boxes resolved, counted per row as an external link, and only a
           target outside the image is an unknown link (counted per row); a
           seq whose walk runs OUT OF THE REGION or away (the walker's own
           verdict: an entry past the table's live chains, walked as garbage)
           is not a chain — counted per row as an invalid chain on that side
           and never compared node by node (Zabel and Jedah carry dozens, and
           their garbage differed by game by construction); a seq that is a
           live chain on one game and invalid on the other is listed per row
           as `invalid_one_side`, never as a content difference (run 27:
           Demitri's c:0x2e is live on vsavj and out_of_region on vs2); the
           sprite-record pointer is the one node field not compared (it is
           relocated between games). A node whose boxes cannot be resolved is
           counted per row (`unresolved_nodes`), never read as equal. The first
           pass compared raw tables and indices and read every character as
           differing on ~half its chains — the renumbering, not the data.
  hitbox   raw table lengths are reported as information only (the attack
           table's end is not bounded in a whole image)
  defense  the defender-side defense-curve row (vsavj PRG:0x0B8940, vs2
           PRG:0x0D2ABE, 32 B per victim id — docs/project/tables/defense_rows.md)
  proj     the projectile chains are resolved through the PROJECTILE hitbox
           tables (bank rows proj_hitbox_base / proj_hitbox_comp), never the
           fighter's (rule-checker run 2026-09-17-24)
NOT COMPARED, and the verdict does not rest on them (stated, not silent —
run 2026-09-17-24): the 21 code_ptr rows (the character's own routines,
relocated between games); the 19 `auto` rows (kind unknown to the bank map —
a differing auto row is COUNTED in its own column and reported, never
classed as data or as a pointer); and the six data_ptr rows the tool does
not decode — capture_kf_ptr (the throw-victim keyframes, a per-ATTACKER
block, swept by tests/audit_capture_matrix.sh), tail_data_ptr, ai_script_0-3
(CPU-only, GitHub #129). A P2 that only stands and gets hit runs engine code
and its data, which is what the compared classes hold.
"NEAREST FOR A VICTIM ROLE" is a stated metric, not a verdict: table a (the
base states a standing P2 lives in) identical FIRST, then the fewest differing
b chains (the reactions a hit P2 runs), shared sequences only. Under it
Demitri (a: same; b: 3) and Bishamon (a: 2; b: 2) lead; Bulleta has the fewest
b differences of all (b:0x10 alone, the engine-wide held-pose push box) but
three table-a chains differ (0x24/0x26/0x27), so she ranks behind them on
the first criterion and is the alternative if those chains are never entered.
The verdict per id: SAME-DATA when every compared class is identical;
otherwise the differing classes. "Which chains differ" and the "nearest"
reading are over the SHARED sequences of a table; sequences present in one
game only are counted separately per table (`only_vsavj` / `only_vsav2`) and
frozen, never folded into "differ" — vs2 grew several tables (Bishamon's c:
56 -> 178, Zabel's b: 178 -> 285). Prints the SHA-1 of both images.
"""
import argparse, hashlib, json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import _minitoml as mt
from anim_nodes import walk_table
from hitbox_records import HitboxSet

NAMES = {0x00: "Bulleta", 0x01: "Demitri", 0x02: "Gallon", 0x03: "Victor", 0x04: "Zabel", 0x05: "Morrigan",
         0x06: "Anakaris", 0x07: "Felicia", 0x08: "Bishamon", 0x09: "Aulbath", 0x0A: "Sasquatch",
         0x0B: "(random cell)", 0x0C: "Q-Bee", 0x0D: "Lei-Lei", 0x0E: "Lilith", 0x0F: "Jedah"}
VACATED = {0x02, 0x09, 0x0A}           # the three vs2 dropped (atlas/select_screen.md)
SHARED = [i for i in range(16) if i not in VACATED and i != 0x0B]
DEFENSE = {"vsavj": 0x0B8940, "vsav2": 0x0D2ABE}


def rd32(img, a): return int.from_bytes(img[a:a + 4], "big")


REC_KEYS = ("box", "real", "white", "meter", "strength", "special", "cls", "pb_hit", "pb_blk", "facing", "freeze", "scale", "recov")


TABLES = ("anim_index_a", "anim_index_a2", "anim_index_b", "anim_index_c", "anim_index_proj")


def node_index(img, rows, d, cid):
    """every node address of the character's five tables -> (table, seq, node #),
    so a link or a loop that leaves its chain is compared by WHERE IT LANDS in
    the character's own graph, not collapsed to one token (run 2026-09-17-26)"""
    idx = {}
    for name in TABLES:
        try:
            res = walk_table(img, 0, rd32(img, rows[name] + d + cid * 4))
        except Exception:
            continue
        for seq, ch in res["chains"].items():
            for k, n in enumerate(ch["nodes"]):
                idx.setdefault(n["addr"], (name[11:], seq, k))
    return idx


def ext_node(img, hb, addr):
    """the comparable content of ONE node reached by a link that lands in no
    walked chain of the character (an EXTERNAL target): its own fields with the
    boxes resolved, so the target is compared by what it is, never by its
    address (run 2026-09-17-26: raw addresses differ by game and inflated the
    diff counts of link-heavy characters)"""
    try:
        a = int(addr, 16) if isinstance(addr, str) else int(addr)
        b = img[a:a + 0x18]
        if len(b) < 0x18:
            return ("UNKNOWN", "out-of-image")
        hb8 = int.from_bytes(b[8:10], "big"); hbA = int.from_bytes(b[10:12], "big")
        try:
            bx = hb.node_boxes(hb8, hbA); rec = bx["attack"]
            boxes = (tuple(bx["vuln"]), bx["push"], tuple(rec[k] for k in REC_KEYS) if rec else None)
        except Exception:
            boxes = ("UNRESOLVED",)
        return ("EXT", b[0], b[1], b[0x16], b[0x10:0x16].hex(), boxes)
    except Exception:
        return ("UNKNOWN", str(addr))


def chain_shape(img, table, hb, index):
    """the walker's chains reduced to what is comparable across games: node
    timing/flags/script/sfx, the link and the loop target as (table, seq, node)
    in the character's own graph, and the RESOLVED boxes and attack record of
    every node (never the indices). A node whose boxes cannot be resolved is
    counted (`unresolved`), never silently equal."""
    res = walk_table(img, 0, table)
    out = {}
    for seq, ch in res["chains"].items():
        if ch["end"] in ("out_of_region", "runaway"):
            # the walker ran off the real chains into data (a seq entry past the
            # table's live chains): NOT a chain — counted per row, never compared
            # node by node (its "nodes" are garbage and differ by game by construction)
            out[seq] = ("INVALID", ch["end"], 0)
            continue
        nodes = ch["nodes"]
        shape = []
        unresolved = 0
        for n in nodes:
            link = n.get("link")
            li = None if link is None else index.get(link) or ext_node(img, hb, link)
            try:
                bx = hb.node_boxes(n["hb8"], n["hbA"])
                rec = bx["attack"]
                boxes = (tuple(bx["vuln"]), bx["push"], tuple(rec[k] for k in REC_KEYS) if rec else None)
            except Exception as e:
                boxes = ("UNRESOLVED",); unresolved += 1
            shape.append((n["dur"], n["flags"], n.get("shadow"), n.get("op"), n.get("sfx"), li, boxes))
        end = ch["end"]
        if isinstance(end, str) and end.startswith("loop:"):
            la = end[5:]  # the walker's own hex-string form, the index's key form
            end = ("loop",) + (index.get(la) or ext_node(img, hb, la))
        out[seq] = (shape, end, unresolved)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vsavj"); ap.add_argument("vsav2")
    ap.add_argument("--ids", help="comma-separated hex ids (default: every legacy id both games carry)")
    ap.add_argument("--bank", default=str(Path(__file__).parent.parent / "build/manifest/bank_map.toml"))
    ap.add_argument("--json")
    ap.add_argument("--layout", choices=("vsav2", "vsavj"), default="vsav2",
                    help="which game's LAYOUT (bank origin, defense table) the SECOND image is read with; vsavj = read both images alike (the gate's self-compare control)")
    a = ap.parse_args()
    imgs = {"vsavj": Path(a.vsavj).read_bytes(), "vsav2": Path(a.vsav2).read_bytes()}
    for k, v in imgs.items():
        print(f"{k}: {a.__dict__[k]} sha1 {hashlib.sha1(v).hexdigest()} ({len(v)} bytes)")
    bank = mt.loads(Path(a.bank).read_text())
    orig = {"vsavj": int(bank["origins"]["vsavj"]), "vsav2": int(bank["origins"]["vsav2"])}
    delta = orig[a.layout] - orig["vsavj"]
    def_b = DEFENSE[a.layout]
    print(f"second image read with the {a.layout} layout: bank offset {delta:#x}, defense table {def_b:#x}")
    tables = bank["table"]
    ids = [int(x, 16) for x in a.ids.split(",")] if a.ids else SHARED
    report = {}
    for cid in ids:
        r = {"name": NAMES.get(cid, "?"), "values_diff": [], "auto_diff": [], "hitbox_diff": [], "anim_diff": [],
             "defense_same": None, "code_ptr_rows": 0, "data_ptr_not_compared": []}
        for t in tables:
            kind, base = t["kind"], int(t["vsavj"])
            if kind == "code_ptr":
                r["code_ptr_rows"] += 1; continue
            if kind == "data_ptr":
                if t["name"] not in ("anim_index_a", "anim_index_a2", "anim_index_b", "anim_index_c", "anim_index_proj",
                                     "hitbox_base", "hitbox_comp", "proj_hitbox_base", "proj_hitbox_comp"):
                    r["data_ptr_not_compared"].append(t["name"])
                continue
            if kind == "byte2d":
                w = int(t["span"]) // 32; off = cid * w
            else:
                stride = int(t["stride"]); w = stride // 32; off = cid * w
            va = imgs["vsavj"][base + off: base + off + w]; vb = imgs["vsav2"][base + delta + off: base + delta + off + w]
            if va != vb:
                (r["auto_diff"] if kind == "auto" else r["values_diff"]).append(t["name"])
        # hitbox
        rows = {t["name"]: int(t["vsavj"]) for t in tables}
        hb = {}
        for g, img in imgs.items():
            d = 0 if g == "vsavj" else delta
            hb[g] = HitboxSet.from_image(img, rd32(img, rows["hitbox_base"] + d + cid * 4), rd32(img, rows["hitbox_comp"] + d + cid * 4))
        for tab in ("vuln0", "vuln1", "vuln2", "push"):
            la, lb = hb["vsavj"].table_len(tab), hb["vsav2"].table_len(tab)
            if la != lb: r["hitbox_diff"].append(f"{tab} table {la}/{lb}B")
        fa, fb = hb["vsavj"].family_count(), hb["vsav2"].family_count()
        if fa != fb: r["hitbox_diff"].append(f"families {fa}/{fb}")
        # anim
        index = {g: node_index(img, rows, 0 if g == "vsavj" else delta, cid) for g, img in imgs.items()}
        r["unresolved_nodes"] = {"vsavj": 0, "vsav2": 0}
        r["unknown_links"] = {"vsavj": 0, "vsav2": 0}
        phb = {}
        r["proj_tables"] = {}
        for g, img in imgs.items():
            d = 0 if g == "vsavj" else delta
            try:
                phb[g] = HitboxSet.from_image(img, rd32(img, rows["proj_hitbox_base"] + d + cid * 4), rd32(img, rows["proj_hitbox_comp"] + d + cid * 4))
                r["proj_tables"][g] = "ok"
            except Exception as e:  # NO silent fallback to the fighter's tables (run 2026-09-17-25 Q1): the state is frozen per row
                phb[g] = None
                r["proj_tables"][g] = "none"
        for name in ("anim_index_a", "anim_index_a2", "anim_index_b", "anim_index_c", "anim_index_proj"):
            sh = {}
            for g, img in imgs.items():
                d = 0 if g == "vsavj" else delta
                try:
                    if name == "anim_index_proj" and phb[g] is None:
                        sh[g] = {"UNRESOLVED": "no projectile hitbox tables on " + g}
                    else:
                        sh[g] = chain_shape(img, rd32(img, rows[name] + d + cid * 4), phb[g] if name == "anim_index_proj" else hb[g], index[g])
                        for shp, end, unres in sh[g].values():
                            if shp == "INVALID":
                                r.setdefault("invalid_chains", {"vsavj": 0, "vsav2": 0})[g] += 1; continue
                            r["unresolved_nodes"][g] += unres
                            r["unknown_links"][g] += sum(1 for nd in shp if isinstance(nd[5], tuple) and nd[5][0] == "UNKNOWN") + (1 if isinstance(end, tuple) and len(end) > 1 and end[1] == "UNKNOWN" else 0)
                            r.setdefault("external_links", {"vsavj": 0, "vsav2": 0})[g] += sum(1 for nd in shp if isinstance(nd[5], tuple) and nd[5][0] == "EXT") + (1 if isinstance(end, tuple) and len(end) > 1 and end[1] == "EXT" else 0)
                except Exception as e:  # a walk that refuses is a difference to look at, not a pass
                    sh[g] = {"ERROR": str(e)}
            if sh["vsavj"] != sh["vsav2"]:
                ka, kb = set(sh["vsavj"]), set(sh["vsav2"])
                comp = {}
                nd = 0
                one_side_invalid = sorted(k for k in ka & kb if (sh["vsavj"][k][0] == "INVALID") != (sh["vsav2"][k][0] == "INVALID"))
                for k in ka & kb:
                    A, B = sh["vsavj"][k], sh["vsav2"][k]
                    if A == B: continue
                    if k in one_side_invalid:
                        comp["invalid-one-side"] = comp.get("invalid-one-side", 0) + 1; continue  # never a CONTENT difference (run 2026-09-17-27)
                    nd += 1
                    if len(A[0]) != len(B[0]) or A[1] != B[1]:
                        comp["nodes/end"] = comp.get("nodes/end", 0) + 1; continue
                    for na, nb in zip(A[0], B[0]):
                        for i, lab in enumerate(("dur", "flags", "shadow", "op", "sfx", "link", "boxes")):
                            if na[i] != nb[i]: comp[lab] = comp.get(lab, 0) + 1
                r["anim_diff"].append(f"{name[11:]}(seqs {len(ka)}/{len(kb)}, {nd} differ: {comp})")
                r.setdefault("anim_seqs_diff", {})[name[11:]] = {"differ": sorted(k for k in ka & kb if sh["vsavj"][k] != sh["vsav2"][k] and k not in one_side_invalid),
                                                                  "invalid_one_side": one_side_invalid,
                                                                  "only_vsavj": sorted(ka - kb), "only_vsav2": sorted(kb - ka)}
            else:
                ka = set(sh["vsavj"])
                r.setdefault("anim_seqs_diff", {})[name[11:]] = {"differ": [], "invalid_one_side": [], "only_vsavj": [], "only_vsav2": []}
        # defense row
        r["defense_same"] = imgs["vsavj"][DEFENSE["vsavj"] + cid * 32: DEFENSE["vsavj"] + cid * 32 + 32] == \
                            imgs["vsav2"][def_b + cid * 32: def_b + cid * 32 + 32]
        same = not (r["values_diff"] or r["anim_diff"]) and r["defense_same"]
        r["verdict"] = "SAME-DATA" if same else "DIFFERS"
        report[f"{cid:#04x}"] = r
        print(f"{cid:#04x} {r['name']:10} {r['verdict']:9} values:{r['values_diff'] or '-'} hitbox:{r['hitbox_diff'] or '-'} "
              f"anim:{r['anim_diff'] or '-'} defense:{'same' if r['defense_same'] else 'DIFFERS'} auto-rows-differing:{len(r['auto_diff'])} "
              f"unresolved-nodes:{r['unresolved_nodes']} external-links:{r.get('external_links')} unknown-links:{r['unknown_links']} invalid-chains:{r.get('invalid_chains')} "
              f"not-compared: {r['code_ptr_rows']} code_ptr rows, data_ptr {r['data_ptr_not_compared']}")
    if a.json:
        Path(a.json).write_text(json.dumps(report, indent=1))
    n = sum(1 for r in report.values() if r["verdict"] == "SAME-DATA")
    print(f"SAME-DATA legacy characters: {n} of {len(report)}")


if __name__ == "__main__":
    main()
