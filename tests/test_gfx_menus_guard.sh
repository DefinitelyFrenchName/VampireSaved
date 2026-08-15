#!/bin/sh
# test_gfx_menus_guard.sh — ground truth for the pixel gate's rompath guard
# (14z-90, GitHub issue #6).
#
# WHY. tests/test_gfx_menus.sh hardcoded build/donovan6/rompath while its
# caller built into $OUTBASE, so on any non-default outbase the soaks and the
# masked legacy gate measured one build and the pixel gate measured another.
# The dangerous half is that it did not SKIP — tools/run_mame.sh chains
# "$rompath;$ROMDIR" and MAME resolves missing members by hash out of the
# pristine set (docs/platform/gotchas.md, 14z-62h), so the gate compared
# vanilla against vanilla-frozen goldens: a permanent pass proving nothing.
#
# The guard tests the SET ZIP, not the directory, and that distinction is the
# whole point: build/don_m5/rompath and build/hui40/rompath EXIST and contain
# vsavjw.zip only, so a `[ -d ]` check passes and falls straight through.
#
# These three cases run WITHOUT the emulator (the guard fires first); the
# positive control does start MAME.
#
# Usage: ROMDIR=... tests/test_gfx_menus_guard.sh   (~40s, MAME for case 3)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
G=tests/test_gfx_menus.sh

echo "== 1. a rompath that does not exist =="
set +e; out=$("$REPO/$G" /nonexistent/rompath 2>&1); rc=$?; set -e
if [ "$rc" != 0 ] && echo "$out" | grep -q "no vsavj.zip"; then
    echo "  ok: FAILs and names the missing set"
else
    echo "FAIL: an absent rompath did not fail the gate (rc=$rc)"; fail=1
fi

echo "== 2. a rompath that EXISTS but holds no vsavj.zip =="
# This is the case a directory-existence check cannot catch. Use a real WIDE
# build dir if present, else synthesise the same shape.
WIDE_RP="$REPO/build/don_m5/rompath"
if [ ! -f "$WIDE_RP/vsavjw.zip" ] || [ -f "$WIDE_RP/vsavj.zip" ]; then
    WIDE_RP="$(mktemp -d)/rompath"; mkdir -p "$WIDE_RP"; : > "$WIDE_RP/vsavjw.zip"
fi
set +e; out=$("$REPO/$G" "$WIDE_RP" 2>&1); rc=$?; set -e
if [ "$rc" != 0 ] && echo "$out" | grep -q "no vsavj.zip"; then
    echo "  ok: a vsavjw-only dir FAILs instead of falling through to \$ROMDIR"
else
    echo "FAIL: a set-less rompath did not fail the gate (rc=$rc) — this is"
    echo "      the silent vanilla-vs-vanilla pass the fix exists to close"
    fail=1
fi

echo "== 3. POSITIVE CONTROL: the default invocation still passes =="
if [ -f "$REPO/build/donovan6/rompath/vsavj.zip" ]; then
    set +e; out=$("$REPO/$G" 2>&1); rc=$?; set -e
    if [ "$rc" = 0 ] && echo "$out" | grep -q "PASS: menu gfx gate"; then
        echo "  ok: default rompath still gates three frames pixel-exact"
    else
        echo "FAIL: the gate no longer passes on its default build (rc=$rc)"
        echo "$out" | tail -4
        fail=1
    fi
else
    # Never silently green: an unrun positive control is the vacuous-pass trap.
    echo "FAIL: build/donovan6/rompath/vsavj.zip absent — the positive control"
    echo "      cannot run, so cases 1-2 prove only that the gate can refuse."
    fail=1
fi

[ "$fail" = 0 ] && echo "PASS: pixel-gate rompath guard (2 negative controls + positive)" \
    || { echo "FAIL: pixel-gate rompath guard"; exit 1; }
