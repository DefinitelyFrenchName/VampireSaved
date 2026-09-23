#!/usr/bin/env python3
"""extract.py — the TRANSCRIPT EXTRACT the procedural checker (C1) reads (GitHub #172, slice S3).

The checker is context-free by ruling (2026-09-23: "a generic checklist plus a transcript
extract, never CLAUDE.md"), so what it can judge is exactly what this extract carries.
One line per event, in transcript order, each prefixed `[<record index> <HH:MM>]`:

  M   the maintainer's message, verbatim (up to 2,000 characters)
  A   the agent's visible statement to the maintainer, verbatim — never its private
      reasoning, which is not a statement
  A#  a deterministic aid under an A line: every FIGURE the statement reports that no
      earlier tool result, tool input or maintainer message contains (QP3). A figure is
      a number of two or more digits, or a decimal; issue numbers (#172), session keys
      (14z-176), hex and dates are not figures. The line is a HINT, not a verdict: a
      figure derived by stated arithmetic from sourced inputs is fine, and the checker
      decides
  T   a tool call: tool, [run_in_background] when tracked, its description, and the
      head of its command or path (300 characters)
  D   a DETACHED launch inside that call (the C0.1 classifier, `agentlib`), which no
      completion notification can report (QP4)
  R   the call's result: `ok` or `ERROR`, and its first 160 characters
  N   a task event: a tracked launch (its id) or its completion notification (id,
      status, and whether it arrived with the agent idle or mid-turn)

and a closing TASKS block: every tracked task with no notification in the span, and
every detached launch — the jobs QP4 asks the agent to have accounted for.

Records are parsed by TYPE, never grepped: a transcript embeds the system prompt, which
names every marker (docs/project/gotchas.md, 14z-175).

Usage:
  python3 tools/agent/extract.py TRANSCRIPT [--from N] [--to N] [--out FILE]
  python3 tools/agent/extract.py --session ID [...]      # this project's transcript by id prefix
  python3 tools/agent/extract.py --selftest
Stdlib only.
"""
import argparse
import glob
import json
import os
import re
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import agentlib  # noqa: E402

REPO = os.path.dirname(os.path.dirname(HERE))
# a figure: 2+ digits or a decimal, not glued to letters, `#`, `z-`, `0x`, `-`-dates or hex
_FIG = re.compile(r"(?<![\w#.:/-])(\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+\.\d+|\d{2,})(?![\w-]|\.\d|:\d)")


def figures(text):
    """-> the figures a statement reports, normalised (thousands separators dropped)."""
    out = []
    for m in _FIG.finditer(text):
        f = m.group(1).replace(",", "")
        if re.fullmatch(r"20\d\d", f):  # a year
            continue
        if f not in out:
            out.append(f)
    return out


def sourced(fig, corpus):
    """Is the figure present in any source text as a whole number token?"""
    pat = re.compile(rf"(?<![\d.]){re.escape(fig)}(?![\d])")
    alt = None
    if len(fig) > 3 and "." not in fig:
        # the source may print thousands separators
        with_commas = f"{int(fig):,}"
        alt = re.compile(rf"(?<![\d.]){re.escape(with_commas)}(?![\d])")
    return any(pat.search(s) or (alt and alt.search(s)) for s in corpus)


# A tracked launch's result STARTS with one of these; a result that merely QUOTES the
# marker (a `sed` of a file that names it, a selftest printed) is not a launch — 7 of
# 798 marker-carrying results in the archive were quotes (14z-176), yielding 3 phantom
# tasks (2 in 14z-175's transcript, 1 in 14z-176's — some ids were quoted twice).
# `agentlib.tasks` still uses the looser test; the same fix there is the maintainer's to
# apply (the file is edit-locked), after which this should call it instead.
_LAUNCH_HEADS = ("Command running in background with ID:", "Command did not complete within")


def tracked_launch(text):
    s = text.lstrip()
    if not s.startswith(_LAUNCH_HEADS):
        return None
    m = agentlib._TASK_ID.search(s)
    return (m.group(1) or m.group(2)) if m else None


def _text(content):
    if isinstance(content, str):
        return content
    return " ".join(x.get("text", "") for x in content or [] if isinstance(x, dict))


def extract(path, first=0, last=None):
    out, corpus = [], []
    tracked, detached = {}, []
    for n, r in agentlib.records(path):
        if last is not None and n > last:
            break
        c = agentlib._content(r)
        ts = str(r.get("timestamp"))[11:16]
        inside = n >= first
        for tid, st, form in agentlib.notifications(r):
            if tid in tracked:
                tracked[tid]["ended"] = True
            if inside:
                out.append(f"[{n} {ts}] N  task {tid} finished: {st} ({form})")
        if r.get("type") == "user" and isinstance(c, str):
            s = c.strip()
            if s.startswith("<task-notification>") or "<command-name>" in s or s.startswith("<local-command"):
                continue
            corpus.append(s)
            if inside:
                out.append(f"[{n} {ts}] M  {s[:2000]}")
            continue
        if not isinstance(c, list):
            continue
        for b in c:
            t = b.get("type")
            if r.get("type") == "assistant" and t == "text" and b.get("text", "").strip():
                txt = b["text"].strip()
                if inside:
                    out.append(f"[{n} {ts}] A  {txt}")
                    miss = [f for f in figures(txt) if not sourced(f, corpus)]
                    if miss:
                        out.append(f"[{n} {ts}] A# figures no earlier tool output, tool input or maintainer message contains: {', '.join(miss[:40])}")
            elif t == "tool_use":
                inp = b.get("input") or {}
                corpus.append(json.dumps(inp))
                what = inp.get("command") or inp.get("file_path") or inp.get("prompt") or inp.get("pattern") or ""
                what = " ".join(str(what).split())[:300]
                bg = " [run_in_background]" if inp.get("run_in_background") else ""
                if inside:
                    out.append(f"[{n} {ts}] T  {b.get('name')}{bg}: {inp.get('description', '')} :: {what}")
                if b.get("name") == "Bash" and not inp.get("run_in_background"):
                    why = agentlib.detach_reason(str(inp.get("command", "")))
                    if why:
                        detached.append((n, inp.get("description", ""), why))
                        if inside:
                            out.append(f"[{n} {ts}] D  DETACHED launch — {why}")
            elif t == "tool_result":
                text = _text(b.get("content"))
                corpus.append(text)
                tid = tracked_launch(text)
                if tid:
                    tracked.setdefault(tid, {"n": n, "ended": False})
                    if inside:
                        out.append(f"[{n} {ts}] N  task {tid} launched (tracked; its end will notify)")
                if inside:
                    out.append(f"[{n} {ts}] R  {'ERROR' if b.get('is_error') else 'ok'}: {' '.join(text.split())[:160]}")
    out.append("")
    out.append("TASKS (the jobs QP4 asks about)")
    open_t = [t for t, v in tracked.items() if not v["ended"] and v["n"] >= first]
    out.append(f"  tracked tasks launched in the span with no completion notification by its end: {', '.join(open_t) or 'none'}")
    ds = [d for d in detached if d[0] >= first]
    out.append(f"  detached launches in the span (no notification can ever report them): {len(ds)}")
    for n, desc, why in ds:
        out.append(f"    [{n}] {desc} — {why}")
    return "\n".join(out) + "\n"


def selftest():
    def rec(kind, content, n=0):
        return {"type": kind, "timestamp": f"2026-09-23T10:{n:02d}:00Z", "message": {"content": content}}
    rows = [
        rec("user", "please measure it"),
        rec("assistant", [{"type": "tool_use", "id": "u1", "name": "Bash", "input": {"command": "wc -l x", "description": "count"}}]),
        rec("user", [{"type": "tool_result", "tool_use_id": "u1", "content": "  1,623 x"}]),
        rec("assistant", [{"type": "tool_use", "id": "u2", "name": "Bash", "input": {"command": "nohup long.sh > l &", "description": "go"}}]),
        rec("user", [{"type": "tool_result", "tool_use_id": "u2", "content": "started"}]),
        rec("assistant", [{"type": "tool_use", "id": "u3", "name": "Bash", "input": {"command": "t.sh", "run_in_background": True}}]),
        rec("user", [{"type": "tool_result", "tool_use_id": "u3", "content": "Command running in background with ID: bx1. Output is being written to: /t/bx1.output"}]),
        rec("assistant", [{"type": "tool_use", "id": "u4", "name": "Bash", "input": {"command": "sed -n 1,5p doc.md"}}]),
        rec("user", [{"type": "tool_result", "tool_use_id": "u4", "content": "the doc says: Command running in background with ID: bq9. Output ..."}]),
        rec("assistant", [{"type": "thinking", "thinking": "private 777"},
                          {"type": "text", "text": "It has 1623 lines, and 4096 more rows in #172 for 14z-176, 2026, 0x1F. I'll poll."}]),
    ]
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")
    got = extract(f.name)
    os.unlink(f.name)
    checks = {
        "maintainer line": "M  please measure it" in got,
        "sourced figure (1,623 printed, 1623 said) not flagged": "1623" not in got.split("A#")[-1].split("\n")[0],
        "unsourced figure flagged": "A# figures" in got and "4096" in got.split("A#")[-1].split("\n")[0],
        "issue/session/year/hex not figures": all(x not in got.split("A#")[-1].split("\n")[0] for x in ("172", "176", "2026", "1F")),
        "private reasoning excluded": "777" not in got,
        "detached launch listed": "D  DETACHED" in got and "detached launches in the span (no notification can ever report them): 1" in got,
        "tracked open task listed": "no completion notification by its end: bx1" in got,
        "a QUOTED launch marker is not a launch": "bq9" not in got.split("TASKS")[1] and "task bq9 launched" not in got,
    }
    bad = [k for k, v in checks.items() if not v]
    for k in bad:
        print(f"  selftest WRONG: {k}")
    print(f"selftest: {len(checks)} checks, {len(bad)} wrong -> {'PASS' if not bad else 'FAIL'}")
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("transcript", nargs="?")
    ap.add_argument("--session")
    ap.add_argument("--from", dest="first", type=int, default=0)
    ap.add_argument("--to", dest="last", type=int)
    ap.add_argument("--out")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    path = a.transcript
    if a.session:
        slug = re.sub(r"[^A-Za-z0-9-]", "-", REPO)
        hits = glob.glob(os.path.expanduser(f"~/.claude/projects/{slug}/{a.session}*.jsonl"))
        if len(hits) != 1:
            print(f"--session {a.session}: {len(hits)} transcripts match", file=sys.stderr)
            return 2
        path = hits[0]
    if not path:
        ap.error("a transcript or --session is required")
    text = extract(path, a.first, a.last)
    if a.out:
        open(a.out, "w", encoding="utf-8").write(text)
        print(f"wrote {a.out}: {len(text)} characters, {text.count(chr(10))} lines")
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
