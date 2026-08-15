#!/bin/sh
# propose_masked_specs.sh — measure named replays MASKED on a build against the
# frozen vanilla basis, and print the proposed `.masked` expectation line for
# each. The authoring half of promoting a legacy replay off a self-frozen
# `.sha1` (14z-89); the enforcing half is tests/audit_legacy_pairings.sh.
#
# It PROPOSES. It never writes an expectation file and never ratifies a class:
# every non-`exact` class must be mechanism-attributed, and a shape outside the
# vocabulary ("proposed: NONE") is a superset-invariant failure to root-cause,
# not a tolerance to widen (CLAUDE.md §4 standing watch).
#
# ONE RUN PER REPLAY, deliberately: tests/run_suite.sh runs every replay TWICE
# and fails on nondeterminism, and it is the acceptance gate for whatever is
# authored from this output. Duplicating that here would double the wall clock
# to re-answer a question the gate asks anyway.
#
# The basis log must already exist — freeze it first:
#   VERIFY_BASIS=16_xemu_2p tools/freeze_masked_basis.sh \
#       tests/expected/vsavj/masked-v2 "$(cat tests/expected/<set>/mask)" <name>...
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=6] [BASIS=vsavj/masked-v2]
#        tools/propose_masked_specs.sh <builddir> <replay-name>...
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
JOBS="${JOBS:-6}"
BASIS="${BASIS:-vsavj/masked-v2}"
BUILD="${1:?usage: propose_masked_specs.sh <builddir> <replay-name>...}"; shift
[ $# -ge 1 ] || { echo "no replay names given"; exit 2; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "no $BUILD/rompath/vsavjw.zip"; exit 1; }

EXP="$(python3 tools/build_fingerprint.py "$PWD/$BUILD/rompath;$ROMDIR" --set vsavjw)"
MASK="$(cat "tests/expected/$EXP/mask")"
echo "build $BUILD -> tests/expected/$EXP"
echo "mask  $MASK"
echo "basis tests/expected/$BASIS"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
pool=0
for name in "$@"; do
    if [ ! -f "tests/expected/$BASIS/logs/$name.log" ]; then
        echo "$name: NO BASIS LOG in tests/expected/$BASIS/logs — freeze it first"
        continue
    fi
    ( MASK_RANGES="$MASK" MAME_ROMPATH="$PWD/$BUILD/rompath;$ROMDIR" \
      tools/run_replay_mame.sh vsavjw "tests/replays/$name.rpl" \
      "$W/$name.log" "$W/sb_$name" >"$W/mame_$name.log" 2>&1 ) &
    pool=$((pool + 1))
    if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done
wait

for name in "$@"; do
    printf '%-34s ' "$name"
    if [ ! -f "$W/$name.log" ] || ! grep -q '^END ' "$W/$name.log"; then
        echo "RUN-FAIL (no END line) — no verdict"
        continue
    fi
    echo
    python3 tools/describe_masked_shape.py "tests/expected/$BASIS/logs/$name.log" \
        "$W/$name.log" --basis "$BASIS" | sed 's/^/    /'
done
