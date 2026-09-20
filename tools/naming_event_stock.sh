#!/bin/sh
# naming_event_stock.sh — THE STOCK EACH EVENT OF A NAMING PART ACTUALLY HAD AND
# SPENT, on native vsav2. Promoted from a 14z-172 scratch probe (GitHub #168).
#
# WHY. An ES move and its normal twin can enter the SAME anim chain — Pyron's
# Planet Burning does (build/manifest/moves_pyron.toml, "MP and HP enter a2:0x1e
# -> a2:0x21 -> a2:0x22"), and so the chain id cannot tell them apart. The stock
# can: the ES version spends one and the normal version spends none ([VSP-170],
# the discriminator that also catches an ES move degrading silently on an empty
# meter). This prints, per event of a part, the stock AT the event frame and the
# MINIMUM over the following 120 frames, so the spend is the difference.
#
# It is a PROBE, not a gate: it asserts nothing and freezes nothing. The corpus-wide
# headroom assertion is tests/audit_move_parity.sh section 2b; this is what you run
# when you need to say which of two same-chain moves an event actually fired.
#
# MEASURED 14z-172 on pyron part 5 (the 63214-vs-41236 challenge part), which is
# what identified its event 0 as the NORMAL Planet Burning after GitHub #168 moved
# the schedule: ev0 spends 0, and all five "(ES)" events of the part spend 1.
#
# Usage: ROMDIR=... [MAME_BIN=~/.cache/vampire-saved/mame/cps2] tools/naming_event_stock.sh <tenant> <part> <outdir>
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="$(cd "${ROMDIR:-../ROMS}" && pwd)"; export ROMDIR
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
T="$1"; P="$2"; O="$3"
mkdir -p "$O"; rm -rf "$O/sb"; mkdir -p "$O/sb"
python3 tools/name_moves.py gen "$T" "$P" "$O/r.rpl" "$O/r.json" >/dev/null
PK="$(python3 -c "import json;print(';'.join(json.load(open('$O/r.json'))['pokes']))")"
FR="$(python3 -c "import json;print(json.load(open('$O/r.json'))['frames'])")"
MAME_SANDBOX="$O/sb" REPLAY="$O/r.rpl" POKES="$PK" \
  FIELDS="ff8509:b:stock,ff850a:w:meter,ff8406:b:seq,ff841c:l:node,ff8410:w:x,ff8810:w:p2x" \
  FIELD_OUT="$O/tr.txt" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
  "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$O/mame.log" 2>&1
python3 - "$O/r.json" "$O/tr.txt" <<'PY'
import json, re, sys
sched = json.load(open(sys.argv[1]))
rows = {}
for line in open(sys.argv[2]):
    m = re.match(r"F (\d+) (.*)", line.strip())
    if m: rows[int(m.group(1))] = dict(p.split("=",1) for p in m.group(2).split())
print(f"{'#':>2} {'frame':>6} {'name':52} {'stock@ev':>8} {'min ev..ev+120':>14} {'spent':>5}")
for i, e in enumerate(sched["events"]):
    f = e["frame"]
    win = [int(rows[x]["stock"]) for x in range(f, f+121) if x in rows]
    at = int(rows[f]["stock"]) if f in rows else -1
    print(f"{i:>2} {f:>6} {e['name'][:52]:52} {at:>8} {min(win) if win else -1:>14} {at-(min(win) if win else at):>5}")
PY
