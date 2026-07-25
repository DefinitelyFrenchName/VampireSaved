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
    ap.add_argument("--stage", type=int, required=True, choices=range(1, 6))
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

    def alloc(hole, size, what, fallback=True):
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

    # ── stage 1: null relocation ─────────────────────────────────────────────
    # Jedah player-path hitbox block bounds by next-distinct-pointer on vsavj
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
    jh_len = jh_end - jh_start
    notes.append(f"# stage 1: Jedah hitbox block 0x{jh_start:06X}+0x{jh_len:X} "
                 f"(base {seeds[0]:#x} comp {seeds[1]:#x})")
    dst = alloc("a", jh_len, "jedah hitbox copy")
    if dst is not None:
        delta = dst - jh_start
        poke_bytes(dst, vj[jh_start:jh_start + jh_len], "jedah hitbox copy (null reloc)")
        fragments.append((dst, jh_len, "VSAV", "stage1 jedah hitbox copy"))
        repoint("hitbox_base", seeds[0] + delta, "null reloc")
        repoint("hitbox_comp", seeds[1] + delta, "null reloc")

    # trampolines: dispatch_00 via hole A (re-encrypted), dispatch_01 via
    # hole B (outside the encrypted range -> stored raw)
    for tname, hole in (("dispatch_00", "a"), ("dispatch_01", "b")):
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
        # allocate every wanted region first (deterministic order: code
        # first so it stays in the encrypted hole, then data)
        for name in sorted(want, key=lambda n: (regions[n]["kind"] != "code", n)):
            r = regions[name]
            d = alloc("a", r["len"], f"region {name}")
            if d is not None:
                placed[name] = d
                fragments.append((d, r["len"], "VS2",
                                  f"donovan {name} (vsav2 0x{r['src']:06X})"))

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
            d = placed[name]
            fixed = out / f"fixed_{name}.bin"
            fixed.write_bytes(bytes(blob))
            op = "code_file" if r["kind"] == "code" else "data_file"
            ops.append({"op": op, "addr": f"{d:#x}", "path": fixed.name})
            notes.append(f"{op:9s} {d:#08x} +{r['len']:#x}  donovan {name} "
                         f"(from vsav2 0x{r['src']:06X})")

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

    if args.stage >= 4 and "proj_hook" in port:
        ph = port["proj_hook"]
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
                fail.append(f"proj_hook: engine bytes at {site:#x} != expected "
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
            if host and host in placed:
                newt = tgt + (placed[host] - regions[host]["src"])
                ported += 1
            else:
                newt = None
            if newt is None:
                # unported extra type: point at a tripwire so a use is LOUD
                newt = tripwire_for(tgt, f"proj_hook type {k}") \
                    if args.tripwire_open else None
                if newt is None:
                    fail.append(f"proj_hook: extra type {k} handler {tgt:#x} "
                                f"not ported/placed")
                    newt = 0
            table += newt.to_bytes(4, "big")
        tdst = alloc("a", len(table), "proj_hook extended table")
        thunk = None
        if tdst is not None:
            ops.append({"op": "data", "addr": f"{tdst:#x}", "hex": table.hex()})
            notes.append(f"data   {tdst:#08x} +{len(table):#x}  proj_hook "
                         f"extended type table ({n_van} vanilla + "
                         f"{n_src - n_van} ported, {ported} placed)")
            fragments.append((tdst, len(table), "GEN", "proj_hook ext table"))
            thunk = alloc("a", 14, "proj_hook thunk")
        if thunk is not None:
            tk = (bytes([0x41, 0xF9]) + tdst.to_bytes(4, "big")   # lea tbl,A0
                  + bytes([0x20, 0x70, 0x00, 0x00])               # movea.l (A0,D0.w),A0
                  + bytes([0x70, 0x00])                           # moveq #0,D0
                  + bytes([0x4E, 0xD0]))                          # jmp (A0)
            ops.append({"op": "code", "addr": f"{thunk:#x}", "hex": tk.hex()})
            notes.append(f"code   {thunk:#08x} proj_hook thunk")
            fragments.append((thunk, 14, "GEN", "proj_hook thunk"))
            site_patch = bytes([0x4E, 0xB9]) + thunk.to_bytes(4, "big") \
                + bytes([0x4E, 0x71])
            ops.append({"op": "code", "addr": f"{site:#x}",
                        "hex": site_patch.hex()})
            notes.append(f"code   {site:#08x} ENGINE HOOK: dispatch -> jsr "
                         f"thunk; nop (vanilla types identical via table copy)")
            fragments.append((site, 8, "GEN", "proj_hook engine site"))

    if args.stage >= 4:
        for d in man["dispatch"]:
            newt = None
            tgt = d["src_target"]
            host = region_of(tgt)
            if host in placed:
                newt = tgt + (placed[host] - man["regions"][host]["src"])
            if newt is None:
                fail.append(f"{d['table']}: dispatch target {tgt:#x} unplaced")
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
