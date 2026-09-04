#!/bin/sh
# test_null_build.sh — M0 acceptance: the null-patch build reproduces vanilla
# vsavj bit-identically from reference inputs, deterministically.
#
# Usage: ROMDIR=/path/to/roms tests/test_null_build.sh
# PASS = (a) two builds are byte-identical zips, and (b) every member's SHA-1
# equals the frozen reference manifest entry (docs/checksums.txt).
set -eu

ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== build twice"
python3 "$REPO/tools/build_rom.py" "$ROMDIR" "$WORK/a/vsavj.zip"
python3 "$REPO/tools/build_rom.py" "$ROMDIR" "$WORK/b/vsavj.zip" > /dev/null

cmp "$WORK/a/vsavj.zip" "$WORK/b/vsavj.zip" || { echo "FAIL: builds not deterministic"; exit 1; }
echo "ok: two builds byte-identical"

echo "== members vs frozen reference manifest"
python3 - "$WORK/a/vsavj.zip" "$REPO/docs/checksums.txt" <<'EOF'
import hashlib, sys, zipfile
out_zip, manifest_path = sys.argv[1], sys.argv[2]
frozen = {}
for line in open(manifest_path):
    if line.startswith("#") or not line.strip():
        continue
    path, size, crc, sha = line.rsplit(None, 3)
    frozen[path] = sha
ok = True
with zipfile.ZipFile(out_zip) as zf:
    names = zf.namelist()
    ref_members = {p.split("/", 1)[1] for p in frozen if p.startswith("vsavj.zip/")}
    if set(names) != ref_members:
        print(f"FAIL membership: built {sorted(names)} != reference {sorted(ref_members)}")
        ok = False
    for n in names:
        sha = hashlib.sha1(zf.read(n)).hexdigest()
        want = frozen.get(f"vsavj.zip/{n}")
        tag = "ok  " if sha == want else "FAIL"
        if sha != want:
            ok = False
        print(f"{tag} {n} {sha}" + ("" if sha == want else f" != {want}"))
sys.exit(0 if ok else 1)
EOF
echo "PASS: null build reproduces vanilla vsavj bit-identically"
