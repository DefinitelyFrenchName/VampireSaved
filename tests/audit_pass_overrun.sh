#!/bin/sh
# audit_pass_overrun.sh — THE BLIZZARD SWORD CPU OVERRUNS, ours vs native, frozen AS MEASURED (14z-168, GitHub #136): on three Blizzard Sword frames of the whole #136 corpus a double-pass activation runs past the frame, so one frame completes NO logic pass — twice on native vsav2 (donovan_2, donovan_11), once on ours (donovan_10) — and the rest of each part stays one engine pass out of step with its inputs. Per event window the scheduler's idle time is equal on both builds within about 1%.
#
# MUST-FIRE: perturbed-copy: overrun-planted — a copy of our donovan_11 trace with one pass-counter step removed (a zero-pass frame planted where ours has none) must change our overrun row and FAIL the frozen compare, so an `overrun ... none` row is a reading of the trace (in-gate: the planted copy must reduce differently; mode: every part's trace is planted before the reduction and the table FAILs)
#
# WHY. 29 of #136's 108 DIFF rows (tests/audit_move_parity_attribution.sh, class
# SLOWDOWN) begin on a frame where RAM:$FF8081 — the pass counter, stepped at the top
# of every logic pass (docs/game/engine_internals.md, the play-mode paragraph) — does not
# step on one leg, right after a double-pass frame. It is not a port cost: native loses
# the pass in two of the three parts, and the idle-spin dispatches of the scheduler's
# spin slot (15; the state-8 write at PRG:0x001204/0x001218 on the task table
# $FF025C, as tests/audit_tick_cadence.sh reads it) average the same per window on both
# builds (ratio 1.00-1.01). Which frame overruns is set by where the work falls inside a
# frame. The host engine's clock governs —
# the maintainer, 2026-09-02, #114: "we must respect the fact that we are porting the
# character to a different engine and the engine, being vanilla vsav, takes precedence."
# (DECISIONS_HISTORY.md, the #114 lines).
#
# WHAT IT FREEZES (tests/expected/pass_overrun.tsv):
#   overrun <part> <leg> <zero-pass frames after the round start | none>
#   idle <part> <event> <leg> mean=<spin dispatches per frame, 1 decimal> zero=<frames with none>
#   for donovan_2 (events 0-2), donovan_10 (0-1) and donovan_11 (the P2 block event and
#   Blizzard Sword [LP] blocked), the committed rigs with the parity gate's pins.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged26] [FREEZE=1] tests/audit_pass_overrun.sh
#   emulator tier, MAME; 12 runs (the task taps write ~100 MB each, deleted with the work dir) —
#   measured 14z-168 on this MacBook, solo: ~60 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/pass_overrun.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|overrun-planted) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
PARTS="donovan_2:3110 donovan_10:3000 donovan_11:4590"   # part:last frame (past each overrun)
OURS_PATH_donovan="D D DR DR"
pokes_for() {  # pokes_for <json> <frames> (the parity gate's, copied)
    _b="$(python3 -c "import json;print(';'.join(json.load(open('$1'))['pokes']))")"
    _l="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$2)))")"
    _r="$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$2)))")"
    printf '%s;%s;%s' "$_b" "$_l" "$_r"
}
rpl_for() {  # rpl_for <rig.rpl> <leg> <out.rpl>
    if [ "$2" = native ]; then cp "$1" "$3"; return; fi
    awk -v path="$OURS_PATH_donovan" '
        /^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
        { print }' "$1" > "$3"
}
for pf in $PARTS; do
    part="${pf%:*}"; fr="${pf#*:}"
    j="$REPO/tests/replays/naming/$part.json"; pk="$(pokes_for "$j" "$fr")"
    for leg in native ours; do
        rpl_for "$REPO/tests/replays/naming/$part.rpl" "$leg" "$W/$part.$leg.rpl"
        if [ $leg = native ]; then set_=vsav2; rp="$ROMDIR"; else set_=vsavjw; rp="$BUILD/rompath;$ROMDIR"; fi
        for k in f t; do d="$W/$part.$leg.$k"; mkdir -p "$d"; done
        # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log (docs/platform/gotchas.md):
        # `set +e` keeps the status write alive, and a run whose instrument wrote its summary line counts as
        # completed (docs/project/gotchas.md, the set -e capture entry)
        ( set +e; cd "$W/$part.$leg.f" && MAME_SANDBOX="$W/$part.$leg.f/sb" MAME_ROMPATH="$rp" REPLAY="$W/$part.$leg.rpl" POKES="$pk" \
            FIELDS="ff8081:b:pc,ff8080:b:fc" FIELD_OUT="$W/$part.$leg.ft" FIELD_FROM=2540 FIELD_TO="$fr" FRAMES="$fr" \
            "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$part.$leg.f/mame.log" 2>&1
          _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$W/$part.$leg.ft" 2>/dev/null && _st=0; echo $_st > "$W/$part.$leg.f/rc"; rm -rf "$W/$part.$leg.f/sb" ) </dev/null &
        ( set +e; cd "$W/$part.$leg.t" && MAME_SANDBOX="$W/$part.$leg.t/sb" MAME_ROMPATH="$rp" REPLAY="$W/$part.$leg.rpl" POKES="$pk" \
            RTAP=ff025c,512 WINDOW=999999,999999 FRAMES="$fr" TRACE_OUT="$W/$part.$leg.tap" \
            "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/$part.$leg.t/mame.log" 2>&1
          _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$W/$part.$leg.tap" 2>/dev/null && _st=0; echo $_st > "$W/$part.$leg.t/rc"; rm -rf "$W/$part.$leg.t/sb" ) </dev/null &
    done
    wait
done
# the task tap segfaults MAME at teardown on some legs (docs/platform/gotchas.md, the hot-field tap) — its log is
# evidence only if it carries its END line; the field traces must exit 0
for pf in $PARTS; do part="${pf%:*}"; for leg in native ours; do
    _rc="$(cat "$W/$part.$leg.f/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$part $leg trace exited $_rc"
    tail -1 "$W/$part.$leg.tap" 2>/dev/null | grep -q '^END ' || bad "$part $leg task tap has no END line (exit $(cat "$W/$part.$leg.t/rc" 2>/dev/null))"
done; done
[ "$fail" = 0 ] || { echo "FAIL: audit_pass_overrun"; exit 1; }
plant() {  # plant <trace in> <trace out>: one pass-counter step removed at 4000 (a planted zero-pass frame)
    awk '$1=="F" && $2>=4000 { for (i = 3; i <= NF; i++) if ($i ~ /^pc=/) { v = substr($i, 4) - 1; if (v < 0) v += 256; $i = "pc=" v } } {print}' "$1" > "$2"
}
if [ "$CONTROL" = overrun-planted ]; then for pf in $PARTS; do part="${pf%:*}"; plant "$W/$part.ours.ft" "$W/p.ft" && mv "$W/p.ft" "$W/$part.ours.ft"; done; fi
reduce() {  # reduce <W> <parts>
    python3 - "$1" "$2" <<'PY'
import sys
W, parts = sys.argv[1], sys.argv[2].split()
for pf in parts:
    part = pf.split(":")[0]
    for leg in ("native", "ours"):
        d = {}
        for l in open(f"{W}/{part}.{leg}.ft"):
            t = l.split()
            if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
        z = [f for f in sorted(d) if f > 2546 and f - 1 in d and (d[f]["pc"] - d[f - 1]["pc"]) % 256 == 0]
        print(f"overrun\t{part}\t{leg}\t{','.join(map(str, z)) or 'none'}")
PY
}
: > "$W/got.tsv"
reduce "$W" "$PARTS" >> "$W/got.tsv" 2> "$W/err" || bad "$(cat "$W/err")"
python3 - "$W" "$REPO" "$PARTS" >> "$W/got.tsv" 2>> "$W/err" <<'PY' || bad "$(cat "$W/err")"
import sys, json, collections, statistics
W, REPO, parts = sys.argv[1], sys.argv[2], sys.argv[3].split()
for pf in parts:
    part, last = pf.split(":"); last = int(last)
    ev = json.load(open(f"{REPO}/tests/replays/naming/{part}.json"))["events"]
    disp = {}
    for leg in ("native", "ours"):
        c = collections.Counter()
        for l in open(f"{W}/{part}.{leg}.tap"):
            if l[0] != "W": continue
            t = l.split(); off = int(t[5], 16)
            if t[3] in ("001204", "001218") and (off - 0xFF025C) % 0x20 == 0 and (off - 0xFF025C) // 0x20 == 15:
                c[int(t[1])] += 1
        disp[leg] = c
    for k, e in enumerate(ev):
        lo = e["frame"]; hi = min((ev[k + 1]["frame"] if k + 1 < len(ev) else lo + e["gap"]) - 1, last - 1)
        if lo >= last: break
        if lo > hi: continue   # a zero-length window (donovan_11's "P2 blocks" setup event)
        for leg in ("native", "ours"):
            v = [disp[leg][f] for f in range(lo, hi + 1)]
            print(f"idle\t{part}\t{k}\t{leg}\tmean={statistics.mean(v):.1f}\tzero={sum(1 for x in v if x == 0)}")
PY
[ "$fail" = 0 ] || { echo "FAIL: audit_pass_overrun"; exit 1; }
sed 's/^/  /' "$W/got.tsv"

if [ "${FREEZE:-0}" = 1 ]; then
    { echo "# tests/expected/pass_overrun.tsv — the Blizzard Sword CPU overruns (zero-pass frames, RAM:\$FF8081) and the scheduler's idle"
      echo "# spin dispatches per event window, ours (merged-m18) vs native vsav2 (tests/audit_pass_overrun.sh; field_trace + read_tap on"
      echo "# the task table). Evidence class: in-emulator. Frozen 14z-168 with FREEZE=1 (GitHub #136, class SLOWDOWN)."
      echo "# Columns: overrun <part> <leg> <frames|none> | idle <part> <event> <leg> mean= zero="
      echo "#--"; cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi

if [ "$CONTROL" = overrun-planted ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: overrun-planted — a planted zero-pass frame turns our overrun rows"; echo "FAIL: audit_pass_overrun (control mode)"; exit 1
    else echo "CONTROL DEAD: overrun-planted — the plant changed nothing"; echo "FAIL: audit_pass_overrun"; exit 1; fi
fi
plant "$W/donovan_11.ours.ft" "$W/ctl.ft"; cp "$W/donovan_11.ours.ft" "$W/keep.ft"; cp "$W/ctl.ft" "$W/donovan_11.ours.ft"
reduce "$W" "donovan_11:4590" > "$W/ctl.rows" 2>/dev/null || true; cp "$W/keep.ft" "$W/donovan_11.ours.ft"
pl_row="$(awk -F'\t' '$1=="overrun" && $2=="donovan_11" && $3=="ours" {print $4}' "$W/ctl.rows")"
real_row="$(awk -F'\t' '$1=="overrun" && $2=="donovan_11" && $3=="ours" {print $4}' "$W/got.tsv")"
if [ -n "$pl_row" ] && [ "$pl_row" != "$real_row" ]; then
    echo "CONTROL FIRED: overrun-planted — the planted trace reads $pl_row where ours reads $real_row"
else echo "CONTROL DEAD: overrun-planted — the planted zero-pass frame was not read"; fail=1; fi
if [ "$fail" = 0 ]; then echo "PASS: audit_pass_overrun"; else echo "FAIL: audit_pass_overrun"; exit 1; fi
