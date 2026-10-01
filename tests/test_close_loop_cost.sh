#!/bin/sh
# test_close_loop_cost.sh — the close-loop cost reader counts every pass of a close's check runner
# and the packet's span, whatever interpreter ran the runner and however a prepare's output was cut
# (`tools/agent/close_loop_cost.py`, 14z-187b, GitHub #187).
#
# WHAT: tools/agent/close_loop_cost.py reads a session transcript and reports each execution of a
#   close's check runner with its seconds, the passes whose own command edited a count, the
#   packet's span from the first rule-checker prepare to the last record, and every distinct
#   "<n> untracked" figure.
# HOW: builds a SYNTHETIC transcript (no real transcript is committed: one carries the user's
#   identity) holding every shape that has broken the reader — a runner run by python3 with a
#   subcommand, its `status` call and a mere mention (neither a pass), a background pass ended by
#   its task notification, a sh-run runner, a prepare whose output was cut to its last line, a
#   record — and requires the reader's exact lines; then runs the reader's own --plant; three
#   controls run shadow copies with one perturbation each, and each must fail the comparison.
# EXPECTS: the python3 runner 2 passes / 190 s (70 s foreground EDITS-COUNT, 120 s background),
#   the sh runner 1 pass / 30 s, the span 0.67 h, the figure 1,234, the plant CAUGHT; each control
#   FIRES.
#
# WHY. The 14z-186 close ran #187's own runner, tools/close_checks.py, under python3: the reader
# counted 0 of its 14 `run` calls and found run 486's prepare nowhere (piped through `tail -1`, its
# output never said "prepared run"). Fixed, the reader gives 14 passes / 913 s / 0.92 h for that
# close, and still reproduces the 14z-185 close byte for byte (62 passes, 18,799 s, 11.52 h).
#
# MUST-FIRE: shadow-tool: no-python — a copy whose runner pattern knows only sh/bash must miss the python3 passes, and the comparison must FAIL (mode: the gate reads that copy)
# MUST-FIRE: shadow-tool: verb-ignored — a copy that ignores --verb must count the runner's `status` call as a pass, and the comparison must FAIL (mode: the gate reads that copy)
# MUST-FIRE: shadow-tool: prepare-by-line — a copy that finds a prepare only by a "prepared run" line must miss the tail-cut prepare, and the comparison must FAIL (mode: the gate reads that copy)
#
# Usage: tests/test_close_loop_cost.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
TOOL=tools/agent/close_loop_cost.py

python3 - "$W/t.jsonl" <<'PY'
import json, sys
recs = []
def call(ts, uid, cmd, bg=False):
    inp = {"command": cmd}
    if bg: inp["run_in_background"] = True
    recs.append({"type": "assistant", "timestamp": ts, "message": {"content": [
        {"type": "tool_use", "id": uid, "name": "Bash", "input": inp}]}})
def result(ts, uid, body):
    recs.append({"type": "user", "timestamp": ts, "message": {"content": [
        {"type": "tool_result", "tool_use_id": uid, "content": body}]}})
call("2026-10-01T09:50:00Z", "P", "python3 tools/rulecheck.py prepare --decision build --claim x 2>&1 | tail -1")
result("2026-10-01T09:50:02Z", "P", "  python3 tools/rulecheck.py record 2026-10-01-9001 --a <file> --b <file>")
call("2026-10-01T10:00:00Z", "R1", "echo '1,234 untracked' >> build/x/row.txt; python3 tools/close_checks.py run build/x/checks.tsv --out build/x/out")
result("2026-10-01T10:01:10Z", "R1", "26 checks, 0 not as expected")
call("2026-10-01T10:05:00Z", "S", "python3 tools/close_checks.py status build/x/checks.tsv --out build/x/out")
result("2026-10-01T10:05:01Z", "S", "status: RUN OF RECORD")
call("2026-10-01T10:06:00Z", "M", "sed -n 1,5p tools/close_checks.py")
result("2026-10-01T10:06:01Z", "M", "#!/usr/bin/env python3")
call("2026-10-01T10:10:00Z", "R2", "python3 tools/close_checks.py run build/x/checks.tsv --out build/x/out --only tickets", bg=True)
result("2026-10-01T10:10:01Z", "R2", "Command running in background with ID: bgx1. Output is being written to: /tmp/x")
recs.append({"type": "user", "timestamp": "2026-10-01T10:12:00Z", "message": {"content":
    "<task-notification>\n<task-id>bgx1</task-id>\n<status>completed</status>\n</task-notification>"}})
call("2026-10-01T10:30:00Z", "D", "python3 tools/rulecheck.py record 2026-10-01-9002 --a a.txt --b b.txt --session x")
result("2026-10-01T10:30:05Z", "D", "OK: no question violated")
call("2026-10-01T11:00:00Z", "SH", "sh build/x/run_checks.sh")
result("2026-10-01T11:00:30Z", "SH", "done")
with open(sys.argv[1], "w") as f:
    for r in recs: f.write(json.dumps(r) + "\n")
PY

shadow() {  # shadow <control> — a copy of the reader with ONE perturbation
    mkdir -p "$W/$1"; cp "$TOOL" "$W/$1/close_loop_cost.py"
    python3 - "$W/$1/close_loop_cost.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "no-python": ("(?:sh|bash|python3?)", "(?:sh|bash)"),
    "verb-ignored": ("_VERB = (r'\\s+' + re.escape(A.verb) + r'\\b') if A.verb else ''", "_VERB = ''  # CONTROL verb-ignored"),
    "prepare-by-line": ('and "rulecheck.py prepare" in i.get("command", "") and (rid.search(i.get("command", "")) or rid.search(results[u][1]))',
                        'and re.search(r"prepared run " + rid.pattern, results[u][1])'),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/close_loop_cost.py"
}

# check <tool> <out> — the reader's lines on the synthetic transcript; 0 when every line is as expected
check() {
    python3 "$1" "$W/t.jsonl" --script tools/close_checks.py --verb run --first-run 9001 --last-run 9002 > "$2.py" 2>&1 || return 1
    python3 "$1" "$W/t.jsonl" --script build/x/run_checks.sh > "$2.sh" 2>&1 || return 1
    grep -qx '  count: 2  total_seconds: 190  max_seconds: 120' "$2.py" \
    && grep -qx "  passes whose own command edits a '<n> untracked' figure: 1  their seconds: 70" "$2.py" \
    && grep -q '^  2026-10-01T10:10:00Z    120 s  background  R2$' "$2.py" \
    && grep -q '^  2026-10-01T10:00:00Z     70 s  foreground  R1  EDITS-COUNT$' "$2.py" \
    && grep -qx '  first prepare -9001: 2026-10-01T09:50:02Z  last record -9002: 2026-10-01T10:30:05Z  hours: 0.67' "$2.py" \
    && grep -qx '  2026-10-01T10:00  1,234  (input)' "$2.py" \
    && grep -qx '  count: 1  total_seconds: 30  max_seconds: 30' "$2.sh"
}

echo "== test_close_loop_cost: #187 — the close-loop cost reader =="
fail=0
T="$TOOL"
if vs_ctl_is no-python || vs_ctl_is verb-ignored || vs_ctl_is prepare-by-line; then T="$(shadow "$VS_CTL")"; fi
if check "$T" "$W/real"; then echo "  ok    every line as expected (2 python3 passes / 190 s, 1 sh pass / 30 s, span 0.67 h, figure 1,234)"
else echo "  FAIL  the reader's lines on the synthetic transcript:"; sed 's/^/        /' "$W/real.py" "$W/real.sh"; fail=1; fi

if [ -z "${VS_CTL:-}" ]; then
    python3 "$TOOL" "$W/t.jsonl" --script tools/close_checks.py --verb run --first-run 9001 --last-run 9002 --plant > "$W/plant.txt" 2>&1 || true
    if grep -q '^PLANT: CAUGHT' "$W/plant.txt"; then echo "  ok    $(grep '^PLANT:' "$W/plant.txt")"
    else echo "  FAIL  the reader's own plant: $(grep '^PLANT:' "$W/plant.txt" || tail -1 "$W/plant.txt")"; fail=1; fi
    # each control must fail for ITS reason (a copy that crashes, or misreads something else, is DEAD)
    for c in no-python verb-ignored prepare-by-line; do
        case "$c" in
        no-python)       want='^  count: 0  total_seconds: 0  max_seconds: -$' ;;
        verb-ignored)    want='^  count: 3  total_seconds: 191  max_seconds: 120$' ;;
        prepare-by-line) want='^  NOT FOUND \(prepare -9001: 0, record -9002: 1\)$' ;;
        esac
        if check "$(shadow "$c")" "$W/ctl_$c"; then vs_ctl_dead "$c" "the perturbed copy still read every line as expected" || fail=1
        elif grep -qE "$want" "$W/ctl_$c.py"; then vs_ctl_fired "$c" "$(grep -m1 -E "$want" "$W/ctl_$c.py" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the copy failed, but not for its reason: $(tail -1 "$W/ctl_$c.py")" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: the reader counts every pass of the runner, whatever runs it, and finds the packet's span"
else echo "FAIL: test_close_loop_cost"; exit 1; fi
