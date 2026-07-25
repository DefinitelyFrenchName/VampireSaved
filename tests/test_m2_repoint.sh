#!/bin/sh
# test_m2_repoint.sh — proves the M2 slot-replacement mechanism on trusted
# vanilla tooling: repointing a bank-table slot entry takes effect in a live
# game, AND the superset invariant holds (only content involving the modified
# slot changes).
#
# Experiment: repoint vsavj Jedah's (slot 0x0F) hitbox-base entry in table
# PRG:0x0BD97A to Demitri's (slot 0x01, 0x093B6A). Then:
#   1. in a live match, picking Jedah loads 0x093B6A at RAM:$FF8460;
#   2. all legacy replays NOT involving Jedah are bit-identical to vanilla;
#   3. the attract replay is bit-identical up to frame 4277 and diverges at
#      4278 — exactly where its CPU demo shows Jedah (char id 0x0F verified).
#
# Usage: ROMDIR=... tests/test_m2_repoint.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- build the repointed set ---
cat > "$WORK/patch.json" <<'JSON'
{"ops":[{"op":"poke32","addr":"0xBD9B6","val":"0x00093B6A"}]}
JSON
# 0xBD9B6 = table 0xBD97A + slot 0x0F * 4
python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/prg" --patch "$WORK/patch.json" > "$WORK/p.log"
grep -q "^1 member(s) changed" "$WORK/p.log" || { echo "FAIL: expected exactly 1 changed member"; exit 1; }
ROMDIR="$ROMDIR" "$REPO/tools/pack_build.sh" "$WORK/prg" "$WORK/prom" > /dev/null
RP="$WORK/prom;$ROMDIR"

run() { # replay -> checksum log (patched build, sandboxed)
    MAME_ROMPATH="$RP" REPLAY="$REPO/tests/replays/$1.rpl" CHECKSUM_OUT="$WORK/$1.log" \
        MAME_SANDBOX="$WORK/$1box" "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
}

# --- 1. repoint takes effect in a live game ---
cat > "$WORK/pick_jedah.rpl" <<'EOF'
300-305 sys=C1
800-803 sys=S1
1000-1002 p1=U
1040-1042 p1=U
1080-1082 p1=R
1700-1702 p1=1
EOF
DUMPS="3600:ff8460-ff8464" MAME_ROMPATH="$RP" REPLAY="$WORK/pick_jedah.rpl" \
    CHECKSUM_OUT="$WORK/pj.log" MAME_SANDBOX="$WORK/pjbox" "$REPO/tools/run_mame.sh" vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
# RAM dumps land next to CHECKSUM_OUT
HB=$(xxd -p "$(dirname "$WORK/pj.log")/dump_3600_ff8460.bin")
case "$HB" in
    000b0d2e*) echo "FAIL: patched Jedah still uses vanilla base 0x0B0D2E"; exit 1 ;;
    00093b6a*) echo "  ok: patched Jedah loads Demitri hitbox base 0x093B6A" ;;
    *) echo "FAIL: unexpected hitbox base $HB"; exit 1 ;;
esac

# --- 2. superset: non-Jedah replays bit-identical ---
fail=0
for r in 02_demitri_vs_cpu 03_two_player_vs 05_timeout_idle 06_test_mode 07_mash_storm 10_midattract_start; do
    run "$r"
    got=$(shasum "$WORK/$r.log" | cut -d' ' -f1)
    exp=$(cat "$REPO/tests/expected/vsavj/$r.sha1")
    if [ "$got" = "$exp" ]; then echo "  ok: $r bit-identical"; else echo "FAIL: $r diverged"; fail=1; fi
done

# --- 3. attract identical until Jedah appears (frame 4278) ---
run 01_attract_long
# fresh vanilla attract (same sandboxed runner, ROMDIR only) for frame-level compare
MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/01_attract_long.rpl" \
    CHECKSUM_OUT="$WORK/van_attract.log" MAME_SANDBOX="$WORK/vanbox" "$REPO/tools/run_mame.sh" vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
DIV=$(python3 - "$WORK/van_attract.log" "$WORK/01_attract_long.log" <<'PY'
import sys
a=[l.split() for l in open(sys.argv[1]) if not l.startswith("END")]
b=[l.split() for l in open(sys.argv[2]) if not l.startswith("END")]
for i in range(min(len(a),len(b))):
    if a[i][1]!=b[i][1]:
        print(a[i][0]); break
else:
    print("none")
PY
)
if [ "$DIV" = "4278" ]; then
    echo "  ok: attract bit-identical through 4277, diverges at 4278 (Jedah demo)"
else
    echo "FAIL: attract diverged at frame $DIV (expected 4278)"; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: repoint mechanism + superset invariant proven" || { echo "SUITE RED"; exit 1; }
