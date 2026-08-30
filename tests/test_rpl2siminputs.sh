#!/bin/sh
# test_rpl2siminputs.sh — the .rpl -> jtframe sim_inputs.hex translator
# (14z-106): bit mapping locked against test.cpp's parse_inputs, a frozen
# translation of a real replay, and the refusals must FIRE (P2, button 4,
# service). ROM-free, seconds, ci_portable.
#
# THE DIRECTION NIBBLE WAS REVERSED FROM BIRTH, AND THIS GATE FROZE THE
# REVERSAL (found 14z-107 (12), MEASURED IN FULL AND FIXED 14z-108).
# `test.cpp:380` copies the file's bits 4-7 straight onto `joystick1[3:0]`,
# and jtframe's joystick port is MSB-FIRST — `joy[3]=Up [2]=Down [1]=Left
# [0]=Right` (`modules/jtframe/hdl/keyboard/jtframe_keyboard.v:107-110`).
# The translator read the macro NAME "UDLR" as "bit4=Up ... bit7=Right", so
# every direction any replay ever asked the simulator for arrived as its
# OPPOSITE. Correct map:
#
#     file bit4 = RIGHT   bit5 = LEFT   bit6 = DOWN   bit7 = UP
#
# HOW IT WAS MEASURED, because a bit map is not to be reasoned about: four
# single-direction presses on stock `vsavj`
# (`tests/replays/107_four_directions.rpl`), read off the GAME'S OWN P1 input
# mirror `RAM:$FF8058.w` on both implementations — MAME, and `cps2w` under
# Verilator with integrity-checked work-RAM dump sets on both legs:
#
#     asked   MAME    core (pre-fix)   the core actually delivered
#     Up      0x0008  0x0001           Right
#     Down    0x0004  0x0002           Left
#     Left    0x0002  0x0004           Down
#     Right   0x0001  0x0008           Up
#
# 14z-107 (12) had only the Left/Down half and INFERRED a two-bit swap that
# left Up and Right untouched. The inference was wrong; a two-bit fix would
# have left half the defect in place. Full write-up: docs/platform/mister.md,
# "THE SIMULATED JOYSTICK'S DIRECTIONS ARE REVERSED".
#
# WHICH FROZEN EXPECTATION MOVED, AND WHICH DID NOT — stated because the
# record (STATE 14z-107, NEXT_SESSION, mister.md, gotchas.md, HANDOFF) said
# BOTH would, and that was wrong:
#   * check 1's bit-map vector MOVED, re-derived here:
#       111 6ee 000 000 080  ->  181 67e 000 000 010
#   * check 3's `05_timeout_idle` sha1 DID NOT MOVE, and cannot: that replay
#     scripts a coin, a start and one button-1 tap and NO DIRECTION TOKEN, so
#     no direction bit is ever set in its translation. Check 6 asserts that
#     mechanism directly rather than resting on the hash.
#     CONSEQUENCE: `05_timeout_idle`'s sim_inputs.hex is byte-identical across
#     this fix, so `test_mister_sim_anchor`'s frozen anchor (MAME 2146 / sim
#     2609 / skew 463) CANNOT have moved either. It was not re-run for this
#     change, and this is the reason.
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier ci_portable) `.rpl` -> `sim_inputs.hex` bit map, frozen translation,
#   refusals, the per-direction lock + its must-fire control (5/5b), and the
#   anchor-independence check + its positive control (6/6b). The direction map
#   was REVERSED end for end and is FIXED (14z-108, measured on all four
#   against `RAM:$FF8058`): the frozen vector moved `111 6ee 000 000 080` ->
#   `181 67e 000 000 010`, and the `05_timeout_idle` sha1 `eb3e1d04…` did NOT
#   move and cannot — that replay scripts no direction token, which is also
#   why the sim anchor could not move
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; T="$(mktemp -d)"; fail=0
ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }
P="python3 $REPO/tools/rpl2siminputs.py"

# 1 bit mapping (test.cpp: coin1 b0, start1 b2, R b4 L b5 D b6 U b7, btn1-3 b8-b10)
printf '1 p1=U1 sys=C1\n2 p1=DLR23 sys=S1S2C2\n3 wait\n5 p1=R\n' > "$T/a.rpl"
$P "$T/a.rpl" "$T/a.hex" >/dev/null
got="$(tr '\n' ' ' < "$T/a.hex")"
[ "$got" = "181 67e 000 000 010 " ] && ok "1 bit mapping ($got)" || bad "1 bit mapping: $got"

# 2 --frames pads/truncates, --offset shifts
$P "$T/a.rpl" "$T/b.hex" --frames 3 --offset 1 >/dev/null
got="$(tr '\n' ' ' < "$T/b.hex")"
[ "$got" = "000 181 67e " ] && ok "2 frames/offset ($got)" || bad "2 frames/offset: $got"

# 3 frozen translation of a real legacy replay (12000 frames, 13 active)
$P "$REPO/tests/replays/05_timeout_idle.rpl" "$T/c.hex" >/dev/null
h="$(shasum "$T/c.hex" | cut -c1-40)"
[ "$h" = "eb3e1d04e58b3a2b7bf713d40c4d6ac4796e550c" ] && ok "3 05_timeout_idle frozen $h" || bad "3 05_timeout_idle moved: $h"

# 4 refusals MUST fire
for case in "1 p2=4" "1 p1=4" "1 p1=6" "1 sys=TS"; do
    printf '%s\n' "$case" > "$T/r.rpl"
    if $P "$T/r.rpl" "$T/r.hex" >/dev/null 2>&1; then bad "4 refusal did not fire for '$case'"; else ok "4 refused '$case'"; fi
done

# 5 EACH DIRECTION, ONE AT A TIME, LOCKED TO ITS MEASURED FILE BIT. Check 1
# presses three directions at once and would pass under any PERMUTATION of
# the four; this is the check that names them individually.
dirbits(){   # $1 = token -> the hex word the translator emits for it alone
    printf '1 p1=%s\n' "$1" > "$T/d.rpl"
    python3 "$2" "$T/d.rpl" "$T/d.hex" >/dev/null 2>&1 || { echo "XX"; return; }
    head -1 "$T/d.hex"
}
check_dirs(){   # $1 = translator path, $2 = label; returns 0 if ALL four match
    _bad=0
    for pair in "U 080" "D 040" "L 020" "R 010"; do
        tok="${pair%% *}"; exp="${pair##* }"
        g="$(dirbits "$tok" "$1")"
        [ "$g" = "$exp" ] || { echo "    $2: $tok -> $g, expected $exp"; _bad=1; }
    done
    return $_bad
}
if check_dirs "$REPO/tools/rpl2siminputs.py" "translator"; then
    ok "5 directions map MSB-first (U=080 D=040 L=020 R=010), each measured against RAM:\$FF8058"
else
    bad "5 direction map does not match the 14z-108 measurement"
fi

# 5b MUST-FIRE CONTROL: check 5 has to REJECT the defect it was written for.
# A check that has never failed is a check nobody has proven can fail (THE
# INSTRUMENT PROTOCOL, docs/project/gotchas.md). Rebuild the PRE-14z-108
# reversed map and require check 5 to catch it.
sed 's/^DIRS = .*/DIRS = {"U": 1 << 4, "D": 1 << 5, "L": 1 << 6, "R": 1 << 7}/' \
    "$REPO/tools/rpl2siminputs.py" > "$T/reversed.py"
grep -q '"U": 1 << 4' "$T/reversed.py" || bad "5b control could not be built (DIRS line moved)"
if check_dirs "$T/reversed.py" "control" >/dev/null 2>&1; then
    bad "5b CONTROL DID NOT FIRE: check 5 passes the pre-14z-108 REVERSED map"
else
    ok "5b control fired: the reversed map is rejected"
fi

# 6 THE ANCHOR REPLAY CARRIES NO DIRECTION BIT — the mechanism behind check
# 3 not moving, asserted directly instead of inferred from a hash.
# Written in python, not awk: `and()`/`strtonum()` are GAWK builtins and this
# repo runs on BWK awk, where the first draft of this check passed because awk
# ERRORED (exit 2), not because the property held — a verdict bug of exactly
# the kind CLAUDE.md section 4 forbids, caught by 6b below before it was
# trusted.
dirbits_in(){   # count lines with any of bits 4-7 set
    python3 -c 'import sys; print(sum(1 for l in open(sys.argv[1]) if int(l,16) & 0xf0))' "$1"
}
$P "$REPO/tests/replays/05_timeout_idle.rpl" "$T/e.hex" >/dev/null
n="$(dirbits_in "$T/e.hex")"
[ "$n" = "0" ] && ok "6 05_timeout_idle sets no direction bit (so the frozen sim anchor cannot move with the map)" \
                || bad "6 05_timeout_idle sets a direction bit on $n lines — check 3's sha1 is not direction-independent"

# 6b POSITIVE CONTROL for check 6's counter: it must COUNT a direction bit.
printf '080\n000\n010\n' > "$T/f.hex"
n="$(dirbits_in "$T/f.hex")"
[ "$n" = "2" ] && ok "6b control fired: the direction-bit counter counts (2 of 3)" \
                || bad "6b CONTROL DID NOT FIRE: counter returned $n on a file with 2 direction lines"

# 7 PLAYER 2 IS SCRIPTABLE (14z-109), AND IT DID NOT MOVE PLAYER 1.
# The COVERAGE half deferred since 14z-107 (8). P2 went into file bits 12+
# because everything at and below bit 11 was already spoken for and bits 12+
# were UNUSED -- which is what makes the change provably backward compatible
# rather than believed to be. Check 3 above is the proof: the frozen
# 05_timeout_idle sha1 is asserted AFTER this change and is the same value.
p2bits_in(){   # count lines with any P2 bit (12..18) set
    python3 -c 'import sys; print(sum(1 for l in open(sys.argv[1]) if int(l,16) & 0x7f000))' "$1"
}
printf '1 p2=U\n2 p2=D\n3 p2=L\n4 p2=R\n5 p2=1\n6 p2=2\n7 p2=3\n' > "$T/p2.rpl"
if $P "$T/p2.rpl" "$T/p2.hex" --frames 7 >/dev/null 2>&1; then
    ok "7a p2 tokens are accepted (the 14z-107 (8) COVERAGE gap is closed)"
else
    bad "7a p2 tokens are still refused"
fi
if [ -s "$T/p2.hex" ]; then
    got="$(awk '{printf "%s ", $1}' "$T/p2.hex")"
    # minimal-width hex, NOT zero-padded: padding would rewrite every
    # existing sim_inputs.hex and move check 3's frozen sha1.
    exp="8000 4000 2000 1000 10000 20000 40000 "
    [ "$got" = "$exp" ] \
        && ok "7b p2 bit map frozen (U=8000 D=4000 L=2000 R=1000; buttons 10000/20000/40000)" \
        || bad "7b p2 bit map is [$got], expected [$exp]"
else
    bad "7b no p2 output produced"
fi
# 7c BACKWARD COMPATIBILITY asserted directly, not inferred from check 3:
# a replay scripting no p2 must set no P2 bit at all.
$P "$REPO/tests/replays/05_timeout_idle.rpl" "$T/nop2.hex" >/dev/null
n2="$(p2bits_in "$T/nop2.hex")"
[ "$n2" = "0" ] && ok "7c a replay scripting no p2 sets ZERO P2 bits — old files are byte-identical" \
                || bad "7c 05_timeout_idle sets a P2 bit on $n2 lines — backward compatibility is broken"
# 7d MUST-FIRE CONTROL: 7c has to be able to fail.
n3="$(p2bits_in "$T/p2.hex")"
[ "$n3" = "0" ] && bad "7d CONTROL DID NOT FIRE: the P2-bit counter reads 0 on a replay that scripts P2" \
                || ok "7d control fired: the P2-bit counter counts ($n3 of 7)"

rm -rf "$T"
[ $fail = 0 ] && echo "PASS test_rpl2siminputs" || { echo "FAIL test_rpl2siminputs"; exit 1; }
