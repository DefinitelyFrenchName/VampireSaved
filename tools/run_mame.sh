#!/bin/sh
# run_mame.sh — headless, sandboxed MAME invocation (SMS run.sh pattern).
#
# Usage: ROMDIR=/path/to/roms tools/run_mame.sh <set> [extra mame args...]
#
# Every run gets a FRESH sandbox for cfg/nvram/etc under $MAME_SANDBOX (or a
# mktemp dir), so runs are reproducible: no leaked EEPROM/nvram state between
# runs, which would silently break determinism comparisons. Set
# MAME_SANDBOX=/some/dir to inspect or reuse a sandbox (e.g. to test
# nvram-carrying scenarios deliberately).
set -eu

SET="${1:?usage: run_mame.sh <set> [mame args...]}"
shift
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"

SANDBOX="${MAME_SANDBOX:-$(mktemp -d)}"
mkdir -p "$SANDBOX"

# MAME_ROMPATH overrides the rompath (e.g. "patched_dir;$ROMDIR" for patched
# builds); defaults to ROMDIR. Everything else (fresh sandbox) is unchanged,
# so a patched-build run is directly comparable to a frozen vanilla run.
ROMPATH="${MAME_ROMPATH:-$ROMDIR}"

# MAME_BIN selects the emulator binary. UNSET, it defaults BY SET NAME to a PINNED
# source build (#196, maintainer-ruled 2026-10-02 "By set name"): `vsavjw` -> the
# WIDE build ~/.cache/vampire-saved/mame/cps2, every stock set -> the reference
# build ~/.cache/vampire-saved/mame-ref/cps2 (tools/setup_mame.sh builds both). A
# missing default is REFUSED, never replaced by whatever `mame` is on PATH: until
# 14z-189 an unset MAME_BIN ran PATH's `mame` (Homebrew 0.288 on the Mac, a shim
# on Linux), so a by-hand run's instrument depended on the host. Measured before
# the change (build/agent189/t196/): the 15 gates that never set MAME_BIN gave
# the same verdict and output under all three binaries, teardown PIDs aside.
# Inside a tier tests/run_all_emulator.sh exports MAME_BIN, so nothing changes
# there. Nothing else about the invocation changes, so the runs stay comparable
# to every frozen log. Gate: tests/test_mame_default_bin.sh.
# TRUE HEADLESS (added 14z-59d). MAME's "-video none" still creates an SDL
# window; SDL_VIDEODRIVER=dummy means SDL creates no window AT ALL, so
# there is nothing to steal focus and nothing for a stray keystroke to land
# on. This is the fix at the source and it works on the current machine
# today — no migration required.
# Measured non-perturbing: work RAM bit-identical to the frozen
# expectations, and VIDEO_OUT still captures a live framebuffer (3,952
# distinct checksums over 5,520 frames, unchanged), because the emulated
# bitmap is internal to MAME and owes nothing to SDL.
# Override with SDL_VIDEODRIVER=<driver> if a run ever needs a real window.
: "${SDL_VIDEODRIVER:=dummy}"
export SDL_VIDEODRIVER

# INPUT ISOLATION (added 14z-59c). MAME's "-video none" still creates a
# window that can take focus, and any host keystroke that lands on it is
# injected into the EMULATED controls — MAME's default keyboard map covers
# P1 directions/buttons, coins and start. A replay is only reproducible if
# its inputs come exclusively from the script, so all four host input
# providers are disabled. This is not a preference; a run that can absorb a
# stray keypress is not an oracle.
# The maintainer runs the harness on their working laptop, which makes this
# a live hazard rather than a theoretical one, and it is the leading
# explanation for the two 14z-59 divergences (STATE.md).
# Verified non-perturbing: the frozen vanilla suite reproduces bit-for-bit
# with these flags set.
# THE ONE BOUNDARY between this shell and a native program. Off Windows every
# call below returns its argument untouched, so this block is inert on the
# hosts where the instrument already worked ([CPE-24]).
. "$(cd "$(dirname "$0")/.." && pwd)/tests/lib/native_path.sh"
if [ "$VS_NATIVE" = 1 ]; then
    ROMPATH="$(native_pathlist "$ROMPATH")"
    # the Lua running INSIDE MAME opens these by name, and it is native too
    for _v in REPLAY CHECKSUM_OUT VIDEO_OUT INPUT_OUT DUMPS MASK_BASIS; do
        eval "_cur=\${$_v:-}"
        [ -z "$_cur" ] || eval "export $_v=\"\$(native_path \"\$_cur\")\""
    done
    # and every absolute path in the caller's own arguments (-autoboot_script …)
    _args=""
    for _a in "$@"; do
        case "$_a" in /*) _a="$(native_path "$_a")" ;; esac
        _args="$_args $(printf '%s' "$_a" | sed "s/'/'\\\\''/g; s/^/'/; s/\$/'/")"
    done
    eval "set -- $_args"
    NSANDBOX="$(native_path "$SANDBOX")"
else
    NSANDBOX="$SANDBOX"
fi
# THE FALLBACK INVENTORY (14z-188, GitHub #196), opt-in and inert unless asked: with MAME_FALLBACK_LOG set, a run
# that runs with MAME_BIN UNSET (since 14z-189 it takes the pinned default by set name; before, `mame` on PATH) appends one line — the UTC time, the set, and the first
# tests/<gate>.sh among this process's ancestors (or "-") — so one emulator tier names every gate that depends on
# what `mame` happens to be. Nothing is printed and nothing else changes; unset, the line below never runs.
if [ -z "${MAME_BIN:-}" ] && [ -n "${MAME_FALLBACK_LOG:-}" ]; then
    _fg="-"; _fp=$PPID; _fi=0
    while [ "$_fi" -lt 12 ] && [ -n "$_fp" ] && [ "$_fp" != 0 ] && [ "$_fp" != 1 ]; do
        _fa="$(ps -o args= -p "$_fp" 2>/dev/null || true)"
        case "$_fa" in *tests/*.sh*) _fg="$(printf '%s\n' "$_fa" | tr ' ' '\n' | grep -m1 'tests/[^/]*\.sh$' || echo -)"; break ;; esac
        _fp="$(ps -o ppid= -p "$_fp" 2>/dev/null | tr -d ' ' || true)"; _fi=$((_fi + 1))
    done
    printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SET" "$_fg" >> "$MAME_FALLBACK_LOG" 2>/dev/null || true
fi
if [ -z "${MAME_BIN:-}" ]; then
    case "$SET" in
        vsavjw) MAME_BIN="$HOME/.cache/vampire-saved/mame/cps2" ;;
        *)      MAME_BIN="$HOME/.cache/vampire-saved/mame-ref/cps2" ;;
    esac
    if [ ! -x "$MAME_BIN" ]; then
        echo "run_mame.sh: MAME_BIN is unset and the pinned default for set '$SET' is absent: $MAME_BIN" >&2
        echo "  build it with tools/setup_mame.sh, or set MAME_BIN (#196: no fall back to the mame on PATH)" >&2
        exit 2
    fi
fi
exec "$MAME_BIN" "$SET" \
    -rompath "$ROMPATH" \
    -keyboardprovider none -mouseprovider none \
    -joystickprovider none -lightgunprovider none \
    -video none -sound none -nothrottle -skip_gameinfo \
    -cfg_directory "$NSANDBOX/cfg" \
    -nvram_directory "$NSANDBOX/nvram" \
    -diff_directory "$NSANDBOX/diff" \
    -snapshot_directory "$NSANDBOX/snap" \
    -state_directory "$NSANDBOX/sta" \
    -homepath "$NSANDBOX" \
    "$@"
