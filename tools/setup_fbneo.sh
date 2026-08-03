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

# CPS-2 WIDE profile patch (docs/cps2_wide.md). Separate file from the
# harness patch on purpose: the harness is frontend-only infrastructure,
# while this one adds a DRIVER DESCRIPTOR and is governed by Rule 1 v2.
# Keeping the trust surfaces separable is the point.
# Set WIDE=0 to build the harness-only reference binary that
# tests/test_wide_profile.sh needs for the emulator superset invariant.
# IMPORTANT: that reference must differ from the test binary ONLY by this
# patch — build it from the SAME tree state (harness included), or the
# comparison silently measures unrelated frontend differences instead.
WPATCH="$REPO/emu/fbneo-patches/0002-cps2-wide-v1.patch"
if [ "${WIDE:-1}" = "0" ]; then
    echo "WIDE=0: harness-only build (reference binary for the superset invariant)"
elif git -C "$FB" apply --check "$WPATCH" 2>/dev/null; then
    git -C "$FB" apply "$WPATCH"
    echo "CPS-2 WIDE profile patch applied"
elif grep -q Cps2Wide "$FB/src/burn/drv/capcom/cps.h" 2>/dev/null; then
    echo "CPS-2 WIDE profile patch already present"
else
    echo "WIDE patch neither applies nor present — submodule state unexpected" >&2
    exit 1
fi

# SKIPDEPEND=1 means header changes are NOT tracked (docs/GOTCHAS.md), so a
# driver edit needs its object invalidated explicitly.
touch "$FB/src/burn/drv/capcom/d_cps2.cpp" "$FB/src/burn/drv/capcom/cps_obj.cpp"
# Portable job count: nproc on Linux/WSL2, sysctl on macOS.
cd "$FB" && make sdl2 SKIPDEPEND=1 \
    -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"
echo "built: $FB/fbneo"
