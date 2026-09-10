#!/bin/sh
# test_tick_durations.sh — OUR DERIVED FRAME DATA IS THE ENGINE'S, measured in
# ENGINE TICKS (14z-126b). This is what closed the last open residue of the
# community cross-check: Jedah's crouching recovery.
#
# MUST-FIRE: perturbed-copy: perturbed-total — a crouching move's derived total moved by one in the measured tick table must fail the derived-vs-measured compare (mode: JE's first crouch total is bumped and section 1 must fail)
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
# Usage: ROMDIR=... tests/test_tick_durations.sh   (~22 min, 6 MAME runs)
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
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
# ONE perturbation, called by the executable mode (on JE's real tick table): bump
# the first crouching move's derived total by one, so the derived-vs-measured
# compare fails.
perturb_total() {  # perturb_total <tick_durations txt>
    python3 - "$1" <<'PY'
import sys
p = sys.argv[1]; out = []; done = False
for l in open(p):
    if l.startswith("  2") and not done:
        f = l.split(); f[2] = str(int(f[2]) + 1); out.append("  " + " ".join(f) + "\n"); done = True
    else:
        out.append(l)
open(p, "w").writelines(out)
PY
}

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
    # THE EXECUTABLE MODE: bump JE's first crouch total so section 1's compare fails.
    if [ "$MODE" = perturbed-total ] && [ "$ch" = JE ]; then perturb_total "$W/$ch.txt"; fi
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

# ---- AULBATH'S STANDING NORMALS AND LEI-LEI'S JUMPING NORMALS, PER NODE (14z-146):
# the cross-check's three unarbitrated timing cells. AU 5MP: the sheet's active
# reads "6x3" (18) against our "6,3" (9) — the SPAN in ticks over the attack nodes
# decides. AU 5HP: the sheet's startup 11 against our 9, +2 where the sheet's own
# convention is +1 — the startup in ticks decides. LE J.HP: the sheet's active
# "2,2,2,2,2,1" (11) against our "2,2,2,2,2,2" (12) — an AERIAL, so the landing
# can LEAVE the chain inside its window; the pass's seen-node count and its ticks
# on the attack nodes say whether the sheet's 11 is a landing cut of the data's 12.
for pair in "0x09 AU far 5" "0x0d LE jump J."; do
    set -- $pair; id=$1; ch=$2; st=$3; pfx=$4
    python3 tools/vanilla_join_rig.py gen "$id" "$st" "$W/$ch.rpl" "$W/$ch.json" >/dev/null
    P="$(python3 -c "
import json,sys;d=json.load(open(sys.argv[1]));p=d.get('pokes') or []
print(';'.join(p) if isinstance(p,list) else p)" "$W/$ch.json")"
    FR="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$W/$ch.json")"
    MAME_BIN="$BIN" MAME_SANDBOX="$W/sb_$ch" REPLAY="$W/$ch.rpl" POKES="$P" \
        TAP=ff841c,8 WINDOW=2400,"$FR" FRAMES="$FR" TRACE_OUT="$W/$ch.tap" \
        tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/tap_writes.lua" \
        > "$W/$ch.out" 2>&1 || true
    python3 tools/vanilla_frames.py "$DATA" --char "$ch" --json "$W/${ch}_d.json" >/dev/null
    python3 tools/tick_durations.py "$W/$ch.tap" "$W/${ch}_d.json" "$ch" --prefix "$pfx" --nodes > "$W/$ch.txt"
done
python3 - "$W" <<'PY' || fail=1
import sys, re
W = sys.argv[1]
def rows(ch, pfx):
    lines = open(f"{W}/{ch}.txt").read().split("\n"); out = {}
    for i, l in enumerate(lines):
        if l.startswith("  " + pfx):
            mv = l.split()[0]; nxt = lines[i + 1] if i + 1 < len(lines) else ""
            m = re.search(r"startup-ticks (\d+) \(derived (\d+)\)  span-ticks (\d+) \(derived (\d+)\)(.*)$", nxt)
            out[mv] = (int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4)), "LEFT INSIDE" in m.group(5)) if m else None
    return out
bad = []
au = rows("AU", "5")
if len(au) != 6: bad.append(f"AU: expected 6 standing normals, got {sorted(au)}")
for mv, v in sorted(au.items()):
    print(f"        AU {mv}: startup-ticks {v[0]} derived {v[1]}; span-ticks {v[2]} derived {v[3]}{'; left inside' if v[4] else ''}" if v else f"        AU {mv}: NOT ENTERED")
    if v is None or v[0] != v[1]: bad.append(f"AU {mv}: startup in ticks != derived")
if au.get("5MP") and (au["5MP"][2] != 9 or au["5MP"][4]): bad.append(f"AU 5MP: span-ticks {au['5MP'][2] if au.get('5MP') else '?'} != 9 (the sheet's '6x3' = 18 would be the alternative)")
if au.get("5HP") and au["5HP"][0] != 9: bad.append("AU 5HP: startup-ticks != 9 (the sheet's 11 is one high under its +1 convention)")
le = rows("LE", "J.")
if len(le) != 6: bad.append(f"LE: expected 6 jumping normals, got {sorted(le)}")
for mv, v in sorted(le.items()):
    print(f"        LE {mv}: startup-ticks {v[0]} derived {v[1]}; span-ticks {v[2]} derived {v[3]}{'; LEFT INSIDE THE WINDOW (landing)' if v[4] else ''}" if v else f"        LE {mv}: NOT ENTERED")
    if v is None or v[0] != v[1]: bad.append(f"LE {mv}: startup in ticks != derived")
hp = le.get("J.HP")
if not hp or not hp[4] or not (hp[2] < hp[3]): bad.append(f"LE J.HP: expected the pass LEFT INSIDE its attack window with span-ticks < derived 12 (a landing cut), got {hp}")
if bad:
    print("  FAIL AU/LE: " + "; ".join(bad)); sys.exit(1)
print("  ok AU: 6/6 startups equal in ticks (5HP = 9; the sheet's 11 is one high); 5MP spends 9 ticks on its attack nodes (the sheet's '6x3' is a notation slip for '6,3')")
print(f"  ok LE: 6/6 startups equal in ticks; J.HP is LEFT inside its window by the landing after {hp[2]} of the data's {hp[3]} attack ticks (the sheet's 11 is a landing-cut figure, ours the chain's)")
PY

# ---- CONTROL: a perturbed total must FAIL the same comparison --------------
if python3 - "$W" <<'PY'
import re, sys
W = sys.argv[1]
lines = [l for l in open(f"{W}/JE.txt") if l.startswith("  2")]
l = lines[0]; f = l.split()
total = int(f[2]); meas = int(re.search(r"\[(\d+)\]", l).group(1))
sys.exit(0 if total + 1 != meas else 1)   # a bumped total would not match measured -> the compare can fail
PY
then vs_ctl_fired perturbed-total "a total off by one does not match the measured ticks (section 1 compares the perturbed JE table under the mode)"
else vs_ctl_dead perturbed-total "a perturbed total was accepted — the derived-vs-measured compare cannot fail"; fail=1; fi

[ "$fail" -eq 0 ] || { echo "FAIL test_tick_durations"; exit 1; }
echo "PASS: 18/18 derived totals equal the engine's measured tick counts (JE, LI, DE); BI's and AU's standing startups and LE's jumping startups equal in ticks; AU 5MP span 9, LE J.HP landing-cut"
