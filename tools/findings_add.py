#!/usr/bin/env python3
"""findings_add.py — append ONE finding to the sitting's FINDINGS TABLE when it is paid for, in the table's form, so the
form is never hand-typed (GitHub #206, 14z-189).

WHY. The close checklist's step 1 table (STATE.md, the newest group's row "(N) THE FINDINGS TABLE") was written AT the
close, reconstructed from the session's record; at the 14z-188 close, after two compactions, rule-checker run
2026-10-02-569 found two findings missing and run 562 three bare `none` tests and an unquoted statement. #206: append
each finding in the same commit that homes its fact ([VSP-12] "at discovery time" applied to the table), so the close
reviews a table instead of rebuilding one.

THE FORM (what tools/none_reasons.py, tools/homes_tracked.py and the rule-checker read):
    (x) <finding> — <home>[, <home>...] / <test>[, <test>...]            or  ... / none (<reason>)   or  ... / #N (open)
a home is a TRACKED file in backticks (plus any section words after it) or `GitHub #N` with a row in the ticket index;
a test is a tracked file in backticks, an OPEN ticket `#N (open)`, or `none (<reason>)` with a non-empty reason.

    python3 tools/findings_add.py --finding TEXT --home H [--home H...] (--test T [--test T...] | --ticket N | --none REASON)
                                  [--create] [--state STATE.md] [--dry-run]
      H and T: `path [section words]` (the first word must be a tracked file) or `#N`. The row is the newest group's row
      whose title ends "THE FINDINGS TABLE"; --create makes it when the group has none, numbered after the group's
      highest row, before its CLOSE row. The letter is the next after the row's highest; past (z) it refuses.
    python3 tools/findings_add.py --selftest [--perturb form-unchecked]
      a synthetic repo with known answers; --perturb form-unchecked is a known-bad variant that accepts an untracked
      home and an empty `none` reason — its self-test must FAIL (the must-fire control of tests/test_close_standing.sh).

WHAT IT CANNOT SEE: whether the finding is true, whether the home says it, and whether the table is complete.
"""
import os, re, subprocess, sys, tempfile

PERTURB = ""
TAIL = "THE FINDINGS TABLE"
DESC = " (checklist step 1: every finding, its live home, the test that reproduces it)"


class Refused(Exception):
    pass


def tracked(root, path):
    return subprocess.run(["git", "ls-files", "--error-unmatch", "--", path], cwd=root,
                          capture_output=True).returncode == 0


def tickets(root):
    st = {}
    p = os.path.join(root, "docs/project/tickets.tsv")
    if os.path.exists(p):
        for l in open(p, encoding="utf-8"):
            f = l.rstrip("\n").split("\t")
            if len(f) > 2 and f[0].isdigit():
                st[f[0]] = f[2]
    return st


def cite(root, value, role):
    """one home or test value -> its text in the table's form"""
    v = value.strip()
    if " — " in v and PERTURB != "form-unchecked":
        # #224 (14z-191): the table splits a finding at its LAST ` — `, so a separator inside a home or a
        # test moves the split and tools/findings_anchors.py reads the tail as the home
        raise Refused(f"{role} {v!r} contains ' — ', the table's own separator: shorten the anchor")
    m = re.fullmatch(r"(?:GitHub )?#(\d+)", v)
    if m:
        st = tickets(root).get(m.group(1))
        if st is None and PERTURB != "form-unchecked":
            raise Refused(f"{role} #{m.group(1)}: no row in docs/project/tickets.tsv")
        if role == "test":
            if st != "open" and PERTURB != "form-unchecked":
                raise Refused(f"test #{m.group(1)} is {st}, not open: a closed ticket tests nothing")
            return f"#{m.group(1)} (open)"
        return f"GitHub #{m.group(1)}"
    path, _, rest = v.partition(" ")
    if not tracked(root, path) and PERTURB != "form-unchecked":
        raise Refused(f"{role} {path!r} is not a tracked file (git ls-files): a build/ artifact or a typo is no home")
    return f"`{path}`" + (" " + rest.strip() if rest.strip() else "")


def group_bounds(lines):
    start = next((i for i, l in enumerate(lines) if l.startswith("## Session ")), None)
    if start is None:
        raise Refused("no '## Session' group in the STATE file")
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith(("## ", "# "))), len(lines))
    return start, end


def add(root, state, finding, homes, tests, ticket, none, create=False, dry=False):
    if not finding.strip() or re.search(r"\([a-z]\) |\||\n", finding):
        raise Refused("the finding text is empty, or holds `|`, a newline or a `(x) ` letter form that would split the row")
    if not homes:
        raise Refused("a finding needs at least one --home")
    if sum(bool(x) for x in (tests, ticket, none is not None)) != 1:
        raise Refused("give exactly one of --test, --ticket, --none")
    if none is not None and not none.strip() and PERTURB != "form-unchecked":
        raise Refused("--none needs its reason: a bare `none` reads the same as a test nobody wrote (rule-checker run 2026-10-02-563)")
    home_txt = ", ".join(cite(root, h, "home") for h in homes)
    if tests:
        test_txt = ", ".join(cite(root, t, "test") for t in tests)
    elif ticket:
        test_txt = cite(root, "#" + str(ticket).lstrip("#"), "test")
    else:
        test_txt = f"none ({none.strip()})" if none.strip() else "none"
    p = os.path.join(root, state)
    text = open(p, encoding="utf-8").read()
    lines = text.split("\n")
    start, end = group_bounds(lines)
    rows = [i for i in range(start, end) if re.match(r"\| \*\*\(\d+\) " + TAIL + r"\*\*", lines[i])]
    if len(rows) > 1:
        raise Refused(f"the newest group has {len(rows)} findings rows")
    if not rows:
        if not create:
            raise Refused("the newest group has no findings row: pass --create to make it")
        nums = [int(m.group(1)) for l in lines[start:end] for m in [re.match(r"\| \*\*\((\d+)\)", l)] if m]
        n = max(nums + [0]) + 1
        title = f"({n}) {TAIL}"
        at = next((i for i in range(start, end) if lines[i].startswith("| **CLOSE")), None)
        if at is None:
            at = max((i for i in range(start, end) if lines[i].startswith("|")), default=None)
            if at is None:
                raise Refused("the newest group has no table to put the row in")
            at += 1
        lines.insert(at, f"| **{title}**{DESC} | |")
        rows = [at]
    i = rows[0]
    row = lines[i]
    title = re.match(r"\| \*\*(.*?)\*\*", row).group(1)
    used = re.findall(r"(?:^|; |\| )\(([a-z])\) ", row)
    if used and max(used) == "z":
        raise Refused("letters exhausted at (z)")
    letter = chr(ord(max(used)) + 1) if used else "a"
    body = re.sub(r"\s*\|\s*$", "", row)
    sep = "; " if used else " "
    entry = f"({letter}) {finding.strip()} — {home_txt} / {test_txt}"
    lines[i] = body + sep + entry + " |"
    if not dry:
        open(p, "w", encoding="utf-8").write("\n".join(lines))
    print(f"{'would add' if dry else 'added'} ({letter}) to row {title}: {entry}")
    return title, letter


def selftest():
    ok = True
    def say(cond, what):
        nonlocal ok
        print(("  ok: " if cond else "  FAIL: ") + what)
        ok = ok and cond
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import none_reasons
    with tempfile.TemporaryDirectory() as d:
        def w(f, s):
            os.makedirs(os.path.dirname(os.path.join(d, f)) or d, exist_ok=True)
            open(os.path.join(d, f), "w").write(s)
        w("a.md", "x\n"); w("tests/t.sh", "x\n")
        w("docs/project/tickets.tsv", "issue\tkind\tstatus\ttitle\n7\tbug\topen\tz\n6\tbug\tdone\ty\n")
        old = "| **(2) THE FINDINGS TABLE** (old) | (a) old — `a.md` / none |"
        w("STATE.md", "# STATE\n\n## Session 14z-9 — new\n\n| | |\n|---|---|\n| opened | x |\n| **(1) WORK** | y |\n"
          "| **CLOSE (14z-9)** | z |\n\n## Session 14z-8 — old\n\n| | |\n|---|---|\n" + old + "\n\n# STANDING SECTIONS\n")
        subprocess.run(["git", "init", "-q"], cwd=d)
        subprocess.run(["git", "add", "a.md", "tests/t.sh", "docs/project/tickets.tsv"], cwd=d)
        def tryit(**k):
            try:
                return add(d, "STATE.md", **k), ""
            except Refused as e:
                return None, str(e)
        r, why = tryit(finding="f1", homes=["a.md"], tests=["tests/t.sh"], ticket=None, none=None)
        say(r is None and "--create" in why, "no findings row in the newest group: refused without --create")
        r, _ = tryit(finding="the first finding", homes=['a.md "Its section"'], tests=["tests/t.sh"], ticket=None, none=None, create=True)
        s = open(os.path.join(d, "STATE.md")).read()
        say(r == ("(2) THE FINDINGS TABLE", "a") and '| **(2) THE FINDINGS TABLE**' in s.split("## Session 14z-8")[0]
            and s.index("(2) THE FINDINGS TABLE") < s.index("**CLOSE (14z-9)**"),
            "--create numbers the row after the group's highest, before its CLOSE row, and the first finding is (a)")
        r, _ = tryit(finding="a statement", homes=["a.md", "#7"], tests=None, ticket=None, none="a working-practice lesson")
        r2, _ = tryit(finding="carried", homes=["a.md"], tests=None, ticket=7, none=None)
        s = open(os.path.join(d, "STATE.md")).read()
        say(r and r[1] == "b" and r2 and r2[1] == "c" and "(a) the first finding — `a.md` \"Its section\" / `tests/t.sh`; (b) a statement — `a.md`, GitHub #7 / none (a working-practice lesson); (c) carried — `a.md` / #7 (open) |" in s,
            "letters run on, homes are backticked tracked files or GitHub #N, the test forms are a file, none (reason) and #N (open)")
        say(old in s, "the older group's same-titled row is untouched")
        code, _ = none_reasons.check(s, "(2) THE FINDINGS TABLE")
        say(code == 0, "the row the tool wrote passes tools/none_reasons.py (newest group)")
        for k, want in ((dict(finding="x", homes=["build/x.log"], tests=["tests/t.sh"], ticket=None, none=None), "not a tracked file"),
                        (dict(finding="x", homes=["a.md"], tests=None, ticket=None, none=""), "reason"),
                        (dict(finding="x", homes=["a.md"], tests=None, ticket=6, none=None), "not open"),
                        (dict(finding="has (q) inside", homes=["a.md"], tests=["tests/t.sh"], ticket=None, none=None), "letter form"),
                        (dict(finding="x", homes=["a.md"], tests=["tests/t.sh"], ticket=7, none=None), "exactly one"),
                        (dict(finding="x", homes=["a.md Ruled — y"], tests=["tests/t.sh"], ticket=None, none=None), "separator")):
            r, why = tryit(**k)
            say(r is None and want in why, f"refused: {want}")
        before = open(os.path.join(d, "STATE.md")).read()
        add(d, "STATE.md", "dry", ["a.md"], ["tests/t.sh"], None, None, dry=True)
        say(open(os.path.join(d, "STATE.md")).read() == before, "--dry-run writes nothing")
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    global PERTURB
    a = sys.argv[1:]
    if "--perturb" in a:
        PERTURB = a[a.index("--perturb") + 1]
    if a[:1] == ["--selftest"]:
        return selftest()
    def many(name):
        return [a[i + 1] for i, x in enumerate(a) if x == name and i + 1 < len(a)]
    def one(name):
        v = many(name)
        return v[0] if v else None
    if not one("--finding"):
        sys.exit(__doc__)
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or os.getcwd()
    try:
        add(root, one("--state") or "STATE.md", one("--finding"), many("--home"), many("--test"), one("--ticket"),
            one("--none"), "--create" in a, "--dry-run" in a)
    except Refused as e:
        print(f"REFUSED: {e}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
