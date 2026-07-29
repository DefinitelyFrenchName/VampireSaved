#!/usr/bin/env python3
"""overlay_port.py — M2b stage 7: port the vs2 companion-overlay data
zone (tables/strips/streams/records) into Jedah's strip area and repoint
Jedah's per-char code immediates to it (topology B, STATE session 14q).

Mechanism (measured; docs/GOTCHAS.md "companion overlay draws the HOST's
records"): the in-match overlay sub-objects walk per-char record-pointer
strips. Strip TABLE bases are hardcoded immediates in per-char code;
Jedah's code drives the overlay for slot 0x0F (always Donovan on this
build) but resolves HIS tables — his darkness art animates where the
sword-drag/statue belong.

Surgery:
  1. Place the vs2 zone slice [0x2A0426,0x2A63F0) at 0x267112 (Jedah's
     strip/stream area [0x267112,0x271CE8) — record area untouched).
     Intra-slice longs rebased; the six select-family records map to
     their in-place-replaced Jedah addresses (select_port RECORDS).
  2. Rewrite record tile codes (format-aware; fmt4/6/8 draw stored +
     0x3800 — handler decode session 14q) to freshly placed bank-1
     positions (Jedah's dead overlay tile indices + bank-1 padding),
     emitting overlay_tiles.json [src_grpA_idx, dst_grpA_idx] pairs.
  3. Poke Jedah-code table immediates (opcode space; re-encrypted by
     patch_prg's code path) to the rebased table addresses. Site list
     is data-driven (--sites json) so gate-failing sites can be
     removed one by one — the masked legacy gate arbitrates select-path
     sharing.

Record cptrs into the vs2 global pool are content-matched into vsavj's
pool (same-value class #3); misses are reported (NOT silently ported).

Usage:
  overlay_port.py <romdir> --ops-vsavj ops.bin [--emit --out DIR]
                  [--sites sites.json]
Prints SHA-1 of all inputs. Deterministic; rerunnable.
"""

import argparse
import collections
import hashlib
import json
import zipfile
from pathlib import Path

SLICE_LO, SLICE_HI = 0x2A0426, 0x2A63F0
# Split placement (session 14q): the pre-match legacy paths (attract,
# select wheel) READ scattered spans of Jedah's strip area (measured
# watchpoint clusters 0x267112 / 0x267F32-7A / 0x26810E / 0x269032-40 /
# 0x270048-EC — lossy sampler, ±0x40 margins, the masked legacy gate is
# the arbiter). The slice is split at 0x2A4A48 (above the max
# self-relative table reach 0x2A4A46, measured) into two contiguous
# parts placed in the two big read-free gaps; the ported-cptr tail
# rides behind part A.
SPLIT = 0x2A4A48
# Placement v3 (session 14q): Jedah's own in-match ANIM area — the only
# provably-dead-in-this-build space (slot 0x0F always runs Donovan,
# including the attract demo). Attributed bounds from vanilla-demo
# cursor/record sampling: streams 0x248D5C-0x25004E, records
# 0x25570C-0x2601EC. The earlier strip-area placement (0x269xxx)
# broke legacy replays: the shared MUSIC-SEQUENCE POOL interleaves that
# zone (02_demitri masked diverged at 891/1726 with sound-driver RAM
# deltas — see STATE).
PLACE_A = 0x248D80          # inside his stream core
PLACE_B = 0x2557B0          # inside his record cluster A
GAP_A_HI, GAP_B_HI = 0x250100, 0x260200
DELTA_A = PLACE_A - SLICE_LO
DELTA_B = PLACE_B - SPLIT
LEN_A = SPLIT - SLICE_LO
LEN_B = SLICE_HI - SPLIT
JZONE_HI = 0x271CE8


def reloc(v):
    """slice-internal address -> placed address"""
    return v + (DELTA_A if v < SPLIT else DELTA_B)

VALUE_MAP = {
    0x267112: 0x2A0426, 0x2671C6: 0x2A04FA, 0x2671E6: 0x2A051E,
    0x267224: 0x2A055C, 0x267284: 0x2A05BC, 0x2672AA: 0x2A05E2,
    0x26752A: 0x2A0862, 0x2675AA: 0x2A08E2, 0x26762A: 0x2A0962,
    0x26772A: 0x2A0A62, 0x26775A: 0x2A0A96,
}
SELECT_MAP = {
    0x2A63F0: 0x271CE8, 0x2A657E: 0x27221A, 0x2A7F68: 0x273766,
    0x2A7F86: 0x273AAC, 0x2A6416: 0x2720FA, 0x2A8CF8: 0x274642,
}
POOL_LO, POOL_HI = 0x300000, 0x361000
PAD_LO, PAD_HI = 0x3640, 0x3800     # bank-1 padding run (group A idx +0x10000)


def load_be(z, names):
    raw = b"".join(z.read(n) for n in names)
    img = bytearray(len(raw))
    img[0::2] = raw[1::2]
    img[1::2] = raw[0::2]
    return raw, img


def walk_records(img, base, lo, hi, cptr_ok):
    """Format-aware record walk over [lo,hi) of img (indexed by addr-base).
    Returns {addr: (fmt, cptr|None, [(entry_off, stored, attr|None)])}
    entry_off is img-relative; drawn code = stored (+0x3800 for fmt 4/6/8).
    fmt4 has no cptr and a single packed tile long; fmtA is a composite
    sub-dispatch and is skipped (counted)."""
    recs, skipped_a = {}, 0
    for i in range(lo - base, hi - base - 4, 2):
        v = int.from_bytes(img[i:i + 4], "big")
        if not (lo <= v < hi) or v in recs:
            continue
        o = v - base
        fmt = int.from_bytes(img[o:o + 2], "big")
        if fmt > 0x0A or fmt % 2:
            continue
        if fmt == 0x0A:
            skipped_a += 1
            continue
        if fmt in (0, 6):
            cnt = int.from_bytes(img[o + 2:o + 4], "big")
            if not (0 < cnt <= 0x100):
                continue
            attr = int.from_bytes(img[o + 4:o + 6], "big")
            cptr = int.from_bytes(img[o + 6:o + 10], "big")
            if not cptr_ok(cptr):
                continue
            ents = [(o + 10 + 2 * k,
                     int.from_bytes(img[o + 10 + 2 * k:o + 12 + 2 * k],
                                    "big"), attr) for k in range(cnt)]
        elif fmt in (2, 8):
            bud = int.from_bytes(img[o + 2:o + 4], "big")
            cnt = int.from_bytes(img[o + 4:o + 6], "big")
            if not (0 < cnt + 1 <= bud <= 0x100):
                continue
            cptr = int.from_bytes(img[o + 6:o + 10], "big")
            if not cptr_ok(cptr):
                continue
            ents = [(o + 10 + 4 * k,
                     int.from_bytes(img[o + 10 + 4 * k:o + 12 + 4 * k],
                                    "big"),
                     int.from_bytes(img[o + 12 + 4 * k:o + 14 + 4 * k],
                                    "big")) for k in range(cnt + 1)]
        else:  # fmt 4: budget.w count.w tile_attr.l xy.l — no cptr
            bud = int.from_bytes(img[o + 2:o + 4], "big")
            cnt = int.from_bytes(img[o + 4:o + 6], "big")
            if not (0 < cnt <= bud <= 0x100):
                continue
            cptr = None
            ents = [(o + 6, int.from_bytes(img[o + 6:o + 8], "big"),
                     int.from_bytes(img[o + 8:o + 10], "big"))]
        recs[v] = (fmt, cptr, ents)
    return recs, skipped_a


def walk_via_offset(img, o, addr, cptr_ok):
    """validate/parse one record at buffer offset o (placed addr `addr`).
    Returns ((fmt, cptr, ents), skippedA_count) with ents offsets into img,
    or (None, skippedA_count)."""
    fmt = int.from_bytes(img[o:o + 2], "big")
    if fmt > 0x0A or fmt % 2:
        return None, 0
    if fmt == 0x0A:
        return None, 1
    if fmt in (0, 6):
        cnt = int.from_bytes(img[o + 2:o + 4], "big")
        if not (0 < cnt <= 0x100):
            return None, 0
        attr = int.from_bytes(img[o + 4:o + 6], "big")
        cptr = int.from_bytes(img[o + 6:o + 10], "big")
        if not cptr_ok(cptr):
            return None, 0
        ents = [(o + 10 + 2 * k,
                 int.from_bytes(img[o + 10 + 2 * k:o + 12 + 2 * k], "big"),
                 attr) for k in range(cnt)]
    elif fmt in (2, 8):
        bud = int.from_bytes(img[o + 2:o + 4], "big")
        cnt = int.from_bytes(img[o + 4:o + 6], "big")
        if not (0 < cnt + 1 <= bud <= 0x100):
            return None, 0
        cptr = int.from_bytes(img[o + 6:o + 10], "big")
        if not cptr_ok(cptr):
            return None, 0
        ents = [(o + 10 + 4 * k,
                 int.from_bytes(img[o + 10 + 4 * k:o + 12 + 4 * k], "big"),
                 int.from_bytes(img[o + 12 + 4 * k:o + 14 + 4 * k], "big"))
                for k in range(cnt + 1)]
    else:  # fmt 4
        bud = int.from_bytes(img[o + 2:o + 4], "big")
        cnt = int.from_bytes(img[o + 4:o + 6], "big")
        if not (0 < cnt <= bud <= 0x100):
            return None, 0
        cptr = None
        ents = [(o + 6, int.from_bytes(img[o + 6:o + 8], "big"),
                 int.from_bytes(img[o + 8:o + 10], "big"))]
    return (fmt, cptr, ents), 0


def drawn_code(fmt, stored):
    return (stored + 0x3800) & 0xFFFF if fmt in (4, 6, 8) else stored


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("romdir")
    ap.add_argument("--ops-vsavj", required=True)
    ap.add_argument("--emit", action="store_true")
    ap.add_argument("--out")
    ap.add_argument("--sites", help="poke-site list json (from "
                    "--emit-sites); default all discovered sites")
    ap.add_argument("--emit-sites", help="write discovered poke sites here")
    args = ap.parse_args()
    R = Path(args.romdir)

    z2 = zipfile.ZipFile(R / "vsav2.zip")
    raw2, vs2 = load_be(z2, [f"vs2j.{n:02d}" for n in range(3, 11)])
    print(f"vs2 prg sha1 {hashlib.sha1(raw2).hexdigest()}")
    za = zipfile.ZipFile(R / "vsav.zip")
    rawv, vandata = load_be(
        za, ["vm3.05a", "vm3.06a", "vm3.07b", "vm3.08a", "vm3.09b",
             "vm3.10b"])
    print(f"vsav data sha1 {hashlib.sha1(rawv).hexdigest()}")
    opsJ = Path(args.ops_vsavj).read_bytes()
    print(f"vsavj opcodes sha1 {hashlib.sha1(opsJ).hexdigest()}")

    # ---- STRUCTURAL CLOSURE v5: object-granular heap port ------------
    # The overlay streams reference records across the WHOLE per-char
    # zone (select/win records at 0x2A65xx-0x2A8Fxx, extras at
    # 0x2ABxxx), so a fixed slice cannot bound the port. Instead the
    # closure walk (tables -> streams/strips -> records -> cptr lists)
    # collects OBJECTS; each is copied into a relocatable heap laid
    # over Jedah's dead anim areas, with every discovered pointer (and
    # every table entry, which is SELF-RELATIVE and must be recomputed
    # against placed addresses) rewritten through the placement map.
    # Stream node grammar (measured at the table targets): 8-byte
    # (tag.l, ptr.l) nodes; tag = (duration.b, flags.b, param.w); a
    # node is accepted iff its ptr validates as a record, a sub-stream,
    # or a select-mapped record. Termination is data-driven (first
    # invalid node) — over-walk yields harmless extra objects, never a
    # corrupting rewrite.
    ZONE_LO, ZONE_HI = 0x2A0426, 0x2AC000
    ROOTS = [0x2A04FA, 0x2A051E, 0x2A055C, 0x2A05BC, 0x2A0862,
             0x2A08E2, 0x2A0962, 0x2A0A62, 0x2A0A96]

    def in_zone(v):
        return ZONE_LO <= v < ZONE_HI

    def cptr_ok(c):
        return 0x100000 <= c < 0x400000

    def parse_rec(a):
        if not in_zone(a) or a % 2:
            return None
        got, _ = walk_via_offset(vs2, a, a, cptr_ok)
        return got

    def rec_size(fmt, ents):
        if fmt in (0, 6):
            return 10 + 2 * len(ents)
        if fmt in (2, 8):
            return 10 + 4 * len(ents)
        return 14  # fmt 4: fmt.w budget.w count.w tile_attr.l xy.l

    recs, tables, streams, strips = {}, {}, {}, {}
    # per-object pointer sites: {obj_addr: [(off_in_obj, target_addr)]}
    obj_ptrs = {}

    def visit_record(a):
        if a in recs:
            return True
        got = parse_rec(a)
        if got is None:
            return False
        recs[a] = got
        return True

    def visit_stream(a, depth=0):
        # NOTE (session 14q handoff): nodes are (tag.l, ptr.l) at
        # stride 8 here, but the engine's stepper family also walks
        # 0x10- and 0x18-stride node forms — the stride is a property
        # of the OBJECT's stepper class (engine 0x15030-0x15080 lea
        # variants), not derivable from the data (a longest-run
        # heuristic mis-strides real 8-streams and corrupts them).
        # The stepper-class -> table mapping is the remaining decode
        # before the closure is complete.
        if a in streams or depth > 12 or not in_zone(a) or a % 2:
            return a in streams
        streams[a] = 0
        sites = []
        o, n = a, 0
        while in_zone(o + 8):
            ptr = int.from_bytes(vs2[o + 4:o + 8], "big")
            if ptr == 0:
                o += 8
                n += 1
                continue
            ok = (visit_record(ptr) or ptr in SELECT_MAP
                  or visit_stream(ptr, depth + 1))
            if not ok:
                break
            sites.append((o + 4 - a, ptr))
            o += 8
            n += 1
            if n > 0x400:
                break
        if n == 0:
            del streams[a]
            return False
        streams[a] = 8 * n + 8
        obj_ptrs[a] = sites
        return True

    def visit_strip(a):
        if a in strips or not in_zone(a) or a % 2:
            return a in strips
        strips[a] = 0
        sites = []
        o, n = a, 0
        while in_zone(o + 4):
            v = int.from_bytes(vs2[o:o + 4], "big")
            if visit_record(v) or v in SELECT_MAP:
                sites.append((o - a, v))
                o += 4
                n += 1
                continue
            break
        if n == 0:
            del strips[a]
            return False
        strips[a] = 4 * n + 4
        obj_ptrs[a] = sites
        return True

    def visit_whdr_strip(a):
        """grammar 4: leading word, then a bare long-pointer array at
        a+2 (measured at the 0x2A0862-family table targets)"""
        if a in strips or not in_zone(a) or a % 2:
            return a in strips
        strips[a] = 0
        sites = []
        o, n = a + 2, 0
        while in_zone(o + 4):
            v = int.from_bytes(vs2[o:o + 4], "big")
            if visit_record(v) or v in SELECT_MAP:
                sites.append((o - a, v))
                o += 4
                n += 1
                continue
            break
        if n == 0:
            del strips[a]
            return False
        strips[a] = 2 + 4 * n + 4
        obj_ptrs[a] = sites
        return True

    for T in ROOTS:
        entries, bound, k = [], ZONE_HI, 0
        while T + 2 * k + 2 <= min(bound, ZONE_HI) and k < 0x100:
            off = int.from_bytes(vs2[T + 2 * k:T + 2 * k + 2], "big")
            soff = off - 0x10000 if off >= 0x8000 else off
            tgt = T + soff
            if not in_zone(tgt):
                break
            entries.append(tgt)
            if tgt > T:
                bound = min(bound, tgt)
            k += 1
        tables[T] = entries
        for tgt in entries:
            (visit_stream(tgt) or visit_strip(tgt)
             or visit_whdr_strip(tgt) or visit_record(tgt))

    fmtc = collections.Counter(f for f, _, _ in recs.values())
    print(f"closure: {len(tables)} tables "
          f"({sum(len(e) for e in tables.values())} entries), "
          f"{len(streams)} streams, {len(strips)} strips, "
          f"{len(recs)} records {dict(fmtc)}")

    # cptr lists as objects (content-matched first, ported if missing)
    cptr_objs = {}
    for a, (fmt, cptr, ents) in recs.items():
        if cptr is None or in_zone(cptr):
            continue
        if not (0x100000 <= cptr < 0x400000):
            continue
        lst = bytes(vs2[cptr:cptr + 4 * len(ents)])
        j = vandata.find(lst)
        if j == -1 and cptr not in cptr_objs:
            cptr_objs[cptr] = 4 * len(ents)
    print(f"cptr lists: {len(cptr_objs)} need porting")

    # ---- heap packing -------------------------------------------------
    HEAPS = [[0x248D80, 0x250100], [0x2557B0, 0x260200]]
    MAP = {}

    def heap_alloc(size):
        for h in HEAPS:
            if h[0] + size <= h[1]:
                a = h[0]
                h[0] = (h[0] + size + 1) & ~1
                return a
        raise SystemExit(f"heap overflow allocating {size}")

    # a safe terminator object for dead table entries: an immediately
    # invalid stream node (zero tag) — never a self-pointer into the
    # table (a walker landing there would read table words as nodes)
    TERM = heap_alloc(8)
    # tables first (poke targets), then streams/strips/records/cptrs
    for T in ROOTS:
        MAP[T] = heap_alloc(2 * len(tables[T]))
    for a, sz in sorted(streams.items()):
        MAP[a] = heap_alloc(sz)
    for a, sz in sorted(strips.items()):
        MAP[a] = heap_alloc(sz)
    for a, (fmt, cptr, ents) in sorted(recs.items()):
        MAP[a] = heap_alloc(rec_size(fmt, ents))
    for a, sz in sorted(cptr_objs.items()):
        MAP[a] = heap_alloc(sz)
    used = [f"{h[0] - lo:#x}/{hi - lo:#x}"
            for h, (lo, hi) in zip(HEAPS, [(0x248D80, 0x250100),
                                           (0x2557B0, 0x260200)])]
    print(f"heap usage: A {used[0]}, B {used[1]}")

    def mapped(v):
        if v in MAP:
            return MAP[v]
        if v in SELECT_MAP:
            return SELECT_MAP[v]
        return None

    # ---- materialize the heap image ----------------------------------
    # two segment buffers, offsets relative to their heap bases
    segs = {0x248D80: bytearray(HEAPS[0][0] - 0x248D80),
            0x2557B0: bytearray(HEAPS[1][0] - 0x2557B0)}

    def seg_of(addr):
        for base, buf in segs.items():
            if base <= addr < base + len(buf):
                return base, buf
        raise SystemExit(f"address {addr:#x} outside heap segments")

    def write_at(addr, data):
        base, buf = seg_of(addr)
        buf[addr - base:addr - base + len(data)] = data

    # tables: recompute self-relative entries against placed addresses
    for T in ROOTS:
        nt = MAP[T]
        # verbatim copy first: over-walked "entries" may be neighboring
        # data misread as offsets — fabricating words there corrupts it.
        # Only entries whose targets VALIDATED in the closure are
        # recomputed; the rest keep their pristine words (their runtime
        # cursors would be garbage relative to the new base, but ids
        # that never validated are ids the closure believes unused —
        # gate/playtest arbitrates).
        out_words = bytearray(vs2[T:T + 2 * len(tables[T])])
        live = 0
        for k, tgt in enumerate(tables[T]):
            m = mapped(tgt)
            if m is None:
                continue
            d = (m - nt) & 0xFFFF
            out_words[2 * k:2 * k + 2] = d.to_bytes(2, "big")
            live += 1
        print(f"  table {T:06X}: {live}/{len(tables[T])} entries live")
        write_at(nt, out_words)
    # streams/strips: raw copy + pointer rewrites
    for a in list(streams) + list(strips):
        sz = streams.get(a) or strips[a]
        blob = bytearray(vs2[a:a + sz])
        for off, tgt in obj_ptrs[a]:
            m = mapped(tgt)
            if m is not None:
                blob[off:off + 4] = m.to_bytes(4, "big")
        write_at(MAP[a], blob)
    # records: copy, fix cptr (heap tail/content-match), tiles later
    n_cfix = n_cport = n_ckeep = 0
    for a, (fmt, cptr, ents) in recs.items():
        sz = rec_size(fmt, ents)
        blob = bytearray(vs2[a:a + sz])
        if cptr is not None:
            if in_zone(cptr):
                m = mapped(cptr)
                blob[6:10] = (m if m is not None else cptr).to_bytes(4, "big")
                n_ckeep += 1
            elif 0x100000 <= cptr < 0x400000:
                lst = bytes(vs2[cptr:cptr + 4 * len(ents)])
                j = vandata.find(lst)
                if j != -1:
                    blob[6:10] = (j + 0x100000).to_bytes(4, "big")
                    n_cfix += 1
                else:
                    blob[6:10] = MAP[cptr].to_bytes(4, "big")
                    n_cport += 1
        write_at(MAP[a], blob)
    for a, sz in cptr_objs.items():
        write_at(MAP[a], vs2[a:a + sz])
    print(f"cptrs: {n_ckeep} intra-zone, {n_cfix} content-matched, "
          f"{n_cport} heap-ported")

    # ---- tile placement (heap-record entries) ------------------------
    need = {}
    for a, (fmt, cptr, ents) in recs.items():
        for eoff, stored, attr in ents:
            d = drawn_code(fmt, stored)
            at = attr if attr is not None else int.from_bytes(
                vs2[eoff + 2:eoff + 4], "big")
            bx = ((at >> 8) & 15) + 1
            by = ((at >> 12) & 15) + 1
            need.setdefault((d, bx, by), []).append((a, eoff - a, fmt))
    cells_needed = set()
    for (d, bx, by) in need:
        for dy in range(by):
            for dx in range(bx):
                cells_needed.add((d & ~0xF) + (dy << 4) + ((d + dx) & 0xF))
    print(f"blocks: {len(need)}, unique cells {len(cells_needed)}")

    def j_cptr_ok(c):
        return 0x100000 <= c < 0x400000
    jrecs, _ = walk_records(vandata, 0x100000, 0x267112, 0x2748F0,
                            j_cptr_ok)
    # also Jedah's in-match anim-area records (0x248D5C-0x2601EC — the
    # very area the heap overwrites): their drawn bank-1 codes are dead
    # once the area is unreachable (slot 0x0F always runs Donovan)
    jrecs2, _ = walk_records(vandata, 0x100000, 0x248000, 0x260200,
                             j_cptr_ok)
    jrecs.update(jrecs2)
    KEEP = {0x272FB0, 0x272FDA}
    jfree = set()
    for v, (fmt, cptr, ents) in jrecs.items():
        if v in KEEP:
            continue
        for eoff, stored, attr in ents:
            d = drawn_code(fmt, stored)
            at = attr if attr is not None else int.from_bytes(
                vandata[eoff + 2:eoff + 4], "big")
            bx = ((at >> 8) & 15) + 1
            by = ((at >> 12) & 15) + 1
            for dy in range(by):
                for dx in range(bx):
                    jfree.add((d & ~0xF) + (dy << 4) + ((d + dx) & 0xF))
    for v, (fmt, cptr, ents) in jrecs.items():
        if v not in KEEP:
            continue
        for eoff, stored, attr in ents:
            jfree.discard(drawn_code(fmt, stored))
    for claimed in ("build/donovan6/select_tiles.json",
                    "build/donovan/select_tiles.json"):
        cp = Path(claimed)
        if cp.exists():
            for s_, d_ in json.loads(cp.read_text()):
                jfree.discard(d_)
    pad = set(range(PAD_LO, PAD_HI))
    freelist = sorted(jfree | pad)
    print(f"free bank-1 positions: {len(jfree)} dead-Jedah + "
          f"{len(pad)} padding = {len(freelist)}")

    free = set(freelist)
    place = {}
    def fits(base, bx, by):
        for dy in range(by):
            for dx in range(bx):
                c = (base & ~0xF) + (dy << 4) + ((base + dx) & 0xF)
                if c not in free or (base & 0xF) + dx > 0xF:
                    return False
        return True
    for key in sorted(need, key=lambda k: (-k[2], -k[1], k[0])):
        d, bx, by = key
        for base in freelist:
            if base in place.values():
                continue
            if fits(base, bx, by):
                place[key] = base
                for dy in range(by):
                    for dx in range(bx):
                        free.discard((base & ~0xF) + (dy << 4)
                                     + ((base + dx) & 0xF))
                break
        else:
            print(f"  !! no fit for block {d:04X} {bx}x{by}")
    print(f"placed {len(place)}/{len(need)} blocks")

    n_rw = 0
    for key, entlist in need.items():
        base = place.get(key)
        if base is None:
            continue
        for a, rel_off, fmt in entlist:
            stored = (base - 0x3800) & 0xFFFF if fmt in (4, 6, 8) else base
            ha = MAP[a] + rel_off
            hb, hbuf = seg_of(ha)
            hbuf[ha - hb:ha - hb + 2] = stored.to_bytes(2, "big")
            n_rw += 1
    print(f"tile words rewritten: {n_rw}")

    pairs = []
    for (d, bx, by), base in place.items():
        for dy in range(by):
            for dx in range(bx):
                s_ = (d & ~0xF) + (dy << 4) + ((d + dx) & 0xF)
                t_ = (base & ~0xF) + (dy << 4) + ((base + dx) & 0xF)
                pairs.append([s_, t_])
    pairs = sorted({tuple(p) for p in pairs})
    print(f"tile pairs: {len(pairs)}")

    # ---- poke sites --------------------------------------------------
    sites = []
    for vj, v2 in VALUE_MAP.items():
        pat = vj.to_bytes(4, "big")
        j = opsJ.find(pat)
        while j != -1:
            if j % 2 == 0:
                op = int.from_bytes(opsJ[j - 2:j], "big")
                # imm-carrying forms: movea.l #,(207C..2E7C), move.l #
                # (2xxx with imm mode), pea abs.l (4879), cmpi.l (0CB9),
                # lea abs.l (41F9-4DF9 odd regs) — accept the measured
                # dominant forms and anything whose opcode low nibble
                # suggests an immediate/absolute long operand.
                if op in (0x207C, 0x227C, 0x247C, 0x267C, 0x287C, 0x2A7C,
                          0x2C7C, 0x4879) or (op & 0xF1FF) == 0x41F9:
                    if v2 not in MAP:
                        j = opsJ.find(pat, j + 1)
                        continue
                    new = MAP[v2]
                    sites.append({"addr": j, "op": f"{op:04X}",
                                  "old": f"{vj:06X}", "new": f"{new:06X}"})
            j = opsJ.find(pat, j + 1)
    print(f"poke sites discovered: {len(sites)}")
    bysite = collections.Counter(s['old'] for s in sites)
    print("  by value:", dict(bysite))

    if args.emit_sites:
        Path(args.emit_sites).write_text(json.dumps(sites, indent=1))
        print(f"wrote {args.emit_sites}")
    if args.sites:
        sites = json.loads(Path(args.sites).read_text())
        print(f"using {len(sites)} sites from {args.sites}")

    if not args.emit:
        print("(dry run; --emit to write fragments)")
        return

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    segA = bytes(segs[0x248D80])
    segB = bytes(segs[0x2557B0])
    (out / "overlay_segA.bin").write_bytes(segA)
    (out / "overlay_segB.bin").write_bytes(segB)
    json.dump({"segments": [
                   {"at": "248D80", "path": "overlay_segA.bin",
                    "len": len(segA)},
                   {"at": "2557B0", "path": "overlay_segB.bin",
                    "len": len(segB)}],
               "pokes": sites}, (out / "overlay_patch.json").open("w"),
              indent=1)
    json.dump(pairs, (out / "overlay_tiles.json").open("w"))
    print(f"emitted to {out}: segA {len(segA)}B @0x{PLACE_A:06X}, "
          f"segB {len(segB)}B @0x{PLACE_B:06X}, {len(sites)} pokes, "
          f"{len(pairs)} tile pairs")


if __name__ == "__main__":
    main()
