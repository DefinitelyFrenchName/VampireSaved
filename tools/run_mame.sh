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

# MAME_BIN selects the emulator binary; defaults to whatever `mame` is on PATH
# (the Homebrew 0.288 the frozen expectations were created with). B5 points it
# at the pinned source build (tools/setup_mame.sh) and at the WIDE-patched
# binary. Nothing else about the invocation changes, so the runs stay
# comparable to every frozen log.
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
exec "${MAME_BIN:-mame}" "$SET" \
    -rompath "$ROMPATH" \
    -keyboardprovider none -mouseprovider none \
    -joystickprovider none -lightgunprovider none \
    -video none -sound none -nothrottle -skip_gameinfo \
    -cfg_directory "$SANDBOX/cfg" \
    -nvram_directory "$SANDBOX/nvram" \
    -diff_directory "$SANDBOX/diff" \
    -snapshot_directory "$SANDBOX/snap" \
    -state_directory "$SANDBOX/sta" \
    -homepath "$SANDBOX" \
    "$@"
