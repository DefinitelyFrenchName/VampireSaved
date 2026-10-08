#!/bin/sh
# audit_mizuumi_attack.sh — THE ATTACK-START FIELDS OF THE FIGHTER BLOCK, MEASURED (14z-195, promoted from the #118 pilot
# of 14z-194, GitHub #118; HOMING item 3, in part — see NOT COVERED)
#
# WHAT: on pristine vsavj, the mizuumi attack candidates atlas/ram.md records hold as measured:
#   A1 +0x101 at each NEW button press of a human side reads 2 for a kick and 0 for a punch, on the press frame;
#   A2 +0x1B8 counts ATTACK STARTS of a human side: every attack start (a write to +0x101 by PRG:0x02757E) comes with
#      exactly one +0x1B8 write by PRG:0x0274D6, starts that land no hit included — so mizuumi's "whiff counter" is
#      refuted as a whiff count;
#   A3 a CPU side never moves +0x1B8 although it attacks and lands hits;
#   A4 +0x119: PRG:0x028ED0 writes 0xFF only on CHAINED normals — at least three times in 118_chain, each within one frame
#      of a chained start (+0x101 written by PRG:0x028ED8) — and the per-frame value reads 0xFF there, while on the
#      isolated presses of 118_input_sweep 0x028ED0 never writes and the value stays 0 (other PCs write 0xFF
#      transiently, invisible at frame end — measured 14z-195, reported by PC, not asserted);
#   A5 +0x169 reads 13 or 14 on the frame of each landed hit (+0x1B6 incrementing) and never rises except within one frame
#      of one, on the 2P legs.
# HOW: on MAME (the reference binary), FIELD legs under tests/lua/field_trace.lua for 03_two_player_vs, 37_victor_ko_vsavj,
#   118_input_sweep, 118_chain and 02_demitri_vs_cpu (1P: a CPU side that fights), and WRITE-TAP legs under
#   tests/lua/read_tap.lua (each side's +0x100, +0x118 and +0x1B8 words) for the five; a tap write in tap frame f lands
#   in trace frame f+1. Human sides are derived from each replay's input script, never assumed.
# EXPECTS: A1-A5 as stated, each over a nonzero sample. CONTROLS (in-gate, each must make its check fail):
#   previous-press-key (A1 judged against the previous press's key), hit-vs-start (A2's +0x1B8 writes counted against
#   LANDED HITS instead of starts), cpu-side (A3 judged on 02's human side), isolated-presses (A4's chained-start rule
#   judged on the sweep's isolated presses), neighbour-word (A5 judged on +0x168, the next byte: a WRONG WORD read as
#   +0x169 must fail) and hits-shifted (A5 judged against the landed-hit frames moved 30 frames later: a proximity test
#   too loose to tell a hit from a non-hit must fail) — rule-checker run 2026-10-08-729 Q4. The log's header names the
#   commit and the host.
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/read_tap.lua
#   tests/replays/02_demitri_vs_cpu.rpl tests/replays/03_two_player_vs.rpl tests/replays/37_victor_ko_vsavj.rpl
#   tests/replays/118_chain.rpl tests/replays/118_input_sweep.rpl tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: previous-press-key — A1 judged against each press's PREVIOUS press must fail (in-gate); as a mode A1 uses it and the gate FAILs
# MUST-FIRE: perturbed-copy: hit-vs-start — A2 counted against landed hits instead of attack starts must fail (in-gate); as a mode A2 uses it and the gate FAILs
# MUST-FIRE: perturbed-copy: cpu-side — A3 judged on replay 02's HUMAN side must fail (in-gate); as a mode A3 judges it and the gate FAILs
# MUST-FIRE: perturbed-copy: neighbour-word — A5 judged on +0x168 (the neighbouring byte) instead of +0x169 must fail (in-gate); as a mode A5 reads +0x168 and the gate FAILs
# MUST-FIRE: perturbed-copy: hits-shifted — A5 judged against the landed-hit frames moved 30 frames later must fail (in-gate); as a mode A5 uses the shifted frames and the gate FAILs
# MUST-FIRE: perturbed-copy: isolated-presses — A4's chained-start rule judged on 118_input_sweep's isolated presses must fail (in-gate); as a mode A4 judges the sweep and the gate FAILs
#
# NOT COVERED (HOMING item 3's other rows, not promoted at 14z-195): +0x103 (2 toward / 1 back / 0 neither, docs/game/atlas/
#   ram.md — measured at the WRITES by PRG:0x02758C, sweep 28/28; a value read at a press FRAME is not that: replay 37's P2
#   down+HP presses read 2 because neither writer runs there and the earlier toward press's 2 is carried. To be gated
#   at the writes from a tap, not from the field at the press frame — corrected at the merge, 14z-195);
#   +0x167 / +0x168 (the cancel-window tables, measured on the 26/128 marathon re-runs — not promoted); merged-m23;
#   FBNeo (one emulator).
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] tests/audit_mizuumi_attack.sh
#   emulator tier, MAME; ~2 min (ten legs in parallel)
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
echo "  head  $(git -C "$REPO" rev-parse HEAD 2>/dev/null || echo no git); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"

F="ff8109:b:timer"; RT=""
for s in 1 2; do
    base=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 00b:b:face 010:w:x 050:w:hp 101:b:pk 119:b:chf 168:b:exw 169:b:cht 1b6:w:hits 1b8:w:whiff; do
        F="$F,$(printf '%06x' $((base + 0x${spec%%:*}))):${spec#*:}$s"
    done
    for o in 100 118 1b8; do RT="$RT${RT:+;}$(printf '%06x' $((base + 0x$o))),2"; done
done
leg() {  # leg <name> <replay> <frames>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$2" FIELDS="$F" \
        FIELD_OUT="$W/$1.fields" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
tapleg() {  # tapleg <name> <replay> <frames>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$2" RTAP="$RT" WINDOW="0,0" \
        TRACE_OUT="$W/$1.tap" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/read_tap.lua" \
        > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
LEGS="03:tests/replays/03_two_player_vs.rpl:12000 37:tests/replays/37_victor_ko_vsavj.rpl:7000
      sweep:tests/replays/118_input_sweep.rpl:5200 chain:tests/replays/118_chain.rpl:3700
      02:tests/replays/02_demitri_vs_cpu.rpl:12000"
echo "== 1. the legs (pristine vsavj, MAME)"
for l in $LEGS; do
    n="${l%%:*}"; rest="${l#*:}"; r="${rest%%:*}"; fr="${rest#*:}"
    leg "$n" "$r" "$fr" & tapleg "tap$n" "$r" "$fr" &
done
wait
fail=0
for l in $LEGS; do
    n="${l%%:*}"
    grep -q '^FIELDSUMMARY' "$W/$n.fields" 2>/dev/null || { echo "  FAIL  $n: no FIELDSUMMARY (see $W/$n/mame.log) — VOID"; fail=1; }
    grep -q '^END ' "$W/tap$n.tap" 2>/dev/null || { echo "  FAIL  tap$n: no END line (see $W/tap$n/mame.log) — VOID"; fail=1; }
done
[ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_attack (a leg did not complete)"; exit 1; }
echo "  ok    ten legs complete"

check() {  # check <perturbation: none|previous-press-key|hit-vs-start|cpu-side|isolated-presses>
    python3 - "$W" "$REPO" "$1" <<'PY'
import collections, re, sys
W, REPO, PERT = sys.argv[1], sys.argv[2], sys.argv[3]
LEGS = {"03": "tests/replays/03_two_player_vs.rpl", "37": "tests/replays/37_victor_ko_vsavj.rpl", "sweep": "tests/replays/118_input_sweep.rpl",
        "chain": "tests/replays/118_chain.rpl", "02": "tests/replays/02_demitri_vs_cpu.rpl"}
BASE = {1: 0xff8400, 2: 0xff8800}
BTN = set("123456")
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
def staged(rpl):
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
def wfield(leg, s, off):
    """[(trace frame, pc, byte value)] for the byte at block offset `off` (a tap write in tap frame f lands in f+1)."""
    a = BASE[s] + off; out = []
    for l in open(f"{W}/tap{leg}.tap"):
        if l.startswith("W "):
            q = l.split(); f, pc, w, data, mask = int(q[1]), q[3], int(q[5], 16), int(q[7], 16), int(q[9], 16)
            if w == a & ~1:
                if a & 1 and mask & 0x00ff: out.append((f + 1, pc, data & 0xff))
                if not a & 1 and mask & 0xff00: out.append((f + 1, pc, (data >> 8) & 0xff))
    return out
T = {k: load(f"{W}/{k}.fields") for k in LEGS}
S = {k: staged(f"{REPO}/{v}") for k, v in LEGS.items()}
HUMAN = {k: sorted({s for fr in S[k].values() for s in (1, 2) if fr[s]}) for k in LEGS}
# A1 +0x101 at each new press of a human side, on the press frame: 2 kick, 0 punch
n1 = ok1 = 0
for k in ("03", "37", "sweep"):
    byf = {d["f"]: d for d in T[k]}
    for s in HUMAN[k]:
        presses = []
        for d in T[k]:
            f = d["f"]
            if not inmatch(d):
                continue
            new = (S[k].get(f, {1: set(), 2: set()})[s] & BTN) - (S[k].get(f - 1, {1: set(), 2: set()})[s] & BTN)
            if new:
                presses.append((f, "K" if min(new) in "456" else "P"))
        for i, (f, cls) in enumerate(presses):
            if PERT == "previous-press-key":
                if not i:
                    continue
                cls = presses[i - 1][1]
            n1 += 1; ok1 += byf[f][f"pk{s}"] == (2 if cls == "K" else 0)
res(n1 > 0 and ok1 == n1, "A1", f"+0x101 on the press frame is 2 for a kick, 0 for a punch: {ok1}/{n1} presses of the human sides of 03, 37 and the sweep")
# A2 +0x1B8: one write by 0x0274D6 per attack start (a +0x101 write by 0x02757E), misses included
n2 = ok2 = miss_starts = 0; per = []
for k in ("03", "37", "sweep", "chain"):
    byf = {d["f"]: d for d in T[k]}
    for s in HUMAN[k]:
        starts = sorted(f for f, pc, v in wfield(k, s, 0x101) if pc == "02757e")
        w1b8 = collections.Counter(f for f, pc, v in wfield(k, s, 0x1B9) if pc == "0274d6")
        if not starts:
            continue
        hits = sorted(b["f"] for a, b in zip(T[k], T[k][1:]) if b[f"hits{s}"] > a[f"hits{s}"])
        for i, st in enumerate(starts):
            end = min(starts[i + 1] if i + 1 < len(starts) else st + 60, st + 60)
            landed = any(st <= h <= end for h in hits)
            miss_starts += not landed
        cmp_n = len(hits) if PERT == "hit-vs-start" else len(starts)
        n2 += 1; ok2 += sum(w1b8.values()) == cmp_n
        per.append(f"{k} P{s} starts {len(starts)} writes {sum(w1b8.values())}")
res(n2 > 0 and ok2 == n2 and miss_starts > 0, "A2",
    f"+0x1B8 written once per attack start on {ok2}/{n2} human sides ({'; '.join(per)}), {miss_starts} of the starts landing no hit — not a whiff count"
    + (" (mode hit-vs-start: compared with landed hits)" if PERT == "hit-vs-start" else ""))
# A3 a CPU side never moves +0x1B8 (replay 02), while it lands hits
cpu = [s for s in (1, 2) if s not in HUMAN["02"]]
if PERT == "cpu-side":
    cpu = HUMAN["02"]
for s in cpu:
    M = [d for d in T["02"] if inmatch(d)]
    moves = sum(1 for a, b in zip(M, M[1:]) if b[f"whiff{s}"] != a[f"whiff{s}"])
    lands = sum(1 for a, b in zip(M, M[1:]) if b[f"hits{s}"] > a[f"hits{s}"])
    res(len(HUMAN["02"]) == 1 and moves == 0 and lands > 0, "A3", f"replay 02's {'(mode cpu-side: HUMAN) ' if PERT == 'cpu-side' else 'CPU '}side P{s}: +0x1B8 changes {moves} times in {len(M)} in-match frames while it lands {lands} hits")
# A4 +0x119: PRG:0x028ED0 writes 0xFF only at chained starts; the per-frame value reads 0xFF only on the chain leg.
# (14z-195: other PCs also write 0xFF transiently — one on the sweep's isolated presses — and the frame-end value never
# shows it; those writes are REPORTED by PC, not asserted away.)
leg4 = "sweep" if PERT == "isolated-presses" else "chain"
ff = [(f, pc) for f, pc, v in wfield(leg4, 1, 0x119) if v == 0xff]
by28 = [f for f, pc in ff if pc == "028ed0"]
chained = sorted(f for f, pc, v in wfield(leg4, 1, 0x101) if pc == "028ed8")
near = sum(1 for f in by28 if any(abs(f - c) <= 1 for c in chained))
other = collections.Counter(pc for f, pc in ff if pc != "028ed0")
reads = sum(1 for a, b in zip(T[leg4], T[leg4][1:]) if a["chf1"] != 0xff and b["chf1"] == 0xff)
res(len(by28) >= 3 and near == len(by28) and reads >= 3, "A4",
    f"{leg4}: 0x028ED0 wrote +0x119 = 0xFF {len(by28)} times, {near} within 1 f of a chained start ({len(chained)} by 0x028ED8); "
    f"the per-frame value rose to 0xFF {reads} times; other 0xFF writers (transient) {dict(other)}")
swf = [(f, pc) for f, pc, v in wfield("sweep", 1, 0x119) if v == 0xff]
sw = sorted({d["chf1"] for d in T["sweep"] if inmatch(d)} | {d["chf2"] for d in T["sweep"] if inmatch(d)})
res(sw == [0] and not [1 for f, pc in swf if pc == "028ed0"], "A4",
    f"118_input_sweep's isolated presses: +0x119 per-frame value in match {sw}, 0x028ED0 writes 0; other 0xFF writes {dict(collections.Counter(pc for f, pc in swf))}")
# A5 +0x169 at landed hits on the 2P legs (controls: neighbour-word reads +0x168; hits-shifted moves the hit frames 30 later)
at = collections.Counter(); rises = nearhit = nhits = 0
fld5 = "exw" if PERT == "neighbour-word" else "cht"
sh5 = 30 if PERT == "hits-shifted" else 0
for k in ("03", "37", "chain"):
    byf = {d["f"]: d for d in T[k]}
    for s in (1, 2):
        hitf = [b["f"] + sh5 for a, b in zip(T[k], T[k][1:]) if b[f"hits{s}"] > a[f"hits{s}"]]
        hitf = [f for f in hitf if f in byf]
        rf = [b["f"] for a, b in zip(T[k], T[k][1:]) if b[f"{fld5}{s}"] > a[f"{fld5}{s}"]]
        nhits += len(hitf); at.update(byf[f][f"{fld5}{s}"] for f in hitf)
        rises += len(rf); nearhit += sum(1 for r in rf if any(abs(r - h) <= 1 for h in hitf))
res(nhits > 0 and set(at) <= {13, 14} and nearhit == rises, "A5", f"{'+0x168 (mode neighbour-word)' if fld5 == 'exw' else '+0x169'} at {nhits} landed hits{' (moved 30 f later)' if sh5 else ''} {dict(at)}; {nearhit}/{rises} rises within 1 f of a hit (03, 37, chain)")
sys.exit(1 if bad else 0)
PY
}
echo "== 2. the checks"
if [ -n "${VS_CTL:-}" ]; then
    check "$VS_CTL" > "$W/mode.log" 2>&1 && rc=0 || rc=1
    cat "$W/mode.log"
    case "$VS_CTL" in previous-press-key) tag='A1' ;; hit-vs-start) tag='A2' ;; cpu-side) tag='A3' ;; isolated-presses) tag='A4' ;; neighbour-word|hits-shifted) tag='A5' ;; esac
    if [ "$rc" = 1 ] && grep -q "FAIL  \[$tag\]" "$W/mode.log"; then vs_ctl_fired "$VS_CTL" "the perturbed checks failed $tag (mode)"
    else vs_ctl_dead "$VS_CTL" "the perturbed checks did not fail $tag (rc $rc)" || true; fi
    echo "FAIL: audit_mizuumi_attack (control mode)"; exit 1
fi
check none > "$W/checks.log" 2>&1 || fail=1
cat "$W/checks.log"
grep -q '\[A5\]' "$W/checks.log" || { echo "  FAIL  the checks did not reach A5 (a crash is not a verdict): $(tail -1 "$W/checks.log")"; exit 1; }
echo "== 3. the must-fire controls (in-gate)"
for c in previous-press-key:A1 hit-vs-start:A2 cpu-side:A3 isolated-presses:A4 neighbour-word:A5 hits-shifted:A5; do
    name="${c%%:*}"; tag="${c#*:}"
    check "$name" > "$W/ctl_$name.log" 2>&1 && rc=0 || rc=1
    if [ "$rc" = 1 ] && grep -q "FAIL  \[$tag\]" "$W/ctl_$name.log"; then
        vs_ctl_fired "$name" "$(grep "FAIL  \[$tag\]" "$W/ctl_$name.log" | head -1 | sed 's/^ *//' | cut -c1-150)"
    else
        vs_ctl_dead "$name" "the perturbed run did not fail $tag (rc $rc): $(tail -1 "$W/ctl_$name.log" | cut -c1-120)" || true; fail=1
    fi
done
if [ "$fail" = 0 ]; then echo "PASS: audit_mizuumi_attack"; else echo "FAIL: audit_mizuumi_attack"; exit 1; fi
