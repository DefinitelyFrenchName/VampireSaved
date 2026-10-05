#!/bin/sh
# test_release_prune.sh — `tools/upload_release_assets.sh --prune` EMPTIES EVERY EARLIER MERGED FREEZE
# RELEASE THAT STILL HOLDS A ZIP, walking past freezes that were never released (GitHub #221, 14z-191).
# ci_portable: no ROM, no emulator, no network (a stub stands in for `gh`), ~1 s.
#
# WHAT: the uploader's prune targets, read through its own --prune-plan, are every earlier
#   `freeze/merged-m*` tag whose release holds a .zip — newest first, past tags with no release —
#   and nothing when none does.
# HOW: the REAL uploader run with --prune-plan on the tree's own freeze tags, `VS_PRUNE_PROBE` a stub
#   that says which tags' releases hold a zip: merged-m19 and merged-m16 yes, everything else no (so
#   merged-m20 and merged-m21 between them and merged-m22 play the frozen-never-released freezes of
#   #221); then a stub that says no for every tag.
# EXPECTS: `freeze/merged-m19 freeze/merged-m16` for freeze/merged-m22, `none` with no zip anywhere. A red
#   is the #221 shape: the prune stopped at the first earlier tag, found no release there, and left an
#   older freeze's binaries hosted (merged-m19's seven zips under merged-m22, 14z-189).
#
# MUST-FIRE: shadow-tool: previous-only — a copy of the uploader that looks only at the tag JUST before (the pre-#221 logic) must plan nothing for freeze/merged-m22 and FAIL section 1 (mode: section 1 reads that copy)
#
# The tags are real and permanent (freeze tags are never moved or deleted), so the expected plan is a
# property of the stub and the uploader's walk, not of what GitHub hosts today.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
for t in freeze/merged-m16 freeze/merged-m19 freeze/merged-m20 freeze/merged-m21 freeze/merged-m22; do
    git rev-parse --verify -q "refs/tags/$t" >/dev/null || { echo "FAIL: tag $t is missing — the fixture rests on it"; exit 1; }
done
SH="$REPO/build/.release_prune_$$"; trap 'rm -rf "$SH"' EXIT INT TERM
mkdir -p "$SH/tools" "$SH/tests/lib"
printf '#!/bin/sh\ncase "$1" in freeze/merged-m19|freeze/merged-m16) exit 0;; *) exit 1;; esac\n' > "$SH/probe_some.sh"
printf '#!/bin/sh\nexit 1\n' > "$SH/probe_none.sh"
chmod +x "$SH/probe_some.sh" "$SH/probe_none.sh"
# THE SHADOW (one function the mode and the in-gate control both use): the pre-#221 walk, the one tag
# just before, inside a scratch root under build/ so its git commands still see this repository's tags
previous_only() {
    cp tests/lib/os_metadata.sh "$SH/tests/lib/"
    sed "s/awk -v t=\"\$TAG\" '\$0==t{exit} {print}'/awk -v t=\"\$TAG\" '\$0==t{exit} {p=\$0} END{print p}'/" \
        tools/upload_release_assets.sh > "$SH/tools/upload_release_assets.sh"
    cmp -s tools/upload_release_assets.sh "$SH/tools/upload_release_assets.sh" && { echo "  the walk is not where the control expects it"; return 1; }
    return 0
}
UP="tools/upload_release_assets.sh"
if vs_ctl_is previous-only; then previous_only || exit 1; UP="$SH/tools/upload_release_assets.sh"; fi
plan() { VS_PRUNE_PROBE="$1" sh "$2" freeze/merged-m22 --prune-plan 2>&1 | sed -n 's/^prune plan for freeze\/merged-m22: //p' | sed 's/ *$//'; }

echo "== 1. two earlier releases hold zips, with never-released freezes between (the #221 shape)"
got="$(plan "$SH/probe_some.sh" "$UP")"
[ "$got" = "freeze/merged-m19 freeze/merged-m16" ] && ok "plan: $got" || bad "plan: '$got', want 'freeze/merged-m19 freeze/merged-m16'"
echo "== 2. no earlier release holds a zip"
got="$(plan "$SH/probe_none.sh" "$UP")"
[ "$got" = "none" ] && ok "plan: none" || bad "plan: '$got', want 'none'"

if vs_ctl_is previous-only; then
    [ "$fail" = 1 ] && { echo "FAIL: test_release_prune (control mode: the one-tag walk was caught)"; exit 1; }
    echo "FAIL: test_release_prune — the one-tag walk passed section 1"; exit 1
fi
echo "== 3. controls"
if previous_only; then
    got="$(plan "$SH/probe_some.sh" "$SH/tools/upload_release_assets.sh")"
    if [ "$got" != "freeze/merged-m19 freeze/merged-m16" ]; then vs_ctl_fired previous-only "the one-tag walk plans '$got' for freeze/merged-m22"
    else vs_ctl_dead previous-only "the one-tag walk planned the full set"; fail=1; fi
else vs_ctl_dead previous-only "could not build the shadow"; fail=1; fi

[ "$fail" = 0 ] && echo "PASS: test_release_prune" || echo "FAIL: test_release_prune"
exit "$fail"
