#!/bin/sh
# test_applier_vcdiff.sh — SLICE A1 OF THE APPLIER APP: the JS VCDIFF decoder must
# equal the tool of record on the bytes we actually ship (2026-09-20).
#
# WHAT: the JS VCDIFF decoder (tools/applier/vcdiff.mjs) equals the tool of record on the
#   bytes we ship: every patch of the shipped release decodes to the manifest's exact size
#   and SHA-1.
# HOW: rebuilds the source blob from $ROMDIR as the applier does (asserting the blob's own
#   sha1 first), decodes every patch under node and compares; the control flips one byte of
#   a patch copy.
# EXPECTS: every member's size and SHA-1 as the manifest declares; the flipped patch yields
#   a mismatch or a refusal.
#
# docs/project/applier_app_scope.md recommends a static, client-side browser page as the
# no-Python route to vsavjw.zip, and the ONE part of that which is not wiring is the
# VCDIFF decoder — everything else the page needs is native (`deflate-raw`,
# `crypto.subtle` SHA-1). So the decoder is written and locked FIRST, and this gate is
# what makes the scope document's claim reproducible instead of a one-off measurement:
# `tools/applier/vcdiff.mjs` decodes EVERY patch of the shipped release and must produce
# the manifest's exact size and SHA-1 for each, which is the same acceptance
# `tools/apply_release.py` is held to by tests/test_release_roundtrip.sh.
#
# It rebuilds the source blob from $ROMDIR exactly as the applier does (and asserts the
# blob's own sha1 against the manifest first, so a wrong blob cannot be mistaken for a
# wrong decoder).
#
# MUST-FIRE: perturbed-copy: flipped-patch-byte — one byte flipped in a copy of one patch must make the JS decoder produce a member that does NOT match the manifest (a wrong sha1, or a refusal); if it still matched, the comparison would not be reading the decoder's output at all (mode: the gate runs against that perturbed copy)
#
# Usage: ROMDIR=... tests/test_applier_vcdiff.sh [release/merged-m20/mame]   # ci_static
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
ROMDIR="${ROMDIR:?set ROMDIR}"
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REL="${1:-release/merged-m20/mame}"
[ -f "$REL/manifest.json" ] || { echo "SKIP: no release manifest at $REL"; exit 0; }
command -v node >/dev/null 2>&1 || { echo "SKIP: no node on this host (the module is ES-module JS; the browser is its real target)"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

# the source blob, built the applier's way and checked against the manifest FIRST
python3 - "$ROMDIR" "$REL/manifest.json" "$W/blob.bin" <<'PY' || { echo "FAIL: could not rebuild the source blob"; exit 1; }
import hashlib, json, os, sys, zipfile
romdir, mf, out = sys.argv[1:4]
m = json.load(open(mf))
h = hashlib.sha1()
with open(out, "wb") as f:
    for z in m["source"]["order"]:
        zf = zipfile.ZipFile(os.path.join(romdir, z))
        for n in sorted(zf.namelist()):
            d = zf.read(n); f.write(d); h.update(d)
if h.hexdigest() != m["source"]["sha1"]:
    print(f"  the rebuilt blob is {h.hexdigest()[:8]}, the manifest says {m['source']['sha1'][:8]}")
    sys.exit(1)
print(f"  ok: source blob rebuilt from $ROMDIR and matches the manifest ({os.path.getsize(out)} bytes)")
PY

SRC="$REL"
if vs_ctl_is flipped-patch-byte; then
    # the perturbation: a full copy of the release dir with ONE byte of ONE patch flipped
    cp -R "$REL" "$W/perturbed"
    python3 - "$W/perturbed" <<'PY'
import glob, sys, os
d = sys.argv[1]
f = sorted(glob.glob(os.path.join(d, "patches", "vsavjw", "*.xdelta")))[0]
b = bytearray(open(f, "rb").read())
b[len(b) // 2] ^= 0x01
open(f, "wb").write(bytes(b))
print(f"  CONTROL: flipped one byte of {os.path.basename(f)}")
PY
    SRC="$W/perturbed"
fi

cat > "$W/fid.mjs" <<'JSEOF'
import { vcdiffDecode } from process.argv[4];
JSEOF
# (the import path has to be a literal for an ES module, so the runner is written out
# with the module's absolute path baked in rather than passed as an argument)
cat > "$W/fid.mjs" <<JSEOF
import { vcdiffDecode } from '$REPO/tools/applier/vcdiff.mjs';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const rel = process.argv[2], blobPath = process.argv[3];
const m = JSON.parse(readFileSync(rel + '/manifest.json', 'utf8'));
const blob = new Uint8Array(readFileSync(blobPath));
let ok = 0, bad = 0;
const t0 = Date.now();
for (const e of m.zips['vsavjw.zip']) {
  if (!e.patch) continue;
  let out;
  try { out = vcdiffDecode(new Uint8Array(readFileSync(rel + '/' + e.patch)), blob); }
  catch (err) { console.log('  REFUSED ' + e.member + ': ' + err.message); bad++; continue; }
  const h = createHash('sha1').update(out).digest('hex');
  if (out.length !== e.size || h !== e.sha1) {
    console.log('  WRONG ' + e.member + ': size ' + out.length + '/' + e.size +
                ' sha1 ' + h.slice(0, 12) + '/' + e.sha1.slice(0, 12));
    bad++;
  } else ok++;
}
console.log('  ' + ok + ' patches decoded to the manifest\\'s exact sha1, ' + bad +
            ' not (' + ((Date.now() - t0) / 1000).toFixed(1) + ' s)');
process.exit(bad ? 1 : 0);
JSEOF

rc=0
node "$W/fid.mjs" "$SRC" "$W/blob.bin" > "$W/out.txt" 2>&1 || rc=$?
cat "$W/out.txt"

if vs_ctl_is flipped-patch-byte; then
    if [ "$rc" = 0 ]; then
        vs_ctl_dead flipped-patch-byte "a patch with a flipped byte still decoded to the manifest's sha1" || true
        echo "FAIL: test_applier_vcdiff"; exit 1
    fi
    vs_ctl_fired flipped-patch-byte "a flipped patch byte is caught: $(grep -m1 -E '^  (WRONG|REFUSED)' "$W/out.txt" | cut -c3-72)"
    echo "FAIL: test_applier_vcdiff (control mode: the perturbed patch was correctly rejected)"
    exit 1
fi

[ "$rc" = 0 ] || { echo "FAIL: the JS decoder did not reproduce every member"; exit 1; }

# the control, in-gate: the same perturbation, run for real
cp -R "$REL" "$W/ctl"
python3 - "$W/ctl" <<'PY'
import glob, sys, os
d = sys.argv[1]
f = sorted(glob.glob(os.path.join(d, "patches", "vsavjw", "*.xdelta")))[0]
b = bytearray(open(f, "rb").read()); b[len(b) // 2] ^= 0x01
open(f, "wb").write(bytes(b))
PY
crc=0
node "$W/fid.mjs" "$W/ctl" "$W/blob.bin" > "$W/ctl.txt" 2>&1 || crc=$?
if [ "$crc" = 0 ]; then
    vs_ctl_dead flipped-patch-byte "a patch with a flipped byte still decoded to the manifest's sha1" || true
    echo "FAIL: test_applier_vcdiff"; exit 1
fi
vs_ctl_fired flipped-patch-byte "a flipped patch byte is caught: $(grep -m1 -E '^  (WRONG|REFUSED)' "$W/ctl.txt" | cut -c3-72)"

echo "PASS: test_applier_vcdiff — the JS port equals apply_release.py on every shipped patch"
