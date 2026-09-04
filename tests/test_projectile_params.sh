#!/bin/sh
# test_projectile_params.sh — THE PROJECTILE PARAMETERS (character-data map
# phase 3, 14z-121): every $FF9400-pool projectile type's inline parameter
# tables, decoded from the type HANDLER (tools/projectile_params.py) and
# MEASURED on the live spawn.
#
# WHAT IT HOLDS.
#   1. the decoder's rows for the eight handlers on NATIVE vs2 (walker-2 table
#      0x5C620[type]: 0x3E Blizzard Sword; 0x40/0x41/0x42 Sol Smasher ground/
#      air, Cosmo Disruption; 0x44..0x47 Mighty Launcher, Plasma Trap, Final
#      Guardian Beta, Erasing Sphere) equal tests/expected/projectile_params.txt
#      (FREEZE=1 re-freezes — only after a change is attributed);
#   2. OURS == VS2: the same decoder on each build's OPCODE view (verify_op.bin)
#      at the handler's PLACED address (patch/placements.json) yields the same
#      rows — the port carries the parameters byte-for-byte inside the ported
#      code regions (x066ec4 on Donovan; x0672d0..x0689cc on Pyron and Huitzil);
#   3. LIVE: on the census rigs (tests/replays/naming/{donovan_2,pyron_2,
#      pyron_4,huitzil_2,huitzil_4}) every spawn's slot fields at its first
#      sampled frame match the decoded row selected by the slot's +0x9A (the
#      variant: 0/2/4 = LP/MP/HP, 6 = ES) — +0x40/+0x44 (x/y velocity, 16.16,
#      negated when the slot's flip_x +0x0B is 0), +0x48/+0x4C (accelerations),
#      +0x50, and +0x26 (the byte, or the HIGH byte of a word-table type: Plasma Trap, Erasing Sphere) — allowing ONE tick (the handler may run once
#      before frame_done: velocity += acceleration, +0x26 -= 1 unless already 0). Cosmo
#      Disruption (immediate-shaped, seven orbiting pieces) is exempt from 3
#      and reported.
#   4. negative control: a decoded row with one velocity word perturbed must
#      FAIL the live compare.
#
# Emulator tier (MAME, ~3 min: five native legs in parallel). ROM-free parts
# (1, 2) run first and alone when NOLIVE=1.
# Usage: ROMDIR=... [MAME_BIN=...] [DON=build/don_m20 PYR=build/pyron38 HUI=build/hui54] [NOLIVE=1] [FREEZE=1] tests/test_projectile_params.sh
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier emulator (MAME, ~3 min; `NOLIVE=1` = the ROM-free half)) THE
#   PROJECTILE PARAMETERS (14z-121, phase 3): `tools/projectile_params.py`
#   decodes every `$FF9400` type handler's inline init (walker-2 table
#   `0x5C620[type]`; `+0x9A` → `+0x26/+0x50` and an `(xv, xacc, yv, yacc)`
#   record; Cosmo = immediates) — rows frozen in
#   `tests/expected/projectile_params.txt` (`FREEZE=1`); the same decoder on
#   each build's `verify_op.bin` at the placed handler must equal vs2 (ours ==
#   vs2, three builds); the five census rigs' live spawns must match their
#   rows (27 tabled spawns, one tick allowed; the seven tabled types each
#   measured); a perturbed row must fail. Run after any change to the decoder,
#   the rigs, or a projectile handler region
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
DON="${DON:-build/don_m20}"; PYR="${PYR:-build/pyron38}"; HUI="${HUI:-build/hui54}"
W="$(mktemp -d "${TMPDIR:-/tmp}/projparams.XXXXXX")"; trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
EXP="tests/expected/projectile_params.txt"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/vs2_op.bin" || { echo "SKIP: no vsav2 opcode view (set ROMDIR to build the cache)"; exit 0; }
VS2="$W/vs2_op.bin"
HANDLERS="66ec4 672d0 67550 67846 6800c 68458 68768 689cc"

echo "== 1. the decoder's rows on native vs2 == the frozen expectation"
python3 tools/projectile_params.py "$VS2" $HANDLERS --json "$W/vs2.json" | grep -v '^#' > "$W/vs2.txt" || bad "decoder failed"
if [ "${FREEZE:-0}" = 1 ]; then cp "$W/vs2.txt" "$EXP"; echo "  FROZE  $EXP ($(wc -l < "$EXP" | tr -d ' ') lines)"; fi
if diff -u "$EXP" "$W/vs2.txt" > "$W/d1.txt"; then ok "$(wc -l < "$W/vs2.txt" | tr -d ' ') decoder lines identical to $EXP"; else bad "decoder rows differ from $EXP:"; head -20 "$W/d1.txt"; fi
n="$(grep -c '^  idx' "$W/vs2.txt" | tr -d ' ')"; [ "$n" -ge 24 ] && ok "$n evaluated rows" || bad "only $n rows"

echo "== 2. OURS == VS2 on every build's opcode view at the placed handler"
for b in "$DON" "$PYR" "$HUI"; do
    [ -s "$b/verify_op.bin" ] && [ -s "$b/patch/placements.json" ] || { bad "$b: verify_op.bin / placements.json missing"; continue; }
    python3 - "$b" "$VS2" "$W/vs2.json" <<'PY' || fail=1
import json, sys, subprocess
sys.path.insert(0, "tools")
import projectile_params as pp
b, vs2, vs2json = sys.argv[1:4]
regs = json.load(open(f"{b}/patch/placements.json"))["regions"]
ours = open(f"{b}/verify_op.bin", "rb").read()
vs2rows = {r["handler"]: r for r in json.load(open(vs2json))}
n = 0
for h, r in vs2rows.items():
    a = int(h, 16)
    for name, reg in regs.items():
        try: src, dst, ln = reg["src"], reg["dst"], reg["len"]
        except KeyError: continue
        if src <= a < src + ln:
            d = pp.decode(ours, dst + a - src)
            def strip(x):   # placement-dependent fields out: addresses, the raw tables, the immediates' PCs
                y = {k: v for k, v in x.items() if k not in ("handler", "init", "tables")}
                if "immediates" in y: y["immediates"] = [{k: v for k, v in i.items() if k != "pc"} for i in y["immediates"]]
                return y
            if d["shape"] != r["shape"] or strip(d) != strip(r):
                print(f"  FAIL  {b}: type handler vs2 {h} (region {name}, ours {dst + a - src:#x}) decodes DIFFERENTLY from vs2"); sys.exit(1)
            n += 1
print(f"  ok    {b}: {n} handler(s) present, rows identical to vs2 (values ride inside the ported regions)")
PY
done

[ "${NOLIVE:-0}" = 1 ] && { [ $fail = 0 ] && echo PASS || echo FAIL; exit $fail; }
: "${ROMDIR:?set ROMDIR}"
echo "== 3. the live spawns on the census rigs (native vs2)"
FS="$(python3 -c "
fs=[]
for n in range(32):
    b=0xff9400+0x100*n
    for off,sz,nm in ((2,'b','t'),(0x9a,'b','v'),(0x0b,'b','f'),(0x26,'b','c26'),(0x50,'w','c50'),(0x40,'l','xv'),(0x44,'l','yv'),(0x48,'l','xa'),(0x4c,'l','ya')):
        fs.append(f'{b+off:x}:{sz}:{nm}{n:02d}')
print(','.join(fs))")"
for rig in donovan_2 pyron_2 pyron_4 huitzil_2 huitzil_4; do
    t="${rig%_*}"; p="${rig##*_}"
    python3 tools/name_moves.py gen "$t" "$p" "$W/$rig.rpl" "$W/$rig.json" > /dev/null || bad "gen $rig"
    cmp -s "$W/$rig.rpl" "tests/replays/naming/$rig.rpl" && cmp -s "$W/$rig.json" "tests/replays/naming/$rig.json" || bad "$rig: tests/replays/naming/$rig.* drifted — regenerate"
    P="$(python3 -c "import json;print(';'.join(json.load(open('$W/$rig.json'))['pokes']))")"
    FR="$(python3 -c "import json;print(json.load(open('$W/$rig.json'))['frames'])")"
    ( cd "$W" && MAME_SANDBOX="$W/sb_$rig" REPLAY="$W/$rig.rpl" POKES="$P" FIELDS="$FS" FIELD_OUT="$W/live_$rig.txt" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
      "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/live_$rig.log" 2>&1 ) </dev/null &
done
wait
cat > "$W/compare.py" <<'PY'
import json, sys, glob, os
vs2 = sys.argv[1]; W = sys.argv[2]; perturb = sys.argv[3] == "perturb"
dec = json.load(open(vs2)); byh = {int(r["handler"], 16): r for r in dec}
tab = open(sys.argv[4], "rb").read()
def handler(t): return int.from_bytes(tab[0x5C620 + t * 4:0x5C620 + t * 4 + 4], "big")
if perturb:
    for r in dec:
        if r["shape"] == "B" and r["rows"]: r["rows"][0]["xv"] += 0x100; break
match = nomatch = cosmo = 0; lines = []
for f in sorted(glob.glob(f"{W}/live_*.txt")):
    rig = os.path.basename(f)[5:-4]; sched = json.load(open(f"{W}/{rig}.json"))
    rows = {}
    for l in open(f):
        p = l.split()
        if len(p) < 3 or p[0] != "F": continue
        rows[int(p[1])] = {k: int(v) for k, v in (kv.split("=") for kv in p[2:])}
    frames = sorted(rows)
    for e in sched["events"]:
        if e["name"].startswith("walk-in"): continue
        t0, t1 = e["frame"], e["frame"] + e["gap"]
        for s in range(32):
            k = f"{s:02d}"
            alive = [fr for fr in frames if t0 <= fr < t1 and rows[fr].get("t" + k)]
            if not alive or alive[0] == t0 or rows.get(alive[0] - 1, {}).get("t" + k): continue
            f0 = alive[0]; v0 = rows[f0]; ty = v0["t" + k]; d = byh.get(handler(ty))
            if d is None: continue
            if d["shape"] == "immediate":
                cosmo += 1; lines.append(f"{rig}\t{e['name']}\ttype {ty:#04x}\timmediate-shape (exempt)"); continue
            sgn = -1 if v0["f" + k] == 0 else 1
            cands = [r for r in d["rows"] if r["index"].get("+0x9A") == v0["v" + k]]
            verdict = None
            for r in cands:
                for tick in (0, 1):
                    if (v0["xv" + k] == sgn * (r["xv"] + tick * r["xa"]) and v0["yv" + k] == r["yv"] + tick * r["ya"]
                            and v0["xa" + k] == sgn * r["xa"] and v0["ya" + k] == r["ya"] and v0["c50" + k] == r["+0x50"]
                            and (v0["c26" + k] == max(r["+0x26"] - tick, 0) if r.get("+0x26_kind", "b") == "b" else v0["c26" + k] in ((r["+0x26"] >> 8), (r["+0x26"] - tick) >> 8))):
                        verdict = f"MATCH +0x9A={v0['v' + k]} tick={tick}"
            if verdict: match += 1
            else: nomatch += 1; verdict = f"NO MATCH live xv={v0['xv'+k]} yv={v0['yv'+k]} xa={v0['xa'+k]} ya={v0['ya'+k]} c26={v0['c26'+k]} c50={v0['c50'+k]} +0x9A={v0['v'+k]}"
            lines.append(f"{rig}\t{e['name']}\ttype {ty:#04x}\t{verdict}")
print("\n".join(lines)); print(f"SUMMARY match={match} nomatch={nomatch} cosmo={cosmo}")
sys.exit(1 if nomatch or match < 20 else 0)
PY
if python3 "$W/compare.py" "$W/vs2.json" "$W" "" "$VS2" > "$W/live.txt"; then ok "every tabled spawn matches its decoded row: $(tail -1 "$W/live.txt")"; else bad "live spawns disagree with the decoder:"; grep -v "MATCH +" "$W/live.txt" | head -20; fi
for t in 0x3e 0x40 0x41 0x44 0x45 0x46 0x47; do grep -q "type $t	MATCH" "$W/live.txt" && ok "type $t measured live" || bad "type $t: no live MATCH"; done

echo "== 4. negative control: a perturbed decoded row must fail the live compare"
if python3 "$W/compare.py" "$W/vs2.json" "$W" perturb "$VS2" > /dev/null 2>&1; then bad "control: a perturbed xv PASSED — the compare is not checking"; else ok "control: a perturbed xv fails the live compare"; fi

[ $fail = 0 ] && echo PASS || echo FAIL
exit $fail
