#!/bin/sh
# test_advancing_guard.sh — THE ADVANCING GUARD (guard push), MEASURED on
# native vs2 and on vsavj, and frozen (14z-123, the documentation pass's G2).
#
# WHY. 14z-121 (4) read vs2 `0x27082` (the second per-frame step routine,
# three byte lists at `0x2797A`: 91 / 115 / 157 px) plus its arming site
# `0x2681E` and wrote them up as "the shape of a THROW MASH-ESCAPE pushing the
# thrower away (read, not measured)". Measured here, it is NOT a throw
# mechanic at all — it is the ADVANCING GUARD: while a fighter is in
# grounded BLOCKSTUN (state word 0x0202, `+0x140` = 2, class byte 0xFF —
# the block-ENTRY handler vsavj `0x2395A`/`0x23966` (vs2 `0x22496`/`0x224A2`)
# opens a 14-frame window `+0x1AB` = 14, and the System Timer Reducer vsavj
# `0x2246E` / vs2 `0x20E24` counts it down; this header said "the block
# handler `0x2246E`" until 14z-126 — the write tap had named the
# decrementer), each
# NEW button press (the new-press mask `+0x126` & 0x77; directions do not
# count) feeds the counter `+0x170`, and when it crosses the threshold the
# ATTACKER (`+0x32(a6)` -> a4) gets `+0x185` = 1, `+0x1B0` = 0, `+0x5D` =
# its own flip_x ^ 1 and `+0x59` = the STRENGTH CLASS of the press that
# completed it (light 0 / medium 1 / heavy 2 — punches and kicks alike),
# so `0x27082` walks list[+0x59] and pushes the attacker AWAY 91 / 115 /
# 157 px. The blocker gets `+0x171` = 0x10, `+0x184` = 1, `+0x5C` = 1,
# `+0x3B5` = 4. A press after the window closes counts for nothing.
#
# THE TWO GAMES DIFFER IN THE THRESHOLD, by design (static, asserted in
# step 2): vs2 adds a STRENGTH WEIGHT per press (light 1 / medium 2 /
# heavy 3, `0x267F4`) and fires at >= 10 (`0x267FC`) — deterministic; a
# 7-tap light mash cannot reach it. vsavj adds 1 per press (`0x27606`)
# and, below 8 (`0x2760E`), rolls the engine RNG `0x14E8A` against a
# per-count bitmask table `0x28D50` (counts 1-2: never; 3: 8/32; 4: 16/32;
# 5: 24/32; 6-7: always) — the familiar "mash more" guard push. Both
# games skip id 0x06 (ANAKARIS has no advancing guard: `0x267B8` /
# `0x275CE`). The push routine and the three lists are byte-identical
# twins (vsavj `0x27E2E`, lists `0x2871C`).
#
# THE RIG (tools/name_moves.py donovan_victim part 4): Victor (P1) 5MP /
# 5HP into a blocking P2 pinned mid-screen — a CORNERED blocker transfers
# the block pushback onto the attacker and that mover overlaps the push
# (the first staging of this rig, and why it is not at the wall). P2 taps
# one button on alternate frames inside the window, or after it (the late
# negative), or not at all (the control). Four legs: vs2 with Donovan
# blocking and with Anakaris blocking; vsavj with Demitri and with
# Anakaris (forced by the early-window id pokes, [VSP-120]).
#
# WHAT IT ASSERTS: the frozen per-event lines (tests/expected/
# advancing_guard.txt, tools/advancing_guard.py's reduction — the
# counter's values, the push frame, the list index, the facing, the
# per-frame steps vs the list bytes READ FROM EACH GAME'S DATA VIEW,
# tick-aware), and structurally: the control and the late mash never
# push; Anakaris never counts and never pushes on either game; on vs2 the
# counter steps by the press weight and the push lands exactly when it
# first reaches 10 (light/LK mashes never do); on vsavj the counter steps
# by 1, no push below a count of 3, and the list index is the strength
# class of the press; every push's steps equal its list; the attacker is
# pushed AWAY (facing right, steps negative).
#
# Emulator tier (MAME, four ~2.5 min legs in parallel). Usage:
#   ROMDIR=... [FREEZE=1] tests/test_advancing_guard.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-123 (inferred_claims row 8): the 0x27082/0x2797A step family is the
#   ADVANCING GUARD (guard push), NOT a throw mash-escape: a grounded block
#   opens a 14-tick window +0x1AB, button presses feed +0x170, the ATTACKER is
#   pushed 91/115/157 px (lists byte- identical vsavj PRG:0x02871C). vs2 fires
#   at a weighted >=10, vsavj +1/ press with an RNG roll below 8. Four legs
#   (vs2 + vsavj), 44 frozen lines; FREEZE=1; rig = name_moves victim part 4
#   (regeneration-checked). ~3 min.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
: "${ROMDIR:?set ROMDIR}"
W="$(mktemp -d "${TMPDIR:-/tmp}/advg.XXXXXX")"; trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
EXP="tests/expected/advancing_guard.txt"
. "$REPO/tests/lib/decrypt_cache.sh"

echo "== 1. the rig equals a regeneration"
python3 tools/name_moves.py gen donovan_victim 4 "$W/r.rpl" "$W/r.json" > /dev/null || bad "gen"
cmp -s "$W/r.rpl" tests/replays/naming/donovan_victim_4.rpl && cmp -s "$W/r.json" tests/replays/naming/donovan_victim_4.json \
  && ok "tests/replays/naming/donovan_victim_4.* = regeneration" || bad "rig drifted — regenerate"

echo "== 2. the static twins (opcode + data views)"
decrypt_view vsav2 "$W/vs2_op.bin" "$W/vs2_data.bin" || bad "decrypt vsav2"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_data.bin" || bad "decrypt vsavj"
python3 - "$W" <<'PY' || fail=1
import sys
w = sys.argv[1]
vs2o = open(f"{w}/vs2_op.bin", "rb").read(); vjo = open(f"{w}/vj_op.bin", "rb").read()
vs2d = open(f"{w}/vs2_data.bin", "rb").read(); vjd = open(f"{w}/vj_data.bin", "rb").read()
bad = 0
def chk(cond, msg):
    global bad
    print(("  ok    " if cond else "  FAIL  ") + msg); bad |= not cond
# the push routine: vs2 0x27082 == vsavj 0x27E2E except the lea's pc-relative displacement word
a, b = vs2o[0x27082:0x27082 + 0x48], vjo[0x27E2E:0x27E2E + 0x48]
chk(a[:0x0E] == b[:0x0E] and a[0x10:] == b[0x10:] and a[0x0E:0x10] != b[0x0E:0x10],
    "push routine: vsavj 0x27E2E is vs2 0x27082 byte-for-byte except the list-table displacement")
chk(a[0x0C:0x0E] == b[0x0C:0x0E] == bytes.fromhex("41fa"), "push routine: lea (pc) at +0x0C on both")
chk(0x27090 + int.from_bytes(a[0x0E:0x10], "big") == 0x2797A and 0x27E3C + int.from_bytes(b[0x0E:0x10], "big") == 0x2871C,
    "the lea resolves to the list table: vs2 0x2797A, vsavj 0x2871C")
def lists(d, base):
    out = []
    for i in range(3):
        p = base + int.from_bytes(d[base + 2 * i:base + 2 * i + 2], "big"); s = []
        while d[p] < 0x80: s.append(d[p]); p += 1
        out.append(s)
    return out
L2, LJ = lists(vs2d, 0x2797A), lists(vjd, 0x2871C)
chk(L2 == LJ, f"the three lists are identical on both games: {[ (len(s), sum(s)) for s in L2 ]} (frames, px)")
chk([sum(s) for s in L2] == [91, 115, 157], "list totals 91 / 115 / 157 px")
# the mash check: vs2 strength-weighted >= 10; vsavj +1 per press, chance table below 8
chk(vs2o[0x267F4:0x267F8] == bytes.fromhex("d32e0170") and vs2o[0x267FC:0x26800] == bytes.fromhex("0c00000a"),
    "vs2 0x267F4 add.b d1,$170(a6) (weight) / 0x267FC cmpi.b #10")
chk(vs2o[0x267F0:0x267F4] == bytes.fromhex("e2095201"), "vs2 weight = (class>>1)+1: lsr.b #1,d1; addq.b #1,d1")
chk(vjo[0x27606:0x2760A] == bytes.fromhex("522e0170") and vjo[0x2760E:0x27612] == bytes.fromhex("0c000008"),
    "vsavj 0x27606 addq.b #1,$170(a6) / 0x2760E cmpi.b #8")
chk(vjo[0x2761E:0x27624] == bytes.fromhex("4eb900014e8a"), "vsavj rolls the RNG 0x14E8A below 8")
tbl = [int.from_bytes(vjd[0x28D50 + 4 * i:0x28D54 + 4 * i], "big") for i in range(8)]
chk(tbl == [0, 0, 0, 0xFF, 0xFFFF, 0xFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF], f"vsavj chance table 0x28D50 = {[hex(t) for t in tbl]}")
chk(vs2o[0x267B8:0x267BE] == bytes.fromhex("0c2e00060382") and vjo[0x275CE:0x275D4] == bytes.fromhex("0c2e00060382"),
    "both games skip id 0x06 (Anakaris) at the head of the check")
chk(vs2o[0x2681E:0x26824] == bytes.fromhex("197c00010185") and vjo[0x27648:0x2764E] == bytes.fromhex("197c00010185"),
    "the arming write +0x185(a4) = 1 on the OTHER fighter: vs2 0x2681E, vsavj 0x27648")
chk(vs2o[0x224A2:0x224A8] == bytes.fromhex("1d7c000e01ab") and vs2o[0x22496:0x2249C] == bytes.fromhex("1d7c00020140"),
    "vs2 block-ENTRY handler 0x22496/0x224A2 (vsavj 0x2395A/0x23966) opens the window: +0x1AB = 14, +0x140 = 2")
sys.exit(bad)
PY

echo "== 3. the four legs"
POKES="$(python3 -c "import json;print(';'.join(json.load(open('$W/r.json'))['pokes']))")"
FR="$(python3 -c "import json;print(json.load(open('$W/r.json'))['frames'])")"
FIELDS="ff8410:w:p1x,ff840b:b:p1face,ff845d:b:p1_5d,ff8459:b:p1_59,ff8585:b:p1_185,ff85b0:w:p1_1b0,ff8810:w:p2x,ff8970:b:p2_170,ff8971:b:p2_171,ff8984:b:p2_184,ff89ab:b:p2_1ab,ff8bb5:b:p2_3b5,ff885c:b:p2_5c,ff8926:b:p2_126,ff8850:w:p2hp,ff8854:b:p2cls,ff8782:b:id,ff8b82:b:p2id"
leg() {  # name set p2id
    mkdir -p "$W/$1"
    ( cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" REPLAY="$W/r.rpl" POKES="$(echo "$POKES" | sed "s/ff8b82:13/ff8b82:$3/g")" FIELDS="$FIELDS" FIELD_OUT="$W/$1/t.txt" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
      "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$1/l.log" 2>&1 ) </dev/null &
}
leg vs2 vsav2 13; leg vs2_anak vsav2 06; leg vsavj vsavj 01; leg vsavj_anak vsavj 06
wait
for l in vs2 vs2_anak vsavj vsavj_anak; do [ -s "$W/$l/t.txt" ] || bad "leg $l: no samples (see $W/$l/l.log)"; done

echo "== 4. the reduction vs the frozen lines"
: > "$W/got.txt"
for l in "vs2 vs2_data.bin 2797A 03,13" "vs2_anak vs2_data.bin 2797A 03,06" "vsavj vj_data.bin 2871C 03,01" "vsavj_anak vj_data.bin 2871C 03,06"; do
    set -- $l
    echo "## leg $1" >> "$W/got.txt"
    python3 tools/advancing_guard.py "$W/$1/t.txt" "$W/r.json" "$W/$2" "$3" --ids "$4" >> "$W/got.txt" || bad "reduce $1"
done
if [ "${FREEZE:-0}" = 1 ]; then cp "$W/got.txt" "$EXP"; echo "  FROZE  $EXP ($(wc -l < "$EXP" | tr -d ' ') lines)"; fi
if diff -u "$EXP" "$W/got.txt" > "$W/d.txt"; then ok "$(wc -l < "$W/got.txt" | tr -d ' ') lines identical to $EXP"; else bad "lines differ:"; head -30 "$W/d.txt"; fi

echo "== 5. the structural shape (verdicts from the values, not the frozen text)"
python3 - "$W/got.txt" <<'PY' || fail=1
import re, sys
legs = {}; cur = None
for l in open(sys.argv[1]):
    l = l.rstrip("\n")
    if l.startswith("## leg "): cur = l[7:]; legs[cur] = []; continue
    if not l or l.startswith("#") or l.startswith("spacer"): continue
    f = l.split("\t"); ev = f[0]; kv = dict(x.split("=", 1) for x in f[1:])
    legs[cur].append((ev, kv))
bad = 0
def chk(cond, msg):
    global bad
    print(("  ok    " if cond else "  FAIL  ") + msg); bad |= not cond
WEIGHT = {"LP": 1, "LK": 1, "MP": 2, "HP": 3, "HK": 3}; CLASS = {"LP": 0, "LK": 0, "MP": 1, "HP": 2, "HK": 2}
def button(ev):
    m = re.search(r"mash (LP|MP|HP|LK|HK)", ev); return m.group(1) if m else None
for leg, rows in legs.items():
    chk(len(rows) == 8, f"{leg}: 8 events reduced")
    chk(all(kv.get("block", "none") != "none" for _, kv in rows), f"{leg}: every attack was BLOCKED (the window opened)")
    chk(all(kv["win"] in ("13", "14") for _, kv in rows if "win" in kv), f"{leg}: the window opens at 14 (13 when two ticks share the frame)")
    ctl = [kv for ev, kv in rows if "no mash" in ev or "late" in ev]
    chk(all(kv.get("push", "none") == "none" and kv.get("counter") == "0" for kv in ctl), f"{leg}: the control and the late mash never count, never push")
    if leg.endswith("_anak"):
        chk(all(kv.get("push", "none") == "none" and kv.get("counter") == "0" for _, kv in rows), f"{leg}: ANAKARIS never counts and is never pushed")
        continue
    for ev, kv in rows:
        b = button(ev)
        if not b: continue
        vals = [int(v) for v in kv["counter"].split(",")]
        steps = [y - x for x, y in zip(vals, vals[1:]) if y]
        pushed = kv.get("push", "none") != "none"
        if leg == "vs2":
            chk(all(s == WEIGHT[b] for s in steps), f"{leg} {ev}: counter steps by the press weight {WEIGHT[b]} ({kv['counter']})")
            reached = max(vals) >= 10
            chk(pushed == reached, f"{leg} {ev}: push iff the counter reached 10 (max {max(vals)}, push={kv.get('push','none')})")
            if pushed: chk(max(vals) - WEIGHT[b] < 10 <= max(vals), f"{leg} {ev}: the push landed on the press that first reached 10")
        else:
            chk(all(s == 1 for s in steps), f"{leg} {ev}: counter steps by 1 per press ({kv['counter']})")
            if pushed: chk(max(vals) >= 3, f"{leg} {ev}: no push below a count of 3 (max {max(vals)})")
        if pushed:
            chk(kv["idx"] == str(CLASS[b]), f"{leg} {ev}: list index {kv['idx']} = the press's strength class {CLASS[b]}")
            chk(kv["list"] == "MATCH", f"{leg} {ev}: the attacker's per-frame steps equal list {kv['idx']} ({kv['steps']})")
            chk(kv["face"] == "1/0" and kv["steps"].endswith("px") and int(kv["steps"].split("/")[1][:-2]) < 0, f"{leg} {ev}: pushed AWAY (attacker faces right, steps negative)")
            chk(kv["flags"].split(",")[0] == "1", f"{leg} {ev}: the blocker's +0x184 set")
    # at least one push per game leg, or the rig is dead
    chk(any(kv.get("push", "none") != "none" for _, kv in rows), f"{leg}: the guard push FIRED at least once (rig liveness)")
sys.exit(bad)
PY

[ "$fail" -eq 0 ] && echo "PASS test_advancing_guard" || echo "FAIL test_advancing_guard"
exit "$fail"
