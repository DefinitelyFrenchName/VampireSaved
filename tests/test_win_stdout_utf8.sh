#!/bin/sh
# test_win_stdout_utf8.sh — the Windows-run python tools write UTF-8, never cp1252 (14z-189, #130, #212).
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
#   THE APPLIER (#212): tools/apply_release.py is run on a SYNTHETIC release (a manifest whose one
#   member is a pristine_from copy of a made-up file in a made-up reference zip: no ROM byte, no
#   ROMDIR) all the way to its final "OK: wrote ... — every member verified" line, under
#   PYTHONIOENCODING=cp932 (the code page that cannot encode the dash: the crash half) and cp1252
#   (the 0x97 half). Its control runs a copy with the reconfigure lines removed, which must exit
#   non-zero with UnicodeEncodeError under cp932.
# EXPECTS: PASS when every listed tool reconfigures its streams and the applier exits 0 under cp932
#   with one UTF-8 em dash; a red names the tool and the counts.
#
# MUST-FIRE: perturbed-copy: reconfigure-removed — a copy of tools/bundle_win_dlls.py with its sys.stdout/sys.stderr reconfigure lines deleted must write cp1252 0x97 and fail (mode: that copy is the tool checked)
# MUST-FIRE: perturbed-copy: applier-reconfigure-removed — a copy of tools/apply_release.py with its reconfigure lines deleted must exit non-zero with UnicodeEncodeError under cp932 on the synthetic release (mode: that copy is the applier checked)
# MUST-FIRE: perturbed-copy: guard-removed — a copy of tools/apply_release.py whose reconfigure calls are UNGUARDED (no hasattr) must exit non-zero when its streams lack reconfigure (Python < 3.7, simulated by a wrapper), so the old-python check sees the guard (rule-checker run 2026-10-03-605)
#
# WHY. #130: tools/bundle_win_dlls.py printed U+FFFD for every em dash on MSYS2, because a native
# Windows python pipes cp1252 + CRLF. Reproduced on ERIS 2026-10-02 (build/agent189/t130_eris.txt:
# the unfixed tool wrote 2 bytes 0x97 and 3 CRs, the fixed one 2 UTF-8 em dashes and 0 CR). The
# same class was fixed in tests/test_release_binaries.sh by sys.stdout.reconfigure(encoding="utf-8",
# newline="\n"); docs/platform/gotchas.md holds the per-PROCESS rule. PYTHONIOENCODING=cp1252 is
# the portable stand-in for that pipe: it reproduced the 0x97 byte on macOS for the unfixed tool.
#
# SCOPE: the tools listed in TOOLS below — the python tools tools/build_release_emulators.sh runs on
# the Windows track — plus the END-USER applier, which a player runs under a native Windows python
# (#212; a redirected stdout is the ANSI code page, cp932 on Japanese Windows). A new such tool is
# added here.
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
    elif [ -n "${CONTROL:-}" ] && [ "$CONTROL" != "applier-reconfigure-removed" ] && [ "$CONTROL" != "guard-removed" ]; then
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

# ── THE APPLIER (#212) on a synthetic release: no ROM byte, no ROMDIR ──
mkdir -p "$W/rel" "$W/dumps"
python3 - "$W" <<'PYEOF'
import hashlib, json, os, sys, zipfile
w = sys.argv[1]
data = b"synthetic member, not a ROM\n"
with zipfile.ZipFile(os.path.join(w, "dumps", "src.zip"), "w") as z:
    z.writestr("m.bin", data)
h = hashlib.sha1(data).hexdigest()
m = {"source": {"recipe": [], "order": [], "sha1": hashlib.sha1(b"").hexdigest()},
     "pristine_sources": [{"zip": "src.zip", "members": [{"member": "m.bin", "size": len(data), "sha1": h}]}],
     "zips": {"out.zip": [{"member": "m.bin", "size": len(data), "sha1": h,
                           "pristine_from": {"zip": "src.zip", "member": "m.bin"}}]},
     "build_fingerprint": "synthetic", "version_string": "synthetic"}
json.dump(m, open(os.path.join(w, "rel", "manifest.json"), "w"))
PYEOF
# apply <applier> <encoding> -> "<exit> <utf8 em dashes> <0x97 bytes> <UnicodeEncodeError lines>"
apply() {
    rm -rf "$W/out_$2"
    PYTHONIOENCODING=$2 python3 "$1" --romdir "$W/dumps" --out "$W/out_$2" \
        --manifest "$W/rel/manifest.json" > "$W/apply_$2.txt" 2>&1 </dev/null
    rc=$?
    echo "$rc $(python3 -c "import sys;b=open(sys.argv[1],'rb').read();print(b.count(b'\xe2\x80\x94'), b.count(b'\x97'), b.count(b'UnicodeEncodeError'))" "$W/apply_$2.txt")"
}
APPLIER=tools/apply_release.py
if [ "${CONTROL:-}" = "applier-reconfigure-removed" ]; then
    strip_reconfigure tools/apply_release.py "$W/apply_ctl_mode.py"; APPLIER="$W/apply_ctl_mode.py"
fi
set -- $(apply "$APPLIER" cp932)
if [ "$1" -eq 0 ] && [ "$2" -ge 1 ] && [ "$4" -eq 0 ] && [ -f "$W/out_cp932/out.zip" ]; then
    echo "  ok: tools/apply_release.py — exit 0 under PYTHONIOENCODING=cp932, $2 UTF-8 em dash(es), set written"
else
    echo "  FAIL: tools/apply_release.py — exit $1 under PYTHONIOENCODING=cp932, $2 UTF-8 em dash(es), $4 UnicodeEncodeError line(s)"; fail=1
fi
set -- $(apply "$APPLIER" cp1252)
if [ "$1" -eq 0 ] && [ "$2" -ge 1 ] && [ "$3" -eq 0 ]; then
    echo "  ok: tools/apply_release.py — exit 0 under PYTHONIOENCODING=cp1252, $2 UTF-8 em dash(es), 0 cp1252 0x97 bytes"
else
    echo "  FAIL: tools/apply_release.py — exit $1 under PYTHONIOENCODING=cp1252, $2 UTF-8 em dash(es), $3 cp1252 0x97 bytes"; fail=1
fi
# the must-fire control: the unfixed applier must crash under cp932 after writing
strip_reconfigure tools/apply_release.py "$W/apply_ctl.py"
set -- $(apply "$W/apply_ctl.py" cp932)
if [ "$1" -ne 0 ] && [ "$4" -ge 1 ]; then
    echo "CONTROL FIRED: applier-reconfigure-removed — the copy without the reconfigure lines exited $1 with UnicodeEncodeError under cp932"
else
    echo "CONTROL DEAD: applier-reconfigure-removed — the copy without the reconfigure lines exited $1 with $4 UnicodeEncodeError line(s) (the synthetic run no longer reaches the dash)"
    fail=1
fi

# THE OLD-PYTHON CHECK (rule-checker run 2026-10-03-605): the applier promises "Python 3", and
# TextIOWrapper.reconfigure is 3.7+; run it with streams that LACK reconfigure (a wrapper standing in for a
# pre-3.7 python, since none is installed here) — it must still write the set and exit 0
cat > "$W/oldpy.py" <<'PYEOF'
import sys, runpy
class NoReconfigure:                      # a text stream as Python < 3.7 has it: no reconfigure
    def __init__(s, f): s._f = f
    def __getattr__(s, n):
        if n == "reconfigure": raise AttributeError(n)
        return getattr(s._f, n)
sys.stdout, sys.stderr = NoReconfigure(sys.stdout), NoReconfigure(sys.stderr)
app = sys.argv[1]; sys.argv = sys.argv[1:]
runpy.run_path(app, run_name="__main__")
PYEOF
oldpy() {  # oldpy <applier> <outdir> -> exit code
    rm -rf "$2"
    python3 "$W/oldpy.py" "$1" --romdir "$W/dumps" --out "$2" --manifest "$W/rel/manifest.json" > "$2.log" 2>&1 </dev/null
    echo $?
}
unguard() {  # unguard <src> <dst>: drop the hasattr guard, keep the reconfigure call (python: BSD sed has no \| )
    python3 -c 'import re,sys; s=open(sys.argv[1]).read(); open(sys.argv[2],"w").write(re.sub(r"if hasattr\(sys\.(stdout|stderr), \"reconfigure\"\): ", "", s))' "$1" "$2"
}
OLDAPP=tools/apply_release.py
if [ "${CONTROL:-}" = "guard-removed" ]; then
    unguard tools/apply_release.py "$W/apply_unguarded_mode.py"; OLDAPP="$W/apply_unguarded_mode.py"
fi
r=$(oldpy "$OLDAPP" "$W/out_oldpy")
if [ "$r" -eq 0 ] && [ -f "$W/out_oldpy/out.zip" ]; then
    echo "  ok: tools/apply_release.py — exit 0 and the set written with streams lacking reconfigure (Python < 3.7)"
else
    echo "  FAIL: tools/apply_release.py — exit $r with streams lacking reconfigure (Python < 3.7): $(tail -1 "$W/out_oldpy.log")"; fail=1
fi
unguard tools/apply_release.py "$W/apply_unguarded.py"
if grep -q 'hasattr(sys' "$W/apply_unguarded.py"; then
    echo "CONTROL DEAD: guard-removed — the perturbation did not remove the guard"; fail=1
else
    r=$(oldpy "$W/apply_unguarded.py" "$W/out_unguarded")
    if [ "$r" -ne 0 ] && grep -q "AttributeError" "$W/out_unguarded.log"; then
        echo "CONTROL FIRED: guard-removed — the unguarded copy exited $r with AttributeError on streams lacking reconfigure"
    else
        echo "CONTROL DEAD: guard-removed — the unguarded copy exited $r (the wrapper no longer hides reconfigure)"; fail=1
    fi
fi

if [ "$fail" -eq 0 ]; then echo "PASS: test_win_stdout_utf8 — every listed tool writes UTF-8 under a cp1252 pipe, and the applier survives cp932"
else echo "FAIL: test_win_stdout_utf8"; exit 1; fi
