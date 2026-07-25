#!/bin/sh
# build_donovan.sh — the donovan-m2 build driver: checksum gate -> extract
# (vhunt2 oracle) -> generate staged patch -> apply -> pack runnable rompath.
#
# Usage: ROMDIR=... tools/build_donovan.sh <stage 1-5> [outbase=build/donovan]
#
# Output: <outbase>/rompath/vsavj.zip — run with
#   MAME_ROMPATH="<outbase>/rompath;$ROMDIR" tools/run_mame.sh vsavj ...
# All ROM-derived intermediates live under <outbase> (gitignored) and are
# regenerated from $ROMDIR on every run (repo rule 7).
set -eu

STAGE="${1:?usage: build_donovan.sh <stage 1-5> [outbase]}"
OUTBASE="${2:-build/donovan}"
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

python3 tools/audit_roms.py "$ROMDIR" > /dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

# EXTRA_ROOTS: absent-in-vsavj support routines ported as extra code
# regions (found by the stage-4 R1 loop; see docs/tables/reconciliation.md).
# Default = the full stage-4 set: the +0x34 newcomer-support zone, the tiny
# VS2 helpers, the id-normalization/char-init engine pair, the source-only
# per-game hook, and the 17 extra secondary-object handlers (types 59-75,
# forced-twin +0x34, caps = inter-handler gaps). Only the handler types
# Donovan actually spawns are ported (59-62); the other extras belong to
# Huitzil/Pyron and stay TRIPWIRED — loud if ever reached (space budget,
# session 5).
DEFAULT_ROOTS="0x5c800:0xd100,0x26142:0x1400,0x28122:0xe00,0x88512:0x2f00:s,0x2b8060:0xb0a0:t0x2a4504:d"
DEFAULT_ROOTS="$DEFAULT_ROOTS,0x65952:0x2d0:t0x65986,0x65c22:0x238:t0x65c56,0x65e5a:0x106a:t0x65e8e,0x66ec4:0x2b8:t0x66ef8"
python3 tools/extract_char.py "$ROMDIR/vsav2.zip" "$OUTBASE/extract" \
    --char 0x13 --oracle "$ROMDIR/vhunt2.zip" \
    --extra-roots "${EXTRA_ROOTS:-$DEFAULT_ROOTS}" > "$OUTBASE/extract.log" 2>&1 \
    || { tail -20 "$OUTBASE/extract.log"; exit 1; }

# GEN_FLAGS: extra generator flags (e.g. "--allow-plausible --tripwire-open"
# for stage-4 experiment builds while the R1 map converges)
# shellcheck disable=SC2086
python3 tools/gen_donovan_patch.py "$OUTBASE/extract" "$OUTBASE/patch" \
    --vsavj "$ROMDIR/vsavj.zip" --stage "$STAGE" ${GEN_FLAGS:-}

python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$OUTBASE/prg" \
    --patch "$OUTBASE/patch/patch.json" | tail -3

rm -rf "$OUTBASE/rompath"
ROMDIR="$ROMDIR" tools/pack_build.sh "$OUTBASE/prg" "$OUTBASE/rompath" > /dev/null
python3 tools/build_fingerprint.py "$OUTBASE/rompath;$ROMDIR" --sha-only \
    | sed 's/^/build fingerprint: /'
echo "OK: stage $STAGE build at $OUTBASE/rompath (fingerprint above; register in tests/expected/registry.tsv at freeze time)"
