#!/usr/bin/env python3
"""verify_gfx_build.py — static output-image verification of a stage-6+
gfx build. This is the check that caught the fmt-0 count corruption
(session 14b): the OBJ records in the BUILT image are re-walked and must
match the source walk exactly.

Checks:
  1. Record parity: the number of records found in the placed anim
     region equals the number found in the source region (a clobbered
     format/header word makes a record undetectable — loud here, wild
     jump at runtime).
  2. Code containment: every referenced tile code lies inside the
     placed windows (main band + effect tail) — nothing unremapped,
     nothing out of range.
  3. Placed-table sanity: the ported per-char OBJ bank table row 0x0F
     reads 0x4000 through the real opcode-decryption path.

Usage: verify_gfx_build.py <outbase>   (e.g. build/donovan6)
Exits nonzero with a FAIL line on any violation.
"""

import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from obj_records import walk  # noqa: E402
from _minitoml import loads as toml_loads  # noqa: E402


def main():
    outbase = sys.argv[1]
    pl = json.load(open(f"{outbase}/patch/placements.json"))
    anim = pl["regions"]["anim"]
    spec = json.load(open(f"{outbase}/gfx/remap_spec.json"))
    # effect_map exists only for delta-shifted tenants (Donovan); a
    # delta-0 tenant places everything at native codes (14z-67)
    _ep = f"{outbase}/patch/effect_map.json"
    eff = json.load(open(_ep)) if os.path.exists(_ep) else []
    lo = spec["placed"][0]
    hi = max([spec["placed"][1]] + [t for _, t in eff])

    # per-tenant source facts (14z-67, de-Donovanized): the anim span
    # from the tenant's layout row, the aux cptr windows from the
    # extraction itself (they were module constants — Donovan's values)
    rj = json.load(open(f"{outbase}/extract/regions.json"))
    aux_src = [(v["src"], v["src"] + v["len"])
               for n, v in rj["regions"].items() if n.startswith("aux")]
    _root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    _lay = toml_loads(open(os.path.join(
        _root, "build/manifest/gfx_layout3.toml")).read())
    _tj = json.load(open(f"{outbase}/patch/tenant.json"))
    _row = {r["name"]: r for r in _lay["tenant"]}[_tj["name"]]
    src_base = _row["anim_base"]
    src_end = _row["anim_base"] + _row["anim_len"]
    sweep_lo, sweep_hi = _row["sweep_lo"], _row["sweep_hi"]

    op_path = f"{outbase}/verify_op.bin"
    data_path = f"{outbase}/verify_data.bin"
    # The packed set name follows the build profile: a CPS-2 WIDE build packs
    # as vsavjw. Discover it rather than hard-coding vsavj, so this gate keeps
    # verifying the artifact that was actually produced.
    import glob
    cands = [z for z in glob.glob(f"{outbase}/rompath/*.zip")
             if os.path.basename(z).startswith("vsavj")]
    if not cands:
        raise SystemExit(f"verify: no vsavj*.zip in {outbase}/rompath")
    prg_zip = sorted(cands, key=len)[-1]   # prefer vsavjw.zip over vsavj.zip
    subprocess.run([sys.executable, "tools/cps2_decrypt.py",
                    prg_zip, op_path,
                    "--data-out", data_path],
                   check=True, capture_output=True)

    src = open(f"{outbase}/extract/region_anim.bin", "rb").read()
    # 14z-74: collect the SOURCE's accepted sweep offsets and hand them to the
    # built-image walk below, so the sweep heuristic cannot invent records from
    # straddled reads that only look like pointers after placement moved the
    # aux regions (measured on Pyron: 8 straddles -> 11 phantom records and 8
    # out-of-band tiles, with the real pointer correctly relocated).
    s_sweep = []
    _, s_entries, s_records = walk(
        src, src_base, src_base, src_end,
        lambda c: any(a <= c < b for a, b in aux_src),
        sweep_lo, sweep_hi, sweep_seen=s_sweep)

    out = open(data_path, "rb").read()
    aux_dst = [(r["dst"], r["dst"] + r["len"])
               for n, r in pl["regions"].items() if n.startswith("aux")]
    tiles, o_entries, o_records = walk(
        out, 0, anim["dst"], anim["dst"] + anim["len"],
        lambda c: any(a <= c < b for a, b in aux_dst),
        sweep_lo, sweep_hi, sweep_allow=set(s_sweep))

    fail = 0
    if (s_records, s_entries) != (o_records, o_entries):
        print(f"FAIL: record/entry parity src ({s_records},{s_entries}) "
              f"!= out ({o_records},{o_entries}) — header corruption "
              f"or walker drift")
        fail = 1
    else:
        print(f"  ok: record parity ({o_records} records, "
              f"{o_entries} entries)")
    # session 14z-10: codes may also land in the protected-tile POOL
    # (manifest protected_tiles.json) — vanilla-vetted free positions the
    # exception allocator uses; and NEVER on a protected position.
    import json as _json
    _pd = _json.loads(open("build/manifest/protected_tiles.json").read())
    _pool = set()
    for _a, _b in _pd["pool"]:
        _pool.update(range(int(_a, 16), int(_b, 16)))
    _prot = {int(x, 16) for x in _pd["protected"]}
    onprot = sorted(t for t in tiles if t in _prot)
    if onprot:
        print(f"FAIL: {len(onprot)} tile codes on PROTECTED positions: "
              f"{[hex(t) for t in onprot[:6]]}")
        fail = 1
    else:
        print(f"  ok: no tile codes on protected positions "
              f"({len(_prot)} protected)")
    outside = sorted(t for t in tiles
                     if not (lo <= t <= hi) and t not in _pool)
    if outside:
        print(f"FAIL: {len(outside)} tile codes outside placed windows "
              f"[{lo:#x},{hi:#x}]: {[hex(t) for t in outside[:6]]}")
        fail = 1
    else:
        print(f"  ok: all {len(tiles)} tile codes within "
              f"[0x{lo:04X},0x{hi:04X}]")
    opimg = open(op_path, "rb").read()
    x26 = pl["regions"]["x026142"]["dst"]
    # The tenant's id and gfx bank, not constants. This check used to assert
    # row 0x0F == 0x4000 outright, so it agreed with the port only by
    # coincidence: a build whose tenant had moved still asserted Jedah's row
    # and passed. Reading tenant.json makes the program half and the gfx half
    # answer to one manifest row. Falls back to the historical constants when
    # a build predates tenant.json.
    tj = f"{outbase}/patch/tenant.json"
    from gfx_tiles import bank_word
    slot, want = 0x0F, 0x4000
    if os.path.isfile(tj):
        t = json.load(open(tj))
        slot = int(t["id"])
        # WIDE encoding, NOT gfx_bank << 13 (bank 4 = 0x1000, the bit-12
        # promote; 4 << 13 would be the sprite-list terminator)
        want = bank_word(int(t.get("gfx_bank", 2)))
    off = x26 + 0x13EE + slot * 2
    row = int.from_bytes(opimg[off:off + 2], "big")
    if row != want:
        print(f"FAIL: placed bank table row {slot:#04x} = {row:#06x} "
              f"(want {want:#06x})")
        fail = 1
    else:
        print(f"  ok: placed bank table row {slot:#04x} = {want:#06x}")
    print("PASS: gfx build output verification" if not fail
          else "FAIL: gfx build output verification")
    sys.exit(fail)


if __name__ == "__main__":
    main()
