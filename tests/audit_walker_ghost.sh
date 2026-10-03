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
# EXPECTS: the reader's PASS: every long on top of the read stack a genuine return address, the
#   push outside every mask, the live ranges as frozen; the three controls fail.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/ tests/lib/controls.sh
#   tests/lib/decrypt_cache.sh tests/lua/walker_sp.lua tests/replays/ tools/run_mame.sh
#   tools/setup_mame.sh tools/walker_ghost.py
#
# MUST-FIRE: known-bad: supervisor-read — the instrument forced to read MAME's SP (the idle supervisor stack, the pre-14z-185 read) must fail the ground-truth check: the longs on top of that stack end no call to the walker (in-gate: one extra run of 21_don_mash with WALKER_SP_READ=sp must fail GROUND; mode: every corpus run of BOTH legs reads SP and the gate FAILs on each) (GitHub #143, 14z-185)
# MUST-FIRE: perturbed-copy: range-moved — the frozen sp_min shifted by 2 must fail the frozen compare, so a moved live range is re-frozen deliberately (in-gate: the reader run with --frozen-shift 2 must fail FROZEN; mode: the gate's own read carries the shift and FAILs)
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
# COVERAGE. Site 0x54470 fires in only 5 of ~50 corpus replays (the long
# mash/arcade rigs) — the same thin base the dispatch census reports. That
# matters much less here than it does for a deadness claim: this measures
# where the stack IS, not that something never happens, and the stack depth
# at a fixed call site is a structural property of the call chain. Still,
# the per-site replay count is printed so the base is visible.
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=8] [BUILD=build/m3b_merged30] [--freeze] tests/audit_walker_ghost.sh
# ~1.5 min (two corpus-wide debug legs, JOBS-parallel; measured 14z-185 on this MacBook: 83 s).
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
BUILD="${BUILD:-build/m3b_merged30}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_da.bin" || { echo "FAIL: vsavj views not delivered"; exit 1; }

run1() {  # run1 <replay> <out dir> [sp] [set rompath sites]  — one walker_sp.lua run (background)
    _n="$1"; _o="$2"; _rpl="tests/replays/$_n.rpl"; mkdir -p "$_o"
    _set="${4:-vsavj}"; _rp="${5:-$ROMDIR}"; _sites="${6:-$SPSITES}"
    _lf=$(sed 's/#.*//' "$_rpl" | awk 'NF { split($1, r, "-"); f=(r[2]?r[2]:r[1]);
         if (f + 0 > m) m = f + 0 } END { print m + 0 }')
    ( MAME_SANDBOX="$_o/sb_$_n" REPLAY="$PWD/$_rpl" SPSITES="$_sites" SP_OUT="$_o/$_n.txt" \
      WALKER_SP_READ="${3:-}" FRAMES=$((_lf + 120)) MAME_ROMPATH="$_rp" \
      tools/run_mame.sh "$_set" -debug -debugger none \
      -autoboot_script "$PWD/tests/lua/walker_sp.lua" >"$_o/$_n.log" 2>&1; rm -rf "$_o/sb_$_n" ) </dev/null &
}
names="$(ls tests/expected/vsavj/masked-v2/logs/*.log | xargs -n1 basename | sed 's/\.log$//')"
echo "corpus: $(echo "$names" | wc -w | tr -d ' ') legacy replays (every replay with a vanilla basis log)"
_sp=""; vs_ctl_is supervisor-read && _sp=sp
pool=0
for n in $names; do
    [ -f "tests/replays/$n.rpl" ] || continue
    run1 "$n" "$W/runs" "$_sp"
    pool=$((pool + 1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done
run1 21_don_mash "$W/ctl_sp" sp      # the supervisor-read control's one run
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
        run1 "$n" "$W/reloc" "$_sp" vsavjw "$BUILD/rompath;$ROMDIR" "$_rsites"   # the supervisor-read mode forces SP here too
        pool=$((pool + 1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
    done
    wait
else
    echo "FAIL: no build (verify_op.bin, rompath/vsavjw.zip) at $BUILD for the relocated leg"; exit 1
fi

_flags=""
vs_ctl_is range-moved && _flags="--frozen-shift 2"
vs_ctl_is mask-covers && _flags="--extra-mask ff0550-ff06e0"
if [ "${1:-}" = "--freeze" ]; then
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED: --freeze in control mode"; exit 3; }
    python3 tools/walker_ghost.py "$W/runs" "$FROZEN" "$W/vj_op.bin" --freeze; exit $?
fi
fail=0
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
