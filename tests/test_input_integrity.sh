#!/bin/sh
# test_input_integrity.sh — ground truth for the input-integrity check.
#
# WHY IT EXISTS (session 14z-59c). Two MAME replay divergences went
# unexplained through ~2,400 runs of statistics. The maintainer then
# supplied the mechanism: the harness runs on their working laptop, and
# MAME's "-video none" still creates a window that can TAKE FOCUS. Any host
# keystroke landing on it is injected into the EMULATED controls — MAME's
# default map covers P1 directions, buttons, coins and start. A replay that
# absorbs a stray keypress diverges for as long as the key is held and then
# RE-CONVERGES when the script's own staging reasserts: precisely the
# signature observed (frames 190-205 and 218-245, both re-converging).
#
# Two responses, and this gate covers the second:
#   PREVENT — tools/run_mame.sh disables all four host input providers.
#   DETECT  — replay.lua verifies every frame that the live controller bits
#             are exactly what it staged, and writes INPUT-VIOLATION into
#             the log if not; run_replay_mame.sh then fails the run.
#
# CLAUDE.md §4: "Verdict logic is itself tested." A check that has only
# ever been silent proves nothing, so this exercises BOTH directions.
# It also documents a real bug this gate caught in the checker's first
# draft: comparing whole ports flagged every replay at frame 77, because
# :IN2 carries the EEPROM data line alongside the coin/start bits. The
# check now compares only bits the harness can drive.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/test_input_integrity.sh
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
RPL="tests/replays/02_demitri_vs_cpu.rpl"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

echo "== 1. NEGATIVE control: a clean run must NOT trip the check =="
if tools/run_replay_mame.sh vsavj "$RPL" "$WORK/clean.log" "$WORK/sb1" >"$WORK/e1" 2>&1; then
    if grep -q "^INPUT-VIOLATION" "$WORK/clean.log"; then
        echo "  FAIL: violation reported on a clean run (false positive)"; fail=1
    else
        got="$(shasum "$WORK/clean.log" | cut -d' ' -f1)"
        exp="$(cat tests/expected/vsavj/02_demitri_vs_cpu.sha1)"
        if [ "$got" = "$exp" ]; then
            echo "  ok: clean, and still bit-identical to the frozen expectation"
        else
            echo "  FAIL: the check perturbed the run ($got != $exp)"; fail=1
        fi
    fi
else
    echo "  FAIL: clean run rejected:"; sed 's/^/    /' "$WORK/e1" | head -4; fail=1
fi

echo "== 2. POSITIVE control: one stray un-scripted press MUST be caught =="
# INPUT_INJECT_TEST presses P1 Button 1 at this frame WITHOUT recording it
# in held[] — exactly what a host keystroke looks like to the harness.
if INPUT_INJECT_TEST=500 tools/run_replay_mame.sh vsavj "$RPL" \
        "$WORK/dirty.log" "$WORK/sb2" >"$WORK/e2" 2>&1; then
    echo "  FAIL: the injected stray input was NOT detected — the check is blind"
    fail=1
else
    if grep -q "INPUT INTEGRITY VIOLATION" "$WORK/e2"; then
        echo "  ok: detected and the run was rejected"
        grep "^INPUT-VIOLATION" "$WORK/dirty.log" | sed 's/^/    /'
        # It must name the right frame, or it is detecting the wrong thing.
        if grep -q "^INPUT-VIOLATION [0-9]* frame 500 " "$WORK/dirty.log"; then
            echo "  ok: violation reported at the injected frame (500)"
        else
            echo "  FAIL: violation reported at the wrong frame"; fail=1
        fi
    else
        echo "  FAIL: run rejected, but not for an input violation:"
        sed 's/^/    /' "$WORK/e2" | head -4; fail=1
    fi
fi

echo "== the frame-1 baseline is ASSERTED, not adopted (GitHub #57) =="
# The one input pattern with NO divergence signature is a key held from
# BEFORE frame 1 through the whole run: the old code took frame 1's port read
# as "idle", so such a press became the baseline and matched every later
# frame. Zero violations, clean log, P1 direction pressed for the entire run.
#
# This is a STRUCTURAL check on purpose. MAME samples the ports before the
# frame_done callback, so no Lua injection can dirty frame 1's own read —
# measured twice (script load, and the top of frame 1; both land at frame 2),
# and INPUT_INJECT_TEST=1 cannot fire at all since its condition needs frame
# 0. The branch is reachable in the FIELD (a host key held physically is in
# that read) and not from here, so the gate asserts the code shape rather
# than pretending to exercise it.
if grep -q 'baseline\[tag\] = integ_ports\[tag\]:read()' tests/lua/replay.lua; then
    echo "  FAIL: replay.lua still ADOPTS frame 1's reading as the idle"
    echo "        baseline — a control held from boot is invisible to the guard"
    fail=1
elif grep -q 'baseline\[tag\] = controlled\[tag\]' tests/lua/replay.lua; then
    echo "  ok: the baseline is the known active-low idle (all controlled bits)"
else
    echo "  FAIL: cannot find the baseline assignment in replay.lua at all"; fail=1
fi
if grep -q 'are already LOW' tests/lua/replay.lua; then
    echo "  ok: and frame 1 is compared against it, with a named diagnosis"
else
    echo "  FAIL: frame 1 sets a baseline but never CHECKS it"; fail=1
fi
# Corroboration from the run above, not from reading the source: the injected
# violation printed `expected 7f7f ... (mask 7f7f)` — expected == mask, i.e.
# the idle really is all-ones for the controlled bits.
if [ -f "$WORK/e2" ] && grep -qE 'expected ([0-9a-f]+) got [0-9a-f]+ \(mask \1\)' "$WORK/e2"; then
    echo "  ok: the live control corroborates it — expected == mask == all-ones"
fi

echo
[ "$fail" = 0 ] || { echo "FAIL: input-integrity self-check"; exit 1; }
echo "PASS: input-integrity self-check — silent on clean runs, non-perturbing,"
echo "      it catches a single-frame un-scripted press at the right frame, and"
echo "      the frame-1 idle baseline is asserted rather than adopted."
