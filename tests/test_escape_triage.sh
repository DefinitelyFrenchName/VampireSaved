#!/bin/sh
# test_escape_triage.sh — H3.1's verdicts, frozen (14z-100 hardening).
#
# tools/triage_pcrel_escapes.py classifies every UNCOVERED word-form pc-rel
# branch escape by where it lands on the MERGED placements. The 14z-100
# sweep closed the class: 25 sites, ZERO live — 22 ADJACENT-OK (the huitzil
# code->x057456 cluster, same delta by construction) + 3 FOREIGN-REGION
# verdicts that are REVIEWED census false positives (x028122+0x112
# jump-table framing, all tenants; x068c78+0x1ca immediate-word class,
# hui/pyr — evidence in the manifests' reviewed-not-rowed blocks).
#
# THE FREEZE IS THE VERDICT SET, verbatim. Any drift fails BOTH ways:
# a new line is an unreviewed escape (a new region, a moved placement
# turning ADJACENT-OK foreign, a manifest losing a pcrel row); a missing
# line means the build under test is not the frozen generation.
# A FOREIGN/WIDE/OFF verdict may only exist here with a matching review
# in the owning manifest — that is a REVIEW obligation, not a tolerance.
#
# Must-fire control: --all-regions includes COVERED regions, whose raw
# escapes classify non-OK by the hundreds; if that reads zero, the
# classifier stopped discriminating.
#
# Needs the three solo builds' extract/ + the merged placements. ROM-free.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
for d in build/don_m17/extract build/hui51/extract build/pyron35/extract \
         build/m3b_merged20/patch/placements.json; do  # re-pointed 14z-117b (random-select freeze) <- 14z-117
    [ -e "$d" ] || { echo "SKIP: $d absent"; exit 0; }
done
fail=0

echo "== section 0: must-fire control (covered regions' raw escapes)"
N="$(python3 tools/triage_pcrel_escapes.py --all-regions 2>/dev/null | grep -c "LIVE RISK" || true)"
if [ "$N" -ge 100 ]; then
    echo "   ok: classifier discriminates ($N raw LIVE-RISK verdicts on covered regions)"
else
    echo "FAIL: only $N raw verdicts — the classifier stopped discriminating"; fail=1
fi

echo "== section 1: the frozen verdict set"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
python3 tools/triage_pcrel_escapes.py | sort > "$W/got.txt"
if diff -u tests/expected/escape_triage.txt "$W/got.txt" > "$W/diff.txt"; then
    echo "   ok: 25 verdicts unchanged since reviewed (22 ADJACENT-OK + 3 reviewed-FP)"
else
    echo "FAIL: escape-triage drift — review every changed line before shipping:"
    head -15 "$W/diff.txt"
    fail=1
fi

[ "$fail" = 0 ] && echo "PASS: the uncovered-escape class is closed and frozen" \
    || { echo "FAIL"; exit 1; }
