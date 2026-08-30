#!/bin/sh
# test_annotations_current.sh — docs/annotations.md FOLLOWS its carriers
# (14z-123, the documentation rationalization pass). ci_portable: no ROM,
# no build dir, no emulator, ~1 s.
#
# WHAT IT HOLDS. `tools/gen_annotations.py --check` regenerates the address
# -> label/comment stream from every live carrier (the atlas, engine_internals,
# the other reference docs, build/manifest/*.toml, tools/ and tests/) and
# cmp's it against the committed file. WHY: CLAUDE.md §5 promised this
# document at M0 and it was never created; 14z-122 retired the row claiming
# the stream lived "in the atlas + manifest comments", and the 14z-123 check
# measured that claim false (hundreds of addresses named only in
# engine_internals prose, ~260 only in code). A generated index cannot drift
# from its carriers; a hand-written one would have been the sixth copy.
#
# MUST-FIRE CONTROLS on a synthetic root (the generator's --root): a doc
# gaining an address must fail --check until regenerated; a hand-edit to a
# current index must fail the cmp.
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier ci_portable (~1 s)) docs/annotations.md IS GENERATED (14z-123, the
#   T1 annotations check): `tools/gen_annotations.py --check` regenerates the
#   address -> label/comment stream CLAUDE.md §5 promised at M0 — every
#   program-space address named by a live carrier (the atlas,
#   `engine_internals.md`, the reference docs, `build/manifest/*.toml`,
#   `tools/`, `tests/`) with the carrier file and the section or manifest row
#   it sits under; no line numbers by design (they churn on unrelated edits).
#   The tail section lists CODE-ONLY addresses — the documentation gap. WHY:
#   `re/ghidra/` never held a project; the 14z-122 retirement note claimed the
#   stream lived in the atlas + manifest comments, and the check measured
#   ~2,900 addresses across five carrier kinds, ~220 named only in
#   engine_internals prose and ~265 only in code. Four must-fire controls on a
#   synthetic root. Regenerate after any edit that adds or removes a program
#   address: `python3 tools/gen_annotations.py`.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== test_annotations_current: the index follows its carriers =="
LOG="$(mktemp)"
if python3 tools/gen_annotations.py --check >"$LOG" 2>&1; then
    ok "$(head -1 "$LOG")"
else
    bad "gen_annotations.py --check FAILS (regenerate: python3 tools/gen_annotations.py):"
    sed 's/^/        /' "$LOG" | head -20
fi
rm -f "$LOG"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
mkdir -p "$W/docs/game/atlas" "$W/build/manifest"
printf '# doc_shape\n' > "$W/docs/doc_shape.tsv"
printf '# atlas\n\n## A section\n\nthe routine at `PRG:0x012345` reads it\n' > "$W/docs/game/atlas/ram.md"
printf 'name = "a_table"\naddr = 0x0BD800\n' > "$W/build/manifest/bank_map.toml"
python3 tools/gen_annotations.py --root "$W" >/dev/null 2>&1 || bad "control setup: generation on the synthetic root failed"

# a: a current index passes --check
if python3 tools/gen_annotations.py --root "$W" --check >/dev/null 2>&1; then
    ok "control a: a freshly generated index passes --check"
else
    bad "control a: a freshly generated index FAILS --check"
fi

# b: a doc gaining an address fails --check, and regenerating clears it
printf '\n## Another section\n\nand `PRG:0x023456` too\n' >> "$W/docs/game/atlas/ram.md"
if python3 tools/gen_annotations.py --root "$W" --check >/dev/null 2>&1; then
    bad "control b: a new address in a carrier did NOT fail --check"
else
    ok "control b: a new address in a carrier fails --check"
fi
python3 tools/gen_annotations.py --root "$W" >/dev/null 2>&1
if grep -q 'PRG:0x023456.*Another section' "$W/docs/annotations.md"; then
    ok "control b: the regenerated index carries the new address under its section"
else
    bad "control b: the regenerated index lacks the new address / section"
fi

# c: a hand-edit to a current index fails the cmp
printf '| `PRG:0x0FFFFE` | hand-written |\n' >> "$W/docs/annotations.md"
if python3 tools/gen_annotations.py --root "$W" --check >/dev/null 2>&1; then
    bad "control c: a hand-edited index passed --check"
else
    ok "control c: a hand-edited index fails --check"
fi

# d: a code-only address lands in the gap section, not the main table
mkdir -p "$W/tools"
printf 'X=0x034567\n' > "$W/tools/rig.py"
python3 tools/gen_annotations.py --root "$W" >/dev/null 2>&1
if awk '/^## Code-only/{g=1} g && /PRG:0x034567/{found=1} END{exit !found}' "$W/docs/annotations.md"; then
    ok "control d: a code-only address is listed in the gap section"
else
    bad "control d: a code-only address is not in the gap section"
fi

[ "$fail" -eq 0 ] && echo "PASS test_annotations_current" || echo "FAIL test_annotations_current"
exit "$fail"
