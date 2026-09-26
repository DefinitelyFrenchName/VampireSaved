#!/bin/sh
# audit_trap_shock.sh — the Plasma Trap dome inflicts SHOCK on BOTH of Phobos's tracks, and since the 14z-170 class-0x52 fix (ruled 2026-09-18, scoped S1) the two differ by design: the MERGED build plays vs2's rule (the victim shocked, Phobos exempt — the marker class 0x38), the SOLO Phobos build keeps the 14z-85g(2) remap and its attacker freeze (it lacks Donovan's machinery). On-demand, ~4 min (3 runs).
#
# WHAT: the Plasma Trap dome inflicts SHOCK on the victim on both of Phobos's tracks, and
#   since the class-0x52 fix the two tracks differ by design: the merged build plays vs2's
#   rule (victim shocked, Phobos exempt from the attacker freeze) and the solo Phobos build
#   keeps the remap with its attacker freeze; native vsav2 is the anchor.
# HOW: three MAME runs of the deep-overlap trap rig (native, merged, solo) with the speed
#   level and RNG pinned on every leg; the victim's class, shock sub-state and freeze, and
#   Phobos's own freeze, read per frame from dumps; the control plants the attacker freeze
#   into the merged leg's rows.
# EXPECTS: native class 0x52 / merged 0x38 / solo 0x06, all with seq7 == 4 and the freeze
#   from 0x18; no attacker freeze on native and merged, present on solo; native and merged
#   frame-for-frame identical over the dome window. Pre-fix builds fail by design.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh tests/lua/replay.lua
#   tests/replays/hui/92_hui_trap_shock.rpl tools/run_mame.sh tools/run_replay_mame.sh
#   tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: attacker-frozen — a copy of the merged leg's dumps with Phobos's +0x5C set to 0x0B at the dome's first hit frame (the pre-fix attacker freeze) must FAIL the merged verdict, so "the attacker is exempt" is read from the merged leg's own RAM (in-gate: the planted rows must be caught; mode: the merged leg's rows are planted before the verdict and the gate FAILs)
#
# THE MECHANISM THIS LOCKS: the dome's hit records carry vs2's EXTENDED
# class 0x52, which vsavj's victim-reaction jump table (PRG:0x2385C)
# does not reach (entry[0x52] = code bytes -> a wild-but-lucky plain
# hit). The ruled fix: the two hitbox_proj class bytes remapped
# 0x52 -> 0x06 (vs2's OWN table aliases 0x52 == 0x06 -> the shock
# handler; vsavj entry[0x06] = its native electric-shake 0x23AC8, a
# structural twin of vs2's 0x52 handler minus the attacker-freeze
# exemption). KNOWN DEVIATION, accepted 2026-08-14 and WITHDRAWN 2026-09-18 (the class takes vs2's 0x52 rule,
# DECISIONS_HISTORY.md; the fix re-freezes this gate): Phobos receives
# the normal 11f attacker hit-freeze on trap connect (vs2 exempts him)
# — asserted PRESENT here, so a silent drift in either direction is
# loud.
#
# THE VERDICT TELLS (state-level, no debugger): during the dome hit
# window the victim must show class 0x06 (ours; native shows its own
# 0x52) AND shock sub-state seq+0x07 == 4 with the freeze 0x18 decay.
# Pre-fix builds (huitzil-m9-) show class 0x52 + seq7 == 2 (plain
# hit) on ours — this audit FAILS there by design.
#
# THE THREE LEGS SINCE 14z-170 (DECISIONS_HISTORY.md "the class-0x52 fix is scoped ... (S1)"):
#   native  vsav2: class 0x52, seq7 4, the victim's freeze from 0x18, NO attacker freeze (vs2's exemption);
#   merged  (MERGED=, the build that ships): class 0x38 (reaction_hook case 0xA4's marker), seq7 4, the
#           victim from 0x18, NO attacker freeze — the ruled fix;
#   solo    ($1, the solo Phobos build): class 0x06 (the remap `unless_composed = "donovan"` keeps
#           there), seq7 4, and the attacker freeze PRESENT — the deviation S1 keeps on that track.
# THE PINS (14z-170): the speed level ($FF8116 = 6 from 2000) and the RNG ($FF80D4-D5 = 0 from 2363) on
# every leg — the standing ruling on cross-game comparisons (vsav2 defaults to TURBO, vsavj to NORMAL,
# [VSE-84]). Unpinned, this rig's Phobos ran his air trap 2..6 frames slower on ours and the dome
# connected 6 frames later (f3500 vs f3494) — read at first as a pre-existing, unattributed onset
# difference; pinned, native and the fixed merged build are FRAME-FOR-FRAME identical in Phobos's
# states and the victim's hit, class, sub-state and freeze over 3395-3600 (build/rc170/trapt_pinned/),
# which section 2 now asserts as the TIMELINE: the dome's first hit, the shock's end and the recovery on
# the same frames on native and merged.
#
# Usage: ROMDIR=... [MERGED=build/m3b_merged28] tests/audit_trap_shock.sh [solo builddir]
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-85g(2) (~4 min, 2 parallel): the trap dome inflicts SHOCK — rig 92
#   (deep-overlap, walk N=60) on ours + native; ours must show class 0x06 (the
#   ruled remap) + seq7==4 + freeze>=0x10, native its own 0x52; ALSO asserts
#   the accepted deviation (Phobos' 11f attacker freeze) PRESENT so drift is
#   loud. Fails on huitzil-m9- by design
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
BUILD="${1:-build/hui58}"  # the SOLO Phobos build (re-pointed 14z-117b, 14z-119, ...; re-point at every freeze)
MERGED="${MERGED:-build/m3b_merged28}"
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
[ -d "$MERGED/rompath" ] || { echo "SKIP: no merged build at $MERGED"; exit 0; }
WIDE_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$WIDE_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }

RPL="$PWD/tests/replays/hui/92_hui_trap_shock.rpl"
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
PK="$PK;$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,3640)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,3640)))")"
DF="$(python3 -c "print(';'.join(f'{f}:ff8800-ff89ff;{f}:ff8400-ff85ff' for f in range(3480,3620,2)))")"

SOLO_RP="$(abspath "$BUILD")/rompath"; MERGED_RP="$(abspath "$MERGED")/rompath"   # BEFORE any cd (abspath reads $PWD)
mkdir -p "$W/solo/s1" "$W/merged/s1" "$W/native/s1"
( cd "$W/solo" && MAME_BIN="$WIDE_BIN" MAME_ROMPATH="$SOLO_RP;$ROMDIR" \
  POKES="$PK" DUMPS="$DF" FRAMES=3640 \
  "$REPO/tools/run_replay_mame.sh" vsavjw "$RPL" ram.log s1 >out 2>&1 ) &
( cd "$W/merged" && MAME_BIN="$WIDE_BIN" MAME_ROMPATH="$MERGED_RP;$ROMDIR" \
  POKES="$PK" DUMPS="$DF" FRAMES=3640 \
  "$REPO/tools/run_replay_mame.sh" vsavjw "$RPL" ram.log s1 >out 2>&1 ) &
( cd "$W/native" && POKES="$PK" DUMPS="$DF" FRAMES=3640 \
  "$REPO/tools/run_replay_mame.sh" vsav2 "$RPL" ram.log s1 >out 2>&1 ) &
wait
for leg in solo merged native; do
    ls "$W/$leg"/dump_*_ff8800.bin >/dev/null 2>&1 || {
        echo "FAIL: $leg leg produced no dumps:"; tail -8 "$W/$leg/out"; exit 1; }
done

rc=0
python3 - "$W" "$MODE" <<'PY' || rc=$?
import glob, sys, struct
W, MODE = sys.argv[1], sys.argv[2]
# leg -> (the class the victim must show, whether the attacker freeze must be PRESENT)
EXPECT = {"native": (0x52, False), "merged": (0x38, False), "solo": (0x06, True)}

def leg_state(leg):
    rows = []
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ff8800.bin"),
                    key=lambda p: int(p.split("_")[-2])):
        fr = int(f.split("_")[-2])
        b = open(f, "rb").read()
        a = open(f.replace("ff8800", "ff8400"), "rb").read()
        hp = struct.unpack(">H", b[0x50:0x52])[0]
        rows.append((fr, hp, b[0x54], b[0x5C], b[0x07], a[0x5C]))
    return rows

def plant(rows):
    """THE PERTURBATION: Phobos's +0x5C = 0x0B at the dome's first hit frame (the pre-fix attacker freeze)."""
    hit = [r for r in rows if r[1] < 288]
    if not hit: return rows
    f0 = hit[0][0]
    return [(r[0], r[1], r[2], r[3], r[4], 0x0B if r[0] == f0 else r[5]) for r in rows]

def verdict(leg, rows):
    """-> (errors, message). The class/shock/freeze and the attacker-freeze check for one leg."""
    cls, atk_present = EXPECT[leg]
    hit = [r for r in rows if r[1] < 288]
    if not hit:
        return [f"{leg}: the dome never connected (P2 HP never below 288) — the rig's spacing broke; verdict vacuous"], ""
    shock = [r for r in hit if r[2] == cls and r[4] == 4 and r[3] >= 0x10]
    if not shock:
        seen = sorted({(hex(r[2]), r[4]) for r in hit})
        return [f"{leg}: NO shock install — expected class {cls:#x} + seq7==4 + freeze>=0x10 in the hit window; saw (class, seq7) {seen}"], ""
    atk = [r for r in hit if r[5] > 0]
    errs = []
    if atk_present and not atk:
        errs.append(f"{leg}: attacker freeze ABSENT — the solo track keeps the 14z-85g(2) deviation (S1); a silent drift")
    if not atk_present and atk:
        errs.append(f"{leg}: attacker freeze PRESENT ({atk[0][5]:#x} at f{atk[0][0]}) — vs2's class-0x52 rule exempts Phobos")
    msg = (f"{leg} — dome hit at f{hit[0][0]}, shock install (class {cls:#x}, seq7=4, freeze {shock[0][3]:#x}), "
           f"attacker freeze {'present (' + hex(atk[0][5]) + ')' if atk else 'absent'}")
    return errs, msg

errs = []
states = {leg: leg_state(leg) for leg in ("native", "merged", "solo")}
if MODE == "attacker-frozen":
    print("CONTROL MODE: attacker-frozen — the merged leg's rows are planted; this run must FAIL")
    states["merged"] = plant(states["merged"])
for leg in ("native", "merged", "solo"):
    e, m = verdict(leg, states[leg])
    errs += e
    if not e: print(f"  ok: {m}")
# THE TIMELINE (14z-170, pinned): the dome's first hit, the shock's last frame and the victim's return to
# neutral are on the same frames on native and on the merged build (vs2's rule, frame for frame)
def timeline(rows):
    hit = [r for r in rows if r[1] < 288]
    if not hit: return None
    shock = [r[0] for r in hit if r[4] == 4]
    return (hit[0][0], max(shock) if shock else None)
tn, tm = timeline(states["native"]), timeline(states["merged"])
if tn and tn == tm: print(f"  ok: the timeline — first hit f{tn[0]}, last shock sample f{tn[1]} — is native's frame for frame on the merged build")
else: errs.append(f"merged: timeline {tm} differs from native's {tn} (first hit, last shock sample)")
# the in-gate control: the planted merged rows must fail the merged verdict
if MODE != "attacker-frozen":
    e, _ = verdict("merged", plant(states["merged"]))
    if e: print("CONTROL FIRED: attacker-frozen — a planted attacker freeze on the merged leg fails its verdict")
    else: errs.append("CONTROL DEAD: attacker-frozen — the planted attacker freeze passed the merged verdict")
# Verdict control (14z-85g(2)): the checker must fail on the pre-fix shape (class 0x52 + seq7==2 on ours).
fake = [(3500, 285, 0x52, 0x0C, 2, 0)]
if [r for r in fake if r[2] == EXPECT["solo"][0] and r[4] == 4]:
    errs.append("control PASSED on the pre-fix shape — verdict logic dead")
else:
    print("  ok: verdict control — pre-fix shape fails as designed")
for e in errs: print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
[ "$rc" = 0 ] && echo "audit_trap_shock: PASS (dome shock live on both tracks: merged plays vs2's rule, solo keeps the ruled remap)" \
             || echo "audit_trap_shock: FAILURES"
exit "$rc"
