#!/bin/sh
# test_community_crosscheck.sh — OUR DERIVED VANILLA FRAME DATA STILL SAYS WHAT
# THE COMMUNITY WORKBOOK SAYS (14z-125, the community cross-check).
#
# MUST-FIRE: perturbed-copy: perturbed-startup — one derived startup moved by three frames must flip that character's column out of CONSTANT OFFSET (mode: the perturbed derivation is what sections 3-4 classify, and this run must fail)
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
# THE FRAME-DATA RULE (maintainer, 2026-08-31, STATE 14z-126): the committed page
# is the VERDICT-ONLY rendering — verdicts, mechanisms, counts and "What is NOT
# known", no per-move number of ours or the workbook's. The full move-by-move
# comparison is written OUT of the tree by tools/framedata_pages.sh
# (--md-full -> ../charpages/framedata/community_crosscheck_full.md). This gate
# checks the committed page against a --md regeneration, so the split is locked:
# a per-move value creeping back into the public page fails section 4.
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
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
perturb_startup() {  # perturb_startup <in.json> <out.json> — DE 2LP's startup + 3
    python3 - "$1" "$2" <<'PY'
import json, sys
v = json.load(open(sys.argv[1]))
ch = v["characters"]["DE"]
for c in ch["chains"].values():
    if c.get("move") == "2LP" and "frame_data" in c:
        c["frame_data"]["startup"] += 3
        break
else:
    sys.exit("no DE 2LP to perturb")
json.dump(v, open(sys.argv[2], "w"))
PY
}

[ -f "$SHEET" ] || { echo "SKIP: no $SHEET (the community workbook is third-party and lives outside the tree)"; exit 0; }
if [ ! -f "$IMG" ]; then
    # the data view is ROM-derived and lives outside git; take it from the shared
    # decrypt CACHE (tests/lib/decrypt_cache.sh) — never shell out to the decrypt
    # directly, which is what tests/test_decrypt_cache.sh section 5 enforces
    if [ -n "${ROMDIR:-}" ] || [ -f build/out/vsavj_data.bin ]; then
        . "$REPO/tests/lib/decrypt_cache.sh"
        decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 \
            || { echo "SKIP: no vsavj data view and the cache could not fill it"; exit 0; }
        IMG="$W/vsavj_data.bin"
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
# THE EXECUTABLE FORM: under CONTROL=perturbed-startup the perturbed derivation
# IS what is classified, and this run must FAIL.
VJSON="$W/v.json"
if vs_ctl_is perturbed-startup; then perturb_startup "$W/v.json" "$W/v_mode.json" || nope "could not perturb the derivation"; VJSON="$W/v_mode.json"; fi
python3 tools/crosscheck_framedata.py --sheet "$SHEET" --vanilla "$VJSON" --tsv "$W/got.txt" --md "$W/page.md" >/dev/null 2>&1 \
    || nope "crosscheck_framedata failed"
if [ "${FREEZE:-0}" = 1 ] && [ -z "$VS_CTL" ]; then
    cp "$W/got.txt" "$EXP"; cp "$W/page.md" "$PAGE"
    echo "  FROZE $EXP and $PAGE"
fi
if cmp -s "$W/got.txt" "$EXP"; then ok "classification matches $EXP ($(grep -c . "$EXP") rows)"
else nope "classification moved"; diff "$EXP" "$W/got.txt" | head -20; fi

echo "== 4. the generated page is current"
if cmp -s "$W/page.md" "$PAGE"; then ok "$PAGE equals a regeneration"
else nope "$PAGE is stale — regenerate"; diff "$PAGE" "$W/page.md" | head -10; fi

echo "== 5. must-fire controls"
# (a) perturb ONE derived startup on a character whose startup column is a clean offset
perturb_startup "$W/v.json" "$W/v_bad.json" || nope "control (a): could not perturb"
python3 tools/crosscheck_framedata.py --sheet "$SHEET" --vanilla "$W/v_bad.json" --tsv "$W/bad.txt" >/dev/null 2>&1 || nope "control (a): comparator failed"
line="$(grep '^DE	startup' "$W/bad.txt" | head -1)"
echo "  perturbed -> $line"
case "$line" in
*INCONSISTENT*) vs_ctl_fired perturbed-startup "a perturbed derived startup flips DE out of CONSTANT OFFSET"; ok "control (a) fires" ;;
*)              vs_ctl_dead perturbed-startup "DE's startup column did not flip: $line"; nope "control (a)" ;;
esac
out="$(CONTROL= SHEET=/nonexistent-workbook.xlsx sh "$0" 2>&1 | head -1)"
case "$out" in SKIP:*) ok "control (b): a missing workbook SKIPs, never passes vacuously";;
                    *) nope "control (b): a missing workbook did not SKIP (got: $out)";; esac

[ $bad -eq 0 ] && echo "PASS" || echo "FAIL ($bad)"
exit $bad
