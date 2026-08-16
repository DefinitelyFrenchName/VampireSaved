#!/bin/sh
# pack_build.sh — pack patched program files into a runnable rompath dir.
#
# Usage: pack_build.sh <program_files_dir> <out_rompath_dir> [--set vsavj]
# Zips the loose program members (+ key) from <program_files_dir> into
# <out_rompath_dir>/<set>.zip. Run MAME/FBNeo with
#   -rompath "<out_rompath_dir>;$ROMDIR"
# so the parent (vsav.zip) and device (qsound_hle.zip) resolve from ROMDIR
# while the patched program overrides. (MAME will flag a CRC audit mismatch
# on the modified file — expected; it still runs and decrypts it.)
set -eu

SRC="${1:?usage: pack_build.sh <program_dir> <out_rompath_dir> [--set NAME] [--merge ZIP]}"
OUT="${2:?out rompath dir required}"
SET="vsavj"
MERGE=""
shift 2
while [ $# -gt 0 ]; do
    case "$1" in
    --set)   SET="${2:?--set needs a name}"; shift 2 ;;
    # --merge: fold in members from an existing zip that this build does not
    # produce itself — for a CPS-2 WIDE set that is the appended gfx/QSound
    # members from tools/build_wide_romset.py. Members we produced always
    # WIN, so a patched program member is never overwritten by the stock one.
    --merge) MERGE="${2:?--merge needs a zip}"; shift 2 ;;
    *) echo "pack_build.sh: unknown argument '$1'" >&2; exit 1 ;;
    esac
done
ROMDIR="${ROMDIR:?set ROMDIR (for the .key source)}"

mkdir -p "$OUT"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp "$SRC"/*.* "$STAGE"/ 2>/dev/null || true
# 14z-90 (GitHub issue #55). That `|| true` swallows a failed copy, and the
# pack then proceeds over an EMPTY stage. On the --merge path the result is
# worse than an empty zip: the merge fills it with the reference members, so
# the artifact is a PRISTINE set whose program fingerprint equals the
# registered VANILLA vsavj row — run_suite.sh would dispatch it to the vanilla
# expectation set and read GREEN. A build that produced nothing must not be
# packable, and must certainly not impersonate vanilla.
_pb_n=$(ls -1 "$STAGE" 2>/dev/null | wc -l | tr -d ' ')
[ "${_pb_n:-0}" -gt 0 ] || {
    echo "pack_build.sh: no program members copied from $SRC — refusing to" >&2
    echo "  pack. On the --merge path this would produce a set that" >&2
    echo "  fingerprints as VANILLA and dispatch to the vanilla expectations." >&2
    exit 1; }
if [ -n "$MERGE" ]; then
    [ -f "$MERGE" ] || { echo "pack_build.sh: no merge zip at $MERGE" >&2; exit 1; }
    MSTAGE="$(mktemp -d)"
    unzip -q -o "$MERGE" -d "$MSTAGE"
    for f in "$MSTAGE"/*; do
        b="$(basename "$f")"
        # do not clobber anything this build produced
        [ -e "$STAGE/$b" ] || cp "$f" "$STAGE/$b"
    done
    rm -rf "$MSTAGE"
    echo "merged missing members from $(basename "$MERGE")"
fi
# Ensure the key is present. AFTER the merge, so a WIDE set inherits
# vsavj.key from the merge zip; ROMDIR has no vsavjw.zip to take it from.
# KEY_SET names the romset that actually owns the key (a profile clone uses
# its parent's).
if ! ls "$STAGE"/*.key >/dev/null 2>&1; then
    unzip -o -q "$ROMDIR/${KEY_SET:-$SET}.zip" '*.key' -d "$STAGE"
fi
( cd "$STAGE" && rm -f "$SET.zip" && zip -q -X "$SET.zip" * )
cp "$STAGE/$SET.zip" "$OUT/$SET.zip"
echo "packed $OUT/$SET.zip"

# MEMBER-IDENTITY AUDIT (14z-60z). Both emulators resolve a ROM entry by
# HASH before falling back to its NAME, so a member carrying the PRISTINE
# bytes of a member this build patched can shadow it: the patch reverts
# silently, with no error and no 0xFF-fill tell. That is exactly how the
# WIDE romset shipped Donovan with vanilla tiles for two sessions — the
# merged group C was a byte copy of group B (the B4 canary shape).
# Runs on --merge builds, where the hazard is introduced. Non-fatal here
# only because the gfx half of a build lands after this script; the gate
# tests/test_romset_identity.sh and build_donovan.sh fail hard on it.
if [ -n "$MERGE" ]; then
    REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
    python3 "$REPO_DIR/tools/audit_romset_identity.py" "$OUT" --quiet || {
        echo "pack_build.sh: MEMBER-IDENTITY AUDIT FAILED (see above)" >&2
        exit 1
    }
fi
