#!/bin/sh
# test_freeze_tag_coverage.sh — EVERY FROZEN BUILD IS GIT-TAGGED (14z-126b).
# ci_portable: no ROM, no build dir, no emulator, ~1 s. Needs git tags.
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
#   3 GRANDFATHERED  the tag message names its build's fingerprint (full SHA-1
#           or the 8-char short form). THREE tags predate this check and carry
#           neither — the 14z-102 window freeze (donovan-m10, huitzil-m19,
#           pyron-m13), whose messages describe the freeze but name no build.
#           They are frozen as a named allow-list so they cannot grow: a FOURTH
#           such tag FAILS. Fixing the three is a re-tag, not this gate's job.
#
# MUST-FIRE CONTROLS (both on a COPY; the gate never edits a tracked file and
# never creates, moves or deletes a tag):
#   a  a registry row naming a build with no tag  -> section 1 fires
#   b  the section-3 allow-list emptied           -> section 3 fires on the
#      three known tags, proving the check is live and not vacuous
#
# Env: REGISTRY=<path> (default tests/expected/registry.tsv);
#      NOFP_ALLOW="<sets>" (default the three; "" is control b).
set -u
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$(dirname "$0")/.."
REGISTRY="${REGISTRY:-tests/expected/registry.tsv}"
NOFP_ALLOW="${NOFP_ALLOW-donovan-m10 huitzil-m19 pyron-m13}"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

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
unexpected=""
for s in $nofp; do
    case " $NOFP_ALLOW " in *" $s "*) ;; *) unexpected="$unexpected $s";; esac
done
if [ -n "$unexpected" ]; then
    bad "TAG MESSAGE NAMES NO FINGERPRINT (beyond the frozen three):$unexpected"
    bad "  [VSP-94]: the tag message carries the fingerprint and how to reproduce."
else
    ok "fingerprint-in-message: only the frozen$( [ -n "$NOFP_ALLOW" ] && echo " 14z-102 three" ) lack it (${nofp:-none})"
fi

# --- must-fire controls, on COPIES; no tag is ever created/moved/deleted ---
# FTC_CONTROLS=0 marks the sub-runs so they do not recurse.
if [ "${FTC_CONTROLS:-1}" = 1 ]; then
    W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
    cp "$REGISTRY" "$W/reg.tsv"
    printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\tdonovan-m99\tsynthetic control row\n' >> "$W/reg.tsv"
    if FTC_CONTROLS=0 REGISTRY="$W/reg.tsv" sh "$SELF" >"$W/a.log" 2>&1; then
        bad "control a: an untagged build row PASSED — section 1 is not checking"
    elif grep -q "NO FREEZE TAG for registry row 'donovan-m99'" "$W/a.log"; then
        ok "control a: an untagged build row fires"
    else
        bad "control a: fired for the wrong reason:"; sed 's/^/        /' "$W/a.log" | head -6
    fi
    if FTC_CONTROLS=0 NOFP_ALLOW="" sh "$SELF" >"$W/b.log" 2>&1; then
        bad "control b: the emptied allow-list PASSED — section 3 is vacuous"
    elif grep -q "TAG MESSAGE NAMES NO FINGERPRINT" "$W/b.log"; then
        ok "control b: section 3 fires when its allow-list is emptied"
    else
        bad "control b: fired for the wrong reason:"; sed 's/^/        /' "$W/b.log" | head -6
    fi
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
