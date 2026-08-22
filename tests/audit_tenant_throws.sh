#!/bin/sh
# audit_tenant_throws.sh — NORMAL THROWS, both directions per tenant
# (14z-104, coverage matrix).
#
# §4 mandates throw/tech coverage per ported character. The corpus had
# command grabs (H: 80/Circuit Scrapper, D: 65/96) but NO normal-throw
# rig for Pyron at all, and no systematic tenant-as-victim legs. This
# audit runs the plain forward throw (point-blank 6+HP) with every
# tenant THROWING a legacy dummy, and Victor THROWING every tenant —
# the victim direction exercises the #104 capture-keyframe port (every
# attacker's capture_kf block; tenants hold native capture records).
#
# RIG: tests/replays/judge/02_throw.rpl — walk to point-blank, 6+HP.
# The victim is a no-input dummy (cannot tech), so a whiff means rig
# geometry, never a tech escape.
#
# THE THROW SIGNATURE (measured on the Demitri control, 14z-104): the
# attacker enters its attack/throw state, the victim takes damage
# (0x0D on the control) AND leaves the ground in the toss arc (p2y
# rises >= 20px off the floor value 40) within the window. A leg with
# NO damage is REFUSED (rig geometry — the 14z-104 jab-whiff lesson),
# never passed and never read as a tech.
#
# CONTROLS: `ctl` all-legacy (instrument leg); `whiff` (no walk — the
# throw input at spawn range) must deal NO damage, proving the connect
# signal is load-bearing.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged12]
#        tests/audit_tenant_throws.sh          (~9 legs x ~1 min)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged13}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
RPL="$REPO/tests/replays/judge/02_throw.rpl"
FIELDS="ff8406:b:p1seq,ff8806:b:p2seq,ff8850:w:p2hp,ff8814:w:p2y"

leg() {  # name  p1id  p2id  frames-window
    n="$1"; a="$2"; b="$3"
    d="$W/$n"; mkdir -p "$d/sb"
    PK="1400:ff8782:$a;1450:ff8782:$a;1500:ff8782:$a;1400:ff8b82:$b;1450:ff8b82:$b;1500:ff8b82:$b"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$4" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3000 FIELD_TO=3400 FRAMES=3450 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
}
# the whiff-control variant: the same inputs with the walk stripped
sed 's/^2860-3005 p1=R$//' "$RPL" > "$W/whiff.rpl"

leg ctl  01 03 "$RPL"
leg don  13 03 "$RPL"
leg hui  10 03 "$RPL"
leg pyr  11 03 "$RPL"
leg vctl 03 01 "$RPL"
leg vdon 03 13 "$RPL"
leg vhui 03 10 "$RPL"
leg vpyr 03 11 "$RPL"
leg whiff 01 03 "$W/whiff.rpl"
wait

python3 - "$W" <<'PY' || { echo "FAIL: tenant throws audit"; exit 1; }
import sys
W = sys.argv[1]
LEGS = ["ctl", "don", "hui", "pyr", "vctl", "vdon", "vhui", "vpyr", "whiff"]
GROUND = 40
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
    hp = [rows[fr]["p2hp"] for fr in sorted(rows) if rows[fr]["p2hp"]]
    dmg = (hp[0] - min(hp)) if hp else 0
    tossed = [fr for fr in sorted(rows) if rows[fr]["p2y"] >= GROUND + 20]
    if leg == "whiff":
        if dmg:
            errs.append(f"whiff: dealt {dmg} at spawn range — the connect "
                        "signal is not load-bearing")
        else:
            print("  ok: whiff control — no contact at spawn range")
        continue
    if not dmg:
        errs.append(f"{leg}: NO damage — the throw never connected "
                    "(rig geometry; the victim is a dummy and cannot "
                    "tech). REFUSED, not judged."); continue
    if not tossed:
        errs.append(f"{leg}: damage {dmg} but the victim never left the "
                    "ground — a strike connected, not the throw; the "
                    "leg is measuring the wrong event"); continue
    print(f"  ok: {leg} — throw connected (damage {dmg}, "
          f"toss peak y={max(rows[fr]['p2y'] for fr in tossed)})")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: the normal throw connects with every tenant as thrower and"
echo "      as victim (whiff control clean)"
