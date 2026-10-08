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
#      best lag 0-6, over the ACTIVE frames — those with a button staged).
# HOW: on MAME (the reference binary, pristine vsavj), three FIELD legs under tests/lua/field_trace.lua — 03_two_player_vs,
#   37_victor_ko_vsavj and 118_input_sweep (a one-side-at-a-time input sweep, promoted from the pilot) — and three
#   WRITE-TAP legs under tests/lua/read_tap.lua over each side's +0x124 and +0x12A words, which give each frame's RUN
#   COUNT of the routine (the writes by PRG:0x022114 and PRG:0x022126). A tap write in tap frame f lands in trace frame
#   f+1. Each check is EXACT (every judged frame), and each carries the control HOMING named, pooled over legs and
#   sides (per leg a side that never moves can tie): the same prediction with the opposite flip (I2), the wrong
#   frame's run count (I3, I5), no `& ~previous` edge mask (I4), and the staged input 120 frames late (I6, its consistency
#   pooled over the active frames of every judged side) must each LOSE frames.
# EXPECTS: every judged frame of I1-I5 predicted, with at least one judged frame per leg and side; I6 1.000 on every human
#   side with active frames; each pooled control strictly below its check's total (I6's below 0.9).
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/read_tap.lua
#   tests/replays/03_two_player_vs.rpl tests/replays/37_victor_ko_vsavj.rpl tests/replays/118_input_sweep.rpl
#   tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: opposite-flip — I2 judged with the L/R swap applied on the OPPOSITE flip source must lose frames (pooled), and as a mode the gate FAILs I2
# MUST-FIRE: perturbed-copy: wrong-run — I3 and I5 judged with the WRONG frame's run count must lose frames (pooled), and as a mode the gate FAILs them
# MUST-FIRE: perturbed-copy: no-edge-mask — I4 judged without its `& ~+0x125` mask must lose frames (pooled), and as a mode the gate FAILs I4
# MUST-FIRE: perturbed-copy: lag-120 — I6 judged against the staged input 120 frames late must fall below 0.9, and as a mode the gate FAILs I6
#
# NOT COVERED: merged-m23 (the pilot measured it identical on these legs; a legacy oracle covers the merged build's
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
echo "  host  $(uname -sm); MAME_BIN $MAME_BIN"

# ADDRESSES ARE COMPUTED from the block base, never concatenated (14z-189: "ff84"+"39f" read a wrong address as 0).
F="ff8109:b:timer"; RT=""
for s in 1 2; do
    base=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 00b:b:face 010:w:x 038:b:s38 050:w:hp 115:b:s115 120:b:p120 124:b:btn 125:b:dir 127:b:mdir \
                12a:b:b12a 12b:b:b12b 12c:b:b12c 12d:b:b12d 394:b:ibtn 395:b:idir; do
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
lagmaj = 0.0
lagn = 0
judged6 = 0
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
                c["I1"] += d[f"b12a{s}"] == d[f"ibtn{s}"]
                src = d[f"face{s}"] if (d[f"s38{s}"] or d[f"s115{s}"]) else d[f"p120{s}"]
                flip = (not src) if PERT == "opposite-flip" else bool(src)
                c["I2"] += d[f"b12b{s}"] == rel(d[f"idir{s}"], flip)
                ctl["I2"] += d[f"b12b{s}"] == rel(d[f"idir{s}"], not src)
                good = byf[f - 1] if k == 1 else d
                wrong = d if k == 1 else byf[f - 1]
                pick = wrong if PERT == "wrong-run" else good
                c["I3"] += (d[f"b12c{s}"], d[f"b12d{s}"]) == (pick[f"b12a{s}"], pick[f"b12b{s}"])
                ctl["I3"] += (d[f"b12c{s}"], d[f"b12d{s}"]) == (wrong[f"b12a{s}"], wrong[f"b12b{s}"])
            c["n4"] += 1
            cur = rel(d[f"idir{s}"], bool(d[f"face{s}"]))
            pred4 = cur if PERT == "no-edge-mask" else (cur & ~d[f"dir{s}"] & 0xff)
            c["I4"] += d[f"mdir{s}"] == pred4
            ctl["I4"] += d[f"mdir{s}"] == cur
            if (f - 2) in byf:
                k5, kc = r124[s][f - 1], r124[s][f - 2]
                if k5:
                    use = kc if PERT == "wrong-run" else k5
                    if use:
                        c["n5"] += 1
                        src5 = byf[f - 1] if use == 1 else d
                        c["I5"] += d[f"btn{s}"] == src5[f"ibtn{s}"]
                    if kc:
                        ctl["n5"] += 1
                        srcc = byf[f - 1] if kc == 1 else d
                        ctl["I5"] += d[f"btn{s}"] == srcc[f"ibtn{s}"]
        for key in ("n", "I1", "I2", "I3", "n4", "I4", "n5", "I5"):
            tot[key] += c[key]
        per.append((leg, s, c))
        res(c["n"] > 0 and c["I1"] == c["n"] and c["I2"] == c["n"] and c["I3"] == c["n"], f"I1-I3 {leg} P{s}",
            f"{c['n']} in-match frames with a run: +0x12A==+0x394 {c['I1']}, +0x12B==swap(+0x395) by the flip source {c['I2']}, "
            f"(+0x12C,+0x12D)==the previous run's {c['I3']}")
        res(c["n4"] > 0 and c["I4"] == c["n4"], f"I4 {leg} P{s}", f"+0x127 == swap(+0x395 by +0x0B) & ~+0x125 on {c['I4']}/{c['n4']} in-match frames")
        res(c["n5"] > 0 and c["I5"] == c["n5"], f"I5 {leg} P{s}", f"+0x124 == +0x394 one run earlier on {c['I5']}/{c['n5']} judged frames")
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
        if PERT == "lag-120":
            cb = cl
        judged6 += 1
        lagmaj += cl * nl; lagn += nl   # POOLED over the judged sides, like every other control here (a side that presses
                                        # one button all match, replay 37's P2, keys as well 120 frames late: 14z-195)
        res(cb == 1.0, f"I6 {leg} P{s}", f"+0x394 by the staged button set at lag {best} on {nb} active frames: consistency {cb:.3f} (the set 120 frames earlier {cl:.3f})")
res(judged6 > 0, "I6", f"{judged6} human sides judged on active frames")
print(f"CTL I2 {ctl['I2']} {tot['n']} I3 {ctl['I3']} {tot['n']} I4 {ctl['I4']} {tot['n4']} I5 {ctl['I5']} {ctl['n5']} I6 {(lagmaj / lagn if lagn else 1.0):.3f}")
sys.exit(1 if bad else 0)
PY
}

echo "== 2. the checks"
if [ -n "${VS_CTL:-}" ]; then
    check "$VS_CTL" > "$W/mode.log" 2>&1 && rc=0 || rc=1
    grep -v '^CTL ' "$W/mode.log"
    tag=""
    case "$VS_CTL" in opposite-flip) tag='I1-I3' ;; wrong-run) tag='I1-I3|I5' ;; no-edge-mask) tag='I4' ;; lag-120) tag='I6' ;; esac
    if [ "$rc" = 1 ] && grep -Eq "FAIL  \[($tag) " "$W/mode.log"; then vs_ctl_fired "$VS_CTL" "the checks judged with the perturbation failed (mode)"
    else vs_ctl_dead "$VS_CTL" "the perturbed checks did not fail where they must (rc $rc)" || true; fi
    echo "FAIL: audit_mizuumi_inputs (control mode)"; exit 1
fi
check none > "$W/checks.log" 2>&1 || fail=1
grep -v '^CTL ' "$W/checks.log"
grep -q '^CTL ' "$W/checks.log" || { echo "  FAIL  the checks produced no control summary (a crash is not a verdict): $(tail -1 "$W/checks.log")"; exit 1; }

echo "== 3. the must-fire controls (pooled over legs and sides)"
set -- $(sed -n 's/^CTL //p' "$W/checks.log")
# CTL I2 <hits> <n> I3 <hits> <n> I4 <hits> <n> I5 <hits> <n> I6 <consistency>
[ "$3" -gt 0 ] && [ "$2" -lt "$3" ] && vs_ctl_fired opposite-flip "the opposite flip predicts $2 of $3 frames" || { vs_ctl_dead opposite-flip "$2 of $3" || true; fail=1; }
[ "$6" -gt 0 ] && [ "$5" -lt "$6" ] && [ "${12}" -gt 0 ] && [ "${11}" -lt "${12}" ] \
    && vs_ctl_fired wrong-run "the wrong run count predicts I3 on $5 of $6 frames and I5 on ${11} of ${12}" || { vs_ctl_dead wrong-run "I3 $5/$6, I5 ${11}/${12}" || true; fail=1; }
[ "$9" -gt 0 ] && [ "$8" -lt "$9" ] && vs_ctl_fired no-edge-mask "without the edge mask +0x127 matches $8 of $9 frames" || { vs_ctl_dead no-edge-mask "$8 of $9" || true; fail=1; }
python3 -c "import sys; sys.exit(0 if float(sys.argv[1]) < 0.9 else 1)" "${14}" \
    && vs_ctl_fired lag-120 "the staged input 120 frames late explains +0x394 at best ${14}" || { vs_ctl_dead lag-120 "${14}" || true; fail=1; }
if [ "$fail" = 0 ]; then echo "PASS: audit_mizuumi_inputs"; else echo "FAIL: audit_mizuumi_inputs"; exit 1; fi
