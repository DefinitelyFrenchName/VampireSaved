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
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

MAME_REF="${MAME_REF_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
REPLAYS="${REPLAYS:-02_demitri_vs_cpu 07_mash_storm 09_mirror_pick 30_demitri_throw}"

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

# ── 4. THE TRIPWIRE: legacy never takes the type-6 fallback ────────────
# THIS IS THE STANDING WATCH THE MAINTAINER ASKED FOR (14z-71). Sections 1-3
# measure absence, and absence of evidence is not evidence of absence — we
# may simply have missed how vsav uses list-type 6. The build therefore does
# not ASSUME the slot is dead: anything that is not one of our own lists
# falls through to vsav's original type-6 code, and bumps a counter at
# $FF010C on the way past. A write to that counter means a list we did not
# author reached the taken-over type, i.e. the deadness measurement was
# WRONG. Rendering is still correct (that is the point of the fallback), but
# it is a STOP-AND-ASSESS event: do not carry on until it is understood.
#
# COUNT BY PC, NOT BY FRAME. The boot RAM test writes every byte of work RAM,
# $FF010C included (frames 5-72, PCs 0x000D36/0x000D3C/0x000DDC), so a bare
# write count reports five "tripwire hits" on a perfectly clean run — this
# gate cried wolf the first time it ran. Filtering by frame would work but
# would also blind the check during boot and attract. Instead the write must
# come from INSIDE the placed thunk body, whose address is read from the
# build's own atlas — so boot clears are excluded by construction and a real
# arming is caught at any frame.
if [ -n "${BUILD:-}" ]; then
    echo "4. the type-6 fallback tripwire (\$FF010C) is never armed on legacy"
    [ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "  FAIL: no $BUILD/rompath/vsavjw.zip"; fail=1; }
    # size-agnostic: the body grows as pieces are added (0x62 -> 0x102 when
    # the ported type-4 handler went in). A hardcoded size made this fall
    # back to an empty PC range and report a cheerful "unarmed" — the same
    # blind-instrument shape this whole file exists to prevent.
    THUNK=$(sed -n 's/^| `PRG:0x\([0-9A-Fa-f]*\)` | 0x[0-9A-Fa-f]* | GEN | site_thunk beam_list_type6 |.*/\1/p' \
            "$BUILD/patch/atlas_fragment.md" | head -1)
    THUNK_LEN=$(sed -n 's/^| `PRG:0x[0-9A-Fa-f]*` | 0x\([0-9A-Fa-f]*\) | GEN | site_thunk beam_list_type6 |.*/\1/p' \
            "$BUILD/patch/atlas_fragment.md" | head -1)
    if [ -z "$THUNK" ]; then
        echo "  FAIL: cannot find the beam_list_type6 thunk in $BUILD's atlas"; fail=1
    else
        echo "  (thunk body at 0x$THUNK; only writes from inside it count)"
    fi
    THUNK_LO=$((0x$THUNK)); THUNK_HI=$((THUNK_LO + 0x${THUNK_LEN:-62}))
    for r in $REPLAYS; do
        MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
        WATCH=ff010c,2,w TRACE_OUT="$WORK/trip_$r.txt" FRAMES="$(frames_for "$r")" \
        REPLAY="$REPO/tests/replays/$r.rpl" MAME_SANDBOX="$WORK/sbx_trip_$r" \
        MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}" \
            tools/run_mame.sh vsavjw -debug -debugger none \
            -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
            > "$WORK/trip_$r.log" 2>&1 || { echo "  FAIL: $r run did not complete"; fail=1; continue; }
        # POSIX awk has no strtonum, so convert the PC in the shell
        n=0
        for pc in $(awk '$1=="frame" && $3=="PC" {print $4}' "$WORK/trip_$r.txt"); do
            v=$((0x$pc))
            if [ "$v" -ge "$THUNK_LO" ] && [ "$v" -lt "$THUNK_HI" ]; then
                n=$((n + 1))
            fi
        done
        if [ "$n" = "0" ]; then echo "  ok: $r -> tripwire unarmed"
        else
            echo "  FAIL: $r armed the tripwire $n time(s) — A LEGACY LIST REACHED"
            echo "        LIST-TYPE 6. Rendering is still correct (the fallback runs"
            echo "        vanilla's own code), but STOP: re-open the type-6 deadness"
            echo "        claim before continuing. See build/manifest/huitzil.toml,"
            echo "        site_thunk beam_list_type6."
            fail=1
        fi
    done
else
    echo "4. tripwire check SKIPPED (set BUILD=build/hui20 to run it)"
fi

echo
if [ "$fail" -eq 0 ]; then echo "PASS audit_effect_class_rows.sh"; exit 0
else echo "FAIL audit_effect_class_rows.sh"; exit 1; fi
