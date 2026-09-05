#!/bin/sh
# test_checkdocs.sh — the load-bearing numbers the docs share are LOCKED
# across documents (14z-118, the documentation audit). ci_portable: no ROM,
# no build dir, no emulator, ~0.2 s.
#
# WHAT IT HOLDS. `tools/checkdocs.py` reads `docs/doc_locks.tsv` and asserts,
# on the real tree, for every row:
#   1. PRESENCE — every listed document quotes the canonical value verbatim
#      (a doc that stops quoting the number fails loudly instead of drifting);
#   2. NO RIVAL — on any line naming the fact (the row's key regex), no other
#      value of the same shape sits within 80 chars after the key unless the
#      row's `also` list allows it (a sibling romset's twin, a P2 mirror).
# The extractors self-test on synthetic content every run.
#
# WHY. `checkskills.py` locks the skills to the docs and checks a number is
# PRESENT in a log; nothing checked that two DOCS agree. The 14z-117
# specimen (a page drawn from the atlas, wrong one hop away) and the 14z-118
# survey (one address quoted in up to five documents, nothing holding them
# together) are the reason. The atlas row is canonical; syntheses follow it.
#
# MUST-FIRE CONTROLS ON THE REAL TREE (RH-9: a negative control is wrong
# until it has failed on purpose): a copy of the locked files is perturbed
# three ways and each copy must FAIL for the stated reason — a doc that drops
# the number (PRESENCE), a doc that quotes a different number beside the
# fact (RIVAL), and a lock row naming a file that does not exist (MISSING).
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier ci_portable (~0.2 s)) THE DOCS ARE LOCKED TO EACH OTHER (14z-118,
#   the documentation audit): `tools/checkdocs.py` reads `docs/doc_locks.tsv`
#   — one row per load-bearing number (label, canonical value, a key regex
#   naming the fact, the documents that must quote it, the sibling values
#   allowed beside it) — and asserts PRESENCE (every listed doc quotes the
#   canonical verbatim) and NO RIVAL (no other value of the same shape within
#   80 chars after the key unless in `also`). The atlas row is canonical;
#   syntheses follow it. Seeded with 16 locks / 40 file-sites from
#   `doc_audit_14z118.md` §2 (OBJ bank table, sprite-palette pointer table, AI
#   script tables, the voice-borrow writer, the Gallon-variant idiom, the
#   loader, the id fold, the id pair, the fade window, name entries, the ring
#   base, match-init normalisation). Twelve extractor self-tests every run;
#   three must-fire controls on a perturbed copy (dropped number, rival
#   number, missing file). Add a row whenever a number is quoted in a second
#   document
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== test_checkdocs: cross-document number locks =="
if python3 tools/checkdocs.py >/tmp/checkdocs.$$.log 2>&1; then
    ok "checkdocs.py PASS on the tree ($(grep -o '[0-9]* locks, [0-9]* file-sites' /tmp/checkdocs.$$.log | head -1))"
else
    bad "checkdocs.py FAILS on the tree:"; sed 's/^/        /' /tmp/checkdocs.$$.log
fi
rm -f /tmp/checkdocs.$$.log

# --- must-fire controls on a perturbed copy -------------------------------
# every file any lock names, plus the table itself
FILES="docs/doc_locks.tsv $(grep -v '^#' docs/doc_locks.tsv | cut -f4 | tr ',' '\n' | sort -u | tr '\n' ' ')"
mkcopy() {  # mkcopy <dir>
    for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done
}
control() {  # control <label> <dir> <expected substring>
    if python3 tools/checkdocs.py --root "$2" --no-selftest >"$2/log" 2>&1; then
        bad "$1: the perturbed copy PASSED — the check is not checking"
    elif grep -q "$3" "$2/log"; then
        ok "$1: fires ($3)"
    else
        bad "$1: failed for the wrong reason:"; sed 's/^/        /' "$2/log"
    fi
}
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# a: engine_internals stops quoting the OBJ bank table address
mkcopy "$W/a"; sed -i.bak 's/PRG:0x282D4/PRG:0x2XXXX4/g' "$W/a/docs/game/engine_internals.md"
control "dropped number (PRESENCE)" "$W/a" "engine_internals.md does not quote PRG:0x282D4 (PRESENCE)"

# b: engine_internals gains a line quoting a DIFFERENT address beside the same label
#    (the original lines stay, so PRESENCE still passes and only RIVAL can fire)
mkcopy "$W/b"; printf '\nA stray note: the per-char OBJ bank table `PRG:0x282D8` (typo).\n' >> "$W/b/docs/game/engine_internals.md"
control "rival number beside the label (RIVAL)" "$W/b" "RIVAL PRG:0x282D8"

# c: a lock row names a file that is not there
mkcopy "$W/c"; printf 'ghost\tPRG:0x282D4\tOBJ bank table\tdocs/game/atlas/ghost.md\t\n' >> "$W/c/docs/doc_locks.tsv"
control "lock names a missing file (MISSING)" "$W/c" "file MISSING: docs/game/atlas/ghost.md"

# d (14z-122): a reflow that removes every line the key matches must be LOUD —
# the NO-RIVAL half of the lock is disarmed while PRESENCE still passes.
# Reword "OBJ bank table" everywhere it appears in the locked files; the
# canonical address stays, so only key-liveness can fire.
mkcopy "$W/d"
for f in docs/game/atlas/character_tables.md docs/game/engine_internals.md docs/game/gotchas.md docs/project/cps2_wide.md; do
    sed -i.bak 's/OBJ bank table/OBJ bank chart/g' "$W/d/$f"
done
control "key matches nothing (NO-RIVAL disarmed)" "$W/d" "matches NOTHING"

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
