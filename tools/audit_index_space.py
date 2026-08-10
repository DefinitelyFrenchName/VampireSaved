#!/usr/bin/env python3
"""audit_index_space.py — THE OUT-OF-RANGE INDEX SWEEP (14z-76).

The defect class, named in 14z-75 after Pyron's Cosmo Disruption crash:

    vsavj's dispatch tables are SHORTER than vs2's. A ported character
    carries vs2's indices verbatim, so any index past the end of vsavj's
    table dispatches into whatever follows it — usually the table's own
    bytes or the next routine — and the jmp lands on garbage.

Pyron's Cosmo sub-state index 81 hit a vsavj table with 80 entries and jumped
into the table itself: illegal instruction, watchdog reset. `test_variant_dispatch.sh`
sweeps for the *aliased variant row* shape; nothing swept for this one, and
`docs/NEXT_SESSION.md` flagged it as worth writing before the fourth tenant.

WHAT THIS MEASURES. For every `jmp (d8,PC,Dn.w)` word-displacement table in
vsavj it derives the ENTRY COUNT, finds vs2's twin table, and derives that
count too. Any table where **vs2 is longer than vsavj** is a site where a
ported index can overrun. That is the risk inventory; it is a property of the
two ROMs, not of any build, so it is the same list for every tenant.

HOW A TABLE'S LENGTH IS DERIVED — "a jump table ENDS WHERE CODE BEGINS".
TWO independent bounds, both structural, and the count is their minimum:

  (a) a target cannot land inside the table, so N <= min(displacement)/2;
  (b) a table cannot overlap another dispatcher's code, so N <= the distance
      to the next dispatcher anchor after the base.

Bound (a) alone is NOT enough and assuming it was is how the first version of
this sweep missed the very defect it was written for. vsavj's Cosmo table has
80 entries but every one of them points into a handler cluster far beyond the
table (nearest target base+0x212), so (a) permits 265 — while (b) stops it
exactly at the `move.w (d8,PC,Dn),Dn / jmp` pair that begins 160 bytes in.

A table with neither bound available is reported as NOT JUDGED rather than
guessed at. Silent truncation reads as coverage (docs/GOTCHAS.md).

UNITS — the danger window is in ENTRY numbers, and the dispatcher's register
is NOT. The idiom is `move.b <sub-state>,d0 / add.w d0,d0 / move.w (d8,PC,
d0.w),d1`, so the register holds entry*2. Breakpointing a dispatcher and
comparing its d0 against a window from this table will read entries 40 and 41
as "80 and 82, out of range for an 80-entry table" — which is exactly the
false alarm 14z-76 raised for a minute. HALVE the register first.

Usage:
    python3 tools/audit_index_space.py <vsavj_op.bin> <vsav2_op.bin>
            [--min-gap 1] [--json out.json]

Exit 0 always for the plain inventory; --expect-known checks that the known
Cosmo table is still found (the sweep's own positive control).
"""
import argparse
import json
import struct
import sys

JMP_PCIX = b"\x4e\xfb"


def _u16(img, off):
    return struct.unpack_from(">H", img, off)[0]


def dispatcher_anchors(img):
    """Sorted addresses where a pc-indexed dispatcher's CODE starts.

    The idiom is `move.w (d8,PC,Dn.w),Dm` (0x303B/0x323B/...) immediately
    followed by `jmp (d8,PC,Dm.w)` (0x4EFB). The anchor is the move.w when it
    is present, else the jmp itself — a table may not run into either.
    """
    out = []
    a = img.find(JMP_PCIX)
    while a != -1:
        if a % 2 == 0:
            anchor = a
            if a >= 4 and (img[a - 4] & 0xF0) == 0x30 and img[a - 3] == 0x3B:
                anchor = a - 4              # the move.w that feeds it
            out.append(anchor)
        a = img.find(JMP_PCIX, a + 1)
    return sorted(set(out))


def table_len(img, base, anchors, cap=4096):
    """Entry count of the word-displacement table at `base`, or 0 if unbounded.

    N = min( min(disp)/2 , distance to the next dispatcher anchor ). See the
    module docstring: bound (a) alone is far too loose on real tables.
    """
    anchors = sorted(anchors)        # the binary search below requires it, and
    nxt = None                       # a caller passing an unsorted list must
    lo, hi = 0, len(anchors)         # not silently get a wrong count
    while lo < hi:                                   # first anchor > base
        mid = (lo + hi) // 2
        if anchors[mid] > base:
            hi = mid
        else:
            lo = mid + 1
    if lo < len(anchors):
        nxt = anchors[lo]
    if nxt is None:
        return 0                                     # NOT JUDGED
    n = min((nxt - base) // 2, cap)
    if n < 1:
        return 0
    for i in range(n):                               # apply bound (a) inside it
        d = _u16(img, base + 2 * i)
        if d < 2:
            n = min(n, i)
            break
        n = min(n, d // 2)
    return n


def tables(img):
    """All (jmp_addr, base, n_entries) for the simple pc-indexed idiom."""
    anchors = dispatcher_anchors(img)
    out = []
    a = img.find(JMP_PCIX)
    while a != -1:
        if a % 2 == 0:
            ext = _u16(img, a + 2)
            if not (ext & 0x0700):                  # no scaling / long index
                base = a + 2 + (ext & 0xFF)
                if base + 4 < len(img):
                    n = table_len(img, base, anchors)
                    if n >= 4:
                        out.append((a, base, n))
        a = img.find(JMP_PCIX, a + 1)
    return out


def _all(img, pat):
    out, i = [], img.find(pat)
    while i != -1:
        out.append(i)
        i = img.find(pat, i + 1)
    return out


def find_twin(vj, vs2, jmp_addr):
    """vs2's dispatcher for the same site.

    Same contract as tools/audit_variant_dispatch.py: unique context match
    first, ORDINAL correspondence when the context is not unique (vsav ships
    byte-identical dispatcher copies, and demanding uniqueness silently skips
    tables — that is how 14z-75's first defect was missed).
    """
    for n in (0x40, 0x30, 0x20, 0x14, 0x0C):
        if jmp_addr - n < 0:
            continue
        ctx = vj[jmp_addr - n:jmp_addr + 4]
        hj, h2 = _all(vj, ctx), _all(vs2, ctx)
        if not h2:
            continue
        if len(hj) == len(h2) == 1:
            return h2[0] + n
        if len(hj) == len(h2) and (jmp_addr - n) in hj:
            return h2[hj.index(jmp_addr - n)] + n
    return None


def _shape(img, jmp_addr, k=8):
    """The last k MNEMONICS before the dispatcher, operands discarded.

    A byte-exact context match fails whenever the surrounding code holds a
    relocated branch displacement — which is most of the engine, and is why
    the first run of this sweep left 53 of 110 tables unjudged INCLUDING the
    one it was written to find. Mnemonics survive relocation; operands do not.
    """
    import capstone
    md = capstone.Cs(capstone.CS_ARCH_M68K,
                     capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_040)
    for start in range(jmp_addr - 4 * k - 8, jmp_addr - 2, 2):
        if start < 0:
            continue
        ins = list(md.disasm(img[start:jmp_addr], start))
        if ins and ins[-1].address + ins[-1].size == jmp_addr and len(ins) >= k:
            return tuple(i.mnemonic for i in ins[-k:])
    return None


def shape_index(img, dispatchers):
    """{signature: [jmp_addr, ...]} in address order."""
    out = {}
    for a in dispatchers:
        s = _shape(img, a)
        if s:
            out.setdefault(s, []).append(a)
    return out


def find_twin_by_shape(sj, s2, jmp_addr):
    """Ordinal correspondence within an identical instruction-shape class.

    Same doctrine as the byte-context matcher: when a shape is not unique the
    k-th occurrence in vsavj maps to the k-th in vs2. If the two images do not
    even agree on how many dispatchers carry the shape, refuse rather than
    guess — an unjudged table is reported, never silently dropped.
    """
    for sig, addrs in sj.items():
        if jmp_addr in addrs:
            other = s2.get(sig)
            if other and len(other) == len(addrs):
                return other[addrs.index(jmp_addr)]
            return None
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vsavj")
    ap.add_argument("vsav2")
    ap.add_argument("--min-gap", type=int, default=1,
                    help="report only tables where vs2 exceeds vsavj by this many entries")
    ap.add_argument("--json")
    ap.add_argument("--expect-known", action="store_true",
                    help="fail unless the known Cosmo table (vsavj 80 entries) is found")
    args = ap.parse_args()

    vj = open(args.vsavj, "rb").read()
    v2 = open(args.vsav2, "rb").read()

    a2 = dispatcher_anchors(v2)
    vj_tables = tables(vj)
    v2_tables = tables(v2)
    sj = shape_index(vj, [t[0] for t in vj_tables])
    s2 = shape_index(v2, [t[0] for t in v2_tables])
    rows, untwinned, by_shape = [], [], 0
    for jmp, base, n in vj_tables:
        tj = find_twin(vj, v2, jmp)
        if tj is None:
            tj = find_twin_by_shape(sj, s2, jmp)
            if tj is not None:
                by_shape += 1
        if tj is None:
            untwinned.append((jmp, base, n))
            continue
        ext = _u16(v2, tj + 2)
        if ext & 0x0700:
            untwinned.append((jmp, base, n))
            continue
        b2 = tj + 2 + (ext & 0xFF)
        n2 = table_len(v2, b2, a2)
        rows.append({"jmp": jmp, "base": base, "n_vsavj": n,
                     "vs2_jmp": tj, "vs2_base": b2, "n_vs2": n2,
                     "gap": n2 - n})

    risky = sorted([r for r in rows if r["gap"] >= args.min_gap],
                   key=lambda r: -r["gap"])

    print(f"jmp (d8,PC,Dn.w) tables in vsavj : {len(vj_tables)}")
    print(f"  twinned in vs2                 : {len(rows)}"
          f"  ({by_shape} of them by instruction shape)")
    print(f"  no twin located (NOT JUDGED)   : {len(untwinned)}")
    for jmp, base, n in untwinned:
        print(f"      unjudged: jmp {jmp:#08x} table {base:#08x} "
              f"({n} entries in vsavj)")
    print(f"\nTABLES WHERE vs2 IS LONGER — a ported index can overrun "
          f"(gap >= {args.min_gap}): {len(risky)}\n")
    print(f"  {'vsavj jmp':>10}  {'table':>9}  {'vsavj':>6}  {'vs2':>5}  "
          f"{'gap':>4}   danger ENTRY window")
    print("  (entries, not register values — the dispatcher holds entry*2)")
    for r in risky:
        print(f"  {r['jmp']:#010x}  {r['base']:#09x}  {r['n_vsavj']:6d}  "
              f"{r['n_vs2']:5d}  {r['gap']:4d}   "
              f"[{r['n_vsavj']}..{r['n_vs2'] - 1}]")

    if args.json:
        json.dump({"all": rows, "risky": risky}, open(args.json, "w"), indent=1)
        print(f"\nwrote {args.json}")

    if args.expect_known:
        # the Cosmo table: vsavj 80 entries, and vs2's twin longer than 81.
        hit = [r for r in risky if r["n_vsavj"] == 80 and r["n_vs2"] > 81]
        if not hit:
            print("\nFAIL: the known Cosmo table (vsavj 80 entries, vs2 > 81) "
                  "was NOT found — the sweep is not measuring what it claims")
            return 1
        for r in hit:
            print(f"\nok: known Cosmo-class table found at {r['base']:#09x} "
                  f"(vsavj {r['n_vsavj']}, vs2 {r['n_vs2']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
