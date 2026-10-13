#!/bin/sh
# test_retraction_reach.sh — EVERY SITTING'S RETRACTION GREP STILL REACHES THE TREE: every
# tests/rulecheck/retractions/*.tsv judged on ONE scan of the live tree (tools/retraction_grep.py
# --each). ci_portable: no ROM, no emulator, ~30 s; FREEZE cadence (tests/ci_cadence.tsv; #268,
# 14z-199: built on the maintainer's C1 ruling of 2026-10-12; the freeze cadence, the session's application of
# that entry's turned-around tier, validated by the maintainer — DECISIONS_HISTORY.md "Ruled 2026-10-13 (14z-199)"). Split out of tests/test_close_tools.sh, which ran one full
# scan PER FILE at every session tier (twenty scans: 565 s a run measured 14z-199; its controls 3,647-4,065 s a close at
# 14z-196..198, build/agent199/t1/report.md A2).
#
# WHAT: tools/retraction_grep.py --each over every tests/rulecheck/retractions/*.tsv exits 0, ON THE
#   LIVE TREE (an output file is a snapshot with a tree fingerprint, never the check) — each file's
#   REACH controls (a live heading, a corrected wording in plain AND code-spanned form — a `reach:2`
#   control that fails when either carrier is missed — a carrier line-wrapped across a `#` comment
#   prefix, a sentence that lives only in a ROOT document, README.md — the scan reads every tracked
#   file since rule-checker run 2026-09-25-204) are found in the live tree and every GONE wording reads
#   0 hits, so every sitting's retracted wordings were searched by a grep that reaches. Between
#   freezes the session tier covers the same ground in part: the close's standing check
#   `retraction_grep` (tests/close_standing_checks.tsv) runs the sitting's OWN file on the whole tree,
#   and tests/test_close_tools.sh section 1 judges EVERY file's gone wordings on the files the sitting
#   touched; a reach control of an older sitting whose carrier is lost is caught here, at the freeze.
# HOW: one scan reads the tree once (the normalising is the cost, not the matching); the three
#   controls are planted copies of the first pattern file judged IN THE SAME SCAN as the real files,
#   each of which must FAIL with its own text while every real file passes. Under a mode the planted
#   copy REPLACES the first file and the gate must FAIL on the plant's text.
# EXPECTS: PASS when every real pattern file passes and every plant fails on its own text. A tool exit
#   with no FILE verdict lines (a crash, a refused pattern file) is REFUSED (exit 3), never a red — in a
#   MODE too: a mode passes only on the plant's own FAIL text. A red names the pattern file and the dead
#   control (the tree lost a carrier the sitting's close depended on, or a pattern was written narrower
#   than its carrier) or the gone wording that came back.
#
# MUST-FIRE: perturbed-copy: unreachable-control — a copy of a retraction TSV with a reach pattern that exists nowhere must make tools/retraction_grep.py fail that file with a FAIL line naming it (in-gate, in the same scan as the real files; mode: the copy replaces the real file and the gate FAILs)
# MUST-FIRE: perturbed-copy: reach-threshold — a copy of a retraction TSV whose `reach:2` control is raised to `reach:9` (more carriers than exist — since 14z-195 the rendered docs/site copy is a carrier too, so the count varies with what is rendered locally) must make tools/retraction_grep.py fail it naming it, so a reach:N control that lost a carrier cannot pass on the ones left (in-gate; mode: the copy replaces the real file and the gate FAILs)
# MUST-FIRE: perturbed-copy: gone-reintroduced — a copy of a retraction TSV with a wording KNOWN to be live (a reach control's text minus its first word, so the copy repeats no pattern) marked `gone` must make tools/retraction_grep.py fail it naming it, so a retracted wording that comes back is a red (in-gate; mode: the copy replaces the real file and the gate FAILs)
#
# WHY: the 14z-181 close's retraction grep lived in an inline script recorded nowhere, and its pattern
# was narrower than its carrier three times (rule-checker runs 184-187); the per-file loop it became
# cost more than every other close check together by 14z-198 (#268, build/agent199 measurement).
#
# Usage: tests/test_retraction_reach.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d "${TMPDIR:-/tmp}/rreach.XXXXXX")"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
unset RETRACTION_GREP_UNIVERSE   # a test harness's stand-in for the tree (tools/retraction_grep.py universe): never here

FIRST="$(ls tests/rulecheck/retractions/*.tsv | head -1)"
[ -n "$FIRST" ] || { echo "FAIL: no retraction file under tests/rulecheck/retractions/"; echo "FAIL"; exit 1; }
perturb() {   # perturb <name> <copy> — the copy of $FIRST carrying the plant; sets EXPECT, the text its FAIL must carry
    case "$1" in
        unreachable-control)
            cp "$FIRST" "$2"; printf 'zq-no-such-wording-anywhere-%s\tplanted unreachable control\treach\n' "$$" >> "$2"
            EXPECT="zq-no-such-wording-anywhere-$$ (0 < 1)" ;;
        reach-threshold)
            sed 's/\treach:2$/\treach:9/' "$FIRST" > "$2"
            grep -q '	reach:9$' "$2" || { echo "REFUSED: $FIRST has no reach:2 control to raise"; exit 3; }
            EXPECT="< 9)" ;;
        gone-reintroduced)
            awk -F'\t' 'BEGIN{OFS="\t"} $3 ~ /^reach/ && !done {p=$1; sub(/^[^ ]+ /, "", p); print p, "planted: a live wording (a reach control minus its first word) marked gone", "gone"; done=1} {print}' "$FIRST" > "$2"
            EXPECT="marked GONE is back in the tree" ;;
    esac
}

echo "== 1. every pattern file on ONE scan of the live tree (outside a mode, the three plants in the same scan)"
set -- tests/rulecheck/retractions/*.tsv
real="$*"; plants=""
if [ -n "${VS_CTL:-}" ]; then
    perturb "$VS_CTL" "$W/mode.tsv"; MODE_EXPECT="$EXPECT"
    real="$(printf '%s\n' "$@" | sed "s#^$FIRST\$#$W/mode.tsv#" | tr '\n' ' ')"
    echo "MODE: control $VS_CTL — $FIRST replaced by a copy carrying the plant"
else
    for c in unreachable-control reach-threshold gone-reintroduced; do
        perturb "$c" "$W/$c.tsv"; eval "EXP_$(echo "$c" | tr - _)=\"\$EXPECT\""; plants="$plants $W/$c.tsv"
    done
fi
# shellcheck disable=SC2086
python3 tools/retraction_grep.py --each $real $plants > "$W/each.out" 2>&1; rc=$?
head -1 "$W/each.out" | cut -c1-200
if ! grep -q '^EACH: ' "$W/each.out"; then
    echo "REFUSED: tools/retraction_grep.py --each printed no EACH line (exit $rc — a crash or a refusal, not a verdict): $(tail -1 "$W/each.out" | cut -c1-160)"; exit 3
fi
for f in $real; do
    v="$(grep -F "FILE $f: " "$W/each.out")"
    case "$v" in
        "FILE $f: PASS"*) ok "$f: $(printf '%s\n' "${v#"FILE $f: PASS — "}" | cut -c1-140)" ;;
        "") echo "REFUSED: $f has no verdict line in the scan's output"; exit 3 ;;
        *) bad "$(printf '%s\n' "$v" | cut -c1-220)"
           if [ -n "${VS_CTL:-}" ] && [ "$f" = "$W/mode.tsv" ] && ! printf '%s\n' "$v" | grep -qF "$MODE_EXPECT"; then
               echo "REFUSED: mode $VS_CTL — the grep failed WITHOUT naming the plant ($MODE_EXPECT)"; exit 3
           fi ;;
    esac
done

if [ -z "${VS_CTL:-}" ]; then
    echo "== 2. controls (judged in the scan above)"
    for c in unreachable-control reach-threshold gone-reintroduced; do
        eval "want=\"\$EXP_$(echo "$c" | tr - _)\""
        v="$(grep -F "FILE $W/$c.tsv: " "$W/each.out")"
        case "$v" in
            *": PASS"*) vs_ctl_dead "$c" "the planted copy PASSED — the plant is not what the grep catches"; fail=1 ;;
            "") vs_ctl_dead "$c" "the planted copy has no verdict line"; fail=1 ;;
            *) if printf '%s\n' "$v" | grep -qF "$want"; then vs_ctl_fired "$c" "the planted copy of $FIRST FAILS naming the plant: $(printf '%s\n' "$v" | grep -F "$want" | head -1 | sed 's/^FILE [^ ]*: //' | cut -c1-140)"
               else vs_ctl_dead "$c" "the planted copy failed WITHOUT naming the plant ($want)"; fail=1; fi ;;
        esac
    done
fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
