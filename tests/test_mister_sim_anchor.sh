#!/bin/sh
# test_mister_sim_anchor.sh — THE MiSTer LEG OF THE §4 DUAL-EMULATOR ORACLE
# (14z-107). A jtcps2 core under Verilator and MAME run the same legacy replay
# on the same stock vsavj romset; the mapped gameplay fields must agree at the
# round-1 match-start anchor and at the follow offsets.
#
# SINCE SLICE D1 THE CORE UNDER TEST IS `cps2w`, NOT `cps2`, AND THAT IS THE
# POINT (14z-107 (6)). cores/cps2w now carries RTL, and the profile it adds is
# selected at RUNTIME from a spare MRA header byte — so a STOCK vsavj MRA runs
# our RBF with `wide_en` LOW. Pointing this gate at cps2w therefore turns the
# frozen numbers below into the FPGA edition of the emulator superset
# invariant: our core, running the unmodified game, must reproduce the
# REFERENCE core's measurement. The expectations are NOT re-measured on cps2w
# — they stay the cps2 numbers, which is what makes the comparison mean
# something. `SIM_CORE=cps2` re-runs the reference leg itself.
#
# WHY IT MATTERS. CLAUDE.md §4 compares mapped state at sync anchors because
# two codebases traverse identical states on different frame indices. jtcps2
# is a THIRD implementation — Jotego's RTL — and this is the gate that turns
# the simulation lane from a demo into an oracle. It is also the answer to the
# §4 note "revisit at MiSTer: a third implementation is where MAME-specific
# behaviour would surface".
#
# COST: the sim leg boots from frame 0 every run at ~1.0 s per simulated
# frame, so this gate takes ~45 min and needs Verilator + ROMDIR. It is an
# EMULATOR-tier gate: it is NOT in ci_portable/ci_static, and HANDOFF.md
# indexes it with the other manual gates.
#
# FROZEN EXPECTATIONS (re-measured 14z-107 (7), RE-MEASURED AGAIN 14z-107 (8)
# on a run whose simulated controller is no longer pressing four buttons
# nobody scripted — see "THE SECOND RE-FREEZE" below):
#   MAME anchor              frame 2146   (05_timeout_idle, stock vsavj)
#   sim anchor (ABSOLUTE)    frame 2609   (the 462 download frames included)
#   skew (sim - MAME)        463
#
# THE SECOND RE-FREEZE, 14z-107 (8) — AND THIS TIME NOTHING MOVED, WHICH IS
# ITSELF THE RESULT. Every number above was previously measured on a lane in
# which jtframe's `SimInputs` HELD FOUR BUTTONS DOWN: `test.cpp` masked the
# joystick word with `&0xf0` and seeded `joystick1..4 = 0xff` on a `[9:0]`
# ACTIVE-LOW port, so P1's buttons 5 and 6 AND P2's were pressed from the
# first line of `sim_inputs.hex` to the last while MAME's leg held nothing.
# The two legs of this oracle were not running identical inputs — a FIDELITY
# defect in the instrument, found 14z-107 (7) and fixed in fork commit
# `519aff8b` (14z-107 (8)). Re-measured afterwards on the REFERENCE core
# (`cores/cps2`, stock `vsavj`, frame output off, frames 2100-3000 so the
# search could not be boxed in): **MAME 2146, sim 2609, skew 463 — the same
# numbers**, and the anchor is 2609 whether the search window starts at 2100
# or at 2400. So the expectations are re-frozen at their existing values,
# measured for the first time on inputs that match the MAME leg's.
# WHY IT DID NOT MOVE, mechanism rather than luck: a button held from before
# the game boots produces no PRESS EDGE, and this replay's only inputs are a
# coin, a start and one button-1 tap. The boot-phase footprint of the fix is
# 8 bytes of 65,536 in every frame of 560-620 — `RAM:$FF8058/5A/5C/5E`
# (0x60 -> 0x00, the game's own P1/P2 input mirror) and `$FF8060-$FF8063`
# — and nothing downstream of them changed at the match. Full before/after,
# including the MAME differential that located that mirror:
# docs/platform/mister.md, "`SimInputs` HELD BUTTONS 5 AND 6 DOWN".
# The band stays +/- 30 and was not touched.
#
# THE RE-FREEZE, 14z-107 (7) — AND IT INVERTS A VERDICT. The old expectation
# was sim 2502 / skew 356, and it was measured on a run in which jtframe's
# frame writer was REWINDING sim_inputs.hex (see below): every forked child's
# exit(0) fclose()d the inherited FILE* behind the parent's input stream, and
# POSIX repositions the SHARED offset, so the simulated controller was
# replayed once per fork. With the host doing nothing with the pixels
# (--frame-output off, the lane's default since fork commit 8) the same core,
# the same ROM and the same input file put the round-1 match start at
# **2609**, skew **463**. Measured four ways in one 2x2 (14z-107 (7)):
# {pal_lut.hex present, absent} x {frame output off, fork}. All three legs
# that fork ONCE OR NOT AT ALL agree on 2609; the single leg that forks
# hundreds of times — live picture, frame output on — is the one that says
# 2502. So slice D1's "RED" anchor of 2609 was the CORRECT measurement and
# the green 2502 was the artifact, which is exactly why the standing watch
# says root-cause rather than widen. The band is UNCHANGED at +/- 30; only
# the centre moved, and it moved onto a measurement with a named mechanism.
#
# HISTORICAL, kept because the eliminations still hold: the sim anchor also
# moved 2507 -> 2502 when the SDRAM model was fixed, and the
# mechanism is real rather than noise. `cores/cps1/hdl/jtcps1_obj_draw.v:137`
# is `if( &rom_data ) begin // skip blank pixels` — the object pipeline SKIPS
# its 8-pixel draw loop when the fetched GFX word is all-ones. So OBJECT
# TIMING IS A FUNCTION OF GFX ROM CONTENT. Before fork commit 3 the upper
# 8 MB of each GFX bank aliased, so the core skipped whichever tiles the
# corrupt map happened to make blank; now it skips the ones that really are.
# Different skip pattern -> different SDRAM contention -> a few frames of
# drift over 2,500. Five frames in 2,502 is 0.2%, it is inside the frozen
# band, every mapped field still agrees exactly, and the P1/P2 record bases
# are identical to the 14z-107 measurement. 361 was the value on the BROKEN
# model and is retracted, not widened: the band is still +/- 30.
# (Both 2507 and 2502 were measured with the input script being replayed;
# the object-timing mechanism above is real and independent of that, but the
# ABSOLUTE numbers in this paragraph are superseded by the re-freeze.)
#
# THE SKEW IS NOT THE BOOT OFFSET, and that is worth knowing: at the RAM-test
# onset the two are 460 frames apart (462 download frames minus a 2-frame
# lead), and by the round-1 match start they are 463 apart on a clean run —
# so the sim reaches the match ~3 frames LATER relative to its own boot. (On
# the corrupted runs it looked like ~99 frames EARLIER, which was the
# replayed input script hurrying the select screen along.) The
# attract/select/VS path still costs different numbers of frames in the two
# implementations, which is why CLAUDE.md §4 compares mapped state at ANCHORS
# and not at fixed frame indices.
#
# THE CPU OPPONENT IS A LOTTERY, AND IT IS NOT OURS TO FIX. `05_timeout_idle`
# is a 1P arcade match, and the ladder's in-use mask `RAM:$FF8110.l` is
# SOUND-STATE-FED (docs/game/atlas/ram.md:99, the run-to-run draw that cost
# GitHub #110 two frozen audits in 14z-103). Measured here: MAME drew the
# opponent whose record base is $0AE9D4, jtcps2 drew $0A9518 — P1 is Demitri
# ($093B6A) on BOTH sides, both HP are 0x120, the timer is 0x63 on both, and
# every character-independent field agrees exactly. So the fields that are a
# FUNCTION OF WHICH CHARACTER P2 IS are excluded BY NAME below; p2_hp,
# p2_white_hp and the two p2 meter fields stay compared. Pinning the opponent
# needs a 2P replay, which needs P2 SCRIPTING in the `SimInputs` harness —
# still a queued fork commit, maintainer-ruled "later"
# (docs/platform/mister.md "Open / to verify"). Note what fork commit 10 did
# and did NOT do: it stopped the harness ASSERTING P2's buttons 5 and 6, it
# did not make P2 scriptable, so this exclusion stands. Measured after the
# fix, the draw is unchanged — MAME $0AE9D4, jtcps2 $0A9518, the same pair as
# before, on the field the record calls the run-to-run lottery.
# The skew is frozen with a tolerance because it is a boot-phase property, not
# gameplay state; the FIELDS are compared exactly. A skew outside the band is
# a finding: stop and root-cause, do not widen (the standing watch).
#
# FRAME OUTPUT IS OFF, AND THE GATE ASSERTS IT (14z-107 (7)). Slice D1 found
# this gate moving 2502 -> 2609 for a reason that had nothing to do with the
# RTL, and 14z-107 (7) root-caused it: jtframe's Verilator harness forks an
# ImageMagick child per CHANGED frame, that child ended with exit(0), and
# exit() fclose()s the FILE* behind the parent's sim_inputs.hex stream —
# which POSIX makes rewind the SHARED file offset, so the parent re-read
# input lines it had already consumed. The SIMULATED CONTROLLER was being
# replayed, once per fork, and the number of forks follows the PICTURE. The
# first divergent byte was RAM:$FF8060, the per-player START bitmask, which
# is the mechanism signing its own work.
# Fork commit 9 fixes it at the root (_exit(0)); fork commit 8 adds
# JTFRAME_SIM_NOVIDEO and tools/run_sim_jtcps2.sh passes it by default, so
# the run under test does nothing with the pixels at all. Neither is a
# tolerance, so the band below was NOT widened. The mode is part of the run's
# identity and is asserted from the log — the two can never silently differ
# again. Full chain and controls: docs/platform/mister.md, "THE HARNESS'S
# FRAME WRITER CORRUPTED THE SIMULATED INPUT SCRIPT".
#
# CONTROLS (a gate without one asserts nothing):
#   * byte-swapped sim dumps must FAIL the comparison — the one mistake that
#     would otherwise fabricate a "the core disagrees with MAME" report;
#   * a sim run WITHOUT --wram must produce no wram/ at all — the harness hook
#     is inert unless asked (the emulator-superset shape, sim edition);
#   * both dump directories are asserted COMPLETE before anything is compared,
#     and a hole punched in a copy must be rejected — compare_fields.py globs,
#     so a lost dump would otherwise just move the anchor (14z-107 (7)).
#
# Usage: ROMDIR=... [JTSIM_SCRATCH=...] tests/test_mister_sim_anchor.sh
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier manual/emulator (~50 min)) THE ORACLE: MAME and the core under test
#   (`cps2w` since D1, `SIM_CORE=cps2` for the reference leg) agree on every
#   mapped §4 field at the round-1 match-start anchor of `05_timeout_idle`
#   (MAME 2146 / sim 2609, skew 463 ± 30 — RE-MEASURED 14z-107 (7) with host
#   frame output OFF. It read 2502/356 and 2507/361 on runs whose input script
#   the harness's frame writer was replaying, and 2606/460 before that, which
#   was the BOOT offset rather than the anchor). Runs with `--frame-output
#   off` and ASSERTS that mode from the run's own log banner; asserts BOTH
#   dump sets are COMPLETE (`tools/check_wram_dumps.py`) and the sim window
#   NON-CONSTANT before computing any anchor; then the byte-swap, hook-
#   inertness and punched-hole controls
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }

[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset (this gate runs the real romset)"; exit 77; }
command -v verilator >/dev/null 2>&1 || { echo "SKIP: verilator not installed (docs/platform/mister.md Recipe)"; exit 77; }
[ -f "$REPO/emu/jtcores/.gitmodules" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 77; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
command -v "$MAME_BIN" >/dev/null 2>&1 || [ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN (tools/setup_mame.sh)"; exit 77; }
export MAME_BIN

SIM_CORE="${SIM_CORE:-cps2w}"   # the core under test; the EXPECTATIONS are cps2's
RPL="$REPO/tests/replays/05_timeout_idle.rpl"
FIELDS="$REPO/tests/fields_m2a.tsv"
FOLLOW="0,60,180"
# Excluded by name, mechanism in the header: the arcade draw picked a
# different CPU opponent on each implementation, so every field that is a
# function of WHICH character P2 is would assert a disagreement.
SKIP="p2_hitbox_base,p2_ptr64,p2_word132,p2_x,p2_y,p2_attack_id,p2_flip"
EXP_AM=2146          # frozen MAME anchor
EXP_SKEW=463         # frozen sim-minus-MAME skew. RE-MEASURED 14z-107 (7)
                     # with the input script no longer replayed (was 356, and
                     # before that 361 on the pre-fork-commit-3 SDRAM model),
                     # and RE-MEASURED AGAIN 14z-107 (8) with the harness no
                     # longer holding P1's and P2's buttons 5 and 6 down:
                     # unchanged at 463, now measured on inputs that match
                     # the MAME leg's. See "THE SECOND RE-FREEZE" above.
SKEW_TOL=30          # boot-phase band; the FIELDS are compared exactly
MAME_LO=2100; MAME_HI=2400
# ABSOLUTE frames (download included). The window mirrors the MAME leg's
# 2100-2400 with margin, and must START predicate-false or the anchor is
# ambiguous; it must also stay clear of the attract-mode demo fights,
# which is why it is a window and not the whole run.
SIM_FRAMES=2800; SIM_LO=2400; SIM_HI=2800

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
cf() { python3 "$REPO/tools/compare_fields.py" "$@"; }

echo "== MAME leg (stock vsavj, whole 68k work RAM, frames $MAME_LO-$MAME_HI) =="
mkdir -p "$W/mame"
DUMPS="$(python3 -c "print(';'.join(f'{f}:ff0000-ffffff' for f in range($MAME_LO,$MAME_HI+1)))")" \
    MAME_ROMPATH="$ROMDIR" "$REPO/tools/run_replay_mame.sh" vsavj "$RPL" \
    "$W/mame/out.log" "$W/mbox" || { echo "FAIL: MAME leg did not complete"; exit 1; }
python3 "$REPO/tools/check_wram_dumps.py" "$W/mame" --first "$MAME_LO" --last "$MAME_HI" \
    && ok "MAME dump set is COMPLETE ($MAME_LO-$MAME_HI, no holes, uniform size)" \
    || bad "MAME dump set is INCOMPLETE — the anchor below would be an artefact"
AM="$(cf "$W/mame" --list-anchors --fields "$FIELDS" 2>/dev/null | head -1)"
[ "$AM" = "$EXP_AM" ] && ok "MAME anchor at the frozen frame $AM" \
                      || bad "MAME anchor is [$AM], frozen $EXP_AM"

echo "== sim leg (core $SIM_CORE under Verilator, stock vsavj; ~45 min) =="
# --frame-output off is the DEFAULT and is passed explicitly anyway: these
# numbers were frozen under it, and a gate must state the configuration it
# was frozen under rather than inherit it (14z-107 (7)).
"$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$W/sim" --core "$SIM_CORE" --frame-output off \
    --frames "$SIM_FRAMES" --wram "$SIM_LO" "$SIM_HI" || { echo "FAIL: sim leg did not complete"; exit 1; }
# the run's own report of what it did with the pixels, asserted
grep -aq "frame output DISABLED (JTFRAME_SIM_NOVIDEO)" "$W/sim/jtsim.log" \
    && ok "the sim leg ran with HOST FRAME OUTPUT DISABLED (the frozen configuration)" \
    || bad "the sim leg did NOT report JTFRAME_SIM_NOVIDEO — the run is not the frozen configuration"
[ -d "$W/sim/frames" ] && bad "frames/ was collected — this run did work that follows the PICTURE" \
                       || ok "no frames/ produced (no fork, no ImageMagick, nothing reads the pixels)"
python3 "$REPO/tools/check_wram_dumps.py" "$W/sim/wram" --first "$SIM_LO" --last "$SIM_HI" \
    --size 0x10000 --addr 0xff0000 \
    && ok "sim dump set is COMPLETE ($SIM_LO-$SIM_HI, 64 KB each)" \
    || bad "sim dump set is INCOMPLETE — the anchor below would be an artefact"
# NON-CONSTANCY FIRST (the 14z-107 near-miss): an all-zero dump path agreed
# with MAME on 99.2% of sampled bytes, because most of a work-RAM image is
# zero. A dump window whose frames are all identical is a dead instrument, and
# every agreement number computed on it is worthless.
if [ "$(cd "$W/sim/wram" && shasum ./*.bin | cut -c1-40 | sort -u | wc -l | tr -d ' ')" -gt 1 ]
then ok "the dumped window is NON-CONSTANT (the instrument is live)"
else bad "the dumped window is CONSTANT — the 68k wrote no RAM; the run is dead, not agreeing"; fi
AS="$(cf "$W/sim/wram" --list-anchors --fields "$FIELDS" 2>/dev/null | head -1)"
[ -n "$AS" ] || { echo "FAIL: no match-start anchor in the simulated window $SIM_LO-$SIM_HI"; exit 1; }
SKEW=$((AS - AM))
if [ "$SKEW" -ge $((EXP_SKEW - SKEW_TOL)) ] && [ "$SKEW" -le $((EXP_SKEW + SKEW_TOL)) ]; then
    ok "sim anchor at frame $AS, skew $SKEW (frozen $EXP_SKEW +/- $SKEW_TOL)"
else
    bad "sim anchor at frame $AS, skew $SKEW OUTSIDE the frozen band $EXP_SKEW +/- $SKEW_TOL"
fi

echo "== field agreement at the anchor (follow $FOLLOW) =="
if cf "$W/mame" "$W/sim/wram" --fields "$FIELDS" --follow "$FOLLOW" \
        --skip-fields "$SKIP" --label-a mame --label-b "jt$SIM_CORE" > "$W/agree.out" 2>&1; then
    ok "MAME and jtcps2 agree on every mapped field ($(grep '^anchors:' "$W/agree.out" || true))"
else
    bad "dual-implementation disagreement:"; sed 's/^/      /' "$W/agree.out"
fi
# informational only: whole-RAM equality across implementations is not
# expected (CLAUDE.md §4) — the number is recorded, never a verdict.
D="$(cmp -l "$W/mame/dump_$((AM + 60))_ff0000.bin" "$W/sim/wram/dump_$((AS + 60))_ff0000.bin" 2>/dev/null | wc -l | tr -d ' ')"
echo "  note: whole 64 KB at anchor+60 differs in $D of 65536 bytes (informational;"
echo "        ~1,500 measured 14z-107, nearly all of it the other CPU opponent)"
python3 - "$W/mame/dump_$((AM + 60))_ff0000.bin" "$W/sim/wram/dump_$((AS + 60))_ff0000.bin" <<'PY'
import sys
def base(p, addr):
    b = open(p, "rb").read(); o = addr - 0xFF0000
    return int.from_bytes(b[o:o + 4], "big")
m, s = sys.argv[1], sys.argv[2]
print(f"  note: P1 record base mame ${base(m,0xFF8460):06X} / sim ${base(s,0xFF8460):06X}"
      f"   P2 (the arcade draw) mame ${base(m,0xFF8860):06X} / sim ${base(s,0xFF8860):06X}")
PY

echo "== control: byte-swapped sim dumps must FAIL =="
mkdir -p "$W/swap"
python3 - "$W/sim/wram" "$W/swap" <<'PY'
import pathlib, sys
src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
for p in src.iterdir():
    b = p.read_bytes()
    (dst / p.name).write_bytes(bytes(b[i ^ 1] for i in range(len(b))))
PY
if cf "$W/mame" "$W/swap" --fields "$FIELDS" --follow 0 --skip-fields "$SKIP" > "$W/ctrl.out" 2>&1
then bad "CONTROL DID NOT FIRE: byte-swapped sim dumps compared equal"
else ok "control fired: byte-swapped sim dumps rejected"; fi

echo "== control: a hole in the dump set must be REJECTED =="
mkdir -p "$W/holed"
cp "$W/sim/wram/"*.bin "$W/holed/"
rm -f "$W/holed/dump_$((SIM_LO + 7))_ff0000.bin"
if python3 "$REPO/tools/check_wram_dumps.py" "$W/holed" --first "$SIM_LO" --last "$SIM_HI" \
        --size 0x10000 > "$W/hole.out" 2>&1
then bad "CONTROL DID NOT FIRE: a dump set with a hole passed the integrity check"
else ok "control fired: a lost dump is rejected before any anchor is computed"; fi

echo "== control: the harness hook is inert without --wram =="
# --no-load: the macro's absence is a COMPILE-time property, so the cheapest
# run that proves it is a 5-frame one with no ROM transfer (~30 s including
# the rebuild). The 68k does not run in such a run, which is fine here and
# nowhere else.
"$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$W/inert" --core "$SIM_CORE" --frame-output off --no-load --frames 5 > "$W/inert.log" 2>&1 \
    || { bad "the inertness control run failed"; tail -5 "$W/inert.log" | sed 's/^/      /'; }
[ -d "$W/inert/wram" ] && bad "CONTROL DID NOT FIRE: wram/ produced with the macro absent" \
                       || ok "control fired: no wram/ when JTFRAME_SIM_WRAMDUMP is undefined"

[ $fail = 0 ] && echo "PASS test_mister_sim_anchor" || { echo "FAIL test_mister_sim_anchor"; exit 1; }
