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
# adoption numbers on demand against build/pyron20, the last PRE-fix
# artifact (kept on disk; not tree-reproducible — git tag freeze/pyron-m2
# is the way back).
#
# Sections:
#   0  build the CURRENT pyron vertical (pyron.toml verbatim — it carries
#      the row since 14z-82c) and prove THE FIX: the 11,017-frame chaos
#      soak that crashes the PRE-fix build at f7997 must END clean.
#   1  LEGACY COST: live A/B probe-vs-pyron20 whole-RAM checksums over
#      four legacy replays. The builds differ by ONLY the thunk, so any
#      divergence is the thunk's cycle cost where legacy hits transit
#      the map. Identical = zero observable cost on that replay;
#      divergent = the run-shape report is the maintainer's input.
#   2  FIRE CENSUS: how often legacy content actually enters the map
#      routine (probe at the placed body, D0 = the map index) — the
#      denominator for section 1's verdict.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/audit_hitclass_map_cost.sh
# On-demand, ~20 min (1 build + 1 soak + 8 checksum runs + 2 probe runs).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN

# the PRE-fix baseline artifact (pyron-m2). Not tree-reproducible; if the
# dir is gone, rebuild it from git tag freeze/pyron-m2.
REF=build/pyron20
WIDE_ZIP="${WIDE_ROMSET:-$PWD/build/wide0/rompath/vsavjw.zip}"
if [ ! -d "$REF/rompath" ] || [ ! -x "$MAME_BIN" ] || [ ! -f "$WIDE_ZIP" ]; then
    echo "SKIP: need $REF, the WIDE MAME binary and a WIDE overlay romset"
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }

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

PYR_SOAK="1704:ff8782:11;1760:ff8782:11;1900:ff8782:11;2100:ff8782:11;2400:ff8782:11"
POKES="$PYR_SOAK" MAME_ROMPATH="$(abspath "$WORK/fix")/rompath;$ROMDIR" \
    tools/run_replay_guarded.sh vsavjw tests/replays/pyron/70_pyron_mash.rpl \
    "$WORK/soak.log" "$WORK/soakbox" >/dev/null 2>&1 || true
if grep -q "^END 11017" "$WORK/soak.log" \
        && ! grep -q "^CRASH" "$WORK/soak.log"; then
    echo "  ok: THE FIX HOLDS — the soak that crashes the frozen build at"
    echo "      f7997 runs END-clean through 11,017 frames"
else
    echo "  FAIL: the soak did not complete clean on the fix build:"
    grep -E "^(CRASH|END)" "$WORK/soak.log" | head -3
    fail=1
fi

echo "== 1: LEGACY COST — A/B vs $REF (differ by ONLY the thunk) =="
run() {  # run <build> <replay> <out>
    MAME_ROMPATH="$(abspath "$1")/rompath;$ROMDIR" \
        tools/run_replay_mame.sh vsavjw "tests/replays/$2.rpl" "$3" \
        >/dev/null 2>&1 || true
}
for R in 01_attract_long 02_demitri_vs_cpu 03_two_player_vs 05_timeout_idle; do
    run "$REF"       "$R" "$WORK/l_${R}_ref"
    run "$WORK/fix"  "$R" "$WORK/l_${R}_new"
    if cmp -s "$WORK/l_${R}_ref" "$WORK/l_${R}_new"; then
        echo "  ok: $R bit-identical ($(wc -l < "$WORK/l_${R}_ref" | tr -d ' ') frames) — zero observable cost"
    else
        echo "  DIVERGES: $R — the thunk's cycle cost reached legacy state;"
        echo "        shape (maintainer input, not a gate):"
        python3 tools/analyze_divergence.py "$WORK/l_${R}_ref" \
            "$WORK/l_${R}_new" 2>&1 | sed 's/^/        /' | head -8
        fail=1
    fi
done

echo "== 2: FIRE CENSUS — how often legacy content enters the map =="
for R in 02_demitri_vs_cpu 03_two_player_vs; do
    POKES="" MAME_ROMPATH="$(abspath "$WORK/fix")/rompath;$ROMDIR" \
    GUARD_PROBE="$BODY" GUARD_PROBE_MAX=20000 \
        tools/run_replay_guarded.sh vsavjw "tests/replays/$R.rpl" \
        "$WORK/f_$R.log" "$WORK/fbox_$R" >/dev/null 2>&1 || true
    N="$(grep -c '^PROBE ' "$WORK/f_$R.log" || true)"
    VALS="$(grep '^PROBE ' "$WORK/f_$R.log" | sed 's/.*D0=\([0-9a-f]*\) .*/\1/' \
            | sort -u | tr '\n' ' ')"
    echo "  $R: $N map entries; D0 values: ${VALS:-none}"
done
echo "  (guarded runs are never checksum-compared — the census is a"
echo "   denominator for section 1, not a divergence source)"

echo
if [ "$fail" = 0 ]; then
    echo "PASS: the fix holds and legacy content is bit-identical on the"
    echo "      measured replays (the 14z-82c adoption numbers reproduce)."
else
    echo "RESULT: read the sections — a DIVERGES line is the thunk's"
    echo "        measured legacy cost, the number the re-freeze decision"
    echo "        needs (CLAUDE.md §4: measured, then ratified)."
fi
exit "$fail"
