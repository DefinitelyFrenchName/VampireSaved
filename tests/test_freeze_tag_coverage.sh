#!/bin/sh
# test_freeze_tag_coverage.sh — EVERY FROZEN BUILD IS GIT-TAGGED (14z-126b).
# ci_portable: no ROM, no build dir, no emulator, ~1 s. Needs git tags.
#
# MUST-FIRE: perturbed-copy: untagged-row — a registry copy with a build row that has no freeze tag must fail section 1
# MUST-FIRE: perturbed-copy: fingerprint-not-in-tag — a registry copy with one fingerprint perturbed must fail section 3 (the tag message cannot name it)
#
# WHAT IT HOLDS. `tests/expected/registry.tsv` states the invariant in its own
# header: "Rows added only at freeze time... Every row also has an annotated
# git tag freeze/<expectation-set> at the commit that froze it — the way back
# to a tree that reproduces it." That is [VSP-94] (CLAUDE.md 5, HANDOFF "Build
# registry"), and until this gate nothing checked it.
#
# WHY IT EXISTS. The 14z-91 LEGACY-REGRESSION batch — donovan-m7 / huitzil-m15
# / pyron-m9 — had registry rows from 2026-08-16 and NO tag, for 35 sessions.
# Nobody noticed because the only place it showed was HANDOFF's `Previous
# batch` prose, and that prose was chronology nobody read. It surfaced only
# when the chronology was DELETED (14z-126b) and the surviving carriers had to
# be enumerated one by one. The tags exist now; this is what keeps them
# existing. A freeze whose tag is missing is not a bookkeeping slip: the tag
# is the only route back to a tree that reproduces a superseded build, because
# its manifests have moved on (HANDOFF: pyron-m1 and huitzil-m1 "cannot be
# produced from today's tree").
#
# THREE SECTIONS:
#   1 HARD  every registry row that is a BUILD has an ANNOTATED freeze/<set>.
#           The documented non-builds are excused BY SHAPE, not by name:
#           `*-stock` and `*-stage4` (the M2 battery's two legs — HANDOFF
#           "TWO REGISTRY ROWS ARE NOT BUILDS", 14z-97/#96, and they
#           carry-rename at every freeze so a name list would rot) and the
#           `vsavj` null baseline. A row with any OTHER shape must be tagged.
#   2 HARD  no lightweight tags — [VSP-94] says annotated, and a lightweight
#           tag carries no message, so it cannot carry the fingerprint or the
#           reproduce recipe the rule asks for.
#   3 HARD  the tag message names its build's fingerprint (full SHA-1 or the
#           8-char short form) — [VSP-94]: "the tag message carries the
#           fingerprint and how to reproduce". A tag that says what a freeze
#           CHANGED but never which image it certifies cannot answer the one
#           question it exists for. WAS GRANDFATHERED when this gate opened:
#           three tags carried neither form — the 14z-102 window freeze
#           (donovan-m10 / huitzil-m19 / pyron-m13) — and were held as a named
#           allow-list so they could not GROW. The maintainer ruled the amend
#           on 2026-09-01; all three tag messages were rewritten (commit
#           unchanged) and force-pushed, so the allowance had no reason left
#           and was REMOVED rather than left to rot. There are now no
#           exceptions.
#
# MUST-FIRE CONTROLS (both on a COPY; the gate never edits a tracked file and
# never creates, moves or deletes a tag):
#   a  a registry row naming a build with no tag       -> section 1 fires
#   b  a tagged build whose registry fingerprint the tag message does NOT
#      contain (a copy with one fingerprint perturbed)  -> section 3 fires
#
# Env: REGISTRY=<path> (default tests/expected/registry.tsv).
set -u
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$(dirname "$0")/.."
REGISTRY="${REGISTRY:-tests/expected/registry.tsv}"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$(dirname "$0")/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
perturb() {  # perturb <name> <out> — a COPY of the registry
    case "$1" in
    untagged-row) cp "$REGISTRY" "$2"; printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\tdonovan-m99\tsynthetic control row\n' >> "$2" ;;
    fingerprint-not-in-tag) awk -F'\t' 'BEGIN{OFS="\t"} $2=="donovan-m18"{$1="0123456789abcdef0123456789abcdef01234567"} {print}' "$REGISTRY" > "$2" ;;
    esac
}
# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS the registry
# the sections read — and this run must FAIL. The control sub-runs below are
# skipped under the mode (the mode is the control).
if [ -n "$VS_CTL" ]; then perturb "$VS_CTL" "$W/mode.tsv"; REGISTRY="$W/mode.tsv"; FTC_CONTROLS=0; fi

echo "== test_freeze_tag_coverage: every frozen build is git-tagged =="

if [ -z "$(git tag -l 'freeze/*' 2>/dev/null)" ]; then
    echo "SKIP: no freeze/* tags in this checkout (a tagless clone cannot assert this)"
    exit 0
fi
[ -f "$REGISTRY" ] || { bad "no registry at $REGISTRY"; echo FAIL; exit 1; }

# --- 1: every BUILD row has an annotated tag -------------------------------
missing=0; checked=0; excused=0
while IFS="$(printf '\t')" read -r fp set rest; do
    case "$fp" in \#*|"") continue;; esac
    [ -n "${set:-}" ] || continue
    case "$set" in
        *-stock|*-stage4|vsavj) excused=$((excused+1)); continue;;
    esac
    checked=$((checked+1))
    if ! git rev-parse -q --verify "refs/tags/freeze/$set" >/dev/null 2>&1; then
        bad "NO FREEZE TAG for registry row '$set' (fp $(echo "$fp" | cut -c1-8)) — [VSP-94]"
        missing=$((missing+1))
    elif [ "$(git cat-file -t "refs/tags/freeze/$set" 2>/dev/null)" != tag ]; then
        bad "freeze/$set is LIGHTWEIGHT — [VSP-94] requires an annotated tag"
        missing=$((missing+1))
    fi
done < "$REGISTRY"
[ "$missing" = 0 ] && ok "all $checked build rows carry an annotated freeze tag ($excused non-builds excused by shape)"

# --- 2: no lightweight tags anywhere in the namespace ----------------------
light=0
for t in $(git tag -l 'freeze/*'); do
    [ "$(git cat-file -t "$t")" = tag ] || { bad "LIGHTWEIGHT TAG: $t"; light=$((light+1)); }
done
[ "$light" = 0 ] && ok "all $(git tag -l 'freeze/*' | wc -l | tr -d ' ') freeze/* tags are annotated"

# --- 3: the tag message names its fingerprint (grandfathered) --------------
nofp=""
while IFS="$(printf '\t')" read -r fp set rest; do
    case "$fp" in \#*|"") continue;; esac
    [ -n "${set:-}" ] || continue
    git rev-parse -q --verify "refs/tags/freeze/$set" >/dev/null 2>&1 || continue
    msg="$(git tag -l --format='%(contents)' "freeze/$set")"
    short="$(echo "$fp" | cut -c1-8)"
    case "$msg" in *"$fp"*|*"$short"*) continue;; esac
    nofp="$nofp $set"
done < "$REGISTRY"
if [ -n "$nofp" ]; then
    bad "TAG MESSAGE NAMES NO FINGERPRINT:$nofp"
    bad "  [VSP-94]: the tag message carries the fingerprint and how to reproduce."
    bad "  Amend it (git tag -f -a <tag> <same commit>) and force-push."
else
    ok "every freeze tag's message names its build's fingerprint"
fi

# --- must-fire controls, on COPIES; no tag is ever created/moved/deleted ---
# FTC_CONTROLS=0 marks the sub-runs so they do not recurse.
if [ "${FTC_CONTROLS:-1}" = 1 ]; then
    perturb untagged-row "$W/reg.tsv"
    if CONTROL= FTC_CONTROLS=0 REGISTRY="$W/reg.tsv" sh "$SELF" >"$W/a.log" 2>&1; then
        vs_ctl_dead untagged-row "an untagged build row PASSED — section 1 is not checking"; bad "control a"
    elif grep -q "NO FREEZE TAG for registry row 'donovan-m99'" "$W/a.log"; then
        vs_ctl_fired untagged-row "an untagged build row fails section 1"; ok "control a: an untagged build row fires"
    else
        vs_ctl_dead untagged-row "fired for the wrong reason"; bad "control a:"; sed 's/^/        /' "$W/a.log" | head -6
    fi
    # a tagged build whose registry fingerprint its tag message cannot contain
    perturb fingerprint-not-in-tag "$W/reg_b.tsv"
    if CONTROL= FTC_CONTROLS=0 REGISTRY="$W/reg_b.tsv" sh "$SELF" >"$W/b.log" 2>&1; then
        vs_ctl_dead fingerprint-not-in-tag "a fingerprint the tag message lacks PASSED — section 3 is vacuous"; bad "control b"
    elif grep -q "TAG MESSAGE NAMES NO FINGERPRINT.*donovan-m18" "$W/b.log"; then
        vs_ctl_fired fingerprint-not-in-tag "a tag whose message lacks its fingerprint fails section 3"; ok "control b: fires"
    else
        vs_ctl_dead fingerprint-not-in-tag "fired for the wrong reason"; bad "control b:"; sed 's/^/        /' "$W/b.log" | head -6
    fi
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
