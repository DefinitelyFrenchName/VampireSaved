#!/bin/sh
# audit_extra_pass.sh — THE SPEED LEVEL'S EXTRA LOGIC PASS, PREDICTED PER FRAME (14z-195, promoted from the #118 pilot of
# 14z-194, GitHub #118; HOMING item 2)
#
# WHAT: on pristine vsavj, how many logic passes the game runs in a video frame (1 or 2 — the "two-tick frames" every
#   frame-rate trace meets) is decided by the static rule at PRG:0x008E0C-0x008E6A: each activation increments the pass
#   counter RAM:$FF8081; if RAM:$FF8118 is set (this pass IS the extra one) it is cleared, else if the turbo-pass flag
#   RAM:$FF812D is set and bit ($FF8081 & 31) of PAT[$FF8116 & 15] is 1, $FF8118 is set and a second pass runs in the
#   same activation. E1: that prediction, made from the counter's first value in the frame and the previous frame's
#   turbo flag, equals the passes counted on EVERY in-match frame with ONE activation — one pass, or two passes with
#   exactly one write SETTING $FF8118 between them; two passes with no set are two one-pass activations and, like a
#   frame with no pass or three or more, are excluded and COUNTED per leg in the readout (rule-checker run
#   2026-10-08-730 Q4) — at the speed level pinned to
#   0, 6, 8 and 14 and unpinned, on two replays. E2: the pin took — every in-match frame of a pinned leg reads its
#   level, and the unpinned leg reads 6 (vsavj's NORMAL). E3: the unpinned leg's passes-per-frame distribution equals
#   the level-6 leg's, count for count.
# HOW: on MAME (the reference binary), for each of 03_two_player_vs and 37_victor_ko_vsavj and each level (00, 06, 08,
#   0e — pinned by POKES on every frame — and free), a FIELD leg (tests/lua/field_trace.lua: level, the pass counter,
#   the turbo and extra-pass flags, HP and X) and a WRITE-TAP leg (tests/lua/read_tap.lua: the pass-counter word,
#   written by PRG:0x008E10 once per pass, and the $FF8118 word, whose SET marks an extra pass in the same activation). PAT is read from the vsavj OPCODE view at run time (the table is read
#   PC-relative at PRG:0x008E6C) — never stored in the tree.
# EXPECTS: E1 exact on every judged frame of all ten legs, with frames judged on each; E2 and E3 as stated. The log's
#   header names the commit and the host. CONTROL
#   other-level: each leg's frames predicted with every OTHER level's pattern must lose frames for the best of them;
#   CONTROL unpinned-equals-6: the same distribution comparison against the level-8 leg must differ.
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lib/decrypt_cache.sh tests/lua/field_trace.lua
#   tests/lua/pokes_spec.lua tests/lua/read_tap.lua tests/replays/03_two_player_vs.rpl
#   tests/replays/37_victor_ko_vsavj.rpl tools/cps2_decrypt.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: other-level — every leg predicted with the best OTHER level's pattern must lose frames (in-gate); as a mode E1 is judged with that pattern and the gate FAILs
# MUST-FIRE: perturbed-copy: unpinned-equals-6 — the unpinned leg's distribution compared with the LEVEL-8 leg's must differ (in-gate); as a mode E3 compares against level 8 and the gate FAILs
#
# NOT COVERED: merged-m23 (the pilot measured the same per-level counts on it); levels other than 0/6/8/14; what sets
#   the turbo-pass flag $FF812D; frames with two activations (excluded from E1, reported); FBNeo (one emulator).
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] [JOBS=10] tests/audit_extra_pass.sh
#   emulator tier, MAME; ~3 min at JOBS=10 (twenty legs)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
JOBS="${JOBS:-10}"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no reference MAME binary at $MAME_BIN"; exit 0; }
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" rev-parse HEAD 2>/dev/null || echo no git); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 || { echo "FAIL: no vsavj opcode view (decrypt cache)"; exit 1; }

F="ff8109:b:timer,ff8116:b:speed,ff8081:b:pass,ff812d:b:tflag,ff8118:b:xflag"
for s in 1 2; do
    base=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 010:w:x 050:w:hp; do F="$F,$(printf '%06x' $((base + 0x${spec%%:*}))):${spec#*:}$s"; done
done
RT="ff8080,2;ff8118,2"   # the pass counter and the extra-pass flag (its SET tells one two-pass activation)
: > "$W/legs.txt"
for r in "03 tests/replays/03_two_player_vs.rpl 12000" "37 tests/replays/37_victor_ko_vsavj.rpl 7000"; do
    set -- $r
    for lv in 00 06 08 0e; do echo "$1_L$lv $2 $3 $lv" >> "$W/legs.txt"; done
    echo "$1_free $2 $3 -" >> "$W/legs.txt"
done
one() {  # one <tag> <replay> <frames> <level|->  — the field leg and the tap leg of one (replay, level)
    PK=""; [ "$4" != - ] && PK="1-$3:ff8116:$4"
    for k in f t; do
        d="$W/$k$1"; rm -rf "$d"; mkdir -p "$d"
        if [ "$k" = f ]; then
            ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$2" FIELDS="$F" POKES="$PK" \
              FIELD_OUT="$W/$1.fields" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj \
              -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) </dev/null 2>/dev/null || true &
        else
            ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$2" RTAP="$RT" WINDOW="0,0" POKES="$PK" \
              TRACE_OUT="$W/$1.tap" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj \
              -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) </dev/null 2>/dev/null || true &
        fi
    done
    wait
}
echo "== 1. the legs (pristine vsavj, MAME; 10 (replay, level) pairs, each a field leg and a tap leg)"
n=0
while read -r tag r fr lv; do
    one "$tag" "$r" "$fr" "$lv" &
    n=$((n + 1)); [ $((n % (JOBS / 2 > 0 ? JOBS / 2 : 1))) -eq 0 ] && wait
done < "$W/legs.txt"
wait
fail=0
while read -r tag r fr lv; do
    grep -q '^FIELDSUMMARY' "$W/$tag.fields" 2>/dev/null || { echo "  FAIL  $tag: no FIELDSUMMARY (see $W/f$tag/mame.log) — VOID"; fail=1; }
    grep -q '^END ' "$W/$tag.tap" 2>/dev/null || { echo "  FAIL  $tag: no tap END line (see $W/t$tag/mame.log) — VOID"; fail=1; }
done < "$W/legs.txt"
[ "$fail" = 0 ] || { echo "FAIL: audit_extra_pass (a leg did not complete)"; exit 1; }
echo "  ok    twenty legs complete"

check() {  # check <perturbation: none|other-level|unpinned-equals-6>
    python3 - "$W" "$W/vsavj_op.bin" "$1" <<'PY'
import collections, sys
W, OPC, PERT = sys.argv[1], sys.argv[2], sys.argv[3]
img = open(OPC, "rb").read()
PAT = [int.from_bytes(img[0x8E6C + 4 * lv:0x8E70 + 4 * lv], "big") for lv in range(16)]
legs = [l.split() for l in open(f"{W}/legs.txt")]
bad = []
def res(c, t, m):
    print(f"  {'ok  ' if c else 'FAIL'}  [{t}] {m}")
    if not c: bad.append(t)
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
dists, ctl_lost = {}, []
for tag, rpl, fr, lv in legs:
    T = load(f"{W}/{tag}.fields"); byf = {d["f"]: d for d in T}
    passes = collections.defaultdict(list); xsets = collections.Counter()
    for l in open(f"{W}/{tag}.tap"):
        if l.startswith("W "):
            q = l.split()
            f, pc, off, data, mask = int(q[1]) + 1, q[3], q[5], int(q[7], 16), int(q[9], 16)
            if pc == "008e10" and off == "ff8080" and mask & 0xff:
                passes[f].append(data & 0xff)
            if off == "ff8118" and mask & 0xff00 and (data >> 8) & 0xff:
                xsets[f] += 1   # the decider SETS $FF8118 when the next pass is the extra one, in the same activation
    # ONE ACTIVATION, judged: one pass, or two passes with exactly one $FF8118 set between them. TWO ACTIVATIONS: two
    # passes and no set (each a one-pass activation). Anything else (no pass, three or more) is excluded — all counted.
    def kind(f):
        n, x = len(passes[f]), xsets[f]
        if n == 1 and x == 0: return "one-1pass"
        if n == 2 and x == 1: return "one-2pass"
        if n == 2 and x == 0: return "two-activations"
        return f"other-{n}p{x}s"
    M = [d for d in T if inmatch(d) and (d["f"] - 1) in byf]
    levels = collections.Counter(d["speed"] for d in M)
    want = 6 if lv == "-" else int(lv, 16)
    res(M and set(levels) == {want}, f"E2 {tag}", f"the level on every in-match frame: {dict(levels)} (want {want})")
    L = want & 15
    dist = collections.Counter(len(passes[d["f"]]) for d in M)
    dists[tag] = dist
    kinds = collections.Counter(kind(d["f"]) for d in M)
    def predict(pat):
        ok = n = 0
        for d in M:
            ps = passes[d["f"]]
            if kind(d["f"]) not in ("one-1pass", "one-2pass"):
                continue
            tf = byf[d["f"] - 1]["tflag"]
            n += 1; ok += (1 + (1 if tf and (pat >> (ps[0] & 31)) & 1 else 0)) == len(ps)
        return ok, n
    others = {o: predict(PAT[o]) for o in range(16) if PAT[o] != PAT[L]}
    best_o = max(others, key=lambda o: others[o][0])
    ok, n = predict(PAT[best_o] if PERT == "other-level" else PAT[L])
    res(n > 0 and ok == n, f"E1 {tag}", f"{'(mode other-level: level ' + str(best_o) + ') ' if PERT == 'other-level' else ''}"
        f"passes/frame {dict(sorted(dist.items()))}, the prediction holds on {ok}/{n} frames with one activation "
        f"(PAT[{L}] has {bin(PAT[L]).count('1')}/32 bits); the best other level's pattern {others[best_o][0]}/{n}; "
        f"frames by kind {dict(sorted(kinds.items()))} — excluded {len(M) - n}")
    ctl_lost.append(others[best_o][0] < n)
for r in ("03", "37"):
    ref = f"{r}_L08" if PERT == "unpinned-equals-6" else f"{r}_L06"
    res(dists[f"{r}_free"] == dists[ref], f"E3 {r}", f"the unpinned leg's passes/frame {dict(sorted(dists[f'{r}_free'].items()))} vs {ref}'s {dict(sorted(dists[ref].items()))}")
c8 = all(dists[f"{r}_free"] != dists[f"{r}_L08"] for r in ("03", "37"))
print(f"CTL otherlevel {int(all(ctl_lost))} unpinned8 {int(c8)}")
sys.exit(1 if bad else 0)
PY
}
echo "== 2. the checks"
if [ -n "${VS_CTL:-}" ]; then
    check "$VS_CTL" > "$W/mode.log" 2>&1 && rc=0 || rc=1
    grep -v '^CTL ' "$W/mode.log"
    case "$VS_CTL" in other-level) tag='E1' ;; unpinned-equals-6) tag='E3' ;; esac
    if [ "$rc" = 1 ] && grep -q "FAIL  \[$tag " "$W/mode.log"; then vs_ctl_fired "$VS_CTL" "the perturbed checks failed $tag (mode)"
    else echo "REFUSED: CONTROL=$VS_CTL — the perturbation did not make the check it targets fail (rc $rc): a dead mode, not a verdict"; exit 3; fi
    echo "FAIL: audit_extra_pass (control mode)"; exit 1
fi
check none > "$W/checks.log" 2>&1 || fail=1
grep -v '^CTL ' "$W/checks.log"
grep -q '^CTL ' "$W/checks.log" || { echo "  FAIL  the checks produced no control summary (a crash is not a verdict): $(tail -1 "$W/checks.log")"; exit 1; }
echo "== 3. the must-fire controls"
set -- $(sed -n 's/^CTL //p' "$W/checks.log")
[ "$2" = 1 ] && vs_ctl_fired other-level "on every leg the best other level's pattern loses frames" || { vs_ctl_dead other-level "some leg is predicted as well by another level's pattern" || true; fail=1; }
[ "$4" = 1 ] && vs_ctl_fired unpinned-equals-6 "the unpinned leg's distribution differs from the level-8 leg's on both replays" || { vs_ctl_dead unpinned-equals-6 "the level-8 comparison did not differ" || true; fail=1; }
if [ "$fail" = 0 ]; then echo "PASS: audit_extra_pass"; else echo "FAIL: audit_extra_pass"; exit 1; fi
