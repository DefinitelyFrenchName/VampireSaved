#!/bin/sh
# probe_hooks.sh — measure the three Claude Code mechanisms the #172 design rests on,
# in a THROWAWAY scratch project (never this tree's .claude/), with a headless
# `claude -p` on Haiku (GitHub #172; docs/project/agent_architecture_scope.md §2):
#
#   P1  a PreToolUse hook DENIES a detached Bash launch, the agent sees the reason, and
#       the denied command NEVER RAN (the marker file it would create is absent);
#       P1c, its must-fire leg: the same prompt with the deny switched off DOES create it
#   P2  a Stop hook BLOCKS the end of a turn once, and `stop_hook_active` releases it
#   P4  the must-stay-quiet control: the P1/P2 counts read zero on the P3 run
#   P3  a run_in_background launch is recorded in the transcript with its task id
#       and output path — and a HEADLESS run ends with the task still running
#
#   P5  (PROBE_MODELS="id id ...") each named model answers a one-line probe
#
# Usage: [PROBE_MODELS="claude-fable-5-1 ..."] tools/agent/probe_hooks.sh [SCRATCH_DIR]
#        (~1 min: four short Haiku runs, plus one per PROBE_MODELS entry)
# Prints one PASS/FAIL line per probe and exits non-zero on any FAIL.
# Needs: the `claude` CLI and python3. Writes only under SCRATCH_DIR (default: a mktemp dir).
set -u
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/hookprobe.XXXXXX")}
rm -rf "$S"; mkdir -p "$S/.claude" "$S/hooks" || exit 2
cd "$S" || exit 2
git init -q . 2>/dev/null

cat > hooks/pre_bash.py <<'EOF'
import json, re, sys
import os
d = json.load(sys.stdin)
if os.environ.get('PROBE_DENY', '1') == '1' and re.search(r'\bnohup\b|&\s*$|&\s*(echo|;)', d.get('tool_input', {}).get('command', '')):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
        "permissionDecisionReason": "PROBE-DENY: detached launch refused; use run_in_background instead"}}))
EOF
cat > hooks/stop.py <<'EOF'
import json, os, sys
d = json.load(sys.stdin)
open('stop.log', 'a').write(json.dumps(d) + "\n")
if os.environ.get('PROBE_BLOCK') == '1' and not d.get('stop_hook_active'):
    print(json.dumps({"decision": "block", "reason": "PROBE-STOP: before stopping, say the word PINEAPPLE"}))
EOF
cat > .claude/settings.json <<EOF
{"hooks": {
 "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "PROBE_DENY=\$PROBE_DENY python3 $S/hooks/pre_bash.py"}]}],
 "Stop": [{"hooks": [{"type": "command", "command": "PROBE_BLOCK=\$PROBE_BLOCK python3 $S/hooks/stop.py"}]}]
}}
EOF

fail=0
transcript() { python3 -c "import json;print(json.loads(open('stop.log').readline())['transcript_path'])"; }
# count_rec TRANSCRIPT KIND TEXT — records of KIND (user-str | tool-result) whose content
# contains TEXT. Never a bare grep: the transcript embeds the system-prompt snapshot, which
# names these strings (a grep for task-notification matched a run that received none).
count_rec() {
python3 - "$1" "$2" "$3" <<'PY'
import json, sys
path, kind, text = sys.argv[1:4]
n = 0
for line in open(path):
    r = json.loads(line)
    if r.get("type") != "user":
        continue
    c = (r.get("message") or {}).get("content")
    if kind == "user-str" and isinstance(c, str) and c.lstrip().startswith(text):
        n += 1
    elif kind == "tool-result" and isinstance(c, list):
        n += sum(1 for b in c if b.get("type") == "tool_result" and text in json.dumps(b.get("content")))
print(n)
PY
}

# P1 + P2 in one run: a detached launch (denied), then a blocked stop.
rm -f stop.log P1_MARKER
PROBE_DENY=1 PROBE_BLOCK=1 claude -p 'Use the Bash tool to run exactly this command: nohup touch P1_MARKER & echo launched
Then, whatever happened, reply with one short sentence describing what the tool returned.' \
  --model haiku --allowedTools Bash --output-format json </dev/null >run1.json 2>run1.err
T=$(transcript 2>/dev/null)
sleep 2
if [ -n "$T" ] && [ "$(count_rec "$T" tool-result PROBE-DENY)" -ge 1 ] && [ ! -e P1_MARKER ]
then echo "PASS P1: the detached launch was denied, the reason reached the agent, and the command never ran (no P1_MARKER)"
else echo "FAIL P1: denial record $(count_rec "$T" tool-result PROBE-DENY 2>/dev/null), P1_MARKER $( [ -e P1_MARKER ] && echo PRESENT || echo absent)"; fail=1; fi
nstop=$(wc -l < stop.log 2>/dev/null | tr -d ' ')
if [ -n "$T" ] && [ "$(count_rec "$T" user-str 'Stop hook feedback')" -ge 1 ] && [ "${nstop:-0}" -ge 2 ] && grep -q '"stop_hook_active": true' stop.log
then echo "PASS P2: the Stop hook blocked once (feedback in the transcript) and stop_hook_active released it ($nstop stops)"
else echo "FAIL P2: stops=$nstop, feedback/stop_hook_active not both seen"; fail=1; fi

# P1c, the must-fire leg of P1's "never ran": the deny switched off, the same command
# must create the marker — otherwise an absent marker proves nothing.
rm -f stop.log P1_MARKER
PROBE_DENY=0 PROBE_BLOCK=0 claude -p 'Use the Bash tool to run exactly this command: nohup touch P1_MARKER & echo launched
Then reply with one short sentence describing what the tool returned.' \
  --model haiku --allowedTools Bash --output-format json </dev/null >run1c.json 2>run1c.err
sleep 2
if [ -e P1_MARKER ]; then echo "PASS P1c: with the deny off, the same command created P1_MARKER (the marker can fire)"
else echo "FAIL P1c: the marker never appeared without the deny — P1's 'never ran' is unproven"; fail=1; fi
rm -f P1_MARKER

# P3: a tracked background launch, headless.
rm -f stop.log
PROBE_BLOCK=0 claude -p 'Use the Bash tool with run_in_background set to true to run: sleep 20; echo FINISHED-MARKER
Then wait for it to complete (you will be notified), read its output, and reply with the output.' \
  --model haiku --allowedTools Bash --output-format json </dev/null >run2.json 2>run2.err
T=$(transcript 2>/dev/null)
dur=$(python3 -c "import json;print(json.load(open('run2.json')).get('duration_ms'))" 2>/dev/null)
if [ -n "$T" ] && [ "$(count_rec "$T" tool-result 'Command running in background with ID: ')" -ge 1 ] && [ "$(count_rec "$T" tool-result '/tasks/')" -ge 1 ]
then echo "PASS P3a: the tracked launch is recorded with its task id and output path"
else echo "FAIL P3a: no 'running in background with ID' record"; fail=1; fi
notif=$(count_rec "$T" user-str '<task-notification>')
if [ -n "$T" ] && [ "${notif:-1}" = 0 ] && [ "${dur:-99999}" -lt 20000 ]
then echo "PASS P3b: the headless run ended after ${dur} ms with the 20 s task still running (no notification received)"
else echo "FAIL P3b: duration ${dur} ms or a notification was received — the headless-exit behaviour changed"; fail=1; fi

# the must-stay-quiet control: the P3 run denied nothing and blocked nothing, so the
# record counts that PASSED P1 and P2 must read ZERO on its transcript — a count that
# matched the embedded prompt, or any record regardless of content, would fail here.
if [ -n "$T" ] && [ "$(count_rec "$T" tool-result PROBE-DENY)" = 0 ] && [ "$(count_rec "$T" user-str 'Stop hook feedback')" = 0 ]
then echo "PASS P4: the P1/P2 record counts read zero on a run with no denial and no block (the counters are not blind)"
else echo "FAIL P4: a P1/P2 marker counted on a run that had none — the counter matches something other than the event"; fail=1; fi

# P5: model reachability, one one-line probe per id named in PROBE_MODELS.
for m in ${PROBE_MODELS:-}; do
  claude -p 'Reply with exactly: OK' --model "$m" --output-format json </dev/null >"model_$m.json" 2>"model_$m.err"
  got=$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(d.get('is_error'), repr(d.get('result')), list((d.get('modelUsage') or {}).keys()))" "model_$m.json" 2>/dev/null)
  case "$got" in
    "False 'OK' ['$m']") echo "PASS P5: $m answered ($got)";;
    *) echo "FAIL P5: $m -> ${got:-no answer} $(head -c 160 "model_$m.err")"; fail=1;;
  esac
done

echo "scratch: $S"
exit $fail
