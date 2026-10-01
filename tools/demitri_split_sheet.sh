#!/bin/sh
# demitri_split_sheet.sh — Chaos Flare (LP) on PRISTINE vsavj and vsav2, photographed frame by frame, as a PICTURE for a
# human (14z-187b, GitHub #192).
#
# WHY. tests/audit_demitri_split.sh freezes Chaos Flare's node-change frames on both games (vsavj's later nodes change
# 1-2 frames earlier: vs2 lengthened the hold node a2:0x1e#5, 30 -> 32). A frame number is not a capture: a timing a
# player could feel goes before the maintainer as a picture first (rule-checker run 2026-10-01-518 Q2). This is that
# capture, rerunnable: the gate's own replay (tests/replays/dmg192/chaos_flare.rpl) and pins (level 6 from 2000, the
# RNG word 0000 from 2363), one MAME run per game for the snapshots (tests/lua/snapshot_frames.lua) and one for the node
# trace (tests/lua/field_trace.lua), each cell labelled with the node P1 holds that frame and NEW NODE where it changed.
#
# It is an INSTRUMENT, not a gate: it asserts only that every wanted frame was taken. The verdicts live in the gate.
# NOT COMPARABLE across the rows: the stage art and palette (each game ships its own) — compare Demitri's pose.
#
# Usage: ROMDIR=... tools/demitri_split_sheet.sh <out_dir>
#   writes <out_dir>/chaos_flare_<event>_release.png (+40..+50) and chaos_flare_<event>_end.png (+84..+90) for both of
#   the gate's events, 3000 and 3400 (the frozen rows' two legs)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
: "${ROMDIR:?set ROMDIR to the reference-set directory}"
ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
OUT="${1:?usage: tools/demitri_split_sheet.sh <out_dir>}"; mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
PK="$(python3 -c "print(f'{2000}-{(3800)-1}:ff8116:06' + ';' + f'{2363}-{(3800)-1}:ff80d4:0000')")"
SNAPS="$(python3 -c "print(','.join(str(e+o) for e in (3000, 3400) for o in list(range(40,51))+list(range(84,91))))")"
leg() {  # leg <game> <snap|ft>
    d="$OUT/$1"; mkdir -p "$d/$2"
    if [ "$2" = snap ]; then
        ( cd "$d/snap" && MAME_SANDBOX="$d/snap/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/dmg192/chaos_flare.rpl" \
            POKES="$PK" SNAP_FRAMES="$SNAPS" TRACE_OUT="$d/snap.txt" FRAMES=3500 \
            "$REPO/tools/run_mame.sh" "$1" -autoboot_script "$REPO/tests/lua/snapshot_frames.lua" > "$d/snap.log" 2>&1 ) </dev/null
    else
        ( cd "$d/ft" && MAME_SANDBOX="$d/ft/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/dmg192/chaos_flare.rpl" \
            POKES="$PK" FIELDS="ff841c:l:node,ff8782:b:id,ff8b82:b:p2id" FIELD_OUT="$d/f.ft" FIELD_FROM=2300 FIELD_TO=3500 \
            FRAMES=3500 "$REPO/tools/run_mame.sh" "$1" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/ft.log" 2>&1
          rm -rf "$d/ft/sb" ) </dev/null
    fi
}
leg vsavj snap & leg vsavj ft & leg vsav2 snap & leg vsav2 ft & wait
for g in vsavj vsav2; do
    grep -q 'SNAPSUMMARY frames=3500 taken=36 wanted=36' "$OUT/$g/snap.txt" || { echo "VOID: $g did not take every frame ($OUT/$g/snap.txt)"; exit 1; }
done
python3 - "$OUT" <<'PY'
import sys
from PIL import Image, ImageDraw
O = sys.argv[1]; games = ("vsavj", "vsav2")
def trace(g):
    R = {}
    for l in open(f"{O}/{g}/f.ft"):
        s = l.split()
        if s and s[0] == "F": R[int(s[1])] = {k: int(v) for k, v in (kv.split("=") for kv in s[2:])}
    return R
def snaps(g):
    return {int(s[3]): f"{O}/{g}/snap/sb/snap/{g}/{s[1]}.png" for s in (l.split() for l in open(f"{O}/{g}/snap.txt")) if s and s[0] == "SNAP"}
T = {g: trace(g) for g in games}; S = {g: snaps(g) for g in games}
for g in games:
    if (T[g][2300]["id"], T[g][2300]["p2id"]) != (1, 3): sys.exit(f"VOID: {g} ids {T[g][2300]['id']}/{T[g][2300]['p2id']}, not Demitri/Victor")
def sheet(ev, offs, out, title):
    cw, ch, lab = 240, 184, 34
    img = Image.new("RGB", (60 + cw * len(offs), 30 + 2 * (ch + lab)), "white"); d = ImageDraw.Draw(img)
    d.text((6, 8), title, fill="black")
    for r, g in enumerate(games):
        y = 30 + r * (ch + lab); d.text((4, y + lab + ch // 2), g, fill="black")
        for c, o in enumerate(offs):
            f = ev + o; x = 60 + c * cw
            img.paste(Image.open(S[g][f]).convert("RGB").crop((90, 40, 90 + cw, 40 + ch)), (x, y + lab))
            n, p = T[g][f]["node"], T[g][f - 1]["node"]
            d.text((x + 4, y + 2), f"+{o}  node {n & 0xffff:04x}", fill="black")
            if n != p: d.text((x + 4, y + 16), "NEW NODE", fill="red")
    img.save(f"{O}/{out}"); print(f"wrote {O}/{out}")
for ev in (3000, 3400):
    sheet(ev, list(range(40, 51)), f"chaos_flare_{ev}_release.png", f"Chaos Flare (LP), Demitri P1 vs Victor, event at frame {ev}: the hold release (stage art differs by game; compare the pose)")
    sheet(ev, list(range(84, 91)), f"chaos_flare_{ev}_end.png", f"Chaos Flare (LP), event at frame {ev}: the move's last nodes")
    for g in games:
        print(ev, g, "node changes +40..+90:", [o for o in range(40, 91) if T[g][ev + o]["node"] != T[g][ev + o - 1]["node"]])
PY
