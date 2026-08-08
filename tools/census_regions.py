#!/usr/bin/env python3
"""census_regions.py — the three structural censuses over an extraction's
code-kind regions (14z-66 mechanisms, promoted to a tool for the D4
step-2 Pyron early warning; STATE 14z-66 watch item).

Census 1 — [[data_in_code]] candidates: a small DATA table embedded in
a CODE region. If the region is placed in the crypt hole its bytes are
stored re-encrypted, so runtime DATA READS of the table see garbage
(the FG capture-pose crash class, 3 paid debugging arcs). TWO reader
shapes are scanned, both starting from the same table pointer:

  A. INDEXED (the original shape):
    lea (d16,pc),An        (w  & 0xF1FF) == 0x41FA
    move.{b,w,l} (An,Xn.w) (w2 & 0x0038) == 0x0030, reg == An,
                           size field in {1,2,3}
     — the reader must IMMEDIATELY follow the lea.

  B. POST-INCREMENT walk (added 14z-69; the shape that let vs2's fleet
     param stream through the census while the region carried a live
     embedded table — docs/project/gotchas.md):
    lea (d16,pc),An        as above
    ... any code, as long as An is not REDEFINED ...
    move.{b,w,l} (An)+,<ea>   (w2 & 0x0038) == 0x0018, reg == An
     — the reader may be ARBITRARILY FAR from the lea and in another
       basic block. The measured ground-truth case (vs2 0x6D206 ->
       table 0x6D868) has its reader 0x3E bytes later, inside a local
       subroutine reached by bsr, which is why an "immediately after"
       rule can never see it. The scan therefore walks forward to the
       end of the region and stops only if An is redefined by another
       `lea`/`movea` into the same register — the cheap dataflow rule
       that keeps this from matching an unrelated later walk.

with the lea target landing INSIDE a code-kind region of the same
extraction. Every such site needs a [[data_in_code]] manifest row
before that region may be crypt-placed. Findings carry `shape`
("indexed" / "postinc") so the two can be told apart in expectations.

Census 3 — pcrel DATA-pointer escapes (added 14z-69): `lea (d16,pc),An`
whose target leaves the region. Nothing else in the toolchain sees these
(see scan_pcrel_data_escapes), so a relocated region silently reads its
table from whatever now sits at PC+disp. Reported, never auto-fixed.

Census 2 — [[pcrel_escape_fix]] escapes: word-form pcrel branches
(bra/bsr/Bcc.w: (w & 0xF000) == 0x6000, low byte 0) whose target lies
OUTSIDE the region span. Invisible to the sibling oracle (both
siblings preserve spacing) and unrewritable in place; a cloned or
relocated region executing one branches into unrelated bytes (the
x02592a anim freeze, the x026142 air-dash death). Regions with escapes
need a [[pcrel_escape_fix]] row (trampoline pad) or their escapes
individually accounted for.

ALL sweeps are linear pattern scans over code bytes: data words can
pattern-match (false positives are possible, silence is meaningful,
hits need triage). The instrument is ground-truthed against the known
Huitzil inventory in tests/test_census_regions.sh before its numbers
are trusted for any other tenant.

Usage:
  census_regions.py <extract_dir> [--manifest build/manifest/x.toml]
                    [--json out.json]

Prints per-region findings and totals; --manifest marks findings
already covered by data_in_code/pcrel_escape_fix rows. Exit 0 always
(census, not gate — wrap in a test to freeze expectations).
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _minitoml import loads as toml_loads  # noqa: E402


def in_dead(off, dead):
    return any(a <= off < b for a, b in dead)


def _redefines_an(w, an):
    """does this opcode word load a NEW value into address register An?"""
    if (w & 0xF1C0) == 0x41C0 and ((w >> 9) & 7) == an:       # lea <ea>,An
        return True
    if (w & 0xC1C0) in (0x2040, 0x3040) and ((w >> 9) & 7) == an:
        return True                                            # movea.l/.w
    return False


# EA modes that read THROUGH An, i.e. uses of the lea'd table pointer
_EA_MODES = {0x0018: "postinc", 0x0028: "indexed-far", 0x0030: "indexed-far"}


def scan_deferred_reader(blob, i, an, dead):
    """Find the first read that uses An as a base AFTER the lea at `i`,
    without An being redefined first. Returns (offset, shape) or None.

    Deliberately NOT limited to the next instruction. Both measured
    shapes need this: the post-increment walk sits 0x3E bytes away
    inside a bsr subroutine, and the two indexed readers at vs2 0x6CD5E
    / 0x6CFDC sit 2-3 instructions later (`lea; move.b $382(a4),d0;
    lsl.w #2,d0; move.w (a0,d0.w),d1`). The original "reader immediately
    follows the lea" rule saw none of them.
    """
    j = i + 4
    while j + 2 <= len(blob):
        w = int.from_bytes(blob[j:j + 2], "big")
        shape = _EA_MODES.get(w & 0x0038)
        if shape and (w >> 12) in (1, 2, 3) and (w & 7) == an \
                and not in_dead(j, dead):
            return j, shape
        if _redefines_an(w, an):        # the pointer is no longer our table
            return None
        j += 2
    return None


def scan_data_in_code(name, blob, src, dead, code_spans, raw_from=None):
    """lea(d16,pc),An + an INDEXED read (An,Xn.w) or a POST-INCREMENT
    walk (An)+, with the lea target inside a code region."""
    hits = []
    for i in range(0, len(blob) - 8, 2):
        if in_dead(i, dead):
            continue
        w = int.from_bytes(blob[i:i + 2], "big")
        if (w & 0xF1FF) != 0x41FA:
            continue
        an = (w >> 9) & 7
        disp = int.from_bytes(blob[i + 2:i + 4], "big", signed=True)
        tgt = src + i + 2 + disp
        host = next((n for n, (lo, hi) in code_spans.items()
                     if lo <= tgt < hi), None)
        if host is None:
            continue
        w2 = int.from_bytes(blob[i + 4:i + 6], "big")
        indexed = ((w2 & 0x0038) == 0x0030 and (w2 & 7) == an
                   and (w2 >> 12) in (1, 2, 3))
        if indexed:
            shape, reader_off = "indexed", i
        else:
            found = scan_deferred_reader(blob, i, an, dead)
            if found is None:
                continue
            reader_off, shape = found
        hit = {"reader": src + i, "table": tgt, "table_host": host,
               "reader_old_hex": blob[i:i + 8].hex(), "shape": shape}
        # 14z-69i: a table inside its OWN region's raw-emitted tail needs no
        # manifest row — those bytes are written unencrypted, so the data
        # read returns them verbatim. That IS the fix, so it counts as
        # covered (verified byte-for-byte by verify_pcrel_data.py).
        hit["raw_emitted"] = (raw_from is not None and host == name
                              and (tgt - src) >= raw_from)
        if shape != "indexed":
            # the LEA is still the site to rewrite; record where the read
            # actually happens so triage can see how far away it is.
            hit["walk_reader"] = src + reader_off
            hit["walk_distance"] = reader_off - i
        hits.append(hit)
    return hits


def scan_pcrel_data_escapes(name, blob, src, dead, all_spans):
    """Census 3 (14z-69) — `lea (d16,pc),An` whose target leaves the
    region that contains it.

    THE BLIND SPOT THIS CLOSES. Such a lea forms a DATA POINTER, and
    nothing else sees it:
      * census 1 skips it (its target has no code-region host, or a
        DIFFERENT region's — either way not this region's own bytes);
      * census 2 only scans branch opcodes (bra/bsr/Bcc.w);
      * extract_char.py's pcrel_refs sweep only collects `jsr/jmp
        (d16,PC)` and `jsr/jmp (d8,PC,Xn)`.
    So the displacement is copied VERBATIM, and a relocated region
    computes PC+disp at its NEW address — i.e. target + region_delta,
    which holds the intended bytes only if they were copied along with
    the region. When the target lies outside the region (this census),
    they were not. Whether that HARMS anything depends on the bytes now
    at that address, so this census reports; `tools/verify_pcrel_data.py`
    decides, by comparing them against the source table in a built
    image. gen_donovan_patch.py's far-pcrel trampoline explicitly
    covers CODE targets only and notes a far pcrel DATA read "would
    need its data copied near instead (no such case yet)". This is that
    case: vs2's row-8 machine reads its fleet param stream via
    `lea $6D868(pc),a3` at 0x6D206, and 0x6D868 lies OUTSIDE the ported
    region x06cac0 (0x6CAC0..0x6D6C0).
    """
    hits = []
    r_lo, r_hi = src, src + len(blob)
    for i in range(0, len(blob) - 4, 2):
        if in_dead(i, dead):
            continue
        w = int.from_bytes(blob[i:i + 2], "big")
        if (w & 0xF1FF) != 0x41FA:
            continue
        an = (w >> 9) & 7
        disp = int.from_bytes(blob[i + 2:i + 4], "big", signed=True)
        tgt = src + i + 2 + disp
        if r_lo <= tgt < r_hi:
            continue                      # inside: census 1's business
        host = next((n for n, (lo, hi) in all_spans.items()
                     if lo <= tgt < hi), None)
        if host is not None:
            # the target is inside ANOTHER extracted region (code or data);
            # that region is placed too and the generator rewrites the
            # displacement against its placement — measured on the shipped
            # hui11 image, where region x022400's `lea $27FD8(pc),a0`
            # sites all came out as `lea $CCC48(pc),a0`. Not a finding.
            continue
        hits.append({"lea": src + i, "target": tgt, "an": an,
                     "target_host": None, "distance": tgt - r_hi})
    return hits


def scan_escapes(name, blob, src, dead):
    """word-form pcrel branches leaving the region (generator's sweep)."""
    escapes = []
    i = 0
    while i + 4 <= len(blob):
        w = int.from_bytes(blob[i:i + 2], "big")
        if (w & 0xF000) == 0x6000 and (w & 0xFF) == 0:
            if not in_dead(i, dead):
                disp = int.from_bytes(blob[i + 2:i + 4], "big", signed=True)
                tgt = src + i + 2 + disp
                if not (src <= tgt < src + len(blob)):
                    escapes.append({"site": src + i, "opcode": w,
                                    "target": tgt})
            i += 4
            continue
        i += 2
    return escapes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("extract_dir")
    ap.add_argument("--manifest", help="tenant manifest toml; marks "
                    "findings already covered by rows")
    ap.add_argument("--json", help="write findings JSON")
    args = ap.parse_args()

    meta = json.load(open(os.path.join(args.extract_dir, "regions.json")))
    regions = meta["regions"]
    covered_readers, covered_escape_regions = set(), set()
    if args.manifest:
        man = toml_loads(open(args.manifest).read())
        covered_readers = {int(str(dc["reader"]), 0)
                           for dc in man.get("data_in_code", [])}
        covered_escape_regions = {pf["region"]
                                  for pf in man.get("pcrel_escape_fix", [])}

    code_spans = {n: (v["src"], v["src"] + v["len"])
                  for n, v in regions.items() if v["kind"] == "code"}
    # census 3 needs EVERY region, not just code ones: a pcrel data pointer
    # into a DATA region is relocated with it and rewritten by the
    # generator, so it is not a finding (verified on the shipped image).
    all_spans = {n: (v["src"], v["src"] + v["len"]) for n, v in regions.items()}
    out = {"src_set": meta.get("src_set"), "char": meta.get("char"),
           "code_regions": sorted(code_spans),
           "data_in_code": [], "escapes": {}, "pcrel_data_escapes": []}
    tot_dc = tot_dc_unc = tot_esc = tot_pde = 0
    for name, (lo, hi) in sorted(code_spans.items(), key=lambda kv: kv[1]):
        v = regions[name]
        blob = open(os.path.join(args.extract_dir,
                                 f"region_{name}.bin"), "rb").read()
        assert len(blob) == v["len"], f"{name}: bin/len mismatch"
        dead = [tuple(d) for d in v.get("dead", [])]

        dc = scan_data_in_code(name, blob, lo, dead, code_spans,
                               v.get("raw_from"))
        for h in dc:
            h["region"] = name
            h["covered"] = (h["reader"] in covered_readers
                            or h.get("raw_emitted", False))
            out["data_in_code"].append(h)
            tot_dc += 1
            if not h["covered"]:
                tot_dc_unc += 1
            walk = (f" walk@{h['walk_reader']:#08x} (+{h['walk_distance']:#x})"
                    if h["shape"] == "postinc" else "")
            print(f"  data_in_code[{h['shape']}] {name}+{h['reader']-lo:#06x}: "
                  f"reader {h['reader']:#08x} -> table {h['table']:#08x} "
                  f"(in {h['table_host']}){walk}"
                  + ("  [covered: raw-emitted tail]" if h.get("raw_emitted")
                     else "  [covered]" if h["covered"] else "  [UNCOVERED]"))

        pde = scan_pcrel_data_escapes(name, blob, lo, dead, all_spans)
        for h in pde:
            h["region"] = name
            out["pcrel_data_escapes"].append(h)
            tot_pde += 1
            where = "outside EVERY extracted region"
            print(f"  pcrel_data_escape {name}+{h['lea']-lo:#06x}: "
                  f"lea {h['lea']:#08x} -> a{h['an']} = {h['target']:#08x} "
                  f"({where}, {h['distance']:+#x} past region end)"
                  f"  [displacement preserved verbatim -> verify the "
                  f"target bytes in the built image]")

        esc = scan_escapes(name, blob, lo, dead)
        if esc:
            uniq = sorted({e["target"] for e in esc})
            cov = name in covered_escape_regions
            out["escapes"][name] = {"count": len(esc),
                                    "unique_targets": uniq, "covered": cov}
            tot_esc += len(esc)
            print(f"  escapes {name}: {len(esc)} sites -> "
                  f"{len(uniq)} unique targets "
                  f"({', '.join(hex(t) for t in uniq[:8])}"
                  f"{'...' if len(uniq) > 8 else ''})"
                  + ("  [covered]" if cov else "  [UNCOVERED]"))

    print(f"census: {tot_dc} data_in_code sites ({tot_dc_unc} uncovered), "
          f"{tot_esc} escape sites in {len(out['escapes'])} regions, "
          f"{tot_pde} pcrel data-pointer escapes "
          f"over {len(code_spans)} code regions")
    if args.json:
        json.dump(out, open(args.json, "w"), indent=1)
        print(f"wrote {args.json}")


if __name__ == "__main__":
    main()
