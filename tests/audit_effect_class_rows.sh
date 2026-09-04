#!/bin/sh
# audit_effect_class_rows.sh — the THREE deadness measurements the beam
# port rests on (14z-71). All are ROM-read audits, and the first two are
# the ONLY guards their claims have.
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
#            tests/audit_effect_class_rows.sh
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
    WATCH="$_a,$_l,$_ms" TRACE_OUT="$WORK/$_tag.txt" FRAMES="$(frames_for "$_r")" \
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
n=$(watch 02_demitri_vs_cpu 1afc4 2 r,o type10)
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
        for r in $REPLAYS; do
            MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
            WATCH="$BP,1,b" TRACE_OUT="$WORK/trip_$r.txt" FRAMES="$(frames_for "$r")" \
            REPLAY="$REPO/tests/replays/$r.rpl" MAME_SANDBOX="$WORK/sbx_trip_$r" \
            MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}" \
                tools/run_mame.sh vsavjw -debug -debugger none \
                -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
                > "$WORK/trip_$r.log" 2>&1 || { echo "  FAIL: $r run did not complete"; fail=1; continue; }
            n=$(awk -v p="$BP" '$1=="frame" && $3=="PC" && tolower($4)==tolower(p)' \
                "$WORK/trip_$r.txt" | grep -c '^' || true)
            got="$got $r:$n"
            want=$(sed -n "s/^$r = \([0-9]*\)$/\1/p" "$FB_FROZEN" 2>/dev/null | head -1)
            if [ "${1:-}" = "--freeze" ]; then
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
              echo "schema = 1"; echo
              for kv in $got; do
                  echo "${kv%%:*} = ${kv##*:}"
              done
            } > "$FB_FROZEN"
            echo "  FROZE $FB_FROZEN"
        fi
    fi
else
    echo "4. fallback-execution check SKIPPED (set BUILD=build/hui40 to run it)"
fi

echo
if [ "$fail" -eq 0 ]; then echo "PASS audit_effect_class_rows.sh"; exit 0
else echo "FAIL audit_effect_class_rows.sh"; exit 1; fi
