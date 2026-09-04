#!/bin/sh
# run_suite.sh — the oracle replay suite (MAME side), auto-detecting runner.
#
# Usage: ROMDIR=... [MAME_ROMPATH="patched_dir;$ROMDIR"] tests/run_suite.sh [--freeze] [set]
#
# The build under test is whatever the rompath resolves (vanilla by default;
# set MAME_ROMPATH to front a patched build). Its program-image fingerprint
# is looked up in tests/expected/registry.tsv and selects the expectation
# directory tests/expected/<expset>/ (CLAUDE.md §4 auto-detecting runner).
# An unregistered fingerprint fails loudly — registry rows are added only at
# freeze time as a build decision recorded in STATE.md.
#
# For every tests/replays/*.rpl: run twice, fail on nondeterminism, then:
#   <name>.skip expectation: replay not applicable to this set (e.g. it
#     targets another romset); body = the reason, printed.
#   <name>.masked expectation (hooked builds; CLAUDE.md §4 amended basis —
#     both runs use MASK_RANGES matching docs/game/atlas/ram.md):
#       exact <baseset>              bit-identical to the frozen masked log
#                                    tests/expected/<baseset>/logs/<name>.log
#       flicker <baseset> <n> <csv>  compare_flicker verdict must be exactly
#                                    "FLICKER <n> <csv>" (frozen inventory;
#                                    §4 v2 — drift in either direction is a
#                                    loud failure, not tolerance headroom)
#       diverge <baseset> <frame>    first divergence exactly at <frame>
#       window <baseset> <onset> <end>   §4 v3 "bounded re-convergent
#                                    window" (tools/compare_window.py): ONE
#                                    contiguous run, fixed onset, full
#                                    re-convergence, match state untouched.
#                                    For the select screen the roster work
#                                    deliberately extends. A bit-identical
#                                    pair FAILS this class — the expectation
#                                    asserts the divergence exists.
#   <name>.diverge expectation ("<baseset> <frame>"): the log must be
#     line-identical to the frozen full log tests/expected/<baseset>/logs/
#     <name>.log through frame-1 and FIRST diverge exactly at <frame> —
#     for replays that legitimately involve a patched slot (e.g. attract
#     demos). The superset invariant is never weakened, only specified.
#   <name>.sha1 expectation: whole-log SHA-1 equality (the default).
#   --freeze: write sha1 + full log copies instead of comparing. Replays
#     carrying .skip or .masked are left untouched (those expectations are
#     authored from the gate inventory, not self-frozen). A SELF-FROZEN
#     .diverge, however, is RETIRED to .diverge.superseded and reported —
#     dispatch consults .diverge before .sha1, so leaving it would make the
#     freeze unreachable while printing "frozen" (14z-94, GitHub #88).
set -eu

FREEZE=0
if [ "${1:-}" = "--freeze" ]; then FREEZE=1; shift; fi
SET="${1:-vsavj}"
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/masked_compare.sh"   # the §4 comparison vocabulary (14z-97)
ROMPATH="${MAME_ROMPATH:-$ROMDIR}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 14z-90 (issue #3, defense in depth — NOT the root cause of that issue).
# tools/freeze_masked_basis.sh:55 scrubs these before writing a basis ("guard
# 3: nothing from the caller's shell may reach the frozen logs"); the GATE
# side had no equivalent, so an exported TAIL_FRAMES could shorten a gate log
# below its basis. The comparators now reject a length mismatch outright, so
# this is belt-and-braces: the freeze side and the compare side should be
# equally hermetic, or the two are not measuring the same thing.
unset POKES DUMPS SNAP_FRAMES TAIL_FRAMES VIDEO_OUT INPUT_OUT INPUT_INJECT_TEST NO_INPUT_CHECK || true

EXPSET=$(python3 "$REPO/tools/build_fingerprint.py" "$ROMPATH" --set "$SET") \
    || { echo "unregistered build fingerprint — see message above"; exit 1; }
EXPDIR="$REPO/tests/expected/$EXPSET"
mkdir -p "$EXPDIR"
echo "build fingerprint -> expectation set '$EXPSET'"

# check_diverge <log> <spec-file> -> prints verdict, returns 0/1
check_diverge() {
    python3 "$REPO/tools/check_diverge.py" "$1" "$2" "$REPO/tests/expected"
}

# The masked windows of the amended legacy basis (docs/game/atlas/ram.md:
# dead stack $FF7F00-$FF7FFF + QSound latch $FF043C + the palette
# staging slots of the rows this project's palette ports edit — the
# staging area is $FF3F02 + row*0x20; row 0x14's slot $FF4182-$FF41A1
# was ratified round 64 for the 14z-49 port, 14z-64 added the sibling
# slots for the medallion rows 0x16/0x19/0x1A (V2, ratified with the
# donovan-m3a bundle); 14z-88 added row 0x1D's slot $FF42A2-$FF42C1
# (V3, ratified 2026-08-15 for the 14z-87b medallion move) and WITHDREW
# it the same day with the move's revert (STATE 14z-88) — masked-v3 is
# kept on disk as a parked basis. Must stay in sync with M2A_MASK in
# tests/lib/m2a_common.sh.
# PER-SET OVERRIDE (14z-64): an expectation set frozen under a different
# basis ships tests/expected/<set>/mask with its MASK_RANGES string —
# sets without one use the round-64 default below (the stock-track sets).
# A .masked spec's <baseset> MUST be the vanilla basis generated under
# the SAME mask (masked bytes are skipped from the checksum, so v2 logs
# cannot be compared under a v3 mask): tests/expected/vsavj/masked (v1),
# masked-v2, masked-v3 — regenerate with tools/freeze_masked_basis.sh.
MASK="$(masked_mask_for "$EXPDIR")"
if [ -f "$EXPDIR/mask" ]; then
    echo "per-set mask: $MASK"
fi

fail=0
# SUITE_ONLY="<name> <name>..." (14z-105): run ONLY the named replays. An
# AUTHORING aid for the freeze — the self-frozen .sha1 replays can be
# re-frozen without the ~3 h full pass — and NEVER a verdict: a filtered
# run prints FILTERED on its summary line and the acceptance of a freeze
# remains the unfiltered verify run.
[ -n "${SUITE_ONLY:-}" ] && echo "FILTERED RUN (SUITE_ONLY) — not a suite verdict"
for rpl in "$REPO"/tests/replays/*.rpl; do
    name="$(basename "$rpl" .rpl)"
    if [ -n "${SUITE_ONLY:-}" ]; then
        case " $SUITE_ONLY " in *" $name "*) ;; *) continue ;; esac
    fi
    printf '%-24s ' "$name"
    if [ -f "$EXPDIR/$name.skip" ]; then
        echo "SKIP ($(cat "$EXPDIR/$name.skip"))"
        continue
    fi
    # .pending: the shape has been MEASURED but its comparison class is not
    # ratified yet, so there is nothing legitimate to compare against. This
    # is a FAILURE, not a skip — an unvalidated replay must never read as
    # green — but it names the reason and the proposed spec instead of
    # printing a bare NO-EXPECTATION. Added 14z-61 for the WIDE reference,
    # whose select-reaching replays show "frozen flicker inventory + one
    # bounded window per select ENTRY", a composite of two ratified classes
    # that the vocabulary cannot yet express (CLAUDE.md §4 needs sign-off).
    if [ -f "$EXPDIR/$name.pending" ]; then
        echo "PENDING — not validated"
        sed 's/^/                         /' "$EXPDIR/$name.pending"
        fail=1
        continue
    fi
    RUNMASK=""
    [ -f "$EXPDIR/$name.masked" ] && RUNMASK="$MASK"
    MASK_RANGES="$RUNMASK" "$REPO/tools/run_replay_mame.sh" "$SET" "$rpl" "$WORK/$name.1.log" || { echo "RUN-FAIL"; fail=1; continue; }
    MASK_RANGES="$RUNMASK" "$REPO/tools/run_replay_mame.sh" "$SET" "$rpl" "$WORK/$name.2.log" || { echo "RUN-FAIL"; fail=1; continue; }
    if ! cmp -s "$WORK/$name.1.log" "$WORK/$name.2.log"; then
        echo "NONDETERMINISTIC (first divergent frame below)"
        diff "$WORK/$name.1.log" "$WORK/$name.2.log" | head -3
        fail=1
        continue
    fi
    sha=$(shasum "$WORK/$name.1.log" | cut -d' ' -f1)
    if [ "$FREEZE" = 1 ] && [ -n "$RUNMASK" ]; then
        echo "authored .masked expectation — not self-frozen"
    elif [ "$FREEZE" = 1 ]; then
        echo "$sha" > "$EXPDIR/$name.sha1"
        mkdir -p "$EXPDIR/logs"
        cp "$WORK/$name.1.log" "$EXPDIR/logs/$name.log"
        # RETIRE A SUPERSEDED .diverge (14z-94, GitHub #88). Dispatch below
        # consults .diverge BEFORE .sha1, so freezing a replay that still
        # carries one wrote an expectation that could never be reached: the
        # command printed "frozen <sha>" while the replay stayed governed by
        # the OLD divergence allowance. Exactly the case this happens in — a
        # replay that was allowed to diverge and has since been FIXED — is the
        # one where continuing to accept a divergence is worst.
        #
        # Retired, not deleted: a .diverge is a ratified allowance and the
        # frame it names is evidence. Freeze already documents itself as
        # preserving only the AUTHORED .skip and .masked expectations, so
        # superseding a self-frozen class here is the documented intent.
        if [ -f "$EXPDIR/$name.diverge" ]; then
            mv "$EXPDIR/$name.diverge" "$EXPDIR/$name.diverge.superseded"
            echo "  RETIRED $name.diverge ($(cat "$EXPDIR/$name.diverge.superseded"))"
            echo "  -> kept as $name.diverge.superseded; the new .sha1 now governs."
        fi
        echo "frozen $sha"
    elif [ -n "$RUNMASK" ]; then
        # THE VOCABULARY LIVES IN tests/lib/masked_compare.sh (14z-97, GitHub
        # #96). It was inline here — exact/flicker/diverge/window/composite
        # plus the #62 baseset/mask guard — until the M2 battery was
        # re-pointed at the current frozen generation and needed to speak the
        # same classes. The lib is a verbatim lift: these verdict lines are
        # character-for-character what this loop printed before, which is how
        # the extraction was verified (suite output diffed, both directions).
        if verdict=$(masked_check "$EXPDIR" "$name" \
                        "$(cat "$EXPDIR/$name.masked")" \
                        "$RUNMASK" "$WORK/$name.1.log"); then
            echo "$verdict"
        else
            echo "$verdict"; fail=1
        fi
    elif [ -f "$EXPDIR/$name.diverge" ]; then
        check_diverge "$WORK/$name.1.log" "$EXPDIR/$name.diverge" || fail=1
    elif [ ! -f "$EXPDIR/$name.sha1" ]; then
        echo "NO-EXPECTATION (freeze after review, as a STATE.md decision)"
        fail=1
    elif [ "$sha" = "$(cat "$EXPDIR/$name.sha1")" ]; then
        echo "PASS"
    else
        echo "FAIL expected $(cat "$EXPDIR/$name.sha1") got $sha"
        cp "$WORK/$name.1.log" "$WORK/$name.divergent.log" 2>/dev/null || true
        fail=1
    fi
done

[ "$fail" = 0 ] && echo "SUITE GREEN" || echo "SUITE RED"
exit "$fail"
