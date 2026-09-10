#!/bin/sh
# test_rehit_ring.sh — THE MULTI-HIT RE-HIT RULE IS THE RECENT-HIT SLOT, CLEARED
# ON EVERY GAP NODE (14z-146, measured on stock vsavj). The knowledge item the
# 14z-145 close left open: same-id attack windows land ONCE on SA CL.5HK
# (`2(2)3`), THREE times on JE 5HP (`2(5)2(5)2`), FOUR on MO CL.5HK.
#
# THE MECHANISM, static and live (docs/game/engine_internals.md "Multi-hit
# accounting", atlas/ram.md +0x6C/+0x70): the hit test PRG:0x018064 refuses a
# record whose hit id (+0x10) equals the VICTIM's slot `+0x6C[attacker +0x70]`;
# PRG:0x01827C writes the id there at contact; PRG:0x022268 CLEARS the ring
# every engine tick in which the attacker's current node has NO attack record.
# So a same-id record lands again after any gap node, and consecutive attack
# nodes sharing an id land once — which is what tools/frame_data.py derives.
#
# WHAT IT ASSERTS, on three vanilla hit rigs (SA 0x0A, JE 0x0F, MO 0x05; the
# `hit` set of tools/vanilla_join_rig.py, P2 Victor idle, HP re-pinned):
#   1. the only writers of P2's ring are the clearer 0x022276 and the contact
#      install 0x01827C (write tap, PC-attributed);
#   2. STRUCTURE: a skipped clear never falls on a gap-node sample, and every
#      attack-node sample skips the clear except possibly the node's LAST sample
#      (a two-tick frame leaves the node before the clearer runs);
#   3. JE 5HP: three contacts, all hit id 1, the slot CLEARED between each pair;
#      MO CL.5HK: four contacts, ids 1,2,3,4, NO clear between (consecutive
#      attack nodes); SA CL.5HK: ONE contact, and the second window is refused
#      with the slot already clear while P2's midair-hit counter (+0x145) is set
#      and its air-vuln timer (+0x1A4) is zero — the JUGGLE gate at 0x018092,
#      not the dedup; every event's HP drops equal its contact writes;
#   4. the derivation agrees: frame_data's hit segments for the entered chain
#      equal the contacts (JE 3, MO 4) and SA's derived 2 = 1 contact + the
#      juggle refusal.
# CONTROLS (must fire), both on the REAL reducer over a perturbed copy of a
# log: a clear inserted on a non-last attack-node frame fails 2; a contact line
# removed from MO's tap fails 4.
#
# Usage: ROMDIR=... tests/test_rehit_ring.sh   (~4 min, 6 MAME runs in parallel)
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
FIELDS="ff841c:l:node,ff8420:b:cnt,ff8850:w:p2hp,ff886c:b:r0,ff8945:b:p2i145,ff89a4:b:p2i1a4"

echo "== 0. the six legs (tap + field trace per character)"
for pair in "0x0a SA" "0x0f JE" "0x05 MO"; do
    id=${pair%% *}; ch=${pair##* }
    python3 tools/vanilla_join_rig.py gen "$id" hit "$W/$ch.rpl" "$W/$ch.json" >/dev/null
    P="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$W/$ch.json")"
    FR="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$W/$ch.json")"
    ( MAME_BIN="$BIN" MAME_SANDBOX="$W/sbt_$ch" REPLAY="$W/$ch.rpl" POKES="$P" \
        TAP=ff886c,8 WINDOW=2400,"$FR" FRAMES="$FR" TRACE_OUT="$W/$ch.tap" \
        tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/tap_writes.lua" > "$W/$ch.tap.out" 2>&1 || true ) </dev/null &
    ( MAME_BIN="$BIN" MAME_SANDBOX="$W/sbf_$ch" REPLAY="$W/$ch.rpl" POKES="$P" \
        FIELDS="$FIELDS" FIELD_OUT="$W/$ch.ft" FIELD_FROM=2400 FIELD_TO="$FR" FRAMES="$FR" \
        tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$ch.ft.out" 2>&1 || true ) </dev/null &
done
wait
for pair in "0x0a SA" "0x0f JE" "0x05 MO"; do
    id=${pair%% *}; ch=${pair##* }
    [ -s "$W/$ch.tap" ] && [ -s "$W/$ch.ft" ] || { echo "  FAIL $ch: a leg produced no log (see $W/$ch.*.out)"; fail=1; continue; }
    python3 tools/rehit_ring.py "$W/$ch.tap" "$W/$ch.ft" "$W/$ch.json" "$DATA" "$id" > "$W/$ch.red"
    python3 tools/vanilla_frames.py "$DATA" --char "$ch" --json "$W/${ch}_d.json" >/dev/null
    sed 's/^/        /' "$W/$ch.red" | grep -v '^        #'
done
[ "$fail" -eq 0 ] || { echo "FAIL test_rehit_ring"; exit 1; }

# the ONE verdict function, used on the real logs and on the perturbed copies
verdict() {  # $1 = reduced file, $2 = char, $3 = derived json  -> exit 0/1, prints reasons
    python3 - "$1" "$2" "$3" <<'PY'
import json, re, sys
red, ch, dj = sys.argv[1], sys.argv[2], sys.argv[3]
lines = [l for l in open(red) if not l.startswith("#")]
bad = []
w = next(l for l in lines if l.startswith("WRITERS")).split()[1:]
if w != ["01827c", "022276"]: bad.append(f"writers {w} != [01827c, 022276]")
st = dict(kv.split("=") for kv in next(l for l in lines if l.startswith("STRUCT")).split()[1:])
if st["skipped_on_gap"] != "0": bad.append(f"a clear was SKIPPED on a gap-node sample ({st['skipped_on_gap']})")
if st["cleared_on_attack_not_last"] != "0": bad.append(f"a clear fell on a non-last attack-node sample ({st['cleared_on_attack_not_last']})")
if int(st["attack_samples"]) < 10: bad.append("too few attack samples — the rig did not attack")
ev = {}
for l in lines:
    if l.startswith("EVENT"):
        f = l.split(); ev[f[1]] = dict(kv.split("=", 1) for kv in f[2:])
chains = json.load(open(dj))["characters"][ch]["chains"]
def derived_hits(chain):
    # the notation is frame_data's runs grammar: hits are the numbers OUTSIDE the (gap) parentheses
    n = re.sub(r"\(\d+\)", ",", chains[chain]["frame_data"]["notation"])
    return len([t for t in n.split(",") if t])
for b, e in ev.items():
    if e["contacts"] != e["hp_drops"]: bad.append(f"{b}: contacts {e['contacts']} != hp drops {e['hp_drops']}")
want = {("JE", "HP"): (3, r"^1@\d+,1@\d+\+,1@\d+\+$", 0), ("MO", "HK"): (4, r"^1@\d+,2@\d+=,3@\d+=,4@\d+=$", 0), ("SA", "HK"): (1, r"^1@\d+$", 1)}
for (c, b), (n, pat, jug) in want.items():
    if c != ch: continue
    e = ev[b]
    if int(e["contacts"]) != n: bad.append(f"{b}: {e['contacts']} contacts, expected {n}")
    if not re.match(pat, e["ids"]): bad.append(f"{b}: ids {e['ids']} do not match {pat}")
    if (int(e["juggle_refusal_frames"]) > 0) != bool(jug): bad.append(f"{b}: juggle refusal frames {e['juggle_refusal_frames']}, expected {'some' if jug else 'none'}")
    d = derived_hits(e["chain"])
    if d != n + jug: bad.append(f"{b}: derived {d} hit segments on {e['chain']} vs {n} contacts + {jug} juggle refusal")
if bad:
    print("\n".join("    " + x for x in bad)); sys.exit(1)
PY
}

echo "== 1-4. the verdicts"
for ch in SA JE MO; do
    if verdict "$W/$ch.red" "$ch" "$W/${ch}_d.json"; then echo "  ok $ch: writers, structure, contacts and derivation agree"
    else echo "  FAIL $ch"; fail=1; fi
done

echo "== 5. must-fire controls on the real reducer"
# (a) a clear inserted on a NON-LAST attack-node frame of JE's 5HP window -> STRUCT fails
python3 - "$W" <<'PY'
import re, sys
W = sys.argv[1]
ft = {int(m.group(1)): m.group(2) for m in (re.match(r"F (\d+) (.*)", l) for l in open(f"{W}/JE.ft")) if m}
# the first HP-window frame where P1 is on an attack node with cnt > 1 and the tap did NOT clear
tap = open(f"{W}/JE.tap").read().splitlines()
cleared = {int(m.group(1)) for m in (re.match(r"frame (\d+) PC 022276", l) for l in tap) if m}
cands = [f for f, s in ft.items() if 3560 <= f < 3700 and f not in cleared and "cnt=1 " not in s + " " and re.search(r"cnt=(\d+)", s) and int(re.search(r"cnt=(\d+)", s).group(1)) > 1]
f = cands[0]
tap.insert(0, f"frame {f} PC 022276 off ff886c data 00000000 mask 0000ffff")
open(f"{W}/JEc.tap", "w").write("\n".join(tap) + "\n")
PY
python3 tools/rehit_ring.py "$W/JEc.tap" "$W/JE.ft" "$W/JE.json" "$DATA" 0x0f > "$W/JEc.red"
if verdict "$W/JEc.red" JE "$W/JE_d.json" >/dev/null; then echo "  FAIL control (a): a clear on a non-last attack-node frame was accepted"; fail=1
else echo "  ok control (a) fired: a clear inserted on a non-last attack-node frame fails the structure check"; fi
# (b) one contact line removed from MO's tap -> 3 contacts vs 4 derived
grep -v "PC 01827c off ff886c data 00000303" "$W/MO.tap" > "$W/MOc.tap"
python3 tools/rehit_ring.py "$W/MOc.tap" "$W/MO.ft" "$W/MO.json" "$DATA" 0x05 > "$W/MOc.red"
if verdict "$W/MOc.red" MO "$W/MO_d.json" >/dev/null; then echo "  FAIL control (b): a missing contact was accepted"; fail=1
else echo "  ok control (b) fired: a contact removed from MO's log fails the contact/derivation check"; fi

[ "$fail" -eq 0 ] || { echo "FAIL test_rehit_ring"; exit 1; }
echo "PASS: the re-hit rule is the recent-hit slot cleared on gap nodes — JE 5HP 3 contacts (slot cleared between), MO CL.5HK 4 (ids 1-4, consecutive), SA CL.5HK 1 + a juggle-gate refusal; writers and structure as stated"
