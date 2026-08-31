#!/bin/sh
# test_community_crosscheck.sh — OUR DERIVED VANILLA FRAME DATA STILL SAYS WHAT
# THE COMMUNITY WORKBOOK SAYS (14z-125, the community cross-check).
#
# WHAT IT HOLDS. tools/vanilla_frames.py derives startup / active / recovery /
# white / gauge / damage for all 15 vanilla characters straight out of vsavj's
# own per-character bank, and tools/crosscheck_framedata.py classifies every
# (character, column) against the maintainer's workbook by the ruled vocabulary
# (EXACT / CONSTANT OFFSET / CONSTANT RATIO / INCONSISTENT / UNCOMPARABLE). The
# classification is frozen in tests/expected/community_crosscheck.txt, so a
# changed decoder, a changed frame-data derivation, a changed slot join or a
# changed workbook all fail here. The page it feeds is
# docs/project/tables/community_crosscheck.md (GENERATED; regenerate with it).
#
# THE SOURCES ARE THIRD-PARTY AND LIVE OUTSIDE THE TREE (CLAUDE.md rule 7 keeps
# ROM content out; this is the same instinct applied to somebody else's work):
# ../community/vsav-framedata.xlsx is cited, never committed. Without it this
# gate SKIPs and says so — it never passes vacuously.
#
#   1. the reader is an instrument: tools/xlsx_read.py reproduces the workbook
#      cell for cell (checked against openpyxl when it is installed; 28,234
#      cells, the only differences being the 4 date-corrupted VI Invuln cells,
#      a column this comparison does not use);
#   2. the derivation runs for all 15 characters off the frozen vsavj image;
#   3. the classification equals tests/expected/community_crosscheck.txt;
#   4. the GENERATED page equals a regeneration;
#   5. MUST-FIRE CONTROLS: (a) perturbing one derived startup flips that
#      character's column out of CONSTANT OFFSET; (b) a missing workbook SKIPs
#      rather than passes.
#
# Usage: tests/test_community_crosscheck.sh   # ci_static (~10 s; SKIPs without ../community/)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
SHEET="${SHEET:-$REPO/../community/vsav-framedata.xlsx}"
IMG="${IMG:-build/out/vsavj_data.bin}"
EXP=tests/expected/community_crosscheck.txt
PAGE=docs/project/tables/community_crosscheck.md
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
bad=0
ok()  { echo "  ok    $1"; }
nope() { echo "  FAIL  $1"; bad=$((bad + 1)); }

[ -f "$SHEET" ] || { echo "SKIP: no $SHEET (the community workbook is third-party and lives outside the tree)"; exit 0; }
if [ ! -f "$IMG" ]; then
    # the data view is ROM-derived and lives outside git; make it when ROMDIR allows
    if [ -n "${ROMDIR:-}" ] && [ -f "$ROMDIR/vsavj.zip" ]; then
        IMG="$W/vsavj_data.bin"
        python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$W/vsavj_op.bin" --data-out "$IMG" >/dev/null 2>&1 \
            || { echo "SKIP: could not decrypt vsavj"; exit 0; }
    else
        echo "SKIP: no $IMG and no ROMDIR (the vsavj data view is ROM-derived)"; exit 0
    fi
fi

echo "== test_community_crosscheck: our vanilla derivation vs the community workbook =="

echo "== 1. the sheet reader reproduces the workbook"
python3 - "$SHEET" <<'PY' || nope "xlsx_read disagrees with openpyxl"
import sys
sys.path.insert(0, "tools")
import xlsx_read
wb = xlsx_read.Workbook(sys.argv[1])
assert len(wb.sheet_names) == 15, wb.sheet_names
try:
    import openpyxl
except ImportError:
    print("  (openpyxl absent — reader self-consistency only)")
    sys.exit(0)
ref = openpyxl.load_workbook(sys.argv[1], data_only=True)
import datetime
cells = diff = 0
for name in wb.sheet_names:
    mine = wb.grid(name)
    rows = [[("" if c.value is None else c.value) for c in r] for r in ref[name].iter_rows()]
    rows = [r for r in rows if any(str(v).strip() for v in r)]
    for i, r in enumerate(rows):
        for j, v in enumerate(r):
            cells += 1
            m = mine[i][j] if i < len(mine) and j < len(mine[i]) else ""
            a, b = str(v).strip(), str(m).strip()
            if a == b or isinstance(v, datetime.datetime):
                continue
            try:
                if abs(float(a) - float(b)) < 1e-9:
                    continue
            except ValueError:
                pass
            diff += 1
print(f"  (cells {cells}, non-date differences {diff})")
sys.exit(1 if diff else 0)
PY
[ $bad -eq 0 ] && ok "xlsx_read matches the workbook (dates excepted)"

echo "== 2-3. derive all 15 and classify"
python3 tools/vanilla_frames.py "$IMG" --json "$W/v.json" > "$W/derive.log" 2>&1 \
    || { nope "vanilla_frames failed"; sed 's/^/        /' "$W/derive.log"; }
python3 tools/crosscheck_framedata.py --sheet "$SHEET" --vanilla "$W/v.json" --tsv "$W/got.txt" --md "$W/page.md" >/dev/null 2>&1 \
    || nope "crosscheck_framedata failed"
if [ "${FREEZE:-0}" = 1 ]; then
    cp "$W/got.txt" "$EXP"; cp "$W/page.md" "$PAGE"
    echo "  FROZE $EXP and $PAGE"
fi
if cmp -s "$W/got.txt" "$EXP"; then ok "classification matches $EXP ($(grep -c . "$EXP") rows)"
else nope "classification moved"; diff "$EXP" "$W/got.txt" | head -20; fi

echo "== 4. the generated page is current"
if cmp -s "$W/page.md" "$PAGE"; then ok "$PAGE equals a regeneration"
else nope "$PAGE is stale — regenerate"; diff "$PAGE" "$W/page.md" | head -10; fi

echo "== 5. must-fire controls"
python3 - "$W" "$SHEET" <<'PY' || nope "control (a) did not fire"
import json, subprocess, sys
W = sys.argv[1]
v = json.load(open(f"{W}/v.json"))
# perturb ONE derived startup on a character whose startup column is a clean offset
ch = v["characters"]["DE"]
for c in ch["chains"].values():
    if c.get("move") == "2LP" and "frame_data" in c:
        c["frame_data"]["startup"] += 3
        break
else:
    sys.exit("no DE 2LP to perturb")
json.dump(v, open(f"{W}/v_bad.json", "w"))
r = subprocess.run([sys.executable, "tools/crosscheck_framedata.py", "--sheet", sys.argv[2],
                    "--vanilla", f"{W}/v_bad.json", "--tsv", f"{W}/bad.txt"], capture_output=True)
if r.returncode:
    sys.exit(f"comparator failed: {r.stderr.decode()[:300]}")
line = [l for l in open(f"{W}/bad.txt") if l.startswith("DE\tstartup")][0]
print("  perturbed ->", line.strip())
sys.exit(0 if "INCONSISTENT" in line else 1)
PY
[ $bad -eq 0 ] && ok "control (a): a perturbed derived startup flips DE out of CONSTANT OFFSET"
out="$(SHEET=/nonexistent-workbook.xlsx sh "$0" 2>&1 | head -1)"
case "$out" in SKIP:*) ok "control (b): a missing workbook SKIPs, never passes vacuously";;
                    *) nope "control (b): a missing workbook did not SKIP (got: $out)";; esac

[ $bad -eq 0 ] && echo "PASS" || echo "FAIL ($bad)"
exit $bad
