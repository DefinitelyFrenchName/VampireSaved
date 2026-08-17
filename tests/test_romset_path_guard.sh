#!/bin/sh
# test_romset_path_guard.sh — build_wide_romset must never write into, or
# delete, the reference set (14z-94, GitHub #76). ROM-free, ~2 s: the fixture
# builds its own fake romdir, so no real dump is ever at risk in this test.
#
# THE DEFECT. The tool's docstring promises "the reference set in ROMDIR is
# never modified". Nothing enforced it. With outdir == romdir the overlay
# loop does, in order:
#
#     for z in sorted(os.listdir(romdir)):        # the SOURCE zips
#         if os.path.islink(dst) or os.path.exists(dst): os.remove(dst)
#         os.symlink(os.path.join(romdir, z), dst)   # src == dst
#
# — deletes every source zip, then leaves a self-referential symlink in its
# place. THIS IS THE ONE FAILURE IN THIS FILE WITH NO UNDO: rule 7 forbids
# keeping romset copies in the tree, so there is nothing to restore from.
# No malicious input is needed; a wrong second argument is enough.
#
# WHAT IS ASSERTED. Identity, `..` spellings, symlink aliases, and
# containment in either direction are refused BEFORE any mutation — and the
# source zips are byte-identical afterwards, which is the acceptance
# criterion that actually matters. Section 5 is the other half: a legitimate
# separate-directory build must still work, or "reject everything" would pass
# every other section here.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
FAKE="$T/romdir"
mkdir -p "$FAKE"

# A fake reference set: real zips (so the tool gets far enough to be
# destructive) with contents it never inspects before the overlay loop.
python3 - "$FAKE" <<'PY'
import sys, zipfile, os
d = sys.argv[1]
for name in ("vsavj.zip", "vsav.zip", "vsav2.zip"):
    with zipfile.ZipFile(os.path.join(d, name), "w") as z:
        z.writestr("vm3.03", b"\xAA" * 64)
        z.writestr("vm3.01", b"\xBB" * 64)
        z.writestr("vm3.02", b"\xCC" * 64)
PY

hashes() { (cd "$FAKE" && for f in *.zip; do
             printf '%s %s\n' "$f" "$(shasum -a 1 "$f" | cut -d' ' -f1)"; done); }
BEFORE="$(hashes)"

# `run <outdir>` — returns the tool's exit status, output in $T/out
run() { python3 tools/build_wide_romset.py "$FAKE" "$1" > "$T/out" 2>&1; }

must_reject() { # must_reject <label> <outdir>
    if run "$2"; then
        fail "$1: ACCEPTED — this invocation deletes the reference set"
    elif grep -qi "refusing to build" "$T/out"; then
        echo "  ok: $1 refused"
    else
        fail "$1: failed, but not by the guard (so an unrelated error is"
        fail "        masking the hole): $(head -1 "$T/out")"
    fi
    if [ "$(hashes)" != "$BEFORE" ]; then
        fail "$1: THE SOURCE ZIPS CHANGED — mutation happened before the check"
    fi
}

echo "== 1. IDENTITY — outdir is romdir =="
must_reject "outdir == romdir" "$FAKE"

echo "== 2. the same directory spelled through '..' =="
must_reject "romdir/../romdir" "$FAKE/../romdir"

echo "== 3. a SYMLINK alias of the input =="
ln -s "$FAKE" "$T/alias"
must_reject "outdir -> symlink to romdir" "$T/alias"

echo "== 4. CONTAINMENT, both directions =="
must_reject "outdir inside romdir" "$FAKE/sub/out"

# The other direction needs a REAL nested reference set: a symlink into it
# would resolve back outside, and the guard compares realpaths — so that
# fixture would prove nothing (it is how this section first passed wrongly).
NEST="$T/outer/inner_romdir"
mkdir -p "$NEST"
cp "$FAKE"/*.zip "$NEST/"
NEST_BEFORE="$(cd "$NEST" && shasum -a 1 ./*.zip)"
if python3 tools/build_wide_romset.py "$NEST" "$T/outer" > "$T/out" 2>&1; then
    fail "romdir inside outdir: ACCEPTED"
elif grep -qi "refusing to build" "$T/out"; then
    echo "  ok: romdir inside outdir refused"
else
    fail "romdir inside outdir: failed for another reason: $(head -1 "$T/out")"
fi
if [ "$(cd "$NEST" && shasum -a 1 ./*.zip)" != "$NEST_BEFORE" ]; then
    fail "the NESTED reference set was modified before the check"
fi
[ "$(hashes)" = "$BEFORE" ] || fail "source zips changed during section 4"

echo "== 5. CONTROL — a legitimate separate-directory build still works =="
# Without this, a guard that rejected everything would pass sections 1-4.
if run "$T/good/rompath"; then
    if [ -f "$T/good/rompath/vsavjw.zip" ]; then
        echo "  ok: a disjoint outdir builds, and produced vsavjw.zip"
    else
        fail "the build reported success but wrote no vsavjw.zip"
    fi
else
    fail "a LEGITIMATE separate-directory build was rejected:"
    sed 's/^/        /' "$T/out" | head -4
fi

echo "== 6. the reference set is byte-identical after all of the above =="
AFTER="$(hashes)"
if [ "$AFTER" = "$BEFORE" ]; then
    echo "  ok: all $(printf '%s\n' "$BEFORE" | wc -l | tr -d ' ') source zips unchanged"
    printf '%s\n' "$BEFORE" | sed 's/^/      /'
else
    fail "THE REFERENCE SET WAS MODIFIED:"
    # No process substitution: this file is #!/bin/sh and must stay POSIX
    # (tests/test_shell_portability.sh gates that).
    printf '%s\n' "$BEFORE" > "$T/before.txt"
    printf '%s\n' "$AFTER"  > "$T/after.txt"
    diff "$T/before.txt" "$T/after.txt" | sed 's/^/        /'
fi

echo
[ "$rc" = 0 ] && echo "PASS: the reference set cannot be the build's output." \
             || echo "FAIL: see above."
exit $rc
