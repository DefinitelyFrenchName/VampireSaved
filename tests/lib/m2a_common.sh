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
