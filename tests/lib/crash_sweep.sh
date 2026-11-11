# tests/lib/crash_sweep.sh — plant a crash in what a gate's run executes, and classify the run (#310, 14z-218).
# Sourced (POSIX sh). Used by tests/test_crash_sweep.sh; the discovery rigs of 14z-216/218 (build/agent21[68]/t310/) are
# where it came from.
#
#   cs_mkshim <dir>          writes the planted-crash shims python3, sh and bash into <dir>. Each passes every call through
#                            to the real interpreter, except the CS_NTH-th call (counting only calls whose first line of
#                            arguments matches the ERE CS_RE, for the interpreter CS_KIND names; CS_NTH=0 plants nothing
#                            and only counts) which it turns into a crash:
#                              py -> a Python process raising RuntimeError from 30 nested frames (a ~35-line traceback,
#                                    whose `Traceback` header a gate's `tail -N` excerpt drops). No file is written.
#                              sh -> the script the call names (its first non-option argument) gets a syntax error after
#                                    its first line, so the real shell aborts naming the copy. A file TRACKED in the
#                                    repository (CS_REPO) is never edited, and is not COUNTED (so nth addresses only the
#                                    plantable calls: a runner gate's shadow copy, never the tracked runner it also calls);
#                                    the shim resolves links first (a mirror's link is the tracked file).
#                              pyx -> any Python PROCESS, however started (a gate's `subprocess.run([sys.executable, …])`
#                                    never meets a PATH shim): <dir>/pyx/sitecustomize.py, on PYTHONPATH for a pyx run,
#                                    matches the ERE against `" ".join(sys.argv)` at interpreter start and, on the planted
#                                    count, prints the same 30-frame traceback and exits 1 (an exception raised inside
#                                    sitecustomize is swallowed by site.py, so it cannot simply raise). A process started
#                                    with -I, -E or -S is not reached.
#                            Every match is counted in $CS_CNT; each planted call's first line is appended to $CS_CNT.hits.
#                            With VS_TRACE_FILE set (a tracing run, CS_KIND unset), the sitecustomize appends
#                            `pyx<TAB><argv>` for every Python process to that file.
#   cs_run <gate copy> <mode|PLAIN> <kind py|sh|pyx> <ere> <nth> <shim dir> <base>   (nth 0: count only, plant nothing)
#                            runs the copy (CONTROL=<mode>, or no CONTROL for PLAIN) under the shim with that plant, the
#                            output in <base>.log, the fired site keys in <base>.sites (tools/crash_sweep.py's tag), and
#                            sets CS_CLASS (vs_classify_control's verdict for a mode, vs_classify's for PLAIN), CS_EXIT,
#                            CS_HITS (planted calls), CS_SITES (comma-joined fired keys) and CS_SECS.
# The gate and the shims need CS_REPO (the repository root) and CS_PY (the real python3, an absolute path).
cs_mkshim() {
    mkdir -p "$1"
    cat > "$1/python3" <<'EOF'
#!/bin/sh
# tests/lib/crash_sweep.sh's planted-crash shim (#310): python3
if [ "${CS_KIND:-}" = py ] && printf '%s\n' "$*" | head -1 | grep -qE -- "$CS_RE"; then
    n=$(( $(cat "$CS_CNT" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$CS_CNT"
    if [ "$n" = "$CS_NTH" ]; then
        printf '%s\n' "$*" | head -1 | cut -c1-200 >> "$CS_CNT.hits"
        exec "$CS_PY" -c 'exec("".join("def f%d():\n    f%d()\n" % (i, i + 1) for i in range(30)) + "def f30():\n    raise RuntimeError(\"a planted crash (test_crash_sweep, #310)\")\nf0()\n")'
    fi
fi
exec "$CS_PY" "$@"
EOF
    for _cs_i in sh bash; do
        printf '#!/bin/sh\n# tests/lib/crash_sweep.sh'"'"'s planted-crash shim (#310): %s\n_real=/bin/%s\n' "$_cs_i" "$_cs_i" > "$1/$_cs_i"
        cat >> "$1/$_cs_i" <<'EOF'
if [ "${CS_KIND:-}" = sh ] && printf '%s\n' "$*" | head -1 | grep -qE -- "$CS_RE"; then
    _s=""; for _a in "$@"; do case "$_a" in -*) ;; *) _s="$_a"; break ;; esac; done
    _abs="$("$CS_PY" -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$_s")"
    _trk=0; case "$_abs" in "$CS_REPO"/*) git -C "$CS_REPO" ls-files --error-unmatch -- "$_abs" >/dev/null 2>&1 && _trk=1 ;; esac
    # a TRACKED script is never planted, so it is not COUNTED either: nth addresses the plantable calls (14z-218)
    case "$_trk:$_abs" in 1:*|*:/) _cs_skip=1 ;; *) _cs_skip=0 ;; esac
    [ "$_cs_skip" = 0 ] && { n=$(( $(cat "$CS_CNT" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$CS_CNT"; }
    if [ "$_cs_skip" = 0 ]; then n="$n"; else n=-; fi
    if [ "$n" = "$CS_NTH" ]; then
        case "$_trk:$_abs" in
            1:*|*:/) printf 'REFUSED %s\n' "$_s" >> "$CS_CNT.hits" ;;
            *) if [ -f "$_s" ]; then
                   { head -1 "$_s"; echo 'if then   # a planted syntax error (test_crash_sweep, #310)'; tail -n +2 "$_s"; } > "$_s.csplant" \
                       && cat "$_s.csplant" > "$_s" && rm -f "$_s.csplant"
                   printf '%s\n' "$*" | head -1 | cut -c1-200 >> "$CS_CNT.hits"
               else printf 'NOFILE %s\n' "$_s" >> "$CS_CNT.hits"; fi ;;
        esac
    fi
fi
exec "$_real" "$@"
EOF
    done
    chmod +x "$1/python3" "$1/sh" "$1/bash"
    mkdir -p "$1/pyx"
    cat > "$1/pyx/sitecustomize.py" <<'EOF'
# tests/lib/crash_sweep.sh's planted-crash hook (#310): any Python process (kind pyx), and the tracer's pyx lines
import os, sys
def _cs_pyx():
    argv = " ".join(sys.argv)
    tf = os.environ.get("VS_TRACE_FILE")
    if tf and not os.environ.get("CS_KIND"):
        with open(tf, "a") as f:
            f.write("pyx\t" + argv.split("\n")[0][:240] + "\n")
        return
    if os.environ.get("CS_KIND") != "pyx":
        return
    import re
    if not re.search(os.environ.get("CS_RE", "^$"), argv.split("\n")[0]):
        return
    import fcntl
    cnt = os.environ["CS_CNT"]
    with open(cnt + ".lock", "a") as lk:
        fcntl.flock(lk, fcntl.LOCK_EX)
        try:
            n = int(open(cnt).read().strip() or 0) + 1
        except (OSError, ValueError):
            n = 1
        with open(cnt, "w") as f:
            f.write("%d\n" % n)
    if str(n) != os.environ.get("CS_NTH"):
        return
    with open(cnt + ".hits", "a") as f:
        f.write(argv.split("\n")[0][:200] + "\n")
    import traceback
    ns = {}
    exec("".join("def f%d():\n    f%d()\n" % (i, i + 1) for i in range(30))
         + "def f30():\n    raise RuntimeError('a planted crash (test_crash_sweep, #310)')\n", ns)
    try:
        ns["f0"]()
    except RuntimeError:
        traceback.print_exc()
    sys.stderr.flush()
    os._exit(1)
_cs_pyx()
EOF
}

cs_run() {
    _cs_g="$1"; _cs_m="$2"; _cs_b="$7"
    rm -f "$_cs_b.cnt" "$_cs_b.cnt.hits" "$_cs_b.sites"
    _cs_pp="${PYTHONPATH:-}"; [ "$3" = pyx ] && _cs_pp="$6/pyx${PYTHONPATH:+:$PYTHONPATH}"
    _cs_t0=$(date +%s)
    if [ "$_cs_m" = PLAIN ]; then
        env -u CONTROL PATH="$6:$PATH" PYTHONPATH="$_cs_pp" CS_KIND="$3" CS_RE="$4" CS_NTH="$5" CS_CNT="$_cs_b.cnt" VS_SWEEP_SITES="$_cs_b.sites" \
            timeout "${CS_TIMEOUT:-1800}" /bin/sh "$_cs_g" > "$_cs_b.log" 2>&1 < /dev/null; CS_EXIT=$?
        vs_classify "$CS_EXIT" "$_cs_b.log" 80 "$_cs_g"; CS_CLASS="$VS_VERDICT"
    else
        env PATH="$6:$PATH" PYTHONPATH="$_cs_pp" CS_KIND="$3" CS_RE="$4" CS_NTH="$5" CS_CNT="$_cs_b.cnt" VS_SWEEP_SITES="$_cs_b.sites" CONTROL="$_cs_m" \
            timeout "${CS_TIMEOUT:-1800}" /bin/sh "$_cs_g" > "$_cs_b.log" 2>&1 < /dev/null; CS_EXIT=$?
        vs_classify_control "$CS_EXIT" "$_cs_b.log" "$_cs_g" "$_cs_m"; CS_CLASS="$(vs_ctl_class_word)"   # #369 piece 5: UNJUDGED-CAUGHT when only vs_ctl_caught spoke
    fi
    CS_SECS=$(( $(date +%s) - _cs_t0 ))
    CS_HITS="$(grep -cv '^REFUSED\|^NOFILE' "$_cs_b.cnt.hits" 2>/dev/null)"; CS_HITS="${CS_HITS:-0}"
    CS_SITES="$(sort -u "$_cs_b.sites" 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
}
