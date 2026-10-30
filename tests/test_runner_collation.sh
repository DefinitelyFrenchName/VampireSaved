#!/bin/sh
# test_runner_collation.sh — THE RUNNERS SORT IN BYTE ORDER WHATEVER THE CALLER'S LOCALE (#278, 14z-208b). ci_portable: no ROM, ~1 s.
#
# WHAT: tests/lib/collation.sh's vs_pin_collation leaves LC_ALL unset and LC_COLLATE=C, and moves a caller's LC_ALL
#   onto LANG and the other categories (so only collation changes); each of the three runners (tests/run_all_static.sh,
#   tests/run_all_emulator.sh, tests/run_battery_m2.sh) calls it at the top level, once, before its first gate runs.
#   A runner sources the library only when it is there: the runner tests (test_static_runner, test_emulator_runner,
#   test_green_guard, test_release_reuse) run the real runners in synthetic repos that carry only some of tests/lib, and
#   editing them would take their controls off tests/controls_concurrent.txt; so (2) also requires the library tracked.
# HOW: (1) the function runs in a clean `env -i` shell under three caller locales and its result is read; where this
#   host has a COLLATING en_US.UTF-8 (Linux and macOS: it sorts a case-and-punctuation probe differently from C), a
#   sort after the pin must give byte order;
#   (2) each runner's text is read for the pin line and the line of its first gate run; (3) when a runner started this
#   gate (VS_COLLATION_PINNED set), this run's own environment must carry the pin.
# EXPECTS: (1) en_US.UTF-8 in LC_ALL -> LC_ALL unset, LC_COLLATE C, LC_CTYPE and LANG en_US.UTF-8; LANG and LC_COLLATE
#   en_US.UTF-8 -> LC_COLLATE C, LANG kept; nothing set -> LC_COLLATE C. (2) exactly one pin line in each runner, above
#   its first gate run. A red names the case or the runner — the #278 shape: test_escape_triage and test_jtcores_twin
#   compared a locale-sorted list against a byte-ordered frozen one and went red on PILOT only (14z-200).
#
# SCOPE: the runners only. A gate run by hand (`sh tests/<gate>.sh`, a FREEZE=1 re-freeze) keeps the caller's locale;
#   of the nine gates whose FREEZE=1 write takes its order from a shell sort, test_charmap_current.sh pins that line
#   itself (census: build/agent208/t278/census278b.txt, local). Where en_US.UTF-8 is absent or sorts the probe as C does, (1)'s
#   sort probe prints a note and the environment check carries the verdict.
#
# MUST-FIRE: perturbed-copy: collate-dropped — a copy of tests/lib/collation.sh without its `LC_COLLATE=C` line must FAIL (1) (mode: (1) reads that copy)
# MUST-FIRE: perturbed-copy: lc-all-kept — a copy of tests/lib/collation.sh without its `unset LC_ALL` must FAIL (1): a caller's LC_ALL overrides LC_COLLATE (mode: (1) reads that copy)
# MUST-FIRE: perturbed-copy: runner-unpinned — a copy of tests/run_all_static.sh without its pin line must FAIL (2) (mode: (2) reads that copy)
# MUST-FIRE: perturbed-copy: lib-untracked — the tracked-library check run on a path git does not track (a runner sources the library only when it is there) must FAIL (2) (mode: (2) checks that path)
# MUST-FIRE: perturbed-copy: pin-late — a copy of tests/run_all_emulator.sh with its pin line moved to the end must FAIL (2) (mode: (2) reads that copy)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_runner_collation — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
PIN='[ ! -f "$REPO/tests/lib/collation.sh" ] || { . "$REPO/tests/lib/collation.sh"; vs_pin_collation; }'
RUNNERS="tests/run_all_static.sh tests/run_all_emulator.sh tests/run_battery_m2.sh"

# the perturbed copies
grep -v '^    LC_COLLATE=C; export LC_COLLATE$' tests/lib/collation.sh > "$W/collate_dropped.sh"
sed 's/^        _vs_lc="\$LC_ALL"; unset LC_ALL$/        _vs_lc="$LC_ALL"/' tests/lib/collation.sh > "$W/lc_all_kept.sh"
grep -vF "$PIN" tests/run_all_static.sh > "$W/run_all_static.sh"
{ grep -vF "$PIN" tests/run_all_emulator.sh; grep -F "$PIN" tests/run_all_emulator.sh; } > "$W/run_all_emulator.sh"
for _c in collate_dropped.sh lc_all_kept.sh; do
    cmp -s "$W/$_c" tests/lib/collation.sh && { echo "FAIL: test_runner_collation — the $_c copy equals the library (its line moved)"; exit 1; }
done
cmp -s "$W/run_all_static.sh" tests/run_all_static.sh && { echo "FAIL: test_runner_collation — no pin line to drop in tests/run_all_static.sh"; exit 1; }

env_check() {   # env_check <collation.sh> — the three caller locales; prints a line per case, exit 1 on a wrong one
    _lib="$1"; _bad=0
    while IFS='|' read -r _name _vars _want; do
        # shellcheck disable=SC2086
        _got="$(env -i PATH="$PATH" HOME="$HOME" $_vars sh -c '. "$1"; vs_pin_collation; printf "%s,%s,%s,%s" "${LC_ALL-unset}" "${LC_COLLATE-unset}" "${LC_CTYPE-unset}" "${LANG-unset}"' sh "$_lib")"
        if [ "$_got" = "$_want" ]; then echo "  ok    $_name: LC_ALL,LC_COLLATE,LC_CTYPE,LANG = $_got"
        else echo "  FAIL  $_name: LC_ALL,LC_COLLATE,LC_CTYPE,LANG = $_got, want $_want"; _bad=1; fi
    done <<EOF
LC_ALL=en_US.UTF-8|LC_ALL=en_US.UTF-8|unset,C,en_US.UTF-8,en_US.UTF-8
LANG and LC_COLLATE en_US.UTF-8|LANG=en_US.UTF-8 LC_COLLATE=en_US.UTF-8|unset,C,unset,en_US.UTF-8
nothing set||unset,C,unset,unset
EOF
    # the order itself, where this host's en_US.UTF-8 collates: a probe of case and punctuation (`a`/`B`, `_`/`-`/`.`/`:`)
    # that dictionary order and byte order sort differently on Linux and on macOS alike
    _p='a_c\nab\nB\na\na-c\na.c\na:c\n'
    _c="$(printf "$_p" | LC_ALL=C sort | tr '\n' ' ')"
    _u="$(printf "$_p" | LC_ALL=en_US.UTF-8 sort 2>/dev/null | tr '\n' ' ')"
    if [ -n "$_u" ] && [ "$_u" != "$_c" ]; then
        _o="$(env -i PATH="$PATH" HOME="$HOME" LC_ALL=en_US.UTF-8 sh -c '. "$1"; vs_pin_collation; printf "$2" | sort | tr "\n" " "' sh "$_lib" "$_p")"
        if [ "$_o" = "$_c" ]; then echo "  ok    under LC_ALL=en_US.UTF-8 (which sorts the probe '$_u' here) the pinned sort gives byte order: $_o"
        else echo "  FAIL  under LC_ALL=en_US.UTF-8 the pinned sort gives '$_o', not byte order '$_c'"; _bad=1; fi
    else
        echo "  note  this host has no collating en_US.UTF-8 (it sorts the probe as C does, or is absent): the environment lines above carry the verdict"
    fi
    return "$_bad"
}

tracked_check() {   # tracked_check <path> — the library is in git's index, so every checkout's runners find it
    if git ls-files --error-unmatch "$1" >/dev/null 2>&1; then echo "  ok    $1 is tracked, so a runner in this repo always finds it"
    else echo "  FAIL  $1 is not tracked: a checkout would run every runner unpinned"; return 1; fi
}

runner_check() {   # runner_check <file>... — one top-level pin line, above the first gate run; exit 1 on a wrong one
    _bad=0
    for _r in "$@"; do
        _n="$(grep -cxF "$PIN   # COLLATION-PIN: byte-order sort/ls for every gate (#278); absent only in a runner test's synthetic repo" "$_r")"
        _p="$(grep -nF "$PIN" "$_r" | head -1 | cut -d: -f1)"
        _e="$(grep -nE '^[^#]*(tests/"?\$\{?_?g\}?"?\.sh|static_job\.sh|static_pool\.py|^bat )' "$_r" | head -1 | cut -d: -f1)"
        if [ "$_n" = 1 ] && [ -n "$_p" ] && [ -n "$_e" ] && [ "$_p" -lt "$_e" ]; then echo "  ok    $_r: pin at line $_p, first gate run at line $_e"
        else echo "  FAIL  $_r: $_n top-level pin line(s), pin at line ${_p:-none}, first gate run at line ${_e:-none}"; _bad=1; fi
    done
    return "$_bad"
}

LIB=tests/lib/collation.sh; RUN="$RUNNERS"; LIBPATH=tests/lib/collation.sh
vs_ctl_is collate-dropped && LIB="$W/collate_dropped.sh"
vs_ctl_is lc-all-kept && LIB="$W/lc_all_kept.sh"
vs_ctl_is runner-unpinned && RUN="$W/run_all_static.sh"
vs_ctl_is pin-late && RUN="$W/run_all_emulator.sh"
vs_ctl_is lib-untracked && LIBPATH=tests/lib/collation_untracked.sh

echo "== 1. vs_pin_collation under three caller locales ($LIB)"
env_check "$LIB" || fail=1
echo "== 2. the runners call it before their first gate"
tracked_check "$LIBPATH" || fail=1
# shellcheck disable=SC2086
runner_check $RUN || fail=1
echo "== 3. this run's own environment"
if [ -n "${VS_COLLATION_PINNED:-}" ]; then
    if [ -z "${LC_ALL:-}" ] && [ "${LC_COLLATE:-}" = C ]; then echo "  ok    started by a runner: LC_ALL unset, LC_COLLATE=C"
    else echo "  FAIL  started by a runner, but LC_ALL='${LC_ALL:-}' LC_COLLATE='${LC_COLLATE:-}'"; fail=1; fi
else
    echo "  note  run by hand: the caller's locale (LC_ALL='${LC_ALL:-}' LC_COLLATE='${LC_COLLATE:-}') is kept, as designed"
fi
if [ -n "$VS_CTL" ]; then
    [ "$fail" = 1 ] && { echo "FAIL: test_runner_collation (control mode: the perturbed copy was caught)"; exit 1; }
    echo "FAIL: test_runner_collation — the perturbed copy passed"; exit 1
fi

echo "== 4. controls"
if env_check "$W/collate_dropped.sh" > "$W/c1.txt" 2>&1; then vs_ctl_dead collate-dropped "the library without LC_COLLATE=C passed"; fail=1
else vs_ctl_fired collate-dropped "$(grep -m1 'FAIL' "$W/c1.txt" | sed 's/^ *//')"; fi
if env_check "$W/lc_all_kept.sh" > "$W/c2.txt" 2>&1; then vs_ctl_dead lc-all-kept "the library keeping LC_ALL passed"; fail=1
else vs_ctl_fired lc-all-kept "$(grep -m1 'FAIL' "$W/c2.txt" | sed 's/^ *//')"; fi
if runner_check "$W/run_all_static.sh" > "$W/c3.txt" 2>&1; then vs_ctl_dead runner-unpinned "tests/run_all_static.sh without its pin passed"; fail=1
else vs_ctl_fired runner-unpinned "$(grep -m1 'FAIL' "$W/c3.txt" | sed 's/^ *//')"; fi
if runner_check "$W/run_all_emulator.sh" > "$W/c4.txt" 2>&1; then vs_ctl_dead pin-late "tests/run_all_emulator.sh with its pin last passed"; fail=1
else vs_ctl_fired pin-late "$(grep -m1 'FAIL' "$W/c4.txt" | sed 's/^ *//')"; fi
if tracked_check tests/lib/collation_untracked.sh > "$W/c5.txt" 2>&1; then vs_ctl_dead lib-untracked "an untracked library path passed"; fail=1
else vs_ctl_fired lib-untracked "$(grep -m1 'FAIL' "$W/c5.txt" | sed 's/^ *//')"; fi
[ "$fail" = 0 ] && echo "PASS: test_runner_collation" || echo "FAIL: test_runner_collation"
exit "$fail"
