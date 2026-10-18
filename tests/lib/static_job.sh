#!/bin/sh
# static_job.sh — ONE gate of a parallel static tier (14z-205, GitHub #299). Runs tests/<gate>.sh, then — when the
# runner's own rule would execute its controls — each declared control as a CONTROL=<name> mode, and writes each run's
# exit status and seconds beside the log the runner reads ($W/pre/<gate>.run, $W/pre/<gate>.ctl.<name>.run). Started by
# tests/run_all_static.sh --jobs N through `xargs -P`; the runner then classifies every result in registry order exactly
# as a serial run does (run_tier and exec_controls read these files instead of running the gate), so only the wall
# clock differs. The rule mirrored here, and nowhere else decided: controls run for a gate the classifier reads PASS,
# that declares at least one, under --exec-controls all (or portable for the portable tier), unless the confirm plan
# carries its controls (`carry-controls` with the same declared count, #286 (c) / #298). A mismatch is harmless: the
# runner executes serially any control this job did not.
#
# usage: tests/lib/static_job.sh <gate> <work dir> <exec-controls all|portable|none> <tier label>
set -u
g="$1"; W="$2"; X="$3"; L="$4"
REPO="$(pwd)"; export REPO
. tests/lib/classify.sh
mkdir -p "$W/pre"
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
    [ -n "$_cc" ] && [ "$_cc" = "$VS_CTL_DECLARED" ] && exit 0
fi
for _n in $(vs_ctl_declared "tests/$g.sh"); do
    _c0=$(date +%s)
    CONTROL="$_n" tests/"$g".sh </dev/null > "$W/$g.ctl.$_n.out" 2>&1 && _cs=0 || _cs=$?
    _c1=$(date +%s)
    echo "$_cs $((_c1 - _c0))" > "$W/pre/$g.ctl.$_n.run"
done
exit 0
