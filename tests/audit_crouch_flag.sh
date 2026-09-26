#!/bin/sh
# audit_crouch_flag.sh — THE FIGHTER'S +0x121 IS THE CROUCH FLAG, measured against a scripted Down on native vsav2 and on our merged build (14z-169): the guard decision (vsavj PRG:0x0182E8-0x0183E4, vs2 0x016BA4-) branches on the VICTIM's +0x121 before comparing the record's class, so this names which of its two class lists applies to a standing victim (0x02 0x03 0x38 0x39) and which to a crouching one (0x2C 0x37 0x42 0x48 0x4A 0x4D) — read as lows and overheads, no hit against a guard run.
#
# WHAT: the fighter's +0x121 is the CROUCH flag: it rises with a scripted Down and falls
#   with its release, identically on native vs2 and on our merged build — the fact that
#   names which of the guard decision's two class lists applies to a standing and to a
#   crouching victim.
# HOW: the naming part donovan_1 (Down held 2840-2870) on both games on MAME, P1's (+0x121,
#   seq, sub) at every change over 2830-2880 and P2's flag frozen per leg; the control
#   deletes the Down from the replay and the flag must then never rise.
# EXPECTS: the frozen transitions on both legs, P2's flag held 0, the stripped run flat. NOT
#   covered: +0x121 in the air, while blocking, or on P2.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/crouch_flag.tsv
#   tests/lua/field_trace.lua tests/replays/ tools/name_moves.py tools/run_mame.sh
#   tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: down-removed — the same rig with P1's Down (2840-2870) deleted from the replay must never raise +0x121, so the transition rows are proven to follow the input and not a timer (in-gate: the stripped run's +0x121 must stay 0 over the window; mode: every leg runs stripped and the frozen compare FAILs)
#
# WHY. docs/game/engine_internals.md ("The licence covers the class") states that a record
# class 0x38 is sent to the hit path by a STANDING victim's guard decision where 0x06 is not
# (worded as a reading since rule-checker run 2026-09-18-51 Q2): tools/audit_reaction_classes.py shows the
# guard chain comparing the record's class in two lists on the two branches of `tst.b $121(a1)`
# (tests/expected/reaction_classes.tsv, the rec17-cmp rows), and which branch is standing
# rested on what +0x121 IS — undocumented until this gate (docs/game/atlas/ram.md now carries it).
# Rig: tests/replays/naming/donovan_1 (P1 Donovan, Down held 2840-2870 by the schedule's
# "Crouch" event), native as committed, ours on the merged wheel's path (the parity gate's).
# NOT COVERED: +0x121 in the air, while blocking, or on P2 (P2 never crouches here); what the
# two lists do beyond selecting the hit path (the block path is 0x0183EE).
#
# FROZEN: tests/expected/crouch_flag.tsv — per leg, P1's (+0x121, seq, sub) at every frame it
# changes over 2830-2880, plus P2's +0x121 held 0.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged28] [FREEZE=1] tests/audit_crouch_flag.sh
#   emulator tier, MAME; 4 field-trace runs — measured 14z-169 on this MacBook: ~15 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged28}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/crouch_flag.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|down-removed) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
J="$REPO/tests/replays/naming/donovan_1.json"; R="${J%.json}.rpl"
PK="$(python3 -c "import json;print(';'.join(json.load(open('$J'))['pokes']))")"
grep -q '^2840-2870 p1=D$' "$R" || { echo "FAIL: the rig no longer holds Down at 2840-2870 — re-read the schedule"; exit 1; }
# ONE perturbation, shared by the in-gate control and the mode: the Down line removed
strip_down() { grep -v '^2840-2870 p1=D$' "$1" > "$2"; }
awk -v path="D D DR DR" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
    for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
    /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$R" > "$W/ours.rpl"
cp "$R" "$W/native.rpl"
for leg in native ours; do strip_down "$W/$leg.rpl" "$W/$leg.nodown.rpl"; done
if [ "$CONTROL" = down-removed ]; then for leg in native ours; do cp "$W/$leg.nodown.rpl" "$W/$leg.rpl"; done; fi
FIELDS="ff8521:b:f121,ff8406:b:seq,ff8407:b:sub,ff8921:b:p2f121,ff8782:b:id"
run() {  # run <name> <set> <rompath> <rpl>
    mkdir -p "$W/$1"
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$PK" FIELDS="$FIELDS" \
        FIELD_OUT="$W/$1.ft" FIELD_FROM=1400 FIELD_TO=2880 FRAMES=2885 \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$1/mame.log" 2>&1
      echo $? > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
echo "== 1. the runs"
run native vsav2 "$ROMDIR" "$W/native.rpl"; run ours vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl"
[ -n "$CONTROL" ] || { run native.ctl vsav2 "$ROMDIR" "$W/native.nodown.rpl"; run ours.ctl vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.nodown.rpl"; }
wait
reduce() {  # reduce <leg> <ft>: the transitions of (f121, seq, sub) over 2830-2880 and P2's +0x121
    python3 - "$1" "$2" <<'PY'
import sys
leg, ft = sys.argv[1], sys.argv[2]
d = {}
for l in open(ft):
    t = l.split()
    if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
if 1400 not in d or 2880 not in d: sys.exit(f"VOID: {leg} trace incomplete (a run that did not finish is not evidence)")
if d[1400]["id"] != 0x13: sys.exit(f"VOID: {leg} P1 is {d[1400]['id']:#04x}, not Donovan 0x13 — the pick did not land")
prev = None
for f in range(2830, 2881):
    k = (d[f]["f121"], d[f]["seq"], d[f]["sub"])
    if k != prev: print(f"{leg}\tp1\t{f}\tf121={k[0]}\tseq={k[1]:02x}\tsub={k[2]:02x}")
    prev = k
print(f"{leg}\tp2\tf121-max={max(d[f]['p2f121'] for f in range(2830, 2881))}")
PY
}
: > "$W/got.tsv"
for leg in native ours; do
    [ -f "$W/$leg.ft" ] || { bad "$leg: no trace (exit $(cat "$W/$leg/rc" 2>/dev/null || echo none))"; continue; }
    reduce "$leg" "$W/$leg.ft" >> "$W/got.tsv" 2> "$W/$leg.err" || bad "$(cat "$W/$leg.err")"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_crouch_flag"; exit 1; }
sed 's/^/  /' "$W/got.tsv"
# the property itself: +0x121 is 1 on the frames Down is held and 0 just before and after, on both legs
for leg in native ours; do
    python3 - "$W/$leg.ft" "$leg" "$CONTROL" <<'PY' || fail=1
import sys
d = {}
for l in open(sys.argv[1]):
    t = l.split()
    if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
on = [f for f in range(2830, 2881) if d[f]["f121"]]
if sys.argv[3] == "down-removed":
    print(f"  {'FAIL' if not on else 'ok  '}  {sys.argv[2]}: (control mode) +0x121 raised on {len(on)} frames without the Down")
    sys.exit(1 if not on else 0)
if on == list(range(2840, 2871)): print(f"  ok    {sys.argv[2]}: +0x121 = 1 exactly while Down is held (2840-2870)"); sys.exit(0)
print(f"  FAIL  {sys.argv[2]}: +0x121 is 1 on {on[:3]}..{on[-3:] if on else ''} ({len(on)} frames), not 2840-2870"); sys.exit(1)
PY
done
if [ -z "$CONTROL" ]; then
    _c=0
    for leg in native ours; do
        if [ -f "$W/$leg.ctl.ft" ] && awk '$1=="F" && $2>=2830 && $2<=2880' "$W/$leg.ctl.ft" | grep -q . \
           && ! awk '$1=="F" && $2>=2830 && $2<=2880 && $3!="f121=0"' "$W/$leg.ctl.ft" | grep -q .; then _c=$((_c + 1)); fi
    done
    if [ "$_c" = 2 ]; then echo "CONTROL FIRED: down-removed — without the Down, +0x121 stays 0 over 2830-2880 on both legs"
    else echo "CONTROL DEAD: down-removed — a stripped run raised +0x121 or produced no samples"; fail=1; fi
fi
echo "== 2. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] && [ -z "$CONTROL" ] || { echo "FAIL: audit_crouch_flag (not frozen: fix the red first, no control)"; exit 1; }
    { echo "# tests/expected/crouch_flag.tsv — P1's +0x121 against the scripted Down of tests/replays/naming/donovan_1 (2840-2870), native vsav2"
      echo "# and $(basename "$BUILD") (tests/audit_crouch_flag.sh; field_trace). Evidence class: in-emulator. Frozen 14z-169 with FREEZE=1."
      echo "#--"; cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi
if [ "$CONTROL" = down-removed ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: down-removed — the stripped rig fails the property and the frozen compare"; echo "FAIL: audit_crouch_flag (control mode)"; exit 1
    else echo "CONTROL DEAD: down-removed — the stripped rig passed"; echo "FAIL: audit_crouch_flag"; exit 1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_crouch_flag"; else echo "FAIL: audit_crouch_flag"; exit 1; fi
