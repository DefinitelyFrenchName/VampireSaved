#!/bin/sh
# audit_shared_wall_push.sh — WHO KEEPS A SHARED CORNER: the two engines' push-apart differs when both fighters are clamped against the same wall edge in the same frame (14z-184, GitHub #179).
#
# WHAT: the push-apart routine is the same code in both games (vsavj 0x01926A, vs2 0x017C6C);
#   when BOTH fighters are walled (+0x116 set) and grounded it moves the fighter in its FIRST
#   register — P1, unless P1's +0x148 is set, which swaps the order. vs2's view clamp sets
#   +0x148 on the fighter it clamps (`st.b $148(a6)` at vs2 0x027444 / 0x02745E); vsavj's
#   clamp (0x0281E6-0x028200) is the same code without those two stores. So on a shared wall
#   vsavj pushes P1 out and vs2 pushes P2 out. The tenants run on vsavj's engine and follow
#   vsavj's rule: native Phobos keeps the corner at his Sitting Attack landing, ours is pushed
#   out — the #179 report, ruled the host engine's behaviour, documented, not ported.
# HOW: write taps (read_tap.lua) of both fighters' x, y, facing, +0x116, +0x148 and ids on
#   MAME, two parts: `legacy_lilith` — the maintainer's control design, the same characters,
#   positions and inputs on pristine vsavj and vs2: Lilith (P1) and Victor (P2) by REAL picks
#   (tools/select_paths.py on each game's decoded wheel), no position poke, Lilith walks Victor
#   into the right corner, throws him (f3000), pursuit U+P (8P) at +50..+110; `huitzil_3` —
#   the naming rig's event 8 (Sitting Attack [8P] off a throw) on native vs2 and on ours, the
#   parity gate's replays and pins. Level and RNG pinned as the parity gates do. A SECOND
#   INSTRUMENT, field_trace.lua (RAM sampled at frame_done, not write taps), runs every leg
#   again and must agree with the taps' end positions and the legacy first split.
# EXPECTS: the frozen rows (tests/expected/shared_wall_push.tsv): the legacy legs identical
#   until the landing (first split f3144), then vsavj's push PC 0x0193B2 moving P1 and vs2's
#   0x017DB4 moving P2; vs2's clamp the only non-zero +0x148 writer, vsavj and ours none; the
#   end positions (the pushed-out fighter at 960, the corner at 1000); the field trace
#   agreeing with the taps on every end row and the legacy split; all three controls fail.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/shared_wall_push.tsv
#   tests/lib/controls.sh tests/lib/decrypt_cache.sh tests/lua/field_trace.lua
#   tests/lua/read_tap.lua tests/replays/naming/ tools/name_moves.py tools/run_mame.sh
#   tools/select_paths.py tools/select_wheel.py tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: flag-planted — a copy of the pristine vsavj leg's tap with ONE non-zero store to P1's +0x148 planted at a game PC before the landing must add a writer to the vsavj flag row and FAIL the frozen compare, so "vsavj never sets +0x148" is something the reducer can refuse (in-gate: the planted copy is reduced and must differ; mode: the real vsavj and ours taps are planted and the gate FAILs)
# MUST-FIRE: perturbed-copy: early-split — a copy of the vs2 legacy tap with ONE x write planted at the end of f3100, forty frames before the landing, must move the first-split row and FAIL, so "identical until the landing" is something the split reader can refuse (in-gate: the planted copy's split row must differ from the frozen one; mode: the real vs2 tap is planted, and the split row and the field-trace agreement both FAIL)
# MUST-FIRE: perturbed-copy: legs-swapped — the two legs' taps of each part reduced under each other's labels must FAIL the frozen compare, so the frozen split is one the rows can tell apart by leg (in-gate: the swapped reduction is diffed against the frozen rows and must differ; mode: every part's legs are swapped and the gate FAILs)
#
# THE LEGACY CONTROL — the maintainer, 2026-09-27, in their own words: "You not only need
# the move but the same setup of character and positions ... As for the move what you need
# is a pursuit move and for all characters in VS and VS2 the command is 8P/K", "pursuit
# moves (8+P/K) are performed OTG, so the opponent needs to have been knocked down first";
# and on the Lilith capture: "from what I see it seems indeed to be an engine-wide property.
# If so, the vanilla engine works BUT we aboslutely must document this difference in the two
# games". Lilith is the ONE clean legacy control of the 14z-184 sweep (every other character's
# two games differ from the throw onward, or never share x): docs/game/engine_internals.md
# "THE PUSH-APART AT A SHARED WALL".
#
# NOT COVERED (named, not tested): the attacker as P2 (the static reading predicts the split
# reversed: vsavj pushes the victim-as-P1 out, vs2 the attacker-as-P2); the LEFT wall (vs2's
# clamp flags +0x148 there too, 0x027444, so the reading predicts the same split; every rig
# here is at the right corner); the resolver's airborne and +0x115 branches; Sitting Attack
# event 9. read_tap.lua and field_trace.lua share MAME, the rig and the pokes.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged30] [PARTS="legacy_lilith huitzil_3"] [FREEZE=1] tests/audit_shared_wall_push.sh
#   emulator tier, MAME; ~20 s (4 tap runs and 4 field traces, in parallel)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged30}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/shared_wall_push.tsv"
PARTS="${PARTS:-legacy_lilith huitzil_3}"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FLOOR=2300
RT="ff8410,2;ff8810,2;ff8414,2;ff8814,2;ff840a,2;ff880a,2;ff8516,2;ff8916,2;ff8548,2;ff8948,2;ff8782,2;ff8b82,2"
# per part: <frames> <push window lo> <hi> <end frame>
GEOM_legacy_lilith="3160 3140 3150 3150"
GEOM_huitzil_3="6160 6146 6156 6156"
pins() {  # pins <frames> — the parity gates' level and RNG pins
    python3 -c "print(f'{2000}-{($1)-1}:ff8116:06' + ';' + f'{2363}-{($1)-1}:ff80d4:0000')"
}
tap() {  # tap <name> <set> <rompath> <rpl> <pokes> <frames>   (background)
    mkdir -p "$W/$1"
    ( cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$6" \
        RTAP="$RT" WINDOW="0,0" TRACE_OUT="$W/$1.txt" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/$1/mame.log" 2>&1
      rm -rf "$W/$1/sb" ) </dev/null &
}
FT="ff8410:w:p1x,ff8810:w:p2x,ff8414:w:p1y,ff8814:w:p2y,ff840a:w:p1f,ff880a:w:p2f"
trace() {  # trace <name> <set> <rompath> <rpl> <pokes> <frames>   (background) — the second instrument
    mkdir -p "$W/$1.ft"
    ( cd "$W/$1.ft" && MAME_SANDBOX="$W/$1.ft/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$6" \
        FIELDS="$FT" FIELD_OUT="$W/$1.ft.txt" FIELD_FROM="$FLOOR" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$1.ft/mame.log" 2>&1
      rm -rf "$W/$1.ft/sb" ) </dev/null &
}
# the field trace's rows, IN THE TAPS' FRAME NUMBERS: read_tap labels a write with the frame counter BEFORE that
# frame's frame_done, field_trace samples AFTER incrementing it, so a write labelled W N is field_trace's F N+1
# (measured 14z-184: the taps' end-of-frame x/y/facing at N equal the trace's at N+1 on 999/999 frames, both legacy
# legs; docs/platform/gotchas.md). Both x at <end> are read from F <end>+1; a first split at F k is reported as k-1.
field_rows() {  # field_rows <part> <leg> <ft.txt> <end>  |  field_rows <part> - <ftA> <ftB>
    python3 - "$@" "$FLOOR" <<'PY'
import sys
part, leg, a, b, floor = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5])
def load(p):
    d, done = {}, False
    for l in open(p):
        t = l.split()
        if t and t[0].startswith("FIELDSUMMARY"): done = True
        if t and t[0] == "F": d[int(t[1])] = dict(kv.split("=") for kv in t[2:])
    if not done or not d: sys.exit(f"VOID: {p} has no FIELDSUMMARY line or no frames (a dead trace is not evidence)")
    return d
if leg != "-":
    d = load(a); f = d[int(b) + 1]
    print(f"{part}\t{leg}\tfield-end\t{b}\tP1 x={f['p1x']} P2 x={f['p2x']}")
else:
    A, B = load(a), load(b)
    first = next((str(f - 1) for f in sorted(set(A) & set(B)) if f - 1 >= floor and A[f] != B[f]), "-")
    print(f"{part}\t-\tfield-first-split\t{floor}-\t{first}")
PY
}
# the whole-run agreement of the two instruments on one leg: the taps' end-of-frame x/y/facing at every frame N
# (writes merged by their mask — a byte store's data word carries the other byte unspecified) against the trace's
# F N+1; every sampled frame must agree, except a frame whose F N+1 the RIG POKED at a compared address — a Lua
# poke is sampled by the trace and never logged by the write tap (measured 14z-184: huitzil_3's nine in-window
# position pins, 2565..5765, are exactly the nine disagreeing frames on both legs; the count excluded is printed)
agree() {  # agree <tap.txt> <ft.txt> <pokes file> -> "<agreeing> <compared> <disagreeing frames> <excluded>"
    python3 - "$1" "$2" "$FLOOR" "$3" <<'PY'
import sys
K = {0xff8410: "p1x", 0xff8810: "p2x", 0xff8414: "p1y", 0xff8814: "p2y", 0xff840a: "p1f", 0xff880a: "p2f"}
def s16(v): return v - 0x10000 if v & 0x8000 else v
tap, raw, cur = {}, {}, None
for l in open(sys.argv[1]):
    t = l.split()
    if not t or t[0] != "W": continue
    f = int(t[1])
    if cur is not None and f != cur:
        for g in range(cur, f): tap[g] = {K[a]: s16(v) for a, v in raw.items()}
    cur = f; a = int(t[5], 16)
    if a in K:
        d, m = int(t[7], 16) & 0xffff, int(t[9], 16) & 0xffff
        raw[a] = (raw.get(a, 0) & ~m | d & m) & 0xffff
ft = {}
for l in open(sys.argv[2]):
    t = l.split()
    if t and t[0] == "F": ft[int(t[1])] = {k: int(v) for k, v in (kv.split("=") for kv in t[2:])}
poked = {int(x.split(":")[0]) for x in open(sys.argv[4]).read().strip().split(";") if x and int(x.split(":")[1], 16) in K}
allf = [n for n in sorted(tap) if n >= int(sys.argv[3]) and n + 1 in ft]
fr = [n for n in allf if n + 1 not in poked]
bad = [n for n in fr if any(tap[n].get(k) != v for k, v in ft[n + 1].items())]
print(len(fr) - len(bad), len(fr), ",".join(map(str, bad[:12])) or "-", len(allf) - len(fr))
PY
}
# ONE reducer, shared by the gate and every control mode ([VSP-181]): one leg's tap -> rows
reduce() {  # reduce <part> <leg label> <tap.txt> <push lo> <push hi> <end frame>
    python3 - "$@" "$FLOOR" <<'PY'
import sys
part, leg, path, lo, hi, end, floor = sys.argv[1], sys.argv[2], sys.argv[3], *map(int, sys.argv[4:8])
W = []
ended = False
for l in open(path):
    t = l.split()
    if not t: continue
    if t[0] == "END": ended = True
    if t[0] == "W": W.append((int(t[1]), t[3], int(t[5], 16), int(t[7], 16), int(t[9], 16)))
if not ended: sys.exit(f"VOID: {path} has no END line (a dead tap is not evidence)")
# the push-apart routine's own range, per engine (vsavj 0x01926A-0x0193B8; vs2 0x017C6C-0x017DBA)
def in_push(pc):
    v = int(pc, 16); return 0x1926A <= v < 0x193B8 or 0x17C6C <= v < 0x17DBA
WHO = {0xff8410: "P1", 0xff8810: "P2"}
push = [f"{f}:{pc}:{WHO[a]}:{d & 0xffff:04x}" for f, pc, a, d, m in W if lo <= f <= hi and a in WHO and in_push(pc)]
print(f"{part}\t{leg}\tpush\t{lo}-{hi}\t{','.join(push) or '-'}")
# every PC that stores a NON-ZERO byte to either fighter's +0x148 (an even address: the byte is the word's high half)
setters = sorted({pc for f, pc, a, d, m in W if f >= floor and a in (0xff8548, 0xff8948) and m & 0xff00 and (d >> 8) & 0xff})
print(f"{part}\t{leg}\tflag148-set\t{floor}-\t{','.join(setters) or '-'}")
# end-of-frame state at <end>: the last write of each word at or before it
st = {}
for f, pc, a, d, m in W:
    if f > end: break
    st[a] = d & 0xffff
print(f"{part}\t{leg}\tend\t{end}\tP1 x={st.get(0xff8410, 0)} P2 x={st.get(0xff8810, 0)}")
ids = {a: (d >> 8) & 0xff for f, pc, a, d, m in W if f < floor and a in (0xff8782, 0xff8b82) and m & 0xff00}
print(f"{part}\t{leg}\tids\t-\tp1={ids.get(0xff8782, 0):02x} p2={ids.get(0xff8b82, 0):02x}")
PY
}
split() {  # split <part> <tapA> <tapB> — the first frame >= FLOOR whose end-of-frame x/y/facing differ
    python3 - "$1" "$2" "$3" "$FLOOR" <<'PY'
import sys
part, a, b, floor = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
KEYS = (0xff8410, 0xff8810, 0xff8414, 0xff8814, 0xff840a, 0xff880a)
def frames(p):
    st, out, cur = {}, {}, None
    for l in open(p):
        t = l.split()
        if not t or t[0] != "W": continue
        f = int(t[1])
        if cur is not None and f != cur: out[cur] = tuple(st.get(k) for k in KEYS)
        cur = f; a_ = int(t[5], 16)
        if a_ in KEYS: st[a_] = int(t[7], 16) & 0xffff
    if cur is not None: out[cur] = tuple(st.get(k) for k in KEYS)
    return out
A, B = frames(a), frames(b)
last_a = last_b = None
first = "-"
for f in range(floor, max(max(A), max(B)) + 1):
    last_a = A.get(f, last_a); last_b = B.get(f, last_b)
    if last_a != last_b: first = str(f); break
print(f"{part}\t-\tfirst-split\t{floor}-\t{first}")
PY
}
plant_split() {  # plant_split <tap> <frame> — ONE x write to P1 (x 0x03E7) after that frame's last write
    awk -v f="$2" '!done && $1 == "W" && $2 > f { print "W " f " PC 0273ee off ff8410 data 000003e7 mask 0000ffff"; done = 1 } { print }' "$1"
}
plant() {  # plant <tap> <frame> — ONE non-zero store to P1's +0x148 by a game PC, before that frame's first write
    awk -v f="$2" '!done && $1 == "W" && $2 == f { print "W " f " PC 0281f0 off ff8548 data 0000ffff mask 0000ff00"; done = 1 } { print }' "$1"
}

echo "== 1. rigs and taps"
. "$REPO/tests/lib/decrypt_cache.sh"
for p in $PARTS; do
    eval "_g=\$GEOM_$p"; set -- $_g; fr=$1
    case "$p" in
    legacy_lilith)
        decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_da.bin" || { bad "vsav2 views not delivered"; continue; }
        decrypt_view vsavj "$W/vj_op.bin" "$W/vj_da.bin" || { bad "vsavj views not delivered"; continue; }
        for s in vsavj vsav2; do
            case "$s" in vsavj) da="$W/vj_da.bin" ;; *) da="$W/v2_da.bin" ;; esac
            python3 "$REPO/tools/select_wheel.py" "$da" --set "$s" --json "$W/wheel_$s.json" > "$W/wheel_$s.log" 2>&1 \
                || { bad "$s wheel: $(tail -1 "$W/wheel_$s.log")"; continue; }
            # the rig: REAL picks (Lilith 0x0E for P1, Victor 0x03 for P2), walk Victor into the right corner,
            # a toward-MP throw up close, then U+P at the naming recipe's offsets +50..+110
            { printf '300-305 sys=C1\n420-425 sys=C2\n800-803 sys=S1\n940-943 sys=S2\n'
              python3 "$REPO/tools/select_paths.py" "$W/wheel_$s.json" --rpl-prologue 0x0e 0x03
              printf '2600-2995 p1=R\n3000-3003 p1=R2\n'
              for t in 3050 3065 3080 3095 3110; do printf '%d-%d p1=U1\n' "$t" "$((t + 2))"; done
              printf '3400 wait\n'; } > "$W/$p.$s.rpl"
            pins "$fr" > "$W/$p.pokes"
            tap "$p.$s" "$s" "$ROMDIR" "$W/$p.$s.rpl" "$(pins "$fr")" "$fr"
            trace "$p.$s" "$s" "$ROMDIR" "$W/$p.$s.rpl" "$(pins "$fr")" "$fr"
        done ;;
    huitzil_3)
        R="$REPO/tests/replays/naming"
        base="$(python3 -c "import json;print(';'.join(json.load(open('$R/huitzil_3.json'))['pokes']))")"
        cp "$R/huitzil_3.rpl" "$W/$p.vsav2.rpl"
        # ours: the parity gate's cursor path to our Phobos cell (tests/audit_move_parity.sh OURS_PATH_huitzil, copied)
        awk -v path="D D D" '
            /^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
                for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
            /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
            { print }' "$R/huitzil_3.rpl" > "$W/$p.ours.rpl"
        printf '%s;%s\n' "$base" "$(pins "$fr")" > "$W/$p.pokes"
        tap "$p.vsav2" vsav2 "$ROMDIR" "$W/$p.vsav2.rpl" "$base;$(pins "$fr")" "$fr"
        trace "$p.vsav2" vsav2 "$ROMDIR" "$W/$p.vsav2.rpl" "$base;$(pins "$fr")" "$fr"
        tap "$p.ours" vsavjw "$BUILD/rompath;$ROMDIR" "$W/$p.ours.rpl" "$base;$(pins "$fr")" "$fr"
        trace "$p.ours" vsavjw "$BUILD/rompath;$ROMDIR" "$W/$p.ours.rpl" "$base;$(pins "$fr")" "$fr" ;;
    *) bad "unknown part $p" ;;
    esac
done
wait
[ "$fail" = 0 ] || { echo "FAIL: audit_shared_wall_push"; exit 1; }

echo "== 2. rows vs tests/expected/shared_wall_push.tsv"
: > "$W/got.tsv"; : > "$W/swapped.tsv"; : > "$W/field.tsv"
for p in $PARTS; do
    eval "_g=\$GEOM_$p"; set -- $_g; lo=$2; hi=$3; en=$4
    case "$p" in legacy_lilith) a=vsavj; b=vsav2 ;; *) a=ours; b=vsav2 ;; esac
    for leg in $a $b; do
        [ -s "$W/$p.$leg.txt" ] || { bad "$p $leg: no tap"; continue; }
        if vs_ctl_is flag-planted && [ "$leg" != vsav2 ]; then
            plant "$W/$p.$leg.txt" "$lo" > "$W/$p.$leg.pl" && mv "$W/$p.$leg.pl" "$W/$p.$leg.txt"
        fi
        if vs_ctl_is early-split && [ "$p" = legacy_lilith ] && [ "$leg" = vsav2 ]; then
            plant_split "$W/$p.$leg.txt" 3100 > "$W/$p.$leg.pl" && mv "$W/$p.$leg.pl" "$W/$p.$leg.txt"
        fi
        [ -s "$W/$p.$leg.ft.txt" ] || { bad "$p $leg: no field trace"; continue; }
    done
    [ "$fail" = 0 ] || break
    if vs_ctl_is legs-swapped; then la=$b; lb=$a; else la=$a; lb=$b; fi
    reduce "$p" "$la" "$W/$p.$a.txt" "$lo" "$hi" "$en" >> "$W/got.tsv" || { bad "$p $a: reduce"; continue; }
    reduce "$p" "$lb" "$W/$p.$b.txt" "$lo" "$hi" "$en" >> "$W/got.tsv" || { bad "$p $b: reduce"; continue; }
    [ "$p" = legacy_lilith ] && split "$p" "$W/$p.$a.txt" "$W/$p.$b.txt" >> "$W/got.tsv"
    # the second instrument: its rows go to their own file, then must AGREE with the taps' (section 2b)
    field_rows "$p" "$a" "$W/$p.$a.ft.txt" "$en" >> "$W/field.tsv" || bad "$p $a: field trace"
    field_rows "$p" "$b" "$W/$p.$b.ft.txt" "$en" >> "$W/field.tsv" || bad "$p $b: field trace"
    [ "$p" = legacy_lilith ] && { field_rows "$p" - "$W/$p.$a.ft.txt" "$W/$p.$b.ft.txt" >> "$W/field.tsv" || bad "$p: field split"; }
    # the in-gate legs-swapped copy (always built; compared in section 3)
    reduce "$p" "$b" "$W/$p.$a.txt" "$lo" "$hi" "$en" >> "$W/swapped.tsv"
    reduce "$p" "$a" "$W/$p.$b.txt" "$lo" "$hi" "$en" >> "$W/swapped.tsv"
    [ "$p" = legacy_lilith ] && split "$p" "$W/$p.$a.txt" "$W/$p.$b.txt" >> "$W/swapped.tsv"
done
cat "$W/got.tsv" "$W/field.tsv" | sed 's/^/  | /'
if [ "${FREEZE:-0}" = 1 ]; then
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED: FREEZE=1 in control mode"; exit 3; }
    { sed -n '/^#/p' "$EXPECT" 2>/dev/null; cat "$W/got.tsv"; } > "$W/new.tsv"
    grep -q '^#' "$W/new.tsv" || { echo "REFUSED: $EXPECT has no header to keep"; exit 3; }
    mv "$W/new.tsv" "$EXPECT"; echo "FROZEN: $EXPECT ($(grep -vc '^#' "$EXPECT") rows)"; exit 0
fi
grep -v '^#' "$EXPECT" > "$W/want.tsv"
for p in $PARTS; do
    grep "^$p	" "$W/want.tsv" > "$W/want.$p" || true
    grep "^$p	" "$W/got.tsv" > "$W/got.$p" || true
    [ -s "$W/want.$p" ] || { bad "$p: no frozen rows"; continue; }
    if diff "$W/want.$p" "$W/got.$p" > "$W/diff.$p"; then ok "$p: $(wc -l < "$W/got.$p" | tr -d ' ') rows as frozen"
    else bad "$p: rows differ from the frozen expectation"; sed 's/^/        /' "$W/diff.$p"; fi
done

echo "== 2b. the second instrument agrees with the taps"
# the taps' end and split rows, re-labelled, must equal the field trace's (the same rig, a different reader)
sed -e 's/	end	/	field-end	/' -e 's/	first-split	/	field-first-split	/' "$W/got.tsv" | grep -E '	field-(end|first-split)	' | sort > "$W/tap_view.tsv"
sort "$W/field.tsv" > "$W/field_view.tsv"
if [ -s "$W/field_view.tsv" ] && diff "$W/tap_view.tsv" "$W/field_view.tsv" > "$W/agree.diff"; then ok "field_trace agrees with the taps on $(wc -l < "$W/field_view.tsv" | tr -d ' ') rows"
else bad "field_trace and the taps disagree"; sed 's/^/        /' "$W/agree.diff"; fi
for p in $PARTS; do
    case "$p" in legacy_lilith) legs="vsavj vsav2" ;; *) legs="ours vsav2" ;; esac
    for leg in $legs; do
        set -- $(agree "$W/$p.$leg.txt" "$W/$p.$leg.ft.txt" "$W/$p.pokes")
        if [ "${2:-0}" -gt 0 ] && [ "$1" = "$2" ]; then ok "$p $leg: every frame agrees, taps at N = field_trace at N+1 ($1/$2; $4 poked frames excluded)"
        else bad "$p $leg: the instruments agree on ${1:-?}/${2:-?} frames (disagreeing: ${3:-?})"; fi
    done
done

echo "== 3. must-fire controls"
if vs_ctl_is flag-planted || vs_ctl_is legs-swapped || vs_ctl_is early-split; then
    if [ "$fail" = 1 ]; then vs_ctl_fired "$VS_CTL" "the perturbed real input loses the frozen rows"; echo "FAIL: audit_shared_wall_push (control mode)"; exit 1
    else vs_ctl_dead "$VS_CTL" "the perturbed real input still matched" || true; echo "FAIL: audit_shared_wall_push"; exit 1; fi
fi
first="$(echo $PARTS | cut -d' ' -f1)"
eval "_g=\$GEOM_$first"; set -- $_g
case "$first" in legacy_lilith) a=vsavj ;; *) a=ours ;; esac
plant "$W/$first.$a.txt" "$2" > "$W/ctl.tap"
reduce "$first" "$a" "$W/ctl.tap" "$2" "$3" "$4" | grep '	flag148-set	' > "$W/ctl.row"
if grep -q "^$first	$a	flag148-set	" "$W/want.tsv" && ! grep -qxF -f "$W/ctl.row" "$W/want.tsv"; then
    vs_ctl_fired flag-planted "one planted +0x148 store on $first $a adds $(cut -f5 "$W/ctl.row") to the flag row"
else vs_ctl_dead flag-planted "the planted store did not change the $first $a flag row" || fail=1; fi
if echo " $PARTS " | grep -q " legacy_lilith "; then
    plant_split "$W/legacy_lilith.vsav2.txt" 3100 > "$W/ctl_split.tap"
    split legacy_lilith "$W/legacy_lilith.vsavj.txt" "$W/ctl_split.tap" > "$W/ctl_split.row"
    if grep -q '	first-split	' "$W/want.tsv" && ! grep -qxF -f "$W/ctl_split.row" "$W/want.tsv"; then
        vs_ctl_fired early-split "one x write planted at the end of f3100 moves the first split to $(cut -f5 "$W/ctl_split.row")"
    else vs_ctl_dead early-split "the planted early write did not move the first-split row" || fail=1; fi
fi
if diff -q "$W/want.tsv" "$W/swapped.tsv" > /dev/null; then vs_ctl_dead legs-swapped "the legs reduced under each other's labels still match" || fail=1
else vs_ctl_fired legs-swapped "the legs reduced under each other's labels differ from the frozen rows"; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_shared_wall_push — on a shared wall vsavj pushes P1 out and vs2 pushes P2 out, as frozen"
else echo "FAIL: audit_shared_wall_push"; exit 1; fi
