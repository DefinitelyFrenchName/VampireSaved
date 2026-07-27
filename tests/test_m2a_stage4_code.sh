#!/bin/sh
# test_m2a_stage4_code.sh — M2a stage-4 gate: ported code + engine hooks.
#
# Locks (all measured 2026-07-25, session 7):
#   1. Extraction correctness: the bare-long sibling veto holds — the seven
#      operand-pair sites that were being corrupted (docs/GOTCHAS.md) are
#      byte-identical to the vsav2 source in the generated blob, and the
#      extract log reports a nonzero veto count.
#   2. Bring-up: the full 12_donovan_vs_cpu moveset replay (9320 frames)
#      runs END-clean under the -debug crash guard — no crash, no tripwire.
#   3. Superset invariant per the amended CLAUDE.md §4 (masked live-RAM,
#      maintainer-approved 2026-07-25) with the v2 per-replay classes
#      (maintainer-approved 2026-07-27; standing watch on flicker growth):
#      m2a_legacy_gate_masked runs the full legacy set against frozen
#      masked vanilla logs — 02/05/07 exact; 03/10/16 flicker-tolerated
#      (tools/compare_flicker.py, ground-truthed); 06 first-divergence
#      exactly 700 (TS press; latch-phase propagation into service mode);
#      attract exactly 4278 (Jedah demo); pick exactly 1080 (anim hover).
#
# Usage: ROMDIR=... tests/test_m2a_stage4_code.sh [outbase]
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUTBASE="${1:-$REPO/build/donovan_stage4_gate}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"
. "$REPO/tests/lib/m2a_common.sh"

fail=0

echo "== build stage 4 =="
mkdir -p "$OUTBASE"
GEN_FLAGS="--allow-plausible --tripwire-open" \
    tools/build_donovan.sh 4 "$OUTBASE" | tail -2
RP="$OUTBASE/rompath;$ROMDIR"

echo "== 1. extraction: bare-long veto fact-lock =="
grep -E "vetoed \(operand bytes\)" "$OUTBASE/extract.log" | grep -qv " 0 vetoed" \
    && echo "  ok: veto active in extract log" \
    || { echo "FAIL: no veto activity in extract log"; fail=1; }
python3 - "$OUTBASE" <<'EOF' || fail=1
import sys
out = sys.argv[1]
fixed = open(f'{out}/patch/fixed_x088512.bin','rb').read()
src = open('build/out/vsav2_opcodes.bin','rb').read()
base = 0x88512
bad = [hex(a) for a in
       (0x8A49A, 0x8A510, 0x8A362, 0x88C58, 0x8972C, 0x8AA06, 0x8B382)
       if src[a-2:a+6] != fixed[a-base-2:a-base+6]]
if bad:
    print(f"FAIL: operand-pair sites corrupted again: {bad}"); sys.exit(1)
print("  ok: all 7 known operand-pair sites byte-identical to source")
EOF

echo "== 2. guarded replays (full length, -debug guard) =="
for gr in 12_donovan_vs_cpu 19_don_dp_spam 20_don_round2 21_don_mash; do
    if MAME_ROMPATH="$RP" tools/run_replay_guarded.sh vsavj \
        "tests/replays/$gr.rpl" "$WORK/$gr.log" "$WORK/${gr}box" \
        > "$WORK/${gr}_guard.out" 2>&1; then
        echo "  ok: $gr END-clean under guard"
    else
        echo "FAIL: guard tripped on $gr:"
        cat "$WORK/${gr}_guard.out"; fail=1
    fi
done

echo "== 3. legacy gate, amended §4 basis (masked live-RAM, frozen expectations) =="
m2a_legacy_gate_masked "$RP" "$WORK"
[ "$gate_fail" = 0 ] || fail=1

[ "$fail" = 0 ] && echo "PASS: M2a stage-4 code gate" || { echo "FAIL: M2a stage-4 code gate"; exit 1; }
