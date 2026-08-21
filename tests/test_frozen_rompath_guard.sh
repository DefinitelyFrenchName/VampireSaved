#!/bin/sh
# test_frozen_rompath_guard.sh — tools/build_donovan.sh must refuse to rebuild
# over a FROZEN REFERENCE rompath (14z-90, GitHub issue #26).
#
# WHY. build_donovan.sh does an unconditional `rm -rf "$OUTBASE/rompath"`, and
# its callers take an arbitrary outbase. So `tests/run_battery_m2.sh
# build/don_m5` deletes the registered donovan-m5 reference and repacks a
# STOCK build under its name — the battery's prefix GEN_FLAGS carries no
# --profile, so it cannot even produce the WIDE set it just destroyed. Every
# gate then measures a different ROM under a frozen name, and
# audit_legacy_pairings.sh reports success by SKIPPING what it can no longer
# find, so the #24/#29 skip-as-pass class turns the loss into a green run.
#
# tools/run_hui_behavior.sh already refuses this class ("today's manifest would
# produce DIFFERENT bytes under an old name", 14z-71); the discipline had just
# never reached the builder itself.
#
# THE GUARD IS A TRACK-MISMATCH CHECK, and that scope was measured rather than
# assumed. An earlier revision of it refused any REGISTERED rompath — which
# would have blocked a DOCUMENTED workflow: HANDOFF.md:231 gives
# `tools/build_donovan.sh 6 build/don_m4` as a rebuild recipe, and don_m4 is a
# frozen reference. Rebuilding a WIDE reference AS WIDE is how reproducibility
# gets checked and must stay legal. What is never legal is replacing one
# track's set with the other's under the same name.
#
# COST: this runs the real builder to the point of the guard, ~4 min. It is an
# ON-DEMAND gate, not part of the fast tier. It operates on a COPY of a frozen
# rompath, never the real one — a control that could destroy the artifact it
# protects would be worse than the defect.
#
# Usage: ROMDIR=... tests/test_frozen_rompath_guard.sh   (~4 min, no emulator)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

SRC=build/don_m10/rompath
if [ ! -f "$SRC/vsavjw.zip" ]; then
    # Never silently green: without a frozen reference to copy, this control
    # would assert nothing at all.
    echo "FAIL: $SRC/vsavjw.zip absent — this control cannot run, and a SKIP"
    echo "      here would claim protection that was never tested."
    exit 1
fi

echo "== 1. a STOCK build over a WIDE rompath must be REFUSED =="
O="$WORK/frozen_copy"; mkdir -p "$O/rompath" "$O/patch"
cp "$SRC"/*.zip "$O/rompath/"
# 14z-90: the guard's FIRST version sat just before the `rm -rf rompath`,
# which is AFTER gen_donovan_patch.py has already rewritten $OUTBASE/patch/.
# I destroyed build/don_m5's patch metadata with exactly this invocation while
# testing that version — the rompath survived and the intermediates did not,
# and two static gates went red until the build was regenerated. So the
# control asserts BOTH survive; a guard that fires after the first write is
# not a guard.
echo "canary — must survive a refused rebuild" > "$O/patch/canary.txt"
before="$(ls "$O/rompath" | sort | tr '\n' ' ')"
before_patch="$(cat "$O/patch/canary.txt" 2>/dev/null || echo MISSING)"
# no --profile: this is what tests/run_battery_m2.sh does, and it is the
# exact invocation that would have destroyed the reference.
set +e
TENANT_MANIFEST=build/manifest/donovan.toml TENANT_CHAR=0x13 \
GEN_FLAGS="--allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 "$O" > "$WORK/build.log" 2>&1
rc=$?
set -e
after="$(ls "$O/rompath" 2>/dev/null | sort | tr '\n' ' ')"

if [ "$rc" != 0 ]; then echo "  ok: builder exited $rc"
else echo "FAIL: the builder proceeded over a frozen reference"; fail=1; fi

if grep -q "REFUSING to rebuild" "$WORK/build.log"; then
    echo "  ok: refusal names both tracks"
    grep "It holds a" "$WORK/build.log" | sed 's/^/      /'
else
    echo "FAIL: no refusal in the log"; tail -5 "$WORK/build.log"; fail=1
fi

# The assertion that actually matters: the artifact still exists.
if [ "$before" = "$after" ] && [ -n "$after" ]; then
    echo "  ok: the rompath SURVIVED ($after)"
else
    echo "FAIL: the rompath was modified or destroyed"
    echo "      before: [$before]  after: [$after]"; fail=1
fi
after_patch="$(cat "$O/patch/canary.txt" 2>/dev/null || echo MISSING)"
if [ "$before_patch" = "$after_patch" ]; then
    echo "  ok: the patch/ intermediates SURVIVED — the guard fired before"
    echo "      the first write, not just before the rm"
else
    echo "FAIL: patch/ was overwritten — the guard is placed AFTER generation,"
    echo "      which is the exact defect that cost a rebuild in 14z-90"
    fail=1
fi

echo "== 2. POSITIVE CONTROL: a WIDE build over a WIDE rompath must PROCEED =="
# This is HANDOFF.md:231's documented recipe (`build_donovan.sh 6 build/don_m4`
# on a frozen reference). Without this case, a guard that refused every
# registered rompath would satisfy case 1 while breaking the documented way to
# check reproducibility — which is exactly what an earlier revision of this
# guard did.
O2="$WORK/same_track"; mkdir -p "$O2/rompath"
cp "$SRC"/*.zip "$O2/rompath/"
set +e
TENANT_MANIFEST=build/manifest/donovan.toml TENANT_CHAR=0x13 \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
WIDE_ROMSET="$PWD/build/wide0/rompath/vsavjw.zip" \
    tools/build_donovan.sh 6 "$O2" > "$WORK/build2.log" 2>&1
rc2=$?
set -e
if grep -q "REFUSING to rebuild" "$WORK/build2.log"; then
    echo "FAIL: a same-track rebuild was refused — this blocks HANDOFF's own"
    echo "      documented recipe for checking reproducibility"; fail=1
elif [ "$rc2" = 0 ]; then
    echo "  ok: same-track rebuild proceeds and completes"
else
    echo "  ok: same-track rebuild was not refused by the guard (exit $rc2 came"
    echo "      from elsewhere in the build, not from the track check)"
fi

[ "$fail" = 0 ] && echo "PASS: frozen-rompath guard (refusal + artifact survives + positive control)" \
    || { echo "FAIL: frozen-rompath guard"; exit 1; }
