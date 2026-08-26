#!/bin/sh
# audit_fg_parity.sh — Phobos' EX Final Guardian (623+2K) damage PARITY:
# the same replay on native vsav2 and on the build, per-attempt damage
# and tick counts compared against the frozen native staircase.
# On-demand, ~4 min (2 MAME runs, parallel).
#
# THE ITEM THIS LOCKS (14z-85f, closing the 14z-85e parity item): the
# beam ticks of FG are processed by the PORTED vs2 object-hit damage
# applier (vs2 0x28A6A, region x028122). Before the fix its A5-relative
# staging displacements were ported VERBATIM: scaled damage landed in
# vs2's work vars ($FF3494/96/98) which vsavj's post-process never
# reads ($FF3442/44/46) — 12 combo-counted ticks, ZERO HP (same-value
# class #4, docs/game/gotchas.md; the fix is Donovan's session-14n
# six-row port_patch family, propagated to huitzil.toml/pyron.toml).
# Measured before the fix on this replay: ours 1/1/1/1/1 HP vs native
# 23/23/23/23/52. After: bit-exact parity.
#
# THE FROZEN STAIRCASE (measured native vsav2, 14z-85f, and re-measured
# on the native leg EVERY run — a reference that drifts fails loudly):
#   attempts at f3266/3566/3866/4166/4466 (stock decrement = EX fired,
#   the 14z-85e downgrade trap), 12 HP-decrement events each,
#   damage 23/23/23/23/52 (the 5th lands cornered: 11 beam ticks + one
#   30 HP terminal hit).
#
# The replay is the 85_hui_df_vs2 opening (native-comparable pick flow:
# both ids poked, P2 human and idle) + five spaced 623+2K attempts —
# tests/replays/hui/89_hui_ex_fg_vs2.rpl documents the shape.
#
# Usage: ROMDIR=... tests/audit_fg_parity.sh [builddir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
   # RE-POINTED 14z-94 (GitHub #94): was build/m3b_merged, a pre-WIDE-v1.1 set
   # (19 members, no vsw.z01/z02) — the script could not run at all.
   # Its frozen inventory may still describe the OLD build: run it
   # before trusting a green, and re-measure rather than absorb.
BUILD="${1:-build/m3b_merged15}"  # re-pointed 14z-110b
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

RPL="$REPO/tests/replays/hui/89_hui_ex_fg_vs2.rpl"
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3120:ff8509:03;3900:ff8509:03;4300:ff8509:03"
DF=$(python3 -c "print(';'.join(f'{f}:ff8850-ff8853;{f}:ff8509-ff850a;{f}:ff8782-ff8783;{f}:ff8b82-ff8b83' for f in range(3150,5150,2)))")

run_leg() {  # $1 tag  $2 set  $3 rompath-or-empty
    d="$W/$1"; mkdir -p "$d"
    ( cd "$d" && \
      if [ -n "$3" ]; then MAME_ROMPATH="$3;$ROMDIR"; export MAME_ROMPATH; fi; \
      MAME_SANDBOX="$d/sb" POKES="$PK" REPLAY="$RPL" DUMPS="$DF" FRAMES=5220 \
      CHECKSUM_OUT="$d/c.ram" \
      "$REPO/tools/run_mame.sh" "$2" \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/out" 2>&1 )
}
run_leg native vsav2 "" &
run_leg ours vsavjw "$REPO/$BUILD/rompath" &
wait

python3 - "$W" <<'PY' || fail=1
import glob, sys
W = sys.argv[1]

# The frozen native staircase (14z-85f). BOTH legs must match it —
# the native leg re-derives the reference every run.
EXPECT = [(23, 12), (23, 12), (23, 12), (23, 12), (52, 12)]

def parse(leg):
    frames, hp, stock, ids = [], [], [], None
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ff8850.bin"),
                    key=lambda p: int(p.split("_")[-2])):
        fr = int(f.split("_")[-2])
        b = open(f, "rb").read()
        frames.append(fr); hp.append((b[0] << 8) | b[1])
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ff8509.bin"),
                    key=lambda p: int(p.split("_")[-2])):
        stock.append(open(f, "rb").read()[0])
    idf = sorted(glob.glob(f"{W}/{leg}/dump_*_ff8782.bin"))
    if idf: ids = open(idf[0], "rb").read()[0]
    return frames, hp, stock, ids

def verdict(frames, hp, stock, ids, leg):
    errs = []
    if ids != 0x10:
        errs.append(f"{leg}: P1 id {ids!r} != 0x10 — forced pick did not land")
        return errs, []
    live = [h for h in hp if h]
    if not live or max(live) != 288:
        errs.append(f"{leg}: P2 HP never at 288 — dead or mis-based rig")
        return errs, []
    # EX-fired tells: stock decrements (re-pokes step it back up; count
    # only -1 steps)
    fired = [frames[i] for i in range(1, len(stock))
             if stock[i] == stock[i-1] - 1]
    if len(fired) != len(EXPECT):
        errs.append(f"{leg}: {len(fired)} EX firings (stock decrements) at "
                    f"{fired}, expected {len(EXPECT)} — attempts whiffed or "
                    "downgraded; this run proves nothing about damage")
        return errs, []
    ev = [(frames[i], hp[i-1] - hp[i]) for i in range(1, len(hp))
          if hp[i] < hp[i-1]]
    bounds = fired + [10**9]
    got = []
    for i in range(len(fired)):
        e = [x for x in ev if bounds[i] <= x[0] < bounds[i+1]]
        got.append((sum(x[1] for x in e), len(e)))
    for i, (want, have) in enumerate(zip(EXPECT, got)):
        if want != have:
            errs.append(f"{leg}: attempt {i+1} (dmg, ticks) = {have}, "
                        f"frozen native staircase says {want}")
    return errs, got

all_errs = []
for leg in ("native", "ours"):
    frames, hp, stock, ids = parse(leg)
    errs, got = verdict(frames, hp, stock, ids, leg)
    all_errs += errs
    if not errs:
        print(f"  ok: {leg} — 5 EX firings, staircase {got}")

# Verdict-logic controls (each MUST fail): the checker on (a) a leg with
# one tick's damage removed, (b) a leg whose stocks never decrement.
frames, hp, stock, ids = parse("native")
if frames:
    hp_m = list(hp)
    for i in range(1, len(hp_m)):
        if hp_m[i] < hp_m[i-1]:            # refund the first tick
            delta = hp_m[i-1] - hp_m[i]
            hp_m[i:] = [h + delta for h in hp_m[i:]]
            break
    e1, _ = verdict(frames, hp_m, stock, ids, "ctl-a")
    e2, _ = verdict(frames, hp, [3] * len(stock), ids, "ctl-b")
    if not e1:
        all_errs.append("control (a) PASSED with a tick removed — verdict "
                        "logic is not checking damage")
    if not e2:
        all_errs.append("control (b) PASSED with no stock decrements — "
                        "verdict logic is not checking EX liveness")
    if e1 and e2:
        print("  ok: verdict controls — both mutations fail as designed")
else:
    all_errs.append("controls could not run (no native data)")

for e in all_errs:
    print("FAIL:", e)
sys.exit(1 if all_errs else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: FG parity audit"; exit 1; }
echo "PASS: Final Guardian damage is NATIVE-PARITY on this build —"
echo "      both legs match the frozen staircase 23/23/23/23/52 with the"
echo "      per-attempt EX-liveness tells (14z-85f fix: the x028122"
echo "      object-hit damage work-var reconciliation)"
