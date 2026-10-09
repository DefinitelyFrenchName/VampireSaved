#!/bin/sh
# audit_marionette_cost.sh — WHAT A MARIONETTE PORT WOULD COST vsavj: every place vs2 touches her flag +0x3C3, the vsavj
# instruction a port would have to hook there, how often LEGACY content executes each one, and her assets' size
# (14z-189, GitHub #128 — the maintainer: "Authorise a cost measurement"; no build)
#
# WHAT: (1) STATIC — tools/audit_marionette_cost.py classifies each of vs2's 28 +0x3C3 sites by the three-sibling
#   method (masked unique anchors before and after the site, then an instruction diff of the two spans): INSERT (vs2
#   code vsavj lacks, a pure insertion), REPLACE (vs2 code that replaces vsavj code), NEW (vs2 code in a sub-state
#   vsavj's twin routine does not have) — each with the vsavj HOOK POINT, the first vsavj instruction after the
#   difference. (2) ASSETS — her records as the +0x3C3 code selects them (the select record, the VS/sprite record, the
#   palette block), walked to their tile codes. (3) DYNAMIC — on PRISTINE vsavj, tests/lua/pc_count.lua counts every
#   execution of every hook point, PER EMULATED FRAME, over every replay with a frozen vanilla masked-basis log (the
#   legacy corpus, to its basis length) plus 128_shadow_vs_legacy_vsavj (Shadow on vanilla, to frame 9000) — Shadow is
#   legacy content, and most +0x3C3 sites sit beside a +0x3BC (Shadow) test.
# HOW: the static and asset censuses on decrypted views (tests/lib/decrypt_cache.sh); MAME -debug breakpoints, one per
#   hook point plus two WITNESSES (vsavj PRG:0x020AB4 `st.b $3bc(a6)` — Shadow's setter — and PRG:0x009BB2, the
#   round-end morph test), JOBS legs in parallel. The cycle figure is a MODEL, stated: the cheapest hook that keeps
#   vanilla's own instructions is `jsr abs.l` to a thunk that tests the flag, branches and returns — JSR abs.L 20 +
#   TST.B d16(An) 12 + Bcc.B 10 (taken; 8 not) + RTS 16 = 58 cycles per execution (MC68000 user manual execution
#   times); the displaced vanilla instructions run in the thunk at their own cost. The frame budget is MAME's model
#   of the board: maincpu clock 16,000,000 / refresh 59.637405 = 268,288 cycles (`-listxml vsavj`).
# EXPECTS: the static table, the asset lines and every per-site count (hits, replays, frames, max-per-frame), the worst
#   frame's combined hook executions and its modelled cycles, all equal to tests/expected/marionette_cost.tsv; every
#   leg complete; the Shadow setter executed exactly once on the witness replay (the replay really armed Shadow under
#   the instrument); each control FAILs. THE INSTRUMENT'S ALIGNMENT (14z-196, GitHub #228 — #213's method, as
#   tests/audit_dispatch_census.sh): every breakpoint leg covered its counted frames in EMULATED frames (EMUFRAMES ==
#   PCEND); a REFERENCE leg per replay (the same script, SITES=none: no breakpoint, no debugger) reproduces the frozen
#   vanilla basis checksum (masked-v2, its MASK) at the basis log's last frame, so the script's frame index and input
#   staging are replay.lua's; and each breakpoint leg's game frame counter RAM:$FF8080 equals its reference leg's at
#   that frame. The witness replay has no frozen basis log, so the gate runs replay.lua ITSELF on it (tools/
#   run_replay_mame.sh, the same mask) and holds the witness reference leg to that live log at its last frame — the
#   worst frame comes from that leg (rule-checker run 2026-10-08-766 Q1). How many breakpoint legs also equal the
#   basis byte for byte is PRINTED, not asserted: a stop can move the game ([MFI-2]).
# FOLLOWS: emu/mame-patches/ tests/expected/marionette_cost.tsv tests/expected/vsavj/masked-v2/
#   tests/lib/controls.sh tests/lib/decrypt_cache.sh tests/lua/pc_count.lua tests/lua/replay.lua tests/replays/
#   tools/audit_marionette_cost.py tools/run_replay_mame.sh
#   tools/find_equiv.py tools/gfx_tiles.py tools/run_mame.sh tools/scan_code_refs.py tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: site-removed — a copy of vs2's opcode view with the +0x3C3 store at PRG:0x007122 re-encoded as +0x3C4 must change the static census (28 -> 27 sites), so the hook list is read from the image, not echoed (in-gate; as a mode the gate FAILs)
# MUST-FIRE: known-bad: drift-clock — the witness replay re-run with every site armed under pc_count.lua's OLD frame_done clock (PC_CLOCK=frame_done, the [MFI-5] desync) must miss Shadow's arming (PRG:0x020AB4 never executes), cover fewer emulated frames than it counted, and read a game frame counter at its last frame unlike its reference leg's, so the witness, the coverage check and the game-clock anchor each see a replay whose input drifted under the instrument (in-gate on 1800 frames; as a mode every leg runs the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — a reference leg of 03_two_player_vs under pc_count.lua's first-frame skip (PC_CLOCK=skip_first, the defect #228 fixed) must miss the frozen basis checksum at its anchor, so the anchor sees an instrument one frame behind replay.lua (in-gate; as a mode every reference leg runs the skip and the gate FAILs)
#
# NOT COVERED: vs2 code that is hers but never names +0x3C3 (a NEW routine is counted once, by its twin); cycles on
#   paths the corpus never runs (a hook point with 0 hits is "not observed in this corpus", a bound, not deadness —
#   [VSP-22]); the oracle-class cost (whether a hook on a hot legacy path moves a frozen `.masked` class is only
#   measurable by building the hooks); her character data beyond the three records (she copies the opponent's moves);
#   FBNeo; vh2's 3 extra sites (vh2 31 vs vs2 28, tests/test_copy_flags.sh) — vs2 is the measured source.
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=4] [KEEP=<dir>] [FREEZE=1] tests/audit_marionette_cost.sh
#   emulator tier, MAME; ~8 min at JOBS=4 (static census ~40 s twice, 57 legs and their 57 reference legs, the
#   control legs)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
JOBS="${JOBS:-4}"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
. "$REPO/tests/lib/decrypt_cache.sh"
EXPECT="$REPO/tests/expected/marionette_cost.tsv"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "  host  $(uname -sm); MAME_BIN $MAME_BIN; JOBS $JOBS"
fail=0
T=tools/audit_marionette_cost.py
WITNESS_SET=20ab4
WITNESS_MORPH=9bb2
WREPLAY=128_shadow_vs_legacy_vsavj
WFRAMES=9000

echo "== 1. the static census (vs2 -> vsavj hook points)"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_data.bin"
decrypt_view vsavj "$W/vj_op.bin"
python3 - "$W/v2_op.bin" "$W/v2_op_bad.bin" <<'PY'
import sys
d = bytearray(open(sys.argv[1], "rb").read())
assert d[0x7122:0x7126] == bytes.fromhex("1d4003c3"), d[0x7122:0x7126].hex()
d[0x7122:0x7126] = bytes.fromhex("1d4003c4")
open(sys.argv[2], "wb").write(bytes(d))
PY
V2="$W/v2_op.bin"
vs_ctl_is site-removed && V2="$W/v2_op_bad.bin"
python3 "$T" "$V2" "$W/vj_op.bin" | grep -v '^#' > "$W/static.txt" || { echo "  FAIL: the static census errored"; exit 1; }
sed 's/^/    /' "$W/static.txt"
python3 "$T" --assets "$W/v2_data.bin" | grep -v '^#' > "$W/assets.txt" || { echo "  FAIL: the asset census errored"; exit 1; }
sed 's/^/    /' "$W/assets.txt"
HOOKS="$(sed -n 's/^HOOKLIST //p' "$W/static.txt")"
[ -n "$HOOKS" ] || { echo "  FAIL: no HOOKLIST"; exit 1; }

echo "== 2. the legacy corpus on pristine vsavj: every hook point's executions per emulated frame"
CLOCK=""
vs_ctl_is drift-clock && CLOCK=frame_done
REFCLOCK=""
vs_ctl_is first-frame-skip && REFCLOCK=skip_first
SITES="$WITNESS_SET,$WITNESS_MORPH,$HOOKS"
BASIS=tests/expected/vsavj/masked-v2
MASK="$(cat "$BASIS/MASK")"   # the basis's own record (#213's anchor, tests/audit_dispatch_census.sh)
run_leg() { # name rpl frames out clock anchor — the breakpoint leg
    MAME_SANDBOX="$W/sb_$1" REPLAY="$REPO/$2" SITES="$SITES" OUT="$4" FRAMES="$3" PC_CLOCK="$5" \
        ANCHOR="$6" MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" tools/run_mame.sh vsavj -debug -debugger none \
        -autoboot_script "$REPO/tests/lua/pc_count.lua" > "$4.log" 2>&1 || true
}
ref_leg() { # name rpl frames out clock anchor — the REFERENCE leg: no breakpoint, no debugger (#228)
    MAME_SANDBOX="$W/sbr_$1" REPLAY="$REPO/$2" SITES=none OUT="$4" FRAMES="$3" PC_CLOCK="$5" \
        ANCHOR="$6" MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" tools/run_mame.sh vsavj \
        -autoboot_script "$REPO/tests/lua/pc_count.lua" > "$4.log" 2>&1 || true
}
: > "$W/legs.txt"
for lf in "$BASIS"/logs/*.log; do
    n="$(basename "$lf" .log)"
    [ -f "tests/replays/$n.rpl" ] || continue
    fr="$(tail -1 "$lf" | awk '{print $2}')"
    an="$(awk '$1 ~ /^[0-9]+$/ {l=$1} END {print l+0}' "$lf")"   # the basis log's last frame
    [ "$an" -gt "$fr" ] && an="$fr"
    printf '%s %s %s %s\n' "$n" "tests/replays/$n.rpl" "$fr" "$an" >> "$W/legs.txt"
done
printf '%s %s %s %s\n' "$WREPLAY" "tests/replays/$WREPLAY.rpl" "$WFRAMES" "$WFRAMES" >> "$W/legs.txt"
echo "  legs: $(wc -l < "$W/legs.txt" | tr -d ' ') (the corpus with a vanilla basis log, plus $WREPLAY), each with a reference leg"
# the witness replay's live basis: replay.lua itself, the same mask (run 2026-10-08-766 Q1)
( MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" tools/run_replay_mame.sh vsavj "tests/replays/$WREPLAY.rpl" \
    "$W/rl_$WREPLAY.log" "$W/sbrl_$WREPLAY" > "$W/rl_$WREPLAY.run" 2>&1 || true ) &
pool=1
while read -r n rpl fr an; do
    run_leg "$n" "$rpl" "$fr" "$W/pc_$n.txt" "$CLOCK" "$an" &
    ref_leg "$n" "$rpl" "$fr" "$W/ref_$n.txt" "$REFCLOCK" "$an" &
    pool=$((pool + 2)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done < "$W/legs.txt"
wait

echo "== 3. the in-gate controls: the witness leg under the OLD clock (1800 frames); a reference leg under the first-frame skip"
run_leg "ctl" "tests/replays/$WREPLAY.rpl" 1800 "$W/ctl_drift.txt" frame_done 1800 &
ref_leg "ctl" "tests/replays/$WREPLAY.rpl" 1800 "$W/ctl_ref.txt" "" 1800 &
wait
ctl_set="$(awk -v a="$(printf '%06x' 0x$WITNESS_SET)" '$1=="SITE" && $2==a {print $4}' "$W/ctl_drift.txt")"
ce="$(awk '$1=="EMUFRAMES" {print $2}' "$W/ctl_drift.txt")"
cg="$(awk '$1=="GAMECLOCK" {print $3}' "$W/ctl_drift.txt")"
rg="$(awk '$1=="GAMECLOCK" {print $3}' "$W/ctl_ref.txt")"
if ! grep -q '^PCEND 1800' "$W/ctl_drift.txt" || [ -z "$ce" ] || [ -z "$cg" ] || [ -z "$rg" ]; then
    vs_ctl_dead drift-clock "the control legs did not complete" || fail=1
elif [ "$ctl_set" = 0 ] && [ "$ce" -lt 1800 ] && [ "$cg" != "$rg" ]; then
    vs_ctl_fired drift-clock "under the frame_done clock (debugger-stop UI frames counted as frames) the Shadow setter PRG:0x020AB4 executed 0 times in 1800 counted frames, which covered $ce emulated frames, and the game frame counter at frame 1800 reads $cg where the reference leg's reads $rg"
else
    vs_ctl_dead drift-clock "under the drifting clock: setter $ctl_set, $ce emulated of 1800 counted, game clock $cg vs reference $rg — a check cannot see the desync" || fail=1
fi
SKN=03_two_player_vs
SKA="$(awk -v n="$SKN" '$1==n {print $4}' "$W/legs.txt")"
SKF="$(awk -v n="$SKN" '$1==n {print $3}' "$W/legs.txt")"
if vs_ctl_is first-frame-skip; then
    vs_ctl_fired first-frame-skip "every reference leg is running the first-frame skip (mode)"
else
    ref_leg "skip" "tests/replays/$SKN.rpl" "$SKF" "$W/ctl_skip.txt" skip_first "$SKA"
    sk="$(awk '$1=="ANCHOR" {print $3}' "$W/ctl_skip.txt")"
    bs="$(awk -v a="$SKA" '$1==a {print $2}' "$BASIS/logs/$SKN.log")"
    if [ -z "$sk" ] || [ -z "$bs" ]; then
        vs_ctl_dead first-frame-skip "the skip leg or the basis gave no checksum at frame $SKA" || fail=1
    elif [ "$sk" != "$bs" ]; then
        vs_ctl_fired first-frame-skip "under the first-frame skip the reference leg of $SKN reads $sk at frame $SKA where the frozen basis reads $bs"
    else
        vs_ctl_dead first-frame-skip "the skipped reference leg still matched the basis at frame $SKA — the anchor cannot see a one-frame lag" || fail=1
    fi
fi

echo "== 4. the in-gate control: the static census on a planted vs2 copy"
if vs_ctl_is site-removed; then
    vs_ctl_fired site-removed "the gate is running on the planted copy (mode)"
else
    python3 "$T" "$W/v2_op_bad.bin" "$W/vj_op.bin" | grep -v '^#' > "$W/static_bad.txt" || true
    if cmp -s "$W/static.txt" "$W/static_bad.txt"; then
        vs_ctl_dead site-removed "the census did not move with the planted site" || fail=1
    else
        vs_ctl_fired site-removed "$(grep -c '^SITE' "$W/static_bad.txt") sites on the planted copy against $(grep -c '^SITE' "$W/static.txt")"
    fi
fi

echo "== 5a. the instrument's alignment (#228, #213's method)"
W="$W" BASIS="$BASIS" python3 - > "$W/align.txt" <<'PY' || fail=1
import os, re
W, BASIS = os.environ["W"], os.environ["BASIS"]
short, unanchored, clockoff, moved, anchored, exact, n = [], [], [], [], 0, 0, 0
for ln in open(f"{W}/legs.txt"):
    name, _, fr, an = ln.split()
    txt = open(f"{W}/pc_{name}.txt").read() if os.path.exists(f"{W}/pc_{name}.txt") else ""
    rtxt = open(f"{W}/ref_{name}.txt").read() if os.path.exists(f"{W}/ref_{name}.txt") else ""
    n += 1
    me, mc = re.search(r"^EMUFRAMES (\d+)$", txt, re.M), re.search(r"^PCEND (\d+)$", txt, re.M)
    if not me or not mc or me.group(1) != mc.group(1):
        short.append(f"{name} ({me.group(1) if me else 'no EMUFRAMES'} of {mc.group(1) if mc else 'no PCEND'})")
    basis = {}
    lp = os.path.join(BASIS, "logs", name + ".log")
    if not os.path.exists(lp):
        lp = f"{W}/rl_{name}.log"      # the witness: replay.lua's live log (run 2026-10-08-766 Q1)
        if not os.path.exists(lp):
            unanchored.append(f"{name} (no frozen basis and no live replay.lua log)")
    if os.path.exists(lp):
        for l in open(lp):
            p = l.split()
            if len(p) == 2 and p[0].isdigit():
                basis[int(p[0])] = p[1]
    ra = re.search(r"^ANCHOR (\d+) ([0-9a-f]{16})$", rtxt, re.M)
    ca = re.search(r"^ANCHOR (\d+) ([0-9a-f]{16})$", txt, re.M)
    rg = re.search(r"^GAMECLOCK \d+ ([0-9a-f]{2})$", rtxt, re.M)
    cg = re.search(r"^GAMECLOCK \d+ ([0-9a-f]{2})$", txt, re.M)
    if basis:
        if not ra:
            unanchored.append(f"{name} (reference leg: no ANCHOR line)")
        elif basis.get(int(ra.group(1))) != ra.group(2):
            unanchored.append(f"{name} (reference leg, frame {ra.group(1)}: {ra.group(2)} vs basis {basis.get(int(ra.group(1)), 'absent')})")
        else:
            anchored += 1
        if ca and basis.get(int(ca.group(1))) == ca.group(2):
            exact += 1
        else:
            moved.append(name)
    if not cg or not rg or cg.group(1) != rg.group(1):
        clockoff.append(f"{name} (game clock {cg.group(1) if cg else 'none'} vs reference {rg.group(1) if rg else 'none'})")
bad = 0
if short:
    print(f"FAIL {len(short)} breakpoint leg(s) covered fewer emulated frames than they counted: " + ", ".join(short)); bad = 1
else:
    print(f"ok   all {n} breakpoint legs covered exactly their counted frames in emulated time")
if unanchored:
    print(f"FAIL {len(unanchored)} reference leg(s) missed the frozen vanilla basis checksum at their anchor: " + ", ".join(unanchored)); bad = 1
else:
    print(f"ok   {anchored} reference leg(s) reproduced the frozen vanilla basis checksum at the basis log's last frame")
if clockoff:
    print(f"FAIL {len(clockoff)} breakpoint leg(s) whose game frame counter RAM:$FF8080 at the anchor is not their reference leg's: " + ", ".join(clockoff)); bad = 1
else:
    print(f"ok   every breakpoint leg's game frame counter at the anchor equals its reference leg's ({n} legs)")
print(f"info {exact} breakpoint leg(s) also equal the basis byte for byte; {len(moved)} moved under the breakpoint stops: " + (", ".join(moved) if moved else "none"))
raise SystemExit(bad)
PY
sed 's/^/    /' "$W/align.txt"

echo "== 5. aggregate"
W="$W" WITNESS_SET="$WITNESS_SET" WITNESS_MORPH="$WITNESS_MORPH" WREPLAY="$WREPLAY" python3 - > "$W/dyn.txt" <<'PY' || fail=1
import glob, os, re, sys
W = os.environ["W"]
wset, wmorph = int(os.environ["WITNESS_SET"], 16), int(os.environ["WITNESS_MORPH"], 16)
legs = [l.split() for l in open(f"{W}/legs.txt")]
hooks = [int(h, 16) for h in open(f"{W}/static.txt").read().split("HOOKLIST ")[1].split()[0].split(",")]
tot = {h: [0, 0, 0, 0] for h in hooks}        # hits, replays, frames, max
worst, worst_at, bad = 0, "-", []
wit = {}
for n, _, fr, *_ in legs:
    p = f"{W}/pc_{n}.txt"
    txt = open(p).read() if os.path.exists(p) else ""
    if f"PCEND {fr}\n" not in txt:
        bad.append(n)
        continue
    for m in re.finditer(r"^SITE (\w+) hits (\d+) frames (\d+) max (\d+)$", txt, re.M):
        a, h, f, mx = int(m.group(1), 16), int(m.group(2)), int(m.group(3)), int(m.group(4))
        if a in tot:
            t = tot[a]
            t[0] += h; t[1] += h > 0; t[2] += f; t[3] = max(t[3], mx)
        if n == os.environ["WREPLAY"] and a in (wset, wmorph):
            wit[a] = h
    for m in re.finditer(r"^F (\d+) (.*)$", txt, re.M):
        s = sum(int(kv.split(":")[1]) for kv in m.group(2).split() if int(kv.split(":")[0], 16) in tot)
        if s > worst:
            worst, worst_at = s, f"{n}:{m.group(1)}"
for h in hooks:
    t = tot[h]
    print(f"HIT {h:06x} replays {t[1]} hits {t[0]} frames {t[2]} max {t[3]}")
reached = sum(1 for h in hooks if tot[h][1])
print(f"REACHED {reached} of {len(hooks)} hook points executed by the corpus")
print(f"WORST {worst} hook executions in one frame at {worst_at}")
print(f"COST per_exec 58 worst_frame_cycles {worst * 58} frame_budget 268288 ppm {worst * 58 * 1000000 // 268288}")
print(f"WITNESS {os.environ['WREPLAY']} setter {wit.get(wset, 'missing')} morph {wit.get(wmorph, 'missing')}")
if bad:
    print("INCOMPLETE " + " ".join(bad))
PY
sed 's/^/    /' "$W/dyn.txt"
grep -q '^INCOMPLETE' "$W/dyn.txt" && { echo "  FAIL: incomplete legs"; fail=1; }
if grep -q "^WITNESS $WREPLAY setter 1 " "$W/dyn.txt"; then
    echo "  ok    the witness replay armed Shadow under the instrument (setter executed once)"
else
    echo "  FAIL  the witness replay did not arm Shadow exactly once: $(grep '^WITNESS' "$W/dyn.txt")"; fail=1
fi
cat "$W/static.txt" "$W/assets.txt" "$W/dyn.txt" > "$W/got.tsv"

if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] || { echo "FAIL: not freezing a failing run"; exit 1; }
    { echo "# tests/expected/marionette_cost.tsv — frozen by tests/audit_marionette_cost.sh (GitHub #128)."
      echo "# Evidence class: static census of the decrypted views + in-emulator counts on pristine vsavj. Frozen 14z-189 with FREEZE=1; addresses, counts and tile-cell totals only, no ROM bytes."
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1)"; exit 1; }
if grep -v '^#' "$EXPECT" | diff - "$W/got.tsv" > "$W/diff.txt"; then
    echo "  ok    every row as frozen"
else
    echo "  FAIL  differs from the frozen expectation:"; sed 's/^/        /' "$W/diff.txt" | head -20; fail=1
fi
if [ "$fail" = 0 ]; then
    if [ -n "${VS_CTL:-}" ]; then echo "FAIL: audit_marionette_cost (control mode $VS_CTL passed — the control is dead)"; exit 1; fi
    echo "PASS: audit_marionette_cost"
else
    [ -n "${VS_CTL:-}" ] && { echo "FAIL: audit_marionette_cost (control mode)"; exit 1; }
    echo "FAIL: audit_marionette_cost"; exit 1
fi
