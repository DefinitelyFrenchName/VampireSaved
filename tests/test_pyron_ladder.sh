#!/bin/sh
# test_pyr_ladder.sh — the Pyron stage 1-3 ladder gate (14z-67, M3b Phase 5).
#
# Pyron is a VARIANT-ID tenant (0x11): no vanilla path can reach his rows,
# so the stage 1-3 ladder invariant is total (the H-ladder shape).
# STAGE 4 (14z-67 measured): the generator emits the FOUR engine-hook
# sites unconditionally (obj_hook 0x54470/0x5E542, state_hook 0x2A7C8,
# reaction_hook 0x18458 — extension tables tripwired for the unported)
# — so its op invariant carries exactly those four named exemptions,
# and its legacy leg runs on the current MASKED basis (V3 since 14z-88; CLAUDE.md §4 hooked
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
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for st in 1 2 3 4; do
    echo "== stage $st build"
    TENANT_MANIFEST=build/manifest/pyron.toml TENANT_CHAR=0x11 \
    GF="--profile cps2-wide-v1"
    [ "$st" = 4 ] && GF="$GF --allow-plausible --tripwire-open"
    GEN_FLAGS="$GF" \
        tools/build_donovan.sh "$st" "$WORK/pyr$st" > "$WORK/b$st.log" 2>&1 \
        || { tail -15 "$WORK/b$st.log"; echo "FAIL: stage $st build"; exit 1; }
    echo "  ok: built ($(grep '^build fingerprint' "$WORK/b$st.log" | cut -d' ' -f3 | cut -c1-8))"

    python3 - "$WORK/pyr$st/patch/patch.json" "$st" <<'PY'
import json, sys
from pathlib import Path

SPACES = [(0x0BF6A0, 0x100000), (0x3EC720, 0x400000), (0x400010, 0x600000)]
# stage 4: the generator's four engine-hook sites (unconditional,
# 6-byte thunk calls; extension tables tripwired) — named exemptions
HOOK_SITES = {0x54470, 0x5E542, 0x2A7C8, 0x18458} \
    if sys.argv[2] == "4" else set()

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
      f"rows{' / 4 named hook sites' if HOOK_SITES else ''})")
PY
done

echo "== stage-4 boot probe (forced pick, id 0x11)"
tools/force_pick_probe.sh "$WORK/pyr4/rompath" 11 "$WORK/probe" > "$WORK/probe.txt" 2>&1 || {
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
MASK_RANGES="$(cat "$REPO/tests/expected/donovan-m6/mask")" \
MAME_ROMPATH="$WORK/pyr4/rompath;$ROMDIR" \
    tools/run_replay_mame.sh vsavj tests/replays/02_demitri_vs_cpu.rpl \
    "$WORK/r02m.log" "$WORK/r02mbox" > /dev/null 2>&1
python3 "$REPO/tools/compare_flicker.py" "$WORK/r02m.log" \
    "$REPO/tests/expected/vsavj/masked-v3/logs/02_demitri_vs_cpu.log" \
    | grep -q "^EXACT" \
    || { echo "FAIL: stage-4 legacy not masked-EXACT"; exit 1; }
echo "  ok: masked-v3 EXACT vs the frozen vanilla log"

echo "PASS: Pyron stage 1-4 ladder (builds + op invariant + boot probe + legacy bit-identity)"
