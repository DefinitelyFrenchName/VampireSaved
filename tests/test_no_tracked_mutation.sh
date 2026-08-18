#!/bin/sh
# test_no_tracked_mutation.sh — test instrumentation must not write tracked
# source (14z-94, GitHub #81). ROM-free, ~2 s.
#
# THE DEFECT. Several verdict controls prove a substitution site is live by
# PERTURBING tools/gen_donovan_patch.py and re-running it. They edited the
# tracked file in place and restored from a snapshot on an exit trap.
#
# An exit trap covers an ordinary Ctrl-C and nothing else:
#   * two of these gates in two terminals, or two CI workers on one checkout,
#     each snapshot a different transient state and restore over each other;
#   * SIGKILL, a crashed shell or a lost machine leaves the generator
#     PERTURBED — and it is the file every build runs;
#   * a legitimate edit saved DURING a long control suite is silently
#     overwritten by the restore.
#
# None of those requires anything unusual. And the old self-check could not
# see any of them: it compared the file against a snapshot taken by THAT run,
# so a concurrent clobber or a reverted real edit both read as "restored".
#
# THE FIX is tests/lib/shadow_tools.sh — a writable copy inside a throwaway
# repo ROOT (the generator resolves its repo from `Path(__file__).parent
# .parent`, so a bare /tmp copy would find neither the manifests nor its
# sibling modules). Section 3 is the systemic half: it fails any NEW test that
# writes into tools/, which is how this pattern spread in the first place.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

echo "== 1. the shadow helper produces a working, ISOLATED copy =="
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
. "$REPO/tests/lib/shadow_tools.sh"
GEN="$(shadow_tool "$T" gen_donovan_patch.py)"
if [ -f "$GEN" ] && [ ! -L "$GEN" ]; then
    echo "  ok: a real (non-symlink) copy — a symlink would write through"
else
    fail "the shadow is missing or is a SYMLINK, which would write through to"
    fail "      tracked source and defeat the entire fix"
fi
python3 -c "
from pathlib import Path
root = Path('$GEN').resolve().parent.parent
import sys
missing = [p for p in ('build/manifest/donovan.toml', 'tools/cps2_decrypt.py',
                       'tools/_minitoml.py') if not (root / p).exists()]
if missing:
    print('  FAIL: the shadow root cannot reach', missing)
    print('        — the generator resolves its repo from __file__, so it')
    print('        would not find its manifests or its sibling modules')
    sys.exit(1)
print('  ok: the shadow root reaches the manifests and the sibling modules')
" || rc=1

echo "== 2. THE CONTROL — perturbing the shadow leaves tracked source alone =="
before="$(shasum -a 1 tools/gen_donovan_patch.py | cut -d' ' -f1)"
printf '\n# perturbation written by test_no_tracked_mutation.sh\n' >> "$GEN"
after="$(shasum -a 1 tools/gen_donovan_patch.py | cut -d' ' -f1)"
if [ "$before" = "$after" ]; then
    echo "  ok: tracked source unchanged after writing the shadow"
else
    fail "WRITING THE SHADOW CHANGED THE TRACKED FILE — the isolation is fake"
fi
if [ "$(shasum -a 1 "$GEN" | cut -d' ' -f1)" = "$before" ]; then
    fail "the shadow did NOT change either, so section 2 proves nothing —"
    fail "      the perturbation is not landing anywhere"
else
    echo "  ok: and the shadow itself DID change (so the write happened)"
fi
shadow_restore "$T" gen_donovan_patch.py
if [ "$(shasum -a 1 "$GEN" | cut -d' ' -f1)" = "$before" ]; then
    echo "  ok: shadow_restore returns the copy to pristine"
else
    fail "shadow_restore did not restore the shadow"
fi

echo "== 3. no test writes into tools/ (the systemic half) =="
# The pattern spread by copying, so the check has to cover the whole
# directory rather than the two files that were found.
hits=""
for f in tests/*.sh; do
    b="$(basename "$f")"
    [ "$b" = "test_no_tracked_mutation.sh" ] && continue
    # Strip comments so PROSE describing the old pattern is not a hit.
    body="$(sed 's/#.*//' "$f")"
    # (a) a python heredoc writing a literal tools/ path
    if printf '%s' "$body" | grep -q 'Path("tools/' && \
       printf '%s' "$body" | grep -q 'write_text'; then
        hits="$hits $b(write_text)"
    fi
    # (b) shell copying/redirecting/editing INTO tools/
    if printf '%s' "$body" | grep -qE '(^|[^-])> *"?tools/|cp +[^|]*[ "]tools/[a-z_]+\.(py|sh)"? *$|sed +-i[^|]* tools/'; then
        hits="$hits $b(shell-write)"
    fi
done
if [ -n "$hits" ]; then
    fail "test(s) writing tracked source:$hits"
    fail "      Use tests/lib/shadow_tools.sh instead — an exit trap does not"
    fail "      survive SIGKILL, concurrent runs, or a real edit made mid-run."
else
    echo "  ok: no test script writes into tools/"
fi

echo "== 4. CONTROL — that scan actually detects the pattern =="
# Otherwise section 3 passes on a clean tree and on a broken checker alike.
mkdir -p "$T/fake"
cat > "$T/fake/test_bad.sh" <<'BAD'
#!/bin/sh
python3 - <<'PY'
import pathlib
p = pathlib.Path("tools/gen_donovan_patch.py")
p.write_text(p.read_text().replace("a", "b"))
PY
BAD
body="$(sed 's/#.*//' "$T/fake/test_bad.sh")"
if printf '%s' "$body" | grep -q 'Path("tools/' && \
   printf '%s' "$body" | grep -q 'write_text'; then
    echo "  ok: a deliberately offending test IS detected"
else
    fail "the scan does not detect a clear in-place mutation, so section 3"
    fail "      is not evidence of anything"
fi

echo "== 5. the two gates that had the pattern now use the shadow =="
for f in tests/test_tenant_row_owner.sh tests/test_tenant_loop.sh; do
    if grep -q "shadow_tool" "$f"; then
        echo "  ok: $(basename "$f") uses shadow_tool"
    else
        fail "$f no longer uses the shadow helper"
    fi
done
# And the row-owner gate's self-check must ask GIT, not its own snapshot.
if grep -q "git .*diff --quiet -- tools/gen_donovan_patch.py" \
        tests/test_tenant_row_owner.sh; then
    echo "  ok: its integrity check asks git, not a snapshot it took itself"
else
    fail "test_tenant_row_owner.sh still self-checks against its own snapshot,"
    fail "      which passes even when a concurrent run clobbered the file"
fi

echo "== a directory a GATE WRITES TO must not be a TRACKED reference =="
# 14z-95 (GitHub #97). The sibling of the defect above: not a test editing
# tracked SOURCE, but a test building over tracked OUTPUT. run_battery_m2.sh
# builds into build/donovan6 and test_m2a_stage4_code.sh used to build into
# build/donovan_stage4_gate; both carried tracked generator artifacts
# committed at 14z-47/48/49, so every suite run rewrote committed files and
# left a diff. A pre-commit chain whose own side effect is a diff is one
# people learn to scroll past — which is how a REAL unexpected modification
# gets missed.
#
# SCOPE, deliberately narrow: this checks only the dirs a gate WRITES. The
# other ~200 tracked build dirs are frozen historical builds that nothing
# overwrites; whether they belong in git is a separate repo-wide question and
# is NOT what this asserts.
for _d in build/donovan6 build/donovan_stage4_gate; do
    _n=$(git ls-files "$_d" | wc -l | tr -d ' ')
    if [ "$_n" = 0 ]; then
        echo "  ok: $_d has no tracked files"
    else
        fail "$_d has $_n TRACKED file(s) — a gate builds here, so every run"
        fail "      rewrites committed artifacts. Untrack them (they are"
        fail "      generator output) or point the gate elsewhere."
    fi
done
# and the battery's default target must remain one of those ignored dirs, so
# the tracked-ness above cannot be re-introduced by re-pointing the writer
_ob=$(grep -m1 '^OUTBASE=' "$REPO/tests/run_battery_m2.sh" 2>/dev/null || true)
case "$_ob" in
    *build/donovan6*) echo "  ok: run_battery_m2 still targets an ignored dir" ;;
    *) fail "run_battery_m2's default OUTBASE changed ($_ob) — re-check that"
       fail "      its target is git-ignored before trusting the check above" ;;
esac

echo
[ "$rc" = 0 ] && echo "PASS: tests perturb copies, never tracked source." \
             || echo "FAIL: see above."
exit $rc
