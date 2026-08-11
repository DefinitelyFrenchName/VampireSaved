#!/bin/sh
# run_battery_m2.sh — the M2 deliverable battery: the EXACT gate chain a
# stage-6 dev build must pass before any commit that touches the build
# (CLAUDE.md rule 2 / persistent-suite doctrine). One command, no
# chat-memory chain. Sections:
#   0. test_id_space.sh / test_select_wheel.sh — reference-ROM rule locks
#      (id-space shape, select-cursor mechanism); build-independent;
#      + test_romset_identity.sh / test_tenant_id.sh (cheap rule locks) and
#      test_tenant_select_records.sh (M3a variant-id select mechanism —
#      self-builds at 0x13, needs the WIDE MAME binary)
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
# The tenant id is a build input and the frozen reference must stay
# reproducible while the M3a move is in progress. Cheap, no emulator.
tests/test_tenant_id.sh
# 14z-78: no site_thunk body may bake a PLACED address as a literal — it
# tracks nothing, and the failure surfaces as a crash in vanilla code on a
# build whose placement changed, not at build time. This is the gate for
# the guard that makes it loud. Cheap, no emulator (needs an extract dir;
# SKIPs without one).
tests/test_thunk_addr_literal.sh
# 14z-79: the (b') index-window thunk. Its body carries a COPY of engine
# table 0x018468 and 23 handler addresses, so `old_hex` proves only that we
# patched the right place — one wrong trampoline is a SILENT wrong-routine
# dispatch, the very class the thunk removes. This re-derives every byte from
# the reference ROMs. Cheap, no emulator; SKIPs without a Huitzil build.
tests/test_index_window_thunk.sh
# The M3a select-records mechanism (14z-62): a variant-id build must carry
# the tenant's OWN select records and the host's must be vanilla bytes.
# Builds its own 0x13 scratch build and measures the row fetch in MAME, so
# it needs the WIDE emulator; skipped with a note where that is absent.
if [ -x "${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}" ]; then
    tests/test_tenant_select_records.sh
    # The wheel bank-5 move (14z-63): the select wheel serves from group C
    # bank 5 — vanilla medallions byte-copied, real vs2 art for the
    # appended cells. Self-builds a 0x13 scratch build like the gate above.
    tests/test_wheel_bank5.sh
    # The variant-id HUD (14z-63): row 0x13 of the 32-row-aliased HUD
    # tables + free-pool mugshot art; host cells pristine.
    tests/test_tenant_hud.sh
    # The variant-id win-screen palette (14z-63): sparse block + thunk,
    # both paths measured on real 2P victories (replays 61/62).
    tests/test_tenant_winpal.sh
    # The accent/march census (14z-63): 4 frozen family-base sites, all
    # jsr-routed on variant builds; a fifth appearing fails loudly.
    tests/test_accent_census.sh
else
    echo "note: tenant select-records gate skipped (no WIDE MAME binary —"
    echo "      tools/setup_mame.sh; gate: tests/test_tenant_select_records.sh)"
fi

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
# The 14z-2 mirror-victim fix (applied 14z-64 in the re-freeze bundle):
# base-slot mirror throws use the Donovan-victim block. SKIPs on
# variant-id builds (correct by construction there).
tests/test_don_throw_mirror.sh "$OUTBASE"
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
