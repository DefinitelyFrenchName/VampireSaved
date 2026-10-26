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
#   transcript prefix, and writes the key it was given into meta.tsv (the ledger's `session`); the PREPARE READ
#   LIMIT section (#258, 14z-204) proves prepare refuses a text artifact a reader cannot read whole in one Read and
#   a whole indexed archive (listing its entries' ranges), refuses an archive range that starts off its INDEX, and
#   tells the reader which entry a range holds; the PLANT ROTATION section (#258, 14z-204) draws every rotation
#   position and proves each plant is one a reader can read whole (the gate prepared once, so it saw one plant).
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
# MUST-FIRE: shadow-tool: blame-unticketed — a copy of rulecheck.py whose resolve takes an instrument-blaming answer ("no slip", "the plant's reader", "W# hint", a reader's misreading) with no open ticket named (the pre-#271 resolve, BLAME_CHECKED off) must record it, and the RESOLVE BLAME section must FAIL: an instrument defect answered run by run is how the plant readers' 2550/2560 recurred from 14z-179 to 14z-198 unaggregated (#271, 14z-199; mode: the section runs that copy)
# MUST-FIRE: shadow-tool: recheck-unchecked — a copy of rulecheck.py whose resolve takes any --recheck at its word (RECHECK_CHECKED off: no checks run) must resolve a documentation-packet finding whose fix was never made, beside a forged all-OK run record, and the RESOLVE RECHECK section must FAIL: resolve runs the close's standing checks itself and a presentation finding is never certified by the working agent alone (#270, 14z-199, runs 968-970 Q4; mode: the section runs that copy)
# MUST-FIRE: shadow-tool: recheck-own-checks — a copy of rulecheck.py whose --recheck takes any checks file (STANDING_BOUND off) must resolve a finding on the close's own --extra check, and the RESOLVE RECHECK section must FAIL: the checks that certify a fix are the tracked standing set's, rendered at its current sha, never a file or a row the working agent wrote (#270, rule-checker run 2026-10-13-968 Q4; mode: the section runs that copy)
# MUST-FIRE: shadow-tool: recheck-porous-fill — a copy of rulecheck.py whose standing-command match lets a placeholder hold anything (FILL_STRICT off) must resolve a finding on a standing row with shell text inside its filled {ROW}, and the RESOLVE RECHECK section must FAIL: a placeholder's fill is pinned — KEY, RUN and SESSDIR to their known values, ROW to text that cannot leave its quotes (#270, rule-checker run 2026-10-13-969 Q4; mode: the section runs that copy)
# MUST-FIRE: shadow-tool: recheck-pruned-render — a copy of rulecheck.py that binds only the NAMED standing rows (EVERY_ROW off) must resolve a finding on a render with another standing row deleted, and the RESOLVE RECHECK section must FAIL: a re-check runs the whole standing set, every row present and unedited (#270, rule-checker run 2026-10-13-971 Q4; mode: the section runs that copy)
# MUST-FIRE: shadow-tool: recheck-other-session — a copy of rulecheck.py whose re-check binds KEY from the checks file itself and TRANSCRIPT by its shape only (SESSION_BOUND off) must resolve a finding of one sitting on a genuine render made for another, and the RESOLVE RECHECK section must FAIL: the re-check reads THIS run's session — its key, the transcript and base close_standing.py derives (#270, rule-checker run 2026-10-13-972 Q4; mode: the section runs that copy)
# MUST-FIRE: shadow-tool: recheck-unpinned-base — a copy of rulecheck.py whose re-check lets BASE be any hash (BASE_PINNED off) must resolve a finding on a render whose BASE fill was edited to another commit, and the RESOLVE RECHECK section must FAIL: BASE is what close_standing.py derives for the run's session (#270, rule-checker run 2026-10-13-973 Q4; mode: the section runs that copy)
# MUST-FIRE: shadow-tool: unfiltered-plants — a copy of rulecheck.py whose plant rotation has no readable-plant filter (the first #258 cut) must be refused at some rotation position, drawing a plant whose rig file no reader can read whole, and the PLANT ROTATION section must FAIL (#258, 14z-204)
# MUST-FIRE: shadow-tool: unlimited-read — a copy of rulecheck.py with no read limit (READ_MAX_BYTES and READ_MAX_TOKENS lifted, the pre-#258 tool) must prepare a packet naming a 70 KB text artifact no reader can read whole, and the PREPARE READ LIMIT section must FAIL (#258, 14z-204)
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
#
# CONFIRM: always — the CORE of a session run (#269, 14z-200): its prepare sections depend on today's date (prepare numbers a run by it),
# none of which a changed tracked path shows, so tests/run_all_static.sh --confirm never carries it.
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
    cp tools/packet_check.py "$1/tools/"; cp -R tools/agent "$1/tools/agent"   # and the pre-prepare check (#272)
    cp tools/close_checks.py tools/close_standing.py tools/findings_table.py "$1/tools/"   # resolve --recheck runs a close render with them (#270; findings_table, #282 item C)
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

# THE MODE'S VERDICT, one function (rule-checker runs 2026-10-13-952 and -953): a copy whose check stays green is a
# mode that LIES (exit 0); one that fails ON ITS OWN finding is honoured (exit 1); one that fails only on ANOTHER
# finding — an unresolved run in the real ledger, say — is REFUSED (exit 3): both of the last two exited 1 before,
# so a mode read HONOURED on a finding it never produced. The MODE VERDICT section runs it on three logs.
mode_judge() {  # mode_judge <check exit> <log> <the mode's own finding> — prints GREEN|OWN|OTHER, returns 0|1|3
    [ "$1" = 0 ] && { echo GREEN; return 0; }
    grep -qF -- "$3" "$2" && { echo OWN; return 1; }
    echo OTHER; return 3
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
# SECTION PREPARE READ LIMIT's probe (#258, 14z-204): on a throwaway root, a 70 KB text artifact (over the reader's
# 25,000-token PARTIAL-view cap), a 50 KB file of 5,000 short lines (the per-line cost: a byte cap alone passes it), a fixture
# holding a 70 KB file (the plant and calibrate paths) and a whole indexed archive must each be refused
# leaving no run directory, the archive's refusal listing its entries' ranges; a range of the archive that starts at an
# entry its INDEX names must prepare, and the packet must tell the reader which entry it is; a range starting elsewhere
# must be refused, and so must any range once the archive's INDEX is stale. Prints READ-OK or the way it was not.
prepare_readlimit() {  # prepare_readlimit <rulecheck.py to test> <root>
    rm -rf "$2"; mkcopy "$2"; cp "$1" "$2/tools/rulecheck.py"; cp tools/gen_history_index.py "$2/tools/"
    _ar=docs/project/tenant_manifest_history.md
    python3 - "$2" "$_ar" <<'PYR' || { echo "NO-FIXTURE"; return; }
import sys, os
root, ar = sys.argv[1:3]
sys.path.insert(0, os.path.join(root, "tools")); import gen_history_index as g
pad = "a padding line of an archived entry, there only to make the archive larger than one Read call\n" * 300
body = "# TENANT MANIFEST HISTORY\n\n" + "".join(f"## Entry {k} (14z-{900 + k})\n\n{pad}\n" for k in range(3))
os.makedirs(os.path.dirname(os.path.join(root, ar)), exist_ok=True)
open(os.path.join(root, ar), "w").write(g.render(body, g.ENTRY[ar]))
open(os.path.join(root, "big.txt"), "w").write("x" * 70000 + "\n")
open(os.path.join(root, "small.txt"), "w").write("a small artifact\n")
open(os.path.join(root, "many.txt"), "w").write("".join(f"L{i:06d}x\n" for i in range(5000)))
PYR
    _before="$(ls "$2/tests/rulecheck/runs" | wc -l | tr -d ' ')"
    if ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject s --claim c --artifact small.txt --artifact big.txt --session 14z-0 --id 2099-04-04-01 ) > "$2/r1.log" 2>&1; then
        echo "PREPARED-AN-UNREADABLE-ARTIFACT"; return; fi
    grep -q "would not read it in full (#258)" "$2/r1.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/r1.log")"; return; }
    if ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject s --claim c --artifact many.txt --session 14z-0 --id 2099-04-04-06 ) > "$2/r6.log" 2>&1; then
        echo "PREPARED-MANY-SHORT-LINES"; return; fi
    grep -q "would not read it in full (#258)" "$2/r6.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/r6.log")"; return; }
    cp "$2/big.txt" "$2/tests/rulecheck/fixtures/proc-planted-spec-14z178/files/big.txt"
    if ( cd "$2" && python3 tools/rulecheck.py prepare --calibrate proc-planted-spec-14z178 --session 14z-0 --id 2099-04-04-07 ) > "$2/r7.log" 2>&1; then
        echo "PREPARED-A-FIXTURE-WITH-AN-UNREADABLE-FILE"; return; fi
    grep -q "would not read it in full (#258)" "$2/r7.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/r7.log")"; return; }
    rm "$2/tests/rulecheck/fixtures/proc-planted-spec-14z178/files/big.txt"
    if ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject s --claim c --artifact "$_ar" --session 14z-901 --id 2099-04-04-02 ) > "$2/r2.log" 2>&1; then
        echo "PREPARED-A-WHOLE-ARCHIVE"; return; fi
    grep -q -- "--artifact $_ar:[0-9]*-[0-9]*    ## Entry 1 (14z-901)" "$2/r2.log" || { echo "NO-INDEX-RANGES: $(tail -2 "$2/r2.log" | tr '\n' '|')"; return; }
    [ "$(ls "$2/tests/rulecheck/runs" | wc -l | tr -d ' ')" = "$_before" ] || { echo "LEFT-A-RUN-DIRECTORY"; return; }
    _rng="$(grep -o -- "--artifact $_ar:[0-9]*-[0-9]*    ## Entry 1" "$2/r2.log" | sed "s|--artifact $_ar:||; s| .*||")"
    _first="${_rng%-*}"
    if ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject s --claim c --artifact "$_ar:$((_first + 1))-${_rng#*-}" --session 14z-0 --id 2099-04-04-03 ) > "$2/r3.log" 2>&1; then
        echo "PREPARED-A-RANGE-OFF-THE-INDEX"; return; fi
    grep -q "must start at an entry its INDEX names" "$2/r3.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/r3.log")"; return; }
    ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject s --claim c --artifact "$_ar:$_rng" --session 14z-0 --id 2099-04-04-04 ) > "$2/r4.log" 2>&1 \
        || { echo "REFUSED-AN-INDEXED-RANGE: $(tail -1 "$2/r4.log")"; return; }
    grep -q "its INDEX entry \"## Entry 1 (14z-901)\"" "$2/tests/rulecheck/runs/2099-04-04-04/packet.md" || { echo "ENTRY-NOT-NAMED-TO-THE-READER"; return; }
    printf '## Entry 3 (14z-903), appended without regenerating the INDEX\n' >> "$2/$_ar"
    if ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject s --claim c --artifact "$_ar:$_rng" --session 14z-0 --id 2099-04-04-05 ) > "$2/r5.log" 2>&1; then
        echo "PREPARED-FROM-A-STALE-INDEX"; return; fi
    grep -q "whose INDEX is stale" "$2/r5.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/r5.log")"; return; }
    echo READ-OK
}
# SECTION PLANT ROTATION's probe (#258, 14z-204): the plant is drawn by the ledger's length, so a gate that prepares once
# sees ONE plant — the over-limit plants in rotation stayed invisible until the ledger grew by two and every prepare was
# refused. On a throwaway root with one calibrated evidence plant made unreadable (a 70 KB file planted in it), one dummy
# ledger row is appended before each of as many evidence prepares as the family has calibrated plants, so every rotation
# position is drawn: each must prepare (the unreadable plant skipped).
# Prints ROTATION-OK or the way it was not.
plant_rotation() {  # plant_rotation <rulecheck.py to test> <root>
    rm -rf "$2"; mkcopy "$2"; cp "$1" "$2/tools/rulecheck.py"; cp tools/gen_history_index.py "$2/tools/"
    echo "a small artifact" > "$2/small.txt"
    # one calibrated evidence plant made unreadable in the copy (a 70 KB file beside its own): since the 14z-204 trims no
    # real plant is over the limit, so without this the filter would have nothing to skip and its control nothing to draw
    python3 -c "open('$2/tests/rulecheck/fixtures/forced-pick-14z159/files/big.txt', 'w').write('x' * 70000 + chr(10))"
    _n="$(cd "$2" && python3 - <<'PY'
import sys; sys.path.insert(0, "tools"); import rulecheck as rc
from pathlib import Path
r = Path("."); rows = rc.read_ledger(r)
print(len([n for n, ex in rc.list_fixtures(r) if ex[0] == "VIOLATED" and rc.fixture_family(r, n) == "evidence" and rc.calibrated(rows, n, r)]))
PY
)" || { echo "NO-COUNT"; return; }
    [ "${_n:-0}" -ge 1 ] || { echo "NO-EVIDENCE-PLANT"; return; }
    _last="$(grep -v '^#' "$2/tests/rulecheck/ledger.tsv" | grep -v '^id	' | tail -1)"
    _k=0
    while [ "$_k" -lt "$_n" ]; do
        _k=$((_k + 1))
        printf '%s\n' "$_last" | sed "s/^[^	]*/2099-05-05-$_k/" >> "$2/tests/rulecheck/ledger.tsv"
        if ! ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject s --claim c --artifact small.txt --session 14z-0 --id "2099-05-06-$_k" ) > "$2/rot$_k.log" 2>&1; then
            echo "REFUSED-AT-POSITION-$_k: $(grep -m1 -o 'artifact [^ ]* is [0-9,]* bytes' "$2/rot$_k.log" || tail -1 "$2/rot$_k.log")"; return
        fi
    done
    echo ROTATION-OK
}
unfiltered() {  # unfiltered <out> — the shadow tool: the rotation without the readable-plant filter (the first #258 cut)
    sed 's/ and calibrated(ledger_rows, n, root) and plant_readable(root, n)\]/ and calibrated(ledger_rows, n, root)]/' tools/rulecheck.py > "$1"
    [ "$(grep -c 'plant_readable(root, n)\]' "$1")" = 0 ] && [ "$(grep -c 'plant_readable(root, n)\]' tools/rulecheck.py)" = 2 ] \
        || { echo "the readable-plant filter was not found to remove" >&2; return 1; }
}
unlimited() {  # unlimited <out> — the shadow tool: prepare with no read limit (the pre-#258 tool)
    sed -e 's/^READ_MAX_BYTES = 256 \* 1024$/READ_MAX_BYTES = 10 ** 12/' -e 's/^READ_MAX_TOKENS = 25000$/READ_MAX_TOKENS = 10 ** 12/' tools/rulecheck.py > "$1"
    [ "$(grep -c '^READ_MAX_[A-Z]* = 10 \*\* 12$' "$1")" = 2 ] || { echo "the READ_MAX lines were not found to lift" >&2; return 1; }
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
# SECTION RESOLVE BLAME's probe (#271, 14z-199): on a throwaway root with a two-row ticket index (#9001 open, #9002
# done) and four VIOLATED runs, resolve must REFUSE an instrument-blaming answer naming no ticket, and one naming
# only the done ticket; it must accept the same blame naming the open #9001, and a plain answer by work; and an
# answer by work that only QUOTES a blame phrase is refused until it names the ticket (the rule's documented
# cost). Prints BLAME-OK or the way it was not.
resolve_blame() {  # resolve_blame <rulecheck.py to test> <root>
    rm -rf "$2"; mkcopy "$2"; cp "$1" "$2/tools/rulecheck.py"
    printf '# index\n9001\tevolution\topen\tan instrument defect\n9002\tevolution\tdone\ta fixed one\n' > "$2/docs/project/tickets.tsv"
    python3 - "$2" <<'PY2' || { echo "NO-FIXTURE-RUNS"; return; }
import sys
from pathlib import Path
root = Path(sys.argv[1]); sys.path.insert(0, str(root / "tools")); import rulecheck as r
for n in range(1, 5):
    r.append_ledger(root, dict(id=f"2099-07-07-0{n}", date="2099-07-07", session="14z-0", decision="procedure", subject=f"part {n}",
                               control="fx", control_verdict="CAUGHT", verdict="VIOLATED", violated="QP3", resolution="-", model="m"))
PY2
    _res() { ( cd "$2" && python3 tools/rulecheck.py resolve "$1" --how "$3" ) > "$2/res.log" 2>&1; }
    BL="QP3: no slip — the plant's reader quoted its claim's 2550/2560, which the W# hint cannot source"
    if _res 2099-07-07-01 "$2" "$BL"; then echo "RESOLVED-BLAME-UNTICKETED"; return; fi
    grep -q "blames the instrument" "$2/res.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/res.log")"; return; }
    if _res 2099-07-07-01 "$2" "$BL; the cause is #9002"; then echo "RESOLVED-BLAME-NAMING-A-DONE-TICKET"; return; fi
    _res 2099-07-07-02 "$2" "$BL; the cause is #9001" || { echo "REFUSED-BLAME-NAMING-AN-OPEN-TICKET: $(tail -1 "$2/res.log")"; return; }
    _res 2099-07-07-03 "$2" "QP3: fixed — the figure's source is now quoted beside it" || { echo "REFUSED-A-PLAIN-ANSWER: $(tail -1 "$2/res.log")"; return; }
    # the documented cost (rule-checker run 2026-10-13-950 Q4): an answer BY WORK that only quotes a phrase is refused
    # too until it names the ticket that owned the case — 5 of the 19 past matches (runs 825, 932, 933, 938, 939) were such
    if _res 2099-07-07-04 "$2" "QP3: fixed — report.md no longer says the case was no slip"; then echo "RESOLVED-A-QUOTED-PHRASE-UNTICKETED"; return; fi
    _res 2099-07-07-04 "$2" "QP3: fixed — report.md no longer says the case was no slip (#9001)" || { echo "REFUSED-A-QUOTED-PHRASE-WITH-ITS-TICKET: $(tail -1 "$2/res.log")"; return; }
    echo BLAME-OK
}
unblame() {  # unblame <out> — the shadow tool: resolve without the instrument-blame check
    sed 's/^BLAME_CHECKED = True /BLAME_CHECKED = False /' tools/rulecheck.py > "$1"
    grep -q '^BLAME_CHECKED = False ' "$1" || { echo "the blame check's switch was not found" >&2; return 1; }
}
# SECTION RESOLVE RECHECK's probe (#270, 14z-199): on a throwaway GIT root (a `14z-0:` commit, so BASE derives), a
# two-row standing set using every placeholder, RENDERED by the real tools/close_standing.py (plus one --extra row);
# `figs` passes only once the fix exists ({RUN}/fixed), and `resolve --recheck` RUNS the checks itself (run 970 Q4).
# EVERY case runs, each on its own VIOLATED run, and the probe prints RECHECK-OK or the list of what was wrongly
# accepted (RESOLVED-ON-*) or refused for the wrong reason (WRONG-REFUSAL-*), so each control proves ITS case (run 973):
# accepted — the fix made; refused — the fix not made (a red re-check) beside a forged all-OK record, no or an unknown
# check, the close's own --extra check, a pruned render, a hand-edited command, shell text in a filled {ROW} or {RUN},
# another sitting's render, another transcript, another BASE, another SESSDIR, and a file with no render line
resolve_recheck() {  # resolve_recheck <rulecheck.py to test> <root>
    _R="$2"; rm -rf "$2"; mkcopy "$2"; cp "$1" "$2/tools/rulecheck.py"
    ( cd "$2" && git init -q . && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init \
        && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m "14z-0: probe" ) || { echo "NO-GIT-ROOT"; return; }
    printf '# standing\nfigs\t0\tthe figures\t-\t-\ttest -f {RUN}/fixed && echo figures ok --row "{ROW}"\nquotes\t0\tthe quotes\t-\t-\techo quotes ok {KEY} {TRANSCRIPT} {BASE} {SESSDIR}\n' > "$2/tests/close_standing_checks.tsv"
    printf 'mine\t0\tmine\t-\t-\techo mine ok\n' > "$2/extra.tsv"
    # a fake HOME holding this project's transcript, under the name close_standing.py derives it by (run 972 Q4)
    _H="$2.home"; rm -rf "$_H"; _tdir="$_H/.claude/projects/$(cd "$2" && git rev-parse --show-toplevel | python3 -c "import re,sys; print(re.sub(r'[^A-Za-z0-9]', '-', sys.stdin.read().strip()))")"
    mkdir -p "$_tdir"; : > "$_tdir/t.jsonl"
    _render() { ( cd "$_R" && HOME="$_H" python3 tools/close_standing.py render --key "${1:-14z-0}" --row "(2) THE FINDINGS TABLE" --run build/cr --extra extra.tsv ${2:-} ) > "$_R/render.log" 2>&1; }
    _edit() { python3 - "$_R/build/cr/checks.tsv" "$1" "$2" "${3:-}" <<'PYE'
import re, sys
p, name, a, b = sys.argv[1:]
out = []
for ln in open(p):
    f = ln.rstrip("\n").split("\t")
    if not ln.startswith("#") and f[0] == name:
        if a == "DELETE":
            continue
        cmd = re.sub(a, b, f[2]) if b else a       # with a replacement: a regex substitution; alone: the new command
        ln = f"{f[0]}\t{f[1]}\t{cmd}\n"
    out.append(ln)
open(p, "w").write("".join(out))
PYE
    }
    _render || { echo "NO-RENDER: $(tail -1 "$2/render.log")"; return; }
    python3 - "$2" <<'PY3' || { echo "NO-FIXTURE-RUNS"; return; }
import sys
from pathlib import Path
root = Path(sys.argv[1]); sys.path.insert(0, str(root / "tools")); import rulecheck as r
for n in range(1, 17):
    rid = f"2099-08-08-{n:02d}"
    r.append_ledger(root, dict(id=rid, date="2099-08-08", session="14z-1" if n == 10 else "14z-0", decision="recommendation",
                               subject=f"the close: the documentation packet {n}", control="fx", control_verdict="CAUGHT",
                               verdict="VIOLATED", violated="Q1", resolution="-", model="m"))
    d = root / r.RUNS / rid; d.mkdir(parents=True, exist_ok=True)
    (d / "verdict_real.txt").write_text("Q1: VIOLATED — a figure\n")
PY3
    _out=""
    _rr() { ( cd "$_R" && HOME="$_H" python3 tools/rulecheck.py resolve "$1" --how "Q1: fixed — the figure now equals its source" $2 ) > "$_R/res.log" 2>&1; }
    _no() {  # _no <run> <case> <expected refusal text> <resolve args>
        if _rr "$1" "$4"; then _out="$_out RESOLVED-ON-$2"
        elif ! grep -q -- "$3" "$_R/res.log"; then _out="$_out WRONG-REFUSAL-$2[$(tail -1 "$_R/res.log" | cut -c1-80)]"; fi; }
    # the fix NOT made: the re-check is red, and a forged all-OK run record beside it changes nothing
    mkdir -p "$2/build/cr/out"; printf '# run: full 2099-12-31T00:00:00Z deadbeef %s\nname\texpect\texit\tverdict\tseconds\tcommand\nfigs\t0\t0\tOK\t0\tx\nquotes\t0\t0\tOK\t0\tx\nmine\t0\t0\tOK\t0\tx\n' \
        "$(python3 -c "import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest()[:16])" "$2/build/cr/checks.tsv")" > "$2/build/cr/out/exits.tsv"
    _no 2099-08-08-02 A-RED-RECHECK "is not clean" "--recheck build/cr --checks figs"
    : > "$2/build/cr/fixed"   # the fix made
    if _rr 2099-08-08-01 "--recheck build/cr --checks figs"; then
        grep -q "^2099-08-08-01	.*RECHECKED by build/cr (.*checks figs) — Q1: fixed" "$2/tests/rulecheck/ledger.tsv" || _out="$_out RECHECK-NOT-RECORDED"
    else _out="$_out REFUSED-A-GOOD-RECHECK[$(tail -1 "$2/res.log" | cut -c1-80)]"; fi
    _no 2099-08-08-03 AN-UNKNOWN-CHECK "has no check nosuch" "--recheck build/cr --checks nosuch"
    _no 2099-08-08-04 NO-CHECK "needs --checks" "--recheck build/cr"
    _no 2099-08-08-05 THE-CLOSES-OWN-CHECK "is not a standing check" "--recheck build/cr --checks mine"
    _edit quotes DELETE;                                         _no 2099-08-08-06 A-PRUNED-RENDER "lacks the standing check quotes" "--recheck build/cr --checks figs"
    _render; _edit quotes "true";                                _no 2099-08-08-07 A-HAND-EDITED-CHECK "is not the standing row" "--recheck build/cr --checks quotes"
    _render; _edit figs '--row "[^"]*"' '--row "x" || true; echo ""'; _no 2099-08-08-08 A-SHELL-FILLED-ROW "is not the standing row" "--recheck build/cr --checks figs"
    _render; _edit figs 'build/cr/fixed' 'build/cr; true/fixed';  _no 2099-08-08-09 A-SHELL-FILLED-RUN "is not the standing row" "--recheck build/cr --checks figs"
    _render;                                                     _no 2099-08-08-10 ANOTHER-SESSIONS-RENDER "not for run 2099-08-08-10's session 14z-1" "--recheck build/cr --checks figs"
    _render 14z-0 "--transcript /x/other.jsonl";                 _no 2099-08-08-11 ANOTHER-TRANSCRIPT "is not the standing row" "--recheck build/cr --checks figs"
    _render; _edit quotes ' [0-9a-f]{7,40} build$' ' 0123abcd build'; _no 2099-08-08-12 ANOTHER-BASE "is not the standing row" "--recheck build/cr --checks figs"
    _render; _edit quotes ' build$' ' elsewhere';                _no 2099-08-08-13 ANOTHER-SESSDIR "is not the standing row" "--recheck build/cr --checks figs"
    _render; sed '1d' "$2/build/cr/checks.tsv" > "$2/build/cr/c.tmp" && mv "$2/build/cr/c.tmp" "$2/build/cr/checks.tsv"
    _no 2099-08-08-14 A-HAND-WRITTEN-FILE "was not rendered from" "--recheck build/cr --checks figs"
    _rr 2099-08-08-15 "" || _out="$_out REFUSED-A-PLAIN-RESOLVE"
    echo "${_out# }" | grep >/dev/null . && echo "${_out# }" || echo RECHECK-OK
}
unrecheck() {  # unrecheck <out> — the shadow tool: resolve takes any --recheck at its word
    sed 's/^RECHECK_CHECKED = True /RECHECK_CHECKED = False /' tools/rulecheck.py > "$1"
    grep -q '^RECHECK_CHECKED = False ' "$1" || { echo "the recheck switch was not found" >&2; return 1; }
}
unpinnedbase() {  # unpinnedbase <out> — the shadow tool: BASE matches any hash
    sed 's/^BASE_PINNED = True /BASE_PINNED = False /' tools/rulecheck.py > "$1"
    grep -q '^BASE_PINNED = False ' "$1" || { echo "the base switch was not found" >&2; return 1; }
}
othersession() {  # othersession <out> — the shadow tool: KEY and TRANSCRIPT not bound to the run's session
    sed 's/^SESSION_BOUND = True /SESSION_BOUND = False /' tools/rulecheck.py > "$1"
    grep -q '^SESSION_BOUND = False ' "$1" || { echo "the session switch was not found" >&2; return 1; }
}
prunedrender() {  # prunedrender <out> — the shadow tool: only the named standing rows are bound
    sed 's/^EVERY_ROW = True /EVERY_ROW = False /' tools/rulecheck.py > "$1"
    grep -q '^EVERY_ROW = False ' "$1" || { echo "the every-row switch was not found" >&2; return 1; }
}
porousfill() {  # porousfill <out> — the shadow tool: a placeholder matches anything
    sed 's/^FILL_STRICT = True /FILL_STRICT = False /' tools/rulecheck.py > "$1"
    grep -q '^FILL_STRICT = False ' "$1" || { echo "the fill switch was not found" >&2; return 1; }
}
ownchecks() {  # ownchecks <out> — the shadow tool: --recheck takes any checks file
    sed 's/^STANDING_BOUND = True /STANDING_BOUND = False /' tools/rulecheck.py > "$1"
    grep -q '^STANDING_BOUND = False ' "$1" || { echo "the standing switch was not found" >&2; return 1; }
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

if [ "${VS_CTL:-}" = blame-unticketed ]; then
    unblame "$W/unblamed.py" || exit 3
    got="$(resolve_blame "$W/unblamed.py" "$W/rbl_mode")"
    echo "MODE: control blame-unticketed — the shadow copy reads: $got"
    case "$got" in RESOLVED-BLAME-*) ;; *) echo "REFUSED: the shadow copy did not record an unticketed blame ($got)"; exit 3;; esac
    echo "FAIL: rule-checker resolve blame (control mode blame-unticketed — $got)"; exit 1
fi

if [ "${VS_CTL:-}" = recheck-unpinned-base ]; then
    unpinnedbase "$W/unpinnedbase.py" || exit 3
    got="$(resolve_recheck "$W/unpinnedbase.py" "$W/rub_mode")"
    echo "MODE: control recheck-unpinned-base — the shadow copy reads: $got"
    case "$got" in *RESOLVED-ON-ANOTHER-BASE*) ;; *) echo "REFUSED: the shadow copy did not accept another BASE ($got)"; exit 3;; esac
    echo "FAIL: rule-checker resolve recheck (control mode recheck-unpinned-base — $got)"; exit 1
fi

if [ "${VS_CTL:-}" = recheck-other-session ]; then
    othersession "$W/othersess.py" || exit 3
    got="$(resolve_recheck "$W/othersess.py" "$W/ros_mode")"
    echo "MODE: control recheck-other-session — the shadow copy reads: $got"
    case "$got" in *RESOLVED-ON-ANOTHER-SESSIONS-RENDER*) ;; *) echo "REFUSED: the shadow copy did not accept another session's render ($got)"; exit 3;; esac
    echo "FAIL: rule-checker resolve recheck (control mode recheck-other-session — $got)"; exit 1
fi

if [ "${VS_CTL:-}" = recheck-pruned-render ]; then
    prunedrender "$W/pruned.py" || exit 3
    got="$(resolve_recheck "$W/pruned.py" "$W/rpr_mode")"
    echo "MODE: control recheck-pruned-render — the shadow copy reads: $got"
    case "$got" in *RESOLVED-ON-A-PRUNED-RENDER*) ;; *) echo "REFUSED: the shadow copy did not accept a pruned render ($got)"; exit 3;; esac
    echo "FAIL: rule-checker resolve recheck (control mode recheck-pruned-render — $got)"; exit 1
fi

if [ "${VS_CTL:-}" = recheck-porous-fill ]; then
    porousfill "$W/porous.py" || exit 3
    got="$(resolve_recheck "$W/porous.py" "$W/rpf_mode")"
    echo "MODE: control recheck-porous-fill — the shadow copy reads: $got"
    case "$got" in *RESOLVED-ON-A-SHELL-FILLED-ROW*RESOLVED-ON-ANOTHER-SESSDIR*) ;; *) echo "REFUSED: the shadow copy did not accept a shell-filled row ($got)"; exit 3;; esac
    echo "FAIL: rule-checker resolve recheck (control mode recheck-porous-fill — $got)"; exit 1
fi

if [ "${VS_CTL:-}" = recheck-own-checks ]; then
    ownchecks "$W/ownchecks.py" || exit 3
    got="$(resolve_recheck "$W/ownchecks.py" "$W/roc_mode")"
    echo "MODE: control recheck-own-checks — the shadow copy reads: $got"
    case "$got" in *RESOLVED-ON-THE-CLOSES-OWN-CHECK*) ;; *) echo "REFUSED: the shadow copy did not accept the close's own check ($got)"; exit 3;; esac
    echo "FAIL: rule-checker resolve recheck (control mode recheck-own-checks — $got)"; exit 1
fi

if [ "${VS_CTL:-}" = recheck-unchecked ]; then
    unrecheck "$W/unrechecked.py" || exit 3
    got="$(resolve_recheck "$W/unrechecked.py" "$W/rrc_mode")"
    echo "MODE: control recheck-unchecked — the shadow copy reads: $got"
    case "$got" in *RESOLVED-ON-A-RED-RECHECK*) ;; *) echo "REFUSED: the shadow copy did not accept a red re-check ($got)"; exit 3;; esac
    echo "FAIL: rule-checker resolve recheck (control mode recheck-unchecked — $got)"; exit 1
fi

if [ "${VS_CTL:-}" = unfiltered-plants ]; then
    unfiltered "$W/unfiltered.py" || exit 3
    got="$(plant_rotation "$W/unfiltered.py" "$W/prot_mode")"
    echo "MODE: control unfiltered-plants — the shadow copy reads: $got"
    case "$got" in REFUSED-AT-POSITION-*) ;; *) echo "REFUSED: the shadow copy drew no over-limit plant ($got)"; exit 3;; esac
    echo "FAIL: rule-checker plant rotation (control mode unfiltered-plants — $got)"; exit 1
fi

if [ "${VS_CTL:-}" = unlimited-read ]; then
    unlimited "$W/unlimited.py" || exit 3
    got="$(prepare_readlimit "$W/unlimited.py" "$W/prl_mode")"
    echo "MODE: control unlimited-read — the shadow copy reads: $got"
    case "$got" in PREPARED-AN-UNREADABLE-ARTIFACT*) ;; *) echo "REFUSED: the shadow copy did not prepare the unreadable artifact ($got)"; exit 3;; esac
    echo "FAIL: rule-checker prepare read limit (control mode unlimited-read — $got)"; exit 1
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
    crc=0; python3 tools/rulecheck.py check --root "$W/mode" > "$W/mode.log" 2>&1 || crc=$?
    cat "$W/mode.log"
    mrc=0; mode_judge "$crc" "$W/mode.log" "$(expect_msg "$VS_CTL")" > /dev/null || mrc=$?
    case "$mrc" in
        0) echo "PASS: CONTROL=$VS_CTL left the check green — the perturbation is not caught (this mode LIES)"; exit 0 ;;
        1) echo "FAIL: rule-checker record (control mode $VS_CTL reached the gate's own FAIL on its own finding)"; exit 1 ;;
        *) echo "REFUSED: CONTROL=$VS_CTL failed the check, but not on its own finding ($(expect_msg "$VS_CTL"))"; exit 3 ;;
    esac
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

echo "== PLANT ROTATION: every rotation position draws a plant a reader can read whole (#258, 14z-204) =="
got="$(plant_rotation tools/rulecheck.py "$W/prot")"
echo "  the real tool: $got"
[ "$got" = ROTATION-OK ] || { echo "FAIL: the plant rotation ($got)"; fail=1; }

echo "== PREPARE READ LIMIT: no artifact a reader cannot read whole in one Read; an archive is named by its INDEX ranges (#258) =="
got="$(prepare_readlimit tools/rulecheck.py "$W/prl")"
echo "  the real tool: $got"
[ "$got" = READ-OK ] || { echo "FAIL: prepare's read limit ($got)"; fail=1; }

echo "== PREPARE CITES: a merge packet's fork runs are checked by the tool (#217) =="
got="$(prepare_cites tools/rulecheck.py "$W/pcites")"
echo "  $got"
[ "$got" = CITES-OK ] || { echo "FAIL: prepare's citations ($got)"; fail=1; }

echo "== MODE VERDICT: a mode is honoured only on its own finding (runs 2026-10-13-952/953) =="
printf '  FAIL: 2026-10-13-950: VIOLATED with no resolution — the action it stopped is still stopped\n' > "$W/mv_other.log"
{ cat "$W/mv_other.log"; printf '  FAIL: 2026-09-17-01: %s (reads VIOLATED)\n' "$(expect_msg quiet-control)"; } > "$W/mv_own.log"
# set -e: each judgement's exit is captured with `||` so a non-zero verdict does not end the gate
r1=0; mv1="$(mode_judge 1 "$W/mv_other.log" "$(expect_msg quiet-control)")" || r1=$?
r2=0; mv2="$(mode_judge 1 "$W/mv_own.log" "$(expect_msg quiet-control)")" || r2=$?
r3=0; mv3="$(mode_judge 0 "$W/mv_own.log" "$(expect_msg quiet-control)")" || r3=$?
echo "  another finding only: $mv1 ($r1); its own finding beside another: $mv2 ($r2); the check green: $mv3 ($r3)"
[ "$r1/$r2/$r3" = "3/1/0" ] || { echo "FAIL: the mode verdict reads $r1/$r2/$r3, not 3/1/0 (REFUSED / honoured / lies)"; fail=1; }

echo "== RESOLVE BLAME: resolve refuses an instrument-blaming answer that names no open ticket (#271) =="
got="$(resolve_blame tools/rulecheck.py "$W/rbl")"
echo "  the real tool: $got"
[ "$got" = BLAME-OK ] || { echo "FAIL: resolve's instrument-blame rule ($got)"; fail=1; }

echo "== RESOLVE RECHECK: a presentation finding is resolved only on a full run of the standing close checks that resolve makes itself (#270) =="
got="$(resolve_recheck tools/rulecheck.py "$W/rrc")"
echo "  the real tool: $got"
[ "$got" = RECHECK-OK ] || { echo "FAIL: resolve's re-check route ($got)"; fail=1; }

echo "== RESOLVE BLAME on the REAL index: open_tickets reads docs/project/tickets.tsv's status column (run 2026-10-13-955) =="
# an independent reader — awk on the column the index's own header names `status` — against the tool's set
col="$(awk -F'\t' '/^#/ {next} {for (i = 1; i <= NF; i++) if ($i == "status") {print i; exit}}' docs/project/tickets.tsv)"
[ -n "$col" ] || { echo "FAIL: docs/project/tickets.tsv has no header row naming a status column"; col=0; fail=1; }
indep="$(awk -F'\t' -v c="$col" '!/^#/ && ($c == "open" || $c == "parked") {print $1}' docs/project/tickets.tsv | sort -n | tr '\n' ' ')"
tool="$(python3 -c "import sys; sys.path.insert(0, 'tools'); import rulecheck; from pathlib import Path; print(' '.join(sorted(rulecheck.open_tickets(Path('.')), key=int)))") "
n_open="$(printf '%s' "$indep" | wc -w | tr -d ' ')"; n_done="$(awk -F'\t' -v c="$col" '!/^#/ && $c == "done"' docs/project/tickets.tsv | wc -l | tr -d ' ')"
if [ "$indep" = "$tool" ] && [ "$n_open" -gt 0 ] && [ "$n_done" -gt 0 ]; then echo "  ok    the tool's open set equals the index's status column (column $col): $n_open open or parked, $n_done done left out"
else echo "FAIL: open_tickets disagrees with the index's status column $col — tool: $tool | index: $indep"; fail=1; fi

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

if unblame "$W/unblamed_c.py"; then
    got="$(resolve_blame "$W/unblamed_c.py" "$W/rblc")"
    case "$got" in
        RESOLVED-BLAME-*) vs_ctl_fired blame-unticketed "the copy without the blame check: $got";;
        *) vs_ctl_dead blame-unticketed "the shadow copy read $got"; fail=1;;
    esac
else
    vs_ctl_dead blame-unticketed "the blame check's switch was not found"; fail=1
fi

if unpinnedbase "$W/unpinnedbase_c.py"; then
    got="$(resolve_recheck "$W/unpinnedbase_c.py" "$W/rubc")"
    case "$got" in
        *RESOLVED-ON-ANOTHER-BASE*) vs_ctl_fired recheck-unpinned-base "the copy letting BASE be any hash: $got";;
        *) vs_ctl_dead recheck-unpinned-base "the shadow copy read $got"; fail=1;;
    esac
else
    vs_ctl_dead recheck-unpinned-base "the base switch was not found"; fail=1
fi

if othersession "$W/othersess_c.py"; then
    got="$(resolve_recheck "$W/othersess_c.py" "$W/rosc")"
    case "$got" in
        *RESOLVED-ON-ANOTHER-SESSIONS-RENDER*) vs_ctl_fired recheck-other-session "the copy not bound to the run's session: $got";;
        *) vs_ctl_dead recheck-other-session "the shadow copy read $got"; fail=1;;
    esac
else
    vs_ctl_dead recheck-other-session "the session switch was not found"; fail=1
fi

if prunedrender "$W/pruned_c.py"; then
    got="$(resolve_recheck "$W/pruned_c.py" "$W/rprc")"
    case "$got" in
        *RESOLVED-ON-A-PRUNED-RENDER*) vs_ctl_fired recheck-pruned-render "the copy binding only the named rows: $got";;
        *) vs_ctl_dead recheck-pruned-render "the shadow copy read $got"; fail=1;;
    esac
else
    vs_ctl_dead recheck-pruned-render "the every-row switch was not found"; fail=1
fi

if porousfill "$W/porous_c.py"; then
    got="$(resolve_recheck "$W/porous_c.py" "$W/rpfc")"
    case "$got" in
        *RESOLVED-ON-A-SHELL-FILLED-ROW*RESOLVED-ON-ANOTHER-SESSDIR*) vs_ctl_fired recheck-porous-fill "the copy with a porous fill: $got";;
        *) vs_ctl_dead recheck-porous-fill "the shadow copy read $got"; fail=1;;
    esac
else
    vs_ctl_dead recheck-porous-fill "the fill switch was not found"; fail=1
fi

if ownchecks "$W/ownchecks_c.py"; then
    got="$(resolve_recheck "$W/ownchecks_c.py" "$W/rocc")"
    case "$got" in
        *RESOLVED-ON-THE-CLOSES-OWN-CHECK*) vs_ctl_fired recheck-own-checks "the copy without the standing binding: $got";;
        *) vs_ctl_dead recheck-own-checks "the shadow copy read $got"; fail=1;;
    esac
else
    vs_ctl_dead recheck-own-checks "the standing switch was not found"; fail=1
fi

if unrecheck "$W/unrechecked_c.py"; then
    got="$(resolve_recheck "$W/unrechecked_c.py" "$W/rrcc")"
    case "$got" in
        *RESOLVED-ON-A-RED-RECHECK*) vs_ctl_fired recheck-unchecked "the copy without the re-check binding: $got";;
        *) vs_ctl_dead recheck-unchecked "the shadow copy read $got"; fail=1;;
    esac
else
    vs_ctl_dead recheck-unchecked "the recheck switch was not found"; fail=1
fi

if unfiltered "$W/unfiltered_c.py"; then
    got="$(plant_rotation "$W/unfiltered_c.py" "$W/protc")"
    case "$got" in
        REFUSED-AT-POSITION-*) vs_ctl_fired unfiltered-plants "the rotation without the filter: $got";;
        *) vs_ctl_dead unfiltered-plants "the rotation without the filter read $got"; fail=1;;
    esac
else
    vs_ctl_dead unfiltered-plants "the readable-plant filter was not found to remove"; fail=1
fi

if unlimited "$W/unlimited_c.py"; then
    got="$(prepare_readlimit "$W/unlimited_c.py" "$W/prlc")"
    case "$got" in
        PREPARED-AN-UNREADABLE-ARTIFACT*) vs_ctl_fired unlimited-read "the copy with no read limit: $got";;
        *) vs_ctl_dead unlimited-read "the copy with no read limit read $got"; fail=1;;
    esac
else
    vs_ctl_dead unlimited-read "the READ_MAX lines were not found to lift"; fail=1
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
    echo "PASS: the rule-checker's record is sound, record binds the spawn check, prepare's ids hold, prepare requires the session key, a merge packet's cited fork runs are checked, resolve refuses unticketed instrument blame and takes a re-check only from a full run of the standing close checks it makes itself, prepare hands a reader nothing it cannot read whole and every plant rotation position is readable (#258), and its nineteen controls fire"
else
    echo "FAIL: rule-checker record"
    exit 1
fi
