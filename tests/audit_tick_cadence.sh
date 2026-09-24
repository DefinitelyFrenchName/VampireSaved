#!/bin/sh
# audit_tick_cadence.sh — THE EXTRA LOGIC PASS IS DECIDED BY THE SPEED LEVEL, and on vanilla content each game's DEFAULT play mode sets a different one: vsav2 (TURBO, level 8) doubles its pass every third frame, vsavj (NORMAL, level 6) every fourth or fifth, both fighters on the same frames, both passes inside ONE activation of the game task; section C: the decider, the play mode, the stack chain through the game-task loop, and causal controls at matched levels (GitHub #135, measured 14z-156 and 14z-158).
#
# WHAT: the engine's extra logic pass is decided by the SPEED LEVEL, and each game's default
#   play mode sets a different one on vanilla content — vsav2 (TURBO, level 8) doubles its
#   pass every third frame, vsavj (NORMAL, level 6) every fourth or fifth — both fighters on
#   the same frames, both passes inside one activation of the game task; the decider, the
#   play mode and the stack chain measured (#135).
# HOW: the vanilla Victor mirror on vsav2 and vsavj on MAME under tests/lua/tap_writes.lua
#   (no debugger): taps on both fighters' node pointer/timer/tick, P2's hit-freeze, and the
#   task table, plus a whole-work-RAM dump every frame over 2560-2760; section B's negative
#   searches must first find a planted case; controls read vs2's taps with vsavj's PCs,
#   predict from the frame counter instead of the pass counter, and read the chain from the
#   supervisor stack.
# EXPECTS: the frozen tick, double-tick and freeze counts per game, one activation per
#   frame, the pass prediction matching every frame from $FF8081 and the level; each control
#   fails its section. Levels other than 6 and 8 are not asserted.
#
# MUST-FIRE: perturbed-copy: twin-pc — vsav2's taps read with vsavj's tick and node-entry PCs must fail the live-twin assertion (no writes land there), so every count below is proven to rest on the PC map
# MUST-FIRE: perturbed-copy: frame-counter-decider — section C's pass prediction computed from the FRAME counter $FF8080 instead of the PASS counter $FF8081 must fail the every-frame match, so the prediction is proven to rest on the counter the decider reads
# MUST-FIRE: shadow-tool: supervisor-stack — section C's return-address chain read from the supervisor stack (the "SP" state, what tap_writes.lua's STACKLOG read before 14z-158) must fail to find the game-task loop, so the chain is proven to rest on the live user stack
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
#     set defined as counter % 3 == 0 must be found at modulus 3.
#     THIS NEGATIVE IS TRUE OF THE BYTE AND ONLY OF THE BYTE (14z-172, #168): $FF8080
#     wraps at 256 and 256 % 3 == 1, % 13 == 9, so every wrap ROTATES the residue — this
#     window has one, at frame 2652 (255 -> 0). Indexed by the FRAME INDEX instead, the
#     double-pass frames ARE one residue class mod 3 at level 8 and three mod 13 at
#     level 6, disjoint from the single ones, in this very window; the cadence is
#     strictly periodic and tests/audit_tick_phase.sh is where that is asserted.
#     The plant above could not have caught the difference: it defines its target set in
#     the INSTRUMENT'S OWN COORDINATES (counter % 3), so it rides through the wrap with
#     the instrument ([VSP-166]; docs/game/engine_internals.md, the cadence bullet);
#   * any single bit or exact byte value of $FF8000-$FF83FF at frame f-2..f+2 equal to
#     the double-tick set: none; planted: bit 3 of a constant byte set on the double
#     frames must be found at d = 0;
#   * a constant-step accumulator ANYWHERE in the 64 KB (a byte or a big-endian word
#     whose non-zero per-frame step is one constant on >= 60% of frames — it may pause
#     — and whose carry frames match the double set with F1 >= 0.8 at d = -2..2): none;
#     planted: a byte stepping +0x3B with a pause every 17th frame, and a word stepping
#     +0x3B11, each found against its own carry set.
# ~~WHAT DECIDES THE SECOND PASS IS STILL NOT LOCATED~~ — LOCATED 14z-158, section C.
#
# SECTION C — WHAT DECIDES IT, MEASURED 14z-158: THE SPEED LEVEL. The game task's loop
# (vsavj PRG:0x008E0C, vs2 0x0075DA, the same code) counts passes in $FF8081 and, before
# each pass, the decider (vsavj 0x008E32, vs2 0x007600) requests an extra pass in the same
# activation when the turbo-pass flag $FF812D is set and bit (($FF8081 + 1) & 31) of the
# level's 32-bit pattern (vsavj 0x008E6C, vs2 0x00763A) is 1. The level $FF8116 is written
# at the play-mode menu after character select from a per-game table read through the data
# view, and vsav2 sets P1's cursor to TURBO at character confirm where vsavj sets NORMAL.
# Frozen:
#   C1 static: the decider byte-identical in both games; the 16 patterns identical, bits set
#      per level 0 1 2 3 4 6 6 7 8 9 10 11 12 13 16 16; the level table giving levels 0/6/7/8
#      (vsavj) and 0/4/6/8 (vs2) for index 0..3; the cursor-default instructions
#      (clr.b $7(a6) on vsavj, move.b #$1,$7(a6) on vs2).
#   C2 on section B's dumps: $FF812D = 1 and $FF8116 = 8 (vs2) / 6 (vsavj) on all 201 frames;
#      the decider predicts the pass-counter step on all 200 frames; every P2 double-tick frame
#      (tap frame f is dump frame f+1) is a two-pass frame.
#   C3 a STACKLOG tap on P2's node timer: every tick write returns through the game-task loop
#      (vsavj 0x00941E and 0x008E26, vs2 0x007C1E and 0x0075F4) on the live USER stack.
#   C4 the play-mode confirm: vs2 cursor 1, index 3, level 8; vsavj cursor 0, index 1, level 6.
#   C5 causal, the RNG pinned on both games from frame 2400: level 8 on both (vsavj forced) and
#      level 6 on both (vs2's cursor forced to NORMAL, the game writing 6 itself) tick on the
#      same frames over 2560..2899; vsavj with $FF812D forced 0 has no double-tick frame.
# THE CROSS-GAME DIFFERENCE SECTION A FREEZES IS THE PLAY MODE, NOT THE ENGINE ([VSE-84]).
#
# Usage: ROMDIR=... [MAME_BIN=<reference binary, default ~/.cache/vampire-saved/mame-ref/cps2>] tests/audit_tick_cadence.sh
# Runtime: ~1.5 min (90 s measured 14z-158 with section C's 16 legs; 49 s before them, measured solo at the 14z-156 close check: ten MAME legs at ~25x speed plus
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

# ---- SECTION C's legs (14z-158): the decider's static facts need both decrypted
# views; the stack chain, the play-mode writes and the causal pairs are taps on the
# same Victor mirror. The causal pairs pin the RNG ($FF80D4-D5) on both games, which
# otherwise pick the fighters' update order differently ([VSE-84]).
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_dat.bin" || { echo "FAIL: vsavj decrypt view"; exit 1; }
decrypt_view vsav2 "$W/vsav2_op.bin" "$W/vsav2_dat.bin" || { echo "FAIL: vsav2 decrypt view"; exit 1; }
seq_pokes() { python3 -c "import sys; a, b, s = sys.argv[1:4]; print(';'.join(f'{f}:{s}' for f in range(int(a), int(b))))" "$1" "$2" "$3"; }
cleg() {  # cleg <name> <set> <tap> <frames> <window> <pokes> [VAR=value ...]
    _n="$1"; _g="$2"; _t="$3"; _fr="$4"; _wi="$5"; _pk="$6"; shift 6
    env "$@" MAME_BIN="$BIN" MAME_SANDBOX="$W/sbc_$_n" MAME_ROMPATH="$ROMDIR" \
        REPLAY="$W/van.rpl" POKES="$_pk" TAP="$_t" WINDOW="$_wi" FRAMES="$_fr" TRACE_OUT="$W/$_n.tap" \
        tools/run_mame.sh "$_g" -autoboot_script "$REPO/tests/lua/tap_writes.lua" > "$W/$_n.out" 2>&1 || true
    rm -rf "$W/sbc_$_n"
    grep -q "^END $_fr " "$W/$_n.tap" 2>/dev/null \
        || { echo "FAIL: section C leg $_n did not reach frame $_fr (see its MAME output)"; tail -3 "$W/$_n.out"; exit 1; }
}
RNG="$(seq_pokes 2400 2901 ff80d4:0000)"
L8="$(seq_pokes 2000 2901 ff8116:08)"
CUR0="$(seq_pokes 1900 1960 ff8407:00)"
OFF="$(seq_pokes 2400 2901 ff812d:00)"
for g in vsav2 vsavj; do
    cleg "${g}_stk"   "$g" ff8820,4 2760 2560,2760 "$VPOKE" STACKLOG=1 STACKLOG_DEPTH=8
    cleg "${g}_lvl"   "$g" ff8116,2 2000 800,2000  "$VPOKE" REGLOG=1
    cleg "${g}_cur"   "$g" ff8406,2 1965 1200,1965 "$VPOKE"
    cleg "c8_${g}_p1" "$g" ff841c,8 2900 2300,2900 "$VPOKE;$L8;$RNG"
    cleg "c8_${g}_p2" "$g" ff881c,8 2900 2300,2900 "$VPOKE;$L8;$RNG"
done
cleg c6_vsav2_p1  vsav2 ff841c,8 2900 2300,2900 "$VPOKE;$CUR0;$RNG"
cleg c6_vsav2_p2  vsav2 ff881c,8 2900 2300,2900 "$VPOKE;$CUR0;$RNG"
cleg c6_vsav2_lvl vsav2 ff8116,2 2000 800,2000  "$VPOKE;$CUR0" REGLOG=1
cleg c6_vsavj_p1  vsavj ff841c,8 2900 2300,2900 "$VPOKE;$RNG"
cleg c6_vsavj_p2  vsavj ff881c,8 2900 2300,2900 "$VPOKE;$RNG"
cleg off_vsavj_p2 vsavj ff881c,8 2900 2300,2900 "$VPOKE;$OFF"

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
    need(FROZEN["vsav2"]["d2"] > FROZEN["vsavj"]["d2"], "vsav2 doubles more often than vsavj (each game's DEFAULT play mode: vs2 TURBO level 8, vsavj NORMAL level 6 — section C)")
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
# ---------------------------------------------------------------- section C (14z-158)
C_GAME = {
    "vsavj": dict(decider=0x008E32, table=0x008E6C, tbl=0x00A7F0, cursor_pc=0x020D38, cursor_words="422e0007",
                  level_pc="020df2", cursor_writer="020d38", loop=(0x00941E, 0x008E26),
                  level=6, cursor=0, index=1, levels=[0, 6, 7, 8]),
    "vsav2": dict(decider=0x007600, table=0x00763A, tbl=0x009030, cursor_pc=0x01F98C, cursor_words="1d7c00010007",
                  level_pc="01fa48", cursor_writer="01f98c", loop=(0x007C1E, 0x0075F4),
                  level=8, cursor=1, index=3, levels=[0, 4, 6, 8]),
}
BITS = [0, 1, 2, 3, 4, 6, 6, 7, 8, 9, 10, 11, 12, 13, 16, 16]

def section_c(mode):
    fails = []
    def need(cond, msg):
        print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond: fails.append(msg)
    V = {g: {k: open(f"{work}/{g}_{k}.bin", "rb").read() for k in ("op", "dat")} for g in C_GAME}
    # C1 — static, the decrypted views
    j, v = C_GAME["vsavj"], C_GAME["vsav2"]
    need(V["vsavj"]["op"][j["decider"]:j["table"]] == V["vsav2"]["op"][v["decider"]:v["table"]],
         f"the pass decider is byte-identical in both games (opcode view, {j['table'] - j['decider']} bytes)")
    pats = {g: [int.from_bytes(V[g]["op"][C_GAME[g]["table"] + 4 * k:C_GAME[g]["table"] + 4 * k + 4], "big")
                for k in range(16)] for g in C_GAME}
    need(pats["vsavj"] == pats["vsav2"] and [bin(x).count("1") for x in pats["vsavj"]] == BITS,
         f"the 16 speed-level patterns are identical in both games, bits set per level {BITS}")
    for g, c in C_GAME.items():
        lv = list(V[g]["dat"][c["tbl"]:c["tbl"] + 4])
        need(lv == c["levels"], f"{g}: the play-mode level table (data view) gives levels {lv} for index 0..3 (frozen {c['levels']})")
        w = V[g]["op"][c["cursor_pc"]:c["cursor_pc"] + len(c["cursor_words"]) // 2].hex()
        need(w == c["cursor_words"], f"{g}: the cursor default at character confirm is {w} (frozen {c['cursor_words']}, cursor {c['cursor']})")
    # C2 — section B's dumps: the decider predicts every frame
    for g, c in C_GAME.items():
        fs = list(range(2560, 2761))
        D = {f: open(f"{work}/dump_{g}/dump_{f}_ff0000.bin", "rb").read() for f in fs}
        need(all(D[f][0x812D] == 1 and D[f][0x8116] == c["level"] for f in fs),
             f"{g}: turbo-pass flag $FF812D = 1 and speed level $FF8116 = {c['level']} on all 201 dumped frames")
        def mism(counter_off):
            out = []
            for f in fs[1:]:
                step = (D[f][0x8081] - D[f - 1][0x8081]) & 0xFF
                lvl = D[f - 1][0x8116] & 0xF
                pred = 2 if D[f - 1][0x812D] and (pats[g][lvl] >> ((D[f - 1][counter_off] + 1) & 31)) & 1 else 1
                if pred != step: out.append(f)
            return out
        off = 0x8080 if mode == "frame-counter-decider" else 0x8081
        bad = mism(off)
        need(bad == [], f"{g}: the decider (bit (($FF{off:04X} + 1) & 31) of the level's pattern) predicts the pass count of all 200 frames 2561..2760 (mismatches {bad[:6]})")
        if mode == "":
            ctl = mism(0x8080)
            if ctl:
                print(f"CONTROL FIRED: frame-counter-decider — {g}: predicted from the frame counter $FF8080, {len(ctl)} of 200 frames mismatch")
            else:
                print(f"CONTROL DEAD: frame-counter-decider — {g}: the frame counter predicts as well as the pass counter"); fails.append("frame-counter-decider dead")
        t = ticks(g, LIVE[g])["p2"]
        dt = {f + 1 for f in range(2560, 2760) if t[f] >= 2}
        tp = {f for f in fs[1:] if (D[f][0x8081] - D[f - 1][0x8081]) & 0xFF == 2}
        need(len(dt) > 0 and dt <= tp,
             f"{g}: every one of P2's {len(dt)} double-tick frames (tap frame f = dump frame f+1) is a two-pass frame ({len(tp)} two-pass frames)")
    # C3 — the stack chain through the game-task loop
    for g, c in C_GAME.items():
        def chain(which):
            n = bad = 0
            for l in open(f"{work}/{g}_stk.tap"):
                if not l.startswith("frame"): continue
                t = l.split()
                if t[3] != LIVE[g]["tick"] or int(t[5], 16) != 0xFF8820 or "sstack" not in t: continue
                i, k = t.index("stack"), t.index("sstack")
                vals = [int(x, 16) & 0xFFFFFF for x in (t[i + 1:k] if which == "stack" else t[k + 1:])]
                n += 1
                if not all(r in vals for r in c["loop"]): bad += 1
            return n, bad
        which = "sstack" if mode == "supervisor-stack" else "stack"
        n, bad = chain(which)
        need(n > 0 and bad == 0,
             f"{g}: all {n} P2 tick writes return through the game-task loop ({', '.join('%06X' % r for r in c['loop'])}) on the {'supervisor' if which == 'sstack' else 'live user'} stack ({bad} do not)")
        if mode == "":
            cn, cb = chain("sstack")
            if cn > 0 and cb == cn:
                print(f"CONTROL FIRED: supervisor-stack — {g}: read from the supervisor stack, none of the {cn} tick writes shows the loop")
            else:
                print(f"CONTROL DEAD: supervisor-stack — {g}: the supervisor stack shows the loop on {cn - cb} of {cn}"); fails.append("supervisor-stack dead")
    # C4 — the play mode
    def reg_line(path, pc):
        for l in open(path):
            if l.startswith("frame"):
                t = l.split()
                if t[3] == pc:
                    return t, dict(x.split("=") for x in t if "=" in x)
        return None, None
    for g, c in C_GAME.items():
        t, r = reg_line(f"{work}/{g}_lvl.tap", c["level_pc"])
        got = (int(t[7], 16) >> 8) & 0xFF if t else None
        need(t is not None and got == c["level"] and int(r["D0"], 16) == 2 * c["cursor"] and int(r["D1"], 16) == c["index"],
             f"{g}: at the play-mode confirm ({c['level_pc']}) the level written is {got}, cursor {int(r['D0'], 16) // 2 if r else None}, index {int(r['D1'], 16) if r else None} (frozen level {c['level']}, cursor {c['cursor']}, index {c['index']})")
        cur = [l.split() for l in open(f"{work}/{g}_cur.tap") if l.startswith("frame")]
        cw = [int(x[7], 16) & 0xFF for x in cur if x[3] == c["cursor_writer"] and int(x[9], 16) == 0xFF]
        need(cw == [c["cursor"]], f"{g}: P1's play-mode cursor is set to {cw} at character confirm by {c['cursor_writer']} (frozen [{c['cursor']}])")
    # C5 — causal, the RNG pinned on both games
    def dist(name, g, base):
        cnt = Counter()
        for l in open(f"{work}/{name}.tap"):
            if l.startswith("frame"):
                t = l.split()
                if t[3] == LIVE[g]["tick"] and int(t[5], 16) == base: cnt[int(t[1])] += 1
        W = range(2560, 2900)
        return sum(cnt[f] for f in W), frozenset(f for f in W if cnt[f] >= 2)
    doubles = {}
    for L in (8, 6):
        for who, base in (("p1", 0xFF8420), ("p2", 0xFF8820)):
            a, b = dist(f"c{L}_vsavj_{who}", "vsavj", base), dist(f"c{L}_vsav2_{who}", "vsav2", base)
            doubles[(L, who)] = len(a[1])
            need(a[0] > 0 and a == b,
                 f"level {L}, RNG pinned: {who} ticks {a[0]} times with {len(a[1])} double-tick frames on vsavj, {b[0]} with {len(b[1])} on vsav2 — the same frames")
    t, r = reg_line(f"{work}/c6_vsav2_lvl.tap", C_GAME["vsav2"]["level_pc"])
    got = (int(t[7], 16) >> 8) & 0xFF if t else None
    need(got == 6 and r is not None and int(r["D0"], 16) == 0,
         f"vsav2 with P1's cursor forced to NORMAL writes level {got} itself at the confirm")
    need(doubles[(8, "p2")] > doubles[(6, "p2")],
         f"the level is live: P2 has {doubles[(8, 'p2')]} double-tick frames at level 8 and {doubles[(6, 'p2')]} at level 6")
    o = dist("off_vsavj_p2", "vsavj", 0xFF8820)
    need(o[0] > 0 and len(o[1]) == 0, f"vsavj with the turbo-pass flag forced 0: P2 ticks {o[0]} times with {len(o[1])} double-tick frames")
    return fails

if not fails:
    fails += section_b()
if not fails:
    fails += section_c(MODE)
if fails:
    print(f"FAIL: audit_tick_cadence — {len(fails)} assertion(s) failed")
    sys.exit(1)
print("PASS: audit_tick_cadence — at each game's default play mode vsav2 (TURBO, level 8) doubles every third frame and vsavj (NORMAL, level 6) every fourth or fifth, globally and inside one activation; the tick twin is live; the three searches find no simpler decider; the speed-level decider predicts every frame, the play mode and the stack chain are as frozen, and at matched levels with the RNG pinned the two games tick on the same frames")
PY
