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

# --- 14z-90 (issue #3): a SHORT log must not be prefix-compared ----------
# `n = min(len(a), len(b))` certified a run that stopped early as "fully
# re-convergent" over frames it never read. Two cases: a plain truncation,
# and the false GREEN — a run that breaks permanently AFTER the frozen shape,
# where cutting the log before the break hid the break entirely.
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
N = 4000
shape = {829, 2093} | set(range(890, 1803))
def write(path, diverge):
    lines = [f"{i} {'ffffffffffffffff' if i in diverge else '%016x' % i}"
             for i in range(1, N + 1)]
    (work / path).write_text("\n".join(lines + [f"END {N}"]) + "\n")
write("latebreak.log", shape | set(range(3000, N + 1)))
src = (work / "ok.log").read_text().splitlines()
(work / "trunc.log").write_text("\n".join(src[:2200]) + "\nEND 2200\n")
lb = (work / "latebreak.log").read_text().splitlines()
(work / "latebreak_trunc.log").write_text("\n".join(lb[:2500]) + "\nEND 2500\n")
PY
check trunc.log           fail "a truncated log is not prefix-compared"
check latebreak.log       fail "a permanent break after the frozen shape"
check latebreak_trunc.log fail "truncating before that break does not rescue it"

# --- 14z-90 (issue #4): the flicker inventory has a CAP, and the inter-run
# --- convergence check exists but is OFF by default ----------------------
# Measured across all 121 frozen composite specs: the largest inventory is 3,
# so --max-total 8 reds none of them. The fixture below is deliberately over
# the cap.
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
N = 4000
big = set(range(1, 21, 2)) | set(range(890, 1803))   # 10 flicker frames
write_lines = lambda p, d: (work / p).write_text("\n".join(
    [f"{i} {'ffffffffffffffff' if i in d else '%016x' % i}" for i in range(1, N + 1)]
    + [f"END {N}"]) + "\n")
write_lines("bigflicker.log", big)
# two flicker runs 55 frames apart — the shape behind the 5 anomalous specs
write_lines("closeflicker.log", {829, 885, 2093} | set(range(945, 1858)))
PY

if python3 "$REPO/tools/compare_composite.py" "$WORK/base.log" "$WORK/bigflicker.log" \
        --flicker 1,3,5,7,9,11,13,15,17,19 --windows 890-1802 >"$WORK/big.out" 2>&1; then
    echo "  FAIL: a 10-frame flicker inventory passed the max-total cap"; fail=1
else
    echo "  ok: an over-cap flicker inventory is rejected (max-total)"
fi

# The inter-run check must be OFF by default (or it reds 99 of 121 frozen
# specs), and must WORK when asked for. Both directions are asserted, because
# a flag that does nothing is worse than no flag.
if python3 "$REPO/tools/compare_composite.py" "$WORK/base.log" "$WORK/closeflicker.log" \
        --flicker 829,885,2093 --windows 945-1857 >"$WORK/cf1.out" 2>&1; then
    echo "  ok: a 55-frame flicker gap passes by DEFAULT (the boundary rule is"
    echo "      an open maintainer question, not a silent tightening)"
else
    echo "  FAIL: the default is now stricter — this reds frozen specs"; fail=1
fi
if python3 "$REPO/tools/compare_composite.py" "$WORK/base.log" "$WORK/closeflicker.log" \
        --flicker 829,885,2093 --windows 945-1857 --min-converge-flicker 60 \
        >"$WORK/cf2.out" 2>&1; then
    echo "  FAIL: --min-converge-flicker 60 accepted a 55-frame gap — the flag"
    echo "        does nothing, which is worse than not having it"; fail=1
else
    echo "  ok: --min-converge-flicker 60 rejects a 55-frame gap when asked"
fi

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
