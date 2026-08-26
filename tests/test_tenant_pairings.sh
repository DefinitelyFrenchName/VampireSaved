#!/bin/sh
# test_tenant_pairings.sh — TWO PORTED CHARACTERS IN ONE MATCH, every
# ordering (14z-95). The coverage CLAUDE.md §4 mandates and the suite did not
# have.
#
# WHY IT EXISTS. §4 requires "vs each of the 18 (both sides)" for a ported
# character. Until 14z-95 `tests/replays/` contained no pairing of two ported
# characters AT ALL — which is the gap GitHub #99 walked through, and the
# arcade marathon cannot close it: it is a single-credit soak that plays one
# character, and it reaches only two ladder rungs (measured 14z-95).
#
# WHAT IT ASSERTS, per ordering:
#   1. the run completes with no crash (guarded; a watchdog reset or a 68k
#      exception ends the log without END)
#   2. BOTH characters actually loaded, checked on the per-character hitbox
#      base `+0x60.l`
#
# THE SIGNATURE IS +0x60.l, NOT +0x382 — and that choice is load-bearing.
# 14z-87 proved +0x382 is the VOICE-FLAVOR class in match, not the character
# id (`ram.md:85`); the engine reassigns it. GitHub #16 records a live gate
# (`test_pyron_blink`) whose guard reads +0x382 in match and can therefore
# false-REFUSE. `audit_legacy_pairings` already uses +0x60.l for the same
# reason. Measured 14z-95: the base is stable per character AND independent of
# side — Phobos reads 0x4477b0 as P1 and as P2 — so one frozen value serves
# both orderings.
#
# BOTH ORDERINGS, not just both characters: P1 and P2 are different structs
# reached by different code paths, so D-vs-H and H-vs-D are two tests.
#
# The replay is character-agnostic, so ADDING A PAIRING IS A ROW in
# tests/expected/roster_pairings/bases.tsv — no new replay.
#
# 14z-97: the runner moved to tests/lib/pairing.sh when audit_roster_pairings
# became a second caller, and the frozen bases moved to
# tests/expected/roster_pairings/bases.tsv — where they are DERIVED from the
# merged image's own table at PRG:0x0BD97A rather than transcribed from a run.
# The three tenant values are unchanged by that move (checked both ways).
# Build re-pointed m3b_merged9 -> m3b_merged10 (merged-m3, the current freeze).
#
# Usage: ROMDIR=... [MERGED=build/m3b_merged11] tests/test_tenant_pairings.sh
# ~3 min (6 guarded MAME runs, parallel). Needs the MERGED build: the whole
# point is two tenants in ONE image, which no solo build can express.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${MERGED:-build/m3b_merged15}"  # re-pointed 14z-110b
[ -d "$BUILD/rompath" ] || { echo "SKIP: no merged build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN
. "$REPO/tests/lib/pairing.sh"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok()  { echo "  ok: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

BASES="$REPO/tests/expected/roster_pairings/bases.tsv"
[ -f "$BASES" ] || { echo "FAIL: no $BASES"; exit 1; }
base_of() { awk -v c="$1" 'BEGIN{n=0} !/^#/ && tolower($1)==tolower(c) {print $3; n=1} END{exit !n}' "$BASES"; }
name_of() { awk -v c="$1" '!/^#/ && tolower($1)==tolower(c) {print $2}' "$BASES"; }

run_pair() { pairing_run "$W" "$1" "$2" "$3" "${4:-}"; }

echo "== six orderings of three tenants, on $BUILD"
for a in 0x13 0x10 0x11; do for b in 0x13 0x10 0x11; do
    [ "$a" = "$b" ] && continue
    run_pair "$a" "$b" "${a}_${b}"
done; done
run_pair 0x13 0x10 nopoke_ctl nopoke        # verdict control
wait

check() { pairing_check "$W" "$1" "$(base_of "$2")" "$(base_of "$3")"; }

for a in 0x13 0x10 0x11; do for b in 0x13 0x10 0x11; do
    [ "$a" = "$b" ] && continue
    tag="${a}_${b}"; label="$(name_of "$a") vs $(name_of "$b")"
    if check "$tag" "$a" "$b"; then ok "$label — match formed, both loaded, no crash"
    else bad "$label — see above"; fi
done; done

echo "== verdict control: without the forced picks the check must REFUSE"
if check nopoke_ctl 0x13 0x10 >/dev/null 2>&1; then
    bad "control: an UNPOKED run passed the identity check — the gate cannot"
    echo "     tell a tenant pairing from whatever the replay picks on its own,"
    echo "     so every ok above is vacuous"
else
    ok "control: the unpoked run is correctly rejected"
fi

[ "$fail" = 0 ] && echo "PASS: tenant-vs-tenant, all six orderings (CLAUDE.md §4 coverage)" \
    || { echo "FAIL: tenant pairings"; exit 1; }
