#!/bin/sh
# test_effect_placeholders.sh — THE x2b7ef4 COORDINATE-LIST PLACEHOLDERS ARE RESOLVED AT THE OFFSETS THEY WERE WRITTEN, never by an in-place scan (14z-170): a resolved pointer whose low word begins 0xEE is left alone, source data beginning 0xEE is left alone, and a placeholder overwritten before resolution is reported.
#
# MUST-FIRE: shadow-tool: in-place-scan — the resolver the generator carried until 14z-170 (an in-place scan for any even-aligned long whose top byte is 0xEE), run on the same straddle fixture, must CORRUPT it — the resolved pointer's low word and the record's first tile — so the fixture exercises the defect the fix removes (in-gate: the shadow scan's output must differ from the expected bytes; mode: the gate resolves with the shadow scan and FAILs)
#
# WHY. tools/gen_donovan_patch.py's x2b7ef4 companion-effect pass writes a `0xEE000000 + off`
# placeholder into each ported record's coordinate-list pointer, allocates the ported lists,
# then resolves the placeholders. Until 14z-170 it resolved them by scanning every even offset
# of the blob for a long whose top byte is 0xEE, IN PLACE: once a pointer was resolved, the
# window two bytes on began with that pointer's LOW WORD, and when that word's high byte was
# 0xEE (placement-dependent) the window was taken for a placeholder and rewritten — clobbering
# the pointer (to an ODD address) and the record's next word. Measured 14z-170: merged-m18
# (and merged-m16/-m17, don_m22, the stock twin — Donovan's copy placed at PRG:0x0F3F70) carry
# 40 such sites in Donovan's copy and 12 in Pyron's, and the four #136 fixes' +0x30 allocator
# shift re-rolled three more. The fix: resolve_tagged_placeholders() writes exactly the offsets
# the pass recorded.
#
# WHAT IT CHECKS (no ROM, no build): the module-level resolver on synthetic blobs —
#   1. THE STRADDLE: two adjacent records whose resolved pointers read 0x..EExx, the second's
#      placeholder right after the first's pointer: both resolve exactly, nothing else moves;
#   2. SOURCE DATA with a 0xEE top byte at an offset that is not a recorded placeholder: untouched;
#   3. a recorded offset that no longer holds a placeholder: reported, not rewritten.
# NOT COVERED: the pass's record DISCOVERY (a pointer-shaped scan of the placed window, [VSP-68]
# — placement-dependent too, not changed here); the built images, which
# tests/test_m3a_reproducible.sh and the freeze's attribution cover.
#
# Usage: tests/test_effect_placeholders.sh    (ci_portable, ~1 s)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"

rc=0
python3 - "$MODE" <<'PY' || rc=$?
import sys
sys.path.insert(0, "tools")
from gen_donovan_patch import resolve_tagged_placeholders
MODE = sys.argv[1]
bad = 0
def chk(c, m):
    global bad
    print(("  ok    " if c else "  FAIL  ") + m); bad |= not c

def shadow_scan(blob, offsets, la):
    """THE PERTURBATION: the resolver until 14z-170, verbatim in effect — every even offset,
    in place, any long whose top byte is 0xEE."""
    for i in range(0, len(blob) - 4, 2):
        vv = int.from_bytes(blob[i:i + 4], "big")
        if (vv >> 24) == 0xEE:
            blob[i:i + 4] = (la + (vv & 0xFFFFFF)).to_bytes(4, "big")
    return []

resolve = shadow_scan if MODE == "in-place-scan" else resolve_tagged_placeholders

LA = 0x3FCD60                     # the ported-list fragment (merged-m18's Donovan value)
# a record: fmt 0002, budget 000d, count 0004, cptr (4 bytes), then (tile, attr) entries
def record(cptr, tile):
    return bytes.fromhex("0002000d0004") + cptr.to_bytes(4, "big") + tile.to_bytes(2, "big") + bytes.fromhex("1328")
# off 0x20A4 into the fragment: la + 0x20A4 = 0x3FEE04, whose low word begins 0xEE — the straddle
blob = bytearray(record(0xEE000000 + 0x0020A4, 0x11E2) + record(0xEE000000 + 0x0020B8, 0x0695))
offsets = [6, 6 + 14]
src_ee = bytearray(b"\x00" * 4 + bytes.fromhex("EE123456") + b"\x00" * 4)   # source data, not a placeholder
want = bytearray(record(LA + 0x20A4, 0x11E2) + record(LA + 0x20B8, 0x0695))

print("== 1. the straddle")
b1 = bytearray(blob); st = resolve(b1, offsets, LA)
chk(b1 == want and not st, f"both pointers resolve to {LA + 0x20A4:#x} / {LA + 0x20B8:#x} and the tiles stay 11e2 / 0695: {b1.hex()}")
if MODE != "in-place-scan":
    b0 = bytearray(blob); shadow_scan(b0, offsets, LA)
    if b0 != want:
        print(f"CONTROL FIRED: in-place-scan — the old scan corrupts the same fixture: {b0.hex()}")
    else:
        print("CONTROL DEAD: in-place-scan — the old scan resolved the fixture correctly; the fixture does not exercise the straddle")
        bad = 1

print("== 2. source data with a 0xEE top byte")
b2 = bytearray(src_ee); st = resolve(b2, [], LA)
chk(b2 == src_ee and not st, f"an 0xEE-topped long at an unrecorded offset is left alone: {b2.hex()}")

print("== 3. a recorded offset that lost its placeholder")
b3 = bytearray(record(0x00123456, 0x11E2)); st = resolve(b3, [6], LA)
chk(st == [6] and b3 == bytearray(record(0x00123456, 0x11E2)), f"reported ({st}) and not rewritten")
sys.exit(1 if bad else 0)
PY
[ "$rc" = 0 ] && echo "PASS: test_effect_placeholders — placeholders resolve at their recorded offsets only; the straddle, 0xEE source data and a lost placeholder are each handled" && exit 0
echo "FAIL: test_effect_placeholders"; exit 1
