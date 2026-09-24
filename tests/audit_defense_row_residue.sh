#!/bin/sh
# audit_defense_row_residue.sh — THE PHOBOS-THROW ±1 DAMAGE RESIDUE IS THE
# DEFENSE-TABLE ROW THE VICTIM'S ID SELECTS, read watch on both legs (14z-145).
#
# WHAT: the ±1 damage residue of Phobos's throws is the defense-table row the VICTIM's id
#   selects: both games ask the table the same question (same index per hit) and the bytes
#   answered differ exactly for the victims whose row differs between the build and vs2 —
#   since the ruled fix only Sasquatch's cross-generation row.
# HOW: the Circuit Scrapper rig on ours and native vs2 under a -debug READ watch over the
#   defense table (and the rally threshold's read, whose D5 is the byte answered), for the
#   residue victims and a control victim; the byte at each index is taken from each leg's
#   OWN data view (the build's verify_data.bin, vs2's image); controls: equal bytes forced
#   on a residue victim, an empty trace.
# EXPECTS: the read fires on every leg from the one reader, the indices equal, the bytes
#   differ on residue victims only; the equal-bytes control fails section 3, the empty trace
#   fails liveness.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh
#   tests/lua/trace_writes.lua tests/replays/hui/80_hui_grab_2p.rpl
#   tools/build_fingerprint.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: known-bad: residue-answers-equal — a residue victim answering the SAME defense byte on both legs must fail section 3 (mode: the real native leg's bytes of the first residue victim — the first whose row differs between the BUILD and vs2 — are forced equal to ours and the section-3 verdict must fail)
#
# WHY. tests/audit_tenant_throw_geometry.sh froze 5 of 54 (victim, throw) cells
# differing by EXACTLY ±1 total damage, sign per VICTIM: 0x10 (Phobos) ours +1
# on all three throws, 0x13 (Donovan) ours -1 on all three, 0x0A (Sasquatch)
# ours -1 on Circuit Scrapper only. (The tenant cells: the 2026-09-18 ruling takes vs2's rows —
# DECISIONS_HISTORY.md "the tenants' DEFENSE rows become vs2's"; this gate re-freezes when that lands.)
# Ruled WITHIN TOLERANCE (maintainer,
# 2026-09-04), kept open as a KNOWLEDGE item. STATIC (14z-145): the
# defender-side DEFENSE CURVE table (vsavj PRG:0x0B8940 / vs2 PRG:0x0D2ABE,
# 32 B per victim id) differs between the games on EXACTLY ids 0x0A, 0x10,
# 0x13 (and 0x19/0x1A, not roster victims) and on no other row — the residue's
# victim set, no more, no less. Rows 0x10/0x13 are content-SWAPPED between the
# games (UNTIL 14z-170 the port kept vanilla vsavj's rows, so Phobos rode
# Bulleta's curve and Donovan Victor's, and the signs were opposite; the ruled
# fix, docs/project/tables/defense_rows.md, gives them vs2's rows); row 0x0A is
# a CROSS-GENERATION retune of Sasquatch, nothing of ours. This gate is the
# in-emulator half.
#
# WHAT IT MEASURES. The Circuit Scrapper rig of the geometry gate (Phobos
# throwing, tests/replays/hui/80_hui_grab_2p.rpl, the victim forced by the
# early-window poke) under a -debug READ watch over the defense table, ours
# (merged, vsavjw) vs native vsav2, for the three residue victims and one
# control victim whose row is identical in both games. Each hit logs the
# reader's PC and D0 = the index the read used (row = id*32 + column); the
# byte at that index is then taken from each leg's DATA view — ours from the
# BUILD UNDER TEST's own `verify_data.bin`, native from vs2's. (Until 14z-170
# ours was taken from PRISTINE vsavj's view — correct only while the tenant
# rows were vsavj's copies; the ruled defense-row fix moved them and the gate
# kept reporting the old bytes: [VSP-147], the value a -debug watch "reads" is
# a table lookup in an image the gate chooses.)
#   1. LIVENESS: the defense read fires on every leg, from the one reader
#      (vsavj `0x18C20 movea.l #$B8940,a0 ; 0x18C26 move.b (a0,d0.w),d3`, vs2
#      `0x175C6/0x175CC`); the index is `(victim id & 0x1F) << 5 + the victim's
#      +0x3B3` = row victim, column ATTACKER id — read off the disassembly;
#   2. the INDEX is the same on both legs for the same victim (same column
#      per hit, row = victim id) — the two games ask the table the same
#      question;
#   3. the BYTES ANSWERED differ for every RESIDUE victim — one whose row in
#      the BUILD differs from vs2's — and are equal for every other: the d3
#      that seeds the final 2D damage-map row is what differs, and nothing
#      else in the read. On merged-m18 the residue victims are 0x10, 0x13 and
#      0x0A; with the ruled defense-row fix (14z-170) the tenants' rows ARE
#      vs2's and only Sasquatch's 0x0A (vanilla vsavj's own data) remains;
#   4. must-fire controls on the reducer: a synthetic pair with equal bytes
#      for a residue victim FAILS 3; an empty trace FAILS 1.
#   5. (14z-170, rule-checker run 2026-09-19-54 Q1) the same for the low-HP RALLY THRESHOLD
#      table (vsavj PRG:0x0BCC80 / vs2 PRG:0x0D6E1E, 1 B per id): its read `move.b (a0,d5.w),d5`
#      (vsavj 0x018C82, vs2 0x017642) writes the byte into its own index register, so D5 at the hit
#      (trace_writes.lua's opt-in REGS_EXTRA=D5) IS the byte answered, observed live; it must equal
#      the victim id's own entry in the leg's image, and the legs must answer differently exactly
#      where the build's byte differs from vs2's (merged-m18: 0x10 and 0x13; with the fix: none).
# NOT asserted: the ±1 itself (that is the geometry gate's frozen residue) —
# this gate names its MECHANISM. NOT compared: pixels, frame numbers.
#
# Emulator tier (MAME -debug, 16 legs in parallel — curve and threshold per victim and game — ~6 min). Usage:
#   ROMDIR=... [MAME_BIN=$HOME/.cache/vampire-saved/mame/cps2] \
#     [MERGED=build/m3b_merged27] [VICTIMS="10 13 0a 03"] [KEEP=dir] tests/audit_defense_row_residue.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
: "${ROMDIR:?set ROMDIR}"
MERGED="${MERGED:-build/m3b_merged27}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "FAIL: MAME_BIN=$MAME_BIN is not executable (tools/setup_mame.sh)"; exit 1; }
[ -f "$MERGED/rompath/vsavjw.zip" ] || { echo "FAIL: no $MERGED/rompath/vsavjw.zip"; exit 1; }
[ -f "$MERGED/verify_data.bin" ] || { echo "FAIL: no $MERGED/verify_data.bin (the build's data view, where ours' bytes are read)"; exit 1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
VICTIMS="${VICTIMS:-10 13 0a 03}"     # the three residue victims + Victor (row identical in both games)
ATT=10                                # Phobos, the attacker of the geometry gate
W="$(mktemp -d "${TMPDIR:-/tmp}/defrow.XXXXXX")"
if [ -n "${KEEP:-}" ]; then mkdir -p "$KEEP"; trap 'cp -R "$W"/. "$KEEP"/ 2>/dev/null; rm -rf "$W"' EXIT; else trap 'rm -rf "$W"' EXIT; fi
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
RPL=tests/replays/hui/80_hui_grab_2p.rpl
echo "== build under test: $MERGED  $(python3 tools/build_fingerprint.py "$MERGED/rompath" --set vsavjw --sha-only | cut -c1-8); attacker 0x$ATT, victims $VICTIMS"

echo "== 1. the legs under the read watch (parallel)"
# (14z-170, rule-checker run 2026-09-19-54 Q1) each (victim, leg) runs TWICE: the defense curve and the
# low-HP rally THRESHOLD table (vsavj PRG:0x0BCC80 / vs2 PRG:0x0D6E1E, 1 B per id), whose read
# `move.b (a0,d5.w),d5` indexes with D5 — logged by trace_writes.lua's opt-in REGS_EXTRA.
for vic in $VICTIMS; do
    for leg in ours native; do for tab in curve thr; do
        d="$W/${vic}_$leg"; [ "$tab" = thr ] && d="$W/${vic}_${leg}_thr"; mkdir -p "$d"
        if [ "$leg" = ours ]; then _s=vsavjw; _rp="$REPO/$MERGED/rompath;$ROMDIR"; _w="b8940,400,r"; [ "$tab" = thr ] && _w="bcc80,20,r"
        else                      _s=vsav2;  _rp="$ROMDIR";                       _w="d2abe,400,r"; [ "$tab" = thr ] && _w="d6e1e,20,r"; fi
        pk="1400:ff8782:$ATT;1450:ff8782:$ATT;1500:ff8782:$ATT;1400:ff8b82:$vic;1450:ff8b82:$vic;1500:ff8b82:$vic"
        ( cd "$d" && WATCH="$_w" REGS_EXTRA=D5 TRACE_OUT="$d/t.txt" FRAMES=3400 REPLAY="$REPO/$RPL" POKES="$pk" \
            MAME_SANDBOX="$d/sb" MAME_ROMPATH="$_rp" \
            "$REPO/tools/run_mame.sh" "$_s" -debug -debugger none -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
            > "$d/l.log" 2>&1 ) </dev/null &
    done; done
done
wait
for vic in $VICTIMS; do for leg in ours native ours_thr native_thr; do
    [ -s "$W/${vic}_$leg/t.txt" ] || bad "leg $vic/$leg: no trace (see $W/${vic}_$leg/l.log)"
    grep -q '^END' "$W/${vic}_$leg/t.txt" || bad "leg $vic/$leg: did not reach END"
done; done
[ "$fail" = 0 ] || exit 1

echo "== 2-3. the reads: same index both legs, bytes differ only for the residue victims"
python3 - "$W" "$VICTIMS" "$MODE" "$MERGED/verify_data.bin" <<'PY' || fail=1
import sys, collections
w, victims = sys.argv[1], sys.argv[2].split()
MODE = sys.argv[3] if len(sys.argv) > 3 else ""
bad = 0
def chk(c, m):
    global bad
    print(("  ok    " if c else "  FAIL  ") + m); bad |= not c
v2 = open("build/out/vsav2_data.bin", "rb").read()
ob = open(sys.argv[4], "rb").read()        # THE BUILD UNDER TEST's data view (14z-170)
BASE = {"ours": (0x0B8940, ob), "native": (0x0D2ABE, v2),
        "ours_thr": (0x0BCC80, ob), "native_thr": (0x0D6E1E, v2)}
READER = {"ours": {0x018C26, 0x018C2A}, "native": {0x0175CC, 0x0175D0},    # the move.b (a0,d0.w),d3 and its post-instruction PC
          "ours_thr": {0x018C82, 0x018C86}, "native_thr": {0x017642, 0x017646}}   # move.b (a0,d5.w),d5 (14z-170)
MATCH_FROM = 1400
def hits(path, base):
    out = []
    for l in open(path):
        f = l.split()
        if not f or f[0] != "frame": continue
        fr, pc = int(f[1]), int(f[3], 16); regs = {f[i]: int(f[i+1], 16) for i in range(4, len(f)-1, 2)}
        if fr < MATCH_FROM: continue                       # the boot sweep and the arming artefact
        out.append((fr, pc, regs["A0"], (regs["D5"] & 0xFF) if base.endswith("_thr") else (regs["D0"] & 0xFFFF)))   # _thr: the byte ANSWERED
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
def verdict3(v, bo, bn, tab="curve"):
    """Section 3's predicate: a victim whose row (curve) or byte (threshold) differs between the BUILD
    and vs2 must be answered DIFFERENT bytes; one whose row is identical, IDENTICAL bytes."""
    if tab == "thr":
        same_row = ob[0x0BCC80 + v] == v2[0x0D6E1E + v]
    else:
        same_row = ob[0x0B8940 + v*32: 0x0B8940 + v*32 + 32] == v2[0x0D2ABE + v*32: 0x0D2ABE + v*32 + 32]
    if same_row:
        return bo == bn, f"CONTROL victim 0x{v:02x} — row identical in the build and vs2, bytes answered identical ({sorted(set(bo))})" if bo == bn else f"control victim 0x{v:02x}: rows identical in the build and vs2 answered DIFFERENT bytes {sorted(set(bo))} vs {sorted(set(bn))}"
    return bo != bn, (f"RESIDUE victim 0x{v:02x} — the bytes answered DIFFER: ours {sorted(set(bo))} vs native {sorted(set(bn))} (d3 seeds a different final-map row)" if bo != bn
                      else f"residue victim 0x{v:02x}: the build's row differs from vs2's but the legs answered the SAME bytes {sorted(set(bo))}")
res = {}
# the first victim whose row differs between the build and vs2 — the mode's target (14z-170)
FIRST_RESIDUE = next((int(x, 16) for x in victims
                      if ob[0x0B8940 + int(x, 16)*32: 0x0B8940 + int(x, 16)*32 + 32]
                      != v2[0x0D2ABE + int(x, 16)*32: 0x0D2ABE + int(x, 16)*32 + 32]), None)
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
    if MODE == "residue-answers-equal" and v == FIRST_RESIDUE: bn = bo
    chk(io == inn, f"{vic}: the INDEX sequence is identical on both legs ({len(io)} reads) — the games ask the same question")
    ok_, msg = verdict3(v, bo, bn); chk(ok_, f"{vic}: {msg}")
    # THE RALLY THRESHOLD (14z-170, rule-checker run 2026-09-19-54 Q1): one byte per id. Its read
    # `move.b (a0,d5.w),d5` writes the byte into its own index register, and the watch reports AFTER
    # the instruction, so D5 at the hit IS the byte answered — observed live, not looked up. It is
    # tied to the victim's id by equalling that id's entry in the leg's own image (a different id's
    # entry equal by coincidence is not excluded; 14z-169's tests/audit_defense_row_reads.sh measured
    # the index directly: the victim's own id).
    for leg in ("ours_thr", "native_thr"):
        base, img = BASE[leg]
        h = hits(f"{w}/{vic}_{leg}/t.txt", leg)
        fs = []
        if not h: fs.append("zero in-play reads — the watch is blind or the throw never landed (LIVENESS)")
        foreign = {hex(pc) for _, pc, _, _ in h if pc not in READER[leg]}
        if foreign: fs.append(f"a reader other than the threshold read touched the table in play: {sorted(foreign)[:4]}")
        vals = [x for _, _, _, x in h]
        res[(vic, leg)] = (fs, vals)
        print(f"  {vic}/{leg}: {len(h)} in-play reads; bytes answered (live) {sorted(set(vals))}; the id's own entry {img[base + v]:#04x}")
        for f in fs: chk(False, f"{vic}/{leg}: {f}")
        if not fs: chk(all(x == img[base + v] for x in vals), f"{vic}/{leg}: every threshold byte answered is 0x{v:02x}'s own entry in the leg's image")
    to, tbo = res[(vic, "ours_thr")]; tn, tbn = res[(vic, "native_thr")]
    if not (to or tn):
        ok_, msg = verdict3(v, tbo, tbn, "thr"); chk(ok_, f"{vic} threshold: {msg.replace('(d3 seeds a different final-map row)', '(the rally engages at a different HP)')}")
# 4. must-fire controls on the reducer — the REAL predicates on synthetic inputs
fs, _, _ = reduce([], "ours"); chk(any("LIVENESS" in f for f in fs), "control: an empty trace is a FAIL")
fs, _, _ = reduce([(3200, 0x000926, 0x0B8940, 0x200)], "ours"); chk(any("reader other" in f for f in fs), "control: a foreign reader in play is caught")
# 0x0A: Sasquatch's row is vanilla vsavj's own retune, which no port row touches — a residue on every build
ok_, _ = verdict3(0x0A, [1, 1], [1, 1])
if not ok_: print("CONTROL FIRED: residue-answers-equal — a residue victim (0x0a) answering EQUAL bytes on both legs fails section 3 (the mode forces this on the real native leg)")
else: print("CONTROL DEAD: residue-answers-equal — a residue victim answering EQUAL bytes was accepted"); bad = 1
ok_, _ = verdict3(0x03, [2, 2], [0, 0]); chk(not ok_, "control: a control victim (0x03) answering DIFFERENT bytes FAILS section 3")
ok_, _ = verdict3(0x03, [0x28], [0x30], "thr"); chk(not ok_, "control: a threshold whose bytes are identical in the build and vs2, answered DIFFERENT, FAILS")
sys.exit(bad)
PY

[ "$fail" = 0 ] && { echo "PASS: audit_defense_row_residue — the defense and rally-threshold bytes answered are the victim's own row: they differ from native exactly where the build's differ from vs2's"; exit 0; }
echo "FAIL: audit_defense_row_residue"; exit 1
