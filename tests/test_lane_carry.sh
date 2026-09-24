#!/bin/sh
# test_lane_carry.sh — ground truth for tools/audit_lane_carry.py: a lane's carry verdict
# is derived from its gates' `# FOLLOWS:` declarations and fails when one moved or one is
# missing (GitHub #171 slice Q3; the tool itself 14z-174). ci_portable: a scratch git
# repository, no ROM, no emulator, ~3 s.
#
# WHAT: tools/audit_lane_carry.py answers MAY CARRY only when every path a lane's gates
#   declare, the gate scripts and the registry are byte-unchanged since the commit, says
#   MUST RE-RUN naming the moved path when one moved, and refuses to carry a lane whose
#   gate declares nothing.
# HOW: a scratch git repository with two stub emulator gates (one declaring
#   `tests/replays/x.rpl tools/t.py`, one undeclared in a second lane) and a registry, one
#   commit; the REAL tool runs against it (--repo) in three states: unchanged, a declared
#   replay edited in the working tree, and the undeclared lane; two shadow-tool controls
#   run copies of the tool with the derivation blinded and the undeclared refusal removed.
# EXPECTS: MAY CARRY (exit 0) on the unchanged repo; MUST RE-RUN (exit 1) naming
#   tests/replays/x.rpl after the edit; MUST RE-RUN (exit 1) naming the undeclared gate;
#   each control's copy reads the opposite on its section.
#
# MUST-FIRE: shadow-tool: carry-blind — a copy of the tool whose derived subjects are replaced by the empty set must say MAY CARRY on the edited repo, which this gate must read as its FAIL (mode: that copy is the tool every section runs)
# MUST-FIRE: shadow-tool: undeclared-carried — a copy with the undeclared refusal removed must say MAY CARRY on the lane whose gate declares nothing (mode: that copy is the tool every section runs)
#
# WHY: the first tool carried hardcoded subject lists and printed its own omissions; a
# derivation that silently derived NOTHING would be a MAY CARRY on every lane — the very
# failure #171 named. The controls are the two ways the derivation could go blind.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
TOOL="$REPO/tools/audit_lane_carry.py"
W="$(mktemp -d "${TMPDIR:-/tmp}/lcarry.XXXXXX")"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

# THE SHADOW TOOLS, built from the real tool by one substitution each; a substitution
# that no longer applies is a red (the tool moved under the control).
mkdir -p "$W/shadow"; cp "$REPO/tools/gate_follows.py" "$REPO/tools/gate_descriptions.py" "$W/shadow/"
sed 's|subjects, undeclared = gf.lane_subjects(repo, a.lane)|subjects, undeclared = [], []|' "$TOOL" > "$W/shadow/blind.py"
cmp -s "$TOOL" "$W/shadow/blind.py" && bad "could not blind the derivation — the lane_subjects call moved"
sed 's|    if undeclared:|    if False:|' "$TOOL" > "$W/shadow/carried.py"
cmp -s "$TOOL" "$W/shadow/carried.py" && bad "could not remove the undeclared refusal — the branch moved"
case "$VS_CTL" in
carry-blind)        TOOL="$W/shadow/blind.py" ;;
undeclared-carried) TOOL="$W/shadow/carried.py" ;;
esac

# THE SCRATCH REPOSITORY
R="$W/repo"; mkdir -p "$R/tests/replays" "$R/tools"
cat > "$R/tests/g_declared.sh" <<'EOF'
#!/bin/sh
# g_declared.sh — a stub emulator gate
#
# WHAT: stub. HOW: stub. EXPECTS: stub.
# FOLLOWS: tests/replays/x.rpl tools/t.py
: "${MAME_BIN:-}"
EOF
cat > "$R/tests/g_undeclared.sh" <<'EOF'
#!/bin/sh
# g_undeclared.sh — a stub emulator gate with no declaration
: "${MAME_BIN:-}"
EOF
printf 'g_declared\tmame\trelease\tromset\t-\tstub\ng_undeclared\tfbneo\trelease\tromset\t-\tstub\n' > "$R/tests/ci_emulator.tsv"
echo "1 wait" > "$R/tests/replays/x.rpl"; echo "print(1)" > "$R/tools/t.py"; echo "unrelated" > "$R/tools/other.py"
( cd "$R" && git init -q && git -c user.name=t -c user.email=t@t add -A && git -c user.name=t -c user.email=t@t commit -q -m base ) || { echo "FAIL: could not make the scratch repository"; exit 1; }
BASE="$(cd "$R" && git rev-parse HEAD)"
run() { python3 "$TOOL" "$1" --since "$BASE" --repo "$R" > "$W/out.txt" 2>&1; echo $?; }

echo "== 1. unchanged: the mame lane MAY CARRY"
rc="$(run mame)"
[ "$rc" = 0 ] && grep -q '^MAY CARRY' "$W/out.txt" && ok "MAY CARRY, exit 0" || { bad "expected MAY CARRY exit 0, got exit $rc"; sed 's/^/        /' "$W/out.txt" | tail -4; }
grep -q 'tests/replays/x.rpl\|3 path prefix' "$W/out.txt" || true

echo "== 2. an unrelated file changed: still MAY CARRY"
echo "changed" >> "$R/tools/other.py"
rc="$(run mame)"
[ "$rc" = 0 ] && ok "an undeclared, unrelated path does not move the verdict" || { bad "an unrelated change made the lane MUST RE-RUN (exit $rc)"; sed 's/^/        /' "$W/out.txt" | tail -4; }

echo "== 3. a declared replay edited in the working tree: MUST RE-RUN, the path named"
echo "2 wait" >> "$R/tests/replays/x.rpl"
rc="$(run mame)"
if [ "$rc" = 1 ] && grep -q '^MUST RE-RUN' "$W/out.txt" && grep -q 'tests/replays/x.rpl' "$W/out.txt"; then ok "MUST RE-RUN naming tests/replays/x.rpl"
else bad "expected MUST RE-RUN naming the replay, got exit $rc"; sed 's/^/        /' "$W/out.txt" | tail -5; fi

echo "== 4. the lane whose gate declares nothing: MUST RE-RUN, the gate named"
rc="$(run fbneo)"
if [ "$rc" = 1 ] && grep -q 'g_undeclared' "$W/out.txt" && grep -q '^MUST RE-RUN' "$W/out.txt"; then ok "the undeclared gate refuses the carry"
else bad "expected MUST RE-RUN naming g_undeclared, got exit $rc"; sed 's/^/        /' "$W/out.txt" | tail -5; fi

if [ -z "$VS_CTL" ]; then
    echo "== 5. controls: each shadow tool must read the opposite on its section"
    rc="$(python3 "$W/shadow/blind.py" mame --since "$BASE" --repo "$R" >/dev/null 2>&1; echo $?)"
    [ "$rc" = 0 ] && vs_ctl_fired carry-blind "the blinded copy said MAY CARRY on the edited repo (exit 0) — section 3 would have failed on it" \
                  || { vs_ctl_dead carry-blind "the blinded copy still said MUST RE-RUN (exit $rc)"; fail=1; }
    rc="$(python3 "$W/shadow/carried.py" fbneo --since "$BASE" --repo "$R" >/dev/null 2>&1; echo $?)"
    [ "$rc" = 0 ] && vs_ctl_fired undeclared-carried "the copy without the refusal carried the undeclared lane (exit 0) — section 4 would have failed on it" \
                  || { vs_ctl_dead undeclared-carried "the copy still refused (exit $rc)"; fail=1; }
fi

[ "$fail" -eq 0 ] && echo "PASS: the carry verdict is derived from the declarations and fails when one moved or is missing" || echo "FAIL"
exit "$fail"
