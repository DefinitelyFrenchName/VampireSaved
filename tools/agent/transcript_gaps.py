#!/usr/bin/env python3
"""transcript_gaps.py — the idle-gap census of Claude Code session transcripts (GitHub #172).

For each session transcript (`~/.claude/projects/<project>/<session>.jsonl`), every
gap of GAP minutes or more that BEGAN after the agent's own turn, classified by what
ended it:

  status   the maintainer asked for status ("status", "finished", "landed", ...)
  notif    a <task-notification> (a harness-tracked job or agent finished)
  other    any other message

plus the session's Bash launches: DETACHED (nohup / setsid / disown / a single
command-ending &, invisible to the harness, so no notification can ever arrive) against
TRACKED (a tool result saying the harness runs it in the background — `run_in_background`
or the 120 s timeout — which notifies on completion).

This is the measurement `docs/project/agent_architecture_scope.md` §1 quotes. The
gap minutes ended by a status question are an UPPER BOUND on waste, not the waste:
part of each gap was a job genuinely still running.

Usage:
  python3 tools/agent/transcript_gaps.py [--dir DIR] [--last N] [--skip-newest K]
                                         [--gap MIN] [--detail SESSION_PREFIX]

  --dir          the transcript directory (default: this project's, derived from cwd)
  --last N       the N newest transcripts, after skipping (default 11)
  --skip-newest  skip the K newest (default 1: the running session's own transcript)
  --detail P     list every gap of the one session whose id starts with P
  --tasks P      list every harness-tracked task of that session, from its move to the
                 background to its completion notification, in EITHER form: a user message
                 (the agent idle) or a `queued_command` attachment (it arrived mid-turn) —
                 parsing only the first form reports finished tasks as never notified
  --detached P   every DETACHED launch of that session (record index, description, the
                 matching span) — the itemised list the scope doc's §1 reads one by one
  --refusals P   every refusal of that session: a C0.1 hook denial (with the command it
                 refused) and a permission-rule denial of an edit (the C0.4 lock)
  --classifier-audit  every non-background Bash command of the selected sessions through
                 the shared classifier AND the census's previous pattern; prints the four agreement
                 counts and, for every command the classifier clears that the first cut
                 flagged, the reason it clears (the S1 validation, scope doc §4)
  --c02          the two deterministic C0.2 candidates over the selected sessions: tracked
                 tasks finished and never read after, and turn ends that promise a wait
                 while no tracked task runs (why C0.2 moved to C1, scope doc §4)
  --selftest     classify a synthetic transcript with known answers and exit

Reads only; writes nothing. Stdlib only (no numpy on this Mac).
"""
import argparse
import datetime
import glob
import json
import os
import re
import sys
import tempfile

# DETACHED and TRACKED come from the ONE classifier the hooks use (agentlib), so the
# census and the hooks cannot disagree. History: a first cut here (`&\s*$|&\s*echo`)
# counted `cmd && echo ...` as detached — 85 of 14z-174's 97 (rule-checker run
# 2026-09-23-97, Q4); a second counted `a & b & wait` (a foreground parallel run).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import agentlib  # noqa: E402

TRACKED_RESULT = agentlib.TRACKED_RESULT
STATUS = re.compile(r"status|finished|landed|done yet|still running|progress", re.I)
# a status QUESTION is short: 14z-174's one long message quoting the agent's own
# sentence back ("... not polling my own background work") matched the keywords and
# is not one. 80 characters holds every status question in the corpus.
STATUS_MAXLEN = 80


def default_dir():
    cwd = os.getcwd()
    return os.path.expanduser("~/.claude/projects/" + re.sub(r"[^A-Za-z0-9]", "-", cwd))


def parse(path):
    """-> (records, detached, tracked); records = [(time, kind, text)] of the MAIN thread."""
    recs, det, trk = [], 0, 0
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            r = json.loads(line)
        except ValueError:
            continue
        if r.get("isSidechain"):
            continue
        m = r.get("message") or {}
        c = m.get("content") if isinstance(m, dict) else None
        if isinstance(c, list):
            for b in c:
                if b.get("type") == "tool_use" and b.get("name") == "Bash":
                    inp = b.get("input") or {}
                    if not inp.get("run_in_background") and agentlib.detach_reason(str(inp.get("command", ""))):
                        det += 1
                elif b.get("type") == "tool_result":
                    body = json.dumps(b.get("content"))
                    if any(k in body for k in TRACKED_RESULT):
                        trk += 1
        ts = r.get("timestamp")
        if not ts or r.get("type") not in ("assistant", "user"):
            continue
        t = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))
        text = ""
        if r["type"] == "user":
            if isinstance(c, str):
                text = c
            elif isinstance(c, list) and not any(b.get("type") == "tool_result" for b in c):
                tx = [b for b in c if b.get("type") == "text"]
                text = tx[0]["text"] if tx else ""
        recs.append((t, r["type"], text))
    recs.sort(key=lambda x: x[0])
    return recs, det, trk


def gaps(recs, gap_min):
    """-> [(minutes, cls, start, ender_text)] for gaps that began after the agent's turn."""
    out = []
    for i in range(1, len(recs)):
        g = (recs[i][0] - recs[i - 1][0]).total_seconds() / 60
        if g >= gap_min and recs[i - 1][1] == "assistant":
            tx = recs[i][2]
            if "<task-notification>" in tx:
                cls = "notif"
            elif STATUS.search(tx) and len(tx.strip()) <= STATUS_MAXLEN:
                cls = "status"
            else:
                cls = "other"
            out.append((g, cls, recs[i - 1][0], tx))
    return out


def tasks(path):
    """-> [(task_id, started, ended_or_None, form, description)] — agentlib.tasks, the
    ONE parser the C0.2 hook uses (both notification forms)."""
    return [(t["id"], t["started"], t["ended"], t["form"] or "NONE",
             f'{t["description"]} :: {" ".join(t["command"].split())[:140]}')
            for t in agentlib.tasks(path)]


# the census's PREVIOUS pattern (written after rule-checker run 2026-09-23-97, replaced
# by agentlib when S1 began), kept only so --classifier-audit reproduces the comparison
# the scope doc quotes (never used to count anything)
FIRST_CUT = re.compile(r"\bnohup\b|\bsetsid\b|\bdisown\b"
                       r"|(?<![&>|])&(?![&>\d])\s*($|\n|;|\)|echo|wait|sleep|pid=|PID=|P\d?=|\w+=\$!)", re.M)
PROMISE = re.compile(r"\b(I'?ll|I will|will)\s+(poll|check back|report (back|when|once)|come back|"
                     r"keep (an eye|polling|watching)|let you know|update you|wait for|be notified|"
                     r"get a notification|notify)|\b(when|once) it (lands|finishes|completes|is done)|"
                     r"\bstill running\b|\bin the background\b", re.I)


def classifier_audit(files):
    import collections
    tot, why = collections.Counter(), collections.Counter()
    for f in files:
        for _, r in agentlib.records(f):
            c = agentlib._content(r)
            if not isinstance(c, list):
                continue
            for b in c:
                if b.get("type") != "tool_use" or b.get("name") != "Bash":
                    continue
                inp = b.get("input") or {}
                if inp.get("run_in_background"):
                    continue
                cmd = str(inp.get("command", ""))
                old, new = bool(FIRST_CUT.search(cmd)), bool(agentlib.detach_reason(cmd))
                tot[("first" if old else "-") + "/" + ("shared" if new else "-")] += 1
                if old and not new:
                    body = agentlib._QUOTED.sub("''", agentlib.strip_heredocs(cmd))
                    if not FIRST_CUT.search(agentlib.strip_heredocs(cmd)):
                        why["inside a heredoc body"] += 1
                    elif not FIRST_CUT.search(body):
                        why["inside a quoted string"] += 1
                    elif agentlib._WAIT.search(body):
                        why["& ... wait (foreground parallel)"] += 1
                    elif "&&" in cmd:
                        why["&& chain"] += 1
                    else:
                        why["UNEXPLAINED"] += 1
    print(f"commands {sum(tot.values())}: both flag {tot['first/shared']}, neither {tot['-/-']}, "
          f"shared-only {tot['-/shared']}, previous-only {tot['first/-']}")
    for k, v in why.most_common():
        print(f"  previous-only, cleared because {k}: {v}")
    return 1 if tot["-/shared"] or why["UNEXPLAINED"] else 0


def c02(files):
    for f in files:
        recs = list(agentlib.records(f))
        ts = agentlib.tasks(f)
        unread = [t for t in ts if t["end_n"] is not None and not t["read_after"]]
        ends = []
        for i, (n, r) in enumerate(recs):
            c = agentlib._content(r)
            if r.get("type") != "assistant" or not isinstance(c, list):
                continue
            if any(b.get("type") == "tool_use" for b in c) or not any(b.get("type") == "text" for b in c):
                continue
            nxt = next((q for _, q in recs[i + 1:] if q.get("type") in ("user", "assistant")), None)
            if nxt and nxt.get("type") == "user":
                ends.append((n, " ".join(b["text"] for b in c if b.get("type") == "text")))
        prom = [(n, t) for n, t in ends if PROMISE.search(t)]
        bare = [n for n, _ in prom
                if not [t for t in ts if t["start_n"] < n and (t["end_n"] is None or t["end_n"] > n)]]
        longest = max(((agentlib_minutes(t)), t["id"]) for t in ts) if ts else (0, "-")
        print(f"{os.path.basename(f)[:8]}  tracked {len(ts):3}  finished-unread {len(unread):3}  "
              f"promise-ends {len(prom):3}  promise-with-nothing-tracked {len(bare):3}  "
              f"longest task {longest[0]:.0f} min ({longest[1]})")
    return 0


def agentlib_minutes(t):
    if not t["ended"]:
        return 0.0
    iso = lambda x: datetime.datetime.fromisoformat(x.replace("Z", "+00:00"))
    return (iso(t["ended"]) - iso(t["started"])).total_seconds() / 60


def selftest():
    t0 = datetime.datetime(2026, 9, 21, 8, 0, tzinfo=datetime.timezone.utc)

    def rec(minute, kind, content):
        return {"type": kind, "timestamp": (t0 + datetime.timedelta(minutes=minute)).isoformat(),
                "message": {"content": content}}
    rows = [
        rec(0, "user", "go"),
        rec(1, "assistant", [{"type": "tool_use", "name": "Bash", "input": {"command": "nohup x.sh > l &"}}]),
        rec(1, "assistant", [{"type": "tool_use", "name": "Bash", "input": {"command": "z.sh > l 2>&1 & echo $!"}}]),
        # must stay QUIET: && chains, a >& redirect, a trailing && continuation
        rec(1, "assistant", [{"type": "tool_use", "name": "Bash", "input": {"command": "a && echo ok || echo no"}}]),
        rec(1, "assistant", [{"type": "tool_use", "name": "Bash", "input": {"command": "b > l 2>&1; c &> m"}}]),
        rec(1, "assistant", [{"type": "tool_use", "name": "Bash", "input": {"command": "d &&\n e"}}]),
        rec(1, "assistant", [{"type": "tool_use", "name": "Bash", "input": {"command": "f a & f b & wait; echo done"}}]),
        rec(1, "assistant", [{"type": "tool_use", "name": "Bash", "input": {"command": "cat > s.sh <<'EOF'\nx & y\nEOF\nsh s.sh"}}]),
        rec(2, "assistant", [{"type": "tool_use", "name": "Bash", "input": {"command": "y.sh", "run_in_background": True}}]),
        rec(2, "user", [{"type": "tool_result", "content": "Command running in background with ID: b1. Output is being written to: /t/b1.output"}]),
        rec(2, "user", [{"type": "tool_result", "content": "Command did not complete within its 120s timeout and was moved to the background (ID: b2)."}]),
        rec(3, "assistant", [{"type": "text", "text": "I'll poll it."}]),
        rec(63, "user", "what's the status?"),           # 60 min, status
        rec(64, "assistant", [{"type": "text", "text": "ok"}]),
        rec(94, "user", "<task-notification><status>completed</status></task-notification>"),  # 30, notif
        rec(95, "assistant", [{"type": "text", "text": "read"}]),
        rec(100, "user", "next"),                          # 5 min: below the threshold
        rec(101, "assistant", [{"type": "text", "text": "x"}]),
        rec(131, "user", "new topic"),                     # 30, other
        rec(132, "assistant", [{"type": "text", "text": "y"}]),
        rec(162, "user", "The idling I have no excuse for beyond not polling; it finished long ago and nobody noticed at all."),  # 30, other (long)
    ]
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")
    recs, det, trk = parse(f.name)
    os.unlink(f.name)
    with open(f.name + ".t", "w") as g:
        for r in rows + [
            rec(3, "user", [{"type": "tool_result", "tool_use_id": "x",
                             "content": "Command running in background with ID: b3. Output ..."}]),
            {"type": "attachment", "timestamp": (t0 + datetime.timedelta(minutes=4)).isoformat(),
             "attachment": {"type": "queued_command", "prompt": "<task-notification> <task-id>b3</task-id>"}},
            rec(9, "user", "<task-notification> <task-id>b1</task-id> <status>completed</status>"),
        ]:
            g.write(json.dumps(r) + "\n")
    tk = {t: form for t, _, _, form, _ in tasks(f.name + ".t")}
    os.unlink(f.name + ".t")
    tasks_ok = tk == {"b1": "idle", "b2": "NONE", "b3": "mid-turn"}
    # the audit's must-fire plant: `a & b` is a detach the PREVIOUS pattern cannot see,
    # so an audit over it must exit non-zero; a clean `&&` alone must exit zero
    import contextlib, io
    audit_ok = True
    for cmd, want in (("a & b", 1), ("a && b", 0)):
        with open(f.name + ".a", "w") as g:
            g.write(json.dumps(rec(0, "assistant", [{"type": "tool_use", "name": "Bash", "input": {"command": cmd}}])) + "\n")
        with contextlib.redirect_stdout(io.StringIO()):
            rc = classifier_audit([f.name + ".a"])
        os.unlink(f.name + ".a")
        audit_ok = audit_ok and rc == want
    got = [(round(g), c) for g, c, _, _ in gaps(recs, 20)]
    want = [(60, "status"), (30, "notif"), (30, "other"), (30, "other")]
    ok = got == want and (det, trk) == (2, 2) and tasks_ok and audit_ok
    print(f"selftest: gaps {got} detached {det} tracked {trk} tasks {tk} audit-plant {'fires' if audit_ok else 'DEAD'} -> {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=None)
    ap.add_argument("--last", type=int, default=11)
    ap.add_argument("--skip-newest", type=int, default=1)
    ap.add_argument("--gap", type=float, default=20)
    ap.add_argument("--detail", default=None)
    ap.add_argument("--tasks", default=None)
    ap.add_argument("--classifier-audit", action="store_true")
    ap.add_argument("--c02", action="store_true")
    ap.add_argument("--detached", default=None)
    ap.add_argument("--refusals", default=None)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    d = a.dir or default_dir()
    files = sorted(glob.glob(os.path.join(d, "*.jsonl")), key=os.path.getmtime)
    if not files:
        print(f"no transcripts under {d}", file=sys.stderr)
        return 2
    if a.refusals:
        hit = [f for f in files if os.path.basename(f).startswith(a.refusals)]
        if len(hit) != 1:
            print(f"--refusals {a.refusals}: {len(hit)} matches", file=sys.stderr)
            return 2
        calls = {}
        for n, r in agentlib.records(hit[0]):
            c = agentlib._content(r)
            if not isinstance(c, list):
                continue
            for b in c:
                if b.get("type") == "tool_use":
                    calls[b.get("id")] = (b.get("name"), b.get("input") or {})
                elif b.get("type") == "tool_result":
                    body = json.dumps(b.get("content"))
                    name, inp = calls.get(b.get("tool_use_id"), ("?", {}))
                    what = " ".join(str(inp.get("command") or inp.get("file_path") or "").split())[:110]
                    if "hook error: C0.1" in body:
                        print(f"{str(r.get('timestamp'))[:16]}Z  #{n}  C0.1 DENIED {name}: {what}")
                    elif "denied by your permission settings" in body:
                        print(f"{str(r.get('timestamp'))[:16]}Z  #{n}  EDIT-LOCK REFUSED {name}: {what}")
        return 0
    if a.detached:
        hit = [f for f in files if os.path.basename(f).startswith(a.detached)]
        if len(hit) != 1:
            print(f"--detached {a.detached}: {len(hit)} matches", file=sys.stderr)
            return 2
        for n, r in agentlib.records(hit[0]):
            c = agentlib._content(r)
            if not isinstance(c, list):
                continue
            for b in c:
                if b.get("type") == "tool_use" and b.get("name") == "Bash":
                    inp = b.get("input") or {}
                    cmd = str(inp.get("command", ""))
                    if not inp.get("run_in_background") and agentlib.detach_reason(cmd):
                        m = (re.search(r"\b(nohup|setsid|disown)\b.{0,70}", cmd, re.S)
                             or re.search(r".{0,50}&", cmd, re.S))
                        span = " ".join((m.group(0) if m else cmd[:70]).split())
                        print(f"{str(r.get('timestamp'))[:16]}Z  #{n}  {inp.get('description', '')[:55]:55} | {span}")
        return 0
    if a.tasks:
        hit = [f for f in files if os.path.basename(f).startswith(a.tasks)]
        if len(hit) != 1:
            print(f"--tasks {a.tasks}: {len(hit)} matches", file=sys.stderr)
            return 2
        iso = lambda x: datetime.datetime.fromisoformat(x.replace("Z", "+00:00"))
        for t, st, en, form, d in tasks(hit[0]):
            dur = f"{(iso(en) - iso(st)).total_seconds() / 60:.0f} min" if en else "no notification"
            print(f"{t}  {st[:16]}Z  {dur:>16}  notified {form:8}  {d}")
        return 0
    if a.detail:
        hit = [f for f in files if os.path.basename(f).startswith(a.detail)]
        if len(hit) != 1:
            print(f"--detail {a.detail}: {len(hit)} matches", file=sys.stderr)
            return 2
        recs, det, trk = parse(hit[0])
        for g, c, start, tx in gaps(recs, a.gap):
            print(f"{g:6.0f} min  {c:6}  from {start:%Y-%m-%d %H:%M}Z  ended by: {tx[:90]!r}")
        return 0
    sel = files[:len(files) - a.skip_newest] if a.skip_newest else files
    sel = sel[-a.last:]
    if a.classifier_audit:
        return classifier_audit(sel)
    if a.c02:
        return c02(sel)
    print(f"transcripts: {d}  (gap >= {a.gap:g} min; newest {a.skip_newest} skipped)")
    print(f"{'session':10} {'start (UTC)':16} {'gaps':>5} {'status':>6} {'notif':>5} {'other':>5} "
          f"{'status-min':>10} {'detached':>8} {'tracked':>7}")
    for f in sel:
        recs, det, trk = parse(f)
        if not recs:
            continue
        gs = gaps(recs, a.gap)
        n = {k: sum(1 for _, c, _, _ in gs if c == k) for k in ("status", "notif", "other")}
        smin = sum(g for g, c, _, _ in gs if c == "status")
        print(f"{os.path.basename(f)[:8]:10} {recs[0][0]:%Y-%m-%d %H:%M} {len(gs):5} {n['status']:6} "
              f"{n['notif']:5} {n['other']:5} {smin:10.0f} {det:8} {trk:7}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
