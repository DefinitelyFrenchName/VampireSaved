#!/bin/sh
# test_docshape.sh — every hand-written doc's SHAPE is declared and enforced
# (14z-122, the documentation rationalization pass). ci_portable: no ROM, no
# build dir, no emulator, ~2 s.
#
# MUST-FIRE: perturbed-copy: chronology-header — a session-shaped header appended to a REFERENCE doc must be reported
# MUST-FIRE: perturbed-copy: anchor-in-hist — a rule anchor in a HIST-class doc must be reported
# MUST-FIRE: perturbed-copy: undeclared-doc — a markdown file with no doc_shape row must be reported
# MUST-FIRE: perturbed-copy: dead-allow-row — an allow row matching nothing must be reported, or allowances rot
# MUST-FIRE: perturbed-copy: banner-absent — a doc the TSV requires a banner of, without one, must be reported
# MUST-FIRE: perturbed-copy: dangling-link — a README link to a file that is not there must be reported
# MUST-FIRE: perturbed-copy: nonexistent-section — a tool citing a doc section that does not exist must be reported
# MUST-FIRE: perturbed-copy: pending-row — a PENDING row under the end-state mode this gate runs must be reported
# MUST-FIRE: perturbed-copy: bold-chronology — a bold `Previous batch (14z-N)` paragraph in a REFERENCE doc must be reported (the header rule's blind spot)
# MUST-FIRE: perturbed-copy: dropped-from-contents — a declared doc absent from README Contents must be reported
# MUST-FIRE: perturbed-copy: shape-tag-flipped — a Contents shape tag disagreeing with the declaration must be reported
# MUST-FIRE: perturbed-copy: twin-no-backlink — a history twin not naming its live doc must be reported
# MUST-FIRE: perturbed-copy: live-no-twin-link — a live doc not naming its twin must be reported (the other direction)
# MUST-FIRE: perturbed-copy: directory-entry-member — a directory entry that stops naming a member must expose that member as missing from Contents
# MUST-FIRE: perturbed-copy: entry-point-off-map — an entry-point doc named nowhere in the README must be reported
#
# WHAT IT HOLDS. `tools/checkdocshape.py` reads docs/doc_shape.tsv (one row
# per document: class, history twin, requirements) and asserts: completeness
# (every .md under docs/, plus HANDOFF.md, is declared — the generated
# tables/chars/ pages were excluded by a hard-coded prefix until 14z-140 and
# are declared GENERATED instead); no session-shaped header in a
# REFERENCE/REGISTER doc (a
# trailing provenance parenthetical is stripped first); no BOLD CHRONOLOGY
# PARAGRAPH in one either (14z-126b — a paragraph-opening bold run that LEADS
# with a session token or a `Previous batch` announcement AND carries a
# session token; a bold opener that merely carries provenance is a fact and
# passes, and a `SUPERSEDED`/`RETRACTED` lead is never barred because
# [VSP-13] step 4 requires that marker to stay in the body prose);
# ORIENT holds one `# `
# header and no (HISTORY header; HIST files carry no anchors; twins exist and
# are HIST; declared banner/atlas-rows requirements; no dangling doc link in
# README/HANDOFF/CLAUDE.md; every docs/x.md 'Section' citation in tools/
# and tests/ names a real header. SINCE 14z-140 (living-docs slice L1) it also
# asserts ROUTING — that the map REACHES every document: README COMPLETENESS
# (every shape row listed in docs/README.md's `## Contents` with its declared
# shape; a directory entry counts for the members its own line NAMES; a row
# declared `entry-point` is exempt from Contents, which excludes the level-0
# entry points on purpose, but must still be named somewhere in the README)
# and TWO-WAY TWINS (the twin names its live document AND the live document
# names its twin — the TSV declaration is one-way). SINCE 14z-124 (G7, the pass's close at
# zero PENDING) the gate runs the tool's --no-pending END-STATE mode: a
# PENDING row FAILS (control h). During the pass (14z-122/123) PENDING was
# skipped here — a red gate for the whole pass would have been a decayed gate.
#
# WHY. The pass moves appended chronology out of reference documents; this is
# the enforcement that stops it growing back (the SMS lesson: staleness is
# defeated by enforcement, not format).
#
# MUST-FIRE CONTROLS on a perturbed copy (RH-9), each must FAIL for its
# stated reason: a-i, a chronology header prepended to a REFERENCE doc; an
# anchor in a HIST-class doc; an undeclared file; a dead allow row; a required
# banner absent; a dangling link; a citation of a nonexistent section; a
# PENDING row; a bold chronology paragraph. j-o, the routing checks: a listed
# document dropped from Contents; a Contents shape tag flipped; a twin that
# stops naming its live document; a live document that stops naming its twin
# (the other direction — a one-way check passes that one); a directory entry
# that stops naming a member; an entry-point row named nowhere in the README.
# n and o exist because those two MECHANISMS are the ways a document could
# otherwise be waved through in silence. The must-NOT-fire side of the bold rule is the tree
# itself — 619 bold paragraph openers in the REFERENCE/REGISTER docs, 70 of
# them carrying a session token, and the rule was calibrated to fire on the
# eight and none of the other 611 (14z-126b).
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
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

FILES="$(python3 tools/checkdocshape.py --list-files)"
mkcopy() {  # mkcopy <dir>
    for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done
    mkdir -p "$1/tools" "$1/tests"
}
applied() { grep -q "$1" "$2" || bad "$3: the perturbation did not apply"; }
absent()  { grep -q "$1" "$2" && bad "$3: the perturbation did not apply"; }
# THE PERTURBATIONS, one per declared control; the control section and the
# CONTROL=<name> mode call the same function. EXPECT = the failure's substring.
# ROUTING (14z-140, living-docs slice L1): dropped-from-contents .. entry-point-off-map
# — every declared document is listed in README's `## Contents` with its shape,
# and a history twin names its live document AND is named by it; the last two
# exist because two MECHANISMS could otherwise wave a document through silently.
perturb() {  # perturb <name> <dir>
    case "$1" in
    chronology-header) printf '\n### 14z-999: an appended discovery note\n' >> "$2/docs/game/atlas/id_space.md"; EXPECT="SESSION-SHAPED HEADER" ;;
    anchor-in-hist)    printf '\nold analysis **[VSE-1]** moved here\n' >> "$2/docs/project/mister_scope.md"; EXPECT="ANCHOR IN HISTORY-class doc" ;;
    undeclared-doc)    printf '# stray\n' > "$2/docs/stray_note.md"; EXPECT="UNDECLARED docs/stray_note.md" ;;
    dead-allow-row)    printf 'docs/game/atlas/id_space.md\tnever-ever-matches\tstale reason\n' >> "$2/docs/doc_shape_allow.tsv"; EXPECT="dead allow row" ;;
    banner-absent)     # perturb the TSV, not the doc
        sed -i.bak 's|^docs/game/atlas/id_space.md\tREFERENCE\t-\t-$|docs/game/atlas/id_space.md\tREFERENCE\t-\tbanner|' "$2/docs/doc_shape.tsv"
        applied 'id_space.md	REFERENCE	-	banner' "$2/docs/doc_shape.tsv" "$1"; EXPECT="NO STATUS BANNER" ;;
    dangling-link)     printf '\nsee also [a ghost](game/atlas/ghost_file.md)\n' >> "$2/docs/README.md"; EXPECT="DANGLING LINK" ;;
    nonexistent-section) printf '# per docs/game/atlas/id_space.md %sA Section Nobody Wrote%s\n' '"' '"' > "$2/tools/synthetic_control.py"; EXPECT="SECTION THAT DOES NOT EXIST" ;;
    pending-row)       # fails the end-state mode the gate runs (since 14z-124)
        sed -i.bak 's|^docs/game/atlas/id_space.md\tREFERENCE\t-\t-$|docs/game/atlas/id_space.md\tPENDING\t-\t-|' "$2/docs/doc_shape.tsv"
        applied 'id_space.md	PENDING' "$2/docs/doc_shape.tsv" "$1"; EXPECT="still PENDING" ;;
    bold-chronology)   # 14z-126b: barred from headers, the log came back as bold paragraphs —
                       # HANDOFF carried eight `**Previous batch (14z-N…)**` blocks, unseen through eight freezes
        printf '\n**Previous batch (14z-999, ruled): don-m9 / merged-m4.**\n' >> "$2/docs/game/atlas/id_space.md"; EXPECT="BOLD CHRONOLOGY PARAGRAPH" ;;
    dropped-from-contents) sed -i.bak '/defense_rows.md/d' "$2/docs/README.md"
        absent 'defense_rows.md' "$2/docs/README.md" "$1"; EXPECT="README CONTENTS MISSING: docs/project/tables/defense_rows.md" ;;
    shape-tag-flipped) sed -i.bak 's|(project/coverage_matrix.md) — \*\*REFERENCE\*\*|(project/coverage_matrix.md) — **INDEX**|' "$2/docs/README.md"
        applied '(project/coverage_matrix.md) — \*\*INDEX\*\*' "$2/docs/README.md" "$1"; EXPECT="README CONTENTS SHAPE MISMATCH: docs/project/coverage_matrix.md" ;;
    twin-no-backlink)  sed -i.bak 's|cps2_wide\.md|REDACTED_LIVE|g' "$2/docs/project/cps2_wide_history.md"
        absent 'cps2_wide\.md' "$2/docs/project/cps2_wide_history.md" "$1"; EXPECT="TWIN BACK-LINK MISSING: docs/project/cps2_wide_history.md does not name cps2_wide.md" ;;
    live-no-twin-link) sed -i.bak 's|cps2_wide_history\.md|REDACTED_TWIN|g' "$2/docs/project/cps2_wide.md"
        absent 'cps2_wide_history\.md' "$2/docs/project/cps2_wide.md" "$1"; EXPECT="TWIN BACK-LINK MISSING: docs/project/cps2_wide.md does not name cps2_wide_history.md" ;;
    directory-entry-member) sed -i.bak '/](game\/atlas\/)/ s|`ram\.md`, ||' "$2/docs/README.md"
        absent '](game/atlas/).*`ram\.md`' "$2/docs/README.md" "$1"; EXPECT="README CONTENTS MISSING: docs/game/atlas/ram.md" ;;
    entry-point-off-map) sed -i.bak 's|annotations\.md|REDACTED_EP|g' "$2/docs/README.md"
        absent 'annotations\.md' "$2/docs/README.md" "$1"; EXPECT="README ENTRY POINT NOT ON THE MAP: docs/annotations.md" ;;
    *) echo "no such perturbation: $1"; exit 3 ;;
    esac
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS the tree
# the main check reads, and this run must FAIL.
ROOT="$REPO"; SELFTEST=""
if [ -n "$VS_CTL" ]; then mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"; ROOT="$W/mode"; SELFTEST="--no-selftest"; fi

echo "== test_docshape: doc shapes declared and enforced =="
if python3 tools/checkdocshape.py --root "$ROOT" --no-pending $SELFTEST >"$W/tree.log" 2>&1; then
    ok "checkdocshape.py PASS on the tree ($(grep -o '[0-9]* still PENDING' "$W/tree.log" | head -1))"
else
    bad "checkdocshape.py FAILS on the tree:"; sed 's/^/        /' "$W/tree.log" | head -30
fi

# --- must-fire controls on a perturbed copy -------------------------------
control() {  # control <name>
    d="$W/$1"; mkcopy "$d"; perturb "$1" "$d"
    # pending-row is only a failure under the end-state mode this gate runs
    flag=""; [ "$1" = pending-row ] && flag="--no-pending"
    if python3 tools/checkdocshape.py --root "$d" $flag --no-selftest >"$d/log" 2>&1; then
        vs_ctl_dead "$1" "the perturbed copy PASSED — the check is not checking"; bad "$1"
    elif grep -q "$EXPECT" "$d/log"; then
        vs_ctl_fired "$1" "$EXPECT"; ok "$1: fires"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$d/log" | head -12
    fi
}
for n in $(vs_ctl_declared "$0"); do control "$n"; done

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
