#!/bin/sh
# test_control_classifier.sh — THE CONTROL CLASSIFIER'S RULES ON KNOWN ANSWERS: #310's (14z-213) and #369's (14z-224). ci_portable: no ROM, ~1 s.
#
# WHAT: tests/lib/classify.sh `vs_classify_control` (one copy, read by both runners) reads a CONTROL= mode run that
#   FAILs WITHOUT having judged its perturbation as not honoured — #310's shapes 1-4 (ruled 2026-10-30, 14z-213:
#   "Classifier rules 1-4 (Recommended)"): (1) the gate's own `CONTROL DEAD: <this control>` then a non-zero exit ->
#   LIES; (2) a SKIP with a non-zero exit and no FAIL line -> UNJUDGED; (3) the gate's own refusal, a `REFUSED:` line
#   with exit 3 -> UNJUDGED; (4) a crash it could not see: a traceback indented by `sed 's/^/  /'`, or a shell abort
#   naming a tests/lib file -> DIED. And #369 (ruled 2026-11-08, "A1, B1, c1"): a mode is HONOURED only on its own
#   `CONTROL CAUGHT: <name> — ` line; without one a FAIL is UNJUDGED, unless the gate is on the shrink-only debt list
#   tests/expected/ctl_caught_debt.tsv, which keeps the old fall-through (a copy of a listed gate is listed: by basename).
# HOW: synthetic mode logs fed to vs_classify_control directly ([VSP-19]: the verdict logic on ground truth). #310's rules
#   on a debt-listed stub gate (the path they were written for), each with a case it must catch and a near miss it must
#   leave HONOURED (another control's DEAD line; a tool's REFUSED quoted in an exit-1 FAIL; a SKIP beside a FAIL; the word
#   Traceback in prose; a child script's own abort); #369's on an unlisted stub: no CAUGHT, another mode's, its own, its
#   own with exit 0, beside a traceback, beside NOT JUDGED, indented, a longer name, no name, beside its own DEAD, no gate.
#   The debt list is a scratch one ($W/fake/tests/expected/ctl_caught_debt.tsv, through REPO), never the tracked file.
# EXPECTS: every case its class; each control's disabled rule misreads its case.
#
# MUST-FIRE: shadow-tool: own-dead-honoured — a copy of tests/lib/classify.sh whose rule-1 branch is disabled must read the own-DEAD case HONOURED, and the gate must FAIL (mode: that copy is the classifier under test; the gate FAILs)
# MUST-FIRE: shadow-tool: skip-honoured — a copy whose rule-2 branch is disabled must read the SKIP-exit case HONOURED, and the gate must FAIL (mode: as above)
# MUST-FIRE: shadow-tool: refused-honoured — a copy whose rule-3 branch is disabled must read the exit-3 refusal HONOURED, and the gate must FAIL (mode: as above)
# MUST-FIRE: shadow-tool: lib-abort-honoured — a copy whose rule-4 library-abort branch is disabled must read the tests/lib abort HONOURED, and the gate must FAIL (mode: as above)
# MUST-FIRE: shadow-tool: fallthrough-honoured — a copy whose #369 no-positive-evidence branch is disabled (the pre-#369 fall-through, HONOURED on any FAIL) must read the no-CAUGHT case HONOURED, and the gate must FAIL (mode: as above)
#
# WHY: #310 (14z-206): a mode run that FAILs for any reason but its perturbation read HONOURED; the 14z-210 census found
#   939 of 957 controls with such a path. Measured 14z-213 on #299's 14z-206 legs (413 honoured controls each): rules 1-4
#   move exactly five rows, and the three gates behind them (test_bundle_parsers, test_df_startup_provenance,
#   test_defense_rows_census) were fixed in the same change: two modes had tested nothing (build/agent213/t310/).
#   #369 (14z-223 post-mortem): listing the wrong answers never finished; a mode now needs its own check's evidence.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_control_classifier — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
: > "$W/main.log"
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*" | tee -a "$W/main.log"; fail=1; }
mkdir -p "$W/fake/tests/expected" "$W/copy"; printf '# scratch debt list\ng_debt.sh\n' > "$W/fake/tests/expected/ctl_caught_debt.tsv"

# the classifier under test: the real one, or a mode's copy with one rule disabled
CLS="$REPO/tests/lib/classify.sh"
shadow() {  # shadow <rule marker> <out>
    sed "s@^\(        elif \).*$1.*\$@\1false; then   # disabled by test_control_classifier@" "$CLS" > "$2"
    cmp -s "$CLS" "$2" && { echo "FAIL: test_control_classifier — could not disable '$1' (the line moved)"; exit 1; }
}
WANT=""   # each mode's own finding: the case its disabled rule misreads
case "${VS_CTL:-}" in
own-dead-honoured)    shadow '#310 rule 1' "$W/cls.sh"; CLS="$W/cls.sh"; WANT="FAIL  rule 1: its own CONTROL DEAD, exit 1 -> HONOURED" ;;
skip-honoured)        shadow '#310 rule 2' "$W/cls.sh"; CLS="$W/cls.sh"; WANT="FAIL  rule 2: a SKIP with exit 77, no FAIL -> HONOURED" ;;
refused-honoured)     shadow '#310 rule 3' "$W/cls.sh"; CLS="$W/cls.sh"; WANT="FAIL  rule 3: the gate's own REFUSED, exit 3 -> HONOURED" ;;
lib-abort-honoured)   shadow "#310 rule 4: a shared library" "$W/cls.sh"; CLS="$W/cls.sh"; WANT="FAIL  rule 4: a shell abort naming a tests/lib file -> HONOURED" ;;
fallthrough-honoured) shadow '#369 no positive evidence' "$W/cls.sh"; CLS="$W/cls.sh"; WANT="FAIL  #369: no CAUGHT line, off the debt list -> HONOURED" ;;
esac

classify() {  # classify <classifier> <exit> <log> <gate> <control name>: prints VERDICT|DETAIL
    REPO="$W/fake" sh -c '. "$1"; vs_classify_control "$2" "$3" "$4" "$5"; echo "$VS_CTL_EXEC|$VS_CTL_EXEC_DETAIL"' _ "$1" "$2" "$3" "$4" "$5"
}
case_() {  # case_ <label> <gate> <exit> <control name> <expected class> <log text (printf format)>
    printf "$6" > "$W/log"
    out="$(classify "$CLS" "$3" "$W/log" "$2" "$4")"
    [ "${out%%|*}" = "$5" ] && ok "$1 -> $5" || bad "$1 -> ${out%%|*}, expected $5 (${out#*|})"
}
D=tests/g_debt.sh; U=tests/g_x.sh
echo "== #310's rules on known answers (a debt-listed gate: the old fall-through)"
case_ "rule 1: its own CONTROL DEAD, exit 1"            $D 1 flip LIES     'CONTROL MODE: flip\nCONTROL DEAD: flip — the plant changed nothing\nFAIL: g_x\n'
case_ "  near miss: ANOTHER control's DEAD, exit 1"      $D 1 flip HONOURED '  FAIL  caught\nCONTROL DEAD: other — not mine\nFAIL: g_x\n'
case_ "rule 2: a SKIP with exit 77, no FAIL"            $D 77 flip UNJUDGED 'SKIP: no MiSTer core on this host\n'
case_ "  near miss: a SKIP line beside a FAIL"           $D 1 flip HONOURED '  SKIP  one leg\n  FAIL  caught\nFAIL: g_x\n'
case_ "rule 3: the gate's own REFUSED, exit 3"           $D 3 flip UNJUDGED 'REFUSED: mode flip — its perturbation did not make its own clause fail\n'
case_ "  near miss: a tool's REFUSED in an exit-1 FAIL"  $D 1 flip HONOURED 'REFUSED: this message would close the issue\nCONTROL FIRED: flip — caught\nFAIL: g_x\n'
case_ "rule 4: an indented traceback"                    $D 1 flip DIED     '  Traceback (most recent call last):\n    File "x.py", line 3\n  ValueError: bad\nFAIL: g_x\n'
case_ "  near miss: the word Traceback in prose"         $D 1 flip HONOURED '  FAIL  no Traceback expected here, got a diff\nFAIL: g_x\n'
case_ "rule 4: a shell abort naming a tests/lib file"    $D 1 flip DIED     'tests/lib/decrypt_cache.sh: line 66: ROMDIR: parameter not set\nFAIL: g_x\n'
case_ "  near miss: a FAIL quoting a lib path"           $D 1 flip HONOURED '  FAIL  tests/lib/decrypt_cache.sh refused the copy, as planted\nFAIL: g_x\n'
case_ "before #310's rules: NOT JUDGED"                  $D 1 flip UNJUDGED 'NOT JUDGED: the browser run did not complete\nFAIL: g_x\n'
case_ "before #310's rules: a plain FAIL"                $D 1 flip HONOURED '  FAIL  caught\nFAIL: g_x\n'
echo "== #369: honoured only on its own CONTROL CAUGHT line (a gate off the debt list)"
case_ "#369: no CAUGHT line, off the debt list"          $U 1 flip UNJUDGED '  FAIL  caught\nFAIL: g_x\n'
case_ "#369: another mode's CAUGHT"                      $U 1 flip UNJUDGED 'CONTROL CAUGHT: other — FAIL  [E1] row 3\nFAIL: g_x\n'
case_ "#369: its own CAUGHT"                             $U 1 flip HONOURED '  FAIL  [E1] row 3\nCONTROL CAUGHT: flip — FAIL  [E1] row 3\nFAIL: g_x\n'
case_ "#369: exit 0 with its own CAUGHT"                 $U 0 flip LIES     'CONTROL CAUGHT: flip — FAIL  [E1] row 3\nPASS: g_x\n'
case_ "#369: its own CAUGHT beside a traceback"          $U 1 flip DIED     'Traceback (most recent call last):\n  File "x.py", line 3\nValueError: bad\nCONTROL CAUGHT: flip — x\nFAIL: g_x\n'
case_ "#369: its own CAUGHT beside NOT JUDGED"           $U 1 flip UNJUDGED 'NOT JUDGED: under control mode flip, the leg wrote nothing\nCONTROL CAUGHT: flip — x\nFAIL: g_x\n'
case_ "#369: its own CAUGHT beside its own DEAD"         $U 1 flip LIES     'CONTROL DEAD: flip — the plant changed nothing\nCONTROL CAUGHT: flip — x\nFAIL: g_x\n'
case_ "#369: an indented CAUGHT line is prose"           $U 1 flip UNJUDGED '  CONTROL CAUGHT: flip — x\nFAIL: g_x\n'
case_ "#369: a longer name's CAUGHT is not its own"      $U 1 flip UNJUDGED 'CONTROL CAUGHT: flip-2 — x\nFAIL: g_x\n'
case_ "#369: no control name given"                      $U 1 ""   UNJUDGED 'CONTROL CAUGHT: flip — x\nFAIL: g_x\n'
case_ "#369: no gate given (a runner with its reader unplugged)" "" 1 flip UNJUDGED '  FAIL  caught\nFAIL: g_x\n'
case_ "#369: a COPY of a listed gate is listed"          "$W/copy/g_debt.sh" 1 flip HONOURED '  FAIL  caught\nFAIL: g_x\n'

if [ -n "${VS_CTL:-}" ]; then
    if [ "$fail" = 0 ]; then echo "PASS: test_control_classifier (control mode $VS_CTL changed no verdict)"; exit 0; fi
    vs_ctl_caught "$W/main.log" "$WANT"
    echo "FAIL: test_control_classifier (control mode $VS_CTL)"; exit 1
fi
echo "== controls: each rule disabled must misread its case"
fire() {  # fire <control> <rule marker> <gate> <exit> <name> <log>
    shadow "$2" "$W/s.sh"; printf "$6" > "$W/log"
    got="$(classify "$W/s.sh" "$4" "$W/log" "$3" "$5")"; got="${got%%|*}"
    [ "$got" = HONOURED ] && vs_ctl_fired "$1" "with the rule disabled the case reads HONOURED" || { vs_ctl_dead "$1" "the disabled copy read '$got'"; fail=1; }
}
fire own-dead-honoured    '#310 rule 1' $D 1 flip 'CONTROL DEAD: flip — the plant changed nothing\nFAIL: g_x\n'
fire skip-honoured        '#310 rule 2' $D 77 flip 'SKIP: no MiSTer core on this host\n'
fire refused-honoured     '#310 rule 3' $D 3 flip 'REFUSED: mode flip — its perturbation did not make its own clause fail\n'
fire lib-abort-honoured   "#310 rule 4: a shared library" $D 1 flip 'tests/lib/decrypt_cache.sh: line 66: ROMDIR: parameter not set\nFAIL: g_x\n'
fire fallthrough-honoured '#369 no positive evidence' $U 1 flip '  FAIL  caught\nFAIL: g_x\n'

[ "$fail" = 0 ] && echo "PASS: test_control_classifier — #310's rules 1-4 and #369's positive-evidence rule read their known answers and leave every near miss honoured" || echo "FAIL: test_control_classifier"
exit "$fail"
