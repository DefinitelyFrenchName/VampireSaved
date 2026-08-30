#!/usr/bin/env python3
"""charmap_gen.py — THE TENANT CHARACTER-DATA MAP (machine file), phase 0.

  python3 tools/charmap_gen.py <build_dir> <out.json>
        [--overrides build/manifest/charmap_<tenant>.toml]   (default: by tenant name)
        [--manifest  build/manifest/<tenant>.toml]           (default: by tenant name)
        [--bank-map  build/manifest/bank_map.toml]
        [--source vh=<extract_dir>]                          (RESERVED — the Vampire Hunter hook)
        [--tenant-key <suffix>]                              (merged builds: placement key suffix)

WHAT IT IS (maintainer's request, 2026-08-29). One deterministic JSON per tenant,
readable by agents, rendered for humans by tools/charmap_md.py, that lays every
per-character data structure the project has decoded side by side as
  vs2   — the SOURCE bytes the extractor took (build/<t>/extract/region_*.bin,
          regions.json `values[]`)
  ours  — what the BUILT image carries (build/<t>/verify_data.bin, read through
          build/<t>/patch/placements.json for relocated regions and at the bank
          row addresses for the 32-row tables)
  vh    — null; a per-source slot reserved for Vampire Hunter (a different engine
          generation; needs its own bank map + extract before the flag means anything)
with every difference ATTRIBUTED: `relocated` (a pointer field in regions.json
`refs`, checked against the placement), `region_fix:<note>` / `port_patch:<note>` /
`table_fix:<note>` / `data_port_fix:<name>` (an existing manifest row covers the
byte), `override:<id>` (a charmap override row, see charmap_compile.py), or
UNATTRIBUTED (counted per region; the frozen count is what the gate holds — growth
is a finding, never noise). Values are DECODED numbers (rule-7 posture ruled
2026-08-29: derived data, tracked under docs/); undecoded spans are never dumped
as hex, only their unattributed diff bytes are shown, capped.

THE STRUCTURES (phase 0 = what the tree had already decoded; see `undecoded`):
  bank         every bank_map.toml table's tenant row: value16/8 raw, rec8 as
               longs, param32_* as (fwd,back) 16.16 walk velocities, jump_params
               as 3 rows x (xv,xaccel,yv,gravity) 16.16, byte2d 30 bytes,
               data_ptr FOLLOWED to its placed copy, code_ptr targets, auto raw
  dispatch     the 20 dispatch rows: vs2 target, oracle target, ours, expected
  regions      every extracted region: bounds, placement, sha1 both sides, the
               byte diff attributed (counts + a capped list of unattributed sites)
  sfx          the per-node sfx record array ([[sound_table]]): 8-byte records
               id/alt_id/p4/p5/d3 for vs2 and the remap the manifest applies
  fsm_nodes    object-script STATE node runs (0x20-byte, +0x10 counter, +0x17
               state; audit_fsm_census.node_runs) in vs2 and in the built copy
  sprite_lists obj_records.walk summary of the anim region (records, entries,
               distinct tiles) both sides; the tile-code delta vs [gfx_remap]
  overrides    the charmap override rows applied, each verified against vs2
Phase 1 adds `anim` (node chains, moves); phase 2 the hitbox records.

Prints the SHA-1 of every input (project convention). Output is byte-deterministic.
"""
import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _minitoml import loads as toml_loads  # noqa: E402
import obj_records  # noqa: E402
import audit_fsm_census  # noqa: E402
import anim_nodes  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
SCHEMA = 1
TENANT_BY_CHAR = {0x10: "huitzil", 0x11: "pyron", 0x13: "donovan"}
UNATTRIBUTED_CAP = 64

UNDECODED = [
    {"structure": "hitbox", "what": "DONE 14z-120 (5): box = (x, y, hw, hh) signed words, authored for the LEFT-facing sprite and mirrored when flip_x=1; +0x8C = attack (base[4]), +0x90 = push (base[3]); family hb8 -> {vuln,vuln,vuln,push}; record +8 real / +9 white / +0x10 hit id / +0x17 CLASS (the '+0x1D' was the same byte counted from the wrong base). +0x14 = the attacker's meter gain on hit (measured 14z-120 (6)). 14z-121, from the record's READERS in the vs2 hit code (0x16930-0x175F6): +0x13 = the HIT-FREEZE class (pairs table 0x17FA4), +0x1B = the white-damage RECOVERY-RATE class (table 0x18018 -> victim +0x13A/+0x13B), +0xE = the victim's FACING rule, +0x1A = a combo-scaling table selector (0 = the attacker's per-character table), +0xC/+0xD = the PUSHBACK STEP-TABLE index on hit/block (-> victim +0x59; vs2 0x2783C lists, 14z-121 (3) — the pushback the 14z-120 (6) correlation was chasing), +0xF -> +0x5A, +0x19 -> +0x56, +0x1E -> +0x1A4, +0x16 = special flag (class 4 -> 5), +0x1D tested on the node-byte-3 path; +0x1C is ADDED to the victim's +0x161 accumulator (240 f decay, threshold byte15b = 60) ONLY while +0x15E is armed by a per-character DARK FORCE handler — the 14z-120 (6) 'scales the pushback' reading is RETRACTED (the reader never fired on any measured contact). NOT READ by the hit code: +0x11, +0x12, +0x15, +0x18, +0x1F", "evidence": "tests/test_hitbox_encoding.sh (8/8 hits on the first overlap frame; class = +0x17 on the fighter, projectile, multi-hit and column paths); tools/hitbox_records.py; engine_internals 'The attack record's fields, by their readers' (14z-121)"},
    {"structure": "anim", "what": "MOVE NAMES for the chains (which seq is which move) — DONE for Donovan 14z-120 (build/manifest/moves_donovan.toml, measured by tests/test_move_naming.sh; labelled in donovan_anim.md); Huitzil and Pyron await their naming rigs", "evidence": "the chains are decoded and live-verified (test_anim_node_walk, 14z-118); names come from the maintainer's move lists -> build/manifest/moves_<tenant>.toml, seq ids from tools/name_moves.py on the native game"},
    {"structure": "anim", "what": "DONE 14z-120 (5): hbA != 0 marks an ATTACK node (hbA>>8 = the attack record); startup / active / recovery per chain are derived in <tenant>_anim.md", "evidence": "tests/test_hitbox_encoding.sh"},
    {"structure": "anim", "what": "table a2's entry rule: its chains are entered MID-CHAIN by node index (measured: 5 jumps onto a2 nodes 3/5/7/13); the select routine is vs2 0x271F4/0x2710C (table pointer by d1, (a0, seq*2) word offset -> node), the advance 0x27252 (+0x18 links / sequential) — 14z-121; which code picks the node INDEX for a mid-chain entry is unread", "evidence": "test_anim_node_walk observation; the +0x1C write taps of 14z-121"},
    {"structure": "anim", "what": "the 6-byte script-op area at +0x10..+0x15 of every node", "evidence": "kept as hex; engine_internals 'the [cf14]..[0b] script-op area'"},
    {"structure": "reaction", "what": "DONE 14z-120 (7): the tenant's reaction SET (which table:seq each class enters, the block chain b:0x0c, the measured stun lengths) — see 'Reactions as the victim'; the hold ends when the pushback step list (0x2783C[record +0xC]) ends (14z-121 (3); the 14z-120 (12) 'pushbox separation' reading is retracted); the 'own table per tenant' reading was a labelling artefact — deterministically labelled, the three tenants share the same canonical b: seqs (14z-121 (2)); the 'unindexed lying/wake nodes' were table-b entries the chain decoder's table bound had cut off (fixed 14z-121: tools/anim_nodes.py; Huitzil's b:0x2a/0x2d/0x44/0x46/0x48)", "evidence": "tests/test_reactions.sh, tests/expected/reactions_<tenant>.txt (Huitzil re-frozen 14z-121), tests/test_anim_node_walk.sh"},
    {"structure": "projectile", "what": "DONE 14z-121: in the map as `structures.projectile` (page section 'Projectile parameters'); every $FF9400 type's inline parameters decoded from its handler (walker-2 table 0x5C620[type]; one init shape: +0x9A selects (xv, xacc, yv, yacc) 16.16 records + the +0x26 byte and +0x50 word; Cosmo Disruption is state-immediate) and MEASURED on the live spawns for all seven tabled types; ours == vs2 on every build (the values ride inside the ported code regions)", "evidence": "tools/projectile_params.py, tests/test_projectile_params.sh, tests/expected/projectile_params.txt"},
    {"structure": "bank", "what": "DONE 14z-121 (a reference scan of vsavj's code for every base in the physics bank): the 17 `gap_*` rows are 13 SLICES of param32_a / jump_params / param32_b / rec8_b (the bank map declared the interiors of larger-stride tables as their own rows), the two halves of the 32-LONG capture-keyframe pointer table 0x0BE27A, and one REAL per-char word table at 0x0BE23A (an airborne height threshold, check unread); rec8_b = the pursuit physics record pair (0x0BE3FA, id*0x20). Each row carries the resolution in bank_map.toml `note`", "evidence": "bank_map.toml notes; engine_internals 'The physics bank's gap rows'"},
    {"structure": "sfx", "what": "sfx record field +6 (d3.w, 'level-ish')", "evidence": "engine_internals 960"},
    {"structure": "meter", "what": "DONE 14z-121 (4): +0x392.w is NOT an engine meter — written only inside one character's code block (vs2 0x4D0C0), no engine reader", "evidence": "ram.md +0x392 row (static)"},
    {"structure": "regions", "what": "the x2b7ef4 (companion-effect tail) residue: 24-bit frame pointers and tile words rewritten by the effect pass (14z-71) that phase 0 does not attribute per byte — counted and frozen, not explained", "evidence": "the region's `diff.sites`; attribute from the effect pass's own ledger in a later step"},
]


def sha1_of(p):
    return hashlib.sha1(Path(p).read_bytes()).hexdigest()


def s32(b):
    return int.from_bytes(b, "big", signed=True)


def u32(b):
    return int.from_bytes(b, "big")


def u16(b):
    return int.from_bytes(b, "big")


def fx16(v):
    """16.16 fixed -> float, 5 decimals (deterministic text)."""
    return round(v / 65536.0, 5)


def load_manifest(path):
    return toml_loads(Path(path).read_text()) if Path(path).is_file() else {}


def rows(doc, key):
    v = doc.get(key, [])
    return v if isinstance(v, list) else [v]


class Built:
    """The built data-space image + placements."""
    def __init__(self, build, tenant_key=None):
        self.build = Path(build)
        self.img = (self.build / "verify_data.bin").read_bytes()
        pj = json.loads((self.build / "patch" / "placements.json").read_text())
        self.place = {}
        for k, v in pj["regions"].items():
            name = k
            if tenant_key and k.endswith(tenant_key):
                name = k[: -len(tenant_key)]
            elif tenant_key and not k.endswith(tenant_key):
                continue
            self.place[name] = v

    def placed(self, region, off=0):
        p = self.place.get(region)
        return None if p is None else p["dst"] + off

    def rd(self, addr, n):
        return self.img[addr: addr + n]

    def region_bytes(self, region, length):
        p = self.place.get(region)
        return None if p is None else self.img[p["dst"]: p["dst"] + length]


def region_of(regions, addr):
    for name, r in regions.items():
        if r["src"] <= addr < r["src"] + r["len"]:
            return name, addr - r["src"]
    return None, None


RECON = {}  # vs2 engine address -> vsavj twin (reconciliation.toml + the tenant overlay)


def load_recon(manifest):
    m = {}
    files = [REPO / "build/manifest/reconciliation.toml"]
    for t in rows(manifest, "tenant"):
        if t.get("recon_overlay"):
            files.append(REPO / str(t["recon_overlay"]))
    for f in files:
        if not f.is_file():
            continue
        doc = toml_loads(f.read_text())
        for r in rows(doc, "map"):
            if "vsav2" in r and "vsavj" in r and isinstance(r["vsavj"], int):
                m[int(r["vsav2"])] = int(r["vsavj"])
    return m


def expected_placed(regions, built, target):
    """A vs2 address -> where the port put it: a placed region offset, or the
    reconciliation twin for an ENGINE address; None if neither is known."""
    name, off = region_of(regions, target)
    if name is None:
        return RECON.get(target)
    p = built.placed(name)
    return None if p is None else p + off


def attribute_diff(name, r, vs2, ours, manifest, overrides, built, regions, tilemap=None, ranges=None):
    """Classify every differing byte offset of one region."""
    tilemap = tilemap or {}
    ranges = ranges or []  # [(lo, hi, label)] — a 4-byte ours value inside one is a pointer to that placed blob
    refs = {}
    for ref in r.get("refs", []):
        w = ref["width"] // 8
        for k in range(w):
            refs[ref["off"] + k] = ref
    fixes = {}  # off -> label
    for rf in rows(manifest, "region_fix"):
        if rf.get("region") == name:
            o = int(rf["off"]) if not isinstance(rf["off"], str) else int(rf["off"], 0)
            for k in range(len(bytes.fromhex(rf["new_hex"]))):
                fixes[o + k] = "region_fix:" + str(rf.get("note", ""))[:60]
    for pp in rows(manifest, "port_patch"):
        sa = pp.get("src_addr")
        if sa is None:
            continue
        sa = int(sa) if not isinstance(sa, str) else int(sa, 0)
        rn, ro = region_of(regions, sa)
        if rn == name:
            for k in range(len(bytes.fromhex(pp["new_hex"]))):
                fixes.setdefault(ro + k, "port_patch:" + str(pp.get("note", ""))[:60])
    for tf in rows(manifest, "table_fix"):
        if tf.get("region") == name:
            o = int(tf["table_off"]) if not isinstance(tf["table_off"], str) else int(tf["table_off"], 0)
            for k in range(len(bytes.fromhex(tf["rows_hex"]))):
                fixes.setdefault(o + k, "table_fix:" + str(tf.get("note", ""))[:60])
    for dp in rows(manifest, "data_port"):
        if dp.get("region") == name and dp.get("fixes"):
            for item in str(dp["fixes"]).split(","):
                o, old, new = item.split(":")
                o = int(o, 0)
                for k in range(len(bytes.fromhex(new))):
                    fixes.setdefault(o + k, "data_port_fix:" + str(dp.get("name", ""))[:40])
    ov = {}
    for o in overrides:
        if o["region"] == name:
            for k in range(len(bytes.fromhex(o["value"]))):
                ov[o["off"] + k] = "override:" + o["id"]

    gr = manifest.get("gfx_remap", {}) if manifest.get("gfx_remap", {}).get("region") == name else {}
    band = (gr.get("band_lo"), gr.get("band_hi"), gr.get("delta")) if gr else None
    counts = {"total": 0, "relocated_ok": 0, "relocated_bad": 0, "attributed": 0, "override": 0, "gfx_remap": 0, "unattributed": 0}
    by_label = {}
    unatt = []
    labels = {}  # differing offset -> label (for the structure-level passes)
    i = 0
    n = min(len(vs2), len(ours))
    seen_refs = set()
    while i < n:
        if vs2[i] == ours[i]:
            i += 1
            continue
        counts["total"] += 1
        if i in ov:
            counts["override"] += 1
            by_label[ov[i]] = by_label.get(ov[i], 0) + 1
            labels[i] = ov[i]
        elif i in refs:
            ref = refs[i]
            if id(ref) not in seen_refs:
                seen_refs.add(id(ref))
                w = ref["width"] // 8
                if w in (3, 4):
                    got = int.from_bytes(ours[ref["off"]: ref["off"] + w], "big")
                    want = expected_placed(regions, built, ref["target"])
                    ok = want is not None and got == want
                elif w == 2:
                    ok = True  # pcrel16 displacements are rewritten against placement; accepted (phase 0)
                else:
                    ok = False
                counts["relocated_ok" if ok else "relocated_bad"] += 1
                for k in range(w):
                    labels[ref["off"] + k] = "relocated" if ok else "relocated_bad"
                if not ok and len(unatt) < UNATTRIBUTED_CAP:
                    unatt.append({"off": f"{ref['off']:#x}", "kind": "relocated_bad", "vs2": vs2[ref['off']:ref['off']+w].hex(), "ours": ours[ref['off']:ref['off']+w].hex(), "target": f"{ref['target']:#x}"})
        elif i in fixes:
            counts["attributed"] += 1
            by_label[fixes[i]] = by_label.get(fixes[i], 0) + 1
            labels[i] = fixes[i]
        elif band and i % 2 == 0 and i + 1 < n and _is_remapped_word(vs2, ours, i, band):
            # a sprite-record tile code inside the [gfx_remap] band, moved by its delta
            counts["gfx_remap"] += 2
            labels[i] = labels[i + 1] = "gfx_remap"
            i += 2
            continue
        elif band and i % 2 == 1 and i >= 1 and _is_remapped_word(vs2, ours, i - 1, band):
            counts["gfx_remap"] += 1
            labels[i] = "gfx_remap"
        elif tilemap and i % 2 == 0 and i + 1 < n and tilemap.get(u16(vs2[i:i+2])) == u16(ours[i:i+2]):
            # a shelf-packed non-band tile code, per the build's own gfx ledger (patch/effect_map.json)
            counts["gfx_remap"] += 2
            labels[i] = labels[i + 1] = "gfx_remap"
            i += 2
            continue
        elif tilemap and i % 2 == 1 and i >= 1 and tilemap.get(u16(vs2[i-1:i+1])) == u16(ours[i-1:i+1]):
            counts["gfx_remap"] += 1
            labels[i] = "gfx_remap"
        elif ranges and _ptr_into(ours, i, ranges) is not None:
            lab, span = _ptr_into(ours, i, ranges)
            counts["attributed"] += span
            by_label[lab] = by_label.get(lab, 0) + 1
            for k in range(span):
                labels[i + k] = lab
            i += span
            continue
        else:
            counts["unattributed"] += 1
            labels[i] = "UNATTRIBUTED"
            if len(unatt) < UNATTRIBUTED_CAP:
                unatt.append({"off": f"{i:#x}", "kind": "unattributed", "vs2": f"{vs2[i]:02x}", "ours": f"{ours[i]:02x}"})
        i += 1
    return counts, dict(sorted(by_label.items())), unatt, labels


def _ptr_into(ours, i, ranges):
    """If a 4-byte big-endian value starting at an even offset covering i points
    inside one of `ranges`, return (label, bytes_consumed_from_i); else None."""
    for start in (i - (i % 2), i - (i % 2) - 2):
        if start < 0 or start + 4 > len(ours):
            continue
        v = u32(ours[start:start + 4])
        for lo, hi, lab in ranges:
            if lo <= v < hi:
                return lab, (start + 4 - i)
    return None


def _is_remapped_word(vs2, ours, i, band):
    lo, hi, delta = band
    a = u16(vs2[i:i + 2]); b = u16(ours[i:i + 2])
    return lo <= a <= hi and b == ((a + delta) & 0xFFFF)


def decode_bank_row(tbl, cid, blob_vs2, blob_ours):
    """Decode one bank row from raw bytes of both sides; returns fields dict."""
    kind = tbl["kind"]
    f = {}
    def fld(name, fmt, a, b, extra=None):
        d = {"fmt": fmt, "vs2": a, "ours": b, "vh": None, "diff": a != b}
        if extra:
            d.update(extra)
        f[name] = d
    if kind == "value16":
        fld("value", "u16", u16(blob_vs2), u16(blob_ours))
    elif kind == "value8":
        fld("value", "u8", blob_vs2[0], blob_ours[0])
    elif kind == "value32":
        fld("value", "u32", u32(blob_vs2), u32(blob_ours))
    elif kind == "rec8" and tbl["name"].startswith("param32_"):
        fld("fwd_walk_xv", "s16.16", fx16(s32(blob_vs2[0:4])), fx16(s32(blob_ours[0:4])))
        fld("back_walk_xv", "s16.16", fx16(s32(blob_vs2[4:8])), fx16(s32(blob_ours[4:8])))
    elif kind == "rec8" and tbl["name"] == "jump_params":
        for k, row in enumerate(("neutral", "forward", "back")):
            for j, nm in enumerate(("xv", "xaccel", "yv", "gravity")):
                o = k * 16 + j * 4
                fld(f"{row}_{nm}", "s16.16", fx16(s32(blob_vs2[o:o+4])), fx16(s32(blob_ours[o:o+4])))
    elif kind == "rec8":
        fld("long0", "s32", s32(blob_vs2[0:4]), s32(blob_ours[0:4]))
        fld("long1", "s32", s32(blob_vs2[4:8]), s32(blob_ours[4:8]))
    elif kind == "byte2d":
        fld("row", "bytes", blob_vs2.hex(), blob_ours.hex())
    else:  # auto: raw entry, undecoded
        fld("raw", "hex", blob_vs2.hex(), blob_ours.hex())
    return f


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("build_dir", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--overrides", type=Path)
    ap.add_argument("--manifest", type=Path)
    ap.add_argument("--bank-map", type=Path, default=REPO / "build/manifest/bank_map.toml")
    ap.add_argument("--source", action="append", default=[], help="RESERVED: vh=<extract_dir>")
    ap.add_argument("--tenant-key", default=None)
    a = ap.parse_args()

    ex = a.build_dir / "extract"
    rj = json.loads((ex / "regions.json").read_text())
    cid = int(rj["char"], 16) if isinstance(rj["char"], str) else rj["char"]
    tenant = TENANT_BY_CHAR.get(cid, f"id{cid:#04x}")
    manifest_path = a.manifest or (REPO / "build/manifest" / f"{tenant}.toml")
    overrides_path = a.overrides or (REPO / "build/manifest" / f"charmap_{tenant}.toml")
    manifest = load_manifest(manifest_path)
    RECON.update(load_recon(manifest))
    ovdoc = load_manifest(overrides_path)
    bank = toml_loads(a.bank_map.read_text())["table"]
    built = Built(a.build_dir, a.tenant_key)
    regions = rj["regions"]
    for s in a.source:
        if not s.startswith("vh="):
            sys.exit(f"unknown --source {s}")
        sys.exit("--source vh= is reserved: Vampire Hunter needs its own bank map and extract first (see the plan)")

    inputs = {}
    for label, p in (("regions.json", ex / "regions.json"), ("verify_data.bin", a.build_dir / "verify_data.bin"),
                     ("placements.json", a.build_dir / "patch" / "placements.json"), ("bank_map.toml", a.bank_map),
                     ("manifest", manifest_path), ("overrides", overrides_path)):
        if Path(p).is_file():
            inputs[label] = sha1_of(p)
            print(f"read  {p}  sha1 {inputs[label]}")
        else:
            inputs[label] = None
    for f in [REPO / "build/manifest/reconciliation.toml"] + [REPO / str(t["recon_overlay"]) for t in rows(manifest, "tenant") if t.get("recon_overlay")]:
        if f.is_file():
            inputs[f.name] = sha1_of(f)
            print(f"read  {f}  sha1 {inputs[f.name]}")

    # ---- overrides: verify each against vs2 bytes; resolve (region, off) ----
    overrides = []
    for o in rows(ovdoc, "override"):
        path = str(o["path"]).split("/")
        if path[0] != "region" or len(path) != 3:
            sys.exit(f"override {o.get('id')}: phase-0 paths are region/<name>/<hexoff> (got {o['path']})")
        rname, off = path[1], int(path[2], 16)
        blob = (ex / f"region_{rname}.bin").read_bytes()
        exp = bytes.fromhex(o["expect"]); val = bytes.fromhex(o["value"])
        if len(exp) != len(val):
            sys.exit(f"override {o['id']}: expect/value length mismatch")
        if blob[off: off + len(exp)] != exp:
            sys.exit(f"override {o['id']}: vs2 bytes at {rname}+{off:#x} are {blob[off:off+len(exp)].hex()}, expect {o['expect']}")
        overrides.append({"id": str(o["id"]), "region": rname, "off": off, "expect": o["expect"], "value": o["value"],
                          "stage": int(o.get("stage", 6)), "note": str(o.get("note", ""))})

    # ---- bank rows ----
    values_by_name = {v["table"]: v for v in rj["values"]}
    tenant_rows_ = rows(manifest, "tenant")
    port_param32 = any(t.get("port_param32") for t in tenant_rows_) or manifest.get("port_param32", False)
    value_skip = set() if port_param32 else {"param32_a", "param32_b", "jump_params"}
    claimed = {st["ptr_table"]: str(st.get("name", "sound_table")) for st in rows(manifest, "sound_table")}
    shim_tables = {str(manifest["init_shim"].get("dispatch")) for _ in [0] if manifest.get("init_shim")}
    bank_records = {}
    for tbl in bank:
        name = tbl["name"]; kind = tbl["kind"]; base = tbl["vsavj"]; stride = tbl["stride"]
        if kind == "byte2d":
            width = tbl["span"] // 32
        else:
            width = stride // 32
        row_addr = base + cid * width
        ours_raw = built.rd(row_addr, width)
        v = values_by_name.get(name)
        rec = {"loc": {"space": "bank", "vsavj_row": f"{row_addr:#08x}", "len": width, "kind": kind, "table_base": f"{base:#08x}"}, "fields": {}}
        if tbl.get("note"):
            rec["note"] = tbl["note"]   # 14z-121: the reference scan's resolution of the auto/gap rows (bank_map.toml `note`)
        if kind in ("data_ptr", "code_ptr"):
            vs2_ptr = int(v["ptr"], 16) if v and "ptr" in v else None
            ours_ptr = u32(ours_raw)
            want = expected_placed(regions, built, vs2_ptr) if vs2_ptr is not None else None
            if vs2_ptr is None:
                src = "no-vs2-value"
            elif want is not None and ours_ptr == want:
                src = "relocated"
            elif ours_ptr == vs2_ptr:
                src = "byte"
            elif base in claimed:
                src = f"manifest:sound_table:{claimed[base]} (the array is placed by the sound op; the row is its ptr_table)"
            elif name in shim_tables:
                src = "manifest:init_shim (synthesised pool-seeding shim routed through this dispatch row)"
            else:
                src = "UNATTRIBUTED"
            rec["fields"]["ptr"] = {"fmt": "addr", "vs2": (f"{vs2_ptr:#08x}" if vs2_ptr is not None else None),
                                    "ours": f"{ours_ptr:#08x}", "expected_placed": (f"{want:#08x}" if want is not None else None),
                                    "vh": None, "ours_source": src, "diff": src not in ("byte", "relocated")}
        else:
            vs2_raw = bytes.fromhex(v["value"]) if v and "value" in v else None
            if vs2_raw is None:
                # not in values[] (auto rows the extractor reports separately): compare against the vs2 bank read is
                # impossible without the source image; record ours only
                rec["fields"]["raw"] = {"fmt": "hex", "vs2": None, "ours": ours_raw.hex(), "vh": None, "ours_source": "no-vs2-value", "diff": False}
            else:
                fields = decode_bank_row(tbl, cid, vs2_raw, ours_raw)
                for fn, fd in fields.items():
                    if not fd["diff"]:
                        fd["ours_source"] = "byte"
                    elif name in value_skip:
                        fd["ours_source"] = "manifest:VALUE_SKIP — row NOT ported (no port_param32 in [[tenant]]); ours is the vsavj ALIAS row's content (id & 0x0F)"
                    elif name in ("param32_a", "param32_b", "jump_params"):
                        fd["ours_source"] = "manifest:port_param32 set AFTER this build (UNFROZEN physics port — the next freeze's image carries vs2's row; until then ours is the alias row's content)"
                    else:
                        fd["ours_source"] = "UNATTRIBUTED"
                rec["fields"] = fields
        bank_records[name] = rec

    # ---- dispatch rows ----
    code = regions.get("code")
    dispatch = {}
    for d in rj["dispatch"]:
        tb = next((t for t in bank if t["name"] == d["table"]), None)
        ours_ptr = u32(built.rd(tb["vsavj"] + cid * 4, 4)) if tb else None
        want = expected_placed(regions, built, d["src_target"])
        if want is not None and ours_ptr == want:
            src = "relocated"
        elif ours_ptr == d["src_target"]:
            src = "byte"
        elif d["table"] in shim_tables:
            src = "manifest:init_shim (synthesised pool-seeding shim; falls into the relocated handler)"
        else:
            src = "UNATTRIBUTED"
        dispatch[d["table"]] = {"vs2": f"{d['src_target']:#08x}", "orc": f"{d['orc_target']:#08x}",
                                "ours": (f"{ours_ptr:#08x}" if ours_ptr is not None else None),
                                "expected_placed": (f"{want:#08x}" if want is not None else None),
                                "ours_source": src, "diff": src not in ("relocated", "byte")}

    # ---- regions ----
    tilemap = {}
    em = a.build_dir / "patch" / "effect_map.json"
    if em.is_file():
        tilemap = {int(k): int(v) for k, v in json.loads(em.read_text())}
    ranges = []
    pj_path = a.build_dir / "patch" / "patch.json"
    if pj_path.is_file():
        pj = json.loads(pj_path.read_text())
        ops = pj if isinstance(pj, list) else pj.get("ops", [])
        for op in ops:
            if op.get("op") == "data_file" and str(op.get("path", "")).endswith("effect_lists.bin"):
                f = a.build_dir / "patch" / "effect_lists.bin"
                if f.is_file():
                    lo = int(op["addr"], 16) if isinstance(op["addr"], str) else int(op["addr"])
                    ranges.append((lo, lo + f.stat().st_size, "effect_lists (companion-effect coord list pointer, resolved from a 0xEE placeholder)"))
    reg_out = {}
    region_labels = {}
    totals = {"unattributed": 0, "relocated_bad": 0, "code_bytes_differ": 0}
    for name, r in regions.items():
        vs2 = (ex / f"region_{name}.bin").read_bytes()
        ours = built.region_bytes(name, r["len"])
        entry = {"kind": r["kind"], "src": f"{r['src']:#08x}", "orc": f"{r['orc']:#08x}", "len": r["len"],
                 "placed": (f"{built.placed(name):#08x}" if built.placed(name) is not None else None),
                 "sha1_vs2": r.get("sha1"), "sha1_ours": (hashlib.sha1(ours).hexdigest() if ours else None),
                 "variant_sites": len(r.get("variant_sites", [])), "refs": len(r.get("refs", []))}
        if ours is None:
            entry["diff"] = {"note": "region not placed in this build"}
        elif r["kind"] == "code":
            nd = sum(1 for k in range(min(len(vs2), len(ours))) if vs2[k] != ours[k])
            entry["diff"] = {"bytes_differ": nd, "note": "relocated CODE: pc-relative rewrites, reconciliation retargets and thunks — attribution is the reconciliation / pointer_flow / pcrel gates' business, out of this map's scope"}
            totals["code_bytes_differ"] += nd
        else:
            counts, by_label, unatt, labels = attribute_diff(name, r, vs2, ours, manifest, overrides, built, regions, tilemap, ranges)
            region_labels[name] = labels
            entry["diff"] = {"counts": counts, "attributed_by": by_label, "sites": unatt}
            totals["unattributed"] += counts["unattributed"]
            totals["relocated_bad"] += counts["relocated_bad"]
        reg_out[name] = entry

    # ---- sfx records ----
    sfx = {}
    for st in rows(manifest, "sound_table"):
        src = st["src"]; n = int(st["entries"])
        rn, ro = region_of(regions, src)
        remap = {}
        for item in str(st.get("remap_ids", "")).split(","):
            if ":" in item:
                s, d = item.split(":"); remap[int(s, 0)] = int(d, 0)
        recs = []
        if rn is not None:
            blob = (ex / f"region_{rn}.bin").read_bytes()
            for k in range(n):
                b = blob[ro + 8 * k: ro + 8 * k + 8]
                if len(b) < 8:
                    recs.append({"idx": k, "note": "outside the extracted region (the sound_table op copies from the source image); phase 0 reads blobs only"})
                    continue
                sid = u16(b[0:2]); alt = u16(b[2:4])
                recs.append({"idx": k, "id": sid, "alt_id": alt, "p4": b[4], "p5": b[5], "d3": u16(b[6:8]),
                             "ours_id": remap.get(sid, sid), "ours_alt_id": remap.get(alt, alt),
                             "ours_source": ("manifest:sound_table.remap_ids" if (sid in remap or alt in remap) else "byte")})
        sfx[str(st.get("name", "sfx"))] = {"loc": {"src": f"{src:#08x}", "region": rn, "off": (f"{ro:#x}" if ro is not None else None), "entries": n,
                                                  "placed_in": str(st.get("hole", ""))}, "records": recs}

    # ---- FSM state-node runs (vs2 vs built) over data regions ----
    fsm = {}
    for name, r in regions.items():
        if r["kind"] != "data":
            continue
        vs2 = (ex / f"region_{name}.bin").read_bytes()
        runs_v = [(s - r["src"], [st for _, st in seg]) for s, seg in audit_fsm_census.node_runs(vs2, r["src"])]
        ours = built.region_bytes(name, r["len"])
        runs_o = [(s - built.placed(name), [st for _, st in seg]) for s, seg in audit_fsm_census.node_runs(ours, built.placed(name))] if ours else []
        if runs_v or runs_o:
            vd = {f"{o:#x}": st for o, st in runs_v}; od = {f"{o:#x}": st for o, st in runs_o}
            fsm[name] = {"runs_vs2": len(runs_v), "runs_ours": len(runs_o),
                         "runs": [{"off": k, "vs2_states": vd.get(k), "ours_states": od.get(k),
                                   "diff": vd.get(k) != od.get(k)} for k in sorted(set(vd) | set(od), key=lambda x: int(x, 16))]}

    # ---- sprite-list summary of the anim region ----
    sprite = {}
    if "anim" in regions and built.placed("anim") is not None:
        r = regions["anim"]
        vs2 = (ex / "region_anim.bin").read_bytes()
        ok_any = lambda p: True
        t_v, e_v, n_v = obj_records.walk(vs2, r["src"], r["src"], r["src"] + r["len"], ok_any)
        dst = built.placed("anim")
        ours = built.region_bytes("anim", r["len"])
        t_o, e_o, n_o = obj_records.walk(ours, dst, dst, dst + r["len"], ok_any)
        gr = manifest.get("gfx_remap", {})
        sprite = {"records": {"vs2": n_v, "ours": n_o}, "entries": {"vs2": e_v, "ours": e_o},
                  "distinct_tiles": {"vs2": len(t_v), "ours": len(t_o)},
                  "gfx_remap": ({"band_lo": f"{gr['band_lo']:#x}", "band_hi": f"{gr['band_hi']:#x}", "delta": f"{gr['delta']:#x}"} if gr else None),
                  "note": "tile-code differences inside the band are the [gfx_remap] delta by construction (phase 0 does not re-derive them per record)"}

    # ---- anim node chains (phase 1): vs2 from the blob, ours from the built copy ----
    anim = {}
    if "anim" in regions and built.placed("anim") is not None:
        r = regions["anim"]; blob = (ex / "region_anim.bin").read_bytes()
        dst = built.placed("anim"); ours_blob = built.region_bytes("anim", r["len"])
        totals_nodes = {"nodes": 0, "differ": 0, "attributed": 0}
        for tname in ("a", "a2", "b", "c", "proj"):
            v = values_by_name.get("anim_index_" + tname)
            if not v or "ptr" not in v:
                continue
            t_vs2 = int(v["ptr"], 16)
            t_ours = t_vs2 - r["src"] + dst
            wv = anim_nodes.walk_table(blob, r["src"], t_vs2, r["src"] + r["len"])
            # ours: walk exactly vs2's entry count (a rewritten table word must not shrink the table)
            wo = anim_nodes.walk_table(ours_blob, dst, t_ours, dst + r["len"], max_seq=wv["entries"], entries=wv["entries"])
            chains = {}
            alab = region_labels.get("anim", {})
            for seq, cv in wv["chains"].items():
                co = wo["chains"].get(seq, {"nodes": [], "end": "missing", "start": None})
                # the index-table word: did the port move this chain's START?
                sv = int(cv["start"], 16) - t_vs2 if cv["start"] else None
                so = int(co["start"], 16) - t_ours if co.get("start") else None
                if sv is not None and sv != so:
                    woff = (t_vs2 - r["src"]) + 2 * int(seq, 16)
                    lab = {alab.get(woff), alab.get(woff + 1)} - {None}
                    chains[seq] = {"start": cv["start"], "end": cv["end"], "frames": cv.get("frames"), "n": len(cv["nodes"]),
                                   "ours_end": co.get("end"), "nodes": [],
                                   "start_moved": {"vs2_off": f"{sv:#x}", "ours_off": (f"{so:#x}" if so is not None else None),
                                                   "ours_source": (",".join(sorted(lab)) if lab else "UNATTRIBUTED")}}
                    totals_nodes["nodes"] += len(cv["nodes"]); totals_nodes["differ"] += 1
                    if lab and "UNATTRIBUTED" not in lab: totals_nodes["attributed"] += 1
                    continue
                nodes = []
                for k, nv in enumerate(cv["nodes"]):
                    no = co["nodes"][k] if k < len(co["nodes"]) else None
                    off = int(nv["addr"], 16) - r["src"]
                    fields = {}
                    for fn in ("dur", "flags", "hb8", "hbA", "shadow", "sfx", "op"):
                        a_, b_ = nv[fn], (no[fn] if no else None)
                        fields[fn] = {"vs2": a_, "ours": b_, "diff": a_ != b_}
                    sp_v = int(nv["sprite"], 16); sp_o = int(no["sprite"], 16) if no else None
                    want = expected_placed(regions, built, sp_v)
                    fields["sprite"] = {"vs2": nv["sprite"], "ours": (no["sprite"] if no else None), "expected_placed": (f"{want:#x}" if want else None),
                                        "diff": not (sp_o == want or sp_o == sp_v), "ours_source": ("relocated" if sp_o == want else ("byte" if sp_o == sp_v else "UNATTRIBUTED"))}
                    if nv.get("link"):
                        lv = int(nv["link"], 16); lo = int(no["link"], 16) if (no and no.get("link")) else None
                        wl = expected_placed(regions, built, lv)
                        lsrc = "relocated" if (wl is not None and lo == wl) else ("byte" if lo == lv else "UNATTRIBUTED")
                        fields["link"] = {"vs2": nv["link"], "ours": (no.get("link") if no else None), "expected_placed": (f"{wl:#x}" if wl else None), "diff": lsrc == "UNATTRIBUTED", "ours_source": lsrc}
                    nd = [fn for fn, fd in fields.items() if fd["diff"]]
                    src = "byte"
                    if nd:
                        # reuse the region-level per-byte attribution of this node's 0x18 bytes
                        labs = {alab[k] for k in range(off, off + 0x18) if k in alab}
                        src = ",".join(sorted(labs)) if labs else "UNATTRIBUTED"
                        totals_nodes["differ"] += 1
                        if labs and "UNATTRIBUTED" not in labs and "relocated_bad" not in labs:
                            totals_nodes["attributed"] += 1
                    totals_nodes["nodes"] += 1
                    nodes.append({"addr": nv["addr"], "off": f"{off:#x}", "fields": fields, "diff": nd, "ours_source": src})
                chains[seq] = {"start": cv["start"], "end": cv["end"], "frames": cv.get("frames"), "n": len(cv["nodes"]),
                               "ours_end": co["end"], "nodes": nodes}
            anim[tname] = {"table_vs2": f"{t_vs2:#x}", "table_ours": f"{t_ours:#x}", "entries": wv["entries"], "chains": chains}
        anim["_summary"] = totals_nodes
        anim["_verified_by"] = "tests/test_anim_node_walk.sh (Donovan, native vs2: 3638/3638 node pointers on the graph, 14z-118)"

    # ---- hitbox tables + attack records (phase 2, 14z-120 (5)): vs2 from the extract, ours from the built copy ----
    hitbox = {}
    if "hitbox" in regions and built.placed("hitbox") is not None:
        import hitbox_records
        Hv = hitbox_records.HitboxSet(ex)
        r = regions["hitbox"]; dst = built.placed("hitbox"); ours_blob = built.region_bytes("hitbox", r["len"])
        hlab = region_labels.get("hitbox", {})
        rp = regions.get("hitbox_proj"); pdst = built.placed("hitbox_proj") if rp else None
        pours = built.region_bytes("hitbox_proj", rp["len"]) if (rp and pdst is not None) else b""
        plab = region_labels.get("hitbox_proj", {})
        def recs(proj):
            n = Hv.proj_count() if proj else Hv.table_len("attack") // hitbox_records.REC
            base_v = Hv.proj_attack() if proj else Hv.tables["attack"]
            src, blob, lab = (rp["src"], pours, plab) if proj else (r["src"], ours_blob, hlab)
            out = []
            for k in range(n):
                rv = Hv.record(k, proj=proj); off = base_v - src + k * 0x20
                ob = blob[off:off + 0x20] if len(blob) >= off + 0x20 else b""
                fields = {"box": rv["box"], "real": rv["real"], "white": rv["white"], "hit_id": rv["hit_id"], "meter": rv["meter"], "strength": rv["strength"], "special": rv["special"], "cls": rv["cls"], "b1c": rv["b1c"], "b1d": rv["b1d"],
                          "pb_hit": rv["pb_hit"], "pb_blk": rv["pb_blk"], "facing": rv["facing"], "freeze": rv["freeze"], "scale": rv["scale"], "recov": rv["recov"]}
                diff = [i for i in range(0x20) if ob and ob[i] != bytes.fromhex(rv["raw"])[i]]
                labs = {hlab.get(off + i) if not proj else plab.get(off + i) for i in diff} - {None}
                out.append({"idx": k, "addr": rv["addr"], "fields": fields, "ours_diff": [f"+{i:#x}:{bytes.fromhex(rv['raw'])[i]:#04x}->{ob[i]:#04x}" for i in diff],
                            "ours_source": (",".join(sorted(labs)) if labs else ("byte" if not diff else "UNATTRIBUTED"))})
            return out
        hitbox = {"base": f"{Hv.base:#x}", "family_table": f"{Hv.comp:#x}", "family_entries": Hv.family_count(),
                  "tables": {k: f"{v:#x}" for k, v in Hv.tables.items()},
                  "box_counts": {k: Hv.table_len(k) // 8 for k in ("vuln0", "vuln1", "vuln2", "push")},
                  "attack": recs(False), "proj": recs(True) if rp else [],
                  "_encoding": "box = (x, y, hw, hh) signed words, centre at fighter (x + (flip_x ? -x : x), y + y), half-extents; node hb8 -> family entry {vuln0,vuln1,vuln2,push}; node hbA>>8 -> attack record (0x20: +0 box, +8 real, +9 white, +0x10 hit id, +0xC/+0xD pushback step-table index on hit/block, +0xE facing rule, +0x13 hit-freeze class, +0x14 attacker meter gain, +0x16 special flag, +0x17 reaction class, +0x1A combo-scaling row, +0x1B white-damage recovery class, +0x1C the DF-armed accumulator value (Aulbath-victim mechanic), +0x1D 0; +0x11/+0x12/+0x15/+0x18/+0x1F unread — 14z-121)",
                  "_verified_by": "tests/test_hitbox_encoding.sh (Donovan on native vs2, 14z-120 (5): 8/8 hits on the first overlap frame, class = record +0x17 on every path)"}
        hitbox["_summary"] = {"attack_records": len(hitbox["attack"]), "attack_differ": sum(1 for x in hitbox["attack"] if x["ours_diff"]),
                              "attack_unattributed": sum(1 for x in hitbox["attack"] if x["ours_source"] == "UNATTRIBUTED"),
                              "proj_records": len(hitbox["proj"]), "proj_differ": sum(1 for x in hitbox["proj"] if x["ours_diff"]),
                              "proj_unattributed": sum(1 for x in hitbox["proj"] if x["ours_source"] == "UNATTRIBUTED")}

    # ---- projectile parameters (phase 3, 14z-121): each $FF9400 type's inline init decoded on vs2 and on the build ----
    projectile = {}
    vs2op = REPO / "build" / "out" / "vsav2_opcodes.bin"
    TYPES = {"donovan": [0x3E], "pyron": [0x40, 0x41, 0x42], "huitzil": [0x44, 0x45, 0x46, 0x47]}   # the census, tests/expected/projectile_census.txt
    if vs2op.exists() and (a.build_dir / "verify_op.bin").exists():
        import projectile_params as pp
        vs2img = vs2op.read_bytes(); oursimg = (a.build_dir / "verify_op.bin").read_bytes()
        for ty in TYPES.get(tenant, []):
            h = int.from_bytes(vs2img[0x5C620 + ty * 4:0x5C620 + ty * 4 + 4], "big")
            dv = pp.decode(vs2img, h)
            oh = None
            for name, reg in regions.items():
                if reg.get("src") is not None and reg["src"] <= h < reg["src"] + reg["len"] and built.placed(name) is not None:
                    oh = built.placed(name) + h - reg["src"]; break
            do = pp.decode(oursimg, oh) if oh is not None else None
            same = do is not None and do["shape"] == dv["shape"] and (do.get("rows") == dv.get("rows")) and ([{k: v for k, v in i.items() if k != "pc"} for i in do.get("immediates", [])] == [{k: v for k, v in i.items() if k != "pc"} for i in dv.get("immediates", [])])
            projectile[f"{ty:#04x}"] = {"handler_vs2": f"{h:#x}", "handler_ours": (f"{oh:#x}" if oh is not None else None), "shape": dv["shape"],
                                        "rows": dv.get("rows", []), "immediates": dv.get("immediates", []), "ours_source": ("byte" if same else ("UNATTRIBUTED" if do else "not-ported"))}
        # the moves that spawn each type (the frozen census, tests/expected/projectile_census.txt)
        cen = REPO / "tests/expected/projectile_census.txt"
        if cen.exists():
            for l in cen.read_text().splitlines():
                f = l.split("\t")
                if len(f) < 4 or f[0] != tenant: continue
                for tok in f[3].split():
                    ty = f"{int(tok.split(':')[0], 16):#04x}"
                    if ty in projectile:
                        mv = f[2].split(" [")[0].split(" (")[0].split(" in ")[0]
                        projectile[ty].setdefault("moves", [])
                        if mv not in projectile[ty]["moves"]: projectile[ty]["moves"].append(mv)
        projectile["_encoding"] = "per type: +0x9A (0/2/4 = LP/MP/HP, 6 = ES) selects +0x26 (byte or word), +0x50 (word) and an (xv, xacc, yv, yacc) 16.16 record (x-terms negated when flip_x = 0); Blizzard indexes (xv, yv) pairs by +0x0A*8; Cosmo Disruption = immediates per state"
        projectile["_verified_by"] = "tests/test_projectile_params.sh (29/29 live spawns match; ours == vs2 on three builds; 14z-121)"

    out = {
        "schema": SCHEMA, "tenant": tenant, "char": f"{cid:#04x}",
        "inputs": inputs,
        "sources": {"vs2": {"set": rj["src_set"], "oracle": rj["oracle_set"], "kind": "extract"},
                    "ours": {"set": str(a.build_dir), "kind": "built"}, "vh": None},
        "structures": {"bank": {"records": bank_records}, "dispatch": dispatch, "regions": reg_out,
                       "sfx": sfx, "fsm_nodes": fsm, "sprite_lists": sprite, "anim": anim, "hitbox": hitbox, "projectile": projectile},
        "overrides": overrides,
        "undecoded": UNDECODED,
        "diff_summary": {
            "bank_fields_unattributed": sum(1 for rec in bank_records.values() for fd in rec["fields"].values() if fd.get("ours_source") == "UNATTRIBUTED"),
            "dispatch_unattributed": sum(1 for d in dispatch.values() if d["ours_source"] == "UNATTRIBUTED"),
            "region_bytes_unattributed": totals["unattributed"],
            "relocated_bad": totals["relocated_bad"],
            "code_bytes_differ_out_of_scope": totals["code_bytes_differ"],
            "physics_rows_ported": port_param32,
            "anim_nodes": anim.get("_summary", {}).get("nodes", 0),
            "anim_nodes_differ_unattributed": anim.get("_summary", {}).get("differ", 0) - anim.get("_summary", {}).get("attributed", 0),
        },
    }
    text = json.dumps(out, indent=1, sort_keys=True) + "\n"
    a.out.parent.mkdir(parents=True, exist_ok=True)
    a.out.write_text(text)
    print(f"wrote {a.out}  sha1 {hashlib.sha1(text.encode()).hexdigest()}  ({len(text)} bytes)")
    print("summary:", json.dumps(out["diff_summary"]))


if __name__ == "__main__":
    main()
