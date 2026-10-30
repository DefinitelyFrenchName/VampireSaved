#!/bin/sh
# test_recurrence_alarm.sh — A RULE-CHECKER FINDING THAT KEEPS COMING BACK IS A RED until a ticket owns its
# cause (tools/recurrence_alarm.py; #271, 14z-199: the rot rule "a recurring violation opens a ticket", adopted by the
# maintainer — "8. Rot -> I agree with your proposals"). ci_portable: no ROM, no emulator, ~1 s.
#
# WHAT: (1) the alarm's verdict logic on a synthetic ledger with known answers (its --selftest): a pair of
#   tokens cited in 3 subjects across 2 sessions recurs, with extract record indices and run numbers set
#   aside; a sitting's own re-check loop, one shared token (a topic), a calibration and one sitting under two
#   transcript prefixes do not; an acknowledgement silences the runs it covers, a recurrence AFTER its
#   through-run counts afresh, and an acknowledgement naming an unindexed ticket is REFUSED; (2) on the REAL
#   ledger, every recurring signature is acknowledged by tests/rulecheck/recurrence.tsv with a ticket that has
#   a row in docs/project/tickets.tsv. A red names the signature — a question and its two tokens — with its
#   subjects, sessions and runs: open a ticket for its cause and add the acknowledgement row.
# HOW: tools/recurrence_alarm.py reads every non-calibration VIOLATED run's verdict_real.txt; it is the static
#   tier, run at every close, that makes the alarm a standing close check (no separate close row: the same
#   check twice is the duplication #268 removed). It runs at every close because it is session cadence (listed in
#   tests/ci_portable.txt, not in tests/ci_cadence.tsv); when #269 turns the tier around, it belongs in the
#   always-run core, since what it reads (the ledger) changes at every sitting.
# EXPECTS: SELFTEST PASS and `0 not` acknowledged on the real ledger. A tool exit with neither line is REFUSED.
#
# MUST-FIRE: known-bad: through-ignored — tools/recurrence_alarm.py --selftest --through-ignored: an acknowledgement that covers every run, past AND future (a fix that did not hold silenced forever), must print SELFTEST FAIL on the recurs-afresh case, while --selftest passes (mode: the self-test runs the known-bad variant and the gate FAILs)
# MUST-FIRE: perturbed-copy: ack-dropped — the REAL ledger judged with an empty acknowledgement file must FAIL naming the calibration plants' reader pair QP3 2550 + 2560, the case that recurred from 14z-179 to 14z-198 unaggregated: the alarm fires on the real record, not only on the synthetic one (mode: the real check runs with the empty file and the gate FAILs)
#
# WHY: a calibration plant's reader quoting its claim's frames 2550/2560 failed procedure runs over seventeen
#   sessions, resolved run by run ("no slip", "accepted"); nothing read the ledger across runs (#271).
#
# Usage: tests/test_recurrence_alarm.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d "${TMPDIR:-/tmp}/recur.XXXXXX")" || { echo "FAIL: test_recurrence_alarm — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
: > "$W/empty.tsv"

if [ -z "${VS_CTL:-}" ] || vs_ctl_is through-ignored; then
echo "== 1. the alarm's verdict logic on a synthetic ledger (--selftest)"
v=""; vs_ctl_is through-ignored && { v="--through-ignored"; echo "MODE: control through-ignored — the self-test runs the variant whose acknowledgements cover future runs too"; }
out="$(python3 tools/recurrence_alarm.py --selftest $v 2>&1)"
if printf '%s\n' "$out" | grep >/dev/null '^SELFTEST PASS'; then ok "$(printf '%s\n' "$out" | tail -1)"
elif printf '%s\n' "$out" | grep >/dev/null '^SELFTEST FAIL'; then
    bad "$(printf '%s\n' "$out" | grep 'WRONG\|^SELFTEST' | tr '\n' ' ' | cut -c1-200)"
    if vs_ctl_is through-ignored && ! printf '%s\n' "$out" | grep >/dev/null 'WRONG: occurrences after the acknowledged run recur afresh'; then
        echo "REFUSED: mode through-ignored — the self-test failed, but not on the recurs-afresh case"; exit 3; fi
else echo "REFUSED: tools/recurrence_alarm.py --selftest printed no SELFTEST line (a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi
fi

if [ -z "${VS_CTL:-}" ] || vs_ctl_is ack-dropped; then
echo "== 2. the real ledger: every recurring finding acknowledged by a ticket"
a=""; vs_ctl_is ack-dropped && { a="--ack $W/empty.tsv"; echo "MODE: control ack-dropped — the real ledger judged with an empty acknowledgement file"; }
# shellcheck disable=SC2086
out="$(python3 tools/recurrence_alarm.py $a 2>&1)"; rc=$?
if [ "$rc" = 0 ] && printf '%s\n' "$out" | grep >/dev/null '^recurrence: .* 0 not$'; then ok "$(printf '%s\n' "$out" | head -1)"
elif [ "$rc" = 1 ] && printf '%s\n' "$out" | grep >/dev/null '^RECURRING: '; then
    bad "$(printf '%s\n' "$out" | head -1)"; printf '%s\n' "$out" | grep '^RECURRING: ' | head -10 | cut -c1-200 | sed 's/^/        /'
    if vs_ctl_is ack-dropped && ! printf '%s\n' "$out" | grep >/dev/null '^RECURRING: QP3 2550 + 2560 '; then
        echo "REFUSED: mode ack-dropped — the alarm failed, but not on the plant readers' 2550 + 2560"; exit 3; fi
else echo "REFUSED: tools/recurrence_alarm.py exited $rc with no verdict (a crash or a refused acknowledgement): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi
fi

if [ -z "${VS_CTL:-}" ]; then
    echo "== 3. controls"
    if python3 tools/recurrence_alarm.py --selftest --through-ignored > "$W/c1.out" 2>&1; then vs_ctl_dead through-ignored "the variant passed the self-test — the recurs-afresh case is not what it catches"; fail=1
    elif grep -q 'WRONG: occurrences after the acknowledged run recur afresh' "$W/c1.out"; then vs_ctl_fired through-ignored "the variant FAILS the self-test on the recurs-afresh case while the real tool passes it"
    else vs_ctl_dead through-ignored "the variant exited non-zero WITHOUT the recurs-afresh WRONG line: $(tail -1 "$W/c1.out" | cut -c1-120)"; fail=1; fi
    python3 tools/recurrence_alarm.py --ack "$W/empty.tsv" > "$W/c2.out" 2>&1; rc=$?
    if [ "$rc" = 1 ] && grep -q '^RECURRING: QP3 2550 + 2560 ' "$W/c2.out"; then vs_ctl_fired ack-dropped "with no acknowledgements the real ledger FAILS: $(grep -m1 '^RECURRING: QP3 2550 + 2560 ' "$W/c2.out" | cut -c12-120)"
    else vs_ctl_dead ack-dropped "with no acknowledgements the real ledger exited $rc without naming QP3 2550 + 2560"; fail=1; fi
fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
