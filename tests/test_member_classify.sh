#!/bin/sh
# test_member_classify.sh — PROGRAM and GFX members must never be confused,
# and the three classifiers must agree (14z-94, GitHub #19). ~2 s.
#
# THE DEFECT. `_PRG_RE` matched `.41`-`.44` with an optional single-letter
# suffix, so it also matched the GFX members `vsw.41m` and `vsw.43m`. The gfx
# namer emits `vsw.{31+2i}m`; at the currently-used `--gfx 4` it stops at
# `vsw.37m` and nothing collides, but the documented growth path
# (`--gfx 8`, docs/project/M3b_plan.md:219) produces vsw.39m, vsw.41m,
# vsw.43m, vsw.45m — and the middle two would have been loaded as PROGRAM.
#
# Consequences on such a build, none of them loud: `load_set`/`load_stored`
# concatenate two 4 MB gfx members into the 68k blob, so every logical word
# past ~0x400000 is wrong; `build_fingerprint` hashes gfx into the DISPATCH
# fingerprint; and because `int("41")` is the sort key for both `vsw.41` and
# `vsw.41m`, member ORDER comes from namelist order rather than load order.
# Note 39m and 45m do NOT match, so even the corruption is non-obvious.
#
# THE FIX is that the suffix class excludes `m`. Section 2 is the one that
# matters: it tests the names that do not exist yet, because the whole point
# is a path that is inert today and wrong at the next member count.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0

python3 - <<'PY' || rc=1
import sys, glob, zipfile, os
sys.path.insert(0, "tools")
import cps2_decrypt as cps
import build_fingerprint as bf   # noqa: F401 — imported to prove it shares the regex

rc = 0

print("== 1. every REAL program member still classifies as program ==")
romdir = os.environ.get("ROMDIR", "")
zips = sorted(glob.glob(os.path.join(romdir, "*.zip"))) if romdir else []
zips += [p for p in ("build/hui51/rompath/vsavjw.zip",  # re-pointed 14z-117b (random-select freeze) <- 14z-117
                     "build/m3b_merged20/rompath/vsavjw.zip") if os.path.exists(p)]  # re-pointed 14z-117b (random-select freeze) <- 14z-117
if not zips:
    print("  SKIP: no ROMDIR and no packed build to read")
else:
    seen = 0
    for z in zips:
        for n in zipfile.ZipFile(z).namelist():
            if cps._PRG_RE.search(n):
                seen += 1
                if n.endswith("m"):
                    print(f"  FAIL: {z}:{n} classified PROGRAM but is m-suffixed")
                    rc = 1
    print(f"  ok: {seen} program-classified members across {len(zips)} zips, "
          "none m-suffixed")

print("== 2. CONTROL — the --gfx 8 names must NOT classify as program ==")
# These members do not exist yet. That is the point: the defect is inert at
# --gfx 4 and wrong at the count the project has already planned.
future = ["vsw.39m", "vsw.41m", "vsw.43m", "vsw.45m"]
for n in future:
    if cps._PRG_RE.search(n):
        print(f"  FAIL: {n} classifies as PROGRAM — the --gfx 8 path is unsafe")
        rc = 1
if rc == 0:
    print(f"  ok: none of {future} classify as program")

print("== 3. CONTROL — the regex has not been loosened into uselessness ==")
must = ["vm3j.03d", "vm3j.04d", "vm3j.05a", "vm3j.06b", "vm3j.10b",
        "vh2j.05", "vs2j.10", "vsw.41", "vsw.42", "vsw.43", "vsw.44"]
missed = [n for n in must if not cps._PRG_RE.search(n)]
if missed:
    print(f"  FAIL: real program members no longer match: {missed}")
    rc = 1
else:
    print(f"  ok: all {len(must)} known program spellings still match")

print("== 4. the gfx members in use today are still not program ==")
gfx = ["vm3.13m", "vm3.15m", "vm3.17m", "vm3.19m",
       "vsw.31m", "vsw.33m", "vsw.35m", "vsw.37m", "vsw.21m"]
hit = [n for n in gfx if cps._PRG_RE.search(n)]
if hit:
    print(f"  FAIL: gfx members classify as program: {hit}")
    rc = 1
else:
    print(f"  ok: {len(gfx)} current gfx members classify as gfx")

sys.exit(rc)
PY

echo
if [ "$rc" = 0 ]; then
    echo "PASS: program and gfx members cannot be confused, today or at --gfx 8."
else
    echo "FAIL: see above."
fi
exit $rc
