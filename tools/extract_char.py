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

# hard anchors (docs/atlas/character_tables.md; measured 14z-65) — asserted
# per (src_set, char). An extraction for a char with NO anchor row hard-fails:
# unanchored extraction is silent-drift territory (the DONOVAN_ANCHORS gap —
# every other char used to run with no assertion at all).
CHAR_ANCHORS = {
    ("vsav2", 0x10): {"dispatch_00": 0x057450, "hitbox_base": 0x0C4370,
                      "anim_index_a": 0x245872},
    ("vsav2", 0x11): {"dispatch_00": 0x059424, "hitbox_base": 0x0C75FE,
                      "anim_index_a": 0x264086},
    ("vsav2", 0x13): {"dispatch_00": 0x05AE20, "hitbox_base": 0x0C8DF8,
                      "anim_index_a": 0x27F548},
}


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


def diff_refs(a_blob, b_blob, shifts, allow_engine, selfptr=None):
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
        if site is None and selfptr:
            # self-contained data region: any pointer landing inside the
            # region (in BOTH games' coordinates) relocates by the region
            # delta regardless of cross-game micro-shifts between sub-blobs
            sname, a_lo, a_hi, b_lo, b_hi = selfptr
            for width, span in ((24, 3), (32, 4)):
                for off in range(max(0, i - span + 1),
                                 min(i, len(a_blob) - span) + 1):
                    va = int.from_bytes(a_blob[off:off + span], "big")
                    vb = int.from_bytes(b_blob[off:off + span], "big")
                    if va != vb and a_lo <= va < a_hi and b_lo <= vb < b_hi:
                        site = {"off": off, "width": width, "target": va,
                                "orc_target": vb, "shift": sname}
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


def segmented_data_refs(a_img, b_img, a0, b0, length, sname, shifts):
    """Gap-tolerant oracle diff for multi-blob asset regions: sub-blobs sit
    at slightly different relative offsets across the sibling games
    (insertions), so a linear diff loses alignment at the first insertion.
    Walk in chunks; when unexplained density spikes, RESYNC by searching the
    oracle image for the next 32-byte exact match within +-0x2000. Returns
    (refs, segments, dead_zones). Pointer fields are classified with the
    selfptr rule (both values inside the family windows)."""
    refs, segments, dead = [], [], []
    a_off = 0
    b_delta = 0     # oracle position for a-offset X = b0 + X + b_delta
    seg_start = 0
    CH = 0x100
    sp = (sname, a0, a0 + length + 0x2000, b0 - 0x2000, b0 + length + 0x4000)
    while a_off < length:
        n = min(CH, length - a_off)
        ca = a_img[a0 + a_off:a0 + a_off + n]
        cb = b_img[b0 + a_off + b_delta:b0 + a_off + b_delta + n]
        if len(cb) < n:
            break
        c_refs, unex = diff_refs(ca, cb, shifts, False, sp)
        if len(unex) <= max(4, n // 20):
            for ref in c_refs:
                ref["off"] = ref["off"] + a_off
                refs.append(ref)
            a_off += n
            continue
        # alignment wall: resync at the next 32-byte exact match
        segments.append((seg_start, a_off + unex[0], b_delta))
        found = False
        for probe in range(unex[0], min(unex[0] + 0x1000, length - a_off - 32), 4):
            pat = a_img[a0 + a_off + probe:a0 + a_off + probe + 32]
            center = b0 + a_off + probe + b_delta
            pos = b_img.find(pat, max(0, center - 0x2000), center + 0x2000)
            if pos != -1:
                dead.append((a_off, a_off + probe))
                a_off += probe
                b_delta = pos - (b0 + a_off)
                seg_start = a_off
                found = True
                break
        if not found:
            dead.append((a_off, length))
            a_off = length
            break
    segments.append((seg_start, a_off, b_delta))
    return refs, segments, dead


FILLER_MAX = 0x20  # dead inter-routine debris never measured larger


def _ends_flow_out(buf, pos):
    """True when the bytes before pos end an unconditional flow-out — the
    only place dead inter-routine filler can legally start. Checked in BOTH
    images before tolerating a filler run (14z-65)."""
    if pos >= 6 and buf[pos - 6:pos - 4] == b"\x4e\xf9":      # jmp abs.l
        return True
    if pos >= 4 and buf[pos - 4:pos - 2] == b"\x60\x00":      # bra.w
        return True
    if pos >= 2:
        w = buf[pos - 2:pos]
        if w in (b"\x4e\x75", b"\x4e\x73"):                   # rts / rte
            return True
        if w[0] == 0x60 and w[1] != 0x00:                     # bra.s
            return True
        if w[0] == 0x4e and 0xD0 <= w[1] <= 0xD7:             # jmp (An)
            return True
    return False


def oracle_extend(a_img, a_start, b_img, b_start, cap, shifts, allow_engine,
                  selfptr=None, filler_dead=None):
    """Region length by oracle coverage: extend chunk-by-chunk while the diff
    classifier explains (almost) every differing byte — shared character
    data stays explainable under the known shifts even where pointer-dense
    (anim scripts); the two games' unrelated surroundings do not. Trims
    trailing uniform padding.

    filler_dead (code regions only, 14z-65): pass a list to enable DEAD
    INTER-ROUTINE FILLER tolerance. The sibling builds carry junk debris
    between routines that differs in content (Pyron: 12 bytes at
    PRG:0x0576F4 after two jmps, code resuming byte-identical) — each such
    run aborted the scan. A failing chunk is tolerated ONLY when its
    unexplained bytes form one short run (<= FILLER_MAX) that starts right
    after an unconditional flow-out in BOTH images AND the chunk re-diffs
    clean with the run masked (so a misalignment wall — the piecewise-shift
    boundary — still stops the scan at the chunk floor, exactly as before:
    the frozen Donovan extraction is bit-identical by construction). Runs
    are appended to filler_dead as (start, end) region-relative offsets."""
    length = 0
    MARGIN = 8  # so pointer fields spanning a chunk edge classify correctly
    while length < cap:
        lo = max(0, length - MARGIN)
        hi = length + SIM_CHUNK + MARGIN
        ca = a_img[a_start + lo:a_start + hi]
        cb = b_img[b_start + lo:b_start + hi]
        if len(ca) < (hi - lo) or len(cb) < (hi - lo):
            break
        _, unexplained = diff_refs(ca, cb, shifts, allow_engine, selfptr)
        core = [i for i in unexplained
                if (length - lo) <= i < (length - lo) + SIM_CHUNK]
        if len(core) > SIM_CHUNK // 50:  # >2% unexplained -> out of region
            if filler_dead is None:
                break
            rs, re_ = core[0], core[-1] + 1
            if (re_ - rs > FILLER_MAX
                    or not _ends_flow_out(ca, rs)
                    or not _ends_flow_out(cb, rs)):
                break
            cb2 = bytearray(cb)
            cb2[rs:re_] = ca[rs:re_]  # mask the run; re-verify the rest
            _, unex2 = diff_refs(ca, bytes(cb2), shifts, allow_engine,
                                 selfptr)
            core2 = [i for i in unex2
                     if (length - lo) <= i < (length - lo) + SIM_CHUNK]
            if len(core2) > SIM_CHUNK // 50:
                break  # misalignment wall, not filler
            filler_dead.append((lo + rs, lo + re_))
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
    anchors = CHAR_ANCHORS.get((src_name, char))
    if anchors is None:
        fail.append(f"no anchor row for ({src_name}, {char:#x}) — measure "
                    f"dispatch_00/hitbox_base/anim_index_a and add it to "
                    f"CHAR_ANCHORS (unanchored extraction is not allowed)")
    else:
        for tname, want in anchors.items():
            got = src.u32(table_addr(tab[tname], origins, src_name) + char * 4)
            if got != want:
                fail.append(f"ANCHOR {tname}[{char:#x}] = {got:#x}, "
                            f"expected {want:#x}")
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
        if rname == "hitbox_proj":
            # next-ptr has no upper neighbor for the last character and falls
            # back to +0x4000; the REAL structure is compact (base sub-table
            # offsets top out at +0x5A, comp strides at +0x400 — measured
            # session 5). Cap at 0x1000 (2x margin); projectile-behavior
            # gates verify sufficiency.
            s1 = min(s1, s0 + 0x1000)
        regions[rname] = {"src": s0, "orc": s0 + shifts["bank"],
                          "len": s1 - s0, "kind": "data", "shift": "bank"}

    # anim: seeded at anim_index_a[char]; initial oracle scan, then grown to
    # closure over forward escapes in the classification pass below
    alen = oracle_extend(src.data, an_s, orc.data, an_o, ANIM_CAP, shifts, False)
    regions["anim"] = {"src": an_s, "orc": an_o, "len": alen, "grow": ANIM_CAP,
                       "kind": "data", "shift": "anim"}

    # code: span of in-window dispatch targets, similarity-extended (plaintext)
    # (every code_ptr dispatch table in the bank map — was a hardcoded
    # range(14) until dispatch_14 was resolved from gap_bd7fa, 2026-07-27)
    #
    # 14z-65: the appended window's sibling shift is PIECEWISE (measured
    # +0x36 / +0x30 / +0x34 stretches — routines separated by junk filler
    # whose LENGTH drifts between the builds), so a single-shift scan dies
    # at the first stretch boundary (Huitzil) and a filler run aborts it
    # outright (Pyron). Targets are grouped by their own dispatch-pair local
    # shift (v_o - v_s: free per-target ground truth). The group containing
    # dispatch_00 is THE "code" region — for a single-group char (Donovan)
    # this degenerates to exactly the old behavior, byte-identical. Every
    # other group becomes an extra-root-style region x<start> with its own
    # shift name; cross-group refs then classify against those regions with
    # the existing hosts machinery, and a manifest layout_group preserves
    # their source-relative spacing at placement.
    disp = []
    for tn in sorted(n for n in tab if n.startswith("dispatch_")):
        v_s = src.u32(table_addr(tab[tn], origins, src_name) + char * 4)
        v_o = orc.u32(table_addr(tab[tn], origins, orc_name) + char * 4)
        if NEWCOMER_CODE[0] <= v_s < NEWCOMER_CODE[1]:
            disp.append((tn, v_s, v_o))
        else:
            engine_dispatch.append({"table": tn, "src_target": v_s,
                                    "orc_target": v_o, "delta": v_o - v_s})
    if not disp:
        fail.append("no dispatch targets in the newcomer code window")
        regions["code"] = {"src": 0, "orc": 0, "len": 0, "grow": CODE_CAP,
                           "kind": "code", "shift": "code"}
    else:
        groups = {}
        for tn, v_s, v_o in disp:
            groups.setdefault(v_o - v_s, []).append((tn, v_s))
        spans = sorted((min(v for _, v in g), max(v for _, v in g), d)
                       for d, g in groups.items())
        for (s1, e1, d1), (s2, e2, d2) in zip(spans, spans[1:]):
            if e1 >= s2:
                fail.append(f"dispatch shift groups interleave: "
                            f"[{s1:#x},{e1:#x}]{d1:+#x} vs "
                            f"[{s2:#x},{e2:#x}]{d2:+#x} — window model wrong")
        start_override = None
        for idx, (gstart, gend, gdelta) in enumerate(spans):
            is_primary = any(tn == "dispatch_00" for tn, _ in groups[gdelta])
            if start_override is not None:
                start = start_override
                start_override = None
            else:
                start = (gstart & ~0xF) if is_primary else gstart
            twin = start + gdelta
            rname = "code" if is_primary else f"x{start:06x}"
            shname = "code" if is_primary else rname
            if not is_primary:
                shifts[shname] = gdelta
            nxt = spans[idx + 1] if idx + 1 < len(spans) else None
            cap = min(CODE_CAP, nxt[0] - start) if nxt else CODE_CAP
            dead = []
            ins = []
            pt_s = src.plaintext(start, min(start + cap + 0x300, 0x100000))
            pt_o = orc.plaintext(twin, min(twin + cap + 0x300, 0x100000))
            clen = oracle_extend(pt_s, 0, pt_o, 0, cap, shifts, True,
                                 filler_dead=dead)
            span_need = gend - start
            if clen <= span_need or (nxt and clen < nxt[0] - start):
                # The floor scan stopped short — find the true wall (first
                # genuinely unexplained byte), then resolve what it is.
                win = min(max(span_need, clen) + 0x300, len(pt_s), len(pt_o))
                _, unex = diff_refs(pt_s[:win], pt_o[:win], shifts, True)
                wall = next((u for u in unex if u >= clen
                             and not any(a0 <= u < b0 for a0, b0 in dead)),
                            None)
                if wall is not None and nxt is not None:
                    # SIBLING-INSERTION BOUNDARY (14z-65, measured on
                    # Huitzil: vs2's handler head carries a 6-byte
                    # jsr $8ACD8 its vh2 twin lacks — the +0x36 -> +0x30
                    # transition). Walk forward from the wall probing the
                    # NEXT group's delta; the first position that
                    # classifies clean under it starts that group's
                    # region, and the un-twinned sliver [wall, p) stays in
                    # THIS region as source-only insertion bytes (their
                    # refs ride the operand scanner / same-value merge).
                    nd = nxt[2]
                    p_found = None
                    for p in range(wall & ~1, min(nxt[0] - start,
                                                  wall + 0x100), 2):
                        ob = orc.plaintext(start + p + nd,
                                           start + p + nd + 0x48)
                        # strict: p is an instruction START in both builds
                        # (same opcode word) and every diff in the probe
                        # window classifies — a lax probe accepted the wall
                        # itself via spurious engine/pcrel decodes
                        if pt_s[p:p + 2] != ob[:2]:
                            continue
                        _, u2 = diff_refs(pt_s[p:p + 0x40], ob[:0x40],
                                          {**shifts, "_next": nd}, True)
                        if not u2:
                            p_found = p
                            break
                    if p_found is not None:
                        ins.append((wall, p_found))
                        report.append(
                            f"  {rname}: sibling-insertion boundary at "
                            f"+{wall:#x} — {p_found - wall} source-only "
                            f"bytes, next group starts {start + p_found:#x} "
                            f"(delta {nd:+#x})")
                        clen = p_found
                        start_override = start + p_found
                elif wall is not None and wall > span_need:
                    # wall-precise tail (no next group): take the region to
                    # the true wall. Fires only when the floor result fails
                    # coverage, so Donovan is byte-identical by construction.
                    report.append(f"  {rname}: wall-precise tail "
                                  f"+{clen:#x} -> +{wall & ~1:#x}")
                    clen = wall & ~1
            if clen <= span_need:
                fail.append(f"{rname}: code similarity scan ended at "
                            f"+{clen:#x}, before the group's last dispatch "
                            f"target (+{span_need:#x})")
            regions[rname] = {"src": start, "orc": twin, "len": clen,
                              "grow": cap, "kind": "code", "shift": shname,
                              "dead": dead, "ins": ins}
            if dead:
                report.append(f"  {rname}: {len(dead)} dead filler zone(s), "
                              f"{sum(b0 - a0 for a0, b0 in dead):#x} bytes "
                              f"({', '.join(f'+{a0:#x}' for a0, b0 in dead)})")
            if not is_primary:
                report.append(f"  code shift group {shname}: "
                              f"{len(groups[gdelta])} dispatch targets, "
                              f"local shift {gdelta:+#x}")
        if "code" not in regions:
            fail.append("dispatch_00's shift group missing — no primary "
                        "code region (bank map / window model wrong)")
            regions["code"] = {"src": 0, "orc": 0, "len": 0,
                               "grow": CODE_CAP, "kind": "code",
                               "shift": "code"}

    # extra code roots: absent-in-vsavj support routines. Spec per root:
    #   addr           twin by masked pattern search, oracle-bounded
    #   addr:len       same, but length capped/fixed to len
    #   addr:len:tX    forced oracle twin at X
    #   addr:len:tX:d  DATA region (raw view, An-relative reads) with twin X
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
        is_data = len(parts) > 3 and parts[3] == "d"
        if len(parts) > 2 and parts[2].startswith("t"):
            forced_twin = int(parts[2][1:], 0)
        if is_data:
            sh_name = f"x{root:06x}"
            shifts[sh_name] = forced_twin - root
            shifts[sh_name] = forced_twin - root
            xrefs, segs, deadz = segmented_data_refs(
                src.data, orc.data, root, forced_twin, fixed_len,
                sh_name, shifts)
            regions[sh_name] = {"src": root, "orc": forced_twin,
                                "len": fixed_len, "kind": "data",
                                "shift": sh_name, "pre_classified": True,
                                "refs": xrefs, "variant_sites": []}
            report.append(f"extra region {sh_name}: DATA (segmented oracle), "
                          f"twin 0x{forced_twin:06X}, len 0x{fixed_len:X}, "
                          f"{len(xrefs)} pointer fields, {len(segs)} segments, "
                          f"{len(deadz)} dead zones "
                          f"({sum(b-a for a,b in deadz):#x} bytes unaligned)")
            continue
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
        for ref in scan_code_refs.scan(pat, root, charid=char):
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
            sp = None
            if r.get("selfptr"):
                g = r.get("grow", r["len"])
                sp = (r["shift"], r["src"], r["src"] + g,
                      r["orc"], r["orc"] + g)
            refs, unexplained = diff_refs(a, b, shifts, r["kind"] == "code", sp)
            # dead filler zones (14z-65): junk debris between routines,
            # identified at bounding time under the flow-out rule. Refs
            # decoded from junk bytes are fake pointers (the bare-long
            # masquerade class) and unexplained junk is not a flavor site.
            dz = r.get("dead") or []
            # insertion slivers (14z-65): source-only bytes with no oracle
            # twin — diff-derived "refs" inside them are spurious decodes;
            # their REAL refs come from the operand scanner + same-value
            # merge. Their diff bytes stay out of the variant-site report
            # too (they are already reported as insertions).
            iz = r.get("ins") or []
            if dz or iz:
                refs = [ref for ref in refs
                        if not any(a0 <= ref["off"] < b0
                                   for a0, b0 in dz + iz)]
                unexplained = [i for i in unexplained
                               if not any(a0 <= i < b0 for a0, b0 in dz + iz)]
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
            if r.get("source_only") or r.get("pre_classified"):
                if name not in blobs and r["len"] > 0:
                    blobs[name] = (src.plaintext(r["src"], r["src"] + r["len"])
                                   if r["kind"] == "code"
                                   else src.data[r["src"]:r["src"] + r["len"]])
                continue  # refs come from the scanner / segmented oracle
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
            end = (cb + 0x180 + 0xF) & ~0xF  # tail margin covers the last
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
            sc = scan_code_refs.scan(blobs[name], r["src"], charid=char)
            r["scan"] = sc
            r["charid_sites"] = [c["off"] for c in sc if c["class"] == "charid"]
            if not r.get("source_only") and not r.get("pre_classified"):
                # SAME-VALUE ENGINE REFS (session 12, the mash-wedge root
                # cause): vs2 and vhunt2 are sibling builds — engine
                # operands that COINCIDE across them are invisible to the
                # sibling diff, yet vsavj's layout drifted (the ported
                # meter code's jsr 0x3B2C hit a DIFFERENT vsavj farm entry
                # at the coincident address). Merge scanner-LABELED
                # engine/ROM operands (never bare longs) not already
                # covered by diff-derived refs — each then needs a
                # reconciliation row or rides a loud tripwire.
                have = set()
                for ref in r.get("refs", []):
                    have.update(range(ref["off"], ref["off"] + ref["width"] // 8))
                added = 0
                for c in sc:
                    if (c["width"] == 32 and c["class"] == "rom"
                            and c["how"] in ("jsr", "jmp", "pea", "lea",
                                             "movea", "move_src")
                            and c["off"] not in have
                            and (c["off"] + 3) not in have):
                        r.setdefault("refs", []).append(
                            {"off": c["off"], "width": 32,
                             "target": c["target"], "shift": "engine",
                             "class": "engine"})
                        added += 1
                if added:
                    report.append(f"  {name}: {added} same-value engine "
                                  f"refs merged from the scanner (sibling-"
                                  f"coincident operands)")
            if r["charid_sites"]:
                report.append(f"  {name}: {len(r['charid_sites'])} char-id "
                              f"{char:#x} immediates (rewritten to the dst "
                              f"slot at generation)")
            if r.get("source_only"):
                # PC-relative escapes: brief-format word-table dispatches
                # (jsr/jmp (d8,PC,Xn)) and direct (d16,PC) control flow whose
                # SOURCE targets leave the region. Their displacements are
                # identical across sibling games (spacing preserved there),
                # so neither oracle nor abs-scanner sees them; the generator
                # rewrites each entry against the actual placement (kind
                # pcrel_tblent / pcrel_d16), tripwiring unresolved ones.
                blob = blobs[name]
                pcrel_refs = []
                table_spans = []
                for off in range(0, r["len"] - 4, 2):
                    w = int.from_bytes(blob[off:off + 2], "big")
                    if w in (0x4EBB, 0x4EFB):  # jsr/jmp (d8,PC,Xn)
                        ext = int.from_bytes(blob[off + 2:off + 4], "big")
                        d8 = ext & 0xFF
                        if d8 >= 0x80:
                            continue
                        base = off + 2 + d8
                        # a dispatch table cannot extend past its own
                        # smallest forward target (the case code follows the
                        # table) — bound entries by that invariant so code
                        # words are never misread as entries
                        k = 0
                        bound = 64 * 2
                        ents = []
                        while k * 2 < bound and base + k * 2 + 2 <= r["len"]:
                            v = int.from_bytes(blob[base + k * 2:base + k * 2 + 2],
                                               "big", signed=True)
                            tgt = r["src"] + base + v
                            if v == 0 or not (0x010000 <= tgt < 0x400000):
                                break
                            if 0 < v < bound:
                                bound = v
                            if k * 2 >= bound:
                                break
                            ents.append((k, tgt))
                            k += 1
                        # the whole table extent is DATA (protect it from
                        # the bare-long heuristic), even the entries that
                        # stay in-region
                        n_ent = min(len(ents), max(1, bound // 2))
                        table_spans.append((base, base + n_ent * 2))
                        for k, tgt in ents[:n_ent]:
                            if not (r["src"] <= tgt < r["src"] + r["len"]):
                                pcrel_refs.append({"kind": "pcrel_tblent",
                                                   "off": base + k * 2,
                                                   "base_off": base,
                                                   "target": tgt})
                    elif w in (0x4EBA, 0x4EFA):  # jsr/jmp (d16,PC)
                        v = int.from_bytes(blob[off + 2:off + 4], "big",
                                           signed=True)
                        tgt = r["src"] + off + 2 + v
                        if 0x010000 <= tgt < 0x400000 and not (
                                r["src"] <= tgt < r["src"] + r["len"]):
                            pcrel_refs.append({"kind": "pcrel_d16",
                                               "off": off + 2,
                                               "base_off": off + 2,
                                               "target": tgt})
                r["pcrel_refs"] = pcrel_refs
                # word-table extents are DATA, not pointers: the bare-long
                # heuristic must never rewrite inside them (it fused two
                # adjacent word entries into a bogus 32-bit pointer and
                # corrupted a dispatch table — session 6)
                tbl_bytes = set()
                for ts, te in table_spans:
                    tbl_bytes.update(range(ts, te))
                for p_ in pcrel_refs:
                    tbl_bytes.update(range(p_["base_off"], p_["off"] + 2))
                r["table_bytes"] = sorted(tbl_bytes)
                if pcrel_refs:
                    ext_t = len({p_["target"] for p_ in pcrel_refs})
                    report.append(f"  {name}: {len(pcrel_refs)} PC-rel escape "
                                  f"entries ({ext_t} distinct targets) — "
                                  f"rewritten per placement, unresolved -> "
                                  f"tripwire")
                # no oracle: relocation fields come from labeled operands.
                # bare longs (unlabeled 32-bit ROM values, e.g. inline data
                # pointers) are included ONLY when they point inside an
                # extracted region — but instruction operand pairs like
                # `clr.b $6(a6); moveq #0,d0` (bytes 0006 7000) masquerade
                # as such pointers and a rewrite corrupts the code (paid:
                # session 7, docs/GOTCHAS.md). SIBLING VETO: locate the
                # candidate's context (exact bytes around a wildcarded
                # long) in the sibling build; a REAL pointer into a moved
                # region must differ there by that region's sibling shift,
                # while accidental operand bytes are identical. Only
                # divergent zones (no sibling context) stay unverified.
                orc_win_lo = max(0, r["src"] - 0x4000)
                orc_win = orc.plaintext(
                    orc_win_lo,
                    min(0x100000, r["src"] + r["len"] + 0x4000))
                blob_l = blobs[name]
                # context comparisons must wildcard LABELED 32-bit ref
                # fields (engine operands drift between siblings and would
                # defeat an exact-context match right next to a jsr/jmp).
                # Other bare-long candidates stay hard context: they are
                # mostly operand bytes (the point of the veto), and
                # wildcarding them shreds the anchor in candidate-dense
                # stretches, silently downgrading the verdict to unverified.
                wild = set(tbl_bytes)
                for c_ in sc:
                    if c_["width"] == 32 and c_["how"] != "bare_long":
                        wild.update(range(c_["off"], c_["off"] + 4))

                def sibling_longs_exact(off):
                    """Sibling longs at exact-context matches (8 bytes each
                    side, no wildcards) — succeeds when no other ref field
                    sits nearby."""
                    pre_n = min(8, off)
                    post_n = min(8, len(blob_l) - off - 4)
                    if pre_n + post_n < 8:
                        return None
                    pre = bytes(blob_l[off - pre_n:off])
                    post = bytes(blob_l[off + 4:off + 4 + post_n])
                    vals, p = [], 0
                    while len(vals) < 8:
                        p = orc_win.find(pre, p) if pre_n else -1
                        if p == -1:
                            break
                        q = p + pre_n
                        if orc_win[q + 4:q + 4 + post_n] == post:
                            vals.append(int.from_bytes(orc_win[q:q + 4],
                                                       "big"))
                        p += 1
                    return vals or None

                def sibling_longs_masked(off):
                    """Sibling longs at masked-context matches (longest hard
                    run as anchor, other ref fields wildcarded) — for
                    candidates sitting next to drifting engine operands."""
                    lo = max(0, off - 12)
                    hi = min(len(blob_l), off + 16)
                    win = blob_l[lo:hi]
                    mask = [i + lo not in wild and not (off <= i + lo < off + 4)
                            for i in range(len(win))]
                    # longest run of hard (non-wildcard) bytes
                    best, cur = (0, 0), None
                    for i, m in enumerate(mask + [False]):
                        if m and cur is None:
                            cur = i
                        elif not m and cur is not None:
                            if i - cur > best[0]:
                                best = (i - cur, cur)
                            cur = None
                    if best[0] < 6:
                        return None  # not enough hard context to anchor
                    anchor = bytes(win[best[1]:best[1] + best[0]])
                    vals, p = [], 0
                    while len(vals) < 8:
                        p = orc_win.find(anchor, p)
                        if p == -1:
                            break
                        base_ = p - best[1]
                        if 0 <= base_ <= len(orc_win) - len(win):
                            if all(orc_win[base_ + i] == win[i]
                                   for i in range(len(win)) if mask[i]):
                                q = base_ + (off - lo)
                                vals.append(int.from_bytes(
                                    orc_win[q:q + 4], "big"))
                        p += 1
                    return vals or None

                def sibling_longs(off):
                    return (sibling_longs_exact(off)
                            or sibling_longs_masked(off))

                refs = []
                n_conf = n_veto = n_amb = n_unver = 0
                for c in sc:
                    if c["width"] != 32:
                        continue
                    tgt = c["target"]
                    hosts = [rn for rn, rr in regions.items()
                             if rr["len"] > 0
                             and rr["src"] <= tgt < rr["src"] + rr["len"]]
                    if c["how"] in ("jsr", "jmp", "pea", "lea", "movea",
                                    "move_src"):
                        if hosts:
                            cls = "internal"
                        elif tgt < 0x400000:
                            cls = "engine"
                        else:
                            continue  # RAM/HW: no relocation
                    elif c["how"] == "movea_imm":
                        # movea.l #imm,An loads an ADDRESS by construction:
                        # hosted -> relocate; un-hosted ROM address -> an
                        # ENGINE-shared table/structure needing an R1 row
                        # (session 11: the type-114 effect's shared anim
                        # table 0x1D7428 was silently carried raw and
                        # faulted on the mash soak). RAM/HW targets skip.
                        if hosts:
                            cls = "internal"
                        elif tgt < 0x400000:
                            cls = "engine"
                        else:
                            continue
                    elif c["how"] == "move_imm":
                        # move.l #imm,Dn may be a CONSTANT — hosted only,
                        # never fabricate engine refs from data values
                        if not hosts:
                            continue
                        cls = "internal"
                    elif c["how"] == "bare_long" and hosts:
                        if any(q in tbl_bytes
                               for q in range(c["off"], c["off"] + 4)):
                            continue  # inside a PC-rel word table
                        exp = shifts.get(regions[hosts[0]]["shift"])
                        sib = sibling_longs(c["off"])
                        if sib is not None and exp is not None:
                            # identical evidence dominates: generic context
                            # anchors can also hit unrelated sites, and a
                            # single spurious shift-consistent hit must not
                            # outvote the true twin (paid: 0x8AA06)
                            if all(v == tgt for v in sib):
                                n_veto += 1
                                continue  # sibling-identical: operand bytes
                            elif all(v == tgt + exp for v in sib):
                                n_conf += 1
                            else:
                                n_amb += 1
                                continue  # conflicting sibling evidence
                        else:
                            # no sibling context and not a labeled operand:
                            # with imm loads labeled above, what remains is
                            # overwhelmingly operand bytes — REJECT, loudly
                            n_unver += 1
                            continue
                        cls = "internal"
                    else:
                        continue
                    refs.append({"off": c["off"], "width": 32,
                                 "target": tgt, "shift": "engine",
                                 "class": cls})
                r["refs"] = refs
                report.append(f"  {name}: {len(refs)} scanner-derived refs "
                              f"(source-only region); bare longs: "
                              f"{n_conf} sibling-confirmed, {n_veto} vetoed "
                              f"(operand bytes), {n_amb} rejected "
                              f"(conflicting evidence), {n_unver} rejected "
                              f"(divergent zone, unlabeled)")
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
                      f"engine/ROM refs (R1 surface), {n_id} char-id "
                      f"{char:#x} immediates")

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
