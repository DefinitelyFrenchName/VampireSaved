#!/bin/sh
# test_s4_thresholds.sh — the ratified CLAUDE.md §4 thresholds are declared
# ONCE and every consumer resolves to that one declaration (14z-93,
# GitHub #44). No ROMs, no emulator, ~1s.
#
# WHAT #44 REPORTED. FLICKER_MAX and RECONVERGE were declared FOUR times —
# describe_masked_shape.py, compare_composite.py, compare_flicker.py,
# compare_window.py — with a comment saying they "must stay in step" and
# NOTHING asserting it. describe_masked_shape.py was created precisely to
# give the classifier "one set of thresholds, one place to correct"; it
# achieved that for the heredoc it replaced and left the comparators as
# three more places.
#
# THE FAILURE IS SILENT AND WELL-SHAPED. Change FLICKER_MAX to 3 in
# compare_composite.py after a ruling and describe_masked_shape.py keeps
# proposing lines that classify a 3-frame run as a flicker. The proposed
# line is pasted verbatim into a .masked file — which is what that tool is
# FOR — and the composite checker then rejects it. The tool whose whole
# purpose is "propose a line that drops in verbatim" proposes one that
# cannot pass.
#
# A shared import makes drift impossible by construction; this gate exists
# so that a future edit RE-INTRODUCING a local literal is caught, which an
# import alone cannot prevent.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
CONSUMERS="tools/describe_masked_shape.py tools/compare_composite.py tools/compare_flicker.py tools/compare_window.py"

echo "== 1: one declaration, and it is the ratified pair =="
python3 - <<'PY' || fail=1
import sys
sys.path.insert(0, "tools")
from s4_thresholds import FLICKER_MAX, RECONVERGE
rc = 0
# The ratified values (CLAUDE.md §4 v2). If a maintainer amends §4 these
# change HERE and this line changes with them — deliberately, so that
# amending the ratified numbers is a visible, reviewed edit.
if FLICKER_MAX == 2:
    print("  ok FLICKER_MAX == 2 (§4 v2: isolated <=2-frame divergences)")
else:
    print("  FAIL FLICKER_MAX ==", FLICKER_MAX); rc = 1
if RECONVERGE == 60:
    print("  ok RECONVERGE == 60 (§4 v2: the non-propagation proof)")
else:
    print("  FAIL RECONVERGE ==", RECONVERGE); rc = 1
sys.exit(rc)
PY

echo "== 2: every consumer resolves to that declaration =="
for f in $CONSUMERS; do
    if grep -Eq '^[[:space:]]*from s4_thresholds import' "$f"; then
        echo "  ok $f imports the shared declaration"
    else
        echo "  FAIL $f does not import tools/s4_thresholds.py"; fail=1
    fi
done

echo "== 3: NO consumer re-declares a threshold locally =="
# The regression #44 describes is a local literal reappearing. Assignments
# only — a bare mention in a comment or a docstring is fine and is how the
# provenance gets explained.
for f in $CONSUMERS; do
    if grep -Eq '^[[:space:]]*(FLICKER_MAX|RECONVERGE)[[:space:]]*=' "$f"; then
        echo "  FAIL $f re-declares a threshold locally:"
        grep -En '^[[:space:]]*(FLICKER_MAX|RECONVERGE)[[:space:]]*=' "$f" | sed 's/^/        /'
        fail=1
    else
        echo "  ok $f declares neither locally"
    fi
done

echo "== 4: no consumer hard-codes the VALUES as argparse defaults =="
# The other half of the same drift: `default=60` / `default=2` on the
# --reconverge / --max-stretch / --min-converge options.
for f in $CONSUMERS; do
    hits="$(grep -En 'add_argument\("--(reconverge|max-stretch|min-converge)".*default=[0-9]' "$f" || true)"
    if [ -n "$hits" ]; then
        echo "  FAIL $f hard-codes a threshold default:"
        printf '%s\n' "$hits" | sed 's/^/        /'
        fail=1
    else
        echo "  ok $f takes its defaults from the shared declaration"
    fi
done

echo "== 5: verdict control — the gate must CATCH a re-introduced literal =="
# Ground-truth the check itself (CLAUDE.md §4: verdict logic is tested).
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
printf 'FLICKER_MAX = 3\n' > "$W/drifted.py"
if grep -Eq '^[[:space:]]*(FLICKER_MAX|RECONVERGE)[[:space:]]*=' "$W/drifted.py"; then
    echo "  ok control: a re-introduced local literal IS caught"
else
    echo "  FAIL control: the section-3 check cannot see a local literal"; fail=1
fi
printf '# FLICKER_MAX is 2 (see s4_thresholds)\n' > "$W/comment.py"
if grep -Eq '^[[:space:]]*(FLICKER_MAX|RECONVERGE)[[:space:]]*=' "$W/comment.py"; then
    echo "  FAIL control: a COMMENT is wrongly flagged as a declaration"; fail=1
else
    echo "  ok control: a comment mentioning a threshold is not flagged"
fi

echo "== 6: the consumers still run =="
for f in $CONSUMERS; do
    python3 -m py_compile "$f" 2>/dev/null \
        && echo "  ok $f compiles" \
        || { echo "  FAIL $f does not compile"; fail=1; }
done

echo
if [ "$fail" = 0 ]; then
    echo "PASS: the §4 thresholds are declared once and cannot drift."
else
    echo "FAIL: the §4 thresholds can disagree between tools."
fi
exit "$fail"
