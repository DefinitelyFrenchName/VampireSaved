#!/bin/sh
# audit_defense_row_reads.sh — WHICH ROW EVERY HIT'S DEFENSE READS INDEX, by the victim's identity, over the corpus on our merged build and on pristine vsavj, frozen (14z-169, the analysis before the ruled fix "the tenants' defense rows become vs2's", #136).
#
# MUST-FIRE: perturbed-copy: planted-flavor — donovan_victim_1 on our build with a Lua poke of 0x01 into P2's +0x382 at frame 2680 (inside the match, before the first hit) must be reported as a tenant hit reading a row that is NOT its own and FAIL the own-row check, so the check reads the index the engine read (in-gate: that one run must report a mismatch; mode: every victim part carries the poke and the gate FAILs)
# MUST-FIRE: perturbed-copy: range-silent — a copy of a tap log with every access to P2's +0x382 window deleted must be reported as a DEAD window, so each run's windows are each proven live to the end (in-gate: the first run's copy must read P2 dead; mode: every run's log is perturbed before the liveness check and the gate FAILs)
#
# WHY. The maintainer ruled (2026-09-18, 14z-168: "given the measurements we should take
# the vs2 rows") that Phobos and Donovan take their vs2 defense rows and rally thresholds.
# Both reads index by the VICTIM's +0x382 (docs/game/engine_internals.md, the defense port
# note): the curve at PRG:0x018C10 masks it to 5 bits (row = id*0x20 + +0x3B3, table
# 0x0B8940) and the rally threshold at 0x018C78 reads it unmasked (table 0x0BCC80). So a
# data-only edit of rows 0x10/0x13 is the fix IF every hit on a tenant victim reads the
# tenant's own id there — but in a match +0x382 is the voice-flavor class, which the
# engine can reassign ([VSE-62]). This gate measures the index each read actually took.
# THE TWO HALVES (rule-checker run 2026-09-18-51 Q4: this gate logs reads only at the listed
# pcs, so a reader elsewhere is invisible to it): which instructions name either table is the
# STATIC half, frozen by tests/test_defense_rows_census.sh's reader rows — every absolute long
# and every pc-relative lea/pea landing in a table, over vsavj, vs2 and our whole image:
# exactly the two host reads (0x018C20, 0x018C7C) on vsavj and ours, no placed tenant code.
# This gate is the LIVE half: which index those two reads take. NOT COVERED by either: a table
# base computed at run time, a `(d8,pc,Xn)` form, a `(d16,pc)` operand other than lea/pea, or a
# table reached through a pointer in data.
#
# THE SAMPLE (our build unless named):
#   victim   — the 12 naming victim parts (tests/replays/naming/<tenant>_victim_<n>, Victor
#              P1 attacking the tenant poked as P2, as committed);
#   attacker — the 30 naming parts (the tenant P1, real picks, tests/audit_move_parity.sh's
#              inputs and pins; the tenant is a victim only when Demitri lands a hit);
#   suite    — every tests/replays/*.rpl, unpoked (tenant picks on the merged wheel, 1P CPU
#              matches where the voice-class borrow runs, legacy matches);
#   vsavj    — every tests/replays/*.rpl on pristine vsavj: the LEGACY CONTROL — which row a
#              legacy victim's hit reads in vanilla, which the fix must not change.
# IDENTITY is each block's hitbox base +0x60 (written at load, tapped; [VSP-163]), named by
# tests/expected/roster_pairings/bases.tsv — never +0x382 itself, which is the question.
# A read whose block has no base yet, or a base the table does not name, is `unknown`.
# NOT SAMPLED: every path the corpus does not run; the attacker-side read of +0x382 at
# 0x018C40 (the combo-scaling row, through the hit-registration pair — #157's family) is
# logged and frozen but not judged here.
#
# LIVENESS: every run needs its END line and the END PROBE (a Lua poke of +0x383 on each
# block on its last frame, outside the measured byte) logged in both +0x382 windows.
#
# FROZEN: tests/expected/defense_row_reads.tsv — `<leg> <pc> <victim identity> <value read>
# <reads> <runs>`. The ours rows follow the build (a freeze can move a tenant's base):
# re-freeze at every freeze (FREEZE=1), reviewing the diff.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged26] [JOBS=6] [LEGS="victim attacker suite vsavj"] [FREEZE=1] tests/audit_defense_row_reads.sh
#   emulator tier, MAME; 218 tap runs — measured 14z-169 on this MacBook, solo, JOBS=6: see PROVENANCE
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/defense_row_reads.tsv"
BASES="$REPO/tests/expected/roster_pairings/bases.tsv"
JOBS="${JOBS:-6}"
LEGS="${LEGS:-victim attacker suite vsavj}"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|planted-flavor|range-silent) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
RTAP="ff8782,2;ff8b82,2;ff8460,4;ff8860,4"
RPCS="018c10,018c78,018c40"
PLANT_POKE="2680:ff8b82:01"

# ONE runner: the tap, the END PROBE on the last frame, the planted poke when asked ([VSP-181])
tap_run() {  # tap_run <leg> <name> <set> <rompath> <rpl> <pokes> <frames>
    _d="$W/$1/$2"; mkdir -p "$_d"
    _pk="$6${6:+;}$(($7 - 1)):ff8783:00;$(($7 - 1)):ff8b83:00"
    # set +e: MAME can segfault at TEARDOWN after the log is closed (docs/platform/gotchas.md) —
    # the verdict rests on the END line and the END probe, never the exit code
    ( set +e; cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$4" REPLAY="$5" POKES="$_pk" RTAP="$RTAP" RPCS="$RPCS" \
        TRACE_OUT="$_d/t.tap" FRAMES="$7" "$REPO/tools/run_mame.sh" "$3" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$_d/mame.log" 2>&1
      echo $? > "$_d/rc"; rm -rf "$_d/sb" ) </dev/null &
    _n=$((_n + 1)); [ $((_n % JOBS)) -eq 0 ] && wait
    return 0
}
rpl_frames() { awk '!/^#/ && NF { split($1, a, "-"); v = a[length(a)] + 0; if (v > m) m = v } END { print m + 120 }' "$1"; }
json_frames() { python3 -c "import json;print(json.load(open('$1'))['frames'])"; }
json_pokes() { python3 -c "import json;print(';'.join(json.load(open('$1'))['pokes']))"; }
OURS_PATH_donovan="D D DR DR"; OURS_PATH_huitzil="D D D"; OURS_PATH_pyron="D D D D"
OURS_RP="$BUILD/rompath;$ROMDIR"
_n=0

echo "== 1. the tap runs ($LEGS)"
T0="$(date +%s)"
for leg in $LEGS; do
    case "$leg" in
    victim)
        for j in "$REPO"/tests/replays/naming/*_victim_[0-9]*.json; do
            _pk="$(json_pokes "$j")"; [ "$CONTROL" = planted-flavor ] && _pk="$_pk;$PLANT_POKE"
            tap_run victim "$(basename "$j" .json)" vsavjw "$OURS_RP" "${j%.json}.rpl" "$_pk" "$(json_frames "$j")"
        done ;;
    attacker)
        mkdir -p "$W/rpl"
        for j in "$REPO"/tests/replays/naming/donovan_[0-9]*.json "$REPO"/tests/replays/naming/huitzil_[0-9]*.json "$REPO"/tests/replays/naming/pyron_[0-9]*.json; do
            name="$(basename "$j" .json)"; t="${name%_*}"; fr="$(json_frames "$j")"
            pk="$(json_pokes "$j");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$fr)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$fr)))")"
            eval "_path=\$OURS_PATH_$t"
            awk -v path="$_path" '
                /^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
                    for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
                /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
                { print }' "${j%.json}.rpl" > "$W/rpl/$name.rpl"
            tap_run attacker "$name" vsavjw "$OURS_RP" "$W/rpl/$name.rpl" "$pk" "$fr"
        done ;;
    suite)
        for r in "$REPO"/tests/replays/*.rpl; do tap_run suite "$(basename "$r" .rpl)" vsavjw "$OURS_RP" "$r" "" "$(rpl_frames "$r")"; done ;;
    vsavj)
        for r in "$REPO"/tests/replays/*.rpl; do tap_run vsavj "$(basename "$r" .rpl)" vsavj "$ROMDIR" "$r" "" "$(rpl_frames "$r")"; done ;;
    *) echo "FAIL: unknown leg '$leg'"; exit 1 ;;
    esac
done
if [ -z "$CONTROL" ]; then
    _j="$REPO/tests/replays/naming/donovan_victim_1.json"
    tap_run ctl planted "vsavjw" "$OURS_RP" "${_j%.json}.rpl" "$(json_pokes "$_j");$PLANT_POKE" "$(json_frames "$_j")"
fi
wait
ok "$(ls -d "$W"/*/*/ 2>/dev/null | wc -l | tr -d ' ') runs in $(( $(date +%s) - T0 )) s"

# ONE liveness reader and ONE perturbation, shared by the gate, the in-gate control and the mode
dead_windows() {  # dead_windows <tap> <end frame>: a +0x382 window lacking its END probe write
    awk -v last="$(($2 - 1))" '
        $1=="W" && $2==last && $10=="000000ff" { if ($6=="ff8782") p[1] = 1; if ($6=="ff8b82") p[2] = 1 }
        END { for (r = 1; r <= 2; r++) if (!p[r]) printf "P%d(end-probe) ", r }' "$1"
}
silence_p2() { awk '!(($1 == "W" || $1 == "R") && $6 == "ff8b82")' "$1" > "$2"; }

echo "== 2. liveness"
for d in "$W"/*/*/; do
    [ -f "$d/rc" ] || continue
    run="$(basename "$(dirname "$d")")/$(basename "$d")"; tap="$d/t.tap"
    fr="$(awk '$1=="END" { print $2 }' "$tap" 2>/dev/null)"
    [ -n "$fr" ] || { bad "$run: no END line (exit $(cat "$d/rc")) — a dead tap is not evidence"; continue; }
    if [ "$CONTROL" = range-silent ]; then silence_p2 "$tap" "$tap.sil" && mv "$tap.sil" "$tap"; fi
    _dw="$(dead_windows "$tap" "$fr")"
    [ -z "$_dw" ] || bad "$run: ${_dw}— that window is dead"
done
if [ "$CONTROL" = range-silent ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: range-silent — every run reads P2's window dead"; echo "FAIL: audit_defense_row_reads (control mode)"; exit 1
    else echo "CONTROL DEAD: range-silent — the silenced window still read live"; echo "FAIL: audit_defense_row_reads"; exit 1; fi
fi
[ "$fail" = 0 ] || { echo "FAIL: audit_defense_row_reads"; exit 1; }
ok "every run ends with both END-probe writes logged"
_first="$(ls -d "$W"/victim/*/ "$W"/suite/*/ 2>/dev/null | head -1)"
if [ -n "$_first" ]; then
    silence_p2 "$_first/t.tap" "$W/ctl_range.tap"
    _dr="$(dead_windows "$W/ctl_range.tap" "$(awk '$1=="END" { print $2 }' "$_first/t.tap")")"
    if [ "$_dr" = "P2(end-probe) " ]; then echo "CONTROL FIRED: range-silent — $(basename "$_first") without P2's accesses reads ${_dr}dead"
    else echo "CONTROL DEAD: range-silent — $(basename "$_first") without P2's accesses reads '$_dr'"; fail=1; fi
fi

echo "== 3. the reduction"
reduce() {  # reduce <out.tsv> <leg...> — ONE reducer for the gate and the controls
    _o="$1"; shift
    python3 - "$W" "$_o" "$BASES" "$@" <<'PY'
import sys, os, collections
W, out, bases_p, legs = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
names = {}
for l in open(bases_p):
    if l.startswith("#") or not l.strip():
        continue
    c = l.split()
    names[int(c[2], 16)] = f"{c[1]}:{int(c[0], 16):02x}"
PCS = {"018c10": "defense", "018c78": "threshold", "018c40": "attacker-combo"}
rows = collections.defaultdict(lambda: [0, set()])
for leg in legs:
    d = os.path.join(W, leg)
    if not os.path.isdir(d):
        continue
    for run in sorted(os.listdir(d)):
        tap = os.path.join(d, run, "t.tap")
        if not os.path.exists(tap):
            continue
        base = {"ff8460": [0, 0], "ff8860": [0, 0]}   # per block: (hi word, lo word) as last written
        for l in open(tap):
            x = l.split()
            if not x or x[0] not in ("R", "W"):
                continue
            off, data, mask = x[5], int(x[7], 16) & 0xFFFF, int(x[9], 16)
            if x[0] == "W" and off in ("ff8460", "ff8462", "ff8860", "ff8862"):
                blk = off[:4] + "60"; i = 0 if off.endswith("60") else 1
                old = base[blk][i]
                base[blk][i] = (old & ~mask & 0xFFFF) | (data & mask)
                continue
            if x[0] != "R" or x[3] not in PCS or not mask & 0xFF00:
                continue
            blk = "ff8460" if off == "ff8782" else "ff8860"
            b = (base[blk][0] << 16) | base[blk][1]
            who = names.get(b, "unknown" if b == 0 else f"base{b:#x}")
            val = (data >> 8) & 0xFF
            e = rows[(leg, x[3], PCS[x[3]], who, f"{val:02x}")]; e[0] += 1; e[1].add(run)
with open(out, "w") as o:
    for (leg, pc, kind, who, val), (n, rs) in sorted(rows.items()):
        o.write(f"{leg}\t{pc}\t{kind}\t{who}\t{val}\t{n}\t{len(rs)}\n")
PY
}
_legs=""; for l in $LEGS; do _legs="$_legs $l"; done
reduce "$W/got.tsv" $_legs
sed 's/^/  /' "$W/got.tsv"
# the own-row check, on the two defense reads, for every victim the table names: the read index
# is the victim's own id (the 5-bit fold applies to the curve only, and a tenant id is < 0x20)
own() {  # own <tsv> -> the rows whose read index is not the victim's own id
    awk -F'\t' '($3=="defense" || $3=="threshold") && $4 ~ /:/ { split($4, a, ":"); if (a[2] != $5) print }' "$1"
}
own "$W/got.tsv" > "$W/notown.tsv"
if [ -s "$W/notown.tsv" ]; then bad "a hit read a defense row that is not the victim's own:"; sed 's/^/        /' "$W/notown.tsv"
else ok "every defense and threshold read indexed the victim's own id (every victim the base table names)"; fi
awk -F'\t' '($3=="defense" || $3=="threshold") && $4 !~ /:/' "$W/got.tsv" > "$W/unknown.tsv"
[ ! -s "$W/unknown.tsv" ] || { bad "a defense read on a block whose base the table does not name:"; sed 's/^/        /' "$W/unknown.tsv"; }
for t in donovan:13 phobos:10 pyron:11; do
    case " $LEGS " in *" victim "*)
        awk -F'\t' -v t="$t" '$1=="victim" && $3=="defense" && $4==t' "$W/got.tsv" | grep -q . \
            && ok "positive control: the victim parts land hits on $t" || bad "the victim parts land no hit on $t — the corpus or the tap is blind" ;; esac
done
if [ -z "$CONTROL" ]; then
    reduce "$W/ctl.tsv" ctl
    if own "$W/ctl.tsv" | grep -q .; then echo "CONTROL FIRED: planted-flavor — the poked run reports $(own "$W/ctl.tsv" | head -1 | tr '\t' ' ')"
    else echo "CONTROL DEAD: planted-flavor — the poked run reports every read as the victim's own"; fail=1; fi
fi

echo "== 4. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] && [ -z "$CONTROL" ] && [ "$LEGS" = "victim attacker suite vsavj" ] || { echo "FAIL: audit_defense_row_reads (not frozen: fix the red first, all four legs, no control)"; exit 1; }
    {
        echo "# tests/expected/defense_row_reads.tsv — every read of a fighter's +0x382 by the two defense reads (PRG:0x018C10 the curve,"
        echo "# 0x018C78 the rally threshold) and the attacker-side combo read (0x018C40), by the victim's identity (its hitbox base +0x60"
        echo "# named by roster_pairings/bases.tsv) and the index value read; legs victim / attacker / suite on $(basename "$BUILD"), vsavj on"
        echo "# pristine vsavj (tests/audit_defense_row_reads.sh; tests/lua/read_tap.lua with RPCS). Evidence class: in-emulator."
        echo "# Frozen 14z-169 with FREEZE=1. Columns: <leg> <pc> <read> <identity> <value read> <reads> <runs>."
        echo "# The ours rows follow the build: re-freeze at every freeze, reviewing the diff."
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
if [ "$LEGS" = "victim attacker suite vsavj" ]; then
    [ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
    grep -v '^#' "$EXPECT" > "$W/want.tsv"
    if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
    else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt" | head -40; fi
else
    echo "  (LEGS=\"$LEGS\": a partial run is not compared with the frozen rows)"
fi

if [ "$CONTROL" = planted-flavor ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: planted-flavor — every victim part reports the planted index"; echo "FAIL: audit_defense_row_reads (control mode)"; exit 1
    else echo "CONTROL DEAD: planted-flavor — the planted runs passed"; echo "FAIL: audit_defense_row_reads"; exit 1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_defense_row_reads"; else echo "FAIL: audit_defense_row_reads"; exit 1; fi
