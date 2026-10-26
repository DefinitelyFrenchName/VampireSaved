#!/bin/sh
# test_suite_jobs.sh — run_suite.sh at SUITE_JOBS=N says what it says at SUITE_JOBS=1 (#321, 14z-210). ROM-free, no MAME, ~15 s.
#
# WHAT: tests/run_suite.sh's SUITE_JOBS=N makes every replay's two MAME runs first, N at a time, and then classifies them
#   in replay order; its output, and what --freeze writes into the expectation set, must be the serial run's byte for
#   byte — every verdict kind included (PASS, FAIL, SKIP, PENDING, RUN-FAIL, NONDETERMINISTIC, NO-EXPECTATION, frozen,
#   an authored .masked left alone) — and it must actually run them beside one another.
# HOW: the REAL run_suite.sh symlinked into a fake repo (as tests/test_freeze_retires_diverge.sh does) with a stub MAME
#   runner that prints a line, sleeps 0.4 s and writes a log carrying the replay, the run's MASK_RANGES and, for the
#   replays built to, a run-number or a failure; the suite run at 1 and 8 jobs, verify and --freeze (each on its own copy
#   of the expectations), outputs and expectation trees compared, and the 8-job wall time held under half the serial.
# EXPECTS: identical outputs and trees, and the pool faster than the serial loop; a red is a parallel suite whose
#   verdicts or frozen files are not the serial suite's.
#
# MUST-FIRE: shadow-tool: rc-ignored — a copy of run_suite.sh whose read-back ignores a run's exit status must print a verdict where the serial suite prints RUN-FAIL (mode: that copy is the suite the 8-job runs drive; the compare must fail)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
rc=0
ok() { echo "  ok    $*"; }
fail() { echo "  FAIL  $*"; rc=1; }

T="${KEEP_T:-$(mktemp -d)}"; [ -n "${KEEP_T:-}" ] || trap 'rm -rf "$T"' EXIT INT TERM; mkdir -p "$T"
FR="$T/fakerepo"
mkdir -p "$FR/tools" "$FR/tests/lib" "$FR/tests/replays" "$T/romdir"
ln -s "$REPO/tests/run_suite.sh" "$FR/tests/run_suite.sh"
ln -s "$REPO/tests/lib/masked_compare.sh" "$FR/tests/lib/masked_compare.sh"
# the control: the read-back's exit-status test replaced by `true`
sed 's@        \[ "$(cat "$WORK/$1.$3.rc" 2>/dev/null)" = 0 \]@        true@' "$REPO/tests/run_suite.sh" > "$FR/tests/run_suite_rcignored.sh"
cmp -s "$REPO/tests/run_suite.sh" "$FR/tests/run_suite_rcignored.sh" && fail "could not disable the exit-status read-back — the line moved"
PAR=run_suite.sh
vs_ctl_is rc-ignored && PAR=run_suite_rcignored.sh

for n in 01_pass 02_fail 03_skip 04_pend 05_runfail 06_nondet 07_noexp 08_masked 09_pass2 10_pass3; do
    echo "0 none" > "$FR/tests/replays/$n.rpl"
done
cat > "$FR/tools/build_fingerprint.py" <<'PY'
print("stubset")
PY
cat > "$FR/tools/check_diverge.py" <<'PY'
print("DIVERGE-BRANCH-RAN")
PY
cat > "$FR/tools/run_replay_mame.sh" <<'STUB'
#!/bin/sh
# stub MAME: <set> <rpl> <log> <sandbox>; the run number is the log name's last field before .log
n="$(basename "$2" .rpl)"; k="$(basename "$3" .log)"; k="${k##*.}"
echo "stub ran $n run $k"
sleep 0.4
case "$n" in 05_runfail) [ "$k" = 2 ] && { echo "boom: run 2 of $n" >&2; exit 1; } ;; esac
x=""; [ "$n" = 06_nondet ] && x=" run $k"
printf 'frame 0 %s mask=%s%s\n' "$n" "${MASK_RANGES:-}" "$x" > "$3"
STUB
chmod +x "$FR/tools/run_replay_mame.sh"
E0="$T/exp0/stubset"; mkdir -p "$E0"
echo "not this set" > "$E0/03_skip.skip"
echo "proposed: a class not ratified" > "$E0/04_pend.pending"
echo "exact stubset/masked" > "$E0/08_masked.masked"
echo "0000000000000000000000000000000000000000" > "$E0/02_fail.sha1"
for n in 01_pass 09_pass2 10_pass3; do printf 'frame 0 %s mask=\n' "$n" | shasum | cut -d' ' -f1 > "$E0/$n.sha1"; done

suite() {  # suite <tag> <script> <jobs> [--freeze]: a fresh copy of the expectations, the suite's output and wall seconds
    rm -rf "$FR/tests/expected"; mkdir -p "$FR/tests/expected"; cp -R "$T/exp0/stubset" "$FR/tests/expected/stubset"
    _t0=$(date +%s)
    ( cd "$FR" && ROMDIR="$T/romdir" SUITE_JOBS="$3" sh "./tests/$2" ${4:-} vsavj ) > "$T/$1.out" 2>&1 || true
    echo $(( $(date +%s) - _t0 )) > "$T/$1.sec"
    rm -rf "$T/$1.exp"; cp -R "$FR/tests/expected" "$T/$1.exp"
}

echo "== 1. verify: SUITE_JOBS=8 prints the serial suite's output, line for line"
suite v1 run_suite.sh 1
suite v8 "$PAR" 8
# the stub's own lines sit between a replay's name and its verdict, as a real run's MAME output does
for want in "^FAIL expected 0000" "^03_skip .*SKIP (not this set)" "^04_pend .*PENDING" "^RUN-FAIL" \
            "^NONDETERMINISTIC" "^NO-EXPECTATION" "^PASS" "^SUITE RED"; do
    grep -q "$want" "$T/v1.out" || fail "the serial suite did not print '$want' — the rig does not build the case it claims"
done
grep -q 'boom: run 2 of 05_runfail' "$T/v1.out" || fail "the serial suite did not show the failing run's own output"
if cmp -s "$T/v1.out" "$T/v8.out"; then ok "identical outputs ($(wc -l < "$T/v1.out" | tr -d ' ') lines; RUN-FAIL, NONDETERMINISTIC, SKIP, PENDING included)"
else fail "SUITE_JOBS=8 printed something else:"; diff "$T/v1.out" "$T/v8.out" | head -8 | sed 's/^/        /'
     vs_ctl_is rc-ignored && vs_ctl_fired rc-ignored "a read-back that ignores the exit status prints $(diff "$T/v1.out" "$T/v8.out" | grep '^>' | grep -c . | tr -d ' ') line(s) the serial suite does not"; fi

if ! vs_ctl_is rc-ignored; then   # the control, inline: the copy that ignores a run's exit status must differ
    suite vc run_suite_rcignored.sh 8
    cmp -s "$T/v1.out" "$T/vc.out" && { vs_ctl_dead rc-ignored "a read-back that ignores the exit status printed the serial output"; fail "rc-ignored"; } \
        || vs_ctl_fired rc-ignored "a read-back that ignores the exit status prints $(diff "$T/v1.out" "$T/vc.out" | grep -c '^>' | tr -d ' ') line(s) the serial suite does not"
fi

echo "== 2. --freeze: the same output and the same expectation tree"
suite f1 run_suite.sh 1 --freeze
suite f8 "$PAR" 8 --freeze
grep -q '^authored .masked expectation — not self-frozen' "$T/f1.out" || fail "the serial freeze did not leave the authored .masked alone"
grep -q '^frozen ' "$T/f1.out" || fail "the serial freeze froze nothing"
cmp -s "$T/f1.out" "$T/f8.out" && ok "identical freeze outputs" || { fail "the 8-job freeze printed something else"; diff "$T/f1.out" "$T/f8.out" | head -6 | sed 's/^/        /'; }
diff -r "$T/f1.exp" "$T/f8.exp" > "$T/fdiff" 2>&1 && ok "identical expectation trees after --freeze ($(find "$T/f1.exp" -type f | wc -l | tr -d ' ') files)" \
    || { fail "the 8-job freeze wrote a different tree"; head -6 "$T/fdiff" | sed 's/^/        /'; }

echo "== 3. the pool runs them beside one another"
s1="$(cat "$T/v1.sec")"; s8="$(cat "$T/v8.sec")"
[ $((s8 * 2)) -lt "$s1" ] && ok "SUITE_JOBS=8 took ${s8} s against ${s1} s serial" || fail "SUITE_JOBS=8 took ${s8} s against ${s1} s serial — not under half"

echo "== 4. a SUITE_JOBS that is not a positive integer is refused"
( cd "$FR" && ROMDIR="$T/romdir" SUITE_JOBS=0 sh ./tests/run_suite.sh vsavj ) > "$T/bad.out" 2>&1 && st=0 || st=$?
[ "$st" = 2 ] && grep -q 'SUITE_JOBS must be a positive integer' "$T/bad.out" && ok "SUITE_JOBS=0 refused (exit 2)" || fail "SUITE_JOBS=0 was not refused (exit $st)"

[ "$rc" = 0 ] && echo "PASS: test_suite_jobs" || echo "FAIL: test_suite_jobs"
exit "$rc"
