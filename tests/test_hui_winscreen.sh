#!/bin/sh
# test_hui_winscreen.sh — the Huitzil WIN-SCREEN gate (14z-68m).
#
# Locks the two fixes the maintainer confirmed on ping #10, both of
# which were shipped WRONG once and would regress silently:
#
#   1. PALETTE. The win drawer remaps the char id through the byte
#      table at vs2 0x6B2F2 (OPCODE view) before indexing the pool, so
#      H is row 0x0B = 0x3C2BBC + 0x0B*0xA0 = 0x3C329C. Build 14z-68h
#      shipped 0x3C635C, which is DONOVAN's row at colour 4 — the
#      screen went pink/lavender. This leg asserts the built block is
#      byte-identical to vs2's row-0x0B sets AND that the row's
#      self-labelling marker (last word of each 0x20-byte row = 5*row)
#      says 0x0B, which is the check that would have caught it.
#
#   2. POSITION. The portrait's coords come from the per-winner table
#      0x5F200 (4B/char, CODE rows). vsavj row 0x10 is a plain alias
#      (0x0080,0x0098); vs2's is (0x00C0,0x0080) — H was drawn 64px
#      too far LEFT and 24px too low.
#
# Static by design (no emulator): both are build-image facts, so the
# gate is seconds rather than minutes and can run on every build.
# The in-emulator confirmation lives in the session record — palette
# RAM at rows 0x15-0x19 reads vs2's gold ramp under F000-alpha.
#
# Usage: ROMDIR=... tests/test_hui_winscreen.sh [existing-stage6-build]
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ $# -ge 1 ]; then
    BUILD="$1"
else
    echo "== stage 6 build"
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 6 "$WORK/hui6" > "$WORK/build.log" 2>&1 \
        || { tail -15 "$WORK/build.log"; echo "FAIL: build"; exit 1; }
    BUILD="$WORK/hui6"
fi
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/verify_data.bin" ] || { echo "FAIL: no verify_data.bin in $BUILD"; exit 1; }

python3 - "$BUILD" <<'PY' || exit 1
import json, struct, sys
build = sys.argv[1]
built  = open(f"{build}/verify_data.bin", "rb").read()
builtop= open(f"{build}/verify_op.bin",   "rb").read()
d2     = open("build/out/vsav2_data.bin", "rb").read()
o2     = open("build/out/vsav2_opcodes.bin","rb").read()
oj     = open("build/out/vsavj_opcodes.bin","rb").read()
fail = 0

POOL, UNIT, CSTRIDE = 0x3C2BBC, 0xA0, 0xB40
TBL = 0x6B2F2                      # the id -> row remap, OPCODE view

# --- 0. the remap table view is the one Donovan's frozen row proves --
don_row = o2[TBL + 0x13]
if POOL + don_row * UNIT == 0x3C365C:
    print(f"  ok: remap table read via the OPCODE view (Donovan row {don_row:#04x} "
          f"-> 0x3C365C, his frozen vs2_src)")
else:
    print(f"  FAIL: opcode-view table[0x13]={don_row:#04x} does not reproduce "
          f"Donovan's frozen 0x3C365C — wrong view or wrong table"); fail = 1

hui_row = o2[TBL + 0x10]
src = POOL + hui_row * UNIT
if src == 0x3C329C:
    print(f"  ok: Huitzil row {hui_row:#04x} -> {src:#08x}")
else:
    print(f"  FAIL: Huitzil row {hui_row:#04x} -> {src:#08x}, expected 0x3C329C"); fail = 1

# --- 1. the self-labelling marker: last word of each 0x20 row == 5*row
markers = [struct.unpack('>H', d2[src + r*0x20 + 0x1E: src + r*0x20 + 0x20])[0]
           for r in range(5)]
want = [5*hui_row + k for k in range(5)]
if markers == want:
    print(f"  ok: row markers {[hex(m) for m in markers]} == 5*row — the block "
          f"self-identifies as row {hui_row:#04x}")
else:
    print(f"  FAIL: row markers {[hex(m) for m in markers]} != {[hex(w) for w in want]} "
          f"— this block belongs to a DIFFERENT character (the 14z-68h bug)"); fail = 1

# --- 2. the built sparse block carries vs2's 8 colour sets ------------
pl = json.load(open(f"{build}/patch/placements.json"))
blk = None
import re
notes = open(f"{build}/patch/patch_notes_fragment.md").read()
m = re.search(r"data\s+0x([0-9a-f]+)\s+\+0x[0-9a-f]+\s+win_pal_variant", notes)
if m:
    blk = int(m.group(1), 16)
if blk is None:
    print("  FAIL: no 0x4B00 win-pal sparse block in the patch"); fail = 1
else:
    base = blk                        # the notes' address IS colour 0's set
                                      # (the thunk pre-biases a0 = block - id*0xA0)
    ok = all(d2[src + i*CSTRIDE: src + i*CSTRIDE + UNIT] ==
             built[base + i*0xAA0: base + i*0xAA0 + UNIT] for i in range(8))
    if ok:
        print(f"  ok: all 8 colour sets at {base:#08x} byte-identical to vs2 {src:#08x}")
    else:
        print(f"  FAIL: the built colour sets do not match vs2 {src:#08x}"); fail = 1

# --- 3. the portrait POSITION row (CODE words) ------------------------
TJ, T2 = 0x5F200, 0x6B210
want_x = struct.unpack('>H', o2[T2 + 4*0x10:     T2 + 4*0x10 + 2])[0]
want_y = struct.unpack('>H', o2[T2 + 4*0x10 + 2: T2 + 4*0x10 + 4])[0]
got_x  = struct.unpack('>H', builtop[TJ + 4*0x10:     TJ + 4*0x10 + 2])[0]
got_y  = struct.unpack('>H', builtop[TJ + 4*0x10 + 2: TJ + 4*0x10 + 4])[0]
van_x  = struct.unpack('>H', oj[TJ + 4*0x10:     TJ + 4*0x10 + 2])[0]
if (got_x, got_y) == (want_x, want_y):
    print(f"  ok: portrait position row 0x10 = ({got_x:#06x},{got_y:#06x}) = vs2's")
else:
    print(f"  FAIL: portrait position row 0x10 = ({got_x:#06x},{got_y:#06x}), "
          f"expected vs2's ({want_x:#06x},{want_y:#06x})"); fail = 1
if got_x != van_x:
    print(f"  ok: and it is no longer the vanilla alias ({van_x:#06x} = 64px too far left)")
else:
    print("  FAIL: position row is still the vanilla alias"); fail = 1
sys.exit(fail)
PY

echo "PASS: Huitzil win screen (palette source + self-marker + 8 colour sets + position)"
