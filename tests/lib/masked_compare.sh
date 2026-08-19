# masked_compare.sh — THE ONE implementation of the CLAUDE.md §4 masked
# comparison vocabulary. Source from a test; requires $REPO.
#
# Classes: exact / flicker / diverge / window / composite, plus the
# baseset-vs-mask invariant guard (GitHub #62). Everything here was lifted
# VERBATIM out of tests/run_suite.sh's dispatch (14z-97, GitHub #96) when the
# second caller appeared — the M2 battery, which the maintainer's ruling of
# 2026-08-19 re-pointed at the current frozen generation and which therefore
# needs the same vocabulary the corpus runner speaks. run_suite.sh's printed
# verdict lines are reproduced character-for-character on purpose: that made
# the extraction verifiable by diffing suite output before and after.
#
# WHY ONE COPY. The battery used to carry its own weaker comparator — flicker
# only, plus three hardcoded first-divergence constants — and it is exactly
# the "second copy of one fact" class this project keeps paying for (#70 on
# the mask string, #47/#48/#49 on geometry, wheel tables and member lists).
# A second copy does not stay a copy: it stays at the vocabulary of the day
# it was written, which is how a gate ended up asserting `flicker 1 3507`
# about a tree that has expressed that replay as a `composite` in every
# generation since donovan-m5.
#
# Callers: tests/run_suite.sh, tests/lib/m2a_common.sh.
# Ground truth: tests/test_masked_compare.sh.

# masked_mask_for <expdir> — the MASK_RANGES string an expectation set runs
# under. PER-SET OVERRIDE (14z-64): a set frozen under a different basis ships
# <set>/mask; sets without one use the round-64 V1 default (the early
# stock-track sets). Keep this in step with the comment in run_suite.sh.
MASKED_DEFAULT_MASK="043c-043d,4182-41a2,7f00-8000"
masked_mask_for() {
    if [ -f "$1/mask" ]; then cat "$1/mask"; else echo "$MASKED_DEFAULT_MASK"; fi
}

# masked_check <expdir> <name> <spec> <runmask> <log>
#   Prints the verdict line(s) run_suite.sh has always printed; returns 0 on
#   PASS, 1 on FAIL. <spec> is the contents of <expdir>/<name>.masked.
masked_check() {
    _mc_expdir="$1"; _mc_name="$2"; _mc_spec="$3"; _mc_runmask="$4"; _mc_log="$5"
    _mc_root="$(dirname "$_mc_expdir")"
    _mc_class=${_mc_spec%% *}
    _mc_rest=${_mc_spec#* }
    _mc_base=${_mc_rest%% *}
    _mc_args=${_mc_rest#* }
    _mc_baselog="$_mc_root/$_mc_base/logs/$_mc_name.log"

    # ENFORCE THE BASESET/MASK INVARIANT (14z-94, GitHub #62). It was stated
    # in prose at the top of run_suite.sh and checked nowhere: the RUN mask
    # comes from the expectation set, the BASE comes from the spec, and
    # nothing compared them. Masked bytes are SKIPPED from the checksum, so a
    # basis frozen under a different mask is not comparable — the numbers
    # would simply be over different byte sets. freeze_masked_basis.sh built
    # this guard for the WRITE side in 14z-89 ("REFUSING: $DEST is frozen
    # under a DIFFERENT mask"); this is the read side. The hazard is live,
    # not theoretical: a THIRD basis (vsavj/masked-v3, ratified and withdrawn
    # the same day, STATE 14z-88) is on disk with a different mask, and
    # retargeting a spec to it is a one-token edit.
    _mc_basemask="$_mc_root/$_mc_base/MASK"
    if [ -f "$_mc_basemask" ]; then
        if [ "$_mc_runmask" != "$(cat "$_mc_basemask")" ]; then
            echo "FAIL mask mismatch: this set runs"
            echo "        $_mc_runmask"
            echo "      but $_mc_base was frozen under"
            echo "        $(cat "$_mc_basemask")"
            echo "      Masked bytes are skipped from the checksum, so the two"
            echo "      are not comparable. Fix the spec's baseset or the set's"
            echo "      mask file — do NOT re-freeze to make this green."
            return 1
        fi
    elif [ -f "$_mc_expdir/mask" ]; then
        # A record-less basis is the v1 one, which predates the MASK record
        # (freeze_masked_basis.sh acknowledges the same gap). It is only safe
        # for sets on the BUILT-IN default; a set carrying its own mask file
        # citing it is exactly the untracked pairing.
        echo "FAIL mask mismatch: $_mc_base has no MASK record (it predates them)"
        echo "      but this set overrides the default with its own mask:"
        echo "        $_mc_runmask"
        echo "      Cite a basis with a recorded mask, or regenerate one"
        echo "      with tools/freeze_masked_basis.sh."
        return 1
    fi

    case "$_mc_class" in
    exact)
        if cmp -s "$_mc_baselog" "$_mc_log"; then
            echo "PASS masked-exact"
        else
            echo "FAIL masked live-state diverged from $_mc_base"; return 1
        fi ;;
    flicker)
        _mc_v=$(python3 "$REPO/tools/compare_flicker.py" "$_mc_baselog" "$_mc_log") || true
        if [ "$_mc_v" = "FLICKER $_mc_args" ]; then
            echo "PASS masked-flicker ($_mc_v — frozen inventory)"
        else
            echo "FAIL masked-flicker: got '$_mc_v' expected 'FLICKER $_mc_args' (frozen; drift either way is loud — CLAUDE.md §4 standing watch)"; return 1
        fi ;;
    diverge)
        # THE SPEC FILE'S NAME IS LOAD-BEARING: check_diverge.py derives the
        # base log from the spec's STEM (<root>/<baseset>/logs/<stem>.log), so
        # a temp file called anything but <replay>.mdiverge sends it looking
        # for a log that does not exist and every diverge spec reports
        # NO-BASE-LOG. run_suite.sh's inline version wrote "$WORK/$name.mdiverge"
        # for exactly this reason; caught here by tests/test_masked_compare.sh
        # while lifting the code out.
        _mc_tmp="$(mktemp -d)"
        printf '%s %s' "$_mc_base" "$_mc_args" > "$_mc_tmp/$_mc_name.mdiverge"
        _mc_out=$(python3 "$REPO/tools/check_diverge.py" "$_mc_log" \
                    "$_mc_tmp/$_mc_name.mdiverge" "$_mc_root") && _mc_rc=0 || _mc_rc=1
        rm -rf "$_mc_tmp"
        echo "$_mc_out"
        return "$_mc_rc" ;;
    window)
        # CLAUDE.md §4 v3 "bounded re-convergent window", ratified 2026-08-05
        # for the select screen the roster work extends. args: "<onset> <end>".
        # STRICTER than flicker and than the frozen first-divergence constant:
        # one contiguous run, a fixed onset, full re-convergence, match state
        # untouched. The checker also fails on a bit-IDENTICAL pair, because
        # this expectation asserts the divergence exists.
        _mc_onset=${_mc_args%% *}; _mc_end=${_mc_args##* }
        if _mc_out=$(python3 "$REPO/tools/compare_window.py" "$_mc_baselog" \
                    "$_mc_log" --onset "$_mc_onset" --end "$_mc_end" 2>&1); then
            echo "PASS masked-window ($(echo "$_mc_out" | head -1))"
        else
            echo "FAIL masked-window: $(echo "$_mc_out" | tr '\n' ' ')"; return 1
        fi ;;
    composite)
        # RATIFIED §4 v4 class (CLAUDE.md, maintainer-ratified 2026-08-06),
        # strict conjunction of `flicker` and `window`:
        # args "<flicker-csv> <window-list>".
        # Ground truth: tests/test_compare_composite.sh.
        _mc_fl=${_mc_args%% *}; _mc_win=${_mc_args##* }
        if _mc_out=$(python3 "$REPO/tools/compare_composite.py" "$_mc_baselog" \
                    "$_mc_log" --flicker "$_mc_fl" --windows "$_mc_win" 2>&1); then
            echo "PASS masked-composite ($(echo "$_mc_out" | head -1))"
        else
            echo "FAIL masked-composite: $(echo "$_mc_out" | tr '\n' ' ')"; return 1
        fi ;;
    *)
        echo "FAIL unknown .masked class '$_mc_class'"; return 1 ;;
    esac
    return 0
}
