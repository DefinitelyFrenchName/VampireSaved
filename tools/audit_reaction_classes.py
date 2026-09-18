#!/usr/bin/env python3
"""audit_reaction_classes.py — the REACTION-CLASS route of a hit, re-derived from the
decrypted images, for the classes the tenants' electric hits use (14z-169, the analysis
before the ruled class-0x52 fix: the column shock and the Plasma Trap, #136).

  python3 tools/audit_reaction_classes.py <vsavj_op> <vsavj_data> <vsav2_op> <vsav2_data>
                                          [--ours <build verify_op.bin>] [--tsv]

WHAT A HIT'S CLASS GOES THROUGH (docs/game/engine_internals.md, the reaction-class
paragraphs; every row below is re-read from the image, none is typed in):
  1. the record's class byte (attack record +0x17) is dispatched by ONE of three STAGER
     tables — ground / air / KO, chosen by the victim's state (+0x11F, the HP signs,
     +0x38) — whose handler writes the victim's +0x54: the class itself (the copy
     handler, `move.b $17(a3),$54(a1)`) or a constant (`move.b #n,$54(a1)`);
  2. the victim's +0x54 is dispatched by the REACTION table to a handler, which ends in
     the property byte map [+0x54] and the common install.
So a record class reaches the reaction table only through what its stager WRITES.

MEASURED 14z-169 (this tool's first run): vsavj's ground stager writes 6 for BOTH 0x06
and 0x38 (one handler), its air stager 7 for 0x06/0x07/0x38, its KO stager 8 for
0x06/0x07/0x38/0x39/0x48; no stager handler in either game writes 0x38, and no
`move.b #imm,$54(An)` in either game's code writes it. So no record class — 0x38
included (one Victor record carries it on both games) — leaves 0x38 in +0x54 on vsavj:
the 14z-168 idea that a record remapped to 0x38 would name the column apart from
Lightning Sword's 0x06 at the shock handler is FALSE (the stager rewrites it to 6).
vs2 tells its column apart only on a GROUNDED victim: its ground stager writes 0x52 for
0x52, and its shock handler 0x22656 is vsavj's 0x23AC8 plus ONE test —
`cmpi.b #$52,$54(a6); beq` around the attacker's freeze write; its air and KO stagers
fold 0x52 into 7 and 8 like everything else.

WHO CONSUMES THE CLASS (measured 14z-169, the consumer rows): the victim's +0x54 is
compared against constants at 80+ sites in each game and never against 0x06, 0x07,
0x08, 0x38 or 0x4E — vs2 compares it against 0x52 once, in the shock handler; the three
per-class tables it indexes (-> +0x26) hold the same byte for 0x06 and 0x38 (and vs2's
for 0x52); the property map holds 0x0F for all three. So 0x38 IN +0x54 is read by every
consumer found exactly as 0x06 is — the role 0x52 plays on vs2. 0x38 IN THE RECORD is
not: the guard decision (vsavj 0x182E8-0x183E4) sends record classes 0x02, 0x03, 0x38 and
0x39 to the HIT path when the victim's crouch flag +0x121 is 0 (tests/audit_crouch_flag.sh),
where 0x06 and vs2's 0x52 are in neither of its lists — a third reason the 14z-168 remap idea
fails. How that plays (a low) is a reading of the code: no 0x38 hit against a guard was run
and nothing was captured.

THE RECORD CENSUS walks tables a/a2/b/c and proj of every legacy id both games carry,
as tools/audit_facing_rules.py does (the same resolvers), and counts DISTINCT records by
+0x17. The walk reaches some records that are not real (classes >= 0x50 on vsavj, which
no stager table indexes), so this counts REACHABLE records, not true ones.

NOT COVERED: a class byte read by code other than the three stagers ("the compares" of
the readers table in engine_internals.md) and +0x54 written from a REGISTER — both need
the live census, tests/audit_reaction_class_live.sh.
"""
import argparse, collections, difflib, hashlib, re, struct, sys
from pathlib import Path

R = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(R / "tools"))

# (vsavj table, vs2 table) — the three stager dispatchers and the reaction dispatch
# (engine_internals.md "The reaction-class dispatch is THREE dispatchers"; [VSE-42])
TABLES = {"stager_ground": (0x018468, 0x016D34), "stager_air": (0x018510, 0x016DE4),
          "stager_ko": (0x0185DA, 0x016EB6), "reaction": (0x02385C, 0x022388)}
ENTRIES = {"vsavj": 80, "vsav2": 84}          # 0x00-0x4F / 0x00-0x53 (the renumber gap)
SHOCK = {"vsavj": 0x023AC8, "vsav2": 0x022656}  # the electric-shock reaction handler
PROP = {"vsavj": 0x028D00, "vsav2": 0x027FD8}   # the property byte map (data view)
CLASSES = (0x06, 0x07, 0x08, 0x38, 0x39, 0x48, 0x4E, 0x52)
COPY_RE = re.compile(r"^move\.b \$17\(a3\), \$54\(a1\)$")
IMM_RE = re.compile(r"^move\.b #\$([0-9a-f]+), \$54\(a1\)$")


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def disasm(img, a, n):
    import capstone
    md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)
    return [(i.address, f"{i.mnemonic} {i.op_str}".strip()) for i in md.disasm(img[a:a + n], a)]


def target(img, table, idx):
    return table + struct.unpack(">h", img[table + 2 * idx:table + 2 * idx + 2])[0]


def entries(img, table, n):
    t = [target(img, table, i) for i in range(n)]
    # a table cannot hold its own handlers: every target lies past its last entry
    if min(t) < table + 2 * n:
        raise SystemExit(f"table {table:#x}: a target {min(t):#x} lies inside the {n}-entry table — wrong bound")
    return t


def stager_write(img, a):
    """what a stager handler stores to the victim's +0x54, up to its rts: 'copy', '#nn', or 'none'"""
    out = []
    for _, s in disasm(img, a, 0x20):
        if COPY_RE.match(s):
            out.append("copy")
        m = IMM_RE.match(s)
        if m:
            out.append(f"#{int(m.group(1), 16):02x}")
        if s.startswith("rts") or s.startswith("jmp") or s.startswith("bra"):
            break
    return "+".join(out) or "none"


def norm(s):
    # pc-relative targets and branch displacements move between games; the SHAPE is what is compared
    return re.sub(r"\$[0-9a-f]{4,6}(?=\(pc|$)", "$T", re.sub(r"^(b\w+\.[bw]|bra\.[bw]|bsr\.[bw]|jmp|jsr) .*", r"\1 T", s))


def routes(game, op, ents):
    rows = []
    n = ENTRIES[game]
    tabs = {k: entries(op, v[0 if game == "vsavj" else 1], n) for k, v in TABLES.items()}
    for k in ("stager_ground", "stager_air", "stager_ko"):
        writes = [stager_write(op, t) for t in tabs[k]]
        for c in CLASSES:
            if c < n:
                rows.append((game, "route", k, f"{c:02x}", writes[c]))
        w38 = [f"{i:02x}" for i, w in enumerate(writes) if "#38" in w]
        rows.append((game, "writes38", k, "-", ",".join(w38) or "none"))
        rows.append((game, "copy-count", k, "-", str(sum(1 for w in writes if w == "copy"))))
    rt = tabs["reaction"]
    shock = SHOCK[game]
    rows.append((game, "reaction-to-shock", f"{shock:06x}", "-",
                 ",".join(f"{i:02x}" for i, t in enumerate(rt) if t == shock) or "none"))
    return rows


def shock_diff(jop, vop, va=None):
    """the instruction-shape difference between vsavj's shock handler and another image's
    (vs2's at its own address, or a build's at vsavj's), up to the branch into the common install"""
    def body(img, a):
        out = []
        for _, s in disasm(img, a, 0x60):
            out.append(norm(s))
            if s.startswith("bra"):
                break
        return out
    j, v = body(jop, SHOCK["vsavj"]), body(vop, SHOCK["vsav2"] if va is None else va)
    d = [("vs2-only" if l[0] == "+" else "vsavj-only", l[2:]) for l in difflib.ndiff(j, v) if l[:1] in "+-"]
    return len(j), len(v), d


def record_census(game, data):
    import _minitoml as mt
    from anim_nodes import walk_table
    from hitbox_records import HitboxSet
    from audit_same_data_p2 import SHARED, NAMES, rd32
    bank = mt.loads((R / "build/manifest/bank_map.toml").read_text())
    rows = {t["name"]: int(t["vsavj"]) for t in bank["table"]}
    d = int(bank["origins"][game]) - int(bank["origins"]["vsavj"])
    seen = {}
    for cid in SHARED:
        hb = HitboxSet.from_image(data, rd32(data, rows["hitbox_base"] + d + cid * 4), rd32(data, rows["hitbox_comp"] + d + cid * 4))
        try:
            phb = HitboxSet.from_image(data, rd32(data, rows["proj_hitbox_base"] + d + cid * 4), rd32(data, rows["proj_hitbox_comp"] + d + cid * 4))
        except Exception:
            phb = None
        for name in ("anim_index_a", "anim_index_a2", "anim_index_b", "anim_index_c", "anim_index_proj"):
            h = phb if name == "anim_index_proj" else hb
            if h is None:
                continue
            res = walk_table(data, 0, rd32(data, rows[name] + d + cid * 4))
            for seq, ch in res["chains"].items():
                for nd in ch["nodes"]:
                    if (nd.get("hbA", 0) >> 8) == 0:
                        continue
                    rec = h.node_boxes(nd["hb8"], nd["hbA"])["attack"]
                    if rec:
                        seen.setdefault((cid, name == "anim_index_proj", rec["addr"]), (rec["cls"], NAMES[cid]))
    c = collections.Counter(v[0] for v in seen.values())
    out = [(game, "records", "reachable", "-", str(len(seen))),
           (game, "records", "class>=50", "-", str(sum(v for k, v in c.items() if k >= 0x50)))]
    for k in CLASSES:
        who = collections.Counter(f"{v[1]}/{'proj' if kk[1] else 'fighter'}" for kk, v in seen.items() if v[0] == k)
        out.append((game, "records", "class", f"{k:02x}", f"{c.get(k, 0)} " + (",".join(f"{w}:{n}" for w, n in sorted(who.items())) or "-")))
    out.append((game, "records", "unused<50", "-", ",".join(f"{k:02x}" for k in range(0x50) if k not in c)))
    return out


def imm_writers(game, op, end=0x100000):
    """every `move.b #imm,$54(An)` in the image's code (the reference sets below the crypt
    bound; a build's whole image, placed code included), by value"""
    hits = collections.defaultdict(list)
    for a in range(0, end, 2):
        w = struct.unpack(">H", op[a:a + 2])[0]
        if w & 0xF1FF == 0x117C and op[a + 2] == 0 and op[a + 4:a + 6] == b"\x00\x54":
            hits[op[a + 3]].append(f"{a:06x}/a{(w >> 9) & 7}")
    rows = [(game, "imm54", "sites", "-", str(sum(len(v) for v in hits.values()))),
            (game, "imm54", "values", "-", ",".join(f"{k:02x}:{len(v)}" for k, v in sorted(hits.items())))]
    for k in CLASSES:
        rows.append((game, "imm54", "value", f"{k:02x}", ",".join(hits.get(k, [])) or "none"))
    return rows


CLASS_TABLES = {"vsavj": (0x028BE0, 0x028C40, 0x028CA0), "vsav2": (0x027EB8, 0x027F18, 0x027F78)}  # +0x54 -> +0x26 (default / +0xA / +0x1A8), data view
GUARD = {"vsavj": (0x018358, 0x0183BC), "vsav2": (0x016C1A, 0x016C88)}  # the guard decision's class compares (standing, then crouching)


def cmp_census(game, op, end, disp):
    """every `cmpi.b #imm,<disp>(An)` in the image's code, by value"""
    hits = collections.defaultdict(list)
    for a in range(0, end, 2):
        w = struct.unpack(">H", op[a:a + 2])[0]
        if w & 0xFFF8 == 0x0C28 and op[a + 2] == 0 and op[a + 4:a + 6] == struct.pack(">H", disp):
            hits[op[a + 3]].append(a)
    return hits


def consumers(game, op, dat, end=0x100000):
    """the facts behind "0x38 in +0x54 reacts as 0x06; 0x38 in the RECORD does not" (14z-169)"""
    rows = []
    r17 = cmp_census(game, op, end, 0x17)
    rows.append((game, "rec17-cmp", "all", "-", ",".join(f"{k:02x}" for k in sorted(r17))))
    lo, hi = GUARD[game] if game in GUARD else GUARD["vsavj"]
    for k in CLASSES:
        where = [a for a in r17.get(k, [])]
        tag = ",".join(f"{a:06x}" + ("(guard)" if lo <= a <= hi else "") for a in where)
        rows.append((game, "rec17-cmp", "class", f"{k:02x}", tag or "none"))
    c54 = cmp_census(game, op, end, 0x54)
    rows.append((game, "cmp54", "all", "-", ",".join(f"{k:02x}" for k in sorted(c54))))
    for k in CLASSES:
        rows.append((game, "cmp54", "class", f"{k:02x}", ",".join(f"{a:06x}" for a in c54.get(k, [])) or "none"))
    if dat is not None:
        for t, nm in zip(CLASS_TABLES[game], ("default", "+0xA", "+0x1A8")):
            rows.append((game, "class-table", f"{t:06x}", nm,
                         ",".join(f"{c:02x}:{dat[t + c]:02x}" for c in CLASSES if c < ENTRIES[game])))
    return rows


def run(jop, jdat, vop, vdat, ours=None):
    rows = []
    rows += routes("vsavj", jop, ENTRIES)
    rows += routes("vsav2", vop, ENTRIES)
    if ours is not None:
        rows += [("ours",) + r[1:] for r in routes("vsavj", ours, ENTRIES)]
    for g, dat in (("vsavj", jdat), ("vsav2", vdat)):
        base = PROP[g]
        rows.append((g, "property", f"{base:06x}", "-",
                     ",".join(f"{c:02x}:{dat[base + c]:02x}" for c in CLASSES if c < ENTRIES[g])))
    nj, nv, d = shock_diff(jop, vop)
    rows.append(("both", "shock-handler", f"{SHOCK['vsavj']:06x}|{SHOCK['vsav2']:06x}", "-",
                 f"{nj}|{nv} instructions; " + (" ; ".join(f"{s}: {t}" for s, t in d) or "identical")))
    if ours is not None:
        nj2, no, d2 = shock_diff(jop, ours, SHOCK["vsavj"])
        rows.append(("ours", "shock-handler", f"{SHOCK['vsavj']:06x}", "-",
                     f"{nj2}|{no} instructions vs pristine; " + (" ; ".join(f"{'ours-only' if s == 'vs2-only' else 'vsavj-only'}: {t}" for s, t in d2) or "identical")))
    rows += record_census("vsavj", jdat)
    rows += record_census("vsav2", vdat)
    rows += imm_writers("vsavj", jop)
    rows += imm_writers("vsav2", vop)
    rows += consumers("vsavj", jop, jdat)
    rows += consumers("vsav2", vop, vdat)
    if ours is not None:
        # the whole 6 MB image: placed tenant code included (the constant writers added 14z-169
        # after rule-checker run 2026-09-18-51 Q1: ours' placed code writes +0x54 live)
        rows += [("ours",) + r[1:] for r in imm_writers("ours", ours, end=len(ours))]
        rows += [("ours",) + r[1:] for r in consumers("vsavj", ours, None, end=len(ours))]
    return rows


COPY_HANDLER = 0x01868C   # vsavj's copy handler, `move.b $17(a3),$54(a1)` (tools/audit_fsm_census.py)


def first_record(data, cls):
    """the address of the first reachable legacy vsavj record whose class is `cls`"""
    import _minitoml as mt
    from anim_nodes import walk_table
    from hitbox_records import HitboxSet
    from audit_same_data_p2 import SHARED, rd32
    bank = mt.loads((R / "build/manifest/bank_map.toml").read_text())
    rows = {t["name"]: int(t["vsavj"]) for t in bank["table"]}
    for cid in SHARED:
        hb = HitboxSet.from_image(data, rd32(data, rows["hitbox_base"] + cid * 4), rd32(data, rows["hitbox_comp"] + cid * 4))
        for name in ("anim_index_a", "anim_index_a2", "anim_index_b", "anim_index_c"):
            for seq, ch in walk_table(data, 0, rd32(data, rows[name] + cid * 4))["chains"].items():
                for nd in ch["nodes"]:
                    if (nd.get("hbA", 0) >> 8) == 0:
                        continue
                    rec = hb.node_boxes(nd["hb8"], nd["hbA"])["attack"]
                    if rec and rec["cls"] == cls:
                        return int(rec["addr"], 16)
    return None


def plant(kind, jop, jdat):
    """THE ONE PERTURBATION of each must-fire control (the gate's in-gate check and its mode
    both call this): returns (vsavj_op, vsavj_data, the rows it must move)."""
    jop, jdat = bytearray(jop), bytearray(jdat)
    if kind == "stager-38-copy":
        # vsavj's ground-stager entry 0x38 re-pointed at the copy handler, so a 0x38 record
        # WOULD leave 0x38 in +0x54 — the census must see the route change
        t = TABLES["stager_ground"][0] + 2 * 0x38
        jop[t:t + 2] = struct.pack(">h", COPY_HANDLER - TABLES["stager_ground"][0])
        return bytes(jop), bytes(jdat), ("vsavj\troute\tstager_ground\t38\t", "vsavj\tcopy-count\tstager_ground\t")
    if kind == "record-06-to-38":
        # the first reachable class-0x06 legacy record re-classed 0x38 — the record census
        # must count one fewer 0x06 and one more 0x38
        a = first_record(bytes(jdat), 0x06)
        if a is None:
            raise SystemExit("REFUSED: no reachable class-0x06 record to plant over")
        jdat[a + 0x17] = 0x38
        return bytes(jop), bytes(jdat), ("vsavj\trecords\tclass\t06\t", "vsavj\trecords\tclass\t38\t")
    raise SystemExit(f"REFUSED: no plant named {kind!r}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("vsavj_op"); ap.add_argument("vsavj_data"); ap.add_argument("vsav2_op"); ap.add_argument("vsav2_data")
    ap.add_argument("--ours", help="a build's verify_op.bin: its routes and shock handler beside pristine vsavj's")
    ap.add_argument("--plant", choices=("stager-38-copy", "record-06-to-38"),
                    help="run on a PLANTED copy of vsavj's images (the gate's must-fire controls); prints the rows it must move on stderr")
    ap.add_argument("--tsv", action="store_true")
    a = ap.parse_args()
    imgs = [Path(p).read_bytes() for p in (a.vsavj_op, a.vsavj_data, a.vsav2_op, a.vsav2_data)]
    ours = Path(a.ours).read_bytes() if a.ours else None
    for p, b in zip((a.vsavj_op, a.vsavj_data, a.vsav2_op, a.vsav2_data), imgs):
        print(f"# read {p} sha1 {sha1(b)}", file=sys.stderr)
    if ours is not None:
        print(f"# read {a.ours} sha1 {sha1(ours)}", file=sys.stderr)
    if a.plant:
        imgs[0], imgs[1], moves = plant(a.plant, imgs[0], imgs[1])
        for m in moves:
            print(f"# plant {a.plant} must move: {m.strip()}", file=sys.stderr)
    for r in run(*imgs, ours=ours):
        print("\t".join(r) if a.tsv else "  ".join(r))


if __name__ == "__main__":
    main()
