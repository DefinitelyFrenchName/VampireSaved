#!/bin/sh
# audit_beam_slide.sh — #363, RE-FROZEN TO NATIVE'S FREEZE (14z-221c): PHOBOS'S ES PLASMA BEAM FREEZES THE VICTIM IN THE
# ICE BLOCK ON OURS AS ON NATIVE vs2 (frozen as the bug stood 14z-221b; the maintainer, 2026-11-05: "this finding is indeed
# mechanical NOT cosmetic, thus of greater severity", on the slide capture "vs2 always freezes (not paralyses: the whole
# ice block effect) Demitri on each hit, not just the finale", chose "Fix it too (Recommended)", and on the fixed
# build's capture "Demitri is frozen indeed").
#
# WHAT: the beam hits with reaction class 0x4F on both games. vs2's reaction table PRG:0x022388 sends row 0x4F to the
#   FREEZE (PRG:0x02296C: sub 08, +0x140 = 0x14, +0x11E = 0, the freeze timer +0x5C = 0x1F, the ice block). vsavj's table
#   PRG:0x02385C sends rows 0x4E and 0x4F to its default row PRG:0x0238FC (the pushback slide: before #363's fix Demitri
#   slid 81 px and ended 49 px further from Phobos). #363's fix (build/manifest/huitzil.toml freeze_reaction_row4f and
#   freeze_reaction_4f; STAGED for the next freeze as build/manifest/staged/357_363.patch, so this gate is RED against
#   the frozen merged build until that freeze) points row 0x4F at a jump on the dead span PRG:0x029CBA
#   (tests/test_dead_span.sh) to an authored copy of vs2's handler on vsavj's twins. Mechanism:
#   docs/game/engine_internals.md, "Rows 0x4E and 0x4F of vsavj's reaction table". Legacy reach: none — vanilla never
#   reads row 0x4F (tests/audit_effect_class_rows.sh section 1c) or executes the span (tests/audit_dead_span_exec.sh).
# HOW: step 0 reads the opcode images (tests/lib/decrypt_cache.sh for pristine vsavj and vsav2, BUILD's verify_op.bin):
#   the three tables' rows 0x00, 0x4E and 0x4F, and on ours the jump at PRG:0x029CBA and the body it names. Step 1 runs
#   MAME (non-debug, tests/lua/beam_slide_tap.lua, f2560-3080) on native vsav2 and on ours (BUILD) with the parity
#   gate's protocol (real cursor picks, speed level pinned 6 from f2000, RNG 0000 from f2363, the part's own X pins at
#   2560/2800/3040) on naming part huitzil_4 (P2 Demitri), Plasma Beam (ES) [PP] and [KK]. Each beam is judged in its
#   event window [2600, 2800) and [2840, 3040), cut before the next X pin.
# EXPECTS (frozen 14z-221c on the scratch build build/agent221c/m34x, build/agent221c/t363/fix2/): step 0 — vsavj rows
#   0x00/0x4E/0x4F -> 0x0238FC x3, vsav2 -> 0x022430/0x0226E0/0x02296C, ours -> 0x0238FC/0x0238FC/0x029CBA, ours'
#   PRG:0x029CBA a `jmp` to the authored body (its 0x26 bytes, the manifest's thunk_hex). Step 2 — both legs complete
#   (END); in each window the hits give +0x54 = 0x4F on both legs from the same frozen first frame (f2640, f2880);
#   EVERY traced field (P1 x, P2 x, y, seq, sub, +0x59, +0x164, HP, +0x54, +0x5C, +0x11E, +0x140, P1's +0x5C) equal on
#   both legs on every frame of the window before the rig's first HP pin inside it (the part pins P2's HP at 2950 on
#   both legs, so the KK window is compared up to f2949); native: P2 x constant while +0x54 is 0x4F, sub 08 seen, and
#   +0x5C = 0x1F on the frame after a 0x4F hit (the freeze timer).
#   Not covered: the other ported moves that may carry 0x4E or 0x4F (not measured); row 0x4E (vs2 PRG:0x0226E0, not
#   ported); Demitri as P1; a tenant victim (vsavj's ice-block spawn PRG:0x060ED8 tests 16 bits of the char-id mask
#   where vs2's PRG:0x06D31C tests 32); FBNeo and MiSTer.
# MUST-FIRE: perturbed-copy: slid — ours' P2 x given the slide back (+1 px a frame from the first 0x4F frame on) must fail the field comparison (in-gate; mode: the copy replaces ours and the gate FAILs)
# MUST-FIRE: perturbed-copy: timer-dropped — ours' +0x5C zeroed (vsavj's own row-0x14 freeze reused as is, without vs2's class-0x4F timer) must fail the field comparison (in-gate; mode: the copy replaces ours and the gate FAILs)
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
        "ours":  (sys.argv[3], 0x02385C, [0x0238FC, 0x0238FC, 0x029CBA])}
bad = 0
for g, (p, tab, w) in want.items():
    r = rows(p, tab)
    s = f"{g} table {tab:#08x}: row 0x00 -> {r[0]:#08x}, 0x4E -> {r[1]:#08x}, 0x4F -> {r[2]:#08x}"
    if r == w: print(f"  ok    {s}")
    else:
        bad = 1
        print(f"  FAIL  {s}; frozen " + ", ".join(f"{x:#08x}" for x in w)
              + (" — ours' row 0x4F is not #363's jump (a build without the fix?)" if g == "ours" else ""))
# ours' jump at PRG:0x029CBA and the body it names (the manifest's thunk_hex, build/manifest/huitzil.toml freeze_reaction_4f)
o = open(sys.argv[3], "rb").read()
BODY = bytes.fromhex("1d7c000800071d7c00140140422e011e1d7c001f005c103c001b4eb900027ec04ef900060ed8")
t = struct.unpack(">I", o[0x029CBC:0x029CC0])[0]
if o[0x029CBA:0x029CBC] == b"\x4e\xf9" and o[t:t + len(BODY)] == BODY:
    print(f"  ok    ours PRG:0x029CBA: jmp {t:#08x}, the authored freeze handler ({len(BODY):#x} bytes)")
else:
    bad = 1; print(f"  FAIL  ours PRG:0x029CBA is not a jmp to the authored freeze handler (bytes {o[0x029CBA:0x029CC0].hex()})")
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

prc=0; echo "== 2. the checks"
W="$W" MODE="$MODE" PK="$PK" python3 - <<'PY' || prc=$?
import os, sys
W, MODE = os.environ["W"], os.environ["MODE"]
# the rig's own P2 HP pins (the part's `ff8850` pokes, given to BOTH legs): an HP compare after one inside a window would
# be forced to agree (rule-checker run 2026-11-05-1647: the 2950 pin sits in the KK window), so HP is compared on the
# frame before the window's first pin
HPPIN = sorted(int(p.split(":")[0].split("-")[0]) for p in os.environ["PK"].split(";") if p and p.split(":")[1].lower() == "ff8850")
WIN = {"PP": (2600, 2800, 2640), "KK": (2840, 3040, 2880)}       # event window [a, b) and the frozen first 0x4F frame
FIELDS = ("p1x", "x", "y", "seq", "sub", "s59", "c164", "hp", "c54", "h5c", "f11e", "s140", "a5c")
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
    print(f"  FAIL  {', '.join(dead)}: the tap never reached its END line with every frame 2560-3040 — VOID"); sys.exit(4)   # a dead leg: nothing judged (the shell's vs_ctl_nj)
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
        cmp = range(a, hf + 1)
        bad_f = [(f, k) for f in cmp for k in FIELDS if n[f].get(k) != o[f].get(k)]
        nx = {n[f]["x"] for f in hn}; held = any(n[f]["sub"] == 0x08 for f in hn)
        timer = any(n[f]["c54"] == 0x4F and n[f]["sub"] == 0x08 and n[f]["h5c"] == 0x1F for f in hn)
        msg = (f"[{nm}] class 0x4F from f{h} on both; native P2 x {'constant ' + format(min(nx), '#x') if len(nx) == 1 else 'moves ' + str(sorted(nx))}"
               f" while 0x4F (sub 08 {'seen' if held else 'NOT seen'}, freeze timer 0x1F {'seen' if timer else 'NOT seen'});"
               f" every field equal f{a}-{hf} " + ("on both legs" if not bad_f else
               f"NO: {len(bad_f)} field-frames differ, first f{bad_f[0][0]} {bad_f[0][1]} native {n[bad_f[0][0]].get(bad_f[0][1])}, ours {o[bad_f[0][0]].get(bad_f[0][1])}")
               + f"; P2 HP at f{hf} native {n[hf]['hp']:#x}, ours {o[hf]['hp']:#x}")
        if len(nx) == 1 and held and timer and not bad_f:
            if not quiet: ok(msg)
        else: out.append(msg)
    return out
def slid(o):
    out, d = {}, 0
    for f in sorted(o):
        if f >= min(h for _, _, h in WIN.values()) and o[f]["c54"] == 0x4F: d += 1
        out[f] = dict(o[f], x=o[f]["x"] + d)
    return out
def timer_dropped(o): return {f: dict(v, h5c=0) for f, v in o.items()}
def class_cleared(n): return {f: dict(v, c54=0) for f, v in n.items()}
n, o = L["native"], L["ours"]
if MODE == "slid": o = slid(o)
if MODE == "timer-dropped": o = timer_dropped(o)
if MODE == "class-cleared": n = class_cleared(n)
for m in judge(n, o): bad(m)
if not MODE:
    for c, nn, oo in (("slid", L["native"], slid(L["ours"])), ("timer-dropped", L["native"], timer_dropped(L["ours"])),
                      ("class-cleared", class_cleared(L["native"]), L["ours"])):
        h = judge(nn, oo, True)
        if h: print(f"CONTROL FIRED: {c} — the gate fails on the perturbed copy ({len(h)} window(s)): {h[0]}")
        else: print(f"CONTROL DEAD: {c} — the gate passes on the perturbed copy"); fail = 1
sys.exit(fail)
PY
# a dead leg (exit 4) judged nothing: NOT JUDGED under a mode, never a fired control (14z-221c, rule-checker run 2026-11-05-1653)
if [ "${prc:-0}" = 4 ]; then
    vs_ctl_nj "the native or ours leg never reached its END line with every frame 2560-3040"
    echo "FAIL: audit_beam_slide (a dead leg: nothing judged)"; exit 1
fi
[ "${prc:-0}" = 0 ] || fail=1
if [ -n "$MODE" ]; then
    [ "$fail" = 1 ] || vs_ctl_left_green "$MODE" "FAIL: audit_beam_slide (control mode)"
    echo "CONTROL FIRED: $MODE — the gate failed with the control applied"
    echo "FAIL: audit_beam_slide (control mode)"; exit 1
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_beam_slide"; else echo "FAIL: audit_beam_slide"; exit 1; fi
