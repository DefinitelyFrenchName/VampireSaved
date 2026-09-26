#!/bin/sh
# run_on_snapshot.sh — RUN A TIER ON A SNAPSHOT AT A NAMED COMMIT, immune to the working tree
# (GitHub #153, lever B of #148; ruled 2026-09-26, DECISIONS_HISTORY.md "Ruled 2026-09-26
# (14z-183b) — #153").
#
# WHAT: a test tier (the runner and its arguments after `--`) runs on a SNAPSHOT of a named commit
#   — a clone of the commit plus every out-of-git input copied at the start — so nothing done to
#   the working tree during the run reaches it, and the run leaves a record of what it tested.
# HOW: clones the commit, snapshots build/, the submodules and the siblings by copy-on-write,
#   verifies the clone whole and ROMDIR against docs/checksums.txt, writes the record (commit,
#   start porcelain, listing, fingerprints), runs the runner inside the clone, checks the clone
#   and ROMDIR again, removes the snapshot.
# EXPECTS: the runner's own exit status and log; 2 when a step before the runner is refused (a
#   submodule off its gitlink, the clone not whole, ROMDIR failing verification).
# MUST-FIRE: none — a RUNNER asserts no property of the artifact; its immunity is tested by tests/test_run_on_snapshot.sh
#
# The principle, the maintainer's words: "being immune from any change in the tree while
# tests, especially long tests, run. Also, know against which commit we ran the tests, just
# in case an issue resolution could benefit from it."
#
# WHAT IT DOES, in order (the census and controls behind each step: build/agent183b/plan_153.md,
# summarised in docs/project/snapshot_runs.md):
#   S1 a PLAIN local clone of this repository (its own object store — hardlinked, immutable object
#      files — never --shared, whose borrowed objects a gc in the working tree could remove) checked out at <commit>, verified whole:
#      the commit's tracked-file count, and a tracked porcelain that is empty except for the
#      submodules (whose applied patches are checked INSIDE the run, by
#      test_fbneo_tree_integrity);
#   S2 every out-of-git input SNAPSHOTTED by copy-on-write (`cp -Rc`, APFS clonefile; a plain
#      copy elsewhere) at the start, so nothing the working tree does afterwards reaches the
#      run: all of build/ (then the commit's own tracked build/ files restored over it), each
#      initialised submodule's checkout with its .git/modules dir (refused unless its HEAD is
#      the commit's gitlink), and the declared siblings — ../community beside the tree, and the
#      bbh checkout ($BBH_HOME, else ../../blackbox-harness) exported as BBH_HOME;
#      ROMDIR is read in place and checksum-verified (tools/audit_roms.py) at start AND end;
#   S3 the snapshot lives under $SNAPSHOT_ROOT (default ~/.cache/vampire-saved/snapshots),
#      outside $TMPDIR, whose macOS reaper hollowed this project's scratch clones twice;
#   S4 THE RECORD, build/snapshot_runs/<stamp>-<commit>/ in the working tree: record.txt (the
#      commit, the stamp, the runner and its arguments, its exit, the submodule and bbh commits,
#      the ROMDIR verdicts), tree_porcelain_start.txt (what was NOT tested: uncommitted changes),
#      listing.tsv (every snapshotted file outside git: path, size, mtime), fingerprints.tsv
#      (every build/*/rompath through the commit's tools/build_fingerprint.py), runner.log;
#   the snapshot is removed after the record is written unless --keep.
# Immunity is PROVED by tests/test_run_on_snapshot.sh (S6), which perturbs a working tree while
# a snapshot run is paused and requires the run to see nothing.
#
# Usage:
#   tests/run_on_snapshot.sh [--commit <rev>] [--keep] [--no-romdir] [--repo <dir>] -- <runner> [args...]
#   e.g. ROMDIR=... tests/run_on_snapshot.sh -- tests/run_all_static.sh --strict --cadence freeze
# The runner is resolved inside the snapshot (a path is relative to the clone's root).
# Exit: the runner's exit status; 2 = refused before the runner ran (the reason is printed).
set -eu
# THE RUNNER ITSELF IS SNAPSHOTTED TOO: sh reads a script AS IT RUNS, so an edit to this file in the
# working tree during a run would reach the run mid-way (paid 14z-183b: the first real run died at a
# syntax error after the tier, the header having been edited under it). Re-exec from a private copy.
if [ -z "${RUN_ON_SNAPSHOT_SELF:-}" ]; then
    RUN_ON_SNAPSHOT_HOME="$(cd "$(dirname "$0")/.." && pwd)"
    RUN_ON_SNAPSHOT_SELF="$(mktemp "${TMPDIR:-/tmp}/run_on_snapshot.XXXXXX")"
    cp "$0" "$RUN_ON_SNAPSHOT_SELF"
    export RUN_ON_SNAPSHOT_HOME RUN_ON_SNAPSHOT_SELF
    exec sh "$RUN_ON_SNAPSHOT_SELF" "$@"
fi
SELF_REPO="${RUN_ON_SNAPSHOT_HOME:-$(cd "$(dirname "$0")/.." && pwd)}"
trap 'rm -f "${RUN_ON_SNAPSHOT_SELF:-/nonexistent}"' EXIT INT TERM
REPO="$SELF_REPO"; COMMIT=HEAD; KEEP=0; NOROM=0
while [ $# -gt 0 ]; do
    case "$1" in
    --commit) shift; COMMIT="${1:?--commit needs a revision}" ;;
    --keep) KEEP=1 ;;
    --no-romdir) NOROM=1 ;;
    --repo) shift; REPO="$(cd "${1:?--repo needs a dir}" && pwd)" ;;
    --) shift; break ;;
    *) echo "run_on_snapshot: unknown option $1 (the runner goes after --)" >&2; exit 2 ;;
    esac
    shift
done
[ $# -gt 0 ] || { echo "run_on_snapshot: no runner given (… -- <runner> [args])" >&2; exit 2; }
refuse() { echo "run_on_snapshot: REFUSED — $*" >&2; exit 2; }

SHA="$(git -C "$REPO" rev-parse --verify "$COMMIT^{commit}" 2>/dev/null)" || refuse "no commit '$COMMIT' in $REPO"
SHORT="$(printf %.12s "$SHA")"
STAMP="$(date +%Y%m%dT%H%M%S)"
ROOT="${SNAPSHOT_ROOT:-$HOME/.cache/vampire-saved/snapshots}"
case "$ROOT" in "${TMPDIR:-/nonexistent}"*|/tmp/*|/private/tmp/*|/var/folders/*) refuse "SNAPSHOT_ROOT $ROOT is under a temporary directory the macOS reaper cleans" ;; esac
SNAP="$ROOT/$SHORT-$STAMP"
REC="$REPO/build/snapshot_runs/$STAMP-$SHORT"
[ ! -e "$SNAP" ] || refuse "$SNAP already exists"
if [ "$NOROM" = 0 ]; then [ -n "${ROMDIR:-}" ] && [ -d "$ROMDIR" ] || refuse "ROMDIR is not set to a directory (use --no-romdir only for a tree that reads no ROM)"; fi
mkdir -p "$SNAP" "$REC"
# explicit tests, never ${X:?}: after an EXIT trap a demand's abort exits 0 on macOS bash 3.2 (test_demand_after_trap)
cleanup() { rm -f "${RUN_ON_SNAPSHOT_SELF:-/nonexistent}"; if [ "$KEEP" = 0 ] && [ -n "$SNAP" ] && [ -d "$SNAP" ]; then rm -rf "$SNAP"; fi; }
trap cleanup EXIT INT TERM
say() { echo "$*"; echo "$*" >> "$REC/record.txt"; }
cow() { cp -Rc "$1" "$2" 2>/dev/null || cp -R "$1" "$2"; }   # copy-on-write where the filesystem has it

say "# run_on_snapshot $STAMP"
say "commit      $SHA"
say "repo        $REPO"
say "snapshot    $SNAP"
say "runner      $*"
git -C "$REPO" status --porcelain > "$REC/tree_porcelain_start.txt" 2>&1 || true
say "tree_porcelain_at_start  $(grep -vc '^??' "$REC/tree_porcelain_start.txt" || true) tracked, $(grep -c '^??' "$REC/tree_porcelain_start.txt" || true) untracked — uncommitted changes are NOT tested"

# ---- S1: the clone, at the commit, with its own object store
# a local clone hardlinks the object files: git never rewrites an object or pack in place, so a gc
# or repack in the working tree only unlinks ITS names and the clone keeps its own
git clone -q --no-checkout "$REPO" "$SNAP/repo"
git -C "$SNAP/repo" checkout -q --detach "$SHA"
C="$SNAP/repo"
[ -n "$SNAP" ] && [ -d "$C/.git" ] || refuse "the clone at $C was not created"

# ---- S2: the out-of-git inputs, snapshotted now
if [ -d "$REPO/build" ]; then
    mkdir -p "$C/build"
    cow "$REPO/build/." "$C/build/"
    [ ! -d "$C/build/snapshot_runs" ] || rm -rf "$C/build/snapshot_runs"
    # the commit's own tracked files under build/ win over the working tree's copies
    if git -C "$C" ls-files --error-unmatch build >/dev/null 2>&1; then git -C "$C" checkout -q "$SHA" -- build; fi
fi
SUBS="$(git -C "$C" config -f .gitmodules --get-regexp 'submodule\..*\.path' 2>/dev/null | awk '{print $2}' || true)"
for sm in $SUBS; do
    want="$(git -C "$C" rev-parse "$SHA:$sm" 2>/dev/null || true)"
    if [ ! -e "$REPO/$sm/.git" ]; then say "submodule   $sm  NOT initialised in the working tree — not snapshotted"; continue; fi
    have="$(git -C "$REPO/$sm" rev-parse HEAD)"
    [ "$have" = "$want" ] || refuse "submodule $sm is at $have in the working tree, the commit pins $want"
    gd="$(git -C "$REPO/$sm" rev-parse --absolute-git-dir)"
    mkdir -p "$C/.git/modules/$(dirname "$sm")"
    cow "$gd" "$C/.git/modules/$sm"
    [ -n "$sm" ] || continue
    rm -rf "$C/$sm"
    cow "$REPO/$sm" "$C/$sm"
    printf 'gitdir: %s\n' "$C/.git/modules/$sm" > "$C/$sm/.git"
    git -C "$C/$sm" config core.worktree "$C/$sm"
    got="$(git -C "$C/$sm" rev-parse HEAD)"
    [ "$got" = "$want" ] || refuse "the snapshotted submodule $sm is at $got, not $want"
    say "submodule   $sm  $want  ($(git -C "$C/$sm" status --porcelain | wc -l | tr -d ' ') changed paths — the tracked patches, checked in the run)"
done
if [ -d "$REPO/../community" ]; then cow "$REPO/../community" "$SNAP/community"; say "sibling     community  snapshotted"; else say "sibling     community  absent"; fi
BBH_SRC="${BBH_HOME:-$REPO/../../blackbox-harness}"
if [ -d "$BBH_SRC" ]; then
    cow "$BBH_SRC" "$SNAP/blackbox-harness"
    BBH_HOME="$SNAP/blackbox-harness"; export BBH_HOME
    say "sibling     bbh  $(git -C "$BBH_HOME" rev-parse HEAD 2>/dev/null || echo not-a-git-checkout)  ($(git -C "$BBH_HOME" status --porcelain 2>/dev/null | grep -vc '^??' || true) tracked changes)"
else
    unset BBH_HOME || true
    say "sibling     bbh  absent"
fi

# ---- S1 check: the clone is whole — the commit's file count, and no tracked change but the submodules
want_n="$(git -C "$C" ls-tree -r --name-only "$SHA" | wc -l | tr -d ' ')"
have_n="$(git -C "$C" ls-files | wc -l | tr -d ' ')"
[ "$want_n" = "$have_n" ] || refuse "the clone tracks $have_n files, the commit $want_n"
porc="$(git -C "$C" status --porcelain | grep -v '^??' | awk '{print $2}' || true)"
for p in $porc; do
    case " $(echo $SUBS) " in *" $p "*) ;; *) refuse "the clone differs from $SHORT at $p before the run" ;; esac
done
say "clone       whole: $have_n tracked files, no tracked change outside the submodules"

# ---- the ROMs, read in place, verified
romcheck() {
    if [ "$NOROM" = 1 ]; then say "romdir_$1  not used (--no-romdir)"; return 0; fi
    if [ -f "$C/tools/audit_roms.py" ]; then
        if python3 "$C/tools/audit_roms.py" "$ROMDIR" > "$REC/romdir_$1.txt" 2>&1; then say "romdir_$1  $ROMDIR verified ($(grep -m1 "^verified" "$REC/romdir_$1.txt" || tail -1 "$REC/romdir_$1.txt"))"
        else say "romdir_$1  $ROMDIR FAILED verification — $(tail -1 "$REC/romdir_$1.txt" | cut -c1-80)"; return 1; fi
    else say "romdir_$1  no tools/audit_roms.py at this commit — not verified"; fi
}
romcheck start || refuse "ROMDIR does not verify against docs/checksums.txt at start"

# ---- S4: the listing and the fingerprints, taken BEFORE the runner writes anything
python3 - "$SNAP" > "$REC/listing.tsv" <<'PY'
import os, sys
root = sys.argv[1]
for top in ("repo/build", "community", "blackbox-harness"):
    for d, dirs, files in os.walk(os.path.join(root, top)):
        dirs.sort()
        for f in sorted(files):
            p = os.path.join(d, f)
            try: st = os.lstat(p)
            except OSError: continue
            print(f"{os.path.relpath(p, root)}\t{st.st_size}\t{int(st.st_mtime)}")
PY
say "listing     $(wc -l < "$REC/listing.tsv" | tr -d ' ') files outside git (listing.tsv)"
: > "$REC/fingerprints.tsv"
if [ -f "$C/tools/build_fingerprint.py" ]; then
    for rp in "$C"/build/*/rompath; do
        [ -d "$rp" ] || continue
        d="${rp%/rompath}"; d="${d##*/}"
        set_arg=""; [ -f "$rp/vsavjw.zip" ] && set_arg="--set vsavjw"
        fp="$(cd "$C" && python3 tools/build_fingerprint.py $set_arg "build/$d/rompath${ROMDIR:+;$ROMDIR}" 2>&1 | tail -1)"
        printf 'build/%s\t%s\n' "$d" "$fp" >> "$REC/fingerprints.tsv"
    done
    say "fingerprints $(wc -l < "$REC/fingerprints.tsv" | tr -d ' ') build dirs with a rompath (fingerprints.tsv)"
else
    say "fingerprints no tools/build_fingerprint.py at this commit"
fi

# ---- the run (its exit status survives the tee through a file)
say "start       $(date '+%Y-%m-%d %H:%M:%S')"
set +e
{ ( cd "$C" && "$@" ) 2>&1; echo $? > "$REC/.runner_exit"; } | tee "$REC/runner.log"
set -e
st="$(cat "$REC/.runner_exit" 2>/dev/null || echo 2)"; rm -f "$REC/.runner_exit"
say "end         $(date '+%Y-%m-%d %H:%M:%S')"
say "runner_exit $st"

# ---- after: the clone still at the commit, the ROMs still verified
after="$(git -C "$C" rev-parse HEAD)"
[ "$after" = "$SHA" ] || { say "AFTER: the clone's HEAD moved to $after during the run"; st=2; }
not_sub() { for p in "$@"; do case " $(echo $SUBS) " in *" $p "*) ;; *) echo "$p" ;; esac; done; }
moved="$(not_sub $(git -C "$C" status --porcelain | grep -v '^??' | awk '{print $2}'))"
if [ -n "$moved" ]; then say "AFTER: tracked files changed inside the snapshot during the run: $(echo $moved)"; fi
romcheck end || st=2
if [ "$KEEP" = 1 ]; then say "snapshot    kept at $SNAP"; else say "snapshot    removed"; fi
say "record      $REC"
exit "$st"
