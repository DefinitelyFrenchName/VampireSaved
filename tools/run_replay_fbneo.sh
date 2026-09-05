#!/bin/sh
# run_replay_fbneo.sh — run one input-script replay on patched FBNeo, emit
# checksum log (format-identical to the MAME harness logs).
#
# Usage: ROMDIR=... tools/run_replay_fbneo.sh <set> <replay.rpl> <out.log> [sandbox]
#   env FBNEO_DUMPS    optional "-hdump" spec, same grammar as the MAME
#                      harness DUMPS ("2900:ff8000-ff8700;..."); dump files
#                      land next to <out.log> as <out.log>.dump_<f>_<a>.bin
#   env FBNEO_ROMPATH  optional dir of zips overlaying $ROMDIR (patched-build
#                      runs: its vsavj.zip wins over the reference one)
#   env FBNEO_BIN      optional alternate fbneo binary (A/B of emulator builds)
#   env FBNEO_HVIDEO   optional path for per-frame FRAMEBUFFER checksums.
#                      The RAM checksum is blind to the whole video path, so
#                      any rendering change needs this to be tested at all.
set -eu

SET="${1:?usage: run_replay_fbneo.sh <set> <replay.rpl> <out.log> [sandbox]}"
RPL="${2:?replay path required}"
OUT="${3:?output log path required}"
SANDBOX="${4:-}"
# ABSOLUTE (14z-133b, measured): the emulator runs from inside the overlay/
# sandbox, so a RELATIVE sandbox argument produced NO checksum log at all —
# 0 lines vs 3,120 on the same replay with an absolute one — and the caller
# read an empty file as "no dumps". Same class as the relative FBNEO_ROMPATH
# note below and the gates' $ROMDIR normalisation (14z-132).
if [ -n "$SANDBOX" ]; then mkdir -p "$SANDBOX"; SANDBOX="$(cd "$SANDBOX" && pwd)"; fi
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
# FBNEO_BIN overrides the binary — used by the WIDE emulator superset
# invariant, which A/Bs a pre-patch build against the patched one.
FBNEO="${FBNEO_BIN:-$REPO/emu/fbneo/fbneo}"
[ -x "$FBNEO" ] || { echo "no FBNeo binary; build: (cd emu/fbneo && make sdl2 SKIPDEPEND=1 -j8)"; exit 1; }

RPL="$(cd "$(dirname "$RPL")" && pwd)/$(basename "$RPL")"
OUT_DIR="$(cd "$(dirname "$OUT")" && pwd)"; OUT="$OUT_DIR/$(basename "$OUT")"

# 14z-90 (GitHub issue #12), the SHELL half. The completion check below is
# `grep -q "^END " "$OUT"` — an ARTIFACT check — and nothing here removed the
# artifact first. Combined with the C++ half (main.cpp discards HarnessRun()'s
# status inside a void DoGame and returns 0 unconditionally, so a harness that
# never ran still exits 0), a failed run left the PREVIOUS run's log in place
# and the caller read it as success. Committed gates are saved by mktemp-fresh
# paths, but docs/platform/gotchas.md:703 documents the interactive recipe with
# a fixed reusable `out.log`, and the gotcha above it records that the
# emulator's own error text is hidden in the sandbox log. Silent failure + a
# hidden error + a fixed path is how a previous build's .tap gets written into
# an atlas row.
#
# So: clear the outputs BEFORE the run. After this the run either produces a
# fresh artifact or leaves none, and "no END line" cannot be satisfied by
# yesterday's file. FBNEO_HVIDEO/FBNEO_HTAP_OUT are read via getenv inside the
# harness and never appear in argv, so they must be cleared by name.
rm -f "$OUT" "$OUT".tap "$OUT".dump_*.bin "$OUT".gfx_*.bin
[ -n "${FBNEO_HVIDEO:-}" ] && rm -f "$FBNEO_HVIDEO"
[ -n "${FBNEO_HTAP_OUT:-}" ] && rm -f "$FBNEO_HTAP_OUT"

WORK="${SANDBOX:-$(mktemp -d)}"
mkdir -p "$WORK"
if [ -n "${FBNEO_ROMPATH:-}" ]; then
    # 14z-110: ABSOLUTE-IZE the overlay dir first. The symlinks below are
    # created from the caller's cwd but resolved from INSIDE the sandbox
    # (the emulator cds there), so a relative FBNEO_ROMPATH produced broken
    # links and a bare "DrvInit failed" with every member present — measured:
    # a relative invocation of test_dualtrack failed its first leg this way.
    FBNEO_ROMPATH="$(cd "$FBNEO_ROMPATH" && pwd)"
    # per-zip overlay: reference zips first, overlay zips win
    # 14z-90 (#38): NO trailing slash on the rm — `rm -rf "$WORK/roms/"`
    # follows a symlink and would empty $ROMDIR. On the non-overlay branch
    # below this path IS a symlink to $ROMDIR, and sandboxes get reused.
    rm -rf "$WORK/roms"; mkdir -p "$WORK/roms"
    for z in "$ROMDIR"/*.zip; do ln -sf "$z" "$WORK/roms/$(basename "$z")"; done
    for z in "$FBNEO_ROMPATH"/*.zip; do ln -sf "$z" "$WORK/roms/$(basename "$z")"; done
else
    # 14z-94 (#38): CLEAR IT FIRST. `ln -sfn` cannot replace a real
    # DIRECTORY — on BSD/macOS it creates "$WORK/roms/$(basename $ROMDIR)"
    # inside it instead — so a REUSED sandbox that previously ran WITH
    # FBNEO_ROMPATH kept its overlay directory, and this branch went on
    # serving the PREVIOUS run's patched zips while the caller believed it
    # was running against pristine $ROMDIR. Silent, and exactly backwards
    # from what a non-overlay run is for.
    # No trailing slash, for the same reason the overlay branch says so: if
    # this path is already a symlink to $ROMDIR, `rm -rf "$WORK/roms/"`
    # would follow it and empty the reference sets.
    rm -rf "$WORK/roms"
    ln -sfn "$ROMDIR" "$WORK/roms"
fi

set -- "$SET" -hinput "$RPL" -hout "$OUT"
[ -n "${FBNEO_DUMPS:-}" ] && set -- "$@" -hdump "$FBNEO_DUMPS"

( cd "$WORK" && HOME="$WORK" SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
    "$FBNEO" "$@" > "$WORK/fbneo_replay.log" 2>&1 ) \
    || { cat "$WORK/fbneo_replay.log"; exit 1; }
grep -q "^END " "$OUT" || { echo "harness did not complete (no END line)"; cat "$WORK/fbneo_replay.log"; exit 1; }
