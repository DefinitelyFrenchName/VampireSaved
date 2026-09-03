#!/bin/sh
# audit_continue_ladder.sh — THE #102 DISCRIMINATOR (14z-98): does a
# loss+continue reset the arcade ladder's in-use mask ON VANILLA, with a
# pure-legacy character? On-demand, ~20 min (2 full-marathon MAME runs,
# parallel: pristine vsavj + the merged build).
#
# #102 IS CLOSED — maintainer-ruled 2026-08-19, NOT OURS (the answer this
# gate produced). It is now a REGRESSION LOCK, not an open investigation:
# leg A red means vanilla stopped resetting, i.e. the behavior was ours
# after all, and #102 reopens. Keep running it; do not retire it.
#
# THE QUESTION (#102, filed 14z-97 (3)): "later matches land on earlier
# venues, and the total number of matches can exceed the arcade norm" —
# observed by the maintainer around tenant continue/switch chains. The
# pre-registered discriminator: run the same chain with LEGACY characters
# only; drifts the same -> not ours.
#
# MEASURED 14z-98 on the first mapping pair (Victor forced, natural mash
# losses, 4 extra credits spliced into the marathon's attract):
#   vanilla vsavj:  venues 06 -> 0E -> 12, loss at match 3, CONTINUE
#                   (~960f KO->new match, $8004=000E continue mode),
#                   MASK CLEARED 1 -> 0, then 04 -> 0A -> 06 (a REPEAT).
#   merged-m3:      frame-identical through match 3's start, P1 WON
#                   match 3 instead (the sound-fed lottery differs
#                   between builds — documented, ram.md), then
#                   06 -> 0E -> 12 -> 02 (mask accumulating 1 -> 0x401:
#                   venue DOWN with NO continue — the ladder is not
#                   venue-monotonic even healthy), loss at match 4,
#                   continue, MASK CLEARED 0x401 -> 0, then 08.
# Same mechanism both builds: THE ENGINE'S OWN CONTINUE PATH RESETS THE
# IN-USE MASK, so the pool restarts — earlier venues and extra matches
# are the vanilla envelope, not a port defect. The tenant correlation in
# the field report is explained by "switching requires continuing".
#
# WHAT THIS AUDIT ASSERTS (structural, not exact-trajectory — the venue
# VALUES are per-build lottery draws; the RESET SHAPE is the finding):
#   per leg: (1) the run reaches >= 3 matches; (2) at least one
#   LOSS+CONTINUE occurs (in-use mask held non-zero, then cleared to 0
#   while more matches FOLLOW — the reset with the pool restarting is
#   the whole finding). A third "mask re-accumulates" assertion was
#   removed by its own first run: the 80f dump cadence does not reliably
#   sample the short-lived post-continue mask states, so it refused real
#   data (safe direction; the verdict-logic-is-tested doctrine working).
#   And the VANILLA leg must show it too — that is the discriminator:
#   if vanilla ever stops resetting (this gate's leg A goes red), the
#   behavior was ours after all and #102 reopens.
#
# Kill pokes: NONE — losses are the mash's own (audit_kill_poke_shape:
# a 2-byte HP poke would manufacture #103's stall and wedge the leg).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged22]
#        tests/audit_continue_ladder.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-98 (4), GitHub #102 (CLOSED 2026-08-19, maintainer-ruled NOT OURS —
#   this is now the REGRESSION LOCK, keep running it): THE DISCRIMINATOR —
#   does a loss+continue reset the arcade ladder's in-use mask ON PRISTINE
#   VANILLA with a legacy character? Measured YES: vanilla venues 06->0E->12,
#   loss, continue (~960f, $8004=000E), mask 1->0, pool restarts 04->0A->06 (a
#   repeat); merged same mechanism (0x401->0). Both #102 symptoms = the
#   vanilla envelope; the tenant correlation = "switching requires
#   continuing". Leg A red would mean the behavior was OURS — reopen 102. NO
#   kill pokes by design (audit_kill_poke_shape). Venue VALUES are lottery
#   draws; the RESET SHAPE is the assertion. ~20 min, 2 parallel marathons.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged22}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

# Derive the coin-boosted marathon from the committed one (one source,
# the #48 lesson): 4 extra C1 presses spliced into the early attract.
RPL="$W/coin_marathon.rpl"
python3 - "$RPL" <<'PY'
import sys
lines = open("tests/replays/26_don_arcade_mash.rpl").read().splitlines(keepends=True)
out, done = [], False
for ln in lines:
    if not done and ln[:1].isdigit():
        out.append("100-105 sys=C1\n140-145 sys=C1\n180-185 sys=C1\n220-225 sys=C1\n")
        done = True
    out.append(ln)
open(sys.argv[1], "w").writelines(out)
PY

PKV="1704:ff8782:03;1760:ff8782:03;1900:ff8782:03;2100:ff8782:03;2400:ff8782:03"
DF="$(python3 -c "print(';'.join(f'{f}:ff8000-ff8180;{f}:ff8450-ff8456' for f in range(2500,40600,80)))")"

run_leg() { # tag set rompath
    d="$W/$1"; mkdir -p "$d/sbx"
    ( cd "$d" && REPLAY="$RPL" POKES="$PKV" DUMPS="$DF" CHECKSUM_OUT="$d/out.log" \
      MAME_SANDBOX="$d/sbx" MAME_ROMPATH="$3" \
      "$REPO/tools/run_mame.sh" "$2" \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/mame.log" 2>&1 ) &
}
run_leg vanilla vsavj  "$ROMDIR"
run_leg merged  vsavjw "$REPO/$BUILD/rompath;$ROMDIR"
wait

classify() { # dir
    python3 - "$1" <<'PY'
import glob, struct, re, sys
d = sys.argv[1]
frames = sorted(int(re.search(r'dump_(\d+)_ff8000', f).group(1))
                for f in glob.glob(f"{d}/dump_*_ff8000.bin"))
if not frames:
    print("DEAD no dumps"); sys.exit(0)
seq = []   # (frame, stage, mask)
prev = None
for f in frames:
    b = open(f"{d}/dump_{f}_ff8000.bin", "rb").read()
    stage = struct.unpack(">H", b[0x100:0x102])[0]
    mask = struct.unpack(">I", b[0x110:0x114])[0]
    if (stage, mask) != prev:
        seq.append((f, stage, mask)); prev = (stage, mask)
venues = [s for _, s, _ in seq if s != 0]
distinct_matches = len([1 for i, (_, s, _) in enumerate(seq)
                        if s != 0 and (i == 0 or seq[i-1][1] != s)])
# continue = mask non-zero -> 0 while the run keeps producing venues after
resets = []
for i in range(1, len(seq)):
    f, s, m = seq[i]
    pf, ps, pm = seq[i-1]
    if pm != 0 and m == 0:
        later = [x for x in seq[i:] if x[1] not in (0, ps) ]
        if later:
            resets.append((f, pm))
print(f"matches={distinct_matches} venues={['%x' % v for v in venues]} "
      f"resets={[('f%d' % f, hex(m)) for f, m in resets]}")
if distinct_matches >= 3 and resets:
    print("VERDICT CONTINUE-RESETS")
elif distinct_matches < 3:
    print("VERDICT DEAD-RIG (fewer than 3 matches)")
else:
    print("VERDICT NO-RESET")
PY
}

echo "== leg A: pristine vsavj (the discriminator leg)"
A="$(classify "$W/vanilla")"; echo "$A" | sed 's/^/   /'
echo "== leg B: the merged build, same rig"
B="$(classify "$W/merged")"; echo "$B" | sed 's/^/   /'

case "$A" in
*"VERDICT CONTINUE-RESETS"*) echo "  ok: VANILLA's own continue resets the ladder mask — the #102 drift is the vanilla envelope" ;;
*"VERDICT DEAD-RIG"*) echo "FAIL: vanilla leg rig died (no 3 matches) — no verdict"; fail=1 ;;
*) echo "FAIL: VANILLA did not reset on continue — the behavior would be OURS; #102 reopens"; fail=1 ;;
esac
case "$B" in
*"VERDICT CONTINUE-RESETS"*) echo "  ok: the merged build shows the same mechanism" ;;
*"VERDICT DEAD-RIG"*) echo "FAIL: merged leg rig died — no comparison"; fail=1 ;;
*) echo "FAIL: merged leg did not show the reset ($B) — legs no longer comparable; re-measure"; fail=1 ;;
esac

[ "$fail" = 0 ] && echo "AUDIT PASS (the #102 drift is engine continue behavior on both legs)" \
    || { echo "AUDIT FAIL"; exit 1; }
