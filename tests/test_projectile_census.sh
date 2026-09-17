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
# Usage: ROMDIR=... [MAME_BIN=...] [FREEZE=1] tests/test_projectile_census.sh
#   FREEZE=1 (since 14z-160) rewrites the census from the run; re-frozen 14z-160
#   when the Phobos and Pyron rigs became REAL cursor picks on native vs2
#   (GitHub #151): the poked leg's Donovan flavor had lengthened Phobos's
#   Mighty Launcher windows by the 2-frame flavor-1 startup state and spawned a
#   launcher from "Circuit Scrapper (ES)" that a real Phobos never spawns.
#   Re-frozen 14z-165 when the rigs' P2 became DEMITRI by his real route
#   (maintainer-ruled 2026-09-17; Victor until then) — P2's id is asserted from
#   each leg's trace (RAM:$FF8B82 at frame 2300).
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier emulator (MAME, ~2 min)) WHICH PROJECTILE-POOL TYPES EACH MOVE
#   SPAWNS (14z-120 (11)): the naming rigs' specials/meter parts with the 32
#   pool slots' type bytes sampled; `tools/projectile_census.py` lists per
#   event the types that first appear after the input; frozen
#   `tests/expected/projectile_census.txt`. Run after any change to the rigs
#   or a tenant's projectile handlers
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
F="$(python3 -c "print(','.join([f'ff{0x9400+0x100*n+2:04x}:b:t{n:02d}' for n in range(32)]+['ff841c:l:node','ff8782:b:id','ff8b82:b:p2id']))")"
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
    p2="$(awk '$1=="F" && $2==2300 {for(i=3;i<=NF;i++) if ($i ~ /^p2id=/) {sub("p2id=","",$i); printf "%02x", $i}}' "$W/c_${n}_$p.txt")"
    [ "$p2" = "$(python3 -c "import sys; sys.path.insert(0,'tools'); import name_moves; print(name_moves.TENANTS['$n']['p2_id'])")" ] || bad "$n part $p: P2 is id $p2, not Demitri (01) — the P2 route did not land"
    python3 tools/projectile_census.py "tests/replays/naming/${n}_$p.json" "$W/c_${n}_$p.txt" | sed "s/^/$n	/" >> "$W/got.txt"
done
if [ "${FREEZE:-0}" = 1 ]; then cp "$W/got.txt" tests/expected/projectile_census.txt; echo "  FROZE  tests/expected/projectile_census.txt from this run — VERIFY by re-running without FREEZE"; fi
if diff -u tests/expected/projectile_census.txt "$W/got.txt" > "$W/diff.txt"; then ok "$(wc -l < "$W/got.txt" | tr -d ' ') census lines identical to tests/expected/projectile_census.txt"; else bad "census differs:"; head -20 "$W/diff.txt"; fi
n="$(grep -c 0x "$W/got.txt" | tr -d ' ')"; [ "$n" -ge 20 ] && ok "$n spawning events" || bad "only $n spawning events"
# control: every tenant must spawn at least one distinct type
for n in donovan pyron huitzil; do grep -q "^$n	" "$W/got.txt" && ok "$n spawns" || bad "$n: no projectile spawned"; done
[ $fail = 0 ] && echo PASS || echo FAIL
exit $fail
