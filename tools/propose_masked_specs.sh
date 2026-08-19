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
# THE TRACK IS DETECTED, NOT ASSUMED (14z-97, GitHub #96). This took
# `vsavjw` as a literal, so it served the WIDE track only — while the M2
# battery it now authors expectation sets for builds the STOCK track
# (tools/build_donovan.sh with no --profile, packing vsavj.zip). Detection is
# by which zip the build actually packed; SET= overrides it.
#
# MASK= IS THE AUTHORING ESCAPE, and it is the only one. Registry resolution
# is the normal path and it FAILS LOUDLY on an unregistered fingerprint —
# which is correct for a gate but useless for the one job this tool has:
# measuring a build that is not registered YET, in order to author the set
# that will register it. Passing MASK= says "I am authoring", prints the
# unregistered fingerprint, and skips the lookup. It must match the mask the
# BASIS was frozen under (tests/expected/<basis>/MASK) — the same pairing
# run_suite.sh enforces at compare time — and this checks that when the basis
# records one.
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=6] [BASIS=vsavj/masked-v2]
#        [SET=vsavj|vsavjw] [MASK=<ranges>]
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

# CANONICALISE THE BUILD PATH FIRST (14z-97). This script used to test
# `$BUILD/rompath/...` for existence but hand `$PWD/$BUILD/rompath` to MAME
# and to build_fingerprint — correct only while BUILD is REPO-RELATIVE. Given
# an ABSOLUTE builddir the two disagree: the existence checks pass, the
# emulator gets a path that cannot exist, MAME falls through the ';' rompath
# to $ROMDIR, and every shape below is measured on PRISTINE VANILLA while the
# header still names the build. Measured live: an absolute-path run printed
# fingerprint b0eb9ecd (vanilla) for a stage-6 build. Same class as the two
# caller-environment gotchas of 14z-96 (relative ROMDIR through a symlink,
# FBNeo overlay + cd) — a tool that is correct only when called from one
# directory with one spelling of its argument.
case "$BUILD" in /*) ;; *) BUILD="$PWD/$BUILD" ;; esac

SET="${SET:-}"
if [ -z "$SET" ]; then
    if [ -f "$BUILD/rompath/vsavjw.zip" ]; then SET=vsavjw
    elif [ -f "$BUILD/rompath/vsavj.zip" ]; then SET=vsavj
    else echo "no vsavjw.zip or vsavj.zip in $BUILD/rompath"; exit 1; fi
fi
[ -f "$BUILD/rompath/$SET.zip" ] || { echo "no $BUILD/rompath/$SET.zip"; exit 1; }

if [ -n "${MASK:-}" ]; then
    echo "build $BUILD -> AUTHORING (MASK given; no registry lookup)"
    echo "      fingerprint $(python3 tools/build_fingerprint.py \
        "$BUILD/rompath;$ROMDIR" --set "$SET" --sha-only)"
    basismask="tests/expected/$BASIS/MASK"
    if [ -f "$basismask" ] && [ "$MASK" != "$(cat "$basismask")" ]; then
        echo "REFUSING: the basis $BASIS was frozen under"
        echo "    $(cat "$basismask")"
        echo "  but MASK= gives"
        echo "    $MASK"
        echo "  Masked bytes are skipped from the checksum, so the two are not"
        echo "  comparable and every shape below would be noise."
        exit 1
    fi
else
    EXP="$(python3 tools/build_fingerprint.py "$BUILD/rompath;$ROMDIR" --set "$SET")"
    MASK="$(cat "tests/expected/$EXP/mask")"
    echo "build $BUILD -> tests/expected/$EXP"
fi
echo "set   $SET"
echo "mask  $MASK"
echo "basis tests/expected/$BASIS"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
pool=0
for name in "$@"; do
    if [ ! -f "tests/expected/$BASIS/logs/$name.log" ]; then
        echo "$name: NO BASIS LOG in tests/expected/$BASIS/logs — freeze it first"
        continue
    fi
    ( MASK_RANGES="$MASK" MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
      tools/run_replay_mame.sh "$SET" "tests/replays/$name.rpl" \
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
