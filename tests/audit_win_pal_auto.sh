#!/bin/sh
# audit_win_pal_auto.sh — THE #105 LOCK (14z-99): with AUTO selected by the
# WINNER, the 2P victory portrait screen draws a TENANT winner's portrait
# WHITE (correct shapes, white fill — the maintainer's captured surface).
# On-demand, ~8 min (3 MAME runs, 2 at a time).
#
# THE SURFACE (named from the maintainer's captures, reproduced
# deterministically): the victory screen — winner portrait + win quote —
# shown after match wins in BOTH 1P-vs-COM (PRESS START corner; leg D,
# replay 104, field-confirmed) and 2P (the loser's CONTINUE countdown;
# legs A/B, replays 103/61). An earlier "the 1P flow never shows it"
# reading is RETRACTED — it came from coarse post-KO sampling (the MAP
# screen comes AFTER the win screen) and from mash inputs pressing
# through it (game gotchas, 14z-99).
#
# THE DISCRIMINATOR (all measured on merged-m3, MAME, 14z-99):
#   replay 61  (tenant winner, no AUTO)   -> portrait COLORED
#   replay 103 (= 61 + P1 AUTO at the 2P mode menu) -> portrait WHITE,
#       and the win-pal window 0x90C2A0 holds all-0xFFFF DURING the
#       screen while the real colors arrive only AFTER it (~f5850) —
#       the upload lands LATE, it is not absent.
#   the same replay 103 on PRISTINE vsavj -> its (legacy) AUTO winner
#       renders COLORED — the defect is NOT the engine's own AUTO
#       behavior (the #102 discipline: vanilla leg first).
#   replay 104 (1P vs COM, AUTO, real-KO match win) on merged -> the 1P
#       victory screen WHITE too (leg D) — the flavor the maintainer
#       actually plays.
#   replay 105 (= 103 with P1 left on the DEFAULT cell = Demitri, a
#       LEGACY winner, inputs ENDED AT THE KO) on merged -> leg E,
#       MEASURED 14z-123 (inferred_claims row 14; the one earlier
#       attempt mashed past the KO and was VOID): see the frozen
#       verdict line. Leg E carries its own liveness — P1 +0x60.l must
#       be Demitri's base and P2 must be KO'd (white HP < 0) at f5000 —
#       so a pressed-through or unformed match cannot score.
#
# STATUS (corrected in place 14z-128): #105 SHIPPED FIXED at the 14z-99
# window and the default was flipped there — `EXPECT_WHITE` defaults to 0.
# LEG A (merged + replay 103) freezes the DEFECT while EXPECT_WHITE=1
# (the #98 discipline — flipped when the fix landed). LEG B (merged + replay
# 61) proves the same screen colored without AUTO — if B ever whites, the
# defect grew past the AUTO gate. LEG C (vanilla + replay 103) is the
# not-ours control — if C ever whites, the reading here is wrong and #105
# must be re-derived.
#
# VERDICT LOGIC: a leg's dumps are SCANNED over the whole window; the
# screen is "white" if any >=2 consecutive samples read all-0xFFFF over
# the first 16 words of 0x90C2A0, "colored" if any sample holds a real
# ramp (>=4 distinct non-white non-zero values), and DEAD otherwise —
# no single frame constant is pinned (the #10 lesson).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged22]
#        [EXPECT_WHITE=1] tests/audit_win_pal_auto.sh     (~10 min, 5 MAME runs; default is 0)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-99, GitHub #105: with AUTO selected by the WINNER, the 2P victory
#   screen draws a TENANT winner's portrait WHITE (the maintainer's captured
#   surface, reproduced from their captures). 3 legs: A merged+AUTO = the
#   frozen defect (EXPECT_WHITE=1, flip at the fix); B merged no-AUTO must
#   stay COLORED; C PRISTINE VANILLA + AUTO must stay COLORED (the not-ours
#   control — vanilla renders its AUTO winner fine, so this is ours). Verdicts
#   SCAN the dump window over 0x90C2A0 — no pinned frame constants. RECORD-
#   LEVEL fact for the fix: the win-pal colors arrive AFTER the screen (late
#   upload, not absent). LEG D = the 1P-vs-COM flavor (replay 104, real-KO
#   win, field-confirmed "one of the offending screens") — the flavor the
#   maintainer plays. Merged+legacy+AUTO MEASURED 14z-123 (leg E, replay 105 —
#   P1 on the default cell, inputs ended at the KO): COLORED, with P1 =
#   Demitri's base and P2 KO'd asserted, else DEAD. AUTO is AUTO-GUARD, not
#   autoplay; rigs for this screen END INPUTS AT THE KO and sample densely
#   (the MAP screen comes AFTER the win screen — the two 14z-99 game gotchas).
#   Rigs: replays/103_tenant_2pwin_auto (= 61 + three AUTO lines) +
#   replays/104_1p_auto_ko_win. ~10 min, 4 MAME runs.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged22}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN
EXPECT_WHITE="${EXPECT_WHITE:-0}"   # flipped at the 14z-99 window (#105 landed)

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
DF="$(python3 -c "print(';'.join(f'{f}:90c2a0-90c33f' for f in range(4600,6600,100)))")"

run_leg() { # tag set rompath replay
    d="$W/$1"; mkdir -p "$d/sbx"
    ( cd "$d" && REPLAY="$4" DUMPS="$DF" CHECKSUM_OUT="$d/out.log" \
      MAME_SANDBOX="$d/sbx" MAME_ROMPATH="$3" \
      "$REPO/tools/run_mame.sh" "$2" \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/mame.log" 2>&1 ) &
}
run_leg A vsavjw "$REPO/$BUILD/rompath;$ROMDIR" "$REPO/tests/replays/103_tenant_2pwin_auto.rpl"
run_leg C vsavj  "$ROMDIR"                      "$REPO/tests/replays/103_tenant_2pwin_auto.rpl"
wait
run_leg B vsavjw "$REPO/$BUILD/rompath;$ROMDIR" "$REPO/tests/replays/61_tenant_2pwin.rpl"
# leg E (14z-123): merged + LEGACY winner + AUTO, inputs ended at the KO;
# its dump set adds the two fighter blocks for the liveness check.
d="$W/E"; mkdir -p "$d/sbx"
( cd "$d" && REPLAY="$REPO/tests/replays/105_legacy_2pwin_auto.rpl" DUMPS="$DF;3000:ff8400-ff847f;5000:ff8800-ff887f" CHECKSUM_OUT="$d/out.log" MAME_SANDBOX="$d/sbx" MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/mame.log" 2>&1 ) &
# leg D: the 1P-vs-COM flavor — forced-pick Phobos + early-round
# both-words weakening pokes (audit_kill_poke_shape: never the 2-byte
# shape, never near a corpse); the win screen sits later in this flow,
# so leg D carries its own dump window.
PK_D="1200:ff8782:10;1300:ff8782:10;1400:ff8782:10;1500:ff8782:10;1700:ff8782:10;1900:ff8782:10;2100:ff8782:10"
for f in 3100 3160 3220 5200 5260 5320; do PK_D="$PK_D;$f:ff8850:00050005"; done
DF_D="$(python3 -c "print(';'.join(f'{f}:90c2a0-90c33f' for f in range(5400,6600,100)))")"
d="$W/D"; mkdir -p "$d/sbx"
( cd "$d" && REPLAY="$REPO/tests/replays/104_1p_auto_ko_win.rpl" POKES="$PK_D"   DUMPS="$DF_D" CHECKSUM_OUT="$d/out.log" MAME_SANDBOX="$d/sbx"   MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR"   "$REPO/tools/run_mame.sh" vsavjw   -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/mame.log" 2>&1 ) &
wait

classify() {
    python3 - "$W/$1" <<'PY'
import glob, re, struct, sys
d = sys.argv[1]
runs, white_run, colored = 0, 0, False
for f in sorted(glob.glob(f"{d}/dump_*_90c2a0.bin"),
                key=lambda p: int(re.search(r'dump_(\d+)_', p).group(1))):
    b = open(f, "rb").read()
    w = [struct.unpack(">H", b[i:i+2])[0] for i in range(0, 32, 2)]
    if all(x == 0xFFFF for x in w):
        runs += 1
        white_run = max(white_run, runs)
    else:
        runs = 0
        vals = set(x for x in w if x not in (0xFFFF, 0xF000, 0x0000))
        if len(vals) >= 4:
            colored = True
print("WHITE" if white_run >= 2 else "COLORED" if colored else "DEAD")
PY
}

A="$(classify A)"; B="$(classify B)"; C="$(classify C)"; D="$(classify D)"; E="$(classify E)"
# leg E liveness: Demitri's base on P1 (bases.tsv row 0x01, byte-identical
# to vanilla's table) and a KO'd P2 at f5000 — else the leg is DEAD.
E_LIVE="$(python3 - "$W/E" <<'PY'
import sys
d = sys.argv[1]
try:
    p1 = open(f"{d}/dump_3000_ff8400.bin", "rb").read()
    p2 = open(f"{d}/dump_5000_ff8800.bin", "rb").read()
except OSError:
    print("DEAD (no fighter-block dumps)"); sys.exit(0)
base = int.from_bytes(p1[0x60:0x64], "big")
white = int.from_bytes(p2[0x52:0x54], "big", signed=True)
ok = base == 0x00093B6A and white < 0
print(("LIVE" if ok else "DEAD") + f" (P1 +0x60.l {base:#x}, P2 white HP {white} at f5000)")
PY
)"
case "$E_LIVE" in LIVE*) ;; *) E="DEAD";; esac
echo "  leg A (merged 2P + AUTO tenant winner):    $A"
echo "  leg B (merged 2P + no-AUTO tenant winner): $B"
echo "  leg C (vanilla + AUTO winner):             $C"
echo "  leg D (merged 1P-vs-COM + AUTO tenant):    $D"
echo "  leg E (merged 2P + AUTO LEGACY winner):    $E  [$E_LIVE]"

[ "$B" = COLORED ] || { echo "FAIL: leg B not colored ($B) — the no-AUTO control died or the defect grew past the AUTO gate"; fail=1; }
[ "$C" = COLORED ] || { echo "FAIL: leg C not colored ($C) — vanilla shows it too; the not-ours premise is dead, re-derive #105"; fail=1; }
# FROZEN 14z-123: a LEGACY AUTO winner on the merged build renders COLORED —
# the tenant-only defect never touched the legacy path (superset check).
[ "$E" = COLORED ] || { echo "FAIL: leg E not colored ($E) — a LEGACY AUTO winner on the merged build; if DEAD the rig died or pressed through, if WHITE the defect reaches legacy content: rule 6"; fail=1; }
if [ "$EXPECT_WHITE" = 1 ]; then
    [ "$A" = WHITE ] && echo "  ok: the frozen defect (2P) — AUTO tenant winner draws WHITE (#105 open)" \
        || { echo "FAIL: leg A is $A — if a fix landed, flip EXPECT_WHITE; if none did, rule 6"; fail=1; }
    [ "$D" = WHITE ] && echo "  ok: the frozen defect (1P) — the flavor the maintainer plays" \
        || { echo "FAIL: leg D is $D — the 1P flavor moved independently of 2P; re-measure"; fail=1; }
else
    [ "$A" = COLORED ] && echo "  ok: AUTO tenant winner colored (2P) — the fix holds" \
        || { echo "FAIL: leg A is $A — the fix does not hold"; fail=1; }
    [ "$D" = COLORED ] && echo "  ok: AUTO tenant winner colored (1P)" \
        || { echo "FAIL: leg D is $D — the fix does not hold on the 1P flavor"; fail=1; }
fi

[ "$fail" = 0 ] && echo "AUDIT PASS (defect state as expected)" || { echo "AUDIT FAIL"; exit 1; }
