#!/bin/sh
# test_fbneo_tree_integrity_control.sh — ground truth for the emu/fbneo tree
# integrity gate (14z-90, GitHub issue #36).
#
# WHY A CONTROL AT ALL. The obvious implementation of that gate — and the one
# the issue suggests — is `git apply -R --check` against the tracked patches.
# It FAILS OPEN on the issue's own failure scenario. Measured on a scratch
# copy:
#     append one line at EOF of cps_obj.cpp        -> apply -R --check rc=0
#     insert one line at line 200                  -> apply -R --check rc=0
#     insert one line at line 430 (inside a hunk)  -> rc=1
# because `apply -R --check` only asserts the patch's own hunk context is
# present; it says nothing about the other ~95% of an 896-line file, and
# nothing at all about files no patch touches.
#
# So this control asserts the real gate catches what the plausible-but-wrong
# one misses. Case 1 is the load-bearing one: it is the exact edit the issue
# describes ("a session hand-edits cps_obj.cpp to probe the bit-12 promote"
# and forgets to remove it).
#
# The gate is run against a SCRATCH COPY of the tree, never the live one — a
# control that mutates emu/fbneo would be worse than the defect.
#
# Usage: tests/test_fbneo_tree_integrity_control.sh   (no ROMs/emulator, ~20s)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

FB="$REPO/emu/fbneo"
[ -d "$FB/.git" ] || [ -f "$FB/.git" ] || { echo "FAIL: no emu/fbneo"; exit 1; }

# Build a scratch repo whose emu/fbneo is a copy of the live one, so the gate
# under test resolves REPO to the scratch dir.
S="$WORK/repo"
mkdir -p "$S/emu" "$S/tests"
cp "$REPO/tests/test_fbneo_tree_integrity.sh" "$S/tests/"
chmod +x "$S/tests/test_fbneo_tree_integrity.sh"
cp -R "$REPO/emu/fbneo-patches" "$S/emu/"
# a git clone of the submodule, then re-apply the patch state by copying the
# 8 changed files across (cheap: no full working-tree copy of 700 MB)
git clone -q --no-checkout --shared "$FB" "$S/emu/fbneo" 2>/dev/null || {
    echo "FAIL: could not clone the submodule for the scratch tree"; exit 1; }
git -C "$S/emu/fbneo" checkout -q "$(git -C "$FB" rev-parse HEAD)"
for f in makefile.sdl2 src/burn/drv/capcom/cps.cpp src/burn/drv/capcom/cps.h \
         src/burn/drv/capcom/cps_obj.cpp src/burn/drv/capcom/cps_rw.cpp \
         src/burn/drv/capcom/d_cps2.cpp src/burner/sdl/main.cpp \
         src/burner/sdl/harness.cpp; do
    cp "$FB/$f" "$S/emu/fbneo/$f"
done

run_gate() { set +e; GOUT="$("$S/tests/test_fbneo_tree_integrity.sh" 2>&1)"; GRC=$?; set -e; }

echo "== 0. baseline: the scratch copy passes =="
run_gate
if [ "$GRC" = 0 ]; then echo "  ok: clean copy passes"
else echo "FAIL: the scratch copy does not pass — the control is unsound"
     echo "$GOUT" | tail -4; exit 1; fi

TARGET="$S/emu/fbneo/src/burn/drv/capcom/cps_obj.cpp"
cp "$TARGET" "$WORK/cps_obj.orig"

echo "== 1. a forgotten probe at EOF — the case apply -R --check ACCEPTS =="
printf '// forgotten debug probe\n' >> "$TARGET"
run_gate
if [ "$GRC" != 0 ] && echo "$GOUT" | grep -q "DIFFERS from pinned-commit"; then
    echo "  ok: caught, and named the file"
else
    echo "FAIL: an EOF edit was NOT caught (rc=$GRC) — the gate fails open on"
    echo "      exactly the scenario the issue describes"; fail=1
fi
# and prove the rejected alternative really does accept it
if ( cd "$S/emu/fbneo" && git apply -R --check "$S/emu/fbneo-patches/0001-vampire-saved-harness.patch" \
      "$S/emu/fbneo-patches/0002-cps2-wide-v1.patch" 2>/dev/null ); then
    echo "  ok: confirmed 'git apply -R --check' ACCEPTS the same edit"
else
    echo "  note: apply -R --check also rejected it — the comparison case has"
    echo "        moved; re-derive the example before trusting this rationale"
fi
cp "$WORK/cps_obj.orig" "$TARGET"

echo "== 2. an edit far from any hunk (line 200) =="
awk 'NR==200{print "// stray edit"}1' "$WORK/cps_obj.orig" > "$TARGET"
run_gate
[ "$GRC" != 0 ] && echo "  ok: caught" || { echo "FAIL: a line-200 edit was not caught"; fail=1; }
cp "$WORK/cps_obj.orig" "$TARGET"

echo "== 3. harness.cpp edited — the untracked file a diff cannot see =="
H="$S/emu/fbneo/src/burner/sdl/harness.cpp"; cp "$H" "$WORK/harness.orig"
printf '// stray\n' >> "$H"
run_gate
[ "$GRC" != 0 ] && echo "  ok: caught (this is why the gate reconstructs rather than diffs)" \
   || { echo "FAIL: an edit to the UNTRACKED harness.cpp was not caught"; fail=1; }
cp "$WORK/harness.orig" "$H"

echo "== 4. an extra untracked file in the tree =="
printf 'x\n' > "$S/emu/fbneo/src/burner/sdl/stray_probe.cpp"
run_gate
if [ "$GRC" != 0 ] && echo "$GOUT" | grep -q "changed-file set"; then
    echo "  ok: inventory check caught a file no patch touches"
else
    echo "FAIL: a stray untracked file was not caught (rc=$GRC)"; fail=1
fi
rm -f "$S/emu/fbneo/src/burner/sdl/stray_probe.cpp"

echo "== 5. restored: the gate passes again (no false alarm) =="
run_gate
[ "$GRC" = 0 ] && echo "  ok: clean again" \
   || { echo "FAIL: the gate stays red after restoration — false alarm"; echo "$GOUT" | tail -4; fail=1; }

[ "$fail" = 0 ] && echo "PASS: fbneo tree-integrity gate (4 drift cases incl. the one apply -R misses, + restore)" \
    || { echo "FAIL: fbneo tree-integrity gate"; exit 1; }
