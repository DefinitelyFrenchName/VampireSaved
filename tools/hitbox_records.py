#!/usr/bin/env python3
"""hitbox_records.py — decode a tenant's HITBOX tables and ATTACK RECORDS
(character-data map, PHASE 2; measured 14z-120 (5) on native vs2 with
tools/name_moves.py parts 9/10 under tests/lua/field_trace.lua and the
-debug write tap tests/lua/trace_writes.lua — see tests/test_hitbox_encoding.sh).

  python3 tools/hitbox_records.py <build/<tenant>/extract> [--json out.json] [--node-boxes hb8 hbA]

THE ENCODING, MEASURED (every claim below is what the engine did, not a reading):

  fighter +0x60.l = hitbox BASE (bank row `hitbox_base`): a table of WORD
  offsets base[0..4] from the base itself. The fighter's resolved table
  pointers are  +0x80 = base+base[0]  (vuln table 0)
                +0x84 = base+base[1]  (vuln table 1)
                +0x88 = base+base[2]  (vuln table 2)
                +0x8C = base+base[4]  (ATTACK records, 0x20 bytes each)
                +0x90 = base+base[3]  (PUSH boxes)
  — the community row had +0x8C/+0x90 the other way round; the tap read
  the live pointers (`ff848c` = 0xC986A = base+base[4] for Donovan).

  A BOX is 4 signed words (x, y, hw, hh): centre = (fighter x + x', fighter
  y + y) with x' = x when flip_x (+0x0B) is 0 and -x when flip_x is 1
  (the data is authored for the unflipped sprite, which faces LEFT — so a
  forward box has a NEGATIVE x), half-extents hw/hh, y up (ground = 40).
  Verified: on 8/8 fighter hits the victim's HP write came on the first
  frame the attack box overlapped one of the victim's three vuln boxes, and
  no whiff window ever overlapped (the only extra overlap was a second
  record of the same move while the victim was already in hitstun — the
  hit-id dedup); the un-mirrored convention overlapped on 0/8.

  fighter +0x64.l = the FAMILY table (bank row `hitbox_comp`): 4 bytes per
  entry {vuln0, vuln1, vuln2, push} — box ids into tables 0/1/2 and the
  push table. A node's hb8 word (+8) indexes it; the fighter's +0x94.l is
  the entry (measured equal every frame).

  A node's hbA word (+0xA) >> 8 is the ATTACK RECORD index (0 = not
  attacking; a chain's ACTIVE frames are its nodes with hbA != 0). Record
  (0x20 bytes): +0 box (4 words), +8 real power, +9 white power, +0x10
  hit id (the multi-hit dedup key), +0x14 the ATTACKER'S METER GAIN on a
  hit (measured: 6/12/18 on L/M/H normals, 3 per Lightning Sword tick, 9
  Ifrit, 2 the column — a fraction of it on block; the VICTIM gains 8 per
  hit whatever the record), +0x17 REACTION CLASS, +0x1C scales the
  PUSHBACK (the victim moved 27/41/59 px in 15 frames for 0x14/0x1E/0x28;
  0x46 on specials — the exact law is not derived), +0x1D always 0.
  Observed, not proven: +0x12 = the strength index (1/2/3 on L/M/H, 7 on
  specials), +0x16 = 1 on specials/projectiles, +0x11 (5/6/7 normals,
  0xC/0x3/0xD specials) and +0x13/+0x15 unexplained. The stager reads +0x17 (`move.b $17(a3),
  $54(a1)` at vs2 0x16F70 for the generic classes; the special classes
  dispatch on it to handlers that write their class as an immediate —
  0x4E electric at 0x16FE4, 0x52 column at 0x16FEC, 0x0A at 0x16FF4 — and
  a counter test at 0x16F5E forces class 1). PROJECTILES use the same
  record shape from the `hitbox_proj` region (the object-hit applier
  0x28A6A: `A3 = ($8C,a6) + id*0x20`, then the same +0x17 dispatch —
  Blizzard Sword's record 0xD0D22 has +0x17 = 0x14 and the victim got
  0x14). The "+0x1D class byte" in older notes was never observed.
"""
import argparse
import json
import struct
import sys
from pathlib import Path

REC = 0x20


def s16(x):
    return x - 0x10000 if x >= 0x8000 else x


class HitboxSet:
    def __init__(self, extract):
        ex = Path(extract)
        rj = json.loads((ex / "regions.json").read_text())
        self.vals = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if "ptr" in v}
        r = rj["regions"]["hitbox"]
        self.src, self.img = r["src"], (ex / "region_hitbox.bin").read_bytes()
        rp = rj["regions"].get("hitbox_proj")
        self.psrc, self.pimg = (rp["src"], (ex / "region_hitbox_proj.bin").read_bytes()) if rp else (None, b"")
        self._resolve()

    @classmethod
    def from_image(cls, img, base, comp, src=0, vals=None, proj_base=None):
        """A hitbox set read straight out of a WHOLE data-view image, for a character
        that has no extract — i.e. any VANILLA vsavj character (14z-125, the community
        cross-check). `base`/`comp` are the per-character bank rows `hitbox_base` /
        `hitbox_comp` (build/manifest/bank_map.toml, row = table.vsavj + id*4); the
        decoding below is identical, because the encoding is the engine's, not the port's."""
        self = cls.__new__(cls)
        self.img, self.src = img, src
        self.pimg, self.psrc = b"", None
        self.vals = dict(vals or {})
        self.vals.setdefault("hitbox_base", base)
        self.vals.setdefault("hitbox_comp", comp)
        if proj_base is not None:
            self.vals.setdefault("proj_hitbox_base", proj_base)
        self._resolve()
        return self

    def _resolve(self):
        self.end = self.src + len(self.img)
        self.base = self.vals["hitbox_base"]
        self.comp = self.vals["hitbox_comp"]
        self.words = [self.rd16(self.base + 2 * i) for i in range(5)]
        # +0x80/84/88 = tables 0/1/2; +0x8C (attack) = base[4]; +0x90 (push) = base[3]
        self.tables = {"vuln0": self.base + self.words[0], "vuln1": self.base + self.words[1],
                       "vuln2": self.base + self.words[2], "attack": self.base + self.words[4],
                       "push": self.base + self.words[3]}

    def rd(self, addr, n):
        if self.src <= addr < self.end:
            return self.img[addr - self.src: addr - self.src + n]
        if self.psrc is not None and self.psrc <= addr < self.psrc + len(self.pimg):
            return self.pimg[addr - self.psrc: addr - self.psrc + n]
        raise IndexError(hex(addr))

    def rd16(self, addr):
        return struct.unpack(">H", self.rd(addr, 2))[0]

    def box(self, addr):
        return tuple(s16(x) for x in struct.unpack(">4H", self.rd(addr, 8)))

    def family(self, idx):
        return list(self.rd(self.comp + 4 * idx, 4))

    def family_count(self):
        return (self.base - self.comp) // 4

    def table_len(self, name):
        start = self.tables[name]
        nxt = min([t for t in self.tables.values() if t > start] + [self.end])
        return nxt - start

    def record(self, idx, proj=False):
        a = (self.proj_attack() if proj else self.tables["attack"]) + idx * REC
        b = self.rd(a, REC)
        return {"addr": f"{a:#x}", "box": self.box(a), "real": b[8], "white": b[9], "hit_id": b[0x10],
                "meter": b[0x14], "strength": b[0x12], "special": b[0x16],
                "cls": b[0x17], "b1c": b[0x1c], "b1d": b[0x1d],
                # 14z-121 (3), from the record's READERS (engine_internals "The attack record's fields, by their readers"):
                "pb_hit": b[0x0c], "pb_blk": b[0x0d],      # PUSHBACK step-table index on hit / on block (vs2 0x2783C[idx] -> victim +0x59 -> 0x27038 steps x per frame)
                "facing": b[0x0e], "freeze": b[0x13],      # the victim's facing rule; the hit-freeze class (pairs table 0x17FA4)
                "scale": b[0x1a], "recov": b[0x1b],        # combo-scaling row selector (0 = the attacker's own); white-damage recovery-rate class (0x18018)
                "raw": b.hex()}

    def proj_attack(self):
        pb = self.vals["proj_hitbox_base"]
        return pb + self.rd16(pb + 8)

    def proj_count(self):
        return (self.psrc + len(self.pimg) - self.proj_attack()) // REC

    def node_boxes(self, hb8, hbA):
        fam = self.family(hb8)
        out = {"family": hb8, "vuln": [self.box(self.tables[f"vuln{i}"] + 8 * fam[i]) for i in range(3)],
               "push": self.box(self.tables["push"] + 8 * fam[3]), "attack": None}
        if hbA:
            out["attack"] = self.record(hbA >> 8)
        return out


def placed(cx, cy, flip_x, box):
    """world rectangle (x0, x1, y0, y1) of a box on a fighter at (cx, cy) facing flip_x (1 = right)."""
    x, y, hw, hh = box
    ox = -x if flip_x else x
    return (cx + ox - hw, cx + ox + hw, cy + y - hh, cy + y + hh)


def overlap(a, b):
    return a[0] < b[1] and b[0] < a[1] and a[2] < b[3] and b[2] < a[3]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("extract", type=Path)
    ap.add_argument("--json", type=Path)
    ap.add_argument("--node-boxes", nargs=2, type=lambda x: int(x, 0), metavar=("HB8", "HBA"))
    a = ap.parse_args()
    H = HitboxSet(a.extract)
    n_att = H.table_len("attack") // REC
    print(f"hitbox base {H.base:#x} family {H.comp:#x} ({H.family_count()} entries); tables:",
          {k: hex(v) for k, v in H.tables.items()}, f"attack records: {n_att}")
    if a.node_boxes:
        print(json.dumps(H.node_boxes(*a.node_boxes), indent=1))
    if a.json:
        out = {"base": f"{H.base:#x}", "family_table": f"{H.comp:#x}", "tables": {k: f"{v:#x}" for k, v in H.tables.items()},
               "family": [H.family(i) for i in range(H.family_count())],
               "vuln": {f"vuln{i}": [H.box(H.tables[f"vuln{i}"] + 8 * k) for k in range(H.table_len(f"vuln{i}") // 8)] for i in range(3)},
               "push": [H.box(H.tables["push"] + 8 * k) for k in range(H.table_len("push") // 8)],
               "attack": [H.record(k) for k in range(n_att)],
               "proj_attack_table": f"{H.proj_attack():#x}",
               "proj": [H.record(k, proj=True) for k in range(H.proj_count())]}
        a.json.write_text(json.dumps(out, indent=1))
        print("wrote", a.json)


if __name__ == "__main__":
    main()
