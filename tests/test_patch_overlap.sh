#!/bin/sh
# test_patch_overlap.sh — ground truth for the patch_prg op-overlap assertion
# (14z-65, M3b Phase 0). Two ops writing one word must be a BUILD ERROR that
# names both ops; disjoint and word-adjacent ops must stay clean. No emulator.
#
# Usage: ROMDIR=... tests/test_patch_overlap.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   ground truth for the patch_prg op-overlap assertion (14z-65): two ops
#   writing one word is a NAMED build error; disjoint and word-adjacent ops
#   stay clean. ~2s, no emulator
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

echo "== 1: disjoint ops apply cleanly (negative control)"
cat > "$WORK/clean.json" <<'JSON'
{"ops":[{"op":"data","addr":"0xBF800","hex":"cafebabe"},
        {"op":"poke16","addr":"0xBF900","val":"0x1234"}]}
JSON
python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/clean" \
    --patch "$WORK/clean.json" > /dev/null \
    || { echo "FAIL: disjoint ops rejected"; exit 1; }
echo "  ok: disjoint ops accepted"

echo "== 2: word-adjacent ops apply cleanly (no false positive at the seam)"
cat > "$WORK/adjacent.json" <<'JSON'
{"ops":[{"op":"data","addr":"0xBF800","hex":"cafebabe"},
        {"op":"data","addr":"0xBF804","hex":"deadbeef"}]}
JSON
python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/adj" \
    --patch "$WORK/adjacent.json" > /dev/null \
    || { echo "FAIL: word-adjacent ops rejected"; exit 1; }
echo "  ok: word-adjacent ops accepted"

echo "== 3: same-word overlap is a named build error (positive control)"
cat > "$WORK/overlap.json" <<'JSON'
{"ops":[{"op":"poke32","addr":"0xBF800","val":"0x11112222"},
        {"op":"data","addr":"0xBF900","hex":"00ff"},
        {"op":"poke16","addr":"0xBF802","val":"0x3333"}]}
JSON
if python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/ovl" \
    --patch "$WORK/overlap.json" > "$WORK/ovl.log" 2>&1; then
    echo "FAIL: overlapping ops accepted"; exit 1
fi
grep -q "OP OVERLAP at 0x0BF802" "$WORK/ovl.log" \
    || { echo "FAIL: overlap error missing/unnamed:"; cat "$WORK/ovl.log"; exit 1; }
grep -q "op\[0\] poke32@0xBF800" "$WORK/ovl.log" \
    || { echo "FAIL: first writer not named:"; cat "$WORK/ovl.log"; exit 1; }
grep -q "op\[2\] poke16@0xBF802" "$WORK/ovl.log" \
    || { echo "FAIL: second writer not named:"; cat "$WORK/ovl.log"; exit 1; }
echo "  ok: overlap rejected, both ops named with the clash address"

echo "== 4: partial span overlap caught (blob tail into blob head)"
cat > "$WORK/span.json" <<'JSON'
{"ops":[{"op":"data","addr":"0xBF800","hex":"00112233445566778899aabb"},
        {"op":"data","addr":"0xBF80A","hex":"ccddeeff"}]}
JSON
if python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/span" \
    --patch "$WORK/span.json" > "$WORK/span.log" 2>&1; then
    echo "FAIL: span overlap accepted"; exit 1
fi
grep -q "OP OVERLAP at 0x0BF80A" "$WORK/span.log" \
    || { echo "FAIL: span overlap error missing:"; cat "$WORK/span.log"; exit 1; }
echo "  ok: span overlap rejected at the first shared word"

echo "PASS: op-overlap assertion (2 accepts, 2 named rejects)"
