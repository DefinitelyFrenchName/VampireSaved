#!/bin/sh
# test_host_text_opens.sh — THE RELEASE GENERATOR'S TEXT FILES NAME THEIR ENCODING AND NEWLINE (#308, 14z-207). ci_portable: no ROM, ~1 s.
#
# WHAT: every text open() in the release generator (tools/package_release.py, tools/package_release_platforms.py)
#   names `encoding=`, and every text write also names `newline=`, so the bytes it writes are the same on every
#   host; a pathlib read_text names `encoding=` too, and a pathlib write_text is refused outright (its `newline=` needs
#   Python 3.10, and this Mac's python3 is 3.9: a text write goes through open()). A binary open ('b' in its mode) is
#   exempt.
# HOW: each file parsed with ast, never imported; every call to the builtin open(), and every attribute call
#   .read_text/.write_text/.open, is read for its mode and keywords; a text one missing a keyword is named.
# EXPECTS: every listed file clean. A red names the file, the line and the missing keyword — the #308 shape: on
#   ERIS's MSYS2 MINGW64 Python (cp1252, UTF-8 mode off) a bare open(path, "w") died on PLAY.command's box-drawing
#   characters, and each "\n" became "\r\n".
#
# SCOPE: the files in FILES below. test_readme_recording.sh's host-text guard catches the same defect at run time,
#   but only on the README render path it executes (rule-checker run 2026-10-23-1198 Q4); this gate reads every
#   call site. tools/gen_applier_page.py joins FILES when #314 is fixed.
#
# MUST-FIRE: perturbed-copy: unencoded-open — a copy of tools/package_release.py with `encoding="utf-8", ` removed from its first text write must be named and FAIL the gate (mode: the check runs over that copy too)
# MUST-FIRE: perturbed-copy: newline-dropped — a copy of tools/package_release_platforms.py with `, newline="\n"` removed from its first text write must be named and FAIL the gate (mode: the check runs over that copy too)
# MUST-FIRE: perturbed-copy: write-text — a file whose one text write is `Path(p).write_text(s, encoding="utf-8")` must be named and FAIL the gate (rule-checker run 2026-10-23-1200 Q4) (mode: the check runs over that file too)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
FILES="tools/package_release.py tools/package_release_platforms.py"
# the two perturbed copies: the first match of each pattern only
python3 - "$W" <<'PY'
import sys
w = sys.argv[1]
s = open("tools/package_release.py", encoding="utf-8").read()
k = 'encoding="utf-8", newline="\\n"'
assert k in s, "no text write to perturb in tools/package_release.py"
open(f"{w}/unencoded.py", "w", encoding="utf-8", newline="\n").write(s.replace(k, 'newline="\\n"', 1))
s = open("tools/package_release_platforms.py", encoding="utf-8").read()
assert k in s, "no text write to perturb in tools/package_release_platforms.py"
open(f"{w}/nonewline.py", "w", encoding="utf-8", newline="\n").write(s.replace(k, 'encoding="utf-8"', 1))
open(f"{w}/writetext.py", "w", encoding="utf-8", newline="\n").write(
    'from pathlib import Path\nPath("x.txt").write_text("a\\n", encoding="utf-8")\n')
PY
[ -s "$W/unencoded.py" ] && [ -s "$W/nonewline.py" ] && [ -s "$W/writetext.py" ] || { echo "FAIL: test_host_text_opens — the perturbed copies were not written"; exit 1; }
check() {   # check <file>... — name each text open missing encoding= (or newline= on a write); exit 1 if any
    python3 - "$@" <<'PY'
import ast, sys
bad = n = 0
def kw(call):
    return {k.arg for k in call.keywords}
for p in sys.argv[1:]:
    tree = ast.parse(open(p, encoding="utf-8").read(), p)
    for c in ast.walk(tree):
        if not isinstance(c, ast.Call):
            continue
        f = c.func
        if isinstance(f, ast.Name) and f.id == "open":
            mode = c.args[1] if len(c.args) > 1 else next((k.value for k in c.keywords if k.arg == "mode"), None)
            if mode is not None and not isinstance(mode, ast.Constant):
                print(f"  OPEN {p}:{c.lineno}: a mode that is not a literal"); bad += 1; continue
            m = "r" if mode is None else mode.value
            if "b" in m:
                continue
            n += 1
            if "encoding" not in kw(c):
                print(f"  OPEN {p}:{c.lineno}: text open({m!r}) with no encoding="); bad += 1
            if any(x in m for x in "wax+") and "newline" not in kw(c):
                print(f"  OPEN {p}:{c.lineno}: text write open({m!r}) with no newline="); bad += 1
        elif isinstance(f, ast.Attribute) and f.attr == "write_text":
            n += 1
            print(f"  OPEN {p}:{c.lineno}: .write_text() (no newline= before Python 3.10: write through open())"); bad += 1
        elif isinstance(f, ast.Attribute) and f.attr == "read_text":
            n += 1
            if "encoding" not in kw(c):
                print(f"  OPEN {p}:{c.lineno}: .read_text() with no encoding="); bad += 1
print(f"  {len(sys.argv) - 1} file(s), {n} text open(s), {bad} missing a keyword")
sys.exit(1 if bad else 0)
PY
}
EXTRA=""
vs_ctl_is unencoded-open && EXTRA="$W/unencoded.py"
vs_ctl_is newline-dropped && EXTRA="$W/nonewline.py"
vs_ctl_is write-text && EXTRA="$W/writetext.py"
echo "== 1. the release generator's text opens"
# shellcheck disable=SC2086
if check $FILES $EXTRA; then fail=0; echo "  ok    every text open names its encoding, every write its newline"
else fail=1; echo "  FAIL  a text open without its keyword (above)"; fi
if [ -n "$EXTRA" ]; then
    [ "$fail" = 1 ] && { echo "FAIL: test_host_text_opens (control mode: the perturbed copy was named)"; exit 1; }
    echo "FAIL: test_host_text_opens — the perturbed copy passed"; exit 1
fi
echo "== 2. controls"
if check "$W/unencoded.py" > "$W/c1.txt" 2>&1; then vs_ctl_dead unencoded-open "the copy without encoding= passed"; fail=1
else vs_ctl_fired unencoded-open "$(grep -m1 'no encoding' "$W/c1.txt" | sed 's/^ *//')"; fi
if check "$W/nonewline.py" > "$W/c2.txt" 2>&1; then vs_ctl_dead newline-dropped "the copy without newline= passed"; fail=1
else vs_ctl_fired newline-dropped "$(grep -m1 'no newline' "$W/c2.txt" | sed 's/^ *//')"; fi
if check "$W/writetext.py" > "$W/c3.txt" 2>&1; then vs_ctl_dead write-text "the file with a write_text passed"; fail=1
else vs_ctl_fired write-text "$(grep -m1 'write_text' "$W/c3.txt" | sed 's/^ *//')"; fi
[ "$fail" = 0 ] && echo "PASS: test_host_text_opens" || echo "FAIL: test_host_text_opens"
exit "$fail"
