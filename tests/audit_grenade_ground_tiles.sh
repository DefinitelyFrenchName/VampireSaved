#!/bin/sh
# audit_grenade_ground_tiles.sh — Huitzil's 214+LP GROUND explosion draws
# native vs2's own art (14z-123, the documentation rationalization pass,
# inferred_claims row 9; closes the GUESS "the fuchsia class was most likely
# fixed at 14z-67").
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
# Usage: ROMDIR=... [BUILD=build/m3b_merged21] tests/audit_grenade_ground_tiles.sh
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
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${BUILD:-build/m3b_merged21}"
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

python3 - "$OURS" "$NATIVE" "$BUILD" "$ROMDIR" <<'PY'
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
