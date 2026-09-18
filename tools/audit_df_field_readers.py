#!/usr/bin/env python3
"""audit_df_field_readers.py — every PLACED instruction of a build that addresses one of vs2's
DARK FORCE POWER fields on a fighter block (14z-168, GitHub #136 / #157's Dark Force tail).

WHY. vs2 runs Dark Force Power (fields +0x1C3, +0x1C4, +0x1C6, +0x1C7, +0x1C8, set by its
activation body PRG:0x02619E); vsav — our host engine — runs Dark Force Change (+0x111, +0x110,
+0x176, +0x188/+0x189, set by PRG:0x027000). The tenants' ported code was written for vs2, so
wherever it tests a Power field it reads 0 in our Dark Force (measured: +0x1C3 is 0 throughout our
Dark Force Change, 1 throughout vs2's Power — docs/game/engine_internals.md, Dark Force). One such
reader is MEASURED to change play: the placed copy of vs2's meter adder (x028122) pays the tenants'
start-up gauge inside Dark Force Change (tests/audit_df_meter.sh). The others are listed here so none
is forgotten; what each one does in our Dark Force is not measured by this census.

WHAT IT READS. The build's DECRYPTED opcode image (verify_op.bin) over the build's own placed
spans — patch/placements.json regions whose name is a code region (`code…`, `xNNNNNN…`; data regions
such as anim/hitbox are skipped: a displacement word inside data decodes as a phantom instruction)
and every `code` op of patch/patch.json. At each even offset holding a field's displacement word it
decodes back 2, 4 and 6 bytes and keeps an instruction that starts there, spans the word and names
`$<field>(aN)` in its operands.

WHAT EACH ROW SAYS (corrected 14z-168 after rule-checker run 2026-09-18-46 Q4, which found the
first freeze called every row a "reader" though it held writes): the ACCESS the instruction makes
to the field — `read` (a source operand, or tst/cmp/btst/chk), `write` (the destination of a
move/movep/movem/clr/scc), `rmw` (the destination of an ALU or bit-change op), `addr` (lea/pea: the
address escapes into a register, so the access that follows is indirect and NOT in this census) —
and the BASE register. Nothing in this static census shows the base register holds a FIGHTER
block; the live gate (below) shows it for the rows the corpus executes, and only for those.
`--selftest` checks the scan and the classifier against hand-assembled 68000 encodings (every
access class, a second base register, an immediate and a data-region decoy that must NOT appear).

WHAT IT CANNOT SEE: an access through an index or absolute address, or through a register loaded
by an `addr` row; and vsavj's own code (only placed spans are scanned).
tests/audit_df_field_readers_live.sh cross-checks the rows against what the #136 corpus executes.

Usage: audit_df_field_readers.py <verify_op.bin> <placements.json> <patch.json> [--tsv]
                                 [--plant-first 1c3 --plant-out <image>]
       audit_df_field_readers.py --selftest
  --plant-first writes a copy of the image with the FIRST instruction naming that field re-addressed
  to +0x111 (the vsav field) — the census must then lose it (the gate's must-fire control).
Prints the SHA-1 of the image read.
"""
import argparse, hashlib, json, re, sys

FIELDS = (0x1C3, 0x1C4, 0x1C6, 0x1C7, 0x1C8)
CODE_RE = re.compile(r"^(code|x[0-9a-f]{6})(@|$)")


def spans(placements, patch):
    return spans_from(json.load(open(placements)), json.load(open(patch)))


def spans_from(placements, patch):
    out = []
    for name, r in placements["regions"].items():
        if CODE_RE.match(name):
            out.append((r["dst"], r["dst"] + r["len"], name))
    for o in patch["ops"]:
        if o.get("op") == "code":
            a = o["addr"]; a = int(a, 16) if isinstance(a, str) else a
            out.append((a, a + len(bytes.fromhex(o["hex"])), "code-op"))
    return sorted(out)


READ_ONLY = {"tst", "cmp", "cmpi", "cmpa", "cmpm", "btst", "chk"}
MOVES = {"move", "movea", "movep", "movem"}
ADDR = {"lea", "pea"}


def operands(op_str):
    """capstone's operand text split at top-level commas: `$10(a0,d1.w), d0` is two operands."""
    out, depth, cur = [], 0, ""
    for ch in op_str:
        depth += ch == "("; depth -= ch == ")"
        if ch == "," and depth == 0:
            out.append(cur.strip()); cur = ""
        else:
            cur += ch
    return out + [cur.strip()] if cur.strip() else out


def access(mnemonic, ops, idx):
    """what the instruction does to the operand at `idx`: read, write, rmw or addr."""
    base = mnemonic.split(".")[0]
    if base in ADDR:
        return "addr"
    if base in READ_ONLY:
        return "read"
    if base == "clr" or (base.startswith("s") and len(ops) == 1 and base not in ("swap",)):
        return "write"
    if base in MOVES:
        return "read" if idx == 0 else "write"
    if len(ops) == 2 and idx == 0:
        return "read"
    return "rmw"


def census(img, sp):
    import capstone
    md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)
    rows = {}
    for field in FIELDS:
        pat = field.to_bytes(2, "big"); want = re.compile(r"\$%x\((a\d)\)" % field)
        for lo, hi, name in sp:
            for off in range(lo + (lo & 1), min(hi, len(img)) - 1, 2):
                if img[off:off + 2] != pat:
                    continue
                for back in (2, 4, 6):
                    s = off - back
                    ins = list(md.disasm(img[s:s + 10], s, count=1))
                    if not (ins and ins[0].address == s and s + ins[0].size > off):
                        continue
                    ops = operands(ins[0].op_str)
                    hit = [(i, want.search(o).group(1)) for i, o in enumerate(ops) if want.search(o)]
                    if hit:
                        idx, reg = hit[0]
                        rows[(field, s)] = (name, ins[0].mnemonic, ins[0].op_str, off, access(ins[0].mnemonic, ops, idx), reg)
                        break
    return rows


# (hand-assembled 68000 words, the expected row or None) — encodings from the 68000 PRM opcode maps
FIXTURES = (
    ("4a2e 01c3",           (0x1C3, "read",  "a6")),   # tst.b $1c3(a6)
    ("1d7c 0001 01c3",      (0x1C3, "write", "a6")),   # move.b #$1, $1c3(a6)
    ("1d6e 01c3 019c",      (0x1C3, "read",  "a6")),   # move.b $1c3(a6), $19c(a6)
    ("1d41 01c6",           (0x1C6, "write", "a6")),   # move.b d1, $1c6(a6)
    ("522e 01c3",           (0x1C3, "rmw",   "a6")),   # addq.b #1, $1c3(a6)
    ("018c 01c8",           (0x1C8, "write", "a4")),   # movep.w d0, $1c8(a4)
    ("41ee 01c3",           (0x1C3, "addr",  "a6")),   # lea $1c3(a6), a0
    ("0c2e 0000 01c3",      (0x1C3, "read",  "a6")),   # cmpi.b #$0, $1c3(a6)
    ("302e 01c4",           (0x1C4, "read",  "a6")),   # move.w $1c4(a6), d0
    ("082e 0000 01c3",      (0x1C3, "read",  "a6")),   # btst #$0, $1c3(a6)
    ("42ae 01c4",           (0x1C4, "write", "a6")),   # clr.l $1c4(a6)
    ("303c 01c3",           None),                     # move.w #$1c3, d0 — an immediate, not a field
)


def selftest():
    img = bytearray(b"\x4e\x71" * 0x1000)                 # nop fill
    want, off = {}, 0x100
    for words, exp in FIXTURES:
        b = bytes.fromhex(words.replace(" ", ""))
        img[off:off + len(b)] = b
        if exp:
            want[(exp[0], off)] = exp[1:]
        off += len(b) + 4                                   # two nops between instructions
    img[0x800:0x806] = bytes.fromhex("01c301c401c8")        # field words inside a DATA region
    placements = {"regions": {"code@fixture": {"dst": 0x100, "len": off - 0x100}, "anim@fixture": {"dst": 0x800, "len": 6}}}
    got = {k: (v[4], v[5]) for k, v in census(bytes(img), spans_from(placements, {"ops": []})).items()}
    bad = [f"missing +0x{k[0]:x} at {k[1]:#x} {v}" for k, v in want.items() if k not in got]
    bad += [f"wrong +0x{k[0]:x} at {k[1]:#x}: {got[k]} for {v}" for k, v in want.items() if k in got and got[k] != v]
    bad += [f"false row +0x{k[0]:x} at {k[1]:#x} {v}" for k, v in got.items() if k not in want]
    for b in bad:
        print("SELFTEST FAIL", b)
    print(f"selftest: {len(want)} fixture rows, {len(bad)} wrong")
    return not bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image", nargs="?"); ap.add_argument("placements", nargs="?"); ap.add_argument("patch", nargs="?")
    ap.add_argument("--tsv", action="store_true"); ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--plant-first"); ap.add_argument("--plant-out")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(0 if selftest() else 1)
    img = bytearray(open(a.image, "rb").read())
    print(f"# image {a.image} sha1 {hashlib.sha1(img).hexdigest()}", file=sys.stderr)
    rows = census(bytes(img), spans(a.placements, a.patch))
    if a.plant_first:
        f = int(a.plant_first, 16)
        first = min((k for k in rows if k[0] == f), default=None)
        if first is None:
            sys.exit(f"REFUSED: no instruction naming +0x{f:x} to plant over")
        disp = rows[first][3]
        img[disp:disp + 2] = (0x111).to_bytes(2, "big")
        open(a.plant_out, "wb").write(img)
        print(f"planted +0x{f:x} -> +0x111 at {disp:#08x} (instruction {first[1]:#08x})", file=sys.stderr)
        return
    for (field, addr), (name, mn, op, _, acc, reg) in sorted(rows.items()):
        print(f"{acc}\t+0x{field:x}\t{addr:#08x}\t{name}\t{reg}\t{mn} {op}")
    by = {f: sum(1 for k in rows if k[0] == f) for f in FIELDS}
    print("count\t" + "\t".join(f"+0x{f:x}={n}" for f, n in by.items()))
    acc = {x: sum(1 for v in rows.values() if v[4] == x) for x in ("read", "write", "rmw", "addr")}
    print("access\t" + "\t".join(f"{k}={n}" for k, n in acc.items()))


if __name__ == "__main__":
    main()
