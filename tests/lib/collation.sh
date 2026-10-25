# tests/lib/collation.sh — BYTE-ORDER COLLATION FOR EVERY GATE A RUNNER STARTS (#278, 14z-208b). Sourced by the three
# runners (tests/run_all_static.sh, tests/run_all_emulator.sh, tests/run_battery_m2.sh), which call vs_pin_collation
# once, before their first gate; every gate, control and helper they start inherits it.
#
# WHY: a gate that sorts or lists in the shell (`sort`, `ls`, `comm`, `join`, a bash glob) orders by the caller's
#   locale, and a UTF-8 locale on Linux (en_US.UTF-8) collates `_`, `.` and `:` away, so the same gate compared a
#   different order against its byte-ordered frozen list (#278: test_escape_triage and test_jtcores_twin, red on PILOT
#   only, 14z-200). The census of 14z-208b found 134 such lines in 61 shell files; pinning here covers all of them, and
#   every future one, without touching a gate (a changed gate leaves tests/controls_concurrent.txt until a re-trace).
# WHAT: only collation changes. A caller's LC_ALL (which overrides every category) is moved onto LANG and each
#   category variable, so character handling, messages and numbers stay as the caller had them; then LC_COLLATE=C.
#   macOS's en_US.UTF-8 collates too (case and punctuation: `a A a_c a-c a:c a.c` where C gives `A a a-c a.c a:c a_c`);
#   this Mac's sessions run under LANG=C.UTF-8, which sorts in byte order, so the pin changes nothing there.
# NOT COVERED: a gate run by hand (`sh tests/<gate>.sh`, a FREEZE=1 re-freeze) runs in the caller's locale; a gate
#   whose FREEZE=1 write takes its order from a shell sort keeps that order (nine such gates; test_charmap_current.sh
#   pins its line, and only audit_ex_refused compares its frozen file's order directly). docs/project/gotchas.md.
# CHECKED BY: tests/test_runner_collation.sh.
vs_pin_collation() {
    if [ -n "${LC_ALL:-}" ]; then
        _vs_lc="$LC_ALL"; unset LC_ALL
        LANG="$_vs_lc"; export LANG
        for _vs_v in LC_CTYPE LC_NUMERIC LC_TIME LC_MONETARY LC_MESSAGES; do eval "$_vs_v=\$_vs_lc; export $_vs_v"; done
        unset _vs_lc _vs_v
    fi
    LC_COLLATE=C; export LC_COLLATE
    VS_COLLATION_PINNED=278; export VS_COLLATION_PINNED
}
