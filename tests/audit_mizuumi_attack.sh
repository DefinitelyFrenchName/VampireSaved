#!/bin/sh
# audit_mizuumi_attack.sh — THE ATTACK-START FIELDS OF THE FIGHTER BLOCK, MEASURED (14z-195, promoted from the #118 pilot
# of 14z-194, GitHub #118; HOMING item 3, in part — see NOT COVERED)
#
# WHAT: on pristine vsavj, the mizuumi attack candidates atlas/ram.md records hold as measured:
#   A1 +0x101 reads 2 for a kick and 0 for a punch — on the press frame and in the value written — on each new press
#      PAIRED with a fresh attack start (a +0x101 write by PRG:0x02757E within 2 frames), on every human side of all five
#      legs; presses with no such start (118_chain's chained presses, whose start is 0x028ED8's, and presses that start
#      nothing, e.g. replay 37's P2 holding one button) are counted per side and judged on nothing;
#   A2 +0x1B8 counts ATTACK STARTS of a human side: every FRESH attack start (a write to +0x101 by PRG:0x02757E) is
#      PAIRED ONE-TO-ONE IN TIME with a +0x1B8 write by PRG:0x0274D6 within 1 frame (every start and every write used
#      once; the offsets are reported; every write by 0x0274D6 or 0x028F18 RAISES the word by exactly 1 over its previous
#      value), on every human side of all five legs, starts that land no hit included — so mizuumi's "whiff counter" is refuted as a
#      whiff count; A2b no CHAINED start (+0x101 written by PRG:0x028ED8) has a 0x0274D6 write within that window (the
#      chained count per leg reported, nonzero on 118_chain); A2c each chained start pairs one-to-one with a +0x1B8 write
#      by PRG:0x028F18 instead — so +0x1B8 counts chained starts too, through a second writer (the 14z-194 pilot's
#      census already listed 0x028F18 on the chain leg; rule-checker run 2026-10-08-732);
#   A3 a CPU side never moves +0x1B8 although it attacks and lands hits;
#   A4 +0x119: PRG:0x028ED0 writes 0xFF only on CHAINED normals — at least three times in 118_chain, each within one frame
#      of a chained start (+0x101 written by PRG:0x028ED8) — and every rise of the per-frame value to 0xFF lies within one
#      frame of a chained start (at least three), on either side, while on the
#      isolated presses of 118_input_sweep, on EACH side, 0x028ED0 never writes and the value stays 0 (other PCs write 0xFF
#      transiently, invisible at frame end — measured 14z-195, reported by PC, not asserted); and on all five legs, both
#      sides, every 0x028ED0 0xFF write and every rise of the per-frame value to 0xFF lies within one frame of a chained
#      start on that side;
#   A5 +0x169 reads 13 or 14 on the frame of each landed hit (+0x1B6 incrementing) and never rises except within one frame
#      of one, on both sides of the 2P legs — 03, 37, 118_chain and 118_input_sweep (per-leg hits and rises reported; the
#      sweep's isolated presses land no hit and +0x169 never rises there). 02 (1P vs CPU) is NOT judged: there the claim
#      does not hold as stated (rule-checker run 2026-10-08-738, measured 14z-195 on ERIS: the CPU side's landed hit at
#      trace frame 3553 reads 0, and 6 of 48 rises lie farther than 1 f from a hit — three paired events, P2 rising to 14
#      at 4288/4411/4617 and P1 to 255 one frame later, mechanism not measured); its per-side values are printed as info.
# HOW: on MAME (the reference binary), FIELD legs under tests/lua/field_trace.lua for 03_two_player_vs, 37_victor_ko_vsavj,
#   118_input_sweep, 118_chain and 02_demitri_vs_cpu (1P: a CPU side that fights), and WRITE-TAP legs under
#   tests/lua/read_tap.lua (each side's +0x100, +0x118 and +0x1B8 words) for the five; a tap write in tap frame f lands
#   in trace frame f+1. Human sides are derived from each replay's input script, never assumed.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row, each loaded zip's sha1 — or the gate FAILs before any leg.
#    A1-A5 as stated, each over a nonzero sample. CONTROLS (in-gate, each must make its check fail):
#   previous-press-key (A1 judged against the previous press's key), hit-vs-start (A2's +0x1B8 writes paired with
#   LANDED HITS instead of starts), writes-shifted (A2's writes moved 20 frames later, beyond the window: a write at
#   another moment than the start must fail), reads-shifted (A4's 0xFF rises moved 20 frames later, away from the
#   chained starts), chained-writes-shifted (A2c's 0x028F18 writes moved 20 frames later), cpu-side (A3 judged on 02's human side), isolated-presses (A4's chained-start rule
#   judged on the sweep's isolated presses), neighbour-word (A5 judged on +0x168, the next byte: a WRONG WORD read as
#   +0x169 must fail) and hits-shifted (A5 judged against the landed-hit frames moved 30 frames later: a proximity test
#   too loose to tell a hit from a non-hit must fail) — rule-checker run 2026-10-08-729 Q4. The log's header names the
#   commit and the host.
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/read_tap.lua
#   tests/replays/02_demitri_vs_cpu.rpl tests/replays/03_two_player_vs.rpl tests/replays/37_victor_ko_vsavj.rpl
#   tests/replays/118_chain.rpl tests/replays/118_input_sweep.rpl tools/run_mame.sh tools/setup_mame.sh
#   tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py tests/expected/registry.tsv
#
# MUST-FIRE: perturbed-copy: previous-press-key — A1 judged against each press's PREVIOUS press must fail (in-gate); as a mode A1 uses it and the gate FAILs
# MUST-FIRE: perturbed-copy: hit-vs-start — A2 counted against landed hits instead of attack starts must fail (in-gate); as a mode A2 uses it and the gate FAILs
# MUST-FIRE: perturbed-copy: writes-shifted — A2 with every +0x1B8 write moved 20 frames later (beyond the 1-frame pairing window) must fail (in-gate); as a mode A2 uses the moved writes and the gate FAILs
# MUST-FIRE: perturbed-copy: reads-shifted — A4 with every 0xFF rise of the per-frame value moved 20 frames later must fail (in-gate); as a mode A4 uses the moved rises and the gate FAILs
# MUST-FIRE: perturbed-copy: chained-counted — A2 with the 0x028ED8 chained starts treated as starts to pair with 0x0274D6 writes must fail (in-gate); as a mode A2 pairs them and the gate FAILs
# MUST-FIRE: perturbed-copy: chained-writes-shifted — A2c with every 0x028F18 +0x1B8 write moved 20 frames later (beyond the 1-frame window) must fail (in-gate); as a mode A2c uses the moved writes and the gate FAILs
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
# WHICH ROM RAN (rule-checker run 2026-10-08-736 Q1): every member of every reference zip verified against
# docs/checksums.txt (tools/audit_roms.py), the vsavj program fingerprint equal to tests/expected/registry.tsv's vsavj row,
# and each loaded zip's sha1 printed — a ROMDIR that is not the pristine set FAILs here, before any leg runs.
romchk="$(python3 "$REPO/tools/audit_roms.py" "$ROMDIR" 2>&1)" || true   # set -e: a failing audit must reach the FAIL line, not kill the shell
echo "$romchk" | grep -q 'all match' || { echo "FAIL: ROMDIR is not the pristine reference set (tools/audit_roms.py against docs/checksums.txt):"; echo "$romchk" | tail -5; exit 1; }
romfp="$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR" --set vsavj --sha-only 2>/dev/null)" || true
regfp="$(awk -F'\t' '$2 == "vsavj" && $1 !~ /^#/ {print $1}' "$REPO/tests/expected/registry.tsv")"
[ -n "$romfp" ] && [ "$romfp" = "$regfp" ] || { echo "FAIL: vsavj program fingerprint '$romfp' is not the registry's vsavj row '$regfp'"; exit 1; }
echo "  rom   $(echo "$romchk" | grep 'all match' | head -1); vsavj program fingerprint $romfp = registry vsavj row; zips $(python3 -c 'import hashlib,sys; print(" ".join(f"{z}.zip=" + hashlib.sha1(open(f"{sys.argv[1]}/{z}.zip","rb").read()).hexdigest() for z in ("vsavj","vsav","qsound_hle")))' "$ROMDIR")"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"

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
def wword(leg, s, off):
    """[(trace frame, pc, new word, previous word or None)] for every write to the WORD at block offset `off`, in tap
    order; the previous value is the last write's (any PC) — None before the first."""
    a = BASE[s] + off; out = []; prev = None
    for l in open(f"{W}/tap{leg}.tap"):
        if l.startswith("W "):
            q = l.split(); f, pc, w, data, mask = int(q[1]), q[3], int(q[5], 16), int(q[7], 16), int(q[9], 16)
            if w == a and mask == 0xffff:
                out.append((f + 1, pc, data, prev)); prev = data
    return out
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
# A1 +0x101 on each new press that STARTS A FRESH NORMAL: the press is paired with a +0x101 write by 0x02757E within W1
# frames (offsets reported); a paired press reads 2 for a kick, 0 for a punch, on its press frame AND in the value written.
# Presses with no such start (a chained press — its start is 0x028ED8's — or a press that starts nothing) are COUNTED per
# side and judged on nothing (rule-checker run 2026-10-08-736 Q4). previous-press-key judges the paired presses against
# the previous paired press's class, on the sides whose paired presses hold both a kick and a punch (a side pressing one
# class only cannot fail it, and is named).
W1 = 2
n1 = ok1 = 0; per1 = {}; offs1 = collections.Counter(); ndisc1 = 0; pkfail = []; pknon = []
for k in ("03", "37", "sweep", "02", "chain"):
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
        starts1 = [(f, v) for f, pc, v in wfield(k, s, 0x101) if pc == "02757e"]
        free = list(starts1); paired = []
        for f, cls in presses:
            cand = [(sf, v) for sf, v in free if abs(sf - f) <= W1]
            if cand:
                sf, v = min(cand, key=lambda x: abs(x[0] - f)); free.remove((sf, v)); paired.append((f, cls, v)); offs1[sf - f] += 1
        classes = {c for _, c, _ in paired}
        disc = len(classes) == 2
        good_n = prev_lost = 0
        for i, (f, cls, v) in enumerate(paired):
            want = cls
            if PERT == "previous-press-key":
                if not i:
                    continue
                want = paired[i - 1][1]
            enc = 2 if want == "K" else 0
            good = byf[f][f"pk{s}"] == enc and v == enc
            n1 += 1; ok1 += good; good_n += good
            if i:   # the control, judged in every run: the previous paired press's class
                penc = 2 if paired[i - 1][1] == "K" else 0
                prev_lost += not (byf[f][f"pk{s}"] == penc and v == penc)
        per1[f"{k} P{s}"] = (len(presses), len(paired), good_n)
        if disc:
            ndisc1 += 1
            if prev_lost == 0:
                pkfail.append(f"{k}P{s}")
        else:
            pknon.append(f"{k}P{s}")
res(n1 > 0 and ok1 == n1, "A1", f"+0x101 is 2 for a kick, 0 for a punch, on the press frame and in the 0x02757E write, on {ok1}/{n1} presses PAIRED with a "
    f"fresh start within {W1} f (start-press offsets {dict(sorted(offs1.items()))}) — per side (presses, paired, judged ok): "
    + "; ".join(f"{k} {a}/{b}/{c}" for k, (a, b, c) in per1.items())
    + (" (mode previous-press-key: the previous paired press's class)" if PERT == "previous-press-key" else ""))
print(f"  info  [A1] unpaired presses (no 0x02757E start within {W1} f, judged on nothing): "
      + "; ".join(f"{k} {a - b}" for k, (a, b, c) in per1.items()))
print(f"CTLA1 {ndisc1} {len(pkfail)} {','.join(pknon) or '-'} {','.join(sorted(set(per1) - {k.replace('P', ' P') for k in pknon})).replace(' ', '') or '-'}")
# A2 +0x1B8: one write by 0x0274D6 per attack start (a +0x101 write by 0x02757E), misses included
n2 = ok2 = miss_starts = 0; per = []; offs = collections.Counter()
chain_bad = ok2c = 0; chained_by = {}; per2c = []; inc_n = inc_ok = 0
W2 = 1   # the pairing window: the tap shows each 0x0274D6 write in the same frame as its start (offsets reported)
for k in ("03", "37", "sweep", "02", "chain"):   # every leg (rule-checker run 2026-10-08-738: 02 had been left out)
    byf = {d["f"]: d for d in T[k]}
    for s in HUMAN[k]:
        starts = sorted(f for f, pc, v in wfield(k, s, 0x101) if pc == "02757e")
        w1b8 = collections.Counter(f for f, pc, v in wfield(k, s, 0x1B9) if pc == "0274d6")
        # every 0x0274D6 / 0x028F18 write must RAISE the word by exactly 1 (rule-checker run 2026-10-08-734 Q1a)
        for f, pc, new, prev in wword(k, s, 0x1B8):
            if pc in ("0274d6", "028f18"):
                inc_n += 1; inc_ok += prev is not None and new == (prev + 1) & 0xffff
        if not starts:
            continue
        hits = sorted(b["f"] for a, b in zip(T[k], T[k][1:]) if b[f"hits{s}"] > a[f"hits{s}"])
        for i, st in enumerate(starts):
            end = min(starts[i + 1] if i + 1 < len(starts) else st + 60, st + 60)
            landed = any(st <= h <= end for h in hits)
            miss_starts += not landed
        # PAIRED IN TIME (rule-checker run 2026-10-08-729/731): each start matched one-to-one with a 0x0274D6 write within
        # W2 frames, every start and every write used once; the offsets are reported. hit-vs-start pairs the writes with
        # the LANDED HITS instead; writes-shifted moves every write 20 frames later (beyond the window).
        wf = sorted(f + (20 if PERT == "writes-shifted" else 0) for f in w1b8.elements())
        # CHAINED starts (+0x101 written by 0x028ED8) are NOT 0x0274D6's (rule-checker run 2026-10-08-732): none may have a
        # 0x0274D6 write within W2; they pair one-to-one with +0x1B8 writes by 0x028F18 instead (A2c, measured 14z-195)
        chained2 = sorted(f for f, pc, v in wfield(k, s, 0x101) if pc == "028ed8")
        wf18 = sorted(f + (20 if PERT == "chained-writes-shifted" else 0) for f, pc, v in wfield(k, s, 0x1B9) if pc == "028f18")
        chain_bad += sum(1 for c in chained2 if any(abs(w - c) <= W2 for w in wf))
        free18 = list(wf18); m18 = 0
        for c in chained2:
            cand = [w for w in free18 if abs(w - c) <= W2]
            if cand:
                w = min(cand, key=lambda x: abs(x - c)); free18.remove(w); m18 += 1
        ok2c += m18 == len(chained2) == len(wf18)
        chained_by[k] = chained_by.get(k, 0) + len(chained2)
        per2c.append(f"{k} P{s} chained {len(chained2)} by-0x028F18 {len(wf18)} paired {m18}")
        events = hits if PERT == "hit-vs-start" else sorted(starts + chained2) if PERT == "chained-counted" else starts
        free = list(wf); matched = 0
        for st in events:
            cand = [w for w in free if abs(w - st) <= W2]
            if cand:
                w = min(cand, key=lambda x: abs(x - st)); free.remove(w); matched += 1; offs[w - st] += 1
        n2 += 1; ok2 += matched == len(events) == len(wf)
        per.append(f"{k} P{s} starts {len(starts)} writes {len(wf)} paired {matched}")
res(n2 > 0 and ok2 == n2 and miss_starts > 0, "A2",
    f"each attack start paired one-to-one with a +0x1B8 write within {W2} f on {ok2}/{n2} human sides ({'; '.join(per)}; write-start offsets {dict(sorted(offs.items()))}), "
    f"{miss_starts} of the starts landing no hit — not a whiff count"
    + (" (mode hit-vs-start: paired with landed hits)" if PERT == "hit-vs-start" else "")
    + (" (mode writes-shifted: writes moved 20 f later)" if PERT == "writes-shifted" else "")
    + (" (mode chained-counted: the 0x028ED8 chained starts paired too)" if PERT == "chained-counted" else ""))
res(inc_n > 0 and inc_ok == inc_n, "A2", f"every +0x1B8 write by 0x0274D6 or 0x028F18 raises the word by exactly 1 over its previous value: {inc_ok}/{inc_n}")
res(chain_bad == 0 and chained_by.get("chain", 0) > 0, "A2b",
    f"no 0x028ED8 chained start has a 0x0274D6 +0x1B8 write within {W2} f ({chain_bad} do); chained starts per leg {chained_by} (nonzero on 118_chain required)")
res(ok2c == n2 and chained_by.get("chain", 0) > 0, "A2c",
    f"each chained start paired one-to-one with a +0x1B8 write by 0x028F18 within {W2} f on {ok2c}/{n2} human sides ({'; '.join(per2c)}) — "
    f"+0x1B8 counts chained starts too, through another writer")
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
# BOTH sides (rule-checker run 2026-10-08-734 Q1b): writes, chained starts and the per-frame rises are taken per side
ff = [(s, f, pc) for s in (1, 2) for f, pc, v in wfield(leg4, s, 0x119) if v == 0xff]
by28 = [(s, f) for s, f, pc in ff if pc == "028ed0"]
chained_s = {s: sorted(f for f, pc, v in wfield(leg4, s, 0x101) if pc == "028ed8") for s in (1, 2)}
chained = sorted(chained_s[1] + chained_s[2])
near = sum(1 for s, f in by28 if any(abs(f - c) <= 1 for c in chained_s[s]))
other = collections.Counter(pc for s, f, pc in ff if pc != "028ed0")
# the per-frame value's rises to 0xFF, each within 1 frame of a chained start (rule-checker run 2026-10-08-731 Q1);
# reads-shifted moves every rise 20 frames later, away from the starts
rises4 = [(s, b["f"] + (20 if PERT == "reads-shifted" else 0)) for s in (1, 2)
          for a, b in zip(T[leg4], T[leg4][1:]) if a[f"chf{s}"] != 0xff and b[f"chf{s}"] == 0xff]
reads = sum(1 for s, r in rises4 if any(abs(r - c) <= 1 for c in chained_s[s]))
res(len(by28) >= 3 and near == len(by28) and reads >= 3 and reads == len(rises4), "A4",
    f"{leg4}: 0x028ED0 wrote +0x119 = 0xFF {len(by28)} times, {near} within 1 f of a chained start ({len(chained)} by 0x028ED8); "
    f"the per-frame value rose to 0xFF {len(rises4)} times{' (moved 20 f later)' if PERT == 'reads-shifted' else ''}, {reads} of them within 1 f of a chained start "
    f"(P1 {sum(1 for s, f in by28 if s == 1)} writes / {len(chained_s[1])} chained, P2 {sum(1 for s, f in by28 if s == 2)} / {len(chained_s[2])}); "
    f"other 0xFF writers (transient) {dict(other)}")
# ... and on EVERY leg, both sides (rule-checker run 2026-10-08-738): each 0x028ED0 0xFF write and each rise of the
# per-frame value to 0xFF lies within 1 frame of a same-side chained start (reads-shifted moves the rises 20 f later)
allw = allwn = allr = allrn = 0; per4 = {}
for k in ("03", "37", "sweep", "02", "chain"):
    t = per4.setdefault(k, [0, 0, 0, 0, 0])
    for s in (1, 2):
        ch = sorted(f for f, pc, v in wfield(k, s, 0x101) if pc == "028ed8")
        w28 = [f for f, pc, v in wfield(k, s, 0x119) if v == 0xff and pc == "028ed0"]
        rr = [b["f"] + (20 if PERT == "reads-shifted" else 0) for a, b in zip(T[k], T[k][1:]) if a[f"chf{s}"] != 0xff and b[f"chf{s}"] == 0xff]
        wn = sum(1 for f in w28 if any(abs(f - c) <= 1 for c in ch)); rn = sum(1 for f in rr if any(abs(f - c) <= 1 for c in ch))
        allw += len(w28); allwn += wn; allr += len(rr); allrn += rn
        t[0] += len(ch); t[1] += len(w28); t[2] += wn; t[3] += len(rr); t[4] += rn
res(allw > 0 and allwn == allw and allrn == allr, "A4",
    f"every leg, both sides: {allwn}/{allw} 0x028ED0 0xFF writes and {allrn}/{allr} per-frame rises to 0xFF within 1 f of a chained start"
    f"{' (rises moved 20 f later)' if PERT == 'reads-shifted' else ''} — per leg (chained starts, writes, writes near, rises, rises near): {per4}")
for s in (1, 2):   # the sweep's isolated presses, EACH side (both sides press in 118_input_sweep)
    swf = [(f, pc) for f, pc, v in wfield("sweep", s, 0x119) if v == 0xff]
    sw = sorted({d[f"chf{s}"] for d in T["sweep"] if inmatch(d)})
    pr = sum(1 for f in S["sweep"] if (S["sweep"][f][s] & BTN) and not (S["sweep"].get(f - 1, {1: set(), 2: set()})[s] & BTN)
             and f in {d["f"] for d in T["sweep"] if inmatch(d)})
    res(sw == [0] and not [1 for f, pc in swf if pc == "028ed0"] and pr > 0, "A4",
        f"118_input_sweep's isolated presses, P{s} ({pr} presses in match): +0x119 per-frame value {sw}, 0x028ED0 writes "
        f"{sum(1 for f, pc in swf if pc == '028ed0')}; other 0xFF writes {dict(collections.Counter(pc for f, pc in swf))}")
# A5 +0x169 at landed hits on the 2P legs (controls: neighbour-word reads +0x168; hits-shifted moves the hit frames 30 later)
at = collections.Counter(); rises = nearhit = nhits = 0
fld5 = "exw" if PERT == "neighbour-word" else "cht"
sh5 = 30 if PERT == "hits-shifted" else 0
per5 = {}
for k in ("03", "37", "chain", "sweep"):   # every 2P leg (rule-checker run 2026-10-08-735); 02 is reported below, not judged
    byf = {d["f"]: d for d in T[k]}
    for s in (1, 2):
        hitf = [b["f"] + sh5 for a, b in zip(T[k], T[k][1:]) if b[f"hits{s}"] > a[f"hits{s}"]]
        hitf = [f for f in hitf if f in byf]
        rf = [b["f"] for a, b in zip(T[k], T[k][1:]) if b[f"{fld5}{s}"] > a[f"{fld5}{s}"]]
        nhits += len(hitf); at.update(byf[f][f"{fld5}{s}"] for f in hitf)
        nh = sum(1 for r in rf if any(abs(r - h) <= 1 for h in hitf))
        rises += len(rf); nearhit += nh
        t = per5.setdefault(k, [0, 0, 0]); t[0] += len(hitf); t[1] += len(rf); t[2] += nh
res(nhits > 0 and set(at) <= {13, 14} and nearhit == rises, "A5", f"{'+0x168 (mode neighbour-word)' if fld5 == 'exw' else '+0x169'} at {nhits} landed hits{' (moved 30 f later)' if sh5 else ''} {dict(at)}; {nearhit}/{rises} rises within 1 f of a hit per leg (hits, rises, rises near a hit): {per5}")
# 02 (1P vs CPU) is NOT judged (rule-checker run 2026-10-08-738 asked for every leg; measured 14z-195 on ERIS: 43 landed
# hits, one reading 0, and 42/48 rises near a hit — the claim does not hold there as stated; see the WHAT). Reported per side.
byf = {d["f"]: d for d in T["02"]}
for s in (1, 2):
    hitf = [b["f"] for a, b in zip(T["02"], T["02"][1:]) if b[f"hits{s}"] > a[f"hits{s}"]]
    hitf = [f for f in hitf if f in byf]
    rf = [b["f"] for a, b in zip(T["02"], T["02"][1:]) if b[f"cht{s}"] > a[f"cht{s}"]]
    far = [r for r in rf if not any(abs(r - h) <= 1 for h in hitf)]
    odd = [(f, byf[f][f"cht{s}"]) for f in hitf if byf[f][f"cht{s}"] not in (13, 14)]
    print(f"  info  [A5] 02 P{s} ({'human' if s in HUMAN['02'] else 'CPU'}, not judged): +0x169 at {len(hitf)} landed hits "
          f"{dict(collections.Counter(byf[f][f'cht{s}'] for f in hitf))}; {len(rf) - len(far)}/{len(rf)} rises within 1 f of a hit; "
          f"hits reading neither 13 nor 14 (frame, value) {odd[:8]}; rises far from a hit (frame, value) {[(r, byf[r][f'cht{s}']) for r in far][:8]}")
sys.exit(1 if bad else 0)
PY
}
echo "== 2. the checks"
if [ -n "${VS_CTL:-}" ]; then
    check "$VS_CTL" > "$W/mode.log" 2>&1 && rc=0 || rc=1
    cat "$W/mode.log"
    tag=""
    case "$VS_CTL" in previous-press-key) tag='A1' ;; hit-vs-start|writes-shifted|chained-counted) tag='A2' ;; chained-writes-shifted) tag='A2c' ;; reads-shifted) tag='A4' ;; cpu-side) tag='A3' ;; isolated-presses) tag='A4' ;; neighbour-word|hits-shifted) tag='A5' ;; esac
    if [ "$rc" = 1 ] && grep -q "FAIL  \[$tag\]" "$W/mode.log"; then vs_ctl_fired "$VS_CTL" "the perturbed checks failed $tag (mode)"
    else echo "REFUSED: CONTROL=$VS_CTL — the perturbation did not make the check it targets fail (rc $rc): a dead mode, not a verdict"; exit 3; fi
    echo "FAIL: audit_mizuumi_attack (control mode)"; exit 1
fi
check none > "$W/checks.log" 2>&1 || fail=1
grep -v '^CTLA1 ' "$W/checks.log"
grep -q '\[A5\]' "$W/checks.log" || { echo "  FAIL  the checks did not reach A5 (a crash is not a verdict): $(tail -1 "$W/checks.log")"; exit 1; }
echo "== 3. the must-fire controls (in-gate)"
set -- $(sed -n 's/^CTLA1 //p' "$W/checks.log")
# CTLA1 <discriminating sides> <sides where the previous class did NOT lose> <non-discriminating sides,> <judged sides,>
[ "${1:-0}" -gt 0 ] && [ "${2:-1}" = 0 ] \
    && vs_ctl_fired previous-press-key "on each of the $1 sides whose paired presses hold a kick and a punch ($4), the previous press's class loses (not judged, one class or no press: $3)" \
    || { vs_ctl_dead previous-press-key "discriminating sides ${1:-0}, of them not losing ${2:-?}" || true; fail=1; }
for c in hit-vs-start:A2 writes-shifted:A2 chained-counted:A2 chained-writes-shifted:A2c reads-shifted:A4 cpu-side:A3 isolated-presses:A4 neighbour-word:A5 hits-shifted:A5; do
    name="${c%%:*}"; tag="${c#*:}"
    check "$name" > "$W/ctl_$name.log" 2>&1 && rc=0 || rc=1
    if [ "$rc" = 1 ] && grep -q "FAIL  \[$tag\]" "$W/ctl_$name.log"; then
        vs_ctl_fired "$name" "$(grep "FAIL  \[$tag\]" "$W/ctl_$name.log" | head -1 | sed 's/^ *//' | cut -c1-150)"
    else
        vs_ctl_dead "$name" "the perturbed run did not fail $tag (rc $rc): $(tail -1 "$W/ctl_$name.log" | cut -c1-120)" || true; fail=1
    fi
done
if [ "$fail" = 0 ]; then echo "PASS: audit_mizuumi_attack"; else echo "FAIL: audit_mizuumi_attack"; exit 1; fi
