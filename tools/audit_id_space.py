#!/usr/bin/env python3
"""audit_id_space.py — is the character-id variant half (0x10-0x1F) a hard
architectural half, or a convention the data follows?

The question governs the roster design (can three newcomers take three ids,
or is an indirection needed between wheel cell and character id?) and what a
per-tenant manifest has to declare.

TWO MEASUREMENTS, because the question has two halves.

1. CODE — how wide is the id where it is consumed? Every read of the id
   field `$382(An)` is located, the destination register is tracked forward,
   and the first mask/compare applied to it is reported. A site that does
   `andi #$0f` FOLDS the variant half onto the base half (that subsystem
   cannot tell 0x13 from 0x03); a site with no mask, or `andi #$1f`, treats
   the id as a full 5-bit value.

2. DATA — do the upper rows exist and what is in them? For every id-indexed
   table, row 0x10+k is compared against row k: `alias` (byte-equal, the
   row exists but duplicates), `distinct` (a real alternate dataset), or
   `out of range` (the table is too narrow to have the row at all).

Reading of the result: aliasing is CONVENTIONAL if the upper rows are real
storage that happens to hold copies, and ARCHITECTURAL if the code folds
the bit away or the tables have no upper rows.

Usage:
  audit_id_space.py --set vsavj --op <opcodes.bin> --dat <data.bin>
                    [--bank-map build/manifest/bank_map.toml] [--json out]

Views matter (docs/GOTCHAS.md): tables read `(d8,PC,Dn)` live in the OPCODE
image, tables reached via `lea`/`movea.l` + `(An,Dn)` live in the DATA
image. Each table below records which.
"""

import argparse
import json
import sys

try:
    import capstone
except ImportError:
    print("audit_id_space.py needs capstone (pip3 install capstone)")
    raise

sys.path.insert(0, "tools")
from _minitoml import _loads_subset as toml_loads   # noqa: E402

ID_FIELD = 0x382          # character id, player struct + 0x382
NIDS = 32                 # 5-bit id space

# id-indexed tables OUTSIDE the per-character bank, with the view each is
# read through and its entry width. Located from their consumer sites.
EXTRA_TABLES = {
    "vsavj": [
        # name, addr, entry bytes, rows, view, consumer
        ("obj_bank", 0x0282D4, 2, 32, "op", "0x282BA/0x282C8 (pc-rel indexed)"),
        ("wheel_adjacency", 0x0211E4, 8, 32, "dat", "0x020A70 (lea + (An,Dn))"),
        # 12 words/char (6 pairs, $bc(a5) picks +0/+2), values 0x0370-0x03D7.
        # Its consumer PRG:0x04FAC4 masks the id to 4 bits even though the
        # table has 32 real rows — the mask is convention, not structure.
        ("anim_pairs", 0x04FFA8, 24, 32, "dat", "0x04FAC4 (lea (pc) + (An,Dn))"),
    ],
    "vsav2": [
        ("obj_bank", 0x027530, 2, 32, "op", "per docs/atlas/character_tables.md"),
        ("wheel_adjacency", 0x01588E, 8, 32, "dat", "0x01F638 (movea.l + (An,Dn))"),
    ],
}


def disasm(md, img, addr, count):
    return list(md.disasm(img[addr:addr + count * 10], addr, count=count))


def id_read_sites(md, img, limit=0x400000):
    """Every instruction whose SOURCE is $382(An). Returns
    [(addr, mnemonic, op_str, dst_reg or None)]."""
    out = []
    for a in range(0, limit, 2):
        if img[a:a + 2] != b"\x03\x82":
            continue
        ins = disasm(md, img, a - 2, 1)
        if not ins:
            continue
        i = ins[0]
        if i.size < 4 or "$382(a" not in i.op_str:
            continue
        src, _, dst = i.op_str.partition(", ")
        if "$382(a" not in src:
            continue            # a WRITE to the field, not a read
        out.append((a - 2, i.mnemonic, i.op_str,
                    dst.strip() if dst.strip().startswith("d") else None))
    return out


def _mn(i):
    """capstone m68k mnemonics carry a size suffix (andi.w, move.b). Compare
    on the stem — the first draft of this tool compared on the full mnemonic,
    matched nothing, and reported a confident 'no site masks the id'."""
    return i.mnemonic.split(".")[0]


def first_mask(md, img, addr, reg, depth=10):
    """Walk forward from a read site and report the first andi/cmpi applied
    to `reg`, and whether the value is used to index a table before that."""
    a = addr
    ins = disasm(md, img, a, depth + 1)
    scaled = False
    for i in ins[1:]:
        ops = i.op_str
        m = _mn(i)
        if m in ("rts", "jmp", "bra", "rte") or (
                m.startswith("b") and m not in ("bset", "bclr", "btst", "bchg")):
            break
        if reg and reg in ops:
            if m in ("andi", "and") and "#$" in ops:
                imm = ops.split("#$")[1].split(",")[0].split(" ")[0]
                return ("mask", int(imm, 16), i.address)
            if m in ("cmpi", "cmp") and "#$" in ops:
                imm = ops.split("#$")[1].split(",")[0].split(" ")[0]
                return ("compare", int(imm, 16), i.address)
            if m in ("add", "addx", "lsl", "asl", "addq") and reg in ops:
                scaled = True
            if m in ("move", "movea") and ("(pc," in ops or
                                                    ("(a" in ops and "," + reg in ops)):
                return ("index-unmasked" if not scaled else "index-scaled",
                        None, i.address)
    return ("none", None, None)


# bank origins per set: internal deltas are preserved across all three sets,
# so a vsavj table address rebases by the origin difference (bank_map.toml
# header; verified M1). Reading vsavj addresses out of a vs2 image would
# compare unrelated bytes and invent findings.
BANK_ORIGIN = {"vsavj": 0x0BD0FA, "vsav2": 0x0D7298}


def direct_masks(img, limit=0x400000):
    """`andi.b #imm,$382(An)` — a mask applied STRAIGHT TO THE ID FIELD in
    memory, with no destination register.

    This class is invisible to any register-dataflow walk, and both of this
    tool's earlier walkers missed it for exactly that reason: they tracked
    the register a read went into, and these instructions do not read into
    one. Found only because the id-cycling selector was disassembled by
    hand. Encoding: andi.b #imm,(d16,An) = 0x0228|An, imm byte, disp word.
    """
    out = []
    for a in range(0, limit, 2):
        hi, lo = img[a], img[a + 1]
        if hi != 0x02 or not (0x28 <= lo <= 0x2F):
            continue
        if img[a + 4:a + 6] != b"\x03\x82":
            continue
        out.append((a, img[a + 3], lo & 7))
    return out


def mask_class(imm):
    """A mask FOLDS the variant half only if it keeps the low nibble whole
    and clears bit 4 — i.e. exactly #$0f. #$1f is the full 5-bit id. Any
    other value is a RANGE RESTRICTION for some menu context and must not be
    counted as a fold: vsav2 cycles ids with #$1f in one mode and #$01 in
    another (a 2-value toggle selected by a5-0x50B8), and a naive
    "imm < 0x10 means folding" test miscounts that #$01 as a fold."""
    if imm == 0x0F:
        return "folds-variant-half"
    if imm == 0x1F:
        return "full 5-bit"
    return "range-restriction #$%02x" % imm


def load_bank_tables(path, set_name):
    """-> (decoded, undecoded). `auto` rows are gaps with NO decoded
    consumer; docs/GOTCHAS.md ("Never write an unverified gap") is explicit
    that a gap between known tables is not necessarily a per-character
    table at all, so they are reported apart and never counted as evidence."""
    bm = toml_loads(open(path).read())
    dec, und = [], []
    for t in bm.get("table", []):
        vj = t["vsavj"] if isinstance(t["vsavj"], int) else int(str(t["vsavj"]), 16)
        kind = t.get("kind")
        total = t.get("span") if kind == "byte2d" else t.get("stride")
        if not total:
            continue
        vj += BANK_ORIGIN[set_name] - BANK_ORIGIN["vsavj"]
        row = (t["name"], vj, total // NIDS, NIDS, "dat", "bank/%s" % kind)
        # rec8/byte2d entry LAYOUT is not verified against a consumer:
        # docs/GOTCHAS.md "Per-char table entries are PAIRS more often than
        # you think" — a 16-char table of 8-byte pairs and a 32-char table
        # of 8-byte values have identical spacing, so "row 0x10+k" may not
        # be a row at all. Reported, never counted as evidence.
        (und if kind in ("auto", "rec8", "byte2d") else dec).append(row)
    return dec, und


def alias_matrix(tables, imgs):
    """For each table and each variant id, classify row 0x10+k vs row k."""
    rows = []
    for name, addr, ent, nrow, view, note in tables:
        img = imgs[view]
        rec = {"table": name, "addr": addr, "entry": ent, "rows": nrow,
               "view": view, "note": note, "classes": {}}
        for k in range(0x10):
            hi = 0x10 + k
            if hi >= nrow:
                rec["classes"]["%02X" % hi] = "out-of-range"
                continue
            lo_b = img[addr + k * ent: addr + (k + 1) * ent]
            hi_b = img[addr + hi * ent: addr + (hi + 1) * ent]
            rec["classes"]["%02X" % hi] = "alias" if lo_b == hi_b else "distinct"
        rows.append(rec)
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", required=True, choices=sorted(EXTRA_TABLES))
    ap.add_argument("--op", required=True, help="OPCODE image")
    ap.add_argument("--dat", required=True, help="DATA image")
    ap.add_argument("--bank-map", default="build/manifest/bank_map.toml")
    ap.add_argument("--json")
    args = ap.parse_args()

    imgs = {"op": open(args.op, "rb").read(), "dat": open(args.dat, "rb").read()}
    md = capstone.Cs(capstone.CS_ARCH_M68K,
                     capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)

    print("== 1. CODE: how wide is the id where it is consumed? ==")
    sites = id_read_sites(md, imgs["op"])
    buckets = {}
    detail = []
    for addr, mnem, ops, reg in sites:
        kind, imm, at = first_mask(md, imgs["op"], addr, reg)
        key = kind if imm is None else "%s #$%02x" % (kind, imm)
        buckets.setdefault(key, []).append(addr)
        detail.append({"site": addr, "insn": "%s %s" % (mnem, ops),
                       "kind": kind, "imm": imm, "at": at})
    print("  %d read sites of $%03X(An)\n" % (len(sites), ID_FIELD))
    for key in sorted(buckets, key=lambda k: -len(buckets[k])):
        ex = " ".join("%06X" % a for a in buckets[key][:6])
        print("   %-22s %4d  e.g. %s" % (key, len(buckets[key]), ex))

    print("\n  CAVEAT: 'none' means no mask/compare was seen within %d "
          "instructions\n  of the read, stopping at the first branch — it is "
          "NOT proof that the site\n  does not narrow the id later. The "
          "folding list below is a LOWER BOUND." % 10)

    direct = direct_masks(imgs["op"])
    print("\n  masks applied DIRECTLY to the id field in memory "
          "(no destination register — invisible to a dataflow walk):")
    if direct:
        for a, imm, an in direct:
            cls = mask_class(imm)
            print("    %06X  andi.b #$%02x,$382(a%d)   %s%s"
                  % (a, imm, an, cls,
                     "   <-- FOLDS" if cls == "folds-variant-half" else ""))
    else:
        print("    none")

    folding = {k: v for k, v in buckets.items()
               if k.startswith("mask") and int(k.split("#$")[1], 16) < 0x10}
    print("\n  sites masking the id BELOW 5 bits (these fold 0x1x -> 0x0x):")
    nfold = 0
    if folding:
        for k, v in folding.items():
            print("    %s: %s" % (k, " ".join("%06X" % a for a in v)))
            nfold += len(v)
    dfold = [a for a, imm, _ in direct
             if mask_class(imm) == "folds-variant-half"]
    if dfold:
        print("    direct-to-memory: %s"
              % " ".join("%06X" % a for a in dfold))
        nfold += len(dfold)
    if not nfold:
        print("    none")
    print("    TOTAL FOLDING SITES: %d" % nfold)

    print("\n== 2. DATA: do the upper rows exist, and what is in them? ==")
    dec, und = load_bank_tables(args.bank_map, args.set)
    tables = dec + EXTRA_TABLES[args.set]
    mat = alias_matrix(tables, imgs)
    mat_und = alias_matrix(und, imgs)
    n_alias = n_dist = n_oor = 0
    distinct_rows = []
    for rec in mat:
        cs = rec["classes"]
        n_alias += sum(1 for v in cs.values() if v == "alias")
        n_dist += sum(1 for v in cs.values() if v == "distinct")
        n_oor += sum(1 for v in cs.values() if v == "out-of-range")
        d = sorted(k for k, v in cs.items() if v == "distinct")
        if d:
            distinct_rows.append((rec["table"], rec["addr"], d))
    print("  %d tables x 16 variant ids: %d alias, %d distinct, %d out-of-range"
          % (len(mat), n_alias, n_dist, n_oor))
    print("\n  tables whose variant rows are NOT all copies:")
    if distinct_rows:
        for name, addr, d in distinct_rows:
            print("    %-18s %06X  distinct at %s" % (name, addr, " ".join(d)))
    else:
        print("    none — every variant row is a verbatim copy")

    nd = sum(1 for r in mat_und
             for v in r["classes"].values() if v == "distinct")
    print("\n  (separately: %d rows whose per-id LAYOUT is unverified —"
          "\n   `auto` gaps with no decoded consumer, and rec8/byte2d whose"
          "\n   entry shape is assumed; %d variant slots differ there."
          "\n   NOT counted as evidence — docs/GOTCHAS.md.)" % (len(mat_und), nd))

    if args.json:
        json.dump({"set": args.set, "sites": detail, "tables": mat,
                   "undecoded": mat_und},
                  open(args.json, "w"), indent=1)
        print("\nwrote %s" % args.json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
