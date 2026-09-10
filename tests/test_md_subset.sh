#!/bin/sh
# test_md_subset.sh — the markdown SUBSET the corpus writes is parsed strictly,
# and every construct outside it FAILS (14z-140, living-docs slice L4).
# ci_portable: no ROM, no build dir, no emulator, ~3 s.
#
# MUST-FIRE: known-bad: h4-heading — an h4 heading must be rejected as outside the subset (mode: appended to a copy of one corpus file, which the corpus parse must then fail)
# MUST-FIRE: known-bad: raw-html-div — raw HTML <div> must be rejected as outside the subset (mode: appended to a copy of one corpus file, which the corpus parse must then fail)
# MUST-FIRE: known-bad: raw-html-b — raw HTML <b> must be rejected as outside the subset (mode: appended to a copy of one corpus file, which the corpus parse must then fail)
# MUST-FIRE: known-bad: footnote — a footnote must be rejected as outside the subset (mode: appended to a copy of one corpus file, which the corpus parse must then fail)
# MUST-FIRE: known-bad: image — an image must be rejected as outside the subset (mode: appended to a copy of one corpus file, which the corpus parse must then fail)
# MUST-FIRE: known-bad: autolink — an autolink must be rejected as outside the subset (mode: appended to a copy of one corpus file, which the corpus parse must then fail)
# MUST-FIRE: known-bad: task-list — a task list item must be rejected as outside the subset (mode: appended to a copy of one corpus file, which the corpus parse must then fail)
# MUST-FIRE: known-bad: reference-link-def — a reference-link def must be rejected as outside the subset (mode: appended to a copy of one corpus file, which the corpus parse must then fail)
# MUST-FIRE: known-bad: unclosed-fence — an unclosed fence must be rejected as outside the subset (mode: appended to a copy of one corpus file, which the corpus parse must then fail)
#
# WHAT IT HOLDS. `tools/md_subset.py` is a second implementation of markdown,
# which is only safe if its subset is a CENSUS of what this corpus actually
# writes rather than a guess. This gate asserts three things: the tool's own
# self-tests pass; EVERY document declared in docs/doc_shape.tsv plus the two
# skill GUIDEs — 74 files — parses inside the subset; and each construct
# deliberately left OUT of the subset raises, while each of the six shapes the
# corpus does write is accepted.
#
# WHY. The site (tools/mk_docs_site.py) renders from this parser, so a
# construct it mis-reads renders wrong somewhere a reader would not notice.
# Failing loudly at parse time is the whole design (living_docs_scope.md §9.5),
# and the census in §9.2 is what says which constructs those are.
#
# THE SIX RULES THE CORPUS FORCED, all measured 14z-140 and all with a
# NEGATIVE control below, because each is a way this gate could OVER-fire on
# the live corpus rather than under-fire:
#   1 a code span may WRAP a line break (34 `<name>` placeholders live in one);
#   2 `\|` is an escaped pipe in a cell (21 in 8 files);
#   3 a table row's leading pipe is OPTIONAL (22 rows in 4 files);
#   4 a pipe INSIDE a code span in a cell is content, not a separator;
#   5 a ragged row is NORMALISED and counted, never fatal (it would fail two
#     archives that are never rewritten, [VSP-17]);
#   6 a table needs its DELIMITER row, or a prose line containing a pipe opens
#     one — which is how a subcommand list inside a wrapped code span became a
#     7-cell table.
#
# MUST-FIRE CONTROLS (section 3), each must raise for its stated reason: an
# h4 heading; raw HTML (<div> and <b>); a footnote; an image; an autolink; a
# task list item; a reference-link definition; an unclosed fence. Section 4 is
# the must-NOT-fire side: the six rules above, plus a KNOWN tag inside a code
# span, plus `<details>`/`<summary>` — the one HTML pair the subset accepts
# (§9.8 decision 7).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
TOOL=tools/md_subset.py
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
construct() {  # construct <name> -> the known-bad construct, printf %b escapes
    case "$1" in
    h4-heading) printf '%s' '#### x\n' ;;
    raw-html-div) printf '%s' 'a <div>x</div> b\n' ;;
    raw-html-b) printf '%s' 'a <b>x</b> b\n' ;;
    footnote) printf '%s' 'a[^1] b\n' ;;
    image) printf '%s' '![alt](x.png)\n' ;;
    autolink) printf '%s' 'see <https://x.example> ok\n' ;;
    task-list) printf '%s' '- [ ] a\n' ;;
    reference-link-def) printf '%s' '[x]: http://e.example\n' ;;
    unclosed-fence) printf '%s' '```\nx\n' ;;
    esac
}
expect() {  # expect <name> -> the substring the rejection must carry
    case "$1" in
    h4-heading) echo 'h4 heading' ;;
    raw-html-div) echo 'raw HTML <div>' ;;
    raw-html-b) echo 'raw HTML <b>' ;;
    footnote) echo 'footnote' ;;
    image) echo 'image' ;;
    autolink) echo 'autolink' ;;
    task-list) echo 'task list' ;;
    reference-link-def) echo 'reference-link definition' ;;
    unclosed-fence) echo 'unclosed fenced code block' ;;
    esac
}

echo "== test_md_subset: the corpus parses inside the declared subset =="
[ -f "$TOOL" ] || { echo "FAIL: $TOOL is absent"; exit 1; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# --- 1. the tool's own self-tests -------------------------------------------
if python3 "$TOOL" > "$W/self.log" 2>&1; then
    ok "md_subset.py self-tests pass"
else
    bad "md_subset.py self-tests FAIL:"; sed 's/^/        /' "$W/self.log" | head -20
fi

# --- 2. every declared document parses --------------------------------------
python3 - > "$W/paths" <<'PY'
from pathlib import Path
rows = []
for line in Path("docs/doc_shape.tsv").read_text().splitlines():
    if line.strip() and not line.lstrip().startswith("#"):
        rows.append(line.split("\t")[0].strip())
rows += [str(p) for p in sorted(Path(".claude/skills").glob("*/GUIDE.md"))]
print("\n".join(r for r in rows if Path(r).is_file()))
PY
# THE EXECUTABLE FORM: under CONTROL=<name> the construct is appended to a
# COPY of the first corpus file and that copy replaces it in the corpus parse —
# which must FAIL.
if [ -n "$VS_CTL" ]; then
    first="$(head -1 "$W/paths")"; cp "$first" "$W/mode.md"
    printf '\n%b' "$(construct "$VS_CTL")" >> "$W/mode.md"
    { echo "$W/mode.md"; tail -n +2 "$W/paths"; } > "$W/paths.mode"; mv "$W/paths.mode" "$W/paths"
fi
N=$(wc -l < "$W/paths" | tr -d ' ')
# shellcheck disable=SC2046
if python3 "$TOOL" --no-selftest $(cat "$W/paths") > "$W/parse.log" 2>&1; then
    ok "all $N corpus files parse inside the subset"
else
    bad "a corpus file is OUTSIDE the subset:"; sed 's/^/        /' "$W/parse.log" | head -20
fi

# the census, printed for the record and asserted where a number is load-bearing
# shellcheck disable=SC2046
python3 "$TOOL" --no-selftest --census $(cat "$W/paths") > "$W/census.log" 2>&1
sed 's/^/    /' "$W/census.log"
n_of() { awk -v k="$1" '$1==k {print $2}' "$W/census.log"; }
[ "$(n_of table.no-separator)" = "" ] \
    && ok "no table without its delimiter row (rule 6 holds over the corpus)" \
    || bad "a table with no delimiter row survived: rule 6 is not doing its job"
PH="$(n_of placeholder)"
[ -n "$PH" ] && [ "$PH" -gt 0 ] \
    && ok "$PH \`<word>\` placeholders in prose, ACCEPTED (decision 8)" \
    || bad "no placeholders counted — decision 8's negative control is dead"
RG="$(n_of table.ragged)"
ok "ragged rows normalised and counted: ${RG:-0} (never fatal, rule 5)"

# --- 3. MUST-FIRE: every construct outside the subset ------------------------
must_fire() {  # must_fire <name>
    printf '%b' "$(construct "$1")" > "$W/case.md"
    exp="$(expect "$1")"
    if python3 "$TOOL" --no-selftest "$W/case.md" > "$W/case.log" 2>&1; then
        vs_ctl_dead "$1" "the tool ACCEPTED it — the check is not checking"; bad "$1"
    elif grep -q "$exp" "$W/case.log"; then
        vs_ctl_fired "$1" "$exp"; ok "$1: fires ($exp)"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$W/case.log" | head -4
    fi
}
for n in $(vs_ctl_declared "$0"); do must_fire "$n"; done

# --- 4. MUST-NOT-FIRE: the six shapes the corpus writes ----------------------
accepts() {  # accepts <label> <file body>
    printf '%b' "$2" > "$W/case.md"
    if python3 "$TOOL" --no-selftest "$W/case.md" > "$W/case.log" 2>&1; then
        ok "$1: accepted"
    else
        bad "$1: REJECTED — the gate over-fires on the live corpus:"
        sed 's/^/        /' "$W/case.log" | head -4
    fi
}
accepts "rule 1  a code span wrapping a line break" \
        'see `tools/x.py <name>\n<out>` and stop\n'
accepts "rule 2  an escaped pipe in a cell" \
        '| a | b |\n|---|---|\n| x \\| y | 2 |\n'
accepts "rule 3  a row with no leading pipe" \
        '| a | b |\n|---|---|\n**[X-1]** x | 2 |\n'
accepts "rule 4  a pipe inside a code span in a cell" \
        '| a | b |\n|---|---|\n| `p1|p2|sys` | 2 |\n'
accepts "rule 5  a ragged row" \
        '| a | b |\n|---|---|\n| 1 | 2 | 3 |\n'
accepts "rule 6  a table-shaped prose line inside an open span" \
        'run `bbh a | b |\nc | d | e |` and stop\n'
accepts "decision 8  a <word> placeholder in prose" \
        'the build dir is <name> and <dir outside the repo>\n'
accepts "decision 7  <details>/<summary>" \
        '<details><summary>x</summary>\n\n| a |\n|---|\n\n</details>\n'
accepts "a KNOWN tag INSIDE a code span" \
        'use `<div>` here\n'

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
