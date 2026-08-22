#!/bin/sh
# setup_jtcores.sh — check out the pinned jtcores FORK (the MiSTer core
# tree), init only the submodules this project needs, and build jtframe's
# Go tool. Mirrors tools/setup_mame.sh / setup_fbneo.sh (14z-106).
#
# WHY A FORK AND A PIN. The MiSTer deliverable is a SEPARATE core
# (cores/cps2w -> jtcps2w.rbf) inside a public GPL-3.0 fork of
# jotego/jtcores, so the reference cps2 core stays untouched and usable
# (maintainer ruling 2026-08-22; docs/platform/mister.md). The gitlink AND
# this literal SHA pin it — the MAME lesson (setup_mame.sh): a submodule
# add once staged the default branch while the tag sat only in the
# worktree. emu/jtcores-patches/0001-*.patch is the fork's diff against
# upstream v1.7.3, regenerated here, so the change stays a reviewable
# in-tree file (CLAUDE.md rule 1 v2) — tests/test_jtcores_twin.sh holds
# the patch, the submodule and the core twin to each other.
#
# NEVER init modules/jtframe/target/pocket: it is a PRIVATE ssh submodule
# (git@github.com:jotego/pocket.git) and `--init --recursive` aborts on it.
#
# Usage: tools/setup_jtcores.sh          (no ROMs; needs git, go)
#   env JTCORES_SKIP_GO=1 to skip building the Go tool.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/emu/jtcores"
UPSTREAM_TAG_SHA="63688ce5f4de9b92ac4d2ea4b306009b8ba4bcdb"   # jotego/jtcores v1.7.3
PINNED="b9d0565f372c8ae6921d95c67eae517d6e6b4816"             # fork branch vampire-saved
FORK_URL="https://github.com/DefinitelyFrenchName/jtcores"

if [ ! -f "$SRC/.gitmodules" ]; then
    echo "emu/jtcores is empty — initialising the submodule from $FORK_URL" >&2
    git -C "$REPO" submodule update --init emu/jtcores
fi
HEAD="$(git -C "$SRC" rev-parse HEAD)"
if [ "$HEAD" != "$PINNED" ]; then
    echo "emu/jtcores is at $HEAD, expected pin $PINNED" >&2
    echo "  git -C emu/jtcores fetch origin && git -C emu/jtcores checkout $PINNED" >&2
    echo "  (or update PINNED here deliberately, with the patch regenerated)" >&2
    exit 1
fi
if [ -n "$(git -C "$SRC" status --porcelain --ignore-submodules=all)" ]; then
    echo "emu/jtcores has local modifications — commit them to the fork" >&2
    echo "branch and move PINNED, or \`git -C emu/jtcores checkout .\`" >&2
    exit 1
fi
git -C "$SRC" submodule update --init modules/jtdsp16
echo "jtcores @ $HEAD (fork of v1.7.3 $UPSTREAM_TAG_SHA); jtdsp16 $(git -C "$SRC" submodule status modules/jtdsp16 | cut -c2-41)"

# The reviewable mirror of the fork's delta.
git -C "$SRC" format-patch --stdout "$UPSTREAM_TAG_SHA..$PINNED" \
    > "$REPO/emu/jtcores-patches/0001-cps2w-scaffold.patch"

if [ "${JTCORES_SKIP_GO:-0}" != "1" ]; then
    command -v go >/dev/null 2>&1 || { echo "go not found (brew install go)" >&2; exit 1; }
    ( cd "$SRC/modules/jtframe/src/jtframe" && go build -o jtframe . )
    echo "jtframe tool: $SRC/modules/jtframe/src/jtframe/jtframe"
    echo "env: JTROOT=$SRC JTFRAME=$SRC/modules/jtframe JTBIN=$SRC/release CORES=$SRC/cores ROM=$SRC/rom"
fi
