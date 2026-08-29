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
#                              GATE, pixel gates, menu gfx, M2b records.
#                              14z-97 (GitHub #96): that gate now targets the
#                              CURRENT frozen generation, resolved from the
#                              build's fingerprint, and its classes are
#                              EXACT — the old "watch for growth, advise on
#                              shrink" predicate went with the dev-build
#                              premise it rested on (see m2a_common.sh).
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

# ── SKIP ACCOUNTING (14z-94, GitHub #24) ────────────────────────────────────
# This script is `set -eu` and invoked each gate as a bare command, so exit 0
# was indistinguishable from PASS — and at least four gates `exit 0` when a
# prerequisite is absent, while two whole GROUPS are skipped by an `if [ -x
# <mame> ]` branch. On a machine without the WIDE MAME binary and with pruned
# build dirs, nine of ~24 gates never ran and the script still printed
# "BATTERY GREEN". That sentence is what a session records in STATE.md under
# rule 2, so it must not be printable when a third of the battery self-skipped.
#
# `bat` runs a gate, prints its output, and classifies it. A FAIL still stops
# the battery immediately, exactly as `set -e` did.
_bat_pass=0; _bat_skip=0; _bat_skipped=""
_BAT_TMP="$(mktemp -d)"; trap 'rm -rf "$_BAT_TMP"' EXIT INT TERM

bat() {   # bat <gate.sh> [args...]
    _bat_name="$(basename "$1" .sh)"
    if "$@" > "$_BAT_TMP/out" 2>&1; then
        cat "$_BAT_TMP/out"
        if grep -qE '^ *SKIP' "$_BAT_TMP/out"; then
            _bat_skip=$((_bat_skip + 1))
            _bat_skipped="$_bat_skipped $_bat_name"
        else
            _bat_pass=$((_bat_pass + 1))
        fi
    else
        _bat_st=$?
        cat "$_BAT_TMP/out"
        echo "BATTERY FAILED at $_bat_name (exit $_bat_st)"
        exit "$_bat_st"
    fi
}

# For the `if [ -x <mame> ]` / `else note:` branches, which skip whole GROUPS
# without ever invoking a gate.
bat_group_skip() {   # bat_group_skip <label> <n-gates>
    _bat_skip=$((_bat_skip + $2))
    _bat_skipped="$_bat_skipped $1(x$2)"
}


python3 tools/audit_roms.py "$ROMDIR" > /dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

# Rule locks on the REFERENCE ROM (CLAUDE.md §4: engine-invariant locks run
# on every build). Build-independent, so they run first and cheaply fail
# before anything expensive: the select-cursor mechanism and the shape of
# the character-id space, both of which the roster work builds on.
bat tests/test_id_space.sh
bat tests/test_select_wheel.sh
# Romset assembly is the one step between the ROM builder and the emulator
# that nothing used to check, and it is where the 14z-60z sprite garble
# lived: a merged member carrying the pristine bytes of a patched member,
# which both emulators prefer by hash. Cheap, build-independent, no emulator.
bat tests/test_romset_identity.sh
# The tenant id is a build input and the frozen reference must stay
# reproducible while the M3a move is in progress. Cheap, no emulator.
bat tests/test_tenant_id.sh
# 14z-78: no site_thunk body may bake a PLACED address as a literal — it
# tracks nothing, and the failure surfaces as a crash in vanilla code on a
# build whose placement changed, not at build time. This is the gate for
# the guard that makes it loud. Cheap, no emulator (needs an extract dir;
# SKIPs without one).
bat tests/test_thunk_addr_literal.sh
# 14z-79: the (b') index-window thunk. Its body carries a COPY of engine
# table 0x018468 and 23 handler addresses, so `old_hex` proves only that we
# patched the right place — one wrong trampoline is a SILENT wrong-routine
# dispatch, the very class the thunk removes. This re-derives every byte from
# the reference ROMs. Cheap, no emulator; SKIPs without a Huitzil build.
bat tests/test_index_window_thunk.sh
# 14z-79: the frozen SHARED-SURFACE WRITE inventory. test_hui_ladder.sh
# already requires every op to write free space or a variant row, but it
# runs stages 1-3 and the row that broke Bulleta was stage 4. This lists
# every write onto vanilla-readable bytes, per tenant, and fails on any
# change — turning the next one into a build-time review instead of a
# playtest ten sessions later. Static, no emulator, seconds.
bat tests/test_shared_writes.sh
# The M3a select-records mechanism (14z-62): a variant-id build must carry
# the tenant's OWN select records and the host's must be vanilla bytes.
# Builds its own 0x13 scratch build and measures the row fetch in MAME, so
# it needs the WIDE emulator; skipped with a note where that is absent.
if [ -x "${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}" ]; then
    bat tests/test_tenant_select_records.sh
    # The wheel bank-5 move (14z-63): the select wheel serves from group C
    # bank 5 — vanilla medallions byte-copied, real vs2 art for the
    # appended cells. Self-builds a 0x13 scratch build like the gate above.
    bat tests/test_wheel_bank5.sh
    # The variant-id HUD (14z-63): row 0x13 of the 32-row-aliased HUD
    # tables + free-pool mugshot art; host cells pristine.
    bat tests/test_tenant_hud.sh
    # The variant-id win-screen palette (14z-63): sparse block + thunk,
    # both paths measured on real 2P victories (replays 61/62).
    bat tests/test_tenant_winpal.sh
    # The accent/march census (14z-63): 4 frozen family-base sites, all
    # jsr-routed on variant builds; a fifth appearing fails loudly.
    bat tests/test_accent_census.sh
else
    echo "note: 5 tenant/select gates skipped (no WIDE MAME binary —"
    echo "      tools/setup_mame.sh; first gate: tests/test_tenant_select_records.sh)"
    bat_group_skip wide-mame-group 5
fi

bat tests/test_m2b_stage6.sh "$OUTBASE"
# The set under test must itself be free of that shadowing.
python3 tools/audit_romset_identity.py "$OUTBASE/rompath" || {
    echo "BATTERY STOP: a member of $OUTBASE/rompath shadows a patched member"; exit 1; }
bat tests/test_don_sword.sh "$OUTBASE/rompath"
bat tests/test_don_accent.sh "$OUTBASE/rompath"
bat tests/test_don_colors.sh "$OUTBASE/rompath"
bat tests/test_don_reactions.sh "$OUTBASE/rompath"
bat tests/test_don_column.sh "$OUTBASE/rompath"
bat tests/test_don_sound.sh "$OUTBASE/rompath"
# The 14z-2 mirror-victim fix (applied 14z-64 in the re-freeze bundle):
# base-slot mirror throws use the Donovan-victim block. SKIPs on
# variant-id builds (correct by construction there).
bat tests/test_don_throw_mirror.sh "$OUTBASE"
bat tests/test_m2a_stage4_oracle.sh "$OUTBASE/rompath"
bat tests/test_m2a_stage4_xemu.sh "$OUTBASE/rompath"
bat tests/test_m2a_flavor_selector.sh "$OUTBASE/rompath"

# WIDE-track builds get the rendering gate as well: every gate above is
# RAM-basis and structurally blind to what reaches the screen, which is how
# Donovan shipped rendering as garbage with a green battery (14z-60z).
# Needs the stock-track twin as its reference, so it runs only when both
# tracks are present.
if [ -f "$OUTBASE/rompath/vsavjw.zip" ] && [ -f "$REPO/build/m5_stock12/rompath/vsavj.zip" ]; then  # re-pointed 14z-117b (random-select freeze) <- 14z-117
    bat tests/test_wide_render_content.sh "$REPO/build/m5_stock12/rompath" "$OUTBASE/rompath"  # re-pointed 14z-117b (random-select freeze) <- 14z-117
else
    echo "note: WIDE rendering gate skipped (not a WIDE build, or no stock twin"
    echo "      at build/m5_stock12 — tests/test_wide_render_content.sh)"  # re-pointed 14z-117b (random-select freeze) <- 14z-117
    bat_group_skip wide-render 1
fi
if [ "$_bat_skip" = 0 ]; then
    echo "BATTERY GREEN — $_bat_pass gates, 0 skipped"
else
    echo "BATTERY INCOMPLETE — $_bat_pass passed, $_bat_skip SKIPPED:$_bat_skipped"
    echo "  A skipped gate asserts NOTHING. 'BATTERY GREEN' is the sentence a"
    echo "  session records under rule 2, so it is not printed here. Supply the"
    echo "  missing prerequisites (WIDE MAME binary, build dirs) and re-run."
    exit 1
fi
