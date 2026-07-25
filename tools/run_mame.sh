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

exec mame "$SET" \
    -rompath "$ROMPATH" \
    -video none -sound none -nothrottle -skip_gameinfo \
    -cfg_directory "$SANDBOX/cfg" \
    -nvram_directory "$SANDBOX/nvram" \
    -diff_directory "$SANDBOX/diff" \
    -snapshot_directory "$SANDBOX/snap" \
    -state_directory "$SANDBOX/sta" \
    -homepath "$SANDBOX" \
    "$@"
