#!/bin/sh
# test_build_environment_entry.sh — tools/record_build_environment.py, which composes an
# entry of docs/project/build_environments.md from a host's BINARY.txt records and the log
# of a PASSING tests/test_release_binaries.sh, against SYNTHETIC records and logs: the entry
# carries the captured environment, and every way an entry could rest on something other
# than a capture REFUSES. ROM-free, no emulator, ~1 s.
#
# MUST-FIRE: perturbed-copy: gate-not-passed — the synthetic gate log with its PASS line turned into a FAIL line must make the tool REFUSE, never print an entry (mode: section 1 reads that copy)
# MUST-FIRE: perturbed-copy: env-lines-dropped — a synthetic record with its `env` lines removed must make the tool REFUSE (mode: section 1 reads that copy)
#
# WHY (maintainer, 2026-09-13): "knowing in what exact circumstances is the build known to
# be a success is the true minimum bar." An entry is only worth its capture: the tool
# refuses a log without the gate's PASS, a record for another os-arch, and a record that
# predates the environment capture.
#
# Sections: 0 the CAPTURE, tests/lib/host_env.sh, against stub package managers — one env
# line per prerequisite, NOT INSTALLED for an absent one, never an error message as a
# version, and alive under `set -e` (its first version was not: an absent package ended the
# shell); 1 a passing pair composes an entry with host, system, packages, pins, tree and the
# PASS line; 2 a record for another os-arch REFUSES; 3 the two controls.
#
# Usage: tests/test_build_environment_entry.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
TOOL="$REPO/tools/record_build_environment.py"

record() {  # record <file> <kind> <os-arch>
    cat > "$1" <<EOF
$2 — synthetic record, prebuilt for $3
===========================================

sha256 0000000000000000000000000000000000000000000000000000000000000000 $2

pin        79188379cc8442c54712acbe3b7e73dce157985f
patch      0002-cps2-wide-v1.patch  sha1 17cd7516a25e6198376bc69b88b3392d85122d0e  (the ONLY patch applied)
built      2026-09-13 on Windows via MINGW64 (x86_64), cc.exe 16.2.0, by tools/build_release_emulators.sh $2
tree       abcdef012345
jobs       8
env        Microsoft Windows [version 10.0.19045.7663]; MSYS2 runtime 3.6.10; MSYSTEM=MINGW64
env        pacman mingw-w64-x86_64-SDL2 2.32.10-1
env        pacman diffutils 3.12-1
EOF
}
perturb_gate() { sed 's/^PASS: test_release_binaries/FAIL: test_release_binaries/' "$1" > "$2"; }
perturb_env()  { grep -v '^env ' "$1" > "$2"; }

record "$W/fb.txt" fbneo windows-x86_64
record "$W/mm.txt" cps2 windows-x86_64
printf '== 1. fbneo\n  ok: ...\nPASS: test_release_binaries (windows-x86_64)\n' > "$W/gate.log"
GATE="$W/gate.log"; FB="$W/fb.txt"
if vs_ctl_is gate-not-passed; then perturb_gate "$W/gate.log" "$W/mode.log"; GATE="$W/mode.log"; fi
if vs_ctl_is env-lines-dropped; then perturb_env "$W/fb.txt" "$W/mode_fb.txt"; FB="$W/mode_fb.txt"; fi

# ---- 0. the capture: tests/lib/host_env.sh against STUB package managers (Linux and Windows
# branches), one prerequisite deliberately absent — it must read NOT INSTALLED, and the
# captured lines must compose into an entry
. "$REPO/tests/lib/host_env.sh"
mkdir -p "$W/bin"
cat > "$W/bin/dpkg-query" <<'EOF'
#!/bin/sh
for p; do :; done
case "$p" in qmake6) exit 1 ;; *) printf '9.9-stub' ;; esac
EOF
cat > "$W/bin/pacman" <<'EOF'
#!/bin/sh
case "$2" in mingw-w64-x86_64-sdl3) echo "error: package '$2' was not found" >&2; exit 1 ;; *) echo "$2 8.8-stub" ;; esac
EOF
printf '#!/bin/sh\necho "ldd (stub GLIBC 2.99) 2.99"\n' > "$W/bin/ldd"
printf '#!/bin/sh\necho; echo "Microsoft Windows [version 10.0.0000.0]"\n' > "$W/bin/cmd.exe"
chmod +x "$W/bin/dpkg-query" "$W/bin/pacman" "$W/bin/ldd" "$W/bin/cmd.exe"
( PATH="$W/bin:$PATH"; vs_host_env linux ) > "$W/env_linux.txt"
( PATH="$W/bin:$PATH"; MSYSTEM=MINGW64 vs_host_env windows ) > "$W/env_win.txt"
if grep -qx 'env        dpkg qmake6 NOT INSTALLED' "$W/env_linux.txt" \
   && grep -qx 'env        dpkg libsdl2-dev 9.9-stub' "$W/env_linux.txt" \
   && grep -q '^env        .*ldd (stub GLIBC 2.99) 2.99$' "$W/env_linux.txt" \
   && grep -qx 'env        pacman mingw-w64-x86_64-sdl3 NOT INSTALLED' "$W/env_win.txt" \
   && grep -qx 'env        pacman diffutils 8.8-stub' "$W/env_win.txt" \
   && grep -q '^env        Microsoft Windows \[version 10.0.0000.0\]; MSYS2 runtime .*; MSYSTEM=MINGW64$' "$W/env_win.txt" \
   && ! grep -q 'error' "$W/env_win.txt"; then
    echo "  0 ok: the capture prints one env line per prerequisite, NOT INSTALLED for the absent one, no error text as a version"
else
    echo "FAIL: section 0 — the capture:"; sed 's/^/        /' "$W/env_linux.txt" "$W/env_win.txt"; fail=1
fi

# ---- 1. a passing pair composes an entry
rc=0; python3 "$TOOL" windows-x86_64 "$GATE" "$FB" "$W/mm.txt" > "$W/s1.txt" 2>&1 || rc=$?
if [ "$rc" = 0 ] \
   && grep -q '^### windows-x86_64 — FBNeo + MAME, built 2026-09-13$' "$W/s1.txt" \
   && grep -q 'pacman `mingw-w64-x86_64-SDL2` 2.32.10-1' "$W/s1.txt" \
   && grep -q '| system | Microsoft Windows \[version 10.0.19045.7663\]' "$W/s1.txt" \
   && grep -q 'tree `abcdef012345`, jobs 8' "$W/s1.txt" \
   && grep -q 'PASS: test_release_binaries (windows-x86_64)' "$W/s1.txt"; then
    echo "  1 ok: a passing pair composes the entry — host, system, packages, pins, tree, the PASS line"
else
    echo "FAIL: section 1 — exit $rc, entry:"; sed 's/^/        /' "$W/s1.txt"; fail=1
fi
# ---- 2. a record for another os-arch REFUSES
record "$W/other.txt" fbneo linux-x86_64
rc=0; python3 "$TOOL" windows-x86_64 "$W/gate.log" "$W/other.txt" > "$W/s2.txt" 2>&1 || rc=$?
if [ "$rc" = 2 ] && grep -q '^REFUSED: .* is a record for linux-x86_64, not windows-x86_64' "$W/s2.txt"; then
    echo "  2 ok: a record for another os-arch refuses"
else
    echo "FAIL: section 2 — exit $rc:"; sed 's/^/        /' "$W/s2.txt"; fail=1
fi

# ---- 3. must-fire controls
perturb_gate "$W/gate.log" "$W/c1.log"
rc=0; python3 "$TOOL" windows-x86_64 "$W/c1.log" "$W/fb.txt" > "$W/c1.txt" 2>&1 || rc=$?
if [ "$rc" = 2 ] && grep -q '^REFUSED: .*has no `PASS: test_release_binaries' "$W/c1.txt"; then
    vs_ctl_fired gate-not-passed "$(head -1 "$W/c1.txt")"
else
    vs_ctl_dead gate-not-passed "exit $rc: $(head -1 "$W/c1.txt")" || true; fail=1
fi
perturb_env "$W/fb.txt" "$W/c2.txt.rec"
rc=0; python3 "$TOOL" windows-x86_64 "$W/gate.log" "$W/c2.txt.rec" > "$W/c2.txt" 2>&1 || rc=$?
if [ "$rc" = 2 ] && grep -q '^REFUSED: .*no `env` line' "$W/c2.txt"; then
    vs_ctl_fired env-lines-dropped "$(head -1 "$W/c2.txt")"
else
    vs_ctl_dead env-lines-dropped "exit $rc: $(head -1 "$W/c2.txt")" || true; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: test_build_environment_entry" || { echo "FAIL: test_build_environment_entry"; exit 1; }
