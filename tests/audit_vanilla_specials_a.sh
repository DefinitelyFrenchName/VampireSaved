#!/bin/sh
# audit_vanilla_specials_a.sh — WHICH CHAIN EACH VANILLA SPECIAL ENTERS ON vsavj, WHAT IT SPAWNS, HOW MANY TIMES
# IT LANDS AT CONTACT, ITS STARTUP/ACTIVE/RECOVERY IN LIVE ENGINE TICKS, AND HOW THOSE READ AGAINST THE COMMUNITY
# WORKBOOK — FE AN AU BI BU DE GA JE (GitHub #229, 14z-205, fork F1's half of the specials family).
# Emulator tier, MAME lane, the vsavj ROM (the reference MAME build run_mame.sh pins for a stock set).
#
# WHAT: the motion specials, special projectiles and movement specials of eight vanilla characters, named by the
#   chain the engine enters (the node pointer +0x1C mapped onto the decoded graph, index offsets read SIGNED) and the
#   projectile objects it spawns (RAM:$FF9400 pool), never by the scripted input ([VSE-47]); each move's startup,
#   active and recovery COUNTED IN ENGINE TICKS (one tick = one BYTE write to P1's countdown +0x20 — PRG:0x027F70's
#   `subq.b #1,$20(a6)`, held equal to the PC filter in-gate — the node at that write); then joined to the workbook rows by ROW INDEX and classified with the
#   cross-check page's own classifier (tools/crosscheck_framedata.py).
# HOW: tools/specials_a_rigs.py builds the rigs (P1 forced, P2 Victor idle; both pinned 332 px apart — the WHIFF pin,
#   inside the engine's 336 px separation clamp — 40 frames before each event; three "~" parts walk in to contact and
#   count P2's HP drops). Every leg runs tests/lua/specials_trace.lua: field_trace.lua's per-frame field log on the
#   shared EMULATED-frame clock (tests/lua/emu_clock.lua) with an ALIGN line, and a memory write tap (no debugger)
#   logging each engine tick. #228 option A (tests/lib/instr_align.sh): every leg is held to its FROZEN game clock
#   RAM:$FF8080 (tests/expected/instr_gameclock/audit_vanilla_specials_a.tsv, frozen from REFERENCE legs each held to
#   replay.lua run live), and one staging reference leg per run is held to replay.lua's checksum.
# EXPECTS: the instrument's field log equals field_trace.lua's byte for byte (JE's rig, both scripts); its byte-mask
#   tick criterion equals the PC filter byte for byte (AN's rig); the rigs regenerate byte-identically; every leg is
#   whole (its field, tick and ALIGN lines; exit 0, or 139 at teardown after them — section 2); JE's leg twice gives
#   identical traces; every leg on its frozen game clock and the staging leg on replay.lua; every event fires with P1
#   facing right; the identity table equals tests/expected/vanilla_specials_a.tsv; the events that entered a plain
#   normal or a baseline chain are exactly the DECLARED set; the contact hit counts equal the frozen ones; every event
#   whose move walks an attack node has live ticks; with the workbook present, the verdicts, the live-vs-derived tick
#   agreement and the values hash equal tests/expected/vanilla_specials_a_verdicts.tsv; every control fires.
# NOT TESTED: the characters are FORCED by the early-window poke; positions and P2's HP are re-pinned before each
#   event — the ROM is pristine, the RAM is not. One victim (Victor), one speed level (the default), one rig cadence
#   per move (BI's Kienzen 623P never fires under five cadences: declared, open). A projectile's own frames (the
#   object's anim table) are not counted: projectile rows' timing cells are UNCOMPARABLE. Moves that connect even at
#   the whiff pin read their active/recovery as UNCOMPARABLE. FBNeo. The game clock is a witness modulo 256 frames.
#
# MUST-FIRE: known-bad: drift-clock — a leg under the OLD frame_done clock with the debugger attached (INSTR_CLOCK=frame_done, -debug) must miss its frozen game clock (in-gate: one extra run from the manifest; mode: every leg runs the old clock under the debugger and the alignment check FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: dead-tap — a leg whose tick tap watches the wrong instruction (TICK_MODE=pc TICK_PC=000000) logs no tick, and the live-tick check must FAIL on it (in-gate: JE's rig once more; mode: every leg runs the dead tap)
# MUST-FIRE: perturbed-copy: swapped-chains — two characters' chain cells swapped in a copy of the frozen identity table must fail the section-6 compare (mode: section 6 compares the measured table against that swapped copy)
# MUST-FIRE: perturbed-copy: hidden-normal — one special's measured chain rewritten to a crouching normal (a2:0x0c) must fail the section-7 declared-normal check (mode: section 7 reads that rewritten table)
# MUST-FIRE: perturbed-copy: sheet-hits — Demitri's contact 623LP hit count rewritten to the two the workbook's damage implies must fail the section-8 compare (mode: section 8 reads that rewritten row)
# MUST-FIRE: known-bad: foreign-image — an image one byte off vsavj's data view must fail the provenance check (tests/lib/pristine_vsavj.sh; in-gate; mode: the check is handed that image and the gate FAILs)
# MUST-FIRE: known-bad: foreign-romset — a ROMDIR whose vsavj.zip is vsav2.zip must fail the provenance check (in-gate; mode: the check audits that ROMDIR and the gate FAILs)
# MUST-FIRE: known-bad: foreign-rompath — MAME_ROMPATH pointed away from the audited ROMDIR must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# MUST-FIRE: known-bad: foreign-mame — a MAME_BIN that is not the pin's release must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# A MODE exits 1 only when ITS perturbation made ITS clause fail; otherwise it prints REFUSED and exits 3
# (docs/project/must_fire_contract.md).
# FOLLOWS: tools/specials_a_rigs.py tools/name_moves.py tools/vanilla_join_rig.py tools/vanilla_frames.py
#   tools/frame_data.py tools/hitbox_records.py tools/anim_nodes.py tools/crosscheck_framedata.py tools/xlsx_read.py
#   tools/run_mame.sh tests/lua/specials_trace.lua tests/lua/emu_clock.lua tests/lua/pokes_spec.lua
#   tests/lua/field_trace.lua tests/lua/replay.lua tests/lib/instr_align.sh tests/lib/controls.sh
#   tests/lib/decrypt_cache.sh build/manifest/bank_map.toml tests/expected/vanilla_specials_a.tsv
#   tests/expected/vanilla_specials_a_verdicts.tsv tests/expected/instr_gameclock/
#   tests/lib/pristine_vsavj.sh tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py tools/cps2_decrypt.py tests/expected/registry.tsv tests/lib/mame_ident.sh tools/setup_mame.sh tools/run_mame.sh
#   emu/mame-patches/
#
# SHEET: none — measures pristine vsavj only; no leg of our build
#
# WHY THE HIT PARTS EXIST. On three moves the sheet's damage is the sum of TWO attack records where our derivation
# lands ONE hit (DE 623P, GA 2[8]K: the records share hit id 1, and consecutive same-id attack nodes land once —
# tests/test_rehit_ring.sh) or the sheet splits the hits by strength where ours does not (BI [4]6P/K). The page's rule:
# an inconsistent pattern means re-check OUR measurement first. So each is performed at CONTACT (a walk-in; a near
# pair cannot be poked, the pushboxes cross the fighters, 14z-120) and P2's HP drops are counted: DE 623P lands 1,
# GA 2[8]K 1, BI's Iai Giri 2 at every strength (charged down-back, [1], so the charge does not walk him away).
# WHY TICKS. ~16-30% of frames run a second logic pass (the speed level's pattern, engine_internals), so a frame count
# cannot carry a one-tick convention; and a node's duration byte is not what it plays when game logic cuts it short
# (Jedah's air special: its landing ends the last attack node after 1 of its 2 ticks — the duration bytes read
# 26/26/9 where the engine ticked 23/25/8).
#
# Usage: ROMDIR=... [JOBS=2] [KEEP=dir] [SHEET=<workbook.xlsx>] tests/audit_vanilla_specials_a.sh [--freeze-clock]
#        FREEZE=1 re-freezes the identity table and the verdicts; --freeze-clock re-freezes the game clocks.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
FREEZE_CLOCK=0; [ "${1:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
EXP=tests/expected/vanilla_specials_a.tsv
VEXP=tests/expected/vanilla_specials_a_verdicts.tsv
CLOCKS=tests/expected/instr_gameclock/audit_vanilla_specials_a.tsv
SHEET="${SHEET:-$REPO/../community/vsav-framedata.xlsx}"
JOBS="${JOBS:-2}"
INSTR="$REPO/tests/lua/specials_trace.lua"
T=tools/specials_a_rigs.py
W="$(mktemp -d)"
if [ -n "${KEEP:-}" ]; then mkdir -p "$KEEP"; trap 'cp -R "$W"/. "$KEEP"/ 2>/dev/null; rm -rf "$W"' EXIT; else trap 'rm -rf "$W"' EXIT; fi
bad=0; FAILED=""
ok()  { echo "  ok    $1"; }
nope() { echo "  FAIL  $1"; bad=$((bad + 1)); }
clause_failed() { FAILED="$FAILED $1"; }

[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset"; exit 0; }
ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 || { echo "SKIP: the vsavj data view could not be made"; exit 0; }
IMG="$W/vsavj_data.bin"
# WHICH ROM AND WHICH IMAGE (14z-209, rule-checker run 2026-10-25-1294 Q1/Q4): tests/lib/pristine_vsavj.sh.
. "$REPO/tests/lib/pristine_vsavj.sh"
vs_pristine_vsavj "$W/pv" "$W/vsavj_data.bin" || { echo "FAIL: audit_vanilla_specials_a (the ROM or the analysed image is not pristine vsavj)"; exit 1; }
if [ -z "$MODE" ]; then vs_pristine_vsavj_controls "$W/pv" || { echo "FAIL: audit_vanilla_specials_a (a provenance control is dead)"; exit 1; }; fi

# the legs: <tab>:<pins> — the whiff legs at 488/820, the contact ("~") parts at the far pin with their walk-in
# and the "^" STATE part (14z-205c): BI's Tsuji Hayate, row 38, exists only after a connecting Karame Dama, so its
# events walk in like a contact part and carry the row (tools/specials_a_rigs.py EVENTS["BI^"])
LEGS="FE:488,820 AN:488,820 AU:488,820 BI:488,820 BI+:488,820 BU:488,820 DE:488,820 DE+:488,820 GA:488,820 JE:488,820 BI~:- DE~:- GA~:- BI^:-"
# THE DECLARED NORMAL ENTRIES: events whose first chain is a plain normal (a2:0x00-0x1d) or a baseline chain while the
# workbook row is a special — each measured, each with its reason (tools/specials_a_rigs.py UNJOINABLE and the BI+/DE+
# notes; BI 623P is Kienzen, mizuumi "623P", entering his crouching normals under five cadences — open; BI j.412[6]P
# is the first pass's misread of Karame Dama's 4123P, kept as measured; BU [2]8P is Hop & Missile, a jump: it enters
# the baseline jump chain a:0x0e and spawns the missile, type 0x02). Anything else entering a normal FAILS section 7.
DECLARED="FE|22LP
FE|22MP
FE|22HP
AN|236LK
BI|j.412[6]LP
BI|j.412[6]MP
BI|j.412[6]HP
BI|623LP
BI|623MP
BI|623HP
BI+|623LP slow
BI+|623MP slow
BI+|623HP slow
BI+|623LP tight
BI+|623MP tight
BI+|623HP tight
BI+|6323LP zig
BI+|6323MP zig
BI+|623LP late
BU|[2]8LP
BU|[2]8MP
BU|[2]8HP"

# THE PERTURBATIONS, one function each, called by the control section and by the mode alike.
swap_chains() { python3 - "$1" "$2" <<'PY'
import sys
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
i = next(k for k, r in enumerate(rows) if r[0] == "FE"); j = next(k for k, r in enumerate(rows) if r[0] == "AU")
rows[i][2], rows[j][2] = rows[j][2], rows[i][2]
open(sys.argv[2], "w").write("".join("\t".join(r) + "\n" for r in rows))
PY
}
hide_normal() { awk -F'\t' 'BEGIN{OFS="\t"} $1=="AU" && $2=="623LK" {$3="a2:0x0c"} {print}' "$1" > "$2"; }
sheet_hits() { awk -F'\t' 'BEGIN{OFS="\t"} $1=="DE~" && $2=="623LP" {$3="2"} {print}' "$1" > "$2"; }
declared_check() {  # declared_check <table>
    python3 - "$1" "$DECLARED" <<'PY'
import sys
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
decl = {tuple(l.split("|", 1)) for l in sys.argv[2].splitlines() if l.strip()}
NORMAL_ROWS = {("BU", "5HK"), ("BU", "2HK"), ("BU", "j.HK"), ("BU", "3HK")}   # the workbook's `projectile` normals
def normal(seq):
    c = seq.split(">")[0]
    tn, _, sq = c.partition(":")
    if not sq: return False
    v = int(sq, 16)
    return (tn == "a2" and v < 0x1E) or (tn == "a" and v <= 0x10)
got = {(r[0], r[1]) for r in rows if (r[0], r[1]) not in NORMAL_ROWS and normal(r[2])}
ok = got == decl
print(("  ok    " if ok else "  FAIL  ") + f"{len(got)} special events entered a normal or baseline chain; declared {len(decl)}"
      + ("" if ok else f" — undeclared {sorted(got - decl)}, declared but not measured {sorted(decl - got)}"))
sys.exit(0 if ok else 1)
PY
}
ticks_check() {  # ticks_check <analysis.json ...>: every event whose move walks an attack node has live ticks
    python3 - "$@" <<'PY'
import json, sys
need = got = 0; miss = []
for p in sys.argv[1:]:
    a = json.load(open(p))
    for e in a["events"]:
        if any(w[3] for w in e.get("walk") or []):
            need += 1
            t = e.get("ticks") or {}
            if t.get("active"):
                got += 1
            else:
                miss.append(f"{a['tab']} {e['key']}")
ok = need > 0 and got == need
print(("  ok    " if ok else "  FAIL  ") + f"{got} of {need} events whose move walks an attack node have live engine ticks"
      + ("" if ok else f" — none on: {', '.join(miss[:8])}{' ...' if len(miss) > 8 else ''}"))
sys.exit(0 if ok else 1)
PY
}

echo "== audit_vanilla_specials_a: the vsavj ROM ($(python3 -c "import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],'rb').read()).hexdigest()[:12])" "$ROMDIR/vsavj.zip")); tree $(git -C "$REPO" describe --always --dirty --abbrev=12 2>/dev/null || echo 'no git'); host $(hostname)"

echo "== 1. the rigs regenerate byte-identically"
for L in $LEGS; do
    tab="${L%%:*}"; pins="${L##*:}"; set --; [ "$pins" != "-" ] && set -- $(echo "$pins" | tr ',' ' ')
    python3 $T gen "$tab" "$W/$tab.rpl" "$W/$tab.json" "$@" >/dev/null || nope "gen $tab"
    python3 $T gen "$tab" "$W/re.rpl" "$W/re.json" "$@" >/dev/null
    cmp -s "$W/$tab.rpl" "$W/re.rpl" && cmp -s "$W/$tab.json" "$W/re.json" || nope "rig $tab is not a pure function of its inputs"
done
[ "$bad" = 0 ] && ok "every rig is a pure function of (part, pins)"

DBG=""; CLK=""; TICK="TICK_MODE=mask"
[ "$MODE" = drift-clock ] && { DBG="-debug -debugger none"; CLK="INSTR_CLOCK=frame_done"; }
[ "$MODE" = dead-tap ] && TICK="TICK_MODE=pc TICK_PC=000000"
leg() {  # leg <tab> <outdir> [tick env words] [script]: one leg of <tab>'s rig
    mkdir -p "$2"
    P="$(python3 -c "import json;print(';'.join(json.load(open('$W/$1.json'))['pokes']))")"
    FR="$(python3 -c "import json;print(json.load(open('$W/$1.json'))['frames'])")"
    FL="$(python3 -c "import json;print(json.load(open('$W/$1.json'))['fields'])")"
    # shellcheck disable=SC2086
    ( cd "$2" && env $CLK ${3:-$TICK} MAME_SANDBOX="$2/sb" REPLAY="$W/$1.rpl" POKES="$P" FIELDS="$FL" FIELD_OUT="$2/t.txt" \
        FIELD_FROM=2400 FIELD_TO="$FR" FRAMES="$FR" ALIGN_OUT="$2/align" TICK_TAP=ff8420 \
        "$REPO/tools/run_mame.sh" vsavj $DBG -autoboot_script "${4:-$INSTR}" > run.log 2>&1; echo "$?" > "$2/rc" ) </dev/null
    rm -rf "$2/sb"
}

echo "== 2. the legs ($JOBS at a time) and the instrument's ground truth"
t0=$(date +%s); n=0
for L in $LEGS JE:again JE:twin AN:pc JE:deadtap; do
    tab="${L%%:*}"; d="$W/leg_$tab"
    case "$L" in
        JE:again) d="$W/leg_JE_again"; leg JE "$d" & ;;
        JE:twin) d="$W/leg_JE_twin"; leg JE "$d" "TICK_MODE=mask" "$REPO/tests/lua/field_trace.lua" & ;;
        AN:pc) d="$W/leg_AN_pc"; leg AN "$d" "TICK_MODE=pc TICK_PC=027f70" & ;;
        JE:deadtap) d="$W/leg_JE_deadtap"; leg JE "$d" "TICK_MODE=pc TICK_PC=000000" & ;;
        *) leg "$tab" "$d" & ;;
    esac
    n=$((n + 1)); [ $((n % JOBS)) -eq 0 ] && wait
done
wait
# A LEG IS WHOLE when its field log, its tick summary and its ALIGN line are all written (emu_clock writes the ALIGN
# line immediately before machine:exit()), and MAME exited 0 — or 139: a segmentation fault AT TEARDOWN, after every
# output is written, which MAME's write taps produce intermittently (measured 14z-205 on these 13 rigs, 2 at a time:
# tests/lua/tap_writes.lua 2 of 13, this instrument 3 of 13, the same with every tap handle kept alive; never without a
# tap). The tree's tap gates judge such legs by content (tests/test_tick_durations.sh runs its legs `|| true`). Any other
# exit, or a missing output, FAILS. ROOT-CAUSED #320 (14z-210): the crash is MAME 0.288's `add_change_notifier` binding
# keeping the callback on the Lua thread that registered it, a thread the GC may free before ~address_space unrefs it;
# the instrument now pins that thread (docs/platform/gotchas.md). 139 stays accepted here, with the full output required.
dead=0; c139=0
for L in $LEGS; do tab="${L%%:*}"; d="$W/leg_$tab"; rc="$(cat "$d/rc" 2>/dev/null)"
    grep -q '^FIELDSUMMARY' "$d/t.txt" 2>/dev/null && grep -q '^TICKSUMMARY' "$d/t.txt" 2>/dev/null && [ -s "$d/align" ] \
        || { nope "leg $tab did not complete (field, tick or ALIGN line missing; exit $rc, see $d/run.log)"; dead=1; continue; }
    case "$rc" in 0) ;; 139) c139=$((c139 + 1)) ;; *) nope "leg $tab exited $rc (see $d/run.log)"; dead=1 ;; esac
done
[ "$dead" = 0 ] && ok "$n legs whole (field, tick and ALIGN lines) in $(( $(date +%s) - t0 )) s; exit 0, or 139 at teardown after every output ($c139 of the $(echo $LEGS | wc -w | tr -d ' ') measured legs)"
if cmp -s "$W/leg_JE/t.txt" "$W/leg_JE_again/t.txt" && [ -s "$W/leg_JE/t.txt" ]; then ok "run-to-run: JE's leg twice gives byte-identical traces (fields and ticks)"
else nope "run-to-run: JE's two traces differ (or are empty)"; fi
grep -v -e '^T ' -e '^TICKSUMMARY' "$W/leg_JE/t.txt" > "$W/je_fields.txt"
if cmp -s "$W/je_fields.txt" "$W/leg_JE_twin/t.txt" && [ -s "$W/je_fields.txt" ]; then
    ok "the instrument's field log equals tests/lua/field_trace.lua's byte for byte on JE's rig ($(grep -c '^F ' "$W/je_fields.txt") frames)"
else nope "the instrument's field log differs from field_trace.lua's on JE's rig"; fi
# THE TICK CRITERION'S GROUND TRUTH: the default byte-mask tick (no CPU state read in the tap) against the PC filter
# (PRG:0x027F70, the subq.b tests/test_tick_durations.sh established as one tick) on AN's rig: the tick lines must be
# byte-identical. The pc leg's own exit code is not judged — reading cpu.state inside the tap crashes MAME at
# teardown on most rigs, after every output is written (tests/lua/specials_trace.lua) — but its tick log must be whole.
if grep -q '^TICKSUMMARY' "$W/leg_AN_pc/t.txt" 2>/dev/null && [ -s "$W/leg_AN/t.txt" ] \
    && cmp -s "$W/leg_AN_pc/t.txt" "$W/leg_AN/t.txt"; then
    ok "the byte-mask tick criterion equals the PC filter (PRG:0x027F70) on AN's rig: $(grep -c '^T ' "$W/leg_AN/t.txt") ticks, traces byte-identical"
else nope "the byte-mask tick criterion differs from the PC filter on AN's rig (or a leg is incomplete)"; fi
M="$W/manifest.tsv"; : > "$M"
for L in $LEGS JE:again; do tab="${L%%:*}"; d="$W/leg_$tab"; [ "$L" = JE:again ] && d="$W/leg_JE_again"
    P="$(python3 -c "import json;print(';'.join(json.load(open('$W/$tab.json'))['pokes']))")"
    ia_note_run "$M" vsavj "$tab" vsavj - "$W/$tab.rpl" "POKES=$P" "$d/align"
done

echo "== 3. #228 option A: every leg on its frozen game clock; the staging leg on replay.lua"
if [ "$FREEZE_CLOCK" = 1 ]; then
    if ia_freeze "$INSTR" "$M" "$W/freeze" "$JOBS" "$W/clock_rows.tsv"; then
        { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
          echo "# option A) by \`tests/audit_vanilla_specials_a.sh --freeze-clock\` at $(git describe --always --dirty --abbrev=8 2>/dev/null): pristine vsavj; one"
          echo "# leg per rig (tests/lua/specials_trace.lua); every reference leg held to replay.lua run live."
          echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"; cat "$W/clock_rows.tsv"; } > "$CLOCKS"
        echo "  FROZE $CLOCKS ($(grep -vc '^#' "$CLOCKS") rows)"
    else nope "the clock freeze refused (above)"; fi
fi
if ia_check_manifest "$CLOCKS" "$M" > "$W/align_problems.txt"; then ok "all $(grep -c . "$M") legs counted emulated frames and ended on their frozen game clocks"
else nope "legs off their frozen game clocks:"; sed 's/^/        /' "$W/align_problems.txt" | head -8; clause_failed drift-clock; fi
_sl=$(awk -F'\t' '$2=="JE" {print NR; exit}' "$M")
if ia_stage audit_vanilla_specials_a "$CLOCKS" "$INSTR" "$M" "$_sl" "$W/stage" "$MODE"; then :; else bad=$((bad + 1)); clause_failed first-frame-skip; fi
case "$MODE" in drift-clock|first-frame-skip) ;; *)
    [ "$IA_DRIFT" = fired ] && vs_ctl_fired drift-clock "$IA_DRIFT_MSG" || { vs_ctl_dead drift-clock "$IA_DRIFT_MSG"; bad=$((bad + 1)); }
    [ "$IA_SKIP" = fired ] && vs_ctl_fired first-frame-skip "$IA_SKIP_MSG" || { vs_ctl_dead first-frame-skip "$IA_SKIP_MSG"; bad=$((bad + 1)); } ;;
esac

: > "$W/an_list"
for L in $LEGS; do tab="${L%%:*}"
    [ -s "$W/leg_$tab/t.txt" ] || continue
    python3 $T analyse "$tab" "$W/leg_$tab/t.txt" "$W/$tab.json" "$IMG" --json "$W/leg_$tab/an.json" > "$W/leg_$tab/an.txt" || nope "analyse $tab"
    echo "$W/leg_$tab/an.json" >> "$W/an_list"
done
python3 $T table $(cat "$W/an_list") > "$W/got.tsv"

echo "== 4. every event fired, P1 facing right"
if awk -F'\t' '$3=="UNFIRED"' "$W/got.tsv" | grep -q .; then nope "events never fired:"; awk -F'\t' '$3=="UNFIRED"' "$W/got.tsv" | sed 's/^/        /'
else ok "every event entered a chain ($(grep -c . "$W/got.tsv") events)"; fi
if awk -F'\t' '$6!="R"' "$W/got.tsv" | grep -q .; then nope "P1 faced left at a press (a mirrored motion):"; awk -F'\t' '$6!="R"' "$W/got.tsv" | sed 's/^/        /'
else ok "P1 faced right at every press"; fi

echo "== 6. the identity table against the frozen one"
if [ "${FREEZE:-0}" = 1 ] && [ -z "$MODE" ]; then
    { echo "# tests/audit_vanilla_specials_a.sh — tab key chain-sequence spawned-types p2-hits facing (FREEZE=1 writes it)"; cat "$W/got.tsv"; } > "$EXP"
    echo "  FROZE $EXP ($(grep -vc '^#' "$EXP") rows)"
fi
grep -v '^#' "$EXP" > "$W/exp.tsv" 2>/dev/null || : > "$W/exp.tsv"
cp "$W/exp.tsv" "$W/exp_cmp.tsv"
[ "$MODE" = swapped-chains ] && { swap_chains "$W/exp.tsv" "$W/exp_cmp.tsv"; }
if cmp -s "$W/exp_cmp.tsv" "$W/got.tsv"; then ok "the identity table equals $EXP ($(grep -c . "$W/got.tsv") rows)"
else nope "the identity table moved"; diff "$W/exp_cmp.tsv" "$W/got.tsv" | head -12; clause_failed swapped-chains; fi

echo "== 7. the events that entered a normal are exactly the declared ones"
cp "$W/got.tsv" "$W/s7.tsv"
[ "$MODE" = hidden-normal ] && { hide_normal "$W/got.tsv" "$W/s7.tsv"; }
declared_check "$W/s7.tsv" || { bad=$((bad + 1)); clause_failed hidden-normal; }

echo "== 8. the hit counts at contact"
awk -F'\t' '$1 ~ /~$/ {print $1"\t"$2"\t"$5}' "$W/got.tsv" > "$W/hits.tsv"
[ "$MODE" = sheet-hits ] && { sheet_hits "$W/hits.tsv" "$W/hits.sw"; mv "$W/hits.sw" "$W/hits.tsv"; }
awk -F'\t' '$1 ~ /~$/ {print $1"\t"$2"\t"$5}' "$W/exp.tsv" > "$W/exp_hits.tsv"
if cmp -s "$W/exp_hits.tsv" "$W/hits.tsv" && [ -s "$W/hits.tsv" ]; then
    ok "contact hit counts equal the frozen ones: $(awk -F'\t' '{printf "%s %s=%s; ", $1, $2, $3}' "$W/hits.tsv")"
else nope "contact hit counts moved"; diff "$W/exp_hits.tsv" "$W/hits.tsv" | head; clause_failed sheet-hits; fi

echo "== 9. live engine ticks"
ticks_check $(cat "$W/an_list") || { bad=$((bad + 1)); clause_failed dead-tap; }

echo "== 10. the join against the workbook (tick verdicts, live-vs-derived agreement, the values hash)"
if [ ! -f "$SHEET" ]; then
    echo "  NOTE  no workbook at $SHEET: not joined here (it is third-party and lives outside the tree)"
else
    python3 $T join $(grep -v '~' "$W/an_list") --image "$IMG" --sheet "$SHEET" --json "$W/join.json" > "$W/verdicts.txt" || nope "join"
    python3 $T values-hash "$W/join.json" > "$W/hash.txt"
    python3 $T tick-agreement "$W/join.json" > "$W/agree.txt"
    { cat "$W/verdicts.txt"; cat "$W/agree.txt"; echo "VALUES-SHA256	$(cat "$W/hash.txt")"; } > "$W/vgot.tsv"
    if [ "${FREEZE:-0}" = 1 ] && [ -z "$MODE" ]; then
        { echo "# tests/audit_vanilla_specials_a.sh — per-character column verdicts (timing in LIVE ENGINE TICKS), the live-vs-derived tick agreement, and the sha256 of the joined values (FREEZE=1)"; cat "$W/vgot.tsv"; } > "$VEXP"
        echo "  FROZE $VEXP"
    fi
    grep -v '^#' "$VEXP" > "$W/vexp.tsv" 2>/dev/null || : > "$W/vexp.tsv"
    if cmp -s "$W/vgot.tsv" "$W/vexp.tsv"; then ok "verdicts, tick agreement and values hash equal $VEXP ($(sed -n 's/^TICKS-AGREE\t//p' "$W/vgot.tsv"))"
    else nope "verdicts, tick agreement or values moved"; diff "$W/vexp.tsv" "$W/vgot.tsv" | head -16; fi
fi

echo "== 11. must-fire controls (the three perturbed copies and the dead tap; drift-clock and first-frame-skip above)"
swap_chains "$W/exp.tsv" "$W/swapped.tsv"
if cmp -s "$W/exp.tsv" "$W/swapped.tsv"; then vs_ctl_dead swapped-chains "swapping two chain cells leaves the table unchanged"; bad=$((bad + 1))
else vs_ctl_fired swapped-chains "swapping FE's and AU's first chain cells changes the frozen table (section 6 compares against it under the mode)"; fi
hide_normal "$W/got.tsv" "$W/hidden.tsv"
if declared_check "$W/hidden.tsv" > /dev/null; then vs_ctl_dead hidden-normal "the declared-normal check passed AU 623LK rewritten to a crouching normal"; bad=$((bad + 1))
else vs_ctl_fired hidden-normal "the declared-normal check refuses AU 623LK rewritten to a2:0x0c"; fi
awk -F'\t' '$1 ~ /~$/ {print $1"\t"$2"\t"$5}' "$W/got.tsv" > "$W/h0.tsv"; sheet_hits "$W/h0.tsv" "$W/h1.tsv"
if cmp -s "$W/exp_hits.tsv" "$W/h1.tsv"; then vs_ctl_dead sheet-hits "the contact compare passed DE 623LP at two hits"; bad=$((bad + 1))
else vs_ctl_fired sheet-hits "the contact compare refuses DE 623LP rewritten to the workbook's two hits"; fi
if [ -s "$W/leg_JE_deadtap/t.txt" ] && ! grep -q '^T ' "$W/leg_JE_deadtap/t.txt"; then
    python3 $T analyse JE "$W/leg_JE_deadtap/t.txt" "$W/JE.json" "$IMG" --json "$W/deadtap.json" > /dev/null
    if ticks_check "$W/deadtap.json" > "$W/deadtap.txt"; then vs_ctl_dead dead-tap "the live-tick check passed a leg with no tick ($(cat "$W/deadtap.txt"))"; bad=$((bad + 1))
    else vs_ctl_fired dead-tap "JE's rig with TICK_PC=000000 logs 0 ticks and the live-tick check refuses it: $(sed 's/^ *FAIL *//' "$W/deadtap.txt" | cut -c1-90)"; fi
else vs_ctl_dead dead-tap "the dead-tap leg logged ticks or did not run"; bad=$((bad + 1)); fi

if [ -n "$MODE" ]; then
    case " $FAILED " in *" $MODE "*) echo "FAIL: audit_vanilla_specials_a (control mode $MODE: its clause failed)"; exit 1 ;; esac
    echo "REFUSED: control mode $MODE ran and its clause did not fail"; exit 3
fi
[ "$bad" = 0 ] && { echo "PASS: audit_vanilla_specials_a"; exit 0; }
echo "FAIL: audit_vanilla_specials_a ($bad)"; exit 1
