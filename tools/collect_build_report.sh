#!/bin/sh
# collect_build_report.sh — one file that says what happened on this host, so a
# failed release-binary build is one round trip instead of three.
#
# Usage:  tools/collect_build_report.sh [outfile]
#   ROMDIR=~/roms  MERGED=build/fromrelease  tools/collect_build_report.sh
#
# Writes build-report-<os-arch>-<date>.txt in the current directory (or the
# path you name) and prints where it put it.
#
# WHAT IT COLLECTS: the preflight, tool versions, the builder's CHECK=1 plan
# for both kinds, the tail of whatever build logs exist, every BINARY.txt
# record on this host, and the gate's own output if it has been run.
#
# WHAT IT NEVER COLLECTS (rule 7, and plain privacy): no ROM data, no contents
# of your dumps, no zip members — only file NAMES and whether a checksum
# matched. The one place dumps are touched at all is `audit_roms.py`, which
# reads them and prints verdicts. Nothing here reads a ROM byte into the file.
#
# Written 14z-150 for the first Windows/WSL2 session, alongside
# docs/project/WINDOWS_BUILD.md.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"

case "$(uname -s)" in
Darwin) OS=macos ;;
Linux)  OS=linux ;;
MINGW*|MSYS*|CYGWIN*) OS=windows ;;
*) OS="$(uname -s | tr 'A-Z' 'a-z')" ;;
esac
case "$(uname -m)" in arm64|aarch64) ARCH=arm64 ;; x86_64|amd64) ARCH=x86_64 ;; *) ARCH="$(uname -m)" ;; esac
OSARCH="$OS-$ARCH"
OUT="${1:-build-report-$OSARCH-$(date -u +%Y%m%d-%H%M).txt}"

section() { printf '\n=== %s %s\n' "$1" "$(printf '%0.s-' 1 2 3 4 5 6 7 8 9 0)" ; }
run()     { printf '\n$ %s\n' "$*"; "$@" 2>&1 | sed 's/^/  /' || printf '  (exit %s)\n' "$?"; }

{
printf 'VAMPIRE SAVED — release-binary build report\n'
printf 'generated  %s\n' "$(date -u +'%Y-%m-%d %H:%M UTC')"
printf 'os-arch    %s\n' "$OSARCH"
printf 'uname      %s\n' "$(uname -a)"
printf 'shell      %s   MSYSTEM=%s\n' "${SHELL:-?}" "${MSYSTEM:-<unset>}"
printf 'cwd        %s\n' "$(pwd)"
printf 'ROMDIR     %s\n' "${ROMDIR:-<unset>}"
printf 'MERGED     %s\n' "${MERGED:-<unset>}"
printf '\nNOTE: this file contains NO ROM data — only file names and verdicts.\n'

section "git"
run git log --oneline -3
run git status --short --branch
run git submodule status

section "preflight"
if [ -x tools/preflight_release_build.sh ]; then
    printf '\n$ tools/preflight_release_build.sh\n'
    tools/preflight_release_build.sh 2>&1 | sed 's/^/  /'
    printf '  (exit %s)\n' "$?"
else
    printf '  tools/preflight_release_build.sh not present\n'
fi

section "tool versions"
for t in gcc g++ make python3 git patchelf pkg-config pkgconf sdl2-config ldd objdump readelf strings perl zip; do
    if command -v "$t" >/dev/null 2>&1; then
        printf '  %-12s %s\n' "$t" "$("$t" --version 2>&1 | head -1)"
    else
        printf '  %-12s ABSENT\n' "$t"
    fi
done
if command -v pkg-config >/dev/null 2>&1; then
    printf '  %-12s %s\n' "sdl3(pkg)" "$(pkg-config --modversion sdl3 2>&1 | head -1)"
fi

section "the builder's plan (CHECK=1 — builds nothing)"
for k in fbneo mame; do
    printf '\n$ CHECK=1 tools/build_release_emulators.sh %s\n' "$k"
    CHECK=1 tools/build_release_emulators.sh "$k" 2>&1 | sed 's/^/  /'
done

section "build logs (tails)"
for f in "${BUILD_SCRATCH:-$HOME/.cache/vampire-saved}"/fbneo-release/build.log \
         "${BUILD_SCRATCH:-$HOME/.cache/vampire-saved}"/mame-release.log; do
    if [ -f "$f" ]; then
        printf '\n--- %s (last 60 lines)\n' "$f"
        tail -60 "$f" | sed 's/^/  /'
    else
        printf '\n--- %s : absent\n' "$f"
    fi
done

section "what was produced"
if [ -d release/emulators ]; then
    run find release/emulators -maxdepth 3 -type d
    for rec in release/emulators/*/*/BINARY.txt; do
        [ -f "$rec" ] || continue
        printf '\n--- %s\n' "$rec"
        sed 's/^/  /' "$rec"
    done
    printf '\n--- file inventory (names and sizes only)\n'
    find release/emulators -type f -exec ls -l {} \; 2>/dev/null | awk '{print "  " $5 "  " $NF}'
else
    printf '  release/emulators/ does not exist yet\n'
fi

section "the romset the gate boots"
M="${MERGED:-build/fromrelease}"
if [ -f "$M/rompath/vsavjw.zip" ]; then
    printf '  %s/rompath/vsavjw.zip present (%s bytes)\n' "$M" "$(wc -c < "$M/rompath/vsavjw.zip" | tr -d ' ')"
    if command -v python3 >/dev/null 2>&1 && [ -f tools/build_fingerprint.py ]; then
        printf '  program fingerprint: %s\n' "$(python3 tools/build_fingerprint.py "$M/rompath" --set vsavjw --sha-only 2>&1 | head -1)"
        printf '  (merged-m18 is 1d8bedc5a6aa784967595b95c092fcb5f1c68f26)\n'
    fi
else
    printf '  %s/rompath/vsavjw.zip ABSENT — see WINDOWS_BUILD.md section 3\n' "$M"
fi
if [ -n "${ROMDIR:-}" ] && [ -f tools/audit_roms.py ]; then
    printf '\n$ python3 tools/audit_roms.py "$ROMDIR"   (verdicts only, no ROM data)\n'
    python3 tools/audit_roms.py "$ROMDIR" 2>&1 | tail -5 | sed 's/^/  /'
fi

section "the gate"
if [ -n "${ROMDIR:-}" ]; then
    printf '\n$ MERGED=%s tests/test_release_binaries.sh\n' "$M"
    MERGED="$M" tests/test_release_binaries.sh 2>&1 | sed 's/^/  /'
    printf '  (exit %s)\n' "$?"
else
    printf '  ROMDIR is not set — export it and re-run to include the gate\n'
fi

section "end of report"
} > "$OUT" 2>&1

printf 'wrote %s (%s lines)\n' "$OUT" "$(wc -l < "$OUT" | tr -d ' ')"
printf 'It contains no ROM data. Send this one file.\n'
