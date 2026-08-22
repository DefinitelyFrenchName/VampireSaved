#!/bin/sh
# audit_ladder_selector.sh — THE ARCADE-LADDER SELECTOR, made rerunnable
# (14z-95, GitHub #99). On-demand, ~12 min (2 marathon runs, parallel).
#
# WHY IT EXISTS. #99 is a crash reported at the FIFTH arcade match, and the
# investigation produced a drivable probe for the ladder's state that lived
# only in a shell history. CLAUDE.md §4: every in-emulator probe becomes a
# scripted, rerunnable case before the session ends. This is that case, and it
# is what #99 resumes from.
#
# THE STATE IT WATCHES (docs/game/atlas/ram.md:73-74, 89):
#   $FF8100  the ladder STAGE index — drives the map banner AND the venue
#   $FF8110  the in-use MASK (btst, so MOD 32; "sound-state-fed, the
#            run-to-run lottery" — this is why 14z-85f was flaky)
#   $FF8114  the chosen index into the candidate pool
#   $FF8138  the scan bound (measured 6)
#   $FF8121  the venue byte
#
# THREE SECTIONS, and section 2 is the load-bearing one.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${LADDER_BUILD:-build/m3b_merged13}"
FRAMES="${LADDER_FRAMES:-40700}"
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN

RPL="$REPO/tests/replays/26_don_arcade_mash.rpl"
PICK="1704:ff8782:13;1760:ff8782:13;1900:ff8782:13;2100:ff8782:13;2400:ff8782:13"
# saturate the mask across the whole pre-selection window of match 2
SAT="$(python3 -c "print(';'.join(f'{f}:ff8110:ff;{f}:ff8111:ff;{f}:ff8112:ff;{f}:ff8113:ff' for f in range(7100,7290,10)))")"
DF="$(python3 -c "import sys;print(';'.join(f'{f}:ff8100-ff8140' for f in range(2400, int(sys.argv[1]) - 80, 60)))" "$FRAMES")"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok()  { echo "  ok: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

for leg in ctl sat; do
    d="$W/$leg"; mkdir -p "$d/s1"
    P="$PICK"; [ "$leg" = sat ] && P="$PICK;$SAT"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      POKES="$P" DUMPS="$DF" FRAMES="$FRAMES" GUARD_DEBUG=0 \
      "$REPO/tools/run_replay_guarded.sh" vsavjw "$RPL" out.log s1 >emu 2>&1 ) &
done
wait

echo "== 0: rig liveness — both legs must complete and the probe must fire"
for leg in ctl sat; do
    grep -q "^END " "$W/$leg/out.log" 2>/dev/null \
        || { bad "$leg leg did not END (crash or dead rig)"
             grep -m1 "^CRASH\|^REGS" "$W/$leg/out.log" 2>/dev/null || tail -2 "$W/$leg/emu"; }
    n=$(ls "$W/$leg"/dump_*_ff8100.bin 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" -gt 100 ] || bad "$leg leg produced only $n samples — probe dead"
done

python3 - "$W" <<'PY' || fail=1
import glob, sys, struct
W = sys.argv[1]
def timeline(leg):
    out, prev = [], None
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ff8100.bin"),
                    key=lambda p: int(p.split("_")[-2])):
        fr = int(f.split("_")[-2]); b = open(f, "rb").read()
        cur = (struct.unpack(">H", b[0:2])[0], struct.unpack(">I", b[0x10:0x14])[0],
               struct.unpack(">H", b[0x14:0x16])[0], struct.unpack(">H", b[0x38:0x3a])[0])
        if cur != prev:
            out.append((fr,) + cur); prev = cur
    return out

rc = 0
ctl = timeline("ctl")
print("\n== 1: the selector timeline, and the COVERAGE it implies")
for fr, st, mk, ix, bd in ctl:
    print(f"     f{fr:5d}  stage={st:#06x}  mask={mk:#010x}  idx={ix:#04x}  bound={bd:#04x}")

# A ladder SELECTION is a transition that moves the chosen index or the mask.
sel = [r for i, r in enumerate(ctl) if i and (r[3] != ctl[i-1][3] or r[2] != ctl[i-1][2])]
EXPECT_SEL = 1   # measured 14z-95: ONE index/mask advance in 40,620 frames
if len(sel) < EXPECT_SEL:
    print(f"FAIL: only {len(sel)} ladder advance(s) — fewer than the measured "
          f"{EXPECT_SEL}; the rig stopped reaching the ladder")
    rc = 1
elif len(sel) > EXPECT_SEL:
    print(f"  note: {len(sel)} ladder advances, MORE than the measured "
          f"{EXPECT_SEL} — the rig reaches further than it did. That is an "
          f"improvement and the #99 blocker may be gone; re-freeze deliberately.")
else:
    print(f"  ok: {len(sel)} ladder advance — matching the measured coverage.")
    print("      THIS IS THE #99 BLOCKER, quantified: the 40,620-frame marathon")
    print("      exercises TWO rungs of an eight-entry ladder and then drops to")
    print("      attract. The crash is reported at the FIFTH match.")

print("\n== 2: the scan CANNOT overrun its bound onto table A's 0x18")
# The dead crash hypothesis, locked as a regression gate. ram.md:89 records
# 0x18 at index 7 of all 36 table-A rows and the bound measures 6; if a future
# change let the scan reach index 7, class 0x18 (=24, a character that does
# not exist) would reach the opponent's $382 at character load — which WOULD
# be a crash of exactly #99's shape. Measured 14z-95: it clamps instead.
sat = timeline("sat")
sat_sel = [r for r in sat if r[2] == 0xffffffff and r[3] != 0]
if not sat_sel:
    print("FAIL: the saturated leg never selected with a full mask — the poke "
          "missed its window, so this section proves nothing")
    rc = 1
else:
    worst = max(r[3] for r in sat_sel)
    bound = sat_sel[0][4]
    if worst > bound:
        print(f"FAIL: with the mask saturated the scan reached index "
              f"{worst:#x} > bound {bound:#x} — it can now overrun onto "
              f"table A's 0x18 terminator. That is a crash path.")
        rc = 1
    else:
        print(f"  ok: saturated mask clamps at idx {worst:#x} <= bound "
              f"{bound:#x} (measured 14z-95: idx 0x06, stage 0x0016 — the "
              f"maximum LEGAL stage, not past it)")

print("\n== 3: the mask is LOAD-BEARING (it decides the stage)")
# If poking the mask changed nothing, sections 1-2 would be measuring a dead
# input and every reassurance above would be vacuous.
ctl_stages = {r[1] for r in ctl}
sat_stages = {r[1] for r in sat}
if ctl_stages == sat_stages:
    print(f"FAIL: saturating the in-use mask changed no stage ({sorted(map(hex,ctl_stages))}) "
          f"— the mask is not driving selection here, so this audit is vacuous")
    rc = 1
else:
    print(f"  ok: mask drives the stage — control {sorted(map(hex, ctl_stages))} "
          f"vs saturated {sorted(map(hex, sat_stages))}")
sys.exit(rc)
PY

[ "$fail" = 0 ] && echo "
PASS: ladder selector — coverage quantified, bound holds, mask load-bearing" \
    || { echo "FAIL: ladder selector"; exit 1; }
