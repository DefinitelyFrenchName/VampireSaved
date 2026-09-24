#!/bin/sh
# test_rule_checker.sh — the adversarial RULE-CHECKER's record is sound: every run in tests/rulecheck/ledger.tsv is complete and structured, every planted violation was caught, every fixture is calibrated, every VIOLATED resolved, and every freeze since the checker's birth was checked (GitHub #152, 14z-163). ROM-free, ~2 s.
#
# MUST-FIRE: perturbed-copy: quiet-control — a copy of the record in which one run's plant reads DEAD while its verdict still reads OK must fail: a dead plant VOIDS the verdict, and a checker that stopped catching its plants is a dead control
# MUST-FIRE: perturbed-copy: moved-reader — a copy whose pinned reader .claude/agents/rule-checker.md differs by one line must fail: a calibration counts only if the CURRENT definition read it (14z-178)
# MUST-FIRE: perturbed-copy: unchecked-freeze — a copy of the registry with one more row after the birth row, named by no `freeze` run, must fail: a freeze is bound to the checker mechanically
# MUST-FIRE: perturbed-copy: prose-verdict — a copy of the record in which one run's real verdict is prose instead of the six structured lines must fail: a prose verdict is unfalsifiable and the recorder refuses it
# MUST-FIRE: shadow-tool: unbound-record — a copy of rulecheck.py with the spawn binding removed must let a pinned-reader run be recorded without its transcript, and the RECORD BINDING section must FAIL: `record` binds every reader to the spawn check (14z-178, rule-checker run 2026-09-24-134 Q4)
# MUST-FIRE: perturbed-copy: cross-family-plant — a copy of the record in which a PROCEDURE calibration names an EVIDENCE fixture as its plant must fail: a plant answers its own family's questions, so one from the other checklist proves nothing about the reader (#172 S3, 14z-176)
#
# WHY. The rule-checker (docs/project/rule_checker.md, [VSP-183]/[VSP-184]) is a
# fresh agent that answers five fixed questions from the artifacts behind a
# proposed action. Its own must-fire is the PLANT: every real run is paired
# with a known violation run blind, and a plant that is not caught voids the
# verdict. This gate is what makes the record auditable without re-running an
# agent: tools/rulecheck.py check reads the ledger, the run dirs, the fixtures
# and the registry, and refuses every shape in which the checker could look
# alive while asserting nothing.
#
# Section 1 is the tool's parser selftest (the recorder's refusal of prose is
# what "structured output, never prose" rests on). Section 2 is the check on
# the real tree. Section 3 fires the six controls on a copy (cross-family-plant since 14z-176, moved-reader and
# unbound-record since 14z-178); the RECORD BINDING section (14z-178) proves `record` binds a pinned-reader run to the spawn check.
#
# Usage: tests/test_rule_checker.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# a copy of everything `rulecheck check` reads, under a throwaway root
mkcopy() {  # mkcopy <root>
    mkdir -p "$1/docs/project" "$1/tests/expected" "$1/tools"
    _doc=docs/project/rule_checker.md; cp "$_doc" "$1"/docs/project/
    cp tests/expected/registry.tsv "$1/tests/expected/"
    cp -R tests/rulecheck "$1/tests/rulecheck"
    # the pinned reader (14z-178): a calibration counts only if read by this definition's sha
    mkdir -p "$1/.claude/agents"; cp .claude/agents/rule-checker.md "$1/.claude/agents/"
}

# THE PERTURBATIONS — one function each, called by the control section and
# by the mode alike, so what the mode proves is what the control claims.
perturb() {  # perturb <name> <root>
    case "$1" in
    quiet-control)
        # the first CAUGHT row's plant is declared DEAD while its verdict stays
        python3 - "$2/tests/rulecheck/ledger.tsv" <<'PY'
import sys
p = sys.argv[1]; out = []; done = False
for ln in open(p):
    if not done and not ln.startswith("#") and "\tCAUGHT\t" in ln:
        ln = ln.replace("\tCAUGHT\t", "\tDEAD\t", 1); done = True
    out.append(ln)
assert done, "no CAUGHT row to perturb"
open(p, "w").write("".join(out))
PY
        ;;
    moved-reader)
        printf '\n' >> "$2/.claude/agents/rule-checker.md"
        ;;
    unchecked-freeze)
        printf '%s\t%s\t%s\n' "0000000000000000000000000000000000000000" "merged-m99" "a row planted by the unchecked-freeze control" >> "$2/tests/expected/registry.tsv"
        ;;
    prose-verdict)
        _run="$(ls -d "$2"/tests/rulecheck/runs/*/ | head -1)"
        [ -n "$_run" ] || { echo "no run dir to perturb"; return 1; }
        printf 'Overall this looks fine to me; the legs agree and the control exists.\n' > "$_run/verdict_real.txt"
        ;;
    cross-family-plant)
        # the first procedure-family run (a meta.tsv reading `family procedure`) names an evidence plant
        _run="$(grep -l '^family	procedure$' "$2"/tests/rulecheck/runs/*/meta.tsv | head -1 | xargs dirname)"
        [ -n "$_run" ] || { echo "no procedure run to perturb"; return 1; }
        printf 'fixture\tforced-pick-14z159\nslot\tb\n' > "$_run/control.txt"
        ;;
    *) echo "unknown perturbation $1"; return 1 ;;
    esac
}

# the finding each perturbation must produce — a copy that fails for any OTHER
# reason has not proven this control ([VSP-114])
expect_msg() {  # expect_msg <name>
    case "$1" in
    quiet-control)    echo "a DEAD plant must VOID the verdict" ;;
    moved-reader)     echo "AND the current pinned reader" ;;
    unchecked-freeze) echo "was frozen with no OK \`freeze\` rulecheck row" ;;
    prose-verdict)    echo "not a structured verdict" ;;
    cross-family-plant) echo "is from the evidence family, but the run was read under the procedure checklist" ;;
    esac
}

# SECTION 4's probe: on a throwaway root carrying its own copy of the tool (prepare and record
# resolve the repository from the script's own path), prepare a calibration of a pinned-reader
# run and try to record it (a) with verdict files and no transcript, (b) with a transcript in
# which no reader was spawned — the tool must refuse both. Prints BOUND or the way it was not.
record_binding() {  # record_binding <rulecheck.py to test> <root>
    rm -rf "$2"; mkcopy "$2"; cp "$1" "$2/tools/rulecheck.py"
    ( cd "$2" && python3 tools/rulecheck.py prepare --calibrate proc-planted-spec-14z178 --id 2099-01-01-01 ) > "$2/prep.log" 2>&1 \
        || { echo "PREPARE-FAILED $(tail -1 "$2/prep.log")"; return; }
    printf 'QP1: N-A — none\nQP2: N-A — none\nQP3: OK — none\nQP4: N-A — none\nQP5: VIOLATED — [1] off-spec\nVERDICT: VIOLATED\n' > "$2/v.txt"
    : > "$2/empty.jsonl"
    ( cd "$2" && python3 tools/rulecheck.py record 2099-01-01-01 --a v.txt --b v.txt ) > "$2/ra.log" 2>&1 && { echo "RECORDED-WITHOUT-TRANSCRIPT"; return; }
    grep -q "record it with --session" "$2/ra.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/ra.log")"; return; }
    ( cd "$2" && python3 tools/rulecheck.py record 2099-01-01-01 --a v.txt --b v.txt --transcript empty.jsonl ) > "$2/rb.log" 2>&1 && { echo "RECORDED-WITH-NO-READER"; return; }
    grep -q "never spawned" "$2/rb.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/rb.log")"; return; }
    echo BOUND
}
unbind() {  # unbind <out> — the shadow tool: rulecheck.py with the spawn binding switched off
    sed 's/^    if meta.get("reader"):$/    if False:/' tools/rulecheck.py > "$1"
    grep -q '^    if False:$' "$1" || { echo "the binding line was not found to remove" >&2; return 1; }
}

if [ "${VS_CTL:-}" = unbound-record ]; then
    unbind "$W/unbound.py" || exit 3
    got="$(record_binding "$W/unbound.py" "$W/rbmode")"
    echo "MODE: control unbound-record — the unbound copy reads: $got"
    case "$got" in RECORDED-*) ;; *) echo "REFUSED: the unbound copy did not record the unchecked run ($got)"; exit 3;; esac
    echo "FAIL: rule-checker record (control mode unbound-record: a pinned-reader run could be recorded unchecked — $got)"; exit 1
fi

if [ -n "${VS_CTL:-}" ]; then
    # THE EXECUTABLE FORM: the real record, copied, perturbed, checked — must FAIL
    # on the control's own finding
    mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"
    if python3 tools/rulecheck.py check --root "$W/mode" > "$W/mode.log" 2>&1; then
        cat "$W/mode.log"; echo "FAIL: CONTROL=$VS_CTL left the check green"; exit 1
    fi
    cat "$W/mode.log"
    if ! grep -qF -- "$(expect_msg "$VS_CTL")" "$W/mode.log"; then
        echo "FAIL: CONTROL=$VS_CTL failed the check, but not on its own finding ($(expect_msg "$VS_CTL"))"; exit 1
    fi
    echo "FAIL: rule-checker record (control mode $VS_CTL reached the gate's own FAIL on its own finding)"; exit 1
fi

echo "== 1. the recorder's parser: structured verdicts accepted, prose refused =="
python3 tools/rulecheck.py --selftest || fail=1

echo "== 2. the record on the real tree =="
python3 tools/rulecheck.py check || fail=1

echo "== RECORD BINDING: record binds a pinned-reader run to the spawn check (14z-178) =="
got="$(record_binding tools/rulecheck.py "$W/rb")"
echo "  the real tool: $got"
[ "$got" = BOUND ] || { echo "FAIL: a pinned-reader run could be recorded without its readers checked ($got)"; fail=1; }

echo "== 3. MUST-FIRE CONTROLS on a copy =="
for c in quiet-control moved-reader unchecked-freeze prose-verdict cross-family-plant; do
    rm -rf "$W/c"; mkcopy "$W/c"; perturb "$c" "$W/c"
    if python3 tools/rulecheck.py check --root "$W/c" > "$W/c.log" 2>&1; then
        vs_ctl_dead "$c" "the perturbed copy passed the check"; fail=1
    elif ! grep -qF -- "$(expect_msg "$c")" "$W/c.log"; then
        vs_ctl_dead "$c" "the copy failed, but not on this control's finding: $(grep -m1 '^  FAIL:' "$W/c.log" | cut -c9-120)"; fail=1
    else
        vs_ctl_fired "$c" "$(grep -m1 -F -- "$(expect_msg "$c")" "$W/c.log" | cut -c9-140)"
    fi
done
if unbind "$W/unbound.py"; then
    got="$(record_binding "$W/unbound.py" "$W/rbc")"
    case "$got" in
        RECORDED-*) vs_ctl_fired unbound-record "the copy without the binding: $got";;
        *) vs_ctl_dead unbound-record "the unbound copy did not record the unchecked run ($got)"; fail=1;;
    esac
else
    vs_ctl_dead unbound-record "the binding line was not found to remove"; fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "PASS: the rule-checker's record is sound, record binds the spawn check, and its six controls fire"
else
    echo "FAIL: rule-checker record"
    exit 1
fi
