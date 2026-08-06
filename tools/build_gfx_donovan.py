#!/usr/bin/env python3
"""build_gfx_donovan.py — place Donovan's sprite tiles into vsav's gfx
members at Jedah's band positions (M2b tile-data step).

Reads Donovan's art from vsav2's gfx (bank 3) and writes it into copies
of vsav's group-B simms (vm3.14m/16m/18m/20m — bank 2 lives in group B)
at the Jedah-band placement decided by the session-14 measurements:

  source band  : vs2 bank 3, codes SRC_LO..SRC_HI (0x863F..0xC2EF used)
  placement    : vsav bank 2, delta +0x2750 (16-aligned, preserves
                 sprite-block row-wrap), i.e. codes 0xAD8F..0xEA3F —
                 above the 44-tile Sasquatch-shared band head
                 (0xAD3E-0xAD74), inside Jedah's band (max 0xEEBB).

Only tiles Donovan's OBJ records actually reference (the inventory JSON
from tools/obj_records.py) are copied; every other byte of every member
is untouched (verified). The PRG-side record remap (same delta) is a
separate patcher step — this tool only produces gfx members + the remap
spec consumed by that step.

Usage:
  build_gfx_donovan.py <ROMDIR> <outdir> --tiles <donovan_tiles.json>

Outputs in <outdir>: vm3.14m/16m/18m/20m (patched), remap_spec.json,
and prints SHA-1s of everything read and written (repo convention).
Verification (always run): re-extract every written position and compare
to the source tile; assert untouched ranges byte-identical to input.
"""

import argparse
import hashlib
import json
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gfx_tiles import GROUP_A, GROUP_B, GROUP_C, bank_word, \
    tile_bytes, write_tile  # noqa: E402

SRC_BANK = 3          # Donovan's bank in vsav2
# DST_BANK is the gfx bank the tenant's tiles occupy. It WAS hard-coded to 2
# ("Jedah's bank", slot-0x0F table row 0x4000), which made the gfx half
# silently independent of the port's target id. It is now supplied by the
# tenant (--tenant tenant.json, written by gen_donovan_patch.py) and this
# constant is only the fallback for a manifest that does not declare one.
DST_BANK = 2
DELTA = 0x2750        # 16-aligned code delta, decided session 14
BAND_LO, BAND_HI = 0x863F, 0xC2EF          # Donovan main band (measured)
SAFE_LO, SAFE_HI = 0xAD80, 0xEEBB          # writable window in Jedah band


def load_group(z, prefix, group):
    out = []
    for n in group:
        data = z.read(f"{prefix}.{n}m")
        print(f"  read {prefix}.{n}m sha1 {hashlib.sha1(data).hexdigest()}")
        out.append(data)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("romdir")
    ap.add_argument("outdir")
    ap.add_argument("--tiles", required=True,
                    help="obj_records.py --json output (vs2 tile codes)")
    ap.add_argument("--effects",
                    help="effect_map.json from the generator: [src,dst] "
                         "tile pairs (vs2 bank-3 code -> vsav bank-2 code)")
    ap.add_argument("--effect-tail",
                    help="build/manifest/effect_tail.json: place the "
                         "missing engine-effect band (vs2 bank-1 ->")
    ap.add_argument("--select-tiles",
                    help="select_tiles.json from select_port.py: [src,dst] "
                         "BANK-1 pairs (group-A members; Jedah's freed "
                         "select/splash art positions)")
    ap.add_argument("--overlay-tiles",
                    help="overlay_tiles.json from overlay_port.py: [src,dst] "
                         "BANK-1 pairs (companion-overlay art at dead-Jedah "
                         "+ padding positions; session 14q)")
    ap.add_argument("--select-bank5",
                    help="select_bank5.json from the generator: native "
                         "bank-1 tile codes whose art is copied vs2 -> "
                         "group C BANK 5 (in-group 0x10000+code). Group-C "
                         "mode only; the piece's drawer object is "
                         "bank-gated per hover on the program side")
    ap.add_argument("--wheel-bank5",
                    help="wheel_bank5.json from the generator: the select "
                         "wheel's tile inventory for the bank-5 move — "
                         "'host' codes copied BYTE-IDENTICAL from vsav "
                         "group A (vanilla medallion pixels preserved by "
                         "construction), 'vs2' codes (the appended cells' "
                         "native medallions) from vs2 group A; both to "
                         "group C 0x10000+code. Group-C mode only; the "
                         "drawer's select-init bank word is flipped on "
                         "the program side")
    ap.add_argument("--tenant",
                    help="tenant.json from gen_donovan_patch.py. Supplies the "
                         "destination gfx bank, so this half cannot drift "
                         "from the port's target id — it used to be the "
                         "constant DST_BANK=2 and a build with the tenant "
                         "moved elsewhere still placed Jedah's bank row")
    args = ap.parse_args()
    os.makedirs(args.outdir, exist_ok=True)

    global DST_BANK
    if args.tenant:
        _t = json.load(open(args.tenant))
        DST_BANK = int(_t.get("gfx_bank", DST_BANK))
        print("  tenant %s id %#04x -> gfx bank %d (bank word %#06x)"
              % (_t.get("name"), _t["id"], DST_BANK, bank_word(DST_BANK)))
    # WIDE group C (banks 4-5): the tenant's band+shelf keep their in-group
    # tile indices (code+DELTA, unchanged from the host-band layout, so the
    # RECORDS need no rewrite at all) but the tile DATA goes into the four
    # appended vsw simms instead of vsav's group B, which therefore stays
    # PRISTINE — the host's fighter/select-portrait art comes back wholesale.
    group_c = DST_BANK >= 4

    inv = json.load(open(args.tiles))
    band = sorted(t for t in inv if BAND_LO <= t <= BAND_HI)
    skipped = len(inv) - len(band)
    print(f"inventory: {len(inv)} tiles, {len(band)} in main band "
          f"({skipped} effect/low tiles handled by the per-record map, "
          f"not this tool)")
    lo_dst, hi_dst = band[0] + DELTA, band[-1] + DELTA
    assert SAFE_LO <= lo_dst and hi_dst <= SAFE_HI, \
        f"placement 0x{lo_dst:04X}-0x{hi_dst:04X} outside safe window"
    assert DELTA % 16 == 0, "delta must be 16-aligned (block row-wrap)"

    z2 = zipfile.ZipFile(os.path.join(args.romdir, "vsav2.zip"))
    za = zipfile.ZipFile(os.path.join(args.romdir, "vsav.zip"))
    src = load_group(z2, "vs2", GROUP_B)      # bank 3 = group B (>=0x20000)
    if group_c:
        # fresh zero simms — group C ships zero-filled from
        # build_wide_romset.py, so "untouched == zero" is the invariant
        dst_orig = [bytes(0x400000) for _ in GROUP_C]
    else:
        dst_orig = load_group(za, "vm3", GROUP_B)  # bank 2 = group B too
    dst = [bytearray(s) for s in dst_orig]

    # src bank 3 -> group-B index = 0x10000 + code
    # dst bank 2 -> group-B index = 0x00000 + code
    written = set()
    # session 14z-10: band srcs whose delta target is a PROTECTED vanilla
    # position are relocated by the generator's exception pool (they
    # arrive via effect_map pairs instead) — never write their delta slot.
    skip_band = set()
    exc_path = (os.path.join(os.path.dirname(args.effects), "tile_exceptions.json")
                if args.effects else "")
    if exc_path and os.path.exists(exc_path):
        skip_band = set(json.load(open(exc_path))["skip_band_src"])
        print(f"tile exceptions: {len(skip_band)} band srcs skipped")
    for code in band:
        if code in skip_band:
            continue
        tile = tile_bytes(src, 0x10000 + code)
        write_tile(dst, (code + DELTA), tile)
        written.add(code + DELTA)

    # effect tiles: explicit (src, dst) pairs from the generator's
    # shelf-pack of the mixed-record shared-effect blocks
    eff_pairs = []
    if args.effects:
        eff_pairs = json.load(open(args.effects))
        for s, t in eff_pairs:
            assert SAFE_LO <= t <= SAFE_HI, f"effect dst 0x{t:04X} unsafe"
            assert t not in written, f"effect dst 0x{t:04X} collides"
            write_tile(dst, t, tile_bytes(src, 0x10000 + s))
            written.add(t)
        print(f"effects: {len(eff_pairs)} tiles placed from effect_map")

    # bank-5 select art (option A, 14z-62j): NATIVE bank-1 codes copied
    # into group C's upper bank, disjoint from the band/shelf by
    # construction (band in-group indices are < 0x10000).
    b5 = []
    srcA5 = None
    if args.select_bank5 and group_c:
        b5 = json.load(open(args.select_bank5))
        srcA5 = load_group(z2, "vs2", GROUP_A)
        for c in b5:
            d5 = 0x10000 + c
            assert d5 not in written, f"bank-5 dst 0x{d5:05X} collides"
            write_tile(dst, d5, tile_bytes(srcA5, 0x10000 + c))
            written.add(d5)
        print(f"select bank-5: {len(b5)} native tiles copied to group C "
              f"upper bank")
    elif args.select_bank5:
        b5j = json.load(open(args.select_bank5))
        assert not b5j, ("select_bank5.json has tiles but the build is not "
                        "group-C mode — the drawer gate would dangle")

    # wheel bank-5 (14z-63): the select wheel's whole tile set into group
    # C's upper bank — host entries byte-identical from vsav's own group A
    # (vanilla medallions render pixel-identical by construction), the
    # appended cells' native codes from vs2 group A.
    wb5 = {"host": [], "vs2": []}
    if args.wheel_bank5 and group_c:
        wb5 = json.load(open(args.wheel_bank5))
        srcA_host = load_group(za, "vm3", GROUP_A)
        if srcA5 is None and wb5["vs2"]:
            srcA5 = load_group(z2, "vs2", GROUP_A)
        for c in wb5["host"]:
            d5 = 0x10000 + c
            assert d5 not in written, f"wheel host dst 0x{d5:05X} collides"
            write_tile(dst, d5, tile_bytes(srcA_host, 0x10000 + c))
            written.add(d5)
        for c in wb5["vs2"]:
            d5 = 0x10000 + c
            assert d5 not in written, f"wheel vs2 dst 0x{d5:05X} collides"
            write_tile(dst, d5, tile_bytes(srcA5, 0x10000 + c))
            written.add(d5)
        print(f"wheel bank-5: {len(wb5['host'])} host tiles (byte-identical "
              f"vsav group A) + {len(wb5['vs2'])} vs2 medallion tiles "
              f"copied to group C upper bank")
    elif args.wheel_bank5:
        wj = json.load(open(args.wheel_bank5))
        assert not (wj["host"] or wj["vs2"]), (
            "wheel_bank5.json has tiles but the build is not group-C mode "
            "— the drawer bank flip would serve zeros")

    # verification 1: every written position reads back as the source tile
    # (14z-10: exception-relocated srcs are NOT at delta positions — their
    # readback happens via eff_pairs below)
    for code in band:
        if code in skip_band:
            continue
        got = tile_bytes(dst, code + DELTA)
        want = tile_bytes(src, 0x10000 + code)
        assert got == want, f"readback mismatch at dst code 0x{code+DELTA:04X}"
    for s, t in eff_pairs:
        assert tile_bytes(dst, t) == tile_bytes(src, 0x10000 + s), \
            f"effect readback mismatch at 0x{t:04X}"
    for c in b5:
        assert tile_bytes(dst, 0x10000 + c) == \
            tile_bytes(srcA5, 0x10000 + c), \
            f"bank-5 readback mismatch at 0x{c:04X}"
    for c in wb5["host"]:
        assert tile_bytes(dst, 0x10000 + c) == \
            tile_bytes(srcA_host, 0x10000 + c), \
            f"wheel host readback mismatch at 0x{c:04X}"
    for c in wb5["vs2"]:
        assert tile_bytes(dst, 0x10000 + c) == \
            tile_bytes(srcA5, 0x10000 + c), \
            f"wheel vs2 readback mismatch at 0x{c:04X}"
    # verification 2: untouched positions byte-identical to input
    dirty = 0
    for t2 in range(0, 0x20000):
        if t2 in written:
            continue
        if tile_bytes(dst, t2) != tile_bytes(
                [memoryview(x) for x in dst_orig], t2):
            print(f"FAIL: untouched tile 0x{t2:05X} changed")
            dirty += 1
    assert dirty == 0, f"{dirty} untouched tiles changed"
    print(f"verified: {len(band)} tiles placed at codes "
          f"0x{lo_dst:04X}-0x{hi_dst:04X} (bank {DST_BANK}); "
          f"all other tiles byte-identical")

    if group_c:
        for n, buf in zip(GROUP_C, dst):
            path = os.path.join(args.outdir, f"vsw.{n}m")
            open(path, "wb").write(buf)
            print(f"  wrote vsw.{n}m sha1 "
                  f"{hashlib.sha1(bytes(buf)).hexdigest()}")
        print("group C mode: vsav group B NOT written — the host band "
              "stays pristine")
    else:
        for n, buf in zip(GROUP_B, dst):
            path = os.path.join(args.outdir, f"vm3.{n}m")
            open(path, "wb").write(buf)
            print(f"  wrote vm3.{n}m sha1 "
                  f"{hashlib.sha1(bytes(buf)).hexdigest()}")

    # effect-tail art: vs2 bank-1 blocks placed at vsav bank-1 anchors
    if args.effect_tail:
        et = json.load(open(args.effect_tail))
        srcA0 = load_group(z2, "vs2", GROUP_A)
        dstA0 = [bytearray(s) for s in load_group(za, "vm3", GROUP_A)]
        n = 0
        # place_host_slot (14z-62h): entries that overwrite the HOST's own
        # cells (HUD mugshot, wheel medallion) — only while the tenant
        # occupies the base slot. At a variant id the host keeps his art.
        places = dict(et["place"])
        if DST_BANK < 4:
            places.update(et.get("place_host_slot", {}))
        else:
            print(f"effect-tail: {len(et.get('place_host_slot', {}))} "
                  f"host-slot place(s) SKIPPED (variant-id tenant)")
            # place_variant_slot (14z-63): art whose HOST-slot home was the
            # host's own cells (HUD mugshot) gets a free-pool anchor
            # instead — only on variant-id builds, so the frozen stock
            # track's members are untouched.
            places.update(et.get("place_variant_slot", {}))
            if et.get("place_variant_slot"):
                print(f"effect-tail: {len(et['place_variant_slot'])} "
                      f"variant-slot place(s) added (free-pool anchors)")
        for k, v in places.items():
            tt, bx, by = k.split(",")
            t = int(tt, 16); anchor = int(v, 16)
            for dy in range(int(by)):
                for dx in range(int(bx)):
                    s_ = (t & ~0xF) + (dy << 4) + ((t + dx) & 0xF)
                    d_ = (anchor & ~0xF) + (dy << 4) + ((anchor + dx) & 0xF)
                    write_tile(dstA0, 0x10000 + d_,
                               tile_bytes(srcA0, 0x10000 + s_))
                    n += 1
        for k, v in places.items():
            tt, bx, by = k.split(",")
            t = int(tt, 16); anchor = int(v, 16)
            for dy in range(int(by)):
                for dx in range(int(bx)):
                    s_ = (t & ~0xF) + (dy << 4) + ((t + dx) & 0xF)
                    d_ = (anchor & ~0xF) + (dy << 4) + ((anchor + dx) & 0xF)
                    assert tile_bytes(dstA0, 0x10000 + d_) == \
                        tile_bytes(srcA0, 0x10000 + s_)
        print(f"effect-tail: {n} bank-1 tiles placed")
        for nm, buf in zip(GROUP_A, dstA0):
            open(os.path.join(args.outdir, f"vm3.{nm}m"), "wb").write(buf)
        za_patched = args.outdir  # select pass below must chain on these
    # select-screen art: bank-1 pairs live in GROUP A (abs 0x10000+code)
    if args.select_tiles:
        sel = json.load(open(args.select_tiles))
        srcA = load_group(z2, "vs2", GROUP_A)
        if args.effect_tail:
            # chain on the effect-tail-patched members
            dstA = [bytearray(open(os.path.join(args.outdir,
                    f"vm3.{nm}m"), "rb").read()) for nm in GROUP_A]
        else:
            dstA = [bytearray(s) for s in load_group(za, "vm3", GROUP_A)]
        for s_, t_ in sel:
            write_tile(dstA, 0x10000 + t_, tile_bytes(srcA, 0x10000 + s_))
        for s_, t_ in sel:
            assert tile_bytes(dstA, 0x10000 + t_) == \
                tile_bytes(srcA, 0x10000 + s_), \
                f"select readback mismatch at bank-1 0x{t_:04X}"
        print(f"select: {len(sel)} bank-1 tiles placed")
        for n, buf in zip(GROUP_A, dstA):
            path = os.path.join(args.outdir, f"vm3.{n}m")
            open(path, "wb").write(buf)
            print(f"  wrote vm3.{n}m sha1 "
                  f"{hashlib.sha1(bytes(buf)).hexdigest()}")

    # companion-overlay art: bank-1 pairs, group A — chains on whatever
    # group-A members exist so far (effect-tail/select passes)
    if args.overlay_tiles:
        ovl = json.load(open(args.overlay_tiles))
        srcA = load_group(z2, "vs2", GROUP_A)
        prev = os.path.join(args.outdir, f"vm3.{GROUP_A[0]}m")
        if os.path.exists(prev):
            dstA = [bytearray(open(os.path.join(args.outdir,
                    f"vm3.{nm}m"), "rb").read()) for nm in GROUP_A]
        else:
            dstA = [bytearray(s) for s in load_group(za, "vm3", GROUP_A)]
        for s_, t_ in ovl:
            write_tile(dstA, 0x10000 + t_, tile_bytes(srcA, 0x10000 + s_))
        for s_, t_ in ovl:
            assert tile_bytes(dstA, 0x10000 + t_) == \
                tile_bytes(srcA, 0x10000 + s_), \
                f"overlay readback mismatch at bank-1 0x{t_:04X}"
        print(f"overlay: {len(ovl)} bank-1 tiles placed")
        for n, buf in zip(GROUP_A, dstA):
            path = os.path.join(args.outdir, f"vm3.{n}m")
            open(path, "wb").write(buf)
            print(f"  wrote vm3.{n}m sha1 "
                  f"{hashlib.sha1(bytes(buf)).hexdigest()}")

    spec = {"delta": DELTA, "band_lo": BAND_LO, "band_hi": BAND_HI,
            "dst_bank_word": bank_word(DST_BANK),
            "src_bank_word": bank_word(SRC_BANK),
            "placed": [lo_dst, hi_dst]}
    json.dump(spec, open(os.path.join(args.outdir, "remap_spec.json"), "w"),
              indent=1)
    print(f"wrote remap_spec.json: {spec}")


if __name__ == "__main__":
    main()
