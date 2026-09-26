#!/bin/sh
# test_run_on_snapshot.sh — S6 OF GitHub #153: a run on a snapshot is IMMUNE to the working tree
# (ruled 2026-09-26, DECISIONS_HISTORY.md "Ruled 2026-09-26 (14z-183b) — #153").
#
# WHAT: tests/run_on_snapshot.sh runs its command on a snapshot that nothing done to the
#   working tree during the run can reach — a tracked file edited and committed, a build/
#   output rewritten, a tracked build/ file, a submodule file, the ../community sibling, the
#   bbh checkout, and the runner's own file — and its record names the commit the run was taken at.
# HOW: builds a throwaway world (a repo with a submodule, a build/ output, a community sibling,
#   a bbh checkout), starts a probe under run_on_snapshot.sh that reads all six inputs, pauses
#   it, perturbs all six in the working tree, releases it and has it read them again; then runs
#   the SAME probe IN PLACE with the same perturbation (the positive leg: the perturbation must
#   reach an unsnapshotted run, or the immunity leg proves nothing).
# EXPECTS: the snapshot run reads all six inputs unchanged and records the commit taken before
#   the perturbation; the in-place run sees all six change; each control makes the gate FAIL.
#
# MUST-FIRE: perturbed-copy: link-build — a copy of run_on_snapshot.sh that SYMLINKS each entry of build/ instead of snapshotting it must let the build/ perturbation reach the run, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: in-place — a copy that runs the command in the working tree instead of the clone must let every perturbation reach the run, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: no-self-copy — a copy that runs from its own file instead of a private copy must be cut short when that file is truncated mid-run (the record never gets its end), and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: shared-bbh — a copy that points BBH_HOME at the working checkout instead of its snapshot must let the bbh perturbation reach the run, and the gate must FAIL (mode: the gate runs against that copy)
#
# The world lives in a scratch dir; the snapshots go under ~/.cache/vampire-saved (the runner
# refuses a temporary directory, the macOS reaper's hunting ground) and are removed on exit.
#
# Usage: tests/test_run_on_snapshot.sh      # ci_portable, ~20 s, no ROM, no emulator
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
    "in-place":   ('{ ( cd "$C" && "$@" ) 2>&1;', '{ ( cd "$REPO" && "$@" ) 2>&1;  # CONTROL in-place\n'),
    "shared-bbh": ('    BBH_HOME="$SNAP/blackbox-harness"; export BBH_HOME\n',
                   '    BBH_HOME="$BBH_SRC"; export BBH_HOME  # CONTROL shared-bbh\n'),
    "no-self-copy": ('if [ -z "${RUN_ON_SNAPSHOT_SELF:-}" ]; then\n',
                     'if false; then  # CONTROL no-self-copy\n'),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
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
    mkdir -p "$D/tree/build" && git -C "$D/tree" init -q
    echo tracked-v1 > "$D/tree/t.txt"; echo man-v1 > "$D/tree/build/manifest.txt"
    printf 'build/out.bin\n' > "$D/tree/.gitignore"; echo build-v1 > "$D/tree/build/out.bin"
    cat > "$D/tree/probe.sh" <<'EOF'
#!/bin/sh
# read the six inputs, pause until released, read them again
rd() { printf 'tracked=%s build=%s manifest=%s sub=%s community=%s bbh=%s head=%s\n' \
    "$(cat t.txt)" "$(cat build/out.bin)" "$(cat build/manifest.txt)" "$(cat mod/s.txt)" \
    "$(cat ../community/c.txt)" "$(cat "$BBH_HOME/b.txt")" "$(git rev-parse --short HEAD)"; }
rd > "$PROBE_OUT.t0"; : > "$PROBE_FLAGS/ready"
i=0; while [ ! -f "$PROBE_FLAGS/go" ] && [ $i -lt 600 ]; do sleep 0.1; i=$((i+1)); done
rd > "$PROBE_OUT.t1"
EOF
    git -C "$D/tree" add t.txt build/manifest.txt .gitignore probe.sh
    git -C "$D/tree" -c user.email=t@t -c user.name=t -c protocol.file.allow=always submodule add -q "$D/sub" mod >/dev/null 2>&1
    git -C "$D/tree" -c user.email=t@t -c user.name=t commit -qm world
}

# perturb <dir> — change all six inputs in the working tree, the commit included
perturb() {
    D="$1"
    echo tracked-v2 > "$D/tree/t.txt"; git -C "$D/tree" -c user.email=t@t -c user.name=t commit -qam perturb
    echo build-v2 > "$D/tree/build/out.bin"; echo man-v2 > "$D/tree/build/manifest.txt"
    echo sub-v2 > "$D/tree/mod/s.txt"; echo comm-v2 > "$D/community/c.txt"; echo bbh-v2 > "$D/bbh/b.txt"
}

# leg <label> <runner|-> — run the probe (under the runner, or in place with "-"), perturb mid-run
leg() {
    L="$1"; R="$2"; D="$W/$L"; world "$D"
    FL="$W/$L.flags"; mkdir -p "$FL"; rm -f "$FL/ready" "$FL/go"
    before="$(git -C "$D/tree" rev-parse HEAD)"; echo "$before" > "$W/$L.before"
    if [ "$R" = - ]; then
        ( cd "$D/tree" && BBH_HOME="$D/bbh" PROBE_OUT="$W/$L" PROBE_FLAGS="$FL" sh probe.sh ) > "$W/$L.log" 2>&1 &
    else
        cp "$R" "$W/$L.runner.sh"; R="$W/$L.runner.sh"   # the leg's own copy: truncated mid-run below
        ( BBH_HOME="$D/bbh" PROBE_OUT="$W/$L" PROBE_FLAGS="$FL" SNAPSHOT_ROOT="$SROOT" \
          sh "$R" --repo "$D/tree" --no-romdir -- sh probe.sh ) > "$W/$L.log" 2>&1 &
    fi
    pid=$!
    i=0; while [ ! -f "$FL/ready" ] && [ $i -lt 600 ]; do sleep 0.1; i=$((i+1)); done
    [ -f "$FL/ready" ] || { echo "  FAIL: $L: the probe never reached its pause"; tail -5 "$W/$L.log" | sed 's/^/    /'; kill $pid 2>/dev/null || true; return 1; }
    perturb "$D"; [ "$R" = - ] || : > "$R"; : > "$FL/go"
    wait $pid || { echo "  FAIL: $L: the run exited non-zero"; tail -5 "$W/$L.log" | sed 's/^/    /'; return 1; }
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
    echo "  $2: all six inputs unchanged across the perturbation and the runner's own file truncated mid-run; record complete, commit $(printf %.12s "$rc") = the start commit"
}

RUNNER="$REPO/tests/run_on_snapshot.sh"
if vs_ctl_is link-build || vs_ctl_is in-place || vs_ctl_is shared-bbh || vs_ctl_is no-self-copy; then RUNNER="$(make_copy "$VS_CTL")"; fi

echo "== 1. the positive leg: the perturbation reaches an IN-PLACE run"
if leg inplace -; then
    c="$(changed "$W/inplace")"
    n=$(echo "$c" | wc -w | tr -d ' ')
    if [ "$n" = 7 ]; then echo "  ok: all seven readings changed in place ($c)"
    else echo "  FAIL: in place, only [$c] changed — the perturbation does not reach a run, so section 2 would prove nothing"; fail=1; fi
else fail=1; fi

echo "== 2. the snapshot leg: nothing reaches a run on a snapshot"
if ! immune "$RUNNER" snap; then fail=1; fi

echo "== 3. controls"
if [ -z "${VS_CTL:-}" ]; then
    for ctl in link-build in-place shared-bbh no-self-copy; do
        # the leg's world dir must not be the copy's dir (world() empties it first)
        if immune "$(make_copy "$ctl")" "leg_$ctl" > "$W/leg_$ctl.txt" 2>&1; then
            vs_ctl_dead "$ctl" "the perturbed copy was still immune — the gate cannot see this failure" || fail=1
        elif grep -q 'REACHED' "$W/leg_$ctl.txt"; then vs_ctl_fired "$ctl" "$(grep -m1 'REACHED' "$W/leg_$ctl.txt" | sed 's/^ *//' | cut -c1-110)"
        else vs_ctl_dead "$ctl" "the copy failed without the perturbation reaching the run: $(grep -m1 -E 'FAIL|record' "$W/leg_$ctl.txt" | sed 's/^ *//' | cut -c1-100)" || fail=1; fi
    done
fi
[ -z "$(ls -A "$SROOT" 2>/dev/null)" ] || { echo "  FAIL: a snapshot was left under $SROOT"; fail=1; }

if [ "$fail" = 0 ]; then echo "PASS: a run on a snapshot reads its commit's files and its snapshotted inputs, and nothing the working tree does during the run reaches it"
else echo "FAIL: test_run_on_snapshot"; exit 1; fi
