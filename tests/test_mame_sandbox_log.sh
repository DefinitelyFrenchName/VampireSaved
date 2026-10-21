#!/bin/sh
# test_mame_sandbox_log.sh — with MAME_SANDBOX_LOG set, tools/run_mame.sh logs whether each run's sandbox already held
# an earlier run's MAME state (14z-205, #296 step 1), and it REFUSES such a run unless MAME_SANDBOX_REUSE=1 declares the
# reuse (14z-206, #296 step 2). ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHAT: tools/run_mame.sh's sandbox inventory — one line per run (UTC time, fresh|reused, the set, the sandbox, the
#   calling tests/<gate>.sh or "-"), the state read BEFORE the run writes anything; "reused" means an entry under cfg/,
#   nvram/, sta/ or diff/ of the sandbox; an empty directory a gate made itself, or a snap/ written by a capture, is
#   "fresh"; unset, nothing is written; the #196 fallback inventory still names its gate after the shared lookup; the
#   sandbox column is ABSOLUTE (a relative MAME_SANDBOX=s1 logs as <cwd>/s1); and step 2's refusal: a run into a
#   sandbox holding state exits 3 with a REFUSED line and never starts the binary, unless MAME_SANDBOX_REUSE=1.
# HOW: runs a copy of the wrapper (beside the real tests/lib it sources) with MAME_BIN a stub that writes an nvram file
#   into the -nvram_directory it is handed, as MAME does at exit, and reads the log: a mktemp sandbox, a new named
#   sandbox twice (the second run is #293's shape), a pre-made empty sandbox with an empty cfg/, a sandbox holding only
#   snap/, a run from a fixture tests/<gate>.sh, and a run with the log unset; then, log unset, a named sandbox run
#   three times (fresh, again, again with MAME_SANDBOX_REUSE=1), once more with MAME_SANDBOX_REUSE=0, a snap-only
#   sandbox, and a relative sandbox under a second log. The controls run a copy whose state read is neutered, and a
#   copy whose refusal is removed.
# EXPECTS: fresh, fresh then reused, fresh, fresh, the fixture's gate name in the gate column, no log at all when
#   unset, and the fallback line naming the fixture gate; the stub RUNS on a fresh sandbox, is REFUSED (exit 3, a
#   REFUSED line naming #296, the stub never started) on the second run, RUNS with MAME_SANDBOX_REUSE=1, is refused
#   with MAME_SANDBOX_REUSE=0, RUNS on a snap-only sandbox; the relative sandbox logs as <cwd>/s1.
# FOLLOWS: tools/run_mame.sh tests/lib/native_path.sh
#
# SHEET: none — a ROM-free check of the wrapper with a stub binary; no emulator leg at all
#
# MUST-FIRE: perturbed-copy: state-blind — a copy of tools/run_mame.sh whose state read never sees the sandbox's directories (each `ls -A` pointed at a path that does not exist) must log the second run in one sandbox as fresh and fail (mode: that copy is the wrapper tested)
# MUST-FIRE: shadow-tool: refusal-removed — a copy of tools/run_mame.sh whose step-2 refusal never triggers (its `if` made `if false`) must let the second run into a used sandbox start the binary, and fail the refusal checks (mode: that copy is the wrapper tested)
#
# WHY. #293: two gates named a MAME sandbox after part of a run's identity, so a later run booted on an earlier run's
# nvram and nothing failed; the #291 sheets found it by re-proving every leg on fresh sandboxes. A static census cannot
# see a variable sandbox key whose values repeat, so #296 reads it at run time: this inventory first (run over the
# emulator lanes to attribute every reuse), refusal by default after (step 2, 14z-206, once the one reuse the ERIS
# inventory found, audit_wide_phase_a's replay-keyed sandbox, was keyed by section and replay).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok() { echo "  ok    $*"; }
bad() { echo "  FAIL  $*"; fail=1; }

mkstub() {  # mkstub <path>: a MAME stand-in that writes an nvram file where it is told to, as MAME does at exit
    cat > "$1" <<'STUB'
#!/bin/sh
nv=""; while [ $# -gt 0 ]; do [ "$1" = -nvram_directory ] && nv="$2"; shift; done
[ -n "$nv" ] && mkdir -p "$nv/set" && echo x > "$nv/set/eeprom"
echo RAN
STUB
    chmod +x "$1"
}
# the perturbation, ONE function for the control and the mode
state_blind() {  # state_blind <src> <dst>: the state read never sees the sandbox's directories
    python3 - "$1" "$2" <<'PY'
import sys
s = open(sys.argv[1]).read()
a = '[ -n "$(ls -A "$SANDBOX/$_sbd" 2>/dev/null)" ] && _sbstate=reused'
assert a in s, "the state read moved: update state_blind"
open(sys.argv[2], "w").write(s.replace(a, '[ -n "$(ls -A "$SANDBOX/no_such_dir_$_sbd" 2>/dev/null)" ] && _sbstate=reused'))
PY
}
refusal_removed() {  # refusal_removed <src> <dst>: step 2's refusal never triggers
    python3 - "$1" "$2" <<'PY'
import sys
s = open(sys.argv[1]).read()
a = 'if [ "$_sbstate" = reused ] && [ "${MAME_SANDBOX_REUSE:-}" != 1 ]; then'
assert a in s, "the refusal moved: update refusal_removed"
open(sys.argv[2], "w").write(s.replace(a, 'if false; then'))
PY
}
mirror() {  # mirror <dir> [blind|norefuse]: a wrapper copy at <dir>/tools/run_mame.sh beside the real tests/lib it sources
    mkdir -p "$1/tools" "$1/tests"; ln -s "$REPO/tests/lib" "$1/tests/lib"
    case "${2:-}" in
        blind)    state_blind "$REPO/tools/run_mame.sh" "$1/tools/run_mame.sh" ;;
        norefuse) refusal_removed "$REPO/tools/run_mame.sh" "$1/tools/run_mame.sh" ;;
        *)        cp "$REPO/tools/run_mame.sh" "$1/tools/run_mame.sh" ;;
    esac
}
run() {  # run <wrapper> <root> <log or -> [sandbox or -]
    ( cd "$2" && env -u MAME_SANDBOX -u MAME_SANDBOX_LOG -u MAME_SANDBOX_REUSE ROMDIR="$2/roms" MAME_BIN="$2/stub" \
        ${3#-} ${4:+MAME_SANDBOX="$4"} sh "$1" vsavj > /dev/null 2>&1 )
}
runx() {  # runx <wrapper> <root> <out> [VAR=value ...]: the log unset, output to <out>; returns the wrapper's exit
    _w="$1"; _r="$2"; _o="$3"; shift 3
    ( cd "$_r" && env -u MAME_SANDBOX -u MAME_SANDBOX_LOG -u MAME_SANDBOX_REUSE ROMDIR="$_r/roms" MAME_BIN="$_r/stub" \
        "$@" sh "$_w" vsavj > "$_o" 2>&1 )
}
ran() { grep -qx RAN "$1"; }        # the stub started
refused() { grep -q '^REFUSED: .*MAME_SANDBOX_REUSE=1 (#296)' "$1"; }
state_of() {  # state_of <log> <n>: the state column of the log's n-th line
    sed -n "${2}p" "$1" | cut -f2
}
check() {  # check <wrapper> <root> — the assertions; returns 1 on any FAIL
    _f=0; R="$2"; rm -rf "$R"; mkdir -p "$R/roms"; mkstub "$R/stub"; L="$R/sb.log"
    run "$1" "$R" "MAME_SANDBOX_LOG=$L"
    [ "$(state_of "$L" 1)" = fresh ] && ok "a mktemp sandbox: fresh" || { bad "a mktemp sandbox: got '$(state_of "$L" 1)'"; _f=1; }
    run "$1" "$R" "MAME_SANDBOX_LOG=$L" "$R/sb_named"; run "$1" "$R" "MAME_SANDBOX_LOG=$L" "$R/sb_named"
    if [ "$(state_of "$L" 2)" = fresh ] && [ "$(state_of "$L" 3)" = reused ]; then ok "one named sandbox, two runs: fresh then reused (#293's shape)"
    else bad "one named sandbox, two runs: got '$(state_of "$L" 2)' then '$(state_of "$L" 3)'"; _f=1; fi
    mkdir -p "$R/sb_premade/cfg"; run "$1" "$R" "MAME_SANDBOX_LOG=$L" "$R/sb_premade"
    [ "$(state_of "$L" 4)" = fresh ] && ok "a pre-made sandbox with an empty cfg/: fresh" || { bad "a pre-made sandbox: got '$(state_of "$L" 4)'"; _f=1; }
    mkdir -p "$R/sb_snap/snap/vsavj"; echo x > "$R/sb_snap/snap/vsavj/0000.png"; run "$1" "$R" "MAME_SANDBOX_LOG=$L" "$R/sb_snap"
    [ "$(state_of "$L" 5)" = fresh ] && ok "a sandbox holding only snap/: fresh" || { bad "a snap-only sandbox: got '$(state_of "$L" 5)'"; _f=1; }
    mkdir -p "$R/tests"; printf '#!/bin/sh\nsh "%s" vsavj\n' "$1" > "$R/tests/fixture_gate.sh"
    ( cd "$R" && env -u MAME_SANDBOX MAME_SANDBOX_LOG="$L" MAME_FALLBACK_LOG="$R/fb.log" ROMDIR="$R/roms" MAME_BIN="$R/stub" \
        sh tests/fixture_gate.sh > /dev/null 2>&1 )
    g="$(sed -n 6p "$L" | cut -f5)"
    [ "$g" = tests/fixture_gate.sh ] && ok "the calling gate is named: $g" || { bad "the calling gate: got '$g'"; _f=1; }
    [ "$(wc -l < "$L" | tr -d ' ')" = 6 ] && ok "one line per run (6)" || { bad "lines: $(wc -l < "$L" | tr -d ' '), want 6"; _f=1; }
    run "$1" "$R" "-" "$R/sb_unlogged"
    [ "$(wc -l < "$L" | tr -d ' ')" = 6 ] && ok "MAME_SANDBOX_LOG unset: nothing logged" || { bad "unset: the log grew"; _f=1; }
    # the #196 fallback inventory shares the gate lookup: MAME_BIN unset (the pinned default absent here, so exit 2 after the line)
    ( cd "$R" && env -u MAME_BIN -u MAME_SANDBOX HOME="$R/home" MAME_FALLBACK_LOG="$R/fb.log" ROMDIR="$R/roms" \
        sh tests/fixture_gate.sh > /dev/null 2>&1 )
    [ "$(cut -f3 "$R/fb.log" 2>/dev/null | tail -1)" = tests/fixture_gate.sh ] && ok "the fallback inventory still names its gate" \
        || { bad "the fallback inventory: got '$(cat "$R/fb.log" 2>/dev/null)'"; _f=1; }
    # step 2 (#296): the refusal, with the log unset (the refusal does not depend on the inventory)
    O="$R/out"; S="$R/sb_r"
    runx "$1" "$R" "$O" MAME_SANDBOX="$S"; e=$?
    [ "$e" = 0 ] && ran "$O" && ok "refusal: a fresh named sandbox runs" || { bad "refusal: a fresh sandbox: exit $e"; _f=1; }
    runx "$1" "$R" "$O" MAME_SANDBOX="$S"; e=$?
    if [ "$e" = 3 ] && refused "$O" && ! ran "$O"; then ok "refusal: the second run into it is REFUSED, exit 3, the binary never started"
    else bad "refusal: the second run: exit $e, $(ran "$O" && echo started || echo 'not started'), '$(head -1 "$O")'"; _f=1; fi
    runx "$1" "$R" "$O" MAME_SANDBOX="$S" MAME_SANDBOX_REUSE=1; e=$?
    [ "$e" = 0 ] && ran "$O" && ok "refusal: MAME_SANDBOX_REUSE=1 declares the reuse and runs" || { bad "refusal: REUSE=1: exit $e"; _f=1; }
    runx "$1" "$R" "$O" MAME_SANDBOX="$S" MAME_SANDBOX_REUSE=0; e=$?
    [ "$e" = 3 ] && ! ran "$O" && ok "refusal: MAME_SANDBOX_REUSE=0 is no declaration" || { bad "refusal: REUSE=0: exit $e"; _f=1; }
    mkdir -p "$R/sb_snap2/snap/vsavj"; echo x > "$R/sb_snap2/snap/vsavj/0000.png"   # a NEW one: the stub wrote nvram into sb_snap
    runx "$1" "$R" "$O" MAME_SANDBOX="$R/sb_snap2"; e=$?
    [ "$e" = 0 ] && ran "$O" && ok "refusal: a sandbox holding only snap/ runs" || { bad "refusal: the snap-only sandbox: exit $e"; _f=1; }
    # the log's sandbox column is absolute: a relative MAME_SANDBOX=s1 (seven gates pass one) logs as <cwd>/s1
    ( cd "$R" && env -u MAME_SANDBOX_REUSE MAME_SANDBOX_LOG="$R/abs.log" MAME_SANDBOX=s1 ROMDIR="$R/roms" MAME_BIN="$R/stub" \
        sh "$1" vsavj > /dev/null 2>&1 )
    a="$(cut -f4 "$R/abs.log" 2>/dev/null)"
    [ "$a" = "$R/s1" ] && ok "a relative sandbox logs absolute: $a" || { bad "a relative sandbox logged '$a', want '$R/s1'"; _f=1; }
    return $_f
}

echo "== test_mame_sandbox_log: tools/run_mame.sh logs a sandbox that already held a run's state (#296 step 1) =="
if [ "${CONTROL:-}" = "state-blind" ]; then mirror "$W/m" blind
elif [ "${CONTROL:-}" = "refusal-removed" ]; then mirror "$W/m" norefuse
elif [ -n "${CONTROL:-}" ]; then echo "REFUSED: CONTROL=$CONTROL is not a mode of this gate"; exit 3
else mirror "$W/m"; fi
check "$W/m/tools/run_mame.sh" "$W/t" || fail=1

# the must-fire control: the state-blind copy must log the second run in one sandbox as fresh, and fail the checks
mirror "$W/c" blind; mkdir -p "$W/cr/roms"; mkstub "$W/cr/stub"
run "$W/c/tools/run_mame.sh" "$W/cr" "MAME_SANDBOX_LOG=$W/cr/l" "$W/cr/sb"; run "$W/c/tools/run_mame.sh" "$W/cr" "MAME_SANDBOX_LOG=$W/cr/l" "$W/cr/sb"
if [ -s "$W/cr/sb/nvram/set/eeprom" ] && [ "$(state_of "$W/cr/l" 2)" = fresh ] && ! ( check "$W/c/tools/run_mame.sh" "$W/cc" ) > "$W/ctl.log" 2>&1; then
    echo "CONTROL FIRED: state-blind — the second run on a sandbox holding nvram logged fresh, and the checks failed the copy"
else
    echo "CONTROL DEAD: state-blind — the blind copy logged '$(state_of "$W/cr/l" 2)' or passed the checks"; fail=1
fi
# the must-fire control: the refusal-removed copy must start the binary on the second run into one sandbox, and fail
mirror "$W/n" norefuse; mkdir -p "$W/nr/roms"; mkstub "$W/nr/stub"
runx "$W/n/tools/run_mame.sh" "$W/nr" "$W/nr/o1" MAME_SANDBOX="$W/nr/sb"
runx "$W/n/tools/run_mame.sh" "$W/nr" "$W/nr/o2" MAME_SANDBOX="$W/nr/sb"; ne=$?
if [ "$ne" = 0 ] && ran "$W/nr/o2" && ! ( check "$W/n/tools/run_mame.sh" "$W/nc" ) > "$W/nctl.log" 2>&1; then
    echo "CONTROL FIRED: refusal-removed — the second run into a used sandbox started the binary, and the checks failed the copy"
else
    echo "CONTROL DEAD: refusal-removed — the copy's second run exited $ne, or the checks passed it"; fail=1
fi

if [ "$fail" -eq 0 ]; then echo "PASS: test_mame_sandbox_log — every run says whether its sandbox held an earlier run's state, and a run into one is refused unless declared"
else echo "FAIL: test_mame_sandbox_log"; exit 1; fi
