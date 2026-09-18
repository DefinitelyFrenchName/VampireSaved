#!/bin/sh
# audit_guard_reentry.sh — THE BLOCK ANIMATION RE-ENTERS ON vsavj, NOT ON vs2, on legacy content (14z-168, GitHub #136): when a block's hit-freeze ends into the blockstun slide (seq 0 -> 2) with BACK still held, vsavj re-enters the block animation (the node counter reloaded, every frame back is held) where vsav2 keeps ticking — an ENGINE-GENERATION difference, measured on Demitri on both games, and the source of #136's seven Reflect Wall guard-cancel DIFF rows (Phobos's block animation is a multi-node loop, so on him the re-entry restarts the chain).
#
# MUST-FIRE: perturbed-copy: act-late — a copy of the act rows with ours' and vsavj's first possible attack moved 3 frames later (what a re-entry that delayed recovery would read) must FAIL both the same-frame check and the frozen compare, so "identical" is a measured frame, not an absence (in-gate: the moved copy must fail the check; mode: the rows are moved before the checks and the gate FAILs)
# MUST-FIRE: perturbed-copy: vs2-pattern — a copy of the vsavj rows carrying vsav2's counter values (what vsavj would read if it did NOT re-enter) must FAIL the frozen compare, so the frozen vsavj rows are the re-entry (in-gate: the perturbed copy must differ from the frozen rows; mode: the vsavj rows are replaced before the compare and the table FAILs)
#
# WHY. #136's huitzil_5 events 1-7 (Reflect Wall guard cancels at hit+6/+10/+14) read
# DIFF on Phobos's node at +16/+17: at the freeze end ours enters the block chain's
# first node where native continues its loop. A non-debug write tap showed ours writing
# the chain start with no counter tick (build/p136_14z168, 14z-168). The question — our
# port or the host engine? — is answered by the legacy control this gate freezes: the
# SAME rig with Demitri on P1 (the default cell, no cursor move) on pristine vsavj, on
# vsav2 and on our build. vsavj reloads the counter at +16 and keeps reloading while back
# is held (2 frames at hit+6, 6 at hit+10); vsav2 ticks; ours equals vsavj on EVERY
# sampled field of every frame. The host engine's behaviour governs —
# the maintainer, 2026-09-02, #114: "we must respect the fact that we are porting the
# character to a different engine and the engine, being vanilla vsav, takes precedence."
# (DECISIONS_HISTORY.md, the #114 lines); vanilla wins ties, [VSP-21].
#
# THE RIG: tools/name_moves.py's huitzil part 5 generated with the first event at 2800
# (its first X pin then lands after the round starts — the 14z-167 entrance artifact,
# tests/audit_rig_opening.sh), P1's cursor lines removed so P1 confirms Demitri on the
# default cell on every wheel; P2 Demitri by `R`; the part's pokes plus the parity gate's
# level (6, from 2000) and RNG (from 2363) pins. Events: 2800 (gc at hit+2, back released
# during the freeze — no re-entry on either game), 3220 (hit+6), 3640 (hit+10).
#
# WHAT IT FREEZES (tests/expected/guard_reentry.tsv): `win <leg> <event frame> <offset>
# seq=<P1 seq> cnt=<P1 node counter> frz=<P1 +0x5C>` for offsets +8..+25 of each event,
# on vsav2 and vsavj (node ADDRESSES differ between the games and are not frozen), and
# one `superset` row: the frames where vsavj and ours differ on any sampled field (0);
# two `pixels` rows (added 14z-168); and `act <leg> hold=+N first_attack=+N`
# rows (the maintainer's first-possible-frame test, section 2b, added 14z-168): snapshots at hit+14..+26 of the 3640 event,
# vsavj vs ours identical on every frame, vsav2 vs vsavj differing (the comparison's
# liveness — the games' stage palettes differ). The capture built from them was put
# before the maintainer (build/p136_14z168/cap_guard/DELIVERED.txt); no fighter
# difference between vsav2 and vsavj was visible there. The maintainer then proposed the
# first-possible-frame test (section 2b) and, on its result, ruled: "agreed, all the tests
# converge : it's identical" (2026-09-18, DECISIONS_HISTORY.md, the 14z-168 captures entry).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged26] [FREEZE=1] tests/audit_guard_reentry.sh
#   emulator tier, MAME; three field_trace and three snapshot legs, then 12 act legs — measured 14z-168 on this MacBook, solo: ~20 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/guard_reentry.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|vs2-pattern|act-late) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FR=3700; EVENTS="2800 3220 3640"; SNAPS="3654,3655,3656,3657,3658,3659,3660,3661,3662,3663,3664,3665,3666"

echo "== 1. the rig"
( cd "$REPO" && python3 - "$W" <<'PY'
import sys, json
sys.path.insert(0, "tools"); import name_moves as nm
W = sys.argv[1]
nm.FIRST_EVENT = 2800
nm.gen("huitzil", "5", f"{W}/rig.rpl", f"{W}/rig.json")
PY
) > "$W/gen.log" 2>&1 || { bad "rig generation: $(tail -1 "$W/gen.log")"; }
[ "$fail" = 0 ] || { echo "FAIL: audit_guard_reentry"; exit 1; }
grep -v -E '^(1100|1160|1220|1280)-[0-9]+ p1=' "$W/rig.rpl" > "$W/demitri.rpl"
PK="$(python3 -c "import json;print(';'.join(json.load(open('$W/rig.json'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$FR)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$FR)))")"
python3 -c "import json;print(' '.join(str(e['frame']) for e in json.load(open('$W/rig.json'))['events'][:3]))" > "$W/ev.txt"
[ "$(cat "$W/ev.txt")" = "$EVENTS" ] || bad "the generated events start at $(cat "$W/ev.txt"), not $EVENTS — the schedule moved"
[ "$fail" = 0 ] || { echo "FAIL: audit_guard_reentry"; exit 1; }
ok "huitzil part 5 at FIRST_EVENT 2800, P1's cursor lines removed"

echo "== 2. the legs"
FIELDS="ff841c:l:node,ff8420:b:cnt,ff8406:b:seq,ff8407:b:sub,ff8410:w:x,ff845c:b:frz,ff8450:w:p1hp,ff8782:b:id,ff8b82:b:p2id,ff8081:b:pc,ff881c:l:p2node,ff8806:b:p2seq"
for s in vsav2:vsav2:"$ROMDIR" vsavj:vsavj:"$ROMDIR" ours:vsavjw:"$BUILD/rompath;$ROMDIR"; do
    leg="${s%%:*}"; rest="${s#*:}"; set_="${rest%%:*}"; rp="${rest#*:}"
    mkdir -p "$W/$leg"
    # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log (docs/platform/gotchas.md):
    # `set +e` keeps the status write alive, and a run whose instrument wrote its summary line counts as
    # completed (docs/project/gotchas.md, the set -e capture entry)
    ( set +e; cd "$W/$leg" && MAME_SANDBOX="$W/$leg/sb" MAME_ROMPATH="$rp" REPLAY="$W/demitri.rpl" POKES="$PK" FIELDS="$FIELDS" \
        FIELD_OUT="$W/$leg.ft" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
        "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$leg/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$W/$leg.ft" 2>/dev/null && _st=0; echo $_st > "$W/$leg/rc"; rm -rf "$W/$leg/sb" ) </dev/null &
    # the render layer (14z-168, rule-checker run 2026-09-18-46 Q2): the same inputs snapshotted at
    # hit+14..+26 of the 3640 event; the sheet built from these was put before the maintainer
    # (build/p136_14z168/cap_guard/DELIVERED.txt). The verdict rests on the PNGs, not the exit code.
    mkdir -p "$W/$leg.s"
    ( set +e; cd "$W/$leg.s" && MAME_SANDBOX="$W/$leg.s/sb" MAME_ROMPATH="$rp" REPLAY="$W/demitri.rpl" POKES="$PK" SNAP_FRAMES="$SNAPS" \
        TRACE_OUT="$W/$leg.s/index.txt" FRAMES="$FR" \
        "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/snapshot_frames.lua" > "$W/$leg.s/mame.log" 2>&1 ) </dev/null &
done
wait
for leg in vsav2 vsavj ours; do _rc="$(cat "$W/$leg/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$leg exited $_rc (an emulator that crashed is not evidence)"; done
[ "$fail" = 0 ] || { echo "FAIL: audit_guard_reentry"; exit 1; }
reduce() {  # reduce <W> <events>: the frozen rows (+ the superset row)
    python3 - "$1" "$2" <<'PY'
import sys
W, evs = sys.argv[1], [int(x) for x in sys.argv[2].split()]
def load(p):
    d = {}
    for l in open(p):
        t = l.split()
        if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
    return d
L = {g: load(f"{W}/{g}.ft") for g in ("vsav2", "vsavj", "ours")}
for g, d in L.items():
    if 2300 not in d or max(d) < 3699: sys.exit(f"VOID: {g} trace incomplete")
    if (d[2300]["id"], d[2300]["p2id"]) != (1, 1): sys.exit(f"VOID: {g} is not a Demitri mirror (ids {d[2300]['id']:#x}/{d[2300]['p2id']:#x})")
for g in ("vsav2", "vsavj"):
    for e in evs:
        for o in range(8, 26):
            r = L[g][e + o]
            print(f"win\t{g}\t{e}\t+{o}\tseq={r['seq']}\tcnt={r['cnt']}\tfrz={r['frz']}")
a, b = L["vsavj"], L["ours"]
diff = [f for f in sorted(set(a) & set(b)) if a[f] != b[f]]
print(f"superset\tvsavj-vs-ours\tframes-differing={len(diff)}" + (f"\tfirst={diff[0]}" if diff else ""))
PY
}
reduce "$W" "$EVENTS" > "$W/got.tsv" 2> "$W/red.err" || bad "$(cat "$W/red.err")"
# the pixel rows: vsavj vs ours must be identical frame for frame; vsav2 vs vsavj must DIFFER (the
# stage palettes differ between the games) — the comparison's own liveness, so an all-identical
# result cannot come from comparing a file with itself or two blank frames
python3 - "$W" "$SNAPS" >> "$W/got.tsv" 2>> "$W/red.err" <<'PY' || bad "$(cat "$W/red.err")"
import sys, glob
from PIL import Image
W, snaps = sys.argv[1], sys.argv[2].split(",")
def frames(leg):
    fs = sorted(glob.glob(f"{W}/{leg}.s/sb/snap/*/*.png"))
    if len(fs) != len(snaps): sys.exit(f"VOID: {leg} delivered {len(fs)} snapshots, not {len(snaps)}")
    return [Image.open(f).convert("RGB").tobytes() for f in fs]
F = {g: frames(g) for g in ("vsav2", "vsavj", "ours")}
for a, b in (("vsavj", "ours"), ("vsav2", "vsavj")):
    d = sum(1 for x, y in zip(F[a], F[b]) if x != y)
    print(f"pixels\t{a}-vs-{b}\tframes={len(snaps)}\tdiffering={d}")
PY
[ "$fail" = 0 ] || { echo "FAIL: audit_guard_reentry"; exit 1; }
vs2_rows() {  # vs2_rows <rows in> <rows out>: the vsavj rows given vsav2's counter at the same (event, offset)
    python3 - "$1" "$2" <<'PY'
import sys
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1])]
v2 = {(r[2], r[3]): r[5] for r in rows if r[0] == "win" and r[1] == "vsav2"}
with open(sys.argv[2], "w") as o:
    for r in rows:
        if r[0] == "win" and r[1] == "vsavj" and (r[2], r[3]) in v2: r[5] = v2[(r[2], r[3])]
        o.write("\t".join(r) + "\n")
PY
}
if [ "$CONTROL" = vs2-pattern ]; then vs2_rows "$W/got.tsv" "$W/got.v2" && mv "$W/got.v2" "$W/got.tsv"; fi
for e in $EVENTS; do
    printf '  %s  vsav2 cnt: %s\n        vsavj cnt: %s\n' "$e" \
        "$(awk -F'\t' -v e="$e" '$1=="win" && $2=="vsav2" && $3==e {sub("cnt=","",$6); printf "%s ", $6}' "$W/got.tsv")" \
        "$(awk -F'\t' -v e="$e" '$1=="win" && $2=="vsavj" && $3==e {sub("cnt=","",$6); printf "%s ", $6}' "$W/got.tsv")"
done
grep '^superset' "$W/got.tsv" | sed 's/^/  /'
awk -F'\t' '$1=="superset" && $3!="frames-differing=0"{exit 1}' "$W/got.tsv" || bad "vsavj and ours differ on legacy content (the superset invariant) — $(grep '^superset' "$W/got.tsv")"
grep '^pixels' "$W/got.tsv" | sed 's/^/  /'
awk -F'\t' '$1=="pixels" && $2=="vsavj-vs-ours" && $4!="differing=0"{exit 1}' "$W/got.tsv" || bad "vsavj and ours render differently on legacy content"
awk -F'\t' '$1=="pixels" && $2=="vsav2-vs-vsavj" && $4=="differing=0"{exit 1}' "$W/got.tsv" || bad "the pixel comparison sees no difference even between vsav2 and vsavj — it is blind"

echo "== 2b. the victim acts at its first possible frame (the maintainer's test, 14z-168)"
# The maintainer, 2026-09-18: "have the victim try to act on the first possible frame post
# blockstun. if the frames align then it's truly identical mechanically". The hit+10 event (3640):
# P1 holds back to +21 (the rig's own hold) or to +50, the guard-cancel motion removed, and LP is
# pressed every other frame from +22 on — AFTER the advancing guard's 14-tick window, because a
# light press inside that window feeds vsavj's advancing guard (vs2 needs weighted presses;
# docs/game/engine_internals.md, the ADVANCING GUARD paragraph), which would measure that mechanic
# instead. Two phases (even / odd frames) give one-frame resolution. Measured 14z-168: the first
# attack state (seq 0x0A) at +35 on vsav2, vsavj and ours, both holds. Ruled: "agreed, all the tests
# converge : it's identical" (DECISIONS_HISTORY.md, the 14z-168 captures entry).
AFR=3760
APK="$(python3 -c "import json;print(';'.join(json.load(open('$W/rig.json'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$AFR)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$AFR)))")"
for hold in 3661 3690; do for ph in 0 1; do
    { grep -v -E '^(3660-3661|3662-3663|3664-3667|3636-3661) p1=' "$W/demitri.rpl" | grep -v -E '^[0-9]+ wait$'
      echo "3636-$hold p1=L"; f=$((3662 + ph)); while [ $f -lt 3740 ]; do echo "$f-$f p1=1"; f=$((f + 2)); done
      echo "$AFR wait"; } > "$W/act_${hold}_$ph.rpl"
done; done
for s in vsav2:vsav2:"$ROMDIR" vsavj:vsavj:"$ROMDIR" ours:vsavjw:"$BUILD/rompath;$ROMDIR"; do
    leg="${s%%:*}"; rest="${s#*:}"; set_="${rest%%:*}"; rp="${rest#*:}"
    for hold in 3661 3690; do for ph in 0 1; do
        d="$W/act_${leg}_${hold}_$ph"; mkdir -p "$d"
        ( set +e; cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$rp" REPLAY="$W/act_${hold}_$ph.rpl" POKES="$APK" \
            FIELDS="ff8406:b:seq,ff8407:b:sub,ff845c:b:frz,ff8782:b:id,ff8b82:b:p2id" FIELD_OUT="$d.ft" FIELD_FROM=3600 FIELD_TO="$AFR" FRAMES="$AFR" \
            "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
          _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$d.ft" 2>/dev/null && _st=0; echo $_st > "$d/rc"; rm -rf "$d/sb" ) </dev/null &
    done; done
done
wait
python3 - "$W" >> "$W/got.tsv" 2> "$W/act.err" <<'PY' || bad "act: $(cat "$W/act.err")"
import sys
W = sys.argv[1]
def load(p):
    d = {}
    for l in open(p):
        t = l.split()
        if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
    return d
for hold in (3661, 3690):
    for leg in ("vsav2", "vsavj", "ours"):
        acts, ends = [], []
        for ph in (0, 1):
            d = load(f"{W}/act_{leg}_{hold}_{ph}.ft")
            if 3600 not in d or max(d) < 3759: sys.exit(f"VOID: act {leg} {hold} {ph} trace incomplete")
            if (d[3600]["id"], d[3600]["p2id"]) != (1, 1): sys.exit(f"VOID: act {leg} not a Demitri mirror")
            if not any(d[f]["seq"] == 0 and d[f]["frz"] for f in range(3640, 3660)): sys.exit(f"VOID: act {leg} {hold} {ph} — the block never happened")
            act = next((f for f in range(3660, 3740) if d[f]["seq"] == 0x0A), None)
            if act is None: sys.exit(f"VOID: act {leg} {hold} {ph} — no attack state by +100")
            acts.append(act - 3640)
        print(f"act\t{leg}\thold=+{hold - 3640}\tfirst_attack=+{min(acts)}")
PY
[ "$fail" = 0 ] || { echo "FAIL: audit_guard_reentry (the act runs were VOID)"; exit 1; }
grep '^act' "$W/got.tsv" | sed 's/^/  /'
# ONE perturbation for the act-late control, shared by the in-gate check and the mode
act_late() {  # act_late <rows in> <rows out>: ours' and vsavj's first possible attack 3 frames later
    awk -F'\t' 'BEGIN{OFS="\t"} $1=="act" && ($2=="ours" || $2=="vsavj") {split($4, a, "+"); $4 = "first_attack=+" (a[2] + 3)} {print}' "$1" > "$2"
}
act_same() {  # act_same <rows>: exits 1 unless every hold's first attack is one frame across the legs
    for _h in 21 50; do [ "$(awk -F'\t' -v h="hold=+$_h" '$1=="act" && $3==h {print $4}' "$1" | sort -u | wc -l | tr -d ' ')" = 1 ] || return 1; done
}
if [ "$CONTROL" = act-late ]; then act_late "$W/got.tsv" "$W/got.al" && mv "$W/got.al" "$W/got.tsv"; fi
for hold in 21 50; do
    [ "$(awk -F'\t' -v h="hold=+$hold" '$1=="act" && $3==h {print $4}' "$W/got.tsv" | sort -u | wc -l | tr -d ' ')" = 1 ] \
        && ok "back held to +$hold: the first possible attack is the same frame on all three games" \
        || bad "back held to +$hold: the legs' first possible attack differs"
done

echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/guard_reentry.tsv — the block animation across the freeze end, a Demitri mirror on the #136 guard-cancel rig"
        echo "# (huitzil part 5 at FIRST_EVENT 2800), vsav2 vs pristine vsavj, and vsavj vs our build (tests/audit_guard_reentry.sh;"
        echo "# tests/lua/field_trace.lua). Evidence class: in-emulator. Frozen 14z-168 with FREEZE=1 (GitHub #136). The ENGINE"
        echo "# DIFFERENCE IS FROZEN AS MEASURED: vsavj reloads the counter while back is held after the freeze; vsav2 ticks."
        echo "# Columns: win <leg> <event frame> <offset> seq= cnt= frz= | superset vsavj-vs-ours frames-differing= |"
        echo "# pixels <pair> frames= differing= (snapshots at hit+14..+26 of the 3640 event)"
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt" | head -20; fi

echo "== 4. must-fire control"
if [ "$CONTROL" = act-late ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: act-late — a later first attack on vsavj and ours is caught"; echo "FAIL: audit_guard_reentry (control mode)"; exit 1
    else echo "CONTROL DEAD: act-late — the moved rows passed"; echo "FAIL: audit_guard_reentry"; exit 1; fi
fi
act_late "$W/got.tsv" "$W/ctl_act.tsv"
if act_same "$W/ctl_act.tsv"; then echo "CONTROL DEAD: act-late — the same-frame check passed the moved rows"; fail=1
else echo "CONTROL FIRED: act-late — the same-frame check refuses ours and vsavj 3 frames late"; fi
if [ "$CONTROL" = vs2-pattern ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: vs2-pattern — vsavj given vsav2's counters loses the frozen rows"; echo "FAIL: audit_guard_reentry (control mode)"; exit 1
    else echo "CONTROL DEAD: vs2-pattern — the swap changed nothing"; echo "FAIL: audit_guard_reentry"; exit 1; fi
fi
vs2_rows "$W/got.tsv" "$W/ctl.tsv"
if diff -q "$W/got.tsv" "$W/ctl.tsv" > /dev/null; then echo "CONTROL DEAD: vs2-pattern — vsavj's counters already equal vsav2's"; fail=1
else echo "CONTROL FIRED: vs2-pattern — vsav2's counters change $(diff "$W/got.tsv" "$W/ctl.tsv" | grep -c '^<' | tr -d ' ') vsavj rows"; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_guard_reentry"; else echo "FAIL: audit_guard_reentry"; exit 1; fi
