#!/bin/sh
# audit_legacy_pairings.sh — WHICH REPLAYS ARE LEGACY CONTENT, and is every
# one of them compared against VANILLA rather than against itself?
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
# (+0x382 is the char id only at SELECT; in match the engine reassigns it
# as the voice-flavor class from a sound-state-fed list, 14z-87).
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
# Default builds: the three current sets. ~30 min (225 MAME legs, JOBS-parallel).
# Section 0 (verdict controls) is static and runs first — a checker that has
# not been ground-truthed never issues a verdict.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
JOBS="${JOBS:-6}"
OUT="${PAIRINGS_OUT:-build/legacy_pairings}"
CHK="python3 $REPO/tools/check_legacy_pairings.py"
BUILDS="${*:-build/don_m14:13 build/hui48:10 build/pyron32:11}"  # re-pointed 14z-110b
FIELDS="ff8782:b:p1id,ff8b82:b:p2id,ff8460:l:p1hb,ff8860:l:p2hb"

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
# voice-flavor class the engine reassigns there (14z-87)
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
    d="$(dirname "$1")/sb_$(basename "$1" .field)"; mkdir -p "$d"
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
    [ -s "$1" ] || : > "$1.DEAD"
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

echo "== 1: sweep — id trajectories, vanilla vs each build (JOBS=$JOBS) =="
for rpl in "$REPO"/tests/replays/*.rpl; do
    name="$(basename "$rpl" .rpl)"
    fr=$(( $(last_frame "$rpl") + 120 ))
    want_van=0
    for b in $BUILDS; do
        dir="${b%%:*}"; tag="$(basename "$dir")"
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
    leg "$W/$tag/CONTROL_forced.field" vsavjw "$REPO/$dir/rompath" "$rpl" "$fr" \
        "1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id" &
    sync_pool
done
wait

# ---------------------------------------------------------------- section 2
echo "== 2: classify + assert coverage =="
for b in $BUILDS; do
    dir="${b%%:*}"; tag="$(basename "$dir")"
    exp="$(cat "$W/expset_$tag")"
    rep="$OUT/pairings_$exp.tsv"
    : > "$rep"
    echo "-- $dir -> tests/expected/$exp --"

    # liveness + the live positive control, before any coverage verdict
    verdict "$W/van/16_xemu_2p.field" "$W/$tag/16_xemu_2p.field" liveness "$W/live"
    if [ "$rc" = 0 ] && grep -q "LEGACY" "$W/live"; then
        echo "  ok liveness: 16_xemu_2p reads LEGACY with a real fighter pair"
        sed -n '1p' "$W/live" | sed 's/^/      /'
    else
        echo "  FAIL liveness: rc=$rc — the rig is not producing matches"
        sed 's/^/      /' "$W/live"; fail=1
    fi
    verdict "$W/van/16_xemu_2p.field" "$W/$tag/CONTROL_forced.field" forced-pick "$W/pos"
    if [ "$rc" = 1 ]; then
        echo "  ok control: the same replay with the tenant id poked -> TENANT"
    else
        echo "  FAIL control: poking the tenant id did not flip the verdict (rc=$rc)"
        sed 's/^/      /' "$W/pos"; fail=1
    fi

    nl=0; nt=0; nn=0; holes=""
    # 14z-90 (#23): the corpus below is a glob, so assert first that nothing
    # dropped out of it. Without this the sweep's coverage is whatever
    # happened to survive.
    _dead=$(ls "$W/$tag"/*.field.DEAD "$W/van"/*.field.DEAD 2>/dev/null | wc -l | tr -d ' ')
    if [ "${_dead:-0}" != 0 ]; then
        echo "FAIL: $_dead leg(s) produced no field data — those replays were"
        echo "      NOT measured, and a glob-derived corpus cannot see that:"
        ls "$W/$tag"/*.field.DEAD "$W/van"/*.field.DEAD 2>/dev/null \
            | sed 's|.*/||; s|\.field\.DEAD$||; s|^|        |'
        fail=1
    fi
    for f in "$W/$tag"/*.field; do
        name="$(basename "$f" .field)"
        if [ "$name" = CONTROL_forced ]; then continue; fi
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

if [ "$fail" = 0 ]; then echo "LEGACY-PAIRING COVERAGE: PASS"; else echo "LEGACY-PAIRING COVERAGE: FAIL"; fi
exit "$fail"
