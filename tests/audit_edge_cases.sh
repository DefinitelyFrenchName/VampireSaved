#!/bin/sh
# audit_edge_cases.sh — DELIBERATE STATE-TRANSITION EDGES per tenant
# (14z-104 (4); coverage matrix gap 2 — §4's edge-case bias, served
# deliberately instead of incidentally).
#
# WHAT: three deliberate state-transition edges per tenant: a KO landing mid-throw (both as
#   thrower and as victim), a double KO by trade in a mirror match, and an EX input on the
#   first live match frame. Every KO is a death on the victim's LAST bar, as natural play reaches
#   one (the game has one round, a fresh full bar after the first down: the maintainer, 2026-10-31,
#   #343; docs/game/gotchas.md "THE GAME HAS ONE ROUND"). The outcome of a down is the side code
#   $FF8105 (1 = P1 won, 2 = P2 won, 3 = DRAW; PRG:0x00988E / 0x00989C / 0x0098B2); $FF8120 is the
#   winner's PERFECT test (0xFF at PRG:0x0098DC, then 0x01 at PRG:0x0098EC when the winner's white
#   HP +0x52 is below $FF815A's full value), which the draw path branches past — not the side (#342, 14z-215).
# HOW: the judge/pokes scaffolding on MAME with HP poked low and inputs timed to the edge; each KO
#   victim's next-bar threshold +0x138 and bat +0x3B0 poked to 0 with its HP (the last bar:
#   docs/game/gotchas.md "A POKED KO NEEDS THE VICTIM ON ITS LAST BAR"; both fighters' in the
#   double KO), the hold to the KO read from the trace;
#   the down's side is read from $FF8105, the winner's perfect flag from $FF8120, stocks from
#   $FF8509, both HP words, +0x138 and +0x3B0 per side; every leg is field-liveness guarded. Two
#   legacy Demitri-vs-Victor throw-KO legs break the side/damage confound: `tko_p2` (the throw moved
#   to P2 in-gate, P1 poked to 2: a P2 win at FULL HP) and `tko_hurt` (the thrower poked to 200
#   first: a P1 win, HURT).
# EXPECTS: every throw-KO, Phobos as thrower included, is a last-bar death (the victim's +0x138 and
#   bat 0 the frame before its HP goes negative, the bat 0 -> 0xFF at the down) and the down settles
#   ($FF810E 0 -> 1, the down that ends the match), side/perfect at the down = the seven other
#   throw-KO legs 1/0xFF (the P1 thrower is never hit), tko_p2 2/0xFF, tko_hurt 1/0x01; the trade
#   kills both fighters on their last bars (both bats 0 -> 0xFF at the down) and reads the DRAW code
#   $FF8105 = 3 with $FF8120 still 0x00 (unwritten: 0x00 from the match start, each leg's trade its
#   first settled down); frame-1 EX fires where the character has one (stock decrements) and produces a
#   stockless action where not.
#   ~~the throw-KO settles with the round advancing (except Phobos as thrower, whose throw cannot
#   finish an opponent and restores HP to half — measured identical on native vsav2 and frozen so)~~
#   RETRACTED 14z-215 (#343): there is no round to advance, and the "half-restore" was the victim's
#   FIRST DOWN (HP/white 144, +0x138 144 -> 0, bat 1 -> 0) from the HP-only poke leaving its spare bar
#   unused; on the last bar Phobos' throw kills like every other (our build and native vsav2 alike).
# POKE READ-BACK (ruled 2026-09-25 (14z-181), tests/expected/poke_readback.tsv): the `p1hp`/`p2hp` <= 1 read at the both_low line is the STAGE GUARD of the poked value, and since #343 the KO line judges P1's HP going negative (p1hp re-ruled OBSERVES 2026-10-31, 14z-215); the verdicts are the down's codes ($FF8105's side and $FF8120's perfect flag since #342; $FF8120 alone when ruled), the stock decrement and the half-HP restore (OBSERVES; the half-HP restore RETRACTED 14z-215, #343: no leg reads it since). The `nb1`/`nb2`/`bat1`/`bat2` reads (14z-215, #343) — the poked last bar's hold the frame before the KO, and the bat's 0 -> 0xFF at the down — are OBSERVES (ruled 2026-10-31, 14z-215: the maintainer, "OBSERVES", by 14z-181's "samples a window the pin never touches" for the hold reads; the bat's 0 -> 0xFF a change the gate asserts).
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lua/field_trace.lua tests/lib/controls.sh
#   tests/replays/judge/02_throw.rpl tools/run_mame.sh tools/setup_mame.sh
#
# SHEET: no-reference-leg — our build against frozen vs2 values, with no vs2 rig in the gate (ruled 2026-10-17: listed, not drawn)
#
# MUST-FIRE: known-bad: side-by-perfect — the outcome judged by the retracted 14z-104 reading of $FF8120 (0xFF = P1 won, 0x01 = P2 won, 0x00 = draw) instead of $FF8105 must fail on the tko_p2 and tko_hurt legs, so the gate tells the side of the down from the winner's damage (in-gate; as a mode the side check reads $FF8120 and the gate FAILs)
# MUST-FIRE: known-bad: perfect-by-side — the perfect flag expected from the side (0xFF when P1 won, 0x01 when P2 won, 0x00 at a draw: the 14z-104 expectation) must fail on the tko_p2 and tko_hurt legs, so the $FF8120 check measures the winner's damage, not the side (in-gate; as a mode $FF8120 is expected from the side and the gate FAILs)
# MUST-FIRE: known-bad: ko-without-last-bar — the throw-KO legs without the +0x138/+0x3B0 pokes (the 14z-104 rig, HP alone) must fail, the victim dying with its spare bar unused (bat 1 -> 0, not 0 -> 0xFF) and Phobos' throw giving a first down instead of a kill, so the gate tells a last-bar death from one that skips the spare bar (as a mode the throw-KO pokes are HP alone and the gate FAILs)
# MUST-FIRE: known-bad: dko-without-last-bar — the double-KO legs without the +0x138/+0x3B0 pokes (the 14z-104 rig, HP alone) must fail, both fighters dying with their spare bars unused (bats 1 -> 0, not 0 -> 0xFF) although the draw codes read the same, so the gate tells a last-bar double KO from one that skips both spare bars (as a mode the double-KO pokes are HP alone and the gate FAILs)
#
# NOT COVERED: no tenant wins a throw-KO as P2 or hurt; a double KO after an earlier settled down
#   (where $FF8120 would still hold that down's value: it is not cleared, tko_ctl's next match still
#   reads 0xFF) is not rigged; $FF8120's 0x00 written at PRG:0x0098FC ($FF8108 differing from the
#   winner's +0x3B0) is reached by no leg; what follows the down is not asserted (the match end
#   $FF810E 0xFF after a KO is audit_tenant_downwin's; after the trade the window shows no 0xFF and
#   both ids cleared, measured 14z-215 and not frozen); no first down through a throw is rigged
#   (the HP-only poke gave one through Phobos' throw, #343).
#
# Three families, all on the judge/pokes scaffolding, all guarded by
# field-liveness (a crash kills a leg's samples and fails it):
#
#   1. KO DURING CAPTURE (throw-KO): the victim is poked to 2 HP on
#      its LAST bar (+0x138 and +0x3B0 to 0, #343) and thrown — the
#      kill lands mid-throw, inside the capture states.
#      Every tenant kills this way AND dies this way (a tenant dying
#      inside a legacy capture runs its ported death-from-capture
#      path). Judge must settle: the down that ends the match ($FF810E
#      0 -> 1, the victim's bat 0 -> 0xFF), the side code $FF8105
#      names the thrower, and the thrower's perfect flag $FF8120 is 0xFF
#      (unhurt) — ~~winner 0xFF~~ RETRACTED 14z-215 (#342): 0xFF is the
#      thrower's PERFECT flag, not the side; tko_p2 (2/0xFF) and tko_hurt
#      (1/0x01) separate the two. ~~Judge must settle: round advances~~
#      RETRACTED 14z-215 (#343): the game has one round; $FF810E 0 -> 1
#      is the down that ends the match.
#      ~~EXCEPT PHOBOS AS THROWER: his throw CANNOT finish an opponent —
#      the would-be kill converts to a transient death flag + an HP
#      RESTORE to exactly half (144/144) with NO round transition, and
#      native vsav2 measures the IDENTICAL frame shape (14z-104 (4)).
#      A vs2 grab-family property faithfully ported (beside his
#      untechable sweep), frozen native-anchored as the tko_hui leg.~~
#      RETRACTED 14z-215 (#343): with HP alone the victim's spare bar was
#      unused, and the "half-restore" is its FIRST DOWN — HP/white 144,
#      +0x138 144 -> 0, bat 1 -> 0, the match going on — on our build
#      (f3093) and native vsav2 (f3086) alike; on the last bar Phobos'
#      throw KILLS (bat 0 -> 0xFF, $FF8105 1, $FF8120 0xFF; our build
#      f3100, native vsav2 f3093), so tko_hui is an ordinary KO leg.
#      The other throws killed through the HP-only poke with the bat
#      1 -> 0 (a death that skips the spare bar).
#   2. DOUBLE KO (the trade): a MIRROR match with both fighters poked
#      to 1 HP on their LAST bars (#343) and both jabbing on the same
#      frame — mirrors guarantee symmetric startup, so the jabs trade
#      and both die (both bats 0 -> 0xFF at the down). The judge's
#      DRAW code is $FF8105 == 3 (PRG:0x0098B2, which branches past the
#      perfect writes, so $FF8120 keeps its value from the match start, 0x00).
#      With HP alone (the 14z-104 rig) both bats went 1 -> 0 and every
#      other traced field was the same, frame for frame (14z-215,
#      our build; Demitri and Victor mirrors on pristine vsavj too).
#      ~~keeps its round-1 value 0x00~~ RETRACTED 14z-215 (#343): there
#      is no round 1; the byte is not cleared between matches.
#      ~~The judge's DRAW code is $FF8120 == 0x00 (measured 14z-104 (4)
#      — the third value of the winner byte, beside 0xFF/0x01)~~
#      RETRACTED 14z-215 (#342): $FF8120 is not written on the draw path;
#      0x00 is its value since the match start, true of round 1 only.
#   3. FRAME-1 EX: the DP+2K input starting on the FIRST live match
#      frame (f2886) with poked meter. Frozen per leg from measurement:
#      Phobos/Pyron/Donovan fire their EX (stock decrements) — asserts
#      the input buffer and the EX machinery are live from frame one;
#      the Demitri control's and Donovan's DP+2K are not their EX
#      shapes and must simply produce an action without a stock spend
#      (measured 14z-104 (4)); Phobos and Pyron fire theirs.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged34] [JOBS=5]
#        tests/audit_edge_cases.sh          (~17 legs x ~1 min, JOBS at a time)
# SHARES: self
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
JOBS="${JOBS:-5}"
BUILD="${BUILD:-build/m3b_merged34}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)" || { echo "FAIL: audit_edge_cases — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT
FIELDS="ff8450:w:p1hp,ff8850:w:p2hp,ff8120:b:perfect,ff810e:b:rounds,ff8509:b:stk,ff8406:b:p1seq,ff8105:b:side05"
FIELDS="$FIELDS,ff8538:w:nb1,ff8938:w:nb2,ff87b0:b:bat1,ff8bb0:b:bat2"   # +0x138 and +0x3B0 per side (#343)

THROW="$REPO/tests/replays/judge/02_throw.rpl"
grep -qx '3010-3014 p1=R3' "$THROW" || { echo "FAIL: the throw line '3010-3014 p1=R3' is not in $THROW — the tko_p2 edit cannot apply"; exit 1; }
sed 's/^3100-3104 p1=R3$//' "$THROW" > "$W/throw.rpl"
# tko_p2's script: the throw moved from P1 to P2 (forward for P2 is L), so P2 throws the poked P1 (#342)
sed 's/^3100-3104 p1=R3$//; s/^3010-3014 p1=R3$/3010-3014 p2=L3/' "$THROW" > "$W/p2throw.rpl"
{ sed 's/^3010-3014 p1=R3$/3010-3012 p1=1/; s/^3100-3104 p1=R3$//' \
    "$THROW"; echo "3010-3012 p2=1"; } > "$W/dko.rpl"
cat > "$W/frame1.rpl" <<'EOF'
300-305 sys=C1
420-425 sys=C2
800-803 sys=S1
940-943 sys=S2
1100-1102 p2=R
1160-1162 p2=R
1300-1302 p1=1
1360-1362 p2=1
2886-2888 p1=R
2889-2891 p1=D
2892-2895 p1=DR45
3600 wait
EOF

n=0
leg() {  # name  p1id  p2id  replay  extra-pokes
    n_="$1"; a="$2"; b="$3"
    d="$W/$n_"; mkdir -p "$d/sb"
    PK="1400:ff8782:$a;1450:ff8782:$a;1500:ff8782:$a;1400:ff8b82:$b;1450:ff8b82:$b;1500:ff8b82:$b$5"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$4" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=2880 FIELD_TO=5100 FRAMES=5150 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
    n=$((n + 1)); [ $((n % JOBS)) -eq 0 ] && wait
    return 0
}
# the victims on their LAST bar (#343): +0x138 (the next-bar threshold) and +0x3B0 (the bat) -> 0 with the HP, so
# the death is the last bar's and not one that skips the spare bar (docs/game/gotchas.md "A POKED KO NEEDS THE
# VICTIM ON ITS LAST BAR"); the hold to the KO is asserted from the trace
LAST2=";3006:ff8938:0000;3006:ff8bb0:00"     # P2 victim's +0x138, +0x3B0
LAST1=";3006:ff8538:0000;3006:ff87b0:00"     # P1 victim's +0x138, +0x3B0
KL1="$LAST1"; KL2="$LAST2"; DL="$LAST1$LAST2"
if vs_ctl_is ko-without-last-bar; then KL1=""; KL2=""; fi    # the control: the 14z-104 throw-KO rig, HP alone
if vs_ctl_is dko-without-last-bar; then DL=""; fi            # the control: the 14z-104 double-KO rig, HP alone
KOBASE=";3006:ff8850:0002;3008:ff8852:0002"                                  # the KO pokes; KL2 adds the last bar
DKBASE=";3004:ff8450:0001;3005:ff8452:0001;3006:ff8850:0001;3007:ff8852:0001"   # the trade's; DL adds both last bars
KO="$KOBASE$KL2"
DK="$DKBASE$DL"
MT=";2860:ff8509:03;2880:ff8509:03"
# family 1: throw-KO, both directions
leg tko_ctl 01 03 "$W/throw.rpl" "$KO"
leg tko_don 13 03 "$W/throw.rpl" "$KO"
leg tko_hui 10 03 "$W/throw.rpl" "$KO"
leg tko_pyr 11 03 "$W/throw.rpl" "$KO"
leg vko_don 03 13 "$W/throw.rpl" "$KO"
leg vko_hui 03 10 "$W/throw.rpl" "$KO"
leg vko_pyr 03 11 "$W/throw.rpl" "$KO"
# the confound legs (#342): P2 (Victor) throws the poked P1 at full HP; a hurt P1 (200) throws the dummy
leg tko_p2 01 03 "$W/p2throw.rpl" ";3006:ff8450:0002;3008:ff8452:0002$KL1"
leg tko_hurt 01 03 "$W/throw.rpl" ";3004:ff8450:00c800c8$KO"
# family 2: double-KO mirrors
leg dko_ctl 01 01 "$W/dko.rpl" "$DK"
leg dko_don 13 13 "$W/dko.rpl" "$DK"
leg dko_hui 10 10 "$W/dko.rpl" "$DK"
leg dko_pyr 11 11 "$W/dko.rpl" "$DK"
# the two last-bar controls' legs, in-gate (14z-216): the base pokes alone, as the modes leave them
leg kctl_nolast 01 03 "$W/throw.rpl" "$KOBASE"
leg dctl_nolast 01 01 "$W/dko.rpl" "$DKBASE"
# family 3: frame-1 EX
leg f1_ctl 01 03 "$W/frame1.rpl" "$MT"
leg f1_don 13 03 "$W/frame1.rpl" "$MT"
leg f1_hui 10 03 "$W/frame1.rpl" "$MT"
leg f1_pyr 11 03 "$W/frame1.rpl" "$MT"
wait

python3 - "$W" "$MODE" <<'PY' || { echo "FAIL: edge-case audit"; exit 1; }
import sys
W, mode = sys.argv[1], sys.argv[2]
errs = []
# the down's codes (#342): side = $FF8105 (1 = P1 won, 2 = P2 won, 3 = draw);
# perfect = $FF8120 (0xFF the winner never hit, 0x01 the winner hurt; the draw path skips it: 0x00 from the match start)
RETRACTED = {0xFF: 1, 0x01: 2, 0x00: 3}  # the 14z-104 reading of $FF8120 as the outcome
BY_SIDE = {1: 0xFF, 2: 0x01, 3: 0x00}    # the 14z-104 expectation of $FF8120 from the outcome
CONFOUND = ("tko_p2", "tko_hurt")
seen = {}
def last_bar(rows, down, victims):
    """THE LAST-BAR DEATH (#343): per victim, the pokes held to the KO (+0x138 and the bat 0 the frame before
    its HP goes negative) and the bat goes 0 -> 0xFF at the down. Returns an error string or None."""
    for v in victims:
        ko = next((fr for fr in sorted(rows) if rows[fr][f"p{v}hp"] < 0), None)
        if ko is None or ko - 1 not in rows:
            return f"P{v}'s HP never went negative in the window — no KO"
        b, a = rows[ko - 1], rows[down]
        if (b[f"nb{v}"], b[f"bat{v}"], a[f"bat{v}"]) != (0, 0, 0xFF):
            return (f"the KO of P{v} (f{ko}) is not a last-bar death: +0x138 {b[f'nb{v}']} and bat {b[f'bat{v}']} "
                    f"the frame before, bat {a[f'bat{v}']:#04x} at the down (f{down}); expected +0x138 0, "
                    "bat 0 -> 0xff (with HP alone the spare bar is unused: bat 1 -> 0)")
    return None
def load(leg):
    rows = {}
    for line in open(f"{W}/{leg}/field.txt"):
        f = line.split()
        if len(f) < 3 or f[0] != "F": continue
        d = dict(kv.split("=") for kv in f[2:])
        rows[int(f[1])] = {k: int(v) for k, v in d.items()}
    return rows
def codes(leg, rows, adv, side, perf):
    """The down's side ($FF8105 at the first settled frame) and perfect flag ($FF8120 over the
    settled frames); under a mode the perturbed reading. Returns an error string or None."""
    at = rows[adv[0]]
    seen[leg] = (at["side05"], at["perfect"])
    got = RETRACTED.get(at["perfect"]) if mode == "side-by-perfect" else at["side05"]
    if got != side:
        return f"side code $FF8105 = {got} at the down (f{adv[0]}), expected {side}"
    want_perf = BY_SIDE[side] if mode == "perfect-by-side" else perf
    perfs = {rows[fr]["perfect"] for fr in adv}
    if perfs != {want_perf}:
        return (f"perfect flag $FF8120 {sorted(hex(p) for p in perfs)}, expected "
                f"{want_perf:#04x}")
    return None
TKO = {l: (1, 0xFF) for l in ("tko_ctl", "tko_don", "tko_hui", "tko_pyr", "vko_don", "vko_hui", "vko_pyr")}
TKO.update({"tko_p2": (2, 0xFF), "tko_hurt": (1, 0x01)})
for leg in ("tko_ctl","tko_don","tko_hui","tko_pyr","vko_don","vko_hui","vko_pyr","tko_p2","tko_hurt"):
    rows = load(leg)
    if not rows: errs.append(f"{leg}: dead leg"); continue
    adv = [fr for fr in sorted(rows) if rows[fr]["rounds"] >= 1]
    # ~~tko_hui: Phobos' throw cannot kill — a native-anchored half-restore to 144, no round~~ RETRACTED 14z-215
    # (#343): that was the victim's first down from the HP-only poke; on the last bar Phobos' throw kills (our
    # build and native vsav2), so tko_hui is judged like every other throw-KO leg
    if not adv:
        errs.append(f"{leg}: KO-in-capture never judged — the #103 shape "
                    "inside the throw states"); continue
    side, perf = TKO[leg]
    # stage guard: the thrower's HP at the down is what the leg claims (full for 0xFF, below full for 0x01)
    whp = rows[adv[0]]["p1hp" if side == 1 else "p2hp"]
    if (perf == 0xFF and whp != 0x120) or (perf == 0x01 and not 0 < whp < 0x120):
        errs.append(f"{leg}: the thrower's HP at the down is {whp:#x} — not the "
                    f"{'full-HP' if perf == 0xFF else 'hurt'} winner the leg claims; fix the rig"); continue
    e = codes(leg, rows, adv, side, perf) or last_bar(rows, adv[0], ["2" if side == 1 else "1"])
    if e:
        errs.append(f"{leg}: {e}"); continue
    print(f"  ok: {leg} — last-bar throw-KO judged to P{side} at f{adv[0]} (the victim's bat 0 -> 0xff), "
          f"perfect {perf:#04x}")
for leg in ("dko_ctl","dko_don","dko_hui","dko_pyr"):
    rows = load(leg)
    if not rows: errs.append(f"{leg}: dead leg"); continue
    # the trade must actually happen: both HP reach 0/dead state
    both_low = any(rows[fr]["p1hp"] <= 1 and rows[fr]["p2hp"] <= 1
                   for fr in rows if fr < 3015)
    if not both_low:
        errs.append(f"{leg}: the 1-HP pokes did not land — REFUSED"); continue
    adv = [fr for fr in sorted(rows) if rows[fr]["rounds"] >= 1]
    if not adv:
        errs.append(f"{leg}: the trade never judged"); continue
    e = codes(leg, rows, adv, 3, 0x00)
    if e:
        errs.append(f"{leg}: {e} — the trade did not double-KO (mirror jabs "
                    "must trade; if one side won, the jab did not trade and the "
                    "leg measures the wrong event)")
        continue
    e = last_bar(rows, adv[0], ["1", "2"])
    if e:
        errs.append(f"{leg}: {e}"); continue
    print(f"  ok: {leg} — last-bar double KO drawn at f{adv[0]} (both bats 0 -> 0xff; $FF8105 = 3, "
          "$FF8120 unwritten 0x00)")
# THE CONTROLS (in-gate): each perturbed reading must disagree on BOTH confound legs
if all(l in seen for l in CONFOUND):
    ev = ", ".join(f"{l} $FF8120={seen[l][1]:#04x} reads {RETRACTED.get(seen[l][1])}, side {TKO[l][0]}" for l in CONFOUND)
    if all(RETRACTED.get(seen[l][1]) != TKO[l][0] for l in CONFOUND):
        print(f"CONTROL FIRED: side-by-perfect — the retracted reading misjudges both confound legs ({ev})")
    else:
        print(f"CONTROL DEAD: side-by-perfect — the retracted reading agrees with a confound leg ({ev})"); errs.append("side-by-perfect dead")
    ev = ", ".join(f"{l} side {seen[l][0]} predicts {BY_SIDE.get(seen[l][0], 0):#04x}, $FF8120={seen[l][1]:#04x}" for l in CONFOUND)
    if all(BY_SIDE.get(seen[l][0]) != seen[l][1] for l in CONFOUND):
        print(f"CONTROL FIRED: perfect-by-side — the side-derived expectation misses both confound legs ({ev})")
    else:
        print(f"CONTROL DEAD: perfect-by-side — the side-derived expectation matches a confound leg ({ev})"); errs.append("perfect-by-side dead")
else:
    missing = [l for l in CONFOUND if l not in seen]
    for c in ("side-by-perfect", "perfect-by-side"):
        print(f"CONTROL DEAD: {c} — confound leg(s) {missing} not judged")
    errs.append(f"the confound legs {missing} were not judged")
# frame-1: frozen per leg (measured 14z-104 (4))
F1 = {"f1_ctl": "acts", "f1_don": "acts", "f1_hui": "ex", "f1_pyr": "ex"}
for leg, want in F1.items():
    rows = load(leg)
    if not rows: errs.append(f"{leg}: dead leg"); continue
    stks = [rows[fr]["stk"] for fr in sorted(rows) if fr >= 2886]
    fired = any(a > b for a, b in zip(stks, stks[1:]))
    acted = any(rows[fr]["p1seq"] not in (0, 2, 4) for fr in rows if fr < 3000)
    if want is None:
        print(f"  MEASURE {leg}: ex_fired={fired} acted={acted} — freeze me")
        continue
    if want == "ex" and not fired:
        errs.append(f"{leg}: the frame-1 EX did not fire (frozen: it does)")
    elif want == "acts" and (fired or not acted):
        errs.append(f"{leg}: expected a non-EX action (fired={fired} "
                    f"acted={acted})")
    else:
        print(f"  ok: {leg} — frame-1 behavior held ({'EX fired' if fired else 'action, no stock'})")
# THE LAST-BAR CONTROLS, IN-GATE (14z-216, the M24 freeze: declared at 14z-215 but fired only as CONTROL= modes, so a
# plain run printed neither and the runner read both NOT FIRED): one leg each with the SAME base pokes as the KO legs and
# NO last-bar pokes (the 14z-104 rig, HP alone) must fail last_bar(); a leg with no KO is DEAD, never caught.
for ctl, leg, vic in (("ko-without-last-bar", "kctl_nolast", ["2"]), ("dko-without-last-bar", "dctl_nolast", ["1", "2"])):
    rows = load(leg)
    if not rows:
        print(f"CONTROL DEAD: {ctl} — the control leg {leg} produced no samples"); errs.append(f"{ctl} dead"); continue
    adv = [fr for fr in sorted(rows) if rows[fr]["rounds"] >= 1]
    e = last_bar(rows, adv[0] if adv else max(rows), vic)
    if e and "never went negative" not in e:
        print(f"CONTROL FIRED: {ctl} — with HP alone ({leg}) the last-bar check fails: {e[:150]}")
    else:
        print(f"CONTROL DEAD: {ctl} — the HP-only leg {leg} {'passed the last-bar check' if not e else 'had no KO'}")
        errs.append(f"{ctl} dead")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo 'PASS: the deliberate edges hold — a last-bar KO-in-capture judges both'
echo '      directions (side $FF8105, the thrower'"'"'s perfect flag $FF8120),'
echo '      last-bar mirror trades draw ($FF8105 = 3), frame-1 inputs serve'
