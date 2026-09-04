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
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   Phase C step 2: image grows to 6MB, WIDE romset shaped+runs, extension
#   PROVABLY READ (negative control), stock build untouched
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# ABSOLUTE, and it is load-bearing (14z-132). Section 4 runs each leg from
# inside its own temp dir (`cd "$WORK/$leg"`) with
# MAME_ROMPATH="$WORK/wide/rompath;$ROMDIR", so a RELATIVE $ROMDIR — which is
# how the runners invoke every gate (`ROMDIR=../ROMS`) — resolves against the
# leg dir, finds no reference members, and the run produces NO DUMPS. The
# liveness check then reports "the clean leg held the victim on only 0
# frames", which reads as a defect in the artifact and is not one.
ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
# THE STOCK PIN IS RESOLVED FROM registry.tsv, NOT CARRIED AS A LITERAL
# (14z-130). It was `ae701ffb…` — the donovan-m2c stock twin, 14z-64 — and by
# the time it was read again the stock twin had MOVED FOUR TIMES, each move
# RULED and attributed in its own registry row: cf455760 (14z-110, the #99 fix
# is not profile-gated), d29fd062 (14z-110b, the remap), 38e9cb2c (14z-119,
# port_param32) and e86e1d04 (14z-130, the boot title). So section 1 had been
# asserting a constant with no expiry against a value the project deliberately
# moves ([VSP-95] for fingerprints). The invariant it is actually defending is
# not "byte-identical to donovan-m2c" but "the stock build is the REGISTERED
# stock twin, and any move of it went through the freeze ritual" — which is
# exactly what registry.tsv records. Resolving it here means the anchor is the
# REVIEWED row and not this build's own output ([VSP-166]); STOCK_FP= still
# overrides for a deliberate one-off.
_reg="$REPO/tests/expected/registry.tsv"
STOCK_FP="${STOCK_FP:-$(awk -F'\t' '$1 !~ /^#/ && $2 ~ /-stock$/ {fp=$1} END{print fp}' "$_reg")}"
[ -n "$STOCK_FP" ] || { echo "no *-stock row in $_reg — cannot resolve the stock twin"; exit 1; }
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
    echo "  FAIL: stock fingerprint $got != $STOCK_FP (the newest *-stock row"
    echo "        in tests/expected/registry.tsv) — either a pipeline change"
    echo "        leaked into the stock track, or the stock twin MOVED and the"
    echo "        freeze ritual has not registered it yet. Check which."; fail=1
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
# RE-TARGETED 14z-131 (maintainer-ruled: "if it works then we'll be able to
# update, otherwise we'll likely drop"). The old control zeroed 0x160 bytes at
# CPU:$400010 and required 12_donovan_vs_cpu's log to change. It had been DEAD
# since 14z-111: that address stopped holding the Phase-C sound table and now
# holds region x101aca, Donovan's AI SCRIPT BLOCK, which the replay cannot
# read because Donovan is the PLAYER there ([VSE-75]: 2P versus never reads
# them). A control that cannot fire is worse than no control.
#
# WHAT IT ZEROES NOW: the 32-WORD PER-VICTIM OFFSET HEAD of Donovan's
# capture-keyframe blob. The capture POSITIONER at PRG:0x02802E is vanilla
# engine code that does, every frame a victim is held:
#     d1 = attacker $382 ; a0 = [0x0BE27A + d1*4]      <- the attacker's blob
#     d1 = victim   $382 ; a0 = a0 + word[a0 + d1*2]   <- the per-victim head
#     victim $10/$14 = attacker $10/$14 +/- (dx,dy) from that entry
# so zeroing the head sends every victim to entry 0 and the victim SNAPS onto
# the attacker. Measured 14z-131 on build/m3b_merged22, P1 Donovan vs P2
# Victor on tests/replays/judge/02_throw.rpl: the hold runs 3010-3056 and the
# offsets collapse from NINE distinct values (including a 181px lift) to
# (0,0)/(56,0) — all 47 held frames differ, and nothing crashes.
#
# WHY THIS IS A LEGITIMATE ANCHOR ([VSP-166]). The blob's ADDRESS is read from
# the build's own table, but the ASSERTION is not: it is the victim position
# the GAME's vanilla positioner computes. If the build's pointer were wrong we
# would zero the wrong bytes and this control would FAIL LOUDLY, never pass
# vacuously — the opposite of the dead-probe trap. The gate asserts the
# pointer lands in the extension FIRST, so "the extension is read" is the
# thing actually under test.
CAP_RPL="tests/replays/judge/02_throw.rpl"
CAP_PK="1400:ff8782:13;1450:ff8782:13;1500:ff8782:13;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
CAP_DF="$(python3 -c "print(';'.join(f'{f}:ff8410-ff8418;{f}:ff8810-ff8818;{f}:ff8934-ff8935' for f in range(3005,3060)))")"
cap_ptr=$(python3 - "$WORK/wide/verify_data.bin" <<'PY'
import sys, struct
img = open(sys.argv[1], 'rb').read()
print("%d" % struct.unpack_from('>I', img, 0x0BE27A + 0x13 * 4)[0])
PY
)
if [ "$cap_ptr" -lt 4194304 ]; then
    echo "  FAIL: capture_kf_ptr[0x13] = $(printf '0x%06X' "$cap_ptr") is NOT in the"
    echo "        extension (CPU \$400000+), so this control cannot test whether"
    echo "        the extension is read. Re-scope it or drop it — do not widen."
    fail=1
else
  cp -r "$WORK/wide/rompath" "$WORK/neg"
  python3 - "$WORK/neg/vsavjw.zip" "$cap_ptr" <<'PY'
import sys, zipfile
p, ptr = sys.argv[1], int(sys.argv[2])
z = zipfile.ZipFile(p); infos = z.infolist()
data = {i.filename: z.read(i.filename) for i in infos}; z.close()
off = ptr - 0x400000                      # vsw.41 offset == CPU offset - 0x400000
b = bytearray(data["vsw.41"]); b[off:off + 0x40] = b"\x00" * 0x40
data["vsw.41"] = bytes(b)
o = zipfile.ZipFile(p, "w", zipfile.ZIP_DEFLATED)
for i in infos: o.writestr(i.filename, data[i.filename])
o.close()
PY
  for leg in capclean capzero; do
      mkdir -p "$WORK/$leg/sbx"
      if [ "$leg" = capclean ]; then _rp="$WORK/wide/rompath;$ROMDIR"; else _rp="$WORK/neg;$ROMDIR"; fi
      ( cd "$WORK/$leg" && REPLAY="$REPO/$CAP_RPL" POKES="$CAP_PK" DUMPS="$CAP_DF" \
        CHECKSUM_OUT="$WORK/$leg/out.log" MAME_SANDBOX="$WORK/$leg/sbx" \
        MAME_ROMPATH="$_rp" "$REPO/tools/run_mame.sh" vsavjw \
        -autoboot_script "$REPO/tests/lua/replay.lua" > "$WORK/$leg/mame.log" 2>&1 ) &
  done
  wait
  python3 - "$WORK" <<'PY' || fail=1
import glob, re, struct, sys
W = sys.argv[1]
def traj(leg):
    rows = []
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ff8810.bin"),
                    key=lambda p: int(re.search(r'dump_(\d+)_', p).group(1))):
        fr = int(re.search(r'dump_(\d+)_', f).group(1))
        cap = open(f"{W}/{leg}/dump_{fr}_ff8934.bin", 'rb').read()
        if not (cap and cap[0]):
            continue
        v = open(f, 'rb').read(); a = open(f"{W}/{leg}/dump_{fr}_ff8410.bin", 'rb').read()
        rows.append((fr,
                     struct.unpack_from('>h', v, 0)[0] - struct.unpack_from('>h', a, 0)[0],
                     struct.unpack_from('>h', v, 4)[0] - struct.unpack_from('>h', a, 4)[0]))
    return {f: (x, y) for f, x, y in rows}
c, z = traj("capclean"), traj("capzero")
# LIVENESS FIRST: a hold that never happened cannot prove anything.
if len(c) < 10:
    print(f"  FAIL: the clean leg held the victim on only {len(c)} frames — the"
          f"\n        rig did not produce a capture, so the control is void"
          f"\n        (not evidence the extension is unread).")
    sys.exit(1)
if len({v for v in c.values()}) < 2:
    print(f"  FAIL: the clean hold has only {len({v for v in c.values()})} distinct offset(s)"
          f" — nothing for\n        the control to collapse; re-scope the window.")
    sys.exit(1)
common = sorted(set(c) & set(z))
nd = sum(1 for f in common if c[f] != z[f])
if not common:
    print("  FAIL: the two legs share no held frame — cannot compare."); sys.exit(1)
if nd == 0:
    print("  FAIL: zeroing the capture-keyframe head changed NOTHING — the"
          "\n        extension is never read there, so placing data in it proves"
          "\n        nothing (the B4 trap).")
    sys.exit(1)
print(f"  ok: the hold collapses — {nd}/{len(common)} held frames move, "
      f"{len({v for v in c.values()})} distinct offsets -> "
      f"{len({v for v in z.values()})}; the 68k genuinely reads the blob at "
      f"CPU:$4010E0+")
PY
fi

echo
[ "$fail" = 0 ] || { echo "FAIL: Phase C image gate"; exit 1; }
echo "PASS: Phase C step 2 — the program image grows to 6MB, the WIDE romset"
echo "      is correctly shaped and runs, the extension is provably read, and"
echo "      the stock build is untouched."
