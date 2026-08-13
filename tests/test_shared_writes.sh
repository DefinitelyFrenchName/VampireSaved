#!/bin/sh
# test_shared_writes.sh — the frozen shared-surface write inventory (14z-79).
#
# WHAT IT LOCKS. Every build op that lands outside declared free space and
# outside a known variant row is enumerated per tenant in
# build/manifest/shared_writes.toml. Any addition, removal or change fails.
#
# WHY. `tests/test_hui_ladder.sh` already requires every op to write free space
# or a VARIANT ROW — but it runs stages 1-3, and the row that broke Bulleta was
# stage 4: `data_port df_palette_seq_rows` wrote 0x80 bytes at vsavj 0x39ACC0,
# which is palette-seq ids 0x1E-0x21 = BULLETA'S Dark Force block. It shipped in
# 14z-69 and rendered a LEGACY character wrong for ten sessions, invisible to
# every RAM gate. This gate makes the next one of those a build-time event.
#
# HONEST LIMIT (say it out loud, because a green run is easy to over-read): a
# pass means the set is UNCHANGED SINCE IT WAS REVIEWED, not that it is safe.
# An entry frozen without checking whose bytes it lands on stays wrong and
# green. When it fails, establish whose bytes the new write touches — do not
# re-freeze until it passes.
#
# Sections:
#   1. each tenant build matches its frozen inventory
#   2. POSITIVE CONTROL — the instrument flags the real defect: the withdrawn
#      DF-palette write is present in build/hui27's inventory (that build is
#      the frozen huitzil-m2, which carried it)
#   3. VERDICT CONTROLS — a synthetic added write and a synthetic removed
#      write must each be CAUGHT
#
# Static, no emulator, seconds. Builds it cannot find are SKIPPED with a note
# (a fresh checkout has no build dirs).
# Usage: tests/test_shared_writes.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
fail=0
seen=0

echo "== 1. each tenant build matches its frozen inventory"
# The build dir per tenant comes from the TOML's own `build =` field
# (14z-84: the pins were hardcoded here and rotted two freezes behind —
# hui29/pyron20 while the frozen builds were m5/m3 — so the gate
# compared frozen inventories against superseded images and read the
# newly-reviewed entries as GONE).
PAIRS="$(python3 - <<'PY'
import re
s = open("build/manifest/shared_writes.toml").read()
for m in re.finditer(r'name = "(\w+)"\s*\nbuild = "build/([^"]+)"', s):
    print(f"{m.group(1)}:{m.group(2)}")
PY
)"
for pair in $PAIRS; do
    t=${pair%%:*}; b=${pair#*:}
    if [ ! -f "build/$b/patch/patch.json" ]; then
        echo "  SKIP $t (no build/$b)"; continue
    fi
    seen=$((seen + 1))
    if out=$(python3 tools/audit_shared_writes.py "build/$b" --tenant "$t" 2>&1); then
        echo "  $(echo "$out" | tail -1)"
    else
        echo "$out" | grep -E "^FAIL|NEW|GONE" | sed 's/^/    /'
        fail=1
    fi
done
[ "$seen" -gt 0 ] || { echo "SKIP: no tenant builds present"; exit 0; }

echo "== 2. positive control — the instrument sees the real defect"
if [ -f "build/hui27/patch/patch.json" ]; then
    if python3 tools/audit_shared_writes.py build/hui27 | grep -q '"0x39acc0 128 data"'; then
        echo "  ok: 0x39acc0 +128 (the withdrawn DF-palette row that broke"
        echo "      Bulleta) IS flagged as a shared-surface write on hui27"
    else
        echo "  FAIL: the audit does NOT flag 0x39acc0 on build/hui27 — it"
        echo "        cannot see the class it exists for"
        fail=1
    fi
else
    echo "  SKIP (no build/hui27 to control against)"
fi

echo "== 3. verdict controls (each MUST be caught)"
python3 - "$WORK" <<'PY' || fail=1
import json, re, shutil, subprocess, sys
from pathlib import Path
work = Path(sys.argv[1])
# the control mutates the CURRENT frozen huitzil build — from the toml's
# own build field (14z-84: a hardcoded pin here rotted exactly like the
# section-1 pins did)
import re as _re
_m = _re.search(r'name = "huitzil"\s*\nbuild = "([^"]+)"',
                open("build/manifest/shared_writes.toml").read())
src = Path(_m.group(1))
if not (src / "patch/patch.json").exists():
    print(f"  SKIP (no {src})"); sys.exit(0)
ok = True
for tag, mutate in (
    ("an ADDED shared write (a new byte poked into vanilla space)",
     lambda ops: ops + [{"op": "poke16", "addr": "0x030000", "hex": "0000"}]),
    ("a REMOVED shared write (an engine hook silently dropped)",
     lambda ops: [o for o in ops if int(o["addr"], 0) != 0x018460]),
):
    d = work / re.sub(r"\W+", "_", tag)[:24]
    shutil.rmtree(d, ignore_errors=True)
    shutil.copytree(src, d, symlinks=True,
                    ignore=shutil.ignore_patterns("rompath", "extract", "gfx"))
    pj = d / "patch/patch.json"
    doc = json.load(open(pj))
    doc["ops"] = mutate(doc["ops"])
    json.dump(doc, open(pj, "w"))
    r = subprocess.run(["python3", "tools/audit_shared_writes.py", str(d),
                        "--tenant", "huitzil"], capture_output=True, text=True)
    caught = r.returncode != 0
    print(f"  control: {tag}: {'CAUGHT' if caught else 'MISSED'}")
    ok = ok and caught
# and the positive half: the UNMUTATED build must still pass, so the controls
# are not passing merely because everything mismatches
r = subprocess.run(["python3", "tools/audit_shared_writes.py", str(src),
                    "--tenant", "huitzil"], capture_output=True, text=True)
print(f"  control: the UNMUTATED build still passes: {r.returncode == 0}")
sys.exit(0 if ok and r.returncode == 0 else 1)
PY

[ "$fail" -ne 0 ] && { echo "FAIL: shared-surface write inventory"; exit 1; }
echo "PASS: shared-surface writes match the frozen, reviewed inventory"
