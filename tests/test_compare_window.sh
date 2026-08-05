#!/bin/sh
# test_compare_window.sh — ground truth for the "bounded re-convergent
# window" comparison class (CLAUDE.md §4 v3).
#
# A comparison class is worth exactly as much as its checker, and this
# project has shipped a wrong conclusion from a verdict bug before (the SMS
# "blockable frame trap"). So the checker is exercised against synthetic
# logs whose answer is known, in BOTH directions, before any gate trusts it.
#
# The class exists because the roster deliberately alters the select screen.
# It must accept exactly that shape and reject everything laxer: scattered
# flicker, a drifting onset, and — most importantly — a divergence that
# never re-converges, which would mean match state was touched.
#
# Usage: tests/test_compare_window.sh   (no emulator, no ROMDIR)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="${TMPDIR:-/tmp}/cmpwin_$$"
mkdir -p "$W"
trap 'rm -rf "$W"' EXIT
fail=0

# mk <file> <divergent frames...> — 400 frames; the listed ones differ
mk() {
    _f="$1"; shift
    _d=" $* "
    i=1
    : > "$_f"
    while [ "$i" -le 400 ]; do
        case "$_d" in
            *" $i "*) printf '%d %s\n' "$i" "ffffffffffffffff" >> "$_f" ;;
            *)        printf '%d %s\n' "$i" "0000000000000000" >> "$_f" ;;
        esac
        i=$((i + 1))
    done
    echo "END 400" >> "$_f"
}

check() {  # check <label> <want-rc> <args...>
    _l="$1"; _w="$2"; shift 2
    if python3 tools/compare_window.py "$@" >"$W/out" 2>&1; then _rc=0; else _rc=$?; fi
    if [ "$_rc" = "$_w" ]; then
        echo "  PASS  $_l"
    else
        echo "  FAIL  $_l (rc=$_rc want $_w)"
        sed 's/^/        /' "$W/out"
        fail=1
    fi
}

mk "$W/base"                                  # all identical
mk "$W/window" 100 101 102 103 104            # one contiguous run, 100..104
mk "$W/scattered" 100 101 150 151 200         # three runs
mk "$W/late" 120 121 122 123 124              # right shape, wrong onset
mk "$W/tail" 396 397 398 399 400              # never re-converges

echo "== the shape the class exists to accept =="
check "single contiguous window at the frozen onset" 0 \
    "$W/base" "$W/window" --onset 100 --end 104

echo "== everything laxer must be rejected =="
check "scattered flicker is not a window" 1 \
    "$W/base" "$W/scattered" --onset 100 --end 200
check "a drifting onset is caught" 1 \
    "$W/base" "$W/late" --onset 100 --end 104
check "a window that never re-converges is caught" 1 \
    "$W/base" "$W/tail" --onset 396 --end 400
check "a bit-identical pair is NOT a silent pass" 1 \
    "$W/base" "$W/base" --onset 100 --end 104

if [ "$fail" = 0 ]; then
    echo "COMPARE WINDOW: PASS"
else
    echo "COMPARE WINDOW: FAIL"
fi
exit "$fail"
