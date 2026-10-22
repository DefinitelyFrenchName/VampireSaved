#!/bin/sh
# audit_legacy_pairings.sh — WHICH REPLAYS ARE LEGACY CONTENT, and is every
# one of them compared against VANILLA rather than against itself?
#
# WHAT: every replay that loads only vanilla characters on the build (a LEGACY pairing,
#   judged by the fighters' hitbox bases, never by the filename) carries a `.masked` or
#   `.pending` expectation compared against VANILLA — a self-frozen `.sha1` on legacy
#   content is the 14z-88 hole where a superset regression sat green; a tenant-loading
#   replay keeps its `.sha1`.
# HOW: every non-skipped replay run bare on MAME as run_suite does (no pokes), the loaded
#   characters read from +0x60 and classed LEGACY / TENANT / NO-MATCH by
#   tools/check_legacy_pairings.py against the expectation kinds; a LEGACY verdict may be
#   overridden only by a printed `.legacy-exempt` reason.
# EXPECTS: no legacy pairing on a bare .sha1, every override printed, NO-MATCH replays
#   reported for hand judgement; each tenant's forced-pick control loads THAT tenant.
#   Every leg runs on its own fresh sandbox (#293, 14z-205): the sweep runs each DISTINCT build once (the default
#   names one build three times, once per tenant id, and those three legs used to share one sandbox and one out file,
#   so a later leg booted on an earlier one's nvram), and each id's control has its own file.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/ tests/lua/field_trace.lua
#   tests/replays/ tools/build_fingerprint.py tools/check_legacy_pairings.py
#   tools/freeze_masked_basis.sh tools/run_mame.sh tools/setup_mame.sh tests/lib/sheet.sh tests/lib/controls.sh
#
# SHEET: legs vsavj,ours — moments: per replay, the first frame of each distinct fighter pair the verdict compares (the +0x60 hitbox-base sequence), on each leg at its own frame; for a NO-MATCH replay its last traced frame — not comparable: the select wheel on our build (21 cells against vanilla's 16, by design) and a hook-cycle load phase of a frame or two (tolerated by the verdict)
# SHEET-VERDICTS: LEGACY = the replay loads only vanilla characters on the build, so it is legacy content and must carry a .masked (or .pending) expectation; TENANT = it loads a tenant (Donovan, Phobos or Pyron), so a bare .sha1 is correct; NO-MATCH = no fighter pair ever loaded, reported and hand-judged, never classed
# MUST-FIRE: perturbed-copy: shared-sandbox — a leg whose sandbox already exists (a carried run, #293) must be refused, never run (in-gate: a planted leg with its sandbox made beforehand must leave a REUSED marker and no run; mode: the sweep runs every BUILDS entry without de-duplication, the pre-#293 rig, so a replay's second leg finds the first one's sandbox and the gate FAILs)
#
# WHY THIS EXISTS (14z-89, closing the gap 14z-88 exposed the hard way).
# The 14z-87b medallion row move cost `38_victor_p1_vsavj` — P1 Victor vs
# P2 cell 0x0F — one main-loop iteration at the select->VS fade, and the
# whole-RAM stream never re-converged against vanilla. On the current
# de-substituted builds cell 0x0F is JEDAH, so that replay loads VANILLA
# IDS: it is a legacy pairing, and a superset-invariant regression sat
# GREEN in every battery. It sat green because the replay carried a
# SELF-FROZEN `.sha1` — an expectation compared only against the build's
# own earlier run, which by construction cannot see a legacy regression;
# it re-freezes whatever the build does.
#
# That is a CLASS, not one replay. Most `*_don_*` and `*_victor_*` replays
# were authored on the SUBSTITUTION track, where select cell 0x0F was
# Donovan. On the de-substituted WIDE builds they pick Jedah. They have
# been legacy content for many sessions while wearing tenant filenames.
# THE FILENAME IS THE LAST THING THAT TELLS YOU WHAT A REPLAY LOADS.
#
# WHAT THIS ASSERTS. For every replay the set does not `.skip`:
#   verdict LEGACY  (same characters as vanilla)  => it MUST carry a
#                   `.masked` (or a `.pending`) expectation. A LEGACY
#                   replay on a bare `.sha1` is the 14z-88 hole and FAILS.
#   verdict TENANT  (loads a tenant)              => `.sha1` is correct;
#                   no vanilla oracle exists for it.
#   A LEGACY verdict may be OVERRIDDEN by a written reason: a rig that
#   navigates the EXTENDED WHEEL can load vanilla's fighters by coincidence
#   while having no vanilla oracle for the run (61/62 on the sets that do not
#   back cell 0x13). Such a replay stays self-frozen only with the reason in
#   `tests/expected/<set>/<name>.legacy-exempt`, which is PRINTED every run.
#   verdict NO-MATCH(no fighter ever loaded)      => REPORTED, never
#                   auto-judged: whether a select/attract-only replay is
#                   tenant-affected is decided by what the SCREEN does
#                   (the wheel gains three cells), which this instrument
#                   cannot see. See the hand-judged list below.
#
# THE SIGNATURE IS +0x60, NOT +0x382 — see tools/check_legacy_pairings.py
# (+0x382 is the char id, but on a 1P CPU flow the arcade ladder writes the
# CPU side's next opponent there before it loads — ram.md +0x382, 14z-188).
#
# NO POKES, DELIBERATELY. Several replays are only meaningful under the
# forced-pick / HP pokes their own gate scripts supply. This audit runs
# them EXACTLY as `tests/run_suite.sh` does — bare — because the question
# is about the expectations run_suite dispatches, and a replay that loads
# Jedah under the suite is legacy content under the suite whatever a gate
# does with it elsewhere.
#
# HAND-JUDGED NO-MATCH REPLAYS (14z-89, measured): 44_don_select_hover,
# 58_don_select_confirm, 64_select_mashright and 92_p2_ring_walk never
# populate a fighter block on either leg — they are select-screen rigs, and
# the screen they drive is the EXTENDED WHEEL (21 cells vs vanilla's 16),
# a difference this instrument cannot see and the roster work intends.
# Self-frozen is correct for them. They are printed every run so the
# judgement is re-made rather than inherited.
# NOT in that list, and the reason this is MEASURED rather than assumed:
# 63_idle_select LOOKS like the same kind of rig (the cursor wanders until
# the select timer forces a pick) but measures LEGACY on all three sets —
# the forced pick lands on the same character as vanilla, so it has a
# vanilla oracle and was promoted with the rest.
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=6] [PAIRINGS_OUT=build/legacy_pairings]
#        tests/audit_legacy_pairings.sh [builddir:tenantid ...]
# Default builds: the merged build, once per tenant id for the forced-pick controls; the sweep runs each distinct
# build once (#293). ~30 min before #293 (225 MAME legs, JOBS-parallel), fewer legs since.
# Section 0 (verdict controls) is static and runs first — a checker that has
# not been ground-truthed never issues a verdict.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-89: WHICH REPLAYS ARE LEGACY CONTENT — and is each one compared
#   against VANILLA rather than against itself? Measures every non-skip
#   replay's loaded-character signature on vanilla AND on the build and FAILS
#   if a legacy pairing carries only a self-frozen `.sha1` (which by
#   construction cannot see a legacy regression — that is how the 14z-88
#   medallion regression stayed green). The filename does not answer it: the
#   *_don_*/*_victor_* families became LEGACY when M3a restored Jedah to cell
#   0x0F, and 35 of ~43 self-frozen replays per set measured as legacy
#   pairings. Signature is +0x60.l (the per-character hitbox base) NOT +0x382
#   (a CPU flow's ladder pick rewrites it, ram.md +0x382, 14z-188); compares the distinct-value SEQUENCE
#   so a hook-cycle load phase is tolerated. 7 static verdict controls incl.
#   the dead-instrument refusal, plus a LIVE positive control per set (the
#   same replay with the tenant id poked must flip LEGACY->TENANT). NO POKES
#   otherwise — it measures what run_suite dispatches. ~30 min, JOBS-parallel;
#   report per set in build/legacy_pairings/*.tsv
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
JOBS="${JOBS:-6}"
OUT="${PAIRINGS_OUT:-build/legacy_pairings}"
CHK="python3 $REPO/tools/check_legacy_pairings.py"
BUILDS="${*:-build/m3b_merged31:13 build/m3b_merged31:10 build/m3b_merged31:11}"  # re-pointed 14z-133b: MERGED (B2, maintainer-ruled; expectation set merged-m16)  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
FIELDS="ff8782:b:p1id,ff8b82:b:p2id,ff8460:l:p1hb,ff8860:l:p2hb,ff812d:b:st,ff810e:b:ph"   # st/ph: the sheet's in-round frames only (#291 S4-E); the checker reads the four named above

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mkdir -p "$OUT"
fail=0
verdict() { rc=0; $CHK "$1" "$2" --name "$3" > "$4" 2>&1 || rc=$?; }

# ---------------------------------------------------------------- section 0
# VERDICT CONTROLS. Static fixtures, no emulator, seconds. Each names the
# way the checker could be wrong and requires it to be caught.
echo "== 0: verdict controls (static; the checker before any verdict) =="
mk() { printf '%s\n' "$2" > "$W/$1"; printf 'FIELDSUMMARY frames=%s\n' "$3" >> "$W/$1"; }
ctl() {  # $1 label  $2 vanilla  $3 build  $4 want-rc  $5 what it proves
    verdict "$W/$2" "$W/$3" "$1" "$W/ctl"
    if [ "$rc" = "$4" ]; then echo "  ok $1: $5"
    else echo "  FAIL $1: rc=$rc want $4 — $5"; sed 's/^/      /' "$W/ctl"; fail=1; fi
}
mk c_van 'F 100 p1id=0 p2id=0 p1hb=0 p2hb=0
F 200 p1id=0 p2id=2 p1hb=604522 p2hb=619678
F 300 p1id=0 p2id=2 p1hb=604522 p2hb=619678' 3
cp "$W/c_van" "$W/c_same"
mk c_ten 'F 100 p1id=0 p2id=0 p1hb=0 p2hb=0
F 200 p1id=19 p2id=2 p1hb=4212345 p2hb=619678
F 300 p1id=19 p2id=2 p1hb=4212345 p2hb=619678' 3
# same characters, loaded two frames later — engine hooks cost cycles, and a
# frame-indexed diff would call this a different match
mk c_phase 'F 100 p1id=0 p2id=0 p1hb=0 p2hb=0
F 202 p1id=0 p2id=2 p1hb=604522 p2hb=619678
F 302 p1id=0 p2id=2 p1hb=604522 p2hb=619678' 3
: > "$W/c_dead"
printf 'F 100 p1id=0 p2id=0 p1hb=0 p2hb=0\n' > "$W/c_trunc"
mk c_nom 'F 100 p1id=0 p2id=0 p1hb=0 p2hb=0
F 200 p1id=0 p2id=0 p1hb=0 p2hb=0' 2
cp "$W/c_nom" "$W/c_nom2"
# same fighters, different IN-MATCH +0x382 — the verdict must not ride on the
# value the arcade ladder writes there before the CPU side loads (14z-188)
mk c_voice 'F 100 p1id=0 p2id=0 p1hb=0 p2hb=0
F 200 p1id=6 p2id=12 p1hb=604522 p2hb=619678
F 300 p1id=12 p2id=6 p1hb=604522 p2hb=619678' 3

ctl c1  c_van c_same  0 "identical legs -> LEGACY"
ctl c2  c_van c_ten   1 "a different fighter base -> TENANT"
ctl c3  c_van c_phase 0 "a two-frame load phase is tolerated -> LEGACY"
ctl c4  c_van c_dead  3 "an EMPTY leg -> DEAD, never agreement"
ctl c4b c_van c_trunc 3 "a TRUNCATED leg (no FIELDSUMMARY) -> DEAD"
ctl c5  c_nom c_nom2  2 "no fighter on either leg -> NO-MATCH"
ctl c6  c_van c_voice 0 "voice-class reassignment does not flip the verdict"
if [ "$fail" != 0 ]; then
    echo "VERDICT LOGIC UNSOUND — no measurement attempted"; exit 1
fi

# ---------------------------------------------------------------- section 1
# THE SWEEP. One field_trace leg per (replay, target). The vanilla leg is
# shared across sets — vanilla is vanilla.
last_frame() {   # $1 = .rpl ; the highest scripted frame
    sed 's/#.*//' "$1" | awk 'NF { split($1, r, "-"); f = (r[2] ? r[2] : r[1]);
        if (f + 0 > m) m = f + 0 } END { print m + 0 }'
}
leg() {          # $1 out.field  $2 set  $3 rompath-or-empty  $4 rpl  $5 frames  [$6 pokes]
    d="$(dirname "$1")/sb_$(basename "$1" .field)"
    # #293: a leg's sandbox must be NEW. mkdir (not -p) is atomic and fails on an existing directory, so a leg that would
    # boot on another run's nvram is refused before MAME starts, and says so in a marker section 2 turns into a FAIL.
    if ! mkdir "$d" 2>/dev/null; then echo "$d" > "$1.REUSED"; return 0; fi
    ( if [ -n "$3" ]; then MAME_ROMPATH="$3;$ROMDIR"; export MAME_ROMPATH; fi
      MAME_SANDBOX="$d" REPLAY="$4" FIELDS="$FIELDS" FIELD_OUT="$1" \
      FRAMES="$5" POKES="${6:-}" \
      "$REPO/tools/run_mame.sh" "$2" \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" >"$d/mame.log" 2>&1 ) || true
    # 14z-90 (GitHub issue #23). The `|| true` above is deliberate — one dead
    # leg must not abort a 30-minute sweep — but the corpus downstream is a
    # GLOB over the .field files this produces (:223), so a leg that died just
    # VANISHED from the sweep and the audit still printed COVERAGE: PASS. A
    # replay that was never measured must not read the same as one that was.
    [ -s "$1" ] || keep_dead "$1" "$d"
}
# #233 (14z-192): the sandbox above lives in $W, which the EXIT trap deletes, so a
# dead leg's mame.log went with it and its cause was never readable. A dead leg's
# sandbox is COPIED to $DEAD_DIR first, and its .DEAD marker names the copy.
DEAD_DIR="$OUT/dead/$(date -u +%Y%m%dT%H%M%SZ)_$$"
keep_dead() {    # $1 out.field  $2 sandbox
    _k="$DEAD_DIR/$(basename "$(dirname "$1")")_$(basename "$1" .field)"
    mkdir -p "$_k"; cp -R "$2"/. "$_k"/ 2>/dev/null || true
    echo "$_k" > "$1.DEAD"
}
show_dead() {    # $1 .DEAD marker: the kept copy and the tail of its MAME log
    _k="$(cat "$1")"
    echo "        $(basename "$1" .field.DEAD): kept $_k"
    if [ -s "$_k/mame.log" ]; then tail -5 "$_k/mame.log" | sed 's/^/          | /'
    else echo "          | (no mame.log in the sandbox)"; fi
}
pool=0
sync_pool() { pool=$((pool + 1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi; }

# Resolve each build's expectation set ONCE (the fingerprint hashes the zip).
TAGS=""
for b in $BUILDS; do
    dir="${b%%:*}"; tag="$(basename "$dir")"
    if [ ! -f "$REPO/$dir/rompath/vsavjw.zip" ]; then
        echo "SKIP: no $dir/rompath/vsavjw.zip"; exit 0
    fi
    exp="$(python3 "$REPO/tools/build_fingerprint.py" "$REPO/$dir/rompath;$ROMDIR" --set vsavjw)" \
        || { echo "FAIL: $dir has no registry row"; exit 1; }
    echo "$exp" > "$W/expset_$tag"
    echo "  $dir -> tests/expected/$exp"
    mkdir -p "$W/$tag"
    TAGS="$TAGS $tag"
done
mkdir -p "$W/van"

echo "== 0a: a leg whose sandbox already exists is refused, never run (#293; a planted leg) =="
if ! vs_ctl_is shared-sandbox; then
    mkdir -p "$W/plant/sb_PLANT_reused"
    leg "$W/plant/PLANT_reused.field" vsavj "" "$W/no_such_replay.rpl" 10
    if [ -f "$W/plant/PLANT_reused.field.REUSED" ] && [ ! -e "$W/plant/sb_PLANT_reused/mame.log" ]; then
        vs_ctl_fired shared-sandbox "a planted leg whose sandbox existed was refused before MAME started (REUSED marker, no run)"
    else
        vs_ctl_dead shared-sandbox "a planted leg whose sandbox existed was run anyway"; fail=1
    fi
    rm -f "$W/plant/PLANT_reused.field.REUSED"
fi

echo "== 0b: a dead leg's MAME log is KEPT and shown (#233; a planted leg with no replay) =="
mkdir -p "$W/plant"
leg "$W/plant/PLANT_dead.field" vsavj "" "$W/no_such_replay.rpl" 10
if [ -f "$W/plant/PLANT_dead.field.DEAD" ] && _pk="$(cat "$W/plant/PLANT_dead.field.DEAD")" \
   && [ -s "$_pk/mame.log" ] && grep -q "no_such_replay" "$_pk/mame.log"; then
    echo "  ok plant: the dead leg is DEAD and its mame.log survives the trap, naming the cause:"
    show_dead "$W/plant/PLANT_dead.field.DEAD"
    rm -rf "$_pk"; rmdir "$DEAD_DIR" 2>/dev/null || true
else
    echo "  FAIL plant: a dead leg's log was not kept (marker: $(cat "$W/plant/PLANT_dead.field.DEAD" 2>/dev/null || echo none))"
    fail=1
fi

echo "== 1: sweep — id trajectories, vanilla vs each build (JOBS=$JOBS) =="
# each DISTINCT build once (#293): one out file and one fresh sandbox per (replay, build), never shared between ids
DIRS="$(for b in $BUILDS; do echo "${b%%:*}"; done | awk '!seen[$0]++' | tr '\n' ' ')"
vs_ctl_is shared-sandbox && DIRS="$(for b in $BUILDS; do echo "${b%%:*}"; done | tr '\n' ' ')"   # the pre-#293 rig
for rpl in "$REPO"/tests/replays/*.rpl; do
    name="$(basename "$rpl" .rpl)"
    fr=$(( $(last_frame "$rpl") + 120 ))
    want_van=0
    for dir in $DIRS; do
        tag="$(basename "$dir")"
        exp="$(cat "$W/expset_$tag")"
        if [ -f "$REPO/tests/expected/$exp/$name.skip" ]; then continue; fi
        want_van=1
        leg "$W/$tag/$name.field" vsavjw "$REPO/$dir/rompath" "$rpl" "$fr" &
        sync_pool
    done
    if [ "$want_van" = 1 ]; then
        leg "$W/van/$name.field" vsavj "" "$rpl" "$fr" &
        sync_pool
    fi
done

# The live POSITIVE CONTROL, one per set: the SAME legacy replay with the
# tenant's id poked at select must flip LEGACY -> TENANT. Without it, "every
# replay came back LEGACY" could equally mean the instrument cannot see a
# tenant at all.
for b in $BUILDS; do
    dir="${b%%:*}"; id="${b##*:}"; tag="$(basename "$dir")"
    rpl="$REPO/tests/replays/16_xemu_2p.rpl"
    fr=$(( $(last_frame "$rpl") + 120 ))
    leg "$W/$tag/CONTROL_forced_$id.field" vsavjw "$REPO/$dir/rompath" "$rpl" "$fr" \
        "1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id" &
    sync_pool
done
wait

# ---------------------------------------------------------------- section 2
echo "== 2: classify + assert coverage =="
# loads_id <field file> <hex id>: the forced leg's P1 id reads <id> on its last in-match sample (#293: each tenant's
# control is judged on ITS run, never on another id's)
loads_id() { awk -v want="$(printf '%d' "0x$2")" '$1 == "F" { id = ""; hb = 0
    for (i = 3; i <= NF; i++) { split($i, kv, "="); if (kv[1] == "p1id") id = kv[2] + 0; if (kv[1] == "p1hb") hb = kv[2] + 0 }
    if (hb != 0 && id != "") last = id } END { exit (last != "" && last == want) ? 0 : 1 }' "$1"; }
for b in $BUILDS; do
    dir="${b%%:*}"; tag="$(basename "$dir")"; id="${b##*:}"
    if [ -s "$W/$tag/CONTROL_forced_$id.field" ] && loads_id "$W/$tag/CONTROL_forced_$id.field" "$id"; then
        echo "  ok control $id: the forced-pick leg loads id 0x$id (its own run)"
    else
        echo "  FAIL control $id: the forced-pick leg does not load id 0x$id — a shared or wrong control run"; fail=1
    fi
done
# the id check refuses another tenant's run (a static plant: the first id's file judged against a different id)
_b1="$(echo $BUILDS | awk '{print $1}')"; _d1="${_b1%%:*}"; _i1="${_b1##*:}"
_other="$(for b in $BUILDS; do i="${b##*:}"; [ "$i" != "$_i1" ] && { echo "$i"; break; }; done)"
if [ -n "$_other" ]; then
    if loads_id "$W/$(basename "$_d1")/CONTROL_forced_$_i1.field" "$_other"; then
        echo "  FAIL plant: id 0x$_i1's control was accepted as id 0x$_other — the id check cannot tell tenants apart"; fail=1
    else echo "  ok plant: id 0x$_i1's control is refused as id 0x$_other"; fi
fi
_classified=""
for b in $BUILDS; do
    dir="${b%%:*}"; tag="$(basename "$dir")"; id="${b##*:}"
    exp="$(cat "$W/expset_$tag")"
    rep="$OUT/pairings_$exp.tsv"
    echo "-- $dir (tenant 0x$id) -> tests/expected/$exp --"
    verdict "$W/van/16_xemu_2p.field" "$W/$tag/CONTROL_forced_$id.field" forced-pick "$W/pos"
    if [ "$rc" = 1 ]; then
        echo "  ok control: the same replay with the tenant id poked -> TENANT"
    else
        echo "  FAIL control: poking the tenant id did not flip the verdict (rc=$rc)"
        sed 's/^/      /' "$W/pos"; fail=1
    fi
    case " $_classified " in *" $tag "*) echo "  (the sweep of $tag is classified above, once)"; continue ;; esac
    _classified="$_classified $tag"
    : > "$rep"

    # liveness + the live positive control, before any coverage verdict
    verdict "$W/van/16_xemu_2p.field" "$W/$tag/16_xemu_2p.field" liveness "$W/live"
    if [ "$rc" = 0 ] && grep -q "LEGACY" "$W/live"; then
        echo "  ok liveness: 16_xemu_2p reads LEGACY with a real fighter pair"
        sed -n '1p' "$W/live" | sed 's/^/      /'
    else
        echo "  FAIL liveness: rc=$rc — the rig is not producing matches"
        sed 's/^/      /' "$W/live"; fail=1
    fi

    nl=0; nt=0; nn=0; holes=""
    # 14z-90 (#23): the corpus below is a glob, so assert first that nothing
    # dropped out of it. Without this the sweep's coverage is whatever
    # happened to survive.
    _reused=$(ls "$W/$tag"/*.field.REUSED "$W/van"/*.field.REUSED 2>/dev/null | wc -l | tr -d ' ')
    if [ "${_reused:-0}" != 0 ]; then
        echo "FAIL: $_reused leg(s) found their sandbox already there — a carried run (#293), refused:"
        for _rm in "$W/$tag"/*.field.REUSED "$W/van"/*.field.REUSED; do [ -f "$_rm" ] && echo "        $(basename "$_rm" .field.REUSED)"; done
        fail=1
    fi
    _dead=$(ls "$W/$tag"/*.field.DEAD "$W/van"/*.field.DEAD 2>/dev/null | wc -l | tr -d ' ')
    if [ "${_dead:-0}" != 0 ]; then
        echo "FAIL: $_dead leg(s) produced no field data — those replays were"
        echo "      NOT measured, and a glob-derived corpus cannot see that:"
        for _dm in "$W/$tag"/*.field.DEAD "$W/van"/*.field.DEAD; do
            [ -f "$_dm" ] && show_dead "$_dm"
        done
        fail=1
    fi
    for f in "$W/$tag"/*.field; do
        name="$(basename "$f" .field)"
        case "$name" in CONTROL_forced*) continue ;; esac
        verdict "$W/van/$name.field" "$f" "$name" "$W/v"
        kind=none
        for k in masked pending sha1 diverge; do
            if [ -f "$REPO/tests/expected/$exp/$name.$k" ]; then kind="$k"; break; fi
        done
        case "$rc" in
        0) v=LEGACY;   nl=$((nl + 1)) ;;
        1) v=TENANT;   nt=$((nt + 1)) ;;
        2) v=NO-MATCH; nn=$((nn + 1)) ;;
        *) v=DEAD ;;
        esac
        exempt="$REPO/tests/expected/$exp/$name.legacy-exempt"
        printf '%s\t%s\t%s\n' "$name" "$v" "$kind" >> "$rep"
        if [ "$v" = DEAD ]; then
            echo "  FAIL $name: instrument dead"; sed 's/^/      /' "$W/v"; fail=1
        elif [ "$v" = LEGACY ] && [ "$kind" != masked ] && [ "$kind" != pending ]; then
            # A LEGACY verdict means only "the same fighters loaded". A rig that
            # navigates the EXTENDED WHEEL can load vanilla's fighters by
            # coincidence while having no vanilla oracle for the run at all; such
            # a replay may stay self-frozen, but only with the reason WRITTEN DOWN
            # in <set>/<name>.legacy-exempt, which is printed every run so the
            # judgement is re-made rather than inherited.
            if [ -f "$exempt" ]; then
                echo "  exempt $name (self-frozen by hand-judged reason):"
                sed 's/^/        /' "$exempt"
            else
                holes="$holes $name"
            fi
        fi
    done
    echo "  $nl LEGACY / $nt TENANT / $nn NO-MATCH   -> $rep"
    if [ -n "$holes" ]; then
        echo "  FAIL: legacy pairings guarded only by a self-frozen expectation —"
        echo "        a self-frozen log cannot see a legacy regression (14z-88):"
        for h in $holes; do
            echo "          $h ($(awk -F'\t' -v n="$h" '$1 == n { print $3 }' "$rep"))"
        done
        echo "        FIX: freeze the vanilla basis log, then author a .masked spec:"
        echo "          tools/freeze_masked_basis.sh tests/expected/vsavj/masked-v2 \\"
        echo "            \"\$(cat tests/expected/$exp/mask)\" <name>..."
        fail=1
    fi
    awk -F'\t' '$2 == "NO-MATCH" { printf "  no-match (hand-judged): %s [%s]\n", $1, $3 }' "$rep"
done

# THE SHEET (#291): with SHEET_OUT set, one sheet per replay this run classified — vanilla and our build as this run
# played them (bare, as run_suite does), at the first frame of each distinct fighter pair the verdict compares, proven
# on the four fields this run traced there. Nothing the gate decides changes.
. "$REPO/tests/lib/sheet.sh"
if sheet_on; then
    _done=""
    for b in $BUILDS; do
        dir="${b%%:*}"; tag="$(basename "$dir")"
        case " $_done " in *" $tag "*) continue ;; esac; _done="$_done $tag"
        exp="$(cat "$W/expset_$tag")"; rep="$OUT/pairings_$exp.tsv"
        while IFS='	' read -r name v kind; do
            [ -s "$W/van/$name.field" ] && [ -s "$W/$tag/$name.field" ] || continue
            rpl="$REPO/tests/replays/$name.rpl"; fr=$(( $(last_frame "$rpl") + 120 ))
            sheet_new "$tag.$name" "$name: vanilla vsavj above $tag (bare, as run_suite runs it)" - - \
                "the select wheel on our build (21 cells against vanilla's 16, by design) and a hook-cycle load phase of a frame or two (tolerated by the verdict)"
            sheet_leg "$tag.$name" vanilla vsavj vsavj "$ROMDIR" "$rpl" - "$fr"
            sheet_leg "$tag.$name" ours ours vsavjw "$REPO/$dir/rompath;$ROMDIR" "$rpl" - "$fr"
        done < "$rep"
        python3 - "$W" "$tag" "$rep" "$REPO/tests/expected/$exp" >> "$W/sheet_rows.tsv" <<'PYS'
import os, sys
W, tag, rep, expdir = sys.argv[1:5]
os.makedirs(f"{W}/sheettr", exist_ok=True)
spec = {"p1id": "ff8782:b", "p2id": "ff8b82:b", "p1hb": "ff8460:l", "p2hb": "ff8860:l"}
def trace(p):
    d = []
    for l in open(p):
        t = l.split()
        if t and t[0] == "F": d.append((int(t[1]), {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}))
    return d
def runs(d):
    out = []
    for f, s in d:
        k = (s.get("p1hb", 0), s.get("p2hb", 0))
        if not any(k): continue
        if not out or out[-1][1] != k: out.append((f, k))
    return out
for line in open(rep):
    name, v, kind = line.rstrip("\n").split("\t")
    pv, pb = f"{W}/van/{name}.field", f"{W}/{tag}/{name}.field"
    if not (os.path.getsize(pv) if os.path.exists(pv) else 0) or not (os.path.getsize(pb) if os.path.exists(pb) else 0):
        continue
    ex = " (legacy-exempt)" if os.path.exists(f"{expdir}/{name}.legacy-exempt") else ""
    verdict = "%s, expectation %s%s" % (v, kind, ex)
    tv, tb = trace(pv), trace(pb)
    dv, db = {f: s for f, s in tv}, {f: s for f, s in tb}
    rv, rb = runs(tv), runs(tb)
    sid = f"{tag}.{name}"
    if not rv and not rb:
        mom = [("end", "the last traced frame: no fighter ever loaded (NO-MATCH, judged by hand)", tv[-1][0] if tv else 0, tb[-1][0] if tb else 0, "-")]
    else:
        mom = []
        for k in range(max(len(rv), len(rb))):
            a = rv[k] if k < len(rv) else None
            b = rb[k] if k < len(rb) else None
            vals = "vanilla %s, ours %s (hitbox bases)" % ("(%X,%X)" % a[1] if a else "none", "(%X,%X)" % b[1] if b else "none")
            mom.append(("p%d" % (k + 1), "distinct fighter pair #%d" % (k + 1), a[0] if a else None, b[0] if b else None, vals))
    # S4-E (#291): each pair's own run is the frames from its first frame to the next pair's; the frames in it where a
    # round is on ($FF812D) show the pair fighting, so up to 9 of them are drawn beside the load frame the gate judged
    def inround(r, d, k, last):
        lo = r[k][0] if k < len(r) else None
        if lo is None: return []
        hi = r[k + 1][0] if k + 1 < len(r) else last + 1
        fr = [f for f in sorted(d) if lo <= f < hi and d[f].get("st", 0) != 0]
        return [fr[round(i * (len(fr) - 1) / 8)] for i in range(9)] if len(fr) > 9 else fr
    keep = {"vanilla": set(), "ours": set()}
    for mid, lab, fa, fb, vals in mom:
        print("moment\t%s\t%s\t%s\t%s\t%s" % (sid, mid, lab, verdict, vals))
        for leg, f, dd, rr, tt in (("vanilla", fa, dv, rv, tv), ("ours", fb, db, rb, tb)):
            if f is None: continue
            s = dd.get(f)
            exp = ",".join("%s=%d" % (spec[k], s[k]) for k in sorted(spec) if k in s) if s else "-"
            print("at\t%s\t%s\t%s\t%d\t%s\t%s" % (sid, mid, leg, f, "fields" if s else "none", exp))
            span = inround(rr, dd, int(mid[1:]) - 1, tt[-1][0] if tt else 0) if s and mid.startswith("p") else []
            if span:
                print("span\t%s\t%s\t%s\t%s" % (sid, mid, leg, ",".join(map(str, sorted(set(span) | {f})))))
                keep[leg] |= set(span) | {f}
    for leg, src in (("vanilla", pv), ("ours", pb)):
        if keep[leg]:                 # the gate's own trace lines at the drawn frames, nothing else
            dst = f"{W}/sheettr/{sid}.{leg}.trace"
            with open(dst, "w") as o:
                o.writelines(l for l in open(src) if l.startswith("F ") and int(l.split()[1]) in keep[leg])
            with open(f"{W}/sheettr.list", "a") as o:
                o.write("%s\t%s\t%s\n" % (sid, leg, dst))
PYS
    done
    [ -s "$W/sheettr.list" ] && while IFS='	' read -r _sid _leg _tr; do sheet_trace "$_sid" "$_leg" "$_tr" "$FIELDS"; done < "$W/sheettr.list"
    [ -s "$W/sheet_rows.tsv" ] && sheet_rows "$W/sheet_rows.tsv"
fi

if vs_ctl_is shared-sandbox; then
    if [ "$fail" = 1 ]; then vs_ctl_fired shared-sandbox "with the sweep not de-duplicated, a replay's second leg found the first one's sandbox and was refused"
    else vs_ctl_dead shared-sandbox "the duplicated sweep passed — a carried sandbox goes unseen"; fail=1; fi
fi
if [ "$fail" = 0 ]; then echo "LEGACY-PAIRING COVERAGE: PASS"; else echo "LEGACY-PAIRING COVERAGE: FAIL"; fi
exit "$fail"
