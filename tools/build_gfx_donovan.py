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


# REFUSE TO RUN WITH ASSERTIONS DISABLED (14z-94, GitHub #79). This file's
# collision, band-bound and placement checks are `assert` statements, and
# `python -O` / PYTHONOPTIMIZE=1 removes them ENTIRELY — an invalid graphics
# placement would then exit 0, and the gate that is supposed to catch it would
# print PASS because the expected raise never happened. Converting each assert
# would fix today's checks and not tomorrow's; refusing the mode fixes the
# class. A safety check that can be switched off by an environment variable is
# not a safety check.
if not __debug__:
    raise SystemExit(
        f"{__file__}: refusing to run under python -O / PYTHONOPTIMIZE — its "
        f"safety checks are assertions and would be stripped (GitHub #79)")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gfx_tiles import GROUP_A, GROUP_B, GROUP_C, bank_word, cell_at, \
    tile_bytes, write_tile  # noqa: E402
from _minitoml import loads as toml_loads  # noqa: E402

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
# 14z-67 (D4): the constants above are DONOVAN'S rows of the ratified
# 3-tenant layout (build/manifest/gfx_layout3.toml) and are now only the
# fallback for a build run without --layout/--tenant. Any other tenant
# MUST resolve its band/delta through the layout manifest — and a
# delta-0 tenant (H/P: native codes) takes the delta0 placement path:
# ALL inventory tiles placed at native codes (band + scatter; there is
# no effect map because nothing moves), writes asserted strictly below
# Donovan's frozen SAFE_LO ceiling (disjointness by interval, the
# tests/test_gfx_layout3.sh invariant).


def check_profile_fields(prof, path):
    """The [profile] block must AGREE with what this builder implements
    (14z-94, GitHub #87).

    bank4_word/bank5_word/collision_rule read as executable layout policy and
    were consumed by nothing: the bank words are computed by
    gfx_tiles.bank_word() and the collision rule is hardcoded in place() —
    whose docstring even cites "gfx_layout3.toml's collision_rule" while not
    reading it. Editing any of them changed no output and invalidated no
    build, so the repository recorded policy the artifact producer did not
    enforce.

    These are checked rather than obeyed, deliberately. The values are baked
    into frozen references (the m3a/stock fingerprints), so making them
    genuinely settable would be a way to silently produce a non-reproducible
    build. Asserting instead makes the manifest TRUE — an edit now fails
    loudly rather than doing nothing — without giving it the power to move a
    frozen byte. If a value here ever needs to change, the change belongs in
    both places, with a re-measure.
    """
    for bank, key in ((4, "bank4_word"), (5, "bank5_word")):
        if key in prof and int(prof[key]) != bank_word(bank):
            sys.exit(
                f"{path}: [profile].{key} = {int(prof[key]):#06x} but this "
                f"build emits {bank_word(bank):#06x} for bank {bank} "
                f"(gfx_tiles.bank_word). The manifest and the builder "
                f"disagree about the OBJ y-word; fix both together — bit 15 "
                f"is the sprite-list terminator, so a wrong bank word ends "
                f"the list at the first tenant sprite.")
    rule = prof.get("collision_rule")
    if rule is not None and rule != "same-source-or-fail":
        sys.exit(
            f"{path}: [profile].collision_rule = {rule!r}, but place() "
            f"implements 'same-source-or-fail' and nothing else. Selecting "
            f"another policy here would change no behaviour, so it is "
            f"refused rather than ignored.")
    print(f"  profile fields agree with the builder "
          f"(bank4 {bank_word(4):#06x}, bank5 {bank_word(5):#06x}, "
          f"collision {rule or 'same-source-or-fail'})")


def check_scatter_bounds(codes, row, path):
    """A delta-0 tenant's native codes must lie inside the bounds its layout
    row DECLARES (14z-94, GitHub #87).

    scatter_lo/scatter_hi documented the tenant's scattered low tiles — 25
    for huitzil, 51 for pyron including 0xA42C, "the highest H∪P native
    code" — and were read by nothing: the delta-0 path places every
    inventoried tile at its native code without consulting them. So the
    numbers could be wrong, or the inventory could grow past them, with
    nothing to notice.

    The union with the main band is the actual claim the layout makes: every
    placed code is either in the tenant's band or in its declared scatter.
    """
    if "scatter_lo" not in row or "scatter_hi" not in row:
        return
    slo, shi = int(row["scatter_lo"]), int(row["scatter_hi"])
    blo, bhi = int(row["band_lo"]), int(row["band_hi"])
    stray = [c for c in codes
             if not (slo <= c <= shi or blo <= c <= bhi)]
    if stray:
        sys.exit(
            f"{path}: tenant {row['name']} places {len(stray)} tile code(s) "
            f"outside BOTH its band {blo:#06x}-{bhi:#06x} and its declared "
            f"scatter {slo:#06x}-{shi:#06x}: "
            + ", ".join(f"{c:#06x}" for c in sorted(stray)[:8])
            + ("..." if len(stray) > 8 else "")
            + f"\n  The layout row no longer describes what is placed. "
              f"Re-measure the scatter bounds rather than widening them to "
              f"fit — they are what the disjointness argument rests on.")
    n_scatter = sum(1 for c in codes if slo <= c <= shi and not blo <= c <= bhi)
    print(f"  scatter bounds hold: {n_scatter} code(s) in "
          f"{slo:#06x}-{shi:#06x}, the rest inside the band")


def load_group(z, prefix, group):
    out = []
    for n in group:
        data = z.read(f"{prefix}.{n}m")
        print(f"  read {prefix}.{n}m sha1 {hashlib.sha1(data).hexdigest()}")
        out.append(data)
    return out


def place(dst, written, idx, tile, kind, sidx, pass_name):
    """same-source-or-fail — gfx_layout3.toml's collision_rule, generalized
    to EVERY pass (14z-83 S1; it was implemented on 2 of 8). A destination
    written twice must carry byte-identical tiles: identical -> benign
    skip (returns False), different -> a NAMED build error. `written` is a
    dict idx -> (kind, sidx) so the error names both provenances — that
    dict is also the cross-link ledger the chain mode consumes (S2).

    Solo-build bit-identity: no solo pass collides with different bytes
    today (tests/audit_gfx_merged_census.sh, intra-tenant = 0), so this
    changes no output byte on any existing path — it converts silent
    impossibilities into loud errors."""
    if idx in written:
        assert tile_bytes(dst, idx) == tile, (
            f"{pass_name}: dst 0x{idx:05X} collides with DIFFERENT bytes "
            f"(prior {written[idx][0]}:0x{written[idx][1]:05X}, "
            f"new {kind}:0x{sidx:05X}) — same-source-or-fail")
        return False
    write_tile(dst, idx, tile)
    written[idx] = (kind, sidx)
    return True


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
    ap.add_argument("--strip-tiles",
                    help="strip_tiles/<char>.json (14z-71): vs2 BANK-1 tiles "
                         "copied into group C bank 4 at code+shift. The "
                         "type-4 list handler HARDCODES its bank word "
                         "(ori.w #$2000 = bank 1) and biases codes by "
                         "+0x3800, so a tenant's procedural strips cannot "
                         "reach group C through the record path at all — "
                         "their art is fetched from a bank our port never "
                         "populated. A ported copy of that handler supplies "
                         "bank 4 and the shifted bias; this places the art "
                         "it will then address.")
    ap.add_argument("--effect-c5",
                    help="effect_c5.json from the generator (14z-67): the "
                         "companion-effect records' full bank-1 code list, "
                         "kept NATIVE — art copied vs2 group A -> group C "
                         "BANK 5 at 0x10000+code; the ported piece "
                         "spawners' bank setters flip to #$3000 on the "
                         "program side. Group-C mode only")
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
    ap.add_argument("--chain",
                    help="a PRIOR link's outdir (14z-83 S2): group-C "
                         "members start from its vsw simms instead of "
                         "zeros, group-A members from its vm3 copies, and "
                         "its gfx_written.json seeds the collision ledger "
                         "— so cross-LINK collisions get the same "
                         "same-source-or-fail verdict place() gives "
                         "cross-pass ones, and the last link's members "
                         "carry every link's tiles. The ledger file is "
                         "REQUIRED (the marker of a completed link): a "
                         "mistyped path must fail loudly, never silently "
                         "build solo and wipe the prior link. Group-C "
                         "mode only")
    ap.add_argument("--tenant",
                    help="tenant.json from gen_donovan_patch.py. Supplies the "
                         "destination gfx bank, so this half cannot drift "
                         "from the port's target id — it used to be the "
                         "constant DST_BANK=2 and a build with the tenant "
                         "moved elsewhere still placed Jedah's bank row")
    ap.add_argument("--layout",
                    default=os.path.join(os.path.dirname(
                        os.path.dirname(os.path.abspath(__file__))),
                        "build/manifest/gfx_layout3.toml"),
                    help="the ratified 3-tenant group-C layout manifest; "
                         "the tenant's band/delta resolve from its row "
                         "(keyed by tenant.json's id)")
    args = ap.parse_args()
    os.makedirs(args.outdir, exist_ok=True)

    global DST_BANK, DELTA, BAND_LO, BAND_HI, SRC_BANK, SAFE_LO, SAFE_HI
    layout_row = None
    frozen_ceiling = SAFE_LO   # Donovan's safe window floor: the delta-0
    #                            write ceiling (disjointness by interval)
    if args.tenant:
        _t = json.load(open(args.tenant))
        DST_BANK = int(_t.get("gfx_bank", DST_BANK))
        print("  tenant %s id %#04x -> gfx bank %d (bank word %#06x)"
              % (_t.get("name"), _t["id"], DST_BANK, bank_word(DST_BANK)))
        lay = toml_loads(open(args.layout).read())
        rows = {r["name"]: r for r in lay["tenant"]}
        frozen_ceiling = rows["donovan"]["safe_lo"]
        # resolve by NAME: band/delta are per-CHARACTER facts; the id
        # differs per track (Donovan is 0x0F on stock, 0x13 on WIDE)
        layout_row = rows.get(_t.get("name"))
        if layout_row is None:
            sys.exit(f"build_gfx: tenant {_t.get('name')!r} has no row in "
                     f"{args.layout} — the 3-tenant layout must be "
                     f"extended (and re-measured) before its gfx can build")
        SRC_BANK = int(layout_row["src_bank"])
        assert SRC_BANK == 3, \
            "source reads index vs2 group B at bank 3's in-group offset " \
            "(0x10000+code); a non-bank-3 tenant needs that generalized " \
            "deliberately, not silently"
        DELTA = int(layout_row["delta"])
        BAND_LO, BAND_HI = int(layout_row["band_lo"]), int(layout_row["band_hi"])
        print("  layout row %s: band %#06x-%#06x delta %+#x src bank %d"
              % (layout_row["name"], BAND_LO, BAND_HI, DELTA, SRC_BANK))
        # Donovan's row must equal the frozen constants — the m3a/stock
        # references are only reproducible if this resolution is a no-op
        # for him, on both tracks. Assert rather than trust.
        if _t.get("name") == "donovan":
            assert (DELTA, BAND_LO, BAND_HI) == (0x2750, 0x863F, 0xC2EF), \
                "layout donovan row drifted from the frozen constants"
        # 14z-83 S1: the safe window is manifest-driven like band/delta
        # (it was the last module-constant pair) — with the same frozen-
        # drift assert, since the m3a reference bakes these values.
        if "safe_lo" in layout_row:
            assert (int(layout_row["safe_lo"]), int(layout_row["safe_hi"])) \
                == (SAFE_LO, SAFE_HI), \
                "layout safe window drifted from the frozen constants"
            SAFE_LO = int(layout_row["safe_lo"])
            SAFE_HI = int(layout_row["safe_hi"])
        check_profile_fields(lay.get("profile") or {}, args.layout)
    # WIDE group C (banks 4-5): the tenant's band+shelf keep their in-group
    # tile indices (code+DELTA, unchanged from the host-band layout, so the
    # RECORDS need no rewrite at all) but the tile DATA goes into the four
    # appended vsw simms instead of vsav's group B, which therefore stays
    # PRISTINE — the host's fighter/select-portrait art comes back wholesale.
    group_c = DST_BANK >= 4

    inv = json.load(open(args.tiles))
    if DELTA == 0:
        # delta-0 tenant (14z-67 layout): EVERY inventoried tile places at
        # its native code — band and scatter alike; no per-record effect
        # map exists because no code moves. The one placement constraint
        # is the interval disjointness the layout rests on: strictly
        # below Donovan's frozen safe window.
        band = sorted(inv)
        print(f"inventory: {len(inv)} tiles, all placed at native codes "
              f"(delta-0 tenant)")
        assert not args.effects, \
            "delta-0 tenant: an effect map must not exist (nothing moves)"
        if layout_row is not None:
            check_scatter_bounds(band, layout_row, args.layout)
    else:
        band = sorted(t for t in inv if BAND_LO <= t <= BAND_HI)
        skipped = len(inv) - len(band)
        print(f"inventory: {len(inv)} tiles, {len(band)} in main band "
              f"({skipped} effect/low tiles handled by the per-record map, "
              f"not this tool)")
    lo_dst, hi_dst = band[0] + DELTA, band[-1] + DELTA
    if DELTA == 0:
        assert hi_dst < frozen_ceiling, \
            f"delta-0 placement reaches 0x{hi_dst:04X} >= frozen ceiling " \
            f"0x{frozen_ceiling:04X} (Donovan's SAFE_LO) — layout violated"
    else:
        assert SAFE_LO <= lo_dst and hi_dst <= SAFE_HI, \
            f"placement 0x{lo_dst:04X}-0x{hi_dst:04X} outside safe window"
    assert DELTA % 16 == 0, "delta must be 16-aligned (block row-wrap)"

    z2 = zipfile.ZipFile(os.path.join(args.romdir, "vsav2.zip"))
    za = zipfile.ZipFile(os.path.join(args.romdir, "vsav.zip"))
    src = load_group(z2, "vs2", GROUP_B)      # bank 3 = group B (>=0x20000)
    chain_ledger = {"C": [], "B": [], "A": []}
    if args.chain:
        assert group_c, "--chain is a group-C mechanism (the merge is " \
                        "WIDE-only); a stock-track chain has no design"
        assert os.path.abspath(args.chain) != os.path.abspath(args.outdir), \
            "--chain dir must not be the outdir"
        led_path = os.path.join(args.chain, "gfx_written.json")
        assert os.path.exists(led_path), \
            f"--chain {args.chain} has no gfx_written.json — not a " \
            "completed link (a wrong path here would silently wipe it)"
        print(f"  chain {led_path} sha1 {hashlib.sha1(open(led_path, 'rb').read()).hexdigest()}")
        chain_ledger.update(json.load(open(led_path)))
    if group_c:
        if args.chain:
            # continue the prior link's members; "untouched == prior
            # link's bytes" becomes the invariant
            dst_orig = []
            for n in GROUP_C:
                p = os.path.join(args.chain, f"vsw.{n}m")
                data = open(p, "rb").read()
                print(f"  chain vsw.{n}m sha1 "
                      f"{hashlib.sha1(data).hexdigest()}")
                dst_orig.append(data)
        else:
            # fresh zero simms — group C ships zero-filled from
            # build_wide_romset.py, so "untouched == zero" is the invariant
            dst_orig = [bytes(0x400000) for _ in GROUP_C]
    else:
        dst_orig = load_group(za, "vm3", GROUP_B)  # bank 2 = group B too
    dst = [bytearray(s) for s in dst_orig]

    # src bank 3 -> group-B index = 0x10000 + code
    # dst bank 2 -> group-B index = 0x00000 + code
    # idx -> (src kind, src idx): the collision ledger, seeded with the
    # prior link's entries so a cross-link collision is judged by place()
    # exactly like a cross-pass one (bytes are compared against the dst
    # buffer, which carries the prior link's tiles)
    written = {i: (k, s) for i, k, s in chain_ledger["C"]}
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
        place(dst, written, code + DELTA, tile_bytes(src, 0x10000 + code),
              "vs2B", 0x10000 + code, "band")

    # effect tiles: explicit (src, dst) pairs from the generator's
    # shelf-pack of the mixed-record shared-effect blocks
    eff_pairs = []
    if args.effects:
        eff_pairs = json.load(open(args.effects))
        for s, t in eff_pairs:
            assert SAFE_LO <= t <= SAFE_HI, f"effect dst 0x{t:04X} unsafe"
            place(dst, written, t, tile_bytes(src, 0x10000 + s),
                  "vs2B", 0x10000 + s, "effects")
        print(f"effects: {len(eff_pairs)} tiles placed from effect_map")

    # 14z-71: PROCEDURAL-STRIP art (the beam's stretching middle). Sourced
    # from vs2 BANK 1 — not the tenant's bank-3 band — because the type-4
    # handler composes its own bank word instead of taking the object's.
    # Destination is code+SHIFT inside group C bank 4, and the SAME shift is
    # baked into the ported handler's code bias, so no sprite list is edited.
    if args.strip_tiles and group_c and json.load(open(args.strip_tiles))["tiles"]:
        st = json.load(open(args.strip_tiles))
        shift = int(st["shift"], 16) if isinstance(st["shift"], str) \
            else st["shift"]
        srcA1 = load_group(z2, "vs2", GROUP_A)
        assert shift % 16 == 0, "strip shift must be 16-aligned (row wrap)"
        for c in st["tiles"]:
            d1 = c + shift
            assert d1 < 0x10000, \
                f"strip dst 0x{d1:05X} leaves group C bank 4"
            place(dst, written, d1, tile_bytes(srcA1, 0x10000 + c),
                  "vs2A", 0x10000 + c, "strip")
        print(f"strip tiles: {len(st['tiles'])} vs2 bank-1 tiles copied to "
              f"group C bank 4 at +{shift:#06x} "
              f"(0x{min(st['tiles'])+shift:04X}-0x{max(st['tiles'])+shift:04X})")
    elif args.strip_tiles and json.load(open(args.strip_tiles))["tiles"]:
        raise AssertionError("strip_tiles has tiles but the build is not "
                             "group-C mode — the ported handler's bank 4 "
                             "would serve zeros")

    # companion-effect art in bank 5 (14z-67, the ping-#7 fuchsia class):
    # the records' NATIVE bank-1 codes, art from vs2 group A. Placed
    # FIRST among the bank-5 passes; a later pass colliding on a code
    # asserts loudly unless the bytes agree (same-source rule).
    eff5 = []
    srcA5 = None
    if args.effect_c5 and group_c:
        eff5 = json.load(open(args.effect_c5))
        srcA5 = load_group(z2, "vs2", GROUP_A)
        for c in eff5:
            place(dst, written, 0x10000 + c, tile_bytes(srcA5, 0x10000 + c),
                  "vs2A", 0x10000 + c, "effect-c5")
        print(f"effect-c5: {len(eff5)} native bank-1 tiles copied to "
              f"group C upper bank")
    elif args.effect_c5:
        e5j = json.load(open(args.effect_c5))
        assert not e5j, ("effect_c5.json has tiles but the build is not "
                        "group-C mode — the spawner bank flip would dangle")

    # bank-5 select art (option A, 14z-62j): NATIVE bank-1 codes copied
    # into group C's upper bank, disjoint from the band/shelf by
    # construction (band in-group indices are < 0x10000).
    b5 = []
    if args.select_bank5 and group_c:
        b5 = json.load(open(args.select_bank5))
        if srcA5 is None:
            srcA5 = load_group(z2, "vs2", GROUP_A)
        for c in b5:
            # same-source rule: an effect-c5 tile may already have placed
            # this code from the SAME vs2 group A — place() skips it
            place(dst, written, 0x10000 + c, tile_bytes(srcA5, 0x10000 + c),
                  "vs2A", 0x10000 + c, "select-bank5")
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
            place(dst, written, 0x10000 + c,
                  tile_bytes(srcA_host, 0x10000 + c),
                  "vsavA", 0x10000 + c, "wheel-host")
        for c in wb5["vs2"]:
            place(dst, written, 0x10000 + c, tile_bytes(srcA5, 0x10000 + c),
                  "vs2A", 0x10000 + c, "wheel-vs2")
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
    for c in eff5:
        assert tile_bytes(dst, 0x10000 + c) == \
            tile_bytes(srcA5, 0x10000 + c), \
            f"effect-c5 readback mismatch at 0x{c:04X}"
    for c in wb5["host"]:
        assert tile_bytes(dst, 0x10000 + c) == \
            tile_bytes(srcA_host, 0x10000 + c), \
            f"wheel host readback mismatch at 0x{c:04X}"
    for c in wb5["vs2"]:
        assert tile_bytes(dst, 0x10000 + c) == \
            tile_bytes(srcA5, 0x10000 + c), \
            f"wheel vs2 readback mismatch at 0x{c:04X}"
    if args.strip_tiles and group_c and json.load(open(args.strip_tiles))["tiles"]:
        _st = json.load(open(args.strip_tiles))
        _sh = int(_st["shift"], 16) if isinstance(_st["shift"], str) \
            else _st["shift"]
        _sa = load_group(z2, "vs2", GROUP_A)
        for c in _st["tiles"]:
            assert tile_bytes(dst, c + _sh) == tile_bytes(_sa, 0x10000 + c), \
                f"strip readback mismatch at 0x{c:04X}"

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

    # group-A passes share one ledger: three passes write the same four
    # members (chaining through the outdir files), and a cross-pass
    # different-bytes overwrite was SILENT before place() (each pass
    # readback-verified only its own pairs) — 14z-83 S1. Chained links
    # (S2) pre-copy the prior link's vm3 group-A members into the outdir
    # so the passes' existing file-chaining carries them cumulatively.
    writtenA = {i: (k, s) for i, k, s in chain_ledger["A"]}
    if args.chain:
        prev0 = os.path.join(args.chain, f"vm3.{GROUP_A[0]}m")
        if os.path.exists(prev0):
            for nm in GROUP_A:
                data = open(os.path.join(args.chain, f"vm3.{nm}m"),
                            "rb").read()
                open(os.path.join(args.outdir, f"vm3.{nm}m"),
                     "wb").write(data)
            print("  chain: prior link's group-A members carried forward")
    # effect-tail art: vs2 bank-1 blocks placed at vsav bank-1 anchors
    if args.effect_tail:
        et = json.load(open(args.effect_tail))
        srcA0 = load_group(z2, "vs2", GROUP_A)
        # base = the outdir's members when they exist (a chained link's
        # carried-forward copies); pristine vsav otherwise — solo builds
        # start this pass with an empty outdir, so nothing changes there
        if os.path.exists(os.path.join(args.outdir, f"vm3.{GROUP_A[0]}m")):
            dstA0 = [bytearray(open(os.path.join(args.outdir,
                     f"vm3.{nm}m"), "rb").read()) for nm in GROUP_A]
        else:
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
            # per-tenant variant-slot art (14z-67): a tenant's OWN HUD
            # art rides place_variant_slot_<name>, scoped so another
            # tenant's build (and the frozen m3a reference) is untouched
            if layout_row is not None:
                _tk = "place_variant_slot_" + layout_row["name"]
                places.update(et.get(_tk, {}))
                if et.get(_tk):
                    print(f"effect-tail: {len(et[_tk])} {_tk} place(s) "
                          f"added")
        for k, v in places.items():
            tt, bx, by = k.split(",")
            t = int(tt, 16); anchor = int(v, 16)
            for dy in range(int(by)):
                for dx in range(int(bx)):
                    s_ = cell_at(t, dx, dy)
                    d_ = cell_at(anchor, dx, dy)
                    place(dstA0, writtenA, 0x10000 + d_,
                          tile_bytes(srcA0, 0x10000 + s_),
                          "vs2A", 0x10000 + s_, "effect-tail")
                    n += 1
        for k, v in places.items():
            tt, bx, by = k.split(",")
            t = int(tt, 16); anchor = int(v, 16)
            for dy in range(int(by)):
                for dx in range(int(bx)):
                    s_ = cell_at(t, dx, dy)
                    d_ = cell_at(anchor, dx, dy)
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
        if os.path.exists(os.path.join(args.outdir, f"vm3.{GROUP_A[0]}m")):
            # chain on the members written so far (this run's effect-tail
            # pass, or a chained link's carried-forward copies)
            dstA = [bytearray(open(os.path.join(args.outdir,
                    f"vm3.{nm}m"), "rb").read()) for nm in GROUP_A]
        else:
            dstA = [bytearray(s) for s in load_group(za, "vm3", GROUP_A)]
        for s_, t_ in sel:
            place(dstA, writtenA, 0x10000 + t_,
                  tile_bytes(srcA, 0x10000 + s_),
                  "vs2A", 0x10000 + s_, "select")
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
            place(dstA, writtenA, 0x10000 + t_,
                  tile_bytes(srcA, 0x10000 + s_),
                  "vs2A", 0x10000 + s_, "overlay")
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

    # the write ledger (14z-83 S1): every destination this run touched,
    # with its source provenance — the chain mode (S2) loads a prior
    # link's ledger so cross-LINK collisions get the same
    # same-source-or-fail treatment place() gives cross-PASS ones
    ledger_group = "C" if group_c else "B"
    ledger = {ledger_group: sorted([i, k, s]
                                   for i, (k, s) in written.items()),
              "A": sorted([i, k, s] for i, (k, s) in writtenA.items())}
    json.dump(ledger, open(os.path.join(args.outdir, "gfx_written.json"),
                           "w"))
    print(f"wrote gfx_written.json ({len(written)} group-{ledger_group} + "
          f"{len(writtenA)} group-A entries)")

    spec = {"delta": DELTA, "band_lo": BAND_LO, "band_hi": BAND_HI,
            "dst_bank_word": bank_word(DST_BANK),
            "src_bank_word": bank_word(SRC_BANK),
            "placed": [lo_dst, hi_dst]}
    json.dump(spec, open(os.path.join(args.outdir, "remap_spec.json"), "w"),
              indent=1)
    print(f"wrote remap_spec.json: {spec}")


if __name__ == "__main__":
    main()
