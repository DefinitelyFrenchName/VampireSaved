#!/bin/sh
# audit_sas_penguin_count.sh — SASQUATCH'S PENGUIN DARK FORCE ON PRISTINE VSAVJ: +0x36C IS THE COUNT OF PENGUINS STILL TO
# THROW AND +0x14B THE COUNT ON SCREEN; EACH PUNCH RELEASES ONE, WHICH TRAVELS FARTHER THE STRONGER THE PUNCH (measured
# 14z-214, GitHub #118 batch B6; the chain read on captures and confirmed by the maintainer: "yes")
#
# WHAT: on pristine vsavj, Sasquatch's HP+HK Dark Force (the un-armed sub-state 4 of dispatch_16 row 0x0A) writes 8 to
#   his +0x36C once, at PRG:0x047F14, and in the same frame PRG:0x05475A raises his +0x14B eight times, one per penguin
#   spawned (type-0x24 projectiles, sub-ids 7..0, the farthest first); each later punch lowers +0x36C by one at
#   PRG:0x04800E (8 -> 7 .. 0 -> 0xFF, nine punches), and the penguin whose sub-id equals the new value walks off and
#   explodes on its own, PRG:0x054770 lowering +0x14B by one for each of the eight; the punch that takes +0x36C to 0xFF
#   ends the Dark Force within 60 frames, at least 60 frames before the same mode ends untouched; with no punch +0x36C
#   stays 8 and the mode's end removes all eight in one frame; the LP+LK activation (the armed sub-state) and a leg with
#   no stocks never write +0x36C; P2's +0x36C is never written in the match. THE ROW: at f3300 exactly eight type-0x24
#   penguins stand in projectile slots, sub-ids 7..0, X rising as the sub-id falls (sub 7 the farthest behind him); the eight
#   leave the pool in sub-id order 7, 6 .. 0, sub 8-k after punch k and before the mode ends (each explodes on its own
#   about a second after its release: S8). ONE PUNCH of each strength (LP, MP, HP) at f3340: the released penguin (sub 7) travels 175, 256 and 351 px from where it stood at f3300 and is removed 56, 68
#   and 79 frames after f3341 — the distance grows with the strength (the maintainer's reading, 14z-214).
# HOW: on MAME (the reference binary), replay tests/replays/df/105_df_sas_armor.rpl's prologue (P1 Sasquatch 0x0A, P2
#   Victor 0x03, by poke; stocks poked at f3100/3120), derived in-gate into scripts where P1 walks right f3130-3249 and
#   P2 f3130-3189 (P1 ends beside Victor, so the camera shows the penguins behind him), then: toss (the HP+HK edit, P2's
#   lines from f3300 dropped, P1 punch taps LP/MP/HP cycling every 40 f from f3340 to f3820, thirteen taps), hold (no
#   taps), nodf (toss without the stock pokes) and s1/s2/s3 (one LP / MP / HP at f3340); armor is the replay as it is
#   (LP+LK). FIELD legs (tests/lua/field_trace.lua; s1-s3 trace every projectile slot $FF9400+0x100*n: type +0x02, sub
#   +0x03, X +0x10) and WRITE-TAP legs (tests/lua/read_tap.lua over both sides' +0x36C words and P1's +0x14A word); a
#   READBACK leg runs nodf with +0x36C poked to 0x5A at f3500; a TOSSPOOL leg replays toss with every projectile slot
#   traced. A tap write in tap frame f lands in trace frame f+1.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row, each loaded zip's sha1 — or the gate FAILs before any leg; and it
#   names the MAME (tests/lib/mame_ident.sh), or the gate FAILs. Every leg complete (FIELDSUMMARY / END) and every tap
#   live (writes before f1000, the boot clears). S1-S10 as stated in WHAT; R1: the poked 0x5A reads back on every frame
#   from f3500 and 0 before. CONTROLS (in-gate, each must make its check fail): hold-as-toss (S1 and S7 judged on the
#   hold leg), taps-shifted (S1's decrements paired with punch frames moved 20 frames later), p2-side (S1 judged on P2's
#   +0x36C), readback-unpoked (R1 judged on the toss leg, never poked) and strength-swapped (S8 with the LP and HP legs
#   swapped), layout-reversed (S9 with the X order read backwards) and release-off-by-one (S10 expecting sub 9-k after punch k). The
#   log's header names the commit and host.
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lib/mame_ident.sh tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/read_tap.lua
#   tests/replays/df/105_df_sas_armor.rpl tools/run_mame.sh tools/setup_mame.sh tools/audit_roms.py docs/checksums.txt
#   tools/build_fingerprint.py tests/expected/registry.tsv
#
# SHEET: none — measures pristine vsavj and/or native vsav2 only; no leg of our build
#
# MUST-FIRE: known-bad: hold-as-toss — S1 and S7 judged on the hold leg (the same Dark Force, no punch) must fail, so the decrements and the per-penguin removals they count come from the punches (in-gate; as a mode they judge the hold leg and the gate FAILs)
# MUST-FIRE: perturbed-copy: taps-shifted — S1 with every punch frame moved 20 frames later must fail, so each decrement is paired with its own punch, not with any punch (in-gate; as a mode S1 uses the moved frames and the gate FAILs)
# MUST-FIRE: perturbed-copy: p2-side — S1 judged on P2's +0x36C must fail, so the trace and tap see which side is which (in-gate; as a mode S1 judges P2 and the gate FAILs)
# MUST-FIRE: known-bad: readback-unpoked — R1 judged on the toss leg, which is never poked, must fail, so R1's 0x5A comes from the poke at +0x36C's address (in-gate; as a mode R1 judges the toss leg and the gate FAILs)
# MUST-FIRE: perturbed-copy: layout-reversed — S9 with the slots' X read in reverse order must fail, so it sees which penguin is farthest (in-gate; as a mode S9 reads them reversed and the gate FAILs)
# MUST-FIRE: perturbed-copy: release-off-by-one — S10 expecting the penguin with sub-id 9-k (not 8-k) to be the k-th to leave the pool must fail, so it tells the released penguin from its neighbours (in-gate; as a mode S10 expects 9-k and the gate FAILs)
# MUST-FIRE: perturbed-copy: strength-swapped — S8 with the LP and HP legs swapped must fail, so it tells the strengths apart (in-gate; as a mode S8 judges the swapped legs and the gate FAILs)
#
# NOT COVERED: what ends the Dark Force at 0xFF is not traced (S0's static read names +0x176; it read 0 on every sampled
#   frame); the CPU's coin flip between the two sub-states (S0) is not exercised; whether a penguin hurts Victor, and its
#   travel when it meets him, are not judged (the strength legs' penguins pass behind or beside him).
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] tests/audit_sas_penguin_count.sh
#   emulator tier, MAME; ~15 s (twelve legs in parallel)
set -u
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no reference MAME binary at $MAME_BIN"; exit 0; }
romchk="$(python3 "$REPO/tools/audit_roms.py" "$ROMDIR" 2>&1)" || true
echo "$romchk" | grep >/dev/null 'all match' || { echo "FAIL: ROMDIR is not the pristine reference set (tools/audit_roms.py against docs/checksums.txt):"; echo "$romchk" | tail -5; exit 1; }
romfp="$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR" --set vsavj --sha-only 2>/dev/null)" || true
regfp="$(awk -F'\t' '$2 == "vsavj" && $1 !~ /^#/ {print $1}' "$REPO/tests/expected/registry.tsv")"
[ -n "$romfp" ] && [ "$romfp" = "$regfp" ] || { echo "FAIL: vsavj program fingerprint '$romfp' is not the registry's vsavj row '$regfp'"; exit 1; }
echo "  rom   $(echo "$romchk" | grep 'all match' | head -1); vsavj program fingerprint $romfp = registry vsavj row; zips $(python3 -c 'import hashlib,sys; print(" ".join(f"{z}.zip=" + hashlib.sha1(open(f"{sys.argv[1]}/{z}.zip","rb").read()).hexdigest() for z in ("vsavj","vsav","qsound_hle")))' "$ROMDIR")"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else
    W="$(mktemp -d)" || { echo "FAIL: audit_sas_penguin_count — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }

# THE SCRIPTS, derived from replay 105 (its header: the pair and the stocks are poked; P1 activates at f3260).
RPL="$REPO/tests/replays/df/105_df_sas_armor.rpl"
cp "$RPL" "$W/armor.rpl"
awk '/^4600 wait/ {next}
     /^3260-3263 p1=14$/ {print "3260-3263 p1=36"; hp = 1; next}
     $2 ~ /^p2=/ { split($1, r, "-"); if (r[1] + 0 >= 3300) next }
     {print} END {if (!hp) exit 1}' "$RPL" > "$W/body" || { echo "FAIL: the HP+HK edit did not apply to $RPL"; exit 1; }
printf '3130-3189 p2=R\n3130-3249 p1=R\n' >> "$W/body"
TAPS=""
i=0; f=3340
while [ "$f" -le 3820 ]; do TAPS="$TAPS $f"; f=$((f + 40)); done
{ cat "$W/body"; echo "4600 wait"; } > "$W/hold.rpl"
{ cat "$W/body"; for f in $TAPS; do echo "$f-$((f + 2)) p1=$((i % 3 + 1))"; i=$((i + 1)); done; echo "4600 wait"; } > "$W/toss.rpl"
for b in 1 2 3; do { cat "$W/body"; echo "3340-3342 p1=$b"; echo "4600 wait"; } > "$W/s$b.rpl"; done
PKB="1400:ff8782:0a;1450:ff8782:0a;1500:ff8782:0a;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
STK=";3100:ff8509:03;3120:ff8509:03"
FIELDS="ff802e:b:df,ff876c:b:p1_36c,ff8b6c:b:p2_36c,ff854b:b:p1_14b,ff8576:b:p1_176,ff8406:b:p1seq,ff8410:w:p1x,ff8810:w:p2x"
PF="ff802e:b:df,ff876c:b:p1_36c,ff854b:b:p1_14b"
n=0; while [ "$n" -lt 32 ]; do a=$((0xff9400 + n * 0x100))
    PF="$PF,$(printf '%06x' $((a + 2))):b:t$n,$(printf '%06x' $((a + 3))):b:s$n,$(printf '%06x' $((a + 0x10))):w:x$n"; n=$((n + 1)); done
field() {  # field <name> <rpl> <pokes> [fields]
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$2" POKES="$3" FIELDS="${4:-$FIELDS}" \
        FIELD_OUT="$W/$1.fields" FIELD_FROM=3000 FIELD_TO=4600 FRAMES=4650 "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
tap() {  # tap <name> <rpl> <pokes>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$2" POKES="$3" RTAP="ff876c,2;ff8b6c,2;ff854a,2" \
        WINDOW="0,0" TRACE_OUT="$W/$1.tap" FRAMES=4650 "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
echo "== 1. the legs (pristine vsavj, MAME)"
field toss "$W/toss.rpl" "$PKB$STK" &  tap taptoss "$W/toss.rpl" "$PKB$STK" &
field hold "$W/hold.rpl" "$PKB$STK" &  tap taphold "$W/hold.rpl" "$PKB$STK" &
field armor "$W/armor.rpl" "$PKB$STK" & tap taparmor "$W/armor.rpl" "$PKB$STK" &
field nodf "$W/toss.rpl" "$PKB" &      tap tapnodf "$W/toss.rpl" "$PKB" &
PLANT_POKE="3500:ff876c:5a"   # R1's read-back plant: the positive control that the trace reads +0x36C
field readback "$W/toss.rpl" "$PKB;$PLANT_POKE" &
for b in 1 2 3; do field "s$b" "$W/s$b.rpl" "$PKB$STK" "$PF" & done
field tosspool "$W/toss.rpl" "$PKB$STK" "$PF" &
wait
fail=0
for n in toss hold armor nodf readback s1 s2 s3 tosspool; do
    grep -q '^FIELDSUMMARY' "$W/$n.fields" 2>/dev/null || { echo "  FAIL  $n: no FIELDSUMMARY (see $W/$n/mame.log) — VOID"; fail=1; }
done
for n in toss hold armor nodf; do
    grep -q '^END ' "$W/tap$n.tap" 2>/dev/null || { echo "  FAIL  tap$n: no END line (see $W/tap$n/mame.log) — VOID"; fail=1; }
done
[ "$fail" = 0 ] || { echo "FAIL: audit_sas_penguin_count (a leg did not complete)"; exit 1; }
echo "  ok    thirteen legs complete"

echo "== 2. the checks"
python3 - "$W" "$MODE" $TAPS <<'PY'
import sys
W, mode, taps = sys.argv[1], sys.argv[2], [int(t) for t in sys.argv[3:]]
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
def hi(d): return (d >> 8) & 0xFF   # the even address of a word write (+0x36C)
def lo(d): return d & 0xFF          # the odd address (+0x14B in the +0x14A word)
F = {n: fields(n) for n in ("toss", "hold", "armor", "nodf", "readback", "s1", "s2", "s3", "tosspool")}
T = {n: writes(n) for n in ("toss", "hold", "armor", "nodf")}
bad = []
def say(ok, msg):
    print(("  ok    " if ok else "  FAIL  ") + msg)
    if not ok: bad.append(msg)
for n, w in T.items():
    say(any(f < 1000 for f, *_ in w), f"tap {n}: live ({sum(1 for f, *_ in w if f < 1000)} writes before f1000)")

def s1(leg, side_addr, punches):
    """S1: in the match, exactly one write of 8 from 0x047F14, then one decrement from 0x04800E one frame before each of
    the first nine punches (8-k after punch k, 0xFF after the ninth), and no other write."""
    inm = [(f, pc, hi(d)) for f, pc, a, d, m in T[leg] if f >= 3000 and a == side_addr and m & 0xFF00]
    if not inm or inm[0][1:] != (0x047F14, 8):
        return False, f"first in-match write {inm[:1]} is not 8 from 0x047F14"
    dec = inm[1:]
    want = [(p - 1, 0x04800E, (8 - k) & 0xFF) for k, p in enumerate(punches[:9], 1)]
    if dec != want:
        return False, f"decrements {[(f, hex(pc), v) for f, pc, v in dec][:4]}.. ({len(dec)}) != one per punch, 7..0,0xFF ({len(want)})"
    return True, f"8 at f{inm[0][0]} from 0x047F14, then {len(dec)} decrements from 0x04800E one frame before punches 1-9, 7..0,0xFF"
def s7(leg, punches, df_end):
    """S7: +0x14B raised to 8 by eight 0x05475A writes in the activation frame, then lowered by one 0x054770 write per
    released penguin, each after its punch and before the Dark Force ends (eight before the end)."""
    w = [(f, pc, lo(d)) for f, pc, a, d, m in T[leg] if f >= 3000 and a == 0xFF854A and m & 0xFF]
    up = [x for x in w if x[1] == 0x05475A]
    if [v for _, _, v in up] != list(range(1, 9)) or len({f for f, _, _ in up}) != 1:
        return False, f"spawn writes {up[:3]}.. ({len(up)}) are not 1..8 in one frame"
    down = [x for x in w if x[1] == 0x054770 and df_end and x[0] < df_end]
    if [v for _, _, v in down] != list(range(7, -1, -1)) or any(f <= p for (f, _, _), p in zip(down, punches)):
        return False, f"removals before the end {[(f, v) for f, _, v in down]} are not 7..0, each after its punch"
    return True, f"+0x14B 1..8 at f{up[0][0]} from 0x05475A; 7..0 from 0x054770 at f{[f for f, _, _ in down]}"
def df_end(fl):
    on = [f for f in sorted(fl) if fl[f]["df"] == 1]
    return next((f for f in sorted(fl) if on and f > on[0] and fl[f]["df"] == 0), None)
et, eh = df_end(F["toss"]), df_end(F["hold"])

leg, addr, punches = "toss", 0xFF876C, taps
if mode == "hold-as-toss": leg = "hold"
if mode == "taps-shifted": punches = [p + 20 for p in taps]
if mode == "p2-side": addr = 0xFF8B6C
ok, why = s1(leg, addr, punches); say(ok, f"S1 toss: {why}")
tf = F["toss"]
vals = [tf[p]["p1_36c"] for p in taps[:9]]
say(vals == [(8 - k) & 0xFF for k in range(1, 10)], f"S2 field +0x36C at punches 1-9 = {vals}")
w9 = taps[8] - 1
say(et is not None and eh is not None and 0 < et - w9 <= 60 and eh - et >= 60,
    f"S3 Dark Force end: toss f{et} ({None if et is None else et - w9} f after the 9th decrement), hold f{eh}")
hw = [(f, pc, hi(d)) for f, pc, a, d, m in T["hold"] if f >= 3000 and a == 0xFF876C]
hf = F["hold"]; set_at = next(f for f in sorted(hf) if hf[f]["p1_36c"] == 8)
say(hw == [(hw[0][0], 0x047F14, 8)] if hw else False, f"S4 hold: +0x36C in-match writes {[(f, hex(pc), v) for f, pc, v in hw]}")
say(all(hf[f]["p1_36c"] == 8 for f in hf if f >= set_at), f"S4 hold: +0x36C 8 from f{set_at} to the trace's end")
hrem = [f for f, pc, a, d, m in T["hold"] if f >= 3000 and a == 0xFF854A and pc == 0x054770]
say(len(hrem) == 8 and len(set(hrem)) == 1 and eh is not None and 0 <= hrem[0] + 1 - eh <= 30,
    f"S4 hold: the eight penguins removed in one frame (f{sorted(set(hrem))}) at the mode's end (f{eh})")
for n in ("armor", "nodf"):
    w = [x for x in T[n] if x[0] >= 3000 and x[2] in (0xFF876C, 0xFF8B6C)]
    say(not w and all(v["p1_36c"] == 0 for v in F[n].values()), f"S5 {n}: {len(w)} in-match +0x36C writes, field always 0")
p2 = [x for n in T for x in T[n] if x[0] >= 3000 and x[2] == 0xFF8B6C]
say(not p2, f"S6 P2 +0x36C: {len(p2)} in-match writes over four taps")
ok, why = s7("hold" if mode == "hold-as-toss" else "toss", taps, eh if mode == "hold-as-toss" else et)
say(ok, f"S7 toss: {why}")

# S8: one punch of each strength; the released penguin is the projectile slot holding type 0x24, sub 7 at f3300
WANT = {"s1": (175, 56), "s2": (256, 68), "s3": (351, 79)}   # measured 14z-214: travel px, frames release -> removal
def travel(leg):
    fl = F[leg]; v = fl[3300]
    slot = next((n for n in range(32) if v[f"t{n}"] == 0x24 and v[f"s{n}"] == 7), None)
    if slot is None: return None
    alive = [f for f in sorted(fl) if f >= 3341 and fl[f][f"t{slot}"] == 0x24]
    gone = next((f for f in sorted(fl) if f > 3341 and fl[f][f"t{slot}"] != 0x24), None)
    return (fl[alive[-1]][f"x{slot}"] - v[f"x{slot}"], None if gone is None else gone - 3341)
got = {k: travel(k) for k in WANT}
if mode == "strength-swapped": got = {"s1": got["s3"], "s2": got["s2"], "s3": got["s1"]}
say(got == WANT, f"S8 one punch LP/MP/HP: released penguin's travel and frames to removal {got} (frozen {WANT})")
# S9: the row at f3300 — eight type-0x24 slots, sub-ids 7..0, X rising as the sub-id falls
def s9(fl, reverse=False):
    v = fl[3300]; pen = sorted((v[f"s{n}"], v[f"x{n}"]) for n in range(32) if v[f"t{n}"] == 0x24)
    xs = [x for _, x in pen][::-1] if reverse else [x for _, x in pen]
    return [sb for sb, _ in pen] == list(range(8)) and all(a > b for a, b in zip(xs, xs[1:])), pen
ok9, pen = s9(F["tosspool"], mode == "layout-reversed")
say(ok9, f"S9 the row at f3300: (sub, X) {pen} — sub 7 the farthest behind")
# S10: the eight leave the pool (type no longer 0x24) in sub-id order 7..0, sub 8-k after punch k, all before the end
def s10(fl, off=8):
    v0 = fl[3300]; slot = {v0[f"s{n}"]: n for n in range(32) if v0[f"t{n}"] == 0x24}
    gone = {sb: next((f for f in sorted(fl) if f > 3300 and fl[f][f"t{n}"] != 0x24), None) for sb, n in slot.items()}
    order = [sb for sb, f in sorted(gone.items(), key=lambda x: (x[1] is None, x[1] or 0))]
    want = [off - k for k in range(1, 9)]
    after = all(gone.get(off - k) is not None and et is not None and taps[k - 1] < gone[off - k] < et for k in range(1, 9))
    return order == want and after, {sb: gone[sb] for sb in order}
ok10, mv = s10(F["tosspool"], 9 if mode == "release-off-by-one" else 8)
say(ok10, f"S10 the penguins leave the pool, sub: frame {mv} (punches at {taps[:8]}, the mode ends f{et})")
r1 = lambda fl: all(v["p1_36c"] == 0x5A for f, v in fl.items() if f >= 3500) and all(v["p1_36c"] == 0 for f, v in fl.items() if f < 3500)
say(r1(F["toss" if mode == "readback-unpoked" else "readback"]), "R1 readback: 0x5A poked at f3500 reads back on every later frame, 0 before")
print(f"  info  +0x176 nonzero on {sum(1 for v in tf.values() if v['p1_176'])} toss frames")
if not mode:
    for name, res in (("hold-as-toss", s1("hold", 0xFF876C, taps)[0] or s7("hold", taps, eh)[0]),
                      ("taps-shifted", s1("toss", 0xFF876C, [p + 20 for p in taps])[0]),
                      ("p2-side", s1("toss", 0xFF8B6C, taps)[0]),
                      ("readback-unpoked", r1(F["toss"])),
                      ("strength-swapped", {"s1": got["s3"], "s2": got["s2"], "s3": got["s1"]} == WANT),
                      ("layout-reversed", s9(F["tosspool"], True)[0]),
                      ("release-off-by-one", s10(F["tosspool"], 9)[0])):
        print(f"CONTROL DEAD: {name} — the perturbed check still passed" if res else
              f"CONTROL FIRED: {name} — the perturbed check fails")
        if res: bad.append(name)
sys.exit(1 if bad else 0)
PY
rc=$?
[ "$rc" = 0 ] || { echo "FAIL: audit_sas_penguin_count"; exit 1; }
echo "PASS: audit_sas_penguin_count — +0x36C counts the penguins still to throw (8 -> 0, 0xFF ends the mode), +0x14B those on screen; the travel grows with the punch"
