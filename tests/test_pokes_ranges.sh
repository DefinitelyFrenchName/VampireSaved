#!/bin/sh
# test_pokes_ranges.sh — a RANGE in the POKES grammar (F1-F2:addr:hex) writes exactly what its per-frame entries
# write, frame for frame (tests/lua/pokes_spec.lua, 14z-187b, GitHub #201).
#
# WHAT: the shared POKES parser expands `F1-F2:addr:hex` into the per-frame entries it stands for, so a run pinned
#   by ranges is the run pinned by per-frame entries — whole work RAM, every frame.
# HOW: tests/lua/replay.lua on pristine vsavj, tests/replays/dmg192/chaos_flare.rpl (a match from ~2363), three runs:
#   PER-FRAME (the level pinned 8 over 2000-3399, the RNG word 1234 over 2363-3399 and the frame counter $FF8080 0000
#   over 2500-3049, one entry per frame — the form every gate used before #201), RANGES (the same pins as three range
#   entries), and SHORT (the frame-counter range ending one frame early, 3048). The per-frame RAM checksum logs are compared.
# EXPECTS: PER-FRAME and RANGES byte-identical over the whole run; SHORT differs from RANGES (so the comparison can
#   see a one-frame error in a range's end); the two strings' lengths printed (per-frame against ranges).
# FOLLOWS: emu/mame-patches/ tests/lua/pokes_spec.lua tests/lua/replay.lua tests/replays/dmg192/chaos_flare.rpl tools/run_mame.sh
#   tools/setup_mame.sh tests/lib/controls.sh
#
# MUST-FIRE: perturbed-copy: range-short — the frame-counter range ending one frame early must change the run (in-gate: the SHORT run's checksum log differs from the RANGES run's; mode: the SHORT pins stand in for the RANGES pins and the gate FAILs)
#
# WHY. Linux caps one environment string at 128 KiB (MAX_ARG_STRLEN; on ERIS 131,072 bytes fails and 131,067 passes)
# and the per-frame pins of a long rig reached 164,095 bytes, so the parity-style gates' legs could not even start
# off macOS (#201). Ranges carry the same pins in ~40 bytes; this gate is the proof that they ARE the same pins.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/test_pokes_ranges.sh      # emulator tier, MAME, three runs (~1 min)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

# Pins that BITE (a first draft pinned level 6 — vsavj's default — and the RNG, whose last frame is often undrawn: the
# short control was DEAD): the level 8 (TURBO, a different tick cadence on vsavj), the RNG word 1234, and the frame
# counter $FF8080 held at 0000 — the game advances it every frame, so a range one frame short MUST change RAM.
PER="$(python3 -c "print(';'.join(f'{f}:ff8116:08' for f in range(2000,3400)) + ';' + ';'.join(f'{f}:ff80d4:1234' for f in range(2363,3400)) + ';' + ';'.join(f'{f}:ff8080:0000' for f in range(2500,3050)))")"
RNG="2000-3399:ff8116:08;2363-3399:ff80d4:1234;2500-3049:ff8080:0000"
SHORT="2000-3399:ff8116:08;2363-3399:ff80d4:1234;2500-3048:ff8080:0000"
[ "$MODE" = range-short ] && RNG="$SHORT"
leg() {  # leg <tag> <pokes>
    mkdir -p "$W/$1"
    ( cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/dmg192/chaos_flare.rpl" POKES="$2" \
        CHECKSUM_OUT="$W/$1.ck" TAIL_FRAMES=60 \
        "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/replay.lua" > "$W/$1/mame.log" 2>&1; rm -rf "$W/$1/sb" ) </dev/null
}
echo "== 1. three runs (per-frame pins ${#PER} bytes, as ranges ${#RNG} bytes)"
leg per "$PER" & leg ranges "$RNG" & leg short "$SHORT" & wait
for t in per ranges short; do
    n="$(grep -c . "$W/$t.ck" 2>/dev/null || echo 0)"
    [ "$n" -gt 3400 ] && ok "$t: $n checksum lines" || bad "$t: the run is short or dead ($n lines, $W/$t/mame.log)"
done
echo "== 2. ranges against per-frame entries: byte-identical"
if cmp -s "$W/per.ck" "$W/ranges.ck"; then ok "the RANGES run is the PER-FRAME run, every frame of whole work RAM"
else bad "the runs differ, first at: $(diff "$W/per.ck" "$W/ranges.ck" | grep -m1 '^[<>]' | cut -c1-80)"; fi
if [ -z "$MODE" ]; then
    if cmp -s "$W/ranges.ck" "$W/short.ck"; then vs_ctl_dead range-short "a range one frame short changed nothing — the comparison cannot see a range's end" || fail=1
    else
        first="$(diff "$W/ranges.ck" "$W/short.ck" | grep -m1 '^<' | awk '{print $2}')"
        vs_ctl_fired range-short "the frame-counter range ending at 3048 instead of 3049 changes the run (first differing line: frame ${first:-?})"
    fi
fi

if [ "$fail" = 0 ]; then echo "PASS: test_pokes_ranges"; else echo "FAIL: test_pokes_ranges"; exit 1; fi
