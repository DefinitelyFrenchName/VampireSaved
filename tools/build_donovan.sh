#!/bin/sh
# build_donovan.sh — the donovan-m2 build driver: checksum gate -> extract
# (vhunt2 oracle) -> generate staged patch -> apply -> pack runnable rompath.
#
# Usage: ROMDIR=... tools/build_donovan.sh <stage 1-5> [outbase=build/donovan]
#
# Output: <outbase>/rompath/vsavj.zip — run with
#   MAME_ROMPATH="<outbase>/rompath;$ROMDIR" tools/run_mame.sh vsavj ...
# All ROM-derived intermediates live under <outbase> (gitignored) and are
# regenerated from $ROMDIR on every run (repo rule 7).
set -eu

STAGE="${1:?usage: build_donovan.sh <stage 1-5> [outbase]}"
OUTBASE="${2:-build/donovan}"
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

python3 tools/audit_roms.py "$ROMDIR" > /dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

python3 tools/extract_char.py "$ROMDIR/vsav2.zip" "$OUTBASE/extract" \
    --char 0x13 --oracle "$ROMDIR/vhunt2.zip" > "$OUTBASE/extract.log" 2>&1 \
    || { tail -20 "$OUTBASE/extract.log"; exit 1; }

python3 tools/gen_donovan_patch.py "$OUTBASE/extract" "$OUTBASE/patch" \
    --vsavj "$ROMDIR/vsavj.zip" --stage "$STAGE"

python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$OUTBASE/prg" \
    --patch "$OUTBASE/patch/patch.json" | tail -3

rm -rf "$OUTBASE/rompath"
ROMDIR="$ROMDIR" tools/pack_build.sh "$OUTBASE/prg" "$OUTBASE/rompath" > /dev/null
python3 tools/build_fingerprint.py "$OUTBASE/rompath;$ROMDIR" --sha-only \
    | sed 's/^/build fingerprint: /'
echo "OK: stage $STAGE build at $OUTBASE/rompath (fingerprint above; register in tests/expected/registry.tsv at freeze time)"
