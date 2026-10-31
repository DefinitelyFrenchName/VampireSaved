#!/bin/sh
# audit_anakaris_rows.sh — FIVE MIZUUMI PLAYER-STRUCT CANDIDATES ON ANAKARIS, MEASURED ON PRISTINE VSAVJ: +0x152 IS HIS
# HOVER TIMER, +0x156 AND +0x1A0 THE VICTIM'S CURSE TIMER AND FLAG, +0x1AA THE LOSER'S FLAG THAT PICKS HIS WIN POSE, +0x374
# THE X OF HIS MUMMY DROP HANDS (measured 14z-215, GitHub #118 batch B1; the maintainer read the capture sheets: the doll,
# the coffins and the Mummy Drop "yes", the float's second press "in that case yes")
#
# WHAT: on pristine vsavj, P1 Anakaris (0x06) against an idle P2 Victor (0x03):
#   +0x152 (P1, byte): an up press from the ground writes 0x77 at PRG:0x0267D8 within a frame of the press (three presses:
#   a 2-frame tap, a 30-frame hold, a tap), and an up press while hovering writes 0x77 again at PRG:0x026850 (+0x151
#   1 -> 0: Up from the ground hovers 8 px up, Y 40 -> 48; Up again while hovering rises to 57 px, Y 97, and restarts the
#   120-tick timer); each 0x77 is followed by exactly 120 decrements (0x02683C after a press from the ground, 0x02692C
#   after the press while hovering) to 0xFF, then the descent; no other in-match write; a diagonal jump (UR,
#   UL) and a walk never write it; P2's +0x152 is never written in the match.
#   +0x1A0 / +0x156 (P2, the victim): a Royal Judgement hit (P2 +0x54 = 0x18) writes +0x1A0 := 1 at PRG:0x023E6A; with P2
#   standing, PRG:0x025FA8 then writes +0x156 := 0x10 / 0x70 / 0xC0 / 0x110 for +0x56 = 0 / 1 / 2 / 3 (LP / MP / HP /
#   ES), with P2 in the air PRG:0x0247DC writes 0x3C / 0x9C / 0xEC (LP / MP / HP) — rising with +0x56 on both paths; each
#   set is counted down by 1 per write (PRG:0x026274 standing, PRG:0x025478 airborne) to 0, +0x1A0 reads 1 on every frame
#   +0x156 is non-zero, and PRG:0x026742 clears +0x1A0 after it reaches 0; a whiffed cloud writes neither; P1's are never
#   written in the match.
#   +0x1AA (P2, the loser): Pharaoh Magic's fourth hit (P2 +0x54 = 0x1C after 0x19, 0x1A, 0x1B) runs PRG:0x023F1A, which
#   clears it, and PRG:0x023F24 sets it to 1 in the same frame only when P2's HP is negative (the KO leg; the no-KO leg
#   only clears); a coffin KO (+0x54 0x37) never runs either; at the win, P1's +0x18D is written 4 when P2's +0x1AA is 1
#   and otherwise not 4 — the causal pair: the Pharaoh Magic KO with +0x1AA poked back to 0 gives 8, the coffin KO 6 and,
#   with +0x1AA poked to 1, 4.
#   +0x374 (P1, long): each Mummy Drop's first in-match write is a long from PRG:0x03BFEE whose high word is P1's X plus
#   96 / 152 / 208 / 72 (LP / MP / HP / ES); the hand objects at RAM:$FFB800 and $FFB880 carry that word at their +0x10
#   on every frame both are live; the MP drop catches P2 (0x03C1A8 pulls the X back, P2's X = the high word + 48 on every
#   pulled frame) and the ES drop advances (0x03C34C) and catches (0x03C396); LP and HP catch nothing; the five coffins
#   never write it (two hit P2, +0x54 0x37); 4123KK writes it once, as a word, at PRG:0x03C760; P2's never in match.
#   R1: the five fields poked at f4500 read back at f4500 and not at f4499. Only this behaviour is claimed: the community
#   names are adopted, if at all, as "consistent with"; the pose and the doll themselves are judged on captures.
# HOW: on MAME (the reference binary), nineteen scripts made in-gate by the gate's own generator (below) from replay
#   105's prologue (P1/P2 by poke, P1 stocks 3 at f3100/3120); for each a FIELD leg (tests/lua/field_trace.lua, both
#   sides' +0x06/+0x07/+0x10/+0x14/+0x38/+0x50/+0x54/+0x56/+0x151-+0x153/+0x156/+0x1A0/+0x1AA/+0x374, P1's +0x18D and
#   +0x3B6, the hand objects' +0x10) and, but for readback, a WRITE-TAP leg (tests/lua/read_tap.lua over both sides'
#   words +0x152, +0x156, +0x1A0, +0x1AA, +0x374, +0x376, +0x54 and P1's +0x18C). At most three MAME at once. A tap
#   write in tap frame f lands in trace frame f+1.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row, each loaded zip's sha1 — or the gate FAILs before any leg; and it
#   names the MAME (tests/lib/mame_ident.sh), or the gate FAILs. Every leg complete and every tap live. F1-F4, C1-C5,
#   W1-W4, M1-M7 and R1 as stated in WHAT. CONTROLS (in-gate, each must make its check fail): float-on-diagonal (F1 judged
#   with the expected presses moved to the UR/UL presses), strength-swapped (C1 with the LP and HP legs swapped),
#   p1-side (C1 judged on P1's block), air-as-ground (C2 expecting the standing PC 0x025FA8), hand-offset (M2 with the
#   hands' X compared with the high word + 1), ctl-as-pm (W2 judged on the coffin KO), unpoked-set (W4's cof_set
#   expectation judged on cof_kill) and readback-unpoked (R1 judged on the float leg).
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lib/mame_ident.sh tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/read_tap.lua
#   tests/replays/df/105_df_sas_armor.rpl tools/run_mame.sh tools/setup_mame.sh tools/audit_roms.py docs/checksums.txt
#   tools/build_fingerprint.py tests/expected/registry.tsv
#
# SHEET: none — measures pristine vsavj and/or native vsav2 only; no leg of our build
#
# MUST-FIRE: perturbed-copy: float-on-diagonal — F1 judged with its presses moved to the UR and UL presses must fail, so the 0x77 writes are tied to the up presses, not to any jump (in-gate; as a mode F1 uses the diagonal presses and the gate FAILs)
# MUST-FIRE: perturbed-copy: strength-swapped — C1 with the LP and HP legs' values swapped must fail, so it tells the strengths apart (in-gate; as a mode C1 swaps them and the gate FAILs)
# MUST-FIRE: perturbed-copy: p1-side — C1 judged on P1's +0x1A0/+0x156 must fail, so the trace and tap see which side is the victim (in-gate; as a mode C1 judges P1 and the gate FAILs)
# MUST-FIRE: perturbed-copy: air-as-ground — C2 expecting the standing writer PRG:0x025FA8 must fail, so the airborne path is measured, not assumed (in-gate; as a mode C2 expects it and the gate FAILs)
# MUST-FIRE: perturbed-copy: hand-offset — M2 comparing the hand objects' X with +0x374's high word + 1 must fail, so the equality is exact (in-gate; as a mode M2 adds 1 and the gate FAILs)
# MUST-FIRE: known-bad: ctl-as-pm — W2 judged on the coffin KO (no 0x1C reaction) must fail, so the set comes from Pharaoh Magic's reaction (in-gate; as a mode W2 judges cof_kill and the gate FAILs)
# MUST-FIRE: known-bad: unpoked-set — W4's "+0x18D := 4 after +0x1AA poked to 1" judged on the unpoked coffin KO must fail, so the 4 comes from the poke (in-gate; as a mode W4 judges cof_kill and the gate FAILs)
# MUST-FIRE: known-bad: readback-unpoked — R1 judged on the float leg, never poked, must fail, so R1's values come from the pokes at the fields' addresses (in-gate; as a mode R1 judges float and the gate FAILs)
#
# NOT COVERED: the doll, the hover's heights and the win pose are judged by the maintainer on captures, not here (the
#   pose's sound id 0x034B is not named: "I can't say so let's not adpot the name"); a third Up while hovering (the
#   maintainer's "once; further presses do nothing", seen on a scratch run) is not played here; the
#   hover's re-arm after a rise (0x0269A2) is never reached; the second curse setter's table is read only at +0x56 0-3
#   and the airborne one at 0-2 (no airborne ES leg); the clear pair 0x0254DC/0x0254E0 is never reached; the Anakaris
#   +0x374 byte counter (0x03CF42 / 0x03D144 / cmpi #7 at 0x03D204) is never reached by any leg here; what decides
#   +0x18D when +0x1AA is 0 (8 after Pharaoh Magic, 6 after the coffin) is not traced; the object 0x0100191E path
#   (0x03E4AC) is not judged; P2 is Victor only.
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] tests/audit_anakaris_rows.sh
#   emulator tier, MAME; ~3 min (37 legs, three at a time); scope ondemand (the pristine-only ruling)
set -u
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$HERE/$(basename "$0")"; MODE="${VS_CTL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no reference MAME binary at $MAME_BIN"; exit 0; }
romchk="$(python3 "$REPO/tools/audit_roms.py" "$ROMDIR" 2>&1)" || true
echo "$romchk" | grep >/dev/null 'all match' || { echo "FAIL: ROMDIR is not the pristine reference set (tools/audit_roms.py against docs/checksums.txt):"; echo "$romchk" | tail -5; exit 1; }
romfp="$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR" --set vsavj --sha-only 2>/dev/null)" || true
regfp="$(awk -F'\t' '$2 == "vsavj" && $1 !~ /^#/ {print $1}' "$REPO/tests/expected/registry.tsv")"
[ -n "$romfp" ] && [ "$romfp" = "$regfp" ] || { echo "FAIL: vsavj program fingerprint '$romfp' is not the registry's vsavj row '$regfp'"; exit 1; }
echo "  rom   $(echo "$romchk" | grep 'all match' | head -1); vsavj program fingerprint $romfp = registry vsavj row; zips $(python3 -c 'import hashlib,sys; print(" ".join(f"{z}.zip=" + hashlib.sha1(open(f"{sys.argv[1]}/{z}.zip","rb").read()).hexdigest() for z in ("vsavj","vsav","qsound_hle")))' "$ROMDIR")"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else
    W="$(mktemp -d)" || { echo "FAIL: audit_anakaris_rows — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }

rm -rf "$W/rpl"; mkdir -p "$W/rpl"
cat > "$W/mk_rpl.py" <<'PY'
#!/usr/bin/env python3
"""the generator (audit_anakaris_rows.sh, 14z-215, #118 B1): <replay 105> <out dir> — the Anakaris rig's replays and per-leg pokes.

Every replay is replay 105's select prologue (tests/replays/df/105_df_sas_armor.rpl, every line before f2000: the
four system taps, the two cursor moves and the two confirms); the pair is forced by poke (P1 +0x382 = 0x06 Anakaris,
P2 +0x382 = 0x03 Victor, at f1400/1450/1500, the B6 template's way) and P1's stocks are poked to 3 at f3100/3120 on
every leg (the ES/EX legs need them; the others carry them so every leg has the same state). P2 is human and idle
except where a line says p2=. Directions are for P1 on the left facing right (R = toward).
Writes <name>.rpl and, for a leg with extra pokes, <name>.pokes (the POKES grammar, ';'-separated).
"""
import os
import sys

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
pro = [l.rstrip("\n") for l in open(src) if l.strip() and not l.startswith("#") and int(l.split()[0].split("-")[0]) < 2000]
assert len(pro) == 8, pro


def seq(f, toks, who="p1", step=3):
    """one token per `step` frames from f, held for the whole step"""
    return [f"{f + i * step}-{f + i * step + step - 1} {who}={t}" for i, t in enumerate(toks)]


def m236(f, b):
    return seq(f, ["D", "DR", "R", b])


def m22(f, b):   # D, a 3-frame gap, D, D+button (the cadence that fired the coffins in exploration x1)
    return [f"{f}-{f + 2} p1=D", f"{f + 6}-{f + 8} p1=D", f"{f + 9}-{f + 11} p1=D{b}"]


PM = seq(3500, ["5", "1", "D", "4", "2"], step=4)   # Pharaoh Magic, community MK,LP,2,LK,MP
L = {}
# (a) float: U tap; U held 30 f; U then U again while floating (the rise); UR; UL; a walk
L["float"] = (["3000-3001 p1=U", "3300-3329 p1=U", "3600-3601 p1=U", "3630-3631 p1=U", "3900-3901 p1=UR",
               "4200-4201 p1=UL", "4400-4460 p1=R"], "")
# (b) curse: Royal Judgement (community J.236LP) from the float, P2 standing: LP, MP, HP; the ES with stock
L["rjg"] = (["3000-3001 p1=U"] + m236(3010, "1") + ["3400-3401 p1=U"] + m236(3410, "2") +
            ["3800-3801 p1=U"] + m236(3810, "3"), "")
L["rjes"] = (["3200-3201 p1=U"] + m236(3210, "12"), "")
#     P2 jumps straight up 25 f after the float so the cloud meets him in the air; one leg per strength
for b, s in (("1", "lp"), ("2", "mp"), ("3", "hp")):
    L["rjair_" + s] = (["3000-3001 p1=U"] + m236(3010, b) + ["3025-3026 p2=U"], "")
#     the whiff control: P2 jumps 45 f after, and the cloud passes under him
L["rjwhiff"] = (["3000-3001 p1=U"] + m236(3010, "1") + ["3045-3046 p2=U"], "")
# (c) Mummy Drop (community 236P, the strength sets the distance): LP, MP, HP, ES
for b, s in (("1", "lp"), ("2", "mp"), ("3", "hp"), ("12", "es")):
    L["md_" + s] = (m236(3200, b), "")
# (d) coffins (community 22P/22K): 22LP, 22MP, 22HP, 22LK, then the ES 22PP with stock
L["coffin"] = (m22(3000, "1") + m22(3300, "2") + m22(3600, "3") + m22(3900, "4") + m22(4200, "12"), "")
#     4123KK (community: The Pit to the Underworld, EX), the other move whose code names +0x374
L["pit"] = (seq(3200, ["L", "DL", "D", "DR", "45"]), "")
# (e) win: Pharaoh Magic without a KO; with P2's HP poked to 1 before its fourth hit (the KO);
#     the same KO with P2's +0x1AA poked back to 0 before the win; a coffin (22MP) KO; the coffin KO with +0x1AA poked to 1
HPK = "3770:ff8850:00010001"
L["pm"] = (PM, "")
L["pm_kill"] = (PM, HPK)
L["pm_clr"] = (PM, HPK + ";3800:ff89aa:00")
L["cof_kill"] = (m22(3300, "2"), "3330:ff8850:00010001")
L["cof_set"] = (m22(3300, "2"), "3330:ff8850:00010001;3400:ff89aa:01")
# R1: the float leg with the five fields poked at f4500 (P1 +0x152, P2 +0x156, P2 +0x1A0, P2 +0x1AA, P1 +0x374)
L["readback"] = (L["float"][0], "4500:ff8552:5a;4500:ff8956:005a;4500:ff89a0:5a;4500:ff89aa:5a;4500:ff8774:5a5a5a5a")
for name, (lines, pokes) in L.items():
    with open(os.path.join(out, name + ".rpl"), "w") as f:
        f.write(f"# #118 B1 {name} (audit_anakaris_rows.sh, 14z-215): replay 105's prologue, P1 Anakaris / P2 Victor by poke\n")
        f.write("\n".join(pro + sorted(lines, key=lambda l: int(l.split()[0].split("-")[0]))) + "\n4700 wait\n")
    if pokes:
        open(os.path.join(out, name + ".pokes"), "w").write(pokes + "\n")
print(" ".join(L))
PY
LEGS="$(python3 "$W/mk_rpl.py" "$REPO/tests/replays/df/105_df_sas_armor.rpl" "$W/rpl")" || { echo "FAIL: audit_anakaris_rows (the generator)"; exit 1; }
PKB="1400:ff8782:06;1450:ff8782:06;1500:ff8782:06;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3120:ff8509:03"
F="ffb810:w:hx0,ffb890:w:hx1,ff858d:b:c18d1,ff87b6:b:c3b61"
for s in 1 2; do b=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 006:b:seq 007:b:sub 010:w:x 014:w:y 038:b:air 050:w:hp 054:b:r54 056:b:r56 151:b:c151 152:b:c152 153:b:c153 156:w:c156 1a0:b:c1a0 1aa:b:c1aa 374:l:c374; do
        F="$F,$(printf '%06x' $((b + 0x${spec%%:*}))):${spec#*:}$s"; done; done
RT="ff858c,2"; for b in ff8400 ff8800; do for o in 152 156 1a0 1aa 374 376 054; do RT="$RT;$(printf '%06x' $((0x$b + 0x$o - 0x$o % 2))),2"; done; done
pokes() { if [ -f "$W/rpl/$1.pokes" ]; then echo "$PKB;$(cat "$W/rpl/$1.pokes")"; else echo "$PKB"; fi; }
field() {  # field <leg>
    d="$W/$1"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/rpl/$1.rpl" POKES="$(pokes "$1")" FIELDS="$F" \
        FIELD_OUT="$W/$1.fields" FIELD_FROM=2900 FRAMES=4700 timeout -k 30 900 "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
tap() {  # tap <leg>
    d="$W/tap$1"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/rpl/$1.rpl" POKES="$(pokes "$1")" RTAP="$RT" \
        WINDOW="0,0" TRACE_OUT="$W/$1.tap" FRAMES=4700 timeout -k 30 900 "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
echo "== 1. the legs (pristine vsavj, MAME; three at a time)"
pids=""; n=0
launch() { "$@" & pids="$pids $!"; n=$((n + 1)); if [ "$n" -ge 3 ]; then for p in $pids; do wait "$p"; done; pids=""; n=0; fi; }
for l in $LEGS; do
    rm -rf "$W/$l" "$W/tap$l" "$W/$l.fields" "$W/$l.tap"
    launch field "$l"
    [ "$l" = readback ] || launch tap "$l"
done
for p in $pids; do wait "$p"; done
fail=0; nl=0
for l in $LEGS; do
    grep -q '^FIELDSUMMARY' "$W/$l.fields" 2>/dev/null || { echo "  FAIL  $l: no FIELDSUMMARY (see $W/$l/mame.log) — VOID"; fail=1; }
    nl=$((nl + 1))
    [ "$l" = readback ] && continue
    grep -q '^END ' "$W/$l.tap" 2>/dev/null || { echo "  FAIL  tap$l: no END line (see $W/tap$l/mame.log) — VOID"; fail=1; }
    nl=$((nl + 1))
done
[ "$fail" = 0 ] || { echo "FAIL: audit_anakaris_rows (a leg did not complete)"; exit 1; }
echo "  ok    $nl legs complete"

echo "== 2. the checks"
python3 - "$W" "$MODE" $LEGS <<'PY'
import sys
W, mode, LEGS = sys.argv[1], sys.argv[2], sys.argv[3:]
def fields(n):
    out = {}
    for l in open(f"{W}/{n}.fields"):
        if l.startswith("F "):
            p = l.split(); out[int(p[1])] = {k: int(v) for k, v in (x.split("=") for x in p[2:])}
    return out
def writes(n):
    w = []
    for l in open(f"{W}/{n}.tap"):
        p = l.split()
        if p and p[0] == "W":   # W <frame> PC <pc> off <addr> data <val> mask <m>
            w.append((int(p[1]), int(p[3], 16), int(p[5], 16), int(p[7], 16), int(p[9], 16)))
    return w
F = {n: fields(n) for n in LEGS}
T = {n: writes(n) for n in LEGS if n != "readback"}
bad = []
def say(ok, msg):
    print(("  ok    " if ok else "  FAIL  ") + msg)
    if not ok: bad.append(msg)
for n, w in T.items():
    if not any(f < 1000 for f, *_ in w): say(False, f"tap {n}: dead (no write before f1000)")
say(all(any(f < 1000 for f, *_ in w) for w in T.values()), f"taps live: {len(T)} legs each with boot writes before f1000")
P1, P2 = 0xFF8400, 0xFF8800
def bw(n, addr, lo=2900):
    """byte writes in match: (frame, pc, value) for the byte at addr (the tap logs words)"""
    even = addr & ~1; m = 0xFF00 if addr == even else 0x00FF
    return [(f, pc, (d >> 8) & 0xFF if m == 0xFF00 else d & 0xFF) for f, pc, a, d, mk in T[n] if f >= lo and a == even and mk & m]
def ww(n, addr, lo=2900):
    return [(f, pc, d) for f, pc, a, d, mk in T[n] if f >= lo and a == addr and mk == 0xFFFF]

# ---------- (a) +0x152, the float
w = bw("float", P1 + 0x152)
sets = [(f, pc) for f, pc, v in w if v == 0x77]
PRESS1, PRESS2 = [3000, 3300, 3600], [3630]
if mode == "float-on-diagonal": PRESS1, PRESS2 = [3900, 4200], []
want = [(p, 0x0267D8) for p in PRESS1] + [(p, 0x026850) for p in PRESS2]
okf1 = len(sets) == len(want) and all(pc == wpc and -1 <= f - p <= 2 for (f, pc), (p, wpc) in zip(sorted(sets), sorted(want)))
say(okf1, f"F1 float: +0x152 := 0x77 writes {[(f, hex(pc)) for f, pc in sets]} = one per up press {[p for p, _ in want]} within a frame (0x0267D8 from the ground, 0x026850 the second press while hovering)")
def runs(w):
    """per 0x77 set: the decrement writes after it up to the next set"""
    out = []; cur = None
    for f, pc, v in w:
        if v == 0x77: cur = [f, pc, []]; out.append(cur)
        elif cur is not None and v == (cur[2][-1][2] - 1 if cur[2] else 0x76) & 0xFF: cur[2].append((f, pc, v))
    return out
r = runs(w)
desc = [(hex(pc), len(d), d[-1][2] if d else None, sorted({hex(x[1]) for x in d})) for f, pc, d in r]
okf2 = ([d[1] for d in desc] == [120, 120, 20, 120] and [d[2] for d in desc] == [0xFF, 0xFF, 0x63, 0xFF]
        and [d[3] for d in desc] == [["0x2683c"]] * 3 + [["0x2692c"]])
say(okf2, f"F2 float: decrements after each 0x77 (setter, count, last value, writers) {desc} — 120 to 0xFF; the third cut at 0x63 by the second press")
fl = F["float"]
y_t1 = max(fl[f]["y1"] for f in range(3010, 3100)); y_t2 = max(fl[f]["y1"] for f in range(3640, 3750))
say(y_t1 == 48 and y_t2 == 97 and fl[3620]["c1511"] == 1 and fl[3640]["c1511"] == 0, f"F2b float: Y {y_t1} after the press from the ground (ground 40), {y_t2} after the press while hovering; +0x151 1 before the second press, 0 after")
diag = [x for x in w if x[0] >= 3880]
say(not diag and all(fl[f]["c1511"] == 2 for f in (3910, 4210)), f"F3 float: UR (3900), UL (4200) and the walk (4400) write +0x152 {len(diag)} times; +0x151 reads 2 in both diagonal jumps")
p2w = [(n, x) for n in T for x in bw(n, P2 + 0x152) if x[1:] != (0x016E4E, 0)]
nclr = sum(1 for n in T for x in bw(n, P2 + 0x152) if x[1:] == (0x016E4E, 0))
say(not p2w, f"F4 P2's +0x152: {len(p2w)} in-match writes over {len(T)} legs other than the block clear 0x016E4E's zeros ({nclr}, at round changes)")

# ---------- (b) +0x156 / +0x1A0, the curse
def curse(n, side=P2, lo=2900, hi=99999):
    """(+0x1A0 set frame, +0x156 set (frame, pc, value), the victim's +0x56 at the set, +0x54 at contact)"""
    s1a0 = [(f, pc) for f, pc, v in bw(n, side + 0x1A0, lo) if v == 1 and f < hi]
    s156 = [(f, pc, d) for f, pc, d in ww(n, side + 0x156, lo) if pc in (0x025FA8, 0x0247DC) and f < hi]
    return s1a0, s156
GROUND = {0: 0x10, 1: 0x70, 2: 0xC0, 3: 0x110}
AIR = {0: 0x3C, 1: 0x9C, 2: 0xEC}
side = P1 if mode == "p1-side" else P2
sfx = "1" if mode == "p1-side" else "2"
got = {}
for n, lo, hi in (("rjg", 2900, 3390), ("rjg", 3390, 3790), ("rjg", 3790, 4700), ("rjes", 2900, 4700)):
    a, s = curse(n, side, lo, hi)
    if len(a) == 1 and len(s) == 1 and a[0][1] == 0x023E6A and s[0][1] == 0x025FA8:
        f = s[0][0]; got[F[n][f + 1][f"r56{sfx}"]] = (s[0][2], F[n][a[0][0] + 1][f"r54{sfx}"])
vals = {k: v for k, (v, _) in got.items()}
if mode == "strength-swapped": vals[0], vals[2] = vals.get(2), vals.get(0)
say(vals == GROUND and all(c == 0x18 for _, c in got.values()) and [vals[k] for k in sorted(vals)] == sorted(vals.values()),
    f"C1 curse standing: per +0x56, +0x156 set by 0x025FA8 after +0x1A0 := 1 from 0x023E6A, contact class 0x18: {[(k, hex(v), hex(c)) for k, (v, c) in sorted(got.items())]} (frozen {[(k, hex(v)) for k, v in GROUND.items()]}, rising)")
gotair = {}
WPC = 0x025FA8 if mode == "air-as-ground" else 0x0247DC
for n in ("rjair_lp", "rjair_mp", "rjair_hp"):
    a, s = curse(n)
    if len(a) == 1 and len(s) == 1 and s[0][1] == WPC:
        f = s[0][0]; gotair[F[n][f + 1]["r562"]] = (s[0][2], F[n][f]["air2"])
say({k: v for k, (v, _) in gotair.items()} == AIR and all(a for _, a in gotair.values()),
    f"C2 curse airborne: per +0x56, +0x156 set by {hex(WPC)} with P2 airborne: {[(k, hex(v), air) for k, (v, air) in sorted(gotair.items())]} (frozen {[(k, hex(v)) for k, v in AIR.items()]}, rising)")
def c3(n):
    """the countdown and the flag over each curse span: decrements by 1 only, +0x1A0 == 1 while +0x156 > 0, then cleared by 0x026742"""
    fl = F[n]; out = []
    for f, pc, v in curse(n)[1]:
        allw = ww(n, P2 + 0x156, f); i0 = allw.index((f, pc, v)); decs = []
        for x in allw[i0 + 1:]:
            if x[1] not in (0x026274, 0x025478): break
            decs.append(x)
            if x[2] == 0: break
        span = list(range(f + 1, decs[-1][0] + 1)) if decs else []   # +0x156 > 0 from the set's landing to the zero's
        chain = all(b[2] == a[2] - 1 for a, b in zip([(f, pc, v)] + decs, decs)) and decs and decs[-1][2] == 0
        flag = all(fl[g]["c1a02"] == 1 and fl[g]["c1562"] > 0 for g in span)
        clr = [x for x in bw(n, P2 + 0x1A0, f) if x[2] == 0][:1]
        end = span[-1] if span else f
        out.append((n, f, hex(v), len(decs), sorted({hex(x[1]) for x in decs}), chain and flag and bool(clr) and clr[0][1] == 0x026742 and clr[0][0] > end))
    return out
r3 = [x for n in ("rjg", "rjes", "rjair_lp", "rjair_mp", "rjair_hp") for x in c3(n)]
say(len(r3) == 7 and all(x[-1] for x in r3), f"C3 countdown: (leg, set frame, value, decrements, writers, ok) {r3} — by 1 to 0, +0x1A0 1 throughout, cleared by 0x026742 after")
wh = curse("rjwhiff")
say(not wh[0] and not wh[1] and all(v["r542"] != 0x18 for v in F["rjwhiff"].values()), f"C4 whiff: +0x1A0 sets {wh[0]}, +0x156 sets {wh[1]}, P2 +0x54 never 0x18")
p1c = [(n, x) for n in T for x in curse(n, P1)[0] + curse(n, P1)[1]]
say(not p1c, f"C5 P1's +0x1A0 / +0x156: {len(p1c)} in-match sets over {len(T)} legs")

# ---------- (e) +0x1AA, the win
def w1aa(n):
    return [(f, pc, v) for f, pc, v in bw(n, P2 + 0x1AA) if pc in (0x023F1A, 0x023F24)]
def cls(n):
    out = []
    for f, pc, v in bw(n, P2 + 0x54):
        if v and (not out or out[-1] != v): out.append(v)
    return out
say(w1aa("pm") == [(w1aa("pm")[0][0], 0x023F1A, 0)] if w1aa("pm") else False,
    f"W1 Pharaoh Magic, no KO: 0x023F reaction writes {[(f, hex(pc), v) for f, pc, v in w1aa('pm')]} (one clear, no set); P2 classes {[hex(c) for c in cls('pm')]}")
def w2(n):
    w = w1aa(n); fl = F[n]
    if len(w) != 2 or w[0][1:] != (0x023F1A, 0) or w[1][1:] != (0x023F24, 1) or w[0][0] != w[1][0]: return False, w
    hp = fl[w[0][0]]["hp2"]
    return hp < 0 and fl[w[0][0] + 1]["c1aa2"] == 1, (w, hp)
ok2, why2 = w2("cof_kill" if mode == "ctl-as-pm" else "pm_kill")
say(ok2, f"W2 Pharaoh Magic KO: 0x023F1A clears and 0x023F24 sets +0x1AA in one frame with P2 HP < 0: {why2}; P2 classes {[hex(c) for c in cls('pm_kill')]}")
ck = w1aa("cof_kill")
say(not ck and all(v["c1aa2"] == 0 for v in F["cof_kill"].values()) and 0x37 in cls("cof_kill") and min(v["hp2"] for v in F["cof_kill"].values()) < 0,
    f"W3 coffin KO: 0x023F writes {ck}, +0x1AA 0 on every frame; classes {[hex(c) for c in cls('cof_kill')]}, P2 HP min {min(v['hp2'] for v in F['cof_kill'].values())}")
def pose(n):
    """the first non-zero write to P1's +0x18D (the even byte of the +0x18C word is +0x18C; +0x18D is the odd byte)"""
    x = [(f, pc, d & 0xFF) for f, pc, a, d, m in T[n] if f >= 2900 and a == 0xFF858C and m & 0x00FF and d & 0xFF]
    return x[0] if x else None
pz = {n: pose(n) for n in ("pm_kill", "pm_clr", "cof_kill", "cof_set")}
aa = {n: F[n][pz[n][0]]["c1aa2"] if pz[n] else None for n in pz}
setleg = "cof_kill" if mode == "unpoked-set" else "cof_set"
ok4 = (pz["pm_kill"] and pz["pm_kill"][2] == 4 and aa["pm_kill"] == 1 and pz["pm_clr"] and pz["pm_clr"][2] != 4 and aa["pm_clr"] == 0
       and pz["cof_kill"] and pz["cof_kill"][2] != 4 and pz[setleg] and pz[setleg][2] == 4 and aa[setleg] == 1)
say(bool(ok4), f"W4 win: P1 +0x18D first write (frame, PC, value) and P2 +0x1AA at that frame: {[(n, None if pz[n] is None else (pz[n][0], hex(pz[n][1]), pz[n][2]), aa[n]) for n in pz]} — 4 exactly when +0x1AA is 1")

# ---------- (c)/(d) +0x374, the Mummy Drop hands
DIST = {"md_lp": 96, "md_mp": 152, "md_hp": 208, "md_es": 72}
got1 = {}
for n in DIST:
    w = [(f, pc, a, d) for f, pc, a, d, m in T[n] if f >= 2900 and a in (P1 + 0x374, P1 + 0x376)]
    f0 = w[0][0] if w else None
    first = [x for x in w if x[0] == f0 and x[1] == 0x03BFEE]
    hiw = next((d for f, pc, a, d in first if a == P1 + 0x374), None)
    got1[n] = (len(first) == 2 and hiw is not None) and (hiw - F[n][f0]["x1"])
say(got1 == DIST, f"M1 Mummy Drop: first in-match +0x374 write a long from 0x03BFEE, high word - P1 X = {got1} (frozen {DIST}, rising LP < MP < HP)")
add = 1 if mode == "hand-offset" else 0
def hand_window(n):
    """field frames from the first +0x374 write's landing to the move's end, or to the frame before the last write lands
    (the hands stop following on the release frame)"""
    fl = F[n]; w = sorted({f for f, pc, a, d, m in T[n] if f >= 2900 and a in (P1 + 0x374, P1 + 0x376)})
    if not w: return []
    end = next(f for f in sorted(fl) if f > w[0] + 1 and fl[f]["seq1"] not in (14, 16))
    if len(w) > 1: end = min(end, w[-1] + 1)
    return list(range(w[0] + 1, end))
m2 = {}
for n in DIST:
    fl = F[n]; live = hand_window(n)
    m2[n] = (len(live), sum(1 for f in live if fl[f]["hx0"] == fl[f]["hx1"] == ((fl[f]["c3741"] >> 16) & 0xFFFF) + add))
say(all(a > 0 and a == b for a, b in m2.values()), f"M2 the hand objects $FFB810/$FFB890 == +0x374's high word on every frame both are live: (frames, equal) {m2}")
carried = []
for n, ppc in (("md_mp", 0x03C1A8), ("md_es", 0x03C396)):
    fl = F[n]; pull = sorted({f for f, pc, a, d, m in T[n] if pc == ppc})
    carried += [(n, f + 1, fl[f + 1]["x2"] - ((fl[f + 1]["c3741"] >> 16) & 0xFFFF)) for f in pull[:-1]]   # the last pull frame releases P2
caught = [(n, sorted({hex(pc) for f, pc, a, d, m in T[n] if f >= 2900 and a in (P1 + 0x374, P1 + 0x376)}), 0x11 in cls(n)) for n in DIST]
say(len(carried) >= 8 and all(o == 48 for _, _, o in carried) and [c[1:] for c in caught] == [(["0x3bfee"], False), (["0x3bfee", "0x3c1a8"], True), (["0x3bfee"], False), (["0x3bfee", "0x3c34c", "0x3c396"], True)],
    f"M3/M4 catches: (leg, +0x374 writers, P2 caught = class 0x11) {caught}; pulled frames before the release {len(carried)}, P2 X - high word {sorted({o for _, _, o in carried})}")
cw = [x for x in T["coffin"] if x[0] >= 2900 and (x[2] & 0x3FF) in (0x374, 0x376)]
say(not cw and cls("coffin").count(0x37) >= 1 and sum(1 for f in sorted(F["coffin"]) if F["coffin"][f]["seq1"] in (14, 16) and F["coffin"][f - 1]["seq1"] not in (14, 16)) == 5,
    f"M5 coffins: {len(cw)} in-match +0x374 writes (either side); five special starts (state 14/16); P2 classes {[hex(c) for c in cls('coffin')]}")
pw = [(f, hex(pc), hex(a), m) for f, pc, a, d, m in T["pit"] if f >= 2900 and a in (P1 + 0x374, P1 + 0x376)]
say(len(pw) == 1 and pw[0][1] == "0x3c760" and pw[0][2] == hex(P1 + 0x374) and pw[0][3] == 0xFFFF, f"M6 4123KK: +0x374 writes {pw} (one word, 0x03C760)")
p2m = [(n, x) for n in T for x in T[n] if x[0] >= 2900 and x[2] in (P2 + 0x374, P2 + 0x376) and not (x[1] == 0x016E4E and x[3] == 0)]
say(not p2m, f"M7 P2's +0x374: {len(p2m)} in-match writes over {len(T)} legs other than the block clear 0x016E4E's zeros")

# ---------- R1, the instrument
POKED = {"c1521": 0x5A, "c1562": 0x5A, "c1a02": 0x5A, "c1aa2": 0x5A, "c3741": 0x5A5A5A5A}
def r1(n):
    fl = F[n]
    return all(fl[4500][k] == v for k, v in POKED.items()) and all(fl[4499][k] != v for k, v in POKED.items())
say(r1("float" if mode == "readback-unpoked" else "readback"), f"R1 readback: the five pokes at f4500 read back at f4500, not at f4499")
if not mode:
    def c1_vals(side_sfx, swap=False):
        return vals if not swap else {0: vals.get(2), 1: vals.get(1), 2: vals.get(0), 3: vals.get(3)}
    p1_got = {}
    for n, lo, hi in (("rjg", 2900, 3390), ("rjg", 3390, 3790), ("rjg", 3790, 4700), ("rjes", 2900, 4700)):
        a, s = curse(n, P1, lo, hi)
        if a and s: p1_got[len(p1_got)] = s[0][2]
    air_as_ground = any(s[0][1] == 0x025FA8 for n in ("rjair_lp", "rjair_mp", "rjair_hp") for s in [curse(n)[1]] if s)
    hand_off = all(a > 0 and sum(1 for f in hand_window(n) if F[n][f]["hx0"] == F[n][f]["hx1"] == ((F[n][f]["c3741"] >> 16) & 0xFFFF) + 1) == a for n, (a, b) in m2.items())
    p_un = pose("cof_kill")
    PRESSD = [(p, 0x0267D8) for p in (3900, 4200)]
    fod = len(sets) == len(PRESSD) and all(pc == wpc and -1 <= f - p <= 2 for (f, pc), (p, wpc) in zip(sorted(sets), PRESSD))
    for name, res in (("float-on-diagonal", fod),
                      ("strength-swapped", c1_vals("2", True) == GROUND),
                      ("p1-side", p1_got == GROUND),
                      ("air-as-ground", air_as_ground),
                      ("hand-offset", hand_off),
                      ("ctl-as-pm", w2("cof_kill")[0]),
                      ("unpoked-set", bool(p_un and p_un[2] == 4)),
                      ("readback-unpoked", r1("float"))):
        print(f"CONTROL DEAD: {name} — the perturbed check still passed" if res else f"CONTROL FIRED: {name} — the perturbed check fails")
        if res: bad.append(name)
sys.exit(1 if bad else 0)
PY
rc=$?
[ "$rc" = 0 ] || { echo "FAIL: audit_anakaris_rows"; exit 1; }
echo "PASS: audit_anakaris_rows — +0x152 the 0x77 hover timer (re-armed once by Up while hovering), +0x156/+0x1A0 the victim's curse timer (rising with +0x56) and flag, +0x1AA the KO'd victim's Pharaoh Magic flag that sets P1 +0x18D to 4, +0x374 the Mummy Drop hands' X"
