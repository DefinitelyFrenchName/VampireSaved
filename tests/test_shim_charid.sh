#!/bin/sh
# test_shim_charid.sh — the init shim can identify WHICH tenant it is running
# for, because (0x382,A6) already holds the character id when it runs.
#
# WHAT: the init shim can identify WHICH tenant it runs for: at char-init (0x382,A6) already
#   holds the character id, on BOTH player structs — the premise the merged shim's per-id
#   flavour chain rests on.
# HOW: GUARD_PROBE_MEM reads memory at the shim's hit on two 2P replays on MAME with the
#   forced-pick pokes (without them the shim never runs and the gate measures nothing —
#   section 0 proves the probe armed); the verdict control reads offset +0x000, which must
#   NOT hold the id.
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): replay_guard.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua); every probe run's game clock RAM:$FF8080 at its last frame is held to
#   tests/expected/instr_gameclock/test_shim_charid.tsv, frozen by `--freeze-clock` from REFERENCE legs (the guard
#   without -debug, the same POKES) each held to replay.lua run live; one STAGING reference leg is held to replay.lua
#   on every run (tests/lib/instr_align.sh).
# EXPECTS: 0x13 read at +0x382 on both structs, the control offset not; a quiet leg without
#   section 0 is a dead rig. Every probe run on emulated time at its frozen game clock, the staging leg on
#   replay.lua's checksum.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/instr_gameclock/ tests/lib/controls.sh
#   tests/lib/instr_align.sh tests/lua/emu_clock.lua tests/lua/replay.lua tests/lua/replay_guard.lua tests/replays/
#   tools/run_mame.sh tools/run_replay_guarded.sh tools/setup_mame.sh
#
# SHEET: none — runs our build only, judged on its own; no reference leg and no frozen reference values
#
# MUST-FIRE: known-bad: drift-clock — a probe run under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 5,315 emulated frames of 5,320 counted) must miss its frozen game clock (in-gate: one extra run; mode: every probe run runs the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
#
# WHY (M3b slice G, 14z-77). A merged build has ONE init shim serving N
# tenants, and each needs a different VS2/VH2 flavor byte. `flavor_tail()`
# therefore emits `cmpi.b #id,(0x382,A6)` per tenant — which is only correct
# if the player struct's id field is POPULATED at the moment the shim runs,
# at char-init, before the character handler.
#
# That was an ASSUMPTION when the code was written: strongly implied (the
# dispatch the shim is hosted on is itself id-indexed, and +0x382 is the id
# field of both player structs, docs/game/atlas/ram.md) but not measured at
# this point in the frame. A register dump alone cannot answer it and
# frame-level ordering is too coarse — both events are inside one frame — so
# `GUARD_PROBE_MEM` was added to replay_guard.lua to read memory AT THE HIT.
#
# Measured 14z-77 on donovan-m3a: A6=$FF8400 -> $FF8782 = 0x13 and
# A6=$FF8800 -> $FF8B82 = 0x13, on two independent 2P replays. BOTH player
# structs, because the chain must work for either.
#
# The rig needs the forced-pick pokes. Without them replay 11 never runs
# Donovan's char-init at all and this gate measures nothing while looking
# like it passed — which is exactly what happened first (CLAUDE.md: a
# negative result from a rig is a fact about the RIG until proven otherwise).
# Section 0 is that proof, on this instrument, every run.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/test_shim_charid.sh [build] [id] [--freeze-clock]
#   build defaults to build/don_m27, the current donovan freeze build (the registry row passes %DON%; until #328,
#   14z-210, a pre-M23 donovan-m3a build no clean clone has — its frozen clocks read the same here), id to 0x13.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-77 (M3b slice G): the init shim can identify WHICH tenant it runs for
#   — (0x382,A6) already holds the character id at char-init. That was an
#   ASSUMPTION the merged shim's per-id flavor chain rests on. (F2 FIXED
#   14z-82: the merged shim is assembled at engine_here and planted on EVERY
#   declaring tenant's row, each chain block exiting into its OWNER's handler;
#   audit_merged_legacy section 0 asserts HENT==SHIM. The id-read finding here
#   is what the chain rests on.) Measured on BOTH player structs ($FF8782 and
#   $FF8B82 = 0x13), 2 replays. NEEDS THE FORCED-PICK POKES: replay 11 never
#   forms a Donovan match and returns a meaningless zero, so section 0 proves
#   the probe is armed before any verdict. Verdict control: offset +0x000 must
#   NOT read the id. ~44s. Defaults build/m5_wide, id 0x13
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"

# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
FREEZE_CLOCK=0; _pos=""
for a in "$@"; do if [ "$a" = "--freeze-clock" ]; then FREEZE_CLOCK=1; else _pos="$_pos $a"; fi; done
# shellcheck disable=SC2086
set -- $_pos
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
CLOCKS="tests/expected/instr_gameclock/test_shim_charid.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"
BUILD="${1:-build/don_m27}"  # re-pointed 14z-210 (#328) <- build/m5_wide, a pre-M23 build no clean clone has
TID="${2:-13}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN

if [ ! -d "$BUILD/rompath" ] || [ ! -x "$MAME_BIN" ]; then
    echo "SKIP: need a build at $BUILD and the WIDE MAME binary at $MAME_BIN"
    echo "      (tools/setup_mame.sh; build dirs are untracked)"
    exit 0
fi

# The shim address is READ FROM THE BUILD, never hardcoded — it is allocated,
# so it moves whenever the space model does.
SHIM="$(sed -n 's/^code *0x0*\([0-9a-f]*\) init shim .*/\1/p' \
        "$BUILD/patch/patch_notes_fragment.md" | head -1)"
if [ -z "$SHIM" ]; then
    echo "SKIP: no 'init shim' line in $BUILD/patch/patch_notes_fragment.md"
    echo "      (a build below stage 5 has no shim to probe)"
    exit 0
fi
echo "  build $BUILD, tenant id 0x$TID, shim at PRG:0x$SHIM"

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
export MAME_ROMPATH="$PWD/$BUILD/rompath;$ROMDIR"
# Forced pick for BOTH sides: the cursor path lands on different characters
# on the two wheels, so hand-picking cannot be relied on (HANDOFF).
export POKES="1400:ff8782:$TID;1450:ff8782:$TID;1500:ff8782:$TID;\
1400:ff8b82:$TID;1450:ff8b82:$TID;1500:ff8b82:$TID"
fail=0

probe() {  # probe <addr> <memspec> <replay> -> log path on stdout
    # shellcheck disable=SC2086
    env $_clk GUARD_PROBE="$1" GUARD_PROBE_MEM="$2" ALIGN_OUT="$WORK/$1_$2_$3.align" \
    tools/run_replay_guarded.sh vsavjw "tests/replays/$3.rpl" \
        "$WORK/$1_$2_$3.log" "$WORK/box_$1_$2_$3" >/dev/null 2>&1 || true
    ia_note_run "$WORK/manifest.tsv" build "$3" vsavjw "$MAME_ROMPATH" "$REPO/tests/replays/$3.rpl" \
        "MAME_BIN=$MAME_BIN POKES=$POKES GUARD_PROBE=$1 GUARD_PROBE_MEM=$2" "$WORK/$1_$2_$3.align"
    echo "$WORK/$1_$2_$3.log"
}

echo "== 0: the instrument arms (a real zero and a blind zero look alike) =="
L="$(probe 016c64 A6+382 03_two_player_vs)"
N="$(grep -c '^PROBE ' "$L" || true)"
if [ "${N:-0}" -gt 0 ]; then
    echo "  ok: the pool seeder 0x016c64 reports $N hits with MEM attached"
else
    echo "  FAIL: no hits at a known-executed address — the probe is blind,"
    echo "        so every zero below would be meaningless"
    exit 1
fi

echo "== 1: at the shim, (0x382,A6) already holds the tenant id =="
for R in 03_two_player_vs 16_xemu_2p; do
    L="$(probe "$SHIM" A6+382 "$R")"
    HITS="$(grep -c '^PROBE ' "$L" || true)"
    if [ "${HITS:-0}" -lt 2 ]; then
        echo "  FAIL: $R — $HITS shim hits, expected both player structs."
        echo "        The rig did not form the match; fix the rig, do not"
        echo "        read this as a fact about the engine."
        fail=1; continue
    fi
    BAD="$(grep '^PROBE ' "$L" | grep -vc "=$TID\$" || true)"
    P1="$(grep -c 'A6=00ff8400 .*=' "$L" || true)"
    P2="$(grep -c 'A6=00ff8800 .*=' "$L" || true)"
    if [ "${BAD:-0}" = 0 ] && [ "${P1:-0}" -ge 1 ] && [ "${P2:-0}" -ge 1 ]; then
        echo "  ok: $R — $HITS hits, every one reads 0x$TID; both structs"
        echo "      seen (P1 A6=\$FF8400, P2 A6=\$FF8800)"
    else
        echo "  FAIL: $R — $BAD hit(s) did not read 0x$TID (P1 $P1, P2 $P2)"
        grep '^PROBE ' "$L" | head -4
        fail=1
    fi
done

echo "== 2: verdict control — the id is at +0x382, not everywhere =="
# If some other offset in the struct also read the tenant id, section 1 would
# pass on a coincidence rather than on the field it names.
L="$(probe "$SHIM" A6+0 03_two_player_vs)"
if grep '^PROBE ' "$L" | grep -q "=$TID\$"; then
    echo "  FAIL: (0x000,A6) also reads 0x$TID — section 1 is not evidence"
    echo "        that +0x382 specifically carries the character id"
    fail=1
else
    echo "  ok: (0x000,A6) does not read 0x$TID, so +0x382 is doing the work"
fi

echo "== 3: the instrument's alignment (#228 step 4, option A) =="
if [ "$FREEZE_CLOCK" = 1 ]; then
    [ "$fail" = 0 ] || { echo "REFUSED: sections 0-2 failed — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/replay_guard.lua" "$WORK/manifest.tsv" "$WORK/fz" "${JOBS:-4}" "$WORK/clocks.tsv" \
        > "$WORK/fz.txt" || { sed 's/^/  /' "$WORK/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/test_shim_charid.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): build = $BUILD, tenant 0x$TID;"
      echo "# every reference leg held to replay.lua run live, every probe run to its reference leg's game clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$WORK/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$WORK/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
if ia_check_manifest "$CLOCKS" "$WORK/manifest.tsv" > "$WORK/align_bad.txt"; then
    echo "  ok: every probe run on emulated time, at its frozen game clock"
else echo "  FAIL: $(wc -l < "$WORK/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$WORK/align_bad.txt" | sed 's/^/        /'; fail=1; fi
ia_stage test_shim_charid "$CLOCKS" "$REPO/tests/lua/replay_guard.lua" "$WORK/manifest.tsv" 1 "$WORK/st" "$MODE" || fail=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "FAIL: init-shim char-id gate (control mode: $MODE)"; exit 1; }
    echo "FAIL: init-shim char-id gate — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi

[ "$fail" = 0 ] || { echo "FAIL: init-shim char-id gate"; exit 1; }
echo "PASS: the init shim can identify its tenant — (0x382,A6) holds the"
echo "      character id at char-init, both player structs, 2 replays"
