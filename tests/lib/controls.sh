# controls.sh — THE MUST-FIRE CONTRACT'S READER, one copy, sourced by the
# classifier (tests/lib/classify.sh) and by every gate that declares a control.
# (14z-147, step two of the maintainer's ruling on the BBX finding — STATE
# "Decisions pending": "agreed with everything you just said".)
#
# THE GRAMMAR is BBX's R10 (docs/project/must_fire_contract.md is the copy of
# record in this tree). It is a COPY, never a dependency: "independent but
# compatible" (maintainer, 2026-09-08). Four regexes, and the header is the
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

vs_ctl_read() {  # vs_ctl_read <script> <log>
    _s="$1"; _l="$2"
    VS_CTL_DECLARED=0; VS_CTL_FIRED=0; VS_CTL_DEAD=0; VS_CTL_UNDECLARED=0
    VS_CTL_MISSING=""; VS_CTL_DETAIL=""; VS_CTL_VERDICT=OK
    _decl="$(vs_ctl_declared "$_s")"
    _none="$(vs_ctl_none "$_s")"
    _fired="$(grep -aE '^CONTROL FIRED: [a-z0-9-]+' "$_l" 2>/dev/null | sed -E 's/^CONTROL FIRED: ([a-z0-9-]+).*/\1/')"
    _dead="$(grep -aE '^CONTROL DEAD: [a-z0-9-]+' "$_l" 2>/dev/null | sed -E 's/^CONTROL DEAD: ([a-z0-9-]+).*/\1/')"
    for _n in $_decl; do
        VS_CTL_DECLARED=$((VS_CTL_DECLARED + 1))
        if printf '%s\n' "$_dead" | grep -qx -- "$_n"; then
            VS_CTL_DEAD=$((VS_CTL_DEAD + 1)); VS_CTL_MISSING="$VS_CTL_MISSING $_n(dead)"
        elif printf '%s\n' "$_fired" | grep -qx -- "$_n"; then
            VS_CTL_FIRED=$((VS_CTL_FIRED + 1))
        else
            VS_CTL_DEAD=$((VS_CTL_DEAD + 1)); VS_CTL_MISSING="$VS_CTL_MISSING $_n(not fired)"
        fi
    done
    for _n in $_fired $_dead; do
        printf '%s\n' "$_decl" | grep -qx -- "$_n" \
            || { VS_CTL_UNDECLARED=$((VS_CTL_UNDECLARED + 1)); VS_CTL_MISSING="$VS_CTL_MISSING $_n(undeclared)"; }
    done
    if [ "$VS_CTL_DEAD" != 0 ] || [ "$VS_CTL_UNDECLARED" != 0 ]; then
        VS_CTL_VERDICT=RED
        VS_CTL_DETAIL="controls RED:$VS_CTL_MISSING"
    elif [ "$VS_CTL_DECLARED" = 0 ]; then
        if [ -n "$_none" ]; then VS_CTL_VERDICT=NONE; VS_CTL_DETAIL="none — $_none"
        else VS_CTL_VERDICT=UNDECLARED; VS_CTL_DETAIL="no MUST-FIRE line"; fi
    fi
    return 0
}
