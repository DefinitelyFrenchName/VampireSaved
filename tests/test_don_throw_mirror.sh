#!/bin/sh
# test_don_throw_mirror.sh — the 14z-2 mirror-victim fix (applied 14z-64
# in the M3a re-freeze bundle): in a BASE-SLOT mirror match (both players
# on slot 0x0F = Donovan there), the thrown victim must use the
# DONOVAN-victim keyframe block, not Jedah's.
#
# MECHANISM. The throw victim-keyframe blob (data_port
# throw_victim_keyframes, dst 0x0B19F8) carries a victim-id offset table;
# entry [0x0F] at blob+0x1E held 0x0B30 (the Jedah-victim block) and the
# fix makes it 0x0D88 (the Donovan-victim block) — in the mirror flavor,
# victim id 0x0F IS Donovan. Byte-attributed: the candidate differs from
# the pre-fix frozen build by EXACTLY these two bytes (PRG:0x0B1A16).
#
#   1. STATIC — the built image holds 0x0D88 at blob+0x1E, with the
#      blob's head bytes intact (the right blob, the right word).
#   2. RUNTIME — replay 65 (both players pick slot 0x0F, P1 throws):
#      the victim keyframe walker reads the FIXED block (0xB2780+) and
#      never the old one (0xB2528+). Measured 206/0 on the candidate
#      and 0/206 on the pre-fix build — a matched control pair.
#
# BASE-SLOT track only (on variant-id builds the host block stays
# vanilla and the mirror flavor is tenant-vs-tenant at 0x13, correct by
# construction — the gate SKIPs on those builds).
#
# Usage: ROMDIR=... tests/test_don_throw_mirror.sh [outbase]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

OUTBASE="${1:-}"
if [ -z "$OUTBASE" ]; then
    OUTBASE="$WORK/build"
    echo "== 0. building the base-slot track (fresh) =="
    GEN_FLAGS="--allow-plausible --tripwire-open" \
        tools/build_donovan.sh 6 "$OUTBASE" > "$WORK/build.log" 2>&1 || {
        echo "FAIL: build did not complete"; tail -20 "$WORK/build.log"
        exit 1; }
    tail -2 "$WORK/build.log" | sed 's/^/  /'
fi
if [ -f "$OUTBASE/patch/tenant.json" ] && \
   python3 -c "import json,sys; sys.exit(0 if json.load(open('$OUTBASE/patch/tenant.json'))['id'] >= 0x10 else 1)"; then
    echo "SKIP: variant-id build — the mirror flavor is correct by construction there"
    exit 0
fi

echo "== 1. static: the fixed word in the built image =="
python3 - "$OUTBASE/prg" <<'PY' || { echo "FAIL: static"; exit 1; }
import sys, os
sys.path.insert(0, "tools")
import cps2_decrypt as cps
d = sys.argv[1]
names = sorted((n for n in os.listdir(d) if cps._PRG_RE.search(n)),
               key=lambda n: int(cps._PRG_RE.search(n).group(1)))
blob = b"".join(open(os.path.join(d, n), "rb").read() for n in names)
img = bytes(cps.words_to_logical_bytes(cps.words_from_file_bytes(blob)))
BLOB = 0x0B19F8
vs2 = open("build/out/vsav2_data.bin", "rb").read()
SRC = 0x0CA1CA
assert img[BLOB:BLOB + 4] == vs2[SRC:SRC + 4], \
    f"blob head {img[BLOB:BLOB+4].hex()} != vs2 src head — wrong blob"
assert vs2[SRC + 0x1E:SRC + 0x20].hex() == "0b30", \
    "vs2 source entry [0x0F] is not 0b30 — the fix premise moved"
w = img[BLOB + 0x1E:BLOB + 0x20].hex()
assert w == "0d88", f"victim entry [0x0F] = {w}, expected 0d88 (the fix)"
print("  ok: vs2 blob in place, entry [0x0F] fixed 0b30 -> 0d88")
PY

echo "== 2. runtime: the mirror throw walks the fixed block =="
if [ "${SKIP_RUNTIME:-0}" = 1 ]; then
    echo "  SKIPPED (SKIP_RUNTIME=1)"
else
    for w in b2780 b2528; do
        WATCH="$w,32,r" TRACE_OUT="$WORK/w_$w.txt" FRAMES=4400 \
        REPLAY="$REPO/tests/replays/65_don_mirror_throw.rpl" \
        MAME_SANDBOX="$WORK/sbx_$w" \
        MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
            tools/run_mame.sh vsavj -debug -debugger none \
            -autoboot_script tests/lua/trace_writes.lua \
            > /dev/null 2>&1 || true
    done
    NEW=$(($(grep -c '^frame' "$WORK/w_b2780.txt") - 1))
    OLD=$(($(grep -c '^frame' "$WORK/w_b2528.txt") - 1))
    if [ "$NEW" -ge 50 ] && [ "$OLD" -eq 0 ]; then
        echo "  ok: victim walker reads the FIXED block ($NEW reads), old block untouched"
    else
        echo "  FAIL: fixed-block reads=$NEW (want >=50), old-block reads=$OLD (want 0)"
        fail=1
    fi
fi

if [ "$fail" -ne 0 ]; then
    echo "FAIL: mirror-victim gate"
    exit 1
fi
echo "PASS: mirror-victim gate (the 2-byte fix, static + a matched"
echo "      runtime control on the mirror throw)"
