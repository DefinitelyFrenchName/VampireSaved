#!/bin/sh
# test_ctl_caught_lint.sh — A CONTROL MODE IS HONOURED ONLY ON POSITIVE EVIDENCE FROM ITS OWN CHECK: THE STATIC HALF
# (GitHub #369, 14z-224; maintainer-ruled 2026-11-08 "A1, B1, c1" on build/agent224/t369/design.md). ci_portable, ~10 s.
#
# WHAT: tests/lib/classify.sh honours a mode only on `CONTROL CAUGHT: <mode> — `, which tests/lib/controls.sh
#   vs_ctl_caught prints from the gate's main check output. tools/ctl_caught_lint.py holds what that run-time rule cannot
#   see: [a] the literal is printed only through the helper; [b] no catch-all ERE; [c] no vs_ctl_fired naming the mode
#   variable off the debt list; [d] every mode-declaring gate calls vs_ctl_caught or is on the shrink-only debt list
#   tests/expected/ctl_caught_debt.tsv; [e] in a gate with several modes the ERE is computed per mode; [debt] the list
#   only shrinks (each row one gate, once, existing, declaring a mode, not yet migrated, present at 8464fa3f, and on the
#   list's first version, blob ORIGIN_BLOB below, and on every committed version since). The ground-truth gates that
#   write synthetic logs may carry the literal, never in an echo/printf to their own stdout.
# HOW: the lint over the tree, the declared modes read by vs_ctl_declared (the one grammar reader), the base commit's
#   gates by `git ls-tree`, the allowed rows by `git cat-file` of ORIGIN_BLOB and `git show` of every commit that
#   touched the list (`git log`). Each control plants one gate (or one debt row) in a scratch copy of tests/ and the lint must
#   name it; a near miss (a migrated gate with two modes and a per-mode ERE) must pass. The tracked tree is never written.
# EXPECTS: PASS with NOTE lines ctl_caught.debt_gates and ctl_caught.migrated_gates (the migration's progress).
# NOT HELD (by review only, named in docs/project/must_fire_contract.md § #369): a vs_ctl_caught call handed a file other
#   than the main check's output; a per-mode ERE that still matches any failure of the check; and THE STATED LIMIT
#   (maintainer, 2026-11-09: "Land with a stated limit (Recommended)"): in the six ground-truth gates the lint covers
#   echo or printf written on one line, sent to stdout or stderr; any other printer (awk, cat of a file, tee), a line
#   assembled at run time (the literal split, or built in a variable, function, command substitution or format) are
#   review. Stated by the session, NOT ruled by the maintainer: the reader is textual, so a one-line echo/printf it
#   mis-splits, a redirect target held in a variable and a later redirect overriding an earlier one pass too; and in ANY
#   file a literal assembled at run time (split, formatted, built in a variable) passes rule [a], which reads the
#   literal written whole; code outside tests/ and tools/ is not read.
# FOLLOWS: tests/ tools/ctl_caught_lint.py tests/lib/controls.sh tests/expected/ctl_caught_debt.tsv tools/
#
# MUST-FIRE: perturbed-copy: echo-caught — a copy of tests/ with a gate that echoes `CONTROL CAUGHT:` by hand must be named under [a], or a gate could print its own evidence
# MUST-FIRE: perturbed-copy: deep-file — a copy with tools/zz_sub/plant.awk (a subdirectory, not shell or python) printing `CONTROL CAUGHT:` must be named under [a], or a printer outside tests/*.sh would go unread (rule-checker run 2026-11-09-1746)
# MUST-FIRE: perturbed-copy: catch-all — a copy with a migrated gate whose vs_ctl_caught ERE is '^ *FAIL' must be named under [b], or any failure would count as the finding
# MUST-FIRE: perturbed-copy: fired-mode-var — a copy with a migrated gate that also calls vs_ctl_fired "$VS_CTL" must be named under [c] (the 25-line shape #369 retires)
# MUST-FIRE: perturbed-copy: no-helper — a copy with a gate that declares a mode, never calls vs_ctl_caught and is not on the debt list must be named under [d]
# MUST-FIRE: perturbed-copy: fixed-literal — a copy with a migrated two-mode gate sharing one fixed ERE must be named under [e]
# MUST-FIRE: perturbed-copy: debt-joined — a copy of the debt list with a gate that did not exist at 8464fa3f added must be named under [debt], or the list could grow
# MUST-FIRE: perturbed-copy: debt-stale — a copy of the debt list with a migrated gate (test_control_classifier.sh) added back must be named under [debt], or a migrated gate could slip back to the old fall-through
# MUST-FIRE: perturbed-copy: debt-unmigrated — a copy where test_control_classifier.sh's vs_ctl_caught calls are deleted and its row added back must be named under [debt] (not on every earlier version), or a gate could be un-migrated and re-listed (rule-checker run 2026-11-09-1743)
# MUST-FIRE: perturbed-copy: debt-mode-gained — a copy where a gate present at 8464fa3f with no mode gains one and is listed must be named under [debt] (not on every earlier version), or the list could grow by gates that were never debt (rule-checker run 2026-11-09-1743)
# MUST-FIRE: perturbed-copy: debt-returned — a scratch history whose first commit holds the list's first version and whose second deletes one row, read with the tree's list (row present) must name that row under [debt], or a migrated-and-deleted row could come back (rule-checker run 2026-11-09-1743)
# MUST-FIRE: perturbed-copy: truth-echo — a copy of tests/test_control_classifier.sh (a ground-truth gate) that echoes `CONTROL CAUGHT:` to its own stdout must be named under [a], or a migrated ground-truth gate could print its own evidence (rule-checker run 2026-11-09-1743)
# MUST-FIRE: perturbed-copy: truth-arrow — the same with a `->` inside the echoed message must be named under [a], or a `>` in quoted text would read as a redirect (rule-checker run 2026-11-09-1744)
# MUST-FIRE: perturbed-copy: truth-stderr — the same echoed `>&2` must be named under [a], or stderr (captured with 2>&1) would carry forged evidence (rule-checker run 2026-11-09-1744)
# MUST-FIRE: perturbed-copy: truth-devstderr — the same echoed `>/dev/stderr` must be named under [a], or a device path would read as a file (rule-checker run 2026-11-09-1745)
# MUST-FIRE: perturbed-copy: truth-prefixed — the same as `VAR=x /bin/echo "CONTROL CAUGHT: ..."` must be named under [a], or an assignment prefix or a pathed echo would hide the printer (rule-checker run 2026-11-09-1745)
# MUST-FIRE: perturbed-copy: truth-heredoc — the same as a `cat <<EOF` heredoc whose body line is `CONTROL CAUGHT: ...` must be named under [a], or a multi-line string or heredoc (read one line at a time) would pass
# MUST-FIRE: perturbed-copy: truth-printf — the same as `printf '%s\n' "CONTROL CAUGHT: ..."` must be named under [a], or the literal in an argument rather than the format would pass (rule-checker run 2026-11-09-1744)
#
# Usage: tests/test_ctl_caught_lint.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_ctl_caught_lint — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
PLANT=test_zz_ctl_plant.sh
ORIGIN_BLOB=9cf7c951b9fe499b04e1537e428bef1c287b6e3c   # tests/expected/ctl_caught_debt.tsv as first landed (14z-224)
DEBT=tests/expected/ctl_caught_debt.tsv

git ls-tree --name-only 8464fa3f tests/ 2>/dev/null | sed -n 's|^tests/\(.*\.sh\)$|\1|p' > "$W/base.txt"
[ -s "$W/base.txt" ] || { echo "FAIL: test_ctl_caught_lint — cannot list the gates of the base commit 8464fa3f (git ls-tree)"; exit 2; }
for g in tests/*.sh; do vs_ctl_declared "$g" | sed "s|^|${g#tests/}	|"; done > "$W/decl.txt"
[ -s "$W/decl.txt" ] || { echo "FAIL: test_ctl_caught_lint — no declared mode read from tests/ (the grammar reader returned nothing)"; exit 2; }
# THE ALLOWED ROWS: the list's first version, intersected with every committed version since (a deleted row never returns)
rows() { grep -v '^#' | grep -v '^$' | LC_ALL=C sort -u; }
allowed_rows() {  # allowed_rows <repo> <out>: the first version's rows, intersected with every committed version's
    git -C "$1" cat-file -p "$ORIGIN_BLOB" 2>/dev/null | rows > "$2"
    [ -s "$2" ] || { echo "FAIL: test_ctl_caught_lint — cannot read the debt list's first version (blob $ORIGIN_BLOB) in $1"; exit 2; }
    nver=0
    for _c in $(git -C "$1" log --format=%H -- "$DEBT" 2>/dev/null); do
        git -C "$1" show "$_c:$DEBT" 2>/dev/null | rows > "$W/ver.txt"
        LC_ALL=C comm -12 "$2" "$W/ver.txt" > "$2.new"; mv "$2.new" "$2"; nver=$((nver + 1))
    done
}
allowed_rows "$REPO" "$W/allowed.txt"
echo "NOTE: ctl_caught.list_versions $nver (committed versions intersected with the first, $ORIGIN_BLOB)"

lint() {  # lint <root> <decl> <out>: the lint's exit status
    python3 -I "$REPO/tools/ctl_caught_lint.py" --root "$1" --decl "$2" --base "$W/base.txt" --allowed "${ALLOWED:-$W/allowed.txt}" > "$3" 2>&1
}
copy() {  # copy: a fresh scratch tree at $W/t (tests/*.sh, tests/lib, the debt list) and its declarations at $W/t.decl
    rm -rf "$W/t"; mkdir -p "$W/t/tests/lib" "$W/t/tests/expected"
    cp tests/*.sh "$W/t/tests/"; cp tests/lib/*.sh "$W/t/tests/lib/"; cp tests/expected/ctl_caught_debt.tsv "$W/t/tests/expected/"
    cp "$W/decl.txt" "$W/t.decl"
}
gate() {  # gate <n modes> <body line>...: writes the planted gate into the copy and adds its declarations
    _n="$1"; shift
    { echo '#!/bin/sh'; echo "# $PLANT — planted by test_ctl_caught_lint"; _i=1
      while [ "$_i" -le "$_n" ]; do echo "# MUST-FIRE: perturbed-copy: m$_i — planted mode $_i"; _i=$((_i + 1)); done
      echo '. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"'
      for _l in "$@"; do echo "$_l"; done; } > "$W/t/tests/$PLANT"
    _i=1; while [ "$_i" -le "$_n" ]; do printf '%s\tm%s\n' "$PLANT" "$_i" >> "$W/t.decl"; _i=$((_i + 1)); done
}
plant() {  # plant <control>: one copy perturbed the control's way; sets WANT, the finding the lint must print
    copy; ALLOWED=
    case "$1" in
    deep-file)      mkdir -p "$W/t/tools/zz_sub"; printf 'BEGIN { print "CONTROL CAUGHT: m1 — FAIL  [x] planted" }\n' > "$W/t/tools/zz_sub/plant.awk"
                    WANT="FAIL  \\[a\\] tools/zz_sub/plant.awk:" ;;
    echo-caught)    gate 0 'echo "CONTROL CAUGHT: m1 — FAIL  [x] planted by hand"'; WANT="FAIL  \\[a\\] tests/$PLANT:" ;;
    catch-all)      gate 1 'vs_ctl_caught "$W/out" '"'"'^ *FAIL'"'"; WANT="FAIL  \\[b\\] tests/$PLANT:" ;;
    fired-mode-var) gate 1 'vs_ctl_caught "$W/out" "FAIL  \[E1 m1"' 'vs_ctl_fired "$VS_CTL" "the copy failed"'; WANT="FAIL  \\[c\\] tests/$PLANT:" ;;
    no-helper)      gate 1 'echo "FAIL: planted"; exit 1'; WANT="FAIL  \\[d\\] tests/$PLANT:" ;;
    fixed-literal)  gate 2 'vs_ctl_caught "$W/out" "FAIL  \[E1 "'; WANT="FAIL  \\[e\\] tests/$PLANT:" ;;
    debt-joined)    gate 1 'echo "FAIL: planted"; exit 1'; echo "$PLANT" >> "$W/t/tests/expected/ctl_caught_debt.tsv"
                    WANT="FAIL  \\[debt\\] [^ ]*: $PLANT did not exist at 8464fa3f" ;;
    debt-stale)     echo test_control_classifier.sh >> "$W/t/tests/expected/ctl_caught_debt.tsv"
                    WANT="FAIL  \\[debt\\] [^ ]*: test_control_classifier.sh calls vs_ctl_caught" ;;
    debt-unmigrated) sed '/vs_ctl_caught/d' tests/test_control_classifier.sh > "$W/t/tests/test_control_classifier.sh"
                    echo test_control_classifier.sh >> "$W/t/tests/expected/ctl_caught_debt.tsv"
                    WANT="FAIL  \\[debt\\] [^ ]*: test_control_classifier.sh is not on every earlier version" ;;
    debt-mode-gained) _g="$(cut -f1 "$W/decl.txt" | LC_ALL=C sort -u | LC_ALL=C comm -23 "$W/base.txt" - | while read -r _b; do [ -f "tests/$_b" ] && { echo "$_b"; break; }; done)"
                    printf '%s\tm1\n' "$_g" >> "$W/t.decl"; echo "$_g" >> "$W/t/tests/expected/ctl_caught_debt.tsv"
                    WANT="FAIL  \\[debt\\] [^ ]*: ${_g:-<none found>} is not on every earlier version" ;;
    debt-returned)  _h="$W/hist"; rm -rf "$_h"; mkdir -p "$_h/tests/expected"; git init -q "$_h"
                    git cat-file -p "$ORIGIN_BLOB" > "$_h/$DEBT"; _r="$(rows < "$_h/$DEBT" | head -1)"
                    hg() { git -C "$_h" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
                    hg add "$DEBT"; hg commit -q -m first
                    grep -vx "$_r" "$_h/$DEBT" > "$_h/d.tmp"; mv "$_h/d.tmp" "$_h/$DEBT"; hg commit -q -am second
                    allowed_rows "$_h" "$W/allowed_h.txt"; ALLOWED="$W/allowed_h.txt"
                    WANT="FAIL  \\[debt\\] [^ ]*: ${_r:-<no row>} is not on every earlier version" ;;
    truth-echo)     printf 'echo "CONTROL CAUGHT: flip — FAIL  [E1] row 3"\n' >> "$W/t/tests/test_control_classifier.sh"
                    WANT="FAIL  \\[a\\] tests/test_control_classifier.sh:[0-9]*: a ground-truth gate prints" ;;
    truth-arrow)    printf 'echo "CONTROL CAUGHT: flip — FAIL  rule 1 -> HONOURED"\n' >> "$W/t/tests/test_control_classifier.sh"
                    WANT="FAIL  \\[a\\] tests/test_control_classifier.sh:[0-9]*: a ground-truth gate prints" ;;
    truth-stderr)   printf 'echo "CONTROL CAUGHT: flip — FAIL  [E1] row 3" >&2\n' >> "$W/t/tests/test_control_classifier.sh"
                    WANT="FAIL  \\[a\\] tests/test_control_classifier.sh:[0-9]*: a ground-truth gate prints" ;;
    truth-printf)   printf '%s\n' "printf '%s\\\\n' \"CONTROL CAUGHT: flip — FAIL  [E1] row 3\"" >> "$W/t/tests/test_control_classifier.sh"
                    WANT="FAIL  \\[a\\] tests/test_control_classifier.sh:[0-9]*: a ground-truth gate prints" ;;
    truth-devstderr) printf 'echo "CONTROL CAUGHT: flip — FAIL  [E1] row 3" >/dev/stderr\n' >> "$W/t/tests/test_control_classifier.sh"
                    WANT="FAIL  \\[a\\] tests/test_control_classifier.sh:[0-9]*: a ground-truth gate prints" ;;
    truth-prefixed) printf 'X=1 /bin/echo "CONTROL CAUGHT: flip — FAIL  [E1] row 3"\n' >> "$W/t/tests/test_control_classifier.sh"
                    WANT="FAIL  \\[a\\] tests/test_control_classifier.sh:[0-9]*: a ground-truth gate prints" ;;
    truth-heredoc)  printf 'cat <<EOF\nCONTROL CAUGHT: flip — FAIL  [E1] row 3\nEOF\n' >> "$W/t/tests/test_control_classifier.sh"
                    WANT="FAIL  \\[a\\] tests/test_control_classifier.sh:[0-9]*: a ground-truth gate prints" ;;
    truth-near)     _tc="$W/t/tests/test_control_classifier.sh"   # each line redirected on its own: the lint reads one line at a time
                    printf '%s\n' 'printf '"'"'PASS\nCONTROL CAUGHT: flip — x\n'"'"' > "$W/synthetic.log"' >> "$_tc"
                    printf '%s\n' 'echo "CONTROL CAUGHT: flip — x -> y" >> "$W/synthetic.log" 2>&1' >> "$_tc"
                    printf '%s\n' 'echo "== a CONTROL CAUGHT line in prose"' >> "$_tc"; WANT="" ;;
    near-miss)      gate 2 'case "$VS_CTL" in m1) want="FAIL  \[E1 a" ;; m2) want="FAIL  \[E1 b" ;; esac' 'vs_ctl_caught "$W/out" "$want"'; WANT="" ;;
    esac
}

# the main check: the tracked tree, or under a mode the copy that mode perturbs
ROOT="$REPO"; DECL="$W/decl.txt"; WANT=""
if [ -n "${VS_CTL:-}" ]; then plant "$VS_CTL"; ROOT="$W/t"; DECL="$W/t.decl"; fi
lint "$ROOT" "$DECL" "$W/main.out"; st=$?
cat "$W/main.out"
if [ "$st" != 0 ]; then
    [ -n "${VS_CTL:-}" ] && vs_ctl_caught "$W/main.out" "$WANT"
    echo "FAIL: test_ctl_caught_lint — the lint named the finding(s) above (exit $st)"; exit 1
fi
[ -n "${VS_CTL:-}" ] && vs_ctl_left_green "$VS_CTL" "FAIL: test_ctl_caught_lint — control mode $VS_CTL left the lint green"
grep -q '^NOTE: ctl_caught.debt_gates [0-9]' "$W/main.out" || { echo "FAIL: test_ctl_caught_lint — the lint printed no debt NOTE"; exit 1; }

# the controls, each on its own copy (plain run only), and the near miss
fail=0
for c in $(vs_ctl_declared "$0"); do
    plant "$c"; lint "$W/t" "$W/t.decl" "$W/c.out"; s=$?
    if [ "$s" = 1 ] && _l="$(grep -m1 -E "$WANT" "$W/c.out")"; then vs_ctl_fired "$c" "$(printf '%s' "$_l" | sed 's/^ *//' | cut -c1-120)"
    else vs_ctl_dead "$c" "the lint exited $s without '$WANT': $(grep -m1 FAIL "$W/c.out" | cut -c1-100)" || fail=1; fi
done
plant near-miss; lint "$W/t" "$W/t.decl" "$W/n.out"; s=$?
if [ "$s" = 0 ]; then echo "  ok    near miss: a migrated two-mode gate with a per-mode ERE passes"
else echo "  FAIL  near miss: the lint refused a migrated two-mode gate with a per-mode ERE: $(grep -m1 FAIL "$W/n.out")"; fail=1; fi
plant truth-near; lint "$W/t" "$W/t.decl" "$W/n.out"; s=$?
if [ "$s" = 0 ]; then echo "  ok    near miss: a ground-truth gate writing the literal to a file, or naming it in prose, passes"
else echo "  FAIL  near miss: the lint refused a ground-truth gate's synthetic log or prose: $(grep -m1 FAIL "$W/n.out")"; fail=1; fi
[ "$fail" = 0 ] && echo "PASS: test_ctl_caught_lint — no finding on the tree; all 18 planted shapes named; both near misses pass" \
                || echo "FAIL: test_ctl_caught_lint — see above"
exit "$fail"
