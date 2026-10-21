#!/usr/bin/env python3
"""extract.py — the TRANSCRIPT EXTRACT the procedural checker (C1) reads (GitHub #172, slice S3).

The checker is context-free by ruling (2026-09-23: "a generic checklist plus a transcript
extract, never CLAUDE.md"), so what it can judge is exactly what this extract carries.
One line per event, in transcript order, each prefixed `[<record index> <HH:MM>]`:

  M   the maintainer's message, verbatim (up to 2,000 characters); `M  [mid-turn]` for one sent while the
      agent was working, which reaches the transcript only as a `queued_command` attachment from a human
      (#262, 14z-205c)
  A   the agent's visible statement to the maintainer, verbatim — never its private
      reasoning, which is not a statement
  A#  a deterministic aid under an A line: every FIGURE the statement reports that no
      earlier tool result, tool input or maintainer message contains (QP3). A figure is
      a number of two or more digits, or a decimal; issue numbers (#172), session keys
      (14z-176), hex and dates are not figures. The line is a HINT, not a verdict: a
      figure derived by stated arithmetic from sourced inputs is fine, and the checker
      decides. A decimal figure is also sourced by a source number with more decimals that
      ROUNDS to it (half up): "11.8" by `real 11.80`, "10.5" by `real 10.45` (#277, 14z-205c)
  T   a tool call: tool, [run_in_background] when tracked, its description, and the
      head of its command or path (300 characters)
  D   a DETACHED launch inside that call (the C0.1 classifier, `agentlib`), which no
      completion notification can report (QP4)
  R   the call's result: `ok` or `ERROR`, and its first 160 characters
  A@  an aid under an A line (#277, 14z-205c): each figure or path the statement cites whose source is a
      result line cut before it, quoted in its context — the cut hid `real 11.80` behind "11.8 s"
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
  WX  the worker's REPORT, verbatim, line by line (bounded): its SubagentHandback when its own
      transcript holds one; else the hand-back the SESSION received from it (an `<agent-message
      from="<id>">` record, anywhere in the transcript — it can arrive after `--to`), marked as such;
      else, for a BACKGROUND worker, `NOT DELIVERED` with its last text so far marked as NOT a report
      (#208: the 14z-188 close's extract was cut six seconds before a checker handed back, and its
      first text "Let me read all the named files." read as its report — procedure run
      2026-10-02-566 QP5); a foreground worker's last text, as before
  W@  as A@, for the worker's report against its own results (#277)
  W#  every figure of the report that no result the WORKER itself got contains (QP3 widened
      to workers, ruled 2026-09-23) — a hint, as A# is; the spec is NOT a source, because a
      figure found only in the spec was handed to the worker, not measured by it — EXCEPT for a
      RULE-CHECKER reader (#271, maintainer-ruled 2026-10-12, 14z-199): it judges the claim its
      prompt carries and quotes it, so its prompt is a source. A calibration plant's reader
      quoting its planted claim's frames 2550/2560 raised W# in procedure runs from 14z-179 to
      14z-198 (tools/recurrence_alarm.py names the family)
  W§  under a W# line (#263, 14z-205c): for each figure W# lists, the lines of a file the report CITES beside it
      (`name.py:448-460, 667`), quoted from the worker's own read of that file — the inputs of a figure a worker
      derived from a file, which no result contains as a number (run 2026-10-13-986's reader: "6630 frames (first
      event 2600 to frames 9230; name_moves.py.txt:448-460, 667, 683)"). The check's own arithmetic stays QP3's
  W   `NO WORKER TRANSCRIPT` when a call has none, so a missing worker cannot read as a quiet one

and a closing TASKS block: every tracked task with no notification in the span, and
every detached launch — the jobs QP4 asks the agent to have accounted for.

A span cut with `--from` opens with a PRELUDE (#277, 14z-205c): the last `--prelude` (default 40) event
lines before its first record, each marked `< ` so no `[record` parser counts them as the span — context
only, so a report in the span whose calls sit just before the cut is not judged blind.

Records are parsed by TYPE, never grepped: a transcript embeds the system prompt, which
names every marker (docs/project/gotchas.md, 14z-175).

Usage:
  python3 tools/agent/extract.py TRANSCRIPT [--from N] [--to N] [--prelude N] [--out FILE]
  python3 tools/agent/extract.py --session ID [...]      # this project's transcript by id prefix
  python3 tools/agent/extract.py --selftest
Stdlib only.
"""
import argparse
import collections
import glob
import json
import os
import re
import sys
import tempfile
from decimal import ROUND_HALF_UP, Decimal

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


def _matchers(fig):
    """-> the patterns that find a figure in a source, and the test a ROUNDED decimal match must pass"""
    pats = [re.compile(rf"(?<![\d.]){re.escape(fig)}(?![\d])")]
    if len(fig) > 3 and "." not in fig:
        # the source may print thousands separators
        pats.append(re.compile(rf"(?<![\d.]){re.escape(f'{int(fig):,}')}(?![\d])"))
    rounds = None
    if "." in fig:
        # #277 (14z-205c): the statement may write a measured figure to fewer decimals than its source
        # ("11.8" for `real 11.80`, "10.5" for 10.45): a source number with more decimals that rounds to it
        # half up sources it (the integer part may carry: 9.96 -> 10.0)
        ip, dp = fig.split(".")
        ints = "|".join(sorted({ip, str(int(ip) - 1)} if int(ip) > 0 else {ip}))
        # a whole number token only (run 2026-10-20-1157, the maintainer: "Near + whole token"): not inside a word,
        # not part of a version (`git version 2.54.0` falsely sourced "2.5")
        pats.append(re.compile(rf"(?<![\w.])((?:{ints})\.\d{{{len(dp) + 1},}})(?![\w]|\.\d)"))
        q, want = Decimal(1).scaleb(-len(dp)), Decimal(fig)
        rounds = lambda m: Decimal(m).quantize(q, ROUND_HALF_UP) == want
    return pats, rounds


def find_in(fig, text, pats=None, rounds=None):
    """-> the first match of the figure in one source text (re.Match), or None"""
    if pats is None:
        pats, rounds = _matchers(fig)
    for i, pat in enumerate(pats):
        for m in pat.finditer(text):
            if rounds is None or i < len(pats) - 1 or rounds(m.group(1)):
                return m
    return None


NEAR_RECORDS = 50   # #277: a ROUNDED source must sit in a tool result of the last 50 records before the statement


def sourced(fig, corpus, near=None):
    """Is the figure present in any source text as a whole number token, or, for a decimal, rounded from one? A
    rounded source is looked for in `near` when given (the extract passes the tool results of the last NEAR_RECORDS
    records: on three transcripts the true roundings sat 4 records back, the two false ones, `load averages: 1.93`
    for "1.9 MB" and a version for "2.5", thousands; run 2026-10-20-1157), else in the whole corpus."""
    pats, rounds = _matchers(fig)
    if rounds is None:
        return any(find_in(fig, s, pats, rounds) for s in corpus)
    if any(p.search(s) for p in pats[:-1] for s in corpus):
        return True
    return any(rounds(m.group(1)) for s in (corpus if near is None else near) for m in pats[-1].finditer(s))


RESULT_CHARS, PRELUDE_LINES = 160, 40   # 40: run 2026-10-13-1017's evidence sat 35 lines before its part's cut
_PATH = re.compile(r"(?<![\w/.-])((?:[\w.-]+/)+[\w.-]+)")   # a path a statement cites (`a/b`, `build/x/y.txt`)


_WORD = re.compile(r"\w")


def whole_in(fig, text):
    """#277 (rule-checker run 2026-10-20-1157): find_in, but only where the figure stands as a whole token, not inside
    a hash or a key ("35" in `…feaa35b7e…`, "14" in `14z-189`): the A@ quote must show the figure's own source"""
    pats, rounds = _matchers(fig)
    for i, pat in enumerate(pats):
        for m in pat.finditer(text):
            if rounds is not None and i == len(pats) - 1 and not rounds(m.group(1)):
                continue
            if (m.start() and _WORD.match(text[m.start() - 1])) or (m.end() < len(text) and _WORD.match(text[m.end()])):
                continue   # inside a word: not this figure's source
            return m
    return None


def cut_cites(text, results):
    """#277 (14z-205c): each figure or path the statement cites that a result holds only BEYOND the head a result line
    prints (RESULT_CHARS), with its context from the latest such result. `results` is [(record, full text)]."""
    out = []
    cites = [(f, None) for f in figures(text)] + [(p, re.compile(rf"(?<![\w/.-]){re.escape(p)}(?![\w/-])"))
                                                   for p in dict.fromkeys(x.rstrip(".") for x in _PATH.findall(text))]
    for tok, rx in cites[:20]:
        for n, full in reversed(results):
            flat = " ".join(full.split())
            m = rx.search(flat) if rx else whole_in(tok, flat)
            if not m:
                continue
            if m.end() > RESULT_CHARS and not (rx.search(flat[:RESULT_CHARS]) if rx else whole_in(tok, flat[:RESULT_CHARS])):
                a, b = max(0, m.start() - 50), m.end() + 50
                out.append(f"{tok} <- [{n}] \"{'…' if a else ''}{flat[a:b]}{'…' if b < len(flat) else ''}\"")
            break
    return out


def _text(content):
    if isinstance(content, str):
        return content
    return " ".join(x.get("text", "") for x in content or [] if isinstance(x, dict))


SPEC_LINES, REPORT_LINES = 80, 60
JUDGE_PROMPT_SOURCED = True   # #271: False is the pre-#271 extractor (test_agent_extract's judge-prompt-unsourced control)


def is_judge(inp, meta):
    """A rule-checker reader: by the call's subagent_type, or by the worker's own meta.json agentType."""
    return inp.get("subagent_type") == "rule-checker" or (meta or {}).get("agentType") == "rule-checker"


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


def session_handbacks(path):
    """-> {agent_id: (record, report)} for every `[Subagent hand-back]` the session received, over the WHOLE
    transcript (a hand-back can arrive after the span's end). The report is the text after the frame's
    "The report follows:" line, each line's two-space harness indent removed (#208)."""
    found = {}
    for n, r in agentlib.records(path):
        a = r.get("attachment") or {}
        hb = str(a.get("prompt", "")) if r.get("type") == "attachment" else ""
        if not hb.startswith("<agent-message"):
            continue
        who = re.search(r'from="([^"]+)"', hb)
        body = hb.split("The report follows:\n", 1)
        if not who or len(body) < 2 or "[Subagent hand-back]" not in body[0]:
            continue
        text = body[1].rsplit("</agent-message>", 1)[0].rstrip("\n")
        found.setdefault(who.group(1), (n, "\n".join(ln[2:] if ln.startswith("  ") else ln for ln in text.split("\n"))))
    return found


_CITE = re.compile(r"([\w.-]+\.\w+):(\d+(?:-\d+)?(?:,\s*\d+(?:-\d+)?)*)")   # `name.py:448-460, 667, 683`
_NUMBERED = re.compile(r"^\s*(\d+)(?:\t|→)(.*)$")   # a line of a Read result, as the harness numbers it
CITED_LINES = 20


def cited_lines(report, fig, reads):
    """#263 (14z-205c): the lines of a file the report cites in the sentence that states `fig`, from the worker's own
    reads (`reads` = {basename: {full path: {line number: text}}}). -> [(basename, number, text)], at most CITED_LINES;
    rule-checker run 2026-10-21-1160: a NOTE (number 0) says when a basename names two different files read (nothing
    is quoted from either), a cited line the reads do not hold is marked, and lines past the cap are counted"""
    out, more, noted = [], 0, set()
    for sent in re.split(r"(?<=\.)\s+(?=[A-Z])|\n", report):   # a sentence; a `;` inside one keeps its citation
        if not find_in(fig, sent):
            continue
        for name, spans in _CITE.findall(sent):
            base = os.path.basename(name)
            files = reads.get(base, {})
            if len(files) > 1:   # which file the report means is unknown: quote neither
                if base not in noted:
                    noted.add(base)
                    out.append((base, 0, f"[{len(files)} different files named {base} were read ({', '.join(sorted(files))}); none quoted]"))
                continue
            got = next(iter(files.values()), {})
            for sp in re.split(r",\s*", spans):
                a, _, b = sp.partition("-")
                for k in range(int(a), int(b or a) + 1):
                    if len(out) >= CITED_LINES:
                        more += 1
                    else:
                        out.append((base, k, got.get(k, "[not in the worker's reads]")))
    if more:
        out.append(("", 0, f"[{more} more cited line(s) not shown]"))
    return out


def worker_lines(tag, block, inp, workers, sess_hb=None):
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
    agent_id, meta, recs = w
    # the REPORT is what the worker DELIVERED: its SubagentHandback message when it made one, else
    # its last text. A text written AFTER the hand-back is never delivered and must not override it
    # (14z-178, procedure run 2026-09-24-137 QP5: a worker's trailing prose, written after a
    # conforming hand-back, was read as its report and judged against its spec)
    models, efforts, results, report, handback = set(), set(), [], "", None
    paths, reads = {}, {}   # #263: what each Read call read, numbered, by file basename, then full path
    for r in recs:
        c = (r.get("message") or {}).get("content")
        if r.get("type") == "assistant":
            models.add(str((r.get("message") or {}).get("model")))
            efforts.add(str(r.get("effort")))
        for b in c if isinstance(c, list) else []:
            t = b.get("type")
            if t == "tool_use" and b.get("name") == "SubagentHandback":
                handback = str((b.get("input") or {}).get("message", ""))
            elif t == "tool_use":
                i = b.get("input") or {}
                if b.get("name") == "Read" and i.get("file_path"):
                    paths[b.get("id")] = str(i["file_path"])   # the FULL path: two files may share a basename
                what = i.get("command") or i.get("file_path") or i.get("pattern") or i.get("prompt") or ""
                out.append(f"{tag} WT {b.get('name')}: {' '.join(str(what).split())[:300]}")
            elif t == "tool_result":
                text = _text(b.get("content"))
                if text.startswith('{"success":true,"message":"Report delivered'):
                    continue
                results.append(text)
                if b.get("tool_use_id") in paths:
                    full = paths[b["tool_use_id"]]
                    got = reads.setdefault(os.path.basename(full), {}).setdefault(full, {})
                    for ln in text.split("\n"):
                        m = _NUMBERED.match(ln)
                        if m:
                            got[int(m.group(1))] = m.group(2)
                out.append(f"{tag} WR {'ERROR' if b.get('is_error') else 'ok'}: {' '.join(text.split())[:RESULT_CHARS]}")
            elif t == "text" and r.get("type") == "assistant" and b.get("text", "").strip():
                report = b["text"].strip()
    out.insert(1 + min(len(spec), SPEC_LINES + 1), f"{tag} WM ran on {','.join(sorted(models))} at effort {','.join(sorted(efforts))}")
    note = ""
    if handback is not None:
        report = handback
    elif agent_id in (sess_hb or {}):
        hn, report = sess_hb[agent_id]
        note = f"(the hand-back the session received at record {hn}; the worker's own transcript holds no SubagentHandback)"
    elif (meta or {}).get("requestShape") == "background":
        last = report
        report = ""
        note = ("(NOT DELIVERED when this extract was made: no SubagentHandback in the worker's transcript and no hand-back "
                "in the session's — the worker may still have been running; its last text so far, NOT a report: "
                + (" ".join(last.split())[:160] if last else "none") + ")")
    if note:
        out.append(f"{tag} WX {note}")
    rep = report.split("\n") if report else ["(no report)"]
    for ln in rep[:REPORT_LINES]:
        out.append(f"{tag} WX | {ln}")
    if len(rep) > REPORT_LINES:
        out.append(f"{tag} WX | … {len(rep) - REPORT_LINES} more report lines not shown")
    # a rule-checker reader judges the claim its prompt carries: quoting it is not an unsourced figure (#271)
    sources = results + ([str(inp.get("prompt", ""))] if JUDGE_PROMPT_SOURCED and is_judge(inp, meta) else [])
    cut = cut_cites(report, list(enumerate(results)))
    if cut:
        out.append(f"{tag} W@ cited from results whose WR line was cut at {RESULT_CHARS} characters (the worker's result number): {' ; '.join(cut)}")
    miss = [f for f in figures(report) if not sourced(f, sources)]
    if miss:
        out.append(f"{tag} W# figures in the report that no result the worker got contains: {', '.join(miss[:40])}")
        shown = {}
        for f in miss[:10]:
            cl = cited_lines(report, f, reads)
            if cl and tuple(cl) in shown:
                out.append(f"{tag} W§ {f}: the same lines as {shown[tuple(cl)]}")
            elif cl:
                shown[tuple(cl)] = f
                out.append(f"{tag} W§ {f}: the lines its sentence cites, from the worker's own reads: "
                           + " | ".join((f"{nm}:{k}: " if k else "") + ' '.join(tx.split())[:150] for nm, k, tx in cl))
    return out


def mid_turn_message(r):
    """#262 (14z-205c): the text of a maintainer message sent mid-turn, which reaches the transcript only as a
    `queued_command` attachment (beside a `queue-operation` enqueue), or None. `origin.kind` names its sender (human,
    peer for a worker's hand-back, task-notification); an attachment without `origin` counts when it is a plain prompt."""
    a = (r.get("attachment") or {}) if r.get("type") == "attachment" else {}
    if a.get("type") != "queued_command":
        return None
    s = str(a.get("prompt", "")).strip()
    kind = (a.get("origin") or {}).get("kind")
    human = kind == "human" if kind else (a.get("commandMode") == "prompt" and not s.startswith("<"))
    return s if human and s else None


def extract(path, first=0, last=None, prelude=PRELUDE_LINES):
    out, corpus, results, said = [], [], [], set()
    before = collections.deque(maxlen=max(prelude, 0))   # #277: the event lines just before the span
    workers = workers_of(path)
    sess_hb = session_handbacks(path)
    tracked, detached = {}, []
    for n, r in agentlib.records(path):
        if last is not None and n > last:
            break
        c = agentlib._content(r)
        ts = str(r.get("timestamp"))[11:16]
        inside = n >= first
        sink = out if inside else before
        a = r.get("attachment") or {}
        hb = str(a.get("prompt", "")) if r.get("type") == "attachment" else ""
        if hb.startswith("<agent-message"):
            corpus.append(hb)
            who = re.search(r'from="([^"]+)"', hb)
            sink.append(f"[{n} {ts}] H  report of worker {who.group(1) if who else '?'} arrived (hand-back)")
        # the THIRD report form (2.1.281, measured 14z-178 by probe_agents.sh A10): a background
        # worker's report as the <result> of its completion notification — a user string or a
        # queued_command attachment. Its text sources an A# line like a hand-back's.
        for note in ([c] if r.get("type") == "user" and isinstance(c, str) else []) + [hb]:
            res = re.search(r"<result>(.*?)</result>", note, re.S) if note.lstrip().startswith("<task-notification>") else None
            if res and res.group(1).strip():
                corpus.append(res.group(1))
                tid = re.search(r"<task-id>([^<]+)</task-id>", note)
                sink.append(f"[{n} {ts}] H  report of task {tid.group(1) if tid else '?'} arrived (in its completion notification)")
        if r.get("type") == "assistant":
            said.clear()   # #262 (run 2026-10-20-1158): a message's two forms come before the reply; the same text later is a new message
        mid = mid_turn_message(r)
        if mid and mid not in said:
            said.add(mid)
            corpus.append(mid)
            sink.append(f"[{n} {ts}] M  [mid-turn] {mid[:2000]}")
        for tid, st, form in agentlib.notifications(r):
            if tid in tracked:
                tracked[tid]["ended"] = True
            sink.append(f"[{n} {ts}] N  task {tid} finished: {st} ({form})")
        if r.get("type") == "user" and isinstance(c, str):
            s = c.strip()
            if s.startswith("<task-notification>") or "<command-name>" in s or s.startswith("<local-command"):
                continue
            corpus.append(s)
            if s not in said:   # #262: once, whichever form came first
                said.add(s)
                sink.append(f"[{n} {ts}] M  {s[:2000]}")
            continue
        if not isinstance(c, list):
            continue
        for b in c:
            t = b.get("type")
            if r.get("type") == "assistant" and t == "text" and b.get("text", "").strip():
                txt = b["text"].strip()
                sink.append(f"[{n} {ts}] A  {txt}")
                if inside:
                    cut = cut_cites(txt, results)
                    if cut:
                        out.append(f"[{n} {ts}] A@ cited from results whose R line was cut at {RESULT_CHARS} characters: {' ; '.join(cut)}")
                    near = [t for k, t in results if n - k <= NEAR_RECORDS]   # #277: where a rounded source may sit
                    miss = [f for f in figures(txt) if not sourced(f, corpus, near)]
                    if miss:
                        out.append(f"[{n} {ts}] A# figures no earlier tool output, tool input or maintainer message contains: {', '.join(miss[:40])}")
            elif t == "tool_use":
                inp = b.get("input") or {}
                corpus.append(json.dumps(inp))
                what = inp.get("command") or inp.get("file_path") or inp.get("prompt") or inp.get("pattern") or ""
                what = " ".join(str(what).split())[:300]
                bg = " [run_in_background]" if inp.get("run_in_background") else ""
                sink.append(f"[{n} {ts}] T  {b.get('name')}{bg}: {inp.get('description', '')} :: {what}")
                if inside and b.get("name") in ("Agent", "Task"):
                    out.extend(worker_lines(f"[{n} {ts}]", b, inp, workers, sess_hb))
                if b.get("name") == "Bash" and not inp.get("run_in_background"):
                    why = agentlib.detach_reason(str(inp.get("command", "")))
                    if why:
                        detached.append((n, inp.get("description", ""), why))
                        sink.append(f"[{n} {ts}] D  DETACHED launch — {why}")
            elif t == "tool_result":
                text = _text(b.get("content"))
                corpus.append(text)
                results.append((n, text))
                # agentlib's test: a result that merely QUOTES the launch marker is not a
                # launch (7 of 798 in the archive were quotes, 3 phantom tasks; 14z-176)
                tid = agentlib.tracked_launch(text)
                if tid:
                    tracked.setdefault(tid, {"n": n, "ended": False})
                    sink.append(f"[{n} {ts}] N  task {tid} launched (tracked; its end will notify)")
                sink.append(f"[{n} {ts}] R  {'ERROR' if b.get('is_error') else 'ok'}: {' '.join(text.split())[:RESULT_CHARS]}")
    if first > 0 and before:
        out[:0] = [f"BEFORE THE SPAN (#277): the last {len(before)} event lines before record {first}, context only, marked `<`;"
                   " judge the span that follows", *("< " + ln for ln in before), f"THE SPAN (records {first} on)"]
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
        # #208: two BACKGROUND workers whose own transcripts hold only a first text (cut mid-run):
        # w3's report reached the session as a hand-back AFTER the call, w4's never did
        rec("assistant", [{"type": "tool_use", "id": "a3", "name": "Agent", "input": {"subagent_type": "rule-checker", "description": "c3", "prompt": "Q1"}}]),
        rec("assistant", [{"type": "tool_use", "id": "a4", "name": "Agent", "input": {"subagent_type": "rule-checker", "description": "c4", "prompt": "Q1"}}]),
        # #271: a rule-checker reader quotes its prompt's claim (2560) and states a figure in neither (4242); a
        # measurer whose spec names 555 is still flagged for it (above)
        rec("assistant", [{"type": "tool_use", "id": "a5", "name": "Agent", "input": {"subagent_type": "rule-checker", "description": "c5",
                           "prompt": "Claim: the pins start from frame 2560 at the earliest"}}]),
        {"type": "attachment", "timestamp": "2026-09-23T10:09:00Z",
         "attachment": {"type": "queued_command", "prompt": '<agent-message from="w3">\n[Subagent hand-back] The text below is the final report. The report follows:\n  Q1: OK — six lines\n  VERDICT: OK\n</agent-message>'}},
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
                      {"type": "text", "text": "FIG lines = 1234 <- C1\nFIG other = 9876 <- C1\nFIG answer = 555 <- C1"}]}},
                  {"type": "assistant", "effort": "high", "message": {"model": "mS", "content": [
                      {"type": "tool_use", "id": "h1", "name": "SubagentHandback",
                       "input": {"message": "FIG lines = 1234 <- C1\nFIG other = 9876 <- C1\nFIG answer = 555 <- C1"}}]}},
                  {"type": "assistant", "effort": "high", "message": {"model": "mS", "content": [
                      {"type": "text", "text": "Trailing prose written after the hand-back, never delivered."}]}}):
            g.write(json.dumps(r) + "\n")
    with open(os.path.join(d, "s", "subagents", "agent-w5.meta.json"), "w") as g:
        json.dump({"agentType": "rule-checker", "toolUseId": "a5"}, g)
    with open(os.path.join(d, "s", "subagents", "agent-w5.jsonl"), "w") as g:
        for r in ({"type": "assistant", "effort": "high", "message": {"model": "mR", "content": [
                      {"type": "tool_use", "id": "r5", "name": "Read", "input": {"file_path": "a.txt"}}]}},
                  {"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": "r5", "content": "pins at t - 40"}]}},
                  {"type": "assistant", "effort": "high", "message": {"model": "mR", "content": [
                      {"type": "tool_use", "id": "h5", "name": "SubagentHandback",
                       "input": {"message": "Q1: VIOLATED — the pins from 2560 rest on 4242"}}]}}):
            g.write(json.dumps(r) + "\n")
    for wid, tu in (("w3", "a3"), ("w4", "a4")):
        with open(os.path.join(d, "s", "subagents", f"agent-{wid}.meta.json"), "w") as g:
            json.dump({"agentType": "rule-checker", "toolUseId": tu, "requestShape": "background"}, g)
        with open(os.path.join(d, "s", "subagents", f"agent-{wid}.jsonl"), "w") as g:
            g.write(json.dumps({"type": "assistant", "effort": "high", "message": {"model": "mR", "content": [
                {"type": "text", "text": "Let me read all the named files."}]}}) + "\n")
    wg = extract(main)
    wg_cut = extract(main, last=len(wrows) - 2)   # the span ends BEFORE w3's hand-back arrives
    shutil.rmtree(d)
    wline = next((ln for ln in wg.split("\n") if " W# " in ln), "")
    w5 = wg.split("worker rule-checker — c5", 1)[-1].split(" W  worker ", 1)[0]   # the c5 worker's block
    w5line = next((ln for ln in w5.split("\n") if " W# " in ln), "")
    checks.update({
        "worker spec shown": "WS | TASK: x" in wg,
        "worker caps shown": "WM ran on mS at effort high" in wg,
        "worker call and result shown": "WT Bash: wc -l f" in wg and "WR ok: 1234 f" in wg,
        "worker report shown": "WX | FIG lines = 1234 <- C1" in wg,
        "the DELIVERED hand-back is the report, not a text written after it": "Trailing prose" not in wg,
        "worker figure sourced in its own result not flagged": "1234" not in wline,
        "worker figure in no result flagged": "9876" in wline,
        "worker figure found only in the SPEC flagged": "555" in wline,
        "a rule-checker's figure found only in its PROMPT not flagged (#271)": "worker rule-checker — c5" in wg and "2560" not in w5line,
        "a rule-checker's figure in neither its prompt nor its results flagged (#271)": "4242" in w5line,
        "a call without a worker transcript is loud": "NO WORKER TRANSCRIPT" in wg,
        "a hand-back is shown and sources the orchestrator": "H  report of worker w9 arrived" in wg
            and not any("A# " in ln and "8642" in ln for ln in wg.split("\n")),
        "a notification's <result> is shown and sources the orchestrator": "H  report of task tq7 arrived (in its completion notification)" in wg
            and not any("A# " in ln and "7531" in ln for ln in wg.split("\n")),
        "a notification with no <result> carries no report": "task tq8 arrived" not in wg,
        "a message QUOTING a notification is not a report": "4455" not in "".join(ln for ln in wg.split("\n") if " H  " in ln),
        "an unsourced figure after them is still flagged": any("A# " in ln and "3344" in ln for ln in wg.split("\n")),
        # #208
        "a background worker's report is the hand-back the session received (#208)": "WX | Q1: OK — six lines" in wg
            and "WX (the hand-back the session received at record" in wg,
        "...even when the hand-back arrives after the span's end (#208)": "WX | Q1: OK — six lines" in wg_cut,
        "a background worker's first text is never its report (#208)": not any(" WX | Let me read" in ln for ln in wg.split("\n")),
        "a background worker with no hand-back anywhere is NOT DELIVERED (#208)": "WX (NOT DELIVERED when this extract was made" in wg
            and "NOT a report: Let me read all the named files.)" in wg,
    })
    # #277 (14z-205c): a figure written to fewer decimals, a result line cut before what a statement cites, a part's
    # prelude. The long result holds `real 10.45` and a path past the 160-character head; the statement cites 10.5
    # (rounded half up from 10.45: sourced), 10.4 (no source rounds to it: flagged) and the path
    pad = "x" * 170
    prows = [
        rec("user", "time the gate", 1),
        rec("assistant", [{"type": "tool_use", "id": "p1", "name": "Bash", "input": {"command": "time sh g.sh", "description": "time"}}], 2),
        rec("user", [{"type": "tool_result", "tool_use_id": "p1", "content": f"PASS {pad} real 10.45 wrote build/t277/out.log commit 31942f2c15a6303437979138d9a5feaa35b7e352"}], 3),
        rec("assistant", [{"type": "text", "text": "The gate took 10.5 s (not 10.4 s) over 35 checks; its log is build/t277/out.log."}], 4),
        rec("user", "and the controls?", 5),
        rec("assistant", [{"type": "text", "text": "Checking the controls now."}], 6),
    ]
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        for r in prows:
            f.write(json.dumps(r) + "\n")
    pg, pspan = extract(f.name), extract(f.name, first=4)
    os.unlink(f.name)
    # run 2026-10-20-1157: a rounded source must be a whole token (not a version) and near (the last 50 records)
    frows = [rec("user", "sizes", 1),
             rec("assistant", [{"type": "tool_use", "id": "f1", "name": "Bash", "input": {"command": "uptime", "description": "up"}}], 2),
             rec("user", [{"type": "tool_result", "tool_use_id": "f1", "content": "load averages: 1.93 2.49 2.57"}], 3)]
    frows += [rec("assistant", [{"type": "text", "text": "Working."}], 4 + i % 50) for i in range(60)]
    frows += [rec("assistant", [{"type": "tool_use", "id": "f2", "name": "Bash", "input": {"command": "git --version", "description": "v"}}], 58),
              rec("user", [{"type": "tool_result", "tool_use_id": "f2", "content": "git version 2.54.0 (Apple Git-157)"}], 59),
              rec("assistant", [{"type": "text", "text": "The file is about 1.9 MB and the step took 2.5 s."}], 59)]
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        for r in frows:
            f.write(json.dumps(r) + "\n")
    fa = next((ln for ln in extract(f.name).split("\n") if " A# " in ln), "")
    os.unlink(f.name)
    pa = next((ln for ln in pg.split("\n") if " A# " in ln), "")
    pat = next((ln for ln in pg.split("\n") if " A@ " in ln), "")
    checks.update({
        "a figure written to fewer decimals than its source is sourced (10.5 from 10.45, #277)": "10.5" not in pa,
        "a figure no source rounds to is still flagged (10.4, #277)": "10.4" in pa,
        "a rounded source far back does not source (1.9 from a load average 60 records earlier, #277)": "1.9" in fa,
        "a version number does not source by rounding (2.5 from git version 2.54.0, #277)": "2.5" in fa,
        "a cited figure past a result line's cut is quoted (A@, #277)": "10.5 <- [2]" in pat and "real 10.45" in pat,
        "a cited path past a result line's cut is quoted (A@, #277)": "build/t277/out.log <- [2]" in pat,
        "a figure inside a hash past the cut is not quoted as its source (A@, #277)": "35 <- " not in pat,
        "a --from span opens with its prelude, every line marked (#277)": pspan.startswith("BEFORE THE SPAN (#277)")
            and "< [0 10:01] M  time the gate" in pspan and "THE SPAN (records 4 on)" in pspan
            and not any(ln.startswith("[") and int(ln[1:].split()[0]) < 4 for ln in pspan.split("\n") if ln[:1] == "["),
        "a span from the start has no prelude (#277)": "BEFORE THE SPAN" not in pg,
    })
    # #262 (14z-205c): a mid-turn maintainer message is a queued_command attachment from a human (beside a queue
    # enqueue), never a user record; a worker's hand-back (peer) and a task notification in the same form are not
    # maintainer messages; an attachment without `origin` counts as a plain prompt; the same text twice is one M line
    def att(prompt, kind=None, mode="prompt", n=0):
        a = {"type": "queued_command", "prompt": prompt, "commandMode": mode}
        if kind:
            a["origin"] = {"kind": kind}
        return {"type": "attachment", "timestamp": f"2026-09-23T11:{n:02d}:00Z", "attachment": a}
    qrows = [
        rec("user", "start the run", 1),
        {"type": "queue-operation", "operation": "enqueue", "timestamp": "2026-09-23T11:02:00Z", "content": "Congratulations, identical Phobos confirmed"},
        att("Congratulations, identical Phobos confirmed", "human", n=2),
        att('<agent-message from="w7">[Subagent hand-back] The report follows:\n  done', "peer", n=3),
        att("<task-notification>\n<task-id>tz1</task-id>\n<status>completed</status>\n</task-notification>", "task-notification", "task-notification", 4),
        att("an older mid-turn message, 9182 rows", None, n=5),
        rec("user", "an older mid-turn message, 9182 rows", 6),
        rec("assistant", [{"type": "text", "text": "Thanks; the 9182 rows are next."}], 7),
        att("Congratulations, identical Phobos confirmed", "human", n=8),   # the same words again, after a reply
    ]
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        for r in qrows:
            f.write(json.dumps(r) + "\n")
    qg = extract(f.name)
    os.unlink(f.name)
    qm = [ln for ln in qg.split("\n") if " M  " in ln]
    checks.update({
        "a mid-turn maintainer message (queued_command, human) is an M line (#262)": "M  [mid-turn] Congratulations, identical Phobos confirmed" in qg,
        "a worker's hand-back and a task notification are not M lines (#262)": not any("Subagent hand-back" in ln or "task-notification" in ln for ln in qm),
        "an attachment without origin counts as a plain prompt, and the same text is ONE M line (#262)":
            sum("older mid-turn message" in ln for ln in qm) == 1,
        "the same words sent again after a reply are a second M line (#262)": sum("identical Phobos confirmed" in ln for ln in qm) == 2,
        "a mid-turn message sources the figures after it (#262)": not any("A# " in ln and "9182" in ln for ln in qg.split("\n")),
    })
    # #263 (14z-205c): a worker figure derived from a file it read (2550 = FIRST_EVENT - 50) stays listed under W#,
    # and W§ quotes the lines its sentence cites from the worker's own read; a figure with no citation gets no W§
    d2 = tempfile.mkdtemp()
    m2 = os.path.join(d2, "s.jsonl")
    with open(m2, "w") as g:
        for r in (rec("user", "go"), rec("assistant", [{"type": "tool_use", "id": "c1", "name": "Agent",
                  "input": {"subagent_type": "measurer", "description": "pins", "prompt": "TASK: where do the pins start?"}}])):
            g.write(json.dumps(r) + "\n")
    os.makedirs(os.path.join(d2, "s", "subagents"))
    with open(os.path.join(d2, "s", "subagents", "agent-w6.meta.json"), "w") as g:
        json.dump({"agentType": "measurer", "toolUseId": "c1"}, g)
    with open(os.path.join(d2, "s", "subagents", "agent-w6.jsonl"), "w") as g:
        for r in ({"type": "assistant", "effort": "high", "message": {"model": "mS", "content": [
                      {"type": "tool_use", "id": "d1", "name": "Read", "input": {"file_path": "/x/build/name_moves.py.txt"}}]}},
                  {"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": "d1",
                      "content": "    76\t# the schedule\n    77\tFIRST_EVENT = 2600\n   699\t        pins.append(f\"{t - 50}:ff8850\")\n"}]}},
                  # two different files named cfg.txt (run 2026-10-21-1160): a citation of cfg.txt:3 quotes neither
                  {"type": "assistant", "effort": "high", "message": {"model": "mS", "content": [
                      {"type": "tool_use", "id": "d2", "name": "Read", "input": {"file_path": "/x/a/cfg.txt"}},
                      {"type": "tool_use", "id": "d3", "name": "Read", "input": {"file_path": "/x/b/cfg.txt"}}]}},
                  {"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": "d2", "content": "     3\tsize = small\n"},
                                                           {"type": "tool_result", "tool_use_id": "d3", "content": "     3\tsize = large\n"}]}},
                  {"type": "assistant", "effort": "high", "message": {"model": "mS", "content": [
                      {"type": "tool_use", "id": "h6", "name": "SubagentHandback",
                       "input": {"message": "FIG first pin = 2550 <- name_moves.py.txt:77, 699. FIG guess = 8123 <- none. "
                                            "FIG gap = 4321 <- name_moves.py.txt:998. FIG size = 5678 <- cfg.txt:3"}}]}}):
            g.write(json.dumps(r) + "\n")
    dg = extract(m2)
    shutil.rmtree(d2)
    dw = next((ln for ln in dg.split("\n") if " W# " in ln), "")
    ds = [ln for ln in dg.split("\n") if " W§ " in ln]
    checks.update({
        "a worker figure derived from a file it read stays listed (#263)": "2550" in dw,
        "...and W§ quotes the lines its sentence cites, from the worker's own read (#263)": len(ds) == 3
            and "2550:" in ds[0] and "name_moves.py.txt:77: FIRST_EVENT = 2600" in ds[0] and "name_moves.py.txt:699:" in ds[0]
            and "t - 50" in ds[0] and ":76:" not in ds[0],
        "a W# figure with no citation gets no W§ (#263)": not any("8123:" in ln for ln in ds),
        "a cited line the worker never read is marked, not dropped (#263)": any("4321:" in ln and "name_moves.py.txt:998: [not in the worker's reads]" in ln for ln in ds),
        "a basename naming two files read quotes neither (#263)": any("5678:" in ln and "2 different files named cfg.txt" in ln and "size =" not in ln for ln in ds),
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
    ap.add_argument("--prelude", type=int, default=PRELUDE_LINES, help="event lines shown before a --from cut (#277; 0: none)")
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
    text = extract(path, a.first, a.last, a.prelude)
    if a.out:
        open(a.out, "w", encoding="utf-8").write(text)
        print(f"wrote {a.out}: {len(text)} characters, {text.count(chr(10))} lines")
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
