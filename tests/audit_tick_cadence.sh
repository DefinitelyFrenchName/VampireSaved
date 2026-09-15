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
#   the task table $FF025C..$FF045B — 16 slots x 0x20, the scheduler's state writes;
# plus one tests/lua/replay.lua run per game dumping ALL work RAM ($FF0000-$FFFFFF)
# every frame 2560..2760, for section B.
#
# SECTION A — WHAT IT FROZE, measured 14z-156 on the reference MAME binary, 2300..2900:
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
#
# SECTION B — WHAT DOES NOT DECIDE THE SECOND PASS (added at the 14z-156 close check:
# these three searches ran as scratch probes first and their negatives were quoted
# before any of them had found a planted case). Over P2's double-tick frames inside
# the dump window, each search must FIRST find a case planted in the real dumps —
# a search that cannot see its own plant is a dead instrument and FAILS the gate:
#   * the frame counter RAM:$FF8080 (the frame interrupt's addq.b #1, checked to step
#     +1 between consecutive dumps — the dumps' alignment control): no modulus 2..64
#     leaves every residue all-double or all-single (a modulus near the window's 201
#     frames is trivially pure and says nothing, so none is tested); planted: a target
#     set defined as counter % 3 == 0 must be found at modulus 3;
#   * any single bit or exact byte value of $FF8000-$FF83FF at frame f-2..f+2 equal to
#     the double-tick set: none; planted: bit 3 of a constant byte set on the double
#     frames must be found at d = 0;
#   * a constant-step accumulator ANYWHERE in the 64 KB (a byte or a big-endian word
#     whose non-zero per-frame step is one constant on >= 60% of frames — it may pause
#     — and whose carry frames match the double set with F1 >= 0.8 at d = -2..2): none;
#     planted: a byte stepping +0x3B with a pause every 17th frame, and a word stepping
#     +0x3B11, each found against its own carry set.
# WHAT DECIDES THE SECOND PASS IS STILL NOT LOCATED (#135 stays open).
#
# Usage: ROMDIR=... [MAME_BIN=<reference binary, default ~/.cache/vampire-saved/mame-ref/cps2>] tests/audit_tick_cadence.sh
# Runtime: ~50 s (49 s measured solo at the 14z-156 close check: ten MAME legs at ~25x speed plus
# the section B searches; MAME's "Average speed ... (48 seconds)" is EMULATED time, and a
# runtime once read from it came out ~10x too long), emulator tier.
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
    # section B's dumps: all work RAM every frame 2560..2760 (they land beside CHECKSUM_OUT)
    DSPEC="$(python3 -c "print(';'.join(f'{f}:ff0000-ffffff' for f in range(2560, 2761)))")"
    mkdir -p "$W/dump_$g"
    MAME_BIN="$BIN" MAME_SANDBOX="$W/sbd_$g" MAME_ROMPATH="$ROMDIR" DUMPS="$DSPEC" \
        REPLAY="$W/van.rpl" POKES="$VPOKE" CHECKSUM_OUT="$W/dump_$g/c.log" \
        tools/run_mame.sh "$g" -autoboot_script "$REPO/tests/lua/replay.lua" > "$W/dump_$g/mame.out" 2>&1 || true
    nd="$(ls "$W/dump_$g"/dump_*_ff0000.bin 2>/dev/null | wc -l | tr -d ' ')"
    [ "$nd" = 201 ] || { echo "FAIL: leg $g/dumps wrote $nd of 201 work-RAM dumps (see its MAME output)"; tail -3 "$W/dump_$g/mame.out"; exit 1; }
done

python3 - "$W" "$MODE" <<'PY'
import os, sys
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

def ticks(g, pc):
    return {who: Counter(fr for fr, p, off, m in TAPS[g][who] if p == pc["tick"] and off == base)
            for who, base in (("p1", 0xFF8420), ("p2", 0xFF8820))}

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
        t = ticks(g, pc)
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

# ---------------------------------------------------------------- section B
def modulus_pure(col, fs, target, moduli):
    """moduli M whose every residue of col is all-target or all-other, with both kinds present"""
    out = []
    for M in moduli:
        kinds = {}
        for f in fs:
            kinds.setdefault(col[f] % M, set()).add(f in target)
        if all(len(k) == 1 for k in kinds.values()) and any(k == {True} for k in kinds.values()):
            out.append(M)
    return out

def predictors(byte_at, fs, target, offs):
    """(kind, d, off, x): a bit (either polarity) or an exact value whose frames equal the target set at f+d"""
    hits = []
    for d in (-2, -1, 0, 1, 2):
        fr = [f for f in fs if (f + d) in fs]
        want = [f in target for f in fr]
        if not any(want):
            continue
        for off in offs:
            col = [byte_at(off, f + d) for f in fr]
            for b in range(8):
                v = [(x >> b) & 1 == 1 for x in col]
                if v == want or [not y for y in v] == want:
                    hits.append(("bit", d, off, b))
            vals = set(col)
            if 1 < len(vals) <= 64:
                for x in vals:
                    if [c == x for c in col] == want:
                        hits.append(("eq", d, off, x))
    return hits

def accumulators(value_at, fs, target, offs, width):
    """(off, width, k, d, tp, fp, fn): a pausable constant-step accumulator whose carries match the target"""
    mod = 1 << (8 * width); out = []
    pairs = [f for f in fs if f + 1 in fs]
    for off in offs:
        vals = {f: value_at(off, f, width) for f in fs}
        steps = Counter((vals[f + 1] - vals[f]) % mod for f in pairs)
        nz = [k for k in steps if k != 0]
        if len(nz) != 1 or steps[nz[0]] < 0.6 * len(pairs):
            continue
        k = nz[0]
        ev = {f for f in pairs if (vals[f + 1] - vals[f]) % mod == k and vals[f] + k >= mod}
        if not ev:
            continue
        for d in (-2, -1, 0, 1, 2):
            evd = {f + d for f in ev}
            tp = len(evd & target); fp = len(evd - target); fn = len(target - evd)
            if tp and 2 * tp / (2 * tp + fp + fn) >= 0.8:
                out.append((off, width, k, d, tp, fp, fn))
    return out

def section_b(quiet=False):
    fails = []
    def need(cond, msg):
        if not quiet: print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond: fails.append(msg)
    for g in LIVE:
        fs = list(range(2560, 2761))
        D = {f: open(f"{work}/dump_{g}/dump_{f}_ff0000.bin", "rb").read() for f in fs}
        need(all(len(D[f]) == 0x10000 for f in fs), f"{g}: 201 work-RAM dumps of 64 KB")
        steps80 = {(D[f + 1][0x8080] - D[f][0x8080]) & 0xFF for f in fs[:-1]}
        need(steps80 == {1}, f"{g}: RAM:$FF8080 steps +1 between every pair of dumps — the dumps are one frame apart (measured {sorted(steps80)})")
        t = ticks(g, LIVE[g])["p2"]
        target = {f for f in fs if t[f] >= 2}
        need(len(target) > 0, f"{g}: {len(target)} P2 double-tick frames inside the dump window")
        counter = {f: D[f][0x8080] for f in fs}
        # the frame-counter modulus, and its plant
        planted = {f for f in fs if counter[f] % 3 == 0}
        need(3 in modulus_pure(counter, fs, planted, range(2, 65)), f"{g}: planted — a target defined as $FF8080 % 3 == 0 is found at modulus 3")
        real = modulus_pure(counter, fs, target, range(2, 65))
        need(real == [], f"{g}: no modulus 2..64 of $FF8080 separates double-tick frames from single ones (measured {real})")
        # the bit / exact-value predictor over $FF8000-$FF83FF, and its plant
        const = [o for o in range(0x8000, 0x8400) if len({D[f][o] for f in fs}) == 1]
        need(len(const) > 0, f"{g}: a constant byte exists in $FF8000-$FF83FF to plant into")
        po = const[0]
        plant = {f: (0x08 if f in target else 0x00) for f in fs}
        byte_planted = lambda off, f: plant[f] if off == po else D[f][off]
        got = predictors(byte_planted, fs, target, [po])
        need(("bit", 0, po, 3) in got, f"{g}: planted — bit 3 of RAM:${0xFF0000 + po:06X} set on the double frames is found at d = 0")
        real = predictors(lambda off, f: D[f][off], fs, target, range(0x8000, 0x8400))
        need(real == [], f"{g}: no bit or exact value of $FF8000-$FF83FF equals the double-tick set at d = -2..+2 (measured {len(real)} hit(s))")
        # the accumulator over all work RAM, and its two plants (their own carry sets)
        const_all = [o for o in range(0, 0x10000 - 1) if len({D[f][o] for f in fs}) == 1 and len({D[f][o + 1] for f in fs}) == 1]
        need(len(const_all) > 0, f"{g}: a constant word exists in work RAM to plant into")
        ao = const_all[0]
        for width, k, v0 in ((1, 0x3B, 0x10), (2, 0x3B11, 0x1000)):
            mod = 1 << (8 * width); v = v0; col = {}
            for i, f in enumerate(fs):
                col[f] = v
                v = (v + (0 if i % 17 == 16 else k)) % mod
            carries = {f for f in fs[:-1] if col[f + 1] != col[f] and col[f] + k >= mod}
            def value_planted(off, f, w, col=col, width=width):
                if off == ao and w == width:
                    return col[f]
                return int.from_bytes(D[f][off:off + w], "big")
            got = accumulators(value_planted, fs, carries, [ao], width)
            need(any(o == ao and dd == 0 and fp == 0 and fn == 0 for o, w, kk, dd, tp, fp, fn in got),
                 f"{g}: planted — a width-{width} accumulator stepping +{k:#x} with pauses is found against its {len(carries)} carries")
        real = []
        for width in (1, 2):
            real += accumulators(lambda off, f, w: int.from_bytes(D[f][off:off + w], "big"), fs, target, range(0, 0x10000 - width + 1), width)
        need(real == [], f"{g}: no pausable constant-step accumulator anywhere in work RAM carries on the double-tick frames (F1 >= 0.8; measured {len(real)})")
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
if not fails:
    fails += section_b()
if fails:
    print(f"FAIL: audit_tick_cadence — {len(fails)} assertion(s) failed")
    sys.exit(1)
print("PASS: audit_tick_cadence — vsav2 doubles every third frame, vsavj every fourth or fifth, globally and inside one activation; the tick twin is live; neither the frame counter, a single $FF8000-$FF83FF bit or value, nor a work-RAM accumulator decides it (each search found its plant)")
PY
