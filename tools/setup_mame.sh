#!/bin/sh
# setup_mame.sh — bring the pinned MAME submodule to the patched, built state.
#
# Usage: tools/setup_mame.sh
# Env:
#   MAME_BUILD_ROOT  build mirror location (default ~/.cache/vampire-saved/mame)
#   WIDE=0           build the reference binary WITHOUT the profile patch
#                    (tests/test_mame_wide.sh needs one for the emulator
#                    superset invariant; it must differ from the build under
#                    test by ONLY that patch, so build it from the same tree)
#   MAME_JOBS        parallelism (default: hw.ncpu)
#
# Idempotent: pins the submodule, mirrors it, applies our patches (skipped if
# already applied), builds. Prints the resulting binary path.
#
# Prerequisites:
#   macOS       brew install sdl3 pkgconf
#   Debian/WSL2 apt install libsdl3-dev pkgconf build-essential python3
# MAME 0.288's OSD is SDL3 and its scripts/src/osd/sdl3.lua finds it through
# pkg-config ONLY — with pkg-config absent it silently falls back to
# framework linkage and the build dies on 'SDL3/SDL.h' file not found,
# several minutes in (docs/GOTCHAS.md). That is not macOS-specific.
#
# WSL2 note: keep BOTH the repo and MAME_BUILD_ROOT on the ext4 filesystem
# (~/...), never under /mnt/c. Building ~900 MB of sources across the
# 9p/drvfs bridge is dramatically slower and has its own file-semantics
# surprises.
#
# WHY AN OUT-OF-TREE MIRROR (docs/GOTCHAS.md):
#   MAME's GENie build system does not support spaces anywhere in the source
#   path — scripts/genie.lua:18 carries the escaping line COMMENTED OUT
#   upstream, and SOURCES= builds shell out to makedep.py with MAME_DIR
#   unquoted. This repository's path contains a space. Symlinking to a
#   space-free path does NOT help: GENie resolves the physical path through
#   getcwd(). So the pinned submodule stays the source of truth (never built
#   in, stays clean) and the build runs from an rsync'd, space-free mirror.
#
# WHY A SOURCES-FILTERED BUILD:
#   SUBTARGET=cps2 SOURCES=src/mame/capcom/cps2.cpp builds only the CPS-2
#   driver, which is minutes rather than hours. Whether that changes emulation
#   is not argued, it is MEASURED: tests/test_mame_parity.sh requires the
#   resulting binary to reproduce the frozen vanilla oracle logs bit-for-bit.
set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/emu/mame"
# Portable job count: nproc on Linux/WSL2, sysctl on macOS.
JOBS="${MAME_JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

# WIDE and reference builds get SEPARATE roots by default so both binaries
# exist at once — the emulator superset invariant compares them, so building
# one over the other would mean a full rebuild every time the gate runs.
if [ -n "${MAME_BUILD_ROOT:-}" ]; then
    MIRROR="$MAME_BUILD_ROOT"
elif [ "${WIDE:-1}" = "0" ]; then
    MIRROR="$HOME/.cache/vampire-saved/mame-ref"
else
    MIRROR="$HOME/.cache/vampire-saved/mame"
fi

case "$MIRROR" in
*[[:space:]]*)
    echo "MAME_BUILD_ROOT contains a space: '$MIRROR'" >&2
    echo "MAME's build system cannot handle that — pick a space-free path." >&2
    exit 1 ;;
esac

# >>> MIRROR GUARD (GitHub #80) >>>   [extracted verbatim by
#     tests/test_mame_mirror_guard.sh — keep both markers, and keep this block
#     self-contained: it may read only MIRROR, REPO, SRC and HOME]
# MIRROR GUARD (14z-94, GitHub #80). Below, this script runs
#
#     rsync -a --delete "$SRC/" "$MIRROR/"
#
# and --delete removes everything in $MIRROR that is not in the MAME source.
# $MIRROR came from an environment variable whose only validation was "no
# spaces", so a typo or a stale export in a shell — `MAME_BUILD_ROOT=$HOME`,
# or a work directory reused while troubleshooting a build location — deletes
# unrelated files. No malicious input required; this is a normal-use hazard.
#
# TWO INDEPENDENT CHECKS, because either alone leaves a hole:
#
#   1. CANONICAL PATH. Reject the filesystem root, $HOME itself, any ANCESTOR
#      of the repo or of $HOME, and the repo/source trees in either direction.
#      realpath resolves `..` spellings and symlink aliases, which is what a
#      string comparison misses. Note $HOME/.cache/... is fine — it is a
#      descendant of $HOME, not $HOME.
#
#   2. OWNERSHIP SENTINEL. Canonical checks cannot know that
#      ~/projects/scratch is precious. So --delete only ever runs inside a
#      directory this script has claimed. A NEW or EMPTY target is claimed
#      automatically (initialization stays one command); a pre-existing
#      NON-EMPTY directory without the sentinel is refused, and the operator
#      is told exactly how to opt in. That is the case that eats data.
#
# The sentinel names the tool and the mirrored source so a stray file cannot
# accidentally read as one.
MIRROR_SENTINEL=".vampire-saved-mame-mirror"

canon() { python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"; }
MIRROR_C="$(canon "$MIRROR")"
REPO_C="$(canon "$REPO")"
SRC_C="$(canon "$SRC")"
HOME_C="$(canon "$HOME")"

refuse() {
    echo "REFUSING to mirror into '$MIRROR'" >&2
    echo "  resolves to: $MIRROR_C" >&2
    echo "  reason: $1" >&2
    echo "" >&2
    echo "  This script runs 'rsync --delete' into that directory, which" >&2
    echo "  would remove everything there that is not part of MAME." >&2
    echo "  Set MAME_BUILD_ROOT to a dedicated path, e.g." >&2
    echo "    MAME_BUILD_ROOT=\$HOME/.cache/vampire-saved/mame" >&2
    exit 1
}

[ "$MIRROR_C" = "/" ]      && refuse "that is the filesystem root"
[ "$MIRROR_C" = "$HOME_C" ] && refuse "that is your home directory itself"
[ "$MIRROR_C" = "$REPO_C" ] && refuse "that is this repository"
[ "$MIRROR_C" = "$SRC_C" ]  && refuse "that is the pinned MAME submodule (the mirror SOURCE)"

# An ancestor of the repo, the source, or $HOME. The trailing separator is
# what keeps /Users/koneko-backup from matching /Users/koneko.
for descendant in "$REPO_C" "$SRC_C" "$HOME_C"; do
    case "$descendant" in
    "$MIRROR_C"/*) refuse "that directory CONTAINS $descendant" ;;
    esac
done
# ...and inside the repo or the source tree, which --delete would gut.
case "$MIRROR_C" in
"$REPO_C"/*) refuse "that is inside this repository" ;;
"$SRC_C"/*)  refuse "that is inside the pinned MAME submodule" ;;
esac

# Ownership sentinel: --delete only runs where this script has claimed.
if [ ! -e "$MIRROR_C" ]; then
    :                                  # new target — claimed on creation below
elif [ ! -d "$MIRROR_C" ]; then
    refuse "that path exists and is not a directory"
elif [ -f "$MIRROR_C/$MIRROR_SENTINEL" ]; then
    :                                  # ours already
elif [ -z "$(ls -A "$MIRROR_C" 2>/dev/null)" ]; then
    :                                  # empty — safe to claim
elif [ -f "$MIRROR_C/makefile" ] && [ -d "$MIRROR_C/src/mame" ] \
                                 && [ -d "$MIRROR_C/src/emu" ]; then
    # MIGRATION (14z-94): mirrors created before the sentinel existed carry
    # no marker, and refusing them would break working setups for a guard
    # that is supposed to be invisible in normal use. All three of makefile +
    # src/mame + src/emu together is a MAME source tree and nothing else —
    # a scratch or documents directory does not accidentally have them — so
    # such a directory is adopted and claimed below.
    :
else
    echo "REFUSING to mirror into '$MIRROR'" >&2
    echo "  resolves to: $MIRROR_C" >&2
    echo "  reason: it already exists, is NOT empty, and carries no" >&2
    echo "          $MIRROR_SENTINEL marker — so this script has never" >&2
    echo "          owned it and cannot know what is in it." >&2
    echo "" >&2
    echo "  'rsync --delete' would remove every file there that is not part" >&2
    echo "  of MAME. If this directory really is a disposable build mirror," >&2
    echo "  say so explicitly:" >&2
    echo "    touch '$MIRROR_C/$MIRROR_SENTINEL'" >&2
    echo "  Otherwise point MAME_BUILD_ROOT somewhere dedicated." >&2
    exit 1
fi
# <<< MIRROR GUARD <<<

# The pinned revision, stated here as well as in the gitlink, because
# `submodule update` silently checks out whatever the INDEX says. Paid for:
# `git submodule add` staged the default branch (master, 0.289) while the
# tag was only checked out in the working tree and never staged, so a later
# `submodule update` reset the tree to 0.289 — and the WIDE binary got
# built from a DIFFERENT MAME than the reference binary. That is the
# drifting-reference trap (14z-55) in a new costume: the comparison still
# "passes", it just no longer means what it says.
PINNED="27a8d9e85b58058965907d1d8a7a92f8ed039348"   # tag mame0288

git -C "$REPO" submodule update --init --depth 1 emu/mame 2>/dev/null \
    || git -C "$REPO" submodule update --init emu/mame
[ -f "$SRC/src/mame/capcom/cps2.cpp" ] || {
    echo "submodule emu/mame is not checked out as expected" >&2; exit 1; }
HEAD_SHA="$(git -C "$SRC" rev-parse HEAD)"
if [ "$HEAD_SHA" != "$PINNED" ]; then
    echo "emu/mame is at $HEAD_SHA but the pin is $PINNED (tag mame0288)." >&2
    echo "Every frozen MAME expectation belongs to the pinned revision;" >&2
    echo "building another one silently changes the instrument. Fix with:" >&2
    echo "  git -C emu/mame checkout $PINNED && git add emu/mame" >&2
    exit 1
fi
echo "MAME source: $(git -C "$SRC" rev-parse --short HEAD) (tag mame0288, verified)"

# The submodule is the pristine pin AND the authoring workspace for the patch
# below. If it is left dirty, the mirror inherits those edits and the patch
# then fails to apply — or worse, silently applies on top of them. Refuse.
if [ -n "$(git -C "$SRC" status --porcelain)" ]; then
    echo "emu/mame has uncommitted changes." >&2
    echo "Regenerate the patch and restore the pin:" >&2
    echo "  git -C emu/mame diff > emu/mame-patches/0002-cps2-wide-v1.patch" >&2
    echo "  git -C emu/mame checkout ." >&2
    exit 1
fi

# Mirror. Anchored excludes only: an unanchored '/build/' would also drop
# scripts/build/, whose complay.py the layout rules need (paid for once).
mkdir -p "$MIRROR"

# Claim the target BEFORE the destructive step, so an interrupted first run
# leaves an owned mirror rather than a half-populated unowned one that the
# guard above would then refuse forever (GitHub #80). Excluded from the rsync
# below for the same reason --delete would otherwise remove it on every run.
if [ ! -f "$MIRROR/$MIRROR_SENTINEL" ]; then
    {
        echo "VampireSaved MAME build mirror."
        echo "Written by tools/setup_mame.sh; source: $SRC_C"
        echo "This directory is DISPOSABLE: setup_mame.sh runs 'rsync --delete'"
        echo "into it. Do not keep anything here you want to survive."
    } > "$MIRROR/$MIRROR_SENTINEL"
    echo "claimed build mirror: $MIRROR_C"
fi

rsync -a --delete --exclude '/.git' --exclude '/build/' \
      --exclude "/$MIRROR_SENTINEL" "$SRC/" "$MIRROR/"

# CPS-2 WIDE profile patch (docs/project/cps2_wide.md), the MAME twin of
# emu/fbneo-patches/0002. Governed by Rule 1 v2: a new driver entry carrying
# the profile, and one gated conditional of emulation logic.
#
# NOTE: applied with patch(1), NOT `git apply`. The mirror lives under
# $HOME, and if $HOME happens to be a git repository (it is, on this
# machine) then `git -C <mirror> apply` treats the diff's paths as
# repo-root-relative, finds them outside the current prefix, prints
# "Skipped patch ..." and EXITS 0. The build then succeeds and produces a
# STOCK binary while the script cheerfully reports the patch applied.
# `--check` passes too. patch(1) has no repository semantics.
# Whatever the tool, the exit code is not the evidence — the assertion
# below is (docs/GOTCHAS.md).
WPATCH="$REPO/emu/mame-patches/0002-cps2-wide-v1.patch"
MARKER="cps2wide"
if [ "${WIDE:-1}" = "0" ]; then
    echo "WIDE=0: unpatched build (reference binary for the superset invariant)"
elif [ ! -f "$WPATCH" ]; then
    echo "no WIDE patch yet at $WPATCH — building stock MAME"
else
    patch -p1 --forward --silent -d "$MIRROR" < "$WPATCH" || {
        echo "WIDE patch does not apply to the pinned tree" >&2; exit 1; }
    # Prove it landed. Both files, not just one.
    grep -q "$MARKER" "$MIRROR/src/mame/capcom/cps2.cpp" \
        && grep -q "^vsavjw" "$MIRROR/src/mame/mame.lst" || {
        echo "patch reported success but the mirror does not carry it" >&2
        echo "  (cps2.cpp marker '$MARKER' and/or the mame.lst row are missing)" >&2
        exit 1; }
    echo "CPS-2 WIDE profile patch applied (verified in the mirror)"
fi

cd "$MIRROR"
# REGENIE=1 every time: the patch adds a driver to src/mame/mame.lst, and the
# generated drivlist/project files must be rebuilt from it or the new entry is
# silently absent from the binary. Cheap next to the compile.
make SUBTARGET=cps2 SOURCES=src/mame/capcom/cps2.cpp NOWERROR=1 REGENIE=1 -j"$JOBS"

# SUBTARGET=cps2 names the binary after the subtarget, not "mame<sub>".
BIN="$MIRROR/cps2"
[ -x "$BIN" ] || { echo "build finished but no binary at $BIN" >&2; exit 1; }

# End-to-end assertion: does the BINARY carry what we asked for? A
# SOURCES-filtered build silently omits a driver missing from mame.lst, and
# a silently-skipped patch produces a stock binary that builds perfectly.
# Neither shows up in an exit code, so check the artifact itself.
if [ "${WIDE:-1}" != "0" ] && [ -f "$WPATCH" ]; then
    "$BIN" -listfull vsavjw >/dev/null 2>&1 || {
        echo "built binary does NOT know the vsavjw driver — the profile is absent" >&2
        exit 1; }
    echo "verified: binary carries the vsavjw driver"
else
    ! "$BIN" -listfull vsavjw >/dev/null 2>&1 || {
        echo "reference binary unexpectedly KNOWS vsavjw — not a clean reference" >&2
        exit 1; }
    echo "verified: reference binary has no vsavjw driver"
fi
echo "built: $BIN"
