#!/bin/sh
# test_killshread_es.sh — KILLSHREAD (ES): the maintainer's ruling (14z-121)
# that the ES stance change's effect plays out DURING THE SUMMON — the
# returning Killshread attacks going away AND coming back, where the plain
# summon attacks one way — MEASURED on native vs2 and frozen.
#
# Rig: tools/name_moves.py donovan part 12 (tests/replays/naming/donovan_12.*):
# Donovan (forced 0x13) on P1 pinned at x=552, Victor idle on P2 at x=728 (in
# the sword's path); plain plant (214LK / 214HK) then a summon, then the ES
# plant (214KK, one stock) then a summon — twice each. field_trace.lua samples
# P2's HP / white / class / freeze and the stock count.
#
# One line per CONTACT (a P2 HP or white drop):
#   <event>\t+<frames after the event's input>\tcls=<+0x54>\thp=<delta>\twhite=<delta>\tstock=<P1 stocks>
# frozen in tests/expected/killshread_es.txt (FREEZE=1 re-freezes — only after
# a change is attributed). Measured 14z-121: the PLANT never connects at this
# range; a summon after a PLAIN plant lands ONE wave (3 ticks, +36..+40 LK /
# +129..+134 HK); a summon after the ES plant lands TWO waves (+31..+38 and
# +84..+86, the second ending in the knockdown class 0x16) and the ES spent
# one stock. The gate also asserts those shapes structurally (a plain summon
# has one contact group, an ES summon two), so the frozen numbers are not
# the only check.
# Emulator tier (MAME, ~2 min). Usage: ROMDIR=... [MAME_BIN=...] [FREEZE=1] tests/test_killshread_es.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
: "${ROMDIR:?set ROMDIR}"
W="$(mktemp -d "${TMPDIR:-/tmp}/ksES.XXXXXX")"; trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
EXP="tests/expected/killshread_es.txt"

echo "== 1. the rig equals a regeneration"
python3 tools/name_moves.py gen donovan 12 "$W/r.rpl" "$W/r.json" > /dev/null || bad "gen"
cmp -s "$W/r.rpl" tests/replays/naming/donovan_12.rpl && cmp -s "$W/r.json" tests/replays/naming/donovan_12.json && ok "tests/replays/naming/donovan_12.* = regeneration" || bad "rig drifted — regenerate"

echo "== 2. the native leg"
POKES="$(python3 -c "import json;print(';'.join(json.load(open('$W/r.json'))['pokes']))")"
FR="$(python3 -c "import json;print(json.load(open('$W/r.json'))['frames'])")"
FIELDS="ff8410:w:p1x,ff8810:w:p2x,ff8850:w:p2hp,ff8852:w:p2white,ff8854:b:cls,ff885c:b:frz,ff8509:b:stock,ff8782:b:id,ff8b82:b:p2id"
( cd "$W" && MAME_SANDBOX="$W/sb" REPLAY="$W/r.rpl" POKES="$POKES" FIELDS="$FIELDS" FIELD_OUT="$W/t.txt" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
  "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/l.log" 2>&1 ) </dev/null
[ -s "$W/t.txt" ] || bad "no samples"

echo "== 3. contacts"
python3 - "$W/t.txt" "$W/r.json" > "$W/got.txt" <<'PY' || bad "contact extraction"
import sys, json
rows = {}
for l in open(sys.argv[1]):
    f = l.split()
    if len(f) < 3 or f[0] != "F": continue
    rows[int(f[1])] = {k: int(v) for k, v in (kv.split("=") for kv in f[2:])}
ev = json.load(open(sys.argv[2]))["events"]
ids = {(v["id"], v["p2id"]) for v in rows.values()}
assert ids == {(0x13, 0x03)}, f"ids {ids}"   # Donovan vs Victor, both forced
prev = None
for fr in sorted(rows):
    v = rows[fr]
    if prev and (v["p2hp"] < prev["p2hp"] or v["p2white"] < prev["p2white"]):
        e = [x for x in ev if x["frame"] <= fr][-1]
        print(f"{e['name']}\t+{fr - e['frame']}\tcls={v['cls']:#04x}\thp={v['p2hp'] - prev['p2hp']}\twhite={v['p2white'] - prev['p2white']}\tstock={v['stock']}")
    prev = v
PY
if [ "${FREEZE:-0}" = 1 ]; then cp "$W/got.txt" "$EXP"; echo "  FROZE  $EXP ($(wc -l < "$EXP" | tr -d ' ') lines)"; fi
if diff -u "$EXP" "$W/got.txt" > "$W/d.txt"; then ok "$(wc -l < "$W/got.txt" | tr -d ' ') contact lines identical to $EXP"; else bad "contacts differ:"; head -20 "$W/d.txt"; fi
python3 - "$W/got.txt" <<'PY' || fail=1
import sys, collections
groups = collections.defaultdict(list)
for l in open(sys.argv[1]):
    name, off = l.split("\t")[:2]; groups[name].append(int(off[1:]))
def waves(offs):  # contact groups separated by > 20 frames
    w = 0; last = None
    for o in sorted(offs):
        if last is None or o - last > 20: w += 1
        last = o
    return w
bad = 0
for name, offs in groups.items():
    if "plant" in name: print(f"  FAIL  the plant connected ({name}) — the rig's range moved"); bad = 1
for name in ("Killshread Summon [214LK] after plain", "Killshread Summon [214HK] after plain"):
    n = waves(groups.get(name, []));  print(("  ok    " if n == 1 else "  FAIL  ") + f"{name}: {n} contact wave(s) (expected 1)"); bad |= n != 1
for name in ("Killshread Summon [214LK] after ES", "Killshread Summon [214HK] after ES"):
    n = waves(groups.get(name, []));  print(("  ok    " if n == 2 else "  FAIL  ") + f"{name}: {n} contact wave(s) (expected 2 — the sword attacks going away AND coming back)"); bad |= n != 2
sys.exit(bad)
PY
[ $fail = 0 ] && echo PASS || echo FAIL
exit $fail
