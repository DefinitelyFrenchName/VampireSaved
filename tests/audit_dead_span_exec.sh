#!/bin/sh
# audit_dead_span_exec.sh — THE RUNTIME BOUND beside tests/test_dead_span.sh: does LEGACY content ever EXECUTE the six
# bytes #294's port is placed on? (14z-216, GitHub #294; promoted from build/agent216/rc294/dead/exec_bound.sh.)
#
# WHAT: on PRISTINE vsavj (MAME), over every replay with a frozen vanilla masked-basis log, how often the CPU executes
#   the span's two instruction heads PRG:0x024024 (moveq) and PRG:0x024026 (bra.w), beside the neighbouring handlers of
#   the victim reaction dispatch (PRG:0x024002 / 0x024020, row 0x20's head and tail; PRG:0x02402A, row 0x21's head) and
#   the per-frame palette dispatcher PRG:0x02ADDC (every fighter, every match frame).
# HOW: tests/lua/pc_count.lua (breakpoints, the emulated-frame clock), one run per replay, FRAMES = the replay's last
#   input frame + 120; every run must end with PCEND equal to EMUFRAMES (it covered its replay in emulated frames).
# EXPECTS: 0 executions at 0x024024 and 0x024026 in every replay. A BOUND, NEVER A PROOF — the static proof is
#   tests/test_dead_span.sh. Measured 14z-216: 64/64 replays complete, 0 at the span, 0 at the three neighbouring
#   handlers too (the corpus never lands reaction classes 0x20/0x21), 597,329 at 0x02ADDC in 62 replays: the bound says
#   nothing about the span's own neighbourhood, and that is stated, not hidden. Read taps cannot add a READ bound:
#   MAME read taps are blind to ROM fetches (RH-15).
# MUST-FIRE: known-bad: live-site — the per-frame dispatcher PRG:0x02ADDC, executed by every fighter on every match frame, must register executions in the same runs; zero there means the instrument saw nothing (in-gate; as a mode the span list is replaced by an address no code reaches, the image's last word, and the gate FAILs)
# FOLLOWS: tests/lua/pc_count.lua tests/replays/ tests/expected/vsavj/masked-v2/ tools/run_mame.sh tools/setup_mame.sh
#   emu/mame-patches/ tests/lib/controls.sh
#
# SHEET: none — measures pristine vsavj only; no leg of our build
#
# Usage: ROMDIR=... [JOBS=6] tests/audit_dead_span_exec.sh      on-demand (64 MAME debug runs, ~25 min on the MacBook)
# SHARES: none — one control mode, so no two of its own jobs to keep apart, and its plain run always pooled (#370 A1, 14z-225)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"; if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
LIVE=02addc; SPAN="024024,024026,029cba,02a586,02a58a"
vs_ctl_is live-site && LIVE=3ffffe
# 14z-221c (#363): the candidates for the row-0x4F jump (029cba, 02a586/02a58a) beside #294's span; informational
# neighbours: 029cc0 (the bra after 029cba), the victim reaction dispatcher 02383c and its default row 0238fc, and
# vsavj's own freeze reaction 023d82 (row 0x14, the handler #363's port is modelled on)
# 14z-221c: 023f68, the `move.b $23f84(pc,d0.w),d0` whose byte table (indexed by the victim's +0x56, unmasked)
# tools/audit_dead_span.py rule D finds within 0x100 of #294's span — the read executing 0 times bounds that reference
SITES="$SPAN,024002,024020,02402a,029cc0,02383c,0238fc,023d82,023f68,$LIVE"
# #369: under the mode the REAL live site stays breakpointed too, so the unreached address's zero is read beside a site
# shown live in the same runs (a blind instrument reads NOT JUDGED, not the mode's finding)
vs_ctl_is live-site && SITES="$SITES,02addc"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
JOBS=${JOBS:-6}; pool=0
for lg in tests/expected/vsavj/masked-v2/logs/*.log; do
  n=$(basename "$lg" .log); rpl="tests/replays/$n.rpl"; [ -f "$rpl" ] || continue
  lf=$(sed 's/#.*//' "$rpl" | awk 'NF { split($1, r, "-"); f=(r[2]?r[2]:r[1]); if (f + 0 > m) m = f + 0 } END { print m + 0 }')
  ( MAME_SANDBOX="$W/sb_$n" REPLAY="$PWD/$rpl" SITES="$SITES" OUT="$W/$n.txt" FRAMES=$((lf + 120)) MAME_ROMPATH="$ROMDIR" \
    timeout 3600 tools/run_mame.sh vsavj -debug -debugger none -autoboot_script "$PWD/tests/lua/pc_count.lua" >"$W/$n.log" 2>&1; rm -rf "$W/sb_$n" ) &
  pool=$((pool + 1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done
wait
W="$W" SPAN="$SPAN" LIVE="$LIVE" MODE="${VS_CTL:-}" python3 - > "$W/main.log" <<'PY' && rc=0 || rc=$?
import glob, os, sys
W, span, live, mode = os.environ["W"], os.environ["SPAN"].split(","), os.environ["LIVE"], os.environ["MODE"]
tot, rep, bad, n = {}, {}, [], 0
for f in sorted(glob.glob(f"{W}/*.txt")):
    n += 1; L = open(f).read().splitlines(); name = os.path.basename(f)[:-4]
    em = [l.split()[1] for l in L if l.startswith("EMUFRAMES")]; pe = [l.split()[1] for l in L if l.startswith("PCEND")]
    if not pe or not em or em[0] != pe[0]:
        bad.append(f"{name} (EMUFRAMES {em[:1]} PCEND {pe[:1]})"); continue
    for l in L:
        if l.startswith("SITE"):
            w = l.split(); tot[w[1]] = tot.get(w[1], 0) + int(w[3]); rep[w[1]] = rep.get(w[1], 0) + (int(w[3]) > 0)
print(f"runs {n}; incomplete {len(bad)}")
for b in bad: print(f"  INCOMPLETE {b}")
for s in sorted(tot): print(f"  site {s}: {tot[s]} executions in {rep[s]} replays")
fail = 0
if n == 0 or bad: fail = 1
for s in span:
    if tot.get(s, 0): print(f"  FAIL  the span head PRG:0x{s.upper()} executed {tot[s]} times"); fail = 1
if tot.get(live, 0) > 0: print(f"CONTROL FIRED: live-site — PRG:0x{live.upper()} executed {tot[live]} times in {rep[live]} replays: the instrument sees execution")
elif mode:   # #369: under the mode the unreached address is the main check's finding, not this control's verdict
    print(f"  FAIL  the live site PRG:0x{live.upper()} registered no execution in {n} runs"); fail = 1
    if not tot.get("02addc", 0): print(f"  BLIND  the real live site PRG:0x02ADDC also registered no execution in {n} runs"); fail = 1
else: print(f"CONTROL DEAD: live-site — PRG:0x{live.upper()} registered no execution: the bound is blind"); fail = 1
print("PASS" if not fail else "FAIL"); sys.exit(fail)
PY
cat "$W/main.log"
if [ "$rc" != 0 ]; then
    if [ -n "${VS_CTL:-}" ]; then   # #369: honoured only on the mode's own finding, and only when every run completed
        if grep -qE '^runs 0;|^  INCOMPLETE ' "$W/main.log"; then
            vs_ctl_nj "no run, or a run that did not complete: the live site's count measures nothing"
        elif grep -q '^  BLIND  ' "$W/main.log"; then
            vs_ctl_nj "the real live site PRG:0x02ADDC registered no execution either: the instrument is blind, so the unreached address's zero measures nothing"
        else vs_ctl_caught "$W/main.log" '^  FAIL  the live site PRG:0x3FFFFE registered no execution in [1-9][0-9]* runs$' || :; fi
    fi
    exit 1
fi
