#!/bin/sh
# audit_ladder_pick_store.sh — +0x382 IS THE CHARACTER ID, AND THE 1P ARCADE LADDER WRITES THE CPU SIDE'S BEFORE IT LOADS: the measurements that retracted 14z-87's "voice-class borrow" (GitHub #195, #202; 14z-188), on pristine vsavj.
#
# WHAT: the routine 14z-87 named a "voice-class borrow" (store PRG:0x0AEF6) is the arcade ladder's opponent pick. On a CPU
#   flow it writes the CPU side's +0x382 once, before that fighter loads; a value poked there BEFORE the store is
#   overwritten by the draw, one poked AFTER it is the character that loads (the hitbox base +0x60 names it); and a 2P
#   match never runs the store. A game fact, so it is measured on pristine vsavj, no build involved.
# HOW: rig 90 (tests/replays/don/90_don_plant.rpl — its own header: it never forms its match and times out into a CPU
#   game, P1 the CPU side) on MAME, five legs: a non-debug PC-attributed write tap on both players' +0x382
#   (tests/lua/read_tap.lua); fighter-block dumps at f3460/f3470/f4200 unpoked, with 0x03 (Victor) poked at f3300
#   (before the store) and at f3480 (after it); and the same tap over a 2P replay (tests/replays/16_xemu_2p.rpl). The
#   loaded character is named by its +0x60 against the 16 legacy rows of tests/expected/roster_pairings/bases.tsv
#   (byte-identical in vanilla vsavj, that file's header).
# EXPECTS: rig 90 — exactly one in-play write to $FF8782, by the store PC, between f3460 and f3470, and none to $FF8B82
#   by it; unpoked, P1's +0x60 at f4200 is the base of the character its +0x382 names; poked before, +0x382 reads 0x03
#   at f3460 and the unpoked leg's drawn value at f3470, and P1 loads as the unpoked leg's character; poked after, P1
#   loads as Victor. The 2P replay — boot-POST writes seen (liveness) and no write by the store PC. Every control fails.
# FOLLOWS: emu/mame-patches/ tests/expected/roster_pairings/bases.tsv tests/lib/controls.sh tests/lua/read_tap.lua
#   tests/lua/replay.lua tests/replays/16_xemu_2p.rpl tests/replays/don/90_don_plant.rpl tools/run_mame.sh
#   tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: store-pc-moved — the tap checks run with the store PC moved off 0x0AEF6 must fail rig 90's one-write check, so the writer is attributed by its PC, not merely counted (in-gate: on the real tap log; mode: the PC moved and the gate FAILs)
# MUST-FIRE: perturbed-copy: poke-legs-swapped — the dump checks run with the before- and after-poke legs exchanged must fail, so "before is overwritten, after is loaded" is something the checks can refuse (in-gate: on the real dumps; mode: exchanged and the gate FAILs)
# MUST-FIRE: perturbed-copy: base-misnamed — the dump checks run with every legacy base reassigned to the next character must fail, so the loaded character is named by its +0x60 (in-gate: on the real dumps; mode: reassigned and the gate FAILs)
#
# NOT COVERED: a real 1P arcade run (rig 90's flow is one CPU match, P1 the CPU side); later rungs, continues, a
#   challenger joining; the keep-tenant thunk our builds add at this store (GitHub #202 — this gate runs pristine vsavj);
#   the draw's value itself (never frozen: the ladder's draw is state-fed).
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] tests/audit_ladder_pick_store.sh
#   emulator tier, MAME; ~2 min (5 legs in parallel)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
R90="$REPO/tests/replays/don/90_don_plant.rpl"; R2P="$REPO/tests/replays/16_xemu_2p.rpl"
D="3460:ff8400-ff8bff;3470:ff8400-ff8bff;4200:ff8400-ff8bff"

tapleg() {  # tapleg <name> <rpl> <frames>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$2" RTAP="ff8782,2;ff8b82,2" WINDOW="2000,$3" \
        TRACE_OUT="$W/$1.txt" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/read_tap.lua" \
        > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true   # a teardown segfault (MFI-12): the END line decides
}
dumpleg() {  # dumpleg <name> <pokes>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$R90" POKES="$2" DUMPS="$D" CHECKSUM_OUT="$d/cs.log" \
        FRAMES=4210 "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true   # the dumps decide
}
echo "== 1. the legs (pristine vsavj, MAME)"
tapleg tap90 "$R90" 4300 & tapleg tap2p "$R2P" 4300 &
dumpleg unpoked "" & dumpleg before "3300:ff8782:03" & dumpleg after "3480:ff8782:03" &
wait
fail=0
for t in tap90 tap2p; do grep -q '^END ' "$W/$t.txt" 2>/dev/null || { echo "  FAIL  $t: no END line (see $W/$t/mame.log) — VOID"; fail=1; }; done
for l in unpoked before after; do for f in 3460 3470 4200; do
    [ -f "$W/$l/dump_${f}_ff8400.bin" ] || { echo "  FAIL  $l: no dump at f$f (see $W/$l/mame.log) — VOID"; fail=1; }
done; done
[ "$fail" = 0 ] || { echo "FAIL: audit_ladder_pick_store (a leg did not complete)"; exit 1; }
echo "  ok    five legs complete"

check() {  # check <store pc> <before leg> <after leg> <base rotation> — prints ok/FAIL lines, exits 1 on any FAIL
    python3 - "$W" "$1" "$2" "$3" "$4" "$REPO/tests/expected/roster_pairings/bases.tsv" <<'PY'
import re, sys
W, store, before, after, rot, bases_p = sys.argv[1], int(sys.argv[2], 16), sys.argv[3], sys.argv[4], int(sys.argv[5]), sys.argv[6]
bad = []
def ok(m): print(f"  ok    {m}")
def no(m): print(f"  FAIL  {m}"); bad.append(m)
def writes(p):
    out = []
    for ln in open(p):
        m = re.match(r"W (\d+) PC (\w+) off (\w+) data (\w+) mask (\w+)", ln)
        if m: out.append((int(m.group(1)), int(m.group(2), 16), m.group(3), int(m.group(4), 16), int(m.group(5), 16)))
    return out
W90, W2P = writes(f"{W}/tap90.txt"), writes(f"{W}/tap2p.txt")
by_store = lambda ws: [w for w in ws if w[0] > 2000 and w[1] in (store, store + 4)]
p1 = [w for w in by_store(W90) if w[2] == "ff8782"]
p2 = [w for w in by_store(W90) if w[2] == "ff8b82"]
if len(p1) == 1 and 3460 < p1[0][0] < 3470: ok(f"rig 90: one in-play write to $FF8782 by the store, f{p1[0][0]} PC {p1[0][1]:#x}")
else: no(f"rig 90: in-play writes to $FF8782 by PC {store:#x}: {[(f, hex(pc)) for f, pc, *_ in p1]} (want exactly one, f3460-f3470)")
if not p2: ok("rig 90: no write to $FF8B82 by the store")
else: no(f"rig 90: the store wrote $FF8B82: {p2}")
if any(pc in (0xD34, 0xD3A, 0xDD8) for _, pc, *_ in W2P): ok("2P replay: boot-POST writes seen (the tap is live)")
else: no("2P replay: no boot-POST writes — dead instrument")
if not by_store(W2P): ok("2P replay: no write by the store PC")
else: no(f"2P replay: the store ran: {by_store(W2P)}")
B = {}
for ln in open(bases_p):
    if ln.startswith("#") or not ln.strip(): continue
    c, n, b = ln.split("\t")[:3]
    if int(c, 16) < 0x10: B[int(c, 16)] = (n, int(b, 16))
cl = sorted(B)
if rot: B = {c: (B[c][0], B[cl[(i + 1) % len(cl)]][1]) for i, c in enumerate(cl)}
name_of = {b: n for n, b in B.values()}
def blk(leg, f):
    b = open(f"{W}/{leg}/dump_{f}_ff8400.bin", "rb").read()[:0x400]
    return b[0x382], int.from_bytes(b[0x60:0x64], "big")
u70, u = blk("unpoked", 3470)[0], blk("unpoked", 4200)
want = B.get(u[0], ("?", None))
if u[1] == want[1]: ok(f"unpoked: P1 +0x382 {u[0]:#04x} at f4200 and +0x60 {u[1]:#010x} name the same character ({want[0]})")
else: no(f"unpoked: P1 +0x382 {u[0]:#04x} names {want[0]} but +0x60 {u[1]:#010x} is {name_of.get(u[1], '?')}")
b60, b70, b = blk(before, 3460)[0], blk(before, 3470)[0], blk(before, 4200)
if b60 == 0x03 and b70 == u70 and b[1] == u[1]:
    ok(f"poked 0x03 before the store: 0x03 at f3460, the draw {b70:#04x} at f3470, P1 loads as {name_of.get(b[1], '?')} like the unpoked leg")
else: no(f"poked before the store: f3460 {b60:#04x} (want 0x03), f3470 {b70:#04x} (want {u70:#04x}), f4200 +0x60 {b[1]:#010x} (want {u[1]:#010x})")
a = blk(after, 4200)
if a[0] == 0x03 and a[1] == B[0x03][1]: ok(f"poked 0x03 after the store: P1 loads as {B[0x03][0]} (+0x60 {a[1]:#010x})")
else: no(f"poked after the store: f4200 +0x382 {a[0]:#04x}, +0x60 {a[1]:#010x} = {name_of.get(a[1], '?')} (want 0x03, {B[0x03][0]})")
sys.exit(1 if bad else 0)
PY
}
echo "== 2. the checks"
PC=0AEF6; BEF=before; AFT=after; ROT=0
vs_ctl_is store-pc-moved && PC=0AEF0
vs_ctl_is poke-legs-swapped && { BEF=after; AFT=before; }
vs_ctl_is base-misnamed && ROT=1
check "$PC" "$BEF" "$AFT" "$ROT" || fail=1

echo "== 3. the controls"
if check 0AEF0 before after 0 > /dev/null 2>&1; then vs_ctl_dead store-pc-moved "the checks pass with the store PC moved" || fail=1
else vs_ctl_fired store-pc-moved "the checks refuse rig 90's write once the store PC is moved"; fi
if check 0AEF6 after before 0 > /dev/null 2>&1; then vs_ctl_dead poke-legs-swapped "the checks pass with the poke legs exchanged" || fail=1
else vs_ctl_fired poke-legs-swapped "the checks refuse the exchanged poke legs"; fi
if check 0AEF6 before after 1 > /dev/null 2>&1; then vs_ctl_dead base-misnamed "the checks pass with every base reassigned" || fail=1
else vs_ctl_fired base-misnamed "the checks refuse the reassigned bases"; fi

[ "$fail" = 0 ] && echo "PASS: audit_ladder_pick_store" || { echo "FAIL: audit_ladder_pick_store"; exit 1; }
