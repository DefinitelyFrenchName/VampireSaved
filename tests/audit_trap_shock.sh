#!/bin/sh
# audit_trap_shock.sh — the Plasma Trap dome inflicts SHOCK (14z-85g(2),
# maintainer-ruled option (a) 2026-08-14). On-demand, ~4 min (2 runs).
#
# THE MECHANISM THIS LOCKS: the dome's hit records carry vs2's EXTENDED
# class 0x52, which vsavj's victim-reaction jump table (PRG:0x2385C)
# does not reach (entry[0x52] = code bytes -> a wild-but-lucky plain
# hit). The ruled fix: the two hitbox_proj class bytes remapped
# 0x52 -> 0x06 (vs2's OWN table aliases 0x52 == 0x06 -> the shock
# handler; vsavj entry[0x06] = its native electric-shake 0x23AC8, a
# structural twin of vs2's 0x52 handler minus the attacker-freeze
# exemption). KNOWN, MAINTAINER-ACCEPTED DEVIATION: Phobos receives
# the normal 11f attacker hit-freeze on trap connect (vs2 exempts him)
# — asserted PRESENT here, so a silent drift in either direction is
# loud.
#
# THE VERDICT TELLS (state-level, no debugger): during the dome hit
# window the victim must show class 0x06 (ours; native shows its own
# 0x52) AND shock sub-state seq+0x07 == 4 with the freeze 0x18 decay.
# Pre-fix builds (huitzil-m9-) show class 0x52 + seq7 == 2 (plain
# hit) on ours — this audit FAILS there by design.
#
# Usage: ROMDIR=... tests/audit_trap_shock.sh [builddir]
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-85g(2) (~4 min, 2 parallel): the trap dome inflicts SHOCK — rig 92
#   (deep-overlap, walk N=60) on ours + native; ours must show class 0x06 (the
#   ruled remap) + seq7==4 + freeze>=0x10, native its own 0x52; ALSO asserts
#   the accepted deviation (Phobos' 11f attacker freeze) PRESENT so drift is
#   loud. Fails on huitzil-m9- by design
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/hui54}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
WIDE_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$WIDE_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }

RPL="$PWD/tests/replays/hui/92_hui_trap_shock.rpl"
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
DF="$(python3 -c "print(';'.join(f'{f}:ff8800-ff89ff;{f}:ff8400-ff85ff' for f in range(3480,3620,2)))")"
BUILD_RP="$(abspath "$BUILD")/rompath"

mkdir -p "$W/ours/s1" "$W/native/s1"
( cd "$W/ours" && MAME_BIN="$WIDE_BIN" MAME_ROMPATH="$BUILD_RP;$ROMDIR" \
  POKES="$PK" DUMPS="$DF" FRAMES=3640 \
  "$REPO/tools/run_replay_mame.sh" vsavjw "$RPL" ram.log s1 >out 2>&1 ) &
( cd "$W/native" && POKES="$PK" DUMPS="$DF" FRAMES=3640 \
  "$REPO/tools/run_replay_mame.sh" vsav2 "$RPL" ram.log s1 >out 2>&1 ) &
wait
for leg in ours native; do
    ls "$W/$leg"/dump_*_ff8800.bin >/dev/null 2>&1 || {
        echo "FAIL: $leg leg produced no dumps:"; tail -8 "$W/$leg/out"; exit 1; }
done

python3 - "$W" <<'PY'
import glob, sys, struct
W = sys.argv[1]
EXPECT_CLS = {"ours": 0x06, "native": 0x52}   # ours = the ruled remap

def leg_state(leg):
    rows = []
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ff8800.bin"),
                    key=lambda p: int(p.split("_")[-2])):
        fr = int(f.split("_")[-2])
        b = open(f, "rb").read()
        a = open(f.replace("ff8800", "ff8400"), "rb").read()
        hp = struct.unpack(">H", b[0x50:0x52])[0]
        rows.append((fr, hp, b[0x54], b[0x5C], b[0x07], a[0x5C]))
    return rows

errs = []
for leg in ("ours", "native"):
    rows = leg_state(leg)
    hit = [r for r in rows if r[1] < 288]
    if not hit:
        errs.append(f"{leg}: the dome never connected (P2 HP never below "
                    "288) — the rig's spacing broke; verdict vacuous")
        continue
    shock = [r for r in hit if r[2] == EXPECT_CLS[leg] and r[4] == 4
             and r[3] >= 0x10]
    if not shock:
        seen = sorted({(hex(r[2]), r[4]) for r in hit})
        errs.append(f"{leg}: NO shock install — expected class "
                    f"{EXPECT_CLS[leg]:#x} + seq7==4 + freeze>=0x10 in the "
                    f"hit window; saw (class, seq7) {seen}")
        continue
    print(f"  ok: {leg} — dome hit at f{hit[0][0]}, shock install "
          f"(class {EXPECT_CLS[leg]:#x}, seq7=4, freeze {shock[0][3]:#x})")
    if leg == "ours":
        atk = [r for r in hit if r[5] > 0]
        if not atk:
            errs.append("ours: attacker freeze ABSENT — the accepted "
                        "deviation (Phobos 0x0B on trap connect) drifted; "
                        "if this is option (b) landing, re-freeze "
                        "deliberately")
        else:
            print(f"  ok: ours — attacker freeze present "
                  f"({atk[0][5]:#x} at f{atk[0][0]}; the accepted deviation)")

# Verdict control: the checker must fail on the pre-fix shape
# (class 0x52 + seq7==2 on ours).
fake = [(3500, 285, 0x52, 0x0C, 2, 0)]
ctl = [r for r in fake if r[2] == EXPECT_CLS["ours"] and r[4] == 4]
if ctl:
    errs.append("control PASSED on the pre-fix shape — verdict logic dead")
else:
    print("  ok: verdict control — pre-fix shape fails as designed")

for e in errs: print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
rc=$?
[ "$rc" = 0 ] && echo "audit_trap_shock: PASS (dome shock live, deviation as ruled)" \
             || echo "audit_trap_shock: FAILURES"
exit "$rc"
