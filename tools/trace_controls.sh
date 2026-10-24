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
set -u
O="${1:?out dir}"; shift; [ "$#" -gt 0 ] || { echo "usage: $0 <out dir> <gate>..." >&2; exit 2; }
command -v strace > /dev/null || { echo "trace_controls.sh: no strace on this host (Linux only)" >&2; exit 2; }
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO" || exit 3
case "$O" in /*) ;; *) O="$PWD/$O" ;; esac
mkdir -p "$O/st" "$O/out"; : > "$O/done.tsv"
{ echo "head $(git rev-parse HEAD) on $(hostname) $(date -u +%FT%TZ)"; git status --porcelain -uno; } > "$O/head.txt"
. tests/lib/controls.sh
one() {  # one <gate>: its controls, one after another
    g="$1"; . "$REPO/tests/lib/controls.sh"
    for c in $(vs_ctl_declared "tests/$g.sh"); do
        t0=$(date +%s)
        CONTROL="$c" timeout "${CTL_TIMEOUT:-2400}" strace -f -qq -y -o "$O/st/$g.$c.st" \
            -e trace=open,openat,creat,rename,renameat,renameat2 sh "tests/$g.sh" < /dev/null > "$O/out/$g.$c.out" 2>&1
        printf '%s\t%s\t%s\t%s\t%s\n' "$g" "$c" "$?" "$(( $(date +%s) - t0 ))" "$REPO" >> "$O/done.tsv"
    done
}
export -f one; export O REPO
printf '%s\n' "$@" | xargs -P "${JOBS:-8}" -I{} bash -c 'one "$1"' _ {}
echo "traced $(wc -l < "$O/done.tsv") control run(s) of $# gate(s) into $O"
