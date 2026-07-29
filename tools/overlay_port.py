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

    # ---- slice + pointer relocation (two-part split) -----------------
    sl = bytearray(vs2[SLICE_LO:SLICE_HI])
    n_delta = n_sel = 0
    warn = collections.Counter()
    for i in range(0, len(sl) - 4, 2):
        v = int.from_bytes(sl[i:i + 4], "big")
        if SLICE_LO <= v < SLICE_HI:
            sl[i:i + 4] = reloc(v).to_bytes(4, "big")
            n_delta += 1
        elif v in SELECT_MAP:
            sl[i:i + 4] = SELECT_MAP[v].to_bytes(4, "big")
            n_sel += 1
        elif 0x2A63F0 <= v < 0x2AA000:
            warn["select-unported"] += 1
    print(f"slice: {n_delta} intra-longs rebased (split at "
          f"0x{SPLIT:06X}), {n_sel} select-mapped, warnings {dict(warn)}")

    # ---- record walk over the (virtually) placed slice ---------------
    # placed addr -> offset into `sl` (part A and part B are contiguous
    # slices of the same buffer; only their placed bases differ)
    def sloff(v):
        if PLACE_A <= v < PLACE_A + LEN_A:
            return v - PLACE_A
        if PLACE_B <= v < PLACE_B + LEN_B:
            return LEN_A + (v - PLACE_B)
        return None

    def cptr_ok(c):
        return 0x100000 <= c < 0x400000

    # discovery: every relocated long in `sl` that lands in a placed
    # window is a candidate record start; validate fmt-aware in place
    recs, skipped_a = {}, 0
    for i in range(0, len(sl) - 4, 2):
        v = int.from_bytes(sl[i:i + 4], "big")
        o = sloff(v)
        if o is None or v in recs:
            continue
        got, ska = walk_via_offset(sl, o, v, cptr_ok)
        skipped_a += ska
        if got is not None:
            recs[v] = got
    fmtc = collections.Counter(f for f, _, _ in recs.values())
    print(f"records: {len(recs)} {dict(fmtc)}; fmtA skipped {skipped_a}")

    # cptr fixes: for every record whose cptr still aims at vs2 data
    # space, content-match the X/Y list into vsavj's data image; misses
    # are PORTED into the free tail of Jedah's strip area after the
    # slice (the slice is 24KB into a 44KB budget).
    tail = bytearray()
    tail_map = {}
    TAIL_AT = PLACE_A + LEN_A
    n_cfix = n_cport = n_ckeep = 0
    for v, (fmt, cptr, ents) in recs.items():
        if cptr is None:
            continue
        o = sloff(v)
        if PLACE_A <= cptr < PLACE_A + LEN_A or \
                PLACE_B <= cptr < PLACE_B + LEN_B:
            n_ckeep += 1        # already relocated intra-slice pointer
            continue
        if not (0x100000 <= cptr < 0x400000):
            continue
        npairs = len(ents)
        lst = bytes(vs2[cptr:cptr + 4 * npairs])
        j = vandata.find(lst)
        if j != -1:
            sl[o + 6:o + 10] = (j + 0x100000).to_bytes(4, "big")
            n_cfix += 1
        else:
            if lst not in tail_map:
                tail_map[lst] = len(tail)
                tail += lst
            addr = TAIL_AT + tail_map[lst]
            sl[o + 6:o + 10] = addr.to_bytes(4, "big")
            n_cport += 1
    assert TAIL_AT + len(tail) <= GAP_A_HI, "tail overflows gap A"
    print(f"cptrs: {n_ckeep} intra-slice, {n_cfix} content-matched, "
          f"{n_cport} ported to tail ({len(tail)}B at 0x{TAIL_AT:06X})")

    # ---- tile placement ----------------------------------------------
    # census of needed (drawn) codes with block geometry
    need = {}
    for v, (fmt, cptr, ents) in recs.items():
        for eoff, stored, attr in ents:
            d = drawn_code(fmt, stored)
            a = attr if attr is not None else int.from_bytes(
                sl[eoff + 2:eoff + 4], "big")
            bx = ((a >> 8) & 15) + 1
            by = ((a >> 12) & 15) + 1
            need.setdefault((d, bx, by), []).append((v, eoff, fmt))
    cells_needed = set()
    for (d, bx, by) in need:
        for dy in range(by):
            for dx in range(bx):
                cells_needed.add((d & ~0xF) + (dy << 4) + ((d + dx) & 0xF))
    print(f"blocks: {len(need)}, unique cells {len(cells_needed)}")

    # free bank-1 positions: Jedah's dead overlay drawn codes
    def j_cptr_ok(c):
        return 0x100000 <= c < 0x400000
    jrecs, _ = walk_records(vandata, 0x100000, 0x267112, 0x2748F0,
                            j_cptr_ok)
    KEEP = {0x272FB0, 0x272FDA}   # legacy-read records — codes stay live
    jfree = set()
    for v, (fmt, cptr, ents) in jrecs.items():
        if v in KEEP:
            continue
        for eoff, stored, attr in ents:
            d = drawn_code(fmt, stored)
            a = attr if attr is not None else int.from_bytes(
                vandata[eoff + 2:eoff + 4], "big")
            bx = ((a >> 8) & 15) + 1
            by = ((a >> 12) & 15) + 1
            for dy in range(by):
                for dx in range(bx):
                    jfree.add((d & ~0xF) + (dy << 4) + ((d + dx) & 0xF))
    for v, (fmt, cptr, ents) in jrecs.items():
        if v not in KEEP:
            continue
        for eoff, stored, attr in ents:
            d = drawn_code(fmt, stored)
            jfree.discard(d)
    # exclude positions already claimed by select_tiles / effect placements
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

    # 16-aligned shelf packing of needed blocks into free positions:
    # greedy row-fit — a block (bx,by) needs bx consecutive columns on
    # by consecutive rows at the same column window (row stride 16).
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

    # rewrite stored codes in the slice
    n_rw = 0
    for key, entlist in need.items():
        base = place.get(key)
        if base is None:
            continue
        d, bx, by = key
        for v, eoff, fmt in entlist:
            new_drawn = base
            stored = (new_drawn - 0x3800) & 0xFFFF if fmt in (4, 6, 8) \
                else new_drawn
            sl[eoff:eoff + 2] = stored.to_bytes(2, "big")
            n_rw += 1
    print(f"tile words rewritten: {n_rw}")

    # tile pairs [src_code, dst_code] (bank-1 codes; the gfx step adds
    # the 0x10000 group-A offset — same convention as select_tiles.json)
    pairs = []
    for (d, bx, by), base in place.items():
        for dy in range(by):
            for dx in range(bx):
                s_ = (d & ~0xF) + (dy << 4) + ((d + dx) & 0xF)
                t_ = (base & ~0xF) + (dy << 4) + ((base + dx) & 0xF)
                pairs.append([s_, t_])
    # dedup (blocks sharing cells)
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
                    new = reloc(v2)
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
    segA = bytes(sl[:LEN_A]) + bytes(tail)
    segB = bytes(sl[LEN_A:])
    (out / "overlay_segA.bin").write_bytes(segA)
    (out / "overlay_segB.bin").write_bytes(segB)
    json.dump({"segments": [
                   {"at": f"{PLACE_A:06X}", "path": "overlay_segA.bin",
                    "len": len(segA)},
                   {"at": f"{PLACE_B:06X}", "path": "overlay_segB.bin",
                    "len": len(segB)}],
               "pokes": sites}, (out / "overlay_patch.json").open("w"),
              indent=1)
    json.dump(pairs, (out / "overlay_tiles.json").open("w"))
    print(f"emitted to {out}: segA {len(segA)}B @0x{PLACE_A:06X}, "
          f"segB {len(segB)}B @0x{PLACE_B:06X}, {len(sites)} pokes, "
          f"{len(pairs)} tile pairs")


if __name__ == "__main__":
    main()
