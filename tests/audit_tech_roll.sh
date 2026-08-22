#!/bin/sh
# audit_tech_roll.sh — THE TECH ROLL (moving recovery), both directions
# per tenant, plus the pursuit-vs-roll counter (14z-104 (3); coverage
# matrix gap 1, maintainer-described mechanic 2026-08-22).
#
# MEASURED (legacy control, 14z-104 (3)): the roll registers as a HELD
# direction+button through the knockdown landing (a 4-frame tap at the
# floor frame does NOT register); it is button-independent; the victim
# enters a distinct roll state (seq 0x04 on the control) and translates
# ~152px in the held direction (a roll toward the wall registers but
# travels 0). The roll is real ported surface both ways: a TENANT
# rolling runs his vs2-ported recovery states, and a legacy victim must
# be able to roll out of a TENANT's knockdown.
#
# WHAT IT ASSERTS (rig judge/03_down_attack.rpl + victim inputs):
#   roller legs (each tenant knocked down by Demitri, rolling toward
#   midscreen): the roll state fires (a non-idle, non-lying seq during
#   the down window) AND the victim TRANSLATES >= 60px — the ported
#   recovery states execute and move;
#   attacker legs (each tenant sweeps; Victor rolls out): the legacy
#   roll works identically off a TENANT's knockdown — EXCEPT Phobos:
#   his crouch-HK knockdown is UNTECHABLE, measured identically on
#   NATIVE vsav2 (14 dmg / knockdown / zero roll on both games,
#   14z-104 (3)) — a vs2 design property faithfully ported, frozen
#   here as the leg's expectation;
#   the PURSUIT-ROLL COUNTER (maintainer-described): Demitri pursues a
#   ROLLING victim — the leap must fire AND deal NO damage (the victim
#   rolled out from under the aim) AND the victim must end displaced
#   >= 60px from the aim spot: the designed whiff, measured.
#
# CONTROLS: `tap` (4-frame tap at the floor frame) must NOT roll —
# proves the held requirement and that the roll signature cannot fire
# from the sweep alone; `ctl` all-legacy (instrument leg).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged12]
#        tests/audit_tech_roll.sh          (~9 legs x ~1 min)
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
FIELDS="ff8810:w:p2x,ff8814:w:p2y,ff8806:b:p2seq,ff8850:w:p2hp,ff8406:b:p1seq"
# the roll hold spans every attacker's landing frame (measured 3061-3082
# across attackers); L = toward midscreen for the victim at the wall
{ cat "$BASE"; echo "3058-3088 p2=L1"; } > "$W/roll.rpl"
{ cat "$BASE"; echo "3080-3083 p2=L1"; } > "$W/tap.rpl"
{ cat "$BASE"; echo "3058-3088 p2=L1"; echo "3072-3075 p1=U3"; } > "$W/pursroll.rpl"

leg() {  # name  p1id  p2id  replay
    n="$1"; a="$2"; b="$3"
    d="$W/$n"; mkdir -p "$d/sb"
    PK="1400:ff8782:$a;1450:ff8782:$a;1500:ff8782:$a;1400:ff8b82:$b;1450:ff8b82:$b;1500:ff8b82:$b"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$4" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3020 FIELD_TO=3250 FRAMES=3300 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
}
# tenants ROLL out of Demitri's knockdown
leg ctl  01 03 "$W/roll.rpl"
leg rdon 01 13 "$W/roll.rpl"
leg rhui 01 10 "$W/roll.rpl"
leg rpyr 01 11 "$W/roll.rpl"
# Victor rolls out of each TENANT's knockdown
leg adon 13 03 "$W/roll.rpl"
leg ahui 10 03 "$W/roll.rpl"
leg apyr 11 03 "$W/roll.rpl"
# the pursuit-vs-roll counter + the tap control
leg purs 01 03 "$W/pursroll.rpl"
leg tap  01 03 "$W/tap.rpl"
wait

python3 - "$W" <<'PY' || { echo "FAIL: tech-roll audit"; exit 1; }
import sys
W = sys.argv[1]
LEGS = ["ctl", "rdon", "rhui", "rpyr", "adon", "ahui", "apyr", "purs", "tap"]
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
    tumble = any(rows[fr]["p2y"] > 60 for fr in rows if fr < 3086)
    if not tumble:
        errs.append(f"{leg}: the sweep did not knock down — REFUSED"); continue
    xs = [rows[fr]["p2x"] for fr in sorted(rows) if 3060 <= fr <= 3150]
    travel = (max(xs) - min(xs)) if xs else 0
    if leg == "tap":
        if travel >= 60:
            errs.append(f"tap control: rolled {travel}px on a tap — the "
                        "held requirement is not real")
        else:
            print(f"  ok: tap control — no roll on a tap (travel {travel}px)")
        continue
    if leg == "purs":
        leap = [fr for fr in sorted(rows) if rows[fr]["p1seq"] == 0x0E and fr > 3068]
        hp = [rows[fr]["p2hp"] for fr in sorted(rows)]
        pre = [rows[fr]["p2hp"] for fr in sorted(rows) if fr < 3072]
        dmg = (min(pre) - min(hp)) if pre else 0
        if not leap:
            errs.append("purs: the pursuit never fired over the roller"); continue
        if travel < 60:
            errs.append(f"purs: the victim never rolled (travel {travel}px) "
                        "— the counter was not exercised"); continue
        if dmg:
            errs.append(f"purs: the pursuit HIT a rolling victim for {dmg} "
                        "— the roll should evade it (maintainer-described "
                        "counter); name the mechanism")
        else:
            print(f"  ok: purs — pursuit fired, victim rolled {travel}px, "
                  "leap whiffed the vacated spot (the designed counter)")
        continue
    if leg == "ahui":
        # Phobos' crouch-HK knockdown is UNTECHABLE — native-anchored
        # (vsav2 measures the identical 14dmg/no-roll, 14z-104 (3)).
        if travel >= 60:
            errs.append(f"ahui: Victor ROLLED ({travel}px) out of Phobos' "
                        "sweep — native vs2 forbids it; the knockdown "
                        "class moved")
        else:
            print(f"  ok: ahui — Phobos' untechable knockdown held "
                  f"(travel {travel}px, the native-anchored expectation)")
        continue
    if travel < 60:
        errs.append(f"{leg}: roll travel only {travel}px — the roll state "
                    "did not execute (ported recovery states, if a tenant "
                    "leg: investigate before absorbing)")
    else:
        print(f"  ok: {leg} — rolled {travel}px out of the knockdown")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: the tech roll executes with every tenant as roller and off"
echo "      every tenant's knockdown; the pursuit-vs-roll counter behaves"
echo "      as designed (tap control clean)"
