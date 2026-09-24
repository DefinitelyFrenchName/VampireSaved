#!/bin/sh
# test_emulator_staleness.sh — WHICH EMULATOR GATES' GREEN IS STALE, and is any row eating
# its cap (GitHub #171 slices Q4 and Q5, ruled 2026-09-24: "NOTE at session, FAIL at
# freeze/release"; "Half the cap" — DECISIONS_HISTORY.md "Ruled 2026-09-24 (14z-180) —
# #171 gate qualification"). ci_portable: no ROM, no emulator; reads a run directory under
# build/ when one exists and a scratch git repository for its controls, ~3 s.
#
# WHAT: over the newest emulator-tier run that recorded its commit (build/emu_*/commit.txt,
#   written by tests/run_all_emulator.sh since 14z-180): every gate that PASSED there and
#   has since had a path its `# FOLLOWS:` header declares move — committed, in the working
#   tree or untracked — is STALE; and no results row's seconds reach HALF its cap (the
#   registry's 7th column, else 5,400 s; a control row shares its gate's cap).
# HOW: tools/audit_emulator_staleness.py (importing the one FOLLOWS reader) diffs the
#   recorded commit against the tree and matches the moved paths to each passed gate's
#   declaration; the cadence comes from VS_CADENCE (exported by tests/run_all_static.sh,
#   default session). Section 2 proves the instrument on a scratch git repository: a
#   planted run whose declared replay moved must name its gate, an unmoved one must not,
#   an undeclared gate must be named as unjudgeable, and a planted row at 0.5 of its cap
#   must fail; the controls run the tool at freeze cadence over the moved plant and over
#   the headroom plant.
# EXPECTS: at session cadence a PASS whatever is stale (the stale list is a NOTE and the
#   command to retire it: tests/run_all_emulator.sh --stale); at freeze or release cadence
#   a stale or undeclared passed gate is a FAIL; a row at or above half its cap is a FAIL
#   at every cadence; no run of record is a NOTE at session and a FAIL at freeze/release.
#
# MUST-FIRE: known-bad: moved-input — the scratch run whose declared replay was edited after the recorded commit, judged at freeze cadence, must FAIL naming its gate (mode: that verdict is this gate's)
# MUST-FIRE: known-bad: headroom-eaten — the scratch run with one row's seconds planted at 0.5 of its cap must FAIL naming the row (mode: that verdict is this gate's)
#
# WHY: at the 14z-174 release tier the MiSTer lane's green was carried on inputs checked
# by hand; shape 2 of docs/project/gate_qualification_scope.md is "a gate whose input moved
# after it last ran". This gate would have read "3 gates stale since 14z-171" at that
# close. Q5: the release run's own contention roughly halved a 300 s control's headroom;
# 0.5 is where a measured number stops being a safe cap.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
TOOL=tools/audit_emulator_staleness.py
CAD="${VS_CADENCE:-session}"
W="$(mktemp -d "${TMPDIR:-/tmp}/estale.XXXXXX")"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

# THE SCRATCH REPOSITORY: two gates in the registry, one declaring, one not; a run that
# PASSED both, recorded on the base commit; then the declared replay moves.
R="$W/repo"; mkdir -p "$R/tests/replays" "$R/tools" "$R/build/emu_plant"
cat > "$R/tests/g_follows.sh" <<'EOF'
#!/bin/sh
# g_follows.sh — a stub emulator gate
# FOLLOWS: tests/replays/x.rpl tools/t.py
: "${MAME_BIN:-}"
EOF
cat > "$R/tests/g_still.sh" <<'EOF'
#!/bin/sh
# g_still.sh — a stub whose inputs never move
# FOLLOWS: tools/never.py
: "${MAME_BIN:-}"
EOF
printf '#!/bin/sh\n: "${MAME_BIN:-}"\n' > "$R/tests/g_undeclared.sh"
printf 'g_follows\tmame\trelease\tromset\t-\tstub\t600\ng_still\tmame\trelease\tromset\t-\tstub\ng_undeclared\tmame\trelease\tromset\t-\tstub\n' > "$R/tests/ci_emulator.tsv"
echo "1 wait" > "$R/tests/replays/x.rpl"; echo "print(1)" > "$R/tools/t.py"; echo "print(0)" > "$R/tools/never.py"
( cd "$R" && git init -q && git -c user.name=t -c user.email=t@t add -A . && git -c user.name=t -c user.email=t@t commit -q -m base ) \
    || { echo "FAIL: could not make the scratch repository"; exit 1; }
BASE="$(cd "$R" && git rev-parse HEAD)"
plant() {  # plant <dir> <seconds for g_follows>
    mkdir -p "$1"; echo "$BASE" > "$1/commit.txt"
    printf 'gate\tlane\tscope\tverdict\tseconds\tdetail\ng_follows\tmame\trelease\tPASS\t%s\t\ng_still\tmame\trelease\tPASS\t12\t\ng_undeclared\tmame\trelease\tPASS\t5\t\ng_follows@ctl\tmame\trelease\tPASS\t20\t\n' "$2" > "$1/results.tsv"
}
plant "$R/build/emu_plant" 100
echo "2 wait" >> "$R/tests/replays/x.rpl"          # the declared input moves in the working tree
plant "$R/build/emu_headroom" 300                   # 300 of a 600 s cap: exactly half
tool_on() { python3 "$TOOL" --root "$R" --repo "$R" --run "$R/build/$1" --cadence "$2" > "$W/o_$1_$2.txt" 2>&1; echo $?; }

if [ -n "$VS_CTL" ]; then
    case "$VS_CTL" in
        moved-input)    rc="$(tool_on emu_plant freeze)";   f="$W/o_emu_plant_freeze.txt" ;;
        headroom-eaten) rc="$(tool_on emu_headroom session)"; f="$W/o_emu_headroom_session.txt" ;;
    esac
    echo "MODE: control $VS_CTL — the tool's verdict on the planted run is this gate's verdict"
    sed 's/^/  /' "$f"
    [ "$rc" = 0 ] && { echo "PASS"; exit 0; } || { echo "FAIL"; exit 1; }
fi

echo "== 1. the tree's newest run of record, cadence $CAD"
if python3 "$TOOL" --cadence "$CAD" > "$W/real.txt" 2>&1; then
    sed 's/^/  /' "$W/real.txt"
else
    rc=$?
    sed 's/^/  /' "$W/real.txt"
    if [ "$rc" = 2 ]; then
        [ "$CAD" = session ] && ok "NOTE: no recorded run yet — the next tests/run_all_emulator.sh writes commit.txt" \
                             || bad "no run of record at $CAD cadence — a freeze or release runs the tier on the commit it builds from"
    else
        bad "the run of record has a stale or undeclared passed gate, or a row at half its cap, at $CAD cadence"
    fi
fi

echo "== 2. the instrument, on the scratch repository"
rc="$(tool_on emu_plant session)"; f="$W/o_emu_plant_session.txt"
grep -q 'g_follows: tests/replays/x.rpl' "$f" && ok "the moved replay names its gate (g_follows)" || { bad "g_follows not named for its moved replay"; sed 's/^/        /' "$f"; }
grep -q 'g_still' "$f" && grep 'g_still' "$f" | grep -qv 'FOLLOWS' && bad "g_still named though nothing it follows moved" || ok "an unmoved gate (g_still) is not named"
grep -q 'without a FOLLOWS declaration.*g_undeclared' "$f" && ok "the undeclared passed gate is named as unjudgeable" || bad "g_undeclared not named"
[ "$rc" = 0 ] && ok "at session cadence the stale list is a NOTE (exit 0)" || bad "session cadence exited $rc"
grep -q 'run_all_emulator.sh --stale' "$f" && ok "the readout names the command that retires it" || bad "no --stale hint"
rc="$(tool_on emu_plant freeze)"
[ "$rc" = 1 ] && grep -q 'FAIL: 1 stale' "$W/o_emu_plant_freeze.txt" && ok "at freeze cadence the same run FAILs" || bad "freeze cadence exited $rc"
rc="$(tool_on emu_headroom session)"
[ "$rc" = 1 ] && grep -q 'g_follows: 300 s of 600 s (0.50)' "$W/o_emu_headroom_session.txt" && ok "a row at exactly half its cap FAILs, at session cadence too" \
                                                                                           || { bad "headroom plant: exit $rc"; sed 's/^/        /' "$W/o_emu_headroom_session.txt"; }
grep -q 'g_follows@ctl' "$W/o_emu_headroom_session.txt" && bad "the control row (20 s of 600) was flagged" || ok "a control row under half its gate's cap is not flagged"
names="$(python3 "$TOOL" --root "$R" --repo "$R" --run "$R/build/emu_plant" --names)"
[ "$names" = "g_follows" ] && ok "--names prints exactly the stale gate (what run_all_emulator.sh --stale runs)" || bad "--names printed '$names'"

echo "== 3. controls"
rc="$(tool_on emu_plant freeze)"
[ "$rc" = 1 ] && vs_ctl_fired moved-input "the moved plant FAILs at freeze cadence (exit 1)" || { vs_ctl_dead moved-input "exit $rc"; fail=1; }
rc="$(tool_on emu_headroom session)"
[ "$rc" = 1 ] && vs_ctl_fired headroom-eaten "the half-cap plant FAILs (exit 1)" || { vs_ctl_dead headroom-eaten "exit $rc"; fail=1; }

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
