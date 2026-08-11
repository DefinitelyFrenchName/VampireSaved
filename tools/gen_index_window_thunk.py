#!/usr/bin/env python3
"""gen_index_window_thunk.py — the (b') thunk body (14z-79).

Emits the `thunk_hex` for the `[[site_thunk]]` that covers the OUT-OF-RANGE
INDEX WINDOW of vsavj's sub-state dispatcher at `PRG:0x018460`.

THE DEFECT. vsavj's table at `0x018468` has 80 entries; vsav2's twin
(`0x016D34`, dispatcher `0x016D2C`) has 84. A ported character carries vs2's
sub-state indices verbatim, so entries 80-83 read the words of the NEXT
dispatcher (`323b 0006 4efb 1002` at `0x018508`) as offsets:

    80  0x323B -> 0x01B6A3  ODD   -> vec3                       LOUD
    81  0x0006 -> 0x01846E  the table itself -> watchdog reset  LOUD
    82  0x4EFB -> 0x01D363  ODD   -> vec3    Phobos Plasma Trap LOUD
    83  0x1002 -> 0x01946A  real code -> WRONG ROUTINE          SILENT
                                        Phobos Reflect Wall

Fix (b'), maintainer-approved for the full 80-83 window: hook the dispatcher,
run vs2's handler INLINE for those four indices, leave every other index on
the vanilla path. Legacy-safe by IMPOSSIBILITY, not by a deadness measurement:
vanilla reaching 80-83 crashes today, so no legacy behaviour can depend on the
branch we add. (That matters — the conservative static deadness scan saturated
at "all 80 entries used", and entries 82/83 are exactly the two with no
full-body twin, so the one-byte retarget that fixed Pyron's Cosmo is not
available here.)

TWO THINGS THAT SHAPE THE BODY, both measured in 14z-79.

1. THE TABLE READS THROUGH THE OPCODE VIEW. The original spec (STATE 14z-78)
   had the thunk read the table with `lea 0x018468,a0 / move.w (0,a0,d0.w),d1`.
   That is a DATA-space read, and CPS-2 decrypts only program-space fetches
   (docs/platform/gotchas.md "PC-relative reads are DECRYPTED reads"), so it
   returns ciphertext: 38 of the 80 legacy targets come out ODD. The body
   therefore carries its own copy of the index table and reads it
   PC-relatively; being inside a `code` op it re-encrypts with the body, so
   the read decrypts back to what we authored.

2. NO REGISTER NEED BE BORROWED. The normal path is a PC-relative read of the
   local table plus `jmp (2,PC,d1.w)` into a trampoline, so nothing is saved,
   nothing is restored, and NOTHING IS WRITTEN TO RAM on the legacy path. The
   spec's stack dance — and with it the `move.l (a7)+,(a7)` ordering question,
   whose failure mode was a silent 4-byte-per-dispatch leak — is deleted
   rather than verified.

   BUT D1 IS NOT FREE, and assuming it was cost a build. Each trampoline
   restores D1 to vanilla's offset before jumping (see the note at the
   trampoline emitter). A static finding that D1 is dead on ENTRY to all 80
   handlers is true and insufficient: the handlers `rts` into a downstream
   chain that the entry-level analysis never examined.

WHY TRAMPOLINES. `jmp (2,PC,d1.w)` reaches +/-32K from the jmp. The handlers
sit at `0x0186xx`; `hole_a` starts at `0x0BF6A0`, ~0xE4A48 away. So the local
table cannot hold rebased offsets to the real handlers — it holds offsets to
local `jmp <target>.l` trampolines instead. 80 entries collapse to 23 distinct
targets, so 23 trampolines suffice.

THE DANGER DISPATCH IS FOUR EXACT EQUALITY TESTS, not a range test, so a d0
that is merely >= 0xA0 cannot silently pick up entry 80's handler. Scope stays
exactly the approved 80-83: table `0x0185da`'s bad entries are all LOUD and
cleared by playtest, and `0x03975e`'s entry 10 sits behind a dispatcher
measured cold.

WHAT FALLS THROUGH, and why it is trapped rather than passed on. An ODD d0
faults identically here and in vanilla (both read a word at an odd address,
vector 3). An EVEN d0 >= 0xA8 is the one case where this thunk cannot
reproduce vanilla: vanilla reads the SIBLING dispatcher's table, we would read
our own trampolines, and a wild jump inside the thunk could land SILENTLY.
Nothing reaches it — vs2's table itself stops at entry 83, so no tenant
carries such an index, and vanilla crashes on it — but 6 bytes buy a defined
outcome instead of an undefined one, so it jumps to an odd address: vector 3,
the same LOUD signature vanilla gives entries 80 and 82.

Usage:
    python3 tools/gen_index_window_thunk.py <vsavj_opcodes.bin> <vsav2_opcodes.bin>
    python3 tools/gen_index_window_thunk.py ... --json      # machine-readable
    python3 tools/gen_index_window_thunk.py ... --quiet     # hex only

Both inputs are DECRYPTED OPCODE images (tools/cps2_decrypt.py). Passing the
zips, or the data views, is the mistake that silently returns nonsense — so
the layout assertions below are checked on every run and the SHA-1 of each
input is printed.
"""
import argparse
import hashlib
import json
import struct
import sys

# ── the vsavj site ────────────────────────────────────────────────────────
VJ_SITE = 0x018460          # move.w (6,PC,d0.w),d1   — the 6-byte site
VJ_JMP = 0x018464           # jmp    (2,PC,d1.w)
VJ_TABLE = 0x018468         # 80 words, offsets relative to itself
VJ_N = 80
VJ_NEXT_DISPATCH = 0x018508  # where the table ends and the sibling begins

# ── the vsav2 twin, and the four danger handlers ─────────────────────────
VS2_TABLE = 0x016D34
VS2_N = 84
# entry -> (vs2 handler address, body length). Addresses re-derived from the
# vs2 table below; these are the EXPECTED values and a mismatch is fatal.
VS2_DANGER = {80: (0x017024, 8), 81: (0x016F70, 8),
              82: (0x016FEC, 8), 83: (0x016F78, 12)}

DISPATCH_SHAPE = bytes.fromhex("323b00064efb1002")


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def w(img, a):
    return struct.unpack_from(">H", img, a)[0]


def sw(img, a):
    return struct.unpack_from(">h", img, a)[0]


def build(vj, v2):
    """Return (body_bytes, facts_dict). Raises SystemExit on any premise miss."""
    def need(cond, msg):
        if not cond:
            sys.exit(f"FATAL: {msg}")

    # ── premises, re-derived rather than trusted ─────────────────────────
    need(vj[VJ_SITE:VJ_SITE + 8] == DISPATCH_SHAPE,
         f"vsavj {VJ_SITE:#08x} is {vj[VJ_SITE:VJ_SITE+8].hex()}, not the "
         f"dispatcher shape {DISPATCH_SHAPE.hex()} — wrong image or wrong view")
    need(vj[VJ_NEXT_DISPATCH:VJ_NEXT_DISPATCH + 8] == DISPATCH_SHAPE,
         f"vsavj {VJ_NEXT_DISPATCH:#08x} is not the sibling dispatcher, so the "
         f"table is not {VJ_N} entries long")
    need(v2[VS2_TABLE - 8:VS2_TABLE] == DISPATCH_SHAPE,
         f"vsav2 {VS2_TABLE-8:#08x} is not the twin dispatcher")

    targets = [VJ_TABLE + sw(vj, VJ_TABLE + 2 * n) for n in range(VJ_N)]
    need(all(t % 2 == 0 for t in targets),
         "some vsavj targets are ODD — this is the DATA view, not the opcode "
         "view (docs/platform/gotchas.md: pc-relative reads are decrypted)")
    need(not any(VJ_TABLE <= t < VJ_NEXT_DISPATCH for t in targets),
         "a target lands inside the table itself")

    # the four vs2 danger bodies, taken from vs2's OWN table
    danger = {}
    for n, (exp_addr, blen) in sorted(VS2_DANGER.items()):
        addr = VS2_TABLE + sw(v2, VS2_TABLE + 2 * n)
        need(addr == exp_addr,
             f"vs2 entry {n} resolves to {addr:#08x}, expected {exp_addr:#08x}")
        body = v2[addr:addr + blen]
        need(body.endswith(b"\x4e\x75"),
             f"vs2 entry {n} body {body.hex()} does not end in rts")
        danger[n] = body

    # ── layout ──────────────────────────────────────────────────────────
    # Offsets are fixed by construction; every branch displacement is computed
    # from them and asserted in range, so a later edit cannot silently produce
    # a body whose branches miss.
    O_NORMAL = 0x06
    O_DANGER = 0x0E
    o = {}                              # label -> offset
    parts = []

    def put(hexs):
        parts.append(bytes.fromhex(hexs))

    def here():
        return sum(len(p) for p in parts)

    def disp8(frm, to):
        """8-bit branch displacement, measured from the byte after the opcode."""
        d = to - (frm + 2)
        need(-128 <= d <= 127, f"branch {frm:#x}->{to:#x} out of .s range")
        return "%02x" % (d & 0xFF)

    # Derived, not hardcoded, so editing any piece cannot silently misplace
    # the rest: 4+2 filter, 4+4 normal path, 4*(4+2) dispatch chain, 6 for
    # the out-of-scope trap, then the four bodies, the table, the trampolines.
    O_TRAP = O_DANGER + 4 * 6
    off = O_TRAP + 6
    for entry in (80, 81, 82, 83):
        o[entry] = off
        off += len(danger[entry])
    O_TABLE = off
    O_TRAMP = O_TABLE + 2 * VJ_N

    put("0c4000a0")                                   # +00 cmpi.w #$00A0,d0
    put("64" + disp8(0x04, O_DANGER))                 # +04 bcc.s  danger
    need(here() == O_NORMAL, "normal path is not at +0x06")
    # +06 move.w (<table>,PC,d0.w),d1 — PC base is the extension word, +0x08
    pcdisp = O_TABLE - 0x08
    need(0 <= pcdisp <= 0x7F, f"table pc-rel displacement {pcdisp:#x} > 127")
    put("323b00%02x" % pcdisp)
    put("4efb1002")                                   # +0a jmp (2,PC,d1.w)
    need(here() == O_DANGER, "danger path is not at +0x0e")
    # Four EXACT equality tests, not a range test. What falls through is
    # d0 >= 0xA0 that is neither 0xA0/A2/A4/A6: an ODD d0 (which vanilla also
    # faults on — the local read is at an odd address too, identical vec3), or
    # an even index >= 84. The latter is where vanilla and this thunk cannot
    # agree: vanilla reads the SIBLING dispatcher's table, we would read our
    # own trampolines, and a wild jump inside the thunk could land silently.
    # Neither is reachable — vs2's table itself stops at 83, so no tenant
    # carries such an index and vanilla crashes on it — but an undefined
    # outcome is not worth keeping when a defined one costs 6 bytes. Trap it
    # into an ODD address: vector 3, the same LOUD signature vanilla gives
    # entries 80 and 82, and one tests/test_crash_guard.sh already ground-
    # truths.
    for entry in (82, 83, 80, 81):
        put("0c4000%02x" % (2 * entry))
        put("67" + disp8(here(), o[entry]))
    need(here() == O_TRAP, f"trap is at {here():#x}, expected {O_TRAP:#x}")
    put("4ef900000001")                               # jmp $1 -> vec3, LOUD
    for entry in (80, 81, 82, 83):
        need(here() == o[entry],
             f"entry {entry} body is at {here():#x}, expected {o[entry]:#x}")
        put(danger[entry].hex())
    need(here() == O_TABLE, f"table is at {here():#x}, expected {O_TABLE:#x}")

    # The index table: entry n -> the offset of its trampoline, relative to the
    # PC base of the `jmp (2,PC,d1.w)` above (extension word at +0x0c, so +0x0e).
    #
    # EACH TRAMPOLINE RESTORES D1 TO VANILLA'S VALUE BEFORE JUMPING, and that
    # is load-bearing — measured, after a version without it diverged.
    #
    # A first cut left D1 holding the REBASED offset, on the strength of a
    # static finding that D1 is dead on entry to all 80 handlers. That finding
    # is true and it is not enough: the handlers `rts`, and what they return
    # into (0x01821A, a chain of five bsr.w) is a downstream consumer the
    # entry-level analysis never looked at. Result: every self-frozen legacy
    # log moved and two masked legacy replays grew a second divergent run —
    # systematic divergence on a site dispatched only 22 times per replay,
    # which is why a cycle-cost explanation never fitted. STATE 14z-78 called
    # this exactly right ("D1 must be left holding the table OFFSET — a
    # handler downstream may read it"); the entry-only measurement did not
    # license overriding it.
    #
    # `move.w #imm,d1` also reproduces vanilla's CCR exactly (N/Z from the
    # offset, V/C cleared, X untouched) and writes only D1's low word, just as
    # `move.w (mem),d1` does. So register and flag state at handler entry is
    # now bit-identical to vanilla and the deadness question stops mattering
    # at all — the safer construction, not the cleverer one.
    #
    # target <-> offset is a bijection (target = 0x018468 + offset), so one
    # trampoline per DISTINCT target carries one unambiguous vanilla offset.
    distinct = []
    for t in targets:
        if t not in distinct:
            distinct.append(t)
    jmp_base = 0x0A + 4
    for t in targets:
        off = (O_TRAMP + 10 * distinct.index(t)) - jmp_base
        need(0 < off <= 0x7FFF, f"rebased offset {off} out of 16-bit range")
        put("%04x" % off)
    need(here() == O_TRAMP, f"trampolines at {here():#x}, expected {O_TRAMP:#x}")
    for t in distinct:
        van_off = t - VJ_TABLE
        need(0 <= van_off <= 0xFFFF, f"vanilla offset {van_off} not a word")
        put("323c%04x" % van_off)                     # move.w #<vanilla off>,d1
        put("4ef9%08x" % t)                           # jmp <handler>.l

    body = b"".join(parts)
    return body, {
        "site": VJ_SITE,
        "old_hex": vj[VJ_SITE:VJ_SITE + 6].hex(),
        "n_entries": VJ_N,
        "n_distinct_targets": len(distinct),
        "distinct_targets": [f"{t:#08x}" for t in distinct],
        "table_off": O_TABLE,
        "tramp_off": O_TRAMP,
        "len": len(body),
        "danger": {n: {"vs2_addr": f"{VS2_DANGER[n][0]:#08x}",
                       "body": danger[n].hex()} for n in sorted(danger)},
        "thunk_hex": body.hex(),
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("vsavj_opcodes")
    ap.add_argument("vsav2_opcodes")
    ap.add_argument("--json", action="store_true", help="machine-readable")
    ap.add_argument("--quiet", action="store_true", help="print the hex only")
    a = ap.parse_args()

    vj = open(a.vsavj_opcodes, "rb").read()
    v2 = open(a.vsav2_opcodes, "rb").read()
    body, facts = build(vj, v2)
    facts["src"] = {a.vsavj_opcodes: sha1(vj), a.vsav2_opcodes: sha1(v2)}

    if a.quiet:
        print(facts["thunk_hex"])
        return
    if a.json:
        print(json.dumps(facts, indent=2))
        return

    print(f"read {a.vsavj_opcodes} sha1 {sha1(vj)}")
    print(f"read {a.vsav2_opcodes} sha1 {sha1(v2)}")
    print(f"site      {VJ_SITE:#08x}  old_hex {facts['old_hex']}  (patch = jmp)")
    print(f"table     {VJ_N} entries, {facts['n_distinct_targets']} distinct "
          f"targets")
    for n in sorted(facts["danger"]):
        print(f"  entry {n}  vs2 {facts['danger'][n]['vs2_addr']}  "
              f"{facts['danger'][n]['body']}")
    print(f"layout    code +0x00  table +{facts['table_off']:#04x}  "
          f"tramp +{facts['tramp_off']:#04x}  total {facts['len']} bytes")
    print()
    print(facts["thunk_hex"])


if __name__ == "__main__":
    main()
