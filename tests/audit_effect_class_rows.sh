#!/bin/sh
# audit_effect_class_rows.sh — the THREE deadness measurements the beam
# port rests on (14z-71). All are ROM-read audits, and the first two are
# the ONLY guards their claims have.
#
# WHAT: the three deadness measurements the beam port rests on: vanilla never dispatches
#   effect-class row 16 (0 reads against a live control on row 37), the composite handler's
#   A5 scratch $FF3578-$FF3581 IS used by vsavj (so vs2's displacements cannot be kept), and
#   drawer list-type 10 is NOT a spare slot (thousands of legacy reads) — plus since 14z-91
#   the type-6 fallback's EXECUTION against a frozen per-replay inventory.
# HOW: MAME -debug watches on the OPCODES space (the tables are read pc-relatively; a plain
#   watchpoint is silently blind), every section with a positive control on the same
#   instrument and leg.
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): trace_writes.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua), so every watch run of sections 1-3 plays its whole replay since
#   14z-197 (until then the type-10 run of 02_demitri_vs_cpu covered 2,817 emulated frames of 5,520 counted); each run's game clock
#   RAM:$FF8080 at its last frame is held to tests/expected/instr_gameclock/audit_effect_class_rows.tsv, frozen by
#   `--freeze-clock` from REFERENCE legs (no watch, no debugger) each held to replay.lua run live; one STAGING
#   reference leg is held to replay.lua on every run (tests/lib/instr_align.sh). Section 4's runs (BUILD set) are held
#   the same way, as leg `merged` (#261, maintainer-ruled 2026-10-17 "Freeze, record as unattributed"); section 4
#   therefore runs BEFORE section 5, and under --freeze-clock it registers its runs without judging them.
# EXPECTS: 0 / used / used as measured, the fallback inventory exact; a blind instrument
#   cannot pass as a clean result. Every section 1-3 run on emulated time at its frozen game clock, the staging leg
#   on replay.lua's checksum.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/instr_gameclock/ tests/lib/controls.sh
#   tests/lib/instr_align.sh tests/lua/emu_clock.lua tests/lua/replay.lua tests/lua/trace_writes.lua tests/replays/
#   tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: known-bad: drift-clock — a watch run under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 2,817 emulated frames of 5,520 counted on 02_demitri_vs_cpu) must miss its frozen game clock (in-gate: one extra run; mode: every section 1-3 watch run, and with BUILD set every section 4 run (#261), runs the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
#
# WHY THIS EXISTS. Two of the beam port's rows are justified by "legacy
# never reaches this", which is a measurement, not an argument:
#
#   1. EFFECT-CLASS ROW 16. Every secondary-object pool dispatches on the
#      object's CLASS byte (+0x02) through a 38-row table of handler
#      pointers (vsavj 0x080AAC). vsav ships rows 16/17/19/31 as STUBS
#      pointing at the bare `rts` after the table; vs2/vh2 fill 16/17/19.
#      Row 16 is the beam's. Repointing it is superset-safe ONLY because
#      vanilla never dispatches class 16.
#
#   2. THE TYPE-12 HANDLER'S A5 SCRATCH. vs2's composite-list handler
#      parks three values at -0x4A80/-0x4A84/-0x4A88(a5) = RAM
#      $FF3580/$FF357C/$FF3578. vsavj DOES own that neighbourhood (a
#      0x200-byte buffer at $FF3502 cleared at match init by 0x016E04),
#      so keeping Capcom's displacements is safe only because those exact
#      ten bytes are never touched.
#
#   3. LIST-TYPE 10 IS NOT A DEAD SLOT. Recorded so the shortcut is not
#      re-proposed: vsav's drawer table has a bare `rts` at type 10, which
#      looks like a free slot to repoint instead of hooking the drawer. It
#      is not — legacy uses it thousands of times per replay.
#
# THE INSTRUMENT TRAP THIS TEST IS BUILT AROUND. Every one of these tables
# is read PC-RELATIVELY, and on CPS-2 a pc-relative read is served by
# m68k_read_pcrelative_* -> m_readimm16 -> AS_OPCODES. A plain `wpset`
# watchpoint is SILENTLY BLIND to it and reports ZERO hits, which reads as
# "this row is never used" and inverts the finding. Sections 1 and 3 use
# the opcodes space (WATCH=...,r,o -> wposet) and every section carries a
# POSITIVE CONTROL taken with the same instrument on the same leg, so a
# blind instrument cannot pass as a clean result.
#
# Usage: ROMDIR=... [REPLAYS="02_demitri_vs_cpu 07_mash_storm ..."] \
#            tests/audit_effect_class_rows.sh [--freeze-clock | --freeze]
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-71: the THREE deadness measurements the beam port rests on — effect-
#   class row 16 is never dispatched by vanilla (0 reads, against a 1760-hit
#   control on row 37); the composite handler's A5 scratch $FF3578-$FF3581 IS
#   used (39/replay) so vs2's displacements cannot be kept; and drawer list-
#   type 10 is NOT a spare slot (2702 reads) — the closed shortcut. EVERY
#   section carries a same-instrument positive control: this file exists
#   because a blind watchpoint and a real zero look identical, and both traps
#   bit here (GOTCHAS)
#   (THOSE COUNTS ARE THE frame_done CLOCK'S, 14z-197: on replay 02's 5,520 frames the row-37 control's run covered
#   3,759 emulated frames and type 10's 2,817 (#228 step 3); over the whole replay the control reads 3,872 and type 10
#   13,508 — sections 1 and 3 print them.
#   The zeros of row 16 hold over every frame of all six replays.)
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
CLOCKS="tests/expected/instr_gameclock/audit_effect_class_rows.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"

MAME_REF="${MAME_REF_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
# WIDENED 14z-91. The four short rigs were the default for ten sessions and
# are exactly why the type-6 deadness claim survived being false: neither of
# the two replays that actually reach the fallback was ever run here.
# 21_don_mash (387 entries) and 26_don_arcade_mash (948) are the long mash
# rigs that found it. Removing them from the default would restore the blind
# spot, so they stay; REPLAYS= still overrides for a quick pass.
REPLAYS="${REPLAYS:-02_demitri_vs_cpu 07_mash_storm 09_mirror_pick 30_demitri_throw 21_don_mash 26_don_arcade_mash}"

# frames: last scripted frame + tail, per replay
frames_for() {
    _last=$(grep -oE '^[0-9]+' "tests/replays/$1.rpl" | sort -n | tail -1)
    echo $((_last + 120))
}

# watch <replay> <addr> <len> <mode-space> <tag> -> prints the hit count
watch() {
    _r=$1; _a=$2; _l=$3; _ms=$4; _tag=$5
    unset MAME_ROMPATH || true
    ia_note "$WORK/manifest.tsv" vsavj "$_r" vsavj - "$REPO/tests/replays/$_r.rpl" "$(frames_for "$_r")" \
        "MAME_BIN=$MAME_REF WATCH=$_a,$_l,$_ms" "$WORK/$_tag.align"
    # shellcheck disable=SC2086
    env $_clk WATCH="$_a,$_l,$_ms" TRACE_OUT="$WORK/$_tag.txt" FRAMES="$(frames_for "$_r")" ALIGN_OUT="$WORK/$_tag.align" \
    REPLAY="$REPO/tests/replays/$_r.rpl" MAME_SANDBOX="$WORK/sbx_$_tag" \
    MAME_BIN="$MAME_REF" \
        tools/run_mame.sh vsavj -debug -debugger none \
        -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
        > "$WORK/$_tag.log" 2>&1 || { echo "RUNFAIL"; return; }
    # frame 1 with all-zero registers is the watchpoint ARMING artefact,
    # logged on every run — never a real access.
    awk '$1=="frame" && $2>1' "$WORK/$_tag.txt" | wc -l | tr -d ' '
}

fail=0

# ── 1. effect-class row 16 is DEAD in vanilla ──────────────────────────
# table 0x080AAC, row 16 slot = +16*4 = 0x080AEC.  control: row 37
# (0x080B40), the shared reader every effect object goes through.
echo "1. effect-class row 16 (0x080AEC) is never dispatched by vanilla"
for r in $REPLAYS; do
    n=$(watch "$r" 80aec 4 r,o "row16_$r")
    if [ "$n" = "0" ]; then echo "  ok: $r -> 0 reads"
    else echo "  FAIL: $r -> $n reads of the row we repoint"; fail=1; fi
done
echo "   positive control (row 37, the shared reader — same instrument, same leg):"
c=$(watch 02_demitri_vs_cpu 80b40 4 r,o ctl_row37)
if [ "$c" -gt 100 ] 2>/dev/null; then
    echo "  ok: $c reads — the opcodes-space watchpoint DOES fire here,"
    echo "      so the zeros above are a finding and not a blind instrument"
else
    echo "  FAIL: control read the shared reader $c times — instrument is blind,"
    echo "        every zero above is meaningless"; fail=1
fi

# ── 2. the type-12 handler's A5 scratch is untouched by vanilla ────────
# $FF3578-$FF3581 (10 bytes).  control: the SAME start widened to 0x10,
# which reaches $FF3582+ where vsavj's own buffer traffic lives.
echo "2. vanilla DOES use \$FF3578-\$FF3581, so the composite handler cannot"
echo "   keep vs2's own A5 displacements — it needs relocated scratch"
for r in $REPLAYS; do
    n=$(watch "$r" ff3578 a rw "scratch_$r")
    if [ "$n" -gt 0 ] 2>/dev/null; then
        echo "  ok: $r -> $n accesses (vsavj's \$FF3502 buffer reaches in here)"
    else
        echo "  FAIL: $r -> $n. If this window really is free that is a NEW"
        echo "        finding and vs2's displacements could be kept verbatim —"
        echo "        but check the INSTRUMENT first: a length the tracer"
        echo "        rejects kills the run and prints a clean-looking zero."
        fail=1
    fi
done

# ── 3. list-type 10 is NOT a free slot (the closed shortcut) ───────────
# drawer table base 0x01AFBA (entry 0's own offset IS the table length:
# 0x000C -> 6 entries, types 0..10).  Type 10's handler is a bare `rts`,
# which invites repointing it instead of hooking the drawer.
echo "3. drawer list-type 10 is USED by legacy (so it is not a spare slot)"
# every slot of the six-entry table (PRG:0x01AFBA, entry 0 = its 12-byte length) on the same replay, PRINTED: the
# per-type reads docs/game/atlas/sprite_lists.md quotes (14z-197: over the whole replay; only type 10 is asserted)
for ts in 0:1afba 2:1afbc 4:1afbe 6:1afc0 8:1afc2; do
    echo "  type ${ts%%:*}: $(watch 02_demitri_vs_cpu "${ts#*:}" 2 r,o "type${ts%%:*}") reads"
done
n=$(watch 02_demitri_vs_cpu 1afc4 2 r,o type10)
echo "  type 10: $n reads"
if [ "$n" -gt 100 ] 2>/dev/null; then
    echo "  ok: $n reads of the type-10 entry — repointing it would change"
    echo "      legacy rendering; the shortcut is closed, measured not assumed"
else
    echo "  FAIL: only $n reads — if type 10 really is dead, that is a NEW"
    echo "        finding and the beam port should use it instead of a hook"
    fail=1
fi

# ── 4. THE TRIPWIRE: how often does LEGACY take the type-6 fallback? ────
# THIS IS THE STANDING WATCH THE MAINTAINER ASKED FOR (14z-71). Sections 1-3
# measure absence, and absence of evidence is not evidence of absence — we
# may simply have missed how vsav uses list-type 6. The build therefore does
# not ASSUME the slot is dead: anything that is not one of our own lists
# falls through to vsav's original type-6 code.
#
# AND THE DEADNESS CLAIM WAS WRONG. 14z-89 measured legacy lists reaching
# type 6 on `21_don_mash` (387x) and `26_don_arcade_mash` (948x). The
# "safe and loud" design did its job — rendering stayed correct throughout,
# because the fallback runs vsav's own code instruction-for-instruction —
# and this is the DEADNESS REGISTER's first real hit.
#
# WHY IT WAS MISSED, and what changed here (14z-91): the default replay set
# was the four short rigs below, and nobody pointed the gate at a long mash
# rig. The two that arm it are now IN the default. That is the whole reason
# the widening is not optional.
#
# WATCH EXECUTION, NOT A COUNTER (maintainer ruling 14z-89 (2)). The
# fallback used to bump $FF010C. That is live work RAM vanilla does not
# keep, so the two arming replays could never re-converge with the vanilla
# masked basis and sat `.pending` — a permanent legacy divergence bought to
# observe an event we can observe directly. The counter is gone; this
# section breakpoints the fallback's ENTRY instead. Zero legacy RAM
# perturbation, no new mask window.
#
# THE VERDICT IS A FROZEN INVENTORY, NOT ZERO. A gate that fails on a
# known-nonzero event is permanently red and gets ignored, which is worse
# than no gate. Drift in EITHER direction is the stop-and-assess event: a
# new non-zero where zero was frozen means a fresh legacy path reached the
# taken-over type; a count that moves on 21/26 means the drawer's traffic
# changed.
#
# ADDRESSES ARE DERIVED, NEVER HARDCODED. The thunk's placed address and
# length come from the build's own atlas (a hardcoded size once made this
# fall back to an empty PC range and report a cheerful "unarmed" — the same
# blind-instrument shape this whole file exists to prevent), and the
# fallback's offset inside the body is decoded from the manifest's two entry
# branches, which must agree with each other.
FB_FROZEN="build/manifest/type6_fallback.toml"
if [ -n "${BUILD:-}" ]; then
    # absolute: section 5's reference legs run from their own directories (tests/lib/instr_align.sh _ia_leg)
    BUILD_ARG="$BUILD"   # as given, for the frozen files' headers (an absolute path would name this host)
    case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
    echo "4. the type-6 fallback's EXECUTION matches its frozen inventory"
    [ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "  FAIL: no $BUILD/rompath/vsavjw.zip"; fail=1; }
    THUNK=$(sed -n 's/^| `PRG:0x\([0-9A-Fa-f]*\)` | 0x[0-9A-Fa-f]* | GEN | site_thunk beam_list_type6 |.*/\1/p' \
            "$BUILD/patch/atlas_fragment.md" | head -1)
    if [ -z "$THUNK" ]; then
        echo "  FAIL: cannot find the beam_list_type6 thunk in $BUILD's atlas"; fail=1
    fi
    # the fallback offset, decoded from the manifest body's two entry branches
    FB_OFF=$(python3 - <<'PY'
import re, sys
b = bytes.fromhex(re.search(r'name = "beam_list_type6".*?thunk_hex = "([0-9a-f]+)"',
                            open('build/manifest/huitzil.toml').read(), re.S).group(1))
o1 = 0x06 + 2 + b[0x07]          # bcs.s  "not in our low region"
o2 = 0x0e + 2 + b[0x0f]          # bcc.s  "not in our high region"
if o1 != o2:
    sys.exit(f"entry branches disagree: {o1:#x} vs {o2:#x}")
print(o1)
PY
) || { echo "  FAIL: $FB_OFF"; fail=1; FB_OFF=""; }
    if [ -n "$THUNK" ] && [ -n "$FB_OFF" ]; then
        BP=$(printf '%x' $((0x$THUNK + FB_OFF)))
        echo "  (thunk at 0x$THUNK, fallback entry +$(printf '0x%x' "$FB_OFF") -> breakpoint 0x$BP)"
        got=""
        S4_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
        for r in $REPLAYS; do
            # each run is held to its frozen game clock in section 5, as sections 1-3 are (#261, ruled 2026-10-17)
            ia_note "$WORK/manifest.tsv" merged "$r" vsavjw "$BUILD/rompath;$ROMDIR" "$REPO/tests/replays/$r.rpl" \
                "$(frames_for "$r")" "MAME_BIN=$S4_BIN WATCH=$BP,1,b" "$WORK/trip_$r.align"
            # shellcheck disable=SC2086
            env $_clk MAME_ROMPATH="$BUILD/rompath;$ROMDIR" ALIGN_OUT="$WORK/trip_$r.align" \
            WATCH="$BP,1,b" TRACE_OUT="$WORK/trip_$r.txt" FRAMES="$(frames_for "$r")" \
            REPLAY="$REPO/tests/replays/$r.rpl" MAME_SANDBOX="$WORK/sbx_trip_$r" \
            MAME_BIN="$S4_BIN" \
                tools/run_mame.sh vsavjw -debug -debugger none \
                -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
                > "$WORK/trip_$r.log" 2>&1 || { echo "  FAIL: $r run did not complete"; fail=1; continue; }
            n=$(awk -v p="$BP" '$1=="frame" && $3=="PC" && tolower($4)==tolower(p)' \
                "$WORK/trip_$r.txt" | grep -c '^' || true)
            got="$got $r:$n"
            want=$(sed -n "s/^$r = \([0-9]*\)$/\1/p" "$FB_FROZEN" 2>/dev/null | head -1)
            if [ "${1:-}" = "--freeze" ] || [ "$FREEZE_CLOCK" = 1 ]; then
                echo "  measured: $r -> $n"
            elif [ -z "$want" ]; then
                echo "  FAIL: $r has no frozen expectation in $FB_FROZEN (measured $n)"
                echo "        run with --freeze after REVIEWING the number"; fail=1
            elif [ "$n" = "$want" ]; then
                echo "  ok: $r -> $n fallback entries (frozen)"
            else
                echo "  FAIL: $r took the type-6 fallback $n time(s), frozen at $want."
                echo "        DRIFT EITHER WAY IS A STOP-AND-ASSESS EVENT: a new"
                echo "        non-zero means a legacy path reached the taken-over"
                echo "        list-type 6 for the first time; a changed count means"
                echo "        the drawer's traffic moved. Re-open the deadness claim"
                echo "        before continuing. See build/manifest/huitzil.toml,"
                echo "        site_thunk beam_list_type6."
                fail=1
            fi
        done
        # POSITIVE CONTROL, same instrument and same leg. The old counter
        # design had one for free: the boot RAM test wrote $FF010C, so a
        # totally dead watchpoint could not look clean. A breakpoint sees
        # none of that, so arm one on a PC that MUST execute and require
        # hits — otherwise "0 entries" and "bpset silently did nothing" are
        # the same observation. 0x000D36 is one of the boot RAM-test PCs the
        # old design had to filter OUT; here it is the liveness proof.
        cr="$(echo "$REPLAYS" | awk '{print $1}')"
        MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
        WATCH="d36,1,b" TRACE_OUT="$WORK/ctl.txt" FRAMES=200 \
        REPLAY="$REPO/tests/replays/$cr.rpl" MAME_SANDBOX="$WORK/sbx_ctl" \
        MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}" \
            tools/run_mame.sh vsavjw -debug -debugger none \
            -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
            > "$WORK/ctl.log" 2>&1 || true
        cn=$(awk '$1=="frame" && $3=="PC"' "$WORK/ctl.txt" 2>/dev/null | grep -c '^' || true)
        if [ "${cn:-0}" -gt 0 ]; then
            echo "  ok: instrument control — bpset arms under this romset ($cn hits at 0x000d36)"
        else
            echo "  FAIL: instrument control DEAD — a breakpoint on the boot RAM test"
            echo "        PC 0x000d36 reported no hits, so every '0 entries' above is"
            echo "        meaningless. Fix the instrument before reading any verdict."
            fail=1
        fi
        if [ "${1:-}" = "--freeze" ]; then
            { echo "# build/manifest/type6_fallback.toml — FROZEN per-replay count of"
              echo "# LEGACY entries into the type-6 fallback (14z-91). Regenerate with"
              echo "# BUILD=<dir> tests/audit_effect_class_rows.sh --freeze, and REVIEW"
              echo "# every number: this file is the record of how often vanilla content"
              echo "# reaches a list-type we took over. Drift either way is a"
              echo "# stop-and-assess event, never something to absorb."
              echo "# Frozen on BUILD=$BUILD_ARG at $(git rev-parse --short=8 HEAD). The 14z-89 counts, taken by the old"
              echo "# \$FF010C counter (21_don_mash 387, 26_don_arcade_mash 948), had moved before this first freeze;"
              echo "# both moves are recorded UNATTRIBUTED (#261, maintainer-ruled 2026-10-17). Measured before the freeze"
              echo "# (on #261): this build under the old frame_done clock reads 21_don_mash 388 (consistent with the"
              echo "# 14z-197 clock change, not proven: another instrument and build in 14z-89) and 26_don_arcade_mash"
              echo "# 1316 (so not the clock)."
              echo "schema = 1"; echo
              for kv in $got; do
                  echo "${kv%%:*} = ${kv##*:}"
              done
            } > "$WORK/type6_new.toml"   # promoted after section 5, only if every check held (#261)
        fi
    fi
else
    echo "4. fallback-execution check SKIPPED (set BUILD=<the merged build> to run it; the registry passes BUILD=%MERGED%)"
fi

echo "5. the instrument's alignment, sections 1-3 and section 4's runs (#228 step 4, option A; #261)"
if [ "$FREEZE_CLOCK" = 1 ]; then
    [ "$fail" = 0 ] || { echo "REFUSED: sections 1-4 failed — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/trace_writes.lua" "$WORK/manifest.tsv" "$WORK/fz" "${JOBS:-4}" "$WORK/clocks.tsv" \
        > "$WORK/fz.txt" || { sed 's/^/  /' "$WORK/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`${BUILD_ARG:+BUILD=$BUILD_ARG }tests/audit_effect_class_rows.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): pristine vsavj,"
      echo "# sections 1-3, and leg merged = section 4's runs on that build (#261); every reference leg held to replay.lua run"
      echo "# live, every watch run to its reference leg's game clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$WORK/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$WORK/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
if ia_check_manifest "$CLOCKS" "$WORK/manifest.tsv" > "$WORK/align_bad.txt"; then
    echo "  ok: every section 1-3 run${BUILD:+ and section 4 run} on emulated time, at its frozen game clock"
else echo "  FAIL: $(wc -l < "$WORK/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$WORK/align_bad.txt" | sed 's/^/        /'; fail=1; fi
ia_stage audit_effect_class_rows "$CLOCKS" "$REPO/tests/lua/trace_writes.lua" "$WORK/manifest.tsv" 1 "$WORK/st" "$MODE" || fail=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "FAIL audit_effect_class_rows.sh (control mode: $MODE)"; exit 1; }
    echo "FAIL audit_effect_class_rows.sh — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi


if [ "${1:-}" = "--freeze" ] && [ -f "$WORK/type6_new.toml" ]; then
    if [ "$fail" = 0 ]; then cp "$WORK/type6_new.toml" "$FB_FROZEN"; echo "  FROZE $FB_FROZEN"
    else echo "  REFUSED: a check failed — $FB_FROZEN not written"; fi
fi
echo
if [ "$fail" -eq 0 ]; then echo "PASS audit_effect_class_rows.sh"; exit 0
else echo "FAIL audit_effect_class_rows.sh"; exit 1; fi
