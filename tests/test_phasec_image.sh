#!/bin/sh
# test_phasec_image.sh — Phase C step 2: the program image grows, and the
# extension is genuinely READ.
#
# The dual-track decision (14z-59g) says WIDE is the roster build while the
# stock build stays byte-identical. This gate holds both halves at once:
#
#   1. STOCK build unchanged — the pipeline gained image-growth, set-aware
#      packing and merging, all of which are shared code paths. If any of it
#      leaks into a stock build, the frozen donovan-m2c world moves.
#   2. WIDE build produces a correctly SHAPED romset — four appended 512KB
#      members, because the emulator descriptors declare a fixed geometry and
#      a set carrying fewer members simply fails to load. Image shape follows
#      the PROFILE, never the content.
#   3. It RUNS on the vsavjw driver, full replay, clean END.
#   4. NEGATIVE CONTROL — zero the 0x160-byte sound table at CPU $400010 and
#      behaviour MUST change. This is the B4 lesson made permanent: a
#      relocation that "passes" without a control proves nothing, because the
#      data may simply never be read. Frame 3121 on 12_donovan_vs_cpu when
#      this was first established.
#
# Usage: ROMDIR=... tests/test_phasec_image.sh
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
STOCK_FP="${STOCK_FP:-ae701ffb06d0cbf3462cad1a9faa47534a3c00e4}"
WIDE_SET="${WIDE_ROMSET:-build/wide0/rompath/vsavjw.zip}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

[ -f "$WIDE_SET" ] || { echo "no WIDE romset at $WIDE_SET (tools/build_wide_romset.py)"; exit 1; }

echo "== 1. STOCK build must stay byte-identical =="
GEN_FLAGS="--allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 "$WORK/stock" > "$WORK/stock.log" 2>&1 || {
        echo "  FAIL: stock build errored"; tail -10 "$WORK/stock.log"; exit 1; }
got=$(sed -n 's/.*build fingerprint: \([0-9a-f]\{40\}\).*/\1/p' "$WORK/stock.log" | head -1)
if [ "$got" = "$STOCK_FP" ]; then
    echo "  ok: $got"
else
    echo "  FAIL: stock fingerprint $got != $STOCK_FP — pipeline change leaked"; fail=1
fi
[ -f "$WORK/stock/rompath/vsavj.zip" ] && echo "  ok: packed as vsavj (stock set)" || {
    echo "  FAIL: stock build did not pack vsavj.zip"; fail=1; }

echo "== 2. WIDE build: shape follows the profile =="
KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
    tools/build_donovan.sh 6 "$WORK/wide" > "$WORK/wide.log" 2>&1 || {
        echo "  FAIL: WIDE build errored"; tail -10 "$WORK/wide.log"; exit 1; }
grep -E "^stage 6:" "$WORK/wide.log" | sed 's/^/  /'
python3 - "$WORK/wide/rompath/vsavjw.zip" <<'PY' || fail=1
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
ext = sorted(n for n in z.namelist() if n.startswith("vsw.4"))
want = ["vsw.41", "vsw.42", "vsw.43", "vsw.44"]
if ext != want:
    print(f"  FAIL: extension members {ext}, expected {want}"); sys.exit(1)
bad = [n for n in ext if z.getinfo(n).file_size != 0x80000]
if bad:
    print(f"  FAIL: wrong member size: {bad}"); sys.exit(1)
print(f"  ok: {len(ext)} x 0x80000 extension members, and the gfx/QSound "
      f"members merged ({len([n for n in z.namelist() if n.endswith('m')])} total)")
PY

echo "== 3. it RUNS on the vsavjw driver =="
if FBNEO_ROMPATH="$WORK/wide/rompath" \
        tools/run_replay_fbneo.sh vsavjw tests/replays/12_donovan_vs_cpu.rpl \
        "$WORK/real.log" "$WORK/s1" >/dev/null 2>&1 \
   && grep -q "^END " "$WORK/real.log"; then
    echo "  ok: full replay, clean END ($(grep -c '^[0-9]' "$WORK/real.log") frames)"
else
    echo "  FAIL: the WIDE build does not run"; fail=1
fi

echo "== 4. NEGATIVE CONTROL: the extension must actually be READ =="
cp -r "$WORK/wide/rompath" "$WORK/neg"
python3 - "$WORK/neg/vsavjw.zip" <<'PY'
import sys, zipfile
p = sys.argv[1]
z = zipfile.ZipFile(p); names = z.namelist(); data = {n: z.read(n) for n in names}; z.close()
b = bytearray(data["vsw.41"]); b[0x10:0x10+0x160] = b"\x00" * 0x160
data["vsw.41"] = bytes(b)
o = zipfile.ZipFile(p, "w", zipfile.ZIP_DEFLATED)
for n in names: o.writestr(n, data[n])
o.close()
PY
FBNEO_ROMPATH="$WORK/neg" tools/run_replay_fbneo.sh vsavjw \
    tests/replays/12_donovan_vs_cpu.rpl "$WORK/zero.log" "$WORK/s2" >/dev/null 2>&1 || true
if [ ! -s "$WORK/zero.log" ]; then
    echo "  FAIL: control run produced no log"; fail=1
elif cmp -s "$WORK/real.log" "$WORK/zero.log"; then
    echo "  FAIL: zeroing the table changed NOTHING — it is never read, so"
    echo "        placing it in the extension proves nothing (the B4 trap)."
    fail=1
else
    fr=$(diff "$WORK/real.log" "$WORK/zero.log" | awk '/^< [0-9]/{print $2; exit}')
    echo "  ok: diverges at frame $fr — the 68k genuinely reads CPU \$400010"
fi

echo
[ "$fail" = 0 ] || { echo "FAIL: Phase C image gate"; exit 1; }
echo "PASS: Phase C step 2 — the program image grows to 6MB, the WIDE romset"
echo "      is correctly shaped and runs, the extension is provably read, and"
echo "      the stock build is untouched."
