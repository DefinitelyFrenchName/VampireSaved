#!/bin/sh
# test_attribute_patch_delta.sh — the freeze's op-by-op attribution runs on EVERY track, the solo tracks
# that write no gen.log included (`tools/attribute_patch_delta.py`, 14z-193, GitHub #231 part 1).
#
# WHAT: tools/attribute_patch_delta.py attributes a solo track's delta (donovan M22 -> M23, no gen.log)
#   to the end and says its generator notes are absent, and still reads the merged build's gen.log.
# HOW: runs the tool on two PINNED freeze pairs — build/don_m26 -> build/don_m27 (solo, no gen.log) and
#   build/m3b_merged30 -> build/m3b_merged31 (merged, gen.log present); the control runs a copy that
#   opens gen.log unconditionally again, which must stop on the solo pair.
# EXPECTS: the solo pair exits 0 with its NOTE and its alignment line; the merged pair exits 0 with no
#   NOTE; the control's copy exits non-zero on the solo pair.
#
# WHY. At the M23 freeze the tool stopped with FileNotFoundError on all four solo tracks, so their delta
# rested on op sets, which cannot see a byte inside a placed data file (#194's class; rule-checker run
# 2026-10-06-699). The pairs are FIXTURES pinned at M22 -> M23: a freeze never re-points them.
#
# MUST-FIRE: shadow-tool: gen-log-required — a copy that opens NEW/gen.log unconditionally must stop on the solo pair, and the gate must FAIL (mode: the solo case runs that copy)
#
# Usage: tests/test_attribute_patch_delta.sh      # ci_static (needs the four build dirs), ~10 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
SOLO_OLD=build/don_m26; SOLO_NEW=build/don_m27          # pinned fixtures (M22 -> M23), never re-pointed
MRG_OLD=build/m3b_merged30; MRG_NEW=build/m3b_merged31  # pinned fixtures (M22 -> M23), never re-pointed
for d in $SOLO_OLD $SOLO_NEW $MRG_OLD $MRG_NEW; do
    [ -f "$d/patch/patch.json" ] || { echo "SKIP: no $d/patch/patch.json (a build dir of the M22 -> M23 freeze)"; exit 0; }
done
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

make_copy() {  # the tool as it was before #231: gen.log opened unconditionally
    cp tools/attribute_patch_delta.py "$W/apd_ctl.py"
    python3 - "$W/apd_ctl.py" <<'PY'
import sys; p = sys.argv[1]; s = open(p).read()
a = '(open(GEN_LOG) if os.path.exists(GEN_LOG) else [])'
assert s.count(a) == 1
open(p, "w").write(s.replace(a, 'open(GEN_LOG)', 1).replace('GEN_LOG = f', '# CONTROL gen-log-required\nGEN_LOG = f', 1))
PY
    echo "$W/apd_ctl.py"
}

echo "== test_attribute_patch_delta: #231 — the attribution runs on a solo track without a gen.log =="
fail=0
T=tools/attribute_patch_delta.py
vs_ctl_is gen-log-required && T="$(make_copy)"

echo "-- 1. the solo pair $SOLO_OLD -> $SOLO_NEW (no gen.log)"
rc=0; python3 "$T" "$SOLO_OLD" "$SOLO_NEW" > "$W/solo.txt" 2>&1 || rc=$?
if [ "$rc" = 0 ] && grep -q '^NOTE: no .*gen.log' "$W/solo.txt" && grep -q '^aligned pairs ' "$W/solo.txt"; then
    echo "  ok: exit 0, $(grep -c 'EDIT op' "$W/solo.txt" | tr -d ' ') EDIT line(s), the absent notes named"
else
    echo "  FAIL: rc=$rc"; tail -3 "$W/solo.txt" | sed 's/^/      /'; fail=1
fi

echo "-- 2. the merged pair $MRG_OLD -> $MRG_NEW (gen.log present)"
rc=0; python3 tools/attribute_patch_delta.py "$MRG_OLD" "$MRG_NEW" > "$W/merged.txt" 2>&1 || rc=$?
if [ "$rc" = 0 ] && ! grep -q '^NOTE: no ' "$W/merged.txt" && grep -q '^aligned pairs ' "$W/merged.txt"; then
    echo "  ok: exit 0, gen.log read (no NOTE)"
else
    echo "  FAIL: rc=$rc"; tail -3 "$W/merged.txt" | sed 's/^/      /'; fail=1
fi

if [ -z "${VS_CTL:-}" ]; then
    echo "-- 3. control: the unconditional open must stop on the solo pair"
    rc=0; python3 "$(make_copy)" "$SOLO_OLD" "$SOLO_NEW" > "$W/ctl.txt" 2>&1 || rc=$?
    if [ "$rc" != 0 ] && grep -q 'FileNotFoundError' "$W/ctl.txt"; then
        vs_ctl_fired gen-log-required "the pre-#231 copy stops (rc=$rc, FileNotFoundError on $SOLO_NEW/gen.log)"
    else
        vs_ctl_dead gen-log-required "the pre-#231 copy did not stop (rc=$rc)" || fail=1
    fi
fi

if [ "$fail" -eq 0 ]; then echo "PASS: test_attribute_patch_delta"; else echo "FAIL: test_attribute_patch_delta"; exit 1; fi
