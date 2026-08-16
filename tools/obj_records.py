#!/usr/bin/env python3
"""obj_records.py — walk a character's OBJ (sprite) records and inventory
the gfx tiles they reference.

Record format (decoded session 14 from the vsavj emitter chain
0x1ABC8 -> 0x1AC68 -> 0x1ADC6 -> 0x1AF9E; format-2 handler 0x1B234):

  format 2 (handler 0x1B234):
    +0 format.w, +2 budget.w (checked vs remaining d7), +4 count.w
    (entries = count+1), +6 cptr.l -> X/Y word-pair list, +10 entries
    of (tile.w, attr.w) — 4 bytes each.
  format 0 (handler 0x1AFC6) — DIFFERENT HEADER AND STRIDE:
    +0 format.w, +2 count.w (doubles as the budget check; `subq #1`
    BEFORE the dbra => entries = COUNT, not count+1), +4 attr.w (ONE
    attr for the whole record), +6 cptr.l, +10 entries of tile.w —
    2 BYTES each. (Session-14b corruption catch: the count+1 misread
    made the walker treat the NEXT record's format word as a tile.)
  (Session-14b lesson: treating format 0 as 4-byte entries remaps only
  every other tile — the character-select blink, playtest 2026-07-28.)

Emit semantics (the R2 answer, atlas character_tables.md):
  - tile.w is ABSOLUTE within a 64K-tile bank; written RAW to OBJ RAM.
  - bank = OBJ Y-word bits 13-14, OR'd in from object field +0x18
    (per-char init table: vsavj 0x282D4 / vsav2 0x27530, PC-relative =
    read via OPCODE space; slot-indexed).  tile_abs = bank<<16 | tile.
  - attr size bits: bx=(attr>>8&15)+1, by=(attr>>12&15)+1; block cell
    (dx,dy) uses tile (n & ~0xF) + (dy<<4) + ((n+dx) & 0xF)  — row
    stride 16 with within-row wrap, so any code remap must be 16-aligned
    to preserve block geometry.

Usage:
  obj_records.py <image.bin> --base 0xADDR --start 0xADDR --end 0xADDR
                 [--cptr-lo 0x100000] [--cptr-hi 0x400000] [--json out]

  image.bin  data-space image (records/anim live in data space)
  --base     ROM address of image[0] (0 for full images)
  --start/--end  the character's anim region (record pointers + records)
  --cptr-lo/hi   validity window for coordinate-list pointers

Prints the inventory: entries, unique expanded tiles, band clusters.
"""

import argparse
import hashlib
import json
import sys


def walk(dat, base, start, end, cptr_ok, sweep_lo=0x8000, sweep_hi=0xEEBB,
         sweep_allow=None, sweep_seen=None, ptr_allow=None, ptr_seen=None,
         ptr_rejected=None):
    """dat indexed by ROM address - base. Returns (tiles set, n_entries,
    n_records). sweep_lo/hi: the band-coherence window of the SWEEP pass
    (offset-computed records) — historically the Donovan/Jedah band; a
    tenant's own band for anyone else (14z-67 de-Donovanization).

    sweep_seen / sweep_allow (14z-74) make the SWEEP pass relocation-aware.
    The sweep is a heuristic — it scans every even offset for a record-shaped
    header — and its cptr test only asks "does this long land in an aux
    region?". After placement that question has a DIFFERENT answer for the
    same bytes, because the aux regions move: a 4-byte read at +6 that
    STRADDLES a relocated pointer can land inside the new aux window while
    the source's equivalent read fell outside it. Measured on Pyron
    (14z-74): 8 such straddles invented 11 records and 8 out-of-band tiles
    in the built image, with the underlying pointer correctly relocated —
    i.e. a verifier artifact, not a build defect. Passing the source's
    accepted sweep offsets as `sweep_allow` makes the built-image walk
    VERIFY the source's record structure instead of re-deriving it, which
    is what a src-vs-out parity check means in the first place.
    Offsets are relative to `start`.

    ptr_seen / ptr_allow (14z-92, GitHub #75) do the SAME for the POINTER
    pass, which 14z-74 left ungated. That pass is a heuristic too — it reads
    a 4-byte value at every even offset and dereferences it if the value
    falls inside [start,end) — and the SECOND predicate is the one that
    moves: after placement, "is this long inside the region?" has a
    different answer for the same bytes, because the REGION moves. Measured
    on merged Huitzil: the bytes 00 42 1e 94 at region offset 0x1D160
    STRADDLE one entry's attr and the next entry's tile inside a real
    fmt-2 record, and read as 0x00421E94 — byte-identical in source and
    build, i.e. never relocated, i.e. not a pointer. The source window
    [0x245872,0x264072) and every solo placement exclude it; the merged
    placement [0x41A7E0,0x438FE0) contains it, so the pass dereferenced it
    to offset 0x76B4, where relocated bytes happen to read fmt=0 count=67
    with a cptr that lands in the moved aux window. That ONE phantom record
    was +1 record, +67 entries and 34 out-of-band tiles.
    `ptr_seen` is a dict {ptr_off: tgt_off} the SOURCE walk fills; passing
    it back as `ptr_allow` makes the built-image walk accept a candidate
    only at a pointer offset the source accepted AND only if it resolves to
    the same target offset — so the pass VERIFIES the relocation instead of
    re-deriving the structure, and a pointer relocated to the WRONG target
    is caught, which a bare count comparison can miss.
    `ptr_rejected`, if a list, collects the (ptr_off, tgt_off) candidates
    that VALIDATED as records and were then turned away by the allow-map —
    i.e. the placement coincidences themselves, not merely every in-window
    longword. That count is worth printing rather than hiding: it is 0 on
    a build where nothing coincides and 1 on merged Huitzil."""
    tiles, entries, records = set(), 0, 0
    seen = set()
    for a in range(start, end - 4, 2):
        i = a - base
        v = int.from_bytes(dat[i:i + 4], "big")
        if not (start <= v < end) or v in seen:
            continue
        o = v - base
        fmt = int.from_bytes(dat[o:o + 2], "big")
        cptr = int.from_bytes(dat[o + 6:o + 10], "big")
        if fmt > 0x20 or fmt % 2 or not cptr_ok(cptr):
            continue
        if fmt == 0:
            count = int.from_bytes(dat[o + 2:o + 4], "big")
            attr = int.from_bytes(dat[o + 4:o + 6], "big")
            if not (0 < count <= 0x100):
                continue
            # 14z-67: a real record's entries lie INSIDE the region — a
            # shape-matching tail pointer otherwise reads past the end
            # (zeros in a source image; NEIGHBORING PLACED CONTENT in a
            # built one — the H verify false-record)
            if o + 10 + 2 * count > end - base:
                continue
            ent = [(int.from_bytes(dat[o + 10 + 2*k:o + 12 + 2*k], "big"),
                    attr) for k in range(count)]
        else:
            budget = int.from_bytes(dat[o + 2:o + 4], "big")
            count = int.from_bytes(dat[o + 4:o + 6], "big")
            if not (0 < count + 1 <= budget <= 0x100):
                continue
            if o + 10 + 4 * (count + 1) > end - base:
                continue
            ent = [(int.from_bytes(dat[o + 10 + 4*k:o + 12 + 4*k], "big"),
                    int.from_bytes(dat[o + 12 + 4*k:o + 14 + 4*k], "big"))
                   for k in range(count + 1)]
        # The allow-map is consulted AFTER validation on purpose: what is
        # worth counting is the candidates that would otherwise have been
        # ACCEPTED as records — the placement coincidences — not every
        # in-window longword the source never endorsed either. Rejecting
        # here also leaves `seen` untouched, so a later, legitimate
        # pointer to the same target is still free to claim it.
        if ptr_allow is not None and ptr_allow.get(a - start) != v - start:
            if ptr_rejected is not None:
                ptr_rejected.append((a - start, v - start))
            continue
        seen.add(v)
        if ptr_seen is not None:
            ptr_seen[a - start] = v - start
        records += 1
        for t, at in ent:
            bx = ((at >> 8) & 15) + 1
            by = ((at >> 12) & 15) + 1
            entries += 1
            for dy in range(by):
                for dx in range(bx):
                    tiles.add((t & ~0xF) + (dy << 4) + ((t + dx) & 0xF))
    # SWEEP pass (session 14z-11): records reached by OFFSET COMPUTATION
    # (the aux/+0x64 chain — e.g. the electrocute X-ray overlays) have no
    # in-region pointer and the pass above misses them: their band words
    # stayed unremapped and their tiles uninventoried (the round-31
    # X-ray garble). Scan every even offset as a candidate head with the
    # same strict validation.
    # CORRECTED 14z-92 (#75): this comment used to claim "the header+cptr
    # joint constraint keeps false positives negligible in record-zone
    # data". That is not a property of the data — it is a property of the
    # PLACEMENT ADDRESS, and it is re-rolled by every allocator change.
    # Measured on merged Huitzil: 200 candidate heads are in-window in the
    # BUILT image and were not in the source, and the count is the SAME on
    # merged7 (where one of them validated as a record and aborted the
    # build) and on merged8 (where none did). The surface does not shrink;
    # only whether a candidate lands on validating bytes changes. Both
    # heuristic passes therefore verify the source's structure
    # (sweep_allow / ptr_allow) rather than trusting a false-positive rate
    # that nobody re-measures.
    for a in range(start, end - 10, 2):
        if a in seen:
            continue
        if sweep_allow is not None and (a - start) not in sweep_allow:
            continue
        o = a - base
        fmt = int.from_bytes(dat[o:o + 2], "big")
        cptr = int.from_bytes(dat[o + 6:o + 10], "big")
        if fmt > 0x20 or fmt % 2 or not cptr_ok(cptr):
            continue
        if fmt == 0:
            count = int.from_bytes(dat[o + 2:o + 4], "big")
            attr = int.from_bytes(dat[o + 4:o + 6], "big")
            if not (0 < count <= 0x100):
                continue
            if o + 10 + 2 * count > end - base:
                continue
            ent = [(int.from_bytes(dat[o + 10 + 2*k:o + 12 + 2*k], "big"),
                    attr) for k in range(count)]
        else:
            budget = int.from_bytes(dat[o + 2:o + 4], "big")
            count = int.from_bytes(dat[o + 4:o + 6], "big")
            if not (0 < count + 1 <= budget <= 0x100):
                continue
            if o + 10 + 4 * (count + 1) > end - base:
                continue
            ent = [(int.from_bytes(dat[o + 10 + 4*k:o + 12 + 4*k], "big"),
                    int.from_bytes(dat[o + 12 + 4*k:o + 14 + 4*k], "big"))
                   for k in range(count + 1)]
        # sweep-only strictness: real overlay records are small-piece,
        # modest-budget, band-coherent — reject pseudo-headers
        if fmt != 0:
            if not (int.from_bytes(dat[o + 2:o + 4], "big") <= 0x40):
                continue
        if not ent:
            continue
        _band = sum(1 for _t, _ in ent if sweep_lo <= _t <= sweep_hi)
        if _band * 2 < len(ent):
            continue
        if any(((_a >> 8) & 15) + 1 > 8 or ((_a >> 12) & 15) + 1 > 8
               for _, _a in ent):
            continue
        seen.add(a)
        if sweep_seen is not None:
            sweep_seen.append(a - start)
        records += 1
        for t, at in ent:
            bx = ((at >> 8) & 15) + 1
            by = ((at >> 12) & 15) + 1
            entries += 1
            for dy in range(by):
                for dx in range(bx):
                    tiles.add((t & ~0xF) + (dy << 4) + ((t + dx) & 0xF))
    return tiles, entries, records


def clusters(tiles, gap=0x400):
    ts = sorted(tiles)
    if not ts:
        return []
    out = [[ts[0], ts[0]]]
    for t in ts[1:]:
        if t - out[-1][1] > gap:
            out.append([t, t])
        else:
            out[-1][1] = t
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--base", type=lambda x: int(x, 0), required=True)
    ap.add_argument("--start", type=lambda x: int(x, 0), required=True)
    ap.add_argument("--end", type=lambda x: int(x, 0), required=True)
    ap.add_argument("--cptr-lo", type=lambda x: int(x, 0), default=0x100000)
    ap.add_argument("--cptr-hi", type=lambda x: int(x, 0), default=0x400000)
    ap.add_argument("--sweep-lo", type=lambda x: int(x, 0), default=0x8000,
                    help="sweep-pass band-coherence window (default = the "
                         "historical Donovan/Jedah band; pass the tenant's "
                         "own band for anyone else, 14z-67)")
    ap.add_argument("--sweep-hi", type=lambda x: int(x, 0), default=0xEEBB)
    ap.add_argument("--json")
    args = ap.parse_args()

    dat = open(args.image, "rb").read()
    # repo convention: every analysis tool prints the SHA-1 of what it reads
    # (added 14z-83 — this was the one gfx tool without it, so a walk's
    # provenance was unrecorded in its own output)
    print(f"read {args.image} sha1 {hashlib.sha1(dat).hexdigest()}")
    inreg = (args.start, args.end)

    def cptr_ok(p):
        return (args.cptr_lo <= p < args.cptr_hi
                and not (inreg[0] <= p < inreg[1]))

    tiles, entries, records = walk(dat, args.base, args.start, args.end,
                                   cptr_ok, args.sweep_lo, args.sweep_hi)
    print(f"records {records}, entries {entries}, "
          f"unique expanded tiles {len(tiles)}")
    for lo, hi in clusters(tiles):
        n = sum(1 for t in tiles if lo <= t <= hi)
        print(f"  band 0x{lo:04X}-0x{hi:04X}: {n} tiles "
              f"({n * 128 // 1024} KB, extent 0x{hi - lo + 1:X})")
    if args.json:
        json.dump(sorted(tiles), open(args.json, "w"))
        print(f"wrote {args.json}")


if __name__ == "__main__":
    main()
