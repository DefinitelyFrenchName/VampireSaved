#!/bin/sh
# run_fbneo.sh — headless, sandboxed FBNeo invocation.
#
# Usage: ROMDIR=/path/to/roms tools/run_fbneo.sh <set> [fbneo args...]
#
# Runs the submodule-built SDL2 FBNeo (emu/fbneo/fbneo) with SDL dummy
# video/audio drivers from a FRESH sandbox directory. FBNeo's SDL frontend
# searches "roms/" relative to cwd, so the sandbox gets a symlink to ROMDIR;
# its config/nvram land in the sandbox too, never in the repo or HOME.
# Set FBNEO_SANDBOX=/some/dir to inspect or reuse a sandbox.
#
# NOTE: the SDL2 frontend has no scripting; this wrapper gives us boot/soak
# runs only. The per-frame RAM-checksum hook (mirroring the MAME Lua probe)
# is the planned FBNeo-side harness patch — see STATE.md next actions.
set -eu

SET="${1:?usage: run_fbneo.sh <set> [fbneo args...]}"
shift
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
FBNEO="$REPO/emu/fbneo/fbneo"
[ -x "$FBNEO" ] || { echo "no FBNeo binary at $FBNEO — build: (cd emu/fbneo && make sdl2 SKIPDEPEND=1 -j8)"; exit 1; }

SANDBOX="${FBNEO_SANDBOX:-$(mktemp -d)}"
mkdir -p "$SANDBOX"
ln -sfn "$ROMDIR" "$SANDBOX/roms"

cd "$SANDBOX"
# HOME override: FBNeo persists config under ~/Library/Application Support/
# (macOS); leaked config between runs would break reproducibility, so each
# sandbox gets its own.
HOME="$SANDBOX" SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy exec "$FBNEO" "$SET" "$@"
