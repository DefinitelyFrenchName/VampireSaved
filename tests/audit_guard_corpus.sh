#!/bin/sh
# audit_guard_corpus.sh — THE AUTHORITATIVE-GUARD CORPUS SOAK (14z-101,
# hardening register §5's queued item). Every replay in tests/replays/*.rpl
# runs under the crash guard on the build under test, in FOUR legs: unpoked,
# and with P1 forced to each tenant (0x10 / 0x11 / 0x13). Any 68k exception,
# PC excursion or soft reset on any leg is a FINDING; rule 6 applies.
#
# WHY IT EXISTS. The suite's comparison gates see divergence, not vectors;
# the guarded coverage before this was six marathon legs of ONE replay
# (audit_tripwire_reach) plus per-gate rigs. This runs the WHOLE corpus —
# 79 replays, ~472k script frames, ~1.9M guarded frames across the legs —
# so every scripted path the project owns has been walked under guard on
# the shipping image at least once per tenant forcing.
#
# HONEST LIMITS, stated rather than implied:
#  - The forced legs poke the P1 commit field over f1400-1700 (the
#    select-commit era of the standard skeletons). A replay whose select
#    window lies elsewhere simply degrades to a legacy run on that leg —
#    still a valid guard leg; this soak measures CRASH-FREEDOM, not
#    coverage attribution. (Poking later frames is deliberately avoided:
#    +0x382 is the VOICE-FLAVOR class in match — ram.md:85 — and writing
#    ids into it mid-match manufactures states real play cannot produce,
#    the audit_kill_poke_shape lesson.)
#  - A PASS means "no vector fired on THESE rigs" — rig-bounded, like
#    every guard soak. Widen the corpus, never the tolerance.
#
# Verdict logic: the guard's own ground truth is tests/test_crash_guard.sh
# (clean negative + vec3/vec4 positive controls) — referenced, not
# re-proven. This script adds the DEAD-leg refusal (a leg with no verdict
# line is not a measurement) and a per-run verdict map kept under
# build/guard_corpus/ for the record.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged12] [JOBS=2]
#        [LEGS="none 10 11 13"] [ONLY=<replay-stem>]
#        [PICK_FRAMES="1400 1450 1500 1600 1700"]
#        tests/audit_guard_corpus.sh
# ~30-45 min at JOBS=2 (niced — playtests may share the machine).
#
# MUST-FIRE CONTROL (run it whenever the classifier is doubted): the
# known 14z-93 crash must reproduce and be named —
#   BUILD=build/hui41 ONLY=26_don_arcade_mash LEGS=10 \
#     PICK_FRAMES="1704 1760 1900 2100 2400" tests/audit_guard_corpus.sh
# must FAIL with the vec4 tripwire for unresolved vs2 0x494de.
# (26's select window is later than the standard skeletons', hence the
# late schedule — the same one audit_tripwire_reach uses.)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged18}"  # re-pointed 14z-115 (select-wheel freeze) <- 14z-113 (merged-m10: one-zip repackaging of merged-m9, same program)
JOBS="${JOBS:-2}"
LEGS="${LEGS:-none 10 11 13}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }

OUTDIR="build/guard_corpus"
mkdir -p "$OUTDIR"
STAMP="$(date +%s)"
MAP="$OUTDIR/$(basename "$BUILD").$STAMP.tsv"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }
RP="$(abspath "$BUILD")/rompath;$ROMDIR"

set -- tests/replays/*.rpl
[ -e "$1" ] || { echo "FAIL: no replays"; exit 1; }

pool=0
sync_pool() { pool=$((pool+1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi; }

echo "== guard soak: $BUILD, legs [$LEGS], JOBS=$JOBS =="
n=0
for rpl in tests/replays/*.rpl; do
    stem="$(basename "$rpl" .rpl)"
    [ -n "${ONLY:-}" ] && [ "$stem" != "$ONLY" ] && continue
    for leg in $LEGS; do
        tag="${stem}__$leg"
        mkdir -p "$W/$tag"
        if [ "$leg" = "none" ]; then PK=""; else
            PK=""
            for pf in ${PICK_FRAMES:-1400 1450 1500 1600 1700}; do
                PK="${PK:+$PK;}$pf:ff8782:$leg"
            done
        fi
        n=$((n+1))
        ( POKES="$PK" MAME_ROMPATH="$RP" \
            nice -n 19 tools/run_replay_guarded.sh vsavjw "$rpl" \
            "$W/$tag/g.log" "$W/$tag/sb" >/dev/null 2>&1 || true ) &
        sync_pool
    done
done
wait
[ "$n" -gt 0 ] || { echo "FAIL: nothing ran (bad ONLY filter?)"; exit 1; }

fail=0
ok=0
printf "replay\tleg\tverdict\n" > "$MAP"
for d in "$W"/*/; do
    tag="$(basename "$d")"
    stem="${tag%__*}"; leg="${tag##*__}"
    log="$d/g.log"
    if [ ! -f "$log" ] || ! grep -qE "^(END |CRASH |END-CRASH |PCWEEDS |SOFTRESET )" "$log"; then
        echo "  DEAD: $tag — no verdict line; not a measurement"
        printf "%s\t%s\tDEAD\n" "$stem" "$leg" >> "$MAP"
        fail=1; continue
    fi
    if grep -qE "^(CRASH |END-CRASH |PCWEEDS |SOFTRESET )" "$log"; then
        line="$(grep -m1 -E '^(CRASH |END-CRASH |PCWEEDS |SOFTRESET )' "$log")"
        printf "%s\t%s\t%s\n" "$stem" "$leg" "$line" >> "$MAP"
        echo "  FAIL: $tag — $line"
        pc="$(printf '%s' "$line" | sed -n 's/.*PC \([0-9a-f]*\).*/\1/p')"
        if [ -n "$pc" ]; then
            who="$(grep -i "0x0*$pc ILLEGAL  TRIPWIRE" \
                   "$BUILD/patch/patch_notes_fragment.md" 2>/dev/null | head -1)"
            [ -n "$who" ] && echo "        $who" \
                          && echo "        => an UNRECONCILED reference is reachable; resolve the row." \
                          || echo "        (not a planted tripwire — an ordinary crash, the worse finding)"
        fi
        # keep the failing leg's evidence
        keep="$OUTDIR/$(basename "$BUILD").$STAMP.$tag"
        mkdir -p "$keep"; cp "$log" "$keep/" 2>/dev/null || true
        fail=1
    else
        printf "%s\t%s\t%s\n" "$stem" "$leg" "$(grep -m1 '^END ' "$log")" >> "$MAP"
        ok=$((ok+1))
    fi
done

echo
echo "   verdict map: $MAP ($n runs, $ok clean)"
if [ "$fail" = 0 ]; then
    echo "PASS: $n guarded runs, zero vectors — the whole corpus is guard-clean"
    echo "      on $BUILD under every tenant forcing. Rig-bounded, as always."
else
    echo "FAIL: a guarded leg produced a vector or died. Rule 6."
fi
exit "$fail"
