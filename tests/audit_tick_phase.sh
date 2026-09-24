#!/bin/sh
# audit_tick_phase.sh — THE ENGINE'S DOUBLE-PASS CADENCE IS PERIODIC IN FRAMES,
# AND ITS PERIOD IS WHAT tools/name_moves.py QUANTISES ITS SCHEDULE SHIFT TO
# (14z-172, GitHub #168).
#
# WHAT: the engine's double-pass cadence is periodic in FRAMES — one residue class mod 3 at
#   speed level 8, three classes mod 13 at level 6 — and tools/name_moves.py's TICK_QUANTUM
#   (39, their lcm) and ROUND_START (2545, the same with and without the level pin) are what
#   this gate is the provenance of.
# HOW: one naming-rig leg on native vsav2 on MAME at each level, the pass counter's double
#   steps classed by frame index; the generator's constants read from its source; a second
#   leg without the level pin for the round start; controls flatten the pass counter and
#   perturb TICK_QUANTUM.
# EXPECTS: the residue classes exact, the constants equal to the measured periods and round
#   start; the flat trace and the wrong quantum fail. WHY a shift must be a multiple of 39
#   rather than 3 is recorded as its own ticket, not explained here.
#
# MUST-FIRE: perturbed-copy: flat-pass — a copy of the level-8 trace with the pass counter made to step by exactly 1 every frame (no second pass anywhere) must FAIL the period assertion, so a dead tap or a frozen counter cannot read as a clean cadence (in-gate: the flattened copy must lose its double-pass frames; mode: the flattened trace replaces the real one and section 1 FAILs)
# MUST-FIRE: perturbed-copy: quantum-off — a copy of tools/name_moves.py whose TICK_QUANTUM is not the lcm of the two measured periods must FAIL section 2, so the constant cannot drift from what this gate measures (in-gate: the perturbed value must be rejected; mode: the gate reads the perturbed copy and section 2 FAILs)
#
# WHY. tools/name_moves.py shifts seven naming parts' schedules so their first
# position pin lands after the round start (#168). WHICH shift is not free: the
# engine runs a SECOND logic pass on a periodic set of frames, so an input
# scheduled DF frames later meets a different pass phase unless DF is a multiple
# of the period, and the corpus's input-window-edge recipes ("late button",
# "pair AFTER the motion") then fire a different move. Measured both ways
# (build/rig172, 14z-172): shifts of 190, 194, 200 and 208 each moved the
# huitzil_7 Circuit Scrapper family, and 195 and 234 — the multiples of 39 —
# moved nothing but the two corrections the fix exists to make.
#
# So the generator carries TWO constants this gate is the provenance of:
#   ROUND_START  = 2545   the frame $FF812D first reads 1 (section 3)
#   TICK_QUANTUM = 39     lcm(3, 13), the two periods (sections 1 and 2)
# A frozen constant whose provenance cannot be named is a claim ([VSP-165]).
#
# WHAT IT ASSERTS
#   1. on ONE naming-rig leg, the double-pass frames (the pass counter $FF8081
#      stepping by 2, atlas/ram.md) are exactly one residue class mod 3 at speed
#      level 8 — vsav2's default TURBO, which tests/test_move_naming.sh runs
#      unpinned — and exactly three residue classes mod 13 at level 6, the pin
#      tests/audit_move_parity.sh puts on both its legs;
#   2. tools/name_moves.py's TICK_QUANTUM equals the lcm of those two periods;
#   3. the round start is the SAME frame with the rig's own speed-level pin and
#      WITHOUT it, and equals the generator's ROUND_START. WHAT THAT SEPARATES,
#      EXACTLY: the round start does not move with the SPEED-LEVEL PIN, so 2545
#      is not that pin's number (14z-171, promoted here 14z-172 from
#      build/rig171/roundstart.sh and rs_unpinned.sh). WHAT IT DOES NOT
#      SEPARATE: both legs run the SAME replay and the SAME base poke list, so a
#      defect in the rig's input path would move the round start on both and this
#      section would not see it (rule-checker run 2026-09-20-87 Q3). The claim
#      that 2545 belongs to the round INTRO rather than to the rig rests on the
#      other measurement 14z-171 made — the same 2545 on both legs of five
#      differently-scheduled parts across all three tenants — not on this gate.
#
# WHAT IT DOES NOT CLAIM. Only levels 6 and 8 are measured, on one part; the
# cadence at any other level is not asserted, and neither is WHY a shift
# divisible by 39 is needed rather than by 3 alone — two shifts that are
# multiples of 3 but not of 13 (192, 273) each moved pyron_3's marginal air-throw
# rows, which is recorded as its own ticket, not explained here.
#
# Usage: ROMDIR=... [MAME_BIN=~/.cache/vampire-saved/mame/cps2] [PART=huitzil_7] tests/audit_tick_phase.sh
#   emulator tier, MAME; the two legs run in parallel, native vsav2 — measured 14z-172 on this MacBook, solo: ~60 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
PART="${PART:-huitzil_7}"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
case "$CONTROL" in ""|flat-pass|quantum-off) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
TENANT="$(echo "$PART" | sed 's/_.*//')"; PARTNO="$(echo "$PART" | sed 's/.*_//')"
FROM=2560; TO=6000                       # the event window, clear of the round intro
NM="$REPO/tools/name_moves.py"
python3 "$NM" gen "$TENANT" "$PARTNO" "$W/r.rpl" "$W/r.json" > /dev/null
BASE="$(python3 -c "import json;print(';'.join(json.load(open('$W/r.json'))['pokes']))")"
FR="$(python3 -c "import json;print(json.load(open('$W/r.json'))['frames'])")"

leg() {  # leg <name> <extra pokes>   (background)
    mkdir -p "$W/$1"
    # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log
    # (docs/platform/gotchas.md): `set +e` keeps the status write alive.
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" REPLAY="$W/r.rpl" POKES="$BASE$2" FRAMES="$FR" \
        FIELDS="ff8081:b:pass,ff8080:b:frm,ff8116:b:lvl,ff812d:b:rnd,ff8782:b:id" \
        FIELD_OUT="$W/$1.tr" FIELD_FROM=2300 FIELD_TO="$FR" \
        "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$1/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$W/$1.tr" 2>/dev/null && _st=0; echo $_st > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
LVL6=";$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$FR)))")"
echo "== 1. the double-pass cadence on $PART, frames $FROM-$TO"
leg lvl8 ""
leg lvl6 "$LVL6"
wait
for l in lvl8 lvl6; do
    _rc="$(cat "$W/$l/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$l: the emulator exited $_rc"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_tick_phase (a leg did not run)"; exit 1; }
if [ "$CONTROL" = flat-pass ]; then
    # the perturbation: a pass counter that steps by exactly 1 every frame — a dead
    # tap, a frozen counter, or a leg that never entered the match all look like this
    python3 - "$W/lvl8.tr" > "$W/flat.tr" <<'PY'
import re, sys
n = 0
for line in open(sys.argv[1]):
    m = re.match(r"(F )(\d+)( .*)", line.rstrip("\n"))
    if not m: print(line.rstrip("\n")); continue
    n += 1
    print(m.group(1) + m.group(2) + re.sub(r"pass=\d+", f"pass={n % 256}", m.group(3)))
PY
    mv "$W/flat.tr" "$W/lvl8.tr"
    echo "  control flat-pass: the level-8 trace's pass counter flattened to +1 a frame"
fi
period() {  # period <trace> <expected period> <expected residues> <label>
    python3 - "$1" "$2" "$3" "$4" <<'PY'
import re, sys
from collections import Counter
path, want, want_res, label = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
lo, hi = 2560, 6000
rows = {}
for line in open(path):
    m = re.match(r"F (\d+) (.*)", line.strip())
    if m: rows[int(m.group(1))] = dict(kv.split("=", 1) for kv in m.group(2).split())
fr = sorted(f for f in rows if lo <= f <= hi)
if len(fr) < 1000: sys.exit(f"VOID: {label} has only {len(fr)} samples in {lo}..{hi}")
lv = set(rows[f].get("lvl") for f in fr)
d = {b: (int(rows[b]["pass"]) - int(rows[a]["pass"])) % 256 for a, b in zip(fr, fr[1:]) if b == a + 1}
dbl = [f for f, v in d.items() if v >= 2]
gaps = Counter(b - a for a, b in zip(sorted(dbl), sorted(dbl)[1:]))
res = sorted(set(f % want for f in dbl))
sing = set(f % want for f, v in d.items() if v < 2)
clean = bool(dbl) and not (set(res) & sing)
# the BYTE frame counter $FF8080 wraps at 256 and 256 % 3 == 1, % 13 == 9, so a
# modulus of the byte rotates at every wrap and cannot separate the classes
# (14z-156 searched the byte and concluded there was no modulus; 14z-172)
byte_res = sorted(set(int(rows[f]["frm"]) % want for f in dbl))
byte_sing = set(int(rows[f]["frm"]) % want for f, v in d.items() if v < 2)
print(f"LEVELS {','.join(sorted(x or '?' for x in lv))}")
print(f"N {len(d)} DOUBLES {len(dbl)} CLASSES {len(res)} WANT {want_res} CLEAN {int(clean)} RES {','.join(str(x) for x in res) or 'none'}")
print(f"GAPS {','.join(str(k) for k in sorted(gaps)) or 'none'} COUNTS {' '.join(f'{k}x{v}' for k, v in sorted(gaps.items()))}")
print(f"BYTE {'DISJOINT' if not (set(byte_res) & byte_sing) else 'OVERLAPS'} {len(byte_res)}")
PY
}
# <leg> <period> <how many residue classes> <the gap set> <speed level>
for spec in "lvl8 3 1 3 8" "lvl6 13 3 4,5 6"; do
    set -- $spec
    _l="$1"; _p="$2"; _nc="$3"; _gs="$4"; _lv="$5"
    period "$W/$_l.tr" "$_p" "$_nc" "$_l" > "$W/$_l.per" 2>&1 || { bad "$_l: $(cat "$W/$_l.per")"; continue; }
    _lvls="$(awk '$1=="LEVELS"{print $2}' "$W/$_l.per")"
    _n="$(awk '$1=="N"{print $2}' "$W/$_l.per")"; _d="$(awk '$1=="N"{print $4}' "$W/$_l.per")"
    _got="$(awk '$1=="N"{print $6}' "$W/$_l.per")"; _cl="$(awk '$1=="N"{print $10}' "$W/$_l.per")"
    _res="$(awk '$1=="N"{print $12}' "$W/$_l.per")"
    _gaps="$(awk '$1=="GAPS"{print $2}' "$W/$_l.per")"
    _gapc="$(sed -n 's/^GAPS [^ ]* COUNTS //p' "$W/$_l.per")"
    _byte="$(awk '$1=="BYTE"{print $2}' "$W/$_l.per")"
    [ "$_lvls" = "$_lv" ] || bad "$_l: the leg ran at speed level(s) $_lvls, not $_lv — the cadence measured is not the one claimed"
    # THE ASSERTION IS THE PERIOD, NOT THE PHASE: how many residue classes the
    # doubles occupy and that no single-pass frame shares one. The residue VALUES
    # depend on where frame numbering starts and are printed, never frozen.
    if [ "$_cl" = 1 ] && [ "$_got" = "$_nc" ] && [ "$_gaps" = "$_gs" ]; then
        ok "$_l (level $_lv): $_d double-pass frames of $_n in exactly $_got residue class(es) mod $_p {$_res}, disjoint from the single ones; gaps {$_gaps} ($_gapc)"
    else
        bad "$_l (level $_lv): $_got residue class(es) mod $_p {$_res} (want $_nc, disjoint=$_cl), gaps {$_gaps} want {$_gs} — the cadence is not the frozen period, so the generator's TICK_QUANTUM no longer follows it"
    fi
    # the negative that explains why 14z-156's search found none: the BYTE counter wraps
    [ "$_byte" = OVERLAPS ] && ok "$_l: the same set indexed by the BYTE counter \$FF8080 OVERLAPS the single-pass residues — a byte wrapping at 256 rotates every modulus that does not divide 256, which is why a search over it finds none (14z-156)" || bad "$_l: the byte counter \$FF8080 separates the classes too — the wrap explanation for 14z-156's negative does not hold here"
done

echo "== 2. the generator's TICK_QUANTUM is the lcm of the two measured periods"
if [ "$CONTROL" = quantum-off ]; then
    sed 's/^TICK_QUANTUM = 39/TICK_QUANTUM = 13/' "$NM" > "$W/nm_ctl.py"; NM="$W/nm_ctl.py"
    echo "  control quantum-off: reading a copy whose TICK_QUANTUM is 13, not lcm(3, 13)"
fi
Q="$(python3 -c "
import re, sys
s = open(sys.argv[1]).read()
m = re.search(r'^TICK_QUANTUM = (\d+)', s, re.M)
print(m.group(1) if m else '')" "$NM")"
WANT_Q="$(python3 -c "import math;print(math.lcm(3, 13))")"
if [ "$Q" = "$WANT_Q" ]; then ok "2 TICK_QUANTUM = $Q = lcm(3, 13), the two periods section 1 measured"
else bad "2 TICK_QUANTUM = ${Q:-<absent>} but the measured periods give lcm(3, 13) = $WANT_Q — a shift that is not a multiple of both re-rolls the corpus's input-window-edge events (#168)"; fi

echo "== 3. the round start, and the separating control that makes it the intro's"
rs() { python3 -c "
import re, sys
for line in open(sys.argv[1]):
    m = re.match(r'F (\d+) (.*)', line.strip())
    if not m: continue
    kv = dict(x.split('=', 1) for x in m.group(2).split())
    if kv.get('rnd') == '1': print(m.group(1)); break
else: print('')" "$1"; }
RS8="$(rs "$W/lvl8.tr")"; RS6="$(rs "$W/lvl6.tr")"
RS_GEN="$(python3 -c "
import re, sys
print(re.search(r'^ROUND_START = (\d+)', open(sys.argv[1]).read(), re.M).group(1))" "$REPO/tools/name_moves.py")"
if [ -n "$RS8" ] && [ "$RS8" = "$RS6" ]; then
    ok "3.1 the round start is frame $RS8 WITH the rig's speed-level pin (level 6) and WITHOUT it (level 8) — so 2545 is not the speed pin's number; both legs share the replay and base pokes, so this does not separate the rig itself (header, Q3)"
else bad "3.1 the round start moves with the speed-level pin (pinned $RS6, unpinned $RS8) — 2545 would then be the speed pin's number, and the generator's ROUND_START would be a rig artifact"; fi
if [ "$RS8" = "$RS_GEN" ]; then ok "3.2 tools/name_moves.py's ROUND_START = $RS_GEN, the measured frame"
else bad "3.2 tools/name_moves.py's ROUND_START = $RS_GEN but the measured round start is $RS8 — the pin floor no longer follows the game"; fi

echo "== 4. must-fire controls"
if [ -n "$CONTROL" ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $CONTROL — the perturbed input reached the gate's own FAIL"; echo "FAIL: audit_tick_phase (control mode)"; exit 1
    else echo "CONTROL DEAD: $CONTROL — the perturbation left every assertion green"; echo "FAIL: audit_tick_phase"; exit 1; fi
fi
python3 - "$W/lvl8.tr" > "$W/flat.tr" <<'PY'
import re, sys
n = 0
for line in open(sys.argv[1]):
    m = re.match(r"(F )(\d+)( .*)", line.rstrip("\n"))
    if not m: print(line.rstrip("\n")); continue
    n += 1
    print(m.group(1) + m.group(2) + re.sub(r"pass=\d+", f"pass={n % 256}", m.group(3)))
PY
period "$W/flat.tr" 3 1 flat > "$W/flat.per" 2>&1 || true
_fd="$(awk '$1=="N"{print $4}' "$W/flat.per")"
if [ "${_fd:-0}" = 0 ]; then echo "CONTROL FIRED: flat-pass — a pass counter stepping +1 a frame leaves 0 double-pass frames of $(awk '$1=="N"{print $2}' "$W/flat.per"), which section 1 refuses"
else echo "CONTROL DEAD: flat-pass — the flattened trace still shows $_fd double-pass frames"; fail=1; fi
sed 's/^TICK_QUANTUM = 39/TICK_QUANTUM = 13/' "$REPO/tools/name_moves.py" > "$W/nm_ctl.py"
_cq="$(python3 -c "
import re, sys
m = re.search(r'^TICK_QUANTUM = (\d+)', open(sys.argv[1]).read(), re.M); print(m.group(1) if m else '')" "$W/nm_ctl.py")"
if [ "$_cq" != "$WANT_Q" ]; then echo "CONTROL FIRED: quantum-off — a copy carrying TICK_QUANTUM = $_cq is not lcm(3, 13) = $WANT_Q and section 2 refuses it"
else echo "CONTROL DEAD: quantum-off — the perturbed copy still reads $WANT_Q"; fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_tick_phase"; else echo "FAIL: audit_tick_phase"; exit 1; fi
