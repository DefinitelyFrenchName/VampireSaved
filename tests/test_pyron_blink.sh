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
# Usage: ROMDIR=... tests/test_pyron_blink.sh [outbase]
# Env: MAME_BIN, PYRON_BLINK_EXPECT, SKIP_RUNTIME=1 (controls only).
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# DEFAULT RE-POINTED 14z-92: was build/pyron17, which predates WIDE v1.1/v1.2
# and is REFUSED by MAME today ("vsw.z01 NOT FOUND") — the same stale-reference
# class as hui31 in test_merged_render_content and pyron20 in
# audit_hitclass_map_cost, all three found the same session. pyron-m9 carries
# the same blink fix pyron17 did. RE-POINT THIS WHEN PYRON IS RE-FROZEN.
BUILD="${1:-build/pyron26}"
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
python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$WORK/vsavj_op.bin" \
    --data-out "$VAN" > /dev/null

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
        "$LO" "$HI" --expect "$EXPECT" || fail=1
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
mk("natmoves",    [good if i % 2 else seq for i in range(n)],
   nat_vals=[good if i % 3 else other for i in range(n)])
print("   built: real, noblink, wrongsource, notpicked, natmoves")
PY

ctl_case() {  # name expect want(pass|fail) why
    if python3 tools/check_pyron_blink.py "$CTL/$1/native" "$CTL/$1/ours" \
            "$VAN" "$LO" "$HI" --expect "$2" > "$WORK/c.txt" 2>&1
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
ctl_case natmoves    blinks fail "a native leg that is NOT constant invalidates the reference"

if [ "$fail" -ne 0 ]; then echo "FAIL: pyron blink gate"; exit 1; fi
echo "PASS: pyron blink gate (native/ours per-leg row-10 variance +"
echo "      mechanism attribution + 7 verdict controls)"
