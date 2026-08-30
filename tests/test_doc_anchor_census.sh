#!/bin/sh
# test_doc_anchor_census.sh — every skill anchor's FILE and SECTION are frozen
# (14z-122, the documentation rationalization pass). ci_portable: no ROM, no
# build dir, no emulator, ~1 s.
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
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== test_doc_anchor_census: every anchor's file + section frozen =="
if python3 tools/doc_anchor_census.py --check >/tmp/anchor_census.$$.log 2>&1; then
    ok "census matches the frozen file ($(grep -o '[0-9]* anchors' /tmp/anchor_census.$$.log | head -1))"
else
    bad "doc_anchor_census.py --check FAILS on the tree:"; sed 's/^/        /' /tmp/anchor_census.$$.log | head -40
fi
rm -f /tmp/anchor_census.$$.log

# --- must-fire controls on a perturbed copy -------------------------------
FILES="$(python3 tools/doc_anchor_census.py --list-files)"
mkcopy() {  # mkcopy <dir>
    for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done
}
control() {  # control <label> <dir> <expected substring>
    if python3 tools/doc_anchor_census.py --root "$2" --check --no-selftest >"$2/log" 2>&1; then
        bad "$1: the perturbed copy PASSED — the check is not checking"
    elif grep -q "$3" "$2/log"; then
        ok "$1: fires ($3)"
    else
        bad "$1: failed for the wrong reason:"; sed 's/^/        /' "$2/log" | head -20
    fi
}
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# A: MSV-6 moves from mister_map.md to platform/mister.md — both in _MISTER_DOCS
mkcopy "$W/a"
ID="$(grep -o '\*\*\[MSV-[0-9]*\]\*\*' "$W/a/docs/project/mister_map.md" | head -1 | tr -d '*[]')"
[ -n "$ID" ] || bad "control A: no MSV anchor in mister_map.md to move"
sed -i '' "s/\*\*\[$ID\]\*\* //" "$W/a/docs/project/mister_map.md"
printf '\n**[%s]** moved here by the control.\n' "$ID" >> "$W/a/docs/platform/mister.md"
if python3 tools/checkskills.py --root "$W/a" --no-selftest >"$W/a/cs.log" 2>&1; then
    ok "control A premise: checkskills PASSES the between-file move (the blind spot is real)"
else
    bad "control A premise: checkskills FAILED the move — the blind spot closed? read:"; sed 's/^/        /' "$W/a/cs.log" | head -5
fi
control "A: anchor moved between two files of one list" "$W/a" "$ID"

# B: a header inserted directly above the first anchored line of engine_internals
mkcopy "$W/b"
LN="$(grep -n '\*\*\[VSE-[0-9]*\]\*\*' "$W/b/docs/game/engine_internals.md" | head -1 | cut -d: -f1)"
sed -i '' "${LN}i\\
## A synthetic section inserted by control B
" "$W/b/docs/game/engine_internals.md"
control "B: a section move (header inserted above an anchor)" "$W/b" "A synthetic section inserted by control B"

# C: a defined rule anchored in a history twin
mkcopy "$W/c"
printf '# engine_internals — HISTORY\n**[VSE-1]** moved here by control C\n' > "$W/c/docs/game/engine_internals_history.md"
control "C: a rule anchored in a history file" "$W/c" "VSE-1 anchored in HISTORY file"

# D: a stray bold token in an archive becomes a new reviewed row
mkcopy "$W/d"
printf '\n**[CPE-999]** a stray token appended by control D\n' >> "$W/d/DECISIONS_HISTORY.md"
control "D: a new stray token in an archive" "$W/d" "CPE-999"

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
