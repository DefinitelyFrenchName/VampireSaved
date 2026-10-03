#!/bin/sh
# audit_mizuumi_struct.sh — THE MIZUUMI PLAYER-STRUCT CANDIDATES, MEASURED: the offsets adopted into atlas/ram.md from
# the community's Reverse Engineering page, each held by a check whose CONTROL would disagree (14z-189, GitHub #118)
#
# WHAT: on pristine vsavj, the community names below are CONSISTENT with the measured behaviour — and only that behaviour
#   is claimed (whether +0x11D gates throws, or +0x39F counts consecutive wins, is not measured): +0x11D reads 1 only at close range, +0x1B6 counts the hits it LANDS, +0x380 is 2 on a human-controlled side, 0 on
#   the CPU's, and cleared on a 2P loser after its death, +0x39F/+0x3F0 are set on the WINNER of a 2P replay's first decisive outcome only, and +0x05
#   reads 0x08 on the winner at both a time-over and a KO (the loser 0x0A / 0x0C); +0x130 tracks the X distance |x1-x2|
#   LESS A PER-FIGHTER OFFSET (recorded, the offset unexplained, so the name is not adopted as exact); one name does NOT
#   hold — +0x15A is never set, even at a measured time-over; +0x18D is RECORDED, its name not adopted (the time-over
#   winner 0x0C, the KO winner 0). Every writer PC of these fields in two replays is frozen too, so the rows that name a
#   writer are held. +0x6D is a CROSS-CHECK of ram.md's known recent-hit slots (+0x6C..+0x6F), not an adoption: the slot
#   for hits from P2, so P1's rises when P1 is hit and P2's never rises.
# HOW: on MAME, three FIELD legs under tests/lua/field_trace.lua (per frame, addresses computed from the block bases) —
#   02_demitri_vs_cpu (1P: a CPU side that fights), 03_two_player_vs (2P to a time-over), 37_victor_ko_vsavj (2P to a
#   KO) — and two WRITE-TAP legs under tests/lua/read_tap.lua (03 and 37, every write to the fields above, PC
#   attributed). The checks compare each candidate with an INDEPENDENT quantity — both HP words, both X positions, the
#   round timer $FF8109 — and every count, value set and writer set is frozen in tests/expected/mizuumi_struct.tsv.
#   A sixth leg replays 03 with +0x130 POKED to |x1-x2| on 3000 in-match frames and +0x15A poked to 1 on 300: the
#   positive control that the trace reads those two addresses (a misread address reads 0 and refutes anything) —
#   every poked +0x130 value must read back, +0x15A must read back the poked 1 on every frame of its poked range, and the
#   +0x15A refutation must fail on that leg. +0x130's own check
#   carries a control in the check: the same statistic against |x1-x2| 120 frames earlier must collapse; +0x11D's
#   check (C3) carries the same kind: against the distance 120 frames earlier its close-range relation must break.
# EXPECTS: every check PASS and every count equal to the frozen file; each control's run FAILs.
# FOLLOWS: emu/mame-patches/ tests/expected/mizuumi_struct.tsv tests/lib/controls.sh tests/lua/field_trace.lua
#   tests/lua/pokes_spec.lua tests/lua/read_tap.lua tests/replays/ tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: sides-swapped — the checks run with each side's candidate fields read against the other side's HP and X must fail the hit-flag, hit-counter and streak checks, so the checks see which side is which (in-gate on the real traces; as a mode the gate FAILs)
# MUST-FIRE: known-bad: refutation-pokes — the checks run with the poked 03 leg in place of the real one must fail the +0x15A refutation, and every value poked into +0x130 must read back, so the trace reads both addresses and the refutation could have come out the other way (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: roles-inverted — C8 run with each tapped replay's winner and loser swapped, and replay 02's checks run with its human and CPU sides swapped, must fail (C8, C8b and C4), so every role statement — 0x027CCC on the winner, 0x031206 on 03's winner only, the +0x39F/+0x3F0/+0x05 writers ram.md attributes to a winner or a loser (C8b), +0x380 2 on the human side — is derived (02's human side from its input script, 03's and 37's winners from HP at their first decisive outcome), not assumed (in-gate; as a mode the gate FAILs)
#
# NOT COVERED: the ~70 other unadopted candidates (build-dir record of 14z-189: build/t118/; GitHub #118); what
#   +0x130's per-fighter offset is (a box width is the guess, not measured); what +0x15A and +0x18D ARE; the finish TYPE behind +0x3BE/+0x3BF; character-specific slots (+0x34-+0x36,
#   +0x360-+0x37F) for the characters this corpus does not play; a 1P match a human wins; FBNeo (one emulator).
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] [FREEZE=1] tests/audit_mizuumi_struct.sh
#   emulator tier, MAME; ~4 min (5 legs in parallel, then the poked leg)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
EXPECT="$REPO/tests/expected/mizuumi_struct.tsv"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "  host  $(uname -sm); MAME_BIN $MAME_BIN"

# ADDRESSES ARE COMPUTED from the block base, never concatenated (14z-189: "ff84"+"39f" read a wrong address as 0).
F="ff8109:b:timer"; RT=""
for s in 1 2; do
    base=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 005:b:status 010:w:x 050:w:hp 06d:b:hitflag 11d:b:throwrange 130:w:dist 15a:b:timeover \
                18d:b:winpose 1b6:w:hits 380:b:playing 39f:b:streak 3f0:b:streakm; do
        F="$F,$(printf '%06x' $((base + 0x${spec%%:*}))):${spec#*:}$s"
    done
    for o in 004 06c 11c 130 15a 18c 1b6 380 39e 3f0; do   # the write tap: the word holding each field, decimal length
        RT="$RT${RT:+;}$(printf '%06x' $((base + 0x$o))),2"
    done
done
leg() {  # leg <name> <replay> <frames> [pokes]
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/$2.rpl" FIELDS="$F" \
        POKES="${4:-}" FIELD_OUT="$W/$1.fields" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true   # a teardown segfault (MFI-12): the FIELDSUMMARY line decides
}
tapleg() {  # tapleg <name> <replay> <frames>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/$2.rpl" RTAP="$RT" WINDOW="0,0" \
        TRACE_OUT="$W/$1.tap" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/read_tap.lua" \
        > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true   # the END line decides
}
echo "== 1. the legs (pristine vsavj, MAME)"
leg 02_demitri_vs_cpu 02_demitri_vs_cpu 12000 & leg 03_two_player_vs 03_two_player_vs 12000 &
leg 37_victor_ko_vsavj 37_victor_ko_vsavj 7000 &
tapleg tap03 03_two_player_vs 12000 & tapleg tap37 37_victor_ko_vsavj 7000 &
wait
fail=0
for r in 02_demitri_vs_cpu 03_two_player_vs 37_victor_ko_vsavj; do
    grep -q '^FIELDSUMMARY' "$W/$r.fields" 2>/dev/null || { echo "  FAIL  $r: no FIELDSUMMARY (see $W/$r/mame.log) — VOID"; fail=1; }
done
for t in tap03 tap37; do
    grep -q '^END ' "$W/$t.tap" 2>/dev/null || { echo "  FAIL  $t: no END line (see $W/$t/mame.log) — VOID"; fail=1; }
done
[ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_struct (a leg did not complete)"; exit 1; }
echo "  ok    five legs complete"

# the poked leg: its pokes are computed from the real 03 leg, so it runs after it
python3 - "$W/03_two_player_vs.fields" "$W/pokes.txt" <<'PY'
import sys
fr = []
for l in open(sys.argv[1]):
    if l.startswith("F "):
        p = l.split(); d = {kv.split("=")[0]: int(kv.split("=")[1]) for kv in p[2:]}
        if d["hp1"] > 0 and d["hp2"] > 0 and d["x1"] and d["x2"]:
            fr.append((int(p[1]), abs(d["x1"] - d["x2"])))
fr = fr[:3000]
ent = [f"{f}:ff8530:{v:04x}" for f, v in fr] + [f"{fr[0][0]}-{fr[299][0]}:ff855a:01"]
open(sys.argv[2], "w").write(";".join(ent))
PY
leg poked03 03_two_player_vs 12000 "$(cat "$W/pokes.txt")"
grep -q '^FIELDSUMMARY' "$W/poked03.fields" 2>/dev/null || { echo "  FAIL  poked03: no FIELDSUMMARY (see $W/poked03/mame.log) — VOID"; exit 1; }
echo "  ok    the poked leg complete ($(tr ';' '\n' < "$W/pokes.txt" | wc -l | tr -d ' ') poke entries)"

check() {  # check <swap 0|1> <the 03 leg's name> <out.tsv> [<invert 02's roles 0|1>] — prints [tag] ok/FAIL lines, writes the counts, exits 1 on any FAIL
    python3 - "$W" "$1" "$2" "$3" "$REPO/tests/replays/02_demitri_vs_cpu.rpl" "${4:-0}" <<'PY'
import sys, re
from statistics import median
W, swap, leg03, out = sys.argv[1], sys.argv[2] == "1", sys.argv[3], sys.argv[4]
# replay 02's HUMAN side, derived from its own input script (the side with joystick/button entries), never assumed
# (rule-checker run 2026-10-03-587 Q4); roles-inverted swaps it to prove C4 and C5-1P see which side is which
sides02 = {int(m) for m in re.findall(r"\bp([12])=", open(sys.argv[5]).read())}
inv02 = sys.argv[6] == "1"
CAND = ("status", "hitflag", "throwrange", "dist", "timeover", "winpose", "hits", "playing", "streak", "streakm")
def load(r):
    T = []
    for l in open(f"{W}/{r}.fields"):
        if l.startswith("F "):
            p = l.split(); d = {"f": int(p[1])}
            for kv in p[2:]:
                k, v = kv.split("="); d[k] = int(v)
            if swap:   # the control: each side's CANDIDATE fields read against the other side's HP and X
                for c in CAND:
                    d[c + "1"], d[c + "2"] = d[c + "2"], d[c + "1"]
            T.append(d)
    return T
legs = {"02": load("02_demitri_vs_cpu"), "03": load(leg03), "37": load("37_victor_ko_vsavj")}
bad, counts = [], []
def ok(t, m): print(f"  ok    [{t}] {m}")
def no(t, m): print(f"  FAIL  [{t}] {m}"); bad.append(t)
def res(c, t, m): (ok if c else no)(t, m)
def cnt(k, v): counts.append(f"{k}\t{v}")
def drops(T, s): return [b["f"] for a, b in zip(T, T[1:]) if 0 <= b[f"hp{s}"] < a[f"hp{s}"]]
def near(fs, gs): return sum(1 for f in fs if any(abs(f - g) <= 3 for g in gs))
def inmatch(d): return d["hp1"] > 0 and d["hp2"] > 0 and d["x1"] and d["x2"]
# C1 +0x6D — a CROSS-CHECK of a KNOWN row, not an adoption: atlas/ram.md's recent-hit slots +0x6C..+0x6F hold one byte per
# ATTACKING block (+0x6C[attacker +0x70]), so +0x6D is the slot for hits FROM block 1 (P2). Mizuumi's "Received Hit Flag"
# is that slot seen from P1: P1's rises within 3 frames of P1's own hp drop; P2's never rises although P2 is hit.
rise = {1: 0, 2: 0}; own = opp = 0; p2hit = 0
for T in legs.values():
    for s, o in ((1, 2), (2, 1)):
        r = [b["f"] for a, b in zip(T, T[1:]) if a[f"hitflag{s}"] == 0 and b[f"hitflag{s}"] != 0]
        rise[s] += len(r)
        if s == 1:
            own += near(r, drops(T, 1)); opp += near(r, drops(T, 2))
    p2hit += len(drops(T, 2))
cnt("hitflag_rises_p1", rise[1]); cnt("hitflag_near_own_drop_p1", own); cnt("hitflag_near_opp_drop_p1", opp)
cnt("hitflag_rises_p2", rise[2]); cnt("p2_hp_drops", p2hit)
res(rise[1] and own * 10 >= rise[1] * 9 and opp * 20 <= rise[1] and rise[2] == 0 and p2hit, "C1",
    f"+0x6D (the slot for hits from P2): P1's rises {rise[1]}, {own} within 3f of P1's own hp drop, {opp} of P2's; P2's rises {rise[2]} while P2 took {p2hit} hits")
# C2 +0x1B6 hits-landed counter: increments within 3 frames of the OPPONENT's hp drop; control: its own
inc = n_opp = n_own = 0
for T in legs.values():
    for s, o in ((1, 2), (2, 1)):
        i = [b["f"] for a, b in zip(T, T[1:]) if b[f"hits{s}"] > a[f"hits{s}"]]
        inc += len(i); n_opp += near(i, drops(T, o)); n_own += near(i, drops(T, s))
cnt("hits_increments", inc); cnt("hits_near_opp_drop", n_opp); cnt("hits_near_own_drop", n_own)
res(inc and n_opp * 10 >= inc * 9 and n_own * 10 <= inc, "C2", f"+0x1B6 increments {inc}: {n_opp} within 3f of an OPPONENT hp drop, {n_own} of its own")
# C3 +0x11D throw range — separation, not a median ratio (a replay fought at close range has a low "off" median too):
# almost no "on" frame lies beyond 80 px, while a quarter or more of the "off" frames do
# Its CONTROL IN THE CHECK (rule-checker run 2026-10-03-592 Q4: sides-swapped cannot move a statistic of the symmetric
# |x1-x2|): the same "on" frames held against the distance 120 frames EARLIER must break the relation (more than 1 in
# 200 beyond 80 px) — a flag that merely followed some slower quantity would keep it
on, off, lag_on = [], [], []
for T in legs.values():
    dist_at = {d["f"]: abs(d["x1"] - d["x2"]) for d in T if inmatch(d)}
    for d in T:
        if inmatch(d):
            for s in (1, 2):
                (on if d[f"throwrange{s}"] else off).append(abs(d["x1"] - d["x2"]))
                if d[f"throwrange{s}"] and (d["f"] - 120) in dist_at:
                    lag_on.append(dist_at[d["f"] - 120])
far_on = sum(1 for x in on if x > 80); far_off = sum(1 for x in off if x > 80); lag_far = sum(1 for x in lag_on if x > 80)
cnt("throwrange_on_frames", len(on)); cnt("throwrange_on_over80", far_on); cnt("throwrange_off_frames", len(off)); cnt("throwrange_off_over80", far_off)
cnt("throwrange_on_lag120", len(lag_on)); cnt("throwrange_on_lag120_over80", lag_far)
res(on and off and far_on * 200 <= len(on) and far_off * 4 >= len(off) and lag_far * 200 > len(lag_on), "C3",
    f"+0x11D: while 1, {far_on} of {len(on)} side-frames beyond 80 px; while 0, {far_off} of {len(off)}; control: against the distance 120 frames earlier, {lag_far} of {len(lag_on)} 'on' side-frames beyond 80 px — the current distance is what it tracks")
# C4 +0x380 playing: 1P — the human side (from the replay's inputs) reaches 2, the CPU side never leaves 0 although it takes hits
T = legs["02"]
if len(sides02) != 1:
    no("C4", f"replay 02's input script drives sides {sorted(sides02)} — not a 1P replay, the human side cannot be derived")
H = next(iter(sides02)) if len(sides02) == 1 else 1
if inv02:
    H = 3 - H
C = 3 - H
ph, pc = {d[f"playing{H}"] for d in T}, {d[f"playing{C}"] for d in T}
cnt("human_02", f"P{H}")
cnt("playing_02_p1", ",".join(map(str, sorted({d["playing1"] for d in T})))); cnt("playing_02_p2", ",".join(map(str, sorted({d["playing2"] for d in T})))); cnt("cpu_side_hp_drops_02", len(drops(T, C)))
res(2 in ph and pc == {0} and drops(T, C), "C4", f"+0x380 in 1P: human side P{H} (from the replay's inputs) {sorted(ph)}, CPU side P{C} {sorted(pc)} while it took {len(drops(T, C))} hits")
# the first DECISIVE OUTCOME: the side whose opponent DIED (37) or that had more HP at the time-over (03) — whether
# that outcome ends the match rather than a round or a bat is NOT measured here ($FF8107 / $FF810C would)
def winner(T):
    for d in T:
        if d["hp1"] < 0 and d["hp2"] >= 0: return 2, d["f"]
        if d["hp2"] < 0 and d["hp1"] >= 0: return 1, d["f"]
    t0 = next((d for d in T if d["timer"] == 0 and d["hp1"] > 0 and d["hp2"] > 0), None)
    return (1 if t0["hp1"] > t0["hp2"] else 2, t0["f"]) if t0 else (None, None)
W_ = {k: winner(legs[k]) for k in ("03", "37")}
# replay 02: only its FIRST KO is frozen — a KO can cost a bat without ending the match, and nothing here shows
# where 02's match ends (rule-checker run 2026-10-03-588), so no winner is claimed for it
W02 = winner(legs["02"])
cnt("first_ko_02", f"P{W02[0]} survives at f{W02[1]}" if W02[0] else "-")
for k, (w, f0) in W_.items():
    if w is None:
        no("C0", f"replay {k}: no decisive outcome found — VOID")
if "C0" in bad:
    sys.exit(1)
# C4b +0x380 on 37's loser: 2 until after its death, then 0; the winner stays 2
T = legs["37"]; w, f0 = W_["37"]; l = 3 - w
clr = next((d["f"] for d in T if d["f"] > f0 and d[f"playing{l}"] == 0), None)
wend = {d[f"playing{w}"] for d in T if d["f"] >= f0}
cnt("playing_37_loser_cleared", clr if clr else "-"); cnt("playing_37_winner_after", ",".join(map(str, sorted(wend))))
res(clr and wend == {2} and all(d[f"playing{l}"] == 2 for d in T if f0 - 100 <= d["f"] <= f0), "C4b",
    f"+0x380 in 37: the loser P{l} (dead at f{f0}) cleared at f{clr}; the winner holds {sorted(wend)}")
# C5 +0x39F / +0x3F0 on the 2P winner of the first decisive outcome only; never in the 1P replay's window
for k in ("03", "37"):
    T = legs[k]; w, f0 = W_[k]; l = 3 - w
    sw, sl = max(d[f"streak{w}"] for d in T), max(d[f"streak{l}"] for d in T)
    mw, ml = max(d[f"streakm{w}"] for d in T), max(d[f"streakm{l}"] for d in T)
    first = next((d["f"] for d in T if d[f"streak{w}"]), None)
    cnt(f"winner_{k}", f"P{w}@{f0}"); cnt(f"streak_{k}", f"{sw}/{sl}"); cnt(f"streakm_{k}", f"{mw}/{ml}"); cnt(f"streak_first_{k}", first)
    res(sw >= 1 and sl == 0 and mw >= 1 and ml == 0, "C5", f"replay {k}: +0x39F/+0x3F0 winner P{w} {sw}/{mw} (first at f{first}, the first decisive outcome at f{f0}), loser {sl}/{ml}")
s1 = max(max(d["streak1"], d["streak2"], d["streakm1"], d["streakm2"]) for d in legs["02"])
cnt("streak_any_1p", s1)
res(s1 == 0, "C5", f"+0x39F/+0x3F0 never set in the 1P replay 02's 12000-frame window (max {s1}; its first KO at f{W02[1]}, where the match ends is not measured)")
# C5b +0x18D RECORDED, its name not adopted: the loser's stays 0 in both; the winners' values are frozen as measured
vals = {}
for k in ("03", "37"):
    T = legs[k]; w, f0 = W_[k]; l = 3 - w
    vals[k] = (max(d[f"winpose{w}"] for d in T), max(d[f"winpose{l}"] for d in T))
    cnt(f"winpose_{k}", f"{vals[k][0]}/{vals[k][1]}")
res(vals["03"][1] == 0 and vals["37"][1] == 0, "C5b",
    f"+0x18D winner/loser: 03 (time-over) {vals['03'][0]}/{vals['03'][1]}, 37 (KO) {vals['37'][0]}/{vals['37'][1]} — the loser's stays 0")
# C6a +0x05 at the first decisive outcome: the winner 0x08, the loser 0x0A at 03's time-over and 0x0C at 37's KO
for k, lv in (("03", 0x0A), ("37", 0x0C)):
    T = legs[k]; w, f0 = W_[k]; l = 3 - w
    st = next((d["f"] for d in T if d["f"] >= f0 and d[f"status{w}"] == 0x08 and d[f"status{l}"] == lv), None)
    cnt(f"status_outcome_first_{k}", st if st else "-")
    res(st, "C6a", f"+0x05 at replay {k}'s first decisive outcome (f{f0}): winner 0x08 / loser 0x{lv:02X} first at f{st}")
# C6b +0x15A never set (mizuumi's "Time Over Flag" does not hold)
to = sum(1 for Tl in legs.values() for d in Tl if d["timeover1"] or d["timeover2"])
cnt("timeover_nonzero_frames", to)
res(to == 0, "C6b", f"+0x15A nonzero on {to} frames of the three legs — mizuumi's 'Time Over Flag' does not hold")
# C7 +0x130 is the X distance LESS A PER-FIGHTER OFFSET: per leg and side, distN-|x1-x2| lies within 3 px of that
# side's modal offset on most in-match frames. CONTROL: the same against |x1-x2| taken LAG frames earlier, a distance
# that is not the current one — pooled over the legs it must fall far below (replay 03's fighters barely move, so
# its lagged distance stays close: the control is pooled, never per leg)
from collections import Counter
LAG = 120
def share(T, s, lag):
    offs = [T[i][f"dist{s}"] - abs(T[i - lag]["x1"] - T[i - lag]["x2"]) for i in range(LAG, len(T)) if inmatch(T[i])]
    m = Counter(offs).most_common(1)[0][0]
    return m, sum(1 for o in offs if abs(o - m) <= 3), len(offs)
rn = rt = cn = ct = 0; low = []
for k, T in legs.items():
    for s in (1, 2):
        m, a, n = share(T, s, 0); _, b, _ = share(T, s, LAG)
        rn += a; rt += n; cn += b; ct += n
        cnt(f"dist_{k}_P{s}", f"mode {m} within3 {a}/{n} lag{LAG} {b}/{n}")
        if a * 4 < n * 3: low.append(f"{k}P{s} {a}/{n}")
res(not low, "C7", f"+0x130 - |x1-x2| within 3 px of each side's modal offset on >= 3/4 of in-match frames, every leg and side ({rn}/{rt} pooled){' — below: ' + ', '.join(low) if low else ''}")
res(rt and cn * 2 <= ct and rn >= 2 * cn, "C7", f"+0x130 control: against |x1-x2| {LAG} frames earlier, {cn}/{ct} pooled — the current distance is what it tracks")
open(out, "w").write("\n".join(counts) + "\n")
sys.exit(1 if bad else 0)
PY
}

writers() {  # writers <out.tsv> — the writer PCs of every field in the two tap legs, frozen
    python3 - "$W" "$1" <<'PY'
import re, sys
from collections import defaultdict, Counter
W, out = sys.argv[1], sys.argv[2]
FIELD = {0x005: "status", 0x06d: "hitflag", 0x11d: "throwrange", 0x130: "dist", 0x131: "dist", 0x15a: "timeover",
         0x18d: "winpose", 0x1b6: "hits", 0x1b7: "hits", 0x380: "playing", 0x39f: "streak", 0x3f0: "streakm"}
WORD = {"dist", "hits"}
lines, bad = [], 0
for t in ("tap03", "tap37"):
    pcs = defaultdict(Counter); vals = defaultdict(lambda: defaultdict(set)); nw = 0
    for l in open(f"{W}/{t}.tap"):
        m = re.match(r"W (\d+) PC (\w+) off (\w+) data (\w+) mask (\w+)", l)
        if not m:
            continue
        pc, off, data, mask = m[2], int(m[3], 16), int(m[4], 16), int(m[5], 16)
        base = off & ~1
        seen = set()
        for a, v, on in ((base, (data >> 8) & 0xff, mask & 0xff00), (base + 1, data & 0xff, mask & 0x00ff)):
            side = 1 if a < 0xff8800 else 2
            fld = FIELD.get(a - (0xff8400 if side == 1 else 0xff8800))
            if not on or not fld or (side, fld) in seen:
                continue
            seen.add((side, fld)); nw += 1
            pcs[(side, fld)][pc] += 1
            if fld not in WORD:
                vals[(side, fld)][pc].add(v)
    if nw == 0:
        print(f"  FAIL  [W] {t}: no write to any field — a dead tap"); bad = 1
    for (side, fld) in sorted(pcs):
        parts = []
        for pc in sorted(pcs[(side, fld)]):
            vs = sorted(vals[(side, fld)][pc])
            vtxt = "" if fld in WORD else ("=" + "/".join(f"{v:02x}" for v in vs) if len(vs) <= 4 else f"=*{len(vs)}")
            parts.append(f"{pc}:{pcs[(side, fld)][pc]}{vtxt}")
        lines.append(f"writers_{t}_P{side}_{fld}\t{' '.join(parts)}")
    print(f"  ok    [W] {t}: {nw} field writes, {len({p for c in pcs.values() for p in c})} distinct writer PCs")
open(out, "w").write("\n".join(lines) + "\n")
sys.exit(bad)
PY
}

echo "== 2. the checks"
if vs_ctl_is sides-swapped; then
    if check 1 03_two_player_vs "$W/got.tsv"; then vs_ctl_dead sides-swapped "the swapped checks passed" || true
    else echo "CONTROL FIRED: sides-swapped — the gate ran with the sides swapped and its checks failed"; fi
    echo "FAIL: audit_mizuumi_struct (control mode)"; exit 1
fi
if vs_ctl_is refutation-pokes; then
    if check 0 poked03 "$W/got.tsv"; then vs_ctl_dead refutation-pokes "the checks passed on the poked leg" || true
    else echo "CONTROL FIRED: refutation-pokes — the gate ran on the poked 03 leg and its checks failed"; fi
    echo "FAIL: audit_mizuumi_struct (control mode)"; exit 1
fi
check 0 03_two_player_vs "$W/got.tsv" || fail=1
writers "$W/writers.tsv" || fail=1
# [C8] THE ROLE STATEMENTS ram.md's +0x18D row makes, DERIVED here from the per-side writer sets and each replay's
# winner (rule-checker run 2026-10-03-586 Q4: the winner/loser mapping was a hand step): 0x027CCC writes the
# WINNER's +0x18D and never the loser's, on both tapped replays; 0x031206 writes it only on 03's (time-over) winner.
# Its control roles-inverted runs the same check with each replay's winner and loser swapped and must FAIL.
c8() {  # $1 = 0 (as measured) | 1 (roles inverted)
python3 - "$W/writers.tsv" "$W/got.tsv" "$1" <<'PY'
import sys
w = dict(l.rstrip("\n").split("\t", 1) for l in open(sys.argv[1]) if "\t" in l)
g = dict(l.rstrip("\n").split("\t", 1) for l in open(sys.argv[2]) if "\t" in l)
inv = sys.argv[3] == "1"; bad = 0
for r in ("03", "37"):
    win = int(g[f"winner_{r}"].split("@")[0][1])
    if inv:
        win = 3 - win
    lose = 3 - win
    ws = {e.split(":")[0] for e in w.get(f"writers_tap{r}_P{win}_winpose", "").split()}
    ls = {e.split(":")[0] for e in w.get(f"writers_tap{r}_P{lose}_winpose", "").split()}
    ok = "027ccc" in ws and "027ccc" not in ls and (("031206" in ws) == (r == "03")) and "031206" not in ls
    print(f"  {'ok  ' if ok else 'FAIL'}  [C8] replay {r}: winner P{win}'s +0x18D writers {'include' if '027ccc' in ws else 'LACK'} 0x027CCC, "
          f"the loser P{lose}'s {'include' if '027ccc' in ls else 'lack'} it; 0x031206 on the winner {'yes' if '031206' in ws else 'no'}, on the loser {'yes' if '031206' in ls else 'no'}")
    bad |= not ok
    # [C8b] every OTHER writer ram.md attributes to a winner or a loser (rule-checker run 2026-10-03-598 Q4): (field,
    # pc, role, the value it must write there, exclusive = absent from the other side's list)
    def vals(side, fld):
        out = {}
        for e in w.get(f"writers_tap{r}_P{side}_{fld}", "").split():
            pc, rest = e.split(":", 1)
            out[pc] = rest.split("=", 1)[1] if "=" in rest else ""
        return out
    ROLE = [("streak", "00991c", "win", "01", True), ("streak", "009924", "lose", "00", True),
            ("streakm", "009920", "win", "01", True), ("streakm", "009c8e", "win", "01", False),
            ("streakm", "009c8e", "lose", "00", False), ("status", "027c7c", "win", "08", True)]
    ROLE += [("status", "027c54", "lose", "0a", True)] if r == "03" else [("status", "027ce8", "lose", "0c", True)]
    miss = []
    for fld, pc, role, v, excl in ROLE:
        me, other = (win, lose) if role == "win" else (lose, win)
        mv, ov = vals(me, fld), vals(other, fld)
        if mv.get(pc) != v or (excl and pc in ov):
            miss.append(f"{fld}:{pc}({role})")
    print(f"  {'ok  ' if not miss else 'FAIL'}  [C8b] replay {r}: the {len(ROLE)} role-attributed writers of +0x39F/+0x3F0/+0x05 sit on the derived side with their value"
          + (f" — wrong: {' '.join(miss)}" if miss else ""))
    bad |= bool(miss)
sys.exit(bad)
PY
}
if vs_ctl_is roles-inverted; then
    if c8 1 > "$W/c8inv.log" 2>&1; then c8r=0; else c8r=1; fi
    check 0 03_two_player_vs "$W/inv02.tsv" 1 > "$W/inv02.log" 2>&1 || true
    cat "$W/c8inv.log" "$W/inv02.log"
    if [ "$c8r" = 0 ] || ! grep -q 'FAIL  \[C8b\]' "$W/c8inv.log" || ! grep -q 'FAIL  \[C4\]' "$W/inv02.log"; then
        vs_ctl_dead roles-inverted "with the roles swapped C8 rc=$c8r and replay 02's C4 $(grep -q 'FAIL  \[C4\]' "$W/inv02.log" && echo failed || echo PASSED)" || true
    else
        echo "CONTROL FIRED: roles-inverted — the gate ran C8 and replay 02's checks with the roles swapped and they failed"
    fi
    echo "FAIL: audit_mizuumi_struct (control mode)"; exit 1
fi
c8 0 || fail=1
if c8 1 > "$W/c8inv.log" 2>&1; then c8r=0; else c8r=1; fi
check 0 03_two_player_vs "$W/inv02.tsv" 1 > "$W/inv02.log" 2>&1 || true
if [ "$c8r" = 0 ] || ! grep -q 'FAIL  \[C8b\]' "$W/c8inv.log" || ! grep -q 'FAIL  \[C4\]' "$W/inv02.log"; then
    vs_ctl_dead roles-inverted "with the roles swapped C8 rc=$c8r and replay 02's checks failed on: $(grep -o 'FAIL  \[C[0-9a-z]*\]' "$W/inv02.log" | tr '\n' ' ') — some role statement does not see which side is which" || fail=1
else
    vs_ctl_fired roles-inverted "$(grep -c 'FAIL  \[C8\]' "$W/c8inv.log") of 2 C8 rows, $(grep -c 'FAIL  \[C8b\]' "$W/c8inv.log") of 2 C8b rows, and replay 02's C4, failed with the roles swapped"
fi
cat "$W/writers.tsv" >> "$W/got.tsv"

echo "== 3. the must-fire controls (in-gate)"
if check 1 03_two_player_vs "$W/swap.tsv" > "$W/swap.log" 2>&1; then
    vs_ctl_dead sides-swapped "the checks PASSED with the sides swapped — they do not see which side is which" || fail=1
elif grep -q 'FAIL  \[C1\]' "$W/swap.log" && grep -q 'FAIL  \[C2\]' "$W/swap.log" && grep -q 'FAIL  \[C5\]' "$W/swap.log"; then
    vs_ctl_fired sides-swapped "$(grep -c '  FAIL' "$W/swap.log") check(s) failed with the sides swapped, C1 C2 C5 among them"
else
    vs_ctl_dead sides-swapped "the swapped run failed, but not on all of C1 C2 C5: $(grep -o 'FAIL  \[C[0-9a-z]*\]' "$W/swap.log" | tr '\n' ' ')" || fail=1
fi
python3 - "$W/poked03.fields" "$W/pokes.txt" > "$W/pokeread.txt" <<'PY'
import sys
want = {}; tw = {}
for e in open(sys.argv[2]).read().split(";"):
    f, a, v = e.split(":")
    if a == "ff8530":
        want[int(f)] = int(v, 16)
    elif a == "ff855a":   # a frame RANGE: every frame in it must read the poked value back
        lo, hi = (int(x) for x in f.split("-"))
        for k in range(lo, hi + 1):
            tw[k] = int(v, 16)
got = {}; tg = {}; to = 0
for l in open(sys.argv[1]):
    if l.startswith("F "):
        p = l.split(); d = {kv.split("=")[0]: int(kv.split("=")[1]) for kv in p[2:]}
        if int(p[1]) in want:
            got[int(p[1])] = d["dist1"]
        if int(p[1]) in tw:
            tg[int(p[1])] = d["timeover1"]
        to += d["timeover1"] != 0
print(f"{sum(1 for f, v in want.items() if got.get(f) == v)} {len(want)} {to} "
      f"{sum(1 for f, v in tw.items() if tg.get(f) == v)} {len(tw)}")
PY
read -r pk_dist pk_n pk_to pk_ta pk_tn < "$W/pokeread.txt"
echo "  info  the poked leg reads back +0x130 = the poked value on $pk_dist of $pk_n frames, +0x15A = the poked value on $pk_ta of the $pk_tn frames of its poked range (nonzero on $pk_to frames in all)"
printf 'poke_dist_readback\t%s/%s\npoke_timeover_frames\t%s\npoke_timeover_readback\t%s/%s\n' "$pk_dist" "$pk_n" "$pk_to" "$pk_ta" "$pk_tn" >> "$W/got.tsv"
if check 0 poked03 "$W/poked.tsv" > "$W/poked.log" 2>&1; then
    vs_ctl_dead refutation-pokes "the checks PASSED on the poked leg — the refutations could not have come out the other way" || fail=1
elif grep -q 'FAIL  \[C6b\]' "$W/poked.log" && [ "$pk_dist" = "$pk_n" ] && [ "$pk_n" -gt 0 ] && [ "$pk_ta" = "$pk_tn" ] && [ "$pk_tn" -gt 0 ]; then
    vs_ctl_fired refutation-pokes "the +0x15A refutation failed on the poked leg ($(grep -E 'FAIL  \[C6b\]' "$W/poked.log" | sed 's/^ *//')), +0x15A read back on $pk_ta of the $pk_tn frames of its poked range, and +0x130 read back $pk_dist of $pk_n poked values"
else
    vs_ctl_dead refutation-pokes "the poked run did not fail C6b, or a poke did not read back on every poked frame (+0x130 $pk_dist/$pk_n, +0x15A $pk_ta/$pk_tn): $(grep -o 'FAIL  \[C[0-9a-z]*\]' "$W/poked.log" | tr '\n' ' ')" || fail=1
fi

echo "== 4. the frozen counts"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_struct (not frozen: fix the red first)"; exit 1; }
    { echo "# tests/expected/mizuumi_struct.tsv — the counts tests/audit_mizuumi_struct.sh measured on pristine vsavj (GitHub #118)."
      echo "# Evidence class: in-emulator. Frozen 14z-189 with FREEZE=1; counts, value sets and writer PCs only, no ROM bytes."
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1)"; exit 1; }
if grep -v '^#' "$EXPECT" | diff - "$W/got.tsv" > "$W/diff.txt"; then echo "  ok    every count as frozen"
else echo "  FAIL  the counts moved:"; sed 's/^/        /' "$W/diff.txt"; fail=1; fi
if [ "$fail" = 0 ]; then echo "PASS: audit_mizuumi_struct"; else echo "FAIL: audit_mizuumi_struct"; exit 1; fi
