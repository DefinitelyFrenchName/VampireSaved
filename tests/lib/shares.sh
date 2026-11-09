# tests/lib/shares.sh — WHAT A GATE SHARES, AND THE HOST CLAIM ON IT (#370, 14z-225; maintainer-ruled 2026-11-08 A1, B1,
# C1). Sourced by the gates that hold a registry token, by tools/mister_mra.sh and by tests/lib/desktop_session.sh.
#
#   vs_shares <script>          the tokens of the script's `# SHARES:` line, one a line; `none` for `# SHARES: none — …`;
#                               nothing (exit 1) when the line is missing or malformed. The grammar and its census are
#                               tests/lib/share_pool.py (the Python reader the pools import) and tests/test_shares.sh.
#   vs_shares_claim <who> <token>...
#                               claim each REGISTRY token (tests/shares.tsv) on this host for this shell's lifetime, in
#                               sorted order: an OS file lock (fcntl.flock) on $VS_SHARES_DIR/<token>.flock, taken and held
#                               by tests/lib/share_lock.py, a helper that lives exactly as long as this shell ($$) and is
#                               released by the kernel when it ends — so a crashed or killed holder frees its token, and
#                               no stale or owner-less lock can exist (maintainer-ruled 2026-11-09 "Kernel lock
#                               (Recommended)"; the mkdir lock it replaced failed five rule-checker rounds, 2026-11-09-1751
#                               to -1755). A live holder is waited for up to the token's wait seconds (tests/shares.tsv;
#                               VS_SHARES_WAIT overrides), then REFUSED: one line naming the holder and the wait, and exit 3
#                               (UNJUDGED under a control mode, red in a plain run). RE-ENTRANT: a shell whose environment
#                               names the token's live holder (VS_SHARES_HOLDER_<token, - as _>, exported by the claim)
#                               proceeds without claiming — a run nested under its holder (the desktop gate inside
#                               audit_dead_leg_linux, tools/mister_mra.sh inside a gate that claimed jtsim-scratch) would
#                               otherwise wait on its own parent and REFUSE. `self` and `none` are never claimed.
#   vs_shares_release           end this shell's lock helpers (call it from the EXIT trap); without it each helper ends
#                               within 0.2 s of this shell, so a missed release costs nothing.
# Every function here is safe under `set -e` (half of the holding gates run `set -eu`): a read that fails is guarded.
VS_SHARES_DIR="${VS_SHARES_DIR:-/tmp/vampire-saved-shares-$(id -u)}"
VS_SHARES_TAKEN=""

vs_shares() {
    awk 'NR == 1 { next } /^#/ { print; next } { exit }' "$1" \
        | awk '/^# SHARES: / { n++; l = $0 } END { if (n != 1) exit 1; print l }' \
        | sed -n -E -e 's/^# SHARES: none — .+$/none/p' -e 's/^# SHARES: ([a-z0-9-]+( [a-z0-9-]+)*)$/\1/p' \
        | tr ' ' '\n' | grep .
}

_vs_shares_wait() {  # the token's wait seconds from tests/shares.tsv (900 when the row has none)
    _vsw="$(awk -F'\t' -v t="$1" '!/^#/ && $1 == t {print $2; exit}' "${REPO:-.}/tests/shares.tsv" 2>/dev/null)" || _vsw=""
    case "$_vsw" in ''|*[!0-9]*) _vsw=900 ;; esac
    echo "${VS_SHARES_WAIT:-$_vsw}"
}

vs_shares_claim() {
    _vsc_who="$1"; shift
    mkdir -p "$VS_SHARES_DIR" 2>/dev/null || { echo "REFUSED: $_vsc_who — cannot create the host claim directory $VS_SHARES_DIR"; exit 3; }
    for _vsc_t in $(printf '%s\n' "$@" | sort -u); do
        case "$_vsc_t" in self|none) continue ;; esac
        _vsc_var="VS_SHARES_HOLDER_$(printf '%s' "$_vsc_t" | tr '-' '_')"
        eval "_vsc_h=\${$_vsc_var:-}"
        _vsc_lock="$VS_SHARES_DIR/$_vsc_t.flock"
        _vsc_o="$(cut -d' ' -f1 "$_vsc_lock" 2>/dev/null)" || _vsc_o=""
        if [ -n "$_vsc_h" ] && [ "$_vsc_o" = "$_vsc_h" ] && kill -0 "$_vsc_h" 2>/dev/null; then
            continue   # SHARES-NESTED: under the token's live holder
        fi
        _vsc_max="$(_vs_shares_wait "$_vsc_t")"   # SHARES-WAIT: the token's wait, tests/shares.tsv (VS_SHARES_WAIT overrides)
        _vsc_ready="$VS_SHARES_DIR/.ready.$$.$_vsc_t"; rm -f "$_vsc_ready"
        python3 "${REPO:-.}/tests/lib/share_lock.py" hold "$_vsc_lock" "$_vsc_max" "$$" "$_vsc_who" "$_vsc_ready" </dev/null >/dev/null 2>&1 &
        _vsc_p=$!
        _vsc_n=0; _vsc_cap=$(( (_vsc_max + 15) * 10 ))
        while [ ! -s "$_vsc_ready" ] && [ "$_vsc_n" -lt "$_vsc_cap" ] && kill -0 "$_vsc_p" 2>/dev/null; do sleep 0.1; _vsc_n=$((_vsc_n + 1)); done
        _vsc_r="$(cat "$_vsc_ready" 2>/dev/null)" || _vsc_r=""; rm -f "$_vsc_ready"
        case "$_vsc_r" in
        HELD*) VS_SHARES_TAKEN="$VS_SHARES_TAKEN $_vsc_p"; eval "$_vsc_var=\$\$; export $_vsc_var" ;;
        REFUSED*)
            set -- $_vsc_r
            echo "REFUSED: $_vsc_who — the shared resource '$_vsc_t' is held on this host by ${3:-?} ${4:-} ($_vsc_lock; waited ${2}s of $_vsc_max)"
            exit 3 ;;
        *)  kill "$_vsc_p" 2>/dev/null || :
            echo "REFUSED: $_vsc_who — the host claim on '$_vsc_t' did not answer (tests/lib/share_lock.py, $_vsc_lock)"
            exit 3 ;;
        esac
    done
    return 0
}

vs_shares_release() {
    for _vsr_p in $VS_SHARES_TAKEN; do kill "$_vsr_p" 2>/dev/null || :; done
    VS_SHARES_TAKEN=""
    return 0
}
