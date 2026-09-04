#!/bin/sh
# test_decrypt_oracle.sh — verify tools/cps2_decrypt.py against MAME's own
# cps2crypt implementation (dual-implementation agreement).
#
# Usage: ROMDIR=/path/to/roms tests/test_decrypt_oracle.sh [set]   (default vsavj)
# PASS = our decrypted image is byte-identical to MAME's opcode space.
set -eu

SET="${1:-vsavj}"
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

echo "== python decrypt ($SET)"
python3 "$REPO/tools/cps2_decrypt.py" "$ROMDIR/$SET.zip" "$WORK/py_opcodes.bin" | grep -v '^[0-9]*%'

echo "== mame opcode-space dump ($SET)"
( cd "$WORK" && DUMP_OUT="$WORK/mame_opcodes.bin" mame "$SET" \
    -rompath "$ROMDIR" -video none -sound none -nothrottle \
    -skip_gameinfo -autoboot_script "$REPO/tests/lua/dump_opcodes.lua" \
    > "$WORK/mame.log" 2>&1 ) || { cat "$WORK/mame.log"; exit 1; }

PY_SHA=$(shasum "$WORK/py_opcodes.bin" | cut -d' ' -f1)
MAME_SHA=$(shasum "$WORK/mame_opcodes.bin" | cut -d' ' -f1)
echo "python: $PY_SHA"
echo "mame  : $MAME_SHA"

if [ "$PY_SHA" = "$MAME_SHA" ]; then
    echo "PASS: decryption bit-identical to MAME oracle"
else
    echo "FAIL: images differ; first differing bytes:"
    cmp -l "$WORK/py_opcodes.bin" "$WORK/mame_opcodes.bin" | head -5
    exit 1
fi
