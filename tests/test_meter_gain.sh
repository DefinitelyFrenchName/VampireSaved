#!/bin/sh
# test_meter_gain.sh — THE GAUGE COLUMN ARBITRATED: what a vanilla normal pays
# its attacker in METER, read off the engine on a CONNECT (14z-146). The
# community cross-check's `gauge_hit` column carried six cells no instrument
# could adjudicate (SA 5HK/2HP, BI 2HK, FE 5MP, ZA J.2HK, LE J.HP).
#
# MUST-FIRE: perturbed-copy: perturbed-net — SA 5MP's net meter gain moved by one in a copy of the measured table must fail law A (mode: section A-D runs the real verdict on that perturbed table and must fail)
#
# THE INSTRUMENT: tools/vanilla_join_rig.py CONNECTING legs (`hit`, `hit_crouch`,
# `hit_jump`, `hit_jump_down`; P1 walks in, P2 Victor idle, HP re-pinned) traced
# for P1's meter (+0x10A, 0x90 = one stock, plus +0x109 stocks) and P2's HP.
# The meter moves in STEPS: the SWING COST on the press frame (before any hit)
# and one ON-HIT step per landed hit, on the frame P2's HP drops — so one leg
# yields swing, hits and per-hit gain (tools/meter_gain.py). A whiff twin was
# tried first and is redundant: it repeats the swing step, and it cannot be
# produced at all for a move that carries its attacker across the screen
# (Zabel's dive kicks connect at the engine's 336 px separation clamp, whatever
# the rig pins — the wider pins of the first attempt were clamped back).
#
# WHAT IT ASSERTS:
#   A. THE LAW, every connecting event: the net on-hit gain equals the record's
#      +0x14 meter byte (our per-hit derivation) TIMES THE HITS THAT LANDED.
#   B. every event's swing cost is 0 / 3 / 6 by button strength and equals the
#      workbook's own `gauge whiff` cell for that move.
#   C. THE SIX CELLS, frozen as (hits landed, net): the residue is never the
#      per-hit meter — it is HOW MANY WINDOWS LAND on an idle standing victim at
#      one geometry. SA 5HK/2HP land 1 of 2 (the juggle gate, test_rehit_ring),
#      LE J.HP 3 of 6, BI 2HK 1 of 2 (its sheet cell "24(24)" is a conditional
#      second hit, now read as such), ZA J.2HK 1 with ours == engine (the sheet's
#      row carries M-strength numbers on an H move), FE 5MP 1 with ours == engine
#      (the sheet's "5" is a typo for 15). The derivation counts the chain's
#      WINDOWS (its capacity); the workbook counts what LANDED for its author.
#   D. a VOID leg (a connect that missed) is reported and never counted; a VOID
#      on one of the six cells FAILS.
#   E. the full measured table is hash-locked OUT OF TREE
#      (../charpages/framedata/vanilla_meter_gain.tsv, sha256 in tests/expected).
# CONTROL (must fire): a perturbed net on a copy of the table fails law A.
#
# Usage: ROMDIR=... tests/test_meter_gain.sh   [FREEZE=1]   (~4 min, 8 MAME runs in parallel)
#        SKIPs without ../community/vsav-framedata.xlsx (third-party, outside the tree)
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
SHEET="${SHEET:-$REPO/../community/vsav-framedata.xlsx}"
[ -f "$SHEET" ] || { echo "SKIP: no $SHEET (the community workbook is third-party and lives outside the tree)"; exit 0; }
OUTDIR="${FRAMEDATA_OUT:-$REPO/../charpages/framedata}"
HEXP="$REPO/tests/expected/vanilla_meter_gain.sha256"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"
fail=0
FIELDS="ff841c:l:node,ff8850:w:p2hp,ff850a:w:p1meter,ff8509:b:p1stock,ff8414:w:p1y"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
# ONE perturbation, called by the section-F control and by the executable mode:
# SA 5MP's net meter gain (+0x14 column) moved by one, which fails law A.
perturb_net() {  # perturb_net <in> <out>
    awk -F'\t' 'BEGIN{OFS="\t"} NR>1 && $1=="SA" && $4=="5MP" {$11=$11+1} {print}' "$1" > "$2"
}

echo "== 0. eight connecting legs"
for leg in "SA 0x0a hit" "SA 0x0a hit_crouch" "BI 0x08 hit_crouch" "FE 0x07 hit" \
           "ZA 0x04 hit_jump_down" "ZA 0x04 hit" "LE 0x0d hit_jump" "LE 0x0d hit"; do
    set -- $leg; ch=$1; id=$2; st=$3
    python3 tools/vanilla_join_rig.py gen "$id" "$st" "$W/${ch}_$st.rpl" "$W/${ch}_$st.json" >/dev/null
    P="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$W/${ch}_$st.json")"
    FR="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$W/${ch}_$st.json")"
    mkdir -p "$W/${ch}_$st"
    ( MAME_BIN="$BIN" MAME_SANDBOX="$W/${ch}_$st/sb" REPLAY="$W/${ch}_$st.rpl" POKES="$P" \
        FIELDS="$FIELDS" FIELD_OUT="$W/${ch}_$st/t.txt" FIELD_FROM=2400 FIELD_TO="$FR" FRAMES="$FR" \
        tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/${ch}_$st/l.log" 2>&1 || true ) </dev/null &
done
wait
for d in "$W"/*_*/; do [ -s "$d/t.txt" ] || { echo "  FAIL: no trace in $d"; fail=1; }; done
[ "$fail" -eq 0 ] || { echo "FAIL test_meter_gain"; exit 1; }
python3 tools/vanilla_frames.py "$DATA" --json "$W/v.json" >/dev/null
python3 tools/meter_gain.py "$W" "$W/v.json" "$DATA" --sheet "$SHEET" > "$W/table.tsv"
python3 tools/meter_gain.py "$W" "$W/v.json" "$DATA" --sheet "$SHEET" --cells > "$W/cells.tsv"
sed 's/^/        /' "$W/cells.tsv"

# the ONE verdict, run on the real table and on the perturbed copy
verdict() {  # $1 = table.tsv -> exit 0/1
    python3 - "$1" <<'PY'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1]), delimiter="\t"))
bad = []; law_a = 0; law_b = 0
cost = {"LP": 0, "LK": 0, "MP": 3, "MK": 3, "HP": 6, "HK": 6}
def i(x):
    return None if x in ("None", "", None) else int(x)
for r in rows:
    key = f"{r['tab']} {r['move']}"
    if i(r["stray_steps"]): bad.append(f"{key}: {r['stray_steps']} meter step(s) neither the swing nor a hit")
    if i(r["swing"]) is not None:
        law_b += 1
        if i(r["swing"]) != cost[r["button"]]: bad.append(f"B {key}: swing {r['swing']} != {cost[r['button']]} for {r['button']}")
        # the ONE named exception: the workbook's ZA J.2HK row carries M-strength numbers (whiff 3, hit 15) on an H move
        if key != "ZA J.2HK" and i(r["sheet_whiff"]) is not None and i(r["swing"]) != i(r["sheet_whiff"]): bad.append(f"B {key}: swing {r['swing']} != the sheet's gauge whiff {r['sheet_whiff']}")
    hits = i(r["hits"])
    if hits and i(r["per_hit"]) is not None:
        law_a += 1
        if i(r["net"]) != i(r["per_hit"]) * hits: bad.append(f"A {key}: net {r['net']} != per-hit {r['per_hit']} x {hits} hits")
# C. the six cells and their controls: (hits landed, net) frozen
cells = {"SA 5HK": (1, 18), "SA 2HP": (1, 18), "BI 2HK": (1, 18), "FE 5MP": (1, 12), "ZA J.2HK": (1, 18),
         "LE J.HP": (3, 18), "SA 5MP": (1, 12), "ZA 5HK": (1, 9), "LE 5HP": (1, 18)}
for key, (h, net) in cells.items():
    r = next((x for x in rows if f"{x['tab']} {x['move']}" == key), None)
    if r is None: bad.append(f"C {key}: no row"); continue
    if i(r["hits"]) == 0: bad.append(f"C {key}: VOID leg (no hit landed)"); continue
    if (i(r["hits"]), i(r["net"])) != (h, net): bad.append(f"C {key}: (hits, net) = ({r['hits']}, {r['net']}), frozen ({h}, {net})")
if law_a < 30: bad.append(f"A: only {law_a} connecting events — the rig did not connect")
if law_b < 40: bad.append(f"B: only {law_b} swing costs read")
print(f"    law A over {law_a} connecting events, law B over {law_b} swings")
if bad:
    print("\n".join("    " + b for b in bad)); sys.exit(1)
PY
}

echo "== A-D. the verdict"
# THE EXECUTABLE MODE: the verdict runs on the PERTURBED table, so a real
# perturbation of the measured data reaches the gate's own FAIL.
MAIN="$W/table.tsv"
if [ "$MODE" = perturbed-net ]; then perturb_net "$W/table.tsv" "$W/table.mode.tsv"; MAIN="$W/table.mode.tsv"; fi
if verdict "$MAIN"; then echo "  ok the per-hit law, the swing costs and the six cells hold"
else echo "  FAIL"; fail=1; fi

echo "== E. the measured table, hash-locked out of tree"
mkdir -p "$OUTDIR"
{ echo "# vanilla_meter_gain.tsv (OUT OF TREE, ../charpages/framedata/) — P1's meter steps per vanilla normal on a"
  echo "# CONNECT (the swing cost, then one step per landed hit), measured on vsavj by tests/test_meter_gain.sh (14z-146)."
  cat "$W/table.tsv"; } > "$OUTDIR/vanilla_meter_gain.tsv"
HSHA="$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$W/table.tsv")"
if [ "${FREEZE:-0}" = 1 ]; then echo "$HSHA  table.tsv (the body, header lines excluded)" > "$HEXP"; echo "  FROZE $HEXP"; fi
if [ "$(cut -c1-64 "$HEXP" 2>/dev/null)" = "$HSHA" ]; then echo "  ok the measured table hashes to the frozen $HEXP ($(grep -c . "$W/table.tsv") rows)"
else echo "  FAIL the meter measurement moved (sha256 $HSHA != frozen) — review $OUTDIR/vanilla_meter_gain.tsv, then FREEZE=1"; fail=1; fi

echo "== F. must-fire control"
perturb_net "$W/table.tsv" "$W/perturbed.tsv"
if verdict "$W/perturbed.tsv" >/dev/null; then vs_ctl_dead perturbed-net "a perturbed net was accepted" || true; fail=1
else vs_ctl_fired perturbed-net "SA 5MP's net moved by one fails law A (section A-D runs the real verdict on it under the mode)"; fi

[ "$fail" -eq 0 ] || { echo "FAIL test_meter_gain"; exit 1; }
echo "PASS: per landed hit the engine pays the record's +0x14; swing costs 0/3/6 equal the sheet's gauge whiff; the six cells are hits-landed residues, not meter residues"
