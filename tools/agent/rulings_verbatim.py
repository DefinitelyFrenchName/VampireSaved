#!/usr/bin/env python3
"""rulings_verbatim.py — every quote a session ATTRIBUTES to the maintainer is the maintainer's own words, and
every message the maintainer sent is on record (14z-185b, GitHub #190 P2, maintainer-ruled 2026-09-29 "P1+P2,
then P4").

WHY. In the 14z-185 close, rule-checker runs 425, 443, 444 and 445 found rulings quoted only from the session's
own record, a heading quote the maintainer never wrote, a mid-turn message (recorded as a queue enqueue, not a
user record) never recorded, and a ruling with no standing-rulings line. The scratch checks that answered them
hard-coded that session. This is the MECHANISM.

THE MAINTAINER'S OWN WORDS (from the transcripts given): user messages that are not a subagent hand-back, a
task notification, a system reminder, a local-command caveat or the compaction summary; mid-turn messages
(`queue-operation` enqueues, the same filters); and ANSWERS to AskUserQuestion (the text after each `"="` in its
tool result, so the session's own question text never counts). Plus any --source FILE (an issue body the
maintainer wrote, saved locally).

(1) QUOTES. In the record files (default DECISIONS_HISTORY.md and STATE.md), in DECISIONS_HISTORY blocks whose
heading names `(KEY)` and in STATE's `## Session KEY` group, every `*"..."*` is classed by the text just before
it on its line:
  MAINTAINER  a bold label or phrase naming the maintainer or a mid-turn message ("**The maintainer, verbatim:**",
              "the maintainer: ", "**Then, mid-turn, verbatim:**") and not a question label;
  QUESTION    a label naming a question ("**The question, verbatim:**", "asked"): must be the SESSION's own
              question text (an AskUserQuestion question or an assistant message), never checked as the
              maintainer's;
  OTHER       anything else (a doc quote), listed, not checked.
A MAINTAINER quote not found (whitespace collapsed, `\\"` read as `"`) in the maintainer's own words FAILS.
(2) HOMED. Every maintainer message and answer since --since (an ISO time; default: all) must have a quoted
span of at least 5 words (or the whole message when shorter) in a record file, or be named in --exempt FILE
(`<first words of the message><TAB><reason>`, e.g. a status question). Missing FAILS; an exempt row that
matches no message, or has no reason, is STALE and FAILS.

Usage:
  python3 tools/agent/rulings_verbatim.py --key 14z-185b --transcript T.jsonl [--transcript ...]
         [--record FILE ...] [--source FILE ...] [--since ISO] [--exempt FILE]
  python3 tools/agent/rulings_verbatim.py --selftest
"""
import json, os, re, sys, tempfile

NOISE = ("[Subagent hand-back]", "<agent-message", "Another Claude session sent a message", "<task-notification>", "<system-reminder>",
         "This session is being continued", "<local-command-caveat>", "<command-name>", "<local-command-stdout>")
QUOTE = re.compile(r'\*"((?:[^"\\]|\\.)*?)"\*')
MAINT = re.compile(r"(maintainer|mid-turn|side conversation)[^*\n]{0,60}(\*\*|:)\s*[^*]{0,12}$", re.I)
# a quote joined to the previous one ("*"..."*, then, asked X, *"..."*", "*"..."* and *"..."*") is spoken by
# the SAME party as that one — the previous quote's class, never a fresh guess (measured 14z-185b)
CONT = re.compile(r'"\*[,;]?\s*(then|and)\b[^*\n]{0,40}$', re.I)
# a QUESTION is a bold label naming one ("**The question, verbatim:**"), or "asked" IMMEDIATELY before the quote;
# "then, asked who edits, *"..."*" introduces the maintainer's ANSWER (measured 14z-185b: the first form misread it)
QUEST = re.compile(r"\*\*[^*\n]*question[^*\n]*\*\*\s*[^*]{0,12}$|\basked\s*$", re.I)


def norm(s):
    return re.sub(r"\s+", " ", s.replace('\\"', '"')).strip()


def texts_of(content):
    if isinstance(content, str):
        return [content]
    out = []
    for x in content or []:
        if isinstance(x, dict) and x.get("type") == "text":
            out.append(x.get("text", ""))
    return out


def own_words(transcripts, since=None):
    """-> (messages [(ts, text)], answers [(ts, text)], session_texts [text])"""
    msgs, answers, session = [], [], []
    for t in transcripts:
        ask_ids = set()
        for line in open(t, encoding="utf-8", errors="replace"):
            try:
                r = json.loads(line)
            except ValueError:
                continue
            ts = r.get("timestamp", "")
            if since and ts and ts < since:
                continue
            if r.get("type") == "queue-operation" and r.get("operation") == "enqueue":
                c = str(r.get("content", ""))
                if c.strip() and not c.lstrip().startswith(NOISE):
                    msgs.append((ts, c))
                continue
            m = r.get("message") or {}
            content = m.get("content")
            if r.get("type") == "assistant" and isinstance(content, list):
                for x in content:
                    if isinstance(x, dict) and x.get("type") == "tool_use" and x.get("name") == "AskUserQuestion":
                        ask_ids.add(x.get("id"))
                        session.extend(q.get("question", "") for q in x.get("input", {}).get("questions", []))
                    elif isinstance(x, dict) and x.get("type") == "text":
                        session.append(x.get("text", ""))
            if r.get("type") == "user":
                if isinstance(content, list):
                    for x in content:
                        if isinstance(x, dict) and x.get("type") == "tool_result" and x.get("tool_use_id") in ask_ids:
                            body = x["content"] if isinstance(x["content"], str) else " ".join(
                                y.get("text", "") for y in x["content"] if isinstance(y, dict))
                            for a in re.findall(r'"="(.*?)"(?=[.,]\s|\.\s*You|\s*$)', body, re.S):
                                answers.append((ts, a))
                # isMeta marks text the HARNESS injected (skill loads, agent hand-backs, caveats, image captions) —
                # never the maintainer's words, so a quote matching it must not verify (rule-checker 2026-10-04-658 Q4)
                for tx in ([] if r.get("isMeta") else texts_of(content)):
                    if tx.strip() and not tx.lstrip().startswith(NOISE) and "tool_result" not in tx:
                        msgs.append((ts, tx))
    return msgs, answers, session


def record_blocks(path, key):
    t = open(path, encoding="utf-8").read()
    if os.path.basename(path).startswith("DECISIONS_HISTORY"):
        return [b for b in re.split(r"(?m)^(?=## )", t) if re.match(r"## .*\(" + re.escape(key) + r"\)", b)]
    m = re.search(r"(?ms)^## Session " + re.escape(key) + r" .*?(?=^## Session |^# STANDING|\Z)", t)
    return [m.group(0)] if m else []


def classify(before, prev=None):
    tail = before[-90:]
    if prev and CONT.search(tail) and not re.search(r"\basked\s*$", tail) and not re.search(r"\*\*[^*]*question", tail, re.I):
        return prev
    if QUEST.search(tail):
        return "QUESTION"
    if MAINT.search(tail):
        return "MAINTAINER"
    return "OTHER"


def run(key, transcripts, records, sources, since, exempt):
    msgs, answers, session = own_words(transcripts, since)
    words = [norm(t) for _, t in msgs + answers] + [norm(open(s, encoding="utf-8").read()) for s in sources]
    sess = [norm(t) for t in session]
    bad = 0
    record_text = ""
    for rp in records:
        for b in record_blocks(rp, key):
            record_text += b + "\n"
            for line in b.split("\n"):
                prev = None
                for m in QUOTE.finditer(line):
                    q = norm(m.group(1))
                    kind = classify(line[:m.start()], prev)
                    prev = kind
                    if kind == "MAINTAINER":
                        if any(q in w for w in words):
                            print(f"  ok         maintainer: {q[:90]}")
                        else:
                            print(f"  NOT FOUND  quoted as the maintainer's but in none of their messages: {q[:120]}")
                            bad += 1
                    elif kind == "QUESTION":
                        tag = "the session's question" if any(q in s for s in sess) else "a question (not in the transcript's session text)"
                        print(f"  question   {tag}: {q[:90]}")
    rn = norm(record_text.replace('\\"', '"'))
    ex = []
    if exempt:
        for line in open(exempt, encoding="utf-8"):
            if line.strip() and not line.startswith("#"):
                f = line.rstrip("\n").split("\t")
                ex.append((norm(f[0]), f[1].strip() if len(f) > 1 else ""))
    used = set()
    for ts, t in msgs + answers:
        n = norm(t)
        toks = n.split(" ")
        spans = [n] if len(toks) < 5 else [" ".join(toks[i:i + 5]) for i in range(len(toks) - 4)]
        if any(s in rn for s in spans):
            continue
        hit = [i for i, (p, r) in enumerate(ex) if n.startswith(p) and r]
        if hit:
            used.update(hit)
            continue
        print(f"  UNHOMED    {ts[:16]} {n[:110]}")
        bad += 1
    for i, (p, r) in enumerate(ex):
        if i not in used and not any(norm(t).startswith(p) for _, t in msgs + answers) or not r:
            print(f"  STALE      exempt row {p[:60]!r}: " + ("no reason" if not r else "matches no message"))
            bad += 1
    print(f"maintainer messages {len(msgs)}  answers {len(answers)}  failures {bad}")
    return bad


def selftest():
    ok = True
    with tempfile.TemporaryDirectory() as d:
        T = os.path.join(d, "t.jsonl")
        recs = [
            {"type": "user", "timestamp": "2026-01-01T00:00:00Z", "message": {"content": "Freeze the real ranges now please"}},
            {"type": "user", "timestamp": "2026-01-01T00:01:00Z", "message": {"content": "what's the status?"}},
            {"type": "queue-operation", "operation": "enqueue", "timestamp": "2026-01-01T00:02:00Z", "content": "Of note, P3 later too"},
            {"type": "user", "timestamp": "2026-01-01T00:02:30Z", "message": {"content": "<task-notification> x </task-notification>"}},
            {"type": "user", "isMeta": True, "timestamp": "2026-01-01T00:02:40Z", "message": {"content": [{"type": "text", "text": "Base directory for this skill: /x"}]}},
            {"type": "assistant", "timestamp": "2026-01-01T00:03:00Z", "message": {"content": [
                {"type": "tool_use", "id": "q1", "name": "AskUserQuestion", "input": {"questions": [{"question": "Which route should it take?"}]}}]}},
            {"type": "user", "timestamp": "2026-01-01T00:04:00Z", "message": {"content": [
                {"type": "tool_result", "tool_use_id": "q1", "content": 'Your questions have been answered: "Which route should it take?"="Route A, backtested". You can now continue.'}]}},
        ]
        open(T, "w").write("\n".join(json.dumps(r) for r in recs) + "\n")
        D = os.path.join(d, "DECISIONS_HISTORY.md")
        EX = os.path.join(d, "exempt.tsv")
        good = ('## Ruled 2026-01-01 (14z-9) — x\n\n**The question, verbatim:** *"Which route should it take?"*\n\n'
                '**The maintainer, verbatim:** *"Freeze the real ranges now please"*, then *"Route A, backtested"*.\n'
                '**Then, mid-turn, verbatim:** *"Of note, P3 later too"*\n'
                '| row | the maintainer: *"Freeze the real ranges now please"*, then, asked which route, *"Route A, backtested"* |\n')
        cases = [
            ("clean", good, "what's the status\ta status question, not a ruling\n", 0),
            ("altered quote", good.replace("real ranges now", "real ranges later"), "what's the status\ta status question\n", 1),
            ("question as maintainer", good.replace("**The question, verbatim:**", "**The maintainer, verbatim:**"), "what's the status\ta status question\n", 1),
            ("unhomed message", good.replace('**Then, mid-turn, verbatim:** *"Of note, P3 later too"*\n', ""), "what's the status\ta status question\n", 1),
            # two QUESTIONS joined by "and": the second is the session's too, never checked as the maintainer's
            ("two questions joined", good.replace('**The question, verbatim:** *"Which route should it take?"*', '**The questions, verbatim:** *"Which route should it take?"* and *"Is this a session question?"*'),
             "what's the status\ta status question\n", 0),
            # a QUESTION label that also names the maintainer is still the session's question (found dead by
            # test_rulings_verbatim's questions-unseen control, 14z-185b: no case needed question detection)
            ("question label naming the maintainer", good.replace("**The question, verbatim:**", "**The question put to the maintainer, verbatim:**"),
             "what's the status\ta status question\n", 0),
            # text the harness injected (isMeta) quoted as the maintainer's is NOT their words (14z-189, run 658)
            ("harness text as maintainer", good + '**The maintainer, verbatim:** *"Base directory for this skill: /x"*\n',
             "what's the status\ta status question\n", 1),
            ("stale exempt", good, "what's the status\ta status question\nnever sent this\tno such message\n", 1),
            # an ANSWER introduced by "then, asked X," is the maintainer's and is checked
            ("answer after 'then, asked'", good.replace(', then, asked which route, *"Route A, backtested"*', ', then, asked which route, *"Route B, untested"*'),
             "what's the status\ta status question\n", 1),
        ]
        for name, dh, exr, want in cases:
            open(D, "w").write(dh)
            open(EX, "w").write(exr)
            print(f"-- case {name}")
            got = run("14z-9", [T], [D], [], None, EX)
            g = (got == 0) if want == 0 else (got >= 1)
            ok = ok and g
            print(("  ok: " if g else "  FAIL: ") + f"case {name}: {got} failure(s), expected " + ("none" if want == 0 else "at least one"))
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    opt = lambda k: [a[i + 1] for i, x in enumerate(a) if x == k]
    if not opt("--key") or not opt("--transcript"):
        sys.exit(__doc__)
    records = opt("--record") or ["DECISIONS_HISTORY.md", "STATE.md"]
    return 1 if run(opt("--key")[0], opt("--transcript"), records, opt("--source"),
                    (opt("--since") or [None])[0], (opt("--exempt") or [None])[0]) else 0


if __name__ == "__main__":
    sys.exit(main())
