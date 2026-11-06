#!/bin/sh
# test_signal_traps.sh — A SCRIPT THAT TRAPS INT, TERM, HUP OR QUIT ENDS IN THAT TRAP (#359, 14z-221c). ci_portable: no ROM, ~14 s.
#
# WHAT: no shell script under tests/ or tools/ carries a trap on INT, TERM, HUP or QUIT whose action runs no `exit`
#   (RESUMES), exits with no non-zero status (EXITS0), or cannot be read (UNREAD) — tools/signal_traps.py. A POSIX
#   shell runs a signal trap's action and RESUMES the script; `trap '<cleanup>' EXIT INT TERM` (228 traps in 221
#   files at a152efa7) let a gate that the runner's timeout(1) sent TERM run its cleanup and keep running after the
#   runner had recorded TIMEOUT. The accepted form: trap '<cleanup>' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
# HOW: 1. the PREMISE, measured on every shell this host has (sh, bash, dash): a stub with the old form, sent TERM
#   while it sleeps, prints the line after its sleep and exits 0; the same stub in the accepted form does not, exits
#   143 and runs its cleanup once; and the accepted form's normal-path status is the script's own `exit N` (0, 1, 3).
#   2. the census over the tree, which must read at least 500 shell files and 400 stopping-signal traps (a blinded
#   scan reads fewer). 3. known answers on synthetic scripts: five bad forms named with their tag, seven good forms
#   not named. 4. the control.
# EXPECTS: 0 named on the tree. A red names the file, the line and the tag; the fix is the accepted form above (a
#   function action takes `exit 130` / `exit 143` traps of its own the same way).
#
# MUST-FIRE: known-bad: grep-planted — section 2b's plain grep given one more file holding `trap 'rm -rf "$W"' EXIT INT TERM` must name it NEW and FAIL the gate (in-gate: the same grep run on the planted file alone must name it; mode: the planted file joins the tracked list)
# MUST-FIRE: known-bad: resuming-trap — a script with `trap 'rm -rf "$W"' EXIT INT TERM` added to the census of the tree must be named RESUMES and FAIL the gate (mode: section 2 reads that planted script with the tree)
#
# WHY A PREMISE SECTION: the rule rests on a shell behaviour, so the gate re-measures it each run instead of citing it;
#   a host whose shell stopped resuming would show here. INT is not measured: a background job of a non-interactive
#   shell starts with INT ignored, and an ignored-at-entry signal cannot be trapped.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_signal_traps — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

echo "== 1. the premise: what a TERM does to each trap form"
cat > "$W/old.sh" <<'EOF'
trap 'echo CLEANUP' EXIT INT TERM
: > "$1"
sleep 1
echo AFTER-SLEEP
EOF
cat > "$W/exitonly.sh" <<'EOF'
trap 'echo CLEANUP' EXIT
: > "$1"
sleep 1
echo AFTER-SLEEP
EOF
cat > "$W/new.sh" <<'EOF'
trap 'echo CLEANUP' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
: > "$1"
sleep 1
echo AFTER-SLEEP
EOF
term_run() {  # term_run <shell> <stub> <out>: start the stub, send it TERM once its traps are armed; prints its exit status
    rm -f "$W/armed"
    "$1" "$2" "$W/armed" > "$3" 2>&1 &
    _p=$!; _i=0
    while [ ! -e "$W/armed" ] && [ "$_i" -lt 200 ]; do sleep 0.05; _i=$((_i + 1)); done
    kill -TERM "$_p" 2>/dev/null
    wait "$_p"; echo "$?"
}
shells=0
for sh in sh bash dash; do
    command -v "$sh" >/dev/null 2>&1 || continue
    shells=$((shells + 1))
    rc="$(term_run "$sh" "$W/old.sh" "$W/old.$sh.out")"
    nc="$(grep -c CLEANUP "$W/old.$sh.out")"
    if [ "$rc" = 0 ] && grep -q AFTER-SLEEP "$W/old.$sh.out"; then
        ok "$sh: the old form resumed after TERM (ran AFTER-SLEEP, exit 0, cleanup run $nc times)"
    else
        bad "$sh: the old form did not resume after TERM (exit $rc: $(tr '\n' ' ' < "$W/old.$sh.out")) — the rule's premise no longer holds here; re-read #359"
    fi
    rc="$(term_run "$sh" "$W/new.sh" "$W/new.$sh.out")"
    nc="$(grep -c CLEANUP "$W/new.$sh.out")"
    if [ "$rc" = 143 ] && [ "$nc" = 1 ] && ! grep -q AFTER-SLEEP "$W/new.$sh.out"; then
        ok "$sh: the accepted form stopped on TERM (exit 143, cleanup run once, no AFTER-SLEEP)"
    else
        bad "$sh: the accepted form did not stop cleanly on TERM (exit $rc, cleanup $nc times: $(tr '\n' ' ' < "$W/new.$sh.out"))"
    fi
    # reported, never asserted (14z-221c, #359's worker): whether an EXIT-only trap runs on TERM differs by shell — dash
    # (PILOT's /bin/sh) did not run it, sh and bash on macOS did — so an EXIT-only gate can leak its $W when TERM'd there
    rc="$(term_run "$sh" "$W/exitonly.sh" "$W/exitonly.$sh.out")"
    echo "  MEASURE  $sh: an EXIT-only trap under TERM: exit $rc, cleanup run $(grep -c CLEANUP "$W/exitonly.$sh.out") time(s)"
    nfail=0
    for n in 0 1 3; do
        printf "trap 'rm -f \"\$1\"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM\n: > \"\$1\"\nexit %s\n" "$n" > "$W/st.sh"
        "$sh" "$W/st.sh" "$W/st.tmp" >/dev/null 2>&1; rc=$?
        if [ "$rc" = "$n" ] && [ ! -e "$W/st.tmp" ]; then :; else
            nfail=1; bad "$sh: the accepted form's normal exit $n came back $rc (cleanup ran: $([ -e "$W/st.tmp" ] && echo no || echo yes))"; fi
    done
    [ "$nfail" = 0 ] && ok "$sh: the accepted form's normal-path status is the script's own (exit 0, 1, 3) and its cleanup ran"
done
[ "$shells" -ge 1 ] || bad "no shell found to measure the premise on"

echo "== 2. the census of tests/ and tools/"
EXTRA=""
if vs_ctl_is resuming-trap; then
    mkdir -p "$W/plant"
    printf '#!/bin/sh\nW="$(mktemp -d)" || exit 2\ntrap '"'"'rm -rf "$W"'"'"' EXIT INT TERM\nsleep 60\n' > "$W/plant/zz_planted_resume.sh"
    EXTRA="$W/plant/zz_planted_resume.sh"
fi
# shellcheck disable=SC2086
out="$(python3 tools/signal_traps.py --root "$REPO" ${EXTRA:+--extra "$EXTRA"} 2>&1)"; rc=$?
echo "$out" | grep -v '^[0-9]' | head -20 | sed 's/^/        /'
last="$(echo "$out" | tail -1)"
if [ -n "$EXTRA" ]; then   # the mode's own finding: the planted script named RESUMES
    if echo "$out" | grep >/dev/null "^RESUMES	$EXTRA:3	"; then
        echo "FAIL: test_signal_traps (control mode: the planted trap was named RESUMES)"; exit 1; fi
    if [ "$rc" != 0 ]; then printf '%s\n' "$out" > "$W/mode.out"; vs_ctl_show_err "$W/mode.out" || :
        echo "NOT JUDGED: $VS_CTL — the census failed (exit $rc) without naming the planted trap"; echo "FAIL: test_signal_traps"; exit 1; fi
    vs_ctl_left_green "$VS_CTL" "FAIL: test_signal_traps — the planted trap was not named"
fi
if [ "$rc" = 0 ]; then ok "no script resumes after a stopping signal: $last"
else printf '%s\n' "$out" > "$W/s2.out"; vs_ctl_show_err "$W/s2.out" || :
    bad "trap(s) named above (exit $rc): write them as trap '<cleanup>' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM"; fi
nf="$(echo "$last" | sed -n 's/^\([0-9]*\) shell file.*/\1/p')"; ns="$(echo "$last" | sed -n 's/.*read, \([0-9]*\) on INT.*/\1/p')"
if [ "${nf:-0}" -ge 500 ] && [ "${ns:-0}" -ge 400 ]; then ok "the census read $nf shell files and $ns stopping-signal traps (floors 500 / 400)"
else bad "the census read ${nf:-?} shell files and ${ns:-?} stopping-signal traps, under the floors 500 / 400: a blinded scan"; fi

echo "== 2b. a second method: plain grep, sharing nothing with the reader (14z-221c, rule-checker run 2026-11-06-1671)"
# Every tracked file under tests/ and tools/ outside tests/rulecheck/, in ANY language, for (A) a line naming trap and a
# stopping signal, (B) a signal list on a line without the word trap (a multi-line action's tail), minus comment lines and
# the accepted forms; a hit must be one of the ALLOWED lines (fixture or prose text, by exact content), never a new one.
# This gate and tools/signal_traps.py hold bad forms as fixtures by design and are left out. Grep-pattern-bound: a trap
# built in a variable or a signal list split across lines is beyond it (stated, not tested).
GA="$W/grep_allowed.txt"
cat > "$GA" <<'ALLOWED'
tests/test_tmp_hygiene.sh	trap 'rm -rf "$Q/x"' INT TERM
tests/test_tmp_hygiene.sh	else ok "eight safe trap forms not named (a later trap, \"\$M\" alone, another variable, trap text in quotes, an INT-only trap, a heredoc, a trap after a later-line [ -n ] guard, the word trap as an argument)"; fi
ALLOWED
git -C "$REPO" ls-files tests tools | grep -v '^tests/rulecheck/' | grep -vx 'tests/test_signal_traps.sh' | grep -vx 'tools/signal_traps.py' > "$W/grep_files.txt"
printf '#!/bin/sh\nW="$(mktemp -d)" || exit 2\ntrap '"'"'rm -rf "$W"'"'"' EXIT INT TERM\n' > "$W/plant2b.sh"
vs_ctl_is grep-planted && echo "$W/plant2b.sh" >> "$W/grep_files.txt"
grep2b() {  # grep2b <file list> <hits out>: the section's grep over the listed files
    ( cd "$REPO" && tr '\n' '\0' < "$1" | xargs -0 grep -HnIE '(INT|TERM|HUP|QUIT)' 2>/dev/null ) \
        | grep -E 'trap|(EXIT|0)[ ]+(INT|2)[ ]+(TERM|15)|INT[ ]+TERM|HUP|QUIT' \
        | grep -vE "^[^:]+:[0-9]+:[[:space:]]*#" \
        | grep -vE "trap 'exit 1[34][03]' (INT|TERM)" > "$2" || :
}
ng="$(wc -l < "$W/grep_files.txt" | tr -d ' ')"
grep2b "$W/grep_files.txt" "$W/grep_hits.txt"
nh=0; nnew=0
while IFS= read -r h; do
    nh=$((nh + 1)); f="${h%%:*}"; rest="${h#*:}"; txt="${rest#*:}"
    if grep -qxF "$(printf '%s\t%s' "$f" "$txt")" "$GA"; then :; else nnew=$((nnew + 1)); echo "        NEW  $h"; fi
done < "$W/grep_hits.txt"
[ "$ng" -ge 5000 ] || bad "the grep read $ng tracked files, under the 5000 floor: a blinded file list"
if [ "$nnew" = 0 ]; then ok "plain grep over $ng tracked files: $nh hit(s), every one an allowed fixture or prose line, no resuming trap"
else
    if vs_ctl_is grep-planted && grep -q "plant2b.sh" "$W/grep_hits.txt"; then echo "FAIL: test_signal_traps (control mode: the planted trap was named NEW)"; exit 1; fi
    bad "plain grep over $ng tracked files: $nnew hit(s) outside the allowed lines (above) — a trap the reader may not have judged"; fi
if vs_ctl_is grep-planted; then vs_ctl_left_green grep-planted "FAIL: test_signal_traps — the planted trap was not named by the grep"; fi
echo "$W/plant2b.sh" > "$W/grep_plant_list.txt"; grep2b "$W/grep_plant_list.txt" "$W/grep_plant_hits.txt"
if grep -q "plant2b.sh:3:" "$W/grep_plant_hits.txt"; then vs_ctl_fired grep-planted "$(head -1 "$W/grep_plant_hits.txt" | cut -c1-120)"
else vs_ctl_dead grep-planted "the grep did not name a planted resuming trap" || fail=1; fi

echo "== 3. known answers"
K="$W/k"; mkdir -p "$K"
# the bad forms, one per file: <tag> <file>
cat > "$K/b_combined.sh" <<'EOF'
#!/bin/sh
W="$(mktemp -d)" || exit 2; trap 'rm -rf "$W"' EXIT INT TERM
EOF
cat > "$K/b_sigonly.sh" <<'EOF'
#!/bin/sh
trap 'echo stopping' TERM HUP
EOF
cat > "$K/b_func.sh" <<'EOF'
#!/bin/sh
cleanup() { rm -rf "$W"; echo "will not exit"; }
trap cleanup EXIT SIGINT 15
EOF
cat > "$K/b_exit0.sh" <<'EOF'
#!/bin/sh
trap 'rm -rf "$W"; exit' INT TERM
EOF
cat > "$K/b_unread.sh" <<'EOF'
#!/bin/sh
CMD='rm -rf "$W"'
trap "$CMD" INT TERM
EOF
# the good forms, all in one file: none may be named
cat > "$K/good.sh" <<'EOF'
#!/bin/sh
W="$(mktemp -d)" || exit 2; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
trap 'rm -rf "$W"' EXIT   # a comment after the trap
X=1
stop() { rm -rf "$W"; exit 143; }
trap stop TERM
trap '' INT
trap - INT TERM
echo "trap 'rm -rf x' EXIT INT TERM is text here"
cat > "$W/stub.sh" <<'STUB'
trap 'echo inside a heredoc' EXIT INT TERM
STUB
EOF
for pair in RESUMES:b_combined RESUMES:b_sigonly RESUMES:b_func EXITS0:b_exit0 UNREAD:b_unread; do
    tag="${pair%%:*}"; f="${pair#*:}"
    o="$(python3 tools/signal_traps.py --root "$K/none" --extra "$K/$f.sh" 2>&1)"; r=$?
    if [ "$r" = 1 ] && echo "$o" | grep >/dev/null "^$tag	$K/$f.sh:"; then ok "$f.sh named $tag"
    else bad "$f.sh not named $tag (exit $r): $(echo "$o" | head -2 | tr '\n' ' ')"; fi
done
o="$(python3 tools/signal_traps.py --root "$K/none" --extra "$K/good.sh" 2>&1)"; r=$?
if [ "$r" = 0 ] && echo "$o" | tail -1 | grep -q '^1 shell file(s), 7 trap command(s) read, 3 on INT/TERM/HUP/QUIT; 0 named$'; then
    ok "seven good forms not named (the split form, EXIT alone with a trailing comment, a function that exits 143, an ignored INT, a reset, trap text in quotes and in a heredoc): $(echo "$o" | tail -1)"
else bad "the good forms: exit $r, $(echo "$o" | tr '\n' ' ')"; fi

echo "== 4. control"
mkdir -p "$W/c"
printf '#!/bin/sh\nW="$(mktemp -d)" || exit 2\ntrap '"'"'rm -rf "$W"'"'"' EXIT INT TERM\nsleep 60\n' > "$W/c/zz_planted_resume.sh"
o="$(python3 tools/signal_traps.py --root "$REPO" --extra "$W/c/zz_planted_resume.sh" 2>&1)"
if echo "$o" | grep >/dev/null "^RESUMES	$W/c/zz_planted_resume.sh:3	"; then
    vs_ctl_fired resuming-trap "$(echo "$o" | grep -m1 '^RESUMES' | cut -c1-140)"
else printf '%s\n' "$o" > "$W/c.out"; vs_ctl_show_err "$W/c.out" || :
    vs_ctl_dead resuming-trap "the planted trap was not named: $(echo "$o" | tail -1)"; fail=1; fi

[ "$fail" = 0 ] && echo "PASS: test_signal_traps" || echo "FAIL: test_signal_traps"
exit "$fail"
