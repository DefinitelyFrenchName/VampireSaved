#!/bin/sh
# audit_hitclass_map_cost.sh — what the 14z-82b hit-class map extension
# FIXES and what it COSTS legacy content (ADOPTED 14z-82c; rerunnable).
#
# THE CONSEQUENCE IS PER-INDEX, and this decides what can be a control
# (measured 14z-129, vsavj OPCODE view at PRG:0x1A88E — the map lives in the
# opcode image, which is what tools/gen_hitclass_map_thunk.py reads):
#     map[64] = 0x4e  pyron satellite  -> LOUD, the f7997 fault
#     map[67] = 0x00  pyron            -> the do-nothing default
#     map[68] = 0x12  huitzil grenade  -> SILENT (a real clash, no crash)
#     map[70] = 0x00  huitzil EX FG    -> the do-nothing default
# So only a type-64 clash can be section 0's positive control. HANDOFF's
# out-of-range doctrine: "no crash" clears a LOUD entry completely and a
# SILENT one not at all.
#
# THE DEFECT IT FIXES (measured, 14z-82b): vsavj's projectile-pool hit
# sweep maps both colliding objects' type bytes through one 64-entry byte
# map (routine PRG:0x1A888, seven callers); ported types >= 64 landing a
# hit over-index it — the f7997 vec3, LATENT IN THE FROZEN pyron BUILD
# ITSELF (pyron20 + 70_pyron_mash + the forced-pick pokes crashes at
# f7997 with no probes and no merge; huitzil spawns types 68/72 into the
# same pool and shares the exposure; donovan's 59-63 fit the map).
#
# THE FIX (ADOPTED 2026-08-12, 14z-82c — the manifests carry the row;
# build/pyron21 = pyron-m3 is byte-identical to the originally measured
# probe build): the generated site_thunk body
# (tools/gen_hitclass_map_thunk.py — vanilla's 64 bytes verbatim + vs2's
# 16 extension entries + a loud >=80 ILLEGAL). This audit re-measures the
# adoption numbers on demand against a NO-THUNK TWIN built from the CURRENT
# manifest (see "THE REFERENCE IS BUILT, NOT KEPT" below — the old
# build/pyron20 reference was retired 14z-92, both because it no longer
# boots and because it had stopped being a control).
#
# Sections:
#   0  build the CURRENT pyron vertical (pyron.toml verbatim — it carries
#      the row since 14z-82c) AND a no-thunk twin, then prove THE FIX on
#      tests/replays/pyron/84_pyron_clash_type64.rpl: it must END clean WITH
#      the thunk and CRASH WITHOUT it. The crash half is the positive
#      control — an END-clean run alone cannot tell a fix from a rig that
#      stopped firing the move.
#      RIG CHANGED 14z-129: the control used to ride the 11,017-frame chaos
#      soak and expected the f7997 crash. The soak stopped reaching the map
#      at all (section 4: total=0), so the control was DEAD for sessions and
#      this gate refused a verdict — correctly. What was missing was
#      CONTACT: the sweep is POOL-vs-POOL, so a tenant projectile hitting a
#      FIGHTER never transits the map, and the 37-leg census put 107 objects
#      of type >= 64 into the pool with ZERO map entries. The new rig adds
#      the opposing PROJECTILE and lands 14 dispatches at map index 0x40.
#      GUARD_DEBUG=1 is load-bearing (cheap mode sees no vec3).
#   1  LEGACY COST: live A/B fix-vs-no-thunk-twin whole-RAM checksums over
#      THE WHOLE LEGACY CORPUS. The builds differ by ONLY the thunk BY
#      CONSTRUCTION (same manifest, one row stripped), so any
#      divergence is the thunk's cycle cost where legacy hits transit
#      the map. Identical = zero observable cost on that replay;
#      divergent = the run-shape report is the maintainer's input.
#   2  FIRE CENSUS: how often legacy content actually enters the map
#      routine (probe at the placed body, D0 = the map index) — the
#      denominator for section 1's verdict, over the SAME corpus. Since
#      14z-93 the indices are BINNED (in-domain / vs2 extension / trap),
#      so the fix's safety argument is stated by the instrument.
#   3  TENANT FIRE CENSUS (14z-93): the other half — how often a TENANT
#      enters the map with an index >= 64, plus the SPAWN DENOMINATOR
#      (how many type >= 64 objects entered the pool at all). That is what
#      the thunk BUYS, and no section measured it before. Huitzil + Pyron
#      only (donovan.toml does not declare the row: his types 59-63 fit).
#      RESULT 14z-93: 0 map entries over 37 rigs against 121 pooled
#      dangerous objects — the gap is CONTACT, not absence. On that basis
#      the maintainer ruled **KEEP the thunk** (2026-08-16). This section
#      is now a REGRESSION GATE on that ruling, not an open question:
#      the only measurement that would reopen it is a pool-vs-pool
#      contact rig scoring 0 extension entries.
#   4  WHY THE SOAK IS NO LONGER THE CONTROL. Same probe on the soak rig,
#      separating "the over-index still happens, the address moved" from
#      "the rig stopped producing the event". It answered the second
#      (total=0), which is what sent 14z-129 to build the clash rig section
#      0 now uses. Kept as the standing check that the soak's own map
#      transit is still zero — if it ever returns, that is a finding.
#
# WHAT SECTIONS 3-4 CANNOT DO, STATED UP FRONT. The hit sweep is
# POOL-vs-POOL, so a tenant projectile hitting a FIGHTER never transits
# this map (measured; tests/replays/hui/88_hui_plasma_trap_contact.rpl was
# authored to force a pool-vs-pool contact and scored ZERO on both cuts).
# A tenant zero here therefore has two possible meanings and the section
# reports them as two verdicts, never one: "enters and stays below 64" is
# a result; "no rig produced the event" is a gap in the RIGS. Collapsing
# them is the exact coverage artefact that produced the retracted
# "legacy never enters the map" claim.
#
# WIDENED 14z-92 (M4): both sections ran on a hardcoded FOUR replays
# (section 1) and TWO (section 2). `hitclass_map_extend` is ADOPTED and
# live on a SHARED ENGINE SITE — vsavj's projectile hit sweep, seven
# callers — so "legacy never enters the map" was a load-bearing claim
# resting on two replays. That is the same coverage shape that produced
# the 14z-89 legacy regression (a self-frozen spec cannot see what it
# never runs), and it is the reason M4 was filed. The corpus is now the
# LEGACY PAIRINGS themselves: every replay carrying a `.masked` spec,
# i.e. every replay measured against the vanilla basis. 4 -> 46 on
# section 1, 2 -> 46 on section 2.
#
# The set is RESOLVED, not pinned, and the resolution is PRINTED — a gate
# that names a frozen build by path goes stale silently at the next
# re-freeze (paid for in 14z-92: test_merged_render_content had named
# build/hui31 and produced no huitzil measurement for six sessions;
# docs/project/gotchas.md "A frozen build stops being a usable REFERENCE").
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=6] [HITCLASS_SET=pyron-mN]
#        [HITCLASS_REPLAYS="a b c"] [HITCLASS_TENANT_ONLY=1]
#        [HITCLASS_TENANT_REPLAYS="hui/70_hui_mash ..."]
#        tests/audit_hitclass_map_cost.sh
# On-demand: 3 builds + 2 soaks + 2*N checksum runs + N legacy probe runs
# + 37 tenant probe runs + 2 armed-probe controls + 1 soak probe,
# JOBS-parallel. NO WALL-CLOCK FIGURE IS QUOTED HERE ON PURPOSE — the one
# in HANDOFF went stale the moment the corpus grew 4 -> 46 and was still
# being read a session later. Budget on the work formula, and poll the
# process rather than trusting a completion notice.
# HITCLASS_TENANT_ONLY=1 skips sections 1 and 2 (the 2*N + N legacy runs)
# so section 3 can be iterated; section 0 still runs because section 3
# needs its build and its $BODY.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-82b ON-DEMAND (NO minute figure on purpose — the "~20 min" here was
#   measured on the 4+2 replay version and was still being read a session
#   after the corpus grew to 46. Budget on the work formula in the script
#   header; poll the process): the adoption numbers on a PROBE build — the
#   11,017-frame soak that crashes frozen pyron-m2 must END clean; legacy A/B
#   bit-identical (measured: 30,284 frames, zero divergence); fire census.
#   REWRITTEN 14z-92 (M4): corpus-wide (46 legacy pairings, was 4 + 2), the
#   reference is now a NO-THUNK TWIN built from the current manifest (the old
#   build/pyron20 no longer boots AND had stopped being a control), and the
#   crash soak has a positive control. RESULT: the "legacy enters the map 0
#   times" claim is FALSIFIED — 230 entries over 2 replays, all indices < 64,
#   so legacy gets vanilla answers; 43/46 bit-identical. Never freezes the
#   probe. EXTENDED 14z-93 with the OTHER HALF: section 3 is the TENANT fire
#   census (what the thunk BUYS, the number M4 left open), all 37 hui+pyron
#   rigs on verticals built from the CURRENT manifests, indices binned in-
#   domain / vs2-extension / trap. Huitzil+Pyron only — donovan.toml does not
#   declare the row. Section 4 diagnoses section 0's dead crash control with
#   the same probe. THE THREE VERDICTS ARE KEPT APART BY DESIGN: "reaches the
#   extension", "enters but stays below 64", and "NO RIG PRODUCES THE EVENT"
#   (the sweep is POOL-vs-POOL, so a tenant projectile hitting a FIGHTER never
#   transits the map) mean different things, and folding them is what produced
#   the retracted claim. HITCLASS_TENANT_ONLY=1 skips 1+2. Verdict logic
#   ground-truthed by tests/test_classify_hitclass_probe.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN

# THE REFERENCE IS BUILT, NOT KEPT (rewritten 14z-92, M4). It used to be
# build/pyron20 — the frozen pre-fix artifact — and BOTH of that reference's
# properties had rotted:
#   1. IT NO LONGER BOOTS. pyron20 predates WIDE v1.1/v1.2, so MAME refuses
#      it outright ("vsw.22m WRONG CHECKSUMS: EXPECTED CRC(dec0de3b) FOUND
#      CRC(1147406a)", "Required files are missing"). Every leg of section 1
#      died. Same class as the hui31 reference in
#      test_merged_render_content, measured the same day; see
#      docs/project/gotchas.md "A frozen build stops being a usable
#      REFERENCE when the profile bumps".
#   2. WORSE, THE PREMISE WAS FALSE. This audit's whole claim is that the
#      two builds "differ by ONLY the thunk, so any divergence is the
#      thunk's cycle cost". pyron.toml has changed SIX times since the
#      pyron-m2 freeze — the hitclass adoption itself, per-tenant sfx
#      records, the FG damage reconciliation, the M5 voice batch, the
#      voice-borrow fix and the 14z-91 walker relocation. Had the reference
#      still booted, this audit would have attributed six sessions of
#      unrelated change to the thunk and printed it as a cost measurement.
#      A reference that is not rebuilt from the SAME manifest is not a
#      control; it is a second variable.
# So the reference is now BUILT FROM THE CURRENT MANIFEST WITH THE THUNK
# ROW STRIPPED (the tools/probe_hook_removal.sh technique, 14z-89). The A/B
# then isolates the thunk BY CONSTRUCTION, and the no-thunk twin doubles as
# the crash positive control: the soak must END clean WITH the thunk and
# CRASH at f7997 WITHOUT it, on builds that differ by nothing else.
WIDE_ZIP="${WIDE_ROMSET:-$PWD/build/wide0/rompath/vsavjw.zip}"
if [ ! -x "$MAME_BIN" ] || [ ! -f "$WIDE_ZIP" ]; then
    echo "SKIP: need the WIDE MAME binary and a WIDE overlay romset"
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }

JOBS="${JOBS:-6}"
pool=0
sync_pool() { pool=$((pool + 1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi; }

# classify <probe log> — read one guarded-run log through the ground-truthed
# classifier (tools/classify_hitclass_probe.py, gated by
# tests/test_classify_hitclass_probe.sh). Sets $crc (0 OK / 1 DEAD /
# 2 CAPPED / 3 CRASH) plus $c_st $c_total $c_ext $c_trap $c_vals.
#
# It is a function and not four greps because the states it separates are
# the ones that make a zero mean different things — see the tool's header.
classify() {
    crc=0
    _o="$(python3 tools/classify_hitclass_probe.py "$1" 2>&1)" || crc=$?
    set -- $_o
    c_st="${1:-DEAD}"; c_total="${2#total=}"; c_ext="${3#ext=}"
    c_trap="${4#trap=}"; c_vals="${5#vals=}"
    # A tool that failed to run at all must not present as a clean zero.
    case "$c_total" in ''|*[!0-9]*) c_st=DEAD; c_total=0; c_ext=0; c_trap=0
                                    c_vals="-"; crc=1 ;; esac
    return 0
}

# THE LEGACY CORPUS (14z-92, M4) — resolved and printed, never pinned.
if [ -n "${HITCLASS_SET:-}" ]; then
    SET_DIR="tests/expected/$HITCLASS_SET"
else
    SET_DIR="$(ls -d tests/expected/pyron-m* 2>/dev/null | sort -V | tail -1)"
fi
[ -n "${SET_DIR:-}" ] && [ -d "$SET_DIR" ] || {
    echo "FAIL: no pyron expectation set found (looked for"
    echo "      tests/expected/pyron-m*); set HITCLASS_SET=<name>"; exit 1; }
CORPUS="${HITCLASS_REPLAYS:-}"
if [ -z "$CORPUS" ]; then
    for f in "$SET_DIR"/*.masked; do
        [ -e "$f" ] || continue
        n="$(basename "$f" .masked)"
        [ -f "tests/replays/$n.rpl" ] && CORPUS="$CORPUS $n"
    done
fi
NCORP=0; for _ in $CORPUS; do NCORP=$((NCORP + 1)); done
[ "$NCORP" -gt 0 ] || {
    echo "FAIL: legacy corpus is EMPTY from $SET_DIR — a zero-replay audit"
    echo "      would print PASS while measuring nothing"; exit 1; }
echo "== corpus: $NCORP legacy pairings from $SET_DIR (JOBS=$JOBS) =="

echo "== 0: build the current pyron vertical (pyron.toml verbatim) =="
grep -q 'name = "hitclass_map_extend"' build/manifest/pyron.toml || {
    echo "FAIL: pyron.toml no longer carries hitclass_map_extend — the"
    echo "      adopted fix was removed; this audit's premise is gone"
    exit 1; }
KEY_SET=vsavj TENANT_MANIFEST=build/manifest/pyron.toml \
TENANT_CHAR=0x11 WIDE_ROMSET="$WIDE_ZIP" \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 "$WORK/fix" > "$WORK/build.log" 2>&1 || {
    echo "FAIL: probe build errored"; tail -10 "$WORK/build.log"; exit 1; }
BODY="$(sed -n 's/^code *0x0*\([0-9a-f]*\) .*site_thunk hitclass_map_extend.*/\1/p' \
        "$WORK/fix/patch/patch_notes_fragment.md" | head -1)"
[ -n "$BODY" ] || { echo "FAIL: thunk body not in the fragment"; exit 1; }
echo "  ok: built; body at 0x$BODY"

> "$WORK/nothunk.toml"
NAMES="hitclass_map_extend" SRC="build/manifest/pyron.toml" \
python3 - "$WORK/nothunk.toml" <<'PY' || { echo "FAIL: strip"; exit 1; }
import os, sys
drop = set(os.environ["NAMES"].split())
lines = open(os.environ["SRC"]).read().split("\n")
out, i, removed = [], 0, []
while i < len(lines):
    if lines[i].strip() == "[[site_thunk]]":
        k, name = i + 1, None
        while k < len(lines) and not (lines[k].startswith("[[") or
              (lines[k].startswith("[") and lines[k].rstrip().endswith("]"))):
            if lines[k].startswith("name = ") and name is None:
                name = lines[k].split('"')[1]
            k += 1
        if name in drop:
            removed.append(name); i = k; continue
    out.append(lines[i]); i += 1
open(sys.argv[1], "w").write("\n".join(out))
missing = drop - set(removed)
if missing:
    sys.exit("NOT FOUND in the manifest: " + ", ".join(sorted(missing)))
print("  removed from the twin: " + ", ".join(removed))
PY
KEY_SET=vsavj TENANT_MANIFEST="$WORK/nothunk.toml" \
TENANT_CHAR=0x11 WIDE_ROMSET="$WIDE_ZIP" \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 "$WORK/nothunk" > "$WORK/build2.log" 2>&1 || {
    echo "FAIL: no-thunk twin build errored"; tail -10 "$WORK/build2.log"; exit 1; }
echo "  ok: no-thunk twin built (same manifest, hitclass_map_extend stripped)"
# NON-VACUITY (14z-92). If stripping the row produced the SAME image, then
# section 1's "bit-identical" verdict would be measuring one build against
# itself and would pass no matter what. Two identical dumps read as
# agreement (RH-18). Assert the twin really is a different program.
FP_FIX="$(sed -n 's/^build fingerprint: //p' "$WORK/build.log"  | tail -1)"
FP_NOT="$(sed -n 's/^build fingerprint: //p' "$WORK/build2.log" | tail -1)"
if [ -z "$FP_FIX" ] || [ -z "$FP_NOT" ]; then
    echo "  FAIL: could not read both build fingerprints — cannot prove the"
    echo "        A/B is non-vacuous"; fail=1
elif [ "$FP_FIX" = "$FP_NOT" ]; then
    echo "  FAIL: VACUOUS A/B — the no-thunk twin is byte-identical to the"
    echo "        fix build ($FP_FIX). Stripping hitclass_map_extend changed"
    echo "        nothing, so section 1 would compare a build with itself."
    fail=1
else
    echo "  ok: A/B is non-vacuous — fix $FP_FIX != twin $FP_NOT"
fi

# THE RIG IS THE POOL-VS-POOL CLASH, NOT THE MASH SOAK (14z-129).
# The soak (70_pyron_mash) stopped reaching the map at all — section 4
# measured total=0 — so its crash control was DEAD and this gate correctly
# refused a verdict rather than pass on an END-clean run that proved
# nothing. What was missing was CONTACT, not exposure: the 37-leg census put
# 107 objects of type >= 64 into the pool and entered the map zero times,
# because the sweep is POOL-vs-POOL and a tenant projectile hitting a
# FIGHTER never transits it. 84_pyron_clash_type64 supplies the opposing
# PROJECTILE (P2 Demitri flares through Pyron's satellite spawns) and lands
# 14 dispatches at map index 0x40 — the LOUD one, map[64] = 0x4e.
# The soak still runs below as the LEGACY-COST leg; it is simply no longer
# asked to be the control it can no longer be.
CLASH_POKES="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;1400:ff8b82:01;1450:ff8b82:01;1500:ff8b82:01"
# The 1P forced-pick string for pyron. Section 0 no longer uses it (its rig is
# the 2P clash above), but sections 3 and 4 DO — it is the census corpus row
# for pyron/70_pyron_mash and the probe string for section 4's standing check.
# Keep it defined HERE: section 3's table comment says "PYR_SOAK is defined up
# in section 0", and the table is expanded with `eval`, so an undefined name
# does not fail loudly — it silently empties the corpus (measured 14z-129:
# removing it collapsed section 3 to "0 tenant rigs" and still printed a
# verdict shaped like a result).
PYR_SOAK="1704:ff8782:11;1760:ff8782:11;1900:ff8782:11;2100:ff8782:11;2400:ff8782:11"
# The two 14z-129 CLASH rigs are 2P and poke BOTH sides (P1 tenant, P2 Demitri
# 0x01 for the opposing flare). CLASH_POKES above is pyron's; this is huitzil's.
HUI_CLASH="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:01;1450:ff8b82:01;1500:ff8b82:01"
clash() {  # clash <build> <out> — GUARD_DEBUG=1 is LOAD-BEARING: cheap mode
           # installs no exception breakpoints, so the twin's vec3 is
           # INVISIBLE there and both legs report END 5020 (measured 14z-129).
    GUARD_DEBUG=1 POKES="$CLASH_POKES" \
        MAME_ROMPATH="$(abspath "$1")/rompath;$ROMDIR" \
        tools/run_replay_guarded.sh vsavjw \
        tests/replays/pyron/84_pyron_clash_type64.rpl \
        "$2" "$2.box" >/dev/null 2>&1 || true
}
clash "$WORK/fix"     "$WORK/clash.log"
clash "$WORK/nothunk" "$WORK/clash_nothunk.log"
# THE POSITIVE CONTROL IS NOT OPTIONAL: an END-clean run proves nothing
# unless the same rig CRASHES without the thunk. Otherwise "no crash" may
# mean the rig stopped firing the move (the downgrade class, paid for
# repeatedly on this project — and paid for by THIS control, which sat dead
# from the moment the soak's trajectory drifted off the map).
ctl_live=1
if grep -q "^CRASH" "$WORK/clash_nothunk.log"; then
    echo "  ok: CONTROL — without the thunk the clash CRASHES" \
         "($(grep -m1 '^CRASH' "$WORK/clash_nothunk.log" | cut -c1-60))"
else
    echo "  FAIL: CONTROL DEAD — the clash did NOT crash on the no-thunk twin,"
    echo "        so an END-clean run on the fix build proves nothing about"
    echo "        the thunk. Check the map index the rig reaches (section 3's"
    echo "        probe): only map[64] = 0x4e is LOUD. A clash at a SILENT"
    echo "        index (huitzil's 68 = 0x12) cannot be this control —"
    echo "        tests/replays/hui/96_hui_grenade_clash.rpl records that."
    grep -E "^(CRASH|END)" "$WORK/clash_nothunk.log" | head -3
    ctl_live=0
    fail=1
fi
if grep -q "^END 5020" "$WORK/clash.log" \
        && ! grep -q "^CRASH" "$WORK/clash.log"; then
    # 14z-93: this message used to read "the soak that crashes the no-thunk
    # twin at f7997 runs END-clean" UNCONDITIONALLY — so on a dead control it
    # asserted the crash two lines under the branch that had just reported
    # there wasn't one. A success line must not restate the premise the
    # control failed to establish.
    if [ "$ctl_live" = 1 ]; then
        echo "  ok: THE FIX HOLDS — the clash that crashes the no-thunk twin"
        echo "      at its FIRST index-64 dispatch runs END-clean here"
    else
        echo "  note: the clash runs END-clean on the fix build — but with the"
        echo "        control DEAD that is not evidence about the thunk, only"
        echo "        that this rig does not crash."
    fi
else
    echo "  FAIL: the clash did not complete clean on the fix build:"
    grep -E "^(CRASH|END)" "$WORK/clash.log" | head -3
    fail=1
fi

if [ "${HITCLASS_TENANT_ONLY:-0}" = 1 ]; then
    echo "== 1: LEGACY COST — SKIPPED (HITCLASS_TENANT_ONLY=1) =="
    n_ok=0; n_div=0; n_dead=0
else
echo "== 1: LEGACY COST — A/B fix vs the NO-THUNK TWIN =="
run() {  # run <build> <replay> <out> — explicit per-leg sandbox: these run
         # in PARALLEL, and two legs sharing a MAME sandbox inherit each
         # other's EEPROM (the defect fixed in freeze_masked_basis.sh,
         # 14z-91). $WORK is cleaned by the trap.
    sb="$3.sb"; mkdir -p "$sb"
    MAME_ROMPATH="$(abspath "$1")/rompath;$ROMDIR" \
        tools/run_replay_mame.sh vsavjw "tests/replays/$2.rpl" "$3" "$sb" \
        >/dev/null 2>&1 || true
}
for R in $CORPUS; do
    run "$WORK/nothunk" "$R" "$WORK/l_${R}_ref" &
    sync_pool
    run "$WORK/fix"  "$R" "$WORK/l_${R}_new" &
    sync_pool
done
wait
n_ok=0; n_div=0; n_dead=0
for R in $CORPUS; do
    # A leg that never produced a log must NOT read as "identical" — two
    # empty files compare equal (14z-90 issue #23, the same trap in
    # audit_legacy_pairings). Absent/empty is DEAD and fails the audit.
    if [ ! -s "$WORK/l_${R}_ref" ] || [ ! -s "$WORK/l_${R}_new" ]; then
        echo "  DEAD: $R — a leg produced no checksum log (not a verdict)"
        n_dead=$((n_dead + 1)); fail=1; continue
    fi
    if cmp -s "$WORK/l_${R}_ref" "$WORK/l_${R}_new"; then
        n_ok=$((n_ok + 1))
    else
        echo "  DIVERGES: $R — the thunk's cycle cost reached legacy state;"
        echo "        shape (maintainer input, not a gate):"
        python3 tools/analyze_divergence.py "$WORK/l_${R}_ref" \
            "$WORK/l_${R}_new" 2>&1 | sed 's/^/        /' | head -8
        n_div=$((n_div + 1)); fail=1
    fi
done
echo "  $n_ok/$NCORP bit-identical, $n_div divergent, $n_dead dead"
fi

if [ "${HITCLASS_TENANT_ONLY:-0}" = 1 ]; then
    echo "== 2: FIRE CENSUS — SKIPPED (HITCLASS_TENANT_ONLY=1) =="
else
echo "== 2: FIRE CENSUS — how often legacy content enters the map =="
for R in $CORPUS; do
    ( POKES="" MAME_ROMPATH="$(abspath "$WORK/fix")/rompath;$ROMDIR" \
      GUARD_PROBE="$BODY" GUARD_PROBE_MAX=20000 \
        tools/run_replay_guarded.sh vsavjw "tests/replays/$R.rpl" \
        "$WORK/f_$R.log" "$WORK/fbox_$R" >/dev/null 2>&1 || true ) &
    sync_pool
done
wait
tot=0; tot_ext=0; tot_trap=0; c_dead=0; seen_vals=""
for R in $CORPUS; do
    # A guarded run that never started logs nothing, and "0 map entries"
    # from a dead rig is indistinguishable from a real zero — the trap this
    # project has paid for repeatedly. Require the run to have COMPLETED.
    # 14z-93: the completeness check, the index binning and the CAP check
    # all moved into tools/classify_hitclass_probe.py, which is
    # ground-truthed by tests/test_classify_hitclass_probe.sh. The old
    # `grep -q '^END '` could not see a PROBE-CAP truncation, and the old
    # value list was raw hex nobody binned — the "all indices < 64"
    # conclusion lived only in prose (docs/game/engine_internals.md).
    classify "$WORK/f_$R.log"
    n_total="$c_total"; n_ext="$c_ext"; n_trap="$c_trap"; vals="$c_vals"
    case "$crc" in
        1) echo "  DEAD: $R — guarded run did not complete; its zero is not evidence"
           c_dead=$((c_dead + 1)); fail=1; continue ;;
        3) echo "  CRASH: $R — the guard tripped on the FIX build; not a census result"
           c_dead=$((c_dead + 1)); fail=1; continue ;;
        2) echo "  CAPPED: $R — hit GUARD_PROBE_MAX; total is a FLOOR, not a count"
           fail=1 ;;
    esac
    tot=$((tot + n_total)); tot_ext=$((tot_ext + n_ext))
    tot_trap=$((tot_trap + n_trap))
    if [ "$n_total" -gt 0 ]; then
        echo "  $R: $n_total map entries ($n_ext ext >=0x40, $n_trap trap >=0x50); D0: $vals"
        seen_vals="$seen_vals $vals"
    fi
done
echo "  corpus total: $tot map entries over $NCORP replays ($c_dead dead)"
echo "                $tot_ext at index >=0x40, $tot_trap at index >=0x50"
if [ "$tot" = 0 ]; then
    echo "  => legacy content NEVER enters the map on this corpus"
elif [ "$tot_ext" = 0 ] && [ "$tot_trap" = 0 ]; then
    # THE ADOPTED FIX'S ACTUAL SAFETY ARGUMENT, stated by the instrument
    # rather than by prose. Retracted 14z-92: it is NOT "legacy never
    # enters" (it enters 230 times) — it is "legacy enters constantly and
    # receives VANILLA's own bytes", because the thunk body is vanilla's 64
    # entries verbatim below 0x40.
    echo "  => legacy ENTERS ($tot times) but stays inside vanilla's 64"
    echo "     entries, so it reads vanilla's own bytes out of the thunk."
else
    echo "  => LEGACY REACHES THE EXTENSION ($tot_ext ext / $tot_trap trap)."
    echo "     This contradicts the adopted fix's safety argument and is a"
    echo "     STOP-AND-ESCALATE, not a tolerance: legacy would be reading"
    echo "     vs2's bytes where vanilla read its own."
    fail=1
fi
echo "  (guarded runs are never checksum-compared — the census is a"
echo "   denominator for section 1, not a divergence source)"
fi

# ---------------------------------------------------------------- section 3
# THE TENANT SIDE (14z-93). Sections 1-2 measure what the thunk costs
# LEGACY. This measures what it BUYS — how often a tenant enters the map
# with an index >= 64, and how many dangerous objects reach the pool at all.
#
# THE RULING THIS GATE NOW PROTECTS (maintainer, 2026-08-16): **KEEP
# `hitclass_map_extend`**, on the measured asymmetry — 0 map entries over
# 37 rigs, but 121 pooled objects of type >= 64, so the gap is CONTACT
# rather than absence, and each of those 121 is one collision away from
# indexing past vanilla's 64 entries. Cost of keeping is bounded and
# measured (section 1: 43/46 bit-identical; section 2: all legacy indices
# far below 64). Cost of dropping is the f7997 vec3.
#
# So a future run that reports 0 spawns as well as 0 entries is a
# REGRESSION IN THE RIGS, not evidence for dropping the row.
#
# SCOPE IS HUITZIL + PYRON, BY CONSTRUCTION. Donovan's projectile types are
# 59-63, they fit vanilla's 64-entry map, and donovan.toml deliberately does
# not declare this row — there is no thunk on his build to probe. Stated
# rather than silently omitted.
#
# WHAT A ZERO WOULD AND WOULD NOT MEAN. The hit sweep is POOL-vs-POOL: both
# loop registers stride pool slots, so a tenant projectile hitting a FIGHTER
# never transits this map (measured, tests/replays/hui/88_hui_plasma_trap_contact.rpl).
# That replay was authored to produce a pool-vs-pool contact and scored 0 map
# entries on both of its cuts. So "0 ext" and "no rig produces the event at
# all" are DIFFERENT results and the section reports them as such — folding
# them together is precisely the coverage artefact that produced the
# retracted "legacy never enters" claim.
echo
echo "== 3: TENANT FIRE CENSUS — does a tenant reach the extension? =="

# THE HUITZIL VERTICAL. Built from the CURRENT manifest for the same reason
# section 0's twin is (":86-87 — a reference that is not rebuilt from the
# SAME manifest is not a control; it is a second variable"), and NOT from
# build/hui41: a frozen build stops being a usable reference the moment the
# profile bumps (docs/project/gotchas.md; it cost this audit its pyron20
# reference and cost test_merged_render_content six sessions of huitzil
# coverage).
grep -q 'name = "hitclass_map_extend"' build/manifest/huitzil.toml || {
    echo "FAIL: huitzil.toml no longer carries hitclass_map_extend"; exit 1; }
KEY_SET=vsavj TENANT_MANIFEST=build/manifest/huitzil.toml \
TENANT_CHAR=0x10 WIDE_ROMSET="$WIDE_ZIP" \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 "$WORK/hfix" > "$WORK/build3.log" 2>&1 || {
    echo "FAIL: huitzil vertical build errored"; tail -10 "$WORK/build3.log"; exit 1; }
HBODY="$(sed -n 's/^code *0x0*\([0-9a-f]*\) .*site_thunk hitclass_map_extend.*/\1/p' \
        "$WORK/hfix/patch/patch_notes_fragment.md" | head -1)"
[ -n "$HBODY" ] || { echo "FAIL: huitzil thunk body not in the fragment"; exit 1; }
echo "  ok: huitzil vertical built; body at 0x$HBODY (pyron's at 0x$BODY)"

# THE CORPUS. An explicit table, NOT a glob: every tenant rig needs its own
# forced-pick string (mash / fx / cosmo / 2p windows differ), and a poke that
# misses yields a legitimate-looking zero from the WRONG character — the
# test_pyron_ladder failure, which was green while building Donovan (#84).
# 21 of the 37 rows carry their string in the replay's own header; the rest
# are copied from the gate that drives that replay, named per row.
# ALL 37, not a sample: a two-replay census is exactly what produced the
# claim this section exists to replace.
HUI_SOAK="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10"
HUI_FX="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"
HUI_2P="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
HUI_EX="$HUI_SOAK;3000:ff8509:09"
HUI_FG="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;3000:ff8509:03;3020:ff8509:03"
PYR_2P="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
PYR_PICK="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11"

tenant_rows() {   # <tenant-key>|<replay>|<pokes>   — tenant key h or p
cat <<ROWS
h|hui/70_hui_mash|$HUI_SOAK
h|hui/71_hui_ex_fg|$HUI_FG
h|hui/72_hui_ex_es|$HUI_EX
h|hui/73_hui_ex_fg_close|$HUI_EX
h|hui/74_hui_walk|$HUI_SOAK
h|hui/75_hui_air|$HUI_SOAK
h|hui/76_hui_hcb|$HUI_FX
h|hui/77_hui_fg_whiff|$HUI_EX
h|hui/78_hui_fg_chaos|$HUI_EX
h|hui/79_hui_airdash|$HUI_SOAK
h|hui/80_hui_grab_2p|$HUI_FX
h|hui/81_hui_rw_gc|$HUI_FX
h|hui/82_hui_df_2p|$HUI_FX
h|hui/83_hui_fx|$HUI_FX
h|hui/83b_hui_ray_2p|$HUI_FX
h|hui/83c_hui_grenade_2p|$HUI_2P
h|hui/83d_hui_grenade_ground|$HUI_2P
h|hui/85_hui_df_vs2|$HUI_2P;3100:ff8509:03;3120:ff8509:03
h|hui/86_hui_beam_variants|$HUI_2P;3100:ff8509:03;3400:ff8509:03;3700:ff8509:03
h|hui/87_hui_plasma_trap|$HUI_2P
h|hui/88_hui_plasma_trap_contact|$HUI_2P
h|hui/89_hui_ex_fg_vs2|$HUI_2P;3100:ff8509:03;3120:ff8509:03;3900:ff8509:03;4300:ff8509:03
h|hui/90_hui_oracle|$HUI_FX;2360:ff80d4:42;2360:ff80d5:42;2500:ff8509:09
h|hui/92_hui_trap_shock|$HUI_2P
h|hui/96_hui_grenade_clash|$HUI_CLASH
p|pyron/70_pyron_mash|$PYR_SOAK
p|pyron/84_pyron_clash_type64|$CLASH_POKES
p|pyron/71_pyron_cosmo|$PYR_PICK;3000:ff8509:03;3020:ff8509:03
p|pyron/72_pyron_cosmo_2p|$PYR_2P;3300:ff8509:03;3700:ff8509:03;4100:ff8509:03
p|pyron/73_pyron_air_214p|$PYR_2P
p|pyron/74_pyron_air_214p_sweep|$PYR_2P
p|pyron/75_pyron_air_sweep|$PYR_2P
p|pyron/76_pyron_blink_vs2|$PYR_2P
p|pyron/77_pyron_cosmo_storm|$PYR_PICK;3300:ff8509:09;3700:ff8509:09;4100:ff8509:09;4500:ff8509:09;4900:ff8509:09;5300:ff8509:09;5700:ff8509:09;6100:ff8509:09;6500:ff8509:09;6900:ff8509:09;7300:ff8509:09;7700:ff8509:09
p|pyron/78_pyron_cosmo_hold|$PYR_PICK;3000:ff8509:09;3300:ff8509:09
p|pyron/79_pyron_cosmo_realpick|3000:ff8509:09;3300:ff8509:09
p|pyron/80_pyron_cosmo_pairsweep|$PYR_PICK;3300:ff8509:09;3900:ff8509:09;4500:ff8509:09;5100:ff8509:09;5700:ff8509:09;6300:ff8509:09
p|pyron/81_pyron_cosmo_repro|$PYR_PICK;3300:ff8509:09
p|pyron/82_pyron_cosmo_twice|$PYR_PICK;3300:ff8509:09;3900:ff8509:09
ROWS
}

# TABLE INTEGRITY, BEFORE ANY LEG RUNS. Every row must name a replay that
# exists and carry a non-empty pick poke. The rows interpolate shell
# variables (PYR_SOAK is defined up in section 0), so a reorder or a typo
# would yield an EMPTY poke — and a leg with no forced pick still runs, still
# ends cleanly, and reports a confident zero for the wrong character. That is
# the #84 shape, and it is cheaper to refuse here than to explain later.
for row in $(tenant_rows); do
    case "$row" in *\|*\|*) ;; *) echo "FAIL: malformed corpus row [$row]"; exit 1 ;; esac
    _r="${row#*|}"; _rpl="${_r%%|*}"; _pk="${_r#*|}"
    [ -f "tests/replays/$_rpl.rpl" ] || {
        echo "FAIL: corpus row names a missing replay: $_rpl"; exit 1; }
    case "$_rpl" in
        # THE ONE NAMED EXEMPTION. 79_pyron_cosmo_realpick picks Pyron
        # through the WHEEL rather than by poke — that is the whole point of
        # the rig (it is the "does the real select path reach him" control),
        # so requiring a pick poke would break it. Its legitimacy is checked
        # downstream instead, by the $FF8460 hitbox-base read: if the real
        # pick failed, the leg reports NO-MATCH or a stray base, not a zero.
        pyron/79_pyron_cosmo_realpick) ;;
        *) case "$_pk" in
               *ff8782*) ;;
               *) echo "FAIL: corpus row $_rpl has no P1 pick poke [$_pk] — an"
                  echo "      unpoked leg measures whatever the cursor landed on"
                  exit 1 ;;
           esac ;;
    esac
done
TROWS="$(tenant_rows | grep -c '^[hp]|' || true)"
if [ -n "${HITCLASS_TENANT_REPLAYS:-}" ]; then
    echo "  corpus: RESTRICTED to [$HITCLASS_TENANT_REPLAYS] (iteration mode)"
else
    echo "  corpus: $TROWS tenant rigs (all of tests/replays/{hui,pyron})"
fi

# Every leg dumps the P1 hitbox base ($FF8460, the +0x60.l signature
# audit_legacy_pairings.sh classifies on) at three points spread across the
# run, so a leg that never formed the tenant's match cannot present its zero
# as a measurement. +0x382 would NOT do: in match that byte is the voice
# class and the engine reassigns it (14z-87, ram.md:85).
last_frame() { sed 's/#.*//' "$1" | awk 'NF { split($1, r, "-");
    f = (r[2] ? r[2] : r[1]); if (f + 0 > m) m = f + 0 } END { print m + 0 }'; }

# EACH LEG GETS ITS OWN DIRECTORY. replay_guard.lua writes DUMPS next to the
# CHECKSUM LOG, not into the sandbox (`out_dir` is the log's dirname), and
# the filename is only `dump_<frame>_<addr>.bin` — so 37 legs sharing $WORK
# would overwrite each other's hitbox dumps and silently attribute one leg's
# character to another.
tleg() {   # tleg <build> <body> <replay> <pokes> <tag>
    rpl="tests/replays/$3.rpl"
    lf="$(last_frame "$rpl")"
    d1=$(( lf * 55 / 100 )); d2=$(( lf * 70 / 100 )); d3=$(( lf * 85 / 100 ))
    mkdir -p "$WORK/tl_$5"
    ( POKES="$4" MAME_ROMPATH="$(abspath "$1")/rompath;$ROMDIR" \
      GUARD_PROBE="$2" GUARD_PROBE_MAX=20000 \
      DUMPS="$d1:ff8460-ff8463;$d2:ff8460-ff8463;$d3:ff8460-ff8463" \
        tools/run_replay_guarded.sh vsavjw "$rpl" \
        "$WORK/tl_$5/probe.log" "$WORK/tl_$5/sb" >/dev/null 2>&1 || true ) &
}

# Rows carry no spaces (the poke grammar is `frame:addr:val;…`), so plain
# word-splitting over the table is safe.
for row in $(tenant_rows); do
    tk="${row%%|*}"; rest="${row#*|}"; rpl="${rest%%|*}"; pk="${rest#*|}"
    case "$row" in *\|*\|*) ;; *) continue ;; esac
    if [ -n "${HITCLASS_TENANT_REPLAYS:-}" ]; then
        want=0
        for w in $HITCLASS_TENANT_REPLAYS; do
            if [ "$w" = "$rpl" ]; then want=1; fi
        done
        [ "$want" = 1 ] || continue
    fi
    tag="$(printf '%s' "$rpl" | tr '/' '_')"
    if [ "$tk" = h ]; then tleg "$WORK/hfix" "$HBODY" "$rpl" "$pk" "$tag"
    else                   tleg "$WORK/fix"  "$BODY"  "$rpl" "$pk" "$tag"; fi
    sync_pool
done
wait

# THE ARMED-PROBE CONTROL. Every number below is a count of breakpoint hits;
# if the breakpoint is not actually armed on these builds, every zero is
# vacuous. 26_don_arcade_mash is the replay section 2 measures at 228 entries,
# so it is the one leg whose non-zero is already known independently.
for tk in h p; do
    if [ "$tk" = h ]; then bd="$WORK/hfix"; bb="$HBODY"; else bd="$WORK/fix"; bb="$BODY"; fi
    ( POKES="" MAME_ROMPATH="$(abspath "$bd")/rompath;$ROMDIR" \
      GUARD_PROBE="$bb" GUARD_PROBE_MAX=20000 \
        tools/run_replay_guarded.sh vsavjw tests/replays/26_don_arcade_mash.rpl \
        "$WORK/armed_$tk.log" "$WORK/armedbox_$tk" >/dev/null 2>&1 || true ) &
    sync_pool
done
wait
armed_ok=1
for tk in h p; do
    classify "$WORK/armed_$tk.log"
    if [ "$crc" = 0 ] && [ "$c_total" -gt 0 ]; then
        echo "  ok armed[$tk]: 26_don_arcade_mash fires the probe $c_total times"
    else
        echo "  FAIL armed[$tk]: the probe did not fire on a replay measured at"
        echo "        228 entries in section 2 ($c_st total=$c_total) — every"
        echo "        tenant zero below is VACUOUS, not a finding."
        armed_ok=0; fail=1
    fi
done

# Read back the hitbox-base dumps: which character actually loaded.
hb_of() {   # hb_of <tag> -> distinct non-zero $FF8460 longs seen, space-sep
    python3 - "$WORK/tl_$1" <<'PY'
import glob, os, sys
seen = []
for p in sorted(glob.glob(os.path.join(sys.argv[1], "dump_*_ff8460.bin"))):
    with open(p, "rb") as fh:
        b = fh.read(4)
    if len(b) == 4:
        v = int.from_bytes(b, "big")
        if v and v not in seen:
            seen.append(v)
print(" ".join("%06x" % v for v in seen))
PY
}

t_tot=0; t_ext=0; t_trap=0; t_dead=0; t_norig=0; t_legs=0
: > "$WORK/tenant_report.txt"
for row in $(tenant_rows); do
    tk="${row%%|*}"; rest="${row#*|}"; rpl="${rest%%|*}"
    case "$row" in *\|*\|*) ;; *) continue ;; esac
    tag="$(printf '%s' "$rpl" | tr '/' '_')"
    [ -d "$WORK/tl_$tag" ] || continue
    t_legs=$((t_legs + 1))
    classify "$WORK/tl_$tag/probe.log"
    hb="$(hb_of "$tag")"
    case "$crc" in
        1) echo "  DEAD: $rpl — guarded run did not complete; not a measurement"
           t_dead=$((t_dead + 1)); fail=1; continue ;;
        3) echo "  CRASH: $rpl — the guard tripped ON THE FIX BUILD."
           echo "        entries=$c_total ext=$c_ext trap=$c_trap D0: $c_vals"
           echo "        A crash here is a FINDING, not a dead rig — root-cause"
           echo "        it before reading any verdict below."
           t_dead=$((t_dead + 1)); fail=1; continue ;;
        2) echo "  CAPPED: $rpl — hit GUARD_PROBE_MAX; total is a FLOOR"
           fail=1 ;;
    esac
    if [ -z "$hb" ]; then
        echo "  NO-MATCH: $rpl — \$FF8460 never populated; the rig formed no"
        echo "        match, so its $c_total entries describe nothing"
        t_dead=$((t_dead + 1)); fail=1; continue
    fi
    t_tot=$((t_tot + c_total)); t_ext=$((t_ext + c_ext)); t_trap=$((t_trap + c_trap))
    [ "$c_total" = 0 ] && t_norig=$((t_norig + 1))
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$tk" "$rpl" "$c_total" "$c_ext" "$c_trap" "$hb" >> "$WORK/tenant_report.txt"
    if [ "$c_total" -gt 0 ]; then
        echo "  $rpl: $c_total entries ($c_ext ext, $c_trap trap); D0: $c_vals; hb=$hb"
    fi
done

# WHICH CHARACTER DID EACH LEG ACTUALLY LOAD? A single shared hitbox base
# across a tenant's legs is the evidence the forced picks took; a stray value
# is the #84 shape (a green gate measuring the wrong character).
for tk in h p; do
    [ -s "$WORK/tenant_report.txt" ] || break
    bases="$(awk -F'\t' -v k="$tk" '$1 == k { print $6 }' "$WORK/tenant_report.txt" \
             | tr ' ' '\n' | sed '/^$/d' | sort -u | tr '\n' ' ')"
    nb="$(printf '%s' "$bases" | wc -w | tr -d ' ')"
    if [ "${nb:-0}" -le 1 ]; then
        echo "  ok pick[$tk]: every leg loaded ONE character (hb=$bases)"
    else
        echo "  NOTE pick[$tk]: legs loaded $nb distinct hitbox bases [$bases]."
        echo "        Expected for 2P rigs (P1 is the tenant, but a leg whose"
        echo "        pick MISSED would look the same). Per-leg values are in"
        echo "        the table above; check any leg whose base is unique."
    fi
done

# ---- THE SPAWN DENOMINATOR ----------------------------------------------
# A zero from the map probe is ambiguous ON ITS OWN and the two readings
# license opposite rulings: "the tenant never stamps a dangerous type" vs
# "it stamps them constantly and nothing ever collided with one". This leg
# supplies the second number — how many objects of type >= 64 went into the
# $FF9400 projectile pool at all — using the pool tap (no debugger, so
# frame counting stays replay-exact) over the SAME corpus.
echo "  -- spawn denominator: type >= 64 into the \$FF9400 pool --"
for row in $(tenant_rows); do
    tk="${row%%|*}"; rest="${row#*|}"; rpl="${rest%%|*}"; pk="${rest#*|}"
    case "$row" in *\|*\|*) ;; *) continue ;; esac
    tag="$(printf '%s' "$rpl" | tr '/' '_')"
    [ -d "$WORK/tl_$tag" ] || continue
    if [ "$tk" = h ]; then bd="$WORK/hfix"; else bd="$WORK/fix"; fi
    lf="$(last_frame "tests/replays/$rpl.rpl")"
    mkdir -p "$WORK/sp_$tag"
    # The subshell's OWN stderr is redirected too, not just the command's:
    # MAME routinely dies by SIGSEGV in TEARDOWN after the log is complete
    # (docs/GOTCHAS.md; audit_type_writes.sh ignores the exit code for the
    # same reason), and the shell prints "Segmentation fault" when it reaps
    # the child. Left unredirected that message lands in the middle of the
    # results table and reads as a failed measurement. The validity
    # criterion is the tap's own `END` line, asserted per leg below — a run
    # that did not reach END is reported DEAD and fails the audit.
    ( REPLAY="$PWD/tests/replays/$rpl.rpl" TAP="ff9400,3c00" \
      FRAMES=$(( lf + 120 )) POKES="$pk" TRACE_OUT="$WORK/sp_$tag/tap.txt" \
      MAME_ROMPATH="$(abspath "$bd")/rompath;$ROMDIR" \
      MAME_SANDBOX="$WORK/sp_$tag/sb" \
        tools/run_mame.sh vsavjw \
        -autoboot_script tests/lua/type_write_census.lua \
        >"$WORK/sp_$tag/mame.log" 2>&1 || true ) 2>>"$WORK/sp_$tag/mame.log" &
    sync_pool
done
wait
s_tot=0; s_dead=0; s_types=""
for row in $(tenant_rows); do
    rest="${row#*|}"; rpl="${rest%%|*}"
    case "$row" in *\|*\|*) ;; *) continue ;; esac
    tag="$(printf '%s' "$rpl" | tr '/' '_')"
    [ -d "$WORK/sp_$tag" ] || continue
    src=0
    so="$(python3 tools/classify_pool_spawns.py "$WORK/sp_$tag/tap.txt" 2>&1)" || src=$?
    if [ "$src" != 0 ]; then
        echo "  DEAD(spawn): $rpl — tap did not complete; its zero is not evidence"
        s_dead=$((s_dead + 1)); fail=1; continue
    fi
    n="$(printf '%s' "$so" | sed 's/.*spawns=\([0-9]*\).*/\1/')"
    ty="$(printf '%s' "$so" | sed 's/.*types=\([^ ]*\).*/\1/')"
    s_tot=$((s_tot + n))
    if [ "$n" -gt 0 ]; then
        echo "  $rpl: $n spawns of type >= 64; types: $ty"
        s_types="$s_types,$ty"
    fi
done
echo "  spawn total: $s_tot objects of type >= 64 entered the projectile"
echo "               pool over $t_legs legs ($s_dead dead taps)"

echo "  tenant total: $t_tot map entries over $t_legs legs"
echo "                $t_ext at index >=0x40 (the vs2 EXTENSION)"
echo "                $t_trap at index >=0x50 (the planted ILLEGAL)"
echo "                $t_norig legs produced no map entry at all, $t_dead dead"
if [ "$armed_ok" = 0 ]; then
    echo "  => NO VERDICT: the probe was not armed (see FAIL armed above)."
elif [ "$t_ext" -gt 0 ] || [ "$t_trap" -gt 0 ]; then
    echo "  => THE THUNK IS LOAD-BEARING. A tenant reaches the extension"
    echo "     $t_ext time(s); without the thunk each is a wild jump into"
    echo "     the map[64] = 0x4E rts opcode (the f7997 vec3)."
elif [ "$t_tot" -gt 0 ]; then
    echo "  => TENANT ENTERS ($t_tot times) BUT STAYS BELOW 0x40 on this"
    echo "     corpus. That is a real bounded answer, NOT a demonstration"
    echo "     that the thunk is unnecessary: the frozen stamp inventory"
    echo "     still carries type-64..75 rows in this pool, so the rigs"
    echo "     reach the map without reaching those types."
elif [ "$s_tot" -gt 0 ]; then
    echo "  => NO RIG PRODUCES A POOL-VS-POOL CONTACT — BUT THE EXPOSURE IS"
    echo "     LIVE. The corpus put $s_tot objects of type >= 64 into the"
    echo "     projectile pool and entered the map ZERO times, so the gap is"
    echo "     CONTACT, not absence: the dangerous object is present and"
    echo "     nothing collided with it. The sweep is pool-vs-pool (both"
    echo "     loop registers stride pool slots), so a tenant projectile"
    echo "     hitting a FIGHTER never transits this map."
    echo "     THIS IS NOT A LICENCE TO DROP THE THUNK. It is a missing RIG:"
    echo "     tests/replays/hui/88_hui_plasma_trap_contact.rpl's header"
    echo "     names what is needed — an opposing PROJECTILE to clash with"
    echo "     (P2 doing a pool-object move into the mine), not a walking"
    echo "     fighter."
else
    echo "  => NEITHER THE MAP NOR THE POOL SAW ANYTHING. No dangerous type"
    echo "     was even stamped, so the rigs are not exercising the tenant's"
    echo "     projectile machine at all. Fix the rigs before reading this"
    echo "     as a fact about the thunk — and check the pick controls above."
fi

# ---------------------------------------------------------------- section 4
# WHY IS SECTION 0'S CRASH CONTROL DEAD? Same probe, aimed at the soak rig
# section 0 uses. An f7997 crash IS a >= 64 map entry, so this separates the
# two candidate explanations instead of leaving "check the rig".
echo
echo "== 4: the dead crash control, diagnosed with the probe =="
( POKES="$PYR_SOAK" MAME_ROMPATH="$(abspath "$WORK/fix")/rompath;$ROMDIR" \
  GUARD_PROBE="$BODY" GUARD_PROBE_MAX=20000 \
    tools/run_replay_guarded.sh vsavjw tests/replays/pyron/70_pyron_mash.rpl \
    "$WORK/soak_probe.log" "$WORK/soakprobe_box" >/dev/null 2>&1 || true )
classify "$WORK/soak_probe.log"
echo "  soak rig on the FIX build: $c_st total=$c_total ext=$c_ext trap=$c_trap D0: $c_vals"
if [ "$crc" = 1 ]; then
    echo "  => INCONCLUSIVE: the probed soak did not complete."
elif [ "$c_ext" -gt 0 ] || [ "$c_trap" -gt 0 ]; then
    echo "  => THE OVER-INDEX STILL HAPPENS. The thunk is catching it; the"
    echo "     control died only because the no-thunk twin's wild jump no"
    echo "     longer lands on f7997 (placement moved under it across six"
    echo "     manifest changes). Re-point the control at the GUARD, not at"
    echo "     that address."
elif [ "$c_total" -gt 0 ]; then
    echo "  => THE RIG STOPPED PRODUCING THE EVENT. It still reaches the map"
    echo "     ($c_total times) but never at an index >= 0x40, so there is"
    echo "     nothing for the twin to crash on. The control needs a new rig,"
    echo "     not a new address."
else
    echo "  => THE SOAK DOES NOT REACH THE MAP — a RECORDED FACT now, not a"
    echo "     blocked verdict. Section 0 no longer rides this rig: since"
    echo "     14z-129 its control is pyron/84_pyron_clash_type64, which"
    echo "     supplies the opposing PROJECTILE the soak never had. Kept as a"
    echo "     standing check: if this transit ever returns to nonzero, the"
    echo "     soak's trajectory moved back onto the map and that is a finding."
fi

echo
if [ "$fail" = 0 ]; then
    echo "PASS: the fix holds and legacy content is bit-identical on the"
    echo "      measured replays (the 14z-82c adoption numbers reproduce)."
else
    echo "RESULT: read the sections TOGETHER, not separately (14z-92)."
    echo "        A DIVERGES line is NOT automatically the thunk's cycle"
    echo "        cost: stripping the row also moves the ALLOCATOR, so the"
    echo "        twin differs by the thunk AND by the placement shift its"
    echo "        absence causes. Cross-check each divergent replay against"
    echo "        its census count. Measured 14z-92: 26_don_arcade_mash"
    echo "        diverges WITH 228 map entries (map-transit cycles), while"
    echo "        21_don_mash and 22_don_dualmash diverge with ZERO entries"
    echo "        (placement shift, not the map). Only the first is a cost"
    echo "        the thunk itself imposes."
fi
exit "$fail"
