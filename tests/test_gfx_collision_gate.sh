#!/bin/sh
# test_gfx_collision_gate.sh — ground truth for build_gfx_donovan.place()
# (14z-83 S1): the same-source-or-fail rule every gfx pass now routes
# through. Pure functions on synthetic simms — no ROMs, no emulator, ~1s.
#
# The verdict logic is itself under test (CLAUDE.md §4): a collision gate
# that cannot fail is not a gate, so the different-bytes case must RAISE
# and the test FAILS if it does not (RH-25).
#
# Cases:
#   1. clean write        -> writes, ledger records provenance
#   2. same-source dup    -> benign skip, first provenance kept, bytes intact
#   3. different bytes    -> AssertionError naming BOTH provenances (must
#                            actually raise — the must-fail control)
#   4. textual coverage   -> no pass bypasses place(): the only direct
#                            write_tile on a destination buffer is inside
#                            place() itself
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-83 (S1): ground truth for build_gfx place() — same-source-or- fail on
#   EVERY pass (was 2 of 8; the band pass had NO check). Clean write, benign
#   same-source skip, different- bytes MUST-RAISE control naming both
#   provenances, and the single-write- path textual lock. Emits
#   gfx_written.json (the S2 chain ledger). No ROMs, ~1s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
from build_gfx_donovan import place
from gfx_tiles import tile_bytes

# synthetic 4-member group, big enough for low tile indices (block 0)
dst = [bytearray(0x2000) for _ in range(4)]
tileA = bytes(range(2, 130))
tileB = bytes(range(3, 131))
w = {}

# 1. clean write
assert place(dst, w, 5, tileA, "vs2B", 0x10005, "t1") is True
assert tile_bytes(dst, 5) == tileA, "clean write readback"
assert w[5] == ("vs2B", 0x10005), "ledger provenance"
print("  ok: clean write + ledger provenance")

# 2. same-source duplicate: benign skip, first provenance kept
assert place(dst, w, 5, tileA, "vs2A", 0x20005, "t2") is False
assert w[5] == ("vs2B", 0x10005), "first provenance must survive the skip"
assert tile_bytes(dst, 5) == tileA
print("  ok: same-source duplicate skipped, provenance kept")

# 3. different bytes MUST raise, naming both provenances
raised = False
try:
    place(dst, w, 5, tileB, "vs2A", 0x20005, "t3")
except AssertionError as e:
    raised = True
    msg = str(e)
    assert "vs2B:0x10005" in msg and "vs2A:0x20005" in msg, \
        f"error must name both provenances, got: {msg}"
assert raised, "DIFFERENT-BYTES COLLISION DID NOT RAISE — the gate " \
               "cannot fail where it must"
assert tile_bytes(dst, 5) == tileA, "failed place must not have written"
print("  ok: different-bytes collision raised, both provenances named")

# 4. no pass bypasses place(): outside place() itself, no direct
#    write_tile on a destination buffer remains in the builder
import re
src = open("tools/build_gfx_donovan.py").read()
calls = re.findall(r"^\s*write_tile\(", src, re.M)
assert len(calls) == 1, \
    f"{len(calls)} direct write_tile call(s) — every pass must place()"
print("  ok: place() is the single write path (1 write_tile, in place())")
PY

echo "PASS: gfx collision gate ground truth"
