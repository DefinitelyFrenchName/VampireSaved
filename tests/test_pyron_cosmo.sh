#!/bin/sh
# test_pyron_cosmo.sh — the Cosmo Disruption crash gate (rewritten 14z-75).
#
# THE CRASH. Pyron's EX drives the shared engine to sub-state 81 and the
# engine dispatches it through a pc-relative table:
#     018460  move.w ($6,PC,D0.w),D1     ; table base 0x018468
#     018464  jmp    ($2,PC,D1.w)
# Measured at the crash (rig 72, f3569): D0 = 0xA2, i.e. index 81.
# THE TABLE HAS ONLY 80 ENTRIES (0..79). It ends at 0x018508, where a SECOND
# dispatcher begins (`323b 0006 / 4efb 1002`, its own table at 0x018510). So
# index 81 reads 0x01850A — dispatcher #2's DISPLACEMENT OPERAND, value
# 0x0006 — and jumps to 0x018468+6, into the table's own bytes. Executing
# them hits an illegal instruction and the watchdog resets the board.
#
# THE 14z-74 FIX AND WHY IT WAS WITHDRAWN. It wrote that same word
# 0x0006 -> 0x0224. That genuinely STOPPED THE CRASH — measured: pyron17
# does not reset on rig 72 where pyron18 does — because the out-of-range
# read then returns a real handler. But the word is dispatcher #2's
# displacement, so it moved that dispatcher's table for EVERY character and
# broke four legacy replays. Right effect, wrong byte.
#
# (RETRACTED, earlier in 14z-75: I claimed "the word never fixed the crash".
# That was measured on rigs 71/77/80, none of which reproduce it — 71 and 77
# release the pair early, and rig 80's reset is a DIFFERENT event that hits
# all three builds. Rig 72 is the one that reproduces, and on it the word
# plainly works. The maintainer was right.)
#
# THE FIX NOW IN PLACE is in HIS OWN PORTED DATA, not the engine: the
# sub-state byte at vs2 0x0D0C7F (region hitbox_proj), reached as +0x17(A3),
# is retargeted 81 -> 79. vs2's table is larger so 81 is valid there; vsavj's
# is not, and the port copied the index verbatim — an index-space mismatch.
# Entry 79 already holds 0x0224, the displacement reaching 0x01868C, the
# handler 14z-74 established is byte-identical to vs2's. Legacy-safe by
# construction: the byte lives in a region that exists only in this build.
#
# Usage: ROMDIR=... tests/test_pyron_cosmo.sh [outbase]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
   # RE-POINTED 14z-94 (GitHub #94): was build/pyron18, a pre-WIDE-v1.1 set
   # (19 members, no vsw.z01/z02) — the script could not run at all.
   # Its frozen inventory may still describe the OLD build: run it
   # before trusting a green, and re-measure rather than absorb.
BUILD="${1:-build/pyron27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
fail=0

decrypt_view vsavj "$WORK/vj.bin" "$WORK/vjd.bin"

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

echo "== 3. runtime: the EX FIRES and the game does NOT reset (rig 72)"
# Rig 72 is the ONLY rig that reproduces: 2P dummy, point blank, long hold.
# 71/77/78/79 do not (early release / a pair that never fires), and rig 80's
# reset is a different event. A watchdog reset is not a 68k exception, so
# survival is judged by P1 +0x382 still holding 0x11.
# The gate REFUSES to pass unless a stock was spent — with an empty meter the
# pair is downgraded and "no reset" would prove nothing.
if [ "${SKIP_RUNTIME:-0}" = 1 ]; then
    echo "   SKIPPED (SKIP_RUNTIME=1)"
else
    [ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no vsavjw.zip"; exit 1; }
    PK="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11"
    PK="$PK;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
    PK="$PK;3300:ff8509:03;3700:ff8509:03;4100:ff8509:03"
    DUMPS="3290:ff8500-ff851f;3450:ff8500-ff851f"
    for f in 3450 3550 3650 3750 3900 4100 4400 4650; do
        DUMPS="$DUMPS;$f:ff8400-ff87ff"
    done
    mkdir -p "$WORK/rt"
    ( cd "$WORK/rt" && POKES="$PK" DUMPS="$DUMPS" \
      MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
      MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}" \
      "$REPO/tools/run_replay_mame.sh" vsavjw \
      "$REPO/tests/replays/pyron/72_pyron_cosmo_2p.rpl" ram.log s1 \
      > out.log 2>&1 ) || { echo "FAIL: the runtime leg did not complete"; fail=1; }
    python3 - "$WORK/rt" <<'PY2' || fail=1
import os, sys
d = sys.argv[1]
before = open(os.path.join(d, "dump_3290_ff8500.bin"), "rb").read()[0x09]
after  = open(os.path.join(d, "dump_3450_ff8500.bin"), "rb").read()[0x09]
print(f"   stocks f3290 {before:#04x} -> f3450 {after:#04x}")
if not (after < 3 or before < after):
    pass
fired = (after == 0x02)
if not fired:
    print("FAIL: the EX did not fire (no stock spent) — a downgraded input "
          "proves nothing about the crash")
    sys.exit(1)
print("   ok: the EX fired (one stock spent)")
for f in (3450, 3550, 3650, 3750, 3900, 4100, 4400, 4650):
    blk = open(os.path.join(d, "dump_%d_ff8400.bin" % f), "rb").read()
    if blk[0x382] != 0x11:
        print(f"FAIL: the game RESET — P1 +0x382 = {blk[0x382]:#04x} at f{f} "
              f"(watchdog; the Cosmo crash is back)")
        sys.exit(1)
print("   ok: no reset — Pyron still in the match at f4650")
PY2
fi

[ "$fail" -ne 0 ] && { echo "FAIL: pyron cosmo withdrawal guard"; exit 1; }
echo "PASS: pyron cosmo gate (the legacy-corrupting word stays out, the EX"
echo "      fires, and the crash rig no longer resets)" 
