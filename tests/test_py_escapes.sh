#!/bin/sh
# test_py_escapes.sh — NO TRACKED PYTHON FILE CARRIES AN INVALID STRING ESCAPE (14z-191). ci_portable: no ROM, ~3 s.
#
# WHAT: every tracked .py under tools/ and tests/ compiles with invalid-escape warnings turned into errors
#   (DeprecationWarning on Python <= 3.11, SyntaxWarning from 3.12) — so no host's Python warns on it today and
#   none refuses it when the warning becomes an error.
# HOW: each file compiled, never imported, under `python3 -W error::DeprecationWarning -W error::SyntaxWarning`; a
#   file whose compile raises is named with the message.
# EXPECTS: every file compiles. A red names the file and the escape — the 14z-191 shape: tools/package_release.py's
#   README text held `roms\` before a backtick, an invalid escape PILOT's Python 3.12 printed as a SyntaxWarning
#   on every packaging run (the Mac's 3.9 stays silent).
#
# MUST-FIRE: perturbed-copy: planted-escape — a file holding "\`" in a plain string, compiled by the same check, must be named and FAIL the gate (mode: the check runs over that file too)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
printf 's = "a roms\\`b"\n' > "$W/planted.py"
check() {   # check <file>... — print each file whose compile raises, exit 1 if any
    python3 -W error::DeprecationWarning -W error::SyntaxWarning - "$@" <<'PY'
import sys
bad = 0
for p in sys.argv[1:]:
    with open(p, encoding="utf-8") as f:
        s = f.read()
    try:
        compile(s, p, "exec")
    except (SyntaxError, DeprecationWarning, SyntaxWarning) as e:
        print(f"  ESCAPE {p}: {e}"); bad += 1
print(f"  {len(sys.argv) - 1} files compiled, {bad} with an invalid escape")
sys.exit(1 if bad else 0)
PY
}
FILES="$(git ls-files 'tools/*.py' 'tests/*.py' | sort -u)"
EXTRA=""; vs_ctl_is planted-escape && EXTRA="$W/planted.py"
echo "== 1. every tracked Python file under tools/ and tests/"
# shellcheck disable=SC2086
if check $FILES $EXTRA; then fail=0; echo "  ok    no invalid escape"; else fail=1; echo "  FAIL  an invalid escape (above)"; fi
if vs_ctl_is planted-escape; then
    [ "$fail" = 1 ] && { echo "FAIL: test_py_escapes (control mode: the planted escape was named)"; exit 1; }
    echo "FAIL: test_py_escapes — the planted escape passed"; exit 1
fi
echo "== 2. control"
if check "$W/planted.py" > "$W/c.txt" 2>&1; then vs_ctl_dead planted-escape "the planted escape compiled clean"; fail=1
else vs_ctl_fired planted-escape "$(grep -m1 ESCAPE "$W/c.txt" | sed 's/^ *//')"; fi
[ "$fail" = 0 ] && echo "PASS: test_py_escapes" || echo "FAIL: test_py_escapes"
exit "$fail"
