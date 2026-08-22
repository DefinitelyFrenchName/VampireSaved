#!/usr/bin/env python3
"""audit_gfx_merged.py — the 3-tenant merged GROUP-C destination census
(M3b Phase 3 step S0, session 14z-83).

Models the COMPLETE group-C write set of a merged 3-tenant gfx build —
every pass of tools/build_gfx_donovan.py, both banks — and byte-compares
every colliding destination at its SOURCES. The ratified layout's interval
proof (tests/test_gfx_layout3.sh) covers the walked INVENTORIES only; this
tool additionally models the side inventories that also write bank 4/5
(strip_tiles, extra_tiles, effect_map, effect_c5, select_bank5,
wheel_bank5), which is where the one known real collision lives.

Collision classes:
  benign — same destination, byte-identical source tiles (the ratified
           same-source-or-fail rule's "same-source" case; boundary
           overlaps between delta-0 tenants are this by construction,
           but this tool PROVES it with tile bytes, never assumes it).
  REAL   — same destination, DIFFERENT source bytes. A merged build must
           not ship any. (Known as of 14z-83: Huitzil's 288 strip dsts
           inside Pyron's native band — vs2 group A vs group B sources.)

Inventories are re-derived from the reference ROMs (obj_records.walk over
the ratified gfx_layout3 spans — the same instrument test_gfx_layout3.sh
locks). Side inventories are read from the three FROZEN build dirs, whose
bit-exact reproducibility is gated by tests/test_m3a_reproducible.sh; every
input's SHA-1 is printed (repo convention).

Usage:
  audit_gfx_merged.py <ROMDIR> [--vs2-data <decrypted vs2 data image>]
      [--json <out.json>] [--strip-json <path>] [--extra-h <path>]
      [--build-d build/m5_wide] [--build-h build/hui30]
      [--build-p build/pyron21]

Exit: 0 with the census printed (the GATE asserts on the --json output;
this tool reports, it does not judge — except on internal inconsistency).
"""

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gfx_tiles import GROUP_A, GROUP_B, tile_bytes  # noqa: E402
from obj_records import walk  # noqa: E402
from _minitoml import loads as toml_loads  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def sha1_of(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def jload(path):
    print(f"  read {path} sha1 {sha1_of(path)}")
    return json.load(open(path))


def load_group(z, prefix, group, label):
    out = []
    for n in group:
        data = z.read(f"{prefix}.{n}m")
        print(f"  read {label} {prefix}.{n}m sha1 "
              f"{hashlib.sha1(data).hexdigest()}")
        out.append(data)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("romdir")
    ap.add_argument("--vs2-data",
                    help="pre-decrypted vsav2 DATA image (cps2_decrypt.py "
                         "--data-out). Decrypted into a tempdir if absent")
    ap.add_argument("--layout", default=os.path.join(
        REPO, "build/manifest/gfx_layout3.toml"))
    ap.add_argument("--build-d", default=os.path.join(REPO, "build/m5_wide"))
    ap.add_argument("--build-h", default=os.path.join(REPO, "build/hui32"))
    ap.add_argument("--build-p", default=os.path.join(REPO, "build/pyron21"))
    ap.add_argument("--strip-json", default=os.path.join(
        REPO, "build/manifest/strip_tiles/0x10.json"),
        help="override for verdict controls")
    ap.add_argument("--extra-h", default=os.path.join(
        REPO, "build/manifest/extra_tiles/0x10.json"))
    ap.add_argument("--json", help="write the full classification here")
    args = ap.parse_args()

    man = toml_loads(open(args.layout).read())
    ten = {t["name"]: t for t in man["tenant"]}
    print(f"  read {args.layout} sha1 {sha1_of(args.layout)}")

    # -- 1. re-derive the three inventories from the reference ROMs --------
    if args.vs2_data:
        data_path = args.vs2_data
        tmp = None
    else:
        tmp = tempfile.TemporaryDirectory()
        data_path = os.path.join(tmp.name, "vs2_data.bin")
        subprocess.run([sys.executable,
                        os.path.join(REPO, "tools/cps2_decrypt.py"),
                        os.path.join(args.romdir, "vsav2.zip"),
                        os.path.join(tmp.name, "vs2_op.bin"),
                        "--data-out", data_path],
                       check=True, stdout=subprocess.DEVNULL)
    dat = open(data_path, "rb").read()
    print(f"  read vs2 data image sha1 {hashlib.sha1(dat).hexdigest()}")

    inv = {}
    for name in ("donovan", "huitzil", "pyron"):
        t = ten[name]
        base, ln = t["anim_base"], t["anim_len"]
        seg = dat[base:base + ln]
        lo, hi = 0x300000, 0x361000
        cptr_ok = (lambda b=base, e=base + ln:
                   lambda v: lo <= v < hi and not (b <= v < e))()
        tiles, entries, records = walk(
            seg, base, base, base + ln, cptr_ok,
            sweep_lo=t["sweep_lo"], sweep_hi=t["sweep_hi"])
        inv[name] = tiles
        print(f"  walk {name}: span {base:#x}+{ln:#x} -> {records} records, "
              f"{entries} entries, {len(tiles)} unique tiles")

    # -- 2. per-tenant destination maps: index -> (src_kind, src_idx) ------
    # index: in-group group-C position (bank 4 = code, bank 5 = 0x10000+code)
    # src_kind: vs2B (vsav2 group B), vs2A (vsav2 group A),
    #           vsavA (vsav group A)
    dst = {"donovan": {}, "huitzil": {}, "pyron": {}}
    intra = []          # (tenant, index, kinds) — collisions inside ONE build

    def place(tenant, idx, kind, sidx):
        d = dst[tenant]
        if idx in d:
            intra.append((tenant, idx, d[idx], (kind, sidx)))
            return
        d[idx] = (kind, sidx)

    # Donovan (delta tenant): band minus exceptions at +delta, effect map
    d_row = ten["donovan"]
    exc = jload(os.path.join(args.build_d, "patch/tile_exceptions.json"))
    skip_band = set(exc["skip_band_src"])
    delta = d_row["delta"]
    for c in sorted(inv["donovan"]):
        if d_row["band_lo"] <= c <= d_row["band_hi"] and c not in skip_band:
            place("donovan", c + delta, "vs2B", 0x10000 + c)
    eff = jload(os.path.join(args.build_d, "patch/effect_map.json"))
    for s, t_ in eff:
        place("donovan", t_, "vs2B", 0x10000 + s)

    # Huitzil (delta 0): inventory + extra_tiles native, strip at +shift
    extra = jload(args.extra_h)["tiles"]
    for c in sorted(inv["huitzil"] | set(extra)):
        place("huitzil", c, "vs2B", 0x10000 + c)
    st = jload(args.strip_json)
    shift = int(st["shift"], 16) if isinstance(st["shift"], str) \
        else st["shift"]
    for c in st["tiles"]:
        place("huitzil", c + shift, "vs2A", 0x10000 + c)

    # Pyron (delta 0): inventory native
    for c in sorted(inv["pyron"]):
        place("pyron", c, "vs2B", 0x10000 + c)

    # bank-5 passes, per tenant, in build_gfx pass order
    b5_sets = {}
    authored = {}
    for name, bdir in (("donovan", args.build_d), ("huitzil", args.build_h),
                       ("pyron", args.build_p)):
        e5p = os.path.join(bdir, "patch/effect_c5.json")
        if os.path.exists(e5p):
            for c in jload(e5p):
                place(name, 0x10000 + c, "vs2A", 0x10000 + c)
        for c in jload(os.path.join(bdir, "patch/select_bank5.json")):
            place(name, 0x10000 + c, "vs2A", 0x10000 + c)
        wb = jload(os.path.join(bdir, "patch/wheel_bank5.json"))
        for c in wb["host"]:
            place(name, 0x10000 + c, "vsavA", 0x10000 + c)
        for c in wb["vs2"]:
            place(name, 0x10000 + c, "vs2A", 0x10000 + c)
        for k, h in wb.get("authored", {}).items():   # 14z-105 version glyphs
            authored[int(k, 0)] = bytes.fromhex(h)
            place(name, int(k, 0), "authored", int(k, 0))
        b5_sets[name] = wb

    # -- 3. byte-compare every collision at its sources --------------------
    z2 = zipfile.ZipFile(os.path.join(args.romdir, "vsav2.zip"))
    za = zipfile.ZipFile(os.path.join(args.romdir, "vsav.zip"))
    groups = {"vs2B": load_group(z2, "vs2", GROUP_B, "vsav2"),
              "vs2A": load_group(z2, "vs2", GROUP_A, "vsav2"),
              "vsavA": load_group(za, "vm3", GROUP_A, "vsav")}

    def src_bytes(kind, sidx):
        if kind == "authored":          # NEW content: bytes ride the json
            return authored[sidx]
        return tile_bytes(groups[kind], sidx)

    def classify(pairs):
        """pairs: list of (idx, (kindA,sidxA), (kindB,sidxB))"""
        benign, real = [], []
        for idx, a, b in pairs:
            rec = {"idx": idx, "a": a, "b": b}
            if src_bytes(*a) == src_bytes(*b):
                benign.append(rec)
            else:
                real.append(rec)
        return benign, real

    report = {"pairs": {}, "intra": [], "occupancy": {}}
    names = ("donovan", "huitzil", "pyron")
    total_real = 0
    for i, na in enumerate(names):
        for nb in names[i + 1:]:
            common = sorted(set(dst[na]) & set(dst[nb]))
            pairs = [(x, dst[na][x], dst[nb][x]) for x in common]
            benign, real = classify(pairs)
            total_real += len(real)
            b4 = [p for p in common if p < 0x10000]
            print(f"  {na}∩{nb}: {len(common)} shared dsts "
                  f"({len(b4)} bank-4, {len(common)-len(b4)} bank-5) -> "
                  f"{len(benign)} same-source benign, {len(real)} REAL")
            if real:
                lo_r = min(r["idx"] for r in real)
                hi_r = max(r["idx"] for r in real)
                print(f"    REAL range {lo_r:#07x}-{hi_r:#07x} "
                      f"(sources {real[0]['a'][0]} vs {real[0]['b'][0]})")
            report["pairs"][f"{na}:{nb}"] = {
                "shared": len(common),
                "benign": len(benign),
                "real": sorted(r["idx"] for r in real)}
    ib, ir = classify([(idx, a, b) for _, idx, a, b in intra])
    print(f"  intra-tenant collisions: {len(intra)} "
          f"({len(ib)} same-source benign, {len(ir)} REAL)")
    total_real += len(ir)
    report["intra"] = {"total": len(intra),
                       "real": sorted(r["idx"] for r in ir)}

    # -- 4. occupancy + free pools vs the manifest ledger ------------------
    union4 = set()
    union5 = set()
    for d in dst.values():
        union4 |= {i for i in d if i < 0x10000}
        union5 |= {i for i in d if i >= 0x10000}
    print(f"  bank 4 union: {len(union4)}/65536 codes "
          f"({100.0 * len(union4) / 65536:.1f}%), "
          f"{65536 - len(union4)} free")
    print(f"  bank 5 union: {len(union5)}/65536 codes")
    free_runs = []
    prev = -1
    for c in sorted(union4) + [0x10000]:
        if c > prev + 1:
            free_runs.append((prev + 1, c - 1))
        prev = c
    free_runs = [(a, b) for a, b in free_runs if b - a + 1 >= 256]
    print("  bank-4 free runs (>=256 codes): "
          + ", ".join(f"{a:#06x}-{b:#06x}({b - a + 1})"
                      for a, b in free_runs))
    man_pools = [(p["lo"], p["hi"]) for p in man.get("free_pool", [])]
    for lo_p, hi_p in man_pools:
        used = [c for c in range(lo_p, hi_p + 1) if c in union4]
        tag = "EMPTY" if not used else f"{len(used)} USED"
        print(f"  manifest pool {lo_p:#06x}-{hi_p:#06x}: {tag}")
        report["occupancy"][f"pool_{lo_p:#x}"] = len(used)
    report["occupancy"]["bank4_union"] = len(union4)
    report["occupancy"]["bank5_union"] = len(union5)
    report["total_real"] = total_real

    if args.json:
        json.dump(report, open(args.json, "w"), indent=1)
        print(f"  wrote {args.json}")
    print(f"CENSUS: {total_real} REAL collision(s) across the 3-tenant "
          f"merged group-C write set")


if __name__ == "__main__":
    main()
