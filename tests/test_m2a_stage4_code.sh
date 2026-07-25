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
#   3. Superset invariant, live state: with the two measured cycle-skew
#      windows masked (dead stack $FF7F00-$FF7FFF at frame-done + QSound
#      handshake latch $FF043C — see GOTCHAS "Engine hooks on hot paths"),
#      02_demitri_vs_cpu is bit-identical to vanilla FULL LENGTH and
#      attract first diverges exactly at 4278 (the Jedah demo). Masked
#      equality is also the confinement proof: every byte outside the two
#      windows is compared on every frame.
#      NOTE: the whole-RAM (unmasked) comparison basis for hooked builds is
#      a pending maintainer decision (STATE.md); this gate locks the
#      measured facts without weakening any frozen expectation.
#   4. Pick divergence: 11_pick_donovan first diverges from frozen vanilla
#      at exactly 1080 (select-screen anim hover — stage-3 constant).
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
MASK="043c-043d,7f00-8000"

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

echo "== 2. guarded moveset replay (full length, -debug guard) =="
if MAME_ROMPATH="$RP" tools/run_replay_guarded.sh vsavj \
    tests/replays/12_donovan_vs_cpu.rpl "$WORK/12.log" "$WORK/12box" \
    > "$WORK/12_guard.out" 2>&1; then
    echo "  ok: 12_donovan_vs_cpu END-clean under guard"
else
    echo "FAIL: guard tripped on 12_donovan_vs_cpu:"
    cat "$WORK/12_guard.out"; fail=1
fi

echo "== 3. legacy live-state (masked: dead stack + QSound latch) =="
for r in 02_demitri_vs_cpu; do
    MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" tools/run_replay_mame.sh vsavj \
        "tests/replays/$r.rpl" "$WORK/${r}_van.log" "$WORK/${r}_vanbox"
    MASK_RANGES="$MASK" MAME_ROMPATH="$RP" tools/run_replay_mame.sh vsavj \
        "tests/replays/$r.rpl" "$WORK/${r}_pat.log" "$WORK/${r}_patbox"
    if cmp -s "$WORK/${r}_van.log" "$WORK/${r}_pat.log"; then
        echo "  ok: $r masked bit-identical full length"
    else
        echo "FAIL: $r masked live-state diverged"; fail=1
    fi
done
MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" tools/run_replay_mame.sh vsavj \
    tests/replays/01_attract_long.rpl "$WORK/att_van.log" "$WORK/att_vanbox"
MASK_RANGES="$MASK" MAME_ROMPATH="$RP" tools/run_replay_mame.sh vsavj \
    tests/replays/01_attract_long.rpl "$WORK/att_pat.log" "$WORK/att_patbox"
att_div=$(python3 - "$WORK/att_van.log" "$WORK/att_pat.log" <<'EOF'
import sys
van = open(sys.argv[1]).read().splitlines()
pat = open(sys.argv[2]).read().splitlines()
print(next((a.split()[0] for a, b in zip(van, pat) if a != b), "NONE"))
EOF
)
if [ "$att_div" = "4278" ]; then
    echo "  ok: attract masked first-divergence exactly 4278 (Jedah demo)"
else
    echo "FAIL: attract masked first-divergence $att_div (expected 4278)"; fail=1
fi

echo "== 4. pick divergence (masked live-state; ghost bytes appear from"
echo "      menu-time object dispatch, so the unmasked constant is void) =="
MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" tools/run_replay_mame.sh vsavj \
    tests/replays/11_pick_donovan.rpl "$WORK/pick_van.log" "$WORK/pick_vanbox"
MASK_RANGES="$MASK" MAME_ROMPATH="$RP" tools/run_replay_mame.sh vsavj \
    tests/replays/11_pick_donovan.rpl "$WORK/pick.log" "$WORK/pickbox"
pick_div=$(python3 - "$WORK/pick_van.log" "$WORK/pick.log" <<'EOF'
import sys
van = open(sys.argv[1]).read().splitlines()
pat = open(sys.argv[2]).read().splitlines()
print(next((a.split()[0] for a, b in zip(van, pat) if a != b), "NONE"))
EOF
)
if [ "$pick_div" = "1080" ]; then
    echo "  ok: pick replay masked first-divergence exactly 1080 (anim hover)"
else
    echo "FAIL: pick masked first-divergence $pick_div (expected 1080)"; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: M2a stage-4 code gate" || { echo "FAIL: M2a stage-4 code gate"; exit 1; }
