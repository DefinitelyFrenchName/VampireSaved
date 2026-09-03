#!/bin/sh
# audit_edge_cases.sh — DELIBERATE STATE-TRANSITION EDGES per tenant
# (14z-104 (4); coverage matrix gap 2 — §4's edge-case bias, served
# deliberately instead of incidentally).
#
# Three families, all on the judge/pokes scaffolding, all guarded by
# field-liveness (a crash kills a leg's samples and fails it):
#
#   1. KO DURING CAPTURE (throw-KO): the victim is poked to 2 HP and
#      thrown — the kill lands mid-throw, inside the capture states.
#      Every tenant kills this way AND dies this way (a tenant dying
#      inside a legacy capture runs its ported death-from-capture
#      path). Judge must settle: round advances, winner 0xFF.
#      EXCEPT PHOBOS AS THROWER: his throw CANNOT finish an opponent —
#      the would-be kill converts to a transient death flag + an HP
#      RESTORE to exactly half (144/144) with NO round transition, and
#      native vsav2 measures the IDENTICAL frame shape (14z-104 (4)).
#      A vs2 grab-family property faithfully ported (beside his
#      untechable sweep), frozen native-anchored as the tko_hui leg.
#   2. DOUBLE KO (the trade): a MIRROR match with both fighters poked
#      to 1 HP and both jabbing on the same frame — mirrors guarantee
#      symmetric startup, so the jabs trade and both die. The judge's
#      DRAW code is $FF8120 == 0x00 (measured 14z-104 (4) — the third
#      value of the winner byte, beside 0xFF/0x01).
#   3. FRAME-1 EX: the DP+2K input starting on the FIRST live match
#      frame (f2886) with poked meter. Frozen per leg from measurement:
#      Phobos/Pyron/Donovan fire their EX (stock decrements) — asserts
#      the input buffer and the EX machinery are live from frame one;
#      the Demitri control's and Donovan's DP+2K are not their EX
#      shapes and must simply produce an action without a stock spend
#      (measured 14z-104 (4)); Phobos and Pyron fire theirs.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged22]
#        tests/audit_edge_cases.sh          (~14 legs x ~1 min)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged22}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
FIELDS="ff8450:w:p1hp,ff8850:w:p2hp,ff8120:b:winner,ff810e:b:rounds,ff8509:b:stk,ff8406:b:p1seq"

sed 's/^3100-3104 p1=R3$//' "$REPO/tests/replays/judge/02_throw.rpl" > "$W/throw.rpl"
{ sed 's/^3010-3014 p1=R3$/3010-3012 p1=1/; s/^3100-3104 p1=R3$//' \
    "$REPO/tests/replays/judge/02_throw.rpl"; echo "3010-3012 p2=1"; } > "$W/dko.rpl"
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

leg() {  # name  p1id  p2id  replay  extra-pokes
    n="$1"; a="$2"; b="$3"
    d="$W/$n"; mkdir -p "$d/sb"
    PK="1400:ff8782:$a;1450:ff8782:$a;1500:ff8782:$a;1400:ff8b82:$b;1450:ff8b82:$b;1500:ff8b82:$b$5"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$4" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=2880 FIELD_TO=5100 FRAMES=5150 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
}
KO=";3006:ff8850:0002;3008:ff8852:0002"
DK=";3004:ff8450:0001;3005:ff8452:0001;3006:ff8850:0001;3007:ff8852:0001"
MT=";2860:ff8509:03;2880:ff8509:03"
# family 1: throw-KO, both directions
leg tko_ctl 01 03 "$W/throw.rpl" "$KO"
leg tko_don 13 03 "$W/throw.rpl" "$KO"
leg tko_hui 10 03 "$W/throw.rpl" "$KO"
leg tko_pyr 11 03 "$W/throw.rpl" "$KO"
leg vko_don 03 13 "$W/throw.rpl" "$KO"
wait
leg vko_hui 03 10 "$W/throw.rpl" "$KO"
leg vko_pyr 03 11 "$W/throw.rpl" "$KO"
# family 2: double-KO mirrors
leg dko_ctl 01 01 "$W/dko.rpl" "$DK"
leg dko_don 13 13 "$W/dko.rpl" "$DK"
leg dko_hui 10 10 "$W/dko.rpl" "$DK"
wait
leg dko_pyr 11 11 "$W/dko.rpl" "$DK"
# family 3: frame-1 EX
leg f1_ctl 01 03 "$W/frame1.rpl" "$MT"
leg f1_don 13 03 "$W/frame1.rpl" "$MT"
leg f1_hui 10 03 "$W/frame1.rpl" "$MT"
leg f1_pyr 11 03 "$W/frame1.rpl" "$MT"
wait

python3 - "$W" <<'PY' || { echo "FAIL: edge-case audit"; exit 1; }
import sys
W = sys.argv[1]
errs = []
def load(leg):
    rows = {}
    for line in open(f"{W}/{leg}/field.txt"):
        f = line.split()
        if len(f) < 3 or f[0] != "F": continue
        d = dict(kv.split("=") for kv in f[2:])
        rows[int(f[1])] = {k: int(v) for k, v in d.items()}
    return rows
for leg in ("tko_ctl","tko_don","tko_hui","tko_pyr","vko_don","vko_hui","vko_pyr"):
    rows = load(leg)
    if not rows: errs.append(f"{leg}: dead leg"); continue
    adv = [fr for fr in sorted(rows) if rows[fr]["rounds"] >= 1]
    if leg == "tko_hui":
        # Phobos' throw cannot kill: native-anchored half-restore, no round.
        half = any(rows[fr]["p2hp"] == 144 for fr in rows)
        if adv:
            errs.append("tko_hui: Phobos' throw KILLED — native vs2 half-"
                        "restores instead; the grab-family property moved")
        elif not half:
            errs.append("tko_hui: neither a round nor the 144 half-restore "
                        "— the leg measured neither known outcome")
        else:
            print("  ok: tko_hui — the no-kill half-restore held (144/144, "
                  "no round; the native-anchored vs2 property)")
        continue
    if not adv:
        errs.append(f"{leg}: KO-in-capture never judged — the #103 shape "
                    "inside the throw states"); continue
    win = {rows[fr]["winner"] for fr in adv}
    if win != {0xFF}:
        errs.append(f"{leg}: winner {sorted(hex(w) for w in win)}, expected "
                    "0xff"); continue
    print(f"  ok: {leg} — throw-KO judged (round advanced f{adv[0]})")
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
    win = {rows[fr]["winner"] for fr in adv}
    if win != {0x00}:
        errs.append(f"{leg}: winner {sorted(hex(w) for w in win)}, expected "
                    "the DRAW code 0x00 — the trade did not double-KO "
                    "(mirror jabs must trade; if one side won, the jab "
                    "did not trade and the leg measures the wrong event)")
        continue
    print(f"  ok: {leg} — double-KO drawn (0x00) at f{adv[0]}")
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
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: the deliberate edges hold — KO-in-capture judges both"
echo "      directions, mirror trades draw (0x00), frame-1 inputs serve"
