#!/usr/bin/env python3
"""rc_actions.py — WHICH RULE-CHECKER RUNS ARE ONE ACTION, and which run is its first (GitHub #335, 14z-212).

An ACTION is one thing put to the rule-checker (a build, a freeze, an expectation, a recommendation, a procedure
check) together with every re-check of it until it passed or was dropped. The ledger (tests/rulecheck/ledger.tsv)
has no action column; since 14z-212 `rulecheck prepare` records one in the run's meta.tsv instead — `action <the id
of the action's first run>`, and on a re-check `redoes <the run it redoes>` (prepare --redoes). For the rows before
that, a run joins an earlier action by the FIRST rule below that holds (ruled 2026-10-29, the maintainer: "Link, else
wording"):

  RECORDED  its meta.tsv names its action                                                         (MEASURED)
  NAMED     its subject names a run OF THE SAME DECISION that it follows — "after run(s) <id>[, <id> and <id>]" — a full
            id, or a run number read as the latest earlier run whose id ends in it (read from the record's text; a
            freeze "after runs 389-404" follows that freeze's expectation runs, a different action)
  WORDING   it joins the OPEN action (its last run VIOLATED or VOID) of the same session and decision whose last
            subject shares at least half its words (Jaccard over lower-case words, a few stop words dropped) (ESTIMATED)
  otherwise it starts a new action.

What counts (ruled 2026-10-29): calibration rows are not actions (they test the checker); a VOID run (its plant was
dead, so it licensed nothing) is linked like any run but never counted as an action's first run — the first run is
the first non-VOID one, and an action of VOID runs only is left out; a packet prepared but never run (NOT-RUN.txt in
its run directory, no ledger row) is no run. All three are shown apart, never dropped silently. "Which question fails
first" counts EVERY question VIOLATED on an action's first run ("Every question").

Used by tools/session_metrics.py (the dashboard's figures) and tools/rulecheck.py (prepare's --redoes and its nudge).
Gate: tests/test_session_metrics.sh.
"""
import os
import re

STOP = {"the", "a", "of", "and", "to", "in", "on", "as", "is", "its", "at", "for", "by", "with", "an", "be"}
WORD = re.compile(r"[a-z0-9#]+")
NAMED = re.compile(r"after runs? ([0-9][0-9, \-]*(?:and [0-9\-][0-9\-]*)?)")
RUN_ID = re.compile(r"\d{4}-\d\d-\d\d-\d+|\d+")
SIMILAR = 0.5


def words(subject):
    return set(WORD.findall(subject.lower())) - STOP


def similarity(s1, s2):
    w1, w2 = words(s1), words(s2)
    return len(w1 & w2) / max(1, len(w1 | w2))


def run_order(rid):
    date, _, n = rid.rpartition("-")
    return (date, int(n) if n.isdigit() else 0)


def read_meta(path):
    d = {}
    if os.path.exists(path):
        for ln in open(path, encoding="utf-8"):
            if "\t" in ln:
                k, v = ln.rstrip("\n").split("\t", 1)
                d.setdefault(k, v)
    return d


def metas(repo, rows):
    """-> {run id: meta.tsv dict} for the ledger rows whose run directory records an action"""
    out = {}
    for r in rows:
        m = read_meta(os.path.join(repo, "tests/rulecheck/runs", r["id"], "meta.tsv"))
        if m.get("action"):
            out[r["id"]] = m
    return out


def named_runs(subject, earlier):
    """the run ids a subject says it follows, resolved against the earlier run ids (latest first for a bare number)"""
    m = NAMED.search(subject)
    if not m:
        return []
    out = []
    for tok in RUN_ID.findall(m.group(1)):
        if tok in earlier:
            out.append(tok)
        else:
            hit = [x for x in reversed(earlier) if x.endswith("-" + tok)]
            if hit:
                out.append(hit[0])
    return out


def link(rows, meta=None):
    """-> {run id: (action id, how)} for every non-calibration ledger row, how in RECORDED | NAMED | WORDING | NEW"""
    meta = meta or {}
    rows = sorted((r for r in rows if r["decision"] != "calibration"), key=lambda r: run_order(r["id"]))
    action, seen, open_ = {}, [], {}   # open_: (session, decision) -> {action id: last subject}
    decision = {r["id"]: r["decision"] for r in rows}
    for r in rows:
        rid, k, a, how = r["id"], (r["session"], r["decision"]), None, "NEW"
        m = meta.get(rid)
        if m and m.get("action"):
            a, how = m["action"], "RECORDED"   # prepare resolved it when it wrote meta.tsv
        if a is None:
            for x in named_runs(r["subject"], seen):
                if x in action and decision[x] == r["decision"]:
                    a, how = action[x][0], "NAMED"
                    break
        if a is None:
            best = None
            for aid, subj in open_.get(k, {}).items():
                j = similarity(r["subject"], subj)
                if j >= SIMILAR and (best is None or j > best[1]):
                    best = (aid, j)
            if best:
                a, how = best[0], "WORDING"
        if a is None:
            a = rid
        if a == rid and how != "RECORDED":
            how = "NEW"
        action[rid] = (a, how)
        seen.append(rid)
        for ok in open_.values():
            ok.pop(a, None)
        if r["verdict"] in ("VIOLATED", "VOID"):
            open_.setdefault(k, {})[a] = r["subject"]
    return action


def actions(rows, meta=None):
    """-> [action dict] in first-run order: id, decision, session, first (run id), verdict, violated (list), runs,
    run_ids (in order), hows (set), void_only (bool), final (the verdict of its LAST run: OK when a re-check passed, VIOLATED when the
    action stopped there)"""
    links = link(rows, meta)
    by = {}
    for r in sorted((r for r in rows if r["id"] in links), key=lambda r: run_order(r["id"])):
        aid, how = links[r["id"]]
        a = by.setdefault(aid, {"id": aid, "decision": r["decision"], "runs": 0, "hows": set(), "first": None, "run_ids": []})
        a["runs"] += 1
        a["run_ids"].append(r["id"])
        a["hows"].add(how)
        a["final"] = r["verdict"]
        if a["first"] is None and r["verdict"] != "VOID":
            v = r["violated"] if r["verdict"] == "VIOLATED" else "-"
            a.update(first=r["id"], session=r["session"], verdict=r["verdict"],
                     violated=[] if v == "-" else v.split())
    for a in by.values():
        a["void_only"] = a["first"] is None
    return sorted(by.values(), key=lambda a: run_order(a["id"]))


def not_run(repo):
    """-> [(run id, session, decision)] for every prepared run directory marked NOT-RUN.txt"""
    d = os.path.join(repo, "tests/rulecheck/runs")
    out = []
    if os.path.isdir(d):
        for rid in sorted(os.listdir(d), key=run_order):
            if os.path.exists(os.path.join(d, rid, "NOT-RUN.txt")):
                m = read_meta(os.path.join(d, rid, "meta.tsv"))
                out.append((rid, m.get("session", ""), m.get("decision", "")))
    return out
