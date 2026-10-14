#!/bin/sh
# test_close_tools.sh — THE CLOSE RITUAL'S FILE-LEVEL CHECKS RUN AND CAN FAIL: the retraction grep's
# gone wordings stay gone in what the sitting touched, and the matcher, the homes tool, the address
# scan and the reason check each pass their own self-test (tools/retraction_grep.py,
# tools/homes_tracked.py, tools/close_findings.py, tools/none_reasons.py). ci_portable: no ROM, no
# emulator, ~10 s (measured 14z-199; it read "~3 s" while one full scan per retraction file made it
# 565 s — #268).
#
# WHAT: (1) since #268 (maintainer-ruled 2026-10-12, 14z-199) EVERY tests/rulecheck/retractions/*.tsv's
#   GONE wordings read 0 hits in the files the sitting TOUCHED — the paths changed since origin/main,
#   committed or not, plus every untracked file under the scan's roots — read by ONE touched scan
#   (tools/retraction_grep.py --touched LIST --each). The matcher judges each file's text alone
#   (retraction_grep.py judge: a pattern is found in one file's normalised text or not), so an
#   OLD gone wording can come back only in a file that changed; a pattern file the sitting CHANGED —
#   a new one, or a new gone wording added to an old one — is judged on the WHOLE tree instead,
#   since its new wordings were never scanned (rule-checker run 2026-10-13-946 Q4). REACH controls of
#   unchanged pattern files need the whole tree and are judged by
#   tests/test_retraction_reach.sh at every freeze and release (and the sitting's OWN file on the whole
#   tree by the close's standing check `retraction_grep`). The touched list is the static runner's
#   (tests/run_all_static.sh cad_changed: STATIC_CHANGED_PATHS when set, else git), with the same
#   limit: in a snapshot clone (tests/run_on_snapshot.sh) origin/main is the source tree's own branch,
#   so the list holds only what the snapshot itself changed — a freeze runs the whole-tree gate anyway.
#   With no origin/main at all the section runs the FULL scan, reach judged too (the safe side);
#   (1b) the matcher's self-test;
#   (2) tools/homes_tracked.py --selftest
#   passes, and (2b) the tool runs on the NEWEST findings-table row of STATE.md (the current
#   sitting's, on the live tree: every home and test it names is tracked) — a planted findings row citing a backticked build/ file, a prose build/ path, a name
#   that resolves nowhere, a gate stem that resolves nowhere, a ticket with no index row, ticket rows
#   citing a build/ file, an untracked file and a § anchor on no line, a prose-cited document that resolves nowhere and a
#   parenthesised test clause saying scratch, and a backticked and a prose name that end two or
#   more tracked files but are none of them exactly (AMBIGUOUS, rule-checker run 2026-09-25-206), are
#   caught on all eleven, and a real gate stem, a clean ticket and a prose-cited README resolve; and
#   (since 14z-189, #205) a bare document name that resolves is REPORTED TRACKED (in prose and
#   backticked), one in a home that resolves nowhere FAILs, and every finding letter is judged on its
#   OWN homes — a letter whose homes resolve to no tracked file and no ticket row FAILs, whatever the
#   other letters cite (four such letters in the plant), and an option's `(a)` inside a finding is not
#   a letter;
#   (1c, since 14z-184) tools/close_findings.py --selftest: its planted-address, suffix-address (the
#   second address a `/NN` suffix form names) and old-home-only controls all fire; (2c, since
#   14z-188) tools/none_reasons.py --selftest: a findings row whose test is a bare `none` is caught,
#   one that says why passes; (2e, since 14z-201, #282 item C) tools/findings_table.py --selftest: a
#   findings section naming a TSV reads as the one-line row the tools parse, a missing TSV as MISSING. NEVER write a
#   self-test's planted address in this header: a gate header is a live home to that tool, and the
#   plant would read homed (paid 14z-184: the suffix control read DEAD until the literal left).
# HOW: the tools run in-process on the tree; the controls run the touched scan on a copy of a pattern
#   file with a wording of this gate's own text planted as gone, and each self-test on its known-bad
#   variant, which must fail it. Under a mode only the section the control perturbs runs (#268): the
#   other sections read inputs the perturbation does not touch, and each cost a full run per mode.
# EXPECTS: PASS when every gone wording is absent from the touched files, every self-test passes and
#   the newest findings row is clean. A tool that exits non-zero
#   WITHOUT its own FAIL line (a crash, a refused pattern file) is REFUSED (exit 3, dead), never a
#   red — in a MODE too: a mode passes only on the plant's own FAIL text. A red names the pattern file and the gone wording
#   that came back in a touched file (a retracted claim reintroduced), or the self-test that failed.
#
# MUST-FIRE: perturbed-copy: gone-new-untouched — a CHANGED copy of a retraction TSV (listed as touched) with a NEW gone wording that only an UNTOUCHED file carries (this gate's own header, the gate not listed) must get the WHOLE-TREE scan and fail naming the wording (in-gate on a two-file stand-in for the tree, RETRACTION_GREP_UNIVERSE, which proves the routing in ~1 s; the mode on the real tree), so a gone wording added this sitting cannot hide in a file nobody touched (rule-checker run 2026-10-13-946 Q4) (in-gate: the copy and a list naming only it; mode: the copy replaces the newest real pattern file in the real list, the gate's script removed from it, and the gate FAILs)
# MUST-FIRE: perturbed-copy: gone-touched — a copy of a retraction TSV with a wording of THIS gate's own text marked `gone`, the gate's script listed as touched, must make the touched scan (tools/retraction_grep.py --touched LIST --each) fail that file naming the wording, so the touched scan reads the files it is given and judges their gone wordings (in-gate: the copy and a one-file list; mode: the copy replaces the newest real pattern file and the script joins the real touched list, and the gate FAILs) — the three whole-tree controls (unreachable-control, reach-threshold, gone-reintroduced) moved with the whole-tree scan to tests/test_retraction_reach.sh (#268)
# MUST-FIRE: known-bad: case-fold-dropped — tools/retraction_grep.py --selftest --nofold: the matcher with its case-folding REMOVED (a known-bad variant) must print SELFTEST FAIL naming the upper-case heading case, while --selftest prints SELFTEST PASS — the self-test matches planted TEXTS (a wording in an UPPER-CASE heading, one wrapped across a `#` prefix, one across a Lua `--` prefix, one code-spanned), not the tree, so no stray carrier elsewhere can mask a matcher defect (rule-checker run 2026-09-25-199 Q4) (in-gate; mode: the no-fold variant is the one checked, so the gate FAILs)
# MUST-FIRE: known-bad: markup-dropped — tools/retraction_grep.py --selftest --nomarkup: the matcher without its #242 collapses (14z-195: a Markdown quote prefix on a wrapped line, a rendered page's tags and entities, a code string join, `**` emphasis) must print SELFTEST FAIL naming the quote-wrapped case, while --selftest passes (mode: the matcher self-test runs with --nomarkup)
# MUST-FIRE: shadow-tool: output-overwrites — a copy of tools/homes_tracked.py without its output-path guard, given the state copy it reads as its output, must overwrite that copy, and section 2d must FAIL on it (mode: section 2d runs that copy)
# MUST-FIRE: known-bad: build-home-planted — tools/homes_tracked.py --selftest --blind: the tool with its build/ reads DISABLED (a known-bad variant) must FAIL its own self-test, whose planted row cites a backticked build/ file and a prose build/ path, an unresolved name, an unresolved gate stem, a ticket with no index row, ticket rows (a planted index) citing a build/ file, an untracked file and a § anchor on no line, a prose-cited document that resolves nowhere and a parenthesised scratch-citing test clause (in-gate: --selftest must print SELFTEST PASS and --selftest --blind must print SELFTEST FAIL naming the two build/ reads as missed — a traceback is DEAD, not fired; mode: the blind variant is the one checked, so the gate FAILs because the plant is not caught)
# MUST-FIRE: known-bad: bare-name-silent — tools/homes_tracked.py --selftest --nobare: the tool with bare-name resolution REMOVED (the pre-#205 tool, a bare `engine_internals` silent) must print SELFTEST FAIL with bare=False, while --selftest prints SELFTEST PASS (section 2; #205, rule-checker run 2026-10-02-562) (in-gate; mode: the no-bare variant is the one checked, so the gate FAILs)
# MUST-FIRE: known-bad: letter-unchecked — tools/homes_tracked.py --selftest --noletters: the tool with the PER-LETTER home check removed must print SELFTEST FAIL with letters=False, so a finding whose only home resolves nowhere cannot pass on the other letters' homes (section 2; #205) (in-gate; mode: the no-letters variant is the one checked, so the gate FAILs)
# MUST-FIRE: known-bad: bare-none-accepted — tools/none_reasons.py --selftest --lenient: the reason check with a bare `none` ACCEPTED (a known-bad variant) must print SELFTEST FAIL on the planted bare-none row, while --selftest prints SELFTEST PASS (section 2c; 14z-188 close, rule-checker run 2026-10-02-563)
#
# WHY: at the 14z-181 close the two checks lived in inline scripts recorded nowhere, and the
# table they checked cited five build-only files (rule-checker runs 185-187, GitHub #152's
# discipline: a test that exists only in a build/ artifact is not a test).
#
# Usage: tests/test_close_tools.sh
#
# CONFIRM: always — the CORE of a session run (#269, 14z-200): it reads the paths changed since origin/main, which move with every commit and fetch,
# none of which a changed tracked path shows, so tests/run_all_static.sh --confirm never carries it.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d "${TMPDIR:-/tmp}/closetools.XXXXXX")"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
unset RETRACTION_GREP_UNIVERSE   # a test harness's stand-in for the tree, set below for ONE control only (#268)

runs_for() {   # runs_for <control>... — true outside a mode, or when the mode is one of this section's controls (#268)
    [ -z "${VS_CTL:-}" ] && return 0
    for _c in "$@"; do [ "$VS_CTL" = "$_c" ] && return 0; done
    return 1
}
NEWEST="$(ls tests/rulecheck/retractions/*.tsv | tail -1)"
plant_gone() {   # plant_gone <copy> — $NEWEST plus a wording of this gate's own text marked gone; sets EXPECT
    PW="$(sed -n 's/^# WHAT: \((1) since #268 (maintainer-ruled [^)]*) EVERY\) .*$/\1/p' tests/test_close_tools.sh | head -1)"
    [ -n "$PW" ] || { echo "REFUSED: the planted wording's line moved out of this gate's header"; exit 3; }
    cp "$NEWEST" "$1"; printf '%s\tplanted: a wording of tests/test_close_tools.sh marked gone (the control gone-touched)\tgone\n' "$PW" >> "$1"
    EXPECT="marked GONE is back in the tree: $PW"
}
judge_split() {   # judge_split <list|-> <out> <tsv>... — a pattern file the sitting CHANGED (in the list) is judged on the
    # WHOLE tree: its gone wordings may be new, and a new one already in an untouched file is a red (rule-checker run
    # 2026-10-13-946 Q4); every other file's gone wordings on the listed (touched) files only. `-`: everything whole.
    _l="$1"; _o="$2"; shift 2; _full=""; _rest=""
    for _t in "$@"; do
        if [ "$_l" = - ] || grep -qxF "$_t" "$_l"; then _full="$_full $_t"; else _rest="$_rest $_t"; fi
    done
    : > "$_o"; _rc=0
    # shellcheck disable=SC2086
    if [ -n "$_full" ]; then python3 tools/retraction_grep.py --each $_full >> "$_o" 2>&1; _r=$?; [ "$_r" -gt "$_rc" ] && _rc=$_r; fi
    # shellcheck disable=SC2086
    if [ -n "$_rest" ]; then python3 tools/retraction_grep.py --touched "$_l" --each $_rest >> "$_o" 2>&1; _r=$?; [ "$_r" -gt "$_rc" ] && _rc=$_r; fi
    _want=0; [ -n "$_full" ] && _want=$((_want + 1)); [ -n "$_rest" ] && _want=$((_want + 1))
    [ "$(grep -c '^EACH: ' "$_o")" = "$_want" ] || _rc=3
    return "$_rc"
}
if runs_for gone-touched gone-new-untouched; then
echo "== 1. every retraction file's GONE wordings in the files the sitting touched; a CHANGED retraction file on the whole tree"
set -- tests/rulecheck/retractions/*.tsv
real="$*"; list="$W/touched.txt"
if [ -n "${STATIC_CHANGED_PATHS+x}" ]; then   # the runner's override (tests/run_all_static.sh cad_changed)
    printf '%s\n' "$STATIC_CHANGED_PATHS" | awk 'NF' | sort -u > "$list"
elif git rev-parse -q --verify origin/main >/dev/null 2>&1; then
    { git diff --name-only origin/main; git ls-files --others -- docs tests tools build/manifest; } | sort -u > "$list"
else
    list=-; echo "  note  no origin/main to diff against: every pattern file is judged on the WHOLE tree (reach too) — the safe side"
fi
if vs_ctl_is gone-touched; then
    plant_gone "$W/mode.tsv"; MODE_EXPECT="$EXPECT"
    real="$(printf '%s\n' "$@" | sed "s#^$NEWEST\$#$W/mode.tsv#" | tr '\n' ' ')"
    echo tests/test_close_tools.sh >> "$list"
    echo "MODE: control gone-touched — $NEWEST replaced by a copy where a wording of this gate's header is marked gone, and this gate listed as touched"
elif vs_ctl_is gone-new-untouched; then
    plant_gone "$W/mode.tsv"; MODE_EXPECT="$EXPECT"
    real="$(printf '%s\n' "$@" | sed "s#^$NEWEST\$#$W/mode.tsv#" | tr '\n' ' ')"
    [ "$list" = - ] || { grep -vxF tests/test_close_tools.sh "$list" > "$W/l2"; echo "$W/mode.tsv" >> "$W/l2"; list="$W/l2"; }
    echo "MODE: control gone-new-untouched — $NEWEST replaced by a CHANGED copy with a new gone wording of this gate's header, this gate NOT listed as touched"
fi
judge_split "$list" "$W/each.out" $real; rc=$?
if [ "$rc" -ge 2 ]; then
    echo "REFUSED: tools/retraction_grep.py --each printed no EACH line, or exited $rc (a crash or a refusal, not a verdict): $(grep -v '^FILE' "$W/each.out" | tail -1 | cut -c1-160)"; exit 3
fi
if [ "$rc" -eq 0 ]; then ok "$(grep '^# retraction_grep.py --each' "$W/each.out" | sed 's/^# retraction_grep.py --each: //' | cut -c1-110 | tr '\n' '|'): $(grep '^EACH' "$W/each.out" | tr '\n' ' ')"
else
    bad "$(grep '^FILE .*: FAIL' "$W/each.out" | cut -c1-220 | tr '\n' ' ')"
    if [ -n "${VS_CTL:-}" ] && ! grep -F "FILE $W/mode.tsv: " "$W/each.out" | grep -qF "$MODE_EXPECT"; then
        echo "REFUSED: mode $VS_CTL — the scan failed WITHOUT naming the plant ($MODE_EXPECT)"; exit 3
    fi
fi
fi

if runs_for case-fold-dropped markup-dropped; then
echo "== 1b. the matcher itself: case-folding, comment-prefix and backtick collapsing on planted texts"
nofold=""
if vs_ctl_is case-fold-dropped; then nofold="--nofold"; echo "MODE: control case-fold-dropped — the matcher self-test runs WITHOUT case-folding"; fi
if vs_ctl_is markup-dropped; then nofold="--nomarkup"; echo "MODE: control markup-dropped — the matcher self-test runs WITHOUT the #242 collapses"; fi
out="$(python3 tools/retraction_grep.py --selftest $nofold 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^SELFTEST PASS'; then ok "$(printf '%s\n' "$out" | tail -1 | cut -c1-160)"
elif printf '%s\n' "$out" | grep -q '^SELFTEST FAIL'; then
    bad "$(printf '%s\n' "$out" | grep '^SELFTEST FAIL' | cut -c1-160)"
    if vs_ctl_is case-fold-dropped && ! printf '%s\n' "$out" | grep -q '^SELFTEST FAIL:.*upper-case'; then echo "REFUSED: mode case-fold-dropped — the no-fold self-test failed but NOT on the upper-case case"; exit 3; fi
    if vs_ctl_is markup-dropped && ! printf '%s\n' "$out" | grep -q '^SELFTEST FAIL:.*quote-wrapped'; then echo "REFUSED: mode markup-dropped — the no-markup self-test failed but NOT on the quote-wrapped case"; exit 3; fi
else echo "REFUSED: the matcher self-test neither passed nor failed on its own line (exit $rc — a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi
fi

if [ -z "${VS_CTL:-}" ]; then
echo "== 1c. the address scan (tools/close_findings.py --selftest): a planted address, a suffix-form address and an old-only home"
# its three control lines are the tool's own, reported here as one verdict (not as this gate's CONTROL lines): no gate ran
# the self-test until 14z-184, when the documentation packet (rule-checker run 2026-09-25-322) found `0x028B5A/5E`'s second
# address unread
out="$(python3 tools/close_findings.py --selftest 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && [ "$(printf '%s\n' "$out" | grep -c '^CONTROL FIRED:')" -eq 3 ]; then ok "close_findings self-test: planted-address, suffix-address and old-home-only all fire"
elif printf '%s\n' "$out" | grep -q '^CONTROL DEAD:'; then bad "close_findings self-test: $(printf '%s\n' "$out" | grep '^CONTROL DEAD:' | cut -c1-140 | tr '\n' ' ')"
else echo "REFUSED: tools/close_findings.py --selftest neither passed nor named a dead control (exit $rc — a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi
fi

if runs_for build-home-planted bare-name-silent letter-unchecked; then
echo "== 2. the homes tool catches a planted untracked home"
blind=""
if vs_ctl_is build-home-planted; then blind="--blind"; echo "MODE: control build-home-planted — the self-test runs on the BLIND variant (build/ reads disabled): the plant must go uncaught and the gate FAIL"; fi
if vs_ctl_is bare-name-silent; then blind="--nobare"; echo "MODE: control bare-name-silent — the self-test runs WITHOUT bare-name resolution (the pre-#205 tool): the plant must go uncaught and the gate FAIL"; fi
if vs_ctl_is letter-unchecked; then blind="--noletters"; echo "MODE: control letter-unchecked — the self-test runs WITHOUT the per-letter home check: the plant must go uncaught and the gate FAIL"; fi
out="$(python3 tools/homes_tracked.py --selftest $blind 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^SELFTEST PASS'; then ok "$(printf '%s\n' "$out" | tail -1)"
elif printf '%s\n' "$out" | grep -q '^SELFTEST FAIL'; then
    bad "$(printf '%s\n' "$out" | grep '^SELFTEST FAIL' | cut -c1-160)"
    if vs_ctl_is build-home-planted && ! printf '%s\n' "$out" | grep -q '^SELFTEST FAIL: (False, False'; then echo "REFUSED: mode build-home-planted — the blind self-test failed but NOT on the two build/ reads"; exit 3; fi
    if vs_ctl_is bare-name-silent && ! printf '%s\n' "$out" | grep -q '^SELFTEST FAIL:.* bare=False'; then echo "REFUSED: mode bare-name-silent — the no-bare self-test failed but NOT on the bare names"; exit 3; fi
    if vs_ctl_is letter-unchecked && ! printf '%s\n' "$out" | grep -q '^SELFTEST FAIL:.* letters=False'; then echo "REFUSED: mode letter-unchecked — the no-letters self-test failed but NOT on the letters"; exit 3; fi
else echo "REFUSED: the self-test neither passed nor failed on its own line (exit $rc — a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi
fi

if runs_for bare-none-accepted; then
echo "== 2c. the reason check (tools/none_reasons.py --selftest): a finding whose test is none must say why"
lenient=""
if vs_ctl_is bare-none-accepted; then lenient="--lenient"; echo "MODE: control bare-none-accepted — the self-test runs on the LENIENT variant (a bare none accepted): the plant must go uncaught and the gate FAIL"; fi
out="$(python3 tools/none_reasons.py --selftest $lenient 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^SELFTEST PASS'; then ok "$(printf '%s\n' "$out" | tail -1)"
elif printf '%s\n' "$out" | grep -q '^SELFTEST FAIL'; then bad "$(printf '%s\n' "$out" | grep '^SELFTEST FAIL' | head -1 | cut -c1-160)"
else echo "REFUSED: tools/none_reasons.py --selftest neither passed nor failed on its own line (exit $rc — a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi
fi

if [ -z "${VS_CTL:-}" ]; then
echo "== 2e. the findings TSV reader (tools/findings_table.py --selftest, #282 item C): a pointer section reads as its row"
out="$(python3 tools/findings_table.py --selftest 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^SELFTEST PASS'; then ok "$(printf '%s\n' "$out" | tail -1)"
elif printf '%s\n' "$out" | grep -q '^SELFTEST FAIL'; then bad "$(printf '%s\n' "$out" | grep 'FAIL' | head -1 | cut -c1-160)"
else echo "REFUSED: tools/findings_table.py --selftest neither passed nor failed on its own line (exit $rc — a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi
fi

unguard() {   # a copy of homes_tracked.py without the output-path guard (the control output-overwrites)
    python3 - tools/homes_tracked.py "$1" <<'PY'
import sys
s = open(sys.argv[1]).read()
a = "        if pathlib.Path(o).resolve() == pathlib.Path(state).resolve() or os.path.normpath(o) in tracked:"
assert s.count(a) == 1, "the guard moved"
open(sys.argv[2], "w").write(s.replace(a, "        if False:   # CONTROL output-overwrites"))
PY
    cp tools/findings_table.py "$(dirname "$1")/"   # the copy's sibling module (#282 item C)
}
if [ -z "${VS_CTL:-}" ]; then
echo "== 2b. the NEWEST findings table row of STATE.md, on the live tree (the close's own output is a snapshot)"
if out="$(python3 tools/homes_tracked.py --newest 2>&1)"; then ok "$(printf '%s\n' "$out" | head -1 | cut -c1-200)"
elif printf '%s\n' "$out" | grep -q '^FAIL'; then bad "$(printf '%s\n' "$out" | grep '^FAIL\|^#' | head -4 | tr '\n' ' ' | cut -c1-300)"
else echo "REFUSED: tools/homes_tracked.py --newest exited non-zero with no FAIL line (a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi
fi

if runs_for output-overwrites; then
echo "== 2d. the output path is never an input (14z-191: \`--newest STATE.md\` wrote the report over STATE.md)"
cp STATE.md "$W/S.md"; H0="$(shasum "$W/S.md" | cut -c1-40)"
HT=tools/homes_tracked.py
if vs_ctl_is output-overwrites; then unguard "$W/ht_unguarded.py"; HT="$W/ht_unguarded.py"; fi
python3 "$HT" --newest --state "$W/S.md" "$W/S.md" > "$W/ow.txt" 2>&1; rc=$?
if [ "$rc" = 3 ] && grep -q '^REFUSED: the output path' "$W/ow.txt" && [ "$(shasum "$W/S.md" | cut -c1-40)" = "$H0" ]; then
    ok "the state file given as the output path is REFUSED and left byte-identical"
else bad "the state file given as the output path was not refused (exit $rc), or it changed"; fi
fi

if [ -z "${VS_CTL:-}" ]; then
    echo "== 3. controls"
    cp STATE.md "$W/S2.md"; H2="$(shasum "$W/S2.md" | cut -c1-40)"; unguard "$W/ht_unguarded.py"
    python3 "$W/ht_unguarded.py" --newest --state "$W/S2.md" "$W/S2.md" > /dev/null 2>&1
    if [ "$(shasum "$W/S2.md" | cut -c1-40)" != "$H2" ]; then vs_ctl_fired output-overwrites "without the guard the report overwrote the state copy it read"
    else vs_ctl_dead output-overwrites "the unguarded copy left the state copy unchanged"; fail=1; fi
    plant_gone "$W/c1.tsv"; echo tests/test_close_tools.sh > "$W/c1.list"
    judge_split "$W/c1.list" "$W/c1.out" "$W/c1.tsv"; rc=$?
    if [ "$rc" -eq 0 ]; then vs_ctl_dead gone-touched "a wording of this gate's text marked gone did not fail the touched scan of this gate"; fail=1
    elif [ "$rc" = 1 ] && grep -qF "$EXPECT" "$W/c1.out"; then vs_ctl_fired gone-touched "the touched scan of tests/test_close_tools.sh FAILS the planted copy of $NEWEST: $(grep '^FILE' "$W/c1.out" | grep -F "$EXPECT" | head -1 | sed 's/^FILE [^ ]*: //' | cut -c1-120)"
    else vs_ctl_dead gone-touched "the touched scan exited $rc WITHOUT naming the planted wording: $(tail -1 "$W/c1.out" | cut -c1-120)"; fail=1; fi
    plant_gone "$W/c9.tsv"; echo "$W/c9.tsv" > "$W/c9.list"   # the pattern file CHANGED; the file carrying the wording NOT touched
    printf 'tests/test_close_tools.sh\ntests/lib/controls.sh\n' > "$W/c9.universe"   # the tree's stand-in: this gate and the library it sources, not in the list
    RETRACTION_GREP_UNIVERSE="$W/c9.universe"; export RETRACTION_GREP_UNIVERSE
    judge_split "$W/c9.list" "$W/c9.out" "$W/c9.tsv"; rc=$?
    unset RETRACTION_GREP_UNIVERSE
    if [ "$rc" -eq 0 ]; then vs_ctl_dead gone-new-untouched "a new gone wording in a changed pattern file, carried by an untouched file, did not fail"; fail=1
    elif [ "$rc" = 1 ] && grep -qF "$EXPECT" "$W/c9.out" && grep -q 'ONE scan over [0-9]* files (every tracked' "$W/c9.out"; then vs_ctl_fired gone-new-untouched "the CHANGED copy of $NEWEST gets the whole-tree scan (on a two-file stand-in for the tree, this gate among them, the list naming only the copy) and FAILS on a wording only the untouched gate carries: $(grep '^FILE' "$W/c9.out" | grep -F "$EXPECT" | head -1 | sed 's/^FILE [^ ]*: //' | cut -c1-110)"
    else vs_ctl_dead gone-new-untouched "the changed pattern file exited $rc WITHOUT a whole-tree FAIL naming the wording: $(tail -1 "$W/c9.out" | cut -c1-120)"; fail=1; fi
    if python3 tools/retraction_grep.py --selftest --nofold >"$W/c5.out" 2>&1; then vs_ctl_dead case-fold-dropped "the no-fold matcher passed the self-test — the upper-case plant is not what it catches"; fail=1
    elif grep -q '^SELFTEST FAIL:.*upper-case' "$W/c5.out"; then vs_ctl_fired case-fold-dropped "$(grep '^SELFTEST FAIL' "$W/c5.out" | cut -c1-120)"
    else vs_ctl_dead case-fold-dropped "the no-fold matcher exited non-zero WITHOUT its self-test FAIL line: $(tail -1 "$W/c5.out" | cut -c1-120)"; fail=1; fi
    if python3 tools/retraction_grep.py --selftest --nomarkup >"$W/c5m.out" 2>&1; then vs_ctl_dead markup-dropped "the no-markup matcher passed the self-test — the #242 plants are not what it catches"; fail=1
    elif grep -q '^SELFTEST FAIL:.*quote-wrapped' "$W/c5m.out"; then vs_ctl_fired markup-dropped "$(grep '^SELFTEST FAIL' "$W/c5m.out" | cut -c1-140)"
    else vs_ctl_dead markup-dropped "the no-markup matcher exited non-zero WITHOUT its self-test FAIL line: $(tail -1 "$W/c5m.out" | cut -c1-120)"; fail=1; fi
    if python3 tools/none_reasons.py --selftest --lenient >"$W/c6.out" 2>&1; then vs_ctl_dead bare-none-accepted "the lenient variant passed the self-test — the bare-none plant is not what it catches"; fail=1
    elif grep -q '^SELFTEST FAIL: want 1 got 0' "$W/c6.out"; then vs_ctl_fired bare-none-accepted "the lenient variant FAILS the self-test on the bare-none row ($(grep '^SELFTEST FAIL' "$W/c6.out" | cut -c1-60)) while the real tool passes it (section 2c)"
    else vs_ctl_dead bare-none-accepted "the lenient variant exited non-zero WITHOUT the self-test's own FAIL line: $(tail -1 "$W/c6.out" | cut -c1-120)"; fail=1; fi
    if python3 tools/homes_tracked.py --selftest --nobare >"$W/c7.out" 2>&1; then vs_ctl_dead bare-name-silent "the no-bare variant passed the self-test — the bare-name plant is not what it catches"; fail=1
    elif grep -q '^SELFTEST FAIL:.* bare=False' "$W/c7.out"; then vs_ctl_fired bare-name-silent "the no-bare variant FAILS the self-test on the bare names ($(grep '^SELFTEST FAIL' "$W/c7.out" | grep -o 'bare=False letters=[A-Za-z]*')) while the real tool passes it (section 2)"
    else vs_ctl_dead bare-name-silent "the no-bare variant exited non-zero WITHOUT the self-test's own FAIL line: $(tail -1 "$W/c7.out" | cut -c1-120)"; fail=1; fi
    if python3 tools/homes_tracked.py --selftest --noletters >"$W/c8.out" 2>&1; then vs_ctl_dead letter-unchecked "the no-letters variant passed the self-test — the per-letter plant is not what it catches"; fail=1
    elif grep -q '^SELFTEST FAIL:.* letters=False' "$W/c8.out"; then vs_ctl_fired letter-unchecked "the no-letters variant FAILS the self-test on the letters ($(grep '^SELFTEST FAIL' "$W/c8.out" | grep -o 'letters=False')) while the real tool passes it (section 2)"
    else vs_ctl_dead letter-unchecked "the no-letters variant exited non-zero WITHOUT the self-test's own FAIL line: $(tail -1 "$W/c8.out" | cut -c1-120)"; fail=1; fi
    if python3 tools/homes_tracked.py --selftest --blind >"$W/c2.out" 2>&1; then vs_ctl_dead build-home-planted "the BLIND variant passed the self-test — the plant is not what the self-test catches"; fail=1
    elif grep -q '^SELFTEST FAIL: (False, False' "$W/c2.out"; then vs_ctl_fired build-home-planted "the blind variant FAILS the self-test on the two build/ reads ($(grep '^SELFTEST FAIL' "$W/c2.out" | cut -c1-60)) while the real tool passes it (section 2)"
    else vs_ctl_dead build-home-planted "the blind variant exited non-zero WITHOUT the self-test's own FAIL line: $(tail -1 "$W/c2.out" | cut -c1-120)"; fail=1; fi
fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
