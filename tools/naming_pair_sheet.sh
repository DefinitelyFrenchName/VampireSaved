#!/bin/sh
# naming_pair_sheet.sh — ONE NAMING PART, NATIVE vs2 ABOVE OURS, PHOTOGRAPHED ON THE SAME FRAMES
# (14z-184, GitHub #177 and #179).
#
# WHY IT EXISTS. tests/audit_move_parity.sh compares every naming-rig event of a
# tenant on native vsav2 and on the merged WIDE build frame by frame and freezes
# one verdict per event, but a verdict is a word: the maintainer confirms a
# movement or a landing on PICTURES ([VSP-20]-era "captures before conclusions").
# Twice in 14z-184 (#179's landing, #177's movement) those pictures were built
# from scratch scripts under build/; this is that rig, as a tool ([VSP-18]).
#
# It is an INSTRUMENT, not a gate: it asserts nothing and has no expectations.
# THE RIG IS THE PARITY GATE'S, COPIED: the part's committed replay on native;
# on ours P1's prologue cursor moves replaced by the merged wheel's path
# (audit_move_parity.sh `rpl_for`, OURS_PATH per tenant); the part's own pokes
# plus the level pinned to 6 from 2000 and the RNG from the match anchor, on
# both legs. At a matched level the two engines tick alike ([VSE-84]), so the
# same frame number is the same moment on both legs — which is what the gate's
# IDENT verdicts already say, and what the pictures let a human see.
#
# WHAT IS NOT COMPARABLE: the stage and its palette (each game ships its own) and
# P2's art. Compare the TENANT's position and pose.
#
# A leg that took fewer snapshots than asked is VOID: the tool refuses to draw.
#
# Usage:
#   ROMDIR=... tools/naming_pair_sheet.sh <tenant> <part> <out.png> "<label>:<f1,f2,...>" ...
#   e.g. tools/naming_pair_sheet.sh huitzil 1 jump.png "Jump [8]:2966,2974,2982" "Back dash:3474,3480"
# Env: BUILD (default build/m3b_merged28), MAME_BIN, SCALE (default 0.5), TITLE, KEEP=<dir> (keep the runs),
#      RIG_DIR (default tests/replays/naming)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 4 ] || { sed -n '/^# Usage:/,/^# Env:/p' "$0"; exit 2; }
T="$1"; P="$2"; OUT="$3"; shift 3
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged28}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -x "$MAME_BIN" ] || { echo "FAIL: no MAME at $MAME_BIN"; exit 1; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no WIDE build at $BUILD"; exit 1; }
RIG_DIR="${RIG_DIR:-$REPO/tests/replays/naming}"   # another rig directory (e.g. tests/replays/chains174, part c174)
J="$RIG_DIR/${T}_$P.json"; R="$RIG_DIR/${T}_$P.rpl"
[ -f "$J" ] && [ -f "$R" ] || { echo "FAIL: no naming part ${T}_$P"; exit 1; }
case "$T" in donovan) CUR="D D DR DR" ;; huitzil) CUR="D D D" ;; pyron) CUR="D D D D" ;; *) echo "FAIL: tenant $T"; exit 1 ;; esac
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
FRAMES="$(printf '%s\n' "$@" | sed 's/^[^:]*://' | tr '\n' ',' | tr -s ',' | sed 's/,$//')"
FR=$(python3 -c "print(max(int(x) for x in '$FRAMES'.split(','))+2)")
base="$(python3 -c "import json;print(';'.join(json.load(open('$J'))['pokes']))")"
pins="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$FR)) + ';' + ';'.join(f'{f}:ff80d4:0000' for f in range(2363,$FR)))")"
cp "$R" "$W/native.rpl"
awk -v cur="$CUR" '
    /^1104-1106 p2=R$/ && !done { n = split(cur, m, " "); t = 1100
        for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
    /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
    { print }' "$R" > "$W/ours.rpl"
for leg in native ours; do
    if [ "$leg" = native ]; then set_=vsav2; rp="$ROMDIR"; else set_=vsavjw; rp="$BUILD/rompath;$ROMDIR"; fi
    mkdir -p "$W/$leg"
    ( cd "$W/$leg" && MAME_SANDBOX="$W/$leg/sb" MAME_ROMPATH="$rp" REPLAY="$W/$leg.rpl" POKES="$base;$pins" \
        SNAP_FRAMES="$FRAMES" FRAMES="$FR" TRACE_OUT="$W/$leg/index.txt" \
        "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/snapshot_frames.lua" > "$W/$leg/mame.log" 2>&1 ) </dev/null &
done
wait
python3 - "$W" "$OUT" "${TITLE:-${T}_$P: native vs2 above ours, same frames}" "${SCALE:-0.5}" "$@" <<'PY'
import glob, os, sys
from PIL import Image, ImageDraw
W, out, title, S, specs = sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4]), sys.argv[5:]
def shots(leg):
    idx = {}
    for l in open(os.path.join(W, leg, "index.txt")):
        t = l.split()
        if len(t) == 4 and t[0] == "SNAP" and t[2] == "frame": idx[int(t[3])] = t[1]
    subs = glob.glob(os.path.join(W, leg, "sb", "snap", "*", ""))
    if not subs: sys.exit(f"VOID: the {leg} leg took no snapshots ({W}/{leg}/mame.log)")
    return {f: os.path.join(subs[0], n + ".png") for f, n in idx.items()}
legs = {leg: shots(leg) for leg in ("native", "ours")}
rows = []
for sp in specs:
    label, frames = sp.rsplit(":", 1); frames = [int(x) for x in frames.split(",")]
    for leg, name in (("native", "native vs2"), ("ours", "ours")):
        miss = [f for f in frames if f not in legs[leg] or not os.path.exists(legs[leg][f])]
        if miss: sys.exit(f"VOID: the {leg} leg has no snapshot at {miss}")
        rows.append((f"{label}: {name}", [(f, legs[leg][f]) for f in frames]))
w0, h0 = Image.open(rows[0][1][0][1]).size
cw, ch = int(w0 * S), int(h0 * S)
LW, TH, CAP = 190, 30, 14
img = Image.new("RGB", (LW + max(len(r[1]) for r in rows) * cw, TH + len(rows) * (ch + CAP)), "white")
d = ImageDraw.Draw(img)
d.text((6, 8), title, fill="black")
for r, (label, cells) in enumerate(rows):
    y = TH + r * (ch + CAP)
    d.text((6, y + ch // 2), label, fill="black")
    for c, (f, p) in enumerate(cells):
        img.paste(Image.open(p).convert("RGB").resize((cw, ch)), (LW + c * cw, y + CAP))
        d.text((LW + c * cw + 4, y + 1), f"f{f}", fill="black")
img.save(out); print(f"WROTE {out} {img.size[0]}x{img.size[1]}, {len(rows)} rows")
PY
