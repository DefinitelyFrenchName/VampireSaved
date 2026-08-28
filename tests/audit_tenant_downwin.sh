#!/bin/sh
# audit_tenant_downwin.sh — THE LIFE-MARKER TRANSITION (KO-path judge),
# both directions per tenant (14z-104).
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
# contact kills. No timer poke — the transition here is the KO path.
#
# WHAT IT ASSERTS, per leg: the KO happens (victim HP crosses to 0/dead),
# the round ADVANCES ($FF810E 0 -> 1) with the winner code $FF8120 ==
# 0xFF (P1 always wins the down here — P1 is the attacker in every leg),
# and round 2 spawns live (both HP refill to 0x120). Guarded END-clean.
#
# CONTROLS: leg `ctl`/`vctl` are all-legacy (instrument moved if red);
# leg `nopoke` omits the HP poke — the jab must NOT produce a round
# transition in-window, proving the KO poke is load-bearing and the
# "round advanced" signal cannot pass vacuously.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged12]
#        tests/audit_tenant_downwin.sh          (~9 legs x ~1.5 min)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged17}"  # re-pointed 14z-113 (merged-m10: one-zip repackaging of merged-m9, same program)
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
RPL="$REPO/tests/replays/judge/01_timeout_lead.rpl"
FIELDS="ff8120:b:winner,ff810e:b:rounds,ff8450:w:p1hp,ff8850:w:p2hp,ff891f:b:p2dead,ff8109:b:timer"
KOPK=";3006:ff8850:0001;3008:ff8852:0001"   # dummy real+white -> 1; ANY contact kills
   # (4 was not enough: Pyron's LP measured 2 damage at this spacing, 14z-104)

leg() {  # name  p1id  p2id  extra-pokes
    n="$1"; a="$2"; b="$3"; extra="$4"
    d="$W/$n"; mkdir -p "$d/sb"
    PK="1400:ff8782:$a;1450:ff8782:$a;1500:ff8782:$a;1400:ff8b82:$b;1450:ff8b82:$b;1500:ff8b82:$b$extra"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$RPL" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3000 FIELD_TO=5200 FRAMES=5250 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
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
# discrimination control: no HP poke -> the jab must NOT end the round
leg nopoke 01 03 ""
wait

python3 - "$W" <<'PY' || { echo "FAIL: tenant downwin audit"; exit 1; }
import sys
W = sys.argv[1]
LEGS = ["ctl", "don", "hui", "pyr", "vctl", "vdon", "vhui", "vpyr", "nopoke"]
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
    advanced = [fr for fr in sorted(rows) if rows[fr]["rounds"] >= 1]
    if leg == "nopoke":
        if advanced:
            errs.append("nopoke: the round advanced WITHOUT the KO poke — "
                        "the transition signal is vacuous")
        else:
            print("  ok: nopoke control — one jab does not end a round")
        continue
    if not advanced:
        errs.append(f"{leg}: the round never advanced — the KO was not "
                    "judged (the #103 stall shape; check the victim's "
                    "white-HP path)"); continue
    winners = {rows[fr]["winner"] for fr in advanced}
    if winners != {0xFF}:
        errs.append(f"{leg}: winner code(s) {sorted(hex(w) for w in winners)}, "
                    "expected 0xff (P1 is the attacker in every leg)")
        continue
    refill = [fr for fr in advanced
              if rows[fr]["p1hp"] == 0x120 and rows[fr]["p2hp"] == 0x120]
    if not refill:
        errs.append(f"{leg}: round 2 never spawned with refilled HP — "
                    "the match stalled after the down")
    else:
        print(f"  ok: {leg} — KO judged at f{advanced[0]}, "
              f"round 2 live at f{refill[0]}")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: the KO-path life-marker transition judges cleanly with every"
echo "      tenant as winner AND as victim (controls green)"
