#!/bin/sh
# test_fbneo_tree_integrity.sh — the emu/fbneo working tree must be EXACTLY
# the pinned upstream commit plus the two tracked patches (14z-90, issue #36).
#
# WHY. CLAUDE.md rule 1 makes the patch files the trust surface: "the trust
# surface of emulator changes must remain a small, human-reviewable set of
# declarative mapping lines." That is only true if the BINARY WE BUILD comes
# from those lines. tools/setup_fbneo.sh could not check it: on an
# already-patched tree its forward `apply --check` fails, so it falls to an
# `elif` that tests `[ -f harness.cpp ]` and greps cps.h for one string —
# name-existence and a substring. Any other edit is silently accepted, and
# harness.cpp is UNTRACKED in the submodule so `git -C emu/fbneo diff` does
# not contain it at all.
#
# WHY NOT `git apply -R --check`, which is the obvious fix and the one the
# issue suggests: it only validates HUNK CONTEXT WINDOWS. Measured on a
# scratch copy during 14z-90:
#     append one line at EOF of cps_obj.cpp      -> apply -R --check rc=0
#     insert one line at line 200                -> apply -R --check rc=0
#     insert one line at line 430 (inside a hunk)-> rc=1
# So the issue's own failure scenario — "a session hand-edits cps_obj.cpp to
# probe the bit-12 promote" — passes that check unless the edit happens to
# land within ~3 lines of an existing hunk. A check that fails open on the
# scenario it was written for is worse than none.
#
# So this RECONSTRUCTS the expected tree (pinned commit + both patches into a
# scratch dir) and compares WHOLE FILES with cmp, plus an inventory check so
# drift in a file no patch touches cannot hide either.
#
# Usage: tests/test_fbneo_tree_integrity.sh   (no ROMs, no emulator, ~5s)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
FB="$REPO/emu/fbneo"
P1="$REPO/emu/fbneo-patches/0001-vampire-saved-harness.patch"
P2="$REPO/emu/fbneo-patches/0002-cps2-wide-v1.patch"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# The frozen expectation. Update these THREE together, in the same commit as
# any change to the patches, or this gate is lying.
PINNED="79188379cc8442c54712acbe3b7e73dce157985f"
PATCHED_FILES="makefile.sdl2
src/burn/drv/capcom/cps.cpp
src/burn/drv/capcom/cps.h
src/burn/drv/capcom/cps_obj.cpp
src/burn/drv/capcom/cps_rw.cpp
src/burn/drv/capcom/d_cps2.cpp
src/burner/sdl/main.cpp
src/burner/sdl/harness.cpp"

[ -d "$FB/.git" ] || [ -f "$FB/.git" ] || {
    echo "FAIL: no emu/fbneo submodule — run tools/setup_fbneo.sh"; exit 1; }

echo "== 1. the submodule is at the pinned commit =="
got="$(git -C "$FB" rev-parse HEAD)"
if [ "$got" = "$PINNED" ]; then
    echo "  ok: $PINNED"
else
    echo "FAIL: submodule at $got, expected $PINNED"
    echo "      an upstream bump invalidates both patches' line numbers"
    fail=1
fi

echo "== 2. exactly the expected files are modified or added =="
# -uall so an untracked file anywhere is visible; harness.cpp is expected to
# be one, which is precisely why a diff-based check cannot see it.
inv="$(git -C "$FB" status --porcelain -uall | sed 's/^...//' | sort)"
want="$(printf '%s\n' "$PATCHED_FILES" | sort)"
if [ "$inv" = "$want" ]; then
    echo "  ok: 8 files, matching the patch inventory"
else
    echo "FAIL: the working tree's changed-file set is not the patch set."
    echo "      unexpected or missing:"
    printf '%s\n' "$inv" > "$WORK/got.txt"; printf '%s\n' "$want" > "$WORK/want.txt"
    diff "$WORK/want.txt" "$WORK/got.txt" | sed 's/^/        /' || true
    fail=1
fi

echo "== 3. every patched file matches the reconstruction, byte for byte =="
T="$WORK/expect"
mkdir -p "$T"
git -C "$FB" archive "$PINNED" | tar -x -C "$T"
( cd "$T" && git init -q . && git apply "$P1" "$P2" ) || {
    echo "FAIL: the tracked patches do not apply cleanly to the pinned commit"
    echo "      — the patches themselves are broken, not the tree"
    exit 1
}
n_ok=0
for f in $PATCHED_FILES; do
    if [ ! -f "$FB/$f" ]; then
        echo "FAIL: $f missing from the working tree"; fail=1; continue
    fi
    if [ ! -f "$T/$f" ]; then
        echo "FAIL: $f is in the tree but the patches do not create it"; fail=1; continue
    fi
    if cmp -s "$T/$f" "$FB/$f"; then
        n_ok=$((n_ok+1))
    else
        echo "FAIL: $f DIFFERS from pinned-commit + tracked patches"
        echo "      (the built binary would not come from the reviewed lines)"
        diff "$T/$f" "$FB/$f" | head -6 | sed 's/^/        /' || true
        fail=1
    fi
done
[ "$fail" = 0 ] && echo "  ok: $n_ok/8 files byte-identical to the reconstruction"

[ "$fail" = 0 ] && echo "PASS: emu/fbneo is exactly the pinned commit + the two tracked patches" \
    || { echo "FAIL: emu/fbneo tree integrity"; exit 1; }
