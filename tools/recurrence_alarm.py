#!/usr/bin/env python3
"""recurrence_alarm.py — a rule-checker finding that keeps COMING BACK is loud (#271, 14z-199: C3 and the rot rule
"a recurring violation opens a ticket", the session's proposals the maintainer adopted — DECISIONS_HISTORY.md "Ruled
2026-10-12 (14z-199)": "I agree with your proposals for C1, C2, C3, C4", "8. Rot -> I agree with your proposals"). The case that made it: a calibration plant's reader quoting its claim's frames 2550/2560 failed
procedure runs from 14z-179 to 14z-198, resolved run by run ("no slip", "accepted") and never aggregated,
because nothing read the ledger across runs.

  python3 tools/recurrence_alarm.py [--ack FILE]        # the ledger of the tree it runs in
  python3 tools/recurrence_alarm.py --selftest [--through-ignored]

A SIGNATURE is a question plus a PAIR of tokens cited in one VIOLATED line of a run's verdict_real.txt.
A token is a figure of three or more digits (tools/agent/extract.py's figure finder; an extract record
index `[N]` and a run number `run N` / `runs N-M` are removed first, since they name where, not what) or a
`file:line` anchor (its basename). A pair, not one token: a single number recurs by TOPIC (the fighter's
`$382` in five unrelated packets), a pair by the same evidence quoted again.

Counted over every VIOLATED run of tests/rulecheck/ledger.tsv except calibrations (a calibration's subject
IS a planted fixture, VIOLATED by design): the distinct SUBJECTS (a subject's ` — re-check after …` tail
removed, so a sitting's own fix loop counts once) and the distinct SESSIONS (the 14z-N key; a run recorded
before #209 gives its key in its subject, its session column holding a transcript prefix). A signature RECURS when it is
in 3 or more subjects across 2 or more sessions (validated by the maintainer, DECISIONS_HISTORY.md "Ruled 2026-10-13
(14z-199)": "Points 1 and 2 I validated"). (Measured 14z-199, build/agent199/t271: over the whole
ledger this names only the calibration-plant reader family and the close's documentation packet Q1 — the
ticket's first form, "3 or more runs or 2 or more sessions", also named a sitting's own re-check loop and
coincidences.)

ACKNOWLEDGED by a row of tests/rulecheck/recurrence.tsv —
`question<TAB>tokens (space-separated)<TAB>#N<TAB>through-run-id<TAB>note` — when the question matches and
both tokens are in the row's set: its occurrences in runs up to and including through-run-id are the
ticket's. The ticket must have a row in docs/project/tickets.tsv. Occurrences AFTER through-run-id count
afresh, so a fix that did not hold raises the alarm again.

EXIT 1 when a signature recurs on unacknowledged occurrences (each named, with its runs and sessions);
EXIT 3 (REFUSED) on a malformed acknowledgement row or a ticket with no index row; else 0.
"""
import argparse
import csv
import itertools
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools" / "agent"))
import extract  # noqa: E402  (the ONE figure finder)

LEDGER = "tests/rulecheck/ledger.tsv"
RUNS = "tests/rulecheck/runs"
ACK = "tests/rulecheck/recurrence.tsv"
TICKETS = "docs/project/tickets.tsv"
MIN_SUBJECTS, MIN_SESSIONS = 3, 2
THROUGH_IGNORED = False   # --through-ignored: an acknowledgement covers every run, past and future — KNOWN-BAD


def run_key(rid):
    """`2026-10-12-945` -> ('2026-10-12', 945): the ledger's ids in recording order."""
    m = re.fullmatch(r"(\d{4}-\d\d-\d\d)-(\d+)", rid)
    return (m.group(1), int(m.group(2))) if m else (rid, 0)


def subject(s):
    return re.sub(r"\s*[—-]+\s*re-check after.*$", "", s).strip()


def sitting(r):
    """The run's 14z-N key: the session column, or — for a run recorded before #209 made prepare require the key,
    whose column holds a transcript prefix or `-` — the first key its subject names (a sitting compacted across two
    transcripts is ONE session; measured 14z-199: 14z-181's documentation-packet loop read as two)."""
    if re.fullmatch(r"14z-\d+[a-z]?", r["session"]):
        return r["session"]
    m = re.search(r"14z-\d+[a-z]?", r["subject"])
    return m.group(0) if m else r["session"]


def tokens(evidence):
    ev = re.sub(r"\[\d+\]", " ", evidence)
    ev = re.sub(r"\bruns?\s+(?:\d{4}-\d\d-\d\d-)?\d+(?:\s*[-–,]\s*\d+)*", " ", ev)
    figs = {f for f in extract.figures(ev) if len(f.split(".")[0]) >= 3}
    anchors = {re.sub(r"^.*/", "", a) for a in re.findall(r"[\w./-]+\.\w+:\d+", evidence)}
    return sorted(figs | anchors)


def read_ledger(root):
    with open(root / LEDGER) as f:
        return list(csv.DictReader((ln for ln in f if not ln.startswith("#")), delimiter="\t"))


def occurrences(root):
    """-> {(question, tok_a, tok_b): [(run_id, subject, session), ...]}"""
    occ = {}
    for r in read_ledger(root):
        if r["verdict"] != "VIOLATED" or r["decision"] == "calibration":
            continue
        p = root / RUNS / r["id"] / "verdict_real.txt"
        if not p.is_file():
            continue
        for ln in p.read_text(errors="replace").splitlines():
            m = re.match(r"(Q\w+): VIOLATED — (.*)", ln)
            if not m:
                continue
            for a, b in itertools.combinations(tokens(m.group(2)), 2):
                occ.setdefault((m.group(1), a, b), []).append((r["id"], subject(r["subject"]), sitting(r)))
    return occ


def read_acks(root, ack_path):
    """-> [(question, token set, ticket, through)]; REFUSED (exit 3) on a bad row or an unindexed ticket."""
    p = Path(ack_path) if ack_path else root / ACK
    if not p.is_file():
        return []
    tickets = set()
    tp = root / TICKETS
    if tp.is_file():
        tickets = {ln.split("\t")[0] for ln in tp.read_text().splitlines() if ln and not ln.startswith("#")}
    out = []
    for n, ln in enumerate(p.read_text().splitlines(), 1):
        if not ln.strip() or ln.startswith("#"):
            continue
        c = ln.split("\t")
        if len(c) != 5 or not re.fullmatch(r"Q\w+", c[0]) or not re.fullmatch(r"#\d+", c[2]) \
                or not re.fullmatch(r"\d{4}-\d\d-\d\d-\d+", c[3]) or len(c[1].split()) < 2:
            print(f"REFUSED: {p} line {n} is not `question<TAB>two or more tokens<TAB>#N<TAB>through-run-id<TAB>note`: {ln[:100]!r}")
            sys.exit(3)
        if c[2][1:] not in tickets:
            print(f"REFUSED: {p} line {n} acknowledges with {c[2]}, which has no row in {TICKETS}")
            sys.exit(3)
        out.append((c[0], set(c[1].split()), c[2], c[3]))
    return out


def judge(root, ack_path=None):
    occ = occurrences(root)
    acks = read_acks(root, ack_path)
    recurring, acked = [], []
    for sig, hits in occ.items():
        q, a, b = sig
        mine = [ak for ak in acks if ak[0] == q and a in ak[1] and b in ak[1]]
        fresh = [h for h in hits if not any(THROUGH_IGNORED or run_key(h[0]) <= run_key(ak[3]) for ak in mine)]
        subj_all, sess_all = {h[1] for h in hits}, {h[2] for h in hits}
        subj, sess = {h[1] for h in fresh}, {h[2] for h in fresh}
        if len(subj) >= MIN_SUBJECTS and len(sess) >= MIN_SESSIONS:
            recurring.append((sig, fresh))
        elif len(subj_all) >= MIN_SUBJECTS and len(sess_all) >= MIN_SESSIONS:
            acked.append((sig, mine[0][2] if mine else "?"))
    return recurring, acked


def report(recurring, acked):
    print(f"recurrence: {len(recurring) + len(acked)} signature(s) recur (>= {MIN_SUBJECTS} subjects in >= {MIN_SESSIONS} sessions);"
          f" {len(acked)} acknowledged by a ticket, {len(recurring)} not")
    for (q, a, b), fresh in sorted(recurring, key=lambda x: (-len({h[2] for h in x[1]}), x[0])):
        runs = sorted({h[0] for h in fresh}, key=run_key)
        print(f"RECURRING: {q} {a} + {b} — {len({h[1] for h in fresh})} subjects, {len({h[2] for h in fresh})} sessions"
              f" ({' '.join(sorted({h[2] for h in fresh}))}), runs {runs[0]} .. {runs[-1]} ({len(runs)})")
    if recurring:
        print("FAIL: a finding recurs with no ticket acknowledging it — open a ticket for its cause and add a row to"
              f" {ACK} (question, tokens, #N, the last run it covers, a note)")
    return 1 if recurring else 0


def selftest():
    """A synthetic ledger with known answers (the real tool on a temporary root)."""
    d = Path(tempfile.mkdtemp())
    try:
        (d / RUNS).mkdir(parents=True); (d / "docs/project").mkdir(parents=True)
        (d / TICKETS).write_text("# index\n9001\tevolution\topen\tthe plant reader\n")
        cols = ["id", "date", "session", "decision", "subject", "control", "control_verdict", "verdict", "violated", "resolution", "model"]
        rows = []

        def run(rid, sess, subj, line, decision="procedure"):
            (d / RUNS / rid).mkdir()
            (d / RUNS / rid / "verdict_real.txt").write_text(line + "\nVERDICT: VIOLATED\n")
            rows.append([rid, rid[:10], sess, decision, subj, "fx", "CAUGHT", "VIOLATED", line.split(":")[0], "-", "m"])
        # A: the plant family — 3 subjects, 2 sessions, the same pair (2550, 2560) with record indices and run ids around it
        run("2099-01-01-01", "14z-1", "session 1 part 1", "QP3: VIOLATED — [4731] W# lists 2560 and 2550 (run 931) from name_moves.py.txt:687")
        run("2099-01-01-02", "14z-1", "session 1 part 2", "QP3: VIOLATED — [5260] the frames 2550 and 2560, name_moves.py.txt:687")
        run("2099-01-02-01", "14z-2", "session 2 part 1", "QP3: VIOLATED — [7090] 2560 / 2550 again (runs 940-944)")
        # B: a re-check loop — one subject four times in one session (same pair): never recurring
        for n in range(1, 5):
            run(f"2099-01-03-0{n}", "14z-3", "my report" + (f" — re-check after run {n}" if n > 1 else ""), "Q1: VIOLATED — 565 s and 482 s unstaged")
        # C: a topic coincidence — one shared token (+0x382 read as $382) in three subjects and two sessions: no pair
        run("2099-01-04-01", "14z-4", "pyron a", "Q1: VIOLATED — move.b $382(a6) shows 111 only")
        run("2099-01-04-02", "14z-4", "pyron b", "Q4: VIOLATED — $382 at 222")
        run("2099-01-05-01", "14z-5", "pyron c", "Q1: VIOLATED — $382 and 333")
        # D: calibrations of a fixture are VIOLATED by design: never counted
        for n in range(1, 4):
            run(f"2099-01-06-0{n}", f"14z-{6 + n}", f"fixture-{n}", "Q1: VIOLATED — 7777 and 8888", decision="calibration")
        # G: one sitting under two transcript prefixes (pre-#209 rows): its key is in the subject — ONE session
        run("2099-01-09-01", "abcd1234", "14z-11 close, the packet", "Q2: VIOLATED — caps.txt:20 and caps.txt:39")
        run("2099-01-09-02", "abcd1234", "14z-11 close, the packet: again", "Q2: VIOLATED — caps.txt:20 and caps.txt:39")
        run("2099-01-09-03", "ef567890", "14z-11 close, the packet: once more", "Q2: VIOLATED — caps.txt:20 and caps.txt:39")
        # E: record indices and run numbers are not tokens: [1234] [5678] and run 4321 / runs 8765-8766 in 3 subjects, 2 sessions
        run("2099-01-07-01", "14z-7", "e1", "QP3: VIOLATED — [1234] [5678] run 4321")
        run("2099-01-07-02", "14z-7", "e2", "QP3: VIOLATED — [1234] [5678] runs 8765-8766")
        run("2099-01-08-01", "14z-8", "e3", "QP3: VIOLATED — [1234] [5678] run 4321")
        with open(d / LEDGER, "w") as f:
            f.write("# synthetic\n" + "\t".join(cols) + "\n" + "".join("\t".join(r) + "\n" for r in rows))
        rec, _ = judge(d, d / "none.tsv")
        sigs = {s for s, _ in rec}
        checks = {
            "the plant pair recurs (3 subjects, 2 sessions), indices and run ids aside": ("QP3", "2550", "2560") in sigs,
            "a pair in two subjects of one session does not recur": ("QP3", "2560", "name_moves.py.txt:687") not in sigs,
            "a re-check loop of one subject never recurs": not any(s[1] in ("482", "565") for s in sigs),
            "one shared token is a topic, not a recurrence": not any("382" in s for s in sigs),
            "calibrations are not counted": not any("7777" in s for s in sigs),
            "record indices and run numbers are not tokens": not any(t in s for s in sigs for t in ("1234", "5678", "4321", "8765")),
            "one sitting under two transcript prefixes is one session": not any("caps.txt:20" in s for s in sigs),
        }
        ack = d / "ack.tsv"
        ack.write_text("QP3\t2550 2560 name_moves.py.txt:687\t#9001\t2099-01-02-01\tthe plant reader\n")
        rec, acked = judge(d, ack)
        checks["an acknowledgement through the last run silences the pair"] = not rec and any(s == ("QP3", "2550", "2560") for s, _ in acked)
        # F: the fix did not hold — three later subjects in two later sessions recur afresh
        run("2099-02-01-01", "14z-9", "session 9", "QP3: VIOLATED — 2550 and 2560 once more")
        run("2099-02-01-02", "14z-9", "session 9 b", "QP3: VIOLATED — 2550 and 2560 once more")
        run("2099-02-02-01", "14z-10", "session 10", "QP3: VIOLATED — 2550 and 2560 once more")
        with open(d / LEDGER, "w") as f:
            f.write("# synthetic\n" + "\t".join(cols) + "\n" + "".join("\t".join(r) + "\n" for r in rows))
        rec, _ = judge(d, ack)
        checks["occurrences after the acknowledged run recur afresh"] = any(s == ("QP3", "2550", "2560") for s, _ in rec)
        ack.write_text("QP3\t2550 2560\t#9002\t2099-01-02-01\tno such ticket\n")
        try:
            import contextlib, io
            with contextlib.redirect_stdout(io.StringIO()) as buf:
                judge(d, ack)
            checks["an acknowledgement naming an unindexed ticket is REFUSED"] = False
        except SystemExit as e:
            checks["an acknowledgement naming an unindexed ticket is REFUSED"] = e.code == 3 and "#9002" in buf.getvalue()
    finally:
        shutil.rmtree(d)
    bad = [k for k, v in checks.items() if not v]
    for k in bad:
        print(f"  selftest WRONG: {k}")
    print(f"SELFTEST {'PASS' if not bad else 'FAIL'}: {len(checks)} checks, {len(bad)} wrong" + (" (through-ignored variant)" if THROUGH_IGNORED else ""))
    return 1 if bad else 0


def main():
    global THROUGH_IGNORED
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--ack", help=f"the acknowledgement file (default {ACK})")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--through-ignored", action="store_true", help="KNOWN-BAD: an acknowledgement covers every run")
    a = ap.parse_args()
    THROUGH_IGNORED = a.through_ignored
    if a.selftest:
        return selftest()
    rec, acked = judge(REPO, a.ack)
    return report(rec, acked)


if __name__ == "__main__":
    sys.exit(main())
