#!/usr/bin/env python3
"""gen_donovan_patch.py — generate the donovan-m2 patch (a patch_prg.py op
list) from the extraction manifest, staged per the M2a bring-up ladder.

Stages (cumulative; each later stage includes all earlier ops):
  1  null relocation, zero Donovan bytes: Jedah's own player-path hitbox
     block copied into hole A (data raw inside the encrypted zone) with the
     pair repointed, plus two hand-authored jmp-back trampolines — one
     re-encrypted in hole A, one raw in hole B — behind two dispatch
     entries. Proves allocator/copy/repoint/encrypt with zero R1 ambiguity;
     Jedah must play identically.
  2  + Donovan passive data: hitbox + hitbox_proj blobs, per-char value
     rows (params/rec8/words/bytes/byte2d + oracle-classified gap values),
     4 hitbox-family repoints.
  3  + Donovan anim + sprite sub-table clusters (internal fixups), 4 anim
     table repoints.
  4  + Donovan code (engine refs resolved via reconciliation.toml — any
     unresolved/unverified ref FAILS with the full R1 report), 14 dispatch
     repoints.
  5  + aux pokes from donovan.toml (select screen / quotes / AI ...).

Every bank repoint pokes slot 0x0F AND the aliasing variant row 0x1F, after
asserting they are vanilla-equal. Every destination range is asserted to be
0xFF fill in vanilla vsavj before use. Output is deterministic.

Usage:
    python3 tools/gen_donovan_patch.py <extract_dir> <out_dir> \
        --vsavj $ROMDIR/vsavj.zip --stage N \
        [--port build/manifest/donovan.toml] \
        [--recon build/manifest/reconciliation.toml] \
        [--bank-map build/manifest/bank_map.toml]
"""

import argparse
import json
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cps2_decrypt as cps  # noqa: E402
from _minitoml import loads as toml_loads  # noqa: E402

VSAVJ_ORIGIN = 0x0BD0FA


def stage_regions(manifest_regions, stage):
    """Which regions each stage places (cumulative, deterministic order):
    2: hitbox family; 3: anim + sprite sub-table clusters; 4: code + the
    ported absent-support routines (x* extra regions)."""
    names = sorted(manifest_regions)
    want = []
    if stage >= 2:
        want += [n for n in names if n.startswith("hitbox")]
    if stage >= 3:
        want += [n for n in names if n == "anim" or n.startswith("aux")]
    if stage >= 4:
        want += [n for n in names if n == "code" or n.startswith("x")]
    return want


def _int(v):
    return v if isinstance(v, int) else int(v, 0)


def load_vsavj(zpath):
    words, keybytes, prgs, sha1s = cps.load_set(zpath)
    return bytes(cps.words_to_logical_bytes(words))


def normalise_tenants(port, profile=None, override=None):
    """`[[tenant]]` supersedes `[port]`.

    A tenant is one ported character occupying one character id. Rather than
    rewrite the six places that read `port["port"]`, a tenant row is
    NORMALISED into the `[port]` shape the generator already understands —
    so a manifest carrying a single tenant at the old slot must produce a
    BYTE-IDENTICAL image, which is how this refactor is verified (the Phase
    C discipline: a refactor that moves zero bytes).

    The one semantic change is `mirror_variant`. It exists because a
    BASE-half slot's variant row aliases it in vanilla (slot 0x0F and its
    mirror 0x1F). A tenant that IS a variant id has no mirror, and one at
    0x13 must never touch 0x03 (Victor) — so the default is now derived
    from the id rather than assumed true.
    """
    tenants = port.get("tenant", [])
    if not tenants:
        return port                      # legacy [port] manifest, untouched
    if len(tenants) > 1:
        raise SystemExit("gen_donovan_patch: %d tenants declared; multi-tenant "
                         "builds are not implemented yet (M3 Phase 3). Land "
                         "one tenant at a time." % len(tenants))
    t = tenants[0]
    # PROFILE-GATED ID (M3a, 14z-61). De-substitution — moving the tenant off
    # a legacy character's slot onto its own variant id — is ROSTER work, and
    # the dual-track ruling (14z-59g) puts roster work on the WIDE track: the
    # stock build stays the frozen compatibility artifact. It has no choice in
    # the matter either, since a tenant at a variant id needs its tiles OUT of
    # the host character's gfx band, and only the extension has that room.
    # So one manifest still produces both tracks, with the id per profile.
    # "profile=id[,profile=id...]" — the manifest parser is minimal, so this
    # follows near_map's k=v string shape rather than a TOML sub-table.
    by_profile = {}
    for kv in str(t.get("id_by_profile", "")).split(","):
        if kv.strip():
            k, _, v = kv.partition("=")
            by_profile[k.strip()] = _int(v.strip())
    tid = by_profile.get(profile, _int(t["id"]))
    if override is not None:
        tid = override
    if tid >= 0x10 and not profile:
        raise SystemExit(
            f"gen_donovan_patch: tenant id {tid:#04x} is a VARIANT id, which "
            f"requires a build profile — its tiles cannot share the host "
            f"character's gfx band, and a stock build has nowhere else to put "
            f"them. Build with --profile, or declare a base-half id for the "
            f"stock track via [tenant.id_by_profile].")
    if tid in (0x12, 0x18):
        raise SystemExit(
            f"gen_donovan_patch: tenant id {tid:#04x} is RESERVED "
            f"(docs/game/atlas/id_space.md): 0x12 is the Gallon select variant "
            f"vanilla writes as an immediate, 0x18 is Oboro Bishamon.")
    p = dict(port.get("port", {}))
    p["src_set"] = t["src_set"]
    p["src_char"] = t["src_char"]
    p["dst_slot"] = tid
    p["mirror_variant"] = t.get("mirror_variant", tid < 0x10)
    for k in ("alloc_wrap", "near_map", "hole_b_regions", "gfx_bank", "name",
              "port_param32"):
        if k in t:
            p[k] = t[k]
    # A variant-id tenant's tiles live in the WIDE extension (that is WHY
    # a variant id requires a profile), so its gfx bank defaults to the
    # first group-C bank rather than the manifest's base-slot bank. The
    # base-slot bank (the host's band) stays whatever the manifest says.
    if tid >= 0x10:
        p["gfx_bank"] = _int(t.get("gfx_bank_variant", 4))
    port = dict(port)
    port["port"] = p
    return port


def load_bank_map(path):
    doc = toml_loads(Path(path).read_text())
    return {t["name"]: t for t in doc["table"]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("extract_dir", type=Path)
    ap.add_argument("out_dir", type=Path)
    ap.add_argument("--vsavj", type=Path, required=True)
    ap.add_argument("--stage", type=int, required=True, choices=range(1, 7))
    root = Path(__file__).resolve().parent.parent
    ap.add_argument("--port", type=Path, default=root / "build/manifest/donovan.toml")
    ap.add_argument("--recon", type=Path,
                    default=root / "build/manifest/reconciliation.toml")
    ap.add_argument("--bank-map", type=Path,
                    default=root / "build/manifest/bank_map.toml")
    ap.add_argument("--allow-plausible", action="store_true",
                    help="use reconciliation rows with status=plausible "
                         "(experiment builds; behavior gates arbitrate)")
    ap.add_argument("--tenant-id", type=lambda v: int(v, 0), default=None,
                    help="override the tenant's character id for this build. "
                         "Used while a de-substitution is IN PROGRESS: the "
                         "manifest keeps the id the frozen reference was built "
                         "with, so that reference stays reproducible, and the "
                         "move is explicit on the command line until it lands.")
    ap.add_argument("--profile", default=None,
                    help="build profile name; enables address spaces gated on "
                         "it (e.g. cps2-wide-v1). Without it, profile-gated "
                         "spaces do not exist and a stock-size build cannot "
                         "accidentally depend on them.")
    ap.add_argument("--tripwire-open", action="store_true",
                    help="route refs with missing/open reconciliation rows "
                         "to per-target planted-ILLEGAL tripwires instead of "
                         "failing — the guard's fault PC then names exactly "
                         "which unresolved target actually fires")
    args = ap.parse_args()
    out = args.out_dir
    out.mkdir(parents=True, exist_ok=True)

    man = json.loads((args.extract_dir / "regions.json").read_text())
    port = toml_loads(args.port.read_text())
    # Dotted table names are BANNED in this manifest (14z-62c): tomllib
    # nests them, the subset parser detaches them as orphan top-level keys
    # — the same manifest builds DIFFERENT bytes per host python. The
    # 14z-2 [[data_port.fix]] row was silently dropped this way on every
    # build from this machine, frozen references included.
    _dotted = [k for k in port if "." in k]
    if _dotted:
        raise SystemExit(f"gen_donovan_patch: dotted table name(s) in the "
                         f"manifest: {_dotted} — banned (host-dependent "
                         f"parse, 14z-62c). Use the flat equivalents.")
    port = normalise_tenants(port, args.profile, args.tenant_id)
    bank = load_bank_map(args.bank_map)
    vj = load_vsavj(args.vsavj)
    recon = {}
    if args.recon.is_file():
        for m in toml_loads(args.recon.read_text()).get("map", []):
            recon[_int(m["vsav2"])] = m
    # PER-TENANT RECON OVERLAY (14z-65): the shared map's rows are frozen
    # for the reference tenant's reproducibility — his build consumes OPEN
    # rows as tripwires, so resolving a row he references changes HIS
    # bytes. A tenant manifest may declare recon_overlay = "<toml>" whose
    # rows override the shared map for THAT tenant's builds only. The
    # Phase 2 merge replaces this with proper per-tenant row scoping.
    _ov = port.get("recon_overlay") or (port.get("tenant") or [{}])[0].get("recon_overlay")
    if _ov:
        _ovp = root / _ov
        if not _ovp.is_file():
            raise SystemExit(f"recon_overlay {_ov} not found")
        for m in toml_loads(_ovp.read_text()).get("map", []):
            recon[_int(m["vsav2"])] = m

    # ── M5: the per-node sfx helper goes live ONLY with the record array ─────
    # 14z-52 measured exactly why this coupling has to be structural. The
    # ported dispatcher resolves slot 0x0F through the per-char pointer table;
    # without THIS character's own array, that row still points at JEDAH's
    # (~40 live entries) while Donovan's scripts index up to 43. An un-stubbed
    # helper would therefore read PAST the array and enqueue whatever follows
    # — including the vsavj 0x700-0x7FF MUSIC range. That is the original
    # 214P/214K "music instead of sfx" bug, and it is a shipping-grade defect.
    #
    # So the un-stub is driven by the SAME manifest row that places the array,
    # not by a profile name and not by a hand-edited reconciliation status. If
    # the array is not placed — a stock-size build, where the row is
    # profile-gated away — the helper stays stubbed BY CONSTRUCTION. There is
    # no ordering of edits that can produce a live helper with no array.
    unstubbed = []
    for _st in port.get("sound_table", []):
        if args.stage < _int(_st.get("stage", 0)):
            continue
        if _st.get("profile") and _st["profile"] != args.profile:
            continue
        for _spec in str(_st.get("unstub", "")).split(","):
            _spec = _spec.strip()
            if not _spec:
                continue
            _v2, _vj = (_int(x) for x in _spec.split("="))
            _row = recon.get(_v2)
            if _row is None:
                fail_early = f"sound_table {_st['name']}: unstub {_v2:#x} has no recon row"
                raise SystemExit(fail_early)
            _row["vsavj"] = _vj
            _row["kind"] = "engine"
            _row["status"] = "verified"
            unstubbed.append((_st["name"], _v2, _vj))

    dst_slot = _int(port["port"]["dst_slot"])
    var_slot = dst_slot | 0x10
    mirror = port["port"].get("mirror_variant", True)
    # ── address-space model (Phase C) ────────────────────────────────────────
    # Placement used to be two hard-coded holes. It is now a declarative,
    # ORDERED list of spaces, because the roster does not fit in two holes and
    # "which hole?" is the wrong question once the WIDE extension exists.
    #
    # A space is {name, start, end, cur, class, profile, fallback}:
    #   class   "crypt" = inside the CPS-2 encryption window, so CODE placed
    #                     here must be re-encrypted; "raw" = outside it.
    #   profile when set, the space only exists for that build profile, so a
    #           stock-size build cannot accidentally allocate into space that
    #           only a patched emulator provides.
    #   fallback name of the next space to try on overflow.
    #
    # Manifests may declare [[space]] entries; a manifest with only the legacy
    # [hole_a]/[hole_b] sections synthesises the identical two-space list, so
    # existing builds are byte-for-byte unchanged (asserted by
    # tests/test_phasec_spaces.sh).
    spaces = {}
    order = []
    decl = port.get("space", [])
    if decl:
        for s in decl:
            nm = s["name"]
            spaces[nm] = {"name": nm, "start": _int(s["start"]),
                          "end": _int(s["end"]), "cur": _int(s["start"]),
                          "class": s.get("class", "raw"),
                          "profile": s.get("profile"),
                          "fallback": s.get("fallback")}
            order.append(nm)
    else:
        spaces["hole_a"] = {"name": "hole_a", "start": _int(port["hole_a"]["start"]),
                            "end": _int(port["hole_a"]["end"]),
                            "cur": _int(port["hole_a"]["start"]),
                            "class": "crypt", "profile": None, "fallback": "hole_b"}
        spaces["hole_b"] = {"name": "hole_b", "start": _int(port["hole_b"]["start"]),
                            "end": _int(port["hole_b"]["end"]),
                            "cur": _int(port["hole_b"]["start"]),
                            "class": "raw", "profile": None, "fallback": None}
        order = ["hole_a", "hole_b"]

    # Legacy call sites say alloc("a"/"b", ...); keep that vocabulary.
    ALIAS = {"a": "hole_a", "b": "hole_b"}

    # Drop spaces belonging to a profile we are not building for. Doing this
    # by CONSTRUCTION (rather than by remembering not to use them) is what
    # makes a stock build incapable of depending on the WIDE extension.
    for nm in list(spaces):
        pr = spaces[nm]["profile"]
        if pr and pr != args.profile:
            del spaces[nm]
            order.remove(nm)

    ops = []
    notes = []
    fail = []
    fragments = []  # (dst, len, provenance, what) for the atlas fragment

    def vj_u32(addr):
        return int.from_bytes(vj[addr:addr + 4], "big")

    gap_free = []  # (start, end) inside already-claimed group spans
    pcrel_far_tramps = {}  # resolved target -> near jmp trampoline (14z-65)
    dc_tables = {}         # (table src, len) -> placed DATA copy (14z-69)

    def alloc(hole, size, what, fallback=True):
        """Place `size` bytes, returning the destination address.

        `hole` names a space ("a"/"b" are the legacy aliases). On overflow the
        space's declared `fallback` chain is followed, so growing the address
        space is a manifest edit rather than a code edit.
        """
        # gap-fit first: reuse dead space inside layout-group spans
        for gi, (gs, ge) in enumerate(gap_free):
            if ge - gs >= size:
                gap_free[gi] = ((gs + size + 0xF) & ~0xF, ge)
                return gs
        nm = ALIAS.get(hole, hole)
        sp = spaces.get(nm)
        if sp is None:
            fail.append(f"no address space '{hole}' for {what}"
                        + (f" (profile '{args.profile}')" if args.profile else
                           " (is it profile-gated? pass --profile)"))
            return None
        start = sp["cur"]
        if start + size > sp["end"]:
            nxt = sp["fallback"] if fallback else None
            if nxt and nxt in spaces:
                return alloc(nxt, size, what, fallback=True)
            fail.append(f"space {nm} overflow allocating 0x{size:X} for {what} "
                        f"(free 0x{max(0, sp['end'] - start):X})")
            return None
        # Beyond the base image is legal ONLY in a profile-gated space: the
        # patcher grows the image and emits the appended members (the "image"
        # block written below). Extension bytes are 0xFF fill by construction,
        # so there is nothing to verify there — but in BASE space the
        # 0xFF-fill check still guards every byte.
        if start + size > len(vj):
            if not sp["profile"]:
                fail.append(
                    f"space {nm} allocation 0x{start:06X}+0x{size:X} for {what} "
                    f"lies beyond the 0x{len(vj):X}-byte program image, and {nm} "
                    f"is not profile-gated — a stock build cannot grow the image.")
                return None
        else:
            for i in range(start, start + size):
                if vj[i] != 0xFF:
                    fail.append(f"dest 0x{i:06X} for {what} is not 0xFF fill")
                    return None
        sp["cur"] = (start + size + 0xF) & ~0xF
        return start

    def table_entry_addr(tname, slot):
        t = bank[tname]
        es = (t["span"] // 32) if t["kind"] == "byte2d" else (t["stride"] // 32)
        return _int(t["vsavj"]) + slot * es, es

    def repoint(tname, value, what):
        """poke32 a bank pointer entry at dst_slot (+ variant mirror)."""
        a, es = table_entry_addr(tname, dst_slot)
        assert es == 4
        ops.append({"op": "poke32", "addr": f"{a:#x}", "val": f"{value:#010x}"})
        notes.append(f"poke32 {a:#08x} <- {value:#010x}  {tname}[{dst_slot:#x}] {what}")
        if mirror:
            av, _ = table_entry_addr(tname, var_slot)
            if vj_u32(av) != vj_u32(a):
                fail.append(f"{tname}: slot {var_slot:#x} does not alias "
                            f"{dst_slot:#x} in vanilla ({vj_u32(av):#x} vs "
                            f"{vj_u32(a):#x}) — mirror assumption broken")
            else:
                ops.append({"op": "poke32", "addr": f"{av:#x}",
                            "val": f"{value:#010x}"})
                notes.append(f"poke32 {av:#08x} <- {value:#010x}  "
                             f"{tname}[{var_slot:#x}] variant mirror")

    def poke_bytes(addr, data, what):
        """Raw bytes at addr; odd-aligned edges are merged with vanilla
        neighbor bytes into word-aligned data ops."""
        start, blob = addr, data
        if start % 2:
            start -= 1
            blob = vj[start:start + 1] + blob
        if (start + len(blob)) % 2:
            blob = blob + vj[start + len(blob):start + len(blob) + 1]
        ops.append({"op": "data", "addr": f"{start:#x}", "hex": blob.hex()})
        notes.append(f"data   {start:#08x} +{len(blob):#x}  {what}")

    # ── stage 1: null relocation (scaffolding proof; emitted only for the
    # stage 1-3 ladder builds — stage 4+ needs the space and overrides every
    # repoint anyway) ────────────────────────────────────────────────────────
    def vsavj_ptr_bounds(table_names, slot):
        seeds, all_ptrs = [], set()
        for tn in table_names:
            base = _int(bank[tn]["vsavj"])
            for c in range(32):
                v = vj_u32(base + c * 4)
                if 0x1000 < v < 0x400000:
                    all_ptrs.add(v)
                if c == slot:
                    seeds.append(v)
        start = min(seeds)
        above = [p for p in all_ptrs if p > max(seeds)]
        return seeds, start, (min(above) if above else max(seeds) + 0x4000)

    seeds, jh_start, jh_end = vsavj_ptr_bounds(["hitbox_base", "hitbox_comp"],
                                               dst_slot)
    if args.stage > 3:
        jh_len = 0  # skip scaffolding
    else:
        jh_len = jh_end - jh_start
    notes.append(f"# stage 1: Jedah hitbox block 0x{jh_start:06X}+0x{jh_len:X} "
                 f"(base {seeds[0]:#x} comp {seeds[1]:#x})")
    dst = alloc("a", jh_len, "jedah hitbox copy") if jh_len else None
    if dst is not None:
        delta = dst - jh_start
        poke_bytes(dst, vj[jh_start:jh_start + jh_len], "jedah hitbox copy (null reloc)")
        fragments.append((dst, jh_len, "VSAV", "stage1 jedah hitbox copy"))
        # OWNERSHIP (14z-65): at stage >= 2 the passive-data pass repoints
        # these same rows to the real ported data — the scaffold repoints
        # emitted anyway and relied on last-write-wins (the op-overlap
        # assertion now forbids that). The COPY still emits so stage-2/3
        # ladder builds keep their allocator layout (and their bytes,
        # since the final row values were identical either way).
        if args.stage == 1:
            repoint("hitbox_base", seeds[0] + delta, "null reloc")
            repoint("hitbox_comp", seeds[1] + delta, "null reloc")
        else:
            notes.append("# stage-1 scaffold repoints skipped: the stage-2+ "
                         "passive-data pass owns the hitbox rows (14z-65)")

    # trampolines: dispatch_00 via hole A (re-encrypted), dispatch_01 via
    # hole B (outside the encrypted range -> stored raw)
    for tname, hole in ((("dispatch_00", "a"), ("dispatch_01", "b"))
                        if args.stage <= 3 else ()):
        a, _ = table_entry_addr(tname, dst_slot)
        target = vj_u32(a)
        tdst = alloc(hole, 6, f"{tname} trampoline")
        if tdst is None:
            continue
        code = bytes([0x4E, 0xF9]) + target.to_bytes(4, "big")  # jmp abs.l
        ops.append({"op": "code", "addr": f"{tdst:#x}", "hex": code.hex()})
        notes.append(f"code   {tdst:#08x} jmp {target:#08x}  {tname} trampoline "
                     f"(hole {hole})")
        fragments.append((tdst, 6, "GEN", f"stage1 {tname} trampoline"))
        repoint(tname, tdst, f"-> trampoline (hole {hole})")

    # ── stages 2+: Donovan regions ───────────────────────────────────────────
    placed = {}   # region name -> dest addr
    if args.stage >= 2:
        regions = man["regions"]
        bank_doc = toml_loads(args.bank_map.read_text())
        src_bank_origin = _int(bank_doc["origins"][man["src_set"]])
        src_zip = args.vsavj.parent / f"{man['src_set']}.zip"
        src_data_img = load_vsavj(src_zip)  # raw data view of the source set

        def table_addr_src(tname):
            t = bank[tname]
            es = (t["span"] // 32) if t["kind"] == "byte2d" else (t["stride"] // 32)
            src_slot = _int(port["port"]["src_char"])
            return (src_bank_origin + (_int(t["vsavj"]) - VSAVJ_ORIGIN)
                    + src_slot * es)
        want = stage_regions(regions, args.stage)
        # [table_fix] (stage-gated): a ported region carrying a truncated
        # engine table grows to cover it; the blob pad + table rewrite
        # happen in the blob pass below. Must run BEFORE allocation so
        # the placement reserves the padded length.
        tf = port.get("table_fix")
        if tf and args.stage >= _int(tf.get("stage", 0)):
            tfr = regions.get(tf["region"])
            if tfr and tfr["len"] < _int(tf["pad_len"]):
                notes.append(f"# table_fix: region {tf['region']} len "
                             f"{tfr['len']:#x} -> {_int(tf['pad_len']):#x} "
                             f"({tf['note']})")
                tfr["len"] = _int(tf["pad_len"])
        # [[pcrel_escape_fix]] (14z-66): engine-style cloned regions carry
        # PC-RELATIVE word-form branches (bra/bsr/Bcc.w) escaping the
        # region — INVISIBLE to the sibling oracle (both games preserve
        # spacing, so the displacement bytes diff clean) and unrewritable
        # in place (no Bcc abs.l exists). Found when the x02592a jump-clone
        # froze mid-anim: its `bpl.w 0x271C4` kept the vs2 displacement and
        # branched into unrelated placed bytes. Reserve a trampoline pad
        # ADJACENT to the region (the branch must reach it with a word
        # displacement); the blob pass rewrites each escape to a
        # `jmp <resolved>.l` trampoline in the pad. Must run before
        # allocation so placement reserves the pad.
        pcrel_fixes = {}
        for pf in port.get("pcrel_escape_fix", []):
            if args.stage < _int(pf.get("stage", 4)):
                continue
            pfr = regions.get(pf["region"])
            if pfr:
                pcrel_fixes[pf["region"]] = pfr["len"]
                pfr["len"] += _int(pf.get("pad", 0x120))

        # allocate every wanted region first (deterministic order: code
        # first so it stays in the encrypted hole, then data)
        hole_b_set = set(x.strip() for x in
                         port["port"].get("hole_b_regions", "").split(",") if x)
        # layout groups: regions that PC-reference each other must keep
        # their SOURCE-relative spacing (PC-relative displacements — both
        # direct and via word jump tables — are invisible to the oracle
        # because the sibling games preserve spacing too). Allocate the
        # whole span; recycle the inter-region gaps via gap_free.
        grouped = set()
        for grp in port.get("layout_group", []):
            members = [m for m in grp["regions"].split(",")
                       if m in regions and m in want]
            if not members:
                continue
            base_src = min(regions[m]["src"] for m in members)
            span_end = max(regions[m]["src"] + regions[m]["len"]
                           for m in members)
            span = span_end - base_src
            gbase = alloc("a", span, f"layout group ({grp['regions']})")
            if gbase is None:
                continue
            covered = sorted((regions[m]["src"] - base_src,
                              regions[m]["src"] - base_src + regions[m]["len"])
                             for m in members)
            pos = 0
            for cs, ce in covered:
                if cs - pos >= 0x20:
                    gap_free.append((gbase + pos + 0xF & ~0xF, gbase + cs))
                pos = ce
            for m in members:
                placed[m] = gbase + (regions[m]["src"] - base_src)
                grouped.add(m)
                fragments.append((placed[m], regions[m]["len"], "VS2",
                                  f"donovan {m} (grouped, vsav2 0x{regions[m]['src']:06X})"))
            notes.append(f"# layout group at {gbase:#x}+{span:#x}: "
                         + ", ".join(f"{m}@{placed[m]:#x}" for m in members)
                         + f"; {sum(ge-gs for gs, ge in gap_free):#x} gap bytes recycled")
        # near_map: satellite regions that must land within d16 reach of an
        # anchor region (PC-rel table-entry rewrites) — placed after it
        near_map = {}
        for pair in port["port"].get("near_map", "").split(","):
            if "=" in pair:
                sat, anchor = pair.split("=")
                near_map[sat.strip()] = anchor.strip()
        for name in sorted(want, key=lambda n: (regions[n]["kind"] != "code", n)):
            if name in grouped or name in near_map:
                continue
            r = regions[name]
            hole = "b" if name in hole_b_set else "a"
            d = alloc(hole, r["len"], f"region {name}")
            if d is not None:
                placed[name] = d
                fragments.append((d, r["len"], "VS2",
                                  f"donovan {name} (vsav2 0x{r['src']:06X})"))
        for name, anchor in near_map.items():
            if name not in want or name not in regions:
                continue
            r = regions[name]
            want_at = placed.get(anchor)
            if want_at is None:
                fail.append(f"near_map: anchor {anchor} unplaced for {name}")
                continue
            best = None
            for gi, (gs, ge) in enumerate(gap_free):
                if ge - gs >= r["len"] and abs(gs - want_at) < 0x6000:
                    if best is None or abs(gs - want_at) < abs(gap_free[best][0] - want_at):
                        best = gi
            if best is not None:
                gs, ge = gap_free[best]
                placed[name] = gs
                gap_free[best] = ((gs + r["len"] + 0xF) & ~0xF, ge)
            else:
                d = alloc("a", r["len"], f"region {name} (near {anchor})")
                if d is None:
                    continue
                if abs(d - want_at) >= 0x6000:
                    fail.append(f"near_map: {name} landed {d:#x}, too far "
                                f"from {anchor} at {want_at:#x}")
                placed[name] = d
            if name in placed:
                fragments.append((placed[name], r["len"], "VS2",
                                  f"donovan {name} (near {anchor}, vsav2 "
                                  f"0x{r['src']:06X})"))

        def region_of(target):
            for name, r in regions.items():
                if r["len"] > 0 and r["src"] <= target < r["src"] + r["len"]:
                    return name
            return None

        patched_clones = {}  # target -> placed clone address

        def patched_clone_for(tgt, m, where):
            """vs2-only entry points whose vsavj "twin" is a FALSE byte-match
            (e.g. vs2 0x5C77E = the UNMASKED set-anim entry; vsavj embeds
            `andi.w #$ff,d0` mid-routine with no unmasked entry — Donovan's
            sword anim numbers 0x124-0x201 truncate through it, round-26
            sword-swing root cause). Synthesize the true equivalent: clone
            the vanilla routine bytes and apply the row's patch (old->new,
            deletion allowed), placed once in hole a."""
            if tgt not in patched_clones:
                src = _int(m["clone_src"])
                ln = _int(m["clone_len"])
                body = bytearray(
                    (root / "build/out/vsavj_opcodes.bin").read_bytes()[src:src + ln])
                old = bytes.fromhex(m["patch_old"])
                new = bytes.fromhex(m.get("patch_new", ""))
                i = bytes(body).find(old)
                if i < 0 or bytes(body).find(old, i + 1) >= 0:
                    fail.append(f"{where}: patched_clone {tgt:#x}: patch_old "
                                f"not found or not unique in clone span")
                    return None
                body[i:i + len(old)] = new
                cd = alloc("a", len(body), f"patched clone {tgt:#x}")
                if cd is None:
                    return None
                ops.append({"op": "code", "addr": f"{cd:#x}",
                            "hex": bytes(body).hex()})
                notes.append(f"code   {cd:#08x} +{len(body):#x}  patched clone "
                             f"of {src:#x} for vs2 {tgt:#x} ({m.get('note','')[:40]})")
                fragments.append((cd, len(body), "GEN",
                                  f"patched clone {src:#06x} (vs2 {tgt:#06x})"))
                patched_clones[tgt] = cd
            return patched_clones[tgt]

        tripwires = {}  # unresolved target -> planted-ILLEGAL address

        def tripwire_for(tgt, where):
            if tgt not in tripwires:
                d = alloc("a", 2, f"tripwire {tgt:#x}")
                if d is None:
                    return None
                ops.append({"op": "code", "addr": f"{d:#x}", "hex": "4afc"})
                notes.append(f"code   {d:#08x} ILLEGAL  TRIPWIRE for "
                             f"unresolved {tgt:#x}")
                tripwires[tgt] = d
            notes.append(f"# {where}: unresolved {tgt:#x} -> tripwire "
                         f"{tripwires[tgt]:#x}")
            return tripwires[tgt]

        # ported code assumes VIRGIN pool slots (vs2 spawns before any
        # recycling); our timeline hands it dirty ones — uninitialized
        # bytes (+5 substate, +0x3C mode, ...) then feed jump tables.
        # Wrap the mapped allocators with a zero-fill (category byte at +8
        # preserved; only HIS calls are wrapped, vanilla allocs untouched).
        alloc_wrap_set = {_int(x) for x in
                          port["port"].get("alloc_wrap", "").split(",") if x}
        alloc_wrappers = {}

        def alloc_wrapper_for(tgt, where):
            if tgt in alloc_wrappers:
                return alloc_wrappers[tgt]
            m = recon.get(tgt)
            if not (m and m.get("status") == "verified"):
                fail.append(f"{where}: alloc_wrap target {tgt:#x} has no "
                            f"verified alloc mapping")
                return None
            real = _int(m["vsavj"])
            wd = alloc("a", 44, f"alloc wrapper {tgt:#x}")
            if wd is None:
                return None
            code = (bytes([0x4E, 0xB9]) + real.to_bytes(4, "big")  # jsr real
                    + bytes([0x67, 0x20])                          # beq.s done
                    + bytes([0x48, 0xE7, 0xC0, 0x80])              # movem.l d0-d1/a0,-(sp)
                    + bytes([0x10, 0x2C, 0x00, 0x08])              # move.b (8,A4),d0
                    + bytes([0x20, 0x4C])                          # movea.l A4,A0
                    + bytes([0x32, 0x3C, 0x00, 0x1F])              # move.w #31,d1
                    + bytes([0x42, 0x98])                          # clr.l (a0)+
                    + bytes([0x51, 0xC9, 0xFF, 0xFC])              # dbra d1,-4
                    + bytes([0x19, 0x40, 0x00, 0x08])              # move.b d0,(8,A4)
                    + bytes([0x4C, 0xDF, 0x01, 0x03])              # movem.l (sp)+
                    + bytes([0xB8, 0xFC, 0x00, 0x00])              # cmpa.w #0,A4
                    + bytes([0x4E, 0x75]))                         # rts
            ops.append({"op": "code", "addr": f"{wd:#x}", "hex": code.hex()})
            notes.append(f"code   {wd:#08x} slot-clearing alloc wrapper for "
                         f"{tgt:#x} -> {real:#x} (0x80 cleared, +8 preserved)")
            fragments.append((wd, 44, "GEN", f"alloc wrapper {tgt:#x}"))
            alloc_wrappers[tgt] = wd
            return wd

        farm_ports = {}

        def farm_port_for(tgt, m, where):
            """vsav2-added predicate-farm entries are pure PC-relative
            (`lea (d16,PC),A3; bra.w common`) and cannot relocate as bytes.
            Synthesize the absolute equivalent: copy the 8-byte parameter
            block, then `lea <param>.l,A3; jmp <vsavj common>.l`."""
            if tgt not in farm_ports:
                param = bytes.fromhex(m["param_hex"])
                pd = alloc("a", len(param), f"farm param {tgt:#x}")
                sd = alloc("a", 12, f"farm stub {tgt:#x}")
                if pd is None or sd is None:
                    return None
                ops.append({"op": "data", "addr": f"{pd:#x}", "hex": param.hex()})
                stub = (bytes([0x47, 0xF9]) + pd.to_bytes(4, "big")
                        + bytes([0x4E, 0xF9]) + _int(m["common"]).to_bytes(4, "big"))
                ops.append({"op": "code", "addr": f"{sd:#x}", "hex": stub.hex()})
                notes.append(f"code   {sd:#08x} farm-port stub for {tgt:#x} "
                             f"(param at {pd:#08x}, common {_int(m['common']):#x})")
                fragments.append((sd, 12, "GEN", f"farm-port stub {tgt:#x}"))
                farm_ports[tgt] = sd
            return farm_ports[tgt]

        def relocate_target(ref, where):
            """New vsavj address for a ref target, or None + fail note."""
            cls = ref.get("class", "internal")
            tgt = ref["target"]
            # a placed region always wins: refs whose sibling-drift delta
            # got them classified 'engine' still relocate internally when
            # the target lives inside ported/extracted code or data
            host0 = region_of(tgt)
            if host0 and host0 in placed:
                return tgt + (placed[host0] - regions[host0]["src"])
            if cls == "internal":
                host = region_of(tgt)
                if host and host in placed:
                    return tgt + (placed[host] - regions[host]["src"])
                if host:
                    fail.append(f"{where}: ref -> {tgt:#x} in region {host} "
                                f"not placed at this stage")
                    return None
                fail.append(f"{where}: internal ref -> {tgt:#x} outside regions")
                return None
            if cls == "bank_ref":
                m = recon.get(tgt)
                if m and m.get("status") == "verified":
                    return _int(m["vsavj"])
                # auto-verify by the bank delta rule: (a) candidate carries
                # byte-identical content (shared constants), or (b) candidate
                # is exactly a known bank-table base (the cross-set layout
                # identity is the atlas's core verified fact; per-char table
                # CONTENTS legitimately differ)
                cand = VSAVJ_ORIGIN + (tgt - src_bank_origin)
                if 0 <= cand < len(vj) and src_data_img[tgt:tgt + 16] == vj[cand:cand + 16]:
                    notes.append(f"# bank_ref {tgt:#x} -> {cand:#x} "
                                 f"(delta rule, 16B byte-identical)")
                    return cand
                if any(_int(t["vsavj"]) == cand for t in bank.values()):
                    notes.append(f"# bank_ref {tgt:#x} -> {cand:#x} "
                                 f"(delta rule, known table base)")
                    return cand
                fail.append(f"{where}: bank_ref {tgt:#x} (delta-rule candidate "
                            f"{cand:#x}) failed byte-identity — needs a "
                            f"verified reconciliation row")
                return None
            if cls in ("engine", "pcrel16", "code_neighbor"):
                if tgt in alloc_wrap_set:
                    return alloc_wrapper_for(tgt, where)
                m = recon.get(tgt)
                if m and m.get("kind") == "farm_port":
                    return farm_port_for(tgt, m, where)
                if m and m.get("kind") == "patched_clone":
                    return patched_clone_for(tgt, m, where)
                ok = m and (m.get("status") == "verified"
                            or (args.allow_plausible
                                and m.get("status") == "plausible"))
                if ok:
                    return _int(m["vsavj"])
                if args.tripwire_open:
                    return tripwire_for(tgt, where)
                fail.append(f"{where}: {cls} ref {tgt:#x} unresolved "
                            f"(reconciliation row missing/unverified)")
                return None
            fail.append(f"{where}: unknown ref class {cls} -> {tgt:#x}")
            return None

        for name in sorted(placed):
            r = regions[name]
            blob = bytearray((args.extract_dir / f"region_{name}.bin").read_bytes())
            # [table_fix] pad + whole-table rewrite (see the config note in
            # donovan.toml): zero-pad the blob to the reserved length and
            # write the documented row values at the table offset.
            if (tf and tf["region"] == name
                    and args.stage >= _int(tf.get("stage", 0))):
                rows = bytearray(bytes.fromhex(tf["rows_hex"]))
                toff = _int(tf["table_off"])
                if len(blob) < r["len"]:
                    blob.extend(b"\x00" * (r["len"] - len(blob)))
                # The rows above are the VANILLA vsavj table. The tenant's own
                # row is then written explicitly from its declared gfx bank.
                # Until now nothing wrote a tenant row at all: the build
                # worked only because the tenant sat in Jedah's slot, whose
                # vanilla row (0x0F = 0x4000) already names the bank the tiles
                # were placed in. That coincidence dies the moment the tenant
                # moves — row 0x13's vanilla value is 0x2000 — so make it
                # explicit rather than inherited.
                _tid = _int(port["port"]["dst_slot"])
                _tbank = _int(port["port"].get("gfx_bank", 2))
                from gfx_tiles import bank_word as _bw
                if (_tid + 1) * 2 <= len(rows):
                    _was = int.from_bytes(rows[_tid * 2:_tid * 2 + 2], "big")
                    rows[_tid * 2:_tid * 2 + 2] = _bw(_tbank).to_bytes(2, "big")
                    notes.append(f"# {name}+{toff + _tid * 2:#x}: bank table "
                                 f"row {_tid:#04x} <- {_bw(_tbank):#06x} "
                                 f"(bank {_tbank}, WIDE encoding; vanilla row "
                                 f"was {_was:#06x}) — tenant-driven")
                else:
                    fail.append(f"table_fix: tenant id {_tid:#04x} is beyond "
                                f"the {len(rows) // 2}-row bank table; the "
                                f"table must be widened before a tenant can "
                                f"live there")
                blob[toff:toff + len(rows)] = bytes(rows)
                notes.append(f"# {name}+{toff:#x}: table_fix {len(rows)} "
                             f"bytes ({tf['note']})")
            # [[region_fix]] (14z-27): guarded byte patches inside an
            # extractor region blob (old-verified against the extracted
            # source bytes) — for value-level porting decisions the
            # extraction faithfully copies but the host engine needs
            # differently (e.g. hit-class remaps).
            for rf in port.get("region_fix", []):
                if rf["region"] != name or args.stage < _int(rf.get("stage", 0)):
                    continue
                roff = _int(rf["off"])
                rold = bytes.fromhex(rf["old_hex"])
                rnew = bytes.fromhex(rf["new_hex"])
                if bytes(blob[roff:roff + len(rold)]) != rold:
                    fail.append(f"region_fix {name}+{roff:#x}: old bytes "
                                f"mismatch ({bytes(blob[roff:roff+len(rold)]).hex()})")
                    continue
                blob[roff:roff + len(rnew)] = rnew
                notes.append(f"# {name}+{roff:#x}: region_fix "
                             f"{rold.hex()} -> {rnew.hex()} ({rf.get('note','')})")
            for ref in r.get("refs", []):
                if ref["width"] == 16:
                    # pcrel16 (14z-65): a PC-relative word displacement whose
                    # target drifted between the siblings — it reaches
                    # OUTSIDE its co-moving span (measured: x055478's
                    # `jmp (d16,PC)` into x057456, the regions' separation
                    # differs by the 6-byte sibling insertion). The 68k base
                    # is the extension word's own address. Rewrite the
                    # displacement against actual placement.
                    site_src = r["src"] + ref["off"]
                    disp_src = (ref["target"] ^ 0x8000) - 0x8000
                    tgt_abs = (site_src + disp_src) & 0xFFFFFF
                    host = region_of(tgt_abs)
                    if host is None or host not in placed:
                        fail.append(f"{name}+{ref['off']:#x}: pcrel16 target "
                                    f"{tgt_abs:#x} not in a placed region")
                        continue
                    new_tgt = tgt_abs + (placed[host] - regions[host]["src"])
                    new_site = placed[name] + ref["off"]
                    disp = new_tgt - new_site
                    if not (-0x8000 <= disp <= 0x7FFF):
                        fail.append(f"{name}+{ref['off']:#x}: pcrel16 "
                                    f"displacement {disp:#x} out of i16 range "
                                    f"— bring the regions closer "
                                    f"(layout_group/near_map)")
                        continue
                    blob[ref["off"]:ref["off"] + 2] = \
                        (disp & 0xFFFF).to_bytes(2, "big")
                    notes.append(f"# {name}+{ref['off']:#x}: pcrel16 -> "
                                 f"{host}@{tgt_abs:#x} (disp {disp_src:#x} -> "
                                 f"{disp & 0xFFFF:#x} after placement)")
                    continue
                newt = relocate_target(ref, f"{name}+{ref['off']:#x}")
                if newt is None:
                    continue
                span = ref["width"] // 8
                blob[ref["off"]:ref["off"] + span] = newt.to_bytes(span, "big")
            # ported code carries the source game's char id in immediates —
            # src_char there, dst_slot here (scan-confirmed sites only; the
            # literal was 0x13 until 14z-65, silently missing any other
            # tenant's sites)
            src_id = _int(port["port"]["src_char"])
            for off in r.get("charid_sites", []):
                if blob[off:off + 2] == bytes([0x00, src_id]):
                    blob[off:off + 2] = bytes([0x00, dst_slot])
                    notes.append(f"# {name}+{off:#x}: char-id imm "
                                 f"{src_id:#x} -> {dst_slot:#x}")
            # PC-relative escapes (word-table entries / direct d16) from
            # source-only regions: rewrite each displacement against actual
            # placement; unresolved targets -> a shared per-region tripwire
            # (within d16 reach), so an exercised-but-unported state is LOUD
            pr_trip = None
            for ref in r.get("pcrel_refs", []):
                tgt = ref["target"]
                host = region_of(tgt)
                if host and host in placed:
                    resolved = tgt + (placed[host] - regions[host]["src"])
                else:
                    if pr_trip is None:
                        # must sit within d16 reach of the region: gap-fit
                        # near the region's placement
                        want = placed[name]
                        best = None
                        for gi, (gs, ge) in enumerate(gap_free):
                            if ge - gs >= 2 and abs(gs - want) < 0x7000:
                                if best is None or abs(gs - want) < abs(gap_free[best][0] - want):
                                    best = gi
                        if best is not None:
                            gs, ge = gap_free[best]
                            pr_trip = gs
                            gap_free[best] = ((gs + 2 + 0xF) & ~0xF, ge)
                        else:
                            pr_trip = alloc("a", 2, f"pcrel tripwire {name}")
                        if pr_trip is not None:
                            ops.append({"op": "code", "addr": f"{pr_trip:#x}",
                                        "hex": "4afc"})
                            notes.append(f"code   {pr_trip:#08x} ILLEGAL  "
                                         f"shared pcrel TRIPWIRE for {name}")
                    resolved = pr_trip
                if resolved is None:
                    continue
                pc_base = placed[name] + ref["base_off"]
                disp = resolved - pc_base
                if not (-0x8000 <= disp < 0x8000):
                    # NEAR JMP TRAMPOLINE (14z-65): a pcrel word-table entry
                    # resolving beyond d16 reach (Huitzil's copy of the
                    # per-game x088512 zone dispatches into vsavj engine
                    # code) bounces through a 6-byte jmp abs.l within reach.
                    # Only valid for CODE targets — these entries are
                    # dispatch tables; a far pcrel DATA read would need its
                    # data copied near instead (no such case yet; the
                    # trampoline jmp would fault loudly, not read wrong
                    # data). Donovan-inert: this branch was a hard fail
                    # before, so no frozen build ever reached it.
                    tr = pcrel_far_tramps.get(resolved)
                    if tr is None:
                        want = placed[name]
                        best = None
                        for gi, (gs, ge) in enumerate(gap_free):
                            if ge - gs >= 6 and abs(gs - want) < 0x7000:
                                if best is None or abs(gs - want) < \
                                        abs(gap_free[best][0] - want):
                                    best = gi
                        if best is not None:
                            gs, ge = gap_free[best]
                            tr = gs
                            gap_free[best] = ((gs + 6 + 0xF) & ~0xF, ge)
                        else:
                            tr = alloc("a", 6, f"pcrel far trampoline {name}")
                        if tr is None:
                            fail.append(f"{name}+{ref['off']:#x}: no room "
                                        f"for a pcrel far trampoline")
                            continue
                        ops.append({"op": "code", "addr": f"{tr:#x}",
                                    "hex": "4ef9" + f"{resolved:08x}"})
                        notes.append(f"code   {tr:#08x} jmp {resolved:#08x}"
                                     f"  pcrel far trampoline ({name})")
                        fragments.append((tr, 6, "GEN",
                                          f"pcrel far trampoline ({name} -> "
                                          f"{resolved:#x})"))
                        pcrel_far_tramps[resolved] = tr
                    disp = tr - pc_base
                    if not (-0x8000 <= disp < 0x8000):
                        fail.append(f"{name}+{ref['off']:#x}: pcrel far "
                                    f"trampoline still out of d16 range "
                                    f"({disp:#x})")
                        continue
                blob[ref["off"]:ref["off"] + 2] = \
                    (disp & 0xFFFF).to_bytes(2, "big")
            n_pr = len(r.get("pcrel_refs", []))
            if n_pr:
                notes.append(f"# {name}: {n_pr} pcrel escape entries "
                             f"rewritten (tripwire at "
                             f"{pr_trip:#x})" if pr_trip else
                             f"# {name}: {n_pr} pcrel escape entries rewritten")

            # poisoned immediates (donovan.toml [[imm_poison]]): unreachable
            # movea.l #imm operands whose target is deliberately unported —
            # repointed at a shared poison table (odd-value words) so any
            # future writer that makes the branch reachable faults loudly
            # (vec3, A0 = the poison block) instead of silently reading
            # unrelated vsavj bytes
            for ip in port.get("imm_poison", []):
                if ip["region"] != name:
                    continue
                off = _int(ip["src_addr"]) - r["src"]
                old = _int(ip["old_imm"]).to_bytes(4, "big")
                if not (0 <= off < r["len"]) or blob[off:off + 4] != old:
                    fail.append(f"imm_poison {ip['note']}: bytes at "
                                f"{name}+{off:#x} != {old.hex()}")
                    continue
                if "poison_addr" not in port:
                    pa = alloc("a", 16, "imm_poison table")
                    if pa is None:
                        continue
                    ops.append({"op": "data", "addr": f"{pa:#x}",
                                "hex": "0001" * 8})
                    notes.append(f"data   {pa:#08x} +0x10  imm_poison table "
                                 f"(odd-entry words -> vec3 on use)")
                    fragments.append((pa, 16, "GEN", "imm_poison table"))
                    port["poison_addr"] = pa
                blob[off:off + 4] = port["poison_addr"].to_bytes(4, "big")
                notes.append(f"# {name}+{off:#x}: imm_poison {old.hex()} -> "
                             f"{port['poison_addr']:#x} ({ip['note']})")

            # targeted port patches (donovan.toml [[port_patch]]): documented
            # byte edits on ported code, old bytes verified. Rows may carry
            # a minimum stage (e.g. the M2b gfx-bank patches are stage-6
            # only, keeping stage-5 builds byte-identical to the freeze).
            for pp in port.get("port_patch", []):
                if pp["region"] != name:
                    continue
                if args.stage < _int(pp.get("stage", 0)):
                    continue
                off = _int(pp["src_addr"]) - r["src"]
                old = bytes.fromhex(pp["old_hex"])
                # new_hex_variant (14z-62d): a row whose replacement value
                # depends on WHERE the tenant lives — the OBJ bank setters
                # write the host band's word at a base-half slot and the
                # WIDE group-C word at a variant id.
                _nh = pp["new_hex"]
                if dst_slot >= 0x10 and "new_hex_variant" in pp:
                    _nh = pp["new_hex_variant"]
                new = bytes.fromhex(_nh)
                if not (0 <= off < r["len"]) or blob[off:off + len(old)] != old:
                    fail.append(f"port_patch {pp['note']}: bytes at "
                                f"{name}+{off:#x} != {pp['old_hex']}")
                    continue
                blob[off:off + len(new)] = new
                notes.append(f"# {name}+{off:#x}: port_patch {pp['old_hex']} "
                             f"-> {_nh} ({pp['note']})")

            # data_in_code (14z-66): a small DATA table embedded in a CODE
            # region placed in the crypt hole is stored re-encrypted, so
            # opcode fetches through it decrypt fine but runtime DATA READS
            # see garbage (the 14z-20 class in region form — found via the
            # FG capture-pose random table: draws like 0xFF over-ran every
            # victim's capture table). Each row relocates the table's
            # SOURCE-DATA-VIEW bytes to a RAW hole and reroutes the
            # region's reader through a 12-byte helper there. The only
            # supported reader shape is `lea (d16,pc),a1 + move.b
            # (a1,d0.w),d0` (8 bytes -> jsr helper + nop): lea sets no
            # flags and the helper's move.b sets NZ exactly like the
            # displaced one, so the reroute is ghost-clean.
            for dc in port.get("data_in_code", []):
                if dc["region"] != name:
                    continue
                if args.stage < _int(dc.get("stage", 4)):
                    continue
                t_src, t_len = _int(dc["table"]), _int(dc["table_len"])
                rd_src = _int(dc["reader"])
                rd_off = rd_src - r["src"]
                dold = bytes.fromhex(dc["reader_old_hex"])
                shape = dc.get("shape", "indexed")
                _lw = int.from_bytes(dold[0:2], "big") if len(dold) >= 2 else 0
                _rw = int.from_bytes(dold[4:6], "big") if len(dold) == 8 else 0
                _an = (_lw >> 9) & 7
                # shape "indexed": lea (d16,pc),An then a read whose EA is
                # (An,Xn.w) (mode 6, reg An) — the read op + its brief
                # extension word are copied verbatim into the helper, so any
                # size/index register works as long as it consumes the lea'd
                # An.
                # shape "postinc" (14z-69): the reader is a `move (An)+`
                # walk that may sit ARBITRARILY FAR from the lea, in another
                # basic block (measured: 0x3E bytes away inside a bsr
                # subroutine), so the 8-byte jsr+nop rewrite cannot reach
                # it. Only the POINTER needs redirecting: the 4-byte lea
                # becomes `bsr.w helper` and the helper reloads An with the
                # relocated table address. Same ghost-clean argument — lea
                # sets no flags, bsr/rts set none either.
                if shape in ("pointer", "postinc", "indexed-far"):
                    shape = "pointer"
                    if len(dold) != 4 or (_lw & 0xF1FF) != 0x41FA:
                        fail.append(f"data_in_code {dc['note']}: pointer "
                                    f"reader_old_hex must be the 4-byte "
                                    f"lea(d16,pc),An alone")
                        continue
                # shape "pointer-inline" (14z-74, Pyron's air dive): the site
                # is `lea (d16,pc),An` followed by a NOP the original build
                # left there. lea.l #imm32,An is exactly those 6 bytes, so the
                # pointer can be redirected IN PLACE — no helper, no
                # allocation, and none of the bsr.w reach constraint that
                # makes "pointer" fail when the near gaps are empty. Same
                # ghost-clean argument as the other shapes: LEA and NOP both
                # set no flags, so nothing downstream can observe the swap.
                elif shape == "pointer-inline":
                    if (len(dold) != 6 or (_lw & 0xF1FF) != 0x41FA
                            or int.from_bytes(dold[4:6], "big") != 0x4E71):
                        fail.append(f"data_in_code {dc['note']}: "
                                    f"pointer-inline reader_old_hex must be "
                                    f"lea(d16,pc),An followed by a NOP")
                        continue
                elif (len(dold) != 8 or (_lw & 0xF1FF) != 0x41FA
                        or (_rw & 0x0038) != 0x0030 or (_rw & 7) != _an
                        or (_rw >> 12) not in (1, 2, 3)):
                    fail.append(f"data_in_code {dc['note']}: reader_old_hex "
                                f"must be lea(d16,pc),An + a move read via "
                                f"(An,Xn.w)")
                    continue
                _n = len(dold)
                if not (0 <= rd_off < r["len"]) or blob[rd_off:rd_off + _n] != dold:
                    fail.append(f"data_in_code {dc['note']}: bytes at "
                                f"{name}+{rd_off:#x} != reader_old_hex")
                    continue
                disp = int.from_bytes(dold[2:4], "big", signed=True)
                if rd_src + 2 + disp != t_src:
                    fail.append(f"data_in_code {dc['note']}: lea targets "
                                f"{rd_src + 2 + disp:#x}, row says {t_src:#x}")
                    continue
                tbl_bytes = src_data_img[t_src:t_src + t_len]
                dc_hole = dc.get("hole", "b")
                # one DATA copy per (table, len): the same stream is read
                # from several sites (x06cac0 reads 0x6D91C from three).
                ta = dc_tables.get((t_src, t_len))
                if ta is None:
                    ta = alloc(dc_hole, t_len, f"data_in_code table")
                    if ta is None:
                        continue
                    dc_tables[(t_src, t_len)] = ta
                    ops.append({"op": "data", "addr": f"{ta:#x}",
                                "hex": tbl_bytes.hex()})
                    fragments.append((ta, t_len, "VS2",
                                      f"data_in_code table ({dc['note']})"))
                if shape == "pointer":
                    # helper: lea.l #table,An ; rts  — reached by a 4-byte
                    # bsr.w, so it must land within d16 of the SITE. Prefer
                    # a near gap, exactly like the pcrel far trampolines.
                    site = placed[name] + rd_off
                    ha = None
                    for gi, (gs, ge) in enumerate(gap_free):
                        if ge - gs >= 8 and abs(gs - site) < 0x7000:
                            ha = gs
                            gap_free[gi] = ((gs + 8 + 0xF) & ~0xF, ge)
                            break
                    if ha is None:
                        # the TABLE goes to a raw hole (data reads must see
                        # it verbatim), but the HELPER is pure code and has
                        # to be within bsr.w reach of the site — so it comes
                        # from the CRYPT hole that holds the placed regions
                        # themselves, not from the row's table hole (which
                        # defaults to "b" at 0x3EC720+, ~0x32xxxx away).
                        ha = alloc(dc.get("helper_hole", "a"), 8,
                                   "data_in_code pointer helper")
                    if ha is None:
                        continue
                    disp = ha - (site + 2)
                    if not (-0x8000 <= disp < 0x8000):
                        fail.append(f"data_in_code {dc['note']}: pointer "
                                    f"helper out of bsr.w reach ({disp:#x})")
                        continue
                    helper = ((0x41F9 | (_an << 9)).to_bytes(2, "big")
                              + ta.to_bytes(4, "big") + bytes.fromhex("4e75"))
                    ops.append({"op": "code", "addr": f"{ha:#x}",
                                "hex": helper.hex()})
                    blob[rd_off:rd_off + 4] = (bytes.fromhex("6100")
                                               + (disp & 0xFFFF).to_bytes(2, "big"))
                    fragments.append((ha, 8, "GEN",
                                      f"data_in_code pointer helper "
                                      f"({dc['note']})"))
                    notes.append(f"# {name}+{rd_off:#x}: data_in_code "
                                 f"[pointer] bsr.w -> helper {ha:#08x}, "
                                 f"table {ta:#08x} (DATA view of "
                                 f"{man['src_set']} {t_src:#08x}; "
                                 f"{dc['note']})")
                    continue
                elif shape == "pointer-inline":
                    # lea (d16,pc),An + nop  ->  lea.l #table,An  (6 bytes)
                    blob[rd_off:rd_off + 6] = (
                        (0x41F9 | (_an << 9)).to_bytes(2, "big")
                        + ta.to_bytes(4, "big"))
                    notes.append(f"# {name}+{rd_off:#x}: data_in_code "
                                 f"[pointer-inline] lea.l #{ta:#08x},a{_an} "
                                 f"in place (DATA view of {man['src_set']} "
                                 f"{t_src:#08x}; {dc['note']})")
                    continue
                ha = alloc(dc_hole, 12, f"data_in_code helper")
                if ha is None:
                    continue
                helper = ((0x41F9 | (_an << 9)).to_bytes(2, "big")
                          + ta.to_bytes(4, "big")
                          + dold[4:8] + bytes.fromhex("4e75"))
                ops.append({"op": "code", "addr": f"{ha:#x}",
                            "hex": helper.hex()})
                blob[rd_off:rd_off + 8] = (bytes.fromhex("4eb9")
                                           + ha.to_bytes(4, "big")
                                           + bytes.fromhex("4e71"))
                notes.append(f"# {name}+{rd_off:#x}: data_in_code reroute -> "
                             f"helper {ha:#08x}, table {ta:#08x} (DATA view "
                             f"of {man['src_set']} {t_src:#08x}; "
                             f"{dc['note']})")
                fragments.append((ha, 12, "GEN",
                                  f"data_in_code helper ({dc['note']})"))

            # pcrel_escape_fix blob pass (14z-66; see the pre-allocation
            # comment). Rewrites every word-form pcrel branch escaping the
            # ORIGINAL span to a trampoline in the pad: resolved targets
            # (another placed region, or a verified recon row) get
            # `jmp <resolved>.l`; unresolved ones get an ILLEGAL trampoline
            # under --tripwire-open (loud, attributable) and a hard fail
            # without it. Trampolines dedup per resolved target.
            if name in pcrel_fixes:
                orig_len = pcrel_fixes[name]
                if len(blob) < r["len"]:
                    blob.extend(b"\x00" * (r["len"] - len(blob)))
                tramp_off = orig_len
                tramp_of = {}
                n_esc = n_trip = 0
                # 14z-74 (maintainer-approved D5): the [table_fix] bank-word
                # table is DATA, not code — but this scan treats any
                # `0x6000`-form word as a bra.w/bsr.w and rewrites the word
                # AFTER it to a trampoline displacement. table_fix writes that
                # table earlier in this same loop iteration, so every row
                # holding 0x6000 silently clobbered the row following it.
                # Measured: Huitzil's rows 0x01/0x0A/0x0C emerged as
                # 0074/0068/006a (garbage bank words, baked into manifests as
                # fixed points of the bug), and Pyron's TENANT row 0x11 lost
                # its 0x1000 -> 0x0066. Huitzil escaped only because his own
                # row 0x10 = 0x1000 is not a branch form. Exclude the table.
                tf_span = None
                if (tf and tf["region"] == name
                        and args.stage >= _int(tf.get("stage", 0))):
                    _to = _int(tf["table_off"])
                    tf_span = (_to, _to + len(bytes.fromhex(tf["rows_hex"])))
                i = 0
                while i + 4 <= orig_len:
                    if tf_span and tf_span[0] <= i < tf_span[1]:
                        i = tf_span[1]
                        continue
                    w = int.from_bytes(blob[i:i + 2], "big")
                    if (w & 0xF000) == 0x6000 and (w & 0xFF) == 0:
                        disp = int.from_bytes(blob[i + 2:i + 4], "big")
                        if disp >= 0x8000:
                            disp -= 0x10000
                        tgt = r["src"] + i + 2 + disp
                        if not (r["src"] <= tgt < r["src"] + orig_len):
                            res = None
                            host = region_of(tgt)
                            if host and host in placed:
                                res = tgt + (placed[host]
                                             - regions[host]["src"])
                            else:
                                row = recon.get(tgt)
                                if (row and row.get("status") == "verified"
                                        and _int(row.get("vsavj", 0))):
                                    res = _int(row["vsavj"])
                            key = res if res is not None else ("trip", tgt)
                            ta = tramp_of.get(key)
                            if ta is None:
                                if tramp_off + 6 > r["len"]:
                                    fail.append(f"pcrel_escape_fix {name}: "
                                                f"trampoline pad overflow")
                                    break
                                ta = tramp_off
                                if res is not None:
                                    blob[ta:ta + 6] = (b"\x4e\xf9"
                                                       + res.to_bytes(4, "big"))
                                elif args.tripwire_open:
                                    blob[ta:ta + 6] = b"\x4a\xfc" * 3
                                    notes.append(
                                        f"# {name}+{ta:#x}: ESCAPE TRIPWIRE "
                                        f"for unresolved pcrel target "
                                        f"{tgt:#x}")
                                    n_trip += 1
                                else:
                                    fail.append(f"pcrel_escape_fix {name}: "
                                                f"unresolved escape target "
                                                f"{tgt:#x} at +{i:#x}")
                                    break
                                tramp_of[key] = ta
                                tramp_off += 6
                            ndisp = ta - (i + 2)
                            blob[i + 2:i + 4] = (ndisp & 0xFFFF).to_bytes(2, "big")
                            n_esc += 1
                        i += 4
                        continue
                    i += 2
                notes.append(f"# pcrel_escape_fix {name}: {n_esc} escapes -> "
                             f"{len(tramp_of)} trampolines ({n_trip} "
                             f"tripwired), pad {orig_len:#x}..{r['len']:#x}")

            # M2b gfx remap (donovan.toml [gfx_remap], stage-gated): walk
            # the OBJ records in this region (tools/obj_records.py format,
            # decoded session 14) and shift main-band tile words by the
            # placement delta. Effect/low codes stay untouched (per-record
            # effect map is a later step; they render garbled, never crash
            # — tile codes cannot fault).
            gr = port.get("gfx_remap")
            if (gr and gr["region"] == name
                    and args.stage >= _int(gr.get("stage", 0))):
                b_lo, b_hi = _int(gr["band_lo"]), _int(gr["band_hi"])
                delta = _int(gr["delta"])
                assert delta % 16 == 0, "gfx_remap delta must be 16-aligned"
                # This pass runs AFTER ref relocation: in-region record
                # pointers and coordinate-list pointers are already
                # PLACED (dst) addresses. Scan with the dst base; a valid
                # cptr lands inside a placed aux region.
                base = placed[name]
                aux_dst = [(placed[an], placed[an] + regions[an]["len"])
                           for an in placed if an.startswith("aux")]
                seen_rec = set()
                n_rw = 0
                # Format-aware walk (tools/obj_records.py header doc):
                # format 2/8 = 4-byte (tile,attr) entries, count at +4;
                # format 0 = 2-byte tile-only entries, count at +2, one
                # attr in the header (the char-select blink lesson).
                # Two passes: collect entries, then rewrite — band codes
                # get +delta; NON-band codes (shared-effect art the main
                # objects draw at their own bank — the residual-blink
                # class, playtest round 5) get shelf-packed rectangle
                # targets in the freed Jedah-band tail [eff_lo, eff_hi],
                # emitted as effect_map.json for the tile placement step.
                def _entries(o):
                    fmt = int.from_bytes(blob[o:o + 2], "big")
                    cptr = int.from_bytes(blob[o + 6:o + 10], "big")
                    if (fmt > 0x20 or fmt % 2
                            or not any(lo <= cptr < hi
                                       for lo, hi in aux_dst)):
                        return None
                    if fmt == 0:
                        # subq #1 before dbra: entries = COUNT (session
                        # 14b corruption catch — count+1 clobbers the
                        # next record's format word via the effect map)
                        count = int.from_bytes(blob[o + 2:o + 4], "big")
                        if not (0 < count <= 0x100):
                            return None
                        attr = int.from_bytes(blob[o + 4:o + 6], "big")
                        return [(o + 10 + 2 * k, attr)
                                for k in range(count)]
                    budget = int.from_bytes(blob[o + 2:o + 4], "big")
                    count = int.from_bytes(blob[o + 4:o + 6], "big")
                    if not (0 < count + 1 <= budget <= 0x100):
                        return None
                    return [(o + 10 + 4 * k, None) for k in range(count + 1)]

                collected = []
                for i in range(0, r["len"] - 4, 2):
                    v = int.from_bytes(blob[i:i + 4], "big")
                    if not (base <= v < base + r["len"]) or v in seen_rec:
                        continue
                    ent = _entries(v - base)
                    if ent is None:
                        continue
                    seen_rec.add(v)
                    collected.append(ent)
                # sweep pass (14z-11, mirrors obj_records.walk): offset-
                # computed records (the aux-chain X-ray overlays) have no
                # in-region pointer — scan every even offset as a head
                # with the same validation so their band words remap too.
                for i in range(0, r["len"] - 10, 2):
                    v = base + i
                    if v in seen_rec:
                        continue
                    ent = _entries(i)
                    if ent is None:
                        continue
                    # sweep-only strictness (mirrors obj_records):
                    # small pieces, modest budget, band-coherent entries
                    if int.from_bytes(blob[i:i + 2], "big") != 0:
                        if int.from_bytes(blob[i + 2:i + 4], "big") > 0x40:
                            continue
                    _codes = []
                    _ok = True
                    for _toff, _ha in ent:
                        _t = int.from_bytes(blob[_toff:_toff + 2], "big")
                        _a = (_ha if _ha is not None else
                              int.from_bytes(blob[_toff + 2:_toff + 4],
                                             "big"))
                        if (((_a >> 8) & 15) + 1 > 8
                                or ((_a >> 12) & 15) + 1 > 8):
                            _ok = False
                            break
                        _codes.append(_t)
                    if not _ok or not _codes:
                        continue
                    if sum(1 for _t in _codes
                           if 0x8000 <= _t <= 0xEEBB) * 2 < len(_codes):
                        continue
                    seen_rec.add(v)
                    collected.append(ent)

                # session 14z-10: PROTECTED-TILE POLICY. Vanilla content
                # references tile positions inside the "Jedah band" window
                # (manifest protected_tiles.json, runtime-audited: the VS
                # curtain c625, the 0xE4xx-0xE8xx shared block, round-UI
                # codes — the round-27..29 garble class). One rectangle
                # first-fit allocator over the hole-punched pool serves
                # BOTH the effect shelf AND band blocks whose remapped
                # span would land on a protected position. Blocks never
                # cross a 16-column row (measured invariant, preserved).
                eff_lo, eff_hi = _int(gr["eff_lo"]), _int(gr["eff_hi"])
                prot_doc = json.loads(
                    (root / "build/manifest/protected_tiles.json").read_text())
                protected = {int(x, 16) for x in prot_doc["protected"]}
                pool_ranges = [(int(a, 16), int(b, 16))
                               for a, b in prot_doc["pool"]]
                free = set()
                for a_, b_ in pool_ranges:
                    free.update(range(a_, b_))
                free -= protected
                # effect_tail.json bank2 placements (Anita feet) live in
                # the same code space — their spans are not free
                _et = json.loads((root / "build/manifest/effect_tail.json"
                                  ).read_text())
                for _k, _v in _et.get("bank2_place", {}).items():
                    _c, _bx, _by = _k.split(",")
                    _h = int(_v, 16)
                    for _dy in range(int(_by)):
                        for _dx in range(int(_bx)):
                            free.discard((_h & ~0xF) + (_dy << 4)
                                         + ((_h + _dx) & 0xF))

                def span_of(head, bx, by):
                    return [(head & ~0xF) + (dy << 4) + ((head + dx) & 0xF)
                            for dy in range(by) for dx in range(bx)]

                def fit_block(bx, by):
                    for a_, b_ in pool_ranges:
                        for p in range(a_, b_):
                            if (p & 0xF) + bx > 16:
                                continue
                            cells = span_of(p, bx, by)
                            if any(c not in free for c in cells):
                                continue
                            for c in cells:
                                free.discard(c)
                            return p
                    return None

                blocks = {}
                nonexc_band_srcs = set()
                for ent in collected:
                    for toff, hdr_attr in ent:
                        t = int.from_bytes(blob[toff:toff + 2], "big")
                        a = (hdr_attr if hdr_attr is not None else
                             int.from_bytes(blob[toff + 2:toff + 4], "big"))
                        bx = ((a >> 8) & 15) + 1
                        by = ((a >> 12) & 15) + 1
                        if b_lo <= t <= b_hi:
                            if any(c in protected
                                   for c in span_of(t + delta, bx, by)):
                                blocks.setdefault((t, bx, by, True), None)
                            else:
                                nonexc_band_srcs.update(span_of(t, bx, by))
                                # their delta targets WILL be written by
                                # the band loop — never allocate there
                                # (the pool in the manifest is static;
                                # the sweep grows the inventory)
                                for c in span_of(t + delta, bx, by):
                                    free.discard(c)
                        else:
                            blocks.setdefault((t, bx, by, False), None)
                for key in sorted(blocks,
                                  key=lambda k: (-k[2], -k[1], k[0])):
                    t, bx, by, _isb = key
                    nt = fit_block(bx, by)
                    if nt is None:
                        fail.append(f"gfx_remap: protected-pool overflow "
                                    f"placing block {t:#x} {bx}x{by}")
                        continue
                    blocks[key] = nt

                n_eff = 0
                n_exc = 0
                for ent in collected:
                    for toff, hdr_attr in ent:
                        t = int.from_bytes(blob[toff:toff + 2], "big")
                        a = (hdr_attr if hdr_attr is not None else
                             int.from_bytes(blob[toff + 2:toff + 4], "big"))
                        bx = ((a >> 8) & 15) + 1
                        by = ((a >> 12) & 15) + 1
                        if b_lo <= t <= b_hi:
                            nt = blocks.get((t, bx, by, True))
                            if nt is not None:
                                blob[toff:toff + 2] = nt.to_bytes(2, "big")
                                n_exc += 1
                            else:
                                blob[toff:toff + 2] = (t + delta).to_bytes(
                                    2, "big")
                                n_rw += 1
                        else:
                            nt = blocks.get((t, bx, by, False))
                            if nt is not None:
                                blob[toff:toff + 2] = nt.to_bytes(2, "big")
                                n_eff += 1
                pairs = []
                exc_srcs = set()
                for (t, bx, by, isb), nt in blocks.items():
                    if nt is None:
                        continue
                    src_span = span_of(t, bx, by)
                    dst_span = span_of(nt, bx, by)
                    pairs.extend([s, d] for s, d in zip(src_span, dst_span))
                    if isb:
                        exc_srcs.update(src_span)
                json.dump(pairs, (out / "effect_map.json").open("w"))
                # band srcs relocated by exception AND not otherwise needed
                # at src+delta must be skipped by build_gfx's band loop
                # (their delta target is a protected position!)
                skip = sorted(exc_srcs - nonexc_band_srcs)
                json.dump({"skip_band_src": skip},
                          (out / "tile_exceptions.json").open("w"))
                notes.append(f"# {name}: gfx_remap +{delta:#x} on {n_rw} "
                             f"band tile words, {n_exc} exception words, "
                             f"{n_eff} effect words ({len(blocks)} blocks "
                             f"pooled; {len(skip)} band srcs skipped; "
                             f"{len(protected)} protected) in "
                             f"{len(seen_rec)} records")

            # [effect_tail] (build/manifest/effect_tail.json, session 14j):
            # the x2b7ef4 companion-effect records draw at BANK 1; the
            # engine effect page shifted (+0x47 class relocs) and vs2's
            # elemental-sword band (0x0E17-0x0F02) has no vsav home —
            # placed at the padding run 0x3640+. Per-block code remap.
            if name == "x2b7ef4" and args.stage >= 6:
                et = json.loads((Path(__file__).resolve().parent.parent
                                 / "build/manifest/effect_tail.json"
                                 ).read_text())
                bmap = {}
                for k, d_ in et["reloc"].items():
                    tt, bx, by = k.split(",")
                    bmap[(int(tt, 16), int(bx), int(by))] = int(tt, 16) + d_
                for k, v in et["place"].items():
                    tt, bx, by = k.split(",")
                    bmap[(int(tt, 16), int(bx), int(by))] = int(v, 16)
                base = placed[name]
                # The records' coordinate lists live in vs2's GLOBAL
                # coordinate pool (0x30xxxx) — same-value across the
                # sibling pair, so the diff never relocated them (the
                # classic sibling-coincidence gotcha; latent since M2a:
                # these companion-effect entries have been reading X/Y
                # from unrelated vsavj bytes). Fix: content-match each
                # list into VSAVJ's own pool; Donovan-specific lists are
                # appended to a GEN fragment in hole B.
                POOL_LO, POOL_HI = 0x300000, 0x361000
                # bank-2-attributed records (sword/statue class, session
                # 14k-b): drawn by #\$4000-patched objects — their entries
                # use the BAND-TAIL placements (vs2 bank-3 content), not
                # the bank-1 maps. Keyed by SOURCE record address.
                # 14z-67: band-tail placements exist only for a tenant
                # with a [gfx_remap] band (Donovan). A delta-0 tenant
                # (H/P) has no band tail and never draws these records
                # (they are the DONOVAN companions' art riding in the
                # shared region) — skip the b2 rewrite so no effect_map
                # is fabricated for a build that places no shelf.
                b2_recs = ({int(x, 16) for x in et.get("bank2_recs", [])}
                           if port.get("gfx_remap") else set())
                # 14z-67 (ping #7: the fuchsia-explosion / missing-ray /
                # missing-electricity class): 2,007 of the 5,714 bank-1
                # tiles these records reference are NOT byte-identical in
                # vsav's effect page, and effect_tail's Donovan-era maps
                # cover only 385 of them. On a delta-0 GROUP-C tenant the
                # clean fix is bank 5: keep every tile word NATIVE (skip
                # the bmap rewrite entirely), emit the full referenced
                # bank-1 code list as effect_c5.json (build_gfx places
                # the art at native codes in group C's upper bank), and
                # flip the ported piece-spawner setters #$2000 -> #$3000
                # (manifest port_patch rows — tenant-only by
                # construction: only ported content reaches them).
                c5_mode = (not port.get("gfx_remap")
                           and _int(port["port"].get("gfx_bank", 2)) >= 4)
                c5_tiles = set()
                b2map = {}
                for k, v_ in et.get("bank2_place", {}).items():
                    tt, bx, by = k.split(",")
                    b2map[(int(tt, 16), int(bx), int(by))] = int(v_, 16)
                b2_pairs = []
                extra_lists = bytearray()
                extra_map = {}
                n_et = n_b2 = n_cfix = n_cport = 0
                seen2 = set()
                for i in range(0, r["len"] - 4, 2):
                    v = int.from_bytes(blob[i:i + 4], "big")
                    if not (base <= v < base + r["len"]) or v in seen2:
                        continue
                    o = v - base
                    fmt = int.from_bytes(blob[o:o + 2], "big")
                    cptr = int.from_bytes(blob[o + 6:o + 10], "big")
                    if (fmt > 0x20 or fmt % 2
                            or not (POOL_LO <= cptr < POOL_HI)):
                        continue
                    if fmt == 0:
                        cnt = int.from_bytes(blob[o + 2:o + 4], "big")
                        if not (0 < cnt <= 0x100):
                            continue
                        hdr_at = int.from_bytes(blob[o + 4:o + 6], "big")
                        offs = [(o + 10 + 2 * k, hdr_at) for k in range(cnt)]
                        npairs = cnt
                    elif fmt in (2, 8):
                        budget = int.from_bytes(blob[o + 2:o + 4], "big")
                        cnt = int.from_bytes(blob[o + 4:o + 6], "big")
                        if not (0 < cnt + 1 <= budget <= 0x100):
                            continue
                        offs = [(o + 10 + 4 * k, None) for k in range(cnt + 1)]
                        npairs = cnt + 1
                    else:
                        continue
                    seen2.add(v)
                    src_v = v - base + r["src"]
                    is_b2 = src_v in b2_recs
                    # coordinate-list fixup
                    lst = src_data_img[cptr:cptr + 4 * npairs]
                    hit = vj.find(bytes(lst), 0x300000, 0x361000)
                    if hit != -1:
                        blob[o + 6:o + 10] = hit.to_bytes(4, "big")
                        n_cfix += 1
                    else:
                        key2 = bytes(lst)
                        if key2 not in extra_map:
                            extra_map[key2] = len(extra_lists)
                            extra_lists += lst
                        blob[o + 6:o + 10] = (0xEE000000
                                              + extra_map[key2]).to_bytes(
                                                  4, "big")
                        n_cport += 1
                    for toff, hdr_at in offs:
                        t = int.from_bytes(blob[toff:toff + 2], "big")
                        a_ = (hdr_at if hdr_at is not None else
                              int.from_bytes(blob[toff + 2:toff + 4], "big"))
                        key = (t, ((a_ >> 8) & 15) + 1, ((a_ >> 12) & 15) + 1)
                        if is_b2:
                            nt = b2map.get(key)
                            if nt is not None:
                                blob[toff:toff + 2] = nt.to_bytes(2, "big")
                                n_b2 += 1
                                bx2, by2 = key[1], key[2]
                                for dy in range(by2):
                                    for dx in range(bx2):
                                        b2_pairs.append([
                                            (t & ~0xF) + (dy << 4)
                                            + ((t + dx) & 0xF),
                                            (nt & ~0xF) + (dy << 4)
                                            + ((nt + dx) & 0xF)])
                            continue
                        if c5_mode:
                            # native codes kept; art follows to bank 5
                            if t < 0x10000:
                                bx5, by5 = key[1], key[2]
                                for dy in range(by5):
                                    for dx in range(bx5):
                                        c5_tiles.add(
                                            (t & ~0xF) + (dy << 4)
                                            + ((t + dx) & 0xF))
                            continue
                        nt = bmap.get(key)
                        if nt is not None:
                            blob[toff:toff + 2] = nt.to_bytes(2, "big")
                            n_et += 1
                if extra_lists:
                    la = alloc("b", len(extra_lists),
                               "companion-effect coordinate lists")
                    (out / "effect_lists.bin").write_bytes(bytes(extra_lists))
                    ops.append({"op": "data_file", "addr": f"{la:#x}",
                                "path": "effect_lists.bin"})
                    fragments.append((la, len(extra_lists), "VS2",
                                      "companion-effect coord lists"))
                    # resolve the 0xEE-tagged placeholders
                    for i in range(0, r["len"] - 4, 2):
                        vv = int.from_bytes(blob[i:i + 4], "big")
                        if (vv >> 24) == 0xEE:
                            blob[i:i + 4] = (la + (vv & 0xFFFFFF)).to_bytes(
                                4, "big")
                if b2_pairs:
                    # only reachable with [gfx_remap] present (b2_recs
                    # gating above), whose pass wrote effect_map.json
                    emj = json.loads((out / "effect_map.json").read_text())
                    known = {tuple(p) for p in emj}
                    for p in b2_pairs:
                        if (p[0], p[1]) not in known:
                            emj.append(p)
                            known.add((p[0], p[1]))
                    (out / "effect_map.json").write_text(json.dumps(emj))
                if c5_mode:
                    (out / "effect_c5.json").write_text(
                        json.dumps(sorted(c5_tiles)))
                    notes.append(f"# {name}: effect-c5 — {len(c5_tiles)} "
                                 f"bank-1 codes kept NATIVE (art -> group C "
                                 f"bank 5); {n_cfix} coord lists matched, "
                                 f"{n_cport} ported "
                                 f"({len(extra_lists)}B fragment)")
                    if len(c5_tiles) < 1000 or (n_cfix + n_cport) < 100:
                        fail.append(f"effect-c5: {len(c5_tiles)} codes / "
                                    f"{n_cfix + n_cport} coord lists — "
                                    f"below expectation, walker drifted")
                else:
                    notes.append(f"# {name}: effect_tail — {n_et} bank-1 "
                                 f"words, {n_b2} bank-2 words (tail "
                                 f"placements), {n_cfix} coord lists "
                                 f"matched, {n_cport} ported "
                                 f"({len(extra_lists)}B fragment)")
                    if n_et < 100 or (n_cfix + n_cport) < 100:
                        fail.append(f"effect_tail: {n_et} tile words / "
                                    f"{n_cfix + n_cport} coord lists — "
                                    f"below expectation, walker drifted")
                if port.get("gfx_remap") and n_rw < 10000:
                    fail.append(f"gfx_remap: only {n_rw} tile words rewritten "
                                f"(expected ~14k) — walker or band drifted")
            d = placed[name]
            op = "code_file" if r["kind"] == "code" else "data_file"
            raw_from = r.get("raw_from")
            if raw_from is not None and 0 < raw_from < len(blob):
                # 14z-69i: the region's own pc-relative DATA TABLES live in
                # the forced tail. Emitting them inside the code op stores
                # them ENCRYPTED, and CPS-2 decrypts opcode fetches only —
                # so the machine's runtime data reads saw garbage (measured:
                # 7/7 pointers, x06cac0). Split the emission: code up to the
                # first table, raw data from there. The pointers themselves
                # need no rewriting — inside the region they already resolve
                # to the right address.
                head = out / f"fixed_{name}.bin"
                head.write_bytes(bytes(blob[:raw_from]))
                ops.append({"op": op, "addr": f"{d:#x}", "path": head.name})
                notes.append(f"{op:9s} {d:#08x} +{raw_from:#x}  donovan "
                             f"{name} code (from vsav2 0x{r['src']:06X})")
                tail = out / f"fixed_{name}_tables.bin"
                # from the SOURCE DATA IMAGE, not from `blob`: blob holds the
                # region's OPCODE-view (plaintext) content, but an (An)-based
                # read is a DATA-space read and returns the raw stored bytes
                # (docs/platform/gotchas.md "PC-relative reads are
                # PROGRAM-space; (An)-based reads are DATA-space"). To make
                # the copy read like vs2's original, store vs2's raw bytes.
                # Safe for this span by construction: it is the forced tail,
                # a dead zone, so no pointer fixups were applied to it.
                tail.write_bytes(bytes(src_data_img[r["src"] + raw_from:
                                                    r["src"] + r["len"]]))
                ops.append({"op": "data_file", "addr": f"{d + raw_from:#x}",
                            "path": tail.name})
                notes.append(f"data_file {d + raw_from:#08x} "
                             f"+{len(blob) - raw_from:#x}  donovan {name} "
                             f"RAW TABLES (unencrypted; vs2 "
                             f"0x{r['src'] + raw_from:06X})")
                fragments.append((d + raw_from, len(blob) - raw_from, "VS2",
                                  f"{name} raw pc-rel data tables"))
            else:
                fixed = out / f"fixed_{name}.bin"
                fixed.write_bytes(bytes(blob))
                ops.append({"op": op, "addr": f"{d:#x}", "path": fixed.name})
                notes.append(f"{op:9s} {d:#08x} +{r['len']:#x}  donovan {name} "
                             f"(from vsav2 0x{r['src']:06X})")

        # [palette] (stage-gated): place the character's sprite-palette
        # block (all confirm-button variants) raw in hole B and repoint
        # the engine's per-char palette pointer table row (slot 0x0F —
        # replaced-slot content, superset-clean). Decoded session 14:
        # uploader vsavj 0x1C3FE (vs2 twin 0x1AE6E), table indexed by
        # the pre-scaled char id, 12 rows to palette RAM 0x90C140.
        pals = port.get("palette")
        if isinstance(pals, dict):
            pals = [pals]
        for pal in (pals or []):
            if args.stage < _int(pal.get("stage", 0)):
                continue
            psrc, plen = _int(pal["src"]), _int(pal["len"])
            pname = pal.get("name", "sprite")
            pblock = bytes(src_data_img[psrc:psrc + plen])
            expect = bytes.fromhex(pal["src_head_hex"])
            if pblock[:len(expect)] != expect:
                fail.append(f"palette {pname}: src block head at {psrc:#x} "
                            f"!= {pal['src_head_hex']} (image drift?)")
                continue
            pa = alloc(pal.get("hole", "b"), plen, f"{pname} palette block")
            if pa is None:
                fail.append(f"palette {pname}: no room")
                continue
            fn = f"palette_block_{pname}.bin"
            (out / fn).write_bytes(pblock)
            ops.append({"op": "data_file", "addr": f"{pa:#x}", "path": fn})
            fragments.append((pa, plen, "VS2", f"{pname} palette block"))
            # The row FOLLOWS THE TENANT (14z-62c — the manifest used to
            # hardcode row 0x0F, so a variant-id build silently repointed
            # JEDAH's palette row: replay-11 RAM diff caught his cached
            # block pointer at $FFB8C1 holding the ported address, and his
            # match palettes/fades diverging from vanilla). extra_tables is
            # the hand-rolled 0x1F MIRROR (0x38C258 == 0x38C218 + 0x40 —
            # measured, NOT a separate table); a variant-id tenant has no
            # mirror, so extras are emitted only on the base half.
            if "row" in pal:
                fail.append(f"palette {pname}: the manifest declares a fixed "
                            f"'row' — the row follows the tenant now "
                            f"(14z-62c); delete the key")
                continue
            prow = dst_slot
            if prow >= 0x10:
                ta = _int(pal["table"]) + 4 * prow
                aa = _int(pal["table"]) + 4 * (prow & 0x0F)
                if vj_u32(ta) != vj_u32(aa):
                    fail.append(f"palette {pname}: variant row {ta:#x} does "
                                f"not alias its base-half counterpart — "
                                f"table shape moved")
                    continue
            tables = [_int(pal["table"])]
            if prow < 0x10:
                tables += [_int(x) for x in
                           str(pal.get("extra_tables", "")).split(",") if x]
            for tb in tables:
                ta = tb + 4 * prow
                ops.append({"op": "poke32", "addr": f"{ta:#x}",
                            "val": f"{pa:#010x}"})
                notes.append(f"data     {pa:#08x} +{plen:#x}  {pname} "
                             f"palette block (vsav2 0x{psrc:06X}); poke32 "
                             f"{ta:#08x} (table {tb:#x} row {prow:#x})")

        # per-char value rows -> vsavj slot 0x0F rows
        # param32_a/b (movement velocity pairs) are NOT ported BY DEFAULT
        # (session 14w-b): with Donovan's true vs2 velocities his
        # 21_don_mash soak crashes at ~10050 (correct movement reaches a
        # state with a broken pointer — return address into anim data;
        # separate landmine, queued). He has played every clean round at
        # Jedah's speeds; keep that until the crash path is decoded. The
        # addressing fix (rec8 pairs) stays — it is what protects
        # FELICIA's walk-back from the old mis-stride write.
        # 14z-66: the skip became a PER-TENANT default (port_param32 in
        # [[tenant]]): the 14w-b crash is a Donovan-port landmine, not a
        # property of velocity porting — Huitzil opts in after his own
        # soak battery re-examined the hazard (playtest round-1 item 2:
        # he moved at the row-0x10 ALIAS content = Bulleta's speeds).
        # Donovan's manifest carries no flag -> his bytes are unchanged.
        VALUE_SKIP = set() if port["port"].get("port_param32", False) \
            else {"param32_a", "param32_b", "jump_params"}
        # Explicit-ownership claims (14z-65): a [[sound_table]] row that WILL
        # emit repoints its ptr_table row ITSELF (the measured, id-allowlisted
        # port). The generic value-row repoint below must not also write that
        # row: on WIDE builds both wrote tail_data_ptr[tenant] (0x0BF466) and
        # the shipped bytes were correct only because the sound op was emitted
        # later — silent last-write-wins, found by the 14z-65 overlap audit.
        # Claims use the sound_table section's EXACT gating, so a stock build
        # (sound_table skipped there) keeps the generic repoint unchanged.
        claimed_ptr_tables = {
            _int(st["ptr_table"]): f"sound_table {st['name']}"
            for st in (port.get("sound_table", []) if args.stage >= 6 else [])
            if args.stage >= _int(st.get("stage", 0))
            and not (st.get("profile") and st["profile"] != args.profile)
        }
        for v in man["values"]:
            if v["table"] in VALUE_SKIP:
                notes.append(f"# {v['table']}: velocity pair NOT ported "
                             f"(14w-b crash guard; Jedah speeds retained)")
                continue
            t = bank[v["table"]]
            a, es = table_entry_addr(v["table"], dst_slot)
            if v["kind"] in ("data_ptr", "code_ptr"):
                owner = claimed_ptr_tables.get(_int(t["vsavj"]))
                if owner:
                    notes.append(f"# {v['table']}: ptr row owned by {owner} "
                                 f"— generic repoint suppressed (14z-65)")
                    continue
                ptr = _int(v["ptr"])
                host = region_of(ptr)
                if host is None:
                    fail.append(f"{v['table']}: ptr {ptr:#x} outside all regions")
                elif host in placed:
                    repoint(v["table"], ptr + (placed[host] - regions[host]["src"]),
                            f"donovan {host}")
                else:
                    notes.append(f"# {v['table']}: region {host} not placed at "
                                 f"stage {args.stage} — repoint deferred")
                continue
            data = bytes.fromhex(v["value"])
            poke_bytes(a, data, f"{v['table']}[{dst_slot:#x}] value")
            # value-table variant rows are dead data in vanilla (variant ids
            # resolve to base slots except 0x18), not aliases — poke
            # unconditionally so any 5-bit-indexed path sees Donovan's value
            if mirror:
                av, _ = table_entry_addr(v["table"], var_slot)
                poke_bytes(av, data, f"{v['table']}[{var_slot:#x}] mirror")
        # oracle-classified gap value tables
        # GAP TABLES DISABLED (session 14w): the auto_tables "gap"
        # heuristic assumed untyped gaps between per-char tables were
        # more per-char rows and wrote slot-0x0F "values" + 0x1F "dark
        # mirrors" into them. They are JUMP-PHYSICS PARAMETER tables
        # (index 0x1F = the wall-jump-back velocity — vanilla
        # 0xFFFF4800 became 0xFFFFEC00 and broke Felicia's triangle
        # jump in pure legacy matches, playtest rounds 18/19; found by
        # per-op restore bisection). 31 of the 42 gap writes changed
        # vanilla engine bytes with unverified semantics. NOTHING may
        # be written to a gap without a decoded consumer. Donovan's
        # own physics come from his ported regions, not these rows.
        for a_t in (man["auto_tables"] if False else []):
            if a_t["verdict"] == "pointers":
                # per-entry union semantics: a ROM-plausible entry hosted by
                # an extracted region repoints; anything else copies verbatim
                t = bank[a_t["table"]]
                a, es = table_entry_addr(a_t["table"], dst_slot)
                raw = bytes.fromhex(a_t["entry_guess"]) if "entry_guess" in a_t \
                    else None
                if raw is None:
                    sa = table_addr_src(a_t["table"])
                    raw = src_data_img[sa:sa + es]
                v = int.from_bytes(raw, "big")
                host = region_of(v) if v < 0x400000 else None
                if host and host in placed:
                    repoint(a_t["table"], v + (placed[host] - regions[host]["src"]),
                            f"gap ptr -> donovan {host}")
                else:
                    poke_bytes(a, raw, f"{a_t['table']}[{dst_slot:#x}] gap "
                               f"entry (verbatim)")
                    if mirror:
                        av, _ = table_entry_addr(a_t["table"], var_slot)
                        poke_bytes(av, raw, f"{a_t['table']}[{var_slot:#x}] mirror")
                continue
            if a_t["verdict"] != "values":
                notes.append(f"# gap table {a_t['table']}: {a_t['verdict']} — "
                             f"NOT ported (needs consumer disasm)")
                continue
            t = bank[a_t["table"]]
            a, es = table_entry_addr(a_t["table"], dst_slot)
            data = bytes.fromhex(a_t["entry_guess"])
            poke_bytes(a, data, f"{a_t['table']}[{dst_slot:#x}] gap value")
            if mirror:
                av, _ = table_entry_addr(a_t["table"], var_slot)
                poke_bytes(av, data, f"{a_t['table']}[{var_slot:#x}] mirror")

    # ── engine_dispatch rows (14z-65): out-of-window dispatch rows were
    # assumed vanilla-alias-correct — measured WRONG for Huitzil:
    # dispatch_07 is per-char even in engine space (his 0x23AFE vs
    # Bulleta's 0x2D68E), so the vanilla row-0x10 alias served BULLETA's
    # substate dispatcher — one link of the specials-never-trigger chain.
    # Rule: when the SOURCE game's row for src_char differs from its row
    # for the alias char (dst_slot & 0x0F), the alias is wrong — repoint
    # the tenant's row at the recon-verified vsavj twin. Donovan-inert
    # (measured: all his engine_dispatch rows equal their alias rows).
    if args.stage >= 4:
        def _src_u32(a):
            return int.from_bytes(src_data_img[a:a + 4], "big")
        for e in man.get("engine_dispatch", []):
            tn = e["table"]
            t = bank[tn]
            es = (t["span"] // 32) if t["kind"] == "byte2d" else (t["stride"] // 32)
            base_src = src_bank_origin + (_int(t["vsavj"]) - VSAVJ_ORIGIN)
            own = _src_u32(base_src + _int(port["port"]["src_char"]) * es)
            alias = _src_u32(base_src + (dst_slot & 0x0F) * es)
            if own == alias:
                continue
            m_ = recon.get(own)
            ok = m_ and (m_.get("status") == "verified"
                         or (args.allow_plausible
                             and m_.get("status") == "plausible"))
            if not ok:
                fail.append(f"engine_dispatch {tn}: the tenant's row "
                            f"{own:#x} differs from the alias char's "
                            f"{alias:#x} — needs a verified reconciliation "
                            f"row (the vanilla alias serves the WRONG "
                            f"handler)")
                continue
            repoint(tn, _int(m_["vsavj"]),
                    f"engine twin of {own:#x} (alias char row {alias:#x} "
                    f"differs)")

    for ph in (port.get("obj_hook", []) if args.stage >= 4 else []):
        site = _int(ph["site"])
        vtab = _int(ph["vanilla_table"])
        n_van = _int(ph["vanilla_entries"])
        stab = _int(ph["src_table"])
        n_src = _int(ph["src_entries"])
        # engine-site safety: the bytes we replace must be exactly the
        # expected dispatch sequence (movea.l (d8,PC,D0.w),A0; moveq; jsr)
        vj_pt_site = None  # site is in plaintext space; compare via opcodes view
        expect = bytes.fromhex("207b001270004e90")
        # patch_prg works on stored words; for the check we use the decrypted
        # analysis image if available, else trust the config (test gate covers)
        opc = root / "build/out/vsavj_opcodes.bin"
        if opc.is_file():
            got = open(opc, "rb").read()[site:site + 8]
            if got != expect:
                fail.append(f"obj_hook: engine bytes at {site:#x} != expected "
                            f"dispatch sequence ({got.hex()})")
        # BOTH source tables are read PC-relatively by the engine, i.e.
        # through 68k PROGRAM space -> CPS2-decrypted; copy entries from the
        # decrypted views. The extended table is accessed An-relative by the
        # thunk (a DATA read) and is therefore emitted raw. (docs/GOTCHAS.md)
        vj_pt = (root / "build/out/vsavj_opcodes.bin").read_bytes()
        src_pt = (root / f"build/out/{man['src_set']}_opcodes.bin").read_bytes()
        table = bytearray()
        for k in range(n_van):
            table += vj_pt[vtab + k * 4:vtab + k * 4 + 4]
        ported = 0
        for k in range(n_van, n_src):
            tgt = int.from_bytes(src_pt[stab + k * 4:stab + k * 4 + 4], "big")
            host = region_of(tgt)
            m = recon.get(tgt)
            if host and host in placed:
                newt = tgt + (placed[host] - regions[host]["src"])
                ported += 1
            elif m and (m.get("status") == "verified"
                        or (args.allow_plausible
                            and m.get("status") == "plausible")):
                newt = _int(m["vsavj"])
                ported += 1
            else:
                newt = None
            if newt is None:
                # unported extra type: point at a tripwire so a use is LOUD
                newt = tripwire_for(tgt, f"obj_hook@{site:#x} type {k}") \
                    if args.tripwire_open else None
                if newt is None:
                    fail.append(f"obj_hook@{site:#x}: extra type {k} handler "
                                f"{tgt:#x} not ported/placed")
                    newt = 0
            table += newt.to_bytes(4, "big")
        # AUTHORED union rows (14z-68): types that exist in NEITHER table.
        # The src table only carries the ids the source game itself used;
        # a tenant that needs its own type — so a SHARED type's rewritten
        # machine can be reached without touching the shared row — declares
        # it here as {index, src}. `src` is a SOURCE-game address resolved
        # exactly like a ported extra (placed region first, then recon), so
        # an unported target tripwires instead of silently dispatching into
        # the host. Indexes must continue the table with no gap: a row that
        # is not the next index is a build error, because the engine indexes
        # this table by type*4 and a hole would dispatch to whatever the
        # allocator left there.
        for ex in [e for e in port.get("obj_hook_extra", [])
                   if _int(e["site"]) == site]:
            idx = _int(ex["index"])
            cur = len(table) // 4
            if idx != cur:
                fail.append(f"obj_hook@{site:#x}: extra row index {idx} is not "
                            f"the next table index ({cur}) — no gaps allowed")
                continue
            tgt = _int(ex["src"])
            host = region_of(tgt)
            m = recon.get(tgt)
            if host and host in placed:
                newt = tgt + (placed[host] - regions[host]["src"])
            elif m and (m.get("status") == "verified"
                        or (args.allow_plausible
                            and m.get("status") == "plausible")):
                newt = _int(m["vsavj"])
            else:
                newt = tripwire_for(tgt, f"obj_hook@{site:#x} authored type {idx}") \
                    if args.tripwire_open else None
                if newt is None:
                    fail.append(f"obj_hook@{site:#x}: authored type {idx} handler "
                                f"{tgt:#x} not ported/placed")
                    newt = 0
            table += newt.to_bytes(4, "big")
            notes.append(f"#   obj_hook authored type {idx} -> {newt:#08x} "
                         f"(from {args.src_set if hasattr(args, 'src_set') else 'src'} "
                         f"{tgt:#x}; {ex.get('note', '')})")
        tdst = alloc("a", len(table), "obj_hook ext table")
        thunk = None
        if tdst is not None:
            ops.append({"op": "data", "addr": f"{tdst:#x}", "hex": table.hex()})
            notes.append(f"data   {tdst:#08x} +{len(table):#x}  proj_hook "
                         f"extended type table ({n_van} vanilla + "
                         f"{n_src - n_van} ported, {ported} placed)")
            fragments.append((tdst, len(table), "GEN", "proj_hook ext table"))
            thunk = alloc("a", 18, "obj_hook thunk")
        if thunk is not None:
            # GHOST-CLEAN topology (superset invariant, measured 2026-07-25):
            # replace ONLY the movea+moveq (6 bytes) with `jmp thunk` and
            # leave the vanilla `jsr (A0)` at its original address; the
            # thunk indexes the extended table then jumps BACK to that jsr.
            # The push therefore happens at the vanilla address with the
            # vanilla return value — a jsr-into-thunk design pushes a
            # different return address and leaves divergent ghost bytes
            # below SP in work RAM, failing the bit-exact legacy gate.
            tk = (bytes([0x41, 0xF9]) + tdst.to_bytes(4, "big")   # lea tbl,A0
                  + bytes([0x20, 0x70, 0x00, 0x00])               # movea.l (A0,D0.w),A0
                  + bytes([0x70, 0x00])                           # moveq #0,D0
                  + bytes([0x4E, 0xF9]) + (site + 6).to_bytes(4, "big"))  # jmp site+6 (the vanilla jsr (A0))
            ops.append({"op": "code", "addr": f"{thunk:#x}", "hex": tk.hex()})
            notes.append(f"code   {thunk:#08x} obj_hook thunk (ghost-clean: "
                         f"returns to vanilla jsr)")
            fragments.append((thunk, len(tk), "GEN", "obj_hook thunk"))
            site_patch = bytes([0x4E, 0xF9]) + thunk.to_bytes(4, "big")
            ops.append({"op": "code", "addr": f"{site:#x}",
                        "hex": site_patch.hex()})
            notes.append(f"code   {site:#08x} ENGINE HOOK: dispatch -> jmp "
                         f"thunk; vanilla jsr (A0) at {site + 6:#x} untouched "
                         f"(vanilla types identical via table copy)")
            fragments.append((site, 6, "GEN", "obj_hook engine site"))

    sh = port.get("state_hook") if args.stage >= 4 else None
    if sh:
        # +0x14E engine state-dispatch extension (donovan.toml [state_hook];
        # design + measured constants: docs/project/tables/reconciliation.md
        # "Session 8"). Four parts, all GEN except the records (VS2):
        #   1. 12 palette-seq records -> hole B (raw; byte-identical in
        #      vhunt2 — verified at config time, asserted here)
        #   2. ghost-clean base-swap thunks on the 4 seq-table consumers
        #      (movea.l #base is exactly 6 bytes = jmp thunk; no pushes;
        #      CCR-safe: andi.w follows at every site)
        #   3. 12 synthesized case stubs (vs2's are uniform; targets are
        #      the structurally-verified vsavj twins ret_equiv/seq_set)
        #   4. the state thunk: vanilla states jmp back to the untouched
        #      move.w+jsr (ghost-clean); extended states dispatch via a
        #      long table, preserving D0 (the stubs compare it to +0x14F)
        site = _int(sh["site"])
        first_ext = _int(sh["first_ext"])
        n_ext = _int(sh["n_ext"])
        seq_id0 = _int(sh["seq_first_id"])
        opc_img = (root / "build/out/vsavj_opcodes.bin").read_bytes()
        expect_site = (bytes([0x70, 0x00, 0x10, 0x2E])
                       + _int(sh["state_off"]).to_bytes(2, "big"))
        if opc_img[site:site + 6] != expect_site:
            fail.append(f"state_hook: engine bytes at {site:#x} != "
                        f"moveq/move.b prefix ({opc_img[site:site+6].hex()})")
        src_data = (root / f"build/out/{man['src_set']}_data.bin").read_bytes()
        rlen = _int(sh["records_len"])
        recs = src_data[_int(sh["records_src"]):_int(sh["records_src"]) + rlen]
        # sibling-oracle identity check on the records (config-time finding,
        # re-asserted every build)
        orc_p = root / f"build/out/{man['oracle_set']}_data.bin"
        if "records_orc" in sh and orc_p.is_file():
            orc_data = orc_p.read_bytes()
            tw = _int(sh["records_orc"])
            if orc_data[tw:tw + rlen] != recs:
                fail.append("state_hook: seq records differ from the "
                            "sibling twin — misbounded or wrong address")
        rdst = alloc("b", rlen, "state_hook seq records")
        if rdst is not None:
            ops.append({"op": "data", "addr": f"{rdst:#x}", "hex": recs.hex()})
            notes.append(f"data   {rdst:#08x} +{rlen:#x}  state_hook palette-"
                         f"seq records (ids {seq_id0:#x}-{seq_id0+n_ext-1:#x})")
            fragments.append((rdst, rlen, "VS2", "state_hook seq records"))
            # PRIVATE seq-set entry (session 12: the session-9 base-swap
            # consumer thunks hijacked vanilla ids 0x2CD+ — vsavj's table
            # has its own live records there; the attract intro's fades
            # use them and WEDGED. Only Donovan's stubs may see the VS2
            # records: wrapper loads the swapped base and enters the
            # engine seq-set AFTER its movea — vanilla flows untouched.)
            alt_base = rdst - seq_id0 * 32
            sw = alloc("a", 12, "state_hook private seq entry")
            if sw is not None:
                wk = (b"\x20\x7c" + alt_base.to_bytes(4, "big")
                      + b"\x4e\xf9"
                      + (_int(sh["seq_set"]) + 6).to_bytes(4, "big"))
                ops.append({"op": "code", "addr": f"{sw:#x}", "hex": wk.hex()})
                notes.append(f"code   {sw:#08x} state_hook private seq entry "
                             f"(records base {rdst:#08x} - {seq_id0:#x}*32 -> "
                             f"engine {_int(sh['seq_set']) + 6:#x})")
                fragments.append((sw, 12, "GEN", "state_hook private seq entry"))
                sh["_seq_entry"] = sw
        # 14z-46: per-stub seq ids (vs2's cases are NOT consecutive — the
        # original synthesis held only for the first three). Config
        # seq_ids: one entry per ext state; -1 = dead state (never
        # written by the ported code, vs2 case non-uniform) -> safe
        # no-op stub (jmp ret_equiv). Live ids are re-verified against
        # vs2's OWN dispatch table at build time.
        seq_ids = ([-1 if x.strip() == "-" else int(x.strip(), 0)
                    for x in sh["seq_ids"].split(",")]
                   if "seq_ids" in sh else
                   [seq_id0 + k for k in range(n_ext)])
        if len(seq_ids) != n_ext:
            fail.append(f"state_hook: seq_ids has {len(seq_ids)} entries, "
                        f"n_ext = {n_ext}")
        if "src_dispatch_table" in sh:
            src_opc = (root / f"build/out/{man['src_set']}_opcodes.bin").read_bytes()
            stab = _int(sh["src_dispatch_table"])
            sidx0 = _int(sh["src_first_idx"])
            for k, sid in enumerate(seq_ids):
                if sid < 0:
                    continue
                w = int.from_bytes(src_opc[stab + 2*(sidx0+k):stab + 2*(sidx0+k) + 2], "big")
                case = src_opc[stab + w:stab + w + 0x20]
                m = case.find(b"\x30\x3c")
                real = int.from_bytes(case[m+2:m+4], "big") if m >= 0 else None
                if real != sid:
                    fail.append(f"state_hook: seq_ids[{k}] = {sid:#x} but the "
                                f"src case (idx {sidx0+k}) carries "
                                f"{real if real is None else hex(real)}")
                lo = seq_id0
                if not (lo <= sid < lo + rlen // 32):
                    fail.append(f"state_hook: seq_ids[{k}] = {sid:#x} outside "
                                f"the ported record block "
                                f"[{lo:#x},{lo + rlen//32:#x})")
        stubs = alloc("a", 32 * n_ext, "state_hook case stubs")
        et = alloc("a", 4 * n_ext, "state_hook ext table")
        mt = alloc("a", 50, "state_hook thunk")
        if None not in (stubs, et, mt):
            blob = b""
            for k in range(n_ext):
                if seq_ids[k] < 0:
                    piece = b"\x4e\xf9" + _int(sh["ret_equiv"]).to_bytes(4, "big")
                    piece += b"\x4e\x71" * ((32 - len(piece)) // 2)
                else:
                    piece = (b"\xb0\x2e" + _int(sh["prev_state_off"]).to_bytes(2, "big")
                             + b"\x66\x06"
                             + b"\x4e\xf9" + _int(sh["ret_equiv"]).to_bytes(4, "big")
                             + b"\x42\x2e" + _int(sh["clr_b_off"]).to_bytes(2, "big")
                             + b"\x42\x6e" + _int(sh["clr_w_off"]).to_bytes(2, "big")
                             + b"\x30\x3c" + seq_ids[k].to_bytes(2, "big")
                             + b"\x72\x01"
                             + b"\x4e\xf9" + sh["_seq_entry"].to_bytes(4, "big"))
                blob += piece
            assert len(blob) == 32 * n_ext
            ops.append({"op": "code", "addr": f"{stubs:#x}", "hex": blob.hex()})
            ext = b"".join((stubs + 32 * k).to_bytes(4, "big")
                           for k in range(n_ext))
            ops.append({"op": "data", "addr": f"{et:#x}", "hex": ext.hex()})
            tk = (b"\x70\x00"
                  + b"\x10\x2e" + _int(sh["state_off"]).to_bytes(2, "big")
                  + b"\x0c\x40" + first_ext.to_bytes(2, "big")
                  + b"\x65\x20"
                  + b"\x0c\x40" + (first_ext + 2 * n_ext).to_bytes(2, "big")
                  + b"\x64\x1a"
                  + b"\x32\x00"
                  + b"\x04\x41" + first_ext.to_bytes(2, "big")
                  + b"\xd2\x41"
                  + b"\x20\x7c" + et.to_bytes(4, "big")
                  + b"\x20\x70\x10\x00"
                  + b"\x4e\x90"
                  + b"\x4e\xf9" + _int(sh["site_after"]).to_bytes(4, "big")
                  + b"\x4e\xf9" + _int(sh["site_resume"]).to_bytes(4, "big"))
            assert len(tk) == 50
            ops.append({"op": "code", "addr": f"{mt:#x}", "hex": tk.hex()})
            ops.append({"op": "code", "addr": f"{site:#x}",
                        "hex": (b"\x4e\xf9" + mt.to_bytes(4, "big")).hex()})
            notes.append(f"code   {site:#08x} ENGINE HOOK: +{_int(sh['state_off']):#x} "
                         f"state dispatch -> thunk {mt:#08x} (vanilla ids "
                         f"ghost-clean via jmp-back; ids {first_ext:#x}-"
                         f"{first_ext + 2*n_ext - 2:#x} -> {n_ext} synthesized "
                         f"stubs at {stubs:#08x}, ext table {et:#08x})")
            fragments.append((stubs, 32 * n_ext, "GEN", "state_hook case stubs"))
            fragments.append((et, 4 * n_ext, "GEN", "state_hook ext table"))
            fragments.append((mt, 50, "GEN", "state_hook thunk"))
            fragments.append((site, 6, "GEN", "state_hook engine site"))

    rh = port.get("reaction_hook") if args.stage >= 4 else None
    if rh:
        # Hit-reaction dispatch extension (donovan.toml [reaction_hook];
        # measured constants + design in the toml comment / reconciliation
        # Session 11). Cases are verbatim position-independent vs2 bytes
        # from the config (reviewable hex). Ghost-clean: the preceding
        # tst/bne pair becomes `jmp thunk`; vanilla ids jmp back to the
        # UNTOUCHED original dispatch.
        sp = _int(rh["site_prefix"])
        opc_img = (root / "build/out/vsavj_opcodes.bin").read_bytes()
        expect = bytes.fromhex(rh["site_prefix_expect"])
        if opc_img[sp:sp + len(expect)] != expect:
            fail.append(f"reaction_hook: bytes at {sp:#x} != expected "
                        f"tst/bne pair ({opc_img[sp:sp+8].hex()})")
        first_ext = _int(rh["first_ext"])
        n_ext = _int(rh["n_ext"])
        cases = [bytes.fromhex(rh[f"case_{first_ext + 2*k:x}"])
                 for k in range(n_ext)]
        blob = b"".join(cases)
        cb = alloc("a", len(blob), "reaction_hook cases")
        et = alloc("a", 4 * n_ext, "reaction_hook ext table")
        th = alloc("a", 50, "reaction_hook thunk")
        if None not in (cb, et, th):
            ops.append({"op": "code", "addr": f"{cb:#x}", "hex": blob.hex()})
            offs = []
            o = 0
            for c in cases:
                offs.append(cb + o)
                o += len(c)
            ext = b"".join(a.to_bytes(4, "big") for a in offs)
            ops.append({"op": "data", "addr": f"{et:#x}", "hex": ext.hex()})
            tk = (bytes([0x4A, 0x29]) + _int(rh["tst_disp"]).to_bytes(2, "big")
                  + bytes([0x67, 0x06])
                  + bytes([0x4E, 0xF9]) + _int(rh["bne_target"]).to_bytes(4, "big")
                  + bytes([0x0C, 0x40]) + first_ext.to_bytes(2, "big")
                  + bytes([0x65, 0x1A])
                  + bytes([0x0C, 0x40]) + (first_ext + 2 * n_ext).to_bytes(2, "big")
                  + bytes([0x64, 0x14])
                  + bytes([0x32, 0x00])
                  + bytes([0x04, 0x41]) + first_ext.to_bytes(2, "big")
                  + bytes([0xD2, 0x41])
                  + bytes([0x20, 0x7C]) + et.to_bytes(4, "big")
                  + bytes([0x20, 0x70, 0x10, 0x00])
                  + bytes([0x4E, 0xD0])
                  + bytes([0x4E, 0xF9]) + _int(rh["dispatch"]).to_bytes(4, "big"))
            assert len(tk) == 50, len(tk)
            ops.append({"op": "code", "addr": f"{th:#x}", "hex": tk.hex()})
            ops.append({"op": "code", "addr": f"{sp:#x}",
                        "hex": (b"\x4e\xf9" + th.to_bytes(4, "big")).hex()})
            notes.append(f"code   {sp:#08x} ENGINE HOOK: hit-reaction "
                         f"dispatch -> thunk {th:#08x} (vanilla ids jmp back "
                         f"to untouched {_int(rh['dispatch']):#x}; ids "
                         f"{first_ext:#x}-{first_ext + 2*n_ext - 2:#x} -> "
                         f"{n_ext} verbatim vs2 cases at {cb:#08x})")
            fragments.append((cb, len(blob), "VS2", "reaction_hook cases"))
            fragments.append((et, 4 * n_ext, "GEN", "reaction_hook ext table"))
            fragments.append((th, 50, "GEN", "reaction_hook thunk"))
            fragments.append((sp, 6, "GEN", "reaction_hook engine site"))

    if args.stage >= 4:
        shim_cfg = port.get("init_shim")
        keeper_cfgs = {k["table"]: k for k in port.get("dispatch_keeper", [])}
        for d in man["dispatch"]:
            newt = None
            tgt = d["src_target"]
            host = region_of(tgt)
            if host in placed:
                newt = tgt + (placed[host] - man["regions"][host]["src"])
            if newt is None:
                fail.append(f"{d['table']}: dispatch target {tgt:#x} unplaced")
                continue
            kc = keeper_cfgs.get(d["table"])
            if kc:
                # SATELLITE RESPAWN KEEPER (14z-65, the Anita pattern made
                # a mechanism): vs2 re-runs char-init EVERY ROUND (measured:
                # native f2886+f8812) — that is how Huitzil's pods respawn.
                # vsavj has no per-round char-init, so the boundary pool
                # scrub leaves the tenant satellite-less (and a surviving
                # reference dispatches the freed slot: the f4983 crash).
                # Donovan's own ported code carries a per-frame companion
                # keeper; this thunk gives a tenant the same behavior by
                # reusing HIS OWN ported spawn code: on the per-frame row,
                # if the intro is done (idle byte == 0) and the satellite
                # ptr word is zero, jsr the ported spawn entry, then fall
                # into the normal handler.
                se = _int(kc["spawn_entry"])
                sh = region_of(se)
                if sh not in placed:
                    fail.append(f"dispatch_keeper: spawn_entry {se:#x} "
                                f"unplaced")
                    continue
                sp = se + (placed[sh] - man["regions"][sh]["src"])
                kd = alloc("a", 24, "satellite respawn keeper")
                if kd is None:
                    continue
                idle = _int(kc.get("idle_check", 0x0A))
                ptrw = _int(kc.get("ptr_check", 0x2A))
                thunk = (bytes([0x4A, 0x2E]) + idle.to_bytes(2, "big")  # tst.b (idle,A6)
                         + bytes([0x66, 0x0C])                          # bne.s skip
                         + bytes([0x4A, 0x6E]) + ptrw.to_bytes(2, "big")  # tst.w (ptr,A6)
                         + bytes([0x66, 0x06])                          # bne.s skip
                         + bytes([0x4E, 0xB9]) + sp.to_bytes(4, "big")  # jsr spawn
                         + bytes([0x4E, 0xF9]) + newt.to_bytes(4, "big"))  # skip: jmp handler
                assert len(thunk) == 24
                ops.append({"op": "code", "addr": f"{kd:#x}",
                            "hex": thunk.hex()})
                notes.append(f"code   {kd:#08x} satellite respawn keeper "
                             f"(idle A6+{idle:#x}==0 & ptr A6+{ptrw:#x}==0 "
                             f"-> jsr {sp:#x}) -> handler {newt:#08x}")
                fragments.append((kd, 24, "GEN", "satellite respawn keeper"))
                repoint(d["table"], kd, "handler via respawn keeper")
                continue
            if shim_cfg and d["table"] == shim_cfg["dispatch"]:
                # synthesized pool-seeding + flavor-default init shim (see
                # donovan.toml). A5 is NOT guaranteed to hold the $FF8000
                # base at dispatch time, and the seeder itself is
                # A5-relative — save A5, load the base, seed if the pool
                # latch is clear, restore; then seed the VS2/VH2 flavor
                # latch in THIS player's struct (A6) — vsavj never writes
                # it, and Donovan's QCB+K handler + projectile read it
                # (maintainer decision 2026-07-27: default = VS2):
                #   move.l A5,-(SP); lea $FF8000.l,A5; tst.l (latch,A5)
                #   bne.s +6; jsr seed_entry; movea.l (SP)+,A5
                #   move.b #flavor_default,(flavor_disp,A6); jmp handler
                _shimlen = 76 if shim_cfg.get("objram_clear") else 68
                if shim_cfg.get("latch_mode") == "phase":
                    _shimlen += 12
                sd = alloc("a", _shimlen, "init seed shim")
                if sd is None:
                    continue
                latch = _int(shim_cfg["latch_disp"])
                flav_d = _int(shim_cfg["flavor_disp"])
                flav_v = _int(shim_cfg["flavor_default"])
                # Start-hold flavor selector (stage 5; community-confirmed
                # protocol, docs/game/atlas/character_tables.md): the byte at
                # flavor_hold_flag is a per-player Start bitmask (bit 0 =
                # P1, bit 1 = P2; live through match load — measured).
                # Holding YOUR Start through match load selects the other
                # game's flavor (latch <- flavor_held). All ops CCR-only —
                # no register clobbers before the handler.
                hold_flag = _int(shim_cfg["flavor_hold_flag"])
                flav_h = _int(shim_cfg["flavor_held"])
                # OBJ-RAM stale-tail clear (session 14z-7, manifest flag
                # objram_clear): zero the full 8KB sprite list once per
                # Donovan char-init. The VS-screen/fade leftovers in the
                # tail priority buckets are re-DISPLAYED by effects that
                # extend the list (Victor 236HP curtain) — vanilla chars
                # leave benign dark tiles there, Donovan leaves his VS
                # portrait pieces (the round-27 shock garble). Clearing at
                # init (screen blanked) makes the exposed tail transparent.
                # Register-safe: d0/a0 saved; CCR irrelevant (next op sets).
                # 14z-7 v2: char-init runs DURING the VS screen (measured:
                # clear at f2362, VS draws past f2364 and re-pollutes) — so
                # the shim only ARMS a marker in the dead-stack scratch
                # ($FF7F00, legacy-masked; worst-case clobber = one missed
                # or one spurious clear, both benign). Donovan's per-frame
                # sword routine consumes it at round start (first frame
                # after the VS screen) and clears the OBJ list there — see
                # the objram_clear blob below.
                objclr = b""
                if shim_cfg.get("objram_clear"):
                    objclr = bytes.fromhex("13fc005000ff7f00")  # move.b #$50,$ff7f00.l (countdown)
                # PHASE-GATED LATCH (14z-65, manifest opt-in latch_mode =
                # "phase"): the pool-head latch alone is FALSE mid-match —
                # a tenant whose ecosystem drains pool 0 makes the round-2
                # char re-init re-run the seeder over LIVE pools (measured:
                # f4890 wipe, orphaned queues, a freed slot dispatched into
                # palette space). $FF800C.l == 0x00040000 EXACTLY at the
                # char-load phase (measured: 0x40000 at first init, 0x60000
                # mid-round, 0 at the round-2 scrub) — seed only then.
                # ABSENT for Donovan's manifest: his frozen shim bytes are
                # unchanged until his own re-freeze adopts the mode.
                phase_gate = b""
                if shim_cfg.get("latch_mode") == "phase":
                    phase_gate = (bytes([0x0C, 0xB9, 0x00, 0x04, 0x00, 0x00,
                                         0x00, 0xFF, 0x80, 0x0C])  # cmpi.l #$40000,$FF800C.l
                                  + bytes([0x66, 0x0C]))           # bne.s past tst/bne/jsr
                shim = (bytes([0x2F, 0x0D])                       # move.l A5,-(SP)
                        + bytes([0x4B, 0xF9, 0x00, 0xFF, 0x80, 0x00])  # lea $FF8000.l,A5
                        + phase_gate
                        + bytes([0x4A, 0xAD]) + latch.to_bytes(2, "big")  # tst.l (latch,A5)
                        + bytes([0x66, 0x06])                     # bne.s skip seed
                        + bytes([0x4E, 0xB9])
                        + _int(shim_cfg["seed_entry"]).to_bytes(4, "big")
                        + bytes([0x2A, 0x5F])                     # movea.l (SP)+,A5
                        + bytes([0x1D, 0x7C, 0x00, flav_v])       # move.b #default,
                        + flav_d.to_bytes(2, "big")               #   (flavor,A6)
                        + objclr                                  # OBJ-RAM tail clear
                        + bytes([0xBD, 0xFC, 0x00, 0xFF, 0x84, 0x00])  # cmpa.l #$FF8400,A6
                        + bytes([0x66, 0x0A])                     # bne.s p2bit
                        + bytes([0x08, 0x39, 0x00, 0x00])         # btst #0,
                        + hold_flag.to_bytes(4, "big")            #   (flag).l
                        + bytes([0x60, 0x08])                     # bra.s join
                        + bytes([0x08, 0x39, 0x00, 0x01])         # p2bit: btst #1,
                        + hold_flag.to_bytes(4, "big")            #   (flag).l
                        + bytes([0x67, 0x06])                     # join: beq.s skip
                        + bytes([0x1D, 0x7C, 0x00, flav_h])       # move.b #held,
                        + flav_d.to_bytes(2, "big")               #   (flavor,A6)
                        + bytes([0x4E, 0xF9]) + newt.to_bytes(4, "big"))  # skip: jmp
                assert len(shim) == 68 + len(objclr) + len(phase_gate), len(shim)
                ops.append({"op": "code", "addr": f"{sd:#x}", "hex": shim.hex()})
                notes.append(f"code   {sd:#08x} init shim (pool latch A5+"
                             f"{latch:#x}, seeder "
                             f"{_int(shim_cfg['seed_entry']):#x}; flavor "
                             f"(A6+{flav_d:#x})<-{flav_v:#04x}, Start-held "
                             f"[{hold_flag:#x} bit=player] -> {flav_h:#04x}) "
                             f"-> handler {newt:#08x}")
                fragments.append((sd, len(shim), "GEN",
                                  "pool-seed + flavor(+Start-hold) init shim"))
                repoint(d["table"], sd, "donovan handler via seed shim")
            else:
                repoint(d["table"], newt, "donovan handler")

    # ── objram_clear round-start blob (14z-7 v2, pairs with the init-shim
    # marker): detour the ported sword routine's per-frame exit
    # (vs2 0x65F00 `jmp $13C0E` -> placed x065e5a+0xA6, relocated target
    # 0x1551A) through a blob that, when the $FF7F00 marker is armed,
    # clears the full 8KB OBJ list once (both display halves are
    # CPU-visible; the active list rebuilds next frame, the stale
    # VS-screen tail — Donovan's portrait pieces, the round-27 Victor-
    # shock garble — stays cleared). Donovan-gated by construction: the
    # blob only runs from HIS routine; legacy paths never execute it and
    # $FF7F00 is inside the masked dead-stack window.
    if args.stage >= 6 and (port.get("init_shim") or {}).get("objram_clear"):
        if "x065e5a" not in placed:
            fail.append("objram_clear: region x065e5a not placed")
        else:
            site = placed["x065e5a"] + (0x65F00 - 0x65E5A)
            ret = 0x1551A
            # v3: the sword object lives from char-init, so its routine
            # runs DURING the VS screen — gate the consume on the match-
            # active flag ($FF8004.l == 0x40000, the established overlay-
            # thunk gate) so the clear fires on the first real match frame.
            # v4: single-shot clears kept racing pre-match drawers (VS
            # screen redraws through ~f2470; the sword exit path first
            # runs ~f2460) — the marker is now a COUNTDOWN (0x50 frames,
            # decremented only while match-active): the clear lands ~80
            # frames into the round, deterministically past every
            # pre-match drawer, replay-timing independent. It runs in the
            # object-update phase, so the same frame's list rebuild
            # repaints all ACTIVE entries — no visible blank; only stale
            # tail buckets stay cleared.
            blob = (bytes.fromhex("4a3900ff7f00")      # tst.b $ff7f00.l
                    + bytes.fromhex("672c")            # beq.s done
                    + bytes.fromhex("0cb90004000000ff8004")  # cmpi.l #$40000,$ff8004.l
                    + bytes.fromhex("6620")            # bne.s done (marker kept)
                    + bytes.fromhex("533900ff7f00")    # subq.b #1,$ff7f00.l
                    + bytes.fromhex("6618")            # bne.s done (still counting)
                    + bytes.fromhex("48e78080")        # movem.l d0/a0,-(sp)
                    + bytes.fromhex("41f900708000")    # lea $708000.l,a0
                    + bytes.fromhex("303c07ff")        # move.w #$7ff,d0
                    + bytes.fromhex("4298")            # clr.l (a0)+
                    + bytes.fromhex("51c8fffc")        # dbra d0,.-2
                    + bytes.fromhex("4cdf0101")        # movem.l (sp)+,d0/a0
                    + bytes.fromhex("4ef9") + ret.to_bytes(4, "big"))  # done: jmp
            # branch checks: all three branches land on the final jmp
            assert 8 + 0x2C == len(blob) - 6, (hex(len(blob)))
            assert 0x14 + 0x20 == len(blob) - 6, (hex(len(blob)))
            assert 0x1C + 0x18 == len(blob) - 6, (hex(len(blob)))
            bd = alloc("a", len(blob), "objram round-start clear blob")
            if bd is None:
                fail.append("objram_clear: no room for blob")
            else:
                ops.append({"op": "code", "addr": f"{bd:#x}", "hex": blob.hex()})
                ops.append({"op": "code", "addr": f"{site:#x}",
                            "hex": "4ef9" + f"{bd:08x}"})
                notes.append(f"code   {bd:#08x} +{len(blob):#x}  objram clear "
                             f"blob; sword-exit site {site:#08x} detoured")
                fragments.append((bd, len(blob), "GEN", "objram clear blob"))
                fragments.append((site, 6, "GEN", "objram clear detour site"))

    if args.stage >= 5:
        for p in port.get("aux_poke", []):
            # only_base_slot (14z-62c): the row writes TENANT CONTENT over
            # the HOST slot's own bytes in place — legitimate only while the
            # tenant OCCUPIES that slot. On a variant-id build the host is a
            # live legacy character again and the write would corrupt him;
            # the row is skipped and the tenant-side equivalent (if any) is
            # a separate, mechanism-measured row.
            if p.get("only_base_slot") and dst_slot >= 0x10:
                notes.append(f"# aux {p['name']}: SKIPPED (host-slot content; "
                             f"tenant is at variant id {dst_slot:#04x})")
                continue
            # only_variant_slot (14z-63): the row writes a VARIANT-half
            # table row (e.g. HUD tables' aliased row 0x13) — meaningful
            # only when the tenant IS at a variant id; on the base-slot
            # track the variant half must stay the vanilla alias.
            if p.get("only_variant_slot") and dst_slot < 0x10:
                notes.append(f"# aux {p['name']}: SKIPPED (variant-half row; "
                             f"tenant is at base slot {dst_slot:#04x})")
                continue
            ops.append({"op": p["op"], "addr": f"{_int(p['addr']):#x}",
                        "val": f"{_int(p['val']):#x}"})
            notes.append(f"{p['op']} {_int(p['addr']):#08x} <- {_int(p['val']):#x} "
                         f" aux {p['name']}")

    # ── data_port: bulk source-set data placed over verified vanilla spans ──
    # Every row must state its full mechanism in the manifest. Guards:
    # sibling-oracle byte identity (orc), destination old-content head
    # (dst_old_head — proves we overwrite exactly the span we think we do),
    # explicit destination bound (dst_end), and old-verified in-blob fixes.
    if args.stage >= 6:
        for dp in port.get("data_port", []):
            if args.stage < _int(dp.get("stage", 0)):
                continue
            nm = dp["name"]
            # only_base_slot (14z-62c): in-place tenant content over the
            # HOST slot's bytes — skipped on variant-id builds, where the
            # host is a live legacy character again (same rationale as the
            # aux_poke gate above).
            if dp.get("only_base_slot") and dst_slot >= 0x10:
                notes.append(f"# data_port {nm}: SKIPPED (host-slot content; "
                             f"tenant is at variant id {dst_slot:#04x})")
                continue
            src, dst, ln = _int(dp["src"]), _int(dp["dst"]), _int(dp["len"])
            _img = dp.get("src_image", man["src_set"])
            sdat = (root / f"build/out/{_img}_data.bin").read_bytes()
            blob = bytearray(sdat[src:src + ln])
            if len(blob) != ln:
                fail.append(f"data_port {nm}: src read short")
                continue
            if "orc" in dp:
                odat = (root / f"build/out/{man['oracle_set']}_data.bin"
                        ).read_bytes()
                tw = _int(dp["orc"])
                if odat[tw:tw + ln] != bytes(blob):
                    fail.append(f"data_port {nm}: sibling twin at {tw:#x} "
                                f"differs — misbounded or wrong address")
                    continue
            # slot_ptr_table (14z-62c): the destination span is the HOST
            # slot's block, reached through a per-char POINTER TABLE row. On
            # a base-half build the block is replaced in place exactly as
            # before. On a variant-id build the host's block must stay
            # vanilla, so the (fixed) blob is placed by the space model and
            # the TENANT's table row is repointed instead — the same
            # place+repoint shape as sound_table, after asserting the
            # variant row is a vanilla alias of its base-half counterpart.
            spt = _int(dp["slot_ptr_table"]) if "slot_ptr_table" in dp else None
            if spt is None or dst_slot < 0x10:
                if dst + ln > _int(dp["dst_end"]):
                    fail.append(f"data_port {nm}: {ln:#x} bytes overrun "
                                f"dst_end {_int(dp['dst_end']):#x}")
                    continue
                vdat = (root / "build/out/vsavj_data.bin").read_bytes()
                oh = bytes.fromhex(dp["dst_old_head"])
                if vdat[dst:dst + len(oh)] != oh:
                    fail.append(f"data_port {nm}: dest old-content mismatch "
                                f"at {dst:#x} ({vdat[dst:dst+len(oh)].hex()})")
                    continue
            # In-blob fixes ride a FLAT `fixes = "off:old:new[,...]"` string
            # (14z-62c). The nested `[[data_port.fix]]` shape is BANNED: the
            # subset parser (no-tomllib hosts) silently detached it as an
            # orphan top-level key, so the 14z-2 mirror-victim fix never
            # applied on this machine — including in both FROZEN references
            # — while a tomllib host would have applied it. A manifest
            # feature that parses differently per host makes fingerprints
            # host-dependent; hard-fail both shapes.
            if "fix" in dp:
                fail.append(f"data_port {nm}: nested [[data_port.fix]] is "
                            f"banned (host-dependent parse, 14z-62c) — use "
                            f"the flat fixes=\"off:old:new,...\" key")
                continue
            ok = True
            nfix = 0
            for _fx in str(dp.get("fixes", "")).split(","):
                if not _fx.strip():
                    continue
                _off_s, _old_s, _new_s = _fx.strip().split(":")
                off = _int(_off_s)
                old = bytes.fromhex(_old_s)
                new = bytes.fromhex(_new_s)
                if bytes(blob[off:off + len(old)]) != old:
                    fail.append(f"data_port {nm}: fix@{off:#x} old bytes "
                                f"mismatch ({bytes(blob[off:off+len(old)]).hex()})")
                    ok = False
                    break
                blob[off:off + len(new)] = new
                nfix += 1
            if not ok:
                continue
            if spt is not None and dst_slot >= 0x10:
                row_at = spt + 4 * dst_slot
                alias_at = spt + 4 * (dst_slot & 0x0F)
                if vj_u32(row_at) != vj_u32(alias_at):
                    fail.append(f"data_port {nm}: variant row {row_at:#x} "
                                f"({vj_u32(row_at):#x}) does not alias its "
                                f"base-half counterpart "
                                f"({vj_u32(alias_at):#x}) — table shape moved")
                    continue
                # the declared dst documents the BASE-HALF slot's block the
                # in-place mode overwrites; anchor that this table is the
                # one that points at it (any base-half row — the manifest's
                # dst belonged to the ORIGINAL slot, not the tenant's alias)
                if dst not in [vj_u32(spt + 4 * i) for i in range(16)]:
                    fail.append(f"data_port {nm}: no base-half row of "
                                f"slot_ptr_table {spt:#x} points at the "
                                f"declared dst {dst:#x} — wrong table?")
                    continue
                pdst = alloc(dp.get("hole", "b"), ln, f"data_port {nm} block")
                if pdst is None:
                    continue
                ops.append({"op": "data", "addr": f"{pdst:#x}",
                            "hex": bytes(blob).hex()})
                ops.append({"op": "poke32", "addr": f"{row_at:#x}",
                            "val": f"{pdst:#x}"})
                notes.append(f"data   {pdst:#08x} +{ln:#x}  data_port {nm} "
                             f"PLACED (tenant at {dst_slot:#04x}; host block "
                             f"{dst:#x} untouched) <- {man['src_set']} "
                             f"{src:#08x} ({nfix} fixes)")
                notes.append(f"poke32 {row_at:#08x} <- {pdst:#x}  data_port "
                             f"{nm} ptr-table {spt:#x} row {dst_slot:#04x}")
                fragments.append((pdst, ln, "VS2",
                                  f"data_port {nm} placed block "
                                  f"({man['src_set']} {src:#06x})"))
                continue
            ops.append({"op": "data", "addr": f"{dst:#x}",
                        "hex": bytes(blob).hex()})
            notes.append(f"data   {dst:#08x} +{ln:#x}  data_port {nm} <- "
                         f"{man['src_set']} {src:#08x} "
                         f"({nfix} fixes)")
            fragments.append((dst, ln, "VS2",
                              f"data_port {nm} ({man['src_set']} {src:#06x})"))

    # ── sound_table (14z-52): port a per-char QSound record array with an
    # ID ALLOWLIST. The engine's own dispatcher skips a record whose id
    # word is 0 (`tst.w d1; beq`), so ids that have no faithful vsavj
    # meaning are zeroed rather than translated — silence beats the wrong
    # sound, and vsavj's 0x700-0x7FF ids are MUSIC TRACKS where vs2 put
    # the newcomer voice bank (14z-52 measurement, docs/project/m5/). The blob is
    # hole-allocated and the per-char pointer row is repointed, so the
    # array length is bounded by OUR measurement (max index used + 1),
    # not by the length of the slot's vanilla array.
    if args.stage >= 6:
        for st in port.get("sound_table", []):
            if args.stage < _int(st.get("stage", 0)):
                continue
            # Profile-gated CONTENT, the companion to profile-gated space: a
            # row that lives in the WIDE extension must not be emitted into a
            # stock-size build, where it would either fail to allocate or —
            # worse — silently land somewhere else.
            if st.get("profile") and st["profile"] != args.profile:
                continue
            nm = st["name"]
            src = _int(st["src"])
            n = _int(st["entries"])
            keep = {_int(x) for x in str(st["keep_ids"]).split(",") if x.strip()}
            sdat = (root / f"build/out/{man['src_set']}_data.bin").read_bytes()
            blob = bytearray(sdat[src:src + n * 8])
            if len(blob) != n * 8:
                fail.append(f"sound_table {nm}: src read short")
                continue
            zeroed = []
            for i in range(n):
                o = i * 8
                sid = int.from_bytes(blob[o:o + 2], "big")
                alt = int.from_bytes(blob[o + 2:o + 4], "big")
                if sid and sid not in keep:
                    zeroed.append((i, sid))
                    blob[o:o + 2] = b"\x00\x00"
                if alt and alt not in keep:
                    blob[o + 2:o + 4] = b"\x00\x00"
            dst = alloc(st.get("hole", "a"), len(blob), f"sound_table {nm}")
            if dst is None:
                continue
            # The row FOLLOWS THE TENANT (14z-62c; ptr_row used to be a
            # manifest constant 0x0F, so a variant-id build repointed
            # JEDAH's sfx array at Donovan's). ptr_old documents the
            # base-half slot's vanilla pointer; a variant row is instead
            # anchored on being a vanilla ALIAS of its base-half
            # counterpart.
            if "ptr_row" in st:
                fail.append(f"sound_table {nm}: the manifest declares a "
                            f"fixed 'ptr_row' — the row follows the tenant "
                            f"now (14z-62c); delete the key")
                continue
            ptr_row = dst_slot
            ptr_at = _int(st["ptr_table"]) + ptr_row * 4
            old_ptr = vj_u32(ptr_at)
            if ptr_row >= 0x10:
                alias = vj_u32(_int(st["ptr_table"]) + (ptr_row & 0x0F) * 4)
                if old_ptr != alias:
                    fail.append(f"sound_table {nm}: variant ptr row holds "
                                f"{old_ptr:#x}, not the base-half alias "
                                f"{alias:#x} — table shape moved")
                    continue
            elif "ptr_old" in st and old_ptr != _int(st["ptr_old"]):
                fail.append(f"sound_table {nm}: ptr row holds {old_ptr:#x}, "
                            f"manifest expects {_int(st['ptr_old']):#x}")
                continue
            ops.append({"op": "data", "addr": f"{dst:#x}",
                        "hex": bytes(blob).hex()})
            ops.append({"op": "poke32", "addr": f"{ptr_at:#x}",
                        "val": f"{dst:#x}"})
            kept = [f"{int.from_bytes(blob[i*8:i*8+2],'big'):#05x}@{i}"
                    for i in range(n) if int.from_bytes(blob[i*8:i*8+2], "big")]
            notes.append(f"data   {dst:#08x} +{len(blob):#x}  sound_table {nm} "
                         f"<- {man['src_set']} {src:#08x} ({n} entries; "
                         f"kept {kept}; zeroed {len(zeroed)} unplayable ids)")
            notes.append(f"poke32 {ptr_at:#08x} <- {dst:#x}  "
                         f"sound_table {nm} per-char ptr row "
                         f"{ptr_row:#04x} (was {old_ptr:#x})")
            fragments.append((dst, len(blob), "VS2",
                              f"sound_table {nm} ({man['src_set']} {src:#06x}, "
                              f"id-allowlisted)"))

    # ── select_wheel (14z-60s): append three cells to the character-select
    # wheel. Three edits, none of which shifts a byte of existing content:
    #   1. TABLE B in place — rows 0x10/0x11/0x13 physically exist already as
    #      unused alias copies, so the new rows and the inbound edges are a
    #      28-byte overwrite, no growth, no relocation.
    #   2. the OBJ record and its coordinate list COPIED into profile-gated
    #      space, widened by three entries, with the vanilla budget word
    #      carried over (GOTCHAS: the emitter debits it from a shared
    #      per-frame budget; a change once flipped a skip decision into a
    #      one-byte $FF811B divergence). 85 >= 21 entries.
    #   3. one longword repointed, the record's single referrer.
    # The vanilla record and list are left untouched where they are: measured
    # to have exactly one referrer each and no interior pointers
    # (docs/game/atlas/select_screen.md), which is what makes copy-and-repoint
    # safe rather than a relocation that has to be prayed over.
    if args.stage >= 6:
        for sw in port.get("select_wheel", []):
            if args.stage < _int(sw.get("stage", 0)):
                continue
            if sw.get("profile") and sw["profile"] != args.profile:
                continue
            nm = sw["name"]
            lay = json.loads((root / sw["layout"]).read_text())
            tb = _int(sw["table_b"])
            rec = _int(sw["record"])
            recptr = _int(sw["record_ptr"])
            clist = _int(sw["coord_list"])

            fmtw, budget, count = struct.unpack(">HHH", vj[rec:rec + 6])
            cptr = int.from_bytes(vj[rec + 6:rec + 10], "big")
            nvan = count + 1
            bad = []
            if count != _int(sw["expect_count"]):
                bad.append(f"count {count} != {_int(sw['expect_count'])}")
            if budget != _int(sw["expect_budget"]):
                bad.append(f"budget {budget:#x} != {_int(sw['expect_budget']):#x}")
            if cptr != _int(sw["expect_cptr"]):
                bad.append(f"cptr {cptr:#x} != {_int(sw['expect_cptr']):#x}")
            if vj_u32(recptr) != rec:
                bad.append(f"{recptr:#x} holds {vj_u32(recptr):#x}, not {rec:#x}")
            if bad:
                fail.append(f"select_wheel {nm}: vanilla anchors moved: "
                            + "; ".join(bad))
                continue

            DIRS = ["R", "L", "D", "U", "DR", "DL", "UR", "UL"]
            # Cell keys are BARE HEX ("10", "11", "13") — parse them as hex
            # explicitly. _int() treats a bare decimal string as decimal, so
            # "10"/"11"/"13" came out as 0x0A/0x0B/0x0D and the new rows were
            # written over Sasquatch, random and Lei-Lei while the newcomers
            # were never created at all. Caught only because two tools
            # disagreed on the changed-byte count by 2 (14z-60s).
            def _cell(k):
                c = int(str(k), 16)
                if not (0x10 <= c <= 0x1F):
                    fail.append(f"select_wheel {nm}: new cell {c:#04x} is not "
                                f"in the variant half 0x10-0x1F — a new cell "
                                f"may never overwrite a vanilla cell")
                if c in (0x12, 0x18):
                    fail.append(f"select_wheel {nm}: id {c:#04x} is RESERVED "
                                f"(docs/game/atlas/id_space.md)")
                return c
            # --- 1. TABLE B, in place -------------------------------------
            rows = [bytearray(vj[tb + c * 8: tb + c * 8 + 8]) for c in range(32)]
            for k, spec in lay["cells"].items():
                c = _cell(k)
                for i, dname in enumerate(DIRS):
                    rows[c][i] = _int(spec["adjacency"][dname])
            for e in lay.get("edges_in", []):
                rows[_int(e["from"])][DIRS.index(e["dir"])] = _int(e["to"])
            nb = 0
            for c in range(32):
                if bytes(rows[c]) != vj[tb + c * 8: tb + c * 8 + 8]:
                    ops.append({"op": "data", "addr": f"{tb + c * 8:#x}",
                                "hex": bytes(rows[c]).hex()})
                    nb += sum(1 for i in range(8)
                              if rows[c][i] != vj[tb + c * 8 + i])
            notes.append(f"data   {tb:#08x}        select_wheel {nm}: TABLE B "
                         f"in place, {nb} bytes over "
                         f"{len(lay['cells'])} new rows + "
                         f"{len(lay.get('edges_in', []))} inbound edges")

            # --- 2. coord list: copy + append ------------------------------
            newcells = [(_cell(k), dict(v)) for k, v in lay["cells"].items()]
            newcells.sort(key=lambda kv: kv[0])
            # bank5 palette rows (14z-63, maintainer round): the layout's
            # vs2 attr pal rows are SHARED vanilla medallion rows here, so
            # real art rendered under wrong palettes (Phobos/Pyron read as
            # noise). On group-C builds each cell's entry is re-palmed to
            # its declared FREE row (measured: OBJ-unreferenced on select
            # across 3 replays + a live poke-probe changed zero pixels)
            # and the vs2 palette bytes are written into select block A
            # (the wheel view's live copy) in the bank5 branch below.
            bank5_active = (sw.get("bank5")
                            and _int(port["port"].get("gfx_bank", 2)) >= 4)
            if bank5_active:
                for _c, spec in newcells:
                    if "pal_row" in spec:
                        spec["attr"] = ((_int(spec["attr"]) & ~0x1F)
                                        | _int(spec["pal_row"]))
            cl = bytearray(vj[clist:clist + nvan * 4])
            # The list's pairs are RELATIVE to the drawer object's base
            # (measured (256,176) — see the layout's _coord_note); 'pos'
            # is a ring-centre, corner_offset the sprite-corner shift.
            # Appending pos verbatim put the three entries at OBJ
            # x=480+/y=344+ — emitted, never on screen (14z-62i).
            _bx, _by = lay.get("obj_base", (0, 0))
            _cx, _cy = lay.get("corner_offset", (0, 0))
            for _c, spec in newcells:
                x, y = spec["pos"]
                cl += struct.pack(">hh", int(x) + int(_cx) - int(_bx),
                                  int(y) + int(_cy) - int(_by))
            cl_dst = alloc(sw.get("hole", "a"), len(cl),
                           f"select_wheel {nm} coords")
            if cl_dst is None:
                continue

            # --- 3. record: copy + append + repoint ------------------------
            body = bytearray(vj[rec:rec + 10 + nvan * 4])
            struct.pack_into(">H", body, 4, nvan + len(newcells) - 1)  # count
            struct.pack_into(">I", body, 6, cl_dst)                    # cptr
            for _c, spec in newcells:
                body += struct.pack(">HH", _int(spec["tile"]), _int(spec["attr"]))
            rec_dst = alloc(sw.get("hole", "a"), len(body),
                            f"select_wheel {nm} record")
            if rec_dst is None:
                continue

            ops.append({"op": "data", "addr": f"{cl_dst:#x}", "hex": bytes(cl).hex()})
            ops.append({"op": "data", "addr": f"{rec_dst:#x}", "hex": bytes(body).hex()})
            ops.append({"op": "poke32", "addr": f"{recptr:#x}", "val": f"{rec_dst:#x}"})
            notes.append(f"data   {cl_dst:#08x} +{len(cl):#x}  select_wheel {nm} "
                         f"coord list ({nvan} vanilla + {len(newcells)} new)")
            notes.append(f"data   {rec_dst:#08x} +{len(body):#x}  select_wheel {nm} "
                         f"record (count {count}->{nvan + len(newcells) - 1}, "
                         f"budget {budget:#x} CARRIED OVER, cptr -> {cl_dst:#x})")
            notes.append(f"poke32 {recptr:#08x} <- {rec_dst:#x}  select_wheel "
                         f"{nm} record ptr (was {rec:#x}; the record's ONLY "
                         f"referrer — vanilla record and list are untouched)")
            fragments.append((rec_dst, len(body), "NEW",
                              f"select_wheel {nm} record (21 cells)"))
            fragments.append((cl_dst, len(cl), "NEW",
                              f"select_wheel {nm} coord list"))

            # ── highlight base rows (14z-63, phase 3 item 2): the ring/
            # highlight drawer ($FFBA00) positions per hovered cell via a
            # 32-row pc-relative word-pair table at the site below —
            # variant half a byte-identical ALIAS in vsav (the TABLE B
            # convention), UN-aliased in vs2 where Capcom wrote its
            # newcomers' bases. Without this, hovering an appended cell
            # draws the highlight at the aliased row's base (the
            # misplaced-label report, 14z-62i). In-place overwrite of
            # rows 0x10/0x11/0x13 with the layout's highlight_base pairs;
            # row 0x12 keeps the alias (reserved id). PC-relative reads
            # assert the PROGRAM function code, so the stored bytes are
            # ENCRYPTED — these are code ops, not data ops. Independent
            # of bank5/group C: any extended-wheel build needs it.
            if sw.get("highlight_base_site"):
                hb_site = _int(sw["highlight_base_site"])
                opc_hb = (root / "build/out/vsavj_opcodes.bin").read_bytes()
                lo_half = opc_hb[hb_site:hb_site + 0x40]
                hi_half = opc_hb[hb_site + 0x40:hb_site + 0x80]
                if lo_half != hi_half:
                    fail.append(f"select_wheel {nm}: highlight base table "
                                f"at {hb_site:#x} variant half is NOT an "
                                f"alias of the base half — wrong site or "
                                f"moved table")
                    continue
                nrows = 0
                for _c, spec in newcells:
                    hb = spec.get("highlight_base")
                    if hb is None:
                        fail.append(f"select_wheel {nm}: cell {_c:#04x} "
                                    f"has no highlight_base in the layout")
                        continue
                    row = hb_site + 4 * _c
                    ops.append({"op": "code", "addr": f"{row:#x}",
                                "hex": struct.pack(">HH", int(hb[0]),
                                                   int(hb[1])).hex()})
                    nrows += 1
                    notes.append(f"code   {row:#08x} +4     select_wheel "
                                 f"{nm}: highlight base row {_c:#04x} <- "
                                 f"({hb[0]},{hb[1]}) (was the row "
                                 f"{_c & 0x0F:#04x} alias)")
                notes.append(f"# select_wheel {nm}: {nrows} highlight base "
                             f"rows written in place (32-row aliased "
                             f"pc-rel table {hb_site:#x}; the vs2 "
                             f"precedent — its variant half is un-aliased "
                             f"for its newcomers)")

            # ── ring_rows (14z-63, maintainer-ratified round 7): the
            # extended cells' hover highlight = the host's ring_ref_cell
            # ring records verbatim (records encode no cell identity; the
            # extended base table above does the placement). P1+P2 rows
            # for cells NOT owned by the tenant (the tenant's own rows
            # ride [[select_records]] art="host_ring"), MIRROR rows
            # (array +0x100) for ALL new cells.
            if sw.get("ring_rows"):
                hl = _int(sw["highlight_array"])
                ref_c = _int(sw["ring_ref_cell"])
                nring = 0
                for off, halves in ((0x00, "p1"), (0x80, "p2"),
                                    (0x100, "mirror")):
                    lo = vj[hl + off:hl + off + 0x40]
                    hi = vj[hl + off + 0x40:hl + off + 0x80]
                    if lo != hi:
                        fail.append(f"select_wheel {nm}: highlight "
                                    f"{halves} half at {hl + off:#x} is "
                                    f"not 32-row aliased")
                        continue
                    ref_rec = vj_u32(hl + off + 4 * ref_c)
                    ref_fmt = int.from_bytes(vj[ref_rec:ref_rec + 2],
                                             "big")
                    if ref_fmt not in (0, 2):
                        fail.append(f"select_wheel {nm}: {halves} ring "
                                    f"ref {ref_rec:#x} fmt {ref_fmt:#x} "
                                    f"not a record")
                        continue
                    for _c, spec in newcells:
                        if halves != "mirror" and _c == dst_slot:
                            continue   # the tenant's P1/P2 rows are
                                       # select_records host_ring's
                        row = hl + off + 4 * _c
                        ops.append({"op": "poke32", "addr": f"{row:#x}",
                                    "val": f"{ref_rec:#x}"})
                        nring += 1
                        notes.append(f"poke32 {row:#08x} <- {ref_rec:#x}"
                                     f"  select_wheel {nm}: {halves} "
                                     f"highlight row {_c:#04x} = host "
                                     f"row {ref_c:#04x} ring (ring_rows)")
                notes.append(f"# select_wheel {nm}: {nring} ring rows "
                             f"poked (host row {ref_c:#04x} records "
                             f"verbatim; P1/P2 for non-tenant cells + "
                             f"mirror for all)")

            # ── bank5 (14z-63, phase 3): serve the WHOLE wheel from WIDE
            # group C bank 5 — real medallion art for the appended cells,
            # vanilla-cell pixels identical BY CONSTRUCTION (byte-copied
            # tiles). The wheel drawer is ONE object (one bank word), so
            # per-entry banks are impossible; the measured mechanism:
            #   * select entry inits the drawer ($FFB800) at PRG:0x5F8B2
            #     `move.w #$2000,$18(a6)` — a per-object init that writes
            #     ONLY this object's bank word (family-wide tap, 14z-63),
            #     unlike the shared attract loop at 0x07C428 (stride-0x80
            #     over every menu object — NEVER patch that one).
            #   * on select the drawer's anim chain is a single FF-entry
            #     (0x2689FA -> the wheel record, stop-flagged), so the
            #     flip affects exactly the wheel record's tiles.
            #   * the VS-phase re-init (0x5FD02) rewrites the field, so
            #     the RAM divergence re-converges (§4 v3 window; end
            #     moves ~2362 -> ~2415 on the pick replays).
            # Tile inventory (emitted for build_gfx_donovan --wheel-bank5):
            # every tile of every vanilla entry, host art byte-identical
            # vsav group A -> group C 0x10000+code; the appended entries'
            # native vs2 codes, art from vs2 group A. Gated on a group-C
            # tenant: with the band in banks 2-3 there is no group C to
            # hold the art, and the flip would serve zeros (the m5_wide
            # 0x0F+WIDE shape keeps its placeholder medallions).
            if sw.get("bank5"):
                from gfx_tiles import bank_word as _bw5
                if _int(port["port"].get("gfx_bank", 2)) < 4:
                    notes.append(f"# select_wheel {nm}: bank5 SKIPPED — "
                                 f"tenant gfx bank < 4 (no group C); "
                                 f"placeholder medallions retained")
                else:
                    site = _int(sw["bank_site"])
                    old = bytes.fromhex(sw["bank_site_old"])
                    opc5 = (root / "build/out/vsavj_opcodes.bin").read_bytes()
                    if opc5[site:site + 6] != old:
                        fail.append(f"select_wheel {nm}: bank site "
                                    f"{site:#x} holds "
                                    f"{opc5[site:site+6].hex()}, expected "
                                    f"{old.hex()} (move.w #$2000,$18(a6))")
                        continue
                    newhex = old[:2].hex() + f"{_bw5(5):04x}" + old[4:].hex()
                    ops.append({"op": "code", "addr": f"{site:#x}",
                                "hex": newhex})

                    def _blk(t, at, into):
                        bx = ((at >> 8) & 15) + 1
                        by = ((at >> 12) & 15) + 1
                        for dy in range(by):
                            for dx in range(bx):
                                into.add((t & ~0xF) + (dy << 4)
                                         + ((t + dx) & 0xF))
                    host_t, new_t = set(), set()
                    for k in range(nvan):
                        t5, at5 = struct.unpack(
                            ">HH", vj[rec + 10 + 4 * k:rec + 14 + 4 * k])
                        _blk(t5, at5, host_t)
                    for _c, spec in newcells:
                        _blk(_int(spec["tile"]), _int(spec["attr"]), new_t)
                    both = host_t & new_t
                    if both:
                        fail.append(f"select_wheel {nm}: host/new tile "
                                    f"overlap {sorted(hex(x) for x in both)}")
                        continue
                    (out / "wheel_bank5.json").write_text(json.dumps(
                        {"host": sorted(host_t), "vs2": sorted(new_t)}))
                    notes.append(f"code   {site:#08x} +6     select_wheel "
                                 f"{nm}: drawer bank word #$2000 -> "
                                 f"#${_bw5(5):04x} (bank 5) in the select "
                                 f"init — writes ONLY $FFB818 (measured)")
                    notes.append(f"# select_wheel {nm}: {len(host_t)} host "
                                 f"+ {len(new_t)} vs2 tiles -> "
                                 f"wheel_bank5.json (group C upper bank, "
                                 f"placed by build_gfx --wheel-bank5)")
                    # medallion palettes (14z-63): the vs2 rows into the
                    # select block A's free rows. RESERVED rows refused:
                    # figure bases/swords/ring/host-medallion (measured
                    # select row map).
                    pal_a = _int(sw.get("pal_block_a", 0))
                    src_wp5 = (root / f"build/out/{man['src_set']}"
                               "_data.bin").read_bytes()
                    RESERVED_PAL = {0x14, 0x15, 0x17, 0x18, 0x1E}
                    for _c, spec in newcells:
                        pr = spec.get("pal_row")
                        ps = spec.get("pal_src")
                        if pr is None or ps is None or not pal_a:
                            fail.append(f"select_wheel {nm}: bank5 cell "
                                        f"{_c:#04x} lacks pal_row/pal_src "
                                        f"(or no pal_block_a) — real art "
                                        f"needs its real palette")
                            continue
                        pr, ps = _int(pr), _int(ps)
                        if pr >= 0x20 or pr in RESERVED_PAL:
                            fail.append(f"select_wheel {nm}: pal_row "
                                        f"{pr:#04x} for cell {_c:#04x} is "
                                        f"reserved or out of range")
                            continue
                        rowb = src_wp5[ps:ps + 0x20]
                        dstp = pal_a + pr * 0x20
                        ops.append({"op": "data", "addr": f"{dstp:#x}",
                                    "hex": rowb.hex()})
                        notes.append(f"data   {dstp:#08x} +0x20  "
                                     f"select_wheel {nm}: medallion pal "
                                     f"row {pr:#04x} (cell {_c:#04x}) <- "
                                     f"vs2 {ps:#x}; entry attr re-palmed")

                    # per-frame palette re-assert (14z-63 round 10 — the
                    # WHITE-OUT fix). The select venue-phase system fades
                    # the whole page from per-phase source blocks the
                    # engine COMPUTES (measured: rows 0x16/0x19/0x00 get
                    # foreign content from 0x3A02C0/0x3A0900/0x3A0960/
                    # 0x3A12C0/0x39A7E0... — sticky, e.g. Donovan's
                    # medallion whiting out), so "a free row" does not
                    # survive phase changes. Instead of chasing every
                    # computed block, the highlight position helper at
                    # 0x5FAD0 — the once-per-select-frame heartbeat,
                    # alive for the screen's whole life — is thunked to
                    # ALSO copy the three block-A rows into palette RAM
                    # (F000-alpha OR, the loader's transform) every
                    # frame: any clobber self-heals next frame, for any
                    # phase known or unknown. Position writes stay
                    # byte-identical (same table via absolute lea);
                    # palette RAM is outside the work-RAM basis, so the
                    # only legacy cost is cycles inside the already-open
                    # select window class. The thunk consumes the whole
                    # 18-byte helper (jsr overwrites its first 3 words;
                    # the remnant is unreachable), so it pops the
                    # helper-internal return and rts's to the caller.
                    # ── march retarget (14z-63 round 10 — the WHITE-OUT
                    # fix). Root cause: the accent MARCH claims palette
                    # row 0x16 in a late select venue phase (the marcher
                    # iterates a row list through the shared uploader's
                    # dest computation at 0x2AD44), overwriting Donovan's
                    # medallion palette with the silver sword march —
                    # invisible on vanilla (row unreferenced), sticky on
                    # ours. Measured: through this uploader row 0x16 is
                    # written ONLY on select (never in matches, 2P
                    # victories, or transitions — those are the fade/load
                    # families), so the redirect is unconditional at the
                    # site: row 0x16 -> row 0x02 (unref-on-select; its
                    # only other select writer is the late hurry phase,
                    # also invisible). Legacy: palette RAM only, both
                    # rows invisible, work RAM untouched (d0 is the
                    # function's own scratch), cycles = the accepted
                    # accent-thunk class on the same call path.
                    mr = sw.get("march_retarget_mid")
                    if mr:
                        # two mid-row dest computations exist (of the four
                        # `move.b $18b(a6),d0` sites): 0x2AD44 (+d1, the
                        # d1-carry family) and 0x2B598 (+1, the per-hover
                        # figure-family writer measured via d0=0xC0 at the
                        # tail). Both are thunked with the same redirect.
                        # Of the THREE dest computations in the
                        # uploader region (add+lsl#5 idiom census), only
                        # TWO are thunked: 0x2AD44 ($18B+d1) is the
                        # IN-MATCH accent path (all four accent sites
                        # funnel through it) — thunking it shifted a
                        # frame-boundary parity permanently (replay 04
                        # f2009 / 05 f9126, the $FF8094 phase flip,
                        # measured 14z-64) AND it never computes the mid
                        # rows on select (the v2 build with it alone
                        # still whited out). The measured select mid-row
                        # writers are the other two. Each thunk also
                        # gates on the select screen being live
                        # ($FFB818 == 0x3000, the wheel drawer's bank
                        # word — set at select entry, cleared by the VS
                        # re-init) as insurance for unmeasured flows.
                        MR_SITES = [
                            (0x2B598, "102e018b5200"),  # $18B + 1 (phase)
                            (0x2B7D8, "102e000fd001"),  # $F + d1 (hover,
                                                        # jump table
                                                        # 0x2B640)
                        ]
                        opc7 = (root / "build/out/vsavj_opcodes.bin"
                                ).read_bytes()
                        for MR_SITE, MR_OLD in MR_SITES:
                            if opc7[MR_SITE:MR_SITE + 6].hex() != MR_OLD:
                                fail.append(f"select_wheel {nm}: march "
                                            f"dest site {MR_SITE:#x} holds"
                                            f" {opc7[MR_SITE:MR_SITE+6].hex()}"
                                            f", expected {MR_OLD}")
                                continue
                            mbody = (
                                MR_OLD        # the displaced load+add
                                + "0c000016"  # cmpi.b #$16,d0
                                "670e"        # beq.b maybe
                                "0c000019"    # cmpi.b #$19,d0
                                "6708"        # beq.b maybe
                                "0c00001a"    # cmpi.b #$1A,d0
                                "6702"        # beq.b maybe
                                "4e75"        # rts
                                # maybe: redirect only while the select
                                # screen is live (wheel drawer bank word)
                                "0c79300000ffb818"  # cmpi.w #$3000,$FFB818
                                "6602"        # bne.b rts
                                "7002"        # moveq #2,d0
                                "4e75")       # rts
                            mt = alloc("a", len(mbody) // 2,
                                       f"select_wheel {nm} march mid-row "
                                       f"retarget {MR_SITE:#x}")
                            if mt is None:
                                continue
                            ops.append({"op": "code", "addr": f"{mt:#x}",
                                        "hex": mbody})
                            ops.append({"op": "code",
                                        "addr": f"{MR_SITE:#x}",
                                        "hex": f"4eb9{mt:08x}"})
                            notes.append(
                                f"code   {mt:#08x} +{len(mbody)//2:#x}"
                                f"  select_wheel {nm}: march mid-row "
                                f"retarget 0x16/0x19 -> 0x02 (dest "
                                f"computation {MR_SITE:#x} jsr-routed)")
                            fragments.append(
                                (mt, len(mbody) // 2, "NEW",
                                 f"select_wheel {nm} march mid-row "
                                 f"retarget {MR_SITE:#x}"))

                    # DISABLED by default (pal_reassert flag): measured
                    # 14z-63 round 10 — even a check-then-copy version
                    # perturbs the legacy fade system (the fade reads
                    # back re-asserted values; its step counters at
                    # $FF0E94/A4/B4/C4 diverge on every fade and never
                    # re-converge). Superseded by march_retarget above.
                    hb_site2 = (_int(sw.get("highlight_base_site", 0))
                                if sw.get("pal_reassert") else 0)
                    if hb_site2:
                        HELPER = 0x5FAD0
                        OLD6 = "3006e5483d7b"
                        opc6 = (root / "build/out/vsavj_opcodes.bin"
                                ).read_bytes()
                        if opc6[HELPER:HELPER + 6].hex() != OLD6:
                            fail.append(f"select_wheel {nm}: helper "
                                        f"{HELPER:#x} holds "
                                        f"{opc6[HELPER:HELPER+6].hex()}, "
                                        f"expected {OLD6}")
                            continue
                        # check-then-copy: an always-copy version cost
                        # ~700 cycles/frame and SHIFTED a legacy
                        # input-accept boundary (replay 11's pick moved
                        # a tick; the match never re-converged — a real
                        # violation, measured). The steady-state path is
                        # three cmpi.w probes on each row's WORD 1 (word
                        # 0 collides: Phobos's f111 == the grey ramp's)
                        # + an early exit; the copy loops run only on
                        # the frame after an actual clobber.
                        prefix = (
                            "2f08"                       # move.l a0,-(sp)
                            "3006"                       # move.w d6,d0
                            "e548"                       # lsl.w #2,d0
                            f"41f9{hb_site2:08x}"        # lea table.l,a0
                            "3d7000000010"               # move.w (a0,d0.w),$10(a6)
                            "3d7000020014"               # move.w 2(a0,d0.w),$14(a6)
                            "205f"                       # movea.l (sp)+,a0
                        )
                        checks = ""
                        n_c = len(newcells)
                        for i, (_c2, spec2) in enumerate(newcells):
                            pr2 = _int(spec2["pal_row"])
                            rowb2 = src_wp5[_int(spec2["pal_src"]) + 2:
                                            _int(spec2["pal_src"]) + 4]
                            w1 = ((rowb2[0] | 0xF0) << 8) | rowb2[1]
                            dst2 = 0x90C000 + pr2 * 0x20 + 2
                            # bne.b to heal: remaining checks then exit(4)
                            remaining = (n_c - 1 - i) * 10
                            disp = remaining + 4
                            checks += (f"0c79{w1:04x}{dst2:08x}"
                                       f"66{disp:02x}")
                        exit_ = "588f4e75"               # addq #4,sp; rts
                        heal = "48e740c0"                # movem.l d1/a0-a1,-(sp)
                        for _c2, spec2 in newcells:
                            pr2 = _int(spec2["pal_row"])
                            src2 = pal_a + pr2 * 0x20
                            dst2 = 0x90C000 + pr2 * 0x20
                            heal += (
                                f"41f9{src2:08x}"        # lea src.l,a0
                                f"43f9{dst2:08x}"        # lea dst.l,a1
                                "700f"                   # moveq #15,d0
                                "3218"                   # move.w (a0)+,d1
                                "0041f000"               # ori.w #$F000,d1
                                "32c1"                   # move.w d1,(a1)+
                                "51c8fff6"               # dbra d0,.-8
                            )
                        heal += ("4cdf0302"              # movem.l (sp)+,d1/a0-a1
                                 "588f4e75")             # addq #4,sp; rts
                        body = prefix + checks + exit_ + heal
                        tk2 = alloc("a", len(body) // 2,
                                    f"select_wheel {nm} pal re-assert thunk")
                        if tk2 is not None:
                            ops.append({"op": "code", "addr": f"{tk2:#x}",
                                        "hex": body})
                            ops.append({"op": "code",
                                        "addr": f"{HELPER:#x}",
                                        "hex": f"4eb9{tk2:08x}"})
                            notes.append(f"code   {tk2:#08x} +{len(body)//2:#x}"
                                         f"  select_wheel {nm}: per-frame "
                                         f"medallion-palette re-assert "
                                         f"(the select heartbeat helper "
                                         f"{HELPER:#x} jsr-routed; position "
                                         f"writes byte-identical, 3 rows "
                                         f"re-copied each frame)")
                            fragments.append((tk2, len(body) // 2, "NEW",
                                              f"select_wheel {nm} pal "
                                              f"re-assert thunk"))

    # ── select_records (M3a, 14z-62): the tenant's OWN select records at a
    # variant id — what the hovered cell displays. Three UI pieces (portrait,
    # name banner, cursor highlight) each ride a 32-row x 4-byte
    # record-pointer array per player (P2 array = P1 + 0x80), indexed by the
    # cursor CELL/ID with NO 4-bit fold; rows 0x10-0x1F alias 0x00-0x0F in
    # vanilla, and no legacy gameplay path writes a variant-half id — so
    # repointing the tenant's two rows per piece touches nothing legacy
    # content can reach, BY CONSTRUCTION (docs/game/atlas/select_screen.md;
    # tests/test_select_arrays.sh, tests/audit_id_writers.sh). At the
    # substituted slot 0x0F this section is INERT: select_port.py's in-place
    # surgery remains that track's mechanism, and the frozen references
    # rebuild byte-identically.
    #
    # Composed records keep VS2'S OWN budget words: the budget debits the OBJ
    # emitter's shared frame budget only on frames that DRAW the record, and
    # a variant row draws only when the tenant is hovered — new-character
    # content by definition (contrast select_port's in-place surgery, which
    # must keep the host's budget because legacy cursors visit slot 0x0F).
    #
    # Tile codes are remapped through select_port.PLACEMENTS (the single
    # placement map — the tenant's select art still sits in the host band
    # until the gfx half moves it to WIDE group C). Entries with no placement
    # keep their vs2 codes as DOCUMENTED PLACEHOLDERS where the manifest row
    # allows it (the ratified medallion policy: imperfect art is acceptable,
    # mechanical soundness is not). The pairs the composed records rely on
    # are emitted as select_tiles.json so the gfx stage places exactly the
    # art these records reference — and none of the slot-0x0F-only families
    # (splash/win-quote), whose Jedah art therefore returns to vanilla on
    # variant-id builds.
    if args.stage >= 6 and dst_slot >= 0x10 and port.get("select_records"):
        import select_port as _selp
        _src_char = _int(port["port"]["src_char"])
        src_data = (root / f"build/out/{man['src_set']}_data.bin").read_bytes()

        def _u16(b, o):
            return int.from_bytes(b[o:o + 2], "big")

        def _u32(b, o):
            return int.from_bytes(b[o:o + 4], "big")

        sel_pairs = {}
        sel_bank5 = set()
        for sr in port["select_records"]:
            if args.stage < _int(sr.get("stage", 0)):
                continue
            nm = sr["name"]
            # art = "native_c5" (14z-62j, option A): the record keeps its
            # NATIVE vs2 tile codes and the art rides WIDE group C bank 5
            # at 0x10000+code — no placement map, no placeholders. The
            # piece's drawer object must be bank-gated on the tenant
            # (the palette thunk does the portrait's).
            # art = "host_ring" (14z-63, maintainer-ratified): the piece's
            # vs2 record is the WRONG UI piece for this slot (vs2's
            # post-confirm name bar vs vsavj's hover ring), so the
            # tenant's rows point at the HOST's ring_ref_cell record
            # VERBATIM — no composition, no allocation, no vs2 read.
            _native = sr.get("art") == "native_c5"
            _host_ring = sr.get("art") == "host_ring"
            for side in ("p1", "p2"):
                # single-sided pieces (14z-62e: splash P1/P2 and the win
                # quote are each ONE array, not a +0x80 pair) declare only
                # the keys they have
                if f"vj_{side}" not in sr:
                    continue
                vj_base = _int(sr[f"vj_{side}"])
                vj_row = vj_base + 4 * dst_slot
                vj_alias = vj_base + 4 * (dst_slot & 0x0F)
                exp_alias = _int(sr[f"expect_vj_alias_{side}"])
                vsrc = _u32(src_data, _int(sr[f"vs2_{side}"]) + 4 * _src_char)
                bad = []
                if vj_u32(vj_alias) != exp_alias:
                    bad.append(f"vj base-half row {vj_alias:#x} holds "
                               f"{vj_u32(vj_alias):#x}, expected {exp_alias:#x}")
                if vj_u32(vj_row) != exp_alias:
                    bad.append(f"vj variant row {vj_row:#x} holds "
                               f"{vj_u32(vj_row):#x} — does not alias its "
                               f"base-half counterpart {exp_alias:#x}")
                if vsrc != _int(sr[f"expect_vs2_{side}"]):
                    bad.append(f"vs2 {side} row holds {vsrc:#x}, expected "
                               f"{_int(sr[f'expect_vs2_{side}']):#x}")
                if bad:
                    fail.append(f"select_records {nm}/{side}: vanilla anchors "
                                "moved: " + "; ".join(bad))
                    continue
                if _host_ring:
                    ref_c = _int(sr["ring_ref_cell"])
                    ref_rec = vj_u32(vj_base + 4 * ref_c)
                    ref_fmt = int.from_bytes(vj[ref_rec:ref_rec + 2], "big")
                    if ref_fmt not in (0, 2):
                        fail.append(f"select_records {nm}/{side}: ring ref "
                                    f"row {ref_c:#04x} record {ref_rec:#x} "
                                    f"fmt {ref_fmt:#x} not a record")
                        continue
                    ops.append({"op": "poke32", "addr": f"{vj_row:#x}",
                                "val": f"{ref_rec:#x}"})
                    notes.append(f"poke32 {vj_row:#08x} <- {ref_rec:#x}  "
                                 f"select_records {nm}/{side} array row "
                                 f"{dst_slot:#04x} = the HOST row "
                                 f"{ref_c:#04x} ring record VERBATIM "
                                 f"(host_ring; was {exp_alias:#x})")
                    continue
                fmt, bud, cm1 = struct.unpack(">HHH", src_data[vsrc:vsrc + 6])
                cnt = cm1 + 1
                cptr = _u32(src_data, vsrc + 6)
                ents = [(_u16(src_data, vsrc + 10 + 4 * k),
                         _u16(src_data, vsrc + 12 + 4 * k)) for k in range(cnt)]
                new_ents, holders = [], []
                for t, at in ents:
                    bx = ((at >> 8) & 15) + 1
                    by = ((at >> 12) & 15) + 1
                    if _native:
                        new_ents.append((t, at))
                        for dy in range(by):
                            for dx in range(bx):
                                sel_bank5.add((t & ~0xF) + (dy << 4)
                                              + ((t + dx) & 0xF))
                        continue
                    anchor = _selp.PLACEMENTS.get((t, bx, by))
                    if anchor is None:
                        if not sr.get("allow_placeholder_tiles", False):
                            fail.append(
                                f"select_records {nm}/{side}: no placement "
                                f"for block (0x{t:04X},{bx},{by}) and "
                                f"placeholders not allowed for this piece")
                        holders.append(t)
                        new_ents.append((t, at))
                        continue
                    new_ents.append((anchor, at))
                    for dy in range(by):
                        for dx in range(bx):
                            s = (t & ~0xF) + (dy << 4) + ((t + dx) & 0xF)
                            d = (anchor & ~0xF) + (dy << 4) + ((anchor + dx) & 0xF)
                            if sel_pairs.get(s, d) != d:
                                fail.append(f"select_records {nm}/{side}: "
                                            f"conflicting placement for tile "
                                            f"0x{s:04X}")
                            sel_pairs[s] = d
                cl = src_data[cptr:cptr + 4 * cnt]
                cl_dst = alloc(sr.get("hole", "a"), len(cl),
                               f"select_records {nm}/{side} coords")
                if cl_dst is None:
                    continue
                body = struct.pack(">HHH", fmt, bud, cnt - 1)
                body += cl_dst.to_bytes(4, "big")
                for t, at in new_ents:
                    body += struct.pack(">HH", t, at)
                rec_dst = alloc(sr.get("hole", "a"), len(body),
                                f"select_records {nm}/{side} record")
                if rec_dst is None:
                    continue
                ops.append({"op": "data", "addr": f"{cl_dst:#x}",
                            "hex": cl.hex()})
                ops.append({"op": "data", "addr": f"{rec_dst:#x}",
                            "hex": body.hex()})
                ops.append({"op": "poke32", "addr": f"{vj_row:#x}",
                            "val": f"{rec_dst:#x}"})
                ph = ("" if not holders else
                      ", PLACEHOLDER tile code(s) "
                      + "/".join(f"0x{t:04X}" for t in holders)
                      + " — unplaced until the gfx half")
                notes.append(f"data   {cl_dst:#08x} +{len(cl):#x}  "
                             f"select_records {nm}/{side} coord list "
                             f"({cnt} pairs, vs2 {cptr:#x})")
                notes.append(f"data   {rec_dst:#08x} +{len(body):#x}  "
                             f"select_records {nm}/{side} record (vs2 "
                             f"{vsrc:#x}, {cnt} entries, budget {bud:#x} = "
                             f"vs2's own{ph})")
                notes.append(f"poke32 {vj_row:#08x} <- {rec_dst:#x}  "
                             f"select_records {nm}/{side} array row "
                             f"{dst_slot:#04x} (was {exp_alias:#x}, the "
                             f"base-half alias)")
                fragments.append((cl_dst, len(cl), "VS2",
                                  f"select_records {nm}/{side} coord list"))
                fragments.append((rec_dst, len(body), "VS2",
                                  f"select_records {nm}/{side} record"))
        _pairs = sorted([s, d] for s, d in sel_pairs.items())
        (out / "select_tiles.json").write_text(json.dumps(_pairs))
        notes.append(f"# select_records: {len(_pairs)} bank-1 tile placements "
                     f"-> select_tiles.json (only the composed records' art; "
                     f"the slot-0x0F splash/win-quote families are NOT "
                     f"placed, so that Jedah art stays vanilla)")
        (out / "select_bank5.json").write_text(
            json.dumps(sorted(sel_bank5)))
        notes.append(f"# select_records: {len(sel_bank5)} native bank-1 "
                     f"tiles -> select_bank5.json (copied vs2 -> group C "
                     f"bank 5 by build_gfx; the drawer's bank is thunk-"
                     f"gated per hover)")

    # ── win_pal_variant (14z-63, phase 3 item 5): the tenant's win-screen
    # palette at a variant id. The sparse-block design: a block laid out
    # with the VANILLA pool's color stride, only the tenant's sets
    # populated, and a thunk at the pool-base load that rebases
    # a0 = block - TT*unit when the winner is the tenant — the vanilla
    # (color*17 + id)*unit arithmetic then lands each color on the
    # tenant's set. Variant-id builds only; the 0x0F track keeps its
    # in-place slice replacement (win_pal_slot0f_c0..c7).
    if args.stage >= 6 and dst_slot >= 0x10:
        for wp in port.get("win_pal_variant", []):
            if args.stage < _int(wp.get("stage", 0)):
                continue
            nm = wp["name"]
            site = _int(wp["site"])
            old = bytes.fromhex(wp["site_old"])
            opc_wp = (root / "build/out/vsavj_opcodes.bin").read_bytes()
            if opc_wp[site:site + 6] != old:
                fail.append(f"win_pal_variant {nm}: site {site:#x} holds "
                            f"{opc_wp[site:site+6].hex()}, expected "
                            f"{old.hex()}")
                continue
            pool = _int(wp["pool_base"])
            if old[2:6] != pool.to_bytes(4, "big"):
                fail.append(f"win_pal_variant {nm}: site_old operand != "
                            f"pool_base {pool:#x}")
                continue
            cstride = _int(wp["pool_color_stride"])
            unit = _int(wp["unit"])
            ncol = _int(wp["colors"])
            vsrc = _int(wp["vs2_src"])
            vstride = _int(wp["vs2_color_stride"])
            src_data = (root / f"build/out/{man['src_set']}_data.bin"
                        ).read_bytes()
            blk_len = (ncol - 1) * cstride + unit
            blk = alloc(wp.get("hole", "a"), blk_len,
                        f"win_pal_variant {nm} sparse block")
            if blk is None:
                continue
            for c in range(ncol):
                sl = src_data[vsrc + c * vstride:vsrc + c * vstride + unit]
                if len(sl) != unit:
                    fail.append(f"win_pal_variant {nm}: vs2 slice {c} "
                                f"read short")
                    break
                ops.append({"op": "data",
                            "addr": f"{blk + c * cstride:#x}",
                            "hex": sl.hex()})
            else:
                # thunk: cmpi.b #TT,d6 / bne.b vanilla / movea.l #rebase,a0
                # / rts / vanilla: movea.l #pool,a0 / rts.  d6 holds the
                # winner id at the site; movea sets no flags and the
                # fall-through (moveq #0,d0) defines its own, so the
                # thunk's CCR clobber is safe.
                rebase = blk - dst_slot * unit
                body = (f"0c06{dst_slot:04x}"      # cmpi.b #TT,d6
                        f"6608"                    # bne.b +8 -> vanilla
                        f"207c{rebase:08x}"        # movea.l #rebase,a0
                        f"4e75"                    # rts
                        f"207c{pool:08x}"          # movea.l #pool,a0
                        f"4e75")                   # rts
                tk = alloc("a", len(body) // 2,
                           f"win_pal_variant {nm} thunk")
                if tk is None:
                    continue
                ops.append({"op": "code", "addr": f"{tk:#x}", "hex": body})
                ops.append({"op": "code", "addr": f"{site:#x}",
                            "hex": f"4eb9{tk:08x}"})
                notes.append(f"data   {blk:#08x} +{blk_len:#x}  "
                             f"win_pal_variant {nm}: sparse block, "
                             f"{ncol} sets of {unit:#x} at stride "
                             f"{cstride:#x} (vs2 {vsrc:#x} "
                             f"stride {vstride:#x})")
                notes.append(f"code   {tk:#08x} +{len(body)//2:#x}  "
                             f"win_pal_variant {nm} thunk (d6==TT -> "
                             f"a0 = {rebase:#x}; else vanilla pool "
                             f"{pool:#x})")
                notes.append(f"code   {site:#08x} +6     win_pal_variant "
                             f"{nm}: movea.l #pool -> jsr {tk:#x}")
                fragments.append((blk, blk_len, "VS2",
                                  f"win_pal_variant {nm} sparse block"))
                fragments.append((tk, len(body) // 2, "NEW",
                                  f"win_pal_variant {nm} thunk"))

    # ── site_thunk: generic 6-byte engine-site -> jsr thunk (14q pattern) ───
    # The thunk body is authored hex (must preserve the displaced
    # instruction's semantics on its vanilla path, including flags where
    # the fall-through consumes them). Old bytes verified against the
    # vanilla opcode image; thunk placed in hole "a"; site patched to
    # jsr thunk (6 bytes, code-op so it re-encrypts).
    # 14z-66: the block gate dropped from 6 to 4 (the shadow-seq guard is
    # a stage-4 behavior thunk) with the per-row DEFAULT stage raised to 6
    # — every pre-existing row declares stage explicitly (6 or 99), so
    # emission is unchanged for them at every stage (m3a gate verifies).
    # patch = "jmp" emits a stack-neutral jmp instead of jsr, for sites
    # whose displaced instruction is itself a jmp (the thunk must then end
    # by continuing the flow, never rts).
    if args.stage >= 4:
        opc_img_st = None
        for st in port.get("site_thunk", []):
            if args.stage < _int(st.get("stage", 6)):
                continue
            nm = st["name"]
            # only_variant_slot (14z-62e): a thunk that exists only for the
            # de-substituted tenant (e.g. the select-palette redirect, whose
            # block lives in profile-gated space). Skipped at base-half
            # slots, where the in-place mechanisms serve.
            if st.get("only_variant_slot") and dst_slot < 0x10:
                notes.append(f"# site_thunk {nm}: SKIPPED (variant-id-only; "
                             f"tenant is at {dst_slot:#04x})")
                continue
            site = _int(st["site"])
            old = bytes.fromhex(st["old_hex"])
            if len(old) != 6:
                fail.append(f"site_thunk {nm}: displaced site must be 6 bytes")
                continue
            if opc_img_st is None:
                opc_img_st = (root / "build/out/vsavj_opcodes.bin").read_bytes()
            if opc_img_st[site:site + 6] != old:
                fail.append(f"site_thunk {nm}: vanilla bytes at {site:#x} != "
                            f"old_hex ({opc_img_st[site:site+6].hex()})")
                continue
            # A site_thunk's body is HAND-AUTHORED machine code, and some of
            # it compares against the tenant's character id
            # (`cmpi.b #<id>,$FF8782` / `$FF8B82`). That id was written as a
            # literal byte inside the hex string, where a tenant move would
            # be silently wrong rather than loud: the thunk would keep
            # gating on 0x0F, so the tenant would take the vanilla path and
            # the OLD occupant of 0x0F would take the ported one, with
            # nothing to crash.
            #
            # `TT` in the hex is substituted with the tenant id and tracks it
            # forever. A stale LITERAL is a hard failure rather than an
            # automatic rewrite — silently editing authored code could mask a
            # thunk that compares against some other character on purpose.
            _hx = st["thunk_hex"].lower()
            _tid = _int(port["port"]["dst_slot"]) & 0xFF
            # TU (14z-62j): the tenant id under the WIN-QUOTE consumer bias
            # (+0x40 rows — the shared consumer at 0x5F328 receives d0
            # pre-biased per piece). Replaced before TT ("tu" contains no
            # "tt").
            _hx = _hx.replace("tu", "%02x" % ((_tid + 0x40) & 0xFF))
            _hx = _hx.replace("tt", "%02x" % _tid)
            # row_subst (14z-62c): a thunk body may embed the ADDRESS of a
            # per-char table row (e.g. the accent thunks read the sprite
            # palette table's tenant row). Hardcoding it froze row 0x0F into
            # the body exactly like the id literal did. The manifest names a
            # non-hex placeholder and the table base; the substituted value
            # is base + 4*tenant, so the body tracks the tenant forever.
            for _kv in str(st.get("row_subst", "")).split(","):
                if not _kv.strip():
                    continue
                _ph, _, _tb = _kv.partition("=")
                _ph = _ph.strip().lower()
                if _ph not in _hx:
                    fail.append(f"site_thunk {st['name']}: row_subst "
                                f"placeholder '{_ph}' not present in "
                                f"thunk_hex")
                _hx = _hx.replace(
                    _ph, "%08x" % (_int(_tb.strip()) + 4 * _tid))
            # region_subst (14z-66): "placeholder=region:offset" — the thunk
            # embeds the PLACED address of an extracted region (+offset),
            # e.g. the tenant_jump_seq thunk aims the clone's sub-state
            # table. Resolved from the placement map, so the body tracks
            # wherever the allocator puts the region.
            for _kv in str(st.get("region_subst", "")).split(","):
                if not _kv.strip():
                    continue
                _ph, _, _spec = _kv.partition("=")
                _ph = _ph.strip().lower()
                _rn, _, _ro = _spec.strip().partition(":")
                if _rn not in placed:
                    fail.append(f"site_thunk {st['name']}: region_subst "
                                f"region '{_rn}' not placed at this stage")
                    continue
                if _ph not in _hx:
                    fail.append(f"site_thunk {st['name']}: region_subst "
                                f"placeholder '{_ph}' not present in "
                                f"thunk_hex")
                _hx = _hx.replace(
                    _ph, "%08x" % (placed[_rn] + _int(_ro or "0")))
            # data_subst (14z-62e): "placeholder=src:len:hole" — the thunk
            # embeds the address of a SOURCE-SET data block; the generator
            # reads it, places it via the space model, emits the data op,
            # and substitutes the allocated address into the body.
            # GATHER form (14z-67): "placeholder=src:len:hole:xN@STRIDE" —
            # N chunks of len bytes at STRIDE intervals, concatenated into
            # one contiguous placed block (a strided GRID COLUMN, e.g.
            # Huitzil's select-portrait palette rows: the vs2 uploader
            # remaps him INTO the grid at column 0x0B rather than giving
            # him a dedicated block like Donovan's).
            for _kv in str(st.get("data_subst", "")).split(","):
                if not _kv.strip():
                    continue
                _ph, _, _spec = _kv.partition("=")
                _ph = _ph.strip().lower()
                _parts = _spec.strip().split(":")
                _srcs, _lens, _hole = _parts[0], _parts[1], _parts[2]
                _dsrc, _dlen = _int(_srcs), _int(_lens)
                _sdat = (root / f"build/out/{man['src_set']}_data.bin"
                         ).read_bytes()
                if len(_parts) > 3 and _parts[3].startswith("x"):
                    _n, _stride = _parts[3][1:].split("@")
                    _n, _stride = int(_n, 0), int(_stride, 0)
                    _blob = b"".join(
                        _sdat[_dsrc + _k * _stride:
                              _dsrc + _k * _stride + _dlen]
                        for _k in range(_n))
                    _dlen = _dlen * _n
                else:
                    _blob = _sdat[_dsrc:_dsrc + _dlen]
                if len(_blob) != _dlen:
                    fail.append(f"site_thunk {st['name']}: data_subst src "
                                f"read short")
                    continue
                _da = alloc(_hole, _dlen,
                            f"site_thunk {st['name']} data block")
                if _da is None:
                    continue
                ops.append({"op": "data", "addr": f"{_da:#x}",
                            "hex": _blob.hex()})
                notes.append(f"data   {_da:#08x} +{_dlen:#x}  site_thunk "
                             f"{st['name']} data block <- {man['src_set']} "
                             f"{_dsrc:#08x}")
                fragments.append((_da, _dlen, "VS2",
                                  f"site_thunk {st['name']} data block"))
                if _ph not in _hx:
                    fail.append(f"site_thunk {st['name']}: data_subst "
                                f"placeholder '{_ph}' not present in "
                                f"thunk_hex")
                _hx = _hx.replace(_ph, "%08x" % _da)
            for _fld in ("00ff8782", "00ff8b82"):
                _i = 0
                while True:
                    _i = _hx.find("0c3900", _i)
                    if _i < 0:
                        break
                    if _hx[_i + 8:_i + 16] == _fld:
                        _got = int(_hx[_i + 6:_i + 8], 16)
                        if _got != _tid:
                            fail.append(
                                f"site_thunk {st['name']}: body compares the "
                                f"char id against {_got:#04x} at hex offset "
                                f"{_i + 6}, but the tenant is {_tid:#04x}. "
                                f"Write 'TT' there so it tracks the tenant.")
                    _i += 6
            # The same trap in ADDRESS-REGISTER-RELATIVE form (14z-62c —
            # this is how four accent thunks and the companion/LS thunks
            # kept gating on 0x0F after the tenant moved: the original
            # guard only knew the absolute `cmpi.b #id,$FF8x82.l` shape).
            # cmpi.b #imm,(d16,An) = 0C28+n; the id lives at displacement
            # $382 (the char-id field) or $A (the select keeper's cached
            # owner id). Word-aligned scan; a mismatch is a hard failure.
            import re as _re
            # id_literal_ok (14z-66): ids a thunk COMPARES ON PURPOSE that
            # are not the tenant — e.g. a displaced VANILLA id test the
            # thunk re-executes verbatim (the tenant_jump_seq thunk
            # re-runs the engine's own Anakaris cmpi). Listed explicitly
            # so the stale-literal guard stays loud for everything else.
            _ok_ids = {_int(x) for x in
                       str(st.get("id_literal_ok", "")).split(",") if x.strip()}
            for _m in _re.finditer(r"0c2[89abcdef]00([0-9a-f]{2})(0382|000a)",
                                   _hx):
                if _m.start() % 4:
                    continue        # not instruction-aligned — embedded data
                _got = int(_m.group(1), 16)
                if _got in _ok_ids:
                    continue
                if _got != _tid:
                    fail.append(
                        f"site_thunk {st['name']}: body compares a char/owner "
                        f"id field against {_got:#04x} at hex offset "
                        f"{_m.start() + 6} (An-relative form), but the tenant "
                        f"is {_tid:#04x}. Write 'TT' there so it tracks the "
                        f"tenant.")
            body = bytes.fromhex(_hx)
            # hole "b" is REQUIRED for thunks carrying embedded data read
            # via data loads: hole "a" lies inside the CPS-2 crypt range,
            # where placed bytes are stored re-encrypted for opcode
            # fetches — data reads bypass decryption and see ciphertext
            # (14z-20, paid for; docs/GOTCHAS.md).
            hole_sel = st.get("hole", "a")
            td = alloc(hole_sel, len(body), f"site_thunk {nm}")
            if td is None:
                fail.append(f"site_thunk {nm}: no room in hole {hole_sel}")
                continue
            patch_kind = st.get("patch", "jsr")
            # rts_ok (14z-71): the site is the head of a CALLED HANDLER, not a
            # point in a fall-through flow — the engine reaches it through a
            # dispatch and every sibling handler exits by `rts`. There, `rts`
            # is the CORRECT exit and jmp_ok's assertion ("the body never
            # rts's") is simply the wrong claim to make; asserting it would
            # be a lie in the manifest. A separate flag keeps jmp_ok's meaning
            # intact and states this site's actual contract: the body may rts,
            # and any path that declines the work must re-enter the displaced
            # original by jmp.
            if (patch_kind == "jmp"
                    and not st["old_hex"].lower().startswith("4ef9")
                    and not st.get("jmp_ok") and not st.get("rts_ok")):
                fail.append(f"site_thunk {nm}: patch='jmp' over a non-jmp "
                            f"site (old_hex starts {st['old_hex'][:4]}) — "
                            f"set jmp_ok = true to assert the thunk body "
                            f"NEVER rts's or falls through (it must re-enter "
                            f"the original flow by jmp only), or rts_ok = true "
                            f"if the site is a CALLED HANDLER whose siblings "
                            f"all exit by rts")
                continue
            ops.append({"op": "code", "addr": f"{td:#x}", "hex": body.hex()})
            ops.append({"op": "code", "addr": f"{site:#x}",
                        "hex": ("4ef9" if patch_kind == "jmp" else "4eb9")
                        + f"{td:08x}"})
            notes.append(f"code   {td:#08x} +{len(body):#x}  site_thunk {nm}; "
                         f"site {site:#08x} {patch_kind}-routed")
            fragments.append((td, len(body), "GEN", f"site_thunk {nm}"))
            fragments.append((site, 6, "GEN", f"site_thunk {nm} engine site"))

    # ── code_word: guarded single-word code patch (session 14z-22) ─────────
    # For data-in-code words a 6-byte site_thunk cannot touch without
    # clobbering neighbors (jump-table entries, embedded constants).
    # old_hex verified against the vanilla opcode image; emitted as a
    # code op so crypt-range re-encryption applies.
    if args.stage >= 6:
        opc_img_cw = None
        for cw in port.get("code_word", []):
            if args.stage < _int(cw.get("stage", 0)):
                continue
            nm = cw["name"]
            old = bytes.fromhex(cw["old_hex"])
            # new_hex_variant (14z-62d): value differs by where the tenant
            # lives (e.g. the OBJ bank word: host band vs WIDE group C).
            _nh = cw["new_hex"]
            if dst_slot >= 0x10 and "new_hex_variant" in cw:
                _nh = cw["new_hex_variant"]
            new = bytes.fromhex(_nh)
            if len(old) != 2 or len(new) != 2:
                fail.append(f"code_word {nm}: old/new must be exactly 2 bytes")
                continue
            if opc_img_cw is None:
                opc_img_cw = (root / "build/out/vsavj_opcodes.bin").read_bytes()
            # slot_table/slot_stride/slot_off (14z-62c): the word is a
            # per-char TABLE ENTRY and follows the tenant. `slot_mirror`
            # additionally pokes the 0x1F twin on base-half builds (the
            # mirror-variant doctrine); a variant-id tenant has no mirror.
            # old_hex documents the BASE-HALF slot's vanilla word; a
            # variant entry is anchored on being a vanilla alias of its
            # base-half counterpart instead.
            if "slot_table" in cw:
                stb = _int(cw["slot_table"])
                sst = _int(cw.get("slot_stride", 4))
                sof = _int(cw.get("slot_off", 0))
                addr = stb + sst * dst_slot + sof
                if dst_slot >= 0x10:
                    alias = stb + sst * (dst_slot & 0x0F) + sof
                    if opc_img_cw[addr:addr + 2] != opc_img_cw[alias:alias + 2]:
                        fail.append(f"code_word {nm}: variant entry at "
                                    f"{addr:#x} does not alias its base-half "
                                    f"counterpart — table shape moved")
                        continue
                elif opc_img_cw[addr:addr + 2] != old:
                    fail.append(f"code_word {nm}: vanilla bytes at {addr:#x} "
                                f"!= old_hex ({opc_img_cw[addr:addr+2].hex()})")
                    continue
                targets = [addr]
                if cw.get("slot_mirror") and dst_slot < 0x10:
                    targets.append(stb + sst * (dst_slot | 0x10) + sof)
                for a2 in targets:
                    ops.append({"op": "code", "addr": f"{a2:#x}",
                                "hex": new.hex()})
                    notes.append(f"code   {a2:#08x} +0x2  code_word {nm} "
                                 f"(slot entry {'mirror ' if a2 != addr else ''}"
                                 f"-> {new.hex()})")
                    fragments.append((a2, 2, "GEN", f"code_word {nm}"))
                continue
            addr = _int(cw["addr"])
            if opc_img_cw[addr:addr + 2] != old:
                fail.append(f"code_word {nm}: vanilla bytes at {addr:#x} != "
                            f"old_hex ({opc_img_cw[addr:addr+2].hex()})")
                continue
            ops.append({"op": "code", "addr": f"{addr:#x}", "hex": new.hex()})
            notes.append(f"code   {addr:#08x} +0x2  code_word {nm} "
                         f"({old.hex()} -> {new.hex()})")
            fragments.append((addr, 2, "GEN", f"code_word {nm}"))

    # ── code_ptr: a guarded single-LONG code patch aimed at a PLACED region
    # (14z-71, the beam port) ─────────────────────────────────────────────
    # The engine's per-pool effect-CLASS tables are rows of absolute handler
    # pointers, indexed by an object field and read PC-relatively — i.e.
    # through the OPCODES space, inside the crypt window — so they are
    # patched with a `code` op, never poke32.
    #
    # vsav ships several of those rows as STUBS pointing at the bare `rts`
    # that follows the table, where vs2/vh2 carry a real handler. This row
    # hands one such dead row a ported handler, which is a strictly smaller
    # change than an obj_hook table rebuild: no relocated table, no engine
    # site patch, and no cycle cost on any legacy path.
    #
    # Superset safety rests on the row being DEAD, measured rather than
    # argued (tests/audit_effect_class_rows.sh), plus old_hex pinning the
    # slot to the stub so a table that ever moves fails the build loudly
    # instead of silently patching someone else's row.
    if args.stage >= 4:
        opc_img_cp = None
        for cp in port.get("code_ptr", []):
            if args.stage < _int(cp.get("stage", 4)):
                continue
            nm = cp["name"]
            addr = _int(cp["addr"])
            old = bytes.fromhex(cp["old_hex"])
            if len(old) != 4:
                fail.append(f"code_ptr {nm}: old_hex must be exactly 4 bytes")
                continue
            if opc_img_cp is None:
                opc_img_cp = (root / "build/out/vsavj_opcodes.bin").read_bytes()
            if opc_img_cp[addr:addr + 4] != old:
                fail.append(f"code_ptr {nm}: vanilla bytes at {addr:#x} != "
                            f"old_hex ({opc_img_cp[addr:addr + 4].hex()})")
                continue
            _rn, _, _ro = str(cp["region"]).partition(":")
            if _rn not in placed:
                fail.append(f"code_ptr {nm}: region '{_rn}' not placed at "
                            f"this stage")
                continue
            val = placed[_rn] + _int(_ro or "0")
            ops.append({"op": "code", "addr": f"{addr:#x}",
                        "hex": f"{val:08x}"})
            notes.append(f"code   {addr:#08x} +0x4  code_ptr {nm} "
                         f"({old.hex()} -> {val:08x} = {_rn}"
                         f"+{_int(_ro or '0'):#x})")
            fragments.append((addr, 4, "GEN", f"code_ptr {nm}"))

    # ── win/quote palette 0x60-view repoint (session 14u) ─────────────────────
    # Companion to select_port's block copies: the hardcoded
    # `lea 0x39FDC0,a0` at CODE:0x1C424 (the char*0x60-view win-screen
    # uploader) must read copy B at 0x24C3C0. Code space — the imm is
    # re-encrypted by patch_prg's code op. Slot-0x0F-only visual
    # surface; the masked gate arbitrates.
    WINPAL_ENABLE = False   # 14z: copies convicted of the throw
                            # victim-teleport (see select_port note)
    if args.stage >= 6 and WINPAL_ENABLE:
        ops.append({"op": "code", "addr": "0x1c426", "hex": "0024c3c0"})
        notes.append("# winpal: 0x1C424 lea imm -> copy B 0x24C3C0")
        # quote-time side-table reader -> the private table. Site
        # attribution is PATH-DEPENDENT and was settled by per-site
        # gate bisection (session 14u): 0x1BF56 preloads at normal
        # select entry, 0x1C5CE on the 2P/VS select path, 0x7D4FC on
        # the challenger-join path — all three stage block bytes
        # through work RAM on LEGACY replays and must keep the vanilla
        # table. Only 0x1C1FA is exclusively quote-time.
        # 14y: 0x1BF56 added — re-reading its code shows it copies
        # DIRECTLY to palette RAM 0x90C2C0 (no work-RAM staging; the
        # "bulk preloader" attribution was wrong for THIS site — only
        # 0x1C5CE/0x7D4FC stage through work RAM). It is the select/HUD
        # portrait-row uploader (side table + char*0xA0) and likely the
        # quote-screen path as well. Legacy chars read copy bytes
        # identical to vanilla; the masked battery arbitrates.
        # 0x1BF56 ACTIVE (maintainer sign-off, session 14y round 22):
        # the select/HUD palette-row uploader reads the patched copies —
        # fixes HUD mini-portrait, select portraits and the quote
        # palette family. Cost accepted: one spawn-boundary flicker
        # frame (@829, the approved mechanism class) on 02/05/07,
        # reclassified masked-EXACT -> masked-FLICKER; revert-and-
        # rethink if playtest shows problems (maintainer's terms).
        for site in ((0x1C1FA, 0x1BF56) if WINPAL_ENABLE else ()):
            ops.append({"op": "code", "addr": f"{site + 2:#x}",
                        "hex": "0024de00"})
        notes.append("# winpal: 3 quote-site table imms -> 0x24DE00")

    # ── M2b stage 7 (session 14q): companion-overlay zone port ────────────────
    # build/manifest/overlay/ is generated by tools/overlay_port.py from
    # pristine vs2 + the vsavj opcode dump (topology B, STATE 14q): the
    # relocated vs2 overlay zone slice lands in Jedah's strip area and
    # his per-char code immediates are repointed (code ops re-encrypt).
    ovdir = Path(__file__).resolve().parent.parent / "build/manifest/overlay"
    if args.stage >= 6 and (ovdir / "overlay_patch.json").exists():
        ovm = json.loads((ovdir / "overlay_patch.json").read_text())
        for seg in ovm["segments"]:
            blob = (ovdir / seg["path"]).read_bytes()
            assert len(blob) == seg["len"], f"overlay {seg['path']} length"
            (out / seg["path"]).write_bytes(blob)
            pa = int(seg["at"], 16)
            ops.append({"op": "data_file", "addr": f"{pa:#x}",
                        "path": seg["path"]})
            fragments.append((pa, len(blob), "VS2",
                              f"companion-overlay zone {seg['path']} "
                              f"(vs2 0x2A0426 split, topology B)"))
        # T-site pokes are CONDITIONAL: the same Jedah display sites run
        # in the attract INTRO CUTSCENE (legacy-exact, pre-4278) and for
        # the in-match overlay (Donovan). Each site's `movea.l #T,a0`
        # (6 bytes) becomes `jsr thunk` (6 bytes); the thunk selects the
        # vanilla or ported table on the documented match-active check
        # $FF8004.l == 0x40000 (docs/game/atlas/ram.md; the attract DEMO is
        # in-match => ported, the cutscene is not => vanilla). CCR note:
        # every jump target (the strip walkers) starts with a d0 mask,
        # so the thunk's flag clobber is dead on all paths.
        pairs_seen = {}
        thunk = bytearray()
        for pk in ovm["pokes"]:
            key = (pk["old"], pk["new"])
            if key not in pairs_seen:
                pairs_seen[key] = len(thunk)
                # a0 = vanilla T; take the ported T only when a match is
                # ACTIVE ($FF8004.l == 0x40000) and a slot-0x0F player is
                # in it ($FF8782/$FF8B82 char id) — shared display code
                # runs these sites for every character (the Demitri-match
                # hang, session 14q); legacy matches must walk the
                # vanilla tables byte-exactly.
                thunk += bytes.fromhex("207c") + \
                    int(pk["old"], 16).to_bytes(4, "big")
                thunk += bytes.fromhex("0cb90004000000ff8004")   # match?
                thunk += bytes.fromhex("661a")                    # no -> rts
                # cmpi.b #<tenant id>,$FF8782 / $FF8B82. The id was hardcoded
                # as 000f here, INSIDE hand-authored machine code — the one
                # place a tenant move would be silently wrong rather than
                # loud: the thunk would gate on 0x0F, so the tenant would get
                # the VANILLA tables and Jedah would get the ported ones, with
                # nothing to crash. Built from the tenant id instead.
                _tid8 = "%02x" % (_int(port["port"]["dst_slot"]) & 0xFF)
                thunk += bytes.fromhex("0c3900" + _tid8 + "00ff8782")
                thunk += bytes.fromhex("670a")                    # yes -> ported
                thunk += bytes.fromhex("0c3900" + _tid8 + "00ff8b82")
                thunk += bytes.fromhex("6606")                    # no -> rts
                thunk += bytes.fromhex("207c") + \
                    int(pk["new"], 16).to_bytes(4, "big")
                thunk += bytes.fromhex("4e75")
        ta = alloc("a", len(thunk), "overlay T-select thunks")
        if ta is not None:
            (out / "overlay_thunks.bin").write_bytes(bytes(thunk))
            ops.append({"op": "code_file", "addr": f"{ta:#x}",
                        "path": "overlay_thunks.bin"})
            fragments.append((ta, len(thunk), "GEN",
                              "overlay T-select thunks (match-flag cond)"))
            for pk in ovm["pokes"]:
                taddr = ta + pairs_seen[(pk["old"], pk["new"])]
                # site addr = the 4-byte immediate; the opcode word 207C
                # sits 2 bytes before — rewrite the full 6-byte insn
                ops.append({"op": "code", "addr": f"{pk['addr'] - 2:#x}",
                            "hex": "4eb9" + f"{taddr:08x}"})
        notes.append(f"# overlay: {len(ovm['segments'])} zone segments + "
                     f"{len(ovm['pokes'])} T-sites thunked "
                     f"({len(pairs_seen)} thunks at {ta:#x})")

    # ── emit ─────────────────────────────────────────────────────────────────
    placements = {name: {"dst": placed[name],
                         "src": man["regions"][name]["src"],
                         "len": man["regions"][name]["len"]}
                  for name in placed}
    (out / "placements.json").write_text(json.dumps(
        {"stage": args.stage, "regions": placements}, indent=1))
    # ── tenant.json: the id the GFX half must agree with ────────────────────
    # build_gfx_donovan.py and verify_gfx_build.py used to hard-code slot
    # 0x0F ("Jedah's bank"), so they were silently independent of the port's
    # target — a build with the tenant moved elsewhere still placed bank
    # table row 0x0F. Emitting the tenant here makes one manifest row drive
    # BOTH halves, and lets the gfx verifier assert against the same id the
    # program half used rather than a constant.
    _tp = port.get("port", {})
    (out / "tenant.json").write_text(json.dumps(
        {"name": _tp.get("name", "donovan"),
         "id": _int(_tp["dst_slot"]),
         "mirror_variant": bool(_tp.get("mirror_variant", False)),
         "src_set": _tp.get("src_set"),
         "src_char": _int(_tp["src_char"]) if "src_char" in _tp else None,
         "gfx_bank": _int(_tp["gfx_bank"]) if "gfx_bank" in _tp else 2},
        indent=1))
    # ── program-image extension (Phase C step 2) ─────────────────────────────
    # If any op lands beyond the base 4MB image, the patcher must GROW the
    # image and emit the appended ROM members. The generator is what knows the
    # profile, so it states the requirement here rather than patch_prg.py
    # re-deriving it. Emitted only when a profile space was actually used, so
    # a WIDE build that happens to need no extension stays byte-identical to
    # the stock one.
    for _n, _v2, _vj in unstubbed:
        notes.append(f"# M5: sfx helper {_v2:#x} UN-STUBBED -> vsavj {_vj:#x} "
                     f"(record array {_n} is placed)")
    ext_spaces = [spaces[n] for n in order
                  if spaces[n]["profile"] and spaces[n]["cur"] > spaces[n]["start"]]
    image = None
    if ext_spaces:
        # Size to the PROFILE's declared extent, not to what we happened to
        # use. The emulator descriptors declare a fixed shape (PRG 6MB as four
        # appended 512KB members) and a romset that carries fewer members
        # simply fails to load. Content decides nothing about image geometry.
        need = max(sp["end"] for sp in ext_spaces)
        msize = 0x80000
        base = len(vj)
        count = -(-(need - base) // msize)        # ceil
        image = {"extend_to": base + count * msize,
                 "member_size": msize,
                 # Names and sizes MUST match the vsavjw descriptors in BOTH
                 # emulator patches; one romset feeds both.
                 "member_names": [f"vsw.{41 + i}" for i in range(count)],
                 # 0xFF, so the allocator's "dest must be 0xFF fill" check
                 # holds for extension space exactly as it does for the holes.
                 "fill": 0xFF,
                 "profile": args.profile}
        notes.append(f"# image: extend to {image['extend_to']:#x} "
                     f"({count} x {msize:#x} member(s): "
                     f"{', '.join(image['member_names'])})")
    spec = {"ops": ops}
    if image:
        spec["image"] = image
    (out / "patch.json").write_text(json.dumps(spec, indent=1))
    (out / "patch_notes_fragment.md").write_text(
        f"# donovan-m2 stage {args.stage} — generated op notes\n\n"
        + "\n".join(notes) + "\n")
    (out / "atlas_fragment.md").write_text(
        "| dest | len | provenance | what |\n|---|---|---|---|\n"
        + "\n".join(f"| `PRG:0x{d:06X}` | 0x{ln:X} | {pv} | {w} |"
                    for d, ln, pv, w in fragments) + "\n")
    print(f"stage {args.stage}: {len(ops)} ops, "
          + ", ".join(f"{sp['name']} 0x{sp['cur']:06X}/0x{sp['end']:06X} "
                      f"(free 0x{max(0, sp['end'] - sp['cur']):X})"
                      for sp in (spaces[n] for n in order)))
    if fail:
        print(f"\nGENERATION FAILED ({len(fail)}):")
        seen = set()
        for f in fail:
            if f not in seen:
                print(f"  {f}")
                seen.add(f)
        sys.exit(1)
    print("GENERATION OK")


if __name__ == "__main__":
    main()
