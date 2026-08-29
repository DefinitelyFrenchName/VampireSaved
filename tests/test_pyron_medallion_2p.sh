#!/usr/bin/env bash
# test_pyron_medallion_2p.sh — the P2-HOVER half of medallion palette
# stability (14z-116). EMULATOR gate, ~5 min, two MAME runs. NOT in
# ci_static; indexed in HANDOFF.
#
# WHY THIS EXISTS — it closes a COVERAGE GAP, not just a bug.
# `tests/test_wheel_bank5.sh` section 3b already asserts that all three
# medallion rows hold the vs2 palettes, but both of its stress protocols
# (replays 63 and 64) are SINGLE-PLAYER select stress. Neither has P2 hover
# a tenant's cell — so 3b was structurally unable to see the residual that
# shipped from 14z-64 to 14z-115, and stayed green the whole time while
# Pyron's medallion was visibly wrong on the board.
#
# THE BUG (measured 14z-116, write-tap attributed): palette row 0x1A is
# BOTH Pyron's medallion row (wheel_layout_proposed.json cells.11 pal_row)
# AND the P2 figure family's base+2 "sword accent" slot. Our own 14z-62k
# thunk at `PRG:0x05F9D0` wrote the accent there on a P2 TENANT hover —
# 16 word writes from PCs 0x3FFC60-0x3FFCA6, the thunk's own copy loop —
# turning the medallion into shades of white, sticky until screen re-entry.
#
# THE FIX (maintainer-chosen 14z-116, of three options): the thunk's P2
# branch now exits instead of writing. `tst.b $381(a4)` is followed by
# `bne` to the pop/rts rather than `beq` past an `adda.w #$60,a1`. Same
# byte count, so no allocation ripple. P1's accent (row 0x17) is untouched.
#
# THE TRADE, as the board actually shows it (maintainer, CRT, 2026-08-29 —
# the session's own prediction of "the vanilla grey ramp" was WRONG): the
# P2 sword draws with whatever row 0x1A holds, and that is now Pyron's
# medallion palette — pixels move from steel blue-white (153,170,221) to
# orange-gold (255,136,34), which on Donovan's gold-and-red costume reads
# as the sword being ABSENT. The grey ramp was the PRE-62k state, before a
# medallion lived in that row.
# AND A PARTIAL FIX IS IMPOSSIBLE, measured: the sword and the medallion
# draw from THE SAME entries of row 0x1A (23 shared colours in the rendered
# frame), so the row cannot be split by pen. Do not re-propose "write the
# accent only into the pens the medallion doesn't use".
#
# THE TWO LEGS ARE A PAIR, and neither is sufficient alone:
#   1. P2 hovers Donovan -> row 0x1A must hold PYRON's vs2 palette for the
#      whole screen. Fails if the P2 write ever comes back.
#   2. P1 hovers Donovan -> row 0x17 must RECEIVE the accent. This is the
#      must-fire half: it fails if someone "fixes" leg 1 by disabling the
#      whole thunk, which would silently undo 14z-62k.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged20] tests/test_pyron_medallion_2p.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged20}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN"; exit 0; }
export MAME_BIN
BUILD="$(cd "$BUILD" && pwd)"
. "$REPO/tests/lib/decrypt_cache.sh"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
decrypt_view vsav2 "$W/vs2_op.bin" "$W/vs2_data.bin"

# Paths are computed from the MERGED build's own TABLE B, never vanilla's —
# this port re-pointed cell 0x08's DOWN edge, so vanilla routes are wrong
# on a WIDE build (paid for by the 14z-116 Shadow rig).
#   P2 default 0x05 -> L 0x0A -> D 0x09 -> D 0x13 (Donovan)
#   P1 default 0x01 -> L 0x05 -> L 0x0A -> D 0x09 -> D 0x13
cat > "$W/p2.rpl" <<'EOF'
300-305 sys=C1
330-335 sys=C2
800-803 sys=S1
830-833 sys=S2
1010-1012 p2=L
1050-1052 p2=D
1090-1092 p2=D
3000 wait
EOF
cat > "$W/p1.rpl" <<'EOF'
300-305 sys=C1
800-803 sys=S1
1000-1002 p1=L
1040-1042 p1=L
1080-1082 p1=D
1120-1122 p1=D
3000 wait
EOF

DF="$(python3 -c "print(';'.join(f'{f}:90c000-90c37f' for f in (1200,1400,1800,2400,2900)))")"
run() { # run <tag> <replay>
    mkdir -p "$W/$1"
    DUMPS="$DF" REPLAY="$2" CHECKSUM_OUT="$W/$1/c.log" MAME_SANDBOX="$W/$1/box" \
        MAME_ROMPATH="$BUILD/rompath;$ROMDIR" "$REPO/tools/run_mame.sh" vsavjw \
        -autoboot_script "$REPO/tests/lua/replay.lua" > "$W/$1/mame.log" 2>&1 || {
            echo "FAIL: $1 — MAME run failed"; tail -5 "$W/$1/mame.log"; fail=1; return 1; }
    grep -q '^END ' "$W/$1/c.log" || { echo "FAIL: $1 — no END line"; fail=1; return 1; }
}

echo "== 1. P2 hovers the tenant: Pyron's medallion row 0x1A must HOLD =="
if run p2 "$W/p2.rpl"; then
    python3 - "$W/p2" "$W/vs2_data.bin" <<'PY' || fail=1
import sys, glob
vs2 = open(sys.argv[2], "rb").read()
def alpha(b):
    return bytes(((b[i] | 0xF0) if i % 2 == 0 else b[i]) for i in range(len(b)))
want = alpha(vs2[0x3BB15C:0x3BB15C + 0x20])          # Pyron's vs2 medallion row
files = sorted(glob.glob(sys.argv[1] + "/dump_*.bin"))
assert files, "no dumps"
bad = 0
for f in files:
    fr = f.split("_")[-2]
    got = open(f, "rb").read()[0x1A * 0x20:0x1B * 0x20]
    if got != want:
        print(f"FAIL f{fr}: row 0x1A lost Pyron's palette — head {got[:8].hex()} "
              f"(want {want[:8].hex()}). The P2 sword write is back.")
        bad += 1
print(f"  ok: row 0x1A held Pyron's vs2 palette across {len(files)} samples"
      if not bad else f"  {bad} sample(s) clobbered")
raise SystemExit(1 if bad else 0)
PY
fi

echo "== 2. MUST-FIRE: P1 hovers the tenant — the accent MUST still land on 0x17 =="
if run p1 "$W/p1.rpl"; then
    python3 - "$W/p1" <<'PY' || fail=1
import sys, glob
# The init grey ramp the 14z-62k thunk exists to replace (patch_notes 14z-62k).
GREY = bytes.fromhex("f111f222f333f444")
files = sorted(glob.glob(sys.argv[1] + "/dump_*.bin"), key=lambda p: int(p.split("_")[-2]))
assert files, "no dumps"
late = [f for f in files if int(f.split("_")[-2]) >= 1400]
bad = [f.split('_')[-2] for f in late
       if open(f, "rb").read()[0x17 * 0x20:0x17 * 0x20 + 8] == GREY]
if bad:
    print(f"FAIL: row 0x17 still holds the GREY RAMP at frames {bad} — the P1 half "
          f"of the sword thunk is dead. Leg 1 would pass with the whole thunk "
          f"removed; this leg is what stops that.")
    raise SystemExit(1)
head = open(late[0], "rb").read()[0x17 * 0x20:0x17 * 0x20 + 8].hex()
print(f"  ok: P1's accent still lands on row 0x17 ({len(late)} samples, head {head})")
PY
fi

if [ "$fail" -eq 0 ]; then echo "PASS test_pyron_medallion_2p"; else echo "FAIL test_pyron_medallion_2p"; fi
exit "$fail"
