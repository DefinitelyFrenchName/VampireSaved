#!/bin/sh
# audit_don_row0c.sh — DONOVAN'S WEAPON PALETTE ROW 0x0C EQUALS NATIVE vs2 ON EVERY FRAME: #294's red sword, fixed by
# porting vs2's per-frame palette routine ([perframe_hook]; the maintainer, 2026-11-01: "indeed if the 6 free bytes
# exist, given the cost this seems like the best solution", then "Yes" to the green light; DECISIONS_HISTORY.md).
#
# WHAT: vsavj's per-frame palette table (PRG:0x02ADEC) kept the default no-op at Donovan's row 0x13, so nothing
#   rewrote his weapon row (P1: palette row 0x0C) when his palette state changed — the sword stayed red where vs2
#   turns it yellow in Victor's electrocute and brown after it. With the port, row 0x13 jumps (through the dead span
#   PRG:0x024024) to vs2's routine. This gate requires P1's palette row 0x0C — all sixteen words — to equal native
#   vs2's on every frame from 2500 on:
#     R1 the electrocute rig (tests/replays/don/294_don_electrocuted.rpl: P2 Victor's held HP, Donovan shocked from f3412);
#     R3 the 15 Donovan naming parts (tests/replays/naming/donovan_1..15; Foot Stab (ES) among them), judged OUTSIDE
#        native's Dark Force frames (P1 +0x1C3, vs2's Dark Force POWER field, set). INSIDE them row 0x0C differs on about
#        378 frames per Dark Force part (14z-216 on mb_294: 1511 frames, donovan_3/4/6/7); the CAUSE IS OPEN — measured,
#        never asserted, never explained away. R5 MEASURES, every run, donovan_6 re-run with P1's +0x1C3 POKED to 1 over
#        native's window (14z-216: the difference unchanged, 378 frames); whether that poke reaches the routine's read
#        is NOT established (no positive control), so R5 rules nothing in or out.
# HOW: three legs per rig on MAME under tests/lua/pal_rows_tap.lua (non-debug; P1's rows 0x0A-0x0D dumped every
#   frame): native vsav2, OURS (BUILD), and BAD — the same build with the per-frame table's row 0x13 put back to
#   vsavj's default word in the emulator's decrypted-opcode share (OPATCH 02ae12:0040, nothing built: the table is read
#   PC-relatively, from the opcode view). A precondition reads BUILD's opcode image: row 0x13 must give the dead span.
# EXPECTS: every leg complete (END), P1 id 0x13 from 2500 on every leg, R1 and R3 0 differing frames on ours. MEASURED,
#   not asserted: rows 0x0A, 0x0B, 0x0D native vs ours. Not covered: Donovan as P2; FBNeo and MiSTer; how it LOOKS (a
#   capture sheet goes to the maintainer before the ticket is reported done).
# MUST-FIRE: known-bad: row-reverted — the BAD leg (row 0x13 back to vsavj's default in the opcode share) must differ from native on row 0x0C in R1 and, outside the Dark Force frames, in the census parts not frozen blind, so no check can pass blind (in-gate; mode: the BAD leg replaces ours and the gate FAILs)
# MUST-FIRE: known-bad: opatch-readback — the BAD leg's opcode-share write must read back as vsavj's word (ae120040 read at 0x02AE10..0x02AE13: the word before and the row) and ours runs the image's hooked word (in-gate; mode: the readback is required to be the hooked word and the gate FAILs)
# FOLLOWS: build/manifest/ tools/name_moves.py emu/mame-patches/ tools/gen_donovan_patch.py tests/lua/pal_rows_tap.lua tests/lua/pokes_spec.lua
#   tests/replays/don/294_don_electrocuted.rpl tests/replays/naming/ tools/run_mame.sh tools/setup_mame.sh tests/lib/controls.sh
#
# SHEET: none — the capture sheet for the maintainer is a separate step; this gate judges palette words only
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged34] [JOBS=6] tests/audit_don_row0c.sh
#   emulator tier, MAME; 48 runs (16 rigs x 3 legs)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged34}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] && [ -f "$BUILD/verify_op.bin" ] || { echo "SKIP: no WIDE build with verify_op.bin at $BUILD"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
echo "  host  $(uname -sm); MAME_BIN $MAME_BIN; build $(basename "$BUILD")"

echo "== 0. the build carries #294's port"
WORD="$(python3 -c "import sys;b=open(sys.argv[1],'rb').read();w=int.from_bytes(b[0x02AE12:0x02AE14],'big');print(hex((0x02ADEC+(w-0x10000 if w&0x8000 else w))&0xFFFFFF))" "$BUILD/verify_op.bin")"
if [ "$WORD" = "0x24024" ]; then ok "the per-frame table's row 0x13 gives PRG:0x024024, the dead span (the port's jump)"
else bad "the per-frame table's row 0x13 gives $WORD, not the dead span — this build does not carry #294's port"; echo "FAIL: audit_don_row0c"; exit 1; fi
HOOKED="$(python3 -c "import sys;b=open(sys.argv[1],'rb').read();print(b[0x02AE10:0x02AE14].hex())" "$BUILD/verify_op.bin")"

JOBS="${JOBS:-6}"; pool=0
leg() {  # leg <dir> <set> <rompath> <rpl> <pokes> <frames> <opatch>
    mkdir -p "$1"
    ( cd "$1" && MAME_SANDBOX="$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" MAX_FRAMES="$6" OPATCH="$7" OUT="$1/rig.log" \
        PALDUMP=0a,0b,0c,0d OBJROWS=0a,0b,0c,0d PALROW=0b \
        timeout 1200 "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/pal_rows_tap.lua" > "$1/mame.log" 2>&1
      rm -rf "$1/sb" ) </dev/null || true
}
three() {  # three <name> <native rpl> <ours rpl> <pokes> <frames>
    leg "$W/$1/native" vsav2 "$ROMDIR" "$2" "$4" "$5" "" &
    leg "$W/$1/ours" vsavjw "$BUILD/rompath;$ROMDIR" "$3" "$4" "$5" "" &
    leg "$W/$1/bad" vsavjw "$BUILD/rompath;$ROMDIR" "$3" "$4" "$5" "02ae12:0040" &
    pool=$((pool + 3)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
}
echo "== 1. the legs: native vsav2 / ours $(basename "$BUILD") / bad (ours with row 0x13 back to vsavj's default, OPATCH 02ae12:0040)"
R294="$REPO/tests/replays/don/294_don_electrocuted.rpl"; mkdir -p "$W/r1"
awk -v path="D D DR DR" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
    for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
    /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$R294" > "$W/r1/ours.rpl"
three r1_shock "$R294" "$W/r1/ours.rpl" "2000-3469:ff8116:06;2363-3469:ff80d4:0000" 3470
for p in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    J="$REPO/tests/replays/naming/donovan_$p.json"; R="$REPO/tests/replays/naming/donovan_$p.rpl"
    FR="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$J")"
    PK="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$J");2000-$((FR-1)):ff8116:06;2363-$((FR-1)):ff80d4:0000"
    mkdir -p "$W/c$p"
    awk -v path="D D DR DR" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
        for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$R" > "$W/c$p/ours.rpl"
    three "c$p" "$R" "$W/c$p/ours.rpl" "$PK" "$FR"
done
wait

# R5, MEASURED EVERY RUN (rule-checker run 2026-11-01-1543 Q1 asked for the premise behind an earlier attribution of the
# window to the routine's Dark Force branch, vs2 0x2A35C `tst.b $1c3(a6)`): donovan_6 re-run on ours and on BAD with P1's
# +0x1C3 POKED to 1 over NATIVE's own +0x1C3 frames. 14z-216: the difference unchanged (378 frames). The poke has no
# positive control (run 2026-11-01-1544 Q4: it may never reach the routine's read), so R5 rules nothing in or out: it
# prints, never asserts, and the window's cause is stated open.
DFW="$(awk '$1=="V" && $2 >= 2500 { for (i=3;i<=NF;i++) if ($i ~ /^f1c3=/) { v=substr($i,6); if (v!="00") { if (!lo) lo=$2; hi=$2 } } } END { if (lo) print lo "-" hi }' "$W/c6/native/rig.log")"
if [ -n "$DFW" ]; then
    J6="$REPO/tests/replays/naming/donovan_6.json"; FR6="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$J6")"
    PK6="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$J6");2000-$((FR6-1)):ff8116:06;2363-$((FR6-1)):ff80d4:0000;$DFW:ff85c3:01"
    leg "$W/c6p/ours" vsavjw "$BUILD/rompath;$ROMDIR" "$W/c6/ours.rpl" "$PK6" "$FR6" "" &
    leg "$W/c6p/bad" vsavjw "$BUILD/rompath;$ROMDIR" "$W/c6/ours.rpl" "$PK6" "$FR6" "02ae12:0040" &
    wait
fi
echo "  donovan_6: native's +0x1C3 window ${DFW:-NONE}; ours and BAD re-run with +0x1C3 poked to 1 over it"

echo "== 2. the checks"
W="$W" MODE="$MODE" HOOKED="$HOOKED" python3 - <<'PY' || fail=1
import os, sys
W, MODE, HOOKED = os.environ["W"], os.environ["MODE"], os.environ["HOOKED"]
def load(path):
    P, ids, end, rb, df = {}, {}, None, None, {}
    try:
        lines = open(path).read().splitlines()
    except OSError:
        return None
    for l in lines:
        t = l.split()
        if not t: continue
        if t[0] == "P":
            P[int(t[1])] = {x[:2]: x[3:] for x in t[2:]}
        elif t[0] == "V":
            kv = dict(x.split("=", 1) for x in t[2:] if "=" in x); ids[int(t[1])] = kv.get("id1"); df[int(t[1])] = kv.get("f1c3", "??")
        elif t[0] == "END":
            end = int(t[1])
        elif t[0] == "OPATCH":
            rb = t[-1]
    return P, ids, end, rb, df
fail = 0
def bad(m):
    global fail; fail = 1; print(f"  FAIL  {m}")
def ok(m): print(f"  ok    {m}")
rigs = ["r1_shock"] + [f"c{p}" for p in range(1, 16)]
L = {}
for r in rigs:
    for leg in ("native", "ours", "bad"):
        x = load(f"{W}/{r}/{leg}/rig.log")
        if not x or x[2] is None or not x[0]:
            bad(f"{r} {leg}: the tap never reached its END line or dumped no palette — VOID"); continue
        if any(v != "13" for f, v in x[1].items() if f >= 2500):
            bad(f"{r} {leg}: P1's id is not 0x13 on every frame from 2500 — the leg is not Donovan's")
        L[(r, leg)] = x
if fail:
    print("FAIL: legs incomplete"); sys.exit(1)
cmp_leg = "bad" if MODE == "row-reverted" else "ours"
want_rb = HOOKED if MODE == "opatch-readback" else HOOKED[:4] + "0040"
rbs = sorted({L[(r, "bad")][3] for r in rigs})
if MODE == "opatch-readback":
    if rbs != [want_rb]: bad(f"(mode) BAD legs read back {rbs}, not {want_rb}")
elif MODE:
    pass
elif rbs == [want_rb]: print(f"CONTROL FIRED: opatch-readback — every BAD leg's opcode-share write read back {want_rb} (row 0x13 = vsavj's 0x0040); ours runs the image's {HOOKED}")
else: print(f"CONTROL DEAD: opatch-readback — BAD legs read back {rbs}, not {want_rb}"); fail = 1
def diff(r, leg, row, lo=2500, hi=10**9):
    nP, oP = L[(r, "native")][0], L[(r, leg)][0]
    return [f for f in sorted(nP) if lo <= f <= hi and f in oP and nP[f][row] != oP[f][row]]
d = diff("r1_shock", cmp_leg, "0c")
(ok if not d else bad)(f"[R1 the electrocute rig] row 0x0C, {cmp_leg} vs native from 2500: {len(d)} differing frames{(' (first ' + ','.join(map(str, d[:5])) + ')') if d else ''}")
# THE DARK FORCE WINDOW (measured 14z-216): inside native's +0x1C3 frames row 0x0C differs with a cause NOT established.
# So R3 judges row 0x0C OUTSIDE native's +0x1C3 frames (must be 0) and MEASURES it inside; the window is stated open.
def in_df(r, f): return L[(r, "native")][4].get(f, "00") not in ("00", "??")
tot = {"0a": 0, "0b": 0, "0d": 0}; out_c = 0; in_c = 0; parts = []
for p in range(1, 16):
    r = f"c{p}"; dd = {row: len(diff(r, cmp_leg, row)) for row in tot}
    for row in tot: tot[row] += dd[row]
    dc = diff(r, cmp_leg, "0c"); o_ = [f for f in dc if not in_df(r, f)]; i_ = [f for f in dc if in_df(r, f)]
    out_c += len(o_); in_c += len(i_)
    dfw = sum(1 for f in L[(r, "native")][4] if f >= 2500 and in_df(r, f))
    parts.append(f"donovan_{p} 0c outside DF={len(o_)}{(' (first ' + ','.join(map(str, o_[:3])) + ')') if o_ else ''} inside DF={len(i_)} of native's {dfw} +0x1C3 frames (0a={dd['0a']} 0b={dd['0b']} 0d={dd['0d']})")
for s_ in parts: print(f"        {s_}")
(ok if out_c == 0 else bad)(f"[R3 the 15-part census] row 0x0C, {cmp_leg} vs native from 2500 outside native's +0x1C3 (Dark Force) frames: {out_c} differing frames over 15 parts")
print(f"  MEASURE row 0x0C inside native's +0x1C3 frames: {in_c} differing frames (cause NOT ESTABLISHED)")
print(f"  MEASURE rows 0x0A {tot['0a']}, 0x0B {tot['0b']}, 0x0D {tot['0d']} differing frames ({cmp_leg} vs native)")
# R5 the premise: with +0x1C3 poked over native's window, ours equals native inside it and BAD does not
def win(r):
    fr = [f for f in L[(r, "native")][4] if f >= 2500 and in_df(r, f)]
    return (min(fr), max(fr)) if fr else None
w6 = win("c6")
pp = {leg: load(f"{W}/c6p/{leg}/rig.log") for leg in ("ours", "bad")}
if not w6 or any(v is None or v[2] is None for v in pp.values()):
    bad(f"[R5 the Dark Force premise] donovan_6: no native +0x1C3 window ({w6}) or a poked leg did not complete — VOID")
else:
    nP = L[("c6", "native")][0]
    def dwin(P): return [f for f in sorted(nP) if w6[0] <= f <= w6[1] and f in P and nP[f]["0c"] != P[f]["0c"]]
    po, pb = dwin(pp["ours"][0]), dwin(pp["bad"][0])
    unpoked = len([f for f in diff("c6", "ours", "0c") if w6[0] <= f <= w6[1]])
    print(f"  MEASURE [R5] donovan_6 with P1 +0x1C3 poked to 1 over native's window {w6[0]}-{w6[1]}: ours {len(po)} differing frames on row 0x0C inside it (unpoked: {unpoked}), BAD {len(pb)} — whether the poke reaches the routine's read is not established (no positive control)")
b1 = len(diff("r1_shock", "bad", "0c"))
bparts = {p: len([f for f in diff(f"c{p}", "bad", "0c") if not in_df(f"c{p}", f)]) for p in range(1, 16)}
blind = [f"donovan_{p}" for p, n in bparts.items() if n == 0]
# the census parts whose moves never show the missing routine on row 0x0C outside Dark Force (BAD equals native there
# too): MEASURED 14z-216 on build/agent216/mb_294 and frozen, so the set cannot grow quietly
BLIND = ["donovan_1", "donovan_2", "donovan_6", "donovan_8", "donovan_9", "donovan_10", "donovan_11", "donovan_13",
         "donovan_14", "donovan_15"]
print(f"        BAD leg row 0x0C differing frames: R1 {b1}, R3 per part " + " ".join(f"{p}:{n}" for p, n in bparts.items()))
if MODE:
    pass
elif b1 > 0 and (BLIND is None or blind == BLIND):
    print(f"CONTROL FIRED: row-reverted — with row 0x13 back to vsavj's default the BAD leg differs from native on row 0x0C in R1 {b1} frames and in {15 - len(blind)} of 15 census parts; blind parts {blind}" + (" (BLIND NOT YET FROZEN)" if BLIND is None else ""))
    if BLIND is None: fail = 1
else:
    print(f"CONTROL DEAD: row-reverted — R1 {b1}; census parts blind {blind}, frozen {BLIND}"); fail = 1
sys.exit(fail)
PY
if [ -n "$MODE" ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $MODE — the gate failed with the control applied"
    else echo "CONTROL DEAD: $MODE — every check passed with the control applied"; fi
    echo "FAIL: audit_don_row0c (control mode)"; exit 1
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_don_row0c"; else echo "FAIL: audit_don_row0c"; exit 1; fi
