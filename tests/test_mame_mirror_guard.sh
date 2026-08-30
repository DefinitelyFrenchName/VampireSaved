#!/bin/sh
# test_mame_mirror_guard.sh — setup_mame.sh must never run `rsync --delete`
# into a directory it does not own (14z-94, GitHub #80). ROM-free, ~3 s.
#
# THE DEFECT. setup_mame.sh did:
#
#     MIRROR="$MAME_BUILD_ROOT"          # only validation: contains no space
#     mkdir -p "$MIRROR"
#     rsync -a --delete ... "$SRC/" "$MIRROR/"
#
# `--delete` removes everything in the target that is not in the MAME source.
# So `MAME_BUILD_ROOT=$HOME`, or a work directory reused while troubleshooting
# a build location, deletes unrelated files during an ordinary setup command.
# Nothing hostile is needed — an env var left exported in a shell is enough.
#
# THE FIX IS TWO INDEPENDENT CHECKS, because either alone leaves a hole:
# canonical-path rejection (root, $HOME, ancestors, the repo and source trees,
# resolved through `..` and symlinks) AND an ownership sentinel, because no
# path rule can know that ~/projects/scratch is precious. New and empty
# targets self-claim, so initialization stays one command; a pre-existing
# non-empty directory is refused with the opt-in spelled out.
#
# HOW THIS IS TESTED WITHOUT AN HOURS-LONG MAME BUILD. The guard block is
# EXTRACTED from tools/setup_mame.sh between its two markers and run in a
# harness — extracted, never copied, so it cannot drift from the shipped
# code. Section 0 fails loudly if the extraction comes back empty, which is
# the failure mode that would make every other section pass vacuously.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #80) `rsync --delete` runs only in a directory
#   `setup_mame.sh` owns. Guard is EXTRACTED from the shipped script between
#   markers, never copied.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
GUARD="$T/guard.sh"

echo "== 0. extract the guard from the shipped script =="
n_open=$(grep -c '^# >>> MIRROR GUARD' tools/setup_mame.sh || true)
n_close=$(grep -c '^# <<< MIRROR GUARD <<<' tools/setup_mame.sh || true)
if [ "$n_open" != 1 ] || [ "$n_close" != 1 ]; then
    echo "  FAIL: markers not found exactly once (open=$n_open close=$n_close)"
    echo "        — the guard cannot be extracted, so this gate would pass"
    echo "        vacuously. Restore the markers in tools/setup_mame.sh."
    exit 1
fi
sed -n '/^# >>> MIRROR GUARD/,/^# <<< MIRROR GUARD <<</p' tools/setup_mame.sh > "$GUARD"
lines=$(wc -l < "$GUARD" | tr -d ' ')
if [ "$lines" -lt 30 ]; then
    echo "  FAIL: extracted only $lines lines — that is not the guard"; exit 1
fi
if ! grep -q "rsync" tools/setup_mame.sh; then
    echo "  FAIL: setup_mame.sh no longer runs rsync — re-check this gate"; exit 1
fi
# The guard must sit BEFORE the destructive line, or it guards nothing.
g_line=$(grep -n '^# <<< MIRROR GUARD <<<' tools/setup_mame.sh | cut -d: -f1)
r_line=$(grep -n '^rsync -a --delete' tools/setup_mame.sh | head -1 | cut -d: -f1)
if [ -z "$r_line" ] || [ "$g_line" -ge "$r_line" ]; then
    fail "the guard does not precede the rsync --delete (guard ends $g_line," \
         "rsync at ${r_line:-none})"
else
    echo "  ok: $lines lines extracted; guard ends line $g_line, rsync line $r_line"
fi

# try <MIRROR> <HOME> — run the extracted guard with a synthetic environment.
try() {
    ( set +e
      MIRROR="$1" HOME="$2" REPO="$T/repo" SRC="$T/repo/emu/mame" \
        sh -c 'set -eu; MIRROR="$MIRROR"; REPO="$REPO"; SRC="$SRC"; HOME="$HOME"
               . '"$GUARD"'
               echo GUARD_PASSED' > "$T/out" 2>&1
      echo $? > "$T/st" )
    read_st=$(cat "$T/st"); return "$read_st"
}

mkdir -p "$T/repo/emu/mame" "$T/home"
HOMEDIR="$T/home"

must_reject() { # must_reject <label> <mirror> [home]
    h="${3:-$HOMEDIR}"
    if try "$2" "$h"; then
        fail "$1: ACCEPTED — rsync --delete would run there"
    elif grep -q "REFUSING to mirror" "$T/out"; then
        echo "  ok: $1 refused"
    else
        fail "$1: rejected, but not by the guard: $(head -1 "$T/out")"
    fi
}
must_accept() { # must_accept <label> <mirror>
    if try "$2" "$HOMEDIR"; then
        echo "  ok: $1 accepted"
    else
        fail "$1: REFUSED, but it is a legitimate target:"
        sed 's/^/        /' "$T/out" | head -4
    fi
}

echo "== 1. structurally dangerous roots =="
must_reject "/"                 "/"
must_reject "\$HOME itself"     "$HOMEDIR"
must_reject "the repository"    "$T/repo"
must_reject "the MAME source"   "$T/repo/emu/mame"

echo "== 2. ANCESTORS — a parent of the repo or of \$HOME =="
must_reject "a parent of both"  "$T"

echo "== 3. inside the repo / inside the source =="
must_reject "inside the repo"   "$T/repo/build/mirror"
must_reject "inside the source" "$T/repo/emu/mame/obj"

echo "== 4. ALIASES — '..' spellings and symlinks resolve to the same place =="
must_reject "\$HOME via '..'"   "$T/home/../home"
ln -s "$HOMEDIR" "$T/home_alias"
must_reject "symlink to \$HOME" "$T/home_alias"
ln -s "$T/repo" "$T/repo_alias"
must_reject "symlink to repo"   "$T/repo_alias"

echo "== 5. THE SENTINEL — a pre-existing NON-EMPTY directory is refused =="
# This is the case a path rule cannot catch, and the one that eats data.
PRECIOUS="$T/precious"
mkdir -p "$PRECIOUS"
echo "six months of work" > "$PRECIOUS/thesis.txt"
echo "irreplaceable"      > "$PRECIOUS/notes.md"
BEFORE="$(cd "$PRECIOUS" && shasum -a 1 ./*)"
must_reject "existing non-empty dir, no sentinel" "$PRECIOUS"
if grep -q "vampire-saved-mame-mirror" "$T/out"; then
    echo "  ok: and the refusal tells the operator how to opt in"
else
    fail "the refusal does not name the sentinel, so it is a dead end"
fi
if [ "$(cd "$PRECIOUS" && shasum -a 1 ./*)" = "$BEFORE" ]; then
    echo "  ok: both files still byte-identical"
else
    fail "THE UNRELATED FILES CHANGED"
fi

echo "== 6. CONTROLS — legitimate targets must still work =="
# Without these, 'reject everything' would pass sections 1-5.
must_accept "a brand-new path"        "$HOMEDIR/.cache/vampire-saved/mame"
mkdir -p "$T/empty"
must_accept "an existing EMPTY dir"   "$T/empty"
mkdir -p "$T/owned"; echo junk > "$T/owned/stale"
touch "$T/owned/.vampire-saved-mame-mirror"
must_accept "a sentinel-owned dir"    "$T/owned"
must_accept "the default under HOME"  "$HOMEDIR/.cache/vampire-saved/mame-ref"

echo "== 6b. MIGRATION — a pre-sentinel mirror must not break =="
# Both of this machine's real mirrors predate the sentinel. A guard that
# refuses a working setup is a guard that gets disabled, so an existing MAME
# TREE self-claims. The signature is all three of makefile + src/mame +
# src/emu, which a documents or scratch directory does not have.
OLD="$T/old_mirror"
mkdir -p "$OLD/src/mame" "$OLD/src/emu"; touch "$OLD/makefile"
must_accept "an unmarked existing MAME tree" "$OLD"
# ...and the signature must be SPECIFIC: two of the three is not enough,
# or 'looks vaguely like a source tree' becomes a licence to delete.
for miss in makefile src/mame src/emu; do
    PART="$T/part_$(echo "$miss" | tr / _)"
    mkdir -p "$PART/src/mame" "$PART/src/emu"; touch "$PART/makefile"
    echo "precious" > "$PART/keepme.txt"
    rm -rf "${PART:?}/$miss"
    must_reject "a tree MISSING $miss" "$PART"
done
if [ -f "$T/part_makefile/keepme.txt" ]; then
    echo "  ok: the near-miss directories were left intact"
else
    fail "a near-miss directory lost files"
fi

echo "== 7. the sentinel is WRITTEN before the destructive line =="
# An interrupted first run must leave an OWNED mirror, not an unowned
# half-populated one the guard would then refuse forever.
s_line=$(grep -n 'MIRROR_SENTINEL"$' tools/setup_mame.sh | head -1 | cut -d: -f1)
w_line=$(grep -n 'claimed build mirror' tools/setup_mame.sh | head -1 | cut -d: -f1)
if [ -n "$w_line" ] && [ "$w_line" -lt "$r_line" ]; then
    echo "  ok: the claim (line $w_line) precedes the rsync (line $r_line)"
else
    fail "the sentinel is written at or after the rsync — an interrupted"
    fail "      first run would leave a directory the guard refuses forever"
fi
if grep -q -- "--exclude \"/\$MIRROR_SENTINEL\"" tools/setup_mame.sh; then
    echo "  ok: and rsync --delete excludes it, so it survives every run"
else
    fail "rsync --delete does not exclude the sentinel — it would be removed"
    fail "      on the very run it authorises, un-claiming the mirror"
fi

echo
[ "$rc" = 0 ] && echo "PASS: --delete runs only in a directory this script owns." \
             || echo "FAIL: see above."
exit $rc
