# jobs.sh — a host-derived, capped job count and a run pool, for gates whose emulator runs are independent
# (#334 item 2, 14z-211; the pattern #321 gave test_mame_wide, audit_merged_legacy and audit_guard_corpus). Source it.
#
# vs_jobs <VAR> <cap> <divisor> — when $VAR is unset or empty, set it to min(<cap>, CPUs / <divisor>), at least 1, so
#   a caller's value always wins and the default follows the host. CPUs: getconf _NPROCESSORS_ONLN, else sysctl, else 4.
# vs_pool_start / vs_pool_run <cmd> [args] / vs_pool_wait — run each command in the background, at most $VS_POOL_N
#   at a time (set by vs_pool_start <n>), in batches of n as the tree's other pooled gates do; vs_pool_wait waits for
#   the last batch. A pooled command's exit status is not collected: a gate judges each run by its ARTIFACT (its log's
#   END line, its output file), as it did serially. Every pooled run must write only paths of its own (its own sandbox,
#   its own log names) — nothing a sibling writes or reads.

vs_jobs() {
    eval "_vj=\${$1:-}"
    if [ -z "$_vj" ]; then
        _vjn="$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"
        _vj=$(( _vjn / $3 )); [ "$_vj" -le "$2" ] || _vj=$2; [ "$_vj" -ge 1 ] || _vj=1
        eval "$1=$_vj"
    fi
}

vs_pool_start() { VS_POOL_N="${1:-1}"; _vp_k=0; }
vs_pool_run() {
    "$@" &
    _vp_k=$(( _vp_k + 1 ))
    [ $(( _vp_k % VS_POOL_N )) -ne 0 ] || wait
}
vs_pool_wait() { wait; }
