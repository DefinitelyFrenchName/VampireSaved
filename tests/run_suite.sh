#!/bin/sh
# run_suite.sh — the legacy oracle replay suite (MAME side).
#
# Usage: ROMDIR=... tests/run_suite.sh [--freeze] [set]
#
# For every tests/replays/*.rpl: run it twice on <set> (default vsavj), fail
# on any nondeterminism, then compare the checksum-log SHA-1 against the
# frozen expectation in tests/expected/<set>/<name>.sha1.
#   --freeze: write expectations instead of comparing (only for a build
#   decision recorded in STATE.md — expectations are the superset invariant).
#
# Expectations are per-set; the build-fingerprint dispatch (auto-detecting
# runner, CLAUDE.md §4) will layer on top when patched builds exist.
set -eu

FREEZE=0
if [ "${1:-}" = "--freeze" ]; then FREEZE=1; shift; fi
SET="${1:-vsavj}"
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
EXPDIR="$REPO/tests/expected/$SET"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$EXPDIR"

fail=0
for rpl in "$REPO"/tests/replays/*.rpl; do
    name="$(basename "$rpl" .rpl)"
    printf '%-24s ' "$name"
    "$REPO/tools/run_replay_mame.sh" "$SET" "$rpl" "$WORK/$name.1.log" || { echo "RUN-FAIL"; fail=1; continue; }
    "$REPO/tools/run_replay_mame.sh" "$SET" "$rpl" "$WORK/$name.2.log" || { echo "RUN-FAIL"; fail=1; continue; }
    if ! cmp -s "$WORK/$name.1.log" "$WORK/$name.2.log"; then
        echo "NONDETERMINISTIC (first divergent frame below)"
        diff "$WORK/$name.1.log" "$WORK/$name.2.log" | head -3
        fail=1
        continue
    fi
    sha=$(shasum "$WORK/$name.1.log" | cut -d' ' -f1)
    if [ "$FREEZE" = 1 ]; then
        echo "$sha" > "$EXPDIR/$name.sha1"
        echo "frozen $sha"
    elif [ ! -f "$EXPDIR/$name.sha1" ]; then
        echo "NO-EXPECTATION (run with --freeze after review)"
        fail=1
    elif [ "$sha" = "$(cat "$EXPDIR/$name.sha1")" ]; then
        echo "PASS"
    else
        echo "FAIL expected $(cat "$EXPDIR/$name.sha1") got $sha"
        cp "$WORK/$name.1.log" "$WORK/$name.divergent.log" 2>/dev/null || true
        fail=1
    fi
done

[ "$fail" = 0 ] && echo "SUITE GREEN" || echo "SUITE RED"
exit "$fail"
