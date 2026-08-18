#!/bin/sh
# ensure_merged_inputs.sh — resolve the merged build's four ROM-derived inputs,
# REGENERATING any that are absent (14z-95, GitHub #27).
#
# Usage: ROMDIR=... tools/ensure_merged_inputs.sh [--check]
#          (no args)  create whatever is missing, then verify all four exist
#          --check    report only; never create. Exit 1 if anything is missing.
#
# WHY THIS EXISTS. tools/build_merged.sh and tests/audit_merged_legacy.sh both
# consumed three `build/*/extract` dirs and `build/wide0` that are untracked by
# rule 7 and that NOTHING IN THE TREE KNEW HOW TO MAKE — the recipe lived as
# prose in HANDOFF.md and in an `echo` on audit_merged_legacy's SKIP path. So
# CLAUDE.md rule 3, "the repo must be able to reproduce the output set from
# pristine inputs at any commit", was false for the milestone deliverable: the
# merged artifact was reproducible on one machine, for as long as those
# directories happened to survive.
#
# MAINTAINER RULING 2026-08-18 (#27): "it should be one command; the procedure
# should be considered only if a single command cannot work." A documented
# procedure a human follows does NOT satisfy rule 3.
#
# THREE PROPERTIES THIS FILE IS BUILT AROUND, each paid for by a real defect:
#
#   1. CREATE-IF-ABSENT, NEVER REBUILD-OVER. #27 asked for these dirs to become
#      regenerable while #26 asked for them to be PROTECTED from being rebuilt
#      over — opposite policies on the same objects, which is what kept #27
#      open. They stop being opposite at this rule: an existing input is used
#      untouched, and only a MISSING one is produced. Nothing here can replace
#      a frozen artifact.
#   2. ONE COPY OF THE ROOT CENSUS. Extraction's real input is the ~170-line
#      per-character extra-roots census in tools/build_donovan.sh, with the
#      measurement behind every span. This calls that script (EXTRACT_ONLY=1)
#      rather than restating the census, so the two cannot drift.
#   3. GEN_FLAGS MUST MATCH THE TRACK. All three pinned dirs hold vsavjw.zip,
#      so build_donovan.sh's cross-track guard (#26) refuses a stock-flagged
#      rebuild into them. Extract-only packs nothing and the guard is
#      irrelevant to it — but passing the matching flag is cheaper and safer
#      than teaching the guard an exemption it would then carry forever.
#
# WHAT THIS DOES NOT PROVE, and where that is proved instead: that a
# REGENERATED extract is byte-identical to the pinned one. It has to be, or the
# merged program fingerprint moves and that is CLAUDE.md rule 6 rather than a
# build convenience. tests/test_merged_inputs.sh measures it.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# dir | char | manifest — the three frozen verticals whose extracts feed the
# merged generator. The DIR NAMES are historical (they are the build each
# extract was first produced in); extraction depends only on
# (vsav2.zip, vhunt2.zip, char, roots), which is why regenerating reproduces
# them byte-for-byte.
TENANTS="build/m5_wide:0x13:build/manifest/donovan.toml \
build/hui32:0x10:build/manifest/huitzil.toml \
build/pyron21:0x11:build/manifest/pyron.toml"

WIDE_DIR="build/wide0/rompath"
WIDE_ZIP_DEFAULT="$WIDE_DIR/vsavjw.zip"
# A caller may point at its own overlay (build_merged.sh's WIDE_ROMSET). Only
# the DEFAULT path is ours to produce — regenerating into a path someone else
# named would be exactly the rebuild-over this file forbids.
WIDE_ZIP="${WIDE_ZIP:-$WIDE_ZIP_DEFAULT}"
# Callers spell the same file both ways — build_merged.sh and
# audit_merged_legacy.sh both build it as "$PWD/build/wide0/..." while this
# file's own default is relative. A plain string compare would read the
# absolute spelling as "someone else's path" and refuse to produce the very
# file it owns, so both spellings count as the default.
WIDE_IS_DEFAULT=0
case "$WIDE_ZIP" in
    "$WIDE_ZIP_DEFAULT"|"$REPO/$WIDE_ZIP_DEFAULT") WIDE_IS_DEFAULT=1 ;;
esac

missing=""

# NB a `for` over the row list, NOT `echo ... | while read`: a piped while runs
# in a SUBSHELL, so its exit status and any variable it sets are lost to the
# rest of the script — the shape that makes a loop look like it verified
# something it did not.
for row in $TENANTS; do
    dir="${row%%:*}"; rest="${row#*:}"
    char="${rest%%:*}"; man="${rest#*:}"
    if [ -d "$dir/extract" ]; then
        echo "  ok (present, untouched): $dir/extract"
        continue
    fi
    if [ "$CHECK_ONLY" = "1" ]; then
        echo "  MISSING: $dir/extract"
        missing="$missing $dir/extract"
        continue
    fi
    echo "  regenerating $dir/extract (char $char) ..."
    EXTRACT_ONLY=1 TENANT_CHAR="$char" TENANT_MANIFEST="$man" \
        GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
        ROMDIR="$ROMDIR" tools/build_donovan.sh 6 "$dir" >/dev/null || {
            echo "FAIL: could not extract char $char into $dir" >&2; exit 1; }
    [ -d "$dir/extract" ] || {
        echo "FAIL: $dir/extract still absent after extraction" >&2; exit 1; }
    echo "  made: $dir/extract"
done

if [ -f "$WIDE_ZIP" ]; then
    echo "  ok (present, untouched): $WIDE_ZIP"
elif [ "$CHECK_ONLY" = "1" ]; then
    echo "  MISSING: $WIDE_ZIP"
    missing="$missing $WIDE_ZIP"
elif [ "$WIDE_IS_DEFAULT" = "0" ]; then
    echo "FAIL: $WIDE_ZIP is missing, and it is a caller-supplied path —" >&2
    echo "      only $WIDE_ZIP_DEFAULT is regenerable from here." >&2
    exit 1
else
    echo "  regenerating $WIDE_ZIP ..."
    # The SHIPPABLE overlay (group C zero-filled) — NOT the B4 canary romset,
    # which takes --gfx-copy-group-b and must never be merged into a build
    # (HANDOFF: hash-shadowing, the 14z-60y sprite garble).
    python3 tools/build_wide_romset.py "$ROMDIR" "$WIDE_DIR" \
        --qsound 2 --gfx 4 --prg 4 >/dev/null || {
            echo "FAIL: could not build the WIDE overlay" >&2; exit 1; }
    [ -f "$WIDE_ZIP" ] || {
        echo "FAIL: $WIDE_ZIP still absent after build_wide_romset" >&2; exit 1; }
    echo "  made: $WIDE_ZIP"
fi

if [ "$CHECK_ONLY" = "1" ]; then
    [ -z "$missing" ] || { echo "CHECK FAILED: missing$missing"; exit 1; }
    echo "CHECK OK: three extracts + the WIDE overlay are all present"
    exit 0
fi

# final verification, independent of which branch produced each input
missing=""
for d in build/m5_wide/extract build/hui32/extract build/pyron21/extract; do
    [ -d "$d" ] || missing="$missing $d"
done
[ -f "$WIDE_ZIP" ] || missing="$missing $WIDE_ZIP"
[ -z "$missing" ] || { echo "FAIL: still missing$missing" >&2; exit 1; }
echo "INPUTS OK: three extracts + the WIDE overlay"
