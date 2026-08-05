#!/bin/sh
# test_compare_composite.sh — ground truth for tools/compare_composite.py,
# the PROPOSED §4 composite class (frozen flicker inventory + frozen bounded
# windows). Written before ratification precisely so the class can be judged
# on a checker whose verdicts are already evidenced.
#
# CLAUDE.md §4: "Verdict logic is itself tested." A checker that has only
# ever been shown to PASS is not evidence. Seven synthetic cases, no
# emulator, ~1s:
#
#   1. exactly the frozen shape                     -> PASS
#   2. an EXTRA flicker frame                       -> FAIL (inventory grew)
#   3. a MISSING flicker frame                      -> FAIL (drift either way)
#   4. a window that starts one frame late          -> FAIL (onset is frozen)
#   5. a window that never re-converges             -> FAIL (the whole point)
#   6. bit-identical logs                           -> FAIL (asserts existence)
#   7. a second, unfrozen window appearing          -> FAIL (nothing extra)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

python3 - "$WORK" <<'PY'
import sys
work = sys.argv[1]
N = 4000

def write(path, diverge):
    """diverge: set of frame numbers that differ from base."""
    lines = []
    for f in range(1, N + 1):
        h = "%016x" % (0xdeadbeef if f in diverge else f)
        lines.append(f"{f} {h}")
    open(f"{work}/{path}", "w").write("\n".join(lines + [f"END {N}"]))

base = set()
# the frozen shape: flicker at 829 and 2093, one window 890..1802
shape = {829, 2093} | set(range(890, 1803))
write("base.log", base)
write("ok.log", shape)
write("extra_flicker.log", shape | {3100})
write("missing_flicker.log", shape - {2093})
write("late_onset.log", ({829, 2093} | set(range(891, 1803))))
write("no_reconverge.log", ({829, 2093} | set(range(890, N + 1))))
write("identical.log", base)
write("second_window.log", shape | set(range(3000, 3200)))
PY

check() {  # check <file> <expect pass|fail> <description>
    if python3 "$REPO/tools/compare_composite.py" "$WORK/base.log" "$WORK/$1" \
            --flicker 829,2093 --windows 890-1802 > "$WORK/$1.out" 2>&1; then
        got=pass
    else
        got=fail
    fi
    if [ "$got" = "$2" ]; then
        echo "  ok: $3 -> $got"
    else
        echo "  FAIL: $3 -> $got (expected $2)"
        sed 's/^/        /' "$WORK/$1.out"
        fail=1
    fi
}

echo "== ground truth for the PROPOSED composite comparison class =="
check ok.log              pass "exactly the frozen shape"
check extra_flicker.log   fail "an extra flicker frame appears"
check missing_flicker.log fail "a frozen flicker frame disappears"
check late_onset.log      fail "the window onset moves by one frame"
check no_reconverge.log   fail "the window never re-converges"
check identical.log       fail "the logs are bit-identical"
check second_window.log   fail "an unfrozen second window appears"

# The class must not be usable as a loophole: it has to reject a shape that
# `flicker` alone would reject, with the window list empty.
if python3 "$REPO/tools/compare_composite.py" "$WORK/base.log" "$WORK/ok.log" \
        --flicker 829,2093 --windows - > "$WORK/nowin.out" 2>&1; then
    echo "  FAIL: a long run passed while the window list was empty"
    fail=1
else
    echo "  ok: with no windows frozen, a long run is rejected (not a loophole)"
fi

[ "$fail" = 0 ] || { echo "FAIL: composite class ground truth"; exit 1; }
echo "PASS: composite class ground truth (7 cases + the no-loophole check)"
