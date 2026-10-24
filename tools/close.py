#!/usr/bin/env python3
"""close.py — the session close's DRIVER: runs the step table of docs/project/session_close.md in order
(GitHub #282 item C, ruled 2026-10-15: DECISIONS_HISTORY.md "Ruled 2026-10-15 (14z-201) — #282 item C").

WHY. The maintainer (#282): the close ritual "is almost never compeletely executed by default". A census found it in
58 places across 30 files, none complete. The table in docs/project/session_close.md is now the one copy, and this
driver reads that table, so the order a close runs in cannot drift from the order the doc gives.

  python3 tools/close.py start --key 14z-N --prev RESULTS.tsv [--run DIR] [--row TITLE] [--transcript ID]
      writes DIR/close_params.tsv (DIR default build/agent<N>/close for 14z-N). ROMDIR must be set and --prev exist.
  python3 tools/close.py next [--run DIR]
      runs the auto steps from the first step not done, in order; stops at a red (shows the log's tail) or at a manual
      step (shows what it needs). Each auto step logs to DIR/steps/<step>.log.
  python3 tools/close.py run STEP [--run DIR]       re-runs one auto step (after a fix)
      A RED step whose command confirms on {PREV} and writes {RUN}/tier_results.tsv (the tier) is re-run with
      --confirm on THE RED RUN'S results, kept as {RUN}/tier_results.red-<utc>.tsv, not on the previous close's (#317):
      the re-run re-runs what was not PASS there or changed since, and carries the rest
  python3 tools/close.py done STEP "EVIDENCE" [--run DIR]
      marks a manual step done, or passes a RED auto step by hand (shown as such); never a step not yet reached
  python3 tools/close.py status [--run DIR]         every step, its state, the commit it ran at, and NEXT
  python3 tools/close.py inputs [--run DIR]         the close-time input files exist (the `inputs` step)
  python3 tools/close.py check [--root DIR]         the table parses, its commands name only tools and tests that
      exist and only known placeholders, and the four live documents point to docs/project/session_close.md
  python3 tools/close.py --selftest [--perturb verdict-ignored|red-base-ignored]
      a synthetic table with known answers; the perturbed drivers (every exit read as 0; a re-run after a red based on
      {PREV} again) must FAIL it

WITHOUT --run, the run directory is $CLOSE_RUN (which the driver sets for every command it runs), else the newest
build/agent*/close/ holding a close_params.tsv.
WHAT IT CANNOT SEE: whether a manual step's evidence is true. A manual step is done when the operator says so in
writing; the documentation packet and the procedure check are what read those claims.
"""
import calendar, datetime, glob, os, re, shutil, subprocess, sys, tempfile

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
DOC = "docs/project/session_close.md"
LIVE = ("CLAUDE.md", "STATE.md", "HANDOFF.md", "docs/NEXT_SESSION.md")
PLACEHOLDERS = {"KEY", "RUN", "ROW", "PREV", "TRANSCRIPT", "ROMDIR"}
KINDS = ("auto", "manual")
PERTURB = ""
PROJ = os.path.expanduser("~/.claude/projects/-Users-koneko-Developer-Vampire-Saved-VampireSaved")


class Bad(Exception):
    pass


def steps(doc_text):
    """[(step, kind, command or '', verdict, done_when, source)] from the table between the CLOSE STEPS markers"""
    m = re.search(r"<!-- CLOSE STEPS.*?-->\n(.*?)<!-- /CLOSE STEPS -->", doc_text, re.S)
    if not m:
        raise Bad(f"no CLOSE STEPS table in {DOC}")
    out = []
    for line in m.group(1).splitlines():
        if not line.startswith("|") or line.startswith("|---") or line.startswith("| step |"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split(" | ")]
        if len(cells) != 6:
            raise Bad(f"a step row without six cells: {line[:80]!r}")
        step, kind, cmd, verdict, when, src = cells
        cmds = re.findall(r"`([^`]+)`", cmd)
        out.append((step, kind, cmds[0] if kind == "auto" and len(cmds) == 1 else "", verdict, when, src, cmd))
    return out


def check(root):
    """problems with the table and the pointers to it, [] when none"""
    probs = []
    try:
        rows = steps(open(os.path.join(root, DOC), encoding="utf-8").read())
    except (Bad, OSError) as e:
        return [str(e)]
    seen = set()
    for step, kind, cmd, verdict, when, src, raw in rows:
        if step in seen:
            probs.append(f"step {step}: DUPLICATE id")
        seen.add(step)
        if kind not in KINDS:
            probs.append(f"step {step}: kind {kind!r} is not one of {KINDS}")
        if kind == "auto":
            if not cmd:
                probs.append(f"step {step}: an auto step needs exactly one backticked command")
            if not re.fullmatch(r"exit 0|line \S.*", verdict):
                probs.append(f"step {step}: verdict {verdict!r} is not `exit 0` or `line <regex>`")
            if "|" in cmd:
                probs.append(f"step {step}: a pipe in the command (the table's cell separator)")
        for ph in re.findall(r"\{([A-Z_]+)\}", raw):
            if ph not in PLACEHOLDERS:
                probs.append(f"step {step}: UNKNOWN placeholder {{{ph}}}")
        for path in re.findall(r"(?<![\w/{])((?:tools|tests)/[\w./-]+\.(?:py|sh))", raw):
            if not os.path.exists(os.path.join(root, path)):
                probs.append(f"step {step}: names {path}, which does not exist")
    for doc in LIVE:
        p = os.path.join(root, doc)
        if not os.path.exists(p) or DOC not in open(p, encoding="utf-8").read():
            probs.append(f"{doc} does not point to {DOC}")
    return probs


def utc():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def head(root):
    return subprocess.run(["git", "rev-parse", "--short=8", "HEAD"], cwd=root, capture_output=True, text=True).stdout.strip() or "-"


def find_run(root, given):
    if given:
        return os.path.abspath(given)
    if os.environ.get("CLOSE_RUN"):   # set by the driver for the commands it runs (a step that calls the driver again)
        return os.path.abspath(os.environ["CLOSE_RUN"])
    cands = sorted(glob.glob(os.path.join(root, "build/agent*/close/close_params.tsv")), key=os.path.getmtime)
    if not cands:
        raise Bad("no close started: run `python3 tools/close.py start --key 14z-N --prev RESULTS.tsv` first")
    return os.path.dirname(cands[-1])


def read_tsv(path):
    d = {}
    if os.path.exists(path):
        for l in open(path, encoding="utf-8"):
            if l.startswith("#") or not l.strip():
                continue
            f = l.rstrip("\n").split("\t")
            d[f[0]] = f[1:]
    return d


def write_state(run, state, order):
    with open(os.path.join(run, "close_state.tsv"), "w", encoding="utf-8") as fh:
        fh.write("# step\tstate\tutc\thead\tnote — written by tools/close.py\n")
        for s in order:
            if s in state:
                fh.write("\t".join([s] + state[s]) + "\n")


def fill(cmd, params):
    return re.sub(r"\{([A-Z_]+)\}", lambda m: params.get(m.group(1), m.group(0)), cmd)


def judge(verdict, rc, log):
    if PERTURB == "verdict-ignored":   # the known-bad driver: every step reads as passed
        return True
    if verdict == "exit 0":
        return rc == 0
    rx = verdict[len("line "):]
    return re.search(rx, log, re.M) is not None


def red_base(run, row, state):
    """#317: the base a RED tier step is re-run on — the red run's own results, copied aside so the re-run's results
    file never overwrites the base it reads; None when the step is not a red confirming tier, or when the red run wrote
    no results of its own (refused before its runner: the results file is older than the red run's log), and the
    previous base then stands"""
    step, cmd = row[0], row[2]
    if PERTURB == "red-base-ignored":   # the known-bad driver: a re-run after a red confirms on {PREV} again
        return None
    if state.get(step, [""])[0] != "RED" or "--confirm {PREV}" not in cmd or "{RUN}/tier_results.tsv" not in cmd:
        return None
    res, logp = os.path.join(run, "tier_results.tsv"), os.path.join(run, "steps", step + ".log")
    if not (os.path.exists(res) and os.path.exists(logp)):
        return None
    m = re.match(r"# (\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ) ", open(logp, encoding="utf-8", errors="replace").readline())
    if not m or os.path.getmtime(res) < calendar.timegm(datetime.datetime.strptime(m.group(1), "%Y-%m-%dT%H:%M:%SZ").timetuple()):
        return None
    keep = os.path.join(run, "tier_results.red-" + utc().replace(":", "") + ".tsv")
    shutil.copyfile(res, keep)
    return keep


def run_step(root, run, params, row, state):
    step, kind, cmd = row[0], row[1], row[2]
    os.makedirs(os.path.join(run, "steps"), exist_ok=True)
    logp = os.path.join(run, "steps", step + ".log")
    base = red_base(run, row, state)
    if base:
        params = dict(params, PREV=base)
        print(f"-- {step}: re-run after a red — --confirm on the red run's results {os.path.relpath(base, root)}, not the previous close's (#317)")
    full = fill(cmd, params)
    print(f"-- {step}: {full}")
    sys.stdout.flush()
    with open(logp, "w", encoding="utf-8") as lf:
        lf.write(f"# {utc()} {head(root)} {full}\n")
        lf.flush()
        p = subprocess.run(["sh", "-c", full], cwd=root, stdout=lf, stderr=subprocess.STDOUT,
                           env=dict(os.environ, CLOSE_RUN=run))
    log = open(logp, encoding="utf-8", errors="replace").read()
    good = judge(row[3], p.returncode, log)
    state[step] = ["DONE" if good else "RED", utc(), head(root), f"exit {p.returncode}; log {os.path.relpath(logp, root)}"]
    if not good:
        tail = "\n".join(log.rstrip().splitlines()[-12:])
        print(f"RED   {step} (exit {p.returncode}, verdict `{row[3]}`) — {os.path.relpath(logp, root)}:\n{tail}")
    else:
        print(f"DONE  {step}")
    return good


def walk(root, run, doc_rows, only=None):
    params = {k: v[0] for k, v in read_tsv(os.path.join(run, "close_params.tsv")).items()}
    state = read_tsv(os.path.join(run, "close_state.tsv"))
    order = [r[0] for r in doc_rows]
    rc = 0
    for row in doc_rows:
        step, kind = row[0], row[1]
        if only and step != only:
            continue
        if not only and step in state and state[step][0] in ("DONE", "PASSED-BY-HAND"):
            continue
        if kind == "manual":
            print(f"NEXT  {step} (manual): {row[4]}")
            if row[6] not in ("-", ""):
                print(f"      command: {fill(row[6], params)}")
            print(f"      then: python3 tools/close.py done {step} \"<evidence: where it shows>\"")
            break
        if not run_step(root, run, params, row, state):
            rc = 1
            break
        if only:
            break
    write_state(run, state, order)
    return rc


def mark(root, run, rows, step, ev):
    """`done STEP EVIDENCE`: the step the close is at, a manual one or a RED auto one"""
    names = [r[0] for r in rows]
    if step not in names:
        raise Bad(f"no step {step!r} in the table")
    state = read_tsv(os.path.join(run, "close_state.tsv"))
    first_open = next((r[0] for r in rows if state.get(r[0], [""])[0] not in ("DONE", "PASSED-BY-HAND")), None)
    if step != first_open:
        raise Bad(f"{step} is not the step the close is at ({first_open}): steps are done in order")
    kind = next(r[1] for r in rows if r[0] == step)
    if kind == "auto" and state.get(step, [""])[0] != "RED":
        raise Bad(f"{step} is an auto step: `next` runs it; only a RED one can be passed by hand")
    state[step] = ["PASSED-BY-HAND" if kind == "auto" else "DONE", utc(), head(root), ev.replace("\t", " ")]
    write_state(run, state, names)
    print(f"{state[step][0]}  {step}: {ev}")
    return 0


def status(root, run, doc_rows):
    state = read_tsv(os.path.join(run, "close_state.tsv"))
    now = head(root)
    nxt = None
    for row in doc_rows:
        s = state.get(row[0])
        if s is None:
            mark = "pending"
            nxt = nxt or row[0]
        else:
            mark = s[0]
            if mark == "RED":
                nxt = nxt or row[0]
            if row[1] == "auto" and mark == "DONE" and s[2] != now:
                mark = f"DONE (STALE: at {s[2]}, HEAD {now})"
        flag = "  <- NEXT" if row[0] == nxt else ""
        print(f"  {row[0]:13} {row[1]:6} {mark}{flag}")
    print(f"next: {nxt or 'none — every step done'}")
    return 0


def inputs(root, run):
    params = {k: v[0] for k, v in read_tsv(os.path.join(run, "close_params.tsv")).items()}
    need = [(os.path.join(run, "classes.tsv"), "every scratch program classed (tools/scratch_census.py, checklist step 5)"),
            (os.path.join(run, "promises.tsv"), "every promise classed (tools/promise_check.py, checklist step 4)"),
            (os.path.join(run, "rulings_exempt.tsv"), "maintainer messages that are not rulings, each with its reason (tools/agent/rulings_verbatim.py)"),
            (os.path.join(root, f"tests/rulecheck/retractions/{params.get('KEY', '?')}.tsv"), "the sitting's retracted wordings (tools/retraction_grep.py)")]
    missing = [(p, why) for p, why in need if not os.path.exists(p)]
    for p, why in missing:
        print(f"MISSING {os.path.relpath(p, root)} — {why}")
    print(f"inputs: {len(need) - len(missing)} of {len(need)} present")
    return 1 if missing else 0


def start(root, a):
    key = a.get("--key")
    prev = a.get("--prev")
    if not key or not re.fullmatch(r"14z-\d+[a-z]?", key):
        raise Bad("--key 14z-N is required")
    if not prev or not os.path.exists(prev):
        raise Bad(f"--prev must name the previous close's tier results.tsv (got {prev!r})")
    if not os.environ.get("ROMDIR"):
        raise Bad("ROMDIR is not set: the tier steps would skip every ROM gate")
    run = os.path.abspath(a.get("--run") or os.path.join(root, f"build/agent{key.split('-', 1)[1]}/close"))
    row = a.get("--row")
    if not row:
        sys.path.insert(0, os.path.join(root, "tools"))
        import findings_table
        st = open(os.path.join(root, "STATE.md"), encoding="utf-8").read()
        m = re.search(r"(?m)^## Session .*?(?=^## |^# |\Z)", st, re.S)
        rows = re.findall(r"(?m)^### (\(\d+\) " + findings_table.TAIL + r")\s*$", m.group(0) if m else "")
        if len(rows) != 1:
            raise Bad(f"the newest group has {len(rows)} findings sections: pass --row")
        row = rows[0]
    tr = a.get("--transcript")
    if not tr:
        js = sorted(glob.glob(os.path.join(PROJ, "*.jsonl")), key=os.path.getmtime)
        if not js:
            raise Bad("no transcript found: pass --transcript")
        tr = os.path.basename(js[-1])[:8]
    os.makedirs(run, exist_ok=True)
    params = {"KEY": key, "RUN": run, "ROW": row, "PREV": os.path.abspath(prev), "TRANSCRIPT": tr, "ROMDIR": os.environ["ROMDIR"]}
    with open(os.path.join(run, "close_params.tsv"), "w", encoding="utf-8") as fh:
        fh.write(f"# the close's parameters — written by tools/close.py start {utc()}\n")
        for k, v in params.items():
            fh.write(f"{k}\t{v}\n")
    print(f"close {key} started in {os.path.relpath(run, root)}")
    for k, v in params.items():
        print(f"  {k:10} {v}")
    return 0


def selftest():
    ok = True

    def say(cond, what):
        nonlocal ok
        print(("  ok: " if cond else "  FAIL: ") + what)
        ok = ok and cond
    with tempfile.TemporaryDirectory() as d:
        os.makedirs(os.path.join(d, "docs/project"))
        os.makedirs(os.path.join(d, "tools"))
        open(os.path.join(d, "tools/x.py"), "w").write("")
        table = ("<!-- CLOSE STEPS: x -->\n| step | kind | command | verdict | done when | from |\n|---|---|---|---|---|---|\n"
                 "| one | auto | `echo {KEY} > one.out` | exit 0 | a | r |\n"
                 "| two | manual | - | - | b | r |\n"
                 "| three | auto | `echo NOT GREEN; exit 0` | line ^GREEN | c | r |\n"
                 "| four | auto | `python3 tools/x.py` | exit 0 | d | r |\n"
                 "| five | auto | `echo run=$CLOSE_RUN` | line ^run=/ | e | r |\n<!-- /CLOSE STEPS -->\n")
        open(os.path.join(d, DOC), "w").write(table)
        for doc in LIVE:
            os.makedirs(os.path.dirname(os.path.join(d, doc)) or d, exist_ok=True)
            open(os.path.join(d, doc), "w").write(f"see {DOC}\n")
        subprocess.run(["git", "init", "-q"], cwd=d)
        run = os.path.join(d, "run")
        os.makedirs(run)
        open(os.path.join(run, "close_params.tsv"), "w").write("KEY\t14z-9\n")
        rows = steps(open(os.path.join(d, DOC)).read())
        say([r[0] for r in rows] == ["one", "two", "three", "four", "five"] and check(d) == [], "the table parses in order and checks clean")
        rc = walk(d, run, rows)
        st = read_tsv(os.path.join(run, "close_state.tsv"))
        say(rc == 0 and st.get("one", [""])[0] == "DONE" and "two" not in st
            and open(os.path.join(d, "one.out")).read().strip() == "14z-9",
            "next runs an auto step with its placeholder filled, then stops at the manual step")
        st["two"] = ["DONE", utc(), "-", "by hand"]
        write_state(run, st, [r[0] for r in rows])
        rc = walk(d, run, rows)
        st = read_tsv(os.path.join(run, "close_state.tsv"))
        say(rc == 1 and st.get("three", [""])[0] == "RED" and "four" not in st,
            "a step whose log lacks its verdict line is RED although it exited 0, and the walk stops there")
        def refused(*a):
            try:
                mark(*a)
                return ""
            except Bad as e:
                return str(e)
        say("in order" in refused(d, run, rows, "four", "x") and "only a RED" not in refused(d, run, rows, "three", "SKIP covered elsewhere"),
            "done refuses a step the close is not at, and passes the RED step it is at by hand")
        st = read_tsv(os.path.join(run, "close_state.tsv"))
        say(st["three"][0] == "PASSED-BY-HAND" and walk(d, run, rows) == 0 and read_tsv(os.path.join(run, "close_state.tsv"))["four"][0] == "DONE",
            "a step passed by hand is shown as such, and the walk goes on past it")
        say(f"run={run}" in open(os.path.join(run, "steps/five.log")).read(),
            "every command runs with CLOSE_RUN set to the close's run directory (a step that calls the driver again finds it)")
        # #317: a red confirming tier re-runs on the red run's results; a red run that wrote none keeps the base
        open(os.path.join(d, "prev.tsv"), "w").write("previous-close\n")
        conf = ("<!-- CLOSE STEPS: x -->\n| step | kind | command | verdict | done when | from |\n|---|---|---|---|---|---|\n"
                "| tier | auto | `cat {PREV} >> {RUN}/bases.txt; echo --confirm {PREV} > /dev/null; "
                "test -f {RUN}/refuse || echo run$(($(wc -l < {RUN}/bases.txt))) > {RUN}/tier_results.tsv; "
                "test -f {RUN}/go` | exit 0 | t | r |\n<!-- /CLOSE STEPS -->\n")
        open(os.path.join(d, DOC), "w").write(conf)
        crun = os.path.join(d, "crun")
        os.makedirs(crun)
        open(os.path.join(crun, "close_params.tsv"), "w").write(f"KEY\t14z-9\nPREV\t{os.path.join(d, 'prev.tsv')}\nRUN\t{crun}\n")
        crows = steps(open(os.path.join(d, DOC)).read())
        r1 = walk(d, crun, crows)                 # red: based on the previous close, writes run1
        r2 = walk(d, crun, crows)                 # red again: based on run1, writes run2
        open(os.path.join(crun, "go"), "w").write("")
        r3 = walk(d, crun, crows)                 # green: based on run2
        bases = open(os.path.join(crun, "bases.txt")).read().split()
        kept = sorted(glob.glob(os.path.join(crun, "tier_results.red-*.tsv")))
        say(r1 == 1 and r2 == 1 and r3 == 0 and bases == ["previous-close", "run1", "run2"] and len(kept) >= 1,
            f"a re-run after a red confirms on the red run's results, kept aside (bases read: {bases})")
        st = read_tsv(os.path.join(crun, "close_state.tsv"))
        st["tier"] = ["RED", utc(), "-", "by hand"]
        write_state(crun, st, ["tier"])
        open(os.path.join(crun, "refuse"), "w").write("")
        os.utime(os.path.join(crun, "tier_results.tsv"), (1, 1))   # a results file older than the red run's log
        walk(d, crun, crows)
        b4 = open(os.path.join(crun, "bases.txt")).read().split()[3:]
        say(b4 == ["previous-close"], f"a red run that wrote no results of its own leaves the previous base (read: {b4})")
        bad = ("<!-- CLOSE STEPS: x -->\n| step | kind | command | verdict | done when | from |\n|---|---|---|---|---|---|\n"
               "| one | auto | `echo {NOPE}` | exit 0 | a | r |\n"
               "| four | auto | `python3 tools/gone.py` | exit 0 | d | r |\n"
               "| one | manual | - | - | b | r |\n<!-- /CLOSE STEPS -->\n")
        open(os.path.join(d, DOC), "w").write(bad)
        probs = check(d)
        say(any("UNKNOWN placeholder {NOPE}" in p for p in probs) and any("tools/gone.py" in p for p in probs)
            and any("DUPLICATE" in p for p in probs), "check names an unknown placeholder, a missing tool and a duplicate step")
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    global PERTURB
    argv = sys.argv[1:]
    if "--perturb" in argv:
        i = argv.index("--perturb")
        PERTURB = argv[i + 1]
        del argv[i:i + 2]
    if argv[:1] == ["--selftest"]:
        return selftest()
    if not argv:
        sys.exit(__doc__)
    cmd, rest = argv[0], argv[1:]
    opts, pos, i = {}, [], 0
    while i < len(rest):
        if rest[i].startswith("--"):
            opts[rest[i]] = rest[i + 1] if i + 1 < len(rest) else ""
            i += 2
        else:
            pos.append(rest[i])
            i += 1
    root = os.path.abspath(opts.get("--root") or REPO)
    try:
        if cmd == "check":
            probs = check(root)
            for p in probs:
                print(f"FAIL  {p}")
            n = len(steps(open(os.path.join(root, DOC), encoding="utf-8").read())) if not any("no CLOSE STEPS" in p for p in probs) else 0
            print(f"close table: {n} steps, {len(probs)} problem(s)")
            return 1 if probs else 0
        if cmd == "start":
            return start(root, opts)
        run = find_run(root, opts.get("--run"))
        rows = steps(open(os.path.join(root, DOC), encoding="utf-8").read())
        if cmd == "next":
            return walk(root, run, rows)
        if cmd == "run":
            if not pos or not any(r[0] == pos[0] and r[1] == "auto" for r in rows):
                raise Bad("run STEP: STEP must be an auto step of the table")
            return walk(root, run, rows, only=pos[0])
        if cmd == "done":
            if len(pos) != 2 or not pos[1].strip():
                raise Bad('done STEP "EVIDENCE": both are required')
            return mark(root, run, rows, pos[0], pos[1])
        if cmd == "status":
            return status(root, run, rows)
        if cmd == "inputs":
            return inputs(root, run)
        raise Bad(f"unknown command {cmd!r}")
    except Bad as e:
        print(f"REFUSED: {e}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
