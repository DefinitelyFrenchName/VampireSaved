#!/usr/bin/env python3
"""pre_push.py — C1's BINDING (GitHub #172 slice S3): no push without a procedure check.
A Claude Code PreToolUse hook on Bash (to be wired in `.claude/settings.json` beside
`pre_bash.py`; spec `docs/project/rule_checker.md` "THE PROCEDURE FAMILY").

It DENIES a Bash call that runs `git push` unless `tests/rulecheck/ledger.tsv` holds a
`procedure` run that PASSED (verdict OK) or was VIOLATED and RESOLVED in writing, whose
checked commit (`head` in its run dir's `meta.tsv`) lies inside the range being pushed
(`git rev-list @{upstream}..HEAD`, falling back to `origin/main..HEAD`). Nothing to push
is allowed. Ruled 2026-09-23 (14z-175): *"Every push + every close"*, and a block binds
the task at fault, never the session — the reason names what to run, the rest of the work
goes on, and the push waits until the check is green or resolved.

INSTALLED 2026-09-23 (14z-176b) by the maintainer; tools/agent/hooks/** and the settings are
edit-locked. Its cases are tests/lib/pre_push_cases.py, run by tests/test_agent_hooks.sh
(18 cases, control open-push-hook).

FAIL-OPEN BY DESIGN, like pre_bash.py: an internal error allows the call and is logged to
`build/agent_hooks/errors.log`.
"""
import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

_PUSH = re.compile(r"\bgit\b(?:\s+-C\s+\S+|\s+-c\s+\S+)*\s+push\b")

HOW = ("Run the procedure check first: `python3 tools/agent/extract.py --session <this session's id> "
       "--out build/agent172/extract_<id>.txt`, then `python3 tools/rulecheck.py prepare --decision "
       "procedure --subject ... --claim ... --artifact build/agent172/extract_<id>.txt --model <model> "
       "--id <id>`, spawn the two fresh readers, `record`, and `resolve` any VIOLATED question by "
       "question. The rest of the work can go on; only the push waits.")


_C_DIR = re.compile(r"\bgit\b(?:\s+-c\s+\S+)*\s+-C\s+(\S+)(?:\s+-c\s+\S+)*\s+push\b")
_CD = re.compile(r"(?:^|[;&|\n]\s*)cd\s+([^\s;&|]+)")


def push_body(cmd):
    """-> the command with heredoc bodies dropped and quoted strings blanked, if it pushes."""
    import agentlib
    body = agentlib._QUOTED.sub("''", agentlib.strip_heredocs(cmd))
    return body if _PUSH.search(body) else None


def push_target(cmd, body, cwd):
    """The directory the push runs in: `git -C <dir> push`, else the last `cd <dir>` before
    the push, else the shell's working directory. Paths are read from the RAW command
    (quoted paths are blanked in the body) at the positions the body's match gives."""
    m = _C_DIR.search(body)
    if m:
        d = cmd[m.start(1):m.end(1)].strip("'\"")
        return os.path.expanduser(d) if os.path.isabs(os.path.expanduser(d)) else os.path.join(cwd, d)
    p = _PUSH.search(body)
    cds = [c for c in _CD.finditer(body) if c.start() < p.start()]
    if cds:
        d = cmd[cds[-1].start(1):cds[-1].end(1)].strip("'\"")
        d = os.path.expanduser(d)
        return d if os.path.isabs(d) else os.path.join(cwd, d)
    return cwd


def same_repo(a, b):
    ra, rb = git(a, "rev-parse", "--show-toplevel"), git(b, "rev-parse", "--show-toplevel")
    return ra[0] == 0 and rb[0] == 0 and os.path.realpath(ra[1]) == os.path.realpath(rb[1])


def git(root, *args):
    p = subprocess.run(["git", "-C", root, *args], capture_output=True, text=True)
    return p.returncode, p.stdout.strip()


def pushed_range(root):
    for base in ("@{upstream}", "origin/main"):
        rc, out = git(root, "rev-list", f"{base}..HEAD")
        if rc == 0:
            return set(out.split()) if out else set()
    return None


def passing_heads(root):
    """Commits checked by a procedure run that passed, or was violated and resolved."""
    heads = set()
    ledger = os.path.join(root, "tests", "rulecheck", "ledger.tsv")
    cols = ("id", "date", "session", "decision", "subject", "control",
            "control_verdict", "verdict", "violated", "resolution", "model")
    for ln in open(ledger, encoding="utf-8"):
        if ln.startswith("#") or ln.startswith("id\t") or not ln.strip():
            continue
        r = dict(zip(cols, ln.rstrip("\n").split("\t")))
        if r.get("decision") != "procedure" or r.get("control_verdict") != "CAUGHT":
            continue
        if not (r.get("verdict") == "OK" or (r.get("verdict") == "VIOLATED" and r.get("resolution", "-") != "-")):
            continue
        meta = os.path.join(root, "tests", "rulecheck", "runs", r["id"], "meta.tsv")
        try:
            for m in open(meta, encoding="utf-8"):
                if m.startswith("head\t"):
                    heads.add(m.split("\t", 1)[1].strip())
        except OSError:
            continue
    return heads


def decide(event, root):
    if event.get("tool_name") != "Bash":
        return None, None
    cmd = str((event.get("tool_input") or {}).get("command", ""))
    body = push_body(cmd)
    if body is None:
        return None, None
    # ONLY a push of THIS repository is bound: the bbh harness and the jtcores fork are
    # pushed from the same shell under their own authorisations, and judging them by this
    # repo's range would refuse them whenever this repo held an unchecked commit (found by
    # prove.py before installation, 14z-176)
    target = push_target(cmd, body, event.get("cwd") or root)
    if not same_repo(target, root):
        return None, None
    rng = pushed_range(root)
    if rng is None:
        return "deny", f"C1 (#172, no push without a procedure check): the range being pushed could not be read. {HOW}"
    if not rng:
        return None, None  # nothing to push
    if passing_heads(root) & rng:
        return None, None
    return "deny", (f"C1 (#172, no push without a procedure check): none of the {len(rng)} commit(s) being "
                    f"pushed was checked by a passed or resolved `procedure` run. {HOW}")


def main():
    raw = sys.stdin.read()
    root = os.environ.get("CLAUDE_PROJECT_DIR") or os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
    try:
        decision, reason = decide(json.loads(raw), root)
    except Exception as e:  # fail open, but never silently
        try:
            d = os.path.join(root, "build", "agent_hooks")
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "errors.log"), "a") as f:
                f.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S')} pre_push {type(e).__name__}: {e}\n")
        except Exception:
            pass
        return 0
    if decision == "deny":
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                                 "permissionDecision": "deny",
                                                 "permissionDecisionReason": reason}}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
