#!/bin/sh
# test_battery_accounting.sh — "BATTERY GREEN" must not be printable when
# gates self-skipped (14z-94, GitHub #24). ROM-free, ~1 s.
#
# WHY. run_battery_m2.sh is `set -eu` and invoked each gate as a bare command,
# so exit 0 was indistinguishable from PASS. At least four gates `exit 0` when
# a prerequisite is absent, and FIVE more are skipped wholesale by the
# `if [ -x <wide mame> ]` branch. On a machine without the WIDE MAME binary
# and with pruned build dirs, nine of ~24 gates never ran — and the script
# still ended with an unconditional `echo "BATTERY GREEN"`.
#
# That sentence is what a session records in STATE.md under CLAUDE.md rule 2
# ("no untested change survives a session"). A reader of the final line could
# not tell a full battery from a third of one.
#
# Section 3 drives the accounting functions directly, because the battery
# itself builds ROMs and runs for many minutes — the logic has to be testable
# without paying that.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #24) `run_battery_m2.sh` cannot print BATTERY GREEN while
#   gates self-skip; counts branch skips by group size.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }
B="tests/run_battery_m2.sh"

echo "== 1. every gate invocation goes through the accounting wrapper =="
stray="$(grep -nE '^\s*tests/[a-z0-9_]+\.sh' "$B" || true)"
if [ -n "$stray" ]; then
    fail "bare gate invocations that bypass the tally:"
    printf '%s\n' "$stray" | sed 's/^/        /' | head -6
else
    n=$(grep -cE '^\s*bat tests/[a-z0-9_]+\.sh' "$B")
    echo "  ok: $n invocations, all wrapped"
fi

echo "== 2. GREEN is conditional, and the skip list is printed =="
grep -q 'BATTERY GREEN — \$_bat_pass gates, 0 skipped' "$B" \
    && echo "  ok: GREEN names the count and requires 0 skips" \
    || fail "the GREEN line is not conditional on a zero skip count"
grep -q 'BATTERY INCOMPLETE' "$B" \
    && echo "  ok: a skipped battery reports INCOMPLETE instead" \
    || fail "there is no INCOMPLETE path — skips would still read as green"
grep -q '_bat_skipped' "$B" \
    && echo "  ok: and it names which gates were skipped" \
    || fail "the skip list is not printed, so the reader cannot act on it"

echo "== 3. the accounting logic, driven directly =="
# Extract the two functions and exercise them against stubs. Extracted, not
# copied, so the code under test is the shipped code.
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
sed -n '/^_bat_pass=0/,/^}$/p' "$B" > "$T/acct.sh"
# the second function too
sed -n '/^bat_group_skip()/,/^}$/p' "$B" >> "$T/acct.sh"
if ! grep -q "bat()" "$T/acct.sh" || ! grep -q "bat_group_skip()" "$T/acct.sh"; then
    echo "  FAIL: could not extract the accounting functions — this section"
    echo "        would prove nothing"; exit 1
fi

mk() { printf '#!/bin/sh\n%s\nexit %s\n' "$2" "$3" > "$T/$1"; chmod +x "$T/$1"; }
mk g_pass.sh 'echo "PASS: fine"' 0
mk g_skip.sh 'echo "SKIP: no build dir"' 0
mk g_fail.sh 'echo "FAIL: broken"' 1

out="$( cd "$T" && sh -c '
    . ./acct.sh
    bat ./g_pass.sh
    bat ./g_skip.sh
    bat_group_skip wide-mame 5
    echo "TALLY pass=$_bat_pass skip=$_bat_skip list=$_bat_skipped"
' 2>&1 )"
if printf '%s' "$out" | grep -q "TALLY pass=1 skip=6"; then
    echo "  ok: 1 pass, 1 self-skip + a 5-gate group skip = 6 skipped"
else
    fail "wrong tally: $(printf '%s' "$out" | grep TALLY || echo '(none)')"
fi
printf '%s' "$out" | grep -q "wide-mame(x5)" \
    && echo "  ok: the group skip names itself and its size" \
    || fail "the group skip is anonymous in the list"

echo "== 4. a FAIL still stops the battery immediately =="
# The wrapper must not soften set -e: a failing gate has to abort, not tally.
if ( cd "$T" && sh -c '. ./acct.sh; bat ./g_fail.sh; echo "REACHED-AFTER-FAIL"' \
        > "$T/f.out" 2>&1 ); then
    fail "a failing gate did not stop the battery"
else
    grep -q "REACHED-AFTER-FAIL" "$T/f.out" \
        && fail "execution continued past a failing gate" \
        || echo "  ok: aborted at the failure"
    grep -q "BATTERY FAILED at g_fail" "$T/f.out" \
        && echo "  ok: and it names the gate that failed" \
        || fail "the abort does not name the failing gate"
fi

echo "== 5. CONTROL — a clean battery still reports GREEN =="
# Without this, "never print GREEN" would pass every section above.
out2="$( cd "$T" && sh -c '
    . ./acct.sh
    bat ./g_pass.sh
    if [ "$_bat_skip" = 0 ]; then echo "BATTERY GREEN — $_bat_pass gates, 0 skipped"; fi
' 2>&1 )"
printf '%s' "$out2" | grep -q "BATTERY GREEN" \
    && echo "  ok: an all-pass run still prints GREEN" \
    || fail "a clean battery no longer reports GREEN"

echo
[ "$rc" = 0 ] && echo "PASS: the battery cannot call itself green while skipping." \
             || echo "FAIL: see above."
exit $rc
