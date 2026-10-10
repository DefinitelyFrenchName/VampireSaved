# instr_align.sh — #228 step 4's alignment checks for a gate built on a breakpoint instrument (14z-197,
# GitHub #228, maintainer-ruled 2026-10-10 "option A"). Sourced; sh, no bashisms.
#
# THE RULING, as this file implements it: every instrument run counts EMULATED frames (tests/lua/emu_clock.lua)
# and writes one ALIGN line (ALIGN_OUT). A gate then
#   - holds every breakpoint run to its replay's FROZEN game clock RAM:$FF8080 at the run's last frame
#     (tests/expected/instr_gameclock/<gate>.tsv), taken ONCE from REFERENCE legs (the same instrument, no
#     breakpoint, no debugger) when the gate is converted or a frozen value moves — the per-replay reference
#     legs do not recur;
#   - runs ONE staging reference leg per gate on every run, its anchor held to the frozen vanilla basis
#     (or to replay.lua run live where the build has no basis);
#   - carries two controls: drift-clock (a breakpoint run under INSTR_CLOCK=frame_done must miss the frozen
#     game clock) and first-frame-skip (the staging leg under INSTR_CLOCK=skip_first must miss its anchor).
#
# WHAT THE GAME CLOCK IS (measured 14z-197, build/agent197/t228/gameclock_by_frames.txt; rule-checker runs
# 2026-10-10-798/799/800): RAM:$FF8080 is ONE BYTE of the game's own vblank count, read at a run's last frame.
# Over all 122 rows first frozen (four legs, three builds) every frame count maps to one value, whatever the replay
# or build; most replays fit frames + a constant (mod 256), and 01_attract_long and 26_don_arcade_mash do not, so the
# game does not count every frame (where it pauses is not measured). So it is an INDEPENDENT witness of the
# script's own frame count (tests/lua/emu_clock.lua's `frames` and `emulated` both come from the script; a defect
# there would pass `frames == emulated` and not the game's count) — modulo 256: a count off by a whole multiple of
# 256 frames passes it. It is not a witness of the game's state: a stop measured to move the game's work RAM left it
# unchanged (tests/test_emu_clock.sh).
#
# THE FROZEN FILE: tests/expected/instr_gameclock/<gate>.tsv, `leg<TAB>replay<TAB>frames<TAB>gameclock`, `#`
# comments. A leg names the build a run plays (e.g. `vsavj`, `reloc`).
#
# Every function is safe under `set -e`: the readers return 0 with no output on a missing file, and ia_check's
# status is its verdict — call it in an `if` or with `|| true`.
#
# Functions:
#   ia_field <align file> <key>        the value after <key> on the ALIGN line (frames, emulated, uiframes, gameclock)
#   ia_anchor <align file>             the anchor checksum, or nothing
#   ia_anchor_frame <align file>       the frame the anchor was taken at, or nothing
#   ia_frozen <tsv> <leg> <replay>     "<frames> <gameclock>" from the frozen file, or nothing
#   ia_check <tsv> <leg> <replay> <align file>
#                                      prints ONE line per problem (no ALIGN line; frames != emulated; no frozen
#                                      row; frames or game clock unlike the frozen row) and returns 1, else 0
#   ia_row <leg> <replay> <align file> a frozen-file row from a reference leg's ALIGN line
ia_field() { awk -v k="$2" '{for (i = 1; i < NF; i++) if ($i == k) {print $(i + 1); exit}}' "$1" 2>/dev/null || true; }
ia_anchor() { awk '{for (i = 1; i < NF; i++) if ($i == "anchor") {print $(i + 2); exit}}' "$1" 2>/dev/null || true; }
ia_anchor_frame() { awk '{for (i = 1; i < NF; i++) if ($i == "anchor") {print $(i + 1); exit}}' "$1" 2>/dev/null || true; }
ia_frozen() { awk -F'\t' -v l="$2" -v r="$3" '!/^#/ && $1 == l && $2 == r {print $3, $4; exit}' "$1" 2>/dev/null || true; }
ia_check() {
    _ia_t="$1"; _ia_l="$2"; _ia_r="$3"; _ia_a="$4"
    if [ ! -s "$_ia_a" ]; then echo "$_ia_l/$_ia_r: no ALIGN line (the run did not reach its last frame)"; return 1; fi
    _ia_f="$(ia_field "$_ia_a" frames)"; _ia_e="$(ia_field "$_ia_a" emulated)"; _ia_g="$(ia_field "$_ia_a" gameclock)"
    _ia_bad=0
    [ "$_ia_f" = "$_ia_e" ] || { echo "$_ia_l/$_ia_r: counted $_ia_f frames over $_ia_e emulated"; _ia_bad=1; }
    _ia_z="$(ia_frozen "$_ia_t" "$_ia_l" "$_ia_r")"
    if [ -z "$_ia_z" ]; then echo "$_ia_l/$_ia_r: no frozen game clock in $_ia_t"; return 1; fi
    [ "${_ia_z% *}" = "$_ia_f" ] || { echo "$_ia_l/$_ia_r: ran $_ia_f frames, the frozen game clock was taken at ${_ia_z% *}"; _ia_bad=1; }
    [ "${_ia_z#* }" = "$_ia_g" ] || { echo "$_ia_l/$_ia_r: game clock $_ia_g at frame $_ia_f, frozen ${_ia_z#* }"; _ia_bad=1; }
    return $_ia_bad
}
ia_row() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$(ia_field "$3" frames)" "$(ia_field "$3" gameclock)"; }
#   ia_replaylua_at <set> <rompath> <replay .rpl> <frame> <dir> [mask]
#                                      replay.lua run live on <set> (MAME_BIN, tools/run_mame.sh), under [mask]
#                                      (replay.lua's MASK_RANGES grammar; none = unmasked); prints its checksum at
#                                      <frame> — the staging yardstick where no basis exists
#   ia_replaylua_run <set> <rompath> <replay .rpl> <dir> [mask]   the same run, no read (for a gate to run several
#                                      in the background); ia_replaylua_read <dir> <frame> reads it afterwards
ia_replaylua_run() {
    mkdir -p "$4"
    CHECKSUM_OUT="$4/cks.log" REPLAY="$3" MAME_SANDBOX="$4/sb" MAME_ROMPATH="$2" MASK_RANGES="${5:-}" \
        tools/run_mame.sh "$1" -autoboot_script "$PWD/tests/lua/replay.lua" > "$4/run.log" 2>&1 || true
    rm -rf "$4/sb"
}
ia_replaylua_read() { awk -v n="$2" '$1 == n {print $2}' "$1/cks.log" 2>/dev/null || true; }
ia_replaylua_at() { ia_replaylua_run "$1" "$2" "$3" "$5" "${6:-}"; ia_replaylua_read "$5" "$4"; }
#
# THE RUN MANIFEST (14z-197, slice 2: the gates on tests/lua/trace_writes.lua). A gate with many runs of differing
# builds, replays, POKES and watches notes each breakpoint run in a manifest, and the four functions below do the
# rest — the checks, the freeze, the staging leg and its two controls — so no gate carries its own copy.
#   ia_note <manifest> <leg> <replay> <set> <rompath|-> <replay .rpl> <frames> <env|-> <align file>
#           one breakpoint run: <env> is the instrument's own environment, space-separated NAME=value words
#           (WATCH=… POKES=… REGS_EXTRA=… and MAME_BIN=… where the gate pins a binary; no value may hold a space),
#           replayed as is by the reference and control legs. One (leg, replay) is ONE frozen row, so two runs under
#           one key must agree on set, rompath, replay, frames, POKES and MAME_BIN (ia_freeze refuses otherwise:
#           give them different legs).
#   ia_check_manifest <tsv> <manifest>          ia_check on every noted run; prints the problems, returns 1 on any
#   ia_freeze <instrument .lua> <manifest> <dir> <jobs> <out rows>
#           per (leg, replay): a REFERENCE leg (the instrument, INSTR_REFERENCE=1, no -debug, ANCHOR at its last
#           frame) and replay.lua run live with the same POKES and binary (the yardstick: replay.lua is the oracle script, so the
#           reference leg's staging is held to it, #213's method); then the reference leg's anchor must equal
#           replay.lua's checksum, and every breakpoint run under that key must count emulated frames and end on the
#           reference leg's game clock. Writes the rows to <out rows>; prints the problems and returns 1 on any.
#   ia_stage <gate> <tsv> <instrument .lua> <manifest> <line> <dir> <mode> [drift line]
#           the per-run staging leg and the two controls, on the manifest's <line>-th run (the drift control on
#           [drift line] when given — a run whose old-clock drift is a whole multiple of 256 frames ends on the frozen
#           byte by wrap-around, measured 14z-197 on test_tenant_select_records: there frames == emulated is what
#           sees it, and the control is aimed at a run the game clock can see): the reference leg's anchor
#           must equal replay.lua's (live) — under <mode> first-frame-skip the leg runs the skip; then, outside a
#           control mode, drift-clock (that breakpoint run re-run from its manifest line — the instrument, its env,
#           -debug — under INSTR_CLOCK=frame_done must miss its frozen GAME CLOCK, not merely its frame count) and
#           first-frame-skip (the staging leg under the skip must miss replay.lua). Prints the staging leg's ok/FAIL
#           line and returns 1 on its FAIL; the controls' outcomes are left in IA_DRIFT / IA_SKIP (`fired` or `dead`)
#           with IA_DRIFT_MSG / IA_SKIP_MSG, for the GATE to print with vs_ctl_fired / vs_ctl_dead — a gate prints its
#           own controls' verdicts (tests/test_must_fire_census.sh reads them in the gate's text). Both are `dead`
#           until the controls run (a control mode, or a staging line that is missing).
ia_note() {
    for _ia_w in $8; do case "$_ia_w" in *=*) ;; -) ;; *) echo "ia_note: env word '$_ia_w' is not NAME=value" >&2; return 1 ;; esac; done
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" >> "$1"
}
ia_check_manifest() {
    _icm_bad=0
    while IFS="$(printf '\t')" read -r _l _r _s _p _f _n _e _a; do
        ia_check "$1" "$_l" "$_r" "$_a" || _icm_bad=1
    done < "$2"
    return $_icm_bad
}
_ia_word() { for _w in $1; do case "$_w" in "$2"=*) echo "${_w#"$2"=}" ;; esac; done; }   # <env> <NAME>: its value
_ia_leg() {   # <instrument> <set> <rompath> <rpl> <frames> <env> <dir> <debug: 1|0> [extra env words]
    mkdir -p "$7"
    _x="$6"; [ "$_x" = - ] && _x=""
    _rp="$3"; [ "$_rp" = - ] && _rp="$ROMDIR"
    _dbg=""; [ "$8" = 1 ] && _dbg="-debug -debugger none"
    # shellcheck disable=SC2086
    ( cd "$7" && env $_x ${9:-} REPLAY="$4" FRAMES="$5" ANCHOR="$5" ALIGN_OUT="$7/align" TRACE_OUT="$7/trace.txt" \
        MAME_SANDBOX="$7/sb" MAME_ROMPATH="$_rp" "$REPO/tools/run_mame.sh" "$2" $_dbg -autoboot_script "$1" \
        > "$7/run.log" 2>&1 ) </dev/null || true
    rm -rf "$7/sb"
}
_ia_rl() {   # <set> <rompath> <rpl> <env> <dir>: replay.lua live, with the env's POKES and MAME_BIN
    mkdir -p "$5"; _rp="$2"; [ "$_rp" = - ] && _rp="$ROMDIR"
    _bin="$(_ia_word "$4" MAME_BIN)"; [ -n "$_bin" ] || _bin="${MAME_BIN:-}"
    ( cd "$5" && env POKES="$(_ia_word "$4" POKES)" CHECKSUM_OUT="$5/cks.log" REPLAY="$3" MAME_SANDBOX="$5/sb" \
        MAME_ROMPATH="$_rp" ${_bin:+"MAME_BIN=$_bin"} \
        "$REPO/tools/run_mame.sh" "$1" -autoboot_script "$REPO/tests/lua/replay.lua" > "$5/run.log" 2>&1 ) </dev/null || true
    rm -rf "$5/sb"
}
ia_freeze() {
    _ia_i="$1"; _ia_m="$2"; _ia_d="$3"; _ia_j="$4"; _ia_o="$5"; _ifz_bad=0; mkdir -p "$_ia_d"; : > "$_ia_o"
    # one key per (leg, replay); the runs under it must agree on what a reference leg would play
    awk -F'\t' '{ k = $1 "\t" $2; v = $3 "\t" $4 "\t" $5 "\t" $6
                  p = ""; n = split($7, w, " "); for (i = 1; i <= n; i++) if (w[i] ~ /^(POKES|MAME_BIN)=/) p = p " " w[i]
                  v = v "\t" p
                  if (k in seen && seen[k] != v) { print "ia_freeze: " $1 "/" $2 ": two runs disagree on set/rompath/replay/frames/POKES/MAME_BIN"; bad = 1 }
                  seen[k] = v } END { exit bad }' "$_ia_m" || return 1
    awk -F'\t' '!s[$1 "\t" $2]++' "$_ia_m" > "$_ia_d/keys.tsv"
    _n=0; _pool=0
    while IFS="$(printf '\t')" read -r _l _r _s _p _f _n2 _e _a; do
        _n=$((_n + 1)); _k="$_ia_d/k$_n"
        _ia_leg "$_ia_i" "$_s" "$_p" "$_f" "$_n2" "$_e" "$_k/ref" 0 INSTR_REFERENCE=1 &
        _ia_rl "$_s" "$_p" "$_f" "$_e" "$_k/rl" &
        _pool=$((_pool + 2)); [ "$_pool" -ge "$_ia_j" ] && { wait; _pool=0; }
    done < "$_ia_d/keys.tsv"
    wait
    _n=0
    while IFS="$(printf '\t')" read -r _l _r _s _p _f _n2 _e _a; do
        _n=$((_n + 1)); _ra="$_ia_d/k$_n/ref/align"
        if [ ! -s "$_ra" ]; then echo "$_l/$_r: the reference leg wrote no ALIGN line"; _ifz_bad=1; continue; fi
        _an="$(ia_anchor "$_ra")"; _af="$(ia_anchor_frame "$_ra")"; _want="$(ia_replaylua_read "$_ia_d/k$_n/rl" "$_af")"
        [ -n "$_an" ] && [ "$_an" = "$_want" ] || { echo "$_l/$_r: the reference leg reads ${_an:-nothing} at frame ${_af:-?}, replay.lua live ${_want:-nothing}"; _ifz_bad=1; }
        [ "$(ia_field "$_ra" frames)" = "$(ia_field "$_ra" emulated)" ] || { echo "$_l/$_r: the reference leg counted $(ia_field "$_ra" frames) over $(ia_field "$_ra" emulated) emulated"; _ifz_bad=1; }
        ia_row "$_l" "$_r" "$_ra" >> "$_ia_o"
        # every breakpoint run under this key
        while IFS="$(printf '\t')" read -r _l2 _r2 _s2 _p2 _f2 _x2 _e2 _a2; do
            [ "$_l2" = "$_l" ] && [ "$_r2" = "$_r" ] || continue
            if [ ! -s "$_a2" ]; then echo "$_l/$_r: a breakpoint run wrote no ALIGN line ($_a2)"; _ifz_bad=1; continue; fi
            [ "$(ia_field "$_a2" frames)" = "$(ia_field "$_a2" emulated)" ] || { echo "$_l/$_r: a breakpoint run counted $(ia_field "$_a2" frames) over $(ia_field "$_a2" emulated) emulated"; _ifz_bad=1; }
            [ "$(ia_field "$_a2" gameclock)" = "$(ia_field "$_ra" gameclock)" ] || { echo "$_l/$_r: a breakpoint run's game clock $(ia_field "$_a2" gameclock), its reference leg's $(ia_field "$_ra" gameclock) ($_a2)"; _ifz_bad=1; }
        done < "$_ia_m"
    done < "$_ia_d/keys.tsv"
    return $_ifz_bad
}
ia_stage() {
    _g="$1"; _t="$2"; _i="$3"; _m="$4"; _ln="$5"; _d="$6"; _mode="$7"; _dln="${8:-$5}"; _ist_bad=0
    IA_DRIFT=dead; IA_DRIFT_MSG="the drift control did not run"; IA_SKIP=dead; IA_SKIP_MSG="the first-frame-skip control did not run"
    _line="$(sed -n "${_ln}p" "$_m")"
    [ -n "$_line" ] || { echo "  FAIL: $_g: no run $_ln in the manifest for the staging leg"; return 1; }
    IFS="$(printf '\t')" read -r _l _r _s _p _f _n _e _a <<EOT
$_line
EOT
    _sk=""; [ "$_mode" = first-frame-skip ] && _sk="INSTR_CLOCK=skip_first"
    _ia_leg "$_i" "$_s" "$_p" "$_f" "$_n" "$_e" "$_d/stage" 0 "INSTR_REFERENCE=1 $_sk" &
    _ia_rl "$_s" "$_p" "$_f" "$_e" "$_d/rl" &
    wait
    _sa="$(ia_anchor "$_d/stage/align")"; _rl="$(ia_replaylua_read "$_d/rl" "$_n")"
    if [ -n "$_rl" ] && [ "$_sa" = "$_rl" ]; then echo "  ok: the staging reference leg ($_l/$_r) reproduces replay.lua at frame $_n ($_sa)"
    else echo "  FAIL: the staging reference leg ($_l/$_r) reads ${_sa:-nothing} at frame $_n, replay.lua ${_rl:-nothing}"; _ist_bad=1; fi
    case "$_mode" in drift-clock|first-frame-skip) return $_ist_bad ;; esac
    IFS="$(printf '\t')" read -r _dl _dr _ds _dp _df _dn _de _da <<EOT
$(sed -n "${_dln}p" "$_m")
EOT
    _ia_leg "$_i" "$_ds" "$_dp" "$_df" "$_dn" "$_de" "$_d/cdrift" 1 INSTR_CLOCK=frame_done
    ia_check "$_t" "$_dl" "$_dr" "$_d/cdrift/align" > "$_d/cdrift.txt" || true
    if grep -q "game clock" "$_d/cdrift.txt"; then IA_DRIFT=fired; IA_DRIFT_MSG="$(grep "game clock" "$_d/cdrift.txt" | head -1) (under the frame_done clock: $(grep -v "game clock" "$_d/cdrift.txt" | head -1))"
    else IA_DRIFT_MSG="the frame_done clock still met the frozen game clock on $_dl/$_dr ($(head -1 "$_d/cdrift.txt"))"; fi
    _ia_leg "$_i" "$_s" "$_p" "$_f" "$_n" "$_e" "$_d/cskip" 0 "INSTR_REFERENCE=1 INSTR_CLOCK=skip_first"
    _ka="$(ia_anchor "$_d/cskip/align")"
    if [ -z "$_ka" ]; then IA_SKIP_MSG="the skip leg wrote no anchor"
    elif [ "$_ka" != "$_rl" ]; then IA_SKIP=fired; IA_SKIP_MSG="under the first-frame skip the staging leg reads $_ka at frame $_n where replay.lua reads $_rl"
    else IA_SKIP_MSG="the skipped clock still reproduced replay.lua"; fi
    return $_ist_bad
}
