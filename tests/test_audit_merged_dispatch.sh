#!/bin/sh
# test_audit_merged_dispatch.sh — ground truth for the expectation enumeration
# that tests/audit_merged_legacy.sh now runs before its leg-(a) glob
# (14z-90, GitHub issue #17).
#
# WHY. That audit evaluated `*.masked` only. `.pending` marks a legacy pairing
# with no ratified class in ANY set — the exact state the audit exists to
# detect — so the two dropped replays put its blind spot over the project's one
# open superset-invariant regression: 43 of 45 pairings measured, gap reported
# nowhere, header claiming 47.
#
# ROM-free and emulator-free ON PURPOSE. The audit itself takes ~2 h and needs
# ROMs and MAME; a control that required that would never be run, and this is
# the check that must run every time the expectation directory changes. It
# deliberately does NOT extend tests/test_suite_dispatch.sh, which hard-requires
# ROMDIR and runs patch_prg/pack_build in its earlier sections.
#
# Usage: tests/test_audit_merged_dispatch.sh   (no ROMs, no emulator, ~1s)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/enumerate_expectations.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# --- 1. every kind is dispatched, and unknown kinds are loud -------------
echo "== 1. synthetic fixture, one of each kind =="
F="$WORK/expect"; mkdir -p "$F" "$WORK/repo/tests/replays"
for s in aa_masked bb_skip cc_sha1 dd_pending ee_bogus; do
    : > "$WORK/repo/tests/replays/$s.rpl"
done
echo "composite vsavj/masked-v2 829 889-1802" > "$F/aa_masked.masked"
echo "reason"                                  > "$F/bb_skip.skip"
echo "deadbeef"                                > "$F/cc_sha1.sha1"
echo "shape: does not re-converge"             > "$F/dd_pending.pending"
echo "junk"                                    > "$F/ee_bogus.bogus"
# a file whose stem is NOT a replay must be ignored entirely
echo "x" > "$F/not_a_replay.masked"
set +e; got=$(enumerate_expectations "$F" "$WORK/repo"); rc=$?; set -e
for want in "aa_masked|masked|EVAL" "bb_skip|skip|SKIP" "cc_sha1|sha1|N/A" \
            "dd_pending|pending|NOT-EVALUATED" "ee_bogus|bogus|UNKNOWN-KIND"; do
    if printf '%s\n' "$got" | grep -qx "$want"; then
        echo "  ok: $want"
    else
        echo "FAIL: missing dispatch line '$want'"; fail=1
    fi
done
if printf '%s\n' "$got" | grep -q "not_a_replay"; then
    echo "FAIL: a file whose stem is not a replay was enumerated"; fail=1
else
    echo "  ok: non-replay files ignored"
fi
[ "$rc" != 0 ] && echo "  ok: pending/unknown make it return $rc" \
    || { echo "FAIL: pending and unknown kinds did not fail the enumeration"; fail=1; }

# --- 2. accounting: nothing may vanish silently -------------------------
echo "== 2. every eligible file produces exactly one line =="
want_n=$(ls "$F" | wc -l | tr -d ' ')
want_n=$((want_n - 1))          # not_a_replay.masked is correctly excluded
got_n=$(printf '%s\n' "$got" | grep -c '|')
if [ "$got_n" = "$want_n" ]; then
    echo "  ok: $got_n lines for $want_n eligible files"
else
    echo "FAIL: $got_n lines for $want_n eligible files — a kind vanished"; fail=1
fi

# --- 3. THE NEGATIVE CONTROL, red on the real tree today -----------------
# donovan-m5 carries exactly two .pending. If this ever returns 0, either the
# regression was fixed and the classes ratified (delete this case with the
# re-freeze) or the enumeration stopped seeing them.
echo "== 3. the real donovan-m5 set names its unevaluated pairings =="
set +e; real=$(enumerate_expectations "$REPO/tests/expected/donovan-m5" "$REPO"); rrc=$?; set -e
np=$(printf '%s\n' "$real" | grep -c "NOT-EVALUATED" || true)
if [ "$np" = 2 ] && [ "$rrc" != 0 ]; then
    echo "  ok: 2 NOT-EVALUATED, enumeration returns $rrc"
    printf '%s\n' "$real" | grep "NOT-EVALUATED" | sed 's/^/      /'
else
    echo "FAIL: expected exactly 2 NOT-EVALUATED and a non-zero return,"
    echo "      got $np and rc=$rrc. If the .pending replays were ratified,"
    echo "      update this case in the same commit as the re-freeze."
    fail=1
fi

# --- 4. no-loophole: a clean directory must PASS ------------------------
# Without this, an enumeration that always failed would satisfy cases 1 and 3.
echo "== 4. no-loophole: a set with no .pending returns 0 =="
rm -f "$F/dd_pending.pending" "$F/ee_bogus.bogus"
set +e; clean=$(enumerate_expectations "$F" "$WORK/repo"); crc=$?; set -e
if [ "$crc" = 0 ] && ! printf '%s\n' "$clean" | grep -q "NOT-EVALUATED"; then
    echo "  ok: a fully ratified set passes cleanly"
else
    echo "FAIL: a clean set did not return 0 (rc=$crc)"; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: merged-audit expectation enumeration (4 cases incl. the live 2-pending control)" \
    || { echo "FAIL: merged-audit expectation enumeration"; exit 1; }
