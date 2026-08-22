#!/bin/sh
# audit_don_ko_writer.sh — THE #103 ROOT-CAUSE LOCK (14z-98): WHO WRITES
# DONOVAN'S HP AT HIS ARCADE DEATH, PC-attributed, non-debug (canonical
# timeline). On-demand, ~8 min (2 MAME read_tap runs, parallel).
#
# THE MECHANISM THIS LOCKS (full chain on GitHub #103, 14z-98 comment):
# the round judge kills on THE SIGN OF WHITE HP (+0x52; in-match machine
# PRG:0x93CE, phase-6 handler 0x97DC, tests at 0x97FC/0x9804), and the
# damage pipeline keeps white <= hp so white crosses zero FIRST. Donovan's
# ported region x026142 carries a node op (vs2 0x262A4) whose tail
# `bra.w $25F9A` ESCAPES the region (target 0x1A8 before its start); the
# preserved displacement lands it in x066ec4's placed copy — his
# CHILD-OBJECT INIT (vs2 0x66FD8) — executed with A6 = the FIGHTER, whose
# `move.w table(pc,d0.w),$50(a6)` pool-durability init pins HIS HP TO 1
# while white sits ~200. The next ordinary hit underflows hp with white
# still positive; the judge never fires; the round stalls ~8,000f (#103).
#
# LEG A (Donovan, EXPECT_DEFECT=1 default) asserts the DEFECT IS STILL
# THERE on the current build (the #98/audit_don_lilith_ko discipline):
#   - a write to $FF8450 from a PC inside the placed x026142/x066ec4
#     window (the escape path; measured PC 0x0CD286 on don_m8/merged-m3)
#     with value 0x0001, and
#   - a subsequent underflow write (engine applier) with NO kill-commit
#     write afterward.
# When the pcrel_escape_fix row lands, flip EXPECT_DEFECT=0: leg A must
# then show ZERO ported-window writes to $FF8450 and MUST show the kill
# commit (both HP words = 0xFFFF in one frame) at his death — the healthy
# shape leg B proves the instrument can see.
#
# LEG B (Victor, same rig) is the INSTRUMENT CONTROL, required in every
# mode: his death must show the kill commit (hp AND white written 0xFFFF
# in the same frame — the 0x18A7C/0x2980A family). Without it, a quiet
# leg A is indistinguishable from a dead tap (RH-15).
#
# CAUSALITY (measured 14z-98, not re-run here): a probe build with
# [[pcrel_escape_fix]] region="x026142" (targets = the 7 verified twins
# in reconciliation_huitzil.toml) flips audit_don_lilith_ko to
# FLOWED 560 — the healthy legacy constant.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged11]
#        [EXPECT_DEFECT=1] tests/audit_don_ko_writer.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged13}"
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN
EXPECT_DEFECT="${EXPECT_DEFECT:-0}"   # flipped at the 14z-99 window (#103 landed)
# WEAKEN_P1=1 (14z-99): same mode and same reason as audit_don_lilith_ko —
# on a FIXED build the mash-Donovan WINS (measured: the CPU never lands a
# hit while he attacks), so his death is lottery-bound and leg A reads
# NEITHER. The weaken leg cuts his inputs at f6100 and pins hp/white to 5
# (both words, once — no re-pin can land on the corpse); the CPU's own hit
# kills through the real judge and the kill commit is tappable. FIX
# VERIFICATION ONLY: refused with EXPECT_DEFECT=1 (the pin overwrites the
# defect's hp:=1 write and would mask the very shape leg A asserts).
if [ "$EXPECT_DEFECT" = 0 ]; then _wdef=1; else _wdef=0; fi
WEAKEN_P1="${WEAKEN_P1:-$_wdef}"
if [ "$WEAKEN_P1" = 1 ] && [ "$EXPECT_DEFECT" = 1 ]; then
    echo "REFUSING: WEAKEN_P1=1 with EXPECT_DEFECT=1 — the pin masks the"
    echo "  defect shape. Weaken only when verifying the FIX."
    exit 1
fi

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

# Same one-source input derivation as audit_don_lilith_ko.sh (#48 lesson).
RPL="$W/marathon_head.rpl"
awk -F'[- ]' '/^[0-9]/ { if ($1 + 0 > 18000) exit } { print }' \
    "$REPO/tests/replays/26_don_arcade_mash.rpl" > "$RPL"
RPL_W="$W/marathon_weaken.rpl"
awk -F'[- ]' '/^[0-9]/ { if ($1 + 0 > 6100) exit } { print }' \
    "$REPO/tests/replays/26_don_arcade_mash.rpl" > "$RPL_W"
printf '17960 wait\n' >> "$RPL_W"

run_leg() { # tag p1class frames
    d="$W/$1"; mkdir -p "$d/sbx"
    PK="1704:ff8782:$2;1760:ff8782:$2;1900:ff8782:$2;2100:ff8782:$2;2400:ff8782:$2"
    _rpl="$RPL"
    if [ "$WEAKEN_P1" = 1 ] && [ "$1" = don ]; then
        PK="$PK;6200:ff8450:00050005;6260:ff8450:00050005;6320:ff8450:00050005"
        _rpl="$RPL_W"
    fi
    ( cd "$d" && RTAP="ff8450,4" WINDOW="0,0" TRACE_OUT="$d/tap.txt" FRAMES="$3" \
      REPLAY="$_rpl" POKES="$PK" MAME_SANDBOX="$d/sbx" \
      MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1 ) &
}
# Leg A window: 13400, NOT 9200 — on a FIXED build the escape no longer
# perturbs ordinary play, the whole match trajectory shifts, and his death
# lands ~f12760 (measured on the 14z-98 probe). A 9200 window ends before
# it and misreads "fix holds" as NEITHER (the RH-19 window trap; caught by
# this audit's own EXPECT_DEFECT=0 rehearsal).
run_leg don 13 13400
run_leg victor 03 10300
wait

# classify <tapfile>: reads the W lines (PC-attributed hp/white writes).
#   emits: DEFECT (ported-window hp:=1 write + underflow, no kill commit)
#          HEALTHY (kill commit: hp and white written 0xffff in one frame)
#          NEITHER <detail>
classify() {
    python3 - "$1" <<'PY'
import sys
ported_lo, ported_hi = 0x0BF6A0, 0x0F4000   # the placed Donovan window (atlas fragment)
allw = []            # (frame, pc, off, val)
for ln in open(sys.argv[1]):
    p = ln.split()
    if p and p[0] == "W":
        allw.append((int(p[1]), int(p[3], 16), int(p[5], 16), int(p[7], 16) & 0xFFFF))
if not allw:
    print("NEITHER no-writes (dead tap — the boot POST writes are missing)")
    sys.exit(0)
# The boot POST sweeps 0xFFFF over work RAM (~f14) and reads as a kill
# commit — the liveness trap read_tap's own header names. The POST is the
# proof the tap is armed; everything else is judged post-boot (round 1
# forms ~f2900 on this rig).
writes = [w for w in allw if w[0] > 2500]
if not writes:
    print("NEITHER no-post-boot-writes (rig never formed a match)")
    sys.exit(0)
pin1 = [w for w in writes if ported_lo <= w[1] < ported_hi and w[2] == 0xFF8450 and w[3] == 1]
under = [w for w in writes if w[2] == 0xFF8450 and w[3] > 0xFF00]
kill  = {}
for w in writes:
    if w[3] == 0xFFFF:
        kill.setdefault(w[0], set()).add(w[2])
commit = [f for f, offs in kill.items() if {0xFF8450, 0xFF8452} <= offs]
if commit:
    print(f"HEALTHY kill-commit at f{min(commit)}")
elif pin1 and under:
    print(f"DEFECT hp:=1 by PC {pin1[0][1]:06x} at f{pin1[0][0]}, underflow at f{under[0][0]}, no kill commit")
else:
    print(f"NEITHER pin1={len(pin1)} underflow={len(under)} commit=0")
PY
}

A="$(classify "$W/don/tap.txt")";    echo "== leg A (Donovan): $A"
B="$(classify "$W/victor/tap.txt")"; echo "== leg B (Victor):  $B"

case "$B" in
HEALTHY*) echo "  ok: control sees the kill commit — the tap can prove a healthy death" ;;
*) echo "FAIL: the CONTROL leg did not show the kill commit ($B) — instrument dead or"
   echo "      the rig no longer produces Victor's death; nothing else here is trustworthy"
   fail=1 ;;
esac

if [ "$fail" = 0 ]; then
    if [ "$EXPECT_DEFECT" = 1 ]; then
        case "$A" in
        DEFECT*) echo "  ok: the escape-path hp:=1 write is still present (expected until the fix lands — #103)" ;;
        *) echo "FAIL: leg A is not the frozen defect shape ($A). If the pcrel_escape_fix"
           echo "      landed, flip EXPECT_DEFECT's default and record the transition;"
           echo "      if none did, something moved unattributed (rule 6)."
           fail=1 ;;
        esac
    else
        case "$A" in
        HEALTHY*) echo "  ok: Donovan's death now takes the kill commit — the fix holds" ;;
        *) echo "FAIL: still the defect shape ($A) — the fix does not hold"; fail=1 ;;
        esac
    fi
fi

[ "$fail" = 0 ] && echo "AUDIT PASS (defect state as expected)" \
    || { echo "AUDIT FAIL"; exit 1; }
