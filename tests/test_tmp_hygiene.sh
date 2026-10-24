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
# HOW: the census over the tree; then known answers on a synthetic tree: five clean forms (atexit, a finally rmtree, a
#   shell EXIT trap set in an `if`, a trap calling a cleanup function, a directory made inside a trapped one) must not
#   be named, and an uncleaned python mkdtemp and an untrapped shell mktemp must be; three sandboxed runner calls (a
#   quoted "$REPO" path with a $(mktemp) 4th argument across a continuation, an env MAME_SANDBOX, a 4-argument guarded
#   call) must not be named, and a 3-argument replay call must be.
# EXPECTS: 0 uncleaned on the tree. A red names the file, the line, the function and the temp variable — the #303
#   shape: six static gates left python tempfile directories behind on every run (up to 145 entries a run,
#   test_poke_readback), measured by running every static gate and each of its controls in a fresh TMPDIR on PILOT.
#
# MUST-FIRE: perturbed-copy: planted-mkdtemp — a python file whose function makes a tempfile.mkdtemp() and never removes it must be named UNCLEANED and FAIL the gate (mode: the census reads that file with the tree)
# MUST-FIRE: perturbed-copy: planted-unsandboxed — a shell gate that calls tools/run_replay_mame.sh with three arguments (no [sandbox]) must be named UNSANDBOXED and FAIL the gate (#303's emulator half) (mode: the census reads that script with the tree)
# MUST-FIRE: perturbed-copy: planted-mktemp — a shell gate whose W="$(mktemp -d)" has no EXIT trap and no rm must be named UNCLEANED and FAIL the gate (mode: the census reads that script with the tree)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
mkdir -p "$W/t/tools" "$W/t/tests"
printf 'import tempfile\ndef f():\n    d = tempfile.mkdtemp()\n    open(d + "/x", "w").write("x")\n' > "$W/t/tools/planted.py"
printf '#!/bin/sh\nW="$(mktemp -d)"\necho x > "$W/x"\n' > "$W/t/tests/planted.sh"
printf '#!/bin/sh\nW="$(mktemp -d)"; trap '"'"'rm -rf "$W"'"'"' EXIT\nPOKES=x tools/run_replay_mame.sh vsavj r.rpl "$W/o.log" > "$W/o.out" 2>&1\n' > "$W/t/tests/unsandboxed.sh"
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
A="$(mktemp -d)"; trap cleanup EXIT
B="$(mktemp -d)"
if [ -n "${KEEP:-}" ]; then trap 'cp -R "$B"/. "$KEEP"/; rm -rf "$B"' EXIT; else trap 'rm -rf "$B"' EXIT; fi
C="$(mktemp -d "$B/inner.XXXXXX")"
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
out="$(python3 tools/tmp_hygiene.py 2>&1)"; rc=$?
[ -z "$EXTRA" ] || out="$out
$(python3 tools/tmp_hygiene.py --root "$W/t" "$EXTRA" 2>&1)"   # the mode: the planted file read with the tree
echo "$out" | sed 's/^/  /' | tail -12
if [ -z "$EXTRA" ]; then [ "$rc" = 0 ] && ok "no uncleaned temporary in the tree" || bad "an uncleaned temporary (above)"
else
    echo "$out" | grep -q '^UNCLEANED\|^UNSANDBOXED' && { echo "FAIL: test_tmp_hygiene (control mode: the planted site was named)"; exit 1; }
    echo "FAIL: test_tmp_hygiene — the planted site was not named"; exit 1
fi

echo "== 2. known answers on a synthetic tree"
out="$(python3 tools/tmp_hygiene.py --root "$W/t" tools/clean.py tests/clean.sh 2>&1)"
if echo "$out" | grep -q '^UNCLEANED\|^UNSANDBOXED'; then bad "a clean form was named: $(echo "$out" | grep -m1 'UNCLEANED\|UNSANDBOXED')"
else ok "five clean forms and three sandboxed runner calls read clean ($(echo "$out" | tail -1))"; fi
echo "$out" | tail -1 | grep -q ' 3 emulator-runner call(s) read' && ok "the three runner calls were read" || bad "the synthetic runner calls were not all read: $(echo "$out" | tail -1)"

echo "== 3. controls"
out="$(python3 tools/tmp_hygiene.py --root "$W/t" tools/planted.py 2>&1)"
if echo "$out" | grep -q '^UNCLEANED	tools/planted.py:3	f	mkdtemp	d$'; then vs_ctl_fired planted-mkdtemp "$(echo "$out" | grep -m1 UNCLEANED)"
else vs_ctl_dead planted-mkdtemp "the uncleaned python mkdtemp was not named"; fail=1; fi
out="$(python3 tools/tmp_hygiene.py --root "$W/t" tests/planted.sh 2>&1)"
if echo "$out" | grep -q '^UNCLEANED	tests/planted.sh:2	shell	mktemp	W$'; then vs_ctl_fired planted-mktemp "$(echo "$out" | grep -m1 UNCLEANED)"
else vs_ctl_dead planted-mktemp "the untrapped shell mktemp was not named"; fail=1; fi
out="$(python3 tools/tmp_hygiene.py --root "$W/t" tests/unsandboxed.sh 2>&1)"
if echo "$out" | grep -q '^UNSANDBOXED	tests/unsandboxed.sh:3	run_replay_mame.sh'; then vs_ctl_fired planted-unsandboxed "$(echo "$out" | grep -m1 UNSANDBOXED)"
else vs_ctl_dead planted-unsandboxed "the 3-argument replay call was not named"; fail=1; fi

[ "$fail" = 0 ] && echo "PASS: test_tmp_hygiene" || echo "FAIL: test_tmp_hygiene"
exit "$fail"
