#!/bin/sh
# test_state_open_lists.sh — AN OPEN LIST HOLDS ONLY WHAT IS OPEN: STATE.md's
# open lists, its size budget and session-group count, NEXT_SESSION's START
# HERE, and THE LEDGER's keys (14z-154; maintainer-ruled 2026-09-14, CLAUDE.md
# [VSP-17]). ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHAT: an open list holds only what is open: STATE.md's 'Decisions pending' and
#   NEXT_SESSION's START HERE carry no closed marker, STATE stays within its size budget and
#   session-group count with exactly the four standing sections and no ticket list, standing
#   rulings are one line each with a home, and every ledger key in either line form resolves
#   to an archived record — violations that predate the rule frozen shrink-only.
# HOW: tools/check_state_lists.py over STATE.md, docs/NEXT_SESSION.md and STATE_HISTORY.md
#   against tests/expected/state_open_lists_debt.txt (~1 s); seven controls on perturbed
#   copies (a struck-through pending entry, a DONE start-here entry, a ticket section, a
#   fourth group, an over-budget file, an unresolved ledger key in each line form).
# EXPECTS: no new violation and no listed one that stopped occurring; each control fails. It
#   does not claim an entry with no marker is open.
#
# MUST-FIRE: perturbed-copy: closed-pending-entry — a struck-through DECIDED entry added to "Decisions pending" must fail as a pending violation
# MUST-FIRE: perturbed-copy: closed-start-here — a DONE entry added to docs/NEXT_SESSION.md "START HERE" must fail as a start-here violation; this branch parsed ZERO entries from 2026-09-18 (when the section became a NUMBERED list and the parser knew only bullets) until 14z-172, and no control exercised it
# MUST-FIRE: perturbed-copy: ticket-section — an "Open bugs" section added under the standing sections must fail (tickets are never listed in STATE)
# MUST-FIRE: perturbed-copy: fourth-group — session group headings added above the standing sections must fail the group count
# MUST-FIRE: perturbed-copy: over-budget — STATE.md padded past 150 KiB must fail the size budget
# MUST-FIRE: perturbed-copy: unresolved-ledger-key — a ledger line naming a session with no record in STATE_HISTORY.md must fail
# MUST-FIRE: perturbed-copy: unresolved-ledger-key-bold — the same in the ledger's SECOND line form, `- **KEY** (date) — …`, which the checker did not match until 14z-179 (four real lines went unchecked)
#
# WHAT IT HOLDS. `tools/check_state_lists.py` reads STATE.md, docs/NEXT_SESSION.md
# and STATE_HISTORY.md and names every violation by a stable key: the size
# budget, the group count, a standing section that is not one of the four, a
# heading that lists tickets, an entry of "Decisions pending" or "START HERE"
# carrying a closed marker (`~~` or a word such as DECIDED / DONE / FIXED), a
# standing ruling longer than one line or naming no home, and a ledger key that
# resolves to no archived record. Violations that existed when the rule was
# written are frozen in tests/expected/state_open_lists_debt.txt, which only
# SHRINKS: a new violation fails, and so does a listed one that no longer occurs.
#
# WHY. The maintainer, 2026-09-14: "we again have many open items (decisions,
# bugs, etc.) that are still listed as open with a mention that they are
# actually closed", and the discipline must be "documented and enforced" rather
# than "just a mention somewhere that never sees any systematic action". STATE's
# own header had prescribed marking closed items in place; nothing read the
# lists, the budget or the group rule.
#
# WHAT IT DOES NOT CLAIM: that an entry with no marker is open. The markers are
# what marking in place leaves behind; a closed item described without one
# passes, and judging that stays with the close.
#
# Usage: tests/test_state_open_lists.sh      # ci_portable
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

FILES="STATE.md STATE_HISTORY.md docs/NEXT_SESSION.md tests/expected/state_open_lists_debt.txt"
mkcopy() {  # mkcopy <dir>
    for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done
}
# THE PERTURBATIONS, one per declared control; the control section and the
# CONTROL=<name> mode call the same function. EXPECT = the failure's substring.
perturb() {  # perturb <name> <dir>
    python3 - "$1" "$2" <<'PY' || { echo "no such perturbation: $1"; exit 3; }
import sys
from pathlib import Path
name, root = sys.argv[1], Path(sys.argv[2])
state, hist = root / "STATE.md", root / "STATE_HISTORY.md"
s = state.read_text()
if name == "closed-pending-entry":
    i = s.index("\n## Decisions pending")
    j = s.index("\n", i + 1) + 1
    s = s[:j] + "\n- ~~**A SYNTHETIC ITEM ADDED BY THE CONTROL**~~ **DECIDED** in place.\n" + s[j:]
elif name == "closed-start-here":
    nxt = root / "docs" / "NEXT_SESSION.md"
    x = nxt.read_text()
    i = x.index("\n## START HERE")
    j = x.index("\n", i + 1) + 1
    nxt.write_text(x[:j] + "\n9. **A SYNTHETIC START-HERE ITEM ADDED BY THE CONTROL IS DONE** — it must fail.\n" + x[j:])
elif name == "ticket-section":
    s += "\n## Open bugs (synthetic, added by the control)\n\n- a bug listed in STATE\n"
elif name == "fourth-group":
    i = s.index("\n# STANDING SECTIONS")
    fake = "".join(f"\n## Session 14z-00{n} — a synthetic group added by the control\n\n| | |\n|---|---|\n"
                   for n in range(4))
    s = s[:i] + fake + s[i:]
elif name == "over-budget":
    s += "\n" + ("padding added by the over-budget control. " * 4000) + "\n"
elif name == "unresolved-ledger-key":
    h = hist.read_text()
    i = h.index("\n- Session ")
    h = h[:i] + "\n- Session 14z-999 — a synthetic ledger line added by the control" + h[i:]
    hist.write_text(h)
elif name == "unresolved-ledger-key-bold":
    h = hist.read_text()
    i = h.index("\n- Session ")
    h = h[:i] + "\n- **14z-998** (2026-01-01) — a synthetic ledger line in the second form, added by the control" + h[i:]
    hist.write_text(h)
else:
    sys.exit(1)
state.write_text(s)
PY
    case "$1" in
    closed-pending-entry)  EXPECT="A SYNTHETIC ITEM ADDED BY THE CONTROL" ;;
    closed-start-here)     EXPECT="start-here" ;;
    ticket-section)        EXPECT="Open bugs (synthetic" ;;
    fourth-group)          EXPECT="session groups above" ;;
    over-budget)           EXPECT="KiB budget" ;;
    unresolved-ledger-key) EXPECT="ledger key 14z-999" ;;
    unresolved-ledger-key-bold) EXPECT="ledger key 14z-998" ;;
    esac
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS the tree the
# main check reads, and this run must FAIL.
ROOT="$REPO"
if [ -n "$VS_CTL" ]; then mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"; ROOT="$W/mode"; fi

echo "== test_state_open_lists: an open list holds only what is open =="
if python3 tools/check_state_lists.py --root "$ROOT" >"$W/tree.log" 2>&1; then
    ok "$(grep '^PASS' "$W/tree.log")"
else
    bad "check_state_lists.py FAILS on the tree:"; sed 's/^/        /' "$W/tree.log" | head -40
fi

# --- must-fire controls on a perturbed copy -------------------------------
control() {  # control <name>
    d="$W/$1"; mkcopy "$d"; perturb "$1" "$d"
    if python3 tools/check_state_lists.py --root "$d" >"$d/log" 2>&1; then
        vs_ctl_dead "$1" "the perturbed copy PASSED — the check is not checking"; bad "$1"
    elif grep -qF "$EXPECT" "$d/log"; then
        vs_ctl_fired "$1" "$EXPECT"; ok "$1: fires"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$d/log" | head -20
    fi
}
for n in $(vs_ctl_declared "$0"); do control "$n"; done

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
