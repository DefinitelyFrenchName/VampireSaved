#!/bin/sh
# audit_flicker_attribution.sh — WHY is each of these flicker frames in a
# frozen expectation? Re-derives the attribution instead of trusting the
# commit message that first made it.
#
# WHAT: why each flicker frame of the frozen composite expectations is there: every
#   differing byte at the attributed frames (37_victor_ko +7168,
#   105_legacy_2pwin_auto +2713/+5868, and +2093 of 03_two_player_vs and the five #118 replays whose
#   merged-m23 spec carries it) falls inside a NAMED window — the palette-fade
#   staging buffer rows or the OBJ-builder secondary stack — re-derived rather than trusted
#   from the commit that first wrote it.
# HOW: ours-vs-vanilla work-RAM dumps at the attributed frames on MAME, every differing byte
#   classified by tools/attribute_ramdiff.py against the named windows. Each CASE runs on its own fresh sandbox, and
#   its vanilla leg must equal the frozen vanilla basis log (tests/expected/vsavj/masked-v2) at the case's frame, so the
#   attribution is of the run the expectation describes (#293, 14z-205: the two 105 cases shared a sandbox, and the
#   f5868 case booted on the f2713 run's nvram).
# EXPECTS: every byte inside its window; a byte outside means the specs describe something
#   else and must be re-opened, never widened; a vanilla leg off the frozen basis is a FAIL (a carried sandbox).
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/ tests/lua/replay.lua
#   tests/replays/ tools/attribute_ramdiff.py tools/build_fingerprint.py tools/run_mame.sh
#   tools/run_replay_mame.sh tools/setup_mame.sh tests/lib/controls.sh tests/lib/sheet.sh
#
# SHEET: legs vsavj,ours — moments: each frozen flicker frame the gate re-attributes (replay and frame from its CASES), on pristine vsavj and the merged build — not comparable: the named windows (the ratified mask and the staging rows the case names), where the two legs differ by attribution
# MUST-FIRE: perturbed-copy: shared-sandbox — the cases share one sandbox per REPLAY (the pre-#293 rig), so 105's f5868 case boots on the f2713 run's nvram and its vanilla leg must fail the frozen-basis check (in-gate: the check run on the merged leg's log, a run that is not the frozen vanilla one, must refuse it; mode: the shared sandboxes and the gate FAILs)
# MUST-FIRE: perturbed-copy: wrong-window — every case expects `qsound-handshake-latch`, a window none of the cases' bytes reach, so the count-aware check must FAIL each case (mode: the real cases with that expectation)
#
# WHY (14z-91). The legacy-regression fix re-measured 139 specs, and two of
# them GAINED a flicker frame:
#
#   donovan-m7/41_don_altcolor_vsavj  +2313
#   donovan-m7/37_victor_ko_vsavj     +7168
#
# A gained frame is a claim about the build, and the rule this session
# worked to was that one is not written into a spec until it is attributed.
# Both attributed to the palette-fade STAGING BUFFER — the family at
# $FF3F02 + row*0x20, which docs/game/engine_internals.md ("The palette-fade
# staging buffer") records as display-only and transient because the
# destination venue's palette overwrites the staged rows. 41 lands in row
# 0x0C, which build/manifest/donovan.toml:862 documents this build patching
# (the P1 weapon-row march); 37 lands in row 0x0A.
#
# THAT ATTRIBUTION IS NOW LOAD-BEARING: it is the reason two `composite`
# specs carry a flicker frame rather than being root-caused. So it is a
# rerunnable measurement, not a sentence in a log. If the differing bytes
# ever move OUTSIDE the named windows, the specs are describing something
# else and must be re-opened.
#
# EXTENDED 14z-128 with the two frames of `105_legacy_2pwin_auto`, the replay
# the emulator-tier sweep found sitting in the corpus FIVE SESSIONS with no
# expectation at all. Its spec is `composite ... 2713,5868 889-2491`, so both
# frames are load-bearing in exactly the sense above, and both were attributed
# by an ours-vs-vanilla dump diff before the spec was authored:
#   +2713 -> 4 bytes at $FF408E-$FF4091 = staging row 0x0C, the window this
#            gate ALREADY names and already enforces on 41 (same window, same
#            byte count) — so it is not a new mechanism, it is this one.
#   +5868 -> 3 bytes at $FF06D8-$FF06D9 and $FF06E1 = the OBJ-BUILDER
#            SECONDARY STACK, `docs/game/atlas/ram.md`'s $FF06D0-$FF06EF row:
#            execution POSITION, not state, one bsr further along, identical
#            the next frame. That window had no NAME here, which is why one
#            was added (`obj-builder-stack`) rather than the frame being
#            waved through. It is disjoint from `dead-stack` ($FF7F00-$FF7FFF)
#            and cannot reclassify a byte in the two older cases.
# Cost: 105 is 9,620 frames, so the gate goes from seconds to a few minutes.
#
# EXTENDED 14z-198 with frame 2093, the flicker 03_two_player_vs has carried
# since the first masked basis: the merged-m23 re-release's audit_legacy_pairings
# found the #118 replays (landed after the freeze, all built on 03) with no
# expectation, and five of their eight specs carry +2093. Dump-diffed at 2093
# on merged-m23 before the specs were written: 03, 118_sel_b1 (03's inputs
# verbatim), 118_chain, 118_input_sweep and 118_sel_b3 -> 8 bytes in staging row 0x0C (plus masked dead-stack bytes),
# 118_sel_b2 -> 4 bytes there; 118_sel_b4, whose spec is window-only, differs
# only in the masked dead stack. Staging row 0x0C again — not a new mechanism.
# FIXED IN THE SAME CHANGE: the "is $want among the windows hit" test was
# `grep -q "$want"` over a summary line that names EVERY window with its count,
# so it could not fail; it now demands a non-zero count in $want (control
# `wrong-window`). Corrected, it showed 41_don_altcolor_vsavj +2313 had nothing
# in staging row 0x0C — its differing bytes are the masked dead stack only — and
# merged-m23 specifies 41 as `window vsavj/masked-v2 889 2091`, with no 2313: the
# case asserted a donovan-m7 frame the build under test no longer flickers on,
# so it is retired rather than kept green by the vacuous match.
#
# THE WINDOWS ARE NAMED, WHICH IS THE POINT. "The two builds differ, and
# that's expected" is the absence of a verdict. Every differing byte must
# fall in a window someone can name, and tools/attribute_ramdiff.py prints
# the strays when one does not.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged31] \
#          tests/audit_flicker_attribution.sh
# ~3 min (4 MAME runs, 2 legs x 2 replays).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-91: WHY is each gained flicker frame in a frozen spec? The legacy re-
#   freeze added exactly two (donovan-m7 41 +2313, 37 +7168) and the rule was
#   that a gained frame is not written until it is attributed. Both are the
#   palette-fade STAGING BUFFER ($FF3F02 + row*0x20, display- only per
#   engine_internals): 41 in row 0x0C, which donovan.toml:862 documents this
#   build patching, and 37 in row 0x0A. Re-derives it via
#   tools/attribute_ramdiff.py against NAMED windows, so a byte landing
#   outside one re-opens the specs rather than widening a window. Also fails
#   on an IDENTICAL pair — these frames are in the specs BECAUSE they differ,
#   so identity means the rig died, not that the build improved. ~3 min, 4
#   MAME runs
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged31}"  # re-pointed 14z-133b: MERGED (B2, maintainer-ruled; expectation set merged-m16)  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
# The mask comes from the BUILD's own expectation set, resolved through
# registry.tsv (the #96 mechanism) — 14z-103: this was pinned to
# tests/expected/donovan-m7/mask, whose set dir no longer exists, so the
# audit had been SKIPping quietly while the m10 specs still carry both
# frozen frames (41: 2313; 37: 6962,7168).
SET="$(python3 tools/build_fingerprint.py "$BUILD/rompath;$ROMDIR" --set vsavjw 2>/dev/null)" \
    || { echo "FAIL: $BUILD's fingerprint is not in tests/expected/registry.tsv"; exit 1; }
MASKF="tests/expected/$SET/mask"
[ -f "$MASKF" ] || { echo "FAIL: no $MASKF (set resolved as $SET)"; exit 1; }
MASK="$(cat "$MASKF")"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

# The named windows. The first four are the ratified mask (so they are
# invisible to the legacy comparison anyway); the last two are the staging
# rows this gate exists to pin.
WINDOWS="--window 043C-043D:qsound-handshake-latch
         --window 4182-41A2:masked-staging-row-0x14
         --window 41C2-41E2:masked-staging-row-0x16
         --window 4222-4262:masked-staging-rows-0x18-0x19
         --window 7F00-7FFF:dead-stack
         --window 4042-4061:staging-row-0x0A
         --window 4082-40A1:staging-row-0x0C
         --window 06D0-06EF:obj-builder-stack"

# frozen (replay, frame, which row it must land in)
CASES="37_victor_ko_vsavj:7168:staging-row-0x0A
       105_legacy_2pwin_auto:2713:staging-row-0x0C
       105_legacy_2pwin_auto:5868:obj-builder-stack
       03_two_player_vs:2093:staging-row-0x0C
       118_sel_b1:2093:staging-row-0x0C
       118_chain:2093:staging-row-0x0C
       118_input_sweep:2093:staging-row-0x0C
       118_sel_b2:2093:staging-row-0x0C
       118_sel_b3:2093:staging-row-0x0C"

. "$REPO/tests/lib/sheet.sh"
BASIS=tests/expected/vsavj/masked-v2
# The basis tracks its mask as MASK, upper case (git ls-files). Until 14z-206 (#291 S4-A) this read `$BASIS/mask`, which
# only a case-insensitive filesystem resolves: the gate passed on the Mac and failed on every Linux run (PILOT, ERIS).
[ -f "$BASIS/MASK" ] || { echo "FAIL: no $BASIS/MASK (the vanilla basis's tracked mask)"; exit 1; }
BASIS_MASK="$(cat "$BASIS/MASK")"
lastnew=""; lastrpl=""; lastframe=""
# fresh_ok <log> <replay> <frame>: the log's checksum at <frame> equals the frozen basis log's (the one copy of the test)
fresh_ok() {
    _a="$(awk -v f="$3" '$1 == f {print $2}' "$1")"; _b="$(awk -v f="$3" '$1 == f {print $2}' "$BASIS/logs/$2.log")"
    [ -n "$_a" ] && [ "$_a" = "$_b" ]
}
# hit_in <summary> <window>: true when attribute_ramdiff's summary counts at least one byte in <window> —
# the one copy of the count-aware test (the case verdict and the inline wrong-window control both call it)
hit_in() { printf '%s' "$1" | grep -E >/dev/null "[;,] [1-9][0-9]* $2(,|\$)"; }

for c in $CASES; do
    rpl="${c%%:*}"; rest="${c#*:}"; frame="${rest%%:*}"; want="${rest##*:}"
    if vs_ctl_is wrong-window; then want=qsound-handshake-latch; fi
    echo "== $rpl frame $frame — expect the unmasked diff in $want =="
    k="$rpl.$frame"                                  # one log dir and one FRESH sandbox per case (#293)
    if vs_ctl_is shared-sandbox; then sk="$rpl"; else sk="$k"; fi
    mkdir -p "$W/van_$k" "$W/new_$k"
    DUMPS="$frame:ff0000-ffffff" MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" \
        tools/run_replay_mame.sh vsavj "tests/replays/$rpl.rpl" \
        "$W/van_$k/a.log" "$W/sbv_$sk" >/dev/null 2>&1 &
    DUMPS="$frame:ff0000-ffffff" MASK_RANGES="$MASK" \
    MAME_ROMPATH="$PWD/$BUILD/rompath;$ROMDIR" \
        tools/run_replay_mame.sh vsavjw "tests/replays/$rpl.rpl" \
        "$W/new_$k/b.log" "$W/sbn_$sk" >/dev/null 2>&1 &
    wait
    if [ ! -f "$W/van_$k/a.log" ] || [ ! -f "$W/new_$k/b.log" ]; then
        echo "  FAIL: a leg did not complete"; fail=1; continue
    fi
    # the vanilla leg IS the frozen run: its checksum at the case frame equals the basis log's (same mask) — #293
    if [ "$MASK" = "$BASIS_MASK" ]; then
        if fresh_ok "$W/van_$k/a.log" "$rpl" "$frame"; then echo "  ok: the vanilla leg equals the frozen basis at f$frame (a fresh boot)"
        else echo "  FAIL: the vanilla leg is NOT the frozen run at f$frame ($(awk -v f="$frame" '$1 == f {print $2}' "$W/van_$k/a.log") against the basis's $(awk -v f="$frame" '$1 == f {print $2}' "$BASIS/logs/$rpl.log")) — a carried sandbox, or the rig moved"; fail=1; continue; fi
        lastnew="$W/new_$k/b.log"; lastrpl="$rpl"; lastframe="$frame"
    else
        echo "  NOTE: the build's mask is not the basis mask, so the vanilla leg is not checked against the basis"
    fi
    out="$(python3 tools/attribute_ramdiff.py "$W/van_$k/a.log" \
             "$W/new_$k/b.log" "$frame" $WINDOWS 2>&1)" && st=0 || st=$?
    printf '%s\n' "$out" | sed 's/^/    /'
    # THE SHEET (#291): with SHEET_OUT set, this case's two legs, each proven on its own masked checksum log, at the
    # frame it attributes; the verdict word is the one the branch below prints. Nothing decided changes.
    if sheet_on && [ -z "${VS_CTL:-}" ]; then
        if [ "$st" != 0 ]; then _sv="DIFF outside every named window"
        elif printf '%s' "$out" | grep -i >/dev/null "identical\|0 differing"; then _sv="identical (the rig no longer reproduces it)"
        elif hit_in "$out" "$want"; then _sv="attributed to $want"
        else _sv="nothing in $want"; fi
        sheet_new "$rpl.$frame" "$rpl f$frame: a frozen flicker frame, pristine vsavj above the merged build" - - \
            "the named windows (the ratified mask and the staging rows the case names), where the two legs differ by attribution"
        sheet_leg "$rpl.$frame" vanilla vsavj vsavj "$ROMDIR" "$REPO/tests/replays/$rpl.rpl" - "$((frame + 1))" "$W/van_$k/a.log" "$MASK"
        sheet_leg "$rpl.$frame" merged ours vsavjw "$PWD/$BUILD/rompath;$ROMDIR" "$REPO/tests/replays/$rpl.rpl" - "$((frame + 1))" "$W/new_$k/b.log" "$MASK"
        sheet_moment "$rpl.$frame" "f$frame" "f$frame, expected in $want" "$_sv" \
            "$(printf '%s' "$out" | tail -1 | tr '\t' ' ' | cut -c1-300)"
        sheet_at "$rpl.$frame" "f$frame" vanilla "$frame" log
        sheet_at "$rpl.$frame" "f$frame" merged "$frame" log
        # S4-D (#291): the flicker frame in context, the 8 frames before it and the frame itself (the legs stop at
        # f+1), each proven on the leg's own masked log
        sheet_span "$rpl.$frame" "f$frame" vanilla "$((frame - 8))-$frame"
        sheet_span "$rpl.$frame" "f$frame" merged "$((frame - 8))-$frame"
    fi
    if [ "$st" != 0 ]; then
        echo "  FAIL: a differing byte fell OUTSIDE every named window."
        echo "        The frozen specs that carry this flicker frame are"
        echo "        describing something other than the staging buffer —"
        echo "        re-open them rather than widening a window."
        fail=1
        continue
    fi
    # a zero-diff would make the attribution vacuous: the frame is in the
    # spec BECAUSE it differs, so an identical pair means the rig moved.
    if printf '%s' "$out" | grep -i >/dev/null "identical\|0 differing"; then
        echo "  FAIL: the two legs are identical at f$frame — this frame is a"
        echo "        frozen flicker frame, so an identical pair means the rig"
        echo "        no longer reproduces it, not that the build improved."
        fail=1
        continue
    fi
    if hit_in "$out" "$want"; then
        echo "  ok: attributed, and $want is among the windows hit"
    else
        echo "  FAIL: nothing landed in $want — the mechanism moved rows."
        fail=1
    fi
done

# THE wrong-window CONTROL, INLINE (the runner reads every declared control from every run): on the last
# real case's summary the count-aware test must say NO for qsound-handshake-latch, a window no case reaches;
# the pre-14z-198 `grep -q "$want"` would say yes, which is the vacuity this control exists to catch.
if ! vs_ctl_is wrong-window && [ -n "${out:-}" ]; then
    if hit_in "$out" qsound-handshake-latch; then vs_ctl_dead wrong-window "the window test said yes for qsound-handshake-latch on $rpl f$frame, which no byte reached" || fail=1
    else vs_ctl_fired wrong-window "the window test says no for qsound-handshake-latch on $rpl f$frame"; fi
fi
# THE shared-sandbox CONTROL, INLINE: the frozen-basis check must refuse a run that is not the frozen vanilla one —
# the merged leg's log at its own flicker frame differs from vanilla by definition of that frame.
if ! vs_ctl_is shared-sandbox && [ -n "$lastnew" ]; then
    if fresh_ok "$lastnew" "$lastrpl" "$lastframe"; then vs_ctl_dead shared-sandbox "the frozen-basis check accepted the merged leg's log at $lastrpl f$lastframe" || fail=1
    else vs_ctl_fired shared-sandbox "the frozen-basis check refuses a run that is not the frozen vanilla one ($lastrpl f$lastframe, the merged leg)"; fi
fi
if vs_ctl_is shared-sandbox; then
    if [ "$fail" = 1 ]; then vs_ctl_fired shared-sandbox "with the cases sharing a sandbox per replay, a vanilla leg failed the frozen-basis check"
    else vs_ctl_dead shared-sandbox "the shared sandboxes passed — the frozen-basis check cannot see carried nvram" || fail=1; fi
fi
if vs_ctl_is wrong-window; then
    if [ "$fail" = 1 ]; then vs_ctl_fired wrong-window "every case expecting qsound-handshake-latch read nothing in it"
    else vs_ctl_dead wrong-window "a case expecting qsound-handshake-latch passed — the window check cannot fail" || fail=1; fi
fi
echo
[ "$fail" = 0 ] && echo "FLICKER ATTRIBUTION: PASS" || echo "FLICKER ATTRIBUTION: FAIL"
exit "$fail"
