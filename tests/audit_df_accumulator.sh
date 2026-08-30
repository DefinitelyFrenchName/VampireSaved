#!/bin/sh
# audit_df_accumulator.sh — THE +0x161 ACCUMULATOR IS SASQUATCH'S DARK FORCE
# ARMOR (measured 14z-123; inferred_claims row 1).
#
# WHY. 14z-121 decoded the attack record's +0x1C from its one reader (vs2
# 0x16B70 / vsavj 0x182B4) as "added into the victim's +0x161 while +0x15E is
# armed, against the bank row byte15b = 60" and, from the DF-table block
# boundaries, read the arming state as AULBATH's — never observed live. The
# 14z-123 measurement: the 0x200-arming state (vsavj 0x47E60, vs2 0x48F9C) is
# ROW 0x0A of dispatch_16 (`0xBF31A`, the per-character seq-0x16 DF activation
# dispatch) — SASQUATCH — and it fires. Aulbath's own row (0x45D8A) arms the
# OTHER family (0x7FFF with +0x18F = 1: full armor, no accumulator).
#
# WHAT IT ASSERTS (pristine vsavj from $ROMDIR, MAME; four legs in parallel):
#   armor  (LP+LK activation, stocks poked): DF enters ($FF802E = 1, never
#          inferred from the fighter block); when the activation chain ends
#          P1's +0x15E reads 0x1FF (armed 0x200, counted down by the timers
#          block) and +0x18F stays 0; every armored contact ADDS the record's
#          +0x1C to +0x161 (Victor cr.LP 20 / cr.MP 30 / cr.HP 40) and reloads
#          the decay +0x162 = 240, with NO reaction (seq unchanged, +0x54
#          unwritten); the contact that carries the sum PAST 60 reacts
#          normally (+0x54 = class, seq 2) and clears +0x161/+0x162; the next
#          contact starts a fresh sum; DF end clears +0x15E. The per-contact
#          shape is FROZEN in tests/expected/df_accumulator.txt.
#   hphk   (HP+HK activation): DF enters, +0x15E and +0x161 stay 0 for the
#          whole mode, every contact reacts — the un-armed sub-state 4.
#   nodf   (no stocks — the pair downgrades to one button): +0x15E and +0x161
#          stay 0; the must-fire negative for the instrument.
#   merged (the same armor leg on the current merged WIDE build): the field
#          trace is BYTE-IDENTICAL to the pristine armor leg — legacy content
#          under the superset invariant, checked here for free.
# The checker is ground-truth tested against a perturbed copy of the armor
# trace ([VSP-19]): a sum that fails to clear past 60 must be reported.
#
# NOT MEASURED HERE, stated: vsav2 has no Sasquatch (cut from VS2); its row
# 0x0A of the twin table 0xD94B8 still points at the residue code 0x48F9C.
# The forced pick 0x0A on vsav2 loads whatever that engine keeps in the slot
# and armed nothing (14z-123 leg r2_v2_armor) — not a Sasquatch measurement.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged21] [FREEZE=1]
#        tests/audit_df_accumulator.sh          (~3 min, four legs in parallel)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged21}"
WIDE_MAME="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
EXP="tests/expected/df_accumulator.txt"
RPL="$REPO/tests/replays/df/105_df_sas_armor.rpl"
[ -f "$ROMDIR/vsavj.zip" ] || { echo "SKIP: no $ROMDIR/vsavj.zip"; exit 0; }
command -v mame >/dev/null || { echo "SKIP: no mame on PATH"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
FIELDS="ff802e:b:df,ff855e:w:p1_15e,ff8561:b:p1_161,ff8562:b:p1_162,ff858f:b:p1_18f,ff8454:b:p1_54,ff8450:w:p1_hp,ff8406:b:p1seq,ff8407:b:p1_sub,ff8522:w:p1_122"
PKB="1400:ff8782:0a;1450:ff8782:0a;1500:ff8782:0a;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
STK=";3100:ff8509:03;3120:ff8509:03"
sed 's/^3260-3263 p1=14/3260-3263 p1=36/' "$RPL" > "$W/hphk.rpl"
grep -q 'p1=36' "$W/hphk.rpl" || { echo "FAIL: the HP+HK edit did not apply"; exit 1; }

leg() { # name set rompath mamebin pokes rpl
    d="$W/$1"; mkdir -p "$d/sb"
    ( cd "$d" && MAME_BIN="$4" MAME_ROMPATH="$3" MAME_SANDBOX="$d/sb" REPLAY="$6" POKES="$5" \
      FIELDS="$FIELDS" FIELD_OUT="$d/field.txt" FIELD_FROM=3000 FIELD_TO=4600 FRAMES=4650 \
      "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
}
echo "== audit_df_accumulator: Sasquatch's DF armor on pristine vsavj (+ merged control) =="
leg armor vsavj "$ROMDIR" mame "$PKB$STK" "$RPL"
leg hphk  vsavj "$ROMDIR" mame "$PKB$STK" "$W/hphk.rpl"
leg nodf  vsavj "$ROMDIR" mame "$PKB" "$RPL"
if [ -f "$BUILD/rompath/vsavjw.zip" ] && [ -x "$WIDE_MAME" ]; then
    leg merged vsavjw "$REPO/$BUILD/rompath;$ROMDIR" "$WIDE_MAME" "$PKB$STK" "$RPL"; MERGED=1
else
    echo "  note: merged control skipped (no $BUILD/rompath/vsavjw.zip or WIDE MAME)"; MERGED=0
fi
wait

python3 tools/df_accumulator_check.py --legs "$W" --render > "$W/got.txt"; rc=$?
[ "$rc" -eq 0 ] || { echo "FAIL: leg analysis rc=$rc"; sed 's/^/    /' "$W/got.txt"; exit 1; }
if [ "$MERGED" = 1 ]; then
    if cmp -s "$W/armor/field.txt" "$W/merged/field.txt"; then
        echo "  ok    merged build: field trace byte-identical to pristine vsavj (superset)"
    else
        echo "  FAIL  merged build: field trace differs from pristine vsavj"; diff "$W/armor/field.txt" "$W/merged/field.txt" | head -10; exit 1
    fi
fi
if [ "${FREEZE:-0}" = 1 ]; then cp "$W/got.txt" "$EXP"; echo "  FROZE  $EXP ($(wc -l < "$EXP" | tr -d ' ') lines)"; fi
[ -f "$EXP" ] || { echo "FAIL: no expectation $EXP (run with FREEZE=1 after reviewing the printed lines)"; cat "$W/got.txt"; exit 1; }
if diff "$EXP" "$W/got.txt" > "$W/diff.txt"; then
    echo "  ok    $(wc -l < "$EXP" | tr -d ' ') frozen lines match"; sed 's/^/        /' "$W/got.txt"
else
    echo "  FAIL  frozen expectation differs:"; sed 's/^/        /' "$W/diff.txt"; exit 1
fi
# [VSP-19] the checker against a perturbed armor trace: a sum past 60 that did
# not clear must be reported as a deviation.
python3 tools/df_accumulator_check.py --selftest "$W/armor/field.txt" || { echo "FAIL: checker self-test"; exit 1; }
echo "PASS audit_df_accumulator"
