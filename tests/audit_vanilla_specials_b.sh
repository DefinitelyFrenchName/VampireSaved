#!/bin/sh
# audit_vanilla_specials_b.sh — WHICH CHAIN EACH VANILLA SPECIAL ENTERS ON vsavj, AND ITS TIMING IN EXACT ENGINE PASSES,
# for Lei-Lei, Lilith, Morrigan, Q-Bee, Sasquatch, Victor and Zabel (GitHub #229, 14z-205, fork F2; registered 14z-209:
# emulator tier, MAME lane, scope ondemand — pristine vsavj only).
#
# WHAT: the community workbook's 80 motion-special, special-projectile and movement-special rows of LE LI MO QB SA VI
#   ZA, each performed on pristine vsavj: the anim chain the engine entered (the name the cross-check joins by), and the
#   move's startup / active / recovery counted in ENGINE PASSES from a tick-accurate tap.
# HOW: tools/specials_b_rigs.py performs each row's input at a wide pin (P2 Victor idle). The legs run
#   tests/lua/specials_b_trace.lua with -debug: P1's fields per EMULATED frame (identity: the node pointer +0x1C labelled
#   by the walker's rule, the anim tables read with SIGNED offsets, the window opened at the row's first button) and a
#   write tap on the pass counter $FF8081, P1's node timer +0x20 and four projectile slots' (timing: every node entry
#   gets an exact pass index; holds included). TWO legs per character: the identity from an INSTR_REFERENCE leg (no
#   debugger), the timing from the -debug tap leg (section 2 says why). Every leg is on the #228 option-A alignment (tests/lib/instr_align.sh):
#   held to its FROZEN game clock (tests/expected/instr_gameclock/audit_vanilla_specials_b.tsv), one staging reference
#   leg held to replay.lua run live on every run.
# EXPECTS: the rigs regenerate byte-identically; every leg on emulated time at its frozen game clock and the staging
#   leg reproduces replay.lua; every row fires a special chain (none UNFIRED, none DEGRADED); the identity map equals
#   tests/expected/vanilla_specials_b.tsv; the timing table's SHA-256 equals tests/expected/vanilla_specials_b_ticks.sha256
#   (the values stay out of the tree: the frame-data rule); the controls below fail.
# FOLLOWS: tools/specials_b_rigs.py tools/name_moves.py tools/vanilla_frames.py tools/anim_nodes.py
#   build/manifest/bank_map.toml tests/expected/vanilla_specials_b.tsv tests/expected/vanilla_specials_b_ticks.sha256
#   tests/expected/instr_gameclock/ tests/lib/instr_align.sh tests/lib/controls.sh tests/lib/decrypt_cache.sh
#   tests/lua/specials_b_trace.lua tests/lua/emu_clock.lua tests/lua/pokes_spec.lua tests/lua/replay.lua tools/run_mame.sh
#   tests/lib/pristine_vsavj.sh tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py tools/cps2_decrypt.py tests/expected/registry.tsv tests/lib/mame_ident.sh tools/setup_mame.sh tools/run_mame.sh
#   emu/mame-patches/
#
# SHEET: none — measures pristine vsavj only; no leg of our build.
#
# MUST-FIRE: perturbed-copy: swapped-strengths — swapping Lei-Lei's LP and HP Ankihou chains in a copy of the frozen map must fail the section-4 compare (mode: section 4 compares the measured map against that swapped copy and must fail)
# MUST-FIRE: known-bad: unsigned-offsets — the anim index tables read with UNSIGNED offsets (tools/anim_nodes.py's reading) must lose Sasquatch's Big Breath and Big Blow, whose a2 entries are negative (mode: the whole analysis reads unsigned and the gate fails)
# MUST-FIRE: known-bad: window-at-event — the event window opened at the event's first frame instead of its first button must read Zabel's ground Death Hurricane as the motion's a:0x29 (mode: the whole analysis opens there and the gate fails)
# MUST-FIRE: known-bad: p1-clock — the timing counted on P1's own tick-writes instead of the pass counter (the walker skips passes on holds) must change the timing table's hash (mode: the whole timing reads that clock and the gate fails)
# MUST-FIRE: known-bad: drift-clock — a tap leg under the OLD frame_done clock (INSTR_CLOCK=frame_done) must miss its frozen game clock (in-gate: one extra run; mode: every tap leg runs the old clock and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: foreign-image — an image one byte off vsavj's data view must fail the provenance check (tests/lib/pristine_vsavj.sh; in-gate; mode: the check is handed that image and the gate FAILs)
# MUST-FIRE: known-bad: foreign-romset — a ROMDIR whose vsavj.zip is vsav2.zip must fail the provenance check (in-gate; mode: the check audits that ROMDIR and the gate FAILs)
# MUST-FIRE: known-bad: foreign-rompath — MAME_ROMPATH pointed away from the audited ROMDIR must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# MUST-FIRE: known-bad: foreign-mame — a MAME_BIN that is not the pin's release must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
#
# Usage: ROMDIR=... tests/audit_vanilla_specials_b.sh        # emulator tier (MAME, 2 at a time)
#        FREEZE=1 re-freezes the map, the timing hash and the game clocks (reference legs + replay.lua); KEEP=dir keeps
#        the traces and the timing table (KEEP/ticks.tsv — per-move values: keep it out of the tree).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
EXP=tests/expected/vanilla_specials_b.tsv
TEXP=tests/expected/vanilla_specials_b_ticks.sha256
CLOCKS=tests/expected/instr_gameclock/audit_vanilla_specials_b.tsv
INSTR="$REPO/tests/lua/specials_b_trace.lua"
IMG="${IMG:-build/out/vsavj_data.bin}"
JOBS=2
W="$(mktemp -d)"
if [ -n "${KEEP:-}" ]; then mkdir -p "$KEEP"; trap 'cp -R "$W"/. "$KEEP"/ 2>/dev/null; rm -rf "$W"' EXIT; else trap 'rm -rf "$W"' EXIT; fi
bad=0
ok()  { echo "  ok    $1"; }
nope() { echo "  FAIL  $1"; bad=$((bad + 1)); }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
[ "$MODE" = unsigned-offsets ] && export SPECIALS_UNSIGNED=1
[ "$MODE" = window-at-event ] && export SPECIALS_WINDOW=event
[ "$MODE" = p1-clock ] && export TICKS_CLOCK=p1
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"

# ONE perturbation, used by the section-6 control and by the executable mode: LE's LP and HP Ankihou chains swapped.
swap_strengths() {  # swap_strengths <in> <out>
    awk -F'\t' 'BEGIN{OFS="\t"} $1=="LE" && $2=="LP ANKIHOU"{lp=$0} $1=="LE" && $2=="HP ANKIHOU"{hp=$0} {rows[NR]=$0} END{
        split(lp, a, "\t"); split(hp, b, "\t");
        for (i = 1; i <= NR; i++) { r = rows[i]; n = split(r, f, "\t");
            if (f[1] == "LE" && f[2] == "LP ANKIHOU") f[4] = b[4]; else if (f[1] == "LE" && f[2] == "HP ANKIHOU") f[4] = a[4];
            o = f[1]; for (j = 2; j <= n; j++) o = o OFS f[j]; print o } }' "$1" > "$2"
}

[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset"; exit 0; }
if [ ! -f "$IMG" ]; then
    . "$REPO/tests/lib/decrypt_cache.sh"
    decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 \
        || { echo "SKIP: no vsavj data view and the cache could not fill it"; exit 0; }
    IMG="$W/vsavj_data.bin"
fi
# WHICH ROM AND WHICH IMAGE (14z-209, rule-checker run 2026-10-25-1294 Q1/Q4): tests/lib/pristine_vsavj.sh.
. "$REPO/tests/lib/pristine_vsavj.sh"
vs_pristine_vsavj "$W/pv" "$IMG" || { echo "FAIL: audit_vanilla_specials_b (the ROM or the analysed image is not pristine vsavj)"; exit 1; }
if [ -z "$MODE" ]; then vs_pristine_vsavj_controls "$W/pv" || { echo "FAIL: audit_vanilla_specials_b (a provenance control is dead)"; exit 1; }; fi
ALL="LE LI MO QB SA VI ZA"
FIELDS="$(python3 tools/specials_b_rigs.py fields)"

echo "== audit_vanilla_specials_b: the vanilla specials' chains and timing (LE LI MO QB SA VI ZA), measured on vsavj =="
echo "== 1. the rigs regenerate byte-identically"
for t in $ALL; do
    python3 tools/specials_b_rigs.py gen "$t" whiff "$W/$t.rpl" "$W/$t.json" >/dev/null || nope "gen $t"
    python3 tools/specials_b_rigs.py gen "$t" whiff "$W/re.rpl" "$W/re.json" >/dev/null
    cmp -s "$W/$t.rpl" "$W/re.rpl" && cmp -s "$W/$t.json" "$W/re.json" || nope "rig $t is not a pure function of its inputs"
done
[ "$bad" = 0 ] && ok "every rig is a pure function of its character"

echo "== 2. the legs: per character an IDENTITY leg (no debugger) and a TAP leg (-debug, armed at 2400), $JOBS at a time"
# THE TWO LEGS (measured 14z-205 on Q-Bee's rig): the TAP leg's game stays on replay.lua's timeline — its pass counter
# equals the identity leg's on every frame, section 3 asserts it — but a stop can land as the screen frame number moves,
# so 123 of its 5,590 per-frame samples were read mid-pass (one node behind); its samples are never the identity. The
# identity is the INSTR_REFERENCE leg's (no stops); the timing is the tap's ordered stream (every node entry, exact).
n=0
leg() {   # leg <tab> <kind: id|tap>
    _L="$W/legs/$1/$2"; mkdir -p "$_L"
    _P="$(python3 -c "import json;print(';'.join(json.load(open('$W/$1.json'))['pokes']))")"
    _F="$(python3 -c "import json;print(json.load(open('$W/$1.json'))['frames'])")"
    if [ "$2" = tap ]; then _x="-debug -debugger none"; _r=""; else _x=""; _r="INSTR_REFERENCE=1"; fi
    # shellcheck disable=SC2086
    ( cd "$_L" && env $_clk $_r TAP_FROM=2400 POKES="$_P" FIELDS="$FIELDS" FIELD_OUT="$_L/t.txt" TRACE_OUT="$_L/tap.txt" \
        REPLAY="$W/$1.rpl" FRAMES="$_F" ALIGN_OUT="$_L/align" MAME_SANDBOX="$_L/sb" timeout 900 "$REPO/tools/run_mame.sh" \
        vsavj $_x -autoboot_script "$INSTR" > run.log 2>&1; rm -rf "$_L/sb" ) </dev/null
}
for t in $ALL; do
    for k in id tap; do
        leg "$t" "$k" &
        n=$((n + 1)); [ $((n % JOBS)) -eq 0 ] && wait
    done
done
wait
: > "$W/manifest.tsv"
for t in $ALL; do
    _P="$(python3 -c "import json;print(';'.join(json.load(open('$W/$t.json'))['pokes']))")"
    ia_note_run "$W/manifest.tsv" tap "${t}_whiff" vsavj - "$W/$t.rpl" "POKES=$_P FIELDS=$FIELDS TAP_FROM=2400" "$W/legs/$t/tap/align"
done
ok "$n legs ran"

echo "== 3. the alignment (#228 option A)"
if [ "${FREEZE:-0}" = 1 ]; then
    if ia_freeze "$INSTR" "$W/manifest.tsv" "$W/fz" "$JOBS" "$W/clocks.tsv" > "$W/freeze_bad.txt"; then
        mkdir -p "$(dirname "$CLOCKS")"
        { echo "# tests/expected/instr_gameclock/audit_vanilla_specials_b.tsv — the game clock RAM:\$FF8080 at each tap leg's last"
          echo "# frame (#228 option A), taken from REFERENCE legs (the instrument, no -debug) each held to replay.lua run live."
          echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
          cat "$W/clocks.tsv"; } > "$CLOCKS"
        echo "  FROZE $CLOCKS ($(grep -vc '^#' "$CLOCKS") rows)"
    else nope "the clock freeze refused:"; sed 's/^/        /' "$W/freeze_bad.txt"; fi
fi
if ia_check_manifest "$CLOCKS" "$W/manifest.tsv" > "$W/align_bad.txt"; then ok "every tap leg on emulated time, at its frozen game clock"
else nope "the alignment:"; sed 's/^/        /' "$W/align_bad.txt"; fi
ia_stage audit_vanilla_specials_b "$CLOCKS" "$INSTR" "$W/manifest.tsv" 1 "$W/st" "$MODE" || bad=$((bad + 1))
: > "$W/idalign_bad.txt"
for t in $ALL; do ia_check "$CLOCKS" tap "${t}_whiff" "$W/legs/$t/id/align" >> "$W/idalign_bad.txt" || true; done
if [ -s "$W/idalign_bad.txt" ]; then nope "the identity legs' alignment:"; sed 's/^/        /' "$W/idalign_bad.txt"
else ok "every identity leg on emulated time, at its frozen game clock"; fi
if python3 tools/specials_b_rigs.py passeq "$W/legs" $ALL > "$W/passeq.txt"; then ok "$(cat "$W/passeq.txt")"
else nope "$(cat "$W/passeq.txt")"; fi

echo "== 4. the identity map"
: > "$W/got.txt"
for t in $ALL; do
    [ -s "$W/legs/$t/id/t.txt" ] || { nope "leg $t/id: no samples (see $W/legs/$t/id/run.log)"; continue; }
    python3 tools/specials_b_rigs.py analyse "$W/legs/$t/id/t.txt" "$W/$t.json" "$IMG" --json "$W/legs/$t/res.json" > /dev/null || nope "analyse $t"
    python3 - "$W/legs/$t/res.json" "$t" >> "$W/got.txt" <<'PY'
import json, sys
for r in json.load(open(sys.argv[1])):
    st = "UNFIRED" if r["entered"] == "UNFIRED" else ("DEGRADED" if r.get("degraded") else "FIRED")
    print("\t".join([sys.argv[2], r["name"], r["input"], r.get("special") or r["entered"], r["entered"], st]))
PY
done
if awk -F'\t' '$6 != "FIRED"' "$W/got.txt" | grep -q .; then
    nope "rows that did not fire a special chain:"; awk -F'\t' '$6 != "FIRED"' "$W/got.txt" | sed 's/^/        /'
else ok "every row fired a special chain ($(grep -c . "$W/got.txt") rows; none UNFIRED, none DEGRADED)"; fi
if [ "${FREEZE:-0}" = 1 ]; then
    { echo "# tests/expected/vanilla_specials_b.tsv — tests/audit_vanilla_specials_b.sh's frozen identity map (#229 F2,"
      echo "# 14z-205): tab, workbook move, input as performed, the SPECIAL chain, the first chain entered, status. Chain ids only."
      cat "$W/got.txt"; } > "$EXP"
    echo "  FROZE $EXP ($(grep -vc '^#' "$EXP") rows)"
fi
grep -v '^#' "$EXP" > "$W/exp.txt" 2>/dev/null || : > "$W/exp.txt"
if [ "$MODE" = swapped-strengths ]; then swap_strengths "$W/exp.txt" "$W/exp.sw" && mv "$W/exp.sw" "$W/exp.txt"; fi
if [ -s "$W/exp.txt" ] && cmp -s "$W/exp.txt" "$W/got.txt"; then ok "the measured map equals $EXP ($(grep -c . "$W/got.txt") rows)"
else nope "the identity map moved"; diff "$W/exp.txt" "$W/got.txt" | head -20; fi

echo "== 5. the timing, in engine passes (the tap)"
ticks_table() {   # ticks_table <out.tsv>: one row per event of every leg, from its own tap
    : > "$1"
    for t in $ALL; do
        python3 tools/specials_b_rigs.py ticks "$W/legs/$t/tap/tap.txt" "$W/legs/$t/res.json" "$IMG" "$t" "$W/legs/$t/ticks.json" > /dev/null || return 1
        python3 - "$W/legs/$t/ticks.json" "$t" >> "$1" <<'PY'
import json, sys
for r in json.load(open(sys.argv[1])):
    pj = r.get("proj") or {}
    print("\t".join(str(x) for x in [sys.argv[2], r["name"], r.get("startup", "-"), r.get("active", "-"), r.get("span", "-"),
                                     r.get("recovery", "-"), r.get("total", "-"), pj.get("startup", "-"), pj.get("active", "-")]))
PY
    done
}
if ticks_table "$W/ticks.tsv"; then
    H="$(shasum -a 256 "$W/ticks.tsv" | cut -d' ' -f1)"
    if [ "${FREEZE:-0}" = 1 ]; then echo "$H  vanilla_specials_b ticks (values out of tree)" > "$TEXP"; echo "  FROZE $TEXP"; fi
    awk -F'\t' '$3 == "-" && $8 == "-"' "$W/ticks.tsv" > "$W/no_timing.txt"
    if [ "$(grep -c . "$W/no_timing.txt")" -le 1 ] && grep -q "HELLS GATE" "$W/no_timing.txt"; then ok "every row but the movement special Hell's Gate carries an attack timing from the tap"
    elif [ ! -s "$W/no_timing.txt" ]; then ok "every row carries a timing from the tap"
    else nope "rows with no attack timing from the tap:"; sed 's/^/        /' "$W/no_timing.txt"; fi
    if [ "$H" = "$(cut -d' ' -f1 "$TEXP" 2>/dev/null)" ]; then ok "the timing table's hash equals $TEXP ($(grep -c . "$W/ticks.tsv") rows)"
    else nope "the timing table moved (hash $H)"; fi
else nope "the tick analysis refused (see $W/legs/*/ticks.json)"; fi

echo "== 6. must-fire controls"
if [ -z "$MODE" ]; then
    swap_strengths "$W/exp.txt" "$W/sw.txt"
    if cmp -s "$W/exp.txt" "$W/sw.txt"; then vs_ctl_dead swapped-strengths "swapping LE's LP/HP Ankihou left the map unchanged"; nope "control swapped-strengths"
    else vs_ctl_fired swapped-strengths "swapping LE's LP and HP Ankihou chains changes the map (section 4 compares against it under the mode)"; fi
    SPECIALS_UNSIGNED=1 python3 tools/specials_b_rigs.py analyse "$W/legs/SA/id/t.txt" "$W/SA.json" "$IMG" > "$W/sa_unsigned.txt" 2>/dev/null
    if grep -E "BIG (BREATH|BLOW)" "$W/sa_unsigned.txt" | grep -q "UNFIRED\|DEGRADED"; then
        vs_ctl_fired unsigned-offsets "read unsigned, Sasquatch's Big Breath/Big Blow rows read $(grep -E 'BIG (BREATH|BLOW)' "$W/sa_unsigned.txt" | cut -f4 | sort -u | tr '\n' ' ')"
    else vs_ctl_dead unsigned-offsets "the unsigned reading still fired Sasquatch's Big Breath/Big Blow"; nope "control unsigned-offsets"; fi
    SPECIALS_WINDOW=event python3 tools/specials_b_rigs.py analyse "$W/legs/ZA/id/t.txt" "$W/ZA.json" "$IMG" > "$W/za_event.txt" 2>/dev/null
    if grep "^ZA	[LMH]K DEATH HURRICANE" "$W/za_event.txt" | cut -f4 | grep -q "^a:0x29"; then
        vs_ctl_fired window-at-event "opened at the event, Zabel's ground Death Hurricane reads $(grep '^ZA	LK DEATH HURRICANE' "$W/za_event.txt" | cut -f4)"
    else vs_ctl_dead window-at-event "the event-start window still read Zabel's Death Hurricane right"; nope "control window-at-event"; fi
    if TICKS_CLOCK=p1 ticks_table "$W/ticks_p1.tsv" && ! cmp -s "$W/ticks.tsv" "$W/ticks_p1.tsv"; then
        vs_ctl_fired p1-clock "on P1's own tick-writes $(diff "$W/ticks.tsv" "$W/ticks_p1.tsv" | grep -c '^>') of $(grep -c . "$W/ticks.tsv") timing rows change (e.g. $(diff "$W/ticks.tsv" "$W/ticks_p1.tsv" | grep '^>' | head -1 | cut -c3- | cut -f1,2,6))"
    else vs_ctl_dead p1-clock "P1's own tick-writes gave the same timing table"; nope "control p1-clock"; fi
    if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG"; nope "control drift-clock"; fi
    if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG"; nope "control first-frame-skip"; fi
else
    echo "  (control mode $MODE: the in-gate controls do not run; the gate must FAIL)"
fi

[ "$bad" = 0 ] && { echo "PASS: audit_vanilla_specials_b"; exit 0; }
echo "FAIL: audit_vanilla_specials_b ($bad)"; exit 1
