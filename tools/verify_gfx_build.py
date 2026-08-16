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
    # 14z-83 S4: multi-tenant form. The solo invocation
    # (`verify_gfx_build.py <outbase>`) is byte-unchanged; a merged build
    # verifies each tenant with --tenant <name> (row from tenants.json,
    # placement keys gain the @<name> suffix for non-first tenants),
    # --gfx-dir <link dir> (the tenant's own chain link) and
    # --extract-dir <frozen extract dir> (the merged build has no
    # extract/ of its own — the three frozen verticals' extracts are the
    # generator's inputs).
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("outbase")
    ap.add_argument("--tenant", help="tenant NAME (merged builds); row "
                    "resolved from patch/tenants.json")
    ap.add_argument("--gfx-dir", help="remap_spec dir (default "
                    "<outbase>/gfx)")
    ap.add_argument("--extract-dir", help="extraction dir (default "
                    "<outbase>/extract)")
    args = ap.parse_args()
    outbase = args.outbase
    gfx_dir = args.gfx_dir or f"{outbase}/gfx"
    ex_dir = args.extract_dir or f"{outbase}/extract"

    pl = json.load(open(f"{outbase}/patch/placements.json"))
    if args.tenant:
        _tens = json.load(open(f"{outbase}/patch/tenants.json"))
        _tj = {t["name"]: t for t in _tens}[args.tenant]
        # tenant 0 keeps the bare spellings (the historical, solo-
        # compatible ones); later tenants ride the @<name> suffix
        sfx = "" if _tens[0]["name"] == args.tenant else f"@{args.tenant}"
    else:
        _tj = json.load(open(f"{outbase}/patch/tenant.json"))
        sfx = ""
    anim = pl["regions"]["anim" + sfx]
    spec = json.load(open(f"{gfx_dir}/remap_spec.json"))
    # effect_map exists only for delta-shifted tenants (Donovan); a
    # delta-0 tenant places everything at native codes (14z-67)
    _ep = f"{outbase}/patch/effect_map.json" if not sfx else \
        f"{outbase}/patch/effect_map.{args.tenant}.json"
    eff = json.load(open(_ep)) if os.path.exists(_ep) else []
    lo = spec["placed"][0]
    hi = max([spec["placed"][1]] + [t for _, t in eff])

    # per-tenant source facts (14z-67, de-Donovanized): the anim span
    # from the tenant's layout row, the aux cptr windows from the
    # extraction itself (they were module constants — Donovan's values)
    rj = json.load(open(f"{ex_dir}/regions.json"))
    aux_src = [(v["src"], v["src"] + v["len"])
               for n, v in rj["regions"].items() if n.startswith("aux")]
    _root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    _lay = toml_loads(open(os.path.join(
        _root, "build/manifest/gfx_layout3.toml")).read())
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

    src = open(f"{ex_dir}/region_anim.bin", "rb").read()
    # 14z-74: collect the SOURCE's accepted sweep offsets and hand them to the
    # built-image walk below, so the sweep heuristic cannot invent records from
    # straddled reads that only look like pointers after placement moved the
    # aux regions (measured on Pyron: 8 straddles -> 11 phantom records and 8
    # out-of-band tiles, with the real pointer correctly relocated).
    # 14z-92 (#75): the same treatment for the POINTER pass, which 14z-74
    # left ungated — a straddled read inside a real record read as an
    # in-region pointer once the merged placement window happened to
    # contain its value, inventing one record, 67 entries and 34
    # out-of-band tiles. `s_ptr` maps the source's accepted pointer
    # offsets to their target offsets; the built walk must reproduce that
    # mapping exactly. See obj_records.walk's docstring.
    s_sweep = []
    s_ptr = {}
    _, s_entries, s_records = walk(
        src, src_base, src_base, src_end,
        lambda c: any(a <= c < b for a, b in aux_src),
        sweep_lo, sweep_hi, sweep_seen=s_sweep, ptr_seen=s_ptr)

    out = open(data_path, "rb").read()
    # this tenant's aux placements only: bare keys for the first tenant,
    # @<name>-suffixed for the others (a merged build carries all three)
    aux_dst = [(r["dst"], r["dst"] + r["len"])
               for n, r in pl["regions"].items() if n.startswith("aux")
               and (n.endswith(sfx) if sfx else "@" not in n)]
    o_ptr, o_rej = {}, []
    tiles, o_entries, o_records = walk(
        out, 0, anim["dst"], anim["dst"] + anim["len"],
        lambda c: any(a <= c < b for a, b in aux_dst),
        sweep_lo, sweep_hi, sweep_allow=set(s_sweep),
        ptr_allow=s_ptr, ptr_seen=o_ptr, ptr_rejected=o_rej)

    fail = 0
    if (s_records, s_entries) != (o_records, o_entries):
        print(f"FAIL: record/entry parity src ({s_records},{s_entries}) "
              f"!= out ({o_records},{o_entries}) — header corruption "
              f"or walker drift")
        # 14z-92: name the records, not just the counts. "1374 != 1375"
        # cost a whole investigation (#75); a source record the built
        # image does not reproduce is the actual defect shape (a
        # clobbered format/count word makes its record undetectable).
        gone = sorted(set(s_ptr) - set(o_ptr))
        for p in gone[:8]:
            print(f"    not reproduced: ptr +0x{p:x} -> record "
                  f"+0x{s_ptr[p]:x}")
        if len(gone) > 8:
            print(f"    ... and {len(gone) - 8} more")
        fail = 1
    else:
        print(f"  ok: record parity ({o_records} records, "
              f"{o_entries} entries)")
    # The coincidences themselves: candidates that validated as records in
    # the BUILT image and that the source never accepted. Printed rather
    # than hidden — #75 was exactly one of these, and it aborted every
    # merged build from merged6 on.
    # Grouped by target: the discovering datum is usually a repeating run
    # (#75's was coordinate data at an 8-byte stride, so one coincidence
    # reported from seven offsets). One line per phantom, not per read.
    _byt = {}
    for p, t in o_rej:
        _byt.setdefault(t, []).append(p)
    for t in sorted(_byt):
        _ps = sorted(_byt[t])
        _via = f"+0x{_ps[0]:x}" + (f" (and {len(_ps) - 1} more)"
                                   if len(_ps) > 1 else "")
        print(f"  note: placement coincidence rejected — record-shaped "
              f"bytes at +0x{t:x}, reached from {_via}; not a source "
              f"record")
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
    # 14z-83 S4: the tenant's OWN copy of the bank-table region. Measured
    # on the merged image before trusting this key choice: every copy
    # (x026142, @huitzil, @pyron) carries ALL THREE tenants' rows
    # (0x10/0x11/0x13 = 0x1000, Jedah 0x0F = 0x4000), so whichever copy
    # the engine serves, the row is right — and the per-tenant key keeps
    # this check meaningful per link.
    x26 = pl["regions"]["x026142" + sfx]["dst"]
    # The tenant's id and gfx bank, not constants. This check used to assert
    # row 0x0F == 0x4000 outright, so it agreed with the port only by
    # coincidence: a build whose tenant had moved still asserted Jedah's row
    # and passed. Reading the tenant row makes the program half and the gfx
    # half answer to one manifest row. Falls back to the historical
    # constants when a build predates tenant.json.
    from gfx_tiles import bank_word
    slot, want = 0x0F, 0x4000
    if _tj is not None:
        slot = int(_tj["id"])
        # WIDE encoding, NOT gfx_bank << 13 (bank 4 = 0x1000, the bit-12
        # promote; 4 << 13 would be the sprite-list terminator)
        want = bank_word(int(_tj.get("gfx_bank", 2)))
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
