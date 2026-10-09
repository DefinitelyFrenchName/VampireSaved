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
#   EXTENDED 14z-196 (HOMING item 4 of the 14z-194 pilot, build/agent194/t118/HOMING.md): +0x3B0 (RECORDED, "Lose a bat
#   Flag" not adopted) reads 1 first, goes 1->0 0-1 frames after the side's HP falls to 144 or below and reads 144 there,
#   and becomes 0xFF on the KO loser on the KO frame or the next, never on the winner (C9); +0x3B6 (RECORDED, "Deathblow
#   Type" not adopted) reads 0 on the loser at EVERY KO and 0 through the time-overs of 03 and 104, the WINNER's value at
#   each KO frozen, not judged (0, 1 and 3 seen) — 14z-196 withdrew the 14z-194 "3 on a CPU KO winner" as a claim: CPU
#   winners read 3 on every KO here, but the static writer PRG:0x019128-0x019152 has no CPU test (7/6/5 under three flags,
#   else the KO hit's attack-record byte +0x1F) (C10); at every KO each side's human/CPU control is the game's own +0x380
#   on the KO frame, equal per leg to the script's START derivation (human only if started after its last loss) and
#   human wherever the script drives the side (C10b); +0x3B2/+0x3E2 (consistent with "Auto-Guard Flag") read 1 from a side's AUTO press (D,D,button after its select
#   confirm, derived from the script) through the match's end and 0 on every side that did not choose AUTO (C11); +0x3E1
#   (consistent with "Character Palette") is K-1 for a side that confirmed with button K (C12) and 8 for a side that chose
#   AUTO (C12b: both such sides confirm with button 1 — whether AUTO adds 8 or replaces K-1 is not measured); +0x390
#   (consistent with "LONGWORD Player Score", 1P only) rises only within 3 frames of an opponent HP drop on the human side
#   of the 1P replay 02, never on its CPU side, every value BCD, and reads 1 throughout the 2P matches 03 and 37 (C13);
#   and the role-attributed writers 0x019152 (+0x3B6, once per KO, on the KO frame, on the winner, its value), 0x00A6A0 (+0x3B0's in-match 1->0 and
#   the loser's 0xFF), 0x020FB6/0x020FBA (+0x3B2/+0x3E2, once per human side, 1 on the AUTO press) and 0x02101A (+0x3E1,
#   once per human side, its in-match value) sit on the derived side with the derived value (C14).
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
#   14z-196: nine more FIELD legs — 104_1p_auto_ko_win (1P, P1 AUTO, a time-over), 05_timeout_idle (1P idle, a CPU KO),
#   105_legacy_2pwin_auto (2P, P1 AUTO, a human KO) and 118_sel_b1..6 (replay 03 with P1 confirming with button 1..6) —
#   five more WRITE-TAP legs (02, 104, 05, 105, 118_sel_b4), every tap leg also over +0x3B0/+0x3B2/+0x3B6/+0x3E0/+0x3E2,
#   two multi-KO legs for C10, C10b and C14, field and tap (128_shadow_vs_legacy_vsavj, a 2P game; 26_don_arcade_mash, 1P),
#   and a POKE leg: replay 03 with the time-over WINNER's +0x3B6 poked to 0x5A on 41 frames around 03's time-over (side
#   and frames derived from the real 03 leg). Roles are derived, never assumed: the outcome and its winner from both HP
#   words and the round timer, a side's human/CPU control from the replay's own input script, the AUTO choice and the
#   confirm button from that script.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row, each loaded zip's sha1 — and the MAME (tests/lib/mame_ident.sh), or the
#   gate FAILs before any leg (added 14z-196, the audit_mizuumi_attack.sh pattern); every check PASS and every count
#   equal to the frozen file; each control's run FAILs.
# FOLLOWS: emu/mame-patches/ tests/expected/mizuumi_struct.tsv tests/lib/controls.sh tests/lib/mame_ident.sh tests/lua/field_trace.lua
#   tests/lua/pokes_spec.lua tests/lua/read_tap.lua tests/replays/ tools/run_mame.sh tools/setup_mame.sh
#   tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py tests/expected/registry.tsv
#
# MUST-FIRE: perturbed-copy: sides-swapped — the checks run with each side's candidate fields read against the other side's HP and X must fail the hit-flag, hit-counter and streak checks, so the checks see which side is which (in-gate on the real traces; as a mode the gate FAILs)
# MUST-FIRE: known-bad: refutation-pokes — the checks run with the poked 03 leg in place of the real one must fail the +0x15A refutation, and every value poked into +0x130 must read back, so the trace reads both addresses and the refutation could have come out the other way (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: roles-inverted — C8 run with each tapped replay's winner and loser swapped, replay 02's checks run with its human and CPU sides swapped, and C9-C14 run with every derived role swapped (winner/loser, human/CPU, AUTO chooser), must fail (C8, C8b, C4, C9, C10, C10b on each of the six KO legs, C11 and C14), so every role statement — 0x027CCC on the winner, 0x031206 on 03's winner only, the +0x39F/+0x3F0/+0x05 writers ram.md attributes to a winner or a loser (C8b), +0x380 2 on the human side, +0x3B0's 0xFF on the KO loser, +0x3B6's 0 on the KO loser and its 0x019152 write on the winner, +0x3B2/+0x3E2 on the AUTO chooser and their writers — is derived (human sides from the input scripts, winners from HP at the first decisive outcome, the AUTO choice from the script), not assumed (in-gate; as a mode the gate FAILs)
# MUST-FIRE: known-bad: poke-3b6 — C10 run with the +0x3B6 poke leg in place of the real 03 leg must fail at 03's time-over, and every poked frame must read the poked 0x5A back, so the field read is +0x3B6 and "0 at a time-over" could have come out the other way (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: p2-confirm — C12 run with each side's +0x3E1 judged against the OTHER side's confirm button must fail (P1 confirms with 2..6 on 118_sel_b2..6, P2 with 1), so the check sees which button confirmed (in-gate; as a mode the gate FAILs)
#
# NOT COVERED: the ~70 other unadopted candidates (build-dir record of 14z-189: build/t118/; GitHub #118); what
#   +0x130's per-fighter offset is (a box width is the guess, not measured); what +0x15A and +0x18D ARE; the finish TYPE behind +0x3BE/+0x3BF; character-specific slots (+0x34-+0x36,
#   +0x360-+0x37F) for the characters this corpus does not play; a 1P match a human wins for C1-C9 and C11-C13 (C10,
#   C10b and C14's 0x019152 check judge 26's human KO win and 128's four 2P KOs); C14's AUTO and palette writers on the
#   multi-match legs 128 and 26 (judged on the single-match legs only); FBNeo (one emulator).
#   14z-196: what +0x3B0 and +0x3B6 MEAN — the bat loss is not identified, and +0x3B6's VALUE at a KO is frozen, not
#   judged (its static derivation from the KO hit's record byte +0x1F is not measured per hit); whether AUTO's 8 in
#   +0x3E1 adds to K-1 (no AUTO leg confirms with a button other than 1); +0x390 beyond replay 02 (one 1P match, four
#   rises); C9's +0x3B0 claims on the six single-outcome legs only; merged-m23.
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] [FREEZE=1] tests/audit_mizuumi_struct.sh
#   emulator tier, MAME; ~4 min (23 legs in parallel, then the two poked legs)
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
[ -x "$MAME_BIN" ] || { echo "SKIP: no reference MAME binary at $MAME_BIN"; exit 0; }
# WHICH ROM RAN (the pattern of audit_mizuumi_attack.sh, rule-checker run 2026-10-08-736 Q1; added here 14z-196): every
# reference member verified against docs/checksums.txt, the vsavj program fingerprint equal to the registry's vsavj row,
# each loaded zip's sha1 printed — a ROMDIR that is not the pristine set FAILs before any leg runs.
romchk="$(python3 "$REPO/tools/audit_roms.py" "$ROMDIR" 2>&1)" || true
echo "$romchk" | grep -q 'all match' || { echo "FAIL: ROMDIR is not the pristine reference set (tools/audit_roms.py against docs/checksums.txt):"; echo "$romchk" | tail -5; exit 1; }
romfp="$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR" --set vsavj --sha-only 2>/dev/null)" || true
regfp="$(awk -F'\t' '$2 == "vsavj" && $1 !~ /^#/ {print $1}' "$REPO/tests/expected/registry.tsv")"
[ -n "$romfp" ] && [ "$romfp" = "$regfp" ] || { echo "FAIL: vsavj program fingerprint '$romfp' is not the registry's vsavj row '$regfp'"; exit 1; }
echo "  rom   $(echo "$romchk" | grep 'all match' | head -1); vsavj program fingerprint $romfp = registry vsavj row; zips $(python3 -c 'import hashlib,sys; print(" ".join(f"{z}.zip=" + hashlib.sha1(open(f"{sys.argv[1]}/{z}.zip","rb").read()).hexdigest() for z in ("vsavj","vsav","qsound_hle")))' "$ROMDIR")"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }

# ADDRESSES ARE COMPUTED from the block base, never concatenated (14z-189: "ff84"+"39f" read a wrong address as 0).
F="ff8109:b:timer"; RT=""
for s in 1 2; do
    base=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 005:b:status 010:w:x 050:w:hp 06d:b:hitflag 11d:b:throwrange 130:w:dist 15a:b:timeover \
                18d:b:winpose 1b6:w:hits 380:b:playing 39f:b:streak 3f0:b:streakm \
                390:l:score 3b0:b:lbat 3b2:b:ag3b 3b6:b:dblow 3e1:b:pal 3e2:b:ag3e 382:b:char; do
        F="$F,$(printf '%06x' $((base + 0x${spec%%:*}))):${spec#*:}$s"
    done
    for o in 004 06c 11c 130 15a 18c 1b6 380 39e 3f0 3b0 3b2 3b6 3e0 3e2; do   # the write tap: the word holding each field, decimal length
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
# the 14z-189 legs, then (14z-196, HOMING item 4) the outcome, AUTO and palette legs: 104 (1P, AUTO, time-over), 05 (1P
# idle, a CPU KO), 105_legacy_2pwin_auto (2P, P1 AUTO, a human KO) and 118_sel_b1..6 (replay 03 with P1 confirming with
# button 1..6), with write taps on 02, 104, 05, 105 and 118_sel_b4; and (rule-checker run 2026-10-08-901 Q1/Q4) two multi-KO
# legs for C10 — 128_shadow_vs_legacy_vsavj (it starts as 2P — both STARTs pressed, P2 confirms at 1500 then idles — and
# after P2 loses its first match the game clears P2's +0x380 and P1 plays the CPU: four KOs, the last a CPU win; measured
# 14z-196 after run 903) and 26_don_arcade_mash (1P) — field and tap; every KO's roles are the game's +0x380 (C10b)
FLEGS="02_demitri_vs_cpu:02_demitri_vs_cpu:12000 03_two_player_vs:03_two_player_vs:12000 37_victor_ko_vsavj:37_victor_ko_vsavj:7000
       104:104_1p_auto_ko_win:13600 05:05_timeout_idle:12000 105auto:105_legacy_2pwin_auto:9600
       selb1:118_sel_b1:3200 selb2:118_sel_b2:3200 selb3:118_sel_b3:3200 selb4:118_sel_b4:3200 selb5:118_sel_b5:3200 selb6:118_sel_b6:3200
       c128:128_shadow_vs_legacy_vsavj:21000 c26:26_don_arcade_mash:40600"
TLEGS="tap03:03_two_player_vs:12000 tap37:37_victor_ko_vsavj:7000 tap02:02_demitri_vs_cpu:12000 tap104:104_1p_auto_ko_win:13600
       tap05:05_timeout_idle:12000 tap105auto:105_legacy_2pwin_auto:9600 tapselb4:118_sel_b4:3200
       tapc128:128_shadow_vs_legacy_vsavj:21000 tapc26:26_don_arcade_mash:40600"
for l in $FLEGS; do n="${l%%:*}"; r="${l#*:}"; leg "$n" "${r%%:*}" "${r#*:}" & done
for l in $TLEGS; do n="${l%%:*}"; r="${l#*:}"; tapleg "$n" "${r%%:*}" "${r#*:}" & done
wait
fail=0; nl=0
for l in $FLEGS; do r="${l%%:*}"; nl=$((nl + 1))
    grep -q '^FIELDSUMMARY' "$W/$r.fields" 2>/dev/null || { echo "  FAIL  $r: no FIELDSUMMARY (see $W/$r/mame.log) — VOID"; fail=1; }
done
for l in $TLEGS; do t="${l%%:*}"; nl=$((nl + 1))
    grep -q '^END ' "$W/$t.tap" 2>/dev/null || { echo "  FAIL  $t: no END line (see $W/$t/mame.log) — VOID"; fail=1; }
done
[ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_struct (a leg did not complete)"; exit 1; }
echo "  ok    $nl legs complete"

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
# the +0x3B6 poke leg (14z-196, HOMING item 4's poke-3b6; the 14z-194 pilot's eris_poke3b6.sh pattern): replay 03 with
# the TIME-OVER WINNER's +0x3B6 poked to 0x5A on 41 frames around 03's time-over — both DERIVED from the real 03 leg —
# so C10's "0 at a time-over" reads an address that can read nonzero, and could have come out the other way
python3 - "$W/03_two_player_vs.fields" "$W/pokes3b6.txt" <<'PY'
import sys
T = []
for l in open(sys.argv[1]):
    if l.startswith("F "):
        p = l.split(); d = {kv.split("=")[0]: int(kv.split("=")[1]) for kv in p[2:]}; d["f"] = int(p[1]); T.append(d)
t0 = next(d for d in T if d["timer"] == 0 and d["hp1"] > 0 and d["hp2"] > 0)
w = 1 if t0["hp1"] > t0["hp2"] else 2
open(sys.argv[2], "w").write(f"{t0['f'] - 13}-{t0['f'] + 27}:{0xff8400 + (w - 1) * 0x400 + 0x3b6:06x}:5a")
PY
leg poke3b6 03_two_player_vs 12000 "$(cat "$W/pokes3b6.txt")"
grep -q '^FIELDSUMMARY' "$W/poke3b6.fields" 2>/dev/null || { echo "  FAIL  poke3b6: no FIELDSUMMARY (see $W/poke3b6/mame.log) — VOID"; exit 1; }
echo "  ok    the +0x3B6 poke leg complete (POKES $(cat "$W/pokes3b6.txt"))"

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

check2() {  # check2 <the 03 leg's name> <invert roles 0|1> <perturbation none|p2-confirm> <out.tsv> — C9-C14 (14z-196,
            # HOMING item 4): +0x3B0, +0x3B6, +0x3B2/+0x3E2, +0x3E1, +0x390 and their role-attributed writers
    python3 - "$W" "$REPO" "$1" "$2" "$3" "$4" <<'PY'
import collections, re, sys
# check2 <W> <REPO> <the 03 leg's name> <invert roles 0|1> <perturbation none|p2-confirm> <out.tsv>
W, REPO, leg03, inv, PERT, out = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1", sys.argv[5], sys.argv[6]
RPL = {"02": "02_demitri_vs_cpu", "03": "03_two_player_vs", "37": "37_victor_ko_vsavj", "104": "104_1p_auto_ko_win",
       "05": "05_timeout_idle", "105auto": "105_legacy_2pwin_auto", **{f"selb{k}": f"118_sel_b{k}" for k in "123456"},
       "c128": "128_shadow_vs_legacy_vsavj", "c26": "26_don_arcade_mash"}
FIELDS = {"02": "02_demitri_vs_cpu", "03": leg03, "37": "37_victor_ko_vsavj", **{k: k for k in RPL if k not in ("02", "03", "37")}}
BTN = set("123456")
bad, counts = [], []
def res(c, t, m):
    print(f"  {'ok  ' if c else 'FAIL'}  [{t}] {m}")
    if not c: bad.append(t)
def cnt(k, v): counts.append(f"{k}\t{v}")
def load(p):
    T = []
    for l in open(p):
        if l.startswith("F "):
            q = l.split(); d = {"f": int(q[1])}
            for kv in q[2:]:
                k, v = kv.split("="); d[k] = int(v)
            T.append(d)
    return T
def staged(rpl):
    S = collections.defaultdict(lambda: {1: set(), 2: set()})
    for line in open(rpl):
        body = line.split("#")[0].strip()
        if not body:
            continue
        rng, *specs = body.split()
        a, _, b = rng.partition("-"); a = int(a); b = int(b) if b else a
        for sp in specs:
            m = re.match(r"^p([12])=(\S+)$", sp)
            if m:
                for fr in range(a, b + 1):
                    S[fr][int(m.group(1))] |= set(m.group(2))
    return S
def inmatch(d): return d["hp1"] > 0 and d["hp2"] > 0 and d["x1"] and d["x2"]
def rising(S, s, toks):
    """frames where any of `toks` becomes held on side s (a press), with the tokens pressed"""
    out = []
    for f in sorted(S):
        now = S[f][s] & toks; prev = S.get(f - 1, {1: set(), 2: set()})[s] & toks
        if now - prev:
            out.append((f, "".join(sorted(now - prev))))
    return out
T = {k: load(f"{W}/{v}.fields") for k, v in FIELDS.items()}
S = {k: staged(f"{REPO}/tests/replays/{v}.rpl") for k, v in RPL.items()}
HUMAN = {k: {s for fr in S[k].values() for s in (1, 2) if fr[s]} for k in RPL}
if inv:   # roles-inverted: every derived role swapped — human <-> CPU below, winner <-> loser in outcome()
    HUMAN = {k: {1, 2} - v for k, v in HUMAN.items()}
def outcome(Tl):
    """the first decisive outcome, DERIVED from HP and the round timer: (winner, loser, frame, KO|TIME) or None"""
    r = None
    for d in Tl:
        if d["hp1"] < 0 and d["hp2"] >= 0: r = (2, 1, d["f"], "KO"); break
        if d["hp2"] < 0 and d["hp1"] >= 0: r = (1, 2, d["f"], "KO"); break
    if r is None:
        t0 = next((d for d in Tl if d["timer"] == 0 and d["hp1"] > 0 and d["hp2"] > 0), None)
        if t0:
            w = 1 if t0["hp1"] > t0["hp2"] else 2
            r = (w, 3 - w, t0["f"], "TIME")
    if r and inv:
        r = (r[1], r[0], r[2], r[3])
    return r
OUT = {k: outcome(T[k]) for k in ("02", "03", "37", "104", "05", "105auto")}
for k, o in OUT.items():
    cnt(f"outcome_{k}", f"{o[3]} P{o[0]} over P{o[1]} at f{o[2]}" if o else "-")
    if o is None:
        res(False, "C9", f"replay {k}: no decisive outcome — VOID")
# C9 +0x3B0, RECORDED (mizuumi's "Lose a bat Flag" not adopted): (a) each side's first nonzero value is 1; (b) the
# in-match 1->0 transitions and the in-match frames where that side's HP falls from above 144 to 144 or below PAIR ONE TO
# ONE, each transition 0 or 1 frame after its fall (offsets frozen; the engine runs 1-3 ticks a video frame, ram.md
# +0x124), and the side's HP reads 144 on the transition frame; (c) at a KO the LOSER's value becomes 0xFF on the KO
# frame or the next (offset frozen) and the WINNER's never reads 0xFF. Independent: both HP words.
n9 = 0
for k in ("02", "03", "37", "104", "05", "105auto"):
    Tl = T[k]; o = OUT[k]
    for s in (1, 2):
        nz = [d for d in Tl if d[f"lbat{s}"]]
        first = (nz[0]["f"], nz[0][f"lbat{s}"]) if nz else None
        tr = [b for a, b in zip(Tl, Tl[1:]) if a[f"lbat{s}"] == 1 and b[f"lbat{s}"] == 0 and inmatch(b)]
        cross = [b["f"] for a, b in zip(Tl, Tl[1:]) if inmatch(a) and inmatch(b) and a[f"hp{s}"] > 144 >= b[f"hp{s}"]]
        at144 = all(b[f"hp{s}"] == 144 for b in tr)
        tf = sorted(b["f"] for b in tr)
        offs = [t - c for t, c in zip(tf, sorted(cross))]
        same = len(tf) == len(cross) and all(o in (0, 1) for o in offs)
        rst = sum(1 for a, b in zip(Tl, Tl[1:]) if a[f"lbat{s}"] != b[f"lbat{s}"] and not inmatch(b) and not (o and o[3] == "KO" and b["f"] in (o[2], o[2] + 1)))
        cnt(f"lbat_{k}_P{s}", f"first {first[1] if first else '-'}@{first[0] if first else '-'} in-match 1->0 {tf} after the hp fall by {offs} other changes off-match {rst}")
        res(first is not None and first[1] == 1 and at144 and same, "C9",
            f"replay {k} P{s}: +0x3B0 first nonzero {first}; in-match 1->0 at {[(b['f'], b[f'hp{s}']) for b in tr]} (frame, hp); HP falls to <=144 at {cross} (transition - fall {offs})")
        n9 += len(tr)
    if o and o[3] == "KO":
        w, l, f0, _ = o
        ff = next((d["f"] for d in Tl if d["f"] >= f0 and d[f"lbat{l}"] == 0xff), None)
        wff = sum(1 for d in Tl if d[f"lbat{w}"] == 0xff)
        cnt(f"lbat_ko_{k}", f"loser P{l} 0xFF at KO+{ff - f0 if ff is not None else '-'}; winner P{w} 0xFF frames {wff}")
        res(ff is not None and ff - f0 in (0, 1) and wff == 0, "C9",
            f"replay {k}: KO at f{f0} — the loser P{l}'s +0x3B0 reads 0xFF from f{ff} (KO+{ff - f0 if ff is not None else '-'}); the winner P{w}'s reads 0xFF on {wff} frames")
res(n9 > 0, "C9", f"{n9} in-match 1->0 transitions of +0x3B0 judged in all (nonzero sample)")
# C10 +0x3B6, RECORDED ("Deathblow Type Notification" not adopted): at EVERY KO (a side's HP falling below 0 while the
# other's holds — DERIVED from both HP words) the LOSER's value reads 0 on the KO frame and the WINNER's value there is
# frozen per KO with the winner's character and control — the control is the GAME'S own +0x380 on the KO frame (2 human,
# 0 CPU; C4), never the script's (rule-checker run 2026-10-08-903: 128 starts as 2P, and after P2 loses its first match
# the game clears P2's +0x380 and P1 plays the CPU) — and at a time-over (03, 104: the first outcome) both read 0 through
# the whole leg. NOT a CPU-ness claim (runs 901, 903): measured, the CPU KO winners read 3, 3, 3 and 0 (128's Aulbath)
# and the human ones 0 or 1 (26's Jedah reads 1), and the static writer has no CPU test —
# PRG:0x019128-0x019152 stores into the attacker's (the winner's) +0x3B6 7 if -$4B8F(a5) is set, else 6 if its +0x111,
# else 5 if its +0x19F, else the KO hit's attack-record byte +0x1F (a3) — so the cause of the values is not established
# and the winner's value is reported, not judged.
def kos(Tl):
    out = []
    for a, b in zip(Tl, Tl[1:]):
        for sd in (1, 2):
            if a[f"hp{sd}"] >= 0 and b[f"hp{sd}"] < 0 and b[f"hp{3 - sd}"] >= 0:
                out.append((3 - sd, sd, b["f"]) if not inv else (sd, 3 - sd, b["f"]))
    return out
KOS = {k: kos(T[k]) for k in ("02", "37", "05", "105auto", "c128", "c26")}
def role(k, s, f0):
    """the side's control at frame f0 by the GAME: +0x380 == 2 human, else CPU (roles-inverted swaps it)"""
    h = {d["f"]: d for d in T[k]}[f0][f"playing{s}"] == 2
    return (not h) if inv else h
nko = 0; vals10 = collections.Counter()
for k, ks in KOS.items():
    B = {d["f"]: d for d in T[k]}
    for w, l, f0 in ks:
        nko += 1
        vw, vl = B[f0][f"dblow{w}"], B[f0][f"dblow{l}"]
        vals10[vw] += 1
        cnt(f"dblow_{k}_f{f0}", f"KO winner P{w} ({'human' if role(k, w, f0) else 'CPU'}, char {B[f0].get(f'char{w}', '-')}) {vw}; loser P{l} {vl}")
        res(vl == 0, "C10", f"replay {k}: KO at f{f0}, winner P{w} ({'human' if role(k, w, f0) else 'CPU'}) +0x3B6 {vw}, the loser P{l}'s {vl}")
for k in ("03", "104"):
    o = OUT[k]; mx = {s: max(d[f"dblow{s}"] for d in T[k]) for s in (1, 2)}
    cnt(f"dblow_{k}", f"TIME both max {mx[1]}/{mx[2]}")
    res(o and o[3] == "TIME" and mx[1] == 0 and mx[2] == 0, "C10", f"replay {k}: time-over at f{o[2] if o else '-'} — +0x3B6 max P1 {mx[1]} P2 {mx[2]} over the whole leg")
res(nko >= 6 and len(vals10) >= 2, "C10", f"{nko} KOs judged, winners' values {dict(sorted(vals10.items()))} (nonzero sample, two values or more)")
# C10b THE ROLES AT EVERY KO, MEASURED TWICE (rule-checker runs 2026-10-08-903 and -905): C10's human/CPU label is the
# game's own +0x380 on the KO frame, and each side's label must agree, per leg, with two derivations from the replay's
# script that never read +0x380: (i) STARTED — a side can be human at a KO only if its own START (sys=S1 / sys=S2) was
# pressed at or before the KO and after that side's last KO loss before it, so a side never started, or not restarted
# after losing (128's P2 after f4791), must read CPU and a started one human; this decides IDLE sides too (02 and 05's
# P2, 26's P2, 128's P2 in its later matches); (ii) DRIVEN — a side the script drives during that match (any input entry
# between the match's first in-match frame and the KO) must read human. roles-inverted swaps the label and must fail
# C10b on EVERY KO leg, 05 included (by (i): its KO has no driven side).
def starts(rpl):
    out = {1: [], 2: []}
    for line in open(rpl):
        body = line.split("#")[0].strip()
        if not body:
            continue
        rng, *specs = body.split()
        a_ = int(rng.partition("-")[0])
        for sp in specs:
            m = re.match(r"^sys=(\S+)$", sp)
            if m:
                toks = [m.group(1)[i:i + 2] for i in range(0, len(m.group(1)), 2)]
                for s_ in (1, 2):
                    if f"S{s_}" in toks:
                        out[s_].append(a_)
    return out
n10b = 0; per10b = []
for k, ks in KOS.items():
    B = {d["f"]: d for d in T[k]}; st = starts(f"{REPO}/tests/replays/{RPL[k]}.rpl")
    lost = {1: [], 2: []}
    bad_k = 0; lines_k = []
    for w, l, f0 in sorted(ks, key=lambda x: x[2]):
        m0 = f0
        while m0 - 1 in B and inmatch(B[m0 - 1]):
            m0 -= 1
        drv = {s: any(S[k].get(f, {1: set(), 2: set()})[s] for f in range(m0, f0 + 1)) for s in (1, 2)}
        for s in (w, l):
            n10b += 1
            h = role(k, s, f0)
            last_loss = max(lost[s], default=-1)
            started = any(last_loss < f <= f0 for f in st[s])
            ok = (h == started) and (h or not drv[s])
            bad_k += not ok
            lines_k.append(f"{k}@{f0}:P{s}:{'human' if h else 'CPU'}/{'started' if started else 'not-started'}/{'driven' if drv[s] else 'idle'}")
        lost[w if inv else l].append(f0)   # the TRUE loser (kos() swaps winner and loser under roles-inverted)
    per10b += lines_k
    res(bad_k == 0, "C10b", f"replay {k}: at {len(ks)} KO(s) every side's +0x380 label equals its START derivation and every driven side reads human ({bad_k} violations): {' '.join(lines_k)}")
cnt("roles_at_ko", " ".join(per10b))
res(n10b > 0, "C10b", f"{n10b // 2} KOs over {len(KOS)} legs judged by both derivations")
# C11 +0x3B2 / +0x3E2 (consistent with mizuumi's "Auto-Guard Flag"): the side whose script, after its select confirm (its
# first button press), presses D twice then a button before the match starts CHOSE AUTO — that side's two bytes read 0
# before that button press and 1 on every frame from it through the last in-match frame (what follows the match is
# reported, not judged: 104 clears both at its game-over reset); every other side's read 0 throughout.
nch = 0
for k in ("104", "105auto", "02", "03", "05", "37", "selb1"):
    Tl = T[k]; m0 = next(d["f"] for d in Tl if inmatch(d)); m1 = max(d["f"] for d in Tl if inmatch(d))
    for s in (1, 2):
        pr = [(f, t) for f, t in rising(S[k], s, BTN | {"D"}) if f < m0]
        btn = [i for i, (f, t) in enumerate(pr) if set(t) & BTN]
        auto = None
        if btn:
            after = pr[btn[0] + 1:]
            nd = 0
            for f, t in after:
                if "D" in t: nd += 1
                if set(t) & BTN and nd >= 2: auto = f; break
        chose = auto is not None
        if inv: chose = not chose; auto = auto if auto else m0
        nz = [d["f"] for d in Tl if d[f"ag3b{s}"] or d[f"ag3e{s}"]]
        vals = {(d[f"ag3b{s}"], d[f"ag3e{s}"]) for d in Tl if (auto or 0) <= d["f"] <= m1} if chose else set()
        later = [d["f"] for a, d in zip(Tl, Tl[1:]) if d["f"] > m1 and (a[f"ag3b{s}"], a[f"ag3e{s}"]) != (d[f"ag3b{s}"], d[f"ag3e{s}"])]
        if chose:
            nch += 1
            pre = [d["f"] for d in Tl if d["f"] < auto and (d[f"ag3b{s}"] or d[f"ag3e{s}"])]
            ok = not pre and vals == {(1, 1)}
            cnt(f"auto_{k}_P{s}", f"chose AUTO at f{auto}: first nonzero f{nz[0] if nz else '-'}; values from the press to the match's end {sorted(vals)}; changes after it {later}")
        else:
            ok = not nz
            cnt(f"auto_{k}_P{s}", f"no AUTO: nonzero frames {len(nz)}")
        res(ok, "C11", f"replay {k} P{s}: {'chose AUTO (D,D,button) at f' + str(auto) if chose else 'did not choose AUTO'} — +0x3B2/+0x3E2 nonzero from f{nz[0] if nz else '-'} ({len(nz)} frames)")
res(nch >= 2, "C11", f"{nch} AUTO choosers judged (nonzero sample)")
# C12 +0x3E1 (consistent with mizuumi's "Character Palette"): the button K a side confirms its character with (its first
# button press in the script) gives +0x3E1 = K-1 on every in-match frame; p2-confirm judges each side against the OTHER
# side's confirm button, which must fail where the two differ (P1 confirms with 2..6 on 118_sel_b2..6, P2 with 1).
diff12 = 0
for k in ("selb1", "selb2", "selb3", "selb4", "selb5", "selb6", "03"):
    Tl = [d for d in T[k] if inmatch(d)]
    conf = {s: next((t for f, t in rising(S[k], s, BTN)), None) for s in (1, 2)}
    for s in (1, 2):
        K = conf[3 - s] if PERT == "p2-confirm" else conf[s]
        got = sorted({d[f"pal{s}"] for d in Tl})
        cnt(f"pal_{k}_P{s}", f"confirm {conf[s]} -> {got}")
        res(K is not None and len(K) == 1 and got == [int(K) - 1], "C12",
            f"replay {k} P{s}: confirm button {K}{' (the OTHER side, mode p2-confirm)' if PERT == 'p2-confirm' else ''} -> +0x3E1 {got} on {len(Tl)} in-match frames")
    diff12 += conf[1] != conf[2]
res(diff12 >= 5, "C12", f"{diff12} legs whose two confirm buttons differ (the p2-confirm control's reach)")
# C12b +0x3E1 on the AUTO legs (measured 14z-196, not in the 14z-194 row): the side that CHOSE AUTO (C11's derivation)
# reads 8 on every in-match frame — both such sides confirm with button 1, so whether AUTO adds 8 to K-1 or replaces it
# is not measured — and the other side reads its K-1 (p2-confirm judges each side against the other side's button)
AUTOS = {}
for k in ("104", "105auto"):
    Tl = T[k]; m0 = next(d["f"] for d in Tl if inmatch(d))
    for s in (1, 2):
        pr = [(f, t) for f, t in rising(S[k], s, BTN | {"D"}) if f < m0]
        btn = [i for i, (f, t) in enumerate(pr) if set(t) & BTN]
        nd = 0; auto = None
        for f, t in (pr[btn[0] + 1:] if btn else []):
            if "D" in t: nd += 1
            if set(t) & BTN and nd >= 2: auto = f; break
        AUTOS[(k, s)] = auto
    conf = {s: next((t for f, t in rising(S[k], s, BTN)), None) for s in (1, 2)}
    for s in (1, 2):
        if s not in HUMAN[k] and not inv:
            continue
        K = conf[3 - s] if PERT == "p2-confirm" else conf[s]
        want = 8 if (AUTOS[(k, s)] is not None) != inv else (int(K) - 1 if K else None)
        got = sorted({d[f"pal{s}"] for d in Tl if inmatch(d)})
        cnt(f"pal_{k}_P{s}", f"confirm {conf[s]} AUTO {'f' + str(AUTOS[(k, s)]) if AUTOS[(k, s)] else '-'} -> {got}")
        res(got == [want], "C12b", f"replay {k} P{s}: {'chose AUTO' if AUTOS[(k, s)] else 'no AUTO'}, confirm button {K} -> +0x3E1 {got} in match (wanted {want})")
# C13 +0x390 (consistent with mizuumi's "LONGWORD Player Score", 1P only): in the 1P replay 02, every rise of the human
# side's score lies within 3 frames of an OPPONENT hp drop (at least one rise), every value is BCD, and the CPU side's
# never rises; in the 2P replays 03 and 37 both sides read 1 on every in-match frame.
Tl = T["02"]
def drops(Tl, s): return [b["f"] for a, b in zip(Tl, Tl[1:]) if 0 <= b[f"hp{s}"] < a[f"hp{s}"]]
def bcd(v): return all(((v >> (4 * i)) & 0xf) <= 9 for i in range(8))
for s in (1, 2):
    up = [b["f"] for a, b in zip(Tl, Tl[1:]) if b[f"score{s}"] > a[f"score{s}"]]
    nearo = sum(1 for f in up if any(abs(f - g) <= 3 for g in drops(Tl, 3 - s)))
    allbcd = all(bcd(d[f"score{s}"] & 0xffffffff) for d in Tl)
    human = s in HUMAN["02"]
    cnt(f"score_02_P{s}", f"{'human' if human else 'CPU'} rises {len(up)} near an opponent hp drop {nearo} bcd {allbcd}")
    if human:
        res(up and nearo == len(up) and allbcd, "C13", f"replay 02 P{s} (human): {len(up)} score rises, {nearo} within 3 f of an opponent hp drop; all BCD {allbcd}")
    else:
        res(not up and allbcd, "C13", f"replay 02 P{s} (CPU): {len(up)} score rises")
for k in ("03", "37"):
    for s in (1, 2):
        v = sorted({d[f"score{s}"] for d in T[k] if inmatch(d)})
        cnt(f"score_{k}_P{s}", f"{v}")
        res(v == [1], "C13", f"replay {k} (2P) P{s}: in-match +0x390 values {v}")
# C14 THE ROLE-ATTRIBUTED WRITERS of the new fields, DERIVED per tapped leg (the C8b pattern): 0x019152 writes the KO
# WINNER's +0x3B6 exactly once per KO (C10's KOs, every tapped leg), on the KO frame, with the value the field reads there, and never the loser's nor at a
# time-over; 0x00A6A0's +0x3B0 writes are exactly C9's in-match 1->0 transitions (value 0) plus the KO loser's 0xFF frame;
# 0x020FB6 / 0x020FBA write each HUMAN side's +0x3B2 / +0x3E2 exactly once — 1 on the AUTO chooser, on its press frame,
# else 0 — and no CPU side's; 0x02101A writes each human side's +0x3E1 exactly once with its in-match value and no CPU
# side's. A write in tap frame f lands in trace frame f+1.
BASE = {1: 0xff8400, 2: 0xff8800}
TAPS = {"03": "tap03", "37": "tap37", "02": "tap02", "104": "tap104", "05": "tap05", "105auto": "tap105auto", "selb4": "tapselb4",
        "c128": "tapc128", "c26": "tapc26"}
FIELD2 = {0x3b0: "lbat", 0x3b2: "ag3b", 0x3b6: "dblow", 0x3e1: "pal", 0x3e2: "ag3e"}
def taps(t):
    out = collections.defaultdict(list)   # (side, fld) -> [(trace frame, pc, value)]
    for l in open(f"{W}/{t}.tap"):
        m = re.match(r"W (\d+) PC (\w+) off (\w+) data (\w+) mask (\w+)", l)
        if not m:
            continue
        f, pc, off, data, mask = int(m[1]), m[2], int(m[3], 16), int(m[4], 16), int(m[5], 16)
        for a, v, on in ((off & ~1, (data >> 8) & 0xff, mask & 0xff00), ((off & ~1) + 1, data & 0xff, mask & 0x00ff)):
            side = 1 if a < 0xff8800 else 2
            fld = FIELD2.get(a - BASE[side])
            if on and fld:
                out[(side, fld)].append((f + 1, pc, v))
    return out
miss14 = []
for k, t in TAPS.items():
    tw = taps(t)
    if not tw:
        res(False, "C14", f"{t}: no write to any new field — a dead tap")
        continue
    for (side, fld) in sorted(tw):
        byp = collections.defaultdict(list)
        for f, pc, v in tw[(side, fld)]:
            byp[pc].append(v)
        cnt(f"writers2_{t}_P{side}_{fld}", " ".join(f"{pc}:{len(v)}=" + "/".join(f"{x:02x}" for x in sorted(set(v))) for pc, v in sorted(byp.items())))
    def by(side, fld, pc): return [(f, v) for f, p, v in tw[(side, fld)] if p == pc]
    o = OUT.get(k)
    BB = {d["f"]: d for d in T[k]}
    for s in (1, 2):   # 0x019152: exactly one write per KO, on the KO frame, on the WINNER, with its +0x3B6 value there
        w019 = by(s, "dblow", "019152")
        want = [(f0, BB[f0][f"dblow{s}"]) for w, l, f0 in KOS.get(k, []) if w == s]
        if w019 != want: miss14.append(f"{k} P{s} 0x019152 {w019} wanted {want}")
    if k in OUT:
        for s in (1, 2):
            Tl = T[k]
            tr = sorted(b["f"] for a, b in zip(Tl, Tl[1:]) if a[f"lbat{s}"] == 1 and b[f"lbat{s}"] == 0 and inmatch(b))
            if o and o[3] == "KO" and s == o[1]:
                ff = next((d["f"] for d in Tl if d["f"] >= o[2] and d[f"lbat{s}"] == 0xff), None)
                tr = tr + ([ff] if ff is not None else [])
            wv = [(f, v) for f, v in by(s, "lbat", "00a6a0")]
            wantv = [(f, 0xff if (o and o[3] == "KO" and s == o[1] and f >= o[2]) else 0) for f in sorted(tr)]
            if wv != wantv: miss14.append(f"{k} P{s} 0x00A6A0 {wv} wanted {wantv}")
    for s in ((1, 2) if k in OUT or k == "selb4" else ()):   # the AUTO/palette writers: the single-match legs only
        human = s in HUMAN[k]
        auto = AUTOS.get((k, s))
        for fld, pc in (("ag3b", "020fb6"), ("ag3e", "020fba")):
            ws = by(s, fld, pc)
            want_ok = (len(ws) == 1 and ws[0][1] == (1 if auto else 0) and (not auto or ws[0][0] == auto)) if human else not ws
            if not want_ok: miss14.append(f"{k} P{s} {pc} {ws} ({'human' if human else 'CPU'}, AUTO {auto})")
        wp = by(s, "pal", "02101a")
        pal = sorted({d[f"pal{s}"] for d in T[k] if inmatch(d)}) if k in T else []
        want_ok = (len(wp) == 1 and [wp[0][1]] == pal) if human else not wp
        if not want_ok: miss14.append(f"{k} P{s} 0x02101A {wp} in-match {pal} ({'human' if human else 'CPU'})")
res(not miss14, "C14", f"the role-attributed writers of +0x3B6/+0x3B0/+0x3B2/+0x3E2/+0x3E1 sit on the derived side with the derived value on {len(TAPS)} tapped legs"
    + (f" — wrong: {'; '.join(miss14)}" if miss14 else ""))
open(out, "w").write("\n".join(counts) + "\n")
sys.exit(1 if bad else 0)
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
if vs_ctl_is poke-3b6; then
    check2 poke3b6 0 none "$W/got2.tsv" > "$W/pk3b6.log" 2>&1 || true
    cat "$W/pk3b6.log"
    if grep -q 'FAIL  \[C10\] replay 03:' "$W/pk3b6.log"; then echo "CONTROL FIRED: poke-3b6 — the gate ran on the +0x3B6 poke leg and C10 failed at 03's time-over"
    else vs_ctl_dead poke-3b6 "C10 did not fail on the poke leg" || true; fi
    echo "FAIL: audit_mizuumi_struct (control mode)"; exit 1
fi
if vs_ctl_is p2-confirm; then
    check2 03_two_player_vs 0 p2-confirm "$W/got2.tsv" > "$W/p2c.log" 2>&1 || true
    cat "$W/p2c.log"
    if grep -q 'FAIL  \[C12\]' "$W/p2c.log"; then echo "CONTROL FIRED: p2-confirm — the gate judged each side's +0x3E1 against the other side's confirm button and C12 failed"
    else vs_ctl_dead p2-confirm "C12 did not fail" || true; fi
    echo "FAIL: audit_mizuumi_struct (control mode)"; exit 1
fi
if vs_ctl_is roles-inverted; then
    if c8 1 > "$W/c8inv.log" 2>&1; then c8r=0; else c8r=1; fi
    check 0 03_two_player_vs "$W/inv02.tsv" 1 > "$W/inv02.log" 2>&1 || true
    check2 03_two_player_vs 1 none "$W/inv2.tsv" > "$W/inv2.log" 2>&1 || true
    cat "$W/c8inv.log" "$W/inv02.log" "$W/inv2.log"
    if [ "$c8r" = 0 ] || ! grep -q 'FAIL  \[C8b\]' "$W/c8inv.log" || ! grep -q 'FAIL  \[C4\]' "$W/inv02.log" \
       || ! grep -q 'FAIL  \[C9\]' "$W/inv2.log" || ! grep -q 'FAIL  \[C10\]' "$W/inv2.log" || ! grep -q 'FAIL  \[C11\]' "$W/inv2.log" \
       || ! grep -q 'FAIL  \[C14\]' "$W/inv2.log" || [ "$(grep -c 'FAIL  \[C10b\] replay ' "$W/inv2.log")" -lt 6 ]; then
        vs_ctl_dead roles-inverted "with the roles swapped C8 rc=$c8r and replay 02's C4 $(grep -q 'FAIL  \[C4\]' "$W/inv02.log" && echo failed || echo PASSED)" || true
    else
        echo "CONTROL FIRED: roles-inverted — the gate ran C8 and replay 02's checks with the roles swapped and they failed"
    fi
    echo "FAIL: audit_mizuumi_struct (control mode)"; exit 1
fi
c8 0 || fail=1
# C9-C14 (14z-196)
check2 03_two_player_vs 0 none "$W/got2.tsv" > "$W/checks2.log" 2>&1 || fail=1
cat "$W/checks2.log"
grep -q '\[C14\]' "$W/checks2.log" || { echo "  FAIL  check2 did not reach C14 (a crash is not a verdict): $(tail -1 "$W/checks2.log")"; fail=1; }
if c8 1 > "$W/c8inv.log" 2>&1; then c8r=0; else c8r=1; fi
check 0 03_two_player_vs "$W/inv02.tsv" 1 > "$W/inv02.log" 2>&1 || true
check2 03_two_player_vs 1 none "$W/inv2.tsv" > "$W/inv2.log" 2>&1 || true
if [ "$c8r" = 0 ] || ! grep -q 'FAIL  \[C8b\]' "$W/c8inv.log" || ! grep -q 'FAIL  \[C4\]' "$W/inv02.log" \
   || ! grep -q 'FAIL  \[C9\]' "$W/inv2.log" || ! grep -q 'FAIL  \[C10\]' "$W/inv2.log" || ! grep -q 'FAIL  \[C11\]' "$W/inv2.log" \
   || ! grep -q 'FAIL  \[C14\]' "$W/inv2.log" || [ "$(grep -c 'FAIL  \[C10b\] replay ' "$W/inv2.log")" -lt 6 ]; then
    vs_ctl_dead roles-inverted "with the roles swapped C8 rc=$c8r, replay 02's checks failed on: $(grep -o 'FAIL  \[C[0-9a-z]*\]' "$W/inv02.log" | tr '\n' ' '), C9-C14 failed on: $(grep -o 'FAIL  \[C[0-9a-z]*\]' "$W/inv2.log" | sort -u | tr '\n' ' ') — some role statement does not see which side is which" || fail=1
else
    vs_ctl_fired roles-inverted "$(grep -c 'FAIL  \[C8\]' "$W/c8inv.log") of 2 C8 rows, $(grep -c 'FAIL  \[C8b\]' "$W/c8inv.log") of 2 C8b rows, replay 02's C4, and C9 ($(grep -c 'FAIL  \[C9\]' "$W/inv2.log")), C10 ($(grep -c 'FAIL  \[C10\]' "$W/inv2.log")), C10b on $(grep -c 'FAIL  \[C10b\] replay ' "$W/inv2.log") of 6 KO legs, C11 ($(grep -c 'FAIL  \[C11\]' "$W/inv2.log")), C14 failed with the roles swapped"
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

python3 - "$W/poke3b6.fields" "$W/pokes3b6.txt" > "$W/pk3b6read.txt" <<'PY'
import sys
rng, addr, val = open(sys.argv[2]).read().strip().split(":")
lo, hi = map(int, rng.split("-")); side = 1 if addr == "ff87b6" else 2
got = {}
for l in open(sys.argv[1]):
    if l.startswith("F "):
        p = l.split(); f = int(p[1])
        if lo <= f <= hi:
            got[f] = int(dict(kv.split("=") for kv in p[2:])[f"dblow{side}"])
print(sum(1 for f in range(lo, hi + 1) if got.get(f) == int(val, 16)), hi - lo + 1)
PY
read -r pk3_ok pk3_n < "$W/pk3b6read.txt"
printf 'poke_3b6_readback\t%s/%s\n' "$pk3_ok" "$pk3_n" >> "$W/got2.tsv"
check2 poke3b6 0 none "$W/pk3b6.tsv" > "$W/pk3b6.log" 2>&1 || true
if grep -q 'FAIL  \[C10\] replay 03:' "$W/pk3b6.log" && [ "$pk3_ok" = "$pk3_n" ] && [ "$pk3_n" -gt 0 ]; then
    vs_ctl_fired poke-3b6 "C10 failed at 03's time-over on the poke leg ($(grep 'FAIL  \[C10\] replay 03:' "$W/pk3b6.log" | sed 's/^ *//' | cut -c1-110)), +0x3B6 read the poked 0x5A back on $pk3_ok of $pk3_n frames"
else
    vs_ctl_dead poke-3b6 "C10 did not fail on the poke leg, or the poke did not read back ($pk3_ok/$pk3_n)" || fail=1
fi
check2 03_two_player_vs 0 p2-confirm "$W/p2c.tsv" > "$W/p2c.log" 2>&1 || true
if grep -q 'FAIL  \[C12\]' "$W/p2c.log"; then
    vs_ctl_fired p2-confirm "$(grep -c 'FAIL  \[C12\]' "$W/p2c.log") C12 rows failed with each side judged against the other side's confirm button"
else
    vs_ctl_dead p2-confirm "C12 passed against the other side's confirm button — the check does not see which button confirmed" || fail=1
fi
cat "$W/got2.tsv" >> "$W/got.tsv"

echo "== 4. the frozen counts"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_struct (not frozen: fix the red first)"; exit 1; }
    { echo "# tests/expected/mizuumi_struct.tsv — the counts tests/audit_mizuumi_struct.sh measured on pristine vsavj (GitHub #118)."
      echo "# Evidence class: in-emulator. Frozen 14z-189 with FREEZE=1, re-frozen 14z-196 with C9-C14 appended (HOMING item 4); counts, value sets and writer PCs only, no ROM bytes."
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1)"; exit 1; }
if grep -v '^#' "$EXPECT" | diff - "$W/got.tsv" > "$W/diff.txt"; then echo "  ok    every count as frozen"
else echo "  FAIL  the counts moved:"; sed 's/^/        /' "$W/diff.txt"; fail=1; fi
if [ "$fail" = 0 ]; then echo "PASS: audit_mizuumi_struct"; else echo "FAIL: audit_mizuumi_struct"; exit 1; fi
