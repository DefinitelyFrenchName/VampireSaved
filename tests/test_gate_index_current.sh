#!/bin/sh
# test_gate_index_current.sh — docs/project/gate_index.md FOLLOWS the tree
# (14z-123, the documentation rationalization pass, G6). ci_portable: no ROM,
# no build dir, no emulator, ~1 s.
#
# WHAT IT HOLDS. `tools/gen_gate_index.py --check` regenerates the gate index
# — one row per tests/*.sh: kind, tier (from the ci registries), family (from
# tests/gate_index.tsv, the one hand-maintained input), needs, the script's
# OWN header sentence as "locks", since — and cmp's it against the committed
# file; it also fails on a script with no family row or a row with no script.
# WHY: HANDOFF's hand-written gate fence indexed 168 of 281 scripts, one of
# them twice, and its comments drifted from the scripts' headers; the
# maintainer ruled a gate's WHY lives in the gate. A generated index cannot
# desync from the tree, and completeness means a new gate is classified at
# birth. The old fence (as of 14z-123) is verbatim in HANDOFF_HISTORY.md.
#
# MUST-FIRE CONTROLS on a synthetic root: a fresh generation passes; a script
# without a family row fails --check; adding the row clears it; a hand-edit
# to the committed index fails the cmp.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== test_gate_index_current: the gate index follows the tree =="
LOG="$(mktemp)"
if python3 tools/gen_gate_index.py --check >"$LOG" 2>&1; then
    ok "$(tail -1 "$LOG")"
else
    bad "gen_gate_index.py --check FAILS (regenerate: python3 tools/gen_gate_index.py; add rows to tests/gate_index.tsv):"
    sed 's/^/        /' "$LOG" | head -20
fi
rm -f "$LOG"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
mkdir -p "$W/tests" "$W/docs/project"
printf '#!/bin/sh\n# test_alpha.sh — a synthetic gate that locks the alpha law (14z-999).\n#\necho PASS\n' > "$W/tests/test_alpha.sh"
printf 'test_alpha\n' > "$W/tests/ci_portable.txt"; : > "$W/tests/ci_static.txt"
printf 'tests/test_alpha.sh\tdocs\n' > "$W/tests/gate_index.tsv"
python3 tools/gen_gate_index.py --root "$W" >/dev/null 2>&1 || bad "control setup: generation on the synthetic root failed"

# a: a fresh generation passes
if python3 tools/gen_gate_index.py --root "$W" --check >/dev/null 2>&1; then
    ok "control a: a freshly generated index passes --check"
else
    bad "control a: a freshly generated index FAILS --check"
fi
# b: a script without a family row fails; the row clears it
printf '#!/bin/sh\n# audit_beta.sh — a synthetic audit with no family row.\n#\necho PASS\n' > "$W/tests/audit_beta.sh"
if python3 tools/gen_gate_index.py --root "$W" --check >/dev/null 2>&1; then
    bad "control b: a script with NO family row passed --check"
else
    ok "control b: a script with no family row fails --check"
fi
printf 'tests/audit_beta.sh\tplatform\n' >> "$W/tests/gate_index.tsv"
python3 tools/gen_gate_index.py --root "$W" >/dev/null 2>&1
if python3 tools/gen_gate_index.py --root "$W" --check >/dev/null 2>&1 && grep -q 'audit_beta.sh.*audit.*emulator' "$W/docs/project/gate_index.md"; then
    ok "control b: with the row the index passes and lists the audit (kind audit, tier emulator)"
else
    bad "control b: the row did not clear the check / the row is missing from the index"
fi
# c: a dead TSV row fails
printf 'tests/test_gone.sh\tdocs\n' >> "$W/tests/gate_index.tsv"
if python3 tools/gen_gate_index.py --root "$W" --check >/dev/null 2>&1; then
    bad "control c: a TSV row for a missing script passed --check"
else
    ok "control c: a TSV row whose script is gone fails --check"
fi
sed -i.bak '$d' "$W/tests/gate_index.tsv"; rm -f "$W/tests/gate_index.tsv.bak"
# d: a hand-edit fails the cmp
printf '| `tests/hand.sh` | test | x | x | x | x |\n' >> "$W/docs/project/gate_index.md"
if python3 tools/gen_gate_index.py --root "$W" --check >/dev/null 2>&1; then
    bad "control d: a hand-edited index passed --check"
else
    ok "control d: a hand-edited index fails --check"
fi

[ "$fail" -eq 0 ] && echo "PASS test_gate_index_current" || echo "FAIL test_gate_index_current"
exit "$fail"
