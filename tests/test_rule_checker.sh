#!/bin/sh
# test_rule_checker.sh — the adversarial RULE-CHECKER's record is sound: every run in tests/rulecheck/ledger.tsv is complete and structured, every planted violation was caught, every fixture is calibrated, every VIOLATED resolved, and every freeze since the checker's birth was checked (GitHub #152, 14z-163). ROM-free, ~2 s.
#
# WHAT: the adversarial rule-checker's record (tests/rulecheck/ledger.tsv and the run
#   directories) is sound: every run complete and structured, every planted violation
#   caught, every fixture calibrated by the CURRENT pinned reader, every VIOLATED resolved
#   in writing, every freeze since the checker's birth named by an OK freeze run, and
#   `record` bound to the readers' spawn check.
# HOW: section 1 runs tools/rulecheck.py's parser selftest; section 2 runs `rulecheck.py
#   check` on the real ledger, fixtures, run dirs and registry; section 3 fires six controls
#   on perturbed copies (a quiet plant, a moved reader, an unchecked freeze, a prose
#   verdict, an unbound recorder, a cross-family plant); the RECORD BINDING section proves a
#   pinned-reader run cannot be recorded without its transcript; the PREPARE SESSION KEY section
#   (#209, 14z-189) proves prepare refuses a run with no --session and one whose --session is a
#   transcript prefix, and writes the key it was given into meta.tsv (the ledger's `session`).
# EXPECTS: PASS with every control fired; a red names the run or fixture and the shape in
#   which the checker could look alive while asserting nothing.
#
# MUST-FIRE: perturbed-copy: quiet-control — a copy of the record in which one run's plant reads DEAD while its verdict still reads OK must fail: a dead plant VOIDS the verdict, and a checker that stopped catching its plants is a dead control
# MUST-FIRE: perturbed-copy: moved-reader — a copy whose pinned reader .claude/agents/rule-checker.md differs by one line must fail: a calibration counts only if the CURRENT definition read it (14z-178)
# MUST-FIRE: perturbed-copy: unchecked-freeze — a copy of the registry with one more row after the birth row, named by no `freeze` run, must fail: a freeze is bound to the checker mechanically
# MUST-FIRE: perturbed-copy: prose-verdict — a copy of the record in which one run's real verdict is prose instead of the six structured lines must fail: a prose verdict is unfalsifiable and the recorder refuses it
# MUST-FIRE: shadow-tool: unbound-record — a copy of rulecheck.py with the spawn binding removed must let a pinned-reader run be recorded without its transcript, and the RECORD BINDING section must FAIL: `record` binds every reader to the spawn check (14z-178, rule-checker run 2026-09-24-134 Q4)
# MUST-FIRE: shadow-tool: counted-id — a copy of rulecheck.py numbering prepare's auto id by a COUNT (the pre-#160 line) must collide with a run directory that has no ledger row, and the PREPARE IDS section must FAIL: the auto id is the next free number above every run directory and ledger id (GitHub #160, 14z-185)
# MUST-FIRE: shadow-tool: late-validate — a copy of rulecheck.py with prepare's early artifact check removed must leave a run directory with no ledger row behind when an artifact is missing, and the PREPARE IDS section must FAIL: prepare checks every artifact before it creates anything (GitHub #160, 14z-185)
# MUST-FIRE: shadow-tool: keyless-prepare — a copy of rulecheck.py whose prepare takes no session key (the pre-#209 line, `session = a.session or "-"`) must prepare a run whose meta.tsv says `session -`, and the PREPARE SESSION KEY section must FAIL: prepare requires the sitting's 14z-N key and refuses a transcript prefix (GitHub #209, 14z-189)
# MUST-FIRE: shadow-tool: unchecked-cite — a copy of rulecheck.py whose prepare takes every --cites at its word must prepare a merge packet citing an unresolved fork run, and the PREPARE CITES section must FAIL: a cited fork run counts only if its plant was caught, it is OK or resolved, and its artifacts are unchanged (#217, 14z-193)
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
    cp tools/claim_lint.py "$1/tools/"   # prepare imports it beside itself (#185 item 3)
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
    ( cd "$2" && python3 tools/rulecheck.py prepare --calibrate proc-planted-spec-14z178 --id 2099-01-01-01 --session 14z-0 ) > "$2/prep.log" 2>&1 \
        || { echo "PREPARE-FAILED $(tail -1 "$2/prep.log")"; return; }
    printf 'QP1: N-A — none\nQP2: N-A — none\nQP3: OK — none\nQP4: N-A — none\nQP5: VIOLATED — [1] off-spec\nVERDICT: VIOLATED\n' > "$2/v.txt"
    : > "$2/empty.jsonl"
    ( cd "$2" && python3 tools/rulecheck.py record 2099-01-01-01 --a v.txt --b v.txt ) > "$2/ra.log" 2>&1 && { echo "RECORDED-WITHOUT-TRANSCRIPT"; return; }
    grep -q "record it with --session" "$2/ra.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/ra.log")"; return; }
    ( cd "$2" && python3 tools/rulecheck.py record 2099-01-01-01 --a v.txt --b v.txt --transcript empty.jsonl ) > "$2/rb.log" 2>&1 && { echo "RECORDED-WITH-NO-READER"; return; }
    grep -q "never spawned" "$2/rb.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/rb.log")"; return; }
    echo BOUND
}
# SECTION PREPARE IDS's probe (GitHub #160, 14z-185): on a throwaway root carrying its own copy of the
# tool, (a) a run directory with no ledger row, named where a COUNT of the ledger's rows would put the
# next auto id (the 2026-09-18-36 collision), must not stop `prepare` without --id; (b) a prepare naming
# a missing artifact must fail AND leave no run directory behind (runs 2026-09-25-347 and -370 did).
# Prints IDS-OK or the way it was not.
# The scenario is built on the COPY with TODAY's ledger rows and run directories removed, so the
# count-based name is a true orphan (no ledger row, no directory) whatever today's runs were: on the
# live ledger the name can land on a real run of today's, and did (14z-185, run -385 — the probe
# then refused, ORPHAN-NAME-TAKEN, and its counted-id control read DEAD).
prepare_ids() {  # prepare_ids <rulecheck.py to test> <root>
    rm -rf "$2"; mkcopy "$2"; cp "$1" "$2/tools/rulecheck.py"
    _today="$(date +%Y-%m-%d)"
    awk -F'\t' -v t="$_today-" 'index($1, t) != 1' "$2/tests/rulecheck/ledger.tsv" > "$2/ledger.today-less" \
        && mv "$2/ledger.today-less" "$2/tests/rulecheck/ledger.tsv" || { echo "NO-LEDGER-TRIM"; return; }
    find "$2/tests/rulecheck/runs" -maxdepth 1 -name "$_today-*" -exec rm -rf {} + 2>/dev/null
    _cnt="$(python3 -c "import sys; sys.path.insert(0, '$2/tools'); import rulecheck as r; print(len(r.read_ledger(r.Path('$2'))))")" \
        || { echo "NO-LEDGER-COUNT"; return; }
    _orphan="$2/tests/rulecheck/runs/$(date +%Y-%m-%d)-$(printf '%02d' $((_cnt + 1)))"
    [ -e "$_orphan" ] && { echo "ORPHAN-NAME-TAKEN $(basename "$_orphan")"; return; }
    mkdir -p "$_orphan"
    ( cd "$2" && python3 tools/rulecheck.py prepare --calibrate proc-planted-spec-14z178 --session 14z-0 ) > "$2/pa.log" 2>&1 \
        || { echo "COLLIDED: $(tail -1 "$2/pa.log")"; return; }
    _before="$(ls "$2/tests/rulecheck/runs" | wc -l | tr -d ' ')"
    ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject s --claim c --artifact no/such/file --session 14z-0 ) > "$2/pb.log" 2>&1 \
        && { echo "PREPARED-WITH-A-MISSING-ARTIFACT"; return; }
    grep -q "artifact not found" "$2/pb.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/pb.log")"; return; }
    [ "$(ls "$2/tests/rulecheck/runs" | wc -l | tr -d ' ')" = "$_before" ] || { echo "LEFT-A-RUN-DIRECTORY"; return; }
    echo IDS-OK
}
# SECTION PREPARE SESSION KEY's probe (GitHub #209, 14z-189): on a throwaway root, prepare with no
# --session and with a transcript prefix (`74077d05`) must both be refused and leave no run directory;
# with `--session 14z-0` it must prepare a run whose meta.tsv reads `session 14z-0`. Prints KEY-OK or the way it was not.
prepare_key() {  # prepare_key <rulecheck.py to test> <root>
    rm -rf "$2"; mkcopy "$2"; cp "$1" "$2/tools/rulecheck.py"
    _before="$(ls "$2/tests/rulecheck/runs" | wc -l | tr -d ' ')"
    if ( cd "$2" && python3 tools/rulecheck.py prepare --calibrate proc-planted-spec-14z178 --id 2099-03-03-01 ) > "$2/k1.log" 2>&1; then
        echo "PREPARED-WITHOUT-KEY $(grep '^session' "$2/tests/rulecheck/runs/2099-03-03-01/meta.tsv" 2>/dev/null | tr '\t' ' ')"; return; fi
    grep -q "prepare needs --session 14z-N" "$2/k1.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/k1.log")"; return; }
    if ( cd "$2" && python3 tools/rulecheck.py prepare --calibrate proc-planted-spec-14z178 --id 2099-03-03-02 --session 74077d05 ) > "$2/k2.log" 2>&1; then
        echo "PREPARED-WITH-A-TRANSCRIPT-PREFIX"; return; fi
    grep -q "is not a 14z-N session key" "$2/k2.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/k2.log")"; return; }
    [ "$(ls "$2/tests/rulecheck/runs" | wc -l | tr -d ' ')" = "$_before" ] || { echo "LEFT-A-RUN-DIRECTORY"; return; }
    ( cd "$2" && python3 tools/rulecheck.py prepare --calibrate proc-planted-spec-14z178 --id 2099-03-03-03 --session 14z-0 ) > "$2/k3.log" 2>&1 \
        || { echo "REFUSED-WITH-A-KEY: $(tail -1 "$2/k3.log")"; return; }
    grep -q "^session	14z-0$" "$2/tests/rulecheck/runs/2099-03-03-03/meta.tsv" || { echo "KEY-NOT-WRITTEN"; return; }
    echo KEY-OK
}
keyless() {  # keyless <out> — the shadow tool: prepare's pre-#209 session line
    sed 's/^    session = session_key(a, root)$/    session = a.session or "-"/' tools/rulecheck.py > "$1"
    grep -q '^    session = a.session or "-"$' "$1" || { echo "the session-key line was not found to revert" >&2; return 1; }
}
counted() {  # counted <out> — the shadow tool: prepare's auto id by the pre-#160 count
    sed 's/^    n = max(taken + \[0\])$/    n = max(len(ledger_rows), len([p for p in (root \/ RUNS).glob(f"{today}-*") if p.is_dir()]) if (root \/ RUNS).exists() else 0)/' tools/rulecheck.py > "$1"
    grep -q 'n = max(len(ledger_rows)' "$1" || { echo "the auto-id line was not found to revert" >&2; return 1; }
}
latecheck() {  # latecheck <out> — the shadow tool: prepare's early artifact check switched off
    sed 's/^    if missing:$/    if False:/' tools/rulecheck.py > "$1"
    grep -q '^    if False:$' "$1" || { echo "the early artifact check was not found to remove" >&2; return 1; }
}
# SECTION PREPARE CITES's probe (#217, 14z-193): on a throwaway root, four hand-made fork runs — OK, VIOLATED
# and resolved (one of its artifacts a line range), VIOLATED and unresolved, OK with its plant MISSED — then
# a merge packet citing the first two must prepare (its meta.tsv and packet name them); citing the unresolved
# one, the missed-plant one or an unrecorded id must be refused leaving no run directory; and once a cited
# fork's artifact changes, both good citations must be refused at prepare, and the merge run already prepared
# must be refused at record. Prints CITES-OK or the way it was not.
prepare_cites() {  # prepare_cites <rulecheck.py to test> <root>
    rm -rf "$2"; mkcopy "$2"; cp "$1" "$2/tools/rulecheck.py"
    mkdir -p "$2/art"; printf 'fork line 1\nfork line 2\nfork line 3\n' > "$2/art/fork.txt"; echo merge > "$2/art/merge.txt"
    python3 - "$2" <<'PY' || { echo "NO-FIXTURE-RUNS"; return; }
import hashlib, sys
from pathlib import Path
root = Path(sys.argv[1]); sys.path.insert(0, str(root / "tools")); import rulecheck as r
whole = hashlib.sha1((root / "art/fork.txt").read_bytes()).hexdigest()
rng = hashlib.sha1("fork line 1\nfork line 2\n".encode()).hexdigest()
rows = {"2099-05-05-01": ("CAUGHT", "OK", "", "-", [("art/fork.txt", whole)]),
        "2099-05-05-02": ("CAUGHT", "VIOLATED", "Q1", "-", [("art/fork.txt", whole)]),
        "2099-05-05-03": ("CAUGHT", "VIOLATED", "Q1", "Q1: fixed in the fork", [("art/fork.txt.lines-1-2 (lines 1-2 of art/fork.txt)", rng)]),
        "2099-05-05-04": ("MISSED", "OK", "", "-", [("art/fork.txt", whole)])}
for rid, (cv, v, vi, res, man) in rows.items():
    d = root / r.RUNS / rid; d.mkdir(parents=True)
    (d / "manifest.tsv").write_text("# artifact\tsha1\n" + "".join(f"{a}\t{h}\n" for a, h in man))
    r.append_ledger(root, dict(id=rid, date="2099-05-05", session="14z-0", decision="evidence", subject="a fork",
                               control="fx", control_verdict=cv, verdict=v, violated=vi or "-", resolution=res, model="m"))
PY
    ROOT="$2"
    _runs() { ls "$ROOT/tests/rulecheck/runs" | wc -l | tr -d ' '; }
    _prep() {  # _prep <id> <cites...>
        _id="$1"; shift; _c=""; for x in "$@"; do _c="$_c --cites $x"; done
        ( cd "$ROOT" && python3 tools/rulecheck.py prepare --decision recommendation --subject merge \
            --claim "merge the forks" --artifact art/merge.txt --session 14z-0 --id "$_id" $_c ) > "$ROOT/c_$_id.log" 2>&1
    }
    _prep 2099-05-06-01 2099-05-05-01 2099-05-05-03 || { echo "REFUSED-GOOD-CITES: $(tail -1 "$2/c_2099-05-06-01.log")"; return; }
    grep -q "^cites	2099-05-05-01 2099-05-05-03$" "$2/tests/rulecheck/runs/2099-05-06-01/meta.tsv" || { echo "CITES-NOT-IN-META"; return; }
    grep -q "2099-05-05-03: VIOLATED, resolved: Q1: fixed in the fork (1 artifacts unchanged)" "$2/tests/rulecheck/runs/2099-05-06-01/packet.md" \
        || { echo "CITES-NOT-IN-PACKET"; return; }
    _before="$(_runs)"
    for bad in "2099-05-05-02:unresolved" "2099-05-05-04:plant reads MISSED" "2099-05-05-09:no ledger row"; do
        _bid="${bad%%:*}"; _why="${bad#*:}"
        if _prep "2099-05-06-1${_bid##*-}" "$_bid"; then echo "PREPARED-CITING-$_bid"; return; fi
        grep -q -- "$_why" "$2/c_2099-05-06-1${_bid##*-}.log" || { echo "REFUSED-$_bid-FOR-ANOTHER-REASON: $(tail -1 "$2/c_2099-05-06-1${_bid##*-}.log")"; return; }
    done
    printf 'fork line 1 EDITED\nfork line 2\nfork line 3\n' > "$2/art/fork.txt"
    for good in 2099-05-05-01 2099-05-05-03; do
        if _prep "2099-05-06-2${good##*-}" "$good"; then echo "PREPARED-CITING-CHANGED-$good"; return; fi
        grep -q "changed since that run was prepared" "$2/c_2099-05-06-2${good##*-}.log" \
            || { echo "REFUSED-CHANGED-$good-FOR-ANOTHER-REASON: $(tail -1 "$2/c_2099-05-06-2${good##*-}.log")"; return; }
    done
    [ "$(_runs)" = "$_before" ] || { echo "LEFT-A-RUN-DIRECTORY"; return; }
    # and AT RECORD: the merge run prepared above cites a fork that has since changed
    : > "$2/va.txt"; : > "$2/vb.txt"
    if ( cd "$ROOT" && python3 tools/rulecheck.py record 2099-05-06-01 --a va.txt --b vb.txt ) > "$2/c_rec.log" 2>&1; then
        echo "RECORDED-CITING-A-CHANGED-FORK"; return; fi
    grep -q "changed since that run was prepared" "$2/c_rec.log" || { echo "RECORD-REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/c_rec.log")"; return; }
    echo CITES-OK
}
uncite() {  # uncite <out> — the shadow tool: prepare with the citation check switched off
    python3 - tools/rulecheck.py "$1" <<'PY' || { echo "the citation check was not found to remove" >&2; return 1; }
import sys
s = open(sys.argv[1]).read(); a = "        cited = check_cited(root, ledger_rows, a.cites)\n"
assert s.count(a) == 1
# the citations are REPORTED from the ledger as the real tool reports them, and never validated
b = ("        cited = [(c, *next(((r['verdict'], r['resolution']) for r in ledger_rows if r['id'] == c), ('?', '-')), 1)"
     " for c in a.cites]  # CONTROL unchecked-cite\n")
open(sys.argv[2], "w").write(s.replace(a, b))
PY
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

if [ "${VS_CTL:-}" = keyless-prepare ]; then
    keyless "$W/keyless.py" || exit 3
    got="$(prepare_key "$W/keyless.py" "$W/pkmode")"
    echo "MODE: control keyless-prepare — the shadow copy reads: $got"
    case "$got" in PREPARED-WITHOUT-KEY*) ;; *) echo "REFUSED: the keyless copy did not prepare a keyless run ($got)"; exit 3;; esac
    echo "FAIL: rule-checker prepare session key (control mode keyless-prepare — $got)"; exit 1
fi

if [ "${VS_CTL:-}" = unchecked-cite ]; then
    uncite "$W/uncited.py" || exit 3
    got="$(prepare_cites "$W/uncited.py" "$W/pcmode")"
    echo "MODE: control unchecked-cite — the shadow copy reads: $got"
    case "$got" in PREPARED-CITING-*) ;; *) echo "REFUSED: the shadow copy did not prepare a bad citation ($got)"; exit 3;; esac
    echo "FAIL: rule-checker prepare cites (control mode unchecked-cite — $got)"; exit 1
fi

case "${VS_CTL:-}" in counted-id|late-validate)
    if [ "$VS_CTL" = counted-id ]; then counted "$W/shadow.py" || exit 3; else latecheck "$W/shadow.py" || exit 3; fi
    got="$(prepare_ids "$W/shadow.py" "$W/pimode")"
    echo "MODE: control $VS_CTL — the shadow copy reads: $got"
    [ "$got" != IDS-OK ] || { echo "REFUSED: the shadow copy still read IDS-OK"; exit 3; }
    echo "FAIL: rule-checker prepare ids (control mode $VS_CTL — $got)"; exit 1;;
esac

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

echo "== PREPARE IDS: the auto id is the next free number; a refused prepare leaves no run directory (#160) =="
got="$(prepare_ids tools/rulecheck.py "$W/pi")"
echo "  the real tool: $got"
[ "$got" = IDS-OK ] || { echo "FAIL: prepare's ids or its refusal left the runs inconsistent ($got)"; fail=1; }

echo "== PREPARE SESSION KEY: prepare requires the sitting's 14z-N key and refuses a transcript prefix (#209) =="
got="$(prepare_key tools/rulecheck.py "$W/pk")"
echo "  the real tool: $got"
[ "$got" = KEY-OK ] || { echo "FAIL: prepare's session key ($got)"; fail=1; }

echo "== PREPARE CITES: a merge packet's fork runs are checked by the tool (#217) =="
got="$(prepare_cites tools/rulecheck.py "$W/pcites")"
echo "  $got"
[ "$got" = CITES-OK ] || { echo "FAIL: prepare's citations ($got)"; fail=1; }

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

if keyless "$W/keyless_c.py"; then
    got="$(prepare_key "$W/keyless_c.py" "$W/pkc")"
    case "$got" in
        PREPARED-WITHOUT-KEY*) vs_ctl_fired keyless-prepare "the copy without the key check: $got";;
        *) vs_ctl_dead keyless-prepare "the keyless copy read $got"; fail=1;;
    esac
else
    vs_ctl_dead keyless-prepare "the session-key line was not found to revert"; fail=1
fi

if uncite "$W/uncited_c.py"; then
    got="$(prepare_cites "$W/uncited_c.py" "$W/pcc")"
    case "$got" in
        PREPARED-CITING-*) vs_ctl_fired unchecked-cite "the copy without the citation check: $got";;
        *) vs_ctl_dead unchecked-cite "the shadow copy read $got"; fail=1;;
    esac
else
    vs_ctl_dead unchecked-cite "the citation check was not found to remove"; fail=1
fi

for c in counted-id late-validate; do
    if [ "$c" = counted-id ]; then counted "$W/shadow_$c.py"; else latecheck "$W/shadow_$c.py"; fi || { vs_ctl_dead "$c" "the shadow copy could not be made"; fail=1; continue; }
    got="$(prepare_ids "$W/shadow_$c.py" "$W/pc_$c")"
    case "$got" in
        COLLIDED*|LEFT-A-RUN-DIRECTORY) vs_ctl_fired "$c" "the shadow copy: $got";;
        *) vs_ctl_dead "$c" "the shadow copy read $got"; fail=1;;
    esac
done

if [ "$fail" -eq 0 ]; then
    echo "PASS: the rule-checker's record is sound, record binds the spawn check, prepare's ids hold, prepare requires the session key, a merge packet's cited fork runs are checked, and its ten controls fire"
else
    echo "FAIL: rule-checker record"
    exit 1
fi
