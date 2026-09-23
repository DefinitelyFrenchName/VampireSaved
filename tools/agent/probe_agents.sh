#!/bin/sh
# probe_agents.sh — measure what a `.claude/agents/<name>.md` WORKER DEFINITION actually
# binds, in a THROWAWAY scratch project (never this tree's .claude/), with headless
# `claude -p` runs (GitHub #172 slice S4; docs/project/agent_architecture_scope.md §2).
# Written 14z-177 from two scratch probes whose first run was VOID: its write controls
# never wrote, because a headless run refuses Write/Bash it was not pre-allowed — so every
# run here passes --allowedTools, and every "cannot" leg has a "can" leg beside it.
#
#   A1  a definition's `model` is the model the worker runs on
#   A2  the ORCHESTRATOR'S `model` parameter on the Agent call BEATS the definition
#   A3  a definition's `effort` is applied and recorded (`effort` on every assistant record
#       of the worker's transcript): low -> low, xhigh -> xhigh
#   A4  a definition with NO effort line INHERITS the parent session's effort
#       (--effort low -> low, --effort xhigh -> xhigh)
#   A5  the `tools` list binds: a read-only worker cannot create a file; A5c, its must-fire
#       leg: a worker given Write, same ask, creates it
#   A6  a `hooks:` block in the definition's frontmatter does NOT fire (its deny never ran,
#       the command it should have refused created its marker) — a NEGATIVE finding, kept
#       as a leg so the day it starts firing this probe says so; A6c, its must-fire leg: the
#       SAME hook command wired as a PROJECT hook does fire and deny that worker's call
#       (added after rule-checker run 2026-09-23-109: a silent hook that could not run at all
#       would have read the same)
#   A7  a PROJECT PreToolUse hook sees the worker's own tool calls and names the worker
#       (`agent_type`, `agent_id`); the orchestrator's own calls carry neither
#   A8  a PROJECT PreToolUse hook on Agent can DENY a call carrying a `model` override;
#       A8c, its must-fire leg: the same gate lets the call without one run
#   A9  a definition with NO `model` line runs on the CALLER's model (haiku under haiku,
#       sonnet under sonnet), and so does a `general-purpose` call with no `model`
#   A10 where a worker's words land: its SPEC is the Agent call's `prompt`, its worker
#       transcript is linked to that call by `meta.json`'s `toolUseId`, its COMMANDS are in
#       that transcript and not the orchestrator's, and its REPORT reaches the orchestrator's
#       transcript (as the call's tool result, or a `[Subagent hand-back]` record)
#   (A9 and A10 added after rule-checker run 2026-09-23-109 found both premises unmeasured)
#
# Usage: tools/agent/probe_agents.sh [SCRATCH_DIR]   (~4 min: thirteen short Haiku/Sonnet runs)
# Prints one PASS/FAIL line per leg and exits non-zero on any FAIL.
# Needs: the `claude` CLI and python3. Writes only under SCRATCH_DIR (default: a mktemp dir).
set -u
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/agentprobe.XXXXXX")}
rm -rf "$S"; mkdir -p "$S/.claude/agents" "$S/hooks" || exit 2
cd "$S" || exit 2
S=$(pwd -P)
git init -q . 2>/dev/null

# every PreToolUse call is logged with its identifying keys; PROBE_AGENT_GATE=1 denies an
# Agent call that carries a model override (A8)
cat > hooks/pre.py <<'EOF'
import json, os, sys
d = json.load(sys.stdin)
i = d.get("tool_input") or {}
open(os.environ["PROBE_LOG"], "a").write(json.dumps({"tool": d.get("tool_name"), "agent_type": d.get("agent_type"),
    "agent_id": d.get("agent_id"), "transcript": d.get("transcript_path"), "input": i}) + "\n")
if os.environ.get("PROBE_AGENT_GATE") == "1" and d.get("tool_name") in ("Agent", "Task") and i.get("model"):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
        "permissionDecisionReason": "AGENT-GATE: a model override is refused; call the worker without one"}}))
EOF
cat > hooks/scoped.py <<'EOF'
import json, sys
open("scoped_hook.log", "a").write("fired\n")
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
    "permissionDecisionReason": "SCOPED-DENY: this worker may not run Bash"}}))
EOF
cat > .claude/settings.json <<EOF
{"hooks": {"PreToolUse": [{"matcher": "Bash|Write|Edit|Agent|Task", "hooks": [{"type": "command",
  "command": "PROBE_LOG=\$PROBE_LOG PROBE_AGENT_GATE=\$PROBE_AGENT_GATE python3 $S/hooks/pre.py"}]},
 {"matcher": "Bash", "hooks": [{"type": "command",
  "command": "if [ \"\$PROBE_SCOPED\" = 1 ]; then python3 $S/hooks/scoped.py; fi"}]}]}}
EOF

defn() { # name model effort tools [extra frontmatter]   (an empty model or effort omits the line)
  {
    echo "---"; echo "name: $1"; echo "description: Probe worker $1."
    [ -n "$2" ] && echo "model: $2"
    [ -n "$3" ] && echo "effort: $3"
    echo "tools: $4"
    [ -n "${5:-}" ] && printf '%s\n' "$5"
    echo "---"
    echo "Do exactly what your instructions ask, with the tools you have. If you cannot, reply CANNOT and why."
  } > ".claude/agents/$1.md"
}
defn w-low sonnet low Bash
defn w-xhigh sonnet xhigh Bash
defn w-noeff sonnet "" Bash
defn w-ro haiku "" "Read, Glob, Grep"
defn w-rw haiku "" "Write, Bash"
defn w-nomodel "" low Bash
defn w-hooked haiku "" Bash "hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: python3 $S/hooks/scoped.py"

fail=0
run() { # tag model effort gate prompt   (PROBE_SCOPED=1 in the caller's env arms A6c's project hook)
  PROBE_LOG="$S/log_$1.jsonl" PROBE_AGENT_GATE=$4 PROBE_SCOPED=${PROBE_SCOPED:-0} claude -p "$5" --model "$2" ${3:+--effort "$3"} \
    --allowedTools "Bash Write Read Glob Grep Agent" --output-format json </dev/null >"out_$1.json" 2>"err_$1.txt"
}
# workers TAG -> "agent_type model effort" per worker transcript of that run (model/effort
# as the SET over its assistant records), read from the transcript the hook log names
workers() {
python3 - "$S/log_$1.jsonl" <<'PY'
import glob, json, os, sys
try:
    t = next(json.loads(l)["transcript"] for l in open(sys.argv[1]))
except Exception:
    sys.exit(0)
for meta in sorted(glob.glob(t[:-len(".jsonl")] + "/subagents/*.meta.json")):
    at = json.load(open(meta)).get("agentType")
    models, efforts = set(), set()
    for line in open(meta[:-len(".meta.json")] + ".jsonl"):
        r = json.loads(line)
        if r.get("type") == "assistant":
            models.add((r.get("message") or {}).get("model")); efforts.add(r.get("effort"))
    print(at, ",".join(sorted(str(m) for m in models)), ",".join(sorted(str(e) for e in efforts)))
PY
}
has() { workers "$1" | grep -qx "$2"; }

# A1 + A3: two effort-capped Sonnet workers under a Haiku parent (which records no effort)
run a haiku "" 0 'Call the Agent tool twice, one after the other: first with subagent_type "w-low" and the prompt "Run the Bash command: echo A-low", then with subagent_type "w-xhigh" and the prompt "Run the Bash command: echo A-xhigh". Reply with both outputs.'
if has a "w-low claude-sonnet-5 low" && has a "w-xhigh claude-sonnet-5 xhigh"
then echo "PASS A1+A3: each definition's model (sonnet) and effort (low, xhigh) is what its worker ran at"
else echo "FAIL A1+A3: workers seen: $(workers a | tr '\n' ';')"; fail=1; fi

# A4: no effort line inherits the parent's effort, both directions
run b sonnet low 0 'Call the Agent tool with subagent_type "w-noeff" and the prompt "Run the Bash command: echo B". Reply with its output.'
run c sonnet xhigh 0 'Call the Agent tool with subagent_type "w-noeff" and the prompt "Run the Bash command: echo C". Reply with its output.'
if has b "w-noeff claude-sonnet-5 low" && has c "w-noeff claude-sonnet-5 xhigh"
then echo "PASS A4: a definition with no effort line ran at the PARENT's effort (low under low, xhigh under xhigh)"
else echo "FAIL A4: under low: $(workers b | tr '\n' ';') under xhigh: $(workers c | tr '\n' ';')"; fail=1; fi

# A2: the orchestrator's model parameter beats the definition (w-ro says haiku)
run d haiku "" 0 'Call the Agent tool with subagent_type "w-ro", the model parameter set to "sonnet", and the prompt "What is 2+2? Reply with the number only." Reply with its answer.'
if workers d | grep -q '^w-ro claude-sonnet-5 '
then echo "PASS A2: a model override on the Agent call ran the haiku-defined worker on sonnet (the call beats the definition)"
else echo "FAIL A2: workers seen: $(workers d | tr '\n' ';')"; fail=1; fi

# A5 + A5c: the tools list binds, with its must-fire leg
rm -f RO_MARKER RW_MARKER
run e haiku "" 0 'Call the Agent tool with subagent_type "w-ro" and the prompt "Create a file named RO_MARKER in the current directory containing the word x, by any means you have." Reply with what it said.'
run f haiku "" 0 'Call the Agent tool with subagent_type "w-rw" and the prompt "Create a file named RW_MARKER in the current directory containing the word x, with the Write tool." Reply with what it said.'
if [ ! -e RO_MARKER ] && [ -e RW_MARKER ]
then echo "PASS A5: the read-only worker could not create its file; A5c: the worker given Write, same ask, did (the marker can fire)"
else echo "FAIL A5: RO_MARKER $( [ -e RO_MARKER ] && echo PRESENT || echo absent), RW_MARKER $( [ -e RW_MARKER ] && echo present || echo ABSENT)"; fail=1; fi

# A6 + A7: a frontmatter hooks: block (does it fire?), and what a PROJECT hook sees of a
# worker's calls vs the orchestrator's
rm -f HOOK_MARKER scoped_hook.log
run g haiku "" 0 'First call the Agent tool with subagent_type "w-hooked" and the prompt "Run the Bash command: touch HOOK_MARKER". Then run the Bash command "echo main-bash" yourself. Reply briefly.'
if [ -e HOOK_MARKER ] && [ ! -e scoped_hook.log ]
then echo "PASS A6: the definition's own hooks: block did NOT fire (no log) and the command it should have denied ran (HOOK_MARKER)"
else echo "FAIL A6: scoped hook log $( [ -e scoped_hook.log ] && echo PRESENT || echo absent), HOOK_MARKER $( [ -e HOOK_MARKER ] && echo present || echo absent) — the frontmatter-hook behaviour changed"; fail=1; fi
a7=$(python3 - "$S/log_g.jsonl" <<'PY'
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1])]
sub = [r for r in rows if r["tool"] == "Bash" and r["agent_type"] == "w-hooked" and r["agent_id"]]
main = [r for r in rows if r["tool"] == "Bash" and "main-bash" in json.dumps(r["input"]) and not r["agent_type"] and not r["agent_id"]]
print(len(sub), len(main))
PY
)
case "$a7" in
  "0 "*|*" 0"|"") echo "FAIL A7: worker/orchestrator Bash rows named as expected: ${a7:-none}"; fail=1;;
  *) echo "PASS A7: the project hook saw the worker's Bash call with agent_type=w-hooked and an agent_id, and the orchestrator's with neither ($a7)";;
esac

# A8 + A8c: a project hook on Agent refuses a model override and lets the plain call run
run h haiku "" 1 'Call the Agent tool with subagent_type "w-ro", the model parameter set to "sonnet", and the prompt "What is 2+2?". If the call is refused, reply with the refusal text verbatim and do not retry.'
run i haiku "" 1 'Call the Agent tool with subagent_type "w-ro" and no model parameter, with the prompt "What is 2+2? Reply with the number only." Reply with its answer.'
den=$(python3 -c "import json;print(len(json.load(open('out_h.json')).get('permission_denials') or []))" 2>/dev/null)
if [ "${den:-0}" -ge 1 ] && [ -z "$(workers h)" ] && workers i | grep -q '^w-ro claude-haiku'
then echo "PASS A8: the Agent gate refused the model override ($den denial, no worker ran); A8c: the call without one ran on the definition's haiku"
else echo "FAIL A8: denials ${den:-?}, workers with override: $(workers h | tr '\n' ';') without: $(workers i | tr '\n' ';')"; fail=1; fi

# A6c: the A6 hook command, wired as a PROJECT hook, fires and denies the same worker call
rm -f HOOK_MARKER scoped_hook.log
PROBE_SCOPED=1 run g2 haiku "" 0 'Call the Agent tool with subagent_type "w-hooked" and the prompt "Run the Bash command: touch HOOK_MARKER". Reply with what it reported.'
if [ -e scoped_hook.log ] && [ ! -e HOOK_MARKER ]
then echo "PASS A6c: the same hook command wired as a project hook fired (log) and its deny held (no HOOK_MARKER) — A6's silence is the frontmatter, not the command"
else echo "FAIL A6c: scoped hook log $( [ -e scoped_hook.log ] && echo present || echo ABSENT), HOOK_MARKER $( [ -e HOOK_MARKER ] && echo PRESENT || echo absent)"; fail=1; fi

# A9: no model line, and a general-purpose call with no model, follow the caller's model
run j haiku "" 0 'Call the Agent tool twice, one after the other, with no model parameter either time: first with subagent_type "w-nomodel" and the prompt "Run the Bash command: echo J1", then with subagent_type "general-purpose" and the prompt "Reply with exactly: J2". Reply with both outputs.'
run k sonnet "" 0 'Call the Agent tool with subagent_type "w-nomodel", no model parameter, and the prompt "Run the Bash command: echo K". Reply with its output.'
if workers j | grep -q '^w-nomodel claude-haiku' && workers j | grep -q '^general-purpose claude-haiku' && workers k | grep -q '^w-nomodel claude-sonnet'
then echo "PASS A9: a definition with no model ran on the caller's (haiku under haiku, sonnet under sonnet), and so did a general-purpose call with no model"
else echo "FAIL A9: under haiku: $(workers j | tr '\n' ';') under sonnet: $(workers k | tr '\n' ';')"; fail=1; fi

# A10: spec, link, commands and report, read from run a's transcripts (w-low ran `echo A-low`)
a10=$(python3 - "$S/log_a.jsonl" <<'PY'
import glob, json, sys
t = next(json.loads(l)["transcript"] for l in open(sys.argv[1]))
calls, main_text, main_bash = {}, [], []
for line in open(t):
    r = json.loads(line)
    c = (r.get("message") or {}).get("content")
    blobs = [r.get("attachment") or {}] + (c if isinstance(c, list) else [c])
    for b in blobs:
        if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") in ("Agent", "Task"):
            calls[b["id"]] = (b.get("input") or {}).get("prompt", "")
        if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "Bash":
            main_bash.append(json.dumps(b.get("input")))
        if r.get("type") in ("user", "attachment"):
            main_text.append(json.dumps(b))
ok = []
for meta in glob.glob(t[:-len(".jsonl")] + "/subagents/*.meta.json"):
    m = json.load(open(meta))
    if m.get("agentType") != "w-low":
        continue
    spec = calls.get(m.get("toolUseId"), "")
    wbash, report = [], ""
    for line in open(meta[:-len(".meta.json")] + ".jsonl"):
        r = json.loads(line)
        c = (r.get("message") or {}).get("content")
        for b in c if isinstance(c, list) else []:
            if b.get("type") == "tool_use" and b.get("name") == "Bash":
                wbash.append(json.dumps(b.get("input")))
            if r.get("type") == "assistant" and b.get("type") == "text":
                report = b.get("text", "")
    ok.append(("echo A-low" in spec, any("A-low" in x for x in wbash),
               not any("A-low" in x for x in main_bash),
               bool(report.strip()) and any(report.strip()[:40] in x or "A-low" in x for x in main_text)))
print(" ".join("1" if all(o) else "0" for o in ok) or "none")
PY
)
if [ "$a10" = 1 ]
then echo "PASS A10: w-low's spec is the Agent call's prompt, its transcript links to that call by toolUseId, its Bash call is in its own transcript and not the orchestrator's, and its report reached the orchestrator's transcript"
else echo "FAIL A10: linkage checks ${a10:-none} (spec/link, worker command, not in main, report delivered)"; fail=1; fi

echo "scratch: $S"
exit $fail
