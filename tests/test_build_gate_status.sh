#!/bin/sh
# test_build_gate_status.sh — ground truth for "a rejected build must abort
# the gate" (14z-90, GitHub issue #1).
#
# WHY. tests/test_m2b_stage6.sh and tests/test_m2a_stage4_code.sh piped
# tools/build_donovan.sh through `tail`. Under #!/bin/sh with no pipefail a
# pipeline's status is the LAST command's, so `tail` always returned 0 and
# the builder's own rejection paths were discarded:
#
#     build_donovan.sh :263  rm -rf "$OUTBASE/rompath"
#                      :275/:287  pack the rompath        <-- artifact on disk
#                      :404  verify_gfx_build.py          <-- can reject
#                      :415  audit_romset_identity.py     <-- can reject
#
# The pack happens BEFORE either rejection, so a build the builder refuses is
# already sitting at $OUTBASE/rompath when the gate soaks it and prints PASS.
# Two further variants: a build dying before :263 leaves the PREVIOUS
# rompath in place (the whole gate then validates yesterday's ROM under
# today's name), and on a FRESH outbase it leaves none at all — at which
# point run_mame.sh's chained `-rompath "dir;$ROMDIR"` silently resolves the
# PRISTINE reference set and the legacy gate measures vanilla against vanilla.
#
# Same class as docs/project/gotchas.md "Pipe a build tool through tail and a
# crash packs STALE artifacts", which this project already paid for once.
#
# HOW. No ROMs and no emulator: the gates are copied into a scratch repo
# whose tools/build_donovan.sh is a stub with scripted failure behaviour.
# Each gate derives REPO from its own $0, so a copied tree is a faithful
# harness. The four cases are the three failure modes plus a positive
# control — without the last one, a gate that ALWAYS aborts would pass.
#
# Usage: tests/test_build_gate_status.sh   (no ROMDIR, no emulator, ~1s)
set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail=0

# --- build the scratch repo ---------------------------------------------
R="$WORK/repo"
mkdir -p "$R/tests/lib" "$R/tools" "$WORK/romdir"
# GATE_SRC lets the ground-truth run point at the PRE-FIX gates, so "this
# control actually fails on the broken code" is rerunnable rather than a
# one-off claim:
#   mkdir /tmp/pre && git show HEAD~1:tests/test_m2b_stage6.sh > /tmp/pre/... \
#   && GATE_SRC=/tmp/pre tests/test_build_gate_status.sh   # must FAIL
GATE_SRC="${GATE_SRC:-$REPO/tests}"
cp "$GATE_SRC/test_m2b_stage6.sh"      "$R/tests/"
cp "$GATE_SRC/test_m2a_stage4_code.sh" "$R/tests/"
cp "$REPO/tests/lib/m2a_common.sh"     "$R/tests/lib/"
# 14z-97: m2a_common.sh sources the shared §4 comparators, so the scratch
# repo needs them too — without this the copied gates die at their first
# line and this control would "pass" on a gate that never ran.
cp "$REPO/tests/lib/masked_compare.sh" "$R/tests/lib/"
chmod +x "$R/tests/test_m2b_stage6.sh" "$R/tests/test_m2a_stage4_code.sh"

# $1 = mode: reject_after_pack | die_before_pack | ok
write_stub() {
    cat > "$R/tools/build_donovan.sh" <<STUB
#!/bin/sh
set -eu
OUT="\$2"
case "$1" in
  reject_after_pack)
      # packs, THEN rejects — build_donovan.sh's real ordering
      mkdir -p "\$OUT/rompath"; : > "\$OUT/rompath/vsavj.zip"
      echo "packed \$OUT/rompath"
      echo "BUILD REJECTED: member-identity audit failed (above)." >&2
      exit 1 ;;
  die_before_pack)
      echo "generator error" >&2
      exit 1 ;;
  ok)
      mkdir -p "\$OUT/rompath"; : > "\$OUT/rompath/vsavj.zip"
      echo "packed \$OUT/rompath"
      exit 0 ;;
esac
STUB
    chmod +x "$R/tools/build_donovan.sh"
}

# run_gate <gate> <mode> <outbase>  -> sets RC and OUT_TXT
run_gate() {
    write_stub "$2"
    set +e
    OUT_TXT="$(cd "$R" && ROMDIR="$WORK/romdir" "$R/tests/$1" "$3" 2>&1)"
    RC=$?
    set -e
}

# THE DISCRIMINATING ASSERTION. Exit status alone is NOT enough here: in this
# scratch repo the post-build stages die anyway (no run_replay_guarded.sh), so
# a pre-fix gate also exits non-zero and a status-only check would pass on the
# BROKEN code. What separates fixed from broken is whether the gate proceeds
# to measure an artifact it should have refused. Measured on the pre-fix tree:
# exit 1, but "guarded soaks" REACHED. So assert on the marker.
# assert_stopped <marker> <label>
assert_stopped() {
    if echo "$OUT_TXT" | grep -q "$1"; then
        echo "FAIL: gate reached '$1' after a failed build ($2)"; fail=1
    else
        echo "  ok: gate stopped before '$1'"
    fi
}
SOAK_MARK="guarded soaks"
S4_MARK="bare-long veto fact-lock"

# --- 1. rejected after packing: the artifact exists and is REJECTED ------
echo "== 1. build rejects itself after packing =="
run_gate test_m2b_stage6.sh reject_after_pack "$WORK/o1"
if [ "$RC" != 0 ]; then echo "  ok: gate exited $RC"
else echo "FAIL: gate exited 0 on a rejected build"; fail=1; fi
if echo "$OUT_TXT" | grep -q "^PASS:"; then
    echo "FAIL: gate printed PASS on a rejected build"; fail=1
else echo "  ok: no PASS verdict printed"; fi
assert_stopped "$SOAK_MARK" "rejected after packing"

# --- 2. died before the pack, a STALE rompath is present ----------------
echo "== 2. build dies early, previous rompath still on disk =="
mkdir -p "$WORK/o2/rompath"; : > "$WORK/o2/rompath/vsavj.zip"
run_gate test_m2b_stage6.sh die_before_pack "$WORK/o2"
if [ "$RC" != 0 ]; then echo "  ok: gate exited $RC, refused the stale artifact"
else echo "FAIL: gate validated a stale rompath and exited 0"; fail=1; fi
assert_stopped "$SOAK_MARK" "stale rompath"

# --- 3. died before the pack, FRESH outbase (no rompath at all) ---------
# The dangerous one: without an existence check the gate proceeds and
# run_mame.sh resolves the pristine set out of $ROMDIR.
echo "== 3. build dies early, no rompath at all =="
run_gate test_m2b_stage6.sh die_before_pack "$WORK/o3"
if [ "$RC" != 0 ]; then echo "  ok: gate exited $RC"
else echo "FAIL: gate exited 0 with no build to measure"; fail=1; fi
if echo "$OUT_TXT" | grep -q "guarded soaks"; then
    echo "FAIL: gate reached the soak stage with no rompath (would measure vanilla)"
    fail=1
else echo "  ok: gate stopped before soaking"; fi

# --- 4. POSITIVE CONTROL: a good build must get PAST the build guard ----
# Without this, a gate that aborts unconditionally would pass 1-3.
echo "== 4. positive control: a successful build proceeds =="
run_gate test_m2b_stage6.sh ok "$WORK/o4"
if echo "$OUT_TXT" | grep -q "guarded soaks"; then
    echo "  ok: gate proceeded past the build step"
else
    echo "FAIL: gate did not reach the soak stage on a SUCCESSFUL build"
    echo "$OUT_TXT" | tail -5
    fail=1
fi

# --- 5. the sibling stage-4 gate carries the same regression ------------
echo "== 5. stage-4 gate, rejected after packing =="
run_gate test_m2a_stage4_code.sh reject_after_pack "$WORK/o5"
if [ "$RC" != 0 ]; then echo "  ok: gate exited $RC"
else echo "FAIL: stage-4 gate exited 0 on a rejected build"; fail=1; fi
assert_stopped "$S4_MARK" "stage-4, rejected after packing"

[ "$fail" = 0 ] && echo "PASS: build-gate exit-status propagation (3 failure modes + positive control + sibling gate)" \
    || { echo "FAIL: build-gate exit-status propagation"; exit 1; }
