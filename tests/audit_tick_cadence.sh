#!/bin/sh
# audit_tick_cadence.sh — on VANILLA content the two engines double their logic pass at different cadences: vsav2 every third frame, vsavj every fourth or fifth, both fighters on the same frames, both passes inside ONE activation of the game task; vsav2's tick site is vsavj's minus 0xDAC and is the live writer (GitHub #135, measured 14z-156).
#
# MUST-FIRE: perturbed-copy: twin-pc — vsav2's taps read with vsavj's tick and node-entry PCs must fail the live-twin assertion (no writes land there), so every count below is proven to rest on the PC map
#
# WHAT IT MEASURES (#135 steps 1-2 of the maintainer-agreed plan, 2026-09-14). The
# vanilla Victor mirror of tests/test_don_immortal_native.sh section 4 (forced id
# 0x03 on both sides, identical inputs, HP on P1 at 2620) is played on vsav2 and on
# vsavj under tests/lua/tap_writes.lua — a memory WRITE TAP with no debugger, so
# replay frames stay exact and every write is seen, not one sample per frame — with
# four taps per game, one per run (MAME without the debugger is deterministic and a
# tap perturbs nothing, so the runs share one timeline at FRAME granularity; never
# compare the order of writes inside a frame across runs):
#   P1 +0x1C..+0x23 and P2 +0x1C..+0x23 — the anim pointer, the node timer, its tick;
#   P2 +0x5C..+0x5D — the hit-freeze counter and its drain;
#   the task table $FF025C..$FF045B — 16 slots x 0x20, the scheduler's state writes.
#
# WHAT IT FROZE, measured 14z-156 on the reference MAME binary, frames 2300..2900:
#   * THE TICK SITE'S TWIN: vsav2 writes +0x20 at PRG:0x0271C4 (subq.b #1,$20(a6)) and
#     enters nodes at 0x02713C/0x027140 — vsavj's 0x027F70/0x027EE8/0x027EEC minus
#     0xDAC, found statically (docs/game/engine_internals.md, the 14z-156 addendum)
#     and asserted here as the DOMINANT writer on both fighters.
#   * TICKS: vsav2 P1 501, P2 651; vsavj P1 465, P2 615 — vsav2 +36 on both fighters,
#     all of it as extra double-tick frames (zero-tick frames equal).
#   * DOUBLE-TICK FRAMES (two tick writes in one frame): vsav2 P1 114, P2 116, 112 on
#     the same frame; vsavj P1 79, P2 81, 78 on the same frame. Gaps between P2's:
#     vsav2 {3: 113, 6: 2} (the pattern 211), vsavj {4: 53, 5: 26, 9: 1}.
#   * THE HIT-FREEZE: P2's +0x5C = 11 drains, vsav2 at PRG:0x0231D0 over frames
#     2629..2637, vsavj at PRG:0x0245AE over 2630..2638 — nine frames on BOTH games on
#     this instrument (the "9 vs 10" of test_don_immortal_native section 4 counts
#     frames with +0x5C > 0 in per-frame dumps from the hit, a different measure).
#   * ONE ACTIVATION: the two game-task slots (3 and 4) are dispatched (the state-8
#     write at PRG:0x001204/0x001218) at most ONCE per frame on both games, frame
#     distribution slot 3 {0: 20, 1: 580}, slot 4 {0: 22, 1: 578}, double-tick frames
#     included — so both passes of a double-tick frame run inside one activation.
# WHAT DECIDES THE SECOND PASS IS NOT LOCATED (#135 stays open): no constant-step
# accumulator was found in work RAM, but that search was never shown to find a
# planted one, so it is not a result and nothing here asserts it.
#
# Usage: ROMDIR=... [MAME_BIN=<reference binary, default ~/.cache/vampire-saved/mame-ref/cps2>] tests/audit_tick_cadence.sh
# Runtime: ~7 min (eight MAME legs of 2,900 frames), emulator tier.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# ABSOLUTE, as in every emulator gate since 14z-132 (a relative ROMDIR resolves
# against a work dir and silently finds no reference members).
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
[ -x "$BIN" ] || { echo "FAIL: no reference MAME binary at $BIN (tools/setup_mame.sh with WIDE=0)"; exit 1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"

VPOKE="1400:ff8782:03;1450:ff8782:03;1500:ff8782:03;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
grep -v '^#' "$REPO/tests/replays/48_don_immortal_ko.rpl" \
  | sed 's/^2620-2624 p1=.*/2620-2624 p1=3/' | grep -v '^261[048]' > "$W/van.rpl"
grep -q '^2620-2624 p1=3$' "$W/van.rpl" || { echo "FAIL: the mirror replay was not derived (the activation line is missing)"; exit 1; }

for g in vsav2 vsavj; do
    for t in "p1:ff841c,8" "p2:ff881c,8" "frz:ff885c,2" "tasks:ff025c,512"; do
        n=${t%%:*}; tap=${t#*:}
        MAME_BIN="$BIN" MAME_SANDBOX="$W/sb_${g}_$n" MAME_ROMPATH="$ROMDIR" \
            REPLAY="$W/van.rpl" POKES="$VPOKE" TAP="$tap" WINDOW=2300,2900 FRAMES=2900 \
            TRACE_OUT="$W/${g}_$n.tap" \
            tools/run_mame.sh "$g" -autoboot_script "$REPO/tests/lua/tap_writes.lua" \
            > "$W/${g}_$n.out" 2>&1 || true
        grep -q '^END 2900 ' "$W/${g}_$n.tap" 2>/dev/null \
            || { echo "FAIL: leg $g/$n did not reach frame 2900 (see its MAME output)"; tail -3 "$W/${g}_$n.out"; exit 1; }
    done
done

python3 - "$W" "$MODE" <<'PY'
import sys
from collections import Counter
work, MODE = sys.argv[1], sys.argv[2]
LIVE = {"vsav2": {"tick": "0271c4", "ptr": "02713c", "dur": "027140"},
        "vsavj": {"tick": "027f70", "ptr": "027ee8", "dur": "027eec"}}
DELTA = 0xDAC
FROZEN = {
    "vsav2": dict(t1=501, t2=651, d1=114, d2=116, same=112, gaps={3: 113, 6: 2},
                  frz_pc="0231d0", frz=(11, 2629, 2637)),
    "vsavj": dict(t1=465, t2=615, d1=79, d2=81, same=78, gaps={4: 53, 5: 26, 9: 1},
                  frz_pc="0245ae", frz=(11, 2630, 2638)),
}
SLOTS = {3: {0: 20, 1: 580}, 4: {0: 22, 1: 578}}

def load(g, n):
    out = []
    for l in open(f"{work}/{g}_{n}.tap"):
        if l.startswith("frame"):
            s = l.split()
            out.append((int(s[1]), s[3], int(s[5], 16), int(s[9], 16)))
    return out

TAPS = {g: {n: load(g, n) for n in ("p1", "p2", "frz", "tasks")} for g in LIVE}

def perturb(pcmap):
    """the twin-pc perturbation: read vsav2's taps with vsavj's PCs"""
    m = {g: dict(v) for g, v in pcmap.items()}
    m["vsav2"] = dict(pcmap["vsavj"])
    return m

def analyse(pcmap, quiet=False):
    fails = []
    def need(cond, msg):
        if not quiet: print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond: fails.append(msg)
    need(int(LIVE["vsavj"]["tick"], 16) - DELTA == int(LIVE["vsav2"]["tick"], 16)
         and int(LIVE["vsavj"]["ptr"], 16) - DELTA == int(LIVE["vsav2"]["ptr"], 16),
         "the frozen vsav2 twin PCs are vsavj's minus 0xDAC")
    for g, f in FROZEN.items():
        pc = pcmap[g]
        for who, base in (("p1", 0xFF8420), ("p2", 0xFF8820)):
            ev = TAPS[g][who]
            need(len(ev) > 0, f"{g} {who}: the tap saw writes (an empty tap is a dead instrument)")
            byte_writers = Counter(p for fr, p, off, m in ev if off == base and m == 0xFF00)
            dom = byte_writers.most_common(1)[0][0] if byte_writers else None
            need(dom == pc["tick"], f"{g} {who}: the dominant byte writer of +0x20 is {pc['tick']} (measured {dom})")
            need(any(p == pc["ptr"] for fr, p, off, m in ev) and any(p == pc["dur"] for fr, p, off, m in ev),
                 f"{g} {who}: node entry writes land at {pc['ptr']}/{pc['dur']}")
        t = {who: Counter(fr for fr, p, off, m in TAPS[g][who] if p == pc["tick"] and off == base)
             for who, base in (("p1", 0xFF8420), ("p2", 0xFF8820))}
        W = range(2300, 2901)
        tot1, tot2 = sum(t["p1"][x] for x in W), sum(t["p2"][x] for x in W)
        d1 = {x for x in W if t["p1"][x] >= 2}; d2 = {x for x in W if t["p2"][x] >= 2}
        ds = sorted(d2); gaps = dict(sorted(Counter(b - a for a, b in zip(ds, ds[1:])).items()))
        need((tot1, tot2) == (f["t1"], f["t2"]), f"{g}: ticks P1 {tot1}, P2 {tot2} (frozen {f['t1']}, {f['t2']})")
        need((len(d1), len(d2), len(d1 & d2)) == (f["d1"], f["d2"], f["same"]),
             f"{g}: double-tick frames P1 {len(d1)}, P2 {len(d2)}, same frame {len(d1 & d2)} (frozen {f['d1']}, {f['d2']}, {f['same']})")
        need(gaps == f["gaps"], f"{g}: gaps between P2's double-tick frames {gaps} (frozen {f['gaps']})")
        dr = [fr for fr, p, off, m in TAPS[g]["frz"] if p == f["frz_pc"] and m == 0xFF00]
        got = (len(dr), min(dr) if dr else None, max(dr) if dr else None)
        need(got == f["frz"], f"{g}: P2 hit-freeze drains at {f['frz_pc']} = {got[0]} over {got[1]}..{got[2]} (frozen {f['frz']})")
        disp = {s: Counter() for s in SLOTS}
        for fr, p, off, m in TAPS[g]["tasks"]:
            s = (off - 0xFF025C) // 0x20
            if p in ("001204", "001218") and s in disp and (off - 0xFF025C) % 0x20 == 0:
                disp[s][fr] += 1
        for s, frozen in SLOTS.items():
            dist = dict(sorted(Counter(disp[s][x] for x in range(2300, 2900)).items()))
            need(dist == frozen, f"{g}: game-task slot {s} dispatches per frame {dist} (frozen {frozen})")
        both = [x for x in d2 if all(disp[s][x] <= 1 for s in SLOTS)]
        need(len(both) == len(d2) and len(d2) > 0,
             f"{g}: on all {len(d2)} double-tick frames each game-task slot ran at most once — both passes in one activation")
        if not quiet:
            print(f"       {g}: passes per frame over 2300..2900 = {tot2 / len(W):.3f} (P2), {len(d2)} doubles")
    need(FROZEN["vsav2"]["d2"] > FROZEN["vsavj"]["d2"], "vsav2 doubles more often than vsavj (the cross-game difference itself)")
    return fails

pcmap = perturb(LIVE) if MODE == "twin-pc" else LIVE
fails = analyse(pcmap)
if MODE == "":
    ctl = analyse(perturb(LIVE), quiet=True)
    if any("dominant byte writer" in x for x in ctl):
        print(f"CONTROL FIRED: twin-pc — with vsavj's PCs, {len(ctl)} assertion(s) fail on vsav2, the live-twin one included")
    else:
        print("CONTROL DEAD: twin-pc — vsav2's taps read with vsavj's PCs did not fail the live-twin assertion")
        sys.exit(1)
if fails:
    print(f"FAIL: audit_tick_cadence — {len(fails)} assertion(s) failed")
    sys.exit(1)
print("PASS: audit_tick_cadence — vsav2 doubles every third frame, vsavj every fourth or fifth, globally and inside one activation; the tick twin is live")
PY
