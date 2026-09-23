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
#       transcript (as the call's tool result, a `[Subagent hand-back]` record, or — since
#       2.1.281, where a headless run launches every worker in the BACKGROUND — the `<result>`
#       of the completion notification carrying THIS call's tool-use id; A10 FAILED on that
#       third form 14z-178 until the matcher learned it, and its "the spec did not supply the
#       token" check no longer counts a notification as the prompt)
#   A11 the SELF-CAPPED built-in the S4 call gate lets through with no model (`Explore`) stays at
#       most Opus-class under a caller ABOVE Opus-class (a Fable 5.1 parent), while
#       `general-purpose` under the same parent runs on Fable — the breach the gate refuses, and
#       the leg's proof that it can see one. Written 14z-177 after a first A11 (a Sonnet parent)
#       FAILED: `Explore` ran on the CALLER's Sonnet, so "it carries its own model" was wrong;
#       the archive fits "the caller's model, capped at Opus-class" (Opus 5 under Fable parents),
#       and the cap is the only property the gate needs. `claude-code-guide` is not available to
#       a headless run ("this agent type doesn't exist"), so it cannot be probed and is NOT
#       allowlisted — a call to it passes a model
#   A12 a definition run as the MAIN session (`claude -p --agent <name>`, the route a pinned
#       rule-checker reader could take — S4 step 4): its `model` and `tools` apply (the definition
#       without Write answers NO-TOOL; A12c, a copy WITH Write, creates its marker), but its
#       `effort` does NOT — the session runs at the settings' default (the definition says low,
#       the run is not low) — while an explicit `--effort low` pins it (added 14z-177; the
#       subagent route applies a definition's effort, A3)
#   A13 what project context a SUBAGENT sees (14z-178, S4 step 4's first act): a random codeword
#       in CLAUDE.md and one in the project's auto-memory index; the main session (the can-leg),
#       a rule-checker-shaped definition, the same with `omitClaudeMd: true`, general-purpose and
#       Explore (the cannot-leg), each read by its no-tool ANSWER against its instructions
#       ATTACHMENT — details at the leg
#   (A9 and A10 added after rule-checker run 2026-09-23-109 found both premises unmeasured;
#   run 2026-09-23-110 then found A10's delivery check VACUOUS — it matched the spec's own
#   token — A9's general-purpose half under one parent only, and A8 not asserting the prompt
#   a template check reads: A10 now uses an output token the spec cannot supply, matched only
#   against THIS call's result or hand-back, with a wrong-id control; A9 runs general-purpose
#   under both parents; A8 asserts the hook's input carries the call's prompt)
#
# Usage: tools/agent/probe_agents.sh [SCRATCH_DIR]   (~7 min: nineteen short runs, one on Fable 5.1)
# Prints one PASS/FAIL line per leg and exits non-zero on any FAIL.
# Needs: the `claude` CLI and python3. Writes only under SCRATCH_DIR (default: a mktemp dir), except
# A13's memory index, created under ~/.claude/projects/<the scratch project>/memory/ only if absent and
# deleted after the leg.
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
run a haiku "" 0 'Call the Agent tool twice, one after the other: first with subagent_type "w-low" and the prompt "Run the Bash command: echo LOW-$((6*7))", then with subagent_type "w-xhigh" and the prompt "Run the Bash command: echo A-xhigh". Reply with both outputs.'
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
a8p=$(python3 -c "
import json,sys
rows=[json.loads(l) for l in open(sys.argv[1]) if json.loads(l)['tool'] in ('Agent','Task')]
print(sum(1 for r in rows if '2+2' in str(r['input'].get('prompt','')) and r['input'].get('subagent_type')=='w-ro'))" "$S/log_i.jsonl" 2>/dev/null)
if [ "${den:-0}" -ge 1 ] && [ -z "$(workers h)" ] && workers i | grep -q '^w-ro claude-haiku' && [ "${a8p:-0}" -ge 1 ]
then echo "PASS A8: the Agent gate refused the model override ($den denial, no worker ran); A8c: the call without one ran on the definition's haiku; and the hook's input carried the call's prompt and subagent_type ($a8p row) — what a template check would read"
else echo "FAIL A8: denials ${den:-?}, workers with override: $(workers h | tr '\n' ';') without: $(workers i | tr '\n' ';')"; fail=1; fi

# A6c: the A6 hook command, wired as a PROJECT hook, fires and denies the same worker call
rm -f HOOK_MARKER scoped_hook.log
PROBE_SCOPED=1 run g2 haiku "" 0 'Call the Agent tool with subagent_type "w-hooked" and the prompt "Run the Bash command: touch HOOK_MARKER". Reply with what it reported.'
if [ -e scoped_hook.log ] && [ ! -e HOOK_MARKER ]
then echo "PASS A6c: the same hook command wired as a project hook fired (log) and its deny held (no HOOK_MARKER) — A6's silence is the frontmatter, not the command"
else echo "FAIL A6c: scoped hook log $( [ -e scoped_hook.log ] && echo present || echo ABSENT), HOOK_MARKER $( [ -e HOOK_MARKER ] && echo PRESENT || echo absent)"; fail=1; fi

# A9: no model line, and a general-purpose call with no model, follow the caller's model
run j haiku "" 0 'Call the Agent tool twice, one after the other, with no model parameter either time: first with subagent_type "w-nomodel" and the prompt "Run the Bash command: echo J1", then with subagent_type "general-purpose" and the prompt "Reply with exactly: J2". Reply with both outputs.'
run k sonnet "" 0 'Call the Agent tool twice, one after the other, with no model parameter either time: first with subagent_type "w-nomodel" and the prompt "Run the Bash command: echo K1", then with subagent_type "general-purpose" and the prompt "Reply with exactly: K2". Reply with both outputs.'
if workers j | grep -q '^w-nomodel claude-haiku' && workers j | grep -q '^general-purpose claude-haiku' && workers k | grep -q '^w-nomodel claude-sonnet' && workers k | grep -q '^general-purpose claude-sonnet'
then echo "PASS A9: with no model, a definition AND a general-purpose call each ran on the caller's model under BOTH parents (haiku under haiku, sonnet under sonnet)"
else echo "FAIL A9: under haiku: $(workers j | tr '\n' ';') under sonnet: $(workers k | tr '\n' ';')"; fail=1; fi

# A10: spec, link, commands and report, read from run a's transcripts (w-low ran `echo A-low`)
a10=$(python3 - "$S/log_a.jsonl" <<'PY'
# The worker ran `echo LOW-$((6*7))`: its output token LOW-42 is NOT in its spec nor in the
# orchestrator's prompt (asserted), so finding it in the orchestrator's transcript means the
# REPORT arrived. Delivery is matched only in a tool_result FOR THIS CALL's id or an
# <agent-message from="THIS AGENT"> record, never anywhere in the transcript (the first
# version matched the spec's own token and passed vacuously — rule-checker run 2026-09-23-110).
import glob, json, os, re, sys
TOKEN = "LOW-42"
t = next(json.loads(l)["transcript"] for l in open(sys.argv[1]))
recs = [json.loads(l) for l in open(t)]
calls, main_bash, prompt_has = {}, [], False
for r in recs:
    c = (r.get("message") or {}).get("content")
    # the orchestrator's PROMPT only — a <task-notification> is also a user string, and since
    # 2.1.281 one can carry the report itself (14z-178), which is delivery, not supply
    if r.get("type") == "user" and isinstance(c, str) and TOKEN in c and not c.lstrip().startswith("<task-notification>"):
        prompt_has = True
    for b in c if isinstance(c, list) else []:
        if b.get("type") == "tool_use" and b.get("name") in ("Agent", "Task"):
            calls[b["id"]] = (b.get("input") or {}).get("prompt", "")
        if b.get("type") == "tool_use" and b.get("name") == "Bash":
            main_bash.append(json.dumps(b.get("input")))
def delivered(call_id, agent_id):
    for r in recs:
        c = (r.get("message") or {}).get("content")
        for b in c if isinstance(c, list) else []:
            if b.get("type") == "tool_result" and b.get("tool_use_id") == call_id and TOKEN in json.dumps(b.get("content")):
                return "tool-result"
        texts = [c] if isinstance(c, str) else []
        texts += [str((r.get("attachment") or {}).get("prompt") or ""), str(r.get("content") or "")]
        for x in texts:
            if f'agent-message from="{agent_id}"' in x and TOKEN in x:
                return "hand-back"
            # the THIRD form (2.1.281, a background worker in a headless run, 14z-178): the report
            # is the <result> of the completion notification whose <tool-use-id> is THIS call's
            m = re.search(r"<tool-use-id>([^<]+)</tool-use-id>", x)
            res = re.search(r"<result>(.*?)</result>", x, re.S)
            if x.lstrip().startswith("<task-notification>") and m and m.group(1) == call_id and res and TOKEN in res.group(1):
                return "notification-result"
    return ""
out = []
for meta in glob.glob(t[:-len(".jsonl")] + "/subagents/*.meta.json"):
    m = json.load(open(meta))
    if m.get("agentType") != "w-low":
        continue
    aid = os.path.basename(meta)[len("agent-"):-len(".meta.json")]
    spec = calls.get(m.get("toolUseId"), "")
    wbash = []
    for line in open(meta[:-len(".meta.json")] + ".jsonl"):
        r = json.loads(line)
        c = (r.get("message") or {}).get("content")
        for b in c if isinstance(c, list) else []:
            if b.get("type") == "tool_use" and b.get("name") == "Bash":
                wbash.append(json.dumps(b.get("input")))
    form = delivered(m.get("toolUseId"), aid)
    wrong = delivered("toolu_not_this_call", "not-this-agent")   # the matcher's own control
    checks = ["LOW-" in spec and TOKEN not in spec and not prompt_has,  # the token is not supplied by the spec
              any("LOW-" in x for x in wbash),                          # the command ran in the worker
              not any("LOW-" in x for x in main_bash),                  # ... and not in the orchestrator
              bool(form), not wrong]                                    # delivered to THIS call; a wrong id finds nothing
    out.append(("1" if all(checks) else "0") + ":" + "".join("1" if c else "0" for c in checks) + ":" + (form or "none"))
print(" ".join(out) or "none")
PY
)
case "$a10" in
  1:*) a10ok=1;; *) a10ok=0;;
esac
if [ "$a10ok" = 1 ] && [ "$(echo "$a10" | wc -w | tr -d ' ')" = 1 ]
then echo "PASS A10: w-low's spec is the Agent call's prompt (linked by toolUseId) and does not contain its output token, its Bash call is in its own transcript and not the orchestrator's, and its REPORT (the token) reached the orchestrator's transcript for THIS call as ${a10##*:}; the matcher finds nothing for a wrong call id ($a10)"
else echo "FAIL A10: checks ${a10:-none} (token-not-in-spec, worker command, not in main, delivered to this call, wrong-id quiet : form)"; fail=1; fi

# A11: under a Fable parent, Explore (no model) stays at most Opus-class; general-purpose does not
run m claude-fable-5-1 "" 0 'Call the Agent tool twice, one after the other, with no model parameter either time: first with subagent_type "Explore" and the prompt "Reply with exactly: E11 (do not search anything)", then with subagent_type "general-purpose" and the prompt "Reply with exactly: G11". Reply with both answers.'
a11=$(workers m | python3 -c "
import re, sys
got = {}
for l in sys.stdin:
    r = l.split()
    if len(r) >= 2: got[r[0]] = r[1]
cap = re.compile(r'^claude-(opus|sonnet|haiku)-')
ex = got.get('Explore', ''); gp = got.get('general-purpose', '')
ok = bool(ex) and all(cap.match(m) for m in ex.split(',')) and 'fable' in gp
print(('1 ' if ok else '0 ') + f'Explore={ex or \"none\"};general-purpose={gp or \"none\"}')")
case "$a11" in
  1*) echo "PASS A11: under a Fable parent with no model, Explore stayed at most Opus-class while general-purpose ran on Fable (${a11#1 }) — the call gate's SELF_CAPPED list holds, and the leg sees the breach";;
  *)  echo "FAIL A11: ${a11:-no workers} — Explore ran above Opus-class under a Fable caller (the call gate's SELF_CAPPED list is stale), or general-purpose did not inherit Fable (the leg cannot see a breach)"; fail=1;;
esac

# A12: --agent runs a definition as the main session — model and tools apply, effort does not
defn m-rc sonnet low "Read, Glob, Grep"
defn m-rcw sonnet low "Read, Write"
echo hello > f12.txt
rm -f W12_MARKER W12C_MARKER
main() { # tag agent extra-args prompt   -> out_<tag>.json
  tag=$1 ag=$2 extra=$3; shift 3
  PROBE_LOG="$S/log_$tag.jsonl" PROBE_AGENT_GATE=0 PROBE_SCOPED=0 claude -p "$1" --agent "$ag" $extra \
    --allowedTools "Write Read" --output-format json </dev/null >"out_$tag.json" 2>"err_$tag.txt"
}
main n1 m-rc "" 'Create a file named W12_MARKER containing x with the Write tool; if you cannot, reply NO-TOOL. Then read f12.txt and reply with its contents.'
main n2 m-rcw "" 'Create a file named W12C_MARKER containing x with the Write tool; if you cannot, reply NO-TOOL.'
main n3 m-rc "--effort low" 'Reply with exactly: E12'
a12=$(python3 - "$S" <<'PY'
import glob, json, os, sys
S = sys.argv[1]
def run(tag):
    sid = json.load(open(f"{S}/out_{tag}.json")).get("session_id", "")
    hits = glob.glob(os.path.expanduser(f"~/.claude/projects/*/{sid}.jsonl")) if sid else []
    e, m = set(), set()
    for line in open(hits[0]) if hits else []:
        r = json.loads(line)
        if r.get("type") == "assistant":
            e.add(str(r.get("effort"))); m.add(str((r.get("message") or {}).get("model")))
    return e, m
e1, m1 = run("n1"); e3, m3 = run("n3")
checks = [bool(m1) and all(x.startswith("claude-sonnet") for x in m1),   # the definition's model
          not os.path.exists(f"{S}/W12_MARKER"),                         # its tools bind
          os.path.exists(f"{S}/W12C_MARKER"),                            # A12c: the Write copy can
          bool(e1) and "low" not in e1,                                  # its effort does NOT apply
          e3 == {"low"}]                                                 # --effort pins it
print(("1 " if all(checks) else "0 ") + "".join("1" if c else "0" for c in checks)
      + f" model={','.join(sorted(m1))} effort-without-flag={','.join(sorted(e1))} with-flag={','.join(sorted(e3))}")
PY
)
case "$a12" in
  1*) echo "PASS A12: --agent applied the definition's model and tools (no Write -> no marker; A12c: the Write copy created one) but NOT its effort, which an explicit --effort pinned (${a12#1 })";;
  *)  echo "FAIL A12: ${a12:-no result} (model, tools bind, can-write copy, effort not applied, --effort pins) — the --agent behaviour changed"; fail=1;;
esac

# A13: what project context does a SUBAGENT see — the project's CLAUDE.md, and the project's
# AUTO-MEMORY index? (S4 step 4's first act, ruled "Subagents", 14z-177; measured 14z-178.)
# Two RANDOM codewords no prompt contains — one in the scratch CLAUDE.md, one in the scratch
# project's own auto-memory index (`<its transcript dir>/memory/MEMORY.md`, located from an
# earlier leg's transcript path, never computed; created only if absent and DELETED after the
# leg — the one write this probe makes outside SCRATCH_DIR). A worker can name a codeword only
# if that file is in its context. Each is asked, WITHOUT a tool, for every CANARY- word it has.
# Two readings per worker: its ANSWER (its assistant records only — never the attachment record
# that carries the file) and the INSTRUCTIONS attachment in its transcript (which files it lists).
#   A13m  the main session — the can-leg: both files load at all, and both codewords are
#         answerable (if memory does not load here, the memory half is VOID, not "blind")
#   A13d  `w-rc`, shaped as the pinned rule-checker (Read, Grep, Glob; its own model)
#   A13o  `w-rco`, the same with `omitClaudeMd: true` (documented, v2.1.271+: "launch this
#         subagent without the user, project, and local CLAUDE.md files")
#   A13g  general-purpose with a model — the form every rule-checker reader has taken
#   A13e  Explore — the archive's cannot-leg (no instructions attachment on any archived run)
# A spec carrying a codeword (the orchestrator sees both files and could pass one on) or a
# worker that ran Read/Grep/Glob VOIDS the leg. The docs say "the main conversation's auto memory
# isn't loaded" in a non-fork subagent; the archive's 217 general-purpose attachments list
# MEMORY.md — this leg measures which is true, and asserts what it measured.
cmd="CANARY-C$(python3 -c 'import secrets; print(secrets.token_hex(5))')"
mem="CANARY-M$(python3 -c 'import secrets; print(secrets.token_hex(5))')"
printf 'Probe project notes.\nThe project codeword is %s.\n' "$cmd" > CLAUDE.md
memdir="$(dirname "$(python3 -c "import json,sys;print(json.loads(open(sys.argv[1]).readline())['transcript'])" "$S/log_a.jsonl")")/memory"
memmine=0
if [ ! -e "$memdir" ]; then
  mkdir -p "$memdir" && printf -- '- [Probe note](probe.md) — the memory codeword is %s\n' "$mem" > "$memdir/MEMORY.md" && memmine=1
fi
defn w-rc haiku high "Read, Glob, Grep"
defn w-rco haiku high "Read, Glob, Grep" "omitClaudeMd: true"
ASK='Without using ANY tool, answer from your context alone: list every word in your context (system prompt, instructions, attachments, memory) that begins with CANARY- . Reply with those words exactly, separated by spaces, and nothing else; if there are none, reply NONE.'
run pm haiku "" 0 "$ASK"
run pw haiku "" 0 "Call the Agent tool four times, one after the other, each time passing the prompt below VERBATIM and adding nothing to it: first with subagent_type \"w-rc\" and no model parameter, then with subagent_type \"w-rco\" and no model parameter, then with subagent_type \"general-purpose\" and the model parameter \"haiku\", then with subagent_type \"Explore\" and no model parameter. Reply with the four answers, one per line. The prompt: $ASK"
[ "$memmine" = 1 ] && rm -rf "$memdir"
a13=$(python3 - "$S" "$cmd" "$mem" "$memmine" <<'PY'
import glob, json, os, sys
S, cmd, mem, memmine = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
def said(recs):
    out = ""
    for r in recs:
        if r.get("type") != "assistant":
            continue
        c = (r.get("message") or {}).get("content")
        for b in c if isinstance(c, list) else [{"text": c}]:
            out += json.dumps(b.get("input")) if b.get("type") == "tool_use" else str(b.get("text") or "")
    return out
def reading(text):
    return ("C" if cmd in text else "-") + ("M" if mem in text else "-")
main = json.load(open(f"{S}/out_pm.json")).get("result", "")
t = next(json.loads(l)["transcript"] for l in open(f"{S}/log_pw.jsonl"))
specs = [json.dumps(json.loads(l)["input"]) for l in open(f"{S}/log_pw.jsonl") if json.loads(l)["tool"] in ("Agent", "Task")]
res = {"main": (reading(main), "-")}
for meta in glob.glob(t[:-len(".jsonl")] + "/subagents/*.meta.json"):
    at = json.load(open(meta)).get("agentType")
    recs = [json.loads(l) for l in open(meta[:-len(".meta.json")] + ".jsonl")]
    tools = [b.get("name") for r in recs if r.get("type") == "assistant"
             for b in ((r.get("message") or {}).get("content") or []) if isinstance(b, dict) and b.get("type") == "tool_use"]
    files = [os.path.basename(str(f.get("path"))) for r in recs if r.get("type") == "attachment"
             and (r.get("attachment") or {}).get("type") == "instructions" for f in (r["attachment"].get("files") or [])]
    att = ("C" if "CLAUDE.md" in files else "-") + ("M" if "MEMORY.md" in files else "-")
    res[at] = ("VOID" if any(n in ("Read", "Grep", "Glob") for n in tools) else reading(said(recs)), att)
leak = any(cmd in s or mem in s for s in specs)
# the can-leg must see CLAUDE.md; the memory half is judged only where the main session saw memory
mem_live = memmine and res["main"][0][1] == "M"
ok = not leak and res["main"][0][0] == "C" and res.get("Explore") == ("--", "--")
for k in ("w-rc", "w-rco", "general-purpose"):
    ans, att = res.get(k, ("", ""))
    ok = ok and ans not in ("", "VOID") and ans[0] == att[0] and (not mem_live or ans[1] == att[1])
print(("1 " if ok else "0 ") + ("SPEC-LEAK " if leak else "") + ("memory-live " if mem_live else "MEMORY-VOID ")
      + " ".join(f"{k}=answer:{v[0]}/attached:{v[1]}" for k, v in sorted(res.items())))
PY
)
case "$a13" in
  1*) echo "PASS A13: ${a13#1 } (C = the CLAUDE.md codeword, M = the memory codeword; answer = what the worker named with no tool, attached = what its instructions attachment listed) — the main session names CLAUDE.md's (the can-leg), Explore names nothing and carries nothing (the cannot-leg), and for w-rc, w-rco and general-purpose the answer agrees with the attachment";;
  *)  echo "FAIL A13: ${a13:-no result} (main must name C, Explore must be --/--, no spec may carry a codeword, no worker may read a file, and each worker's answer must agree with its attachment)"; fail=1;;
esac

echo "scratch: $S"
exit $fail
