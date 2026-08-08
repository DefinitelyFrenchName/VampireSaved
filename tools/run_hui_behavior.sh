#!/bin/sh
# run_hui_behavior.sh — the Huitzil playtest build, interactive.
# 14z-69p (PING #12, build/hui14 = c25b3824): THE DARK FORCE PALETTE
# is fixed — he now flashes his own warm GOLD ramp instead of the
# purple one. The afterimages REMAIN on purpose: that mode is his
# real Vampire Savior Dark Force (mechanically sound, vanilla stock
# cost, clean entry/exit) and you asked to keep the mechanism.
# Previously (PING #11, build/hui13): THE CHILD SIDEKICK'S
# SHADOW is fixed — it rendered as a solid rectangle because two tiles
# (0x0F8B/0x0F8C) were never copied into group C while the remap had
# already rewritten their bank, so the sprites resolved to an EMPTY
# tile. Pixel A/B vs native confirms the tapered shadow. Also carries
# the 14z-69j pc-relative TABLE FIX (the row-8 machine's seven param
# tables now read byte-identical to vs2; under the hood, no visible
# change expected). Program bytes are IDENTICAL to build/hui12 — the
# shadow fix is gfx-only, which is why they share a fingerprint.
# STILL OPEN (do not re-report): the win QUOTE text (still the host's
# line — a 3-level data port, cosmetic), the 236P beam + ES big-beam /
# grab-lightning / 214 family, and FG pacing.
# Previous builds, kept pinned for A/B: build/hui13 (shadow fix),
# build/hui12 (table fix), build/hui11 (PING #10, 5c6dbe43).
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
# Usage: ROMDIR=... tools/run_hui_behavior.sh [outbase=build/hui14]
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
OUTBASE="${1:-build/hui14}"

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
