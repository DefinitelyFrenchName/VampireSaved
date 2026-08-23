#!/bin/sh
# test_mister_wide_inert.sh — THE FPGA SUPERSET INVARIANT, MEASURED DIRECTLY.
# 14z-107 (6), slice D1.
#
# WHAT IT ASSERTS. The reference core `cps2` and the CPS-2 WIDE core `cps2w`,
# running the SAME stock `vsavj` download under Verilator, must produce
# BIT-IDENTICAL 68k work RAM at every frame of a window. Not "agree on mapped
# fields", not "land in a band" — byte-for-byte equal, which is what
# CLAUDE.md rule 1 v2's "stock vsavj is untouched BY CONSTRUCTION" actually
# claims once the profile bit is clear.
#
# WHY IT EXISTS, AND WHY IT IS NOT test_mister_sim_anchor. The anchor gate
# compares our core against MAME at a match-start anchor 2,500 frames into a
# 1P ARCADE replay, and everything on that path — the attract demo, the
# select screen, the CPU opponent draw — is downstream of state this project
# has already recorded as run-to-run and implementation-dependent
# (`docs/game/atlas/ram.md:99`, sound-state-fed). That makes it a fine
# cross-IMPLEMENTATION oracle and a poor inertness instrument. This gate
# compares the two cores against EACH OTHER on the same simulator, where
# "identical" is the only acceptable answer and one differing byte is the
# whole report.
#
# CONTROL (a comparison that cannot fail proves nothing): the same cps2 dumps
# are re-compared against themselves SHIFTED BY ONE FRAME. That must FAIL —
# it is the proof that this comparison would catch a one-frame timing skew,
# which is the smallest divergence the D1 change could plausibly cause.
# Plus: the window must be NON-CONSTANT, or a dead run would compare equal.
#
# COMPLETENESS is asserted by the PRODUCER (14z-107 (7)):
# tools/run_sim_jtcps2.sh runs tools/check_wram_dumps.py on every --wram run
# and refuses to return a dump set with a hole, a short file or a stray
# frame. That matters here because the loop below walks the cps2 side and a
# dump missing from THAT side would silently shrink the comparison rather
# than fail it. Both legs also run with host frame output OFF (the default),
# so nothing either core puts on screen can reach the measurement.
#
# COST: two Verilator runs of the same length, each paying the 462-frame ROM
# download. The default window is early boot (~11 min per core on Apple
# Silicon); WINDOW_LAST further out costs ~1 s per extra frame per core.
# EMULATOR tier — not in ci_portable/ci_static.
#
# Usage: ROMDIR=... [JTSIM_SCRATCH=...] [WINDOW_FIRST=540 WINDOW_LAST=640]
#        tests/test_mister_wide_inert.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }

[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset (this gate runs the real romset)"; exit 77; }
command -v verilator >/dev/null 2>&1 || { echo "SKIP: verilator not installed"; exit 77; }
[ -f "$REPO/emu/jtcores/.gitmodules" ] || { echo "SKIP: emu/jtcores not initialised"; exit 77; }

RPL="${INERT_RPL:-$REPO/tests/replays/05_timeout_idle.rpl}"
FIRST="${WINDOW_FIRST:-540}"
LAST="${WINDOW_LAST:-640}"
FRAMES=$((LAST + 1))

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
for core in cps2 cps2w; do
    echo "== $core, stock vsavj, frames $FIRST-$LAST =="
    "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$W/$core" --core "$core" \
        --frames "$FRAMES" --wram "$FIRST" "$LAST" \
        || { echo "FAIL: the $core leg did not complete"; exit 1; }
done

n=0; same=0; diff=0
for f in "$W/cps2/wram/"*.bin; do
    b="$W/cps2w/wram/$(basename "$f")"
    n=$((n + 1))
    if [ -f "$b" ] && cmp -s "$f" "$b"; then
        same=$((same + 1))
    else
        diff=$((diff + 1))
        [ "$diff" -le 5 ] && echo "      DIFFERS: $(basename "$f")"
    fi
done
[ "$n" -gt 0 ] || { echo "FAIL: the cps2 leg produced no dumps"; exit 1; }

# non-constancy first: an all-identical window would compare equal while
# proving nothing (the 14z-107 near-miss, same lesson as the anchor gate).
if [ "$(cd "$W/cps2/wram" && shasum ./*.bin | cut -c1-40 | sort -u | wc -l | tr -d ' ')" -gt 1 ]
then ok "the window is NON-CONSTANT ($n frames; the instrument is live)"
else bad "the window is CONSTANT — the 68k wrote no RAM, so 'identical' means nothing"; fi

[ "$diff" = 0 ] && ok "cps2w == cps2, BIT-IDENTICAL work RAM in all $same frames" \
                || bad "cps2w differs from cps2 in $diff of $n frames — the D1 profile is NOT inert"

echo "== control: the same dumps shifted by ONE FRAME must FAIL =="
shifted=0
for f in "$W/cps2/wram/"*.bin; do
    fr="$(basename "$f" | sed 's/dump_\([0-9]*\)_.*/\1/')"
    nxt="$W/cps2/wram/$(basename "$f" | sed "s/dump_${fr}_/dump_$((fr + 1))_/")"
    [ -f "$nxt" ] || continue
    cmp -s "$f" "$nxt" || shifted=$((shifted + 1))
done
[ "$shifted" -gt 0 ] && ok "control fired: a one-frame shift differs in $shifted comparisons, so this gate WOULD see a one-frame skew" \
                     || bad "CONTROL DID NOT FIRE: consecutive frames are all identical, so equality here is vacuous"

[ $fail = 0 ] && echo "PASS test_mister_wide_inert" \
              || { echo "FAIL test_mister_wide_inert"; exit 1; }
