#!/bin/sh
# test_tmp_hygiene.sh — EVERY TEMPORARY A TOOL OR GATE MAKES IS REMOVED WHEN ITS MAKER EXITS (#303, 14z-207). ci_portable: no ROM, ~2 s.
#
# WHAT: tools/tmp_hygiene.py's static census of tools/*.py, tests/*.py, tests/lib/*.py and tests/*.sh finds no
#   uncleaned temporary: every python mkdtemp/mkstemp/NamedTemporaryFile(delete=False) registers its removal at exit
#   or removes it in its function, every shell `X="$(mktemp ...)"` is removed by an EXIT trap or a plain rm (or lies
#   inside a removed directory), or the site is on the tool's reviewed ALLOW list with its reason. And every CALL of an
#   emulator runner in a shell script passes its own sandbox (#303's emulator half, ruled 2026-10-23: "Callers pass a
#   sandbox"): a 4th argument to tools/run_replay_mame.sh / run_replay_guarded.sh, MAME_SANDBOX / FBNEO_SANDBOX for
#   tools/run_mame.sh / run_fbneo.sh (TMPDIR alone does not count: macOS's mktemp -d ignores it); the runners keep their
#   default for by-hand use.
#   Since #333 (14z-211) also every shell `X="$(mktemp -d ...)"` statement in tests/*.sh, tests/lib/*.sh and tools/*.sh
#   STOPS when mktemp fails (an `||` after the substitution, a `[ -n "$X" ] ... ||` test on one of the next three lines,
#   or `set -e`): one that carries on runs with $X empty, and "$X/<sub>" is then a path under / (UNGUARDED).
# HOW: the census over the tree; then known answers on a synthetic tree: five clean forms (atexit, a finally rmtree, a
#   shell EXIT trap set in an `if`, a trap calling a cleanup function, a directory made inside a trapped one) must not
#   be named, and an uncleaned python mkdtemp and an untrapped shell mktemp must be; three sandboxed runner calls (a
#   quoted "$REPO" path with a $(mktemp) 4th argument across a continuation, an env MAME_SANDBOX, a 4-argument guarded
#   call) must not be named, and a 3-argument replay call must be.
#   #333: ten guarded forms (an `|| exit`, the `${OUT:-$(mktemp -d)}` form, a `[ -n ]` test on the next line, a heredoc
#   body, an `else` arm, `[ -n ] || X=... ||`, a `case` arm, single-quoted text, a line after an arithmetic `<<`, a
#   `set -e` script) must not be named UNGUARDED; a bare one must be, and since rule-checker run 2026-10-29-1366 so must
#   each of fourteen forms the census once could not read or read as guarded (an else arm, `[ -n ] || X=...`, a case
#   arm, an inline argument, an assignment after `;`, `local`, an env prefix, `-dt`, a line after an arithmetic `<<`,
#   `export X=... || exit`, `|| true`, `[ -n "$X" ] || true`, a line before `set -e`, a line after `set +e`) while the
#   lines `set -e` is in force for read guarded; and since run 2026-10-29-1371 nine more (an `|| true` arm with an exit
#   later on the line, a commented-out test, a line after a here-string `<<<`, after a bash `(( << ))`, after a `<<` in
#   double quotes, a backtick substitution, `--directory`, a `\` continuation, a test after X is used), and backticks,
#   `--directory` and a continuation read guarded with `|| exit`; and since run 2026-10-29-1374 five more (a mktemp that
#   is not its substitution's first word: `TMPDIR=...`, `command`, `/usr/bin/`, `cd ... &&`; a site after a quoted
#   `set -e`), with `command mktemp ... || exit` read guarded and a quoted `mktemp -d` inside a sed pattern not read as a
#   site; then THE DYNAMIC CHECK,
#   a `mktemp` that fails put first on PATH: a synthetic unguarded script must carry on under it (the shim bites), four
#   real guarded gates must stop under it with their own "mktemp -d failed" line and a non-zero exit inside 60 s, and the
#   shared library's m2a_diverge must return non-zero with its line.
# EXPECTS: 0 uncleaned on the tree. A red names the file, the line, the function and the temp variable — the #303
#   shape: six static gates left python tempfile directories behind on every run (up to 145 entries a run,
#   test_poke_readback), measured by running every static gate and each of its controls in a fresh TMPDIR on PILOT.
#
# MUST-FIRE: perturbed-copy: planted-mkdtemp — a python file whose function makes a tempfile.mkdtemp() and never removes it must be named UNCLEANED and FAIL the gate (mode: the census reads that file with the tree)
# MUST-FIRE: perturbed-copy: planted-unsandboxed — a shell gate that calls tools/run_replay_mame.sh with three arguments (no [sandbox]) must be named UNSANDBOXED and FAIL the gate (#303's emulator half) (mode: the census reads that script with the tree)
# MUST-FIRE: perturbed-copy: planted-mktemp — a shell gate whose W="$(mktemp -d)" has no EXIT trap and no rm must be named UNCLEANED and FAIL the gate (mode: the census reads that script with the tree)
# MUST-FIRE: perturbed-copy: planted-unguarded — a shell gate whose W="$(mktemp -d)" is trapped but carries on when mktemp fails, and the thirty-seven unguarded forms of tests/unguarded_forms.sh, tests/setetoggle.sh, tests/unguarded_forms2.sh, tests/unguarded_forms3.sh and tests/unguarded_forms4.sh, must each be named UNGUARDED and FAIL the gate (#333) (mode: the census reads that script with the tree)
# MUST-FIRE: known-bad: shim-blind — the dynamic check with the failing mktemp left OFF the PATH: the synthetic unguarded script then carries on with a real W, and the guarded gates run past their mktemp, so the check names its own shim dead and FAILs (in-gate: the unguarded script must carry on with W EMPTY under the shim; mode: the shim is left off and the gate FAILs)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_tmp_hygiene — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
mkdir -p "$W/t/tools" "$W/t/tests"
printf 'import tempfile\ndef f():\n    d = tempfile.mkdtemp()\n    open(d + "/x", "w").write("x")\n' > "$W/t/tools/planted.py"
printf '#!/bin/sh\nW="$(mktemp -d)"\necho x > "$W/x"\n' > "$W/t/tests/planted.sh"
printf '#!/bin/sh\nW="$(mktemp -d)"; trap '"'"'rm -rf "$W"'"'"' EXIT\nPOKES=x tools/run_replay_mame.sh vsavj r.rpl "$W/o.log" > "$W/o.out" 2>&1\n' > "$W/t/tests/unsandboxed.sh"
printf '#!/bin/sh\nW="$(mktemp -d)"; trap '"'"'rm -rf "$W"'"'"' EXIT\necho "carried-on with W=[$W]"\n' > "$W/t/tests/unguarded.sh"
cat > "$W/t/tests/guarded.sh" <<'SH'
#!/bin/sh
A="$(mktemp -d)" || exit 2; trap 'rm -rf "$A"' EXIT
B="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/b.XXXXXX")}" || { echo "FAIL: x"; exit 2; }; trap 'rm -rf "$B"' EXIT
C="$(mktemp -d)"
[ -n "$C" ] || { echo "FAIL: x"; exit 2; }; trap 'rm -rf "$C"' EXIT
cat > "$A/inner.sh" <<'IN'
D="$(mktemp -d)"; rm -rf "$D"
IN
if [ -n "${KEEP:-}" ]; then G="$KEEP"; else G="$(mktemp -d)" || exit 2; fi
[ -n "${O:-}" ] || O="$(mktemp -d)" || { echo "FAIL: x"; exit 2; }
case "${1:-}" in *) H="$(mktemp -d)" || exit 2 ;; esac
echo 'I="$(mktemp -d)"'
N=$((1 << 3))
J="$(mktemp -d)" || exit 2; trap 'rm -rf "$J"' EXIT
K=`mktemp -d` || exit 2
L="$(mktemp --directory)" || exit 2
M="$(mktemp \
    -d)" || exit 2
G2="$(command mktemp -d)" || exit 2
echo "$(echo x | sed 's/a mktemp -d //')"
trap 'rm -rf "$J" "$K" "$L" "$M" "$G2"' EXIT
g() {
    G3="$(mktemp -d)" || return 2
}
h() { G4="$(mktemp -d)" || return 2; }
trap 'rm -rf "$G3" "$G4"' EXIT
SH
# a sourced library's top-level `return` returns (rule-checker run 2026-10-29-1379): read guarded
mkdir -p "$W/t/tests/lib"
printf '#!/bin/sh\nS1="$(mktemp -d)" || return 1\n' > "$W/t/tests/lib/srcd.sh"
# the forms the census once could not read (rule-checker run 2026-10-29-1366 Q4): each line 2-9 and 11 must be named
cat > "$W/t/tests/unguarded_forms.sh" <<'SH'
#!/bin/sh
if [ -n "${KEEP:-}" ]; then W1="$KEEP"; else W1="$(mktemp -d)"; fi
[ -n "${O2:-}" ] || O2="$(mktemp -d)"; mkdir -p "$O2"
case "${1:-}" in *) C3="$(mktemp -d)" ;; esac
ls "$(mktemp -d)"
x=1; T5="$(mktemp -d)"; fail=0
f() { local L6="$(mktemp -d)" || return 2; }
E7="$(mktemp -d)" sh inner.sh
X8="$(mktemp -dt foo)"
N=$((1 << 3))
Y9="$(mktemp -d)"
export X10="$(mktemp -d)" || exit 2
Z11="$(mktemp -d)" || true
V12="$(mktemp -d)"
[ -n "$V12" ] || true
trap 'rm -rf "$W1" "$O2" "$C3" "$T5" "$E7" "$X8" "$Y9" "$X10" "$Z11" "$V12"' EXIT
SH
# forms that blinded or fooled the census until rule-checker run 2026-10-29-1371: lines 2, 3, 6, 8, 10, 11, 12, 13 and 15
# must be named — an `|| true` arm with an exit later on the line, a commented-out test, a line after a here-string, after
# a bash `(( << ))`, after a `<<` in double quotes, a backtick substitution, `--directory`, a `\` continuation, and a test
# that comes after X is used
cat > "$W/t/tests/unguarded_forms2.sh" <<'SH'
#!/bin/sh
X13="$(mktemp -d)" || true; [ -n "$a" ] || exit 1
X14="$(mktemp -d)"
# [ -n "$X14" ] || exit 2
read a <<< "x"
X15="$(mktemp -d)"
(( n = 1 << 2 ))
X16="$(mktemp -d)"
echo "<<EOF"
X17="$(mktemp -d)"
X18=`mktemp -d`
X19="$(mktemp --directory)"
X20="$(mktemp \
    -d)"
X21="$(mktemp -d)"
echo "$X21/x"
[ -n "$X21" ] || exit 2
trap 'rm -rf "$X13" "$X14" "$X15" "$X16" "$X17" "$X18" "$X19" "$X20" "$X21"' EXIT
SH
# after rule-checker run 2026-10-29-1374: a mktemp that is not its substitution's first word (lines 2-5), and a quoted
# `set -e` that is text, not this script's (line 7): each must be named
cat > "$W/t/tests/unguarded_forms3.sh" <<'SH'
#!/bin/sh
X22="$(TMPDIR="/tmp" mktemp -d)"
X23="$(command mktemp -d)"
X24="$(/usr/bin/mktemp -d)"
X25="$(cd /tmp && mktemp -d)"
sh -c 'true; set -e'
X26="$(mktemp -d)"
trap 'rm -rf "$X22" "$X23" "$X24" "$X25" "$X26"' EXIT
SH
# rule-checker run 2026-10-29-1379: a top-level `|| return` in an executed script runs on; a subshell's own set -e; a
# `\"` inside double quotes (its escape test was dead); `exit` only inside quoted arm text — lines 2, 4, 6 and 7 named
cat > "$W/t/tests/unguarded_forms4.sh" <<'SH'
#!/bin/sh
X27="$(mktemp -d)" || return 2
( cd /tmp; set -e; true )
X28="$(mktemp -d)"
echo "a \"; set -e"
X29="$(mktemp -d)"
X30="$(mktemp -d)" || echo "cannot exit"
X31="$(mktemp -d)" || (exit 2)
set -e
set +o errexit
X32="$(mktemp -d)"
set -e
[ -n "${CI:-}" ] || set +e
X33="$(mktemp -d)"
set +e; [ -n "${CI:-}" ] && set -e
X34="$(mktemp -d)"
set -e
case "${1:-}" in *) set +e ;; esac
X35="$(mktemp -d)"
trap 'rm -rf "$X27" "$X28" "$X29" "$X30" "$X31" "$X32" "$X33" "$X34" "$X35"' EXIT
SH
# rule-checker run 2026-10-29-1382: a conditional `set +e` turns set -e off (line 14), a conditional `set -e` turns
# nothing on (line 16), a case arm's `set +e` turns it off (line 19); `{ set -e; }` runs in this shell: read guarded
printf '#!/bin/sh\n{ set -e; }\nE3="$(mktemp -d)"; trap '"'"'rm -rf "$E3"'"'"' EXIT\n' > "$W/t/tests/sete3.sh"
# rule-checker run 2026-10-29-1380: `set -o errexit` is set -e (read guarded); `|| (exit 2)` and after `set +o errexit`
# (lines 8 and 11 above) are not
printf '#!/bin/sh\nset -o errexit\nE2="$(mktemp -d)"; trap '"'"'rm -rf "$E2"'"'"' EXIT\n' > "$W/t/tests/sete2.sh"
# set -e counts where it is in force AT the line (rule-checker run 2026-10-29-1368): lines 2 and 8 must be named
cat > "$W/t/tests/setetoggle.sh" <<'SH'
#!/bin/sh
A="$(mktemp -d)"
set -e
B="$(mktemp -d)"
set +e; out=$(false); set -e
C="$(mktemp -d)"
set +e
D="$(mktemp -d)"
trap 'rm -rf "$A" "$B" "$C" "$D"' EXIT
SH
printf '#!/bin/sh\nset -eu\nF="$(mktemp -d)"; trap '"'"'rm -rf "$F"'"'"' EXIT\n' > "$W/t/tests/sete.sh"
cat > "$W/t/tools/clean.py" <<'PY'
import atexit, shutil, tempfile
from pathlib import Path
def a():
    d = tempfile.mkdtemp(); atexit.register(shutil.rmtree, d, True)
def b():
    d = Path(tempfile.mkdtemp())
    try:
        pass
    finally:
        shutil.rmtree(d)
PY
cat > "$W/t/tests/clean.sh" <<'SH'
#!/bin/sh
cleanup() { rm -rf "$A"; }
A="$(mktemp -d)" || exit 2; trap cleanup EXIT
B="$(mktemp -d)" || exit 2
if [ -n "${KEEP:-}" ]; then trap 'cp -R "$B"/. "$KEEP"/; rm -rf "$B"' EXIT; else trap 'rm -rf "$B"' EXIT; fi
C="$(mktemp -d "$B/inner.XXXXXX")" || exit 2
MASK_RANGES=x "$REPO/tools/run_replay_mame.sh" vsavj r.rpl "$A/o.log" \
    "$(mktemp -d "$A/sb.XXXXXX")" > "$A/o.out" 2>&1 || true
MAME_SANDBOX="$A/sb2" MAME_ROMPATH=x tools/run_mame.sh vsavj -autoboot_script x.lua > /dev/null
timeout 60 tools/run_replay_guarded.sh vsavj r.rpl "$A/g.log" "$A/g.sb" && echo ok
SH
echo "== 1. the tree"
EXTRA=""
vs_ctl_is planted-mkdtemp && EXTRA="tools/planted.py"
vs_ctl_is planted-mktemp && EXTRA="tests/planted.sh"
vs_ctl_is planted-unsandboxed && EXTRA="tests/unsandboxed.sh"
vs_ctl_is planted-unguarded && EXTRA="tests/unguarded.sh tests/unguarded_forms.sh tests/setetoggle.sh tests/unguarded_forms2.sh tests/unguarded_forms3.sh tests/unguarded_forms4.sh"
out="$(python3 tools/tmp_hygiene.py 2>&1)"; rc=$?
[ -z "$EXTRA" ] || out="$out
$(python3 tools/tmp_hygiene.py --root "$W/t" $EXTRA 2>&1)"   # the mode: the planted file read with the tree
echo "$out" | sed 's/^/  /' | tail -12
if [ -z "$EXTRA" ]; then [ "$rc" = 0 ] && ok "no uncleaned temporary in the tree" || bad "an uncleaned temporary (above)"
else
    echo "$out" | grep >/dev/null '^UNCLEANED\|^UNSANDBOXED\|^UNGUARDED' && { echo "FAIL: test_tmp_hygiene (control mode: the planted site was named)"; exit 1; }
    echo "FAIL: test_tmp_hygiene — the planted site was not named"; exit 1
fi

echo "== 2. known answers on a synthetic tree"
out="$(python3 tools/tmp_hygiene.py --root "$W/t" tools/clean.py tests/clean.sh 2>&1)"
if echo "$out" | grep >/dev/null '^UNCLEANED\|^UNSANDBOXED'; then bad "a clean form was named: $(echo "$out" | grep -m1 'UNCLEANED\|UNSANDBOXED')"
else ok "five clean forms and three sandboxed runner calls read clean ($(echo "$out" | tail -1))"; fi
echo "$out" | tail -1 | grep -q ' 3 emulator-runner call(s) read' && ok "the three runner calls were read" || bad "the synthetic runner calls were not all read: $(echo "$out" | tail -1)"
out="$(python3 tools/tmp_hygiene.py --root "$W/t" tests/guarded.sh tests/sete.sh tests/sete2.sh tests/sete3.sh tests/lib/srcd.sh 2>&1)"
if echo "$out" | grep >/dev/null '^UNGUARDED'; then bad "a guarded form was named: $(echo "$out" | grep -m1 UNGUARDED)"
else ok "twenty guarded mktemp -d forms read guarded: $(echo "$out" | tail -1 | sed 's/.*carrying on after a failed mktemp -d //')"; fi
FORMS="tests/unguarded_forms.sh:2 tests/unguarded_forms.sh:3 tests/unguarded_forms.sh:4 tests/unguarded_forms.sh:5 tests/unguarded_forms.sh:6 tests/unguarded_forms.sh:7 tests/unguarded_forms.sh:8 tests/unguarded_forms.sh:9 tests/unguarded_forms.sh:11 tests/unguarded_forms.sh:12 tests/unguarded_forms.sh:13 tests/unguarded_forms.sh:14 tests/setetoggle.sh:2 tests/setetoggle.sh:8 tests/unguarded_forms2.sh:2 tests/unguarded_forms2.sh:3 tests/unguarded_forms2.sh:6 tests/unguarded_forms2.sh:8 tests/unguarded_forms2.sh:10 tests/unguarded_forms2.sh:11 tests/unguarded_forms2.sh:12 tests/unguarded_forms2.sh:13 tests/unguarded_forms2.sh:15 tests/unguarded_forms3.sh:2 tests/unguarded_forms3.sh:3 tests/unguarded_forms3.sh:4 tests/unguarded_forms3.sh:5 tests/unguarded_forms3.sh:7 tests/unguarded_forms4.sh:2 tests/unguarded_forms4.sh:4 tests/unguarded_forms4.sh:6 tests/unguarded_forms4.sh:7 tests/unguarded_forms4.sh:8 tests/unguarded_forms4.sh:11 tests/unguarded_forms4.sh:14 tests/unguarded_forms4.sh:16 tests/unguarded_forms4.sh:19"
got="$(python3 tools/tmp_hygiene.py --root "$W/t" tests/unguarded_forms.sh tests/setetoggle.sh tests/unguarded_forms2.sh tests/unguarded_forms3.sh tests/unguarded_forms4.sh 2>&1 | awk -F'\t' '$1 == "UNGUARDED" {print $2}' | sort | tr '\n' ' ' | sed 's/ $//')"
want="$(echo $FORMS | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')"
[ "$got" = "$want" ] && ok "thirty-seven unguarded forms (after a conditional set +e, a conditional set -e, a case arm's set +e, || (exit 2), after set +o errexit, a top-level || return, a subshell's set -e, after an escaped quote's set -e, exit only in quotes; TMPDIR= / command / /usr/bin/ / cd && before mktemp, after a quoted set -e; an else arm, [ -n ] ||, a case arm, an inline argument, after ;, local, an env prefix, -dt, after an arithmetic <<, export ||, || true, [ -n ] || true, before set -e, after set +e; an || true arm with a later exit, a commented-out test, after a here-string, after (( << )), after a quoted <<, backticks, --directory, a continuation, a test after a use) each named, and none of the set -e ones" \
    || bad "the unguarded forms named: [$got], want [$want]"

echo "== 3. controls"
out="$(python3 tools/tmp_hygiene.py --root "$W/t" tools/planted.py 2>&1)"
if echo "$out" | grep >/dev/null '^UNCLEANED	tools/planted.py:3	f	mkdtemp	d$'; then vs_ctl_fired planted-mkdtemp "$(echo "$out" | grep -m1 UNCLEANED)"
else vs_ctl_dead planted-mkdtemp "the uncleaned python mkdtemp was not named"; fail=1; fi
out="$(python3 tools/tmp_hygiene.py --root "$W/t" tests/planted.sh 2>&1)"
if echo "$out" | grep >/dev/null '^UNCLEANED	tests/planted.sh:2	shell	mktemp	W$'; then vs_ctl_fired planted-mktemp "$(echo "$out" | grep -m1 UNCLEANED)"
else vs_ctl_dead planted-mktemp "the untrapped shell mktemp was not named"; fail=1; fi
out="$(python3 tools/tmp_hygiene.py --root "$W/t" tests/unsandboxed.sh 2>&1)"
if echo "$out" | grep >/dev/null '^UNSANDBOXED	tests/unsandboxed.sh:3	run_replay_mame.sh'; then vs_ctl_fired planted-unsandboxed "$(echo "$out" | grep -m1 UNSANDBOXED)"
else vs_ctl_dead planted-unsandboxed "the 3-argument replay call was not named"; fail=1; fi

out="$(python3 tools/tmp_hygiene.py --root "$W/t" tests/unguarded.sh tests/unguarded_forms.sh tests/setetoggle.sh tests/unguarded_forms2.sh tests/unguarded_forms3.sh tests/unguarded_forms4.sh 2>&1)"
_nf="$(echo "$out" | grep -c '^UNGUARDED	tests/unguarded_forms.sh:\|^UNGUARDED	tests/setetoggle.sh:\|^UNGUARDED	tests/unguarded_forms2.sh:\|^UNGUARDED	tests/unguarded_forms3.sh:\|^UNGUARDED	tests/unguarded_forms4.sh:')"
if echo "$out" | grep >/dev/null '^UNGUARDED	tests/unguarded.sh:2	shell	mktemp -d	W	' && [ "$_nf" = 37 ]; then vs_ctl_fired planted-unguarded "$(echo "$out" | grep -m1 UNGUARDED | cut -f1-5); and $_nf of the 37 unguarded forms"
else vs_ctl_dead planted-unguarded "the planted unguarded mktemp -d sites were not all named ($_nf of the 37 forms)"; fail=1; fi

echo "== 4. the dynamic check: a mktemp that fails, first on PATH (#333)"
mkdir -p "$W/shim"; printf '#!/bin/sh\necho "mktemp: test_tmp_hygiene shim: failing on purpose" >&2\nexit 1\n' > "$W/shim/mktemp"; chmod +x "$W/shim/mktemp"
SHIM="$W/shim:"; vs_ctl_is shim-blind && SHIM=""
under() { env -u CONTROL PATH="$SHIM$PATH" timeout 60 sh "$@" 2>&1; }   # CONTROL unset: a child refusing a mode is no stop
if vs_ctl_is shim-blind; then   # the mode: no shim, so the guarded gates must run past their mktemp and the gate FAILs
    o="$(under tests/test_live_budget.sh)"; rc=$?
    [ "$rc" = 0 ] && { echo "FAIL: test_tmp_hygiene (control mode: without the shim test_live_budget ran past its mktemp -d)"; exit 1; }
    echo "FAIL: test_tmp_hygiene — control mode shim-blind: test_live_budget stopped without the shim (exit $rc)"; exit 1
fi
o="$(under "$W/t/tests/unguarded.sh")"
if echo "$o" | grep -qF 'carried-on with W=[]'; then vs_ctl_fired shim-blind "the unguarded script carried on with W empty: the shim makes mktemp fail"
else vs_ctl_dead shim-blind "the unguarded script did not carry on with W empty (is the shim on PATH?): $(echo "$o" | tail -1)"; fail=1; fi
for g in test_live_budget test_history_index test_controls_contract test_measures_contract; do
    o="$(under "tests/$g.sh")"; rc=$?
    if [ "$rc" != 0 ] && [ "$rc" != 124 ] && echo "$o" | grep -q "FAIL: $g — mktemp -d failed"; then ok "$g stops at its failed mktemp -d (exit $rc)"
    else bad "$g did not stop at a failed mktemp -d (exit $rc): $(echo "$o" | tail -1 | cut -c1-120)"; fi
done
o="$(env -u CONTROL PATH="$SHIM$PATH" REPO="$REPO" sh -c '. tests/lib/m2a_common.sh; m2a_diverge /dev/null x 1' 2>&1)"; rc=$?
if [ "$rc" != 0 ] && echo "$o" | grep -q "m2a_common: mktemp -d failed"; then ok "the library's m2a_diverge returns $rc at its failed mktemp -d"
else bad "m2a_diverge did not stop at a failed mktemp -d (exit $rc): $(echo "$o" | tail -1 | cut -c1-120)"; fi

[ "$fail" = 0 ] && echo "PASS: test_tmp_hygiene" || echo "FAIL: test_tmp_hygiene"
exit "$fail"
