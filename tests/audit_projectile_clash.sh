#!/bin/sh
# audit_projectile_clash.sh — the pool-vs-pool projectile-contact surface
# (14z-100 hardening H4; the census gap the hitclass KEEP ruling named).
# RE-FRAMED 14z-101: the "defect signature" this audit froze at authoring
# is MEASURED NATIVE PARITY, not a defect — see GitHub #108's resolution.
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
# ~5 min (3 MAME runs, parallel). On-demand.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged15}"  # re-pointed 14z-110b
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
CTL_PK="1400:ff8782:01;1450:ff8782:01;1500:ff8782:01;1400:ff8b82:01;1450:ff8b82:01;1500:ff8b82:01"
TEN_PK="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;1400:ff8b82:01;1450:ff8b82:01;1500:ff8b82:01;3300:ff8509:03"
TEN_DF="3520:ff9400-ff9c00"

( GUARD_PROBE="$BODY" GUARD_PROBE_MAX=20000 POKES="$CTL_PK" \
  MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
  tools/run_replay_guarded.sh vsavjw tests/replays/105_projectile_clash_ctl.rpl \
  "$W/ctl/out.log" "$W/ctl/sbx" >/dev/null 2>&1 || true ) &
( GUARD_PROBE="$BODY" GUARD_PROBE_MAX=20000 POKES="$TEN_PK" DUMPS="$TEN_DF" \
  MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
  tools/run_replay_guarded.sh vsavjw tests/replays/106_pyron_cosmo_clash.rpl \
  "$W/ten/out.log" "$W/ten/sbx" >/dev/null 2>&1 || true ) &
( POKES="$TEN_PK" DUMPS="$TEN_DF" \
  tools/run_replay_mame.sh vsav2 tests/replays/106_pyron_cosmo_clash.rpl \
  "$W/nat/out.log" "$W/nat/sbx" >/dev/null 2>&1 || true ) &
wait
fail=0

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

[ "$fail" = 0 ] && echo "AUDIT PASS" || { echo "AUDIT FAIL"; exit 1; }
