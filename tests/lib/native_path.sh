#!/bin/sh
# native_path.sh — ONE translator for the boundary between this shell and a
# NATIVE program, sourced by anything that hands a path to an emulator.
#
# WHY IT EXISTS (2026-09-12, the first Windows session). On MSYS2 the shell
# lives in MSYS's namespace — `/home/you/…`, `/c/Windows/…`, `/mingw64/bin/…`
# — while MAME and FBNeo are NATIVE WINDOWS programs that read `/home/you` as
# the current drive's `\home\you` and find nothing. The two namespaces look
# alike and are not, which is the whole family of bug this session paid for
# three times: `ldd` answering in MSYS form to a native python
# (tools/bundle_win_dlls.py), and every `-rompath`, `-autoboot_script`,
# sandbox directory and Lua-read environment variable below.
#
# `cygpath -w` is MSYS2's OWN answer and therefore cannot disagree with the
# tools that produced the path. OFF WINDOWS THIS FILE IS A NO-OP BY
# CONSTRUCTION — `native_path` returns its argument untouched — so no
# measurement on macOS or Linux can move because of it ([CPE-24]: changing an
# instrument invalidates every measurement taken with it, so the change must
# be inert where the instrument already worked).
#
# native_path  <path>          -> the same path a native program can open
# native_pathlist <a;b;c>      -> the same, element by element, ';' kept

case "$(uname -s 2>/dev/null)" in
MSYS*|MINGW*|CYGWIN*) VS_NATIVE=1 ;;
*)                    VS_NATIVE=0 ;;
esac

native_path() {
    if [ "$VS_NATIVE" = 0 ] || [ -z "${1:-}" ]; then printf '%s' "${1:-}"; return 0; fi
    case "$1" in
    /*) if command -v cygpath >/dev/null 2>&1; then
            cygpath -w "$1" | tr -d '\r\n'
        else
            printf '%s' "$1"        # no translator: unchanged, and it will fail LOUDLY
        fi ;;
    *)  printf '%s' "$1" ;;         # already native, or relative: leave it alone
    esac
}

native_pathlist() {   # a ';'-separated search path, translated element by element
    if [ "$VS_NATIVE" = 0 ] || [ -z "${1:-}" ]; then printf '%s' "${1:-}"; return 0; fi
    _out=""; _rest="$1"
    while [ -n "$_rest" ]; do
        case "$_rest" in
        *\;*) _one="${_rest%%;*}"; _rest="${_rest#*;}" ;;
        *)    _one="$_rest"; _rest="" ;;
        esac
        _one="$(native_path "$_one")"
        if [ -z "$_out" ]; then _out="$_one"; else _out="$_out;$_one"; fi
    done
    printf '%s' "$_out"
}
