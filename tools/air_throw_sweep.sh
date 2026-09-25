#!/bin/sh
# air_throw_sweep.sh — THE AIR-THROW RIG SWEEPS OF GitHub #169, rerunnable (14z-181, [VSP-18]).
#
# An INSTRUMENT, not a gate: it prints which chain each of pyron_3's two Galactic Throw events
# enters on NATIVE vs2 while ONE rig variable is swept, the pair otherwise as tests/test_move_naming
# runs it (the committed schedule's own pokes, no level or RNG pin: vsav2's default speed level 8). It asserts nothing; the frozen truth is
# tests/expected/move_naming_pyron.txt. The 14z-181 results are build/agent181/air_throw_sweeps_14z181.txt.
#
# Modes (one per run):
#   walk   — the walk-in length before the event's 40-frame pause, W in WALKS (default "30 45 60 75 90 105 120 135 150"),
#            no pin at the walk's end (the 14z-181 section 1: P2 with P1, i.e. LEAD=0)
#   lead   — P2's jump offset relative to P1's, d in LEADS (default "-3 -2 -1 0 1 2 3"), pair pinned at 858/898
#   phase  — the committed recipe at schedule shifts SHIFTS (default "0 1 2 3 4 5 6 7 8 9 10 11 12": every level-6 phase)
#   press  — P1's toward+button offset, A in PRESSES (default "4 6 8 10 12 14 16 18 20 22 24 28"), pair pinned at 858/898
#   xpin   — the pair pinned still at (X, X+40), X in XS (default "700 760 826 858 890 950"), press +14
# LEAD (default: the committed recipe's, -2) sets P2's jump offset for walk/press/xpin/phase — the 14z-181
# sections 1-3 were measured at LEAD=0 (P2 with P1), so `LEAD=0 ... walk|xpin|press` reruns them. For
# lead/press/xpin the pair is pinned at t-40..t-38 (the walk's end overwritten) so the walk is not a second
# variable; every other input is what the committed rig generates.
#
# Usage: ROMDIR=... [MAME_BIN=...] [PYR=build/pyron42] [LEAD=n] tools/air_throw_sweep.sh <walk|lead|phase|press|xpin> [out_dir]
#   MAME, native only, one leg per value in parallel; ~1 min per batch of legs.
set -u
ROMDIR="${ROMDIR:?set ROMDIR}"; REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
PYR="${PYR:-build/pyron42}"; EX="$PYR/extract"
MODE="${1:?mode: lead|phase|press|xpin}"; OUT="${2:-$(mktemp -d)}"; case "$OUT" in /*) ;; *) OUT="$REPO/$OUT" ;; esac; mkdir -p "$OUT/chains"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$EX/regions.json" ] || { echo "SKIP: no extract at $EX"; exit 0; }
python3 - "$EX" "$OUT/chains" <<'PY'
import json, subprocess, sys
ex, w = sys.argv[1], sys.argv[2]
rj = json.load(open(f"{ex}/regions.json")); r = rj["regions"]["anim"]
ptr = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if v["table"].startswith("anim_index")}
for name in ("a", "a2", "b", "c", "proj"):
    subprocess.check_call(["python3", "tools/anim_nodes.py", f"{ex}/region_anim.bin", "--base", hex(r["src"]), "--table", hex(ptr["anim_index_" + name]), "--name", name, "--end", hex(r["src"] + r["len"]), "--json", f"{w}/{name}.json"], stdout=subprocess.DEVNULL)
PY
LEAD="${LEAD:--2}"; export LEAD
case "$MODE" in
    walk)  VALS="${WALKS:-30 45 60 75 90 105 120 135 150}" ;;
    lead)  VALS="${LEADS:--3 -2 -1 0 1 2 3}" ;;
    phase) VALS="${SHIFTS:-0 1 2 3 4 5 6 7 8 9 10 11 12}" ;;
    press) VALS="${PRESSES:-4 6 8 10 12 14 16 18 20 22 24 28}" ;;
    xpin)  VALS="${XS:-700 760 826 858 890 950}" ;;
    *) echo "unknown mode $MODE"; exit 2 ;;
esac
echo "== air_throw_sweep $MODE: $VALS (native vs2, pyron_3; LEAD=$LEAD$([ "$MODE" = lead ] && echo ' ignored: the swept value'))"
for V in $VALS; do
python3 - "$OUT" "$MODE" "$V" <<'PY'
import sys, os, json, re; sys.path.insert(0, 'tools'); import name_moves as nm
OUT, mode, V = sys.argv[1], sys.argv[2], int(sys.argv[3])
lead = V if mode == "lead" else int(os.environ.get("LEAD", "-2"))
tag = f"{mode}{V}"
if mode == "phase": nm.FIRST_EVENT += V
nm.gen('pyron', '3', f'{OUT}/{tag}.rpl', f'{OUT}/{tag}.json')
s = json.load(open(f'{OUT}/{tag}.json'))
ev = [e['frame'] for e in s['events'] if e['name'].startswith('Galactic')]
if mode in ("lead", "press", "xpin"):
    X = V if mode == "xpin" else 858
    for t in ev:
        for f in (t - 40, t - 39, t - 38): s['pokes'] += [f"{f}:ff8410:{X:04x}", f"{f}:ff8810:{X + 40:04x}"]
    json.dump(s, open(f'{OUT}/{tag}.json', 'w'))
out = []
for l in open(f'{OUT}/{tag}.rpl').read().splitlines():
    m = re.match(r'^(\d+)-(\d+) (p[12])=(.*)$', l)
    if m:
        a, b, who, tok = int(m.group(1)), int(m.group(2)), m.group(3), m.group(4)
        t = next((t for t in ev if t - 200 <= a <= t + 40), None)
        if t is not None:
            if who == 'p2' and tok == 'U' and t - 5 <= a: l = f"{t + lead}-{t + lead + 2} p2=U"
            if mode == "press" and who == 'p1' and tok in ('R2', 'R3'): l = f"{t + V}-{t + V + 3} p1={tok}"
            if mode == "walk" and who == 'p1' and tok == 'R' and b == t - 40: l = f"{t - 40 - V}-{t - 40} p1=R"
    out.append(l)
open(f'{OUT}/{tag}.rpl', 'w').write("\n".join(out) + "\n")
PY
    tag="$MODE$V"; mkdir -p "$OUT/sb$tag"
    POKES="$(python3 -c "import json;print(';'.join(json.load(open('$OUT/$tag.json'))['pokes']))")"; FR="$(python3 -c "import json;print(json.load(open('$OUT/$tag.json'))['frames'])")"
    ( cd "$OUT" && MAME_SANDBOX="$OUT/sb$tag" REPLAY="$OUT/$tag.rpl" POKES="$POKES" \
      FIELDS="ff841c:l:node,ff8420:b:cnt,ff8406:b:seq,ff8407:b:sub,ff8414:w:y,ff8109:b:timer,ff8782:b:id,ff881c:l:p2node,ff802e:b:df,ff840b:b:face,ff8b82:b:p2id,ff8410:w:x,ff8810:w:p2x,ff8814:w:p2y" \
      FIELD_OUT="$OUT/trace_$tag.txt" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
      "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$OUT/out_$tag.log" 2>&1; rm -rf "$OUT/sb$tag" ) </dev/null &
done
wait
for V in $VALS; do
    tag="$MODE$V"; [ -s "$OUT/trace_$tag.txt" ] || { echo "$tag: VOID (no samples)"; continue; }
    printf '%-9s ' "$tag:"; python3 tools/name_moves.py expect "$OUT/$tag.json" "$OUT/trace_$tag.txt" "$OUT/chains" | grep 'Galactic' | cut -f2,3 | tr '\n' ' '
    python3 - "$OUT" "$tag" <<'PY'
import sys, json; sys.path.insert(0, 'tools'); import move_parity as mp
OUT, tag = sys.argv[1:3]; s = json.load(open(f'{OUT}/{tag}.json')); t = mp.load_trace(f'{OUT}/trace_{tag}.txt')
ev = [e['frame'] for e in s['events'] if e['name'].startswith('Galactic')]
print('| y at +14 P1/P2:', ' '.join(f"{t[f+14]['y']}/{t[f+14]['p2y']}" for f in ev), '| x:', ' '.join(f"{t[f]['x']}/{t[f]['p2x']}" for f in ev))
PY
done
