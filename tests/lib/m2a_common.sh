# m2a_common.sh — shared helpers for the M2a stage gates. Source from tests.
# Requires: ROMDIR, REPO set by the caller. test_m2_repoint.sh stays frozen
# as the original mechanism proof; these helpers generalize its gates.

# m2a_run <rompath> <replay.rpl> <out.log> <sandbox> — replay on a build
m2a_run() {
    MAME_ROMPATH="$1" "$REPO/tools/run_replay_mame.sh" vsavj "$2" "$3" "$4"
}

# m2a_diverge <log> <name> <frame> — log must match the frozen vanilla full
# log for <name> through <frame>-1 and first diverge exactly at <frame>
m2a_diverge() {
    _dv_dir="$(mktemp -d)"
    printf 'vsavj %s' "$3" > "$_dv_dir/$2.diverge"
    _dv_out=$(python3 "$REPO/tools/check_diverge.py" "$1" "$_dv_dir/$2.diverge" \
        "$REPO/tests/expected") && _dv_rc=0 || _dv_rc=1
    rm -rf "$_dv_dir"
    echo "$_dv_out"
    return "$_dv_rc"
}

# m2a_legacy_gate <rompath> <workdir> — the superset-invariant gate:
# non-slot-0x0F replays bit-identical; attract diverges exactly at its
# Jedah demo (4278). Callers add stage-specific diverge checks for replays
# that legitimately involve slot 0x0F. Sets gate_fail=1 on failure.
M2A_EXACT_REPLAYS="02_demitri_vs_cpu 03_two_player_vs 05_timeout_idle 06_test_mode 07_mash_storm 10_midattract_start 16_xemu_2p"
M2A_ATTRACT_DIVERGE=4278

m2a_legacy_gate() {
    _lg_rp="$1"; _lg_w="$2"
    gate_fail=0
    for _lg_r in $M2A_EXACT_REPLAYS; do
        m2a_run "$_lg_rp" "$REPO/tests/replays/$_lg_r.rpl" \
            "$_lg_w/$_lg_r.log" "$_lg_w/${_lg_r}box"
        _lg_got=$(shasum "$_lg_w/$_lg_r.log" | cut -d' ' -f1)
        _lg_exp=$(cat "$REPO/tests/expected/vsavj/$_lg_r.sha1")
        if [ "$_lg_got" = "$_lg_exp" ]; then
            echo "  ok: $_lg_r bit-identical"
        else
            echo "FAIL: $_lg_r diverged from vanilla"; gate_fail=1
        fi
    done
    m2a_run "$_lg_rp" "$REPO/tests/replays/01_attract_long.rpl" \
        "$_lg_w/01_attract_long.log" "$_lg_w/01box"
    if m2a_diverge "$_lg_w/01_attract_long.log" 01_attract_long "$M2A_ATTRACT_DIVERGE" > /dev/null; then
        echo "  ok: attract bit-identical through $((M2A_ATTRACT_DIVERGE - 1)), diverges at $M2A_ATTRACT_DIVERGE (Jedah demo)"
    else
        echo "FAIL: attract divergence not exactly at $M2A_ATTRACT_DIVERGE"
        m2a_diverge "$_lg_w/01_attract_long.log" 01_attract_long "$M2A_ATTRACT_DIVERGE" || true
        gate_fail=1
    fi
}

# ── Masked legacy gate (CLAUDE.md §4 amendment, 2026-07-25) ──────────────────
# For builds carrying ENGINE HOOKS the legacy comparison is live-RAM: all work
# RAM except the windows documented in docs/game/atlas/ram.md (dead stack
# $FF7F00-$FF7FFF at frame-done, the QSound handshake latch $FF043C, and the
# palette-fade staging slots of the rows this project's palette ports edit).
# The mask STRING is no longer written here — see the next block.
#
# ══ THE TARGET IS RESOLVED FROM THE BUILD, NOT PINNED BY NAME ═══════════════
# 14z-97, GitHub #96. RULED 2026-08-19 (maintainer), option (a): *"the battery
# asserts 'the pipeline, built fresh, reproduces the CURRENT freeze'. Its
# specs re-point at each freeze."*
#
# What this replaced, and why it had to go. This helper used to carry SIX
# constants describing one generation:
#
#     M2A_MASK            the V1 mask string (a second copy of run_suite's)
#     M2A_MASKED_EXP      tests/expected/vsavj/masked   (the V1 basis)
#     M2A_FLICKER_SPECS   tests/expected/donovan-m2c    (frozen 2026-08-02)
#     M2A_MASKED_EXACT    which replays were exact AT THAT GENERATION
#     M2A_MASKED_FLICKER  which replays flickered AT THAT GENERATION
#     M2A_TESTMODE_DIVERGE / M2A_PICK_DIVERGE_MASKED / M2A_ATTRACT_DIVERGE
#
# so it built a CURRENT image from today's manifests and judged it against a
# five-generation-old expectation, in a vocabulary that predates the §4 v3/v4
# `window` and `composite` classes. Every #96 symptom was that mismatch:
# `06_test_mode`'s 700 (which 14z-91's hook removal legitimately retired) and
# `08_challenger_join`'s 3807 (which today's tree expresses as a select-window
# ONSET on the WIDE track). Neither was a build defect.
#
# THE MECHANISM IS THE ONE run_suite.sh HAS ALWAYS USED — CLAUDE.md §4's
# auto-detecting runner. The build's program fingerprint is looked up in
# tests/expected/registry.tsv; that names the expectation set; the set carries
# the mask (tests/expected/<set>/mask) and one `.masked` spec per replay in
# the ratified vocabulary. So "latest frozen" is a POLICY here, not a new
# constant to go stale: at the next freeze the registry row moves and this
# helper follows it with no edit.
#
# AND AN UNREGISTERED FINGERPRINT IS THE RULE-6 SIGNAL, not an inconvenience.
# It means the pipeline no longer reproduces the current freeze, which is
# exactly what the ruling says a red battery means. It must never be worked
# around by pinning a set name back into this file.
#
# THE PREDICATE CHANGED WITH THE TARGET, AND THE OLD REASONING IS RETRACTED.
# 14z-90 (GitHub #2) made the flicker check fail on GROWTH and merely ADVISE
# on shrink, on the explicit grounds that "this helper runs on UNFROZEN dev
# builds, so pinning one build's numbers manufactures false REDs". That
# premise is gone: the build under test is now asserted to reproduce a
# FROZEN generation, so its inventory must match that generation EXACTLY.
# A shrink is no longer benign — it means the fresh build is not the frozen
# one — and it now fails, via the same comparators run_suite.sh uses. The
# growth-only predicate and its ground truth (tests/test_m2a_flicker_gate.sh)
# were retired with this change, not lost: see that file.
#
# M2A_EXPSET=<set> overrides the resolution. It exists for ONE job — authoring
# a new set for a build that is not registered yet — and it says so loudly on
# every run, because a silent name pin is the defect this block replaced.
#
# The §4 comparison vocabulary itself lives in ONE place, shared with the
# corpus runner: tests/lib/masked_compare.sh.
. "$REPO/tests/lib/masked_compare.sh"

# The replay names this gate REFUSES to run without. Names, not classes:
# which class a replay lands in is a property of the generation (09_mirror_pick
# was `flicker 1 829` at m2c and is `exact` now, because 14z-91 removed the
# hook that caused 829), but WHICH REPLAYS THE BATTERY OWES is not. Without
# this floor an expectation set that lost half its files would pass by
# asserting less — the "a skipped gate asserts NOTHING" failure (#29) one
# level down.
M2A_MASKED_REQUIRED="01_attract_long 02_demitri_vs_cpu 03_two_player_vs \
04_select_fuzz 05_timeout_idle 06_test_mode 07_mash_storm 08_challenger_join \
09_mirror_pick 10_midattract_start 11_pick_donovan 16_xemu_2p \
29_felicia_walljump 30_demitri_throw"
# What each one exercises (all vanilla-content; a gate name is
# <NN>_<character>_<mechanic> — the character is the vanilla char driving the
# scenario, NOT a porting target):
#   01_attract_long      attract demos, incl. the one that reaches the patched slot
#   02_demitri_vs_cpu    baseline match: movement, normals, CPU rounds
#   03_two_player_vs     2P match: both input rows live, round handoffs
#   04_select_fuzz       select-screen cursor fuzzing, edge picks
#   05_timeout_idle      timer expiry path, idle anims, timeout judging
#   06_test_mode         service mode (the only replay that reads the sound latch)
#   07_mash_storm        input-storm: simultaneous presses, frame-1 actions
#   08_challenger_join   mid-match challenger interrupt path (re-enters select)
#   09_mirror_pick       mirror-match pick (same-char palette side rules)
#   10_midattract_start  Start pressed mid-attract: demo teardown path
#   11_pick_donovan      picking the patched slot itself
#   16_xemu_2p           2P pattern shared with the dual-emulator gate
#   29_felicia_walljump  wall-latch/triangle-jump physics — added 14w after
#                        the gap-table collateral broke it ungated
#   30_demitri_throw     THROW machinery: grab, victim-keyframe positioner
#                        (0xBE27A table walk), cinematic, damage — added 14z
#                        after the throw-data blind spot let the copies-era
#                        corruption through ungated
M2A_MASK=""      # RESOLVED per run from the expectation set; never pinned here

# m2a_run_masked <rompath> <replay.rpl> <out.log> <sandbox>
m2a_run_masked() {
    MASK_RANGES="$M2A_MASK" MAME_ROMPATH="$1" \
        "$REPO/tools/run_replay_mame.sh" vsavj "$2" "$3" "$4"
}

# m2a_masked_target <rompath> — print the expectation set this build dispatches
# to, or fail with the rule-6 message. Kept separate so a caller can report the
# target before spending twenty minutes of MAME on it.
m2a_masked_target() {
    if [ -n "${M2A_EXPSET:-}" ]; then
        echo "$M2A_EXPSET"
        return 0
    fi
    # build_fingerprint.py prints the unregistered FINGERPRINT on stdout and
    # exits 2, so "whatever it printed" is not the set. Contract here: print a
    # set name and return 0, or print NOTHING and return 1 — a caller that
    # forgets to check the status must not end up with a 40-hex "set name".
    _mt_out=$(python3 "$REPO/tools/build_fingerprint.py" "$1" --set vsavj 2>/dev/null) \
        || return 1
    echo "$_mt_out"
}

# m2a_legacy_gate_masked <rompath> <workdir> — every replay the resolved
# expectation set names, compared with the ratified §4 comparators.
# Sets gate_fail=1 on failure.
m2a_legacy_gate_masked() {
    _mg_rp="$1"; _mg_w="$2"
    gate_fail=0
    # M2A_KEEP_DIR: where failing replays' logs are preserved. The default is
    # the shared evidence directory; a SELF-TEST that drives this gate through
    # deliberate failures MUST override it (test_m2a_flicker_gate.sh does) —
    # otherwise every static-tier run plants a stub log indistinguishable from
    # real failure evidence there (141 accumulated before this was caught).
    _mg_keep="${M2A_KEEP_DIR:-$REPO/build/gate_failures}"

    _mg_set="$(m2a_masked_target "$_mg_rp")" || _mg_set=""
    if [ -z "$_mg_set" ]; then
        echo "FAIL: this build's fingerprint is not in tests/expected/registry.tsv."
        echo "      The M2 battery targets the CURRENT frozen generation"
        echo "      (GitHub #96, maintainer-ruled 2026-08-19), so an unregistered"
        echo "      image means THE PIPELINE NO LONGER REPRODUCES THE FREEZE."
        echo "      That is rule 6: stop and find out what moved. Do NOT pin a"
        echo "      set name here to get past it."
        echo "      fingerprint: $(python3 "$REPO/tools/build_fingerprint.py" \
                                     "$_mg_rp" --set vsavj --sha-only 2>/dev/null)"
        gate_fail=1
        return
    fi
    if [ -n "${M2A_EXPSET:-}" ]; then
        echo "  !! M2A_EXPSET=$_mg_set — the target is PINNED BY NAME, so this"
        echo "     run does NOT assert the ruled policy (that the pipeline"
        echo "     reproduces the current freeze). Authoring only."
    fi
    _mg_exp="$REPO/tests/expected/$_mg_set"
    [ -d "$_mg_exp" ] || { echo "FAIL: no expectation dir $_mg_exp"; gate_fail=1; return; }
    M2A_MASK="$(masked_mask_for "$_mg_exp")"
    echo "  target: $_mg_set   mask: $M2A_MASK"

    # The floor, before any measuring: a set that names fewer replays than the
    # battery owes cannot pass by asserting less.
    for _mg_r in $M2A_MASKED_REQUIRED; do
        [ -f "$_mg_exp/$_mg_r.masked" ] || {
            echo "FAIL: $_mg_set has no spec for $_mg_r, which this gate requires."
            echo "      Author it (tools/propose_masked_specs.sh measures the"
            echo "      shape; every non-exact class needs its mechanism named)."
            gate_fail=1
        }
    done
    [ "$gate_fail" = 0 ] || return

    for _mg_r in $M2A_MASKED_REQUIRED; do
        m2a_run_masked "$_mg_rp" "$REPO/tests/replays/$_mg_r.rpl" \
            "$_mg_w/$_mg_r.log" "$_mg_w/${_mg_r}box"
        if _mg_v=$(masked_check "$_mg_exp" "$_mg_r" \
                    "$(cat "$_mg_exp/$_mg_r.masked")" "$M2A_MASK" \
                    "$_mg_w/$_mg_r.log"); then
            echo "  ok: $_mg_r $_mg_v"
        else
            mkdir -p "$_mg_keep"
            cp "$_mg_w/$_mg_r.log" "$_mg_keep/$_mg_r.$(date +%s).log"
            printf 'FAIL: %s %s\n' "$_mg_r" "$_mg_v"
            echo "      (log kept in build/gate_failures; spec is"
            echo "       $_mg_exp/$_mg_r.masked)"
            gate_fail=1
        fi
    done
}

# RETIRED 14z-97 with the re-point above, recorded so neither comes back by
# accident:
#   m2a_first_divergence  — the hand-rolled "first differing frame" used by the
#       three constant checks (06/01/11). Those are `.masked` specs of class
#       `diverge` now, checked by tools/check_diverge.py through masked_check,
#       which also asserts line-identity BEFORE the frame — the hand-rolled one
#       did not.
#   m2a_freeze_masked     — froze a vanilla masked basis from inside the gate
#       library. tools/freeze_masked_basis.sh is the one freeze path now, and
#       it carries the guards this did not: atomic publish (#86), a MASK record
#       beside the logs (#62 pairs specs to it), and an environment scrub so
#       nothing from the caller's shell reaches a frozen log.
