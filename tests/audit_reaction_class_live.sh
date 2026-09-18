#!/bin/sh
# audit_reaction_class_live.sh — EVERY WRITE AND READ OF THE VICTIM'S REACTION CLASS (+0x54) OVER THE CORPUS, on pristine vsavj (the whole legacy suite), on our merged build and on native vs2 (the #136 naming parts), frozen (14z-169, the analysis before the class-0x52 fix of the column shock and the Plasma Trap, #136, which the maintainer ruled on 2026-09-18: "then I'm all for fixing. Once again, as long as we don't introduce noticeable lag and we don't break more things, it's a pure win/win" — DECISIONS_HISTORY.md): the live half of tests/test_reaction_classes.sh, which can see only constant writes.
#
# MUST-FIRE: perturbed-copy: planted-38 — a run of 02_demitri_vs_cpu on pristine vsavj with a Lua poke of 0x38 into P1's +0x54 at frame 3000 must be reported as a 0x38 write and FAIL the no-0x38 check, so the check reads what the tap logged (in-gate: that one run must report the value; mode: every vsavj run carries the poke and the gate FAILs)
# MUST-FIRE: perturbed-copy: range-silent — a copy of a tap log with every access to P2's +0x54 window deleted must be reported as a DEAD range, so each run's two windows are each proven live to the end before their silence is trusted (in-gate: the first run's copy must read P2 dead; mode: every run's log is perturbed before the liveness check and the gate FAILs)
#
# WHY. tests/test_reaction_classes.sh shows statically that no stager handler and no
# `move.b #imm,$54(An)` in vsavj writes 0x38 into a victim's +0x54, which would make the
# reaction table's 0x38 entry — the electric-shock handler 0x23AC8, property 0x0F, the
# same as 0x06 — reachable by nothing in vanilla. A static scan cannot see +0x54 written
# from a REGISTER, or by code outside the scanned range. This gate taps it: both fighter
# blocks' +0x54/+0x55 (tests/lua/read_tap.lua, non-debug, two 2-byte windows), every
# write attributed by pc and the +0x54 byte's value, every read by pc with the values it
# saw. It also names the CONSUMERS of +0x54 (the read pcs), which the fix's design needs.
#
# THE SAMPLE (three legs):
#   vsavj  — pristine vsavj, EVERY replay under tests/replays/*.rpl, unpoked, for its
#            scripted length + 120 frames (tests/lua/replay.lua's tail) — the legacy corpus;
#   ours   — the merged build, the 30 #136 naming parts (tests/replays/naming/<tenant>_<n>)
#            with tests/audit_move_parity.sh's own inputs and pokes (the merged wheel's
#            path, the level pinned to 6 from 2000 and the RNG from 2363);
#   native — vsav2, the same 30 parts as committed, with the same pins.
# NOT SAMPLED: every path the corpus does not run. A 0x38 write on a path no replay takes
# is not excluded by this gate — the static census (test_reaction_classes) is the other
# half, and neither is a proof of universal absence.
#
# LIVENESS, PER WINDOW: a run counts only if it has an END line and the END PROBE — a Lua
# poke of +0x55 (tapped, outside the measured byte) on each block on the run's last frame —
# is logged in BOTH windows, so a tap lost mid-run cannot pass as silence. POSITIVE
# CONTROLS on the reading: ours must show vsavj's ground stager writing 6 (0x186D0-0x186D5,
# the tenants' remapped electric hits reach it) and native must show vs2's writing 0x52
# (0x16FEC-0x16FF1, its column and trap on a grounded victim).
#
# FROZEN: tests/expected/reaction_class_live.tsv — `<leg> W <pc> <value> <blocks> <runs>`
# per (pc, +0x54 value) written, `<leg> R <pc> <blocks> <runs> <values seen>` per read pc,
# and `<leg> runs <n>`. The ours rows follow the build (placed pcs move): re-freeze at every
# freeze (FREEZE=1), reviewing the diff.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged26] [JOBS=6] [LEGS="vsavj ours native"] [FREEZE=1] tests/audit_reaction_class_live.sh
#   emulator tier, MAME; 148 tap runs — measured 14z-169 on this MacBook, solo, JOBS=6: see the header of the first frozen run (PROVENANCE)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/reaction_class_live.tsv"
JOBS="${JOBS:-6}"
LEGS="${LEGS:-vsavj ours native}"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|planted-38|range-silent) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
RTAP="ff8454,2;ff8854,2"
PLANT_POKE="3000:ff8454:38"

# ONE runner: the tap, the END PROBE on the last frame, and the planted poke when asked ([VSP-181])
tap_run() {  # tap_run <leg> <name> <set> <rompath> <rpl> <pokes> <frames>
    _d="$W/$1/$2"; mkdir -p "$_d"
    _pk="$6${6:+;}$(($7 - 1)):ff8455:00;$(($7 - 1)):ff8855:00"
    # set +e: MAME can segfault at TEARDOWN after the log is closed (docs/platform/gotchas.md, the
    # tap-installer entry; 14z-168's backgrounded-leg fix) — the verdict rests on the END line, never the exit code
    ( set +e; cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$4" REPLAY="$5" POKES="$_pk" RTAP="$RTAP" \
        TRACE_OUT="$_d/t.tap" FRAMES="$7" "$REPO/tools/run_mame.sh" "$3" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$_d/mame.log" 2>&1
      echo $? > "$_d/rc"; rm -rf "$_d/sb" ) </dev/null &
    _n=$((_n + 1)); [ $((_n % JOBS)) -eq 0 ] && wait
    return 0
}
rpl_frames() { awk '!/^#/ && NF { split($1, a, "-"); v = a[length(a)] + 0; if (v > m) m = v } END { print m + 120 }' "$1"; }
OURS_PATH_donovan="D D DR DR"; OURS_PATH_huitzil="D D D"; OURS_PATH_pyron="D D D D"
_n=0

echo "== 1. the tap runs ($LEGS)"
T0="$(date +%s)"
for leg in $LEGS; do
    case "$leg" in
    vsavj)
        for r in "$REPO"/tests/replays/*.rpl; do
            _pk=""; [ "$CONTROL" = planted-38 ] && _pk="$PLANT_POKE"
            tap_run vsavj "$(basename "$r" .rpl)" vsavj "$ROMDIR" "$r" "$_pk" "$(rpl_frames "$r")"
        done ;;
    ours|native)
        for j in "$REPO"/tests/replays/naming/donovan_[0-9]*.json "$REPO"/tests/replays/naming/huitzil_[0-9]*.json "$REPO"/tests/replays/naming/pyron_[0-9]*.json; do
            name="$(basename "$j" .json)"; t="${name%_*}"
            fr="$(python3 -c "import json;print(json.load(open('$j'))['frames'])")"
            pk="$(python3 -c "import json;print(';'.join(json.load(open('$j'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$fr)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$fr)))")"
            if [ "$leg" = native ]; then
                tap_run native "$name" vsav2 "$ROMDIR" "${j%.json}.rpl" "$pk" "$fr"
            else
                eval "_path=\$OURS_PATH_$t"
                mkdir -p "$W/rpl"
                awk -v path="$_path" '
                    /^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
                        for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
                    /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
                    { print }' "${j%.json}.rpl" > "$W/rpl/$name.rpl"
                tap_run ours "$name" vsavjw "$BUILD/rompath;$ROMDIR" "$W/rpl/$name.rpl" "$pk" "$fr"
            fi
        done ;;
    *) echo "FAIL: unknown leg '$leg'"; exit 1 ;;
    esac
done
# the in-gate planted-38 run (one vsavj replay with the poke), unless the mode already plants every run
if [ -z "$CONTROL" ]; then
    tap_run ctl planted38 vsavj "$ROMDIR" "$REPO/tests/replays/02_demitri_vs_cpu.rpl" "$PLANT_POKE" "$(rpl_frames "$REPO/tests/replays/02_demitri_vs_cpu.rpl")"
fi
wait
ok "$(ls -d "$W"/*/*/ 2>/dev/null | wc -l | tr -d ' ') runs in $(( $(date +%s) - T0 )) s"

# ONE liveness reader and ONE perturbation, shared by the gate, the in-gate control and the mode
dead_windows() {  # dead_windows <tap> <frames>: each window lacking the END line or its END PROBE write
    awk -v last="$(($2 - 1))" '$1=="END" { e = 1 }
        $1=="W" && $2==last && $10=="000000ff" { if ($6=="ff8454") p[1] = 1; if ($6=="ff8854") p[2] = 1 }
        END { if (!e) printf "no-END "; for (r = 1; r <= 2; r++) if (!p[r]) printf "P%d(end-probe) ", r }' "$1"
}
silence_p2() { awk '!(($1 == "W" || $1 == "R") && $6 == "ff8854")' "$1" > "$2"; }

echo "== 2. liveness"
for d in "$W"/*/*/; do
    run="$(basename "$(dirname "$d")")/$(basename "$d")"
    [ "$(basename "$(dirname "$d")")" = rpl ] && continue
    tap="$d/t.tap"
    fr="$(awk '$1=="END" { print $2 }' "$tap" 2>/dev/null)"
    [ -n "$fr" ] || { bad "$run: no END line (exit $(cat "$d/rc" 2>/dev/null || echo none)) — a dead tap is not evidence"; continue; }
    if [ "$CONTROL" = range-silent ]; then silence_p2 "$tap" "$tap.sil" && mv "$tap.sil" "$tap"; fi
    _dw="$(dead_windows "$tap" "$fr")"
    [ -z "$_dw" ] || bad "$run: ${_dw}— that window is dead"
done
if [ "$CONTROL" = range-silent ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: range-silent — every run reads P2's window dead"; echo "FAIL: audit_reaction_class_live (control mode)"; exit 1
    else echo "CONTROL DEAD: range-silent — the silenced window still read live"; echo "FAIL: audit_reaction_class_live"; exit 1; fi
fi
[ "$fail" = 0 ] || { echo "FAIL: audit_reaction_class_live"; exit 1; }
ok "every run ends with both END-probe writes logged"
_first="$(ls -d "$W"/vsavj/*/ "$W"/ours/*/ 2>/dev/null | head -1)"
if [ -n "$_first" ]; then
    silence_p2 "$_first/t.tap" "$W/ctl_range.tap"
    _dr="$(dead_windows "$W/ctl_range.tap" "$(awk '$1=="END" { print $2 }' "$_first/t.tap")")"
    if [ "$_dr" = "P2(end-probe) " ]; then echo "CONTROL FIRED: range-silent — $(basename "$_first") without P2's accesses reads ${_dr}dead"
    else echo "CONTROL DEAD: range-silent — $(basename "$_first") without P2's accesses reads '$_dr'"; fail=1; fi
fi

echo "== 3. the reduction"
reduce() {  # reduce <out.tsv> <leg...> — ONE reducer for the gate and the controls
    _o="$1"; shift
    python3 - "$W" "$_o" "$@" <<'PY'
import sys, os, collections
W, out, legs = sys.argv[1], sys.argv[2], sys.argv[3:]
rows = []
for leg in legs:
    d = os.path.join(W, leg)
    if not os.path.isdir(d):
        continue
    wr, rd, runs = collections.defaultdict(lambda: [set(), set()]), collections.defaultdict(lambda: [set(), set(), set()]), 0
    for run in sorted(os.listdir(d)):
        tap = os.path.join(d, run, "t.tap")
        if not os.path.exists(tap):
            continue
        runs += 1
        last = None
        lines = open(tap).read().split("\n")
        for l in lines:
            x = l.split()
            if x and x[0] == "END":
                last = int(x[1]) - 1
        for l in lines:
            x = l.split()
            if not x or x[0] not in ("R", "W"):
                continue
            mask = int(x[9], 16)
            if not mask & 0xFF00:
                continue          # the +0x55 byte only (the END probe among them)
            fr, pc, blk, val = int(x[1]), x[3], "P1" if x[5] == "ff8454" else "P2", (int(x[7], 16) >> 8) & 0xFF
            if x[0] == "W":
                e = wr[(pc, f"{val:02x}")]; e[0].add(run); e[1].add(blk)
            else:
                e = rd[pc]; e[0].add(run); e[1].add(blk); e[2].add(f"{val:02x}")
    rows.append(f"{leg}\truns\t{runs}")
    for (pc, v), (rs, bs) in sorted(wr.items()):
        rows.append(f"{leg}\tW\t{pc}\t{v}\t{','.join(sorted(bs))}\t{len(rs)}")
    for pc, (rs, bs, vs) in sorted(rd.items()):
        rows.append(f"{leg}\tR\t{pc}\t{','.join(sorted(bs))}\t{len(rs)}\t{','.join(sorted(vs))}")
open(out, "w").write("\n".join(rows) + "\n")
PY
}
reduce "$W/got.tsv" $LEGS
awk -F'\t' '{ n[$1 " " $2]++ } END { for (k in n) printf "  %s rows: %d\n", k, n[k] }' "$W/got.tsv" | sort
awk -F'\t' '$2=="W" && $4=="38" && ($1=="vsavj" || $1=="ours")' "$W/got.tsv" > "$W/w38.tsv"
if [ -s "$W/w38.tsv" ]; then bad "0x38 is written into a victim's +0x54:"; sed 's/^/        /' "$W/w38.tsv"
else ok "no write puts 0x38 into +0x54 on vsavj (the legacy corpus) or on ours (the naming parts)"; fi
case " $LEGS " in *" ours "*)
    awk -F'\t' '$1=="ours" && $2=="W" && $4=="06" && $3>="0186d0" && $3<="0186d5"' "$W/got.tsv" | grep -q . \
        && ok "positive control: ours shows vsavj's ground stager writing 6 (the tenants' remapped electric hits)" \
        || bad "ours never shows the ground stager's 6 — the tap or the corpus is blind to the electric path" ;; esac
case " $LEGS " in *" native "*)
    awk -F'\t' '$1=="native" && $2=="W" && $4=="52" && $3>="016fec" && $3<="016ff1"' "$W/got.tsv" | grep -q . \
        && ok "positive control: native shows vs2's ground stager writing 0x52 (its column and trap)" \
        || bad "native never shows vs2's 0x52 write — the tap or the corpus is blind to it" ;; esac
if [ -z "$CONTROL" ]; then
    reduce "$W/ctl.tsv" ctl
    if awk -F'\t' '$2=="W" && $4=="38"' "$W/ctl.tsv" | grep -q .; then echo "CONTROL FIRED: planted-38 — the poked run reports $(awk -F'\t' '$2=="W" && $4=="38" { print "pc " $3 " value 38 in " $5; exit }' "$W/ctl.tsv")"
    else echo "CONTROL DEAD: planted-38 — the poked run reports no 0x38 write"; fail=1; fi
fi

echo "== 4. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] && [ -z "$CONTROL" ] && [ "$LEGS" = "vsavj ours native" ] || { echo "FAIL: audit_reaction_class_live (not frozen: fix the red first, all three legs, no control)"; exit 1; }
    {
        echo "# tests/expected/reaction_class_live.tsv — every write and read of the victim's reaction class (+0x54, both fighter blocks)"
        echo "# over the corpus: vsavj = pristine vsavj, every tests/replays/*.rpl; ours = $(basename "$BUILD"), the 30 #136 naming parts; native = vsav2,"
        echo "# the same parts (tests/audit_reaction_class_live.sh; tests/lua/read_tap.lua). Evidence class: in-emulator. Frozen 14z-169"
        echo "# with FREEZE=1. Columns: <leg> W <pc> <+0x54 value> <blocks> <runs> | <leg> R <pc> <blocks> <runs> <values seen>."
        echo "# The ours rows follow the build: re-freeze at every freeze, reviewing the diff."
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
if [ "$LEGS" = "vsavj ours native" ]; then
    [ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
    grep -v '^#' "$EXPECT" > "$W/want.tsv"
    if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
    else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt" | head -40; fi
else
    echo "  (LEGS=\"$LEGS\": a partial run is not compared with the frozen rows)"
fi

if [ "$CONTROL" = planted-38 ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: planted-38 — every vsavj run reports the planted 0x38"; echo "FAIL: audit_reaction_class_live (control mode)"; exit 1
    else echo "CONTROL DEAD: planted-38 — the planted runs passed"; echo "FAIL: audit_reaction_class_live"; exit 1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_reaction_class_live"; else echo "FAIL: audit_reaction_class_live"; exit 1; fi
