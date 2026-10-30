#!/bin/sh
# test_green_guard.sh — ground truth for the green guard (GitHub #290, ruled 2026-10-16, 14z-203): no commit, and
# no push of a tip, whose tree has no strict GREEN run of the whole static tier with ROMDIR set. ci_portable: a scratch
# git repository, no ROM, no emulator, a few seconds.
#
# WHAT: tools/git-hooks/pre-commit refuses a commit whose tree (the index) has no counting row in
#   the index (<git dir>/green_index.tsv); tools/git-hooks/pre-push refuses a push whose TIP's tree has none and lets an uncovered
#   commit below a covered tip through (ruled: "the pushed tip only"); tests/run_all_static.sh writes the row a run
#   earns, keyed by the tree it tested, and only that.
# HOW: a scratch repository with the REAL hooks (core.hooksPath at its tools/git-hooks) and a bare remote. Sections 1-3
#   write index rows by hand and commit or push: one row per refusal case (none, NOT GREEN, not strict, tier portable,
#   tier static, ROMDIR unset, cadence ondemand, another tree) and the counting rows (session; --exec-controls none;
#   freeze). Section 4 drives `record` on results files (tree moved, fields missing). Section 5 runs the REAL runner
#   in the scratch repository (one stub gate) and commits on the row it wrote; a --tier portable run's row is refused.
#   Section 7 pushes the LEDGER PAGE (#267, ruled 2026-10-30: the guard lets tools/publish_ledger.sh's page through,
#   "nothing bypasses #290") with no row at all: the page's parentless commit to gh-pages is pushed; the page with a
#   file more, a file less or an executable mode, the page with a parent, and the page to another branch are refused.
# EXPECTS: every refusal case refused (exit non-zero, the commit absent); every counting row lets the commit land; the
#   uncovered tip refused and the covered tip pushed; the runner's row carries the tested tree; the ledger page alone
#   pushed, each near-page refused.
#
# MUST-FIRE: shadow-tool: guard-ignores-tree — a copy of green_guard.py whose GUARD-TREE line keeps every row whatever its tree must let section 1's other-tree commit through, and the gate must FAIL (mode: that copy is the guard every section runs; section 6 fires it in-run)
# MUST-FIRE: shadow-tool: guard-ignores-strict — a copy of green_guard.py whose GUARD-SCOPE line drops the strict check must let section 1's non-strict commit through, and the gate must FAIL (mode: that copy is the guard every section runs; section 6 fires it in-run)
# MUST-FIRE: shadow-tool: guard-page-any-ref — a copy of green_guard.py whose GUARD-PAGE-REF line passes the ledger page on every ref must let section 7's page pushed to another branch through, and the gate must FAIL (mode: that copy is the guard every section runs; section 6 fires it in-run)
# MUST-FIRE: shadow-tool: guard-page-any-shape — a copy of green_guard.py whose GUARD-PAGE-SHAPE line accepts any tree must let section 7's page with an extra file through, and the gate must FAIL (mode: that copy is the guard every section runs; section 6 fires it in-run)
# MUST-FIRE: shadow-tool: guard-page-any-parent — a copy of green_guard.py whose GUARD-PAGE-ORPHAN line accepts a commit with a parent must let section 7's page with a parent through, and the gate must FAIL (mode: that copy is the guard every section runs; section 6 fires it in-run)
#
# WHY: #288 found the class three times among the procedure check's real catches (rule-checker runs 2026-10-13-1016,
# 2026-10-13-1028, 2026-10-15-1091): a red tier read as green, a close tier called green, a commit made without its
# tier. The two ways the guard could go blind are the two controls: the tree not compared (shape (iii)) and the
# strict flag not read (shape (i), a run with a SKIP printing GREEN without --strict).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
GUARD="$REPO/tools/git-hooks/green_guard.py"
W="$(mktemp -d "${TMPDIR:-/tmp}/gguard.XXXXXX")" || { echo "FAIL: test_green_guard — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
G="git -c user.name=t -c user.email=t@t -c commit.gpgsign=false"

# THE SHADOW GUARDS, each built from the real guard by one substitution; a substitution that no longer applies is a
# red (the guard moved under the control).
mkdir -p "$W/shadow"
sed 's|    mine = \[r for r in all_rows if r\["tree"\] == tree\]   # GUARD-TREE|    mine = list(all_rows)   # GUARD-TREE disabled|' "$GUARD" > "$W/shadow/tree.py"
cmp -s "$GUARD" "$W/shadow/tree.py" && bad "could not blind the tree comparison — the GUARD-TREE line moved"
sed 's|(("verdict", "GREEN"), ("strict", "1"), ("tier", "all"), ("romdir", "set"))   # GUARD-SCOPE|(("verdict", "GREEN"), ("tier", "all"), ("romdir", "set"))   # GUARD-SCOPE disabled|' "$GUARD" > "$W/shadow/strict.py"
cmp -s "$GUARD" "$W/shadow/strict.py" && bad "could not drop the strict check — the GUARD-SCOPE line moved"
sed 's|    if ref != LEDGER_REF:   # GUARD-PAGE-REF|    if False:   # GUARD-PAGE-REF disabled|' "$GUARD" > "$W/shadow/page-ref.py"
cmp -s "$GUARD" "$W/shadow/page-ref.py" && bad "could not blind the page's ref check — the GUARD-PAGE-REF line moved"
sed 's|            and tuple(sorted(e\[3\] for e in entries)) == LEDGER_FILES)   # GUARD-PAGE-SHAPE|            or True)   # GUARD-PAGE-SHAPE disabled|' "$GUARD" > "$W/shadow/page-shape.py"
cmp -s "$GUARD" "$W/shadow/page-shape.py" && bad "could not blind the page's shape check — the GUARD-PAGE-SHAPE line moved"
sed 's|    if git("rev-list", "--parents", "-n", "1", sha, cwd=root).split()\[1:\]:   # GUARD-PAGE-ORPHAN|    if False:   # GUARD-PAGE-ORPHAN disabled|' "$GUARD" > "$W/shadow/page-parent.py"
cmp -s "$GUARD" "$W/shadow/page-parent.py" && bad "could not blind the page's parent check — the GUARD-PAGE-ORPHAN line moved"
USE="$GUARD"
case "${VS_CTL:-}" in
guard-ignores-tree)   USE="$W/shadow/tree.py" ;;
guard-ignores-strict) USE="$W/shadow/strict.py" ;;
guard-page-any-ref)    USE="$W/shadow/page-ref.py" ;;
guard-page-any-shape)  USE="$W/shadow/page-shape.py" ;;
guard-page-any-parent) USE="$W/shadow/page-parent.py" ;;
esac

# THE SCRATCH REPOSITORY: the real hooks, the guard under test, a bare remote
mkrepo() {  # mkrepo <dir> <guard.py>
    mkdir -p "$1/tools/git-hooks" "$1/build"
    cp "$REPO/tools/git-hooks/pre-commit" "$REPO/tools/git-hooks/pre-push" "$1/tools/git-hooks/"
    cp "$2" "$1/tools/git-hooks/green_guard.py"
    chmod +x "$1/tools/git-hooks/pre-commit" "$1/tools/git-hooks/pre-push"
    printf 'build/\n' > "$1/.gitignore"
    echo base > "$1/f.txt"
    ( cd "$1" && git init -q -b main && $G add -A && $G commit -q --no-verify -m base \
      && git config core.hooksPath tools/git-hooks ) || { echo "FAIL: could not make the scratch repository"; exit 1; }
}
row() {  # row <repo> <tree> <verdict> <strict> <tier> <romdir> <cadence> <exec_controls>
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$5" "$6" "$7" "$8" "/r/results.tsv" "2026-10-16T00:00:00Z" \
        >> "$1/.git/green_index.tsv"
}
R="$W/repo"; mkrepo "$R" "$USE"

echo "== 1. pre-commit: each non-counting row is REFUSED"
refused() {  # refused <label> [row args...] — writes the row (if any) for the staged tree, expects a refusal
    _l="$1"; shift
    echo "$_l" >> "$R/f.txt"; $G -C "$R" add f.txt
    _t="$(git -C "$R" write-tree)"
    : > "$R/.git/green_index.tsv"
    [ $# -gt 0 ] && row "$R" "$@"
    [ "${1:-}" = OTHER ] && sed -i.bak "s/^OTHER/$(printf '%040d' 7)/" "$R/.git/green_index.tsv"
    [ "${1:-}" = TREE ] && sed -i.bak "s/^TREE/$_t/" "$R/.git/green_index.tsv"
    _h0="$(git -C "$R" rev-parse HEAD)"
    $G -C "$R" commit -q -m "$_l" > "$W/commit.out" 2>&1
    if [ "$(git -C "$R" rev-parse HEAD)" = "$_h0" ] && grep -q 'green guard: REFUSED' "$W/commit.out"; then ok "$_l: refused"
    else bad "$_l: the commit LANDED"; $G -C "$R" reset -q --soft "$_h0"; fi
}
refused "no row"
refused "NOT GREEN"        TREE "NOT GREEN" 1 all set session all
refused "not strict"       TREE GREEN 0 all set session all
refused "tier portable"    TREE GREEN 1 portable set session all
refused "tier static"      TREE GREEN 1 static set session all
refused "ROMDIR unset"     TREE GREEN 1 all unset session all
refused "cadence ondemand" TREE GREEN 1 all set ondemand all
refused "another tree"     OTHER GREEN 1 all set session all
$G -C "$R" reset -q --hard HEAD

echo "== 2. pre-commit: a counting row at the staged tree lets the commit land"
for form in "session all" "session none" "freeze all"; do
    set -- $form
    echo "$form" >> "$R/f.txt"; $G -C "$R" add f.txt
    : > "$R/.git/green_index.tsv"; row "$R" "$(git -C "$R" write-tree)" GREEN 1 all set "$1" "$2"
    _h0="$(git -C "$R" rev-parse HEAD)"
    $G -C "$R" commit -q -m "$form" > "$W/commit.out" 2>&1
    [ "$(git -C "$R" rev-parse HEAD)" != "$_h0" ] && ok "cadence $1, --exec-controls $2: committed" \
        || { bad "cadence $1, --exec-controls $2: refused"; sed 's/^/        /' "$W/commit.out" | tail -3; }
done
# the edit made AFTER the run: the working tree's tree is not the row's, and the index moves with the add
echo "after the run" >> "$R/f.txt"; $G -C "$R" add f.txt
_h0="$(git -C "$R" rev-parse HEAD)"; $G -C "$R" commit -q -m late > "$W/commit.out" 2>&1
[ "$(git -C "$R" rev-parse HEAD)" = "$_h0" ] && ok "an edit staged after the green run: refused" || bad "an edit staged after the green run was committed"
$G -C "$R" reset -q --hard HEAD

echo "== 3. pre-push: the TIP's tree is what is checked"
git init -q --bare "$W/remote.git"; git -C "$R" remote add origin "$W/remote.git"
: > "$R/.git/green_index.tsv"
echo "unrun" >> "$R/f.txt"; $G -C "$R" commit -qa --no-verify -m "made without the hook"
if git -C "$R" push -q origin main > "$W/push.out" 2>&1; then bad "a tip whose tree has no run was pushed"
else grep -q 'green guard: REFUSED' "$W/push.out" && ok "a tip whose tree has no run: refused" || { bad "the push failed for another reason"; tail -3 "$W/push.out"; }; fi
echo "covered" >> "$R/f.txt"; $G -C "$R" add f.txt
row "$R" "$(git -C "$R" write-tree)" GREEN 1 all set session none
$G -C "$R" commit -q -m "covered tip" > "$W/commit.out" 2>&1 || bad "the covered commit was refused"
git -C "$R" push -q origin main > "$W/push.out" 2>&1 && ok "an uncovered commit below a covered tip: pushed (the tip only, as ruled)" \
    || { bad "the covered tip was refused"; tail -3 "$W/push.out"; }

echo "== 4. record: a row only for a run whose tree did not move, and only from a complete header"
res() {  # res <file> <tree> <tree_end> [drop]
    { echo "# head x"; echo "# tree $2"; printf '# gate\tverdict\n'; echo "g	PASS"; echo "# tree_end $3"; echo "# verdict GREEN"
      echo "# strict 1"; echo "# tier all"; echo "# romdir set"; echo "# cadence session"
      [ "${4:-}" = drop ] || echo "# exec_controls none"; } > "$1"
}
I="$W/idx.tsv"
res "$W/r1.tsv" aaa aaa; python3 "$USE" record "$W/r1.tsv" "$I" 2>/dev/null
[ "$(grep -vc '^#' "$I" 2>/dev/null)" = 1 ] && grep -q "^aaa	GREEN	1	all	set	session	none	/.*/r1.tsv	" "$I" \
    && ok "a complete header: one row, its fields in order" || bad "a complete header wrote: $(cat "$I" 2>/dev/null | tr '\n' '|')"
res "$W/r2.tsv" aaa bbb; python3 "$USE" record "$W/r2.tsv" "$I" 2>/dev/null
[ "$(grep -vc '^#' "$I")" = 1 ] && ok "the tree moved during the run: no row" || bad "a run whose tree moved wrote a row"
res "$W/r3.tsv" ccc ccc drop
if python3 "$USE" record "$W/r3.tsv" "$I" 2>/dev/null; then bad "a header missing exec_controls was accepted"
else [ "$(grep -vc '^#' "$I")" = 1 ] && ok "a header missing a field: refused, no row" || bad "a header missing a field wrote a row"; fi

echo "== 5. the REAL runner writes the row a run earns, keyed by the tree it tested"
F="$W/fake"; mkrepo "$F" "$USE"
mkdir -p "$F/tests/lib" "$W/romdir"
cp "$REPO/tests/run_all_static.sh" "$F/tests/"
for l in classify.sh controls.sh measures.sh; do cp "$REPO/tests/lib/$l" "$F/tests/lib/"; done
printf '#!/bin/sh\n# g_ok.sh — a stub gate\n#\n# MUST-FIRE: none — a stub\necho "PASS: fine"\n' > "$F/tests/g_ok.sh"; chmod +x "$F/tests/g_ok.sh"
echo g_ok > "$F/tests/ci_portable.txt"; : > "$F/tests/ci_static.txt"
$G -C "$F" add -A; $G -C "$F" commit -q --no-verify -m fixture
echo "staged change" >> "$F/f.txt"; $G -C "$F" add f.txt
T_IDX="$(git -C "$F" write-tree)"
( cd "$F" && ROMDIR="$W/romdir" STATIC_RESULTS_OUT="$W/fr1.tsv" sh tests/run_all_static.sh --strict --exec-controls none ) > "$W/run1.out" 2>&1
grep -q '^GREEN' "$W/run1.out" || { bad "the stub tier did not read GREEN"; tail -5 "$W/run1.out" | sed 's/^/        /'; }
grep -q "^# tree $T_IDX\$" "$W/fr1.tsv" && grep -q "^# tree_end $T_IDX\$" "$W/fr1.tsv" \
    && ok "the results file names the tested tree, start and end ($(printf %.12s "$T_IDX"))" || bad "the results file's tree is not the staged tree: $(grep '^# tree' "$W/fr1.tsv" | tr '\n' '|')"
grep -q "^$T_IDX	GREEN	1	all	set	session	none	" "$F/.git/green_index.tsv" && ok "the index row: GREEN, strict, tier all, ROMDIR set" \
    || bad "the index row: $(cat "$F/.git/green_index.tsv" 2>/dev/null | tr '\n' '|')"
_h0="$(git -C "$F" rev-parse HEAD)"; $G -C "$F" commit -q -m "on the runner's row" > "$W/commit.out" 2>&1
[ "$(git -C "$F" rev-parse HEAD)" != "$_h0" ] && ok "the commit lands on the row the runner wrote" || { bad "refused on the runner's own row"; tail -3 "$W/commit.out"; }
echo "portable only" >> "$F/f.txt"; $G -C "$F" add f.txt
( cd "$F" && ROMDIR="$W/romdir" STATIC_RESULTS_OUT="$W/fr2.tsv" sh tests/run_all_static.sh --strict --tier portable ) > "$W/run2.out" 2>&1
grep -q '^GREEN' "$W/run2.out" || bad "the --tier portable stub run did not read GREEN"
_h0="$(git -C "$F" rev-parse HEAD)"; $G -C "$F" commit -q -m "on a portable row" > "$W/commit.out" 2>&1
[ "$(git -C "$F" rev-parse HEAD)" = "$_h0" ] && ok "a strict GREEN --tier portable run: refused (it ran no static gate)" || bad "a --tier portable run let the commit land"

echo "== 7. pre-push: the ledger page (#267) — only tools/publish_ledger.sh's page, only to gh-pages, needs no row"
PAGE=".nojekyll index.html ledger.css ledger.js"
pg_commit() {  # pg_commit <repo> <parent|-> <mode> <file>... — a commit whose tree holds the named files
    _r="$1"; _p="$2"; _m="$3"; shift 3
    _t="$(for _f; do printf '%s blob %s\t%s\n' "$_m" "$(printf '%s\n' "$_f" | git -C "$_r" hash-object -w --stdin)" "$_f"; done | git -C "$_r" mktree)"
    if [ "$_p" = - ]; then echo page | $G -C "$_r" commit-tree "$_t"; else echo page | $G -C "$_r" commit-tree "$_t" -p "$_p"; fi
}
page_push() {  # page_push <repo> <label> pushed|refused <ref> <commit> — the push judged with NO row in the index
    : > "$1/.git/green_index.tsv"
    if git -C "$1" push -q -f origin "$5:$4" > "$W/push.out" 2>&1; then _got=pushed; else _got=refused; fi
    if [ "$_got" = refused ] && ! grep -q 'green guard: REFUSED' "$W/push.out"; then
        bad "$2: the push failed for another reason"; tail -3 "$W/push.out" | sed 's/^/        /'; return 1; fi
    if [ "$_got" = "$3" ]; then ok "$2: $3"; return 0; fi
    bad "$2: $_got, expected $3"; return 1
}
P1="$(pg_commit "$R" - 100644 $PAGE)"
page_push "$R" "the page, one parentless commit, to gh-pages" pushed refs/heads/gh-pages "$P1"
page_push "$R" "the page with a file more"              refused refs/heads/gh-pages "$(pg_commit "$R" - 100644 $PAGE extra.txt)"
page_push "$R" "the page with a file less"              refused refs/heads/gh-pages "$(pg_commit "$R" - 100644 .nojekyll index.html ledger.css)"
page_push "$R" "the page's files executable"            refused refs/heads/gh-pages "$(pg_commit "$R" - 100755 $PAGE)"
page_push "$R" "the page with a parent"                 refused refs/heads/gh-pages "$(pg_commit "$R" "$P1" 100644 $PAGE)"
page_push "$R" "a repository commit to gh-pages"        refused refs/heads/gh-pages "$(git -C "$R" rev-parse HEAD)"
page_push "$R" "the page to another branch"             refused refs/heads/elsewhere "$P1"

if [ -z "${VS_CTL:-}" ]; then
    echo "== 6. controls: each shadow guard must let its section's refused commit through"
    S="$W/srepo"
    for c in tree strict; do
        rm -rf "$S"; mkrepo "$S" "$W/shadow/$c.py"
        echo "$c" >> "$S/f.txt"; $G -C "$S" add f.txt
        : > "$S/.git/green_index.tsv"
        if [ "$c" = tree ]; then row "$S" "$(printf '%040d' 7)" GREEN 1 all set session all
        else row "$S" "$(git -C "$S" write-tree)" GREEN 0 all set session all; fi
        _h0="$(git -C "$S" rev-parse HEAD)"; $G -C "$S" commit -q -m "$c" > "$W/commit.out" 2>&1
        if [ "$(git -C "$S" rev-parse HEAD)" != "$_h0" ]; then
            vs_ctl_fired "guard-ignores-$c" "the shadow guard let the commit land — section 1 would have failed on it"
        else vs_ctl_dead "guard-ignores-$c" "the shadow guard still refused"; fail=1; fi
    done
    for c in ref shape parent; do
        rm -rf "$S" "$W/sremote.git"; mkrepo "$S" "$W/shadow/page-$c.py"
        git init -q --bare "$W/sremote.git"; git -C "$S" remote add origin "$W/sremote.git"
        : > "$S/.git/green_index.tsv"
        case "$c" in
        ref)    _c="$(pg_commit "$S" - 100644 $PAGE)"; _ref=refs/heads/elsewhere ;;
        shape)  _c="$(pg_commit "$S" - 100644 $PAGE extra.txt)"; _ref=refs/heads/gh-pages ;;
        parent) _c="$(pg_commit "$S" "$(git -C "$S" rev-parse HEAD)" 100644 $PAGE)"; _ref=refs/heads/gh-pages ;;
        esac
        if git -C "$S" push -q -f origin "$_c:$_ref" > "$W/push.out" 2>&1; then
            vs_ctl_fired "guard-page-any-$c" "the shadow guard let the near-page through — section 7 would have failed on it"
        else vs_ctl_dead "guard-page-any-$c" "the shadow guard still refused"; fail=1; fi
    done
fi

[ "$fail" -eq 0 ] && echo "PASS: the green guard refuses every non-counting run and lets the counting ones through" || echo "FAIL: green guard"
exit "$fail"
