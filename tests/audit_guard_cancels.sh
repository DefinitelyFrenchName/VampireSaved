#!/bin/sh
# audit_guard_cancels.sh — THE VSAVJ GUARD CANCELS, MEASURED: which 623+button out of a ground block commits a guard
# cancel for each vanilla character, the chain it enters, and that move's ENGINE TICKS and records, on a hit and on a
# whiff — for the community cross-check (GitHub #229, 14z-205, fork F5). Emulator tier, MAME lane, pristine vsavj.
# Registered 14z-209: emulator tier, MAME lane, scope ondemand (pristine vsavj only).
#
# WHAT: for the 15 vanilla characters with a guard cancel — the 14 the workbook types one for, and Demitri, whose four
#   Demon Cradle GC rows it types `special` / `es special` (#331, 14z-210: measured on build/agent210/t331b/, the
#   maintainer: "Enough, integrate") — and each of the eight
#   623 buttons (LP MP HP LK MK HK, the ES pairs PP = LP+HP and KK = LK+HK): a GC event — P2 (Demitri; a mirror on Demitri's own rigs) 5HP at pushbox
#   contact, P1 holds back through the block and inputs 623+button from +12 (tools/name_moves.py's gc_v, the recipe
#   that fired Phobos's Reflect Wall on native vsav2). For the 57 buttons that commit (tools/gc_rigs.py GC_BUTTONS,
#   the data this gate holds the measurement to): a NOBLOCK event (the same, P1 never holding back) and a WHIFF event
#   (P2's Chaos Flare blocked from ~360 px, the 623+button from +60 inside its blockstun, so the GC reaches nothing),
#   and a DEALT event (#229 Q5 (a), ruled 2026-10-24: the gc event with P2 a defense-row -3 victim — Gallon, Zabel for
#   Gallon's own rows — on which the workbook's guard-cancel damage is read; its first fall is the compared figure, the
#   gc rows' power CLASS the victim-independent one).
#   A GUARD CANCEL is the GAME's own commit — P1's +0x3B5.b := 6 by the commit routine PRG:0x029C6E (atlas ram.md),
#   a stop at 0x029C74 with A6 = P1 — followed by a chain P1 was not in before the motion. The move is timed in ENGINE
#   TICKS: the walker's tick 0x027F70 (`subq.b #1,$20(a6)`, one write = one tick) counted per node between the walker's
#   node writes (0x027EEC, A0 = the node); a hit-freeze holds +0x20, so no freeze is counted. Each node's chain is
#   P1's +0x1C mapped onto tables a2/a/b/c with SIGNED offsets (tools/gc_rigs.walk_signed). The table of the 291 events
#   (identity, chains, startup / active runs / recovery in ticks, every attack run's records with their power CLASS,
#   the stock cost, the GC's first dealt fall on Demitri and on the dealt victim, the whiff's meter gain) is hashed; the values stay out of the tree
#   (FRAMEDATA_OUT, default ../charpages/framedata/guard_cancels.tsv). A host without that table makes it with FREEZE=1
#   (after the rule-checker, as any freeze) or copies it from a host whose table hashes as tests/expected/
#   guard_cancels.sha256; without it the node-shift judgement says NOT JUDGED, never "0 lines differ" (#332).
# HOW: tools/gc_rigs.py gen2 builds 291 one-event rigs (one event per rig: a GC that hits can leave the next event's
#   fighters crossed). Every leg counts EMULATED frames (#228 option A): a TRACE leg per rig (tests/lua/trace_writes.lua,
#   -debug: watchpoints on P1's +0x1C, +0x20 and +0x3B4 from 40 frames before the event, SAMPLE of +0x1C) and a NOSTOP
#   leg per committing gc, whiff and dealt rig (tests/lua/replay_guard.lua without the debugger: DUMPS of P1's
#   0xFF8408-0xFF845F and 0xFF8508-0xFF850B and P2's 0xFF8850-0xFF8853 on every frame of the window — the falls, stock,
#   meter, and the chain sequence on the undisturbed timeline). Each leg's game clock RAM:$FF8080 at its last frame is
#   held to CLOCKS (one row per rig and leg), frozen by --freeze-clock from REFERENCE legs held to replay.lua run live;
#   one STAGING reference leg (the first trace run) is held to replay.lua on every run (tests/lib/instr_align.sh).
# EXPECTS: every leg ended (END) with every window frame dumped; the gc legs commit on exactly GC_BUTTONS' 57 buttons
#   and no other of the 120; no noblock event commits; every whiff event commits and enters the gc event's chain, and
#   P2's HP falls on a whiff exactly where WHIFF_CONNECTS says (5: moves that travel ~360 px reach him); every dealt event
#   commits, enters the gc event's chain and lowers its victim's HP exactly where the gc event lowers Demitri's; on every committing event the two legs agree on the GC chain and the nostop leg's a2 chains are a subsequence of the trace's, every
#   commit is by 0x029C6E, and every SAMPLE of +0x1C is a value the walker wrote (at that frame, or the last before it); the table hashes to EXP; every
#   leg on emulated time at its frozen game clock, the staging leg on replay.lua's checksum.
# NOT TESTED: the characters are FORCED by the early-window poke (the dealt victim too); positions, P2's HP and P1's stock (2) and meter (0)
#   are re-pinned before each event — the ROM is pristine, the RAM is not. ONE timing per kind (+12 near, +60 at range)
#   and ONE attacker (Demitri's 5HP, his Chaos Flare; the dealt victim's own 5HP on the dealt event): a button that does not commit at +12 may at another. A trace
#   leg's stops can move the game ([MFI-2]); its ticks are its own timeline's (the nostop leg must agree on the chains,
#   not on the frames). The game clock is a witness modulo 256 frames. Invulnerability; FBNeo; the cursor path.
#
# MUST-FIRE: known-bad: drift-clock — a trace leg under the OLD frame_done clock (INSTR_CLOCK=frame_done) must miss its frozen game clock (in-gate: one extra run; mode: every leg runs the old clock and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: noblock — the same 623+button with P1 never holding back must commit no guard cancel on any of the 57 committing buttons (in-gate: the noblock legs read 0 commits; mode: the gc rows of the 57 are read from their noblock legs and the identity clause FAILs on all 57)
# MUST-FIRE: perturbed-copy: commit-stripped — every commit stop removed from a copy of each trace must read every event no GC, and the identity clause must FAIL on all 57 and the dealt clause on all 57 dealt events (in-gate and mode)
# MUST-FIRE: perturbed-copy: foreign-pc — every commit stop's PC moved off 0x029C74 in a copy of each trace must read every event no GC (the identity is the commit ROUTINE, not the mark's value), and the identity clause must FAIL on all 57 and the dealt clause on all 57 dealt events (in-gate and mode)
# MUST-FIRE: perturbed-copy: node-shift — every walker node write moved one node (0x18) on in a copy of each trace must change the tick table (the ticks are segmented by the node writes, so the hash reads the walk, not a constant), and the gate must FAIL (in-gate and mode)
# MUST-FIRE: known-bad: table-absent — node-shift judged with no frozen table on the host (FRAMEDATA_OUT an empty dir) must read NOT JUDGED, never "0 lines differ" (#332; in-gate: one extra judgement; mode: the gate runs with FRAMEDATA_OUT empty and FAILs naming the absent table)
# MUST-FIRE: known-bad: rows-absent — the identity clause read on an EMPTY row set must name every one of the 291 rigs MISSING, never "0 of 120 commit" as ok (#331, 14z-210: a run whose legs all failed read that ok line; in-gate: one extra judgement; mode: the run's rows are emptied and the gate FAILs on the identity clause)
# MUST-FIRE: known-bad: foreign-image — an image one byte off vsavj's data view must fail the provenance check (tests/lib/pristine_vsavj.sh; in-gate; mode: the check is handed that image and the gate FAILs)
# MUST-FIRE: known-bad: foreign-romset — a ROMDIR whose vsavj.zip is vsav2.zip must fail the provenance check (in-gate; mode: the check audits that ROMDIR and the gate FAILs)
# MUST-FIRE: known-bad: foreign-rompath — MAME_ROMPATH pointed away from the audited ROMDIR must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# MUST-FIRE: known-bad: foreign-mame — a MAME_BIN that is not the pin's release must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# A MODE exits 1 only when ITS perturbation made ITS clause fail (ctl_judge, the same predicate the control section
# reads); otherwise it prints REFUSED and exits 3 (docs/project/must_fire_contract.md). LEGS_FROM=<a finished run's
# OUT> reuses that run's legs instead of running all 462 (a mode that changes only what is READ — first-frame-skip,
# noblock, the perturbed copies — or a re-reading after a reader fix); drift-clock always re-runs them. The verdict
# of record (a normal run after any freeze) runs its own legs.
# FOLLOWS: build/manifest/bank_map.toml tests/lib/controls.sh tests/lib/decrypt_cache.sh tests/lib/instr_align.sh
#   tests/lua/trace_writes.lua tests/lua/replay_guard.lua tests/lua/emu_clock.lua tests/lua/replay.lua
#   tests/lua/pokes_spec.lua tools/gc_rigs.py tools/anim_nodes.py tools/hitbox_records.py tools/name_moves.py
#   tools/vanilla_frames.py tools/vanilla_join_rig.py tools/run_mame.sh tools/run_replay_guarded.sh
#   tools/setup_mame.sh emu/mame-patches/
#   tests/lib/pristine_vsavj.sh tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py tools/cps2_decrypt.py tests/expected/registry.tsv tests/lib/mame_ident.sh tools/setup_mame.sh tools/run_mame.sh
#   tests/expected/guard_cancels.sha256 tests/expected/instr_gameclock/audit_guard_cancels.tsv
#
# SHEET: none — measures pristine vsavj only; no leg of our build
#
# Usage: ROMDIR=... [JOBS=2] [OUT=<dir>] [EXP=<sha256 file>] [CLOCKS=<tsv>] [FRAMEDATA_OUT=<dir>] [FREEZE=1]
#        [LEGS_FROM=<dir>] tests/audit_guard_cancels.sh [--freeze-clock]
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
FREEZE_CLOCK=0; [ "${1:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
CLOCKS="${CLOCKS:-tests/expected/instr_gameclock/audit_guard_cancels.tsv}"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
JOBS="${JOBS:-2}"
EXP="${EXP:-tests/expected/guard_cancels.sha256}"
FRAMEDATA_OUT="${FRAMEDATA_OUT:-$REPO/../charpages/framedata}"
T=tools/gc_rigs.py
W="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/gcancel.XXXXXX")}"
# absolute, since each leg runs from its own directory (a relative OUT failed every leg, 14z-210); an empty W (a failed
# mktemp) must stop here, never resolve to the working directory that the trap below would then remove
[ -n "$W" ] && mkdir -p "$W" && W="$(cd "$W" && pwd)" && [ -n "$W" ] || { echo "FAIL: audit_guard_cancels — no work directory (mktemp or OUT failed)"; exit 2; }
[ -n "${OUT:-}" ] || trap 'rm -rf "$W"' EXIT
# control table-absent's mode (#332): the out-of-tree table is made absent — an empty dir in its place, inside $W
[ "${CONTROL:-}" = table-absent ] && { FRAMEDATA_OUT="$W/no_table_mode"; mkdir -p "$FRAMEDATA_OUT"; }
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 || { echo "SKIP: the vsavj data view could not be made"; exit 0; }
# WHICH ROM AND WHICH IMAGE (14z-209, rule-checker run 2026-10-25-1294 Q1/Q4): tests/lib/pristine_vsavj.sh.
. "$REPO/tests/lib/pristine_vsavj.sh"
vs_pristine_vsavj "$W/pv" "$W/vsavj_data.bin" || { echo "FAIL: audit_guard_cancels (the ROM or the analysed image is not pristine vsavj)"; exit 1; }
if [ -z "$MODE" ]; then vs_pristine_vsavj_controls "$W/pv" || { echo "FAIL: audit_guard_cancels (a provenance control is dead)"; exit 1; }; fi
GCB="$(python3 $T gcbuttons)"                 # TAB_BTN for the 57 committing buttons
WCX="$(python3 $T whiffconnects)"             # the whiffs measured to reach P2 anyway (data, tools/gc_rigs.py)
TABS="FE AN AU BI BU GA JE LE LI MO QB SA VI ZA DE"; BTNS="LP MP HP LK MK HK PP KK"
if [ -n "${SUBSET:-}" ]; then   # a DRY RUN on some characters only (the counts the clauses expect are the full set's)
    TABS="$SUBSET"; _g=""; for tb in $GCB; do case " $SUBSET " in *" ${tb%_*} "*) _g="$_g $tb" ;; esac; done; GCB="$_g"
    _g=""; for tb in $WCX; do case " $SUBSET " in *" ${tb%_*} "*) _g="$_g $tb" ;; esac; done; WCX="$_g"
    echo "  NOTE  SUBSET=$SUBSET — a dry run, not a verdict"
fi

echo "== audit_guard_cancels: vsavj ($(python3 -c "import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],'rb').read()).hexdigest()[:12])" "$ROMDIR/vsavj.zip")); tree $(git describe --always --dirty --abbrev=12 2>/dev/null); host $(hostname)"
echo "== 1. the rigs"
python3 $T gen2 "$W/rigs" > /dev/null && python3 $T gen2 "$W/rigs2" > /dev/null
if diff -r "$W/rigs" "$W/rigs2" > /dev/null && [ "$(ls "$W/rigs"/*.rpl | wc -l | tr -d ' ')" = 291 ]; then ok "291 rigs, a pure function of (character, kind, button)"
else bad "the rigs are not a pure function of their inputs, or not 291"; fi

ALL_TRACE=""; ALL_NOSTOP=""
for t in $TABS; do for b in $BTNS; do ALL_TRACE="$ALL_TRACE gc_${t}_$b"; done; done
for tb in $GCB; do ALL_TRACE="$ALL_TRACE noblock_$tb whiff_$tb dealt_$tb"; ALL_NOSTOP="$ALL_NOSTOP gc_$tb whiff_$tb dealt_$tb"; done

leg() {  # leg <rig name> <trace|nostop>
    _o="$W/legs/$1/$2"; rm -rf "$_o"; mkdir -p "$_o"
    _p="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$W/rigs/$1.json")"
    _f="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$W/rigs/$1.json")"
    if [ "$2" = trace ]; then
        _e="POKES=$_p $(python3 "$REPO/$T" traceenv "$W/rigs/$1.json")"; printf '%s' "$_e" > "$_o/env"
        # shellcheck disable=SC2086
        ( cd "$_o" && env $_clk $_e REPLAY="$W/rigs/$1.rpl" FRAMES="$_f" TRACE_OUT="$_o/trace.txt" ALIGN_OUT="$_o/align" \
            MAME_SANDBOX="$_o/sb" "$REPO/tools/run_mame.sh" vsavj -debug -debugger none \
            -autoboot_script "$REPO/tests/lua/trace_writes.lua" > "$_o/run.out" 2>&1; rm -rf "$_o/sb" ) </dev/null
    else
        _d="$(python3 "$REPO/$T" dumps "$W/rigs/$1.json")"; printf '%s' "POKES=$_p DUMPS=$_d GUARD_DEBUG=0" > "$_o/env"
        # shellcheck disable=SC2086
        ( env $_clk GUARD_DEBUG=0 POKES="$_p" DUMPS="$_d" ALIGN_OUT="$_o/align" \
            tools/run_replay_guarded.sh vsavj "$W/rigs/$1.rpl" "$_o/run.log" "$_o/sb" > "$_o/run.out" 2>&1; rm -rf "$_o/sb" ) </dev/null
    fi
}
echo "== 2. the legs (trace on all 291, nostop on the 171 committing gc, whiff and dealt rigs; JOBS=$JOBS)"
if [ -n "${LEGS_FROM:-}" ] && [ "$MODE" != drift-clock ]; then
    rm -rf "$W/legs"; cp -R "$LEGS_FROM/legs" "$W/legs"
    echo "  NOTE  reading the legs of $LEGS_FROM (LEGS_FROM) — no leg is run here: a re-reading, not a fresh measurement"
else
    t0=$(date +%s); n=0
    for r in $ALL_TRACE; do leg "$r" trace & n=$((n + 1)); [ $((n % JOBS)) -eq 0 ] && wait; done
    for r in $ALL_NOSTOP; do leg "$r" nostop & n=$((n + 1)); [ $((n % JOBS)) -eq 0 ] && wait; done
    wait
    echo "  NOTE  $n legs in $(( $(date +%s) - t0 )) s"
fi
dead=0
for r in $ALL_TRACE; do grep -q '^END ' "$W/legs/$r/trace/trace.txt" 2>/dev/null || { bad "leg $r/trace did not end: $(tail -1 "$W/legs/$r/trace/run.out" 2>/dev/null | cut -c1-100)"; dead=1; }; done
for r in $ALL_NOSTOP; do grep -q '^END ' "$W/legs/$r/nostop/run.log" 2>/dev/null || { bad "leg $r/nostop did not end"; dead=1; }
    grep -qE '^(CRASH|PCWEEDS|SOFTRESET)' "$W/legs/$r/nostop/run.log" 2>/dev/null && { bad "leg $r/nostop CRASHED"; dead=1; }; done
[ "$dead" = 0 ] && ok "every leg ended clean"
: > "$W/manifest_t.tsv"; : > "$W/manifest_g.tsv"
for r in $ALL_TRACE; do ia_note_run "$W/manifest_t.tsv" trace "$r" vsavj - "$W/rigs/$r.rpl" "$(cat "$W/legs/$r/trace/env")" "$W/legs/$r/trace/align"; done
for r in $ALL_NOSTOP; do ia_note_run "$W/manifest_g.tsv" nostop "$r" vsavj - "$W/rigs/$r.rpl" "$(cat "$W/legs/$r/nostop/env")" "$W/legs/$r/nostop/align"; done

# THE PERTURBATIONS, one function each, used by the control section and by the mode alike: a perturbed copy of the
# legs' trace logs under <out>/legs (the nostop dumps are linked as they are).
perturb() {  # perturb <strip|foreign|shift> <out root>
    python3 - "$W/legs" "$2/legs" "$1" <<'PY'
import os, re, sys
src, dst, kind = sys.argv[1:]
for rig in sorted(os.listdir(src)):
    for leg in os.listdir(os.path.join(src, rig)):
        s, d = os.path.join(src, rig, leg), os.path.join(dst, rig, leg)
        os.makedirs(d, exist_ok=True)
        for f in os.listdir(s):
            p = os.path.join(s, f)
            if leg == "trace" and f == "trace.txt":
                out = []
                for l in open(p, errors="replace"):
                    if kind == "strip" and " PC 029c74 " in l and l.rstrip().endswith("A6 00ff8400"):
                        continue
                    if kind == "foreign" and " PC 029c74 " in l:
                        l = l.replace(" PC 029c74 ", " PC 029c76 ")
                    if kind == "shift" and " PC 027eec " in l:
                        l = re.sub(r"A0 ([0-9a-f]{8})", lambda m: f"A0 {int(m.group(1), 16) + 0x18:08x}", l)
                    out.append(l)
                open(os.path.join(d, f), "w").write("".join(out))
            elif not os.path.exists(os.path.join(d, f)):
                os.symlink(p, os.path.join(d, f))
PY
}
rows_of() {  # rows_of <legs root> [noblock-as-gc] -> rows.jsonl on stdout, every rig
    for r in $ALL_TRACE; do
        _src="$r"
        if [ -n "${2:-}" ]; then case "$r" in gc_*) _tb="${r#gc_}"; case " $GCB " in *" $_tb "*) _src="noblock_$_tb" ;; esac ;; esac; fi
        python3 $T rows2 "$W/rigs/$r.json" "$1/$_src" "$W/vsavj_data.bin" | python3 -c "import json,sys
r=json.loads(sys.stdin.read()); r['rig']='$r'; print(json.dumps(r))"
    done
}
# THE ONE PREDICATE PER CLAUSE (a control section and a mode read the same function).
identity() {  # identity <rows.jsonl> -> problems, one per line; and the committing gc count on the last line
    python3 - "$1" "$GCB" "$WCX" "$ALL_TRACE" <<'PY'
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1])]
want = set(sys.argv[2].split()); connects = set(sys.argv[3].split())
gcs = {r["rig"]: r for r in rows if r["rig"].startswith("gc_")}
# every rig must have a row: a leg whose reader failed leaves no row, and an absent row must never read as "no commit"
# (#331, 14z-210: with every leg failed the clause printed ok on "0 of 120")
have = {r["rig"] for r in rows}
bad = [f"MISSING {rig}: no row (its legs were not read)" for rig in sys.argv[4].split() if rig not in have]
for rig, r in sorted(gcs.items()):
    tb = rig[3:]
    if r["gc"] != (tb in want):
        bad.append(f"IDENTITY {rig}: commits={bool(r['gc'])}, GC_BUTTONS says {tb in want}")
for r in rows:
    if r["rig"].startswith("noblock_") and r.get("commit_frames"):
        bad.append(f"NOBLOCK {r['rig']}: committed at {r['commit_frames']}")
    if r["rig"].startswith("whiff_"):
        g = gcs.get("gc_" + r["rig"][6:], {})
        if not r["gc"]:
            bad.append(f"WHIFF {r['rig']}: no guard cancel")
        elif r.get("t_chain") != g.get("t_chain"):
            bad.append(f"WHIFF {r['rig']}: chain {r.get('t_chain')} where the gc event's is {g.get('t_chain')}")
        if bool(r.get("falls")) != (r["rig"][6:] in connects):
            bad.append(f"WHIFF {r['rig']}: P2's HP falls {r.get('falls')}, WHIFF_CONNECTS says {r['rig'][6:] in connects}")
    if r["rig"].startswith("dealt_"):
        g = gcs.get("gc_" + r["rig"][6:], {})
        if not r["gc"]:
            bad.append(f"DEALT {r['rig']}: no guard cancel on victim {r.get('victim')}")
        elif r.get("t_chain") != g.get("t_chain"):
            bad.append(f"DEALT {r['rig']}: chain {r.get('t_chain')} where the gc event's is {g.get('t_chain')}")
        # the victim's HP falls exactly where Demitri's does on the gc event (Bulleta's guard cancels carry no attack:
        # no fall on either victim, measured 14z-208)
        if bool(r.get("falls")) != bool(g.get("falls")):
            bad.append(f"DEALT {r['rig']}: victim {r.get('victim')}'s HP falls {bool(r.get('falls'))}, Demitri's on the gc event {bool(g.get('falls'))}")
    if r["gc"] or r["rig"][3:] in want:
        if r.get("legs_agree") is False:
            bad.append(f"LEGS {r['rig']}: nostop {r.get('gc_chain')} {r.get('move_chains')} / trace {r.get('t_chain')} {r.get('t_move_chains')}")
        if r.get("dumped") is not None and r["dumped"] != r["dump_need"]:
            bad.append(f"DUMPS {r['rig']}: {r['dumped']}/{r['dump_need']} window frames dumped")
    if r.get("sample_mismatch"):
        bad.append(f"SAMPLE {r['rig']}: {r['sample_mismatch']} +0x1C samples the walker writes do not explain")
for b in bad:
    print(b)
print(f"COMMITTING {sum(1 for r in gcs.values() if r['gc'])}")
PY
}
ctl_judge() {  # ctl_judge <control> <identity output> <table> ; 0 = fired
    case "$1" in
        noblock|commit-stripped|foreign-pc)
            _n="$(grep -c '^IDENTITY ' "$2")"; _c="$(sed -n 's/^COMMITTING //p' "$2")"; _w="$(echo $GCB | wc -w | tr -d ' ')"
            # the perturbed copies strip or move the commit on the DEALT legs too, so the dealt clause must fail on all 57
            # (the noblock mode re-reads only the gc rows, so its dealt rows stay as measured)
            _dn="$(grep -c '^DEALT .*no guard cancel' "$2")"; _dw="$_w"; [ "$1" = noblock ] && _dw=0
            echo "$_n of $_w committing buttons fail the identity clause; $_c gc events commit; $_dn of $_dw dealt events read no guard cancel"
            [ "$_n" = "$_w" ] && [ "$_c" = 0 ] && [ "$_dn" = "$_dw" ] ;;
        rows-absent)
            _m="$(grep -c '^MISSING ' "$2")"; _a="$(echo $ALL_TRACE | wc -w | tr -d ' ')"
            echo "$_m of $_a rigs read MISSING on the empty row set"
            [ "$_m" = "$_a" ] && [ "$_a" -gt 0 ] ;;
        node-shift)
            # the frozen TABLE is out of tree (#332, 14z-210): a host without it cannot judge this clause — say so, and
            # never compare against nothing (diff 2>/dev/null read a missing table as "0 lines differ", so ERIS read DEAD)
            if [ ! -f "$FRAMEDATA_OUT/guard_cancels.tsv" ]; then
                echo "NOT JUDGED: the frozen table $FRAMEDATA_OUT/guard_cancels.tsv is not on this host (out of tree: FREEZE=1 here, or copy it from a host whose table hashes as $EXP)"
                return 3
            fi
            _h="$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$3")"
            # against the FROZEN table (out of tree): in the mode the run's own table IS the shifted one
            _d="$(diff "$3" "$FRAMEDATA_OUT/guard_cancels.tsv" 2>/dev/null | grep -c '^<')"
            echo "the shifted walk's table hashes ${_h%"${_h#????????????}"}, $_d of $(wc -l < "$3" | tr -d ' ') lines differ from the frozen table"
            [ "$_h" != "$(cut -d' ' -f1 "$EXP" 2>/dev/null)" ] && [ "$_d" -gt 0 ] ;;
        *) echo "no such control: $1"; return 2 ;;
    esac
}

echo "== 3. identity, legs, whiffs, and the table"
LEGS="$W/legs"; NBG=""
case "$MODE" in commit-stripped) perturb strip "$W/p_strip"; LEGS="$W/p_strip/legs" ;;
    foreign-pc) perturb foreign "$W/p_foreign"; LEGS="$W/p_foreign/legs" ;;
    node-shift) perturb shift "$W/p_shift"; LEGS="$W/p_shift/legs" ;;
    noblock) NBG=1 ;; esac
rows_of "$LEGS" "$NBG" > "$W/rows.jsonl"
[ "$MODE" = rows-absent ] && : > "$W/rows.jsonl"
identity "$W/rows.jsonl" > "$W/identity.txt"
_np="$(grep -vc '^COMMITTING ' "$W/identity.txt")"
if [ "$_np" = 0 ]; then ok "$(sed -n 's/^COMMITTING //p' "$W/identity.txt") of 120 gc events commit, exactly GC_BUTTONS; 0 of 57 noblock; 57 of 57 whiffs commit into the gc chain, P2 hit only where WHIFF_CONNECTS says; 57 of 57 dealt events commit into the gc chain, the -3 victim's HP falling where Demitri's does; the legs agree; every window dumped; every +0x1C sample explained"
else bad "$_np problem(s):"; grep -v '^COMMITTING ' "$W/identity.txt" | head -12 | sed 's/^/        /'; fi
python3 - "$W/rows.jsonl" <<'PY' > "$W/pcs.txt" && ok "every commit is a stop at 0x029C74 (the routine at 0x029C6E), A6 = P1" || bad "$(cat "$W/pcs.txt")"
import json, sys
# commit_frames come only from 0x029C74 stops with A6 = P1 (tools/gc_rigs.trace_events); a commit elsewhere would be
# a +0x3B4 stop at another PC, which the reader does not count — so this clause is that every event that COMMITS
# carries one commit, not several
bad = [(r["rig"], r["commit_frames"]) for r in map(json.loads, open(sys.argv[1])) if len(r.get("commit_frames", [])) > 1]
print(bad if bad else "")
sys.exit(1 if bad else 0)
PY
python3 $T table2 "$W/rows.jsonl" > "$W/table.tsv"
H="$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$W/table.tsv")"
if [ -n "${FREEZE:-}" ] && [ -z "$MODE" ]; then
    [ "$fail" = 0 ] || { echo "REFUSED: sections 1-3 failed — nothing frozen"; exit 1; }
    mkdir -p "$FRAMEDATA_OUT" "$(dirname "$EXP")"; cp "$W/table.tsv" "$FRAMEDATA_OUT/guard_cancels.tsv"
    printf '%s  guard_cancels.tsv (291 events; tests/audit_guard_cancels.sh FREEZE=1)\n' "$H" > "$EXP"
    echo "  FROZE $EXP; the table is $FRAMEDATA_OUT/guard_cancels.tsv (out of tree)"
fi
WANT="$(cut -d' ' -f1 "$EXP" 2>/dev/null)"
if [ "$H" = "$WANT" ]; then ok "the 291-event table equals the frozen hash"
else bad "the table's hash $H is not the frozen ${WANT:-<none>}"
    [ -f "$FRAMEDATA_OUT/guard_cancels.tsv" ] && diff "$FRAMEDATA_OUT/guard_cancels.tsv" "$W/table.tsv" | head -8 | sed 's/^/        /'; fi

if [ -n "$MODE" ] && [ "$MODE" != drift-clock ] && [ "$MODE" != first-frame-skip ] && [ "$MODE" != table-absent ]; then
    if _ev="$(ctl_judge "$MODE" "$W/identity.txt" "$W/table.tsv")"; then vs_ctl_fired "$MODE" "$_ev (mode)"; echo "FAIL"; exit 1; fi
    case "$_ev" in "NOT JUDGED: "*) echo "$_ev"; echo "FAIL"; exit 1 ;; esac   # #332: the mode measured nothing
    echo "REFUSED: mode $MODE — its perturbation did not make its own clause fail ($_ev): a dead mode, not a verdict"; exit 3
fi

echo "== 4. the instrument's alignment (#228 step 4, option A)"
if [ "$FREEZE_CLOCK" = 1 ]; then
    [ "$fail" = 0 ] || { echo "REFUSED: sections 1-3 failed — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/trace_writes.lua" "$W/manifest_t.tsv" "$W/fz_t" "$JOBS" "$W/clocks_t.tsv" > "$W/fz_t.txt" \
        || { sed 's/^/  /' "$W/fz_t.txt" | head; echo "REFUSED: the trace legs' alignment does not hold — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/replay_guard.lua" "$W/manifest_g.tsv" "$W/fz_g" "$JOBS" "$W/clocks_g.tsv" > "$W/fz_g.txt" \
        || { sed 's/^/  /' "$W/fz_g.txt" | head; echo "REFUSED: the nostop legs' alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/audit_guard_cancels.sh --freeze-clock\`: pristine vsavj; leg trace (trace_writes.lua) and nostop"
      echo "# (replay_guard.lua) per rig; every reference leg held to replay.lua run live, every run to its reference leg's clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$W/clocks_t.tsv" "$W/clocks_g.tsv"; } > "$CLOCKS"
    echo "froze $(cat "$W/clocks_t.tsv" "$W/clocks_g.tsv" | wc -l | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
if ia_check_manifest "$CLOCKS" "$W/manifest_t.tsv" > "$W/align_bad.txt" && ia_check_manifest "$CLOCKS" "$W/manifest_g.tsv" >> "$W/align_bad.txt"
then ok "every leg on emulated time, at its frozen game clock"
else bad "$(wc -l < "$W/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$W/align_bad.txt" | sed 's/^/        /'; fi
ia_stage audit_guard_cancels "$CLOCKS" "$REPO/tests/lua/trace_writes.lua" "$W/manifest_t.tsv" 1 "$W/st" "$MODE" || fail=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "FAIL (control mode: $MODE)"; exit 1; }
    echo "FAIL — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi

echo "== 5. controls"
judge() { if _ev="$(ctl_judge "$1" "$2" "${3:-}")"; then vs_ctl_fired "$1" "$_ev"
          else case "$_ev" in "NOT JUDGED: "*) bad "control $1 ${_ev#NOT JUDGED: }" ;; *) vs_ctl_dead "$1" "$_ev"; fail=1 ;; esac; fi; }   # #332
rows_of "$W/legs" 1 > "$W/rows_nb.jsonl"; identity "$W/rows_nb.jsonl" > "$W/id_nb.txt"; judge noblock "$W/id_nb.txt"
: > "$W/rows_none.jsonl"; identity "$W/rows_none.jsonl" > "$W/id_none.txt"; judge rows-absent "$W/id_none.txt"
for c in strip:commit-stripped foreign:foreign-pc shift:node-shift; do k="${c%%:*}"; name="${c##*:}"
    perturb "$k" "$W/c_$k"; rows_of "$W/c_$k/legs" > "$W/rows_$k.jsonl"; identity "$W/rows_$k.jsonl" > "$W/id_$k.txt"
    python3 $T table2 "$W/rows_$k.jsonl" > "$W/table_$k.tsv"; judge "$name" "$W/id_$k.txt" "$W/table_$k.tsv"
done
# table-absent (#332): the same node-shift judgement with no frozen table on the host must say so, not "0 lines differ"
mkdir -p "$W/no_table"
_ta="$(FRAMEDATA_OUT="$W/no_table" ctl_judge node-shift "$W/id_shift.txt" "$W/table_shift.tsv")"; _tr=$?
case "$_ta" in "NOT JUDGED: "*) [ "$_tr" = 3 ] && vs_ctl_fired table-absent "no frozen table: ${_ta#NOT JUDGED: }" || { vs_ctl_dead table-absent "NOT JUDGED printed but rc $_tr"; fail=1; } ;;
    *) vs_ctl_dead table-absent "with no frozen table the judgement read: $_ta"; fail=1 ;; esac
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
