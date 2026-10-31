#!/usr/bin/env python3
"""dead_exit_census.py — a control mode's DEAD branch printed in words (#310 group 2, 14z-215).

A gate run under CONTROL=<name> must reach its own FAIL. When its perturbation changed no verdict the gate is
expected to say so with `CONTROL DEAD: <name> — …` (tests/lib/controls.sh `vs_ctl_dead` / `vs_ctl_left_green`), which
tests/lib/classify.sh rule 1 reads LIES. A dead branch that prints the same news in WORDS ("control mode X left the
gate green", "the planted escape passed") and exits 1 reads HONOURED: a control that tested nothing certified as
caught. Measured 14z-210/215 (#310's census, build/agent215/t310/deadexit_head.txt): 42 gates, about 89 controls.

THE SCAN is two line patterns, the ones the census used (build/agent215/t310/deadexit.awk), over tests/*.sh:
  P1  a line `echo "…"; exit 1` straight after a fired branch `… && { echo "…"; exit 1; }` / `|| { … }`
  P2  a line `echo "…<passed|dead|not named|not caught|tests nothing|still|green>…"; exit 1` on a line that also
      names the mode (VS_CTL, MODE, CONTROL, vs_ctl_is)
A line carrying vs_ctl_dead, vs_ctl_left_green, `CONTROL DEAD`, `NOT JUDGED` or `REFUSED` is not a word-only exit.
Two refinements over the census's awk, each for a match it made that is not a dead branch: the P2 word is matched
as a WORD of the message (the census matched "dead" inside "audit_df_dead_family"), and a line guarded by
`-z "$MODE"` / `-z "${VS_CTL…` runs only OUTSIDE a mode (the in-gate provenance controls), so no mode reaches it.

WHAT IT DOES NOT SEE (inference, held by tests/test_dead_exit_census.sh's known-gap plant): a dead branch phrased
another way — split over lines, printed with printf, exiting through a variable or a function — is not matched.
The scan is a tripwire for the copied block, not a proof that no word-only dead exit exists.

TWO MORE SHAPES (#310 group 6, 14z-215; the maintainer, 2026-10-31: "... and two new dead-exit patterns"), printed
`DEADEXIT`: a mode whose plant did not apply, or whose finding is never tested, still reads HONOURED.
  P4  an UNCONDITIONAL mode exit: at the script's top level (column 0) a branch taken on the mode alone —
      `if vs_ctl_is X; then echo "…"; exit 1; fi`, `vs_ctl_is X && { echo "…"; exit 1; }`, or the `if` with only
      echo lines and `exit 1` in its body (also `[ "$VS_CTL" = X ]`, `[ -n "$VS_CTL" ]`, `$CONTROL`, `$MODE`) — exits 1
      whether or not the mode's own finding fired, so a dead control reads HONOURED. An INDENTED one sits inside a
      branch whose test may be the finding (test_wide_profile's, audit_marionette_cost's), so it is not named.
  P5  `|| exit 3` (or `|| { echo "…"; exit 3; }` / `&& { … }`) on a line with no `REFUSED` — classify.sh's rule 3
      reads exit 3 as UNJUDGED only beside a `REFUSED: ` line, so a plant that did not apply reads HONOURED.
WHAT P4/P5 DO NOT SEE (held by the gate's known-gap plants): an exit through a function or a `case` arm
(`*) echo "no such perturbation"; exit 3 ;;`), and an indented unconditional exit inside a loop or a function.

Usage: dead_exit_census.py [--root DIR] [extra .sh ...]   prints `WORDONLY|DEADEXIT <path>:<line>: [P] <text>`,
exits 1 on any.
"""
import argparse
import os
import re
import sys

FIRED = re.compile(r'(&&|\|\|) *\{ *echo "[^"]*"; *exit 1; *\}')
ECHO_EXIT = re.compile(r'^\s*echo "([^"]*)"; *exit 1')
P2 = re.compile(r'echo "([^"]*)"; *exit 1')
P2_WORDS = re.compile(r'\b(passed|dead|not named|not caught|tests nothing|still|green)\b')
MODE_WORDS = re.compile(r'VS_CTL|MODE|CONTROL|vs_ctl_is')
# P3 (14z-215, found by this scan's own first run: test_charid_names and test_module_refs): the INVERTED block, whose
# dead branch is the braced one — `[ "$rc" -eq 0 ] && { echo "FAIL: the planted shift passed"; exit 1; }` — and whose
# next line is the honoured exit. A braced echo-exit on a green test (rc/st/e equal to 0) saying the plant passed.
P3_WORDS = re.compile(r'\b(passed|still|green|not named|not caught|tests nothing)\b')
P3_GREEN = re.compile(r'\[ "?\$\{?(rc|st|e|_rc|_st)\}?"? (-eq|=) 0 \] && \{ *echo ')
MARKED = re.compile(r'vs_ctl_dead|vs_ctl_left_green|CONTROL DEAD|NOT JUDGED|REFUSED')
PLAIN_ONLY = re.compile(r'-z "\$MODE"|-z "\$\{VS_CTL')
# P4 / P5 (#310 group 6)
MODE_TEST = (r'(vs_ctl_is "?[a-z0-9$-]+"?|\[ "\$\{?(VS_CTL|CONTROL|MODE)(:-)?\}?" = "?[a-z0-9-]+"? \]'
             r'|\[ -n "\$\{?(VS_CTL|CONTROL|MODE)(:-)?\}?" \])')
P4_ONE = re.compile(r'^(if ' + MODE_TEST + r'; then (echo\b[^;]*; *)+exit 1; *fi\b|' + MODE_TEST + r' && \{ *(echo\b[^;]*; *)+exit 1; *\})')
P4_OPEN = re.compile(r'^if ' + MODE_TEST + r'; then\s*$')
P4_BODY = re.compile(r'^\s*((echo\b[^;]*; *)*echo\b.*|(echo\b[^;]*; *)*exit 1)\s*$')
P4_FI = re.compile(r'^\s*fi\b')
P5 = re.compile(r'\|\| *exit 3\b|(\|\||&&) *\{[^}]*\bexit 3\b')


def p4_block(lines, i):
    """the multi-line P4: lines[i] opens `if <mode test>; then` at column 0 and its body, up to `fi` within six
    lines, is only echo lines ending in `exit 1` — the text joined with ' / ', or None"""
    if not P4_OPEN.search(lines[i]):
        return None
    body = []
    for j in range(i + 1, min(i + 7, len(lines))):
        if P4_FI.search(lines[j]):
            if body and all(P4_BODY.search(b) for b in body) and re.search(r'\bexit 1\s*$', body[-1]):
                return " / ".join([lines[i].strip()] + [b.strip() for b in body])
            return None
        body.append(lines[j])
    return None


def scan(path, label):
    hits = []
    prev = ""
    with open(path, encoding="utf-8", errors="replace") as f:
        lines = [x.rstrip("\n") for x in f]
    for n, cur in enumerate(lines, 1):
        if cur.lstrip().startswith("#"):   # a comment runs nothing (a header may quote the very block)
            continue
        if not MARKED.search(cur) and not PLAIN_ONLY.search(cur):
            if FIRED.search(prev) and ECHO_EXIT.search(cur):
                hits.append(("WORDONLY", label, n, "P1", cur.strip()))
            else:
                m = P2.search(cur)
                if m and P2_WORDS.search(m.group(1)) and MODE_WORDS.search(cur):
                    hits.append(("WORDONLY", label, n, "P2", cur.strip()))
                elif m and P3_WORDS.search(m.group(1)) and P3_GREEN.search(cur):
                    hits.append(("WORDONLY", label, n, "P3", cur.strip()))
            if P4_ONE.search(cur):
                hits.append(("DEADEXIT", label, n, "P4", cur.strip()))
            else:
                blk = p4_block(lines, n - 1)
                if blk:
                    hits.append(("DEADEXIT", label, n, "P4", blk))
        if "REFUSED" not in cur and P5.search(cur):
            hits.append(("DEADEXIT", label, n, "P5", cur.strip()))
        prev = cur
    return hits


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    ap.add_argument("extra", nargs="*")
    a = ap.parse_args()
    tdir = os.path.join(a.root, "tests")
    files = sorted(os.path.join("tests", f) for f in os.listdir(tdir) if f.endswith(".sh"))
    hits = []
    for rel in files:
        hits += scan(os.path.join(a.root, rel), rel)
    for x in a.extra:
        hits += scan(x if os.path.isabs(x) else os.path.join(a.root, x), x)
    for kind, label, n, pat, text in hits:
        print(f"{kind} {label}:{n}: [{pat}] {text[:160]}")
    nw = sum(1 for h in hits if h[0] == "WORDONLY")
    print(f"dead_exit_census: {len(files) + len(a.extra)} scripts read, {nw} word-only dead exit(s), "
          f"{len(hits) - nw} unconditional or unrefused mode exit(s)")
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main())
