#!/bin/sh
# audit_es_ex.sh — THE VSAVJ ES SPECIALS AND EX SUPERS, NAMED BY WHAT THE ENGINE DID: for the community cross-check
# (GitHub #229, 14z-205, fork F3 of the parallel run). Emulator tier, MAME lane, the vsavj ROM (the reference MAME
# build run_mame.sh pins for a stock set).
#
# WHAT: the workbook's 111 ES/EX rows (`type` es special / es special projectile / ex / ex projectile / ex
#   unblockable) on the 15 vanilla characters, as 104 events (one per distinct input; tools/es_ex_rigs.py EVENTS,
#   with the inputs the two INPUT SWEEPS chose, CHOSEN, and the ten events no input fired, UNRESOLVED), each run on a
#   FAR leg (whiff, projectiles) and a NEAR leg (walk-in to contact): the anim chain P1 enters (the MOVE: the first
#   chain after the press that is neither baseline, nor seen before the press, nor a plain normal a2:0x00-0x1d), the
#   stock it paid (+0x109 poked to 9 at t-60), and the records the game STAGED from the move's entry at the fighter
#   applier PRG:0x0189EA and the object-hit applier PRG:0x02979A.
# HOW: tools/es_ex_rigs.py gen (30 rigs, a pure function of the code: regenerated twice, byte-compared); per rig a
#   FIELD leg (tests/lua/field_trace.lua, no debugger: chains, stock, falls, the PASS counter for engine ticks) and two
#   PROBE legs (tests/lua/replay_guard.lua -debug through tools/run_replay_guarded.sh, one logging breakpoint each);
#   `rows` + `records` + `freeze`; the frozen lines are tests/expected/es_ex.tsv — identity (status, move, first chain,
#   stock, record count) and a SHA-1 of each event's record list, never the damage values (frame data stays out of
#   the tree); the engine-tick timing is REPORTED (build dir), never frozen.
# EXPECTS: every leg ends clean; the 208 lines equal the frozen ones; STRUCTURE from the values: every FIRED event
#   paid >= 1 stock and its move is not a plain normal; every UNRESOLVED event reads FIRED-NO-STOCK on both legs, except
#   one that PAYS into another event's chains (SAME_AS: Felicia's 236PP~PP reads the ES Buckler's), which must equal
#   them; the row set maps 110 of the workbook's 111 rows (Demitri's ES Demon Cradle GC declared for the guard-cancel
#   family) where the workbook is present. THE INSTRUMENT'S ALIGNMENT (#228 step 4, option A; tests/lib/instr_align.sh):
#   every probe leg on emulated time at its frozen game clock RAM:$FF8080 (tests/expected/instr_gameclock/audit_es_ex.tsv,
#   frozen by --freeze-clock from REFERENCE legs each held to replay.lua run live), and one STAGING reference leg held
#   to replay.lua on every run.
# NOT TESTED: identity BY EYE (the capture sheets are the maintainer's); the FIELD legs are not on the alignment
#   manifest (no debugger, as audit_vanilla_pursuits' FIELD leg); the probe legs' -debug stops can move the game
#   ([MFI-2]), so their records are compared as a list, never by frame; the characters are FORCED by the early-window
#   poke; P2 is Victor (Demitri for Victor) only; FBNeo; PILOT/ERIS.
#
# MUST-FIRE: known-bad: drift-clock — the probe leg under the OLD frame_done clock (INSTR_CLOCK=frame_done) must miss its frozen game clock (in-gate: one extra run; mode: every probe leg runs the old clock and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: unsigned-offsets — the UNSIGNED table-offset read of tools/anim_nodes.py (ESEX_UNSIGNED=1) must leave Sasquatch's ES Big Breath, ES Big Blow and Big Banana off-graph and fail the compare on them (in-gate: SA's legs re-analysed; mode: every leg analysed unsigned)
# MUST-FIRE: known-bad: empty-bank — Demitri's far rig with the stock poke written 0 must read every ES event FIRED-NO-STOCK (the silent degrade, [VSP-170]) and fail the compare (in-gate: one extra FIELD run; mode: DE's rigs run with an empty bank)
# MUST-FIRE: perturbed-copy: swapped-move — the frozen lines with the first line's move swapped with the first line whose move differs must fail the compare (mode: the compare reads that copy)
# MUST-FIRE: known-bad: foreign-image — an image one byte off vsavj's data view must fail the provenance check (tests/lib/pristine_vsavj.sh; in-gate; mode: the check is handed that image and the gate FAILs)
# MUST-FIRE: known-bad: foreign-romset — a ROMDIR whose vsavj.zip is vsav2.zip must fail the provenance check (in-gate; mode: the check audits that ROMDIR and the gate FAILs)
# MUST-FIRE: known-bad: foreign-rompath — MAME_ROMPATH pointed away from the audited ROMDIR must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# MUST-FIRE: known-bad: foreign-mame — a MAME_BIN that is not the pin's release must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# A MODE exits 1 only when ITS perturbation made the gate fail; otherwise it prints REFUSED and exits 3.
#
# FOLLOWS: build/manifest/bank_map.toml tests/expected/es_ex.tsv tests/expected/instr_gameclock/ tests/lib/controls.sh
#   tests/lib/decrypt_cache.sh tests/lib/instr_align.sh tests/lua/emu_clock.lua tests/lua/field_trace.lua
#   tests/lua/pokes_spec.lua tests/lua/replay.lua tests/lua/replay_guard.lua tools/anim_nodes.py tools/es_ex_rigs.py
#   tools/hitbox_records.py tools/name_moves.py tools/run_mame.sh tools/run_replay_guarded.sh tools/setup_mame.sh
#   tools/vanilla_frames.py tools/vanilla_join_rig.py tools/xlsx_read.py emu/mame-patches/
#   tests/lib/pristine_vsavj.sh tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py tools/cps2_decrypt.py tests/expected/registry.tsv tests/lib/mame_ident.sh tools/setup_mame.sh tools/run_mame.sh
#
# SHEET: none — measures pristine vsavj only; no leg of our build
#
# Usage: ROMDIR=... [JOBS=2] [OUT=<dir>] [CHARS="SA DE"] [FREEZE=1] tests/audit_es_ex.sh [--freeze-clock]
#        CONTROL=<control> runs one control's mode (it must FAIL).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
FREEZE_CLOCK=0; [ "${1:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
CLOCKS="tests/expected/instr_gameclock/audit_es_ex.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
JOBS="${JOBS:-2}"
EXP=tests/expected/es_ex.tsv
T=tools/es_ex_rigs.py
WB="${SHEET:-$REPO/../community/vsav-framedata.xlsx}"
W="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/esex.XXXXXX")}" || { echo "FAIL: audit_es_ex — mktemp -d failed (W)"; exit 2; }; mkdir -p "$W"; W="$(cd "$W" && pwd)"   # absolute: each leg cds into its own dir
[ -n "${OUT:-}" ] || trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 || { echo "SKIP: the vsavj data view could not be made"; exit 0; }
IMG="$W/vsavj_data.bin"
# WHICH ROM AND WHICH IMAGE (14z-209, rule-checker run 2026-10-25-1294 Q1/Q4): tests/lib/pristine_vsavj.sh.
. "$REPO/tests/lib/pristine_vsavj.sh"
vs_pristine_vsavj "$W/pv" "$W/vsavj_data.bin" || { echo "FAIL: audit_es_ex (the ROM or the analysed image is not pristine vsavj)"; exit 1; }
if [ -z "$MODE" ]; then vs_pristine_vsavj_controls "$W/pv" || { echo "FAIL: audit_es_ex (a provenance control is dead)"; exit 1; }; fi
echo "== audit_es_ex: the vsavj ES/EX moves, named by the engine ($(git describe --always --dirty 2>/dev/null), $(hostname -s))"

# THE PERTURBATIONS, one function each, called by the control section and by the mode alike.
empty_bank() {  # empty_bank <rig.json>: the stock poke written 0 (the rig's .rpl is unchanged)
    sed 's/:ff8509:09"/:ff8509:00"/' "$1" > "$1.x" && mv "$1.x" "$1"     # portable (no sed -i: BSD and GNU differ)
}
swap_move() {  # swap_move <in.tsv> <out.tsv>: the first line's move swapped with the first line whose move differs
    awk -F'\t' 'BEGIN{OFS="\t"} {a[NR]=$0; m[NR]=$5} END{j=0; for(i=2;i<=NR;i++) if(m[i]!=m[1]){j=i;break}
        for(i=1;i<=NR;i++){split(a[i],f,"\t"); if(i==1)f[5]=m[j]; if(i==j)f[5]=m[1]; s=f[1]; for(k=2;k<=9;k++) s=s OFS f[k]; print s}}' "$1" > "$2"
}
want_of() {  # want_of <out.tsv>: the frozen lines (the CHARS subset when set), sorted
    grep -v '^#' "$EXP" | sort > "$1"
    if [ -n "${CHARS:-}" ]; then awk -F'\t' -v c=" $CHARS " 'index(c, " " $1 " ")' "$1" > "$1.x"; mv "$1.x" "$1"; fi
}

echo "== 1. the rigs regenerate byte-identically; the row set"
python3 "$T" gen "$W/rigs" >/dev/null && python3 "$T" gen "$W/rigs2" >/dev/null || bad "gen"
diff -r "$W/rigs" "$W/rigs2" >/dev/null && ok "30 rigs are a pure function of the code" || bad "the rigs are not a pure function of the code"
if [ -f "$WB" ]; then
    python3 "$T" rowset "$WB" > "$W/rowset.out"
    grep -q "rows mapped 110" "$W/rowset.out" && ! grep -qE "^(MISSING|NOT IN)" "$W/rowset.out" \
        && ok "the events map 110 of the workbook's 111 ES/EX rows (1 declared for the guard-cancel family)" \
        || bad "the row set: $(tail -1 "$W/rowset.out")"
else echo "  NOTE  the workbook is absent: the row set is not checked"; fi
vs_ctl_is empty-bank && { for j in "$W"/rigs/esex_DE_*.json; do empty_bank "$j"; done; }

echo "== 2. the legs (FIELD + two PROBE legs per rig, $JOBS at a time)"
FIELDS="$(python3 -c "import sys;sys.path.insert(0,'tools');import es_ex_rigs as e;print(e.FIELDS)")"
export REPO FIELDS _clk
: > "$W/jobs"
for j in "$W"/rigs/*.json; do
    b="$(basename "$j" .json)"; tab="${b#esex_}"; tab="${tab%_*}"
    [ -n "${CHARS:-}" ] && { case " $CHARS " in *" $tab "*) ;; *) continue;; esac; }
    echo "F $j $W/legs/$b/field" >> "$W/jobs"
    for ap in 0189ea 02979a; do echo "P $j $W/legs/$b/p$ap $ap" >> "$W/jobs"; done
done
# THE JOB LIST IS xargs's STDIN: a </dev/null on the xargs line replaced it and ran NOTHING (the first draft PASSED on
# zero rigs, 14z-205) — the redirect is per job, inside the script, and zero rigs measured is a FAIL below.
t0=$(date +%s)
xargs -P "$JOBS" -L 1 sh -c '
  kind=$0; j=$1; o=$2; ap=${3:-}; r="${j%.json}.rpl"; mkdir -p "$o"
  P="$(python3 -c "import json,sys;print(\";\".join(json.load(open(sys.argv[1]))[\"pokes\"]))" "$j")"
  FR="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))[\"frames\"])" "$j")"
  if [ "$kind" = F ]; then
    ( cd "$o" && MAME_SANDBOX="$o/sb" REPLAY="$r" POKES="$P" FIELDS="$FIELDS" FIELD_OUT="$o/t.txt" FIELD_FROM=2400 \
      FIELD_TO="$FR" FRAMES="$FR" timeout 900 "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$o/run.out" 2>&1 ) </dev/null
    rm -rf "$o/sb"
  else
    printf "%s" "POKES=$P GUARD_PROBE=$ap" > "$o/env"
    ( cd "$REPO" && env $_clk POKES="$P" GUARD_PROBE="$ap" ALIGN_OUT="$o/align" timeout 900 tools/run_replay_guarded.sh vsavj "$r" \
      "$o/run.log" "$o/sb" > "$o/run.out" 2>&1 ) </dev/null
  fi' < "$W/jobs"
n=0; dead=0
for j in "$W"/rigs/*.json; do
    b="$(basename "$j" .json)"
    [ -d "$W/legs/$b" ] || continue
    n=$((n + 1))
    grep -q '^FIELDSUMMARY' "$W/legs/$b/field/t.txt" 2>/dev/null || { bad "leg $b/field did not complete"; dead=1; }
    for pc in p0189ea p02979a; do
        grep -q '^END ' "$W/legs/$b/$pc/run.log" 2>/dev/null || { bad "leg $b/$pc did not end: $(tail -1 "$W/legs/$b/$pc/run.out" 2>/dev/null | cut -c1-120)"; dead=1; }
        grep -qE '^(CRASH|PCWEEDS|SOFTRESET)' "$W/legs/$b/$pc/run.log" 2>/dev/null && { bad "leg $b/$pc CRASHED"; dead=1; }
    done
done
if [ "$n" = 0 ]; then bad "NO rig was measured (an empty run can never pass)"
elif [ "$dead" = 0 ]; then ok "$((n * 3)) legs of $n rigs ended clean in $(( $(date +%s) - t0 )) s"; fi
for j in "$W"/rigs/*.json; do
    b="$(basename "$j" .json)"
    [ -d "$W/legs/$b" ] || continue
    for pc in p0189ea p02979a; do
        ia_note_run "$W/manifest.tsv" "$pc" "$b" vsavj - "${j%.json}.rpl" "$(cat "$W/legs/$b/$pc/env")" "$W/legs/$b/$pc/align"
    done
done

rows_of() {  # rows_of <legs> <rows.jsonl> <recs.jsonl> [unsigned]
    : > "$2"; : > "$3"
    for j in "$W"/rigs/*.json; do
        b="$(basename "$j" .json)"
        [ -d "$1/$b" ] || continue
        if [ -n "${4:-}" ]; then ESEX_UNSIGNED=1 python3 "$T" rows "$j" "$1/$b/field/t.txt" "$IMG" >> "$2"
        else python3 "$T" rows "$j" "$1/$b/field/t.txt" "$IMG" >> "$2"; fi
        mkdir -p "$W/probe/$b"
        for ap in 0189ea 02979a; do mkdir -p "$W/probe/$b/$ap"; cp "$1/$b/p$ap/run.log" "$W/probe/$b/$ap/run.log" 2>/dev/null; done
        python3 "$T" records "$j" "$W/probe/$b" "$IMG" >> "$3"
    done
}

echo "== 3. the events against the frozen lines"
rows_of "$W/legs" "$W/rows.jsonl" "$W/recs.jsonl" "$(vs_ctl_is unsigned-offsets && echo u)"
python3 "$T" freeze "$W/rows.jsonl" "$W/recs.jsonl" | sort > "$W/got.tsv"
if [ -n "${FREEZE:-}" ] && [ -z "$MODE" ]; then
    if [ ! -s "$W/got.tsv" ] || [ "$fail" = 1 ] || [ -n "${CHARS:-}" ]; then echo "  REFUSED to freeze ($(wc -l < "$W/got.tsv" | tr -d ' ') lines, fail=$fail, CHARS='${CHARS:-}')"
    else
        { echo "# tests/expected/es_ex.tsv — the vsavj ES/EX events (#229, 14z-205 F3), FROZEN by tests/audit_es_ex.sh FREEZE=1;"
          echo "# columns: sheet leg key status move first_chain stock_paid n_records sha1(records)[:12] — identity and a hash"
          echo "# of the staged records, never the damage values (frame data stays out of the tree)."
          cat "$W/got.tsv"; } > "$EXP"
        echo "  FROZE $EXP ($(wc -l < "$W/got.tsv" | tr -d ' ') lines)"
    fi
fi
want_of "$W/want.tsv"
vs_ctl_is swapped-move && { swap_move "$W/want.tsv" "$W/want.sw"; mv "$W/want.sw" "$W/want.tsv"; }
if cmp -s "$W/got.tsv" "$W/want.tsv"; then ok "$(wc -l < "$W/got.tsv" | tr -d ' ') event lines equal the frozen ones"
else bad "the events differ from $EXP:"; diff "$W/want.tsv" "$W/got.tsv" | head -12 | sed 's/^/        /'; fi

echo "== 4. structure, from the values"
python3 - "$W/rows.jsonl" <<'PY' || fail=1
import json, sys
sys.path.insert(0, "tools"); import es_ex_rigs as ex
bad = 0
R = [json.loads(l) for l in open(sys.argv[1])]
for r in R:
    if r["status"] == "FIRED" and (r["stock_paid"] < 1 or r["move"] in ex.NORMALS):
        print(f"  FAIL  {r['sheet']} {r['leg']} {r['key']}: FIRED with stock {r['stock_paid']} into {r['move']}"); bad = 1
    k = (r["sheet"], r["key"])
    if k in ex.SAME_AS:
        o = next((x for x in R if (x["sheet"], x["leg"], x["key"]) == (r["sheet"], r["leg"], ex.SAME_AS[k])), None)
        if o is None or o["chains"] != r["chains"]:
            print(f"  FAIL  {r['sheet']} {r['leg']} {r['key']}: declared the same move as {ex.SAME_AS[k]} but its chains differ"); bad = 1
    elif k in ex.UNRESOLVED and r["status"] != "FIRED-NO-STOCK":
        print(f"  FAIL  {r['sheet']} {r['leg']} {r['key']}: declared UNRESOLVED but reads {r['status']}"); bad = 1
fired = sum(r["status"] == "FIRED" for r in R)
print(f"  {'ok   ' if not bad else 'FAIL '} {fired} of {len(R)} event legs FIRED with stock into a non-normal chain; "
      f"the {len(ex.UNRESOLVED) - len(ex.SAME_AS)} declared UNRESOLVED events read FIRED-NO-STOCK, and {len(ex.SAME_AS)} reads its twin's chains")
sys.exit(bad)
PY

if [ -n "$MODE" ] && [ "$MODE" != drift-clock ] && [ "$MODE" != first-frame-skip ]; then
    if [ "$fail" = 1 ]; then vs_ctl_fired "$MODE" "the gate FAILED on its perturbed input (mode)"; echo "FAIL"; exit 1; fi
    echo "REFUSED: mode $MODE — its perturbation did not make the gate fail: a dead mode, not a verdict"; exit 3
fi

echo "== 3b. the instrument's alignment (#228 step 4, option A)"
if [ "$FREEZE_CLOCK" = 1 ]; then
    [ "$fail" = 0 ] || { echo "REFUSED: sections 1-4 failed — nothing frozen"; exit 1; }
    [ -z "${CHARS:-}" ] || { echo "REFUSED: --freeze-clock on a CHARS subset — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" "$W/fz" "$JOBS" "$W/clocks.tsv" \
        > "$W/fz.txt" || { sed 's/^/  /' "$W/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/audit_es_ex.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): pristine vsavj; legs p0189ea and"
      echo "# p02979a per rig; every reference leg held to replay.lua run live, every guarded leg to its reference leg's game clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      sort "$W/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$W/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
if ia_check_manifest "$CLOCKS" "$W/manifest.tsv" > "$W/align_bad.txt"; then ok "every probe leg on emulated time, at its frozen game clock"
else bad "$(wc -l < "$W/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$W/align_bad.txt" | sed 's/^/        /'; fi
ia_stage audit_es_ex "$CLOCKS" "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" 2 "$W/st" "$MODE" || fail=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "FAIL (control mode: $MODE)"; exit 1; }
    echo "FAIL — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi

echo "== 5. controls"
# unsigned-offsets: SA's FIELD legs re-analysed with the unsigned table read
if [ -d "$W/legs/esex_SA_far" ]; then
    : > "$W/u_rows.jsonl"
    for j in "$W"/rigs/esex_SA_*.json; do b="$(basename "$j" .json)"
        ESEX_UNSIGNED=1 python3 "$T" rows "$j" "$W/legs/$b/field/t.txt" "$IMG" >> "$W/u_rows.jsonl"; done
    grep '"sheet": "SA"' "$W/recs.jsonl" > "$W/u_recs.jsonl"
    python3 "$T" freeze "$W/u_rows.jsonl" "$W/u_recs.jsonl" | sort > "$W/u_got.tsv"
    awk -F'\t' '$1 == "SA"' "$W/want.tsv" > "$W/u_want.tsv"
    _nd="$(diff "$W/u_want.tsv" "$W/u_got.tsv" | grep -c '^>')"
    if [ "$_nd" -gt 0 ]; then vs_ctl_fired unsigned-offsets "the unsigned read changes $_nd of SA's frozen lines (off-graph)"
    else vs_ctl_dead unsigned-offsets "the unsigned read left SA's lines equal" || fail=1; fi
else echo "  NOTE  unsigned-offsets: SA not in this run (CHARS)"; fi
# empty-bank: one extra FIELD run of DE's far rig with the stock poke written 0
if [ -d "$W/legs/esex_DE_far" ]; then
    mkdir -p "$W/eb"; cp "$W/rigs/esex_DE_far.json" "$W/rigs/esex_DE_far.rpl" "$W/eb/"; empty_bank "$W/eb/esex_DE_far.json"
    _p="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$W/eb/esex_DE_far.json")"
    _f="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$W/eb/esex_DE_far.json")"
    ( cd "$W/eb" && MAME_SANDBOX="$W/eb/sb" REPLAY="$W/eb/esex_DE_far.rpl" POKES="$_p" FIELDS="$FIELDS" FIELD_OUT="$W/eb/t.txt" \
        FIELD_FROM=2400 FIELD_TO="$_f" FRAMES="$_f" timeout 900 "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/eb/run.out" 2>&1 ) </dev/null
    python3 "$T" rows "$W/eb/esex_DE_far.json" "$W/eb/t.txt" "$IMG" > "$W/eb/rows.jsonl"
    _es="$(python3 -c "
import json,sys
R=[json.loads(l) for l in open(sys.argv[1])]
es=[r for r in R if r['key'] in ('236PP','623PP','66,623PP','214KK')]
print(sum(r['status']=='FIRED-NO-STOCK' for r in es), len(es))" "$W/eb/rows.jsonl")"
    if [ "$_es" = "4 4" ]; then vs_ctl_fired empty-bank "all 4 of Demitri's ES events read FIRED-NO-STOCK with an empty bank"
    else vs_ctl_dead empty-bank "with an empty bank $_es of Demitri's ES events read FIRED-NO-STOCK" || fail=1; fi
else echo "  NOTE  empty-bank: DE not in this run (CHARS)"; fi
# swapped-move: the perturbed copy of the frozen lines must fail the compare against the measured lines
swap_move "$W/want.tsv" "$W/sw.tsv"
if ! cmp -s "$W/got.tsv" "$W/sw.tsv"; then vs_ctl_fired swapped-move "the swapped copy differs from the measured lines"
else vs_ctl_dead swapped-move "the swapped copy equals the measured lines" || fail=1; fi

[ "$fail" = 0 ] && { echo "PASS"; exit 0; }
echo "FAIL"; exit 1
