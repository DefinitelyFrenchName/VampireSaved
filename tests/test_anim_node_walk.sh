#!/bin/sh
# test_anim_node_walk.sh — THE ANIMATION-NODE DECODER IS AN INSTRUMENT
# (character-data map, phase 1; 14z-118). tools/anim_nodes.py reads the
# per-character anim index tables and walks the 0x18-byte node chains by the
# rules read off vs2's walker (PRG:0x02713C / 0x0271C4: sequential +0x18,
# flags bit7 = follow the link long at +0x18, bit6 = hold). A reading of code
# is not an instrument until the live engine agrees with it, so this gate
# runs DONOVAN ON NATIVE vs2 (17_don_oracle_vsav2.rpl — his own game, no port
# in the way) and samples P1's node pointer obj+0x1C and countdown obj+0x20
# every frame:
#   1. EVERY sampled node pointer lies on the decoded graph (all five tables);
#   2. every frame-to-frame node change is either a graph EDGE (sequential or
#      link) or a JUMP onto a graph node (a new sequence begun by game logic —
#      chain starts, and table-a2 reaction chains entered by node index);
#   3. the first countdown sample on a node equals its duration, or duration-1
#      when the node was set and decremented in the same frame (measured: every
#      mismatch is exactly dur-1);
#   4. NEGATIVE CONTROL: decoding with the wrong stride (0x17) must put most
#      sampled pointers OFF the graph — a graph that accepts everything holds nothing.
# Measured 14z-118 on 3,638 in-match frames: 3638/3638 on-graph, 1225 edges +
# 32 jumps, 1121 exact + 137 dur-1. Emulator tier (MAME), ~2 min.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/don_m18] tests/test_anim_node_walk.sh  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/don_m18}"  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
EX="$BUILD/extract"
[ -f "$EX/regions.json" ] || { echo "SKIP: no $EX/regions.json"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== 1. decode Donovan's five anim tables from the vs2 extract"
python3 - "$EX" "$W" <<'PY' || exit 1
import json, subprocess, sys
ex, w = sys.argv[1], sys.argv[2]
rj = json.load(open(f"{ex}/regions.json")); r = rj["regions"]["anim"]
ptr = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if v["table"].startswith("anim_index")}
for name in ("a", "a2", "b", "c", "proj"):
    t = ptr["anim_index_" + name]
    subprocess.check_call(["python3", "tools/anim_nodes.py", f"{ex}/region_anim.bin", "--base", hex(r["src"]),
                           "--table", hex(t), "--name", name, "--end", hex(r["src"] + r["len"]), "--json", f"{w}/{name}.json"],
                          stdout=subprocess.DEVNULL)
print("  decoded", list(ptr))
PY

echo "== 2. native vs2 leg: Donovan's node pointer + countdown per frame"
mkdir -p "$W/sb"
( cd "$W" && MAME_ROMPATH="$ROMDIR" MAME_SANDBOX="$W/sb" REPLAY="$REPO/tests/replays/17_don_oracle_vsav2.rpl" \
  FIELDS="ff841c:l:node,ff8420:b:cnt,ff8782:b:id" FIELD_OUT="$W/field.txt" FIELD_FROM=1 FIELD_TO=6000 FRAMES=6050 \
  "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/out" 2>&1 )
[ -s "$W/field.txt" ] || { bad "no field samples — the MAME leg did not run"; echo FAIL; exit 1; }

echo "== 3. the three checks + the negative control"
python3 - "$W" <<'PY' || fail=1
import json, sys, collections
w = sys.argv[1]
rows = []
for line in open(f"{w}/field.txt"):
    f = line.split()
    if len(f) < 3 or f[0] != "F": continue
    d = dict(kv.split("=") for kv in f[2:]); rows.append((int(f[1]), int(d["node"]), int(d["cnt"]), int(d["id"])))
inm = [r for r in rows if r[3] == 0x13 and r[1]]
if len(inm) < 1000:
    print(f"  FAIL  only {len(inm)} in-match Donovan frames — the leg is not the rig"); sys.exit(1)

def build(stride):
    graph = {}; dur = {}
    for name in ("a", "a2", "b", "c", "proj"):
        j = json.load(open(f"{w}/{name}.json"))
        for c in j["chains"].values():
            for n in c["nodes"]:
                a = int(n["addr"], 16)
                if stride != 0x18:
                    # the control: re-key every node as if nodes were `stride` apart
                    a = int(c["start"], 16) + (a - int(c["start"], 16)) // 0x18 * stride
                dur[a] = n["dur"]
                nxt = int(n["link"], 16) if (n["flags"] & 0x80 and n.get("link")) else (None if n["flags"] & 0x40 else a + stride)
                graph.setdefault(a, set()).add(nxt)
    return graph, dur

graph, dur = build(0x18)
on = sum(1 for r in inm if r[1] in dur)
if on == len(inm): print(f"  ok    1. every sampled node pointer is on the decoded graph ({on}/{len(inm)})")
else: print(f"  FAIL  1. {len(inm)-on} of {len(inm)} sampled node pointers are OFF the graph"); sys.exit(1)
prev = None; edges = jumps = 0; offg = []
for fr, node, cnt, _ in inm:
    if prev is not None and node != prev:
        if node in graph.get(prev, set()): edges += 1
        elif node in dur: jumps += 1
        else: offg.append((fr, hex(prev), hex(node)))
    prev = node
if offg: print(f"  FAIL  2. transitions to off-graph nodes: {offg[:4]}"); sys.exit(1)
print(f"  ok    2. every node change is a graph edge ({edges}) or a jump onto a graph node ({jumps})")
prevn = None; exact = minus = 0; other = []
for fr, node, cnt, _ in inm:
    if node != prevn:
        if cnt == dur[node]: exact += 1
        elif cnt == dur[node] - 1: minus += 1
        else: other.append((fr, hex(node), cnt, dur[node]))
    prevn = node
if other: print(f"  FAIL  3. first-sample countdown neither dur nor dur-1: {other[:4]}"); sys.exit(1)
print(f"  ok    3. first-sample countdown == duration ({exact}) or duration-1 ({minus}); nothing else")
g2, d2 = build(0x17)
on2 = sum(1 for r in inm if r[1] in d2)
if on2 * 2 < len(inm): print(f"  ok    4. negative control: stride-0x17 decode leaves {len(inm)-on2}/{len(inm)} pointers off-graph (fires)")
else: print(f"  FAIL  4. negative control: the wrong stride still matched {on2}/{len(inm)} — the check is not checking"); sys.exit(1)
PY

if [ "$fail" = 0 ]; then echo "PASS: anim_nodes.py's chains are what the engine walks (Donovan, native vs2)"; else echo "FAIL"; exit 1; fi
