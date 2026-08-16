#!/bin/sh
# audit_hitclass_map_cost.sh — what the 14z-82b hit-class map extension
# FIXES and what it COSTS legacy content (ADOPTED 14z-82c; rerunnable).
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
#      the row since 14z-82c) AND a no-thunk twin, then prove THE FIX: the
#      11,017-frame chaos soak must END clean WITH the thunk and CRASH at
#      f7997 WITHOUT it. The crash half is the positive control — an
#      END-clean run alone cannot tell a fix from a rig that stopped
#      firing the move.
#   1  LEGACY COST: live A/B fix-vs-no-thunk-twin whole-RAM checksums over
#      THE WHOLE LEGACY CORPUS. The builds differ by ONLY the thunk BY
#      CONSTRUCTION (same manifest, one row stripped), so any
#      divergence is the thunk's cycle cost where legacy hits transit
#      the map. Identical = zero observable cost on that replay;
#      divergent = the run-shape report is the maintainer's input.
#   2  FIRE CENSUS: how often legacy content actually enters the map
#      routine (probe at the placed body, D0 = the map index) — the
#      denominator for section 1's verdict, over the SAME corpus.
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
#        [HITCLASS_REPLAYS="a b c"] tests/audit_hitclass_map_cost.sh
# On-demand (1 build + 1 soak + 2*N checksum runs + N probe runs,
# JOBS-parallel).
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

PYR_SOAK="1704:ff8782:11;1760:ff8782:11;1900:ff8782:11;2100:ff8782:11;2400:ff8782:11"
soak() {  # soak <build> <out>
    POKES="$PYR_SOAK" MAME_ROMPATH="$(abspath "$1")/rompath;$ROMDIR" \
        tools/run_replay_guarded.sh vsavjw tests/replays/pyron/70_pyron_mash.rpl \
        "$2" "$2.box" >/dev/null 2>&1 || true
}
soak "$WORK/fix"     "$WORK/soak.log"
soak "$WORK/nothunk" "$WORK/soak_nothunk.log"
# THE POSITIVE CONTROL IS NOT OPTIONAL: an END-clean soak proves nothing
# unless the same soak CRASHES without the thunk. Otherwise "no crash" may
# mean the rig stopped firing the move (the downgrade class, paid for
# repeatedly on this project).
if grep -q "^CRASH" "$WORK/soak_nothunk.log"; then
    echo "  ok: CONTROL — without the thunk the soak still CRASHES" \
         "($(grep -m1 '^CRASH' "$WORK/soak_nothunk.log" | cut -c1-60))"
else
    echo "  FAIL: CONTROL DEAD — the soak did NOT crash on the no-thunk twin,"
    echo "        so an END-clean run on the fix build proves nothing about"
    echo "        the thunk. Check the rig before believing section 0."
    grep -E "^(CRASH|END)" "$WORK/soak_nothunk.log" | head -3
    fail=1
fi
if grep -q "^END 11017" "$WORK/soak.log" \
        && ! grep -q "^CRASH" "$WORK/soak.log"; then
    echo "  ok: THE FIX HOLDS — the soak that crashes the no-thunk twin at"
    echo "      f7997 runs END-clean through 11,017 frames"
else
    echo "  FAIL: the soak did not complete clean on the fix build:"
    grep -E "^(CRASH|END)" "$WORK/soak.log" | head -3
    fail=1
fi

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

echo "== 2: FIRE CENSUS — how often legacy content enters the map =="
for R in $CORPUS; do
    ( POKES="" MAME_ROMPATH="$(abspath "$WORK/fix")/rompath;$ROMDIR" \
      GUARD_PROBE="$BODY" GUARD_PROBE_MAX=20000 \
        tools/run_replay_guarded.sh vsavjw "tests/replays/$R.rpl" \
        "$WORK/f_$R.log" "$WORK/fbox_$R" >/dev/null 2>&1 || true ) &
    sync_pool
done
wait
tot=0; c_dead=0; seen_vals=""
for R in $CORPUS; do
    # A guarded run that never started logs nothing, and "0 map entries"
    # from a dead rig is indistinguishable from a real zero — the trap this
    # project has paid for repeatedly. Require the run to have COMPLETED.
    if [ ! -s "$WORK/f_$R.log" ] || ! grep -q '^END ' "$WORK/f_$R.log"; then
        echo "  DEAD: $R — guarded run did not complete; its zero is not evidence"
        c_dead=$((c_dead + 1)); fail=1; continue
    fi
    N="$(grep -c '^PROBE ' "$WORK/f_$R.log" || true)"
    tot=$((tot + N))
    if [ "$N" -gt 0 ]; then
        VALS="$(grep '^PROBE ' "$WORK/f_$R.log" \
                | sed 's/.*D0=\([0-9a-f]*\) .*/\1/' | sort -u | tr '\n' ' ')"
        echo "  $R: $N map entries; D0 values: $VALS"
        seen_vals="$seen_vals $VALS"
    fi
done
echo "  corpus total: $tot map entries over $NCORP replays ($c_dead dead)"
[ "$tot" = 0 ] && echo "  => legacy content NEVER enters the map on this corpus"
echo "  (guarded runs are never checksum-compared — the census is a"
echo "   denominator for section 1, not a divergence source)"

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
