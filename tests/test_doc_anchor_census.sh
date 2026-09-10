#!/bin/sh
# test_doc_anchor_census.sh — every skill anchor's FILE and SECTION are frozen
# (14z-122, the documentation rationalization pass). ci_portable: no ROM, no
# build dir, no emulator, ~1 s.
#
# MUST-FIRE: perturbed-copy: anchor-moved-between-files — an MSV anchor moved from mister_map.md to platform/mister.md (both in one checkskills list, so checkskills PASSES it) must fail the frozen census
# MUST-FIRE: perturbed-copy: section-moved — a header inserted above the first anchored line of engine_internals must fail the census (the anchor's section changed)
# MUST-FIRE: perturbed-copy: rule-in-history — a defined rule anchored in a history twin must be reported
# MUST-FIRE: perturbed-copy: stray-archive-token — a bold rule token appended to an archive must appear as a new reviewed row
#
# WHAT IT HOLDS. `tools/doc_anchor_census.py --check` regenerates one row per
# `**[PFX-N]**` anchor (id, file, nearest preceding header, list status) over
# every doc checkskills reads PLUS the archives it does not, and diffs it
# against tests/expected/doc_anchor_census.tsv. A changed row is a MOVED
# anchor. It also hard-fails a defined rule anchored in a `*_history.md` twin
# and a rule on more than one row. The extractor self-tests every run.
#
# WHY. `checkskills.py` asserts "exactly one anchor somewhere in the list" —
# an anchored paragraph moved between two files of the same list, or to
# another section of the same file, passes it SILENTLY (control A below proves
# that on the real tree). A pass that moves hundreds of paragraphs needs the
# movement to be a reviewed diff; after the pass, this stays the lock.
#
# MUST-FIRE CONTROLS ON THE REAL TREE (RH-9: a negative control is wrong
# until it has failed on purpose), each on a perturbed copy:
#   A  an anchor moved BETWEEN two files of one list — checkskills must still
#      PASS on that copy (the blind spot is real) and the census must FAIL;
#   B  a new header inserted above an anchor (a section move) must FAIL;
#   C  a defined rule anchored in a history twin must FAIL as HISTORY;
#   D  a stray bold token appended to an archive must appear as a new row.
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier ci_portable (~1 s)) EVERY SKILL ANCHOR'S FILE AND SECTION ARE FROZEN
#   (14z-122, the documentation rationalization pass):
#   `tools/doc_anchor_census.py` walks every doc `checkskills.py` reads PLUS
#   the archives it does not (STATE_HISTORY, DECISIONS_HISTORY, NEXT_SESSION,
#   GOTCHAS, patch_notes, every `*_history.md` twin) and freezes one row per
#   `[PFX-N]` — id, file, nearest preceding header, list status — in
#   `tests/expected/doc_anchor_census.tsv`; `--check` diffs it, and hard-fails
#   a defined rule anchored in a history twin or on two rows. WHY:
#   `checkskills` asserts "exactly one anchor somewhere in the list", so a
#   paragraph moved between two files of one list, or to another section,
#   passes it SILENTLY — control A proves that on the real tree (checkskills
#   PASSES the move, the census fails it). A doc commit that moves an anchor
#   reviews the diff and `--freeze`s in the same commit. Four must-fire
#   controls (between-file move, section move, history-twin anchor, a stray
#   token in an archive). `--list-files` prints every file this tool and
#   checkskills read, for copies
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

FILES="$(python3 tools/doc_anchor_census.py --list-files)"
mkcopy() {  # mkcopy <dir>
    for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done
}
# read from the REAL files, before any copy
MOVE_ID="$(grep -o '\*\*\[MSV-[0-9]*\]\*\*' docs/project/mister_map.md | head -1 | tr -d '*[]')"
[ -n "$MOVE_ID" ] || bad "anchor-moved-between-files: no MSV anchor in mister_map.md to move"
FIRST_LN="$(grep -n '\*\*\[VSE-[0-9]*\]\*\*' docs/game/engine_internals.md | head -1 | cut -d: -f1)"
# THE PERTURBATIONS, one per declared control; the control section and the
# CONTROL=<name> mode call the same function. EXPECT = the failure's substring.
perturb() {  # perturb <name> <dir>
    case "$1" in
    anchor-moved-between-files)   # both files are in _MISTER_DOCS
        sed -i.bak "s/\*\*\[$MOVE_ID\]\*\* //" "$2/docs/project/mister_map.md"
        printf '\n**[%s]** moved here by the control.\n' "$MOVE_ID" >> "$2/docs/platform/mister.md"
        EXPECT="$MOVE_ID" ;;
    section-moved)
        sed -i.bak "${FIRST_LN}i\\
## A synthetic section inserted by control B
" "$2/docs/game/engine_internals.md"
        EXPECT="A synthetic section inserted by control B" ;;
    rule-in-history)
        printf '# engine_internals — HISTORY\n**[VSE-1]** moved here by control C\n' > "$2/docs/game/engine_internals_history.md"
        EXPECT="VSE-1 anchored in HISTORY file" ;;
    stray-archive-token)
        printf '\n**[CPE-999]** a stray token appended by control D\n' >> "$2/DECISIONS_HISTORY.md"
        EXPECT="CPE-999" ;;
    *) echo "no such perturbation: $1"; exit 3 ;;
    esac
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS the tree
# the main check reads, and this run must FAIL.
ROOT="$REPO"; SELFTEST=""
if [ -n "$VS_CTL" ]; then mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"; ROOT="$W/mode"; SELFTEST="--no-selftest"; fi

echo "== test_doc_anchor_census: every anchor's file + section frozen =="
if python3 tools/doc_anchor_census.py --root "$ROOT" --check $SELFTEST >"$W/tree.log" 2>&1; then
    ok "census matches the frozen file ($(grep -o '[0-9]* anchors' "$W/tree.log" | head -1))"
else
    bad "doc_anchor_census.py --check FAILS on the tree:"; sed 's/^/        /' "$W/tree.log" | head -40
fi

# --- must-fire controls on a perturbed copy -------------------------------
control() {  # control <name>
    d="$W/$1"; mkcopy "$d"; perturb "$1" "$d"
    if [ "$1" = anchor-moved-between-files ]; then
        # the PREMISE: checkskills passes the between-file move (the blind spot is real)
        if python3 tools/checkskills.py --root "$d" --no-selftest >"$d/cs.log" 2>&1; then
            ok "$1 premise: checkskills PASSES the between-file move (the blind spot is real)"
        else
            bad "$1 premise: checkskills FAILED the move — the blind spot closed? read:"; sed 's/^/        /' "$d/cs.log" | head -5
        fi
    fi
    if python3 tools/doc_anchor_census.py --root "$d" --check --no-selftest >"$d/log" 2>&1; then
        vs_ctl_dead "$1" "the perturbed copy PASSED — the check is not checking"; bad "$1"
    elif grep -q "$EXPECT" "$d/log"; then
        vs_ctl_fired "$1" "$EXPECT"; ok "$1: fires"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$d/log" | head -20
    fi
}
for n in $(vs_ctl_declared "$0"); do control "$n"; done

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
