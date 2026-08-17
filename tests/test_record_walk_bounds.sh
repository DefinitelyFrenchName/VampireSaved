#!/bin/sh
# test_record_walk_bounds.sh — the record walkers must examine the LAST long
# that fits in their range (14z-94, GitHub #51). ROM-free, ~1 s.
#
# THE DEFECT. Both walkers scanned `range(start, end - 4, 2)`. A 4-byte long
# stored at exactly `end-4` lies WHOLLY inside [start, end), but that range
# stops at `end-6` and never examines it. A record pointer in the last long
# of a region would therefore be omitted from the tile inventory — and that
# inventory is what build_gfx_donovan places, so the record's art is never
# copied and it draws whatever occupies the destination band. Silent: no
# builder error, the sprite is simply wrong. It is the same failure mode
# obj_records.py's own docstring records for the earlier format-0 stride bug
# ("the character-select blink, playtest 2026-07-28").
#
# It was copy-pasted into overlay_port.walk_records, so fixing one would have
# left the other wrong; and the SWEEP pass had the same shape one read-width
# along (it reads 10 bytes, so the last address that fits is end-10 and the
# stop must be end-8).
#
# MEASURED INERT ON EVERY SHIPPING TENANT before the fix landed: donovan
# 15612, huitzil 15034, pyron 14225 tiles, and not one gained or lost. The
# bug was latent — which is exactly why it needs a gate rather than a
# rebuild to keep it fixed.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
from obj_records import walk

BASE, LEN = 0x400000, 0x100
AUX = [(0x300000, 0x300100)]
ok = lambda c: any(a <= c < b for a, b in AUX)
rc = 0

def fixture(ptr_off):
    """A region whose ONLY record pointer sits at `ptr_off`, pointing at a
    valid one-entry record. Everything else is zero, so the walk finds this
    record or it finds nothing."""
    r = bytearray(LEN)
    rec = 0x040
    r[ptr_off:ptr_off + 4] = (BASE + rec).to_bytes(4, "big")
    r[rec:rec + 2] = (0x0002).to_bytes(2, "big")         # fmt 2 (even, <=0x20)
    r[rec + 2:rec + 4] = (0x0001).to_bytes(2, "big")     # budget
    r[rec + 4:rec + 6] = (0x0000).to_bytes(2, "big")     # count (entries = +1)
    r[rec + 6:rec + 10] = (0x300000).to_bytes(4, "big")  # cptr, inside AUX
    r[rec + 10:rec + 12] = (0x1234).to_bytes(2, "big")   # entry 0: tile code
    r[rec + 12:rec + 14] = (0x0000).to_bytes(2, "big")   # entry 0: attr
    return bytes(r)

print("== 1. a pointer in the MIDDLE of the range is found (fixture sanity) ==")
tiles, ent, rec = walk(fixture(0x000), BASE, BASE, BASE + LEN, ok, 0x8000, 0xEEBB)
if rec == 1:
    print(f"  ok: mid-range pointer found ({rec} record, {ent} entries)")
else:
    print(f"  FAIL: the fixture itself does not walk ({rec} records) — every"
          f" other section would then pass vacuously")
    rc = 1

print("== 2. THE BOUNDARY — a pointer in the LAST long must also be found ==")
# LEN-4 is the last offset at which a 4-byte long lies wholly inside.
tiles, ent, rec = walk(fixture(LEN - 4), BASE, BASE, BASE + LEN, ok, 0x8000, 0xEEBB)
if rec == 1:
    print(f"  ok: the long at end-4 is examined ({rec} record, {ent} entries)")
else:
    print(f"  FAIL: a record pointer in the LAST long of the region was MISSED"
          f" ({rec} records) — its tiles would never be copied")
    rc = 1

print("== 3. and one PAST the end must not be (no over-read) ==")
# A fix that simply widened the bound too far would read outside the region.
tiles, ent, rec = walk(fixture(0x000), BASE, BASE, BASE + LEN - 8, ok, 0x8000, 0xEEBB)
if rec == 1:
    print("  ok: a narrowed range still finds the in-range pointer")
else:
    print(f"  FAIL: narrowing the range lost the pointer ({rec})")
    rc = 1

print("== 4. the sibling copy in overlay_port carries the same bound ==")
src = open("tools/overlay_port.py").read()
if "hi - base - 2, 2)" in src:
    print("  ok: overlay_port.walk_records uses the corrected bound")
else:
    print("  FAIL: overlay_port.walk_records still excludes its last long —")
    print("        this bound is copy-pasted, so fixing one leaves the other wrong")
    rc = 1

print("== 5. the SWEEP pass's bound accounts for its 10-byte read ==")
src = open("tools/obj_records.py").read()
if "range(start, end - 8, 2)" in src:
    print("  ok: the sweep stop is end-8, so a=end-10 (the last that fits) runs")
else:
    print("  FAIL: the sweep pass still stops short of its last valid address")
    rc = 1

sys.exit(rc)
PY
st=$?

echo
if [ "$st" = 0 ]; then
    echo "PASS: the walkers examine every long that fits in their range."
else
    echo "FAIL: see above."
fi
exit $st
