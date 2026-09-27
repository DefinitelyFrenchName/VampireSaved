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
#   tests/run_on_snapshot.sh [--commit <rev>] [--keep] [--no-romdir] [--repo <dir>]
#                            [--emulator-inputs|--no-emulator-inputs] -- <runner> [args...]
#   e.g. ROMDIR=... tests/run_on_snapshot.sh -- tests/run_all_static.sh --strict --cadence freeze
#        ROMDIR=... tests/run_on_snapshot.sh -- tests/run_all_emulator.sh --freeze --strict
# --emulator-inputs (implied when the runner is tests/run_all_emulator.sh) adds S5, the emulator
# tier's inputs outside the tree: the instrument cache under a private HOME and the Verilator
# scratch clones (GitHub #181, ruled 2026-09-27, DECISIONS_HISTORY.md "Ruled 2026-09-27 (14z-184)").
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
REPO="$SELF_REPO"; COMMIT=HEAD; KEEP=0; NOROM=0; EMU=auto
while [ $# -gt 0 ]; do
    case "$1" in
    --commit) shift; COMMIT="${1:?--commit needs a revision}" ;;
    --keep) KEEP=1 ;;
    --no-romdir) NOROM=1 ;;
    --emulator-inputs) EMU=1 ;;
    --no-emulator-inputs) EMU=0 ;;
    --repo) shift; REPO="$(cd "${1:?--repo needs a dir}" && pwd)" ;;
    --) shift; break ;;
    *) echo "run_on_snapshot: unknown option $1 (the runner goes after --)" >&2; exit 2 ;;
    esac
    shift
done
[ $# -gt 0 ] || { echo "run_on_snapshot: no runner given (… -- <runner> [args])" >&2; exit 2; }
if [ "$EMU" = auto ]; then
    EMU=0; EMU_WHY="not the emulator runner"
    case "$(basename "$1")" in run_all_emulator.sh) EMU=1; EMU_WHY="the runner is run_all_emulator.sh" ;; esac
else
    EMU_WHY="set by the caller"
fi
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
cow() { cp -Rc "$1" "$2" 2>/dev/null || cp -Rp "$1" "$2"; }   # copy-on-write where the filesystem has it (both keep mtimes)

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

# ---- S1b: every tracked file takes the time of the commit that last changed it (#181, ruled
# 2026-09-27 "Last-commit time"). A clone's checkout stamps every file "now", and a gate that compares
# a tracked file's mtime (test_wide_profile: the harness patch against the reference FBNeo binary)
# then reads the clone's checkout time — it refused in every census run. The commit time is
# deterministic per commit; submodule gitlinks are left alone (their checkouts are snapshotted).
mt="$(python3 - "$C" "$SHA" <<'PY'
import os, subprocess, sys
repo, sha = sys.argv[1], sys.argv[2]
tracked = set(subprocess.run(["git", "-C", repo, "ls-files", "-z"], capture_output=True, check=True).stdout.decode().split("\0")) - {""}
gitlinks = {l.split("\t", 1)[1] for l in subprocess.run(["git", "-C", repo, "ls-files", "-s"], capture_output=True, check=True, text=True).stdout.splitlines() if l.startswith("160000 ")}
left = tracked - gitlinks
out = subprocess.run(["git", "-C", repo, "-c", "core.quotePath=false", "log", "--format=@%ct", "--name-only",
                      "--no-renames", sha], capture_output=True, check=True, text=True).stdout
t = None; done = 0
for line in out.splitlines():
    if not line: continue
    if line[0] == "@" and line[1:].isdigit() and line not in left:
        t = int(line[1:]); continue
    if line in left:
        p = os.path.join(repo, line)
        if os.path.lexists(p):
            os.utime(p, (t, t), follow_symlinks=False); done += 1
        left.discard(line)
        if not left: break
print(f"{done} {len(left)}")
PY
)" || refuse "S1b: could not set the tracked files' commit times"
say "mtimes      ${mt% *} tracked files set to their last commit's time (${mt#* } tracked paths never named by a commit on this history)"

# ---- S2b: the git-IGNORED inputs inside the tree. A clone carries none of them; the release
# binaries under release/emulators/ are read by test_release_binaries and test_readme_recording
# (the #181 census). Copied file by file, so a tracked file beside them keeps the commit's content.
ign=0
for d in release/emulators; do
    git -C "$REPO" ls-files --others --ignored --exclude-standard -z -- "$d" 2>/dev/null | tr '\0' '\n' > "$REC/.ignored_$$" || true
    while IFS= read -r f; do
        [ -n "$f" ] && [ -f "$REPO/$f" ] || continue
        case "$f" in */.DS_Store|.DS_Store) continue ;; esac
        mkdir -p "$C/$(dirname "$f")"; cow "$REPO/$f" "$C/$f"; ign=$((ign + 1))
    done < "$REC/.ignored_$$"
    rm -f "$REC/.ignored_$$"
done
say "ignored     $ign git-ignored input files copied in (release/emulators)"

# ---- S5: the emulator tier's inputs outside the tree (--emulator-inputs; #181, ruled 2026-09-27
# "Copy the cache" and "Private copies"). The instrument binaries live under
# ~/.cache/vampire-saved and gates name them in at least three ways, several by a literal
# $HOME path, so the whole cache is copied (copy-on-write) and the runner gets a PRIVATE HOME:
# its .cache/vampire-saved is the copy, every other entry a symlink to the real HOME's (the
# Python user site and the rest resolve as before). The instrument binaries are hashed at the
# start and the end in the LIVE cache — a change there during the run means a gate that bypassed
# the copy cannot be ruled out, so the run is refused (exit 2). The Verilator scratch clones
# (JTSIM_SCRATCH, default $TMPDIR/vampire-saved-jtsim, its -slotN and -b siblings) are copied
# into the snapshot and the run pointed there, so it cannot collide with a simulation in the tree.
INSTRUMENTS="mame/cps2 mame-ref/cps2 fbneo_ref"
CACHE_SRC="$HOME/.cache/vampire-saved"
SNAP_HOME=""; JT_SNAP=""
hash_instruments() {  # hash_instruments <cache dir> > tsv
    for i in $INSTRUMENTS; do
        if [ -f "$1/$i" ]; then printf '%s\t%s\n' "$i" "$(shasum -a 256 "$1/$i" | cut -c1-64)"
        else printf '%s\tABSENT\n' "$i"; fi
    done
}
if [ "$EMU" = 1 ]; then
    SNAP_HOME="$SNAP/home"
    mkdir -p "$SNAP_HOME/.cache/vampire-saved"
    python3 - "$HOME" "$SNAP_HOME" <<'PY'
import os, sys
real, mine = sys.argv[1], sys.argv[2]
for e in sorted(os.listdir(real)):
    if e != ".cache": os.symlink(os.path.join(real, e), os.path.join(mine, e))
if os.path.isdir(os.path.join(real, ".cache")):
    for e in sorted(os.listdir(os.path.join(real, ".cache"))):
        if e != "vampire-saved": os.symlink(os.path.join(real, ".cache", e), os.path.join(mine, ".cache", e))
PY
    ncache=0
    if [ -d "$CACHE_SRC" ]; then
        for e in "$CACHE_SRC"/* "$CACHE_SRC"/.[!.]*; do
            [ -e "$e" ] || continue
            case "${e##*/}" in snapshots) continue ;; esac
            cow "$e" "$SNAP_HOME/.cache/vampire-saved/${e##*/}"; ncache=$((ncache + 1))
        done
    fi
    hash_instruments "$CACHE_SRC" > "$REC/instruments_start.tsv"
    hash_instruments "$SNAP_HOME/.cache/vampire-saved" > "$REC/instruments_copy.tsv"
    cmp -s "$REC/instruments_start.tsv" "$REC/instruments_copy.tsv" || refuse "S5: the copied instruments differ from the live cache's (instruments_start.tsv vs instruments_copy.tsv)"
    say "emu_inputs  yes ($EMU_WHY)"
    say "home        $SNAP_HOME — private: .cache/vampire-saved copied ($ncache entries, snapshots/ left out), every other entry a symlink to $HOME"
    say "instruments $(awk -F'\t' '{printf "%s %.12s  ", $1, $2}' "$REC/instruments_start.tsv")(instruments_start.tsv)"
    JT_SRC="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}"; JT_SRC="${JT_SRC%/}"
    JT_SNAP="$SNAP/jtsim"
    njt=0
    for d in "$JT_SRC" "$JT_SRC"-*; do
        [ -d "$d" ] || continue
        cow "$d" "$JT_SNAP${d#"$JT_SRC"}"; njt=$((njt + 1))
        printf '%s\t%s\n' "$d" "$JT_SNAP${d#"$JT_SRC"}" >> "$REC/jtsim_copies.tsv"
    done
    say "jtsim       $njt scratch clone(s) copied from $JT_SRC* to $JT_SNAP* (JTSIM_SCRATCH points there)"
else
    say "emu_inputs  no ($EMU_WHY)"
fi

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
tops = ["repo/build", "community", "blackbox-harness", "home/.cache/vampire-saved"]
tops += sorted(e for e in os.listdir(root) if e.startswith("jtsim"))
for top in tops:
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
( cd "$C" && ls -d build/emu_* 2>/dev/null || true ) > "$REC/.emu_before"
if [ "$EMU" = 1 ]; then
    { ( cd "$C" && HOME="$SNAP_HOME" JTSIM_SCRATCH="$JT_SNAP" "$@" ) 2>&1; echo $? > "$REC/.runner_exit"; } | tee "$REC/runner.log"
else
    { ( cd "$C" && "$@" ) 2>&1; echo $? > "$REC/.runner_exit"; } | tee "$REC/runner.log"
fi
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
# the run of record comes home (#181, ruled 2026-09-27 "Copied back"): every build/emu_* the run
# created in the clone is copied into the working tree's build/, where the staleness gate reads it
# (tools/audit_emulator_staleness.py globs build/emu_* under its own tree); a name already taken
# there is never overwritten
( cd "$C" && ls -d build/emu_* 2>/dev/null || true ) > "$REC/.emu_after"
for d in $(comm -13 "$REC/.emu_before" "$REC/.emu_after"); do
    if [ -e "$REPO/$d" ]; then say "run_record  $d NOT copied back — the working tree already has one"; st=2
    else cow "$C/$d" "$REPO/$d"; say "run_record  $d copied back to the working tree ($(head -1 "$REPO/$d/commit.txt" 2>/dev/null || echo 'no commit.txt'))"; fi
done
rm -f "$REC/.emu_before" "$REC/.emu_after"
if [ "$EMU" = 1 ]; then
    hash_instruments "$CACHE_SRC" > "$REC/instruments_end.tsv"
    if cmp -s "$REC/instruments_start.tsv" "$REC/instruments_end.tsv"; then say "instruments unchanged in the live cache during the run"
    else say "AFTER: an instrument binary in the LIVE cache changed during the run (instruments_start.tsv vs instruments_end.tsv) — a gate that bypassed the copy cannot be ruled out"; st=2; fi
    # a copied scratch clone must not still point at its original: Verilator's dependency files carry
    # absolute paths, and a run that regenerated them leaves none naming the original
    if [ -f "$REC/jtsim_copies.tsv" ]; then
        while IFS="$(printf '\t')" read -r src dst; do
            n="$(grep -rIl --exclude-dir=.git -F "$src/" "$dst" 2>/dev/null | wc -l | tr -d ' ')"
            say "jtsim_paths $dst: $n file(s) still name $src/"
        done < "$REC/jtsim_copies.tsv"
    fi
fi
if [ "$KEEP" = 1 ]; then say "snapshot    kept at $SNAP"; else say "snapshot    removed"; fi
say "record      $REC"
exit "$st"
