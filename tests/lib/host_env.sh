#!/bin/sh
# host_env.sh — the build ENVIRONMENT a release binary's record carries: one system line and
# one "env        <manager> <package> <version>" line per prerequisite, read from THIS host's
# own package manager. Sourced by tools/build_release_emulators.sh (written into BINARY.txt
# beside `built`); tested against stub package managers by
# tests/test_build_environment_entry.sh; entries of docs/project/build_environments.md are
# composed from these lines by tools/record_build_environment.py — never retyped.
#
# vs_host_env <hostos>      hostos: macos | linux | windows (the builder's HOSTOS)
#
# MEASURED 2026-09-13 on all three hosts, with a positive control each: `brew list --versions`,
# `pacman -Q` and `dpkg-query -W` print NOTHING on stdout for an absent package (dpkg-query also
# for a known-but-not-installed one), so an absent prerequisite reads NOT INSTALLED and an error
# message can never be recorded as a version.
#
# The lists are the preflight's install hints (tools/preflight_release_build.sh) — FBNeo's and
# MAME's prerequisites together — plus what the hint leaves implicit (gcc on Linux).
#
# EVERY QUERY ENDS `|| true`, and that is load-bearing: the builder runs under `set -e`, where an
# assignment from a `$( … )` whose command fails ENDS THE SHELL — `dpkg-query` and `pacman -Q`
# exit 1 on an absent package, so without it the one host missing a prerequisite would lose its
# whole build to the line that records the fact (caught by this file's own test, 2026-09-13;
# the trap is the 14z-136 `$( … )`-under-`set -e` capture family).
vs_host_env() {
    case "$1" in
    macos)
        echo "env        macOS $(sw_vers -productVersion 2>/dev/null || true) $(uname -m); Command Line Tools $(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk '/^version/{print $2}' || true)"
        for _p in sdl2-compat sdl3 sdl2_image pkgconf; do
            _v="$(brew list --versions "$_p" 2>/dev/null | cut -d' ' -f2- || true)"
            echo "env        brew $_p ${_v:-NOT INSTALLED}"
        done ;;
    linux)
        echo "env        $( (. /etc/os-release && echo "$PRETTY_NAME") 2>/dev/null || true ) (kernel $(uname -r)); $(ldd --version 2>/dev/null | head -1 || true)"
        for _p in build-essential gcc make python3 git rsync patch pkgconf zip unzip perl patchelf binutils coreutils diffutils libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev libfontconfig-dev qmake6; do
            _v="$(dpkg-query -W -f='${Version}' "$_p" 2>/dev/null || true)"
            echo "env        dpkg $_p ${_v:-NOT INSTALLED}"
        done ;;
    windows)
        echo "env        $(cmd.exe //c ver 2>/dev/null | tr -d '\r' | grep -v '^$' || true); MSYS2 runtime $(uname -r); MSYSTEM=${MSYSTEM:-unset}"
        for _p in git make patch rsync zip unzip perl coreutils diffutils mingw-w64-x86_64-gcc mingw-w64-x86_64-binutils mingw-w64-x86_64-python mingw-w64-x86_64-pkgconf mingw-w64-x86_64-SDL2 mingw-w64-x86_64-SDL2_image mingw-w64-x86_64-sdl3; do
            _v="$(pacman -Q "$_p" 2>/dev/null | cut -d' ' -f2 || true)"
            echo "env        pacman $_p ${_v:-NOT INSTALLED}"
        done ;;
    *)  echo "env        (no package-manager query is written for $1)" ;;
    esac
}
