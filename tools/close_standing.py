#!/usr/bin/env python3
"""close_standing.py — THE STANDING CLOSE-CHECK SET: rendered for a close from a tracked template, its lists derived,
its plants generated from the live inputs, and the documentation packet's claim generated from its run of record
(GitHub #204 and #207, 14z-189).

WHY. Three closes running took 12, 8 and 7 documentation-packet runs (14z-186, 14z-187b, 14z-188), and four of the six
VIOLATED runs at the 14z-188 close were holes in checks written DURING that close: no check for a bare `none` (563),
a check reading a copy of the row (568), a hard-coded open-ticket list that missed a ticket the same close had added
(570), and that list being hard-coded at all (571). Each close copied the previous checks file and rewrote parts of
it by hand, so the checker probed the same hand-written surface again (#204). The claim handed to the checker was one
long hand-written sentence restating every check, its figure and its path, rewritten for each of seven runs (#207).

WHAT. The set is `tests/close_standing_checks.tsv` (its header is the spec of record); its only parameters are the
session key, the findings row's title and the run directory, and everything else is DERIVED here:

  render --key 14z-N --row "(N) THE FINDINGS TABLE" --run DIR [--transcript PATH] [--extra TSV] [--template TSV]
      writes DIR/checks.tsv (name, expected exit, command: what tools/close_checks.py runs) and DIR/checks_decl.tsv
      (name, source, WHAT, NOT SEEN, figure) with {KEY} {ROW} {RUN} {SESSDIR} {BASE} {TRANSCRIPT} filled. {BASE} is the
      parent of the oldest commit whose subject starts `<key>:` (HEAD when there is none yet); {TRANSCRIPT} is the newest
      top-level .jsonl of this project's Claude Code transcripts unless --transcript names one. --extra adds this
      close's own rows (same six columns, names new). Refuses a title holding a quote, `$`, a backtick or a backslash.
  open-tickets --row TITLE [--next NEXT_SESSION.md] [--state STATE.md] [--tickets tickets.tsv]
      every `#N` in NEXT_SESSION's START HERE and every `#N (open)` in the newest group's findings row must have
      status `open` in the ticket index; exit 0, 1 on any other (or none cited), 2 on a missing input.
  dup-entries FILE [--headings]
      no whole `## ` entry (heading and body) repeats; with --headings no `## ` heading repeats either. exit 0 / 1.
  row-copy --row TITLE --copy FILE [--state STATE.md] [--write]
      the copy equals the newest group's row now (exit 0, 1 differs, 2 missing); --write writes it.
  plant KIND --row TITLE --out DIR
      one generated plant from the live file, written under DIR: bare-none (STATE_plant.md: the row gains a bare
      `none`), row-stale (findings_row_plant.txt: one character changed), next-closed (NEXT_SESSION_plant.md: START
      HERE cites a ticket the index lists as not open), dup-decisions (DECISIONS_HISTORY_plant.md: its first entry
      appended again), dup-state-history (STATE_HISTORY_plant.md: its first group appended again). exit 3 when it
      cannot build the plant, so a plant row expecting 1 never reads OK on a generator failure.
  claim --run DIR [--premises FILE]
      the documentation packet's claim, ONE line on stdout, from the run of record DIR/out/exits.tsv and
      DIR/checks_decl.tsv: one sentence per check (its name, WHAT, exit, seconds, output path and the first output
      line its figure regex matches), then NOT TESTED: each check's NOT SEEN and the premises file's lines (the only
      hand-typed part). Refuses unless `tools/close_checks.py status` would accept the run, and lints the result with
      tools/claim_lint.py (exit 1 on an untied universal).
  --selftest [--perturb NAME]
      every subcommand on a synthetic tree with known answers. --perturb is the gate's must-fire hook
      (tests/test_close_standing.sh): plant-is-live, dup-blind, stale-row-accepted, claim-partial-accepted — each
      known-bad variant must FAIL the self-test.

WHAT IT CANNOT SEE: whether the findings table is complete (a hand read, #206 makes it a review), whether a check's
WHAT line is true of its command (the checker reads both), and the per-letter homes (#205).
"""
import hashlib, io, os, re, subprocess, sys, tempfile
from contextlib import redirect_stdout

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
PERTURB = ""
TEMPLATE = "tests/close_standing_checks.tsv"
PLACE = ("KEY", "ROW", "RUN", "SESSDIR", "BASE", "TRANSCRIPT")
BAD_TITLE = re.compile(r'["$`\\\t]')


def die(msg, code=1):
    print(msg)
    sys.exit(code)


def read_table(path):
    rows, seen = [], set()
    for n, line in enumerate(open(path, encoding="utf-8"), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        f = line.rstrip("\n").split("\t")
        if len(f) != 6 or not re.match(r"^[A-Za-z0-9_.-]+$", f[0]) or not re.match(r"^-?\d+$", f[1]) \
                or not all(x.strip() for x in f):
            die(f"{path}:{n}: expected name, expected exit, WHAT, NOT SEEN, figure, command (six non-empty columns)")
        if f[0] in seen:
            die(f"{path}:{n}: duplicate check name {f[0]}")
        seen.add(f[0])
        rows.append(f)
    return rows


def git(root, *args):
    return subprocess.run(["git", *args], cwd=root, capture_output=True, text=True).stdout


def derive_base(root, key):
    oldest = None
    for line in git(root, "log", "--format=%H %s", "-n", "2000").splitlines():
        h, _, s = line.partition(" ")
        if s.startswith(key + ":"):
            oldest = h
    if oldest is None:
        return git(root, "rev-parse", "--short=8", "HEAD").strip()
    return git(root, "rev-parse", "--short=8", oldest + "^").strip()


def derive_transcript(root):
    d = os.path.expanduser("~/.claude/projects/" + re.sub(r"[^A-Za-z0-9]", "-", root))
    js = [os.path.join(d, x) for x in os.listdir(d) if x.endswith(".jsonl")] if os.path.isdir(d) else []
    return max(js, key=os.path.getmtime) if js else None


def render(root, key, title, run, transcript=None, extra=None, template=None):
    if not re.match(r"^14z-\d+[a-z]?$", key):
        die(f"--key {key!r} is not a 14z-N session key")
    if BAD_TITLE.search(title):
        die(f"--row {title!r}: a quote, $, backtick, backslash or tab would break the rendered commands")
    rows = [r + ["standing"] for r in read_table(os.path.join(root, template or TEMPLATE))]
    if extra:
        names = {r[0] for r in rows}
        for r in read_table(extra):
            if r[0] in names:
                die(f"--extra {extra}: {r[0]} is a standing check — a close adds, it never redefines")
            rows.append(r + ["extra"])
    transcript = transcript or derive_transcript(root)
    if not transcript:
        die("no transcript found for this project: pass --transcript PATH")
    run = run.rstrip("/")
    val = dict(KEY=key, ROW=title, RUN=run, SESSDIR=os.path.dirname(run) or ".",
               BASE=derive_base(root, key), TRANSCRIPT=transcript)
    def fill(s):
        for k in PLACE:
            s = s.replace("{" + k + "}", val[k])
        left = re.findall(r"\{[A-Z]+\}", s)
        if left:
            die(f"unknown placeholder(s) {left} in: {s[:80]}")
        return s
    os.makedirs(os.path.join(root, run), exist_ok=True)
    tsha = hashlib.sha256(open(os.path.join(root, template or TEMPLATE), "rb").read()).hexdigest()[:16]
    with open(os.path.join(root, run, "checks.tsv"), "w", encoding="utf-8") as fh:
        fh.write(f"# rendered by tools/close_standing.py from {template or TEMPLATE} ({tsha}) for {key}; "
                 f"do not edit — re-render (add rows with --extra)\n")
        for r in rows:
            fh.write(f"{r[0]}\t{r[1]}\t{fill(r[5])}\n")
    with open(os.path.join(root, run, "checks_decl.tsv"), "w", encoding="utf-8") as fh:
        fh.write("name\tsource\twhat\tnot_seen\tfigure\n")
        for r in rows:
            fh.write(f"{r[0]}\t{r[6]}\t{fill(r[2])}\t{fill(r[3])}\t{r[4]}\n")
    for k in PLACE:
        print(f"  {k:10s} {val[k]}")
    print(f"rendered {len(rows)} checks ({sum(r[6] == 'extra' for r in rows)} added) into {run}/checks.tsv")
    return 0


def newest_row(state_text, title):
    """the newest session group's row whose first cell is **title** -> (line or None, why)"""
    lines = state_text.split("\n")
    start = next((i for i, l in enumerate(lines) if l.startswith("## Session ")), None)
    if start is None:
        return None, "no '## Session' group"
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith(("## ", "# "))), len(lines))
    hits = [l for l in lines[start:end] if l.startswith("| **" + title + "**")]
    if len(hits) != 1:
        return None, f"rows titled {title!r} in the newest group: {len(hits)} (want 1)"
    return hits[0], ""


def start_here(next_text):
    out, on = [], False
    for l in next_text.split("\n"):
        if l.startswith("## "):
            on = l.startswith("## START HERE")
            continue
        if on:
            out.append(l)
    return "\n".join(out)


def ticket_status(path):
    st = {}
    for l in open(path, encoding="utf-8"):
        f = l.rstrip("\n").split("\t")
        if len(f) > 2 and f[0].isdigit():
            st[f[0]] = f[2]
    return st


def open_tickets(title, nxt, state, tickets):
    try:
        nt, stt, st = open(nxt, encoding="utf-8").read(), open(state, encoding="utf-8").read(), ticket_status(tickets)
    except OSError as e:
        print(f"missing input: {e}")
        return 2
    row, why = newest_row(stt, title)
    cited = set(re.findall(r"#(\d+)", start_here(nt)))
    if row is not None:
        cited |= set(re.findall(r"#(\d+) \(open\)", row))
    else:
        print(f"(the findings row is not read: {why})")
    bad = 0
    for n in sorted(cited, key=int):
        s = st.get(n, "NO ROW")
        bad += s != "open"
        print(f"#{n} {s}")
    print(f"cited {len(cited)}  not open {bad}  ({nxt})")
    return 1 if bad or not cited else 0


def entries(text):
    return [p.rstrip() for p in re.split(r"(?m)^(?=## )", text) if p.startswith("## ")]


def dup_entries(path, headings):
    es = entries(open(path, encoding="utf-8").read())
    rep_e = len(es) - len(set(es))
    hs = [e.split("\n", 1)[0] for e in es]
    rep_h = len(hs) - len(set(hs))
    if PERTURB == "dup-blind":
        rep_e = rep_h = 0
    if headings:
        print(f"headings {len(hs)}  repeated {rep_h}  ({path})")
    print(f"entries {len(es)}  repeated {rep_e}  ({path})")
    for h in sorted({h for h in hs if hs.count(h) > 1}):
        print(f"  repeated heading: {h[:100]}")
    return 1 if rep_e or (headings and rep_h) else 0


def row_copy(title, copy, state, write=False):
    row, why = newest_row(open(state, encoding="utf-8").read(), title)
    if row is None:
        print(f"row: {why}")
        return 2
    sha = hashlib.sha1(row.encode()).hexdigest()[:12]
    if write:
        open(copy, "w", encoding="utf-8").write(row + "\n")
        print(f"row written to {copy} (row sha1 {sha})")
        return 0
    if not os.path.exists(copy):
        print(f"row: no copy at {copy}")
        return 2
    got = open(copy, encoding="utf-8").read()
    if got == row + "\n" or PERTURB == "stale-row-accepted":
        print(f"row copy {copy} equals the newest group's row {title} (row sha1 {sha})")
        return 0
    i = next((k for k, (a, b) in enumerate(zip(got, row + "\n")) if a != b), min(len(got), len(row) + 1))
    print(f"row copy {copy} DIFFERS from the newest group's row {title}: first difference at char {i + 1}")
    return 1


def plant(kind, title, out, root="."):
    p = lambda f: os.path.join(root, f)
    os.makedirs(out, exist_ok=True)
    try:
        if kind == "bare-none":
            s = open(p("STATE.md"), encoding="utf-8").read()
            row, why = newest_row(s, title)
            if row is None:
                die(f"plant bare-none: {why}", 3)
            new = row if PERTURB == "plant-is-live" else re.sub(r"\s*\|\s*$", "", row) + "; (z) PLANTED finding — `STATE.md` / none |"
            dst, body = "STATE_plant.md", s.replace(row, new, 1)
        elif kind == "row-stale":
            row, why = newest_row(open(p("STATE.md"), encoding="utf-8").read(), title)
            if row is None:
                die(f"plant row-stale: {why}", 3)
            k = len(row) // 2
            new = row if PERTURB == "plant-is-live" else row[:k] + ("y" if row[k] == "x" else "x") + row[k + 1:]
            dst, body = "findings_row_plant.txt", new + "\n"
        elif kind == "next-closed":
            st = ticket_status(p("docs/project/tickets.tsv"))
            closed = next((n for n, s in sorted(st.items(), key=lambda x: int(x[0])) if s != "open"), None)
            s = open(p("docs/NEXT_SESSION.md"), encoding="utf-8").read()
            if closed is None or "\n## START HERE" not in s:
                die("plant next-closed: no ticket that is not open, or no START HERE", 3)
            line = "" if PERTURB == "plant-is-live" else f"\n- PLANTED: #{closed} (status {st[closed]} in the index)\n"
            dst, body = "NEXT_SESSION_plant.md", re.sub(r"(\n## START HERE[^\n]*\n)", lambda m: m.group(1) + line, s, count=1)
        elif kind in ("dup-decisions", "dup-state-history"):
            src = "DECISIONS_HISTORY.md" if kind == "dup-decisions" else "STATE_HISTORY.md"
            s = open(p(src), encoding="utf-8").read()
            es = [e for e in re.split(r"(?m)^(?=## )", s) if e.startswith("## " if kind == "dup-decisions" else "## Session ")]
            if not es:
                die(f"plant {kind}: no entry in {src}", 3)
            dst = src.replace(".md", "_plant.md")
            body = s if PERTURB == "plant-is-live" else s.rstrip("\n") + "\n\n" + es[0].rstrip("\n") + "\n"
        else:
            die(f"plant: unknown kind {kind}", 3)
    except OSError as e:
        die(f"plant {kind}: {e}", 3)
    open(os.path.join(out, dst), "w", encoding="utf-8").write(body)
    print(f"plant {kind} -> {os.path.join(out, dst)}")
    return 0


def claim(root, run, premises=None):
    import close_checks, claim_lint
    checks, out = os.path.join(root, run, "checks.tsv"), os.path.join(root, run, "out")
    buf = io.StringIO()
    with redirect_stdout(buf):
        st = close_checks.status(checks, out)
    if st != 0 and PERTURB != "claim-partial-accepted":
        print("claim REFUSED — not a run of record: " + buf.getvalue().strip().replace("\n", " | "))
        return 1
    first, rows = close_checks.read_exits(os.path.join(out, "exits.tsv"))
    decl = {}
    for l in open(os.path.join(root, run, "checks_decl.tsv"), encoding="utf-8"):
        f = l.rstrip("\n").split("\t")
        if len(f) == 5 and f[0] != "name":
            decl[f[0]] = f
    names = [r[0] for r in close_checks.read_checks(checks)]
    m = re.match(r"# rendered by tools/close_standing.py from (\S+) \((\w+)\)", open(checks, encoding="utf-8").readline())
    if not m:
        print(f"claim REFUSED — {checks} was not rendered by this tool (no render line)")
        return 1
    added = sum(decl.get(n, [n, "?"])[1] == "extra" for n in names)
    parts = [f"The run of record `{run}/out/exits.tsv` ({first[2:].strip()}) holds the {len(names)} checks of "
             f"`{run}/checks.tsv` ({len(names) - added} rendered from `{m.group(1)}` at sha256 {m.group(2)}, {added} added by this close), "
             f"each exit as expected (`tools/close_checks.py` status 0)."]
    gaps = []
    for n in names:
        r, d = rows.get(n), decl.get(n)
        if not r or not d:
            print(f"claim REFUSED — {n} has no exits row or no declaration")
            return 1
        fig = ""
        if d[4] != "-":
            path = os.path.join(out, "runs", n + ".out")
            hit = next((l.strip() for l in open(path, encoding="utf-8", errors="replace")
                        if re.search(d[4], l)), None) if os.path.exists(path) else None
            if hit:
                fig = ' (output: "' + re.sub(r"\s+", " ", hit)[:160].replace('"', "'").replace("(", "[").replace(")", "]") + '")'
        parts.append(f"`{n}`: {d[2]} — exit {r[2]} as expected, {r[4]} s, `{run}/out/runs/{n}.out`{fig}.")
        if d[3] != "-":
            gaps.append(f"`{n}`: {d[3]}")
    tail = "NOT TESTED by these checks: " + "; ".join(gaps) + "."
    if premises:
        lines = [l.strip() for l in open(premises, encoding="utf-8") if l.strip() and not l.startswith("#")]
        if lines:
            tail += " This close's own premises, NOT TESTED: " + "; ".join(lines) + "."
    text = " ".join(parts + [tail])
    untied = claim_lint.lint(text)
    if untied:
        print("claim REFUSED — claim_lint finds untied universals: " + " | ".join(str(u) for u in untied))
        return 1
    print(text)
    return 0


# ---------------------------------------------------------------- self-test
def selftest():
    ok = True
    def say(cond, what):
        nonlocal ok
        print(("  ok: " if cond else "  FAIL: ") + what)
        ok = ok and cond
    T = "(4) THE FINDINGS TABLE"
    with tempfile.TemporaryDirectory() as d:
        w = lambda f, s: (os.makedirs(os.path.dirname(os.path.join(d, f)) or d, exist_ok=True), open(os.path.join(d, f), "w").write(s))
        w("STATE.md", "# STATE\n\n## Session 14z-9 — new\n\n| | |\n|---|---|\n| opened | x |\n"
          f"| **{T}** (step 1) | (a) one — `a.md` / `t.sh`; (b) two — `b.md` / none (a statement); ticket #7 (open) |\n"
          "\n## Session 14z-8 — old\n\n| | |\n|---|---|\n"
          f"| **{T}** (step 1) | (a) old — `a.md` / none; ticket #6 (open) |\n\n# STANDING SECTIONS\n")
        w("docs/NEXT_SESSION.md", "# NEXT\n\n## START HERE\n\n1. #5 and #7 go on.\n\n## FACTS\n\n#6 closed long ago.\n")
        w("docs/project/tickets.tsv", "issue\tkind\tstatus\ttitle\n5\tbug\topen\tx\n6\tbug\tdone\ty\n7\tbug\topen\tz\n")
        w("DECISIONS_HISTORY.md", "# D\n\n## Ruled A\n\nbody a\n\n## Ruled B\n\nbody b\n")
        w("STATE_HISTORY.md", "# H\n\n## Session 14z-2 (x)\n\n## Session 14z-2 (x)\n\nbody\n\n## Session 14z-1\n\nold\n")
        st, nx, tk = (os.path.join(d, f) for f in ("STATE.md", "docs/NEXT_SESSION.md", "docs/project/tickets.tsv"))
        def quiet(f, *a, **k):
            b = io.StringIO()
            with redirect_stdout(b):
                try:
                    r = f(*a, **k)
                except SystemExit as e:
                    r = e.code if isinstance(e.code, int) else 1
            return r, b.getvalue()
        r, o = quiet(open_tickets, T, nx, st, tk)
        say(r == 0 and "cited 2  not open 0" in o, "open-tickets: START HERE's #5 and #7 and the row's #7 (open) all open; #6 outside START HERE and in the OLDER group's row not read")
        pd = os.path.join(d, "plants")
        r, o = quiet(plant, "next-closed", T, pd, d)
        r2, o2 = quiet(open_tickets, T, os.path.join(pd, "NEXT_SESSION_plant.md"), st, tk)
        say(r == 0 and r2 == 1 and "#6 done" in o2, "plant next-closed: a generated START HERE citing #6 (done) fails the open-ticket check")
        r, _ = quiet(dup_entries, os.path.join(d, "DECISIONS_HISTORY.md"), True)
        say(r == 0, "dup-entries: distinct entries and headings pass")
        r, _ = quiet(plant, "dup-decisions", T, pd, d)
        r2, o2 = quiet(dup_entries, os.path.join(pd, "DECISIONS_HISTORY_plant.md"), True)
        say(r == 0 and r2 == 1 and "entries 3  repeated 1" in o2, "plant dup-decisions: the first entry appended again fails")
        r, o = quiet(dup_entries, os.path.join(d, "STATE_HISTORY.md"), False)
        r3, _ = quiet(dup_entries, os.path.join(d, "STATE_HISTORY.md"), True)
        say(r == 0 and r3 == 1, "dup-entries: a repeated heading with differing bodies passes the entry check and fails --headings")
        r, _ = quiet(plant, "dup-state-history", T, pd, d)
        r2, _ = quiet(dup_entries, os.path.join(pd, "STATE_HISTORY_plant.md"), False)
        say(r == 0 and r2 == 1, "plant dup-state-history: the first session group appended again fails")
        cp = os.path.join(d, "row.txt")
        r1, _ = quiet(row_copy, T, cp, st, False)
        r2, _ = quiet(row_copy, T, cp, st, True)
        r3, o3 = quiet(row_copy, T, cp, st, False)
        say(r1 == 2 and r2 == 0 and r3 == 0 and "(a) one" in open(cp).read(), "row-copy: no copy reads 2; the written copy is the NEWEST group's row and reads 0")
        r, _ = quiet(plant, "row-stale", T, pd, d)
        r2, _ = quiet(row_copy, T, os.path.join(pd, "findings_row_plant.txt"), st, False)
        say(r == 0 and r2 == 1, "plant row-stale: one character changed fails the copy check")
        import none_reasons
        r, _ = quiet(plant, "bare-none", T, pd, d)
        live, _ = none_reasons.check(open(st).read().split("## Session 14z-8")[0], T)
        got, _ = none_reasons.check(open(os.path.join(pd, "STATE_plant.md")).read().split("## Session 14z-8")[0], T)
        say(r == 0 and live == 0 and got == 1, "plant bare-none: the row gains a bare none and the reason check fails on it")
        for kind, f in (("bare-none", "STATE.md"), ("next-closed", "docs/NEXT_SESSION.md"), ("dup-decisions", "DECISIONS_HISTORY.md")):
            pf = {"bare-none": "STATE_plant.md", "next-closed": "NEXT_SESSION_plant.md", "dup-decisions": "DECISIONS_HISTORY_plant.md"}[kind]
            say(open(os.path.join(pd, pf)).read() != open(os.path.join(d, f)).read(), f"plant {kind} differs from the live file it was generated from")
        r, _ = quiet(plant, "bare-none", "(9) NO SUCH ROW", pd, d)
        say(r == 3, "a plant that cannot be built exits 3, never the 1 its check row expects")
        # render
        subprocess.run(["git", "init", "-q"], cwd=d)
        subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "14z-8: old"], cwd=d)
        subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "14z-9: first"], cwd=d)
        base = git(d, "rev-parse", "--short=8", "HEAD^").strip()
        w("tmpl.tsv", "# t\nnr\t0\tsees {KEY}\tnot {ROW}\t^x\techo {KEY} \"{ROW}\" {RUN} {SESSDIR} {BASE} {TRANSCRIPT}\n"
          "nr_plant\t1\tplanted\t-\t-\tfalse\n")
        w("extra.tsv", "mine\t0\tnew thing\t-\t-\ttrue\n")
        r, o = quiet(render, d, "14z-9", T, "build/a9/close", "/x/t.jsonl", os.path.join(d, "extra.tsv"), "tmpl.tsv")
        ck = open(os.path.join(d, "build/a9/close/checks.tsv")).read()
        say(r == 0 and f'echo 14z-9 "{T}" build/a9/close build/a9 {base} /x/t.jsonl' in ck and "{" not in ck.split("\n", 1)[1]
            and "mine\t0\ttrue" in ck, "render fills every placeholder, derives BASE as the parent of the first 14z-9 commit, and appends --extra")
        r, _ = quiet(render, d, "14z-9", 'bad "title"', "build/a9/close", "/x/t.jsonl", None, "tmpl.tsv")
        w("extra2.tsv", "nr\t0\tredefined\t-\t-\ttrue\n")
        r2, _ = quiet(render, d, "14z-9", T, "build/a9/close", "/x/t.jsonl", os.path.join(d, "extra2.tsv"), "tmpl.tsv")
        say(r == 1 and r2 == 1, "render refuses a title with a quote, and an --extra row redefining a standing check")
        # claim
        import close_checks
        run = "build/a9/close"
        w(run + "/checks.tsv", "# rendered by tools/close_standing.py from tmpl.tsv (0123abcd) for 14z-9\nnr\t0\techo every row x\nnr_plant\t1\texit 1\n")
        w(run + "/checks_decl.tsv", "name\tsource\twhat\tnot_seen\tfigure\nnr\tstanding\tevery row is seen\twhether all rows are true\t^every\n"
          "nr_plant\tstanding\tthe plant fails\t-\t-\n")
        quiet(close_checks.run, os.path.join(d, run, "checks.tsv"), os.path.join(d, run, "out"), [], d)
        w("prem.txt", "# premises\nthe tier ran on HEAD only\n")
        r, o = quiet(claim, d, run, os.path.join(d, "prem.txt"))
        say(r == 0 and "`nr`: every row is seen" in o and 'output: "every row x"' in o and "NOT TESTED" in o
            and "the tier ran on HEAD only" in o and o.count("\n") == 1, "claim: one line, a sentence per check with its figure, NOT TESTED from NOT SEEN and the premises")
        quiet(close_checks.run, os.path.join(d, run, "checks.tsv"), os.path.join(d, run, "out"), ["nr"], d)
        r, o = quiet(claim, d, run, None)
        say(r == 1 and "REFUSED" in o, "claim refuses a partial run")
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def opt(a, name, default=None):
    return a[a.index(name) + 1] if name in a and a.index(name) + 1 < len(a) else default


def main():
    global PERTURB
    a = sys.argv[1:]
    PERTURB = opt(a, "--perturb", "")
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or os.getcwd()
    if a[:1] == ["--selftest"]:
        return selftest()
    if not a:
        die(__doc__)
    c = a[0]
    if c == "render":
        if not (opt(a, "--key") and opt(a, "--row") and opt(a, "--run")):
            die("render needs --key --row --run")
        return render(root, opt(a, "--key"), opt(a, "--row"), opt(a, "--run"), opt(a, "--transcript"), opt(a, "--extra"), opt(a, "--template"))
    if c == "open-tickets":
        return open_tickets(opt(a, "--row", ""), opt(a, "--next", "docs/NEXT_SESSION.md"), opt(a, "--state", "STATE.md"),
                            opt(a, "--tickets", "docs/project/tickets.tsv"))
    if c == "dup-entries" and len(a) > 1:
        return dup_entries([x for x in a[1:] if not x.startswith("--")][0], "--headings" in a)
    if c == "row-copy":
        return row_copy(opt(a, "--row", ""), opt(a, "--copy", ""), opt(a, "--state", "STATE.md"), "--write" in a)
    if c == "plant" and len(a) > 1:
        return plant(a[1], opt(a, "--row", ""), opt(a, "--out", "."))
    if c == "claim":
        return claim(root, opt(a, "--run", ""), opt(a, "--premises"))
    die(__doc__)


if __name__ == "__main__":
    sys.exit(main())
