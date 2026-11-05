# controls.sh — THE MUST-FIRE CONTRACT'S READER, one copy, sourced by the
# classifier (tests/lib/classify.sh) and by every gate that declares a control.
# (14z-147, step two of the maintainer's ruling on the BBX finding — STATE
# "Decisions pending": "agreed with everything you just said".)
#
# THE GRAMMAR is BBX's R10 (docs/project/must_fire_contract.md is the copy of
# record in this tree). It is a COPY, never a dependency: "independent but
# compatible" (maintainer, 2026-09-08); since 14z-197 it evolves on its own (maintainer-ruled
# 2026-10-10: bbh is its own project; kept while it delivers value here). Four regexes, and the header is the
# LEADING COMMENT BLOCK — every `#` line after the shebang up to the first
# non-comment line; a bare `#` does NOT end it (BBX R30, 2026-09-10 — the
# STATE entry's "compatibility trap" about bare `#` separators is resolved by
# that ruling).
#
#   # MUST-FIRE: <shape>: <name> — <what must fail, and why that proves the gate can fail>
#       shape ∈ perturbed-copy | shadow-tool | known-bad ; name [a-z0-9-]+
#   # MUST-FIRE: none — <why this gate asserts no property>
#   CONTROL FIRED: <name> — <evidence>           (printed at run time, col 0)
#   CONTROL DEAD: <name> — <what happened>       (the verdict is FAIL, whatever else said)
#
# THE EXECUTABLE FORM (BBX R29; ours by agreement, STATE 14z-145 point 2): a
# declared name is also a MODE. `CONTROL=<name> tests/<gate>.sh` applies that
# control's perturbation to the gate's REAL input and runs to the gate's own
# verdict, which must be FAIL. A name the header does not declare is REFUSED
# (exit 3) — a runner reads that as a dead control.
#
# Functions (sh, no bashisms — the gates are #!/bin/sh):
#   vs_ctl_header <script>             the leading comment block, to stdout
#   vs_ctl_declared <script>           declared names, one per line
#   vs_ctl_none <script>               the `none` reason, or nothing
#   vs_ctl_mode <script>               honour $CONTROL: sets VS_CTL to the name
#                                      (or empty); REFUSES an undeclared name
#   vs_ctl_is <name>                   true when $VS_CTL is <name>
#   vs_ctl_fired <name> <evidence>     print the FIRED line
#   vs_ctl_dead <name> <what>          print the DEAD line (returns 1 so a
#                                      caller can `|| fail=1`)
#   vs_ctl_left_green <name> <line>    a mode run at the gate's green end: the
#                                      DEAD line, then <line>, then exit 1
#   vs_ctl_show_err <out> [<exc>|-] [<script>]
#                                      a perturbed copy's captured output: a
#                                      crash in it is re-printed so the run
#                                      reads DIED / UNJUDGED (returns 1), none
#                                      returns 0 silently
#   vs_ctl_nj <why>                    under a mode, a dead leg's NOT JUDGED
#                                      line (UNJUDGED); silent in a plain run
#   vs_ctl_read <script> <log>         declared vs fired for one run; sets
#                                      VS_CTL_DECLARED/FIRED/DEAD/UNDECLARED
#                                      (counts), VS_CTL_MISSING (names),
#                                      VS_CTL_VERDICT OK|RED|UNDECLARED|NONE,
#                                      VS_CTL_DETAIL
# Ground truth: tests/test_controls_contract.sh.

VS_CTL_SHAPES='perturbed-copy|shadow-tool|known-bad'

vs_ctl_header() {  # the leading comment block after the shebang; a bare # continues it
    awk 'NR == 1 { next } /^#/ { print; next } { exit }' "$1"
}

vs_ctl_declared() {
    vs_ctl_header "$1" \
        | sed -n -E "s/^# MUST-FIRE: ($VS_CTL_SHAPES): ([a-z0-9-]+) — .+\$/\2/p"
}

vs_ctl_none() {
    vs_ctl_header "$1" | sed -n -E 's/^# MUST-FIRE: none — (.+)$/\1/p' | head -1
}

vs_ctl_mode() {  # vs_ctl_mode <script>
    VS_CTL="${CONTROL:-}"
    [ -n "$VS_CTL" ] || return 0
    if ! vs_ctl_declared "$1" | grep -qx -- "$VS_CTL"; then
        echo "REFUSED: CONTROL=$VS_CTL is not a mode of this gate"
        exit 3
    fi
    echo "CONTROL MODE: $VS_CTL — the perturbation is applied to the REAL input; this run must FAIL"
    return 0
}

vs_ctl_is() { [ "${VS_CTL:-}" = "$1" ]; }

vs_ctl_fired() { echo "CONTROL FIRED: $1 — $2"; }
vs_ctl_dead()  { echo "CONTROL DEAD: $1 — $2"; return 1; }
# vs_ctl_left_green <mode> <the gate's FAIL line> — a mode run that reached the gate's GREEN end (#310, 14z-215): prints
# `CONTROL DEAD: <mode> — …` (tests/lib/classify.sh rule 1 reads its own DEAD line as LIES) and the FAIL line, and
# exits 1. Until then 42 gates printed "control mode X left the gate green" in WORDS and exited 1, which read HONOURED:
# the dead control certified as caught. Ground truth: tests/test_instr_align_unjudged.sh (control dead-close-honoured).
vs_ctl_left_green() {
    echo "CONTROL DEAD: $1 — the control mode left the gate green: its perturbation changed no verdict"   # #310 DEAD-close
    echo "$2"; exit 1
}
# vs_ctl_nj <why> — A DEAD LEG IS NOT A FINDING (#310 group 7, 14z-221; maintainer-ruled 2026-10-31 "5 and 6 now, 7 in
# batches"). Under a CONTROL= mode, a leg that never finished (an emulator that exited non-zero, a trace with no END line,
# no samples, a reducer's VOID) ends the run in the gate's ordinary FAIL, and tests/lib/classify.sh read that as the
# control firing: HONOURED on no measurement. Call this beside each such liveness check, with the check's own words: under
# a mode it prints `NOT JUDGED: under control mode <mode>, <why>` at column 0 (classify.sh reads the run UNJUDGED); in a
# plain run it prints nothing, so a plain run's output and exit are unchanged. Returns 0: the caller keeps its own fail
# flag. NOT for a mode whose honoured outcome IS a dead or VOID leg. The same shape as instr_align.sh's _ia_nj: the mode
# is VS_CTL (vs_ctl_mode), else CONTROL, so a gate that parses CONTROL itself only needs to source this file.
# Ground truth: tests/test_dead_leg_unjudged.sh (control plain-loud checks the silence; nj-stripped the rows).
vs_ctl_nj() { [ -n "${VS_CTL:-${CONTROL:-}}" ] || return 0; echo "NOT JUDGED: under control mode ${VS_CTL:-$CONTROL}, $1"; }
# vs_ctl_show_err <output file> [<expected exception>|-] [<copy script path>] — A PERTURBED COPY'S CRASH IS NOT ITS FINDING
# (#310 group 5, 14z-215; maintainer-ruled 2026-10-31). A control mode runs a copy of a tool or script with one
# perturbation; when the copy CRASHED, the gate used to print only `tail -N` of its output, an indented or joined excerpt,
# or nothing, and read the non-zero exit as the perturbation caught — tests/lib/classify.sh then saw no crash and read
# HONOURED. Call this on the copy's captured output (stdout and stderr) whenever its run did not give the expected answer:
#   a Python traceback          -> `NOT JUDGED:` and the traceback re-printed at column 0 (classify.sh rule 4a: DIED);
#   a headerless SyntaxError /  -> `NOT JUDGED:` (UNJUDGED): the copy never ran;
#     IndentationError / TabError
#   the shell's own error line about <copy script path> (bash `<path>: line N: x`, dash `<path>: N: x`), which
#     classify.sh's own-script branch never matches because it names the copy, not the gate -> `NOT JUDGED:` (UNJUDGED).
# Each prints and returns 1 (so a caller can `|| fail=1`, and a twin can print CONTROL DEAD); no crash returns 0 and
# prints nothing. WHERE A CRASH IS THE HONOURED OUTCOME (test_attribute_patch_delta's FileNotFoundError, the stripped
# applier's UnicodeEncodeError) pass its class as <expected> (an ERE alternative list, e.g. `FileNotFoundError`): the
# output must then END in that exception — it returns 0 silently; any other exception, a shell error, or no exception at
# all prints `NOT JUDGED:` with the traceback quoted behind `  | ` (so rule 4a does not read the expected firing DIED) and
# returns 1. Ground truth: tests/test_ctl_show_err.sh.
vs_ctl_show_err() {
    _vse_f="$1"; _vse_x="${2:--}"; _vse_s="${3:-}"; _vse_sh=""
    [ -f "$_vse_f" ] || { echo "NOT JUDGED: the perturbed copy left no output to judge ($_vse_f)"; return 1; }
    _vse_exc="$(grep -aE '^([A-Za-z_][A-Za-z0-9_]*\.)*[A-Z][A-Za-z0-9]*(Error|Exception|Interrupt|Exit)(: |$)' "$_vse_f" | tail -1)"
    _vse_syn="$(grep -aE '^(SyntaxError|IndentationError|TabError): ' "$_vse_f" | head -1)"
    _vse_tb="$(grep -anE -m1 '^[[:space:]]*Traceback \(most recent call last\)' "$_vse_f" | cut -d: -f1)"
    if [ -n "$_vse_s" ]; then
        _vse_sh="$(grep -aE "^$(printf '%s' "$_vse_s" | sed 's/[.[\*^$/]/\\&/g'): (line )?[0-9]+: [^0-9 ]" "$_vse_f" | head -1)"
    fi
    if [ "$_vse_x" != - ]; then   # the honoured outcome IS a crash: that one exception, nothing else
        if [ -z "$_vse_sh" ] && [ -n "$_vse_exc" ] && printf '%s\n' "$_vse_exc" | grep -qE "^([A-Za-z_][A-Za-z0-9_]*\.)*($_vse_x)(: |$)"; then return 0; fi   # VSE-EXPECTED
        echo "NOT JUDGED: the perturbed copy did not end in the expected $_vse_x — got: $(printf '%s' "${_vse_sh:-${_vse_exc:-no exception}}" | cut -c1-100)"
        tail -12 "$_vse_f" | sed 's/^/  | /'
        return 1
    fi
    if [ -n "$_vse_tb" ]; then   # VSE-TB
        echo "NOT JUDGED: the perturbed copy crashed, so this run judged nothing — ${_vse_exc:-a traceback}"
        sed -n "${_vse_tb}p" "$_vse_f" | sed 's/^[[:space:]]*//'; tail -n +"$((_vse_tb + 1))" "$_vse_f" | tail -12
        return 1
    fi
    if [ -n "$_vse_syn" ] || [ -n "$_vse_sh" ]; then   # VSE-SH
        echo "NOT JUDGED: the perturbed copy could not run, so this run judged nothing — $(printf '%s' "${_vse_sh:-$_vse_syn}" | cut -c1-110)"
        return 1
    fi
    return 0
}

vs_ctl_read() {  # vs_ctl_read <script> <log>
    # ITS SCRATCH NAMES ARE PREFIXED (14z-209, #323): a sh function has no locals, and this one ran in the runner's
    # own shell, where its `_l` overwrote the lane loop variable and disabled the prereq STOP.
    _vcr_s="$1"; _vcr_l="$2"
    VS_CTL_DECLARED=0; VS_CTL_FIRED=0; VS_CTL_DEAD=0; VS_CTL_UNDECLARED=0
    VS_CTL_MISSING=""; VS_CTL_DETAIL=""; VS_CTL_VERDICT=OK
    _vcr_decl="$(vs_ctl_declared "$_vcr_s")"
    _vcr_none="$(vs_ctl_none "$_vcr_s")"
    _vcr_fired="$(grep -aE '^CONTROL FIRED: [a-z0-9-]+' "$_vcr_l" 2>/dev/null | sed -E 's/^CONTROL FIRED: ([a-z0-9-]+).*/\1/')"
    _vcr_dead="$(grep -aE '^CONTROL DEAD: [a-z0-9-]+' "$_vcr_l" 2>/dev/null | sed -E 's/^CONTROL DEAD: ([a-z0-9-]+).*/\1/')"
    for _vcr_n in $_vcr_decl; do
        VS_CTL_DECLARED=$((VS_CTL_DECLARED + 1))
        if printf '%s\n' "$_vcr_dead" | grep -x >/dev/null -- "$_vcr_n"; then
            VS_CTL_DEAD=$((VS_CTL_DEAD + 1)); VS_CTL_MISSING="$VS_CTL_MISSING $_vcr_n(dead)"
        elif printf '%s\n' "$_vcr_fired" | grep -x >/dev/null -- "$_vcr_n"; then
            VS_CTL_FIRED=$((VS_CTL_FIRED + 1))
        else
            VS_CTL_DEAD=$((VS_CTL_DEAD + 1)); VS_CTL_MISSING="$VS_CTL_MISSING $_vcr_n(not fired)"
        fi
    done
    for _vcr_n in $_vcr_fired $_vcr_dead; do
        printf '%s\n' "$_vcr_decl" | grep -x >/dev/null -- "$_vcr_n" \
            || { VS_CTL_UNDECLARED=$((VS_CTL_UNDECLARED + 1)); VS_CTL_MISSING="$VS_CTL_MISSING $_vcr_n(undeclared)"; }
    done
    if [ "$VS_CTL_DEAD" != 0 ] || [ "$VS_CTL_UNDECLARED" != 0 ]; then
        VS_CTL_VERDICT=RED
        VS_CTL_DETAIL="controls RED:$VS_CTL_MISSING"
    elif [ "$VS_CTL_DECLARED" = 0 ]; then
        if [ -n "$_vcr_none" ]; then VS_CTL_VERDICT=NONE; VS_CTL_DETAIL="none — $_vcr_none"
        else VS_CTL_VERDICT=UNDECLARED; VS_CTL_DETAIL="no MUST-FIRE line"; fi
    fi
    return 0
}
