# measures.sh — THE MEASUREMENT CONTRACT'S READER, one copy, sourced by the
# classifier (tests/lib/classify.sh) and by every gate that declares a
# measurement. (GitHub #171 slice Q2, ruled 2026-09-24: "Declared/fired grammar".)
#
# WHY. Shape 1b of docs/project/gate_qualification_scope.md: at the M19 release
# tier two gates measured 0 rows and compared an EMPTY table whose sha256 is the
# hash of the empty string — the freeze had frozen the emptiness, and every close
# for four days was GREEN. A hash says the table is the one frozen; nothing said
# the table had anything in it. This contract makes an empty measurement a
# verdict: a gate that compares a produced table DECLARES what it measures and a
# floor, PRINTS the measurement, and the runners' reader turns a PASS whose
# declared measurement is absent or below its floor into FAIL — exactly as a
# declared control that did not fire does (tests/lib/controls.sh). No fifth
# verdict (the 14z-139 rule): the read happens inside vs_classify, after the
# controls read, on a PASS only.
#
# THE GRAMMAR — the header line sits in the LEADING COMMENT BLOCK (every `#`
# line after the shebang up to the first non-comment line; a bare `#`
# continues it), the run-time line at column 0:
#
#   # MEASURES: <name> — <floor> <what the number counts>
#       name [a-z0-9-]+ ; floor a non-negative integer; the rest is prose
#   MEASURED: <name> = <n>                    (printed at run time; n an integer)
#
# A gate may declare several measurements; each declared name must be printed
# once, at or above its floor. A printed name no header declares is a red too
# (a number nobody can review would count). No `none` form: a gate that
# measures nothing declares nothing.
#
# Functions (sh, no bashisms — the gates are #!/bin/sh):
#   vs_meas_header <script>            the leading comment block, to stdout
#   vs_meas_declared <script>          "name<TAB>floor" per declaration
#   vs_meas_read <script> <log>        declared vs measured for one run; sets
#                                      VS_MEAS_DECLARED/OK/BELOW/MISSING/UNDECLARED
#                                      (counts), VS_MEAS_NAMES (the red ones),
#                                      VS_MEAS_VERDICT OK|RED|NONE, VS_MEAS_DETAIL
#   vs_measured <name> <n>             print the MEASURED line (a gate's helper)
#   vs_meas_guard <script> <name> <n>  THE FREEZE GUARD: under FREEZE=1, a value below
#                                      the declared floor prints `REFUSED FREEZE:` and
#                                      returns 1 — the M19 shape was a FREEZE of an
#                                      empty table (rule-checker run 2026-09-24-143, Q4);
#                                      outside FREEZE=1 it returns 0 and prints nothing
# Ground truth: tests/test_measures_contract.sh.

vs_meas_header() {  # the leading comment block after the shebang; a bare # continues it
    awk 'NR == 1 { next } /^#/ { print; next } { exit }' "$1"
}

vs_meas_declared() {  # name<TAB>floor, one per line
    vs_meas_header "$1" \
        | sed -n -E 's/^# MEASURES: ([a-z0-9-]+) — ([0-9]+)( .*)?$/\1\t\2/p'
}

vs_measured() { echo "MEASURED: $1 = $2"; }

vs_meas_guard() {  # vs_meas_guard <script> <name> <n>
    [ "${FREEZE:-0}" = 1 ] || return 0
    _gf="$(vs_meas_declared "$1" | awk -v n="$2" -F'\t' '$1 == n {print $2; exit}')"
    [ -n "$_gf" ] || { echo "REFUSED FREEZE: $2 is not declared in $1's header (# MEASURES: $2 — <floor>)"; return 1; }
    if [ "$3" -lt "$_gf" ]; then
        echo "REFUSED FREEZE: $2 = $3 < floor $_gf — an empty or shrunken table is not frozen; lower the floor by a reviewed edit if the shrink is real"
        return 1
    fi
    return 0
}

vs_meas_read() {  # vs_meas_read <script> <log>
    _s="$1"; _l="$2"
    VS_MEAS_DECLARED=0; VS_MEAS_OK=0; VS_MEAS_BELOW=0; VS_MEAS_MISSING=0; VS_MEAS_UNDECLARED=0
    VS_MEAS_NAMES=""; VS_MEAS_DETAIL=""; VS_MEAS_VERDICT=OK
    _decl="$(vs_meas_declared "$_s")"
    _got="$(grep -aE '^MEASURED: [a-z0-9-]+ = -?[0-9]+' "$_l" 2>/dev/null | sed -E 's/^MEASURED: ([a-z0-9-]+) = (-?[0-9]+).*/\1 \2/')"
    # one declaration per line, name<TAB>floor: read with cut, never with a parameter
    # expansion on a literal tab (an editor can silently turn it into spaces)
    # awk, not `grep -v`: an empty declaration list must not return 1 under a runner's set -e
    # (the first close tier of 14z-180 died on its first gate exactly there)
    printf '%s\n' "$_decl" | awk 'NF' > "${TMPDIR:-/tmp}/vs_meas_$$.txt"
    while IFS= read -r _row; do
        _n="$(printf '%s' "$_row" | cut -f1)"; _f="$(printf '%s' "$_row" | cut -f2)"
        VS_MEAS_DECLARED=$((VS_MEAS_DECLARED + 1))
        _v="$(printf '%s\n' "$_got" | awk -v n="$_n" '$1 == n {print $2; exit}')"
        if [ -z "$_v" ]; then
            VS_MEAS_MISSING=$((VS_MEAS_MISSING + 1)); VS_MEAS_NAMES="$VS_MEAS_NAMES $_n(not measured)"
        elif [ "$_v" -lt "$_f" ]; then
            VS_MEAS_BELOW=$((VS_MEAS_BELOW + 1)); VS_MEAS_NAMES="$VS_MEAS_NAMES $_n=$_v<$_f"
        else
            VS_MEAS_OK=$((VS_MEAS_OK + 1))
        fi
    done < "${TMPDIR:-/tmp}/vs_meas_$$.txt"
    rm -f "${TMPDIR:-/tmp}/vs_meas_$$.txt"
    for _n in $(printf '%s\n' "$_got" | awk '{print $1}' | sort -u); do
        printf '%s\n' "$_decl" | cut -f1 | grep -qx -- "$_n" \
            || { VS_MEAS_UNDECLARED=$((VS_MEAS_UNDECLARED + 1)); VS_MEAS_NAMES="$VS_MEAS_NAMES $_n(undeclared)"; }
    done
    if [ "$VS_MEAS_MISSING" != 0 ] || [ "$VS_MEAS_BELOW" != 0 ] || [ "$VS_MEAS_UNDECLARED" != 0 ]; then
        VS_MEAS_VERDICT=RED
        VS_MEAS_DETAIL="measures RED:$VS_MEAS_NAMES"
    elif [ "$VS_MEAS_DECLARED" = 0 ]; then
        VS_MEAS_VERDICT=NONE
    fi
    return 0
}
