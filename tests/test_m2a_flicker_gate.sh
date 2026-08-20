#!/bin/sh
# test_m2a_flicker_gate.sh — ground truth for the M2 battery's masked legacy
# gate (`m2a_legacy_gate_masked`). ROM-free: the emulator is stubbed and the
# logs are crafted from the real frozen basis.
#
# REWRITTEN 14z-97 (GitHub #96) — AND THE PREDICATE IT USED TO LOCK IS NOW
# THE OPPOSITE. Read this before "fixing" case 2 back.
#
# The original (14z-90, GitHub #2) locked "fail on GROWTH, ADVISE on shrink",
# on an explicit premise:
#
#     Frozen inventories legitimately MOVE between builds on the same track
#     (donovan-m2b 08_challenger_join -> 2 3507,3807; donovan-m2c -> 1 3507)
#     and this helper gates UNFROZEN dev builds. Pinning one build's numbers
#     would turn a permissive gate into a false-RED one.
#
# That premise was retired by the maintainer's ruling of 2026-08-19 (option
# (a)): the battery now asserts that the pipeline, built fresh, reproduces
# the CURRENT FROZEN generation, and its target is resolved from the build's
# own fingerprint. Against a frozen target a shrink is not benign — it means
# the fresh build is not the frozen one — so drift in EITHER direction is a
# loud failure, and the comparison is the same one run_suite.sh applies.
#
# What is locked here, then:
#   1. growth  -> FAIL   (the standing watch's case, unchanged)
#   2. shrink  -> FAIL   (NEW; it used to be an advisory "ok:")
#   3. exact match of the frozen inventory -> pass
#   4. a required replay with no spec in the set -> FAIL, not a quiet skip
#   5. an unresolvable target -> FAIL naming rule 6, never a pass
#
# Usage: tests/test_m2a_flicker_gate.sh   (no ROMs, no emulator, ~3s)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# A real replay, a real set, a real basis: the specs under test are the ones
# the battery actually enforces, not a fixture that can drift away from them.
RPL=03_two_player_vs
SET=donovan-m9-stock   # re-pointed 14z-99 (window freeze carry-rename)
SPEC="$REPO/tests/expected/$SET/$RPL.masked"
[ -f "$SPEC" ] || { echo "FAIL: no frozen spec at $SPEC"; exit 1; }
BASE=$(awk '{print $2}' "$SPEC")
BASIS="$REPO/tests/expected/$BASE/logs/$RPL.log"
[ -f "$BASIS" ] || { echo "FAIL: no frozen basis log at $BASIS"; exit 1; }
FROZEN=$(awk '{ for (i = 3; i <= NF; i++) printf "%s%s", $i, (i<NF?" ":"") }' "$SPEC")
echo "spec under test: $SET/$RPL -> $(cat "$SPEC")"
echo "frozen inventory: $FROZEN"

# mkflip <out> <frames...> — the basis with those frames' hashes flipped
mkflip() {
    _o="$1"; shift
    FR="$*" python3 - "$BASIS" "$_o" <<'PY'
import os, sys
bad = set(os.environ["FR"].split())
out = []
for line in open(sys.argv[1]):
    f = line.split()
    if len(f) >= 2 and f[0] in bad:
        out.append(f"{f[0]} ffffffffffffffff")
    else:
        out.append(line.rstrip("\n"))
open(sys.argv[2], "w").write("\n".join(out) + "\n")
PY
}

# run_gate <injected-log> [required-list] -> the gate's line(s) for $RPL
run_gate() {
    cp "$1" "$WORK/injected.log"
    _req="${2:-$RPL}"
    OUT=$(
        REPO="$REPO"
        . "$REPO/tests/lib/m2a_common.sh"
        M2A_EXPSET="$SET"
        M2A_MASKED_REQUIRED="$_req"
        # stub the emulator: hand the gate the log under test
        m2a_run_masked() {
            cp "$WORK/injected.log" "$3"
        }
        m2a_legacy_gate_masked "unused-rompath" "$WORK" 2>&1 || true
    )
    printf '%s\n' "$OUT"
}

want() {   # want <label> <pattern> <output>
    if printf '%s' "$3" | grep -q "$2"; then
        echo "  ok: $1"
    else
        echo "FAIL: $1 — expected output matching '$2'"
        printf '%s\n' "$3" | sed 's/^/        /' | head -6
        fail=1
    fi
}
notwant() {
    if printf '%s' "$3" | grep -q "$2"; then
        echo "FAIL: $1 — output must NOT match '$2'"
        printf '%s\n' "$3" | sed 's/^/        /' | head -6
        fail=1
    else
        echo "  ok: $1"
    fi
}

echo "== 1. inventory GROWS (the standing watch's case) =="
mkflip "$WORK/grown.log" 2093 3500
got=$(run_gate "$WORK/grown.log")
want "growth is a loud FAIL" "FAIL: $RPL" "$got"

echo "== 2. inventory SHRINKS — a FAIL since 14z-97, an advisory before =="
cp "$BASIS" "$WORK/shrunk.log"          # bit-identical: the inventory vanished
got=$(run_gate "$WORK/shrunk.log")
want "a vanished divergence is a FAIL" "FAIL: $RPL" "$got"
notwant "and it is not reported as ok:" "ok: $RPL" "$got"

echo "== 3. the frozen inventory itself passes =="
mkflip "$WORK/exactly.log" 2093
got=$(run_gate "$WORK/exactly.log")
want "the frozen shape passes" "ok: $RPL" "$got"
notwant "with no FAIL line" "FAIL: $RPL" "$got"

echo "== 4. a required replay with no spec is a FAIL, not a quiet skip =="
got=$(run_gate "$WORK/exactly.log" "$RPL 99_no_such_replay")
want "the missing spec is named" "no spec for 99_no_such_replay" "$got"

echo "== 5. an unresolvable target names rule 6 and never passes =="
OUT=$(
    REPO="$REPO"
    . "$REPO/tests/lib/m2a_common.sh"
    M2A_MASKED_REQUIRED="$RPL"
    m2a_masked_target() { echo ""; }       # as if the fingerprint were unknown
    m2a_run_masked() { : > "$3"; }
    m2a_legacy_gate_masked "unused-rompath" "$WORK" 2>&1 || true
    echo "gate_fail=$gate_fail"
)
want "the message names rule 6" "rule 6" "$OUT"
want "and the gate fails"       "gate_fail=1" "$OUT"
notwant "and it does not pin a set name to get past it" "ok: $RPL" "$OUT"

echo
[ "$fail" = 0 ] && echo "PASS: the battery's masked gate is loud in both directions" \
                || { echo "FAIL: see above"; exit 1; }
