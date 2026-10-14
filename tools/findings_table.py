#!/usr/bin/env python3
"""findings_table.py — a session's FINDINGS TABLE is a tracked TSV; STATE.md's section points to it
(GitHub #282 item C, ruled 2026-10-15: DECISIONS_HISTORY.md "Ruled 2026-10-15 (14z-201) — #282 item C").

WHY. Until 14z-200 the table was ONE markdown row in STATE.md, `| **(N) THE FINDINGS TABLE** | (a) ...; (b) ... |`,
several kilobytes on one line, rewritten in place by tools/findings_add.py for every finding. The maintainer ruled the
session rows into short sections and the table into a TSV that the close tools read.

THE FORM. A session group carries a section

    ### (N) THE FINDINGS TABLE
    `docs/project/findings/<key>.tsv` — every finding, its live home, the test that reproduces it (checklist step 1).

and the TSV (written only by tools/findings_add.py) holds one finding per line, `#` lines being comments:

    letter<TAB>finding<TAB>homes<TAB>test

each cell in the table's own form (tools/findings_add.py's docstring): homes `` `path` section words `` or
`GitHub #N`, joined by ", "; the test a backticked tracked file, `#N (open)` or `none (<reason>)`.

THE READERS. expand(text, root) returns STATE text with every pointer section replaced by the one-line row the
close tools have always parsed — `| **(N) THE FINDINGS TABLE** (`<tsv>`) | (a) <finding> — <homes> / <test>; ... |`
— so tools/homes_tracked.py, none_reasons.py, findings_anchors.py, close_standing.py and session_metrics.py read a
TSV-backed group and an archived markdown row alike. A section naming a TSV that does not exist expands to a row
saying so, which every reader then fails on (a missing table is never an empty one).

  python3 tools/findings_table.py expand [STATE.md]    # print the expanded text (what the readers see)
  python3 tools/findings_table.py --selftest
"""
import os
import re
import sys
import tempfile

TAIL = "THE FINDINGS TABLE"
DIR = "docs/project/findings"
HEADER = ("# the findings table of session {key} — written by tools/findings_add.py, read through tools/findings_table.py"
          " (#282 item C)\n# letter\tfinding\thomes\ttest\n")
SECTION = re.compile(r"^### (\(\d+\) " + TAIL + r")\s*$")
POINTER = re.compile(r"`([^`]+\.tsv)`")


def tsv_path(key):
    return f"{DIR}/{key}.tsv"


def read(path):
    """[(letter, finding, homes, test)] from a findings TSV, in file order"""
    out = []
    for n, line in enumerate(open(path, encoding="utf-8"), 1):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        f = line.split("\t")
        if len(f) != 4 or not re.fullmatch(r"[a-z]", f[0]):
            raise ValueError(f"{path}:{n}: not `letter<TAB>finding<TAB>homes<TAB>test`: {line[:80]!r}")
        out.append(tuple(f))
    return out


def row(title, rel, records):
    body = "; ".join(f"({l}) {f} — {h} / {t}" for l, f, h, t in records)
    return f"| **{title}** (`{rel}`) | {body} |"


def expand(text, root="."):
    """STATE text with each findings pointer section replaced by its one-line row (see the docstring)"""
    lines = text.split("\n")
    out, i = [], 0
    while i < len(lines):
        m = SECTION.match(lines[i])
        if not m:
            out.append(lines[i])
            i += 1
            continue
        j = i + 1
        while j < len(lines) and not lines[j].startswith(("### ", "## ", "# ")):
            j += 1
        p = POINTER.search("\n".join(lines[i + 1:j]))
        rel = p.group(1) if p else None
        full = os.path.join(root, rel) if rel else None
        if full and os.path.exists(full):
            out.append(row(m.group(1), rel, read(full)))
        else:
            out.append(f"| **{m.group(1)}** (MISSING: {rel or 'no `.tsv` named in the section'}) | |")
        out.append("")
        i = j
    return "\n".join(out)


def read_state(path, root=None):
    """a STATE file's text, expanded; root defaults to the repository the file is in"""
    text = open(path, encoding="utf-8").read()
    if root is None:
        root = os.path.dirname(os.path.abspath(__file__)) + "/.."
    return expand(text, root)


def selftest():
    ok = True

    def say(cond, what):
        nonlocal ok
        print(("  ok: " if cond else "  FAIL: ") + what)
        ok = ok and cond
    with tempfile.TemporaryDirectory() as d:
        os.makedirs(os.path.join(d, DIR))
        open(os.path.join(d, tsv_path("14z-9")), "w").write(
            HEADER.format(key="14z-9") + "a\tone\t`a.md` X\t`t.sh`\nb\ttwo\tGitHub #7\tnone (a statement)\n")
        state = ("## Session 14z-9 — new\n\n### (1) WORK\ny\n\n### (2) THE FINDINGS TABLE\n"
                 "`docs/project/findings/14z-9.tsv` — every finding.\n\n### CLOSE (14z-9)\nz\n\n"
                 "## Session 14z-8 — old\n\n| **(2) THE FINDINGS TABLE** (x) | (a) old — `a.md` / none (r) |\n")
        e = expand(state, d)
        say("| **(2) THE FINDINGS TABLE** (`docs/project/findings/14z-9.tsv`) | (a) one — `a.md` X / `t.sh`; "
            "(b) two — GitHub #7 / none (a statement) |" in e, "a pointer section expands to the one-line row")
        say("### CLOSE (14z-9)" in e and "### (1) WORK" in e, "the sections around it are kept")
        say("| **(2) THE FINDINGS TABLE** (x) | (a) old" in e, "an archived markdown row is left as it is")
        e2 = expand(state.replace("14z-9.tsv`", "14z-0.tsv`"), d)
        say("(MISSING: docs/project/findings/14z-0.tsv) | |" in e2, "a section naming a missing TSV expands to MISSING")
        open(os.path.join(d, "bad.tsv"), "w").write("a\tonly three\tcells\n")
        try:
            read(os.path.join(d, "bad.tsv"))
            say(False, "a malformed line is refused")
        except ValueError:
            say(True, "a malformed line is refused")
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    if a[:1] == ["expand"]:
        sys.stdout.write(read_state(a[1] if len(a) > 1 else "STATE.md"))
        return 0
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main())
