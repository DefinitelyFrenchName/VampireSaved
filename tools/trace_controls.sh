#!/bin/bash
# trace_controls.sh — THE WRITE TRACE OF EVERY CONTROL MODE OF THE NAMED GATES (#315, 14z-207; lane S's method, #312).
# Each declared must-fire control <c> of each gate <g> runs as `CONTROL=<c> sh tests/<g>.sh` under
# `strace -f -qq -y -e trace=open,openat,creat,rename,renameat,renameat2` (with -y a successful open prints the absolute
# path of the fd it returns), from the repository root this script lives in. A gate's controls run one after another;
# up to JOBS gates (default 8) run at once. Linux only (strace). tools/controls_overlap.py scores the traces; a gate
# whose controls write no path a sibling writes or reads earns a row in tests/controls_concurrent.txt, with
# `git hash-object tests/<g>.sh` as its traced blob (tests/test_controls_concurrent.sh holds the list to it).
# usage: ROMDIR=... tools/trace_controls.sh <out dir> <gate>...     writes <out>/st/<g>.<c>.st, <out>/out/<g>.<c>.out,
#        <out>/done.tsv (gate, control, exit, seconds, root) and <out>/head.txt (the commit and git status traced)
#   EMULATOR GATES (#321, 14z-210): CMDS=<gate<TAB>expanded args<TAB>timeout file> runs each control as the emulator
#   runner would (CTL_TMO_MULT times the row's timeout, default 2); STRACE_OPTS=--seccomp-bpf filters in the kernel. The
#   scored list is tests/controls_concurrent_emu.txt (first trace: PILOT at 688edef8, 200 controls of 61 gates, 15,664 s).
set -u
CMDS="${CMDS:-}"; CTL_TMO_MULT="${CTL_TMO_MULT:-2}"; CTL_TIMEOUT="${CTL_TIMEOUT:-2400}"; STRACE_OPTS="${STRACE_OPTS:-}"
O="${1:?out dir}"; shift; [ "$#" -gt 0 ] || { echo "usage: $0 <out dir> <gate>..." >&2; exit 2; }
command -v strace > /dev/null || { echo "trace_controls.sh: no strace on this host (Linux only)" >&2; exit 2; }
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO" || exit 3
case "$O" in /*) ;; *) O="$PWD/$O" ;; esac
mkdir -p "$O/st" "$O/out"; : > "$O/done.tsv"
{ echo "head $(git rev-parse HEAD) on $(hostname) $(date -u +%FT%TZ)"; git status --porcelain -uno; } > "$O/head.txt"
. tests/lib/controls.sh
one() {  # one <gate>: its controls, one after another
    g="$1"; . "$REPO/tests/lib/controls.sh"
    # EMULATOR ROWS (14z-210, #321): CMDS=<file> of gate<TAB>expanded args<TAB>timeout runs each control as
    # tests/run_all_emulator.sh does: VAR=value tokens as environment, the rest positional, the script executed directly,
    # the row's timeout (times CTL_TMO_MULT, default 2) under timeout -k 30. Without CMDS: the static form, as before.
    _env=""; _pos=""; _tmo="${CTL_TIMEOUT:-2400}"; _run="sh tests/$g.sh"
    if [ -n "${CMDS:-}" ]; then
        _row="$(awk -F'\t' -v g="$g" '$1 == g' "$CMDS")"
        for _tok in $(printf '%s' "$_row" | cut -f2); do
            [ "$_tok" = "-" ] && continue
            case "$_tok" in [A-Z_][A-Z0-9_]*=*) _env="$_env $_tok" ;; *) _pos="$_pos $_tok" ;; esac
        done
        _t="$(printf '%s' "$_row" | cut -f3)"; case "$_t" in ""|-) _t=5400 ;; esac
        _tmo=$(( _t * ${CTL_TMO_MULT:-2} )); _run="tests/$g.sh"
    fi
    for c in $(vs_ctl_declared "tests/$g.sh"); do
        t0=$(date +%s)
        # shellcheck disable=SC2086
        env $_env CONTROL="$c" timeout -k 30 "$_tmo" strace ${STRACE_OPTS:-} -f -qq -y -o "$O/st/$g.$c.st" \
            -e trace=open,openat,creat,rename,renameat,renameat2 $_run $_pos < /dev/null > "$O/out/$g.$c.out" 2>&1
        printf '%s\t%s\t%s\t%s\t%s\n' "$g" "$c" "$?" "$(( $(date +%s) - t0 ))" "$REPO" >> "$O/done.tsv"
    done
}
export -f one; export O REPO CMDS CTL_TMO_MULT CTL_TIMEOUT STRACE_OPTS
printf '%s\n' "$@" | xargs -P "${JOBS:-8}" -I{} bash -c 'one "$1"' _ {}
echo "traced $(wc -l < "$O/done.tsv") control run(s) of $# gate(s) into $O"
