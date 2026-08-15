#!/bin/sh
# test_describe_masked_shape.sh — ground truth for tools/describe_masked_shape.py,
# the classifier that turns a measured masked divergence into a PROPOSED
# expectation line in the ratified §4 vocabulary.
#
# WHY IT NEEDS ITS OWN TEST (14z-89). This code used to live as a heredoc
# inside tests/audit_merged_legacy.sh, where nothing exercised it except the
# failure path of a ~45-minute audit — i.e. it was only ever run when
# something else was already wrong. It now has two callers (the merged audit
# and the legacy-pairing promotion), and its output is COPIED INTO EXPECTATION
# FILES by hand. A classifier that proposes a slightly wrong window bound
# would freeze a slightly wrong expectation, which is the quiet kind of
# harness bug this project has paid for before (CLAUDE.md §4: "verdict logic
# is itself tested").
#
# The thresholds under test are the comparators' own and must stay in step:
#   run length <= 2 is a FLICKER frame   (tools/compare_composite.py FLICKER_MAX)
#   >= 60 identical frames after the last divergence = RE-CONVERGED
# Sections 1-6 pin one branch each; section 7 is the boundary pair that
# catches an off-by-one in either threshold.
#
# Static, no emulator, no ROMs, ~1 s.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
D="python3 $REPO/tools/describe_masked_shape.py"
fail=0

# gen <file> <nframes> <divergent-frame-list...> — a checksum log whose named
# frames differ from the base (same format replay.lua writes: "<frame> <hex>").
gen() {
    _f="$1"; _n="$2"; shift 2
    _bad=" $* "
    : > "$_f"
    _i=1
    while [ "$_i" -le "$_n" ]; do
        case "$_bad" in
        *" $_i "*) printf '%d ffffffffffffffff\n' "$_i" >> "$_f" ;;
        *)         printf '%d 0000000000000000\n' "$_i" >> "$_f" ;;
        esac
        _i=$((_i + 1))
    done
    printf 'END %d\n' "$_n" >> "$_f"
}
want() {  # $1 label  $2 base  $3 new  $4 expected "proposed:" line
    got="$($D "$2" "$3" | sed -n 's/^proposed: //p')"
    if [ "$got" = "$4" ]; then
        echo "  ok $1: $got"
    else
        echo "  FAIL $1"; echo "      want: $4"; echo "      got : $got"; fail=1
    fi
}

gen "$W/base" 500
echo "== 1: bit-identical -> exact =="
cp "$W/base" "$W/same"
want identical "$W/base" "$W/same" "exact vsavj/masked-v2 -"

echo "== 2: isolated short runs only -> flicker (the frozen inventory) =="
gen "$W/flick" 500 100 101 300
want flicker "$W/base" "$W/flick" "flicker vsavj/masked-v2 3 100,101,300"

echo "== 3: one long contiguous run, re-converging -> window =="
gen "$W/win" 500 200 201 202 203 204 205
want window "$W/base" "$W/win" "window vsavj/masked-v2 200 205"

echo "== 4: long run + short runs -> composite (the 2P legacy shape) =="
gen "$W/comp" 500 100 200 201 202 203
want composite "$W/base" "$W/comp" "composite vsavj/masked-v2 100 200-203"

echo "== 5: two long runs, no flicker -> composite with an empty flicker list =="
gen "$W/two" 500 100 101 102 103 200 201 202 203
want two-windows "$W/base" "$W/two" "composite vsavj/masked-v2 - 100-103;200-203"

echo "== 6: THE REPLAY-38 SIGNATURE — never re-converges -> NOT expressible =="
# a divergence that runs to the end of the log is a superset-invariant
# failure, not a class: it must be refused, never proposed as a wide window.
gen "$W/perm" 500 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 \
    415 416 417 418 419 420 421 422 423 424 425 426 427 428 429 430 431 432 \
    433 434 435 436 437 438 439 440 441 442 443 444 445 446 447 448 449 450 \
    451 452 453 454 455 456 457 458 459 460 461 462 463 464 465 466 467 468 \
    469 470 471 472 473 474 475 476 477 478 479 480 481 482 483 484 485 486 \
    487 488 489 490 491 492 493 494 495 496 497 498 499 500
if $D "$W/base" "$W/perm" | grep -q "^proposed: NONE"; then
    echo "  ok non-re-convergent: refused, named for root-causing"
else
    echo "  FAIL: a never-re-converging divergence was given a class"; fail=1
fi

echo "== 7: threshold boundaries (an off-by-one in either is caught here) =="
# 7a. a 2-frame run is a flicker; a 3-frame run is a window.
gen "$W/b2" 500 100 101
want "flicker-max (2 frames)" "$W/base" "$W/b2" "flicker vsavj/masked-v2 2 100,101"
gen "$W/b3" 500 100 101 102
want "flicker-max+1 (3 frames)" "$W/base" "$W/b3" "window vsavj/masked-v2 100 102"
# 7b. exactly 60 identical frames after the run is NOT enough (tail > 60);
#     61 is. This is the clause that separates "re-converged" from "ended".
gen "$W/t60" 500 438 439 440        # frames 441..500 identical = tail exactly 60
if $D "$W/base" "$W/t60" | grep -q "^proposed: NONE"; then
    echo "  ok reconverge floor: a 60-frame tail is refused"
else
    echo "  FAIL: a 60-frame tail was accepted as re-convergence"; fail=1
fi
gen "$W/t61" 500 437 438 439        # frames 440..500 identical = tail 61
want "reconverge floor+1" "$W/base" "$W/t61" "window vsavj/masked-v2 437 439"

echo "== 8: a shorter log is reported, never silently truncated =="
gen "$W/short" 300
if $D "$W/base" "$W/short" | grep -q "LENGTH MISMATCH 500 vs 300"; then
    echo "  ok length mismatch named"
else
    echo "  FAIL: a truncated run was compared without saying so"; fail=1
fi

[ "$fail" = 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
