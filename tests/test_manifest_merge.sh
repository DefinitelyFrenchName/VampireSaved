#!/bin/sh
# test_manifest_merge.sh — what the three tenant manifests do when merged.
#
# WHY (M3b slice F, 14z-77). Until now the merge's hazards were a LIST IN A
# DOCUMENT, re-derived by reading TOML by eye. `merge_manifests()` makes them
# a measurement, and this gate FREEZES it: the shared-row dedup counts and the
# exact collision inventory. A manifest edit that adds a collision, or that
# silently stops two engine declarations from deduping, fails here — in
# seconds, with the address named — instead of at the merged build.
#
# The merge is deliberately NOT clever. It concatenates owned rows, dedups
# rows that are identical apart from their owner (engine declarations all
# three tenants make the same way), and REFUSES on anything else. Refusing is
# the point: `[table_fix]`'s `rows_hex` differs by exactly the tenant's own
# OBJ bank row, so a silent "last file wins" would drop a tenant's bank word
# with nothing downstream to catch it.
#
# Four checks, no ROMs, no emulator, no build (~1s).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
from pathlib import Path
from gen_donovan_patch import (toml_loads, manifest_owner, stamp_owner,
                               merge_manifests)

bad = []
def eq(what, got, want):
    if got != want:
        bad.append("%s: got %r, expected %r" % (what, got, want))

def load(*names):
    out = []
    for n in names:
        d = toml_loads(Path("build/manifest/%s.toml" % n).read_text())
        stamp_owner(d, manifest_owner(d))
        out.append(d)
    return out

print("== 1: one document merges to itself (this is why slice F is inert) ==")
(d,) = load("donovan")
m, c = merge_manifests([d])
eq("single-doc collisions", c, [])
eq("single-doc identity", m is d, True)
print("  ok: identity, no collisions")

print("== 2: shared ENGINE rows dedup; owned rows concatenate ==")
docs = load("donovan", "huitzil", "pyron")
m, coll = merge_manifests(docs)
# (section, per-file counts, merged count, shared count). Frozen 14z-77.
FROZEN = [
    ("space",            (3, 3, 3),  3,  3),   # identical in all three
    ("obj_hook",         (2, 2, 2),  2,  2),
    ("select_wheel",     (1, 1, 1),  1,  1),   # one 21-cell wheel per build
    ("site_thunk",       (20, 10, 4), 28, 3),  # the 3 *_bank_variant_id rows
    ("pcrel_escape_fix", (0, 5, 2),  5,  2),   # the H<->P shared-source pair
    ("code_word",        (4, 3, 6),  11, 2),
    ("port_patch",       (21, 55, 14), 87, 3),
    ("tenant",           (1, 1, 1),  3,  0),   # never shared, by definition
    ("select_records",   (6, 6, 6),  18, 0),   # six pieces PER TENANT
    ("win_pal_variant",  (1, 1, 1),  3,  0),
    ("palette",          (2, 2, 2),  6,  0),
    ("aux_poke",         (5, 6, 3),  14, 0),   # disjoint HUD free-pool anchors
]
for sect, per, total, shared in FROZEN:
    eq("%s per-file" % sect, tuple(len(d.get(sect, [])) for d in docs), per)
    rows = m.get(sect, [])
    eq("%s merged" % sect, len(rows), total)
    eq("%s shared" % sect, sum(1 for r in rows if r.get("_owner") is None),
       shared)
print("  ok: %d frozen section shapes (dedup and concatenation both)"
      % len(FROZEN))

print("== 3: the collision inventory is EXACTLY the known set ==")
# Frozen 14z-77. The COUNT is part of the verdict, so a new collision cannot
# arrive unnoticed. TWO CLASSES, and the split is the finding: only the first
# three are real blockers. The six port_patch entries are BASE-TRACK ONLY —
# all three tenants agree on `new_hex_variant`, and a merged build is a WIDE
# build by construction (a variant id requires the profile), so those rows
# never take the value they disagree about.
EXPECT = [
    "[init_shim]: huitzil and donovan declare DIFFERENT singleton tables",
    "[table_fix]: huitzil and donovan declare DIFFERENT singleton tables",
    "[table_fix]: pyron and donovan declare DIFFERENT singleton tables",
]
# base-track-only: reported, but not a merge blocker. Each MUST carry the
# dissolves-on-WIDE wording — if one ever stops doing so, the tenants have
# stopped agreeing on the variant value and it becomes a real blocker.
SOFT = [
    "[[port_patch]] x05c800/0x5cf38",
    "[[port_patch]] x05c800/0x620d4",
    "[[port_patch]] x05c800/0x62194",
    "[[port_patch]] x088512/0x8873e",
    "[[port_patch]] x088512/0x89d26",
    "[[port_patch]] x088512/0x8b100",
    "[[port_patch]] x088512/0x8873e",
    "[[port_patch]] x088512/0x89d26",
    "[[port_patch]] x088512/0x8b100",
]
EXPECT = EXPECT + SOFT
eq("real blockers (non-base-track)",
   sum(1 for c in coll if "BASE-TRACK ONLY" not in c), 3)
for c in coll:
    if c.startswith("[[port_patch]]") and "BASE-TRACK ONLY" not in c:
        bad.append("port_patch collision is no longer base-track-only, so it "
                   "IS a merge blocker now: %s" % c)
eq("collision count", len(coll), len(EXPECT))
for i, want in enumerate(EXPECT):
    if i < len(coll) and not coll[i].startswith(want):
        bad.append("collision %d: %r does not start with %r" % (i, coll[i], want))
if len(coll) == len(EXPECT) and not bad:
    print("  ok: %d collisions, each the expected one:" % len(coll))
    for c in coll:
        print("      - %s" % c)
else:
    for c in coll:
        print("      (got) %s" % c)

print("== 4: verdict controls — the merge must NOT be permissive ==")
# 4a. a differing singleton MUST collide (not silently pick one)
a = {"table_fix": {"rows_hex": "aa", "_owner": "x"}}
b = {"table_fix": {"rows_hex": "bb", "_owner": "y"}}
_, c1 = merge_manifests([a, b])
eq("differing singleton collides", len(c1), 1)
# 4b. an IDENTICAL singleton must dedup to shared, not collide
a = {"table_fix": {"rows_hex": "aa", "_owner": "x"}}
b = {"table_fix": {"rows_hex": "aa", "_owner": "y"}}
m2, c2 = merge_manifests([a, b])
eq("identical singleton dedups", (len(c2), m2["table_fix"]["_owner"]), (0, None))
# 4c. same span + different payload MUST collide even when the rows are
#     otherwise unrelated — the class that concatenation hides
a = {"port_patch": [{"region": "r", "src_addr": 1, "new_hex": "4000",
                     "_owner": "x"}]}
b = {"port_patch": [{"region": "r", "src_addr": 1, "new_hex": "6000",
                     "_owner": "y"}]}
_, c3 = merge_manifests([a, b])
eq("same span, different payload collides", len(c3), 1)
# 4d. same span + SAME payload is the shared shape, not a collision
a = {"port_patch": [{"region": "r", "src_addr": 1, "new_hex": "4000",
                     "_owner": "x"}]}
b = {"port_patch": [{"region": "r", "src_addr": 1, "new_hex": "4000",
                     "_owner": "y"}]}
m4, c4 = merge_manifests([a, b])
eq("same span, same payload dedups", (len(c4), len(m4["port_patch"])), (0, 1))
if not bad:
    print("  ok: collides on differing singletons and differing spans;")
    print("      dedups identical ones; 4 controls")

for b_ in bad:
    print("  FAIL: %s" % b_)
sys.exit(1 if bad else 0)
PY

echo "PASS: manifest merge (inert at one file, frozen dedup shapes, the exact"
echo "      12-collision inventory, and 4 permissiveness controls)"
