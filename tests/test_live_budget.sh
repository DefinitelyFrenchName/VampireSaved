#!/bin/sh
# test_live_budget.sh — the four live documents stay within their size budget (GitHub #282 item F, 14z-201).
# ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHAT: CLAUDE.md, STATE.md, HANDOFF.md and docs/NEXT_SESSION.md each exist, have at most 500 lines and at most
#   50,000 bytes; a document above 200 lines is printed as a WARN (the aim), not failed. The numbers live in one
#   place, tools/check_live_budget.py (tools/check_state_lists.py takes STATE.md's byte cap from there).
# HOW: tools/check_live_budget.py over the tree; controls on a copy of the four documents push one past each limit.
# EXPECTS: the tree passes; each perturbed copy fails and the failure names the document and the limit it broke.
#
# MUST-FIRE: perturbed-copy: over-lines — docs/NEXT_SESSION.md grown past 500 short lines must fail the line maximum, or the 500-line limit is not read
# MUST-FIRE: perturbed-copy: long-lines — HANDOFF.md grown past 50,000 bytes in a few long lines (still under 500 lines) must fail the byte cap, or the budget can be met by writing longer lines
# MUST-FIRE: perturbed-copy: missing-document — a copy without CLAUDE.md must fail by name, or a renamed or deleted live document leaves the budget silently
#
# WHY. The maintainer (#282): "The files are too big again" — rules were skimmed because "there were too many, files
# were too large and you ended up glazing over them". Ruled: "ideally 200 lines long and 500 absolute maximum", a
# cap on bytes as well so long lines cannot meet it, and "50kB sounds like a good targer" (DECISIONS_HISTORY.md
# "Ruled 2026-10-14 (14z-201) — #282's scope" and "Ruled 2026-10-15 (14z-201) — #282 item F"). A document over the
# budget sheds detail to a subject doc or an archive; the archives themselves are indexed, not budgeted.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

FILES="CLAUDE.md STATE.md HANDOFF.md docs/NEXT_SESSION.md"
mkcopy() { for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done; }
perturb() {  # perturb <name> <dir>; EXPECT = the failure's substring
    case "$1" in
    over-lines)       i=0; while [ $i -lt 520 ]; do echo "- a line added by the over-lines control"; i=$((i + 1)); done >> "$2/docs/NEXT_SESSION.md"
                      EXPECT="docs/NEXT_SESSION.md: " ; EXPECT2="-line maximum" ;;
    long-lines)       python3 - "$2/HANDOFF.md" <<'PY'
import sys
p = sys.argv[1]
with open(p, "a") as f:
    for _ in range(4):
        f.write("| a long row added by the long-lines control " + "x" * 6000 + " |\n")
PY
                      EXPECT="HANDOFF.md: " ; EXPECT2="-byte cap" ;;
    missing-document) rm "$2/CLAUDE.md"; EXPECT="CLAUDE.md: MISSING" ; EXPECT2="MISSING" ;;
    *) echo "no such perturbation: $1"; exit 3 ;;
    esac
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS the tree the main check reads, and this run must FAIL.
ROOT="$REPO"
if [ -n "$VS_CTL" ]; then mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"; ROOT="$W/mode"; fi

echo "== test_live_budget: the four live documents within 500 lines and 50,000 bytes =="
if python3 tools/check_live_budget.py --root "$ROOT" >"$W/tree.log" 2>&1; then
    sed 's/^/        /' "$W/tree.log"
    ok "$(tail -1 "$W/tree.log")"
else
    bad "check_live_budget.py FAILS:"; sed 's/^/        /' "$W/tree.log" | head -20
fi

control() {  # control <name>
    d="$W/$1"; mkcopy "$d"; perturb "$1" "$d"
    if python3 tools/check_live_budget.py --root "$d" >"$d/log" 2>&1; then
        vs_ctl_dead "$1" "the perturbed copy PASSED — the check is not checking"; bad "$1"
    elif grep "^FAIL  " "$d/log" | grep -F -e "$EXPECT" | grep -qF -e "$EXPECT2"; then
        vs_ctl_fired "$1" "$(grep "^FAIL  " "$d/log" | grep -F -e "$EXPECT" | head -1)"; ok "$1: fires"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$d/log" | head -8
    fi
}
for n in $(vs_ctl_declared "$0"); do control "$n"; done

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
