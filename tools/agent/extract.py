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
  H   a background worker's report arriving as a `[Subagent hand-back]`, or (since 2.1.281,
      measured 14z-178 by `probe_agents.sh` A10) as the `<result>` of its completion
      notification (its text joins the sources an A# line is checked against, so quoting a
      worker is not "unsourced")

and, under every Agent call, the WORKER it started (slice S4, 14z-177 — read from the worker's
own transcript, `<session>/subagents/agent-<id>.jsonl`, matched by `meta.json`'s `toolUseId`;
the orchestrator's transcript holds neither its commands nor, for a background worker, its
report — measured, `tools/agent/probe_agents.sh` A10):

  W   the call: the worker's type, any `model` override, and its description
  WS  the SPEC, verbatim, line by line (bounded) — what C1 reads the return against
  WM  the model and effort the worker actually RAN at (fields of its assistant records)
  WT  each of the worker's own tool calls (tool, head of its command or path)
  WR  each result the worker got: `ok` or `ERROR`, and its first 160 characters
  WX  the worker's REPORT, verbatim, line by line (bounded)
  W#  every figure of the report that no result the WORKER itself got contains (QP3 widened
      to workers, ruled 2026-09-23) — a hint, as A# is; the spec is NOT a source, because a
      figure found only in the spec was handed to the worker, not measured by it
  W   `NO WORKER TRANSCRIPT` when a call has none, so a missing worker cannot read as a quiet one

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


def _text(content):
    if isinstance(content, str):
        return content
    return " ".join(x.get("text", "") for x in content or [] if isinstance(x, dict))


SPEC_LINES, REPORT_LINES = 80, 60


def workers_of(path):
    """-> {toolUseId: (agent_id, meta, records)} for every worker of this session transcript."""
    found = {}
    for meta in sorted(glob.glob(path[:-len(".jsonl")] + "/subagents/*.meta.json")):
        try:
            m = json.load(open(meta))
            recs = [json.loads(line) for line in open(meta[:-len(".meta.json")] + ".jsonl")]
        except (OSError, ValueError):
            continue
        found[m.get("toolUseId")] = (os.path.basename(meta)[len("agent-"):-len(".meta.json")], m, recs)
    return found


def worker_lines(tag, block, inp, workers):
    """The W block for one Agent call (see the module docstring)."""
    out = []
    over = f" (model override: {inp['model']})" if inp.get("model") else ""
    out.append(f"{tag} W  worker {inp.get('subagent_type') or 'general-purpose'}{over} — {inp.get('description', '')}")
    spec = str(inp.get("prompt", "")).split("\n")
    for ln in spec[:SPEC_LINES]:
        out.append(f"{tag} WS | {ln}")
    if len(spec) > SPEC_LINES:
        out.append(f"{tag} WS | … {len(spec) - SPEC_LINES} more spec lines not shown")
    w = workers.get(block.get("id"))
    if not w:
        out.append(f"{tag} W  NO WORKER TRANSCRIPT for this call — its commands and report cannot be read")
        return out
    _, _, recs = w
    models, efforts, results, report = set(), set(), [], ""
    for r in recs:
        c = (r.get("message") or {}).get("content")
        if r.get("type") == "assistant":
            models.add(str((r.get("message") or {}).get("model")))
            efforts.add(str(r.get("effort")))
        for b in c if isinstance(c, list) else []:
            t = b.get("type")
            if t == "tool_use" and b.get("name") == "SubagentHandback":
                report = str((b.get("input") or {}).get("message", "")) or report
            elif t == "tool_use":
                i = b.get("input") or {}
                what = i.get("command") or i.get("file_path") or i.get("pattern") or i.get("prompt") or ""
                out.append(f"{tag} WT {b.get('name')}: {' '.join(str(what).split())[:300]}")
            elif t == "tool_result":
                text = _text(b.get("content"))
                if text.startswith('{"success":true,"message":"Report delivered'):
                    continue
                results.append(text)
                out.append(f"{tag} WR {'ERROR' if b.get('is_error') else 'ok'}: {' '.join(text.split())[:160]}")
            elif t == "text" and r.get("type") == "assistant" and b.get("text", "").strip():
                report = b["text"].strip()
    out.insert(1 + min(len(spec), SPEC_LINES + 1), f"{tag} WM ran on {','.join(sorted(models))} at effort {','.join(sorted(efforts))}")
    rep = report.split("\n") if report else ["(no report)"]
    for ln in rep[:REPORT_LINES]:
        out.append(f"{tag} WX | {ln}")
    if len(rep) > REPORT_LINES:
        out.append(f"{tag} WX | … {len(rep) - REPORT_LINES} more report lines not shown")
    miss = [f for f in figures(report) if not sourced(f, results)]
    if miss:
        out.append(f"{tag} W# figures in the report that no result the worker got contains: {', '.join(miss[:40])}")
    return out


def extract(path, first=0, last=None):
    out, corpus = [], []
    workers = workers_of(path)
    tracked, detached = {}, []
    for n, r in agentlib.records(path):
        if last is not None and n > last:
            break
        c = agentlib._content(r)
        ts = str(r.get("timestamp"))[11:16]
        inside = n >= first
        a = r.get("attachment") or {}
        hb = str(a.get("prompt", "")) if r.get("type") == "attachment" else ""
        if hb.startswith("<agent-message"):
            corpus.append(hb)
            if inside:
                who = re.search(r'from="([^"]+)"', hb)
                out.append(f"[{n} {ts}] H  report of worker {who.group(1) if who else '?'} arrived (hand-back)")
        # the THIRD report form (2.1.281, measured 14z-178 by probe_agents.sh A10): a background
        # worker's report as the <result> of its completion notification — a user string or a
        # queued_command attachment. Its text sources an A# line like a hand-back's.
        for note in ([c] if r.get("type") == "user" and isinstance(c, str) else []) + [hb]:
            res = re.search(r"<result>(.*?)</result>", note, re.S) if note.lstrip().startswith("<task-notification>") else None
            if res and res.group(1).strip():
                corpus.append(res.group(1))
                if inside:
                    tid = re.search(r"<task-id>([^<]+)</task-id>", note)
                    out.append(f"[{n} {ts}] H  report of task {tid.group(1) if tid else '?'} arrived (in its completion notification)")
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
                    if b.get("name") in ("Agent", "Task"):
                        out.extend(worker_lines(f"[{n} {ts}]", b, inp, workers))
                if b.get("name") == "Bash" and not inp.get("run_in_background"):
                    why = agentlib.detach_reason(str(inp.get("command", "")))
                    if why:
                        detached.append((n, inp.get("description", ""), why))
                        if inside:
                            out.append(f"[{n} {ts}] D  DETACHED launch — {why}")
            elif t == "tool_result":
                text = _text(b.get("content"))
                corpus.append(text)
                # agentlib's test: a result that merely QUOTES the launch marker is not a
                # launch (7 of 798 in the archive were quotes, 3 phantom tasks; 14z-176)
                tid = agentlib.tracked_launch(text)
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
    # the worker block: a session with two Agent calls, one with a worker transcript (a sourced
    # figure, an unsourced one, and one found ONLY in its spec) and one without; plus a hand-back
    import shutil
    d = tempfile.mkdtemp()
    main = os.path.join(d, "s.jsonl")
    wrows = [
        rec("user", "go"),
        rec("assistant", [{"type": "tool_use", "id": "a1", "name": "Agent",
                           "input": {"subagent_type": "measurer", "description": "m", "prompt": "TASK: x\nC1: wc -l f\nthe answer is 555"}}]),
        rec("user", [{"type": "tool_result", "tool_use_id": "a1", "content": "ok"}]),
        rec("assistant", [{"type": "tool_use", "id": "a2", "name": "Agent", "input": {"subagent_type": "reader", "prompt": "TASK: y"}}]),
        {"type": "attachment", "timestamp": "2026-09-23T10:05:00Z",
         "attachment": {"type": "queued_command", "prompt": '<agent-message from="w9">[Subagent hand-back] FIG n = 8642 <- C1'}},
        rec("assistant", [{"type": "text", "text": "the worker says 8642"}]),
        # the third form (14z-178): the report as the <result> of the completion notification;
        # a notification with no <result>, and a maintainer message QUOTING one, carry no report
        rec("user", "<task-notification>\n<task-id>tq7</task-id>\n<status>completed</status>\n"
                    "<result>FIG q = 7531 <- C1</result>\n</task-notification>"),
        rec("assistant", [{"type": "text", "text": "the second worker says 7531"}]),
        rec("user", "<task-notification>\n<task-id>tq8</task-id>\n<status>completed</status>\n</task-notification>"),
        rec("user", "why did it print <task-notification><result>4455</result> earlier?"),
        rec("assistant", [{"type": "text", "text": "and 3344 is mine"}]),
    ]
    with open(main, "w") as g:
        for r in wrows:
            g.write(json.dumps(r) + "\n")
    os.makedirs(os.path.join(d, "s", "subagents"))
    with open(os.path.join(d, "s", "subagents", "agent-w1.meta.json"), "w") as g:
        json.dump({"agentType": "measurer", "toolUseId": "a1"}, g)
    with open(os.path.join(d, "s", "subagents", "agent-w1.jsonl"), "w") as g:
        for r in ({"type": "assistant", "effort": "high", "message": {"model": "mS", "content": [
                      {"type": "tool_use", "id": "b1", "name": "Bash", "input": {"command": "wc -l f"}}]}},
                  {"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": "b1", "content": "  1234 f"}]}},
                  {"type": "assistant", "effort": "high", "message": {"model": "mS", "content": [
                      {"type": "text", "text": "FIG lines = 1234 <- C1\nFIG other = 9876 <- C1\nFIG answer = 555 <- C1"}]}}):
            g.write(json.dumps(r) + "\n")
    wg = extract(main)
    shutil.rmtree(d)
    wline = next((ln for ln in wg.split("\n") if " W# " in ln), "")
    checks.update({
        "worker spec shown": "WS | TASK: x" in wg,
        "worker caps shown": "WM ran on mS at effort high" in wg,
        "worker call and result shown": "WT Bash: wc -l f" in wg and "WR ok: 1234 f" in wg,
        "worker report shown": "WX | FIG lines = 1234 <- C1" in wg,
        "worker figure sourced in its own result not flagged": "1234" not in wline,
        "worker figure in no result flagged": "9876" in wline,
        "worker figure found only in the SPEC flagged": "555" in wline,
        "a call without a worker transcript is loud": "NO WORKER TRANSCRIPT" in wg,
        "a hand-back is shown and sources the orchestrator": "H  report of worker w9 arrived" in wg
            and not any("A# " in ln and "8642" in ln for ln in wg.split("\n")),
        "a notification's <result> is shown and sources the orchestrator": "H  report of task tq7 arrived (in its completion notification)" in wg
            and not any("A# " in ln and "7531" in ln for ln in wg.split("\n")),
        "a notification with no <result> carries no report": "task tq8 arrived" not in wg,
        "a message QUOTING a notification is not a report": "4455" not in "".join(ln for ln in wg.split("\n") if " H  " in ln),
        "an unsourced figure after them is still flagged": any("A# " in ln and "3344" in ln for ln in wg.split("\n")),
    })
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
