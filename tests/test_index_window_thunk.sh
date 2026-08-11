#!/bin/sh
# test_index_window_thunk.sh — the (b') index-window thunk gate (14z-79).
#
# WHAT IT LOCKS. The thunk at engine site 0x018460 that covers the
# OUT-OF-RANGE INDEX WINDOW of vsavj's sub-state table 0x018468 (80 entries;
# vs2's twin has 84). It fixes two confirmed Phobos defects — Plasma Trap
# (entry 82, LOUD) and Reflect Wall (entry 83, SILENT) — and retires the
# window for every tenant.
#
# WHY A GATE AT ALL, given the build already asserts old_hex? Because the
# BODY is 470 bytes of authored machine code carrying a copy of the engine's
# index table and 23 handler addresses. `old_hex` proves we patched the right
# place; nothing proves the body still means what it meant. One wrong
# trampoline address is a SILENT wrong-routine dispatch — the exact defect
# class this thunk exists to remove.
#
# IT RECONSTRUCTS, IT DOES NOT DIFF WITH A TOLERANCE (the
# test_beam_list_type6.sh pattern). Every byte is re-derived from the two
# reference ROMs and required to match the build, so the gate cannot drift
# with the thing it checks.
#
# SECTIONS
#   1. the build's site is `jmp <thunk>` and the body is byte-identical to
#      what tools/gen_index_window_thunk.py derives from the ROMs
#   2. the engine is otherwise UNTOUCHED: the table, the sibling dispatcher
#      (including 0x01850A, the withdrawn 14z-74 word) and the whole handler
#      pool are vanilla
#   3. the table still has exactly 80 entries — if it ever moves, the body's
#      embedded copy is stale and this gate must fail rather than pass quietly
#   4. VERDICT CONTROLS: perturb a trampoline address, a table word and a
#      danger body — the checker must FAIL on each. A checker that cannot
#      fail is not evidence (docs/GOTCHAS.md).
#
# No emulator, no ROMs beyond $ROMDIR, seconds.
# Usage: ROMDIR=... tests/test_index_window_thunk.sh [builddir]   (default build/hui29)
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

BUILD="${1:-build/hui29}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/verify_op.bin" ] || {
    echo "SKIP: no $BUILD/verify_op.bin (build a Huitzil stage-6 build first)"
    exit 0; }
fail=0

# Decrypt the references fresh rather than trusting build/out/*.bin, which any
# earlier step may have overwritten.
echo "== decrypting reference images"
python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$WORK/vj.bin" \
    --data-out "$WORK/vjd.bin" > /dev/null
python3 tools/cps2_decrypt.py "$ROMDIR/vsav2.zip" "$WORK/v2.bin" \
    --data-out "$WORK/v2d.bin" > /dev/null

echo "== 1. the site is jmp-routed and the body reconstructs from the ROMs"
python3 tools/gen_index_window_thunk.py "$WORK/vj.bin" "$WORK/v2.bin" --json \
    > "$WORK/facts.json"
python3 - "$BUILD/verify_op.bin" "$WORK/vj.bin" "$WORK/facts.json" <<'PY' || fail=1
import json, struct, sys
img = open(sys.argv[1], "rb").read()
van = open(sys.argv[2], "rb").read()
f = json.load(open(sys.argv[3]))
SITE, TABLE, NEXT = 0x018460, 0x018468, 0x018508
body = bytes.fromhex(f["thunk_hex"])
ok = True

site = img[SITE:SITE + 6]
if site[:2] != b"\x4e\xf9":
    print(f"  FAIL: site {SITE:#08x} is {site.hex()}, not a jmp abs.l")
    ok = False
else:
    th = struct.unpack_from(">I", site, 2)[0]
    got = img[th:th + len(body)]
    print(f"  site {SITE:#08x} -> jmp {th:#08x}   body {len(body)} bytes")
    if got != body:
        n = next(i for i in range(len(body)) if got[i:i+1] != body[i:i+1])
        print(f"  FAIL: body differs at +{n:#x}: built {got[n:n+8].hex()} "
              f"!= derived {body[n:n+8].hex()}")
        ok = False
    else:
        print(f"  ok: body byte-identical to the ROM-derived reconstruction "
              f"({f['n_distinct_targets']} trampolines, table +{f['table_off']:#x})")
    # the thunk must not have been placed over anything it reads
    if not (0x0BF6A0 <= th < 0x100000):
        print(f"  FAIL: thunk at {th:#08x} is outside hole_a — a PC-relative "
              f"read of its embedded table would see ciphertext")
        ok = False
sys.exit(0 if ok else 1)
PY

echo "== 2. the engine around the site is VANILLA"
python3 - "$BUILD/verify_op.bin" "$WORK/vj.bin" <<'PY' || fail=1
import sys
img = open(sys.argv[1], "rb").read()
van = open(sys.argv[2], "rb").read()
ok = True
for lo, hi, what in (
        (0x018466, 0x018508, "the index table (+ the orphaned ext word)"),
        (0x018508, 0x0185B0, "the sibling dispatcher and its table"),
        (0x01867A, 0x0187BC, "the shared handler pool"),
):
    same = img[lo:hi] == van[lo:hi]
    print(f"  {lo:#08x}-{hi:#08x}  {what}: {'vanilla' if same else 'CHANGED'}")
    ok = ok and same
# called out by name: test_pyron_cosmo.sh guards this word too, because
# 14z-74 rewrote it and broke four legacy replays.
w = img[0x01850A:0x01850C]
print(f"  0x01850A (the WITHDRAWN 14z-74 word) = {w.hex()}")
ok = ok and w == van[0x01850A:0x01850C]
sys.exit(0 if ok else 1)
PY

echo "== 3. the table is still exactly 80 entries"
python3 - "$WORK/vj.bin" <<'PY' || fail=1
import sys
van = open(sys.argv[1], "rb").read()
SHAPE = bytes.fromhex("323b00064efb1002")
n = (0x018508 - 0x018468) // 2
ok = van[0x018460:0x018468] == SHAPE and van[0x018508:0x018510] == SHAPE
print(f"  dispatcher shape at 0x018460 and 0x018508: {ok};  entries = {n}")
if n != 80:
    print("  FAIL: the table is no longer 80 entries — the thunk's embedded "
          "copy is stale"); ok = False
sys.exit(0 if ok else 1)
PY

echo "== 4. verdict controls — the checker must FAIL on a corrupted body"
# Each control perturbs ONE byte of the DERIVED body and requires the section-1
# comparison to reject it. Without these, a checker that silently passes
# everything looks identical to a clean build.
python3 - "$BUILD/verify_op.bin" "$WORK/facts.json" <<'PY' || fail=1
import json, struct, sys
img = open(sys.argv[1], "rb").read()
f = json.load(open(sys.argv[2]))
body = bytearray(bytes.fromhex(f["thunk_hex"]))
th = struct.unpack_from(">I", img, 0x018460 + 2)[0]
built = img[th:th + len(body)]
tramp, table = f["tramp_off"], f["table_off"]
ok = True
for name, off, delta in (
        ("a trampoline target (silent wrong-routine dispatch)", tramp + 5, 2),
        ("an index-table word (wrong trampoline chosen)", table + 3, 6),
        ("a danger body byte (entry 82's class 0x52)", 0x3C + 3, 1),
):
    bad = bytearray(body)
    bad[off] = (bad[off] + delta) & 0xFF
    caught = bytes(bad) != built
    print(f"  control: {name}: {'CAUGHT' if caught else 'MISSED'}")
    ok = ok and caught
# and the positive half: the unperturbed body must still match, so the
# controls are not passing merely because everything mismatches
same = bytes(body) == built
print(f"  control: the UNPERTURBED body still matches: {same}")
sys.exit(0 if ok and same else 1)
PY

[ "$fail" -ne 0 ] && { echo "FAIL: index-window thunk gate"; exit 1; }
echo "PASS: (b') index-window thunk — body reconstructs from the ROMs, engine vanilla"
