#!/usr/bin/env python3
"""audit_type_stamps.py — census of extended object-TYPE stamp sites,
type comparisons and type-byte readers across the tenants' ported spans.

WHY (14z-82). The merged obj_hook union gives a multi-owner type ONE table
entry, routing every tenant into tenant-0's copy (the merged Huitzil vec3,
STATE 14z-81b). The fix renumbers the TYPE NUMBERS in non-first tenants'
copies of the stamp immediates — which is only sound if every place a
family type is WRITTEN or CONSULTED is known. This tool is that census,
static half. It scans the SOURCE opcode view (the ported bytes before
per-tenant reconciliation — the reconciler never touches these immediates)
and maps every hit into each tenant's regions via extract/regions.json,
keyed by SOURCE address, because region NAMES differ per tenant for the
same span (hui x057456 == pyron code — 14z-82).

Hit classes:
  stamp_l_ind   move.l #$01xxTTss,(An)      — THE REWRITE CLASS (opcode-
  stamp_l_d16   move.l #$01xxTTss,(d16,An)    anchored; TT at imm byte +2)
  stamp_l_post  move.l #$01xxTTss,(An)+
  stamp_l_pre   move.l #$01xxTTss,-(An)
  imm_l_other   a $01xxTTss longword NOT anchored by one of the four forms
                above (after any opcode or bare) — TRIAGE, never rewritten
  stamp_w_d16   move.w #imm,(d16,An) with d16 in {2,3} or (imm>>8) in family
  stamp_b_d16   move.b #imm,(d16,An) with d16 in {2,3} and imm byte in family
  cmp_b/w/l     cmpi.{b,w,l} whose immediate matches a family value:
                .b: imm in family; .w: imm in family (a plain type word) OR
                (imm>>8) in family (the +0x02 TTss word view); .l: a full
                $01xxTTss header. EA mode and displacement reported.
  reader        move.b/move.w/tst.b/tst.w reading (2,An)/(3,An) — reported
                only inside FAMILY REGIONS (regions holding a family stamp
                or a family handler), with the two following opcode words
                raw, so a table-index-by-own-type shape can be spotted.

NOT COVERED STATICALLY (dynamic census: tests/audit_type_writes.sh):
  register-sourced writes (move.b Dn,(2,An)), computed immediates, movem,
  and any header composed at runtime. A type stamped only by such a path
  is INVISIBLE here — which is why the dynamic writer-PC census gates the
  generator change, not this scan alone.

Controls (the list_type_census.py lesson: a census that cannot see what it
is looking for reads exactly like a clean result):
  --expect  (default ON for the 0x5E542 family): the six known immediate
            sites MUST appear in the rewrite class, else FAIL.
  negative: vs2 0x0697B8 / 0x090FF4 (family stamps in unported spans) must
            map to NO tenant, else the region model drifted.

Usage:
  python3 tools/audit_type_stamps.py <src_opcodes.bin> \
      --regions build/m5_wide/extract/regions.json \
      --regions build/hui29/extract/regions.json \
      --regions build/pyron20/extract/regions.json \
      [--family 0x5E542:114-120] [--family 0x54470:59-75] \
      [--toml out.toml] [--verify build/manifest/type_stamps.toml] \
      [--no-expect]

Prints the SHA-1 of every input it reads. Exit 0 = census clean (controls
pass; with --verify, no drift). Exit 1 = a control failed or drift.
"""

import argparse
import hashlib
import json
import sys
from pathlib import Path

# the known rewrite-class sites for the 0x5E542 family (114-120), measured
# 14z-81b/82 — the --expect positive control
EXPECT_5E542 = {
    0x08A2D6: 119,  # x088512+0x1DC4
    0x08A5C2: 116,  # x088512+0x20B0
    0x08A64A: 119,  # x088512+0x2138
    0x08ACE0: 117,  # x088512+0x27CE  (the merged-Huitzil crasher)
    0x057492: 115,  # hui x057456+0x3C, imm $0100730B (nonzero ss)
    0x05946A: 118,  # hui x057456+0x2014 / pyron code+0x1FAA
}
# family stamps that live in spans NO tenant ports — the negative control
EXPECT_UNPORTED = (0x0697B8, 0x090FF4, 0x00B63C)

DEFAULT_FAMILIES = ("0x5E542:114-120", "0x54470:59-75")


def sha1(p):
    return hashlib.sha1(Path(p).read_bytes()).hexdigest()


def parse_family(spec):
    site, rng = spec.split(":")
    lo, hi = rng.split("-")
    return int(site, 0), int(lo, 0), int(hi, 0)


def load_tenants(paths):
    """[(tenant_label, {region_name: (src, len, kind)})] — label from the
    build dir name; regions from extract/regions.json (source addresses)."""
    out = []
    for p in paths:
        p = Path(p)
        d = json.loads(p.read_text())
        label = p.parent.parent.name  # build/<name>/extract/regions.json
        regs = {k: (v["src"], v["len"], v.get("kind", "?"))
                for k, v in d["regions"].items()}
        out.append((label, regs, d.get("src_set", "?")))
    return out


def map_addr(tenants, addr):
    """[(tenant, region, off, kind)] for every tenant whose regions contain
    addr. kind matters: a hit inside a DATA-kind region (anim, hitbox) is a
    byte-pattern coincidence, not an instruction — data regions are never
    executed, so such rows are informational and never actionable."""
    hits = []
    for label, regs, _ in tenants:
        for name, (src, ln, kind) in regs.items():
            if src <= addr < src + ln:
                hits.append((label, name, addr - src, kind))
                break  # regions within one tenant do not overlap
    return hits


def code_hits(r):
    return [t for t in r["tenants"] if t[3] != "data"]


def w16(img, i):
    return (img[i] << 8) | img[i + 1]


def w32(img, i):
    return (w16(img, i) << 16) | w16(img, i + 2)


def in_family(fams, tt):
    return [(site, lo, hi) for site, lo, hi in fams if lo <= tt <= hi]


def ea_name(mode, reg):
    return {0: f"D{reg}", 1: f"A{reg}", 2: f"(A{reg})", 3: f"(A{reg})+",
            4: f"-(A{reg})", 5: f"(d16,A{reg})", 6: f"(d8,A{reg},Xn)",
            7: {0: "abs.w", 1: "abs.l", 2: "(d16,PC)", 3: "(d8,PC,Xn)",
                4: "#imm"}.get(reg, "?")}.get(mode, "?")


def scan(img, fams, tenants):
    """Return (rows, reader_rows). Rows keyed by src_addr of the OPCODE."""
    n = len(img)
    rows = {}

    def add(addr, form, **kw):
        # most-specific form wins per address
        if addr in rows and rows[addr]["form"] != "imm_l_other":
            return
        r = {"src_addr": addr, "form": form}
        r.update(kw)
        r["tenants"] = map_addr(tenants, addr)
        rows[addr] = r

    # pass 1: the four anchored move.l #imm,<mem EA> stamp forms + cmpi + w/b
    for i in range(0, n - 5, 2):
        op = w16(img, i)
        # --- move.l #imm,<ea> : 0010 rrr MMM 111100 ---
        if (op & 0xF03F) == 0x203C and (op & 0x01C0) != 0x0040:
            dmode = (op >> 6) & 7
            dreg = (op >> 9) & 7
            imm = w32(img, i + 2)
            if (imm >> 24) == 0x01:
                tt = (imm >> 8) & 0xFF
                if in_family(fams, tt):
                    form = {2: "stamp_l_ind", 3: "stamp_l_post",
                            4: "stamp_l_pre", 5: "stamp_l_d16",
                            0: "imm_l_other",  # move.l #imm,Dn — composed
                            }.get(dmode)
                    if form is None:
                        form = "imm_l_other"
                    kw = {"imm": imm, "type": tt, "ss": imm & 0xFF,
                          "ea": ea_name(dmode, dreg)}
                    if dmode == 5:
                        kw["d16"] = w16(img, i + 6)
                    add(i, form, **kw)
        # --- cmpi.{b,w,l} #imm,<ea> : 00001100 SS MMMrrr ---
        if (op & 0xFF00) == 0x0C00:
            size = (op >> 6) & 3
            mode = (op >> 3) & 7
            reg = op & 7
            if size == 3 or mode == 1:
                pass  # not a cmpi / An dest illegal
            else:
                matched = None
                if size == 0:  # .b — immediate in low byte of ext word
                    v = w16(img, i + 2) & 0xFF
                    if in_family(fams, v):
                        matched = ("cmp_b", v, v)
                elif size == 1:  # .w
                    v = w16(img, i + 2)
                    if in_family(fams, v):
                        matched = ("cmp_w", v, v)          # plain type word
                    elif in_family(fams, (v >> 8) & 0xFF):
                        matched = ("cmp_w", v, (v >> 8) & 0xFF)  # TTss view
                else:  # .l — full header
                    v = w32(img, i + 2)
                    if (v >> 24) == 0x01 and in_family(fams, (v >> 8) & 0xFF):
                        matched = ("cmp_l", v, (v >> 8) & 0xFF)
                if matched:
                    form, v, tt = matched
                    ext = 4 + (4 if size == 2 else 2)
                    kw = {"imm": v, "type": tt,
                          "ea": ea_name(mode, reg)}
                    if mode == 5:
                        kw["d16"] = w16(img, i + ext - 2)
                    add(i, form, **kw)
        # --- move.w #imm,(d16,An) / move.b #imm,(d16,An) targeting +2/+3 ---
        if (op & 0xF1FF) == 0x317C:  # move.w #imm,(d16,An)
            imm = w16(img, i + 2)
            d16 = w16(img, i + 4)
            if d16 in (2, 3) or in_family(fams, (imm >> 8) & 0xFF) \
                    or in_family(fams, imm):
                if d16 in (2, 3) and (in_family(fams, (imm >> 8) & 0xFF)
                                      or in_family(fams, imm)):
                    add(i, "stamp_w_d16", imm=imm, d16=d16,
                        type=(imm >> 8) & 0xFF if
                        in_family(fams, (imm >> 8) & 0xFF) else imm,
                        ea=ea_name(5, (op >> 9) & 7))
        if (op & 0xF1FF) == 0x117C:  # move.b #imm,(d16,An)
            imm = w16(img, i + 2) & 0xFF
            d16 = w16(img, i + 4)
            if d16 in (2, 3) and in_family(fams, imm):
                add(i, "stamp_b_d16", imm=imm, d16=d16, type=imm,
                    ea=ea_name(5, (op >> 9) & 7))

    # pass 2: unanchored $01xxTTss longs (TRIAGE — the 47-false-bare-longs
    # class lives here, which is why this class is never auto-rewritten).
    # byte1 must be <= 0x01: every real header observed is $0100TTss or
    # $0101TTss, and without that filter this class is 1,100+ rows of
    # operand pairs fused into header-plausible longs (measured 14z-82).
    for i in range(0, n - 3, 2):
        if i in rows or (i - 2) in rows:
            continue
        v = w32(img, i)
        if (v >> 24) == 0x01 and ((v >> 16) & 0xFF) <= 0x01 \
                and in_family(fams, (v >> 8) & 0xFF):
            # only keep triage hits inside SOME tenant's regions — a raw
            # value match over 4 MB of unported bytes is pure noise
            t = map_addr(tenants, i)
            if t:
                rows[i] = {"src_addr": i, "form": "imm_l_other", "imm": v,
                           "type": (v >> 8) & 0xFF, "ss": v & 0xFF,
                           "tenants": t}

    # pass 3: (2,An)/(3,An) readers inside FAMILY REGIONS only
    fam_spans = family_spans(rows.values(), tenants)
    readers = []
    READ_OPS = [  # (mask, val, form) — src EA = (d16,An) is mode 101
        (0xF1F8, 0x1028, "reader_move_b"),   # move.b (d16,An),Dn
        (0xF1F8, 0x3028, "reader_move_w"),   # move.w (d16,An),Dn
        (0xFFF8, 0x4A28, "reader_tst_b"),    # tst.b (d16,An)
        (0xFFF8, 0x4A68, "reader_tst_w"),    # tst.w (d16,An)
    ]
    for lo, hi in fam_spans:
        for i in range(lo, min(hi, n) - 5, 2):
            op = w16(img, i)
            for mask, val, form in READ_OPS:
                if (op & mask) == val and w16(img, i + 2) in (2, 3):
                    readers.append({"src_addr": i, "form": form,
                                    "d16": w16(img, i + 2),
                                    "next_words": [w16(img, i + 4),
                                                   w16(img, i + 6)],
                                    "tenants": map_addr(tenants, i)})
                    break

    # pass 4: embedded pool-walker DISPATCHERS anywhere in a ported span —
    # the one shape that consumes a type byte as a TABLE INDEX:
    #   moveq #0,d0; move.b (2,An),d0; add.w d0,d0; add.w d0,d0;
    #   movea.l (d8,PC,D0.w),a0
    # (found live: vs2's own 0x54470-site walker at 0x5C604 sits INSIDE the
    # tenants' code spans, with its 76-entry table at 0x5C620 truncated by
    # every tenant's region end — 14z-82. A renumbered type reaching such an
    # embedded table would over-index it, which is why this pass exists.)
    walkers = []
    all_spans = []
    for label, regs, _ in tenants:
        for name, (src, ln, kind) in regs.items():
            if kind != "data":
                all_spans.append((src, src + ln))
    all_spans.sort()
    merged_sp = []
    for lo, hi in all_spans:
        if merged_sp and lo <= merged_sp[-1][1]:
            merged_sp[-1] = (merged_sp[-1][0], max(hi, merged_sp[-1][1]))
        else:
            merged_sp.append((lo, hi))
    for lo, hi in merged_sp:
        for i in range(lo, min(hi, n) - 11, 2):
            if w16(img, i) == 0x7000 \
                    and (w16(img, i + 2) & 0xFFF8) == 0x1028 \
                    and w16(img, i + 4) == 2 \
                    and w16(img, i + 6) == 0xD040 \
                    and w16(img, i + 8) == 0xD040 \
                    and (w16(img, i + 10) & 0xF1FF) == 0x207B:
                walkers.append({"src_addr": i,
                                "table": i + 12 + (w16(img, i + 12) & 0xFF),
                                "tenants": map_addr(tenants, i)})
    return sorted(rows.values(), key=lambda r: r["src_addr"]), readers, walkers


def family_spans(rows, tenants):
    """Source spans of every tenant region that contains a family stamp,
    plus the handler region x088512's span (all seven 0x5E542-family
    handlers live inside it)."""
    names = set()
    for r in rows:
        if r["form"].startswith("stamp"):
            for tenant, region, _, _kind in r["tenants"]:
                names.add((tenant, region))
    spans = []
    for label, regs, _ in tenants:
        for name, (src, ln, kind) in regs.items():
            if (label, name) in names or name == "x088512" \
                    or name == "x06cac0":
                spans.append((src, src + ln))
    # merge overlaps (the same source span appears under several tenants)
    spans.sort()
    merged = []
    for lo, hi in spans:
        if merged and lo <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(hi, merged[-1][1]))
        else:
            merged.append((lo, hi))
    return merged


def scan_data_in_code(img, fams):
    """The x088512 data_in_code table 0x08C042 (len 0x100): report family
    values in it either way. Its semantics are NOT decoded here — this is
    a could-types-live-here statement, not a verdict."""
    base, ln = 0x08C042, 0x100
    b_hits = [i for i in range(ln) if in_family(fams, img[base + i])]
    w_hits = [i for i in range(0, ln - 1, 2)
              if in_family(fams, (w16(img, base + i) >> 8) & 0xFF)]
    return base, ln, b_hits, w_hits


def tens_str(r):
    return ",".join(f"{t}:{reg}+0x{off:X}" + ("(DATA)" if kind == "data" else "")
                    for t, reg, off, kind in r["tenants"])


def freezable(r):
    """Freeze policy: rows with at least one CODE-region tenant mapping
    (the actionable exposure), plus UNPORTED stamps of the ACTIVE family
    (114-120 — the documented negative controls). Unported 59-75 stamps,
    out-of-region compare noise and data-region byte coincidences stay out
    of the frozen file so it remains reviewable — the scan itself still
    reports them every run."""
    if r["form"].startswith("stamp"):
        if not r["tenants"]:
            return 114 <= r["type"] <= 120
        return bool(code_hits(r))
    return bool(code_hits(r))


def to_toml(rows, readers, walkers, src_set, img_sha):
    L = ["# build/manifest/type_stamps.toml — FROZEN inventory of extended",
         "# object-type stamp sites / comparisons / readers / embedded",
         "# walkers (14z-82). Generated by tools/audit_type_stamps.py;",
         "# HUMAN-REVIEWED before freezing. The generator's renumber pass",
         "# consumes `stamp` rows (114-120 family, code regions, d16==2 for",
         "# byte stamps) and fails closed on any `compare` row typed in a",
         "# renumbered tenant's code regions whose action is not explicitly",
         "# recorded. tests/test_type_stamp_census.sh re-scans and fails on",
         "# drift. Freeze policy: rows mapping into >=1 CODE region, plus",
         "# UNPORTED stamps (the negative controls).",
         "#",
         f"# src image sha1: {img_sha}",
         "schema = 1",
         f'src_set = "{src_set}"',
         ""]
    for r in rows:
        if not freezable(r):
            continue
        kind = "stamp" if r["form"].startswith("stamp") else \
               ("compare" if r["form"].startswith("cmp") else "triage")
        L.append(f"[[{kind}]]")
        L.append(f"src_addr = 0x{r['src_addr']:06X}")
        L.append(f'form = "{r["form"]}"')
        L.append(f"imm = 0x{r['imm']:08X}" if r["form"].startswith(("stamp_l", "imm_l"))
                 or r["form"] == "cmp_l" else f"imm = 0x{r['imm']:04X}")
        L.append(f"type = {r['type']}")
        if "d16" in r:
            L.append(f"d16 = 0x{r['d16']:04X}")
        if "ea" in r:
            L.append(f'ea = "{r["ea"]}"')
        t = tens_str(r)
        L.append(f'tenants = "{t}"' if t else 'tenants = ""  # UNPORTED')
        if kind == "compare":
            L.append('action = "REVIEW"  # set to none/rewrite + note')
        L.append("")
    for r in readers:
        if not code_hits(r):
            continue
        L.append("[[reader]]")
        L.append(f"src_addr = 0x{r['src_addr']:06X}")
        L.append(f'form = "{r["form"]}"')
        L.append(f"d16 = {r['d16']}")
        L.append(f"next_words = \"{r['next_words'][0]:04X} "
                 f"{r['next_words'][1]:04X}\"")
        L.append(f'tenants = "{tens_str(r)}"')
        L.append("")
    for r in walkers:
        L.append("[[walker]]")
        L.append(f"src_addr = 0x{r['src_addr']:06X}")
        L.append(f"table = 0x{r['table']:06X}")
        L.append(f'tenants = "{tens_str(r)}"')
        L.append("")
    return "\n".join(L) + "\n"


def parse_frozen(path):
    """Minimal TOML-subset reader for the frozen file (rows of k = v)."""
    rows = []
    cur = None
    for ln in Path(path).read_text().splitlines():
        s = ln.strip()
        if s.startswith("[["):
            cur = {"_kind": s.strip("[]")}
            rows.append(cur)
        elif cur is not None and "=" in s and not s.startswith("#"):
            k, _, v = s.partition("=")
            v = v.split("#")[0].strip().strip('"')
            cur[k.strip()] = v
    return rows


def freeze_key(kind, src_addr, form, imm, typ):
    return f"{kind} 0x{src_addr:06X} {form} 0x{imm:X} t{typ}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image", help="SOURCE opcode view (vsav2_opcodes.bin)")
    ap.add_argument("--regions", action="append", required=True,
                    help="a tenant's extract/regions.json (repeatable, "
                         "tenant declaration order)")
    ap.add_argument("--family", action="append",
                    help=f"site:lo-hi (default {DEFAULT_FAMILIES})")
    ap.add_argument("--toml", type=Path, help="write frozen-inventory TOML")
    ap.add_argument("--verify", type=Path,
                    help="frozen TOML to diff against (FAIL on drift)")
    ap.add_argument("--no-expect", action="store_true",
                    help="skip the positive control (controls only make "
                         "sense on the real vsav2 image)")
    ap.add_argument("--expect-extra", action="append", default=[],
                    help="addr:type — additional required rewrite-class "
                         "site (verdict-control hook)")
    args = ap.parse_args()

    img = Path(args.image).read_bytes()
    img_sha = sha1(args.image)
    print(f"image: {args.image} sha1 {img_sha}")
    tenants = load_tenants(args.regions)
    for (label, regs, src_set), p in zip(tenants, args.regions):
        print(f"tenant {label}: {len(regs)} regions ({p}) src_set={src_set}")
    fams = [parse_family(f) for f in (args.family or DEFAULT_FAMILIES)]
    for site, lo, hi in fams:
        print(f"family: site 0x{site:05X} types {lo}-{hi}")

    rows, readers, walkers = scan(img, fams, tenants)

    stamps = [r for r in rows if r["form"].startswith("stamp")]
    cmps = [r for r in rows if r["form"].startswith("cmp")]
    triage = [r for r in rows if r["form"] == "imm_l_other"]
    print(f"\n== stamps ({len(stamps)}) ==")
    for r in stamps:
        d = f" d16={r['d16']}" if "d16" in r else ""
        print(f"  0x{r['src_addr']:06X} {r['form']:13s} imm 0x{r['imm']:08X} "
              f"type {r['type']:3d} {r.get('ea', ''):9s}{d} "
              f"{tens_str(r) or 'UNPORTED'}")
    print(f"\n== compares ({len(cmps)}; frozen subset = code-region rows) ==")
    for r in cmps:
        d = f" d16=0x{r['d16']:X}" if "d16" in r else ""
        print(f"  0x{r['src_addr']:06X} {r['form']:6s} imm 0x{r['imm']:X} "
              f"type {r['type']:3d} ea {r.get('ea', '?')}{d} "
              f"{tens_str(r) or '(outside all tenant regions)'}")
    print(f"\n== triage $01xxTTss longs in ported spans ({len(triage)}) ==")
    for r in triage:
        print(f"  0x{r['src_addr']:06X} imm 0x{r['imm']:08X} "
              f"type {r['type']:3d} {tens_str(r)}")
    print(f"\n== (2,An)/(3,An) readers in family regions ({len(readers)}) ==")
    for r in readers:
        print(f"  0x{r['src_addr']:06X} {r['form']:14s} d16={r['d16']} "
              f"next {r['next_words'][0]:04X} {r['next_words'][1]:04X}  "
              f"{tens_str(r)}")
    print(f"\n== embedded type-dispatch walkers in ported code spans "
          f"({len(walkers)}) ==")
    for r in walkers:
        print(f"  0x{r['src_addr']:06X} table 0x{r['table']:06X}  "
              f"{tens_str(r)}")

    base, ln, b_hits, w_hits = scan_data_in_code(img, fams)
    print(f"\n== data_in_code table 0x{base:06X}+0x{ln:X} ==")
    print(f"  family-valued BYTES at {len(b_hits)} offsets, family-typed "
          f"WORD views at {len(w_hits)} even offsets")
    print("  (semantics not decoded here — a nonzero count is a question "
          "for the dynamic census, not a verdict)")

    print("\nNOT COVERED STATICALLY: register-sourced writes "
          "(move.b Dn,(2,An)), computed immediates, movem, runtime-composed "
          "headers. The dynamic writer-PC census "
          "(tests/audit_type_writes.sh) is the gate for those.")

    rc = 0
    # positive control
    if not args.no_expect:
        expect = dict(EXPECT_5E542)
        for e in args.expect_extra:
            a, t = e.split(":")
            expect[int(a, 0)] = int(t, 0)
        stamp_addrs = {r["src_addr"]: r["type"] for r in stamps
                       if r["form"].startswith("stamp_l")}
        for a, t in sorted(expect.items()):
            got = stamp_addrs.get(a)
            if got == t:
                print(f"  PASS  expect 0x{a:06X} type {t}")
            else:
                print(f"  FAIL  expect 0x{a:06X} type {t} — got {got} "
                      f"(the census cannot see a site it is supposed to "
                      f"see; do not trust ANY of its numbers)")
                rc = 1
        # negative control: unported stamps map to no tenant
        by_addr = {r["src_addr"]: r for r in rows}
        for a in EXPECT_UNPORTED:
            r = by_addr.get(a)
            if r is None:
                print(f"  FAIL  negative control 0x{a:06X}: site not found "
                      f"at all (scan drifted)")
                rc = 1
            elif r["tenants"]:
                print(f"  FAIL  negative control 0x{a:06X}: expected "
                      f"UNPORTED, maps to {r['tenants']} (region model "
                      f"drifted — re-review the inventory)")
                rc = 1
            else:
                print(f"  PASS  negative control 0x{a:06X} unported")

    if args.toml:
        args.toml.write_text(to_toml(rows, readers, walkers, tenants[0][2],
                                     img_sha))
        print(f"wrote {args.toml}")

    if args.verify:
        frozen = parse_frozen(args.verify)
        fro = set()
        for r in frozen:
            if r["_kind"] in ("stamp", "compare", "triage"):
                fro.add(freeze_key(r["_kind"], int(r["src_addr"], 0),
                                   r["form"], int(r["imm"], 0),
                                   int(r["type"], 0)))
            elif r["_kind"] == "reader":
                fro.add(f"reader 0x{int(r['src_addr'], 0):06X} {r['form']}")
            elif r["_kind"] == "walker":
                fro.add(f"walker 0x{int(r['src_addr'], 0):06X} "
                        f"{int(r['table'], 0):#x}")
        got = set()
        for r in rows:
            if not freezable(r):
                continue
            kind = "stamp" if r["form"].startswith("stamp") else \
                   ("compare" if r["form"].startswith("cmp") else "triage")
            got.add(freeze_key(kind, r["src_addr"], r["form"], r["imm"],
                               r["type"]))
        for r in readers:
            if code_hits(r):
                got.add(f"reader 0x{r['src_addr']:06X} {r['form']}")
        for r in walkers:
            got.add(f"walker 0x{r['src_addr']:06X} {r['table']:#x}")
        added = sorted(got - fro)
        removed = sorted(fro - got)
        if added or removed:
            for k in added:
                print(f"  DRIFT +{k}")
            for k in removed:
                print(f"  DRIFT -{k}")
            print(f"FAIL: inventory drift vs {args.verify} "
                  f"(+{len(added)}/-{len(removed)}) — a new/changed site "
                  f"must be REVIEWED and re-frozen, not absorbed")
            rc = 1
        else:
            print(f"  PASS  no drift vs {args.verify} "
                  f"({len(fro)} frozen rows)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
