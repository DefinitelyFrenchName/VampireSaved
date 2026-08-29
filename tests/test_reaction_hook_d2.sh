#!/bin/sh
# test_reaction_hook_d2.sh — the #99 fix gate: the reaction_hook D2 WINDOW
# (14z-110, maintainer-ruled 2026-08-26).
#
# WHAT IT LOCKS. The 82-byte reaction_hook thunk on a Donovan-carrying build:
# its bne-arm (the ONLY entry into dispatcher 2 at 0x018508) must carry the
# 0x50-0x53 window dispatching through a second ext table whose four cases are
# BYTE-IDENTICAL to vs2's dispatcher-2 twin handlers — RECONSTRUCTED from the
# reference ROMs, never diffed with a tolerance (the test_index_window_thunk
# pattern: old_hex proves we patched the right place; only reconstruction
# proves the body still means what it meant).
#
# SECTIONS
#   1. the manifest's d2_case_* hex == vs2's OWN handler bytes, re-derived
#      from vsav2.zip: table 0x016DE4 (dispatcher 0x016DDC) entries 0x50-0x53,
#      each read to its rts. A drifted manifest fails here.
#   2. the BUILT image: site 0x018458 is `jmp <thunk>`; the thunk is exactly
#      82 bytes re-assembled from first principles (tst/beq +0x26; d2 window
#      -> et2 -> jmp 0x018508; d1 window -> et -> jmp 0x018460); et2's four
#      longs point at contiguous cases byte-identical to section 1's; and the
#      vanilla dispatcher 0x018508-0x0185B0 (dispatch + 80-entry table) is
#      byte-identical to vsavj's OWN decrypted bytes (ruling (a)) — the
#      oracle is the reference dump, not a build artifact.
#   3. the node DATA matches the frozen census inventory — EMPTY since the
#      14z-110b remap (0x51 -> 0x44, five-consumer equivalence, maintainer GO;
#      'a data remap re-breaks 14z-43/44' was true of 0x19/0x4E, not 0x44).
#   4. VERDICT CONTROLS: a perturbed built case byte, a perturbed et2 long
#      and a perturbed window bound must each FAIL (a checker that cannot
#      fail is not evidence).
#
# No emulator; needs ROMDIR (vsav2 + vsavj oracles) + a built Donovan-carrying
# build. The DYNAMIC leg (force D0=0xA2/A1/A3 at 0x018458 via GUARD_FORCE:
# pre-fix vec3 @ADDR 0x18511, post-fix scratch +0x54 := 0x51) is recorded in
# STATE 14z-110; it needs an emulator and a fighting replay, so it lives there
# and in the guard-corpus soaks rather than in this static gate.
# Usage: ROMDIR=... tests/test_reaction_hook_d2.sh [builddir]   (default build/don_m12)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${1:-build/don_m18}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/verify_op.bin" ] || { echo "SKIP: no verify_op.bin in $BUILD"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in ROMDIR"; exit 0; }
[ -f "$ROMDIR/vsavj.zip" ] || { echo "SKIP: no vsavj.zip in ROMDIR"; exit 0; }

rc=0
python3 - "$BUILD" "$ROMDIR" <<'PY' || rc=1
import struct, sys
from pathlib import Path
sys.path.insert(0, "tools")
import cps2_decrypt as cps
from _minitoml import loads as toml_loads

build, romdir = Path(sys.argv[1]), Path(sys.argv[2])
fail = 0
def ok(m):  print(f"  ok: {m}")
def bad(m):
    global fail; fail = 1; print(f"FAIL: {m}")

def op_view(zpath):
    words, keybytes, prgs, sha1s = cps.load_set(zpath)
    print(f"  oracle {Path(zpath).name}/{prgs[0]} sha1 {sha1s[prgs[0]]}")
    return bytes(cps.words_to_logical_bytes(
        cps.Cipher(keybytes).crypt_words_at(words, 0, decrypt=True)))

vs2 = op_view(romdir / "vsav2.zip")
van = op_view(romdir / "vsavj.zip")

VS2_D2_TAB = 0x016DE4
def vs2_case(idx):
    t = VS2_D2_TAB + struct.unpack(">h", vs2[VS2_D2_TAB + 2*idx:VS2_D2_TAB + 2*idx + 2])[0]
    j = t
    while vs2[j:j+2] != b"\x4e\x75":
        j += 2
        assert j < t + 0x40, "no rts within 0x40 bytes — not a case handler"
    return vs2[t:j+2]
CASES = [vs2_case(0x50 + k) for k in range(4)]

print("== 1: manifest d2_case_* hex == vs2 dispatcher-2 twin handlers (re-derived)")
rh = toml_loads(open("build/manifest/donovan.toml").read())["reaction_hook"]
for k in range(4):
    got = bytes.fromhex(rh[f"d2_case_{0xA0 + 2*k:x}"])
    if got != CASES[k]:
        bad(f"d2_case_{0xA0+2*k:x} != vs2 table[0x{0x50+k:02x}] handler "
            f"({got.hex()} vs {CASES[k].hex()})")
if not fail:
    ok("4/4 d2 cases byte-identical to vs2's own handlers")

print("== 2: built thunk reconstructed from first principles; vanilla dispatcher untouched")
op = (build / "verify_op.bin").read_bytes()
data = (build / "verify_data.bin").read_bytes()

def window(ext_addr, fallthrough):
    return (bytes.fromhex("0c4000a0651a0c4000a86414")     # cmpi/bcs cmpi/bcc
            + bytes.fromhex("3200044100a0d241")            # move/subi/add
            + bytes.fromhex("207c") + ext_addr.to_bytes(4, "big")
            + bytes.fromhex("207010004ed0")
            + bytes.fromhex("4ef9") + fallthrough.to_bytes(4, "big"))

# thunk layout offsets: tst 0-3, beq 4-5, d2 window 6-43, d1 window 44-81;
# inside a window the ext-table address sits at +22..+26.
ET2_OFF, ET_OFF = 6 + 22, 44 + 22

def check_image(op_img, data_img, verbose=False):
    """Return a list of defect strings (empty = good)."""
    defects = []
    site = op_img[0x018458:0x01845E]
    if site[:2] != bytes.fromhex("4ef9"):
        return [f"site 0x018458 is not jmp: {site.hex()}"]
    th = int.from_bytes(site[2:6], "big")
    tk = op_img[th:th+82]
    et2 = int.from_bytes(tk[ET2_OFF:ET2_OFF+4], "big")
    et = int.from_bytes(tk[ET_OFF:ET_OFF+4], "big")
    expect = (bytes.fromhex("4a290038") + bytes.fromhex("6726")
              + window(et2, 0x018508) + window(et, 0x018460))
    if tk != expect:
        defects.append(f"thunk @{th:#x} differs from reconstruction:\n"
                       f"    got  {tk.hex()}\n    want {expect.hex()}")
    t2 = [int.from_bytes(data_img[et2 + 4*i:et2 + 4*i + 4], "big") for i in range(4)]
    o = 0
    for k in range(4):
        got = op_img[t2[k]:t2[k] + len(CASES[k])]
        if got != CASES[k]:
            defects.append(f"built d2 case {k} @{t2[k]:#x} != vs2 handler "
                           f"({got.hex()} vs {CASES[k].hex()})")
        if t2[k] != t2[0] + o:
            defects.append(f"et2 entry {k} not contiguous over the cases blob")
        o += len(CASES[k])
    if verbose and not defects:
        ok(f"thunk @{th:#x} == 82-byte reconstruction (et2 {et2:#x}, et {et:#x})")
        ok("et2 -> 4 built cases byte-identical to vs2, contiguous")
    return defects

for d in check_image(op, data, verbose=True):
    bad(d)

if op[0x018508:0x0185B0] != van[0x018508:0x0185B0]:
    bad("dispatcher 2 (0x018508-0x0185B0) differs from vsavj's own bytes — ruling (a) violated")
else:
    ok("dispatcher 2 + its 80-entry table byte-identical to vsavj's decrypted dump")

print("== 4: verdict controls — the checker must FAIL on perturbation")
if fail == 0:
    site_th = int.from_bytes(op[0x01845A:0x01845E], "big")
    et2_addr = int.from_bytes(op[site_th+ET2_OFF:site_th+ET2_OFF+4], "big")
    case1 = int.from_bytes(data[et2_addr+4:et2_addr+8], "big")
    controls = [
        ("built case byte", "op", case1 + 2),
        ("et2 long",        "data", et2_addr + 6),
        ("window bound",    "op", site_th + 6 + 8),   # the 0xA8 upper-bound byte
    ]
    for name, which, addr in controls:
        bo, do = bytearray(op), bytearray(data)
        (bo if which == "op" else do)[addr] ^= 0x01
        if check_image(bytes(bo), bytes(do)):
            ok(f"perturbed {name} caught")
        else:
            bad(f"perturbed {name} NOT caught — checker cannot fail")
else:
    print("  skipped (section 2 already failing)")
sys.exit(fail)
PY

echo "== 3: node data on the frozen census inventory (EMPTY since 14z-110b)"
if python3 tools/audit_fsm_census.py "$BUILD" --vs2 "$ROMDIR/vsav2.zip" --check build/manifest/fsm_census.toml >/dev/null 2>&1; then
    echo "  ok: fsm census matches the frozen inventory"
else
    echo "FAIL: fsm census drifted — the fix must not touch node data"; rc=1
fi

[ "$rc" = 0 ] && echo "PASS: test_reaction_hook_d2" || echo "FAIL: test_reaction_hook_d2"
exit "$rc"
