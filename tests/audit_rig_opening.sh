#!/bin/sh
# audit_rig_opening.sh — THE NAMING RIGS' OPENING: the two legs draw DIFFERENT
# round-start entrances, and the rig no longer samples across the difference
# (14z-167, rewritten 14z-172 for GitHub #168).
#
# WHAT: the naming rigs' opening: the two legs draw DIFFERENT round-start entrances (native
#   behaviour on two games), and the rig is clear of the difference — every part's first
#   position pin lands after the round start and from that pin on the legs agree at every
#   sample frame, the first event included.
# HOW: two field-trace runs in parallel on MAME (huitzil_5 on both legs), the round-start
#   frame read from $FF812D on both, every part's first pin read from its committed schedule
#   JSON, a pre-pin sample that must differ, post-pin x and seq that must agree (the pin
#   frame itself excluded — x is the poked field), and a sample carrying an x the pin never
#   wrote; controls swap in native's opening rows and regenerate the rig with the
#   round-start floor removed.
# EXPECTS: the frozen rows equal, the pins after 2545, legs differing pre-pin and agreeing
#   after; the swapped opening fails, the floor-less rig pins at 2370 and fails.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/rig_opening.tsv
#   tests/lua/field_trace.lua tests/replays/ tools/name_moves.py tools/run_mame.sh
#   tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: entrance-swapped — a copy of our opening rows carrying native's x and seq (what the two legs would read if they drew the SAME entrance) must FAIL the frozen compare, so the frozen entrance rows are a real difference and not a tautology (in-gate: the perturbed copy must differ from the frozen rows; mode: our rows are replaced before the compare and the table FAILs)
# MUST-FIRE: perturbed-copy: pin-before-round — the rig regenerated from a copy of tools/name_moves.py with its round-start floor removed (ROUND_START = 0, i.e. the pre-#168 schedule) pins at 2370, before the round starts, and must FAIL section 2's pin assertion AND its convergence assertion (in-gate: the perturbed generator's first pin must be < the round start; mode: the gate runs on that rig and FAILs)
#
# WHY. tests/expected/move_parity_events.tsv froze ten rows as DIFF at +0 on x
# with no move involved — the #136 ENTRANCE class. Measured 14z-167
# (docs/game/engine_internals.md "The round-start ENTRANCE and the round start"):
# seven naming parts pinned both fighters' X at 2370, but the round starts at 2545
# ($FF812D), so the pin landed inside the entrance; native drew the car arrival
# (Phobos carried from x=360 to 702), ours the arrival with Cecil in hand (held at
# 552 until 2481), and the legs met the first event 117 px apart. The maintainer
# identified the two entrances on the capture before any conclusion
# (build/x_family_14z167/cap/huitzil_5_opening_sheet.png).
#
# WHAT IT CLAIMS, and what it does NOT. It does NOT claim the legs agree through
# the entrance — they do not, and that is native behaviour on two different games.
# It claims the rig is clear of the difference: the first position pin lands after
# the round start, and from that pin on the two legs agree at every sample frame,
# so no event is ever sampled across a differing entrance. The pre-round-start rows
# are frozen as MEASURED, so the difference cannot silently change shape either.
#
# WHAT IT ASSERTS
#   1. both legs report the SAME round-start frame, and it equals the frozen one;
#   2. the first position pin of EVERY naming part that has one (read from the
#      committed schedule JSON, never a literal) is >= that frame;
#   3. the legs DIFFER at a pre-pin sample — without which 4 would be vacuous;
#   4. AFTER the first pin — not AT it — the legs agree on x and seq at every sample
#      frame, the first event included;
#   5. at least one of those samples carries an x the pin never wrote. x IS THE FIELD
#      THE RIG POKES ($FF8410/$FF8810 from the schedule's own list, handed to BOTH legs),
#      so an agreement at the pin frame is the poke echoing twice and a defect in the pin
#      would make the legs AGREE; the pin frame is excluded from 4 and reported instead
#      (rule-checker run 2026-09-20-86 Q3, which found 2565 inside the assertion);
#   6. every row equals tests/expected/rig_opening.tsv.
#
# A field_trace.lua trace carries NO END line (unlike read_tap.lua's logs), so this
# gate's reduction refuses a missing sample frame and asserts the emulator's exit
# status instead of an END check (rule-checker run 2026-09-18-43 Q1).
#
# Usage: ROMDIR=... [MAME_BIN=~/.cache/vampire-saved/mame/cps2] [BUILD=build/m3b_merged27] [FREEZE=1] tests/audit_rig_opening.sh
#   emulator tier, MAME; two field_trace runs in parallel — measured 14z-172 on this MacBook, solo: ~5 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/rig_opening.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|entrance-swapped|pin-before-round) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
PART=huitzil_5; TENANT=huitzil; PARTNO=5; FR=2800
SAMPLES="2363 2370 2395 2481 2544 2560 2565 2600 2795"
# --- the rig as tests/audit_move_parity.sh builds it (pokes_for / rpl_for / OURS_PATH, copied) ---
OURS_PATH_huitzil="D D D"
pokes_for() {  # pokes_for <json> <frames>
    _b="$(python3 -c "import json;print(';'.join(json.load(open('$1'))['pokes']))")"
    _l="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$2)))")"
    _r="$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$2)))")"
    printf '%s;%s;%s' "$_b" "$_l" "$_r"
}
rpl_for() {  # rpl_for <tenant> <rig.rpl> <leg> <out.rpl>
    if [ "$3" = native ]; then cp "$2" "$4"; return; fi
    eval "_path=\$OURS_PATH_$1"
    awk -v path="$_path" '
        /^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
        { print }' "$2" > "$4"
}
first_pin() {  # first_pin <schedule.json> -> the earliest ff8410/ff8810 poke frame, or nothing
    python3 -c "
import json, sys
p = [int(x.split(':')[0]) for x in json.load(open(sys.argv[1]))['pokes'] if x.split(':')[1] in ('ff8410', 'ff8810')]
print(min(p) if p else '')" "$1"
}
sample() {  # sample <leg> <set> <rompath> <rpl> <pokes>   (background)
    mkdir -p "$W/$1"
    # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log (docs/platform/gotchas.md):
    # `set +e` keeps the status write alive, and a run whose instrument wrote its summary line counts as
    # completed (docs/project/gotchas.md, the set -e capture entry)
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$FR" \
        FIELDS="ff8410:w:x,ff8406:b:seq,ff812d:b:rnd,ff8782:b:id" FIELD_OUT="$W/$1.tr" FIELD_FROM=2300 FIELD_TO="$FR" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$1/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$W/$1.tr" 2>/dev/null && _st=0; echo $_st > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
reduce() {  # reduce <leg> <trace> <samples> -> rows
    python3 - "$1" "$2" "$3" <<'PY'
import sys
leg, p, samples = sys.argv[1], sys.argv[2], [int(x) for x in sys.argv[3].split()]
d = {}
for l in open(p):
    t = l.split()
    if t and t[0] == "F": d[int(t[1])] = dict(kv.split("=", 1) for kv in t[2:])
if not d: sys.exit(f"VOID: {p} has no samples")
if d[min(d)].get("id") != "16": sys.exit(f"VOID: {leg} P1 id is {d[min(d)].get('id')} at {min(d)}, not Phobos (16)")
start = next((f for f in sorted(d) if d[f].get("rnd") == "1"), None)
if start is None: sys.exit(f"VOID: {leg} never reports a round start ($FF812D = 1)")
print(f"start\t{leg}\t{start}")
for f in samples:
    if f not in d: sys.exit(f"VOID: {leg} has no sample at {f}")
    print(f"at\t{leg}\t{f}\tx={d[f]['x']}\tseq={d[f]['seq']}")
PY
}
swap_entrance() {  # swap_entrance <native rows> <ours rows>: ours' at-rows carry native's x and seq
    python3 - "$1" "$2" <<'PY'
import sys
nat = {l.split("\t")[2]: l.rstrip("\n").split("\t")[3:] for l in open(sys.argv[1]) if l.startswith("at\t")}
for l in open(sys.argv[2]):
    t = l.rstrip("\n").split("\t")
    if t[0] == "at" and t[2] in nat: t[3:] = nat[t[2]]
    print("\t".join(t))
PY
}

echo "== 1. the opening, both legs ($PART, frames 2300-$FR)"
j="$REPO/tests/replays/naming/$PART.json"; r="$REPO/tests/replays/naming/$PART.rpl"
if [ "$CONTROL" = pin-before-round ]; then
    # the PRE-#168 schedule, from a perturbed copy of the generator: with the
    # round-start floor removed the shift is zero and the first pin returns to 2370
    sed 's/^ROUND_START = 2545/ROUND_START = 0/' "$REPO/tools/name_moves.py" > "$W/nm_ctl.py"
    python3 "$W/nm_ctl.py" gen "$TENANT" "$PARTNO" "$W/ctl.rpl" "$W/ctl.json" > /dev/null
    j="$W/ctl.json"; r="$W/ctl.rpl"
    echo "  control pin-before-round: the rig regenerated with no round-start floor, first pin $(first_pin "$j")"
fi
pk="$(pokes_for "$j" "$FR")"
rpl_for "$TENANT" "$r" native "$W/native.rpl"; rpl_for "$TENANT" "$r" ours "$W/ours.rpl"
sample native vsav2  "$ROMDIR" "$W/native.rpl" "$pk"
sample ours   vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" "$pk"
wait
for leg in native ours; do
    _rc="$(cat "$W/$leg/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$leg: the emulator exited $_rc"
    reduce "$leg" "$W/$leg.tr" "$SAMPLES" > "$W/$leg.rows" 2> "$W/$leg.err" || bad "$leg: $(cat "$W/$leg.err")"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_rig_opening (a leg did not run or was VOID)"; exit 1; }
if [ "$CONTROL" = entrance-swapped ]; then swap_entrance "$W/native.rows" "$W/ours.rows" > "$W/ours.sw" && mv "$W/ours.sw" "$W/ours.rows"; fi
cat "$W/native.rows" "$W/ours.rows" > "$W/got.tsv"
sed 's/^/  /' "$W/got.tsv"

echo "== 2. the round start, the pins, and the convergence"
RS_N="$(awk -F'\t' '$1=="start" && $2=="native" {print $3}' "$W/native.rows")"
RS_O="$(awk -F'\t' '$1=="start" && $2=="ours" {print $3}' "$W/ours.rows")"
if [ "$RS_N" = "$RS_O" ]; then ok "2.1 both legs report the round start at $RS_N"
else bad "2.1 the legs report DIFFERENT round starts (native $RS_N, ours $RS_O) — the frame is the round intro's property, so this is a rig or instrument fault"; fi
RS="$RS_N"

# 2.2 every naming part's first pin, from its committed schedule
npins=0; badpins=""
for _f in "$REPO"/tests/replays/naming/*.json; do
    _p="$(basename "$_f" .json)"
    _fp="$([ "$CONTROL" = pin-before-round ] && [ "$_p" = "$PART" ] && first_pin "$j" || first_pin "$_f")"
    [ -n "$_fp" ] || continue
    npins=$((npins + 1))
    [ "$_fp" -ge "$RS" ] || badpins="$badpins $_p@$_fp"
done
if [ -z "$badpins" ]; then ok "2.2 all $npins naming parts with a position pin place their first one at or after $RS"
else bad "2.2 position pins land BEFORE the round start ($RS):$badpins — a pin inside the entrance writes X while the two games draw different arrivals"; fi

# 2.3/2.4 the entrance differs, and the legs agree from the first pin on
PIN="$(first_pin "$j")"
# the X VALUES the pin writes, from the schedule itself — the convergence assertion must
# not rest on a sample whose value the rig poked (rule-checker 2026-09-20-86 Q3)
POKED="$(python3 -c "
import json, sys
print(','.join(sorted({str(int(x.split(':')[2], 16)) for x in json.load(open(sys.argv[1]))['pokes'] if x.split(':')[1] in ('ff8410', 'ff8810')})))" "$j")"
python3 - "$W/native.rows" "$W/ours.rows" "$PIN" "$POKED" > "$W/conv.txt" <<'PY' 2>&1 || true
import sys
def rows(p):
    d = {}
    for l in open(p):
        t = l.rstrip("\n").split("\t")
        if t[0] == "at": d[int(t[2])] = (t[3], t[4])
    return d
n, o, pin, poked = rows(sys.argv[1]), rows(sys.argv[2]), int(sys.argv[3]), sys.argv[4].split(",")
pre  = sorted(f for f in n if f < pin)
# THE PIN FRAME IS NOT EVIDENCE OF CONVERGENCE: x is the field the pin WRITES, so at
# that frame both legs necessarily read the poked value and a defect in the pin would
# make them agree (rule-checker run 2026-09-20-86 Q3). The assertion runs on the samples
# AFTER it, and at least one of those must carry an x the pin did not write.
post = sorted(f for f in n if f > pin)
dif_pre  = [f for f in pre  if n[f] != o[f]]
dif_post = [f for f in post if n[f] != o[f]]
free = [f for f in post if n[f][0].split("=", 1)[1] not in poked]
print(f"PRE {len(pre)} {len(dif_pre)} " + ",".join(str(f) for f in dif_pre))
print(f"POST {len(post)} {len(dif_post)} " + ",".join(str(f) for f in dif_post))
print(f"FREE {len(free)} " + ",".join(f"{f}:{n[f][0]}" for f in free))
if pin in n:
    print(f"PINFRAME {pin} {n[pin][0]} {o[pin][0]} {int(n[pin] == o[pin])}")
for f in dif_post:
    print(f"  {f}: native {n[f][0]} {n[f][1]} / ours {o[f][0]} {o[f][1]}")
PY
_npre="$(awk '$1=="PRE"{print $2}' "$W/conv.txt")"; _dpre="$(awk '$1=="PRE"{print $3}' "$W/conv.txt")"
_npost="$(awk '$1=="POST"{print $2}' "$W/conv.txt")"; _dpost="$(awk '$1=="POST"{print $3}' "$W/conv.txt")"
if [ "${_dpre:-0}" -gt 0 ]; then ok "2.3 the legs DIFFER at $_dpre of $_npre samples before the pin ($(awk '$1=="PRE"{print $4}' "$W/conv.txt")) — the entrance difference is live, so 2.4 is not vacuous"
else bad "2.3 the legs agree at every pre-pin sample — the entrance difference this gate exists to bound is not present, so its convergence assertion proves nothing"; fi
_nfree="$(awk '$1=="FREE"{print $2}' "$W/conv.txt")"; _free="$(awk '$1=="FREE"{print $3}' "$W/conv.txt")"
_pinf="$(sed -n 's/^PINFRAME //p' "$W/conv.txt")"
if [ "${_dpost:-1}" = 0 ]; then ok "2.4 AFTER the first pin ($PIN) the legs agree on x and seq at all $_npost samples, the first event (2795) included"
else bad "2.4 the legs still differ at $_dpost of $_npost samples after the pin:"; sed -n '/^  /p' "$W/conv.txt" | head -7 | sed 's/^/        /'; fi
# 2.5 x IS A POKED FIELD (the rig writes ff8410/ff8810), so an agreement at the pin frame
# is the poke echoing on both legs, not convergence. The pin frame is excluded from 2.4
# above and reported here, and at least one post-pin sample must carry an x the pin never
# wrote — otherwise 2.4 could pass on a rig whose pin writes the same wrong value twice.
if [ "${_nfree:-0}" -gt 0 ]; then ok "2.5 $_nfree of $_npost post-pin samples carry an x the pin never wrote ($_free; poked values $POKED), so 2.4 is not the poke echoing — the pin frame itself ($_pinf: native/ours/equal) is excluded from it"
else bad "2.5 every post-pin sample reads an x the pin WROTE (poked values $POKED) — 2.4 would then hold on any rig whose pin lands, including one writing the same wrong value to both legs, so it is evidence of nothing (rule-checker 2026-09-20-86 Q3)"; fi

echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/rig_opening.tsv — the naming rigs' opening (huitzil_5), ours (merged-m19) vs native vsav2"
        echo "# (tests/audit_rig_opening.sh; tests/lua/field_trace.lua). Evidence class: in-emulator. Re-frozen 14z-172 with FREEZE=1."
        echo "# WHAT THESE ROWS RECORD: the two games draw DIFFERENT round-start entrances (native the car arrival, ours the arrival"
        echo "# with Cecil in hand) and CONVERGE once the rig's first position pin lands, which is after the round start (#168)."
        echo "# The pre-pin rows are the entrance DIFFERENCE, frozen as measured; the rows from the pin on are the convergence."
        echo "# Columns: start <leg> <first frame \$FF812D = 1> | at <leg> <frame> x= seq="
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "3 every row as frozen"
else bad "3 differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi

echo "== 4. must-fire controls"
if [ -n "$CONTROL" ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $CONTROL — the perturbed input reached the gate's own FAIL"; echo "FAIL: audit_rig_opening (control mode)"; exit 1
    else echo "CONTROL DEAD: $CONTROL — the perturbation left every assertion green"; echo "FAIL: audit_rig_opening"; exit 1; fi
fi
swap_entrance "$W/native.rows" "$W/ours.rows" > "$W/ctl.rows"
if diff -q "$W/ours.rows" "$W/ctl.rows" > /dev/null; then echo "CONTROL DEAD: entrance-swapped — native's opening equals ours, nothing to discriminate"; fail=1
else _n="$(diff "$W/ours.rows" "$W/ctl.rows" | grep -c '^>')"; echo "CONTROL FIRED: entrance-swapped — our opening with native's x and seq differs from the frozen rows ($(echo "$_n" | tr -d ' ') rows)"; fi
sed 's/^ROUND_START = 2545/ROUND_START = 0/' "$REPO/tools/name_moves.py" > "$W/nm_ctl.py"
python3 "$W/nm_ctl.py" gen "$TENANT" "$PARTNO" "$W/ctl2.rpl" "$W/ctl2.json" > /dev/null
_cp="$(first_pin "$W/ctl2.json")"
if [ "$_cp" -lt "$RS" ]; then echo "CONTROL FIRED: pin-before-round — the generator with no round-start floor pins at $_cp, before the round start ($RS), which assertion 2.2 refuses"
else echo "CONTROL DEAD: pin-before-round — the unfloored generator still pins at $_cp, at or after $RS"; fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_rig_opening"; else echo "FAIL: audit_rig_opening"; exit 1; fi
