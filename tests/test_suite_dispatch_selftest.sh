#!/bin/sh
# test_suite_dispatch_selftest.sh — ground truth for the kind->owner table in
# tests/test_suite_dispatch.sh (14z-90, GitHub issue #7).
#
# WHY. test_suite_dispatch.sh is the structural guard that stops an expectation
# kind from existing on disk with nobody reading it. It used to demand that
# EVERY kind be handled by run_suite.sh, which made it go RED on the
# `.legacy-exempt` markers that record the maintainer's 61/62 ruling and are
# read by tests/audit_legacy_pairings.sh. The repair names an owner per kind.
#
# A repair to a gate is worthless unless the repaired gate can still FAIL, and
# the obvious cheap fix here (loosen the check to "somebody reads it") would
# have looked identical while destroying the guard. So this asserts the two
# ways the table must break, per CLAUDE.md §4 "verdict logic is itself tested":
#
#   1. a kind on disk that is ABSENT from the table          -> RED
#   2. a kind whose NAMED OWNER no longer reads it           -> RED
#      (the old check could not express #2 at all: it only ever grepped
#       run_suite.sh, so an orphaned marker was invisible)
#   3. a row claiming battery-chain coverage it does not have -> RED
#
# Control 1 plants a real fixture and removes it again. Controls 2 and 3 run a
# scratch COPY of the gate with the table rewritten — deliberately NOT an env
# override, because a policy table that an env var can replace is a gate an
# operator can silently switch off.
#
# Usage: ROMDIR=... tests/test_suite_dispatch_selftest.sh   (no emulator, ~10s)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-90 (issue #7): ground truth for the kind->owner table in
#   tests/test_suite_dispatch.sh. Three negative controls: an unlisted kind,
#   an owner that no longer reads its kind, and a false battery-chain claim —
#   each must turn the gate RED and name the reason. ROMDIR, no emulator, ~10s
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

GATE="tests/test_suite_dispatch.sh"
FIXTURE=""
COPY=""
cleanup() { [ -n "$FIXTURE" ] && rm -f "$FIXTURE"; [ -n "$COPY" ] && rm -f "$COPY"; :; }
trap cleanup EXIT

fail=0

# --- 0. baseline: the gate is green on a clean tree ----------------------
echo "== 0. baseline =="
if "$REPO/$GATE" >/dev/null 2>&1; then
    echo "  ok: gate passes on a clean tree"
else
    echo "FAIL: gate is RED before any fixture is planted — fix that first"
    fail=1
fi

# --- 1. an unknown kind must go RED -------------------------------------
# The fixture has to clear BOTH harvest filters: the stem must be a real
# replay, and the extension must not be sha1. A bare `touch junk.bogus`
# would be skipped and would prove nothing.
echo "== 1. unknown kind =="
STEM=03_two_player_vs
[ -f "$REPO/tests/replays/$STEM.rpl" ] || { echo "FAIL: fixture stem $STEM is not a replay"; exit 1; }
FIXTURE="$REPO/tests/expected/vsavj/$STEM.bogus"
[ -e "$FIXTURE" ] && { echo "FAIL: $FIXTURE already exists — refusing to clobber"; exit 1; }
echo "planted by test_suite_dispatch_selftest.sh" > "$FIXTURE"
set +e; out=$("$REPO/$GATE" 2>&1); rc=$?; set -e
if [ "$rc" != 0 ] && echo "$out" | grep -q "not in the owner table"; then
    echo "  ok: unlisted kind '.bogus' -> RED, named"
else
    echo "FAIL: an unlisted expectation kind did not turn the gate RED (rc=$rc)"
    fail=1
fi
rm -f "$FIXTURE"; FIXTURE=""

# --- 2. a named owner that no longer reads its kind must go RED ---------
# The copy lives inside tests/ so the gate's REPO=$0/.. still resolves.
echo "== 2. owner no longer reads its kind =="
COPY="$REPO/tests/.selftest_dispatch_copy.sh"
# NB: unanchored. The table's last row carries the closing quote of the
# KIND_OWNERS string, so a `$`-anchored pattern silently matches nothing —
# which this control caught on its first run.
sed 's|legacy-exempt:tests/audit_legacy_pairings.sh:toplevel|legacy-exempt:tests/run_suite.sh:toplevel|' \
    "$REPO/$GATE" > "$COPY"
chmod +x "$COPY"
if ! grep -q "legacy-exempt:tests/run_suite.sh" "$COPY"; then
    echo "FAIL: could not rewrite the owner row — the table format moved"; fail=1
fi
set +e; out=$("$COPY" 2>&1); rc=$?; set -e
if [ "$rc" != 0 ] && echo "$out" | grep -q "never reads the kind"; then
    echo "  ok: owner that does not read its kind -> RED, named"
else
    echo "FAIL: a wrong owner did not turn the gate RED (rc=$rc)"
    fail=1
fi

# --- 3. a false battery-chain claim must go RED -------------------------
echo "== 3. false run-chain claim =="
sed 's|legacy-exempt:tests/audit_legacy_pairings.sh:toplevel|legacy-exempt:tests/audit_legacy_pairings.sh:battery|' \
    "$REPO/$GATE" > "$COPY"
grep -q "audit_legacy_pairings.sh:battery" "$COPY" || {
    echo "FAIL: could not rewrite the chain field — the table format moved"; fail=1; }
chmod +x "$COPY"
set +e; out=$("$COPY" 2>&1); rc=$?; set -e
if [ "$rc" != 0 ] && echo "$out" | grep -q "never invokes it"; then
    echo "  ok: unearned battery-chain claim -> RED, named"
else
    echo "FAIL: a false run-chain claim did not turn the gate RED (rc=$rc)"
    fail=1
fi
rm -f "$COPY"; COPY=""

# --- 4. the fixture left nothing behind ---------------------------------
echo "== 4. cleanliness =="
if [ -e "$REPO/tests/expected/vsavj/$STEM.bogus" ] \
   || [ -e "$REPO/tests/.selftest_dispatch_copy.sh" ]; then
    echo "FAIL: self-test left a fixture behind"; fail=1
else
    echo "  ok: no fixtures left in the tree"
fi

[ "$fail" = 0 ] && echo "PASS: dispatch kind->owner table ground truth (3 negative controls + baseline)" \
    || { echo "FAIL: dispatch kind->owner table"; exit 1; }
