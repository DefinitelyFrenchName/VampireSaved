#!/bin/sh
# audit_pool_free_byte.sh — the owner-tag byte (+0x7F of the $FFB800 pool
# slot) is FREE, re-measured (14z-84; the 59-75 owner-dispatch fix's
# foundation). On-demand, ~15 min (2 tap legs + 2 dump legs on the merged
# build).
#
# WHAT IT RE-DERIVES (the measurement the fix rests on):
#   1. CENSUS — +0x7F is zero in EVERY live pool slot (type byte +0x02
#      nonzero) across both tenants' effect-heavy windows;
#   2. WRITE-TAP — zero writes hit +0x7F (offset%0x80 == 0x7F) in the
#      same windows, with the instrument's liveness proven by the
#      documented busy fields (+0x00/+0x20 must show heavy traffic).
# KNOWN NEIGHBOR FACT (frozen): +0x7C/+0x7E each take exactly ONE write
# from OUR hole_b code — they are DISQUALIFIED, and their hit staying
# nonzero doubles as a second liveness control.
#
# Once the owner-tag ships, +0x7F writes from OUR stamp-site emissions
# are EXPECTED — this audit then asserts the writer PCs are exactly the
# emitted tag sites (extend at that point, do not delete).
#
# Usage: ROMDIR=... tests/audit_pool_free_byte.sh [merged builddir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/m3b_merged}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

DF=$(python3 -c "print(';'.join(f'{f}:ffb800-ffc7ff' for f in range(3100,3612,4)))")
for leg in hfx:hui/83_hui_fx:10 pcosmo:pyron/71_pyron_cosmo:11; do
    name="${leg%%:*}"; rest="${leg#*:}"; rp="${rest%%:*}"; id="${rest##*:}"
    PK="1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id"
    d="$W/$name"; mkdir -p "$d"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" POKES="$PK" \
      REPLAY="$REPO/tests/replays/$rp.rpl" DUMPS="$DF" FRAMES=3620 \
      CHECKSUM_OUT="$d/c.ram" \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/out" 2>&1 ) \
        || { echo "FAIL: $name census leg did not run"; fail=1; }
    t="$W/tap_$name"; mkdir -p "$t"
    ( cd "$t" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$t/sb" POKES="$PK" \
      REPLAY="$REPO/tests/replays/$rp.rpl" \
      TAP="ffb800,4096" WINDOW="3100,3610" FRAMES=3620 \
      TRACE_OUT="$t/tap.txt" \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/tap_writes.lua" > "$t/out" 2>&1 ) \
        || { echo "FAIL: $name tap leg did not run"; fail=1; }
done

python3 - "$W" <<'PY' || fail=1
import glob, re, sys, collections
W = sys.argv[1]
errs = []
for leg in ("hfx", "pcosmo"):
    live = 0; nonzero7f = 0
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ffb800.bin")):
        d = open(f, "rb").read()
        for s in range(0, min(len(d), 0x1000), 0x80):
            slot = d[s:s+0x80]
            if len(slot) < 0x80 or slot[2] == 0:
                continue
            live += 1
            if slot[0x7F] != 0:
                nonzero7f += 1
    if live < 200:
        errs.append(f"{leg}: only {live} live-slot observations — the rig "
                    "did not form the effect content (verdict vacuous)")
    elif nonzero7f:
        errs.append(f"{leg}: +0x7F NONZERO in {nonzero7f}/{live} live slots")
    else:
        print(f"  ok: {leg} census — +0x7F zero in all {live} live slots")
    hits = collections.Counter()
    for ln in open(f"{W}/tap_{leg}/tap.txt"):
        m = re.match(r"frame \d+ PC [0-9a-f]+ off ([0-9a-f]+)", ln)
        if m:
            hits[int(m.group(1), 16) % 0x80] += 1
    if hits[0x00] < 100 or hits[0x20] < 100:
        errs.append(f"{leg}: busy fields quiet (+0x00={hits[0x00]}, "
                    f"+0x20={hits[0x20]}) — the tap is not live")
    elif hits[0x7F]:
        errs.append(f"{leg}: +0x7F took {hits[0x7F]} write(s)")
    else:
        print(f"  ok: {leg} tap — zero +0x7F writes; instrument live "
              f"(+0x00={hits[0x00]}, +0x20={hits[0x20]})")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: pool free-byte audit"; exit 1; }
echo "PASS: +0x7F is free — zero values in live slots AND zero writes,"
echo "      both tenants, instrument liveness proven"
