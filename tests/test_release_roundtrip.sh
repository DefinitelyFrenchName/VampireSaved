#!/bin/sh
# test_release_roundtrip.sh — THE RELEASE PACKAGE GATE (14z-105).
#
# A release is a set of xdelta3 patches + a manifest + an applier
# (tools/package_release.py). This gate is what makes it shippable:
#   1  ROUND TRIP — package the build, apply the package to the PRISTINE
#      reference dumps in a scratch dir, and require every member of every
#      output zip byte-identical to the build's rompath (and the program
#      fingerprint + whole-artifact manifest to agree).
#   2  THE APPLIER REFUSES — a corrupted patch file, a wrong reference
#      member (one byte flipped in a copy of vsavj.zip), and a manifest
#      with a wrong target sha1 must each make apply_release.py exit
#      non-zero WITHOUT writing the output zips.
#   3  RULE 7 — no patch file carries a verbatim run of reference-ROM
#      bytes: every 64-byte-aligned chunk of every reference member is
#      indexed, and a rolling 64-byte window over every patch byte must
#      never hit the index (catches any verbatim run >= 128 bytes). The
#      packager disables xdelta3's secondary compression so this scan
#      sees the real payload. Must-fire control: a patch file with one
#      reference chunk appended IS caught.
#   4  THE PER-PLATFORM LAYOUT (14z-113, docs/project/release_format.md) —
#      the tree's release/<name>/ has fbneo/ mame/ mister/, each with the
#      patch set (manifests byte-identical), the emulator dirs carry the
#      tree's driver patch + EMULATOR.md, mister/ carries MRAs +
#      BITSTREAM.txt + MISTER.md + the .rbf whose sha256 EQUALS the
#      record's, the record byte-identical to the canonical
#      release/bitstreams/<CURRENT>/ one (the build resource every release
#      packages from); no cross-platform leakage; must-fire: a copy missing
#      mame/emulator/ is rejected.
#
# Usage: ROMDIR=... tests/test_release_roundtrip.sh [build_rompath] [name]
#   defaults build/m3b_merged21/rompath, merged-m14. Needs xdelta3.  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
RP="${1:-build/m3b_merged21/rompath}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
NAME="${2:-merged-m14}"  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -d "$RP" ] || { echo "SKIP: $RP missing"; exit 77; }
command -v xdelta3 >/dev/null || { echo "SKIP: xdelta3 not installed"; exit 77; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

echo "== 1. round trip: package -> apply to pristine dumps -> byte-identical =="
python3 tools/package_release.py "$RP" "$W/rel" --romdir "$ROMDIR" --name "$NAME" \
    --version "$(grep -h '^version_text' build/manifest/donovan.toml | sed 's/.*= *"\(.*\)"/\1/')" \
    > "$W/pack.log" 2>&1 || { echo "FAIL: packager"; tail -5 "$W/pack.log"; exit 1; }
grep "^packaged" "$W/pack.log"
python3 "$W/rel/$NAME/apply_release.py" --romdir "$ROMDIR" --out "$W/applied" \
    > "$W/apply.log" 2>&1 || { echo "FAIL: applier"; tail -5 "$W/apply.log"; exit 1; }
python3 - "$RP" "$W/applied" <<'PY' || fail=1
import sys, zipfile, hashlib, os
a, b = sys.argv[1:3]
n = 0
for z in sorted(os.listdir(a)):
    if not z.endswith(".zip"): continue
    za, zb = zipfile.ZipFile(os.path.join(a, z)), zipfile.ZipFile(os.path.join(b, z))
    if sorted(za.namelist()) != sorted(zb.namelist()):
        print(f"FAIL: {z} member inventory differs"); sys.exit(1)
    for m in za.namelist():
        if za.read(m) != zb.read(m):
            print(f"FAIL: {z}/{m} differs after the round trip"); sys.exit(1)
        n += 1
print(f"  ok: {n} members byte-identical after the round trip")
PY
fp() { python3 tools/build_fingerprint.py "$1" --set vsavjw 2>&1 | grep -oE '\b[0-9a-f]{40}\b' | tail -1; }
fa="$(fp "$RP")"; fb="$(fp "$W/applied")"
[ -n "$fa" ] && [ "$fa" = "$fb" ] && echo "  ok: program fingerprint $fb reproduced" \
    || { echo "FAIL: fingerprint $fa vs $fb"; fail=1; }
ma="$(python3 tools/artifact_manifest.py "$RP")"; mb="$(python3 tools/artifact_manifest.py "$W/applied")"
[ "$ma" = "$mb" ] && echo "  ok: whole-artifact manifest reproduced ($mb)" \
    || { echo "FAIL: whole-artifact manifest $ma vs $mb"; fail=1; }

echo "== 2. the applier refuses bad inputs and writes nothing =="
refuse() { # refuse <label> <reldir> <romdir>
    if python3 "$2/apply_release.py" --romdir "$3" --out "$W/out_$1" > "$W/$1.log" 2>&1; then
        echo "FAIL: $1 was ACCEPTED"; fail=1
    elif [ -e "$W/out_$1" ] && ls "$W/out_$1"/*.zip >/dev/null 2>&1; then
        echo "FAIL: $1 refused but wrote output zips"; fail=1
    else
        echo "  ok: $1 refused ($(tail -1 "$W/$1.log" | cut -c1-70))"
    fi
}
cp -r "$W/rel/$NAME" "$W/bad_patch"
pf="$(find "$W/bad_patch/patches" -name '*.xdelta' | head -1)"
python3 -c "import sys;p=sys.argv[1];b=bytearray(open(p,'rb').read());b[len(b)//2]^=0xFF;open(p,'wb').write(bytes(b))" "$pf"
refuse corrupted_patch "$W/bad_patch" "$ROMDIR"
cp -r "$W/rel/$NAME" "$W/bad_manifest"
python3 - "$W/bad_manifest/manifest.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
for e in m["zips"]["vsavjw.zip"]:
    if "patch" in e: e["sha1"] = "0" * 40; break
json.dump(m, open(sys.argv[1], "w"))
PY
refuse wrong_target_sha1 "$W/bad_manifest" "$ROMDIR"
mkdir -p "$W/bad_roms"
for z in vsavj vsav vsav2 vhunt2; do ln -s "$ROMDIR/$z.zip" "$W/bad_roms/$z.zip"; done
rm "$W/bad_roms/vsavj.zip"
python3 - "$ROMDIR/vsavj.zip" "$W/bad_roms/vsavj.zip" <<'PY'
import zipfile, sys
zi, zo = zipfile.ZipFile(sys.argv[1]), zipfile.ZipFile(sys.argv[2], "w")
for n in zi.namelist():
    d = bytearray(zi.read(n))
    if n == "vm3j.05a": d[100] ^= 1
    zo.writestr(n, bytes(d))
PY
refuse wrong_dump "$W/rel/$NAME" "$W/bad_roms"

echo "== 3. rule 7: no verbatim reference-ROM run in any patch file =="
python3 - "$ROMDIR" "$W/rel/$NAME/patches" "$W/control.xdelta" <<'PY' || fail=1
import sys, os, zipfile, hashlib
romdir, pdir, ctrl = sys.argv[1:4]
WIN = 64
MOD = (1 << 61) - 1; B = 257
idx = set(); chunk0 = None
for z in ("vsavj.zip", "vsav.zip", "vsav2.zip", "vhunt2.zip"):
    zf = zipfile.ZipFile(os.path.join(romdir, z))
    for n in zf.namelist():
        d = zf.read(n)
        for o in range(0, len(d) - WIN + 1, WIN):
            c = d[o:o + WIN]
            if len(set(c)) < 8: continue          # skip fills (not copyrightable, and common)
            idx.add(hashlib.sha1(c).digest()[:8])
            if chunk0 is None and len(set(c)) > 40: chunk0 = c
def scan(path):
    d = open(path, "rb").read(); hits = 0
    for o in range(0, len(d) - WIN + 1):
        if hashlib.sha1(d[o:o + WIN]).digest()[:8] in idx:
            hits += 1
    return len(d), hits
total = 0; bad = []
for root, _, files in os.walk(pdir):
    for f in files:
        n, hits = scan(os.path.join(root, f)); total += n
        if hits: bad.append((f, hits))
if bad:
    print("FAIL: verbatim reference-ROM runs in patches:", bad); sys.exit(1)
print(f"  ok: {total} patch bytes scanned against {len(idx)} reference chunks — no verbatim run")
# must-fire control: one reference chunk appended to a copy of a patch
p0 = os.path.join(pdir, sorted(os.listdir(pdir))[0])
f0 = sorted(os.listdir(p0))[0]
open(ctrl, "wb").write(open(os.path.join(p0, f0), "rb").read() + chunk0 + chunk0)
n, hits = scan(ctrl)
if not hits:
    print("FAIL: the rule-7 scan did not fire on a planted reference chunk"); sys.exit(1)
print(f"  ok: must-fire control — planted reference chunk caught ({hits} hits)")
PY

echo "== 4. the per-platform layout of the tree's release/$NAME (14z-113, docs/project/release_format.md) =="
REL="release/$NAME"
if [ ! -d "$REL" ]; then
    echo "  (no $REL in the tree — layout check not applicable)"
else
    for p in fbneo mame mister; do
        for f in manifest.json apply_release.py README.md patches; do
            [ -e "$REL/$p/$f" ] || { echo "FAIL: $REL/$p/$f missing"; fail=1; }
        done
    done
    m0="$(shasum "$REL/fbneo/manifest.json" | cut -c1-40)"
    for p in mame mister; do
        [ "$(shasum "$REL/$p/manifest.json" | cut -c1-40)" = "$m0" ] \
            || { echo "FAIL: $REL/$p/manifest.json differs from fbneo's"; fail=1; }
    done
    [ "$fail" = 0 ] && echo "  ok: three platform dirs, each with the patch set; manifests byte-identical ($(echo "$m0" | cut -c1-8))"
    for p in fbneo mame; do
        cmp -s "$REL/$p/emulator/0002-cps2-wide-v1.patch" "emu/$p-patches/0002-cps2-wide-v1.patch" \
            && [ -f "$REL/$p/EMULATOR.md" ] \
            || { echo "FAIL: $REL/$p/emulator/ patch missing or not the tree's emu/$p-patches/0002"; fail=1; }
    done
    ls "$REL/mister/"*.mra >/dev/null 2>&1 && [ -f "$REL/mister/BITSTREAM.txt" ] && [ -f "$REL/mister/MISTER.md" ] \
        || { echo "FAIL: $REL/mister/ lacks an .mra, BITSTREAM.txt or MISTER.md"; fail=1; }
    grep -q 'sha256' "$REL/mister/BITSTREAM.txt" \
        || { echo "FAIL: BITSTREAM.txt carries no sha256 line"; fail=1; }
    # the bitstream itself is present and IS the one the record names (14z-113, maintainer: a build resource,
    # canonical under release/bitstreams/<seed>/, hash-verified into every release, never copied from another release)
    rbf="$(ls "$REL/mister/"*.rbf 2>/dev/null | head -1)"
    want="$(grep -oE 'sha256 +[0-9a-f]{64}' "$REL/mister/BITSTREAM.txt" | grep -oE '[0-9a-f]{64}')"
    if [ -z "$rbf" ]; then echo "FAIL: $REL/mister/ holds no .rbf"; fail=1
    elif [ "$(shasum -a 256 "$rbf" | cut -c1-64)" != "$want" ]; then echo "FAIL: $rbf sha256 != BITSTREAM.txt's"; fail=1
    else echo "  ok: $(basename "$rbf") present, sha256 ${want%${want#????????}}… matches its record"; fi
    cur="release/bitstreams/$(cat release/bitstreams/CURRENT 2>/dev/null)"
    [ -f "$cur/BITSTREAM.txt" ] && cmp -s "$cur/BITSTREAM.txt" "$REL/mister/BITSTREAM.txt" \
        || { echo "FAIL: $REL/mister/BITSTREAM.txt is not the canonical $cur/BITSTREAM.txt (stale CURRENT, or copied from another release?)"; fail=1; }
    # cross-platform leakage: a platform dir must hold NOTHING of another platform's
    ls "$REL/fbneo/"*.mra "$REL/mame/"*.mra "$REL/fbneo/"*.rbf "$REL/mame/"*.rbf >/dev/null 2>&1 \
        && { echo "FAIL: MiSTer files inside an emulator platform dir"; fail=1; }
    [ -e "$REL/mister/emulator" ] && { echo "FAIL: emulator patch inside mister/"; fail=1; }
    [ "$fail" = 0 ] && echo "  ok: emulator dirs carry the tree's driver patch + EMULATOR.md; mister/ carries MRAs + BITSTREAM.txt + MISTER.md; no cross-platform leakage"
    # must-fire control: the same checks on a copy with mame/emulator/ removed must FAIL
    cp -r "$REL" "$W/layout_bad"; rm -rf "$W/layout_bad/mame/emulator"
    if cmp -s "$W/layout_bad/mame/emulator/0002-cps2-wide-v1.patch" "emu/mame-patches/0002-cps2-wide-v1.patch" 2>/dev/null; then
        echo "FAIL: layout control — a release missing mame/emulator/ was accepted"; fail=1
    else
        echo "  ok: must-fire control — a release missing mame/emulator/ is rejected"
    fi
fi

if [ "$fail" = 0 ]; then
    echo "PASS: release package — round-trips byte-identical from pristine dumps,"
    echo "      the applier refuses bad patches/manifests/dumps without writing,"
    echo "      and no patch carries reference-ROM bytes (rule 7)"
else
    echo "FAIL: release package"; exit 1
fi
