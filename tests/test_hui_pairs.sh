#!/bin/sh
# test_hui_pairs.sh — Reflect Wall guard-cancel + pair-press gate
# (14z-66, playtest round-1 items 6/7 — the coverage half of item 5).
# Both sections assert the NATIVE-MATCHED signatures measured on the
# A/B of record (replay headers), not just no-crash.
# Usage: ROMDIR=... tests/test_hui_pairs.sh [existing-stage4-builddir]
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   Reflect Wall GC + Dark Force gate (14z-66): both native-matched signatures
#   (GC seq 0x0E + blowback; DF 0x0A at both activations). Self-builds stage 4
#   unless given a build
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
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
if [ $# -ge 1 ]; then BUILD="$1"; echo "== using existing build $BUILD"; else
    echo "== stage 4 build"
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 4 "$WORK/hui4" > "$WORK/build.log" 2>&1 \
        || { tail -15 "$WORK/build.log"; echo "FAIL: build"; exit 1; }
    BUILD="$WORK/hui4"
fi
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no vsavjw.zip"; exit 1; }
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"

echo "== Reflect Wall guard cancel (replay 81)"
d="$WORK/rw"; mkdir -p "$d"
( cd "$d" && POKES="$PK" DUMPS="3225:ff8400-ff8420;3240:ff8800-ff8820" \
  MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
  "$REPO/tools/run_replay_guarded.sh" vsavjw "$REPO/tests/replays/hui/81_hui_rw_gc.rpl" \
      "$d/g.log" "$d/box" > "$d/g.out" 2>&1 ) || {
    echo "FAIL: RW guard tripped:"; grep -m2 -E "CRASH|REGS" "$d/g.log"; exit 1; }
python3 - "$d" <<'PYEOF'
import struct, sys
d = sys.argv[1]
p1 = open("%s/dump_3225_ff8400.bin" % d, 'rb').read()
p2 = open("%s/dump_3240_ff8800.bin" % d, 'rb').read()
x2 = struct.unpack('>i', p2[0x10:0x14])[0] / 65536.0
print("  P1 seq=%02x  attacker x @3240 = %.0f" % (p1[0x06], x2))
if not (p1[0x06] == 0x0E and x2 > 400):
    print("FAIL: GC signature off (native: seq 0x0E + attacker blown past 400)")
    sys.exit(1)
PYEOF
echo "  ok: guard cancel fires, attacker blown back"

# CORRECTED 14z-69 — THIS SECTION IS NOT DARK FORCE. Replay 82 presses
# the P+K pair with an EMPTY meter ($FF8509 = 0 throughout, on both
# games), and DF costs one banked stock: the pair is DOWNGRADED to a
# single button and the match continues normally. seq 0x0A is that
# downgrade path. Real DF is seq 0x16 -> 0x18 with the stock spent and
# the match-level flag $FF802E set — see tests/test_hui_df_style.sh,
# which is the actual Dark Force gate (and the 14z-66 claim "DF
# mechanics are already native-correct" was made from THIS measurement,
# so it is unproven, not established).
# The assertion below is still a good regression on the pair-press
# downgrade path — both games take it identically at both presses — so
# it stays, under its true name.
echo "== pair-press downgrade path, empty meter (replay 82) — NOT Dark Force"
d="$WORK/df"; mkdir -p "$d"
( cd "$d" && POKES="$PK" DUMPS="3110:ff8400-ff8420;4210:ff8400-ff8420" \
  MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
  "$REPO/tools/run_replay_guarded.sh" vsavjw "$REPO/tests/replays/hui/82_hui_df_2p.rpl" \
      "$d/g.log" "$d/box" > "$d/g.out" 2>&1 ) || {
    echo "FAIL: pair-press guard tripped:"; grep -m2 -E "CRASH|REGS" "$d/g.log"; exit 1; }
python3 - "$d" <<'PYEOF'
import sys
d = sys.argv[1]
a = open("%s/dump_3110_ff8400.bin" % d, 'rb').read()
b = open("%s/dump_4210_ff8400.bin" % d, 'rb').read()
print("  pair-press seqs: f3110=%02x f4210=%02x (0x0A = the empty-meter"
      " downgrade, NOT Dark Force — see test_hui_df_style.sh)" % (a[0x06], b[0x06]))
if not (a[0x06] == 0x0A and b[0x06] == 0x0A):
    print("FAIL: pair-press signature off (native: seq 0x0A at both presses)")
    sys.exit(1)
PYEOF
echo "  ok: both pair presses take the native downgrade path"
echo "PASS: Huitzil pair coverage (Reflect Wall GC + pair-press downgrade)"
