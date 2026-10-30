#!/bin/sh
# audit_pool_drop.sh — EVERY GATE THAT POOLS ITS EMULATOR RUNS STILL FAILS WHEN THE POOL LOSES ONE (#334, 14z-212).
#
# WHAT: each gate that runs a list of independent emulator runs through tests/lib/jobs.sh's pool still FAILS when one
#   of those runs never happens — the failure mode rule-checker run 2026-10-29-1376 (Q4) named: "an edited gate can
#   no longer fail". vs_pool_run does not collect a run's exit status; the gate must see the lost run in its artifacts.
# HOW: the subject set is every tests/*.sh that calls vs_pool_run (this gate excepted). Each runs twice as
#   tests/run_all_emulator.sh runs it — its tests/ci_emulator.tsv arguments, %PLACEHOLDER%s expanded to the same build
#   set (MERGED/DON/HUI/PYR/STOCK, the runner's defaults), VAR=value tokens as environment, its row's timeout, stdin
#   closed, exit status as verdict — but called directly (the runner's own start-up costs ~100 s a call, measured
#   14z-212): BASE as registered, and DROP with VS_POOL_DROP_FIRST=1, under which vs_pool_run drops the first run of
#   each shell unrun and logs it. A gate passes this audit when BASE exits 0 and DROP does not, with at least one run
#   dropped; the BASE leg is what separates a DROP FAIL caused by the lost run from one caused by anything else.
#   It follows build/manifest/, tests/ and tools/ whole: its verdict is every pooled gate's, and what they read.
# EXPECTS: every subject separates. Measured 14z-212 on the Mac (build/agent212/t334/dropctl/): 59 of 61 separated;
#   audit_type_writes and audit_id_writers PASSED with a run dropped (each globbed the traces it found) and now name
#   the legs they start.
# NOT TESTED: a run lost after it started (a crash mid-run, a truncated trace) — each gate's own END-line and
#   completeness checks cover that, not this audit; a drop of any run but each shell's first.
# MUST-FIRE: known-bad: hook-off — the DROP leg runs without VS_POOL_DROP_FIRST, so nothing is dropped and the first subject (or POOL_DROP_GATES's) must read NOT-DROPPED, never "separates" (in-gate: a two-command pool with the hook on must run exactly one; as a mode the subjects' DROP legs run unhooked and the gate FAILs)
# FOLLOWS: build/manifest/ tests/ tools/
#
# expand() below copies run_all_emulator.sh's: a placeholder it does not know reaches the gate unexpanded, and the
# BASE leg FAILs, naming it.
#
# SHEET: none — judges the gates' own verdicts on our tree; no reference leg and no frozen reference values
#
# ON-DEMAND: every pooled gate twice (~2 x 4,200 s on ERIS, 14z-212). POOL_DROP_GATES="<gate> ..." limits the set.
# Usage: ROMDIR=... [POOL_DROP_GATES="..."] [OUT=<dir>] tests/audit_pool_drop.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
W="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/pooldrop.XXXXXX")}"
[ -n "$W" ] && mkdir -p "$W" && W="$(cd "$W" && pwd)" && [ -n "$W" ] || { echo "FAIL: audit_pool_drop — no work directory (mktemp or OUT failed)"; exit 2; }
[ -n "${OUT:-}" ] || trap 'rm -rf "$W"' EXIT
fail=0
MERGED="${MERGED:-build/m3b_merged31}"; DON="${DON:-build/don_m27}"; HUI="${HUI:-build/hui61}"
PYR="${PYR:-build/pyron46}"; STOCK="${STOCK:-build/m5_stock22}"
expand() {  # expand <string> — tests/run_all_emulator.sh's %PLACEHOLDER% vocabulary, the same defaults
    printf '%s' "$1" \
      | sed -e "s|%MERGED_RP%|$MERGED/rompath|g" -e "s|%MERGED%|$MERGED|g" \
            -e "s|%DON_RP%|$DON/rompath|g"       -e "s|%DON%|$DON|g" \
            -e "s|%HUI_RP%|$HUI/rompath|g"       -e "s|%HUI%|$HUI|g" \
            -e "s|%PYR_RP%|$PYR/rompath|g"       -e "s|%PYR%|$PYR|g" \
            -e "s|%STOCK_RP%|$STOCK/rompath|g"   -e "s|%STOCK%|$STOCK|g"
}
leg() {  # leg <gate> <log> [VAR=value ...] — the gate as the runner invokes it; prints its exit status
    _lg="$1"; _ll="$2"; shift 2
    _env=""; _pos=""
    for _tok in $(expand "$_args"); do
        [ "$_tok" = "-" ] && continue
        case "$_tok" in [A-Z_][A-Z0-9_]*=*) _env="$_env $_tok" ;; *) _pos="$_pos $_tok" ;; esac
    done
    # shellcheck disable=SC2086
    env $_env "$@" timeout -k 30 "$_tmo" "tests/$_lg.sh" $_pos < /dev/null > "$_ll" 2>&1; echo $?
}

echo "== 1. the hook (in-gate control hook-off's ground truth)"
mkdir -p "$W/hook"
( . "$REPO/tests/lib/jobs.sh"; VS_POOL_DROP_FIRST=1 VS_POOL_DROP_LOG="$W/hook/on.log"
  vs_pool_start 2; vs_pool_run touch "$W/hook/on_a"; vs_pool_run touch "$W/hook/on_b"; vs_pool_wait )
( . "$REPO/tests/lib/jobs.sh"
  vs_pool_start 2; vs_pool_run touch "$W/hook/off_a"; vs_pool_run touch "$W/hook/off_b"; vs_pool_wait )
_on="$(ls "$W/hook" | grep -c '^on_')"; _off="$(ls "$W/hook" | grep -c '^off_')"
if [ "$_on" = 1 ] && [ -f "$W/hook/on_b" ] && [ "$_off" = 2 ] && grep -q 'POOL-DROP' "$W/hook/on.log" 2>/dev/null; then
    vs_ctl_fired hook-off "with the hook on, a two-command pool ran one (the second) and logged the drop; off, it ran both"
else
    vs_ctl_dead hook-off "the hook did not drop exactly the first run (on: $_on run, off: $_off run)" || fail=1
fi

if [ -n "${POOL_DROP_GATES:-}" ]; then GATES="$POOL_DROP_GATES"
else GATES="$(grep -l 'vs_pool_run' tests/*.sh | sed 's|^tests/||; s|\.sh$||' | grep -vx audit_pool_drop)"; fi
vs_ctl_is hook-off && GATES="$(printf '%s\n' $GATES | head -1)"
echo "== 2. each pooled gate, BASE then DROP ($(printf '%s\n' $GATES | wc -l | tr -d ' ') gates)"
n_sep=0; n_bad=0
for g in $GATES; do
    row="$(awk -F'\t' -v g="$g" '$1 == g && $0 !~ /^#/ {print; exit}' tests/ci_emulator.tsv)"
    [ -n "$row" ] || { echo "  FAIL  $g: no tests/ci_emulator.tsv row"; fail=1; n_bad=$((n_bad + 1)); continue; }
    _args="$(printf '%s' "$row" | cut -f5)"; _tmo="$(printf '%s' "$row" | cut -f7)"
    case "$_tmo" in ""|-) _tmo=5400 ;; esac
    : > "$W/$g.dropped"
    rb="$(leg "$g" "$W/base_$g.log")"
    if vs_ctl_is hook-off; then rd="$(leg "$g" "$W/drop_$g.log")"
    else rd="$(leg "$g" "$W/drop_$g.log" VS_POOL_DROP_FIRST=1 VS_POOL_DROP_LOG="$W/$g.dropped")"; fi
    nd="$(grep -c 'POOL-DROP' "$W/$g.dropped" 2>/dev/null)"; [ -n "$nd" ] || nd=0
    if [ "$rb" != 0 ]; then r="BASE exit $rb: cannot separate ($(tail -1 "$W/base_$g.log" | cut -c1-100))"
    elif [ "$nd" = 0 ]; then r="NOT-DROPPED (DROP exit $rd)"
    elif [ "$rd" = 0 ]; then r="DROP PASSES with $nd run(s) lost"
    else r=separates; fi
    if [ "$r" = separates ]; then echo "  ok    $g: BASE exit 0, DROP exit $rd ($nd dropped)"; n_sep=$((n_sep + 1))
    else echo "  FAIL  $g: $r"; n_bad=$((n_bad + 1)); fail=1; fi
done
echo "  $n_sep separate, $n_bad do not"
if vs_ctl_is hook-off; then
    [ "$n_sep" = 0 ] || vs_ctl_dead hook-off "a subject separated with the hook off" || fail=1
    exit 1
fi
if [ "$fail" = 0 ]; then echo "PASS: every pooled gate FAILs when the pool loses a run ($n_sep)"; else echo "FAIL: audit_pool_drop"; fi
exit $fail
