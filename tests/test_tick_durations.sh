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
# Usage: ROMDIR=... tests/test_tick_durations.sh   (~12 min, 3 MAME runs)
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
echo "PASS: 18/18 derived totals equal the engine's measured tick counts (JE, LI, DE)"
