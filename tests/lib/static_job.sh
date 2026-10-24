#!/bin/sh
# static_job.sh — ONE job of a parallel static tier (14z-205, GitHub #299; split 14z-207, #312). Runs tests/<gate>.sh,
# or one of its declared controls as a CONTROL=<name> mode, and writes each run's exit status and seconds beside the log
# the runner reads ($W/pre/<gate>.run, $W/pre/<gate>.ctl.<name>.run). Started by tests/lib/static_pool.py under
# tests/run_all_static.sh --jobs N; the runner then classifies every result in registry order exactly as a serial run
# does (run_tier and exec_controls read these files instead of running the gate), so only the wall clock differs.
#
# THE RULE, mirrored here and nowhere else decided: controls run for a gate the classifier reads PASS, that declares at
# least one, under --exec-controls all (or portable for the portable tier), unless the confirm plan carries its controls
# (`carry-controls` with the same declared count, #286 (c) / #298). A mismatch is harmless: the runner executes serially
# any control this job did not.
#
# MODES (#312): `gate` runs the gate and writes the controls the rule would execute to $W/pre/<gate>.ctlq — one name a
# line, after a first line `concurrent` (the gate is listed in tests/controls_concurrent.txt: each control may run as its
# own pool job, beside its siblings) or `serial` (they run one after another in one job, as before #312); no file when the
# rule executes none. `control <name>` runs one control; `controls` runs every name of the .ctlq in order. With no mode
# (an `# ORDER: last` gate, run alone after the pool) the gate and then its controls run in one job, as before.
#
# usage: tests/lib/static_job.sh <gate> <work dir> <exec-controls all|portable|none> <tier label> [gate|control <name>|controls]
set -u
g="$1"; W="$2"; X="$3"; L="$4"; MODE="${5:-full}"; CN="${6:-}"
REPO="$(pwd)"; export REPO
. tests/lib/classify.sh
mkdir -p "$W/pre"
run_control() {  # run_control <name>
    _c0=$(date +%s)
    CONTROL="$1" tests/"$g".sh </dev/null > "$W/$g.ctl.$1.out" 2>&1 && _cs=0 || _cs=$?
    _c1=$(date +%s)
    echo "$_cs $((_c1 - _c0))" > "$W/pre/$g.ctl.$1.run"
}
case "$MODE" in
control) run_control "$CN"; exit 0 ;;
controls) sed 1d "$W/pre/$g.ctlq" | while read -r _n; do run_control "$_n"; done; exit 0 ;;
gate|full) ;;
*) echo "static_job.sh: bad mode '$MODE'" >&2; exit 2 ;;
esac
_t0=$(date +%s)
tests/"$g".sh </dev/null > "$W/$g.out" 2>&1 && _st=0 || _st=$?
_t1=$(date +%s)
echo "$_st $((_t1 - _t0))" > "$W/pre/$g.run"
case "$X" in none) exit 0 ;; portable) [ "$L" = portable ] || exit 0 ;; esac
vs_classify "$_st" "$W/$g.out" 58 "tests/$g.sh"
case "$VS_VERDICT" in TIMEOUT|FAIL|SKIP) exit 0 ;; esac
[ "${VS_CTL_DECLARED:-0}" != 0 ] || exit 0
if [ -f "$W/plan.tsv" ]; then
    _cc="$(awk -F'\t' -v g="$g" '$1 == "RERUN" && $2 == g && $4 == "carry-controls" {print $5}' "$W/plan.tsv")"
    [ -n "$_cc" ] && [ "$_cc" = "$VS_CTL_DECLARED" ] && exit 0   # JOB-CARRY-CONTROLS
fi
if [ "$MODE" = gate ]; then   # JOB-QUEUE-CONTROLS: the pool runs them, each as its own job when the gate allows it
    { awk -F'\t' -v g="$g" '!/^#/ && $1 == g {f = 1} END {exit !f}' tests/controls_concurrent.txt 2>/dev/null && echo concurrent || echo serial
      for _n in $(vs_ctl_declared "tests/$g.sh"); do echo "$_n"; done; } > "$W/pre/$g.ctlq.tmp"
    mv "$W/pre/$g.ctlq.tmp" "$W/pre/$g.ctlq"
    exit 0
fi
for _n in $(vs_ctl_declared "tests/$g.sh"); do run_control "$_n"; done
exit 0
