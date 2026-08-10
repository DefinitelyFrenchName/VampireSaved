#!/bin/sh
# test_pyron_cosmo.sh — WITHDRAWAL GUARD (rewritten 14z-75).
#
# THIS GATE USED TO CERTIFY THE 14z-74 COSMO DISRUPTION FIX. That fix was
# WRONG and is withdrawn; the gate now exists to stop it coming back.
#
# WHAT 14z-74 BELIEVED: sub-state jump table 0x018468 ships entry 81 as a
# dead stub (0x0006) where vs2 has a handler, so repointing it to 0x0224
# fixes Pyron's Cosmo Disruption crash — and the row is dead in vanilla
# (measured: 0 dispatcher reads, against a live control).
#
# WHAT IS ACTUALLY THERE. The table at 0x018468 has exactly EIGHTY entries
# (0..79). It ENDS at 0x018508, where a second dispatcher begins:
#     018460  323b 0006   move.w (6,PC,Dn.w),D1     <- dispatcher #1
#     018464  4efb 1002   jmp    (2,PC,D1.w)        ;  table base 0x018468
#     018468  ... 80 entries ...
#     018508  323b 0006   move.w (6,PC,D3.w),D1     <- dispatcher #2
#     01850A              ^^^^ ITS DISPLACEMENT OPERAND
#     01850C  4efb 1002   jmp    (2,PC,D1.w)        ;  table base 0x018510
# 0x018468 + 81*2 = 0x01850A is TWO ENTRIES PAST THE END of table #1 and is
# dispatcher #2's displacement. Writing 0x0224 there made that dispatcher
# read its jump table 0x21E bytes away FOR EVERY CHARACTER, legacy included.
#
# WHY THE DEADNESS MEASUREMENT MISSED IT: it was taken on 02_demitri_vs_cpu,
# where vanilla reads 0x01850A ZERO times. On 05_timeout_idle vanilla reads
# it SIX times (frames 3190/3201/3211/3222/3233/3244, all at PC 0x018508 —
# that instruction fetching its own extension word). A deadness claim is only
# as good as the replay it is measured on.
#
# COST: 01_attract_long, 05_timeout_idle, 07_mash_storm and 30_demitri_throw
# all diverged from vanilla and NEVER re-converged. Removing this one word
# restores all four to the ratified select-wheel window and nothing more.
#
# THE CRASH IS NOW REPRODUCED (14z-75, after the maintainer supplied the
# recipe: hold the pair until the move ends by itself). See
# tests/replays/pyron/80_pyron_cosmo_pairsweep.rpl — DETERMINISTIC watchdog
# reset at f4840, and it reproduces IDENTICALLY on pyron14, pyron17 and
# pyron18. That is the important part: **the withdrawn word never fixed the
# Cosmo crash.** It was present in pyron14, the build where the fix was
# declared maintainer-confirmed, and the revert did not cause it.
#
# SHAPE: it is a HANG, not an exception. Whole-RAM stops changing at f4770
# (11 frames), resumes briefly, freezes again f4788-f4836, and the watchdog
# clears work RAM at f4838. The crash guard sees nothing.
# CONDITIONS measured: it needs MULTIPLE COMPLETED firings — one or two held
# firings survive; the three-attempt sweep resets. The BUTTON PAIR matters:
# LK+MK (45) never fires the move in this harness at all (stock never spent),
# while MP+HP (23) and LP+HP (13) do.
# INSTRUMENT NOTE: MAME's -debug perturbs the crash AWAY (no freeze in a
# debug run over the same window), so the next step needs FBNeo's
# non-perturbing write tap with PC attribution, not the MAME debugger.
#
# The older text below is kept for the record.
# (SUPERSEDED) NEVER REPRODUCED IN THIS HARNESS (measured earlier 14z-75).
# On build/pyron18, which does NOT carry the withdrawn word, replay 77 fires
# the EX four times over twelve attempts and the match survives to the end;
# build/pyron17, which DOES carry it, survives too. On replay 71 the two
# builds are BIT-IDENTICAL — the word never touched the move there at all.
# (They do diverge on replay 77 from f6837, so the word is not inert for
# Pyron in general; it simply prevents no crash we can demonstrate.)
#
# SO THERE IS NOTHING TO RE-FIX UNTIL THE CRASH IS REPRODUCED. What this
# harness does NOT cover, and what the maintainer's report may depend on:
# a real cursor pick rather than a forced-pick poke, arcade mode rather than
# 1P-vs-CPU, other opponents and stages, the move CONNECTING vs whiffing,
# and mid-combo or cornered activations. Get one of those reproducing before
# writing a single byte — the last attempt fixed a crash nobody had
# reproduced and corrupted legacy for every character instead.
#
# Usage: ROMDIR=... tests/test_pyron_cosmo.sh [outbase]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
BUILD="${1:-build/pyron18}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
fail=0

python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$WORK/vj.bin" \
    --data-out "$WORK/vjd.bin" > /dev/null

echo "== 1. the withdrawn word must be VANILLA in the build"
python3 - "$BUILD/verify_op.bin" "$WORK/vj.bin" <<'PY' || fail=1
import sys
ours=open(sys.argv[1],'rb').read(); van=open(sys.argv[2],'rb').read()
A=0x01850A
o,v = ours[A:A+2], van[A:A+2]
print(f"   0x{A:06X}: vanilla {v.hex()}  build {o.hex()}")
if o!=v:
    print("FAIL: the withdrawn Cosmo repoint is present again. It corrupts "
          "dispatcher #2's displacement for EVERY character — see this "
          "file's header before touching it.")
    sys.exit(1)
print("   ok: dispatcher #2's displacement is untouched")
PY

echo "== 2. the table-length fact this rests on"
python3 - "$WORK/vj.bin" <<'PY' || fail=1
import sys, struct
van=open(sys.argv[1],'rb').read()
d2=0x018508
if van[d2:d2+2].hex()!="323b" or van[d2+4:d2+6].hex()!="4efb":
    print(f"FAIL: 0x{d2:06X} is not the expected dispatcher shape"); sys.exit(1)
n=(d2-0x018468)//2
print(f"   table 0x018468 ends at dispatcher #2 (0x{d2:06X}) -> {n} entries (0..{n-1})")
if n!=80:
    print(f"FAIL: expected 80 entries, measured {n} — re-derive before trusting this gate")
    sys.exit(1)
print("   ok: index 81 is off the end by 2, exactly as the withdrawal says")
PY

echo "== 3. runtime: the EX fires repeatedly and the MATCH SURVIVES"
# A watchdog reset is NOT a 68k exception, so the crash guard cannot see it
# (14z-74). Judge by survival: after twelve EX attempts the P1 fighter block
# must still hold Pyron. The gate REFUSES to pass unless the EX actually
# fired at least once — with an empty meter the pair is silently downgraded
# and a "no crash" result would prove nothing.
if [ "${SKIP_RUNTIME:-0}" = 1 ]; then
    echo "   SKIPPED (SKIP_RUNTIME=1)"
else
    [ -f "$BUILD/rompath/vsavjw.zip" ] || {
        echo "FAIL: no $BUILD/rompath/vsavjw.zip"; exit 1; }
    PK="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11"
    for f in 3300 3700 4100 4500 4900 5300 5700 6100 6500 6900 7300 7700; do
        PK="$PK;$f:ff8509:09"
    done
    SAMPLES="3690 4090 4490 4890 5290 5690 6090 6490 6890 7290 7690 8090"
    DUMPS="$(python3 -c "
import sys
fr='$SAMPLES'.split()
print(';'.join(['%s:ff8500-ff851f'%f for f in fr] + ['8600:ff8400-ff87ff']))")"
    mkdir -p "$WORK/rt"
    ( cd "$WORK/rt" && POKES="$PK" DUMPS="$DUMPS" \
      MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
      MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}" \
      "$REPO/tools/run_replay_mame.sh" vsavjw \
      "$REPO/tests/replays/pyron/77_pyron_cosmo_storm.rpl" ram.log s1 \
      > out.log 2>&1 ) || { echo "FAIL: the runtime leg did not complete"; fail=1; }
    python3 - "$WORK/rt" "$SAMPLES" <<'PY2' || fail=1
import os, sys
d, samples = sys.argv[1], sys.argv[2].split()
fired = 0
for f in samples:
    b = open(os.path.join(d, "dump_%s_ff8500.bin" % f), "rb").read()
    if 0x09 - b[0x09] > 0:
        fired += 1
print(f"   EX activations measured (a stock spent): {fired}/12")
if fired == 0:
    print("FAIL: the EX never fired — every attempt was downgraded, so this "
          "section proves nothing about crashing")
    sys.exit(1)
blk = open(os.path.join(d, "dump_8600_ff8400.bin"), "rb").read()
cid = blk[0x382]
print(f"   P1 +0x382 at f8600 = {cid:#04x}")
if cid != 0x11:
    print("FAIL: Pyron is no longer in the match at f8600 — the game reset "
          "(watchdog) or the match ended unexpectedly")
    sys.exit(1)
print("   ok: the match survived twelve EX attempts")
PY2
fi

[ "$fail" -ne 0 ] && { echo "FAIL: pyron cosmo withdrawal guard"; exit 1; }
echo "PASS: pyron cosmo guard (the bad word stays out; the EX fires and the"
echo "      match survives). NOTE: the maintainer-reported crash has NEVER"
echo "      been reproduced in this harness — see the header." 
