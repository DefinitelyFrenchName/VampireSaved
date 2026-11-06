#!/bin/sh
# audit_don_row0b.sh — DONOVAN'S PALETTE ROW 0x0B EQUALS NATIVE vs2 ON EVERY FRAME: #127's black foot and #162's orange
# flash, both fixed by (M) — vs2's mask bit 0x13 at PRG:0x02ADB4 (14z-216; the maintainer, 2026-11-01: "1. Yes, (M) at the
# next freeze, closing both (recommended) -> agreed", DECISIONS_HISTORY.md).
#
# WHAT: Donovan's palette reload (PRG:0x02ADAC) tests vsavj's per-character mask; without his bit it reloads his block
#   rows 1-3 into palette rows 0x0B-0x0D at every palette-state change, and block row 1 overwrites the effect palette
#   in row 0x0B (#127: the Press of Death deity's foot turns black when he is hit; #162: the deity flashes orange as
#   the Killshread column ends). With (M) the build reloads row 0x0A only, as vs2 does. This gate requires P1's palette
#   row 0x0B — all sixteen words — to equal native vs2's on every frame from 2500, on:
#     R1 #127's hit rig (tests/replays/don/127_pod_hit.rpl: Press of Death, P2 jabbing, Donovan hit at f2994);
#     R2 its NO-HIT control (tests/replays/don/127_pod_nohit.rpl);
#     R3 the 15-part census: every Donovan attacker naming part (tests/replays/naming/donovan_1..15, ours through the
#        merged wheel's real cursor path, as tests/audit_column_flash_cause.sh builds it);
#     R4 #162's part-4 compare: donovan_4's Killshread column, frames 2800-2870, reported on its own.
# HOW: three legs per rig on MAME under tests/lua/pal_rows_tap.lua (non-debug; P1's rows 0x0A-0x0D dumped every
#   frame): native vsav2, OURS (BUILD), and BAD — the same build with vsavj's mask word put back in the emulator's
#   decrypted-opcode share (OPATCH 02adb4:ef92, nothing built). A precondition reads BUILD's opcode image: the word at
#   PRG:0x02ADB4 must be vs2's (the build carries (M)).
# EXPECTS: every leg complete (END), P1 id 0x13 from 2500 on every leg, R1-R4 0 differing frames on ours. MEASURED,
#   not asserted: rows 0x0A and 0x0C native vs ours (their differences are #294's per-frame routine and Dark Force,
#   which (M) leaves alone; t127 census, 14z-216: 0x0A 1904 frames, 0x0C 2363) and row 0x0D. Not covered: Donovan as
#   P2 (rows 0x10-0x13); FBNeo and MiSTer; census parts donovan_8 and donovan_13, whose moves never show the
#   defect on row 0x0B (the BAD leg equals native there too, measured 14z-216), so their 0 is not evidence; how it LOOKS (the maintainer read the captures before the ruling:
#   build/agent216/t127/sheet_127_pod_hit.png, t162/sheets).
# MUST-FIRE: known-bad: mask-reverted — the BAD leg (vsavj's mask word in the opcode share) must differ from native on row 0x0B in R1, in R2, in R4's window and in every census part but the frozen blind two (donovan_8, donovan_13: their moves never show the defect), so no check can pass blind and the blind set cannot grow quietly (in-gate; mode: the BAD leg replaces ours and the gate FAILs)
# MUST-FIRE: known-bad: opatch-readback — the BAD leg's opcode-share write must read back as vsavj's word (223cef92) and ours' unpatched word as vs2's (223cef9a) read from the image; a write that did not land would make BAD equal ours (in-gate; mode: the BAD leg's readback is required to be vs2's word and the gate FAILs)
# FOLLOWS: build/manifest/ tools/name_moves.py emu/mame-patches/ tests/lua/pal_rows_tap.lua tests/lua/pokes_spec.lua tests/replays/don/127_pod_hit.rpl
#   tests/replays/don/127_pod_nohit.rpl tests/replays/naming/ tools/run_mame.sh tools/setup_mame.sh tests/lib/controls.sh
#
# SHEET: none — the maintainer read the captures before the ruling (sheet_127_pod_hit.png, sheet_127_pod_unhit_tail.png, the #162 sheets); this gate judges palette words only
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged34] [JOBS=6] tests/audit_don_row0b.sh
#   emulator tier, MAME; 51 runs (17 rigs x 3 legs), ~10 min on the MacBook at JOBS=6
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

echo "== 0. the build carries (M)"
WORD="$(python3 -c "import sys;b=open(sys.argv[1],'rb').read();print(b[0x02ADB2:0x02ADB6].hex())" "$BUILD/verify_op.bin")"
if [ "$WORD" = "223cef9a" ]; then ok "PRG:0x02ADB2 reads move.l #\$ef9a…: vs2's mask word (bit 0x13 set)"
else bad "PRG:0x02ADB2-0x02ADB5 reads $WORD, not vs2's mask word — this build does not carry (M)"; echo "FAIL: audit_don_row0b"; exit 1; fi

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
    leg "$W/$1/bad" vsavjw "$BUILD/rompath;$ROMDIR" "$3" "$4" "$5" "02adb4:ef92" &
    pool=$((pool + 3)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
}
echo "== 1. the legs: native vsav2 / ours $(basename "$BUILD") / bad (ours with vsavj's mask word, OPATCH 02adb4:ef92)"
PK127="1400:ff8782:13;1450:ff8782:13;1500:ff8782:13;1400:ff8b82:01;1450:ff8b82:01;1500:ff8b82:01;2800:ff8509:03;2900:ff8509:03;2000-3199:ff8116:06;2363-3199:ff80d4:0000"
three r1_hit "$REPO/tests/replays/don/127_pod_hit.rpl" "$REPO/tests/replays/don/127_pod_hit.rpl" "$PK127" 3200
three r2_nohit "$REPO/tests/replays/don/127_pod_nohit.rpl" "$REPO/tests/replays/don/127_pod_nohit.rpl" "$PK127" 3200
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

echo "== 2. the checks"
W="$W" MODE="$MODE" python3 - <<'PY' || fail=1
import os, sys
W, MODE = os.environ["W"], os.environ["MODE"]
def load(path):
    P, ids, end, rb = {}, {}, None, None
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
            kv = dict(x.split("=", 1) for x in t[2:] if "=" in x); ids[int(t[1])] = kv.get("id1")
        elif t[0] == "END":
            end = int(t[1])
        elif t[0] == "OPATCH":
            rb = t[-1]
    return P, ids, end, rb
fail = 0
def bad(m):
    global fail; fail = 1; print(f"  FAIL  {m}")
def ok(m): print(f"  ok    {m}")
rigs = ["r1_hit", "r2_nohit"] + [f"c{p}" for p in range(1, 16)]
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
cmp_leg = "bad" if MODE == "mask-reverted" else "ours"
want_rb = "223cef9a" if MODE == "opatch-readback" else "223cef92"
rbs = sorted({L[(r, "bad")][3] for r in rigs})
if MODE == "opatch-readback":
    if rbs != [want_rb]: bad(f"(mode) BAD legs read back {rbs}, not {want_rb}")
elif MODE:
    pass
elif rbs == [want_rb]: print(f"CONTROL FIRED: opatch-readback — every BAD leg's opcode-share write read back {want_rb} (vsavj's mask word); ours runs the image's 223cef9a")
else: print(f"CONTROL DEAD: opatch-readback — BAD legs read back {rbs}, not {want_rb}"); fail = 1
def diff(r, leg, row, lo=2500, hi=10**9):
    nP, oP = L[(r, "native")][0], L[(r, leg)][0]
    return [f for f in sorted(nP) if lo <= f <= hi and f in oP and nP[f][row] != oP[f][row]]
for r, tag in (("r1_hit", "R1 #127 hit rig"), ("r2_nohit", "R2 #127 no-hit control")):
    d = diff(r, cmp_leg, "0b")
    (ok if not d else bad)(f"[{tag}] row 0x0B, {cmp_leg} vs native from 2500: {len(d)} differing frames{(' (first ' + ','.join(map(str, d[:5])) + ')') if d else ''}")
tot = {"0a": 0, "0b": 0, "0c": 0, "0d": 0}; bad_tot = 0; parts = []
for p in range(1, 16):
    r = f"c{p}"; d = {row: len(diff(r, cmp_leg, row)) for row in tot}
    for row in tot: tot[row] += d[row]
    bad_tot += len(diff(r, "bad", "0b"))
    parts.append(f"donovan_{p} 0b={d['0b']} (0a={d['0a']} 0c={d['0c']} 0d={d['0d']})")
for s in parts: print(f"        {s}")
(ok if tot["0b"] == 0 else bad)(f"[R3 the 15-part census] row 0x0B, {cmp_leg} vs native from 2500: {tot['0b']} differing frames over 15 parts")
print(f"  MEASURE rows 0x0A {tot['0a']}, 0x0C {tot['0c']}, 0x0D {tot['0d']} differing frames ({cmp_leg} vs native; #294 / Dark Force, not (M)'s)")
d4 = diff("c4", cmp_leg, "0b", 2800, 2870)
(ok if not d4 else bad)(f"[R4 #162 part 4] donovan_4 row 0x0B over the Killshread column 2800-2870: {len(d4)} differing frames")
# THE KNOWN-BAD LEG FIRES ON EVERY CHECK (rule-checker run 2026-11-01-1537 Q4): R1, R2, R4's window and EVERY
# census part each need the BAD leg to differ from native on row 0x0B, so no check can pass blind
b1 = len(diff("r1_hit", "bad", "0b")); b2 = len(diff("r2_nohit", "bad", "0b"))
b4 = len(diff("c4", "bad", "0b", 2800, 2870))
bparts = {p: len(diff(f"c{p}", "bad", "0b")) for p in range(1, 16)}
# the census parts whose moves never show the defect on row 0x0B even with vsavj's mask word (measured 14z-216 on mb_m:
# donovan_8 and donovan_13 — their 0 on ours is not evidence of the fix, and the set is frozen so it cannot grow quietly)
BLIND = ["donovan_8", "donovan_13"]
blind = [f"donovan_{p}" for p, n in bparts.items() if n == 0]
print(f"        BAD leg row 0x0B differing frames: R1 {b1}, R2 {b2}, R4 {b4}, R3 per part " + " ".join(f"{p}:{n}" for p, n in bparts.items()))
if MODE:
    pass
elif b1 > 0 and b2 > 0 and b4 > 0 and blind == BLIND:
    print(f"CONTROL FIRED: mask-reverted — with vsavj's mask word the BAD leg differs from native on row 0x0B in R1 {b1}, R2 {b2} and R4 {b4} frames and in {15 - len(blind)} of 15 census parts (R3 {bad_tot} frames); the parts that cannot see the defect are exactly the frozen {BLIND}")
else:
    print(f"CONTROL DEAD: mask-reverted — R1 {b1}, R2 {b2}, R4 {b4}; census parts blind to the defect {blind}, frozen {BLIND}: a check the BAD leg cannot fail, or a moved blind set (re-measure)"); fail = 1
sys.exit(fail)
PY
if [ -n "$MODE" ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $MODE — the gate failed with the control applied"
    else echo "CONTROL DEAD: $MODE — every check passed with the control applied"; fi
    echo "FAIL: audit_don_row0b (control mode)"; exit 1
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_don_row0b"; else echo "FAIL: audit_don_row0b"; exit 1; fi
