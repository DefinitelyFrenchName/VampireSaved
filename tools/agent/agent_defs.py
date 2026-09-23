#!/usr/bin/env python3
"""agent_defs.py — the STATIC CAP CHECK on every worker definition (GitHub #172, slice S4).

Ruled 2026-09-23 (14z-177, `DECISIONS_HISTORY.md` "Ruled 2026-09-23 (14z-177)"): workers are
named definitions under `.claude/agents/`, at most Opus-class, effort at most `xhigh` (the
maintainer's #172 ask). MEASURED the same sitting (`tools/agent/probe_agents.sh`): a definition
with no `model` or no `effort` runs at its CALLER's (A9, A4) — which S5 makes Fable — and a
`hooks:` block in the frontmatter did not fire (A6). So every definition must STATE its caps, and
must not carry a key that reads as enforcement and is not. The call-side half (the Agent call's
`model` beats the definition's, A2) is the call gate's, not this tool's.

Each `<dir>/*.md` must have a frontmatter block (`---` ... `---`) with EXACTLY these keys:
  name         equal to the file's stem
  description  non-empty
  model        opus | sonnet | haiku, or a claude-(opus|sonnet|haiku)-<version> id
               (never omitted, never `inherit`, never Fable)
  effort       low | medium | high | xhigh   (never omitted, never `max`)
  tools        a comma-separated list, every entry in ALLOWED_TOOLS (never omitted: an omitted
               list grants every tool — documented, not measured)
Any other key (`hooks`, `permissionMode`, `disallowedTools`, `mcpServers`, ...) is refused: a
new key is a reviewed widening of this list, never a silent one. And every name in REQUIRED
must be present. The body (the worker's prompt) must be non-empty.

Usage:
  python3 tools/agent/agent_defs.py [DIR]      # default .claude/agents; exit 0 all OK, 1 any BAD
Prints one line per definition (OK / BAD <reasons>) and a count line. Stdlib only.
"""
import os
import re
import sys

KEYS = ("name", "description", "model", "effort", "tools")
MODELS = re.compile(r"^(opus|sonnet|haiku|claude-(opus|sonnet|haiku)-[0-9][0-9a-z.-]*)$")
EFFORTS = ("low", "medium", "high", "xhigh")
# the tools a worker may hold. No Write/Edit/NotebookEdit (a worker returns figures, it does not
# change the tree), no Agent/Task (a worker does not spawn workers — the call gate binds calls).
ALLOWED_TOOLS = ("Bash", "Read", "Grep", "Glob")
# the definitions the ruled order puts in step 1 (the pinned rule-checker joins at step 4)
REQUIRED = ("measurer", "reader")


def parse(path):
    """-> (keys: {key: value}, body, problems)"""
    lines = open(path, encoding="utf-8").read().split("\n")
    if not lines or lines[0].strip() != "---":
        return {}, "", ["no frontmatter block"]
    try:
        end = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration:
        return {}, "", ["unterminated frontmatter block"]
    keys, problems = {}, []
    for ln in lines[1:end]:
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        if ln[0] in " \t-":          # a nested line belongs to the key above it
            continue
        m = re.match(r"^([A-Za-z_][\w-]*)\s*:\s*(.*)$", ln)
        if not m:
            problems.append(f"unreadable frontmatter line {ln!r}")
            continue
        k, v = m.group(1), m.group(2).strip().strip("'\"")
        if k in keys:
            problems.append(f"key {k!r} twice")
        keys[k] = v
    return keys, "\n".join(lines[end + 1:]).strip(), problems


def check(path):
    keys, body, bad = parse(path)
    if not keys and bad:
        return bad
    stem = os.path.splitext(os.path.basename(path))[0]
    for k in keys:
        if k not in KEYS:
            bad.append(f"key {k!r} not allowed" + (" (a frontmatter hooks: block did not fire, probe_agents A6)" if k == "hooks" else ""))
    for k in KEYS:
        if k not in keys or not keys[k]:
            bad.append(f"{k} missing" + {"model": " (it would follow the caller's model, A9)",
                                         "effort": " (it would follow the caller's effort, A4)",
                                         "tools": " (an omitted list grants every tool)"}.get(k, ""))
    if keys.get("name") and keys["name"] != stem:
        bad.append(f"name {keys['name']!r} is not the file's stem {stem!r}")
    if keys.get("model") and not MODELS.match(keys["model"]):
        bad.append(f"model {keys['model']!r} is not Opus-class or below")
    if keys.get("effort") and keys["effort"] not in EFFORTS:
        bad.append(f"effort {keys['effort']!r} is not one of {'/'.join(EFFORTS)}")
    if keys.get("tools"):
        tools = [t.strip() for t in keys["tools"].split(",") if t.strip()]
        for t in tools:
            if t not in ALLOWED_TOOLS:
                bad.append(f"tool {t!r} not in {'/'.join(ALLOWED_TOOLS)}")
    if not body:
        bad.append("empty body (no prompt)")
    return bad


def main(argv):
    d = argv[1] if len(argv) > 1 else ".claude/agents"
    files = sorted(f for f in os.listdir(d) if f.endswith(".md")) if os.path.isdir(d) else []
    nbad = 0
    for f in files:
        bad = check(os.path.join(d, f))
        nbad += bool(bad)
        print(f"{'BAD' if bad else 'OK '} {f}" + (": " + "; ".join(bad) if bad else ""))
    names = {os.path.splitext(f)[0] for f in files}
    missing = [n for n in REQUIRED if n not in names]
    for n in missing:
        print(f"BAD {n}.md: required definition missing")
    # always a count line: an empty directory and a blind reader must not look alike
    print(f"definitions: {len(files)}, bad: {nbad + len(missing)}")
    return 1 if (nbad or missing or not files) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
