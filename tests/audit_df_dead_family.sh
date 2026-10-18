#!/bin/sh
# audit_df_dead_family.sh — vs2's P+K (DARK FORCE POWER) NEVER REACHES THE
# VS-STYLE DARK FORCE FAMILY: its shared field-setter tail at vs2 PRG:0x02622A
# takes ZERO hits on a P+K activation while the activation body takes exactly one
# (measured 14z-126). SCOPED 14z-168: the family is NOT dead in vs2 — the three
# newcomers' vs2 EX moves (their personal Dark Force) run through 0x02622A and
# arm +0x147 from their own handlers (tests/audit_df_modes.sh).
#
# WHAT: vs2's P+K (Dark Force POWER) never reaches the VS-style Dark Force family's shared
#   field-setter tail at vs2 PRG:0x02622A — a claim by ABSENCE carried with its positive
#   control: the activation body must fire exactly once at the press. (The tenants' EX moves
#   DO reach it; that is audit_df_modes.)
# HOW: four -debug runs on native vsav2 of the df/97 rig (HP+HK at f3260, stocks poked) with
#   GUARD_PROBE breakpoints on the candidate and the control, for a newcomer (Donovan) and a
#   vanilla character (Demitri); the must-fire asserts the candidate fired, which it never
#   does.
# EXPECTS: 0 probe lines on the candidate and exactly 1 on the control, logged at frame 3259, on both
#   legs. Every run on emulated time at its frozen game clock, the staging leg on replay.lua's checksum.
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): replay_guard.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua); every run's game clock RAM:$FF8080 at its last frame is held to
#   tests/expected/instr_gameclock/audit_df_dead_family.tsv, frozen by `--freeze-clock` from REFERENCE legs (the
#   guard without -debug, the same POKES) each held to replay.lua run live; one STAGING reference leg is held to
#   replay.lua on every run (tests/lib/instr_align.sh).
# FOLLOWS: emu/mame-patches/ tests/expected/instr_gameclock/ tests/lib/controls.sh tests/lib/instr_align.sh
#   tests/lua/emu_clock.lua tests/lua/replay.lua tests/lua/replay_guard.lua
#   tests/replays/df/97_df_mech.rpl tools/run_mame.sh tools/run_replay_guarded.sh
#   tools/setup_mame.sh
#
# SHEET: none — measures pristine vsavj and/or native vsav2 only; no leg of our build
#
# MUST-FIRE: known-bad: drift-clock — a probe run under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 7,008 emulated frames of 7,010 counted) must miss its frozen game clock (in-gate: one extra run; mode: every probe run runs the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
# MUST-FIRE: known-bad: candidate-reached — the dead field-setter 0x02622A is never reached, so demanding it WAS reached must fail (mode: the candidate is asserted to have fired, which the real trace never shows, so the gate FAILs)
#
# WHY. docs/game/preserved_data.md entry 1: vs2/vh2 carry the VS-style
# seq-0x16 Dark Force handlers for all 18 characters and P+K never reaches them
# (corrected 14z-168: the newcomers' EX moves do; this gate's legs are P+K). The
# listing showed one more member — a vsav-style field setter at vs2 0x02622A
# (`+0x111/+0x110/+0x143/+0x176`, fixed `+0x189` = 5 / `+0x188` = 0x23),
# reached only by `jmp $2622a.l` from ten per-character sites inside the
# handler ranges. "Never reached" is a claim measured by ABSENCE ([VSP-22]),
# so it carries a positive control on the same instrument, leg and frame: the
# vs2 activation body 0x02619E, which MUST fire once at the activation press.
#
# WHAT IT ASSERTS (native vsav2 from $ROMDIR, replay df/97 — activation HP+HK
# at f3260 with poked stocks —, `GUARD_PROBE` logging breakpoints, two
# characters: a newcomer (Donovan 0x13) and a vanilla one (Demitri 0x01)):
#   candidate 0x02622A: 0 PROBE lines on both legs;
#   control   0x02619E: exactly 1 PROBE line on both legs, logged at frame 3259 — it runs DURING frame 3260, the frame
#             whose input carries the press, and the guard labels a stop with the last COMPLETED frame. Until 14z-197
#             (#228 step 4) this read 3260: the guard's frame_done count included the debugger's boot halt.
# Four -debug runs of ~7,000 frames; ~3 min in parallel.
#
# Usage: ROMDIR=... tests/audit_df_dead_family.sh [--freeze-clock]
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
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
FREEZE_CLOCK=0; [ "${1:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
CLOCKS="tests/expected/instr_gameclock/audit_df_dead_family.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"
RPL="$REPO/tests/replays/df/97_df_mech.rpl"
for leg in don:13 dem:01; do n="${leg%%:*}"; id="${leg#*:}"
    PK="1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3120:ff8509:03"
    for pr in 2622a 2619e; do
        # shellcheck disable=SC2086
        ( env $_clk POKES="$PK" GUARD_PROBE=$pr TAIL_FRAMES=10 ALIGN_OUT="$W/${n}_$pr.align" tools/run_replay_guarded.sh vsav2 "$RPL" "$W/${n}_$pr.log" "$W/sb_${n}_$pr" > "$W/${n}_$pr.out" 2>&1 ) &
    done
done
wait
for leg in don:13 dem:01; do n="${leg%%:*}"; id="${leg#*:}"
    PK="1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3120:ff8509:03"
    for pr in 2622a 2619e; do
        ia_note_run "$W/manifest.tsv" "$n" 97_df_mech vsav2 - "$RPL" "POKES=$PK GUARD_PROBE=$pr TAIL_FRAMES=10" "$W/${n}_$pr.align"
    done
done
bad=0
for n in don dem; do
    for pr in 2622a 2619e; do
        f="$W/${n}_$pr.log"
        grep -q '^END ' "$f" || { echo "  FAIL: $n/$pr: no END line — dead leg"; bad=1; continue; }
        hits="$(grep -c '^PROBE' "$f" || true)"
        if [ "$pr" = 2622a ]; then
            if [ "$MODE" = candidate-reached ]; then
                if [ "$hits" = 0 ]; then echo "  candidate-reached mode ($n): candidate 0x2622A NOT reached (0 hits), as it never is — the mode demands the forbidden reach, so the gate FAILs"; bad=1
                else echo "CONTROL DEAD: candidate-reached — candidate 0x2622A was reached $hits times ($n)"; fi
            elif [ "$hits" = 0 ]; then
                if [ "$n" = don ]; then vs_ctl_fired candidate-reached "candidate 0x2622A is never reached (0 hits); the mode demands the forbidden reach so the gate FAILs"; fi
                echo "  ok    $n: candidate 0x2622A never reached (0 hits)"
            else
                echo "CONTROL DEAD: candidate-reached — candidate 0x2622A was reached $hits times ($n)"; echo "  FAIL: $n: candidate 0x2622A reached $hits times"; bad=1
            fi
        else
            fr="$(grep -m1 '^PROBE' "$f" | awk '{print $2}')"
            [ "$hits" = 1 ] && [ "$fr" = 3259 ] && echo "  ok    $n: control 0x2619E fired once, logged at f3259 (during the press frame 3260)" || { echo "  FAIL: $n: control 0x2619E fired $hits times (first at ${fr:-never}; want once, logged 3259)"; bad=1; }
        fi
    done
done
echo "== the instrument's alignment (#228 step 4, option A)"
if [ "$FREEZE_CLOCK" = 1 ]; then
    [ "$bad" = 0 ] || { echo "REFUSED: the audit failed — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" "$W/fz" "${JOBS:-4}" "$W/clocks.tsv" \
        > "$W/fz.txt" || { sed 's/^/  /' "$W/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/audit_df_dead_family.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): native vsav2, don and dem"
      echo "# legs; every reference leg held to replay.lua run live, every probe run to its reference leg's game clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$W/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$W/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
if ia_check_manifest "$CLOCKS" "$W/manifest.tsv" > "$W/align_bad.txt"; then
    echo "  ok    every probe run on emulated time, at its frozen game clock"
else echo "  FAIL: $(wc -l < "$W/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$W/align_bad.txt" | sed 's/^/        /'; bad=1; fi
ia_stage audit_df_dead_family "$CLOCKS" "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" 1 "$W/st" "$MODE" || bad=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$bad" = 1 ] && { echo "FAIL audit_df_dead_family (control mode: $MODE)"; exit 1; }
    echo "FAIL audit_df_dead_family — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || bad=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || bad=1; fi

[ "$bad" = 0 ] && echo "PASS audit_df_dead_family" || { echo "FAIL audit_df_dead_family"; exit 1; }
