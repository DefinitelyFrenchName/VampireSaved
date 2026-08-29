#!/bin/sh
# test_attract_roster.sh — THE ATTRACT-DEMO ROSTER, decoded from the ROM and
# frozen (14z-118, the ram.md audit). ci_static: needs ROMDIR (the decrypt
# cache), no build dir, no emulator, ~2 s.
#
# WHAT IT HOLDS. docs/game/atlas/ram.md had carried "Full attract demo
# roster: TODO — enumerate all demo matchups" since M0. The attract assigner
# at PRG:0x005BEA reads the demo counter at a5-0x61D6 (= RAM:$FF1E2A), masks
# it to #$e and doubles it, then reads an 8-entry x 4-byte table at
# PRG:0x005C08 — (P1 id, P2 id, venue.w) — into $782(a5)/$b82(a5)/$100(a5)
# (RAM:$FF8782 / $FF8B82 / $FF8100). The table is PC-relative, i.e. read
# through the OPCODE view (docs/GOTCHAS.md), inside the encrypted MB.
#
# MEASURED DYNAMICALLY 14z-118 on vanilla vsavj (build/attract_roster_trace_14z118.log,
# field_trace.lua over 40,000 attract frames): the eight matchups appear in
# table order, one per attract cycle (~3,470 frames apart), the counter
# stepping by 2 and wrapping at 16. Every base id appears exactly once per
# column. Consequence for the superset invariant: no tenant id can ever be
# featured by the demo — the ids are vanilla's own bytes, never patched.
#
# Sections:
#   1  the reader's instruction bytes at 0x005BEA-0x005C06 are as decoded
#   2  the table at 0x005C08 is exactly the frozen eight rows
#   3  NEGATIVE CONTROL: a copy with one id byte changed FAILS section 2
#
# Usage: ROMDIR=... tests/test_attract_roster.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:-}"
[ -n "$ROMDIR" ] || { echo "SKIP: ROMDIR unset (the decode needs the reference image)"; exit 0; }
. "$REPO/tests/lib/decrypt_cache.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
decrypt_view vsavj "$W/vj.bin" "$W/vjd.bin"

check() {  # check <opcodes.bin>  -> exit 0 if the roster decodes as frozen
python3 - "$1" <<'PY'
import sys
b = open(sys.argv[1], "rb").read()
# 1. the reader: move.b -$61d6(a5),d0 / andi.w #$e,d0 / add.w d0,d0 /
#    move.b $5c08(pc,d0.w),$782(a5) / move.b $5c09(pc,d0.w),$b82(a5) /
#    move.w $5c0a(pc,d0.w),$100(a5) / rts
# (bytes taken from the decrypted image at 14z-118, never hand-encoded: the
#  (d8,PC,Xn) displacements are 0x12/0x0d/0x08 from each extension word)
reader = bytes.fromhex("102d9e2a0240000ed040"      # move.b/andi/add
                       "1b7b00120782"              # move.b $5c08(pc,d0.w),$782(a5)
                       "1b7b000d0b82"              # move.b $5c09(pc,d0.w),$b82(a5)
                       "3b7b00080100"              # move.w $5c0a(pc,d0.w),$100(a5)
                       "4e75")
got = b[0x5BEA:0x5BEA + len(reader)]
if got != reader:
    print("FAIL: the attract assigner at 0x005BEA is not the decoded reader:", got.hex()); sys.exit(1)
print("  ok: reader at PRG:0x005BEA decodes as frozen (counter a5-0x61D6, #$e mask, x2, table 0x005C08)")
# 2. the table
want = [(0x0F,0x03,0x0010),(0x02,0x00,0x000C),(0x0C,0x08,0x0008),(0x0E,0x04,0x0004),
        (0x06,0x0A,0x0002),(0x01,0x05,0x0000),(0x09,0x07,0x000A),(0x0D,0x06,0x0006)]
t = b[0x5C08:0x5C28]
rows = [(t[4*k], t[4*k+1], int.from_bytes(t[4*k+2:4*k+4], "big")) for k in range(8)]
if rows != want:
    print("FAIL: attract table differs from the frozen roster:")
    for k,(r,w) in enumerate(zip(rows,want)): print(f"    demo {k}: got P1 {r[0]:#04x} P2 {r[1]:#04x} venue {r[2]:#06x}  want {w[0]:#04x} {w[1]:#04x} {w[2]:#06x}")
    sys.exit(1)
ids1 = sorted(r[0] for r in rows); ids2 = sorted(r[1] for r in rows)
if len(set(ids1)) != 8 or len(set(ids2)) != 8 or max(ids1+ids2) > 0x0F:
    print("FAIL: roster shape — expected 8 distinct base ids per column"); sys.exit(1)
for k,r in enumerate(rows): print(f"  ok: demo {k}: P1 {r[0]:#04x} vs P2 {r[1]:#04x}, venue {r[2]:#06x}")
print("  ok: 8 distinct base ids per column, none in the variant half")
PY
}

echo "== 1+2. the reader and the table, vanilla vsavj"
check "$W/vj.bin" || { echo "FAIL"; exit 1; }

echo "== 3. negative control: one id byte changed must FAIL"
python3 - "$W/vj.bin" "$W/bad.bin" <<'PY'
import sys
b = bytearray(open(sys.argv[1], "rb").read()); b[0x5C0C] = 0x13   # demo 1's P1 -> a tenant id
open(sys.argv[2], "wb").write(bytes(b))
PY
if check "$W/bad.bin" >"$W/ctl.txt" 2>&1; then
    echo "  FAIL: the perturbed table PASSED — the check is not checking"; exit 1
elif grep -q "differs from the frozen roster" "$W/ctl.txt"; then
    echo "  ok: control fires (table differs)"
else
    echo "  FAIL: control failed for the wrong reason:"; sed 's/^/    /' "$W/ctl.txt"; exit 1
fi
echo "PASS: the attract-demo roster is the frozen eight matchups, read by the decoded assigner"
