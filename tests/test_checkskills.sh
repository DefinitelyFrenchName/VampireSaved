#!/bin/sh
# test_checkskills.sh — the two MiSTer skills are locked to the docs they
# distil (14z-114). ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHAT IT HOLDS. `tools/checkskills.py` asserts, on the real tree:
#   1. every `- [PFX-N]` rule in .claude/skills/*/SKILL.md (MSC/MSV the MiSTer
#      pair, CPH/CPE the CPS-2 hardware and emulation pair since 14z-114)
#      is ANCHORED exactly once (`**[MSC-N]**`) in the docs it distils, and
#      every anchor has a rule — both ways, so a deleted paragraph or an
#      unanchored addition fails;
#   2. the level-1 skill names nothing game-specific (mister_scope.md §1's
#      liftability test);
#   3. every number a skill quotes appears in a LOG, never only in the
#      synthesis mister_core.md;
#   4. every cross-reference [PFX-N] between skills names a defined rule.
# The tool self-tests its extractors on synthetic content every run.
#
# MUST-FIRE CONTROLS ON THE REAL TREE (RH-9: a negative control is wrong
# until it has failed on purpose): a copy of the relevant files is perturbed
# eight ways (14z-114: + an unanchored CPH rule, + a dangling cross-reference, + a port token in the game skill, + a VSP anchor where STATE rolls over) — an unanchored rule appended, one anchor stripped from a doc,
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
# FILES is DERIVED (14z-122): the union of every path checkskills.py and
# doc_anchor_census.py read, printed by the census tool — the hard-coded copy
# of checkskills' own lists drifted whenever a list changed, and a missing
# file makes every control fail for the wrong reason.
FILES="$(python3 tools/doc_anchor_census.py --list-files)"
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

# control b picks the FIRST MSV anchor mister_map.md carries (14z-122: the
# hard-coded MSV-6 broke the control whenever that one paragraph moved file).
mkcopy "$W/b"
BID="$(grep -o '\*\*\[MSV-[0-9]*\]\*\*' "$W/b/docs/project/mister_map.md" | head -1 | tr -d '*[]')"
[ -n "$BID" ] || bad "control b: mister_map.md carries no MSV anchor to strip"
sed -i '' "s/\*\*\[$BID\]\*\* //" "$W/b/docs/project/mister_map.md"
grep -q "\*\*\[$BID\]\*\*" "$W/b/docs/project/mister_map.md" && bad "control b: the anchor was not stripped"
control "stripped anchor" "$W/b" "ANCHORED NOWHERE: $BID"

mkcopy "$W/c"; printf -- '\nA note that names Donovan by name.\n' >> "$W/c/.claude/skills/mister-cps2-wide-core/SKILL.md"
control "game name in level 1" "$W/c" "level-1 skill names 'donovan'"

mkcopy "$W/d"; printf -- '\nThe magic figure is 0xDEADBEEF1.\n' >> "$W/d/.claude/skills/mister-vampire-saved/SKILL.md"
control "number in no log" "$W/d" "in NO log: 0xDEADBEEF1"

mkcopy "$W/e"; printf -- '- [CPH-999] a hardware rule nobody anchored\n' >> "$W/e/.claude/skills/cps2-hardware/SKILL.md"
control "unanchored CPH rule" "$W/e" "ANCHORED NOWHERE: CPH-999"

mkcopy "$W/f"; printf -- '- [CPE-999] a rule with a dangling reference to [CPH-998]\n' >> "$W/f/.claude/skills/cps2-emulation/SKILL.md"
control "dangling cross-reference" "$W/f" "cross-reference \[CPH-998\]"

mkcopy "$W/g"; printf -- '\nA line about the tenant build/m3b_merged17.\n' >> "$W/g/.claude/skills/vampire-savior-engine/SKILL.md"
control "port token in the game skill" "$W/g" "level-1 skill names 'tenant'"

mkcopy "$W/h"; printf -- '- [VSP-999] a port rule anchored where STATE rolls over\n' >> "$W/h/.claude/skills/vampire-saved-port/SKILL.md"
printf -- '\n**[VSP-999]** an anchor appended outside the two standing sections.\n' >> "$W/h/STATE.md"
control "STATE anchor outside the standing sections" "$W/h" "VSP-999 anchored in STATE.md OUTSIDE"

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
