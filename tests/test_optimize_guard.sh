#!/bin/sh
# test_optimize_guard.sh — a safety check that an environment variable can
# switch off is not a safety check (14z-94, GitHub #79). ROM-free, ~2 s.
#
# THE DEFECT. The graphics collision, band-bound and placement checks are
# `assert` statements, and `python -O` / PYTHONOPTIMIZE=1 removes assert
# statements ENTIRELY. Under that mode an invalid placement exits 0 — and the
# gate meant to catch it prints PASS, because the raise it waits for never
# happens. Both layers vanish together, which is the property that makes this
# worse than an ordinary missing check.
#
# THE FIX IS TO REFUSE THE MODE, not to convert the statements. Converting
# each assert fixes today's checks and not tomorrow's; refusing at import time
# covers every assert in the file, including ones not written yet.
#
# Section 3 is the systemic half: any tool a BUILDER invokes that relies on
# asserts must carry the guard, so a new one cannot quietly join without it.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

# #79 named the first two. Section 3 found the other four, and they are not
# lesser: cps2_decrypt's round-trip self-check is what stands between a wrong
# key schedule and a silently corrupt shipped ROM, and select_port carries the
# same conflicting-tile-placement check as the gfx builder.
GUARDED="tools/build_gfx_donovan.py tools/gen_donovan_patch.py
         tools/cps2_decrypt.py tools/extract_char.py
         tools/select_port.py tools/verify_pcrel_data.py"

echo "== 1. each guarded tool REFUSES under -O, and says why =="
for t in $GUARDED; do
    if out=$(python3 -O "$t" --help 2>&1); then
        fail "$t ran under -O — its assertions would be stripped"
    elif printf '%s' "$out" | grep -q "GitHub #79"; then
        echo "  ok: $(basename "$t") refused, naming the reason"
    else
        fail "$t failed under -O for an UNNAMED reason; this control would"
        fail "      then pass on any unrelated breakage: $(printf '%s' "$out" | head -1)"
    fi
done

echo "== 2. and still runs NORMALLY (the guard is not a brick) =="
for t in $GUARDED; do
    if python3 "$t" --help >/dev/null 2>&1; then
        echo "  ok: $(basename "$t") runs with assertions enabled"
    else
        fail "$t no longer runs at all — the guard broke it"
    fi
done

echo "== 3. no assert-using tool invoked by a BUILDER lacks the guard =="
# The builders are what turn a bad check into a shipped ROM, so their tool
# graph is the set that matters. A tool with zero asserts needs no guard.
missing=""
for b in tools/build_donovan.sh tools/build_merged.sh; do
    [ -f "$b" ] || continue
    for t in $(grep -oE 'tools/[a-z0-9_]+\.py' "$b" | sort -u); do
        [ -f "$t" ] || continue
        n=$(grep -c '^[[:space:]]*assert ' "$t" || true)
        [ "$n" -eq 0 ] && continue
        if ! grep -q "GitHub #79" "$t"; then
            missing="$missing $t($n)"
        fi
    done
done
if [ -n "$missing" ]; then
    fail "assert-using tools reachable from a builder without the guard:$missing"
    fail "      Add the 'if not __debug__: raise SystemExit(...)' guard, or"
    fail "      convert those asserts to explicit raises."
else
    echo "  ok: every assert-using tool a builder invokes carries the guard"
fi

echo "== 4. CONTROL — the guard would actually catch a stripped assert =="
# Proves the premise rather than assuming it: under -O an assert is gone.
if python3 -O -c "
def f():
    assert False, 'safety'
    return 1
raise SystemExit(0 if f() == 1 else 1)" 2>/dev/null; then
    echo "  ok: confirmed — under -O an assert does not raise at all"
else
    fail "this Python does NOT strip asserts under -O, so the premise of the"
    fail "      guard (and of #79) does not hold here — re-check the finding"
fi

echo
[ "$rc" = 0 ] && echo "PASS: safety checks cannot be switched off by the environment." \
             || echo "FAIL: see above."
exit $rc
