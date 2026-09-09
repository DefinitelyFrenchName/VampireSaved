#!/bin/sh
# capture_sheet.sh — OURS vs NATIVE capture geometry, as NUMBERS and as a
# PICTURE, matched by KEYFRAME (14z-143).
#
# WHY IT EXISTS. The maintainer has twice required captures before accepting a
# capture-geometry finding (14z-131, and again at the 14z-143 port), and both
# times the rig was rebuilt by hand in a scratch directory and thrown away. The
# measurement is gated (audit_pyron_capture_block, audit_don_grab_pose,
# test_hui_grab_victim); the PRESENTATION of it was not rerunnable, which is
# what [VSP-18] exists to stop. This is that rig, as a tool.
#
# It is an INSTRUMENT, not a gate: it prints what it measured and writes a PNG.
# It asserts nothing and has no expectations to freeze. The verdicts live in the
# gates above; use this to LOOK at what they measured, and to hand a human
# something to eyeball.
#
# *** THE ALIGNMENT RULE, and it is the whole point ([VSP-136]). *** The two
# games do not run the same number of video frames per engine tick — ours dwells
# about one frame longer per keyframe, the ruled host-clock difference ([VSE-83];
# maintainer 2026-09-02, "the engine, being vanilla vsav, takes precedence"). So
# same-frame snapshots compare DIFFERENT keyframes and invent a difference that
# is not there. This tool reads each leg's per-frame victim offset, walks the
# ORDERED sequence of distinct offsets, and photographs the frame on which each
# leg is showing the SAME keyframe.
#
# *** WHAT IS NOT COMPARABLE ACROSS THE COLUMNS ([VSP-168]). *** HUD styling,
# and the VICTIM'S OWN SPRITE — a legacy victim is VS's art on our leg and VS2's
# on the native one, and each game ships its own. Compare WHERE and HOW the
# victim is held, never its pixels. The caption says so on the sheet itself.
#
# A leg that never made the hold is VOID, not a pass ([VSP-170]): the tool
# refuses to draw a sheet from it and says which leg died.
#
# Usage:
#   ROMDIR=... tools/capture_sheet.sh <attacker_hex> <victim_hex> [out.png]
# Env (code defaults, [VSP-165]):
#   BUILD=build/m3b_merged26      the "ours" leg
#   BEFORE=                       optional third column (a pre-fix build), drawn
#                                 at OURS' frame numbers — a leg whose geometry
#                                 differs has no matching keyframe by definition
#   RPL=tests/replays/judge/02_throw.rpl
#   WINDOW=3005-3074              the frame window to dump
#   MAME_BIN=$HOME/.cache/vampire-saved/mame/cps2   (PINNED — run_mame.sh falls
#                                 back to a PATH `mame` that does not know
#                                 vsavjw, and the leg then measures nothing)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ATT="${1:?usage: capture_sheet.sh <attacker_hex> <victim_hex> [out.png]}"
VIC="${2:?usage: capture_sheet.sh <attacker_hex> <victim_hex> [out.png]}"
OUT="${3:-/tmp/capture_sheet_${ATT}_${VIC}.png}"
ROMDIR="${ROMDIR:?set ROMDIR}"
# ABSOLUTE ([VSP-108]): legs cd into work dirs and then compose MAME_ROMPATH
# strings that still contain $ROMDIR; a relative value resolves against the WORK
# dir and silently finds no reference members.
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
BUILD="${BUILD:-build/m3b_merged26}"
BEFORE="${BEFORE:-}"
RPL="${RPL:-$REPO/tests/replays/judge/02_throw.rpl}"
WINDOW="${WINDOW:-3005-3074}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "FAIL: no MAME binary at $MAME_BIN (tools/setup_mame.sh)"; exit 1; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no $BUILD/rompath/vsavjw.zip"; exit 1; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
F0="${WINDOW%%-*}"; F1="${WINDOW##*-}"
PK="1400:ff8782:$ATT;1450:ff8782:$ATT;1500:ff8782:$ATT;1400:ff8b82:$VIC;1450:ff8b82:$VIC;1500:ff8b82:$VIC"
DF="$(python3 -c "import sys; a,b=int(sys.argv[1]),int(sys.argv[2]); print(';'.join(f'{f}:ff8410-ff8418;{f}:ff8810-ff8818;{f}:ff8934-ff8935' for f in range(a,b+1)))" "$F0" "$F1")"

echo "== capture_sheet: attacker $ATT vs victim $VIC =="
echo "   ours   $BUILD  ($(python3 tools/build_fingerprint.py "$BUILD/rompath" --set vsavjw --sha-only 2>/dev/null | cut -c1-8))"
echo "   native vsav2 from \$ROMDIR"
[ -n "$BEFORE" ] && echo "   before $BEFORE  ($(python3 tools/build_fingerprint.py "$BEFORE/rompath" --set vsavjw --sha-only 2>/dev/null | cut -c1-8))"

# ── 1. the dump legs, in parallel; every MAME run takes a FRESH sandbox ───────
for leg in ours native; do
    mkdir -p "$W/$leg/sbx"
    if [ "$leg" = ours ]; then _s=vsavjw; _rp="$REPO/$BUILD/rompath;$ROMDIR"
    else                      _s=vsav2;  _rp="$ROMDIR"; fi
    ( cd "$W/$leg" && REPLAY="$RPL" POKES="$PK" DUMPS="$DF" \
      CHECKSUM_OUT="$W/$leg/out.log" MAME_SANDBOX="$W/$leg/sbx" MAME_ROMPATH="$_rp" \
      "$REPO/tools/run_mame.sh" "$_s" -autoboot_script "$REPO/tests/lua/replay.lua" \
      > "$W/$leg/mame.log" 2>&1 ) &
done
wait     # the wrapper MUST wait: a shell that exits orphans its MAME children

# ── 2. the offsets, and the keyframe alignment ───────────────────────────────
python3 - "$W" > "$W/plan.txt" <<'PY'
import glob, re, struct, sys
d = sys.argv[1]
def offs(leg):
    out = []
    for f in glob.glob(f"{d}/{leg}/dump_*_ff8810.bin"):
        fr = int(re.search(r'dump_(\d+)_', f).group(1))
        cap = open(f"{d}/{leg}/dump_{fr}_ff8934.bin", 'rb').read()
        if not (cap and cap[0]):          # not captured on this frame
            continue
        v = open(f, 'rb').read(); a = open(f"{d}/{leg}/dump_{fr}_ff8410.bin", 'rb').read()
        out.append((fr, struct.unpack_from('>h', v, 0)[0] - struct.unpack_from('>h', a, 0)[0],
                        struct.unpack_from('>h', v, 4)[0] - struct.unpack_from('>h', a, 4)[0]))
    return sorted(out)
O, N = offs("ours"), offs("native")
if not O or not N:
    print("VOID " + ("ours" if not O else "native")); raise SystemExit(0)
def seq(rows):                       # ORDERED distinct offsets + first frame each
    s = []
    for fr, dx, dy in rows:
        if not s or s[-1][1] != (dx, dy):
            s.append((fr, (dx, dy)))
    return s
so, sn = seq(O), seq(N)
print(f"HELD ours {len(O)} frames {O[0][0]}-{O[-1][0]}   native {len(N)} frames {N[0][0]}-{N[-1][0]}")
print(f"KEYFRAMES ours {len(so)}   native {len(sn)}")
setO, setN = {k for _, k in so}, {k for _, k in sn}
print(f"OFFSET-SET overlap {len(setO & setN)} of union {len(setO | setN)}")
print("SEQ ours   " + " ".join(f"({k[0]},{k[1]})" for _, k in so))
print("SEQ native " + " ".join(f"({k[0]},{k[1]})" for _, k in sn))
# pair by the offset VALUE where both legs show it; else by ordinal position
pairs, used = [], set()
for fo, k in so:
    m = [fn for fn, kn in sn if kn == k and fn not in used]
    if m:
        used.add(m[0]); pairs.append((fo, m[0], k))
if not pairs:                        # geometries disagree entirely: ordinal
    for i in range(min(len(so), len(sn))):
        pairs.append((so[i][0], sn[i][0], so[i][1]))
    print("PAIRING ordinal (no shared offset — the legs disagree everywhere)")
else:
    print("PAIRING by keyframe value")
for fo, fn, k in pairs[:8]:
    print(f"PAIR {fo} {fn} {k[0]},{k[1]}")
PY
cat "$W/plan.txt"
if grep -q '^VOID ' "$W/plan.txt"; then
    echo "FAIL: the $(sed -n 's/^VOID //p' "$W/plan.txt") leg never made the hold — VOID, not a result ([VSP-170])"
    exit 1
fi
OF="$(awk '/^PAIR /{printf "%s,",$2}' "$W/plan.txt" | sed 's/,$//')"
NF="$(awk '/^PAIR /{printf "%s,",$3}' "$W/plan.txt" | sed 's/,$//')"
[ -n "$OF" ] || { echo "FAIL: no comparable keyframes"; exit 1; }

# ── 3. the snapshot legs, at the PAIRED frames ───────────────────────────────
snap() {  # snap <name> <set> <rompath> <frames>
    mkdir -p "$W/snap_$1/sbx"
    ( cd "$W/snap_$1" && REPLAY="$RPL" POKES="$PK" SNAP_FRAMES="$4" \
      TRACE_OUT="$W/snap_$1/index.txt" MAME_SANDBOX="$W/snap_$1/sbx" MAME_ROMPATH="$3" \
      "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/snapshot_frames.lua" \
      > "$W/snap_$1/mame.log" 2>&1 ) & }
snap ours   vsavjw "$REPO/$BUILD/rompath;$ROMDIR" "$OF"
snap native vsav2  "$ROMDIR"                      "$NF"
[ -n "$BEFORE" ] && snap before vsavjw "$REPO/$BEFORE/rompath;$ROMDIR" "$OF"
wait

# ── 4. the sheet ─────────────────────────────────────────────────────────────
command -v magick >/dev/null || { echo "NOTE: no imagemagick — numbers above, no sheet"; exit 0; }
FONT="${CAPTURE_FONT:-/System/Library/Fonts/Supplemental/Andale Mono.ttf}"
[ -f "$FONT" ] || FONT=""
lbl() { [ -n "$FONT" ] && printf '%s' "-font|$FONT"; }
i=0; rows=""
awk '/^PAIR /{print $4}' "$W/plan.txt" | while read -r k; do :; done
for k in $(awk '/^PAIR /{print $4}' "$W/plan.txt"); do
    n=$(printf '%04d' "$i")
    cols=""
    [ -n "$BEFORE" ] && { magick "$W/snap_before/sbx/snap/vsavjw/$n.png" -bordercolor '#b03a3a' -border 3 "$W/c_b$i.png"; cols="$cols $W/c_b$i.png"; }
    magick "$W/snap_ours/sbx/snap/vsavjw/$n.png"  -bordercolor '#3aa05a' -border 3 "$W/c_o$i.png"
    magick "$W/snap_native/sbx/snap/vsav2/$n.png" -bordercolor '#8a8a8a' -border 3 "$W/c_n$i.png"
    cols="$cols $W/c_o$i.png $W/c_n$i.png"
    ntile=$([ -n "$BEFORE" ] && echo 3 || echo 2)
    # shellcheck disable=SC2086
    magick montage -label '' ${FONT:+-font "$FONT"} $cols -tile ${ntile}x1 -geometry +5+5 -background '#101010' "$W/row_$i.png"
    if [ -n "$FONT" ]; then
        magick "$W/row_$i.png" -background '#101010' -fill '#e8e8e8' -font "$FONT" -pointsize 15 \
            label:"kf$((i+1))  offset ($k)$([ -n "$BEFORE" ] && echo '     BEFORE(red) | OURS(green) | NATIVE(grey)' || echo '     OURS(green) | NATIVE(grey)')" \
            -gravity center -append "$W/rowl_$i.png"
    else cp "$W/row_$i.png" "$W/rowl_$i.png"; fi
    rows="$rows $W/rowl_$i.png"
    i=$((i + 1))
done
# shellcheck disable=SC2086
magick montage -label '' ${FONT:+-font "$FONT"} $rows -tile 1x -geometry +10+6 -background '#101010' "$W/body.png"
if [ -n "$FONT" ]; then
    OVL="$(sed -n 's/^OFFSET-SET //p' "$W/plan.txt")"
    magick -background '#101010' -fill '#ffffff' -font "$FONT" -pointsize 20 \
        label:"CAPTURE GEOMETRY - attacker $ATT vs victim $VIC   (offset-set $OVL)" \
        -bordercolor '#101010' -border 10 "$W/h1.png"
    magick -background '#101010' -fill '#c8c8c8' -font "$FONT" -pointsize 14 \
        label:"Rows are matched by KEYFRAME, not by frame number: ours dwells ~1 video frame longer per keyframe
(the ruled host-clock difference, [VSE-83]) so same-frame snapshots would compare different keyframes.
NOT comparable across the columns: HUD styling, and the victim's own sprite - each game ships its own.
Compare WHERE and HOW the victim is held. Numbers: tools/capture_sheet.sh's stdout; verdicts: the gates." \
        -bordercolor '#101010' -border 10 "$W/h2.png"
    magick "$W/h1.png" "$W/h2.png" "$W/body.png" -background '#101010' -gravity center -append "$OUT"
else cp "$W/body.png" "$OUT"; fi
echo "SHEET $OUT"
