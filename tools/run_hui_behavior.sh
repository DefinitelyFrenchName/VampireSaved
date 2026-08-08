#!/bin/sh
# run_hui_behavior.sh — the Huitzil playtest build, interactive.
# 14z-68 (PING #9, build/hui10 = 64128aa7): THE WIN-SCREEN PALETTE.
# Win a match as Phobos and check the victory portrait — it should be
# GOLD (his normal family), where ping #8 showed pink/lavender. That
# is the ONE thing this build is for; details + what is deliberately
# still broken: build/hui10/PING9_ARTIFACT.md.
# STILL OPEN (do not re-report): the garbled blue-grey blocks on the
# win pose (a SEPARATE art defect from the palette), the 236P beam +
# ES big-beam/grab-lightning/214 family, the child companion's
# rectangular shadow, DF style, FG pacing.
# Previous: 14z-67 (ping #8, build/hui9) — 236P freeze ray restored,
# command-grab throw arc native-exact (yv 16.0), companion art bank 5.
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
# Usage: ROMDIR=... tools/run_hui_behavior.sh [outbase=build/hui10]
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
OUTBASE="${1:-build/hui10}"

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
