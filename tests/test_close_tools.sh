#!/bin/sh
# test_close_tools.sh — THE CLOSE RITUAL'S TWO FILE-LEVEL CHECKS RUN AND CAN FAIL: the retraction
# grep reaches the tree (tools/retraction_grep.py) and the findings table's homes and tests are
# tracked files (tools/homes_tracked.py). ci_portable: no ROM, no emulator, ~3 s (14z-181).
#
# WHAT: (1) tools/retraction_grep.py over every tests/rulecheck/retractions/*.tsv exits 0, ON THE LIVE
#   TREE at every tier (an output file is a snapshot with a tree fingerprint, never the check) — each
#   file's REACH controls (a live heading, a corrected wording in plain AND code-spanned form — a
#   `reach:2` control that fails when either carrier is missed — a carrier line-wrapped across a
#   `#` comment prefix, a sentence that lives only in a ROOT document, README.md — the scan reads
#   every tracked file since rule-checker run 2026-09-25-204) are found in the live tree and every
#   GONE wording reads 0 hits, so the sitting's
#   retracted wordings were searched by a grep that reaches; (2) tools/homes_tracked.py --selftest
#   passes, and (2b) the tool runs on the NEWEST findings-table row of STATE.md (the current
#   sitting's, on the live tree: every home and test it names is tracked) — a planted findings row citing a backticked build/ file, a prose build/ path, a name
#   that resolves nowhere, a gate stem that resolves nowhere, a ticket with no index row, ticket rows
#   citing a build/ file, an untracked file and a § anchor on no line, a prose-cited document that resolves nowhere and a
#   parenthesised test clause saying scratch, and a backticked and a prose name that end two or
#   more tracked files but are none of them exactly (AMBIGUOUS, rule-checker run 2026-09-25-206), are
#   caught on all eleven, and a real gate stem, a clean ticket and a prose-cited README resolve.
# HOW: both tools run in-process on the tree; the controls run the grep on a copy of a pattern
#   file with an unreachable reach control planted, and the homes tool's self-test on its BLIND
#   variant (--blind, the build/ reads disabled), which must fail it.
# EXPECTS: PASS when every reach control of every retraction file is found, every gone wording is
#   absent, the self-test passes and the newest findings row is clean. A tool that exits non-zero
#   WITHOUT its own FAIL line (a crash, a refused pattern file) is REFUSED (exit 3, dead), never a
#   red — in a MODE too: a mode passes only on the plant's own FAIL text. A red names the pattern file and the dead control (the tree lost a carrier the
#   sitting's close depended on, or a pattern was written narrower than its carrier).
#
# MUST-FIRE: perturbed-copy: unreachable-control — a copy of a retraction TSV with a reach pattern that exists nowhere must make tools/retraction_grep.py exit 1 with a FAIL line naming it (in-gate; mode: the copy replaces the real file and the gate FAILs)
# MUST-FIRE: perturbed-copy: reach-threshold — a copy of a retraction TSV whose `reach:2` control is raised to `reach:3` (a third carrier does not exist) must make tools/retraction_grep.py exit 1 naming it, so a reach:N control that lost a carrier cannot pass on the ones left (in-gate; mode: the copy replaces the real file and the gate FAILs)
# MUST-FIRE: perturbed-copy: gone-reintroduced — a copy of a retraction TSV with a wording KNOWN to be live (a reach control's text minus its first word, so the copy repeats no pattern) marked `gone` must make tools/retraction_grep.py exit 1 naming it, so a retracted wording that comes back is a red (in-gate; mode: the copy replaces the real file and the gate FAILs)
# MUST-FIRE: known-bad: case-fold-dropped — tools/retraction_grep.py --selftest --nofold: the matcher with its case-folding REMOVED (a known-bad variant) must print SELFTEST FAIL naming the upper-case heading case, while --selftest prints SELFTEST PASS — the self-test matches planted TEXTS (a wording in an UPPER-CASE heading, one wrapped across a `#` prefix, one code-spanned), not the tree, so no stray carrier elsewhere can mask a matcher defect (rule-checker run 2026-09-25-199 Q4) (in-gate; mode: the no-fold variant is the one checked, so the gate FAILs)
# MUST-FIRE: known-bad: build-home-planted — tools/homes_tracked.py --selftest --blind: the tool with its build/ reads DISABLED (a known-bad variant) must FAIL its own self-test, whose planted row cites a backticked build/ file and a prose build/ path, an unresolved name, an unresolved gate stem, a ticket with no index row, ticket rows (a planted index) citing a build/ file, an untracked file and a § anchor on no line, a prose-cited document that resolves nowhere and a parenthesised scratch-citing test clause (in-gate: --selftest must print SELFTEST PASS and --selftest --blind must print SELFTEST FAIL naming the two build/ reads as missed — a traceback is DEAD, not fired; mode: the blind variant is the one checked, so the gate FAILs because the plant is not caught)
#
# WHY: at the 14z-181 close the two checks lived in inline scripts recorded nowhere, and the
# table they checked cited five build-only files (rule-checker runs 185-187, GitHub #152's
# discipline: a test that exists only in a build/ artifact is not a test).
#
# Usage: tests/test_close_tools.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d "${TMPDIR:-/tmp}/closetools.XXXXXX")"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

echo "== 1. the retraction grep reaches the tree (every tests/rulecheck/retractions/*.tsv)"
n=0
for f in tests/rulecheck/retractions/*.tsv; do
    [ -f "$f" ] || continue; n=$((n+1)); src="$f"
    if vs_ctl_is unreachable-control; then
        cp "$f" "$W/planted.tsv"; printf 'zq-no-such-wording-anywhere-%s\tplanted unreachable control\treach\n' "$$" >> "$W/planted.tsv"; src="$W/planted.tsv"
        echo "MODE: control unreachable-control — $f replaced by a copy with an unreachable reach pattern"
    elif vs_ctl_is reach-threshold; then
        sed 's/\treach:2$/\treach:3/' "$f" > "$W/planted.tsv"; src="$W/planted.tsv"
        grep -q '	reach:3$' "$W/planted.tsv" || { echo "FAIL: $f has no reach:2 control to raise"; exit 1; }
        echo "MODE: control reach-threshold — $f replaced by a copy whose reach:2 control demands 3 carriers"
    elif vs_ctl_is gone-reintroduced; then
        awk -F'\t' 'BEGIN{OFS="\t"} $3 ~ /^reach/ && !done {p=$1; sub(/^[^ ]+ /, "", p); print p, "planted: a live wording (a reach control minus its first word) marked gone", "gone"; done=1} {print}' "$f" > "$W/planted.tsv"; src="$W/planted.tsv"
        echo "MODE: control gone-reintroduced — $f replaced by a copy where a live reach wording is also marked gone"
    fi
    if out="$(python3 tools/retraction_grep.py "$src" 2>&1)"; then ok "$f: $(printf '%s\n' "$out" | tail -1)"
    elif printf '%s\n' "$out" | grep -q '^FAIL: '; then
        bad "$f: $(printf '%s\n' "$out" | grep '^FAIL' | cut -c1-160)"
        if [ -n "${VS_CTL:-}" ]; then   # a MODE must fail on the PLANT's own FAIL line, never on a crash
            case "$VS_CTL" in
                unreachable-control) want="zq-no-such-wording-anywhere-$$ (0 < 1)" ;;
                reach-threshold) want="(2 < 3)" ;;
                gone-reintroduced) want="marked GONE is back in the tree" ;;
                *) want="" ;;
            esac
            if [ -n "$want" ] && ! printf '%s\n' "$out" | grep -qF "$want"; then echo "REFUSED: mode $VS_CTL — the grep failed WITHOUT naming the plant ($want): $(printf '%s\n' "$out" | grep '^FAIL' | cut -c1-120)"; exit 3; fi
        fi
    else echo "REFUSED: $f — tools/retraction_grep.py exited non-zero with no FAIL line (a crash or a refusal, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi
done
[ "$n" -gt 0 ] || bad "no retraction file under tests/rulecheck/retractions/"

echo "== 1b. the matcher itself: case-folding, comment-prefix and backtick collapsing on planted texts"
nofold=""
if vs_ctl_is case-fold-dropped; then nofold="--nofold"; echo "MODE: control case-fold-dropped — the matcher self-test runs WITHOUT case-folding"; fi
out="$(python3 tools/retraction_grep.py --selftest $nofold 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^SELFTEST PASS'; then ok "$(printf '%s\n' "$out" | tail -1 | cut -c1-160)"
elif printf '%s\n' "$out" | grep -q '^SELFTEST FAIL'; then
    bad "$(printf '%s\n' "$out" | grep '^SELFTEST FAIL' | cut -c1-160)"
    if vs_ctl_is case-fold-dropped && ! printf '%s\n' "$out" | grep -q '^SELFTEST FAIL:.*upper-case'; then echo "REFUSED: mode case-fold-dropped — the no-fold self-test failed but NOT on the upper-case case"; exit 3; fi
else echo "REFUSED: the matcher self-test neither passed nor failed on its own line (exit $rc — a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi

echo "== 2. the homes tool catches a planted untracked home"
blind=""
if vs_ctl_is build-home-planted; then blind="--blind"; echo "MODE: control build-home-planted — the self-test runs on the BLIND variant (build/ reads disabled): the plant must go uncaught and the gate FAIL"; fi
out="$(python3 tools/homes_tracked.py --selftest $blind 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^SELFTEST PASS'; then ok "$(printf '%s\n' "$out" | tail -1)"
elif printf '%s\n' "$out" | grep -q '^SELFTEST FAIL'; then
    bad "$(printf '%s\n' "$out" | grep '^SELFTEST FAIL' | cut -c1-160)"
    if vs_ctl_is build-home-planted && ! printf '%s\n' "$out" | grep -q '^SELFTEST FAIL: (False, False'; then echo "REFUSED: mode build-home-planted — the blind self-test failed but NOT on the two build/ reads"; exit 3; fi
else echo "REFUSED: the self-test neither passed nor failed on its own line (exit $rc — a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi

echo "== 2b. the NEWEST findings table row of STATE.md, on the live tree (the close's own output is a snapshot)"
if out="$(python3 tools/homes_tracked.py --newest 2>&1)"; then ok "$(printf '%s\n' "$out" | head -1 | cut -c1-200)"
elif printf '%s\n' "$out" | grep -q '^FAIL'; then bad "$(printf '%s\n' "$out" | grep '^FAIL\|^#' | head -4 | tr '\n' ' ' | cut -c1-300)"
else echo "REFUSED: tools/homes_tracked.py --newest exited non-zero with no FAIL line (a crash, not a verdict): $(printf '%s\n' "$out" | tail -1 | cut -c1-160)"; exit 3; fi

if [ -z "${VS_CTL:-}" ]; then
    echo "== 3. controls"
    f="$(ls tests/rulecheck/retractions/*.tsv | head -1)"; cp "$f" "$W/c1.tsv"; printf 'zq-no-such-wording-anywhere-%s\tplanted\treach\n' "$$" >> "$W/c1.tsv"
    if python3 tools/retraction_grep.py "$W/c1.tsv" >"$W/c1.out" 2>&1; then vs_ctl_dead unreachable-control "an unreachable reach pattern did not make the grep exit 1"; fail=1
    elif grep -q "^FAIL: reach control.*zq-no-such-wording-anywhere-$$ (0 < 1)" "$W/c1.out"; then vs_ctl_fired unreachable-control "$(grep '^FAIL' "$W/c1.out" | cut -c1-120)"
    else vs_ctl_dead unreachable-control "the grep exited non-zero WITHOUT naming the planted control: $(tail -1 "$W/c1.out" | cut -c1-120)"; fail=1; fi
    sed 's/\treach:2$/\treach:3/' "$f" > "$W/c3.tsv"
    if ! grep -q '	reach:3$' "$W/c3.tsv"; then vs_ctl_dead reach-threshold "$f has no reach:2 control to raise"; fail=1
    elif python3 tools/retraction_grep.py "$W/c3.tsv" >"$W/c3.out" 2>&1; then vs_ctl_dead reach-threshold "a reach:3 control with two carriers did not make the grep exit 1"; fail=1
    elif grep -q "^FAIL: reach control.*(2 < 3)" "$W/c3.out"; then vs_ctl_fired reach-threshold "$(grep '^FAIL' "$W/c3.out" | cut -c1-120)"
    else vs_ctl_dead reach-threshold "the grep exited non-zero WITHOUT naming the raised threshold: $(tail -1 "$W/c3.out" | cut -c1-120)"; fail=1; fi
    awk -F'\t' 'BEGIN{OFS="\t"} $3 ~ /^reach/ && !done {p=$1; sub(/^[^ ]+ /, "", p); print p, "planted: a live wording (a reach control minus its first word) marked gone", "gone"; done=1} {print}' "$f" > "$W/c4.tsv"
    if python3 tools/retraction_grep.py "$W/c4.tsv" >"$W/c4.out" 2>&1; then vs_ctl_dead gone-reintroduced "a live wording marked gone did not make the grep exit 1"; fail=1
    elif grep -q "^FAIL: a wording marked GONE is back" "$W/c4.out"; then vs_ctl_fired gone-reintroduced "$(grep '^FAIL' "$W/c4.out" | cut -c1-120)"
    else vs_ctl_dead gone-reintroduced "the grep exited non-zero WITHOUT naming the gone wording: $(tail -1 "$W/c4.out" | cut -c1-120)"; fail=1; fi
    if python3 tools/retraction_grep.py --selftest --nofold >"$W/c5.out" 2>&1; then vs_ctl_dead case-fold-dropped "the no-fold matcher passed the self-test — the upper-case plant is not what it catches"; fail=1
    elif grep -q '^SELFTEST FAIL:.*upper-case' "$W/c5.out"; then vs_ctl_fired case-fold-dropped "$(grep '^SELFTEST FAIL' "$W/c5.out" | cut -c1-120)"
    else vs_ctl_dead case-fold-dropped "the no-fold matcher exited non-zero WITHOUT its self-test FAIL line: $(tail -1 "$W/c5.out" | cut -c1-120)"; fail=1; fi
    if python3 tools/homes_tracked.py --selftest --blind >"$W/c2.out" 2>&1; then vs_ctl_dead build-home-planted "the BLIND variant passed the self-test — the plant is not what the self-test catches"; fail=1
    elif grep -q '^SELFTEST FAIL: (False, False' "$W/c2.out"; then vs_ctl_fired build-home-planted "the blind variant FAILS the self-test on the two build/ reads ($(grep '^SELFTEST FAIL' "$W/c2.out" | cut -c1-60)) while the real tool passes it (section 2)"
    else vs_ctl_dead build-home-planted "the blind variant exited non-zero WITHOUT the self-test's own FAIL line: $(tail -1 "$W/c2.out" | cut -c1-120)"; fail=1; fi
fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
