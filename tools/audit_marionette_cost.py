#!/usr/bin/env python3
"""audit_marionette_cost.py — where would a Marionette port have to hook vsavj?
(14z-189, GitHub #128: the maintainer authorised a COST MEASUREMENT, no build.)

WHAT IT MEASURES. vs2 (and vh2) carry a second copy-character flag, +0x3C3
(Marionette), that vsavj never touches (tests/test_copy_flags.sh: 0 / 28 / 31
code sites). For EVERY vs2 instruction naming `$3c3(aN)` this tool finds the
place in vsavj where vs2's code differs, by the three-sibling method (CLAUDE.md
§5 — vsavj and vs2 are two builds of one engine):

  1. ANCHORS. Every 0x20-byte window of vs2 code within +-RADIUS of the site is
     searched in vsavj with tools/find_equiv.py's masked matcher (absolute-address
     operands wildcarded). A window counts as an anchor only if its best vsavj
     match scores >= MIN and beats the runner-up by >= GAP (unique). The NEAREST
     anchor before the site and the nearest after it give two vs2->vsavj spans.
  2. INSTRUCTION DIFF. Both spans are disassembled (operands' immediates and
     absolute addresses normalised to `$X`, register-relative displacements such as
     `$3c3(` kept) and aligned with difflib. The non-equal block holding the site is
     the vs2 code vsavj lacks; the first vsavj instruction after it is the HOOK
     POINT — the address a port's hook would displace, and the one whose execution
     count prices the hook on legacy content.
  3. A site with no anchor pair inside RADIUS gets a second pass at RADIUS2 with
     looser MIN2/GAP2, accepted ONLY as a pure insertion (difflib `delete`): a wide
     window that "aligns" by replacement has walked into unrelated code or data
     (measured 14z-189 on vs2 0x08A6D4, where the wide pass paired 14 vs2
     instructions with 91 vsavj ones decoded out of data).
  4. Anything left is NEW — vs2 code inside a routine whose vsavj twin lacks the
     whole sub-state. Its row names the nearest vsavj twin address (the last
     pre-anchor's end) so the twin's execution can still be counted.

Rows: `SITE <vs2 addr> <insn> | <class> <n vs2 insns> <bytes> | hook <vsavj addr> <vsavj insn>`
with class INSERT (pure insertion), REPLACE (vs2 block replaces k vsavj insns:
the hook rewrites vanilla code), NEW (no re-alignment; twin named). Then
`HOOKS <n unique hook points>` and `HOOKLIST <comma-separated vsavj addrs>`.

WHAT IT CANNOT SEE: whether a hook point is EXECUTED by legacy content (that is
tests/lua/pc_count.lua's job, in tests/audit_marionette_cost.sh); the cost of
data (her records and art); whether vs2 code that does NOT name +0x3C3 is also
part of her (her per-round re-copy may live in such code — the 0x1BA-byte block
before vsavj 0x02B640 is counted once, as one hook). Linear disassembly can
mis-frame inside data (RH-11); the anchors must be unique to count.

Usage: audit_marionette_cost.py <vs2_op.bin> <vsavj_op.bin>
       audit_marionette_cost.py --assets <vs2_data.bin>     (her records' size, see ASSET_CHAINS)
Prints the SHA-1 of both images. Exit 0 always — the gate judges.
"""
import difflib
import hashlib
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import capstone  # noqa: E402
import find_equiv as fe  # noqa: E402

RADIUS, MIN, GAP = 0x100, 0.90, 0.20
RADIUS2, MIN2, GAP2 = 0x300, 0.85, 0.15
WIN = 0x20
HI = 0xC0000
NUM = re.compile(r"\$-?[0-9a-f]+(?![0-9a-f]*\()")
md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)


def ins_at(img, pc):
    return next(md.disasm(img[pc:pc + 10], pc), None)


def txt(img, pc):
    x = ins_at(img, pc)
    return f"{x.mnemonic} {x.op_str}".strip().replace(" ", "") if x else "?"


def stream(img, lo, hi):
    out, pc = [], lo
    while pc < hi:
        x = ins_at(img, pc)
        if x is None:
            out.append((pc, 2, "?"))
            pc += 2
            continue
        out.append((pc, x.size, x.mnemonic + " " + NUM.sub("$X", x.op_str)))
        pc += x.size
    return out


def sites_of(img):
    out, pc = [], 0
    while pc < HI:
        x = ins_at(img, pc)
        if x is None:
            pc += 2
            continue
        if "$3c3(a" in f"{x.mnemonic} {x.op_str}":
            out.append(pc)
        pc += x.size
    return out


def anchors(src, dst, s, size, radius, mn, gap):
    pre = post = None
    for o in range(-radius, radius + 2, 2):
        a = s + o
        if o < 0 and a + WIN > s:
            continue
        if 0 <= o < size:
            continue
        try:
            c = fe.masked_search(src, dst, a, WIN, allow_fallback=False)
        except fe.WindowUnusable:
            continue
        if not c:
            continue
        second = c[1][0] if len(c) > 1 else 0.0
        if c[0][0] < mn or c[0][0] - second < gap:
            continue
        if o < 0:
            pre = (o, c[0][1] - a)
        elif post is None:
            post = (o, c[0][1] - a)
    return pre, post


def classify(src, dst, s, pre, post):
    a_lo, a_hi = s + pre[0], s + post[0] + WIN
    b_lo, b_hi = a_lo + pre[1], a_hi + post[1]
    A, B = stream(src, a_lo, a_hi), stream(dst, b_lo, b_hi)
    sm = difflib.SequenceMatcher(None, [x[2] for x in A], [x[2] for x in B], autojunk=False)
    for op, i1, i2, j1, j2 in sm.get_opcodes():
        if op != "equal" and any(A[k][0] == s for k in range(i1, i2)):
            hook = B[j1][0] if j1 < len(B) else b_hi
            nbytes = sum(A[k][1] for k in range(i1, i2))
            return op, i2 - i1, nbytes, hook, j2 - j1
    return None


import gfx_tiles  # noqa: E402

# HER ASSETS IN vs2, as the code that names +0x3C3 selects them (14z-189, read off
# vs2 PRG:0x06C32A / 0x0933EA / 0x02ACCA): each is an index into an effect-anim
# table fed to the setter at vs2 0x013778 (`a0 = table + word[table + 2*idx]`),
# or a palette-row offset.
ASSET_CHAINS = [("select", 0x2A04FA, 0x10, "vs2 0x06C32A: the select-screen record, row 0x10"),
                ("vs", 0x2B7EF4, 0xB3, "vs2 0x0933EA: the VS/sprite record, index 0xB3 (else 0xAA)")]
ASSET_PAL = (0x3CB7DC, 0x140, "vs2 0x02ACCA: `lea $140(a0)` past the palette base, + id($3AE)*32")


def u16(d, a):
    return int.from_bytes(d[a:a + 2], "big")


def u32(d, a):
    return int.from_bytes(d[a:a + 4], "big")


def chain(d, table, idx):
    """The effect walker (vs2 0x013790): 0x10-byte nodes; flags byte +1: 0 -> next
    node (+0x10); negative -> the LINK long at +0x10; bit 6 -> hold (end); +4.l the
    sprite record. Returns the node addresses in walk order (each once)."""
    a, seen = table + u16(d, table + 2 * idx), []
    while a not in seen and len(seen) < 512:
        seen.append(a)
        fl = d[a + 1]
        if fl & 0x80:
            a = u32(d, a + 0x10)
        elif fl & 0x40 and fl != 0:
            break
        else:
            a = a + 0x10
    return seen


def record_cells(d, rec):
    """The tile codes one OBJ record draws (format 2: count+1 (tile, attr) entries;
    format 0x0A: count+1 8-byte (tile, attr, x, y) entries; format 0: count tile words, one attr) — obj_records.py's decode, blocks expanded
    by gfx_tiles. Returns (format, entries, cells set) or None for a non-record."""
    fmt = u16(d, rec)
    if fmt == 2:
        n = u16(d, rec + 4) + 1
        ent = [(u16(d, rec + 10 + 4 * i), u16(d, rec + 12 + 4 * i)) for i in range(n)]
    elif fmt == 0x0A:   # (tile, attr, x, y) 8-byte entries, count-1 at +6 (her select record, measured 14z-189)
        n = u16(d, rec + 6) + 1
        ent = [(u16(d, rec + 8 + 8 * i), u16(d, rec + 10 + 8 * i)) for i in range(n)]
    elif fmt == 0:
        n = u16(d, rec + 2)
        attr = u16(d, rec + 4)
        ent = [(u16(d, rec + 10 + 2 * i), attr) for i in range(n)]
    else:
        return None
    if not 0 < len(ent) <= 0x100:
        return None
    cells = set()
    for tile, attr in ent:
        bx, by = gfx_tiles.attr_block(attr)
        cells.update(gfx_tiles.block_cells(tile, bx, by))
    return fmt, len(ent), cells


def assets(d):
    total = set()
    for name, table, idx, why in ASSET_CHAINS:
        nodes = chain(d, table, idx)
        recs = []
        for a in nodes:
            r = u32(d, a + 4)
            if r not in recs:
                recs.append(r)
        cells, ents, bad = set(), 0, 0
        for r in recs:
            got = record_cells(d, r) if 0 < r < len(d) - 16 else None
            if got is None:
                bad += 1
                continue
            ents += got[1]
            cells |= got[2]
        total |= cells
        print(f"ASSET {name} table {table:06x} idx {idx:#x} nodes {len(nodes)} node_bytes {16 * len(nodes):#x}"
              f" records {len(recs)} not_records {bad} entries {ents} tile_cells {len(cells)} | {why}")
    base, off, why = ASSET_PAL
    print(f"ASSET palette base {base:06x} block {base + off:06x}+ {off:#x} bytes ({off // 32} rows) | {why}")
    print(f"ASSET total_tile_cells {len(total)} ({len(total) * 128} bytes of 16x16 4bpp art)")


def main():
    if sys.argv[1] == "--assets":
        d = open(sys.argv[2], "rb").read()
        print(f"# vs2 data {sys.argv[2]} sha1 {hashlib.sha1(d).hexdigest()}")
        assets(d)
        return
    src = open(sys.argv[1], "rb").read()
    dst = open(sys.argv[2], "rb").read()
    print(f"# vs2 {sys.argv[1]} sha1 {hashlib.sha1(src).hexdigest()}")
    print(f"# vsavj {sys.argv[2]} sha1 {hashlib.sha1(dst).hexdigest()}")
    hooks = []
    counts = {"INSERT": 0, "REPLACE": 0, "NEW": 0}
    for s in sites_of(src):
        size = ins_at(src, s).size
        head = f"SITE {s:06x} {txt(src, s)}"
        pre, post = anchors(src, dst, s, size, RADIUS, MIN, GAP)
        res = classify(src, dst, s, pre, post) if (pre and post) else None
        if res is None:
            pre2, post2 = anchors(src, dst, s, size, RADIUS2, MIN2, GAP2)
            r2 = classify(src, dst, s, pre2, post2) if (pre2 and post2) else None
            if r2 and r2[0] == "delete":
                res = r2
            else:
                twin = None
                if pre:   # the first vsavj instruction boundary at/after the anchor's end
                    end = s + pre[0] + WIN + pre[1]
                    twin = next(pc for pc, _, _ in stream(dst, end - 0x40, end + 0x10) if pc >= end)
                counts["NEW"] += 1
                tw = f"{twin:06x} {txt(dst, twin)}" if twin is not None else "none"
                print(f"{head} | NEW - - | twin {tw}")
                if twin is not None:
                    hooks.append(twin)
                continue
        op, n, nb, hook, k = res
        cls = "INSERT" if op == "delete" else "REPLACE"
        counts[cls] += 1
        extra = f" replacing {k}" if cls == "REPLACE" else ""
        print(f"{head} | {cls} {n} {nb:#x}{extra} | hook {hook:06x} {txt(dst, hook)}")
        hooks.append(hook)
    uniq = sorted(set(hooks))
    print(f"CLASSES INSERT {counts['INSERT']} REPLACE {counts['REPLACE']} NEW {counts['NEW']}")
    print(f"HOOKS {len(uniq)}")
    print("HOOKLIST " + ",".join(f"{h:x}" for h in uniq))


if __name__ == "__main__":
    main()
