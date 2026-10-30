#!/usr/bin/env python3
"""session_metrics.py — where a session's work went, every figure labelled by its CLASS (GitHub #264).

Reads, READ-ONLY, what the work already wrote, and emits the datasets of the session dashboard
(the Claude dashboard "Vampire Saved Session Ledger"). Every figure carries {value, class, source, rule}:

  MEASURED      read directly from a record the work itself wrote (a ledger row, a run record, a commit)
  DERIVED       arithmetic on measured figures; `rule` is the formula
  ESTIMATED     a heuristic classification of measured data; `rule` is the heuristic, and it can be wrong
  INFERRED      a judgement about meaning (a cause, a category); `rule` says how it was judged
  EXTRAPOLATED  a projection beyond the data or a backfill
This tool emits NO INFERRED and NO EXTRAPOLATED figure. A first cut classed each re-check's CAUSE by keywords in
its resolution text and was dropped before landing: sampled, it read a count of "18 modes" as a control
problem. Re-checks are counted by the rule-checker QUESTION that failed (MEASURED, named as
docs/project/rule_checker.md words it), and each run's resolution text is in rc_runs.json as written.

A figure the sources do not hold is ABSENT, never filled in (a session with no transcript id on record
has no transcript figures; a worker transcript with no usage field adds no tokens).

THE SOURCES (each figure names its own):
  tests/rulecheck/ledger.tsv                every rule-checker run, keyed by its `session` column; its ACTIONS (#335) —
                                            a run and its re-checks — linked by tools/rc_actions.py, which reads
  tests/rulecheck/runs/*/meta.tsv           the action a run records (prepare, since 14z-212), and NOT-RUN.txt
  build/static_runs/<UTC>_<pid>/            each static tier run: results.tsv, results.controls.tsv,
                                            run_record_start/end.json (untracked; present on the host that ran it)
  git log                                   commits whose subject starts with the key and ':' or ' '
                                            (the key EXACTLY: 14z-185 never counts 14z-185b's commits)
  STATE.md, STATE_HISTORY.md                the session's heading (its transcript id) and its findings row
  tests/rulecheck/retractions/<key>.tsv     the wordings the session retracted
  docs/project/tickets.tsv                  the tickets whose `sessions` column names the key
  the session transcript (+ subagents/)     timestamps, maintainer messages, tool calls, token usage, workers.
                                            Found by the id on the session's STATE heading (MEASURED); else the
                                            transcript whose span holds the most of the session's commits, given
                                            only when no other session's commits claim it (DERIVED). The ledger's
                                            `session` column holds that id instead of the key on some rows (the
                                            procedure runs of 14z-180 to 14z-187b): those rows count too.

Usage:
  python3 tools/session_metrics.py collect --keys 14z-188..14z-197 --out DIR
        [--repo .] [--projects DIR] [--transcript KEY=PATH ...] [--static-runs DIR]
      writes DIR/figures.json, DIR/rc_runs.json, DIR/tiers.json, DIR/costly.json, DIR/actions.json (row objects,
      the dashboard's datasets; actions.json, #335: one row per rule-checker action, its first run and verdict) and prints one line per session. --keys takes a range (A..B, by the
      number then the suffix) or a comma list; a range spans every key the ledger, git or STATE
      knows in it.
  python3 tools/session_metrics.py check DIR
      every figure has a class among the five, a source, and (unless MEASURED) a rule; exit 1 if not.

Gate: tests/test_session_metrics.sh (a synthetic repository with known answers, and its controls).
Written 14z-198.
"""
import argparse, glob, json, os, re, statistics, subprocess, sys
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "agent"))
sys.path.insert(0, HERE)
from findings_table import read_state   # a TSV-backed findings section reads as its row (#282 item C)
from rulings_verbatim import own_words  # noqa: E402  the maintainer-message reader the close already trusts
from transcript_gaps import subagents  # noqa: E402  the worker reader the close's --cap already trusts
import rc_actions  # noqa: E402  which rule-checker runs are one action, and its first run (#335)

CLASSES = ("MEASURED", "DERIVED", "ESTIMATED", "INFERRED", "EXTRAPOLATED")
ACTIVE_GAP_S = 300          # ESTIMATED active time: a gap between two records counts only up to this
KEY_RE = re.compile(r"^(14z-(\d+)([a-z]?))$")
LEDGER = "tests/rulecheck/ledger.tsv"
# the rule-checker's questions, named as docs/project/rule_checker.md words them (Q1-Q5 "evidence", QP1-QP5 "procedure")
QUESTIONS = {"Q1": "stated basis", "Q2": "capture", "Q3": "shared premise", "Q4": "control for this failure",
             "Q5": "decision source", "QP1": "said vs done", "QP2": "claimed vs run", "QP3": "measured, not inferred",
             "QP4": "accounted", "QP5": "spec conformance"}


def key_sort(k):
    m = KEY_RE.match(k)
    return (int(m.group(2)), m.group(3)) if m else (10 ** 9, k)


def fig(rows, session, section, metric, label, value, unit, cls, source, rule=""):
    assert cls in CLASSES, cls
    if value is None:
        return
    rows.append({"session": session, "section": section, "metric": metric, "label": label,
                 "value": value, "unit": unit, "class": cls, "source": source, "rule": rule})


def ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def utc(iso):
    """an ISO time with any offset -> 'YYYY-MM-DDTHH:MM:SS' in UTC, comparable with transcript timestamps"""
    return ts(iso).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")


# ---------------------------------------------------------------- sources

def read_ledger(repo):
    out = []
    p = os.path.join(repo, LEDGER)
    if not os.path.exists(p):
        return out
    cols = None
    for line in open(p, encoding="utf-8"):
        if line.startswith("#") or not line.strip():
            continue
        f = line.rstrip("\n").split("\t")
        if cols is None:
            cols = f
            continue
        out.append(dict(zip(cols, f)))
    return out


def git_commits(repo):
    """-> [(key, sha, iso, files, ins, dels)] for every commit whose subject starts with a session key"""
    r = subprocess.run(["git", "-C", repo, "log", "--no-merges", "--shortstat", "--format=@@%H\t%cI\t%s"],
                       capture_output=True, text=True, check=True).stdout
    out, cur = [], None
    for line in r.splitlines():
        if line.startswith("@@"):
            sha, iso, subj = line[2:].split("\t", 2)
            m = re.match(r"(14z-\d+[a-z]?)[: ]", subj)
            cur = [m.group(1), sha, iso, 0, 0, 0] if m else None
            if cur:
                out.append(cur)
        elif cur and "changed" in line:
            for n, what in re.findall(r"(\d+) (file|insertion|deletion)", line):
                cur[{"file": 3, "insertion": 4, "deletion": 5}[what]] += int(n)
    return [tuple(c) for c in out]


def state_sections(repo):
    """-> {key: (path, heading line no., section text)} from STATE.md then STATE_HISTORY.md"""
    out = {}
    for name in ("STATE.md", "STATE_HISTORY.md"):
        p = os.path.join(repo, name)
        if not os.path.exists(p):
            continue
        lines = read_state(p, repo).split("\n")
        starts = [(i, re.match(r"## Session (14z-\d+[a-z]?)\b", l)) for i, l in enumerate(lines)]
        starts = [(i, m.group(1)) for i, m in starts if m]
        for j, (i, k) in enumerate(starts):
            end = starts[j + 1][0] if j + 1 < len(starts) else len(lines)
            out.setdefault(k, (name, i + 1, "\n".join(lines[i:end])))
    return out


def findings_count(section):
    """the findings row's lettered items, counted a, b, c ... until a letter is missing"""
    row = next((l for l in section.split("\n") if re.match(r"\| \*\*\(\d+\) THE FINDINGS TABLE", l)), None)
    if row is None:
        return None
    seen = set(re.findall(r"(?:\| |; )\(([a-z])\) ", row))
    n = 0
    while chr(ord("a") + n) in seen:
        n += 1
    return n


def static_runs(d):
    out = []
    for run in sorted(glob.glob(os.path.join(d, "*_*"))):
        res = os.path.join(run, "results.tsv")
        if not os.path.exists(res):
            continue
        name = os.path.basename(run)
        try:
            start = datetime.strptime(name.split("_")[0], "%Y%m%dT%H%M%SZ").strftime("%Y-%m-%dT%H:%M:%SZ")
        except ValueError:
            continue
        head, args, gates = "", "", []
        for line in open(res, encoding="utf-8"):
            if line.startswith("# head "):
                head = line.split()[2]
            elif line.startswith("# args"):
                args = line[len("# args"):].strip()
            elif not line.startswith("#") and line.strip():
                f = line.rstrip("\n").split("\t")
                if len(f) >= 3 and f[2].lstrip("-").isdigit():
                    gates.append((f[0], f[1], int(f[2])))
        ctls = []
        cp = os.path.join(run, "results.controls.tsv")
        if os.path.exists(cp):
            for line in open(cp, encoding="utf-8"):
                f = line.rstrip("\n").split("\t")
                if not line.startswith("#") and len(f) >= 4 and f[3].lstrip("-").isdigit():
                    ctls.append((f[0], f[1], f[2], int(f[3])))
        wall = None
        try:
            a = json.load(open(os.path.join(run, "run_record_start.json")))["utc"]
            b = json.load(open(os.path.join(run, "run_record_end.json")))["utc"]
            wall = int((ts(b) - ts(a)).total_seconds())
        except (OSError, ValueError, KeyError):
            pass
        out.append({"run": name, "start": start, "head": head, "args": args, "gates": gates,
                    "controls": ctls, "wall": wall, "path": os.path.relpath(run)})
    return out


def transcript_figures(path):
    recs = []
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            recs.append(json.loads(line))
        except ValueError:
            pass
    stamps = sorted(r["timestamp"] for r in recs if r.get("timestamp"))
    if not stamps:
        return None
    t = [ts(s) for s in stamps]
    active = sum(min((b - a).total_seconds(), ACTIVE_GAP_S) for a, b in zip(t, t[1:]))
    msgs, answers, _ = own_words([path])
    seen, uniq = set(), []
    for at, text in sorted(msgs):
        k = re.sub(r"\s+", " ", text).strip()
        if k not in seen:
            seen.add(k)
            uniq.append((at, k))
    # reply latency: a maintainer message whose previous assistant record ended a turn (text, no tool call)
    lat, last_end = [], None
    by_ts = sorted((r for r in recs if r.get("timestamp")), key=lambda r: r["timestamp"])
    msg_ts = {at for at, _ in uniq}
    for r in by_ts:
        if r.get("type") == "assistant":
            c = (r.get("message") or {}).get("content") or []
            kinds = {x.get("type") for x in c if isinstance(x, dict)}
            last_end = r["timestamp"] if ("text" in kinds and "tool_use" not in kinds) else None
        elif r["timestamp"] in msg_ts and last_end:
            lat.append((ts(r["timestamp"]) - ts(last_end)).total_seconds())
            last_end = None
    tools, bg, usage = {}, 0, {}
    for r in recs:
        if r.get("type") != "assistant":
            continue
        m = r.get("message") or {}
        for x in m.get("content") or []:
            if isinstance(x, dict) and x.get("type") == "tool_use":
                tools[x.get("name")] = tools.get(x.get("name"), 0) + 1
                if (x.get("input") or {}).get("run_in_background"):
                    bg += 1
        if m.get("id") and isinstance(m.get("usage"), dict):
            usage[m["id"]] = m["usage"]          # one assistant message spans several records: keep it once
    tok = lambda f: sum(int(u.get(f) or 0) for u in usage.values())
    workers = subagents(path)
    wtok_out = 0
    for meta in glob.glob(path[:-len(".jsonl")] + "/subagents/*.jsonl"):
        wu = {}
        for line in open(meta, encoding="utf-8", errors="replace"):
            try:
                r = json.loads(line)
            except ValueError:
                continue
            m = r.get("message") or {}
            if r.get("type") == "assistant" and m.get("id") and isinstance(m.get("usage"), dict):
                wu[m["id"]] = m["usage"]
        wtok_out += sum(int(u.get("output_tokens") or 0) for u in wu.values())
    return {"first": stamps[0], "last": stamps[-1], "span_s": (t[-1] - t[0]).total_seconds(), "active_s": active,
            "messages": len(uniq), "answers": len(answers), "latency": lat, "tools": tools, "bg": bg,
            "out_tok": tok("output_tokens"), "in_tok": tok("input_tokens") + tok("cache_creation_input_tokens")
            + tok("cache_read_input_tokens"), "assistant_msgs": len(usage), "workers": workers,
            "worker_out_tok": wtok_out}


# ---------------------------------------------------------------- collect

def transcript_spans(projects):
    """-> {path: (first, last)} for every top-level transcript, read from its head and tail only"""
    out = {}
    for p in glob.glob(os.path.join(projects, "*.jsonl")):
        first = last = None
        with open(p, "rb") as f:
            for line in f:
                m = re.search(rb'"timestamp":\s*"([^"]+)"', line)
                if m:
                    first = m.group(1).decode()
                    break
            f.seek(max(0, os.path.getsize(p) - 262144))
            for m in re.finditer(rb'"timestamp":\s*"([^"]+)"', f.read()):
                last = max(last or "", m.group(1).decode())
        if first and last:
            out[p] = (first, last)
    return out


def map_transcripts(keys, sections, commits, projects):
    """-> {key: (path, how)}: the STATE heading's transcript id where recorded (MEASURED); otherwise the
    transcript whose span holds the most of the key's commits (DERIVED), and only when no other key claims it"""
    spans = transcript_spans(projects)
    out, claims = {}, {}
    for key in keys:
        sec = sections.get(key)
        m = re.search(r"transcript `([0-9a-f]{8})", sec[2].split("\n", 1)[0]) if sec else None
        if m:
            hits = [p for p in spans if os.path.basename(p).startswith(m.group(1))]
            if len(hits) == 1:
                out[key] = (hits[0], "MEASURED")
                claims.setdefault(hits[0], []).append(key)
            continue
        times = [utc(c[2]) for c in commits if c[0] == key]
        inside = lambda p: sum(spans[p][0][:19] <= t <= spans[p][1][:19] for t in times)
        best = max(spans, key=inside, default=None) if times else None
        if best and inside(best):
            out[key] = (best, "DERIVED")
            claims.setdefault(best, []).append(key)
    shared = {p for p, ks in claims.items() if len(ks) > 1}
    return {k: v for k, v in out.items() if v[0] not in shared or v[1] == "MEASURED"}, shared, spans


PREPARED = re.compile(r"prepared run (\d{4}-\d\d-\d\d-\d+)")


def prepare_times(projects):
    """-> {run id: UTC time} — when `rulecheck prepare` printed "prepared run <id>", read from every session transcript
    and worker transcript under `projects` (#335 item, 14z-212: hours to pass). A run prepared twice keeps its first."""
    out = {}
    for f in glob.glob(os.path.join(projects, "*.jsonl")) + glob.glob(os.path.join(projects, "*", "subagents", "*.jsonl")):
        for line in open(f, encoding="utf-8", errors="replace"):
            if "prepared run 20" not in line:
                continue
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if d.get("type") != "user" or not d.get("timestamp"):
                continue
            c = d.get("message", {}).get("content")
            for m in PREPARED.finditer(c if isinstance(c, str) else json.dumps(c)):
                t = utc(d["timestamp"])
                if m.group(1) not in out or t < out[m.group(1)]:
                    out[m.group(1)] = t
    return out


def keys_in(spec, known):
    if ".." in spec:
        a, b = spec.split("..")
        lo, hi = key_sort(a), key_sort(b)
        return sorted((k for k in known if lo <= key_sort(k) <= hi), key=key_sort)
    return [k.strip() for k in spec.split(",") if k.strip()]


def chain_key(subject):
    s = re.split(r" — | -- ", subject, 1)[0]
    return re.sub(r"\b(?:run|runs) [\d\-–, ]+|\(.*?\)", "", s).strip().lower()[:80]


def collect(a):
    repo = a.repo
    ledger = read_ledger(repo)
    commits = git_commits(repo)
    sections = state_sections(repo)
    runs = static_runs(a.static_runs)
    known = {r["session"] for r in ledger} | {c[0] for c in commits} | set(sections)
    keys = keys_in(a.keys, {k for k in known if KEY_RE.match(k)})
    tmap = {k: (p, "MEASURED") for k, p in (x.split("=", 1) for x in a.transcript)}
    mapped, shared, _ = map_transcripts([k for k in keys if k not in tmap], sections, commits, a.projects)
    figures, rc_rows, tier_rows, costly, act_rows = [], [], [], [], []
    acts = rc_actions.actions(ledger, rc_actions.metas(repo, ledger))   # over the WHOLE ledger: a link may cross sessions
    notrun = rc_actions.not_run(repo)
    ptimes = prepare_times(a.projects)
    for x in acts:   # hours from the action's first packet to the one that passed (both prepare times on record)
        t0, t1 = ptimes.get(x["run_ids"][0]), ptimes.get(x["run_ids"][-1])
        x["hours"] = round((ts(t1) - ts(t0)).total_seconds() / 3600, 2) if x["final"] == "OK" and t0 and t1 else None
    tickets = []
    tp = os.path.join(repo, "docs/project/tickets.tsv")
    if os.path.exists(tp):
        cols = None
        for line in open(tp, encoding="utf-8"):
            if line.startswith("#"):
                continue
            f = line.rstrip("\n").split("\t")
            if cols is None:
                cols = f
                continue
            tickets.append(dict(zip(cols, f)))
    for key in keys:
        F = lambda *x: fig(figures, key, *x)
        sec = sections.get(key)
        # -- transcript
        tpath, how = tmap.get(key) or mapped.get(key, (None, None))
        tf = transcript_figures(tpath) if tpath and os.path.exists(tpath) else None
        tid = os.path.basename(tpath)[:8] if tf else None
        tsrc = f"transcript {os.path.basename(tpath)[:8]}" if tf else ""
        if tf:
            F("time", "transcript", "Transcript", tid, "", how, tsrc,
              "" if how == "MEASURED" else "no transcript id on the session's STATE heading: the transcript whose span "
              "holds the most of the session's commits, when no other session's commits claim it")
            F("time", "span_h", "Session span", round(tf["span_s"] / 3600, 2), "h", "DERIVED", tsrc,
              "last record's timestamp minus the first's; wall time, not working time")
            F("time", "active_h", "Active time", round(tf["active_s"] / 3600, 2), "h", "ESTIMATED", tsrc,
              f"sum of the gaps between consecutive records, each capped at {ACTIVE_GAP_S} s; a longer gap counts as idle")
            F("time", "maint_msgs", "Maintainer messages", tf["messages"], "", "MEASURED", tsrc,
              "the close's rulings_verbatim reader (queue enqueues included), the same text counted once")
            F("time", "maint_answers", "Answers to questions asked", tf["answers"], "", "MEASURED", tsrc)
            if tf["latency"]:
                F("time", "reply_median_min", "Median maintainer reply time", round(statistics.median(tf["latency"]) / 60, 1),
                  "min", "DERIVED", tsrc, f"median over {len(tf['latency'])} replies of (message time minus the end of the turn before it)")
            F("cost", "tool_calls", "Tool calls", sum(tf["tools"].values()), "", "MEASURED", tsrc)
            F("cost", "bash_calls", "Shell commands", tf["tools"].get("Bash", 0), "", "MEASURED", tsrc)
            F("cost", "bg_jobs", "Background jobs launched", tf["bg"], "", "MEASURED", tsrc)
            F("cost", "out_tok", "Output tokens (orchestrator)", tf["out_tok"], "tokens", "MEASURED", tsrc,
              "usage.output_tokens of each assistant message, once per message id")
            F("cost", "in_tok", "Input tokens incl. cache (orchestrator)", tf["in_tok"], "tokens", "MEASURED", tsrc,
              "usage input + cache creation + cache read, once per message id")
            F("cost", "workers", "Workers spawned", len(tf["workers"]), "", "MEASURED", tsrc + "/subagents",
              "one per subagents/*.meta.json (transcript_gaps.py's reader)")
            for kind in sorted({w[0] or "?" for w in tf["workers"]}):
                F("cost", f"workers_{kind}", f"Workers: {kind}", sum(1 for w in tf["workers"] if (w[0] or "?") == kind),
                  "", "MEASURED", tsrc + "/subagents")
            F("cost", "worker_fallbacks", "Worker model fallbacks", sum(len(w[7]) for w in tf["workers"]), "",
              "MEASURED", tsrc + "/subagents")
            F("cost", "worker_out_tok", "Output tokens (workers)", tf["worker_out_tok"], "tokens", "MEASURED",
              tsrc + "/subagents", "usage.output_tokens of each worker message, once per message id")
        # -- rule-checker ledger
        L = [r for r in ledger if r.get("session") in (key, tid)]
        src = f"{LEDGER} (session = {key}" + (f" or {tid}, its transcript" if tid else "") + ")"
        if L:
            F("checks", "rc_runs", "Rule-checker runs", len(L), "", "MEASURED", src)
            for d in sorted({r["decision"] for r in L}):
                F("checks", f"rc_{d}", f"Runs: {d}", sum(r["decision"] == d for r in L), "", "MEASURED", src)
            for v in ("OK", "VIOLATED", "VOID"):
                F("checks", f"rc_{v.lower()}", f"Verdict {v}", sum(r["verdict"] == v for r in L), "", "MEASURED", src)
            F("checks", "plants_caught", "Plants caught", sum(r["control_verdict"] == "CAUGHT" for r in L), "", "MEASURED", src)
            F("checks", "plants_dead", "Plants dead", sum(r["control_verdict"] == "DEAD" for r in L), "", "MEASURED", src)
            qs = {}
            for r in L:
                if r["verdict"] == "VIOLATED":
                    for q in r["violated"].split():
                        qs[q] = qs.get(q, 0) + 1
            for q in sorted(qs, key=lambda q: (len(q), q)):
                F("checks", f"q_{q}", f"{q} {QUESTIONS.get(q, '')} violated".replace("  ", " "), qs[q], "", "MEASURED", src)
            viol = [r for r in L if r["verdict"] == "VIOLATED"]
            F("checks", "rc_unresolved", "VIOLATED runs not resolved", sum(r["resolution"] == "-" for r in viol), "",
              "MEASURED", src, "")
            chains = {}
            for r in L:
                if r["decision"] != "calibration":
                    chains.setdefault((r["decision"], chain_key(r["subject"])), []).append(r)
            if chains:
                lens = [len(c) for c in chains.values()]
                rule = ("runs of one decision whose subject reads the same once run numbers, parentheses and the "
                        "text after the first ' — ' are dropped are one packet; a different wording splits a packet")
                F("checks", "packets", "Checked packets", len(chains), "", "ESTIMATED", src, rule)
                F("checks", "rechecks", "Re-check runs (runs beyond each packet's first)", sum(lens) - len(lens), "",
                  "ESTIMATED", src, rule)
                F("checks", "longest_packet", "Longest packet (runs until it stopped)", max(lens), "", "ESTIMATED", src, rule)
            # #335 (ruled 2026-10-29): per ACTION, its first run's verdict and the questions it violated
            A = [x for x in acts if not x["void_only"] and x.get("session") in (key, tid)]
            if A:
                exact = all(x["hows"] == {"RECORDED"} for x in A)
                acls = "DERIVED" if exact else "ESTIMATED"
                arule = ("an action is a run and its re-checks; its first run is its first non-VOID run; calibration rows "
                         "are not actions. " + ("Every run here records its action in its meta.tsv (prepare, since 14z-212)."
                         if exact else "Linked by tools/rc_actions.py: the action a run's meta.tsv records, else a run of "
                         "the same decision its subject names ('after run N'), else an open VIOLATED action of the same "
                         "session and decision whose subject shares at least half its words, else a new action."))
                asrc = src + "; tests/rulecheck/runs/*/meta.tsv"
                F("checks", "actions", "Actions checked", len(A), "", acls, asrc, arule)
                n_ok = sum(x["verdict"] == "OK" for x in A)
                F("checks", "first_ok", "Actions OK on their first run", n_ok, "", acls, asrc, arule)
                F("checks", "first_ok_pct", "First-run OK rate", round(100 * n_ok / len(A)), "%", acls, asrc,
                  "OK first runs / actions. " + arule)
                for d in sorted({x["decision"] for x in A}):
                    D = [x for x in A if x["decision"] == d]
                    k_ok = sum(x["verdict"] == "OK" for x in D)
                    F("checks", f"actions_{d}", f"Actions: {d}", len(D), "", acls, asrc, arule)
                    F("checks", f"first_ok_{d}", f"First-run OK: {d}", k_ok, "", acls, asrc, arule)
                    F("checks", f"first_ok_pct_{d}", f"First-run OK rate: {d}", round(100 * k_ok / len(D)), "%", acls, asrc,
                      "OK first runs / actions of this decision. " + arule)
                fq = {}
                for x in A:
                    for q in x["violated"]:
                        fq[q] = fq.get(q, 0) + 1
                for q in sorted(fq, key=lambda q: (len(q), q)):
                    F("checks", f"first_q_{q}", f"{q} {QUESTIONS.get(q, '')} violated on a first run".replace("  ", " "),
                      fq[q], "", acls, asrc, "every question VIOLATED on an action's first run counts once (ruled "
                      "2026-10-29, \"Every question\"). " + arule)
                H = sorted(x["hours"] for x in A if x["hours"] is not None)
                if H:
                    hsrc, hrule = ("the session transcripts (main and workers): each run's 'prepared run <id>' tool result",
                                   "an action passed when its last run is OK; its hours run from its first packet's "
                                   "preparation to the preparation of the packet that passed; a passed action without "
                                   "both times on record is left out")
                    F("checks", "pass_h_n", "Passed actions with both preparation times", len(H), "", "MEASURED", hsrc)
                    F("checks", "pass_h_median", "Median hours from first packet to the one that passed",
                      round(statistics.median(H), 2), "h", "DERIVED", hsrc, hrule)
                for x in A:
                    act_rows.append({"action": x["id"], "session": key, "decision": x["decision"], "first": x["first"],
                                     "verdict": x["verdict"], "final": x["final"], "violated": " ".join(x["violated"]), "runs": x["runs"], "hours": x["hours"],
                                     "links": " ".join(sorted(x["hows"]))})
            vo = [x for x in acts if x["void_only"] and x["id"] in {r["id"] for r in L}]
            if vo:
                F("checks", "actions_void_only", "Actions of VOID runs only (not counted)", len(vo), "", "MEASURED", src)
            for r in L:
                rc_rows.append({"id": r["id"], "session": key, "decision": r["decision"], "verdict": r["verdict"],
                                "plant": r["control_verdict"], "violated": r["violated"] if r["violated"] != "-" else "",
                                "subject": r["subject"][:160], "resolution": (r["resolution"] if r["resolution"] != "-" else "")[:400]})
        NR = [x for x in notrun if x[1] in (key, tid)]
        if NR:
            F("checks", "not_run", "Packets prepared and never run (not counted)", len(NR), "", "MEASURED",
              "tests/rulecheck/runs/*/NOT-RUN.txt, by the session in its meta.tsv")
        # -- commits
        C = [c for c in commits if c[0] == key]
        if C:
            gsrc = f"git log, subjects starting '{key}:' or '{key} '"
            F("output", "commits", "Commits", len(C), "", "MEASURED", gsrc)
            F("output", "files", "Files changed (sum over commits)", sum(c[3] for c in C), "", "MEASURED", gsrc)
            F("output", "insertions", "Lines inserted", sum(c[4] for c in C), "", "MEASURED", gsrc)
            F("output", "deletions", "Lines deleted", sum(c[5] for c in C), "", "MEASURED", gsrc)
        # -- STATE: findings, retractions, tickets
        if sec:
            n = findings_count(sec[2])
            F("quality", "findings", "Findings in the findings table", n, "", "MEASURED", f"{sec[0]}:{sec[1]} (the findings row)",
              "lettered items (a), (b) ... counted until a letter is missing; findings recorded outside the table are not counted")
        rp = os.path.join(repo, "tests/rulecheck/retractions", key + ".tsv")
        if os.path.exists(rp):
            rows = [l.split("\t") for l in open(rp, encoding="utf-8") if l.strip() and not l.startswith("#")]
            F("quality", "retracted", "Wordings retracted or corrected", sum(1 for r in rows if len(r) < 3 or not r[2].strip().startswith("reach")),
              "", "MEASURED", os.path.relpath(rp, repo), "")
        T = [t for t in tickets if key in re.split(r"[,\s]+", t.get("sessions", ""))]
        if T:
            F("quality", "tickets_touched", "Tickets naming this session", len(T), "", "MEASURED",
              "docs/project/tickets.tsv `sessions` column")
        # -- static tiers
        if tf:
            mine = [r for r in runs if tf["first"][:19] <= r["start"] <= tf["last"][:19]]
            trule = "a run belongs to the session when its start (the run directory's UTC name) falls inside the transcript's span"
        else:
            heads = {c[1] for c in C}
            mine = [r for r in runs if r["head"] in heads]
            trule = "a run belongs to the session when the commit it ran on is one of the session's commits"
        if mine:
            F("tiers", "tier_runs", "Static tier runs", len(mine), "", "DERIVED", "build/static_runs/*/results.tsv", trule)
            walls = [r["wall"] for r in mine if r["wall"] is not None]
            if walls:
                F("tiers", "tier_wall_h", "Static tier wall time", round(sum(walls) / 3600, 2), "h", "DERIVED",
                  "build/static_runs/*/run_record_start.json, run_record_end.json",
                  "sum over the session's runs of (end utc minus start utc); a run with no end record is left out. " + trule)
            F("tiers", "tier_fail", "Gate FAILs across tier runs", sum(sum(g[1] == "FAIL" for g in r["gates"]) for r in mine),
              "", "DERIVED", "build/static_runs/*/results.tsv", "sum of FAIL rows. " + trule)
            for r in mine:
                g_s = sum(g[2] for g in r["gates"])
                c_s = sum(c[3] for c in r["controls"])
                tier_rows.append({"run": r["run"], "session": key, "start": r["start"], "args": r["args"],
                                  "head": r["head"][:8], "wall_s": r["wall"], "gate_s": g_s, "control_s": c_s,
                                  "pass": sum(g[1] == "PASS" for g in r["gates"]), "skip": sum(g[1] == "SKIP" for g in r["gates"]),
                                  "fail": sum(g[1] == "FAIL" for g in r["gates"]), "controls": len(r["controls"]),
                                  "honoured": sum(c[2] == "HONOURED" for c in r["controls"]),
                                  "source": r["path"], "assigned_by": trule})
            longest = max(mine, key=lambda r: (r["wall"] or 0, len(r["gates"])))
            items = [(g[0], "gate", g[2]) for g in longest["gates"]]
            per_ctl = {}
            for c in longest["controls"]:
                per_ctl[c[0]] = per_ctl.get(c[0], 0) + c[3]
            items += [(g, "controls", s) for g, s in per_ctl.items()]
            for name, kind, s in sorted(items, key=lambda x: -x[2])[:10]:
                costly.append({"session": key, "run": longest["run"], "item": name, "kind": kind, "seconds": s,
                               "source": longest["path"]})
        print(f"{key}: {sum(1 for x in figures if x['session'] == key)} figures"
              f"{'' if tf else ' (no transcript on record)'}; {len(L)} rule-checker runs; {len(C)} commits; {len(mine)} tier runs")
    for p in sorted(shared):
        print(f"transcript {os.path.basename(p)[:8]}: claimed by more than one session's commits, so none of them is given it")
    os.makedirs(a.out, exist_ok=True)
    for name, rows in (("figures", figures), ("rc_runs", rc_rows), ("tiers", tier_rows), ("costly", costly),
                       ("actions", act_rows)):
        with open(os.path.join(a.out, name + ".json"), "w") as f:
            json.dump(rows, f, indent=0, sort_keys=True)
    return 0


def check(d):
    bad = 0
    rows = json.load(open(os.path.join(d, "figures.json")))
    for r in rows:
        why_bad = ("class " + str(r.get("class"))) if r.get("class") not in CLASSES else \
                  "no source" if not r.get("source") else \
                  "no rule" if r["class"] != "MEASURED" and not r.get("rule") else ""
        if why_bad:
            bad += 1
            print(f"  BAD  {r.get('session')} {r.get('metric')}: {why_bad}")
    print(f"{len(rows)} figures, {bad} without a class, a source or (when not MEASURED) a rule")
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sp = ap.add_subparsers(dest="cmd", required=True)
    c = sp.add_parser("collect")
    c.add_argument("--keys", required=True)
    c.add_argument("--out", required=True)
    c.add_argument("--repo", default=".")
    c.add_argument("--projects", default=os.path.expanduser(
        "~/.claude/projects/" + re.sub(r"[^A-Za-z0-9]", "-", os.path.abspath("."))))
    c.add_argument("--transcript", action="append", default=[], help="KEY=PATH, overriding the STATE heading's id")
    c.add_argument("--static-runs", default="build/static_runs")
    k = sp.add_parser("check")
    k.add_argument("dir")
    a = ap.parse_args()
    return collect(a) if a.cmd == "collect" else check(a.dir)


if __name__ == "__main__":
    sys.exit(main())
