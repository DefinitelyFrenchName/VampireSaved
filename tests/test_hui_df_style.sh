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
# Sections:
#   1. THE A/B — replay 85 (control dash -> DF -> two DF air dashes -> DF
#      walk) on native vsav2 and on the build, compared by
#      tools/check_df_style.py: rig non-vacuity (right character, DF
#      actually latched, dash actually engaged), palette row 0x0A
#      frame-exact, and the fighter's own pal-0x0A draws equal to native's
#      within the measured +/-2 frame skew.
#   2. VERDICT-LOGIC CONTROLS — the same checker run against three
#      synthetic corruptions of the build leg, each of which MUST fail:
#      a one-frame palette recolour, an afterimage (a duplicated draw of
#      his own art), and a de-latched Dark Force. A gate that only ever
#      passes is not evidence; these make the PASS mean something.
#
# STATUS AT AUTHORING (14z-69): section 1 PASSES — the symptom does NOT
# reproduce headlessly on hui11, on either emulator, forced-pick or
# hand-pick. Kept as the A/B of record, so that when the maintainer's
# repro conditions are known the first question ("does our DF differ from
# native's at all, and where?") is already instrumented.
#
# Usage: ROMDIR=... tests/test_hui_df_style.sh [wide-builddir]
#        (defaults to build/hui11; needs a build carrying H's real art)
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

BUILD="${1:-build/hui11}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || {
    echo "FAIL: no $BUILD/rompath/vsavjw.zip (WIDE tenant build required)"; exit 1; }

MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
RPL="$REPO/tests/replays/hui/85_hui_df_vs2.rpl"
# both sides poked, so the two legs differ only in the GAME: P1 = Huitzil
# (native id 0x10 on both), P2 = Victor (id 0x03 on both — without this the
# cursor path lands on different characters on the two wheels).
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"

CONTROL=3190
ANCHORS="3190 3200 3330 3350 3370 3480 3500 3600"
PALFR="$(python3 -c "print(' '.join(str(f) for f in list(range(3320,3391,2))+list(range(3450,3521,2))+list(range(3560,3651,2))))")"
OBJFR="3190 3350 3480"

DUMPS="$(python3 -c "
a='$ANCHORS'.split(); p='$PALFR'.split()
print(';'.join(['%s:ff8400-ff87ff'%f for f in a] + ['%s:90c140-90c15f'%f for f in p]))")"
OBJ_CSV="$(echo "$OBJFR" | tr ' ' ',')"

leg() {   # $1 tag  $2 set  $3 rompath-or-empty
    tag=$1; set_=$2; rp=$3
    d="$WORK/$tag"; mkdir -p "$d/s1" "$d/s2"
    if [ -n "$rp" ]; then MAME_ROMPATH="$rp;$ROMDIR"; export MAME_ROMPATH
    else unset MAME_ROMPATH || true; fi
    ( cd "$d" && POKES="$PK" DUMPS="$DUMPS" \
      "$REPO/tools/run_replay_mame.sh" "$set_" "$RPL" "$d/ram.log" "$d/s1" \
      > "$d/ram.out" 2>&1 ) || { tail -5 "$d/ram.out"; echo "FAIL: $tag replay leg"; exit 1; }
    ( cd "$d" && REPLAY="$RPL" POKES="$PK" DUMP_FRAMES="$OBJ_CSV" FRAMES=3610 \
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
echo "== 1. the A/B"
python3 "$REPO/tools/check_df_style.py" "$WORK" \
    --anchors "$ANCHORS" --pal "$PALFR" --obj "$OBJFR" --control "$CONTROL" \
    || { echo "FAIL: Dark Force presentation differs from native"; exit 1; }

echo
echo "== 2. verdict-logic controls (each MUST fail)"
python3 - "$WORK" "$CONTROL" <<'PYEOF'
import os, shutil, sys
work, control = sys.argv[1], int(sys.argv[2])
for tag in ("neg_pal", "neg_ghost", "neg_df"):
    d = os.path.join(work, tag)
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    os.symlink(os.path.join(work, "native"), os.path.join(d, "native"))
    shutil.copytree(os.path.join(work, "ours"), os.path.join(d, "ours"),
                    ignore=shutil.ignore_patterns("s1", "s2"))
o = lambda tag, n: os.path.join(work, tag, "ours", n)

# (a) a one-frame recolour of the fighter's palette row
p = o("neg_pal", "dump_3350_90c140.bin")
b = bytearray(open(p, "rb").read())
b[0:2] = b"\x0f\x0f"                     # one colour word moved
open(p, "wb").write(bytes(b))

# (b) an afterimage: one extra draw of his own art at a trailing position
p = o("neg_ghost", "obj.txt")
lines = open(p).read().splitlines(True)
ghost = next(l for l in lines if l.startswith("F3350 ") and "pal=0a" in l
             and "code=39d6" in l)
lines.insert(lines.index(ghost) + 1, ghost)
open(p, "w").writelines(lines)

# (c) Dark Force never latched (the vacuous-pass shape)
for f in (3330, 3350, 3370, 3480, 3500, 3600):
    p = o("neg_df", "dump_%d_ff8400.bin" % f)
    b = bytearray(open(p, "rb").read())
    b[0x1b5] = b[0x1b9] = 0
    open(p, "wb").write(bytes(b))
print("   built: neg_pal (recolour), neg_ghost (afterimage), neg_df (no DF)")
PYEOF

ok=1
for neg in neg_pal neg_ghost neg_df; do
    if python3 "$REPO/tools/check_df_style.py" "$WORK/$neg" \
           --anchors "$ANCHORS" --pal "$PALFR" --obj "$OBJFR" \
           --control "$CONTROL" --quiet > "$WORK/$neg.out" 2>&1; then
        echo "   FAIL: checker PASSED the $neg corruption"; ok=0
    else
        echo "   ok: $neg rejected — $(grep -m1 '  - ' "$WORK/$neg.out" | cut -c5-90)"
    fi
done
[ "$ok" = 1 ] || { echo "FAIL: verdict logic does not detect the symptom it claims to"; exit 1; }

echo
echo "PASS: Huitzil Dark Force presentation matches native vsav2, and the"
echo "      checker demonstrably rejects a recolour, an afterimage and a"
echo "      match that never entered Dark Force"
