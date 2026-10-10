#!/bin/sh
# audit_walker_repoint.sh — after the relocation, does ANYTHING still reach
# the vanilla object-pool walkers?
#
# WHAT: after the walker relocation nothing still reaches the VANILLA object-pool walkers at
#   run time — the residual a static caller scan cannot close (a target computed at run
#   time).
# HOW: breakpoints on the vanilla and relocated walker entries over the replay corpus on
#   MAME against the build, AND the same instrument on an un-relocated REF_BUILD where the
#   vanilla entries must fire (the negative control that makes a zero readable); the control
#   forces a vanilla hit count non-zero.
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): walker_sp.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua); every run's game clock RAM:$FF8080 at its last frame is held to
#   tests/expected/instr_gameclock/audit_walker_repoint.tsv, frozen by `--freeze-clock` from REFERENCE legs (no
#   breakpoint, no debugger; each breakpoint run's game clock equal to its reference leg's); one STAGING reference
#   leg (21_don_mash on the build) is held on every run to replay.lua run live on the same build (no basis exists
#   for a hacked build).
# EXPECTS: vanilla entries silent and relocated entries firing on the build; vanilla entries
#   firing on the reference build. Zero everywhere is a dead breakpoint, not a pass. Every run on emulated time at
#   its frozen game clock, the staging leg on replay.lua's checksum.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/instr_gameclock/ tests/lib/controls.sh
#   tests/lib/instr_align.sh tests/lua/emu_clock.lua tests/lua/replay.lua tests/lua/walker_sp.lua
#   tests/replays/ tools/audit_walker_callers.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: known-bad: drift-clock — a breakpoint run under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 4,250 emulated frames of 18,520 counted on 24_don_winmash) must miss its frozen game clock (in-gate: one extra run of 21_don_mash on the build; mode: every breakpoint run runs the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
# MUST-FIRE: known-bad: vanilla-walker-reached — after the relocation no caller reaches a vanilla walker, so a nonzero hit on one must fail section 1 (mode: a vanilla-walker hit count is forced nonzero so the "still reached" FAIL fires and the gate FAILs)
#
# WHY (14z-91). The obj_hook legacy-cycle fix copies each walker into free
# space and rewrites the operand of every `jsr <walker>`. Completeness is
# the correctness argument: a caller left pointing at the vanilla walker
# keeps walking the VANILLA table, which is bit-identical for legacy (it IS
# vanilla) but an over-index — a wild dispatch — for a tenant type.
#
# tools/audit_walker_callers.py enumerates the callers statically and found
# 23 `jsr abs.l` and nothing else: no data longword equals either walker
# address, no jsr/jmp (d16,PC), and every branch hit is the walker's own
# loop or an operand word misread by a linear scan. But a target COMPUTED at
# runtime is invisible to any static scan, and that residual is exactly what
# this closes: run the corpus and require the vanilla entries to be silent.
#
# THE NEGATIVE CONTROL IS NOT OPTIONAL. "Zero hits on the vanilla walker" is
# also what a dead breakpoint says. So the same instrument is pointed at a
# REFERENCE build that has NOT been relocated, where the vanilla entries MUST
# fire — otherwise every zero above is unreadable. Set REF_BUILD to one.
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=6] [REF_BUILD=build/don_m5] \
#          [REPLAYS="..."] tests/audit_walker_repoint.sh <builddir> [--freeze-clock]
# ~5 min.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-91: after the relocation, does ANYTHING still reach the vanilla
#   walkers? Closes the residual the static caller scan cannot (a target
#   computed at runtime). Vanilla entries must be SILENT, relocated entries
#   must FIRE. NEGATIVE CONTROL is not optional and is built in: the same
#   instrument on an un-relocated REF_BUILD must see the vanilla walkers, or
#   every zero is just a dead breakpoint. Measured identical counts either
#   side of the move (1243 / 40236). ~5 min
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${1:?usage: audit_walker_repoint.sh <builddir> [--freeze-clock]}"
FREEZE_CLOCK=0; [ "${2:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
# DELIBERATE PIN (do not "fix" at a freeze, 14z-103): the negative control
# must be a build WITHOUT the 14z-91 walker relocation, and don_m5 (14z-87)
# is the newest such build. Every current build is relocated, so this can
# never re-point forward; the dir is classed EVIDENCE in the build-dir
# census for exactly this reason.
REF_BUILD="${REF_BUILD:-build/don_m5}"
JOBS="${JOBS:-6}"
# a legacy pair, a long mash rig (the only family that reaches walker A), and
# two tenant rigs so the RELOCATED walkers are exercised by tenant content
REPLAYS="${REPLAYS:-02_demitri_vs_cpu 21_don_mash 24_don_winmash 36_pick_tenant_cell 12_donovan_vs_cpu}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
CLOCKS="tests/expected/instr_gameclock/audit_walker_repoint.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }

# the relocated entry points, derived from the BUILD's own patch.json
NEW=$(BUILD="$BUILD" python3 - <<'PY'
import json, os, sys
sys.path.insert(0, "tools")
from _minitoml import loads
vj = open("build/out/vsavj_opcodes.bin", "rb").read()
ops = json.load(open(os.path.join(os.environ["BUILD"], "patch/patch.json")))["ops"]
out = []
for r in loads(open("build/manifest/donovan.toml").read())["obj_hook"]:
    pre = vj[r["walker"]:r["walker"] + r["walker_len"]].hex()
    b = [o for o in ops if o["op"] == "code" and o["hex"].startswith(pre)]
    if not b:
        sys.exit(f"no relocated copy of walker {r['walker']:#x} in this build")
    # the `jsr (A0)` sits at walker+0x1E (site = walker+0x18, jsr = site+6)
    out.append("%x" % (int(b[0]["addr"], 16) + 0x1E))
print(",".join(out))
PY
) || { echo "FAIL: $NEW"; exit 1; }
OLD="54476,5e548"
echo "vanilla walker jsr:   $OLD  (must be SILENT)"
echo "relocated walker jsr: $NEW  (must FIRE)"

frames_for() {
    # NOTE the spaces around `=`: tests/test_shell_portability.sh scans for
    # bash-array syntax and `f=(` inside an awk program looks exactly like it.
    sed 's/#.*//' "tests/replays/$1.rpl" | awk 'NF { split($1, r, "-");
        f = (r[2] ? r[2] : r[1]); if (f + 0 > m) m = f + 0 } END { print m + 120 }'
}

run_leg() {   # $1 tag  $2 rompath-build  $3 sites  [$4 env...: INSTR_REFERENCE=1 makes it a reference leg]  [$5 replays]
    _t="$1"; _b="$2"; _s="$3"; _x="${4:-}"; pool=0
    _dbg="-debug -debugger none"; case "$_x" in *INSTR_REFERENCE=1*) _dbg="" ;; esac
    for r in ${5:-$REPLAYS}; do
        # shellcheck disable=SC2086
        ( env $_x MAME_SANDBOX="$W/sb_${_t}_$r" REPLAY="$PWD/tests/replays/$r.rpl" \
          SPSITES="$_s" SP_OUT="$W/${_t}_$r.txt" FRAMES="$(frames_for "$r")" ANCHOR="$(frames_for "$r")" \
          ALIGN_OUT="$W/${_t}_$r.align" MAME_ROMPATH="$PWD/$_b/rompath;$ROMDIR" \
          tools/run_mame.sh vsavjw $_dbg \
          -autoboot_script "$PWD/tests/lua/walker_sp.lua" \
          >"$W/${_t}_$r.log" 2>&1 ) &
        pool=$((pool + 1)); [ "$pool" -ge "$JOBS" ] && { wait; pool=0; }
    done
    wait
}
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"
_skip=""; [ "$MODE" = first-frame-skip ] && _skip="INSTR_CLOCK=skip_first"

total_for() {  # $1 tag  $2 hex site -> total hits across replays
    # NORMALISE BOTH SIDES, AND COMPARE AS STRINGS. walker_sp.lua prints the
    # site %06x-padded, so a bare `$2 == "5e548"` is an awk string-vs-number
    # trap: "054476" vs "54476" compare NUMERICALLY and match, while
    # "05e548" vs "5e548" compare as strings and do not — the gate reported a
    # confident 0 hits for one site and the right number for its twin. A
    # blind instrument and a real zero look identical, so this is padded in
    # the shell and forced to a string compare in awk.
    _s=$(printf '%06x' $((0x$2)))
    awk -v s="$_s" '$1=="SP" && ($2 "") == (s "") { t += $4 } END { print t + 0 }' \
        "$W/$1"_*.txt 2>/dev/null
}
complete_for() { grep -l SPEND "$W/$1"_*.txt 2>/dev/null | wc -l | tr -d ' '; }

echo
echo "== 1. on $BUILD: vanilla entries silent, relocated entries live =="
run_leg new "$BUILD" "$OLD,$NEW" "$_clk"
n=$(complete_for new)
[ "$n" = "$(echo "$REPLAYS" | wc -w | tr -d ' ')" ] || {
    echo "  FAIL: only $n of $(echo "$REPLAYS" | wc -w | tr -d ' ') runs completed"; fail=1; }
for s in $(echo "$OLD" | tr ',' ' '); do
    h=$(total_for new "$s")
    # THE EXECUTABLE MODE: force a vanilla-walker hit so the "still reached" FAIL fires.
    if [ "$MODE" = vanilla-walker-reached ]; then h=1; fi
    if [ "${h:-0}" = "0" ]; then
        echo "  ok: vanilla $s never reached ($h hits)"
        vs_ctl_fired vanilla-walker-reached "vanilla walker $s is never reached (0 hits); the mode forces a hit and the gate FAILs"
    else
        echo "CONTROL DEAD: vanilla-walker-reached — vanilla walker $s reached $h time(s)"
        echo "  FAIL: vanilla walker $s still reached $h time(s) — a caller was"
        echo "        MISSED. Legacy stays bit-identical (it is vanilla), but a"
        echo "        tenant object dispatched there over-indexes the vanilla"
        echo "        table. Re-run tools/audit_walker_callers.py and look for a"
        echo "        reference form it does not cover (a computed target)."
        fail=1
    fi
done
for s in $(echo "$NEW" | tr ',' ' '); do
    h=$(total_for new "$s")
    if [ "${h:-0}" -gt 0 ]; then echo "  ok: relocated $s reached $h time(s)"
    else
        echo "  FAIL: relocated walker $s NEVER ran — the repoint did not take,"
        echo "        or this replay set does not reach it."
        fail=1
    fi
done

echo
echo "== 2. NEGATIVE CONTROL on $REF_BUILD (not relocated): vanilla MUST fire =="
if [ ! -f "$REF_BUILD/rompath/vsavjw.zip" ]; then
    echo "  FAIL: no $REF_BUILD/rompath/vsavjw.zip — without this control every"
    echo "        zero above is indistinguishable from a dead breakpoint."
    fail=1
else
    run_leg ref "$REF_BUILD" "$OLD" "$_clk"
    any=0
    for s in $(echo "$OLD" | tr ',' ' '); do
        h=$(total_for ref "$s")
        echo "  ref $s: $h hits"
        [ "${h:-0}" -gt 0 ] && any=1
    done
    if [ "$any" = 1 ]; then
        echo "  ok: the instrument sees the vanilla walkers on an un-relocated"
        echo "      build, so section 1's zeros are real"
    else
        echo "  FAIL: the vanilla walkers did not fire on $REF_BUILD either —"
        echo "        the instrument is dead and section 1 proves nothing."
        fail=1
    fi
fi

echo
echo "== 3. the instrument's alignment (#228 step 4, option A) =="
if [ "$FREEZE_CLOCK" = 1 ]; then
    run_leg rnew "$BUILD" "$OLD,$NEW" "INSTR_REFERENCE=1"
    run_leg rref "$REF_BUILD" "$OLD" "INSTR_REFERENCE=1"
    # neither build has a basis: each reference leg is held to replay.lua run live on its build (rule-checker run
    # 2026-10-10-798 Q1; #213's method)
    pool=0
    for r in $REPLAYS; do
        ( ia_replaylua_run vsavjw "$PWD/$BUILD/rompath;$ROMDIR" "$PWD/tests/replays/$r.rpl" "$W/rl_new/$r" ) </dev/null &
        ( ia_replaylua_run vsavjw "$PWD/$REF_BUILD/rompath;$ROMDIR" "$PWD/tests/replays/$r.rpl" "$W/rl_ref/$r" ) </dev/null &
        pool=$((pool + 2)); [ "$pool" -ge "$JOBS" ] && { wait; pool=0; }
    done
    wait
    bad=0; : > "$W/clocks.tsv"
    for r in $REPLAYS; do
        for lg in new:new:rnew ref:ref:rref; do
            leg="${lg%%:*}"; rest="${lg#*:}"; bp="$W/${rest%%:*}_$r.align"; rf="$W/${rest#*:}_$r.align"
            [ -s "$rf" ] || { echo "  $leg/$r: the reference leg wrote no ALIGN line"; bad=1; continue; }
            a="$(ia_anchor "$rf")"; af="$(ia_anchor_frame "$rf")"; want="$(ia_replaylua_read "$W/rl_$leg/$r" "$af")"
            [ -n "$a" ] && [ "$a" = "$want" ] || { echo "  $leg/$r: the reference leg reads ${a:-nothing} at frame ${af:-?}, replay.lua live ${want:-nothing}"; bad=1; }
            [ "$(ia_field "$bp" frames)" = "$(ia_field "$bp" emulated)" ] || { echo "  $leg/$r: the breakpoint run counted $(ia_field "$bp" frames) over $(ia_field "$bp" emulated) emulated"; bad=1; }
            [ "$(ia_field "$bp" gameclock)" = "$(ia_field "$rf" gameclock)" ] || { echo "  $leg/$r: the breakpoint run's game clock $(ia_field "$bp" gameclock), its reference leg's $(ia_field "$rf" gameclock)"; bad=1; }
            ia_row "$leg" "$r" "$rf" >> "$W/clocks.tsv"
        done
    done
    [ "$bad" = 0 ] || { echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    [ "$fail" = 0 ] || { echo "REFUSED: sections 1-2 failed — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/audit_walker_repoint.sh <build> --freeze-clock\` at $(git rev-parse --short=8 HEAD): new = $BUILD, ref = $REF_BUILD."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$W/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$W/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
: > "$W/align_bad.txt"
for r in $REPLAYS; do
    ia_check "$CLOCKS" new "$r" "$W/new_$r.align" >> "$W/align_bad.txt" || true
    [ -f "$REF_BUILD/rompath/vsavjw.zip" ] && ia_check "$CLOCKS" ref "$r" "$W/ref_$r.align" >> "$W/align_bad.txt" || true
done
if [ -s "$W/align_bad.txt" ]; then echo "  FAIL: $(wc -l < "$W/align_bad.txt" | tr -d ' ') run(s) off their frozen alignment:"; head -8 "$W/align_bad.txt" | sed 's/^/        /'; fail=1
else echo "  ok: every run of both builds on emulated time, at its frozen game clock"; fi
# the staging reference leg: 21_don_mash on the build, held to replay.lua run live (no basis for a hacked build)
SR=21_don_mash; SF="$(frames_for "$SR")"
run_leg stage "$BUILD" "$OLD,$NEW" "INSTR_REFERENCE=1 $_skip" "$SR"
RL="$(ia_replaylua_at vsavjw "$PWD/$BUILD/rompath;$ROMDIR" "$PWD/tests/replays/$SR.rpl" "$SF" "$W/rl")"
sa="$(ia_anchor "$W/stage_$SR.align")"
if [ -n "$RL" ] && [ "$sa" = "$RL" ]; then echo "  ok: the staging reference leg reproduces replay.lua at frame $SF ($sa)"
else echo "  FAIL: the staging reference leg reads ${sa:-nothing} at frame $SF, replay.lua ${RL:-nothing}"; fail=1; fi
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "FAIL: audit_walker_repoint (control mode: $MODE)"; exit 1; }
    echo "FAIL: audit_walker_repoint — control mode $MODE left the gate green"; exit 1
fi
run_leg cdrift "$BUILD" "$OLD,$NEW" "INSTR_CLOCK=frame_done" "$SR"
if ia_check "$CLOCKS" new "$SR" "$W/cdrift_$SR.align" > "$W/cdrift.txt"; then
    vs_ctl_dead drift-clock "the frame_done clock still met the frozen game clock" || fail=1
else vs_ctl_fired drift-clock "$(head -1 "$W/cdrift.txt")"; fi
run_leg cskip "$BUILD" "$OLD,$NEW" "INSTR_REFERENCE=1 INSTR_CLOCK=skip_first" "$SR"
ka="$(ia_anchor "$W/cskip_$SR.align")"
if [ -z "$ka" ]; then vs_ctl_dead first-frame-skip "the skip leg wrote no anchor" || fail=1
elif [ "$ka" != "$RL" ]; then vs_ctl_fired first-frame-skip "under the first-frame skip the staging leg reads $ka at frame $SF where replay.lua reads $RL"
else vs_ctl_dead first-frame-skip "the skipped clock still reproduced replay.lua" || fail=1; fi

echo
[ "$fail" = 0 ] && echo "WALKER REPOINT: PASS" || echo "WALKER REPOINT: FAIL"
exit "$fail"
