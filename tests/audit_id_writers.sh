#!/bin/sh
# audit_id_writers.sh — which character ids does VANILLA ever assign?
#
# ON-DEMAND (22 MAME runs, ~10 min). Not in the battery; run it when the
# claim below is load-bearing for a decision, and after any change that
# could add a writer of the character-id field.
#
# WHY IT MATTERS. The roster plan puts newcomers on ids in the variant half
# (Huitzil 0x10, Pyron 0x11, Donovan 0x13 — docs/game/atlas/id_space.md). If no
# legacy gameplay path can ever PRODUCE such an id, then those rows are
# unreachable by legacy content and the superset invariant holds by
# construction — a much stronger position than the current slot-0x0F port,
# which needs in-place record surgery precisely because legacy cursors
# visit Jedah's cell.
#
# METHOD. Tap the character-id field of BOTH player structs
# (P1 RAM:$FF8782, P2 RAM:$FF8B82 — a6+0x382) across the legacy corpus and
# collect every (writing PC, value) pair. The P2 field is not optional: the
# CPU-opponent picker, the attract assignment and the challenger path write
# only there, and a P1-only tap misses all three.
#
# Measured 14z-60 (vanilla vsavj), 11 replays x 2 fields:
#   005BF4 -> 02 0F   attract, P1          009008 -> 01   P1 init
#   005BFA -> 00 03   attract, P2          00AEF6 -> 0A 0C 0E  CPU opponent
#   008A86 -> 05      challenger join      020A80 -> 00 01 03 05 06 08  select
#   (plus boot RAM-clear at 000D34/000D3A/000DD8/016E4C/016E4E)
#
# KNOWN GAP, deliberately not papered over: 0x18 (Oboro Bishamon) IS a
# variant id vanilla uses — four sites compare against it (PRG:0x018F9A,
# 0x026FBE, 0x0293A8, 0x043000) — and no replay in this corpus reaches it.
# So this audit proves "no legacy replay HERE writes the variant half", not
# "vanilla cannot". A tenant must still avoid 0x18.
#
# Usage: ROMDIR=... tests/audit_id_writers.sh [outdir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
OUT="${1:-${TMPDIR:-/tmp}/id_writers_$$}"
mkdir -p "$OUT"

REPLAYS="01_attract_long 02_demitri_vs_cpu 03_two_player_vs 04_select_fuzz
         05_timeout_idle 06_test_mode 07_mash_storm 08_challenger_join
         09_mirror_pick 10_midattract_start 16_xemu_2p"

python3 tools/audit_roms.py "$ROMDIR" >/dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

for r in $REPLAYS; do
    for who in p1:ff8782 p2:ff8b82; do
        tag=${who%%:*}; addr=${who##*:}
        # NOTE: the exit code is deliberately ignored. MAME can segfault in
        # TEARDOWN after the log is complete (docs/GOTCHAS.md); the END
        # summary line below is the artifact that decides validity.
        REPLAY="tests/replays/$r.rpl" TAP="$addr,2" FRAMES=7000 \
            TRACE_OUT="$OUT/$r.$tag.txt" MAME_SANDBOX="$OUT/sbx_${r}_$tag" \
            tools/run_mame.sh vsavj \
            -autoboot_script tests/lua/tap_writes.lua \
            >"$OUT/$r.$tag.log" 2>&1 || true
        printf '.'
    done
done
echo

python3 - "$OUT" <<'PY'
import glob, os, sys, collections
out = sys.argv[1]
BOOT = {0x000D34, 0x000D3A, 0x000DD8, 0x016E4C, 0x016E4E}
bypc = collections.defaultdict(set)
incomplete = []
files = sorted(glob.glob(out + "/*.txt"))
for f in files:
    body = open(f).read()
    if "\nEND " not in body and not body.startswith("END "):
        incomplete.append(os.path.basename(f)); continue
    for line in body.splitlines():
        p = line.split()
        if not p or p[0] != "frame":
            continue
        pc = int(p[3], 16); data = int(p[7], 16); mask = int(p[9], 16)
        v = data & 0xFF if mask & 0xFF else (data >> 8) & 0xFF
        bypc[pc].add(v)

print("tap logs: %d, complete: %d" % (len(files), len(files) - len(incomplete)))
if incomplete:
    print("INCOMPLETE (no END line): %s" % " ".join(incomplete))

print("\ngameplay writers of the character-id field:")
for pc in sorted(bypc):
    if pc in BOOT:
        continue
    print("  %06X -> %s" % (pc, " ".join("%02X" % v for v in sorted(bypc[pc]))))

gp = {v for pc, vs in bypc.items() if pc not in BOOT for v in vs}
print("\nunion of gameplay-written ids: %s"
      % " ".join("%02X" % v for v in sorted(gp)))
bad = sorted(v for v in gp if 0x10 <= v <= 0x1F)

fail = 0
if incomplete:
    print("\nFAIL: %d tap log(s) lack an END summary line" % len(incomplete))
    fail = 1
if bad:
    print("\nFAIL: a gameplay path wrote a VARIANT-HALF id: %s"
          % " ".join("%02X" % v for v in bad))
    print("  That breaks the 'variant rows are unreachable by legacy'")
    print("  argument in docs/game/atlas/id_space.md — attribute it before")
    print("  planning any tenant on the variant half.")
    fail = 1
if not fail:
    print("\nPASS: no legacy gameplay path writes an id in 0x10-0x1F")
    print("  (caveat in the header: 0x18/Oboro is unexercised by this corpus)")
sys.exit(fail)
PY
