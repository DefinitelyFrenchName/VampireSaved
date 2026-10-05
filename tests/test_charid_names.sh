#!/bin/sh
# test_charid_names.sh — EVERY IN-TREE CHARACTER-ID -> NAME MAP AGREES WITH THE ATLAS SLOT TABLE
# (GitHub #218, 14z-191). ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHAT: every Python dict under tools/ and tests/ that maps character ids to names (`0x0A: "Sasquatch"`
#   or `"SA": (0x0A, "Sasquatch")`, at least four of its names characters of the table) names each id
#   0x00-0x0F (the random cell 0x0B excepted) as docs/game/atlas/character_tables.md's slot table does —
#   and the census finds at least the frozen floor of such maps.
# HOW: tools/audit_charid_names.py reads the atlas table (refusing one that does not yield fifteen ids),
#   parses every tracked .py by AST (never importing it), and judges each (id, name) pair whose name is a
#   character of the table; the floor is tests/expected/charid_name_maps_floor.txt (rises only).
# EXPECTS: PASS with 0 mismatches and at least the floor's maps. A red names the file, line, id and both
#   names — the #218 shape, where tools/audit_poked_legs.py labelled 0x0A-0x0E one row off (Q-Bee at
#   0x0A, Lilith at 0x0D) — or a census that found fewer maps than the floor, a tool gone blind.
#
# MUST-FIRE: perturbed-copy: shifted-map — the census plus a planted map carrying #218's own shift (0x0A Q-Bee, 0x0C Lei-Lei, 0x0D Lilith, 0x0E Sasquatch) must report the planted rows and FAIL (mode: the tool's --plant)
# MUST-FIRE: perturbed-copy: blind-floor — the census held to a floor one above what it finds must fail: a census that loses a map is a red, never a quieter pass (mode: --floor N+1)
#
# Usage: tests/test_charid_names.sh            # FREEZE=1 raises the floor to today's count
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
TOOL="python3 tools/audit_charid_names.py"
FLOOR_FILE="tests/expected/charid_name_maps_floor.txt"
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

floor="$(grep -v '^#' "$FLOOR_FILE" | tr -d ' \n')"
case "$floor" in ''|*[!0-9]*) echo "FAIL: $FLOOR_FILE carries no integer floor"; exit 1;; esac

if vs_ctl_is shifted-map; then
    echo "== MODE shifted-map: the census with #218's shift planted"
    $TOOL --plant --floor "$floor"; rc=$?
    [ "$rc" -eq 0 ] && { echo "FAIL: the planted shift passed"; exit 1; }
    echo "FAIL (mode): as required — the planted shift was reported"; exit 1
fi
if vs_ctl_is blind-floor; then
    echo "== MODE blind-floor: the census held to one map more than it finds"
    n="$($TOOL --floor 0 | sed -n 's/.* \([0-9]*\) character maps,.*/\1/p')"
    $TOOL --floor "$((n + 1))"; rc=$?
    [ "$rc" -eq 0 ] && { echo "FAIL: a census below its floor passed"; exit 1; }
    echo "FAIL (mode): as required — the census below its floor failed"; exit 1
fi

echo "== 1. the census, floor $floor (from $FLOOR_FILE)"
out="$($TOOL --floor "$floor" 2>&1)"; rc=$?
echo "$out" | sed 's/^/  /'
if [ "$rc" -eq 0 ]; then ok "every id->name pair agrees with the atlas, at or above the floor"; else bad "the census is red (exit $rc)"; fi
n="$(echo "$out" | sed -n 's/.* \([0-9]*\) character maps,.*/\1/p' | head -1)"
if [ "${FREEZE:-0}" = 1 ] && [ -n "$n" ] && [ "$n" -gt "$floor" ]; then
    { echo "# tests/expected/charid_name_maps_floor.txt — the fewest character-id -> name maps"; echo "# tests/test_charid_names.sh accepts (rises only; FREEZE=1 after review). Provenance:"; echo "# tests/expected/PROVENANCE.md."; echo "$n"; } > "$FLOOR_FILE"
    echo "  FROZE floor $floor -> $n"
fi

echo "== 2. controls: each must fire in-gate (the modes above prove them as modes)"
P="$($TOOL --plant --floor "$floor" 2>&1)"
if printf '%s\n' "$P" | grep -q '^CONTROL FIRED: shifted-map' && printf '%s\n' "$P" | grep -q '^MISMATCH <plant'; then
    vs_ctl_fired shifted-map "$(printf '%s\n' "$P" | grep '^CONTROL FIRED: shifted-map' | sed 's/^CONTROL FIRED: shifted-map — //')"
else vs_ctl_dead shifted-map "the planted shift was not reported"; fail=1; fi
if [ -n "$n" ] && ! $TOOL --floor "$((n + 1))" >/dev/null 2>&1; then
    vs_ctl_fired blind-floor "held to $((n + 1)) maps, the census of $n failed"
else vs_ctl_dead blind-floor "a census below its floor passed (n='$n')"; fail=1; fi

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
