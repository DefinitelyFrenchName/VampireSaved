#!/bin/sh
# test_checkskills.sh — the two MiSTer skills are locked to the docs they
# distil (14z-114). ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHAT IT HOLDS. `tools/checkskills.py` asserts, on the real tree:
#   1. every `- [MSC-N]` / `- [MSV-N]` rule in
#      .claude/skills/{mister-cps2-wide-core,mister-vampire-saved}/SKILL.md
#      is ANCHORED exactly once (`**[MSC-N]**`) in the docs it distils, and
#      every anchor has a rule — both ways, so a deleted paragraph or an
#      unanchored addition fails;
#   2. the level-1 skill names nothing game-specific (mister_scope.md §1's
#      liftability test);
#   3. every number a skill quotes appears in a LOG, never only in the
#      synthesis mister_core.md.
# The tool self-tests its extractors on synthetic content every run.
#
# MUST-FIRE CONTROLS ON THE REAL TREE (RH-9: a negative control is wrong
# until it has failed on purpose): a copy of the relevant files is perturbed
# three ways — an unanchored rule appended, one anchor stripped from a doc,
# a game name inserted into the level-1 skill — and each copy must FAIL.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== test_checkskills: skills locked to docs =="
if python3 tools/checkskills.py >/tmp/checkskills.$$.log 2>&1; then
    ok "checkskills.py PASS on the tree ($(grep -o '[0-9]* rules' /tmp/checkskills.$$.log | head -1))"
else
    bad "checkskills.py FAILS on the tree:"; sed 's/^/        /' /tmp/checkskills.$$.log
fi
rm -f /tmp/checkskills.$$.log

# --- must-fire controls on a perturbed copy -------------------------------
FILES=".claude/skills/mister-cps2-wide-core/SKILL.md .claude/skills/mister-vampire-saved/SKILL.md
docs/platform/mister.md docs/project/mister_core.md docs/project/mister_map.md docs/project/mister_fit.md
docs/project/mister_field.md docs/project/cps2_wide.md docs/project/release_format.md
docs/platform/gotchas.md docs/project/gotchas.md HANDOFF.md CLAUDE.md release/bitstreams/18269/BITSTREAM.txt"
mkcopy() {  # mkcopy <dir>
    for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done
}
control() {  # control <label> <dir> <expected substring>
    if python3 tools/checkskills.py --root "$2" --no-selftest >"$2/log" 2>&1; then
        bad "$1: the perturbed copy PASSED — the check is not checking"
    elif grep -q "$3" "$2/log"; then
        ok "$1: fires ($3)"
    else
        bad "$1: failed for the wrong reason:"; sed 's/^/        /' "$2/log"
    fi
}
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

mkcopy "$W/a"; printf -- '- [MSC-999] a rule nobody anchored\n' >> "$W/a/.claude/skills/mister-cps2-wide-core/SKILL.md"
control "unanchored rule" "$W/a" "ANCHORED NOWHERE"

mkcopy "$W/b"; sed -i '' 's/\*\*\[MSV-6\]\*\* //' "$W/b/docs/project/mister_map.md"
grep -q '\*\*\[MSV-6\]\*\*' "$W/b/docs/project/mister_map.md" && bad "control b: the anchor was not stripped"
control "stripped anchor" "$W/b" "ANCHORED NOWHERE: MSV-6"

mkcopy "$W/c"; printf -- '\nA note that names Donovan by name.\n' >> "$W/c/.claude/skills/mister-cps2-wide-core/SKILL.md"
control "game name in level 1" "$W/c" "level-1 skill names 'donovan'"

mkcopy "$W/d"; printf -- '\nThe magic figure is 0xDEADBEEF1.\n' >> "$W/d/.claude/skills/mister-vampire-saved/SKILL.md"
control "number in no log" "$W/d" "in NO log: 0xDEADBEEF1"

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
