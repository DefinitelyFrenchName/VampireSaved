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
# THE COSMO DISRUPTION CRASH IS THEREFORE OPEN AGAIN. A replacement must be
# built on the real mechanism, must be gated on the tenant id so legacy
# cannot reach it, must prove deadness on a replay that EXERCISES the
# neighbouring code, and must pass tests/run_suite.sh — not a tenant-scoped
# gate alone.
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

[ "$fail" -ne 0 ] && { echo "FAIL: pyron cosmo withdrawal guard"; exit 1; }
echo "PASS: pyron cosmo withdrawal guard (the bad word stays out;"
echo "      NOTE the Cosmo Disruption crash is OPEN — see the header)"
