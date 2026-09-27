#!/bin/sh
# test_run_on_snapshot.sh — S6 OF GitHub #153 (and #181's inputs): a run on a snapshot is IMMUNE to
# the working tree (ruled 2026-09-26, DECISIONS_HISTORY.md "Ruled 2026-09-26 (14z-183b) — #153";
# the emulator tier's inputs ruled 2026-09-27, "Ruled 2026-09-27 (14z-184) — #181").
#
# WHAT: tests/run_on_snapshot.sh runs its command on a snapshot that nothing done to the
#   working tree during the run can reach — a tracked file edited and committed, a build/
#   output rewritten, a tracked build/ file, a submodule file, the ../community sibling, the
#   bbh checkout, a file of the ~/.cache/vampire-saved instrument cache, a Verilator scratch
#   clone, and the runner's own file — and its record names the commit the run was taken at;
#   a tracked file carries its last commit's time, a build/emu_* the run writes comes back to
#   the working tree, and an instrument binary changed in the LIVE cache during a run is reported.
# HOW: builds a throwaway world (a repo with a submodule, a build/ output, a community sibling,
#   a bbh checkout, a HOME holding an instrument cache, a scratch clone), starts a probe under
#   run_on_snapshot.sh --emulator-inputs that reads all nine inputs, pauses it, perturbs them in
#   the working tree, releases it and has it read them again; then runs the SAME probe IN PLACE
#   with the same perturbation (the positive leg: the perturbation must reach an unsnapshotted
#   run, or the immunity leg proves nothing); section 4 changes an instrument binary mid-run.
# EXPECTS: the snapshot run reads every input unchanged, records the commit taken before the
#   perturbation, sees t.txt at its commit's time, reaches the real HOME's other entries, and
#   returns its build/emu_probe to the tree; the in-place run sees nine readings change; a
#   mid-run instrument change reads unchanged inside the run and turns the run's exit to 2
#   with its AFTER line; each control makes the gate FAIL.
#
# MUST-FIRE: perturbed-copy: link-build — a copy of run_on_snapshot.sh that SYMLINKS each entry of build/ instead of snapshotting it must let the build/ perturbation reach the run, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: in-place — a copy that runs the command in the working tree instead of the clone must let every perturbation reach the run, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: no-self-copy — a copy that runs from its own file instead of a private copy must be cut short when that file is truncated mid-run (the record never gets its end), and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: shared-bbh — a copy that points BBH_HOME at the working checkout instead of its snapshot must let the bbh perturbation reach the run, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: shared-home — a copy that runs the command under the caller's HOME instead of the private one must let the instrument-cache perturbation reach the run, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: shared-scratch — a copy that leaves JTSIM_SCRATCH on the caller's scratch clone must let the scratch perturbation reach the run, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: checkout-mtime — a copy that skips S1b leaves t.txt at its checkout time instead of its commit's, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: no-copy-back — a copy that never copies the run's build/emu_* back leaves the working tree without the run of record, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: no-instrument-check — a copy that never compares the live instruments at the end exits 0 after an instrument changed mid-run, and the gate must FAIL (mode: the gate runs against that copy)
#
# The world lives in a scratch dir; the snapshots go under ~/.cache/vampire-saved (the runner
# refuses a temporary directory, the macOS reaper's hunting ground) and are removed on exit.
#
# Usage: tests/test_run_on_snapshot.sh      # ci_portable, ~40 s, no ROM, no emulator
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"
SROOT="$HOME/.cache/vampire-saved/test-snapshots-$$"
cleanup() { rm -rf "${W:?}" "${SROOT:?}"; }
trap cleanup EXIT INT TERM
fail=0

# make_copy <control> — run_on_snapshot.sh with ONE perturbation
make_copy() {
    mkdir -p "$W/ctl_$1/tests"; cp tests/run_on_snapshot.sh "$W/ctl_$1/tests/run_on_snapshot.sh"
    python3 - "$W/ctl_$1/tests/run_on_snapshot.sh" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "link-build": ('    cow "$REPO/build/." "$C/build/"\n',
                   '    for e in "$REPO"/build/*; do ln -sfn "$e" "$C/build/"; done  # CONTROL link-build\n'),
    "in-place":   [('{ ( cd "$C" && "$@" ) 2>&1;', '{ ( cd "$REPO" && "$@" ) 2>&1;  # CONTROL in-place\n'),
                   ('{ ( cd "$C" && HOME="$SNAP_HOME" JTSIM_SCRATCH="$JT_SNAP" "$@" ) 2>&1;',
                    '{ ( cd "$REPO" && "$@" ) 2>&1;  # CONTROL in-place\n')],
    "shared-bbh": ('    BBH_HOME="$SNAP/blackbox-harness"; export BBH_HOME\n',
                   '    BBH_HOME="$BBH_SRC"; export BBH_HOME  # CONTROL shared-bbh\n'),
    "no-self-copy": ('if [ -z "${RUN_ON_SNAPSHOT_SELF:-}" ]; then\n',
                     'if false; then  # CONTROL no-self-copy\n'),
    "shared-home": ('{ ( cd "$C" && HOME="$SNAP_HOME" JTSIM_SCRATCH="$JT_SNAP" "$@" ) 2>&1;',
                    '{ ( cd "$C" && JTSIM_SCRATCH="$JT_SNAP" "$@" ) 2>&1;  # CONTROL shared-home\n'),
    "shared-scratch": ('{ ( cd "$C" && HOME="$SNAP_HOME" JTSIM_SCRATCH="$JT_SNAP" "$@" ) 2>&1;',
                       '{ ( cd "$C" && HOME="$SNAP_HOME" "$@" ) 2>&1;  # CONTROL shared-scratch\n'),
    "checkout-mtime": ('os.utime(p, (t, t), follow_symlinks=False); done += 1',
                       'done += 1  # CONTROL checkout-mtime'),
    "no-copy-back": ('for d in $(comm -13 "$REC/.emu_before" "$REC/.emu_after"); do',
                     'for d in ; do  # CONTROL no-copy-back'),
    "no-instrument-check": ('if cmp -s "$REC/instruments_start.tsv" "$REC/instruments_end.tsv"; then',
                            ': CONTROL no-instrument-check; if true; then'),
}
pairs = edits[name]
if isinstance(pairs, tuple): pairs = [pairs]
for a, b in pairs:
    assert s.count(a) == 1, name
    s = s.replace(a, b, 1)
open(p, "w").write(s)
PY
    echo "$W/ctl_$1/tests/run_on_snapshot.sh"
}

# world <dir> — a fresh repo with a submodule, a build/ output, and the two siblings
world() {
    D="$1"; [ -n "$D" ] || { echo "FAIL: world() needs a dir"; exit 1; }; rm -rf "$D"; mkdir -p "$D"
    mkdir -p "$D/sub" && git -C "$D/sub" init -q && echo sub-v1 > "$D/sub/s.txt"
    git -C "$D/sub" add s.txt && git -C "$D/sub" -c user.email=t@t -c user.name=t commit -qm sub
    mkdir -p "$D/bbh" && git -C "$D/bbh" init -q && echo bbh-v1 > "$D/bbh/b.txt"
    git -C "$D/bbh" add b.txt && git -C "$D/bbh" -c user.email=t@t -c user.name=t commit -qm bbh
    mkdir -p "$D/community" && echo comm-v1 > "$D/community/c.txt"
    mkdir -p "$D/home/.cache/vampire-saved/inp" "$D/home/.cache/vampire-saved/mame" "$D/home/Library"
    echo cache-v1 > "$D/home/.cache/vampire-saved/inp/rec.txt"; echo inst-v1 > "$D/home/.cache/vampire-saved/fbneo_ref"
    echo mame-v1 > "$D/home/.cache/vampire-saved/mame/cps2"; echo lib-v1 > "$D/home/Library/l.txt"
    mkdir -p "$D/jtsim" "$D/jtsim-slot1"; echo jt-v1 > "$D/jtsim/j.txt"; echo jt1-v1 > "$D/jtsim-slot1/j.txt"
    mkdir -p "$D/tree/build" && git -C "$D/tree" init -q
    echo tracked-v1 > "$D/tree/t.txt"; echo man-v1 > "$D/tree/build/manifest.txt"
    printf 'build/out.bin\n' > "$D/tree/.gitignore"; echo build-v1 > "$D/tree/build/out.bin"
    cat > "$D/tree/probe.sh" <<'EOF'
#!/bin/sh
# read the six inputs, pause until released, read them again
rd() { printf 'tracked=%s build=%s manifest=%s sub=%s community=%s bbh=%s head=%s cache=%s jtsim=%s inst=%s\n' \
    "$(cat t.txt)" "$(cat build/out.bin)" "$(cat build/manifest.txt)" "$(cat mod/s.txt)" \
    "$(cat ../community/c.txt)" "$(cat "$BBH_HOME/b.txt")" "$(git rev-parse --short HEAD)" \
    "$(cat "$HOME/.cache/vampire-saved/inp/rec.txt")" "$(cat "$JTSIM_SCRATCH/j.txt")" \
    "$(cat "$HOME/.cache/vampire-saved/fbneo_ref")"; }
rd > "$PROBE_OUT.t0"
python3 -c 'import os,sys; print(int(os.stat(sys.argv[1]).st_mtime))' t.txt > "$PROBE_OUT.mtime"
cat "$HOME/Library/l.txt" > "$PROBE_OUT.lib" 2>&1 || true
: > "$PROBE_FLAGS/ready"
i=0; while [ ! -f "$PROBE_FLAGS/go" ] && [ $i -lt 600 ]; do sleep 0.1; i=$((i+1)); done
rd > "$PROBE_OUT.t1"
mkdir -p build/emu_probe; git rev-parse HEAD > build/emu_probe/commit.txt
EOF
    git -C "$D/tree" add t.txt build/manifest.txt .gitignore probe.sh
    git -C "$D/tree" -c user.email=t@t -c user.name=t -c protocol.file.allow=always submodule add -q "$D/sub" mod >/dev/null 2>&1
    # the world commit carries a FIXED date, so a tracked file's commit time differs from both its
    # write time and any checkout time (S1b)
    GIT_AUTHOR_DATE=2021-01-01T00:00:00Z GIT_COMMITTER_DATE=2021-01-01T00:00:00Z \
        git -C "$D/tree" -c user.email=t@t -c user.name=t commit -qm world
    touch -t 202001010000 "$D/tree/t.txt"
}

# perturb <dir> — change every input in the working tree, the commit included; with INST=1 the
# instrument binary too (section 4)
perturb() {
    D="$1"
    echo tracked-v2 > "$D/tree/t.txt"; git -C "$D/tree" -c user.email=t@t -c user.name=t commit -qam perturb
    echo build-v2 > "$D/tree/build/out.bin"; echo man-v2 > "$D/tree/build/manifest.txt"
    echo sub-v2 > "$D/tree/mod/s.txt"; echo comm-v2 > "$D/community/c.txt"; echo bbh-v2 > "$D/bbh/b.txt"
    echo cache-v2 > "$D/home/.cache/vampire-saved/inp/rec.txt"; echo jt-v2 > "$D/jtsim/j.txt"
    if [ "${INST:-0}" = 1 ]; then echo inst-v2 > "$D/home/.cache/vampire-saved/fbneo_ref"; fi
}

# leg <label> <runner|-> [expected exit] — run the probe (under the runner, or in place with "-"),
# perturb mid-run
leg() {
    L="$1"; R="$2"; X="${3:-0}"; D="$W/$L"; world "$D"
    FL="$W/$L.flags"; mkdir -p "$FL"; rm -f "$FL/ready" "$FL/go"
    before="$(git -C "$D/tree" rev-parse HEAD)"; echo "$before" > "$W/$L.before"
    if [ "$R" = - ]; then
        ( cd "$D/tree" && HOME="$D/home" JTSIM_SCRATCH="$D/jtsim" BBH_HOME="$D/bbh" PROBE_OUT="$W/$L" PROBE_FLAGS="$FL" sh probe.sh ) > "$W/$L.log" 2>&1 &
    else
        cp "$R" "$W/$L.runner.sh"; R="$W/$L.runner.sh"   # the leg's own copy: truncated mid-run below
        ( HOME="$D/home" JTSIM_SCRATCH="$D/jtsim" BBH_HOME="$D/bbh" PROBE_OUT="$W/$L" PROBE_FLAGS="$FL" \
          SNAPSHOT_ROOT="$SROOT" sh "$R" --repo "$D/tree" --no-romdir --emulator-inputs -- sh probe.sh ) > "$W/$L.log" 2>&1 &
    fi
    pid=$!
    i=0; while [ ! -f "$FL/ready" ] && [ $i -lt 600 ]; do sleep 0.1; i=$((i+1)); done
    [ -f "$FL/ready" ] || { echo "  FAIL: $L: the probe never reached its pause"; tail -5 "$W/$L.log" | sed 's/^/    /'; kill $pid 2>/dev/null || true; return 1; }
    perturb "$D"; [ "$R" = - ] || : > "$R"; : > "$FL/go"
    got=0; wait $pid || got=$?
    [ "$got" = "$X" ] || { echo "  FAIL: $L: the run exited $got, expected $X"; tail -5 "$W/$L.log" | sed 's/^/    /'; return 1; }
}

# fields that differ between t0 and t1
changed() { python3 - "$1.t0" "$1.t1" <<'PY'
import sys
a = dict(kv.split("=", 1) for kv in open(sys.argv[1]).read().split())
b = dict(kv.split("=", 1) for kv in open(sys.argv[2]).read().split())
print(" ".join(k for k in a if a[k] != b.get(k)))
PY
}

# immune <runner> <label> — the snapshot leg's verdict: 0 = nothing reached the run
immune() {
    leg "$2" "$1" || return 1
    chg="$(changed "$W/$2")"
    if [ -n "$chg" ]; then echo "  $2: the perturbation REACHED the run: $chg"; return 1; fi
    rec="$(ls -d "$W/$2/tree/build/snapshot_runs/"*/ 2>/dev/null | head -1)"
    [ -n "$rec" ] || { echo "  $2: no record written"; return 1; }
    rc="$(awk '/^commit /{print $2}' "$rec/record.txt")"
    [ "$rc" = "$(cat "$W/$2.before")" ] || { echo "  $2: the record's commit $rc is not the commit taken at start"; return 1; }
    grep -q 'repo/build/out.bin' "$rec/listing.tsv" || { echo "  $2: the listing lacks build/out.bin"; return 1; }
    grep -q '^runner_exit 0' "$rec/record.txt" && grep -q '^record ' "$rec/record.txt" || { echo "  $2: the perturbation REACHED the run: the runner file, truncated mid-run, cut the record short"; return 1; }
    [ "$(cat "$W/$2.mtime")" = 1609459200 ] || { echo "  $2: MTIME: t.txt read $(cat "$W/$2.mtime") inside the run, not its commit's time 1609459200 (S1b)"; return 1; }
    [ "$(cat "$W/$2.lib")" = lib-v1 ] || { echo "  $2: the private HOME lost the real HOME's other entries (Library/l.txt read: $(cat "$W/$2.lib"))"; return 1; }
    [ "$(cat "$W/$2/tree/build/emu_probe/commit.txt" 2>/dev/null)" = "$rc" ] || { echo "  $2: the run's build/emu_probe was NOT COPIED BACK to the working tree with the start commit"; return 1; }
    echo "  $2: all nine inputs unchanged across the perturbation and the runner's own file truncated mid-run; record complete, commit $(printf %.12s "$rc") = the start commit; t.txt at its commit's time; build/emu_probe copied back"
}

RUNNER="$REPO/tests/run_on_snapshot.sh"
CONTROLS="link-build in-place shared-bbh no-self-copy shared-home shared-scratch checkout-mtime no-copy-back no-instrument-check"
for c in $CONTROLS; do if vs_ctl_is "$c"; then RUNNER="$(make_copy "$VS_CTL")"; fi; done

echo "== 1. the positive leg: the perturbation reaches an IN-PLACE run"
if leg inplace -; then
    c="$(changed "$W/inplace")"
    n=$(echo "$c" | wc -w | tr -d ' ')
    if [ "$n" = 9 ]; then echo "  ok: all nine readings changed in place ($c)"
    else echo "  FAIL: in place, only [$c] changed — the perturbation does not reach a run, so section 2 would prove nothing"; fail=1; fi
else fail=1; fi

echo "== 2. the snapshot leg: nothing reaches a run on a snapshot"
if ! immune "$RUNNER" snap; then fail=1; fi

# instrument <runner> <label> — section 4: an instrument binary changed in the LIVE cache mid-run
# reads unchanged inside the run, and the runner reports it and exits 2
instrument() {
    rec_of() { ls -d "$W/$2/tree/build/snapshot_runs/"*/ 2>/dev/null | head -1; }
    if ! INST=1 leg "$2" "$1" 2; then
        # a run that COMPLETED (its record whole) with exit 0 missed the change; any other failure is
        # the copy dying, never evidence (the 14z-183b trap: a control that "fires" by crashing)
        r="$(rec_of "$@")"
        if [ -n "$r" ] && grep -q '^runner_exit 0' "$r/record.txt" && grep -q '^record ' "$r/record.txt"; then
            echo "  $2: NOT DETECTED: the run completed (record whole, exit 0) after an instrument changed in the live cache"
        fi
        return 1
    fi
    chg="$(changed "$W/$2")"
    case " $chg " in *" inst "*) echo "  $2: the instrument change REACHED the run"; return 1 ;; esac
    rec="$(ls -d "$W/$2/tree/build/snapshot_runs/"*/ 2>/dev/null | head -1)"
    grep -q '^AFTER: an instrument binary in the LIVE cache changed' "$rec/record.txt" || { echo "  $2: the instrument change was NOT DETECTED at the end"; return 1; }
    echo "  $2: the run read the copy (inst unchanged), and the record reports the live change with exit 2"
}

echo "== 3. an instrument changed in the live cache mid-run is detected"
if ! instrument "$RUNNER" inst; then fail=1; fi

echo "== 4. controls"
if [ -z "${VS_CTL:-}" ]; then
    for ctl in $CONTROLS; do
        # the leg's world dir must not be the copy's dir (world() empties it first)
        case "$ctl" in
        checkout-mtime) mark='MTIME' ;; no-copy-back) mark='NOT COPIED BACK' ;;
        no-instrument-check) mark='NOT DETECTED' ;; *) mark='REACHED' ;;
        esac
        copy="$(make_copy "$ctl")"
        # a copy its own edit broke would "fire" by crashing (docs/project/gotchas.md, paid 14z-184)
        if ! sh -n "$copy" 2>"$W/leg_$ctl.parse"; then
            vs_ctl_dead "$ctl" "the perturbed copy does not parse: $(head -1 "$W/leg_$ctl.parse" | cut -c1-90)" || fail=1; continue
        fi
        if [ "$ctl" = no-instrument-check ]; then instrument "$copy" "leg_$ctl" > "$W/leg_$ctl.txt" 2>&1 && ok=1 || ok=0
        else immune "$copy" "leg_$ctl" > "$W/leg_$ctl.txt" 2>&1 && ok=1 || ok=0; fi
        if [ "$ok" = 1 ]; then
            vs_ctl_dead "$ctl" "the perturbed copy still passed — the gate cannot see this failure" || fail=1
        elif grep -q "$mark" "$W/leg_$ctl.txt"; then vs_ctl_fired "$ctl" "$(grep -m1 "$mark" "$W/leg_$ctl.txt" | sed 's/^ *//' | cut -c1-110)"
        else vs_ctl_dead "$ctl" "the copy failed for another reason: $(grep -m1 -E 'FAIL|record|REACHED' "$W/leg_$ctl.txt" | sed 's/^ *//' | cut -c1-100)" || fail=1; fi
    done
fi
[ -z "$(ls -A "$SROOT" 2>/dev/null)" ] || { echo "  FAIL: a snapshot was left under $SROOT"; fail=1; }

if [ "$fail" = 0 ]; then echo "PASS: a run on a snapshot reads its commit's files and its snapshotted inputs, and nothing the working tree does during the run reaches it"
else echo "FAIL: test_run_on_snapshot"; exit 1; fi
