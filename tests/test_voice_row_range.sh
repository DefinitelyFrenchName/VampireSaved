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
# DEFAULT = THE SHIPPING BUILDS (re-pointed 14z-94, GitHub #30). It used to
# defaulted to the PRE-FIX builds (hui41/pyron26/hui42) before 14z-94; the
# so the gate asserted "the frozen builds still carry #92". That is history,
# not a regression check, and it made the gate permanently RED: once
# tests/run_all_static.sh started running the suite, a gate that can never go
# green is exactly what trains people to ignore the chain.
#
# The pre-fix builds remain the GROUND-TRUTH CONTROL and are worth keeping —
# run them explicitly to confirm this gate can still fail:
#
#   BUILDS="build/hui41:0x10 build/pyron26:0x11" tests/test_voice_row_range.sh
#     -> must FAIL with 4 bytes > 0x16 per tenant
#
# A build dir that is absent is SKIPPED, not failed, so a fresh checkout does
# not red (GitHub #29: the skip is reported, never counted as a pass).
BUILDS="${BUILDS:-build/hui51:0x10 build/pyron35:0x11 build/don_m17:0x13}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117

_present=""
for _b in $BUILDS; do
    [ -d "${_b%%:*}" ] && _present="$_present $_b"
done
if [ -z "$_present" ]; then
    echo "SKIP: none of the named tenant builds are on disk ($BUILDS)"
    exit 0
fi
BUILDS="$_present"

rc_b=0
BUILDS="$BUILDS" python3 - <<'PY' || rc_b=$?
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

# ── SECTION B — TABLE A, the CLASS half ────────────────────────────────────
# Added 14z-94. The section above audits table B only, on the stated ground
# that "table A holds class ids, a different space". True, and it left that
# space unaudited — while the authored rows introduce classes 0x11 and 0x13,
# which vanilla vsavj never emits. That is the same shape as #92 (a vs2 value
# in a vsavj table), so it gets measured rather than assumed benign.
#
# It runs BEFORE the verdict is combined, and its own status is separate:
# while #92 is open section A is RED BY DESIGN, and a section that only ran
# on section A's success would never execute at all.
#
# THE BOUNDS ARE DERIVED, and they are two different bounds:
#   structural — the ladder tables are (TB - TA) / 0x40 rows; a class C
#                indexes row C of BOTH (C<<6), so C outside that count reads
#                another table's bytes;
#   mask       — the selector does `btst d1,d2` with d2 = $FF8110.l, and a
#                data-register btst takes the bit number MOD 32, so a class
#                >= 32 silently aliases another class's in-use bit.
# The mask bound is the tighter one and is the one that matters.
#
# TWO MARKER VALUES ARE NOT CLASSES, both measured over all 36 vanilla rows:
#   0x18 at group index 7 — universal, every row, every group. Never scanned
#        (the bound $FF8138 measured 6), so it is a sentinel, not a class.
#   0xff — appears ONLY as entire rows 0x0b and 0x1b (56 bytes each, all of
#        indices 0-6), never mixed into a real ladder. An empty-slot marker.
#        Class 0x0b is also absent from every other row's candidates.
rc_a=0
BUILDS="$BUILDS" python3 - <<'PY' || rc_a=$?
import json, os, sys

VD = open("build/out/vsavj_data.bin", "rb").read()
TA, TB = 0x00B268, 0x00BB68
NROWS = (TB - TA) // 0x40        # structural bound, derived
MASKW = 32                       # btst Dn,Dm is mod 32
SENTINEL, EMPTY = 0x18, 0xFF

# The set of classes the port INTRODUCES, frozen. A pass means "unchanged
# since reviewed" (the shared_writes doctrine), not "any new class is safe":
# a new entry here forces someone to establish what it indexes.
#
# It is the three TENANT classes, and it is three rather than two because
# this check caught its author: the set was first frozen as {0x11, 0x13}
# from the Huitzil and Pyron rows alone, and Donovan's row introduces 0x10
# (he schedules Phobos). Each tenant's ladder names the OTHER tenants, so
# any subset smaller than the roster is an accident of which rows you read.
INTRODUCED = {0x10, 0x11, 0x13}

print()
print(f"  derived: {NROWS} ladder rows ({NROWS:#04x}); mask width {MASKW}")

rc = 0
# ---- vanilla's own shape, as the cross-check ------------------------------
van = {}
for c in range(NROWS):
    r = VD[TA + (c << 6): TA + (c << 6) + 64]
    for g in range(8):
        for i in range(8):
            van.setdefault(i, set()).add(r[g * 8 + i])
if van[7] != {SENTINEL}:
    print(f"  FAIL: index 7 is not uniformly {SENTINEL:#04x} across vanilla "
          f"({sorted(van[7])}) — the sentinel model is wrong")
    rc = 1
else:
    print(f"  ok: vanilla index 7 is {SENTINEL:#04x} in all {NROWS} rows")

ff_rows = [c for c in range(NROWS)
           if all(VD[TA + (c << 6) + g * 8 + i] == EMPTY
                  for g in range(8) for i in range(7))]
ff_total = sum(VD[TA + (c << 6): TA + (c << 6) + 64].count(EMPTY)
               for c in range(NROWS))
if ff_total != len(ff_rows) * 56:
    print(f"  FAIL: {EMPTY:#04x} appears outside whole-empty rows "
          f"({ff_total} bytes vs {len(ff_rows)} full rows) — it is not just "
          "an empty-slot marker, so the exemption below is unsafe")
    rc = 1
else:
    print(f"  ok: {EMPTY:#04x} confined to whole rows "
          f"{[hex(c) for c in ff_rows]} — empty-slot marker")

# ---- every authored table-A row must obey both bounds ---------------------
seen = 0
for spec in os.environ["BUILDS"].split():
    d, cls = spec.rsplit(":", 1)
    cls = int(cls, 16)
    pj = os.path.join(d, "patch", "patch.json")
    if not os.path.exists(pj):
        continue
    want = TA + (cls << 6)
    for o in json.load(open(pj))["ops"]:
        a = o.get("addr")
        if not isinstance(a, str) or int(a, 16) != want:
            continue
        h = bytes.fromhex(o["hex"])
        seen += 1
        bad_sent = [g for g in range(8) if h[g * 8 + 7] != SENTINEL]
        over = [(i, v) for i, v in enumerate(h)
                if v != EMPTY and i % 8 != 7 and v >= MASKW]
        new = {v for i, v in enumerate(h)
               if i % 8 != 7 and v != EMPTY and v not in van[i % 8]}
        if bad_sent:
            print(f"  FAIL {d} row {cls:#04x}: groups {bad_sent} do not end "
                  f"in the {SENTINEL:#04x} sentinel")
            rc = 1
        if over:
            print(f"  FAIL {d} row {cls:#04x}: {len(over)} class(es) >= "
                  f"{MASKW} — the in-use bit aliases another class")
            print("        " + ", ".join(f"+{i:#04x}={v:#04x}" for i, v in over[:8]))
            rc = 1
        if new - INTRODUCED:
            print(f"  FAIL {d} row {cls:#04x}: introduces class(es) "
                  f"{sorted(hex(v) for v in new - INTRODUCED)} that vanilla "
                  "never emits and that are NOT in the reviewed set")
            rc = 1
        if not (bad_sent or over or (new - INTRODUCED)):
            extra = sorted(hex(v) for v in new)
            print(f"  ok   {d} row {cls:#04x}: sentinels intact, all classes "
                  f"< {MASKW} with rows in both tables; introduces {extra}")

if seen == 0:
    print("  FAIL: no authored table-A rows found — nothing measured")
    rc = 1
sys.exit(rc)
PY

echo
if [ "${rc_a:-0}" -ne 0 ]; then
  echo "FAIL (table A): see section B above."
fi
if [ "${rc_b:-0}" -ne 0 ]; then
  echo "FAIL (table B): the #92 stage values are still out of range."
  echo "  Those four offsets per tenant select class 0x13 (Donovan) at stage"
  echo "  0x18 = REVENGER'S ROOST, which vsav does not have. The value space"
  echo "  is named by tools/decode_stage_banners.py; the replacement is a"
  echo "  maintainer decision because the stage is visible in arcade mode."
fi
[ "${rc_a:-0}" -eq 0 ] && [ "${rc_b:-0}" -eq 0 ] || exit 1

echo
echo "PASS: every authored voice row stays inside vanilla's value range."
