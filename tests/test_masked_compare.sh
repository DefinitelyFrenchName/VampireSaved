#!/bin/sh
# test_masked_compare.sh — ground truth for tests/lib/masked_compare.sh, the
# ONE implementation of the CLAUDE.md §4 masked comparison vocabulary
# (14z-97, GitHub #96).
#
# WHY. The vocabulary used to live inline in run_suite.sh, where its only
# proof was the corpus itself: if a class was subtly wrong, the way you found
# out was a wrong verdict on a real build. Lifting it out for the M2 battery
# made it a library with two callers, and CLAUDE.md §4 is explicit that
# verdict logic is itself tested — this project has already shipped one wrong
# conclusion from a verdict bug rather than a game bug (the SMS "blockable
# frame trap").
#
# It paid for itself immediately. `check_diverge.py` derives the base log
# from the SPEC FILE'S STEM, so the lifted `diverge` branch — which wrote its
# temp spec to a fixed name — sent every diverge expectation looking for
# `logs/spec.log` and would have reported NO-BASE-LOG on 01_attract_long and
# 11_pick_donovan the moment the battery ran. Case "diverge at the frozen
# frame" below is that regression lock.
#
# Each class is exercised in BOTH directions: the shape it exists to accept,
# and at least one laxer shape it must reject. The per-comparator ground
# truths (test_compare_window.sh, test_compare_composite.sh,
# test_m2a_flicker_gate.sh's successor) prove the checkers; this proves the
# DISPATCH — that a spec line selects the right checker, passes it the right
# arguments, and turns its result into the right verdict.
#
# Usage: tests/test_masked_compare.sh   (no emulator, no ROMDIR, ~2s)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-97 (#96): ground truth for tests/lib/masked_compare.sh, the ONE
#   implementation of the §4 vocabulary
#   (exact/flicker/diverge/window/composite + the #62 baseset/mask guard) now
#   shared by run_suite.sh and the M2 battery. Every class in both directions;
#   it caught a real bug in the lift (the diverge spec's temp-file STEM). No
#   ROMs, no emulator, ~2s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/masked_compare.sh"
W="$(mktemp -d)"           # GitHub #68: not a predictable name
trap 'rm -rf "$W"' EXIT
fail=0

MASKSTR="043c-043d,7f00-8000"
ROOT="$W/expected"
mkdir -p "$ROOT/basis/logs" "$ROOT/theset"
printf '%s\n' "$MASKSTR" > "$ROOT/basis/MASK"
printf '%s\n' "$MASKSTR" > "$ROOT/theset/mask"

# mk <file> <divergent frames...> — 400 frames; the listed ones differ.
# Same generator shape as tests/test_compare_window.sh.
mk() {
    _f="$1"; shift
    _d=" $* "
    i=1
    : > "$_f"
    while [ "$i" -le 400 ]; do
        case "$_d" in
            *" $i "*) printf '%d %s\n' "$i" "ffffffffffffffff" >> "$_f" ;;
            *)        printf '%d %s\n' "$i" "0000000000000000" >> "$_f" ;;
        esac
        i=$((i + 1))
    done
    echo "END 400" >> "$_f"
}

mkrange() {   # mkrange <file> <lo> <hi> [extra frames...]
    _f="$1"; _lo="$2"; _hi="$3"; shift 3
    _x=" $* "
    i=1
    : > "$_f"
    while [ "$i" -le 400 ]; do
        if [ "$i" -ge "$_lo" ] && [ "$i" -le "$_hi" ]; then
            printf '%d %s\n' "$i" "ffffffffffffffff" >> "$_f"
        else
            case "$_x" in
                *" $i "*) printf '%d %s\n' "$i" "ffffffffffffffff" >> "$_f" ;;
                *)        printf '%d %s\n' "$i" "0000000000000000" >> "$_f" ;;
            esac
        fi
        i=$((i + 1))
    done
    echo "END 400" >> "$_f"
}

# check <label> <want-rc> <name> <spec> <runmask> <log> [want-substring]
check() {
    _l="$1"; _w="$2"; _n="$3"; _s="$4"; _m="$5"; _lg="$6"; _want="${7:-}"
    if out=$(masked_check "$ROOT/theset" "$_n" "$_s" "$_m" "$_lg" 2>&1); then
        _rc=0
    else
        _rc=$?
    fi
    if [ "$_rc" != "$_w" ]; then
        echo "  FAIL  $_l (rc=$_rc want $_w)"
        printf '%s\n' "$out" | sed 's/^/        /'
        fail=1
        return
    fi
    if [ -n "$_want" ] && ! printf '%s' "$out" | grep -q "$_want"; then
        echo "  FAIL  $_l (rc ok, but the verdict did not mention '$_want')"
        printf '%s\n' "$out" | sed 's/^/        /'
        fail=1
        return
    fi
    echo "  PASS  $_l"
}

# --- the logs ---------------------------------------------------------------
mk       "$ROOT/basis/logs/case.log"                    # base: all identical
mk       "$W/same"                                      # identical to base
mk       "$W/onebyte" 7                                 # differs at 7
# 60 frames apart at least: compare_flicker requires min-converge 60 BETWEEN
# runs as well as after the last one. (composite does not — §4 v5 rules the
# figure INTRA-mechanism — which is why the composite case below spaces its
# window and flicker only 49 apart and still passes.)
mk       "$W/flick" 100 200                             # two isolated frames
mk       "$W/flick3" 100 200 300                        # a third frame
mkrange  "$W/window" 100 104                            # one contiguous run
mkrange  "$W/comp"   100 150 200                        # window + one flicker
mkrange  "$W/comp2"  100 150 200 300                    # ...plus a stray
mkrange  "$W/late"   42 400                             # diverges at 42, stays
mkrange  "$W/early"  10 400                             # diverges at 10

echo "== exact =="
check "bit-identical passes"                 0 case "exact basis -" "$MASKSTR" "$W/same"     "PASS masked-exact"
check "one differing byte fails"             1 case "exact basis -" "$MASKSTR" "$W/onebyte"  "FAIL masked live-state"

echo "== flicker (frozen inventory, drift either way is loud) =="
check "the frozen inventory passes"          0 case "flicker basis 2 100,200" "$MASKSTR" "$W/flick"  "PASS masked-flicker"
check "a GROWN inventory fails"              1 case "flicker basis 2 100,200" "$MASKSTR" "$W/flick3" "FAIL masked-flicker"
# 14z-97: the battery's old predicate advised on shrink and failed only on
# growth, because it ran on unfrozen dev builds. Its target is a FROZEN
# generation now, so a shrink means the fresh build is not the frozen one.
check "a SHRUNK inventory fails too"         1 case "flicker basis 2 100,200" "$MASKSTR" "$W/onebyte" "FAIL masked-flicker"
check "bit-identical is not a silent pass"   1 case "flicker basis 2 100,200" "$MASKSTR" "$W/same"    "FAIL masked-flicker"

echo "== diverge (the regression lock for the spec-stem bug) =="
check "divergence at the frozen frame"       0 case "diverge basis 42" "$MASKSTR" "$W/late"  "PASS"
check "an EARLIER onset fails"               1 case "diverge basis 42" "$MASKSTR" "$W/early"
check "no divergence at all fails"           1 case "diverge basis 42" "$MASKSTR" "$W/same"
# The bug this file was written by: a spec temp-file not named for the replay
# makes check_diverge look for logs/<wrong>.log. A NO-BASE-LOG verdict must
# never be mistaken for a pass, and must not be what a healthy build prints.
if masked_check "$ROOT/theset" case "diverge basis 42" "$MASKSTR" "$W/late" \
       | grep -q "NO-BASE-LOG"; then
    echo "  FAIL  a healthy diverge spec printed NO-BASE-LOG (the stem bug is back)"
    fail=1
else
    echo "  PASS  a healthy diverge spec finds its base log"
fi

echo "== window =="
check "one contiguous run at the frozen onset" 0 case "window basis 100 104" "$MASKSTR" "$W/window" "PASS masked-window"
check "a drifting onset fails"                 1 case "window basis 110 114" "$MASKSTR" "$W/window"
check "bit-identical FAILS (the class asserts the divergence exists)" \
                                               1 case "window basis 100 104" "$MASKSTR" "$W/same"

echo "== composite (strict conjunction; adds no tolerance) =="
check "frozen flicker + frozen window passes" 0 case "composite basis 200 100-150" "$MASKSTR" "$W/comp"  "PASS masked-composite"
check "an unaccounted extra run fails"        1 case "composite basis 200 100-150" "$MASKSTR" "$W/comp2"
check "bit-identical fails"                   1 case "composite basis 200 100-150" "$MASKSTR" "$W/same"

echo "== the baseset/mask invariant (GitHub #62) =="
check "a set running a DIFFERENT mask than its basis is refused" \
    1 case "exact basis -" "043c-043d,dead-beef,7f00-8000" "$W/same" "mask mismatch"
# A basis with no MASK record is the v1 one; a set that overrides the default
# and cites it is the untracked pairing, and must be refused rather than
# silently compared over two different byte sets.
mkdir -p "$ROOT/oldbasis/logs"
cp "$ROOT/basis/logs/case.log" "$ROOT/oldbasis/logs/case.log"
check "a record-less basis cited by a mask-carrying set is refused" \
    1 case "exact oldbasis -" "$MASKSTR" "$W/same" "no MASK record"

echo "== an unknown class is a failure, not a skip =="
check "unknown class"                        1 case "sortof basis -" "$MASKSTR" "$W/same" "unknown .masked class"

echo "== masked_mask_for =="
if [ "$(masked_mask_for "$ROOT/theset")" = "$MASKSTR" ]; then
    echo "  PASS  a set with a mask file reports it"
else
    echo "  FAIL  a set with a mask file did not report it"; fail=1
fi
mkdir -p "$ROOT/nomask"
if [ "$(masked_mask_for "$ROOT/nomask")" = "$MASKED_DEFAULT_MASK" ]; then
    echo "  PASS  a set without one falls back to the V1 default"
else
    echo "  FAIL  the V1 fallback moved"; fail=1
fi

echo
[ "$fail" = 0 ] && echo "PASS: masked_compare dispatch validated" \
                || { echo "FAIL: see above"; exit 1; }
