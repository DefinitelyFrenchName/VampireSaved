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
