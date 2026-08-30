#!/bin/sh
# test_projectile_census.sh — WHICH PROJECTILE-POOL TYPES EACH TENANT'S MOVES
# SPAWN (character-data map phase 3, 14z-120 (11)). The naming rigs' specials
# and meter parts (donovan/pyron/huitzil parts 2 and 4) replayed on native vs2
# with the 32 pool slots' type bytes sampled per frame; tools/projectile_census.py
# lists, per event, the types that FIRST appear after its input; frozen in
# tests/expected/projectile_census.txt. Measured: Donovan Blizzard 0x3E; Pyron
# Sol Smasher 0x40/0x41 (air), Cosmo 0x42; Huitzil Launcher 0x44, Plasma Trap
# 0x45, Final Guardian 0x46, Erasing Sphere 0x47. Emulator tier (~2 min).
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/test_projectile_census.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
F="$(python3 -c "print(','.join([f'ff{0x9400+0x100*n+2:04x}:b:t{n:02d}' for n in range(32)]+['ff841c:l:node','ff8782:b:id']))")"
for t in donovan:2 donovan:4 pyron:2 pyron:4 huitzil:2 huitzil:4; do
    n=${t%%:*}; p=${t#*:}
    POKES="$(python3 -c "import json;print(';'.join(json.load(open('tests/replays/naming/${n}_$p.json'))['pokes']))")"
    FR="$(python3 -c "import json;print(json.load(open('tests/replays/naming/${n}_$p.json'))['frames'])")"
    rm -rf "$W/sb_${n}_$p"; mkdir -p "$W/sb_${n}_$p"
    ( cd "$W" && MAME_SANDBOX="$W/sb_${n}_$p" REPLAY="$REPO/tests/replays/naming/${n}_$p.rpl" POKES="$POKES" FIELDS="$F" FIELD_OUT="$W/c_${n}_$p.txt" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
      "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/l_${n}_$p.log" 2>&1 ) </dev/null &
done
wait
: > "$W/got.txt"
for t in donovan:2 donovan:4 pyron:2 pyron:4 huitzil:2 huitzil:4; do
    n=${t%%:*}; p=${t#*:}
    [ -s "$W/c_${n}_$p.txt" ] || bad "$n part $p: no samples"
    python3 tools/projectile_census.py "tests/replays/naming/${n}_$p.json" "$W/c_${n}_$p.txt" | sed "s/^/$n	/" >> "$W/got.txt"
done
if diff -u tests/expected/projectile_census.txt "$W/got.txt" > "$W/diff.txt"; then ok "$(wc -l < "$W/got.txt" | tr -d ' ') census lines identical to tests/expected/projectile_census.txt"; else bad "census differs:"; head -20 "$W/diff.txt"; fi
n="$(grep -c 0x "$W/got.txt" | tr -d ' ')"; [ "$n" -ge 20 ] && ok "$n spawning events" || bad "only $n spawning events"
# control: every tenant must spawn at least one distinct type
for n in donovan pyron huitzil; do grep -q "^$n	" "$W/got.txt" && ok "$n spawns" || bad "$n: no projectile spawned"; done
[ $fail = 0 ] && echo PASS || echo FAIL
exit $fail
