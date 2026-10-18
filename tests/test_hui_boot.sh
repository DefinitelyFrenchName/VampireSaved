#!/bin/sh
# test_hui_boot.sh — the Huitzil stage-4 BOOT gate (14z-65).
#
# WHAT: the first rung with Phobos's code live: a forced-id match FORMS with his own data
#   (the row-0x10 hitbox base read from the build's own patch.json) and SURVIVES guarded,
#   while a legacy replay on the same build stays bit-identical to vanilla.
# HOW: builds stage 4 from the huitzil manifest, runs the forced-pick boot probe and the
#   crash guard on MAME, and a legacy replay against the frozen vanilla expectation.
# EXPECTS: his base loaded, guard clean (a watchdog reboot would read as zeros, which the
#   base check subsumes), legacy bit-identical. The probe's guarded run on emulated time at its frozen game clock,
#   the staging leg on replay.lua's checksum.
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): replay_guard.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua); the forced-pick probe's guarded run (tools/force_pick_probe.sh, its
#   environment from <probe>/guard_env) has its game clock RAM:$FF8080 at the last frame held to
#   tests/expected/instr_gameclock/test_hui_boot.tsv, frozen by `--freeze-clock` from a REFERENCE leg (the guard without
#   -debug, the same POKES) held to replay.lua run live; one STAGING reference leg is held to replay.lua on every run
#   (tests/lib/instr_align.sh). The stage-4 build is built fresh, so a manifest change that moves its game clock
#   FAILs the gate until re-frozen.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/donovan-m5/mask tests/expected/instr_gameclock/
#   tests/expected/vsavj/masked-v2/logs/02_demitri_vs_cpu.log tests/lib/controls.sh tests/lib/instr_align.sh
#   tests/lua/emu_clock.lua tests/lua/replay.lua
#   tests/lua/replay_guard.lua tests/replays/02_demitri_vs_cpu.rpl tools/build_donovan.sh
#   tools/compare_flicker.py tools/force_pick_probe.sh tools/run_mame.sh
#   tools/run_replay_guarded.sh tools/run_replay_mame.sh tools/setup_mame.sh
#
# SHEET: none — the subject is a development-stage build of the M2a/tenant ladder, not a release set; its comparison with vsavj is outside #291's scope (census class S)
#
# MUST-FIRE: known-bad: drift-clock — the probe's guarded run under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 3,600 emulated frames of 3,601 counted) must miss its frozen game clock (in-gate: one extra run; mode: the probe run runs the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
#
# The first rung with his CODE live: builds stage 4 from the huitzil
# manifest and proves a forced-id match FORMS and SURVIVES —
#   1. the forced-pick probe loads HIS hitbox base (the row-0x10 poke
#      value read back from the build's own patch.json, not hardcoded);
#   2. the crash guard is clean over the full run (no exception, no
#      tripwire — and per GOTCHAS 14z-65 a watchdog reboot would read as
#      ZEROS, so the loaded-base check subsumes the reboot check);
#   3. the legacy replay is still BIT-IDENTICAL to vanilla (the superset
#      side of the same build).
# History: this rung took the fall-through layout group (the 0x57456
# mid-handler region split), the [init_shim], and the five measured
# stubbed_sound rows (ids 0x72a-0x74a — vsavj same-id keys different
# music-class content) — see STATE 14z-65.
#
# Usage: ROMDIR=... tests/test_hui_boot.sh [--freeze-clock]
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   Huitzil stage-4 BOOT gate (14z-65): the forced-pick match forms with HIS
#   data (base read from the build's own patch), guard clean, legacy bit-
#   identical
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FREEZE_CLOCK=0; [ "${1:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
CLOCKS="tests/expected/instr_gameclock/test_hui_boot.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"

echo "== stage 4 build"
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 4 "$WORK/hui4" > "$WORK/build.log" 2>&1 \
    || { tail -15 "$WORK/build.log"; echo "FAIL: stage 4 build"; exit 1; }
echo "  ok: built ($(grep '^build fingerprint' "$WORK/build.log" | cut -d' ' -f3 | cut -c1-8))"

EXPECT_BASE="$(python3 - "$WORK/hui4/patch/patch.json" <<'PY'
import json, sys
for o in json.load(open(sys.argv[1]))["ops"]:
    if o.get("addr", "").lower() == "0xbd9ba":
        print(f"{int(o['val'], 0):08x}")
PY
)"
[ -n "$EXPECT_BASE" ] || { echo "FAIL: no hitbox_base[0x10] op in the patch"; exit 1; }

echo "== forced-pick boot (id 0x10)"
# the build packs as vsavjw when any allocation reaches wide_ext — run
# the set that was actually packed (14z-65: a vsavj-set probe against a
# vsavjw rompath silently falls back to the PRISTINE ROM: false greens)
if [ -f "$WORK/hui4/rompath/vsavjw.zip" ]; then
    export SET=vsavjw MAME_BIN="$HOME/.cache/vampire-saved/mame/cps2"
fi
# shellcheck disable=SC2086
env $_clk ALIGN_OUT="$WORK/probe.align" tools/force_pick_probe.sh "$WORK/hui4/rompath" 10 "$WORK/probe" > "$WORK/probe.txt"
ia_note_run "$WORK/manifest.tsv" hui4 pick "${SET:-vsavj}" "$WORK/hui4/rompath;$ROMDIR" "$WORK/probe/pick.rpl" \
    "$(cat "$WORK/probe/guard_env")" "$WORK/probe.align"
cat "$WORK/probe.txt" | sed 's/^/  /'
grep -q "hitbox base 0x$EXPECT_BASE — char LOADED" "$WORK/probe.txt" \
    || { echo "FAIL: HIS base 0x$EXPECT_BASE not loaded"; exit 1; }
grep -q "guard        : clean" "$WORK/probe.txt" \
    || { echo "FAIL: guard not clean"; exit 1; }

echo "== legacy replay under the v2 masked basis (hooked build)"
# stage 4 carries the obj_hook engine thunks, so the whole-RAM bit-identity
# of the ladder gate no longer applies (CLAUDE.md §4 hooked-build basis).
# Measured 14z-65: EXACT under the v2 mask — frozen as EXACT; any future
# flicker must be measured and ratified per doctrine, never tolerated here.
MASK_RANGES="$(cat "$REPO/tests/expected/donovan-m5/mask")" \
MAME_ROMPATH="$WORK/hui4/rompath;$ROMDIR" MAME_BIN="${MAME_BIN:-mame}" \
    tools/run_replay_mame.sh "${SET:-vsavj}" tests/replays/02_demitri_vs_cpu.rpl \
    "$WORK/r02.log" "$WORK/r02box" > /dev/null 2>&1
python3 "$REPO/tools/compare_flicker.py" "$WORK/r02.log" \
    "$REPO/tests/expected/vsavj/masked-v2/logs/02_demitri_vs_cpu.log" \
    | grep -q "^EXACT" \
    || { echo "FAIL: legacy replay not masked-EXACT"; exit 1; }
echo "  ok: masked-v2 EXACT vs the frozen vanilla log"

echo "== the instrument's alignment (#228 step 4, option A)"
if [ "$FREEZE_CLOCK" = 1 ]; then
    ia_freeze "$REPO/tests/lua/replay_guard.lua" "$WORK/manifest.tsv" "$WORK/fz" "${JOBS:-4}" "$WORK/clocks.tsv" \
        > "$WORK/fz.txt" || { sed 's/^/  /' "$WORK/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at the probe run's last frame, frozen from a REFERENCE leg (#228 step 4,"
      echo "# option A) by \`tests/test_hui_boot.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): hui4 = the stage-4 build, built fresh;"
      echo "# the reference leg held to replay.lua run live, the probe run to its game clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$WORK/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$WORK/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
afail=0
if ia_check_manifest "$CLOCKS" "$WORK/manifest.tsv" > "$WORK/align_bad.txt"; then echo "  ok: the probe run on emulated time, at its frozen game clock"
else echo "  FAIL: $(wc -l < "$WORK/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$WORK/align_bad.txt" | sed 's/^/        /'; afail=1; fi
ia_stage test_hui_boot "$CLOCKS" "$REPO/tests/lua/replay_guard.lua" "$WORK/manifest.tsv" 1 "$WORK/st" "$MODE" || afail=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$afail" = 1 ] && { echo "FAIL: test_hui_boot (control mode: $MODE)"; exit 1; }
    echo "FAIL: test_hui_boot — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || afail=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || afail=1; fi
[ "$afail" = 0 ] || { echo "FAIL: test_hui_boot — the instrument's alignment"; exit 1; }
echo "PASS: Huitzil stage-4 boot (his data loads, guard clean, legacy intact)"
