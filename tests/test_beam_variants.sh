#!/bin/sh
# test_beam_variants.sh — the BEAM VARIANT + GFX-READINESS gate (14z-70h).
#
# WHY IT EXISTS. Two facts the beam port rests on, both measured this
# session and both easy to get wrong later:
#
#  1. The maintainer's three inputs (236+P, 236+K, 236+2P/2K) are ONE art
#     path. All three draw pal 0x0C from H's own band; the ES simply uses
#     more tiles. If that stops being true, the port's "one hook covers
#     all three" premise is gone.
#  2. Every tile those variants draw is ALREADY in our group C. That is
#     why the beam port is expected to need no copy-inventory work — and
#     it is exactly the check whose absence made the 214+P explosion a
#     two-step fix (base tiles added, fuchsia block still there).
#
# TWO TRAPS THIS GATE ENCODES, both paid for in 14z-70:
#  - ES CONSUMES ONE METER STOCK. With an empty meter it degrades to the
#    normal special silently, exactly like Dark Force. The replay pokes
#    $FF8509 and section 1 asserts a stock was SPENT (state, not input).
#  - obj_records_dump reports a multi-tile sprite's BASE code only. Tile
#    coverage MUST expand w*h at base + row*0x10 + col, or a 6x6 sprite
#    hides 35 tiles.
#
# Sections:
#   1. NATIVE — all three variants fire, and the ES really is the ES
#      (a stock is spent; its sprite count exceeds P/K's).
#   2. ONE ART PATH — all three draw pal 0x0C from the tenant band.
#   3. GFX READY — 0 of the tiles they draw are missing from group C.
#
# Usage: ROMDIR=... tests/test_beam_variants.sh [wide-builddir]
#        (defaults to build/hui54)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-70h: the beam-port premises. All THREE variants (236+P / 236+K /
#   236+2P==2K) are ONE art path — pal 0x0C from the tenant band — and every
#   tile they draw is ALREADY in group C, so the port needs no copy-inventory
#   work. Encodes two paid-for traps: ES CONSUMES A METER STOCK (empty meter =
#   silent downgrade, like DF, so it asserts the ES is richer than P), and
#   multi-tile sprites must be expanded w*h at base+row*0x10+col
#   (obj_records_dump reports the BASE code only). Native leg only, ~1 min
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
   # RE-POINTED 14z-94 (GitHub #94): was build/hui25, a pre-WIDE-v1.1 set
   # (19 members, no vsw.z01/z02) — the script could not run at all.
   # Its frozen inventory may still describe the OLD build: run it
   # before trusting a green, and re-measure rather than absorb.
BUILD="${1:-build/hui54}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD";; esac  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no $BUILD/rompath/vsavjw.zip"; exit 1; }
REF_BIN="${MAME_REF_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
RPL="$REPO/tests/replays/hui/86_hui_beam_variants.rpl"
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3400:ff8509:03;3700:ff8509:03;3740:ff8509:03"
fail=0

echo "1-2. native: the three variants, and whether they share an art path"
DUMP_FRAMES=3163,3165,3167,3463,3465,3467,3783,3785,3787 \
TRACE_OUT="$WORK/obj.txt" FRAMES=3800 REPLAY="$RPL" POKES="$PK" \
MAME_SANDBOX="$WORK/s" MAME_BIN="$REF_BIN" \
  tools/run_mame.sh vsav2 -autoboot_script "$REPO/tests/lua/obj_records_dump.lua" \
  > "$WORK/run.log" 2>&1 || { echo "  FAIL: the native run did not complete"; exit 1; }

python3 - "$WORK/obj.txt" "$BUILD" "$ROMDIR" <<'PYEOF' || fail=1
import sys, re, collections, hashlib, zipfile, importlib.util
objtxt, build, romdir = sys.argv[1], sys.argv[2], sys.argv[3]
spec = importlib.util.spec_from_file_location("gt", "tools/gfx_tiles.py")
gt = importlib.util.module_from_spec(spec); spec.loader.exec_module(gt)
pat = re.compile(r"^F(\d+) \S+ \S+ x=\S+ y=\S+ code=\S+ attr=\S+ "
                 r"pal=(\S+) sz=(\S+) a18=\S+ a19=(\S+)")
per = collections.defaultdict(lambda: collections.defaultdict(set))
sz_of = {}
for line in open(objtxt):
    m = pat.match(line)
    if not m: continue
    fr, pal, sz, a19 = int(m.group(1)), m.group(2), m.group(3), int(m.group(4), 16)
    per[fr][pal].add(a19); sz_of[(a19, pal)] = sz
GROUPS = {"236+P": (3163, 3165, 3167), "236+K": (3463, 3465, 3467),
          "236+2P (ES)": (3783, 3785, 3787)}
bad = 0
need = set()
for name, frames in GROUPS.items():
    codes = set()
    for f in frames: codes |= per[f].get("0c", set())
    banks = {a >> 16 for a in codes}
    if not codes:
        print(f"  FAIL: {name} drew no pal-0C sprites — the variant did not fire"); bad = 1; continue
    if banks != {3}:
        print(f"  FAIL: {name} draws pal 0C from banks {sorted(banks)}, want bank 3 "
              f"(the tenant band) — the 'one art path' premise is broken"); bad = 1
    else:
        lo, hi = min(a & 0xffff for a in codes), max(a & 0xffff for a in codes)
        print(f"  ok: {name} — {len(codes)} pal-0C codes, bank 3, 0x{lo:04x}-0x{hi:04x}")
    for a in codes:
        w, h = (int(v) for v in sz_of[(a, "0c")].split("x"))
        for r in range(h):
            for c in range(w): need.add((a & 0xffff) + r * 0x10 + c)
# the ES must be RICHER than P/K — the state assertion that it was not downgraded
n = {k: len(set().union(*[per[f].get("0c", set()) for f in v])) for k, v in GROUPS.items()}
if n["236+2P (ES)"] <= n["236+P"]:
    print(f"  FAIL: the ES drew {n['236+2P (ES)']} codes vs P's {n['236+P']} — it was "
          f"DOWNGRADED (empty meter), not an ES. Poke $FF8509."); bad = 1
else:
    print(f"  ok: the ES is richer than P ({n['236+2P (ES)']} vs {n['236+P']} codes) — it fired")
print("3. gfx readiness: are those tiles in our group C?")
z = zipfile.ZipFile(build + "/rompath/vsavjw.zip")
C = [z.read("vsw.%dm" % k) for k in (31, 33, 35, 37)]
vs2 = gt.load_simms(romdir + "/vsav2.zip:vs2")
BLANK = hashlib.sha1(b"\x00" * 128).digest()
missing = [c for c in sorted(need)
           if hashlib.sha1(gt.tile_bytes(C, c)).digest() == BLANK
           and hashlib.sha1(gt.tile_bytes(vs2[1], 0x10000 + c)).digest() != BLANK]
if missing:
    print(f"  FAIL: {len(missing)} of {len(need)} beam tiles are EMPTY in group C "
          f"(0x{min(missing):04x}-0x{max(missing):04x}) -> extra_tiles/<char>.json")
    bad = 1
else:
    print(f"  ok: all {len(need)} beam tiles (multi-tile expanded) are present in group C")
sys.exit(bad)
PYEOF

echo
if [ "$fail" -eq 0 ]; then echo "PASS test_beam_variants.sh"; exit 0
else echo "FAIL test_beam_variants.sh"; exit 1; fi
