#!/bin/sh
# test_hui_ladder.sh — the Huitzil stage 1-3 ladder gate (14z-65, M3b).
#
# Huitzil is a VARIANT-ID tenant (0x10): no vanilla path can reach his rows,
# so unlike Donovan's M2a ladder (divergence frames pinned per stage) the
# ladder invariant here is total:
#   1. Stages 1-3 BUILD from the huitzil manifest.
#   2. THE OP INVARIANT: every emitted op writes either (a) inside a
#      declared free space (hole_a/hole_b/wide_ext — 0xFF-verified by the
#      allocator) or (b) a VARIANT ROW (slot 0x10-0x1F) of a bank-map
#      table. A variant-id tenant's patch touches no byte legacy content
#      can reach — the superset invariant AT THE OP LEVEL, checked per op.
#   3. A legacy replay on the stage-3 build is BIT-IDENTICAL to the frozen
#      vanilla expectation (whole-RAM, unmasked).
#
# Usage: ROMDIR=... tests/test_hui_ladder.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for st in 1 2 3; do
    echo "== stage $st build"
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1" \
        tools/build_donovan.sh "$st" "$WORK/hui$st" > "$WORK/b$st.log" 2>&1 \
        || { tail -15 "$WORK/b$st.log"; echo "FAIL: stage $st build"; exit 1; }
    echo "  ok: built ($(grep '^build fingerprint' "$WORK/b$st.log" | cut -d' ' -f3 | cut -c1-8))"

    python3 - "$WORK/hui$st/patch/patch.json" <<'PY'
import json, sys
from pathlib import Path

SPACES = [(0x0BF6A0, 0x100000), (0x3EC720, 0x400000), (0x400010, 0x600000)]

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
    if not in_space and not variant_row_ok(a, n):
        bad.append((i, o["op"], hex(a), n))
if bad:
    print("FAIL: ops outside free space + variant rows:", bad)
    sys.exit(1)
print(f"  ok: op invariant holds ({len(ops)} ops: free space or variant rows only)")
PY
done

echo "== legacy replay bit-identity on stage 3 (whole-RAM, unmasked)"
MAME_ROMPATH="$WORK/hui3/rompath;$ROMDIR" \
    tools/run_replay_mame.sh vsavj tests/replays/02_demitri_vs_cpu.rpl \
    "$WORK/r02.log" "$WORK/r02box" > /dev/null 2>&1
sha=$(shasum "$WORK/r02.log" | cut -d' ' -f1)
exp=$(cat "$REPO/tests/expected/vsavj/02_demitri_vs_cpu.sha1")
[ "$sha" = "$exp" ] \
    || { echo "FAIL: replay diverged from vanilla ($sha != $exp)"; exit 1; }
echo "  ok: bit-identical to the frozen vanilla expectation"

echo "PASS: Huitzil stage 1-3 ladder (builds + op invariant + legacy bit-identity)"
