#!/bin/sh
# test_mame_determinism.sh — is MAME actually deterministic, run to run?
#
# The whole oracle rests on an assumption nobody had ever measured at
# volume: that the same binary, the same set and the same inputs produce
# the same work-RAM stream every time. B5 found two counterexamples in a
# single 126-run gate execution (session 14z-59) — `08_challenger_join` and
# `41_don_altcolor_vsav2`, both diverging in the boot window and both
# refusing to reproduce in dozens of targeted repeats. Neither was a
# source-vs-Homebrew difference: both binaries reproduce each replay
# identically when re-run.
#
# So this gate measures the RATE instead of asserting the assumption. It
# runs a short boot probe N times and requires every run to be identical.
# A single divergence is a FAILURE, and the divergent pair is preserved and
# classified with tools/analyze_divergence.py — PHASE SHIFT (a timing
# difference) and TRANSIENT (real state differed) point at very different
# causes, so the gate does not make the reader guess.
#
# COVERAGE LIMIT, read this before quoting a PASS as reassurance: the
# default probe is 520 frames, while the replays that actually diverged are
# 3,000-12,000. A clean run bounds the rate for the BOOT WINDOW, which is
# where both observations started — it does not bound it for a full replay.
# 480 probe runs came back clean while the point estimate from full-length
# replays was ~1.6%/run; if the probe covered the same trigger that would be
# a ~0.04% coincidence, so it probably does NOT cover it. To measure a full
# replay instead: PROBE=tests/replays/08_challenger_join.rpl (slower, and
# that is the point).
#
# Usage:
#   ROMDIR=... [MAME_BIN=...] [RUNS=60] [SET=vsavj] [PROBE=<rpl>] \
#     tests/test_mame_determinism.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   RUNS=/JOBS=/PROBE= repetitions; measures the run-to-run divergence rate
#   the whole oracle assumes is zero (see STATE 14z-59)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
RUNS="${RUNS:-60}"
SET="${SET:-vsavj}"
BIN="${MAME_BIN:-$(command -v mame || true)}"
[ -n "$BIN" ] && [ -x "$BIN" ] || { echo "no MAME binary (set MAME_BIN)"; exit 1; }
PROBE="${PROBE:-$REPO/tests/probes/boot_probe.rpl}"
ARTIFACTS="${MAME_DET_ARTIFACTS:-$REPO/build/gate_failures/mame_determinism}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "binary : $BIN"
echo "         sha1 $(shasum "$BIN" | cut -d' ' -f1)"
echo "set    : $SET   runs: $RUNS   probe: $(basename "$PROBE")"

# JOBS>1 runs the repetitions concurrently. Both regimes matter and they
# test different hypotheses: SEQUENTIAL reproduces the regime the observed
# divergences appeared in, PARALLEL stresses the machine, which is the
# obvious suspect if the cause is anything environmental rather than
# intra-process. Report them separately; do not average them together.
JOBS="${JOBS:-1}"
echo "jobs   : $JOBS ($([ "$JOBS" = 1 ] && echo sequential || echo parallel))"

bad=0
ref=""
i=0
while [ "$i" -lt "$RUNS" ]; do
    batch=0
    first=$((i + 1))
    while [ "$batch" -lt "$JOBS" ] && [ "$i" -lt "$RUNS" ]; do
        i=$((i + 1))
        batch=$((batch + 1))
        ( MAME_BIN="$BIN" tools/run_replay_mame.sh "$SET" "$PROBE" \
              "$WORK/r$i.log" "$WORK/sb$i" >/dev/null 2>&1 ) &
    done
    wait
    n="$first"
    while [ "$n" -le "$i" ]; do
        if [ ! -s "$WORK/r$n.log" ]; then
            echo "  run $n: RUN-FAIL"
            bad=$((bad + 1))
        elif [ -z "$ref" ]; then
            ref="$WORK/ref.log"
            cp "$WORK/r$n.log" "$ref"
            echo "  run $n: reference $(shasum "$ref" | cut -d' ' -f1)"
        elif ! cmp -s "$ref" "$WORK/r$n.log"; then
            echo "  run $n: DIVERGED from the reference run"
            mkdir -p "$ARTIFACTS"
            cp "$ref" "$ARTIFACTS/ref.log"
            cp "$WORK/r$n.log" "$ARTIFACTS/run$n.log"
            python3 tools/analyze_divergence.py "$ref" "$WORK/r$n.log" \
                | sed 's/^/    /' | tee "$ARTIFACTS/run$n.verdict"
            bad=$((bad + 1))
        fi
        rm -f "$WORK/r$n.log"
        rm -rf "$WORK/sb$n"
        n=$((n + 1))
    done
done

echo
if [ "$bad" != 0 ]; then
    echo "FAIL: $bad of $RUNS runs diverged — MAME is NOT deterministic here."
    echo "      Artifacts + classification: $ARTIFACTS"
    echo "      Every frozen MAME expectation this project owns assumes it is."
    exit 1
fi
echo "PASS: $RUNS/$RUNS runs bit-identical."
echo "      Note what this does and does not say: it bounds the divergence"
echo "      rate, it does not prove the rate is zero. Raise RUNS to tighten"
echo "      the bound."
