#!/bin/sh
# audit_projectile_clash.sh — the pool-vs-pool projectile-contact surface
# (14z-100 hardening H4; the census gap the hitclass KEEP ruling named).
# RE-FRAMED 14z-101: the "defect signature" this audit froze at authoring
# is MEASURED NATIVE PARITY, not a defect — see GitHub #108's resolution.
#
# WHAT: the pool-vs-pool projectile-contact surface for Pyron's Cosmo satellites: they are
#   projectile-sweep-inert on our build exactly as on native vsav2 (+0x94 hit-row index 0 on
#   both), with each game's own OBJ bank word — measured native parity, not a defect (#108).
# HOW: three parallel MAME legs probing the hit-class thunk body: a Demitri-vs-Demitri flare
#   control that must show the sweep path ALIVE, the tenant rig on the build, and the same
#   rig on pristine vsav2 as the parity anchor.
# EXPECTS: the control fires (a quiet control voids everything), the tenant leg shows bank
#   word 0x1000, satellite +0x94 == 0 and zero probe fires, the native leg +0x94 == 0 and
#   bank word 0x6000. A hit-active native satellite reopens #108; EXPECT_SAT_SWEEP=1 is
#   refused. Both guarded legs on emulated time at their frozen game clocks, the staging leg on replay.lua's checksum.
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): replay_guard.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua), so the tenant leg's f3520 dump is the native leg's f3520 since 14z-197;
#   both guarded legs' game clock RAM:$FF8080 at the last frame is held to
#   tests/expected/instr_gameclock/audit_projectile_clash.tsv, frozen by `--freeze-clock` from REFERENCE legs (the
#   guard without -debug, the same POKES) each held to replay.lua run live; one STAGING reference leg (the control) is
#   held to replay.lua on every run (tests/lib/instr_align.sh).
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/instr_gameclock/ tests/lib/controls.sh
#   tests/lib/instr_align.sh tests/lua/emu_clock.lua tests/lua/replay.lua tests/lua/replay_guard.lua
#   tests/replays/105_projectile_clash_ctl.rpl tests/replays/106_pyron_cosmo_clash.rpl
#   tools/run_mame.sh tools/run_replay_guarded.sh tools/run_replay_mame.sh
#   tools/setup_mame.sh tests/lib/sheet.sh
#
# SHEET: legs vs2,ours — moments: the f3520 pool dump both legs are judged on (a Cosmo satellite's bank word and +0x94 hit-row index) — not comparable: the bank word itself, each game's own by design (0x6000 native, 0x1000 our WIDE row, #108); each game's stage, palette and P2's art
#
# MUST-FIRE: known-bad: drift-clock — a guarded leg under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 5,151 emulated frames of 5,620 counted on the control) must miss its frozen game clock (in-gate: one extra run; mode: both guarded legs run the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
#
# What 14z-101's writer hunt established (FBNEO_HTAP, both legs, whole-run):
#   - fighter/satellite +0x18 is the per-char OBJ BANK WORD (table
#     PRG:0x282D4, writer PRG:0x282C0). Ours reads 0x1000 because our own
#     obj_bank_word_slot variant row PATCHES the table (14z-62c, load-
#     bearing: WIDE group C bank 4 — 0x6000 there re-garbles tenant
#     sprites). Native's 0x6000 is vs2's own bank word. Both correct.
#   - the sweep entry gate (vsavj 0x1A734 / vs2 twin 0x19144, instruction-
#     identical) never reads +0x18. It requires +0x00==1 on both objects,
#     +0x70 (team) to DIFFER, and +0x94 (hit-row index) NONZERO ON BOTH.
#   - cosmo satellites carry +0x94 == 0 in BOTH games, refreshed to 0
#     every live frame from their own record data (ours PC 0x545DC,
#     native sibling 0x5C7BC), so they are projectile-sweep-inert
#     NATIVELY too. There is nothing to fix.
#
# THREE LEGS, probing the hitclass-map thunk body (from the build's own
# patch fragment):
#   CONTROL (105_projectile_clash_ctl): Demitri vs Demitri head-on flares.
#     The sweep path must be ALIVE — measured 468 probe fires at authoring.
#     A quiet control means the probe or the path died; nothing else in
#     this audit is a verdict then (the 87 rule).
#   TENANT (106_pyron_cosmo_clash on the build): Pyron cosmo satellites +
#     one legacy flare through the field, P1 clean of hitstun at spawn.
#     Frozen parity signature: bank word 0x1000, satellite +0x94 == 0,
#     ZERO tenant probe fires.
#   NATIVE (106 on pristine vsav2): the parity ANCHOR — vs2's own
#     satellites must show +0x94 == 0 and bank word 0x6000. If this leg
#     ever shows a hit-ACTIVE native satellite, the parity claim is dead
#     and #108 reopens — re-derive before touching anything.
#
# EXPECT_SAT_SWEEP=1 (the former "fix mode") is REFUSED: #108 resolved
# NOT-A-DEFECT, and the "fix" it described (word := 0x6000) would be a
# real regression (the 14z-62c grey-block garble) with no collision gain.
#
# ~5 min (3 MAME runs, parallel). On-demand. Usage: ROMDIR=... [BUILD=...] tests/audit_projectile_clash.sh [--freeze-clock]
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
BUILD="${BUILD:-build/m3b_merged31}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN

if [ "${EXPECT_SAT_SWEEP:-0}" != 0 ]; then
    echo "REFUSED: EXPECT_SAT_SWEEP=1 was the anticipated fix mode; #108 is"
    echo "resolved NOT-A-DEFECT (native parity, 14z-101) and word 0x6000"
    echo "would regress rendering. See the header and GitHub #108."
    exit 1
fi

BODY="$(sed -n 's/^code *0x0*\([0-9a-f]*\) .*site_thunk hitclass_map_extend.*/\1/p' \
        "$BUILD/patch/patch_notes_fragment.md" | head -1)"
[ -n "$BODY" ] || { echo "FAIL: hitclass thunk body not in the fragment"; exit 1; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mkdir -p "$W/ctl" "$W/ten" "$W/nat"
FREEZE_CLOCK=0; [ "${1:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
CLOCKS="tests/expected/instr_gameclock/audit_projectile_clash.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"
CTL_PK="1400:ff8782:01;1450:ff8782:01;1500:ff8782:01;1400:ff8b82:01;1450:ff8b82:01;1500:ff8b82:01"
TEN_PK="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;1400:ff8b82:01;1450:ff8b82:01;1500:ff8b82:01;3300:ff8509:03"
TEN_DF="3520:ff9400-ff9c00"

# shellcheck disable=SC2086
( env $_clk GUARD_PROBE="$BODY" GUARD_PROBE_MAX=20000 POKES="$CTL_PK" ALIGN_OUT="$W/ctl/align" \
  MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
  tools/run_replay_guarded.sh vsavjw tests/replays/105_projectile_clash_ctl.rpl \
  "$W/ctl/out.log" "$W/ctl/sbx" >/dev/null 2>&1 || true ) &
# shellcheck disable=SC2086
( env $_clk GUARD_PROBE="$BODY" GUARD_PROBE_MAX=20000 POKES="$TEN_PK" DUMPS="$TEN_DF" ALIGN_OUT="$W/ten/align" \
  MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
  tools/run_replay_guarded.sh vsavjw tests/replays/106_pyron_cosmo_clash.rpl \
  "$W/ten/out.log" "$W/ten/sbx" >/dev/null 2>&1 || true ) &
( POKES="$TEN_PK" DUMPS="$TEN_DF" \
  tools/run_replay_mame.sh vsav2 tests/replays/106_pyron_cosmo_clash.rpl \
  "$W/nat/out.log" "$W/nat/sbx" >/dev/null 2>&1 || true ) &
wait
fail=0
ia_note_run "$W/manifest.tsv" build 105_projectile_clash_ctl vsavjw "$REPO/$BUILD/rompath;$ROMDIR" \
    "$REPO/tests/replays/105_projectile_clash_ctl.rpl" "MAME_BIN=$MAME_BIN POKES=$CTL_PK GUARD_PROBE=$BODY GUARD_PROBE_MAX=20000" "$W/ctl/align"
ia_note_run "$W/manifest.tsv" build 106_pyron_cosmo_clash vsavjw "$REPO/$BUILD/rompath;$ROMDIR" \
    "$REPO/tests/replays/106_pyron_cosmo_clash.rpl" "MAME_BIN=$MAME_BIN POKES=$TEN_PK DUMPS=$TEN_DF GUARD_PROBE=$BODY GUARD_PROBE_MAX=20000" "$W/ten/align"

NC="$(grep -c '^PROBE' "$W/ctl/out.log" 2>/dev/null)" || true
NC="${NC:-0}"
grep -q "^END " "$W/ctl/out.log" 2>/dev/null || { echo "FAIL: control leg died"; fail=1; }
if [ "$NC" -ge 100 ]; then
    echo "   ok: control — the sweep path is ALIVE ($NC fires)"
else
    echo "FAIL: control fired only $NC times — probe or path dead; no verdicts"; exit 1
fi

NT="$(grep -c '^PROBE' "$W/ten/out.log" 2>/dev/null)" || true
NT="${NT:-0}"
grep -q "^END " "$W/ten/out.log" 2>/dev/null || { echo "FAIL: tenant leg died"; fail=1; }

# One satellite's (bank word, +0x94) from a leg's f3520 pool dump.
sat_probe() {
    python3 - "$1" <<'PY'
import sys, glob
d = sys.argv[1]
fs = glob.glob(f"{d}/dump_3520_ff9400.bin")
if not fs:
    print("NODUMP"); raise SystemExit
b = open(fs[0], "rb").read()
for s in range(8):
    sl = b[s*0x100:(s+1)*0x100]
    if sl[0] and sl[2] == 0x42:
        print(f"{sl[0x18]:02x}{sl[0x19]:02x} {sl[0x94]:02x}"); break
else:
    print("NOSAT")
PY
}

set -- $(sat_probe "$W/ten"); SAT="${1:-NOSAT}"; H94="${2:-}"
if [ "$SAT" = "NOSAT" ] || [ "$SAT" = "NODUMP" ]; then
    echo "FAIL: tenant leg produced no satellite at f3520 — rig dead ($SAT)"; fail=1
elif [ "$NT" = 0 ] && [ "$SAT" = "1000" ] && [ "$H94" = "00" ]; then
    echo "   ok(parity): satellites bank word 0x$SAT (our WIDE row), +0x94=$H94, tenant fires $NT"
else
    echo "FAIL: word 0x$SAT / +0x94=$H94 / fires $NT — the frozen #108 parity signature MOVED; re-derive"
    fail=1
fi

set -- $(sat_probe "$W/nat"); NSAT="${1:-NOSAT}"; N94="${2:-}"
grep -q "^END " "$W/nat/out.log" 2>/dev/null || { echo "FAIL: native leg died"; fail=1; }
if [ "$NSAT" = "NOSAT" ] || [ "$NSAT" = "NODUMP" ]; then
    echo "FAIL: native leg produced no satellite at f3520 — rig dead ($NSAT)"; fail=1
elif [ "$NSAT" = "6000" ] && [ "$N94" = "00" ]; then
    echo "   ok(anchor): NATIVE satellites bank word 0x$NSAT, +0x94=$N94 — vs2's own satellites are sweep-inert too"
else
    echo "FAIL: native anchor moved (word 0x$NSAT / +0x94=$N94) — the parity claim is dead; #108 reopens"
    fail=1
fi

echo "== the instrument's alignment (#228 step 4, option A)"
if [ "$FREEZE_CLOCK" = 1 ]; then
    [ "$fail" = 0 ] || { echo "REFUSED: the audit failed — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" "$W/fz" "${JOBS:-4}" "$W/clocks.tsv" \
        > "$W/fz.txt" || { sed 's/^/  /' "$W/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/audit_projectile_clash.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): build = $BUILD;"
      echo "# every reference leg held to replay.lua run live, every guarded leg to its reference leg's game clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$W/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$W/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
if ia_check_manifest "$CLOCKS" "$W/manifest.tsv" > "$W/align_bad.txt"; then
    echo "   ok: both guarded legs on emulated time, at their frozen game clocks"
else echo "FAIL: $(wc -l < "$W/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$W/align_bad.txt" | sed 's/^/        /'; fail=1; fi
ia_stage audit_projectile_clash "$CLOCKS" "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" 1 "$W/st" "$MODE" || fail=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "AUDIT FAIL (control mode: $MODE)"; exit 1; }
    echo "AUDIT FAIL — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi

# THE SHEET (#291): with SHEET_OUT set, the tenant leg and its native anchor as this run played them, and the one
# moment both are judged on, each proven on the leg's own checksum log. Nothing the gate decides changes.
. "$REPO/tests/lib/sheet.sh"
if sheet_on && [ -z "$MODE" ]; then
    if [ "$NT" = 0 ] && [ "$SAT" = 1000 ] && [ "$H94" = 00 ] && [ "$NSAT" = 6000 ] && [ "$N94" = 00 ]; then _v="IDENTICAL (sweep-inert on both)"; else _v=DIFF; fi
    sheet_new clash "Pyron's Cosmo satellites vs a flare (106_pyron_cosmo_clash): native vs2 above ours" pyron "#108" \
        "the bank word itself, each game's own by design (0x6000 native, 0x1000 our WIDE row); each game's stage, palette and P2's art"
    sheet_leg clash native vs2 vsav2 "$ROMDIR" "$REPO/tests/replays/106_pyron_cosmo_clash.rpl" "$TEN_PK" \
        "$(awk '$1 ~ /^[0-9]+$/ {n = $1} END {print n}' "$W/nat/out.log")" "$W/nat/out.log"
    sheet_leg clash ours ours vsavjw "$REPO/$BUILD/rompath;$ROMDIR" "$REPO/tests/replays/106_pyron_cosmo_clash.rpl" "$TEN_PK" \
        "$(awk '$1 ~ /^[0-9]+$/ {n = $1} END {print n}' "$W/ten/out.log")" "$W/ten/out.log"
    sheet_moment clash f3520 "f3520: a Cosmo satellite in the pool dump" "$_v" \
        "native word 0x$NSAT +0x94=$N94; ours word 0x$SAT +0x94=$H94, tenant probe fires $NT"
    sheet_at clash f3520 native 3520 log
    sheet_at clash f3520 ours 3520 log
fi

[ "$fail" = 0 ] && echo "AUDIT PASS" || { echo "AUDIT FAIL"; exit 1; }
