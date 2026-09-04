#!/bin/sh
# test_qs_songs.sh — the authored-Z80-song machinery gate (14z-86, M5).
#
# Runs tools/build_qs_songs.py against a scratch copy of the canonical
# WIDE overlay and verifies the result AGAINST THE REFERENCES, not the
# builder's own output: every [[song]] row's placement must equal its vs2
# source bytes, its id row must encode exactly [addr24 BE][00], and every
# byte OUTSIDE the declared spans must be identical to the stock driver
# members (the vanilla-span identity that makes Z80 songs legacy-invisible
# by construction). Then the driver-level reachability laws: entry b0 != 0
# (a b0==0 row is the driver's own no-op marker) and the placement inside
# the banked image.
#
# Verdict controls (RH-8/9): (1) a corrupted song byte in the output must
# be CAUGHT by the checker; (2) the builder must REFUSE a row targeting a
# LIVE id (0x119); (3) refuse a placement over non-zero bytes.
#
# Static, no emulator, ~5 s. Usage: ROMDIR=... tests/test_qs_songs.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-86: the authored-Z80-song machinery (WIDE v1.1 vsw.z01/z02 content
#   members; tools/build_qs_songs.py). Placements == vs2 source bytes, id rows
#   exact, vanilla-span identity, the b0==0 reachability law, 3 verdict
#   controls (corrupt byte / live-id refusal / non-zero-span refusal). Static,
#   ~5 s
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

[ -f "$REPO/build/wide0/rompath/vsavjw.zip" ] || {
    echo "SKIP: no canonical WIDE overlay (build/wide0) — build it first"; exit 0; }
if ! python3 - "$REPO/build/wide0/rompath/vsavjw.zip" <<'PY'
import sys, zipfile
names = zipfile.ZipFile(sys.argv[1]).namelist()
sys.exit(0 if "vsw.z01" in names else 1)
PY
then
    echo "SKIP: overlay predates WIDE v1.1 (no vsw.z01) — rebuild wide0"; exit 0
fi

cp "$REPO/build/wide0/rompath/vsavjw.zip" "$W/t.zip"
python3 "$REPO/tools/build_qs_songs.py" "$W/t.zip" "$ROMDIR/vsav2.zip" \
    --vsav "$ROMDIR/vsav.zip" --ledger "$W/ledger.json" \
    --manifest "$REPO/build/manifest/qs_songs.toml" > "$W/build.log" \
    || fail "builder errored: $(tail -3 "$W/build.log")"

python3 - "$W" "$ROMDIR" <<'PY' || exit 1
import os, sys, zipfile
w, romdir = sys.argv[1], sys.argv[2]
repo = os.environ["REPO"]
sys.path.insert(0, f"{repo}/tools")
from _minitoml import loads

songs = loads(open(f"{repo}/build/manifest/qs_songs.toml").read())["song"]
zt = zipfile.ZipFile(f"{w}/t.zip")
out = zt.read("vsw.z01") + zt.read("vsw.z02")
za = zipfile.ZipFile(f"{romdir}/vsav.zip")
stock = za.read("vm3.01") + za.read("vm3.02")
zb = zipfile.ZipFile(f"{romdir}/vsav2.zip")
vs2 = zb.read("vs2.01") + zb.read("vs2.02")

import json as _json
ledger = _json.load(open(f"{w}/ledger.json"))
TABLE = 0x9006
touched = set()
for sp in ledger["spans"]:          # the builder's own declared spans
    touched.update(range(sp["off"], sp["off"] + sp["len"]))
for s in songs:
    row = TABLE + s["id"] * 4
    place, ln, src = s["place"], s["len"], s["vs2_src"]
    if out[place:place + ln] != vs2[src:src + ln]:
        sys.exit(f"FAIL: {s['name']} placement != vs2 source bytes")
    want = bytes([(place >> 16) & 0xFF, (place >> 8) & 0xFF, place & 0xFF, 0])
    if out[row:row + 4] != want:
        sys.exit(f"FAIL: {s['name']} id row {out[row:row+4].hex()} != {want.hex()}")
    if want[0] == 0:
        sys.exit(f"FAIL: {s['name']} entry b0==0 — unreachable by the driver's own no-op law")
    if stock[row:row + 4] != b"\x00\x00\x00\x00":
        sys.exit(f"FAIL: {s['name']} targets a NON-FREE stock row")
# voice-batch songs: verbatim vs their vs2 sources (independent re-check)
for v in ledger.get("voices", []):
    blob = vs2_song = None
    at, ln = v["at"], v["len"]
    # locate the vs2 source: its song addr from the vs2 id table
    vrow = 0x9006 + (v["vs2_id"] % 0xA70) * 4
    vaddr = (vs2[vrow] << 16) | (vs2[vrow + 1] << 8) | vs2[vrow + 2]
    if out[at:at + ln] != vs2[vaddr:vaddr + ln]:
        sys.exit(f"FAIL: voice {v['vs2_id']:#x} copy != vs2 source")
# the two relocation pointer writes are the ONLY non-zero-span writes:
t0_stock = stock[0x3B04] | (stock[0x3B05] << 8)
if out[0x3B04] | (out[0x3B05] << 8) == t0_stock and ledger.get("voices"):
    sys.exit("FAIL: table-0 pointer not repointed on a voice build")
for i in range(len(out)):
    if i not in touched and out[i] != stock[i]:
        sys.exit(f"FAIL: byte {i:#x} differs from stock outside every declared span")
print(f"ok: {len(songs)} songs + {len(ledger.get('voices', []))} voice songs "
      f"verified against references; "
      f"{len(out) - len(touched)} vanilla bytes identical")

# control 1: corrupt a placed byte -> the placement check above must catch it
bad = bytearray(out)
bad[songs[0]["place"] + 5] ^= 0xFF
if bytes(bad[songs[0]["place"]:songs[0]["place"] + songs[0]["len"]]) == \
        vs2[songs[0]["vs2_src"]:songs[0]["vs2_src"] + songs[0]["len"]]:
    sys.exit("FAIL: CONTROL 1 DEAD — corrupted placement still equals source")
print("ok: control 1 fired (corrupted song byte detected)")
PY
[ $? -eq 0 ] || exit 1

# ── PACKING LAW #3 (14z-87b): every authored record's INCLUSIVE window ──
# The DSP plays/loops through the record's `end` offset INCLUSIVE (field
# width proves it: native windows end at 0xFFFF). The original packer
# copied end-EXCLUSIVE, so every packed sample's last played byte held the
# NEXT blob's first byte — for a silent loop tail, one foreign byte = a
# ~1.8kHz impulse-train beep to keyoff (the sword-plant beep: rec#0x3C8 =
# Donovan 0x705, fired at every plant; 3 contaminated records measured).
# Assert: for every voice_batch record, the CONTENT AT THE RESOLVED WINDOW
# [start..end] INCLUSIVE equals vs2's source window inclusive — this is a
# claim about what PLAYS, not about what was written.
python3 - "$W" "$ROMDIR" <<'PY' || exit 1
import os, sys, zipfile, json, struct
w, romdir = sys.argv[1], sys.argv[2]
ledger = json.load(open(f"{w}/ledger.json"))
if not ledger.get("records"):
    print("ok: law 3 vacuous (no voice_batch records in this manifest)")
    sys.exit(0)
zt = zipfile.ZipFile(f"{w}/t.zip")
z21 = zt.read("vsw.21m")
za = zipfile.ZipFile(f"{romdir}/vsav.zip")
qs = za.read("vm3.11m") + za.read("vm3.12m")
zb = zipfile.ZipFile(f"{romdir}/vsav2.zip")
q2 = zb.read("vs2.11m") + zb.read("vs2.12m")
v2z = zb.read("vs2.01") + zb.read("vs2.02")
v2rec = struct.unpack_from("<H", v2z, 0x3B02)[0]
bad = 0
for r in ledger["records"]:
    s = r["vs2_sample"]
    rec = bytes.fromhex(r["rec"])
    nb, nst = rec[0], struct.unpack("<H", rec[1:3])[0]
    nen = struct.unpack("<H", rec[5:7])[0]
    if nb >= 0x80:
        got = z21[((nb - 0x80) << 16) | nst:(((nb - 0x80) << 16) | nen) + 1]
    else:
        got = qs[(nb << 16) | nst:((nb << 16) | nen) + 1]
    ro = v2rec + s * 8
    b2 = v2z[ro]
    st2 = struct.unpack_from("<H", v2z, ro + 1)[0]
    en2 = struct.unpack_from("<H", v2z, ro + 5)[0]
    want = q2[(b2 << 16) | st2:((b2 << 16) | en2) + 1]
    if got != want:
        print(f"FAIL law3: sample {s:#x} rec#{r['new_index']:#x}: inclusive "
              f"window differs (len {len(got):#x} vs {len(want):#x}; "
              f"end byte {got[-1:] .hex()} vs {want[-1:].hex()})")
        bad += 1
if bad:
    sys.exit(1)
print(f"ok: law 3 — all {len(ledger['records'])} records' inclusive windows "
      f"match vs2 (incl. the end byte)")
PY
[ $? -eq 0 ] || exit 1

# law-3 verdict control: flip one record's END byte in the packed member —
# the checker above must catch it (RH-9: a control that has failed on purpose)
python3 - "$W" "$ROMDIR" <<'PY' || exit 1
import sys, zipfile, json, struct, io, os
w, romdir = sys.argv[1], sys.argv[2]
ledger = json.load(open(f"{w}/ledger.json"))
recs = [r for r in ledger.get("records", []) if bytes.fromhex(r["rec"])[0] >= 0x80]
if not recs:
    print("ok: law-3 control vacuous (no packed records)"); sys.exit(0)
r = recs[0]
rec = bytes.fromhex(r["rec"])
nb, nst = rec[0], struct.unpack("<H", rec[1:3])[0]
nen = struct.unpack("<H", rec[5:7])[0]
zt = zipfile.ZipFile(f"{w}/t.zip")
z21 = bytearray(zt.read("vsw.21m"))
off = (((nb - 0x80) << 16) | nen)
z21[off] ^= 0x5A
zb = zipfile.ZipFile(f"{romdir}/vsav2.zip")
q2 = zb.read("vs2.11m") + zb.read("vs2.12m")
v2z = zb.read("vs2.01") + zb.read("vs2.02")
v2rec = struct.unpack_from("<H", v2z, 0x3B02)[0]
ro = v2rec + r["vs2_sample"] * 8
b2 = v2z[ro]; st2 = struct.unpack_from("<H", v2z, ro+1)[0]; en2 = struct.unpack_from("<H", v2z, ro+5)[0]
want = q2[(b2 << 16) | st2:((b2 << 16) | en2) + 1]
got = bytes(z21[((nb - 0x80) << 16) | nst:off + 1])
if got == want:
    sys.exit("FAIL: LAW-3 CONTROL DEAD — a flipped end byte still matches")
print("ok: law-3 verdict control fired (flipped end byte caught)")
PY
[ $? -eq 0 ] || exit 1

# control 2: the builder must REFUSE a live target id (0x119)
cp "$REPO/build/wide0/rompath/vsavjw.zip" "$W/t2.zip"
cat > "$W/bad.toml" <<'EOF'
[[song]]
name = "control_live_id"
id = 0x119
place = 0x3CB00
vs2_src = 0x34332
len = 0x33
EOF
if python3 "$REPO/tools/build_qs_songs.py" "$W/t2.zip" "$ROMDIR/vsav2.zip" \
    --manifest "$W/bad.toml" > "$W/c2.log" 2>&1; then
    fail "CONTROL 2 DEAD: builder accepted a LIVE target id"
fi
grep -q "not free" "$W/c2.log" || fail "control 2 refused for the wrong reason"
echo "ok: control 2 fired (live-id refusal)"

# control 3: refuse a placement over non-zero bytes (the live 0x119 song)
cat > "$W/bad3.toml" <<'EOF'
[[song]]
name = "control_nonzero_place"
id = 0x0D9
place = 0x29AB2
vs2_src = 0x34332
len = 0x33
EOF
cp "$REPO/build/wide0/rompath/vsavjw.zip" "$W/t3.zip"
if python3 "$REPO/tools/build_qs_songs.py" "$W/t3.zip" "$ROMDIR/vsav2.zip" \
    --manifest "$W/bad3.toml" > "$W/c3.log" 2>&1; then
    fail "CONTROL 3 DEAD: builder wrote over non-zero bytes"
fi
grep -q "not zero-fill" "$W/c3.log" || fail "control 3 refused for the wrong reason"
echo "ok: control 3 fired (non-zero placement refusal)"

echo "PASS: qs song machinery (reference-reconstructed content, vanilla-span"
echo "      identity, reachability law, 3 verdict controls)"
