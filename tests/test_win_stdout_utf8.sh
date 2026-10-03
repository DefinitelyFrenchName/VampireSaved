#!/bin/sh
# test_win_stdout_utf8.sh — the Windows-run python tools write UTF-8, never cp1252 (14z-189, #130).
# ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHAT: every python tool that runs under a NATIVE Windows python (MSYS2 MINGW64) during a release
#   build writes its console output as UTF-8, so an em dash reaches the log as e2 80 94, not as
#   cp1252's single 0x97 byte (which the UTF-8 terminal shows as U+FFFD). The same reconfigure line
#   sets LF newlines; this gate does NOT see that half (PYTHONIOENCODING has no newline setting) —
#   it was measured on ERIS only (0 CR, build/agent189/t130_eris.txt).
# HOW: runs each listed tool with no arguments (its usage text, which carries an em dash, goes to
#   stderr through sys.exit) under PYTHONIOENCODING=cp1252, the encoding a native Windows python
#   gives a pipe, and counts the bytes: at least one UTF-8 em dash and no 0x97. The control runs a
#   copy of the tool with its reconfigure lines removed, which must write 0x97.
# EXPECTS: PASS when every listed tool reconfigures its streams; a red names the tool and the counts.
#
# MUST-FIRE: perturbed-copy: reconfigure-removed — a copy of tools/bundle_win_dlls.py with its sys.stdout/sys.stderr reconfigure lines deleted must write cp1252 0x97 and fail (mode: that copy is the tool checked)
#
# WHY. #130: tools/bundle_win_dlls.py printed U+FFFD for every em dash on MSYS2, because a native
# Windows python pipes cp1252 + CRLF. Reproduced on ERIS 2026-10-02 (build/agent189/t130_eris.txt:
# the unfixed tool wrote 2 bytes 0x97 and 3 CRs, the fixed one 2 UTF-8 em dashes and 0 CR). The
# same class was fixed in tests/test_release_binaries.sh by sys.stdout.reconfigure(encoding="utf-8",
# newline="\n"); docs/platform/gotchas.md holds the per-PROCESS rule. PYTHONIOENCODING=cp1252 is
# the portable stand-in for that pipe: it reproduced the 0x97 byte on macOS for the unfixed tool.
#
# SCOPE: the tools listed in TOOLS below — the python tools tools/build_release_emulators.sh runs on
# the Windows track. A new such tool is added here.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
TOOLS="tools/bundle_win_dlls.py"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

# counts <tool path> -> "<utf8 em dashes> <0x97 bytes>"
counts() {
    PYTHONIOENCODING=cp1252 python3 "$1" > "$W/out" 2>&1 </dev/null
    python3 -c "import sys;b=open(sys.argv[1],'rb').read();print(b.count(b'\xe2\x80\x94'), b.count(b'\x97'))" "$W/out"
}

# the perturbation, ONE function for the control and the mode
strip_reconfigure() {  # strip_reconfigure <src> <dst>
    grep -v 'reconfigure(encoding="utf-8"' "$1" > "$2"
}

echo "== test_win_stdout_utf8: the Windows-run python tools write UTF-8 =="
for t in $TOOLS; do
    src="$t"
    if [ "${CONTROL:-}" = "reconfigure-removed" ]; then
        strip_reconfigure "$t" "$W/$(basename "$t")"; src="$W/$(basename "$t")"
    elif [ -n "${CONTROL:-}" ]; then
        echo "REFUSED: CONTROL=$CONTROL is not a mode of this gate"; exit 3
    fi
    set -- $(counts "$src")
    if [ "$1" -ge 1 ] && [ "$2" -eq 0 ]; then
        echo "  ok: $t — $1 UTF-8 em dash(es), 0 cp1252 0x97 bytes under PYTHONIOENCODING=cp1252"
    else
        echo "  FAIL: $t — $1 UTF-8 em dash(es), $2 cp1252 0x97 bytes under PYTHONIOENCODING=cp1252"; fail=1
    fi
done

# the must-fire control: the unfixed copy must write 0x97
strip_reconfigure tools/bundle_win_dlls.py "$W/ctl.py"
set -- $(counts "$W/ctl.py")
if [ "$2" -ge 1 ]; then
    echo "CONTROL FIRED: reconfigure-removed — the copy without the reconfigure lines wrote $2 cp1252 0x97 byte(s)"
else
    echo "CONTROL DEAD: reconfigure-removed — the copy without the reconfigure lines wrote no 0x97 byte (the stand-in no longer reproduces the pipe)"
    fail=1
fi

if [ "$fail" -eq 0 ]; then echo "PASS: test_win_stdout_utf8 — every listed tool writes UTF-8 under a cp1252 pipe"
else echo "FAIL: test_win_stdout_utf8"; exit 1; fi
