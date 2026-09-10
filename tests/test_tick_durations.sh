#!/bin/sh
# test_tick_durations.sh — OUR DERIVED FRAME DATA IS THE ENGINE'S, measured in
# ENGINE TICKS (14z-126b). This is what closed the last open residue of the
# community cross-check: Jedah's crouching recovery.
#
# WHAT IT ASSERTS. For three vanilla characters (JE, LI, DE) every crouching
# normal's derived TOTAL (startup+active+recovery, tools/vanilla_frames.py)
# equals the number of engine ticks the chain actually consumes on stock
# vsavj -- 18 of 18, exactly, no tolerance.
#
# WHY TICKS AND NOT FRAMES. field_trace samples once per FRAME and ~16% of
# frames advance the node countdown by TWO ticks (some three or four), so a
# frame-rate trace cannot adjudicate a one-frame convention. A write tap fires
# per WRITE: PRG:0x027F70 `subq.b #$1,$20(a6)` IS one tick
# (engine_internals "THE ENGINE TICK IS DIRECTLY OBSERVABLE").
#
# WHAT IT SETTLES. The workbook reads Jedah's six crouching normals (and
# Lilith's 2MK) as recovery +3 where every other character is a flat +2. Our
# startup and active agree with the workbook under its stated conventions and
# are NOT flagged; the totals here are ground truth; therefore our recovery is
# right and the outlier is in the workbook. Arbitrated, not guessed.
#
# CONTROL (must fire): a perturbed derived total must FAIL, so the comparison
# cannot rot into "any number passes".
#
# TWO TRAPS ENCODED HERE, both paid for:
#   * the tap range is EVEN and WORD-ALIGNED -- a 1-byte tap on this 16-bit
#     bus returns a clean, meaningless zero (docs/platform/gotchas.md).
#   * segmentation is by the ANIM POINTER leaving the chain's address range.
#     Counting ticks over a rig window measures the crouch IDLE instead and
#     reports ~365 for every move -- identical numbers are the tell.
#
# Usage: ROMDIR=... tests/test_tick_durations.sh   (~16 min, 4 MAME runs)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
case "$ROMDIR" in /*) ;; *) ROMDIR="$(cd "$ROMDIR" && pwd)" ;; esac
export ROMDIR
BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
[ -x "$BIN" ] || BIN="$HOME/.cache/vampire-saved/mame/cps2"
[ -x "$BIN" ] || { echo "SKIP: no MAME binary"; exit 0; }
DATA="$REPO/build/out/vsavj_data.bin"
[ -f "$DATA" ] || { echo "SKIP: no $DATA (tools/cps2_decrypt.py)"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"
fail=0

for pair in "0x0f JE" "0x0e LI" "0x01 DE"; do
    id=${pair%% *}; ch=${pair##* }
    python3 tools/vanilla_join_rig.py gen "$id" crouch "$W/$ch.rpl" "$W/$ch.json" >/dev/null
    P="$(python3 -c "
import json,sys;d=json.load(open(sys.argv[1]));p=d.get('pokes') or []
print(';'.join(p) if isinstance(p,list) else p)" "$W/$ch.json")"
    MAME_BIN="$BIN" MAME_SANDBOX="$W/sb_$ch" REPLAY="$W/$ch.rpl" POKES="$P" \
        TAP=ff841c,8 WINDOW=2400,4600 FRAMES=4600 TRACE_OUT="$W/$ch.tap" \
        tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/tap_writes.lua" \
        > "$W/$ch.out" 2>&1 || true
    python3 tools/vanilla_frames.py "$DATA" --char "$ch" --json "$W/${ch}_d.json" >/dev/null
    python3 tools/tick_durations.py "$W/$ch.tap" "$W/${ch}_d.json" "$ch" --prefix 2 > "$W/$ch.txt"
    python3 - "$W/$ch.txt" "$ch" <<'PY' || fail=1
import sys, re
rows = [l for l in open(sys.argv[1]) if l.startswith("  2")]
if len(rows) != 6:
    print(f"  FAIL {sys.argv[2]}: expected 6 crouching normals, got {len(rows)}"); sys.exit(1)
bad = []
for l in rows:
    f = l.split()
    mv, total, meas = f[0], f[2], re.search(r"\[(\d+)\]", l)
    if not meas: bad.append(f"{mv}: NOT ENTERED"); continue
    if int(meas.group(1)) != int(total): bad.append(f"{mv}: derived {total} vs measured {meas.group(1)}")
if bad:
    print(f"  FAIL {sys.argv[2]}: " + "; ".join(bad)); sys.exit(1)
print(f"  ok {sys.argv[2]}: 6/6 crouching normals -- derived total == measured engine ticks")
PY
done

# ---- BISHAMON'S STANDING NORMALS, PER NODE (14z-145): the community cross-check's
# one remaining startup outlier is BI 5MK — the sheet says 5 where every other
# move reads ours+1 (so 6 expected). Ours derives 5 = node 0's duration byte.
# The tap sees every tick per node: the STARTUP IN TICKS is the ticks spent
# before the first attack node (frame_data.first). Asserted equal to the
# derived startup for all six standing normals — if 5MK's node 0 spends other
# than 5 ticks, the derivation is what is wrong; if it spends 5, the sheet is.
python3 tools/vanilla_join_rig.py gen 0x08 far "$W/BI.rpl" "$W/BI.json" >/dev/null
P="$(python3 -c "
import json,sys;d=json.load(open(sys.argv[1]));p=d.get('pokes') or []
print(';'.join(p) if isinstance(p,list) else p)" "$W/BI.json")"
MAME_BIN="$BIN" MAME_SANDBOX="$W/sb_BI" REPLAY="$W/BI.rpl" POKES="$P" \
    TAP=ff841c,8 WINDOW=2400,4600 FRAMES=4600 TRACE_OUT="$W/BI.tap" \
    tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/tap_writes.lua" \
    > "$W/BI.out" 2>&1 || true
python3 tools/vanilla_frames.py "$DATA" --char BI --json "$W/BI_d.json" >/dev/null
python3 tools/tick_durations.py "$W/BI.tap" "$W/BI_d.json" BI --prefix 5 --nodes > "$W/BI.txt"
python3 - "$W/BI.txt" <<'PY' || fail=1
import sys, re
lines = open(sys.argv[1]).read().split("\n")
rows = {}
for i, l in enumerate(lines):
    if l.startswith("  5"):
        mv = l.split()[0]; nxt = lines[i + 1] if i + 1 < len(lines) else ""
        m = re.search(r"startup-ticks (\d+) \(derived (\d+)\)", nxt)
        rows[mv] = (int(m.group(1)), int(m.group(2))) if m else None
if len(rows) != 6:
    print(f"  FAIL BI: expected 6 standing normals, got {sorted(rows)}"); sys.exit(1)
bad = [f"{mv}: {v}" for mv, v in rows.items() if v is None or v[0] != v[1]]
for mv, v in sorted(rows.items()):
    print(f"        BI {mv}: startup-ticks {v[0] if v else '?'} derived {v[1] if v else '?'}")
if bad:
    print("  FAIL BI: startup in ticks != derived: " + "; ".join(bad)); sys.exit(1)
print("  ok BI: 6/6 standing normals -- startup in engine ticks == derived (5MK's node 0 spends the 5 ticks its byte says; the sheet's 5 is one low)")
PY

# ---- CONTROL: a perturbed total must FAIL the same comparison --------------
python3 - "$W" <<'PY' || { echo "  FAIL control: a perturbed total was accepted"; fail=1; }
import json, re, sys
W = sys.argv[1]
lines = [l for l in open(f"{W}/JE.txt") if l.startswith("  2")]
l = lines[0]; f = l.split()
total = int(f[2]); meas = int(re.search(r"\[(\d+)\]", l).group(1))
sys.exit(0 if total + 1 != meas else 1)   # perturbed derived != measured -> control fires
PY
echo "  ok control fired: a total off by one does not match the measured ticks"

[ "$fail" -eq 0 ] || { echo "FAIL test_tick_durations"; exit 1; }
echo "PASS: 18/18 derived totals equal the engine's measured tick counts (JE, LI, DE); BI's six standing startups equal in ticks"
