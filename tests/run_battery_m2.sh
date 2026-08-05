#!/bin/sh
# run_battery_m2.sh — the M2 deliverable battery: the EXACT gate chain a
# stage-6 dev build must pass before any commit that touches the build
# (CLAUDE.md rule 2 / persistent-suite doctrine). One command, no
# chat-memory chain. Sections:
#   0. test_id_space.sh / test_select_wheel.sh — reference-ROM rule locks
#      (id-space shape, select-cursor mechanism); build-independent
#   1. test_m2b_stage6.sh    — build (with dev GEN_FLAGS) + static gfx
#                              verification, guarded soaks, MASKED LEGACY
#                              GATE (frozen flicker inventory — watch for
#                              growth: standing maintainer watch), pixel
#                              gates, menu gfx, M2b records
#   2. test_don_sword.sh     — sword-swing behavior (frozen anim node)
#   3. test_don_accent.sh    — palette locks: weapon accent steadiness,
#                              Victor-accent legacy byte guard + cycle,
#                              fixture-override rows, shock-window
#                              vanilla lock (palette ROM->RAM is
#                              RAM-gate-blind; these are the only locks)
#   3b. test_don_colors.sh   — kick-color + mirror rows + select sword
#   3c. test_don_reactions.sh — 421P gameplay lock (multi-hit, no KD)
#   3d. test_don_column.sh    — column-KO crash gate (record-type aliases)
#   3e. test_don_sound.sh     — sound-ring gate: no vsavj MUSIC-range id
#                              may be enqueued (the 14z-52 tripwire), and
#                              per-replay id inventories are frozen
#   4. test_m2a_stage4_oracle.sh — vsav2-as-oracle field gates
#   5. test_m2a_stage4_xemu.sh   — MAME/FBNeo dual-emulator agreement
#   6. test_m2a_flavor_selector.sh — Start-hold latch
#
# Usage: ROMDIR=... tests/run_battery_m2.sh [outbase]   (default build/donovan6)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUTBASE="${1:-$REPO/build/donovan6}"
cd "$REPO"

python3 tools/audit_roms.py "$ROMDIR" > /dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

# Rule locks on the REFERENCE ROM (CLAUDE.md §4: engine-invariant locks run
# on every build). Build-independent, so they run first and cheaply fail
# before anything expensive: the select-cursor mechanism and the shape of
# the character-id space, both of which the roster work builds on.
tests/test_id_space.sh
tests/test_select_wheel.sh
# Romset assembly is the one step between the ROM builder and the emulator
# that nothing used to check, and it is where the 14z-60z sprite garble
# lived: a merged member carrying the pristine bytes of a patched member,
# which both emulators prefer by hash. Cheap, build-independent, no emulator.
tests/test_romset_identity.sh

tests/test_m2b_stage6.sh "$OUTBASE"
# The set under test must itself be free of that shadowing.
python3 tools/audit_romset_identity.py "$OUTBASE/rompath" || {
    echo "BATTERY STOP: a member of $OUTBASE/rompath shadows a patched member"; exit 1; }
tests/test_don_sword.sh "$OUTBASE/rompath"
tests/test_don_accent.sh "$OUTBASE/rompath"
tests/test_don_colors.sh "$OUTBASE/rompath"
tests/test_don_reactions.sh "$OUTBASE/rompath"
tests/test_don_column.sh "$OUTBASE/rompath"
tests/test_don_sound.sh "$OUTBASE/rompath"
tests/test_m2a_stage4_oracle.sh "$OUTBASE/rompath"
tests/test_m2a_stage4_xemu.sh "$OUTBASE/rompath"
tests/test_m2a_flavor_selector.sh "$OUTBASE/rompath"

# WIDE-track builds get the rendering gate as well: every gate above is
# RAM-basis and structurally blind to what reaches the screen, which is how
# Donovan shipped rendering as garbage with a green battery (14z-60z).
# Needs the stock-track twin as its reference, so it runs only when both
# tracks are present.
if [ -f "$OUTBASE/rompath/vsavjw.zip" ] && [ -f "$REPO/build/m5_stock/rompath/vsavj.zip" ]; then
    tests/test_wide_render_content.sh "$REPO/build/m5_stock/rompath" "$OUTBASE/rompath"
else
    echo "note: WIDE rendering gate skipped (not a WIDE build, or no stock twin"
    echo "      at build/m5_stock — tests/test_wide_render_content.sh)"
fi
echo "BATTERY GREEN"
