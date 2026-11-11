#!/bin/sh
# test_module_refs.sh — EVERY CROSS-MODULE PYTHON NAME THE TOOLS AND GATES REFERENCE STILL
# EXISTS (GitHub #171 slice Q1, ruled 2026-09-24 — DECISIONS_HISTORY.md "Ruled 2026-09-24
# (14z-180) — #171 gate qualification", "Land it now"). ci_portable: no ROM, no build dir,
# no emulator, ~1 s.
#
# WHAT: every `import <tool>` / `from <tool> import` and every `<alias>.<NAME>` reference
#   from tools/**/*.py and tests/**/*.py into a module under tools/ names something that
#   module defines at its top level TODAY — and the census is not empty.
# HOW: tools/audit_module_refs.py parses every file by AST (never imports it), collects the
#   references scope-aware (a function's own `pp` is not the module alias `pp`), resolves each
#   against the target module's top-level definitions, and refuses a census below the frozen
#   floor tests/expected/module_refs_floor.txt (the count can only rise).
# EXPECTS: PASS with 0 unresolved references and at least the floor's count. A red names the
#   file, line and `module.NAME` that no longer resolves — the 14z-165 shape, where
#   tools/vanilla_join_rig.py kept calling the deleted name_moves.PROLOGUE and five emulator
#   gates asserted nothing for four days (STATE_HISTORY 14z-174 row (12)) — or a census that
#   shrank below its floor, which is a tool that stopped seeing files.
#
# MUST-FIRE: perturbed-copy: planted-prologue — the historical caller (git show e01ae8de^:tools/vanilla_join_rig.py, `name_moves.PROLOGUE` at its line 110) parsed through the SAME extractor must be reported unresolved, and the gate must FAIL (mode: the tool's --plant)
# MUST-FIRE: perturbed-copy: empty-census — a census over NO files must fail the floor: 0 references is an empty measurement, never a pass (mode: the tool's --plant-empty)
#
# WHY THE FLOOR IS A FROZEN FILE and not a constant here: a number in a gate header is where
# the 300 s control timeout hid (#171 shape 3); tests/expected/PROVENANCE.md says where this
# one came from and `FREEZE=1` moves it only upward.
#
# Usage: tests/test_module_refs.sh            # FREEZE=1 raises the floor to today's count
# SHARES: none — its 2 control modes were write-traced apart (tests/controls_concurrent.txt, pilot:413e9b92) and its plain run always pooled (#370 A1, 14z-225)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
TOOL="python3 tools/audit_module_refs.py"
FLOOR_FILE="tests/expected/module_refs_floor.txt"
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

floor="$(grep -v '^#' "$FLOOR_FILE" | tr -d ' \n')"
case "$floor" in ''|*[!0-9]*) echo "FAIL: $FLOOR_FILE carries no integer floor"; exit 1;; esac

if [ -n "${VS_CTL:-}" ]; then   # #369: the mode's own finding, from the tool's output, is the evidence
    W="$(mktemp -d)" || { echo "FAIL: test_module_refs — mktemp -d failed"; exit 2; }
    trap 'rm -rf "$W"' EXIT
    case "$VS_CTL" in
        planted-prologue) echo "== MODE planted-prologue: the historical caller through the extractor"; ARG=--plant
            WANT='^  UNRESOLVED <plant e01ae8de\^:tools/vanilla_join_rig\.py>:110  name_moves\.PROLOGUE$' ;;
        empty-census) echo "== MODE empty-census: no files through the census"; ARG=--plant-empty
            WANT=' 0 reference\(s\) over 0 files is below the floor of [0-9]+$' ;;
    esac
    $TOOL "$ARG" --floor "$floor" > "$W/main.log" 2>&1; rc=$?
    cat "$W/main.log"
    # the tool's own exit is the verdict: 0 means the perturbation passed the census
    [ "$rc" -eq 0 ] && vs_ctl_left_green "$VS_CTL" "FAIL: the $VS_CTL perturbation passed the census"
    vs_ctl_caught "$W/main.log" "$WANT"
    echo "FAIL (mode): as required — the $VS_CTL perturbation was reported"; exit 1
fi

echo "== 1. the census, floor $floor (from $FLOOR_FILE)"
out="$($TOOL --floor "$floor" 2>&1)"; rc=$?
echo "$out" | sed 's/^/  /'
if [ "$rc" -eq 0 ]; then ok "every reference resolves, at or above the floor"; else bad "the census is red (exit $rc)"; fi
n="$(echo "$out" | sed -n 's/.*modules, \([0-9]*\) references over.*/\1/p' | head -1)"
if [ "${FREEZE:-0}" = 1 ] && [ -n "$n" ] && [ "$n" -gt "$floor" ]; then
    { echo "# tests/expected/module_refs_floor.txt — the fewest cross-module references"; echo "# tests/test_module_refs.sh accepts (rises only; FREEZE=1 after review). Provenance:"; echo "# tests/expected/PROVENANCE.md."; echo "$n"; } > "$FLOOR_FILE"
    echo "  FROZE floor $floor -> $n"
fi

echo "== 2. controls: each must fire in-gate (the modes above prove them as modes)"
if $TOOL --plant --floor "$floor" >"$REPO/build/.module_refs_plant.log" 2>&1; then
    vs_ctl_dead planted-prologue "the historical reference passed the census"; fail=1
else
    if grep -q '^CONTROL FIRED: planted-prologue' "$REPO/build/.module_refs_plant.log"; then
        vs_ctl_fired planted-prologue "$(grep '^CONTROL FIRED: planted-prologue' "$REPO/build/.module_refs_plant.log" | sed 's/^CONTROL FIRED: planted-prologue — //')"
    else vs_ctl_dead planted-prologue "the tool failed without reporting the plant"; fail=1; fi
fi
if $TOOL --plant-empty --floor "$floor" >"$REPO/build/.module_refs_empty.log" 2>&1; then
    vs_ctl_dead empty-census "an empty census passed the floor"; fail=1
else
    if grep -q '^CONTROL FIRED: empty-census' "$REPO/build/.module_refs_empty.log"; then
        vs_ctl_fired empty-census "$(grep '^CONTROL FIRED: empty-census' "$REPO/build/.module_refs_empty.log" | sed 's/^CONTROL FIRED: empty-census — //')"
    else vs_ctl_dead empty-census "the tool failed without reporting the empty census"; fail=1; fi
fi
rm -f "$REPO/build/.module_refs_plant.log" "$REPO/build/.module_refs_empty.log"

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
