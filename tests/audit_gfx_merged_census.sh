#!/bin/sh
# audit_gfx_merged_census.sh — the 3-tenant merged group-C write-set census
# (M3b Phase 3 S0, 14z-83; expectation flipped to ZERO-REAL by the S3 strip
# relocation, maintainer-approved same day). Static: reference zips + frozen
# manifests/build side files; no MAME, no build. ~4 min (one vs2 decrypt +
# 4 census runs).
#
# WHAT IT FREEZES: the complete merged bank-4/bank-5 destination model and
# its collision classification (tools/audit_gfx_merged.py):
#   - ZERO real collisions anywhere. The one that existed — Huitzil's 288
#     strip dsts (vs2 group-A source) inside Pyron's native band (vs2
#     group-B source) at the old shift 0x1000 — was relocated by S3 to
#     0x86A0-0x87BF (shift 0x3800, head of ratified free pool 1). ANY real
#     collision is now a straight FAIL.
#   - Every shared destination is same-source benign, intra-tenant
#     collisions are zero, and the four manifest free pools (pool 1 split
#     by the relocation) are EMPTY.
#   - The union occupancy numbers are FROZEN (drift = a side inventory
#     moved: re-review, never absorb — the type-stamp-census convention).
#
# VERDICT CONTROLS (the comparator itself is under test, RH-8/9/25):
#   A. a shift-0 strip json lands the strip on Huitzil's OWN band
#      (cross-kind, different bytes) -> intra REAL must be NONZERO;
#   B. the OLD shift 0x1000 reproduces the historical defect EXACTLY —
#      288 REAL at 0x5EA0-0x5FBF (the S0 finding as executable fixture);
#   C. B's fixture + a doctored vsav2.zip whose group A carries ONE strip
#      tile's group-B bytes -> REAL drops to exactly 287 (per-tile
#      identity detection, not range matching).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-83 (M3b Phase 3 S0): the COMPLETE merged group-C write-set census
#   (tools/audit_gfx_merged.py) — every build_gfx pass, both banks, incl. the
#   side inventories test_gfx_layout3 is blind to (strip/extra/effect_map/
#   bank-5 sets). Byte-compares every colliding dst at source. Freezes: the
#   ONLY real collision = H's 288 strip dsts 0x5EA0-0x5FBF inside P's band
#   (the S3 relocation target — flips to ZERO when it lands); occupancy
#   45,449/65,536; pools EMPTY. Two comparator verdict controls (must- fire
#   both directions). Static, ~3min
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

echo "== 0: decrypt vs2 once (shared by all census runs) =="
decrypt_view vsav2 "$W/vs2_op.bin" "$W/vs2_data.bin"

echo "== 1: the census on the real inputs =="
python3 tools/audit_gfx_merged.py "$ROMDIR" --vs2-data "$W/vs2_data.bin" \
    --json "$W/main.json" | grep -E "walk |∩|intra|union|pool|CENSUS"

python3 - "$W/main.json" <<'PY' || fail=1
import json, sys
r = json.load(open(sys.argv[1]))
errs = []
for pair, d in r["pairs"].items():
    if d["real"]:
        errs.append(f"{pair} has {len(d['real'])} REAL collision(s) "
                    "(expected none anywhere since the S3 relocation)")
if r["intra"]["real"]:
    errs.append("intra-tenant REAL collisions (expected none)")
if r["total_real"] != 0:
    errs.append(f"total REAL {r['total_real']} != 0")
# frozen occupancy: drift means a side inventory moved — re-review
FROZEN = {"bank4_union": 45737, "bank5_union": 6610,
          "pool_0x8648": 0, "pool_0x87c0": 0,
          "pool_0xa42d": 0, "pool_0xee74": 0}
for k, v in FROZEN.items():
    if r["occupancy"][k] != v:
        errs.append(f"occupancy {k} = {r['occupancy'][k]}, frozen {v}")
for e in errs:
    print("FAIL:", e)
if not errs:
    print("  ok: ZERO real collisions; occupancy frozen "
          "(bank4 45737, four pools empty)")
sys.exit(1 if errs else 0)
PY

echo "== 2: control A — shift-0 strip must produce intra REAL collisions =="
python3 - "$W" <<'PY'
import json, sys
st = json.load(open("build/manifest/strip_tiles/0x10.json"))
st["shift"] = "0x0"
json.dump(st, open(sys.argv[1] + "/strip_shift0.json", "w"))
st["shift"] = "0x1000"     # the OLD shift: the historical-defect fixture
json.dump(st, open(sys.argv[1] + "/strip_old.json", "w"))
PY
python3 tools/audit_gfx_merged.py "$ROMDIR" --vs2-data "$W/vs2_data.bin" \
    --strip-json "$W/strip_shift0.json" --json "$W/ctlA.json" > /dev/null
python3 - "$W/ctlA.json" <<'PY' || fail=1
import json, sys
r = json.load(open(sys.argv[1]))
n = len(r["intra"]["real"])
if n == 0:
    print("FAIL: control A — shift-0 strip produced ZERO intra REAL "
          "collisions; the comparator cannot fail where it must")
    sys.exit(1)
print(f"  ok: control A fired ({n} intra REAL collisions on the "
      "doctored shift)")
PY

echo "== 3: control B — the OLD shift reproduces the historical 288 =="
python3 tools/audit_gfx_merged.py "$ROMDIR" --vs2-data "$W/vs2_data.bin" \
    --strip-json "$W/strip_old.json" --json "$W/ctlB.json" > /dev/null
python3 - "$W/ctlB.json" <<'PY' || fail=1
import json, sys
r = json.load(open(sys.argv[1]))
got = r["pairs"]["huitzil:pyron"]["real"]
if got != list(range(0x5EA0, 0x5FC0)):
    print(f"FAIL: control B — old shift gave {len(got)} REAL (want the "
          "historical 288 at 0x5EA0-0x5FBF); the defect fixture no "
          "longer reproduces")
    sys.exit(1)
print("  ok: control B fired (old shift reproduces 288 REAL at "
      "0x5EA0-0x5FBF)")
PY

echo "== 4: control C — one byte-identical tile drops the fixture to 287 =="
python3 - "$ROMDIR" "$W" <<'PY'
import json, os, sys, zipfile
sys.path.insert(0, "tools")
from gfx_tiles import GROUP_A, GROUP_B, tile_bytes, write_tile
romdir, w = sys.argv[1], sys.argv[2]
z2 = zipfile.ZipFile(os.path.join(romdir, "vsav2.zip"))
ga = [bytearray(z2.read(f"vs2.{n}m")) for n in GROUP_A]
gb = [z2.read(f"vs2.{n}m") for n in GROUP_B]
st = json.load(open("build/manifest/strip_tiles/0x10.json"))
c = st["tiles"][0]                # one strip src; OLD-shift dst = c+0x1000
write_tile(ga, 0x10000 + c, tile_bytes(gb, 0x10000 + (c + 0x1000)))
dd = os.path.join(w, "romdir_c")
os.makedirs(dd, exist_ok=True)
out = zipfile.ZipFile(os.path.join(dd, "vsav2.zip"), "w",
                      zipfile.ZIP_DEFLATED)
repl = {f"vs2.{n}m": bytes(b) for n, b in zip(GROUP_A, ga)}
for info in z2.infolist():
    out.writestr(info, repl.get(info.filename, z2.read(info.filename)))
out.close()
os.symlink(os.path.join(romdir, "vsav.zip"), os.path.join(dd, "vsav.zip"))
print(f"  doctored vs2 group A: tile {c:#06x} := group-B bytes of "
      f"{c + 0x1000:#06x}")
PY
python3 tools/audit_gfx_merged.py "$W/romdir_c" --vs2-data "$W/vs2_data.bin" \
    --strip-json "$W/strip_old.json" --json "$W/ctlC.json" > /dev/null
python3 - "$W/ctlC.json" <<'PY' || fail=1
import json, sys
r = json.load(open(sys.argv[1]))
n = len(r["pairs"]["huitzil:pyron"]["real"])
if n != 287:
    print(f"FAIL: control C — REAL count {n} != 287 after making one "
          "fixture tile byte-identical; per-tile identity detection broken")
    sys.exit(1)
print("  ok: control C fired (fixture REAL 288 -> 287 on the doctored "
      "source)")
PY

echo
if [ "$fail" != 0 ]; then
    echo "FAIL: merged gfx census"
    exit 1
fi
echo "PASS: merged group-C write-set census — ZERO real collisions since"
echo "      the S3 strip relocation; occupancy frozen; all three"
echo "      comparator controls fired"
