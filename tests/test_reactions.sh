#!/bin/sh
# test_reactions.sh — WHICH CHAINS A TENANT RUNS AS THE VICTIM, PER REACTION
# CLASS, AND HOW LONG (character-data map, PHASE 3; measured 14z-120 (7)).
#
# WHAT IT HOLDS. tools/name_moves.py's `<tenant>_victim` schedules put the
# tenant on P2 (the P2 early-window poke) against Victor on P1 (forced 0x03)
# and run every contact class the naming rigs reached: light/medium/heavy
# standing and crouching normals, the sweep, a jumping heavy, the throw, a DP,
# a fireball — hits (part 1), BLOCKED (part 2, P2 holds away), anti-air
# (part 3, Donovan). tools/reaction_map.py turns P2's per-frame node pointer
# into one line per contact: the victim's class byte, the freeze, the chain
# PATH (table:seq@entry-node, OFF:<addr> for nodes the index tables do not
# reach) and the frames until the tenant is back on a stand chain — frozen in
# tests/expected/reactions_<tenant>.txt (FREEZE=1 re-freezes it FROM THE RUN —
# only after the change is attributed: 14z-121 re-froze Huitzil's when the chain
# decoder's table bound was fixed and the OFF: nodes became b: chains). So a changed reaction set, a changed
# extract, a changed decoder or a changed rig fails here. The ids of both
# fighters are asserted from the trace (P1 0x03, P2 the tenant).
# Emulator tier (MAME, ~1 min per tenant, legs in parallel).
#
# Usage: ROMDIR=... [MAME_BIN=...] [DON=build/don_m18 HUI=build/hui52 PYR=build/pyron36] [TENANTS="donovan pyron huitzil"] tests/test_reactions.sh
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier emulator (MAME, ~2 min, legs in parallel)) THE REACTION SETS
#   (14z-120 (7), phase 3): the tenant on P2 (P2 early-window poke) vs Victor
#   on P1 (forced 0x03); every contact class hit and blocked;
#   `tools/reaction_map.py` turns P2's node pointer into one line per contact
#   (class, freeze, chain path table:seq@node, frames to the return) frozen in
#   `tests/expected/reactions_<tenant>.txt` (`FREEZE=1` re-freezes from the
#   run, 14z-121); both ids asserted from the trace. Run after any change to
#   the extracts, the decoder, the victim rigs or a reaction-set remap
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
DON="${DON:-build/don_m18}"; HUI="${HUI:-build/hui52}"; PYR="${PYR:-build/pyron36}"
TENANTS="${TENANTS:-donovan pyron huitzil}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FIELDS="ff8410:w:x,ff8414:w:y,ff840b:b:face,ff841c:l:node,ff8782:b:id,ff8810:w:p2x,ff8814:w:p2y,ff880b:b:p2face,ff881c:l:p2node,ff8820:b:p2cnt,ff8821:b:p2flags,ff8854:b:p2cls,ff8850:w:p2hp,ff8852:w:p2white,ff885c:b:p2frz,ff8b82:b:p2id,ff8840:l:p2xv,ff8844:l:p2yv"
allfail=0
for TENANT in $TENANTS; do
fail=0
case $TENANT in donovan) EX="$DON/extract"; WANT=19;; huitzil) EX="$HUI/extract"; WANT=16;; pyron) EX="$PYR/extract"; WANT=17;; esac
[ -f "$EX/regions.json" ] || { echo "SKIP: no $EX/regions.json"; exit 0; }
V="${TENANT}_victim"
PARTS="$(python3 -c "import sys; sys.path.insert(0,'tools'); import name_moves; print(' '.join(p for p in sorted(name_moves.SCHEDULES['$V'], key=int) if ('$V', p) not in name_moves.PHASE2_PARTS))")"   # 14z-123: victim part 4 is the advancing-guard rig (test_advancing_guard.sh), not a reaction part
[ "$TENANT" = donovan ] || PARTS="1 2"
EXP="tests/expected/reactions_$TENANT.txt"
echo "######## $TENANT (parts $PARTS)"
echo "== 1. rigs equal a regeneration; chains decoded"
for p in $PARTS; do
    python3 tools/name_moves.py gen "$V" $p "$W/r_$p.rpl" "$W/r_$p.json" >/dev/null || bad "gen $p"
    cmp -s "$W/r_$p.rpl" "tests/replays/naming/${V}_$p.rpl" && cmp -s "$W/r_$p.json" "tests/replays/naming/${V}_$p.json" || bad "part $p: tests/replays/naming/${V}_$p.* drifted — regenerate"
done
rm -rf "$W/chains"; mkdir -p "$W/chains"
python3 - "$EX" "$W/chains" <<'PY' || bad "decode"
import json, subprocess, sys
ex, w = sys.argv[1], sys.argv[2]
rj = json.load(open(f"{ex}/regions.json")); r = rj["regions"]["anim"]
ptr = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if v["table"].startswith("anim_index")}
for name in ("a", "a2", "b", "c", "proj"):
    subprocess.check_call(["python3", "tools/anim_nodes.py", f"{ex}/region_anim.bin", "--base", hex(r["src"]), "--table", hex(ptr["anim_index_" + name]),
                           "--name", name, "--end", hex(r["src"] + r["len"]), "--json", f"{w}/{name}.json"], stdout=subprocess.DEVNULL)
PY
echo "== 2. the legs"
for p in $PARTS; do
    POKES="$(python3 -c "import json;print(';'.join(json.load(open('$W/r_$p.json'))['pokes']))")"
    FR="$(python3 -c "import json;print(json.load(open('$W/r_$p.json'))['frames'])")"
    rm -rf "$W/sb$p"; mkdir -p "$W/sb$p"
    ( cd "$W" && MAME_SANDBOX="$W/sb$p" REPLAY="$W/r_$p.rpl" POKES="$POKES" FIELDS="$FIELDS" FIELD_OUT="$W/t_$p.txt" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
      "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/l_$p.log" 2>&1 ) </dev/null &
done
wait
for p in $PARTS; do [ -s "$W/t_$p.txt" ] || bad "part $p: no samples"; done
[ $fail = 0 ] || { echo "$TENANT: FAIL"; allfail=1; continue; }
echo "== 3. ids + the frozen contact lines"
ids="$(awk '$1=="F"&&$2==3000{for(i=3;i<=NF;i++){split($i,a,"=");if(a[1]=="id"||a[1]=="p2id")printf "%s=%s ",a[1],a[2]}}' "$W/t_1.txt")"
case "$ids" in "id=3 p2id=$WANT ") ok "P1 = Victor (3), P2 = $TENANT ($WANT)";; *) bad "ids at f3000: $ids (want id=3 p2id=$WANT)";; esac
: > "$W/got.txt"
for p in $PARTS; do python3 tools/reaction_map.py "$W/r_$p.json" "$W/t_$p.txt" "$W/chains" >> "$W/got.txt" || bad "reaction_map $p"; done
if [ "${FREEZE:-0}" = 1 ]; then cp "$W/got.txt" "$EXP"; echo "  FROZE  $EXP from this run ($(wc -l < "$EXP" | tr -d ' ') lines) — FREEZE=1"; fi
if diff -u "$EXP" "$W/got.txt" > "$W/diff.txt"; then ok "$(wc -l < "$W/got.txt" | tr -d ' ') contact lines identical to $EXP"; else bad "contact lines differ from $EXP:"; head -30 "$W/diff.txt"; fi
n="$(grep -c 'cls=0x' "$W/got.txt" | tr -d ' ')"; [ "$n" -ge 10 ] && ok "$n contacts measured" || bad "only $n contacts"
[ $fail = 0 ] && echo "$TENANT: PASS" || { echo "$TENANT: FAIL"; allfail=1; }
done
[ $allfail = 0 ] && echo PASS || echo FAIL
exit $allfail
