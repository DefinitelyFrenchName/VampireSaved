#!/usr/bin/env bash
# test_shadow_tenant.sh — SHADOW morphing into a TENANT (14z-116).
# EMULATOR gate, ~6 min, two MAME runs. NOT in ci_static (see the registry
# check in run_all_static.sh); indexed in HANDOFF.
#
# THE QUESTION, in the maintainer's words: the risk with Shadow is not
# selecting him, it is "whether the game breaks when Shadow faces a tenant"
# — and "breaks" explicitly includes the QUIET failure, **Shadow taking the
# SHELL character instead of the tenant**. Donovan's shell is Victor
# (0x13 aliases 0x03), so that failure would show as record 0x0009769E
# where 0x003FA9D0 belongs, with everything else looking healthy. This gate
# exists so that answer cannot rot.
#
# THE MECHANISM (docs/game/atlas/select_screen.md, decoded 14z-116):
#   PRG:0x020CB0  cmpi.b #$5,$42(a6)   5 START PRESSES on the "?" cell 0x0B
#                                      arm $43 (gated on btst #15 of the
#                                      EDGE word d3 — presses, not a hold)
#   PRG:0x020AB4  st.b $3bc(a6)        confirm sets the copy flag
#   PRG:0x009BB2  move.b $382(a1),$382(a0)   at the ROUND/MATCH END the
#                                      flagged winner takes the LOSER's id
#                                      and palette, UNMASKED
# The copy carries no mask, no fold and no bound, and char-init then runs
# the same 32-row loader a normal tenant pick runs — so the tenant id
# survives. That is the claim; this measures it.
#
# SECTION 1  the armed leg: P1 beats tenant Donovan and MUST become him,
#            with Donovan's own record installed, not Victor's.
# SECTION 2  THE MUST-FIRE CONTROL: the identical replay with FOUR START
#            presses instead of five. $43 must stay clear, $3BC must stay
#            clear, and P1 must NOT morph. Without this leg section 1 would
#            pass just as well on a build where the flag did nothing.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged21] tests/test_shadow_tenant.sh  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-116 (~6 min, 2 MAME runs): SHADOW MORPHING INTO A TENANT. The "?" cell
#   + FIVE START PRESSES arms $43 (PRG:0x020CB0 — presses, not a hold);
#   confirm sets $3BC; at the ROUND END PRG:0x009BB2 gives the flagged winner
#   the LOSER's id, UNMASKED. Asserts P1 beats tenant Donovan and becomes id
#   0x13 with DONOVAN'S OWN record 0x003FA9D0 — the point is that it is NOT
#   Victor's 0x0009769E, the shell 0x13 aliases (the quiet failure the
#   maintainer named). Must-fire control: the same replay with FOUR presses
#   must not arm, not set $3BC and not morph. Replay 113; only the FIRST morph
#   is deterministic (the arcade draw is a lottery past ~8500).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged21}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN"; exit 0; }
export MAME_BIN
BUILD="$(cd "$BUILD" && pwd)"

# Frozen from the merged build's own table (tests/expected/roster_pairings/
# bases.tsv). DONOVAN is the tenant; VICTOR is the shell he aliases, and is
# named here only so a shell substitution is reported as one.
DONOVAN=0x3fa9d0
VICTOR=0x9769e
MORPH_FRAME=7800     # after the round-1 win at ~7400; before the arcade
                     # draw makes later frames a lottery ([VSE-79])

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
RPL="$REPO/tests/replays/113_shadow_vs_tenant.rpl"
[ -f "$RPL" ] || { echo "FAIL: missing $RPL"; exit 1; }
# The control differs by ONE line: the fifth START press is commented out.
sed 's/^1360-1362 sys=S1/# CONTROL: FOUR presses — must NOT arm/' "$RPL" > "$W/four.rpl"
cmp -s "$RPL" "$W/four.rpl" && { echo "FAIL: the control edit matched nothing — the replay's 5th press line moved"; exit 1; }

run() { # run <tag> <replay>
    mkdir -p "$W/$1"
    DUMPS="1420:ff8400-ff8c00;${MORPH_FRAME}:ff8400-ff8c00" REPLAY="$2" \
        CHECKSUM_OUT="$W/$1/c.log" MAME_SANDBOX="$W/$1/box" \
        MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
        "$REPO/tools/run_mame.sh" vsavjw \
        -autoboot_script "$REPO/tests/lua/replay.lua" > "$W/$1/mame.log" 2>&1 || {
            echo "FAIL: $1 — MAME run failed"; tail -5 "$W/$1/mame.log"; fail=1; return 1; }
    # RH-25 / CPE-9: assert the run COMPLETED before reading any value from
    # it — an aborted run leaves dumps that look like a measurement.
    grep -q '^END ' "$W/$1/c.log" || { echo "FAIL: $1 — no END line"; fail=1; return 1; }
}
fld() { # fld <tag> <frame> <side 0|1> <id|base|f3bc|f43>
    python3 - "$W/$1/dump_$2_ff8400.bin" "$3" "$4" <<'PY'
import sys
b = open(sys.argv[1], "rb").read(); o = 0x400 * int(sys.argv[2]); k = sys.argv[3]
if   k == "id":   print(f"{b[o+0x382]:#04x}")
elif k == "base": print(f"{int.from_bytes(b[o+0x60:o+0x64],'big'):#x}")
elif k == "f3bc": print(f"{b[o+0x3bc]:#04x}")
elif k == "f43":  print(f"{b[o+0x43]:#04x}")
elif k == "f42":  print(f"{b[o+0x42]:#04x}")
PY
}

echo "== 1. ARMED: five START presses on \"?\", then a round win over Donovan =="
if run armed "$RPL"; then
    a42="$(fld armed 1420 0 f42)"; a43="$(fld armed 1420 0 f43)"
    [ "$a42" = "0x05" ] && [ "$a43" = "0xff" ] \
        && echo "  ok: the arming counted 5 presses and armed (\$42=$a42 \$43=$a43)" \
        || { echo "FAIL: \$42=$a42 \$43=$a43 (want 0x05 / 0xff) — the code did not arm"; fail=1; }
    p2sel="$(fld armed 1420 1 id)"
    [ "$p2sel" = "0x13" ] && echo "  ok: P2 selected the tenant (id 0x13)" \
        || { echo "FAIL: P2 id $p2sel at select (want 0x13) — the wheel path is wrong, not the mechanism"; fail=1; }
    f3bc="$(fld armed "$MORPH_FRAME" 0 f3bc)"
    [ "$f3bc" = "0xff" ] && echo "  ok: the copy flag \$3BC is set on P1" \
        || { echo "FAIL: \$3BC=$f3bc (want 0xff)"; fail=1; }
    id="$(fld armed "$MORPH_FRAME" 0 id)"; base="$(fld armed "$MORPH_FRAME" 0 base)"
    if [ "$id" = "0x13" ] && [ "$base" = "$DONOVAN" ]; then
        echo "  ok: SHADOW BECAME THE TENANT — id $id, record $base (Donovan's own)"
    elif [ "$base" = "$VICTOR" ]; then
        echo "FAIL: SHELL SUBSTITUTION — id $id took Victor's record $base, not Donovan's $DONOVAN"; fail=1
    else
        echo "FAIL: P1 id $id record $base (want 0x13 / $DONOVAN)"; fail=1
    fi
fi

echo "== 2. CONTROL (must fire): four presses — no arm, no morph =="
if run four "$W/four.rpl"; then
    c42="$(fld four 1420 0 f42)"; c43="$(fld four 1420 0 f43)"
    [ "$c42" = "0x04" ] && [ "$c43" = "0x00" ] \
        && echo "  ok: four presses did NOT arm (\$42=$c42 \$43=$c43)" \
        || { echo "FAIL: control \$42=$c42 \$43=$c43 (want 0x04 / 0x00)"; fail=1; }
    c3bc="$(fld four "$MORPH_FRAME" 0 f3bc)"
    [ "$c3bc" = "0x00" ] && echo "  ok: \$3BC stayed clear" \
        || { echo "FAIL: control \$3BC=$c3bc (want 0x00) — the flag is not gated on the count"; fail=1; }
    cid="$(fld four "$MORPH_FRAME" 0 id)"
    [ "$cid" != "0x13" ] && echo "  ok: no morph without the flag (P1 id $cid)" \
        || { echo "FAIL: P1 morphed to $cid WITHOUT the flag — section 1 proves nothing"; fail=1; }
fi

if [ "$fail" -eq 0 ]; then echo "PASS test_shadow_tenant"; else echo "FAIL test_shadow_tenant"; fi
exit "$fail"
