#!/bin/sh
# test_region_overlap_control.sh — ground truth for tests/test_region_overlap.sh
# (14z-90, GitHub issue #9).
#
# WHY. That gate froze 2000 conflicting bytes measured on build/m5_wide +
# build/hui30 + build/pyron21 — a trio that has been superseded 2-9 freezes
# over. It exited 0 while asserting facts about builds nobody ships, which is a
# false green whether or not anyone runs it. Section 5 now also asserts the
# shipped trio (2033 bytes, 7624 raw — re-measured 14z-103 on the m10/m19/m13 trio).
#
# The 2000 figure was NOT overwritten. STATE.md records it as the evidence that
# deleted the shared-span dedup work item, so re-freezing it would detach a
# closed decision from its measurement. Both numbers are asserted; this control
# proves the NEW one can fail, because a constant nobody can make fail is not
# an assertion.
#
# Usage: tests/test_region_overlap_control.sh   (no ROMs, no emulator, ~2 min)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
COPY=""
cleanup() { [ -n "$COPY" ] && rm -f "$COPY"; :; }
trap cleanup EXIT
fail=0

# The copy lives in tests/ so the gate's REPO=$0/.. still resolves. A copy
# placed elsewhere resolves REPO to the temp dir and SKIPs with exit 0 —
# observed while building this, and exactly the vacuous-control trap.
COPY="$REPO/tests/.regoverlap_control_copy.sh"

# --- 1. the current-trio constants must be able to FAIL ------------------
# Point section 5 at the SUPERSEDED trio: its real figure is 2000, so the
# 2033 assertion must reject it. This is the 2000-vs-2033 delta, asserted.
echo "== 1. current-trio section pointed at the superseded trio =="
sed 's|^CUR_BUILDS="build/don_m15 build/hui49 build/pyron33".*|CUR_BUILDS="build/m5_wide build/hui30 build/pyron21"|' \
    "$REPO/tests/test_region_overlap.sh" > "$COPY"
chmod +x "$COPY"
grep -q 'CUR_BUILDS="build/m5_wide' "$COPY" || {
    echo "FAIL: could not rewrite CUR_BUILDS — the gate's shape moved"; fail=1; }
set +e; out=$("$COPY" 2>&1); rc=$?; set -e
if [ "$rc" != 0 ] && echo "$out" | grep -q "total conflicting bytes"; then
    echo "  ok: the stale trio is rejected by the current-trio assertion"
    echo "$out" | grep "total conflicting bytes" | head -1 | sed 's/^/      /'
else
    echo "FAIL: section 5 accepted the superseded trio (rc=$rc) — the"
    echo "      constants are not actually asserting anything"
    fail=1
fi
rm -f "$COPY"; COPY=""

# --- 2. a missing NAMED build must FAIL, not SKIP ------------------------
# ~33 gates in this repo exit 0 on missing inputs. Under a named-build gate
# that is the silent-pass hazard: the gate reports on builds that are absent.
echo "== 2. a named build that is absent =="
COPY="$REPO/tests/.regoverlap_control_copy.sh"
sed 's|^HIST_BUILDS="build/m5_wide build/hui30 build/pyron21"|HIST_BUILDS="build/m5_wide build/hui30 build/definitely_not_a_build"|' \
    "$REPO/tests/test_region_overlap.sh" > "$COPY"
chmod +x "$COPY"
set +e; out=$("$COPY" 2>&1); rc=$?; set -e
if [ "$rc" != 0 ] && echo "$out" | grep -q "stale"; then
    echo "  ok: a named-but-absent build FAILs loudly instead of skipping"
else
    echo "FAIL: an absent named build did not fail the gate (rc=$rc)"
    echo "$out" | head -3
    fail=1
fi
rm -f "$COPY"; COPY=""

# --- 3. POSITIVE CONTROL: the real gate still passes --------------------
# Without this, a gate broken into always-failing would satisfy 1 and 2.
echo "== 3. positive control =="
if "$REPO/tests/test_region_overlap.sh" >/dev/null 2>&1; then
    echo "  ok: the unmodified gate still passes both trios"
else
    echo "FAIL: the real gate does not pass — sections 1-4 or 5 are wrong"
    fail=1
fi

[ "$fail" = 0 ] && echo "PASS: region-overlap trio assertions (2 negative controls + positive)" \
    || { echo "FAIL: region-overlap trio assertions"; exit 1; }
