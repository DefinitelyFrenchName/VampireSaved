#!/bin/sh
# test_session_reap.sh — A GATE RUN LEAVES NOTHING BEHIND (#364, #371; design R, ruled 2026-11-11, 14z-226).
# ROM-free and emulator-free, ~15 s; needs python3 and GNU timeout (or gtimeout).
#
# WHAT: tests/lib/session_run.py, through which tests/run_all_emulator.sh runs every gate (plain and CONTROL=), passes
#   the gate's exit status through, gives the gate a TMPDIR of its own and removes it, ends every process left in the
#   gate's session (TERM, a bounded wait, KILL) even when a nested timeout put it in a group of its own and it ignores
#   TERM, and forwards a TERM sent to it to the gate's session; and the runner's four gate command lines go through it.
# HOW: the helper on small commands: exit 3; a shell killed by TERM (143); `timeout 1 sleep 9` (124). A command that
#   writes into its TMPDIR: the TMPDIR is a fresh `gate.*` under the given base, and gone afterwards. A PLANT that
#   exits 0 leaving two TERM-ignoring sleeps (one direct, one under a nested `timeout 600`, the shape measured on PILOT
#   in 14z-225), each with a sleep length unique to this run: 0 must be left. A plain sleep behind the helper, the
#   helper sent TERM: exit 143 and 0 left. The runner: every line that runs `tests/$_g.sh` names the helper (4 lines),
#   and the runner exports JTSIM_SCRATCH (a MiSTer gate's scratch fallback would otherwise land in the per-gate TMPDIR).
# EXPECTS: 3 of 3 statuses, the TMPDIR case, 0 plant survivors, the forwarded TERM, 4 of 4 runner lines and the export.
# FOLLOWS: tests/lib/session_run.py tests/run_all_emulator.sh tests/lib/controls.sh tests/lib/classify.sh
# NOT TESTED: a real emulator gate (the runner's rows measure that: build/agent226/t364/, local); macOS `mktemp -d`
#   without a template ignoring TMPDIR (docs/platform/gotchas.md), a limit of the helper, not checked here.
#
# SHEET: none — an instrument check on processes and directories it makes itself; no leg of our build compared
#
# MUST-FIRE: shadow-tool: no-reap — the helper with its reap switched off (in its own process, the file untouched) must leave the plant's sleeps alive and FAIL the gate (in-gate: that case alone; mode: every helper case run that way)
# MUST-FIRE: shadow-tool: no-forward — the helper with no signal handler installed (in its own process) must die on the TERM sent to it and leave the gate's sleep alive, and FAIL the gate (in-gate: that case alone; mode: every helper case run that way)
# MUST-FIRE: perturbed-copy: unwired — a copy of the runner with one gate command line not through the helper must FAIL the wiring check (in-gate: that copy; mode: the copy is the runner read)
#
# SHARES: none — each run and each control mode writes only its own mktemp directory, and its sleeps carry lengths unique to its own pid
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
TO="$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || true)"
[ -n "$TO" ] || { echo "SKIP: no GNU timeout on this host (the runner needs it too)"; exit 0; }
H=tests/lib/session_run.py
W="$(mktemp -d "${TMPDIR:-/tmp}/session_reap.XXXXXX")" || { echo "FAIL: test_session_reap — mktemp -d failed"; exit 2; }
N1=$((70000 + $$ % 9000)); N2=$((N1 + 9001)); N3=$((N1 + 18002))   # sleep lengths unique to this run
sweep() { for _p in $(pgrep -f "^sleep ($N1|$N2|$N3)\$" 2>/dev/null); do kill -KILL "$_p" 2>/dev/null; done; }
trap 'sweep; rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
fail=0; : > "$W/main.log"
ok()  { echo "  ok    $*"; }
bad() { echo "  FAIL  $*"; echo "  FAIL  $*" >> "$W/main.log"; fail=1; }   # main.log: the check's findings (#369)
left() { pgrep -f "^sleep ($N1|$N2|$N3)\$" 2>/dev/null | wc -l | tr -d ' '; }

# helper <perturbation|-> <command...>: the helper as the runner calls it, or loaded in a process of its own with one
# part switched off (the file untouched). HX=exec, set inside a backgrounded subshell, makes the subshell BECOME the
# helper, so `$!` is the helper's pid (a TERM sent to a function's subshell never reaches the helper, 14z-226).
HX=""
helper() {
    _p="$1"; shift
    if [ "$_p" = - ]; then $HX python3 "$H" "$@"; return; fi
    $HX python3 - "$_p" "$@" <<'PY'
import signal, sys
sys.path.insert(0, "tests/lib")
import session_run as m
p = sys.argv[1]
if p == "no-reap":
    m.reap = lambda sid, status, wait_s: 0
elif p == "no-forward":
    signal.signal = lambda *a, **k: None
sys.exit(m.main(sys.argv[2:]))
PY
}
P=-; vs_ctl_is no-reap && P=no-reap; vs_ctl_is no-forward && P=no-forward
export REAP_WAIT=2

echo "== 1. the exit status passes through"
for c in "3|sh -c 'exit 3'" "143|sh -c 'kill -TERM \$\$'" "124|$TO 1 sleep 9"; do
    want="${c%%|*}"; cmd="${c#*|}"
    eval "helper $P $cmd" > "$W/s.out" 2>&1; st=$?
    [ "$st" = "$want" ] && ok "exit $want from: $cmd" || bad "exit $st from: $cmd, want $want"
done

echo "== 2. a TMPDIR of the gate's own, removed afterwards"
mkdir -p "$W/base"
TMPDIR="$W/base" helper $P sh -c 'echo "$TMPDIR" > "$0"; echo x > "$TMPDIR/f"' "$W/tmpdir.txt" > "$W/t.out" 2>&1
g="$(cat "$W/tmpdir.txt" 2>/dev/null)"
case "$g" in "$W/base/gate."*) ok "the gate's TMPDIR was $(basename "$g") under the base" ;; *) bad "the gate's TMPDIR was '$g', want a gate.* under $W/base" ;; esac
n="$(find "$W/base" -mindepth 1 | wc -l | tr -d ' ')"
[ -n "$g" ] && [ ! -e "$g" ] && [ "$n" = 0 ] && ok "removed afterwards, the base empty" || bad "the gate's TMPDIR left behind ($n entries in the base)"

echo "== 3. the plant: it exits 0 leaving two TERM-ignoring sleeps (one under a nested timeout)"
cat > "$W/plant.sh" <<EOF
#!/bin/sh
sh -c 'trap "" TERM; exec sleep $N1' &
$TO 600 sh -c 'trap "" TERM; sleep $N2' &
sleep 1; exit 0
EOF
helper $P "$TO" -k 30 20 sh "$W/plant.sh" > "$W/plant.out" 2>&1; st=$?
sleep 1; l="$(left)"
[ "$st" = 0 ] && [ "$l" = 0 ] && ok "0 left; $(grep -a 'KILL needed' "$W/plant.out" | sed 's/^### session_run: //')" \
    || bad "plant: $l sleep(s) left after the helper returned (exit $st)"
sweep

echo "== 4. a TERM sent to the helper reaches the gate's session"
( HX=exec; helper $P sh -c "sleep $N3" ) > "$W/fwd.out" 2>&1 &
hp=$!; i=0
while [ "$i" -lt 50 ] && [ "$(left)" = 0 ]; do sleep 0.1; i=$((i + 1)); done
kill -TERM "$hp" 2>/dev/null; wait "$hp"; st=$?
sleep 1; l="$(left)"
[ "$st" = 143 ] && [ "$l" = 0 ] && ok "exit 143, 0 left" || bad "forward: exit $st, $l sleep(s) left after the helper was sent TERM"
sweep

echo "== 5. the runner's gate command lines go through the helper"
R=tests/run_all_emulator.sh
if vs_ctl_is unwired; then
    perl -pe 'if (!$d && s{python3 tests/lib/session_run.py "\$TIMEOUT_BIN"}{"\$TIMEOUT_BIN"}) { $d = 1 }' "$R" > "$W/runner_unwired.sh"
    R="$W/runner_unwired.sh"
fi
wiring() {  # wiring <runner> -> prints the problems, one per line
    grep -n '"tests/\$_g\.sh" \$_pos' "$1" | grep -v '^[0-9]*:[[:space:]]*#' > "$W/lines.txt"
    nl="$(wc -l < "$W/lines.txt" | tr -d ' ')"
    [ "$nl" = 4 ] || echo "the runner has $nl gate command lines, want 4"
    grep -v 'python3 tests/lib/session_run.py ' "$W/lines.txt" | sed 's/^/a gate command line not through the helper: /'
    grep -q '^export JTSIM_SCRATCH="\$JTSIM_BASE"$' "$1" || echo "the runner does not export JTSIM_SCRATCH"
}
wiring "$R" > "$W/wiring.txt"
if [ -s "$W/wiring.txt" ]; then while IFS= read -r line; do bad "$(echo "$line" | cut -c1-200)"; done < "$W/wiring.txt"
else ok "4 of 4 gate command lines through the helper; JTSIM_SCRATCH exported"; fi

if [ -n "${VS_CTL:-}" ]; then
    [ "$fail" = 1 ] || vs_ctl_left_green "$VS_CTL" "FAIL: test_session_reap (control mode)"
    case "$VS_CTL" in
    no-reap)    WANT='^  FAIL  plant: [1-9][0-9]* sleep\(s\) left after the helper returned' ;;
    no-forward) WANT='^  FAIL  forward: exit [0-9]+, [1-9][0-9]* sleep\(s\) left after the helper was sent TERM$' ;;
    unwired)    WANT='^  FAIL  a gate command line not through the helper: ' ;;
    *) WANT='' ;;
    esac
    vs_ctl_caught "$W/main.log" "$WANT" || :
    echo "FAIL: test_session_reap (control mode)"; exit 1
fi

echo "== 6. controls"
helper no-reap "$TO" -k 30 20 sh "$W/plant.sh" > "$W/c1.out" 2>&1; sleep 1; l="$(left)"
if [ "$l" -gt 0 ]; then vs_ctl_fired no-reap "with the reap off, $l plant sleep(s) outlived the helper"
else vs_ctl_dead no-reap "with the reap off, no plant sleep outlived the helper: the survivor count is blind"; fail=1; fi
sweep
( HX=exec; helper no-forward sh -c "sleep $N3" ) > "$W/c2.out" 2>&1 &
hp=$!; i=0
while [ "$i" -lt 50 ] && [ "$(left)" = 0 ]; do sleep 0.1; i=$((i + 1)); done
kill -TERM "$hp" 2>/dev/null; wait "$hp"; sleep 1; l="$(left)"
if [ "$l" -gt 0 ]; then vs_ctl_fired no-forward "with no handler, the helper died on TERM and $l sleep(s) of the gate's session lived on"
else vs_ctl_dead no-forward "with no handler, nothing outlived the helper: the forwarding case cannot tell"; fail=1; fi
sweep
perl -pe 'if (!$d && s{python3 tests/lib/session_run.py "\$TIMEOUT_BIN"}{"\$TIMEOUT_BIN"}) { $d = 1 }' tests/run_all_emulator.sh > "$W/c3.sh"
if wiring "$W/c3.sh" | grep -q '^a gate command line not through the helper: '; then vs_ctl_fired unwired "a runner copy with one line unwired is named"
else vs_ctl_dead unwired "a runner copy with one line unwired passed the wiring check"; fail=1; fi

[ "$fail" = 0 ] && echo "PASS: test_session_reap — statuses, the gate's TMPDIR, 0 plant survivors, the forwarded TERM, 4 of 4 runner lines" || echo "FAIL: test_session_reap"
exit "$fail"
