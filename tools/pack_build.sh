#!/bin/sh
# pack_build.sh — pack patched program files into a runnable rompath dir.
#
# Usage: pack_build.sh <program_files_dir> <out_rompath_dir> [--set vsavj]
# Zips the loose program members (+ key) from <program_files_dir> into
# <out_rompath_dir>/<set>.zip. Run MAME/FBNeo with
#   -rompath "<out_rompath_dir>;$ROMDIR"
# so the parent (vsav.zip) and device (qsound_hle.zip) resolve from ROMDIR
# while the patched program overrides. (MAME will flag a CRC audit mismatch
# on the modified file — expected; it still runs and decrypts it.)
set -eu

SRC="${1:?usage: pack_build.sh <program_dir> <out_rompath_dir> [--set NAME]}"
OUT="${2:?out rompath dir required}"
SET="vsavj"
[ "${3:-}" = "--set" ] && SET="${4:?}"
ROMDIR="${ROMDIR:?set ROMDIR (for the .key source)}"

mkdir -p "$OUT"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp "$SRC"/*.* "$STAGE"/ 2>/dev/null || true
# ensure the key is present (from ROMDIR if the patch dir didn't carry it)
if ! ls "$STAGE"/*.key >/dev/null 2>&1; then
    unzip -o -q "$ROMDIR/$SET.zip" '*.key' -d "$STAGE"
fi
( cd "$STAGE" && rm -f "$SET.zip" && zip -q -X "$SET.zip" * )
cp "$STAGE/$SET.zip" "$OUT/$SET.zip"
echo "packed $OUT/$SET.zip"
