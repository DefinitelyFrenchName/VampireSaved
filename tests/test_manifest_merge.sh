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
    # [init_shim] was the third blocker until slice G merged it (ratified).
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
   sum(1 for c in coll if "BASE-TRACK ONLY" not in c), 2)
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

print("== 3b: [init_shim] merges (slice G, maintainer-ratified) ==")
from gen_donovan_patch import flavor_tail, flavor_write
sh = m["init_shim"]
# latch_mode is NOT per tenant: the seeder is shared, so a build containing
# Phobos carries his phase gate for everyone. Not a preference — without it
# his ecosystem drains pool 0 and the round-2 re-init re-seeds LIVE pools.
eq("phase mode wins", sh.get("latch_mode"), "phase")
# flavor IS per tenant: the polarity differs because the engine branch each
# character tests differs (14z-66, measured against native).
eq("flavor per owner", sh.get("_flavor_by_owner"),
   {"donovan": (0x01, 0x00), "huitzil": (0x00, 0x01)})
eq("scalar flavor keys removed", "flavor_default" in sh, False)
# Pyron declares no shim, so he gets no entry and therefore NO WRITE — the
# ratified conservative half, by construction rather than by a check.
eq("pyron absent from the flavor map", "pyron" in sh["_flavor_by_owner"], False)

TEN = [{"name": "donovan", "dst_slot": 0x13},
       {"name": "huitzil", "dst_slot": 0x10},
       {"name": "pyron",   "dst_slot": 0x11}]
f = []
one = flavor_tail({"donovan": (1, 0)}, 0x3C2, 0xFF8060, 0x123456, b"", TEN, f)
# ONE declaring tenant must emit exactly the bytes the shim has always had —
# an unconditional write, no compare. This is what keeps the four frozen
# references bit-exact, so it is asserted on the bytes, not assumed.
eq("N=1 tail length", len(one), 46)
eq("N=1 has no id compare", one[:2].hex(), "1d7c")
eq("N=1 tail bytes", one.hex(),
   "1d7c000103c2bdfc00ff8400660a0839000000ff8060"
   "60080839000100ff806067061d7c000003c24ef900123456")
two = flavor_tail(sh["_flavor_by_owner"], 0x3C2, 0xFF8060, 0x123456, b"", TEN, f)
eq("N=2 tail length", len(two), 54 * 2 + 6)
eq("no emit failures", f, [])
for i, (name, tid) in enumerate((("donovan", 0x13), ("huitzil", 0x10))):
    blk = two[i * 54:(i + 1) * 54]
    # cmpi.b #id,(0x382,A6) — the player struct's character-id field
    eq("block %d cmpi" % i, blk[:6].hex(), "0c2e00%02x0382" % tid)
    # bne.s +0x2E: PC after the branch is block+8, so it lands on block+54,
    # i.e. exactly the next block. Uniform at any N — no branch-distance
    # limit, which is why each block exits with its own jmp.
    eq("block %d bne disp" % i, blk[6:8].hex(), "662e")
    eq("block %d lands on next" % i, 8 + 0x2E, 54)
    eq("block %d exits via jmp" % i, blk[48:54].hex(), "4ef900123456")
# a tenant with no entry matches nothing and falls through to the trailing
# jmp — no flavor byte is written for it at all
eq("no cmpi for pyron", "0c2e00110382" in two.hex(), False)
eq("trailing fallthrough jmp", two[108:].hex(), "4ef900123456")
if not bad:
    print("  ok: phase wins, flavor per owner, Pyron unwritten by")
    print("      construction, N=1 byte-identical, N=2 chain verified")

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
echo "      11-collision inventory (2 real blockers), the ratified [init_shim]"
echo "      merge, and 4 permissiveness controls)"
