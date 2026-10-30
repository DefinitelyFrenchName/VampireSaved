#!/bin/sh
# test_mame_runner_hygiene.sh — A MAME REPLAY THAT WRITES NOTHING CANNOT PASS ON THE LAST RUN'S LOG (14z-197, GitHub #253). ci_portable: no ROM, no MAME, ~2 s.
#
# WHAT: tools/run_replay_mame.sh clears what the run must write — the checksum log, INPUT_OUT, VIDEO_OUT and each
#   file a DUMPS spec names — before the emulator starts, so a run that exits 0 without writing fails on its own
#   missing log instead of passing on the previous one; a dump in the same directory that no spec names is kept;
#   a run that writes a complete log still passes.
# HOW: the wrapper as shipped, its MAME_BIN a stub: `silent` exits 0 and writes nothing, `fail` exits 1, `good`
#   writes a fresh log ending `END`. Stale outputs are planted before each run.
# EXPECTS: silent and fail -> non-zero exit and every planted output gone; the unnamed dump kept; good -> exit 0
#   on its own fresh log. The 14z-197 shape: a seeded `END 1` log and a no-output exit 0 returned success with the
#   stale log in place (the FBNeo sibling has cleared its outputs since 14z-90, #12, tests/test_fbneo_runner_hygiene.sh).
#
# MUST-FIRE: shadow-tool: no-clear — a copy of the wrapper with its clearing step removed (the pre-#253 wrapper) must return success on the stale log under the silent stub and FAIL section 1 (mode: the copy is the wrapper under test)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_mame_runner_hygiene — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM
rc=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; rc=1; }

cat > "$W/fake_mame.sh" <<'EOF'
#!/bin/sh
case "${FAKE_MODE:-silent}" in
    silent) exit 0 ;;
    fail)   exit 1 ;;
    good)   printf '0 fresh\nEND 1\n' > "$CHECKSUM_OUT"; exit 0 ;;
esac
EOF
chmod +x "$W/fake_mame.sh"
printf '0 0 0\n' > "$W/r.rpl"; mkdir -p "$W/roms"

# no_clear <root> — a shadow root: tools/ holds the wrapper with its clearing step removed beside a link to the
# real run_mame.sh, and tests/ links to the real one (the wrapper resolves both from its own location)
no_clear() {
    mkdir -p "$1/tools" && ln -s "$REPO/tests" "$1/tests" && ln -s "$REPO/tools/run_mame.sh" "$1/tools/run_mame.sh" || return 1
    python3 - "$REPO/tools/run_replay_mame.sh" "$1/tools/run_replay_mame.sh" <<'PY'
import sys
s = open(sys.argv[1]).read()
start, end = s.find('rm -f "$OUT"\n'), s.find('IFS="$_ifs"\n')
if start < 0 or end < start:
    sys.exit("no_clear: the clearing step was not found")
open(sys.argv[2], "w").write(s[:start] + ": # CONTROL no-clear\n" + s[end + len('IFS="$_ifs"\n'):])
PY
    chmod +x "$1/tools/run_replay_mame.sh"
}
WRAP="$REPO/tools/run_replay_mame.sh"
if vs_ctl_is no-clear; then
    no_clear "$W/shadow" || { echo "REFUSED: CONTROL=no-clear could not build its copy"; exit 3; }
    WRAP="$W/shadow/tools/run_replay_mame.sh"
fi

run() {  # run <wrapper> <mode> <case dir> [env assignments...] — the wrapper's exit status
    w="$1"; m="$2"; d="$3"; shift 3
    env "$@" ROMDIR="$W/roms" MAME_BIN="$W/fake_mame.sh" FAKE_MODE="$m" \
        sh "$w" vsavj "$W/r.rpl" "$d/out.log" "$d/sandbox" > "$d/wrapper.txt" 2>&1
    echo $?
}
stale_log() { printf '0 stale\nEND 1\n' > "$1/out.log"; }

section1() {  # section1 <wrapper> <dir> — the silent and failing stubs on a stale log
    for m in silent fail; do
        d="$2/$m"; mkdir -p "$d"; stale_log "$d"
        e="$(run "$1" "$m" "$d")"
        [ "$e" = 0 ] && echo "    $m: exit 0 on the stale log"
        [ -f "$d/out.log" ] && echo "    $m: the stale log survived ($(head -1 "$d/out.log"))"
    done
}
echo "== 1. a run that writes nothing cannot pass on the previous run's log"
section1 "$WRAP" "$W/s1" > "$W/s1.txt"
if [ -s "$W/s1.txt" ]; then bad "the stale log was accepted or survived:"; cat "$W/s1.txt"
else ok "silent (exit 0, no output) and failing stubs: non-zero exit, stale log removed"; fi

echo "== 2. the side channels a run names are cleared by name, and only those"
d="$W/s2"; mkdir -p "$d"; stale_log "$d"
for f in in.txt vid.txt dump_2900_ff8000.bin dump_5_00ff00.bin dump_7_000001.bin; do echo stale > "$d/$f"; done
e="$(run "$WRAP" silent "$d" INPUT_OUT="$d/in.txt" VIDEO_OUT="$d/vid.txt" DUMPS='2900:ff8000-ff8700;5:ff00-ff10')"
left=""; for f in out.log in.txt vid.txt dump_2900_ff8000.bin dump_5_00ff00.bin; do [ -f "$d/$f" ] && left="$left $f"; done
[ -z "$left" ] && ok "INPUT_OUT, VIDEO_OUT and both DUMPS files cleared" || bad "stale side-channel output(s) survived:$left"
[ -f "$d/dump_7_000001.bin" ] && ok "a dump no spec names is left alone (another leg's, in a shared directory)" || bad "an unnamed dump was deleted"
[ "$e" != 0 ] && ok "the run exited $e" || bad "the silent run exited 0"

echo "== 3. POSITIVE CONTROL — a run that writes its log passes"
d="$W/s3"; mkdir -p "$d"; stale_log "$d"
e="$(run "$WRAP" good "$d")"
[ "$e" = 0 ] && grep -qx '0 fresh' "$d/out.log" && ok "exit 0 on the run's own fresh log" || { bad "the good stub: exit $e"; sed 's/^/        /' "$d/wrapper.txt"; }

if vs_ctl_is no-clear; then
    [ "$rc" = 1 ] && { echo "FAIL: test_mame_runner_hygiene (control mode: no-clear)"; exit 1; }
    echo "FAIL: test_mame_runner_hygiene — control mode no-clear left the gate green"; exit 1
fi

echo "== 4. control"
if ! no_clear "$W/ctl" > "$W/ctl_build.txt" 2>&1; then
    vs_ctl_dead no-clear "the copy could not be built: $(tail -1 "$W/ctl_build.txt")" || rc=1
else
    section1 "$W/ctl/tools/run_replay_mame.sh" "$W/c1" > "$W/c1.txt"
    if grep -q 'silent: exit 0 on the stale log' "$W/c1.txt"; then
        vs_ctl_fired no-clear "the wrapper without its clearing step returned success on the stale log (silent stub)"
    else
        vs_ctl_dead no-clear "the copy did not accept the stale log: $(head -1 "$W/c1.txt")" || rc=1
    fi
fi

[ "$rc" = 0 ] && echo "PASS: test_mame_runner_hygiene" || echo "FAIL: test_mame_runner_hygiene"
exit "$rc"
