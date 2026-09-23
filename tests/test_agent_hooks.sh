#!/bin/sh
# test_agent_hooks.sh — SLICE S1 OF GitHub #172: the agent-discipline hooks decide what
# the evidence says they should (docs/project/agent_architecture_scope.md, 2026-09-23).
#
# C0.1 (`tools/agent/hooks/pre_bash.py`) denies a Bash call that detaches a job the
# harness cannot track, or waits on `pgrep`. It is replayed here over a frozen fixture,
# `tests/agent/c01_commands.jsonl`, cut from real session transcripts: the TWELVE `nohup`
# launches of 14z-174 — every long job of the session whose idle gaps opened #172 — must
# be DENIED, and real commands the first census wrongly counted as detached (a `&` in a
# heredoc body or a quoted string, a foreground parallel run ending in `wait`, `&&`
# chains) must be ALLOWED, beside synthetic edge cases (the pgrep waiter, setsid, a
# PID-based `kill -0` waiter that must pass). The hook is driven exactly as Claude Code
# drives it: the PreToolUse event JSON on stdin, the decision JSON on stdout.
#
# Also: the hook FAILS OPEN on a malformed event (exit 0, no decision) and records the
# error, so a hook bug cannot stop a session but cannot hide either; and the census that
# justified the hook (`tools/agent/transcript_gaps.py --selftest`) shares its classifier.
#
# MUST-FIRE: perturbed-copy: blind-classifier — a copy of the hooks whose `detach_reason` always answers "no detach" must let the 14z-174 launches through, and the gate must FAIL on them (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: greedy-heredoc — a copy whose `strip_heredocs` swallows every line after an UNTERMINATED `<<` operator (the defect rule-checker run 2026-09-23-100 found) must hide the `nohup` in the arithmetic-shift rows, and the gate must FAIL on the must-deny side (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: no-heredoc-strip — a copy whose `strip_heredocs` returns the command unchanged must deny commands that only WRITE a script containing `&`, and the gate must FAIL on the must-allow side (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: open-push-hook — a copy of the C1 push hook (`pre_push.py`, slice S3) whose `decide` allows every call must let an unchecked push through, and the gate must FAIL on the must-deny push cases (mode: the gate drives that copy)
#
# SLICE S3's BINDING (installed by the maintainer 2026-09-23, 14z-176b): `pre_push.py`
# refuses a `git push` of THIS repository unless a passed or resolved `procedure` run of
# the rule-checker checked a commit in the pushed range. `tests/lib/pre_push_cases.py`
# drives it through 18 cases against a scratch repo — including pushes of ANOTHER
# repository from the same shell, which the proposal wrongly refused until those cases
# were added (14z-176b).
#
# Usage: tests/test_agent_hooks.sh      # ci_portable, ~4 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
FIX=tests/agent/c01_commands.jsonl

# make_copy <name> — a copy of tools/agent with ONE perturbation, for the controls
make_copy() {
    mkdir -p "$W/$1"; cp -R tools/agent "$W/$1/agent"
    case "$1" in
        blind-classifier)
            python3 - "$W/$1/agent/agentlib.py" <<'PY'
import sys; p = sys.argv[1]; s = open(p).read()
a = 'def detach_reason(cmd):\n'
assert s.count(a) == 1
s = s.replace(a, a + '    return None  # CONTROL blind-classifier\n', 1)
open(p, 'w').write(s)
PY
            ;;
        greedy-heredoc)
            python3 - "$W/$1/agent/agentlib.py" <<'PY'
import sys; p = sys.argv[1]; s = open(p).read()
a = '            if end is not None:\n                i = end + 1\n'
assert s.count(a) == 1
s = s.replace(a, '            i = end + 1 if end is not None else len(lines)  # CONTROL greedy-heredoc\n', 1)
open(p, 'w').write(s)
PY
            ;;
        no-heredoc-strip)
            python3 - "$W/$1/agent/agentlib.py" <<'PY'
import sys; p = sys.argv[1]; s = open(p).read()
a = 'def strip_heredocs(cmd):\n'
assert s.count(a) == 1
s = s.replace(a, a + '    return cmd  # CONTROL no-heredoc-strip\n', 1)
open(p, 'w').write(s)
PY
            ;;
        open-push-hook)
            python3 - "$W/$1/agent/hooks/pre_push.py" <<'PY'
import sys; p = sys.argv[1]; s = open(p).read()
a = 'def decide(event, root):\n'
assert s.count(a) == 1
s = s.replace(a, a + '    return None, None  # CONTROL open-push-hook\n', 1)
open(p, 'w').write(s)
PY
            ;;
    esac
    echo "$W/$1/agent"
}

# replay <agent dir> <out> — every fixture row through the hook, one line per mismatch
replay() {
    python3 - "$1/hooks/pre_bash.py" "$FIX" > "$2" <<'PY'
import json, subprocess, sys
hook, fix = sys.argv[1:3]
bad = n = 0
for line in open(fix):
    row = json.loads(line); n += 1
    ev = {"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": row["command"]}}
    p = subprocess.run([sys.executable, hook], input=json.dumps(ev), capture_output=True, text=True)
    got = "allow"
    if p.returncode != 0:
        got = f"exit{p.returncode}"
    elif p.stdout.strip():
        got = json.loads(p.stdout)["hookSpecificOutput"]["permissionDecision"]
    if got != row["expect"]:
        bad += 1
        print(f"MISMATCH expect={row['expect']} got={got} [{row['source']}] {row['why']} :: {' '.join(row['command'].split())[:90]}")
print(f"ROWS {n} MISMATCHES {bad}")
PY
}

echo "== test_agent_hooks: #172 slice S1 — C0.1 against its frozen fixture =="
fail=0
n_deny=$(grep -c '"expect": "deny"' "$FIX"); n_allow=$(grep -c '"expect": "allow"' "$FIX")
n_174=$(grep -c '"source": "d5b070d5:' "$FIX")
echo "  fixture: $n_deny must-deny ($n_174 of them the 14z-174 launches), $n_allow must-allow"
[ "$n_174" -eq 12 ] || { echo "FAIL: the fixture must carry the twelve 14z-174 launches (has $n_174)"; fail=1; }

AG=tools/agent
if vs_ctl_is blind-classifier || vs_ctl_is greedy-heredoc || vs_ctl_is no-heredoc-strip || vs_ctl_is open-push-hook; then AG="$(make_copy "$VS_CTL")"; fi
replay "$AG" "$W/replay.txt"
sed -n '/^MISMATCH/p' "$W/replay.txt" | head -12 | sed 's/^/  /'
tail -1 "$W/replay.txt" | sed 's/^/  /'
grep -q ' MISMATCHES 0$' "$W/replay.txt" || { echo "FAIL: the hook's decisions disagree with the fixture"; fail=1; }

# the fail-open path: a malformed event is allowed, and the error is recorded
E="$W/errroot"; mkdir -p "$E"
out="$(printf 'not json' | CLAUDE_PROJECT_DIR="$E" python3 "$AG/hooks/pre_bash.py")"; rc=$?
if [ "$rc" = 0 ] && [ -z "$out" ] && grep -q 'pre_bash JSONDecodeError' "$E/build/agent_hooks/errors.log" 2>/dev/null; then
    echo "  fail-open: a malformed event is allowed (exit 0, no decision) and recorded in build/agent_hooks/errors.log"
else
    echo "FAIL: the fail-open path (rc=$rc, out='$out', log $( [ -f "$E/build/agent_hooks/errors.log" ] && echo present || echo absent))"; fail=1
fi

# the INSTALLATION (ruled 2026-09-23, "Install + protect"): the tracked project settings
# must still wire this hook on Bash and keep the three edit-lock rules — a settings edit
# that drops either would otherwise switch the enforcement off with every gate green
python3 - .claude/settings.json > "$W/wiring.txt" <<'PY' || fail=1
import json, sys
try:
    s = json.load(open(sys.argv[1]))
except Exception as e:
    print(f"FAIL: .claude/settings.json unreadable ({e})"); sys.exit(1)
cmds = [h.get("command", "") for m in s.get("hooks", {}).get("PreToolUse", []) if m.get("matcher") == "Bash"
        for h in m.get("hooks", []) if h.get("type") == "command"]
deny = set(s.get("permissions", {}).get("deny", []))
need = {"Edit(.claude/settings.json)", "Edit(tools/agent/hooks/**)", "Edit(tools/agent/agentlib.py)"}
bad = []
if not any("tools/agent/hooks/pre_bash.py" in c for c in cmds):
    bad.append("no PreToolUse Bash hook runs tools/agent/hooks/pre_bash.py")
if not any("tools/agent/hooks/pre_push.py" in c for c in cmds):
    bad.append("no PreToolUse Bash hook runs tools/agent/hooks/pre_push.py (C1's push binding)")
if need - deny:
    bad.append(f"edit-lock rules missing: {sorted(need - deny)}")
for b in bad:
    print(f"FAIL: installation — {b}")
if not bad:
    print("  installation: .claude/settings.json wires pre_bash.py and pre_push.py on Bash and keeps the three edit-lock rules")
sys.exit(1 if bad else 0)
PY
cat "$W/wiring.txt"

# C1's push hook over its 18 cases (the installed hook, or the control's perturbed copy)
python3 tests/lib/pre_push_cases.py "$AG/hooks/pre_push.py" > "$W/push.txt" 2>&1 || true
sed -n '/^  BAD /p' "$W/push.txt" | head -8
tail -1 "$W/push.txt" | sed 's/^/  push hook: /'
grep -q -- '-> PASS$' "$W/push.txt" || { echo "FAIL: the push hook's decisions disagree with its cases"; fail=1; }

# the census shares the classifier and its own selftest must hold
python3 tools/agent/transcript_gaps.py --selftest | sed 's/^/  /'
python3 tools/agent/transcript_gaps.py --selftest | grep -q 'PASS$' || { echo "FAIL: transcript_gaps selftest"; fail=1; }

# the controls, in-gate: each perturbed copy must produce mismatches on ITS side
if [ -z "${VS_CTL:-}" ]; then
    python3 tests/lib/pre_push_cases.py "$(make_copy open-push-hook)/hooks/pre_push.py" > "$W/ctl_push.txt" 2>&1 || true
    k=$(grep -c '^  BAD .*expect deny' "$W/ctl_push.txt" || true)
    if [ "${k:-0}" -gt 0 ]; then vs_ctl_fired open-push-hook "$k must-deny push cases let through by the perturbed copy"
    else vs_ctl_dead open-push-hook "the always-allow copy matched every push case — the cases cannot see an open hook" || fail=1; fi
    for c in blind-classifier greedy-heredoc no-heredoc-strip; do
        replay "$(make_copy "$c")" "$W/ctl_$c.txt"
        case "$c" in blind-classifier|greedy-heredoc) side=deny;; no-heredoc-strip) side=allow;; esac
        k=$(grep -c "^MISMATCH expect=$side " "$W/ctl_$c.txt" || true)
        if [ "${k:-0}" -gt 0 ]; then vs_ctl_fired "$c" "$k must-$side rows mismatched on the perturbed copy"
        else vs_ctl_dead "$c" "the perturbed copy matched every must-$side row — the replay cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: C0.1 denies the 14z-174 launches and every must-deny case, allows every must-allow case, and fails open on a malformed event; C1's push hook decides all 18 of its cases"
else echo "FAIL: test_agent_hooks"; exit 1; fi
