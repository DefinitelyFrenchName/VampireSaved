#!/usr/bin/env python3
"""close_loop_cost.py — what a close's checking loop cost, read from the session transcript.

Written 14z-185b from the 14z-185 close (the figures of the re-run tickets); promoted
from build/agent185b/loop_cost.py so the figures those tickets quote stay reproducible.

Usage: python3 tools/agent/close_loop_cost.py <transcript.jsonl> [--script NAME]
         [--first-run N] [--last-run N] [--figure WORD] [--plant]
  --script NAME   the check runner whose executions are counted: a basename, or the
                  repo-relative path it is run by (default run_checks.sh)
  --first-run N / --last-run N   rule-checker run numbers bounding the packet's span
                  (the first `prepare` result naming -N, the last `record` call naming -M)
  --figure WORD   the volatile count followed, as "<n> WORD" (default: untracked)

Prints, each figure on its own line:
  (1) every EXECUTION of the runner (a Bash call that runs it with sh/bash or by path,
      foreground or background), its start and seconds; a background run (asked for, or
      moved there by the tool's timeout) ends at its completed task-notification; a pass
      whose own command edits a "<n> WORD" figure is flagged EDITS-COUNT;
  (2) the packet's span, when both run numbers are given;
  (3) every distinct "<n> WORD" figure in tool inputs and texts, in first-seen order.
--plant: adds a synthetic runner call of known 600 s duration and an edit that only
  MENTIONS the runner; the run must be counted with 600 s and the mention not at all
  (exit 0 CAUGHT, 1 MISSED).
"""
import json, re, sys
from datetime import datetime

def arg(name, default=None):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default


# --script is a basename or a repo-relative path. A path is matched LITERALLY when run by
# path (a bare `\S*/name` pattern also matched prose inside heredocs: a 1 s false run,
# found 14z-185b); either form is matched by basename when run through sh/bash.
_S = arg("--script", "run_checks.sh")
_BASE = re.escape(_S.rsplit("/", 1)[-1])
EXEC = re.compile(r'(?:^|[;&|(]\s*|&&\s*|\s)(?:sh|bash)\s+(?:\S*/)?' + _BASE + r'|(?:^|[;&|]\s*)(?:\./)?'
                  + (re.escape(_S) if "/" in _S else r'\./' + _BASE))
UNTR = re.compile(r'(\d,?\d{3}) ' + re.escape(arg("--figure", "untracked")))
FIRST, LAST = arg("--first-run"), arg("--last-run")


def ts(r):
    return datetime.fromisoformat(r["timestamp"].replace("Z", "+00:00"))


def texts(content):
    if isinstance(content, str):
        yield content
    elif isinstance(content, list):
        for c in content:
            if isinstance(c, dict):
                if c.get("type") == "text":
                    yield c.get("text", "")
                elif c.get("type") == "tool_result":
                    yield from texts(c.get("content"))


def main():
    path = sys.argv[1]
    plant = "--plant" in sys.argv
    recs = []
    for line in open(path, encoding="utf-8"):
        try:
            r = json.loads(line)
        except ValueError:
            continue
        if "timestamp" in r:
            recs.append(r)
    if plant:
        t0 = "2030-01-01T00:00:00Z"
        recs += [
            {"type": "assistant", "timestamp": t0, "message": {"content": [
                {"type": "tool_use", "id": "PLANT1", "name": "Bash", "input": {"command": "sh build/x/" + arg("--script", "run_checks.sh")}},
                {"type": "tool_use", "id": "PLANT2", "name": "Bash", "input": {"command": "sed -n 1p build/x/" + arg("--script", "run_checks.sh")}}]}},
            {"type": "user", "timestamp": "2030-01-01T00:10:00Z", "message": {"content": [
                {"type": "tool_result", "tool_use_id": "PLANT1", "content": "ok"},
                {"type": "tool_result", "tool_use_id": "PLANT2", "content": "ok"}]}},
        ]
    uses, results, notes = {}, {}, []
    untracked, seen = [], set()
    for r in recs:
        msg = r.get("message") or {}
        content = msg.get("content")
        if isinstance(content, list):
            for c in content:
                if not isinstance(c, dict):
                    continue
                if c.get("type") == "tool_use" and c.get("name") == "Bash":
                    uses[c["id"]] = (ts(r), c.get("input", {}))
                    for m in UNTR.finditer(c.get("input", {}).get("command", "")):
                        if m.group(1) not in seen:
                            seen.add(m.group(1)); untracked.append((r["timestamp"][:16], m.group(1), "input"))
                if c.get("type") == "tool_result":
                    body = "\n".join(texts([c]))
                    results[c.get("tool_use_id")] = (ts(r), body)
        for t in texts(content) if content is not None else []:
            for m in re.finditer(r"<task-id>(\w+)</task-id>.*?<status>(\w+)</status>", t, re.S):
                notes.append((ts(r), m.group(1), m.group(2)))
            for m in UNTR.finditer(t):
                if m.group(1) not in seen:
                    seen.add(m.group(1)); untracked.append((r["timestamp"][:16], m.group(1), "text"))
        if r.get("type") == "queue-operation":
            t = str(r.get("content", ""))
            for m in re.finditer(r"<task-id>(\w+)</task-id>.*?<status>(\w+)</status>", t, re.S):
                notes.append((ts(r), m.group(1), m.group(2)))
    runs = []
    for uid, (t0, inp) in uses.items():
        cmd = inp.get("command", "")
        if not EXEC.search(cmd):
            continue
        if uid not in results:
            continue
        t1, body = results[uid]
        bg = inp.get("run_in_background") or re.search(r"moved to the background \(ID: \w+\)|in background with ID: \w+", body)
        if bg:
            m = re.search(r"ID: (\w+)", body)
            ends = [n[0] for n in notes if m and n[1] == m.group(1) and n[2] == "completed"]
            if not ends:
                runs.append((t0, None, None, uid, "background, no completion found")); continue
            t1 = min(ends)
        runs.append((t0, t1, int((t1 - t0).total_seconds()), uid, "background" if bg else "foreground"))
    runs.sort(key=lambda x: x[0])
    print(f"(1) {arg('--script', 'run_checks.sh')} executions:")
    for t0, t1, s, uid, kind in runs:
        edits = "  EDITS-COUNT" if UNTR.search(uses[uid][1].get("command", "")) else ""
        print(f"  {t0:%Y-%m-%dT%H:%M:%SZ}  {s if s is not None else '-':>5} s  {kind}  {uid}{edits}")
    secs = [x[2] for x in runs if x[2] is not None]
    print(f"  count: {len(runs)}  total_seconds: {sum(secs)}  max_seconds: {max(secs) if secs else '-'}")
    ec = [x for x in runs if x[2] is not None and UNTR.search(uses[x[3]][1].get("command", ""))]
    print(f"  passes whose own command edits a '<n> {arg('--figure', 'untracked')}' figure: {len(ec)}  their seconds: {sum(x[2] for x in ec)}")
    prep = [t for t, b in results.values() if FIRST and re.search(r"prepared run \d{4}-\d\d-\d\d-" + FIRST + r"\b", b)]
    rec = [results[u][0] for u, (t, i) in uses.items() if LAST and u in results and re.search(r"rulecheck\.py record \d{4}-\d\d-\d\d-" + LAST + r"\b", i.get("command", ""))]
    print("(2) packet span:")
    if not (FIRST and LAST):
        print("  not asked (--first-run and --last-run)")
    elif prep and rec:
        a, b = min(prep), max(rec)
        print(f"  first prepare -{FIRST}: {a:%Y-%m-%dT%H:%M:%SZ}  last record -{LAST}: {b:%Y-%m-%dT%H:%M:%SZ}  hours: {(b - a).total_seconds() / 3600:.2f}")
    else:
        print(f"  NOT FOUND (prepare -{FIRST}: {len(prep)}, record -{LAST}: {len(rec)})")
    print(f"(3) distinct '<n> {arg('--figure', 'untracked')}' figures, first-seen order:")
    for t, n, where in untracked:
        print(f"  {t}  {n}  ({where})")
    if plant:
        p = [x for x in runs if x[3] == "PLANT1"]
        m = [x for x in runs if x[3] == "PLANT2"]
        ok = len(p) == 1 and p[0][2] == 600 and not m
        print(f"PLANT: {'CAUGHT' if ok else 'MISSED'} (run counted 600 s, mention not counted)")
        sys.exit(0 if ok else 1)


main()
