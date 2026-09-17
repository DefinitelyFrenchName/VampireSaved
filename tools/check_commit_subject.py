#!/usr/bin/env python3
"""check_commit_subject.py — refuse a commit message that GitHub would read as
CLOSING an issue (14z-162, GitHub #151).

THE MECHANISM. A commit pushed to the default branch whose message carries one
of GitHub's closing keywords (close/closes/closed, fix/fixes/fixed,
resolve/resolves/resolved) directly before an issue reference (`#N`,
`owner/repo#N`, or an issue URL) closes that issue on push, and GitHub
attributes the close to the PUSHING account. An optional colon between the
keyword and the reference is accepted. This project's session-close commit
subjects were shaped `14z-N CLOSE: #<ticket> ...`, and that shape closed the
same issue twice (#151: 22:22Z on 2026-09-16 and 00:17Z on 2026-09-17, each at the second of
its push) and #136 once; the second close was then recorded as a deliberate act
of the maintainer, who had never been asked (docs/project/gotchas.md, the
14z-162 entry). Closing a ticket is a decision ([VSP-182]) and never a side
effect of a commit message.

WHAT IT CHECKS. Every line of every message in scope, subject and body alike —
GitHub reads the whole message. A match is reported with the commit and the
line; the exit status is 1 on any match, 0 otherwise. The check is textual and
case-insensitive, like GitHub's.

SCOPE.
  --file MSG        one message file (the commit-msg hook's argument)
  --range A..B      the commits in that range (default `origin/main..HEAD`;
                    when the range is empty or `origin/main` is unknown, HEAD)
  --selftest        the frozen fixtures below, assembled from pieces so this
                    file's own text never carries the flagged shape

Usage: python3 tools/check_commit_subject.py [--file MSG | --range A..B | --selftest]
Hook: tools/install_hooks.sh installs the commit-msg hook that runs `--file`.
Gate: tests/test_commit_subject.sh.
"""
import argparse
import re
import subprocess
import sys

KEYWORDS = r"(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)"
REF = r"(?:#\d+|[\w.-]+/[\w.-]+#\d+|https?://github\.com/[\w.-]+/[\w.-]+/issues/\d+)"
PATTERN = re.compile(r"\b" + KEYWORDS + r"\s*:?\s*" + REF, re.IGNORECASE)


def hits(message):
    """Every (line number, line, matched text) GitHub would act on."""
    out = []
    for n, line in enumerate(message.splitlines(), 1):
        for m in PATTERN.finditer(line):
            out.append((n, line.rstrip(), m.group(0)))
    return out


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def commits_in(rng):
    try:
        git("rev-parse", "--verify", "--quiet", rng.split("..")[0] + "^{commit}")
    except subprocess.CalledProcessError:
        return ["HEAD"]
    shas = git("rev-list", rng).split()
    return shas or ["HEAD"]


def check_range(rng):
    bad = 0
    shas = commits_in(rng)
    for sha in shas:
        msg = git("log", "-1", "--format=%B", sha)
        short = git("log", "-1", "--format=%h", sha).strip()
        for n, line, m in hits(msg):
            print(f"CLOSING KEYWORD: {short} line {n}: `{m}` in: {line[:120]}")
            bad += 1
    print(f"checked {len(shas)} commit(s) in {rng}: {bad} closing keyword(s)")
    return bad


def check_file(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        msg = f.read()
    bad = 0
    for n, line, m in hits(msg):
        print(f"CLOSING KEYWORD: line {n}: `{m}` in: {line[:120]}")
        bad += 1
    if bad:
        print("REFUSED: this message would close the issue(s) above on push. "
              "Closing a ticket is a decision, never a commit's side effect — reword "
              "(e.g. `14z-N CLOSE — #151 step 3 ...`, or `the fix for #99`).")
    return bad


def selftest():
    # Assembled from pieces: this file must never itself contain the shape.
    kw, sp, ref = "CLOSE", ": ", "#" + "151"
    cases = [
        ("14z-161 " + kw + sp + ref + " step 3 — the sweep", True),   # the 14z-161 subject shape
        ("Fixes" + ": " + "#" + "12 the thing", True),
        ("resolves owner/repo" + "#" + "3", True),
        ("closed " + "https://github.com/o/r/issues/" + "7", True),
        ("14z-161 " + kw + " — " + ref + " step 3", False),          # a dash breaks the adjacency
        ("the fix for " + ref, False),
        (ref + " closed by the maintainer", False),                    # ref before the keyword
        ("#149/#147 closed invalid by ruling", False),
        ("prefixes " + ref, False),                                    # \b: 'fixes' inside 'prefixes'
    ]
    bad = 0
    for text, expect in cases:
        got = bool(hits(text))
        mark = "ok " if got == expect else "BAD"
        if got != expect:
            bad += 1
        print(f"  {mark} flagged={got!s:5} expected={expect!s:5}  {text}")
    print(f"selftest: {len(cases)} fixtures, {bad} wrong")
    return bad


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--file")
    ap.add_argument("--range", default="origin/main..HEAD")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return 1 if selftest() else 0
    if a.file:
        return 1 if check_file(a.file) else 0
    return 1 if check_range(a.range) else 0


if __name__ == "__main__":
    sys.exit(main())
