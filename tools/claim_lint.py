#!/usr/bin/env python3
"""claim_lint.py — every UNIVERSAL or DEFINITE in a rule-checker claim is tied to a named check or to the claim's NOT
TESTED part (GitHub #185 item 3, ruled 2026-10-01 (14z-187b): "I agree with the item 3 proposal").

WHY. #185's finding: most of a close loop's rule-checker findings were universals and definites written from intent —
"every figure is compared", "the one FBNeo runner", "rebuilds every track" — with the check built afterwards to match.
A claim that says EVERY / ONLY / NONE / ALL / THE ONE asserts something about a whole set; the lint makes the writer say,
in the same clause, which check measured that set, or say that it is not tested.

THE WORDS are the five the proposal named; `each`, `no`, `never`, `always` are NOT read (a universal carried
by one of them passes unseen — run 2026-10-01-518's violated universal was carried by `each`).

THE RULE. The claim is split into SENTENCES, outside parentheses (a reference given in a parenthetical or a ";"
clause belongs to its sentence). A sentence holding one of the words — `every`,
`only`, `none`, `all`, `the one` (word-bounded, case-folded) — is TIED when it also holds one of:
  * a path to an artifact or a program: a token ending in .log .tsv .txt .sh .py .lua .diff .md .json .png .rpl .dis,
    one starting with build/ tests/ tools/ docs/, or a dir/name.ext relative path (the reader can open it);
  * a backticked name (`a_gate`, `a-control`) — a gate, a control, a field the artifacts name;
  * the words FIRED / FAILs / PASS next to a control, which name a check's verdict ("control x FIRED").
A clause in the NOT TESTED part (everything after "NOT tested" / "NOT TESTED" / "NOT covered", case-insensitive) is
tied by being there: a named gap is the claim's to accept. A frequency ("every 20 frames", "every other frame") and a
quotation ('every row as frozen') assert no set and are not read. Anything else is UNTIED and reported with its sentence.

It LINTS; it does not judge truth: a tied universal can still be false (that is the rule-checker's job), and an untied
one can be true. It makes the writer name the measurement or the gap before a reader is spent on it.

Usage:
  python3 tools/claim_lint.py --claim "TEXT" | --file PATH     exit 1 and a list of UNTIED clauses, else exit 0
  python3 tools/claim_lint.py --selftest
"""
import argparse, re, sys

WORDS = re.compile(r"\b(every|only|none|all|the one)\b", re.I)
PATH = re.compile(r"(?:(?<![\w/])(?:build|tests|tools|docs)/[\w./<>*-]+|[\w./<>*-]+\.(?:log|tsv|txt|sh|py|lua|diff|md|json|png|rpl|dis)\b|(?<![\w/])[\w.-]+/[\w./<>*-]+\.[A-Za-z]{2,4}\b)")
TICK = re.compile(r"`[^`\s][^`]*`")
VERDICT = re.compile(r"\bcontrols?\b[^;.]{0,80}\b(FIRED|FAILs?|PASS)\b|\b(FIRED|FAILs?)\b[^;.]{0,40}\bmode\b")
GAP = re.compile(r"\bNOT (tested|covered)\b", re.I)


FREQ = re.compile(r"\bevery\s+(?:\d|other\b)", re.I)   # only a NUMBER or "other": "every frame matches" asserts a set
QUOTED = re.compile(r"(?<!\w)'[^']*'(?!\w)|\"[^\"]*\"|\u201c[^\u201d]*\u201d")   # a quote opens and closes at a word edge: possessives are not quotes


def split_top(t):
    """sentences, split only OUTSIDE parentheses and brackets: a reference in a parenthetical belongs to its sentence"""
    out, depth, cur = [], 0, []
    for i, ch in enumerate(t):
        depth += ch in "([" ; depth -= ch in ")]" and depth > 0
        cur.append(ch)
        if depth == 0 and ch in ".!?" and (i + 1 == len(t) or t[i + 1].isspace()) and not re.search(r"\b(e\.g|i\.e|vs|etc)\.$", "".join(cur[-5:])):
            out.append("".join(cur).strip()); cur = []
    if "".join(cur).strip():
        out.append("".join(cur).strip())
    return [c for c in out if c]


def clauses(text):
    """-> [(sentence, in_gap)]; the gap part is everything after the first NOT tested/covered marker. The tie scope is
    the SENTENCE (outside parentheses), so a reference given in the same sentence ties the universal it supports."""
    m = GAP.search(text)
    head, gap = (text[:m.start()], text[m.start():]) if m else (text, "")
    return [(c, False) for c in split_top(head)] + [(c, True) for c in split_top(gap)]


def lint(text):
    """-> [(word, clause)] for every UNTIED universal/definite"""
    out = []
    for c, in_gap in clauses(text):
        bare = FREQ.sub(" ", QUOTED.sub(" ", c))   # a quotation and a frequency ("every 20 frames") assert no set
        words = [w.group(1).lower() for w in WORDS.finditer(bare)]
        if not words or in_gap:
            continue
        if PATH.search(c) or TICK.search(c) or VERDICT.search(c):
            continue
        out.append((", ".join(sorted(set(words))), c))
    return out


def selftest():
    cases = [
        ("untied universal", "Every row is compared and the gate passes", 1),
        ("tied by a path", "every row is compared (build/x/run.log PASS)", 0),
        ("tied by a file name", "all six roots confirmed (verify2.log)", 0),
        ("tied by a backticked name", "the only control is `range-short`", 0),
        ("tied by a control verdict", "all three controls FIRED", 0),
        ("in the NOT TESTED part", "The fix is built (a.log). NOT tested: every other image; the only other path", 0),
        ("the one, untied", "the one FBNeo runner covers it", 1),
        ("a semicolon clause shares its sentence's reference", "rows equal (t/x.tsv); none of the others differ", 0),
        ("a short relative path ties", "every window converges (t197/sites.dis)", 0),
        ("a universal-free claim", "the fix moves two bytes", 0),
        ("case-folded", "ALL rows match", 1),
        ("a reference later in the same sentence", "the swap holds (every victim, both sides; the rest apart) (sweep.log)", 0),
        ("a frequency is not a universal", "stepped builders, every 20 frames, are left", 0),
        ("a quotation is not the claim", "section 4 reads 'every row as frozen' and the rows hold.", 0),
        ("the next sentence does not tie", "Every figure is compared. The log is build/x.log.", 1),
        ("two possessives are not a quotation", "the gate's every row matches the tool's output", 1),
        ("every frame asserting a set is read", "every frame matches native", 1),
        ("every other is a frequency", "pinned every other frame", 0),
    ]
    bad = 0
    for name, text, want in cases:
        got = len(lint(text))
        ok = got == want
        bad += not ok
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}: {got} untied (want {want})")
    print("SELFTEST PASS" if not bad else "SELFTEST FAIL")
    return 0 if not bad else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--claim"); ap.add_argument("--file"); ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    text = a.claim if a.claim is not None else (open(a.file).read() if a.file else None)
    if text is None:
        ap.error("give --claim or --file")
    found = lint(text)
    for w, c in found:
        print(f"UNTIED [{w}]: {c}")
    print(f"claim_lint: {len(found)} untied universal/definite clause(s)")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
