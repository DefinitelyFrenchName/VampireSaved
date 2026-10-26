#!/bin/sh
# test_packet_check.sh — THE PRE-PREPARE CHECK POINTS AT WHAT A SCRIPT CAN SEE BEFORE THE READERS ARE SPAWNED
# (tools/packet_check.py, run by `tools/rulecheck.py prepare`; #272, ruled 2026-10-12 (14z-199): "let's try your
# proposal and iterate on it, based on measured data"). ci_portable: no ROM, no emulator, a few seconds.
#
# WHAT: (1) the check's logic on known answers (its --selftest): a claim figure, a double-quoted span and an
#   attribution to the maintainer that no artifact holds are flagged, and a run or line number, a thousands
#   separator, a quote held across an ellipsis, a single-quoted held attribution and a "not put to the maintainer"
#   are not; a deliverable is read only when named, and then its untied absolute sentence and its unsourced figure
#   are flagged while a sentence tied to a `name` and a figure another artifact holds are not; the replay's matcher
#   pairs each kind with the evidence that names it; the replay reads a synthetic ledger's REAL slot (the one control.txt
#   does not name), refuses a run with no recorded slot or a staged copy that differs from its manifest, and stops at
#   --through; its AS FILED tally refuses only on the filed kinds and buckets each run once by size; (2) PREPARE on a throwaway copy: a packet with an unsourced
#   figure and a deliverable holding an untied absolute sentence is PREPARED (the check never refuses), prints its
#   flags, and keeps them as the run's precheck.txt and its meta.tsv `precheck` line; a --deliverable that is not
#   one of the --artifact paths is refused.
# HOW: section 1 runs tools/packet_check.py --selftest; section 2 builds a throwaway copy of what prepare reads
#   (the tools, tools/agent/, the rule-checker spec, the ledger and its fixtures, the pinned reader) and prepares two
#   packets on it with the tool under test.
# EXPECTS: SELFTEST PASS and PRECHECK-OK. A run with neither verdict is REFUSED.
#
# MUST-FIRE: known-bad: deliverable-ignored — tools/packet_check.py --selftest --deliverable-ignored: a check that does not read the packet's deliverables must print SELFTEST FAIL on the deliverable case, while --selftest passes (mode: the self-test runs the known-bad variant and the gate FAILs)
# MUST-FIRE: known-bad: replay-unbound — tools/packet_check.py --selftest --replay-unbound: a replay that takes slot a when control.txt names no plant slot and never checks the staged copy against the run's manifest.tsv must print SELFTEST FAIL on those two replay cases, while --selftest passes: the replay's figures are what #272 was decided on (rule-checker run 2026-10-13-962 Q4; mode: the self-test runs the known-bad variant and the gate FAILs)
# MUST-FIRE: known-bad: tally-any-flag — tools/packet_check.py --selftest --tally-any-flag: an AS FILED tally that refuses on any flag kind (not only the filed FIGURE and ATTRIB) must print SELFTEST FAIL on the tally case, while --selftest passes: the refusal counts #272 was decided on come from that tally (rule-checker run 2026-10-13-964 Q4; mode: the self-test runs the known-bad variant and the gate FAILs)
# MUST-FIRE: shadow-tool: unkept-flags — a copy of rulecheck.py whose prepare does not write precheck.txt must prepare a run without its flags kept, and the PREPARE section must FAIL: the flags are kept with the run so a later measurement can count what they caught live (mode: the section runs that copy)
#
# WHY: in 14z-188..14z-198 most rule-checker runs were VIOLATED, and the 14z-199 report took 13 VIOLATED rounds
#   (runs 932-944); measured (docs/project/rule_checker.md § "The pre-prepare check (#272)"), a script points at
#   a small share of what the readers find, so the check flags and never refuses.
#
# Usage: tests/test_packet_check.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d "${TMPDIR:-/tmp}/pcheck.XXXXXX")"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

if [ -z "${VS_CTL:-}" ] || vs_ctl_is deliverable-ignored || vs_ctl_is replay-unbound || vs_ctl_is tally-any-flag; then
echo "== 1. the check's logic on known answers (--selftest)"
v=""; vs_ctl_is deliverable-ignored && { v="--deliverable-ignored"; echo "MODE: control deliverable-ignored — the self-test runs the variant that does not read the deliverables"; }
vs_ctl_is tally-any-flag && { v="--tally-any-flag"; echo "MODE: control tally-any-flag — the self-test runs the tally that refuses on any flag kind"; }
vs_ctl_is replay-unbound && { v="--replay-unbound"; echo "MODE: control replay-unbound — the self-test runs the replay that takes slot a by default and skips the manifest"; }
out="$(python3 tools/packet_check.py --selftest $v 2>&1)"
if printf '%s\n' "$out" | grep >/dev/null '^SELFTEST PASS'; then ok "SELFTEST PASS ($(printf '%s\n' "$out" | grep -c '^  ok ') cases)"
elif printf '%s\n' "$out" | grep >/dev/null '^SELFTEST FAIL'; then
    bad "$(printf '%s\n' "$out" | grep 'WRONG' | tr '\n' ' ' | cut -c1-200)"
    if vs_ctl_is deliverable-ignored && ! printf '%s\n' "$out" | grep >/dev/null 'WRONG  D-ABSOLUTE and D-FIGURE'; then
        echo "REFUSED: mode deliverable-ignored — the self-test failed, but not on the deliverable case"; exit 3; fi
    if vs_ctl_is replay-unbound && ! { printf '%s\n' "$out" | grep >/dev/null 'WRONG  replay: no slot in control.txt' && printf '%s\n' "$out" | grep >/dev/null 'WRONG  replay: a staged copy changed'; }; then
        echo "REFUSED: mode replay-unbound — the self-test failed, but not on the two replay cases"; exit 3; fi
    if vs_ctl_is tally-any-flag && ! printf '%s\n' "$out" | grep >/dev/null 'WRONG  replay: the AS FILED tally refuses the OK run'; then
        echo "REFUSED: mode tally-any-flag — the self-test failed, but not on the tally case"; exit 3; fi
else echo "REFUSED: tools/packet_check.py --selftest printed no SELFTEST line (a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi
fi

# PREPARE on a throwaway copy of what prepare reads
prepare_probe() {  # prepare_probe <rulecheck.py to test> <root> — prints PRECHECK-OK or what went wrong
    mkdir -p "$2/docs/project" "$2/tests/expected" "$2/tools" "$2/.claude/agents" "$2/build/pc"
    cp "$1" "$2/tools/rulecheck.py"; cp tools/claim_lint.py tools/packet_check.py "$2/tools/"
    cp -R tools/agent "$2/tools/agent"; _doc=docs/project/rule_checker.md; cp "$_doc" "$2/docs/project/"
    cp tests/expected/registry.tsv "$2/tests/expected/"; cp -R tests/rulecheck "$2/tests/rulecheck"
    cp .claude/agents/rule-checker.md "$2/.claude/agents/"
    printf 'checks run 72\n' > "$2/build/pc/run.log"
    printf '# Report\n\nThe close ran 72 checks (build/pc/run.log).\n\nOne case alone failed ten runs.\n' > "$2/build/pc/report.md"
    _claim="The report's figures hold: 73 checks ran (build/pc/run.log). NOT TESTED: nothing else."
    if ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject "packet check probe" \
            --claim "$_claim" --artifact build/pc/run.log --artifact build/pc/report.md --deliverable build/pc/other.md \
            --session 14z-0 --id 2099-04-04-01 ) > "$2/p0.log" 2>&1; then echo "UNLISTED-DELIVERABLE-ACCEPTED"; return; fi
    grep -q -- "--deliverable must be one of the --artifact paths" "$2/p0.log" || { echo "REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/p0.log")"; return; }
    ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject "packet check probe" \
            --claim "$_claim" --artifact build/pc/run.log --artifact build/pc/report.md --deliverable build/pc/report.md \
            --session 14z-0 --id 2099-04-04-02 ) > "$2/p1.log" 2>&1 || { echo "NOT-PREPARED: $(tail -1 "$2/p1.log")"; return; }
    grep -q '^PACKET CHECK (#272)' "$2/p1.log" || { echo "NO-FLAGS-PRINTED"; return; }
    _r="$2/tests/rulecheck/runs/2099-04-04-02"
    [ -f "$_r/precheck.txt" ] || { echo "FLAGS-NOT-KEPT"; return; }
    grep -q '^  FLAG FIGURE: 73$' "$_r/precheck.txt" || { echo "NO-FIGURE-FLAG: $(tr '\n' ' ' < "$_r/precheck.txt" | cut -c1-160)"; return; }
    grep -q '^  FLAG D-ABSOLUTE: One case alone failed ten runs\.  \[build/pc/report.md\]$' "$_r/precheck.txt" \
        || { echo "NO-DELIVERABLE-FLAG: $(tr '\n' ' ' < "$_r/precheck.txt" | cut -c1-160)"; return; }
    grep -q '^precheck	2 flag(s): D-ABSOLUTE 1, FIGURE 1$' "$_r/meta.tsv" || { echo "META-PRECHECK: $(grep '^precheck' "$_r/meta.tsv")"; return; }
    grep -q '^deliverables	build/pc/report.md$' "$_r/meta.tsv" || { echo "META-DELIVERABLES"; return; }
    echo PRECHECK-OK
}
unkept() {  # unkept <out> — the shadow tool: prepare without the precheck.txt write
    sed 's/^        (rdir \/ "precheck.txt").write_text(/        (rdir \/ "precheck.unkept").write_text(/' tools/rulecheck.py > "$1"
    grep -q 'precheck.unkept' "$1" || { echo "the precheck.txt write was not found to remove" >&2; return 1; }
}

if [ -z "${VS_CTL:-}" ] || vs_ctl_is unkept-flags; then
echo "== 2. PREPARE prints the flags, keeps them with the run, and never refuses on them"
tool=tools/rulecheck.py
if vs_ctl_is unkept-flags; then echo "MODE: control unkept-flags — the section runs a copy of rulecheck.py that does not write precheck.txt"
    unkept "$W/rulecheck_unkept.py" || { echo "REFUSED: the shadow tool could not be built"; exit 3; }; tool="$W/rulecheck_unkept.py"; fi
got="$(prepare_probe "$tool" "$W/root")"
case "$got" in
PRECHECK-OK) ok "PRECHECK-OK — prepared with 2 flags kept (precheck.txt, meta.tsv), an unlisted --deliverable refused" ;;
*) bad "the prepare probe: $got"
   if vs_ctl_is unkept-flags && [ "$got" != FLAGS-NOT-KEPT ]; then echo "REFUSED: mode unkept-flags — the probe failed, but not on the kept flags ($got)"; exit 3; fi ;;
esac
fi

if [ -z "${VS_CTL:-}" ]; then
echo "== 3. MUST-FIRE CONTROLS (executed in-gate)"
o="$(python3 tools/packet_check.py --selftest --deliverable-ignored 2>&1)"
if printf '%s\n' "$o" | grep >/dev/null 'WRONG  D-ABSOLUTE and D-FIGURE' && printf '%s\n' "$o" | grep >/dev/null '^SELFTEST FAIL'; then
    echo "CONTROL FIRED: deliverable-ignored — the self-test FAILs on the deliverable case"
else echo "CONTROL DEAD: deliverable-ignored — the variant that reads no deliverable passed the self-test"; fail=1; fi
o="$(python3 tools/packet_check.py --selftest --replay-unbound 2>&1)"
if printf '%s\n' "$o" | grep >/dev/null 'WRONG  replay: no slot in control.txt' && printf '%s\n' "$o" | grep >/dev/null 'WRONG  replay: a staged copy changed' \
        && printf '%s\n' "$o" | grep >/dev/null '^SELFTEST FAIL'; then
    echo "CONTROL FIRED: replay-unbound — the self-test FAILs on the unrecorded slot and the changed staged copy"
else echo "CONTROL DEAD: replay-unbound — the unbound replay passed the self-test"; fail=1; fi
o="$(python3 tools/packet_check.py --selftest --tally-any-flag 2>&1)"
if printf '%s\n' "$o" | grep >/dev/null 'WRONG  replay: the AS FILED tally refuses the OK run' && printf '%s\n' "$o" | grep >/dev/null '^SELFTEST FAIL'; then
    echo "CONTROL FIRED: tally-any-flag — the self-test FAILs on the AS FILED tally case"
else echo "CONTROL DEAD: tally-any-flag — the tally refusing on any flag passed the self-test"; fail=1; fi
unkept "$W/rulecheck_unkept.py" && g="$(prepare_probe "$W/rulecheck_unkept.py" "$W/root_ctl")" || g="SHADOW-NOT-BUILT"
if [ "$g" = FLAGS-NOT-KEPT ]; then echo "CONTROL FIRED: unkept-flags — the probe reads FLAGS-NOT-KEPT on the copy"
else echo "CONTROL DEAD: unkept-flags — the probe read $g on the copy that keeps no flags"; fail=1; fi
fi

if [ "$fail" = 0 ]; then echo "GREEN: test_packet_check — the check's logic and prepare's flags"; exit 0; fi
echo "RED: test_packet_check"; exit 1
