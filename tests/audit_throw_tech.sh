#!/bin/sh
# audit_throw_tech.sh — THE THROW TECH-HIT (escape), both directions per
# tenant (14z-104 (3); coverage matrix gap 1's second half).
#
# MEASURED (legacy control, 14z-104 (3)): the tech registers as the
# victim's own throw input (forward + HP) held from ~2 frames AFTER the
# grab connects; it HALVES the throw damage (control: 13 -> 7) while
# the escape flip still arcs. An input on the SAME frame as the grab is
# the throw-vs-throw interaction instead (both whiff, 0 damage) — a
# different event, deliberately not this audit's subject.
#
# WHAT IT ASSERTS, per leg (rig judge/02_throw.rpl + the victim's tech
# input at 3012-3018): the teched damage equals the FROZEN value —
# escaper legs (each tenant techs Demitri's throw): all tech to the
# uniform 7 (measured; the tenants' ported reaction rows honor the
# escape); thrower legs (Victor techs each tenant's throw): per-throw
# frozen values (thui 14 -> 7, tpyr 12 -> 2). DONOVAN'S throw measures
# IDENTICAL with and without the tech input (5/5, same toss arc) — and
# NATIVE vsav2 measures the same 5/5 identity, so that is the ported
# design, frozen here as the tdon expectation (native-anchored).
#
# CONTROL: `notech` (no victim input) must deal the FULL 13 — proves
# the tech input is load-bearing and the reduced values cannot appear
# on their own.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged12]
#        tests/audit_throw_tech.sh          (~8 legs x ~1 min)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged13}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
BASE="$REPO/tests/replays/judge/02_throw.rpl"
FIELDS="ff8850:w:p2hp,ff8814:w:p2y"
# one throw only (strip the rig's second attempt), tech input held 3012-3018
sed 's/^3100-3104 p1=R3$//' "$BASE" > "$W/one.rpl"
{ cat "$W/one.rpl"; echo "3012-3018 p2=L3"; } > "$W/tech.rpl"

leg() {  # name  p1id  p2id  replay
    n="$1"; a="$2"; b="$3"
    d="$W/$n"; mkdir -p "$d/sb"
    PK="1400:ff8782:$a;1450:ff8782:$a;1500:ff8782:$a;1400:ff8b82:$b;1450:ff8b82:$b;1500:ff8b82:$b"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$4" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3000 FIELD_TO=3200 FRAMES=3250 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
}
# tenants ESCAPE Demitri's throw
leg e03  01 03 "$W/tech.rpl"
leg edon 01 13 "$W/tech.rpl"
leg ehui 01 10 "$W/tech.rpl"
leg epyr 01 11 "$W/tech.rpl"
# Victor techs each TENANT's throw
leg tdon 13 03 "$W/tech.rpl"
leg thui 10 03 "$W/tech.rpl"
leg tpyr 11 03 "$W/tech.rpl"
# the discriminating control: no tech input -> full damage
leg notech 01 03 "$W/one.rpl"
wait

python3 - "$W" <<'PY' || { echo "FAIL: throw-tech audit"; exit 1; }
import sys
W = sys.argv[1]
# FROZEN (14z-104 (3), measured on merged-m5; tdon native-anchored 5/5).
WANT = {"e03": 7, "edon": 7, "ehui": 7, "epyr": 7,
        "tdon": 5, "thui": 7, "tpyr": 2, "notech": 13}
errs = []
for leg, want in WANT.items():
    rows = {}
    for line in open(f"{W}/{leg}/field.txt"):
        f = line.split()
        if len(f) < 3 or f[0] != "F": continue
        d = dict(kv.split("=") for kv in f[2:])
        rows[int(f[1])] = {k: int(v) for k, v in d.items()}
    if not rows:
        errs.append(f"{leg}: no field samples — dead leg"); continue
    hp = [rows[fr]["p2hp"] for fr in sorted(rows) if rows[fr]["p2hp"]]
    if not hp or hp[0] != 0x120:
        errs.append(f"{leg}: match not live"); continue
    dmg = hp[0] - min(hp)
    if dmg == 0:
        errs.append(f"{leg}: the throw never connected (0 damage) — "
                    "REFUSED, rig geometry; not read as a tech"); continue
    if dmg != want:
        errs.append(f"{leg}: teched damage {dmg}, frozen value {want} — "
                    "the tech outcome moved; name the mechanism before "
                    "absorbing")
    else:
        print(f"  ok: {leg} — damage {dmg} (frozen)")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: the throw tech halves damage with every tenant escaping and"
echo "      every tenant being teched (tdon = the native-anchored 5/5"
echo "      identity; no-tech control at full damage)"
