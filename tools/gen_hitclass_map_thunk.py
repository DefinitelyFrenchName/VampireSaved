#!/usr/bin/env python3
"""gen_hitclass_map_thunk.py — generate the hit-class map-extension thunk
body (14z-82b) from the two reference opcode images. NEVER hand-type it.

THE DEFECT. vsavj's projectile-pool hit sweep (the seven-dispatcher
cluster at PRG:0x1A770-0x1A886) maps BOTH colliding objects' type bytes
through ONE shared byte map:

    0x1A888: move.b (4,PC,D0.w),d0 ; rts     -- map at 0x1A88E, 64 entries

vs2's sibling (dispatcher 0x1919A, routine 0x19292, map 0x19298) carries
the same 0-58 prefix, its own 59-63 values (see build()), then 16
more — entries 64-79 — for its extended projectile types. vsavj stops at 63, so a ported object of type >= 64
in the $FF94xx pool that lands a hit indexes past the map into code
bytes (map[64] = the 0x4E of the following rts), takes a garbage word-
table displacement and jumps wild — the f7997 vec3, LATENT IN BOTH
FROZEN TENANT BUILDS (pyron's satellite type 64 measured crashing
pyron20 itself; huitzil spawns 68/72 into the same pool; donovan's
59-63 fit and he is safe).

THE BODY (94 bytes): byte-identical semantics to vanilla for indices
0-63, vs2's own values for 64-79, and a LOUD planted ILLEGAL for >= 80
(word compare — vs2's map also ends at 79, so nothing defined lives
above; vanilla's behavior there was a silent garbage read, and loud
beats silent):

    +0   0C40 0050   cmpi.w #80,d0        ; CCR overwritten below
    +4   6456        bcc.s  +0x56 -> ILLEGAL
    +6   103B 0004   move.b (4,PC,D0.w),d0  ; map at +12, same shape
    +10  4E75        rts                    ;   as the vanilla routine
    +12  <64 vanilla map bytes><16 vs2 extension bytes>
    +92  4AFC        ILLEGAL

Entered by bsr (7 callers, 4 bsr.w + 3 bsr.s, all inside the cluster);
the site patch is `jmp body` over the routine's own 6 bytes, so the
return path and stack are untouched (ghost-clean) and the final CCR on
the normal path is the loaded byte's NZ — exactly vanilla's.

SAFETY ARGUMENT, printed and asserted below:
  * the two images' 0-58 map bytes are IDENTICAL (vanilla's true
    domain — its type table has 59 entries; 59-63 may differ and
    vanilla's bytes win, see build());
  * the seven word tables' entries reachable from the extension's values
    are byte-identical between the images where the extension uses them
    (values 0x02..0x0E -> entries 1-7 identical in the first cluster
    table; value 0x00 -> each engine's default entry, verified to be a
    plain rts in vsavj);
  * vs2's own map ends at entry 79 (the rts opcode follows).

Usage:
    python3 tools/gen_hitclass_map_thunk.py \
        build/out/vsavj_opcodes.bin build/out/vsav2_opcodes.bin
Prints the thunk_hex for the [[site_thunk]] row and the SHA-1s of what
it read. tests/test_hitclass_map_thunk.sh reconstructs the committed row
from the ROMs and fails on any drift.
"""

import hashlib
import sys

VJ_ROUTINE = 0x1A888          # move.b (4,PC,D0.w),d0 ; rts
VJ_MAP = 0x1A88E
VS2_MAP = 0x19298
VJ_WORDTAB = 0x1A7A0          # first cluster dispatcher's 8-word table
VS2_WORDTAB = 0x191AA
N_VAN = 64
N_EXT = 16                    # vs2 entries 64..79 (its map is
                              # 80 entries; types stop at 75)
BOUND = N_VAN + N_EXT         # 80


def build(vj, vs2):
    assert vj[VJ_ROUTINE:VJ_ROUTINE + 6] == bytes.fromhex("103B00044E75"), \
        "vsavj routine bytes moved — wrong image or wrong address"
    van = vj[VJ_MAP:VJ_MAP + N_VAN]
    shared = vs2[VS2_MAP:VS2_MAP + N_VAN]
    # VANILLA's true domain is 0-58 (its 0x54470 table has 59 types);
    # 59-63 are unreachable padding in vsavj. The two engines must agree
    # on 0-58 EXACTLY; 59-63 are allowed to differ and vsavj's bytes WIN
    # (measured 14z-82b: vs2 populates 61/62 = 0x0E/0x04 — hit classes
    # for DONOVAN's satellite types — where vsavj holds the do-nothing 0.
    # Keeping vanilla's zeros preserves donovan-m3a's shipped behavior
    # byte-for-byte; adopting vs2's values there would give Donovan's
    # type-61/62 projectile hits their vs2 reactions, which is a
    # maintainer decision recorded in STATE, not this tool's to make.)
    assert van[:59] == shared[:59], (
        "the two engines' 0-58 map bytes differ — the transplant "
        "premise fails; STOP and re-derive")
    ext = vs2[VS2_MAP + N_VAN:VS2_MAP + N_VAN + N_EXT]
    # vs2's map must END at 79: the routine's rts follows
    assert vs2[VS2_MAP + BOUND:VS2_MAP + BOUND + 2] == b"\x4e\x75", \
        "vs2 map does not end at entry 79 — bound drifted"
    # every extension value indexes a word-table entry that is
    # byte-identical between the images, or the default (entry 0), which
    # must be a plain rts in vsavj (map value 0 -> do-nothing reaction)
    for i, v in enumerate(ext):
        assert v % 2 == 0 and v <= 0x0E, f"ext[{64+i}] = {v:#x} out of shape"
        if v == 0:
            d = int.from_bytes(vj[VJ_WORDTAB:VJ_WORDTAB + 2], "big")
            assert vj[VJ_WORDTAB + d:VJ_WORDTAB + d + 2] == b"\x4e\x75", \
                "vsavj default entry is not a plain rts"
        else:
            a = vj[VJ_WORDTAB + v:VJ_WORDTAB + v + 2]
            b = vs2[VS2_WORDTAB + v:VS2_WORDTAB + v + 2]
            assert a == b, (f"word-table entry {v:#x} differs between the "
                            f"images ({a.hex()} vs {b.hex()}) — the "
                            f"extension value would dispatch a different "
                            f"handler here")
    body = (bytes.fromhex("0C400050")            # cmpi.w #80,d0
            + bytes.fromhex("6456")              # bcc.s -> ILLEGAL (+0x56)
            + bytes.fromhex("103B0004")          # move.b (4,PC,D0.w),d0
            + bytes.fromhex("4E75")              # rts
            + van + ext                          # 80 map bytes (even)
            + bytes.fromhex("4AFC"))             # ILLEGAL
    assert len(body) == 94
    # self-check the internal displacements
    assert body[4] == 0x64 and body[5] == (92 - 6)          # bcc target
    assert 12 + N_VAN + N_EXT == 92
    return body


def main():
    vj_p, vs2_p = sys.argv[1], sys.argv[2]
    vj = open(vj_p, "rb").read()
    vs2 = open(vs2_p, "rb").read()
    for p, img in ((vj_p, vj), (vs2_p, vs2)):
        print(f"# {p} sha1 {hashlib.sha1(img).hexdigest()}", file=sys.stderr)
    body = build(vj, vs2)
    print(f"# body {len(body)} bytes; map bound {BOUND}; "
          f"old_hex 103b00044e75 at {VJ_ROUTINE:#x}", file=sys.stderr)
    print(body.hex())


if __name__ == "__main__":
    main()
