#!/bin/sh
# audit_wide_phase_a.sh — CPS-2 WIDE Phase A measurements (no ROM growth,
# no emulator changes). Each section answers ONE architecture question and
# prints a decision line. Run on VANILLA vsavj: these measure what the
# ORIGINAL game does, which is what the profile must not disturb.
#
#   A1  unmapped 68k address space   -> is PRG linear growth to 6MB inert?
#   A2  OBJ y-word bit 12            -> is the 19th tile-address bit free?
#       (bit 15 is NOT available: it terminates the CPS-2 sprite list)
#   A3  scroll3 tile-address wrap    -> is growing the gfx region inert?
#   A4  Z80 driver ROM free space    -> is there room for new sample rows?
#
# Full rationale: the approved WIDE plan + docs/project/cps2_wide.md.
# Usage: ROMDIR=... tests/audit_wide_phase_a.sh [corpus...]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The legacy corpus: vanilla-content replays that exercise attract, menus,
# matches, 2P, throws, timeouts and the service path. Deliberately NOT the
# Donovan replays — Phase A measures vanilla behaviour.
CORPUS="${*:-01_attract_long 02_demitri_vs_cpu 03_two_player_vs 04_select_fuzz \
05_timeout_idle 06_test_mode 07_mash_storm 08_challenger_join 09_mirror_pick \
10_midattract_start 29_felicia_walljump 30_demitri_throw}"

run_one() { # $1=script $2=replay $3=outfile $4=frames  (extra env passed through)
    mkdir -p "$WORK/$2"
    # MAME can segfault during teardown after manager.machine:exit() — a
    # known cosmetic race in this harness. The log is fully written before
    # that, so the exit code is not evidence; every caller asserts on the
    # instrument's own SUMMARY line instead.
    REPLAY="$REPO/tests/replays/$2.rpl" FRAMES="$4" TRACE_OUT="$3" \
        CHECKSUM_OUT="$WORK/$2/c.log" MAME_SANDBOX="$WORK/$2" \
        MAME_ROMPATH="$ROMDIR" tools/run_mame.sh vsavj \
        -autoboot_script "$REPO/tests/lua/$1" > /dev/null 2>&1 || true
}

echo "== A1: unmapped 68k address space (decides PRG growth cost) =="
# Ground-truth the instrument first: a null result is only evidence if the
# probe can demonstrably see a real access (CLAUDE.md §4 — verdict logic is
# itself tested).
mkdir -p "$WORK/ctl"
PROBE_CONTROL=1 REPLAY="$REPO/tests/replays/02_demitri_vs_cpu.rpl" FRAMES=600 \
    TRACE_OUT="$WORK/a1_control.txt" CHECKSUM_OUT="$WORK/ctl/c.log" \
    MAME_SANDBOX="$WORK/ctl" MAME_ROMPATH="$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/unmapped_probe.lua" > /dev/null 2>&1
ctl=$(grep UNMAPPEDSUMMARY "$WORK/a1_control.txt" 2>/dev/null \
      | sed -E 's/.*CONTROL_workram=([0-9]+).*/\1/')
if [ -z "${ctl:-}" ] || [ "$ctl" -eq 0 ]; then
    echo "  FAIL: control window saw 0 reads of work RAM — the probe is blind,"
    echo "        so a null result would be meaningless. Fix before trusting A1."
    exit 1
fi
echo "  ok: instrument ground-truthed (control window saw $ctl work-RAM reads)"
a1_total=0
for rp in $CORPUS; do
    run_one unmapped_probe.lua "$rp" "$WORK/a1_$rp.txt" 3600
    line=$(grep UNMAPPEDSUMMARY "$WORK/a1_$rp.txt" || echo "MISSING")
    [ "$line" = MISSING ] && { echo "  FAIL $rp: no summary"; exit 1; }
    n=$(echo "$line" | sed -E 's/.*total=([0-9]+).*/\1/')
    a1_total=$((a1_total + n))
    [ "$n" -eq 0 ] || echo "  $rp: $line"
done
if [ "$a1_total" -eq 0 ]; then
    echo "  ok: ZERO reads in every candidate window across the corpus"
    echo "  DECISION A1: linear PRG growth to 6MB is inert -> zero FBNeo core lines"
else
    echo "  DECISION A1: $a1_total reads into candidate windows -> use the high"
    echo "               window (\$A00000) + 2 declarative SekMapMemory lines"
fi

echo "== A2: OBJ y-word bit 12 (decides the 19th tile-address bit) =="
a2_bad=0
for rp in $CORPUS; do
    run_one objy_bits.lua "$rp" "$WORK/a2_$rp.txt" 3600
    line=$(grep OBJYSUMMARY "$WORK/a2_$rp.txt" || echo "MISSING")
    [ "$line" = MISSING ] && { echo "  FAIL $rp: no summary"; exit 1; }
    b=$(echo "$line" | sed -E 's/.*bit12=([0-9]+).*/\1/')
    [ "$b" -eq 0 ] || { echo "  BIT12 SET in $rp: $line"; a2_bad=$((a2_bad + 1)); }
done
if [ "$a2_bad" -eq 0 ]; then
    echo "  ok: bit 12 never set by vanilla on a live sprite"
    echo "  DECISION A2: 19th bit available via the CPS-2 Turbo rule (bit12 -> bit15 promote)"
else
    echo "  DECISION A2: BLOCKED — vanilla uses y-word bit 12; the 19-bit plan needs"
    echo "               a different bit. Do NOT append gfx groups until resolved."
fi

echo "== A3: scroll3 tile-address wrap (decides gfx-growth inertness) =="
# scroll3 absolute tile index = 0x10000 + 4*code; it exceeds the 0x40000-tile
# region (and today WRAPS via nCpsGfxMask) once code >= 0xC000.
a3_max=0
for rp in $CORPUS; do
    SCROLL3_OUT="$WORK/a3_$rp.txt" run_one scroll3_watch.lua "$rp" "$WORK/a3_t_$rp.txt" 3600 || true
    line=$(grep SCROLL3SUMMARY "$WORK/a3_$rp.txt" 2>/dev/null || echo "")
    [ -n "$line" ] || { echo "  note: $rp produced no scroll3 summary"; continue; }
    # Use the CENSUS max, which excludes the 0xFFFF blank/uninitialised
    # sentinel. Raw maxcode is always 0xFFFF because unused tilemap cells
    # hold it, and that would report a permanent false BLOCKED.
    cen=$(grep SCROLL3CENSUS "$WORK/a3_$rp.txt" 2>/dev/null || echo "")
    [ -n "$cen" ] || { echo "  note: $rp produced no scroll3 census"; continue; }
    mc=$(echo "$cen" | sed -E 's/.*max_real=([0-9a-f]+).*/\1/')
    hc=$(echo "$cen" | sed -E 's/.*high_cells=([0-9]+).*/\1/')
    mcd=$((0x$mc))
    [ "$mcd" -gt "$a3_max" ] && a3_max=$mcd
    [ "$hc" -eq 0 ] || echo "  $rp: $cen"
done
printf '  corpus max REAL scroll3 code: 0x%x (wrap threshold 0xC000; 0xFFFF blanks excluded)\n' "$a3_max"
if [ "$a3_max" -lt 49152 ]; then
    echo "  DECISION A3: no real legacy code reaches the wrap point -> gfx growth is"
    echo "               inert for scroll3. (Blank 0xFFFF cells still nominally address"
    echo "               past the region; B1's pixel gate is the definitive confirmation.)"
else
    echo "  DECISION A3: BLOCKED — legacy scroll3 codes reach the wrap point; growing"
    echo "               the gfx region changes their addresses. A compat mask must be"
    echo "               designed BEFORE any member is appended."
fi

echo "== A4: Z80 driver ROM free space (room for new sample-table rows?) =="
python3 tools/audit_z80_space.py "$ROMDIR/vsav.zip:vm3"

echo "PHASE A COMPLETE — record the four decision lines in STATE.md"
