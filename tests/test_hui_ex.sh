#!/bin/sh
# test_hui_ex.sh — Huitzil EX-move gate (14z-66, playtest round-1 item 1).
#
# The maintainer's round-1 report: both EX moves (Final Guardian 623+2K,
# Erasing Sphere 421+2K) ran most of their animation then crash-reset
# (watchdog signature). Root cause (measured, replay 72): the ES flow's
# one-shot voice cue (x0689cc+0xec) reached the open sound-farm tripwire
# for vs2 0x4EFA (sfx id 0x748, newcomer voice range) — ILLEGAL in a
# plain run = garbage vector = watchdog reset. Fix: three stubbed_sound
# overlay rows (0x4efa/0x4fb0/0x4fca, ids 0x748/0x729/0x72e).
#
# This gate re-runs both scripted EX repros guarded and asserts BOTH
# halves of each verdict:
#   1. guard CLEAN end-to-end (no tripwire/fault on the EX flows);
#   2. STOCK CONSUMED (ff8509 decrements from the poked 9) — proof the
#      ES version actually fired; without this the gate would stay green
#      if input timing drift stopped the move from coming out at all
#      (the 14z-44 "silent soak coverage loss" mechanism).
#
# Usage: ROMDIR=... tests/test_hui_ex.sh [existing-stage4-builddir]
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ $# -ge 1 ]; then
    BUILD="$1"
    echo "== using existing build $BUILD"
else
    echo "== stage 4 build"
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 4 "$WORK/hui4" > "$WORK/build.log" 2>&1 \
        || { tail -15 "$WORK/build.log"; echo "FAIL: build"; exit 1; }
    BUILD="$WORK/hui4"
fi
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no vsavjw.zip (WIDE build required)"; exit 1; }
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"

# frame:file pairs chosen per replay: a dump before the first possible
# fire (stock must read the poked 9) and the final dump (must be < 9).
run_ex() {
    rpl="$1"; label="$2"; lastdump="$3"
    dir="$WORK/$label"; mkdir -p "$dir"
    ( cd "$dir" && \
      POKES="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10;3000:ff8509:09" \
      DUMPS="3200:ff8500-ff8510;$lastdump:ff8500-ff8510" \
      MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
      "$REPO/tools/run_replay_guarded.sh" vsavjw "$REPO/tests/replays/hui/$rpl" \
          "$dir/g.log" "$dir/box" > "$dir/g.out" 2>&1 ) || {
        echo "FAIL: $label guard tripped:"
        grep -m2 -E "CRASH|REGS" "$dir/g.log" || tail -5 "$dir/g.out"
        exit 1
    }
    pre="$(xxd -p -s 9 -l 1 "$dir/dump_3200_ff8500.bin")"
    post="$(xxd -p -s 9 -l 1 "$dir/dump_${lastdump}_ff8500.bin")"
    [ "$pre" = "09" ] || { echo "FAIL: $label stock poke missing (pre=$pre)"; exit 1; }
    if [ "$post" = "09" ]; then
        echo "FAIL: $label no stock consumed (post=$post) — EX never fired (coverage loss)"
        exit 1
    fi
    echo "  ok: $label guard clean, EX fired (stock 09 -> $post)"
}

# case-sensitivity note: BUILD may be absolute already
case "$BUILD" in /*) BUILD_ABS="$BUILD" ;; *) BUILD_ABS="$REPO/$BUILD" ;; esac
BUILD="$BUILD_ABS"

echo "== Erasing Sphere 421+2K (replay 72)"
run_ex 72_hui_ex_es.rpl es 4400

echo "== Final Guardian 623+2K, connect range (replay 73)"
run_ex 73_hui_ex_fg_close.rpl fg 4600

echo "PASS: Huitzil EX moves (both fire, guard clean)"
