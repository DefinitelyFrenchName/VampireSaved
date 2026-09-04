#!/bin/sh
# audit_ff0460_writer.sh — who writes RAM:$FF0460, and with what values?
#
# ON-DEMAND (1 FBNeo run, ~1 min). The measurement behind the 14z-82 atlas
# row: $FF0460 is the SOUND DRIVER's current-record pointer spill, written
# by the dispatch prologue at PRG:0x0011DE/0x0011E2 (`move.l sp,(-$7BA4,A5);
# move.l a0,(-$7BA0,A5)`) dozens of times per frame with A0 = the record
# being serviced ($FF02xx channel records, 0x20-stride, or the $FF043C
# latch). That NAMES the mechanism of the merged build's one-frame flicker
# at f2005 (leg-a 04_select_fuzz): a hook-cycle-skewed frame samples the
# spill MID-SCAN ($00FF02DC) instead of at rest ($00FF043C) — pointer
# phase, no gameplay surface. Rerun this whenever a new divergence lands
# on $FF045C-$FF0463 or the ratification of the merged flicker inventory
# is revisited.
#
# PASS = exactly ONE gameplay writer PC (FBNeo attributes the tap to the
# FOLLOWING instruction, so the tap PC is 0x0011E6 for the 0x0011E2 write;
# boot-clear PCs 0xD3C/0xDDA/0xD34 are excluded) and every written pointer
# value in $FF0200-$FF04FF.
#
# Usage: ROMDIR=... tests/audit_ff0460_writer.sh
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="$(mktemp -d)"           # GitHub #68: not a predictable name
trap 'rm -rf "$W"' EXIT

FBNEO_HTAP="ff0460-ff0463" tools/run_replay_fbneo.sh vsavj \
    tests/replays/04_select_fuzz.rpl "$W/out.log" "$W/sbx" \
    >"$W/run.log" 2>&1 || { echo "FAIL: replay run died"; tail -5 "$W/run.log"; exit 1; }
[ -f "$W/out.log.tap" ] || { echo "FAIL: no tap file"; exit 1; }

python3 - "$W/out.log.tap" <<'PY'
import sys, collections
# boot-time RAM-clear loops write 0000/FFFF patterns over all of work RAM
# in the first seconds; exclude by FRAME (the attract/gameplay question
# starts well after), not by an ever-growing PC list
BOOT_FRAMES = 200
pcs = collections.Counter()
vals = collections.Counter()
for ln in open(sys.argv[1]):
    p = ln.split()
    if len(p) < 5 or not p[0].isdigit():
        continue
    frame, addr, val, pc = int(p[0]), int(p[1], 16), int(p[2], 16), \
        int(p[4].replace("pc=", ""), 16)
    if frame < BOOT_FRAMES:
        continue
    pcs[pc] += 1
    if addr == 0xFF0462:            # low word of the pointer = the record
        vals[val] += 1
total = sum(pcs.values())
print(f"gameplay writes: {total}, writer PCs: "
      + ", ".join(f"{pc:06X}x{n}" for pc, n in pcs.most_common()))
print("record low-words: "
      + ", ".join(f"{v:04X}x{n}" for v, n in vals.most_common()))
fail = 0
if total == 0:
    print("FAIL: zero gameplay writes — dead tap (liveness)"); fail = 1
if len(pcs) != 1 or 0x0011E6 not in pcs:
    print("FAIL: expected exactly one writer, tap-PC 0011E6 (the 0011E2 "
          "spill) — the sound driver's dispatch prologue moved or gained "
          "company; re-attribute before trusting the flicker mechanism")
    fail = 1
bad = [v for v in vals if not (0x0200 <= v <= 0x04FF)]
if bad:
    print(f"FAIL: pointer low-words outside $FF0200-$FF04FF: "
          + ", ".join(f"{v:04X}" for v in bad))
    fail = 1
if not fail:
    print("PASS: $FF0460 = sound-driver record-pointer spill, single "
          "writer, all values in the channel-record/latch block")
sys.exit(fail)
PY
