#!/bin/sh
# test_ctl_show_err.sh — A PERTURBED COPY THAT CRASHED IS NOT THE CONTROL FIRING (#310 group 5, 14z-215). ci_portable: no ROM, ~3 s.
#
# WHAT: tests/lib/controls.sh `vs_ctl_show_err <output> [<expected exception>|-] [<copy script>]`, which a gate calls on a
#   perturbed copy's captured output when the copy's run did not give the expected answer: a Python traceback is
#   re-printed at column 0 (tests/lib/classify.sh rule 4a reads the mode DIED), a headerless SyntaxError or the shell's own
#   error line about the copy script prints `NOT JUDGED:` (UNJUDGED); where a crash IS the honoured outcome, only the
#   named exception passes and anything else prints `NOT JUDGED:`. A copy's ordinary finding (a non-zero exit, no crash)
#   prints nothing and still reads HONOURED; an in-gate twin given a crashing copy prints CONTROL DEAD.
# HOW: a stub gate written into a scratch directory sources tests/lib/controls.sh (or a control's copy with one branch
#   disabled); its mode runs a perturbed copy — a Python script or a shell script chosen per case — and fails on it the
#   way the 21 group-5 gates do (the copy's tail in the FAIL line, then vs_ctl_show_err), and its plain run is the twin
#   (fired only on the copy's positive FOUND line and no crash). Each case runs it under CONTROL=copy-mode (or none) and
#   classifies the log with vs_classify_control exactly as both runners do.
# EXPECTS: (a) a copy raising KeyError on its main path, after printing a FOUND line, reads DIED; (b) the twin given that
#   copy, and the shell copy with a syntax error, print CONTROL DEAD; (c) a shell copy with a syntax error, one that aborts
#   on a `${VAR:?}` demand, and a Python copy with a SyntaxError read UNJUDGED; (d) with FileNotFoundError expected, a copy
#   raising it reads HONOURED and one raising KeyError, or exiting 1 with no exception, reads UNJUDGED; the near misses —
#   a Python and a shell copy exiting 1 on a FOUND line — read HONOURED and their twin fires; (e) this gate's own mode run
#   whose controls.sh line moved (tb-hidden, expected-blind) is REFUSED and reads UNJUDGED. Each control's disabled branch
#   misreads its case HONOURED (or the twin FIRED); refusal-reverted's pre-fix copy makes (e) read HONOURED.
# FOLLOWS: tests/lib/classify.sh tests/lib/controls.sh
#
# MUST-FIRE: shadow-tool: tb-hidden — a copy of tests/lib/controls.sh whose vs_ctl_show_err traceback branch (VSE-TB) is disabled must let the copy raising on its main path read HONOURED and its twin print CONTROL FIRED, and the gate must FAIL (mode: the cases run on that copy)
# MUST-FIRE: shadow-tool: sh-hidden — a copy whose shell-error branch (VSE-SH) is disabled must let the shell copy with a syntax error read HONOURED, and the gate must FAIL (mode: as above)
# MUST-FIRE: shadow-tool: expected-blind — a copy whose expected-exception test (VSE-EXPECTED) accepts any end must let a copy raising KeyError where FileNotFoundError is expected read HONOURED, and the gate must FAIL (mode: as above)
# MUST-FIRE: known-bad: refusal-reverted — this gate's copy with its mode-run refusal reverted to the pre-fix form (a plant that cannot be planted a plain FAIL exit 1) must let case (e)'s moved-line runs read HONOURED, and the gate must FAIL (mode: case (e) runs on that copy)
#
# WHY: #310 (the 14z-215 re-census, group 5): 21 gates ran a perturbed copy under a control mode and printed only `tail
#   -N`, an indented or joined excerpt, or nothing of its output, so a copy that CRASHED read as its perturbation caught —
#   HONOURED — and seven in-gate twins read the copy's silence as the control firing. Ruled 2026-10-31 (maintainer):
#   "a helper in tests/lib/controls.sh plus ~21 group-5 gates ... Each is proven by a planted case that must read DIED or
#   UNJUDGED".
# SHARES: none — its 4 control modes were write-traced apart (tests/controls_concurrent.txt, pilot:17f4f67f) and its plain run always pooled (#370 A1, 14z-225)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_ctl_show_err — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

CTLS="$REPO/tests/lib/controls.sh"; CLS="$REPO/tests/lib/classify.sh"
shadow_for() {  # shadow_for <control> <dir>: sets CTLS to that control's copy of controls.sh under <dir>; returns 1
    # when the branch's line moved (the caller decides: the plain run FAILs, a mode run REFUSES — #310, 14z-215 run -1510)
    mkdir -p "$2"
    python3 - "$REPO/tests/lib/controls.sh" "$2/ctl.sh" "$1" <<'PY' || return 1
import re, sys
src, out, name = sys.argv[1:4]
s = open(src).read()
pat, rep = {
    "tb-hidden": (r'if \[ -n "\$_vse_tb" \]; then   # VSE-TB', 'if false; then   # VSE-TB disabled'),
    "sh-hidden": (r'if \[ -n "\$_vse_syn" \] \|\| \[ -n "\$_vse_sh" \]; then   # VSE-SH', 'if false; then   # VSE-SH disabled'),
    "expected-blind": (r'if \[ -z "\$_vse_sh" \] && \[ -n "\$_vse_exc" \] && [^\n]*; then return 0; fi   # VSE-EXPECTED',
                       'return 0   # VSE-EXPECTED disabled'),
}[name]
t, n = re.subn(pat, rep, s)
if n != 1: sys.exit(f"{name}: its line matched {n} times")   # moved: no traceback (a crash here still raises)
open(out, "w").write(t)
PY
    CTLS="$2/ctl.sh"
}
# a mode whose plant cannot be planted is a REFUSAL (exit 3, read UNJUDGED), never the gate's FAIL (#310 group 6's form)
if [ -n "${VS_CTL:-}" ] && [ "$VS_CTL" != refusal-reverted ]; then
    shadow_for "$VS_CTL" "$W/mode" || { echo "REFUSED: $VS_CTL — could not disable its controls.sh line (it moved), so the plant did not apply and the mode judged nothing"; exit 3; }
fi

# THE PERTURBED COPIES: each prints what a real copy prints, then ends its own way
C="$W/copies"; mkdir -p "$C"
cat > "$C/crash_main.py" <<'EOF'
import sys
def main():
    print("FOUND: a partial result, printed before the crash")
    rows = {}
    return rows["missing"]   # KeyError on the MAIN path, not at import
if __name__ == "__main__":
    sys.exit(main())
EOF
cat > "$C/finding.py" <<'EOF'
import sys
print("FOUND: the perturbation, caught")
sys.exit(1)
EOF
cat > "$C/fnf.py" <<'EOF'
import sys
def main():
    print("reading the generator notes")
    return len(open("/nonexistent-310-group5/gen.log").read())
if __name__ == "__main__":
    sys.exit(main())
EOF
printf 'import sys\ndef main(:\n    pass\n' > "$C/syntax.py"
printf '#!/bin/sh\necho "FOUND: a partial result"\nif then; fi\n' > "$C/copy_syntax.sh"
printf '#!/bin/sh\necho "FOUND: a partial result"\n: "${%s:?the copy needs it}"\necho done\n' UNSET_IN_THE_COPY > "$C/copy_abort.sh"   # the demand written through %s, so test_demand_after_trap does not read it as this gate's own
printf '#!/bin/sh\necho "FOUND: the perturbation, caught"\nexit 1\n' > "$C/copy_finding.sh"

# THE STUB GATE: a group-5 gate's shape. COPY the perturbed copy; EXPECT the honoured exception (or -)
cat > "$W/g_copy.sh" <<'EOF'
#!/bin/sh
# g_copy.sh — a stub gate whose mode runs a perturbed copy (tests/test_ctl_show_err.sh)
# MUST-FIRE: perturbed-copy: copy-mode — stub
set -u
. "$CTLS"; vs_ctl_mode "$0"
fail=0
run_copy() { case "$COPY" in *.py) python3 "$COPY" > "$SW/copy.out" 2>&1 ;; *) sh "$COPY" > "$SW/copy.out" 2>&1 ;; esac; }
if vs_ctl_is copy-mode; then
    if run_copy; then echo "  ok    the copy found nothing"
    else echo "  FAIL  the copy's run: $(tail -1 "$SW/copy.out")"; vs_ctl_show_err "$SW/copy.out" "${EXPECT:--}" "$COPY" || true; fail=1; fi
    [ "$fail" = 1 ] && { echo "FAIL: g_copy (control mode: copy-mode)"; exit 1; }
    vs_ctl_left_green copy-mode "FAIL: g_copy — control mode copy-mode left the gate green"
fi
run_copy || :
if grep -q '^FOUND: ' "$SW/copy.out" && vs_ctl_show_err "$SW/copy.out" "${EXPECT:--}" "$COPY"; then vs_ctl_fired copy-mode "the copy reports: $(grep -m1 '^FOUND: ' "$SW/copy.out")"
else vs_ctl_dead copy-mode "the copy gave no FOUND line, or crashed" || fail=1; fi
[ "$fail" = 0 ] && echo "PASS: g_copy" || echo "FAIL: g_copy"; exit "$fail"
EOF
chmod +x "$W/g_copy.sh"
_n=0
# #369 (14z-224): the stubs stand for gates on the shrink-only debt list tests/expected/ctl_caught_debt.tsv, the
# pre-#369 fall-through these cases were written for; a scratch copy of the list naming them reaches the stub run and
# the classifier through REPO (the tracked list is never written). tests/test_control_classifier.sh holds the strict path.
mkdir -p "$W/debt/tests/expected"; { cat "$REPO/tests/expected/ctl_caught_debt.tsv"; echo g_copy.sh; } > "$W/debt/tests/expected/ctl_caught_debt.tsv"
run_stub() {  # run_stub <mode or -> <copy> [expected exception]: runs the stub gate; sets LOG, ST, CLASS
    _n=$((_n + 1)); _m="$1"; [ "$_m" = - ] && _m=""
    SW="$W/s$_n"; mkdir -p "$SW"; LOG="$SW.log"
    env CONTROL="$_m" CTLS="$CTLS" SW="$SW" COPY="$C/$2" EXPECT="${3:--}" REPO="$W/debt" sh "$W/g_copy.sh" > "$LOG" 2>&1 </dev/null && ST=0 || ST=$?
    CLASS="$(REPO="$W/debt" sh -c '. "$1"; vs_classify_control "$2" "$3" "$4" "$5"; echo "$VS_CTL_EXEC"' _ "$CLS" "$ST" "$LOG" "$W/g_copy.sh" "$_m")"
}
expect() {  # expect <label> <class> <copy> [expected exception]: the mode run's class
    _l="$1"; _c="$2"; shift 2; run_stub copy-mode "$@"
    [ "$CLASS" = "$_c" ] && ok "$_l -> $_c" || bad "$_l -> $CLASS (exit $ST), expected $_c: $(command grep -a -m1 'NOT JUDGED\|Traceback\|FAIL' "$LOG" | cut -c1-100)"
}
twin() {  # twin <label> <FIRED|DEAD> <copy>: the plain run's in-gate twin line
    _l="$1"; _w="$2"; shift 2; run_stub - "$@"
    if command grep -qa "^CONTROL $_w: copy-mode " "$LOG"; then ok "$_l: the twin prints CONTROL $_w"
    else bad "$_l: the twin printed $(command grep -a -m1 '^CONTROL ' "$LOG" | cut -c1-90), expected CONTROL $_w"; fi
}

cases() {
    echo "== (a) a Python copy that raises on its main path"
    expect "a KeyError after a FOUND line"                          DIED     crash_main.py
    expect "  near miss: a copy exiting 1 on its FOUND line"         HONOURED finding.py
    echo "== (b) the in-gate twin given the same copies"
    twin   "the copy raising on its main path"                       DEAD     crash_main.py
    twin   "the shell copy with a syntax error"                      DEAD     copy_syntax.sh
    twin   "  near miss: the copy exiting 1 on its FOUND line"       FIRED    finding.py
    echo "== (c) a copy that never ran: the shell's own error about it, a SyntaxError"
    expect "a shell copy with a syntax error"                        UNJUDGED copy_syntax.sh
    expect "a shell copy aborting on an unset-variable demand"        UNJUDGED copy_abort.sh
    expect "a Python copy with a SyntaxError"                        UNJUDGED syntax.py
    expect "  near miss: a shell copy exiting 1 on its FOUND line"   HONOURED copy_finding.sh
    echo "== (d) a crash that IS the honoured outcome: FileNotFoundError expected"
    expect "the copy raising FileNotFoundError"                      HONOURED fnf.py FileNotFoundError
    expect "a copy raising KeyError instead"                         UNJUDGED crash_main.py FileNotFoundError
    expect "a copy exiting 1 with no exception"                      UNJUDGED finding.py FileNotFoundError
}
cases
revert_refusal() {  # revert_refusal <out>: this gate with its mode-run refusal reverted to the pre-fix FAIL exit 1
    python3 - "$REPO/tests/test_ctl_show_err.sh" "$1" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
t, n = re.subn(r'\|\| \{ echo "REFUSED: \$VS_CTL — could not disable its controls\.sh line \(it moved\)[^\n]*exit 3; \}',
               lambda m: '|| { echo "FAIL: test_ctl_show_err — could not disable $VS_CTL\'s line (it moved)"; exit 1; }', s)
if n != 1: sys.exit(f"refusal line matched {n} times")
open(sys.argv[2], "w").write(t)
PY
}
MVSRC="$REPO/tests/test_ctl_show_err.sh"
if vs_ctl_is refusal-reverted; then   # the copy (e) runs: the mode-run refusal reverted to the pre-fix FAIL exit 1
    MVSRC="$W/reverted_gate.sh"
    revert_refusal "$MVSRC" || { echo "REFUSED: refusal-reverted — the refusal line was not found to revert, so the plant did not apply and the mode judged nothing"; exit 3; }
fi
echo "== (e) a mode whose plant cannot be planted (its controls.sh line moved) is REFUSED, read UNJUDGED, never HONOURED"
moved_run() {  # moved_run <gate copy> <control> <sed on controls.sh>: the copy run with a controls.sh whose line moved; sets _got, _st, _mv
    _mv="$W/mv_$2_$(basename "$1" .sh)"; mkdir -p "$_mv/tests/lib"; cp "$1" "$_mv/tests/test_ctl_show_err.sh"
    cp "$REPO/tests/lib/classify.sh" "$_mv/tests/lib/"; sed "$3" "$REPO/tests/lib/controls.sh" > "$_mv/tests/lib/controls.sh"
    mkdir -p "$_mv/tests/expected"; cp "$W/debt/tests/expected/ctl_caught_debt.tsv" "$_mv/tests/expected/"   # the copy is listed, as this gate is (#369)
    env CONTROL="$2" sh "$_mv/tests/test_ctl_show_err.sh" > "$_mv.log" 2>&1 </dev/null && _st=0 || _st=$?
    _got="$(REPO="$W/debt" sh -c '. "$1"; vs_classify_control "$2" "$3" "$4" "$5"; echo "$VS_CTL_EXEC"' _ "$CLS" "$_st" "$_mv.log" "$_mv/tests/test_ctl_show_err.sh" "$2")"
}
moved() {  # moved <label> <control> <class> <sed on controls.sh>: this gate (or the mode's reverted copy) with a moved line
    moved_run "$MVSRC" "$2" "$4"
    [ "$_got" = "$3" ] && ok "$1 -> $3" || bad "$1 -> $_got (exit $_st), expected $3: $(command grep -a -m1 'REFUSED\|FAIL\|NOT JUDGED' "$_mv.log" | cut -c1-100)"
}
moved "tb-hidden with its VSE-TB marker gone"                    tb-hidden      UNJUDGED 's/   # VSE-TB$//'
moved "expected-blind with its VSE-EXPECTED marker gone"         expected-blind UNJUDGED 's/   # VSE-EXPECTED$//'

if [ -n "${VS_CTL:-}" ]; then
    [ "$fail" = 0 ] && echo "PASS: test_ctl_show_err" || echo "FAIL: test_ctl_show_err (control mode $VS_CTL)"; exit "$fail"
fi
echo "== controls: each branch disabled must misread its case"
fire() {  # fire <control> <label> <expected misread: class | FIRED> <copy> [expected exception]
    _ctl="$1"; _lab="$2"; _want="$3"; shift 3
    shadow_for "$_ctl" "$W/c_$_ctl" || { echo "FAIL: test_ctl_show_err — could not disable $_ctl's line (it moved)"; exit 1; }
    if [ "$_want" = FIRED ]; then run_stub - "$@"; _got="$(command grep -a -m1 '^CONTROL [A-Z]*: copy-mode' "$LOG" | sed 's/^CONTROL \([A-Z]*\):.*/\1/')"
    else run_stub copy-mode "$@"; _got="$CLASS"; fi
    CTLS="$REPO/tests/lib/controls.sh"
    if [ "$_got" = "$_want" ]; then vs_ctl_fired "$_ctl" "with the branch disabled $_lab reads $_got"
    else vs_ctl_dead "$_ctl" "$_lab read '$_got' with the branch disabled, not $_want"; fail=1; fi
}
fire tb-hidden      "the copy raising on its main path"            HONOURED crash_main.py
fire tb-hidden      "its twin"                                     FIRED    crash_main.py
fire sh-hidden      "the shell copy with a syntax error"           HONOURED copy_syntax.sh
fire expected-blind "a KeyError where FileNotFoundError is expected" HONOURED crash_main.py FileNotFoundError
# refusal-reverted's twin: case (e)'s moved-line run on this gate's copy with the pre-fix FAIL exit 1 must read HONOURED
if revert_refusal "$W/reverted_twin.sh" 2> "$W/reverted_twin.err"; then
    moved_run "$W/reverted_twin.sh" tb-hidden 's/   # VSE-TB$//'
    if [ "$_got" = HONOURED ]; then vs_ctl_fired refusal-reverted "with the refusal reverted a moved-line mode run reads HONOURED"
    else vs_ctl_dead refusal-reverted "with the refusal reverted a moved-line mode run read '$_got', not HONOURED"; fail=1; fi
else vs_ctl_dead refusal-reverted "the refusal line was not found to revert: $(tail -1 "$W/reverted_twin.err")"; fail=1; fi

[ "$fail" = 0 ] && echo "PASS: test_ctl_show_err — a crashed perturbed copy reads DIED or UNJUDGED and its twin DEAD; a finding stays HONOURED; an expected exception passes only as itself" || echo "FAIL: test_ctl_show_err"
exit "$fail"
