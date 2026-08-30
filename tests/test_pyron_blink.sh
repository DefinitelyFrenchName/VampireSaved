#!/bin/sh
# test_pyron_blink.sh — the Pyron sprite/HUD BLINK gate (14z-75).
#
# Palette RAM row 10 (0x90C140) carries Pyron's SPRITE and his in-match
# HUD MUGSHOT — which is why both blinked. Before the fix it alternated
# every frame while native vsav2 held it constant. FIXED in build/pyron17;
# this gate now guards the fix and would make a regression loud.
#
# NOTE this gate only sees the IN-MATCH instance. The same defect lived in
# TWO more tables that drive the SELECT screen and the between-fight ROUTE
# MAP, and pyron16 — which passed this gate — still blinked on both.
# tests/test_variant_dispatch.sh is the gate that covers all three.
#
#   1. NATIVE vs OURS on replay 76, the same script and the same pokes on
#      both legs; tools/check_pyron_blink.py does the verdict.
#   2. VERDICT CONTROLS — the checker's own logic, exercised against
#      synthetic dumps. This file exists because "native is constant" and
#      "native was never measured" look identical in a passing log.
#
# PYRON_BLINK_EXPECT=fixed (the default since the fix) requires ours to
# hold row 10 constant AND equal native's bit-for-bit. =blinks reproduces
# the pre-fix shape — exactly 2 values alternating every frame, one equal
# to native's constant and the other vsavj palette-seq row 0x26 under the
# uploader's 0xF000 OR — and still passes on build/pyron15.
#
# ROOT CAUSE (14z-75): a DEAD ROW, in THREE per-character palette-routine
# jump tables whose rows 0x10-0x1F alias 0x00-0x0F, so row 0x11 gave Pyron
# row 0x01's ANIMATED handler where vs2's row 0x11 is the DEFAULT no-op:
#     0x2A8A4 (in-match)   patch 0x2A8C6  008E -> 0040
#     0x2B650 (select/map) patch 0x2B672  0042 -> 0040
#     0x73790 (select/map) patch 0x737B2  0042 -> 0040
# Each is one word, each set to vs2's own value. Legacy-safe by
# construction — vanilla never puts an id in 0x10-0x1F (audit_id_writers).
#
# The symptom looked like a Dark Force recolour because 0x2AD82 IS the
# DF-family palette-seq resolver (huitzil.toml 14z-69p) — but $FF802E = 0
# on both legs: he was never in Dark Force.
#
# CROSS-TENANT: Huitzil's row 0x10 is 0x004A (row 0x00's handler) where
# vs2's is the default — the same class, latent and currently benign
# (0 hits at 0x2AD82). huitzil-m2 is FROZEN; changing it is a maintainer
# call.
#
# THE PICK GUARD (GitHub #16, fixed 14z-92; hardened 14z-123): each leg's P1
# `+0x60.l` (hitbox base) must be ONE non-zero value for the window AND equal
# Pyron's row of that game's hitbox_base table — never `+0x382`, which is the
# voice-flavor class in match and produced a false REFUSE on the native leg.
# Measured 14z-123 on build/pyron36: native 0x0c75fe, ours 0x0fc6ac, both ==
# their tables' row 0x11.
#
# Usage: ROMDIR=... tests/test_pyron_blink.sh [outbase]
# Env: MAME_BIN, PYRON_BLINK_EXPECT, SKIP_RUNTIME=1 (controls only).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-75: the sprite/HUD BLINK. Palette row 10 (0x90C140) carries Pyron's
#   SPRITE and his in-match HUD MUGSHOT, so both blink. Native vsav2 vs the
#   build on replay 76 (one rig, both games), compared by a PHASE-INDEPENDENT
#   property — distinct row-10 values over 40 CONSECUTIVE frames — because the
#   two games are never on the same frame and a frame-indexed diff produced a
#   confounded figure that stood a whole session. native 1/0 changes, ours
#   2/39. Attribution is part of the verdict: ours' two values must be NAMED
#   (native's constant + vsavj palette-seq row 0x26 under the uploader's
#   0xF000 OR), so a look-alike defect fails. REFUSES to judge unless each
#   leg's +0x60.l (the hitbox base; never +0x382, the in-match voice-flavor
#   byte — #16, fixed 14z-92) is ONE non-zero value AND equals Pyron's row of
#   that game's own hitbox_base table (vs2 data 0xD7B18, the build's 0x3D97A);
#   8 verdict controls incl. a loaded-wrong-character refusal (14z-123; this
#   row carried a "KNOWN WEAKNESS … blocked" note for a fix already shipped at
#   14z-92). FIXED 14z-75 (a DEAD ROW: per-char palette-routine table 0x2A8A4
#   row 0x11 aliased row 0x01's ANIMATED handler; one word 0x2A8C6 008E->0040
#   = vs2's own value). PYRON_BLINK_EXPECT=fixed (default) | blinks
#   (reproduces the pre-fix shape on pyron15). Checker
#   tools/check_pyron_blink.py. Defaults build/pyron30 (14z-103; roll at each
#   freeze)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# DEFAULT RE-POINTED 14z-92 (pyron17, pre-v1.1, MAME-refused) -> pyron26,
# and 14z-103 -> pyron30 (pyron-m13, the current freeze). Every generation
# carries the same blink fix pyron17 introduced. Re-point at each freeze.
BUILD="${1:-build/pyron36}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="${PYRON_BLINK_EXPECT:-fixed}"
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"

RPL="$REPO/tests/replays/pyron/76_pyron_blink_vs2.rpl"
# P1 = Pyron (native id 0x11 on vsav2, the tenant id on ours);
# P2 = Victor (0x03 on BOTH games — without it the cursor path lands on
# different characters on the two wheels).
PK="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
LO=3400
HI=3440
DUMPS="$(python3 -c "
print(';'.join(['%d:ff8400-ff87ff'%f for f in (3200,3400,3600)]
             + ['%d:90c140-90c15f'%f for f in range($LO,$HI)]))")"

VAN="$WORK/vsavj_data.bin"
decrypt_view vsavj "$WORK/vsavj_op.bin" "$VAN"
decrypt_view vsav2 "$WORK/vsav2_op.bin" "$WORK/vsav2_data.bin"
# 14z-123 (inferred_claims row 15): the guard requires each leg's base to be
# PYRON'S OWN ROW of that game's hitbox_base table, read from the images the
# legs run — vs2's data view (bank_map hitbox_base 0x0BD97A + the vs2 origin
# delta = 0xD7B18; anchor row 0x13 == 0x0C8DF8) and the BUILD's prg member
# (0x3D97A, LE-word file order — the audit_continue_switch derivation).
EXPECT_BASE="$(python3 - "$WORK/vsav2_data.bin" "$BUILD/prg/vm3j.04d" <<'PY'
import struct, sys
v2 = open(sys.argv[1], "rb").read()
t2 = struct.unpack(">32I", v2[0xD7B18:0xD7B18 + 128])
assert t2[0x13] == 0x0C8DF8, "vs2 hitbox_base anchor moved (bank_map.toml)"
data = open(sys.argv[2], "rb").read()
raw = data[0x3D97A:0x3D97A + 128]
sw = bytearray()
for i in range(0, 128, 2):
    sw += raw[i+1:i+2] + raw[i:i+1]
tj = struct.unpack(">32I", bytes(sw))
print(f"native={t2[0x11]:#x},ours={tj[0x11]:#x}")
PY
)"

if [ "${SKIP_RUNTIME:-0}" = 1 ]; then
    echo "== 1. native vs ours: SKIPPED (SKIP_RUNTIME=1)"
else
    [ -f "$BUILD/rompath/vsavjw.zip" ] || {
        echo "FAIL: no $BUILD/rompath/vsavjw.zip (WIDE tenant build required)"
        exit 1; }
    echo "== 1. native (vsav2) vs ours ($BUILD), replay 76, expect: $EXPECT"
    for tag in native ours; do
        d="$WORK/$tag"; mkdir -p "$d/s1"
        if [ "$tag" = native ]; then
            set_=vsav2; unset MAME_ROMPATH || true
        else
            set_=vsavjw; MAME_ROMPATH="$BUILD/rompath;$ROMDIR"
            export MAME_ROMPATH
        fi
        ( cd "$d" && POKES="$PK" DUMPS="$DUMPS" \
          "$REPO/tools/run_replay_mame.sh" "$set_" "$RPL" "$d/ram.log" \
          "$d/s1" > "$d/out" 2>&1 ) || {
            tail -5 "$d/out"; echo "FAIL: $tag leg did not complete"
            exit 1; }
    done
    python3 tools/check_pyron_blink.py "$WORK/native" "$WORK/ours" "$VAN" \
        "$LO" "$HI" --expect "$EXPECT" --expect-base "$EXPECT_BASE" || fail=1
fi

echo "== 2. verdict controls (the checker's own logic)"
CTL="$WORK/ctl"
python3 - "$CTL" "$VAN" "$LO" "$HI" <<'PY'
import os, sys
sys.path.insert(0, "tools")
from check_pyron_blink import seq_to_palette, SEQ_ROW_26, HB_OFF
ctl, van, lo, hi = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
vj = open(van, "rb").read()
good = bytes.fromhex("fe00ff60ff90ffb0ffd0fff0fffbfffffdfffafff0fff0dff0bff09ff07ff000")
seq = seq_to_palette(vj[SEQ_ROW_26:SEQ_ROW_26 + 0x20])
other = bytes(32)

# 14z-92 (#16): the guard reads +0x60.l (hitbox base), not +0x382. A
# synthetic leg therefore needs a plausible NON-ZERO base; base 0 is the
# "no fighter was loaded" case the guard must refuse.
PYRON_BASE = 0x00093B6A   # measured on build/pyron26, force_pick_probe
def mk(name, ours_vals, nat_vals=None, base=PYRON_BASE):
    d = os.path.join(ctl, name)
    for legname, vals in (("native", nat_vals or [good] * (hi - lo)),
                          ("ours", ours_vals)):
        p = os.path.join(d, legname); os.makedirs(p, exist_ok=True)
        for i, f in enumerate(range(lo, hi)):
            open(os.path.join(p, "dump_%d_90c140.bin" % f), "wb").write(vals[i])
        blk = bytearray(0x400); blk[HB_OFF:HB_OFF + 4] = base.to_bytes(4, "big")
        for f in (3200, 3400, 3600):
            open(os.path.join(p, "dump_%d_ff8400.bin" % f), "wb").write(bytes(blk))

n = hi - lo
mk("real",        [good if i % 2 else seq for i in range(n)])
mk("noblink",     [good] * n)
mk("wrongsource", [good if i % 2 else other for i in range(n)])
mk("notpicked",   [good if i % 2 else seq for i in range(n)], base=0)
mk("wrongchar",   [good if i % 2 else seq for i in range(n)], base=0x0009769E)  # Victor, loaded
mk("natmoves",    [good if i % 2 else seq for i in range(n)],
   nat_vals=[good if i % 3 else other for i in range(n)])
print("   built: real, noblink, wrongsource, notpicked, wrongchar, natmoves")
PY

# the synthetic legs carry PYRON_BASE on both sides, so that is the expected
# base for the controls; wrongchar carries Victor's and must be refused.
CTL_BASE="native=0x93b6a,ours=0x93b6a"
ctl_case() {  # name expect want(pass|fail) why
    if python3 tools/check_pyron_blink.py "$CTL/$1/native" "$CTL/$1/ours" \
            "$VAN" "$LO" "$HI" --expect "$2" --expect-base "$CTL_BASE" > "$WORK/c.txt" 2>&1
    then got=pass; else got=fail; fi
    if [ "$got" = "$3" ]; then
        echo "  ok: $1 (--expect $2) -> $got  [$4]"
    else
        echo "  FAIL: $1 (--expect $2) -> $got, wanted $3  [$4]"
        sed 's/^/       /' "$WORK/c.txt"; fail=1
    fi
}
ctl_case real        blinks pass "the frozen shape is accepted"
ctl_case noblink     blinks fail "a build that does NOT blink must not pass 'blinks'"
ctl_case noblink     fixed  pass "...and is exactly what 'fixed' accepts"
ctl_case real        fixed  fail "the blink must not pass as fixed"
ctl_case wrongsource blinks fail "a 2-value blink from the WRONG source is a different defect"
ctl_case notpicked   blinks fail "a leg where Pyron was never picked must be refused"
ctl_case wrongchar   fixed  fail "a leg where a DIFFERENT character was loaded must be refused (14z-123)"
ctl_case natmoves    blinks fail "a native leg that is NOT constant invalidates the reference"

if [ "$fail" -ne 0 ]; then echo "FAIL: pyron blink gate"; exit 1; fi
echo "PASS: pyron blink gate (native/ours per-leg row-10 variance +"
echo "      mechanism attribution + per-leg Pyron-base guard + 8 verdict controls)"
