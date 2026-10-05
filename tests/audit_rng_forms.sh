#!/bin/sh
# audit_rng_forms.sh — THE PARITY GATES UNDER THREE RNG FORMS: what the 0000 pin (the RNG's fixed point) hides, measured against the gates' own pin (GitHub #183, 14z-186).
#
# WHAT: the ours-vs-native parity gates pin the engine RNG word $FF80D4 to 0000 on every frame from the match anchor
#   (2363) — the routine's FIXED POINT, so every draw returns 0 and every RNG-decided branch takes its zero path on
#   both legs. #183 asked whether they should pin otherwise; the maintainer ruled (2026-09-30) to keep 0000 as the
#   basis on this audit's measurement, which it re-runs: audit_move_parity (ALL=1, 32 parts), audit_chains174 and
#   audit_chains184 under form A (their own pin), form B (0100 poked on every frame — a non-zero word) and form C
#   (5a5a poked 2363..2599, then free).
# HOW: each gate is run UNCHANGED through its RNG_WORD/RNG_UNTIL probe knob (A: none; B: RNG_WORD=0100; C:
#   RNG_WORD=5a5a RNG_UNTIL=2600), its table kept (GOT_OUT, KEEP); tools/rng_forms.py compares every B and C row
#   against form A's row from the same build and script, and form A's move_parity table against the frozen
#   tests/expected/move_parity_events.tsv, so a build or basis move cannot pass for an RNG effect. A gate's own
#   verdict under B or C is not this audit's verdict (audit_chains184 stops at its native outcome check under both).
# EXPECTS: form A passes all three gates and equals the frozen move_parity table; under B no IDENT row of
#   audit_move_parity or audit_chains174 turns DIFF, and some move_parity rows move (the pin reaches the game); every
#   tally row equal to tests/expected/rng_forms.tsv; every control fails.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/audit_chains174.sh tests/audit_chains184.sh
#   tests/audit_move_parity.sh tests/expected/move_parity_events.tsv tests/expected/rng_forms.tsv tests/lib/controls.sh
#   tools/rng_forms.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: ident-flipped — form B's move_parity table with one IDENT row made DIFF must break "under B no IDENT row turns DIFF", so that absence is read row by row against form A (in-gate: the flipped copy must show an IDENT->DIFF transition; mode: the real B table is flipped and the audit FAILs)
# MUST-FIRE: perturbed-copy: baseline-moved — form A's move_parity table with its middle row's verdict flipped must break "form A equals the frozen table", so the build/basis control can fail (in-gate: the moved copy must differ from the frozen table; mode: the real A table is moved and the audit FAILs)
# MUST-FIRE: perturbed-copy: form-inert — form B's table replaced by form A's must break "under B the pin reaches the game", so a knob that never reached the game cannot pass for "no new difference" (in-gate: A against itself must move no row; mode: the real B table is replaced and the audit FAILs)
#
# NOT COVERED: which update order the object loop takes under B, or which branches the frame's later draws select;
#   any other non-zero word; the other gates that pin 0000 (about 20 beyond these three); audit_chains184's rows under
#   B and C (its native outcome check stops it — the Sword Grapple whiff at +8 no longer starts a2:0x41); what causes
#   C's IDENT->DIFF rows (not attributed; ours draws in vsavj's motion trackers where native does not, #176); FBNeo;
#   a second host; run-to-run repeats.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged31] [FREEZE=1] [KEEP=<dir> [REUSE=1]] tests/audit_rng_forms.sh
#   REUSE=1 with KEEP re-reads a work dir an earlier run of THIS audit filled (the control modes on the real tables,
#   seconds instead of hours); a form whose tables are missing is run
#   emulator tier, MAME; ~8 min on this MacBook (nine gate runs, each parallel inside; 7 min 30 s measured 14z-186)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
export ROMDIR
BUILD="${BUILD:-build/m3b_merged31}"; export BUILD
EXPECT="$REPO/tests/expected/rng_forms.tsv"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "== audit_rng_forms: build $BUILD, work $W"

form_env() {  # the knob per form
    case $1 in A) echo "" ;; B) echo "RNG_WORD=0100" ;; C) echo "RNG_WORD=5a5a RNG_UNTIL=2600" ;; esac
}
for f in A B C; do
    if [ -n "${REUSE:-}" ] && [ -n "${KEEP:-}" ] && [ -f "$W/mp_$f.got.tsv" ] && [ -f "$W/c184_$f.log" ]; then
        echo "  form $f: REUSED from $W (REUSE=1: the tables of an earlier run of this audit, read again)"; continue
    fi
    fe="$(form_env $f)"
    echo "  form $f: ${fe:-no knob, the 0000 pin}"
    ( unset FREEZE CONTROL; env $fe ALL=1 GOT_OUT="$W/mp_$f.got.tsv" sh tests/audit_move_parity.sh > "$W/mp_$f.log" 2>&1 ) || true
    ( unset FREEZE CONTROL; env $fe KEEP="$W/c174_$f" sh tests/audit_chains174.sh > "$W/c174_$f.log" 2>&1 ) || true
    ( unset FREEZE CONTROL; env $fe KEEP="$W/c184_$f" sh tests/audit_chains184.sh > "$W/c184_$f.log" 2>&1 ) || true
done

fail=0
_fz=""; [ -n "${FREEZE:-}" ] && [ -z "${VS_CTL:-}" ] && _fz=--freeze
python3 tools/rng_forms.py "$W" "$EXPECT" --control "${VS_CTL:-}" $_fz || fail=1

if [ -n "${VS_CTL:-}" ]; then
    if [ "$fail" = 1 ]; then vs_ctl_fired "$VS_CTL" "the perturbed real input fails the audit"; echo "FAIL: audit_rng_forms (control mode)"; exit 1
    else vs_ctl_dead "$VS_CTL" "the perturbed real input still passed" || true; echo "FAIL: audit_rng_forms"; exit 1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_rng_forms"; else echo "FAIL: audit_rng_forms"; exit 1; fi
