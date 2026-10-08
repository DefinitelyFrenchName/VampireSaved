#!/bin/sh
# audit_mizuumi_inputs.sh — THE INPUT WORDS OF THE FIGHTER BLOCK, PREDICTED EXACTLY FROM THEIR STATIC MECHANISM
# (14z-195, promoted from the #118 pilot of 14z-194, GitHub #118; HOMING item 1)
#
# WHAT: on pristine vsavj, the mizuumi input candidates adopted into atlas/ram.md hold on EVERY in-match frame of three
#   replays, both sides, as the static routine PRG:0x022114-0x0221F6 predicts them — not as a statistical fit:
#   I1 +0x12A == +0x394 (the held buttons) on every frame the routine ran (a write by PRG:0x022126);
#   I2 +0x12B == +0x395 (the held directions, ABSOLUTE) with its L/R bits swapped when the flip source is set (+0x0B if
#      +0x38 or +0x115, else +0x120 — PRG:0x0221CC-0x0221F6);
#   I3 (+0x12C, +0x12D) == the PREVIOUS RUN's (+0x12A, +0x12B) (PRG:0x022120): the frame before when the routine ran
#      once, the same frame when it ran twice;
#   I4 +0x127 == swap(+0x395 by +0x0B) & ~+0x125 (newly pressed facing-relative directions, PRG:0x02218E-0x0221B4);
#   I5 +0x124 == +0x394 as it stood one RUN earlier (+0x124 <- +0x122 <- +0x394 at PRG:0x022114, 1-3 runs per frame);
#   I6 +0x394 is the held-button set of the side's own staged input (one value per set, consistency 1.000 at the
#      best lag 0-6, over the ACTIVE frames — those with a button staged);
#   I7 +0x122 == +0x394 and +0x123 == swap(+0x395 by +0x0B) on every frame the routine ran (PRG:0x02211A writes the
#      word, PRG:0x02218E-0x0221A6 swaps its L/R bits when +0x0B is set);
#   I8 the edge words on every in-match frame: +0x126 == +0x122 & ~+0x124 (newly pressed buttons, PRG:0x0221AA-0x0221B4,
#      the word whose low byte is I4's +0x127) and +0x128/+0x129 == +0x124/+0x125 & ~+0x122/+0x123 (newly RELEASED,
#      PRG:0x0221B8-0x0221C2);
#   I10 +0x125 == the previous RUN's +0x123 (+0x124.w <- +0x122.w at PRG:0x022114: the previous frame's when the routine
#      ran once, the same frame's when it ran twice).
#   The routine was listed at 14z-195 with tools/m68k_list.py (PRG:0x022110-0x022200); I7 and I8 are this gate's own
#   measurement — the 14z-194 pilot named +0x122/+0x126 only in its mechanism and +0x128/+0x129 not at all.
# HOW: on MAME (the reference binary, pristine vsavj), three FIELD legs under tests/lua/field_trace.lua — 03_two_player_vs,
#   37_victor_ko_vsavj and 118_input_sweep (a one-side-at-a-time input sweep, promoted from the pilot) — and three
#   WRITE-TAP legs under tests/lua/read_tap.lua over each side's +0x124 and +0x12A words, which give each frame's RUN
#   COUNT of the routine (the writes by PRG:0x022114 and PRG:0x022126). A tap write in tap frame f lands in trace frame
#   f+1. Each check is EXACT (every judged frame), and each carries the control HOMING named, pooled over legs and
#   sides (per leg a side that never moves can tie): the same prediction with the opposite flip (I2), the wrong
#   frame's run count (I3, I5, I10), no `& ~previous` edge mask (I4, I8), the opposite flip for +0x123 (I7) and the
#   OTHER side's +0x394 for I1 must each
#   LOSE frames. I6's control, the staged input 120 frames late, is judged PER
#   SIDE on the sides that CAN discriminate — those whose active frames carry at least two distinct +0x394 values — each
#   below 0.9; a side pressing a single button all match (replay 37's P2: toward+HP) maps its one value to any lagged key
#   alike, so it cannot fail that control and is named, not judged (rule-checker run 2026-10-08-729 Q4).
# EXPECTS: every judged frame of I1-I5, I7, I8 and I10 predicted, with at least one judged frame per leg and side; I6 1.000 on
#   every human side with active frames; each pooled control strictly below its check's total; I6's control below 0.9 on
#   every discriminating side, with at least one such side. The log's header names the commit and the host.
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/read_tap.lua
#   tests/replays/03_two_player_vs.rpl tests/replays/37_victor_ko_vsavj.rpl tests/replays/118_input_sweep.rpl
#   tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: opposite-flip — I2 and I7's +0x123 judged with the L/R swap applied on the OPPOSITE flip source must lose frames (pooled), and as a mode the gate FAILs them
# MUST-FIRE: perturbed-copy: other-side — I1 judged against the OTHER side's +0x394 must lose frames (pooled), and as a mode the gate FAILs I1
# MUST-FIRE: perturbed-copy: wrong-run — I3 and I5 judged with the WRONG frame's run count must lose frames (pooled), and as a mode the gate FAILs them
# MUST-FIRE: perturbed-copy: no-edge-mask — I4 and I8 judged without their `& ~previous` / `& ~current` masks must lose frames (pooled), and as a mode the gate FAILs them
# MUST-FIRE: perturbed-copy: lag-120 — I6 judged against the staged input 120 frames late must fall below 0.9 on every discriminating side, and as a mode the gate FAILs I6
#
# NOT COVERED: I2's FLIP-SOURCE RULE against plain +0x0B — the +0x120 branch is reached (replay 03's P1: the rule and
#   +0x0B differ on 472 frames with a run, measured 14z-195 on ERIS; 0 on the other five sides) but on NONE of those
#   frames is a left or right direction held, so +0x12B reads the same under either rule (plain +0x0B predicted
#   33360/33360): a control replacing the rule by +0x0B was DEAD and was removed; separating them needs a leg holding
#   L or R while +0x38 and +0x115 are clear and +0x120 != +0x0B (the readout prints that count, RULESEP).
#   +0x397 — the pilot's "+0x395 one frame late" does NOT hold exactly: measured 14z-195 on ERIS (c4466c51 +
#   these checks), it equals the PREVIOUS frame's +0x395 on 9531/9537 in-match frames (03 P1 and P2), 4106/4125 (37 P2),
#   3050/3058 and 3051/3058 (sweep P1/P2), the SAME frame's on 33304/33440 pooled; the rule for the misses (its writer
#   PRG:0x014E52/58 against the frame boundary) is not determined, so it is not asserted; +0x12E/+0x12F (the routine goes on past PRG:0x0221FA into its own edge words — not traced); merged-m23 (the pilot measured it identical on these legs; a legacy oracle covers the merged build's
#   legacy content); what the game DOES with each word (who reads +0x127 is a static row of ram.md, PRG:0x029930);
#   FBNeo (one emulator).
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] tests/audit_mizuumi_inputs.sh
#   emulator tier, MAME; ~2 min (six legs in parallel)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no reference MAME binary at $MAME_BIN"; exit 0; }
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"

# ADDRESSES ARE COMPUTED from the block base, never concatenated (14z-189: "ff84"+"39f" read a wrong address as 0).
F="ff8109:b:timer"; RT=""
for s in 1 2; do
    base=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 00b:b:face 010:w:x 038:b:s38 050:w:hp 115:b:s115 120:b:p120 124:b:btn 125:b:dir 127:b:mdir \
                12a:b:b12a 12b:b:b12b 12c:b:b12c 12d:b:b12d 394:b:ibtn 395:b:idir \
                122:b:b122 123:b:b123 126:b:b126 128:b:b128 129:b:b129; do
        F="$F,$(printf '%06x' $((base + 0x${spec%%:*}))):${spec#*:}$s"
    done
    for o in 124 12a; do RT="$RT${RT:+;}$(printf '%06x' $((base + 0x$o))),2"; done
done
leg() {  # leg <name> <replay> <frames>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$2" FIELDS="$F" \
        FIELD_OUT="$W/$1.fields" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true   # a teardown segfault (MFI-12): the FIELDSUMMARY line decides
}
tapleg() {  # tapleg <name> <replay> <frames>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$2" RTAP="$RT" WINDOW="0,0" \
        TRACE_OUT="$W/$1.tap" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/read_tap.lua" \
        > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true   # the END line decides
}
echo "== 1. the legs (pristine vsavj, MAME)"
leg 03 tests/replays/03_two_player_vs.rpl 12000 & leg 37 tests/replays/37_victor_ko_vsavj.rpl 7000 &
leg sweep tests/replays/118_input_sweep.rpl 5200 &
tapleg tap03 tests/replays/03_two_player_vs.rpl 12000 & tapleg tap37 tests/replays/37_victor_ko_vsavj.rpl 7000 &
tapleg tapsweep tests/replays/118_input_sweep.rpl 5200 &
wait
fail=0
for r in 03 37 sweep; do
    grep -q '^FIELDSUMMARY' "$W/$r.fields" 2>/dev/null || { echo "  FAIL  $r: no FIELDSUMMARY (see $W/$r/mame.log) — VOID"; fail=1; }
    grep -q '^END ' "$W/tap$r.tap" 2>/dev/null || { echo "  FAIL  tap$r: no END line (see $W/tap$r/mame.log) — VOID"; fail=1; }
done
[ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_inputs (a leg did not complete)"; exit 1; }
echo "  ok    six legs complete"

check() {  # check <perturbation: none|opposite-flip|wrong-run|no-edge-mask|lag-120> — ok/FAIL lines and a CTL summary line
    python3 - "$W" "$REPO" "$1" <<'PY'
import collections, re, sys
W, REPO, PERT = sys.argv[1], sys.argv[2], sys.argv[3]
LEGS = {"03": "tests/replays/03_two_player_vs.rpl", "37": "tests/replays/37_victor_ko_vsavj.rpl", "sweep": "tests/replays/118_input_sweep.rpl"}
BASE = {1: 0xff8400, 2: 0xff8800}
SWAP = [0, 2, 1, 3]
BTN = set("123456")
def load(p):
    T = []
    for l in open(p):
        if l.startswith("F "):
            q = l.split(); d = {"f": int(q[1])}
            for kv in q[2:]:
                k, v = kv.split("="); d[k] = int(v)
            T.append(d)
    return T
def inmatch(d): return d["hp1"] > 0 and d["hp2"] > 0 and d["x1"] and d["x2"]
def runs(tap, off, pc):
    """tap frame -> number of writes by `pc` to the word at block offset `off`, per side."""
    out = {1: collections.Counter(), 2: collections.Counter()}
    for l in open(tap):
        if l.startswith("W "):
            q = l.split()
            if q[3] != pc:
                continue
            a = int(q[5], 16)
            for s in (1, 2):
                if a == BASE[s] + off:
                    out[s][int(q[1])] += 1
    return out
def staged(rpl):
    """frame -> {1: set(tokens), 2: set(tokens)}, field_trace.lua's replay grammar (one character per token)."""
    S = collections.defaultdict(lambda: {1: set(), 2: set()})
    for line in open(rpl):
        body = line.split("#")[0].strip()
        if not body:
            continue
        rng, *specs = body.split()
        a, _, b = rng.partition("-"); a = int(a); b = int(b) if b else a
        for sp in specs:
            m = re.match(r"^p([12])=(\S+)$", sp)
            if m:
                for fr in range(a, b + 1):
                    S[fr][int(m.group(1))] |= set(m.group(2))
    return S
def rel(dirbyte, flip): return (dirbyte & ~3) | SWAP[dirbyte & 3] if flip else dirbyte
bad = []
def res(c, t, m):
    print(f"  {'ok  ' if c else 'FAIL'}  [{t}] {m}")
    if not c: bad.append(t)
tot = collections.Counter(); ctl = collections.Counter()
judged6 = 0
ndisc = 0
lagworst = 0.0
nondisc = []
per = []
for leg, rpl in LEGS.items():
    T = load(f"{W}/{leg}.fields"); byf = {d["f"]: d for d in T}
    r12a = runs(f"{W}/tap{leg}.tap", 0x12A, "022126")
    r124 = runs(f"{W}/tap{leg}.tap", 0x124, "022114")
    S = staged(f"{REPO}/{rpl}")
    for s in (1, 2):
        c = collections.Counter()
        for d in T:
            f = d["f"]
            if not inmatch(d) or (f - 1) not in byf:
                continue
            k = r12a[s][f - 1]          # the routine's runs that produced trace frame f
            if k:
                c["n"] += 1
                c["I1"] += d[f"b12a{s}"] == d[f"ibtn{3 - s if PERT == 'other-side' else s}"]
                ctl["I1"] += d[f"b12a{s}"] == d[f"ibtn{3 - s}"]   # control other-side: the OTHER side's +0x394
                src = d[f"face{s}"] if (d[f"s38{s}"] or d[f"s115{s}"]) else d[f"p120{s}"]
                flip = (not src) if PERT == "opposite-flip" else bool(src)
                c["I2"] += d[f"b12b{s}"] == rel(d[f"idir{s}"], flip)
                ctl["I2"] += d[f"b12b{s}"] == rel(d[f"idir{s}"], not src)
                good = byf[f - 1] if k == 1 else d
                wrong = d if k == 1 else byf[f - 1]
                pick = wrong if PERT == "wrong-run" else good
                c["I3"] += (d[f"b12c{s}"], d[f"b12d{s}"]) == (pick[f"b12a{s}"], pick[f"b12b{s}"])
                ctl["I3"] += (d[f"b12c{s}"], d[f"b12d{s}"]) == (wrong[f"b12a{s}"], wrong[f"b12b{s}"])
                c["rulediff"] += bool(src) != bool(d[f"face{s}"])   # frames where the flip-source rule and plain +0x0B differ
                c["rulesep"] += bool(src) != bool(d[f"face{s}"]) and (d[f"idir{s}"] & 3) in (1, 2)   # ... with L or R held: the
                                                                                                     # only frames that can tell them apart
                fl7 = (not d[f"face{s}"]) if PERT == "opposite-flip" else bool(d[f"face{s}"])
                c["I7"] += d[f"b122{s}"] == d[f"ibtn{s}"] and d[f"b123{s}"] == rel(d[f"idir{s}"], fl7)
                ctl["I7"] += d[f"b122{s}"] == d[f"ibtn{s}"] and d[f"b123{s}"] == rel(d[f"idir{s}"], not d[f"face{s}"])
            c["n4"] += 1
            cur = rel(d[f"idir{s}"], bool(d[f"face{s}"]))
            pred4 = cur if PERT == "no-edge-mask" else (cur & ~d[f"dir{s}"] & 0xff)
            c["I4"] += d[f"mdir{s}"] == pred4
            ctl["I4"] += d[f"mdir{s}"] == cur
            nomask = PERT == "no-edge-mask"
            p126 = d[f"b122{s}"] if nomask else (d[f"b122{s}"] & ~d[f"btn{s}"] & 0xff)
            p128 = d[f"btn{s}"] if nomask else (d[f"btn{s}"] & ~d[f"b122{s}"] & 0xff)
            p129 = d[f"dir{s}"] if nomask else (d[f"dir{s}"] & ~d[f"b123{s}"] & 0xff)
            c["I8"] += (d[f"b126{s}"], d[f"b128{s}"], d[f"b129{s}"]) == (p126, p128, p129)
            ctl["I8"] += (d[f"b126{s}"], d[f"b128{s}"], d[f"b129{s}"]) == (d[f"b122{s}"], d[f"btn{s}"], d[f"dir{s}"])
            if (f - 2) in byf:
                k5, kc = r124[s][f - 1], r124[s][f - 2]
                if k5:
                    use = kc if PERT == "wrong-run" else k5
                    if use:
                        c["n5"] += 1
                        src5 = byf[f - 1] if use == 1 else d
                        c["I5"] += d[f"btn{s}"] == src5[f"ibtn{s}"]
                        c["I10"] += d[f"dir{s}"] == src5[f"b123{s}"]   # +0x125 <- the previous run's +0x123 (PRG:0x022114, the word)
                    if kc:
                        ctl["n5"] += 1
                        srcc = byf[f - 1] if kc == 1 else d
                        ctl["I5"] += d[f"btn{s}"] == srcc[f"ibtn{s}"]
                        ctl["I10"] += d[f"dir{s}"] == srcc[f"b123{s}"]
        for key in ("n", "I1", "I2", "I3", "n4", "I4", "n5", "I5", "I7", "I8", "I10", "rulediff", "rulesep"):
            tot[key] += c[key]
        per.append((leg, s, c))
        res(c["n"] > 0 and c["I1"] == c["n"] and c["I2"] == c["n"] and c["I3"] == c["n"], f"I1-I3 {leg} P{s}",
            f"{c['n']} in-match frames with a run: +0x12A==+0x394 {c['I1']}, +0x12B==swap(+0x395) by the flip source {c['I2']}, "
            f"(+0x12C,+0x12D)==the previous run's {c['I3']}")
        res(c["n4"] > 0 and c["I4"] == c["n4"], f"I4 {leg} P{s}", f"+0x127 == swap(+0x395 by +0x0B) & ~+0x125 on {c['I4']}/{c['n4']} in-match frames")
        res(c["n5"] > 0 and c["I5"] == c["n5"], f"I5 {leg} P{s}", f"+0x124 == +0x394 one run earlier on {c['I5']}/{c['n5']} judged frames")
        res(c["n5"] > 0 and c["I10"] == c["n5"], f"I10 {leg} P{s}", f"+0x125 == the previous run's +0x123 on {c['I10']}/{c['n5']} judged frames")
        print(f"  info  [flip-rule {leg} P{s}] the flip-source rule and plain +0x0B differ on {c['rulediff']} of {c['n']} frames with a run, "
              f"{c['rulesep']} of them with L or R held (the only frames that could separate them)")
        res(c["n"] > 0 and c["I7"] == c["n"], f"I7 {leg} P{s}", f"+0x122 == +0x394 and +0x123 == swap(+0x395 by +0x0B) on {c['I7']}/{c['n']} frames with a run")
        res(c["n4"] > 0 and c["I8"] == c["n4"], f"I8 {leg} P{s}", f"+0x126 == +0x122 & ~+0x124, +0x128/+0x129 == +0x124/+0x125 & ~+0x122/+0x123 on {c['I8']}/{c['n4']} in-match frames")
    # I6: +0x394 is the held-button set of the side's own staged input — consistency at the best lag 0-6, both human sides
    human = {s for fr in S.values() for s in (1, 2) if fr[s]}
    def keyat(s, f):
        return "".join(sorted(S.get(f, {1: set(), 2: set()})[s] & BTN))
    for s in sorted(human):
        # ACTIVE frames only (a button staged at the judged lag): on idle frames both the input and the lagged input are
        # empty, which made a whole-trace consistency read 0.98-1.00 at lag+120 (14z-195, the first ERIS run)
        def cons(lag, ctl_shift=0):
            by = collections.defaultdict(collections.Counter)
            for d in T:
                f = d["f"]
                if inmatch(d) and (f - lag - ctl_shift) in byf and keyat(s, f - lag):
                    by[keyat(s, f - lag - ctl_shift) or "-"][d[f"ibtn{s}"]] += 1
            n = sum(sum(v.values()) for v in by.values())
            return (sum(v.most_common(1)[0][1] for v in by.values()) / n) if n else 0.0, n
        best = max(range(0, 7), key=lambda L: cons(L)[0])
        cb, nb = cons(best); cl, nl = cons(best, 120)
        if nb == 0:
            print(f"  info  [I6 {leg} P{s}] no in-match frame with a staged button — not judged")
            continue
        # can this side FAIL the lag control at all? only if its active frames carry two or more +0x394 values: one value
        # maps to any lagged key alike (replay 37's P2 presses toward+HP all match — rule-checker run 2026-10-08-729 Q4)
        vals = {d[f"ibtn{s}"] for d in T if inmatch(d) and (d["f"] - best) in byf and keyat(s, d["f"] - best)}
        disc = len(vals) >= 2
        if PERT == "lag-120" and disc:
            cb = cl
        judged6 += 1
        if disc:
            ndisc += 1; lagworst = max(lagworst, cl)
        else:
            nondisc.append(f"{leg}P{s}")
        res(cb == 1.0, f"I6 {leg} P{s}", f"+0x394 by the staged button set at lag {best} on {nb} active frames: consistency {cb:.3f}; "
            + (f"the set 120 frames earlier {cl:.3f} (judged)" if disc else f"ONE +0x394 value on its active frames {sorted(vals)}: the lag control cannot discriminate here, not judged ({cl:.3f})"))
res(judged6 > 0, "I6", f"{judged6} human sides judged on active frames; the lag control applies to {ndisc} of them (not to {' '.join(nondisc) or 'none'})")
print(f"CTL I2 {ctl['I2']} {tot['n']} I3 {ctl['I3']} {tot['n']} I4 {ctl['I4']} {tot['n4']} I5 {ctl['I5']} {ctl['n5']} I6 {lagworst:.3f} {ndisc} "
      f"I7 {ctl['I7']} {tot['n']} I8 {ctl['I8']} {tot['n4']} I10 {ctl['I10']} {ctl['n5']} RULEDIFF {tot['rulediff']} {tot['n']} RULESEP {tot['rulesep']} I1X {ctl['I1']} {tot['n']}")
sys.exit(1 if bad else 0)
PY
}

echo "== 2. the checks"
if [ -n "${VS_CTL:-}" ]; then
    check "$VS_CTL" > "$W/mode.log" 2>&1 && rc=0 || rc=1
    grep -v '^CTL ' "$W/mode.log"
    tag=""
    case "$VS_CTL" in opposite-flip) tag='I1-I3|I7' ;; other-side) tag='I1-I3' ;; wrong-run) tag='I1-I3|I5|I10' ;; no-edge-mask) tag='I4|I8' ;; lag-120) tag='I6' ;; esac
    if [ "$rc" = 1 ] && grep -Eq "FAIL  \[($tag) " "$W/mode.log"; then vs_ctl_fired "$VS_CTL" "the checks judged with the perturbation failed (mode)"
    else echo "REFUSED: CONTROL=$VS_CTL — the perturbation did not make the check it targets fail (rc $rc): a dead mode, not a verdict"; exit 3; fi
    echo "FAIL: audit_mizuumi_inputs (control mode)"; exit 1
fi
check none > "$W/checks.log" 2>&1 || fail=1
grep -v '^CTL ' "$W/checks.log"
grep -q '^CTL ' "$W/checks.log" || { echo "  FAIL  the checks produced no control summary (a crash is not a verdict): $(tail -1 "$W/checks.log")"; exit 1; }

echo "== 3. the must-fire controls (pooled over legs and sides)"
set -- $(sed -n 's/^CTL //p' "$W/checks.log")
# CTL I2 <hits> <n> I3 <hits> <n> I4 <hits> <n> I5 <hits> <n> I6 <worst discriminating side> <sides> I7 <hits> <n> I8 <hits> <n> I10 <hits> <n> RULEDIFF <frames> <n> RULESEP <frames> I1X <hits> <n>
[ "$3" -gt 0 ] && [ "$2" -lt "$3" ] && [ "${18}" -gt 0 ] && [ "${17}" -lt "${18}" ] \
    && vs_ctl_fired opposite-flip "the opposite flip predicts +0x12B on $2 of $3 frames and +0x123 on ${17} of ${18}" || { vs_ctl_dead opposite-flip "I2 $2/$3, I7 ${17}/${18}" || true; fail=1; }
[ "$6" -gt 0 ] && [ "$5" -lt "$6" ] && [ "${12}" -gt 0 ] && [ "${11}" -lt "${12}" ] && [ "${23}" -lt "${24}" ] \
    && vs_ctl_fired wrong-run "the wrong run count predicts I3 on $5 of $6 frames, I5 on ${11} of ${12}, I10 on ${23} of ${24}" || { vs_ctl_dead wrong-run "I3 $5/$6, I5 ${11}/${12}, I10 ${23}/${24}" || true; fail=1; }
echo "  info  I2's flip-source rule vs plain +0x0B: they differ on ${26} of ${27} frames with a run, ${29} of them with L or R held — the rule is NOT separated from +0x0B on these legs (see NOT COVERED)"
[ "${32}" -gt 0 ] && [ "${31}" -lt "${32}" ] && vs_ctl_fired other-side "the OTHER side's +0x394 matches +0x12A on ${31} of ${32} frames" || { vs_ctl_dead other-side "${31} of ${32}" || true; fail=1; }
[ "$9" -gt 0 ] && [ "$8" -lt "$9" ] && [ "${21}" -gt 0 ] && [ "${20}" -lt "${21}" ] \
    && vs_ctl_fired no-edge-mask "without the edge masks +0x127 matches $8 of $9 frames and +0x126/+0x128/+0x129 ${20} of ${21}" || { vs_ctl_dead no-edge-mask "I4 $8/$9, I8 ${20}/${21}" || true; fail=1; }
python3 -c "import sys; sys.exit(0 if float(sys.argv[1]) < 0.9 and int(sys.argv[2]) > 0 else 1)" "${14}" "${15}" \
    && vs_ctl_fired lag-120 "on each of the ${15} discriminating sides the staged input 120 frames late explains +0x394 at most ${14}" || { vs_ctl_dead lag-120 "worst ${14} over ${15} discriminating sides" || true; fail=1; }
if [ "$fail" = 0 ]; then echo "PASS: audit_mizuumi_inputs"; else echo "FAIL: audit_mizuumi_inputs"; exit 1; fi
