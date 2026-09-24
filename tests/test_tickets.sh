#!/bin/sh
# test_tickets.sh — THE TICKET INDEX: every GitHub issue has exactly one row,
# open/closed agrees with GitHub's, and every row answers the four local
# questions with links that resolve (14z-154; maintainer-ruled 2026-09-14,
# CLAUDE.md [VSP-182]). ci_portable: no ROM, no network, no emulator, ~1 s.
#
# WHAT: the ticket index: every saved GitHub issue has exactly one row in
#   docs/project/tickets.tsv and no row lacks an issue, each status agrees with GitHub's
#   saved open/closed state, every one of the four answers is a resolving link or an
#   explicit none, no `learned`/`wrong` answer points at STATE or an archive, every session
#   key resolves, `?` appears only in the shrink-only backfill debt, and the generated
#   tickets.md is current.
# HOW: tools/tickets.py check and page --check over the TSV, the saved GitHub list and the
#   debt file (~1 s, offline); six controls (a missing row, a disagreeing state, an
#   unresolved link, a learned answer in an archive, debt growth, a stale page).
# EXPECTS: every property holds and every control fails. It does not judge whether an answer
#   is ENOUGH (the close does), nor that the saved GitHub list is fresh (refreshed at every
#   close).
#
# MUST-FIRE: perturbed-copy: row-missing — a ticket row deleted from a copy of the index must fail (a saved issue with no row)
# MUST-FIRE: perturbed-copy: state-disagrees — a row whose status says the opposite of the saved GitHub state must fail
# MUST-FIRE: perturbed-copy: link-unresolved — an answer linking text no line of its file contains must fail
# MUST-FIRE: perturbed-copy: learned-in-archive — a `learned` answer pointing at STATE_HISTORY.md must fail (learnings live in live documents)
# MUST-FIRE: perturbed-copy: debt-grows — a row carrying `?` whose issue is not in the backfill debt must fail
# MUST-FIRE: perturbed-copy: page-stale — a hand edit to the generated page must fail the currency check
#
# WHAT IT HOLDS. `tools/tickets.py check` reads docs/project/tickets.tsv (the
# LIST's source of truth — its header is the spec of record),
# docs/project/tickets_github.tsv (GitHub's issue list as saved at a close by
# `tools/tickets.py refresh`) and tests/expected/tickets_debt.txt (the rows not
# yet backfilled, shrink-only), and fails on: a saved issue with no row or a row
# with no issue, a status disagreeing with GitHub's open/closed, an answer link
# that does not resolve, a `learned`/`wrong` link to STATE.md or an archive, a
# session key resolving to no record, a `?` outside the debt, or a fully
# answered row still listed as debt. `tools/tickets.py page --check` keeps the
# generated docs/project/tickets.md current.
#
# WHY. The maintainer ruled strict sources of truth for tickets: the list here,
# the story on GitHub, the facts in the subject documents — and "enough to
# understand and work from" must be in the docs, so losing GitHub loses no
# decision, learning or error. A fourth place an item lives goes stale without a
# gate; this is that gate.
#
# WHAT IT DOES NOT CLAIM: that an answer is ENOUGH (judged at the close that
# closes the ticket), or that the saved GitHub list is current (refreshed at
# every close; the gate is offline by design).
#
# Usage: tests/test_tickets.sh      # ci_portable
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

FILES="docs/project/tickets.tsv docs/project/tickets_github.tsv docs/project/tickets.md tests/expected/tickets_debt.txt"
mkcopy() {  # mkcopy <dir>
    for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done
}
# THE PERTURBATIONS, one per declared control; the control section and the
# CONTROL=<name> mode call the same function. EXPECT = the failure's substring.
# Each edits the FIRST ticket row of the copy; links still resolve in this tree.
perturb() {  # perturb <name> <dir>
    python3 - "$1" "$2" <<'PY' || { echo "no such perturbation: $1"; exit 3; }
import sys
from pathlib import Path
name, root = sys.argv[1], Path(sys.argv[2])
idx, snap = root / "docs/project/tickets.tsv", root / "docs/project/tickets_github.tsv"
debt, page = root / "tests/expected/tickets_debt.txt", root / "docs/project/tickets.md"
cols = ["issue", "kind", "status", "title", "repro", "decided", "learned", "wrong", "sessions"]
lines = idx.read_text().splitlines()
data = [i for i, l in enumerate(lines) if l and not l.startswith("#") and not l.startswith("issue\t")]
first = data[0]
row = dict(zip(cols, lines[first].split("\t")))
state = {l.split("\t")[0]: l.split("\t")[1] for l in snap.read_text().splitlines()
         if l and not l.startswith("#") and not l.startswith("number\t")}
if name == "row-missing":
    del lines[first]
elif name == "state-disagrees":
    row["status"] = "done" if state.get(row["issue"]) == "OPEN" else "open"
elif name == "link-unresolved":
    row["repro"] = "STATE.md § a heading no document carries, planted by the control"
elif name == "learned-in-archive":
    row["learned"] = "STATE_HISTORY.md"
elif name == "debt-grows":
    listed = {l.strip() for l in debt.read_text().splitlines() if l.strip() and not l.startswith("#")}
    if row["issue"] in listed:
        debt.write_text("".join(l + "\n" for l in debt.read_text().splitlines() if l.strip() != row["issue"]))
        row["kind"] = "?"
    else:
        row["kind"] = "?"
elif name == "page-stale":
    page.write_text(page.read_text() + "\nA line added by hand to a generated page.\n")
else:
    sys.exit(1)
if name not in ("row-missing", "page-stale"):
    lines[first] = "\t".join(row[c] for c in cols)
idx.write_text("\n".join(lines) + "\n")
PY
    case "$1" in
    row-missing)        EXPECT="has no row in" ;;
    state-disagrees)    EXPECT="on GitHub" ;;
    link-unresolved)    EXPECT="which no line of" ;;
    learned-in-archive) EXPECT="is not a live document" ;;
    debt-grows)         EXPECT="is not in the backfill debt" ;;
    page-stale)         EXPECT="differs from a regeneration" ;;
    esac
}
run_tool() {  # run_tool <dir> <check|page> — the tool on the data files of <dir>, links in this tree
    if [ "$2" = page ]; then
        python3 tools/tickets.py page --check --index "$1/docs/project/tickets.tsv" \
            --snapshot "$1/docs/project/tickets_github.tsv" --debt "$1/tests/expected/tickets_debt.txt" \
            --page "$1/docs/project/tickets.md"
    else
        python3 tools/tickets.py check --index "$1/docs/project/tickets.tsv" \
            --snapshot "$1/docs/project/tickets_github.tsv" --debt "$1/tests/expected/tickets_debt.txt"
    fi
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS what the main
# checks read, and this run must FAIL.
DATA="$REPO"
if [ -n "$VS_CTL" ]; then mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"; DATA="$W/mode"; fi

echo "== test_tickets: the ticket index =="
if run_tool "$DATA" check >"$W/check.log" 2>&1; then
    ok "$(grep '^PASS' "$W/check.log")"
else
    bad "tickets.py check FAILS:"; sed 's/^/        /' "$W/check.log" | head -40
fi
if run_tool "$DATA" page >"$W/page.log" 2>&1; then
    ok "$(grep '^PASS' "$W/page.log")"
else
    bad "the generated page is not current:"; sed 's/^/        /' "$W/page.log" | head -20
fi

# --- must-fire controls on a perturbed copy -------------------------------
control() {  # control <name>
    d="$W/$1"; mkcopy "$d"; perturb "$1" "$d"
    what=check; [ "$1" = page-stale ] && what=page
    if run_tool "$d" "$what" >"$d/log" 2>&1; then
        vs_ctl_dead "$1" "the perturbed copy PASSED — the check is not checking"; bad "$1"
    elif grep -qF "$EXPECT" "$d/log"; then
        vs_ctl_fired "$1" "$EXPECT"; ok "$1: fires"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$d/log" | head -20
    fi
}
for n in $(vs_ctl_declared "$0"); do control "$n"; done

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
