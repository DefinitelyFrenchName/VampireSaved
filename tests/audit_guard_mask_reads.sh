#!/bin/sh
# audit_guard_mask_reads.sh — WHICH LONGWORDS OF THE GUARD-MASH MASK TABLE
# `PRG:0x028D50` THE ENGINE READS, ours vs vanilla — and that the port's bytes
# in its FIRST longword sit behind an index the check never produces. (14z-145.)
#
# WHY: `PRG:0x028D50` carried THREE names — `effect_map_5051` (huitzil.toml),
# `hit_class_props_ext_hi` (donovan.toml) and the guard-MASH RNG mask table
# (atlas/ram.md +0x170, engine_internals "advancing guard") — and the open-items
# list asked which is right. MEASURED 14z-145, static first: ALL THREE ARE, at
# ONE address, because TWO TABLES OVERLAP by Capcom's own layout.
#   * the per-id byte map at `PRG:0x028D00` (vs2 `0x027FD8`) — 64 `lea (pc)`
#     readers in vsavj `0x02392A-0x025F16`, the reaction/effect handlers. vsavj
#     populates ids 0x00-0x4A; vs2 grew it to 0x53 (ids 0x4E-0x53 = 0F 1B 1F 19
#     0F 03) and the port copies those six bytes to `0x028D4E-0x028D53` — that
#     is what both manifest names describe, and their bytes are identical.
#   * the guard-mash mask table at `PRG:0x028D50`: EIGHT longwords, index =
#     the press count * 4 (`0x027616 lea $28d50(pc),a0 ; move.l (a0,d0.w),d2`,
#     the ONE reader in the whole image), then `btst d0,d2` on RNG & 31 —
#     popcounts 0/0/0/8/16/24/32/32 = "3: 8/32, 4: 16/32, 5: 24/32, 6+: always".
#     vs2's own check uses press WEIGHTS and reads no table; its copy of the
#     table (`0x02802C`, one longword shorter) is dead.
#   So vsavj's map entries 0x50-0x53 ARE mask[0] — and the port fills them.
#   mask[0] is read only if the count is 0 at the read, and the count is
#   PRE-INCREMENTED (`addq.b #1,$170(a6)` at `0x027606`, cleared by the
#   block-entry handler at `0x024AF2/0x024B1A`, capped by the arm at 8): the
#   index is 1..7 by construction. STATIC. This gate is the in-emulator half.
#
# WHAT IT MEASURES: the advancing-guard rig (tests/replays/naming/
# donovan_victim_4.rpl — Victor 5MP/5HP into a blocking, mashing Demitri; the
# same legacy pairing test_advancing_guard runs on vsavj) under a -debug READ
# watch over `0x028D50-0x028D6F`, on pristine vsavj AND on the merged build.
#   1. LIVENESS: reads happen on both legs (a blind watch reads as FAIL, not
#      as "never used" — [MFI-15]/[VSP-22]); a `DUMPS` of the same bytes through
#      the same program space shows vanilla 00000000 and ours 1F190F03 at +0.
#   2. ONE READER IN PLAY: every hit after the forced-pick frame is the mash
#      check (PC 0x02761E, the post-instruction PC MAME reports for the move.l
#      at 0x02761A) with A0 = 0x028D50; the boot self-test's ROM sweep also
#      passes through the range (PCs 0x926 / 0x122C, arbitrary D0) and is
#      reported, never judged — it is before the match by construction. SO IS
#      THE GATE'S OWN `DUMPS` READ: a Lua space read through the watched range
#      logs ONE hit at dump-frame+1 with whatever PC the CPU was at (measured:
#      DUMPS at 2000 -> a hit at 2001, PC 0x122C), so the dump is taken at
#      frame 1200, inside the boot window, and never at a match frame.
#   3. OFFSET 0 IS NEVER READ: every D0 is in {4,8,...,28}.
#   4. OURS == VANILLA: the per-offset hit inventory is identical (the legacy
#      path runs the same mash on the same frames — the superset invariant
#      seen from the table's side).
#   5. must-fire control on the reducer: a synthetic hit at offset 0 FAILS.
# NOT frozen: the inventory is printed, equality is the assertion.
#
# THE TRAP THIS RIG AVOIDS: the read is `(a0,d0.w)`, a plain data access, so
# the PROGRAM-space watch sees it; a `(d16,pc,Dn)` read would need `,o`
# (tests/lua/trace_writes.lua header). If section 1 ever reports zero hits,
# the FIRST suspect is the space, not the table.
#
# Emulator tier (MAME -debug, two ~4 min legs in parallel). Usage:
#   ROMDIR=... [MAME_BIN=$HOME/.cache/vampire-saved/mame/cps2] \
#     [MERGED=build/m3b_merged26] [KEEP=dir] tests/audit_guard_mask_reads.sh
#   (KEEP copies the traces and dumps out before the workdir is removed.)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
: "${ROMDIR:?set ROMDIR}"
MERGED="${MERGED:-build/m3b_merged26}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "FAIL: MAME_BIN=$MAME_BIN is not executable (tools/setup_mame.sh)"; exit 1; }
[ -f "$MERGED/rompath/vsavjw.zip" ] || { echo "FAIL: no $MERGED/rompath/vsavjw.zip — set MERGED to the current merged build"; exit 1; }
W="$(mktemp -d "${TMPDIR:-/tmp}/gmask.XXXXXX")"
if [ -n "${KEEP:-}" ]; then mkdir -p "$KEEP"; trap 'cp -R "$W"/. "$KEEP"/ 2>/dev/null; rm -rf "$W"' EXIT; else trap 'rm -rf "$W"' EXIT; fi
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
RIG=tests/replays/naming/donovan_victim_4
echo "== build under test: $MERGED  $(python3 tools/build_fingerprint.py "$MERGED/rompath" --set vsavjw --sha-only | cut -c1-8)"

echo "== 0. the rig (test_advancing_guard's vsavj leg: P1 Victor 0x03, P2 Demitri 0x01)"
POKES="$(python3 -c "import json;print(';'.join(json.load(open('$RIG.json'))['pokes']))" | sed 's/ff8b82:13/ff8b82:01/g')"
FR="$(python3 -c "import json;print(json.load(open('$RIG.json'))['frames'])")"
ok "replay $RIG.rpl, $FR frames, $(echo "$POKES" | tr ';' '\n' | grep -c '^') pokes"

echo "== 1. the two legs under the read watch (parallel)"
leg() {  # name set rompath
    mkdir -p "$W/$1"
    ( cd "$W/$1" && WATCH="28d50,20,r" TRACE_OUT="$W/$1/t.txt" FRAMES="$FR" REPLAY="$REPO/$RIG.rpl" POKES="$POKES" \
        DUMPS="1200:28d50-28d70" MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" \
        "$REPO/tools/run_mame.sh" "$2" -debug -debugger none -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
        > "$W/$1/l.log" 2>&1 ) </dev/null &
}
leg vanilla vsavj "$ROMDIR"; leg ours vsavjw "$REPO/$MERGED/rompath;$ROMDIR"
wait
for l in vanilla ours; do
    [ -s "$W/$l/t.txt" ] || bad "leg $l: no trace (see $W/$l/l.log)"
    grep -q '^END' "$W/$l/t.txt" || bad "leg $l: the run did not reach END"
    d="$W/$l/dump_1200_28d50.bin"
    [ -s "$d" ] || bad "leg $l: no DUMPS artifact"
done
[ "$fail" = 0 ] || exit 1

echo "== 2. the bytes the engine sees (program space, the same one the read uses)"
python3 - "$W" <<'PY' || fail=1
import sys
w = sys.argv[1]; bad = 0
def chk(c, m):
    global bad
    print(("  ok    " if c else "  FAIL  ") + m); bad |= not c
van = open(f"{w}/vanilla/dump_1200_28d50.bin", "rb").read(); our = open(f"{w}/ours/dump_1200_28d50.bin", "rb").read()
L = lambda b: [int.from_bytes(b[4*i:4*i+4], "big") for i in range(8)]
chk(L(van) == [0, 0, 0, 0xFF, 0xFFFF, 0xFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF], f"vanilla mask table = {[hex(x) for x in L(van)]}")
chk(L(our)[0] == 0x1F190F03, f"ours mask[0] = {L(our)[0]:08x} — the port's map entries 0x50-0x53 (vs2's own bytes)")
chk(L(our)[1:] == L(van)[1:], "ours mask[1..7] == vanilla (the live entries are untouched)")
sys.exit(bad)
PY

echo "== 3. the reads: one reader, offsets 4..28 only, ours == vanilla"
python3 - "$W" <<'PY' || fail=1
import sys, collections
w = sys.argv[1]; bad = 0
def chk(c, m):
    global bad
    print(("  ok    " if c else "  FAIL  ") + m); bad |= not c
def hits(path):
    out = []
    for l in open(path):
        f = l.split()
        if not f or f[0] != "frame": continue
        fr, pc = int(f[1]), int(f[3], 16); regs = {f[i]: int(f[i+1], 16) for i in range(4, len(f) - 1, 2)}
        if pc == 0 and all(v == 0 for v in regs.values()): continue   # the arming artefact, frame 1
        out.append((fr, pc, regs["A0"], regs["D0"] & 0xFFFF))
    return out
CHECK_PCS = {0x02761A, 0x02761E}   # the move.l at 0x02761A; MAME reports the post-instruction PC
MATCH_FROM = 1400                   # the forced-pick pokes start here; everything before is boot
def reduce(h):
    fails = []
    if not h: fails.append("zero hits — the watch is blind or the rig never blocked (LIVENESS)")
    chk_hits = [x for x in h if x[1] in CHECK_PCS]
    other = [x for x in h if x[1] not in CHECK_PCS]
    # any OTHER reader of the range must be the boot self-test's ROM sweep — before the match
    late = [(fr, pc) for fr, pc, _, _ in other if fr >= MATCH_FROM]
    if late: fails.append(f"another reader touches the table IN PLAY: {[(f, hex(p)) for f, p in late][:4]}")
    if h and not chk_hits: fails.append("the mash check never read the table (LIVENESS of the rig)")
    if any(a0 != 0x028D50 for _, _, a0, _ in chk_hits): fails.append("a check hit with A0 != 0x028D50")
    offs = collections.Counter(d0 for _, _, _, d0 in chk_hits)
    if 0 in offs: fails.append(f"OFFSET 0 READ {offs[0]} time(s) — mask[0] IS reachable, the port's bytes are LIVE")
    if any(o % 4 or o > 28 for o in offs): fails.append(f"an offset outside 4..28 step 4: {sorted(offs)}")
    boot = collections.Counter(pc for fr, pc, _, _ in other if fr < MATCH_FROM)
    return fails, offs, boot
res = {}
for leg in ("vanilla", "ours"):
    h = hits(f"{w}/{leg}/t.txt"); fs, offs, boot = reduce(h); res[leg] = (fs, offs)
    inv = ", ".join(f"+{o:#x}(count {o//4}) x{n}" for o, n in sorted(offs.items()))
    bs = ", ".join(f"PC {pc:#x} x{n}" for pc, n in sorted(boot.items()))
    print(f"  {leg}: {len(h)} hits; the check's inventory: {inv or '-'}; boot-time sweep readers: {bs or '-'}")
    for f in fs: chk(False, f"{leg}: {f}")
    if not fs: chk(True, f"{leg}: every in-play read is the mash check, A0 = 0x028D50, offset in 4..28 — mask[0] NEVER read")
chk(res["vanilla"][1] == res["ours"][1], "ours == vanilla: identical per-offset inventory (legacy pairing, same frames)")
# 5. must-fire control on the reducer — a synthetic offset-0 hit must FAIL it
fs, _, _ = reduce([(3000, 0x02761E, 0x028D50, 0)])
chk(any("OFFSET 0 READ" in f for f in fs), "control: a synthetic read at offset 0 is caught")
fs, _, _ = reduce([])
chk(any("LIVENESS" in f for f in fs), "control: an empty trace is a FAIL, not a clean null")
fs, _, _ = reduce([(3000, 0x000926, 0x000000, 0x1234)])
chk(any("IN PLAY" in f for f in fs), "control: a foreign reader during the match is caught")
sys.exit(bad)
PY

if [ "$fail" = 0 ]; then echo "PASS: audit_guard_mask_reads — mask[0] is unreachable on both legs; the port's bytes there are inert on the legacy path"; exit 0; fi
echo "FAIL: audit_guard_mask_reads"; exit 1
