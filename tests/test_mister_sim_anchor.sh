#!/bin/sh
# test_mister_sim_anchor.sh — THE MiSTer LEG OF THE §4 DUAL-EMULATOR ORACLE
# (14z-107). Stock jtcps2 under Verilator and MAME run the same legacy replay
# on the same stock vsavj romset; the mapped gameplay fields must agree at the
# round-1 match-start anchor and at the follow offsets.
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
# FROZEN EXPECTATIONS (re-measured 14z-107 (3), stock cps2 core, fork pin
# 74ed17d — the pin with the FIXED Verilator SDRAM model):
#   MAME anchor              frame 2146   (05_timeout_idle, stock vsavj)
#   sim anchor (ABSOLUTE)    frame 2502   (the 462 download frames included)
#   skew (sim - MAME)        356
#
# THE SIM ANCHOR MOVED 2507 -> 2502 WHEN THE SDRAM MODEL WAS FIXED, and the
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
#
# THE SKEW IS NOT THE BOOT OFFSET, and that is worth knowing: at the RAM-test
# onset the two are 460 frames apart (462 download frames minus a 2-frame
# lead), but by the round-1 match start they are 361 apart — the sim reaches
# the match ~99 frames earlier RELATIVE to its own boot. The attract/select/VS
# path costs different numbers of frames in the two implementations, which is
# precisely why CLAUDE.md §4 compares mapped state at ANCHORS and not at fixed
# frame indices.
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
# needs a 2P replay, which needs P2 in the v1.7.3 `SimInputs` harness — a
# queued fork commit (docs/platform/mister.md "Open / to verify").
# The skew is frozen with a tolerance because it is a boot-phase property, not
# gameplay state; the FIELDS are compared exactly. A skew outside the band is
# a finding: stop and root-cause, do not widen (the standing watch).
#
# CONTROLS (a gate without one asserts nothing):
#   * byte-swapped sim dumps must FAIL the comparison — the one mistake that
#     would otherwise fabricate a "the core disagrees with MAME" report;
#   * a sim run WITHOUT --wram must produce no wram/ at all — the harness hook
#     is inert unless asked (the emulator-superset shape, sim edition).
#
# Usage: ROMDIR=... [JTSIM_SCRATCH=...] tests/test_mister_sim_anchor.sh
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

RPL="$REPO/tests/replays/05_timeout_idle.rpl"
FIELDS="$REPO/tests/fields_m2a.tsv"
FOLLOW="0,60,180"
# Excluded by name, mechanism in the header: the arcade draw picked a
# different CPU opponent on each implementation, so every field that is a
# function of WHICH character P2 is would assert a disagreement.
SKIP="p2_hitbox_base,p2_ptr64,p2_word132,p2_x,p2_y,p2_attack_id,p2_flip"
EXP_AM=2146          # frozen MAME anchor
EXP_SKEW=356         # frozen sim-minus-MAME skew (see the header; was 361 on
                     # the pre-fork-commit-3 SDRAM model)
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
AM="$(cf "$W/mame" --list-anchors --fields "$FIELDS" 2>/dev/null | head -1)"
[ "$AM" = "$EXP_AM" ] && ok "MAME anchor at the frozen frame $AM" \
                      || bad "MAME anchor is [$AM], frozen $EXP_AM"

echo "== sim leg (stock jtcps2 under Verilator; ~45 min) =="
"$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$W/sim" --core cps2 \
    --frames "$SIM_FRAMES" --wram "$SIM_LO" "$SIM_HI" || { echo "FAIL: sim leg did not complete"; exit 1; }
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
        --skip-fields "$SKIP" --label-a mame --label-b jtcps2 > "$W/agree.out" 2>&1; then
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
print(f"  note: P1 record base mame ${base(m,0xFF8460):06X} / jtcps2 ${base(s,0xFF8460):06X}"
      f"   P2 (the arcade draw) mame ${base(m,0xFF8860):06X} / jtcps2 ${base(s,0xFF8860):06X}")
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

echo "== control: the harness hook is inert without --wram =="
# --no-load: the macro's absence is a COMPILE-time property, so the cheapest
# run that proves it is a 5-frame one with no ROM transfer (~30 s including
# the rebuild). The 68k does not run in such a run, which is fine here and
# nowhere else.
"$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$W/inert" --core cps2 --no-load --frames 5 > "$W/inert.log" 2>&1 \
    || { bad "the inertness control run failed"; tail -5 "$W/inert.log" | sed 's/^/      /'; }
[ -d "$W/inert/wram" ] && bad "CONTROL DID NOT FIRE: wram/ produced with the macro absent" \
                       || ok "control fired: no wram/ when JTFRAME_SIM_WRAMDUMP is undefined"

[ $fail = 0 ] && echo "PASS test_mister_sim_anchor" || { echo "FAIL test_mister_sim_anchor"; exit 1; }
