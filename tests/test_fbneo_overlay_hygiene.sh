#!/bin/sh
# test_fbneo_overlay_hygiene.sh — a non-overlay FBNeo run must not inherit a
# previous run's overlay (14z-94, GitHub #38). ~2 s, no emulator, no ROMs.
#
# THE DEFECT. run_replay_fbneo.sh builds "$WORK/roms" two ways: with
# FBNEO_ROMPATH it makes a real DIRECTORY of symlinks (reference zips first,
# overlay zips winning); without it, it symlinks $ROMDIR directly. The second
# branch used a bare `ln -sfn`, which cannot replace a real directory — on
# BSD/macOS it creates "$WORK/roms/<basename>" INSIDE it. So a REUSED sandbox
# that had previously run with an overlay kept that overlay, and the
# non-overlay run went on serving the PREVIOUS run's patched zips while the
# caller believed it was measuring pristine $ROMDIR. Exactly backwards from
# what a non-overlay run exists to do, and silent.
#
# This gate drives the script with a STUB emulator, so it needs neither FBNeo
# nor real romsets: the roms/ wiring happens before the binary is invoked, and
# the wiring is the whole question. The script exits nonzero (the stub writes
# no END line) — that is expected and not what is asserted.
#
# THE SAFETY CONTROL IS NOT OPTIONAL. The fix adds an `rm -rf` next to a path
# that is a SYMLINK TO $ROMDIR on this very branch. A trailing slash there
# would follow the link and empty the reference sets. Section 3 runs the
# non-overlay branch twice against a populated fake ROMDIR and requires the
# contents to survive.
#
# GROUND TRUTH: RUNNER=<path> points this gate at another copy of the script.
# `tests/test_fbneo_overlay_hygiene_control.sh` reconstructs the PRE-FIX
# runner and requires section 2 to FAIL against it — because a hygiene gate
# that has never seen the defect is indistinguishable from one that cannot.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
RUNNER="${RUNNER:-tools/run_replay_fbneo.sh}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

# a fake reference set and a fake overlay, each with a distinguishable zip
mkdir -p "$T/romdir" "$T/overlay" "$T/bin"
: > "$T/romdir/vsavj.zip"
: > "$T/romdir/pristine_marker.zip"
: > "$T/overlay/vsavj.zip"
: > "$T/overlay/overlay_marker.zip"
printf '#!/bin/sh\nexit 0\n' > "$T/bin/fbneo"; chmod +x "$T/bin/fbneo"
: > "$T/replay.rpl"

run() { # run <sandbox> [overlay]
    if [ -n "${2:-}" ]; then ov="$2"; else ov=""; fi
    # THE SANDBOX IS THE FOURTH POSITIONAL, not an env var: the script does
    # `SANDBOX="${4:-}"`, which OVERWRITES any exported value with the empty
    # string, so an env-passed sandbox silently becomes a fresh mktemp -d and
    # every assertion here would look at a directory the run never touched.
    FBNEO_BIN="$T/bin/fbneo" ROMDIR="$T/romdir" FBNEO_ROMPATH="$ov" \
        sh "$RUNNER" vsavjw "$T/replay.rpl" "$1/out.log" "$1" \
        > "$1/run.log" 2>&1 || true
}

echo "== 1. an overlay run builds a real roms/ directory =="
SB="$T/sb"; mkdir -p "$SB"
run "$SB" "$T/overlay"
if [ -d "$SB/roms" ] && [ ! -L "$SB/roms" ] && [ -e "$SB/roms/overlay_marker.zip" ]; then
    echo "  ok: overlay branch made a real directory carrying the overlay zip"
else
    fail "the overlay branch did not produce the expected roms/ directory"
fi

echo "== 2. THE DEFECT — the SAME sandbox, now WITHOUT an overlay =="
run "$SB"
if [ -e "$SB/roms/overlay_marker.zip" ]; then
    fail "the non-overlay run still serves the previous overlay's zips"
    fail "      ($SB/roms/overlay_marker.zip is still resolvable)"
elif [ ! -L "$SB/roms" ]; then
    fail "roms/ is not a symlink after a non-overlay run — it is $(ls -ld "$SB/roms" | cut -c1-1)"
else
    echo "  ok: roms/ is a symlink to \$ROMDIR; the overlay is gone"
    if [ -e "$SB/roms/pristine_marker.zip" ]; then
        echo "  ok: and it resolves the pristine reference set"
    else
        fail "roms/ is a symlink but does not resolve \$ROMDIR's contents"
    fi
fi

echo "== 3. SAFETY CONTROL — the rm must never follow the link into \$ROMDIR =="
before=$(ls "$T/romdir" | sort | tr '\n' ' ')
run "$SB"          # non-overlay again: now roms/ IS a symlink to $ROMDIR
after=$(ls "$T/romdir" | sort | tr '\n' ' ')
if [ "$before" = "$after" ]; then
    echo "  ok: \$ROMDIR intact across a repeat non-overlay run ($after)"
else
    fail "\$ROMDIR was modified by the run: '$before' -> '$after'"
fi

echo "== 4. a fresh sandbox is unaffected either way =="
SB2="$T/sb2"; mkdir -p "$SB2"
run "$SB2"
if [ -L "$SB2/roms" ] && [ -e "$SB2/roms/pristine_marker.zip" ]; then
    echo "  ok: a first-time non-overlay run symlinks \$ROMDIR"
else
    fail "a fresh non-overlay sandbox did not get a \$ROMDIR symlink"
fi

echo
if [ "$rc" = 0 ]; then
    echo "PASS: a non-overlay run never inherits a previous overlay, and the"
    echo "      cleanup cannot reach \$ROMDIR."
else
    echo "FAIL: see above."
fi
exit $rc
