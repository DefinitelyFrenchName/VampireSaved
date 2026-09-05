#!/bin/sh
# test_jtsim_scratch_heal.sh — a jtsim scratch clone hollowed by the macOS tmp
# reaper is HEALED, not trusted (14z-133b). ROM-free, ~5 s (three local
# clones of emu/jtcores, hardlinked).
#
# THE CLASS. tools/mister_mra.sh and tools/run_sim_jtcps2.sh keep a clone of
# the jtcores fork under ${JTSIM_SCRATCH:-$TMPDIR/vampire-saved-jtsim} and
# used to re-clone only when `.git` was ABSENT. macOS purges $TMPDIR by file
# age, piecemeal, so the clone survives with `.git` intact and its tracked
# files gone: 4,099 of 4,244 on 2026-09-05 (paid at 14z-111 first — the
# documented remedy was a manual `rm -rf`, which is why it recurred, and it
# recurred as a red `test_mister_mra_map` between two static runs two hours
# apart, straddling the 03:35 daily maintenance). The symptom is a 0-second
# "Cannot open .../macros.def" with nothing in the tree changed.
#
# THE RULE: `mister_mra.sh --ensure-scratch` (which run_sim_jtcps2.sh now
# delegates to) asks git which tracked files are missing, restores them from
# the clone's own object store, and re-clones only if the store is hollow too.
#
# WHAT THIS LOCKS
#  1. a fresh scratch: cloned, at the pin, nothing missing;
#  2. the reaper's shape — tracked files deleted, .git intact — is healed IN
#     PLACE (no re-clone: the clone's HEAD reflog is untouched);
#  3. the store hollowed too (packs removed) — the tool RE-CLONES and lands
#     at the pin;
#  4. MUST-FIRE CONTROL: a shadow copy of the tool with the heal removed
#     leaves the hollow clone hollow — so 2 depends on the heal, not on git
#     doing it for free.
#
# Usage: tests/test_jtsim_scratch_heal.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
[ -f "emu/jtcores/.gitmodules" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 77; }
. "$REPO/tests/lib/shadow_tools.sh"
PIN="$(sed -n 's/^PINNED="\([0-9a-f]*\)".*/\1/p' tools/setup_jtcores.sh)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/jtsim_heal.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
S="$WORK/scratch"
fail=0
missing() { git -C "$S" ls-files --deleted | wc -l | tr -d ' '; }
hollow() {  # delete the first N tracked files, macros.def among them — the reaper's shape
    git -C "$S" ls-files | head -200 > "$WORK/victims"
    echo "cores/cps2w/cfg/macros.def" >> "$WORK/victims"
    (cd "$S" && xargs rm -f < "$WORK/victims")
}

echo "== 1. a fresh scratch is cloned and pinned =="
JTSIM_SCRATCH="$S" tools/mister_mra.sh --ensure-scratch --quiet || { echo "  FAIL: ensure on a fresh dir"; fail=1; }
[ "$(git -C "$S" rev-parse HEAD)" = "$PIN" ] && echo "  ok: HEAD is the pin $PIN" || { echo "  FAIL: HEAD is not the pin"; fail=1; }
[ "$(missing)" = 0 ] && echo "  ok: no tracked file missing" || { echo "  FAIL: $(missing) missing on a fresh clone"; fail=1; }

echo "== 2. the reaper's shape (.git intact, tracked files gone) is HEALED IN PLACE =="
hollow
n="$(missing)"; [ "$n" -gt 100 ] && echo "  ok: hollowed — $n tracked files missing, macros.def among them" \
                                 || { echo "  FAIL: could not hollow the clone"; fail=1; }
reflog_before="$(git -C "$S" reflog | wc -l | tr -d ' ')"
JTSIM_SCRATCH="$S" tools/mister_mra.sh --ensure-scratch --quiet || { echo "  FAIL: ensure on a hollow clone"; fail=1; }
[ "$(missing)" = 0 ] && [ -f "$S/cores/cps2w/cfg/macros.def" ] \
    && echo "  ok: healed — 0 missing, macros.def back" || { echo "  FAIL: $(missing) still missing"; fail=1; }
[ "$(git -C "$S" reflog | wc -l | tr -d ' ')" = "$reflog_before" ] \
    && echo "  ok: healed IN PLACE (reflog untouched — no re-clone)" || { echo "  FAIL: the clone was re-created, not healed"; fail=1; }

echo "== 3. the object store hollowed too -> RE-CLONE, at the pin =="
hollow; rm -rf "$S/.git/objects/pack"
JTSIM_SCRATCH="$S" tools/mister_mra.sh --ensure-scratch --quiet || { echo "  FAIL: ensure on a store-hollow clone"; fail=1; }
[ "$(missing)" = 0 ] && [ -f "$S/cores/cps2w/cfg/macros.def" ] && [ "$(git -C "$S" rev-parse HEAD)" = "$PIN" ] \
    && echo "  ok: re-cloned — complete and at the pin" || { echo "  FAIL: not recovered from a hollow store"; fail=1; }

echo "== 4. MUST-FIRE CONTROL: the tool WITHOUT the heal leaves the hollow clone hollow =="
CTL="$(shadow_tool "$WORK" mister_mra.sh)"
python3 - "$CTL" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p).read()
a = s.index("# ---------------------------------------------------- 1b. HEAL")
b = s.index('if [ "$ENSURE" = 1 ]; then', a)
open(p, "w").write(s[:a] + s[b:])
PY
grep -q "1b. HEAL" "$CTL" && { echo "  FAIL: the control still carries the heal"; fail=1; }
hollow
n="$(missing)"
JTSIM_SCRATCH="$S" sh "$CTL" --ensure-scratch --quiet || true
[ "$(missing)" = "$n" ] && [ "$n" -gt 100 ] \
    && echo "  ok: control fires — without the heal, $n files stay missing" \
    || { echo "  FAIL: control did not fire ($(missing) missing after a heal-less ensure)"; fail=1; }

if [ "$fail" -eq 0 ]; then echo "PASS: a hollowed jtsim scratch clone is healed, re-cloned when its store is gone, and the control fires"
else echo "FAIL: jtsim scratch heal"; exit 1; fi
