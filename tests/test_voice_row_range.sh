#!/bin/sh
# test_voice_row_range.sh — the AUTHORED voice-class rows must stay inside
# vanilla's value range (14z-93, GitHub #92). ~2s, no emulator.
#
# THE DEFECT THIS GATES. Each tenant build authors a 64-byte row in each of
# the two voice-class tables at its own voice-class index:
#
#     table A (candidate ids)      PRG:0x00B268 + class*64
#     table B (parallel values)    PRG:0x00BB68 + class*64
#
# `0x00af16` fills the live pool from `class*64 + $FF8121`, the selector loop
# at `0x00aee2` picks an unused candidate index, and `0x00af10` reads
# `tableB_pool[index]` into `$FF8100`. That value is then used by `0x05ffb6`
# as `A0 = 0x26775A + 2*v - 4`, a ROW of the per-char long-pointer table
# `0x26771E`, whose FOLLOWING row is dereferenced.
#
# **The last row with a valid follower is 0x19**, so the largest safe value
# is `2*(0x19-14) = 0x16`. Vanilla obeys that by construction: over all 1024
# bytes of table B's classes 0x00-0x0F it emits only the even values
# 0x00..0x16 and NEVER 0x18.
#
# Huitzil's and Pyron's authored rows contained **0x18** at four offsets
# each. When `$FF8121` lands on one and the selector picks it, `$FF8100`
# becomes 24, the pointer-table lookup reaches row 0x1A, and its follower is
# that table's own `0x00400000` terminator — dereferenced, read as `0x7080`,
# and taken as a jump-table index. `vec3`. Deterministic in a rig, a RACE in
# the field (it depends on per-event pool construction), and invisible to
# `run_suite` because no suite replay is long enough.
#
# WHY A RANGE GATE RATHER THAN A FOUR-BYTE FIX. The four offsets are where it
# happened to land; ANY value above vanilla's maximum is unsafe at ANY offset,
# and the same authoring path produces these rows for every future tenant.
# The bound is derived from the two tables, not hardcoded, so if the
# pointer table ever grows the gate follows it.
#
# Usage: [BUILDS="build/hui41:0x10 ..."] tests/test_voice_row_range.sh
# Needs build/out/vsavj_data.bin (the DATA view — these tables are read
# An-relative and live inside the crypt window; the opcode view is noise).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
[ -f build/out/vsavj_data.bin ] || { echo "SKIP: need build/out/vsavj_data.bin"; exit 0; }
BUILDS="${BUILDS:-build/hui41:0x10 build/pyron26:0x11 build/don_m7:0x13 build/hui42:0x10}"

BUILDS="$BUILDS" python3 - <<'PY' || exit 1
import json, os, sys

VD = open("build/out/vsavj_data.bin", "rb").read()
TA, TB = 0x00B268, 0x00BB68
PTR_TBL = 0x26771E          # the per-char long-pointer table

def L(b, a): return int.from_bytes(b[a:a+4], "big")

# ---- derive the safety bound from the DATA, never hardcode it -------------
# v selects row 14 + v/2 of PTR_TBL, and the consumer dereferences the
# FOLLOWING row. The bound is the largest v whose follower is a real pointer.
row = 0
while True:
    nxt = L(VD, PTR_TBL + (row + 1) * 4)
    if not (0x000400 <= nxt < 0x400000):
        break
    row += 1
    if row > 0x40:
        sys.exit("  FAIL: pointer table has no terminator — model is wrong")
# `row` is now the LAST VALID ROW (row+1 is the terminator). The consumer
# dereferences the FOLLOWING row, so the last row that is SAFE to select is
# row-1 — its follower is `row`, still a real pointer. Off-by-one caught by
# this file's own vanilla cross-check when it was first written (14z-93).
LAST_SAFE = row - 1
BOUND = 2 * (LAST_SAFE - 14)
print(f"  derived: last valid row {row:#04x}; last SAFE row {LAST_SAFE:#04x} "
      f"-> max safe value {BOUND:#04x}")

# ---- vanilla's own range, as a cross-check --------------------------------
van = set()
for c in range(0x00, 0x10):
    van.update(VD[TB + (c << 6): TB + (c << 6) + 64])
vmax = max(van)
print(f"  vanilla table B (classes 0x00-0x0F) max = {vmax:#04x}; uses 0x18? {0x18 in van}")
rc = 0
if vmax != BOUND:
    print(f"  FAIL: vanilla max {vmax:#04x} != derived bound {BOUND:#04x} — the two")
    print("        independent derivations disagree, so the model is wrong")
    rc = 1
else:
    print(f"  ok: vanilla's max and the derived bound AGREE at {BOUND:#04x}")

# ---- every authored row must obey it --------------------------------------
seen = 0
for spec in os.environ["BUILDS"].split():
    d, cls = spec.rsplit(":", 1)
    cls = int(cls, 16)
    pj = os.path.join(d, "patch", "patch.json")
    if not os.path.exists(pj):
        print(f"  (skip {d}: no patch.json)")
        continue
    ops = json.load(open(pj))["ops"]
    for tbl, name in ((TB, "B values"), (TA, "A ids")):
        want = tbl + (cls << 6)
        for o in ops:
            a = o.get("addr")
            if not isinstance(a, str) or int(a, 16) != want:
                continue
            h = bytes.fromhex(o["hex"])
            seen += 1
            if name == "A ids":
                continue           # table A holds class ids, a different space
            bad = [(i, v) for i, v in enumerate(h) if v > BOUND]
            if bad:
                print(f"  FAIL {d} row {cls:#04x} ({name}): {len(bad)} byte(s) > {BOUND:#04x}")
                print("        " + ", ".join(f"+{i:#04x}={v:#04x}" for i, v in bad[:8]))
                print("        Any of these reaching $FF8100 indexes the pointer table")
                print(f"        past row {LAST_SAFE:#04x} and dereferences its terminator (#92).")
                rc = 1
            else:
                print(f"  ok   {d} row {cls:#04x} ({name}): all {len(h)} bytes <= {BOUND:#04x}")

if seen == 0:
    print("  FAIL: no authored voice rows found in any build — nothing measured")
    rc = 1
sys.exit(rc)
PY

echo
echo "PASS: every authored voice row stays inside vanilla's value range."
