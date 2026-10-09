#!/bin/sh
# test_emulator_staleness.sh — WHICH EMULATOR GATES' GREEN IS STALE, and is any row eating
# its cap (GitHub #171 slices Q4 and Q5, ruled 2026-09-24: "NOTE at session, FAIL at
# freeze/release"; "Half the cap" — DECISIONS_HISTORY.md "Ruled 2026-09-24 (14z-180) —
# #171 gate qualification"). ci_portable: no ROM, no emulator; reads a run directory under
# build/ when one exists and a scratch git repository for its controls, ~3 s.
#
# WHAT: over each gate's NEWEST ROW across every emulator-tier run that recorded its commit
#   (build/emu_*/commit.txt, written by tests/run_all_emulator.sh since 14z-180; per gate
#   since 14z-192, #211 — a newer partial or empty run no longer hides a gate): every gate whose newest row PASSED and
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
#   Section 2b (14z-192, #211): with no --run the run of record is PER GATE — each gate's
#   newest row over every recorded run — so a newer partial run (only g_still) and a newer
#   EMPTY run (the 0-gate --stale run that printed GREEN) must not hide g_follows.
#   Sections 2c-2e (14z-192, maintainer-ruled 2026-10-06 "Fix the audit now, then re-run"), on a third
#   scratch repository with a real submodule: 2c a path dirty at the run's start whose content is
#   unchanged since (a file by its recorded sha256, a submodule by run_record's index-blind
#   content_sha256 — the patched emu/fbneo's case) is NOT stale, and the same path with different
#   content is; 2d at freeze cadence a stale row outside what a freeze selects (scope `out`) is a NOTE,
#   and at release cadence a FAIL; 2e a gate whose newest row is FAIL fails at freeze cadence, is a
#   NOTE at session, and is listed by --names.
#   Section 2f (14z-195, #237), on a fourth scratch repository: the registry is judged PER ROW — a gate
#   whose own row changed (its description) is stale on tests/ci_emulator.tsv, a gate for which only
#   another row and a comment changed is not, a gate whose code reads the registry is stale on any
#   change, and a run that recorded the registry dirty keeps the whole-file rule.
# EXPECTS: at session cadence a PASS whatever is stale (the stale list is a NOTE and the
#   command to retire it: tests/run_all_emulator.sh --stale); at freeze or release cadence
#   a stale or undeclared passed gate is a FAIL; a row at or above half its cap is a FAIL
#   at every cadence; no run of record is a NOTE at session and a FAIL at freeze/release.
#
# MUST-FIRE: known-bad: moved-input — the scratch run whose declared replay was edited after the recorded commit, judged at freeze cadence, must FAIL naming its gate (mode: that verdict is this gate's)
# MUST-FIRE: known-bad: headroom-eaten — the scratch run with one row's seconds planted at 0.5 of its cap must FAIL naming the row (mode: that verdict is this gate's)
# MUST-FIRE: shadow-tool: keys-ignored — a copy of the tool that never consults the run's record (every moved path moved, the pre-14z-192 rule) must name the unchanged dirty file and submodule stale (mode: that copy is the tool section 2c runs; section 2c must fail)
# MUST-FIRE: shadow-tool: scope-ignored — a copy of the tool whose freeze cadence judges every row must FAIL the out-of-scope plant (mode: that copy is the tool section 2d runs; section 2d must fail)
# MUST-FIRE: known-bad: red-newest — the scratch run whose newest row for g_red is FAIL, judged at freeze cadence, must FAIL naming it (mode: that verdict is this gate's)
# MUST-FIRE: shadow-tool: ondemand-judged — a copy of the tool without the ondemand exemption must FAIL the ondemand g_out at release cadence (mode: that copy is the tool section 2d2 runs; section 2d2 must fail; 14z-196)
# MUST-FIRE: shadow-tool: whole-registry — a copy of the tool that judges tests/ci_emulator.tsv as one file again (the pre-#237 rule) must name g_other stale though only g_own's row and a comment moved (mode: that copy is the tool section 2f runs; section 2f must fail)
# MUST-FIRE: shadow-tool: newest-dir — a copy of the tool that reads only the NEWEST run directory (the pre-#211 run of record) must miss g_follows behind a newer partial run and a newer empty one (mode: that copy is the tool section 2b runs; section 2b must fail)
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

# THE PER-GATE ROOT (section 2b): the same repository, the older full run, then a newer
# run holding only g_still and a newer EMPTY one; mtimes ordered explicitly.
R2="$W/repo2"; cp -R "$R" "$R2"; rm -rf "$R2/build"/emu_*
plant "$R2/build/emu_a_full" 100
mkdir -p "$R2/build/emu_b_partial" "$R2/build/emu_c_empty"
echo "$BASE" > "$R2/build/emu_b_partial/commit.txt"; echo "$BASE" > "$R2/build/emu_c_empty/commit.txt"
printf 'gate\tlane\tscope\tverdict\tseconds\tdetail\ng_still\tmame\trelease\tPASS\t12\t\n' > "$R2/build/emu_b_partial/results.tsv"
printf 'gate\tlane\tscope\tverdict\tseconds\tdetail\n' > "$R2/build/emu_c_empty/results.tsv"
python3 - "$R2/build" <<'PY'
import os, sys
for i, d in enumerate(("emu_a_full", "emu_b_partial", "emu_c_empty")):
    t = 1700000000 + 100 * i
    os.utime(os.path.join(sys.argv[1], d, "results.tsv"), (t, t))
PY
# the shadow: newest_rows() reading only the newest directory, as the run of record was
sed 's|^    for d in runs:$|    for d in runs[-1:]:|' "$TOOL" > "$W/tool_newestdir.py"
cmp -s "$TOOL" "$W/tool_newestdir.py" && { echo "FAIL: could not build the newest-dir shadow — the loop moved"; exit 1; }
# The shadow copies live in $W and import their siblings: tools/ goes on the path rather than copies of them.
# (Until 14z-192 the copy got gate_follows.py alone, which imports gate_descriptions: the newest-dir copy
# CRASHED on import, and its control read as FIRED because a crash names no gate. A control's copy must now
# print its verdict header before its silence counts — docs/project/gotchas.md "A CONTROL WHOSE PERTURBATION
# STEP CRASHES CAN STILL READ AS FIRED".)
export PYTHONPATH="$REPO/tools${PYTHONPATH:+:$PYTHONPATH}"
TOOL2="$TOOL"; vs_ctl_is newest-dir && TOOL2="$W/tool_newestdir.py"
pergate() { python3 "$1" --root "$R2" --repo "$R2" --cadence freeze > "$2" 2>&1; echo $?; }

# THE RECORD ROOT (sections 2c-2e, 14z-192): a submodule, gates following a file and the submodule, one
# out-of-scope gate and one whose newest row is red; runs recorded with tools/run_record.py's own record.
R3="$W/repo3"; S3="$W/sub3"; mkdir -p "$R3/tests" "$R3/tools" "$S3"
CFG="-c user.name=t -c user.email=t@t -c protocol.file.allow=always"
( cd "$S3" && git init -q && echo "x" > lib.txt && git $CFG add -A && git $CFG commit -q -m s ) || { echo "FAIL: scratch submodule"; exit 1; }
for g in g_key g_sub g_out g_red; do
    case $g in g_key) fl="tools/k.py" ;; g_sub) fl="emu/sub" ;; g_out) fl="tools/o.py" ;; g_red) fl="tools/r.py" ;; esac
    printf '#!/bin/sh\n# %s.sh — a stub\n# FOLLOWS: %s\n: "${MAME_BIN:-}"\n' "$g" "$fl" > "$R3/tests/$g.sh"
done
printf 'g_key\tmame\trelease\tromset\t-\tstub\ng_sub\tfbneo\trelease\tromset\t-\tstub\ng_out\tmame\tout\tromset\t-\tstub\ng_red\tmame\trelease\tromset\t-\tstub\n' > "$R3/tests/ci_emulator.tsv"
for f in k o r; do echo "print(0)" > "$R3/tools/$f.py"; done
( cd "$R3" && git init -q && git $CFG add -A && git $CFG commit -q -m base && git $CFG submodule add -q "$S3" emu/sub >/dev/null 2>&1 \
  && git $CFG commit -q -m sub ) || { echo "FAIL: scratch record repository"; exit 1; }
B3="$(cd "$R3" && git rev-parse HEAD)"
echo "print(1)" > "$R3/tools/k.py"; echo "y" > "$R3/emu/sub/lib.txt"; echo "new" > "$R3/emu/sub/patch.txt"   # dirty at the run's start
rec3() {  # rec3 <dir> <g_key verdict> <g_red verdict> — a run whose record is taken NOW
    mkdir -p "$R3/build/$1"; echo "$B3" > "$R3/build/$1/commit.txt"
    printf 'gate\tlane\tscope\tverdict\tseconds\tdetail\ng_key\tmame\trelease\t%s\t10\t\ng_sub\tfbneo\trelease\tPASS\t10\t\ng_out\tmame\tout\tPASS\t10\t\ng_red\tmame\trelease\t%s\t10\t\n' "$2" "$3" > "$R3/build/$1/results.tsv"
    python3 - "$R3" "$R3/build/$1/run_record_start.json" <<'PY'      # tools/run_record.py's own record, of R3
import json, sys; sys.path.insert(0, "tools"); import run_record as rr
json.dump(rr.build(sys.argv[1], phase="start"), open(sys.argv[2], "w"))
PY
}
rec3 emu_rec PASS PASS
( cd "$R3/emu/sub" && git $CFG add patch.txt )                      # staged now, untracked at the run: same content
rec3 emu_red PASS FAIL
echo "print(2)" > "$R3/tools/o.py"                                 # g_out's input moves after both runs
cp "$TOOL" "$W/tool_keysignored.py"; sed -i.bak 's|^        hits = \[h for h in hits if not same_as_run(repo, h, recs\[d\])\]   # the run already had it (14z-192)$|        pass  # CONTROL keys-ignored|' "$W/tool_keysignored.py"
cp "$TOOL" "$W/tool_scopeignored.py"; sed -i.bak 's|^        return (row.get("cadence"), row.get("scope")) == FREEZE_SELECTS$|        return True  # CONTROL scope-ignored|' "$W/tool_scopeignored.py"
cmp -s "$TOOL" "$W/tool_keysignored.py" && { echo "FAIL: could not build the keys-ignored shadow — the line moved"; exit 1; }
cmp -s "$TOOL" "$W/tool_scopeignored.py" && { echo "FAIL: could not build the scope-ignored shadow — the line moved"; exit 1; }
TOOL3K="$TOOL"; vs_ctl_is keys-ignored && TOOL3K="$W/tool_keysignored.py"
TOOL3S="$TOOL"; vs_ctl_is scope-ignored && TOOL3S="$W/tool_scopeignored.py"
on3() {  # on3 <tool> <run dir> <cadence> <out> — exit code
    python3 "$1" --root "$R3" --repo "$R3" --run "$R3/build/$2" --cadence "$3" > "$4" 2>&1; echo $?; }

# THE REGISTRY ROOT (section 2f, 14z-195, #237): three gates, one of which reads the registry in its code;
# a run recorded on the base commit, then g_own's description and a comment change; a second run whose
# commit.txt names the registry dirty.
R4="$W/repo4"; mkdir -p "$R4/tests" "$R4/tools"
for g in g_own g_other g_reads; do printf '#!/bin/sh\n# %s.sh — a stub\n# FOLLOWS: tools/%s.py\n: "${MAME_BIN:-}"\n' "$g" "$g" > "$R4/tests/$g.sh"; echo "print(0)" > "$R4/tools/$g.py"; done
echo 'cut -f1 tests/ci_emulator.tsv > /dev/null' >> "$R4/tests/g_reads.sh"
printf '# a registry\ng_own\tmame\trelease\tromset\t-\tfirst description\ng_other\tmame\trelease\tromset\t-\tstub\ng_reads\tmame\trelease\tromset\t-\tstub\n' > "$R4/tests/ci_emulator.tsv"
( cd "$R4" && git init -q && git $CFG add -A && git $CFG commit -q -m base ) || { echo "FAIL: scratch registry repository"; exit 1; }
B4="$(cd "$R4" && git rev-parse HEAD)"
for run in emu_reg emu_regdirty; do
    mkdir -p "$R4/build/$run"; echo "$B4" > "$R4/build/$run/commit.txt"
    printf 'gate\tlane\tscope\tverdict\tseconds\tdetail\ng_own\tmame\trelease\tPASS\t10\t\ng_other\tmame\trelease\tPASS\t10\t\ng_reads\tmame\trelease\tPASS\t10\t\n' > "$R4/build/$run/results.tsv"
done
echo "tests/ci_emulator.tsv" >> "$R4/build/emu_regdirty/commit.txt"
sed -i.bak -e 's/first description/second description/' -e 's/^# a registry$/# a registry, re-commented/' "$R4/tests/ci_emulator.tsv"; rm -f "$R4/tests/ci_emulator.tsv.bak"
sed 's|^        if gf.REGISTRY in hits and not registry_row_moved(root, repo, c, g, d, recs\[d\]):$|        if False:  # CONTROL whole-registry|' "$TOOL" > "$W/tool_wholereg.py"
cmp -s "$TOOL" "$W/tool_wholereg.py" && { echo "FAIL: could not build the whole-registry shadow — the line moved"; exit 1; }
TOOL4="$TOOL"; vs_ctl_is whole-registry && TOOL4="$W/tool_wholereg.py"
sed 's|^        if reg_all.get(g, {}).get("scope") == "ondemand":$|        if False:  # CONTROL ondemand-judged|' "$TOOL" > "$W/tool_ondjudged.py"
cmp -s "$TOOL" "$W/tool_ondjudged.py" && { echo "FAIL: could not build the ondemand-judged shadow — the line moved"; exit 1; }
TOOL3O="$TOOL"; vs_ctl_is ondemand-judged && TOOL3O="$W/tool_ondjudged.py"
on4() {  # on4 <tool> <run dir> <out> — exit code, at release cadence
    python3 "$1" --root "$R4" --repo "$R4" --run "$R4/build/$2" --cadence release > "$3" 2>&1; echo $?; }

if [ -n "$VS_CTL" ] && [ "$VS_CTL" != newest-dir ] && [ "$VS_CTL" != keys-ignored ] && [ "$VS_CTL" != scope-ignored ] && [ "$VS_CTL" != whole-registry ] && [ "$VS_CTL" != ondemand-judged ]; then
    case "$VS_CTL" in
        moved-input)    rc="$(tool_on emu_plant freeze)";   f="$W/o_emu_plant_freeze.txt" ;;
        headroom-eaten) rc="$(tool_on emu_headroom session)"; f="$W/o_emu_headroom_session.txt" ;;
        red-newest)     rc="$(on3 "$TOOL" emu_red freeze "$W/o_red_ctl.txt")"; f="$W/o_red_ctl.txt" ;;
    esac
    echo "MODE: control $VS_CTL — the tool's verdict on the planted run is this gate's verdict"
    sed 's/^/  /' "$f"
    [ "$rc" = 0 ] && { echo "PASS"; exit 0; } || { echo "FAIL"; exit 1; }
fi

echo "== 1. the tree's run of record (each gate's newest row), cadence $CAD"
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

echo "== 2b. the run of record is per gate (14z-192, #211)"
rc="$(pergate "$TOOL2" "$W/o_pergate.txt")"
if [ "$rc" = 1 ] && grep -q 'g_follows: tests/replays/x.rpl' "$W/o_pergate.txt" && grep -q '3 recorded run' "$W/o_pergate.txt"; then
    ok "behind a newer partial run and a newer empty one, g_follows (newest row in the older run) is still named stale; freeze cadence FAILs"
else
    bad "per-gate run of record: exit $rc"; sed 's/^/        /' "$W/o_pergate.txt"
fi
grep -q 'g_still' "$W/o_pergate.txt" && grep 'g_still' "$W/o_pergate.txt" | grep -qv 'FOLLOWS' && bad "g_still named though nothing it follows moved" || ok "g_still (newest row in the partial run, nothing moved) is not named"

echo "== 2c. a path the run already had is judged by content (14z-192)"
rc="$(on3 "$TOOL3K" emu_rec freeze "$W/o_rec.txt")"
grep -q 'g_key' "$W/o_rec.txt" && bad "g_key named stale though tools/k.py holds what the run measured" || ok "a file dirty at the run's start and unchanged since is not stale (g_key)"
grep -q 'g_sub' "$W/o_rec.txt" && bad "g_sub named stale though the submodule's content is what the run measured (a file then untracked, now staged)" \
    || ok "a submodule whose content is unchanged since the run is not stale, the index notwithstanding (g_sub)"
[ "$rc" = 0 ] && ok "the record run is green at freeze cadence (exit 0)" || { bad "the record run exited $rc"; sed 's/^/        /' "$W/o_rec.txt"; }
echo "print(3)" > "$R3/tools/k.py"; echo "z" > "$R3/emu/sub/lib.txt"
rc="$(on3 "$TOOL" emu_rec freeze "$W/o_rec2.txt")"
grep -q 'g_key: tools/k.py' "$W/o_rec2.txt" && grep -q 'g_sub: emu/sub' "$W/o_rec2.txt" && [ "$rc" = 1 ] \
    && ok "the same paths with new content are stale, and freeze cadence FAILs" || { bad "changed content not named (exit $rc)"; sed 's/^/        /' "$W/o_rec2.txt"; }
echo "print(1)" > "$R3/tools/k.py"; echo "y" > "$R3/emu/sub/lib.txt"
echo "== 2d. a freeze judges what a freeze runs (14z-192)"
rc="$(on3 "$TOOL3S" emu_red freeze "$W/o_scope.txt")"
if grep -q 'NOTE: 1 stale gate(s).*outside what a freeze runs' "$W/o_scope.txt" && grep -A1 'outside what a freeze runs' "$W/o_scope.txt" | grep -q 'g_out: tools/o.py'; then
    ok "at freeze cadence the out-of-scope g_out is a NOTE, not a FAIL"
else
    bad "g_out at freeze cadence"; sed 's/^/        /' "$W/o_scope.txt"
fi
rc="$(on3 "$TOOL" emu_red release "$W/o_scope_rel.txt")"
grep -q 'FAIL: .*stale' "$W/o_scope_rel.txt" && grep -q 'g_out: tools/o.py' "$W/o_scope_rel.txt" && [ "$rc" = 1 ] \
    && ok "at release cadence the same row FAILs" || { bad "g_out at release cadence (exit $rc)"; sed 's/^/        /' "$W/o_scope_rel.txt"; }
echo "== 2d2. an ONDEMAND row is never judged, even at release cadence (14z-196)"
R3o="$W/repo3o"; cp -R "$R3" "$R3o"
sed -i.bak 's/^g_out\tmame\tout\t/g_out\tmame\tondemand\t/' "$R3o/tests/ci_emulator.tsv"; rm -f "$R3o/tests/ci_emulator.tsv.bak"
grep -q "^g_out	mame	ondemand	" "$R3o/tests/ci_emulator.tsv" || bad "could not plant the ondemand row"
python3 "$TOOL3O" --root "$R3o" --repo "$R3o" --run "$R3o/build/emu_red" --cadence release > "$W/o_ond.txt" 2>&1 || true
if grep -A3 '^  NOTE: .*stale gate' "$W/o_ond.txt" | grep -q 'g_out: '; then
    if grep -A3 '^  FAIL: .*stale gate' "$W/o_ond.txt" | grep -q 'g_out: '; then bad "g_out (ondemand) FAILed at release"; else ok "at release cadence the ondemand g_out is a NOTE, never a FAIL"; fi
else bad "the ondemand g_out was not reported as a NOTE"; sed 's/^/        /' "$W/o_ond.txt"; fi

echo "== 2e. a red newest row is judged (14z-192)"
rc="$(on3 "$TOOL" emu_red freeze "$W/o_red.txt")"
grep -q 'FAIL: 1 gate(s) whose newest row is red' "$W/o_red.txt" && grep -q 'g_red: FAIL' "$W/o_red.txt" && [ "$rc" = 1 ] \
    && ok "a FAIL newest row FAILs at freeze cadence" || { bad "red newest row at freeze (exit $rc)"; sed 's/^/        /' "$W/o_red.txt"; }
rc="$(on3 "$TOOL" emu_red session "$W/o_red_s.txt")"
grep -q 'NOTE: 1 gate(s) whose newest row is red' "$W/o_red_s.txt" && [ "$rc" = 0 ] && ok "at session cadence it is a NOTE (exit 0)" || { bad "red newest row at session (exit $rc)"; sed 's/^/        /' "$W/o_red_s.txt"; }
names3="$(python3 "$TOOL" --root "$R3" --repo "$R3" --run "$R3/build/emu_red" --names | tr '\n' ' ')"
case " $names3 " in *" g_red "*) ok "--names lists the red gate, so --stale re-runs it ($names3)" ;; *) bad "--names printed '$names3'" ;; esac

echo "== 2f. the registry is judged per row (14z-195, #237)"
rc="$(on4 "$TOOL4" emu_reg "$W/o_reg.txt")"
grep -q 'g_own: tests/ci_emulator.tsv' "$W/o_reg.txt" && ok "a gate whose own row changed (its description) is stale on the registry (g_own)" \
    || { bad "g_own not named for its changed row"; sed 's/^/        /' "$W/o_reg.txt"; }
grep -q 'g_other' "$W/o_reg.txt" && { bad "g_other named stale though only g_own's row and a comment moved"; sed 's/^/        /' "$W/o_reg.txt"; } \
    || ok "a gate for which only another row and a comment moved is not stale (g_other)"
grep -q 'g_reads: tests/ci_emulator.tsv' "$W/o_reg.txt" && ok "a gate whose code reads the registry is stale on any change (g_reads)" \
    || { bad "g_reads not named"; sed 's/^/        /' "$W/o_reg.txt"; }
[ "$rc" = 1 ] && ok "release cadence FAILs on the two stale gates (exit 1)" || bad "the registry plant exited $rc at release cadence"
rc="$(on4 "$TOOL" emu_regdirty "$W/o_regdirty.txt")"
grep -q 'g_other: tests/ci_emulator.tsv' "$W/o_regdirty.txt" && ok "a run that recorded the registry dirty keeps the whole-file rule (g_other stale)" \
    || { bad "g_other not stale on the dirty-registry run (exit $rc)"; sed 's/^/        /' "$W/o_regdirty.txt"; }

echo "== 3. controls"
if [ "$VS_CTL" = ondemand-judged ]; then
    vs_ctl_fired ondemand-judged "section 2d2 ran the copy without the ondemand exemption (mode)"
else
    python3 "$W/tool_ondjudged.py" --root "$R3o" --repo "$R3o" --run "$R3o/build/emu_red" --cadence release > "$W/o_ondjudged.txt" 2>&1 || true
    grep -A3 '^  FAIL: .*stale gate' "$W/o_ondjudged.txt" | grep -q 'g_out: ' \
        && vs_ctl_fired ondemand-judged "the copy without the exemption FAILs the ondemand g_out at release" || { vs_ctl_dead ondemand-judged "the exemption-free copy did not FAIL g_out"; fail=1; }
fi
if [ "$VS_CTL" = whole-registry ]; then
    vs_ctl_fired whole-registry "section 2f ran the whole-registry copy (mode)"
else
    on4 "$W/tool_wholereg.py" emu_reg "$W/o_wholereg.txt" > /dev/null
    grep -q '^== emulator staleness' "$W/o_wholereg.txt" && grep -q 'g_other: tests/ci_emulator.tsv' "$W/o_wholereg.txt" \
        && vs_ctl_fired whole-registry "the copy judging the registry as one file names g_other stale" || { vs_ctl_dead whole-registry "the whole-file copy did not name g_other"; fail=1; }
fi
if [ "$VS_CTL" = keys-ignored ] || [ "$VS_CTL" = scope-ignored ]; then
    vs_ctl_fired "$VS_CTL" "section 2c/2d ran the $VS_CTL copy (mode)"
else
    on3 "$W/tool_keysignored.py" emu_rec freeze "$W/o_keysignored.txt" > /dev/null
    grep -q '^== emulator staleness' "$W/o_keysignored.txt" && grep -q 'g_key' "$W/o_keysignored.txt" && grep -q 'g_sub' "$W/o_keysignored.txt" \
        && vs_ctl_fired keys-ignored "the copy that ignores the record names g_key and g_sub stale" || { vs_ctl_dead keys-ignored "the record-blind copy did not name them"; fail=1; }
    rc="$(on3 "$W/tool_scopeignored.py" emu_red freeze "$W/o_scopeignored.txt")"
    grep -q '^== emulator staleness' "$W/o_scopeignored.txt" && grep -q 'FAIL: .*stale' "$W/o_scopeignored.txt" && grep -q 'g_out' "$W/o_scopeignored.txt" \
        && vs_ctl_fired scope-ignored "the copy judging every row FAILs g_out at freeze cadence (exit $rc)" || { vs_ctl_dead scope-ignored "exit $rc"; fail=1; }
fi
rc="$(on3 "$TOOL" emu_red freeze "$W/o_red_c.txt")"
[ "$rc" = 1 ] && grep -q 'g_red: FAIL' "$W/o_red_c.txt" && vs_ctl_fired red-newest "the red-newest plant FAILs at freeze cadence (exit 1)" || { vs_ctl_dead red-newest "exit $rc"; fail=1; }
if [ "$VS_CTL" = newest-dir ]; then
    vs_ctl_fired newest-dir "section 2b ran the newest-directory copy (mode)"
else
    rc="$(pergate "$W/tool_newestdir.py" "$W/o_newestdir.txt")"
    if grep -q '^Traceback' "$W/o_newestdir.txt" || ! grep -qE '^(== emulator staleness|NO RUN OF RECORD)' "$W/o_newestdir.txt"; then
        vs_ctl_dead newest-dir "the newest-directory copy produced no verdict (it crashed: a crash is not a fired control)"; fail=1
    elif grep -q 'g_follows' "$W/o_newestdir.txt"; then vs_ctl_dead newest-dir "the newest-directory copy still named g_follows"; fail=1
    else vs_ctl_fired newest-dir "the newest-directory copy reads only the empty run and misses g_follows (exit $rc)"; fi
fi
rc="$(tool_on emu_plant freeze)"
[ "$rc" = 1 ] && vs_ctl_fired moved-input "the moved plant FAILs at freeze cadence (exit 1)" || { vs_ctl_dead moved-input "exit $rc"; fail=1; }
rc="$(tool_on emu_headroom session)"
[ "$rc" = 1 ] && vs_ctl_fired headroom-eaten "the half-cap plant FAILs (exit 1)" || { vs_ctl_dead headroom-eaten "exit $rc"; fail=1; }

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
