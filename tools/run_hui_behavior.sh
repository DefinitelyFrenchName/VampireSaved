#!/bin/sh
# run_hui_behavior.sh — the Huitzil playtest build, interactive.
# 14z-71 (PING #14, build/hui20 = 40cc10b1): THE BEAM DRAWS. Two
# stacked defects, both fixed at zero legacy cost: vsav shipped
# effect-class row 16 as a STUB where vs2/vh2 carry the beam's handler,
# and underneath that its sprite-list drawer has no list-type 12 (the
# composite the beam's list uses) — taken over from vsav's UNUSED
# list-type 6. Look for: the muzzle orb at the cannon, then the beam
# extending to the opponent on 236+P / 236+K / 236+2P. The freeze
# already worked; it is the visuals that were missing.
#
# Previously (PING #13, build/hui17 = 699de9b7): THE 214+P GROUND
# EXPLOSION. The grenade's ground detonation drew a solid FUCHSIA
# rectangle (the ping-#7 "fuchsia class"); 569 group-C tiles were
# remapped but never copied. Fires on tests/replays/hui/83d — 214+LP
# with both fighters walked back to their corners, the ONLY rig that
# detonates the bomb on the ground instead of on the opponent.
#
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
OUTBASE="${1:-build/hui25}"

# NEVER silently rebuild into a directory that already exists (14z-71).
# The old behaviour built TODAY's manifest into whatever path you named, so
# `run_hui_behavior.sh build/hui11` on a pruned rompath handed you a CURRENT
# build wearing a historical name — destroying the A/B evidence you were
# trying to look at, silently. Auto-build only into a path that does not
# exist yet; otherwise say so and stop.
if [ ! -f "$OUTBASE/rompath/vsavjw.zip" ]; then
    if [ -d "$OUTBASE" ] && [ "${REBUILD:-0}" != "1" ]; then
        echo "REFUSING to rebuild: $OUTBASE exists but has no rompath."
        echo "  If this is a historical build, its rompath was pruned — do NOT"
        echo "  rebuild it here: today's manifest would produce DIFFERENT bytes"
        echo "  under an old name. Rebuild it in a fresh directory instead, or"
        echo "  set REBUILD=1 if you really mean to overwrite this one."
        exit 1
    fi
    echo "building the stage-6 gfx build at $OUTBASE ..."
    # 14z-90: no pipe. This script launches an INTERACTIVE PLAYTEST on the
    # result, and `| tail -2` discarded build_donovan.sh's own BUILD REJECTED
    # exit status — handing the maintainer a build the builder refused. Its
    # own :414 comment: "A build that fails this must never reach a playtest".
    _BLOG="$(mktemp -t huibuild)"
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 6 "$OUTBASE" \
        > "$_BLOG" 2>&1 || { tail -20 "$_BLOG"; rm -f "$_BLOG"; exit 1; }
    tail -2 "$_BLOG"; rm -f "$_BLOG"
    [ -f "$OUTBASE/rompath/vsavjw.zip" ] || {
        echo "FAIL: build left no $OUTBASE/rompath/vsavjw.zip — refusing to launch"
        exit 1
    }
fi

# Say WHAT is being launched. "Am I playing what I think I am?" has cost
# this project more than once; the fingerprint is one line and settles it.
_FP="$(python3 tools/build_fingerprint.py "$OUTBASE/rompath;$ROMDIR" \
        --set vsavjw --sha-only 2>/dev/null | tail -1)"
echo "build: $OUTBASE   ${_FP:-(fingerprint unavailable)}"

MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "WIDE MAME missing — tools/setup_mame.sh"; exit 1; }

echo "Launching. Phobos = his own wheel cell (D,D,D from default). Esc quits."
# Keep MAME's writable state OUT of the repo and away from $ROMDIR — the
# reference set was polluted once by an emulator run directly against it
# (it grew cfg/nvram dirs and lost a member). Everything lands in a
# per-build sandbox instead.
_SBX="${MAME_SANDBOX:-$OUTBASE/play}"
mkdir -p "$_SBX/cfg" "$_SBX/nvram" "$_SBX/snap"
exec "$MAME_BIN" vsavjw \
    -rompath "$(cd "$OUTBASE/rompath" && pwd);$ROMDIR" \
    -cfg_directory "$_SBX/cfg" -nvram_directory "$_SBX/nvram" \
    -snapshot_directory "$_SBX/snap" \
    -skip_gameinfo
