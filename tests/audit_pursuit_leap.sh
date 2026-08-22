#!/bin/sh
# audit_pursuit_leap.sh — THE LEAPING PURSUIT ATTACK, both directions per
# tenant (14z-104; the §4 "pursuit attacks" cell's SECOND instrument,
# beside audit_down_attack's grounded OTG surface).
#
# The maintainer confirmed (2026-08-22) vsav retains the Night Warriors
# leaping pursuit: universal U + any P/K over a knocked-down opponent,
# per-character animations, ES variant on two buttons. MEASURED 14z-104
# on the merged build (legacy control = vanilla by the superset
# invariant):
#   - the input REGISTERS during the victim's knockdown FALL and the
#     early flat window; it is BUTTON-INDEPENDENT (U1/U2/U4/U6 all
#     produce the identical leap, seq 0x0E);
#   - the leap AIMS at the victim's position captured at INPUT time and
#     the arc is PER-CHARACTER (Demitri 33f to y=100; Donovan 27f to
#     y=102; Phobos 42f to y=88; Pyron 39f to y=88);
#   - a pursuit at a CORNERED victim lands beside the body (the wall
#     pushbox shoves the attacker off during descent) — vanilla
#     behavior, measured on the all-legacy control.
#
# WHAT IT ASSERTS, per leg (rig judge/03_down_attack.rpl + U3 during
# the fall):
#   attacker legs (each tenant sweeps + pursues): the pursuit STATE
#   (seq 0x0E) fires on the universal input, the leap goes genuinely
#   AIRBORNE (peak p1y >= 60), its duration sits in the per-character
#   plausible band [20,60] frames, and the run completes — the ported
#   per-character pursuit content EXECUTES (the row-31-class stub risk
#   this cell exists for).
#   victim legs (Demitri sweeps + pursues each downed TENANT): the leap
#   fires AT a downed tenant (their down state accepts the pursuit
#   targeting) and the run completes.
#
# NEGATIVE CONTROL: the same U3 input at f3200 — the victim long
# recovered — must NOT produce seq 0x0E (a plain jump instead), proving
# the pursuit state genuinely requires the downed victim.
#
# OPEN REFINEMENT (documented, not hidden): the CONNECT (pursuit damage
# landing) is a knife-edge of victim wake vs flight time in every rig
# geometry tried (12+ variants), INCLUDING the all-legacy control — so
# connect-verification needs a better setup on BOTH games before it can
# be asserted here, and its absence is a fact about the rig, not the
# port. The grounded down-attack damage surface is covered by
# audit_down_attack.sh.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged12]
#        tests/audit_pursuit_leap.sh          (~8 legs x ~1 min)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged13}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
BASE="$REPO/tests/replays/judge/03_down_attack.rpl"
FIELDS="ff8410:w:p1x,ff8414:w:p1y,ff8406:b:p1seq,ff8814:w:p2y,ff8850:w:p2hp"
{ cat "$BASE"; echo "3072-3075 p1=U3"; } > "$W/pursuit.rpl"
{ cat "$BASE"; echo "3200-3203 p1=U3"; } > "$W/late.rpl"

leg() {  # name  p1id  p2id  replay
    n="$1"; a="$2"; b="$3"
    d="$W/$n"; mkdir -p "$d/sb"
    PK="1400:ff8782:$a;1450:ff8782:$a;1500:ff8782:$a;1400:ff8b82:$b;1450:ff8b82:$b;1500:ff8b82:$b"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$4" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3020 FIELD_TO=3280 FRAMES=3330 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
}
leg ctl  01 03 "$W/pursuit.rpl"
leg don  13 03 "$W/pursuit.rpl"
leg hui  10 03 "$W/pursuit.rpl"
leg pyr  11 03 "$W/pursuit.rpl"
leg vdon 01 13 "$W/pursuit.rpl"
leg vhui 01 10 "$W/pursuit.rpl"
leg vpyr 01 11 "$W/pursuit.rpl"
leg late 01 03 "$W/late.rpl"
wait

python3 - "$W" <<'PY' || { echo "FAIL: pursuit-leap audit"; exit 1; }
import sys
W = sys.argv[1]
LEGS = ["ctl", "don", "hui", "pyr", "vdon", "vhui", "vpyr", "late"]
errs = []
for leg in LEGS:
    rows = {}
    for line in open(f"{W}/{leg}/field.txt"):
        f = line.split()
        if len(f) < 3 or f[0] != "F": continue
        d = dict(kv.split("=") for kv in f[2:])
        rows[int(f[1])] = {k: int(v) for k, v in d.items()}
    if not rows:
        errs.append(f"{leg}: no field samples — dead leg"); continue
    tumble = any(rows[fr]["p2y"] > 60 for fr in rows if fr < 3082)
    if not tumble:
        errs.append(f"{leg}: the sweep did not knock down — REFUSED "
                    "(rig geometry)"); continue
    if leg == "late":
        lateleap = [fr for fr in sorted(rows) if fr >= 3195
                    and rows[fr]["p1seq"] == 0x0E]
        if lateleap:
            errs.append("late control: the pursuit state fired with no "
                        "downed victim — the 0x0E signature is not "
                        "pursuit-specific, re-derive it")
        else:
            print("  ok: late control — no pursuit state without a "
                  "downed victim")
        continue
    leap = [fr for fr in sorted(rows) if fr >= 3068
            and rows[fr]["p1seq"] == 0x0E]
    if not leap:
        errs.append(f"{leg}: the pursuit never fired (no seq 0x0E on the "
                    "universal input) — the ported pursuit row did not "
                    "serve"); continue
    dur = leap[-1] - leap[0] + 1
    peak = max(rows[fr]["p1y"] for fr in leap)
    if peak < 60:
        errs.append(f"{leg}: pursuit state fired but never left the "
                    f"ground (peak y {peak}) — a stub, not a leap"); continue
    if not (20 <= dur <= 60):
        errs.append(f"{leg}: leap duration {dur}f outside the plausible "
                    "band [20,60] — the arc content moved"); continue
    print(f"  ok: {leg} — pursuit leap fired ({dur}f, peak y={peak})")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: the leaping pursuit fires with every tenant as attacker and"
echo "      targets every downed tenant (late control clean); connect"
echo "      verification is the documented open refinement"
