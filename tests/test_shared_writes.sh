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
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-79b: THE FROZEN SHARED-SURFACE WRITE INVENTORY. test_hui_ladder.sh
#   already requires every op to write free space or a VARIANT ROW — but it
#   runs stages 1-3, and the row that broke Bulleta was stage 4. Every write
#   landing on vanilla-readable bytes is frozen per tenant in build/manifest/
#   shared_writes.toml (D 67 / H 59 / P 50); any addition, removal or change
#   FAILS, which is the point — it forces someone to establish whose bytes a
#   new write touches. GROUND-TRUTHED: it flags 0x39acc0 +128 on build/hui27,
#   the real defect. + 2 verdict controls. HONEST LIMIT, stated in the tool: a
#   pass means the set is UNCHANGED SINCE REVIEWED, not that the writes are
#   safe; an entry frozen without checking stays wrong and green. tools/
#   audit_shared_writes.py. Static, seconds
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

echo "== 4. THE AUTO-STRIDE BLIND SPOT STAYS CLOSED (14z-128)"
# WHAT THIS LOCKS. The audit exempts a write that lands on a per-character
# table's VARIANT half, computed as `base + 0x10*es .. base + 0x20*es` with
# `es = stride/32` read from bank_map.toml. For a `kind = "auto"` row the
# stride is the SCANNER'S DEFAULT, not a measurement — so the window is not
# the variant half and the exemption lands somewhere else entirely.
#
# It did. `gap_be27a` (auto, stride 0x40) gave es=2 and a window of
# 0x0BE29A-0x0BE2BA on a table whose entries are LONGWORDS: those are rows
# 0x08-0x0F of the capture-keyframe pointer table — Bishamon, Aulbath,
# Sasquatch, 0x0B, Q-Bee, Lei-Lei, Lilith, Jedah. EIGHT LEGACY ROWS, exempted
# by the one gate whose purpose is to make a legacy-surface write a
# build-time review. Nine writes per tenant build sat inside it (the #104
# capture-pose port) and never reached the inventory.
#
# Two-sided control, on a synthetic root so it cannot depend on the real
# manifests: a MEASURED table exempts its variant window, and the SAME table
# marked `auto` exempts nothing.
python3 - "$WORK" <<'PY' || fail=1
import json, shutil, subprocess, sys
from pathlib import Path
work = Path(sys.argv[1]) / "autostride"
shutil.rmtree(work, ignore_errors=True)
(work / "tools").mkdir(parents=True)
(work / "build/manifest").mkdir(parents=True)
(work / "build/fake/patch").mkdir(parents=True)
shutil.copy("tools/audit_shared_writes.py", work / "tools")
for m in ("donovan", "huitzil", "pyron"):
    # one declared free space, far from the fixture tables
    (work / f"build/manifest/{m}.toml").write_text(
        '[[space]]\nstart = 0x700000\nend = 0x700100\n')
BASE = 0x0B0000
def bank_map(kind):
    return (f'[[table]]\nname = "fixture"\nvsavj = 0x{BASE:06X}\n'
            f'kind = "{kind}"\nstride = 0x80\n')
# one write inside the variant window of a stride-0x80 table: base + 0x10*4
addr = BASE + 0x10 * 4
(work / "build/fake/patch/patch.json").write_text(json.dumps(
    {"ops": [{"op": "poke32", "addr": hex(addr), "val": "0x400000"}]}))
seen = {}
for kind in ("data_ptr", "auto"):
    (work / "build/manifest/bank_map.toml").write_text(bank_map(kind))
    r = subprocess.run(["python3", str(work / "tools/audit_shared_writes.py"),
                        str(work / "build/fake"), "--json"],
                       capture_output=True, text=True)
    rows = json.loads(r.stdout) if r.stdout.strip().startswith("[") else []
    seen[kind] = any(int(x["addr"], 16) == addr for x in rows)
ok = (seen["data_ptr"] is False) and (seen["auto"] is True)
print(f"  control: a MEASURED (data_ptr) table exempts its variant window: "
      f"{'yes' if not seen['data_ptr'] else 'NO — the exemption is gone'}")
print(f"  control: the SAME table as `auto` exempts nothing: "
      f"{'yes' if seen['auto'] else 'NO — the blind spot is back'}")
sys.exit(0 if ok else 1)
PY
# And the regression lock on the real tree: the nine capture-keyframe rows the
# blind spot used to hide must be VISIBLE to the audit on a current build.
# Addresses, not a count: a count moves with unrelated work.
HID="0x0be29a 0x0be29e 0x0be2a2 0x0be2a6 0x0be2aa 0x0be2ae 0x0be2b2 0x0be2b6 0x0be2da"
CUR=""
for b in build/m3b_merged21 build/don_m18 build/hui52 build/pyron36; do
    [ -f "$b/patch/patch.json" ] && { CUR="$b"; break; }
done
if [ -z "$CUR" ]; then
    echo "  SKIP (no current build to check the capture-keyframe rows on)"
else
    inv="$(python3 tools/audit_shared_writes.py "$CUR" 2>/dev/null || true)"
    miss=""
    for a in $HID; do
        printf '%s' "$inv" | grep -q "\"$a " || miss="$miss $a"
    done
    if [ -n "$miss" ]; then
        echo "  FAIL: on $CUR these capture-keyframe rows are NOT in the"
        echo "        inventory —$miss"
        echo "        That is the 14z-128 blind spot, back."
        fail=1
    else
        echo "  ok: all nine capture-keyframe rows (0x0be29a-0x0be2b6, 0x0be2da)"
        echo "      are visible to the audit on $CUR"
    fi
fi

[ "$fail" -ne 0 ] && { echo "FAIL: shared-surface write inventory"; exit 1; }
echo "PASS: shared-surface writes match the frozen, reviewed inventory"
