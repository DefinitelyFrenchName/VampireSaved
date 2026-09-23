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

# A DETACHING & is a single & that ends a command: not half of `&&`, not a `>&`/`&>`
# redirect. The first cut (`&\s*$|&\s*echo`) also matched `cmd && echo ...` and counted
# 85 of 14z-174's 97 "detached" calls wrongly (rule-checker run 2026-09-23-97, Q4).
DETACHED = re.compile(r"\bnohup\b|\bsetsid\b|\bdisown\b"
                      r"|(?<![&>|])&(?![&>\d])\s*($|\n|;|\)|echo|wait|sleep|pid=|PID=|P\d?=|\w+=\$!)", re.M)
# TRACKED is read from the tool RESULT, not the call: the harness also tracks a call it
# moved to the background at the 120 s timeout, which `run_in_background` never shows
# (14z-174 had five; the same run's Q1).
TRACKED_RESULT = ("Command running in background with ID:", "moved to the background (ID:")
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
                    if not inp.get("run_in_background") and DETACHED.search(inp.get("command", "")):
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
    """-> [(task_id, started, ended_or_None, form, description)] for every tracked task."""
    start, end, desc, calls = {}, {}, {}, {}
    idre = re.compile(r"\(ID: (\w+)\)|with ID: (\w+)")
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            r = json.loads(line)
        except ValueError:
            continue
        if r.get("isSidechain"):
            continue
        ts = r.get("timestamp")
        m = r.get("message")
        c = m.get("content") if isinstance(m, dict) else None
        if isinstance(c, list):
            for b in c:
                if b.get("type") == "tool_use":
                    inp = b.get("input") or {}
                    cmd = " ".join(str(inp.get("command", "")).split())
                    calls[b.get("id")] = f'{inp.get("description", "")} :: {cmd[:140]}'
                elif b.get("type") == "tool_result":
                    body = json.dumps(b.get("content"))
                    hit = idre.search(body)
                    if hit and any(k in body for k in TRACKED_RESULT):
                        t = hit.group(1) or hit.group(2)
                        start[t] = ts
                        desc[t] = calls.get(b.get("tool_use_id"), "?")
        notes = []
        if isinstance(c, str) and c.lstrip().startswith("<task-notification>"):
            notes.append((c, "idle"))
        att = r.get("attachment") or {}
        if att.get("type") == "queued_command" and "<task-notification>" in str(att.get("prompt")):
            notes.append((str(att["prompt"]), "mid-turn"))
        for text, form in notes:
            k = re.search(r"<task-id>(\w+)</task-id>", text)
            if k and k.group(1) not in end:
                end[k.group(1)] = (ts, form)
    return [(t, start[t], end.get(t, (None, None))[0], end.get(t, (None, "NONE"))[1], desc[t]) for t in start]


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
    got = [(round(g), c) for g, c, _, _ in gaps(recs, 20)]
    want = [(60, "status"), (30, "notif"), (30, "other"), (30, "other")]
    ok = got == want and (det, trk) == (2, 2) and tasks_ok
    print(f"selftest: gaps {got} detached {det} tracked {trk} tasks {tk} -> {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=None)
    ap.add_argument("--last", type=int, default=11)
    ap.add_argument("--skip-newest", type=int, default=1)
    ap.add_argument("--gap", type=float, default=20)
    ap.add_argument("--detail", default=None)
    ap.add_argument("--tasks", default=None)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    d = a.dir or default_dir()
    files = sorted(glob.glob(os.path.join(d, "*.jsonl")), key=os.path.getmtime)
    if not files:
        print(f"no transcripts under {d}", file=sys.stderr)
        return 2
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
