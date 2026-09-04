#!/bin/sh
# test_dualtrack.sh — the two tracks must differ ONLY where they are meant to.
#
# The dual-track decision (14z-59g) keeps a stock-size build alongside the
# CPS-2 WIDE roster build. That is only coherent if the WIDE build is a
# SUPERSET of the stock one: same ENGINE, and the content the extension made
# possible on top.
#
# "Same legacy BEHAVIOUR" is NOT the test, and saying so was this file's
# central mistake for 11 days (re-scoped 14z-94, maintainer-ratified
# 2026-08-17, GitHub #95). The stock build can only carry Donovan by
# SUBSTITUTING him over a legacy character — that is the whole reason the
# WIDE profile exists — so the two tracks have different rosters and their
# behaviour must diverge the moment a roster surface is on screen. What the
# superset claim actually rests on is: identical everywhere the roster is not
# yet involved, and past that, differences that are DATA fed to the same
# engine code rather than a different code path. Sections 1 and 4.
#
# This gate establishes that directly, as a live A/B between the two builds
# — no frozen expectations involved, so it is machine-independent and needs
# no freeze decision:
#
#   1. LEGACY IDENTICAL UP TO SELECT ENTRY.
#      **RE-SCOPED 14z-94, MAINTAINER-RATIFIED 2026-08-17 (GitHub #95):
#      "agreed this is why wide exists and now that it exists we must take
#      it into account."**
#
#      **RETRACTED 14z-94 (GitHub #95): this said "the WIDE build must be
#      bit-identical to the stock build" on legacy replays, full stop.**
#      That was true at 14z-59g and the project deliberately made it false
#      at 14z-64 (the M3a de-substitution, maintainer-ratified). The two
#      builds now have DIFFERENT ROSTERS BY CONSTRUCTION —
#
#          build/m5_stock   patch/tenant.json  id 15 (0x0F), mirror_variant
#                           true  -> Donovan SUBSTITUTED over Jedah
#          build/m5_wide    patch/tenant.json  id 19 (0x13), mirror_variant
#                           false -> Donovan native, JEDAH RESTORED
#
#      — so every replay that reaches the character-select screen must
#      differ there. Measured over all 11 legacy replays: 10 diverge, and
#      every onset is a select-entry frame (890, or 3190 for the one that
#      starts mid-attract); `06_test_mode`, which never reaches select, is
#      bit-identical for its whole 3,120 frames.
#
#      WHAT SURVIVES, and is what section 1 now asserts: everything BEFORE
#      select entry — boot, attract, engine init — must still be
#      bit-identical, and the onset frame is frozen per replay. That keeps
#      the original claim exactly where it is still true, and it is
#      falsifiable: an onset moving EARLIER means the profile reached
#      something it must not.
#
#      NOT A WEAKENING, and the ruling turned on this: full cross-track
#      bit-identity is UNACHIEVABLE BY CONSTRUCTION, not merely stale. A
#      stock-size ROM can hold Donovan only by substituting over someone —
#      that is the reason the WIDE profile exists at all. So there is no
#      version of this gate that could assert the old claim against a
#      correctly-built pair.
#
#      Note the frozen onsets are the same constants CLAUDE.md §4 v3
#      ratifies for the bounded re-convergent window class, which is
#      independent corroboration that this is select entry.
#
#   2. PATCHED-SLOT CONTENT DIFFERS, AND THE DIFFERENCE IS ATTRIBUTED. On
#      Donovan replays the two MUST diverge — the sfx helper is live on WIDE
#      and stubbed on stock. Identical here would mean the WIDE build
#      carries content that does nothing: the vacuous-relocation trap (B4)
#      in yet another hat.
#
#      01_attract_long belongs in THIS group, not group 1: the attract demo
#      features the patched slot, which is why the stock build already
#      carries `diverge vsavj/masked 4278` for it.
#
#   3. THE DIFFERENCE STARTS IN SOUND, AND IS DATA, NOT CONTROL FLOW.
#      Section 3 attributes the ONSET, measured 14z-94 (GitHub #95).
#
#      **RETRACTED 14z-94: this block used to say "Measured 14z-59j, its
#      stock-vs-WIDE difference is 57 bytes ... ZERO bytes of gameplay
#      state", and section 3 asserted that at a fixed frame 4400.** That
#      expectation was measured before 14z-86's M5 voice block enlarged
#      what the WIDE track's sound side does, and it has been false since.
#      Re-measured: the tracks are BIT-IDENTICAL through frame 4266, and
#      after the onset the divergence GROWS — 3 bytes at 4267, then 84,
#      260, 538, 759 at 4270/4280/4300/4400. A late fixed frame therefore
#      measures accumulated propagation, which is unbounded by design and
#      says nothing about correctness.
#
#      WHY IT PROPAGATES, and why that is not a defect: `ram.md:89` records
#      the arcade-ladder in-use mask `$FF8110.l` as SOUND-STATE-FED — "the
#      run-to-run lottery". Once the live sfx helper makes the sound state
#      differ, the attract demo's own selection differs, and the whole
#      machine follows. That is the documented mechanism, not a leak.
#
#      SO THE ONSET IS WHAT CARRIES INFORMATION, and it is tight:
#        * first divergent frame 4267, frozen;
#        * every differing byte in $FF87A4-$FF87A7 — the P1 effect-channel
#          record pointer (`ram.md:192`, the +0x3n0 per-fighter sub-structs);
#        * stock writes 0x000CEAF0 there, WIDE writes 0x00390CA0 — the
#          ported effect record, which is exactly the content the extension
#          exists to carry;
#        * and the WRITER IS THE SAME on both legs, `PRG:0x01C186`, with
#          identical write counts and PC distribution. That is the load-
#          bearing assertion: same code, different DATA. A WIDE build that
#          had taken a different BRANCH would show a different writer set,
#          and that is what would mean the profile leaked into engine flow.
#
# Usage: ROMDIR=... tests/test_dualtrack.sh [stock_rompath] [wide_rompath]
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   dual-track. RE-SCOPED 14z-94, MAINTAINER- RATIFIED 2026-08-17 (GitHub
#   #95): this row said "WIDE is legacy-IDENTICAL to stock", which 14z-64's
#   M3a de-substitution made false — the two builds carry DIFFERENT ROSTERS by
#   construction (m5_stock puts Donovan at 0x0F over Jedah; m5_wide restores
#   Jedah and takes native 0x13), so every select-reaching replay must differ.
#   Now: bit-identical UP TO select entry with the onset frozen per replay
#   (890, 3190 for the mid-attract one, none for 06_test_mode); patched-slot
#   content differs; and the attract divergence is attributed at its ONSET
#   (frame 4267, 3 bytes in the P1 effect-channel record pointer) with the
#   SAME writer PC on both legs — data, not control flow. NOT in any runner
#   (#30): that is how it stayed red 11 days
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
STOCK="${1:-$REPO/build/m5_stock15/rompath}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
WIDE="${2:-$REPO/build/don_m20/rompath}"    # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$STOCK/vsavj.zip"  ] || { echo "no stock build at $STOCK";  exit 1; }
[ -f "$WIDE/vsavjw.zip" ] || { echo "no WIDE build at $WIDE";     exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# FROZEN SELECT-ENTRY ONSETS (14z-94, GitHub #95). `none` = never reaches the
# select screen and must be bit-identical for its whole length. See the header
# for why this replaced a blanket bit-identity requirement. The two values are
# the SAME select-entry constants CLAUDE.md §4 v3 ratifies for the bounded
# re-convergent window class — 890, and 3190 for the one replay that starts
# mid-attract — which is independent corroboration that what is being measured
# here is select entry and not something else.
LEGACY_ONSETS="02_demitri_vs_cpu:890 03_two_player_vs:890 04_select_fuzz:890 \
05_timeout_idle:890 06_test_mode:none 07_mash_storm:890 08_challenger_join:890 \
09_mirror_pick:890 10_midattract_start:3190 29_felicia_walljump:890 \
30_demitri_throw:890"
DONOVAN="01_attract_long 12_donovan_vs_cpu 19_don_dp_spam 25_don_darkforce 56_don_es_ls"

run() {  # run <tag> <set> <rompath> <replay>
    FBNEO_ROMPATH="$3" tools/run_replay_fbneo.sh "$2" \
        "$REPO/tests/replays/$4.rpl" "$WORK/$1.log" "$WORK/sb_$1" >/dev/null 2>&1
}

echo "== 1. LEGACY must be identical UP TO select entry =="
for spec in $LEGACY_ONSETS; do
    rp="${spec%%:*}"; want="${spec##*:}"
    run "s_$rp" vsavj  "$STOCK" "$rp"
    run "w_$rp" vsavjw "$WIDE"  "$rp"
    got=$(diff "$WORK/s_$rp.log" "$WORK/w_$rp.log" | awk '/^< [0-9]/{print $2; exit}')
    [ -z "$got" ] && got=none
    if [ "$got" = "$want" ]; then
        if [ "$want" = none ]; then
            echo "  ok: $rp identical throughout (never reaches select)"
        else
            echo "  ok: $rp identical through frame $((want - 1)); diverges at $want"
        fi
    elif [ "$want" = none ]; then
        echo "  FAIL: $rp now diverges at frame $got — it reached select where it"
        echo "        never did, or the profile touched pre-select behaviour"
        fail=1
    elif [ "$got" = none ]; then
        echo "  FAIL: $rp is now IDENTICAL where it diverged at $want. The two"
        echo "        tracks are supposed to have DIFFERENT rosters; identical"
        echo "        here means one of the builds is not what it claims to be"
        fail=1
    else
        echo "  FAIL: $rp onset moved $want -> $got. Anything before select"
        echo "        entry is boot/attract/engine init, where the WIDE profile"
        echo "        must not reach. Root-cause it; do not re-freeze."
        fail=1
    fi
done

echo "== 2. patched-slot content must differ (else it does nothing) =="
for rp in $DONOVAN; do
    run "sd_$rp" vsavj  "$STOCK" "$rp"
    run "wd_$rp" vsavjw "$WIDE"  "$rp"
    if cmp -s "$WORK/sd_$rp.log" "$WORK/wd_$rp.log"; then
        echo "  FAIL: $rp identical — the live sfx helper changes NOTHING"
        fail=1
    else
        fr=$(diff "$WORK/sd_$rp.log" "$WORK/wd_$rp.log" | awk '/^< [0-9]/{print $2; exit}')
        echo "  ok: $rp diverges from frame $fr (sfx helper live on WIDE)"
    fi
done

# The frozen onset expectation (14z-94, GitHub #95). See the header for why
# this replaced a fixed late frame. Growth in ONSET or WINDOW means stop and
# root-cause, exactly as the CLAUDE.md §4 standing watch requires — do NOT
# widen either to make this pass.
ONSET_EXPECT=4267
ONSET_WINDOW_LO=0x87A4
ONSET_WINDOW_HI=0x87A7

echo "== 3. the attract divergence must START in the effect channel =="
# The onset comes from the per-frame checksums section 2 already produced, so
# no extra emulator run is needed to find it.
onset=$(diff "$WORK/sd_01_attract_long.log" "$WORK/wd_01_attract_long.log" \
        | awk '/^< [0-9]/{print $2; exit}')
if [ -z "$onset" ]; then
    echo "  FAIL: the two tracks never diverge on 01_attract_long — section 2"
    echo "        should already have caught that"
    fail=1
elif [ "$onset" != "$ONSET_EXPECT" ]; then
    echo "  FAIL: onset moved to frame $onset (frozen: $ONSET_EXPECT)."
    echo "        The frame the live sfx helper first perturbs state is a"
    echo "        measured constant; a move means the helper fires elsewhere."
    fail=1
else
    echo "  ok: onset at frame $onset (frozen)"
fi

if [ -n "$onset" ]; then
    FBNEO_DUMPS="$onset:ff0000-ffffff" FBNEO_ROMPATH="$STOCK" \
        tools/run_replay_fbneo.sh vsavj "$REPO/tests/replays/01_attract_long.rpl" \
        "$WORK/on_s.log" "$WORK/sb_on_s" >/dev/null 2>&1
    FBNEO_DUMPS="$onset:ff0000-ffffff" FBNEO_ROMPATH="$WIDE" \
        tools/run_replay_fbneo.sh vsavjw "$REPO/tests/replays/01_attract_long.rpl" \
        "$WORK/on_w.log" "$WORK/sb_on_w" >/dev/null 2>&1
    python3 - "$WORK" "$onset" "$ONSET_WINDOW_LO" "$ONSET_WINDOW_HI" <<'PY' || fail=1
import sys
W, fr, lo, hi = sys.argv[1], int(sys.argv[2]), int(sys.argv[3], 16), int(sys.argv[4], 16)
try:
    a = open(f"{W}/on_s.log.dump_{fr}_ff0000.bin", "rb").read()
    b = open(f"{W}/on_w.log.dump_{fr}_ff0000.bin", "rb").read()
except FileNotFoundError as e:
    print(f"  FAIL: onset dump missing ({e})"); sys.exit(1)
d = [i for i in range(min(len(a), len(b))) if a[i] != b[i]]
if not d:
    print(f"  FAIL: the dumps at the onset frame are IDENTICAL, so this"
          f"        section is not measuring the divergence it named")
    sys.exit(1)
stray = [i for i in d if not (lo <= i <= hi)]
print(f"  {len(d)} byte(s) differ at the onset: "
      + ", ".join(f"$FF{i:04X} {a[i]:02x}->{b[i]:02x}" for i in d))
if stray:
    print(f"  FAIL: {len(stray)} byte(s) OUTSIDE the effect-channel pointer"
          f" $FF{lo:04X}-$FF{hi:04X}: " + ", ".join(f"$FF{i:04X}" for i in stray[:8]))
    print( "        The divergence no longer STARTS in the effect channel."
           " Identify what")
    print( "        moved (docs/game/atlas/ram.md) before touching this window"
           " — widening it")
    print( "        is how a real engine-flow leak would get absorbed.")
    sys.exit(1)
sw = int.from_bytes(a[lo:hi+1].rjust(4, b"\0"), "big")
ww = int.from_bytes(b[lo:hi+1].rjust(4, b"\0"), "big")
print(f"  ok: all inside the P1 effect-channel record pointer "
      f"(stock {sw:#08x} -> WIDE {ww:#08x})")
PY
fi

echo "== 4. and it must be DATA, not a different code path =="
# The load-bearing check. Same writer PC on both legs means the WIDE build
# ran the SAME engine code and fed it a different record; a different writer
# set would mean the profile changed engine control flow, which is what
# Rule 1 exists to prevent.
FBNEO_HTAP="ff87a4-ff87a7" FBNEO_HTAP_OUT="$WORK/s.tap" FBNEO_ROMPATH="$STOCK" \
    tools/run_replay_fbneo.sh vsavj "$REPO/tests/replays/01_attract_long.rpl" \
    "$WORK/tp_s.log" "$WORK/sb_tp_s" >/dev/null 2>&1
FBNEO_HTAP="ff87a4-ff87a7" FBNEO_HTAP_OUT="$WORK/w.tap" FBNEO_ROMPATH="$WIDE" \
    tools/run_replay_fbneo.sh vsavjw "$REPO/tests/replays/01_attract_long.rpl" \
    "$WORK/tp_w.log" "$WORK/sb_tp_w" >/dev/null 2>&1
if [ ! -s "$WORK/s.tap" ] || [ ! -s "$WORK/w.tap" ]; then
    echo "  FAIL: the write tap produced nothing — a dead instrument, not a"
    echo "        clean result (FBNEO_HTAP)"
    fail=1
else
    # Only the pc= lines: the tap file carries a header and an "END <n>"
    # trailer, and counting those as writers made the comparison noisy.
    pcs_s=$(awk '/pc=/{print $NF}' "$WORK/s.tap" | sort | uniq -c | sort -k2 | tr -s ' ')
    pcs_w=$(awk '/pc=/{print $NF}' "$WORK/w.tap" | sort | uniq -c | sort -k2 | tr -s ' ')
    if [ "$pcs_s" = "$pcs_w" ]; then
        echo "  ok: identical writer set and counts on both legs —"
        printf '%s\n' "$pcs_s" | sed 's/^ */      /'
        echo "      same engine code, different record: a DATA difference"
    else
        echo "  FAIL: the two tracks write $FF87A4-A7 from DIFFERENT code."
        echo "        That is engine control flow diverging, not content:"
        printf '%s\n' "$pcs_s" > "$WORK/pcs_s.txt"
        printf '%s\n' "$pcs_w" > "$WORK/pcs_w.txt"
        diff "$WORK/pcs_s.txt" "$WORK/pcs_w.txt" | sed 's/^/          /'
        fail=1
    fi
fi

echo
[ "$fail" = 0 ] || { echo "FAIL: dual-track gate"; exit 1; }
echo "PASS: dual-track — the two tracks are bit-identical up to select entry"
echo "      (frozen onsets), and past it they differ only as their DIFFERENT"
echo "      ROSTERS require; the attract divergence starts in the effect"
echo "      channel and is written by the SAME engine code on both legs."
