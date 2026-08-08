#!/bin/sh
# test_hui_df_style.sh — the DARK FORCE STYLE gate (14z-69): a direct
# ours-vs-NATIVE A/B of Huitzil in Dark Force, at the phase the symptom
# was reported at.
#
# WHY IT EXISTS. The playtest item is "in Dark Force H gets afterimages
# and a purple recolour; native applies neither". Two sessions chased it
# from our side alone (effect channels, the seq-0x0A handler, shadow
# servants — all ruled out) because "the native leg is unreachable" was
# on the record: 14z-68j found the early-window id poke did not force him
# on vsav2. That was replay 61, whose input timing is authored for OUR
# wheel. The replay-80 poke flow DOES reach him natively, and replay 85
# runs UNCHANGED on both games — which is what this gate is built on.
#
# AND WHY SECTION 0 IS THE POINT OF IT. The first version of this gate
# compared two matches in which DARK FORCE NEVER ACTIVATED, and reported
# the symptom as "does not reproduce". DF costs one banked stock; with an
# empty meter the P+K pair is downgraded to a single button (seq 0x0A —
# not DF) and play continues normally, so the screenshots looked like
# ordinary matches and every number agreed. The replay now pokes stocks
# in ($FF8509) and the checker REFUSES TO JUDGE unless both legs show
# the match-level DF flag $FF802E set and a stock actually spent. Every
# future DF measurement goes through that check. (Do not substitute a
# fighter-block byte for that flag: +0x1F4 and +0x1B5/+0x1B9 both look
# like DF and are set by JUMPING.)
#
# Sections:
#   1. THE A/B — replay 85 (control dash -> DF -> DF walk -> two DF air
#      dashes) on native vsav2 and on the build, compared by
#      tools/check_df_style.py.
#   2. VERDICT-LOGIC CONTROLS — the same checker against three synthetic
#      corruptions, each of which MUST fail: DF never activated (the
#      vacuous-pass shape that fooled the first version), the recolour
#      absent, and the afterimages absent.
#
# EXPECTATION. Default --expect colours-fixed (14z-69p): the RECOLOUR is
# fixed and the MODE is kept on purpose. Ours must no longer upload the
# purple ramp, must land on the warm sequence native's DF also shows
# (one animation step apart — rows of ONE ported block, vs2 0x3ABEDC),
# and must STILL draw the afterimages, because that mode is his real
# Vampire Savior Dark Force and the maintainer asked to keep it.
# DF_STYLE_EXPECT=differs replays the pre-fix state; =matches asserts
# full native equality, which is NOT the target here (the two games run
# different DF systems, so their palettes are one ramp step apart).
#
# Usage: ROMDIR=... [DF_STYLE_EXPECT=differs|matches] \
#            tests/test_hui_df_style.sh [wide-builddir]
#        (defaults to build/hui11; needs a build carrying H's real art)
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

BUILD="${1:-build/hui11}"
EXPECT="${DF_STYLE_EXPECT:-colours-fixed}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || {
    echo "FAIL: no $BUILD/rompath/vsavjw.zip (WIDE tenant build required)"; exit 1; }

MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
RPL="$REPO/tests/replays/hui/85_hui_df_vs2.rpl"
# P1 = Huitzil (native id 0x10 on both games), P2 = Victor (0x03 on both,
# or the cursor path picks different characters on the two wheels), and
# THREE BANKED STOCKS so the DF pair is not downgraded (docs/game/atlas/ram.md
# +0x109 — the documented ES-scripting poke).
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3120:ff8509:03"

CONTROL=3180
ANCHORS="3140 3180 3200 3270 3300 3400 3440 3480 3540 3560"
PALFR="$(python3 -c "print(' '.join(str(f) for f in list(range(3380,3481,2))+list(range(3520,3581,2))))")"
OBJFR="3180 3400 3440 3540 3560"

DUMPS="$(python3 -c "
a='$ANCHORS'.split(); p='$PALFR'.split()
print(';'.join(['%s:ff8400-ff87ff'%f for f in a]      # P1 fighter block
              + ['%s:ff8020-ff805f'%f for f in a]     # match state (802E = DF flag)
              + ['%s:90c140-90c15f'%f for f in p]))")"
OBJ_CSV="$(echo "$OBJFR" | tr ' ' ',')"

leg() {   # $1 tag  $2 set  $3 rompath-or-empty
    tag=$1; set_=$2; rp=$3
    d="$WORK/$tag"; mkdir -p "$d/s1" "$d/s2"
    if [ -n "$rp" ]; then MAME_ROMPATH="$rp;$ROMDIR"; export MAME_ROMPATH
    else unset MAME_ROMPATH || true; fi
    ( cd "$d" && POKES="$PK" DUMPS="$DUMPS" \
      "$REPO/tools/run_replay_mame.sh" "$set_" "$RPL" "$d/ram.log" "$d/s1" \
      > "$d/ram.out" 2>&1 ) || { tail -5 "$d/ram.out"; echo "FAIL: $tag replay leg"; exit 1; }
    ( cd "$d" && REPLAY="$RPL" POKES="$PK" DUMP_FRAMES="$OBJ_CSV" FRAMES=3700 \
      TRACE_OUT="$d/obj.txt" MAME_SANDBOX="$d/s2" \
      "$REPO/tools/run_mame.sh" "$set_" \
      -autoboot_script "$REPO/tests/lua/obj_records_dump.lua" \
      > "$d/obj.out" 2>&1 ) || { tail -5 "$d/obj.out"; echo "FAIL: $tag obj leg"; exit 1; }
}

echo "== native leg (vsav2)"
leg native vsav2 ""
echo "== build leg ($BUILD)"
leg ours vsavjw "$BUILD/rompath"

echo
echo "== 1. the A/B (expect: $EXPECT)"
python3 "$REPO/tools/check_df_style.py" "$WORK" \
    --anchors "$ANCHORS" --pal "$PALFR" --obj "$OBJFR" \
    --control "$CONTROL" --expect "$EXPECT" \
    || { echo "FAIL: the DF-style comparison did not match expectation '$EXPECT'"; exit 1; }

echo
echo "== 2. verdict-logic controls (each MUST fail)"
python3 - "$WORK" "$CONTROL" "$PALFR" <<'PYEOF'
import os, shutil, sys
work, control = sys.argv[1], int(sys.argv[2])
palfr = [int(x) for x in sys.argv[3].split()]
for tag in ("neg_nodf", "neg_nopal", "neg_noghost", "neg_purple"):
    d = os.path.join(work, tag)
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    os.symlink(os.path.join(work, "native"), os.path.join(d, "native"))
    shutil.copytree(os.path.join(work, "ours"), os.path.join(d, "ours"),
                    ignore=shutil.ignore_patterns("s1", "s2"))
o = lambda tag, n: os.path.join(work, tag, "ours", n)

# (a) THE SHAPE THAT FOOLED THE FIRST VERSION: Dark Force never active.
#     Clear the match-level DF flag and un-spend the stock on our leg.
import glob
for p in glob.glob(os.path.join(work, "neg_nodf", "ours", "dump_*_ff8020.bin")):
    b = bytearray(open(p, "rb").read())
    b[0x0e] = 0
    open(p, "wb").write(bytes(b))
for p in glob.glob(os.path.join(work, "neg_nodf", "ours", "dump_*_ff8400.bin")):
    b = bytearray(open(p, "rb").read())
    b[0x109] = 3
    open(p, "wb").write(bytes(b))

# (b) no recolour: copy native's palette rows over ours
for f in palfr:
    shutil.copyfile(os.path.join(work, "native", "dump_%d_90c140.bin" % f),
                    o("neg_nopal", "dump_%d_90c140.bin" % f))

# (c) no afterimages: keep only the FIRST 7 of our pal-0x0A draws per
#     frame (native draws 6-8), i.e. the body without its trailing copies
p = o("neg_noghost", "obj.txt")
kept, out = {}, []
for line in open(p):
    if " pal=0a" in line:
        f = line.split()[0]
        kept[f] = kept.get(f, 0) + 1
        if kept[f] > 7:
            continue
    out.append(line)
open(p, "w").writelines(out)
# (d) THE REGRESSION THIS FIX GUARDS AGAINST: the purple ramp is back.
#     This is the control that matters under --expect colours-fixed;
#     neg_nopal (ours == native) is only a corruption under "differs".
PURPLE = bytes.fromhex("f222ffffffbfffdffe9ffb5ff86ff67e"
                       "f76effbffa5ffe7ffc6ff95ff57df002")
for f in palfr:
    open(o("neg_purple", "dump_%d_90c140.bin" % f), "wb").write(PURPLE)
print("   built: neg_nodf (DF never active), neg_nopal (ours == native), "
      "neg_noghost (no afterimages), neg_purple (the purple ramp returns)")
PYEOF

# which synthetic states are CORRUPTIONS depends on the expectation:
# under "colours-fixed" ours matching native is fine, but the purple
# returning is the regression; under "differs" it is the other way round.
case "$EXPECT" in
    colours-fixed) NEGS="neg_nodf neg_purple neg_noghost" ;;
    *)             NEGS="neg_nodf neg_nopal neg_noghost" ;;
esac
ok=1
for neg in $NEGS; do
    if python3 "$REPO/tools/check_df_style.py" "$WORK/$neg" \
           --anchors "$ANCHORS" --pal "$PALFR" --obj "$OBJFR" \
           --control "$CONTROL" --expect "$EXPECT" --quiet \
           > "$WORK/$neg.out" 2>&1; then
        echo "   FAIL: checker PASSED the $neg corruption"; ok=0
    else
        echo "   ok: $neg rejected — $(grep -m1 '  - ' "$WORK/$neg.out" | cut -c5-95)"
    fi
done
[ "$ok" = 1 ] || { echo "FAIL: verdict logic does not detect what it claims to"; exit 1; }

echo
echo "PASS: the DF-style A/B is valid (both legs verifiably IN Dark Force)"
echo "      and its outcome matches expectation '$EXPECT'"
