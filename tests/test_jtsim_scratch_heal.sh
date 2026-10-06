#!/bin/sh
# test_jtsim_scratch_heal.sh — a jtsim scratch clone hollowed by the macOS tmp
# reaper is HEALED, not trusted (14z-133b). ROM-free, ~5 s (three local
# clones of emu/jtcores, hardlinked).
#
# WHAT: a jtsim scratch clone hollowed by the macOS tmp reaper (tracked files gone, .git
#   intact) is HEALED in place by `mister_mra.sh --ensure-scratch`, a clone whose object
#   store is hollow too is re-cloned at the pin, and a fresh scratch is cloned at the pin
#   with nothing missing.
# HOW: three local hardlinked clones of emu/jtcores shaped as fresh, reaped, and
#   store-hollowed (ROM-free, ~5 s); the control cuts the heal block from a copy of the
#   tool, which must leave the reaped clone hollow. Section 5 (#232): a SUBMODULE initialised
#   from the local emu/jtcores checkout (no network), reaped as the 03:35 maintenance did it —
#   its gitdir HEAD, worktree gitfile and tracked files gone — must be healed back to the
#   commit the superproject records; its control cuts only the submodule heal.
# EXPECTS: the three shapes handled as stated and the control failing; a red is the 0-second
#   'Cannot open macros.def' red returning between two static runs.
#
# MUST-FIRE: shadow-tool: heal-removed — a copy of mister_mra.sh with the 1b HEAL block cut must leave a hollowed clone hollow (mode: section 2 runs that copy, and must fail)
# MUST-FIRE: shadow-tool: submodule-heal-removed — a copy of mister_mra.sh with only the SUBMODULE heal cut must leave a reaped submodule broken (mode: section 5 runs that copy, and must fail)
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
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
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
# THE SHADOW TOOL: mister_mra.sh with the heal block cut out
CTL="$(shadow_tool "$WORK" mister_mra.sh)"
python3 - "$CTL" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p).read()
a = s.index("# ---------------------------------------------------- 1b. HEAL")
b = s.index('if [ "$ENSURE" = 1 ]; then', a)
open(p, "w").write(s[:a] + s[b:])
PY
grep -q "1b. HEAL" "$CTL" && { echo "  FAIL: the control still carries the heal"; fail=1; }
# THE SECOND SHADOW TOOL (#232): only the submodule heal cut, the top-level heal kept
CTL2="$(shadow_tool "$WORK/ctl2" mister_mra.sh)"
python3 - "$CTL2" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = s.index("sub_ok() {  # sub_ok <path>")
b = s.index('if [ "$ENSURE" = 1 ]; then', a)
open(p, "w").write(s[:a] + s[b:])
PY
grep -q "sub_ok" "$CTL2" && { echo "  FAIL: the submodule control still carries the submodule heal"; fail=1; }
grep -q "1b. HEAL" "$CTL2" || { echo "  FAIL: the submodule control lost the top-level heal"; fail=1; }
# THE EXECUTABLE FORM: under CONTROL=heal-removed section 2 runs the shadow
# tool — and must FAIL (the clone stays hollow).
TOOL=tools/mister_mra.sh
vs_ctl_is heal-removed && TOOL="sh $CTL"
TOOL5=tools/mister_mra.sh
vs_ctl_is submodule-heal-removed && TOOL5="sh $CTL2"

echo "== 1. a fresh scratch is cloned and pinned =="
JTSIM_SCRATCH="$S" tools/mister_mra.sh --ensure-scratch --quiet || { echo "  FAIL: ensure on a fresh dir"; fail=1; }
[ "$(git -C "$S" rev-parse HEAD)" = "$PIN" ] && echo "  ok: HEAD is the pin $PIN" || { echo "  FAIL: HEAD is not the pin"; fail=1; }
[ "$(missing)" = 0 ] && echo "  ok: no tracked file missing" || { echo "  FAIL: $(missing) missing on a fresh clone"; fail=1; }

echo "== 2. the reaper's shape (.git intact, tracked files gone) is HEALED IN PLACE =="
hollow
n="$(missing)"; [ "$n" -gt 100 ] && echo "  ok: hollowed — $n tracked files missing, macros.def among them" \
                                 || { echo "  FAIL: could not hollow the clone"; fail=1; }
reflog_before="$(git -C "$S" reflog | wc -l | tr -d ' ')"
JTSIM_SCRATCH="$S" $TOOL --ensure-scratch --quiet || { echo "  FAIL: ensure on a hollow clone"; fail=1; }
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
hollow
n="$(missing)"
JTSIM_SCRATCH="$S" sh "$CTL" --ensure-scratch --quiet || true
[ "$(missing)" = "$n" ] && [ "$n" -gt 100 ] \
    && vs_ctl_fired heal-removed "without the heal, $n files stay missing" \
    || { vs_ctl_dead heal-removed "$(missing) missing after a heal-less ensure"; fail=1; }

echo "== 5. a REAPED SUBMODULE (#232: gitdir HEAD, gitfile and files gone) is HEALED to the recorded commit =="
JTSIM_SCRATCH="$S" tools/mister_mra.sh --ensure-scratch --quiet || { echo "  FAIL: ensure before the submodule case"; fail=1; }
SM=modules/fx68k; SG="$S/.git/modules/modules/fx68k"
WANT="$(git -C "$S" ls-tree HEAD "$SM" | awk '{print $3}')"
git -C "$S" config submodule.modules/fx68k.url "$REPO/emu/jtcores/modules/fx68k"
git -C "$S" -c protocol.file.allow=always submodule update --init --quiet "$SM" 2>&1 | sed 's/^/    /'
sub_good() { [ "$(git -C "$S/$SM" rev-parse HEAD 2>/dev/null)" = "$WANT" ] && [ -z "$(git -C "$S/$SM" ls-files --deleted 2>/dev/null)" ] && [ -f "$S/$SM/.git" ]; }
reap_sub() {  # the shape the 03:35 maintenance left on 2026-10-06
    git -C "$S/$SM" ls-files | head -40 > "$WORK/subvictims"
    (cd "$S/$SM" && xargs rm -f < "$WORK/subvictims")
    rm -f "$SG/HEAD" "$S/$SM/.git"
}
sub_good && echo "  ok: $SM initialised from the local checkout at $WANT" || { echo "  FAIL: could not initialise $SM locally"; fail=1; }
reap_sub
sub_good && { echo "  FAIL: could not reap $SM"; fail=1; } || echo "  ok: reaped — HEAD, gitfile and $(wc -l < "$WORK/subvictims" | tr -d ' ') files gone"
JTSIM_SCRATCH="$S" $TOOL5 --ensure-scratch --quiet || true
if vs_ctl_is submodule-heal-removed; then
    sub_good && echo "  ok (mode): healed anyway" || { echo "  FAIL: the reaped submodule stays broken"; fail=1; }
else
    sub_good && echo "  ok: healed — at $WANT, gitfile back, nothing deleted" || { echo "  FAIL: $SM not healed"; fail=1; }
    [ "$(git -C "$S" rev-parse HEAD)" = "$PIN" ] && echo "  ok: the superproject is still at the pin" || { echo "  FAIL: the superproject moved"; fail=1; }
    reap_sub
    JTSIM_SCRATCH="$S" sh "$CTL2" --ensure-scratch --quiet >/dev/null 2>&1 || true
    sub_good && { vs_ctl_dead submodule-heal-removed "the reaped submodule healed without the submodule heal"; fail=1; } \
             || vs_ctl_fired submodule-heal-removed "without the submodule heal $SM stays broken (HEAD $(git -C "$S/$SM" rev-parse --short HEAD 2>/dev/null || echo none), want ${WANT%%${WANT#???????}})"
fi

if [ "$fail" -eq 0 ]; then echo "PASS: a hollowed jtsim scratch clone is healed, re-cloned when its store is gone, and the control fires"
else echo "FAIL: jtsim scratch heal"; exit 1; fi
