#!/bin/sh
# audit_lilith_gps_counter.sh — LILITH'S GLOOMY PUPPET SHOW ON PRISTINE VSAVJ: +0x14C IS 1 EXACTLY WHILE THE THROWN HAT
# (A TYPE-0x36 PROJECTILE) IS LIVE, RAISED AT ITS SPAWN AND LOWERED AT ITS DEATH; HER SOUL FLASH MOVES +0x14A INSTEAD
# (measured 14z-215, GitHub #118 batch B5; the maintainer read the capture sheet (b5_gps_near): "yes")
#
# WHAT: on pristine vsavj, P1 Lilith's 4123+LK+MK with 3 stocks spends 2 (3 -> 1 at f3207) and starts the Gloomy Puppet
#   Show; at f3224 one type-0x36 projectile (the thrown hat) enters the $FF9400 pool and PRG:0x05475A writes P1's +0x14C
#   0 -> 1; when that projectile leaves the pool PRG:0x054770 writes 1 -> 0; +0x14C is 1 on exactly the frames a type-0x36
#   projectile is live (Victor near, the hat hits: f3224-3291, 68 f; Victor in the corner, it whiffs and Victor's HP never
#   moves: f3224-3288, 65 f), and nothing else writes it in the match. With 1 stock the same input spends nothing, spawns
#   no type 0x36 and never writes +0x14C. Her Soul Flash (236+LP, no stock) spawns a type-0x33 projectile and moves +0x14A
#   (0x05475A 0 -> 1, 0x054770 1 -> 0, 1 exactly while the type 0x33 is live) and never +0x14C. Idle, P1's +0x149..+0x14D
#   are never written in the match; P2's +0x149..+0x14D are never written in the match on any leg. Static, from S0 (not
#   judged here): 0x05475A/0x054770 add/subtract 1 at owner+0x149+class, so +0x14C is the owner's class-3 counter; three
#   projectile types call it with class 3 (0x23, stamped in Aulbath's code; 0x32, Lei-Lei's; 0x36, Lilith's).
# HOW: on MAME (the reference binary), tests/replays/df/105_df_sas_armor.rpl's prologue (the pair by poke: P1 $FF8782 = 0x0E
#   Lilith, P2 $FF8B82 = 0x03 Victor, both human; P2 idle), derived in-gate into gps (4123 at f3200-3207, LK+MK f3207-3209),
#   far (gps with P2 walking right f3000-3190), sf (236 f3200-3206, LP f3205-3207) and idle; stocks poked to 3 at
#   f3100/3120 on gps/far, to 1 on stk1 (the gps script). FIELD legs (tests/lua/field_trace.lua: P1 stocks, P1 and P2
#   +0x149..+0x14D, Victor's HP, the 32 projectile slots' type byte) and WRITE-TAP legs (tests/lua/read_tap.lua over P1's
#   and P2's +0x148..+0x14D words); a READBACK leg runs idle with +0x14C poked to 0x5A at f3500. A tap write in tap frame f
#   lands in trace frame f+1. Never more than three MAME legs at once.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row, each loaded zip's sha1 — or the gate FAILs before any leg; and it names
#   the MAME (tests/lib/mame_ident.sh), or the gate FAILs. Every leg complete and every tap live. G1-G7 as stated in WHAT;
#   R1: the poked 0x5A reads back on every frame from f3500 and 0 before. CONTROLS (in-gate, each must make its check fail):
#   stk1-as-gps, sf-as-gps, p2-side, class-shifted, window-shifted, readback-unpoked. The log's header names the commit and host.
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lib/mame_ident.sh tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/read_tap.lua
#   tests/replays/df/105_df_sas_armor.rpl tools/run_mame.sh tools/setup_mame.sh tools/audit_roms.py docs/checksums.txt
#   tools/build_fingerprint.py tests/expected/registry.tsv
#
# SHEET: none — measures pristine vsavj and/or native vsav2 only; no leg of our build
#
# MUST-FIRE: known-bad: stk1-as-gps — G1 judged on the one-stock leg (the same input, no Gloomy Puppet Show) must fail, so the 0 -> 1 -> 0 pair comes from the move (in-gate; as a mode G1 judges stk1 and the gate FAILs)
# MUST-FIRE: known-bad: sf-as-gps — G1 judged on the Soul Flash leg (another projectile of hers) must fail, so +0x14C is not any projectile's flag (in-gate; as a mode G1 judges sf and the gate FAILs)
# MUST-FIRE: perturbed-copy: p2-side — G1 judged on P2's +0x14C must fail, so the tap sees which side is which (in-gate; as a mode G1 judges P2 and the gate FAILs)
# MUST-FIRE: perturbed-copy: class-shifted — G1 reading +0x14B (the class-2 neighbour in the same tapped word) must fail, so the check reads the byte it names (in-gate; as a mode G1 reads +0x14B and the gate FAILs)
# MUST-FIRE: perturbed-copy: window-shifted — G2 with the type-0x36 frames moved one frame later must fail, so the frame-exact match is measured (in-gate; as a mode G2 shifts and the gate FAILs)
# MUST-FIRE: known-bad: readback-unpoked — R1 judged on the idle leg, never poked, must fail, so R1's 0x5A comes from the poke at +0x14C's address (in-gate; as a mode R1 judges idle and the gate FAILs)
#
# NOT COVERED: Aulbath's type 0x23 and Lei-Lei's type 0x32 (the other class-3 callers, S0 static) are not played, so that
#   they move +0x14C is static only; two hats at once (Mimic Doll's copy, the type-0x36 stamp at PRG:0x05D018) is not
#   played; the dance's inputs and the hat on Victor's head after the projectile dies (drawn by another object) are not
#   judged; who READS +0x14C (Lilith x11, Aulbath, Lei-Lei, the CPU AI's OR of the five counters, S0) is not exercised; the
#   picture lags the counter by about one frame on the snapshots (the hat is drawn once more after the clear), not judged.
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] audit_lilith_gps_counter.sh
#   emulator tier, MAME; ~1 min (eleven legs, three at a time); scope ondemand (the pristine-only ruling)
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
    W="$(mktemp -d)" || { echo "FAIL: audit_lilith_gps_counter — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }

# THE SCRIPTS, derived from replay 105's prologue (everything before its "# activate" line: coins, starts, the select presses).
RPL="$REPO/tests/replays/df/105_df_sas_armor.rpl"
awk '/^# activate/ {exit} {print}' "$RPL" | grep -v '^#' > "$W/prologue"
grep -q '^1360-1362 p2=1$' "$W/prologue" || { echo "FAIL: replay 105's prologue is not the one this gate was measured on"; exit 1; }
GPS="3200-3201 p1=L
3202-3203 p1=DL
3204-3205 p1=D
3206-3208 p1=DR
3207-3209 p1=45"
{ cat "$W/prologue"; echo "$GPS"; echo "4400 wait"; } > "$W/gps.rpl"
{ cat "$W/prologue"; echo "3000-3190 p2=R"; echo "$GPS"; echo "4400 wait"; } > "$W/far.rpl"
{ cat "$W/prologue"; printf '%s\n' "3200-3201 p1=D" "3202-3203 p1=DR" "3204-3206 p1=R" "3205-3207 p1=1" "4400 wait"; } > "$W/sf.rpl"
{ cat "$W/prologue"; echo "4400 wait"; } > "$W/idle.rpl"
PKB="1400:ff8782:0e;1450:ff8782:0e;1500:ff8782:0e;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
STK3=";3100:ff8509:03;3120:ff8509:03"; STK1=";3100:ff8509:01;3120:ff8509:01"
PLANT_POKE="3500:ff854c:5a"   # R1's read-back plant: the positive control that the trace reads +0x14C
FIELDS="ff8509:b:stk,ff8850:w:hp2"
for o in 149 14a 14b 14c 14d; do FIELDS="$FIELDS,$(printf '%06x' $((0xff8400 + 0x$o))):b:p1_$o,$(printf '%06x' $((0xff8800 + 0x$o))):b:p2_$o"; done
n=0; while [ "$n" -lt 32 ]; do FIELDS="$FIELDS,$(printf '%06x' $((0xff9402 + n * 0x100))):b:t$n"; n=$((n + 1)); done
field() {  # field <name> <rpl> <pokes>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$2" POKES="$3" FIELDS="$FIELDS" \
        FIELD_OUT="$W/$1.fields" FIELD_FROM=3000 FIELD_TO=4400 FRAMES=4420 timeout -k 10 600 "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
tap() {  # tap <name> <rpl> <pokes>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$2" POKES="$3" RTAP="ff8548,6;ff8948,6" \
        WINDOW="0,0" TRACE_OUT="$W/$1.tap" FRAMES=4420 timeout -k 10 600 "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
echo "== 1. the legs (pristine vsavj, MAME, three at a time)"
field gps "$W/gps.rpl" "$PKB$STK3" &   tap tapgps "$W/gps.rpl" "$PKB$STK3" &   field far "$W/far.rpl" "$PKB$STK3" &
wait
tap tapfar "$W/far.rpl" "$PKB$STK3" &    field stk1 "$W/gps.rpl" "$PKB$STK1" &  tap tapstk1 "$W/gps.rpl" "$PKB$STK1" &
wait
field sf "$W/sf.rpl" "$PKB" &          tap tapsf "$W/sf.rpl" "$PKB" &          field idle "$W/idle.rpl" "$PKB" &
wait
tap tapidle "$W/idle.rpl" "$PKB" &      field readback "$W/idle.rpl" "$PKB;$PLANT_POKE" &
wait
fail=0
for n in gps far stk1 sf idle readback; do
    grep -q '^FIELDSUMMARY' "$W/$n.fields" 2>/dev/null || { echo "  FAIL  $n: no FIELDSUMMARY (see $W/$n/mame.log) — VOID"; fail=1; }
done
for n in gps far stk1 sf idle; do
    grep -q '^END ' "$W/tap$n.tap" 2>/dev/null || { echo "  FAIL  tap$n: no END line (see $W/tap$n/mame.log) — VOID"; fail=1; }
done
[ "$fail" = 0 ] || { echo "FAIL: audit_lilith_gps_counter (a leg did not complete)"; exit 1; }
echo "  ok    eleven legs complete"

echo "== 2. the checks"
python3 - "$W" "$MODE" <<'PY'
import sys
W, mode = sys.argv[1], sys.argv[2]
def fields(n):
    out = {}
    for l in open(f"{W}/{n}.fields"):
        if l.startswith("F "):
            p = l.split(); out[int(p[1])] = {k: int(v) for k, v in (x.split("=") for x in p[2:])}
    return out
def writes(n):
    w = []
    for l in open(f"{W}/tap{n}.tap"):
        p = l.split()
        if p and p[0] == "W":   # W <frame> PC <pc> off <addr> data <val> mask <m>
            w.append((int(p[1]), int(p[3], 16), int(p[5], 16), int(p[7], 16), int(p[9], 16)))
    return w
def byte_writes(n, addr):
    """in-match writes that touch the byte at addr: (frame, pc, value). The tap reports the word address."""
    out = []
    for f, pc, a, d, m in writes(n):
        if f < 3000: continue
        if a == addr and m & 0xFF00: out.append((f, pc, (d >> 8) & 0xFF))      # even byte of the word at addr
        elif a == addr - 1 and m & 0x00FF: out.append((f, pc, d & 0xFF))      # odd byte of the word at addr-1
    return out
F = {n: fields(n) for n in ("gps", "far", "stk1", "sf", "idle", "readback")}
T = {n: writes(n) for n in ("gps", "far", "stk1", "sf", "idle")}
bad = []
def say(ok, msg):
    print(("  ok    " if ok else "  FAIL  ") + msg)
    if not ok: bad.append(msg)
for n, w in T.items():
    say(any(f < 1000 for f, *_ in w), f"tap {n}: live ({sum(1 for f, *_ in w if f < 1000)} writes before f1000)")
WANT = {"gps": (3224, 3291), "far": (3224, 3288)}   # measured 14z-215: first and last frame +0x14C = 1 / a type 0x36 live

def g1(leg, addr):
    """G1: exactly two in-match writes to the byte: 1 from 0x05475A, then 0 from 0x054770."""
    w = byte_writes(leg, addr)
    ok = [(pc, v) for _, pc, v in w] == [(0x05475A, 1), (0x054770, 0)]
    return ok, f"in-match writes {[(f, hex(pc), v) for f, pc, v in w]}", w
def g2(leg, fld, typ, shift=0):
    """G2: the field is 1 exactly on the frames a projectile of type typ is live (0 elsewhere), in-match."""
    fl = F[leg]
    live = {f for f, v in fl.items() if any(v[f"t{n}"] == typ for n in range(32))}
    if shift: live = {f + shift for f in live}
    one = {f for f, v in fl.items() if v[fld] == 1}
    other = {f for f, v in fl.items() if v[fld] not in (0, 1)}
    return bool(live) and one == live and not other, (min(one) if one else None, max(one) if one else None, len(one))

addr, leg1 = 0xFF854C, "gps"
if mode == "stk1-as-gps": leg1 = "stk1"
if mode == "sf-as-gps": leg1 = "sf"
if mode == "p2-side": addr = 0xFF894C
if mode == "class-shifted": addr = 0xFF854B
for leg in ("gps", "far"):
    ok, why, w = g1(leg1 if leg == "gps" else leg, addr if leg == "gps" else 0xFF854C)
    say(ok, f"G1 {leg1 if leg == 'gps' else leg}: {why}")
    ok2, (a, b, c) = g2(leg, "p1_14c", 0x36, 1 if mode == "window-shifted" else 0)
    say(ok2 and (a, b) == WANT[leg], f"G2 {leg}: +0x14C = 1 on f{a}-{b} ({c} f), exactly the frames a type-0x36 projectile is live (frozen {WANT[leg]})")
    okb, _, wb = g1(leg, 0xFF854C)
    say(okb and wb[0][0] + 1 == a and wb[1][0] == b, f"G2b {leg}: the 0x05475A write (tap f{wb[0][0] if wb else None}) opens the window and the 0x054770 write closes it (tap frame f lands in trace frame f+1)")
gf, ff, sf_ = F["gps"], F["far"], F["stk1"]
stk_drop = [f for f in sorted(gf) if f > 3000 and gf[f]["stk"] != gf[f - 1]["stk"]] if 3000 in gf else []
say([(f, gf[f - 1]["stk"], gf[f]["stk"]) for f in stk_drop if f > 3150] == [(3207, 3, 1)], f"G3 gps: stocks {[(f, gf[f - 1]['stk'], gf[f]['stk']) for f in stk_drop if f > 3150]} (3 -> 1 at f3207, the move costs two)")
say(all(v["stk"] == 1 for f, v in sf_.items() if f >= 3150) and not any(v[f"t{n}"] == 0x36 for v in sf_.values() for n in range(32))
    and not byte_writes("stk1", 0xFF854C) and all(v["p1_14c"] == 0 for v in sf_.values()),
    "G3 stk1: one stock, the same input: stocks stay 1, no type 0x36, +0x14C never written and always 0")
hp = sorted({v["hp2"] for f, v in ff.items() if f >= 3150})
say(len(hp) == 1, f"G4 far: Victor's HP {hp} never moves (the hat whiffs)")
ok, why, _ = g1("sf", 0xFF854A)
say(ok, f"G5 sf: +0x14A {why} (the instrument sees her class-1 counter)")
ok2, (a, b, c) = g2("sf", "p1_14a", 0x33)
say(ok2, f"G5 sf: +0x14A = 1 on f{a}-{b} ({c} f), exactly the frames a type-0x33 projectile is live")
say(not byte_writes("sf", 0xFF854C) and all(v["p1_14c"] == 0 for v in F["sf"].values()), "G5 sf: +0x14C never written in the match, always 0")
p2w = [(n, x) for n in T for a in range(0xFF8949, 0xFF894E) for x in byte_writes(n, a)]
say(not p2w, f"G6 P2's +0x149..+0x14D: {len(p2w)} in-match writes over five taps")
iw = [x for a in range(0xFF8549, 0xFF854E) for x in byte_writes("idle", a)]
say(not iw, f"G7 idle: {len(iw)} in-match writes to P1's +0x149..+0x14D")
r1 = lambda fl: all(v["p1_14c"] == 0x5A for f, v in fl.items() if f >= 3500) and all(v["p1_14c"] == 0 for f, v in fl.items() if f < 3500)
say(r1(F["idle" if mode == "readback-unpoked" else "readback"]), "R1 readback: 0x5A poked at f3500 reads back on every later frame, 0 before")
if not mode:
    for name, res in (("stk1-as-gps", g1("stk1", 0xFF854C)[0]), ("sf-as-gps", g1("sf", 0xFF854C)[0]),
                      ("p2-side", g1("gps", 0xFF894C)[0]), ("class-shifted", g1("gps", 0xFF854B)[0]),
                      ("window-shifted", g2("gps", "p1_14c", 0x36, 1)[0]), ("readback-unpoked", r1(F["idle"]))):
        print(f"CONTROL DEAD: {name} — the perturbed check still passed" if res else
              f"CONTROL FIRED: {name} — the perturbed check fails")
        if res: bad.append(name)
sys.exit(1 if bad else 0)
PY
rc=$?
[ "$rc" = 0 ] || { echo "FAIL: audit_lilith_gps_counter"; exit 1; }
echo "PASS: audit_lilith_gps_counter — +0x14C is 1 exactly while Lilith's Gloomy Puppet Show hat (type 0x36) is live; the Soul Flash moves +0x14A, one stock spawns nothing"
