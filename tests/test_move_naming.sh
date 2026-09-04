#!/bin/sh
# test_move_naming.sh — THE MOVE LIST'S CHAIN IDS ARE WHAT NATIVE VS2 ENTERS
# (character-data map, phase 1 naming step; 14z-120).
#
# WHAT IT HOLDS. build/manifest/moves_donovan.toml carries a (table, seq) per
# move, measured by tools/name_moves.py: eight scripted rigs on NATIVE vs2
# (P1 Donovan, P2 Victor idle) perform every move; P1's anim node pointer
# obj+0x1C is sampled per frame (tests/lua/field_trace.lua) and mapped onto
# the chain graph decoded by tools/anim_nodes.py (the instrument
# test_anim_node_walk.sh verified). The chains ENTERED inside each event's
# window are frozen in tests/expected/move_naming_donovan.txt, and every seq
# the TOML names must appear among the measured chains. So a wrong seq in
# the TOML, a changed rig, a changed decoder, or a changed extract fails here.
#
#   1. the committed rigs equal a regeneration (the schedule is code);
#   2. the eight legs run (parallel, ~1 min headless) and every event's
#      entered-chain list equals the frozen line — the two positive controls
#      are Blizzard Sword HP (a2:0x33 = vs2 0x283E58, replay 59's chain) and
#      Lightning Sword ES (a2:0x38 = vs2 0x284A64, replay 56's);
#   3. every table:seq named in moves_donovan.toml was entered by some event;
#   4. NEGATIVE CONTROL: the expectation lines are not vacuous — an event
#      whose frozen chain is replaced by a neighbour's must FAIL the compare.
#
# TRAPS THIS RIG PAID FOR (project/gotchas.md): $FF8109 is a BINARY timer —
# a 0x99 poke ends the round; 63214 contains 214, so a grapple with the sword
# planted is Killshread Lightning; a facing flip turns "4" into forward; a
# throw leaves P2 behind P1 and mirrors every later motion (hence the
# per-event position pins); and a MAME sandbox reused across tenants
# carried an nvram that changed one throw's outcome ([VSP-117]) — every leg
# now starts from a cleared sandbox.
#
# 14z-120 (2): all THREE tenants — Pyron (4 parts) and Huitzil (8 parts, the
# last four the input search for Genocide Vulcan / the guard cancel / the
# grapple, kept as measured) — each on its own extract, forced by the
# early-window poke; every part pins both fighters' X before each event.
#
# Usage: ROMDIR=... [MAME_BIN=...] [DON=build/don_m20 HUI=build/hui54 PYR=build/pyron38] [TENANTS="donovan pyron huitzil"] tests/test_move_naming.sh   # emulator tier (MAME, ~3 min)
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier emulator (MAME, ~3 min, legs in parallel)) THE MOVE LISTS' CHAIN IDS
#   ARE WHAT NATIVE VS2 ENTERS (14z-120, phase 1 naming step; all three
#   tenants since 14z-120 (2)): `tools/name_moves.py gen` regenerates the rigs
#   (`tests/replays/naming/<tenant>_<part>.{rpl,json}` must match — Donovan 8
#   parts, Pyron 4, Huitzil 8), runs them on native vs2 (Pyron/Huitzil forced
#   by the early-window poke, both fighters' X pinned before every event) with
#   P1's `obj+0x1C` sampled per frame, maps every pointer onto
#   `anim_nodes.py`'s graph from that tenant's extract and compares each
#   event's entered-chain list to `tests/expected/move_naming_<tenant>.txt`;
#   every `table:seq` in `build/manifest/moves_<tenant>.toml` must have been
#   entered; positive controls Blizzard HP = vs2 `0x283E58` (replay 59) and
#   Lightning ES = `0x284A64` (replay 56); negative control: a swapped line
#   fails the compare. Run after any change to a move list's seq ids, the rig
#   schedules, the decoder or the vs2 extracts
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
DON="${DON:-build/don_m20}"; HUI="${HUI:-build/hui54}"; PYR="${PYR:-build/pyron38}"   # the vs2 EXTRACTS (anim region + index pointers)
TENANTS="${TENANTS:-donovan pyron huitzil}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
allfail=0
for TENANT in $TENANTS; do
case $TENANT in donovan) EX="$DON/extract";; huitzil) EX="$HUI/extract";; pyron) EX="$PYR/extract";; esac
[ -f "$EX/regions.json" ] || { echo "SKIP: no $EX/regions.json"; exit 0; }
PARTS="$(python3 -c "import sys; sys.path.insert(0,'tools'); import name_moves; print(' '.join(p for p in sorted(name_moves.SCHEDULES['$TENANT'], key=int) if ('$TENANT', p) not in name_moves.PHASE2_PARTS))")"
EXP="tests/expected/move_naming_$TENANT.txt"
fail=0
echo "######## $TENANT (parts $PARTS)"

echo "== 1. the committed rigs equal a regeneration"
for p in $PARTS; do
    python3 tools/name_moves.py gen $TENANT $p "$W/r_$p.rpl" "$W/r_$p.json" >/dev/null || { bad "gen part $p"; continue; }
    if cmp -s "$W/r_$p.rpl" "tests/replays/naming/${TENANT}_$p.rpl" && cmp -s "$W/r_$p.json" "tests/replays/naming/${TENANT}_$p.json"; then :; else bad "part $p: tests/replays/naming/${TENANT}_$p.* drifted from tools/name_moves.py — regenerate"; fi
done
[ $fail = 0 ] && ok "$(echo $PARTS | wc -w | tr -d ' ') rigs match the schedule"

echo "== 2. decode the five anim tables from the vs2 extract"
rm -rf "$W/chains"; mkdir -p "$W/chains"
python3 - "$EX" "$W/chains" <<'PY' || { bad "decode"; echo FAIL; exit 1; }
import json, subprocess, sys
ex, w = sys.argv[1], sys.argv[2]
rj = json.load(open(f"{ex}/regions.json")); r = rj["regions"]["anim"]
ptr = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if v["table"].startswith("anim_index")}
for name in ("a", "a2", "b", "c", "proj"):
    subprocess.check_call(["python3", "tools/anim_nodes.py", f"{ex}/region_anim.bin", "--base", hex(r["src"]),
                           "--table", hex(ptr["anim_index_" + name]), "--name", name, "--end", hex(r["src"] + r["len"]),
                           "--json", f"{w}/{name}.json"], stdout=subprocess.DEVNULL)
PY

echo "== 3. the native vs2 legs (parallel)"
for p in $PARTS; do
    rm -rf "$W/sb$p"; mkdir -p "$W/sb$p"   # [VSP-117]: a sandbox carried from another tenant's leg flipped one throw outcome (14z-120 (2))
    POKES="$(python3 -c "import json;print(';'.join(json.load(open('$W/r_$p.json'))['pokes']))")"
    FR="$(python3 -c "import json;print(json.load(open('$W/r_$p.json'))['frames'])")"
    ( cd "$W" && MAME_SANDBOX="$W/sb$p" REPLAY="$W/r_$p.rpl" POKES="$POKES" \
      FIELDS="ff841c:l:node,ff8420:b:cnt,ff8406:b:seq,ff8407:b:sub,ff8509:b:stock,ff8410:w:x,ff8414:w:y,ff8850:w:p2hp,ff8109:b:timer,ff8782:b:id,ff881c:l:p2node,ff802e:b:df,ff8810:w:p2x,ff840b:b:face" \
      FIELD_OUT="$W/trace_$p.txt" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
      "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/out_$p.log" 2>&1 ) </dev/null &
done
wait
for p in $PARTS; do [ -s "$W/trace_$p.txt" ] || bad "part $p: no field samples (see the MAME log)"; done
[ $fail = 0 ] || { echo "$TENANT: FAIL (a leg did not run)"; allfail=1; continue; }

echo "== 4. measured chains vs the frozen expectation"
: > "$W/got.txt"
for p in $PARTS; do python3 tools/name_moves.py expect "$W/r_$p.json" "$W/trace_$p.txt" "$W/chains" >> "$W/got.txt" || bad "expect part $p"; done
if [ "${FREEZE:-0}" = 1 ]; then cp "$W/got.txt" "$EXP"; echo "  FROZE  $EXP from this run ($(wc -l < "$EXP" | tr -d ' ') lines) — FREEZE=1 (14z-121 (4): the labels are 'the first decoded chain containing the node'; the chain-decoder bound fix relabelled shared nodes c:0x00 -> b:0x23)"; fi
if diff -u "$EXP" "$W/got.txt" > "$W/diff.txt"; then
    ok "$(wc -l < "$W/got.txt" | tr -d ' ') event lines identical to $EXP"
else
    bad "measured chains differ from $EXP:"; head -40 "$W/diff.txt"
fi

echo "== 5. every seq named in moves_$TENANT.toml was entered BY AN EVENT OF ITS OWN NAME (14z-120 (3): the cross-character check)"
cat > "$W/ownname.py" <<'PY'
import sys; sys.path.insert(0, "tools"); import _minitoml
rows = [r for r in _minitoml.loads(open(sys.argv[2]).read())["move"] if r["seq"]]
names = sorted((r["name"] for r in rows), key=len, reverse=True)   # longest prefix wins
by_row = {r["name"]: set() for r in rows}
unowned = []
for line in open(sys.argv[1]):
    part, ev, rest = line.rstrip("\n").split("\t")
    if "WRONG-ID" in rest:
        print("  FAIL  the wrong character was on P1:", ev, rest); sys.exit(1)
    owner = next((n for n in names if ev == n or ev.startswith(n + " ")), None)
    if owner is None: unowned.append(ev); continue
    by_row[owner] |= set(rest.split())
missing = []
n = 0
for r in rows:
    for q in r["seq"].split(","):
        n += 1
        k = f"{r['table']}:0x{int(q.strip(), 16):02x}"
        if k not in by_row[r["name"]]: missing.append((r["name"], k, sorted(by_row[r["name"]])[:6]))
if missing:
    print("  FAIL  seq not entered by any event of the row's own name (wrong row or wrong file?):")
    for m in missing: print("        ", m)
    sys.exit(1)
print(f"  ok    {n} table:seq ids in the TOML, every one entered by an event named for its row; {len(unowned)} events own no row (movement/controls)")
PY
python3 "$W/ownname.py" "$W/got.txt" "build/manifest/moves_$TENANT.toml" || fail=1
# CONTROL (RH-9): the first two seq-carrying rows swap their seq — the check must FAIL
python3 - "build/manifest/moves_$TENANT.toml" "$W/swapped.toml" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
seqs = re.findall(r'\nseq = "(0x[0-9a-f,x]+)"', s)
a, b = seqs[0], seqs[1]
s = s.replace(f'\nseq = "{a}"', '\nseq = "@@A"', 1).replace(f'\nseq = "{b}"', f'\nseq = "{a}"', 1).replace('\nseq = "@@A"', f'\nseq = "{b}"', 1)
open(sys.argv[2], "w").write(s)
PY
if python3 "$W/ownname.py" "$W/got.txt" "$W/swapped.toml" >/dev/null 2>&1; then bad "control: two rows with swapped seqs PASSED the own-name check — it is not checking"; else ok "control: two rows with swapped seqs fail the own-name check"; fi

echo "== 6. negative control: a swapped chain must fail the compare"
python3 - "$EXP" "$W/ctl.txt" <<'PY'
import sys
L = open(sys.argv[1]).read().split("\n")
i = next(k for k, l in enumerate(L) if l.split("\t")[1:2] == ["5LP"])
L[i] = L[i].replace("a2:0x00", "a2:0x02")
open(sys.argv[2], "w").write("\n".join(L))
PY
if diff -q "$W/ctl.txt" "$W/got.txt" >/dev/null; then bad "control: a swapped 5LP chain compared EQUAL — the compare is not comparing"; else ok "control: the swapped 5LP line fails the compare"; fi
[ $fail = 0 ] && echo "$TENANT: PASS" || { echo "$TENANT: FAIL"; allfail=1; }
rm -f "$W"/trace_*.txt "$W"/r_*.rpl "$W"/r_*.json "$W"/got.txt
done
[ $allfail = 0 ] && echo PASS || echo FAIL
exit $allfail
