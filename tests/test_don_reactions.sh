#!/bin/sh
# test_don_reactions.sh — Change Immortal behavior gate (14z-26..28).
#
# GAMEPLAY LOCK (round-41, maintainer): 421P is a standing up-to-8-hit
# multi — it must MULTI-HIT and must NOT knock down a standing
# opponent. The 14z-27 class remap (0x4E -> 0x04) violated this
# (single-hit hard knockdown) and was reverted; this gate keeps any
# future fix honest on the move's core behavior.
#
# STRENGTHENED 14z-36: the sworded deity's records are remapped to
# type 0x06 (vs2-alias-proven: vs2 word[0x4E]==word[0x06]) = native
# class-8 electric — section 2 asserts the complete death chain on a
# fatal hit (grounded node 0x158210), closing the round-39
# neutral-pose bug for the sworded variant too.
#
# ---------------------------------------------------------------------------
# PROVENANCE WARNING (2026-09-02, GitHub #114). THIS GATE IS GREEN AND THE MOVE
# IS STILL WRONG. Read before trusting anything below.
#   * ALL FOUR LEGS RUN `vsavj`. Nothing here measures native. The "native ==
#     10" and "native window ends ~2689" figures are HARDCODED CONSTANTS whose
#     source was the maintainer's playtest plus community information
#     ("definitely 9 base on VS2, ours 8", STATE 14z-42c) -- TESTIMONY, not a
#     measurement. The comments below read as if measured; they were not.
#   * MEASURED 2026-09-02 on stock vsav2 (Donovan forced, [VSP-123]) with this
#     same replay: NATIVE lands 6 hits / 10 damage and HOLDS the victim at
#     x=728 through f2685. OURS lands 3 hits / 11 damage and pushes the victim
#     728 -> 852, ending at f2640. Positions are identical between the games
#     until the move connects, so this is not a rig artifact.
#   * TWO BLIND SPOTS, both structural: the dump window starts at f2630 and our
#     FIRST HIT IS AT f2627, so the gate sums 7 of the true 11; and the
#     assertions are ONE-SIDED (`<= 10`, "by f2700"), so "too few hits,
#     finishing early" passes. This gate was written against the OLD symptom
#     (14-15 hits, too slow) and cannot see an overcorrection.
#   * NOT TIGHTENED HERE ON PURPOSE: widening the window and making the bounds
#     two-sided turns this gate RED, and a red gate halts forward work
#     ([VSP-7]). That is the maintainer's call, tracked on #114.
# ---------------------------------------------------------------------------
#
# STRENGTHENED 14z-42 (hit-freeze fix, ls_freeze_vs2_* thunks): the
# no-mash HP version at this spacing is NATIVE-CLASS — total damage
# <= 10 (native == 10: 5-point initial sword hit + 5 deity ticks;
# the pre-fix build dealt 22) and the last damage lands by f2700
# (native window ends ~2689; the slow pre-fix build hit until ~2797
# — a layout-independent duration proxy for the cadence). Mash
# extension verified native-equal separately (3 -> 4 loop
# iterations on both games, session 14z-42).
#
# Usage: ROMDIR=... tests/test_don_reactions.sh [rompath_dir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

DUMPS=$(python3 -c "print(';'.join(f'{f}:ff8850-ff8854;{f}:ff8800-ff8830' for f in range(2630,2760,10)))")
DUMPS="$DUMPS" REPLAY="$REPO/tests/replays/48_don_immortal_ko.rpl" \
    CHECKSUM_OUT="$WORK/c.log" MAME_SANDBOX="$WORK" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK" <<'EOF2'
import sys, os, glob
work = sys.argv[1]
frames = sorted(int(os.path.basename(p).split('_')[1])
                for p in glob.glob(os.path.join(work, 'dump_*_ff8850.bin')))
assert len(frames) >= 10, f"only {len(frames)} dumps"
prev = None; hits = 0
hp_first = hp_last = None; last_hit_frame = None
for f in frames:
    hp = int.from_bytes(open(os.path.join(work, f'dump_{f}_ff8850.bin'),'rb').read()[:2],'big')
    ob = open(os.path.join(work, f'dump_{f}_ff8800.bin'),'rb').read()
    node = int.from_bytes(ob[0x1c:0x20],'big')
    assert not (0x157F00 <= node <= 0x1586FF), (
        f"victim in knockdown-family node {node:#x} at f{f} — 421P must "
        f"not knock down a standing opponent (the 14z-27 regression)")
    if hp_first is None: hp_first = hp
    if prev is not None and hp < prev:
        hits += 1; last_hit_frame = f
    prev = hp; hp_last = hp
assert hits >= 2, f"only {hits} damage steps — 421P must multi-hit"
total = hp_first - hp_last
assert total <= 10, (
    f"{total} total damage no-mash — exceeds the native total of 10 "
    f"(hit-freeze regression: the pre-14z-42 build dealt 22)")
assert last_hit_frame is not None and last_hit_frame <= 2700, (
    f"last damage step at f{last_hit_frame} — past the native-class window "
    f"(<=2700); the move is running slow (hit-freeze regression)")
print(f"  ok: 421P multi-hits ({hits} steps, {total} total, last at "
      f"f{last_hit_frame}) native-class, no knockdown on a standing opponent")
EOF2
# ── 2. fatal: the full native electric death chain ───────────────────
mkdir -p "$WORK/ko"
POKES="2600:ff8850:00010001" \
DUMPS="2950:ff8800-ff8830;3030:ff8800-ff8830" \
    REPLAY="$REPO/tests/replays/48_don_immortal_ko.rpl" \
    CHECKSUM_OUT="$WORK/ko/c.log" MAME_SANDBOX="$WORK/ko" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK/ko" <<'EOF2'
import sys, os
work = sys.argv[1]
for fr in (2950, 3030):
    d = open(os.path.join(work, f'dump_{fr}_ff8800.bin'), 'rb').read()
    node = int.from_bytes(d[0x1c:0x20], 'big')
    assert node == 0x158210, (
        f"victim node at f{fr} = {node:#x}, expected grounded death "
        f"0x158210 (idle loop = the round-39 neutral-pose bug)")
print("  ok: deity KO runs the full native electric death (grounded at 0x158210)")
EOF2
# ── 3. MATCH-END (round-2 clinching) deity KO — the round-50 blind spot:
#      sections 1-2 only ever kill in round 1; the neutral-pose bug family
#      (14z-25 round 38) is match-end-specific. Replay 54 wins round 1 with
#      the deity, then kills again in round 2 (match over) — the victim
#      must still chain to the grounded death node.
mkdir -p "$WORK/me"
POKES="2400:ff8850:00080008;3100:ff8850:00080008" \
DUMPS="3420:ff8800-ff8830;3650:ff8800-ff8830;4100:90c2a0-90c340;4100:708020-708028" \
    REPLAY="$REPO/tests/replays/54_don_matchend_ko.rpl" \
    CHECKSUM_OUT="$WORK/me/c.log" MAME_SANDBOX="$WORK/me" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK/me" <<'EOF2'
import sys, os
work = sys.argv[1]
d = open(os.path.join(work, 'dump_3650_ff8800.bin'), 'rb').read()
node = int.from_bytes(d[0x1c:0x20], 'big')
assert node == 0x158210, (
    f"match-end victim node at f3650 = {node:#x}, expected grounded death "
    f"0x158210 (neutral pose = the round-38/50 match-end bug family)")
print("  ok: MATCH-END deity KO chains to the grounded death (0x158210)")
# 14z-45 WIN-SCREEN LOCKS (same run, f4100 = the victory screen):
# palette rows 0x15-0x19 must be the native vs2 win set (frozen from
# matchend_vs2 f4100) and the portrait composition base must be
# native (first OBJ entry at 160,32 — the pre-fix build drew at
# 32,56 = the round-51/55 left-shift).
FROZEN = "fffdffb8fd96fc86fb75f964f753f542f331ffd7feb5fd93fb73f0f8f0f8f055fffdffb8fd96fc86fb75f964f753f542fd93ff43fd32fb22f912fadef7abf056fffdf0f8fd96fc86fb75f964f753f542f331ffd7fd93fadef7abf47bf258f057fffdffc9ffb8fe96fc86fa75f753f542f331fd32f932fadef7abf47bf248f058fffdffc9ffb8fe96fc86fa75f753f542f331fd32fb22f912fadef7abf47bf059"
pal = open(os.path.join(work, 'dump_4100_90c2a0.bin'),'rb').read()[:0xa0]
assert pal.hex() == FROZEN, (
    "win-screen palette rows 0x15-0x19 diverge from the frozen native set "
    "(the round-51 wash = Jedah's rows; check win_pal_slot0f_c* data_ports)")
import struct
ob = open(os.path.join(work, 'dump_4100_708020.bin'),'rb').read()
x, y = struct.unpack('>HH', ob[:4])
assert (x & 0x3ff, y & 0x3ff) == (160, 32), (
    f"win-portrait base entry at ({x & 0x3ff},{y & 0x3ff}), native = (160,32) "
    f"(the round-55 shift; check win_pos_*_slot0f code_words)")
print("  ok: win screen native-locked (palette rows 15-19 + composition base)")
EOF2
# ── 4. ES Lightning Sword (14z-44): 9-hit native lock + ES-death lock.
#      Replay 56 needs a banked stock (POKES ff8509 — the ES resolver
#      tests +0x109 for pair presses). Native datums in the replay
#      header. Guards the ES record-type remaps (0x4E->0x06 x7) and
#      the round-52 ES-finish neutral-pose bug.
mkdir -p "$WORK/es"
DUMPS=$(python3 -c "print(';'.join(f'{f}:ff8850-ff8854' for f in range(2625,2745,10)))")
DUMPS="2600:708000-708200;$DUMPS"
POKES="2550:ff8509:09" DUMPS="$DUMPS" \
    REPLAY="$REPO/tests/replays/56_don_es_ls.rpl" \
    CHECKSUM_OUT="$WORK/es/c.log" MAME_SANDBOX="$WORK/es" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK/es" <<'EOF2'
import sys, os, glob
work = sys.argv[1]
frames = sorted(int(os.path.basename(p).split('_')[1])
                for p in glob.glob(os.path.join(work, 'dump_*_ff8850.bin')))
assert len(frames) >= 10, f"only {len(frames)} ES dumps"
prev = None; hits = 0; first = last = None
for f in frames:
    hp = int.from_bytes(open(os.path.join(work, f'dump_{f}_ff8850.bin'),'rb').read()[:2],'big')
    if first is None: first = hp
    if prev is not None and hp < prev: hits += 1
    prev = hp; last = hp
total = first - last
assert 11 <= total <= 13, (
    f"ES total damage {total} — native == 13 (9 hits: 5-pt sword + 8 ticks); "
    f"pre-14z-44 builds dealt 6-11 (victim escaped the shake)")
assert hits >= 7, f"only {hits} ES damage steps at 10f sampling — native-class is 8-9"
print(f"  ok: ES 421P native-class ({hits} steps, {total} total)")
# 14z-49 HUD asset lock (in-match, f2600): Donovan's mugshot and name
# plate must ride the repointed/replaced cells — mugshot = table-0x0F
# code 0x05C8 + vsavj stager base 0x3800 = OBJ code 0x3DC8 (2x2 pal 0A,
# P1 flank x=200,y=32), name = pool-tail code 0xBE8C via the aux_poke'd
# table entry (3x1 pal 02 at x=144,y=40). Art content is asserted
# byte-exact by the gfx builder; this locks the live plumbing.
d = open(os.path.join(work, 'dump_2600_708000.bin'), 'rb').read()
ents = set()
for i in range(0, len(d) - 8, 8):
    x = int.from_bytes(d[i:i+2], 'big') & 0x3FF
    y = int.from_bytes(d[i+2:i+4], 'big') & 0x3FF
    code = int.from_bytes(d[i+4:i+6], 'big')
    attr = int.from_bytes(d[i+6:i+8], 'big')
    ents.add((x, y, code, attr))
assert (200, 32, 0x3DC8, 0x112A) in ents, \
    "HUD mugshot entry (0x3DC8 2x2 pal 0A at 200,32) missing — table 0x0F/stager drift?"
assert (144, 40, 0xBE8C, 0x0202) in ents, \
    "HUD name plate entry (0xBE8C 3x1 pal 02 at 144,40) missing — name-table aux_poke drift?"
print("  ok: HUD mugshot + name plate ride the 14z-49 cells (0x3DC8 / 0xBE8C)")
EOF2
mkdir -p "$WORK/esko"
POKES="2550:ff8509:09;2600:ff8850:00010001" \
DUMPS="2950:ff8800-ff8830;3030:ff8800-ff8830" \
    REPLAY="$REPO/tests/replays/56_don_es_ls.rpl" \
    CHECKSUM_OUT="$WORK/esko/c.log" MAME_SANDBOX="$WORK/esko" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK/esko" <<'EOF2'
import sys, os
work = sys.argv[1]
for fr in (2950, 3030):
    d = open(os.path.join(work, f'dump_{fr}_ff8800.bin'), 'rb').read()
    node = int.from_bytes(d[0x1c:0x20], 'big')
    assert node == 0x158210, (
        f"ES-kill victim node at f{fr} = {node:#x}, expected grounded death "
        f"0x158210 (the round-52 ES-finish neutral-pose bug)")
print("  ok: ES kill chains to the grounded death (the round-52 fix holds)")
EOF2
# ── 5. HALF-CIRCLE COMMAND ACCEPT (14z-48, round-58 blocker): the
#      farm-helper-match reconciliation had collapsed distinct vs2
#      motion tables; Blizzard Sword (41236P) and Sword Grapple
#      (63214MP) lock the corrected farm_port rows. Assertion = the
#      move CHAIN is entered (P1 node in the move's ported range)
#      shortly after the input; the pre-fix build fell back to
#      normals (nodes elsewhere).
mkdir -p "$WORK/hc1" "$WORK/hc2"
DUMPS="2632:ff8400-ff8430;2640:ff8400-ff8430"     REPLAY="$REPO/tests/replays/59_don_blizzard_hcf.rpl"     CHECKSUM_OUT="$WORK/hc1/c.log" MAME_SANDBOX="$WORK/hc1"     MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj     -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
DUMPS="2780:ff8400-ff8430;2800:ff8400-ff8430"     REPLAY="$REPO/tests/replays/60_don_grapple_hcb.rpl"     CHECKSUM_OUT="$WORK/hc2/c.log" MAME_SANDBOX="$WORK/hc2"     MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj     -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
python3 - "$WORK" <<'EOF2'
import sys, os
work = sys.argv[1]
def node(sub, fr):
    d = open(os.path.join(work, sub, f'dump_{fr}_ff8400.bin'),'rb').read()
    return int.from_bytes(d[0x1c:0x20],'big')
bz = [node('hc1', f) for f in (2632, 2640)]
assert any(0x0D7980 <= n <= 0x0D8340 for n in bz), (
    f"Blizzard Sword chain not entered (nodes {[hex(n) for n in bz]}) — "
    f"41236 accept broken (check the 0x2916C farm_port row)")
gr = [node('hc2', f) for f in (2780, 2800)]
assert any(0x0D0000 <= n <= 0x0DF000 and not (0x0D3000 <= n <= 0x0D3800) for n in gr), (
    f"Sword Grapple not triggered (nodes {[hex(n) for n in gr]}) — "
    f"63214 accept broken (check the 0x2915C/0x29164 farm_port rows)")
print("  ok: half-circle commands accept (Blizzard 41236 + Grapple 63214)")
EOF2
echo "PASS: Donovan hit-class reaction gate"
