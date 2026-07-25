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
REGION_ORDER = ["code", "hitbox", "hitbox_proj", "anim",
                "aux0_0", "aux0_1", "aux0_2", "aux0_3", "aux0_4"]
STAGE_REGIONS = {2: ["hitbox", "hitbox_proj"],
                 3: ["anim", "aux0_0", "aux0_1", "aux0_2", "aux0_3", "aux0_4"],
                 4: ["code"]}


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

    def alloc(hole, size, what):
        start, end = holes[hole]
        if start + size > end:
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
        want = []
        for s in (2, 3, 4):
            if args.stage >= s:
                want += STAGE_REGIONS[s]
        # allocate every wanted region first (deterministic REGION_ORDER)
        for name in REGION_ORDER:
            if name not in want or name not in regions:
                continue
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

        def relocate_target(ref, where):
            """New vsavj address for a ref target, or None + fail note."""
            cls = ref.get("class", "internal")
            tgt = ref["target"]
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
                cand = VSAVJ_ORIGIN + (tgt - src_bank_origin)
                m = recon.get(tgt)
                if m and m.get("status") == "verified":
                    return _int(m["vsavj"])
                fail.append(f"{where}: bank_ref {tgt:#x} (delta-rule candidate "
                            f"{cand:#x}) needs a verified reconciliation row")
                return None
            if cls in ("engine", "pcrel16", "code_neighbor"):
                m = recon.get(tgt)
                if m and m.get("status") == "verified":
                    return _int(m["vsavj"])
                fail.append(f"{where}: {cls} ref {tgt:#x} unresolved "
                            f"(reconciliation row missing/unverified)")
                return None
            fail.append(f"{where}: unknown ref class {cls} -> {tgt:#x}")
            return None

        for name in [n for n in REGION_ORDER if n in placed]:
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
            if v["kind"] == "data_ptr":
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
            if mirror and t["kind"] != "byte2d":
                av, _ = table_entry_addr(v["table"], var_slot)
                if vj[av:av + es] == vj[a:a + es]:
                    poke_bytes(av, data, f"{v['table']}[{var_slot:#x}] mirror")
                else:
                    fail.append(f"{v['table']}: variant row not vanilla-aliased")
        # oracle-classified gap value tables
        for a_t in man["auto_tables"]:
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
                if vj[av:av + es] == vj[a:a + es]:
                    poke_bytes(av, data, f"{a_t['table']}[{var_slot:#x}] mirror")
                else:
                    fail.append(f"{a_t['table']}: variant row not vanilla-aliased")

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
