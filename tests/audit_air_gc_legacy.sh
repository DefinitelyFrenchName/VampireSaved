#!/bin/sh
# audit_air_gc_legacy.sh — THE LEGACY CONTROL FOR #182: no original character's AIR block opens the guard window or commits a guard cancel, on pristine vsavj, native vs2 or ours (14z-185, GitHub #182).
#
# WHAT: the evidence that the air guard cancel is PHOBOS'S ALONE in both games, so #182 (it never
#   fires on ours) is a port gap and no host-engine rule is overridden by fixing it; and the
#   legacy guard any #182 fix must keep green. Both engines' block entry (vsavj 0x02393A, vs2
#   0x022480) open the guard window +0x158 := 0x0E on a GROUNDED block only; vs2 alone also opens
#   it in the air, for fighter id 0x10 (docs/game/engine_internals.md "THE GUARD WINDOW ON AN AIR
#   BLOCK"). The maintainer, 2026-09-27 (14z-185), from Mizuumi: Phobos's Reflect Wall is "(Air
#   OK)" and he is unique in that; Lei-Lei is not listed as Air OK; Zabel's guard cancel is
#   623+K and he has no air one. A guard cancel is COMMITTED by one routine in both games (vsavj
#   0x029C6E, vs2 0x028FA0: +0x3B5 := 6, the window cleared — the GUARD CANCEL banner), which is
#   what this gate reads as "a guard cancel happened". Zabel's check (vsavj 0x036A6E) and Phobos's
#   (vs2 0x055470) require the window with no fall-through; Lei-Lei's (vsavj 0x04B3FA) falls through
#   to her plain 623+P, which comes out of an air block with no commit and no banner.
# HOW: the 14z-184 rig (build/agent184/t174/legacy/run.sh, promoted; Zabel's motion corrected to
#   623+K at 14z-185): P1 = Lei-Lei (0x0d, 623+LP) or Zabel (0x04, 623+LK), P2 = Demitri (0x01),
#   by REAL picks (tools/select_paths.py on the decoded wheel; vsavj's wheel drives ours, whose
#   original cells are vsavj's, and every leg's picked ids are asserted); level 6 and the RNG
#   pinned as the parity gates do; three events, each after a far position pin at t-230 and P1
#   walking in (t-190..t-40): E0 the guard-cancel motion from a GROUND block (P2 5HP at 2800, P1
#   holds back, the motion from +12), E1/E2 the same motion from an AIR block at Phobos's two
#   timings (P2 jumps in, j.HP at +10 / +14; P1 jumps straight up at +2 / +6 and holds back; the
#   motion from +22 / +26). THE POSITIVE LEG: Phobos (0x10, 623+LP) on native vs2 on the same rig
#   and timings, the one character that has an air guard cancel — it must open the window and
#   commit one in E1 and E2, so the legacy characters' zero is a zero at a timing that CAN produce
#   an air guard cancel. Non-debug write taps (read_tap.lua) on P1's +0x140 (block kind),
#   +0x158 (guard window), +0x3B5 (the guard-cancel commit), +0x147, +0x38 (airborne), +0x106
#   (command) and +0x06 (sequence), each one byte of its tapped word; seven MAME legs in parallel
#   (two characters x pristine vsavj, native vs2, ours — the WIDE build, its fingerprint printed
#   and its MAME log required to name the vsavjw set — plus Phobos on native vs2).
# EXPECTS: per character and leg, the picked ids and every event's byte writes (frame:value) equal
#   tests/expected/air_gc_legacy.tsv; the three legs' rows identical once the leg label is
#   dropped; every E0 opens the window AND commits a guard cancel, the commit mark written by the commit
#   routine's first instruction (vsavj/ours 0x029C6E, vs2 0x028FA0) (the instrument sees both); no
#   E1/E2 writes a non-zero +0x158 or commits a guard cancel on any legacy leg; native Phobos opens
#   the window and commits in E1 and in E2; all five controls fail.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/air_gc_legacy.tsv
#   tests/lib/controls.sh tests/lib/decrypt_cache.sh tests/lua/read_tap.lua tools/build_fingerprint.py
#   tools/run_mame.sh tools/select_paths.py tools/select_wheel.py tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: air-window-planted — a copy of the pristine vsavj tap with ONE non-zero +0x158 store planted in E1 must FAIL the no-air-window check, so "no window in the air" is something the reader can refuse (in-gate: the first character's planted copy must count a non-zero air window write; mode: every vsavj leg's tap is planted and the gate FAILs)
# MUST-FIRE: perturbed-copy: ground-window-removed — a copy of a tap with every +0x158 write removed from E0 must FAIL the ground check, so the air zero is read by an instrument proven to see the window (in-gate: the stripped copy's ground count must be zero; mode: every leg's taps are stripped and the gate FAILs)
# MUST-FIRE: perturbed-copy: air-commit-planted — a copy of the native vs2 tap with ONE +0x3B5 := 6 store planted in E1 must FAIL the no-air-commit check and the three-leg equality, so "no guard cancel from an air block" is something the reader can refuse (in-gate: the first character's planted copy must count an air commit; mode: every vs2 leg's tap is planted and the gate FAILs)
# MUST-FIRE: perturbed-copy: positive-stripped — a copy of native Phobos's tap with every +0x158 and +0x3B5 write removed from E1/E2 must FAIL the positive check, so "this rig's air timing can produce an air guard cancel" is something the gate can refuse (in-gate: the stripped copy's E1 window and commit counts must both be zero; mode: Phobos's tap is stripped and the gate FAILs)
# MUST-FIRE: perturbed-copy: ground-commit-removed — a copy of a tap with every +0x3B5 write removed from E0 must FAIL the ground-commit check, so the air zero is read by an instrument proven to see a committed guard cancel (in-gate: the stripped copy's ground commit count must be zero; mode: every leg's taps are stripped and the gate FAILs)
#
# NOT COVERED (named, not tested): the other original characters (their air block is the same
#   block-entry code with no id test, read statically in both games, not rigged); P2 as the
#   character; the left side; any event timing other than the three; FBNeo; Phobos himself (his
#   native vs ours air guard cancel is tests/audit_chains174.sh). Lei-Lei's 623+P from an air
#   block DOES come out (sequence 0x0E) through her command check's no-window branch, with no
#   commit and no banner, identically on every leg — recorded in the rows, captured and shown to
#   the maintainer (14z-185), and not a guard cancel.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged29] [CHARS="leilei zabel phobos"] [FREEZE=1] [KEEP=<dir>] tests/audit_air_gc_legacy.sh
#   emulator tier, MAME; ~7 s (7 legs in parallel)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged29}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/air_gc_legacy.tsv"
CHARS="${CHARS:-leilei zabel phobos}"
legs_of() {  # the legs each character runs: the two legacy characters on all three; Phobos, the POSITIVE leg, on native vs2
    case "$1" in phobos) echo vsav2 ;; *) echo "vsavj vsav2 ours" ;; esac
}
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FR=4200
EVENTS="E0:2800 E1:3220 E2:3640"
RT="ff8558,2;ff8506,2;ff8406,2;ff8540,2;ff87b4,2;ff8546,2;ff8438,2;ff8782,2;ff8b82,2"
# per character: its id and the guard-cancel motion's three steps (P1 on the left, facing right)
CHAR_leilei="0d R D DR1"      # 623+LP
CHAR_zabel="04 R D DR4"       # 623+LK (the maintainer, 14z-185; the 14z-184 rig's 421+K was wrong)
CHAR_phobos="10 R D DR1"      # 623+LP, Reflect Wall — the one character with an air guard cancel (native vs2 only)
rig() {  # rig <char> <wheel.json> — the 14z-184 rig, byte for byte but for Zabel's motion
    eval "_c=\$CHAR_$1"; set -- $_c "$2"; id=$1; M1=$2; M2=$3; M3=$4; wheel=$5
    printf '300-305 sys=C1\n420-425 sys=C2\n800-803 sys=S1\n940-943 sys=S2\n'
    python3 "$REPO/tools/select_paths.py" "$wheel" --rpl-prologue "0x$id" 0x01
    t=2800; printf '%d-%d p1=R\n' $((t-190)) $((t-40))
    printf '%d-%d p2=3\n%d-%d p1=L\n%d-%d p1=%s\n%d-%d p1=%s\n%d-%d p1=%s\n' $t $((t+3)) $((t-4)) $((t+11)) $((t+12)) $((t+13)) "$M1" $((t+14)) $((t+15)) "$M2" $((t+16)) $((t+19)) "$M3"
    for spec in "3220 2 10 22" "3640 6 14 26"; do
        set -- $spec; t=$1; a=$2; h=$3; g=$4
        printf '%d-%d p1=R\n' $((t-190)) $((t-40))
        printf '%d-%d p2=UL\n%d-%d p2=3\n%d-%d p1=U\n%d-%d p1=L\n%d-%d p1=%s\n%d-%d p1=%s\n%d-%d p1=%s\n' $t $((t+2)) $((t+h)) $((t+h+3)) $((t+a)) $((t+a+2)) $((t+a+3)) $((t+g-1)) $((t+g)) $((t+g+1)) "$M1" $((t+g+2)) $((t+g+3)) "$M2" $((t+g+4)) $((t+g+7)) "$M3"
    done
    printf '4300 wait\n'
}
pins() {  # the parity gates' level and RNG pins, and the three far position pins
    python3 -c "
p=[f'{2000}-{($FR)-1}:ff8116:06']+[f'{2363}-{($FR)-1}:ff80d4:0000']
for t in (2800,3220,3640): p+=[f'{t-230}:ff8410:0228', f'{t-230}:ff8810:02d8']
print(';'.join(p))"
}
tap() {  # tap <name> <set> <rompath> <rpl>   (background)
    mkdir -p "$W/$1"
    ( cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$(pins)" FRAMES="$FR" \
        RTAP="$RT" WINDOW="0,0" TRACE_OUT="$W/$1.txt" \
        "$REPO/tools/run_mame.sh" "$2" -verbose -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/$1/mame.log" 2>&1
      rm -rf "$W/$1/sb" ) </dev/null &
}
# ONE reducer, shared by the gate and every control ([VSP-181]): one leg's tap -> rows. Each field is ONE byte of its
# tapped word: an even offset is the high byte (mask 0xff00), an odd one the low byte (mask 0x00ff); a write whose mask
# misses the field's byte is the neighbouring field and is skipped.
reduce() {  # reduce <char> <leg label> <tap.txt>
    python3 - "$1" "$2" "$3" "$EVENTS" <<'PY'
import sys
ch, leg, path, evs = sys.argv[1:5]
F = [("block140", 0xff8540, 1), ("window158", 0xff8558, 1), ("commit3b5", 0xff87b4, 0), ("x147", 0xff8546, 0),
     ("air38", 0xff8438, 1), ("cmd106", 0xff8506, 1), ("seq06", 0xff8406, 1)]
W, W2, ended = [], [], False
for l in open(path):
    t = l.split()
    if not t: continue
    if t[0] == "END": ended = True
    if t[0] == "W":
        W.append((int(t[1]), int(t[5], 16), int(t[7], 16), int(t[9], 16)))
        W2.append((int(t[1]), t[3], int(t[5], 16), int(t[7], 16), int(t[9], 16)))
if not ended: sys.exit(f"VOID: {path} has no END line (a dead tap is not evidence)")
ids = {a: (d >> 8) & 0xff for f, a, d, m in W if f < 2000 and a in (0xff8782, 0xff8b82) and m & 0xff00}
print(f"{ch}\t{leg}\t-\tids\tp1={ids.get(0xff8782, 0):02x} p2={ids.get(0xff8b82, 0):02x}")
for ev in evs.split():
    name, t = ev.split(":"); t = int(t)
    for fld, a, hi in F:
        bm = 0xff00 if hi else 0x00ff
        w = [f"{f}:{(d >> 8 if hi else d) & 0xff:02x}" for f, a_, d, m in W if t - 10 <= f < t + 70 and a_ == a and m & bm]
        print(f"{ch}\t{leg}\t{name}\t{fld}\t{','.join(w) or '-'}")
    # WHO wrote each commit mark: the commit routine's first instruction (vsavj/ours 0x029C6E, vs2 0x028FA0)
    pcs = sorted({pc for f, pc, a_, d, m in W2 if t - 10 <= f < t + 70 and a_ == 0xff87b4 and m & 0xff and d & 0xff == 6})
    print(f"{ch}\t{leg}\t{name}\tcommit_pc\t{','.join(pcs) or '-'}")
PY
}
nonzero() {  # nonzero <rows> <event pattern> <field> — non-zero writes of that field in those events
    awk -F'\t' -v ev="$2" -v fld="$3" '$3 ~ ev && $4 == fld && $5 != "-" { n = split($5, w, ","); for (i = 1; i <= n; i++) { split(w[i], p, ":"); if (p[2] != "00") c++ } } END { print c + 0 }' "$1"
}
commits() {  # commits <rows> <event pattern> — +0x3B5 := 6 writes (the commit routine's value) in those events
    awk -F'\t' -v ev="$2" '$3 ~ ev && $4 == "commit3b5" && $5 != "-" { n = split($5, w, ","); for (i = 1; i <= n; i++) { split(w[i], p, ":"); if (p[2] == "06") c++ } } END { print c + 0 }' "$1"
}
eqv() {  # eqv <rows> — the leg-free view the three legs must share: the leg label dropped, and the commit_pc rows
    # (a PC names a routine per game, [VSE-8]; each leg's writer is asserted on its own in section 3)
    awk -F'\t' -v OFS='\t' '$4 != "commit_pc" { $2 = ""; print }' "$1" | cut -f1,3-
}
plant_window() {  # plant_window <tap> — ONE non-zero +0x158 store in E1 (f3236), before that frame's first write
    awk '!done && $1 == "W" && $2 >= 3236 { print "W 3236 PC 02393a off ff8558 data 00000e0e mask 0000ff00"; done = 1 } { print }' "$1"
}
strip_ground_window() {  # every +0x158 write of E0 removed
    awk '!($1 == "W" && $2 >= 2790 && $2 < 2870 && $6 == "ff8558")' "$1"
}
plant_commit() {  # plant_commit <tap> — ONE +0x3B5 := 6 store in E1 (f3246), as the commit routine writes it
    awk '!done && $1 == "W" && $2 >= 3246 { print "W 3246 PC 028fa0 off ff87b4 data 00000606 mask 000000ff"; done = 1 } { print }' "$1"
}
strip_air_phobos() {  # every +0x158 and +0x3B4/+0x3B5 write of E1 and E2 removed
    awk '!($1 == "W" && (($2 >= 3210 && $2 < 3290) || ($2 >= 3630 && $2 < 3710)) && ($6 == "ff8558" || $6 == "ff87b4"))' "$1"
}
strip_ground_commit() {  # every +0x3B5/+0x3B4 write of E0 removed
    awk '!($1 == "W" && $2 >= 2790 && $2 < 2870 && $6 == "ff87b4")' "$1"
}

echo "== 1. wheels, rigs and taps"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_da.bin" || { echo "FAIL: vsav2 views not delivered"; exit 1; }
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_da.bin" || { echo "FAIL: vsavj views not delivered"; exit 1; }
for s in vsavj vsav2; do
    case "$s" in vsavj) da="$W/vj_da.bin" ;; *) da="$W/v2_da.bin" ;; esac
    python3 "$REPO/tools/select_wheel.py" "$da" --set "$s" --json "$W/wheel_$s.json" > "$W/wheel_$s.log" 2>&1 \
        || { echo "FAIL: $s wheel: $(tail -1 "$W/wheel_$s.log")"; exit 1; }
done
fp="$(python3 "$REPO/tools/build_fingerprint.py" --set vsavjw --sha-only "$BUILD/rompath" 2>/dev/null)" || fp=""
[ -n "$fp" ] || { echo "FAIL: no fingerprint for $BUILD/rompath"; exit 1; }
echo "  ours: $BUILD (vsavjw fingerprint $fp)"
for c in $CHARS; do
    eval "_c=\${CHAR_$c:-}"; [ -n "$_c" ] || { bad "unknown character $c"; continue; }
    rig "$c" "$W/wheel_vsav2.json" > "$W/$c.vsav2.rpl"
    tap "$c.vsav2" vsav2 "$ROMDIR" "$W/$c.vsav2.rpl"
    [ "$c" = phobos ] && continue
    rig "$c" "$W/wheel_vsavj.json" > "$W/$c.vsavj.rpl"
    tap "$c.vsavj" vsavj "$ROMDIR" "$W/$c.vsavj.rpl"
    tap "$c.ours" vsavjw "$BUILD/rompath;$ROMDIR" "$W/$c.vsavj.rpl"
done
wait
[ "$fail" = 0 ] || { echo "FAIL: audit_air_gc_legacy"; exit 1; }
for c in $CHARS; do
    [ "$c" = phobos ] || { grep -q 'load of vsavjw\.ini' "$W/$c.ours/mame.log" && ok "$c ours: MAME ran the vsavjw set" || bad "$c ours: the MAME log does not name the vsavjw set"; }
    for leg in $(legs_of "$c"); do
        [ -s "$W/$c.$leg.txt" ] || { bad "$c $leg: no tap (see $W/$c.$leg/mame.log)"; continue; }
        if vs_ctl_is air-window-planted && [ "$leg" = vsavj ]; then plant_window "$W/$c.$leg.txt" > "$W/p" && mv "$W/p" "$W/$c.$leg.txt"; fi
        if vs_ctl_is ground-window-removed; then strip_ground_window "$W/$c.$leg.txt" > "$W/p" && mv "$W/p" "$W/$c.$leg.txt"; fi
        if vs_ctl_is air-commit-planted && [ "$leg" = vsav2 ]; then plant_commit "$W/$c.$leg.txt" > "$W/p" && mv "$W/p" "$W/$c.$leg.txt"; fi
        if vs_ctl_is positive-stripped && [ "$c" = phobos ]; then strip_air_phobos "$W/$c.$leg.txt" > "$W/p" && mv "$W/p" "$W/$c.$leg.txt"; fi
        if vs_ctl_is ground-commit-removed; then strip_ground_commit "$W/$c.$leg.txt" > "$W/p" && mv "$W/p" "$W/$c.$leg.txt"; fi
    done
done
[ "$fail" = 0 ] || { echo "FAIL: audit_air_gc_legacy"; exit 1; }

echo "== 2. rows vs tests/expected/air_gc_legacy.tsv"
: > "$W/got.tsv"
for c in $CHARS; do for leg in $(legs_of "$c"); do
    reduce "$c" "$leg" "$W/$c.$leg.txt" > "$W/$c.$leg.rows" || { bad "$c $leg: reduce"; continue; }
    cat "$W/$c.$leg.rows" >> "$W/got.tsv"
done; done
sed 's/^/  | /' "$W/got.tsv"
if [ "${FREEZE:-0}" = 1 ]; then
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED: FREEZE=1 in control mode"; exit 3; }
    [ "$fail" = 0 ] || { echo "REFUSED: a leg did not reduce"; exit 3; }
    { sed -n '/^#/p' "$EXPECT" 2>/dev/null; cat "$W/got.tsv"; } > "$W/new.tsv"
    grep -q '^#' "$W/new.tsv" || { echo "REFUSED: $EXPECT has no header to keep"; exit 3; }
    mv "$W/new.tsv" "$EXPECT"; echo "FROZEN: $EXPECT ($(grep -vc '^#' "$EXPECT") rows)"; exit 0
fi
grep -v '^#' "$EXPECT" > "$W/want.tsv" || true
for c in $CHARS; do
    grep "^$c	" "$W/want.tsv" > "$W/want.$c" || true
    grep "^$c	" "$W/got.tsv" > "$W/got.$c" || true
    [ -s "$W/want.$c" ] || { bad "$c: no frozen rows"; continue; }
    if diff "$W/want.$c" "$W/got.$c" > "$W/diff.$c"; then ok "$c: $(wc -l < "$W/got.$c" | tr -d ' ') rows as frozen"
    else bad "$c: rows differ from the frozen expectation"; sed 's/^/        /' "$W/diff.$c"; fi
done

echo "== 3. the claims, read from the rows"
for c in $CHARS; do
    eval "_c=\$CHAR_$c"; set -- $_c; id=$1
    for leg in $(legs_of "$c"); do
        r="$W/$c.$leg.rows"; [ -s "$r" ] || continue
        grep -q "	ids	p1=$id p2=01$" "$r" && ok "$c $leg: picked p1=$id p2=01" || bad "$c $leg: the picks are not p1=$id p2=01 ($(grep '	ids	' "$r" | cut -f5))"
        gw="$(nonzero "$r" '^E0$' window158)"; aw="$(nonzero "$r" '^E[12]$' window158)"
        gc="$(commits "$r" '^E0$')"; ac="$(commits "$r" '^E[12]$')"
        [ "$gw" -gt 0 ] && [ "$gc" -gt 0 ] && ok "$c $leg: E0 (ground block) opens the window ($gw non-zero +0x158 writes) and commits a guard cancel ($gc +0x3B5 := 6)" \
            || bad "$c $leg: E0 does not both open the window ($gw) and commit a guard cancel ($gc) — the instrument is not proven to see them"
        case "$leg" in vsav2) cpc=028fa0 ;; *) cpc=029c6e ;; esac
        [ "$(awk -F'\t' '$3 == "E0" && $4 == "commit_pc" { print $5 }' "$r")" = "$cpc" ] && ok "$c $leg: every E0 commit mark is written by the commit routine ($cpc)" \
            || bad "$c $leg: the E0 commit mark's writer is not the commit routine $cpc ($(awk -F'\t' '$3 == "E0" && $4 == "commit_pc" { print $5 }' "$r"))"
        if [ "$c" = phobos ]; then
            # THE POSITIVE LEG: the same motion at the same air timings DOES open the window and commit, in E1 and in E2
            for e in E1 E2; do
                ew="$(nonzero "$r" "^$e\$" window158)"; ec="$(commits "$r" "^$e\$")"
                [ "$ew" -gt 0 ] && [ "$ec" -gt 0 ] && ok "$c $leg: $e (air block) opens the window ($ew) and commits an air guard cancel ($ec) — this rig's air timing can produce one" \
                    || bad "$c $leg: $e does not produce Phobos's native air guard cancel (window $ew, commit $ec) — the rig's air timing is not proven able to"
            done
            continue
        fi
        [ "$aw" = 0 ] && ok "$c $leg: E1/E2 (air block) write no non-zero +0x158" || bad "$c $leg: an air block opened the window ($aw non-zero +0x158 writes)"
        [ "$ac" = 0 ] && ok "$c $leg: E1/E2 (air block) commit no guard cancel" || bad "$c $leg: an air block committed a guard cancel ($ac +0x3B5 := 6)"
    done
    [ "$c" = phobos ] && continue
    eqv "$W/$c.vsavj.rows" > "$W/$c.eq.vsavj" 2>/dev/null || true
    for leg in vsav2 ours; do
        eqv "$W/$c.$leg.rows" > "$W/$c.eq.$leg" 2>/dev/null || true
        if [ -s "$W/$c.eq.vsavj" ] && cmp -s "$W/$c.eq.vsavj" "$W/$c.eq.$leg"; then ok "$c: $leg equals pristine vsavj on every row"
        else bad "$c: $leg differs from pristine vsavj"; diff "$W/$c.eq.vsavj" "$W/$c.eq.$leg" | sed 's/^/        /' || true; fi
    done
done

echo "== 4. must-fire controls"
if vs_ctl_is air-window-planted || vs_ctl_is ground-window-removed || vs_ctl_is air-commit-planted || vs_ctl_is ground-commit-removed || vs_ctl_is positive-stripped; then
    if [ "$fail" = 1 ]; then vs_ctl_fired "$VS_CTL" "the perturbed real taps fail the gate"; echo "FAIL: audit_air_gc_legacy (control mode)"; exit 1
    else vs_ctl_dead "$VS_CTL" "the perturbed real taps still pass" || true; echo "FAIL: audit_air_gc_legacy"; exit 1; fi
fi
first="$(echo $CHARS | cut -d' ' -f1)"
plant_window "$W/$first.vsavj.txt" > "$W/ctl_aw.tap"; reduce "$first" vsavj "$W/ctl_aw.tap" > "$W/ctl_aw.rows"
n="$(nonzero "$W/ctl_aw.rows" '^E[12]$' window158)"
if [ "$n" -gt 0 ]; then vs_ctl_fired air-window-planted "one planted store gives $first vsavj $n non-zero air +0x158 writes"
else vs_ctl_dead air-window-planted "the planted store left the air window count at 0" || fail=1; fi
strip_ground_window "$W/$first.vsavj.txt" > "$W/ctl_gw.tap"; reduce "$first" vsavj "$W/ctl_gw.tap" > "$W/ctl_gw.rows"
n="$(nonzero "$W/ctl_gw.rows" '^E0$' window158)"
if [ "$n" = 0 ]; then vs_ctl_fired ground-window-removed "the stripped copy's E0 opens no window"
else vs_ctl_dead ground-window-removed "the stripped copy still shows $n E0 window writes" || fail=1; fi
plant_commit "$W/$first.vsav2.txt" > "$W/ctl_ac.tap"; reduce "$first" vsav2 "$W/ctl_ac.tap" > "$W/ctl_ac.rows"
n="$(commits "$W/ctl_ac.rows" '^E[12]$')"; eqv "$W/ctl_ac.rows" > "$W/ctl_ac.eq"
if [ "$n" -gt 0 ] && [ -s "$W/$first.eq.vsavj" ] && ! cmp -s "$W/$first.eq.vsavj" "$W/ctl_ac.eq"; then vs_ctl_fired air-commit-planted "one planted store gives $first vsav2 $n air commit(s) and breaks the equality with vsavj"
else vs_ctl_dead air-commit-planted "the planted commit was not counted or left the legs equal" || fail=1; fi
strip_ground_commit "$W/$first.vsavj.txt" > "$W/ctl_gc.tap"; reduce "$first" vsavj "$W/ctl_gc.tap" > "$W/ctl_gc.rows"
n="$(commits "$W/ctl_gc.rows" '^E0$')"
if [ "$n" = 0 ]; then vs_ctl_fired ground-commit-removed "the stripped copy's E0 commits no guard cancel"
else vs_ctl_dead ground-commit-removed "the stripped copy still shows $n E0 commit writes" || fail=1; fi

if echo " $CHARS " | grep -q " phobos "; then
    strip_air_phobos "$W/phobos.vsav2.txt" > "$W/ctl_ps.tap"; reduce phobos vsav2 "$W/ctl_ps.tap" > "$W/ctl_ps.rows"
    ew="$(nonzero "$W/ctl_ps.rows" '^E1$' window158)"; ec="$(commits "$W/ctl_ps.rows" '^E1$')"
    if [ "$ew" = 0 ] && [ "$ec" = 0 ]; then vs_ctl_fired positive-stripped "the stripped copy of native Phobos's tap shows no E1 window and no E1 commit"
    else vs_ctl_dead positive-stripped "the stripped copy still shows E1 window $ew / commit $ec" || fail=1; fi
fi

if [ "$fail" = 0 ]; then echo "PASS: audit_air_gc_legacy — Lei-Lei's and Zabel's ground guard cancels commit and their air blocks neither open the guard window nor commit one, alike on vsavj, vs2 and ours, where native Phobos on the same rig commits one"
else echo "FAIL: audit_air_gc_legacy"; exit 1; fi
