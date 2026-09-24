#!/bin/sh
# test_gate_coverage_current.sh — docs/project/gate_coverage.md FOLLOWS the gates' headers
# (14z-180, GitHub #171 slice Q0). ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHAT: the GENERATED coverage page — every gate's `# WHAT:` / `# HOW:` / `# EXPECTS:`
#   fields rendered by family for reading — equals a fresh regeneration from the tree, so
#   the page the maintainer reviews can never say something a header does not.
# HOW: `tools/gen_gate_coverage.py --check` regenerates the page from every tests/*.sh
#   header (tools/gate_descriptions.py, the one reader) and the family rows of
#   tools/gen_gate_index.py, and compares it with the committed file; two controls run the
#   same check on a COPY of the real inputs with one perturbation each.
# EXPECTS: PASS when the committed page equals the regeneration. A red is a stale page
#   (regenerate: `python3 tools/gen_gate_coverage.py`) or a header edit not yet rendered.
#
# MUST-FIRE: perturbed-copy: hand-edited-coverage — a line hand-added to the committed page must fail the cmp (mode: the check runs on a copy of the tree whose page carries the line)
# MUST-FIRE: perturbed-copy: description-dropped — a described gate's `# WHAT:` field removed in a copy of the tree must make the regeneration differ from the committed page and fail (mode: the check runs on that copy)
#
# WHY ITS OWN GATE and not test_gate_index_current: the generic harness renders the index
# with a lifted copy of gen_gate_index.py and its fidelity gate F9 requires byte-identity
# (tests/test_bbh_fidelity.sh), so the description rendering lives beside the index, not
# in it (the generator's docstring).
#
# Usage: tests/test_gate_coverage_current.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d "${TMPDIR:-/tmp}/gcov.XXXXXX")"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

# copy NAME DIR — a copy of the real inputs with control NAME's perturbation
copy() {
    mkdir -p "$2/tests" "$2/docs/project"
    cp tests/*.sh tests/*.tsv tests/*.txt "$2/tests/"
    GC=docs/project/gate_coverage.md
    cp "$GC" "$2/docs/project/"
    case "$1" in
        hand-edited-coverage) printf '\n### `hand.sh` — test, x\n\n**WHAT:** planted.\n' >> "$2/docs/project/gate_coverage.md" ;;
        description-dropped)
            g="$(python3 tools/gate_descriptions.py 2>/dev/null | awk -F'\t' '$1=="declares"{print $2; exit}')"
            [ -n "$g" ] || { echo "FAIL: no described gate to perturb"; exit 1; }
            sed -i.bak '/^# WHAT:/d' "$2/tests/$g.sh"; rm -f "$2/tests/$g.sh.bak" ;;
    esac
}

ROOT="$REPO"
if [ -n "$VS_CTL" ]; then copy "$VS_CTL" "$W/mode"; ROOT="$W/mode"; echo "MODE: control $VS_CTL — the check runs on a perturbed copy"; fi

echo "== 1. the coverage page follows the headers"
if python3 tools/gen_gate_coverage.py --root "$ROOT" --check > "$W/check.log" 2>&1; then ok "$(tail -1 "$W/check.log")"
else bad "gen_gate_coverage.py --check FAILS (regenerate: python3 tools/gen_gate_coverage.py):"; sed 's/^/        /' "$W/check.log" | head -12; fi

if [ -z "$VS_CTL" ]; then
    echo "== 2. controls: each perturbed copy must fail the check"
    for c in hand-edited-coverage description-dropped; do
        copy "$c" "$W/$c"
        if python3 tools/gen_gate_coverage.py --root "$W/$c" --check >/dev/null 2>&1; then vs_ctl_dead "$c" "the perturbed copy passed --check"; fail=1
        else vs_ctl_fired "$c" "the perturbed copy fails --check"; fi
    done
fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
