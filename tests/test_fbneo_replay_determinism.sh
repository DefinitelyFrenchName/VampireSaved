#!/bin/sh
# test_fbneo_replay_determinism.sh — patched FBNeo runs a scripted replay
# with identical work-RAM checksums across two fresh-sandbox runs.
# (Guards the EEPROM-sandboxing fix — see docs/GOTCHAS.md.)
#
# Usage: ROMDIR=... tests/test_fbneo_replay_determinism.sh [set] [replay]
set -eu

SET="${1:-vsavj}"
RPL="${2:-$(cd "$(dirname "$0")" && pwd)/replays/02_demitri_vs_cpu.rpl}"
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

"$REPO/tools/run_replay_fbneo.sh" "$SET" "$RPL" "$WORK/a.log"
"$REPO/tools/run_replay_fbneo.sh" "$SET" "$RPL" "$WORK/b.log"
if cmp -s "$WORK/a.log" "$WORK/b.log"; then
    echo "PASS: FBNeo replay deterministic ($(grep -c ' ' "$WORK/a.log") frames)"
else
    echo "FAIL: FBNeo runs differ; first divergence:"
    diff "$WORK/a.log" "$WORK/b.log" | head -3
    exit 1
fi
