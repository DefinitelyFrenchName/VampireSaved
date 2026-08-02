#!/bin/sh
# run_battery_m2.sh — the M2 deliverable battery: the EXACT gate chain a
# stage-6 dev build must pass before any commit that touches the build
# (CLAUDE.md rule 2 / persistent-suite doctrine). One command, no
# chat-memory chain. Sections:
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

tests/test_m2b_stage6.sh "$OUTBASE"
tests/test_don_sword.sh "$OUTBASE/rompath"
tests/test_don_accent.sh "$OUTBASE/rompath"
tests/test_don_colors.sh "$OUTBASE/rompath"
tests/test_don_reactions.sh "$OUTBASE/rompath"
tests/test_don_column.sh "$OUTBASE/rompath"
tests/test_don_sound.sh "$OUTBASE/rompath"
tests/test_m2a_stage4_oracle.sh "$OUTBASE/rompath"
tests/test_m2a_stage4_xemu.sh "$OUTBASE/rompath"
tests/test_m2a_flavor_selector.sh "$OUTBASE/rompath"
echo "BATTERY GREEN"
