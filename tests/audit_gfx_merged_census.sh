#!/bin/sh
# audit_gfx_merged_census.sh — the 3-tenant merged group-C write-set census
# (M3b Phase 3 S0, 14z-83). Static: reference zips + frozen manifests/build
# side files; no MAME, no build. ~3 min (one vs2 decrypt + 3 census runs).
#
# WHAT IT FREEZES: the complete merged bank-4/bank-5 destination model and
# its collision classification (tools/audit_gfx_merged.py):
#   - EXACTLY ONE real-collision class exists: Huitzil's 288 strip dsts
#     0x5EA0-0x5FBF (vs2 group-A source) inside Pyron's native band (vs2
#     group-B source). THE KNOWN DEFECT the S3 strip relocation removes —
#     when it lands, this expectation flips to ZERO and any real collision
#     anywhere becomes a straight FAIL.
#   - Every other shared destination is same-source benign (byte-proven
#     for cross-kind pairs; same-source tuples are identical by
#     construction), intra-tenant collisions are zero, and the three
#     manifest free pools are EMPTY.
#   - The union occupancy numbers are FROZEN (drift = a side inventory
#     moved: re-review, never absorb — the type-stamp-census convention).
#
# VERDICT CONTROLS (the comparator itself is under test, RH-8/9/25):
#   A. a shift-0 strip json lands the strip on Huitzil's OWN band
#      (cross-kind, different bytes) -> intra REAL must be NONZERO;
#   B. a doctored vsav2.zip whose group A carries ONE strip tile's
#      group-B bytes makes exactly that collision byte-identical
#      -> REAL must drop to exactly 287 (per-tile identity detection,
#      not range matching).
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

echo "== 0: decrypt vs2 once (shared by all census runs) =="
python3 tools/cps2_decrypt.py "$ROMDIR/vsav2.zip" "$W/vs2_op.bin" \
    --data-out "$W/vs2_data.bin" > /dev/null 2>&1

echo "== 1: the census on the real inputs =="
python3 tools/audit_gfx_merged.py "$ROMDIR" --vs2-data "$W/vs2_data.bin" \
    --json "$W/main.json" | grep -E "walk |∩|intra|union|pool|CENSUS"

python3 - "$W/main.json" <<'PY' || fail=1
import json, sys
r = json.load(open(sys.argv[1]))
errs = []
STRIP = list(range(0x5EA0, 0x5FC0))
if r["pairs"]["huitzil:pyron"]["real"] != STRIP:
    errs.append("huitzil:pyron REAL set is not exactly the 288 strip dsts "
                "0x5EA0-0x5FBF")
for pair in ("donovan:huitzil", "donovan:pyron"):
    if r["pairs"][pair]["real"]:
        errs.append(f"{pair} has REAL collisions (expected none)")
if r["intra"]["real"]:
    errs.append("intra-tenant REAL collisions (expected none)")
if r["total_real"] != 288:
    errs.append(f"total REAL {r['total_real']} != 288 (the held strip "
                "defect, S3 removes it)")
# frozen occupancy: drift means a side inventory moved — re-review
FROZEN = {"bank4_union": 45449, "bank5_union": 6610,
          "pool_0x8648": 0, "pool_0xa42d": 0, "pool_0xee74": 0}
for k, v in FROZEN.items():
    if r["occupancy"][k] != v:
        errs.append(f"occupancy {k} = {r['occupancy'][k]}, frozen {v}")
for e in errs:
    print("FAIL:", e)
if not errs:
    print("  ok: exactly the 288-code strip collision, nothing else; "
          "occupancy frozen")
sys.exit(1 if errs else 0)
PY

echo "== 2: control A — shift-0 strip must produce intra REAL collisions =="
python3 - "$W" <<'PY'
import json, sys
st = json.load(open("build/manifest/strip_tiles/0x10.json"))
st["shift"] = "0x0"
json.dump(st, open(sys.argv[1] + "/strip_shift0.json", "w"))
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

echo "== 3: control B — one byte-identical strip tile must drop REAL to 287 =="
python3 - "$ROMDIR" "$W" <<'PY'
import json, os, sys, zipfile
sys.path.insert(0, "tools")
from gfx_tiles import GROUP_A, GROUP_B, tile_bytes, write_tile
romdir, w = sys.argv[1], sys.argv[2]
z2 = zipfile.ZipFile(os.path.join(romdir, "vsav2.zip"))
ga = [bytearray(z2.read(f"vs2.{n}m")) for n in GROUP_A]
gb = [z2.read(f"vs2.{n}m") for n in GROUP_B]
st = json.load(open("build/manifest/strip_tiles/0x10.json"))
c = st["tiles"][0]                      # one strip src; dst = c + 0x1000
write_tile(ga, 0x10000 + c, tile_bytes(gb, 0x10000 + (c + 0x1000)))
dd = os.path.join(w, "romdir_b")
os.makedirs(dd, exist_ok=True)
out = zipfile.ZipFile(os.path.join(dd, "vsav2.zip"), "w",
                      zipfile.ZIP_DEFLATED)
repl = {f"vs2.{n}m": bytes(b) for n, b in zip(GROUP_A, ga)}
for info in z2.infolist():
    out.writestr(info, repl.get(info.filename, z2.read(info.filename)))
out.close()
# census only reads vsav2.zip + vsav.zip from the romdir
os.symlink(os.path.join(romdir, "vsav.zip"), os.path.join(dd, "vsav.zip"))
print(f"  doctored vs2 group A: tile {c:#06x} := group-B bytes of "
      f"{c + 0x1000:#06x}")
PY
python3 tools/audit_gfx_merged.py "$W/romdir_b" --vs2-data "$W/vs2_data.bin" \
    --json "$W/ctlB.json" > /dev/null
python3 - "$W/ctlB.json" <<'PY' || fail=1
import json, sys
r = json.load(open(sys.argv[1]))
n = len(r["pairs"]["huitzil:pyron"]["real"])
if n != 287:
    print(f"FAIL: control B — REAL count {n} != 287 after making one "
          "strip tile byte-identical; per-tile identity detection broken")
    sys.exit(1)
print("  ok: control B fired (REAL 288 -> 287 on the doctored source)")
PY

echo
if [ "$fail" != 0 ]; then
    echo "FAIL: merged gfx census"
    exit 1
fi
echo "PASS: merged group-C write-set census — the ONLY real collision is"
echo "      the held 288-code strip defect (S3 target); occupancy frozen;"
echo "      both comparator controls fired"
