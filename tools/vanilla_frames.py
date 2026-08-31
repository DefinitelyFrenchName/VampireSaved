#!/usr/bin/env python3
"""vanilla_frames.py — derive per-move frame data for a VANILLA vsavj character,
the same figures tools/charmap_md.py derives for the three tenants (14z-125,
the community cross-check).

  python3 tools/vanilla_frames.py [image.bin] [--char DE|0x01|all] [--json out.json]

WHY A SIBLING AND NOT A FLAG ON charmap_gen.py. That tool's `Built` class needs
`verify_data.bin` + `patch/placements.json`, and tools/extract_char.py refuses
any (set, char) without a CHAR_ANCHORS row — there is no vsavj row. A vanilla
character has no port, no placement and no "ours" side: there is only the game.
So this reads the vsavj DATA VIEW directly and uses the same decoders:

  build/manifest/bank_map.toml  the 32-row bank; row = table.vsavj + id*4
  tools/anim_nodes.py           the node-chain walker (already character-agnostic)
  tools/hitbox_records.py       HitboxSet.from_image (the raw-image constructor)
  tools/frame_data.py           THE startup/active/recovery derivation

THE MOVE JOIN IS MEASURED, NOT ASSUMED. Table `a2`'s standing-normal slots come
in CLOSE/FAR pairs and the engine picks by proximity; which slot is which was
settled in-emulator by tests/test_vanilla_frame_join.sh (see NORMALS below), not
by fitting our numbers against the community sheet — a fit against the very
source being checked is circular and cannot be the evidence ([VSP-19]: verdict
logic is itself tested). Two structural shortcuts were tried first and BOTH were
discarded on their own controls: predicting a character's command normals from
whether our odd slot aliases the even one scored 31/90, and the close/far fit
against the sheet is the circular one. The rig replaced both.
"""
import argparse
import hashlib
import json
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _minitoml  # noqa: E402
import anim_nodes  # noqa: E402
import frame_data  # noqa: E402
import hitbox_records  # noqa: E402

REPO = Path(__file__).resolve().parent.parent

# sheet tab -> vsavj character id (maintainer-confirmed 2026-08-31: the tab is the
# first two letters of the JAPANESE name; LE = Lei-Lei, LI = Lilith). STATE 14z-124.
CHARS = {"BU": (0x00, "Bulleta"), "DE": (0x01, "Demitri"), "GA": (0x02, "Gallon"),
         "VI": (0x03, "Victor"), "ZA": (0x04, "Zabel"), "MO": (0x05, "Morrigan"),
         "AN": (0x06, "Anakaris"), "FE": (0x07, "Felicia"), "BI": (0x08, "Bishamon"),
         "AU": (0x09, "Aulbath"), "SA": (0x0A, "Sasquatch"), "QB": (0x0C, "Q-Bee"),
         "LE": (0x0D, "Lei-Lei"), "LI": (0x0E, "Lilith"), "JE": (0x0F, "Jedah")}

# The CROUCHING and JUMPING slots are the layout measured on all three tenants by
# tools/name_moves.py (gate tests/test_move_naming.sh) — not re-measured on vanilla
# characters, and said so on the page.
FIXED = {0x0c: "2LP", 0x0d: "2MP", 0x0e: "2HP", 0x0f: "2LK", 0x10: "2MK", 0x11: "2HK",
         0x12: "J.LP", 0x13: "J.MP", 0x14: "J.HP", 0x15: "J.LK", 0x16: "J.MK", 0x17: "J.HK"}
# The STANDING normals are NOT a fixed layout: which chain a button enters depends on
# the character AND on proximity, and it was MEASURED per character on vsavj rather
# than assumed (tools/vanilla_join_rig.py, frozen here). A first model — even = close,
# odd = far for everyone — was overturned by that measurement; see the rig's header.
SLOTS_TSV = REPO / "tests/expected/vanilla_normal_slots.tsv"


def measured_slots(path=SLOTS_TSV):
    """{tab: {slot int: move name}} from the frozen rig measurement. The FAR chain is
    the sheet's plain row (`5MP`); a DIFFERENT near chain is its `CL.` row. Where the
    two are the same chain the character simply has no close variant and only the
    plain name is used."""
    per = {}
    if not Path(path).exists():
        return per
    for ln in Path(path).read_text().splitlines():
        if not ln.strip() or ln.startswith("#"):
            continue
        tab, dist, btn, chain = ln.split("\t")
        if not chain.startswith("a2:"):
            continue
        per.setdefault(tab, {}).setdefault(btn, {})[dist] = int(chain.split(":")[1], 16)
    out = {}
    for tab, btns in per.items():
        m = dict(FIXED)
        for btn, d in btns.items():
            far, near = d.get("far"), d.get("near")
            if far is not None:
                m[far] = "5" + btn
            if near is not None and near != far:
                m[near] = "CL.5" + btn
        out[tab] = m
    return out


SLOT_ROLE = {**{k: "crouching (tenant-measured layout)" for k in range(0x0c, 0x12)},
             **{k: "jumping (tenant-measured layout)" for k in range(0x12, 0x18)}}

DEFAULT_IMAGE = REPO / "build/out/vsavj_data.bin"


def bank_rows(bank_map):
    return {t["name"]: t for t in _minitoml.loads(Path(bank_map).read_text())["table"]}


def row_ptr(img, table, cid):
    """the character's entry of a 32-row pointer bank table: base + id*4."""
    a = table["vsavj"] + cid * 4
    return struct.unpack(">I", img[a:a + 4])[0]


def derive_char(img, rows, cid, names=None):
    """Every chain of tables a and a2 for one vanilla character, with frame data."""
    H = hitbox_records.HitboxSet.from_image(img, row_ptr(img, rows["hitbox_base"], cid),
                                            row_ptr(img, rows["hitbox_comp"], cid))
    out = {"char_id": f"{cid:#04x}",
           "hitbox_base": f"{H.base:#x}", "hitbox_comp": f"{H.comp:#x}",
           "tables": {k: f"{v:#x}" for k, v in H.tables.items()}, "chains": {}}
    for tn in ("a", "a2"):
        tbl = row_ptr(img, rows["anim_index_" + tn], cid)
        w = anim_nodes.walk_table(img, 0, tbl, len(img))
        out.setdefault("anim_tables", {})[tn] = {"ptr": f"{tbl:#x}", "entries": w["entries"]}
        for seq, c in w["chains"].items():
            if not c.get("start"):
                continue
            durs = [n["dur"] for n in c["nodes"]]
            atk = [n["hbA"] >> 8 for n in c["nodes"]]
            hids, recs = {}, {}
            for a in {x for x in atk if x}:
                try:
                    r = H.record(a)
                except IndexError:
                    continue
                hids[a] = r["hit_id"]
                recs[a] = {"real": r["real"], "white": r["white"], "meter": r["meter"],
                           "cls": r["cls"], "hit_id": r["hit_id"], "strength": r["strength"],
                           "pb_hit": r["pb_hit"], "pb_blk": r["pb_blk"], "freeze": r["freeze"]}
            fd = frame_data.derive(durs, atk, hids)
            sq = int(seq, 16)
            row = {"table": tn, "seq": seq, "start": c["start"], "nodes": len(c["nodes"]),
                   "frames": c["frames"], "end": c["end"], "records": recs}
            nm = names if names is not None else FIXED
            if tn == "a2" and sq in nm:
                row["move"] = nm[sq]
                row["slot_role"] = SLOT_ROLE.get(sq, "standing (rig-measured)")
            if fd:
                row["frame_data"] = {k: fd[k] for k in ("startup", "active", "span", "recovery",
                                                        "first", "last", "records", "notation")}
                # the first record is the one a single-hit move's damage columns compare against
                first_rec = fd["records"][0]
                if first_rec in recs:
                    row["damage"] = {"red": recs[first_rec]["real"], "white": recs[first_rec]["white"],
                                     "gauge_hit": recs[first_rec]["meter"]}
                # a multi-hit move's sheet cell is per hit (`7+7+11`), so carry the sequence too
                if len(fd["runs"]) > 1:
                    seq_recs = [r["records"][0] for r in fd["runs"] if r["kind"] == "hit"]
                    row["damage_per_hit"] = {
                        "red": [recs[r]["real"] for r in seq_recs if r in recs],
                        "white": [recs[r]["white"] for r in seq_recs if r in recs],
                        "gauge_hit": [recs[r]["meter"] for r in seq_recs if r in recs]}
            out["chains"][f"{tn}:{seq}"] = row
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image", nargs="?", type=Path, default=DEFAULT_IMAGE,
                    help="vsavj DATA-view image (default build/out/vsavj_data.bin)")
    ap.add_argument("--bank-map", type=Path, default=REPO / "build/manifest/bank_map.toml")
    ap.add_argument("--char", default="all", help="sheet tab (DE), id (0x01) or 'all'")
    ap.add_argument("--json", type=Path)
    a = ap.parse_args()

    if not a.image.exists():
        sys.exit(f"{a.image} is absent — make it with:\n"
                 f"  python3 tools/cps2_decrypt.py \"$ROMDIR/vsavj.zip\" build/out/vsavj_opcodes.bin "
                 f"--data-out {a.image}")
    img = a.image.read_bytes()
    print(f"read {a.image} ({len(img)} bytes) sha1 {hashlib.sha1(img).hexdigest()}")
    rows = bank_rows(a.bank_map)
    slots = measured_slots()
    if not slots:
        print("  NOTE: tests/expected/vanilla_normal_slots.tsv absent — standing normals unnamed")

    if a.char == "all":
        want = list(CHARS.items())
    else:
        key = a.char.upper()
        if key in CHARS:
            want = [(key, CHARS[key])]
        else:
            cid = int(a.char, 0)
            hit = [(t, v) for t, v in CHARS.items() if v[0] == cid]
            want = hit or [(f"{cid:#04x}", (cid, f"id {cid:#04x}"))]

    doc = {"source": {"image": str(a.image), "sha1": hashlib.sha1(img).hexdigest(),
                      "bank_map": str(a.bank_map)},
           "normal_slots": {t: {f"{k:#04x}": v for k, v in m.items()} for t, m in slots.items()},
           "slots_measured_by": str(SLOTS_TSV.relative_to(REPO)),
           "characters": {}}
    for tab, (cid, name) in want:
        d = derive_char(img, rows, cid, slots.get(tab))
        d["name"] = name
        d["tab"] = tab
        doc["characters"][tab] = d
        named = sum(1 for c in d["chains"].values() if "move" in c and "frame_data" in c)
        print(f"  {tab} {name:10} id {cid:#04x}  a2 {d['anim_tables']['a2']['ptr']}  "
              f"{d['anim_tables']['a2']['entries']:3} chains  {named}/24 named normal slots with frame data")

    if a.json:
        a.json.parent.mkdir(parents=True, exist_ok=True)
        a.json.write_text(json.dumps(doc, indent=1, sort_keys=True) + "\n")
        print(f"wrote {a.json}")


if __name__ == "__main__":
    main()
