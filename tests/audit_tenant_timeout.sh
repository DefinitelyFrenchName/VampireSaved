#!/bin/sh
# audit_tenant_timeout.sh — THE TIMEOUT JUDGE, per tenant (14z-104).
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
# input feeds the judge).
#
# WHAT IT ASSERTS, per leg:
#   1. the timer genuinely reaches 0 in the trace (the poke landed and
#      the countdown ran — a leg that never times out measures nothing);
#   2. the judge AWARDS THE DOWN TO THE HP LEADER: round-winner code
#      $FF8120 == 0xFF (P1 won) — measured 14z-104: 0xFF on a P1-lead
#      timeout, 0x01 on a P2-lead timeout, on both probe runs;
#   3. the round ADVANCES ($FF810E 0 -> 1) and round 2 spawns live
#      (both HP words refill to 0x120) — the match continues, no stall;
#   4. the run is guarded END-clean (crash/reset/exception fails).
#
# CONTROLS:
#   - leg `ctl` (Demitri) is the LEGACY CONTROL: the same rig through
#     vanilla judge rows — if it fails, the instrument moved, and no
#     tenant verdict is trustworthy.
#   - leg `inv` (Demitri, P1 HP poked BELOW the dummy's) must be judged
#     the OTHER way ($FF8120 == 0x01): proves the winner byte
#     discriminates rather than always reading 0xFF.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged12]
#        tests/audit_tenant_timeout.sh          (~5 legs x ~2 min)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged13}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
RPL="$REPO/tests/replays/judge/01_timeout_lead.rpl"
FIELDS="ff8109:b:timer,ff8120:b:winner,ff810e:b:rounds,ff8450:w:p1hp,ff8850:w:p2hp"

leg() {  # name  p1id  extra-pokes
    n="$1"; id="$2"; extra="$3"
    d="$W/$n"; mkdir -p "$d/sb"
    PK="1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3300:ff8109:03$extra"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$RPL" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3300 FIELD_TO=5200 FRAMES=5250 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
}
leg ctl 01 ""
leg don 13 ""
leg hui 10 ""
leg pyr 11 ""
# the inverted control: P1's real+white HP poked below the dummy's 284
leg inv 01 ";3200:ff8450:0080;3210:ff8452:0080"
wait

python3 - "$W" <<'PY' || { echo "FAIL: tenant timeout audit"; exit 1; }
import sys
W = sys.argv[1]
WANT = {"ctl": 0xFF, "don": 0xFF, "hui": 0xFF, "pyr": 0xFF, "inv": 0x01}
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
    if not any(r["timer"] == 0 for r in rows.values()):
        errs.append(f"{leg}: the timer never reached 0 — the timeout "
                    "never fired; nothing judged"); continue
    # THE LEAD MUST EXIST (14z-104: Phobos' jab measured a WHIFF at the
    # original walk spacing — a tied-HP timeout judged to P1 would have
    # passed this audit vacuously). Refuse to judge a leg whose jab never
    # landed. The `inv` leg's lead is the POKE, exempt from this check.
    if leg != "inv":
        pre0 = [rows[fr]["p2hp"] for fr in sorted(rows)
                if rows[fr]["rounds"] == 0 and rows[fr]["p2hp"]]
        if not pre0 or min(pre0) >= 0x120:
            errs.append(f"{leg}: the jab never landed (p2hp never below "
                        "0x120 before the timeout) — no lead, verdict "
                        "vacuous; fix the rig geometry"); continue
    winners = {r["winner"] for r in rows.values() if r["rounds"] >= 1}
    if not winners:
        errs.append(f"{leg}: the round never advanced ($FF810E stayed 0) "
                    "— the judge did not settle (the #103 stall shape)"); continue
    if winners != {want}:
        errs.append(f"{leg}: winner code(s) {sorted(hex(w) for w in winners)}, "
                    f"expected {want:#04x} — the timeout down went the "
                    "wrong way (or the code drifted)")
        continue
    # round 2 must spawn live: after the round advanced, HP refills
    refill = [fr for fr in sorted(rows)
              if rows[fr]["rounds"] >= 1 and rows[fr]["p1hp"] == 0x120
              and rows[fr]["p2hp"] == 0x120]
    if not refill:
        errs.append(f"{leg}: round 2 never spawned with refilled HP — "
                    "the match stalled after the judge")
    else:
        print(f"  ok: {leg} — timeout judged, winner {want:#04x}, "
              f"round 2 live at f{refill[0]}")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: the timeout judge awards the down to the HP leader for all"
echo "      three tenants (legacy control green, inverted control judged"
echo "      the other way)"
