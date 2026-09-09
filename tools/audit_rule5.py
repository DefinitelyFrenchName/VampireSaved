#!/usr/bin/env python3
"""audit_rule5.py — the rule-5 census (living-docs L2, 14z-141).

CLAUDE.md rule 5: "Behavioral values live in documented tables, not in code."
This tool measures how far that holds. Every scalar literal in the canonical
manifests, and every module-level constant in the generators, is classified

    IN-TABLE  a hand-written docs/project/tables/ row carries the value
    DERIVED   computed at build time from a source (orc/src, or a named
              computation in the attributed provenance)
    BAKED     it exists only here

in three columns: `gameplay` (rule 5's obligation), `fact` (what a rebuild
needs), `code` (the generators). The ratio is reported as NOTE-class numbers,
never a verdict. `--freeze`/`--check` lock the BAKED inventory so it can only
SHRINK.

WHAT THE MEASUREMENT TAUGHT THIS TOOL (14z-141, scope doc section 10.3):
  - the canon has SUBDIRECTORIES, and `overlay.wip/` is tracked but INERT
    (`2b8fd827` renamed `overlay/` at the 14s revert; build_donovan.sh:466
    still guards on the old path). EXCLUDED by ruling — 10,110 scalars, 48%
    of the pre-exclude census, all of it a parked experiment.
  - provenance is attached to PARAGRAPHS, not to values: 4,566 standalone
    comment lines against 237 trailing. Reading the value's own line sees
    ~5% of it, so this scanner attributes comment BLOCKS.
  - a block can be a RETRACTION ("RETIRED 14z-91", "NEVER APPLIED",
    "REVERT"). Attaching it to the row beneath would hand a live row the
    provenance of a withdrawn one — [VSP-13]'s failure mode inside a tool.
  - JSON has no comments, so this tree invented `_comment`/`_who`/`_src`
    keys. They are provenance, not values.
  - rule 5's four categories: damage, timings and meter travel as ROM DATA
    REGIONS and are never re-typed here, but VARIANT SELECTION is, and it is
    the gameplay column (ruled 2026-09-07). It is a BOOLEAN, so this tool
    does not restrict itself to numeric literals.

Usage:
    python3 tools/audit_rule5.py --report
    python3 tools/audit_rule5.py --keys
    python3 tools/audit_rule5.py --freeze tests/expected/rule5_baked.tsv
    python3 tools/audit_rule5.py --check  tests/expected/rule5_baked.tsv
    python3 tools/audit_rule5.py --selftest
    (--root DIR runs the whole census over a copy — how the gate's controls work)
"""
import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

MANIFEST_DIR = "build/manifest"

# --- the canon --------------------------------------------------------------
# Not a glob: `git ls-files` so the untracked probe_*.toml drop out by
# construction (they are copies of the tenant manifests and would inflate six
# of nine table kinds — measured 14z-141).
EXCLUDE_NAMES = {".keep", "moves_TEMPLATE.toml"}
# probe_*.toml are UNTRACKED copies of the tenant manifests used for one-off
# probes. `git ls-files` drops them by construction in the tree - but --root
# runs on a plain directory where the fallback walk would pick them up, and a
# tool whose two paths disagree is a tool that measures something different in
# a test than in production. So the exclusion is EXPLICIT (found by the gate's
# own control, 14z-141).
EXCLUDE_GLOBS = ("probe_*.toml",)
EXCLUDE_DIRS = {
    # RULED 2026-09-07. Tracked, deliberately inert: `2b8fd827` ("round 16:
    # overlay reverted") renamed overlay/ -> overlay.wip/, and
    # tools/build_donovan.sh:466 still tests the OLD path, so the guard can
    # never fire. Carries 10,204 of the 21,218 pre-exclude scalars.
    "overlay.wip",
}

GENERATORS = ["gen_donovan_patch.py", "select_port.py", "build_gfx_donovan.py",
              "build_qs_songs.py", "gen_anita_bank2.py", "overlay_port.py"]

# --- the judgement table ----------------------------------------------------
# GAMEPLAY is rule 5's obligation. Measured 14z-141: of 389 (kind, key) pairs
# exactly one has a behavioural NAME, because this port moves damage/timing/
# meter as ROM data regions. What IS here is rule 5's fourth named category,
# VARIANT SELECTION — which slot a row applies to, and which roster cell
# reaches it.
GAMEPLAY_KEYS = {
    "only_variant_slot",  # the superset invariant per row: tenant slot only
    "only_base_slot",     # its twin
    "id_by_profile",      # which id the tenant takes, per profile
    "dst_slot",           # the destination roster slot
    "mirror_variant",     # the mirror-match variant
    "roster_subst",       # a thunk that substitutes a roster entry
    "layout",             # [[select_wheel]].layout -> the adjacency JSON
}
GAMEPLAY_PAIRS = {("tenant", "id")}          # the tenant's roster id
BY_ADDRESS = {("aux_poke", "val")}           # classified by TARGET, never by key

# [[aux_poke]].val is judged by where it WRITES (ruled 2026-09-07). Every band
# is measured and cited; a poke outside all of them is UNCLASSIFIED, so a newly
# authored gameplay poke cannot pass as FACT by reusing an existing key.
AUX_POKE_BANDS = [
    (0x01C800, 0x01C830, "FACT",
     "the boot NAME SCREEN (14z-130, Japan entry only) - cosmetic"),
    (0x028D40, 0x028D60, "GAMEPLAY",
     "the hit-class / guard-MASH RNG mask table - docs/game/atlas/ram.md:156 "
     "documents PRG:0x028D50 as the mash chance table (3: 8/32, 4: 16/32, "
     "5: 24/32, 6+: always); the manifests name the same bytes "
     "`hit_class_props_ext_*` and `effect_map_*`. THREE NAMES FOR ONE "
     "ADDRESS, two of them ours - unresolved 14z-141, needs measurement"),
    (0x089800, 0x089980, "FACT",
     "the HUD mugshot and name tables - cosmetic"),
    (0x5FF000, 0x600000, "FACT",
     "the voice-alias thunk in the WIDE extension - sound"),
]

# Every (kind, key) pair MEASURED in the canon at 14z-141. A pair that is
# not here is UNCLASSIFIED and FAILS the gate: a NEW key must be looked at
# by a person before the census can speak for it. Without this the default
# would be `fact`, and a newly authored gameplay value would pass in
# silence - which is the one thing the census exists to prevent.
KNOWN_PAIRS = {
    "(top)": {
        "schema", "src_set"
    },
    "aux_poke": {
        "addr", "name", "only_base_slot", "only_variant_slot", "op", "val"
    },
    "code_ptr": {
        "addr", "name", "note", "old_hex", "region", "stage"
    },
    "code_word": {
        "addr", "name", "new_hex", "new_hex_variant", "note", "old_hex",
        "only_variant_slot", "slot_mirror", "slot_off", "slot_stride",
        "slot_table", "stage"
    },
    "compare": {
        "action", "d16", "ea", "form", "imm", "note", "src_addr", "tenants",
        "type"
    },
    "data_in_code": {
        "note", "reader", "reader_old_hex", "region", "shape", "table",
        "table_len"
    },
    "data_port": {
        "dst", "dst_end", "dst_old_head", "fixes",
        # `fixes_variant` (14z-144): the `_variant` twin of `fixes`, resolved
        # against the row's OWNER exactly as row_hex() resolves new_hex. Same
        # CLASS as `fixes` — an in-blob byte correction, a fact about where a
        # sub-block lives, not a tunable a player feels — so it classifies
        # with it and not into GAMEPLAY_KEYS.
        "fixes_variant", "hole", "len", "name",
        "note", "only_base_slot", "only_variant_slot", "orc",
        "slot_ptr_table", "slot_rows", "src", "stage"
    },
    "don_m21": {
        "escapes", "resolved", "unresolved"
    },
    "file": {
        "name", "provenance", "source"
    },
    "free_pool": {
        "hi", "lo"
    },
    "gfx_remap": {
        "band_hi", "band_lo", "delta", "eff_hi", "eff_lo", "region", "stage"
    },
    "hole_a": {
        "end", "start"
    },
    "hole_b": {
        "end", "start"
    },
    "hui55": {
        "escapes", "resolved", "unresolved"
    },
    "init_shim": {
        "dispatch", "flavor_default", "flavor_disp", "flavor_held",
        "flavor_hold_flag", "latch_disp", "latch_mode", "objram_clear",
        "seed_entry"
    },
    "layout_group": {
        "regions"
    },
    "map": {
        "clone_len", "clone_src", "common", "helper", "kind", "note",
        "param_hex", "patch_new", "patch_old", "profile", "sfx_id",
        "status", "vsav2", "vsavj"
    },
    "merged_don": {
        "build", "extract", "placement_suffix", "same_as"
    },
    "merged_hui": {
        "build", "extract", "placement_suffix", "same_as"
    },
    "merged_pyr": {
        "build", "extract", "placement_suffix", "same_as"
    },
    "move": {
        "input", "kind", "name", "notes", "seq", "table"
    },
    "obj_hook": {
        "caller_old_hex", "callers", "site", "src_entries", "src_table",
        "vanilla_entries", "vanilla_table", "walker", "walker_len",
        "walker_old_hex"
    },
    "origins": {
        "vhunt2", "vsav2", "vsavj"
    },
    "palette": {
        "extra_tables", "hole", "len", "name", "src", "src_head_hex",
        "stage", "table"
    },
    "pcrel_escape_fix": {
        "pad", "region", "stage"
    },
    "port": {
        "alloc_wrap", "dst_slot", "hole_b_regions", "mirror_variant",
        "near_map", "region_space", "src_char", "src_set"
    },
    "port_patch": {
        "new_hex", "new_hex_variant", "note", "old_hex", "region",
        "src_addr", "stage"
    },
    "profile": {
        "bank4_word", "bank5_word", "collision_rule", "group", "name"
    },
    "pyron40": {
        "escapes", "resolved", "unresolved"
    },
    "reaction_hook": {
        "bne_target", "case_a0", "case_a2", "case_a4", "case_a6",
        "d2_case_a0", "d2_case_a2", "d2_case_a4", "d2_case_a6", "dispatch",
        "first_ext", "n_ext", "site_prefix", "site_prefix_expect",
        "tst_disp"
    },
    "reader": {
        "d16", "form", "next_words", "src_addr", "tenants"
    },
    "region_fix": {
        "new_hex", "note", "off", "old_hex", "region", "stage"
    },
    "select_records": {
        "allow_placeholder_tiles", "art", "expect_vj_alias_p1",
        "expect_vj_alias_p2", "expect_vs2_p1", "expect_vs2_p2", "hole",
        "name", "ring_ref_cell", "stage", "vj_p1", "vj_p2", "vs2_p1",
        "vs2_p2"
    },
    "select_wheel": {
        "bank5", "bank_site", "bank_site_old", "cell_outline", "coord_list",
        "expect_budget", "expect_count", "expect_cptr", "highlight_array",
        "highlight_base_site", "hole", "layout", "march_retarget_mid",
        "name", "outline_base", "outline_pal", "pal_block_a", "profile",
        "record", "record_ptr", "ring_ref_cell", "ring_rows", "stage",
        "table_b", "version_base", "version_font", "version_pal",
        "version_text", "version_x", "version_y"
    },
    "set": {
        "description", "name"
    },
    "site": {
        "entries", "hits", "observed", "replays", "site", "sp_max", "sp_min"
    },
    "site_thunk": {
        "data_subst", "hole", "id_literal_ok", "jmp_ok", "name", "note",
        "old_hex", "only_variant_slot", "patch", "profile", "region_subst",
        "roster_subst", "row_subst", "rts_ok", "site", "stage", "thunk_hex"
    },
    "song": {
        "id", "len", "name", "place", "provenance", "vs2_src"
    },
    "sound_table": {
        "entries", "hole", "keep_ids", "name", "profile", "ptr_old",
        "ptr_table", "remap_ids", "src", "stage", "unstub"
    },
    "space": {
        "class", "end", "fallback", "name", "profile", "start"
    },
    "stamp": {
        "d16", "ea", "form", "imm", "src_addr", "tenants", "type"
    },
    "state_hook": {
        "clr_b_off", "clr_w_off", "first_ext", "n_ext", "prev_state_off",
        "records_len", "records_orc", "records_src", "ret_equiv",
        "seq_base", "seq_first_id", "seq_ids", "seq_set", "site",
        "site_after", "site_resume", "src_dispatch_table", "src_first_idx",
        "state_off"
    },
    "strip": {
        "dst_hi", "dst_lo", "shift", "src_hi", "src_lo", "tenant"
    },
    "table": {
        "kind", "name", "note", "optional", "region", "span", "stride",
        "vsavj"
    },
    "table_fix": {
        "note", "pad_len", "region", "rows_hex", "stage", "table_off"
    },
    "tenant": {
        "alloc_wrap", "anim_base", "anim_len", "band_hi", "band_lo",
        "build", "count", "delta", "gfx_bank", "hole_b_regions", "id",
        "id_by_profile", "name", "near_map", "port_param32",
        "recon_overlay", "region_space", "safe_hi", "safe_lo", "scatter_hi",
        "scatter_lo", "src_bank", "src_char", "src_set", "sweep_hi",
        "sweep_lo", "writes"
    },
    "triage": {
        "action", "form", "imm", "note", "src_addr", "tenants", "type"
    },
    "voice_batch": {
        "enable", "exclude", "id_base", "ids", "records_base", "songs_base",
        "t7_base", "table0_copy"
    },
    "walker": {
        "src_addr", "table", "tenants"
    },
    "win_pal_variant": {
        "colors", "hole", "name", "pool_base", "pool_color_stride", "site",
        "site_old", "stage", "unit", "vs2_color_stride", "vs2_src"
    },
}

IGNORE_KEYS = {
    "name", "note", "notes", "description", "schema", "kind", "status",
    "input", "source", "art", "profile", "class", "common", "build",
    "extract", "same_as", "placement_suffix",
}

# A row whose provenance names a computation, or that carries an oracle/source
# address, is DERIVED rather than BAKED.
DERIVED_KEYS = {"orc", "src", "src_addr", "vs2_src", "clone_src", "records_orc"}
DERIVED_WORDS = re.compile(r"\bderived\b|\bcomputed\b|\brecomputed\b", re.I)

# A comment block that RETRACTS is history, never a row's provenance.
RETRACTION = re.compile(r"\bRETIRED\b|\bNEVER APPLIED\b|\bREVERT(?:ED)?\b|"
                        r"\bWITHDRAWN\b|\bSUPERSEDED\b|~~", re.I)
PROVENANCE = re.compile(r"\b(measured|ruled|derived|testimony|maintainer)\b|"
                        r"\b14z-\d+", re.I)
# a SECTION banner: a rule of dashes/box characters, or a bold session header
BANNER = re.compile(r"^\s*#\s*(?:[-=_─-╿—]{4,}|"
                    r"[-=_─-╿—]{2,}\s*\S)")

HDR_RE = re.compile(r'^\s*(\[\[?)([A-Za-z0-9_.]+)\]?\]\s*$')
KV_RE = re.compile(r'^\s*([A-Za-z0-9_.\-]+)\s*=\s*(.*)$')


class Record:
    __slots__ = ("column", "file", "kind", "key", "value", "prov", "cls", "note")

    def __init__(self, column, file, kind, key, value, prov, cls, note=""):
        self.column, self.file, self.kind, self.key = column, file, kind, key
        self.value, self.prov, self.cls, self.note = value, prov, cls, note

    def row(self):
        return "\t".join((self.column, self.file, self.kind, self.key,
                          self.value, self.cls, self.note))


def canon(root: Path):
    """Tracked manifests, minus the excluded names and directories."""
    try:
        out = subprocess.run(["git", "ls-files", MANIFEST_DIR], cwd=root,
                             capture_output=True, text=True, check=False).stdout.split()
    except OSError:
        out = []
    if not out:                       # a --root copy is not a git checkout
        base = root / MANIFEST_DIR
        out = [str(p.relative_to(root)) for p in base.rglob("*") if p.is_file()]
    keep = []
    for f in sorted(out):
        rel = Path(f)
        if rel.name in EXCLUDE_NAMES or rel.suffix not in (".toml", ".json"):
            continue
        if any(part in EXCLUDE_DIRS for part in rel.parts):
            continue
        if any(rel.match(g) for g in EXCLUDE_GLOBS):
            continue
        keep.append(f)
    return keep


def classify_key(kind, key, value):
    if kind in KNOWN_PAIRS and key not in KNOWN_PAIRS[kind]:
        return "UNKNOWN"
    if kind not in KNOWN_PAIRS:
        return "UNKNOWN"
    if (kind, key) in BY_ADDRESS:
        return "BY_ADDRESS"
    if (kind, key) in GAMEPLAY_PAIRS or key in GAMEPLAY_KEYS:
        return "gameplay"
    if key in IGNORE_KEYS:
        return None
    return "fact"


def aux_poke_class(addr):
    for lo, hi, cls, why in AUX_POKE_BANDS:
        if lo <= addr < hi:
            return ("gameplay" if cls == "GAMEPLAY" else "fact"), why
    return None, "address in no declared band"


def scan_toml(root, rel, problems):
    """Text scan. Tracks the section banner and the pending comment block, so a
    row's provenance is the PARAGRAPH above it (measured: 43.7% of blocks sit
    tight above a table header, 19.7% inside a table, 9.4% are banners)."""
    recs, lines = [], (root / rel).read_text(errors="replace").splitlines()
    kind, banner, block, pending_rows = "(top)", "", [], []
    i, n, _last = 0, len(lines), -1
    while i < n:
        # EVERY branch below must consume at least one line. Two did not on
        # the first write (the header branch, and the IGNORE-key branch) and
        # both HUNG - the same defect md_subset.py paid for in 14z-140. The
        # guard is at the TOP of the loop on purpose: a check after `i += 1`
        # is skipped by every `continue`, which is most of the branches here.
        assert i > _last, "scan_toml made no progress at %s line %d" % (rel, i + 1)
        _last = i
        raw = lines[i]
        stripped = raw.strip()
        if stripped.startswith("#"):
            start = i
            while i < n and lines[i].strip().startswith("#"):
                i += 1
            text = "\n".join(l.strip().lstrip("#").strip() for l in lines[start:i])
            j = i
            while j < n and not lines[j].strip():
                j += 1
            gapped = j > i
            is_banner = BANNER.match(lines[start]) or (gapped and j < n
                                                       and HDR_RE.match(lines[j]))
            if is_banner:
                banner = text          # attaches to the SECTION, not one table
                block = []
            else:
                block = [text]
            continue
        m = HDR_RE.match(raw.split("#")[0].rstrip())
        if m:
            kind = m.group(2)
            pending_rows = []
            i += 1
            continue
        m = KV_RE.match(raw.split("#")[0].rstrip())
        if m:
            key, val = m.group(1), m.group(2).strip().rstrip(",")
            col = classify_key(kind, key, val)
            note = ""
            if col == "UNKNOWN":
                problems.append("%s: [[%s]].%s is a NEW (kind, key) pair - "
                                "classify it in KNOWN_PAIRS/GAMEPLAY_KEYS first"
                                % (rel, kind, key))
                pending_rows.append((key, val))
                i += 1
                continue
            if col == "BY_ADDRESS":
                addr = None
                for k2, v2 in pending_rows:
                    if k2 == "addr":
                        try:
                            addr = int(v2, 0)
                        except ValueError:
                            addr = None
                if addr is None:
                    col, note = None, "no addr in the row"
                else:
                    col, note = aux_poke_class(addr)
                    if col is None:
                        problems.append("%s: [[%s]].%s writes PRG:0x%06X - %s"
                                        % (rel, kind, key, addr, note))
            pending_rows.append((key, val))
            if col is None:
                i += 1
                continue
            prov_text = "\n".join(block + ([banner] if banner else []))
            prov = "" if RETRACTION.search(prov_text) else prov_text
            cls = "DERIVED" if (key in DERIVED_KEYS
                                or DERIVED_WORDS.search(prov)) else ""
            recs.append(Record(col, rel, kind, key, val, prov, cls, note))
        i += 1
    return recs


def scan_json(root, rel):
    """JSON has no comments; this tree invented `_`-prefixed keys for them."""
    recs = []
    try:
        doc = json.loads((root / rel).read_text(errors="replace"))
    except Exception as exc:                                   # noqa: BLE001
        return [Record("fact", rel, "!parse", "", str(exc), "", "BAKED")]

    def walk(node, path, prov):
        if isinstance(node, dict):
            here = " ".join(("in-table: " + str(v)) if k == "_in_table"
                            else str(v)
                            for k, v in node.items()
                            if k.startswith("_") and isinstance(v, str))
            prov = (prov + " " + here).strip()
            for k, v in node.items():
                if k.startswith("_"):
                    continue
                walk(v, path + [str(k)], prov)
        elif isinstance(node, list):
            for idx, v in enumerate(node):
                walk(v, path + ["[]"], prov)
        else:
            kind = ".".join(path[:-1]) or "(top)"
            key = path[-1] if path else "(top)"
            col = ("gameplay" if ("adjacency" in path or "edges_in" in path)
                   else "fact")
            recs.append(Record(col, rel, kind, key, json.dumps(node), prov, ""))
    walk(doc, [], "")
    return recs


def scan_generators(root):
    """The `code` column: MODULE-LEVEL named constants (ruled 2026-09-07,
    option (a)) plus any literal carrying a provenance tag. STATED BLIND SPOT:
    a value buried as an inline literal inside a function stays invisible, and
    no cheap rule finds it - measured, the plan's same-line-tag rule selected
    3 lines of 2,215 numeric literals, i.e. it measured the comment habit."""
    recs = []
    const = re.compile(r'^([A-Z][A-Z0-9_]*)\s*=\s*([^=].*?)\s*(?:#\s*(.*))?$')
    for name in GENERATORS:
        p = root / "tools" / name
        if not p.exists():
            continue
        for line in p.read_text(errors="replace").splitlines():
            m = const.match(line)
            if not m:
                continue
            key, val, com = m.group(1), m.group(2), m.group(3) or ""
            recs.append(Record("code", "tools/" + name, "(module)", key,
                               val[:60], com, ""))
    return recs


def table_index(root):
    """Hand-written tables only. The GENERATED ones are projections of the
    manifests, so finding a value there proves nothing about provenance."""
    rows, shapes = [], {}
    shape_file = root / "docs/doc_shape.tsv"
    if shape_file.exists():
        for line in shape_file.read_text(errors="replace").splitlines():
            if line.startswith("#") or "\t" not in line:
                continue
            parts = line.split("\t")
            shapes[parts[0]] = parts[1]
    tdir = root / "docs/project/tables"
    for p in sorted(tdir.glob("*.md")) if tdir.exists() else []:
        rel = "docs/project/tables/" + p.name
        if shapes.get(rel) != "REFERENCE":
            continue
        for line in p.read_text(errors="replace").splitlines():
            if line.startswith("|"):
                rows.append((rel, line))
    return rows


IN_TABLE_PTR = re.compile(r"in[-_ ]table:?\s*[\"']?((?:docs/project/)?tables/[\w./-]+)")


TOKEN = re.compile(r"[0-9A-Za-z_.-]+")


def line_values(line):
    """The table side, NORMALISED. `0x08` in a document and `"0x08"` in a
    manifest must compare equal, and a raw substring test cannot do it: norm()
    turns both into "8", but "8" does not word-match inside the text "0x08".
    So both sides are tokenised and normalised (14z-141)."""
    return {norm(t) for t in TOKEN.findall(line)}


def norm(v):
    v = v.strip().strip('"').strip("'")
    try:
        return str(int(v, 0))
    except ValueError:
        return v.lower()


def classify(recs, tables, problems=None):
    """IN-TABLE is POINTER-DRIVEN, not inferred by value matching.

    WHY (measured 14z-141): a value-matching pass returned 19 gameplay rows
    IN-TABLE and ALL NINETEEN were false positives - key `R` of an adjacency
    row matches any table line containing an `r`, and `id` matches the `ids`
    column of qs_voice_map.md. That is the L1 matcher lesson exactly ("a
    completeness check is only as good as its matcher"). Small integers and
    short key names match everywhere, so inference cannot carry this.

    A value is IN-TABLE when the manifest SAYS SO - `# in-table:
    tables/<doc>.md` in its attributed provenance, or an `_in_table` key in
    JSON - AND that hand-written REFERENCE table really carries the value as
    a whole word. A pointer whose table does not carry the value is a
    PROBLEM, not a silent BAKED: it means a migration half-landed."""
    by_file = defaultdict(list)
    for rel, line in tables:
        by_file[rel].append(line.lower())
    for r in recs:
        if r.cls:
            continue
        m = IN_TABLE_PTR.search(r.prov)
        if not m:
            r.cls = "BAKED"
            continue
        rel = m.group(1)
        if not rel.startswith("docs/"):
            rel = "docs/project/" + rel
        nv = norm(r.value)
        if rel not in by_file:
            if problems is not None:
                problems.append("%s: [[%s]].%s names %s, which is not a "
                                "hand-written REFERENCE table"
                                % (r.file, r.kind, r.key, rel))
            r.cls = "BAKED"
            continue
        if not any(nv in line_values(line) for line in by_file[rel]):
            if problems is not None:
                problems.append("%s: [[%s]].%s = %s names %s but no row there "
                                "carries the value"
                                % (r.file, r.kind, r.key, r.value, rel))
            r.cls = "BAKED"
            continue
        r.cls = "IN-TABLE"
        r.note = (r.note + " " + rel).strip()
        if not PROVENANCE.search(r.prov):
            r.note += " no-provenance"
    return recs


def census(root):
    problems, recs = [], []
    for rel in canon(root):
        if rel.endswith(".json"):
            recs += scan_json(root, rel)
        else:
            recs += scan_toml(root, rel, problems)
    recs += scan_generators(root)
    return classify(recs, table_index(root), problems), problems


def tally(recs):
    t = defaultdict(Counter)
    for r in recs:
        t[r.column][r.cls] += 1
    return t


def note_lines(t):
    out = []
    for col in ("gameplay", "fact", "code"):
        c = t.get(col, Counter())
        tot = sum(c.values())
        out.append("NOTE: rule5.%s in-table %d baked %d derived %d (%d/%d baked)"
                   % (col, c["IN-TABLE"], c["BAKED"], c["DERIVED"],
                      c["BAKED"], tot))
    return out


# The FROZEN inventory is the GAMEPLAY and CODE columns only.
#
# WHY, and it is a measurement not a preference: freezing `fact` too made the
# file 8,059 rows, and `fact` is addresses, lengths and hex blobs - ordinary
# port work adds them constantly, so every routine manifest edit would fail
# the gate and be answered by a reflexive re-freeze. A shrink-only signal that
# fires on every commit is not a signal. Rule 5 obliges BEHAVIOURAL values, so
# that is what is locked; `fact` is reported as a NOTE-class number instead, so
# it cannot rot silently either.
FROZEN_COLUMNS = ("gameplay", "code")


def frozen_rows(recs):
    return sorted(r.row() for r in recs
                  if r.cls == "BAKED" and r.column in FROZEN_COLUMNS)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=None)
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--keys", action="store_true")
    ap.add_argument("--freeze", default=None)
    ap.add_argument("--check", default=None)
    ap.add_argument("--allow-growth", default=None)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    root = Path(a.root).resolve() if a.root else Path(__file__).resolve().parent.parent

    if a.selftest:
        return selftest()

    recs, problems = census(root)
    t = tally(recs)

    if a.keys:
        pairs = Counter((r.column, r.kind, r.key) for r in recs)
        for (col, kind, key), n in sorted(pairs.items()):
            print("%-9s %-18s %-24s %5d" % (col, kind, key, n))
        print("# %d (column, kind, key) triples" % len(pairs))
        return 0

    if a.report or not (a.freeze or a.check):
        print("== rule-5 census over %d canonical manifests ==" % len(canon(root)))
        print("| column | in-table | derived | baked | total |")
        print("|---|---|---|---|---|")
        for col in ("gameplay", "fact", "code"):
            c = t.get(col, Counter())
            print("| %s | %d | %d | %d | %d |"
                  % (col, c["IN-TABLE"], c["DERIVED"], c["BAKED"], sum(c.values())))
        for line in note_lines(t):
            print(line)

    if problems:
        print("UNCLASSIFIED: %d" % len(problems))
        for p in problems[:20]:
            print("  " + p)
        if a.freeze or a.check:
            print("FAIL: a value must be classified before the inventory moves")
            return 1

    rows = frozen_rows(recs)
    if a.freeze:
        out = Path(a.freeze)
        if out.exists() and not a.allow_growth:
            old = [l for l in out.read_text().splitlines()
                   if l and not l.startswith("#")]
            if len(rows) > len(old):
                print("FAIL: the BAKED inventory would GROW %d -> %d. Add a table "
                      "row with provenance, or pass --allow-growth \"<reason>\""
                      % (len(old), len(rows)))
                return 1
        out.parent.mkdir(parents=True, exist_ok=True)
        t_now = tally(recs)
        head = ["# rule5_baked.tsv - the BAKED inventory for the GAMEPLAY and CODE",
                "# columns, frozen so it can only SHRINK. `fact` is deliberately",
                "# NOT frozen (see FROZEN_COLUMNS in tools/audit_rule5.py) and is",
                "# reported as a NOTE instead; at this freeze it stood at",
                "# %d baked / %d derived of %d."
                % (t_now["fact"]["BAKED"], t_now["fact"]["DERIVED"],
                   sum(t_now["fact"].values())),
                "# Produced by `python3 tools/audit_rule5.py --freeze",
                "# tests/expected/rule5_baked.tsv`. Provenance: static (the tree",
                "# itself). Columns: column file kind key value class note."]
        if a.allow_growth:
            head.append("# growth allowed: " + a.allow_growth)
        out.write_text("\n".join(head + rows) + "\n")
        print("froze %d BAKED rows -> %s" % (len(rows), a.freeze))
        return 0

    if a.check:
        want = Path(a.check)
        if not want.exists():
            print("FAIL: %s is absent - run --freeze" % a.check)
            return 1
        old = [l for l in want.read_text().splitlines()
               if l and not l.startswith("#")]
        if old == rows:
            print("ok    the BAKED inventory matches (%d rows)" % len(rows))
            return 0
        # A MULTISET, not a set. Identical rows are legitimate - the same
        # (file, kind, key, value) occurs in many tables of one manifest - so
        # a set difference reports NOTHING when the only change is one more
        # copy of a row that already exists, and the tool then exited 1 in
        # SILENCE. Found by this gate's own must-fire control, 14z-141.
        c_old, c_new = Counter(old), Counter(rows)
        new = sorted((c_new - c_old).elements())
        gone = sorted((c_old - c_new).elements())
        if new:
            print("FAIL: %d NEW baked value(s) - add a table row with "
                  "provenance, or re-freeze with a ledger line:" % len(new))
            for r in new[:10]:
                print("  " + r)
        if gone:
            print("FAIL: %d baked value(s) GONE - if they were migrated, "
                  "re-freeze in the same commit with a ledger line:" % len(gone))
            for r in gone[:10]:
                print("  " + r)
        if not new and not gone:
            print("FAIL: the inventory has the same rows in a different ORDER "
                  "(%d rows) - re-freeze; --freeze sorts" % len(rows))
        return 1
    return 0


# --- ground truth -----------------------------------------------------------
def selftest():
    import tempfile
    ok = True

    def check(label, cond):
        nonlocal ok
        print("  %s  %s" % ("ok   " if cond else "FAIL ", label))
        ok = ok and bool(cond)

    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        (root / MANIFEST_DIR).mkdir(parents=True)
        (root / "docs/project/tables").mkdir(parents=True)
        (root / "tools").mkdir(parents=True)
        (root / "docs/doc_shape.tsv").write_text(
            "docs/project/tables/t.md\tREFERENCE\t-\t-\n")
        (root / "docs/project/tables/t.md").write_text(
            "| key | value | provenance |\n|---|---|---|\n"
            "| only_variant_slot | true | measured 14z-141 |\n")
        (root / MANIFEST_DIR / "a.toml").write_text(
            "# measured 14z-141: the block above a table is its provenance\n"
            "# in-table: tables/t.md\n"
            "[[data_port]]\n"
            "name = \"x\"\n"
            "only_variant_slot = true\n"
            "\n"
            "# RETIRED 14z-91 (maintainer-decided): the row below is NOT this\n"
            "[[site_thunk]]\n"
            "only_variant_slot = false\n"
            "\n"
            "[[aux_poke]]\n"
            "name = \"hud\"\n"
            "addr = 0x089900\n"
            "op = \"poke16\"\n"
            "val = 0x1234\n")
        recs, problems = census(root)
        recs = {(r.kind, r.key): r for r in recs}
        check("a block above a table attaches to it",
              PROVENANCE.search(recs[("data_port", "only_variant_slot")].prov))
        check("a RETRACTION block is NOT a row's provenance",
              not recs[("site_thunk", "only_variant_slot")].prov)
        check("variant selection is the gameplay column",
              recs[("data_port", "only_variant_slot")].column == "gameplay")
        check("an aux_poke in the HUD band is fact",
              recs[("aux_poke", "val")].column == "fact")
        check("a POINTED-AT value in a REFERENCE table reads IN-TABLE",
              recs[("data_port", "only_variant_slot")].cls == "IN-TABLE")
        check("a value with NO pointer stays BAKED however it matches",
              recs[("aux_poke", "val")].cls == "BAKED")
        check("no unclassified poke in the fixture", not problems)

        # a HALF-LANDED migration: the pointer exists, the table does not
        # carry the value. It must be a PROBLEM, never a silent BAKED.
        (root / MANIFEST_DIR / "c.toml").write_text(
            "# in-table: tables/t.md\n[[data_port]]\n"
            "only_base_slot = 0x4242\n")
        recs3, problems3 = census(root)
        r3 = {(r.kind, r.key): r for r in recs3}[("data_port", "only_base_slot")]
        check("a pointer whose table lacks the value is a PROBLEM",
              r3.cls == "BAKED" and any("carries the value" in p for p in problems3))
        (root / MANIFEST_DIR / "c.toml").unlink()

        (root / MANIFEST_DIR / "b.toml").write_text(
            "[[aux_poke]]\nname = \"?\"\naddr = 0x123456\nop = \"poke16\"\n"
            "val = 0x1\n")
        _, problems2 = census(root)
        check("an aux_poke outside every declared band is UNCLASSIFIED",
              len(problems2) == 1)

        (root / MANIFEST_DIR / "probe_x.toml").write_text(
            "[[data_port]]\nonly_variant_slot = true\n")
        n_before = len(census(root)[0])
        check("a probe_*.toml is excluded by GLOB, not by git (so --root "
              "and the tree agree)", len(canon(root)) == 2)
        (root / MANIFEST_DIR / "overlay.wip").mkdir()
        (root / MANIFEST_DIR / "overlay.wip/big.json").write_text('{"a": 1}')
        check("overlay.wip is excluded", len(canon(root)) == 2
              and len(census(root)[0]) == n_before)
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
