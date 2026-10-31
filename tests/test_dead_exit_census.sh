#!/bin/sh
# test_dead_exit_census.sh — NO CONTROL MODE'S DEAD BRANCH IS PRINTED IN WORDS ONLY (#310 group 2, 14z-215). ci_portable: no ROM, ~2 s.
#
# WHAT: no tests/*.sh closes a control mode whose perturbation changed no verdict with words and `exit 1` ("control
#   mode X left the gate green", "the planted escape passed"): such a run reads HONOURED under tests/lib/classify.sh,
#   a control that tested nothing certified as caught. The dead branch must print `CONTROL DEAD: <mode> — …`
#   (tests/lib/controls.sh vs_ctl_dead / vs_ctl_left_green), which classify.sh's rule 1 reads LIES.
# HOW: tools/dead_exit_census.py reads every tests/*.sh for the copied block's shapes (P1: an echo-exit straight after a
#   fired branch; P2: an echo-exit naming the mode and a dead word; P3: the inverted block, a braced echo-exit on a green
#   rc) and names each unmarked one; the reviewed exceptions below (ALLOW) are lines the scan matches that no mode
#   reaches. Beside it, four stub gates run under CONTROL=flip and classified as both runners do show what the scan is
#   for: the word-only block reads HONOURED (and is named), its vs_ctl_left_green form reads LIES (and is not), the
#   inverted block reads HONOURED (and is named).
#   SINCE #310 GROUP 6 (14z-215; the maintainer, 2026-10-31: "... and two new dead-exit patterns") the scan also names
#   two mode exits that read HONOURED when the mode tested nothing (printed DEADEXIT): P4, an UNCONDITIONAL mode exit at
#   the script's top level (`if vs_ctl_is X; then echo "FAIL…"; exit 1; fi`, its `&& { … }` and multi-line forms),
#   which exits 1 whether or not the mode's own finding fired; P5, `|| exit 3` (or a braced echo-exit 3) on a line with
#   no `REFUSED` — classify.sh's rule 3 reads exit 3 as UNJUDGED only beside a `REFUSED: ` line. Their stubs under
#   CONTROL=flip: the unconditional exit reads HONOURED (and is named), its form conditional on the finding with
#   vs_ctl_left_green reads LIES (and is not); the bare `|| exit 3` reads HONOURED (and is named), its REFUSED form
#   reads UNJUDGED (and is not).
# EXPECTS: zero unallowed word-only or mode exits; every ALLOW line still present; every stub its class and its naming.
# NOT COVERED (known gaps, each held by a plant the gate FAILs on if it is ever named, so this text is updated): a
#   dead branch phrased another way — its message printed with printf, its `exit 1` on a line of its own
#   (`stub_gap.sh`); a mode's `exit 3` with no REFUSED reached through a `case` arm (`*) echo "no such perturbation";
#   exit 3 ;;`, `stub_gap_case.sh` — ten gates carry that default arm, reachable only by a declared mode their perturb
#   does not handle) or through a function; and an unconditional mode exit INDENTED inside a loop or a function
#   (`stub_gap_indented.sh`; an indented one usually sits in the branch that tested the finding, test_wide_profile's
#   and audit_marionette_cost's do). Each reads HONOURED and is not named. The scan is a tripwire for the copied
#   shapes, not a proof that none remains.
# FOLLOWS: tools/dead_exit_census.py tests/lib/classify.sh tests/lib/controls.sh
#
# MUST-FIRE: known-bad: planted-word-only — a stub gate with the drift family's old close block (`echo "… control mode $VS_CTL left the gate green"; exit 1`) read with the tree must be named, and the gate must FAIL (mode: the census reads that stub with the tree)
# MUST-FIRE: known-bad: planted-inverted — a stub gate with the inverted block (`[ "$rc" -eq 0 ] && { echo "FAIL: the planted flip passed"; exit 1; }`) read with the tree must be named, and the gate must FAIL (mode: as above)
# MUST-FIRE: known-bad: planted-unconditional — a stub gate whose mode exits 1 on the mode alone (`if vs_ctl_is flip; then echo "FAIL: …"; exit 1; fi`, #310 group 6 P4) read with the tree must be named, and the gate must FAIL (mode: as above)
# MUST-FIRE: known-bad: planted-unrefused — a stub gate whose plant-failure path is a bare `plant || exit 3` (#310 group 6 P5) read with the tree must be named, and the gate must FAIL (mode: as above)
#
# WHY: #310 (the 14z-210 census; REMAINING section 1 shape 1): 42 gates, about 89 controls, printed their dead branch
#   in words; groups 1-2 (ruled 2026-10-31, maintainer: "Groups 1-4, then re-census 5-7") moved every one to
#   vs_ctl_left_green, and this scan's first run found two more in the inverted shape (test_charid_names,
#   test_module_refs, four controls). Without the census a new gate copying the old block brings the false honour back.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_dead_exit_census — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

# ALLOW: <path>|<the matched line, exactly>|<why no mode reaches it> — reviewed exceptions, each re-found on every run
ALLOW='tests/audit_marionette_cost.sh|echo "FAIL: audit_marionette_cost"; exit 1|the plain run'"'"'s FAIL: the line above it exits under every mode
tests/test_controls_contract.sh|if vs_ctl_is flip; then echo "FAIL: flipped"; exit 1; fi|a heredoc body: section 5'"'"'s stub g6.sh, whose flipped mode IS the fail, not a mode of this gate'

# THE STUBS: one mode, `flip`, whose perturbation changes nothing (fail stays 0). Their bodies spell the exit @X@ and
# stub() writes `exit 1`, so the census reading THIS file does not name its own plants.
stub() {  # stub <name> <the mode block's body>
    { echo '#!/bin/sh'; echo "# $1 — a stub gate (tests/test_dead_exit_census.sh)"; echo '# MUST-FIRE: known-bad: flip — stub'
      echo 'set -u'; echo '. "$CTLS"; vs_ctl_mode "$0"'; echo 'fail=0; rc=0'; echo 'if vs_ctl_is flip; then'
      printf '%s\n' "$2" | sed 's/@X@/exit 1/g'; echo 'fi'; echo 'echo "PASS: stub"'; } > "$W/$1"
}
stub stub_wordonly.sh '    [ "$fail" = 1 ] && { echo "FAIL: stub (control mode: $VS_CTL)"; @X@; }
    echo "FAIL: stub — control mode $VS_CTL left the gate green"; @X@'
stub stub_fixed.sh '    [ "$fail" = 1 ] && { echo "FAIL: stub (control mode: $VS_CTL)"; @X@; }
    vs_ctl_left_green "$VS_CTL" "FAIL: stub — control mode $VS_CTL left the gate green"'
stub stub_inverted.sh '    [ "$rc" -eq 0 ] && { echo "FAIL: the planted flip passed"; @X@; }
    echo "FAIL (mode): as required — the flip was reported"; @X@'
stub stub_gap.sh '    if [ "$fail" -ne 0 ]; then echo "FAIL: stub (control mode)"; @X@; fi
    printf "%s\n" "FAIL: stub — the flip changed nothing"
    @X@'
# P4 / P5 (#310 group 6): stubraw writes the body at the script's top level, with no wrapping `if`; @X3@ spells `exit 3`
stubraw() {  # stubraw <name> <body>
    { echo '#!/bin/sh'; echo "# $1 — a stub gate (tests/test_dead_exit_census.sh)"; echo '# MUST-FIRE: known-bad: flip — stub'
      echo 'set -u'; echo '. "$CTLS"; vs_ctl_mode "$0"'; echo 'fail=0'
      echo 'plant() { echo "the line the plant replaces was not found" >&2; return 1; }'
      printf '%s\n' "$2" | sed -e 's/@X@/exit 1/g' -e 's/@X3@/exit 3/g'; echo 'echo "PASS: stub"'; } > "$W/$1"
}
stubraw stub_uncond.sh 'if vs_ctl_is flip; then echo "FAIL: stub (control mode: $VS_CTL)"; @X@; fi'
stubraw stub_uncond_fixed.sh 'if vs_ctl_is flip; then [ "$fail" = 1 ] && { echo "FAIL: stub (control mode)"; @X@; }; vs_ctl_left_green flip "FAIL: stub — control mode flip left the gate green"; fi'
stubraw stub_unrefused.sh 'if vs_ctl_is flip; then plant || @X3@; fi'
stubraw stub_unrefused_fixed.sh 'if vs_ctl_is flip; then plant || { echo "REFUSED: flip — the plant did not apply: the mode judged nothing"; @X3@; }; fi'
stubraw stub_gap_case.sh 'perturb() { case "$1" in other) : ;; *) echo "no such perturbation: $1"; @X3@ ;; esac; }
if vs_ctl_is flip; then perturb flip; fi'
stubraw stub_gap_indented.sh 'for _x in 1; do
    vs_ctl_is flip && { echo "FAIL: stub (control mode)"; @X@; }
done'

census() {  # census [extra files...]: the tool's WORDONLY lines minus ALLOW, to stdout; the allowed ones to $W/allowed
    python3 tools/dead_exit_census.py "$@" > "$W/raw.txt" 2>&1; _crc=$?
    : > "$W/allowed"
    while IFS= read -r _h; do
        case "$_h" in WORDONLY*|DEADEXIT*) ;; *) continue ;; esac
        _p="${_h#* }"; _p="${_p%%:*}"; _t="${_h#*] }"; _hit=0
        _old="$IFS"; IFS='
'
        for _a in $ALLOW; do [ "${_a%%|*}" = "$_p" ] && _r="${_a#*|}" && [ "${_r%%|*}" = "$_t" ] && _hit=1; done
        IFS="$_old"
        [ "$_hit" = 1 ] && echo "$_h" >> "$W/allowed" || echo "$_h"
    done < "$W/raw.txt"
    [ "$_crc" = 0 ] || [ "$_crc" = 1 ] || echo "TOOLERROR exit $_crc: $(tail -1 "$W/raw.txt")"
}

EXTRA=""
vs_ctl_is planted-word-only && EXTRA="$W/stub_wordonly.sh"
vs_ctl_is planted-inverted && EXTRA="$W/stub_inverted.sh"
vs_ctl_is planted-unconditional && EXTRA="$W/stub_uncond.sh"
vs_ctl_is planted-unrefused && EXTRA="$W/stub_unrefused.sh"
echo "== 1. every tests/*.sh: no control mode's dead branch in words only, no unconditional or unrefused mode exit"
# shellcheck disable=SC2086
census $EXTRA > "$W/hits.txt"
tail -1 "$W/raw.txt" | sed 's/^/  /'
if [ -s "$W/hits.txt" ]; then bad "$(wc -l < "$W/hits.txt" | tr -d ' ') dead exit(s): WORDONLY prints CONTROL DEAD (vs_ctl_left_green / vs_ctl_dead); DEADEXIT P4 exits on the mode's own finding, P5 says REFUSED:"; sed 's/^/        /' "$W/hits.txt"
else ok "no unallowed word-only dead exit and no unconditional or unrefused mode exit ($(wc -l < "$W/allowed" | tr -d ' ') reviewed exception(s))"; fi
_old="$IFS"; IFS='
'
for _a in $ALLOW; do
    _p="${_a%%|*}"; _r="${_a#*|}"; _t="${_r%%|*}"
    command grep -qF "$_t" "$W/allowed" || bad "ALLOW is stale: $_p no longer carries a matched line '$_t'"
done
IFS="$_old"
if [ -n "${VS_CTL:-}" ]; then
    [ "$fail" = 1 ] && { echo "FAIL: test_dead_exit_census (control mode $VS_CTL: the planted stub was named)"; exit 1; }
    vs_ctl_left_green "$VS_CTL" "FAIL: test_dead_exit_census — control mode $VS_CTL: the planted stub was not named"
fi

echo "== 2. what the census is for: the stubs under CONTROL=flip, classified as the runners do"
classify() {  # classify <stub>: runs it under CONTROL=flip; sets CL (vs_classify_control) and NAMED (1 if the census names it)
    env CONTROL=flip CTLS="$REPO/tests/lib/controls.sh" sh "$W/$1" > "$W/$1.log" 2>&1 </dev/null && _s=0 || _s=$?
    CL="$(sh -c '. "$1"; vs_classify_control "$2" "$3" "$4" flip; echo "$VS_CTL_EXEC"' _ "$REPO/tests/lib/classify.sh" "$_s" "$W/$1.log" "$W/$1")"
    python3 tools/dead_exit_census.py "$W/$1" > "$W/$1.census" 2>&1; NAMED=0; command grep -qE "^(WORDONLY|DEADEXIT) $W/$1:" "$W/$1.census" && NAMED=1
}
classify stub_wordonly.sh
[ "$CL" = HONOURED ] && [ "$NAMED" = 1 ] && ok "the word-only block reads HONOURED (the false honour) and the census names it" \
    || bad "the word-only block read $CL, named=$NAMED (want HONOURED, named)"
classify stub_fixed.sh
[ "$CL" = LIES ] && [ "$NAMED" = 0 ] && ok "its vs_ctl_left_green form (prints 'left the gate green', exit 1) reads LIES and is not named" \
    || bad "the vs_ctl_left_green form read $CL, named=$NAMED (want LIES, not named)"
classify stub_inverted.sh
[ "$CL" = HONOURED ] && [ "$NAMED" = 1 ] && ok "the inverted block reads HONOURED and the census names it" \
    || bad "the inverted block read $CL, named=$NAMED (want HONOURED, named)"
classify stub_gap.sh
if [ "$NAMED" = 0 ]; then echo "  note  NOT COVERED (known gap): a dead branch printed with printf and exiting on its own line reads $CL and is not named"
else bad "the known-gap plant is now named: update the header's NOT COVERED and keep a plant the scan cannot see"; fi
classify stub_uncond.sh
[ "$CL" = HONOURED ] && [ "$NAMED" = 1 ] && ok "P4: the unconditional mode exit reads HONOURED (the false honour) and the census names it" \
    || bad "the unconditional mode exit read $CL, named=$NAMED (want HONOURED, named)"
classify stub_uncond_fixed.sh
[ "$CL" = LIES ] && [ "$NAMED" = 0 ] && ok "P4: its form conditional on the finding (vs_ctl_left_green when not) reads LIES and is not named" \
    || bad "the conditional mode exit read $CL, named=$NAMED (want LIES, not named)"
classify stub_unrefused.sh
[ "$CL" = HONOURED ] && [ "$NAMED" = 1 ] && ok "P5: a plant failure closed by a bare exit 3 reads HONOURED (the false honour) and the census names it" \
    || bad "the bare exit 3 read $CL, named=$NAMED (want HONOURED, named)"
classify stub_unrefused_fixed.sh
[ "$CL" = UNJUDGED ] && [ "$NAMED" = 0 ] && ok "P5: its REFUSED form reads UNJUDGED and is not named" \
    || bad "the REFUSED exit 3 read $CL, named=$NAMED (want UNJUDGED, not named)"
for _gp in stub_gap_case.sh stub_gap_indented.sh; do
    classify "$_gp"
    if [ "$NAMED" = 0 ]; then echo "  note  NOT COVERED (known gap): $_gp reads $CL and is not named"
    else bad "the known-gap plant $_gp is now named: update the header's NOT COVERED and keep a plant the scan cannot see"; fi
done

echo "== 3. controls"
for c in planted-word-only:stub_wordonly.sh planted-inverted:stub_inverted.sh planted-unconditional:stub_uncond.sh planted-unrefused:stub_unrefused.sh; do
    n="${c%%:*}"; f="${c#*:}"
    census "$W/$f" > "$W/c_$n.txt"
    if command grep -qE "^(WORDONLY|DEADEXIT) $W/$f:" "$W/c_$n.txt"; then vs_ctl_fired "$n" "the census names $(command grep -m1 -E "^(WORDONLY|DEADEXIT) $W/$f:" "$W/c_$n.txt" | sed "s|$W/||" | cut -c10-120)"
    else vs_ctl_dead "$n" "the census read $f with the tree and named nothing" || fail=1; fi
done

[ "$fail" = 0 ] && echo "PASS: test_dead_exit_census — no control mode's dead branch is printed in words only, and no mode exits unconditionally or refuses without REFUSED (the known gaps stated)" || echo "FAIL: test_dead_exit_census"
exit "$fail"
