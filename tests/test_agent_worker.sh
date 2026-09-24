#!/bin/sh
# test_agent_worker.sh — SLICE S4 OF GitHub #172, step 2: "a worker run on a known task returns
# figures each traceable to a command" (docs/project/agent_architecture_scope.md §5), over a
# FROZEN real run — ruled 2026-09-23 (14z-177, DECISIONS_HISTORY.md "Ruled 2026-09-23 (14z-177)").
#
# WHAT: a worker run on a known task returns figures each traceable to a spec command: over
#   a FROZEN real `measurer` run, the worker ran at its definition's caps, every report
#   figure appears in a result the worker itself got, every FIG names a spec command the
#   worker ran and re-running that command reproduces the figure, and nothing off-spec ran.
# HOW: tools/agent/extract.py reads the cut fixture tests/agent/worker_fixture/ (the raw
#   transcript carried the maintainer's e-mail; the cut keeps only what the extract reads);
#   only pinned `git show <sha>:<path> | wc -l | shasum` shapes are re-executed; three
#   controls perturb a copy (a changed figure, a missing worker transcript, an off-spec
#   command).
# EXPECTS: every figure re-derives and conformance holds; each control fails on its copy; a
#   red names the figure or the command.
#
# The fixture, tests/agent/worker_fixture/: a headless `claude -p` in this repository
# (2026-09-23, Claude Code 2.1.280, session f155b260) that handed `.claude/agents/measurer.md` a
# spec written from docs/project/worker_spec.md — two commands reading only content pinned at
# commit d5653d1f, so every figure re-derives forever — CUT by tools/agent/cut_worker_fixture.py
# (the raw transcripts carried the maintainer's e-mail; the cut keeps only what the extract reads
# and refuses to write an address). What the gate asserts, through tools/agent/extract.py:
#   1. the worker RAN at its definition's caps (WM: the definition's model family and effort);
#   2. no W# line: every figure of the report is in a result the worker itself got;
#   3. every FIG names a spec command C<n>, that command is among the worker's own calls, and
#      re-running it here (only commands of the pinned `git show <sha>:<path> | wc -l|shasum`
#      shape are ever executed) reproduces the figure;
#   4. conformance, the deterministic half of QP5: the worker ran every spec command and nothing
#      else.
#
# MUST-FIRE: perturbed-copy: planted-figure — the report's 273 changed to 274 in a copy of the worker transcript must be flagged by W# and fail re-derivation, and the gate must FAIL (mode: the gate reads that copy)
# MUST-FIRE: perturbed-copy: blind-worker-transcript — a copy without the worker's transcript must read NO WORKER TRANSCRIPT, and the gate must FAIL (mode: the gate reads that copy)
# MUST-FIRE: perturbed-copy: off-spec-command — the worker's C1 call rewritten to `wc -c` in a copy must fail conformance, and the gate must FAIL (mode: the gate reads that copy)
#
# Usage: tests/test_agent_worker.sh      # ci_portable, ~1 s (needs git and commit d5653d1f)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT INT TERM
FIX="tests/agent/worker_fixture"
SESSION="f155b260-38a2-4bda-b066-6bae9155b4ad"
DEF=".claude/agents/measurer.md"

# perturb NAME DIR — a copy of the fixture at DIR with control NAME's one defect planted
perturb() {
    rm -rf "$2"; cp -R "$FIX" "$2"
    wt="$(ls "$2/$SESSION"/subagents/agent-*.jsonl)"
    case "$1" in
        planted-figure)          sed -i.bak 's/FIG ci_portable_lines = 273/FIG ci_portable_lines = 274/' "$wt";;
        blind-worker-transcript) rm -rf "$2/$SESSION";;
        off-spec-command)        sed -i.bak 's#tests/ci_portable.txt | wc -l"#tests/ci_portable.txt | wc -c"#' "$wt";;
    esac
    find "$2" -name '*.bak' -exec rm -f {} +
}

# judge DIR — the four assertions over the fixture at DIR; prints them, exits 0 only if all hold
judge() {
python3 - "$1/$SESSION.jsonl" "$DEF" <<'PY'
import re, subprocess, sys
sys.path.insert(0, "tools/agent")
import extract
path, defn = sys.argv[1], sys.argv[2]
text = extract.extract(path)
lines = text.split("\n")
fail = []
def pick(code):
    return [ln.split(f" {code} ", 1)[1] for ln in lines if f" {code} " in ln]
blocks = [ln for ln in lines if re.search(r"\] W  worker ", ln)]
if len(blocks) != 1:
    fail.append(f"expected one worker block, found {len(blocks)}")
if any("NO WORKER TRANSCRIPT" in ln for ln in lines):
    fail.append("NO WORKER TRANSCRIPT: the worker's commands and report cannot be read")
# 1. caps: the run matches the definition's model family and effort
d = dict(re.findall(r"^(model|effort):\s*(\S+)", open(defn).read(), re.M))
wm = pick("WM")
if not wm or d.get("model", "?") not in wm[0] or f"at effort {d.get('effort', '?')}" not in wm[0]:
    fail.append(f"the worker did not run at its definition's caps ({d}): {wm}")
# 2. every report figure sourced in the worker's own results
if pick("W#"):
    fail.append(f"W#: {pick('W#')[0]}")
spec = "\n".join(s[2:] if s.startswith("| ") else s for s in pick("WS"))
report = [s[2:] for s in pick("WX") if s.startswith("| ")]
calls = [s.split(": ", 1)[1] for s in pick("WT") if s.startswith("Bash: ")]
cmds = dict(re.findall(r"^C(\d+): (.+)$", spec, re.M))
figs = [m.groups() for m in (re.match(r"FIG (\S+) = (.+?) <- C(\d+)$", r) for r in report) if m]
if not figs:
    fail.append("no FIG line in the report")
SAFE = re.compile(r"^git show [0-9a-f]{7,40}:[\w./-]+ \| (wc -l|shasum -a 1)$")
# 3. traceable: each FIG's command is in the spec, was run by the worker, and reproduces it
for name, value, c in figs:
    cmd = cmds.get(c)
    if not cmd:
        fail.append(f"FIG {name} names C{c}, which the spec does not have"); continue
    if cmd not in calls:
        fail.append(f"FIG {name}: C{c} ({cmd}) is not among the worker's own calls"); continue
    if not SAFE.match(cmd):
        fail.append(f"FIG {name}: C{c} is not of the pinned shape this gate will execute: {cmd}"); continue
    got = subprocess.run(["sh", "-c", cmd], capture_output=True, text=True).stdout.split()
    ok = value in got
    print(f"  {'ok  ' if ok else 'FAIL'}  FIG {name} = {value} <- C{c}: re-run gives {' '.join(got)[:60]}")
    if not ok:
        fail.append(f"FIG {name} = {value} does not re-derive from C{c}")
# 4. conformance: every spec command run, nothing else run
missing = [f"C{c}" for c, cmd in cmds.items() if cmd not in calls]
extra = [x for x in calls if x not in cmds.values()]
if missing or extra:
    fail.append(f"conformance: spec commands not run {missing}, calls not in the spec {extra}")
for f in fail:
    print(f"  FAIL  {f}")
print(f"  worker block: {len(blocks)}, figures: {len(figs)}, spec commands: {len(cmds)}, worker calls: {len(calls)}")
sys.exit(1 if fail else 0)
PY
}

fail=0
target="$FIX"
if [ -n "$VS_CTL" ]; then
    target="$W/mode"; perturb "$VS_CTL" "$target"
    echo "MODE: control $VS_CTL — judging a copy of the fixture with that defect planted"
fi
echo "== the frozen measurer run ($target)"
judge "$target" || { echo "FAIL: the worker's figures are not all traceable to the commands it ran"; fail=1; }

if [ -z "$VS_CTL" ]; then
    echo "== controls: one planted defect per copy, each must fail the judgement"
    for c in planted-figure blind-worker-transcript off-spec-command; do
        perturb "$c" "$W/$c"
        if out="$(judge "$W/$c" 2>&1)"; then
            vs_ctl_dead "$c" "the planted defect passed the judgement" || fail=1
        else
            vs_ctl_fired "$c" "$(echo "$out" | grep '  FAIL' | head -1 | sed 's/^ *FAIL *//' | cut -c1-120)"
        fi
    done
fi

if [ "$fail" -eq 0 ]; then echo "PASS: a real worker run returned figures each traceable to a spec command it ran, at its definition's caps, and nothing off-spec"
else echo "FAIL: test_agent_worker"; fi
exit "$fail"
