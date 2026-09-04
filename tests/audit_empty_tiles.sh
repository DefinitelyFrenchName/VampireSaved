#!/bin/sh
# audit_empty_tiles.sh — does this build DRAW any sprite whose tile is
# blank? (14z-69o, the child-shadow method, promoted to a test.)
#
# WHY. A tenant's gfx remap rewrites tile codes in a band from the source
# bank to group C. If a tile inside that band was never COPIED — because
# the OBJ-record walk that builds the copy inventory follows pointers and
# cannot reach offset-computed records — the bank is rewritten while the
# art is absent, and the sprite renders as a SOLID RECTANGLE. That is
# exactly how the child sidekick's shadow broke, and no other gate could
# see it: the records are right, the codes are right, the walk is right,
# and the tile is simply empty.
#
# METHOD. Play a replay, decode every sprite the build draws out of group
# C, and flag any whose tile is all-zero. This is a COMPLETE check of the
# inventory against what the build actually renders, not a sample: over
# replay 82 it returned exactly the two missing shadow tiles and nothing
# else. Run it for every new tenant and after any gfx-pipeline change.
#
# FIXING a hit: add the code to build/manifest/extra_tiles/<char>.json,
# which build_donovan.sh merges into the copy inventory.
#
# Usage: ROMDIR=... tests/audit_empty_tiles.sh <builddir> [replay...]
#        default replays: the DF/2P rig and the effect showcase.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-69o: does the build DRAW any sprite whose group-C tile is BLANK? A
#   remapped-but-uncopied tile renders as a SOLID RECTANGLE and no other gate
#   can see it (records/codes/walk all correct). Complete, not a sample.
#   Ground-truthed: PASSES on build/hui14, FAILS on build/hui12 naming both
#   shadow tiles. RUN FOR EVERY NEW TENANT
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
BUILD="${1:?usage: audit_empty_tiles.sh <builddir> [replay...]}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no vsavjw.zip in $BUILD"; exit 1; }
shift || true
REPLAYS="$*"
[ -n "$REPLAYS" ] || REPLAYS="hui/82_hui_df_2p hui/83_hui_fx hui/83d_hui_grenade_ground"
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
PK="${EMPTY_TILE_POKES:-1400:ff8782:10;1450:ff8782:10;1500:ff8782:10}"

rc=0
for r in $REPLAYS; do
    rp="$REPO/tests/replays/$r.rpl"
    [ -f "$rp" ] || { echo "  skip $r (no such replay)"; continue; }
    d="$W/$(basename "$r")"; mkdir -p "$d/s"
    # EVERY frame, not every 25th (14z-70f). The 25-frame stride reported
    # only 10 of the 113 missing ground-explosion tiles: an effect animation
    # turns over faster than the sample, so a sparse sweep is "complete" over
    # the frames it looks at and blind between them.
    FR=$(python3 -c "print(','.join(str(f) for f in range(3100,3610)))")
    ( cd "$d" && REPLAY="$rp" POKES="$PK" DUMP_FRAMES="$FR" FRAMES=3610 \
      TRACE_OUT="$d/obj.txt" MAME_SANDBOX="$d/s" \
      MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/obj_records_dump.lua" \
      > "$d/out" 2>&1 ) || { echo "  FAIL: $r did not run"; rc=1; continue; }
    python3 - "$BUILD" "$d/obj.txt" "$r" <<'PYEOF' || rc=1
import sys, re, zipfile, hashlib, importlib.util, collections
build, objtxt, name = sys.argv[1], sys.argv[2], sys.argv[3]
spec = importlib.util.spec_from_file_location("gt", "tools/gfx_tiles.py")
gt = importlib.util.module_from_spec(spec); spec.loader.exec_module(gt)
z = zipfile.ZipFile(build + "/rompath/vsavjw.zip")
C = [z.read("vsw.%dm" % n) for n in (31, 33, 35, 37)]
BLANK = hashlib.sha1(b"\x00" * 128).digest()
pat = re.compile(r"F(\d+) \S+ \S+ x=\S+ y=\S+ code=(\S+) attr=\S+ "
                 r"pal=(\S+) sz=(\S+) a18=\S+ a19=(\S+)")
bad = collections.Counter()
for line in open(objtxt):
    m = pat.match(line)
    if not m:
        continue
    code, pal, a19 = int(m.group(2), 16), int(m.group(3), 16), int(m.group(5), 16)
    sz = m.group(4)
    if code and 0x40000 <= a19 < 0x60000:
        # EXPAND multi-tile sprites (14z-70f). obj_records_dump reports a
        # sprite's BASE code only; a 6x6 sprite covers 36 tiles at
        # base + row*0x10 + col. Checking the base alone is what let the
        # 214+P ground explosion keep drawing a solid fuchsia block after
        # its base tiles had been added to the inventory.
        w, h = (int(v) for v in sz.split("x"))
        for r in range(h):
            for c in range(w):
                t = (a19 - 0x40000) + r * 0x10 + c
                if hashlib.sha1(gt.tile_bytes(C, t)).digest() == BLANK:
                    bad[(pal, code, 0x40000 + t)] += 1
if bad:
    print("  FAIL %s: %d sprite(s) drawn from an EMPTY group-C tile:" % (name, len(bad)))
    for (pal, code, a19), n in sorted(bad.items()):
        print("     pal=%02x code=%04x a19=%05X (%d draws) -> add 0x%04X to "
              "build/manifest/extra_tiles/<char>.json" % (pal, code, a19, n, code))
    sys.exit(1)
print("  ok %s: every group-C sprite resolves to real art" % name)
PYEOF
done
[ "$rc" = 0 ] || { echo "FAIL: the copy inventory has a hole"; exit 1; }
echo "PASS: no sprite in this build draws from an empty group-C tile"
