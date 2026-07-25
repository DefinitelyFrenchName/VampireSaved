#!/usr/bin/env python3
"""extract_char.py — extract one character's program-ROM footprint from a
source set, validated against the sibling set as an oracle.

Walks every table in build/manifest/bank_map.toml at the given char id,
extracts the pointed-to data/code regions (transitive, via the diff oracle),
and emits a machine-readable region manifest + blobs for the patch
generator. ROM-derived bytes go only to the (gitignored) out dir and are
regenerated from $ROMDIR on every build (repo rule 7).

THE ORACLE (the correctness instrument, docs/atlas/character_tables.md):
per-slot character data is byte-identical between vsav2 and vhunt2 except
for embedded pointer fields, which differ by constant per-region shifts
(code +0x30, bank/hitbox -0x76E, anim -0x13B74 — computed at runtime from
anchors, not hardcoded). Therefore, inside a correctly-bounded region,
EVERY byte that differs between the sets must decode as a pointer field
whose delta equals a known shift — that diff-derived field list is the
authoritative relocation map (no data-format knowledge needed), and any
unexplained diff site fails the extraction. Same-value references
(RAM/hardware) never need relocation; engine ROM references inside CODE are
additionally triaged by scan_code_refs.py (they can shift by non-region
engine deltas, or coincide).

Region bounding:
  hitbox  next-distinct-pointer over all 32 entries of the 4 hitbox-family
          tables (both sets; lengths must agree)
  anim    from anim_index_a[char] forward by cross-set similarity scan
          (chunks stay >=90% byte-identical while still in shared character
          data; the two games' unrelated surroundings end it), pad-trimmed
  code    span of the char's 14 dispatch targets, extended by the same
          similarity scan on PLAINTEXT (both sets decrypted), pad-trimmed

Usage:
    python3 tools/extract_char.py <src_set.zip> <out_dir> \
        --char 0x13 --oracle <oracle_set.zip> \
        [--bank-map build/manifest/bank_map.toml]

Exits nonzero if any oracle check fails. Value-table entries that differ
between the sets are NOT failures — they are real VS2-vs-VH2 flavor deltas,
reported as variant_delta for the maintainer (SPEC §3 variant policy).
"""

import argparse
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cps2_decrypt as cps  # noqa: E402
import scan_code_refs  # noqa: E402
from _minitoml import loads as toml_loads  # noqa: E402

VSAVJ_ORIGIN = 0x0BD0FA
NEWCOMER_CODE = (0x057000, 0x05D000)  # appended newcomer handler window
SIM_CHUNK = 0x100
SIM_THRESHOLD = 0.90
ANIM_CAP = 0x30000
CODE_CAP = 0x8000

# hard anchors (docs/atlas/character_tables.md) — asserted when char=0x13
DONOVAN_ANCHORS = {"dispatch_00": 0x05AE20, "hitbox_base": 0x0C8DF8,
                   "anim_index_a": 0x27F548}


class SetImage:
    def __init__(self, zpath):
        self.path = str(zpath)
        words, keybytes, prgs, sha1s = cps.load_set(zpath)
        self.words = words
        self.cipher = cps.Cipher(keybytes)
        self.sha1s = sha1s
        self.data = bytes(cps.words_to_logical_bytes(words))
        for name in prgs:
            print(f"  {Path(zpath).name}/{name}  sha1 {sha1s[name]}")

    def u32(self, addr):
        return int.from_bytes(self.data[addr:addr + 4], "big")

    def plaintext(self, start, end):
        """Decrypted (opcode-view) bytes for [start, end)."""
        w = self.cipher.crypt_words_at(self.words[start // 2:end // 2],
                                       start // 2, decrypt=True)
        return bytes(cps.words_to_logical_bytes(w))


def load_bank_map(path):
    doc = toml_loads(Path(path).read_text())
    origins = {k: int(v) if not isinstance(v, int) else v
               for k, v in doc["origins"].items()}
    tables = doc["table"]
    for t in tables:
        t["vsavj"] = t["vsavj"] if isinstance(t["vsavj"], int) else int(t["vsavj"], 0)
    return origins, tables


def table_addr(t, origins, setname):
    return origins[setname] + (t["vsavj"] - VSAVJ_ORIGIN)


def entry_size(t):
    if t["kind"] == "byte2d":
        return t["span"] // 32
    return t["stride"] // 32


ENGINE_ENVELOPE = 0x40000  # sibling-build engine/data addresses drift by
                          # location-dependent deltas (loader +0x2E, code
                          # +0x30, bank -0x76E, shared-asset data -0x2F88);
                          # a 32-bit both-ROM field within this envelope is
                          # an engine reference (an individually-recorded R1
                          # item), not noise


def diff_refs(a_blob, b_blob, shifts, allow_engine):
    """Diff two same-length blobs; every diff site must decode as a pointer
    field the oracle explains:
      - 32/24-bit field whose (b - a) delta equals a known region shift
        -> {shift: <region>} (relocate by that region's delta)
      - (allow_engine) 32-bit field, both values ROM addrs, |delta| within
        the sibling-build envelope -> {shift: 'engine'} (R1 map required)
      - (allow_engine) 16-bit field with small delta -> {shift: 'pcrel16'}
        (PC-relative displacement to a target outside the region)
    Returns (refs, unexplained_byte_offsets)."""
    assert len(a_blob) == len(b_blob)
    diffs = [i for i in range(len(a_blob)) if a_blob[i] != b_blob[i]]
    refs, unexplained = [], []
    covered = set()
    for i in diffs:
        if i in covered:
            continue
        site = None
        for width, span in ((32, 4), (24, 3)):
            for off in range(max(0, i - span + 1), min(i, len(a_blob) - span) + 1):
                va = int.from_bytes(a_blob[off:off + span], "big")
                vb = int.from_bytes(b_blob[off:off + span], "big")
                delta = vb - va
                for shift_name, shift in shifts.items():
                    if delta == shift and va < 0x400000:
                        site = {"off": off, "width": width, "target": va,
                                "shift": shift_name}
                        break
                if site:
                    break
            if site:
                break
        if site is None and allow_engine:
            for off in range(max(0, i - 3), min(i, len(a_blob) - 4) + 1):
                va = int.from_bytes(a_blob[off:off + 4], "big")
                vb = int.from_bytes(b_blob[off:off + 4], "big")
                if (va != vb and va < 0x400000 and vb < 0x400000
                        and abs(vb - va) <= ENGINE_ENVELOPE):
                    site = {"off": off, "width": 32, "target": va,
                            "orc_target": vb, "shift": "engine"}
                    break
        if site is None and allow_engine:
            # real PC-relative displacement drift between sibling builds is
            # tiny — a tight envelope avoids classifying data words as pcrel
            for off in range(max(0, i - 1), min(i, len(a_blob) - 2) + 1):
                va = int.from_bytes(a_blob[off:off + 2], "big")
                vb = int.from_bytes(b_blob[off:off + 2], "big")
                da = (vb - va + 0x8000) % 0x10000 - 0x8000
                if va != vb and abs(da) <= 0x200:
                    site = {"off": off, "width": 16, "target": va,
                            "orc_target": vb, "shift": "pcrel16"}
                    break
        if site:
            refs.append(site)
            covered.update(range(site["off"], site["off"] + site["width"] // 8))
        else:
            unexplained.append(i)
    return refs, unexplained


def oracle_extend(a_img, a_start, b_img, b_start, cap, shifts, allow_engine):
    """Region length by oracle coverage: extend chunk-by-chunk while the diff
    classifier explains (almost) every differing byte — shared character
    data stays explainable under the known shifts even where pointer-dense
    (anim scripts); the two games' unrelated surroundings do not. Trims
    trailing uniform padding."""
    length = 0
    MARGIN = 8  # so pointer fields spanning a chunk edge classify correctly
    while length < cap:
        lo = max(0, length - MARGIN)
        hi = length + SIM_CHUNK + MARGIN
        ca = a_img[a_start + lo:a_start + hi]
        cb = b_img[b_start + lo:b_start + hi]
        if len(ca) < (hi - lo) or len(cb) < (hi - lo):
            break
        _, unexplained = diff_refs(ca, cb, shifts, allow_engine)
        core = [i for i in unexplained
                if (length - lo) <= i < (length - lo) + SIM_CHUNK]
        if len(core) > SIM_CHUNK // 50:  # >2% unexplained -> out of region
            break
        length += SIM_CHUNK
    blob = a_img[a_start:a_start + length]
    while length > 0x10 and blob[length - 0x10:length] in (b"\xff" * 0x10, b"\x00" * 0x10):
        length -= 0x10
    return length


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src", type=Path)
    ap.add_argument("out_dir", type=Path)
    ap.add_argument("--char", type=lambda x: int(x, 0), default=0x13)
    ap.add_argument("--oracle", type=Path, required=True)
    ap.add_argument("--bank-map", type=Path,
                    default=Path(__file__).resolve().parent.parent
                    / "build" / "manifest" / "bank_map.toml")
    ap.add_argument("--extra-roots", default="",
                    help="comma list of vsav2 code addresses to extract as "
                         "additional regions (absent-in-vsavj support "
                         "routines found by the R1 loop); each is twinned "
                         "in the oracle set by masked pattern search")
    args = ap.parse_args()
    char = args.char
    out = args.out_dir
    out.mkdir(parents=True, exist_ok=True)

    src_name = Path(args.src).stem
    orc_name = Path(args.oracle).stem
    origins, tables = load_bank_map(args.bank_map)
    if src_name not in origins or orc_name not in origins:
        sys.exit(f"bank map has no origin for {src_name}/{orc_name}")

    print(f"source set {args.src}:")
    src = SetImage(args.src)
    print(f"oracle set {args.oracle}:")
    orc = SetImage(args.oracle)

    fail = []
    report = []
    values = []
    engine_dispatch = []
    auto_findings = []
    tab = {t["name"]: t for t in tables}

    def entry(img, setname, t, c=None):
        base = table_addr(t, origins, setname)
        es = entry_size(t)
        a = base + (char if c is None else c) * es
        return a, img.data[a:a + es]

    # ── runtime shifts from anchors (never hardcoded) ────────────────────────
    d0_s = src.u32(table_addr(tab["dispatch_00"], origins, src_name) + char * 4)
    d0_o = orc.u32(table_addr(tab["dispatch_00"], origins, orc_name) + char * 4)
    hb_s = src.u32(table_addr(tab["hitbox_base"], origins, src_name) + char * 4)
    hb_o = orc.u32(table_addr(tab["hitbox_base"], origins, orc_name) + char * 4)
    an_s = src.u32(table_addr(tab["anim_index_a"], origins, src_name) + char * 4)
    an_o = orc.u32(table_addr(tab["anim_index_a"], origins, orc_name) + char * 4)
    shifts = {"code": d0_o - d0_s, "bank": hb_o - hb_s, "anim": an_o - an_s}
    report.append(f"shifts ({src_name}->{orc_name}): "
                  + ", ".join(f"{k}={v:+#x}" for k, v in shifts.items()))

    # ── anchors ──────────────────────────────────────────────────────────────
    if char == 0x13 and src_name == "vsav2":
        for tname, want in DONOVAN_ANCHORS.items():
            got = src.u32(table_addr(tab[tname], origins, src_name) + char * 4)
            if got != want:
                fail.append(f"ANCHOR {tname}[0x13] = {got:#x}, expected {want:#x}")
    if fail:
        for f in fail:
            print(f"FAIL: {f}")
        sys.exit(1)

    # ── region bounding ──────────────────────────────────────────────────────
    regions = {}

    # hitbox / hitbox_proj: next-distinct-pointer over each table pair
    def ptr_bounds(img, setname, table_names):
        seeds, all_ptrs = [], set()
        for tn in table_names:
            base = table_addr(tab[tn], origins, setname)
            for c in range(32):
                v = img.u32(base + c * 4)
                if 0x1000 < v < 0x400000:
                    all_ptrs.add(v)
                if c == char:
                    seeds.append(v)
        start = min(seeds)
        above = [p for p in all_ptrs if p > max(seeds)]
        end = min(above) if above else max(seeds) + 0x4000
        return start, end

    for rname, tnames in (("hitbox", ["hitbox_base", "hitbox_comp"]),
                          ("hitbox_proj", ["proj_hitbox_base", "proj_hitbox_comp"])):
        s0, s1 = ptr_bounds(src, src_name, tnames)
        regions[rname] = {"src": s0, "orc": s0 + shifts["bank"],
                          "len": s1 - s0, "kind": "data", "shift": "bank"}

    # anim: seeded at anim_index_a[char]; initial oracle scan, then grown to
    # closure over forward escapes in the classification pass below
    alen = oracle_extend(src.data, an_s, orc.data, an_o, ANIM_CAP, shifts, False)
    regions["anim"] = {"src": an_s, "orc": an_o, "len": alen, "grow": ANIM_CAP,
                       "kind": "data", "shift": "anim"}

    # code: span of in-window dispatch targets, similarity-extended (plaintext)
    disp = []
    for k in range(14):
        tn = f"dispatch_{k:02d}"
        v_s = src.u32(table_addr(tab[tn], origins, src_name) + char * 4)
        v_o = orc.u32(table_addr(tab[tn], origins, orc_name) + char * 4)
        if NEWCOMER_CODE[0] <= v_s < NEWCOMER_CODE[1]:
            disp.append((tn, v_s, v_o))
        else:
            engine_dispatch.append({"table": tn, "src_target": v_s,
                                    "orc_target": v_o, "delta": v_o - v_s})
    if not disp:
        fail.append("no dispatch targets in the newcomer code window")
        cs_s = cs_o = clen = 0
    else:
        cs_s = min(v for _, v, _o in disp) & ~0xF
        cs_o = cs_s + shifts["code"]
        pt_s = src.plaintext(cs_s, min(cs_s + CODE_CAP, 0x100000))
        pt_o = orc.plaintext(cs_o, min(cs_o + CODE_CAP, 0x100000))
        clen = oracle_extend(pt_s, 0, pt_o, 0, CODE_CAP, shifts, True)
        span_need = max(v for _, v, _o in disp) - cs_s
        if clen <= span_need:
            fail.append(f"code similarity scan ended at +{clen:#x}, before the "
                        f"last dispatch target (+{span_need:#x})")
    regions["code"] = {"src": cs_s, "orc": cs_o, "len": clen, "grow": CODE_CAP,
                       "kind": "code", "shift": "code"}

    # extra code roots: absent-in-vsavj support routines. Spec per root:
    #   addr           twin by masked pattern search, oracle-bounded
    #   addr:len       same, but length capped/fixed to len
    #   addr:len:s     SOURCE-ONLY: no oracle twin exists (per-game hook,
    #                  content diverges between siblings); length is fixed
    #                  and refs come from the operand scanner (labeled
    #                  opcodes only), not the diff
    source_only = []
    for root_s in args.extra_roots.split(","):
        if not root_s:
            continue
        parts = root_s.split(":")
        root = int(parts[0], 0)
        fixed_len = int(parts[1], 0) if len(parts) > 1 and parts[1] else None
        forced_twin = None
        if len(parts) > 2 and parts[2].startswith("t"):
            forced_twin = int(parts[2][1:], 0)
        if len(parts) > 2 and parts[2] == "s":
            sh_name = f"x{root:06x}"
            regions[sh_name] = {"src": root, "orc": root, "len": fixed_len,
                                "kind": "code", "shift": sh_name,
                                "source_only": True}
            source_only.append(sh_name)
            report.append(f"extra region {sh_name}: SOURCE-ONLY, "
                          f"len 0x{fixed_len:X} (per-game hook; scanner refs)")
            continue
        pat = src.plaintext(root, root + 0x40)
        mask = bytearray(b"\x01" * len(pat))
        for ref in scan_code_refs.scan(pat, root):
            for i in range(ref["off"],
                           min(ref["off"] + ref["width"] // 8, len(mask))):
                mask[i] = 0
        # anchor = longest hard run
        best, cur = (0, 0), None
        for i, m in enumerate(list(mask) + [0]):
            if m and cur is None:
                cur = i
            elif not m and cur is not None:
                if i - cur > best[0]:
                    best = (i - cur, cur)
                cur = None
        anchor = bytes(pat[best[1]:best[1] + best[0]])
        # search the oracle's plaintext around root +- 0x8000; score every
        # anchor hit with the full mask and take the best (ties -> smallest
        # |shift|) — the first hit can be a similar-code false friend
        win_lo = max(0, root - 0x8000)
        orc_pt_win = orc.plaintext(win_lo, min(0x100000, root + 0x8000))
        hard = mask.count(1)
        cands = []
        pos = orc_pt_win.find(anchor)
        while pos != -1 and len(cands) < 32:
            base = pos - best[1]
            if 0 <= base <= len(orc_pt_win) - len(pat):
                sc = sum(1 for i in range(len(pat))
                         if mask[i] and orc_pt_win[base + i] == pat[i]) / hard
                cands.append((sc, abs(win_lo + base - root), win_lo + base))
            pos = orc_pt_win.find(anchor, pos + 2)
        if forced_twin is not None:
            twin = forced_twin
        elif not cands:
            fail.append(f"extra root {root:#x}: no oracle twin found")
            continue
        else:
            cands.sort(key=lambda c: (-c[0], c[1]))
            twin = cands[0][2]
        sh_name = f"x{root:06x}"
        shifts[sh_name] = twin - root
        cap = fixed_len if fixed_len else 0x4000
        xlen = oracle_extend(src.plaintext(root, root + cap + 0x100), 0,
                             orc.plaintext(twin, twin + cap + 0x100), 0,
                             cap, shifts, True)
        if fixed_len:
            xlen = min(xlen, fixed_len)
        regions[sh_name] = {"src": root, "orc": twin, "len": xlen,
                            "grow": cap, "kind": "code", "shift": sh_name}
        report.append(f"extra region {sh_name}: twin 0x{twin:06X} "
                      f"(shift {twin - root:+#x}), len 0x{xlen:X}")

    for name, r in regions.items():
        report.append(f"region {name}: {src_name} 0x{r['src']:06X}+0x{r['len']:X} "
                      f"({r['kind']}, shift {r['shift']})")

    # ── region blobs + oracle diff => authoritative relocation fields ────────
    # Diff bytes classify as: region-shift pointer fields (relocate), engine/
    # pcrel16 refs in code (R1 items), or VARIANT SITES — non-pointer bytes
    # that genuinely differ between the sibling games inside shared character
    # data (VS2-vs-VH2 flavor deltas; recorded for the maintainer, the port
    # uses the source set's bytes). Dense unexplained diffs still fail: that
    # means a misbounded region, not flavor.
    VARIANT_DENSITY = 0.01

    def region_blob(r):
        if r["kind"] == "code":
            return (src.plaintext(r["src"], r["src"] + r["len"]),
                    orc.plaintext(r["orc"], r["orc"] + r["len"]))
        return (src.data[r["src"]:r["src"] + r["len"]],
                orc.data[r["orc"]:r["orc"] + r["len"]])

    blobs = {}

    def classify_region(name, r):
        """Grow-to-closure + diff-classify one region. Returns unexplained
        byte offsets (absolute in-region)."""
        for _ in range(64):
            a, b = region_blob(r)
            refs, unexplained = diff_refs(a, b, shifts, r["kind"] == "code")
            fwd = [ref["target"] for ref in refs
                   if ref["shift"] == r["shift"]
                   and ref["target"] >= r["src"] + r["len"]
                   and ref["target"] < r["src"] + r.get("grow", r["len"])]
            if not fwd:
                break
            newlen = ((max(fwd) - r["src"]) // SIM_CHUNK + 1) * SIM_CHUNK
            report.append(f"  {name}: grown to +0x{newlen:X} to close "
                          f"{len(fwd)} forward refs")
            r["len"] = newlen
        blobs[name] = a
        r["refs"] = refs
        r["variant_sites"] = [{"off": i, "src": a[i], "orc": b[i]}
                              for i in unexplained]
        return unexplained

    def discover_shift(unexplained_by_region, blacklist):
        """Histogram 24-bit decodes at unexplained sites; a delta with many
        consistent hits is a NEW region shift (transitive-closure discovery,
        e.g. Donovan's sprite/OBJ sub-tables at -0x2002C). Sparse or
        already-retracted deltas don't qualify."""
        hist = {}
        for name, offs in unexplained_by_region.items():
            r = regions[name]
            a = blobs[name]
            _, b = region_blob(r)
            for i in offs:
                for s in range(max(0, i - 2), min(i, len(a) - 3) + 1):
                    va = int.from_bytes(a[s:s + 3], "big")
                    vb = int.from_bytes(b[s:s + 3], "big")
                    if va != vb and 0x1000 < va < 0x400000 and 0x1000 < vb < 0x400000:
                        d = vb - va
                        hist.setdefault(d, []).append(va)
        best = None
        for d, targets in hist.items():
            if d in blacklist or len(targets) < 16:
                continue
            if best is None or len(targets) > len(hist[best]):
                best = d
        return (best, hist[best]) if best is not None else (None, None)

    # iterate: classify all regions; discover new shifts from unexplained
    # sites; bound the new region by its referencing targets; retract false
    # discoveries (region fails validation); repeat until closed
    unexplained_by_region = {}
    blacklist = set()
    for _ in range(8):
        unexplained_by_region = {}
        for name, r in list(regions.items()):
            if r.get("source_only"):
                if name not in blobs:
                    blobs[name] = src.plaintext(r["src"], r["src"] + r["len"])
                continue  # no oracle; refs come from the scanner later
            if r["len"] > 0:
                unexplained_by_region[name] = classify_region(name, r)
        # retract discovered shifts whose regions fail validation (a false
        # delta from spurious decodes of variant bytes)
        bad_shifts = set()
        for name in [n for n in regions if n.startswith("aux")]:
            r = regions[name]
            dens = len(unexplained_by_region.get(name, [])) / max(1, r["len"])
            if dens > VARIANT_DENSITY:
                bad_shifts.add(r["shift"])
        if bad_shifts:
            for sname in bad_shifts:
                report.append(f"  RETRACTED shift {sname} "
                              f"({shifts[sname]:+#x}): region failed "
                              f"validation — false discovery")
                blacklist.add(shifts[sname])
                del shifts[sname]
                for name in [n for n, rr in regions.items()
                             if rr["shift"] == sname]:
                    del regions[name]
                    blobs.pop(name, None)
                    unexplained_by_region.pop(name, None)
            continue
        delta, targets = discover_shift(
            {n: o for n, o in unexplained_by_region.items() if o}, blacklist)
        if delta is None:
            break
        # split the referenced targets into clusters (gap >= 0x1000) so only
        # this character's sub-table clusters are extracted, not the whole
        # multi-character span — a pure space optimization (the full span
        # oracle-conforms; the gaps belong to the other newcomers)
        sname = f"aux{len({s for s in shifts if s.startswith('aux')})}"
        shifts[sname] = delta
        ts = sorted(set(targets))
        clusters = [[ts[0], ts[0]]]
        for t in ts[1:]:
            if t - clusters[-1][1] >= 0x1000:
                clusters.append([t, t])
            else:
                clusters[-1][1] = t
        for ci, (ca, cb) in enumerate(clusters):
            start = ca & ~0xF
            end = (cb + 0x400 + 0xF) & ~0xF  # tail margin covers the last
            rname = f"{sname}_{ci}"          # sub-table's sequential content
            regions[rname] = {"src": start, "orc": start + delta,
                              "len": end - start, "kind": "data",
                              "shift": sname}
        report.append(f"  DISCOVERED shift {sname} ({delta:+#x}): "
                      f"{len(targets)} referencing fields, "
                      f"{len(clusters)} cluster regions")

    for name, r in regions.items():
        if r["len"] <= 0:
            continue
        unexplained = unexplained_by_region.get(name, [])
        dens = len(unexplained) / max(1, r["len"])
        report.append(f"  {name}: {len(r.get('refs', []))} pointer fields, "
                      f"{len(unexplained)} variant-site bytes ({dens:.2%})")
        if dens > VARIANT_DENSITY:
            head = ", ".join(f"+0x{i:X}" for i in unexplained[:12])
            fail.append(f"region {name}: unexplained diff density {dens:.1%} "
                        f"({head}...) — misbounded region or unknown pointer "
                        f"form")
        # classify refs: internal / bank_ref (delta-rule R1) / code_neighbor
        # / engine / pcrel16 / escape
        for ref in r.get("refs", []):
            sh = ref["shift"]
            if sh in ("engine", "pcrel16"):
                ref["class"] = sh
                continue
            hosts = [rn for rn, rr in regions.items() if rr["shift"] == sh
                     and rr["src"] <= ref["target"] < rr["src"] + rr["len"]]
            if hosts:
                ref["class"] = "internal"
            elif sh == "bank":
                ref["class"] = "bank_ref"
            elif sh == "code":
                ref["class"] = "code_neighbor"
            elif abs(shifts.get(sh, 1 << 30)) <= ENGINE_ENVELOPE:
                # the delta coincides with a ported-region shift but the
                # target is outside that region: an ordinary engine ref
                # whose sibling-build drift equals the region's shift
                ref["class"] = "engine"
                ref["orc_target"] = ref["target"] + shifts[sh]
                ref["shift"] = "engine"
            else:
                ref["class"] = "escape"
        esc = [ref for ref in r.get("refs", []) if ref["class"] == "escape"]
        others = {}
        for ref in r.get("refs", []):
            if ref["class"] != "internal":
                others[ref["class"]] = others.get(ref["class"], 0) + 1
        if others:
            report.append(f"  {name}: non-internal refs {others}")
        if esc:
            fail.append(f"region {name}: {len(esc)} unresolvable escapes "
                        f"(first +0x{esc[0]['off']:X} -> "
                        f"0x{esc[0]['target']:06X} [{esc[0]['shift']}])")

    # ── code triage scan (semantic labels + same-value refs + charid sites) ──
    for name, r in regions.items():
        if r["kind"] == "code" and r["len"] > 0 and name in blobs:
            sc = scan_code_refs.scan(blobs[name], r["src"])
            r["scan"] = sc
            r["charid_sites"] = [c["off"] for c in sc if c["class"] == "charid"]
            if r["charid_sites"]:
                report.append(f"  {name}: {len(r['charid_sites'])} char-id "
                              f"0x13 immediates (rewritten to the dst slot "
                              f"at generation)")
            if r.get("source_only"):
                # no oracle: relocation fields come from labeled operands
                refs = []
                for c in sc:
                    if c["how"] in ("jsr", "jmp", "pea", "lea", "movea",
                                    "move_src") and c["width"] == 32:
                        tgt = c["target"]
                        hosts = [rn for rn, rr in regions.items()
                                 if rr["len"] > 0
                                 and rr["src"] <= tgt < rr["src"] + rr["len"]]
                        if hosts:
                            cls = "internal"
                        elif tgt < 0x400000:
                            cls = "engine"
                        else:
                            continue  # RAM/HW: no relocation
                        refs.append({"off": c["off"], "width": 32,
                                     "target": tgt, "shift": "engine",
                                     "class": cls})
                r["refs"] = refs
                report.append(f"  {name}: {len(refs)} scanner-derived refs "
                              f"(source-only region)")
    if regions["code"]["len"] > 0:
        code_refs = regions["code"]["scan"]
        # cross-check: every oracle 32-bit code ref should be seen by the scanner
        scanned_offs = {cr["off"] for cr in code_refs}
        missed = [ref for ref in regions["code"]["refs"]
                  if ref["width"] == 32 and ref["off"] not in scanned_offs]
        if missed:
            report.append(f"  code: {len(missed)} oracle fields not labeled by "
                          f"the operand scanner (small-delta/PC-rel or unusual "
                          f"encoding) — first +0x{missed[0]['off']:X}")
        n_rom = sum(1 for cr in code_refs if cr["class"] == "rom")
        n_id = sum(1 for cr in code_refs if cr["class"] == "charid")
        report.append(f"  code scan: {len(code_refs)} candidates, {n_rom} "
                      f"engine/ROM refs (R1 surface), {n_id} char-id 0x13 "
                      f"immediates")

    # ── per-table walk: values, pointers, autos ──────────────────────────────
    for t in tables:
        kind = t["kind"]
        name = t["name"]
        a_s, raw_s = (table_addr(t, origins, src_name) + char * entry_size(t),
                      None)
        raw_s = src.data[a_s:a_s + entry_size(t)]
        a_o = table_addr(t, origins, orc_name) + char * entry_size(t)
        raw_o = orc.data[a_o:a_o + entry_size(t)]
        if kind in ("value32", "value16", "value8", "rec8", "byte2d"):
            rec = {"table": name, "kind": kind, "value": raw_s.hex()}
            if raw_s != raw_o:
                rec["variant_delta"] = raw_o.hex()
                report.append(f"  VARIANT DELTA {name}[{char:#x}]: "
                              f"{src_name}={raw_s.hex()} {orc_name}={raw_o.hex()}")
            values.append(rec)
        elif kind == "data_ptr":
            v = int.from_bytes(raw_s, "big")
            region = t["region"]
            r = regions.get(region)
            inside = r and r["src"] <= v < r["src"] + r["len"]
            values.append({"table": name, "kind": kind, "ptr": f"{v:#x}",
                           "region": region, "inside_region": bool(inside)})
            if not inside:
                fail.append(f"{name}[{char:#x}] = {v:#x} outside extracted "
                            f"region '{region}'")
        elif kind == "code_ptr":
            if not name.startswith("dispatch_"):
                v = int.from_bytes(raw_s, "big")
                values.append({"table": name, "kind": "code_ptr",
                               "ptr": f"{v:#x}"})
            # dispatch_* handled in the dispatch walk above
        elif kind == "auto":
            win_s = src.data[table_addr(t, origins, src_name):
                             table_addr(t, origins, src_name) + t["stride"]]
            win_o = orc.data[table_addr(t, origins, orc_name):
                             table_addr(t, origins, orc_name) + t["stride"]]
            if win_s == win_o:
                auto_findings.append({"table": name, "verdict": "values",
                                      "entry_guess": raw_s.hex()})
            else:
                refs, unexplained = diff_refs(win_s, win_o, shifts, False)
                auto_findings.append({
                    "table": name,
                    "verdict": "pointers" if refs and not unexplained
                    else "UNRESOLVED",
                    "refs": refs, "unexplained": len(unexplained)})

    # ── outputs ──────────────────────────────────────────────────────────────
    for name, blob in blobs.items():
        (out / f"region_{name}.bin").write_bytes(blob)
    manifest = {
        "src_set": src_name, "oracle_set": orc_name, "char": f"{char:#x}",
        "input_sha1s": {**src.sha1s},
        "shifts": {k: v for k, v in shifts.items()},
        "regions": {name: {**{k: v for k, v in r.items() if k != "scan"},
                           "sha1": hashlib.sha1(blobs[name]).hexdigest()
                           if name in blobs else None}
                    for name, r in regions.items() if r["len"] > 0},
        "code_scan": regions["code"].get("scan", []),
        "dispatch": [{"table": tn, "src_target": v_s, "orc_target": v_o}
                     for tn, v_s, v_o in disp],
        "engine_dispatch": engine_dispatch,
        "values": values,
        "auto_tables": auto_findings,
    }
    (out / "regions.json").write_text(json.dumps(manifest, indent=1))
    rpt = "\n".join(report)
    (out / "report.txt").write_text(rpt + "\n")
    print(rpt)

    n_unres = sum(1 for a in auto_findings if a["verdict"] == "UNRESOLVED")
    print(f"\nvalues: {len(values)} rows; engine dispatch entries: "
          f"{len(engine_dispatch)}; auto tables: {len(auto_findings)} "
          f"({n_unres} UNRESOLVED)")
    if fail:
        print("\nEXTRACTION FAILED:")
        for f in fail:
            print(f"  {f}")
        sys.exit(1)
    print("EXTRACTION OK (oracle-validated)")


if __name__ == "__main__":
    main()
