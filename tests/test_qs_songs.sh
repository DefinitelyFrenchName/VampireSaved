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
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
ROMDIR="${ROMDIR:?set ROMDIR}"
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

TABLE = 0x9006
touched = set()
for s in songs:
    row = TABLE + s["id"] * 4
    place, ln, src = s["place"], s["len"], s["vs2_src"]
    touched.update(range(row, row + 4))
    touched.update(range(place, place + ln))
    if out[place:place + ln] != vs2[src:src + ln]:
        sys.exit(f"FAIL: {s['name']} placement != vs2 source bytes")
    want = bytes([(place >> 16) & 0xFF, (place >> 8) & 0xFF, place & 0xFF, 0])
    if out[row:row + 4] != want:
        sys.exit(f"FAIL: {s['name']} id row {out[row:row+4].hex()} != {want.hex()}")
    if want[0] == 0:
        sys.exit(f"FAIL: {s['name']} entry b0==0 — unreachable by the driver's own no-op law")
    if stock[row:row + 4] != b"\x00\x00\x00\x00":
        sys.exit(f"FAIL: {s['name']} targets a NON-FREE stock row")
for i in range(len(out)):
    if i not in touched and out[i] != stock[i]:
        sys.exit(f"FAIL: byte {i:#x} differs from stock outside every declared span")
print(f"ok: {len(songs)} songs verified against references; "
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
