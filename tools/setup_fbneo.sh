#!/bin/sh
# setup_fbneo.sh — bring the FBNeo submodule to the patched, built state.
#
# Usage: tools/setup_fbneo.sh
# Idempotent: checks out the pinned submodule commit, applies our harness
# patch (skipped if already applied), builds. SKIPDEPEND=1 is mandatory
# (docs/GOTCHAS.md). Needs: brew sdl2(-compat), sdl2_image, perl.
set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
FB="$REPO/emu/fbneo"

git -C "$REPO" submodule update --init --depth 1 emu/fbneo

PATCH="$REPO/emu/fbneo-patches/0001-vampire-saved-harness.patch"
if git -C "$FB" apply --check "$PATCH" 2>/dev/null; then
    git -C "$FB" apply "$PATCH"
    echo "harness patch applied"
elif [ -f "$FB/src/burner/sdl/harness.cpp" ]; then
    echo "harness patch already present"
else
    echo "patch neither applies nor present — submodule state unexpected" >&2
    exit 1
fi

cd "$FB" && make sdl2 SKIPDEPEND=1 -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
echo "built: $FB/fbneo"
