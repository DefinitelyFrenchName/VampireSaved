#!/bin/sh
# audit_mizuumi_finishes.sh — THE FINISH TYPE IN THE KO WINNER'S +0x3B6, ONE KIND PER LEG, AND THE TWO COUNTERS IT FEEDS:
# +0x3BE COUNTS FINISH TYPES 3, 4 AND 6, +0x3BF TYPE 4 ONLY, ON EITHER SIDE, HUMAN WINNERS (measured 14z-215, GitHub #118
# batch B2; the maintainer read each finish's banner on the capture sheets: "yes")
#
# WHAT: on pristine vsavj, 2P versus (both sides human), the KO made by poking the loser's HP and white HP to 1 after the
#   match is live and then landing one finishing move: PRG:0x019152 writes the finish type once, into the KO winner's
#   +0x3B6 only, in the frame before the KO lands — 0 after a 5LP (Anakaris) and after Victor's 6HP throw (P2 winning),
#   1 after a coffin 22MP (either side), 2 after the ES Mummy Drop, the ES coffin and Demitri's Midnight Bliss 263PP,
#   3 after Pharaoh Magic's fourth hit (either side), 4 after Demitri's Midnight Pleasure's last hit (either side),
#   5 after Anakaris's guard cancel 623PP off a blocked 5LP (the winner's +0x19F = 1 at the write), 6 after a coffin
#   inside Dark Force (the winner's +0x111 = 1, either side), 7 after an ES coffin BLOCKED at 1 HP ($FF3471 = 1, written
#   by PRG:0x0183F6 in the KO frame before the type write); the overrides' flags are 0 on every other leg (the order 7 > 6 > 5 > the record byte of
#   PRG:0x019128). Within 2 frames PRG:0x009A2C sets bit 7 on the same side and PRG:0x05DD0E clears it in that frame.
#   In that frame PRG:0x05E2DC raises the winner's +0x3BE exactly when the type is 3, 4 or 6, and PRG:0x05E2D8 raises
#   its +0x3BF exactly when the type is 4; the loser's are never raised; no other PC writes either non-zero in the
#   match; each raise is an ADD (the _pre legs poke 2 first and read 3). A time over (either side ahead) and a Pharaoh
#   Magic that does not KO write no type, no bit 7, no counter. R1: the four bytes poked at f4000 read back at f4000
#   and not at f3999. The banners the game prints were read by the maintainer on the capture sheets, not here; the
#   community names ("Deathblow Type Notification", "EX Finishes Counter", "Unique Finishes Counter") are not judged.
# HOW: on MAME (the reference binary), the scripts made in-gate by the gate's own generator (below) from replay 105's
#   prologue (pair and stocks by poke); for each a FIELD leg (tests/lua/field_trace.lua: both sides' +0x50/+0x52/+0x54/
#   +0x109/+0x111/+0x19F/+0x3B6/+0x3BE/+0x3BF/+0x382 and $FF3471, $FF8120, $FF8105, $FF810D, $FF8109) and, but for readback, a
#   WRITE-TAP leg (tests/lua/read_tap.lua over both sides' words +0x3B6, +0x3BE, +0x19E, +0x110 and $FF3470). At most
#   three MAME at once. A tap write in tap frame f lands in trace frame f+1, so a write's context is read at frame f.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row, each loaded zip's sha1 — or the gate FAILs before any leg; and it
#   names the MAME (tests/lib/mame_ident.sh), or the gate FAILs. Every leg complete and every tap live. E1-E9 and R1
#   as stated in WHAT. CONTROLS (in-gate, each must make its check fail): type-rotated (E1 expecting every type + 1),
#   loser-side (E1 and E4 judged on the KO loser's block), counting-shifted (E4 with +0x3BE counting {0, 1, 2}),
#   unique-as-ex (E4 with +0x3BF counting type 3 instead of 4), store-not-add (E5 expecting 1 after each raise),
#   override-ignored (E2 expecting every override flag 0), noko-as-ko (E7's no-KO expectation judged on k_pm) and
#   readback-unpoked (R1 judged on pm_noko, never poked).
# RIG RECORDS (poke read-back READS-BACK, ruled 2026-10-31, 14z-215): tmr (the time-over legs' timer poke) — sampled, never judged; a record of the rig's poke, never a measurement of the game.
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lib/mame_ident.sh tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/read_tap.lua
#   tests/replays/df/105_df_sas_armor.rpl tools/run_mame.sh tools/setup_mame.sh tools/audit_roms.py docs/checksums.txt
#   tools/build_fingerprint.py tests/expected/registry.tsv
#
# SHEET: none — measures pristine vsavj and/or native vsav2 only; no leg of our build
#
# MUST-FIRE: perturbed-copy: type-rotated — E1 expecting each leg's type + 1 must fail, so the type is read from the write, not assumed (in-gate; as a mode E1 rotates and the gate FAILs)
# MUST-FIRE: perturbed-copy: loser-side — E1 and E4 judged on the KO loser's block must fail, so the winner is measured from both HP words (in-gate; as a mode they judge the loser and the gate FAILs)
# MUST-FIRE: perturbed-copy: counting-shifted — E4 with +0x3BE counting types {0, 1, 2} instead of {3, 4, 6} must fail, so the rule tells the counting finishes from the others (in-gate; as a mode E4 uses {0, 1, 2} and the gate FAILs)
# MUST-FIRE: perturbed-copy: unique-as-ex — E4 with +0x3BF counting type 3 instead of 4 must fail, so the +0x3BF raise is tied to type 4 (in-gate; as a mode E4 uses 3 and the gate FAILs)
# MUST-FIRE: perturbed-copy: store-not-add — E5 expecting each pre-poked counter to read 1 after its raise must fail, so add is told from store (in-gate; as a mode E5 expects 1 and the gate FAILs)
# MUST-FIRE: perturbed-copy: override-ignored — E2 expecting the +0x111/+0x19F/$FF3471 flags 0 on every leg must fail, so the DF, GC and chip legs really produced their events (in-gate; as a mode E2 expects 0 and the gate FAILs)
# MUST-FIRE: known-bad: noko-as-ko — E7's "no type, no counter" judged on k_pm (a KO) must fail, so E7 can see a KO (in-gate; as a mode E7 judges k_pm and the gate FAILs)
# MUST-FIRE: known-bad: readback-unpoked — R1 judged on pm_noko, never poked, must fail, so R1's values come from the pokes (in-gate; as a mode R1 judges pm_noko and the gate FAILs)
#
# NOT COVERED: the banners (the maintainer, on the 14z-215 capture sheets, local); the 1P ladder readers PRG:0x00A79C /
#   PRG:0x0099E0 that read the counters, and the object-slot-full skip at PRG:0x05E298, are never reached; $FF8136 is 0
#   on every leg; the CPU-winner case is rows B's (tests/audit_mizuumi_rows_b.sh); type 4 is shown on Demitri's
#   Midnight Pleasure only, of the records a static walk reads 4 in (14z-215 scratch, local); throws are
#   Victor's 6HP only; a double KO is not tried; the clear at the next game (PRG:0x016E4E) is rows B's T10, not here.
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] tests/audit_mizuumi_finishes.sh
#   emulator tier, MAME; ~2.5 min (41 legs, three at a time); scope ondemand (the pristine-only ruling)
# SHARES: self
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
    W="$(mktemp -d)" || { echo "FAIL: audit_mizuumi_finishes — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }

rm -rf "$W/rpl"; mkdir -p "$W/rpl"
cat > "$W/mk_rpl.py" <<'PY'
#!/usr/bin/env python3
"""the generator (audit_mizuumi_finishes.sh, 14z-215, #118 B2): <replay 105> <out dir> — the finishes rig's replays and per-leg pokes.

Every replay is replay 105's select prologue (tests/replays/df/105_df_sas_armor.rpl, every line before f2000: the four
system taps, the two cursor moves and the two confirms: a 2P versus match, both sides human). The pair is forced by poke
(+0x382 at f1400/1450/1500, B1's way): P1 Anakaris (0x06) / P2 Victor (0x03), P1 Demitri (0x01) on the Midnight legs,
or the sides swapped on the _p2 legs.
Both sides' stocks are poked to 3 at f3100/3120 on every leg (the ES/EX/DF/GC legs need them). The KO is made by poking
the loser's HP and white HP (+0x50/+0x52) to 1 after the match is live (f2900) and before the finishing hit.
Directions are for a fighter on the left facing right (P1); P2 is on the right, so toward = L, back = R.
Writes <name>.rpl and <name>.pokes (the whole POKES string, ';'-separated).
"""
import os, sys
src, out = sys.argv[1], sys.argv[2]; os.makedirs(out, exist_ok=True)
pro = [l.rstrip("\n") for l in open(src) if l.strip() and not l.startswith("#") and int(l.split()[0].split("-")[0]) < 2000]
assert len(pro) == 8, pro
ANA, VIC, DEM = 0x06, 0x03, 0x01
def pick(p1, p2):
    return ";".join(f"{f}:ff8782:{p1:02x};{f}:ff8b82:{p2:02x}" for f in (1400, 1450, 1500)) + \
        ";3100:ff8509:03;3120:ff8509:03;3100:ff8909:03;3120:ff8909:03"
def seq(f, toks, who="p1", step=3):
    return [f"{f + i * step}-{f + i * step + step - 1} {who}={t}" for i, t in enumerate(toks)]
def m22(f, b, who="p1"):   # D, gap, D, D+button: B1's coffin cadence
    return [f"{f}-{f + 2} {who}=D", f"{f + 6}-{f + 8} {who}=D", f"{f + 9}-{f + 11} {who}=D{b}"]
def pm(f, who="p1"):       # Pharaoh Magic, community MK,LP,2,LK,MP (no horizontal direction: the same on either side)
    return seq(f, ["5", "1", "D", "4", "2"], who=who, step=4)
def MP(who, tw):         # Midnight Pleasure, community LP,MP,Towards,MK,MK, after the other side walks in (f3000-3099)
    other = "p2" if who == "p1" else "p1"; back = "L" if other == "p2" else "R"
    return [f"3000-3099 {other}={back}", f"3105-3108 {who}=1", f"3109-3112 {who}=2", f"3113-3116 {who}={tw}", f"3117-3119 {who}=5", f"3122-3124 {who}=5"]
KO1, KO2 = "ff8450:00010001", "ff8850:00010001"   # P1's / P2's HP and white HP := 1
L = {}
# P1 (human) wins: one finish kind per leg
L["k_lp"] = (ANA, VIC, ["3000-3099 p2=L", "3110-3112 p1=1"], f"3105:{KO2}")                       # 5LP (normal)
L["k_cof"] = (ANA, VIC, m22(3300, "2"), f"3330:{KO2}")                                             # 22MP coffin (special)
L["k_mdes"] = (ANA, VIC, seq(3200, ["D", "DR", "R", "12"]), f"3205:{KO2}")                          # Mummy Drop ES 236PP
L["k_cofes"] = (ANA, VIC, m22(3300, "12"), f"3330:{KO2}")                                          # coffin ES 22PP
L["k_pm"] = (ANA, VIC, pm(3500), f"3770:{KO2}")                                                    # Pharaoh Magic (EX)
L["k_df"] = (ANA, VIC, ["3200-3202 p1=14"] + m22(3400, "2"), f"3420:{KO2}")                        # DF (LP+LK), then the coffin
L["k_gc"] = (ANA, VIC, ["3000-3099 p2=L", "3100-3134 p1=L", "3130-3132 p2=1", "3135-3136 p1=R", "3137-3138 p1=D",
                        "3139-3141 p1=DR12"], f"3138:{KO2}")                                        # guard cancel 623PP off a blocked 5LP
L["k_chip"] = (ANA, VIC, ["3330-3400 p2=R"] + m22(3300, "12"), f"3320:{KO2}")                         # ES coffin BLOCKED (P2 holds back from f3330)
L["k_mp"] = (DEM, VIC, MP("p1", "R"), f"3216:{KO2}")                                              # P1 Demitri's Midnight Pleasure, last hit
L["k_mb"] = (DEM, VIC, ["3000-3099 p2=L", "3105-3107 p1=R", "3108-3110 p1=D", "3111-3113 p1=DR12"], f"3130:{KO2}")  # Midnight Bliss 263PP, last hit
L["k_throw"] = (ANA, VIC, ["3000-3099 p2=L", "3100-3103 p2=L3"], f"3095:{KO1}")                    # P2 Victor's 6HP throw: P2 wins
L["tover"] = (ANA, VIC, [], "3000:ff8109:02;3000:ff8850:00640064")                                 # time over, P1 ahead
L["tover_p2"] = (ANA, VIC, [], "3000:ff8109:02;3000:ff8450:00640064")                              # time over, P2 ahead
# the sides swapped: P2 (human) Anakaris wins
L["k_pm_p2"] = (VIC, ANA, pm(3500, "p2"), f"3770:{KO1}")                                           # Pharaoh Magic on P2
L["k_cof_p2"] = (VIC, ANA, m22(3300, "2", "p2"), f"3330:{KO1}")                                    # coffin on P2
L["k_mp_p2"] = (VIC, DEM, MP("p2", "L"), f"3216:{KO1}")                                           # P2 Demitri's Midnight Pleasure
L["k_pm_pre"] = (ANA, VIC, pm(3500), f"3000:ff87be:02;3770:{KO2}")                                 # k_pm with P1 +0x3BE poked to 2 first: add or store?
L["k_mp_pre"] = (DEM, VIC, MP("p1", "R"), f"3000:ff87be:0202;3216:{KO2}")                            # k_mp with P1 +0x3BE/+0x3BF poked to 2 first
L["k_df_p2"] = (VIC, ANA, ["3200-3202 p2=14"] + m22(3400, "2", "p2"), f"3420:{KO1}")               # DF + coffin on P2
# controls
L["pm_noko"] = (ANA, VIC, pm(3500), "")                                                            # Pharaoh Magic, no KO: counters stay 0
L["readback"] = (ANA, VIC, [], "4000:ff87be:5a;4000:ff87bf:a5;4000:ff8bbe:3c;4000:ff8bbf:c3")      # poke read-back
for name, (p1, p2, lines, pk) in L.items():
    with open(os.path.join(out, name + ".rpl"), "w") as f:
        f.write(f"# #118 B2 {name} (audit_mizuumi_finishes.sh, 14z-215): replay 105's prologue, P1 0x{p1:02X} / P2 0x{p2:02X} by poke\n")
        f.write("\n".join(pro + sorted(lines, key=lambda l: int(l.split()[0].split("-")[0]))) + "\n6400 wait\n")
    open(os.path.join(out, name + ".pokes"), "w").write(pick(p1, p2) + (";" + pk if pk else "") + "\n")
print(" ".join(L))
PY
LEGS="$(python3 "$W/mk_rpl.py" "$REPO/tests/replays/df/105_df_sas_armor.rpl" "$W/rpl")" || { echo "FAIL: audit_mizuumi_finishes (the generator)"; exit 1; }
F="ff8109:b:tmr,ff810d:b:g10d,ff8136:b:g136,ff3471:b:chip,ff8120:b:g120,ff8105:b:g105"
for s in 1 2; do b=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 050:w:hp 052:w:wh 054:b:r54 109:b:stk 111:b:df 19f:b:c19f 3b6:b:c3b6 3be:b:c3be 3bf:b:c3bf 382:b:id; do
        F="$F,$(printf '%06x' $((b + 0x${spec%%:*}))):${spec#*:}$s"; done; done
RT="ff3470,2"; for b in ff8400 ff8800; do for o in 3b6 3be 19e 110; do RT="$RT;$(printf '%06x' $((0x$b + 0x$o))),2"; done; done
field() {  # field <leg>
    d="$W/$1"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/rpl/$1.rpl" POKES="$(cat "$W/rpl/$1.pokes")" FIELDS="$F" \
        FIELD_OUT="$W/$1.fields" FIELD_FROM=2900 FRAMES=5400 timeout -k 30 900 "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
tap() {  # tap <leg>
    d="$W/tap$1"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/rpl/$1.rpl" POKES="$(cat "$W/rpl/$1.pokes")" RTAP="$RT" \
        WINDOW="0,0" TRACE_OUT="$W/$1.tap" FRAMES=5400 timeout -k 30 900 "$REPO/tools/run_mame.sh" vsavj \
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
[ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_finishes (a leg did not complete)"; exit 1; }
echo "  ok    $nl legs complete"

echo "== 2. the checks"
python3 - "$W" "$MODE" $LEGS > "$W/main.log" <<'PY'   # #369: the checks' findings, for vs_ctl_caught
import sys
W, mode, LEGS = sys.argv[1], sys.argv[2], sys.argv[3:]
S16 = lambda x: x - 65536 if x >= 32768 else x
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
BASE = {1: 0xFF8400, 2: 0xFF8800}
def checks(mode, verbose):
    bad = []
    def say(ok, msg):
        if verbose: print(("  ok    " if ok else "  FAIL  ") + msg)
        if not ok: bad.append(msg)
    # the expected finish type and the winning side per KO leg
    EXP = {"k_lp": (0, 1), "k_throw": (0, 2), "k_cof": (1, 1), "k_cof_p2": (1, 2), "k_mdes": (2, 1), "k_cofes": (2, 1),
           "k_mb": (2, 1), "k_pm": (3, 1), "k_pm_p2": (3, 2), "k_pm_pre": (3, 1), "k_mp": (4, 1), "k_mp_p2": (4, 2),
           "k_mp_pre": (4, 1), "k_gc": (5, 1), "k_df": (6, 1), "k_df_p2": (6, 2), "k_chip": (7, 1)}
    PRE = {"k_pm_pre": (2, 0), "k_mp_pre": (2, 2)}          # the counters poked at f3000: (+0x3BE, +0x3BF)
    NOKO = ["tover", "tover_p2", "pm_noko"]
    assert set(EXP) | set(NOKO) | {"readback"} == set(LEGS), sorted(set(LEGS) ^ (set(EXP) | set(NOKO) | {"readback"}))
    for n in T:
        live = any(f < 1000 and (a & 0x3FF) == 0x3BE for f, pc, a, d, m in T[n])
        say(live, f"tap {n}: live (the +0x3BE word's boot writes seen)")
    def koside(n):
        """the side whose HP is > 0 on the first frame the other side's HP is <= 0 (the field)"""
        for f in sorted(F[n]):
            h1, h2 = S16(F[n][f]["hp1"]), S16(F[n][f]["hp2"])
            if h2 <= 0 < h1: return 1, f
            if h1 <= 0 < h2: return 2, f
        return None, None
    def ev(n, side):
        """the 0x019152 / 0x009A2C / 0x05DD0E / 0x05E2DC / 0x05E2D8 writes on <side> in the match (f >= 2900)"""
        b = BASE[side]; out = {k: [] for k in ("type", "bit7", "clr7", "be", "bf")}
        for f, pc, a, d, m in T[n]:
            if f < 2900: continue
            if a == b + 0x3B6 and m & 0xFF00:
                k = {0x019152: "type", 0x009A2C: "bit7", 0x05DD0E: "clr7"}.get(pc)
                if k: out[k].append((f, (d >> 8) & 0xFF))
            if a == b + 0x3BE and pc == 0x05E2DC and m & 0xFF00: out["be"].append((f, (d >> 8) & 0xFF))
            if a == b + 0x3BE and pc == 0x05E2D8 and m & 0x00FF: out["bf"].append((f, d & 0xFF))
        return out
    # E1: one type write, on the winner, with the expected value; none on the loser
    r1 = []
    for n, (typ, side) in EXP.items():
        w, kf = koside(n)
        judge = (3 - w) if (mode == "loser-side" and w) else w
        want = (typ + 1) % 8 if mode == "type-rotated" else typ
        e, lo = ev(n, judge) if judge else None, ev(n, 3 - judge) if judge else None
        ok = w == side and e and [v for f, v in e["type"]] == [want] and not lo["type"]
        r1.append((n, w, kf, e["type"] if e else None, ok))
    say(all(x[-1] for x in r1), "E1 PRG:0x019152 writes the type once, on the KO winner only: " +
        ", ".join(f"{n} P{w} {t}" for n, w, kf, t, ok in r1))
    # E2: the override flags at the write (field frame f, before the write lands): +0x111 on 6, +0x19F on 5, $FF3471 on 7
    r2 = []
    for n, (typ, side) in EXP.items():
        e = ev(n, side)
        if not e["type"]: r2.append((n, None, False)); continue
        f = e["type"][0][0]; v = F[n].get(f, {})
        # $FF3471 is rewritten per contact inside the KO frame (0 at PRG:0x018236, 1 at 0x0183F6 on a block), so it is
        # read from the tap: its last write before the type write, in tap order (the field's end-of-frame copy is stale)
        chip = cpc = None
        for fw, pc, a, d, m in T[n]:
            if a == 0xFF3470 and m & 0xFF and fw <= f: chip, cpc = d & 0xFF, pc
            if fw == f and pc == 0x019152: break
        fl = (v.get(f"df{side}"), v.get(f"c19f{side}"), chip)
        want = (0, 0, 0) if mode == "override-ignored" else (int(typ == 6), int(typ == 5), int(typ == 7))
        ok = fl == want and (typ != 7 or (cpc == 0x0183F6 and mode != "override-ignored"))
        r2.append((n, fl, ok))
    say(all(x[-1] for x in r2), "E2 at the type write (+0x111, +0x19F, $FF3471) is (0,0,0) but DF (1,0,0), GC (0,1,0), chip (0,0,1) written by PRG:0x0183F6 in the KO frame: " +
        ", ".join(f"{n} {fl}" for n, fl, ok in r2))
    # E3: bit 7 set on the same side within 2 frames, cleared by 0x05DD0E in that frame
    r3 = []
    for n, (typ, side) in EXP.items():
        e = ev(n, side)
        if not e["type"] or not e["bit7"]: r3.append((n, False)); continue
        ft, vt = e["type"][0]; fb, vb = e["bit7"][0]
        ok = len(e["bit7"]) == 1 and 0 < fb - ft <= 2 and vb == vt | 0x80 and e["clr7"] == [(fb, vt)]
        r3.append((n, ok))
    say(all(x[-1] for x in r3), f"E3 0x009A2C sets bit 7 within 2 frames of the type and 0x05DD0E clears it in that frame ({sum(x[-1] for x in r3)}/{len(r3)})")
    # E4: the counters raise in the bit-7 frame exactly when the type counts; never on the loser
    CNT_BE = {0, 1, 2} if mode == "counting-shifted" else {3, 4, 6}
    CNT_BF = {3} if mode == "unique-as-ex" else {4}
    r4 = []
    for n, (typ, side) in EXP.items():
        w, kf = koside(n)
        judge = (3 - w) if (mode == "loser-side" and w) else side
        e, lo = ev(n, judge), ev(n, 3 - judge)
        fb = e["bit7"][0][0] if e["bit7"] else None
        pbe, pbf = PRE.get(n, (0, 0))
        ok = ([f for f, v in e["be"]] == ([fb] if typ in CNT_BE else []) and [f for f, v in e["bf"]] == ([fb] if typ in CNT_BF else [])
              and not lo["be"] and not lo["bf"])
        last = F[n][max(F[n])]
        ok = ok and last[f"c3be{judge}"] == pbe + (typ in CNT_BE) and last[f"c3bf{judge}"] == pbf + (typ in CNT_BF) \
            and last[f"c3be{3 - judge}"] == 0 and last[f"c3bf{3 - judge}"] == 0
        r4.append((n, typ, len(e["be"]), len(e["bf"]), ok))
    say(all(x[-1] for x in r4), "E4 +0x3BE raised (0x05E2DC) iff type in {3,4,6}, +0x3BF (0x05E2D8) iff type 4, in the bit-7 frame, on the winner only (type: raises 3BE/3BF): " +
        ", ".join(f"{n} {t}:{a}/{b}" for n, t, a, b, ok in r4))
    # E5: add, not store — the pre-poked legs read the poked value + 1 the frame after the raise
    r5 = []
    for n, (pbe, pbf) in PRE.items():
        typ, side = EXP[n]; e = ev(n, side); fb = e["bit7"][0][0]
        before = (F[n][fb][f"c3be{side}"], F[n][fb][f"c3bf{side}"]); after = (F[n][fb + 1][f"c3be{side}"], F[n][fb + 1][f"c3bf{side}"])
        want = (1, 1 if typ == 4 else pbf) if mode == "store-not-add" else (pbe + 1, pbf + (typ == 4))
        r5.append((n, before, after, before == (pbe, pbf) and after == want))
    say(all(x[-1] for x in r5), "E5 each raise adds 1 to the poked value (before -> after): " + ", ".join(f"{n} {b}->{a}" for n, b, a, ok in r5))
    # E6: no other PC writes +0x3BE/+0x3BF non-zero in the match
    def poked(n):   # the frames a leg pokes the +0x3BE/+0x3BF word (a poke shows in the tap as a write by whatever PC runs)
        return {int(e.split(":")[0]) for e in open(f"{W}/rpl/{n}.pokes").read().strip().split(";") if e.split(":")[1] in ("ff87be", "ff87bf", "ff8bbe", "ff8bbf")}
    oth = sorted({(n, hex(pc)) for n in T for f, pc, a, d, m in T[n] if f >= 2900 and a in (0xFF87BE, 0xFF8BBE)
                  and pc not in (0x05E2DC, 0x05E2D8) and d & m and f not in poked(n)})
    say(not oth, f"E6 no PC but 0x05E2DC/0x05E2D8 writes +0x3BE/+0x3BF non-zero in the match: {oth}")
    # E7: no KO, no type: time over (each side ahead) and a Pharaoh Magic that does not KO
    r7 = []
    for n in (["k_pm"] if mode == "noko-as-ko" else []) + NOKO:
        ws = [hex(pc) for f, pc, a, d, m in T[n] if f >= 2900 and pc in (0x019152, 0x009A2C, 0x05DD0E, 0x05E2DC, 0x05E2D8)]
        last = F[n][max(F[n])]
        r7.append((n, ws, not ws and not any(last[k] for k in ("c3be1", "c3be2", "c3bf1", "c3bf2"))))
    hp = {n: (S16(F[n][3200]["hp1"]), S16(F[n][3200]["hp2"])) for n in ("tover", "tover_p2")}
    g = {n: next(((F[n][f]["g120"], F[n][f]["g105"]) for f in sorted(F[n]) if F[n][f]["g120"]), None) for n in ("tover", "tover_p2")}
    say(all(x[-1] for x in r7) and hp == {"tover": (288, 100), "tover_p2": (100, 288)} and all(g.values()),
        f"E7 no type, bit-7 or counter write on {[x[0] for x in r7]} ({[x[1] for x in r7]}); the time overs ran with HP (P1, P2) {hp} and settled ($FF8120, $FF8105 {g}, recorded, not judged)")
    # E8: the side swap is real — the _p2 legs carry Anakaris/Demitri on P2
    ids = {n: (F[n][3000]["id1"], F[n][3000]["id2"]) for n in ("k_pm", "k_pm_p2", "k_mp", "k_mp_p2")}
    say(ids == {"k_pm": (6, 3), "k_pm_p2": (3, 6), "k_mp": (1, 3), "k_mp_p2": (3, 1)}, f"E8 the pairs (P1 id, P2 id) at f3000: {ids}")
    # R1: the poke read-back
    rb = "pm_noko" if mode == "readback-unpoked" else "readback"
    want = (0x5A, 0xA5, 0x3C, 0xC3)
    got = lambda f: tuple(F[rb][f][k] for k in ("c3be1", "c3bf1", "c3be2", "c3bf2"))
    say(got(4000) == want and got(3999) == (0, 0, 0, 0), f"R1 {rb}: f3999 {got(3999)}, f4000 {got(4000)} (poked {want})")
    return bad
bad = checks(mode, True)
CTL = ["type-rotated", "loser-side", "counting-shifted", "unique-as-ex", "store-not-add", "override-ignored", "noko-as-ko", "readback-unpoked"]
if not mode:
    for c in CTL:
        fb = checks(c, False)
        print(f"CONTROL FIRED: {c} — {len(fb)} check(s) fail: {fb[0][:90]}" if fb else f"CONTROL DEAD: {c} — the perturbed checks still pass")
        if not fb: bad.append(c)
sys.exit(1 if bad else 0)
PY
rc=$?
cat "$W/main.log"
if [ -n "$MODE" ]; then
    case "$MODE" in   # #369: the finding each perturbation must produce
        type-rotated) WANT='^  FAIL  E1 PRG:0x019152 writes the type once, on the KO winner only: .+$' ;;
        loser-side) WANT='^  FAIL  (E1 PRG:0x019152 writes the type once, on the KO winner only: .*P[12] \[\]|E4 \+0x3BE raised \(0x05E2DC\) iff type in ).*$' ;;
        counting-shifted|unique-as-ex) WANT='^  FAIL  E4 \+0x3BE raised \(0x05E2DC\) iff type in \{3,4,6\}, .+$' ;;
        store-not-add) WANT='^  FAIL  E5 each raise adds 1 to the poked value \(before -> after\): .+$' ;;
        override-ignored) WANT='^  FAIL  E2 at the type write .+$' ;;
        noko-as-ko) WANT="^  FAIL  E7 no type, bit-7 or counter write on \\['k_pm', [^]]*\\] \\(\\[\\['0x[0-9a-f]+'.*\$" ;;
        readback-unpoked) WANT='^  FAIL  R1 pm_noko: f3999 .+$' ;;
    esac
    [ "$rc" = 0 ] && vs_ctl_left_green "$MODE" "FAIL: audit_mizuumi_finishes — control mode $MODE left the gate green"
    vs_ctl_caught "$W/main.log" "$WANT"; echo "FAIL: audit_mizuumi_finishes (control mode $MODE)"; exit 1
fi
[ "$rc" = 0 ] || { echo "FAIL: audit_mizuumi_finishes"; exit 1; }
echo "PASS: audit_mizuumi_finishes — finish types 0-7 each on a measured KO kind, on the winner; +0x3BE counts 3/4/6 and +0x3BF 4, on either side, human winners, by adding"
