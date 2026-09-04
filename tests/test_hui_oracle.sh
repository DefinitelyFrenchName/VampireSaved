#!/bin/sh
# test_hui_oracle.sh — Huitzil vsav2-as-oracle behavior gate (14z-66,
# the 17/18-style battery; CLAUDE.md §4 dual-oracle for new content,
# same-emulator two-game form — the test_m2a_stage4_oracle.sh pattern
# adapted for a poke-picked tenant).
#
# ONE replay (tests/replays/hui/90_hui_oracle.rpl) runs on native vsav2
# (reference binary) and on the ported vsavjw build (WIDE binary) with
# IDENTICAL inputs and pokes. Locks (the frozen template semantics):
#   1. Match-start anchors equal.
#   2. NEUTRAL window: compare_fields --exact agrees on every mapped
#      field every frame (ROM-pointer fields skipped by design).
#   3a. HP-decrease sanity: P2 HP-change VALUE sequences equal on both
#       sides and end below 0x120.
#   3b. Comparative bound: ported-H cross-game mismatches <= the native
#       veteran control's (the UNCHANGED 18_veteran_ctl pair, stock
#       vsavj + vsav2 on the reference binary — engine-latency noise
#       measured exactly as the Donovan gate froze it).
#
# Usage: ROMDIR=... tests/test_hui_oracle.sh [rompath_dir]
#   rompath_dir default: build/hui54/rompath — the current huitzil freeze.
#   Re-pointed 14z-128 from build/hui4, which is pre-WIDE-v1.1 (19 members,
#   no vsw.z01) and cannot boot on the current binaries.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   THE vsav2-as-oracle battery (14z-66): the m2a template's 4 locks on H's
#   full moveset (anchors/neutral-exact/HP-trajectory/ comparative bound); RNG
#   determinized on both legs. ~10 min, 8 MAME runs
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/hui54/rompath}"  # re-pointed 14z-128 <- build/hui4 (19 members, no vsw.z01 — pre-WIDE-v1.1 and unbootable on current binaries; the sweep found it as "no dump files", and test_build_ref_rot could not see the $REPO/-prefixed form until the same session)
[ -d "$RPDIR" ] || { echo "no build at $RPDIR — run tools/build_donovan.sh 4 first"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"
fail=0

WIDE_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
REF_BIN="$HOME/.cache/vampire-saved/mame-ref/cps2"
[ -x "$REF_BIN" ] || REF_BIN="$(command -v mame || true)"

FIELDS="$REPO/tests/fields_m2a.tsv"
SKIP="p1_char_id,p1_hitbox_base,p2_hitbox_base,p1_ptr64,p2_ptr64,p1_anim_ptr,p2_anim_ptr,p1_word132,p2_word132"
# The RNG state ($FF80D4/D5) is poked to a fixed value on BOTH legs just
# before the intro-variant draw (his init draws +0x0A from table16[rand]
# at vs2 0x57050-0x5707C; the two GAMES tick the RNG differently through
# their menus, so cross-game draws cannot align naturally — measured:
# native drew 6, ours 2, failing the neutral lock on a field that is
# pure RNG cosmetics pre-engage). Determinizing the RNG aligns every
# RNG consumer in the battery, keeping the neutral lock STRONG instead
# of skipping the field.
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;2360:ff80d4:42;2360:ff80d5:42;2500:ff8509:09"
ANCHOR_SPEC=$(python3 -c "print(';'.join(f'{f}:ff8000-ff8300;{f}:ff8400-ff8c00' for f in range(2300,2510)))")
BAT_SPEC=$(python3 -c "print(';'.join(f'{f}:ff8000-ff8300;{f}:ff8400-ff8c00' for f in range(2510,4400,2)))")

run_windows() { # $1=set $2=replay $3=outtag $4=rompath $5=binary $6=pokes
    mkdir -p "$WORK/$3_anchor" "$WORK/$3_bat"
    POKES="$6" DUMPS="$ANCHOR_SPEC" REPLAY="$2" \
        CHECKSUM_OUT="$WORK/$3_anchor/c.log" MAME_SANDBOX="$WORK/$3_abox" \
        MAME_ROMPATH="$4" MAME_BIN="$5" "$REPO/tools/run_mame.sh" "$1" \
        -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
    POKES="$6" DUMPS="$BAT_SPEC" REPLAY="$2" \
        CHECKSUM_OUT="$WORK/$3_bat/c.log" MAME_SANDBOX="$WORK/$3_bbox" \
        MAME_ROMPATH="$4" MAME_BIN="$5" "$REPO/tools/run_mame.sh" "$1" \
        -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
}

echo "== dumps: native vsav2 / ported vsavjw / veteran controls =="
run_windows vsav2 "$REPO/tests/replays/hui/90_hui_oracle.rpl" nat "$ROMDIR" "$REF_BIN" "$PK" &
run_windows vsavjw "$REPO/tests/replays/hui/90_hui_oracle.rpl" por "$RPDIR;$ROMDIR" "$WIDE_BIN" "$PK" &
wait
run_windows vsav2 "$REPO/tests/replays/18_veteran_ctl_vsav2.rpl" cnat "$ROMDIR" "$REF_BIN" "" &
run_windows vsavj "$REPO/tests/replays/18_veteran_ctl_vsavj.rpl" cpor "$ROMDIR" "$REF_BIN" "" &
wait

echo "== 1. anchors =="
a_nat=$(python3 tools/compare_fields.py --list-anchors --fields "$FIELDS" "$WORK/nat_anchor")
a_por=$(python3 tools/compare_fields.py --list-anchors --fields "$FIELDS" "$WORK/por_anchor")
if [ "$a_nat" = "$a_por" ] && [ -n "$a_nat" ]; then
    echo "  ok: match-start anchors equal ($a_nat)"
else
    echo "FAIL: anchors differ (native '$a_nat' vs ported '$a_por')"; fail=1
fi

echo "== 2. neutral window: exact field agreement =="
if python3 tools/compare_fields.py --fields "$FIELDS" --exact \
    --skip-fields "$SKIP" "$WORK/nat_anchor" "$WORK/por_anchor" \
    > "$WORK/neutral.txt" 2>&1; then
    echo "  ok: $(tail -2 "$WORK/neutral.txt" | head -1)"
else
    echo "FAIL: neutral-window disagreement:"; head -8 "$WORK/neutral.txt"; fail=1
fi

echo "== 3a. HP-decrease sanity (battery) =="
hp_events() {
    python3 - "$1" <<'PY'
import sys, glob
d = sys.argv[1]
last, out = None, []
for p in sorted(glob.glob(f"{d}/dump_*_ff8400.bin"),
                key=lambda p: int(p.split("_")[-2])):
    b = open(p, "rb").read()
    hp = int.from_bytes(b[0x450:0x452], "big")
    if hp != last:
        out.append(hp); last = hp
print(",".join(str(h) for h in out))
PY
}
ev_nat=$(hp_events "$WORK/nat_bat")
ev_por=$(hp_events "$WORK/por_bat")
final_por="${ev_por##*,}"
if [ "$ev_nat" = "$ev_por" ] && [ "$final_por" -lt 288 ]; then
    echo "  ok: P2 HP trajectories equal and decreasing ($ev_nat)"
else
    echo "FAIL: HP trajectories: native [$ev_nat] vs ported [$ev_por]"; fail=1
fi

echo "== 3b. comparative bound vs native-veteran control =="
count_mm() {
    python3 tools/compare_fields.py --fields "$FIELDS" --exact \
        --skip-fields "$SKIP" "$1" "$2" 2>/dev/null \
        | grep -c "^MISMATCH" || true
}
mm_hui=$(count_mm "$WORK/nat_bat" "$WORK/por_bat")
mm_ctl=$(count_mm "$WORK/cnat_bat" "$WORK/cpor_bat")
if [ "$mm_hui" -le "$mm_ctl" ]; then
    echo "  ok: ported-Huitzil battery mismatches ($mm_hui) <= veteran control ($mm_ctl)"
else
    echo "FAIL: ported Huitzil diverges MORE than a native veteran ($mm_hui > $mm_ctl)"; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: Huitzil oracle gate" \
    || { echo "FAIL: Huitzil oracle gate"; exit 1; }
