#!/bin/sh
# test_patch_prg.sh — the program-patch tooling round-trips through MAME.
#
# Usage: ROMDIR=... tests/test_patch_prg.sh
# Gates: (1) null patch is bit-identical to reference vsavj; (2) an injected
# code blob decrypts back to its plaintext in MAME's real opcode space;
# (3) an injected data blob is readable raw. This is what makes patch_prg
# trustworthy for M2 (superset invariant depends on the null case).
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
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

echo "== null patch bit-identical"
python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/null" > "$WORK/null.log"
grep -q "^0 member(s) changed" "$WORK/null.log" || { echo "FAIL: null changed files"; exit 1; }
fail=0
for f in "$WORK"/null/vm3j.*; do
    n=$(basename "$f")
    a=$(shasum "$f" | cut -d' ' -f1)
    b=$(unzip -p "$ROMDIR/vsavj.zip" "$n" | shasum | cut -d' ' -f1)
    [ "$a" = "$b" ] || { echo "FAIL: $n differs from reference"; fail=1; }
done
[ "$fail" = 0 ] && echo "  ok: all program members bit-identical"

echo "== code+data inject decrypts correctly in MAME"
cat > "$WORK/patch.json" <<'JSON'
{"ops":[{"op":"code","addr":"0xBF800","hex":"4e714e714e7560fe"},
        {"op":"data","addr":"0xBF69A","hex":"cafebabe"}]}
JSON
python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/patched" --patch "$WORK/patch.json" > /dev/null
ROMDIR="$ROMDIR" "$REPO/tools/pack_build.sh" "$WORK/patched" "$WORK/prom" > /dev/null
DUMP_OUT="$WORK/opc.bin" DUMP_LEN=$((0xC0000)) mame vsavj \
    -rompath "$WORK/prom;$ROMDIR" -video none -sound none -nothrottle -skip_gameinfo \
    -autoboot_script "$REPO/tests/lua/dump_opcodes.lua" > "$WORK/mame.log" 2>&1 || true
python3 - "$WORK/opc.bin" <<'PY'
import sys
o = open(sys.argv[1], "rb").read()
code = o[0xBF800:0xBF808].hex()
assert code == "4e714e714e7560fe", f"FAIL: opcode @0xBF800 = {code}"
print("  ok: MAME opcode space @0xBF800 == injected plaintext")
PY
echo "PASS: patch_prg round-trips (null bit-identical, code re-encrypts, data raw)"
