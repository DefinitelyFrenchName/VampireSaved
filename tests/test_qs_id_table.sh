#!/bin/sh
# test_qs_id_table.sh — the QSound Z80 driver id-table census gate (14z-86).
#
# Freezes what tools/audit_qs_id_table.py derives from the two games'
# Z80 members (every base from the $3B00 anchor block — nothing filed),
# plus the cross-game facts the M5 ejection pilot rests on:
#   - vsavj: mod 0x6D8, 1512 live / 240 free rows; 0x119 entry 029ab200
#     (the live-tap-verified row), 0x199 entry 02b85700, rows 0x61/0x62
#     (the 0x739/0x73A fold targets) FREE;
#   - vs2: mod 0xA70; 0x739 live @0x34332 slot 11, 0x73A @0x34365 slot 15;
#   - the two fixed-ROM code regions are byte-identical below 0x34F1
#     except the two envelope-base immediates (0x0D85/0x129F) — the
#     licence for verbatim stream copies;
#   - vs2's ejection sample window (record #0x9D: 0x255800-0x257FFF,
#     0x2800 bytes) is byte-identical in vsav's image at 0x18D800, which
#     is vsavj record #0x5C = note-table-1 entry 0x28's sample.
# Verdict controls: a corrupted id-table row in a temp copy MUST fail,
# and the parser MUST NOT reproduce the retracted region-mapping bytes
# (33 07 50 18) for id 0x119 — the 14z-86 file-mapping-trap regression
# guard (docs/platform/gotchas.md).
#
# Static, no emulator. Usage: ROMDIR=... tests/test_qs_id_table.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
ROMDIR="${ROMDIR:?set ROMDIR}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

python3 "$REPO/tools/audit_qs_id_table.py" "$ROMDIR/vsav.zip:vm3" \
    --json "$W/vsavj.json" > "$W/vsavj.txt" || fail "vsavj census errored"
python3 "$REPO/tools/audit_qs_id_table.py" "$ROMDIR/vsav2.zip:vs2" \
    --json "$W/vs2.json" > "$W/vs2.txt" || fail "vs2 census errored"

python3 - "$W" "$ROMDIR" <<'PY' || exit 1
import json, sys, zipfile
w, romdir = sys.argv[1], sys.argv[2]
vj = json.load(open(f"{w}/vsavj.json"))
v2 = json.load(open(f"{w}/vs2.json"))

def die(msg):
    sys.exit(f"FAIL: {msg}")

# --- frozen census shape -------------------------------------------------
if vj["mod"] != 0x6D8: die(f"vsavj mod {vj['mod']:#x} != 0x6d8")
if v2["mod"] != 0xA70: die(f"vs2 mod {v2['mod']:#x} != 0xa70")
if vj["anchors"] != {"header": 0x9000, "records": 0x45FA, "notes": 0x3B12}:
    die(f"vsavj anchors moved: {vj['anchors']}")
if v2["anchors"] != {"header": 0x9000, "records": 0x4798, "notes": 0x3B14}:
    die(f"vs2 anchors moved: {v2['anchors']}")
cls = lambda rows: {c: sum(1 for r in rows if r["class"] == c)
                    for c in {r["class"] for r in rows}}
cj = cls(vj["rows"])
if cj.get("live", 0) != 1512 or (vj["mod"] - cj.get("live", 0)) != 240:
    die(f"vsavj classes moved: {cj}")

# --- the pilot rows ------------------------------------------------------
def row(census, i): return census["rows"][i]
if row(vj, 0x119)["bytes"] != "029ab200":
    die(f"vsavj id 0x119 entry {row(vj,0x119)['bytes']} != 029ab200")
if row(vj, 0x199)["bytes"] != "02b85700":
    die(f"vsavj id 0x199 entry {row(vj,0x199)['bytes']} != 02b85700")
for i in (0x61, 0x62):
    if not row(vj, i)["class"].startswith("free"):
        die(f"vsavj row {i:#x} (0x739/0x73A fold target) not free")
if row(v2, 0x739)["addr"] != 0x34332 or row(v2, 0x73A)["addr"] != 0x34365:
    die("vs2 0x739/0x73a song addresses moved")

# --- cross-game facts ----------------------------------------------------
za = zipfile.ZipFile(f"{romdir}/vsav.zip")
zb = zipfile.ZipFile(f"{romdir}/vsav2.zip")
a = za.read("vm3.01") + za.read("vm3.02")
b = zb.read("vs2.01") + zb.read("vs2.02")
diffs = [i for i in range(0x34F1) if a[i] != b[i]]
if diffs != [0x0D85, 0x0D86, 0x129F, 0x12A0]:
    die(f"fixed-ROM code diff set changed: {[hex(d) for d in diffs][:8]}")

import struct
# vsavj note-table-1 entry 0x28 -> record #0x5C -> bank 0x18 start 0xD800
nt1 = struct.unpack_from("<H", a, 0x3B06)[0]
s, = struct.unpack_from("<H", a, nt1 + 0x28 * 4)
if s != 0x5C: die(f"vsavj entry 0x28 sample# {s:#x} != 0x5c")
rec = a[0x45FA + 0x5C * 8:0x45FA + 0x5C * 8 + 8]
if rec.hex() != "1800d8f3ffffff3c":
    die(f"vsavj record 0x5c {rec.hex()} != 1800d8f3ffffff3c")
# vs2 ejection sample content == vsav image @0x18D800
q2 = zb.read("vs2.11m")[0x255800:0x258000]
qs = za.read("vm3.11m")
if qs[0x18D800:0x190000] != q2:
    die("ejection sample content mismatch (vsav 0x18D800 vs vs2 0x255800)")

# --- verdict controls ----------------------------------------------------
# (1) the retracted region-mapping bytes must NOT be what the parser sees
if row(vj, 0x119)["bytes"] == "33075018":
    die("parser reproduced the RETRACTED region-mapped entry bytes")
# (2) a corrupted table row in a temp copy MUST change the parse
import os
bad = bytearray(za.read("vm3.01"))
bad[0x9006 + 0x119 * 4] ^= 0xFF
zpath = f"{w}/bad.zip"
with zipfile.ZipFile(zpath, "w") as z:
    z.writestr("vm3.01", bytes(bad))
    z.writestr("vm3.02", za.read("vm3.02"))
import subprocess
out = subprocess.run(
    [sys.executable, f"{os.environ['REPO']}/tools/audit_qs_id_table.py",
     f"{zpath}:vm3", "--json", f"{w}/bad.json"],
    capture_output=True, text=True)
if out.returncode != 0:
    die(f"control census errored: {out.stderr[-200:]}")
badrow = json.load(open(f"{w}/bad.json"))["rows"][0x119]
if badrow["bytes"] == row(vj, 0x119)["bytes"]:
    die("CONTROL DEAD: corrupted row parsed identically to clean row")
print("ok: both censuses frozen, pilot rows verified, controls fired")
PY
[ $? -eq 0 ] || exit 1

echo "PASS: qs id-table census (vsavj mod 0x6d8 1512/240, vs2 mod 0xa70;"
echo "      pilot rows + code-identity licence + ejection content lock)"
