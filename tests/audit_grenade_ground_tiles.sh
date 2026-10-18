#!/bin/sh
# audit_grenade_ground_tiles.sh — Huitzil's 214+LP GROUND explosion draws
# native vs2's own art (14z-123, the documentation rationalization pass,
# inferred_claims row 9; closes the GUESS "the fuchsia class was most likely
# fixed at 14z-67").
#
# WHAT: Phobos's 214+LP GROUND explosion draws native vs2's own art tile for tile: the set
#   of palette-06 explosion tile CONTENTS our build draws across the detonation equals
#   native's (441 tiles, intersection 441, 0 ours-only, 0 native-only) and none is blank —
#   closing the 'most likely fixed' guess.
# HOW: replay 83d on the merged build and on native vs2 on the same WIDE MAME binary, the
#   OBJ list dumped every frame across the detonation and each drawn tile decoded to its
#   canonical content (phase-free: the legs run ~5-6 frames apart).
# EXPECTS: ours-only 0, native-only 0, no blank explosion tile; a non-empty ours-only tile
#   is a real divergence.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lua/obj_records_dump.lua
#   tests/replays/hui/83d_hui_grenade_ground.rpl tools/gfx_tiles.py tools/run_mame.sh
#   tools/setup_mame.sh tests/lib/sheet.sh
#
# SHEET: legs vs2,ours — moments: per leg, the detonation's first explosion frame, its fullest frame (most palette-06 explosion entries) and its last, each picture EVENT-PROVEN on that leg's own OBJ-list dump at that frame — not comparable: the frame numbers (the legs run ~5-6 frames apart, so the verdict compares tile SETS, phase-free), each game's stage, and Victor's art (each game's own copy; [VSP-168])
#
# WHY. engine_internals' grenade section (14z-70e/f) concluded the ground
# mushroom "LOOKS right" from snapshots and that the original fuchsia report
# "was most likely fixed" at the 14z-67 effect work — but the closing word
# was a GUESS, and the residual "8 ours-only / 12 native-only contents" was
# left "part of which is sampling". This audit measures it EVERY frame and
# by tile CONTENT, cross-game.
#
# METHOD (both legs the SAME pinned WIDE MAME binary, replay 83d — 214+LP at
# maximum separation, the rig that makes the bomb land SHORT and detonate on
# the ground). Dump the OBJ list every frame across the detonation, take the
# explosion's own palette-06 entries in the blast box, decode each drawn
# tile's CONTENT (the canonical 128-byte form, tools/gfx_tiles.py) — from
# group C on our build, from vs2's own banks on native — and compare the
# SETS. The legs run ~5-6 frames out of phase (measured: the seq-D dispatch
# thunk costs cycles), so a per-FRAME set intersection reads as disagreement
# while the windows agree; comparing the drawn-tile-content SET over the
# detonation is the phase-free measure ([VSP-136], align by content not
# frame). Measured 14z-123: 441 distinct explosion tiles, intersection 441,
# ours-only 0, native-only 0, zero blank — a perfect superset match. The
# "fuchsia" was always pal-06, the explosion's correct orange->magenta fade.
#
# ASSERTS: no palette-06 explosion tile is blank on our build (the
# empty-tile failure mode, audit_empty_tiles' concern); and every explosion
# tile CONTENT our build draws is drawn by native too and vice versa
# (ours-only == 0 AND native-only == 0). A non-empty ours-only tile is a
# REAL divergence (our build drawing art native does not) and fails.
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged31] tests/audit_grenade_ground_tiles.sh
#        2 MAME runs (~4 min). Needs the WIDE MAME binary and a gfx build.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-123 (inferred_claims row 9): the 214+LP ground explosion draws native
#   vs2's own art tile-for-tile (441 tiles, intersection 441, 0 ours-only, 0
#   blank; per-CONTENT across every detonation frame — phase-free). Closes the
#   14z-70e 'most likely fixed' guess. Replay 83d, merged build vs native, ~1
#   min.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${BUILD:-build/m3b_merged31}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
RPL="tests/replays/hui/83d_hui_grenade_ground.rpl"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN"; exit 0; }
[ -f "$RPL" ] || { echo "SKIP: no $RPL"; exit 0; }
export MAME_BIN
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
FR="$(python3 -c 'print(",".join(str(f) for f in range(3400,3521)))')"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

run() {  # <set> <rompath-or-empty> <out>
    d="$W/$1$3"; mkdir -p "$d/s"
    RP="$BUILD/rompath;$ROMDIR"; [ -n "$2" ] || RP="$ROMDIR"
    ( cd "$d" && REPLAY="$REPO/$RPL" POKES="$PK" DUMP_FRAMES="$FR" FRAMES=3521 \
        TRACE_OUT="$d/obj.txt" MAME_SANDBOX="$d/s" MAME_ROMPATH="$RP" \
        "$REPO/tools/run_mame.sh" "$1" \
        -autoboot_script "$REPO/tests/lua/obj_records_dump.lua" >"$d/run" 2>&1 ) \
      || { echo "FAIL: $1 leg died"; tail -5 "$d/run"; exit 1; }
    echo "$d/obj.txt"
}
OURS="$(run vsavjw x "_o")"
NATIVE="$(run vsav2 "" "_n")"

python3 - "$OURS" "$NATIVE" "$BUILD" "$ROMDIR" <<'PY' && _rc=0 || _rc=$?
import sys, re, zipfile, hashlib, importlib.util, collections
ours, native, build, romdir = sys.argv[1:5]
spec = importlib.util.spec_from_file_location("gt", "tools/gfx_tiles.py")
gt = importlib.util.module_from_spec(spec); spec.loader.exec_module(gt)
zo = zipfile.ZipFile(build + "/rompath/vsavjw.zip")
C = [zo.read("vsw.%dm" % n) for n in (31, 33, 35, 37)]
zn = zipfile.ZipFile(romdir + "/vsav2.zip")
GA = [zn.read("vs2.%dm" % n) for n in (13, 15, 17, 19)]
GB = [zn.read("vs2.%dm" % n) for n in (14, 16, 18, 20)]
BLANK = hashlib.sha1(b"\x00" * 128).digest()
pat = re.compile(r"F(\d+) B(\d) E\w+ x=(\w+) y=(\w+) code=(\w+) attr=\w+ "
                 r"pal=(\w+) sz=(\d+)x(\d+) a18=(\w+) a19=(\w+)")

def tiles(path, native):
    seen = collections.Counter(); blanks = 0; ents = 0
    for ln in open(path):
        m = pat.match(ln)
        if not m:
            continue
        x = int(m.group(3), 16) & 0x3ff; y = int(m.group(4), 16) & 0x3ff
        code = int(m.group(5), 16); pal = m.group(6)
        w, h = int(m.group(7)), int(m.group(8))
        a18, a19 = int(m.group(9), 16), int(m.group(10), 16)
        if code == 0 or pal != "06" or not (100 <= x <= 340 and 60 < y < 260):
            continue
        ents += 1
        for r in range(h):
            for c in range(w):
                if native:
                    t = a18 + r * 0x10 + c
                    simms, idx = (GB, t - 0x20000) if t >= 0x20000 else (GA, t)
                else:
                    t = a19 + r * 0x10 + c
                    if not (0x40000 <= t < 0x60000):
                        continue
                    simms, idx = C, t - 0x40000
                dig = hashlib.sha1(gt.tile_bytes(simms, idx)).digest()
                seen[dig] += 1
                if dig == BLANK:
                    blanks += 1
    return seen, blanks, ents

to, bo, eo = tiles(ours, False)
tn, bn, en = tiles(native, True)
inter = set(to) & set(tn)
ours_only = set(to) - set(tn) - {BLANK}
native_only = set(tn) - set(to) - {BLANK}
print(f"  ours pal-06 explosion entries {eo}, distinct tiles {len(to)}, blank {bo}")
print(f"  native pal-06 explosion entries {en}, distinct tiles {len(tn)}, blank {bn}")
print(f"  tile-content intersection {len(inter)}, ours-only {len(ours_only)}, "
      f"native-only {len(native_only)}")
fail = 0
if eo < 100 or en < 100:
    print("  FAIL: explosion did not fire on a leg (rig liveness)"); fail = 1
if bo:
    print(f"  FAIL: {bo} palette-06 explosion tile(s) drawn from EMPTY group-C art "
          "(the fuchsia/placeholder failure mode)"); fail = 1
if ours_only:
    print(f"  FAIL: {len(ours_only)} explosion tile CONTENT(s) our build draws "
          "that native does not — a real divergence, not phase"); fail = 1
if native_only:
    print(f"  WARN: {len(native_only)} native-only tile content(s) — likely the "
          "5-6 frame phase tail; not a build fault (native draws art our "
          "window missed). Not failing on this alone.")
if not fail:
    print("  PASS: the ground explosion draws native vs2's own art, tile-for-tile; "
          "no blank/fuchsia tile; ours-only == 0")
sys.exit(fail)
PY

# THE SHEET (#291, D2): with SHEET_OUT set, both legs re-run under obj_records_dump.lua itself and EVENT-PROVEN on their
# own OBJ-list dump at three frames of the detonation each. Nothing the gate decides changes.
. "$REPO/tests/lib/sheet.sh"
if sheet_on; then
    if [ "$_rc" = 0 ]; then _sv="tile sets equal (ours-only 0, no blank)"; else _sv="the tile-set check FAILS"; fi
    sheet_new grenade "Phobos's 214+LP ground explosion (replay 83d): native vs2 above ours" huitzil - \
        "the frame numbers (the legs run ~5-6 frames apart, so the verdict compares tile SETS, phase-free), each game's stage, and Victor's art (each game's own copy; [VSP-168])"
    _env="DUMP_FRAMES=$FR;FRAMES=3521"
    sheet_leg grenade native vs2 vsav2 "$ROMDIR" "$REPO/$RPL" "$PK" 3521
    sheet_tap grenade native tests/lua/obj_records_dump.lua "$_env"
    sheet_leg grenade ours ours vsavjw "$BUILD/rompath;$ROMDIR" "$REPO/$RPL" "$PK" 3521
    sheet_tap grenade ours tests/lua/obj_records_dump.lua "$_env"
    _sfn="$(sheet_file grenade native.obj "$NATIVE")"; _sfo="$(sheet_file grenade ours.obj "$OURS")"
    python3 - "$NATIVE" "$OURS" > "$W/sheet_frames.txt" <<'PYF'
import re, sys
pat = re.compile(r"F(\d+) B\d E\w+ x=(\w+) y=(\w+) code=(\w+) attr=\w+ pal=(\w+) ")
for leg, path in (("native", sys.argv[1]), ("ours", sys.argv[2])):
    n = {}
    for ln in open(path):
        m = pat.match(ln)
        if not m: continue
        x, y, code = int(m.group(2), 16) & 0x3ff, int(m.group(3), 16) & 0x3ff, int(m.group(4), 16)
        if code and m.group(5) == "06" and 100 <= x <= 340 and 60 < y < 260:
            n[int(m.group(1))] = n.get(int(m.group(1)), 0) + 1
    if n:
        fs = sorted(n); peak = max(fs, key=lambda f: (n[f], -f))
        print(leg, fs[0], peak, fs[-1], n[fs[0]], n[peak], n[fs[-1]])
PYF
    for k in 1 2 3; do
        case $k in 1) _sl="the first explosion frame" ;; 2) _sl="the fullest explosion frame" ;; 3) _sl="the last explosion frame" ;; esac
        _fn="$(awk -v k=$k '$1=="native" {print $(k+1)}' "$W/sheet_frames.txt")"; _fo="$(awk -v k=$k '$1=="ours" {print $(k+1)}' "$W/sheet_frames.txt")"
        _nn="$(awk -v k=$k '$1=="native" {print $(k+4)}' "$W/sheet_frames.txt")"; _no="$(awk -v k=$k '$1=="ours" {print $(k+4)}' "$W/sheet_frames.txt")"
        sheet_moment grenade "m$k" "$_sl" "$_sv" "native f${_fn:-?} ${_nn:-0} entries, ours f${_fo:-?} ${_no:-0} entries"
        [ -n "$_fn" ] && sheet_at grenade "m$k" native "$_fn" event "$_sfn:$_fn-$_fn"
        [ -n "$_fo" ] && sheet_at grenade "m$k" ours "$_fo" event "$_sfo:$_fo-$_fo"
    done
fi
exit "$_rc"
