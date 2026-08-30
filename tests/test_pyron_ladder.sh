#!/bin/sh
# test_pyr_ladder.sh — the Pyron stage 1-3 ladder gate (14z-67, M3b Phase 5).
#
# Pyron is a VARIANT-ID tenant (0x11): no vanilla path can reach his rows,
# so the stage 1-3 ladder invariant is total (the H-ladder shape).
# STAGE 4: the generator emits engine-hook sites unconditionally, so its
# op invariant carries exemptions. CORRECTED 14z-92: those exemptions were
# a hardcoded four (obj_hook 0x54470/0x5E542, state_hook 0x2A7C8,
# reaction_hook 0x18458) which were DONOVAN's and went stale at 14z-91 —
# the obj_hook sites are vanilla now and 23 walker-caller writes are new.
# They are read from build/manifest/shared_writes.toml, the reviewed and
# frozen per-tenant inventory, so the set maintains itself,
# and its legacy leg runs on the MASKED V2 basis (CLAUDE.md §4 hooked
# builds), asserted EXACT like H's. Stage-4 extras: the forced-pick
# boot probe (id-hold / load / guard).
#   1. Stages 1-3 BUILD from the pyrtzil manifest.
#   2. THE OP INVARIANT: every emitted op writes either (a) inside a
#      declared free space (hole_a/hole_b/wide_ext — 0xFF-verified by the
#      allocator) or (b) a VARIANT ROW (slot 0x10-0x1F) of a bank-map
#      table. A variant-id tenant's patch touches no byte legacy content
#      can reach — the superset invariant AT THE OP LEVEL, checked per op.
#   3. A legacy replay on the stage-3 build is BIT-IDENTICAL to the frozen
#      vanilla expectation (whole-RAM, unmasked).
#
# Usage: ROMDIR=... tests/test_pyr_ladder.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   the Pyron stage 1-4 ladder (14z-67): builds from pyron.toml, per-stage op
#   invariant (stage 4 exempts exactly the four generator hook sites), forced-
#   pick boot probe, stage-3 UNMASKED legacy bit-identity + stage-4 masked
#   EXACT (V2 basis; V3 parked 14z-88)
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# STAGE 6 IS IN THE LADDER (14z-93, GitHub #90). It used to stop at 4, and
# the boot probe below ran on the stage-4 build. That expectation was never
# valid for this tenant: stages are cumulative and PYRON'S PORT IS STAGE 6 —
# pyron.toml has THREE rows at stage <= 4 (two pcrel_escape_fix and the
# shared hitclass_map_extend) against 44 at stage 6. Forcing char id 0x11
# onto a build with none of his select/char-load machinery and demanding
# "guard: clean" asserts something that build cannot deliver, and once #84
# made the ladder actually build Pyron it duly crashed (CRASH 3020 vec4).
# The frozen pyron-m9 passes the same probe cleanly, so the artifact was
# never the problem.
# The ladder inherited this shape from Huitzil, whose manifest genuinely
# does carry half the port by stage 4 (51 rows). It does not transfer: for
# Donovan it would be worse still — ZERO rows at stage <= 4.
for st in 1 2 3 4 6; do
    echo "== stage $st build"
    # FIXED 14z-92 (GitHub #84). This was:
    #     TENANT_MANIFEST=... TENANT_CHAR=0x11 \
    #     GF="--profile cps2-wide-v1"
    # which the line continuation makes ONE logical line of three
    # ASSIGNMENTS AND NO COMMAND. POSIX sh sets those as ordinary shell
    # variables; they never enter any child's environment. Only GEN_FLAGS
    # was attached to the build below, so `build_donovan.sh` — a separate
    # process — read neither and fell back to its DONOVAN defaults.
    # This ladder was building and validating Donovan at every stage.
    GF="--profile cps2-wide-v1"
    case "$st" in 4|6) GF="$GF --allow-plausible --tripwire-open" ;; esac
    # The stage-6 rung needs the WIDE overlay to pack a vsavjw.zip; the
    # earlier rungs are stock-shaped and pack vsavj.zip.
    WR=""
    [ "$st" = 6 ] && WR="$PWD/build/wide0/rompath/vsavjw.zip"
    TENANT_MANIFEST=build/manifest/pyron.toml TENANT_CHAR=0x11 GEN_FLAGS="$GF" \
    KEY_SET=vsavj WIDE_ROMSET="$WR" \
        tools/build_donovan.sh "$st" "$WORK/pyr$st" > "$WORK/b$st.log" 2>&1 \
        || { tail -15 "$WORK/b$st.log"; echo "FAIL: stage $st build"; exit 1; }
    # ASSERT WHAT WAS ACTUALLY BUILT. The fix above is one line; this is the
    # part that stops the class recurring. A ladder that cannot say which
    # tenant it built is not evidence about that tenant, and every green run
    # of this gate before 14z-92 was evidence about the wrong one.
    TJ="$WORK/pyr$st/patch/tenant.json"
    if [ -f "$TJ" ]; then
        python3 - "$TJ" <<'PY' || { echo "FAIL: stage $st built the wrong tenant"; exit 1; }
import json, sys
t = json.load(open(sys.argv[1]))
if t.get("name") != "pyron" or t.get("id") != 0x11:
    sys.exit(f"  FAIL: built tenant {t.get('name')} id {t.get('id'):#x}, "
             f"expected pyron id 0x11 — the tenant selection did not reach "
             f"build_donovan.sh (GitHub #84)")
print(f"  ok: tenant is {t['name']} id {t['id']:#x}")
PY
    else
        echo "  FAIL: stage $st produced no patch/tenant.json — cannot"
        echo "        confirm WHICH tenant was built (GitHub #84)"
        exit 1
    fi
    echo "  ok: built ($(grep '^build fingerprint' "$WORK/b$st.log" | cut -d' ' -f3 | cut -c1-8))"

    # THE OP INVARIANT IS A STAGE 1-4 CHECK, and 14z-93 scoped it back to
    # that when stage 6 joined the ladder. At stage 6 the tenant
    # legitimately writes select records, HUD rows, palettes and the wheel
    # row — writes that land on vanilla-readable bytes BY DESIGN. The
    # reviewed authority for those is build/manifest/shared_writes.toml,
    # enforced by tests/test_shared_writes.sh, which fails on any addition,
    # removal or change. Re-deriving a second, weaker version of that list
    # here would just be a place for the two to disagree.
    if [ "$st" = 6 ]; then
        echo "  (op invariant: stage 1-4 check, skipped at 6 —"
        echo "   tests/test_shared_writes.sh is the authority there)"
    else
    python3 - "$WORK/pyr$st/patch/patch.json" "$st" <<'PY'
import json, sys
from pathlib import Path

SPACES = [(0x0BF6A0, 0x100000), (0x3EC720, 0x400000), (0x400010, 0x600000)]
# STAGE-4 EXEMPTIONS — REWRITTEN 14z-92 (found by fixing GitHub #84).
# This was a hardcoded {0x54470, 0x5E542, 0x2A7C8, 0x18458}: "the
# generator's four engine-hook sites". Two problems, both invisible until
# the ladder started building the right tenant:
#   1. It was DONOVAN's list. This is the Pyron ladder.
#   2. It went stale at 14z-91, which made the obj_hook dispatch sites
#      VANILLA (0x54470/0x5E542 are no longer written at all) and added 23
#      walker-CALLER operand writes that are not in it. So the invariant
#      would fail for EITHER tenant now — it had simply not been run.
#      That is GitHub #30 demonstrated: a gate nothing calls decays, and
#      this one decayed silently for a full session.
# The fix defers to the REVIEWED AUTHORITY instead of a literal list:
# build/manifest/shared_writes.toml is the frozen per-tenant inventory of
# every write landing on vanilla-readable bytes, and tests/
# test_shared_writes.sh already fails on any addition, removal or change.
# So "free space, a variant row, or a write someone reviewed and froze" is
# the real invariant, and it maintains itself.
HOOK_SITES = set()
if sys.argv[2] == "4":
    import re as _re
    _txt = Path("build/manifest/shared_writes.toml").read_text()
    # [[tenant]] blocks; take the pyron one's `writes = [ "0xADDR N kind", ]`
    for _blk in _txt.split("[[tenant]]")[1:]:
        if not _re.search(r'name\s*=\s*"pyron"', _blk):
            continue
        for _m in _re.finditer(r'"0x([0-9A-Fa-f]+)\s+\d+\s+\w+"', _blk):
            HOOK_SITES.add(int(_m.group(1), 16))
    if not HOOK_SITES:
        sys.exit("  FAIL: no pyron rows in shared_writes.toml — the "
                 "stage-4 exemption set would be empty, which is not a "
                 "pass condition, it is a dead lookup")

# bank-map tables: (base, entry_size) via the minimal subset parser shape
import re
tables = []
txt = Path("build/manifest/bank_map.toml").read_text()
for block in txt.split("[[table]]")[1:]:
    row = {}
    for m in re.finditer(r'^(\w+)\s*=\s*("[^"]*"|0x[0-9A-Fa-f]+|\d+)',
                         block, re.M):
        k, v = m.group(1), m.group(2).strip('"')
        row[k] = v
    if "vsavj" not in row:
        continue
    base = int(row["vsavj"], 0)
    if row.get("kind") == "byte2d":
        es = int(row["span"], 0) // 32
    else:
        es = int(row.get("stride", "0x80"), 0) // 32
    tables.append((row.get("name", "?"), base, es))

def op_span(pdir, o):
    a = int(o["addr"], 0)
    k = o["op"]
    if k == "poke16": n = 2
    elif k == "poke32": n = 4
    elif k in ("data", "code"): n = len(o["hex"]) // 2
    else: n = (pdir / o["path"]).stat().st_size
    return a, n

def variant_row_ok(a, n):
    for name, base, es in tables:
        lo, hi = base + 0x10 * es, base + 0x20 * es
        if lo <= a and a + n <= hi:
            return True
    return False

pdir = Path(sys.argv[1]).parent
ops = json.load(open(sys.argv[1]))["ops"]
bad = []
for i, o in enumerate(ops):
    a, n = op_span(pdir, o)
    in_space = any(s <= a and a + n <= e for s, e in SPACES)
    if a in HOOK_SITES and n <= 6:
        continue
    if not in_space and not variant_row_ok(a, n):
        bad.append((i, o["op"], hex(a), n))
if bad:
    print("FAIL: ops outside free space + variant rows:", bad)
    sys.exit(1)
print(f"  ok: op invariant holds ({len(ops)} ops: free space / variant "
      f"rows{' / %d reviewed shared writes' % len(HOOK_SITES) if HOOK_SITES else ''})")
PY
    fi
done

# THE BOOT PROBE RUNS ON THE STAGE-6 RUNG (14z-93, GitHub #90) — the rung
# that carries Pyron's port, and the one that corresponds to what ships.
echo "== stage-6 boot probe (forced pick, id 0x11)"
SET=vsavjw tools/force_pick_probe.sh "$WORK/pyr6/rompath" 11 "$WORK/probe" > "$WORK/probe.txt" 2>&1 || {
    cat "$WORK/probe.txt"; echo "FAIL: boot probe errored"; exit 1; }
grep -q 'id-hold @2600: \$FF8782 = 0x11' "$WORK/probe.txt" || {
    cat "$WORK/probe.txt"; echo "FAIL: forced id did not hold"; exit 1; }
grep -q 'char LOADED' "$WORK/probe.txt" || {
    cat "$WORK/probe.txt"; echo "FAIL: his data did not load"; exit 1; }
grep -q 'guard        : clean' "$WORK/probe.txt" || {
    cat "$WORK/probe.txt"; echo "FAIL: guard tripped"; exit 1; }
echo "  ok: id holds, his data loads, guard clean"

echo "== legacy bit-identity on stage 3 (whole-RAM, unmasked — hook-free)"
MAME_ROMPATH="$WORK/pyr3/rompath;$ROMDIR" \
    tools/run_replay_mame.sh vsavj tests/replays/02_demitri_vs_cpu.rpl \
    "$WORK/r02.log" "$WORK/r02box" > /dev/null 2>&1
sha=$(shasum "$WORK/r02.log" | cut -d' ' -f1)
exp=$(cat "$REPO/tests/expected/vsavj/02_demitri_vs_cpu.sha1")
[ "$sha" = "$exp" ] \
    || { echo "FAIL: stage-3 replay diverged from vanilla ($sha != $exp)"; exit 1; }
echo "  ok: bit-identical to the frozen vanilla expectation"

echo "== legacy under the v2 masked basis on stage 4 (hooked build)"
MASK_RANGES="$(cat "$REPO/tests/expected/donovan-m5/mask")" \
MAME_ROMPATH="$WORK/pyr4/rompath;$ROMDIR" \
    tools/run_replay_mame.sh vsavj tests/replays/02_demitri_vs_cpu.rpl \
    "$WORK/r02m.log" "$WORK/r02mbox" > /dev/null 2>&1
python3 "$REPO/tools/compare_flicker.py" "$WORK/r02m.log" \
    "$REPO/tests/expected/vsavj/masked-v2/logs/02_demitri_vs_cpu.log" \
    | grep -q "^EXACT" \
    || { echo "FAIL: stage-4 legacy not masked-EXACT"; exit 1; }
echo "  ok: masked-v2 EXACT vs the frozen vanilla log"

echo "PASS: Pyron stage 1-4+6 ladder (builds + op invariant + stage-6 boot probe + legacy bit-identity)"
