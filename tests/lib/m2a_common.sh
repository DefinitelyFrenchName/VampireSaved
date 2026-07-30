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
# For builds carrying ENGINE HOOKS: legacy comparison is live-RAM — all work
# RAM except the two windows documented in docs/atlas/ram.md (dead stack
# $FF7F00-$FF7FFF at frame-done + QSound handshake latch $FF043C).
# v2 semantics (maintainer-approved 2026-07-27, CLAUDE.md §4): per-replay
# comparison classes against FROZEN masked vanilla logs:
#   exact    02/05/07 + attract/pick diverge-constants: bit-identical
#   flicker  03/10/16: isolated <=2-frame divergent stretches that fully
#            re-converge (tools/compare_flicker.py, ground-truthed) — the
#            input-accept/spawn boundary phase artifact
#   diverge  06_test_mode: first divergence exactly at the TS press (700);
#            service-mode code reads the phase-shifted QSound latch and the
#            offset propagates (persistent, benign, hook-caused — stage-3
#            hook-free builds run 06 bit-identical)
# Hook-free builds keep m2a_legacy_gate (unmasked) above.
M2A_MASK="043c-043d,7f00-8000"
M2A_MASKED_EXP="tests/expected/vsavj/masked"   # relative to $REPO
# What each legacy replay exercises (all vanilla-content; a gate name is
# <NN>_<character>_<mechanic> — the character is the vanilla char driving
# the scenario, NOT a porting target):
#   02_demitri_vs_cpu    baseline match: movement, normals, CPU rounds
#   05_timeout_idle      timer expiry path, idle anims, timeout judging
#   07_mash_storm        input-storm: simultaneous presses, frame-1 actions
#   30_demitri_throw     THROW machinery: grab, victim-keyframe positioner
#                        (0xBE27A table walk), cinematic, damage — added
#                        14z after the throw-data blind spot let the
#                        copies-era corruption through ungated
#   03_two_player_vs     2P match: both input rows live, round handoffs
#   10_midattract_start  Start pressed mid-attract: demo teardown path
#   16_xemu_2p           2P pattern shared with the dual-emulator gate
#   04_select_fuzz       select-screen cursor fuzzing, edge picks
#   08_challenger_join   mid-match challenger interrupt path
#   09_mirror_pick       mirror-match pick (same-char palette side rules)
#   29_felicia_walljump  wall-latch/triangle-jump physics — added 14w
#                        after the gap-table collateral broke it ungated
M2A_MASKED_EXACT="02_demitri_vs_cpu 05_timeout_idle 07_mash_storm 30_demitri_throw"
M2A_MASKED_FLICKER="03_two_player_vs 10_midattract_start 16_xemu_2p 04_select_fuzz 08_challenger_join 09_mirror_pick 29_felicia_walljump"
# 04/08/09 measured session 11 (playtest follow-up: they had fallen out of
# the gate when it was rebuilt): pure flicker class — isolated single-frame
# re-converging divergences (04@1525/2009/2195, 08@3507, 09@829), no
# persistent hover divergence.
M2A_TESTMODE_DIVERGE=700                       # 06: the TS-press frame
M2A_PICK_DIVERGE_MASKED=1080                   # select-screen anim hover

# m2a_run_masked <rompath> <replay.rpl> <out.log> <sandbox>
m2a_run_masked() {
    MASK_RANGES="$M2A_MASK" MAME_ROMPATH="$1" \
        "$REPO/tools/run_replay_mame.sh" vsavj "$2" "$3" "$4"
}

# m2a_first_divergence <log_a> <log_b> — prints first differing frame or NONE
m2a_first_divergence() {
    python3 - "$1" "$2" <<'PYEOF'
import sys
a = open(sys.argv[1]).read().splitlines()
b = open(sys.argv[2]).read().splitlines()
print(next((x.split()[0] for x, y in zip(a, b) if x != y), "NONE"))
PYEOF
}

# m2a_legacy_gate_masked <rompath> <workdir> — full legacy set against the
# frozen masked vanilla logs (freeze with m2a_freeze_masked). gate_fail=1
# on failure.
m2a_legacy_gate_masked() {
    _mg_rp="$1"; _mg_w="$2"
    _mg_exp="$REPO/$M2A_MASKED_EXP"
    gate_fail=0
    [ -d "$_mg_exp/logs" ] || { echo "FAIL: no frozen masked logs at $_mg_exp (run m2a_freeze_masked)"; gate_fail=1; return; }
    _mg_keep="$REPO/build/gate_failures"
    for _mg_r in $M2A_MASKED_EXACT; do
        m2a_run_masked "$_mg_rp" "$REPO/tests/replays/$_mg_r.rpl" \
            "$_mg_w/$_mg_r.log" "$_mg_w/${_mg_r}box"
        if cmp -s "$_mg_exp/logs/$_mg_r.log" "$_mg_w/$_mg_r.log"; then
            echo "  ok: $_mg_r masked bit-identical"
        else
            mkdir -p "$_mg_keep"
            cp "$_mg_w/$_mg_r.log" "$_mg_keep/$_mg_r.$(date +%s).log"
            echo "FAIL: $_mg_r masked live-state diverged (log kept in build/gate_failures)"; gate_fail=1
        fi
    done
    for _mg_r in $M2A_MASKED_FLICKER; do
        m2a_run_masked "$_mg_rp" "$REPO/tests/replays/$_mg_r.rpl" \
            "$_mg_w/$_mg_r.log" "$_mg_w/${_mg_r}box"
        _mg_v=$(python3 "$REPO/tools/compare_flicker.py" \
            "$_mg_exp/logs/$_mg_r.log" "$_mg_w/$_mg_r.log") \
            && echo "  ok: $_mg_r masked ${_mg_v}" \
            || { mkdir -p "$REPO/build/gate_failures"
                 cp "$_mg_w/$_mg_r.log" "$REPO/build/gate_failures/$_mg_r.$(date +%s).log"
                 echo "FAIL: $_mg_r masked: $_mg_v (log kept in build/gate_failures)"; gate_fail=1; }
    done
    m2a_run_masked "$_mg_rp" "$REPO/tests/replays/06_test_mode.rpl" \
        "$_mg_w/06_test_mode.log" "$_mg_w/06box"
    _mg_div=$(m2a_first_divergence "$_mg_exp/logs/06_test_mode.log" \
        "$_mg_w/06_test_mode.log")
    if [ "$_mg_div" = "$M2A_TESTMODE_DIVERGE" ]; then
        echo "  ok: 06_test_mode masked first-divergence exactly $M2A_TESTMODE_DIVERGE (TS press; latch-phase propagation)"
    else
        echo "FAIL: 06_test_mode masked first-divergence $_mg_div (expected $M2A_TESTMODE_DIVERGE)"; gate_fail=1
    fi
    m2a_run_masked "$_mg_rp" "$REPO/tests/replays/01_attract_long.rpl" \
        "$_mg_w/01_attract_long.log" "$_mg_w/01box"
    _mg_div=$(m2a_first_divergence "$_mg_exp/logs/01_attract_long.log" \
        "$_mg_w/01_attract_long.log")
    if [ "$_mg_div" = "$M2A_ATTRACT_DIVERGE" ]; then
        echo "  ok: attract masked first-divergence exactly $M2A_ATTRACT_DIVERGE (Jedah demo)"
    else
        echo "FAIL: attract masked first-divergence $_mg_div (expected $M2A_ATTRACT_DIVERGE)"; gate_fail=1
    fi
    m2a_run_masked "$_mg_rp" "$REPO/tests/replays/11_pick_donovan.rpl" \
        "$_mg_w/11_pick_donovan.log" "$_mg_w/11box"
    _mg_div=$(m2a_first_divergence "$_mg_exp/logs/11_pick_donovan.log" \
        "$_mg_w/11_pick_donovan.log")
    if [ "$_mg_div" = "$M2A_PICK_DIVERGE_MASKED" ]; then
        echo "  ok: pick masked first-divergence exactly $M2A_PICK_DIVERGE_MASKED (anim hover)"
    else
        echo "FAIL: pick masked first-divergence $_mg_div (expected $M2A_PICK_DIVERGE_MASKED)"; gate_fail=1
    fi
}

# m2a_freeze_masked <workdir> — one-time: freeze masked VANILLA logs for the
# whole legacy set (+ sha1s for quick reference). Record the freeze in
# STATE.md. Deterministic and re-derivable from $ROMDIR.
m2a_freeze_masked() {
    _mf_w="$1"
    _mf_exp="$REPO/$M2A_MASKED_EXP"
    mkdir -p "$_mf_exp/logs"
    for _mf_r in $M2A_MASKED_EXACT $M2A_MASKED_FLICKER 06_test_mode 01_attract_long 11_pick_donovan; do
        m2a_run_masked "$ROMDIR" "$REPO/tests/replays/$_mf_r.rpl" \
            "$_mf_w/$_mf_r.log" "$_mf_w/${_mf_r}box"
        cp "$_mf_w/$_mf_r.log" "$_mf_exp/logs/$_mf_r.log"
        shasum "$_mf_w/$_mf_r.log" | cut -d' ' -f1 > "$_mf_exp/$_mf_r.sha1"
        echo "froze $_mf_r (log + sha1)"
    done
}
