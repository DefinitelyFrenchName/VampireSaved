#!/bin/sh
# audit_projectile_clash.sh — the pool-vs-pool projectile-contact surface
# (14z-100 hardening H4; the census gap the hitclass KEEP ruling named).
#
# TWO LEGS on the merged build, probing the hitclass-map thunk body (from
# the build's own patch fragment):
#   CONTROL (105_projectile_clash_ctl): Demitri vs Demitri head-on flares.
#     The sweep path must be ALIVE — measured 468 probe fires at authoring.
#     A quiet control means the probe or the path died; nothing else in
#     this audit is a verdict then (the 87 rule).
#   TENANT (106_pyron_cosmo_clash): Pyron cosmo satellites + one legacy
#     flare through the field, P1 clean of hitstun at spawn.
#
# EXPECT_SAT_SWEEP=0 (default — GitHub #108, THE DEFECT MODE): satellites
#   carry collision word +0x18 == 0x1000 (native vs2: 0x6000, clean-leg
#   A/B measured 14z-100) and the probe fires ZERO times on the tenant
#   leg. This gate freezes the defect's signature so any drift is loud.
# EXPECT_SAT_SWEEP=1 (the fix mode, flip when #108's fix lands): the
#   satellite word must read 0x6000 and the tenant leg must fire >= 1.
#
# ~5 min (2 MAME runs, parallel). On-demand.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged11}"
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN
EXPECT="${EXPECT_SAT_SWEEP:-0}"

BODY="$(sed -n 's/^code *0x0*\([0-9a-f]*\) .*site_thunk hitclass_map_extend.*/\1/p' \
        "$BUILD/patch/patch_notes_fragment.md" | head -1)"
[ -n "$BODY" ] || { echo "FAIL: hitclass thunk body not in the fragment"; exit 1; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mkdir -p "$W/ctl" "$W/ten"
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
SAT="$(python3 - "$W/ten" <<'PY'
import sys, glob
d = sys.argv[1]
fs = glob.glob(f"{d}/dump_3520_ff9400.bin")
if not fs:
    print("NODUMP"); raise SystemExit
b = open(fs[0], "rb").read()
for s in range(8):
    sl = b[s*0x100:(s+1)*0x100]
    if sl[0] and sl[2] == 0x42:
        print(f"{sl[0x18]:02x}{sl[0x19]:02x}"); break
else:
    print("NOSAT")
PY
)"
if [ "$SAT" = "NOSAT" ] || [ "$SAT" = "NODUMP" ]; then
    echo "FAIL: tenant leg produced no satellite at f3520 — rig dead ($SAT)"; fail=1
elif [ "$EXPECT" = 0 ]; then
    if [ "$NT" = 0 ] && [ "$SAT" = "1000" ]; then
        echo "   ok(defect mode): satellites word 0x$SAT, tenant fires $NT — the frozen #108 signature"
    else
        echo "FAIL(defect mode): word 0x$SAT / fires $NT — the #108 signature MOVED; if the fix landed, flip EXPECT_SAT_SWEEP=1"
        fail=1
    fi
else
    if [ "$NT" -ge 1 ] && [ "$SAT" = "6000" ]; then
        echo "   ok(fix mode): satellites word 0x$SAT, tenant fires $NT — native behavior restored"
    else
        echo "FAIL(fix mode): word 0x$SAT / fires $NT — the fix is not doing what #108 specifies"
        fail=1
    fi
fi

[ "$fail" = 0 ] && echo "AUDIT PASS" || { echo "AUDIT FAIL"; exit 1; }
