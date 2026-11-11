#!/bin/sh
# audit_bishamon_charge_316.sh — BISHAMON'S [CHARGE]6+K ON PRISTINE VSAVJ: +0x316 COUNTS THE LOGIC PASSES BACK (OR
# DOWN-BACK) IS HELD, AND ITS VALUE WHEN 6+K COMPLETES PICKS THE IAI GIRI LOW'S LEVEL (0 BELOW 70, 1 BELOW 110, ELSE 2)
# (measured 14z-215, GitHub #118 batch B7; the maintainer read the capture sheets (b7_K48/K49, b7_levels_DL): "yes", "they are the 3 levels indeed")
#
# WHAT: on pristine vsavj, P1 Bishamon holding back (4) or down-back (1) makes +0x316 (byte +6 of the motion tracker at
#   +0x310) count up by exactly the number of logic passes run in each frame (1, or 2 on a double-pass frame; the pass
#   counter RAM:$FF8081), from 1 on the first held frame; the tracker at +0x308 counts identically on the same frames
#   (+0x30E = +0x316). The writers in the match are PRG:0x02A302 (a 0), 0x02A332 and 0x02A35C (each the previous value + 1),
#   the charge kind 0x02A2EA. Releasing into 6 then pressing LK: with fewer than 60 passes held (36, 59 measured) no read,
#   no command (+0x106 stays 0), a normal attack, and +0x316 back to 0; with 60 or more, PRG:0x04185A reads +0x316 once,
#   +0x106 := 4 and +0x0A := 0 / 1 / 2 by the read value (< 70, < 110, >= 110): held 49 / 56 / 57 / 88 / 89 / 120 frames read
#   61 / 69 / 71 / 109 / 110 / 148 and give 0 / 0 / 1 / 1 / 2 / 2 (frozen). The same hold released into 6+LP is read through
#   +0x30E instead (PRG:0x04183A, +0x106 := 2) and never through 0x04185A. Down-back held 90 frames reads 111 at 0x04185A,
#   level 2. Holding down (2) or forward (6), or idle: +0x316 never non-zero. P1 Lilith holding back then 6+LK: her +0x316
#   never written non-zero. P2's +0x316 never non-zero on any leg.
# HOW: on MAME (the reference binary), tests/replays/df/105_df_sas_armor.rpl's prologue (the pair by poke: P1 $FF8782 =
#   0x08 Bishamon or 0x0E Lilith, P2 $FF8B82 = 0x03 Victor, both human; P2 idle), derived in-gate into hold scripts: the
#   direction held f3150 to f3150+N-1, then 6 at f3150+N for 4 f and the button from f3150+N+1 for 3 f. Per script a FIELD
#   leg (tests/lua/field_trace.lua: +0x06, +0x0A, +0x106, the two trackers' +0x30E/+0x316/+0x314, $FF8081, P2's +0x316) and a
#   TAP leg (tests/lua/read_tap.lua over P1's +0x308..+0x317 and P2's +0x310..+0x317 words, reads logged only at PCs
#   0x04185A/0x04183A, f3000-3400). A tap event in tap frame f lands in trace frame f+1. Never more than three MAME legs at once.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row, each loaded zip's sha1 — or the gate FAILs before any leg; and it names
#   the MAME (tests/lib/mame_ident.sh), or the gate FAILs. Every leg complete and every tap live. H1-H9 as stated in WHAT.
#   CONTROLS (in-gate, each must make its check fail): thresholds-shifted, p2-side, pass-blind, tracker-swapped,
#   lilith-as-bishamon, short-as-long. The log's header names the commit and host.
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lib/mame_ident.sh tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/read_tap.lua
#   tests/replays/df/105_df_sas_armor.rpl tools/run_mame.sh tools/setup_mame.sh tools/audit_roms.py docs/checksums.txt
#   tools/build_fingerprint.py tests/expected/registry.tsv
#
# SHEET: none — measures pristine vsavj and/or native vsav2 only; no leg of our build
#
# MUST-FIRE: perturbed-copy: thresholds-shifted — H1 predicting the level with thresholds 72/111 instead of 70/110 must fail, so the 71 -> 1 and 110 -> 2 boundaries are measured (in-gate; as a mode H1 uses 72/111 and the gate FAILs)
# MUST-FIRE: perturbed-copy: p2-side — H1 judged on P2's tracker must fail, so the tap sees which side is which (in-gate; as a mode H1 judges P2 and the gate FAILs)
# MUST-FIRE: perturbed-copy: pass-blind — H3 expecting +0x316 to rise by one per video frame must fail, so it counts logic passes and the hold holds a double-pass frame (in-gate; as a mode H3 expects 1 per frame and the gate FAILs)
# MUST-FIRE: perturbed-copy: tracker-swapped — H1 expecting the K command's read at 0x04183A (the P command's +0x30E reader) must fail, so the K command reads +0x316 (in-gate; as a mode H1 uses 0x04183A and the gate FAILs)
# MUST-FIRE: known-bad: lilith-as-bishamon — H8 judged on Bishamon's 120-frame hold must fail, so H8 can see a +0x316 count (in-gate; as a mode H8 judges K120 and the gate FAILs)
# MUST-FIRE: known-bad: short-as-long — H2 judged on the 49-frame hold (which completes) must fail, so H2 tells a completed charge from a short one (in-gate; as a mode H2 judges K49 and the gate FAILs)
#
# NOT COVERED: Oboro Bishamon (id 0x18, the other +0x316 reader at PRG:0x053662, S0 static) is not played; jumping, being
#   hit or blocking while charging is not played; the exact count at 60 and at 70 is never landed on (59 -> none, 61 -> level
#   0; 69 -> 0, 71 -> 1: the boundaries are S0's static 0x46/0x6E compares and the 60-pass minimum is the tracker's +0x314
#   reaching 0); the level's effect is shown on the sheets (1 / 2 / 3 hits on Victor in the down-back legs), not judged here;
#   only play level 6 (vsavj NORMAL, the default) is run, so a duration in video frames is level-dependent and not judged;
#   the community's charge times for the three levels (45 / 52 / 82 frames) stand to the 60 / 70 / 110 passes here at a
#   near-constant ratio (1.33 / 1.35 / 1.34) — the maintainer, 14z-215: "you have your measurement for internal purposes and
#   the explanation difference for the community" — and are not judged here.
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] audit_bishamon_charge_316.sh
#   emulator tier, MAME; ~2 min (28 legs, three at a time); scope ondemand (the pristine-only ruling)
# SHARES: self
set -u
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"; SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$SELF"; MODE="${VS_CTL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no reference MAME binary at $MAME_BIN"; exit 0; }
romchk="$(python3 "$REPO/tools/audit_roms.py" "$ROMDIR" 2>&1)" || true
echo "$romchk" | grep >/dev/null 'all match' || { echo "FAIL: ROMDIR is not the pristine reference set (tools/audit_roms.py against docs/checksums.txt):"; echo "$romchk" | tail -5; exit 1; }
romfp="$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR" --set vsavj --sha-only 2>/dev/null)" || true
regfp="$(awk -F'\t' '$2 == "vsavj" && $1 !~ /^#/ {print $1}' "$REPO/tests/expected/registry.tsv")"
[ -n "$romfp" ] && [ "$romfp" = "$regfp" ] || { echo "FAIL: vsavj program fingerprint '$romfp' is not the registry's vsavj row '$regfp'"; exit 1; }
echo "  rom   $(echo "$romchk" | grep 'all match' | head -1); vsavj program fingerprint $romfp = registry vsavj row; zips $(python3 -c 'import hashlib,sys; print(" ".join(f"{z}.zip=" + hashlib.sha1(open(f"{sys.argv[1]}/{z}.zip","rb").read()).hexdigest() for z in ("vsavj","vsav","qsound_hle")))' "$ROMDIR")"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else
    W="$(mktemp -d)" || { echo "FAIL: audit_bishamon_charge_316 — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }

# THE SCRIPTS, derived from replay 105's prologue (everything before its "# activate" line).
RPL="$REPO/tests/replays/df/105_df_sas_armor.rpl"
awk '/^# activate/ {exit} {print}' "$RPL" | grep -v '^#' > "$W/prologue"
grep -q '^1360-1362 p2=1$' "$W/prologue" || { echo "FAIL: replay 105's prologue is not the one this gate was measured on"; exit 1; }
hold() {  # hold <name> <direction> <frames held> <button>
    r=$((3150 + $3))
    { cat "$W/prologue"; echo "3150-$((r - 1)) p1=$2"; echo "$r-$((r + 3)) p1=R"; echo "$((r + 1))-$((r + 3)) p1=$4"; echo "3400 wait"; } > "$W/$1.rpl"
}
for n in 30 48 49 56 57 88 89 120; do hold "K$n" L "$n" 4; done
hold P90 L 90 1; hold DL90 DL 90 4; hold D90 D 90 4; hold R90 R 90 4; hold LIL90 L 90 4
{ cat "$W/prologue"; echo "3400 wait"; } > "$W/idle.rpl"
PKB="1400:ff8782:08;1450:ff8782:08;1500:ff8782:08;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
PKL="1400:ff8782:0e;1450:ff8782:0e;1500:ff8782:0e;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
FIELDS="ff8406:b:seq,ff840a:b:lvl,ff8506:b:c106,ff870e:w:t30e,ff8716:w:t316,ff8714:b:t314,ff8081:b:pass,ff8b16:w:p2t316"
field() {  # field <name> <pokes>
    d="$W/$1.f"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/$1.rpl" POKES="$2" FIELDS="$FIELDS" \
        FIELD_OUT="$W/$1.fields" FIELD_FROM=3000 FIELD_TO=3400 FRAMES=3410 timeout -k 10 600 "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
tap() {  # tap <name> <pokes>
    d="$W/$1.t"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/$1.rpl" POKES="$2" RTAP="ff8708,16;ff8b10,8" \
        RPCS="4185a,4183a" WINDOW="3000,3400" TRACE_OUT="$W/$1.tap" FRAMES=3410 timeout -k 10 600 "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
LEGS="K30 K48 K49 K56 K57 K88 K89 K120 P90 DL90 D90 R90 idle LIL90"
echo "== 1. the legs (pristine vsavj, MAME, three at a time)"
for l in $LEGS; do
    pk="$PKB"; [ "$l" = LIL90 ] && pk="$PKL"
    while [ "$(jobs -p | wc -l)" -gt 1 ]; do wait "$(jobs -p | head -1)"; done   # at most three MAME legs at once (one left + the two below)
    field "$l" "$pk" & tap "$l" "$pk" &
done
wait
fail=0
for l in $LEGS; do
    grep -q '^FIELDSUMMARY' "$W/$l.fields" 2>/dev/null || { echo "  FAIL  $l: no FIELDSUMMARY (see $W/$l.f/mame.log) — VOID"; fail=1; }
    grep -q '^END ' "$W/$l.tap" 2>/dev/null || { echo "  FAIL  $l: no tap END line (see $W/$l.t/mame.log) — VOID"; fail=1; }
done
[ "$fail" = 0 ] || { echo "FAIL: audit_bishamon_charge_316 (a leg did not complete)"; exit 1; }
echo "  ok    28 legs complete"

echo "== 2. the checks"
python3 - "$W" "$MODE" $LEGS > "$W/main.log" <<'PY'
import sys
W, mode, legs = sys.argv[1], sys.argv[2], sys.argv[3:]
def fields(n):
    out = {}
    for l in open(f"{W}/{n}.fields"):
        if l.startswith("F "):
            p = l.split(); out[int(p[1])] = {k: int(v) for k, v in (x.split("=") for x in p[2:])}
    return out
def events(n, kind):
    e = []
    for l in open(f"{W}/{n}.tap"):
        p = l.split()
        if p and p[0] == kind:   # W|R <frame> PC <pc> off <addr> data <val> mask <m>
            e.append((int(p[1]), int(p[3], 16), int(p[5], 16), int(p[7], 16), int(p[9], 16)))
    return e
F = {n: fields(n) for n in legs}; TW = {n: events(n, "W") for n in legs}; TR = {n: events(n, "R") for n in legs}
bad = []
def say(ok, msg):
    print(("  ok    " if ok else "  FAIL  ") + msg)
    if not ok: bad.append(msg)
for n in legs:
    say(any(f < 1000 for f, *_ in TW[n]), f"tap {n}: live ({sum(1 for f, *_ in TW[n] if f < 1000)} writes before f1000)")
held = lambda n: int("".join(c for c in n if c.isdigit()))
rel = lambda n: 3150 + held(n)
WANT = {"K49": (61, 0), "K56": (69, 0), "K57": (71, 1), "K88": (109, 1), "K89": (110, 2), "K120": (148, 2)}   # measured 14z-215
def level(v, lo=70, hi=110): return 0 if v < lo else 1 if v < hi else 2
def h1(leg, addr=0xFF8716, pc=0x04185A, lo=70, hi=110):
    """H1: one in-match read of the tracker word at pc; the next trace frame has +0x106 = 4 and +0x0A = level(value)."""
    rd = [(f, d & 0xFFFF) for f, p, a, d, m in TR[leg] if p == pc and a == addr]
    if len(rd) != 1: return False, f"{len(rd)} reads at {pc:#08x}", None
    f, v = rd[0]; nx = F[leg].get(f + 1, {})
    ok = nx.get("c106") == 4 and nx.get("lvl") == level(v, lo, hi) and v == max(F[leg][g]["t316"] for g in F[leg] if g <= f)
    return ok, f"read {v} at tap f{f}; f{f + 1}: +0x106={nx.get('c106')} +0x0A={nx.get('lvl')} (predicted {level(v, lo, hi)})", (v, nx.get("lvl"))
lo, hi, addr, pc = 70, 110, 0xFF8716, 0x04185A
if mode == "thresholds-shifted": lo, hi = 72, 111
if mode == "p2-side": addr = 0xFF8B16
if mode == "tracker-swapped": pc = 0x04183A
got = {}
for leg in WANT:
    ok, why, g = h1(leg, addr, pc, lo, hi); got[leg] = g
    say(ok, f"H1 {leg}: {why}")
say(got == WANT, f"H1 frozen (read, level) per hold: {got} (frozen {WANT})")
def h2(leg):
    """H2: a short hold: no read at 0x04185A, +0x106 never 4, and +0x316 back to 0 the frame the release is seen."""
    fl, r = F[leg], rel(leg)
    rd = [x for x in TR[leg] if x[1] == 0x04185A]
    mx = max(fl[f]["t316"] for f in fl if f < r)
    return not rd and all(v["c106"] != 4 for v in fl.values()) and all(fl[f]["t316"] == 0 for f in range(r + 1, r + 20)), mx
for leg, want in (("K30", 36), ("K48", 59)):
    ok, mx = h2("K49" if mode == "short-as-long" and leg == "K48" else leg)
    say(ok and (mx == want or mode == "short-as-long"), f"H2 {leg}: peak +0x316 {mx} (frozen {want}), no 0x04185A read, +0x106 never 4, +0x316 0 after the release")
def h3(leg, per_frame=False):
    """H3: on every held frame after the first, the rise of +0x316 equals the logic passes run ($FF8081's rise)."""
    fl, r = F[leg], rel(leg)
    pairs = [(fl[f]["t316"] - fl[f - 1]["t316"], (fl[f]["pass"] - fl[f - 1]["pass"]) & 0xFF) for f in range(3151, r)]
    dbl = sum(1 for _, p in pairs if p == 2)
    ok = fl[3150]["t316"] == 1 and all(dt == (1 if per_frame else dp) for dt, dp in pairs) and dbl > 0
    return ok, len(pairs), dbl
ok, nf, dbl = h3("K120", mode == "pass-blind")
say(ok, f"H3 K120: +0x316 1 on the first held frame, then rises by the passes run on each of {nf} held frames ({dbl} double-pass)")
okd, nfd, dbld = h3("DL90")
say(okd, f"H3 DL90: the same on down-back ({nfd} frames, {dbld} double-pass)")
def h4(leg):
    """H4: every in-match write to P1's +0x316 is a 0 from 0x02A302 or previous+1 from 0x02A332/0x02A35C."""
    prev, odd = 0, []
    for f, p, a, d, m in TW[leg]:
        if f < 3000 or a != 0xFF8716: continue
        v = d & 0xFFFF
        if p == 0x02A302 and v == 0: prev = 0
        elif p in (0x02A332, 0x02A35C) and v == prev + 1: prev = v
        else: odd.append((f, hex(p), v))
    return not odd, odd
for leg in ("K49", "K89", "K120", "DL90", "P90"):
    ok, odd = h4(leg); say(ok, f"H4 {leg}: in-match writers of +0x316 only 0x02A302 (0) and 0x02A332/0x02A35C (+1); others {odd[:3]}")
pf, r = F["P90"], rel("P90")
rdp = [(f, d & 0xFFFF) for f, p, a, d, m in TR["P90"] if p == 0x04183A and a == 0xFF870E]
same = all(pf[f]["t30e"] == pf[f]["t316"] for f in range(3150, r))
nok = not [x for x in TR["P90"] if x[1] == 0x04185A]
okp = len(rdp) == 1 and pf[rdp[0][0] + 1]["c106"] == 2 and pf[rdp[0][0] + 1]["lvl"] == level(rdp[0][1]) and rdp[0][1] == 111
say(okp and same and nok, f"H5 P90: 6+LP reads +0x30E at 0x04183A {rdp} (frozen 111), then +0x106={pf[rdp[0][0] + 1]['c106'] if rdp else None} "
    f"+0x0A={pf[rdp[0][0] + 1]['lvl'] if rdp else None}; +0x30E = +0x316 on every held frame: {same}; no 0x04185A read: {nok}")
if mode in ("p2-side", "tracker-swapped"):   # #369: the modes' finding is an ABSENCE of reads, so the tap's R events must be shown live
    _p1 = all(any(x[1] == 0x04185A and x[2] == 0xFF8716 for x in TR[l]) for l in WANT)
    if not (_p1 and len(rdp) == 1):
        print(f"  BLIND  the tap's read events are not shown live (P1 reads at 0x04185a on every K leg: {_p1}; P90's read at 0x04183a: {len(rdp)})")
ok, why, g = h1("DL90")
say(ok and g == (111, 2), f"H6 DL90: down-back charges +0x316 too: {why} (frozen (111, 2))")
for leg in ("D90", "R90", "idle"):
    say(all(v["t316"] == 0 for v in F[leg].values()) and not [x for x in TR[leg] if x[1] == 0x04185A],
        f"H7 {leg}: +0x316 never non-zero, no 0x04185A read")
def h8(leg):
    w = [(f, hex(p), d & 0xFFFF) for f, p, a, d, m in TW[leg] if f >= 3000 and a == 0xFF8716 and d & 0xFFFF]
    return not w and all(v["t316"] == 0 for v in F[leg].values()), w
ok, w = h8("K120" if mode == "lilith-as-bishamon" else "LIL90")
say(ok, f"H8 Lilith held back 90 f then 6+LK: non-zero in-match writes to her +0x316 {w[:3]}, field always 0")
p2 = [(n, f) for n in legs for f, v in F[n].items() if v["p2t316"]] + [(n, x[0]) for n in legs for x in TW[n] if x[0] >= 3000 and x[2] == 0xFF8B16 and x[3] & 0xFFFF]
say(not p2, f"H9 P2's +0x316: {len(p2)} non-zero frames/writes over {len(legs)} legs")
if not mode:
    for name, res in (("thresholds-shifted", all(h1(l, 0xFF8716, 0x04185A, 72, 111)[0] for l in WANT)),
                      ("p2-side", all(h1(l, 0xFF8B16)[0] for l in WANT)),
                      ("pass-blind", h3("K120", True)[0]),
                      ("tracker-swapped", all(h1(l, 0xFF8716, 0x04183A)[0] for l in WANT)),
                      ("lilith-as-bishamon", h8("K120")[0]),
                      ("short-as-long", h2("K49")[0])):
        print(f"CONTROL DEAD: {name} — the perturbed check still passed" if res else
              f"CONTROL FIRED: {name} — the perturbed check fails")
        if res: bad.append(name)
sys.exit(1 if bad else 0)
PY
rc=$?
cat "$W/main.log"
if [ "$rc" != 0 ]; then
    # #369: a mode is honoured only on its own check's finding in the main check's output
    case "$MODE" in
    thresholds-shifted) WANT='^  FAIL  H1 K(57|89): read (71|110) at tap f[0-9]+; f[0-9]+: \+0x106=4 \+0x0A=(1|2) \(predicted (0|1)\)$' ;;
    p2-side) WANT='^  FAIL  H1 K[0-9]+: 0 reads at 0x04185a$' ;;
    pass-blind) WANT='^  FAIL  H3 K120: ' ;;
    tracker-swapped) WANT='^  FAIL  H1 K[0-9]+: 0 reads at 0x04183a$' ;;
    lilith-as-bishamon) WANT='^  FAIL  H8 Lilith held back ' ;;
    short-as-long) WANT='^  FAIL  H2 K48: ' ;;
    *) WANT='' ;;
    esac
    if grep -q '^  BLIND  ' "$W/main.log"; then vs_ctl_nj "the tap logged no read where one is measured (P1's 0x04185A reads, P90's 0x04183A read): its zero reads judged nothing"
    else [ -z "$MODE" ] || vs_ctl_caught "$W/main.log" "$WANT" || :; fi
    echo "FAIL: audit_bishamon_charge_316"; exit 1
fi
echo "PASS: audit_bishamon_charge_316 — +0x316 counts the logic passes back/down-back is held; at 6+LK it is read once and picks the level (<70, <110, else)"
