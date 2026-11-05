#!/bin/sh
# audit_beam_slide.sh — #363, FROZEN AS THE BUG STANDS: PHOBOS'S ES PLASMA BEAM SLIDES THE VICTIM ON OURS WHERE NATIVE vs2
# HOLDS HIM (14z-221; the maintainer, 2026-11-05: "this finding is indeed mechanical NOT cosmetic, thus of greater
# severity", then "Yes. Make the new bug related to #358").
#
# WHAT: the beam hits with reaction class 0x4F on both games. vs2's reaction table PRG:0x022388 sends row 0x4F to a
#   handler (PRG:0x02296C: sub 08, the victim held in place); vsavj's table PRG:0x02385C sends rows 0x4E and 0x4F to its
#   default row (row 0's target PRG:0x0238FC), which runs the pushback slide, and our build carries vsavj's table. On
#   naming part huitzil_4 (P2 Demitri), Plasma Beam (ES) [PP] and [KK]: Demitri slides 81 px on the ground on ours and
#   ends the event 49 px further from Phobos than on native. Mechanism: docs/game/engine_internals.md, "Rows 0x4E and
#   0x4F of vsavj's reaction table are DEFAULT rows". The legacy side (no reachable legacy record carries class 0x4E or
#   0x4F, in either game) is frozen by tests/test_reaction_classes.sh (its `records unused<50` rows), not here.
#   THIS GATE GOES RED WHEN #363 IS FIXED, BY DESIGN: the fix re-points rows 0x4E/0x4F (step 0 fails first, naming it)
#   and the slide disappears; the fix's commit re-freezes it to expect native's hold.
# HOW: step 0 reads the opcode images (tests/lib/decrypt_cache.sh for pristine vsavj and vsav2, BUILD's verify_op.bin):
#   the three tables' rows 0x00, 0x4E and 0x4F. Step 1 runs MAME (non-debug, tests/lua/beam_slide_tap.lua, f2560-3080)
#   on native vsav2 and on ours (BUILD) with the parity gate's protocol (real cursor picks, speed level pinned 6 from
#   f2000, RNG 0000 from f2363, the part's own X pins at 2560/2800/3040). Each beam is judged in its event window
#   [2600, 2800) and [2840, 3040), cut before the next X pin.
# EXPECTS (frozen 14z-221 from build/agent221/t358/push2/ and p2x/p2x_events.tsv, build m3b_merged33 at 0ddac362): both
#   legs complete (END) with P1's x equal on both legs through each window; in each window the hits give +0x54 = 0x4F on
#   both legs (the same first 0x4F frame, f2640 and f2880, and the same P2 HP on the window's last frame before the rig's own HP pin:
#   f2799 and f2949, the part pins P2's HP at 2950 on both legs); native: P2 x constant
#   while +0x54 is 0x4F, sub 08 seen; ours: the slide (seq 02 seen) moves P2 x by +81 (0x51) from the first 0x4F frame to the frame after the last; at the
#   window's last frame ours' P2 x minus native's is +49 (0x31).
#   Not covered: the other ported moves that may carry 0x4E or 0x4F (not measured); row 0x4E's handler; Demitri as P1;
#   FBNeo and MiSTer; the P2 position census over all 526 parity events (FIELDS_EXTRA on tests/audit_move_parity.sh with
#   tools/move_parity_p2x.py — a measurement, not frozen).
# MUST-FIRE: perturbed-copy: held — ours' P2 x trace replaced by native's (no slide) must fail the slide and end-offset checks, so the gate cannot pass on a build where the victim is held (in-gate; mode: the copy replaces ours and the gate FAILs)
# MUST-FIRE: perturbed-copy: class-cleared — native's +0x54 column zeroed must fail the class check, so the class is read from the trace (in-gate; mode: the copy replaces native and the gate FAILs)
# FOLLOWS: build/manifest/ emu/mame-patches/ tools/setup_mame.sh tools/run_mame.sh tools/name_moves.py tests/lua/beam_slide_tap.lua tests/lua/emu_clock.lua
#   tests/lua/pokes_spec.lua tests/replays/naming/huitzil_4.json tests/replays/naming/huitzil_4.rpl tests/lib/decrypt_cache.sh tests/lib/controls.sh
#
# SHEET: none — the beam's capture sheets for the maintainer are #358's (build/agent221/t358/sheets/, local); this gate judges P2's state words only
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged33] [KEEP=<dir>: the two traces are copied there] tests/audit_beam_slide.sh
#   emulator tier, MAME; 2 runs
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged33}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] && [ -f "$BUILD/verify_op.bin" ] || { echo "SKIP: no WIDE build with verify_op.bin at $BUILD"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT; trap 'exit 143' INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
echo "  host  $(uname -sm); MAME_BIN $MAME_BIN; build $(basename "$BUILD")"

echo "== 0. the reaction tables' rows 0x4E and 0x4F (opcode view)"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_data.bin" || { vs_ctl_nj "no vsavj view"; echo "FAIL: audit_beam_slide (no vsavj view)"; exit 1; }
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_data.bin" || { vs_ctl_nj "no vsav2 view"; echo "FAIL: audit_beam_slide (no vsav2 view)"; exit 1; }
python3 - "$W/vj_op.bin" "$W/v2_op.bin" "$BUILD/verify_op.bin" <<'PY' || fail=1
import struct, sys
def rows(path, tab):
    o = open(path, "rb").read()
    return [tab + struct.unpack(">h", o[tab + 2 * i:tab + 2 * i + 2])[0] for i in (0x00, 0x4E, 0x4F)]
want = {"vsavj": (sys.argv[1], 0x02385C, [0x0238FC, 0x0238FC, 0x0238FC]),
        "vsav2": (sys.argv[2], 0x022388, [0x022430, 0x0226E0, 0x02296C]),
        "ours":  (sys.argv[3], 0x02385C, [0x0238FC, 0x0238FC, 0x0238FC])}
bad = 0
for g, (p, tab, w) in want.items():
    r = rows(p, tab)
    s = f"{g} table {tab:#08x}: row 0x00 -> {r[0]:#08x}, 0x4E -> {r[1]:#08x}, 0x4F -> {r[2]:#08x}"
    if r == w: print(f"  ok    {s}")
    else:
        bad = 1
        print(f"  FAIL  {s}; frozen " + ", ".join(f"{x:#08x}" for x in w)
              + (" — ours' rows were re-pointed: if this is #363's fix, re-freeze this gate to expect native's hold" if g == "ours" else ""))
sys.exit(bad)
PY
[ "$fail" = 0 ] || vs_ctl_nj "step 0's reaction-table precondition failed, not the control"

echo "== 1. the legs: native vsav2 / ours $(basename "$BUILD") (huitzil_4, f2560-3080)"
J="$REPO/tests/replays/naming/huitzil_4.json"; R="$REPO/tests/replays/naming/huitzil_4.rpl"
FR=3100
PK="$(python3 -c "import json,sys;print(';'.join(p for p in json.load(open(sys.argv[1]))['pokes'] if int(p.split(':')[0].split('-')[0]) < 3100))" "$J");2000-$((FR-1)):ff8116:06;2363-$((FR-1)):ff80d4:0000"
awk -v path="D D D" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
    for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
    /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$R" > "$W/ours.rpl"
leg() {  # leg <name> <set> <rompath> <rpl>
    mkdir -p "$W/$1"
    ( cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$PK" FRAMES="$FR" SOUT="$W/$1/st" \
        SFROM=2560 STO=3080 timeout 900 "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/beam_slide_tap.lua" > "$W/$1/mame.log" 2>&1
      rm -rf "$W/$1/sb" ) </dev/null || true
}
leg native vsav2 "$ROMDIR" "$R" &
leg ours vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" &
wait
[ -z "${KEEP:-}" ] || { mkdir -p "$KEEP"; cp "$W/native/st" "$KEEP/native.st" 2>/dev/null || true; cp "$W/ours/st" "$KEEP/ours.st" 2>/dev/null || true; }

echo "== 2. the checks"
W="$W" MODE="$MODE" PK="$PK" python3 - <<'PY' || fail=1
import os, sys
W, MODE = os.environ["W"], os.environ["MODE"]
# the rig's own P2 HP pins (the part's `ff8850` pokes, given to BOTH legs): an HP compare after one inside a window would
# be forced to agree (rule-checker run 2026-11-05-1647: the 2950 pin sits in the KK window), so HP is compared on the
# frame before the window's first pin
HPPIN = sorted(int(p.split(":")[0].split("-")[0]) for p in os.environ["PK"].split(";") if p and p.split(":")[1].lower() == "ff8850")
WIN = {"PP": (2600, 2800, 2640), "KK": (2840, 3040, 2880)}       # event window [a, b) and the frozen first 0x4F frame
SLIDE, END = 0x51, 0x31                                          # frozen 14z-221: ours' slide, ours - native at the window's end
fail = 0
def bad(m):
    global fail; fail = 1; print(f"  FAIL  {m}")
def ok(m): print(f"  ok    {m}")
def load(path):
    try: lines = open(path).read().splitlines()
    except OSError: return None
    P, end = {}, None
    for l in lines:
        t = l.split()
        if t and t[0] == "P": P[int(t[1])] = {k: int(v, 16) for k, v in (x.split("=") for x in t[2:])}
        elif t and t[0] == "END": end = int(t[1])
    return P if end is not None and P else None
L = {g: load(f"{W}/{g}/st") for g in ("native", "ours")}
dead = [g for g, x in L.items() if not x or any(f not in x for f in range(2560, 3041))]
if dead:
    if MODE: print(f"NOT JUDGED: under control mode {MODE}, the {', '.join(dead)} leg never reached its END line with every frame 2560-3040")
    print(f"  FAIL  {', '.join(dead)}: the tap never reached its END line with every frame 2560-3040 — VOID"); sys.exit(1)
def perturb(x, src, key):
    return {f: dict(v, **{key: src[f][key]}) for f, v in x.items()}
def judge(n, o, quiet=False):
    out = []
    for nm, (a, b, h) in WIN.items():
        fr = range(a, b)
        p1 = [f for f in fr if n[f]["p1x"] != o[f]["p1x"]]
        if p1: out.append(f"[{nm}] P1's x differs from f{p1[0]} — the two legs do not play the same move"); continue
        hn = [f for f in fr if n[f]["c54"] == 0x4F]; ho = [f for f in fr if o[f]["c54"] == 0x4F]
        if not hn or not ho or hn[0] != h or ho[0] != h:
            out.append(f"[{nm}] first +0x54 = 0x4F frame native {hn[:1]}, ours {ho[:1]}, frozen {h}"); continue
        hf = min([p for p in HPPIN if a < p < b] + [b]) - 1
        if n[hf]["hp"] != o[hf]["hp"]: out.append(f"[{nm}] P2 HP at f{hf} (before the rig's HP pin): native {n[hf]['hp']:#x}, ours {o[hf]['hp']:#x}")
        nx = {n[f]["x"] for f in hn}; held = any(n[f]["sub"] == 0x08 for f in hn)
        slide = o[ho[-1] + 1]["x"] - o[ho[0]]["x"]; seq2 = any(o[f]["seq"] == 0x02 for f in ho)
        endd = o[b - 1]["x"] - n[b - 1]["x"]
        msg = (f"[{nm}] class 0x4F from f{h} on both; native P2 x {'constant ' + format(min(nx), '#x') if len(nx) == 1 else 'moves ' + str(sorted(nx))}"
               f" while 0x4F (sub 08 {'seen' if held else 'NOT seen'}); ours slides {slide:+d} px (seq 02 {'seen' if seq2 else 'NOT seen'},"
               f" frozen {SLIDE:+d}); at f{b-1} ours - native {endd:+d} px (frozen {END:+d}); P2 HP at f{hf} native {n[hf]['hp']:#x}, ours {o[hf]['hp']:#x}")
        if len(nx) == 1 and held and slide == SLIDE and seq2 and endd == END:
            if not quiet: ok(msg)
        else: out.append(msg)
    return out
n, o = L["native"], L["ours"]
if MODE == "held": o = perturb(o, n, "x")
if MODE == "class-cleared": n = {f: dict(v, c54=0) for f, v in n.items()}
for m in judge(n, o): bad(m)
if not MODE:
    h = judge(L["native"], perturb(L["ours"], L["native"], "x"), True)
    if h: print(f"CONTROL FIRED: held — with ours' P2 x replaced by native's the gate fails ({len(h)} window(s)): {h[0]}")
    else: print("CONTROL DEAD: held — the gate passes with no slide on ours"); fail = 1
    c = judge({f: dict(v, c54=0) for f, v in L["native"].items()}, L["ours"], True)
    if c: print(f"CONTROL FIRED: class-cleared — with native's +0x54 zeroed the gate fails ({len(c)} window(s)): {c[0]}")
    else: print("CONTROL DEAD: class-cleared — the gate passes with no class on native"); fail = 1
sys.exit(fail)
PY
if [ -n "$MODE" ]; then
    [ "$fail" = 1 ] || vs_ctl_left_green "$MODE" "FAIL: audit_beam_slide (control mode)"
    echo "CONTROL FIRED: $MODE — the gate failed with the control applied"
    echo "FAIL: audit_beam_slide (control mode)"; exit 1
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_beam_slide"; else echo "FAIL: audit_beam_slide"; exit 1; fi
