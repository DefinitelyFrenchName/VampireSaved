#!/bin/sh
# test_rpl2siminputs.sh — the .rpl -> jtframe sim_inputs.hex translator
# (14z-106): bit mapping locked against test.cpp's parse_inputs, a frozen
# translation of a real replay, and the refusals must FIRE (P2, button 4,
# service). ROM-free, seconds, ci_portable.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; T="$(mktemp -d)"; fail=0
ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }
P="python3 $REPO/tools/rpl2siminputs.py"

# 1 bit mapping (test.cpp: coin1 b0, start1 b2, U b4 D b5 L b6 R b7, btn1-3 b8-b10)
printf '1 p1=U1 sys=C1\n2 p1=DLR23 sys=S1S2C2\n3 wait\n5 p1=R\n' > "$T/a.rpl"
$P "$T/a.rpl" "$T/a.hex" >/dev/null
got="$(tr '\n' ' ' < "$T/a.hex")"
[ "$got" = "111 6ee 000 000 080 " ] && ok "1 bit mapping ($got)" || bad "1 bit mapping: $got"

# 2 --frames pads/truncates, --offset shifts
$P "$T/a.rpl" "$T/b.hex" --frames 3 --offset 1 >/dev/null
got="$(tr '\n' ' ' < "$T/b.hex")"
[ "$got" = "000 111 6ee " ] && ok "2 frames/offset ($got)" || bad "2 frames/offset: $got"

# 3 frozen translation of a real legacy replay (12000 frames, 13 active)
$P "$REPO/tests/replays/05_timeout_idle.rpl" "$T/c.hex" >/dev/null
h="$(shasum "$T/c.hex" | cut -c1-40)"
[ "$h" = "eb3e1d04e58b3a2b7bf713d40c4d6ac4796e550c" ] && ok "3 05_timeout_idle frozen $h" || bad "3 05_timeout_idle moved: $h"

# 4 refusals MUST fire
for case in "1 p2=U" "1 p1=4" "1 p1=6" "1 sys=TS"; do
    printf '%s\n' "$case" > "$T/r.rpl"
    if $P "$T/r.rpl" "$T/r.hex" >/dev/null 2>&1; then bad "4 refusal did not fire for '$case'"; else ok "4 refused '$case'"; fi
done
rm -rf "$T"
[ $fail = 0 ] && echo "PASS test_rpl2siminputs" || { echo "FAIL test_rpl2siminputs"; exit 1; }
