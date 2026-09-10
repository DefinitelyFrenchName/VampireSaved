#!/bin/sh
# audit_defense_row_residue.sh — THE PHOBOS-THROW ±1 DAMAGE RESIDUE IS THE
# DEFENSE-TABLE ROW THE VICTIM'S ID SELECTS, read watch on both legs (14z-145).
#
# MUST-FIRE: known-bad: residue-answers-equal — a residue victim answering the SAME defense byte on both legs must fail section 3 (mode: the real native leg's residue bytes are forced equal to ours and the section-3 verdict must fail)
#
# WHY. tests/audit_tenant_throw_geometry.sh froze 5 of 54 (victim, throw) cells
# differing by EXACTLY ±1 total damage, sign per VICTIM: 0x10 (Phobos) ours +1
# on all three throws, 0x13 (Donovan) ours -1 on all three, 0x0A (Sasquatch)
# ours -1 on Circuit Scrapper only. Ruled WITHIN TOLERANCE (maintainer,
# 2026-09-04), kept open as a KNOWLEDGE item. STATIC (14z-145): the
# defender-side DEFENSE CURVE table (vsavj PRG:0x0B8940 / vs2 PRG:0x0D2ABE,
# 32 B per victim id) differs between the games on EXACTLY ids 0x0A, 0x10,
# 0x13 (and 0x19/0x1A, not roster victims) and on no other row — the residue's
# victim set, no more, no less. Rows 0x10/0x13 are content-SWAPPED between the
# games (the port keeps vanilla vsavj's rows by ruling, docs/project/tables/
# defense_rows.md — so Phobos rides Bulleta's curve and Donovan rides Victor's,
# and the signs are opposite); row 0x0A is a CROSS-GENERATION retune of
# Sasquatch, nothing of ours. This gate is the in-emulator half.
#
# WHAT IT MEASURES. The Circuit Scrapper rig of the geometry gate (Phobos
# throwing, tests/replays/hui/80_hui_grab_2p.rpl, the victim forced by the
# early-window poke) under a -debug READ watch over the defense table, ours
# (merged, vsavjw) vs native vsav2, for the three residue victims and one
# control victim whose row is identical in both games. Each hit logs the
# reader's PC and D0 = the index the read used (row = id*32 + column); the
# byte at that index is then taken from each game's DATA view.
#   1. LIVENESS: the defense read fires on every leg, from the one reader
#      (vsavj `0x18C20 movea.l #$B8940,a0 ; 0x18C26 move.b (a0,d0.w),d3`, vs2
#      `0x175C6/0x175CC`); the index is `(victim id & 0x1F) << 5 + the victim's
#      +0x3B3` = row victim, column ATTACKER id — read off the disassembly;
#   2. the INDEX is the same on both legs for the same victim (same column
#      per hit, row = victim id) — the two games ask the table the same
#      question;
#   3. the BYTES ANSWERED differ for the three residue victims and are equal
#      for the control — the d3 that seeds the final 2D damage-map row is
#      what differs, and nothing else in the read;
#   4. must-fire controls on the reducer: a synthetic pair with equal bytes
#      for a residue victim FAILS 3; an empty trace FAILS 1.
# NOT asserted: the ±1 itself (that is the geometry gate's frozen residue) —
# this gate names its MECHANISM. NOT compared: pixels, frame numbers.
#
# Emulator tier (MAME -debug, 8 legs in parallel, ~5 min). Usage:
#   ROMDIR=... [MAME_BIN=$HOME/.cache/vampire-saved/mame/cps2] \
#     [MERGED=build/m3b_merged26] [VICTIMS="10 13 0a 03"] [KEEP=dir] tests/audit_defense_row_residue.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
: "${ROMDIR:?set ROMDIR}"
MERGED="${MERGED:-build/m3b_merged26}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "FAIL: MAME_BIN=$MAME_BIN is not executable (tools/setup_mame.sh)"; exit 1; }
[ -f "$MERGED/rompath/vsavjw.zip" ] || { echo "FAIL: no $MERGED/rompath/vsavjw.zip"; exit 1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
VICTIMS="${VICTIMS:-10 13 0a 03}"     # the three residue victims + Victor (row identical in both games)
ATT=10                                # Phobos, the attacker of the geometry gate
W="$(mktemp -d "${TMPDIR:-/tmp}/defrow.XXXXXX")"
if [ -n "${KEEP:-}" ]; then mkdir -p "$KEEP"; trap 'cp -R "$W"/. "$KEEP"/ 2>/dev/null; rm -rf "$W"' EXIT; else trap 'rm -rf "$W"' EXIT; fi
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
RPL=tests/replays/hui/80_hui_grab_2p.rpl
echo "== build under test: $MERGED  $(python3 tools/build_fingerprint.py "$MERGED/rompath" --set vsavjw --sha-only | cut -c1-8); attacker 0x$ATT, victims $VICTIMS"

echo "== 1. the legs under the read watch (parallel)"
for vic in $VICTIMS; do
    for leg in ours native; do
        d="$W/${vic}_$leg"; mkdir -p "$d"
        if [ "$leg" = ours ]; then _s=vsavjw; _rp="$REPO/$MERGED/rompath;$ROMDIR"; _w="b8940,400,r"
        else                      _s=vsav2;  _rp="$ROMDIR";                       _w="d2abe,400,r"; fi
        pk="1400:ff8782:$ATT;1450:ff8782:$ATT;1500:ff8782:$ATT;1400:ff8b82:$vic;1450:ff8b82:$vic;1500:ff8b82:$vic"
        ( cd "$d" && WATCH="$_w" TRACE_OUT="$d/t.txt" FRAMES=3400 REPLAY="$REPO/$RPL" POKES="$pk" \
            MAME_SANDBOX="$d/sb" MAME_ROMPATH="$_rp" \
            "$REPO/tools/run_mame.sh" "$_s" -debug -debugger none -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
            > "$d/l.log" 2>&1 ) </dev/null &
    done
done
wait
for vic in $VICTIMS; do for leg in ours native; do
    [ -s "$W/${vic}_$leg/t.txt" ] || bad "leg $vic/$leg: no trace (see $W/${vic}_$leg/l.log)"
    grep -q '^END' "$W/${vic}_$leg/t.txt" || bad "leg $vic/$leg: did not reach END"
done; done
[ "$fail" = 0 ] || exit 1

echo "== 2-3. the reads: same index both legs, bytes differ only for the residue victims"
python3 - "$W" "$VICTIMS" "$MODE" <<'PY' || fail=1
import sys, collections
w, victims = sys.argv[1], sys.argv[2].split()
MODE = sys.argv[3] if len(sys.argv) > 3 else ""
bad = 0
def chk(c, m):
    global bad
    print(("  ok    " if c else "  FAIL  ") + m); bad |= not c
vj = open("build/out/vsavj_data.bin", "rb").read(); v2 = open("build/out/vsav2_data.bin", "rb").read()
BASE = {"ours": (0x0B8940, vj), "native": (0x0D2ABE, v2)}
READER = {"ours": {0x018C26, 0x018C2A}, "native": {0x0175CC, 0x0175D0}}   # the move.b (a0,d0.w),d3 and its post-instruction PC
MATCH_FROM = 1400
def hits(path, base):
    out = []
    for l in open(path):
        f = l.split()
        if not f or f[0] != "frame": continue
        fr, pc = int(f[1]), int(f[3], 16); regs = {f[i]: int(f[i+1], 16) for i in range(4, len(f)-1, 2)}
        if fr < MATCH_FROM: continue                       # the boot sweep and the arming artefact
        out.append((fr, pc, regs["A0"], regs["D0"] & 0xFFFF))
    return out
def reduce(h, leg):
    fails = []
    base, img = BASE[leg]
    if not h: fails.append("zero in-play reads — the watch is blind or the throw never landed (LIVENESS)")
    foreign = {hex(pc) for _, pc, _, _ in h if pc not in READER[leg]}
    if foreign: fails.append(f"a reader other than the defense/apply site touched the table in play: {sorted(foreign)[:4]}")
    if any(a0 != base for _, _, a0, _ in h if _ is not None): fails.append("a hit with A0 not at the table base")
    idx = [d0 for _, _, _, d0 in h]
    return fails, idx, [img[base + i] for i in idx]
def verdict3(v, bo, bn):
    """Section 3's predicate: a victim whose row differs between the images must be answered
    DIFFERENT bytes; one whose row is identical, IDENTICAL bytes."""
    same_row = vj[0x0B8940 + v*32: 0x0B8940 + v*32 + 32] == v2[0x0D2ABE + v*32: 0x0D2ABE + v*32 + 32]
    if same_row:
        return bo == bn, f"CONTROL victim 0x{v:02x} — row identical in both games, bytes answered identical ({sorted(set(bo))})" if bo == bn else f"control victim 0x{v:02x}: identical rows answered DIFFERENT bytes {sorted(set(bo))} vs {sorted(set(bn))}"
    return bo != bn, (f"RESIDUE victim 0x{v:02x} — the bytes answered DIFFER: ours {sorted(set(bo))} vs native {sorted(set(bn))} (d3 seeds a different final-map row)" if bo != bn
                      else f"residue victim 0x{v:02x}: rows differ in the images but the legs answered the SAME bytes {sorted(set(bo))}")
res = {}
for vic in victims:
    v = int(vic, 16)
    for leg in ("ours", "native"):
        h = hits(f"{w}/{vic}_{leg}/t.txt", leg); fs, idx, bytes_ = reduce(h, leg); res[(vic, leg)] = (fs, idx, bytes_)
        rows = collections.Counter(i // 32 for i in idx)
        print(f"  {vic}/{leg}: {len(h)} in-play reads; rows read {dict((hex(k), n) for k, n in rows.items())}; columns {sorted(set(i % 32 for i in idx))}; bytes {sorted(set(bytes_))}")
        for f in fs: chk(False, f"{vic}/{leg}: {f}")
        if not fs: chk(all(i // 32 == v for i in idx), f"{vic}/{leg}: every read is ROW 0x{v:02x} — the victim's own id selects the row")
    fo, io, bo = res[(vic, "ours")]; fn, inn, bn = res[(vic, "native")]
    if fo or fn: continue
    # THE EXECUTABLE MODE: force the first residue victim's native bytes equal to
    # ours, so the section-3 verdict for that victim fails and the gate FAILs.
    if MODE == "residue-answers-equal" and v == 0x10: bn = bo
    chk(io == inn, f"{vic}: the INDEX sequence is identical on both legs ({len(io)} reads) — the games ask the same question")
    ok_, msg = verdict3(v, bo, bn); chk(ok_, f"{vic}: {msg}")
# 4. must-fire controls on the reducer — the REAL predicates on synthetic inputs
fs, _, _ = reduce([], "ours"); chk(any("LIVENESS" in f for f in fs), "control: an empty trace is a FAIL")
fs, _, _ = reduce([(3200, 0x000926, 0x0B8940, 0x200)], "ours"); chk(any("reader other" in f for f in fs), "control: a foreign reader in play is caught")
ok_, _ = verdict3(0x13, [2, 2], [2, 2])
if not ok_: print("CONTROL FIRED: residue-answers-equal — a residue victim (0x13) answering EQUAL bytes on both legs fails section 3 (the mode forces this on the real native leg)")
else: print("CONTROL DEAD: residue-answers-equal — a residue victim answering EQUAL bytes was accepted"); bad = 1
ok_, _ = verdict3(0x03, [2, 2], [0, 0]); chk(not ok_, "control: a control victim (0x03) answering DIFFERENT bytes FAILS section 3")
sys.exit(bad)
PY

[ "$fail" = 0 ] && { echo "PASS: audit_defense_row_residue — the ±1 residue is the defense-table row the victim's id selects: swapped for 0x10/0x13, retuned for 0x0A, identical for the control"; exit 0; }
echo "FAIL: audit_defense_row_residue"; exit 1
