#!/bin/sh
# test_romset_path_guard.sh — build_wide_romset must never write into, or
# delete, the reference set (14z-94, GitHub #76). ROM-free, ~2 s: the fixture
# builds its own fake romdir, so no real dump is ever at risk in this test.
#
# WHAT: build_wide_romset never writes into, or deletes, the reference set: identity, `..`
#   spellings, symlink aliases and containment in either direction between outdir and romdir
#   are refused BEFORE any mutation, the source zips byte-identical afterwards — the one
#   failure in that file with no undo — and a legitimate separate directory still builds.
# HOW: a fake romdir fixture (no real dump at risk) through the tool's guard with each alias
#   shape, then a real separate-directory build (~2 s).
# EXPECTS: every alias refused with the sources untouched, the legitimate build working.
#   Section 7 (14z-197, GitHub #245): a generated vsavjw.zip kept in romdir, and a symlink
#   already at the output path, are never written through — the output is a fresh regular
#   file and both link targets are byte-identical afterwards.
#   Section 8 (14z-197, GitHub #250): a RELATIVE romdir and outdir, run from another cwd, build an overlay
#   whose every link resolves to its source member.
#
# MUST-FIRE: shadow-tool: old-write — a copy of the tool that mirrors romdir's vsavjw.zip and opens the output path in place (the pre-#245 write) must clobber a link target and FAIL section 7 (mode: the copy is the tool under test)
# MUST-FIRE: shadow-tool: relative-link — a copy of the tool that links to romdir as given and never checks the link (the pre-#250 overlay) must leave dangling links under a relative romdir and FAIL section 8 (mode: the copy is the tool under test)
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
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #76) `build_wide_romset` cannot take the reference set as
#   its own output. The one failure in that file with **no undo** (rule 7
#   forbids in-tree romset copies).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
FAKE="$T/romdir"
mkdir -p "$FAKE"

# old_write <copy> — the pre-#245 tool: romdir's vsavjw.zip mirrored like any
# zip, and the output opened IN PLACE (O_TRUNC follows a link at that path).
# Each substitution must apply exactly once, or the control tests nothing.
old_write() {
    python3 - "$REPO/tools/build_wide_romset.py" "$1" <<'PY2'
import sys
s = open(sys.argv[1]).read()
for old, new in (
        ("        if z == GENERATED:\n", "        if False:\n"),
        ('    fd, tmp = tempfile.mkstemp(dir=a.outdir, prefix=".vsavjw.", suffix=".tmp")\n',
         "    fd, tmp = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC), out_path\n")):
    if s.count(old) != 1:
        sys.exit(f"old_write: {old.strip()!r} found {s.count(old)} times, not once")
    s = s.replace(old, new)
open(sys.argv[2], "w").write(s)
PY2
}
# relative_link <copy> — the pre-#250 tool: the link target is romdir as given, and nothing checks it resolves
relative_link() {
    python3 - "$REPO/tools/build_wide_romset.py" "$1" <<'PY2'
import sys
s = open(sys.argv[1]).read()
for old, new in (
        ("os.symlink(os.path.join(os.path.abspath(a.romdir), z), dst)", "os.symlink(os.path.join(a.romdir, z), dst)"),
        ("            if not os.path.exists(dst):\n", "            if False:\n")):
    if s.count(old) != 1:
        sys.exit(f"relative_link: {old.strip()!r} found {s.count(old)} times, not once")
    s = s.replace(old, new)
open(sys.argv[2], "w").write(s)
PY2
}
TOOL="$REPO/tools/build_wide_romset.py"
if vs_ctl_is relative-link; then
    relative_link "$T/relative_link.py" || { echo "REFUSED: CONTROL=relative-link could not build its copy"; exit 3; }
    TOOL="$T/relative_link.py"
fi
if vs_ctl_is old-write; then
    old_write "$T/old_write.py" || { echo "REFUSED: CONTROL=old-write could not build its copy"; exit 3; }
    TOOL="$T/old_write.py"
fi

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
run() { python3 "$TOOL" "$FAKE" "$1" > "$T/out" 2>&1; }

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
if python3 "$TOOL" "$NEST" "$T/outer" > "$T/out" 2>&1; then
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

echo "== 7. NO WRITE THROUGH A LINK AT THE OUTPUT PATH (GitHub #245) =="
# section7 <tool> <dir> — prints one line per breach, exit 1 if any.
# (a) a generated vsavjw.zip kept in romdir (a player keeping sets together);
# (b) a symlink already at the output path, to a file outside both trees, with
#     a romdir holding no vsavjw.zip (so (a)'s mechanism cannot reach it).
# Both targets are sentinels; each must be byte-identical afterwards, the new
# output a REGULAR zip carrying the fake vsavj member, and no staging file left.
section7() {
    D="$2"; mkdir -p "$D/romdir" "$D/romdir_b" "$D/out_b" "$D/elsewhere"
    cp "$FAKE"/vsavj.zip "$FAKE"/vsav.zip "$D/romdir/"
    cp "$FAKE"/vsavj.zip "$FAKE"/vsav.zip "$D/romdir_b/"
    python3 - "$D/romdir/vsavjw.zip" "$D/elsewhere/keep.zip" <<'PY2'
import sys, zipfile
for p in sys.argv[1:]:
    with zipfile.ZipFile(p, "w") as z:
        z.writestr("precious.bin", b"previous compiled game")
PY2
    ln -s "$D/elsewhere/keep.zip" "$D/out_b/vsavjw.zip"
    A0="$(shasum -a 1 < "$D/romdir/vsavjw.zip")"; B0="$(shasum -a 1 < "$D/elsewhere/keep.zip")"
    bad=0
    python3 "$1" "$D/romdir" "$D/out_a" --qsound 0 > "$D/a.log" 2>&1 || { echo "    (a) the build failed: $(tail -1 "$D/a.log")"; bad=1; }
    python3 "$1" "$D/romdir_b" "$D/out_b" --qsound 0 > "$D/b.log" 2>&1 || { echo "    (b) the build failed: $(tail -1 "$D/b.log")"; bad=1; }
    [ "$(shasum -a 1 < "$D/romdir/vsavjw.zip")" = "$A0" ] || { echo "    (a) romdir's vsavjw.zip WAS OVERWRITTEN"; bad=1; }
    [ "$(shasum -a 1 < "$D/elsewhere/keep.zip")" = "$B0" ] || { echo "    (b) the output link's target WAS OVERWRITTEN"; bad=1; }
    for o in out_a out_b; do
        f="$D/$o/vsavjw.zip"
        if [ -L "$f" ] || [ ! -f "$f" ]; then echo "    $o: vsavjw.zip is not a regular file"; bad=1; continue; fi
        python3 -c 'import sys,zipfile; n=zipfile.ZipFile(sys.argv[1]).namelist(); sys.exit(0 if "vm3.03" in n and "precious.bin" not in n else 1)' "$f" \
            || { echo "    $o: vsavjw.zip does not hold the built members"; bad=1; }
        [ -z "$(ls -A "$D/$o" | grep '\.tmp$' || true)" ] || { echo "    $o: a staging file was left behind"; bad=1; }
    done
    grep -q 'skipped .*vsavjw.zip: a generated set' "$D/a.log" || { echo "    (a) romdir's vsavjw.zip was not reported skipped"; bad=1; }
    return $bad
}
if section7 "$TOOL" "$T/s7" > "$T/s7.txt" 2>&1; then
    echo "  ok: (a) romdir's generated vsavjw.zip and (b) an outside link target both unchanged; outputs are regular zips"
else
    fail "a link at the output path was written through:"; sed 's/^/    /' "$T/s7.txt"
fi

echo "== 8. A RELATIVE ROMDIR STILL GIVES LINKS THAT RESOLVE (GitHub #250) =="
# section9 <tool> <dir> — from <dir>/cwd, romdir `dumps` and outdir `build/rompath`, both relative;
# one line per breach, exit 1 if any.
section9() {
    D="$2"; mkdir -p "$D/cwd/dumps"; cp "$FAKE"/vsavj.zip "$FAKE"/vsav.zip "$D/cwd/dumps/"
    bad=0
    ( cd "$D/cwd" && python3 "$1" dumps build/rompath --qsound 0 ) > "$D/r.log" 2>&1 || { echo "    the build failed: $(tail -1 "$D/r.log")"; bad=1; }
    for z in vsavj.zip vsav.zip; do
        l="$D/cwd/build/rompath/$z"
        if [ ! -L "$l" ]; then echo "    $z: no overlay link"; bad=1
        elif [ ! -e "$l" ]; then echo "    $z: the link DANGLES (-> $(readlink "$l"))"; bad=1
        elif ! cmp -s "$l" "$D/cwd/dumps/$z"; then echo "    $z: the link resolves to another file"; bad=1; fi
    done
    return $bad
}
if section9 "$TOOL" "$T/s9" > "$T/s9.txt" 2>&1; then
    echo "  ok: relative romdir and outdir from another cwd: every overlay link resolves to its source member"
else
    fail "a relative romdir gave an unusable overlay:"; sed 's/^/    /' "$T/s9.txt"
fi

if vs_ctl_is relative-link; then
    echo; echo "FAIL: control mode relative-link (see above)"; exit 1
fi
if ! vs_ctl_is old-write; then
    echo "== 9. controls =="
    if ! old_write "$T/ctl.py" > "$T/ctl_build.txt" 2>&1; then
        vs_ctl_dead old-write "the copy could not be built: $(tail -1 "$T/ctl_build.txt")" || rc=1
    elif section7 "$T/ctl.py" "$T/s8" > "$T/s8.txt" 2>&1; then
        vs_ctl_dead old-write "the pre-#245 write passed section 7" || rc=1
    elif grep -q "(a) romdir's vsavjw.zip WAS OVERWRITTEN" "$T/s8.txt" \
            && grep -q "(b) the output link's target WAS OVERWRITTEN" "$T/s8.txt"; then
        vs_ctl_fired old-write "both link targets overwritten by the pre-#245 write ((a) romdir's vsavjw.zip, (b) the outside target)"
    else
        vs_ctl_dead old-write "section 7 failed for another reason: $(head -1 "$T/s8.txt")" || rc=1
    fi
    if ! relative_link "$T/ctl_rel.py" > "$T/ctl_rel_build.txt" 2>&1; then
        vs_ctl_dead relative-link "the copy could not be built: $(tail -1 "$T/ctl_rel_build.txt")" || rc=1
    elif section9 "$T/ctl_rel.py" "$T/s10" > "$T/s10.txt" 2>&1; then
        vs_ctl_dead relative-link "the pre-#250 overlay passed section 8" || rc=1
    elif grep -q 'the link DANGLES' "$T/s10.txt"; then
        vs_ctl_fired relative-link "$(grep -m1 'DANGLES' "$T/s10.txt" | sed 's/^ *//')"
    else
        vs_ctl_dead relative-link "section 8 failed for another reason: $(head -1 "$T/s10.txt")" || rc=1
    fi
fi

echo
[ "$rc" = 0 ] && echo "PASS: the reference set cannot be the build's output." \
             || echo "FAIL: see above."
exit $rc
