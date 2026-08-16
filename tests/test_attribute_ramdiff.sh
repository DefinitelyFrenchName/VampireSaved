#!/bin/sh
# test_attribute_ramdiff.sh — ground truth for tools/attribute_ramdiff.py
# (14z-90, GitHub issue #21).
#
# WHY. `find_dump()` tries two patterns, and the second is DIRECTORY scoped:
#     <log>.dump_<frame>_*.bin        (FBNeo harness — log-scoped, safe)
#     <dir>/dump_<frame>_*.bin        (MAME replay.lua — directory-scoped)
# So when both logs live in one directory — a real shape here
# (tests/test_m2_repoint.sh:33, test_m2b_scroll3.sh:33,
# test_merged_render_content.sh:165 all put two MAME logs in one dir) — both
# sides resolve to the SAME file, the comparison is a file against itself, and
# the tool printed a "note: the dumps are IDENTICAL" and returned 0.
#
# A gate whose PASS is guaranteed by construction is not a gate. That is the
# same class as the "identical = dead rig" rule the project already applies in
# tests/audit_merged_legacy.sh.
#
# NOTE this file also pins the honest half: a genuine zero-diff between two
# DISTINCT dumps is still a note-and-pass, because there the identity is a
# measurement rather than an artefact of path resolution. The fix must not
# blur those two.
#
# Usage: tests/test_attribute_ramdiff.sh   (no ROMs, no emulator, ~1s)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0
T=tools/attribute_ramdiff.py

mkdiff() {  # mkdiff <path> <byte-at-16>
    python3 - "$1" "$2" <<'PY'
import sys
b = bytearray(64)
b[16] = int(sys.argv[2])
open(sys.argv[1], "wb").write(bytes(b))
PY
}

# --- 1. two logs in ONE directory: both sides resolve to the same dump ----
echo "== 1. two MAME logs sharing a directory =="
D="$WORK/shared"; mkdir -p "$D"
: > "$D/a.log"; : > "$D/b.log"
mkdiff "$D/dump_4400_ff0000.bin" 0
set +e; out=$(python3 "$T" "$D/a.log" "$D/b.log" 4400 --window 0-3f:everything 2>&1); rc=$?; set -e
if [ "$rc" != 0 ] && echo "$out" | grep -q "SAME dump file"; then
    echo "  ok: refused, and named the collision"
else
    echo "FAIL: comparing a file with itself did not fail (rc=$rc)"
    echo "$out" | head -3; fail=1
fi

# --- 2. POSITIVE CONTROL: distinct dumps still compare normally ----------
# Without this, a tool that always failed would satisfy case 1.
echo "== 2. distinct dumps, a difference inside a named window =="
A="$WORK/a"; B="$WORK/b"; mkdir -p "$A" "$B"
: > "$A/a.log"; : > "$B/b.log"
mkdiff "$A/dump_4400_ff0000.bin" 0
mkdiff "$B/dump_4400_ff0000.bin" 9
set +e; out=$(python3 "$T" "$A/a.log" "$B/b.log" 4400 --window 0-3f:everything 2>&1); rc=$?; set -e
if [ "$rc" = 0 ]; then
    echo "  ok: a real diff inside a named window passes"
else
    echo "FAIL: a legitimate comparison was rejected (rc=$rc)"
    echo "$out" | head -3; fail=1
fi

# --- 3. a stray byte OUTSIDE every named window must still fail ---------
echo "== 3. an unattributed byte =="
set +e; out=$(python3 "$T" "$A/a.log" "$B/b.log" 4400 --window 0-0f:head 2>&1); rc=$?; set -e
[ "$rc" != 0 ] && echo "  ok: unattributed byte rejected" \
   || { echo "FAIL: a byte outside every window passed"; fail=1; }

# --- 4. genuinely identical DISTINCT dumps stay a note, not a failure ---
echo "== 4. two distinct files that happen to be identical =="
mkdiff "$B/dump_4400_ff0000.bin" 0
set +e; out=$(python3 "$T" "$A/a.log" "$B/b.log" 4400 --window 0-3f:everything 2>&1); rc=$?; set -e
if [ "$rc" = 0 ] && echo "$out" | grep -q "IDENTICAL"; then
    echo "  ok: a measured identity is still a note (not conflated with the collision)"
else
    echo "FAIL: a genuine zero-diff between distinct files was mishandled (rc=$rc)"; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: attribute_ramdiff (same-file collision refused, 3 controls)" \
    || { echo "FAIL: attribute_ramdiff"; exit 1; }
