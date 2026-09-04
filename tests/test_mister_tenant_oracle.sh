#!/bin/sh
# test_mister_tenant_oracle.sh — THE §4 DUAL-EMULATOR ORACLE ON TENANT
# CONTENT (14z-108). MAME and jtcps2w run the same TENANT-PICKING replay on
# the same WIDE romset, and the mapped gameplay fields must agree at the
# round-1 match-start anchor.
#
# WHY IT EXISTS, and why it is not the same gate as test_mister_sim_anchor.
# That gate runs LEGACY content on the stock romset: it is the FPGA edition of
# the emulator superset invariant. This one runs CONTENT THIS PROJECT
# AUTHORED, for which no vanilla oracle exists at all — which is precisely the
# case CLAUDE.md §4 wrote the dual-emulator rule for: "for new-character
# content the same replay is run on patched FBNeo and patched MAME and the two
# must agree on mapped gameplay state at sync anchors". jtcps2w is a THIRD
# implementation, so a bug would have to manifest identically in two unrelated
# codebases AND in Jotego's RTL to slip through.
#
# WHAT IT ADDS OVER test_mister_gfxc_fetch. That gate proves the tenant's art
# is FETCHED — 9,388,928 reads out of obj bank 4. Fetching art is plumbing.
# THIS gate is the first evidence that the tenant FIGHTS CORRECTLY on the
# core: same character record, same HP, same timer, same position, same meter.
#
# FROZEN EXPECTATIONS (measured 14z-108, 36_pick_tenant_cell on the WIDE set):
#   MAME anchor              frame 2886
#   sim anchor (ABSOLUTE)    frame 3546   (the 659 WIDE download frames included)
#   skew (sim - MAME)        660
# THE SKEW IS THE TRANSFER PLUS ONE. The WIDE image takes 659 frames to
# download, so the real cross-implementation skew is +1 frame — and that is
# the SAME +1 the legacy replay shows (463 skew on a 462-frame transfer,
# test_mister_sim_anchor). Two different replays, two different romset sizes,
# the same one-frame offset: the boot-phase difference between MAME and the
# core is a constant, not a function of the content.
#
# P1 IS THE TENANT ON BOTH SIDES, and that is the point of the run:
#   p1_hitbox_base  0x003FA9D0   the RELOCATED tenant record, in wide_ext
#   p1_ptr64        0x003FA790   likewise
#   p1 +0x382       0x13         the tenant's native vs2 id
# A core that had loaded a legacy character instead would fail on the first
# of those, which is the failure this gate is really guarding against — it is
# how 14z-107 (12) looked when the harness put the cursor on Victor.
#
# THE ONE EXCLUDED DISAGREEMENT, and it is LIVE rather than theoretical:
# p2_hitbox_base is 0x000ABD74 on MAME and 0x0009769E on the core. The CPU
# opponent is a SOUND-STATE-FED LOTTERY (docs/game/atlas/ram.md:99, the #110
# mechanism), so the fields that are a FUNCTION OF WHICH CHARACTER P2 IS are
# excluded BY NAME below — exactly as test_mister_sim_anchor excludes them,
# for the same measured reason. p2_hp and the p2 meter fields stay compared
# and agree. That the exclusion FIRES here is useful: it proves the field set
# is not passing vacuously.
#
# COST: the sim leg boots from frame 0 at ~1 s per simulated frame, so this
# gate takes ~65 min and needs Verilator, ROMDIR and the WIDE build. It is an
# EMULATOR-tier gate, not in ci_portable/ci_static.
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier manual/emulator (~65 min)) THE §4 DUAL-EMULATOR ORACLE ON TENANT
#   CONTENT (14z-108) — the first evidence that a tenant FIGHTS CORRECTLY on
#   the core, as opposed to having its art fetched. MAME and `cps2w` run
#   `36_pick_tenant_cell` on the same WIDE romset; the mapped fields of
#   `fields_m2a.tsv` must agree at the round-1 match-start anchor and its
#   follow offsets. This is the case CLAUDE.md §4 wrote the dual-emulator rule
#   FOR — authored content, no vanilla oracle — and jtcps2w is a third
#   implementation, so a bug would have to manifest identically in two
#   unrelated codebases and in Jotego's RTL. Frozen: MAME 2886 / sim 3546 /
#   skew 660 ± 30, and the skew is the 659-frame WIDE transfer PLUS ONE — the
#   same +1 the legacy replay shows on a 462-frame transfer, so the boot-phase
#   offset is a constant rather than a function of content. Asserts P1's
#   hitbox base is `0x003FA9D0` on BOTH legs — the RELOCATED tenant record; a
#   core that loaded a legacy character instead fails there, which is what
#   14z-107 (12) looked like. `p2_hitbox_base` is excluded BY NAME (the sound-
#   fed CPU draw: MAME `0x000ABD74` vs core `0x0009769E`) and a control proves
#   that exclusion is LIVE rather than vacuous. The must-fire control perturbs
#   the TIMER, which is compared but is not an anchor input — a byte-swap
#   control is weaker because it destroys the anchor and never exercises the
#   field comparison at all
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }

RPL="$REPO/tests/replays/36_pick_tenant_cell.rpl"
FIELDS="$REPO/tests/fields_m2a.tsv"
BUILD="${BUILD:-build/m3b_merged23}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
FOLLOW="0,60,180"
SKIP="p2_hitbox_base,p2_ptr64,p2_word132,p2_x,p2_y,p2_attack_id,p2_flip"
EXP_AM=2886          # frozen MAME anchor
EXP_AS=3546          # frozen sim anchor, ABSOLUTE (659 download frames included)
EXP_SKEW=660; SKEW_TOL=30
MAME_LO=2850; MAME_HI=3150
SIM_FRAMES=3800; SIM_LO=3450; SIM_HI=3800

[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset (this gate runs the real romset)"; exit 77; }
command -v verilator >/dev/null 2>&1 || { echo "SKIP: verilator not installed"; exit 77; }
[ -d "$REPO/$BUILD" ] || { echo "SKIP: no $BUILD (build the WIDE romset first)"; exit 77; }
[ -e "$REPO/emu/jtcores/.git" ] || { echo "SKIP: emu/jtcores not initialised"; exit 77; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
cf(){ python3 "$REPO/tools/compare_fields.py" "$@"; }

echo "== MAME leg (WIDE romset vsavjw, whole 68k work RAM, frames $MAME_LO-$MAME_HI) =="
mkdir -p "$W/mame"
: "${MAME_BIN:=$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN (tools/setup_mame.sh)"; exit 77; }
DUMPS="$(python3 -c "print(';'.join(f'{f}:ff0000-ffffff' for f in range($MAME_LO,$MAME_HI+1)))")" \
    MAME_BIN="$MAME_BIN" MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
    "$REPO/tools/run_replay_mame.sh" vsavjw "$RPL" "$W/mame/out.log" "$W/mbox" \
    || { echo "FAIL: MAME leg did not complete"; exit 1; }
python3 "$REPO/tools/check_wram_dumps.py" "$W/mame" --first "$MAME_LO" --last "$MAME_HI" \
    && ok "MAME dump set COMPLETE" || bad "MAME dump set INCOMPLETE — any anchor would be an artefact"
AM="$(cf "$W/mame" --list-anchors --fields "$FIELDS" 2>/dev/null | head -1)"
[ "$AM" = "$EXP_AM" ] && ok "MAME anchor at the frozen frame $AM" || bad "MAME anchor is [$AM], frozen $EXP_AM"

echo "== sim leg (cps2w under Verilator, the WIDE romset; ~65 min) =="
"$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$W/sim" --core cps2w --wide "$BUILD" \
    --frame-output off --frames "$SIM_FRAMES" --wram "$SIM_LO" "$SIM_HI" \
    || { echo "FAIL: sim leg did not complete"; exit 1; }
grep -aq "frame output DISABLED (JTFRAME_SIM_NOVIDEO)" "$W/sim/jtsim.log" \
    && ok "sim leg ran with HOST FRAME OUTPUT DISABLED (the frozen configuration)" \
    || bad "sim leg did NOT report JTFRAME_SIM_NOVIDEO — not the frozen configuration"
python3 "$REPO/tools/check_wram_dumps.py" "$W/sim/wram" --first "$SIM_LO" --last "$SIM_HI" \
    && ok "sim dump set COMPLETE" || bad "sim dump set INCOMPLETE"
AS="$(cf "$W/sim/wram" --list-anchors --fields "$FIELDS" 2>/dev/null | head -1)"
[ "$AS" = "$EXP_AS" ] && ok "sim anchor at the frozen frame $AS" || bad "sim anchor is [$AS], frozen $EXP_AS"

if [ -n "$AM" ] && [ -n "$AS" ]; then
    skew=$((AS - AM)); d=$((skew - EXP_SKEW)); [ $d -lt 0 ] && d=$((-d))
    [ $d -le $SKEW_TOL ] && ok "skew $skew (frozen $EXP_SKEW +/- $SKEW_TOL; = the 659-frame transfer + 1)" \
                         || bad "skew $skew, frozen $EXP_SKEW +/- $SKEW_TOL"
fi

echo "== P1 IS THE TENANT ON BOTH SIDES =="
for leg in "MAME:$W/mame/dump_${AM}_ff0000.bin" "sim:$W/sim/wram/dump_${AS}_ff0000.bin"; do
    who="${leg%%:*}"; f="${leg#*:}"
    v="$(python3 -c "
import sys
b=open(sys.argv[1],'rb').read(); o=0xFF8460-0xFF0000
print('0x%08X' % int.from_bytes(b[o:o+4],'big'))" "$f" 2>/dev/null)"
    [ "$v" = "0x003FA9D0" ] && ok "$who P1 hitbox base $v — the RELOCATED tenant record" \
                            || bad "$who P1 hitbox base is $v, expected 0x003FA9D0 (a LEGACY character was loaded)"
done

echo "== the comparison =="
if cf "$W/mame" "$W/sim/wram" --fields "$FIELDS" --follow "$FOLLOW" --skip-fields "$SKIP" > "$W/cmp.out" 2>&1
then ok "every compared field agrees at the anchor and its follow offsets"
else bad "fields disagree:"; sed 's/^/      /' "$W/cmp.out"; fi

echo "== control: a perturbed COMPARED field must be CAUGHT =="
# The timer is compared and is NOT an input to the anchor predicate, so the
# anchor must still be found and the comparison must then name this field.
# A byte-SWAP control is weaker: it destroys the anchor, so it proves only
# that the anchor predicate rejects garbage and never exercises the field
# comparison at all (measured 14z-108).
mkdir -p "$W/tweak"
python3 - "$W/sim/wram" "$W/tweak" <<'PY'
import pathlib, sys
src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
for p in src.iterdir():
    b = bytearray(p.read_bytes()); b[0x8109] = (b[0x8109] + 1) & 0xFF
    (dst / p.name).write_bytes(bytes(b))
PY
if cf "$W/mame" "$W/tweak" --fields "$FIELDS" --follow "$FOLLOW" --skip-fields "$SKIP" > "$W/ctrl.out" 2>&1
then bad "CONTROL DID NOT FIRE: a perturbed timer compared equal"
else grep -q "timer" "$W/ctrl.out" \
       && ok "control fired: the perturbed timer is caught and NAMED" \
       || bad "control failed but did not name the timer — it caught something else"; fi

echo "== control: the P2 exclusion is LIVE, not vacuous =="
if cf "$W/mame" "$W/sim/wram" --fields "$FIELDS" --follow 0 > "$W/noskip.out" 2>&1
then bad "CONTROL DID NOT FIRE: with NO skip list the legs agree — the exclusion is doing nothing"
else grep -q "p2_hitbox_base" "$W/noskip.out" \
       && ok "control fired: without the skip list p2_hitbox_base disagrees (the sound-fed CPU draw)" \
       || ok "control fired: without the skip list the legs disagree"; fi

[ $fail = 0 ] && echo "PASS test_mister_tenant_oracle" || { echo "FAIL test_mister_tenant_oracle"; exit 1; }
