#!/bin/sh
# trap_air_sheet.sh — THE PLASMA TRAP DOME AND AN AIRBORNE VICTIM, native vs2 beside Vampire Saved, as
# pictures (14z-182, GitHub #175). An INSTRUMENT, not a gate: the verdicts are the probe's numbers.
#
# One row per frame of FRAMES: native (grey border) | ours (green border), labelled with each leg's
# victim y, animation node, HP and reaction class from tools/trap_air_probe.sh's own trace of the
# SAME run configuration. Same-frame pictures are comparable here BECAUSE both legs are pinned (level
# 6, RNG 0000) and the probe's field diff reads them frame-identical; without that they would not be
# (tools/capture_sheet.sh's keyframe matching, [VSE-84]).
#
# Usage: ROMDIR=... [PRESS=3508] [FRAMES=3519,3520,3521,3522,3524] tools/trap_air_sheet.sh [out.png]
#   the Felicia rig: real picks (P1 Phobos, P2 Felicia 0x07), Felicia pinned at x 695 and Phobos at
#   x 540 over 3470-3489, a neutral jump at 3490, j.HP (button 3) at PRESS.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
PRESS="${PRESS:-3508}"; FRAMES="${FRAMES:-3519,3520,3521,3522,3524}"
OUT="${1:-$REPO/build/trap_air_sheet_$PRESS.png}"
W="$REPO/build/trap_air_sheet_$PRESS"; rm -rf "$W"; mkdir -p "$W"
FIRST="${FRAMES%%,*}"; LAST="${FRAMES##*,}"
for leg in native merged; do
    LEG=$leg PICK=real P2CELL=07 XPIN="695@3470-3489" P1XPIN="540@3470-3489" ATK="$PRESS-$((PRESS + 2)) p2=3" \
        FROM="$FIRST" TO="$LAST" SNAP="$FRAMES" sh tools/trap_air_probe.sh "$W/$leg" > "$W/$leg.out" 2>&1 &
done
wait
for leg in native merged; do [ -s "$W/$leg/snap/0000.png" ] || { echo "FAIL: $leg leg has no snapshots ($W/$leg.out)"; exit 1; }; done
command -v magick >/dev/null || { echo "FAIL: no imagemagick"; exit 1; }
FONT="${CAPTURE_FONT:-/System/Library/Fonts/Supplemental/Andale Mono.ttf}"
i=0; rows=""
for f in $(echo "$FRAMES" | tr ',' ' '); do
    n=$(printf '%04d' "$i")
    ln=$(grep "^f$f " "$W/native/boxes.txt" | sed -E 's/.* y=([0-9]+) (AIR|gnd) .* cls=([^ ]+) hp=([0-9]+) .*node=(.*)/y=\1 \2 cls=\3 hp=\4 \5/')
    lo=$(grep "^f$f " "$W/merged/boxes.txt" | sed -E 's/.* y=([0-9]+) (AIR|gnd) .* cls=([^ ]+) hp=([0-9]+) .*node=(.*)/y=\1 \2 cls=\3 hp=\4 \5/')
    magick "$W/native/snap/$n.png" -bordercolor '#8a8a8a' -border 3 "$W/n$i.png"
    magick "$W/merged/snap/$n.png" -bordercolor '#3aa05a' -border 3 "$W/o$i.png"
    magick montage -label '' -font "$FONT" "$W/n$i.png" "$W/o$i.png" -tile 2x1 -geometry +5+5 -background '#101010' "$W/r$i.png"
    magick "$W/r$i.png" -background '#101010' -fill '#e8e8e8' -font "$FONT" -pointsize 14 \
        label:"f$f   NATIVE vs2: $ln     |     VAMPIRE SAVED: $lo" -gravity center -append "$W/rl$i.png"
    rows="$rows $W/rl$i.png"; i=$((i + 1))
done
# shellcheck disable=SC2086
magick montage -label '' -font "$FONT" $rows -tile 1x -geometry +10+6 -background '#101010' "$W/body.png"
magick -background '#101010' -fill '#ffffff' -font "$FONT" -pointsize 20 \
    label:"PLASMA TRAP vs AN AIRBORNE FELICIA - j.HP pressed at $PRESS   (left: native vs2, grey | right: Vampire Saved, green)" \
    -bordercolor '#101010' -border 10 "$W/h1.png"
magick -background '#101010' -fill '#c8c8c8' -font "$FONT" -pointsize 14 \
    label:"Real picks on both games (P1 Phobos, P2 Felicia); level 6 and RNG 0000 pinned on both legs; Felicia at x 695, Phobos at x 540, placed before the window.
The dome's attack box is flat (12 px tall). j.HP's node 4 carries a hurtbox reaching below her feet; on her last descent frame (y 42) it meets the box.
cls 0x7 = the air stager's class (hit in the air); cls 0x52 / 0x38 = the ground path (native byte / our ruled marker)." \
    -bordercolor '#101010' -border 10 "$W/h2.png"
magick "$W/h1.png" "$W/h2.png" "$W/body.png" -background '#101010' -gravity center -append "$OUT"
echo "SHEET $OUT"
