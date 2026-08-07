#!/bin/sh
# run_hui_behavior.sh — the Huitzil playtest build, interactive.
# 14z-67 (ping #8, build/hui9): the ping-#7 fix round — 236P freeze ray
# restored (effect byte-map rows), command-grab throw arc native-exact
# (yv 16.0 — the victim leaves the screen top), companion-record art
# to bank 5. STILL OPEN from ping #7: grab lightning + beam
# duration/palette (the effect-zone clone arc), sidekick shadow,
# win-screen palettes, DF style, FG pacing.
# No forced id: WALK THE WHEEL to his own cell (from Demitri's default
# cell: Down, Down, Down — the appended bottom row) and pick him there.
#
# WHAT TO EXPECT (deliberate, not bugs):
#   * Voice lines/new sfx are SILENT (stubbed until the M5 voice port —
#     maintainer-stated scope, D4).
#   * VS2 flavor is the default; hold START while confirming for VH2
#     (looser float).
#   * Cells 0x11 (Pyron) and 0x13 (Donovan) also exist on the wheel of
#     this SINGLE-TENANT build; only Phobos's cell is backed — picking
#     the others is untested content on this build.
# Ground truth for comparison: native Phobos on vsav2.
#
# Usage: ROMDIR=... tools/run_hui_behavior.sh [outbase=build/hui9]
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
OUTBASE="${1:-build/hui9}"

if [ ! -f "$OUTBASE/rompath/vsavjw.zip" ]; then
    echo "building the stage-6 gfx build at $OUTBASE ..."
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 6 "$OUTBASE" | tail -2
fi

MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "WIDE MAME missing — tools/setup_mame.sh"; exit 1; }

echo "Launching. Phobos = his own wheel cell (D,D,D from default). Esc quits."
exec "$MAME_BIN" vsavjw \
    -rompath "$(cd "$OUTBASE/rompath" && pwd);$ROMDIR" \
    -skip_gameinfo
