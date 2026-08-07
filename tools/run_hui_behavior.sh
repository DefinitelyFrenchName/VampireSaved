#!/bin/sh
# run_hui_behavior.sh — the Huitzil BEHAVIOR playtest build, interactive
# (14z-65, ping #1). Builds stage 4 if needed and launches windowed MAME
# with sound: pick ANY character as P1 — you get Phobos (the id is forced
# by tests/lua/force_id.lua; his wheel cell arrives with the gfx stage).
#
# WHAT TO EXPECT (deliberate, not bugs):
#   * P1's BODY IS GARBLED TILES — no gfx stage yet; judge BEHAVIOR only:
#     moves coming out, projectiles/pods, damage, meter, throws, feel.
#   * Voice lines/new sfx are SILENT (stubbed until the M5 voice port).
#   * The select screen shows the character you picked, not Phobos.
#   * Attract demos also cast P1 as Phobos — odd attract behavior is
#     reportable data (that flow is unsoaked).
# Ground truth for comparison: native Phobos on vsav2.
#
# Usage: ROMDIR=... tools/run_hui_behavior.sh [outbase=build/hui4]
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
OUTBASE="${1:-build/hui4}"

if [ ! -f "$OUTBASE/rompath/vsavjw.zip" ]; then
    echo "building the stage-4 behavior build at $OUTBASE ..."
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 4 "$OUTBASE" | tail -2
fi

MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "WIDE MAME missing — tools/setup_mame.sh"; exit 1; }

echo "Launching. P1 = Phobos regardless of pick. Esc quits."
FORCE_ID=10 exec "$MAME_BIN" vsavjw \
    -rompath "$(cd "$OUTBASE/rompath" && pwd);$ROMDIR" \
    -autoboot_script "$REPO/tests/lua/force_id.lua" \
    -skip_gameinfo
