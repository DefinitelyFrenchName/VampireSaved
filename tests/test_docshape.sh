#!/bin/sh
# test_docshape.sh — every hand-written doc's SHAPE is declared and enforced
# (14z-122, the documentation rationalization pass). ci_portable: no ROM, no
# build dir, no emulator, ~2 s.
#
# WHAT IT HOLDS. `tools/checkdocshape.py` reads docs/doc_shape.tsv (one row
# per document: class, history twin, requirements) and asserts: completeness
# (every .md under docs/ except the generated tables/chars/, plus HANDOFF.md,
# is declared); no session-shaped header in a REFERENCE/REGISTER doc (a
# trailing provenance parenthetical is stripped first); ORIENT holds one `# `
# header and no (HISTORY header; HIST files carry no anchors; twins exist and
# are HIST; declared banner/atlas-rows requirements; no dangling doc link in
# README/HANDOFF/CLAUDE.md; every docs/x.md 'Section' citation in tools/
# and tests/ names a real header. SINCE 14z-124 (G7, the pass's close at
# zero PENDING) the gate runs the tool's --no-pending END-STATE mode: a
# PENDING row FAILS (control h). During the pass (14z-122/123) PENDING was
# skipped here — a red gate for the whole pass would have been a decayed gate.
#
# WHY. The pass moves appended chronology out of reference documents; this is
# the enforcement that stops it growing back (the SMS lesson: staleness is
# defeated by enforcement, not format).
#
# MUST-FIRE CONTROLS on a perturbed copy (RH-9), each must FAIL for its
# stated reason: a chronology header prepended to a REFERENCE doc; an anchor
# in a HIST-class doc; an undeclared file; a dead allow row; a required
# banner absent; a dangling link; a citation of a nonexistent section.
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier ci_portable (~2 s)) EVERY HAND-WRITTEN DOC'S SHAPE IS DECLARED AND
#   ENFORCED (14z-122): `tools/checkdocshape.py` reads `docs/doc_shape.tsv`
#   (one row per doc: class, history twin, requirements; completeness both
#   ways, so a new doc is classified at birth) and lints REFERENCE/REGISTER
#   docs against SESSION-SHAPED HEADERS (a trailing provenance parenthetical —
#   `(measured 14z-N)`, `(paid: 14z-N)` — is stripped by a wrap-tolerant
#   scanner first; a group carrying RETRACTED/superseded words is never
#   stripped), holds ORIENT (NEXT_SESSION) to one `# ` header with history in
#   its twin, forbids anchors in HIST docs, requires declared banners/atlas-
#   rows, resolves every doc link in README/HANDOFF/CLAUDE.md, and verifies
#   every `docs/x.md 'Section'` citation in tools/tests against the file's
#   real headers (backticks normalized, a trailing `...` = prefix). Allowances
#   in `docs/doc_shape_allow.tsv` — a row matching no header FAILS as dead.
#   PENDING rows are skipped until their document's commit flips them; `--no-
#   pending` is the pass-close mode. THIS is what stops the logs re-accreting
#   after the rationalization pass. Seven must-fire controls. First real run
#   found: 26 session-shaped headers (venue_assets + the three gotchas buckets
#   re-classed PENDING for their own commits), CLAUDE.md's docs/annotations.md
#   row promising a file git never saw (retired, open to veto), and three
#   stale section citations
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== test_docshape: doc shapes declared and enforced =="
if python3 tools/checkdocshape.py --no-pending >/tmp/docshape.$$.log 2>&1; then
    ok "checkdocshape.py PASS on the tree ($(grep -o '[0-9]* still PENDING' /tmp/docshape.$$.log | head -1))"
else
    bad "checkdocshape.py FAILS on the tree:"; sed 's/^/        /' /tmp/docshape.$$.log | head -30
fi
rm -f /tmp/docshape.$$.log

FILES="$(python3 tools/checkdocshape.py --list-files)"
mkcopy() {  # mkcopy <dir>
    for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done
    mkdir -p "$1/tools" "$1/tests"
}
control() {  # control <label> <dir> <expected substring>
    if python3 tools/checkdocshape.py --root "$2" --no-selftest >"$2/log" 2>&1; then
        bad "$1: the perturbed copy PASSED — the check is not checking"
    elif grep -q "$3" "$2/log"; then
        ok "$1: fires ($3)"
    else
        bad "$1: failed for the wrong reason:"; sed 's/^/        /' "$2/log" | head -12
    fi
}
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# a: a chronology header in a REFERENCE doc
mkcopy "$W/a"; printf '\n### 14z-999: an appended discovery note\n' >> "$W/a/docs/game/atlas/id_space.md"
control "chronology header in a REFERENCE doc" "$W/a" "SESSION-SHAPED HEADER"

# b: an anchor in a HIST-class doc
mkcopy "$W/b"; printf '\nold analysis **[VSE-1]** moved here\n' >> "$W/b/docs/project/mister_scope.md"
control "anchor in a HIST-class doc" "$W/b" "ANCHOR IN HISTORY-class doc"

# c: an undeclared file
mkcopy "$W/c"; printf '# stray\n' > "$W/c/docs/stray_note.md"
control "undeclared doc" "$W/c" "UNDECLARED docs/stray_note.md"

# d: a dead allow row
mkcopy "$W/d"; printf 'docs/game/atlas/id_space.md\tnever-ever-matches\tstale reason\n' >> "$W/d/docs/doc_shape_allow.tsv"
control "dead allow row" "$W/d" "dead allow row"

# e: a required banner absent (perturb the TSV, not the doc)
mkcopy "$W/e"
sed -i '' 's|^docs/game/atlas/id_space.md\tREFERENCE\t-\t-$|docs/game/atlas/id_space.md\tREFERENCE\t-\tbanner|' "$W/e/docs/doc_shape.tsv"
grep -q 'id_space.md	REFERENCE	-	banner' "$W/e/docs/doc_shape.tsv" || bad "control e: the TSV perturbation did not apply"
control "required banner absent" "$W/e" "NO STATUS BANNER"

# f: a dangling doc link in README
mkcopy "$W/f"; printf '\nsee also [a ghost](game/atlas/ghost_file.md)\n' >> "$W/f/docs/README.md"
control "dangling link" "$W/f" "DANGLING LINK"

# g: a tool citing a section that does not exist
mkcopy "$W/g"; printf '# per docs/game/atlas/id_space.md %sA Section Nobody Wrote%s\n' '"' '"' > "$W/g/tools/synthetic_control.py"
control "citation of a nonexistent section" "$W/g" "SECTION THAT DOES NOT EXIST"

# h: a PENDING row fails the end-state mode the gate runs (since 14z-124)
mkcopy "$W/h"
sed -i '' 's|^docs/game/atlas/id_space.md\tREFERENCE\t-\t-$|docs/game/atlas/id_space.md\tPENDING\t-\t-|' "$W/h/docs/doc_shape.tsv"
grep -q 'id_space.md	PENDING' "$W/h/docs/doc_shape.tsv" || bad "control h: the TSV perturbation did not apply"
if python3 tools/checkdocshape.py --root "$W/h" --no-pending --no-selftest >"$W/h/log" 2>&1; then
    bad "PENDING row under --no-pending: the perturbed copy PASSED — the end state is not enforced"
elif grep -q "still PENDING" "$W/h/log"; then
    ok "PENDING row under --no-pending: fires (still PENDING)"
else
    bad "PENDING row under --no-pending: failed for the wrong reason:"; sed 's/^/        /' "$W/h/log" | head -12
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
