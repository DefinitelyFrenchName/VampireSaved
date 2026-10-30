#!/bin/sh
# test_control_classifier.sh — THE CONTROL CLASSIFIER'S #310 RULES ON KNOWN ANSWERS (14z-213). ci_portable: no ROM, ~1 s.
#
# WHAT: tests/lib/classify.sh `vs_classify_control` (one copy, read by both runners) reads a CONTROL= mode run that
#   FAILs WITHOUT having judged its perturbation as not honoured — #310's shapes 1-4 (ruled 2026-10-30, 14z-213:
#   "Classifier rules 1-4 (Recommended)"): (1) the gate's own `CONTROL DEAD: <this control>` then a non-zero exit ->
#   LIES; (2) a SKIP with a non-zero exit and no FAIL line -> UNJUDGED; (3) the gate's own refusal, a `REFUSED:` line
#   with exit 3 -> UNJUDGED; (4) a crash it could not see: a traceback indented by `sed 's/^/  /'`, or a shell abort
#   naming a tests/lib file -> DIED.
# HOW: synthetic mode logs fed to vs_classify_control directly ([VSP-19]: the verdict logic on ground truth), each rule
#   with a case it must catch and a near miss it must leave HONOURED (another control's DEAD line; a tool's REFUSED quoted
#   in an exit-1 FAIL; a SKIP beside a FAIL; the word Traceback in prose; a child script's own abort), plus the classes
#   that were there before (#310's NOT JUDGED, a plain FAIL).
# EXPECTS: every case its class; each control's disabled rule misreads its case.
#
# MUST-FIRE: shadow-tool: own-dead-honoured — a copy of tests/lib/classify.sh whose rule-1 branch is disabled must read the own-DEAD case HONOURED, and the gate must FAIL (mode: that copy is the classifier under test; the gate FAILs)
# MUST-FIRE: shadow-tool: skip-honoured — a copy whose rule-2 branch is disabled must read the SKIP-exit case HONOURED, and the gate must FAIL (mode: as above)
# MUST-FIRE: shadow-tool: refused-honoured — a copy whose rule-3 branch is disabled must read the exit-3 refusal HONOURED, and the gate must FAIL (mode: as above)
# MUST-FIRE: shadow-tool: lib-abort-honoured — a copy whose rule-4 library-abort branch is disabled must read the tests/lib abort HONOURED, and the gate must FAIL (mode: as above)
#
# WHY: #310 (14z-206): a mode run that FAILs for any reason but its perturbation read HONOURED; the 14z-210 census found
#   939 of 957 controls with such a path. Measured 14z-213 on #299's 14z-206 legs (413 honoured controls each): rules 1-4
#   move exactly five rows, and the three gates behind them (test_bundle_parsers, test_df_startup_provenance,
#   test_defense_rows_census) were fixed in the same change: two modes had tested nothing (build/agent213/t310/).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_control_classifier — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

# the classifier under test: the real one, or a mode's copy with one #310 rule disabled
CLS="$REPO/tests/lib/classify.sh"
shadow() {  # shadow <rule marker> <out>
    sed "s@^\(        elif \).*$1.*\$@\1false; then   # disabled by test_control_classifier@" "$CLS" > "$2"
    cmp -s "$CLS" "$2" && { echo "FAIL: test_control_classifier — could not disable '$1' (the line moved)"; exit 1; }
}
case "${VS_CTL:-}" in
own-dead-honoured)  shadow '#310 rule 1' "$W/cls.sh"; CLS="$W/cls.sh" ;;
skip-honoured)      shadow '#310 rule 2' "$W/cls.sh"; CLS="$W/cls.sh" ;;
refused-honoured)   shadow '#310 rule 3' "$W/cls.sh"; CLS="$W/cls.sh" ;;
lib-abort-honoured) shadow "#310 rule 4: a shared library" "$W/cls.sh"; CLS="$W/cls.sh" ;;
esac

case_() {  # case_ <label> <exit> <control name> <expected class> <log text (printf format)>
    printf "$5" > "$W/log"
    out="$(sh -c '. "$1"; vs_classify_control "$2" "$3" tests/g_x.sh "$4"; echo "$VS_CTL_EXEC|$VS_CTL_EXEC_DETAIL"' _ "$CLS" "$2" "$W/log" "$3")"
    [ "${out%%|*}" = "$4" ] && ok "$1 -> $4" || bad "$1 -> ${out%%|*}, expected $4 (${out#*|})"
}
echo "== #310's rules on known answers"
case_ "rule 1: its own CONTROL DEAD, exit 1"            1 flip LIES     'CONTROL MODE: flip\nCONTROL DEAD: flip — the plant changed nothing\nFAIL: g_x\n'
case_ "  near miss: ANOTHER control's DEAD, exit 1"      1 flip HONOURED '  FAIL  caught\nCONTROL DEAD: other — not mine\nFAIL: g_x\n'
case_ "rule 2: a SKIP with exit 77, no FAIL"            77 flip UNJUDGED 'SKIP: no MiSTer core on this host\n'
case_ "  near miss: a SKIP line beside a FAIL"           1 flip HONOURED '  SKIP  one leg\n  FAIL  caught\nFAIL: g_x\n'
case_ "rule 3: the gate's own REFUSED, exit 3"           3 flip UNJUDGED 'REFUSED: mode flip — its perturbation did not make its own clause fail\n'
case_ "  near miss: a tool's REFUSED in an exit-1 FAIL"  1 flip HONOURED 'REFUSED: this message would close the issue\nCONTROL FIRED: flip — caught\nFAIL: g_x\n'
case_ "rule 4: an indented traceback"                    1 flip DIED     '  Traceback (most recent call last):\n    File "x.py", line 3\n  ValueError: bad\nFAIL: g_x\n'
case_ "  near miss: the word Traceback in prose"         1 flip HONOURED '  FAIL  no Traceback expected here, got a diff\nFAIL: g_x\n'
case_ "rule 4: a shell abort naming a tests/lib file"    1 flip DIED     'tests/lib/decrypt_cache.sh: line 66: ROMDIR: parameter not set\nFAIL: g_x\n'
case_ "  near miss: a FAIL quoting a lib path"           1 flip HONOURED '  FAIL  tests/lib/decrypt_cache.sh refused the copy, as planted\nFAIL: g_x\n'
case_ "before #310's rules: NOT JUDGED"                  1 flip UNJUDGED 'NOT JUDGED: the browser run did not complete\nFAIL: g_x\n'
case_ "before #310's rules: a plain FAIL"                1 flip HONOURED '  FAIL  caught\nFAIL: g_x\n'

if [ -n "${VS_CTL:-}" ]; then
    [ "$fail" = 0 ] && echo "PASS: test_control_classifier" || echo "FAIL: test_control_classifier (control mode $VS_CTL)"; exit "$fail"
fi
echo "== controls: each rule disabled must misread its case"
fire() {  # fire <control> <rule marker> <exit> <name> <log>
    shadow "$2" "$W/s.sh"; printf "$5" > "$W/log"
    got="$(sh -c '. "$1"; vs_classify_control "$2" "$3" tests/g_x.sh "$4"; echo "$VS_CTL_EXEC"' _ "$W/s.sh" "$3" "$W/log" "$4")"
    [ "$got" = HONOURED ] && vs_ctl_fired "$1" "with the rule disabled the case reads HONOURED" || { vs_ctl_dead "$1" "the disabled copy read '$got'"; fail=1; }
}
fire own-dead-honoured  '#310 rule 1' 1 flip 'CONTROL DEAD: flip — the plant changed nothing\nFAIL: g_x\n'
fire skip-honoured      '#310 rule 2' 77 flip 'SKIP: no MiSTer core on this host\n'
fire refused-honoured   '#310 rule 3' 3 flip 'REFUSED: mode flip — its perturbation did not make its own clause fail\n'
fire lib-abort-honoured "#310 rule 4: a shared library" 1 flip 'tests/lib/decrypt_cache.sh: line 66: ROMDIR: parameter not set\nFAIL: g_x\n'

[ "$fail" = 0 ] && echo "PASS: test_control_classifier — #310's rules 1-4 read their known answers and leave every near miss honoured" || echo "FAIL: test_control_classifier"
exit "$fail"
