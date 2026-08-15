#!/bin/sh
# freeze_masked_basis.sh — (re)generate a VANILLA masked-basis log set.
#
# The hooked-build legacy oracle (CLAUDE.md §4) compares live work RAM
# with a set of ratified windows EXCLUDED from the per-frame checksum
# (tests/lua/replay.lua MASK_RANGES: offsets from $FF0000, end exclusive,
# masked bytes are SKIPPED from the checksummed stream). That means the
# vanilla side of every masked comparison must be checksummed under the
# SAME mask as the build under test — so whenever the ratified window list
# grows, the vanilla masked logs are regenerated under the new mask into a
# NEW basis dir (v1 = tests/expected/vsavj/masked, round 64; v2 =
# masked-v2, 14z-64; v3 = masked-v3, 14z-88 — the row-0x1D staging slot).
# Older basis dirs are kept: superseded expectation sets still cite them.
#
# Deterministic and re-derivable from $ROMDIR: each replay runs TWICE on
# vanilla vsavj and the pair must be bit-identical before it is written.
#
# Usage: ROMDIR=... tools/freeze_masked_basis.sh <basis-dir> <mask> <replay-name>...
#   e.g. tools/freeze_masked_basis.sh tests/expected/vsavj/masked-v3 \
#          "043c-043d,4182-41a2,41c2-41e2,4222-4262,42a2-42c2,7f00-8000" \
#          01_attract_long 02_demitri_vs_cpu ...
# Writes <basis-dir>/logs/<name>.log + <basis-dir>/<name>.sha1 and a
# <basis-dir>/MASK record of the mask string used. Honours MAME_BIN.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:?basis dir}"; MASK="${2:?mask string}"; shift 2
[ $# -ge 1 ] || { echo "no replay names given"; exit 2; }
case "$DEST" in /*) ;; *) DEST="$REPO/$DEST" ;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$DEST/logs"
printf '%s\n' "$MASK" > "$DEST/MASK"
fail=0
for name in "$@"; do
    rpl="$REPO/tests/replays/$name.rpl"
    [ -f "$rpl" ] || { echo "$name: no such replay"; fail=1; continue; }
    printf '%-24s ' "$name"
    MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" \
        "$REPO/tools/run_replay_mame.sh" vsavj "$rpl" "$WORK/$name.1.log" \
        || { echo "RUN-FAIL (1)"; fail=1; continue; }
    MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" \
        "$REPO/tools/run_replay_mame.sh" vsavj "$rpl" "$WORK/$name.2.log" \
        || { echo "RUN-FAIL (2)"; fail=1; continue; }
    if ! cmp -s "$WORK/$name.1.log" "$WORK/$name.2.log"; then
        echo "NONDETERMINISTIC — not written"; fail=1; continue
    fi
    cp "$WORK/$name.1.log" "$DEST/logs/$name.log"
    sha="$(shasum "$WORK/$name.1.log" | cut -d' ' -f1)"
    echo "$sha" > "$DEST/$name.sha1"
    echo "frozen $sha ($(grep -c '^' "$DEST/logs/$name.log") lines)"
done
[ "$fail" = 0 ] && echo "BASIS FROZEN: $DEST" || { echo "BASIS INCOMPLETE"; exit 1; }
