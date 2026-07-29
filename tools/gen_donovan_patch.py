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
    bank = load_bank_map(args.bank_map)
    vj = load_vsavj(args.vsavj)
    recon = {}
    if args.recon.is_file():
        for m in toml_loads(args.recon.read_text()).get("map", []):
            recon[_int(m["vsav2"])] = m

    dst_slot = _int(port["port"]["dst_slot"])
    var_slot = dst_slot | 0x10
    mirror = port["port"].get("mirror_variant", True)
    holes = {"a": [_int(port["hole_a"]["start"]), _int(port["hole_a"]["end"])],
             "b": [_int(port["hole_b"]["start"]), _int(port["hole_b"]["end"])]}

    ops = []
    notes = []
    fail = []
    fragments = []  # (dst, len, provenance, what) for the atlas fragment

    def vj_u32(addr):
        return int.from_bytes(vj[addr:addr + 4], "big")

    gap_free = []  # (start, end) inside already-claimed group spans

    def alloc(hole, size, what, fallback=True):
        # gap-fit first: reuse dead space inside layout-group spans
        for gi, (gs, ge) in enumerate(gap_free):
            if ge - gs >= size:
                gap_free[gi] = ((gs + size + 0xF) & ~0xF, ge)
                return gs
        start, end = holes[hole]
        if start + size > end:
            if fallback and hole == "a":
                return alloc("b", size, what, fallback=False)
            fail.append(f"hole {hole} overflow allocating 0x{size:X} for {what}")
            return None
        for i in range(start, start + size):
            if vj[i] != 0xFF:
                fail.append(f"dest 0x{i:06X} for {what} is not 0xFF fill")
                return None
        holes[hole][0] = (start + size + 0xF) & ~0xF
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
        repoint("hitbox_base", seeds[0] + delta, "null reloc")
        repoint("hitbox_comp", seeds[1] + delta, "null reloc")

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
                rows = bytes.fromhex(tf["rows_hex"])
                toff = _int(tf["table_off"])
                if len(blob) < r["len"]:
                    blob.extend(b"\x00" * (r["len"] - len(blob)))
                blob[toff:toff + len(rows)] = rows
                notes.append(f"# {name}+{toff:#x}: table_fix {len(rows)} "
                             f"bytes ({tf['note']})")
            for ref in r.get("refs", []):
                if ref["width"] == 16:  # pcrel16: displacement rewrite TBD
                    newt = relocate_target(ref, f"{name}+{ref['off']:#x}")
                    if newt is None:
                        continue
                    fail.append(f"{name}+{ref['off']:#x}: pcrel16 rewrite not "
                                f"implemented (target {ref['target']:#x})")
                    continue
                newt = relocate_target(ref, f"{name}+{ref['off']:#x}")
                if newt is None:
                    continue
                span = ref["width"] // 8
                blob[ref["off"]:ref["off"] + span] = newt.to_bytes(span, "big")
            # ported code carries the source game's char id in immediates —
            # Donovan is 0x13 there, dst_slot here (scan-confirmed sites only)
            for off in r.get("charid_sites", []):
                if blob[off:off + 2] == b"\x00\x13":
                    blob[off:off + 2] = bytes([0x00, dst_slot])
                    notes.append(f"# {name}+{off:#x}: char-id imm 0x13 -> "
                                 f"{dst_slot:#x}")
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
                    fail.append(f"{name}+{ref['off']:#x}: pcrel rewrite "
                                f"out of d16 range ({disp:#x}) — place "
                                f"target slice nearer")
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
                new = bytes.fromhex(pp["new_hex"])
                if not (0 <= off < r["len"]) or blob[off:off + len(old)] != old:
                    fail.append(f"port_patch {pp['note']}: bytes at "
                                f"{name}+{off:#x} != {pp['old_hex']}")
                    continue
                blob[off:off + len(new)] = new
                notes.append(f"# {name}+{off:#x}: port_patch {pp['old_hex']} "
                             f"-> {pp['new_hex']} ({pp['note']})")

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

                # shelf-pack the non-band blocks (code, bx, by) into the
                # tail; blocks never cross the 16-tile row in source
                # (measured), and stay non-crossing at any target column
                eff_lo, eff_hi = _int(gr["eff_lo"]), _int(gr["eff_hi"])
                blocks = {}
                for ent in collected:
                    for toff, hdr_attr in ent:
                        t = int.from_bytes(blob[toff:toff + 2], "big")
                        a = (hdr_attr if hdr_attr is not None else
                             int.from_bytes(blob[toff + 2:toff + 4], "big"))
                        if not (b_lo <= t <= b_hi):
                            bx = ((a >> 8) & 15) + 1
                            by = ((a >> 12) & 15) + 1
                            blocks.setdefault((t, bx, by), None)
                shelf_row = eff_lo >> 4
                shelf_x = 0
                shelf_h = 0
                for key in sorted(blocks,
                                  key=lambda k: (-k[2], -k[1], k[0])):
                    t, bx, by = key
                    if shelf_x + bx > 16:
                        shelf_row += shelf_h
                        shelf_x = 0
                        shelf_h = 0
                    blocks[key] = (shelf_row << 4) + shelf_x
                    shelf_x += bx
                    shelf_h = max(shelf_h, by)
                    if ((shelf_row + shelf_h) << 4) - 1 > eff_hi:
                        fail.append("gfx_remap: effect shelf overflow past "
                                    f"{eff_hi:#x}")
                        break

                n_eff = 0
                for ent in collected:
                    for toff, hdr_attr in ent:
                        t = int.from_bytes(blob[toff:toff + 2], "big")
                        a = (hdr_attr if hdr_attr is not None else
                             int.from_bytes(blob[toff + 2:toff + 4], "big"))
                        if b_lo <= t <= b_hi:
                            blob[toff:toff + 2] = (t + delta).to_bytes(2,
                                                                       "big")
                            n_rw += 1
                        else:
                            bx = ((a >> 8) & 15) + 1
                            by = ((a >> 12) & 15) + 1
                            nt = blocks.get((t, bx, by))
                            if nt is not None:
                                blob[toff:toff + 2] = nt.to_bytes(2, "big")
                                n_eff += 1
                pairs = []
                for (t, bx, by), nt in blocks.items():
                    if nt is None:
                        continue
                    for dy in range(by):
                        for dx in range(bx):
                            pairs.append([(t & ~0xF) + (dy << 4)
                                          + ((t + dx) & 0xF),
                                          (nt & ~0xF) + (dy << 4)
                                          + ((nt + dx) & 0xF)])
                json.dump(pairs, (out / "effect_map.json").open("w"))
                notes.append(f"# {name}: gfx_remap +{delta:#x} on {n_rw} "
                             f"band tile words + {n_eff} effect words "
                             f"({len(blocks)} blocks -> tail "
                             f"0x{eff_lo:04X}+) in {len(seen_rec)} records")

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
                b2_recs = {int(x, 16) for x in et.get("bank2_recs", [])}
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
                    emj = json.loads((out / "effect_map.json").read_text())
                    known = {tuple(p) for p in emj}
                    for p in b2_pairs:
                        if (p[0], p[1]) not in known:
                            emj.append(p)
                            known.add((p[0], p[1]))
                    (out / "effect_map.json").write_text(json.dumps(emj))
                notes.append(f"# {name}: effect_tail — {n_et} bank-1 words, "
                             f"{n_b2} bank-2 words (tail placements), "
                             f"{n_cfix} coord lists matched, {n_cport} "
                             f"ported ({len(extra_lists)}B fragment)")
                if n_et < 100 or (n_cfix + n_cport) < 100:
                    fail.append(f"effect_tail: {n_et} tile words / "
                                f"{n_cfix + n_cport} coord lists — "
                                f"below expectation, walker drifted")
                if n_rw < 10000:
                    fail.append(f"gfx_remap: only {n_rw} tile words rewritten "
                                f"(expected ~14k) — walker or band drifted")
            d = placed[name]
            fixed = out / f"fixed_{name}.bin"
            fixed.write_bytes(bytes(blob))
            op = "code_file" if r["kind"] == "code" else "data_file"
            ops.append({"op": op, "addr": f"{d:#x}", "path": fixed.name})
            notes.append(f"{op:9s} {d:#08x} +{r['len']:#x}  donovan {name} "
                         f"(from vsav2 0x{r['src']:06X})")

        # [palette] (stage-gated): place the character's sprite-palette
        # block (all confirm-button variants) raw in hole B and repoint
        # the engine's per-char palette pointer table row (slot 0x0F —
        # replaced-slot content, superset-clean). Decoded session 14:
        # uploader vsavj 0x1C3FE (vs2 twin 0x1AE6E), table indexed by
        # the pre-scaled char id, 12 rows to palette RAM 0x90C140.
        pal = port.get("palette")
        if pal and args.stage >= _int(pal.get("stage", 0)):
            psrc, plen = _int(pal["src"]), _int(pal["len"])
            pblock = bytes(src_data_img[psrc:psrc + plen])
            expect = bytes.fromhex(pal["src_head_hex"])
            if pblock[:len(expect)] != expect:
                fail.append(f"palette: src block head at {psrc:#x} != "
                            f"{pal['src_head_hex']} (image drift?)")
            else:
                pa = alloc("b", plen, "sprite palette block")
                (out / "palette_block.bin").write_bytes(pblock)
                ops.append({"op": "data_file", "addr": f"{pa:#x}",
                            "path": "palette_block.bin"})
                fragments.append((pa, plen, "VS2", "sprite palette block"))
                ta = _int(pal["table"]) + 4 * _int(pal["row"])
                ops.append({"op": "poke32", "addr": f"{ta:#x}",
                            "val": f"{pa:#010x}"})
                notes.append(f"data     {pa:#08x} +{plen:#x}  sprite palette "
                             f"block (vsav2 0x{psrc:06X}); poke32 {ta:#08x} "
                             f"(palette table row {_int(pal['row']):#x})")

        # per-char value rows -> vsavj slot 0x0F rows
        for v in man["values"]:
            t = bank[v["table"]]
            a, es = table_entry_addr(v["table"], dst_slot)
            if v["kind"] in ("data_ptr", "code_ptr"):
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
        for a_t in man["auto_tables"]:
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
        # design + measured constants: docs/tables/reconciliation.md
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
        stubs = alloc("a", 32 * n_ext, "state_hook case stubs")
        et = alloc("a", 4 * n_ext, "state_hook ext table")
        mt = alloc("a", 50, "state_hook thunk")
        if None not in (stubs, et, mt):
            blob = b""
            for k in range(n_ext):
                blob += (b"\xb0\x2e" + _int(sh["prev_state_off"]).to_bytes(2, "big")
                         + b"\x66\x06"
                         + b"\x4e\xf9" + _int(sh["ret_equiv"]).to_bytes(4, "big")
                         + b"\x42\x2e" + _int(sh["clr_b_off"]).to_bytes(2, "big")
                         + b"\x42\x6e" + _int(sh["clr_w_off"]).to_bytes(2, "big")
                         + b"\x30\x3c" + (seq_id0 + k).to_bytes(2, "big")
                         + b"\x72\x01"
                         + b"\x4e\xf9" + sh["_seq_entry"].to_bytes(4, "big"))
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
        for d in man["dispatch"]:
            newt = None
            tgt = d["src_target"]
            host = region_of(tgt)
            if host in placed:
                newt = tgt + (placed[host] - man["regions"][host]["src"])
            if newt is None:
                fail.append(f"{d['table']}: dispatch target {tgt:#x} unplaced")
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
                sd = alloc("a", 68, "init seed shim")
                if sd is None:
                    continue
                latch = _int(shim_cfg["latch_disp"])
                flav_d = _int(shim_cfg["flavor_disp"])
                flav_v = _int(shim_cfg["flavor_default"])
                # Start-hold flavor selector (stage 5; community-confirmed
                # protocol, docs/atlas/character_tables.md): the byte at
                # flavor_hold_flag is a per-player Start bitmask (bit 0 =
                # P1, bit 1 = P2; live through match load — measured).
                # Holding YOUR Start through match load selects the other
                # game's flavor (latch <- flavor_held). All ops CCR-only —
                # no register clobbers before the handler.
                hold_flag = _int(shim_cfg["flavor_hold_flag"])
                flav_h = _int(shim_cfg["flavor_held"])
                shim = (bytes([0x2F, 0x0D])                       # move.l A5,-(SP)
                        + bytes([0x4B, 0xF9, 0x00, 0xFF, 0x80, 0x00])  # lea $FF8000.l,A5
                        + bytes([0x4A, 0xAD]) + latch.to_bytes(2, "big")  # tst.l (latch,A5)
                        + bytes([0x66, 0x06])                     # bne.s skip seed
                        + bytes([0x4E, 0xB9])
                        + _int(shim_cfg["seed_entry"]).to_bytes(4, "big")
                        + bytes([0x2A, 0x5F])                     # movea.l (SP)+,A5
                        + bytes([0x1D, 0x7C, 0x00, flav_v])       # move.b #default,
                        + flav_d.to_bytes(2, "big")               #   (flavor,A6)
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
                assert len(shim) == 68, len(shim)
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

    if args.stage >= 5:
        for p in port.get("aux_poke", []):
            ops.append({"op": p["op"], "addr": f"{_int(p['addr']):#x}",
                        "val": f"{_int(p['val']):#x}"})
            notes.append(f"{p['op']} {_int(p['addr']):#08x} <- {_int(p['val']):#x} "
                         f" aux {p['name']}")

    # ── emit ─────────────────────────────────────────────────────────────────
    placements = {name: {"dst": placed[name],
                         "src": man["regions"][name]["src"],
                         "len": man["regions"][name]["len"]}
                  for name in placed}
    (out / "placements.json").write_text(json.dumps(
        {"stage": args.stage, "regions": placements}, indent=1))
    (out / "patch.json").write_text(json.dumps({"ops": ops}, indent=1))
    (out / "patch_notes_fragment.md").write_text(
        f"# donovan-m2 stage {args.stage} — generated op notes\n\n"
        + "\n".join(notes) + "\n")
    (out / "atlas_fragment.md").write_text(
        "| dest | len | provenance | what |\n|---|---|---|---|\n"
        + "\n".join(f"| `PRG:0x{d:06X}` | 0x{ln:X} | {pv} | {w} |"
                    for d, ln, pv, w in fragments) + "\n")
    print(f"stage {args.stage}: {len(ops)} ops, "
          f"hole A watermark 0x{holes['a'][0]:06X}, "
          f"hole B watermark 0x{holes['b'][0]:06X}")
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
