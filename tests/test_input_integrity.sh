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

echo
[ "$fail" = 0 ] || { echo "FAIL: input-integrity self-check"; exit 1; }
echo "PASS: input-integrity self-check — silent on clean runs, non-perturbing,"
echo "      and it catches a single-frame un-scripted press at the right frame."
