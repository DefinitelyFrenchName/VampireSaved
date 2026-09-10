#!/bin/sh
# test_checkskills.sh — the eight skills are locked to the docs they distil
# (14z-114; level 0 added 14z-134). ci_portable: no ROM, no build dir, no
# emulator, ~1 s.
#
# MUST-FIRE: perturbed-copy: unanchored-rule — a rule appended to a level-1 skill with no anchor in any doc must be reported ANCHORED NOWHERE
# MUST-FIRE: perturbed-copy: stripped-anchor — the first MSV anchor stripped from mister_map.md must leave its rule ANCHORED NOWHERE
# MUST-FIRE: perturbed-copy: game-name-in-level1 — a level-1 (board) skill naming a character must fail the liftability test
# MUST-FIRE: perturbed-copy: number-in-no-log — a figure a skill quotes that no LOG carries must be reported
# MUST-FIRE: perturbed-copy: unanchored-cph-rule — the same for the hardware skill's prefix
# MUST-FIRE: perturbed-copy: dangling-crossref — a rule citing an ID no skill defines must be reported
# MUST-FIRE: perturbed-copy: port-token-in-game-skill — the game skill naming a tenant must fail its liftability test
# MUST-FIRE: perturbed-copy: state-anchor-outside — a VSP anchor in STATE.md outside the two standing sections must be reported (it would roll to the archive)
# MUST-FIRE: perturbed-copy: unanchored-level0-rule — the level-0 skills are locked the same way
# MUST-FIRE: perturbed-copy: board-name-in-level0 — a level-0 skill naming the board must fail the stricter liftability test
# MUST-FIRE: perturbed-copy: redirect-removed — a lifted rule's redirect stub deleted leaves its old ID undefined, which must be reported
#
# LEVEL 0 (14z-134): `mame-fbneo-instruments` [MFI] and `mister-jtframe-core`
# [MJC] carry the rules of CPE/CPH/MSC that would still be true if the board
# were not CPS-2. A lifted rule KEEPS ITS NUMBER and anchors in the SAME
# paragraph as the CPS-2 rule it lifts; the CPS-2 skill keeps the old ID as a
# one-line redirect, because 350+ citations outside the skills name the old
# IDs. Three controls below: an unanchored level-0 rule, a board name in
# level 0, and a redirect stub deleted (its anchor goes orphan).
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
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier ci_portable (~1 s)) THE SKILLS ARE LOCKED TO THE DOCS (14z-114): the
#   MiSTer pair `[MSC]`/`[MSV]`, the CPS-2 pair `cps2-hardware` `[CPH]` /
#   `cps2-emulation` `[CPE]`, the game skill `vampire-savior-engine` `[VSE]`
#   (anchored in `engine_internals.md`, `game/gotchas.md` and the atlas;
#   forbids port vocabulary), and the port skill `vampire-saved-port` `[VSP]`
#   (161 rules anchored in CLAUDE.md, HANDOFF, both gotchas, the
#   porting/manifest/triage/hardening/registry docs and — ONLY under "STANDING
#   PRINCIPLE" / "THE DEADNESS REGISTER", because the file rolls — STATE.md),
#   table-driven per prefix. `tools/checkskills.py`: every `- [PFX-N]` rule in
#   `.claude/skills/*/SKILL.md` is anchored exactly once (`[MSC-N]` at the doc
#   paragraph it distils) and every anchor has a rule; the level-1 skill names
#   nothing game-specific (`mister_scope.md` §1); every number a skill quotes
#   appears in a LOG (`platform/mister.md`, `mister_map.md`, `mister_fit.md`,
#   `mister_field.md`, `release_format.md`, the gotchas, `BITSTREAM.txt`) and
#   never only in the synthesis. Cross-references `[PFX-N]` between skills
#   must name a defined rule. Extractors self-tested; eight must-fire controls
#   on a perturbed copy (unanchored rule ×2, stripped anchor, a game name in
#   level 1, a port token in the game skill, an uncited number, a dangling
#   cross-reference, a VSP anchor in STATE outside the standing sections).
#   Editing an anchored paragraph: keep the marker with the fact, or move the
#   rule
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# FILES is DERIVED (14z-122): the union of every path checkskills.py and
# doc_anchor_census.py read, printed by the census tool — the hard-coded copy
# of checkskills' own lists drifted whenever a list changed, and a missing
# file makes every control fail for the wrong reason.
FILES="$(python3 tools/doc_anchor_census.py --list-files)"
mkcopy() {  # mkcopy <dir>
    for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done
}
# control stripped-anchor picks the FIRST MSV anchor mister_map.md carries
# (14z-122: the hard-coded MSV-6 broke the control whenever that paragraph
# moved file) — read from the REAL file, before any copy
BID="$(grep -o '\*\*\[MSV-[0-9]*\]\*\*' docs/project/mister_map.md | head -1 | tr -d '*[]')"
[ -n "$BID" ] || bad "stripped-anchor: mister_map.md carries no MSV anchor to strip"
# THE PERTURBATIONS, one per declared control; the control section and the
# CONTROL=<name> mode call the same function. EXPECT = the failure's substring.
perturb() {  # perturb <name> <dir>
    case "$1" in
    unanchored-rule)   printf -- '- [MSC-999] a rule nobody anchored\n' >> "$2/.claude/skills/mister-cps2-wide-core/SKILL.md"; EXPECT="ANCHORED NOWHERE" ;;
    stripped-anchor)   sed -i.bak "s/\*\*\[$BID\]\*\* //" "$2/docs/project/mister_map.md"
                       grep -q "\*\*\[$BID\]\*\*" "$2/docs/project/mister_map.md" && bad "stripped-anchor: the anchor was not stripped"
                       EXPECT="ANCHORED NOWHERE: $BID" ;;
    game-name-in-level1) printf -- '\nA note that names Donovan by name.\n' >> "$2/.claude/skills/mister-cps2-wide-core/SKILL.md"; EXPECT="level-1 skill names 'donovan'" ;;
    number-in-no-log)  printf -- '\nThe magic figure is 0xDEADBEEF1.\n' >> "$2/.claude/skills/mister-vampire-saved/SKILL.md"; EXPECT="in NO log: 0xDEADBEEF1" ;;
    unanchored-cph-rule) printf -- '- [CPH-999] a hardware rule nobody anchored\n' >> "$2/.claude/skills/cps2-hardware/SKILL.md"; EXPECT="ANCHORED NOWHERE: CPH-999" ;;
    dangling-crossref) printf -- '- [CPE-999] a rule with a dangling reference to [CPH-998]\n' >> "$2/.claude/skills/cps2-emulation/SKILL.md"; EXPECT="cross-reference \[CPH-998\]" ;;
    port-token-in-game-skill) printf -- '\nA line about the tenant build/m3b_merged17.\n' >> "$2/.claude/skills/vampire-savior-engine/SKILL.md"; EXPECT="level-1 skill names 'tenant'" ;;
    state-anchor-outside) printf -- '- [VSP-999] a port rule anchored where STATE rolls over\n' >> "$2/.claude/skills/vampire-saved-port/SKILL.md"
                       printf -- '\n**[VSP-999]** an anchor appended outside the two standing sections.\n' >> "$2/STATE.md"
                       EXPECT="VSP-999 anchored in STATE.md OUTSIDE" ;;
    # level 0 (14z-134): the two board-agnostic skills are locked the same way,
    # and their liftability test is one level stricter — naming the BOARD fails.
    unanchored-level0-rule) printf -- '- [MFI-999] an instrument rule nobody anchored\n' >> "$2/.claude/skills/mame-fbneo-instruments/SKILL.md"; EXPECT="ANCHORED NOWHERE: MFI-999" ;;
    board-name-in-level0) printf -- '\nA note that says this is true on CPS-2 only.\n' >> "$2/.claude/skills/mister-jtframe-core/SKILL.md"; EXPECT="level-1 skill names 'cps'" ;;
    # a redirect stub must keep the old ID DEFINED: stripping one leaves its
    # anchor orphaned, which is exactly the failure that would break a citation.
    redirect-removed)  sed -i.bak '/^- \[CPE-24\] /d' "$2/.claude/skills/cps2-emulation/SKILL.md"; EXPECT="NOT DEFINED in the skill: CPE-24" ;;
    *) echo "no such perturbation: $1"; exit 3 ;;
    esac
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS the tree
# the main check reads, and this run must FAIL.
ROOT="$REPO"; SELFTEST=""
if [ -n "$VS_CTL" ]; then mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"; ROOT="$W/mode"; SELFTEST="--no-selftest"; fi

echo "== test_checkskills: skills locked to docs =="
if python3 tools/checkskills.py --root "$ROOT" $SELFTEST >"$W/tree.log" 2>&1; then
    ok "checkskills.py PASS on the tree ($(grep -o '[0-9]* rules' "$W/tree.log" | head -1))"
else
    bad "checkskills.py FAILS on the tree:"; sed 's/^/        /' "$W/tree.log"
fi

# --- must-fire controls on a perturbed copy -------------------------------
control() {  # control <name>
    d="$W/$1"; mkcopy "$d"; perturb "$1" "$d"
    if python3 tools/checkskills.py --root "$d" --no-selftest >"$d/log" 2>&1; then
        vs_ctl_dead "$1" "the perturbed copy PASSED — the check is not checking"; bad "$1"
    elif grep -q "$EXPECT" "$d/log"; then
        vs_ctl_fired "$1" "$EXPECT"; ok "$1: fires"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$d/log"
    fi
}
for n in $(vs_ctl_declared "$0"); do control "$n"; done

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
