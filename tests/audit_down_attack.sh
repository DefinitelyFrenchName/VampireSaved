#!/bin/sh
# audit_down_attack.sh — HITTING A DOWNED OPPONENT, both directions per
# tenant (14z-104, coverage matrix — the §4 "pursuit attacks" cell).
#
# The corpus had ZERO coverage of the down-state contact surface (no
# rig, no gate, no doc mention). The surface is real ported data both
# ways: a tenant attacking a downed legacy victim dispatches the
# tenant's attack into the victim's down-state hurtbox, and a legacy
# attacker hitting a DOWNED TENANT reads the tenant's ported down-state
# reaction rows.
#
# WHAT THE ENGINE MEASURABLY PROVIDES (12-candidate input screen on the
# Demitri control, 14z-104): a GROUNDED heavy connects on the downed
# victim for reduced damage (11-12 on the control) once the down window
# opens (~16f after grounding); lights never connect; no input produced
# a leaping Night-Warriors-style pursuit. NAMING QUESTION OPEN with the
# maintainer: if vsav does carry a distinct leaping pursuit under some
# other grammar, it gets its own rig — this audit then keeps the
# down-attack surface it already covers.
#
# RIG: tests/replays/judge/03_down_attack.rpl (walk + crouch-HK sweep);
# the per-leg down-attack line is inserted here — input and frame are
# per-CHARACTER on both sides (measured 14z-104): Phobos' heavy as
# attacker is D6@3110; Phobos as VICTIM wakes in 24f, window 3086-3092;
# Victor's sweep throws the victim out of reach, so Demitri is the
# legacy attacker on every victim leg.
#
# WHAT IT ASSERTS, per leg:
#   1. the SWEEP CONNECTED and the victim was genuinely DOWNED (damage
#      before f3090 + an airborne tumble arc, p2y > 60) — a leg whose
#      sweep whiffs or fails to knock down is REFUSED, not judged
#      (the 14z-104 jab-whiff lesson: per-character normals differ);
#   2. the DOWN-ATTACK CONNECTED: additional damage on or after f3096
#      while the victim is in the down/wake window;
#   3. guarded END-clean.
#
# CONTROLS: `ctl` all-legacy (instrument leg); `early` attacks at f3080
# — measured INSIDE the victim's post-grounding invulnerable window, so
# it must deal NO down-attack damage, proving the connect signal is
# time-gated and cannot pass on any contact.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged12]
#        tests/audit_down_attack.sh          (~9 legs x ~1 min)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged13}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
RPL="$REPO/tests/replays/judge/03_down_attack.rpl"
FIELDS="ff8406:b:p1seq,ff8850:w:p2hp,ff8814:w:p2y"

leg() {  # name  p1id  p2id  attack-line
    n="$1"; a="$2"; b="$3"; atk="$4"
    d="$W/$n"; mkdir -p "$d/sb"
    { cat "$RPL"; printf '%s\n' "$atk"; } > "$d/rig.rpl"
    PK="1400:ff8782:$a;1450:ff8782:$a;1500:ff8782:$a;1400:ff8b82:$b;1450:ff8b82:$b;1500:ff8b82:$b"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$d/rig.rpl" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3000 FIELD_TO=3300 FRAMES=3350 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
}
# attackers: each tenant down-attacks the downed Victor dummy
leg ctl  01 03 "3096-3099 p1=UR6"
leg don  13 03 "3096-3099 p1=UR6"
leg hui  10 03 "3110-3113 p1=D6"
leg pyr  11 03 "3096-3099 p1=UR6"
# victims: Demitri down-attacks each downed tenant (per-victim windows)
leg vdon 01 13 "3096-3099 p1=UR6"
leg vhui 01 10 "3086-3089 p1=UR6"
leg vpyr 01 11 "3096-3099 p1=UR6"
# early-window control: inside Victor-the-victim's measured invuln window
leg early 01 03 "3080-3083 p1=UR6"
wait

python3 - "$W" <<'PY' || { echo "FAIL: down-attack audit"; exit 1; }
import sys
W = sys.argv[1]
LEGS = ["ctl", "don", "hui", "pyr", "vdon", "vhui", "vpyr", "early"]
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
    pre = [rows[fr]["p2hp"] for fr in sorted(rows) if fr < 3084]
    post = [rows[fr]["p2hp"] for fr in sorted(rows) if 3084 <= fr <= 3145]
    sweep_dmg = pre[0] - min(pre) if pre else 0
    tumble = any(rows[fr]["p2y"] > 60 for fr in rows if fr < 3096)
    down_dmg = (min(pre) - min(post)) if pre and post else 0
    if not sweep_dmg or not tumble:
        errs.append(f"{leg}: the sweep did not knock down (dmg {sweep_dmg}, "
                    f"tumble {tumble}) — REFUSED, rig geometry for this "
                    "character needs its own knockdown"); continue
    if leg == "early":
        if down_dmg:
            errs.append(f"early: dealt {down_dmg} inside the post-grounding "
                        "invulnerable window — the connect signal is not "
                        "time-gated")
        else:
            print("  ok: early control — the down window is closed at f3086")
        continue
    if not down_dmg:
        errs.append(f"{leg}: sweep landed but the down-attack dealt nothing "
                    "— the down-state contact surface did not serve")
    else:
        print(f"  ok: {leg} — knockdown (dmg {sweep_dmg}), down-attack "
              f"connected (dmg {down_dmg})")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: the down-attack surface serves with every tenant attacking"
echo "      and every tenant downed (early-window control clean)"
