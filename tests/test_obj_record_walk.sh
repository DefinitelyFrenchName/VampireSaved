#!/bin/sh
# test_obj_record_walk.sh — ground truth for the RELOCATION-AWARENESS of
# obj_records.walk()'s two heuristic passes (14z-92, GitHub #75).
# Pure functions on a synthetic region — no ROMs, no build dirs, no
# emulator, ~1s. Portable by construction (tests/ci_portable.txt).
#
# WHY THIS EXISTS. verify_gfx_build.py compares a walk of the SOURCE anim
# region against a walk of the BUILT image. Both passes of the walker are
# heuristics whose predicates are PLACEMENT-DEPENDENT:
#   sweep pass   "does the long at +6 land in an aux region?"  — the aux
#                regions MOVE (hardened 14z-74, sweep_allow)
#   pointer pass "does this 4-byte value land inside [start,end)?" — the
#                REGION moves (hardened 14z-92, ptr_allow)
# So the same bytes get a different answer before and after placement, and
# a phantom record is invented in the built image alone. Measured twice:
# 11 phantoms on Pyron (14z-74, sweep) and 1 on merged Huitzil (#75,
# pointer pass — +1 record, +67 entries, 34 out-of-band tiles, which
# aborted every merged build from merged6 on).
#
# The fixture reproduces the #75 shape exactly: a 4-byte STRADDLE of one
# entry's attr and the next entry's tile, byte-identical in source and
# build (i.e. never relocated, i.e. not a pointer), whose value falls
# inside the built region window but outside the source's.
#
# CLAUDE.md §4, "verdict logic is itself tested" — a parity check that
# cannot fail is not a check, so every control must ACTUALLY fire:
#   A  the phantom  — ptr_allow=None MUST invent it (the pre-fix
#                     behaviour, reachable with no reconstruction), and
#                     the allow-map MUST reject it
#   B  corruption   — a clobbered fmt-0 count word MUST lose its record
#                     (the session-14b defect this parity check exists to
#                     catch; the fix must not have blunted it)
#   C  un-relocated — a pointer left at its source value MUST lose its
#                     record
#   D  swapped      — two pointers relocated to each other's targets: the
#                     COUNTS still match, so the pre-fix check passes and
#                     the allow-map catches it. Strictly stronger, proved
#                     rather than asserted
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
from obj_records import walk

SRC_BASE = 0x200000          # the source (vs2) anim region
OUT_BASE = 0x410000          # where a MERGED build places it
LEN      = 0x400
AUX_SRC  = [(0x300000, 0x300100)]
AUX_DST  = [(0x500000, 0x500100)]
src_ok = lambda c: any(a <= c < b for a, b in AUX_SRC)
out_ok = lambda c: any(a <= c < b for a, b in AUX_DST)


def build(base, aux, swap=False, unrelocate=False, clobber=False):
    r = bytearray(LEN)

    def w(off, val):
        r[off:off + 2] = val.to_bytes(2, "big")

    def l(off, val):
        r[off:off + 4] = val.to_bytes(4, "big")

    # --- the record pointer table (REAL pointers: relocated by the build)
    t1, t2 = 0x040, 0x080
    if swap:
        t1, t2 = t2, t1
    l(0x000, base + t1)
    l(0x004, base + t2)
    if unrelocate:                      # control C: left at its source value
        l(0x004, SRC_BASE + 0x080)

    # --- R1: fmt-2, 4 entries.  Entry 0's attr and entry 1's tile are the
    #     STRADDLE: a 4-byte read at 0x04C yields 0x00410100, which is an
    #     address inside the BUILT window and outside the SOURCE window.
    w(0x040, 0x0002); w(0x042, 0x0004); w(0x044, 0x0003)
    l(0x046, aux[0][0] + 0x10)          # cptr — a real pointer, relocated
    w(0x04A, 0x1000); w(0x04C, 0x0041)  # <- straddle, high word
    w(0x04E, 0x0100); w(0x050, 0x0000)  # <- straddle, low word
    w(0x052, 0x1002); w(0x054, 0x0000)
    w(0x056, 0x1003); w(0x058, 0x0000)

    # --- R2: fmt-0, 4 entries
    w(0x080, 0x0000); w(0x082, 0x0000 if clobber else 0x0004); w(0x084, 0)
    l(0x086, aux[0][0] + 0x20)          # cptr — a real pointer, relocated
    for k in range(4):
        w(0x08A + 2 * k, 0x1010 + k)

    # --- ordinary data that HAPPENS to be header-shaped, with a cptr
    #     constant that is NOT relocated (0x500080). It is junk in both
    #     images; only the moved aux window makes it pass cptr_ok, and
    #     only the moved region window makes anything point at it.
    w(0x100, 0x0000); w(0x102, 0x0006); w(0x104, 0x0000)
    l(0x106, 0x500080)
    for k in range(6):
        w(0x10A + 2 * k, 0x0001 + k)
    return bytes(r)


def W(img, base, ok, **kw):
    return walk(img, base, base, base + LEN, ok, 0x8000, 0xEEBB, **kw)


src = build(SRC_BASE, AUX_SRC)
s_ptr = {}
s_tiles, s_ent, s_rec = W(src, SRC_BASE, src_ok, ptr_seen=s_ptr)
assert (s_rec, s_ent) == (2, 8), f"fixture: source walk {(s_rec, s_ent)}"
assert s_ptr == {0x000: 0x040, 0x004: 0x080}, f"fixture ptr map {s_ptr}"
assert 0x00410100 == int.from_bytes(src[0x04C:0x050], "big"), "straddle"
print(f"  ok: fixture — source walk {s_rec} records, {s_ent} entries, "
      f"straddle datum 0x{0x00410100:08x} present")

# ---------------------------------------------------------------- 1. baseline
out = build(OUT_BASE, AUX_DST)
o_ptr, o_rej = {}, []
o_tiles, o_ent, o_rec = W(out, OUT_BASE, out_ok,
                          ptr_allow=s_ptr, ptr_seen=o_ptr, ptr_rejected=o_rej)
assert (o_rec, o_ent) == (s_rec, s_ent), f"baseline parity {(o_rec, o_ent)}"
assert o_ptr == s_ptr, f"baseline offsets {o_ptr}"
assert o_tiles == s_tiles, "baseline tile inventory"
print(f"  ok: clean relocation — parity ({o_rec},{o_ent}) and the record "
      f"offsets are identical across the move")

# ------------------------------------------- 2. control A: the #75 phantom
# The control must be LIVE: if the pre-fix walk does not invent the
# phantom, this fixture proves nothing and the test fails here.
p_tiles, p_ent, p_rec = W(out, OUT_BASE, out_ok)
assert (p_rec, p_ent) == (3, 14), \
    f"CONTROL A DEAD: ungated walk found {(p_rec, p_ent)}, expected (3,14)"
phantom_tiles = p_tiles - s_tiles
assert phantom_tiles == {1, 2, 3, 4, 5, 6}, f"phantom tiles {phantom_tiles}"
assert (o_rec, o_ent) == (2, 8), "allow-map failed to reject the phantom"
assert (0x04C, 0x100) in o_rej, f"phantom not reported as rejected: {o_rej}"
print(f"  ok: control A — ungated walk invents the phantom (+1 record, "
      f"+{p_ent - s_ent} entries, {len(phantom_tiles)} out-of-band tiles); "
      f"the allow-map rejects it and SAYS so")

# --------------------------------- 3. control B: session-14b count corruption
bad = build(OUT_BASE, AUX_DST, clobber=True)
b_ptr = {}
_, b_ent, b_rec = W(bad, OUT_BASE, out_ok, ptr_allow=s_ptr, ptr_seen=b_ptr)
assert (b_rec, b_ent) != (s_rec, s_ent), \
    "CONTROL B DEAD: a clobbered fmt-0 count word passed parity"
assert set(s_ptr) - set(b_ptr) == {0x004}, f"missing set {b_ptr}"
print(f"  ok: control B — a clobbered fmt-0 count word still FAILS parity "
      f"({b_rec},{b_ent}) and the missing record is named (ptr +0x4)")

# ------------------------------------- 4. control C: un-relocated pointer
un = build(OUT_BASE, AUX_DST, unrelocate=True)
u_ptr = {}
_, u_ent, u_rec = W(un, OUT_BASE, out_ok, ptr_allow=s_ptr, ptr_seen=u_ptr)
assert (u_rec, u_ent) != (s_rec, s_ent), \
    "CONTROL C DEAD: an un-relocated record pointer passed parity"
print(f"  ok: control C — a pointer left at its source value FAILS parity "
      f"({u_rec},{u_ent})")

# ------------------- 5. control D: swapped targets — counts alone are blind
sw = build(OUT_BASE, AUX_DST, swap=True)
_, w_ent_old, w_rec_old = W(sw, OUT_BASE, out_ok)
# blindness, stated as the measurement it is: swapping the two targets
# does not move the ungated counts AT ALL, so no count comparison — the
# pre-14z-92 check included — could ever have seen it.
assert (w_rec_old, w_ent_old) == (p_rec, p_ent), \
    "CONTROL D DEAD: the count-only check was expected to be blind here"
w_ptr = {}
_, w_ent, w_rec = W(sw, OUT_BASE, out_ok, ptr_allow=s_ptr, ptr_seen=w_ptr)
assert (w_rec, w_ent) != (s_rec, s_ent), \
    "pointers relocated to each other's targets passed the allow-map"
print(f"  ok: control D — swapped targets pass a COUNT check "
      f"({w_rec_old},{w_ent_old}) and fail the allow-map ({w_rec},{w_ent}): "
      f"the new check is strictly stronger, measured not asserted")

# ------------------------------------------- 6. the defaults are inert
# Every other caller (obj_records CLI, audit_gfx_merged, the two build
# drivers) walks in SOURCE space with no allow-map; their behaviour must
# be byte-identical to before the change.
assert W(src, SRC_BASE, src_ok) == (s_tiles, s_ent, s_rec), \
    "default-argument behaviour moved"
print("  ok: defaults inert — a walk with neither ptr_seen nor ptr_allow "
      "returns exactly what it always did")

print("PASS: obj_records.walk relocation-awareness (both passes)")
PY
