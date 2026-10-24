#!/bin/sh
# audit_phase_mode_cost.sh — what does Phobos' phase-gated latch cost Donovan?
#
# WHAT: what Phobos's phase-gated latch (`latch_mode = "phase"`, needed by him and carried
#   by every tenant in a merged build) costs Donovan: nothing legacy can observe, and a
#   bounded, re-convergent transient in his own char-init pool state.
# HOW: builds a phase-mode Donovan probe variant and A/Bs it LIVE against donovan-m3a on
#   MAME over 14 replay legs (no registry row exists for a probe, so no frozen set); section
#   0 proves the shim executed (GUARD_PROBE) before any verdict.
# EXPECTS: legacy replays bit-identical; Donovan's own replays diverge from the exact frame
#   the shim runs, for 24-135 frames in 13-16 runs, then re-converge for thousands of
#   frames. An IDENTICAL result on his own content FAILS — the rig stopped forming the
#   match. Section 0's probe run on emulated time at its frozen game clock, the staging leg on replay.lua's checksum.
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): replay_guard.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua); section 0's probe run's game clock RAM:$FF8080 at its last frame is held
#   to tests/expected/instr_gameclock/audit_phase_mode_cost.tsv, frozen by `--freeze-clock` from a REFERENCE leg (the
#   guard without -debug, the same POKES) held to replay.lua run live; one STAGING reference leg is held to replay.lua
#   on every run (tests/lib/instr_align.sh). The phase build is built fresh, so a manifest change that moves its game
#   clock FAILs the gate until re-frozen.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/instr_gameclock/ tests/lib/controls.sh
#   tests/lib/instr_align.sh tests/lua/emu_clock.lua tests/lua/replay.lua tests/lua/replay_guard.lua
#   tests/replays/ tools/build_donovan.sh tools/build_wide_romset.py tools/run_mame.sh
#   tools/run_replay_guarded.sh tools/run_replay_mame.sh tools/setup_mame.sh
#
# SHEET: none — compares builds of ours with each other (A/B, merged vs solo, stock vs WIDE), not with a reference set
#
# MUST-FIRE: known-bad: drift-clock — the probe run under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 5,317 emulated frames of 5,320 counted) must miss its frozen game clock (in-gate: one extra run; mode: the probe run runs the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
#
# WHY (M3b, 14z-77, the maintainer's ratified condition). A merged build has
# ONE init shim and therefore ONE seeder. Phobos NEEDS `latch_mode = "phase"`
# — without it his ecosystem drains pool 0 and the round-2 char re-init
# re-runs the seeder over LIVE pools (14z-65: the f4890 wipe, orphaned
# queues, a freed slot dispatched into palette space). So a build containing
# him carries the gate for EVERYONE, and Donovan's frozen shim bytes change.
#
# The maintainer approved adopting phase mode ON CONDITION that Donovan's
# behaviour be measured first. This is that measurement, made rerunnable.
#
# MEASURED 14z-77, and it RETRACTS the prediction that shipped with slice G.
# I wrote that the gate "should be inert for him — it only narrows the seed
# to the char-load phase, where his first init already sits". It is NOT
# inert. It is bounded and re-convergent:
#
#   LEGACY            bit-identical, 4 replays, 30,284 frames. The shim runs
#                     only on the tenant's dispatch row, so legacy never
#                     executes it. The superset invariant is untouched.
#   DONOVAN'S OWN     diverges from donovan-m3a starting at the EXACT frame
#                     the shim runs (2886 on replay 12, 2363 on 19/20 — the
#                     same frames GUARD_PROBE reports the shim hit), for
#                     24-135 frames in 13-16 short runs, then RE-CONVERGES
#                     completely: 6,000-9,700 identical frames afterwards,
#                     including a full round-2 on replay 20.
#
# So the cost is a transient in his own char-init pool state, confined to the
# load phase, and nothing legacy can observe. Whether that transient is
# acceptable is a MAINTAINER call, not a harness one — this audit exists so
# the question is answered with numbers each time it is asked.
#
# The comparison is a LIVE A/B between two builds, not a frozen expectation
# set, because a phase-mode build has no registry row (rows are added only at
# freeze time) and `run_suite.sh` refuses an unregistered fingerprint.
#
# THE RIG MUST FORM THE MATCH. Without the forced-pick pokes the shim never
# runs at all and every replay compares identical — a green that measures
# nothing. Section 0 proves the shim executed before any verdict is read.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/audit_phase_mode_cost.sh [--freeze-clock]
# On-demand: builds a probe variant and runs 14 replay legs (~15 min).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-77: what Phobos' phase-gated latch costs Donovan — the maintainer's
#   ratified condition for adopting it in the merge. Builds a phase-mode
#   Donovan and A/Bs it LIVE against donovan-m3a (no registry row exists for
#   it, and run_suite refuses an unregistered fingerprint). LEGACY must be
#   bit-identical (4 replays, 30,284 frames — it is); his OWN content must
#   diverge AND re-converge (24-135 frames in 13-16 runs from the exact frame
#   the shim runs, then 6,000-9,700 identical incl. a full round-2). An
#   IDENTICAL result FAILS — that means the rig stopped forming the match. On-
#   demand, ~15 min
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN

# THE REFERENCE IS BUILT FROM THE CURRENT MANIFESTS WITHOUT THE LATCH
# (14z-133b). It used to be build/m5_wide = donovan-m3a, the 14z-64 freeze,
# whose registry row is commented out: legacy behaviour has legitimately
# moved many times since (the 14z-91 walker relocation, #104's capture rows,
# #99's AI rows), so ~90% of legacy frames differed for reasons that had
# nothing to do with the latch — RED 14z-128 on a hollow symptom. Now the
# ONLY difference between the two legs is `latch_mode = "phase"`. REF_BUILD=
# still overrides for a deliberate comparison.
REF="${REF_BUILD:-}"
WIDE_ZIP="${WIDE_ROMSET:-$PWD/build/wide0/rompath/vsavjw.zip}"
if [ ! -x "$MAME_BIN" ] || [ ! -f "$WIDE_ZIP" ]; then
    echo "SKIP: need the WIDE MAME binary and a WIDE overlay romset."
    echo "      python3 tools/build_wide_romset.py \"\$ROMDIR\" build/wide0/rompath \\"
    echo "              --qsound 2 --gfx 4 --prg 4"
    exit 0
fi

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK" build/manifest/_phase_probe.toml' EXIT
fail=0
FREEZE_CLOCK=0; [ "${1:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
CLOCKS="tests/expected/instr_gameclock/audit_phase_mode_cost.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"

echo "== build a phase-mode Donovan (MEASUREMENT ONLY — never freeze it) =="
python3 - <<'PY'
import pathlib
src = pathlib.Path("build/manifest/donovan.toml").read_text()
a = 'latch_disp = 0x7966\n'
assert src.count(a) == 1, "init_shim shape moved; this probe needs updating"
pathlib.Path("build/manifest/_phase_probe.toml").write_text(
    src.replace(a, a + 'latch_mode = "phase"\n'))
PY
KEY_SET=vsavj TENANT_MANIFEST=build/manifest/_phase_probe.toml TENANT_CHAR=0x13 \
WIDE_ROMSET="$WIDE_ZIP" \
GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
tools/build_donovan.sh 6 "$WORK/phase" > "$WORK/build.log" 2>&1 || {
    echo "  FAIL: phase build errored"; tail -15 "$WORK/build.log"; exit 1; }
echo "  ok: built (fingerprint differs from the reference BY DESIGN — the"
echo "      phase gate is 12 bytes of added code)"
if [ -z "$REF" ]; then
    echo "== build the REFERENCE from the same manifests WITHOUT the latch =="
    KEY_SET=vsavj TENANT_MANIFEST=build/manifest/donovan.toml TENANT_CHAR=0x13 \
    WIDE_ROMSET="$WIDE_ZIP" \
    GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
    tools/build_donovan.sh 6 "$WORK/ref" > "$WORK/build_ref.log" 2>&1 || {
        echo "  FAIL: reference build errored"; tail -15 "$WORK/build_ref.log"; exit 1; }
    REF="$WORK/ref"
    echo "  ok: reference built — the two legs differ by latch_mode only"
fi

SHIM="$(sed -n 's/^code *0x0*\([0-9a-f]*\) init shim .*/\1/p' \
        "$WORK/phase/patch/patch_notes_fragment.md" | head -1)"
POK="1400:ff8782:13;1450:ff8782:13;1500:ff8782:13;\
1400:ff8b82:13;1450:ff8b82:13;1500:ff8b82:13"

# Build dirs arrive both relative (the reference) and absolute (the scratch
# probe build), so the rompath must not blindly prepend $PWD — doing so
# produced "<repo>//var/folders/..." and every run failed to start. Section 0
# caught it as "the shim never ran", which is the control working.
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }

run() {  # run <build> <replay> <out> [pokes] — each run its own sandbox inside the trapped WORK (#303)
    POKES="${4:-}" MAME_ROMPATH="$(abspath "$1")/rompath;$ROMDIR" \
        tools/run_replay_mame.sh vsavjw "tests/replays/$2.rpl" "$3" "$(mktemp -d "$WORK/sb.XXXXXX")" \
        >/dev/null 2>&1 || true
}

echo "== 0: the rig FORMS the match (else every verdict below is vacuous) =="
# shellcheck disable=SC2086
env $_clk POKES="$POK" MAME_ROMPATH="$(abspath "$WORK/phase")/rompath;$ROMDIR" ALIGN_OUT="$WORK/probe.align" \
GUARD_PROBE="$SHIM" GUARD_PROBE_MEM=A6+382 \
    tools/run_replay_guarded.sh vsavjw tests/replays/03_two_player_vs.rpl \
    "$WORK/probe.log" "$WORK/pbox" >/dev/null 2>&1 || true
ia_note_run "$WORK/manifest.tsv" phase 03_two_player_vs vsavjw "$(abspath "$WORK/phase")/rompath;$ROMDIR" \
    "$REPO/tests/replays/03_two_player_vs.rpl" "MAME_BIN=${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2} POKES=$POK GUARD_PROBE=$SHIM GUARD_PROBE_MEM=A6+382" "$WORK/probe.align"
H="$(grep -c '^PROBE ' "$WORK/probe.log" || true)"
if [ "${H:-0}" -ge 1 ]; then
    echo "  ok: the shim executed $H time(s) on the phase build"
else
    echo "  FAIL: the shim never ran — the pokes did not form a Donovan"
    echo "        match, so 'identical' below would mean nothing"
    exit 1
fi

echo "== 1: LEGACY must be bit-identical (the superset invariant) =="
for R in 02_demitri_vs_cpu 05_timeout_idle 03_two_player_vs 01_attract_long; do
    run "$REF"        "$R" "$WORK/l_${R}_ref"
    run "$WORK/phase" "$R" "$WORK/l_${R}_new"
    if cmp -s "$WORK/l_${R}_ref" "$WORK/l_${R}_new"; then
        echo "  ok: $R bit-identical ($(wc -l < "$WORK/l_${R}_ref" | tr -d ' ') frames)"
    else
        echo "  FAIL: $R DIVERGES — phase mode reached legacy content, which"
        echo "        the shim's dispatch-row hosting is supposed to prevent"
        fail=1
    fi
done

echo "== 2: DONOVAN's own content — bounded and RE-CONVERGENT =="
for R in 12_donovan_vs_cpu 19_don_dp_spam 20_don_round2; do
    run "$REF"        "$R" "$WORK/d_${R}_ref" "$POK"
    run "$WORK/phase" "$R" "$WORK/d_${R}_new" "$POK"
    python3 - "$WORK/d_${R}_ref" "$WORK/d_${R}_new" "$R" <<'PY' || fail=1
import sys
a = [l.rstrip() for l in open(sys.argv[1])]
b = [l.rstrip() for l in open(sys.argv[2])]
n = min(len(a), len(b)); r = sys.argv[3]
d = [i for i in range(n) if a[i] != b[i]]
if not d:
    print("  FAIL: %s identical — expected the char-init transient. Either "
          "the rig\n        did not pick Donovan, or the gate stopped "
          "applying." % r)
    sys.exit(1)
runs, s, p = [], d[0], d[0]
for i in d[1:]:
    if i != p + 1:
        runs.append((s, p)); s = i
    p = i
runs.append((s, p))
tail = n - 1 - runs[-1][1]
ok = tail > 500          # must fully re-converge and STAY converged
print("  %s: %s — %d/%d frames differ in %d run(s), first at %d, last ends "
      "%d, then %d identical frames"
      % ("ok" if ok else "FAIL", r, len(d), n, len(runs), runs[0][0],
         runs[-1][1], tail))
if not ok:
    print("        does NOT re-converge — that is a different finding from "
          "the\n        measured one and must be root-caused, not tolerated")
sys.exit(0 if ok else 1)
PY
done

echo "== 3: the instrument's alignment (#228 step 4, option A) =="
if [ "$FREEZE_CLOCK" = 1 ]; then
    [ "$fail" = 0 ] || { echo "REFUSED: sections 0-2 failed — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/replay_guard.lua" "$WORK/manifest.tsv" "$WORK/fz" "${JOBS:-4}" "$WORK/clocks.tsv" \
        > "$WORK/fz.txt" || { sed 's/^/  /' "$WORK/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/audit_phase_mode_cost.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): phase = the phase-mode probe"
      echo "# build, built fresh; the reference leg held to replay.lua run live, the probe run to its game clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$WORK/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$WORK/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
if ia_check_manifest "$CLOCKS" "$WORK/manifest.tsv" > "$WORK/align_bad.txt"; then
    echo "  ok: the probe run on emulated time, at its frozen game clock"
else echo "  FAIL: $(wc -l < "$WORK/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$WORK/align_bad.txt" | sed 's/^/        /'; fail=1; fi
ia_stage audit_phase_mode_cost "$CLOCKS" "$REPO/tests/lua/replay_guard.lua" "$WORK/manifest.tsv" 1 "$WORK/st" "$MODE" || fail=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "FAIL: phase-mode cost audit (control mode: $MODE)"; exit 1; }
    echo "FAIL: phase-mode cost audit — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi

[ "$fail" = 0 ] || { echo "FAIL: phase-mode cost audit"; exit 1; }
echo "PASS: phase mode costs LEGACY nothing (bit-identical) and costs Donovan"
echo "      a bounded, fully re-convergent transient at his own char-init"
