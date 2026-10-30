#!/bin/sh
# test_hui_grab_victim.sh — the GRAB-VICTIM placement A/B gate (14z-73).
#
# WHAT: during Phobos's grab the VICTIM is placed as native vsav2 places him through the
#   hold — the victim's offset relative to the attacker tracks native (the 14z-73 fix;
#   before it the victim teleported ~109px mid-animation).
# HOW: replay 80 on native vsav2 and on the build on MAME through field_trace.lua, comparing
#   dx = p2x - p1x (which cancels the ~21px camera offset between the games) via
#   tools/check_grab_victim.py; the checker refuses a leg that never grabbed; two verdict
#   controls.
# EXPECTS: with GRAB_VICTIM_EXPECT=matches (the default) ours tracks native through the hold
#   (peak delta 0); a leg without seq 0x0E and 0x13 damage is refused; the controls fail.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lua/field_trace.lua tests/lib/jobs.sh
#   tests/replays/hui/80_hui_grab_2p.rpl tools/check_grab_victim.py tools/run_mame.sh
#   tools/setup_mame.sh tests/lib/sheet.sh
#
# SHEET: legs vs2,ours — moments: the grab onset on each leg (P1 seq 0x0E) and the hold it judges, onset+6 and onset+12 — not comparable: absolute positions (the games differ by a fixed ~21px camera offset; the gate compares the victim's offset from the attacker), each game's stage and palette, and P2's art (Victor, each game's own copy; [VSP-168])
#
# THE DEFECT — FIXED 14z-73 (grab_hold_keyframes: H's own vs2 keyframe
# block 0x0C56AA ported, row 0xBE2BA repointed; patch_index documents this
# gate guarding it at `matches`, peak Δ=0). Historical shape: during
# Phobos' grab the VICTIM's sprite teleported mid-animation — the victim
# is placed every frame by the attacker's capture-pose data; the endpoints
# looked right but the held phase did not.
#
# WHY THIS RIG WORKS WITHOUT CORNERING (retires the 14z-72 blocker). The two
# legs are different games (native vsav2 vs our vsavjw), so their ABSOLUTE
# positions differ by a fixed ~21px camera/origin offset. 14z-72 compared
# absolute victim-x, saw 21px, and declared the rig "not comparable". But the
# VICTIM OFFSET RELATIVE TO THE ATTACKER (dx = p2x - p1x) is identical on both
# legs before the grab (measured dx=42 both) — the global shift cancels. So
# replay 80, run on both legs with the same both-sides forced pick, is already
# comparable at the relative level; no corner walk is needed.
#
# WHAT IT ASSERTS.
#   1. BOTH legs actually grabbed (P1 seq 0x0E + victim took 0x13 damage).
#      A rig that whiffed measures nothing — the checker refuses to judge it.
#   2. The relative-offset A/B verdict via tools/check_grab_victim.py:
#      --expect matches (DEFAULT SINCE 14z-103; measured Δ=0 on hui46)
#      asserts ours tracks native through the hold. The default had stayed
#      on the PRE-FIX `differs` since the gate's birth at 14z-73 — the fix
#      landed the same session and every freeze ran the gate with explicit
#      =matches, so the stale default was never hit until the 14z-103
#      re-point. GRAB_VICTIM_EXPECT=differs reproduces the pre-fix defect
#      (needs a pre-14z-73 build).
#   3. VERDICT-LOGIC CONTROLS (each MUST be rejected): a "fixed" leg (ours ==
#      native) must fail --expect differs, proving the checker is not blind to
#      the divergence it claims to measure; and a "never grabbed" leg must be
#      refused, proving the connect gate works. (The 14z-71 lesson: a dead
#      instrument and a real result are the same shape from outside.)
#
# Usage: ROMDIR=... [GRAB_VICTIM_EXPECT=differs|matches] [JOBS=N] \
#            tests/test_hui_grab_victim.sh [wide-builddir]
#        (defaults to build/hui61)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   grab-victim placement A/B (14z-73): native vsav2 vs the build, replay 80
#   through field_trace.lua, comparing the victim offset RELATIVE to the
#   attacker (dx=p2x-p1x — cancels the ~21px global camera shift, so NO corner
#   rig is needed). Refuses to judge unless both legs grabbed (seq 0x0E + 0x13
#   dmg); 2 verdict controls. GRAB_VICTIM_EXPECT=matches (default since
#   14z-103; the 14z-73 grab_hold_keyframes fix is what it guards, Δ=0) |
#   =differs reproduces the pre-fix ~109px teleport (needs a pre-14z-73
#   build). Checker tools/check_grab_victim.py. Defaults hui46
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
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
   # RE-POINTED 14z-94 (GitHub #94): was build/hui25, a pre-WIDE-v1.1 set
   # (19 members, no vsw.z01/z02) — the script could not run at all.
   # Its frozen inventory may still describe the OLD build: run it
   # before trusting a green, and re-measure rather than absorb.

BUILD="${1:-build/hui61}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
EXPECT="${GRAB_VICTIM_EXPECT:-matches}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || {
    echo "FAIL: no $BUILD/rompath/vsavjw.zip (WIDE tenant build required)"; exit 1; }

MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
RPL="$REPO/tests/replays/hui/80_hui_grab_2p.rpl"
# P1 = Huitzil (0x10), P2 = Victor (0x03 on both wheels). Early window only —
# late pokes leak into the 2P commit/load (the replay-80 rule).
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
# fighter blocks: P1 $FF8400 / P2 $FF8800. x +0x10.w, y +0x14.w, facing +0x0B,
# seq +0x06, hp +0x50.w (docs/game/atlas/ram.md).
FIELDS="ff8410:w:p1x,ff8414:w:p1y,ff840b:b:p1face,ff8406:b:p1seq,ff8450:w:p1hp,ff8810:w:p2x,ff8814:w:p2y,ff880b:b:p2face,ff8806:b:p2seq,ff8850:w:p2hp,ff8832:w:p2link"

# JOBS (#334 item 2, 14z-211): the two legs are independent — each writes only $WORK/<tag> — so they go through
# tests/lib/jobs.sh's pool, JOBS at a time; default min(4, CPUs/6). A pooled leg records its runner's exit status in
# $WORK/<tag>/rc, and the legs are judged after the pool, in their old order, with the old FAIL lines.
. "$REPO/tests/lib/jobs.sh"; vs_jobs JOBS 4 6
leg() {   # $1 tag  $2 set  $3 rompath-or-empty
    tag=$1; set_=$2; rp=$3
    d="$WORK/$tag"; mkdir -p "$d/s1"
    if [ -n "$rp" ]; then MAME_ROMPATH="$rp;$ROMDIR"; export MAME_ROMPATH
    else unset MAME_ROMPATH || true; fi
    if ( cd "$d" && REPLAY="$RPL" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3130 FIELD_TO=3300 FRAMES=3400 \
      MAME_SANDBOX="$d/s1" \
      "$REPO/tools/run_mame.sh" "$set_" \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" \
      > "$d/run.out" 2>&1 ); then echo 0 > "$d/rc"; else echo 1 > "$d/rc"; fi
}

vs_pool_start "$JOBS"
echo "== native leg (vsav2)"
vs_pool_run leg native vsav2 ""
echo "== build leg ($BUILD)"
vs_pool_run leg ours vsavjw "$BUILD/rompath"
vs_pool_wait
for tag in native ours; do
    [ "$(cat "$WORK/$tag/rc" 2>/dev/null)" = 0 ] || { tail -6 "$WORK/$tag/run.out"; echo "FAIL: $tag leg"; exit 1; }
done

# THE SHEET (#291): with SHEET_OUT set, the two legs as this run played them, at the grab onset and through the hold
# the checker judges (each leg anchored on its own onset), proven on the eleven fields this run traced there. Nothing
# the gate decides changes: the checker's verdict for the sheet is a second, silent run of it.
. "$REPO/tests/lib/sheet.sh"
if sheet_on; then
    python3 "$REPO/tools/check_grab_victim.py" "$WORK" --expect "$EXPECT" --quiet > /dev/null 2>&1 && _gv="matches native (expect $EXPECT): PASS" || _gv="FAIL against expect $EXPECT"
    sheet_new grab "Phobos's Circuit Scrapper grab on Victor (replay 80): native vs2 above ours" huitzil - \
        "absolute positions (the games differ by a fixed ~21px camera offset; the gate compares the victim's offset from the attacker), each game's stage and palette, and P2's art (Victor, each game's own copy; [VSP-168])"
    sheet_leg grab native vs2 vsav2 "$ROMDIR" "$RPL" "$PK" 3400
    sheet_leg grab ours ours vsavjw "$BUILD/rompath;$ROMDIR" "$RPL" "$PK" 3400
    python3 - "$WORK" "$FIELDS" "$_gv" > "$WORK/sheet_rows.tsv" <<'PYS'
import sys
W, fields, gv = sys.argv[1], sys.argv[2], sys.argv[3]
spec = {name: "%s:%s" % (a, sz) for a, sz, name in (f.split(":") for f in fields.split(","))}
tr = {}
for leg in ("native", "ours"):
    d = {}
    for l in open(f"{W}/{leg}/field.txt"):
        t = l.split()
        if t and t[0] == "F": d[int(t[1])] = dict(kv.split("=", 1) for kv in t[2:])
    tr[leg] = d
on = {leg: min((f for f in tr[leg] if tr[leg][f].get("p1seq") == "14"), default=None) for leg in tr}
for k, lab in ((0, "the grab onset (P1 seq 0x0E)"), (6, "onset+6, in the hold"), (12, "onset+12, the end of the judged hold")):
    vals = ", ".join("%s dx=%s" % (leg, (int(tr[leg][on[leg] + k]["p2x"]) - int(tr[leg][on[leg] + k]["p1x"])) if on[leg] is not None and on[leg] + k in tr[leg] else "?") for leg in tr)
    print("moment\tgrab\to%d\t%s\t%s\t%s" % (k, lab, gv, vals))
    for leg in ("native", "ours"):
        if on[leg] is None:
            continue
        f = on[leg] + k
        s = tr[leg].get(f)
        exp = ",".join("%s=%s" % (spec[n], s[n]) for n in sorted(spec) if n in s) if s else "-"
        print("at\tgrab\to%d\t%s\t%d\t%s\t%s" % (k, leg, f, "fields" if s else "none", exp))
        # S4-D (#291): the onset's moment spans the whole hold the checker judges, onset..onset+12 (HOLD_LEN), each
        # frame proven on the fields this run traced there
        if k == 0 and s:
            print("span\tgrab\to0\t%s\t%d-%d" % (leg, f, max(x for x in range(f, f + 13) if x in tr[leg])))
PYS
    sheet_trace grab native "$WORK/native/field.txt" "$FIELDS"
    sheet_trace grab ours "$WORK/ours/field.txt" "$FIELDS"
    sheet_rows "$WORK/sheet_rows.tsv"
fi

echo
echo "== the relative-offset A/B (expect: $EXPECT)"
python3 "$REPO/tools/check_grab_victim.py" "$WORK" --expect "$EXPECT" \
    || { echo "FAIL: grab-victim A/B did not match expectation '$EXPECT'"; exit 1; }

echo
echo "== verdict-logic controls (each MUST be rejected)"
ok=1
# (a) "fixed" — ours == native. Under --expect differs this must FAIL (proves
#     the checker actually sees the divergence, i.e. is not blind).
mkdir -p "$WORK/neg_fixed/native" "$WORK/neg_fixed/ours"
cp "$WORK/native/field.txt" "$WORK/neg_fixed/native/field.txt"
cp "$WORK/native/field.txt" "$WORK/neg_fixed/ours/field.txt"
if python3 "$REPO/tools/check_grab_victim.py" "$WORK/neg_fixed" --expect differs --quiet \
       > "$WORK/neg_fixed.out" 2>&1; then
    echo "   FAIL: checker PASSED the neg_fixed (ours==native) corruption under 'differs'"; ok=0
else
    echo "   ok: neg_fixed rejected — $(grep -m1 '  - ' "$WORK/neg_fixed.out" | cut -c5-90)"
fi
# (b) "never grabbed" — ours' P1 seq never reaches 0x0E. Must be REFUSED.
mkdir -p "$WORK/neg_nograb/native" "$WORK/neg_nograb/ours"
cp "$WORK/native/field.txt" "$WORK/neg_nograb/native/field.txt"
sed 's/p1seq=14/p1seq=0/g' "$WORK/ours/field.txt" > "$WORK/neg_nograb/ours/field.txt"
if python3 "$REPO/tools/check_grab_victim.py" "$WORK/neg_nograb" --expect "$EXPECT" --quiet \
       > "$WORK/neg_nograb.out" 2>&1; then
    echo "   FAIL: checker JUDGED the neg_nograb (whiffed) corruption"; ok=0
else
    echo "   ok: neg_nograb refused — $(grep -m1 '  - ' "$WORK/neg_nograb.out" | cut -c5-90)"
fi
[ "$ok" = 1 ] || { echo "FAIL: verdict logic does not detect what it claims to"; exit 1; }

echo
echo "PASS: grab-victim A/B valid (both legs grabbed) and matches expectation '$EXPECT'"
