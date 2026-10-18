#!/bin/sh
# test_crash_guard.sh — ground truth for the crash guard (verdict-logic
# doctrine, CLAUDE.md §4: a detector is trusted only after it classifies
# known-good and known-bad scenarios correctly).
#
# WHAT: the crash guard classifies known-good and known-bad correctly: a clean vanilla run
#   is CLEAN (and, in cheap mode, checksum-identical to the frozen expectation), a planted
#   ILLEGAL opcode trips vec4, a planted odd jump address trips vec3.
# HOW: four MAME runs: the negative control in cheap and -debug modes (each compared with the
#   frozen vanilla log; the -debug one also run-to-run), then the 14 dispatch tables'
#   slot-0x0F entries pointed at a planted ILLEGAL and at an odd address.
# EXPECTS: CLEAN on the negatives, both checksum-identical to frozen vanilla, CRASH vec4 and
#   vec3 on the positives; a guard that misses either plant is not trusted.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/vsavj/02_demitri_vs_cpu.sha1
#   tests/lib/controls.sh tests/lua/emu_clock.lua
#   tests/lua/replay_guard.lua tests/replays/02_demitri_vs_cpu.rpl tools/pack_build.sh
#   tools/patch_prg.py tools/run_mame.sh tools/run_replay_guarded.sh tools/setup_mame.sh
#
# SHEET: none — an instrument, emulator, release or host check; no leg of our build compared with a reference set
#
# MUST-FIRE: known-bad: drift-clock — the -debug guard under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] count that took the debugger's boot halt for a frame until 14z-197) must NOT reproduce the frozen vanilla log (in-gate: one extra -debug run; mode: section 1b's runs use the old clock and the gate FAILs)
#
#   1a. Negative control, cheap mode (no -debug): clean AND checksum log
#       matches the frozen vanilla expectation (guard instrumentation itself
#       does not perturb emulation).
#   1b. Negative control, authoritative mode (-debug): clean, deterministic
#       run-to-run AND checksum-identical to the frozen vanilla log (since
#       14z-197, GitHub #228 step 4: the guard counts EMULATED frames,
#       tests/lua/emu_clock.lua). Until then 1b was compared run-to-run only,
#       on the belief that "-debug changes the MAME scheduler's timeslicing" —
#       RETRACTED 14z-196 ([MFI-2], docs/platform/gotchas.md): the divergence
#       was the debugger's boot halt counted as a frame. A breakpoint STOP can
#       still move the game, so a run whose probes stop the CPU stays its own
#       timeline; this run's breakpoints (the exception vectors) never stop it.
#   2. Positive vec4: all 14 dispatch tables' slot-0x0F entries -> a planted
#      ILLEGAL (0x4AFC) opcode in the free hole; picking Jedah must trip
#      "CRASH ... vec4".
#   3. Positive vec3: same entries -> an odd address; must trip vec3
#      (address error on the jump).
#
# Usage: ROMDIR=... tests/test_crash_guard.sh
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
trap 'rm -rf "$WORK"' EXIT
fail=0
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
_clk=""; vs_ctl_is drift-clock && _clk="INSTR_CLOCK=frame_done"

# --- 1a. negative control, cheap mode (canonical checksums) ------------------
GUARD_DEBUG=0 CODE_RANGES="0-400000" GUARD_MATCH="3000-3100" \
    "$REPO/tools/run_replay_guarded.sh" vsavj \
    "$REPO/tests/replays/02_demitri_vs_cpu.rpl" "$WORK/negc.log" "$WORK/negcbox" \
    > "$WORK/negc.out" 2>&1 \
    || { echo "FAIL: cheap guard tripped on clean vanilla replay"; cat "$WORK/negc.out"; exit 1; }
got=$(shasum "$WORK/negc.log" | cut -d' ' -f1)
exp=$(cat "$REPO/tests/expected/vsavj/02_demitri_vs_cpu.sha1")
if [ "$got" = "$exp" ]; then
    echo "  ok: cheap-mode guard clean + checksum-identical to frozen vanilla"
else
    echo "FAIL: cheap-mode guard perturbed the checksum log"; fail=1
fi

# --- 1b. negative control, authoritative mode (clean + deterministic + vanilla) --
# shellcheck disable=SC2086
env $_clk "$REPO/tools/run_replay_guarded.sh" vsavj \
    "$REPO/tests/replays/02_demitri_vs_cpu.rpl" "$WORK/neg1.log" "$WORK/neg1box" \
    > "$WORK/neg1.out" 2>&1 \
    || { echo "FAIL: -debug guard tripped on clean vanilla replay"; cat "$WORK/neg1.out"; exit 1; }
# shellcheck disable=SC2086
env $_clk "$REPO/tools/run_replay_guarded.sh" vsavj \
    "$REPO/tests/replays/02_demitri_vs_cpu.rpl" "$WORK/neg2.log" "$WORK/neg2box" \
    > "$WORK/neg2.out" 2>&1 \
    || { echo "FAIL: -debug guard tripped on clean vanilla replay (run 2)"; cat "$WORK/neg2.out"; exit 1; }
if cmp -s "$WORK/neg1.log" "$WORK/neg2.log"; then
    echo "  ok: -debug guard clean + deterministic run-to-run"
else
    echo "FAIL: -debug guard nondeterministic"; fail=1
fi
if [ "$(shasum "$WORK/neg1.log" | cut -d' ' -f1)" = "$exp" ]; then
    echo "  ok: -debug guard checksum-identical to frozen vanilla (the emulated clock)"
else
    echo "FAIL: the -debug guard's log is not the frozen vanilla log ($(diff "$WORK/negc.log" "$WORK/neg1.log" | head -2 | tr '\n' ' '))"; fail=1
fi
if vs_ctl_is drift-clock; then
    echo "FAIL: test_crash_guard (control mode: drift-clock)"; exit 1
fi
INSTR_CLOCK=frame_done "$REPO/tools/run_replay_guarded.sh" vsavj \
    "$REPO/tests/replays/02_demitri_vs_cpu.rpl" "$WORK/drift.log" "$WORK/driftbox" > "$WORK/drift.out" 2>&1 || true
if [ ! -s "$WORK/drift.log" ]; then vs_ctl_dead drift-clock "the frame_done-clock run wrote no log" || fail=1
elif [ "$(shasum "$WORK/drift.log" | cut -d' ' -f1)" != "$exp" ]; then
    vs_ctl_fired drift-clock "under the frame_done clock the -debug guard's log differs from frozen vanilla ($(diff "$WORK/negc.log" "$WORK/drift.log" | head -2 | tr '\n' ' '))"
else vs_ctl_dead drift-clock "the frame_done clock still reproduced frozen vanilla" || fail=1; fi

# --- shared pick-Jedah replay (cursor U,U,R; wait past match start) ----------
cat > "$WORK/pick_jedah.rpl" <<'EOF'
300-305 sys=C1
800-803 sys=S1
1000-1002 p1=U
1040-1042 p1=U
1080-1082 p1=R
1700-1702 p1=1
3600 wait
EOF

# All 14 dispatch tables (bank[0]=0x0BD0FA, stride 0x80), slot 0x0F entry at
# +0x3C in each. Whichever the engine calls first trips the guard.
gen_patch() { # $1 = target value for every dispatch entry, $2 = out json
    python3 - "$1" "$2" <<'PY'
import json, sys
target, out = sys.argv[1], sys.argv[2]
ops = [{"op": "code", "addr": "0xBF800", "hex": "4afc"}]  # planted ILLEGAL
for k in range(14):
    entry = 0x0BD0FA + k * 0x80 + 0x0F * 4
    ops.append({"op": "poke32", "addr": hex(entry), "val": target})
json.dump({"ops": ops}, open(out, "w"))
PY
}

run_positive() { # $1 = name, $2 = dispatch target, $3 = expected vec
    gen_patch "$2" "$WORK/$1.json"
    python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/$1_prg" \
        --patch "$WORK/$1.json" > /dev/null
    ROMDIR="$ROMDIR" "$REPO/tools/pack_build.sh" "$WORK/$1_prg" "$WORK/$1_rom" > /dev/null
    rc=0
    MAME_ROMPATH="$WORK/$1_rom;$ROMDIR" "$REPO/tools/run_replay_guarded.sh" vsavj \
        "$WORK/pick_jedah.rpl" "$WORK/$1.log" "$WORK/$1_box" > "$WORK/$1.out" 2>&1 || rc=$?
    if [ "$rc" = "2" ] && grep -Eq "^CRASH [0-9]+ $3 " "$WORK/$1.log"; then
        echo "  ok: $1 tripped $(grep -m1 '^CRASH' "$WORK/$1.log")"
    else
        echo "FAIL: $1 expected $3 trip (rc=$rc)"
        grep -E "^(CRASH|END)" "$WORK/$1.log" 2>/dev/null || cat "$WORK/$1.out"
        fail=1
    fi
}

# --- 2. positive: illegal opcode (vec4) --------------------------------------
run_positive illegal "0x000BF800" vec4

# --- 3. positive: odd jump target (vec3) -------------------------------------
run_positive oddjump "0x000BF801" vec3

[ "$fail" = 0 ] && echo "PASS: crash guard verdicts validated against ground truth" \
    || { echo "SUITE RED"; exit 1; }
