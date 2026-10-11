#!/bin/sh
# audit_ranking_tenant.sh — A TENANT PLAYER'S SCORE REACHES THE ATTRACT SCORE RANKING (14z-195, GitHub #124).
# Emulator tier, MAME lane: two -debug legs of the 40,620-frame 1P marathon in parallel, ~15 min.
#
# WHAT: the SCORE RANKING (the attract screen after a 1P run) draws each entry's name tag and small
#   portrait from the same name array PRG:0x26752A and portrait array PRG:0x26762A the arcade map
#   reads, indexed by the entry's character id (the reader at PRG:0x08C5D6-0x08C612, unpatched on the
#   merged build — tests/test_map_table_readers.sh). With P1 forced to Donovan (0x13) the player's
#   run enters the ranking's 1st entry with id 0x13, so #124's tenant rows are read there too: on
#   merged-m23 it draws "VICTOR" and a blank portrait where native Vampire Savior 2 draws "DONOVAN" (14z-195,
#   capture sheet on #124). This gate holds the REACH — the id the ranking is handed — not the look,
#   which #124's fix will gate.
# HOW: tests/replays/26_don_arcade_mash.rpl on the merged build under tools/run_replay_guarded.sh with a
#   logging breakpoint at the ranking's portrait read (GUARD_PROBE=08c5e0: D0 = the entry's id) and a
#   dump of P1's id at frame 2000; leg `don13` pokes RAM:$FF8782 = 0x13 at 1400/1450/1500 (the
#   forced pick, through select only — the ranking id is the committed character), leg `none` does
#   not. Each leg in its own directory and sandbox.
# EXPECTS: leg don13 — P1's id 0x13 at frame 2000 and the ranking's first probe id 0x13; leg none —
#   the ranking's first probe id 0x0F (Jedah, the replay's real pick on the merged wheel): the entry
#   follows the player. Every leg ends END 40620 with at least 25 ranking probes; both legs on emulated time at their
#   frozen game clocks, the staging leg on replay.lua's checksum.
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): replay_guard.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua); both legs' game clock RAM:$FF8080 at the last frame is held to
#   tests/expected/instr_gameclock/audit_ranking_tenant.tsv, frozen by `--freeze-clock` from REFERENCE legs (the guard
#   without -debug, the same POKES) each held to replay.lua run live; one STAGING reference leg (`none`) is held to
#   replay.lua on every run (tests/lib/instr_align.sh). Each of those is a 40,620-frame run: ~30 min with them.
#
# MUST-FIRE: known-bad: drift-clock — a leg under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 40,584 emulated frames of 40,620 counted) must miss its frozen game clock (in-gate: one extra run; mode: both legs run the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
# MUST-FIRE: known-bad: poke-dropped — the don13 leg run WITHOUT its pokes must read a first ranking id other than 0x13, and the gate must FAIL (mode: the don13 leg drops its pokes)
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/instr_gameclock/ tests/lib/controls.sh
#   tests/lib/instr_align.sh tests/lua/emu_clock.lua tests/lua/replay.lua tests/lua/replay_guard.lua
#   tests/replays/26_don_arcade_mash.rpl tools/build_fingerprint.py tools/run_mame.sh tools/run_replay_guarded.sh
#   tools/setup_mame.sh
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged31] tests/audit_ranking_tenant.sh [--freeze-clock]
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
FREEZE_CLOCK=0; [ "${1:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
CLOCKS="tests/expected/instr_gameclock/audit_ranking_tenant.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"
BUILD="${BUILD:-build/m3b_merged31}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
RPL=tests/replays/26_don_arcade_mash.rpl
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/ranktenant.XXXXXX")}"; mkdir -p "$W"
[ -n "${OUT:-}" ] || trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
FORCE="1400:ff8782:13;1450:ff8782:13;1500:ff8782:13"
DON_POKES="$FORCE"; vs_ctl_is poke-dropped && DON_POKES=""

leg() {  # leg <name> <pokes>
    mkdir -p "$W/$1"
    # shellcheck disable=SC2086
    env $_clk MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" POKES="$2" GUARD_PROBE=08c5e0 DUMPS="2000:ff8782-ff8782" ALIGN_OUT="$W/$1/align" \
        tools/run_replay_guarded.sh vsavjw "$RPL" "$W/$1/run.log" "$W/$1/sb" > "$W/$1/run.out" 2>&1
}
echo "== audit_ranking_tenant: $BUILD ($(python3 tools/build_fingerprint.py "$BUILD/rompath" --set vsavjw --sha-only 2>/dev/null | cut -c1-8))"
leg don13 "$DON_POKES" & p1=$!
leg none "" & p2=$!
wait "$p1"; wait "$p2"
ia_note_run "$W/manifest.tsv" don13 26_don_arcade_mash vsavjw "$REPO/$BUILD/rompath;$ROMDIR" "$REPO/$RPL" \
    "MAME_BIN=$MAME_BIN POKES=$DON_POKES GUARD_PROBE=08c5e0 DUMPS=2000:ff8782-ff8782" "$W/don13/align"
ia_note_run "$W/manifest.tsv" none 26_don_arcade_mash vsavjw "$REPO/$BUILD/rompath;$ROMDIR" "$REPO/$RPL" \
    "MAME_BIN=$MAME_BIN POKES= GUARD_PROBE=08c5e0 DUMPS=2000:ff8782-ff8782" "$W/none/align"

first_id() { grep -m1 '^PROBE' "$1" | sed -n 's/.* D0=\([0-9a-f]*\).*/\1/p' | tail -c 3; }
for l in don13 none; do
    lg="$W/$l/run.log"
    if grep -q '^END 40620' "$lg" 2>/dev/null; then ok "leg $l ended END 40620"; else bad "leg $l did not end clean: $(grep -m1 -E '^(END|CRASH)' "$lg" 2>/dev/null)"; fi
    n="$(grep -c '^PROBE' "$lg" 2>/dev/null)" || true
    [ "${n:-0}" -ge 25 ] && ok "leg $l: $n ranking probes" || bad "leg $l: ${n:-0} ranking probes (the ranking was never drawn)"
done
d="$(ls "$W/don13"/dump_2000_ff8782* 2>/dev/null | head -1)"
pid="$( [ -n "$d" ] && od -An -tx1 "$d" | tr -d ' \n')"
fd="$(first_id "$W/don13/run.log")"; fn="$(first_id "$W/none/run.log")"
if vs_ctl_is poke-dropped; then
    echo "  (mode poke-dropped: the don13 leg ran without its pokes; P1 id at 2000 = ${pid:-?})"
else
    [ "$pid" = 13 ] && ok "leg don13: P1's id is 0x13 at frame 2000 (the forced pick held)" || bad "leg don13: P1's id at frame 2000 reads '${pid:-none}'"
fi
[ "$fd" = 13 ] && ok "leg don13: the ranking's 1st entry is id 0x13 — a tenant player's id reaches the ranking" || bad "leg don13: the ranking's first id is '${fd:-none}' (want 13)"
[ "$fn" = 0f ] && ok "leg none: the ranking's 1st entry is id 0x0F (Jedah, the real pick)" || bad "leg none: the ranking's first id is '${fn:-none}' (want 0f)"

echo "== controls"
if vs_ctl_is poke-dropped; then
    vs_ctl_fired poke-dropped "the don13 leg ran without its pokes (mode)"
elif [ -n "$fn" ] && [ "$fn" != 13 ]; then
    vs_ctl_fired poke-dropped "the unpoked leg's first ranking id is 0x$fn, not 0x13"
else
    vs_ctl_dead poke-dropped "the unpoked leg read '${fn:-none}'"; fail=1
fi
echo "== the instrument's alignment (#228 step 4, option A)"
if [ "$FREEZE_CLOCK" = 1 ]; then
    [ "$fail" = 0 ] || { echo "REFUSED: the audit failed — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" "$W/fz" "${JOBS:-4}" "$W/clocks.tsv" \
        > "$W/fz.txt" || { sed 's/^/  /' "$W/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/audit_ranking_tenant.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): build = $BUILD;"
      echo "# every reference leg held to replay.lua run live, every guarded leg to its reference leg's game clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$W/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$W/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
if ia_check_manifest "$CLOCKS" "$W/manifest.tsv" > "$W/align_bad.txt"; then ok "both legs on emulated time, at their frozen game clocks"
else bad "$(wc -l < "$W/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$W/align_bad.txt" | sed 's/^/        /'; fi
ia_stage audit_ranking_tenant "$CLOCKS" "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" 2 "$W/st" "$MODE" || fail=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "FAIL (control mode: $MODE)"; exit 1; }
    echo "FAIL — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
