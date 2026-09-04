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
#      maintainer-approved 2026-07-25) with the ratified per-replay classes.
#      RE-POINTED 14z-97 (GitHub #96, maintainer-ruled option (a)): the
#      target is resolved from THIS BUILD's fingerprint through
#      tests/expected/registry.tsv — today `donovan-m8-stage4` — instead of
#      the constants this header used to list (700 / 4278 / 1080 and a
#      donovan-m2c class table frozen 2026-08-02). Every class now lives in
#      the expectation set, in the same vocabulary run_suite.sh speaks, and
#      an unregistered fingerprint stops the gate as a rule-6 signal.
#      What the stage-4 set says, and why 04_select_fuzz is a `diverge`
#      rather than a flicker: tests/expected/donovan-m8-stage4/README.md.
#
# Usage: ROMDIR=... tests/test_m2a_stage4_code.sh [outbase]
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   stage-4 gate: veto lock + guarded moveset + masked legacy gate. 14z-97
#   (#96): the legacy target is RESOLVED from the build's fingerprint
#   (registry.tsv), so it follows each freeze — today donovan-m9-stage4, V2
#   basis. It used to pin donovan-m2c + the V1 basis + three first-divergence
#   constants.
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
WORK="$(mktemp -d)"
# BUILDS TO A SCRATCH DIR BY DEFAULT (14z-94, GitHub #97). This defaulted to
# build/donovan_stage4_gate, which carries SEVEN TRACKED files — so every run
# of this gate rewrote committed artifacts, and `git status` after a test run
# showed a diff. A pre-commit chain whose own side effect is a diff is one
# people learn to scroll past, and that is how a real unexpected modification
# gets missed. Nothing READS that path (it is this gate's build target and
# nothing else), so the tracked copies stay as history and are no longer
# overwritten. Pass an outbase explicitly to keep the build for inspection.
OUTBASE="${1:-$WORK/stage4_build}"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"
. "$REPO/tests/lib/m2a_common.sh"

fail=0

echo "== build stage 4 =="
mkdir -p "$OUTBASE"
# --- build (no pipe: a rejected build must abort the gate) ---------------
# 14z-90: see tests/test_m2b_stage6.sh for the full mechanism. tail's exit
# status masked build_donovan.sh's own BUILD REJECTED paths.
GEN_FLAGS="--allow-plausible --tripwire-open" \
    tools/build_donovan.sh 4 "$OUTBASE" \
    > "$WORK/build.log" 2>&1 || { tail -20 "$WORK/build.log"; exit 1; }
tail -2 "$WORK/build.log"
[ -d "$OUTBASE/rompath" ] || {
    echo "FAIL: no rompath at $OUTBASE — the build produced nothing to gate"
    exit 1
}
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
