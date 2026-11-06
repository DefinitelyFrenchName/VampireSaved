#!/bin/sh
# audit_tenant_downwin.sh — THE LIFE-MARKER TRANSITION (KO-path judge),
# both directions per tenant (14z-104; the KO a true last-bar death and the first down added,
# 14z-215, GitHub #343).
#
# WHAT: the KO path, both ways per tenant: a tenant KOs a legacy dummy on its LAST bar and a
#   legacy attacker KOs the tenant on its last bar, and in both the judge awards the down to the
#   attacker's side, the match ENDS ($FF810E 0xFF) and the next match spawns live — the direct
#   lock on the #103 class (a ported row starving the judge); and the LIFE-MARKER TRANSITION
#   itself (§4), a first down on each side: the victim keeps fighting on its spare bar. The game
#   (the maintainer, 2026-10-31, #343): "on standard dip switch settings, you need two downs to
#   win HOWEVER, there is only one timer so TIME OVER ends the match, not the round. Think of
#   Vampire savior as having only one round but you get a new full life bar after your first
#   down". ~~spawns round 2~~ RETRACTED 14z-215 (#343): the HP-only poke made each KO a death
#   with the spare bar unused, which ENDED THE MATCH, and the refill read as round 2 was the
#   next match's, after $FF810E = 0xFF. The SIDE of the down is $FF8105 (1 = P1 won, 2 = P2 won;
#   PRG:0x00988E / PRG:0x00989C); $FF8120 is the winner's PERFECT test (0xFF at PRG:0x0098DC,
#   then 0x01 at PRG:0x0098EC when the winner's white HP +0x52 is below $FF815A's full value),
#   checked under that name — it is not the side (#342, 14z-215).
# HOW: the judge/01_timeout_lead rig on MAME with the target's real and white HP poked to 1,
#   its next-bar threshold +0x138 to 0 and its bat +0x3B0 to 0 (the last bar: docs/game/gotchas.md
#   "A POKED KO NEEDS THE VICTIM ON ITS LAST BAR"), so the jab kills; the first-down legs `fd`
#   (P2 the victim) and `fd1` (P1, the jab moved to P2) poke the victim's HP to 145 so the jab
#   crosses 144; $FF810E, $FF8105, $FF8120, $FF8008, both HP, white HP, +0x138 and +0x3B0 words
#   and both ids read from field traces;
#   all-legacy `ctl`/`vctl` legs and a `nopoke` leg (the jab must not advance the round) are
#   the controls; two legacy Demitri-vs-Victor legs break the side/damage confound: `p2win`
#   (the jab moved to P2 in-gate, P1 poked to 1: a P2 win at FULL HP) and `p1hurt` (P1 poked
#   to 200 before his killing jab: a P1 win, HURT).
# EXPECTS: per KO leg the last-bar pokes hold to the KO (+0x138 0, bat 0 the frame before), the
#   victim's bat goes 0 -> 0xFF and $FF810E 0 -> 1 at the down, the match ENDS ($FF810E 0xFF) with
#   no respawn before it ($FF810E 0 with both HP 0x120), the next match spawns live after it (both
#   HP 0x120 with $FF810E 1, a new id in the loser's slot, the timer 99), END clean, and at the
#   down side/perfect = the eight tenant/legacy legs 1/0xFF (P1 is the attacker and is never
#   hit), p2win 2/0xFF, p1hurt 1/0x01; per first-down leg the victim's HP and white HP go 145 ->
#   144, +0x138 144 -> 0, bat 1 -> 0, and $FF810E stays 0 and $FF8008 4 to the end of the window
#   (the match goes on); the nopoke leg shows no transition.
# RIG RECORDS (poke read-back READS-BACK, ruled 2026-10-31, 14z-215): wh1 at $FF8450 (the p1hurt leg's 4-byte HP pin writes it) — sampled, never judged; a record of the rig's poke, never a measurement of the game.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lua/field_trace.lua tests/lib/controls.sh
#   tests/replays/judge/01_timeout_lead.rpl tools/run_mame.sh tools/setup_mame.sh
#
# SHEET: none — runs our build only, judged on its own; no reference leg and no frozen reference values
#
# MUST-FIRE: known-bad: side-by-perfect — the side judged by the retracted 14z-104 reading of $FF8120 (0xFF = P1 won, 0x01 = P2 won) instead of $FF8105 must fail on the p2win and p1hurt legs, so the gate tells the side of the down from the winner's damage (in-gate; as a mode the side check reads $FF8120 and the gate FAILs)
# MUST-FIRE: known-bad: perfect-by-side — the perfect flag expected from the side (0xFF when P1 won, 0x01 when P2 won: the 14z-104 expectation) must fail on the p2win and p1hurt legs, so the $FF8120 check measures the winner's damage, not the side (in-gate; as a mode $FF8120 is expected from the side and the gate FAILs)
# MUST-FIRE: known-bad: ko-without-last-bar — the KO legs without the +0x138/+0x3B0 pokes (the 14z-104 rig, HP alone) must fail, the victim dying with its spare bar unused (bat 1 -> 0, not 0 -> 0xFF), so the gate tells a last-bar death from a death that skips the spare bar (as a mode the KO pokes are HP alone and the gate FAILs)
# MUST-FIRE: known-bad: round2-before-end — a respawn with both HP at 0x120 required between the KO and the match end ($FF810E 0xFF), the retracted "round 2 spawns" reading, must fail on every KO leg, so the gate tells a KO that ends the match from one that ends a round (in-gate: the retracted predicate, the first frame with $FF810E >= 1 and both HP 0x120, must land after the match end on every KO leg; as a mode the refill is required before the end and the gate FAILs)
#
# NOT COVERED: no tenant wins a down as P2 or hurt (the tenants are judged only as P1
#   attackers and as P2 victims); $FF8120's 0x00 outcome (PRG:0x0098FC, $FF8108 differing
#   from the winner's +0x3B0) is reached by no leg; $FF810C is not read here (the timeout
#   audit carries it); the first down is legacy only (Demitri and Victor) — no tenant's spare
#   bar is exercised.
#
# §4 mandates life-marker-transition coverage per ported character; the
# corpus had it for Donovan only (20_don_round2 / 23_don_matchwin). This
# is also the DIRECT #103-class lock: the round judge kills on WHITE
# HP's sign (+0x52, ram.md:111), and a ported row that keeps a tenant's
# white pinned produced a real shipped stall once (the Donovan
# arcade-death, fixed 14z-99). A tenant must be judgeable BOTH ways:
#   - as the WINNER (tenant KOs a legacy dummy -> down awarded), and
#   - as the VICTIM (a legacy attacker KOs the tenant -> the TENANT'S
#     death runs the judge through the tenant's own rows).
#
# RIG: tests/replays/judge/01_timeout_lead.rpl (the walk + one jab), with
# the KO produced by poking the target's real+white HP to 1 so any
# contact kills, and its +0x138 and +0x3B0 to 0 so the death is on the
# LAST bar (#343: with HP alone the death skipped the spare bar — bat
# 1 -> 0, +0x138 still 144 — and ended the match at once, measured on
# pristine vsavj, 14z-215). No timer poke — the transition here is the
# KO path.
#
# WHAT IT ASSERTS, per KO leg: the last-bar pokes hold to the KO (the
# victim's +0x138 and bat 0 the frame before its HP goes negative), the
# bat goes 0 -> 0xFF and $FF810E 0 -> 1 at the down, the side code $FF8105
# at the first settled frame is the attacker's side, the winner's perfect
# flag $FF8120 is 0xFF for an unhurt winner and 0x01 for a hurt one, the
# MATCH ENDS (`end`, the first frame after the down with $FF810E 0xFF)
# with no respawn ($FF810E 0, both HP 0x120) before it, and the next match
# spawns live (`refill`, the first frame after `end` with both HP 0x120
# and $FF810E 1; a new id in the loser's slot, the timer 99). Per
# first-down leg: HP/white 145 -> 144, +0x138 144 -> 0, bat 1 -> 0, and
# $FF810E 0 with $FF8008 4 on every later frame of the window. Guarded
# END-clean.
# ~~the round ADVANCES ($FF810E 0 -> 1) ... and round 2 spawns live (both
# HP refill to 0x120)~~ RETRACTED 14z-215 (#343): the refill came after
# $FF810E = 0xFF — the next match's.
# ~~with the winner code $FF8120 == 0xFF (P1 always wins the down here —
# P1 is the attacker in every leg)~~ RETRACTED 14z-215 (#342): $FF8120 is
# the winner's PERFECT test, so 0xFF here meant "P1 unhurt", and a full-HP
# P2 win reads 0xFF too; the side is $FF8105 (the p2win leg reads 2/0xFF).
#
# CONTROLS: leg `ctl`/`vctl` are all-legacy (instrument moved if red);
# leg `nopoke` omits the HP poke — the jab must NOT produce a round
# transition in-window, proving the KO poke is load-bearing and the
# "round advanced" signal cannot pass vacuously. Legs `p2win` and `p1hurt`
# break the side/damage confound; the two MUST-FIRE controls above prove
# each check tells them apart. `ko-without-last-bar` and
# `round2-before-end` (#343) prove the gate tells a last-bar death from
# a spare-bar-skipping one and a match end from a round 2.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged34] [JOBS=6]
#        tests/audit_tenant_downwin.sh          (~13 legs x ~1.5 min, JOBS at a time)
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
JOBS="${JOBS:-6}"
BUILD="${BUILD:-build/m3b_merged34}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)" || { echo "FAIL: audit_tenant_downwin — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT
RPL="$REPO/tests/replays/judge/01_timeout_lead.rpl"
# p2win's script: the replay with its jab moved from P1 to P2, so P2 KOs the poked P1 (#342)
grep -qx '3010-3012 p1=1' "$RPL" || { echo "FAIL: the jab line '3010-3012 p1=1' is not in $RPL — the p2win edit cannot apply"; exit 1; }
sed 's/^3010-3012 p1=1$/3010-3012 p2=1/' "$RPL" > "$W/p2jab.rpl"
FIELDS="ff8120:b:perfect,ff810e:b:rounds,ff8450:w:p1hp,ff8850:w:p2hp,ff891f:b:p2dead,ff8109:b:timer,ff8105:b:side05"
FIELDS="$FIELDS,ff8452:w:wh1,ff8852:w:wh2,ff8538:w:nb1,ff8938:w:nb2,ff87b0:b:bat1,ff8bb0:b:bat2,ff8008:w:phase,ff8782:b:p1id,ff8b82:b:p2id"
# the victim on its LAST bar (#343): real+white -> 1 so ANY contact kills (4 was not enough: Pyron's LP
# measured 2 damage at this spacing, 14z-104), and +0x138 (the next-bar threshold) and +0x3B0 (the bat)
# -> 0, so the death is the match's and not one that skips the spare bar (docs/game/gotchas.md
# "A POKED KO NEEDS THE VICTIM ON ITS LAST BAR"); the hold to the KO is asserted from the trace
LAST2=";3006:ff8938:0000;3006:ff8bb0:00"     # P2 victim's +0x138, +0x3B0
LAST1=";3006:ff8538:0000;3006:ff87b0:00"     # P1 victim's +0x138, +0x3B0
if vs_ctl_is ko-without-last-bar; then LAST2=""; LAST1=""; fi   # the control: the 14z-104 rig, HP alone
KOBASE=";3006:ff8850:0001;3008:ff8852:0001"   # the KO pokes; LAST2 adds the victim's last bar
KOPK="$KOBASE$LAST2"

n=0
leg() {  # name  p1id  p2id  extra-pokes  [replay]
    n_="$1"; a="$2"; b="$3"; extra="$4"; r="${5:-$RPL}"
    d="$W/$n_"; mkdir -p "$d/sb"
    PK="1400:ff8782:$a;1450:ff8782:$a;1500:ff8782:$a;1400:ff8b82:$b;1450:ff8b82:$b;1500:ff8b82:$b$extra"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$r" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3000 FIELD_TO=5200 FRAMES=5250 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
    n=$((n + 1)); [ $((n % JOBS)) -eq 0 ] && wait
    return 0
}
# tenant as WINNER: tenant P1 KOs the legacy dummy
leg ctl 01 03 "$KOPK"
leg don 13 03 "$KOPK"
leg hui 10 03 "$KOPK"
leg pyr 11 03 "$KOPK"
# tenant as VICTIM: legacy P1 (Victor) KOs the tenant dummy
leg vctl 03 01 "$KOPK"
leg vdon 03 13 "$KOPK"
leg vhui 03 10 "$KOPK"
leg vpyr 03 11 "$KOPK"
# discrimination control: no HP poke -> the jab must NOT end the match
leg nopoke 01 03 ""
# the confound legs (#342): P2 (Victor) KOs the poked P1 at full HP; a hurt P1 (200) KOs the dummy
leg p2win 01 03 ";3006:ff8450:0001;3008:ff8452:0001$LAST1" "$W/p2jab.rpl"
leg p1hurt 01 03 ";3004:ff8450:00c800c8$KOPK"
# THE LIFE-MARKER TRANSITION (#343, §4): the victim poked to 145, so the jab crosses the 144 threshold — a first
# down on each side: P2 (Victor) hit by P1's jab; P1 (Demitri) hit by P2's jab
leg fd 01 03 ";3006:ff8850:0091;3008:ff8852:0091"
leg fd1 01 03 ";3006:ff8450:0091;3008:ff8452:0091" "$W/p2jab.rpl"
# the last-bar control's leg, in-gate (14z-216): ctl with the base pokes alone, as the mode leaves them
leg ctl_nolast 01 03 "$KOBASE"
wait

python3 - "$W" "$MODE" <<'PY' || { echo "FAIL: tenant downwin audit"; exit 1; }
import sys
W, mode = sys.argv[1], sys.argv[2]
# leg -> (side, perfect): side = $FF8105 at the down (1 = P1 won, 2 = P2 won);
# perfect = $FF8120 (0xFF the winner never hit, 0x01 the winner hurt) — #342
WANT = {l: (1, 0xFF) for l in ("ctl", "don", "hui", "pyr", "vctl", "vdon", "vhui", "vpyr")}
WANT.update({"p2win": (2, 0xFF), "p1hurt": (1, 0x01)})
CONFOUND = ("p2win", "p1hurt")
RETRACTED = {0xFF: 1, 0x01: 2}          # the 14z-104 reading of $FF8120 as the side
BY_SIDE = {1: 0xFF, 2: 0x01}            # the 14z-104 expectation of $FF8120 from the side
# leg -> (P1 id, P2 id) as poked (hex): the next match's opponent replaces the loser's id (#343)
IDS = {"ctl": (0x01, 0x03), "don": (0x13, 0x03), "hui": (0x10, 0x03), "pyr": (0x11, 0x03),
       "vctl": (0x03, 0x01), "vdon": (0x03, 0x13), "vhui": (0x03, 0x10), "vpyr": (0x03, 0x11),
       "p2win": (0x01, 0x03), "p1hurt": (0x01, 0x03)}
FIRST = {"fd": "2", "fd1": "1"}         # first-down leg -> the victim's side (#343)
HP_FULL, BAR = 0x120, 0x90              # full HP; the spare bar's threshold, 144
LEGS = list(WANT) + ["nopoke"] + list(FIRST)
errs = []
seen = {}
ends = {}       # KO leg -> (down, end, retracted refill) for the round2-before-end companion (#343)
for leg in LEGS:
    rows = {}
    for line in open(f"{W}/{leg}/field.txt"):
        f = line.split()
        if len(f) < 3 or f[0] != "F": continue
        d = dict(kv.split("=") for kv in f[2:])
        rows[int(f[1])] = {k: int(v) for k, v in d.items()}
    if not rows:
        errs.append(f"{leg}: no field samples — dead leg"); continue
    advanced = [fr for fr in sorted(rows) if rows[fr]["rounds"] >= 1]
    if leg in FIRST:
        # THE LIFE-MARKER TRANSITION (#343, §4): the jab crosses 144 — the victim keeps fighting on its spare bar
        v = FIRST[leg]
        hp, wh, nb, bat = f"p{v}hp", f"wh{v}", f"nb{v}", f"bat{v}"
        dn = next((fr for fr in sorted(rows) if fr > 3008 and rows[fr][hp] < 145), None)
        if dn is None or dn - 1 not in rows:
            errs.append(f"{leg}: the jab never brought P{v} below 145 — no first down; fix the rig"); continue
        b, a = rows[dn - 1], rows[dn]
        bat_after = rows.get(dn + 1, a)[bat]
        if (b[hp], b[wh]) != (145, 145):
            errs.append(f"{leg}: P{v}'s HP/white before the jab {b[hp]}/{b[wh]}, not the poked 145/145; fix the rig"); continue
        if (a[hp], a[wh], b[nb], a[nb], b[bat], bat_after) != (BAR, BAR, BAR, 0, 1, 0):
            errs.append(f"{leg}: the first down at f{dn} read HP/white {a[hp]}/{a[wh]}, +0x138 {b[nb]} -> {a[nb]}, "
                        f"bat {b[bat]} -> {bat_after}; expected 144/144, 144 -> 0, 1 -> 0 (the spare bar)"); continue
        later = [fr for fr in sorted(rows) if fr >= dn]
        bad = [fr for fr in later if rows[fr]["rounds"] != 0 or rows[fr]["phase"] != 4]
        if bad:
            r = rows[bad[0]]
            errs.append(f"{leg}: after the first down (f{dn}) f{bad[0]} reads $FF810E {r['rounds']}, $FF8008 "
                        f"{r['phase']} — a first down must not end the match (want 0 and 4)"); continue
        print(f"  ok: {leg} — first down on P{v} at f{dn}: HP/white 145 -> 144/144, +0x138 144 -> 0, bat 1 -> 0; "
              f"$FF810E 0 and $FF8008 4 through f{later[-1]} — the match goes on")
        continue
    if leg == "nopoke":
        if advanced:
            errs.append("nopoke: the round advanced WITHOUT the KO poke — "
                        "the transition signal is vacuous")
        else:
            print("  ok: nopoke control — one jab does not end the match")
        continue
    if not advanced:
        errs.append(f"{leg}: the round never advanced — the KO was not "
                    "judged (the #103 stall shape; check the victim's "
                    "white-HP path)"); continue
    side, perf = WANT[leg]
    v = "2" if side == 1 else "1"       # the victim
    full = lambda r: r["p1hp"] == HP_FULL and r["p2hp"] == HP_FULL
    down = advanced[0]
    end = next((fr for fr in sorted(rows) if fr > down and rows[fr]["rounds"] == 0xFF), None)
    if end is not None:                 # the round2-before-end companion's evidence (#343): the retracted predicate
        ends[leg] = (down, end, next((fr for fr in advanced if full(rows[fr])), None))
    at = rows[down]
    # stage guard: the winner's HP at the down is what the leg claims (full for 0xFF, below full for 0x01)
    whp = at["p1hp"] if side == 1 else at["p2hp"]
    if (perf == 0xFF and whp != 0x120) or (perf == 0x01 and not 0 < whp < 0x120):
        errs.append(f"{leg}: the winner's HP at the down is {whp:#x} — not the "
                    f"{'full-HP' if perf == 0xFF else 'hurt'} winner the leg claims; fix the rig"); continue
    seen[leg] = (at["side05"], at["perfect"])
    # THE SIDE ($FF8105, #342)
    got = RETRACTED.get(at["perfect"]) if mode == "side-by-perfect" else at["side05"]
    if got != side:
        errs.append(f"{leg}: side code $FF8105 = {got} at the down (f{advanced[0]}), "
                    f"expected {side} — the down went to the wrong side")
        continue
    # THE WINNER'S PERFECT FLAG ($FF8120, #342)
    want_perf = BY_SIDE[side] if mode == "perfect-by-side" else perf
    perfs = {rows[fr]["perfect"] for fr in advanced}
    if perfs != {want_perf}:
        errs.append(f"{leg}: perfect flag $FF8120 {sorted(hex(p) for p in perfs)}, "
                    f"expected {want_perf:#04x} — the winner's damage test moved")
        continue
    # THE LAST-BAR DEATH (#343): the pokes held to the KO, the bat goes 0 -> 0xFF and $FF810E 0 -> 1
    ko = next((fr for fr in sorted(rows) if rows[fr][f"p{v}hp"] < 0), None)
    if ko is None or ko - 1 not in rows or down - 1 not in rows:
        errs.append(f"{leg}: P{v}'s HP never went negative in the window — no KO"); continue
    b = rows[ko - 1]
    if (b[f"nb{v}"], b[f"bat{v}"], at[f"bat{v}"], rows[down - 1]["rounds"]) != (0, 0, 0xFF, 0):
        errs.append(f"{leg}: the KO (f{ko}) is not a last-bar death: P{v}'s +0x138 {b[f'nb{v}']} and bat "
                    f"{b[f'bat{v}']} the frame before, bat {b[f'bat{v}']} -> {at[f'bat{v}']} at the down "
                    f"(f{down}, $FF810E {rows[down - 1]['rounds']} -> {at['rounds']}); expected +0x138 0, "
                    "bat 0 -> 0xFF, $FF810E 0 -> 1")
        continue
    # THE KO ENDS THE MATCH (#343). ~~round 2 must spawn live: a refill with $FF810E >= 1~~ RETRACTED
    # 14z-215 (#343): that refill came after $FF810E = 0xFF — the next match's.
    if end is None:
        errs.append(f"{leg}: the match never ended ($FF810E never 0xFF after the down at f{down}) — "
                    "the last-bar KO did not end the match, or the match stalled after the down")
        continue
    after = [fr for fr in sorted(rows) if fr > down]
    r2 = [fr for fr in after if fr < end and rows[fr]["rounds"] == 0 and full(rows[fr])]
    if r2:
        errs.append(f"{leg}: a respawn ($FF810E 0, both HP 0x120) at f{r2[0]}, before the match end "
                    f"at f{end} — a last-bar KO must end the match, not a round")
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
    print(f"  ok: {leg} — last-bar KO judged to P{side} at f{down} (bat 0 -> 0xFF), perfect {perf:#04x}, "
          f"match end f{end}, next match live at f{refill} (loser's slot {lid:#04x} -> {rr[lslot]:#04x})")
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
# round2-before-end (#343): the retracted predicate must place its refill AFTER the match end on every KO leg
if len(ends) == len(WANT):
    ev = ", ".join(f"{l} f{o} > end f{e}" if o is not None else f"{l} none" for l, (d, e, o) in ends.items())
    if all(o is not None and o > e for (d, e, o) in ends.values()):
        print(f"CONTROL FIRED: round2-before-end — the retracted round-2 refill lands after the match end on every KO leg ({ev})")
    else:
        print(f"CONTROL DEAD: round2-before-end — the retracted round-2 refill does not land after the match end on every KO leg ({ev})"); errs.append("round2-before-end dead")
else:
    missing = [l for l in WANT if l not in ends]
    print(f"CONTROL DEAD: round2-before-end — KO leg(s) {missing} reached no match end")
    errs.append(f"round2-before-end: legs {missing} not judged")
# THE LAST-BAR CONTROL, IN-GATE (14z-216, the M24 freeze: declared at 14z-215 but fired only as a CONTROL= mode, so a plain
# run never printed it and the runner read it NOT FIRED): ctl's KO with the SAME base pokes and NO last-bar pokes (the
# 14z-104 rig, HP alone) must not be a last-bar death — P2's +0x138/bat not 0 the frame before the KO; no KO is DEAD.
crow = {}
try:
    for line in open(f"{W}/ctl_nolast/field.txt"):
        f = line.split()
        if len(f) >= 3 and f[0] == "F":
            crow[int(f[1])] = {k: int(v) for k, v in (kv.split("=") for kv in f[2:])}
except OSError:
    pass
cko = next((fr for fr in sorted(crow) if crow[fr]["p2hp"] < 0), None)
if cko is None or cko - 1 not in crow:
    print("CONTROL DEAD: ko-without-last-bar — the HP-only leg ctl_nolast has no KO"); errs.append("ko-without-last-bar dead")
elif (crow[cko - 1]["nb2"], crow[cko - 1]["bat2"]) != (0, 0):
    print(f"CONTROL FIRED: ko-without-last-bar — with HP alone the KO (f{cko}) is not a last-bar death: P2's +0x138 "
          f"{crow[cko - 1]['nb2']} and bat {crow[cko - 1]['bat2']} the frame before (expected 0 and 0 on the last bar)")
else:
    print("CONTROL DEAD: ko-without-last-bar — the HP-only leg died on its last bar anyway"); errs.append("ko-without-last-bar dead")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo 'PASS: the KO-path life-marker transition judges cleanly with every'
echo '      tenant as winner AND as victim, the side read from $FF8105 and the'
echo '      winner'"'"'s perfect flag $FF8120 telling unhurt from hurt; each last-bar KO'
echo '      ends the match and the next match spawns live; a first down on either'
echo '      side leaves the match going on the spare bar (controls green)'
