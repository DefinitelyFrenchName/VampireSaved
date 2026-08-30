#!/bin/sh
# test_fbneo_runner_hygiene.sh — a failed FBNeo run must not leave the PREVIOUS
# run's artifacts behind (14z-90, GitHub issue #12, shell half).
#
# WHY. tools/run_replay_fbneo.sh decides success by an ARTIFACT check —
# `grep -q "^END " "$OUT"` — and did not clear $OUT first. Paired with the C++
# half (main.cpp calls HarnessRun() for side effects inside a void DoGame and
# then returns 0 unconditionally, so a harness that never ran still exits 0),
# a failed run left yesterday's checksum log, .tap and .dump_*.bin in place and
# the caller read them as this run's results.
#
# Committed gates are saved by mktemp-fresh output paths — that is real, and it
# is why this is not critical. But docs/platform/gotchas.md:703 documents the
# INTERACTIVE recipe with a fixed reusable `out.log`, and the gotcha above it
# records that the emulator's own error text is redirected into the sandbox log
# and only shown on non-zero exit. Silent failure + hidden error + fixed path
# is how a previous build's tap gets measured and written into an atlas row.
#
# WHAT THIS CONTROL CAN AND CANNOT SEE. For a ROM-load failure FBNeo does exit
# non-zero, so the exit CODE is not the discriminator here; the surviving
# artifact is. Measured on the pre-fix runner: rc=1 but "$OUT" still present
# holding its old content. The exit-code half is the C++ change and batches
# with the rest of the FBNeo cluster behind #36.
#
# Usage: ROMDIR=... tests/test_fbneo_runner_hygiene.sh   (no ROMs used, ~5s)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-90 (issue #12, shell half): a FAILED FBNeo run must not leave the
#   previous run's log/.tap/side-channel outputs behind, because the
#   completion check is an ARTIFACT check (grep ^END). Measured pre-fix: rc=1
#   but $OUT still present with its old content. ROMDIR, ~5s
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

FB="${FBNEO_BIN:-$REPO/emu/fbneo/fbneo}"
if [ ! -x "$FB" ]; then
    # Never silently green: without the binary this control measures nothing.
    echo "FAIL: no FBNeo binary at $FB — this control cannot run, and a SKIP"
    echo "      here would assert hygiene that was never tested."
    exit 1
fi

mkdir -p "$WORK/empty"

echo "== 1. a failed run must not leave the previous run's log =="
printf '1 deadbeefdeadbeef\nEND 1\n' > "$WORK/o.log"
printf 'stale tap\n' > "$WORK/o.log.tap"
set +e
out=$(ROMDIR="$WORK/empty" tools/run_replay_fbneo.sh vsavj \
      "$REPO/tests/replays/01_attract_long.rpl" "$WORK/o.log" 2>&1)
rc=$?
set -e
if [ -f "$WORK/o.log" ]; then
    echo "FAIL: the stale checksum log survived a failed run"
    echo "      (its first line is still: $(head -1 "$WORK/o.log"))"
    fail=1
else
    echo "  ok: stale checksum log removed before the run"
fi
if [ -f "$WORK/o.log.tap" ]; then
    echo "FAIL: the stale .tap survived a failed run"; fail=1
else
    echo "  ok: stale .tap removed too"
fi
if [ "$rc" = 0 ]; then
    echo "FAIL: the runner reported success on a run that could not load ROMs"
    fail=1
else
    echo "  ok: runner exited $rc"
fi

echo "== 2. the named side-channel outputs are cleared by name =="
# FBNEO_HVIDEO / FBNEO_HTAP_OUT are read via getenv inside the harness and
# never appear in argv, so a caller-supplied path has to be cleared explicitly.
printf 'stale video\n' > "$WORK/v.log"
printf 'stale tapout\n' > "$WORK/t.log"
set +e
FBNEO_HVIDEO="$WORK/v.log" FBNEO_HTAP_OUT="$WORK/t.log" \
    ROMDIR="$WORK/empty" tools/run_replay_fbneo.sh vsavj \
    "$REPO/tests/replays/01_attract_long.rpl" "$WORK/o2.log" >/dev/null 2>&1
set -e
if [ -f "$WORK/v.log" ] || [ -f "$WORK/t.log" ]; then
    echo "FAIL: a stale side-channel output survived (video=$([ -f "$WORK/v.log" ] && echo present || echo gone), tap=$([ -f "$WORK/t.log" ] && echo present || echo gone))"
    fail=1
else
    echo "  ok: FBNEO_HVIDEO and FBNEO_HTAP_OUT outputs cleared"
fi

echo "== 3. POSITIVE CONTROL: the guard idiom is set -e safe =="
# `[ -n "$X" ] && rm -f "$X"` with X unset must not abort the script. If it
# did, every ordinary run would die before starting and cases 1-2 would still
# pass — so this asserts the runner survives the common path.
if sh -c 'set -eu; [ -n "${NOPE:-}" ] && rm -f /nonexistent; echo alive' \
      | grep -q alive; then
    echo "  ok: unset side-channel vars do not abort the runner"
else
    echo "FAIL: the guard idiom aborts under set -e — every run would die"
    fail=1
fi

[ "$fail" = 0 ] && echo "PASS: FBNeo runner artifact hygiene (stale log/tap/side-channels + set -e safety)" \
    || { echo "FAIL: FBNeo runner artifact hygiene"; exit 1; }
