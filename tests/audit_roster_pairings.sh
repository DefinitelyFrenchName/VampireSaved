#!/bin/sh
# audit_roster_pairings.sh — EVERY TENANT AGAINST EVERY CHARACTER, BOTH SIDES.
# On-demand, ~1 h (99 guarded MAME runs, batched). 14z-97.
#
# WHY IT EXISTS. CLAUDE.md §4 mandates, for a ported character, "vs each of
# the 18 (both sides)". The suite has never had it. 14z-95's
# test_tenant_pairings closed the tenant-vs-tenant half — six orderings — and
# its own header says why the rest was still missing: the arcade marathon is a
# single-credit soak that plays ONE character and reaches two ladder rungs.
#
# This is the gap GitHub #99 walked through: a crash reported in a pairing no
# rig had ever run. It is also the MUST-HAVE scope (2P versus), which is why
# it gets the machine ahead of the arcade-ladder work (#102, extended scope).
#
# WHAT IT ASSERTS, per pairing — the same two things the fast gate asserts:
#   1. the run completes with no crash (guarded: a watchdog reset or a 68k
#      exception ends the log without END)
#   2. BOTH characters actually loaded, on the per-character hitbox base
#      `+0x60.l`, against tests/expected/roster_pairings/bases.tsv
#
# THE EXPECTATIONS ARE DERIVED FROM THE ROM, not from a run — read out of the
# merged image's own table at PRG:0x0BD97A. An expectation harvested from the
# run it polices cannot fail. See that directory's README, which also records
# why 0x0B is excluded (it is not a character) and 0x18 included (it is the
# "+1"), and the two-source check that the 16 legacy bases are byte-identical
# in vanilla.
#
# A CRASH HERE IS THE POINT, AND IT STOPS THE RUN BEING A COVERAGE EXERCISE.
# This rig exists to find one on the artifact people play. If a pairing fails
# END-clean, that is rule 6 territory: capture it as a minimal reproduction
# and report it — do not keep batching for a completeness number. The matrix
# below prints as it goes so a stopped run is still evidence.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged11] [JOBS=6]
#        [ONLY=0x13] [BASES=...] tests/audit_roster_pairings.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged18}"  # re-pointed 14z-115 (select-wheel freeze) <- 14z-113 (merged-m10: one-zip repackaging of merged-m9, same program)
JOBS="${JOBS:-6}"
[ -d "$BUILD/rompath" ] || { echo "SKIP: no merged build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN
. "$REPO/tests/lib/pairing.sh"

# BASES is overridable so a single pairing can be reproduced, and so the
# matrix can be smoke-tested on a trimmed table without an hour of MAME.
BASES="${BASES:-$REPO/tests/expected/roster_pairings/bases.tsv}"
[ -f "$BASES" ] || { echo "FAIL: no $BASES"; exit 1; }

TENANTS="${ONLY:-0x13 0x10 0x11}"
ALL="$(awk '!/^#/ && NF {print $1}' "$BASES" | tr '\n' ' ')"
base_of() { awk -v c="$1" '!/^#/ && $1==c {print $3}' "$BASES"; }
name_of() { awk -v c="$1" '!/^#/ && $1==c {print $2}' "$BASES"; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0; pass=0; crashed=""

echo "build   $BUILD"
echo "roster  $(echo "$ALL" | wc -w | tr -d ' ') classes; tenants under test: $TENANTS"
echo "jobs    $JOBS"
echo

# Build the work list: each tenant against every class, BOTH sides. A tenant
# mirror (same class both sides) is included once — it is one of "the 18".
LIST=""
for t in $TENANTS; do
    for o in $ALL; do
        LIST="$LIST $t:$o"
        [ "$t" = "$o" ] || LIST="$LIST $o:$t"
    done
done
LIST="$LIST 0x13:0x10:nopoke_ctl"      # the verdict control, run last

n=0
pool=0
for item in $LIST; do
    p1="${item%%:*}"; rest="${item#*:}"; p2="${rest%%:*}"
    mode=""; tag="$(echo "$p1$p2" | tr -d '#x')_$n"
    case "$item" in *:nopoke_ctl) mode=nopoke; tag=nopoke_ctl ;; esac
    pairing_run "$W" "$p1" "$p2" "$tag" $mode
    eval "TAG_$n=\$tag; P1_$n=\$p1; P2_$n=\$p2; MODE_$n=\$mode"
    n=$((n + 1))
    pool=$((pool + 1))
    if [ "$pool" -ge "$JOBS" ]; then
        wait
        pool=0
        printf '  ... %d/%d runs done\n' "$n" "$(echo "$LIST" | wc -w | tr -d ' ')"
    fi
done
wait
echo

i=0
while [ "$i" -lt "$n" ]; do
    eval "tag=\$TAG_$i; p1=\$P1_$i; p2=\$P2_$i; mode=\$MODE_$i"
    label="$(name_of "$p1") vs $(name_of "$p2")"
    if [ "$mode" = nopoke ]; then
        # THE VERDICT CONTROL. Without the forced picks the identity check
        # must REFUSE; if it passes, the matrix cannot tell a real pairing
        # from whatever the replay picks on its own and every ok above is
        # vacuous.
        if pairing_check "$W" "$tag" "$(base_of "$p1")" "$(base_of "$p2")" >/dev/null 2>&1; then
            echo "FAIL: control — an UNPOKED run passed the identity check, so"
            echo "      every result above is vacuous"
            fail=1
        else
            echo "  ok: control — the unpoked run is correctly rejected"
        fi
    elif out=$(pairing_check "$W" "$tag" "$(base_of "$p1")" "$(base_of "$p2")"); then
        pass=$((pass + 1))
    else
        echo "FAIL: $label"
        printf '%s\n' "$out"
        crashed="$crashed $label;"
        fail=1
    fi
    i=$((i + 1))
done

echo
echo "  $pass pairing(s) formed cleanly with both characters loaded"
if [ -n "$crashed" ]; then
    echo "  FAILED:$crashed"
    echo
    echo "  A failure here is a defect on the SHIPPING artifact, not a gate"
    echo "  problem. Reproduce the single pairing with"
    echo "    ONLY=<tenant class> tests/audit_roster_pairings.sh"
    echo "  and treat it as rule 6 before doing anything else."
fi
[ "$fail" = 0 ] && echo "PASS: roster pairings — every tenant vs every character, both sides" \
    || { echo "FAIL: see above"; exit 1; }
