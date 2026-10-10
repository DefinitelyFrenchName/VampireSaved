#!/bin/sh
# audit_walker_ghost.sh — WHERE ON THE LIVE STACK does each object-pool walker's `jsr (A0)` push its return address, and does that longword lie outside every legacy-oracle mask? (14z-91; re-stated on the live stack 14z-185, GitHub #143)
#
# WHAT: where each object-pool walker's `jsr (A0)` pushes its return address — the one
#   longword of state the walker relocation changes — measured on the LIVE stack, and that it
#   lands outside every legacy-oracle mask, so no mask hides it from the per-frame oracle's
#   checksum (whether the oracle's verdicts catch a differing byte there: see NOT covered below).
# HOW: corpus-wide MAME -debug runs of tests/lua/walker_sp.lua (the live stack chosen by SR's
#   S bit, and the long on top of it) at both walker sites on pristine vsavj, and at the RELOCATED
#   walkers' sites on the build under test (derived from its own call sites); tools/walker_ghost.py
#   proves the pointer against the vsavj opcode image (each long on top ends a `jsr abs.l` to the
#   walker; the build's own image for the relocated leg), checks the push against the union of
#   tests/expected/**/mask, and compares the live ranges with build/manifest/walker_ghost.toml —
#   the relocated sites with the vanilla sites' frozen ranges (the relocation pushes at the same depth).
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): walker_sp.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua); every run's game clock RAM:$FF8080 at its last frame is held to
#   tests/expected/instr_gameclock/audit_walker_ghost.tsv, frozen by `--freeze-clock` from REFERENCE legs (the
#   same script, no breakpoint, no debugger — each pristine one reproducing the frozen basis checksum, each
#   breakpoint run's game clock equal to its reference leg's); one STAGING reference leg (21_don_mash, pristine)
#   is held to the basis on every run.
# EXPECTS: the reader's PASS: every long on top of the read stack a genuine return address, the
#   push outside every mask, the live ranges as frozen; every run on emulated time at its frozen game clock and
#   the staging leg on the basis; the five controls fail.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/ tests/lib/controls.sh
#   tests/lib/decrypt_cache.sh tests/lib/instr_align.sh tests/lua/emu_clock.lua tests/lua/replay.lua tests/lua/walker_sp.lua
#   tests/replays/ tools/run_mame.sh tools/setup_mame.sh tools/walker_ghost.py
#
# MUST-FIRE: known-bad: supervisor-read — the instrument forced to read MAME's SP (the idle supervisor stack, the pre-14z-185 read) must fail the ground-truth check: the longs on top of that stack end no call to the walker (in-gate: one extra run of 21_don_mash with WALKER_SP_READ=sp must fail GROUND; mode: every corpus run of BOTH legs reads SP and the gate FAILs on each) (GitHub #143, 14z-185)
# MUST-FIRE: perturbed-copy: range-moved — the frozen sp_min shifted by 2 must fail the frozen compare, so a moved live range is re-frozen deliberately (in-gate: the reader run with --frozen-shift 2 must fail FROZEN; mode: the gate's own read carries the shift and FAILs)
# MUST-FIRE: known-bad: drift-clock — a breakpoint run under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 4,203 emulated frames of 40,620 counted on 26_don_arcade_mash) must miss its frozen game clock (in-gate: one extra run of 21_don_mash; mode: every breakpoint run of both legs runs the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss the frozen basis checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
# MUST-FIRE: perturbed-copy: mask-covers — one extra mask range over the push must fail the visibility check, so a mask hiding the relocated return address is caught (in-gate: the reader run with --extra-mask over the push must fail VISIBLE; mode: the gate's own read carries the mask and FAILs)
#
# THE PREMISE THIS GATE WAS BUILT ON IS RETRACTED (14z-185, GitHub #143, the maintainer's ruling
# "Freeze the real ranges (Recommended)", DECISIONS_HISTORY.md "Ruled 2026-09-28 (14z-185) — #143").
# Until 14z-185 it asserted the push lay INSIDE the masked dead-stack window $FF7F00-$FF7FFF, from
# walker_sp.lua reading `A7 or SP` — on MAME 0.288 the SUPERVISOR stack, idle at a constant
# $FF7FF6. The walkers run in USER mode (the S bit clear on every hit, vanilla and merged-m20): the
# live stack at the `jsr (A0)` is $FF06DE / $FF055E..$FF06DE, and the push lands at $FF055A-$FF06DD,
# in UNMASKED work RAM, proven by the return address on top of it on every hit of this gate's two
# legs (14z-185: 8,586 + 315,008 on pristine vsavj, 8,591 + 313,113 at the relocated sites on
# merged-m20, the relocated ranges equal to the vanilla ones). The
# relocation's legacy safety therefore rests on the legacy oracle, not on a mask: no oracle mask
# covers that range (the VISIBLE check). Measured once, 14z-185: a byte planted at $FF06DA under
# the oracle's own replay.lua and mask moved its checksum on one exact replay (01_attract_long);
# the rest of the range and the other replays were not planted. NOT covered: the oracle's window, composite and
# flicker verdicts tolerate divergences inside ratified ranges, so a push that survived to a
# checksum there would pass; whether one does is not measured here. An unmeasured lead: 14z-89
# saw live "execution position" divergences at $FF06B5-$FF06D3, inside this range.
#
# WHY (14z-91). The obj_hook legacy-cycle regression's fix relocates each
# walker (0x54458 / 0x5E52A, 0x2C bytes) into free space, appends the
# extended type table at copy+0x2C — the site's own `movea.l (0x12,PC,D0.w)`
# displacement lands there BY CONSTRUCTION — and repoints the `jsr <walker>`
# call sites. The vanilla dispatch instruction is never patched, so not one
# instruction is added and not one instruction's timing changes: `jsr abs.l`
# costs the same whatever its operand, `movea.l (d8,PC,Dn.w)` the same
# wherever PC points. That is why this fix is zero-cost BY CONSTRUCTION
# rather than by census (option (b), maintainer 2026-08-15).
#
# EXACTLY ONE BYTE OF STATE DIFFERS: the relocated `jsr (A0)` pushes
# <copy>+0x20 where vanilla pushed <walker>+0x20. Same stack DEPTH, same
# order, same everything else. [RETRACTED 14z-185, #143 — see above: the
# claim that followed, that the longword is invisible to the legacy oracle
# because it lands inside the dead-stack mask window, rested on the idle
# supervisor stack.] That longword is invisible to the legacy
# oracle if and only if it lands inside the ratified dead-stack mask window
# RAM:$FF7F00-$FF7FFF (CLAUDE.md §4; docs/game/atlas/ram.md). The push
# occupies [A7-4, A7-1], so the test is:
#
#     min(A7) - 4 >= 0xFF7F00      and      max(A7) <= 0xFF8000
#
# IF THIS FAILS, THE DESIGN STOPS. The answer is NOT to widen the mask —
# that silently redefines the baseline the superset invariant rests on, and
# it would buy a permanent blind spot over live work RAM. Escalate.
# [RETRACTED 14z-185, #143: measured on the live stack, it FAILS — the push lands at
# $FF055A-$FF06DD — and "fails the window" is not "not bit-identical": the
# relocation is live on merged-m20 and tests/audit_merged_legacy.sh lands all
# 53 legacy pairings on their ratified classes there. Escalated as #143; the
# maintainer, told the push lands in unmasked RAM, ruled what this gate checks
# from now on: "Freeze the real ranges (Recommended)". No mask was widened.]
#
# DO NOT ASSUME ONE STACK. 14z-89 attributed live divergences to execution
# position at BOTH $FF06B5-$FF06D3 and $FFF991-$FFF9D3, so this engine keeps
# more than one region holding return addresses. The per-page histogram is
# part of the verdict, not decoration: it says where the stack actually is.
#
# COVERAGE. [RETRACTED 14z-197, GitHub #228 step 4: "fires in only 5 of ~50 corpus replays" was the
# frame_done clock's artefact — each run stopped after a fraction of its replay (26_don_arcade_mash: 4,203
# emulated frames of 40,620 counted). On emulated time the walker's `jsr (A0)` at 0x54476 fires in 50 of 56
# replays, 380,413 times, over the same live range as the other walker; walker_ghost.toml re-frozen.] Was:
# Site 0x54470 fires in only 5 of ~50 corpus replays (the long
# mash/arcade rigs) — the same thin base the dispatch census reports. That
# matters much less here than it does for a deadness claim: this measures
# where the stack IS, not that something never happens, and the stack depth
# at a fixed call site is a structural property of the call chain. Still,
# the per-site replay count is printed so the base is visible.
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=8] [BUILD=build/m3b_merged31] [--freeze | --freeze-clock] tests/audit_walker_ghost.sh
# ~6 min (two corpus-wide debug legs, JOBS-parallel; 83 s on this MacBook at 14z-185 while the frame_done clock
# cut the long replays short; 320 s at 14z-197 on emulated time, the whole replays played).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-91: WHERE does each object-pool walker's `jsr (A0)` push its return
#   address, and is that longword inside the masked dead-stack window? THE
#   measurement that gates the walker relocation — it is the single piece of
#   state the move changes. Measured A7 = 0xff7ff6 CONSTANT at BOTH walkers
#   over 279,577 dispatches in all 49 corpus replays, so the push lands at
#   0xff7ff2-0xff7ff5, inside $FF7F00-$FF7FFF. [RETRACTED 14z-185, #143: that
#   A7 was the idle supervisor stack; the live push lands at $FF055A-$FF06DD.] Frozen in
#   build/manifest/walker_ghost.toml. FAILS rather than widening anything: the
#   header says widening the mask is NOT the remedy. Cross-check: the dispatch
#   counts reproduce dispatch_census.toml exactly on a different register. ~5
#   min
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
JOBS="${JOBS:-8}"
# the `jsr (A0)` of each walker = walker + 0x1E (walker 0x54458 / 0x5E52A)
SPSITES="54476,5e548"
FROZEN="build/manifest/walker_ghost.toml"
BUILD="${BUILD:-build/m3b_merged31}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
. "$REPO/tests/lib/instr_align.sh"
CLOCKS="tests/expected/instr_gameclock/audit_walker_ghost.tsv"
BASIS=tests/expected/vsavj/masked-v2; MASK="$(cat "$BASIS/MASK")"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_da.bin" || { echo "FAIL: vsavj views not delivered"; exit 1; }

run1() {  # run1 <replay> <out dir> [sp] [set] [rompath] [sites] [env...] — one walker_sp.lua run (background);
          # its ALIGN line to <out dir>/<replay>.align; INSTR_REFERENCE=1 among the env makes it a reference leg
    _n="$1"; _o="$2"; _rpl="tests/replays/$_n.rpl"; mkdir -p "$_o"
    _set="${4:-vsavj}"; _rp="${5:-$ROMDIR}"; _sites="${6:-$SPSITES}"; _x="${7:-}"
    _lf=$(sed 's/#.*//' "$_rpl" | awk 'NF { split($1, r, "-"); f=(r[2]?r[2]:r[1]);
         if (f + 0 > m) m = f + 0 } END { print m + 0 }')
    _fr=$((_lf + 120)); _an="$_fr"
    if [ -f "$BASIS/logs/$_n.log" ]; then
        _an="$(awk '$1 ~ /^[0-9]+$/ {l=$1} END {print l+0}' "$BASIS/logs/$_n.log")"; [ "$_an" -gt "$_fr" ] && _an="$_fr"
    fi
    _dbg="-debug -debugger none"; case "$_x" in *INSTR_REFERENCE=1*) _dbg="" ;; esac
    # shellcheck disable=SC2086
    ( env $_x MAME_SANDBOX="$_o/sb_$_n" REPLAY="$PWD/$_rpl" SPSITES="$_sites" SP_OUT="$_o/$_n.txt" \
      WALKER_SP_READ="${3:-}" FRAMES=$_fr ANCHOR=$_an MASK_RANGES="$MASK" ALIGN_OUT="$_o/$_n.align" \
      MAME_ROMPATH="$_rp" tools/run_mame.sh "$_set" $_dbg \
      -autoboot_script "$PWD/tests/lua/walker_sp.lua" >"$_o/$_n.log" 2>&1; rm -rf "$_o/sb_$_n" ) </dev/null &
}
basis_at() { awk -v n="$2" '$1 == n {print $2}' "$BASIS/logs/$1.log"; }   # basis_at <replay> <frame>
names="$(ls tests/expected/vsavj/masked-v2/logs/*.log | xargs -n1 basename | sed 's/\.log$//')"
echo "corpus: $(echo "$names" | wc -w | tr -d ' ') legacy replays (every replay with a vanilla basis log)"
_sp=""; vs_ctl_is supervisor-read && _sp=sp
_clk=""; vs_ctl_is drift-clock && _clk="INSTR_CLOCK=frame_done"
_skip=""; vs_ctl_is first-frame-skip && _skip="INSTR_CLOCK=skip_first"
pool=0
for n in $names; do
    [ -f "tests/replays/$n.rpl" ] || continue
    run1 "$n" "$W/runs" "$_sp" vsavj "$ROMDIR" "$SPSITES" "$_clk"
    pool=$((pool + 1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done
run1 21_don_mash "$W/ctl_sp" sp      # the supervisor-read control's one run
run1 21_don_mash "$W/stage" "" vsavj "$ROMDIR" "$SPSITES" "INSTR_REFERENCE=1 $_skip"   # the staging reference leg (#228)
run1 21_don_mash "$W/ctl_drift" "" vsavj "$ROMDIR" "$SPSITES" "INSTR_CLOCK=frame_done" # the drift-clock control's run
run1 21_don_mash "$W/ctl_skip" "" vsavj "$ROMDIR" "$SPSITES" "INSTR_REFERENCE=1 INSTR_CLOCK=skip_first"
wait
# THE RELOCATED LEG (rule-checker 2026-09-28-383 Q4): the ghost IS the relocated walker's push, so the same corpus
# runs on the build under test at its RELOCATED `jsr (A0)` sites, derived from the build's own image: the call sites
# 0x0053F6 (vanilla `jsr 0x05E52A`) and 0x009436 (`jsr 0x054458`) jump to the copies, and site = copy + 0x1E.
RELOC=""
if [ -f "$BUILD/verify_op.bin" ] && [ -f "$BUILD/rompath/vsavjw.zip" ]; then
    RELOC="$(python3 -c "
import sys
img = open('$BUILD/verify_op.bin', 'rb').read()
out = []
for call, van in ((0x0053F6, 0x5E548), (0x009436, 0x54476)):
    assert img[call:call + 2] == b'\x4e\xb9', hex(call)
    copy = int.from_bytes(img[call + 2:call + 6], 'big')
    out.append(f'{copy + 0x1E:x}={van:x}')
print(' '.join(out))")" || { echo "FAIL: the relocated walker sites could not be derived from $BUILD"; exit 1; }
    _rsites="$(echo $RELOC | tr ' ' '\n' | cut -d= -f1 | paste -sd, -)"
    echo "relocated leg: $BUILD, sites $_rsites (mapped to the vanilla sites: $RELOC)"
    pool=0
    for n in $names; do
        [ -f "tests/replays/$n.rpl" ] || continue
        run1 "$n" "$W/reloc" "$_sp" vsavjw "$BUILD/rompath;$ROMDIR" "$_rsites" "$_clk"   # the supervisor-read and drift-clock modes reach this leg too
        pool=$((pool + 1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
    done
    wait
else
    echo "FAIL: no build (verify_op.bin, rompath/vsavjw.zip) at $BUILD for the relocated leg"; exit 1
fi

# THE ONE-TIME ALIGNMENT (#228 step 4, option A): reference legs for every replay of both legs; each pristine one
# must reproduce the frozen basis, each breakpoint run must have covered its frames on emulated time with the game
# clock of its reference leg; only then are the reference legs' game clocks frozen. Every reference leg is held to
# a yardstick outside the instrument: the pristine leg's to the frozen basis, the relocated leg's to replay.lua run
# live on the build under the same mask (rule-checker run 2026-10-10-798 Q1).
if [ "${1:-}" = "--freeze-clock" ]; then
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
    pool=0
    for n in $names; do
        [ -f "tests/replays/$n.rpl" ] || continue
        run1 "$n" "$W/ref_runs" "" vsavj "$ROMDIR" "$SPSITES" "INSTR_REFERENCE=1"
        run1 "$n" "$W/ref_reloc" "" vsavjw "$BUILD/rompath;$ROMDIR" "$_rsites" "INSTR_REFERENCE=1"
        # the build has no basis: its reference leg is held to replay.lua run live, under the same mask (#213's method)
        ( ia_replaylua_run vsavjw "$BUILD/rompath;$ROMDIR" "$PWD/tests/replays/$n.rpl" "$W/rl_reloc/$n" "$MASK" ) </dev/null &
        pool=$((pool + 3)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
    done
    wait
    bad=0; : > "$W/clocks.tsv"
    for n in $names; do
        [ -f "tests/replays/$n.rpl" ] || continue
        for lg in vsavj:runs:ref_runs reloc:reloc:ref_reloc; do
            leg="${lg%%:*}"; rest="${lg#*:}"; bp="$W/${rest%%:*}/$n.align"; ref="$W/${rest#*:}/$n.align"
            [ -s "$ref" ] || { echo "  $leg/$n: the reference leg wrote no ALIGN line"; bad=1; continue; }
            a="$(ia_anchor "$ref")"; af="$(ia_anchor_frame "$ref")"
            if [ "$leg" = vsavj ]; then want="$(basis_at "$n" "$af")"; yard="the basis"
            else want="$(ia_replaylua_read "$W/rl_reloc/$n" "$af")"; yard="replay.lua live"; fi
            [ -n "$a" ] && [ "$a" = "$want" ] || { echo "  $leg/$n: the reference leg reads ${a:-nothing} at frame ${af:-?}, $yard ${want:-nothing}"; bad=1; }
            [ "$(ia_field "$bp" frames)" = "$(ia_field "$bp" emulated)" ] || { echo "  $leg/$n: the breakpoint run counted $(ia_field "$bp" frames) over $(ia_field "$bp" emulated) emulated"; bad=1; }
            [ "$(ia_field "$bp" gameclock)" = "$(ia_field "$ref" gameclock)" ] || { echo "  $leg/$n: the breakpoint run's game clock $(ia_field "$bp" gameclock), its reference leg's $(ia_field "$ref" gameclock)"; bad=1; }
            ia_row "$leg" "$n" "$ref" >> "$W/clocks.tsv"
        done
    done
    [ "$bad" = 0 ] || { echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/audit_walker_ghost.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD), BUILD $(basename "$BUILD")."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$W/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$W/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS (every pristine reference leg on the basis, every breakpoint run on its reference leg's clock)"
    exit 0
fi
fail=0
echo "== the instrument's alignment (#228)"
: > "$W/align_bad.txt"
for n in $names; do
    [ -f "tests/replays/$n.rpl" ] || continue
    ia_check "$CLOCKS" vsavj "$n" "$W/runs/$n.align" >> "$W/align_bad.txt" || true
    ia_check "$CLOCKS" reloc "$n" "$W/reloc/$n.align" >> "$W/align_bad.txt" || true
done
if [ -s "$W/align_bad.txt" ]; then echo "  FAIL  $(wc -l < "$W/align_bad.txt" | tr -d ' ') run(s) off their frozen alignment:"; head -8 "$W/align_bad.txt" | sed 's/^/        /'; fail=1
else echo "  ok    every run of both legs on emulated time, at its frozen game clock"; fi
sa="$(ia_anchor "$W/stage/21_don_mash.align")"; saf="$(ia_anchor_frame "$W/stage/21_don_mash.align")"
if [ -n "$sa" ] && [ "$sa" = "$(basis_at 21_don_mash "$saf")" ]; then echo "  ok    the staging reference leg reproduces the basis at frame $saf"
else echo "  FAIL  the staging reference leg reads ${sa:-nothing} at frame ${saf:-?}, the basis $(basis_at 21_don_mash "${saf:-0}")"; fail=1; fi

_flags=""
vs_ctl_is range-moved && _flags="--frozen-shift 2"
vs_ctl_is mask-covers && _flags="--extra-mask ff0550-ff06e0"
if [ "${1:-}" = "--freeze" ]; then
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED: --freeze in control mode"; exit 3; }
    python3 tools/walker_ghost.py "$W/runs" "$FROZEN" "$W/vj_op.bin" --freeze; exit $?
fi
python3 tools/walker_ghost.py "$W/runs" "$FROZEN" "$W/vj_op.bin" ${_flags} > "$W/read.txt" || fail=1
cat "$W/read.txt"
_map=""; for m in $RELOC; do _map="$_map --map $m"; done
echo
echo "== the relocated leg ($BUILD)"
python3 tools/walker_ghost.py "$W/reloc" "$FROZEN" "$BUILD/verify_op.bin" ${_flags} ${_map} > "$W/read_reloc.txt" || fail=1
cat "$W/read_reloc.txt"

echo
echo "== must-fire controls"
if [ -n "${VS_CTL:-}" ]; then
    if [ "$fail" = 1 ]; then vs_ctl_fired "$VS_CTL" "the gate's own read fails under the control"; echo "FAIL: audit_walker_ghost (control mode)"; exit 1
    else vs_ctl_dead "$VS_CTL" "the gate's own read still passed" || true; echo "FAIL: audit_walker_ghost"; exit 1; fi
fi
# supervisor-read: the instrument reading SP on 21_don_mash must fail the ground truth
if python3 tools/walker_ghost.py "$W/ctl_sp" "$FROZEN" "$W/vj_op.bin" --no-frozen > "$W/ctl_sp.txt"; then
    vs_ctl_dead supervisor-read "the SP read passed the ground truth" || fail=1
elif command grep -q "GROUND" "$W/ctl_sp.txt"; then
    vs_ctl_fired supervisor-read "the SP read fails the ground truth: $(command grep -m1 '^    ground truth' "$W/ctl_sp.txt" | cut -c19-110)"
else vs_ctl_dead supervisor-read "failed, but not on the ground truth" || fail=1; fi
# drift-clock: 21_don_mash under the frame_done clock must miss its frozen game clock
if ia_check "$CLOCKS" vsavj 21_don_mash "$W/ctl_drift/21_don_mash.align" > "$W/ctl_drift.txt"; then
    vs_ctl_dead drift-clock "the frame_done clock still met the frozen game clock" || fail=1
elif command grep -q "game clock\|emulated" "$W/ctl_drift.txt"; then vs_ctl_fired drift-clock "$(head -1 "$W/ctl_drift.txt")"
else vs_ctl_dead drift-clock "failed, but not on the clock: $(head -1 "$W/ctl_drift.txt")" || fail=1; fi
# first-frame-skip: the staging leg under the skip must miss the basis
ka="$(ia_anchor "$W/ctl_skip/21_don_mash.align")"; kaf="$(ia_anchor_frame "$W/ctl_skip/21_don_mash.align")"
if [ -z "$ka" ]; then vs_ctl_dead first-frame-skip "the skip leg wrote no anchor" || fail=1
elif [ "$ka" != "$(basis_at 21_don_mash "$kaf")" ]; then vs_ctl_fired first-frame-skip "under the first-frame skip the staging leg reads $ka at frame $kaf where the basis reads $(basis_at 21_don_mash "$kaf")"
else vs_ctl_dead first-frame-skip "the skipped clock still reproduced the basis" || fail=1; fi
for c in "range-moved:--frozen-shift 2:FROZEN" "mask-covers:--extra-mask ff0550-ff06e0:VISIBLE"; do
    n="${c%%:*}"; rest="${c#*:}"; fl="${rest%%:*}"; want="${rest##*:}"
    if python3 tools/walker_ghost.py "$W/runs" "$FROZEN" "$W/vj_op.bin" $fl > "$W/ctl_$n.txt"; then
        vs_ctl_dead "$n" "the perturbed read passed" || fail=1
    elif command grep -q "CHECK FAIL.*$want" "$W/ctl_$n.txt"; then
        vs_ctl_fired "$n" "$(command grep -m1 "CHECK FAIL.*$want" "$W/ctl_$n.txt" | cut -f2 | cut -c1-110)"
    else vs_ctl_dead "$n" "failed, but not on $want" || fail=1; fi
done
if [ "$fail" = 0 ]; then echo "PASS: audit_walker_ghost — the walkers' pushes land on the live stack outside every oracle mask, at the frozen ranges"
else echo "FAIL: audit_walker_ghost"; exit 1; fi
