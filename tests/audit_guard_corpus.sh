#!/bin/sh
# audit_guard_corpus.sh — THE AUTHORITATIVE-GUARD CORPUS SOAK (14z-101,
# hardening register §5's queued item). Every replay in tests/replays/*.rpl
# runs under the crash guard on the build under test, in FOUR legs: unpoked,
# and with P1 forced to each tenant (0x10 / 0x11 / 0x13). Any 68k exception,
# PC excursion or soft reset on any leg is a FINDING; rule 6 applies.
#
# WHAT: every replay in tests/replays runs under the authoritative crash guard on the build
#   under test in four legs — unpoked and with P1 forced to each tenant — with no 68k
#   exception, PC excursion or soft reset anywhere (rule 6 on any finding).
# HOW: ~79 replays x 4 legs, guarded on MAME at JOBS legs at once (default min(8, CPUs/3)), a DEAD leg (no verdict
#   line) refused; the control runs the 14z-93 crash rig on build/hui41 (one guarded leg, ~25 s) and must
#   reproduce the planted vec4 tripwire for unresolved 0x494de, named by build/hui41's patch notes.
# EXPECTS: every leg END-clean; the known crash reproduced by the control. A PASS is
#   rig-bounded: no vector fired on THESE rigs — widen the corpus, never the tolerance.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh tests/lua/emu_clock.lua
#   tests/lua/replay_guard.lua tests/replays/ tools/run_mame.sh tools/run_replay_guarded.sh
#   tools/setup_mame.sh
#
# SHEET: none — runs our build only, judged on its own; no reference leg and no frozen reference values
#
# MUST-FIRE: known-bad: known-crash — the 14z-93 rig (build/hui41 + 26_don_arcade_mash, P1 forced to 0x10 over the late pick frames, replay and picks one frame earlier for the emulated clock, #373) must reproduce the planted vec4 tripwire for unresolved 0x494de (in-gate on every plain run; as a mode the soak runs only that rig and the gate FAILs on that tripwire's line; REFUSES with exit 3 if build/hui41 or the replay is absent)
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
#    +0x382 is the live character id in match — ram.md +0x382 — and writing
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
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged34] [JOBS=N]
#        [LEGS="none 10 11 13"] [ONLY=<replay-stem>]
#        [PICK_FRAMES="1400 1450 1500 1600 1700"]
#        tests/audit_guard_corpus.sh
# ~30-45 min at JOBS=2 (niced — playtests may share the machine). The default is min(8, CPUs/3), at least 1, since
# 14z-209 (#321, maintainer-ruled 2026-10-26 "Guard corpus jobs"): measured alone on ERIS (24 threads, fork A,
# build/agent209/t321/) 3,106 s at 2, 1,138 s at 8, 830 s at 16, the 389-row verdict table byte-identical; 4,827 s at 2
# inside the 14z-208b freeze tier, 1,679 s at 8 inside the proposed one.
#
# MUST-FIRE CONTROL (run it whenever the classifier is doubted): the
# known 14z-93 crash must reproduce and be named —
#   CONTROL=known-crash tests/audit_guard_corpus.sh
# must FAIL with the vec4 tripwire for unresolved vs2 0x494de.
# (26's select window is later than the standard skeletons', hence the
# late schedule — the same one audit_tripwire_reach uses.)
# RE-TIMED FOR THE EMULATED CLOCK (#373, 14z-227). The rig was written on replay_guard.lua's old clock, which counted
# frame_done calls, so under -debug its input landed one frame early; on the emulated clock (ce64cb0e, 14z-197, #228)
# the same rig crashed elsewhere (CRASH 20100 vec3 PC 01afb6, an ordinary crash) and this gate's firing line, printed
# whenever the rig's files existed, still claimed the tripwire. Measured 14z-227 on the Mac (build/agent227/rt/, local):
# at HEAD with INSTR_CLOCK=frame_done, CRASH 14767 vec4 PC 0fb6e0; on the emulated clock with the replay and the picks
# moved 1 frame earlier, CRASH 14765 vec4 PC 0fb6e0 (2 earlier: a vec3 at 9194; 3 or 4: END clean); bisected to
# ce64cb0e (its parent 4980bd96 gives vec4 14767, as do the five other commits sampled back to 79dc2d03, 2026-09-22,
# around the window's earlier changes to the rig's tracked inputs). The shift is built at run time from
# the committed replay (kc_replay), never committed as a second copy. Both the plain run's control and the mode judge
# the leg's crash by build/hui41's own patch notes: only the row naming unresolved 0x494de counts.
# SHARES: none — one control mode, so no two of its own jobs to keep apart, and its plain run always pooled (#370 A1, 14z-225)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
# THE 14z-93 CRASH RIG (#373): build/hui41, 26_don_arcade_mash with P1 forced to 0x10 over the late pick frames, the
# replay and the picks KC_SHIFT frames earlier than written (the header's RE-TIMED paragraph). One rig for the plain
# run's control and the mode.
KC_SHIFT=1
KC_PICKS=""; for _pf in 1704 1760 1900 2100 2400; do KC_PICKS="${KC_PICKS:+$KC_PICKS }$((_pf - KC_SHIFT))"; done
KC_WANT='TRIPWIRE for unresolved 0x494de$'   # the hui41 patch-notes row of the 14z-93 crash's PC, as the soak prints it
kc_present() { [ -f "$REPO/build/hui41/rompath/vsavjw.zip" ] && [ -f "$REPO/tests/replays/26_don_arcade_mash.rpl" ]; }
kc_replay() {  # kc_replay <out>: the committed replay, every frame KC_SHIFT earlier (a range ending below 1 dropped)
    awk -v k="$KC_SHIFT" '
        match($0, /^[0-9]+(-[0-9]+)?[ \t]/) {
            n = split(substr($0, 1, RLENGTH - 1), p, "-"); a = p[1] - k; b = (n > 1 ? p[2] : p[1]) - k
            if (b < 1) next
            if (a < 1) a = 1
            print a "-" b substr($0, RLENGTH); next }
        { print }' "$REPO/tests/replays/26_don_arcade_mash.rpl" > "$1"
}
# THE EXECUTABLE MODE: the soak runs only the rig, so a vec4 tripwire fires and the gate FAILs; HONOURED only on the
# tripwire's own line (vs_ctl_caught below). REFUSE if the rig's prerequisites are absent (a SKIP under a mode would
# read as LIES).
if [ "$MODE" = known-crash ]; then
    kc_present || { echo "REFUSED: CONTROL=known-crash needs build/hui41 and 26_don_arcade_mash.rpl (absent on this host)"; exit 3; }
    BUILD=build/hui41; ONLY=26_don_arcade_mash; LEGS=10; PICK_FRAMES="$KC_PICKS"
fi
BUILD="${BUILD:-build/m3b_merged34}"  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
if [ -z "${JOBS:-}" ]; then   # min(8, CPUs/3), at least 1 (#321)
    _np="$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 3)"
    JOBS=$(( _np / 3 )); [ "$JOBS" -le 8 ] || JOBS=8; [ "$JOBS" -ge 1 ] || JOBS=1
fi
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

if [ "$MODE" = known-crash ]; then
    kc_replay "$W/26_don_arcade_mash.rpl"; set -- "$W/26_don_arcade_mash.rpl"   # the re-timed copy (#373)
else
    set -- tests/replays/*.rpl
fi
[ -e "$1" ] || { echo "FAIL: no replays"; exit 1; }
: > "$W/main.log"   # the main check's findings (the FAIL and attribution lines), read by vs_ctl_caught
say() { printf '%s\n' "$1" | tee -a "$W/main.log"; }

pool=0
sync_pool() { pool=$((pool+1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi; }

echo "== guard soak: $BUILD, legs [$LEGS], JOBS=$JOBS =="
n=0
for rpl in "$@"; do
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
[ "$n" -gt 0 ] || { vs_ctl_nj "nothing ran (bad ONLY filter?)"; echo "FAIL: nothing ran (bad ONLY filter?)"; exit 1; }   # #310 g7 NJ

fail=0
ok=0
printf "replay\tleg\tverdict\n" > "$MAP"
for d in "$W"/*/; do
    tag="$(basename "$d")"
    stem="${tag%__*}"; leg="${tag##*__}"
    log="$d/g.log"
    if [ ! -f "$log" ] || ! grep -qE "^(END |CRASH |END-CRASH |PCWEEDS |SOFTRESET )" "$log"; then
        vs_ctl_nj "leg $tag has no verdict line (DEAD; not a measurement)"   # #310 g7 NJ
        echo "  DEAD: $tag — no verdict line; not a measurement"
        printf "%s\t%s\tDEAD\n" "$stem" "$leg" >> "$MAP"
        fail=1; continue
    fi
    if grep -qE "^(CRASH |END-CRASH |PCWEEDS |SOFTRESET )" "$log"; then
        line="$(grep -m1 -E '^(CRASH |END-CRASH |PCWEEDS |SOFTRESET )' "$log")"
        printf "%s\t%s\t%s\n" "$stem" "$leg" "$line" >> "$MAP"
        say "  FAIL: $tag — $line"
        pc="$(printf '%s' "$line" | sed -n 's/.*PC \([0-9a-f]*\).*/\1/p')"
        if [ -n "$pc" ]; then
            who="$(grep -i "0x0*$pc ILLEGAL  TRIPWIRE" \
                   "$BUILD/patch/patch_notes_fragment.md" 2>/dev/null | head -1)"
            [ -n "$who" ] && say "        $who" \
                          && say "        => an UNRECONCILED reference is reachable; resolve the row." \
                          || say "        (not a planted tripwire — an ordinary crash, the worse finding)"
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
kc_dead=0
if [ -n "$MODE" ]; then
    # #369/#373: the mode is honoured only on the 14z-93 tripwire's own attribution line in the soak's findings
    [ "$fail" = 0 ] || vs_ctl_caught "$W/main.log" "$KC_WANT" || :
    [ "$fail" != 0 ] || vs_ctl_left_green known-crash "PASS: the 14z-93 rig ran END-clean — no tripwire reproduced"
elif kc_present; then
    # THE IN-GATE CONTROL (#373): run the rig's one leg (~25 s) and fire only on the tripwire it must reproduce. Until
    # 14z-227 this line was printed whenever the rig's two files existed, and claimed the tripwire it no longer reached.
    mkdir -p "$W/kc/sb"; kc_replay "$W/kc/r.rpl"
    PK=""; for pf in $KC_PICKS; do PK="${PK:+$PK;}$pf:ff8782:10"; done
    ( POKES="$PK" MAME_ROMPATH="$(abspath build/hui41)/rompath;$ROMDIR" \
        nice -n 19 tools/run_replay_guarded.sh vsavjw "$W/kc/r.rpl" "$W/kc/g.log" "$W/kc/sb" >/dev/null 2>&1 || true )
    kl="$(grep -m1 -E '^(END |CRASH |END-CRASH |PCWEEDS |SOFTRESET )' "$W/kc/g.log" 2>/dev/null || true)"
    kpc="$(printf '%s' "$kl" | sed -n 's/^CRASH .*PC \([0-9a-f]*\).*/\1/p')"
    kwho=""; [ -z "$kpc" ] || kwho="$(grep -i "0x0*$kpc ILLEGAL  TRIPWIRE" build/hui41/patch/patch_notes_fragment.md 2>/dev/null | head -1)"
    if printf '%s\n' "$kwho" | grep -qE "$KC_WANT"; then
        vs_ctl_fired known-crash "the 14z-93 crash rig (build/hui41 + 26_don_arcade_mash, re-timed for the emulated clock) reproduced '$kl', build/hui41's '$(printf '%s' "$kwho" | sed 's/^[[:space:]]*//')'"
    else
        vs_ctl_dead known-crash "the 14z-93 crash rig ran and gave '${kl:-no verdict line}', not the vec4 tripwire for unresolved 0x494de (#373)" || kc_dead=1
    fi
else
    echo "CONTROL DEAD: known-crash — the crash rig (build/hui41 + 26_don_arcade_mash) is absent, so the control cannot run"
fi
if [ "$kc_dead" = 1 ]; then
    echo "FAIL: the known-crash control is DEAD (above) — the guard's ground truth is not shown on this run."; fail=1
fi
if [ "$fail" = 0 ]; then
    echo "PASS: $n guarded runs, zero vectors — the whole corpus is guard-clean"
    echo "      on $BUILD under every tenant forcing. Rig-bounded, as always."
else
    [ "$kc_dead" = 1 ] && [ "$ok" = "$n" ] || echo "FAIL: a guarded leg produced a vector or died. Rule 6."
fi
exit "$fail"
