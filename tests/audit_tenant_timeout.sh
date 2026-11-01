#!/bin/sh
# audit_tenant_timeout.sh — THE TIMEOUT JUDGE, per tenant (14z-104; the side of the down read from $FF8105 since
# 14z-215, GitHub #342; the time over read as the MATCH's end since 14z-215, GitHub #343).
#
# WHAT: the timeout judge per tenant: when the timer runs out the down goes to the HP leader,
#   the TIME OVER ENDS THE MATCH ($FF810E 0xFF) and the next match spawns live — the judge's
#   other entrance, which a ported row could starve as #103 did the KO path. The game has ONE
#   timer: "on standard dip switch settings, you need two downs to win HOWEVER, there is only
#   one timer so TIME OVER ends the match, not the round. Think of Vampire savior as having
#   only one round but you get a new full life bar after your first down" (the maintainer,
#   2026-10-31, #343). ~~the round advances and round 2 spawns~~ RETRACTED 14z-215 (#343): the
#   refill the gate read as round 2 was the NEXT MATCH's, after $FF810E = 0xFF. The SIDE of the down is the code
#   $FF8105/$FF810C (1 = P1 won, 2 = P2 won; PRG:0x00988E / PRG:0x00989C); $FF8120 is the
#   winner's PERFECT test (0xFF at PRG:0x0098DC, then 0x01 at PRG:0x0098EC when the winner's
#   white HP +0x52 is below $FF815A's full value), checked under that name — it is not the side
#   (#342: 14z-104 read it as the side on legs that confounded side with damage).
# HOW: the judge/01_timeout_lead rig on MAME (one jab for the lead, then idle) with the
#   round timer $FF8109 poked to 3; the timer, $FF8105, $FF810C, $FF8120, $FF810E, both HP
#   words and both character ids ($FF8782/$FF8B82) are read from field traces. Legacy Demitri legs: `ctl` (the instrument control),
#   `inv` (P1 HP poked below the dummy's: judged to P2, who took the jab), `p2full` (the jab
#   line removed in-gate and P1 HP poked low: a P2 win at FULL HP) and `p1hurt` (P1 HP poked to
#   286 after the jab: a P1 win by 2, HURT). The last two separate the side from the damage.
# EXPECTS: per leg the timer reaches 0, $FF810E goes 0 -> 1 at the down, the match ENDS ($FF810E
#   0xFF) with no respawn before it ($FF810E 0 with both HP 0x120), the next match spawns live
#   after it (both HP 0x120 with $FF810E 1, a new opponent in the loser's slot, the timer 99),
#   END clean, and at the down side/perfect = ctl, don, hui, pyr 1/0xFF; inv 2/0x01; p2full
#   2/0xFF; p1hurt 1/0x01. Stage guards: every leg but p2full lands the jab (p2hp below 0x120
#   before the down), p2full's P2 is never hit, p1hurt's P1 is below full at the down. A red on
#   `ctl` means the instrument moved.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lua/field_trace.lua tests/lib/controls.sh
#   tests/replays/judge/01_timeout_lead.rpl tools/run_mame.sh tools/setup_mame.sh
#
# SHEET: none — runs our build only, judged on its own; no reference leg and no frozen reference values
#
# MUST-FIRE: known-bad: side-by-perfect — the side judged by the retracted 14z-104 reading of $FF8120 (0xFF = P1 won, 0x01 = P2 won) instead of $FF8105/$FF810C must fail on the p2full and p1hurt legs, so the gate tells the side of the down from the winner's damage (in-gate; as a mode the side check reads $FF8120 and the gate FAILs)
# MUST-FIRE: known-bad: perfect-by-side — the perfect flag expected from the side (0xFF when P1 won, 0x01 when P2 won: the 14z-104 expectation) must fail on the p2full and p1hurt legs, so the $FF8120 check measures the winner's damage, not the side (in-gate; as a mode $FF8120 is expected from the side and the gate FAILs)
# MUST-FIRE: known-bad: round2-before-end — a respawn with both HP at 0x120 required between the down and the match end ($FF810E 0xFF), the retracted "round 2 spawns" reading, must fail on every leg, so the gate tells a time over that ends the match from one that ends a round (in-gate: the retracted predicate, the first frame with $FF810E >= 1 and both HP 0x120, must land after the match end on every leg; as a mode the refill is required before the end and the gate FAILs)
#
# NOT COVERED: $FF8120's third outcome, 0x00 written at PRG:0x0098FC when $FF8108 differs from
#   the winner's +0x3B0, is reached by no leg; a tied-HP timeout is not rigged; the tenants are
#   judged only as P1 winners at full HP (no tenant wins a timeout as P2 or hurt).
#
# §4 mandates timeout coverage per ported character; until this audit the
# tenants' timeout wins were FIELD-CONFIRMED only (maintainer, 14z-101)
# with no rerunnable instrument. The sharp risk is #103's class: the
# round judge reads per-character state (white HP sign, per-char dispatch
# rows), and a ported row that starves the judge produced a real shipped
# stall once. A timeout is the judge's OTHER entrance.
#
# RIG: tests/replays/judge/01_timeout_lead.rpl — P1 (poke-chosen) lands
# one jab for the HP lead, both sides idle, and the audit pokes the round
# timer ($FF8109) to 3 so the timeout fires in-window (rig-clean: no
# input feeds the judge). The p2full leg's script is that replay without
# its jab line (derived in-gate; the edit is asserted).
#
# WHAT IT ASSERTS, per leg:
#   1. the timer genuinely reaches 0 in the trace (the poke landed and
#      the countdown ran — a leg that never times out measures nothing);
#   2. the judge AWARDS THE DOWN TO THE HP LEADER: the side codes
#      $FF8105/$FF810C at the first settled frame equal the leg's leader
#      (1 = P1, 2 = P2; measured 14z-118 on vanilla ctl/inv, 14z-215 on
#      seven pristine legs of both sides, hurt and unhurt — #342);
#      ~~round-winner code $FF8120 == 0xFF (P1 won) — measured 14z-104:
#      0xFF on a P1-lead timeout, 0x01 on a P2-lead timeout~~ RETRACTED
#      14z-215 (#342): $FF8120 is the winner's PERFECT test; 14z-104's
#      P1 winner was unhurt and its P2 winner had taken the jab;
#   3. the winner's PERFECT flag $FF8120 = 0xFF when the winner was never
#      hit, 0x01 when the winner was hurt;
#   4. the TIME OVER ENDS THE MATCH (#343): $FF810E goes 0 -> 1 at the
#      down; `end`, the first frame after it with $FF810E == 0xFF, exists;
#      no frame between the down and `end` reads $FF810E 0 with both HP at
#      0x120 (no round 2); and the NEXT MATCH spawns live — `refill`, the
#      first frame after `end` with both HP 0x120 and $FF810E 1, exists,
#      with a new id in the loser's slot and the timer at 99 — no stall.
#      ~~the round ADVANCES ($FF810E 0 -> 1) and round 2 spawns live (both
#      HP words refill to 0x120) — the match continues~~ RETRACTED 14z-215
#      (#343): that refill came after $FF810E = 0xFF, the next match's;
#   5. the run is guarded END-clean (crash/reset/exception fails).
#
# CONTROLS:
#   - leg `ctl` (Demitri) is the LEGACY CONTROL: the same rig through
#     vanilla judge rows — if it fails, the instrument moved, and no
#     tenant verdict is trustworthy.
#   - leg `inv` (Demitri, P1 HP poked BELOW the dummy's) must be judged
#     the OTHER way ($FF8105 == 2): the side code discriminates.
#   - legs `p2full` and `p1hurt` break the side/damage confound; the two
#     MUST-FIRE controls above prove each check tells them apart.
#   - `round2-before-end` (#343): the retracted round-2 predicate run
#     beside the new one must land after the match end on every leg.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged32] [JOBS=4]
#        tests/audit_tenant_timeout.sh          (~7 legs x ~2 min, JOBS at a time)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
JOBS="${JOBS:-4}"
BUILD="${BUILD:-build/m3b_merged32}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)" || { echo "FAIL: audit_tenant_timeout — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT
RPL="$REPO/tests/replays/judge/01_timeout_lead.rpl"
# p2full's script: the replay without its jab, so P2 is never hit (#342)
grep -qx '3010-3012 p1=1' "$RPL" || { echo "FAIL: the jab line '3010-3012 p1=1' is not in $RPL — the p2full edit cannot apply"; exit 1; }
grep -vx '3010-3012 p1=1' "$RPL" > "$W/nojab.rpl"
FIELDS="ff8109:b:timer,ff8120:b:perfect,ff810e:b:rounds,ff8450:w:p1hp,ff8850:w:p2hp,ff8105:b:side05,ff810c:b:side0c,ff8782:b:p1id,ff8b82:b:p2id"

n=0
leg() {  # name  p1id  extra-pokes  [replay]
    n_="$1"; id="$2"; extra="$3"; r="${4:-$RPL}"
    d="$W/$n_"; mkdir -p "$d/sb"
    PK="1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3300:ff8109:03$extra"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$r" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3300 FIELD_TO=5200 FRAMES=5250 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
    n=$((n + 1)); [ $((n % JOBS)) -eq 0 ] && wait
    return 0
}
leg ctl 01 ""
leg don 13 ""
leg hui 10 ""
leg pyr 11 ""
# the inverted control: P1's real+white HP poked below the dummy's 284
leg inv 01 ";3200:ff8450:0080;3210:ff8452:0080"
# the confound legs (#342): a P2 win at full HP (no jab), a P1 win hurt (286 against the jabbed 284)
leg p2full 01 ";3200:ff8450:0080;3210:ff8452:0080" "$W/nojab.rpl"
leg p1hurt 01 ";3200:ff8450:011e;3210:ff8452:011e"
wait

python3 - "$W" "$MODE" <<'PY' || { echo "FAIL: tenant timeout audit"; exit 1; }
import sys
W, mode = sys.argv[1], sys.argv[2]
# leg -> (side, perfect): side = $FF8105/$FF810C at the down (1 = P1 won, 2 = P2 won);
# perfect = $FF8120 (0xFF the winner never hit, 0x01 the winner hurt) — #342
WANT = {"ctl": (1, 0xFF), "don": (1, 0xFF), "hui": (1, 0xFF), "pyr": (1, 0xFF),
        "inv": (2, 0x01), "p2full": (2, 0xFF), "p1hurt": (1, 0x01)}
CONFOUND = ("p2full", "p1hurt")
RETRACTED = {0xFF: 1, 0x01: 2}          # the 14z-104 reading of $FF8120 as the side
BY_SIDE = {1: 0xFF, 2: 0x01}            # the 14z-104 expectation of $FF8120 from the side
# leg -> (P1 id, P2 id) as poked (hex): the next match's opponent replaces the loser's id (#343)
IDS = {"ctl": (0x01, 0x03), "don": (0x13, 0x03), "hui": (0x10, 0x03), "pyr": (0x11, 0x03),
       "inv": (0x01, 0x03), "p2full": (0x01, 0x03), "p1hurt": (0x01, 0x03)}
HP_FULL = 0x120
errs = []
seen = {}
ends = {}       # leg -> (down, end, retracted refill) for the round2-before-end companion (#343)
for leg, (side, perf) in WANT.items():
    rows = {}
    for line in open(f"{W}/{leg}/field.txt"):
        f = line.split()
        if len(f) < 3 or f[0] != "F": continue
        d = dict(kv.split("=") for kv in f[2:])
        rows[int(f[1])] = {k: int(v) for k, v in d.items()}
    if not rows:
        errs.append(f"{leg}: no field samples — dead leg"); continue
    if not any(r["timer"] == 0 for r in rows.values()):
        errs.append(f"{leg}: the timer never reached 0 — the timeout "
                    "never fired; nothing judged"); continue
    pre0 = [rows[fr]["p2hp"] for fr in sorted(rows)
            if rows[fr]["rounds"] == 0 and rows[fr]["p2hp"]]
    if leg == "p2full":
        # the full-HP P2 winner: P2 must never be hit before the down
        if not pre0 or min(pre0) != 0x120:
            errs.append(f"{leg}: P2's HP left 0x120 before the down "
                        f"(min {min(pre0) if pre0 else None}) — not a full-HP P2 win; fix the rig"); continue
    else:
        # THE LEAD MUST EXIST (14z-104: Phobos' jab measured a WHIFF at the
        # original walk spacing — a tied-HP timeout judged to P1 would have
        # passed this audit vacuously). Refuse to judge a leg whose jab never
        # landed. Since #342 inv needs it too: its 0x01 is P2's jab damage.
        if not pre0 or min(pre0) >= 0x120:
            errs.append(f"{leg}: the jab never landed (p2hp never below "
                        "0x120 before the timeout) — no lead, verdict "
                        "vacuous; fix the rig geometry"); continue
    adv = [fr for fr in sorted(rows) if rows[fr]["rounds"] >= 1]
    if not adv:
        errs.append(f"{leg}: the round never advanced ($FF810E stayed 0) "
                    "— the judge did not settle (the #103 stall shape)"); continue
    # the round2-before-end companion's evidence, taken before any check can skip the leg (#343)
    full = lambda r: r["p1hp"] == HP_FULL and r["p2hp"] == HP_FULL
    end = next((fr for fr in sorted(rows) if fr > adv[0] and rows[fr]["rounds"] == 0xFF), None)
    if end is not None:
        ends[leg] = (adv[0], end, next((fr for fr in adv if full(rows[fr])), None))   # the retracted predicate
    at = rows[adv[0]]
    if leg == "p1hurt" and at["p1hp"] >= 0x120:
        errs.append(f"{leg}: P1's HP at the down is {at['p1hp']:#x} — not a hurt winner; fix the rig"); continue
    seen[leg] = (at["side05"], at["perfect"])
    # THE SIDE (14z-118 measured $FF8105/$FF810C; since #342 the one side check)
    if mode == "side-by-perfect":
        got = (RETRACTED.get(at["perfect"]), RETRACTED.get(at["perfect"]))
    else:
        got = (at["side05"], at["side0c"])
    if got != (side, side):
        errs.append(f"{leg}: side codes $FF8105/$FF810C = {got[0]}/{got[1]} "
                    f"at the down (f{adv[0]}), expected {side}/{side} — the timeout "
                    "down went the wrong way")
        continue
    # THE WINNER'S PERFECT FLAG ($FF8120, #342)
    want_perf = BY_SIDE[side] if mode == "perfect-by-side" else perf
    perfs = {rows[fr]["perfect"] for fr in adv}
    if perfs != {want_perf}:
        errs.append(f"{leg}: perfect flag $FF8120 {sorted(hex(p) for p in perfs)}, "
                    f"expected {want_perf:#04x} — the winner's damage test moved")
        continue
    # ($FF8127 was asserted here for a few hours at 14z-118 as "1 after a
    #  P2-won down": its writer PRG:0x02228E compares the two fighters'
    #  object byte +0x10 every frame — not match state; the assertion froze a
    #  coincidence of this rig and was removed the same session.)
    # THE TIME OVER ENDS THE MATCH (#343; the maintainer: "there is only one timer so TIME OVER ends
    # the match, not the round"). ~~round 2 must spawn live: after the round advanced, HP refills~~
    # RETRACTED 14z-215 (#343): the first refill with $FF810E >= 1 was the next match's, after 0xFF.
    down = adv[0]
    if rows.get(down - 1, {}).get("rounds", 0) != 0:
        errs.append(f"{leg}: $FF810E was not 0 the frame before the down (f{down - 1}) — no 0 -> 1 edge")
        continue
    after = [fr for fr in sorted(rows) if fr > down]
    if end is None:
        errs.append(f"{leg}: the match never ended ($FF810E never 0xFF after the time over at f{down}) — "
                    "the time over did not end the match, or the match stalled after the judge")
        continue
    r2 = [fr for fr in after if fr < end and rows[fr]["rounds"] == 0 and full(rows[fr])]
    if r2:
        errs.append(f"{leg}: a respawn ($FF810E 0, both HP 0x120) at f{r2[0]}, before the match end "
                    f"at f{end} — a time over must end the match, not a round")
        continue
    if mode == "round2-before-end":
        # the control: the retracted reading — a refill (both HP 0x120) between the down and the end
        pre = [fr for fr in after if fr < end and full(rows[fr])]
        if not pre:
            errs.append(f"{leg}: no refill between the down (f{down}) and the match end (f{end}) — "
                        "round2-before-end: no round 2")
            continue
        refill = pre[0]
    else:
        refill = next((fr for fr in after if fr > end and rows[fr]["rounds"] == 1 and full(rows[fr])), None)
    if refill is None:
        errs.append(f"{leg}: the next match never spawned with refilled HP after the match end at "
                    f"f{end} — the game stalled")
        continue
    lslot, lid = ("p2id", IDS[leg][1]) if side == 1 else ("p1id", IDS[leg][0])
    rr = rows[refill]
    if rr[lslot] == lid or rr["timer"] != 99:
        errs.append(f"{leg}: the refill at f{refill} is not a new match: the loser's slot "
                    f"{'$FF8B82' if side == 1 else '$FF8782'} = {rr[lslot]:#04x} (the leg's was "
                    f"{lid:#04x}), timer {rr['timer']} (want a new id and 99)")
        continue
    print(f"  ok: {leg} — timeout judged to P{side} ($FF8105/$FF810C), "
          f"perfect {perf:#04x}, match end f{end}, next match live at f{refill} "
          f"(loser's slot {lid:#04x} -> {rr[lslot]:#04x}, timer 99)")
# THE CONTROLS (in-gate): each perturbed reading must disagree on BOTH confound legs
if all(l in seen for l in CONFOUND):
    ev = ", ".join(f"{l} $FF8120={seen[l][1]:#04x} reads P{RETRACTED.get(seen[l][1])}, side P{WANT[l][0]}" for l in CONFOUND)
    if all(RETRACTED.get(seen[l][1]) != WANT[l][0] for l in CONFOUND):
        print(f"CONTROL FIRED: side-by-perfect — the retracted reading misjudges both confound legs ({ev})")
    else:
        print(f"CONTROL DEAD: side-by-perfect — the retracted reading agrees with a confound leg ({ev})"); errs.append("side-by-perfect dead")
    ev = ", ".join(f"{l} side P{seen[l][0]} predicts {BY_SIDE.get(seen[l][0], 0):#04x}, $FF8120={seen[l][1]:#04x}" for l in CONFOUND)
    if all(BY_SIDE.get(seen[l][0]) != seen[l][1] for l in CONFOUND):
        print(f"CONTROL FIRED: perfect-by-side — the side-derived expectation misses both confound legs ({ev})")
    else:
        print(f"CONTROL DEAD: perfect-by-side — the side-derived expectation matches a confound leg ({ev})"); errs.append("perfect-by-side dead")
else:
    missing = [l for l in CONFOUND if l not in seen]
    for c in ("side-by-perfect", "perfect-by-side"):
        print(f"CONTROL DEAD: {c} — confound leg(s) {missing} not judged")
    errs.append(f"the confound legs {missing} were not judged")
# round2-before-end (#343): the retracted predicate must place its refill AFTER the match end on every leg
if len(ends) == len(WANT):
    ev = ", ".join(f"{l} f{o} > end f{e}" if o is not None else f"{l} none" for l, (d, e, o) in ends.items())
    if all(o is not None and o > e for (d, e, o) in ends.values()):
        print(f"CONTROL FIRED: round2-before-end — the retracted round-2 refill lands after the match end on every leg ({ev})")
    else:
        print(f"CONTROL DEAD: round2-before-end — the retracted round-2 refill does not land after the match end on every leg ({ev})"); errs.append("round2-before-end dead")
else:
    missing = [l for l in WANT if l not in ends]
    print(f"CONTROL DEAD: round2-before-end — leg(s) {missing} reached no match end")
    errs.append(f"round2-before-end: legs {missing} not judged")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo 'PASS: the timeout judge awards the down to the HP leader ($FF8105/$FF810C)'
echo '      for all three tenants (legacy control green, inverted control judged'
echo '      the other way); the winner'"'"'s perfect flag $FF8120 tells unhurt from'
echo '      hurt on both sides (p2full, p1hurt); the time over ends the match and'
echo '      the next match spawns live (no round 2, no stall)'
